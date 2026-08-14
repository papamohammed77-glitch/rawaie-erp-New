-- TASK-028 Atomic Loading / Unloading Core v1
-- CURRENT-ONLY TARGET MIGRATION
-- IMPORTANT: Not executed against Production by this commit.

BEGIN;

CREATE TABLE IF NOT EXISTS public.fulfillment_backorders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid NOT NULL,
    order_id uuid NOT NULL,
    order_detail_id uuid NOT NULL,
    runsheet_id uuid NOT NULL,
    item_id uuid NOT NULL,
    item_code varchar,
    remaining_qty numeric NOT NULL CHECK (remaining_qty > 0),
    status varchar NOT NULL DEFAULT 'Pending'
        CHECK (status IN ('Pending','Cancelled','Consumed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (order_detail_id, runsheet_id)
);

CREATE INDEX IF NOT EXISTS idx_fulfillment_backorders_order
    ON public.fulfillment_backorders(order_id, status);

CREATE INDEX IF NOT EXISTS idx_fulfillment_backorders_runsheet
    ON public.fulfillment_backorders(runsheet_id, status);

ALTER TABLE public.fulfillment_backorders ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.fulfillment_backorders FROM PUBLIC;
REVOKE ALL ON TABLE public.fulfillment_backorders FROM anon;
GRANT SELECT ON TABLE public.fulfillment_backorders TO authenticated;
GRANT ALL ON TABLE public.fulfillment_backorders TO service_role;

CREATE OR REPLACE FUNCTION public.complete_runsheet_loading(
    p_company_id uuid,
    p_runsheet_id uuid,
    p_items jsonb,
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
    v_main_branch_id uuid;
    v_van_branch_id uuid;
    v_item jsonb;
    v_item_id uuid;
    v_item_code text;
    v_requested numeric;
    v_capacity numeric;
    v_remaining numeric;
    v_od record;
    v_stock record;
    v_source_qty numeric;
    v_source_allocated numeric;
    v_target_qty numeric;
    v_log_code text;
    v_loaded_total numeric := 0;
    v_backorder_count integer := 0;
BEGIN
    IF p_company_id IS NULL THEN
        RAISE EXCEPTION 'company_id is required';
    END IF;

    IF p_runsheet_id IS NULL THEN
        RAISE EXCEPTION 'runsheet_id is required';
    END IF;

    IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'items array is required';
    END IF;

    SELECT *
    INTO v_rs
    FROM public.runsheets
    WHERE id = p_runsheet_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet not found';
    END IF;

    IF v_rs.company_id <> p_company_id THEN
        RAISE EXCEPTION 'runsheet is outside company context';
    END IF;

    IF v_rs.status <> 'Loading' THEN
        RAISE EXCEPTION 'runsheet is not in Loading state: %', v_rs.status;
    END IF;

    IF v_rs.vehicle_id IS NULL THEN
        RAISE EXCEPTION 'runsheet vehicle is required before Loading';
    END IF;

    SELECT *
    INTO v_vehicle
    FROM public.vehicles
    WHERE id = v_rs.vehicle_id
      AND company_id = p_company_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'assigned vehicle not found for company';
    END IF;

    SELECT main_branch_id
    INTO v_main_branch_id
    FROM public.app_settings
    WHERE company_id = p_company_id
    LIMIT 1;

    IF v_main_branch_id IS NULL THEN
        RAISE EXCEPTION 'main branch is not configured';
    END IF;

    SELECT id
    INTO v_van_branch_id
    FROM public.branches
    WHERE company_id = p_company_id
      AND branch_code = 'VAN-' || v_vehicle.vehicle_code
      AND is_active = true
    LIMIT 1;

    IF v_van_branch_id IS NULL THEN
        RAISE EXCEPTION 'canonical VAN branch not found for vehicle %', v_vehicle.vehicle_code;
    END IF;

    -- Aggregate repeated item requests deterministically before changing stock.
    FOR v_item_code, v_requested IN
        SELECT x.item_code, SUM(x.loaded_qty)
        FROM jsonb_to_recordset(p_items)
             AS x(item_code text, loaded_qty numeric)
        GROUP BY x.item_code
    LOOP
        IF v_item_code IS NULL OR btrim(v_item_code) = '' THEN
            RAISE EXCEPTION 'item_code is required';
        END IF;

        IF v_requested IS NULL OR v_requested <= 0 THEN
            RAISE EXCEPTION 'loaded_qty must be greater than zero for %', v_item_code;
        END IF;

        SELECT id
        INTO v_item_id
        FROM public.items
        WHERE company_id = p_company_id
          AND item_code = v_item_code
        LIMIT 1;

        IF v_item_id IS NULL THEN
            RAISE EXCEPTION 'item not found for company: %', v_item_code;
        END IF;

        SELECT COALESCE(SUM(GREATEST(COALESCE(od.qty_picked,0) - COALESCE(od.qty_loaded,0), 0)), 0)
        INTO v_capacity
        FROM public.order_details od
        JOIN public.orders o ON o.id = od.order_id
        WHERE o.company_id = p_company_id
          AND o.runsheet_id = p_runsheet_id
          AND od.item_code = v_item_code;

        IF v_requested > v_capacity THEN
            RAISE EXCEPTION
                'loaded quantity exceeds picked capacity for %: requested %, capacity %',
                v_item_code, v_requested, v_capacity;
        END IF;

        -- Lock both stock rows in deterministic branch-id order to avoid
        -- load/unload lock inversion when multiple runsheets share a branch.
        PERFORM 1
        FROM public.stock_branches sb
        WHERE sb.item_id = v_item_id
          AND sb.branch_id IN (v_main_branch_id, v_van_branch_id)
        ORDER BY sb.branch_id
        FOR UPDATE;

        IF NOT EXISTS (
            SELECT 1 FROM public.stock_branches
            WHERE branch_id = v_main_branch_id AND item_id = v_item_id
        ) THEN
            RAISE EXCEPTION 'MAIN stock row missing for %', v_item_code;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM public.stock_branches
            WHERE branch_id = v_van_branch_id AND item_id = v_item_id
        ) THEN
            RAISE EXCEPTION 'VAN stock row missing for %', v_item_code;
        END IF;

        SELECT qty, allocated_qty
        INTO v_source_qty, v_source_allocated
        FROM public.stock_branches
        WHERE branch_id = v_main_branch_id
          AND item_id = v_item_id;

        SELECT qty
        INTO v_target_qty
        FROM public.stock_branches
        WHERE branch_id = v_van_branch_id
          AND item_id = v_item_id;

        IF (COALESCE(v_source_qty,0) - COALESCE(v_source_allocated,0)) < v_requested THEN
            RAISE EXCEPTION 'insufficient MAIN available stock for %', v_item_code;
        END IF;

        UPDATE public.stock_branches
        SET qty = qty - v_requested,
            allocated_qty = GREATEST(0, allocated_qty - v_requested),
            updated_at = now()
        WHERE branch_id = v_main_branch_id
          AND item_id = v_item_id;

        UPDATE public.stock_branches
        SET qty = qty + v_requested,
            updated_at = now()
        WHERE branch_id = v_van_branch_id
          AND item_id = v_item_id;

        -- Distribute the aggregate item quantity over the individual order lines
        -- without exceeding each line's picked capacity. The existing DB trigger
        -- will recompute run_sheet_details from these authoritative rows.
        v_remaining := v_requested;

        FOR v_od IN
            SELECT od.id,
                   COALESCE(od.qty_picked,0) AS qty_picked,
                   COALESCE(od.qty_loaded,0) AS qty_loaded
            FROM public.order_details od
            JOIN public.orders o ON o.id = od.order_id
            WHERE o.company_id = p_company_id
              AND o.runsheet_id = p_runsheet_id
              AND od.item_code = v_item_code
              AND GREATEST(COALESCE(od.qty_picked,0) - COALESCE(od.qty_loaded,0),0) > 0
            ORDER BY od.id
            FOR UPDATE OF od
        LOOP
            EXIT WHEN v_remaining <= 0;

            DECLARE
                v_delta numeric;
            BEGIN
                v_delta := LEAST(
                    v_remaining,
                    GREATEST(v_od.qty_picked - v_od.qty_loaded, 0)
                );

                IF v_delta > 0 THEN
                    UPDATE public.order_details
                    SET qty_loaded = COALESCE(qty_loaded,0) + v_delta,
                        reason_loading = CASE
                            WHEN COALESCE(qty_picked,0) > COALESCE(qty_loaded,0) + v_delta
                            THEN 'Partial Loading'
                            ELSE reason_loading
                        END,
                        updated_at = now()
                    WHERE id = v_od.id;

                    v_remaining := v_remaining - v_delta;
                END IF;
            END;
        END LOOP;

        IF v_remaining <> 0 THEN
            RAISE EXCEPTION 'failed to allocate loaded quantity across order lines for %', v_item_code;
        END IF;

        v_log_code := 'LOD-' || replace(p_runsheet_id::text, '-', '') || '-' || replace(v_item_id::text, '-', '');

        INSERT INTO public.inventory_log (
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
            v_rs.runsheet_code,
            v_item_id,
            v_item_code,
            i.name,
            'Loading',
            v_requested,
            v_rs.runsheet_code,
            p_user_email
        FROM public.items i
        WHERE i.id = v_item_id;

        -- Persist one backorder ledger row per still-unfulfilled original order line.
        FOR v_od IN
            SELECT od.id AS order_detail_id,
                   od.order_id,
                   od.qty AS ordered_qty,
                   od.qty_loaded,
                   od.item_id,
                   od.item_code
            FROM public.order_details od
            JOIN public.orders o ON o.id = od.order_id
            WHERE o.company_id = p_company_id
              AND o.runsheet_id = p_runsheet_id
              AND od.item_code = v_item_code
              AND COALESCE(od.qty,0) > COALESCE(od.qty_loaded,0)
            FOR UPDATE OF od
        LOOP
            INSERT INTO public.fulfillment_backorders (
                company_id, order_id, order_detail_id, runsheet_id,
                item_id, item_code, remaining_qty, status
            )
            VALUES (
                p_company_id,
                v_od.order_id,
                v_od.order_detail_id,
                p_runsheet_id,
                v_od.item_id,
                v_od.item_code,
                GREATEST(v_od.ordered_qty - COALESCE(v_od.qty_loaded,0), 0),
                'Pending'
            )
            ON CONFLICT (order_detail_id, runsheet_id)
            DO UPDATE SET
                remaining_qty = EXCLUDED.remaining_qty,
                updated_at = now(),
                status = 'Pending';

            v_backorder_count := v_backorder_count + 1;
        END LOOP;

        v_loaded_total := v_loaded_total + v_requested;
    END LOOP;

    UPDATE public.runsheets
    SET status = 'Loaded',
        loader_end = now(),
        updated_at = now()
    WHERE id = p_runsheet_id
      AND status = 'Loading';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet state transition to Loaded failed';
    END IF;

    UPDATE public.orders
    SET order_status = 'Loaded',
        updated_at = now()
    WHERE company_id = p_company_id
      AND runsheet_id = p_runsheet_id;

    RETURN jsonb_build_object(
        'success', true,
        'runsheet_id', p_runsheet_id,
        'runsheet_code', v_rs.runsheet_code,
        'vehicle_id', v_vehicle.id,
        'vehicle_code', v_vehicle.vehicle_code,
        'van_branch_id', v_van_branch_id,
        'loaded_total', v_loaded_total,
        'backorder_lines', v_backorder_count
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_unloading(
    p_company_id uuid,
    p_runsheet_code text,
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
    v_main_branch_id uuid;
    v_van_branch_id uuid;
    v_detail record;
    v_source_qty numeric;
    v_target_qty numeric;
    v_log_code text;
    v_unloaded_total numeric := 0;
BEGIN
    IF p_company_id IS NULL THEN
        RAISE EXCEPTION 'company_id is required';
    END IF;

    IF p_runsheet_code IS NULL OR btrim(p_runsheet_code) = '' THEN
        RAISE EXCEPTION 'runsheet_code is required';
    END IF;

    SELECT *
    INTO v_rs
    FROM public.runsheets
    WHERE company_id = p_company_id
      AND runsheet_code = p_runsheet_code
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet not found';
    END IF;

    IF v_rs.status <> 'Loaded' THEN
        RAISE EXCEPTION 'runsheet is not in Loaded state: %', v_rs.status;
    END IF;

    IF v_rs.vehicle_id IS NULL THEN
        RAISE EXCEPTION 'runsheet vehicle is required for Unloading';
    END IF;

    SELECT *
    INTO v_vehicle
    FROM public.vehicles
    WHERE id = v_rs.vehicle_id
      AND company_id = p_company_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'assigned vehicle not found for company';
    END IF;

    SELECT main_branch_id
    INTO v_main_branch_id
    FROM public.app_settings
    WHERE company_id = p_company_id
    LIMIT 1;

    IF v_main_branch_id IS NULL THEN
        RAISE EXCEPTION 'main branch is not configured';
    END IF;

    SELECT id
    INTO v_van_branch_id
    FROM public.branches
    WHERE company_id = p_company_id
      AND branch_code = 'VAN-' || v_vehicle.vehicle_code
      AND is_active = true
    LIMIT 1;

    IF v_van_branch_id IS NULL THEN
        RAISE EXCEPTION 'canonical VAN branch not found for vehicle %', v_vehicle.vehicle_code;
    END IF;

    FOR v_detail IN
        SELECT item_id, item_code, item_name, qty_loaded
        FROM public.run_sheet_details
        WHERE runsheet_id = v_rs.id
          AND COALESCE(qty_loaded,0) > 0
        ORDER BY item_id
    LOOP
        -- Lock both branches in deterministic order before reading quantities.
        PERFORM 1
        FROM public.stock_branches sb
        WHERE sb.item_id = v_detail.item_id
          AND sb.branch_id IN (v_main_branch_id, v_van_branch_id)
        ORDER BY sb.branch_id
        FOR UPDATE;

        IF NOT EXISTS (
            SELECT 1 FROM public.stock_branches
            WHERE branch_id = v_main_branch_id AND item_id = v_detail.item_id
        ) THEN
            RAISE EXCEPTION 'MAIN stock row missing for %', v_detail.item_code;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM public.stock_branches
            WHERE branch_id = v_van_branch_id AND item_id = v_detail.item_id
        ) THEN
            RAISE EXCEPTION 'VAN stock row missing for %', v_detail.item_code;
        END IF;

        SELECT qty
        INTO v_source_qty
        FROM public.stock_branches
        WHERE branch_id = v_van_branch_id
          AND item_id = v_detail.item_id;

        SELECT qty
        INTO v_target_qty
        FROM public.stock_branches
        WHERE branch_id = v_main_branch_id
          AND item_id = v_detail.item_id;

        IF COALESCE(v_source_qty,0) < v_detail.qty_loaded THEN
            RAISE EXCEPTION 'insufficient VAN stock for % during Unloading', v_detail.item_code;
        END IF;

        UPDATE public.stock_branches
        SET qty = qty - v_detail.qty_loaded,
            updated_at = now()
        WHERE branch_id = v_van_branch_id
          AND item_id = v_detail.item_id;

        UPDATE public.stock_branches
        SET qty = qty + v_detail.qty_loaded,
            updated_at = now()
        WHERE branch_id = v_main_branch_id
          AND item_id = v_detail.item_id;

        v_log_code := 'UNL-' || replace(v_rs.id::text, '-', '') || '-' || replace(v_detail.item_id::text, '-', '');

        INSERT INTO public.inventory_log (
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
        VALUES (
            p_company_id,
            v_log_code,
            CURRENT_DATE,
            v_rs.runsheet_code,
            v_detail.item_id,
            v_detail.item_code,
            COALESCE(v_detail.item_name, v_detail.item_code),
            'Unloading',
            v_detail.qty_loaded,
            v_rs.runsheet_code,
            p_user_email
        );

        v_unloaded_total := v_unloaded_total + v_detail.qty_loaded;
    END LOOP;

    -- Reset authoritative order-detail loaded quantities. The existing trigger
    -- will recompute run_sheet_details from these rows.
    UPDATE public.order_details od
    SET qty_loaded = 0,
        updated_at = now()
    FROM public.orders o
    WHERE od.order_id = o.id
      AND o.company_id = p_company_id
      AND o.runsheet_id = v_rs.id
      AND COALESCE(od.qty_loaded,0) > 0;

    UPDATE public.fulfillment_backorders
    SET status = 'Cancelled',
        updated_at = now()
    WHERE runsheet_id = v_rs.id
      AND status = 'Pending';

    UPDATE public.runsheets
    SET status = 'Picked',
        loader_end = NULL,
        updated_at = now()
    WHERE id = v_rs.id
      AND status = 'Loaded';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet state transition to Picked failed';
    END IF;

    UPDATE public.orders
    SET order_status = 'Pending',
        updated_at = now()
    WHERE company_id = p_company_id
      AND runsheet_id = v_rs.id;

    RETURN jsonb_build_object(
        'success', true,
        'runsheet_code', v_rs.runsheet_code,
        'vehicle_id', v_vehicle.id,
        'vehicle_code', v_vehicle.vehicle_code,
        'van_branch_id', v_van_branch_id,
        'unloaded_total', v_unloaded_total
    );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_runsheet_unloading(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_unloading(uuid,text,text) TO service_role;

COMMIT;
