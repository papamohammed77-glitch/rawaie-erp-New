-- RAWAEA ERP — Inventory Centralization Forward Migration
-- Physical stock movement owner: public.post_stock_movement
-- reserve_stock remains reservation-only; setup_van_stock remains initialization-only.

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE
  v_voucher public.stock_vouchers%ROWTYPE;
  d record;
  v_main uuid;
  v_source uuid;
  m text;
  move_count integer := 0;
  key text;
BEGIN
  SELECT * INTO v_voucher
  FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Voucher not found'; END IF;
  IF v_voucher.status<>'Draft' THEN RAISE EXCEPTION 'Voucher is not Draft'; END IF;
  IF v_voucher.type NOT IN('Transfer','DirectSale','SupplierReturn') THEN
    RAISE EXCEPTION 'Unsupported send movement type: %',v_voucher.type;
  END IF;

  SELECT main_branch_id INTO STRICT v_main
  FROM public.app_settings WHERE company_id=p_company_id;

  v_source:=COALESCE(v_voucher.from_id,v_main);

  IF NOT EXISTS(
    SELECT 1 FROM public.branches b
    WHERE b.id=v_source AND b.company_id=p_company_id
  ) THEN
    RAISE EXCEPTION 'Source branch context invalid';
  END IF;

  m:=CASE v_voucher.type
    WHEN 'Transfer' THEN 'TransferOut'
    WHEN 'DirectSale' THEN 'DirectSale'
    WHEN 'SupplierReturn' THEN 'SupplierReturn'
  END;

  FOR d IN
    SELECT svd.item_id,svd.item_code,SUM(svd.qty) AS qty
    FROM public.stock_voucher_details svd
    WHERE svd.voucher_id=v_voucher.id
    GROUP BY svd.item_id,svd.item_code
    ORDER BY svd.item_id
  LOOP
    IF COALESCE(d.qty,0)<=0 THEN CONTINUE; END IF;

    IF NOT EXISTS(
      SELECT 1 FROM public.items i
      WHERE i.id=d.item_id
        AND i.company_id=p_company_id
        AND i.item_code=d.item_code
    ) THEN
      RAISE EXCEPTION 'Item context invalid: %',d.item_code;
    END IF;

    key:='StockVoucherSend:'||p_company_id::text||':'||
         v_voucher.id::text||':'||d.item_id::text;

    PERFORM public.post_stock_movement(
      p_company_id,m,v_source,NULL,d.item_id,d.qty,
      p_voucher_code,p_voucher_code,p_user_email,key
    );

    move_count:=move_count+1;
  END LOOP;

  UPDATE public.stock_vouchers
  SET status='Sent',sent_date=now()
  WHERE id=v_voucher.id
    AND company_id=p_company_id
    AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'Failed to update voucher state'; END IF;

  RETURN jsonb_build_object(
    'success',true,
    'voucher_id',v_voucher.id,
    'voucher_code',p_voucher_code,
    'status','Sent',
    'movement_count',move_count
  );
END;
$$;

DROP FUNCTION IF EXISTS public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb);

CREATE FUNCTION public.post_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_operation text,
  p_user_email text,
  p_effects jsonb
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE
  v public.stock_vouchers%ROWTYPE;
  e record;
  v_detail_qty numeric;
  v_received_before numeric;
  movement text;
  idem text;
  src uuid;
  tgt uuid;
  remain integer:=0;
