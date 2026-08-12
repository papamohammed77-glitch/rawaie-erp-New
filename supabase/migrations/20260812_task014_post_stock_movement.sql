-- TASK-014 — Stock Engine Implementation
-- Target boundary: public.post_stock_movement
-- Based on persisted Production schema evidence and TARGET — RAWAEA CENTRAL INVENTORY & STOCK MOVEMENT DESIGN.
-- This migration creates the central physical-stock posting primitive only.
-- No existing Voucher RPC / Edge Function consumer is rewired by this migration.

BEGIN;

DO $$
BEGIN
  IF to_regprocedure('public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'TASK-014 safety stop: public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text) already exists; inspect deployed definition before replacement.';
  END IF;
END
$$;

CREATE FUNCTION public.post_stock_movement(
    p_company_id uuid,
    p_movement_type text,
    p_source_branch_id uuid,
    p_target_branch_id uuid,
    p_item_id uuid,
    p_qty numeric,
    p_voucher_id text,
    p_reference text,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_stock stock_branches%rowtype;
    v_available numeric;
    v_before_qty numeric;
    v_after_qty numeric;
    v_branch_id uuid;
    v_log_code text;
    v_source_required boolean;
    v_target_required boolean;
BEGIN
    IF p_company_id IS NULL THEN
        RAISE EXCEPTION 'company_id is required';
    END IF;

    IF p_movement_type IS NULL THEN
        RAISE EXCEPTION 'movement_type is required';
    END IF;

    IF p_qty IS NULL OR p_qty <= 0 THEN
        RAISE EXCEPTION 'quantity must be greater than zero';
    END IF;

    IF p_movement_type NOT IN (
        'PurchaseIn',
        'TransferOut',
        'TransferIn',
        'POSSale',
        'VanSale',
        'SalesReturn',
        'PurchaseReturn',
        'InventoryIncrease',
        'InventoryDecrease'
    ) THEN
        RAISE EXCEPTION 'movement type is not supported by TASK-014: %', p_movement_type;
    END IF;

    v_source_required := p_movement_type IN (
        'TransferOut',
        'POSSale',
        'VanSale',
        'PurchaseReturn',
        'InventoryDecrease'
    );

    v_target_required := p_movement_type IN (
        'PurchaseIn',
        'TransferIn',
        'SalesReturn',
        'InventoryIncrease'
    );

    IF v_source_required AND p_source_branch_id IS NULL THEN
        RAISE EXCEPTION 'source branch is required for movement type %', p_movement_type;
    END IF;

    IF v_target_required AND p_target_branch_id IS NULL THEN
        RAISE EXCEPTION 'target branch is required for movement type %', p_movement_type;
    END IF;

    IF p_movement_type IN ('TransferOut','TransferIn')
       AND p_source_branch_id IS NOT NULL
       AND p_target_branch_id IS NOT NULL
       AND p_source_branch_id = p_target_branch_id THEN
        RAISE EXCEPTION 'source and target branch cannot be identical';
    END IF;

    IF p_source_branch_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM branches b
            WHERE b.id = p_source_branch_id
              AND b.company_id = p_company_id
        ) THEN
            RAISE EXCEPTION 'source branch is missing or outside company context';
        END IF;
    END IF;

    IF p_target_branch_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM branches b
            WHERE b.id = p_target_branch_id
              AND b.company_id = p_company_id
        ) THEN
            RAISE EXCEPTION 'target branch is missing or outside company context';
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM items i
        WHERE i.id = p_item_id
          AND i.company_id = p_company_id
    ) THEN
        RAISE EXCEPTION 'item is missing or outside company context';
    END IF;

    v_branch_id := CASE
        WHEN v_source_required THEN p_source_branch_id
        ELSE p_target_branch_id
    END;

    SELECT *
    INTO v_stock
    FROM stock_branches
    WHERE branch_id = v_branch_id
      AND item_id = p_item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'stock balance row is missing for branch/item';
    END IF;

    v_before_qty := COALESCE(v_stock.qty, 0);
    v_available := v_before_qty - COALESCE(v_stock.allocated_qty, 0);

    IF v_source_required THEN
        IF v_available < p_qty THEN
            RAISE EXCEPTION 'insufficient available stock';
        END IF;

        UPDATE stock_branches
        SET qty = v_stock.qty - p_qty,
            updated_at = now()
        WHERE id = v_stock.id
          AND qty = v_stock.qty
          AND allocated_qty = v_stock.allocated_qty
          AND qty >= allocated_qty + p_qty;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'stock changed during posting';
        END IF;

        v_after_qty := v_stock.qty - p_qty;
    ELSE
        UPDATE stock_branches
        SET qty = v_stock.qty + p_qty,
            updated_at = now()
        WHERE id = v_stock.id
          AND qty = v_stock.qty
          AND allocated_qty = v_stock.allocated_qty;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'stock changed during posting';
        END IF;

        v_after_qty := v_stock.qty + p_qty;
    END IF;

    v_log_code := 'STM-' || replace(gen_random_uuid()::text, '-', '');

    INSERT INTO inventory_log (
        company_id,
        log_code,
        movement_date,
        voucher_id,
        item_id,
        item_code,
        item_name,
        movement_type,
        qty,
        reference,
        user_email
    )
    SELECT
        p_company_id,
        v_log_code,
        CURRENT_DATE,
        p_voucher_id,
        i.id,
        i.item_code,
        COALESCE(i.name, i.item_code),
        p_movement_type,
        p_qty,
        p_reference,
        p_user_email
    FROM items i
    WHERE i.id = p_item_id
      AND i.company_id = p_company_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'item disappeared during inventory log write';
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'movement_type', p_movement_type,
        'branch_id', v_branch_id,
        'item_id', p_item_id,
        'qty', p_qty,
        'before_qty', v_before_qty,
        'after_qty', v_after_qty,
        'allocated_qty', v_stock.allocated_qty,
        'available_qty_before', v_available,
        'log_code', v_log_code
    );
