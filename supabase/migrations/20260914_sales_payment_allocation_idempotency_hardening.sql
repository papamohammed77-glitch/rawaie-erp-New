-- RAWAEA ERP — sales payment allocation idempotency hardening
-- Existing operation_id may only be retried when the exact request fingerprint matches.
-- A reused operation_id with a different payload is rejected before duplicate return.
-- Also rejects stale processing operations older than 15 minutes.

BEGIN;

CREATE OR REPLACE FUNCTION public.post_sales_payment_allocation_atomic(
  p_company_id uuid,
  p_operation_id uuid,
  p_customer_id uuid,
  p_treasury_id uuid,
  p_amount numeric,
  p_receipt_date date,
  p_allocations jsonb,
  p_reference text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_created_by text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
-- The deployed Production definition is intentionally reproduced here so Git remains canonical.
-- Full behavior is identical to the Production definition deployed by migration
-- sales_payment_allocation_idempotency_hardening.
DECLARE v_existing public.erp_operation_registry%ROWTYPE; v_customer public.customers%ROWTYPE; v_treasury public.treasury%ROWTYPE; v_cash_account public.chart_of_accounts%ROWTYPE; v_ar_account public.chart_of_accounts%ROWTYPE; v_receipt_id uuid; v_cash_result jsonb; v_ledger_result jsonb; v_receipt_code text; v_alloc_total numeric:=0; v_unallocated numeric:=0; v_order public.orders%ROWTYPE; v_alloc record; v_outstanding numeric; v_result jsonb; v_alloc_count integer:=0; v_fp text;
BEGIN
 IF p_company_id IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_COMPANY_REQUIRED'; END IF; IF p_operation_id IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_OPERATION_ID_REQUIRED'; END IF; IF p_customer_id IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_CUSTOMER_REQUIRED'; END IF; IF p_treasury_id IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_TREASURY_REQUIRED'; END IF; IF p_amount IS NULL OR p_amount<=0 THEN RAISE EXCEPTION 'SALES_PAYMENT_AMOUNT_INVALID'; END IF; IF p_receipt_date IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_DATE_REQUIRED'; END IF; IF NULLIF(BTRIM(COALESCE(p_created_by,'')),'') IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_CREATED_BY_REQUIRED'; END IF; IF p_allocations IS NOT NULL AND jsonb_typeof(p_allocations)<>'array' THEN RAISE EXCEPTION 'SALES_PAYMENT_ALLOCATIONS_INVALID'; END IF;
 SELECT * INTO v_customer FROM public.customers WHERE id=p_customer_id AND company_id=p_company_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'SALES_PAYMENT_CUSTOMER_NOT_FOUND_OR_WRONG_COMPANY'; END IF;
 SELECT * INTO v_treasury FROM public.treasury WHERE id=p_treasury_id AND company_id=p_company_id AND COALESCE(is_active,true) FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'SALES_PAYMENT_TREASURY_NOT_FOUND_OR_WRONG_COMPANY'; END IF;
 SELECT * INTO v_cash_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='121' AND COALESCE(is_active,true) ORDER BY id LIMIT 1; IF NOT FOUND THEN RAISE EXCEPTION 'SALES_PAYMENT_CASH_ACCOUNT_121_NOT_CONFIGURED'; END IF;
 SELECT * INTO v_ar_account FROM public.chart_of_accounts WHERE company_id=p_company_id AND account_code='123' AND COALESCE(is_active,true) ORDER BY id LIMIT 1; IF NOT FOUND THEN RAISE EXCEPTION 'SALES_PAYMENT_AR_ACCOUNT_123_NOT_CONFIGURED'; END IF;
 v_fp:=md5(p_company_id::text||'|'||p_customer_id::text||'|'||p_treasury_id::text||'|'||p_amount::text||'|'||p_receipt_date::text||'|'||COALESCE(p_allocations,'[]'::jsonb)::text||'|'||COALESCE(p_reference,''));
 INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'post_sales_payment_allocation',p_operation_id::text,jsonb_build_object('fingerprint',v_fp,'customer_id',p_customer_id,'amount',p_amount,'allocations',COALESCE(p_allocations,'[]'::jsonb)),'processing') ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;
 SELECT * INTO v_existing FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='post_sales_payment_allocation' AND operation_key=p_operation_id::text FOR UPDATE;
 IF v_existing.request_payload->>'fingerprint' IS DISTINCT FROM v_fp THEN RAISE EXCEPTION 'SALES_PAYMENT_OPERATION_ID_REUSED_WITH_DIFFERENT_PAYLOAD'; END IF;
 IF v_existing.status='completed' AND v_existing.response_payload IS NOT NULL THEN RETURN v_existing.response_payload||jsonb_build_object('duplicate',true); END IF;
 IF v_existing.status='processing' AND v_existing.created_at < now()-interval '15 minutes' THEN UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error','STALE_PROCESSING_OPERATION'),completed_at=now() WHERE company_id=p_company_id AND operation_type='post_sales_payment_allocation' AND operation_key=p_operation_id::text; RAISE EXCEPTION 'SALES_PAYMENT_OPERATION_STALE_PROCESSING'; END IF;
 IF p_allocations IS NOT NULL AND jsonb_array_length(p_allocations)>0 AND EXISTS (SELECT 1 FROM jsonb_to_recordset(p_allocations) AS x(order_id uuid,order_code text,allocated_amount numeric) GROUP BY COALESCE(x.order_id::text,BTRIM(x.order_code)) HAVING COUNT(*)>1) THEN RAISE EXCEPTION 'SALES_PAYMENT_DUPLICATE_ORDER_ALLOCATION'; END IF;
 IF p_allocations IS NOT NULL THEN FOR v_alloc IN SELECT * FROM jsonb_to_recordset(p_allocations) AS x(order_id uuid,order_code text,allocated_amount numeric) LOOP IF COALESCE(v_alloc.allocated_amount,0)<=0 THEN RAISE EXCEPTION 'SALES_PAYMENT_ALLOCATION_AMOUNT_INVALID'; END IF; IF v_alloc.order_id IS NULL AND NULLIF(BTRIM(COALESCE(v_alloc.order_code,'')),'') IS NULL THEN RAISE EXCEPTION 'SALES_PAYMENT_ORDER_ID_OR_CODE_REQUIRED'; END IF; SELECT * INTO v_order FROM public.orders WHERE company_id=p_company_id AND (v_alloc.order_id IS NULL OR id=v_alloc.order_id) AND (v_alloc.order_id IS NOT NULL OR order_code=BTRIM(v_alloc.order_code)) FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'SALES_PAYMENT_ORDER_NOT_FOUND_OR_WRONG_COMPANY'; END IF; IF v_order.customer_id IS DISTINCT FROM p_customer_id THEN RAISE EXCEPTION 'SALES_PAYMENT_ORDER_CUSTOMER_MISMATCH: %',v_order.order_code; END IF; IF v_order.order_status='Cancelled' THEN RAISE EXCEPTION 'SALES_PAYMENT_ORDER_NOT_PAYABLE: %',v_order.order_code; END IF; v_outstanding:=GREATEST(0,COALESCE(v_order.total_amount,0)-COALESCE(v_order.amount_paid,0)); IF v_alloc.allocated_amount>v_outstanding THEN RAISE EXCEPTION 'SALES_PAYMENT_ALLOCATION_EXCEEDS_OUTSTANDING: % outstanding=% requested=%',v_order.order_code,v_outstanding,v_alloc.allocated_amount; END IF; v_alloc_total:=v_alloc_total+v_alloc.allocated_amount; END LOOP; END IF;
 IF v_alloc_total>p_amount THEN RAISE EXCEPTION 'SALES_PAYMENT_ALLOCATIONS_EXCEED_RECEIPT_AMOUNT'; END IF; v_unallocated:=p_amount-v_alloc_total; v_receipt_code:='RCV-CUST-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,18));
 v_cash_result:=public.post_cash_receipt_atomic(p_company_id,p_operation_id,p_treasury_id,v_cash_account.id,v_ar_account.id,p_amount,p_receipt_date,COALESCE(NULLIF(BTRIM(p_reference),''),v_receipt_code),COALESCE(NULLIF(BTRIM(p_notes),''),'تحصيل من العميل '||v_customer.name),p_created_by,v_customer.name,'CUSTOMER_PAYMENT',p_customer_id,p_notes,v_receipt_code);
 INSERT INTO public.sales_payment_receipts(company_id,customer_id,cash_box_id,operation_id,receipt_code,receipt_date,amount,allocated_amount,unallocated_amount,reference,notes,status,created_by) VALUES(p_company_id,p_customer_id,(v_cash_result->>'cash_box_id')::uuid,p_operation_id,v_receipt_code,p_receipt_date,p_amount,v_alloc_total,v_unallocated,p_reference,p_notes,'Posted',p_created_by) RETURNING id INTO v_receipt_id;
 IF p_allocations IS NOT NULL THEN FOR v_alloc IN SELECT * FROM jsonb_to_recordset(p_allocations) AS x(order_id uuid,order_code text,allocated_amount numeric) LOOP SELECT * INTO v_order FROM public.orders WHERE company_id=p_company_id AND (v_alloc.order_id IS NULL OR id=v_alloc.order_id) AND (v_alloc.order_id IS NOT NULL OR order_code=BTRIM(v_alloc.order_code)) FOR UPDATE; INSERT INTO public.sales_payment_allocations(company_id,receipt_id,order_id,allocated_amount) VALUES(p_company_id,v_receipt_id,v_order.id,v_alloc.allocated_amount); UPDATE public.orders SET amount_paid=COALESCE(amount_paid,0)+v_alloc.allocated_amount,updated_at=now() WHERE id=v_order.id AND company_id=p_company_id; v_alloc_count:=v_alloc_count+1; END LOOP; END IF;
 v_ledger_result:=public.post_customer_ledger_entry(p_company_id,p_operation_id,p_customer_id,p_receipt_date,v_receipt_code,COALESCE(NULLIF(BTRIM(p_notes),''),'تحصيل من العميل '||v_customer.name),0,p_amount,NULL,p_created_by);
 v_result:=jsonb_build_object('success',true,'duplicate',false,'operation_id',p_operation_id,'receipt_id',v_receipt_id,'receipt_code',v_receipt_code,'customer_id',p_customer_id,'amount',p_amount,'allocated_amount',v_alloc_total,'unallocated_amount',v_unallocated,'allocation_count',v_alloc_count,'cash_box_id',v_cash_result->>'cash_box_id');
 UPDATE public.erp_operation_registry SET status='completed',response_payload=v_result,completed_at=now() WHERE company_id=p_company_id AND operation_type='post_sales_payment_allocation' AND operation_key=p_operation_id::text;
 INSERT INTO public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at) VALUES(gen_random_uuid(),p_created_by,'create','sales_payment_receipts',v_receipt_id::text,v_result,now());
 RETURN v_result;
EXCEPTION WHEN others THEN UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error',SQLERRM),completed_at=now() WHERE company_id=p_company_id AND operation_type='post_sales_payment_allocation' AND operation_key=p_operation_id::text AND status<>'completed'; RAISE;
END;
$function$;

REVOKE ALL ON FUNCTION public.post_sales_payment_allocation_atomic(uuid,uuid,uuid,uuid,numeric,date,jsonb,text,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.post_sales_payment_allocation_atomic(uuid,uuid,uuid,uuid,numeric,date,jsonb,text,text,text) TO service_role;

COMMIT;
