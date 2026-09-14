BEGIN;

CREATE TABLE IF NOT EXISTS public.sales_target_plans (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_code text NOT NULL,
 name text NOT NULL,
 period_start date NOT NULL,
 period_end date NOT NULL,
 metric text NOT NULL CHECK (metric IN ('amount','qty','gross_profit','mixed')),
 status text NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Approved','Closed','Cancelled')),
 notes text,
 created_by text,
 approved_by text,
 approved_at timestamptz,
 closed_by text,
 closed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(company_id,plan_code),
 CHECK(period_end>=period_start)
);

CREATE TABLE IF NOT EXISTS public.sales_target_assignments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.sales_target_plans(id) ON DELETE CASCADE,
 sales_rep_id uuid REFERENCES public.users(id) ON DELETE RESTRICT,
 branch_id uuid REFERENCES public.branches(id) ON DELETE RESTRICT,
 target_amount numeric NOT NULL DEFAULT 0 CHECK(target_amount>=0),
 target_qty numeric NOT NULL DEFAULT 0 CHECK(target_qty>=0),
 target_gross_profit numeric NOT NULL DEFAULT 0 CHECK(target_gross_profit>=0),
 weight numeric NOT NULL DEFAULT 100 CHECK(weight>0),
 active boolean NOT NULL DEFAULT true,
 notes text,
 created_by text,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(plan_id,sales_rep_id,branch_id),
 CHECK(sales_rep_id IS NOT NULL OR branch_id IS NOT NULL OR target_amount>0 OR target_qty>0 OR target_gross_profit>0)
);

CREATE TABLE IF NOT EXISTS public.sales_target_runs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 plan_id uuid NOT NULL REFERENCES public.sales_target_plans(id) ON DELETE RESTRICT,
 operation_id text NOT NULL,
 status text NOT NULL CHECK(status IN('Preview','Posted','Approved','Reversed')),
 evaluated_at timestamptz NOT NULL DEFAULT now(),
 created_by text,
 approved_by text,
 approved_at timestamptz,
 reversal_of_run_id uuid REFERENCES public.sales_target_runs(id) ON DELETE RESTRICT,
 total_target_amount numeric NOT NULL DEFAULT 0,
 total_actual_amount numeric NOT NULL DEFAULT 0,
 total_target_qty numeric NOT NULL DEFAULT 0,
 total_actual_qty numeric NOT NULL DEFAULT 0,
 total_target_gp numeric NOT NULL DEFAULT 0,
 total_actual_gp numeric NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(company_id,operation_id)
);

CREATE TABLE IF NOT EXISTS public.sales_target_run_lines (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
 run_id uuid NOT NULL REFERENCES public.sales_target_runs(id) ON DELETE CASCADE,
 assignment_id uuid NOT NULL REFERENCES public.sales_target_assignments(id) ON DELETE RESTRICT,
 sales_rep_id uuid REFERENCES public.users(id) ON DELETE RESTRICT,
 branch_id uuid REFERENCES public.branches(id) ON DELETE RESTRICT,
 target_amount numeric NOT NULL DEFAULT 0,
 actual_amount numeric NOT NULL DEFAULT 0,
 target_qty numeric NOT NULL DEFAULT 0,
 actual_qty numeric NOT NULL DEFAULT 0,
 target_gross_profit numeric NOT NULL DEFAULT 0,
 actual_gross_profit numeric NOT NULL DEFAULT 0,
 achievement_amount_pct numeric NOT NULL DEFAULT 0,
 achievement_qty_pct numeric NOT NULL DEFAULT 0,
 achievement_gp_pct numeric NOT NULL DEFAULT 0,
 primary_achievement_pct numeric NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(run_id,assignment_id)
);

CREATE INDEX IF NOT EXISTS sales_target_plans_company_period_idx ON public.sales_target_plans(company_id,period_start,period_end);
CREATE INDEX IF NOT EXISTS sales_target_assignments_company_plan_idx ON public.sales_target_assignments(company_id,plan_id);
CREATE INDEX IF NOT EXISTS sales_target_runs_company_plan_idx ON public.sales_target_runs(company_id,plan_id,evaluated_at DESC);
CREATE INDEX IF NOT EXISTS sales_target_run_lines_company_run_idx ON public.sales_target_run_lines(company_id,run_id);

