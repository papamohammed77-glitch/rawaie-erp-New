-- RAWAEA ERP — TASK-028 FINAL RELEASE MIGRATION
-- One coherent deployable migration for Loading lifecycle.
-- Consolidates lifecycle state, central stock boundary, Backorder ledger,
-- event idempotency, Reopen/Reload semantics, and run-sheet trigger integrity.
-- Production is intentionally untouched by repository change.

BEGIN;

-- ============================================================
-- 1. Durable fulfillment backorder ledger
-- ============================================================
CREATE TABLE IF NOT EXISTS public.fulfillment_backorders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid NOT NULL REFERENCES public.companies(id),
    order_id uuid NOT NULL REFERENCES public.orders(id),
    order_detail_id uuid NOT NULL REFERENCES public.order_details(id),
    runsheet_id uuid NOT NULL REFERENCES public.runsheets(id),
    item_id uuid NOT NULL REFERENCES public.items(id),
    item_code varchar,
    remaining_qty numeric NOT NULL CHECK (remaining_qty > 0),
    status varchar NOT NULL DEFAULT 'Pending'
        CHECK (status IN ('Pending','Cancelled','Consumed')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (order_detail_id, runsheet_id)
);

CREATE INDEX IF NOT EXISTS idx_fulfillment_backorders_order
    ON public.fulfillment_backorders(order_id,status);
CREATE INDEX IF NOT EXISTS idx_fulfillment_backorders_runsheet
    ON public.fulfillment_backorders(runsheet_id,status);

ALTER TABLE public.fulfillment_backorders ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.fulfillment_backorders FROM PUBLIC;
REVOKE ALL ON TABLE public.fulfillment_backorders FROM anon;
GRANT ALL ON TABLE public.fulfillment_backorders TO service_role;

-- ============================================================
-- 2. Event-level idempotency and run-sheet aggregation integrity
-- ============================================================
ALTER TABLE public.inventory_log
    ADD COLUMN IF NOT EXISTS idempotency_key text;

CREATE UNIQUE INDEX IF NOT EXISTS ux_inventory_log_company_idempotency
    ON public.inventory_log(company_id,idempotency_key)
    WHERE idempotency_key IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_run_sheet_details_runsheet_item
    ON public.run_sheet_details(runsheet_id,item_code);

CREATE OR REPLACE FUNCTION public.sync_run_sheet_details()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    target_runsheet_id uuid;
    v_item_id uuid;
    v_item_code text;
BEGIN
    IF TG_OP='DELETE' THEN
        v_item_code := OLD.item_code;
        SELECT runsheet_id INTO target_runsheet_id
        FROM public.orders WHERE id=OLD.order_id;
    ELSE
        v_item_code := NEW.item_code;
        SELECT runsheet_id INTO target_runsheet_id
        FROM public.orders WHERE id=NEW.order_id;
    END IF;

    IF target_runsheet_id IS NULL THEN
        IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
    END IF;

    SELECT id INTO v_item_id
    FROM public.items
    WHERE item_code=v_item_code
    LIMIT 1;

    INSERT INTO public.run_sheet_details(
        runsheet_id,item_id,item_code,item_name,unit,unit_price,
        qty_ordered,qty_picked,qty_loaded,qty_delivered,
        qty_refused,qty_returned,driver_liability
    )
    SELECT
        target_runsheet_id,
        v_item_id,
        v_item_code,
        MAX(od.item_name),
        MAX(od.unit),
        MAX(od.unit_price),
        COALESCE(SUM(od.qty),0),
        COALESCE(SUM(od.qty_picked),0),
        COALESCE(SUM(od.qty_loaded),0),
        COALESCE(SUM(od.qty_delivered),0),
        COALESCE(SUM(od.qty_refused),0),
        COALESCE(SUM(od.qty_returned),0),
        COALESCE(SUM(od.driver_liability),0)
    FROM public.order_details od
    JOIN public.orders o ON od.order_id=o.id
    WHERE o.runsheet_id=target_runsheet_id
      AND od.item_code=v_item_code
    ON CONFLICT(runsheet_id,item_code)
    DO UPDATE SET
        item_id=EXCLUDED.item_id,
        item_name=EXCLUDED.item_name,
        unit=EXCLUDED.unit,
        unit_price=EXCLUDED.unit_price,
        qty_ordered=EXCLUDED.qty_ordered,
        qty_picked=EXCLUDED.qty_picked,
        qty_loaded=EXCLUDED.qty_loaded,
        qty_delivered=EXCLUDED.qty_delivered,
        qty_refused=EXCLUDED.qty_refused,
        qty_returned=EXCLUDED.qty_returned,
        driver_liability=EXCLUDED.driver_liability,
        updated_at=now();

    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_run_sheet_details ON public.order_details;