END;
$function$;

-- ============================================================
-- TASK-014 deployment verification (self-cleaning)
-- The function persists; all stock/log test effects are rolled back.
-- ============================================================
SAVEPOINT task014_test;

DO $$
DECLARE
    v_company uuid := 'da4ef704-88ac-4120-aa0e-65b92b2aa2bc';
    v_source uuid := '151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6';
    v_target uuid := 'a08568e5-40a7-4b15-85b4-ced8ebf9971d';
    v_item uuid := 'ef864b14-ec62-4b9f-9932-17da041b6e42';
    v_before_source numeric;
    v_before_target numeric;
    v_before_alloc_source numeric;
    v_before_alloc_target numeric;
    v_before_logs bigint;
    v_after_source numeric;
    v_after_target numeric;
    v_after_alloc_source numeric;
    v_after_alloc_target numeric;
    v_after_logs bigint;
    v_result jsonb;
BEGIN
    SELECT qty, allocated_qty
    INTO v_before_source, v_before_alloc_source
    FROM stock_branches
    WHERE branch_id = v_source AND item_id = v_item;

    SELECT qty, allocated_qty
    INTO v_before_target, v_before_alloc_target
    FROM stock_branches
    WHERE branch_id = v_target AND item_id = v_item;

    IF v_before_source IS NULL OR v_before_target IS NULL THEN
        RAISE EXCEPTION 'TASK-014 test fixture stock rows are missing';
    END IF;

    SELECT count(*)
    INTO v_before_logs
    FROM inventory_log
    WHERE voucher_id = 'TASK-014-ENGINE-TEST';

    v_result := public.post_stock_movement(
        v_company,
        'TransferOut',
        v_source,
        NULL,
        v_item,
        1,
        'TASK-014-ENGINE-TEST',
        'TASK-014 transactional engine test OUT',
        'test-operator@rawaea.local'
    );

    IF NOT COALESCE((v_result->>'success')::boolean, false) THEN
        RAISE EXCEPTION 'TransferOut test did not return success';
    END IF;

    v_result := public.post_stock_movement(
        v_company,
        'TransferIn',
        NULL,
        v_target,
        v_item,
        1,
        'TASK-014-ENGINE-TEST',
        'TASK-014 transactional engine test IN',
        'test-operator@rawaea.local'
    );

    IF NOT COALESCE((v_result->>'success')::boolean, false) THEN
        RAISE EXCEPTION 'TransferIn test did not return success';
    END IF;

    SELECT qty, allocated_qty
    INTO v_after_source, v_after_alloc_source
    FROM stock_branches
    WHERE branch_id = v_source AND item_id = v_item;

    SELECT qty, allocated_qty
    INTO v_after_target, v_after_alloc_target
    FROM stock_branches
    WHERE branch_id = v_target AND item_id = v_item;

    SELECT count(*)
    INTO v_after_logs
    FROM inventory_log
    WHERE voucher_id = 'TASK-014-ENGINE-TEST';

    IF v_after_source <> v_before_source - 1
       OR v_after_target <> v_before_target + 1
       OR v_after_alloc_source <> v_before_alloc_source
       OR v_after_alloc_target <> v_before_alloc_target
       OR v_after_logs <> v_before_logs + 2 THEN
        RAISE EXCEPTION 'TASK-014 verification mismatch after engine posting';
    END IF;
END
$$;

ROLLBACK TO SAVEPOINT task014_test;

-- Final deployment check inside the same transaction.
DO $$
BEGIN
    IF to_regprocedure('public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text)') IS NULL THEN
        RAISE EXCEPTION 'TASK-014 deployment verification failed: function not present';
    END IF;
END
$$;

COMMIT;
