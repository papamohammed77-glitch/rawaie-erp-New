-- TASK-028 — Reopen Loading Core
-- Current-only / no Production mutation.
-- Reopen reverses the physical Loading effect only:
-- VAN -> MAIN and restores MAIN allocation.
-- Persisted qty_loaded is preserved; order_details/run_sheet_details are not reset.

BEGIN;

-- Extend the central stock movement contract with a distinct ReopenLoading event.
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
SET search_path = public
AS $$
DECLARE
    v_source_required boolean := p_movement_type IN (
        'TransferOut','DirectSale','SupplierReturn','POSSale','VanSale',
        'PurchaseReturn','InventoryDecrease','Loading','Unloading','ReopenLoading'
    );
    v_target_required boolean := p_movement_type IN (
        'PurchaseIn','TransferIn','DirectReturn','SalesReturn',
        'InventoryIncrease','Loading','Unloading','ReopenLoading'
    );
    v_source_stock public.stock_branches%ROWTYPE;
    v_target_stock public.stock_branches%ROWTYPE;
    v_existing_log public.inventory_log%ROWTYPE;
    v_source_before numeric;
    v_source_after numeric;
    v_target_before numeric;
    v_target_after numeric;
    v_source_available numeric;
    v_branch_company uuid;
    v_log_code text;
