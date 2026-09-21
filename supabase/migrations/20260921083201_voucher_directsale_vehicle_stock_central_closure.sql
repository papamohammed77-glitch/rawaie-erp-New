-- RAWAEA ERP — warehouse vouchers DirectSale central closure
-- Production version: 20260921083201
-- No new Edge Function.
-- DirectSale is a physical movement from a branch to the mobile stock branch
-- of the destination vehicle. Target resolution prefers vehicles.mobile_branch_id
-- and falls back only to the verified VAN-<vehicle_code> legacy mapping.

BEGIN;

CREATE OR REPLACE FUNCTION public.post_stock_movement(
  p_company_id uuid,
  p_movement_type text,
  p_source_branch_id uuid,
  p_target_branch_id uuid,
  p_item_id uuid,
  p_qty numeric,
  p_voucher_id text,
  p_reference text,
  p_user_email text,
  p_idempotency_key text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_source public.stock_branches%ROWTYPE;
  v_target public.stock_branches%ROWTYPE;
  v_item public.items%ROWTYPE;
  v_existing public.inventory_log%ROWTYPE;
  v_move_qty numeric := coalesce(p_qty, 0);
BEGIN
  IF v_move_qty <= 0 THEN
    RAISE EXCEPTION 'كمية الحركة يجب أن تكون أكبر من صفر';
  END IF;

  IF p_movement_type NOT IN (
    'PurchaseIn','TransferOut','TransferIn','POSSale','VanSale','DirectSale',
    'SalesReturn','DirectReturn','SupplierReturn','InventoryIncrease',
    'InventoryDecrease','Loading','Unloading'
  ) THEN
    RAISE EXCEPTION 'نوع حركة مخزنية غير مدعوم: %', p_movement_type;
  END IF;

  IF nullif(btrim(p_idempotency_key), '') IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(
      hashtextextended(
        'RAWAEA:STOCK-IDEM:' || p_company_id::text || ':' || btrim(p_idempotency_key),
        0
      )
    );

    SELECT * INTO v_existing
    FROM public.inventory_log
    WHERE company_id = p_company_id
      AND idempotency_key = btrim(p_idempotency_key)
    LIMIT 1;

    IF FOUND THEN
      IF v_existing.movement_type <> p_movement_type
         OR v_existing.qty <> v_move_qty
         OR v_existing.voucher_id IS DISTINCT FROM p_voucher_id
         OR v_existing.reference IS DISTINCT FROM p_reference
         OR v_existing.source_branch_id IS DISTINCT FROM p_source_branch_id
         OR v_existing.target_branch_id IS DISTINCT FROM p_target_branch_id THEN
        RAISE EXCEPTION 'idempotency key conflict: نفس المفتاح استُخدم لحركة مختلفة';
      END IF;

      RETURN jsonb_build_object(
        'success', true,
        'duplicate', true,
        'inventory_log_id', v_existing.id,
        'movement_type', v_existing.movement_type,
        'qty', v_existing.qty
      );
    END IF;
  END IF;

  SELECT * INTO v_item
  FROM public.items
  WHERE id = p_item_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الصنف غير موجود';
  END IF;

  IF p_source_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id = p_source_branch_id AND b.company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'فرع المصدر لا يتبع الشركة';
  END IF;

  IF p_target_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id = p_target_branch_id AND b.company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'فرع الوجهة لا يتبع الشركة';
  END IF;

  IF p_movement_type = 'DirectSale' AND p_target_branch_id IS NULL THEN
    RAISE EXCEPTION 'DirectSale يتطلب مخزن مركبة كوجهة';
  END IF;

  IF p_source_branch_id IS NULL AND p_target_branch_id IS NULL THEN
    RAISE EXCEPTION 'يجب تحديد مصدر أو وجهة للحركة';
  END IF;

  IF p_movement_type IN (
    'TransferIn','PurchaseIn','SalesReturn','DirectReturn','InventoryIncrease',
    'DirectSale','Loading','Unloading'
  ) THEN
    IF p_target_branch_id IS NULL THEN
      RAISE EXCEPTION 'وجهة الحركة مطلوبة';
    END IF;

    INSERT INTO public.stock_branches(
      id, branch_id, item_id, qty, allocated_qty, updated_at
    )
    VALUES(
      gen_random_uuid(), p_target_branch_id, p_item_id, 0, 0, now()
    )
    ON CONFLICT (branch_id, item_id) DO NOTHING;
  END IF;

  PERFORM 1
  FROM public.stock_branches
  WHERE branch_id IN (p_source_branch_id, p_target_branch_id)
    AND item_id = p_item_id
  ORDER BY branch_id
  FOR UPDATE;

  IF p_movement_type IN (
    'TransferOut','POSSale','VanSale','DirectSale','SupplierReturn','InventoryDecrease','Loading','Unloading'
  ) THEN
    SELECT * INTO v_source
    FROM public.stock_branches
    WHERE branch_id = p_source_branch_id
      AND item_id = p_item_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'رصيد المصدر غير موجود';
    END IF;

    IF p_movement_type = 'Loading' THEN
      IF coalesce(v_source.allocated_qty, 0) < v_move_qty THEN
        RAISE EXCEPTION 'كمية التحميل تتجاوز الكمية المحجوزة';
      END IF;
      IF coalesce(v_source.qty, 0) < v_move_qty THEN
        RAISE EXCEPTION 'الرصيد الفعلي لا يكفي للحركة';
      END IF;
    ELSE
      IF coalesce(v_source.qty, 0) < v_move_qty THEN
        RAISE EXCEPTION 'الرصيد الفعلي لا يكفي للحركة';
      END IF;
      IF coalesce(v_source.qty, 0) - v_move_qty < coalesce(v_source.allocated_qty, 0) THEN
        RAISE EXCEPTION 'لا يمكن خفض الرصيد الفعلي أسفل الرصيد المحجوز';
      END IF;
    END IF;
  END IF;

  IF p_movement_type = 'Loading' THEN
    UPDATE public.stock_branches
    SET qty = qty - v_move_qty,
        allocated_qty = allocated_qty - v_move_qty,
        updated_at = now()
    WHERE branch_id = p_source_branch_id
      AND item_id = p_item_id;

    UPDATE public.stock_branches
    SET qty = qty + v_move_qty,
        updated_at = now()
    WHERE branch_id = p_target_branch_id
      AND item_id = p_item_id;

  ELSIF p_movement_type = 'Unloading' THEN
    IF p_source_branch_id IS NULL OR p_target_branch_id IS NULL THEN
      RAISE EXCEPTION 'حركة التفريغ تتطلب مصدر ووجهة';
    END IF;

    IF coalesce(v_source.qty, 0) < v_move_qty THEN
      RAISE EXCEPTION 'رصيد السيارة لا يكفي للتفريغ';
    END IF;

    UPDATE public.stock_branches
    SET qty = qty - v_move_qty,
        updated_at = now()
    WHERE branch_id = p_source_branch_id
      AND item_id = p_item_id;

    UPDATE public.stock_branches
    SET qty = qty + v_move_qty,
        updated_at = now()
    WHERE branch_id = p_target_branch_id
      AND item_id = p_item_id;

  ELSIF p_movement_type = 'DirectSale' THEN
    UPDATE public.stock_branches
    SET qty = qty - v_move_qty,
        updated_at = now()
    WHERE branch_id = p_source_branch_id
      AND item_id = p_item_id;

    UPDATE public.stock_branches
    SET qty = qty + v_move_qty,
        updated_at = now()
    WHERE branch_id = p_target_branch_id
      AND item_id = p_item_id;

  ELSIF p_movement_type IN (
    'TransferOut','POSSale','VanSale','SupplierReturn','InventoryDecrease'
  ) THEN
    UPDATE public.stock_branches
    SET qty = qty - v_move_qty,
        updated_at = now()
    WHERE branch_id = p_source_branch_id
      AND item_id = p_item_id;

  ELSIF p_movement_type IN (
    'TransferIn','PurchaseIn','SalesReturn','DirectReturn','InventoryIncrease'
  ) THEN
    UPDATE public.stock_branches
    SET qty = qty + v_move_qty,
        updated_at = now()
    WHERE branch_id = p_target_branch_id
      AND item_id = p_item_id;
  END IF;

  INSERT INTO public.inventory_log(
    id, company_id, log_code, movement_date, voucher_id, item_id,
    item_code, item_name, movement_type, qty, reference, user_email,
    created_at, idempotency_key, source_branch_id, target_branch_id
  )
  VALUES(
    gen_random_uuid(), p_company_id,
    'IL-' || replace(gen_random_uuid()::text, '-', ''),
    current_date, p_voucher_id, p_item_id,
    v_item.item_code, v_item.name, p_movement_type, v_move_qty,
    p_reference, p_user_email, now(),
    nullif(btrim(p_idempotency_key), ''),
    p_source_branch_id, p_target_branch_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'duplicate', false,
    'movement_type', p_movement_type,
    'qty', v_move_qty,
    'source_branch_id', p_source_branch_id,
    'target_branch_id', p_target_branch_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic_core_20260828(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
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

COMMIT;
