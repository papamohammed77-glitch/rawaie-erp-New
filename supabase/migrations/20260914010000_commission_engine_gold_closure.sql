BEGIN;

CREATE TABLE IF NOT EXISTS public.commission_plans (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_code text NOT NULL,
 name text NOT NULL,
 basis_type text NOT NULL CHECK (basis_type IN ('achievement','target')),
 basis_metric text NOT NULL CHECK (basis_metric IN ('invoiced_amount','gross_profit','invoiced_qty')),
 payout_method text NOT NULL DEFAULT 'percentage' CHECK (payout_method IN ('percentage','fixed_tier')),
 default_rate numeric(12,6) NOT NULL DEFAULT 0 CHECK (default_rate >= 0),
 target_amount numeric(18,4) CHECK (target_amount IS NULL OR target_amount >= 0),
 target_frequency text CHECK (target_frequency IS NULL OR target_frequency IN ('monthly','quarterly','yearly')),
 effective_from date NOT NULL,
 effective_to date,
 status text NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Approved','Archived')),
 notes text, created_by text, approved_by text, approved_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(company_id,plan_code), CHECK(effective_to IS NULL OR effective_to>=effective_from), CHECK(basis_type<>'target' OR target_amount IS NOT NULL)
);
CREATE TABLE IF NOT EXISTS public.commission_rules (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.commission_plans(id) ON DELETE CASCADE,
 min_achievement_pct numeric(12,4) NOT NULL DEFAULT 0 CHECK(min_achievement_pct>=0), max_achievement_pct numeric(12,4),
 rate numeric(12,6) NOT NULL DEFAULT 0 CHECK(rate>=0), fixed_amount numeric(18,4) NOT NULL DEFAULT 0 CHECK(fixed_amount>=0), priority integer NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,plan_id,min_achievement_pct,priority), CHECK(max_achievement_pct IS NULL OR max_achievement_pct>=min_achievement_pct)
);
CREATE TABLE IF NOT EXISTS public.commission_assignments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.commission_plans(id) ON DELETE CASCADE,
 sales_rep_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
 target_amount numeric(18,4), effective_from date, effective_to date, active boolean NOT NULL DEFAULT true, created_by text,
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(company_id,plan_id,sales_rep_id),
 CHECK(target_amount IS NULL OR target_amount>=0), CHECK(effective_to IS NULL OR effective_from IS NULL OR effective_to>=effective_from)
);
CREATE TABLE IF NOT EXISTS public.commission_runs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.commission_plans(id) ON DELETE RESTRICT,
 period_start date NOT NULL, period_end date NOT NULL, run_type text NOT NULL DEFAULT 'Earned' CHECK(run_type IN('Earned','Reversal')),
 status text NOT NULL DEFAULT 'Posted' CHECK(status IN('Posted','Approved','Paid','Reversed')),
 operation_id uuid NOT NULL DEFAULT gen_random_uuid(), reversal_of_run_id uuid REFERENCES public.commission_runs(id) ON DELETE RESTRICT,
 total_base numeric(18,4) NOT NULL DEFAULT 0, total_commission numeric(18,4) NOT NULL DEFAULT 0, line_count integer NOT NULL DEFAULT 0,
 payment_reference text, reason text, created_by text, approved_by text, approved_at timestamptz, paid_by text, paid_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(company_id,operation_id), CHECK(period_end>=period_start)
);
CREATE TABLE IF NOT EXISTS public.commission_run_lines (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 run_id uuid NOT NULL REFERENCES public.commission_runs(id) ON DELETE CASCADE, order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
 sales_rep_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT, order_code text NOT NULL,
 basis_metric text NOT NULL, gross_amount numeric(18,4) NOT NULL DEFAULT 0, returned_amount numeric(18,4) NOT NULL DEFAULT 0,
 base_amount numeric(18,4) NOT NULL DEFAULT 0, achievement_pct numeric(12,4) NOT NULL DEFAULT 0,
 commission_rate numeric(12,6) NOT NULL DEFAULT 0, commission_amount numeric(18,4) NOT NULL DEFAULT 0,
 source_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb, status text NOT NULL DEFAULT 'Posted' CHECK(status IN('Posted','Reversed')),
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(run_id,order_id,sales_rep_id)
);
CREATE INDEX IF NOT EXISTS commission_assignments_rep_idx ON public.commission_assignments(company_id,sales_rep_id,active);
CREATE INDEX IF NOT EXISTS commission_runs_company_period_idx ON public.commission_runs(company_id,period_start,period_end,status);
CREATE INDEX IF NOT EXISTS commission_run_lines_company_rep_idx ON public.commission_run_lines(company_id,sales_rep_id,created_at);
ALTER TABLE public.commission_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_run_lines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS commission_plans_service_only ON public.commission_plans;
CREATE POLICY commission_plans_service_only ON public.commission_plans FOR ALL TO service_role USING(true) WITH CHECK(true);
DROP POLICY IF EXISTS commission_rules_service_only ON public.commission_rules;
CREATE POLICY commission_rules_service_only ON public.commission_rules FOR ALL TO service_role USING(true) WITH CHECK(true);
DROP POLICY IF EXISTS commission_assignments_service_only ON public.commission_assignments;
CREATE POLICY commission_assignments_service_only ON public.commission_assignments FOR ALL TO service_role USING(true) WITH CHECK(true);
DROP POLICY IF EXISTS commission_runs_service_only ON public.commission_runs;
CREATE POLICY commission_runs_service_only ON public.commission_runs FOR ALL TO service_role USING(true) WITH CHECK(true);
DROP POLICY IF EXISTS commission_run_lines_service_only ON public.commission_run_lines;
CREATE POLICY commission_run_lines_service_only ON public.commission_run_lines FOR ALL TO service_role USING(true) WITH CHECK(true);
CREATE OR REPLACE FUNCTION public.commission_assignment_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $f$ BEGIN
 IF NOT EXISTS(select 1 from public.commission_plans p where p.id=NEW.plan_id and p.company_id=NEW.company_id) THEN RAISE EXCEPTION 'خطة العمولة لا تتبع الشركة'; END IF;
 IF NOT EXISTS(select 1 from public.users u where u.id=NEW.sales_rep_id and u.company_id=NEW.company_id) THEN RAISE EXCEPTION 'مندوب العمولة لا يتبع الشركة'; END IF; RETURN NEW; END; $f$;
