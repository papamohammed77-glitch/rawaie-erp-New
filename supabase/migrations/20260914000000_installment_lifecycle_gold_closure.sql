BEGIN;

ALTER TABLE public.installments
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS order_id uuid,
  ADD COLUMN IF NOT EXISTS customer_uuid uuid,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS created_by text,
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz,
  ADD COLUMN IF NOT EXISTS completed_at timestamptz;

ALTER TABLE public.installment_details
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS installment_uuid uuid,
  ADD COLUMN IF NOT EXISTS installment_no integer,
  ADD COLUMN IF NOT EXISTS remaining_amount numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.installments
  DROP CONSTRAINT IF EXISTS installments_company_fk,
  DROP CONSTRAINT IF EXISTS installments_order_fk,
  DROP CONSTRAINT IF EXISTS installments_customer_fk;
ALTER TABLE public.installment_details
  DROP CONSTRAINT IF EXISTS installment_details_company_fk,
  DROP CONSTRAINT IF EXISTS installment_details_plan_fk;

ALTER TABLE public.installments
  ADD CONSTRAINT installments_company_fk FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE,
  ADD CONSTRAINT installments_order_fk FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE RESTRICT,
  ADD CONSTRAINT installments_customer_fk FOREIGN KEY (customer_uuid) REFERENCES public.customers(id) ON DELETE RESTRICT;