CREATE TRIGGER trg_sync_run_sheet_details
AFTER INSERT OR DELETE OR UPDATE ON public.order_details
FOR EACH ROW EXECUTE FUNCTION public.sync_run_sheet_details();

-- ============================================================
-- 3. Central physical stock movement boundary
-- ============================================================
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
SET search_path=public
AS $$
DECLARE
    v_source_required boolean := p_movement_type IN (
        'TransferOut','DirectSale','SupplierReturn','POSSale','VanSale',
        'PurchaseReturn','InventoryDecrease','Loading','Unloading'
    );
    v_target_required boolean := p_movement_type IN (
        'PurchaseIn','TransferIn','DirectReturn','SalesReturn',
        'InventoryIncrease','Loading','Unloading'
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
    IF p_qty IS NULL OR p_qty<=0 THEN
        RAISE EXCEPTION 'quantity must be greater than zero';
    END IF;
    IF p_movement_type NOT IN (
        'PurchaseIn','TransferOut','TransferIn','DirectSale','DirectReturn',
        'SupplierReturn','POSSale','VanSale','SalesReturn','PurchaseReturn',
        'InventoryIncrease','InventoryDecrease','Loading','Unloading'
    ) THEN
        RAISE EXCEPTION 'movement type is not supported by central inventory engine: %',p_movement_type;
    END IF;
    IF p_movement_type IN ('Loading','Unloading')
       AND NULLIF(btrim(p_idempotency_key),'') IS NULL THEN
        RAISE EXCEPTION 'event-level idempotency_key is required for Loading/Unloading';
    END IF;

    IF p_idempotency_key IS NOT NULL THEN
        SELECT * INTO v_existing_log
        FROM public.inventory_log
        WHERE company_id=p_company_id
          AND idempotency_key=p_idempotency_key
        LIMIT 1;
        IF FOUND THEN
            IF v_existing_log.movement_type<>p_movement_type
               OR v_existing_log.qty<>p_qty THEN
                RAISE EXCEPTION 'idempotency key conflict with an existing movement';
            END IF;
            RETURN jsonb_build_object(
                'success',true,
                'duplicate',true,
                'movement_type',v_existing_log.movement_type,
                'qty',v_existing_log.qty,
                'log_code',v_existing_log.log_code,
                'idempotency_key',v_existing_log.idempotency_key
            );
        END IF;
    END IF;

    IF v_source_required AND p_source_branch_id IS NULL THEN
        RAISE EXCEPTION 'source branch is required for %',p_movement_type;
    END IF;
    IF v_target_required AND p_target_branch_id IS NULL THEN
        RAISE EXCEPTION 'target branch is required for %',p_movement_type;
    END IF;
    IF v_source_required AND v_target_required
       AND p_source_branch_id=p_target_branch_id THEN
        RAISE EXCEPTION 'source and target branch cannot be identical';
    END IF;

    IF p_source_branch_id IS NOT NULL THEN
        SELECT company_id INTO v_branch_company
        FROM public.branches WHERE id=p_source_branch_id;
        IF v_branch_company IS NULL OR v_branch_company<>p_company_id THEN
            RAISE EXCEPTION 'source branch is missing or outside company context';
        END IF;
    END IF;

    IF p_target_branch_id IS NOT NULL THEN
        SELECT company_id INTO v_branch_company
        FROM public.branches WHERE id=p_target_branch_id;
        IF v_branch_company IS NULL OR v_branch_company<>p_company_id THEN
            RAISE EXCEPTION 'target branch is missing or outside company context';
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.items
        WHERE id=p_item_id AND company_id=p_company_id
    ) THEN
        RAISE EXCEPTION 'item is missing or outside company context';
    END IF;

    -- Lock source/target rows in deterministic branch-id order.
    PERFORM 1
    FROM public.stock_branches sb
    WHERE sb.item_id=p_item_id
      AND sb.branch_id IN (p_source_branch_id,p_target_branch_id)
    ORDER BY sb.branch_id
    FOR UPDATE;

    -- Re-check idempotency after row locking for concurrent requests.
    IF p_idempotency_key IS NOT NULL THEN
        SELECT * INTO v_existing_log
        FROM public.inventory_log
        WHERE company_id=p_company_id
          AND idempotency_key=p_idempotency_key
        LIMIT 1;
        IF FOUND THEN
            IF v_existing_log.movement_type<>p_movement_type
               OR v_existing_log.qty<>p_qty THEN
                RAISE EXCEPTION 'idempotency key conflict with an existing movement';
            END IF;
            RETURN jsonb_build_object(
                'success',true,
                'duplicate',true,
                'movement_type',v_existing_log.movement_type,
                'qty',v_existing_log.qty,
                'log_code',v_existing_log.log_code,
                'idempotency_key',v_existing_log.idempotency_key
            );
        END IF;
    END IF;

    IF v_source_required THEN
        SELECT * INTO v_source_stock
        FROM public.stock_branches
        WHERE branch_id=p_source_branch_id
          AND item_id=p_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'source stock balance row is missing';
        END IF;

        v_source_before:=COALESCE(v_source_stock.qty,0);
        v_source_available:=v_source_before-COALESCE(v_source_stock.allocated_qty,0);

        IF p_movement_type='Loading' THEN
            IF v_source_before<p_qty
               OR COALESCE(v_source_stock.allocated_qty,0)<p_qty THEN
                RAISE EXCEPTION 'insufficient picked reservation for Loading';
            END IF;
        ELSIF p_movement_type='Unloading' THEN
            IF v_source_before<p_qty THEN
                RAISE EXCEPTION 'insufficient VAN physical stock for Unloading';
            END IF;
        ELSIF v_source_available<p_qty THEN
            RAISE EXCEPTION 'insufficient available stock';
        END IF;
    END IF;

    IF v_target_required THEN
        SELECT * INTO v_target_stock
        FROM public.stock_branches
        WHERE branch_id=p_target_branch_id
          AND item_id=p_item_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'target stock balance row is missing';
        END IF;
        v_target_before:=COALESCE(v_target_stock.qty,0);
    END IF;

    IF v_source_required THEN
        UPDATE public.stock_branches
        SET qty=v_source_stock.qty-p_qty,
            allocated_qty=CASE
                WHEN p_movement_type='Loading'
                    THEN v_source_stock.allocated_qty-p_qty
                ELSE v_source_stock.allocated_qty
            END,
            updated_at=now()
        WHERE id=v_source_stock.id
          AND qty=v_source_stock.qty
          AND allocated_qty=v_source_stock.allocated_qty;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'source stock changed during posting';
        END IF;
        v_source_after:=v_source_stock.qty-p_qty;
    END IF;

    IF v_target_required THEN
        UPDATE public.stock_branches
        SET qty=v_target_stock.qty+p_qty,
            allocated_qty=CASE
                WHEN p_movement_type='Unloading'
                    THEN v_target_stock.allocated_qty+p_qty
                ELSE v_target_stock.allocated_qty
            END,
            updated_at=now()
        WHERE id=v_target_stock.id
          AND qty=v_target_stock.qty
          AND allocated_qty=v_target_stock.allocated_qty;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'target stock changed during posting';
        END IF;
        v_target_after:=v_target_stock.qty+p_qty;
    END IF;

    v_log_code:='STM-'||replace(gen_random_uuid()::text,'-','');
    INSERT INTO public.inventory_log(
        company_id,log_code,movement_date,voucher_id,item_id,
        movement_type,qty,reference,user_email,idempotency_key
    ) VALUES (
        p_company_id,v_log_code,CURRENT_DATE,p_voucher_id,p_item_id,
        p_movement_type,p_qty,p_reference,p_user_email,p_idempotency_key
    );

    RETURN jsonb_build_object(
        'success',true,
        'duplicate',false,
        'movement_type',p_movement_type,
        'source_branch_id',p_source_branch_id,
        'target_branch_id',p_target_branch_id,
        'item_id',p_item_id,
        'qty',p_qty,
        'source_before_qty',v_source_before,
        'source_after_qty',v_source_after,
        'target_before_qty',v_target_before,
        'target_after_qty',v_target_after,
        'log_code',v_log_code,
        'idempotency_key',p_idempotency_key
    );
