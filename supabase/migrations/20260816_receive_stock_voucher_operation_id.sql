-- RECEIVE idempotency contract: request-level operation identity.
CREATE OR REPLACE FUNCTION public.post_manual_stock_voucher_atomic(p_company_id uuid,p_voucher_code text,p_operation text,p_user_email text,p_effects jsonb,p_operation_id text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE v public.stock_vouchers%ROWTYPE; e record; v_detail_qty numeric; v_received_before numeric; movement text; idem text; src uuid; tgt uuid; remain integer:=0; movement_result jsonb;
BEGIN
 SELECT * INTO v FROM public.stock_vouchers WHERE company_id=p_company_id AND voucher_code=p_voucher_code FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;
 IF p_operation NOT IN('SEND','RECEIVE') THEN RAISE EXCEPTION 'عملية مخزنية غير مدعومة'; END IF;
 IF p_operation='SEND' AND v.status<>'Draft' THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالإرسال'; END IF;
 IF p_operation='RECEIVE' AND v.status<>'Sent' THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالاستلام'; END IF;
 IF p_operation='RECEIVE' AND NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id مطلوب للاستلام'; END IF;
 IF p_effects IS NULL OR jsonb_typeof(p_effects)<>'array' OR jsonb_array_length(p_effects)=0 THEN RAISE EXCEPTION 'لا توجد حركات مخزنية للتنفيذ'; END IF;
 FOR e IN SELECT * FROM jsonb_to_recordset(p_effects) AS x(direction text,branch_id uuid,item_id uuid,item_code text,qty numeric) LOOP
  IF e.qty IS NULL OR e.qty<=0 OR e.branch_id IS NULL OR e.item_id IS NULL OR e.item_code IS NULL THEN RAISE EXCEPTION 'بيانات حركة مخزنية غير صالحة'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=e.branch_id AND b.company_id=p_company_id) THEN RAISE EXCEPTION 'الفرع غير موجود أو لا يتبع الشركة'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.items i WHERE i.id=e.item_id AND i.company_id=p_company_id AND i.item_code=e.item_code) THEN RAISE EXCEPTION 'الصنف غير متسق مع سياق الشركة'; END IF;
  SELECT d.qty,coalesce(d.received_qty,0) INTO v_detail_qty,v_received_before FROM public.stock_voucher_details d WHERE d.voucher_id=v.id AND d.item_id=e.item_id AND d.item_code=e.item_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الصنف غير موجود في تفاصيل الإذن'; END IF;
  IF p_operation='SEND' THEN
   IF e.direction<>'OUT' OR e.branch_id<>v.from_id OR v.type NOT IN('Transfer','DirectSale','SupplierReturn') THEN RAISE EXCEPTION 'اتجاه الإرسال لا يطابق الإذن'; END IF;
   IF e.qty<>v_detail_qty THEN RAISE EXCEPTION 'كمية الإرسال لا تطابق تفاصيل الإذن'; END IF;
   movement:=CASE v.type WHEN 'Transfer' THEN 'TransferOut' WHEN 'DirectSale' THEN 'DirectSale' WHEN 'SupplierReturn' THEN 'SupplierReturn' END; src:=v.from_id; tgt:=NULL; idem:='ManualVoucher:SEND:'||p_company_id::text||':'||v.id::text||':'||e.item_id::text||':'||e.qty::text;
  ELSE
   IF e.direction<>'IN' OR e.branch_id<>v.to_id OR v.type NOT IN('Transfer','DirectReturn') THEN RAISE EXCEPTION 'اتجاه الاستلام لا يطابق الإذن'; END IF;
   IF e.qty>(v_detail_qty-v_received_before) THEN RAISE EXCEPTION 'الكمية المستلمة أكبر من المتبقي'; END IF;
   movement:=CASE v.type WHEN 'Transfer' THEN 'TransferIn' WHEN 'DirectReturn' THEN 'DirectReturn' END; src:=NULL; tgt:=v.to_id; idem:='ManualVoucher:RECEIVE:'||p_company_id::text||':'||v.id::text||':'||p_operation_id::text||':'||e.item_id::text;
  END IF;
  movement_result:=public.post_stock_movement(p_company_id,movement,src,tgt,e.item_id,e.qty,p_voucher_code,p_voucher_code,p_user_email,idem);
  IF p_operation='RECEIVE' AND coalesce((movement_result->>'duplicate')::boolean,false)=false THEN
   UPDATE public.stock_voucher_details SET received_qty=coalesce(received_qty,0)+e.qty WHERE voucher_id=v.id AND item_id=e.item_id AND item_code=e.item_code;
   IF NOT FOUND THEN RAISE EXCEPTION 'تعذر تحديث الكمية المستلمة'; END IF;
  END IF;
 END LOOP;
 IF p_operation='SEND' THEN UPDATE public.stock_vouchers SET status='Sent',sent_date=now() WHERE id=v.id AND company_id=p_company_id AND status='Draft';
 ELSE SELECT count(*) INTO remain FROM public.stock_voucher_details sd WHERE sd.voucher_id=v.id AND coalesce(sd.received_qty,0)<sd.qty; UPDATE public.stock_vouchers SET status=CASE WHEN remain=0 THEN 'Received' ELSE 'Sent' END,received_date=CASE WHEN remain=0 THEN now() ELSE received_date END WHERE id=v.id AND company_id=p_company_id AND status='Sent'; END IF;
 IF NOT FOUND THEN RAISE EXCEPTION 'فشل انتقال حالة الإذن'; END IF;
 RETURN jsonb_build_object('success',true,'voucher_code',p_voucher_code,'operation',p_operation,'status',(SELECT status FROM public.stock_vouchers WHERE id=v.id),'operation_id',p_operation_id);
END;$function$;
REVOKE ALL ON FUNCTION public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb,text) TO service_role;