CREATE OR REPLACE FUNCTION public.sales_target_assignment_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $f$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.sales_target_plans p WHERE p.id=NEW.plan_id AND p.company_id=NEW.company_id) THEN RAISE EXCEPTION 'Target plan company mismatch'; END IF;
 IF NEW.sales_rep_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=NEW.sales_rep_id AND u.company_id=NEW.company_id) THEN RAISE EXCEPTION 'Sales representative company mismatch'; END IF;
 IF NEW.branch_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=NEW.branch_id AND b.company_id=NEW.company_id) THEN RAISE EXCEPTION 'Branch company mismatch'; END IF;
 RETURN NEW;
END; $f$;
DROP TRIGGER IF EXISTS trg_sales_target_assignment_guard ON public.sales_target_assignments;
CREATE TRIGGER trg_sales_target_assignment_guard BEFORE INSERT OR UPDATE ON public.sales_target_assignments FOR EACH ROW EXECUTE FUNCTION public.sales_target_assignment_guard();

CREATE OR REPLACE FUNCTION public.sales_target_audit_trigger() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $f$
DECLARE actor text:=coalesce(nullif(current_setting('request.jwt.claims',true)::jsonb->>'email',''),coalesce(NEW.created_by,NEW.approved_by,'system'));
BEGIN
 IF TG_OP='INSERT' THEN INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data) VALUES(actor,'create',TG_TABLE_NAME,NEW.id::text,to_jsonb(NEW));
 ELSIF TG_OP='UPDATE' THEN INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data,new_data) VALUES(actor,'update',TG_TABLE_NAME,OLD.id::text,to_jsonb(OLD),to_jsonb(NEW));
 ELSE INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data) VALUES(actor,'delete',TG_TABLE_NAME,OLD.id::text,to_jsonb(OLD)); END IF;
 RETURN NULL;
END; $f$;

DROP TRIGGER IF EXISTS trg_sales_target_plans_audit ON public.sales_target_plans;
CREATE TRIGGER trg_sales_target_plans_audit AFTER INSERT OR UPDATE OR DELETE ON public.sales_target_plans FOR EACH ROW EXECUTE FUNCTION public.sales_target_audit_trigger();
DROP TRIGGER IF EXISTS trg_sales_target_assignments_audit ON public.sales_target_assignments;
CREATE TRIGGER trg_sales_target_assignments_audit AFTER INSERT OR UPDATE OR DELETE ON public.sales_target_assignments FOR EACH ROW EXECUTE FUNCTION public.sales_target_audit_trigger();
DROP TRIGGER IF EXISTS trg_sales_target_runs_audit ON public.sales_target_runs;
CREATE TRIGGER trg_sales_target_runs_audit AFTER INSERT OR UPDATE OR DELETE ON public.sales_target_runs FOR EACH ROW EXECUTE FUNCTION public.sales_target_audit_trigger();
DROP TRIGGER IF EXISTS trg_sales_target_run_lines_audit ON public.sales_target_run_lines;
CREATE TRIGGER trg_sales_target_run_lines_audit AFTER INSERT OR UPDATE OR DELETE ON public.sales_target_run_lines FOR EACH ROW EXECUTE FUNCTION public.sales_target_audit_trigger();

ALTER TABLE public.sales_target_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_target_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_target_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_target_run_lines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sales_target_plans_read ON public.sales_target_plans;
CREATE POLICY sales_target_plans_read ON public.sales_target_plans FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_plans.company_id));
DROP POLICY IF EXISTS sales_target_assignments_read ON public.sales_target_assignments;
CREATE POLICY sales_target_assignments_read ON public.sales_target_assignments FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_assignments.company_id));
DROP POLICY IF EXISTS sales_target_runs_read ON public.sales_target_runs;
CREATE POLICY sales_target_runs_read ON public.sales_target_runs FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_runs.company_id));
DROP POLICY IF EXISTS sales_target_run_lines_read ON public.sales_target_run_lines;
CREATE POLICY sales_target_run_lines_read ON public.sales_target_run_lines FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=auth.uid() AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_run_lines.company_id));