END;
$$;

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
SET search_path=public
AS $$
BEGIN
    IF p_movement_type IN ('Loading','Unloading') THEN
        RAISE EXCEPTION 'Loading/Unloading require the event-level idempotency key';
    END IF;
    RETURN public.post_stock_movement(
        p_company_id,p_movement_type,p_source_branch_id,p_target_branch_id,
        p_item_id,p_qty,p_voucher_id,p_reference,p_user_email,NULL
    );
END;
$$;

-- ============================================================
-- 4. Loading lifecycle state transitions
-- ============================================================
CREATE OR REPLACE FUNCTION public.start_runsheet_loading(
    p_company_id uuid,
    p_runsheet_code text,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_user public.users%ROWTYPE;
    v_active text;
BEGIN
    IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code),'') IS NULL THEN
        RAISE EXCEPTION 'company_id and runsheet_code are required';
    END IF;

    SELECT * INTO v_user
    FROM public.users
    WHERE email=p_user_email AND company_id=p_company_id
    LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'user is not registered in the company context';
    END IF;

    SELECT runsheet_code INTO v_active
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND status='Loading'
      AND loader_id=v_user.id
    LIMIT 1;
    IF v_active IS NOT NULL THEN
        RAISE EXCEPTION 'user already has a Loading runsheet: %',v_active;
    END IF;

    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND runsheet_code=p_runsheet_code
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.status<>'Picked' THEN
        RAISE EXCEPTION 'runsheet is not Picked: %',v_rs.status;
    END IF;

    UPDATE public.runsheets
    SET status='Loading',loader_id=v_user.id,loader_start=now(),updated_at=now()
    WHERE id=v_rs.id AND status='Picked';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet transition Picked -> Loading failed';
    END IF;

    RETURN jsonb_build_object(
        'success',true,'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,
        'status','Loading','loader_id',v_user.id
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_runsheet_loading(
    p_company_id uuid,
    p_runsheet_code text,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_user public.users%ROWTYPE;
BEGIN
    IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code),'') IS NULL THEN
        RAISE EXCEPTION 'company_id and runsheet_code are required';
    END IF;

    SELECT * INTO v_user
    FROM public.users
    WHERE email=p_user_email AND company_id=p_company_id
    LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'user is not registered in the company context';
    END IF;

    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND runsheet_code=p_runsheet_code
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.status<>'Loading' THEN
        RAISE EXCEPTION 'runsheet is not Loading: %',v_rs.status;
    END IF;
    IF v_rs.loader_id<>v_user.id THEN
        RAISE EXCEPTION 'runsheet is assigned to another loader';
    END IF;

    UPDATE public.order_details od
    SET qty_loaded=0,updated_at=now()
    FROM public.orders o
    WHERE od.order_id=o.id
      AND o.company_id=p_company_id
      AND o.runsheet_id=v_rs.id
      AND COALESCE(od.qty_loaded,0)>0;

    UPDATE public.runsheets
    SET status='Picked',loader_id=NULL,loader_start=NULL,updated_at=now()
    WHERE id=v_rs.id AND status='Loading';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet transition Loading -> Picked failed';
    END IF;

    RETURN jsonb_build_object(
        'success',true,'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,'status','Picked'
    );
