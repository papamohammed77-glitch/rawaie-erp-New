-- RAWAEA ERP — complete-order-delivery closure
-- Production patch applied and transactionally verified before this canonical recording.
-- Contract: Delivery updates fulfillment state only; Physical Stock is posted at Loading.

CREATE OR REPLACE FUNCTION public.complete_order_delivery_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_order_code text,
  p_user_email text,
  p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_op_key text; v_existing jsonb; v_existing_status text; v_runsheet record; v_order record;
  v_item jsonb; v_item_code text; v_requested numeric; v_remaining numeric; v_updated integer:=0;
  v_result jsonb; v_fingerprint text; v_detail record; v_alloc numeric; v_order_loaded numeric; v_order_delivered numeric;
BEGIN
  IF p_company_id is null OR nullif(btrim(p_user_email),'') is null OR nullif(btrim(p_runsheet_code),'') is null OR nullif(btrim(p_order_code),'') is null THEN RAISE EXCEPTION 'invalid delivery request'; END IF;
  IF p_items is null OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'items are required'; END IF;
  v_fingerprint:=md5(p_company_id::text||'|'||p_runsheet_code||'|'||p_order_code||'|'||p_items::text);
  v_op_key:=p_runsheet_code||':'||p_order_code||':'||v_fingerprint;
  SELECT response_payload,status INTO v_existing,v_existing_status FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='complete_order_delivery' AND operation_key=v_op_key FOR UPDATE;
  IF FOUND THEN
    IF v_existing_status='completed' AND v_existing IS NOT NULL THEN RETURN(v_existing||jsonb_build_object('duplicate',true)); END IF;
    IF v_existing_status='processing' THEN RAISE EXCEPTION 'delivery operation is already in progress'; END IF;
    UPDATE public.erp_operation_registry SET status='processing',request_payload=p_items,response_payload=null,completed_at=null WHERE company_id=p_company_id AND operation_type='complete_order_delivery' AND operation_key=v_op_key;
  ELSE
    INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'complete_order_delivery',v_op_key,p_items,'processing');
  END IF;

  SELECT r.* INTO v_runsheet FROM public.runsheets r WHERE r.company_id=p_company_id AND r.runsheet_code=p_runsheet_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found: %',p_runsheet_code; END IF;
  SELECT o.* INTO v_order FROM public.orders o WHERE o.company_id=p_company_id AND o.order_code=p_order_code AND o.runsheet_id=v_runsheet.id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'order is not assigned to runsheet: %',p_order_code; END IF;
  IF v_order.order_status='Cancelled' THEN RAISE EXCEPTION 'cannot deliver a cancelled order'; END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    v_item_code:=nullif(btrim(coalesce(v_item->>'itemCode',v_item->>'item_code','')),'');
    v_requested:=greatest(coalesce((v_item->>'deliveredQty')::numeric,(v_item->>'delivered_qty')::numeric,0),0);
    IF v_item_code is null THEN RAISE EXCEPTION 'delivery itemCode is required'; END IF;
    IF v_requested<=0 THEN CONTINUE; END IF;
    v_remaining:=v_requested;
    FOR v_detail IN SELECT od.id,od.qty_loaded,od.qty_delivered FROM public.order_details od WHERE od.order_id=v_order.id AND od.item_code=v_item_code ORDER BY od.created_at,od.id FOR UPDATE LOOP
      EXIT WHEN v_remaining<=0;
      v_alloc:=least(v_remaining,greatest(0,coalesce(v_detail.qty_loaded,0)-coalesce(v_detail.qty_delivered,0)));
      IF v_alloc<=0 THEN CONTINUE; END IF;
      UPDATE public.order_details SET qty_delivered=coalesce(qty_delivered,0)+v_alloc,reason_delivery=coalesce(nullif(v_item->>'reason',''),reason_delivery),updated_at=now() WHERE id=v_detail.id;
      v_remaining:=v_remaining-v_alloc; v_updated:=v_updated+1;
    END LOOP;
    IF v_remaining>0 THEN RAISE EXCEPTION 'delivered quantity exceeds loaded quantity for item % by %',v_item_code,v_remaining; END IF;
  END LOOP;

  SELECT coalesce(sum(od.qty_loaded),0),coalesce(sum(od.qty_delivered),0) INTO v_order_loaded,v_order_delivered FROM public.order_details od WHERE od.order_id=v_order.id;
  UPDATE public.orders SET order_status=case when v_order_loaded>0 and v_order_delivered>=v_order_loaded then 'Delivered' else 'Partially Delivered' end,updated_at=now() WHERE id=v_order.id;
  UPDATE public.run_sheet_details rsd SET qty_ordered=a.qty_ordered,qty_picked=a.qty_picked,qty_loaded=a.qty_loaded,qty_delivered=a.qty_delivered,qty_refused=a.qty_refused,qty_returned=a.qty_returned,driver_liability=a.driver_liability,updated_at=now()
  FROM (select od.item_code,coalesce(sum(od.qty),0) qty_ordered,coalesce(sum(od.qty_picked),0) qty_picked,coalesce(sum(od.qty_loaded),0) qty_loaded,coalesce(sum(od.qty_delivered),0) qty_delivered,coalesce(sum(od.qty_refused),0) qty_refused,coalesce(sum(od.qty_returned),0) qty_returned,coalesce(sum(od.driver_liability),0) driver_liability from public.order_details od join public.orders o on o.id=od.order_id where o.company_id=p_company_id and o.runsheet_id=v_runsheet.id group by od.item_code) a
  WHERE rsd.runsheet_id=v_runsheet.id AND rsd.item_code=a.item_code;

  v_result:=jsonb_build_object('success',true,'duplicate',false,'msg','تم إنهاء التسليم بنجاح','updated_count',v_updated,'order_status',(select order_status from public.orders where id=v_order.id));
  UPDATE public.erp_operation_registry SET status='completed',response_payload=v_result,completed_at=now() WHERE company_id=p_company_id AND operation_type='complete_order_delivery' AND operation_key=v_op_key;
  INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data) VALUES(p_user_email,'update','erp_operation_registry',v_op_key,v_result);
  RETURN v_result;
EXCEPTION WHEN OTHERS THEN
  UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() WHERE company_id=p_company_id AND operation_type='complete_order_delivery' AND operation_key=v_op_key;
  RAISE;
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_order_delivery_atomic(uuid,text,text,text,jsonb) FROM public,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.complete_order_delivery_atomic(uuid,text,text,text,jsonb) TO service_role;