CREATE OR REPLACE FUNCTION public.sales_target_engine_atomic(p_company_id uuid,p_operation text,p_user_email text,p_plan_id uuid DEFAULT NULL,p_payload jsonb DEFAULT '{}'::jsonb,p_operation_id text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $f$
DECLARE actor public.users%ROWTYPE; plan_row public.sales_target_plans%ROWTYPE; ass public.sales_target_assignments%ROWTYPE; run_row public.sales_target_runs%ROWTYPE; r numeric; q numeric; gp numeric; target numeric; ach numeric; metric text;
BEGIN
 SELECT * INTO actor FROM public.users WHERE lower(email)=lower(p_user_email) AND coalesce(status,'Active')='Active' LIMIT 1;
 IF NOT FOUND OR actor.company_id<>p_company_id THEN RAISE EXCEPTION 'Authenticated company context invalid'; END IF;
 IF p_operation IN('SAVE_PLAN','SAVE_ASSIGNMENT','APPROVE_PLAN') AND actor.role NOT IN('مدير مبيعات','مشرف مبيعات','مدير النظام','مدير عام') THEN RAISE EXCEPTION 'Sales target management permission required'; END IF;
 IF p_operation='LIST_PLANS' THEN RETURN jsonb_build_object('success',true,'plans',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.period_start DESC,x.created_at DESC) FROM (SELECT * FROM public.sales_target_plans WHERE company_id=p_company_id) x),'[]'::jsonb)); END IF;
 IF p_operation='LIST_ASSIGNMENTS' THEN RETURN jsonb_build_object('success',true,'assignments',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.id) FROM (SELECT * FROM public.sales_target_assignments WHERE company_id=p_company_id AND plan_id=p_plan_id) x),'[]'::jsonb)); END IF;
 IF p_operation='LIST_RUNS' THEN RETURN jsonb_build_object('success',true,'runs',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.evaluated_at DESC) FROM (SELECT * FROM public.sales_target_runs WHERE company_id=p_company_id ORDER BY evaluated_at DESC) x),'[]'::jsonb)); END IF;
 IF p_operation='SAVE_PLAN' THEN
  IF p_plan_id IS NULL THEN INSERT INTO public.sales_target_plans(company_id,plan_code,name,period_start,period_end,metric,status,notes,created_by) VALUES(p_company_id,btrim(p_payload->>'plan_code'),coalesce(nullif(btrim(p_payload->>'name'),'') ,btrim(p_payload->>'plan_code')),(p_payload->>'period_start')::date,(p_payload->>'period_end')::date,coalesce(p_payload->>'metric','amount'),'Draft',p_payload->>'notes',p_user_email) RETURNING * INTO plan_row;
  ELSE UPDATE public.sales_target_plans SET name=coalesce(nullif(btrim(p_payload->>'name'),''),name),period_start=coalesce(nullif(p_payload->>'period_start','')::date,period_start),period_end=coalesce(nullif(p_payload->>'period_end','')::date,period_end),metric=coalesce(nullif(p_payload->>'metric',''),metric),notes=coalesce(p_payload->>'notes',notes),updated_at=now() WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft' RETURNING * INTO plan_row; IF NOT FOUND THEN RAISE EXCEPTION 'Draft target plan not found'; END IF; END IF;
  RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row));
 END IF;
 IF p_operation='SAVE_ASSIGNMENT' THEN
  IF NOT EXISTS(SELECT 1 FROM public.sales_target_plans WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft') THEN RAISE EXCEPTION 'Draft target plan required'; END IF;
  INSERT INTO public.sales_target_assignments(company_id,plan_id,sales_rep_id,branch_id,target_amount,target_qty,target_gross_profit,weight,active,notes,created_by) VALUES(p_company_id,p_plan_id,NULLIF(p_payload->>'sales_rep_id','')::uuid,NULLIF(p_payload->>'branch_id','')::uuid,coalesce((p_payload->>'target_amount')::numeric,0),coalesce((p_payload->>'target_qty')::numeric,0),coalesce((p_payload->>'target_gross_profit')::numeric,0),coalesce((p_payload->>'weight')::numeric,100),coalesce((p_payload->>'active')::boolean,true),p_payload->>'notes',p_user_email) RETURNING * INTO ass;
  RETURN jsonb_build_object('success',true,'assignment',to_jsonb(ass));
 END IF;
 IF p_operation='APPROVE_PLAN' THEN
  UPDATE public.sales_target_plans SET status='Approved',approved_by=p_user_email,approved_at=now(),updated_at=now() WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft' RETURNING * INTO plan_row;
  IF NOT FOUND THEN RAISE EXCEPTION 'Draft target plan not found'; END IF;
  RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row));
 END IF;
 IF p_operation IN('PREVIEW','POST') THEN
  SELECT * INTO plan_row FROM public.sales_target_plans WHERE id=p_plan_id AND company_id=p_company_id;
  IF NOT FOUND OR plan_row.status NOT IN('Approved','Closed') THEN RAISE EXCEPTION 'Approved target plan required'; END IF;
  IF p_operation='POST' THEN
   IF nullif(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id required'; END IF;
   SELECT * INTO run_row FROM public.sales_target_runs WHERE company_id=p_company_id AND operation_id=p_operation_id FOR UPDATE;
   IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'run',to_jsonb(run_row)); END IF;
  END IF;
  INSERT INTO public.sales_target_runs(company_id,plan_id,operation_id,status,created_by) VALUES(p_company_id,p_plan_id,coalesce(nullif(p_operation_id,''),'PREVIEW-'||gen_random_uuid()::text),CASE WHEN p_operation='POST' THEN 'Posted' ELSE 'Preview' END,p_user_email) RETURNING * INTO run_row;
  FOR ass IN SELECT * FROM public.sales_target_assignments WHERE company_id=p_company_id AND plan_id=p_plan_id AND active=true ORDER BY id LOOP
   SELECT coalesce(sum((od.unit_price)*greatest(od.qty-coalesce(od.qty_returned,0),0)),0),coalesce(sum(greatest(od.qty-coalesce(od.qty_returned,0),0)),0),coalesce(sum((od.unit_price-coalesce(i.cost_price,0))*greatest(od.qty-coalesce(od.qty_returned,0),0)),0)
   INTO r,q,gp FROM public.orders o JOIN public.order_details od ON od.order_id=o.id JOIN public.items i ON i.id=od.item_id
   WHERE o.company_id=p_company_id AND o.order_status='Invoiced' AND o.order_date BETWEEN plan_row.period_start AND plan_row.period_end
     AND (ass.sales_rep_id IS NULL OR o.sales_rep_id=ass.sales_rep_id) AND (ass.branch_id IS NULL OR o.branch_id=ass.branch_id);
   metric:=plan_row.metric; target:=CASE metric WHEN 'amount' THEN ass.target_amount WHEN 'qty' THEN ass.target_qty WHEN 'gross_profit' THEN ass.target_gross_profit ELSE ass.target_amount END;
   ach:=CASE WHEN target>0 THEN CASE metric WHEN 'amount' THEN r/target*100 WHEN 'qty' THEN q/target*100 WHEN 'gross_profit' THEN gp/target*100 ELSE r/target*100 END ELSE 0 END;
   INSERT INTO public.sales_target_run_lines(company_id,run_id,assignment_id,sales_rep_id,branch_id,target_amount,actual_amount,target_qty,actual_qty,target_gross_profit,actual_gross_profit,achievement_amount_pct,achievement_qty_pct,achievement_gp_pct,primary_achievement_pct) VALUES(p_company_id,run_row.id,ass.id,ass.sales_rep_id,ass.branch_id,ass.target_amount,r,ass.target_qty,q,ass.target_gross_profit,gp,CASE WHEN ass.target_amount>0 THEN r/ass.target_amount*100 ELSE 0 END,CASE WHEN ass.target_qty>0 THEN q/ass.target_qty*100 ELSE 0 END,CASE WHEN ass.target_gross_profit>0 THEN gp/ass.target_gross_profit*100 ELSE 0 END,ach);
  END LOOP;
  UPDATE public.sales_target_runs z SET total_target_amount=(SELECT coalesce(sum(target_amount),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),total_actual_amount=(SELECT coalesce(sum(actual_amount),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),total_target_qty=(SELECT coalesce(sum(target_qty),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),total_actual_qty=(SELECT coalesce(sum(actual_qty),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),total_target_gp=(SELECT coalesce(sum(target_gross_profit),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),total_actual_gp=(SELECT coalesce(sum(actual_gross_profit),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id) WHERE z.id=run_row.id;
  RETURN jsonb_build_object('success',true,'run_id',run_row.id,'status',(SELECT status FROM public.sales_target_runs WHERE id=run_row.id));
 END IF;
 RAISE EXCEPTION 'Unsupported operation: %',p_operation;
END; $f$;
REVOKE ALL ON FUNCTION public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text) TO service_role;

ALTER TABLE public.sales_target_plans REPLICA IDENTITY FULL;
ALTER TABLE public.sales_target_assignments REPLICA IDENTITY FULL;
ALTER TABLE public.sales_target_runs REPLICA IDENTITY FULL;
ALTER TABLE public.sales_target_run_lines REPLICA IDENTITY FULL;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='sales_target_plans') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.sales_target_plans; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='sales_target_assignments') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.sales_target_assignments; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='sales_target_runs') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.sales_target_runs; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='sales_target_run_lines') THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.sales_target_run_lines; END IF;
END $$;
COMMIT;