END;
$$;

-- ============================================================
-- 5. Atomic Loading / Reload semantics
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_runsheet_loading(
    p_company_id uuid,
    p_runsheet_id uuid,
    p_items jsonb,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_vehicle public.vehicles%ROWTYPE;
    v_main uuid;
    v_van uuid;
    v_item_code text;
    v_requested numeric;
    v_capacity numeric;
    v_remaining numeric;
    v_item_id uuid;
    v_od record;
    v_total numeric:=0;
    v_backorders integer:=0;
    v_idempotency_key_base text;
    v_operation_hash text;
BEGIN
    IF p_company_id IS NULL OR p_runsheet_id IS NULL THEN
        RAISE EXCEPTION 'company_id and runsheet_id are required';
    END IF;
    IF p_items IS NULL OR jsonb_typeof(p_items)<>'array'
       OR jsonb_array_length(p_items)=0 THEN
        RAISE EXCEPTION 'items array is required';
    END IF;

    SELECT * INTO v_rs
    FROM public.runsheets WHERE id=p_runsheet_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.company_id<>p_company_id THEN
        RAISE EXCEPTION 'runsheet outside company context';
    END IF;
    IF v_rs.status<>'Loading' THEN
        RAISE EXCEPTION 'runsheet is not in Loading state: %',v_rs.status;
    END IF;
    IF v_rs.vehicle_id IS NULL OR v_rs.loader_start IS NULL THEN
        RAISE EXCEPTION 'loading cycle identity is missing';
    END IF;

    SELECT * INTO v_vehicle
    FROM public.vehicles
    WHERE id=v_rs.vehicle_id AND company_id=p_company_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'assigned vehicle not found'; END IF;

    SELECT main_branch_id INTO STRICT v_main
    FROM public.app_settings
    WHERE company_id=p_company_id;

    SELECT id INTO v_van
    FROM public.branches
    WHERE company_id=p_company_id
      AND branch_code='VAN-'||v_vehicle.vehicle_code
      AND is_active=true
    LIMIT 1;
    IF v_van IS NULL THEN RAISE EXCEPTION 'canonical VAN branch not found'; END IF;

    SELECT md5(COALESCE(
        string_agg(x.item_code||':'||x.loaded_qty::text,'|' ORDER BY x.item_code),''
    )) INTO v_operation_hash
    FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric);

    v_idempotency_key_base :=
        'TASK-028|Loading|'||v_rs.id::text||'|'||v_rs.loader_start::text||'|'||
        COALESCE(v_rs.loader_end::text,'NONE')||'|'||v_operation_hash;

    FOR v_item_code,v_requested IN
        SELECT x.item_code,SUM(x.loaded_qty)
        FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric)
        GROUP BY x.item_code
        ORDER BY x.item_code
    LOOP
        IF v_item_code IS NULL OR btrim(v_item_code)=''
           OR v_requested IS NULL OR v_requested<=0 THEN
            RAISE EXCEPTION 'invalid loading item request';
        END IF;

        SELECT id INTO v_item_id
        FROM public.items
        WHERE company_id=p_company_id AND item_code=v_item_code
        LIMIT 1;
        IF v_item_id IS NULL THEN
            RAISE EXCEPTION 'item not found: %',v_item_code;
        END IF;

        SELECT COALESCE(SUM(GREATEST(COALESCE(od.qty_picked,0),0)),0)
        INTO v_capacity
        FROM public.order_details od
        JOIN public.orders o ON o.id=od.order_id
        WHERE o.company_id=p_company_id
          AND o.runsheet_id=p_runsheet_id
          AND od.item_code=v_item_code;

        IF v_requested>v_capacity THEN
            RAISE EXCEPTION 'loaded quantity exceeds picked capacity for %',v_item_code;
        END IF;

        -- Reopen is an edit cycle: requested quantity replaces prior loaded quantity.
        UPDATE public.order_details od
        SET qty_loaded=0,updated_at=now()
        FROM public.orders o
        WHERE od.order_id=o.id
          AND o.company_id=p_company_id
          AND o.runsheet_id=p_runsheet_id
          AND od.item_code=v_item_code;

        v_remaining:=v_requested;

        FOR v_od IN
            SELECT od.id,COALESCE(od.qty_picked,0) qty_picked
            FROM public.order_details od
            JOIN public.orders o ON o.id=od.order_id
            WHERE o.company_id=p_company_id
              AND o.runsheet_id=p_runsheet_id
              AND od.item_code=v_item_code
              AND COALESCE(od.qty_picked,0)>0
            ORDER BY od.id
            FOR UPDATE OF od
        LOOP
            EXIT WHEN v_remaining<=0;
            DECLARE v_delta numeric;
            BEGIN
                v_delta:=LEAST(v_remaining,v_od.qty_picked);
                IF v_delta>0 THEN
                    UPDATE public.order_details
                    SET qty_loaded=v_delta,
                        updated_at=now(),
                        reason_loading=CASE
                            WHEN v_delta<v_od.qty_picked THEN 'Partial Loading'
                            ELSE reason_loading
                        END
                    WHERE id=v_od.id;
                    v_remaining:=v_remaining-v_delta;
                END IF;
            END;
        END LOOP;

        IF v_remaining<>0 THEN
            RAISE EXCEPTION 'failed to allocate loaded quantity';
        END IF;

        PERFORM public.post_stock_movement(
            p_company_id,'Loading',v_main,v_van,v_item_id,v_requested,
            v_rs.runsheet_code,
            v_idempotency_key_base||'|'||v_item_id::text,
            p_user_email,
            v_idempotency_key_base||'|'||v_item_id::text
        );

        FOR v_od IN
            SELECT od.id order_detail_id,od.order_id,od.qty ordered_qty,
                   od.qty_loaded,od.item_id,od.item_code
            FROM public.order_details od
            JOIN public.orders o ON o.id=od.order_id
            WHERE o.company_id=p_company_id
              AND o.runsheet_id=p_runsheet_id
              AND od.item_code=v_item_code
              AND COALESCE(od.qty,0)>COALESCE(od.qty_loaded,0)
            FOR UPDATE OF od
        LOOP
            INSERT INTO public.fulfillment_backorders(
                company_id,order_id,order_detail_id,runsheet_id,
                item_id,item_code,remaining_qty,status
            ) VALUES (
                p_company_id,v_od.order_id,v_od.order_detail_id,p_runsheet_id,
                v_od.item_id,v_od.item_code,
                GREATEST(v_od.ordered_qty-COALESCE(v_od.qty_loaded,0),0),
                'Pending'
            )
            ON CONFLICT(order_detail_id,runsheet_id)
            DO UPDATE SET
                remaining_qty=EXCLUDED.remaining_qty,
                status='Pending',
                updated_at=now();
            v_backorders:=v_backorders+1;
        END LOOP;

        v_total:=v_total+v_requested;
    END LOOP;

    UPDATE public.runsheets
    SET status='Loaded',loader_end=now(),updated_at=now()
    WHERE id=p_runsheet_id AND status='Loading';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet state transition to Loaded failed';
    END IF;

    UPDATE public.orders
    SET order_status='Loaded',updated_at=now()
    WHERE company_id=p_company_id AND runsheet_id=p_runsheet_id;

    RETURN jsonb_build_object(
        'success',true,'runsheet_id',p_runsheet_id,
        'runsheet_code',v_rs.runsheet_code,'loaded_total',v_total,
        'backorder_lines',v_backorders
    );
