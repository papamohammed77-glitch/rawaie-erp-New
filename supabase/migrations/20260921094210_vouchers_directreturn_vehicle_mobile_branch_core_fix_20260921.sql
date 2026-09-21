-- RAWAEA ERP — send-stock-voucher vehicle mobile-branch alias correction
-- Surgical fix: v.mobile_branch_id -> v_vehicle.mobile_branch_id.
-- No business workflow change and no new Edge Function.

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic_core_20260828(p_company_id uuid, p_voucher_code text, p_user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_voucher public.stock_vouchers%ROWTYPE;
  d record;
  v_source uuid;
  v_target uuid;
  v_vehicle_branch uuid;
  v_mobile_branch uuid;
  movement text;
  key text;
  r jsonb;
  expected_count integer:=0;
  existing_count integer:=0;
BEGIN
  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ';
  END IF;

  IF NOT (
    (coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb)
    OR coalesce(v_actor.active_warehouse_role,'')='أذونات'
    OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام')
  ) THEN
    RAISE EXCEPTION 'المستخدم غير مخول بإرسال الأذونات المخزنية';
  END IF;

  SELECT * INTO v_voucher
  FROM public.stock_vouchers
  WHERE company_id=p_company_id
    AND voucher_code=p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Voucher not found';
  END IF;

  SELECT count(*) INTO expected_count
  FROM (
    SELECT svd.item_id,svd.item_code
    FROM public.stock_voucher_details svd
    WHERE svd.voucher_id=v_voucher.id
      AND COALESCE(svd.qty,0)>0
    GROUP BY svd.item_id,svd.item_code
  ) g;

  SELECT count(*) INTO existing_count
  FROM public.inventory_log il
  WHERE il.company_id=p_company_id
    AND il.idempotency_key LIKE
      'StockVoucherSend:'||p_company_id::text||':'||v_voucher.id::text||':%';

  IF expected_count>0 AND existing_count=expected_count THEN
    RETURN jsonb_build_object(
      'success',true,'duplicate',true,
      'voucher_id',v_voucher.id,
      'voucher_code',p_voucher_code,
      'status',v_voucher.status,
      'movement_count',existing_count
    );
  END IF;

  IF v_voucher.status<>'Draft' THEN
    RAISE EXCEPTION 'Voucher is not Draft';
  END IF;

  IF v_voucher.type NOT IN('Transfer','DirectSale','DirectReturn','SupplierReturn') THEN
    RAISE EXCEPTION 'Unsupported send movement type: %',v_voucher.type;
  END IF;

  IF v_voucher.from_type='Branch' THEN
    v_source:=v_voucher.from_id;
  ELSIF v_voucher.from_type='Vehicle' THEN
    SELECT coalesce(
      (
        SELECT mb.id
        FROM public.branches mb
        WHERE mb.id=v_vehicle.mobile_branch_id
          AND mb.company_id=p_company_id
          AND mb.is_active=true
      ),
      (
        SELECT lb.id
        FROM public.branches lb
        WHERE lb.company_id=p_company_id
          AND upper(lb.branch_code)=upper('VAN-'||v_vehicle.vehicle_code)
          AND lb.is_active=true
      )
    )
    INTO v_source
    FROM public.vehicles v_vehicle
    WHERE v_vehicle.id=v_voucher.from_id
      AND v_vehicle.company_id=p_company_id
      AND coalesce(v_vehicle.status,'Active')='Active'
      AND coalesce(v_vehicle.mobile_stock_enabled,true)=true;

    IF v_source IS NULL THEN
      RAISE EXCEPTION 'Vehicle source stock context invalid';
    END IF;
  END IF;

  IF v_source IS NULL OR NOT EXISTS(
    SELECT 1
    FROM public.branches b
    WHERE b.id=v_source
      AND b.company_id=p_company_id
      AND b.is_active=true
  ) THEN
    RAISE EXCEPTION 'Source stock context invalid';
  END IF;

  v_target:=NULL;

  IF v_voucher.type='DirectSale' THEN
    SELECT coalesce(
      (
        SELECT mb.id
        FROM public.branches mb
        WHERE mb.id=v.mobile_branch_id
          AND mb.company_id=p_company_id
          AND mb.is_active=true
      ),
      (
        SELECT lb.id
        FROM public.branches lb
        WHERE lb.company_id=p_company_id
          AND upper(lb.branch_code)=upper('VAN-'||v.vehicle_code)
          AND lb.is_active=true
      )
    )
    INTO v_target
    FROM public.vehicles v
    WHERE v.id=v_voucher.to_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;

    IF v_target IS NULL THEN
      RAISE EXCEPTION 'Destination vehicle stock branch is not initialized';
    END IF;

    movement:='DirectSale';

  ELSIF v_voucher.type='DirectReturn' THEN
    IF v_voucher.from_type<>'Vehicle'
       OR v_voucher.to_type<>'Branch'
       OR v_voucher.to_id IS NULL THEN
      RAISE EXCEPTION 'DirectReturn requires Vehicle source and Branch destination';
    END IF;

    IF NOT EXISTS(
      SELECT 1
      FROM public.branches b
      WHERE b.id=v_voucher.to_id
        AND b.company_id=p_company_id
        AND b.is_active=true
    ) THEN
      RAISE EXCEPTION 'DirectReturn destination branch context invalid';
    END IF;

    v_target:=NULL;
    movement:='InventoryDecrease';

  ELSE
    movement:=CASE
      WHEN v_voucher.type='Transfer' THEN 'TransferOut'
      WHEN v_voucher.type='SupplierReturn' THEN 'SupplierReturn'
    END;
  END IF;

  FOR d IN
    SELECT svd.item_id,svd.item_code,SUM(svd.qty) qty
    FROM public.stock_voucher_details svd
    WHERE svd.voucher_id=v_voucher.id
    GROUP BY svd.item_id,svd.item_code
    ORDER BY svd.item_id
  LOOP
    IF COALESCE(d.qty,0)<=0 THEN CONTINUE; END IF;

    IF NOT EXISTS(
      SELECT 1
      FROM public.items i
      WHERE i.id=d.item_id
        AND i.item_code=d.item_code
    ) THEN
      RAISE EXCEPTION 'Item identity invalid: %',d.item_code;
    END IF;

    key:=CASE
      WHEN v_voucher.type='DirectReturn'
        THEN 'DirectReturnOut:'||p_company_id::text||':'||v_voucher.id::text||':'||d.item_id::text
      ELSE
        'StockVoucherSend:'||p_company_id::text||':'||v_voucher.id::text||':'||d.item_id::text
    END;

    SELECT public.post_stock_movement(
      p_company_id,movement,v_source,v_target,d.item_id,d.qty,
      p_voucher_code,p_voucher_code,p_user_email,key
    ) INTO r;
  END LOOP;

  UPDATE public.stock_vouchers
  SET status='Sent',
      sent_date=now(),
      updated_at=now()
  WHERE id=v_voucher.id
    AND company_id=p_company_id
    AND status='Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Failed to update voucher state';
  END IF;

  RETURN jsonb_build_object(
    'success',true,
    'voucher_id',v_voucher.id,
    'voucher_code',p_voucher_code,
    'status','Sent',
    'movement_count',expected_count
  );
END;
$function$;