BEGIN
  SELECT * INTO v
  FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;
  IF p_operation NOT IN('SEND','RECEIVE') THEN RAISE EXCEPTION 'عملية مخزنية غير مدعومة'; END IF;
  IF p_operation='SEND' AND v.status<>'Draft' THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالإرسال'; END IF;
  IF p_operation='RECEIVE' AND v.status<>'Sent' THEN RAISE EXCEPTION 'حالة الإذن لا تسمح بالاستلام'; END IF;
  IF p_effects IS NULL OR jsonb_typeof(p_effects)<>'array' OR jsonb_array_length(p_effects)=0 THEN
    RAISE EXCEPTION 'لا توجد حركات مخزنية للتنفيذ';
  END IF;

  FOR e IN SELECT * FROM jsonb_to_recordset(p_effects) AS x(direction text,branch_id uuid,item_id uuid,item_code text,qty numeric)
  LOOP
    IF e.qty IS NULL OR e.qty<=0 OR e.branch_id IS NULL OR e.item_id IS NULL OR e.item_code IS NULL THEN
      RAISE EXCEPTION 'بيانات حركة مخزنية غير صالحة';
    END IF;

    IF NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=e.branch_id AND b.company_id=p_company_id) THEN
      RAISE EXCEPTION 'الفرع غير موجود أو لا يتبع الشركة';
    END IF;

    IF NOT EXISTS(
      SELECT 1 FROM public.items i
      WHERE i.id=e.item_id AND i.company_id=p_company_id AND i.item_code=e.item_code
    ) THEN
      RAISE EXCEPTION 'الصنف غير متسق مع سياق الشركة';
    END IF;

    SELECT d.qty,coalesce(d.received_qty,0)
    INTO v_detail_qty,v_received_before
    FROM public.stock_voucher_details d
    WHERE d.voucher_id=v.id
      AND d.item_id=e.item_id
      AND d.item_code=e.item_code
    FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'الصنف غير موجود في تفاصيل الإذن'; END IF;

    IF p_operation='SEND' THEN
      IF e.direction<>'OUT' OR e.branch_id<>v.from_id OR v.type NOT IN('Transfer','DirectSale','SupplierReturn') THEN
        RAISE EXCEPTION 'اتجاه الإرسال لا يطابق الإذن';
      END IF;
      IF e.qty<>v_detail_qty THEN RAISE EXCEPTION 'كمية الإرسال لا تطابق تفاصيل الإذن'; END IF;
      movement:=CASE v.type
        WHEN 'Transfer' THEN 'TransferOut'
        WHEN 'DirectSale' THEN 'DirectSale'
        WHEN 'SupplierReturn' THEN 'SupplierReturn'
      END;
      src:=v.from_id;
      tgt:=NULL;
    ELSE
      IF e.direction<>'IN' OR e.branch_id<>v.to_id OR v.type NOT IN('Transfer','DirectReturn') THEN
        RAISE EXCEPTION 'اتجاه الاستلام لا يطابق الإذن';
      END IF;
      IF e.qty > (v_detail_qty-v_received_before) THEN RAISE EXCEPTION 'الكمية المستلمة أكبر من المتبقي'; END IF;
      movement:=CASE v.type
        WHEN 'Transfer' THEN 'TransferIn'
        WHEN 'DirectReturn' THEN 'DirectReturn'
      END;
      src:=NULL;
      tgt:=v.to_id;
    END IF;

    idem:='ManualVoucher:'||p_operation||':'||p_company_id::text||':'||
          v.id::text||':'||e.item_id::text||':'||e.qty::text;

    PERFORM public.post_stock_movement(
      p_company_id,movement,src,tgt,e.item_id,e.qty,
      p_voucher_code,p_voucher_code,p_user_email,idem
    );

    IF p_operation='RECEIVE' THEN
      UPDATE public.stock_voucher_details
      SET received_qty=coalesce(received_qty,0)+e.qty
      WHERE voucher_id=v.id
        AND item_id=e.item_id
        AND item_code=e.item_code;
      IF NOT FOUND THEN RAISE EXCEPTION 'تعذر تحديث الكمية المستلمة'; END IF;
    END IF;
  END LOOP;

  IF p_operation='SEND' THEN
    UPDATE public.stock_vouchers
    SET status='Sent',sent_date=now()
    WHERE id=v.id AND company_id=p_company_id AND status='Draft';
  ELSE
    SELECT count(*) INTO remain
    FROM public.stock_voucher_details sd
    WHERE sd.voucher_id=v.id
      AND coalesce(sd.received_qty,0)<sd.qty;

    UPDATE public.stock_vouchers
    SET status=CASE WHEN remain=0 THEN 'Received' ELSE 'Sent' END,
        received_date=CASE WHEN remain=0 THEN now() ELSE received_date END
    WHERE id=v.id AND company_id=p_company_id AND status='Sent';
  END IF;

  IF NOT FOUND THEN RAISE EXCEPTION 'فشل انتقال حالة الإذن'; END IF;

  RETURN jsonb_build_object(
    'success',true,
    'voucher_code',p_voucher_code,
    'operation',p_operation,
    'status',(SELECT status FROM public.stock_vouchers WHERE id=v.id)
  );
END;
$$;
