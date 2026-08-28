BEGIN;

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_voucher public.stock_vouchers%ROWTYPE;
  d record;
  v_source uuid;
  v_target uuid;
  v_vehicle_branch uuid;
  movement text;
  key text;
  r jsonb;
  expected_count integer:=0;
  existing_count integer:=0;
BEGIN
  SELECT * INTO v_actor FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;
  IF NOT ((coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb)
      OR coalesce(v_actor.active_warehouse_role,'')='أذونات'
      OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام')) THEN
    RAISE EXCEPTION 'المستخدم غير مخول بإرسال الأذونات المخزنية';
  END IF;
  SELECT * INTO v_voucher FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Voucher not found'; END IF;
  SELECT count(*) INTO expected_count FROM (
    SELECT svd.item_id,svd.item_code FROM public.stock_voucher_details svd
    WHERE svd.voucher_id=v_voucher.id AND COALESCE(svd.qty,0)>0
    GROUP BY svd.item_id,svd.item_code) g;
  SELECT count(*) INTO existing_count FROM public.inventory_log il
  WHERE il.company_id=p_company_id
    AND il.idempotency_key LIKE 'StockVoucherSend:'||p_company_id::text||':'||v_voucher.id::text||':%';
  IF expected_count>0 AND existing_count=expected_count THEN
    RETURN jsonb_build_object('success',true,'duplicate',true,'voucher_id',v_voucher.id,
      'voucher_code',p_voucher_code,'status',v_voucher.status,'movement_count',existing_count);
  END IF;
  IF v_voucher.status<>'Draft' THEN RAISE EXCEPTION 'Voucher is not Draft'; END IF;
  IF v_voucher.type NOT IN('Transfer','DirectSale','DirectReturn','SupplierReturn') THEN
    RAISE EXCEPTION 'Unsupported send movement type: %',v_voucher.type;
  END IF;
  v_target:=NULL;
  IF v_voucher.from_type='Branch' THEN v_source:=v_voucher.from_id;
  ELSIF v_voucher.from_type='Vehicle' THEN
    SELECT b.id INTO v_source FROM public.vehicles v
    JOIN public.branches b ON b.company_id=v.company_id
      AND upper(b.branch_code)=upper('VAN-'||v.vehicle_code)
    WHERE v.id=v_voucher.from_id AND v.company_id=p_company_id
      AND COALESCE(v.status,'Active')='Active' LIMIT 1;
  END IF;
  IF v_source IS NULL OR NOT EXISTS(
    SELECT 1 FROM public.branches b WHERE b.id=v_source AND b.company_id=p_company_id) THEN
    RAISE EXCEPTION 'Source stock context invalid';
  END IF;
  IF v_voucher.type='DirectSale' THEN
    SELECT b.id INTO v_vehicle_branch FROM public.vehicles v
    JOIN public.branches b ON b.company_id=v.company_id
      AND upper(b.branch_code)=upper('VAN-'||v.vehicle_code)
    WHERE v.id=v_voucher.to_id AND v.company_id=p_company_id
      AND COALESCE(v.status,'Active')='Active' LIMIT 1;
    IF v_vehicle_branch IS NULL THEN RAISE EXCEPTION 'Destination vehicle stock branch is not initialized'; END IF;
    v_target:=v_vehicle_branch; movement:='DirectSale';
  ELSIF v_voucher.type='DirectReturn' THEN
    IF v_voucher.from_type<>'Vehicle' OR v_voucher.to_type<>'Branch' OR v_voucher.to_id IS NULL THEN
      RAISE EXCEPTION 'DirectReturn requires Vehicle source and Branch destination';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=v_voucher.to_id AND b.company_id=p_company_id) THEN
      RAISE EXCEPTION 'DirectReturn destination branch context invalid';
    END IF;
    v_target:=NULL; movement:='InventoryDecrease';
  ELSE
    movement:=CASE v_voucher.type WHEN 'Transfer' THEN 'TransferOut' WHEN 'SupplierReturn' THEN 'SupplierReturn' END;
  END IF;
  FOR d IN
    SELECT svd.item_id,svd.item_code,SUM(svd.qty) qty
    FROM public.stock_voucher_details svd WHERE svd.voucher_id=v_voucher.id
    GROUP BY svd.item_id,svd.item_code ORDER BY svd.item_id
  LOOP
    IF COALESCE(d.qty,0)<=0 THEN CONTINUE; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.items i WHERE i.id=d.item_id AND i.item_code=d.item_code) THEN
      RAISE EXCEPTION 'Item identity invalid: %',d.item_code;
    END IF;
    key:=CASE WHEN v_voucher.type='DirectReturn'
      THEN 'DirectReturnOut:'||p_company_id::text||':'||v_voucher.id::text||':'||d.item_id::text
      ELSE 'StockVoucherSend:'||p_company_id::text||':'||v_voucher.id::text||':'||d.item_id::text END;
    SELECT public.post_stock_movement(p_company_id,movement,v_source,v_target,d.item_id,d.qty,
      p_voucher_code,p_voucher_code,p_user_email,key) INTO r;
  END LOOP;
  UPDATE public.stock_vouchers SET status='Sent',sent_date=now(),updated_at=now()
  WHERE id=v_voucher.id AND company_id=p_company_id AND status='Draft';
  IF NOT FOUND THEN RAISE EXCEPTION 'Failed to update voucher state'; END IF;
  RETURN jsonb_build_object('success',true,'voucher_id',v_voucher.id,'voucher_code',p_voucher_code,
    'status','Sent','movement_count',expected_count);