BEGIN
    IF p_company_id IS NULL OR p_movement_type IS NULL THEN
        RAISE EXCEPTION 'company_id and movement_type are required';
    END IF;
    IF p_qty IS NULL OR p_qty <= 0 THEN
        RAISE EXCEPTION 'quantity must be greater than zero';
    END IF;
    IF p_movement_type NOT IN (
        'PurchaseIn','TransferOut','TransferIn','DirectSale','DirectReturn',
        'SupplierReturn','POSSale','VanSale','SalesReturn','PurchaseReturn',
        'InventoryIncrease','InventoryDecrease','Loading','Unloading','ReopenLoading'
    ) THEN
        RAISE EXCEPTION 'movement type is not supported by central inventory engine: %', p_movement_type;
    END IF;
    IF p_movement_type IN ('Loading','Unloading','ReopenLoading')
       AND NULLIF(btrim(p_idempotency_key),'') IS NULL THEN
        RAISE EXCEPTION 'event-level idempotency_key is required for Loading/Unloading/ReopenLoading';
    END IF;

    IF p_idempotency_key IS NOT NULL THEN
        SELECT * INTO v_existing_log
        FROM public.inventory_log
        WHERE company_id = p_company_id
          AND idempotency_key = p_idempotency_key
        LIMIT 1;
        IF FOUND THEN
            IF v_existing_log.movement_type <> p_movement_type
               OR v_existing_log.qty <> p_qty THEN
                RAISE EXCEPTION 'idempotency key conflict with an existing movement';
            END IF;
            RETURN jsonb_build_object(
                'success', true,
                'duplicate', true,
                'movement_type', v_existing_log.movement_type,
                'qty', v_existing_log.qty,
                'log_code', v_existing_log.log_code,
                'idempotency_key', v_existing_log.idempotency_key
            );
        END IF;
    END IF;

    IF v_source_required AND p_source_branch_id IS NULL THEN
        RAISE EXCEPTION 'source branch is required for %', p_movement_type;
    END IF;
    IF v_target_required AND p_target_branch_id IS NULL THEN
        RAISE EXCEPTION 'target branch is required for %', p_movement_type;
    END IF;
    IF v_source_required AND v_target_required
       AND p_source_branch_id = p_target_branch_id THEN
        RAISE EXCEPTION 'source and target branch cannot be identical';
    END IF;

    IF p_source_branch_id IS NOT NULL THEN
        SELECT company_id INTO v_branch_company
        FROM public.branches
        WHERE id = p_source_branch_id;
        IF v_branch_company IS NULL OR v_branch_company <> p_company_id THEN
            RAISE EXCEPTION 'source branch is missing or outside company context';
        END IF;
    END IF;

    IF p_target_branch_id IS NOT NULL THEN
        SELECT company_id INTO v_branch_company
        FROM public.branches
        WHERE id = p_target_branch_id;
        IF v_branch_company IS NULL OR v_branch_company <> p_company_id THEN
            RAISE EXCEPTION 'target branch is missing or outside company context';
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.items
        WHERE id = p_item_id
          AND company_id = p_company_id
    ) THEN
        RAISE EXCEPTION 'item is missing or outside company context';
    END IF;

    -- Deterministic row lock order prevents source/target inversion deadlocks.
    PERFORM 1
    FROM public.stock_branches sb
    WHERE sb.item_id = p_item_id
      AND sb.branch_id IN (p_source_branch_id, p_target_branch_id)
    ORDER BY sb.branch_id
    FOR UPDATE;

    -- Re-check idempotency after row locking for concurrent requests.
    IF p_idempotency_key IS NOT NULL THEN
        SELECT * INTO v_existing_log
        FROM public.inventory_log
        WHERE company_id = p_company_id
          AND idempotency_key = p_idempotency_key
        LIMIT 1;
        IF FOUND THEN
            IF v_existing_log.movement_type <> p_movement_type
               OR v_existing_log.qty <> p_qty THEN
                RAISE EXCEPTION 'idempotency key conflict with an existing movement';
            END IF;
            RETURN jsonb_build_object(
                'success', true,
                'duplicate', true,
                'movement_type', v_existing_log.movement_type,
                'qty', v_existing_log.qty,
                'log_code', v_existing_log.log_code,
                'idempotency_key', v_existing_log.idempotency_key
            );
        END IF;
    END IF;

    IF v_source_required THEN
        SELECT * INTO v_source_stock
        FROM public.stock_branches
        WHERE branch_id = p_source_branch_id
          AND item_id = p_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'source stock balance row is missing';
        END IF;

        v_source_before := COALESCE(v_source_stock.qty, 0);
        v_source_available := v_source_before - COALESCE(v_source_stock.allocated_qty, 0);

        IF p_movement_type = 'Loading' THEN
            IF v_source_before < p_qty
               OR COALESCE(v_source_stock.allocated_qty, 0) < p_qty THEN
                RAISE EXCEPTION 'insufficient picked reservation for Loading';
            END IF;
        ELSIF p_movement_type IN ('Unloading','ReopenLoading') THEN
            IF v_source_before < p_qty THEN
                RAISE EXCEPTION 'insufficient VAN physical stock for %', p_movement_type;
            END IF;
        ELSIF v_source_available < p_qty THEN
            RAISE EXCEPTION 'insufficient available stock';
        END IF;
    END IF;

    IF v_target_required THEN
        SELECT * INTO v_target_stock
        FROM public.stock_branches
        WHERE branch_id = p_target_branch_id
          AND item_id = p_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'target stock balance row is missing';
        END IF;
        v_target_before := COALESCE(v_target_stock.qty, 0);
    END IF;

    IF v_source_required THEN
        UPDATE public.stock_branches
        SET qty = v_source_stock.qty - p_qty,
            allocated_qty = v_source_stock.allocated_qty,
            updated_at = now()
        WHERE id = v_source_stock.id
          AND qty = v_source_stock.qty
          AND allocated_qty = v_source_stock.allocated_qty;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'source stock changed during posting';
        END IF;
        v_source_after := v_source_stock.qty - p_qty;
    END IF;

    IF p_movement_type = 'Loading' THEN
        UPDATE public.stock_branches
        SET allocated_qty = v_source_stock.allocated_qty - p_qty,
            updated_at = now()
        WHERE id = v_source_stock.id;
    END IF;

    IF v_target_required THEN
        UPDATE public.stock_branches
        SET qty = v_target_stock.qty + p_qty,
            allocated_qty = CASE
                WHEN p_movement_type IN ('Unloading','ReopenLoading')
                    THEN v_target_stock.allocated_qty + p_qty
                ELSE v_target_stock.allocated_qty
            END,
            updated_at = now()
        WHERE id = v_target_stock.id
          AND qty = v_target_stock.qty
          AND allocated_qty = v_target_stock.allocated_qty;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'target stock changed during posting';
        END IF;
        v_target_after := v_target_stock.qty + p_qty;
    END IF;

    v_log_code := 'STM-' || replace(gen_random_uuid()::text, '-', '');

    INSERT INTO public.inventory_log (
        company_id, log_code, movement_date, voucher_id, item_id,
        movement_type, qty, reference, user_email, idempotency_key
    ) VALUES (
        p_company_id, v_log_code, CURRENT_DATE, p_voucher_id, p_item_id,
        p_movement_type, p_qty, p_reference, p_user_email, p_idempotency_key
    );

    RETURN jsonb_build_object(
        'success', true,
        'duplicate', false,
        'movement_type', p_movement_type,
        'source_branch_id', p_source_branch_id,
        'target_branch_id', p_target_branch_id,
        'item_id', p_item_id,
        'qty', p_qty,
        'source_before_qty', v_source_before,
        'source_after_qty', v_source_after,
        'target_before_qty', v_target_before,
        'target_after_qty', v_target_after,
        'log_code', v_log_code,
        'idempotency_key', p_idempotency_key
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_reopen_loading(
    p_company_id uuid,
    p_runsheet_id uuid,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_vehicle public.vehicles%ROWTYPE;
    v_main uuid;
    v_van uuid;
    v_detail record;
    v_operation_hash text;
    v_key_base text;
    v_total numeric := 0;
    v_reversed integer := 0;
    v_item_id uuid;
BEGIN
    IF p_company_id IS NULL OR p_runsheet_id IS NULL THEN
        RAISE EXCEPTION 'company_id and runsheet_id are required';
    END IF;

    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE id = p_runsheet_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet not found';
    END IF;
    IF v_rs.company_id <> p_company_id THEN
        RAISE EXCEPTION 'runsheet outside company context';
    END IF;
    IF v_rs.status <> 'Loaded' THEN
        RAISE EXCEPTION 'runsheet is not in Loaded state: %', v_rs.status;
    END IF;
    IF v_rs.vehicle_id IS NULL
       OR v_rs.loader_start IS NULL
       OR v_rs.loader_end IS NULL THEN
        RAISE EXCEPTION 'completed loading cycle identity is incomplete';
    END IF;

    SELECT * INTO v_vehicle
    FROM public.vehicles
    WHERE id = v_rs.vehicle_id
      AND company_id = p_company_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'assigned vehicle not found';
    END IF;

    SELECT main_branch_id INTO v_main
    FROM public.app_settings
    WHERE company_id = p_company_id
    LIMIT 1;
    IF v_main IS NULL THEN
        RAISE EXCEPTION 'main branch not configured';
    END IF;

    SELECT id INTO v_van
    FROM public.branches
    WHERE company_id = p_company_id
      AND branch_code = 'VAN-' || v_vehicle.vehicle_code
      AND is_active = true
    LIMIT 1;
    IF v_van IS NULL THEN
        RAISE EXCEPTION 'canonical VAN branch not found';
    END IF;

    SELECT md5(
        COALESCE(
            string_agg(
                COALESCE(r.item_id::text, r.item_code) || ':' || COALESCE(r.qty_loaded, 0)::text,
                '|'
                ORDER BY COALESCE(r.item_id::text, r.item_code)
            ),
            ''
        )
    ) INTO v_operation_hash
    FROM public.run_sheet_details r
    WHERE r.runsheet_id = p_runsheet_id
      AND COALESCE(r.qty_loaded, 0) > 0;

    IF v_operation_hash = md5('') THEN
        RAISE EXCEPTION 'no persisted qty_loaded exists for ReopenLoading';
    END IF;

    -- loader_end is deliberately retained during Reopen. It distinguishes the
    -- completed loading cycle from the next completion event, while qty_loaded
    -- remains available to the user for editing.
    v_key_base := 'TASK-028|ReopenLoading|' ||
                  v_rs.id::text || '|' ||
                  v_rs.loader_start::text || '|' ||
                  v_rs.loader_end::text || '|' ||
                  v_operation_hash;

    FOR v_detail IN
        SELECT r.item_id, r.item_code, r.qty_loaded
        FROM public.run_sheet_details r
        WHERE r.runsheet_id = p_runsheet_id
          AND COALESCE(r.qty_loaded, 0) > 0
        ORDER BY COALESCE(r.item_id::text, r.item_code)
    LOOP
        v_item_id := v_detail.item_id;
        IF v_item_id IS NULL THEN
            SELECT id INTO v_item_id
            FROM public.items
            WHERE company_id = p_company_id
              AND item_code = v_detail.item_code
            LIMIT 1;
        END IF;
        IF v_item_id IS NULL THEN
            RAISE EXCEPTION 'item not found for ReopenLoading: %', v_detail.item_code;
        END IF;

        PERFORM public.post_stock_movement(
            p_company_id,
            'ReopenLoading',
            v_van,
            v_main,
            v_item_id,
            v_detail.qty_loaded,
            v_rs.runsheet_code,
            v_key_base || '|' || v_item_id::text,
            p_user_email,
            v_key_base || '|' || v_item_id::text
        );

        v_total := v_total + v_detail.qty_loaded;
        v_reversed := v_reversed + 1;
    END LOOP;

    -- Preserve qty_loaded and all fulfillment quantities for editing.
    -- Only the Runsheet lifecycle state changes here.
    UPDATE public.runsheets
    SET status = 'Loading',
        updated_at = now()
    WHERE id = p_runsheet_id
      AND status = 'Loaded';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet transition Loaded -> Loading failed';
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'duplicate', false,
        'runsheet_id', p_runsheet_id,
        'runsheet_code', v_rs.runsheet_code,
        'vehicle_id', v_vehicle.id,
        'vehicle_code', v_vehicle.vehicle_code,
        'van_branch_id', v_van,
        'reversed_total', v_total,
        'reversed_items', v_reversed,
        'qty_loaded_preserved', true,
        'loader_start', v_rs.loader_start,
        'loader_end_preserved_for_cycle_identity', true
    );
END;
$$;

-- Reuse the existing 9-argument compatibility overload for non-loading flows;
-- explicitly forbid accidental use of ReopenLoading without event identity.
CREATE OR REPLACE FUNCTION public.post_stock_movement(
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
SET search_path = public
AS $$
BEGIN
    IF p_movement_type IN ('Loading','Unloading','ReopenLoading') THEN
        RAISE EXCEPTION 'Loading/Unloading/ReopenLoading require the event-level idempotency key';
    END IF;
    RETURN public.post_stock_movement(
        p_company_id,p_movement_type,p_source_branch_id,p_target_branch_id,
        p_item_id,p_qty,p_voucher_id,p_reference,p_user_email,NULL
    );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_runsheet_reopen_loading(uuid,uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_reopen_loading(uuid,uuid,text) TO service_role;
REVOKE ALL ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text) TO service_role;

COMMIT;