END;
$$;

-- ============================================================
-- 6. Atomic Unloading
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_runsheet_unloading(
    p_company_id uuid,
    p_runsheet_code text,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_vehicle public.vehicles%ROWTYPE;
    v_main uuid;
    v_van uuid;
    v_detail record;
    v_total numeric:=0;
    v_operation_hash text;
    v_idempotency_key_base text;
BEGIN
    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND runsheet_code=p_runsheet_code
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.status<>'Loaded' THEN
        RAISE EXCEPTION 'runsheet is not in Loaded state: %',v_rs.status;
    END IF;
    IF v_rs.vehicle_id IS NULL OR v_rs.loader_start IS NULL OR v_rs.loader_end IS NULL THEN
        RAISE EXCEPTION 'loading cycle identity is missing';
    END IF;

    SELECT * INTO v_vehicle
    FROM public.vehicles
    WHERE id=v_rs.vehicle_id AND company_id=p_company_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'assigned vehicle not found'; END IF;

    SELECT main_branch_id INTO STRICT v_main
    FROM public.app_settings WHERE company_id=p_company_id;

    SELECT id INTO v_van
    FROM public.branches
    WHERE company_id=p_company_id
      AND branch_code='VAN-'||v_vehicle.vehicle_code
      AND is_active=true
    LIMIT 1;
    IF v_van IS NULL THEN RAISE EXCEPTION 'canonical VAN branch not found'; END IF;

    SELECT md5(COALESCE(
        string_agg(item_id::text||':'||qty_loaded::text,'|' ORDER BY item_id),''
    )) INTO v_operation_hash
    FROM public.run_sheet_details
    WHERE runsheet_id=v_rs.id AND COALESCE(qty_loaded,0)>0;

    v_idempotency_key_base :=
        'TASK-028|Unloading|'||v_rs.id::text||'|'||v_rs.loader_start::text||'|'||
        v_rs.loader_end::text||'|'||v_operation_hash;

    FOR v_detail IN
        SELECT item_id,item_code,qty_loaded
        FROM public.run_sheet_details
        WHERE runsheet_id=v_rs.id
          AND COALESCE(qty_loaded,0)>0
        ORDER BY item_id
    LOOP
        PERFORM public.post_stock_movement(
            p_company_id,'Unloading',v_van,v_main,v_detail.item_id,
            v_detail.qty_loaded,v_rs.runsheet_code,
            v_idempotency_key_base||'|'||v_detail.item_id::text,
            p_user_email,
            v_idempotency_key_base||'|'||v_detail.item_id::text
        );
        v_total:=v_total+v_detail.qty_loaded;
    END LOOP;

    UPDATE public.order_details od
    SET qty_loaded=0,updated_at=now()
    FROM public.orders o
    WHERE od.order_id=o.id
      AND o.company_id=p_company_id
      AND o.runsheet_id=v_rs.id
      AND COALESCE(od.qty_loaded,0)>0;

    UPDATE public.fulfillment_backorders
    SET status='Cancelled',updated_at=now()
    WHERE runsheet_id=v_rs.id AND status='Pending';

    UPDATE public.runsheets
    SET status='Picked',loader_end=NULL,updated_at=now()
    WHERE id=v_rs.id AND status='Loaded';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet state transition to Picked failed';
    END IF;

    UPDATE public.orders
    SET order_status='Pending',updated_at=now()
    WHERE company_id=p_company_id AND runsheet_id=v_rs.id;

    RETURN jsonb_build_object(
        'success',true,'runsheet_code',v_rs.runsheet_code,
        'unloaded_total',v_total
    );
END;
$$;

-- ============================================================
-- 7. Reopen Loading = physical VAN -> MAIN inverse, preserve qty_loaded
-- ============================================================
CREATE OR REPLACE FUNCTION public.complete_runsheet_reopen_loading(
    p_company_id uuid,
    p_runsheet_code text,
    p_user_email text,
    p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_vehicle public.vehicles%ROWTYPE;
    v_main uuid;
    v_van uuid;
    v_detail record;
    v_total numeric:=0;
    v_key text;
    v_existing integer;
BEGIN
    IF p_company_id IS NULL
       OR p_runsheet_code IS NULL
       OR NULLIF(btrim(p_operation_id),'') IS NULL THEN
        RAISE EXCEPTION 'company_id, runsheet_code and operation_id are required';
    END IF;

    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND runsheet_code=p_runsheet_code
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;

    v_key:='TASK-028|ReopenLoading|'||p_operation_id||'|'||v_rs.id::text;

    SELECT COUNT(*) INTO v_existing
    FROM public.inventory_log
    WHERE company_id=p_company_id
      AND idempotency_key LIKE v_key||'|%';
    IF v_existing>0 THEN
        RETURN jsonb_build_object(
            'success',true,'duplicate',true,
            'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,
            'qty_loaded_preserved',true,'operation_id',p_operation_id
        );
    END IF;

    IF v_rs.status<>'Loaded' THEN
        RAISE EXCEPTION 'runsheet is not in Loaded state: %',v_rs.status;
    END IF;
    IF v_rs.vehicle_id IS NULL OR v_rs.loader_start IS NULL OR v_rs.loader_end IS NULL THEN
        RAISE EXCEPTION 'loading cycle identity is missing';
    END IF;

    SELECT * INTO v_vehicle
    FROM public.vehicles
    WHERE id=v_rs.vehicle_id AND company_id=p_company_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'assigned vehicle not found'; END IF;

    SELECT main_branch_id INTO STRICT v_main
    FROM public.app_settings WHERE company_id=p_company_id;

    SELECT id INTO v_van
    FROM public.branches
    WHERE company_id=p_company_id
      AND branch_code='VAN-'||v_vehicle.vehicle_code
      AND is_active=true
    LIMIT 1;
    IF v_van IS NULL THEN RAISE EXCEPTION 'canonical VAN branch not found'; END IF;

    FOR v_detail IN
        SELECT item_id,item_code,COALESCE(qty_loaded,0) qty_loaded
        FROM public.run_sheet_details
        WHERE runsheet_id=v_rs.id
          AND COALESCE(qty_loaded,0)>0
        ORDER BY item_id
    LOOP
        PERFORM public.post_stock_movement(
            p_company_id,'Unloading',v_van,v_main,v_detail.item_id,
            v_detail.qty_loaded,v_rs.runsheet_code,
            v_key||'|'||v_detail.item_id::text,
            p_user_email,
            v_key||'|'||v_detail.item_id::text
        );
        v_total:=v_total+v_detail.qty_loaded;
    END LOOP;

    -- Preserve qty_loaded for editing; clear cycle end marker so the next completion
    -- is a new Loading event with a new cycle identity.
    UPDATE public.runsheets
    SET status='Loading',loader_end=NULL,updated_at=now()
    WHERE id=v_rs.id AND status='Loaded';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'runsheet transition Loaded -> Loading failed';
    END IF;

    RETURN jsonb_build_object(
        'success',true,'duplicate',false,
        'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,
        'reopened_total',v_total,'qty_loaded_preserved',true,
        'operation_id',p_operation_id
    );
END;
$$;

-- ============================================================
-- 8. Privilege boundaries
-- ============================================================
REVOKE ALL ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.start_runsheet_loading(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_runsheet_loading(uuid,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.cancel_runsheet_loading(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_runsheet_loading(uuid,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) TO service_role;
REVOKE ALL ON FUNCTION public.complete_runsheet_unloading(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_unloading(uuid,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.complete_runsheet_reopen_loading(uuid,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_reopen_loading(uuid,text,text,text) TO service_role;

COMMIT;