DROP TRIGGER IF EXISTS trg_commission_assignment_guard ON public.commission_assignments;
CREATE TRIGGER trg_commission_assignment_guard BEFORE INSERT OR UPDATE ON public.commission_assignments FOR EACH ROW EXECUTE FUNCTION public.commission_assignment_guard();
CREATE OR REPLACE FUNCTION public.commission_rule_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $f$ BEGIN
 IF NOT EXISTS(select 1 from public.commission_plans p where p.id=NEW.plan_id and p.company_id=NEW.company_id) THEN RAISE EXCEPTION 'قاعدة العمولة لا تتبع الخطة أو الشركة'; END IF; RETURN NEW; END; $f$;
DROP TRIGGER IF EXISTS trg_commission_rule_guard ON public.commission_rules;
CREATE TRIGGER trg_commission_rule_guard BEFORE INSERT OR UPDATE ON public.commission_rules FOR EACH ROW EXECUTE FUNCTION public.commission_rule_guard();
CREATE OR REPLACE FUNCTION public.commission_audit_trigger() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $f$ DECLARE a text:=coalesce(nullif(current_setting('request.jwt.claims',true)::jsonb->>'email',''),'system'); BEGIN
 IF TG_OP='INSERT' THEN INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data) VALUES(a,'create',TG_TABLE_NAME,NEW.id::text,to_jsonb(NEW));
 ELSIF TG_OP='UPDATE' THEN INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data,new_data) VALUES(a,'update',TG_TABLE_NAME,OLD.id::text,to_jsonb(OLD),to_jsonb(NEW));
 ELSE INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data) VALUES(a,'delete',TG_TABLE_NAME,OLD.id::text,to_jsonb(OLD)); END IF; RETURN NULL; END; $f$;
