-- RAWAEA ERP — complete-return closure
-- Production patch was applied and transactionally verified before recording this canonical migration.
-- Changes: preserve runsheet-return driver-liability responsibility; guard runsheet-only flow from unassigned order record; conform rescue audit entry to audit_log action contract.

-- Canonical Production definition is intentionally reproduced from the verified deployed function.
-- See commit history and Closure log for the verified Production behavior.

CREATE OR REPLACE FUNCTION public.complete_return_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_order_code text,
  p_is_pos_return boolean,
  p_user_email text,
  p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_op_key text; v_existing jsonb; v_main_branch uuid; v_runsheet record; v_order record;
  v_item jsonb; v_item_id uuid; v_item_code text; v_returned numeric; v_remaining numeric;
  v_alloc numeric; v_total_value numeric:=0; v_updated integer:=0; v_skipped integer:=0;
  v_adjusted integer:=0; v_detail record; v_expected_return numeric; v_new_returned numeric;
  v_line_liability numeric; v_shortage numeric; v_shortage_value numeric; v_return_condition text;
  v_reason text; v_customer_balance numeric:=0; v_entry_id uuid; v_inventory_account uuid;
  v_cogs_account uuid; v_inventory_name text; v_cogs_name text; v_order_total_original numeric:=0;
  v_order_total_returned numeric:=0; v_order_new_total numeric:=0; v_order_new_status text;
  v_stock_move jsonb; v_fingerprint text; v_existing_status text; v_result jsonb;
  v_item_name text; v_item_expected_total numeric:=0; v_item_returned_total numeric:=0;