END;
$function$;

CREATE OR REPLACE FUNCTION public.post_manual_stock_voucher_atomic(
  p_company_id uuid,p_voucher_code text,p_operation text,p_user_email text,p_effects jsonb,
  p_operation_id text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE; v public.stock_vouchers%ROWTYPE; e record;
  v_detail_qty numeric; v_received_before numeric; movement text; idem text; src uuid; tgt uuid;
  vehicle_branch uuid; remain integer:=0; movement_result jsonb; requested_fp text; existing_fp text;
BEGIN
  SELECT * INTO v_actor FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;
  IF NOT ((coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb)
      OR coalesce(v_actor.active_warehouse_role,'')='أذونات'
      OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام')) THEN
    RAISE EXCEPTION 'المستخدم غير مخول بتنفيذ دورة الأذونات المخزنية';
  END IF;
  IF p_operation NOT IN ('SEND','RECEIVE') THEN RAISE EXCEPTION 'عملية مخزنية غير مدعومة'; END IF;
  IF p_effects IS NULL OR jsonb_typeof(p_effects)<>'array' OR jsonb_array_length(p_effects)=0 THEN
    RAISE EXCEPTION 'لا توجد حركات مخزنية للتنفيذ';
  END IF;
  IF EXISTS(SELECT 1 FROM jsonb_to_recordset(p_effects) AS x(direction text,branch_id uuid,item_id uuid,item_code text,qty numeric)
            GROUP BY x.item_id HAVING count(*)>1) THEN
    RAISE EXCEPTION 'لا يجوز تكرار الصنف داخل نفس عملية الحركة';
  END IF;
  SELECT * INTO v FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;
  IF p_operation='RECEIVE' THEN
    IF v.type NOT IN ('Transfer','DirectReturn') THEN RAISE EXCEPTION 'هذا النوع من الأذونات لا يملك مرحلة استلام: %',v.type; END IF;
    IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id مطلوب للاستلام'; END IF;
    SELECT string_agg(x.item_id::text||':'||(x.qty::double precision)::text,'|' ORDER BY x.item_id)
      INTO requested_fp FROM jsonb_to_recordset(p_effects) AS x(direction text,branch_id uuid,item_id uuid,item_code text,qty numeric);
    SELECT string_agg(il.item_id::text||':'||(il.qty::double precision)::text,'|' ORDER BY il.item_id)
      INTO existing_fp FROM public.inventory_log il
      WHERE il.company_id=p_company_id
        AND il.idempotency_key LIKE 'ManualVoucher:RECEIVE:'||p_company_id::text||':'||v.id::text||':'||p_operation_id||':%';
    IF existing_fp IS NOT NULL THEN
      IF existing_fp<>requested_fp THEN RAISE EXCEPTION 'idempotency key conflict: نفس operation_id استُخدم مع حركة مختلفة'; END IF;
      RETURN jsonb_build_object('success',true,'duplicate',true,'voucher_code',p_voucher_code,'operation','RECEIVE','status',v.status,'operation_id',p_operation_id);
    END IF;
    IF v.status<>'Sent' THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالاستلام'; END IF;
  ELSE
    IF v.status<>'Draft' THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالإرسال'; END IF;
  END IF;
  FOR e IN SELECT * FROM jsonb_to_recordset(p_effects) AS x(direction text,branch_id uuid,item_id uuid,item_code text,qty numeric) LOOP
    IF e.qty IS NULL OR e.qty<=0 OR e.branch_id IS NULL OR e.item_id IS NULL OR e.item_code IS NULL THEN RAISE EXCEPTION 'بيانات حركة مخزنية غير صالحة'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=e.branch_id AND b.company_id=p_company_id) THEN RAISE EXCEPTION 'الفرع غير موجود أو لا يتبع الشركة'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.items i WHERE i.id=e.item_id AND i.item_code=e.item_code) THEN RAISE EXCEPTION 'الصنف غير متسق مع دليل الأصناف'; END IF;
    SELECT d.qty,coalesce(d.received_qty,0) INTO v_detail_qty,v_received_before
      FROM public.stock_voucher_details d WHERE d.voucher_id=v.id AND d.item_id=e.item_id AND d.item_code=e.item_code FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'الصنف غير موجود في تفاصيل الإذن'; END IF;
    IF p_operation='SEND' THEN
      IF e.direction<>'OUT' OR v.type NOT IN('Transfer','DirectSale','DirectReturn','SupplierReturn') THEN RAISE EXCEPTION 'اتجاه الإرسال لا يطابق الإذن'; END IF;
      IF e.qty<>v_detail_qty THEN RAISE EXCEPTION 'كمية الإرسال لا تطابق تفاصيل الإذن'; END IF;
      IF v.type='DirectReturn' THEN
        IF v.from_type<>'Vehicle' THEN RAISE EXCEPTION 'مصدر المرتجع المباشر يجب أن يكون مركبة'; END IF;
        SELECT b.id INTO vehicle_branch FROM public.vehicles vv
        JOIN public.branches b ON b.company_id=vv.company_id AND upper(b.branch_code)=upper('VAN-'||vv.vehicle_code)
        WHERE vv.id=v.from_id AND vv.company_id=p_company_id AND coalesce(vv.status,'Active')='Active' LIMIT 1;
        IF vehicle_branch IS NULL OR e.branch_id<>vehicle_branch THEN RAISE EXCEPTION 'فرع مخزون المركبة غير متسق مع الإذن'; END IF;
        movement:='InventoryDecrease'; src:=vehicle_branch; tgt:=NULL;
        idem:='DirectReturnOut:'||p_company_id::text||':'||v.id::text||':'||e.item_id::text;
      ELSE
        IF v.from_type<>'Branch' OR e.branch_id<>v.from_id THEN RAISE EXCEPTION 'اتجاه المصدر لا يطابق الإذن'; END IF;
        src:=v.from_id; tgt:=NULL;
        movement:=CASE v.type WHEN 'Transfer' THEN 'TransferOut' WHEN 'DirectSale' THEN 'DirectSale' WHEN 'SupplierReturn' THEN 'SupplierReturn' END;
        idem:='StockVoucherSend:'||p_company_id::text||':'||v.id::text||':'||e.item_id::text;
      END IF;
    ELSE
      IF e.direction<>'IN' THEN RAISE EXCEPTION 'اتجاه الاستلام لا يطابق الإذن'; END IF;
      IF e.qty>(v_detail_qty-v_received_before) THEN RAISE EXCEPTION 'الكمية المستلمة أكبر من المتبقي'; END IF;
      IF v.to_type<>'Branch' OR e.branch_id<>v.to_id THEN RAISE EXCEPTION 'وجهة الاستلام لا تطابق الإذن'; END IF;
      tgt:=v.to_id; src:=NULL;
      movement:=CASE v.type WHEN 'Transfer' THEN 'TransferIn' WHEN 'DirectReturn' THEN 'DirectReturn' END;
      idem:='ManualVoucher:RECEIVE:'||p_company_id::text||':'||v.id::text||':'||p_operation_id::text||':'||e.item_id::text;
    END IF;
    movement_result:=public.post_stock_movement(p_company_id,movement,src,tgt,e.item_id,e.qty,p_voucher_code,p_voucher_code,p_user_email,idem);
    IF p_operation='RECEIVE' AND coalesce((movement_result->>'duplicate')::boolean,false)=false THEN
      UPDATE public.stock_voucher_details SET received_qty=coalesce(received_qty,0)+e.qty
      WHERE voucher_id=v.id AND item_id=e.item_id AND item_code=e.item_code;
      IF NOT FOUND THEN RAISE EXCEPTION 'تعذر تحديث الكمية المستلمة'; END IF;
    END IF;
  END LOOP;
  IF p_operation='SEND' THEN
    UPDATE public.stock_vouchers SET status='Sent',sent_date=now(),updated_at=now()
    WHERE id=v.id AND company_id=p_company_id AND status='Draft';
  ELSE
    SELECT count(*) INTO remain FROM public.stock_voucher_details sd
    WHERE sd.voucher_id=v.id AND coalesce(sd.received_qty,0)<sd.qty;
    UPDATE public.stock_vouchers SET status=CASE WHEN remain=0 THEN 'Received' ELSE 'Sent' END,
      received_date=CASE WHEN remain=0 THEN now() ELSE received_date END,updated_at=now()
    WHERE id=v.id AND company_id=p_company_id AND status='Sent';
  END IF;
  IF NOT FOUND THEN RAISE EXCEPTION 'فشل انتقال حالة الإذن'; END IF;
  RETURN jsonb_build_object('success',true,'voucher_code',p_voucher_code,'operation',p_operation,
    'status',(SELECT status FROM public.stock_vouchers WHERE id=v.id),'operation_id',p_operation_id);
END;
$function$;

COMMIT;