DO $$ DECLARE t text; BEGIN FOREACH t IN ARRAY ARRAY['commission_plans','commission_rules','commission_assignments','commission_runs','commission_run_lines'] LOOP EXECUTE format('DROP TRIGGER IF EXISTS trg_commission_audit ON public.%I',t); EXECUTE format('CREATE TRIGGER trg_commission_audit AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.commission_audit_trigger()',t); END LOOP; END $$;
CREATE OR REPLACE FUNCTION public.commission_engine_atomic(
 p_company_id uuid,p_operation text,p_user_email text,p_plan_id uuid DEFAULT NULL,p_plan_payload jsonb DEFAULT NULL,p_rule_payload jsonb DEFAULT NULL,p_assignment_payload jsonb DEFAULT NULL,p_period_start date DEFAULT NULL,p_period_end date DEFAULT NULL,p_sales_rep_id uuid DEFAULT NULL,p_operation_id uuid DEFAULT NULL,p_run_id uuid DEFAULT NULL,p_reason text DEFAULT NULL,p_payment_reference text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $f$
DECLARE p public.commission_plans%ROWTYPE; r public.commission_runs%ROWTYPE; oldr public.commission_runs%ROWTYPE; x record; q numeric; target numeric; ach numeric; rate numeric; fixed numeric; commission numeric; tb numeric:=0; tc numeric:=0; lc integer:=0; op uuid:=coalesce(p_operation_id,gen_random_uuid()); rev uuid;
BEGIN
 IF NOT EXISTS(select 1 from public.companies where id=p_company_id) THEN RAISE EXCEPTION 'سياق الشركة غير موجود'; END IF;
 IF nullif(btrim(coalesce(p_user_email,'')),'') IS NULL THEN RAISE EXCEPTION 'المستخدم المنفذ مطلوب'; END IF;
 IF p_operation='PLAN_SAVE' THEN
   IF p_plan_id IS NULL THEN INSERT INTO public.commission_plans(company_id,plan_code,name,basis_type,basis_metric,payout_method,default_rate,target_amount,target_frequency,effective_from,effective_to,status,notes,created_by)
   VALUES(p_company_id,nullif(btrim(p_plan_payload->>'plan_code'),''),nullif(btrim(p_plan_payload->>'name'),''),coalesce(p_plan_payload->>'basis_type','achievement'),coalesce(p_plan_payload->>'basis_metric','invoiced_amount'),coalesce(p_plan_payload->>'payout_method','percentage'),coalesce(nullif(p_plan_payload->>'default_rate','')::numeric,0),nullif(p_plan_payload->>'target_amount','')::numeric,nullif(p_plan_payload->>'target_frequency',''),coalesce(nullif(p_plan_payload->>'effective_from','')::date,current_date),nullif(p_plan_payload->>'effective_to','')::date,'Draft',p_plan_payload->>'notes',p_user_email) RETURNING * INTO p;
   ELSE SELECT * INTO p FROM public.commission_plans WHERE id=p_plan_id AND company_id=p_company_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'خطة العمولة غير موجودة ضمن الشركة'; END IF; IF p.status='Approved' THEN RAISE EXCEPTION 'لا يمكن تعديل خطة معتمدة'; END IF;
     UPDATE public.commission_plans SET plan_code=coalesce(nullif(btrim(p_plan_payload->>'plan_code'),''),plan_code),name=coalesce(nullif(btrim(p_plan_payload->>'name'),''),name),basis_type=coalesce(p_plan_payload->>'basis_type',basis_type),basis_metric=coalesce(p_plan_payload->>'basis_metric',basis_metric),payout_method=coalesce(p_plan_payload->>'payout_method',payout_method),default_rate=coalesce(nullif(p_plan_payload->>'default_rate','')::numeric,default_rate),target_amount=case when p_plan_payload ? 'target_amount' then nullif(p_plan_payload->>'target_amount','')::numeric else target_amount end,target_frequency=case when p_plan_payload ? 'target_frequency' then nullif(p_plan_payload->>'target_frequency','') else target_frequency end,effective_from=coalesce(nullif(p_plan_payload->>'effective_from','')::date,effective_from),effective_to=case when p_plan_payload ? 'effective_to' then nullif(p_plan_payload->>'effective_to','')::date else effective_to end,notes=coalesce(p_plan_payload->>'notes',notes),updated_at=now() WHERE id=p.id AND company_id=p_company_id RETURNING * INTO p;
   END IF; IF nullif(p.plan_code,'') IS NULL OR nullif(p.name,'') IS NULL THEN RAISE EXCEPTION 'كود واسم الخطة مطلوبان'; END IF; RETURN jsonb_build_object('success',true,'operation','PLAN_SAVE','plan',to_jsonb(p));
 END IF;
 IF p_plan_id IS NOT NULL THEN SELECT * INTO p FROM public.commission_plans WHERE id=p_plan_id AND company_id=p_company_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'خطة العمولة غير موجودة ضمن الشركة'; END IF; END IF;
 IF p_operation='PLAN_APPROVE' THEN
   IF p.status='Approved' THEN RETURN jsonb_build_object('success',true,'duplicate',true,'plan_id',p.id); END IF;
   IF p_rule_payload IS NOT NULL AND jsonb_typeof(p_rule_payload)='array' THEN DELETE FROM public.commission_rules WHERE company_id=p_company_id AND plan_id=p.id; INSERT INTO public.commission_rules(company_id,plan_id,min_achievement_pct,max_achievement_pct,rate,fixed_amount,priority) SELECT p_company_id,p.id,z.min_achievement_pct,z.max_achievement_pct,coalesce(z.rate,0),coalesce(z.fixed_amount,0),coalesce(z.priority,1) FROM jsonb_to_recordset(p_rule_payload) z(min_achievement_pct numeric,max_achievement_pct numeric,rate numeric,fixed_amount numeric,priority integer); END IF;
   IF NOT EXISTS(select 1 from public.commission_rules where plan_id=p.id) THEN INSERT INTO public.commission_rules(company_id,plan_id,min_achievement_pct,max_achievement_pct,rate,fixed_amount,priority) VALUES(p_company_id,p.id,0,NULL,p.default_rate,0,1); END IF;
   UPDATE public.commission_plans SET status='Approved',approved_by=p_user_email,approved_at=now(),updated_at=now() WHERE id=p.id AND company_id=p_company_id; RETURN jsonb_build_object('success',true,'plan_id',p.id,'status','Approved');
 END IF;
 IF p_operation='PLAN_ASSIGN' THEN
   IF jsonb_typeof(coalesce(p_assignment_payload,'null'::jsonb))<>'array' THEN RAISE EXCEPTION 'قائمة المندوبين مطلوبة'; END IF;
   INSERT INTO public.commission_assignments(company_id,plan_id,sales_rep_id,target_amount,effective_from,effective_to,active,created_by) SELECT p_company_id,p.id,z.sales_rep_id,nullif(z.target_amount,0),nullif(z.effective_from,'')::date,nullif(z.effective_to,'')::date,coalesce(z.active,true),p_user_email FROM jsonb_to_recordset(p_assignment_payload) z(sales_rep_id uuid,target_amount numeric,effective_from text,effective_to text,active boolean) ON CONFLICT(company_id,plan_id,sales_rep_id) DO UPDATE SET target_amount=excluded.target_amount,effective_from=excluded.effective_from,effective_to=excluded.effective_to,active=excluded.active;
   RETURN jsonb_build_object('success',true,'plan_id',p.id,'assigned',jsonb_array_length(p_assignment_payload));
 END IF;
 IF p_operation IN('PREVIEW','POST') THEN
   IF p.status<>'Approved' THEN RAISE EXCEPTION 'خطة العمولة يجب أن تكون Approved'; END IF; IF p_period_start IS NULL OR p_period_end IS NULL OR p_period_end<p_period_start THEN RAISE EXCEPTION 'الفترة غير صحيحة'; END IF;
   CREATE TEMP TABLE IF NOT EXISTS pg_temp._commission_calc(sales_rep_id uuid,order_id uuid,order_code text,gross_amount numeric,returned_amount numeric,base_amount numeric,achievement_pct numeric,rate numeric,fixed_amount numeric,commission_amount numeric) ON COMMIT DROP; TRUNCATE pg_temp._commission_calc;
   FOR x IN SELECT a.sales_rep_id,coalesce(a.target_amount,p.target_amount,0) target_amount FROM public.commission_assignments a JOIN public.users u ON u.id=a.sales_rep_id AND u.company_id=p_company_id WHERE a.company_id=p_company_id AND a.plan_id=p.id AND a.active=true AND (p_sales_rep_id IS NULL OR a.sales_rep_id=p_sales_rep_id) AND (a.effective_from IS NULL OR a.effective_from<=p_period_end) AND (a.effective_to IS NULL OR a.effective_to>=p_period_start) LOOP
     SELECT coalesce(sum(case p.basis_metric when 'invoiced_qty' then greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0) when 'gross_profit' then greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0)*(coalesce(od.unit_price,0)-coalesce(i.cost_price,0)) else greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0)*coalesce(od.unit_price,0) end),0) INTO q FROM public.orders o JOIN public.order_details od ON od.order_id=o.id JOIN public.items i ON i.id=od.item_id WHERE o.company_id=p_company_id AND o.sales_rep_id=x.sales_rep_id AND o.order_status='Invoiced' AND o.order_date BETWEEN p_period_start AND p_period_end;
     target:=case when x.target_amount>0 then x.target_amount else null end; ach:=case when target is null then 0 else q/target*100 end;
     FOR r IN SELECT o.id order_id,o.order_code,sum(greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0)*coalesce(od.unit_price,0)) gross_amount,sum(coalesce(od.qty_returned,0)*coalesce(od.unit_price,0)) returned_amount,case p.basis_metric when 'invoiced_qty' then sum(greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0)) when 'gross_profit' then sum(greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0)*(coalesce(od.unit_price,0)-coalesce(i.cost_price,0))) else sum(greatest(coalesce(od.qty,0)-coalesce(od.qty_returned,0),0)*coalesce(od.unit_price,0)) end base_amount FROM public.orders o JOIN public.order_details od ON od.order_id=o.id JOIN public.items i ON i.id=od.item_id WHERE o.company_id=p_company_id AND o.sales_rep_id=x.sales_rep_id AND o.order_status='Invoiced' AND o.order_date BETWEEN p_period_start AND p_period_end GROUP BY o.id,o.order_code LOOP
       SELECT z.rate,z.fixed_amount INTO rate,fixed FROM public.commission_rules z WHERE z.company_id=p_company_id AND z.plan_id=p.id AND ach>=z.min_achievement_pct AND (z.max_achievement_pct IS NULL OR ach<=z.max_achievement_pct) ORDER BY z.min_achievement_pct DESC,z.priority LIMIT 1;
       rate:=coalesce(rate,p.default_rate,0); fixed:=coalesce(fixed,0); commission:=case when p.payout_method='fixed_tier' then fixed else r.base_amount*rate/100 end;
       INSERT INTO pg_temp._commission_calc VALUES(x.sales_rep_id,r.order_id,r.order_code,r.gross_amount,r.returned_amount,r.base_amount,ach,rate,fixed,commission);
     END LOOP;
   END LOOP;
   SELECT coalesce(sum(base_amount),0),coalesce(sum(commission_amount),0),count(*) INTO tb,tc,lc FROM pg_temp._commission_calc;
   IF p_operation='PREVIEW' THEN RETURN jsonb_build_object('success',true,'operation','PREVIEW','plan_id',p.id,'period_start',p_period_start,'period_end',p_period_end,'total_base',tb,'total_commission',tc,'line_count',lc,'lines',(select coalesce(jsonb_agg(to_jsonb(c) order by c.sales_rep_id,c.order_code),'[]'::jsonb) from pg_temp._commission_calc c)); END IF;
   SELECT * INTO oldr FROM public.commission_runs WHERE company_id=p_company_id AND operation_id=op FOR UPDATE; IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'run_id',oldr.id,'status',oldr.status,'total_commission',oldr.total_commission); END IF;
   INSERT INTO public.commission_runs(company_id,plan_id,period_start,period_end,run_type,status,operation_id,total_base,total_commission,line_count,created_by) VALUES(p_company_id,p.id,p_period_start,p_period_end,'Earned','Posted',op,tb,tc,lc,p_user_email) RETURNING * INTO r;
   INSERT INTO public.commission_run_lines(company_id,run_id,order_id,sales_rep_id,order_code,basis_metric,gross_amount,returned_amount,base_amount,achievement_pct,commission_rate,commission_amount,source_snapshot) SELECT p_company_id,r.id,c.order_id,c.sales_rep_id,c.order_code,p.basis_metric,c.gross_amount,c.returned_amount,c.base_amount,c.achievement_pct,c.rate,c.commission_amount,jsonb_build_object('plan_id',p.id,'plan_code',p.plan_code,'basis_metric',p.basis_metric,'period_start',p_period_start,'period_end',p_period_end) FROM pg_temp._commission_calc c;
   RETURN jsonb_build_object('success',true,'run_id',r.id,'operation_id',op,'status','Posted','total_base',tb,'total_commission',tc,'line_count',lc);
 END IF;
 IF p_operation='APPROVE_RUN' THEN UPDATE public.commission_runs SET status='Approved',approved_by=p_user_email,approved_at=now() WHERE id=p_run_id AND company_id=p_company_id AND status='Posted'; IF NOT FOUND THEN RAISE EXCEPTION 'دفتر العمولة غير موجود أو ليس Posted'; END IF; RETURN jsonb_build_object('success',true,'run_id',p_run_id,'status','Approved'); END IF;
 IF p_operation='MARK_PAID' THEN UPDATE public.commission_runs SET status='Paid',paid_by=p_user_email,paid_at=now(),payment_reference=p_payment_reference WHERE id=p_run_id AND company_id=p_company_id AND status='Approved'; IF NOT FOUND THEN RAISE EXCEPTION 'دفتر العمولة يجب أن يكون Approved قبل الصرف'; END IF; RETURN jsonb_build_object('success',true,'run_id',p_run_id,'status','Paid'); END IF;
 IF p_operation='REVERSE_RUN' THEN SELECT * INTO r FROM public.commission_runs WHERE id=p_run_id AND company_id=p_company_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'دفتر العمولة غير موجود'; END IF; IF r.status='Reversed' OR r.run_type='Reversal' THEN RAISE EXCEPTION 'دفتر العمولة لا يمكن عكسه مرة أخرى'; END IF; IF EXISTS(select 1 from public.commission_runs where reversal_of_run_id=r.id) THEN RAISE EXCEPTION 'تم إنشاء عكس سابق لهذا الدفتر'; END IF; INSERT INTO public.commission_runs(company_id,plan_id,period_start,period_end,run_type,status,operation_id,reversal_of_run_id,total_base,total_commission,line_count,reason,created_by) VALUES(p_company_id,r.plan_id,r.period_start,r.period_end,'Reversal','Posted',op,r.id,-r.total_base,-r.total_commission,r.line_count,p_reason,p_user_email) RETURNING id INTO rev; UPDATE public.commission_runs SET status='Reversed' WHERE id=r.id; UPDATE public.commission_run_lines SET status='Reversed' WHERE run_id=r.id; INSERT INTO public.commission_run_lines(company_id,run_id,order_id,sales_rep_id,order_code,basis_metric,gross_amount,returned_amount,base_amount,achievement_pct,commission_rate,commission_amount,source_snapshot,status) SELECT company_id,rev,order_id,sales_rep_id,order_code,basis_metric,-gross_amount,-returned_amount,-base_amount,achievement_pct,commission_rate,-commission_amount,jsonb_build_object('reversal_of_run_id',r.id),'Reversed' FROM public.commission_run_lines WHERE run_id=r.id; RETURN jsonb_build_object('success',true,'run_id',r.id,'reversal_run_id',rev,'status','Reversed'); END IF;
 RAISE EXCEPTION 'عملية Commission غير مدعومة: %',p_operation;
END; $f$;
REVOKE ALL ON FUNCTION public.commission_engine_atomic(uuid,text,text,uuid,jsonb,jsonb,jsonb,date,date,uuid,uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.commission_engine_atomic(uuid,text,text,uuid,jsonb,jsonb,jsonb,date,date,uuid,uuid,uuid,text,text) TO service_role;
DO $$ BEGIN
 IF NOT EXISTS(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='commission_plans') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.commission_plans; END IF;
 IF NOT EXISTS(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='commission_assignments') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.commission_assignments; END IF;
 IF NOT EXISTS(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='commission_runs') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.commission_runs; END IF;
 IF NOT EXISTS(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='commission_run_lines') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.commission_run_lines; END IF;
END $$;
COMMIT;