BEGIN
  IF p_company_id IS NULL OR NULLIF(btrim(p_user_email),'') IS NULL THEN RAISE EXCEPTION 'invalid company/user context'; END IF;
  IF COALESCE(p_runsheet_code,'')='' AND COALESCE(p_order_code,'')='' THEN RAISE EXCEPTION 'runsheet_code or order_code is required'; END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'items are required'; END IF;
  IF p_runsheet_code IS NOT NULL AND p_order_code IS NULL AND p_is_pos_return THEN RAISE EXCEPTION 'POS return requires order_code'; END IF;
  IF p_runsheet_code IS NOT NULL AND p_is_pos_return THEN RAISE EXCEPTION 'runsheet return and POS return cannot be combined'; END IF;
  v_fingerprint:=md5(coalesce(p_company_id::text,'')||'|'||coalesce(p_runsheet_code,'')||'|'||coalesce(p_order_code,'')||'|'||coalesce(p_is_pos_return,false)::text||'|'||p_items::text);
  v_op_key:=coalesce(p_runsheet_code,p_order_code)||':'||v_fingerprint;
  SELECT response_payload,status INTO v_existing,v_existing_status FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='complete_return' AND operation_key=v_op_key FOR UPDATE;
  IF FOUND THEN
    IF v_existing_status='completed' AND v_existing IS NOT NULL THEN RETURN(v_existing||jsonb_build_object('duplicate',true)); END IF;
    RAISE EXCEPTION 'return operation is already in progress';
  END IF;
  INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'complete_return',v_op_key,p_items,'processing');
  SELECT a.main_branch_id INTO v_main_branch FROM public.app_settings a WHERE a.company_id=p_company_id AND a.main_branch_id IS NOT NULL ORDER BY a.created_at ASC,a.id LIMIT 1;
  IF v_main_branch IS NULL THEN RAISE EXCEPTION 'MAIN branch context unavailable for company'; END IF;
  IF p_runsheet_code IS NOT NULL THEN
    SELECT r.* INTO v_runsheet FROM public.runsheets r WHERE r.company_id=p_company_id AND r.runsheet_code=p_runsheet_code FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found: %',p_runsheet_code; END IF;
    IF v_runsheet.status<>'Returning' THEN RAISE EXCEPTION 'runsheet is not in Returning state: %',v_runsheet.status; END IF;
  END IF;
  IF p_order_code IS NOT NULL THEN
    SELECT o.* INTO v_order FROM public.orders o WHERE o.company_id=p_company_id AND o.order_code=p_order_code FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'order not found: %',p_order_code; END IF;
    IF v_order.order_status='Cancelled' THEN RAISE EXCEPTION 'cannot return a cancelled order'; END IF;
    IF p_runsheet_code IS NOT NULL AND v_order.runsheet_id IS DISTINCT FROM v_runsheet.id THEN RAISE EXCEPTION 'order is not assigned to the requested runsheet'; END IF;
  END IF;
  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    v_item_code:=nullif(btrim(coalesce(v_item->>'item_code',v_item->>'itemCode','')),'');
    v_returned:=greatest(coalesce((v_item->>'returnedQty')::numeric,(v_item->>'returned_qty')::numeric,0),0);
    v_return_condition:=lower(coalesce(v_item->>'return_condition',v_item->>'returnCondition','good'));
    v_reason:=nullif(coalesce(v_item->>'reason',''),'');
    IF v_returned<=0 THEN v_skipped:=v_skipped+1; CONTINUE; END IF;
    IF v_item_code IS NULL THEN RAISE EXCEPTION 'return item_code is required'; END IF;
    IF v_return_condition NOT IN ('good','damaged','missing') THEN RAISE EXCEPTION 'unsupported return condition: %',v_return_condition; END IF;
    SELECT i.id,i.name INTO v_item_id,v_item_name FROM public.items i WHERE i.item_code=v_item_code;
    IF v_item_id IS NULL THEN RAISE EXCEPTION 'item not found: %',v_item_code; END IF;
    IF p_runsheet_code IS NOT NULL THEN
      SELECT coalesce(sum(greatest(0,coalesce(od.qty_loaded,0)-coalesce(od.qty_delivered,0)-coalesce(od.qty_returned,0))),0) INTO v_item_expected_total FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=v_runsheet.id AND od.item_code=v_item_code;
      v_item_returned_total:=v_returned; v_shortage:=greatest(0,v_item_expected_total-v_item_returned_total);
      SELECT coalesce(max(od.unit_price),0) INTO v_shortage_value FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=v_runsheet.id AND od.item_code=v_item_code;
      v_shortage_value:=v_shortage*v_shortage_value; v_remaining:=v_returned;
      FOR v_detail IN SELECT od.id,od.qty_loaded,od.qty_delivered,od.qty_returned,od.unit_price FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=v_runsheet.id AND od.item_code=v_item_code ORDER BY od.created_at ASC,od.id ASC FOR UPDATE OF od LOOP
        EXIT WHEN v_remaining<=0;
        v_expected_return:=greatest(0,coalesce(v_detail.qty_loaded,0)-coalesce(v_detail.qty_delivered,0)-coalesce(v_detail.qty_returned,0));
        v_alloc:=least(v_remaining,v_expected_return); IF v_alloc<=0 THEN CONTINUE; END IF;
        v_new_returned:=coalesce(v_detail.qty_returned,0)+v_alloc;
        v_line_liability:=case when v_return_condition in('damaged','missing') then greatest(0,coalesce(v_detail.qty_loaded,0)-coalesce(v_detail.qty_delivered,0)-v_new_returned)*coalesce(v_detail.unit_price,0) else 0 end;
        UPDATE public.order_details SET qty_returned=v_new_returned,reason_return=coalesce(v_reason,reason_return),driver_liability=v_line_liability,updated_at=now() WHERE id=v_detail.id;
        v_total_value:=v_total_value+v_alloc*coalesce(v_detail.unit_price,0); v_remaining:=v_remaining-v_alloc; v_updated:=v_updated+1;
      END LOOP;
      IF v_remaining>0 THEN RAISE EXCEPTION 'return quantity exceeds outstanding run-sheet quantity for item % by %',v_item_code,v_remaining; END IF;
      IF v_shortage>0 AND v_runsheet.driver_id IS NOT NULL THEN
        INSERT INTO public.driver_liabilities(id,company_id,driver_id,runsheet_id,item_code,item_name,qty_missing,unit_price,amount,reason,status)
        VALUES(gen_random_uuid(),p_company_id,v_runsheet.driver_id,v_runsheet.id,v_item_code,coalesce(v_item_name,v_item_code),v_shortage,case when v_shortage>0 then v_shortage_value/v_shortage else 0 end,v_shortage_value,coalesce(v_reason,'عجز غير مبرر'),'pending');
      END IF;
      IF v_return_condition='good' THEN v_stock_move:=public.post_stock_movement(p_company_id,'SalesReturn',null,v_main_branch,v_item_id,v_returned,p_runsheet_code,p_runsheet_code,p_user_email,'Return:'||v_op_key||':'||v_item_id::text); END IF;
    ELSE
      SELECT od.id,od.qty,od.qty_returned,od.unit_price INTO v_detail FROM public.order_details od WHERE od.order_id=v_order.id AND od.item_code=v_item_code FOR UPDATE;
      IF NOT FOUND THEN RAISE EXCEPTION 'order detail not found for item %',v_item_code; END IF;
      v_expected_return:=greatest(0,coalesce(v_detail.qty,0)-coalesce(v_detail.qty_returned,0));
      IF v_returned>v_expected_return THEN v_adjusted:=v_adjusted+1; v_returned:=v_expected_return; END IF;
      IF v_returned<=0 THEN CONTINUE; END IF;
      UPDATE public.order_details SET qty_returned=coalesce(qty_returned,0)+v_returned,reason_return=coalesce(v_reason,reason_return,'مرتجع من نقطة البيع'),driver_liability=0,updated_at=now() WHERE id=v_detail.id;
      v_total_value:=v_total_value+v_returned*coalesce(v_detail.unit_price,0); v_updated:=v_updated+1;
      IF v_return_condition='good' THEN v_stock_move:=public.post_stock_movement(p_company_id,'SalesReturn',null,v_main_branch,v_item_id,v_returned,p_order_code,p_order_code,p_user_email,'Return:'||v_op_key||':'||v_item_id::text); END IF;
    END IF;
  END LOOP;
  IF p_order_code IS NOT NULL AND v_total_value>0 THEN
    SELECT coalesce(cl.balance,0) INTO v_customer_balance FROM public.customer_ledger cl WHERE cl.customer_id=v_order.customer_id ORDER BY cl.created_at DESC LIMIT 1;
    INSERT INTO public.customer_ledger(customer_id,entry_date,reference,description,debit,credit,balance,due_date,user_email) VALUES(v_order.customer_id,current_date,p_order_code,'مرتجع – '||p_order_code,0,v_total_value,v_customer_balance-v_total_value,current_date,p_user_email);
  END IF;
  IF p_order_code IS NOT NULL THEN
    SELECT coalesce(sum(od.qty),0),coalesce(sum(od.qty_returned),0),coalesce(sum(greatest(0,od.qty-od.qty_returned)*od.unit_price),0) INTO v_order_total_original,v_order_total_returned,v_order_new_total FROM public.order_details od WHERE od.order_id=v_order.id;
    v_order_new_status:=case when v_order_total_original>0 and v_order_total_returned>=v_order_total_original then 'Returned' else 'Partially Returned' end;
    UPDATE public.orders SET order_status=v_order_new_status,total_amount=v_order_new_total,updated_at=now() WHERE id=v_order.id;
  END IF;
  IF p_runsheet_code IS NOT NULL THEN
    UPDATE public.run_sheet_details rsd SET qty_ordered=a.qty_ordered,qty_picked=a.qty_picked,qty_loaded=a.qty_loaded,qty_delivered=a.qty_delivered,qty_refused=a.qty_refused,qty_returned=a.qty_returned,driver_liability=a.driver_liability,updated_at=now()
    FROM (SELECT od.item_code,coalesce(sum(od.qty),0) qty_ordered,coalesce(sum(od.qty_picked),0) qty_picked,coalesce(sum(od.qty_loaded),0) qty_loaded,coalesce(sum(od.qty_delivered),0) qty_delivered,coalesce(sum(od.qty_refused),0) qty_refused,coalesce(sum(od.qty_returned),0) qty_returned,coalesce(sum(od.driver_liability),0) driver_liability FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=v_runsheet.id GROUP BY od.item_code) a
    WHERE rsd.runsheet_id=v_runsheet.id AND rsd.item_code=a.item_code;
    UPDATE public.runsheets SET status='Returned',return_end=now(),updated_at=now() WHERE id=v_runsheet.id AND status='Returning';
  END IF;
  v_result:=jsonb_build_object('success',true,'duplicate',false,'msg','تم إنهاء المرتجعات بنجاح','updated_count',v_updated,'skipped_count',v_skipped,'adjusted_count',v_adjusted,'total_returned_value',v_total_value,'new_order_status',v_order_new_status);
  UPDATE public.erp_operation_registry SET status='completed',response_payload=v_result,completed_at=now() WHERE company_id=p_company_id AND operation_type='complete_return' AND operation_key=v_op_key;
  INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data) VALUES(p_user_email,'update','erp_operation_registry',v_op_key,v_result);
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() WHERE company_id=p_company_id AND operation_type='complete_return' AND operation_key=v_op_key;
  RAISE;
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) TO service_role;
