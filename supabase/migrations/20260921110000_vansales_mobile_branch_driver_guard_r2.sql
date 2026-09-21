-- RAWAEA ERP
-- Migration actually applied during the 2026-09-21 Van Sales integration closure.
-- This first guard revision was superseded immediately by R2 after forensic review.
-- It is retained in Git so canonical history matches Production migration history.

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
    SELECT 1
    FROM public.branches b
    WHERE b.id = p_source_branch_id
      AND b.company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'فرع المصدر لا يتبع الشركة';
  END IF;

  IF p_target_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.branches b
    WHERE b.id = p_target_branch_id
      AND b.company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'فرع الوجهة لا يتبع الشركة';
  END IF;

  IF p_movement_type = 'VanSale' THEN
    IF p_source_branch_id IS NULL THEN
      RAISE EXCEPTION 'VanSale يتطلب مخزن مركبة كمصدر';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.vehicles v
      JOIN public.users du
        ON du.id = v.driver_id
       AND du.company_id = p_company_id
      WHERE v.company_id = p_company_id
        AND v.status = 'Active'
        AND coalesce(v.mobile_stock_enabled, true) = true
        AND v.mobile_branch_id = p_source_branch_id
        AND lower(coalesce(du.email, '')) = lower(coalesce(p_user_email, ''))

    ) THEN
      RAISE EXCEPTION 'VanSale source branch must be the active mobile branch assigned to the authenticated driver';
    END IF;
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

REVOKE ALL ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)
  TO service_role;

COMMIT;