ALTER TABLE public.installment_details
  ADD CONSTRAINT installment_details_company_fk FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE,
  ADD CONSTRAINT installment_details_plan_fk FOREIGN KEY (installment_uuid) REFERENCES public.installments(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS installments_company_installment_id_uk ON public.installments(company_id,installment_id);
CREATE UNIQUE INDEX IF NOT EXISTS installments_active_order_uk ON public.installments(company_id,order_id) WHERE status IN ('Draft','Active','Partially Paid','Overdue');
CREATE INDEX IF NOT EXISTS idx_installments_company_customer ON public.installments(company_id,customer_uuid,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_installments_company_status ON public.installments(company_id,status);
CREATE INDEX IF NOT EXISTS idx_installment_details_company_due ON public.installment_details(company_id,due_date,status);
CREATE UNIQUE INDEX IF NOT EXISTS installment_details_plan_no_uk ON public.installment_details(installment_uuid,installment_no);

CREATE TABLE IF NOT EXISTS public.installment_payment_allocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  installment_id uuid NOT NULL REFERENCES public.installments(id) ON DELETE CASCADE,
  installment_detail_id uuid NOT NULL REFERENCES public.installment_details(id) ON DELETE RESTRICT,
  sales_payment_allocation_id uuid NOT NULL REFERENCES public.sales_payment_allocations(id) ON DELETE RESTRICT,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
  allocated_amount numeric NOT NULL CHECK (allocated_amount > 0),
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS installment_payment_allocations_line_uk ON public.installment_payment_allocations(sales_payment_allocation_id,installment_detail_id);
CREATE INDEX IF NOT EXISTS idx_installment_payment_allocations_plan ON public.installment_payment_allocations(company_id,installment_id,created_at DESC);

CREATE OR REPLACE FUNCTION public.refresh_installment_plan_atomic(p_company_id uuid,p_installment_id uuid,p_as_of date DEFAULT CURRENT_DATE,p_user_email text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE v_plan public.installments%ROWTYPE; v_paid numeric; v_remaining numeric; v_status text; v_total integer; v_paid_lines integer; v_overdue_lines integer;
BEGIN
 SELECT * INTO v_plan FROM public.installments WHERE id=p_installment_id AND company_id=p_company_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'INSTALLMENT_PLAN_NOT_FOUND_OR_WRONG_COMPANY'; END IF;
 UPDATE public.installment_details d SET remaining_amount=GREATEST(0,COALESCE(d.due_amount,0)-COALESCE(d.paid_amount,0)),status=CASE WHEN COALESCE(d.paid_amount,0)>=COALESCE(d.due_amount,0) THEN 'Paid' WHEN COALESCE(d.paid_amount,0)>0 AND d.due_date<p_as_of THEN 'Overdue' WHEN COALESCE(d.paid_amount,0)>0 THEN 'Partially Paid' WHEN d.due_date<p_as_of THEN 'Overdue' ELSE 'Pending' END,paid_date=CASE WHEN COALESCE(d.paid_amount,0)>=COALESCE(d.due_amount,0) THEN COALESCE(d.paid_date,p_as_of) ELSE d.paid_date END,updated_at=now() WHERE d.installment_uuid=v_plan.id;
 SELECT COALESCE(SUM(paid_amount),0),COALESCE(SUM(GREATEST(0,due_amount-paid_amount)),0),COUNT(*),COUNT(*) FILTER (WHERE status='Paid'),COUNT(*) FILTER (WHERE status='Overdue') INTO v_paid,v_remaining,v_total,v_paid_lines,v_overdue_lines FROM public.installment_details WHERE installment_uuid=v_plan.id;
 v_status:=CASE WHEN v_remaining<=0 THEN 'Paid' WHEN v_overdue_lines>0 THEN 'Overdue' WHEN v_paid>0 THEN 'Partially Paid' ELSE 'Active' END;
 UPDATE public.installments SET paid_amount=v_paid,remaining_amount=v_remaining,installment_count=v_total,status=v_status,completed_at=CASE WHEN v_status='Paid' THEN COALESCE(completed_at,now()) ELSE completed_at END,updated_at=now() WHERE id=v_plan.id AND company_id=p_company_id;
 RETURN jsonb_build_object('success',true,'installment_id',v_plan.id,'status',v_status,'total_amount',v_plan.total_amount,'paid_amount',v_paid,'remaining_amount',v_remaining,'installment_count',v_total,'paid_lines',v_paid_lines,'overdue_lines',v_overdue_lines,'as_of',p_as_of);
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_installment_plan_atomic(p_company_id uuid,p_order_id uuid,p_schedule jsonb,p_created_by text,p_operation_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE v_order public.orders%ROWTYPE; v_customer public.customers%ROWTYPE; v_existing public.erp_operation_registry%ROWTYPE; v_plan_id uuid; v_plan_code text; v_outstanding numeric; v_sum numeric:=0; v_idx integer; v_date date; v_amount numeric; v_previous date; v_fp text; v_result jsonb;
BEGIN
 IF p_company_id IS NULL OR p_order_id IS NULL OR p_operation_id IS NULL THEN RAISE EXCEPTION 'INSTALLMENT_REQUIRED_ARGUMENT'; END IF;
 IF NULLIF(BTRIM(COALESCE(p_created_by,'')),'') IS NULL THEN RAISE EXCEPTION 'INSTALLMENT_CREATED_BY_REQUIRED'; END IF;
 IF p_schedule IS NULL OR jsonb_typeof(p_schedule)<>'array' OR jsonb_array_length(p_schedule)=0 THEN RAISE EXCEPTION 'INSTALLMENT_SCHEDULE_REQUIRED'; END IF;
 IF jsonb_array_length(p_schedule)>120 THEN RAISE EXCEPTION 'INSTALLMENT_SCHEDULE_TOO_LARGE'; END IF;
 v_fp:=md5(p_company_id::text||'|'||p_order_id::text||'|'||p_schedule::text);
 INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'create_installment_plan',p_operation_id::text,jsonb_build_object('fingerprint',v_fp,'order_id',p_order_id,'schedule',p_schedule),'processing') ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;
 SELECT * INTO v_existing FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='create_installment_plan' AND operation_key=p_operation_id::text FOR UPDATE;
 IF v_existing.request_payload->>'fingerprint' IS DISTINCT FROM v_fp THEN RAISE EXCEPTION 'INSTALLMENT_OPERATION_ID_REUSED_WITH_DIFFERENT_PAYLOAD'; END IF;
 IF v_existing.status='completed' AND v_existing.response_payload IS NOT NULL THEN RETURN v_existing.response_payload||jsonb_build_object('duplicate',true); END IF;
 SELECT * INTO v_order FROM public.orders WHERE id=p_order_id AND company_id=p_company_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'INSTALLMENT_ORDER_NOT_FOUND_OR_WRONG_COMPANY'; END IF;
 IF v_order.order_status='Cancelled' THEN RAISE EXCEPTION 'INSTALLMENT_ORDER_CANCELLED'; END IF;
 IF v_order.customer_id IS NULL THEN RAISE EXCEPTION 'INSTALLMENT_CUSTOMER_REQUIRED'; END IF;
 SELECT * INTO v_customer FROM public.customers WHERE id=v_order.customer_id AND company_id=p_company_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'INSTALLMENT_CUSTOMER_NOT_FOUND_OR_WRONG_COMPANY'; END IF;
 v_outstanding:=GREATEST(0,COALESCE(v_order.total_amount,0)-COALESCE(v_order.amount_paid,0));
 IF v_outstanding<=0 THEN RAISE EXCEPTION 'INSTALLMENT_ORDER_HAS_NO_OUTSTANDING_BALANCE'; END IF;
 IF EXISTS(SELECT 1 FROM public.installments WHERE company_id=p_company_id AND order_id=p_order_id AND status IN('Draft','Active','Partially Paid','Overdue')) THEN RAISE EXCEPTION 'INSTALLMENT_ACTIVE_PLAN_ALREADY_EXISTS'; END IF;
 FOR v_idx IN 0..jsonb_array_length(p_schedule)-1 LOOP
  v_date:=((p_schedule->v_idx)->>'due_date')::date; v_amount:=((p_schedule->v_idx)->>'amount')::numeric;
  IF v_date IS NULL OR v_amount IS NULL OR v_amount<=0 THEN RAISE EXCEPTION 'INSTALLMENT_SCHEDULE_LINE_INVALID'; END IF;
  IF v_previous IS NOT NULL AND v_date<v_previous THEN RAISE EXCEPTION 'INSTALLMENT_DUE_DATES_MUST_BE_NONDECREASING'; END IF;
  v_previous:=v_date; v_sum:=v_sum+v_amount;
 END LOOP;
 IF abs(v_sum-v_outstanding)>0.01 THEN RAISE EXCEPTION 'INSTALLMENT_SCHEDULE_TOTAL_MISMATCH: outstanding=% schedule=%',v_outstanding,v_sum; END IF;
 v_plan_id:=gen_random_uuid(); v_plan_code:='INS-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,14));
 INSERT INTO public.installments(id,installment_id,invoice_id,customer_id,total_amount,paid_amount,remaining_amount,installment_count,start_date,status,created_at,company_id,order_id,customer_uuid,updated_at,created_by) VALUES(v_plan_id,v_plan_code,v_order.order_code,v_customer.id,v_outstanding,0,v_outstanding,jsonb_array_length(p_schedule),((p_schedule->0)->>'due_date')::date,'Active',now(),p_company_id,p_order_id,v_customer.id,now(),p_created_by);
 FOR v_idx IN 0..jsonb_array_length(p_schedule)-1 LOOP
  v_date:=((p_schedule->v_idx)->>'due_date')::date; v_amount:=((p_schedule->v_idx)->>'amount')::numeric;
  INSERT INTO public.installment_details(id,installment_id,due_date,due_amount,paid_amount,paid_date,status,notes,company_id,installment_uuid,installment_no,remaining_amount,updated_at) VALUES(gen_random_uuid(),v_plan_code,v_date,v_amount,0,NULL,CASE WHEN v_date<CURRENT_DATE THEN 'Overdue' ELSE 'Pending' END,COALESCE((p_schedule->v_idx)->>'notes',''),p_company_id,v_plan_id,v_idx+1,v_amount,now());
 END LOOP;
 v_result:=jsonb_build_object('success',true,'duplicate',false,'installment_id',v_plan_id,'installment_code',v_plan_code,'order_id',p_order_id,'order_code',v_order.order_code,'customer_id',v_customer.id,'total_amount',v_outstanding,'paid_amount',0,'remaining_amount',v_outstanding,'installment_count',jsonb_array_length(p_schedule),'status','Active');
 UPDATE public.erp_operation_registry SET status='completed',response_payload=v_result,completed_at=now() WHERE company_id=p_company_id AND operation_type='create_installment_plan' AND operation_key=p_operation_id::text;
 RETURN v_result;
EXCEPTION WHEN others THEN UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error',SQLERRM),completed_at=now() WHERE company_id=p_company_id AND operation_type='create_installment_plan' AND operation_key=p_operation_id::text AND status<>'completed'; RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_installment_plan_atomic(p_company_id uuid,p_installment_id uuid,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE v_plan public.installments%ROWTYPE; v_paid numeric;
BEGIN
 SELECT * INTO v_plan FROM public.installments WHERE id=p_installment_id AND company_id=p_company_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'INSTALLMENT_PLAN_NOT_FOUND_OR_WRONG_COMPANY'; END IF;
 SELECT COALESCE(SUM(paid_amount),0) INTO v_paid FROM public.installment_details WHERE installment_uuid=v_plan.id;
 IF v_paid>0 THEN RAISE EXCEPTION 'INSTALLMENT_CANNOT_CANCEL_AFTER_PAYMENT'; END IF;
 IF v_plan.status='Cancelled' THEN RETURN jsonb_build_object('success',true,'duplicate',true,'installment_id',v_plan.id,'status','Cancelled'); END IF;
 UPDATE public.installments SET status='Cancelled',cancelled_at=now(),updated_at=now() WHERE id=v_plan.id AND company_id=p_company_id;
 UPDATE public.installment_details SET status='Cancelled',updated_at=now() WHERE installment_uuid=v_plan.id;
 RETURN jsonb_build_object('success',true,'duplicate',false,'installment_id',v_plan.id,'installment_code',v_plan.installment_id,'status','Cancelled');
END;
$function$;

CREATE OR REPLACE FUNCTION public.allocate_sales_payment_to_installment_atomic(p_company_id uuid,p_order_id uuid,p_sales_payment_allocation_id uuid,p_amount numeric,p_created_by text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE v_plan public.installments%ROWTYPE; d record; v_remaining_payment numeric:=p_amount; v_detail_remaining numeric; v_alloc numeric; v_total_alloc numeric:=0;
BEGIN
 IF p_amount IS NULL OR p_amount<=0 THEN RETURN jsonb_build_object('success',true,'allocated_amount',0,'remaining_amount',0); END IF;
 SELECT * INTO v_plan FROM public.installments WHERE company_id=p_company_id AND order_id=p_order_id AND status IN('Active','Partially Paid','Overdue') ORDER BY created_at DESC LIMIT 1 FOR UPDATE;
 IF NOT FOUND THEN RETURN jsonb_build_object('success',true,'plan_found',false,'allocated_amount',0,'remaining_amount',p_amount); END IF;
 FOR d IN SELECT * FROM public.installment_details WHERE installment_uuid=v_plan.id AND status IN('Pending','Partially Paid','Overdue') AND paid_amount<due_amount ORDER BY installment_no,due_date,id FOR UPDATE LOOP
  EXIT WHEN v_remaining_payment<=0;
  v_detail_remaining:=GREATEST(0,COALESCE(d.due_amount,0)-COALESCE(d.paid_amount,0)); v_alloc:=LEAST(v_remaining_payment,v_detail_remaining); IF v_alloc<=0 THEN CONTINUE; END IF;
  INSERT INTO public.installment_payment_allocations(company_id,installment_id,installment_detail_id,sales_payment_allocation_id,order_id,allocated_amount,created_by) VALUES(p_company_id,v_plan.id,d.id,p_sales_payment_allocation_id,p_order_id,v_alloc,p_created_by) ON CONFLICT(sales_payment_allocation_id,installment_detail_id) DO NOTHING;
  IF FOUND THEN
   UPDATE public.installment_details SET paid_amount=COALESCE(paid_amount,0)+v_alloc,remaining_amount=GREATEST(0,COALESCE(d.due_amount,0)-(COALESCE(d.paid_amount,0)+v_alloc)),status=CASE WHEN COALESCE(d.paid_amount,0)+v_alloc>=d.due_amount THEN 'Paid' WHEN d.due_date<CURRENT_DATE THEN 'Overdue' ELSE 'Partially Paid' END,paid_date=CASE WHEN COALESCE(d.paid_amount,0)+v_alloc>=d.due_amount THEN CURRENT_DATE ELSE paid_date END,updated_at=now() WHERE id=d.id;
   v_remaining_payment:=v_remaining_payment-v_alloc; v_total_alloc:=v_total_alloc+v_alloc;
  END IF;
 END LOOP;
 UPDATE public.installments i SET paid_amount=x.paid_amount,remaining_amount=x.remaining_amount,status=CASE WHEN x.remaining_amount<=0 THEN 'Paid' WHEN EXISTS(SELECT 1 FROM public.installment_details z WHERE z.installment_uuid=i.id AND z.status='Overdue') THEN 'Overdue' WHEN x.paid_amount>0 THEN 'Partially Paid' ELSE 'Active' END,completed_at=CASE WHEN x.remaining_amount<=0 THEN COALESCE(i.completed_at,now()) ELSE i.completed_at END,updated_at=now() FROM (SELECT installment_uuid,COALESCE(SUM(paid_amount),0) paid_amount,COALESCE(SUM(GREATEST(0,due_amount-paid_amount)),0) remaining_amount FROM public.installment_details WHERE installment_uuid=v_plan.id GROUP BY installment_uuid) x WHERE i.id=x.installment_uuid AND i.company_id=p_company_id;
 RETURN jsonb_build_object('success',true,'plan_found',true,'installment_id',v_plan.id,'allocated_amount',v_total_alloc,'remaining_amount',v_remaining_payment,'status',(SELECT status FROM public.installments WHERE id=v_plan.id));
END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_sales_payment_to_installment() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE v_result jsonb; v_created_by text;
BEGIN
 v_created_by:=COALESCE(current_setting('request.jwt.claims',true)::jsonb->>'email','system');
 v_result:=public.allocate_sales_payment_to_installment_atomic(NEW.company_id,NEW.order_id,NEW.id,NEW.allocated_amount,v_created_by);
 RETURN NEW;
END;
$function$;
DROP TRIGGER IF EXISTS trg_sales_payment_allocation_installment ON public.sales_payment_allocations;
CREATE TRIGGER trg_sales_payment_allocation_installment AFTER INSERT ON public.sales_payment_allocations FOR EACH ROW EXECUTE FUNCTION public.trg_sales_payment_to_installment();

ALTER TABLE public.installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installment_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.installment_payment_allocations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.installments;
DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.installment_details;
DROP POLICY IF EXISTS installment_company_access ON public.installments;
DROP POLICY IF EXISTS installment_company_insert ON public.installments;
DROP POLICY IF EXISTS installment_company_update ON public.installments;
DROP POLICY IF EXISTS installment_detail_company_access ON public.installment_details;
DROP POLICY IF EXISTS installment_detail_company_insert ON public.installment_details;
DROP POLICY IF EXISTS installment_detail_company_update ON public.installment_details;
DROP POLICY IF EXISTS installment_payment_allocation_company_access ON public.installment_payment_allocations;
CREATE POLICY installment_company_access ON public.installments FOR SELECT TO authenticated USING (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));
CREATE POLICY installment_company_insert ON public.installments FOR INSERT TO authenticated WITH CHECK (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));
CREATE POLICY installment_company_update ON public.installments FOR UPDATE TO authenticated USING (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active')) WITH CHECK (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));
CREATE POLICY installment_detail_company_access ON public.installment_details FOR SELECT TO authenticated USING (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));
CREATE POLICY installment_detail_company_insert ON public.installment_details FOR INSERT TO authenticated WITH CHECK (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));
CREATE POLICY installment_detail_company_update ON public.installment_details FOR UPDATE TO authenticated USING (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active')) WITH CHECK (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));
CREATE POLICY installment_payment_allocation_company_access ON public.installment_payment_allocations FOR SELECT TO authenticated USING (company_id IN (SELECT u.company_id FROM public.users u WHERE u.auth_id=auth.uid() AND COALESCE(u.status,'Active')='Active'));

CREATE OR REPLACE VIEW public.installment_aging_v AS
SELECT i.id AS installment_id,i.company_id,i.installment_id AS installment_code,i.order_id,i.invoice_id,i.customer_uuid AS customer_id,i.total_amount,i.paid_amount,i.remaining_amount,i.status AS stored_status,
CASE WHEN i.remaining_amount<=0 THEN 'Paid' WHEN EXISTS(SELECT 1 FROM public.installment_details d2 WHERE d2.installment_uuid=i.id AND d2.remaining_amount>0 AND d2.due_date<CURRENT_DATE) THEN 'Overdue' WHEN i.paid_amount>0 THEN 'Partially Paid' ELSE 'Active' END AS effective_status,
MIN(d.due_date) FILTER(WHERE d.remaining_amount>0) AS next_due_date,COALESCE(SUM(d.remaining_amount) FILTER(WHERE d.due_date<CURRENT_DATE AND d.remaining_amount>0),0) AS overdue_amount,MAX(CURRENT_DATE-d.due_date) FILTER(WHERE d.due_date<CURRENT_DATE AND d.remaining_amount>0) AS max_overdue_days,c.name AS customer_name,o.order_code
FROM public.installments i LEFT JOIN public.installment_details d ON d.installment_uuid=i.id LEFT JOIN public.customers c ON c.id=i.customer_uuid AND c.company_id=i.company_id LEFT JOIN public.orders o ON o.id=i.order_id AND o.company_id=i.company_id GROUP BY i.id,c.name,o.order_code;
REVOKE ALL ON public.installment_aging_v FROM anon,authenticated;
GRANT SELECT ON public.installment_aging_v TO service_role;

DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM pg_publication WHERE pubname='supabase_realtime') THEN
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.installments'; EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.installment_details'; EXCEPTION WHEN duplicate_object THEN NULL; END;
    BEGIN EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.installment_payment_allocations'; EXCEPTION WHEN duplicate_object THEN NULL; END;
  END IF;
END $$;

CREATE TRIGGER trg_audit_installments AFTER INSERT OR UPDATE OR DELETE ON public.installments FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
CREATE TRIGGER trg_audit_installment_details AFTER INSERT OR UPDATE OR DELETE ON public.installment_details FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
CREATE TRIGGER trg_audit_installment_payment_allocations AFTER INSERT OR UPDATE OR DELETE ON public.installment_payment_allocations FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();

COMMIT;