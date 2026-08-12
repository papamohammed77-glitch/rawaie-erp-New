BEGIN;

-- ============================================================
-- TASK-019 — RECEIVE VOUCHER
-- Production implementation + transactional verification
-- ============================================================

CREATE OR REPLACE FUNCTION public.receive_manual_stock_voucher_v2(
    p_company_id uuid,
    p_voucher_code text,
    p_user_email text,
    p_received_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_voucher public.stock_vouchers%ROWTYPE;
    v_item jsonb;
    v_item_code text;
    v_requested numeric;
    v_received_before numeric;
    v_new_received numeric;
    v_total_qty numeric;
    v_total_received numeric;
    v_item_id uuid;
    v_result jsonb;
    v_processed integer := 0;
    v_fully_received boolean;
BEGIN
    SELECT *
    INTO v_voucher
    FROM public.stock_vouchers
    WHERE voucher_code = p_voucher_code
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'voucher not found';
    END IF;

    IF v_voucher.status <> 'Sent' THEN
        RAISE EXCEPTION 'only Sent vouchers can be received';
    END IF;

    IF v_voucher.type NOT IN ('Transfer','DirectReturn') THEN
        RAISE EXCEPTION 'voucher type is not a Receive type: %', v_voucher.type;
    END IF;

    IF p_received_items IS NULL
       OR jsonb_typeof(p_received_items) <> 'array'
       OR jsonb_array_length(p_received_items) = 0
    THEN
        RAISE EXCEPTION 'received_items must be a non-empty JSON array';
    END IF;

    FOR v_item IN
        SELECT value
        FROM jsonb_array_elements(p_received_items)
    LOOP
        v_item_code := v_item->>'itemCode';
        v_requested := COALESCE((v_item->>'receivedQty')::numeric, 0);

        IF v_item_code IS NULL OR v_item_code = '' THEN
            RAISE EXCEPTION 'itemCode is required';
        END IF;

        IF v_requested <= 0 THEN
            RAISE EXCEPTION 'receivedQty must be greater than zero for item %', v_item_code;
        END IF;

        SELECT
            d.qty,
            COALESCE(d.received_qty, 0),
            d.item_code
        INTO
            v_total_qty,
            v_received_before,
            v_item_code
        FROM public.stock_voucher_details d
        WHERE d.voucher_id = v_voucher.id
          AND d.item_code = v_item_code
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'voucher detail not found for item %', v_item_code;
        END IF;

        v_new_received := v_received_before + v_requested;

        IF v_new_received > v_total_qty THEN
            RAISE EXCEPTION
                'receive exceeds remaining quantity for item %. requested=%, already_received=%, total=%',
                v_item_code,
                v_requested,
                v_received_before,
                v_total_qty;
        END IF;

        SELECT id
        INTO v_item_id
        FROM public.items
        WHERE item_code = v_item_code
          AND company_id = p_company_id;

        IF v_item_id IS NULL THEN
            RAISE EXCEPTION 'item not found: %', v_item_code;
        END IF;

        v_result :=
            public.post_stock_movement(
                p_company_id,
                v_voucher.type,
                NULL,
                v_voucher.to_id,
                v_item_id,
                v_requested,
                v_voucher.voucher_code,
                v_voucher.voucher_code,
                p_user_email
            );

        IF COALESCE((v_result->>'success')::boolean, false) IS NOT TRUE THEN
            RAISE EXCEPTION 'central receive stock movement failed for %', v_item_code;
        END IF;

        UPDATE public.stock_voucher_details
        SET received_qty = v_new_received
        WHERE voucher_id = v_voucher.id
          AND item_code = v_item_code;

        v_processed := v_processed + 1;
    END LOOP;

    SELECT
        COALESCE(SUM(d.qty), 0),
        COALESCE(SUM(d.received_qty), 0)
    INTO
        v_total_qty,
        v_total_received
    FROM public.stock_voucher_details d
    WHERE d.voucher_id = v_voucher.id;

    v_fully_received := v_total_received >= v_total_qty;

    IF v_fully_received THEN
        UPDATE public.stock_vouchers
        SET
            status = 'Received',
            received_date = now(),
            received_by = p_user_email
        WHERE id = v_voucher.id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'voucher_code', p_voucher_code,
        'status', CASE WHEN v_fully_received THEN 'Received' ELSE 'Sent' END,
        'details_processed', v_processed,
        'fully_received', v_fully_received
    );
END;
$function$;

SAVEPOINT task019_test;

DO $$
DECLARE
    v_company uuid := 'da4ef704-88ac-4120-aa0e-65b92b2aa2bc';
    v_source uuid := '151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6';
    v_target uuid := 'a08568e5-40a7-4b15-85b4-ced8ebf9971d';
    v_item uuid := 'ef864b14-ec62-4b9f-9932-17da041b6e42';
    v_create jsonb;
    v_send jsonb;
    v_receive jsonb;
    v_code text;
    v_src_before numeric;
    v_tgt_before numeric;
    v_src_after numeric;
    v_tgt_after numeric;
    v_received numeric;
    v_total numeric;
    v_status text;
    v_logs bigint;
BEGIN
    SELECT qty INTO v_src_before
    FROM public.stock_branches
    WHERE branch_id = v_source AND item_id = v_item
    FOR UPDATE;

    SELECT qty INTO v_tgt_before
    FROM public.stock_branches
    WHERE branch_id = v_target AND item_id = v_item
    FOR UPDATE;

    v_create := public.create_manual_stock_voucher_atomic(
        v_company,
        'Transfer',
        'TASK-019-RECEIVE',
        'Branch',
        v_source,
        'Branch',
        v_target,
        'TASK-019 RECEIVE TEST',
        'test-operator@rawaea.local',
        '[{"itemCode":"1004","itemName":"شيبس تايجر طعوم 5ج","qty":2,"unit":"حبة","unitPrice":0,"notes":"TASK-019"}]'::jsonb
    );

    IF COALESCE((v_create->>'success')::boolean, false) IS NOT TRUE THEN
        RAISE EXCEPTION 'TASK-019 FAIL — CREATE';
    END IF;

    v_code := v_create->>'voucher_code';

    v_send := public.send_manual_stock_voucher_v2(
        v_company,
        v_code,
        'test-operator@rawaea.local'
    );

    IF COALESCE((v_send->>'success')::boolean, false) IS NOT TRUE THEN
        RAISE EXCEPTION 'TASK-019 FAIL — SEND';
    END IF;

    v_receive := public.receive_manual_stock_voucher_v2(
        v_company,
        v_code,
        'test-operator@rawaea.local',
        '[{"itemCode":"1004","receivedQty":1}]'::jsonb
    );

    IF COALESCE((v_receive->>'success')::boolean, false) IS NOT TRUE THEN
        RAISE EXCEPTION 'TASK-019 FAIL — FIRST PARTIAL RECEIVE';
    END IF;

    IF (v_receive->>'status') <> 'Sent' THEN
        RAISE EXCEPTION 'TASK-019 FAIL — partial receive must remain Sent';
    END IF;

    SELECT qty INTO v_src_after
    FROM public.stock_branches
    WHERE branch_id = v_source AND item_id = v_item;

    SELECT qty INTO v_tgt_after
    FROM public.stock_branches
    WHERE branch_id = v_target AND item_id = v_item;

    IF v_src_after <> v_src_before - 2 THEN
        RAISE EXCEPTION 'TASK-019 FAIL — source movement after SEND';
    END IF;

    IF v_tgt_after <> v_tgt_before + 1 THEN
        RAISE EXCEPTION 'TASK-019 FAIL — first RECEIVE movement';
    END IF;

    v_receive := public.receive_manual_stock_voucher_v2(
        v_company,
        v_code,
        'test-operator@rawaea.local',
        '[{"itemCode":"1004","receivedQty":1}]'::jsonb
    );

    IF COALESCE((v_receive->>'success')::boolean, false) IS NOT TRUE THEN
        RAISE EXCEPTION 'TASK-019 FAIL — SECOND RECEIVE';
    END IF;

    IF (v_receive->>'status') <> 'Received' THEN
        RAISE EXCEPTION 'TASK-019 FAIL — full receive must become Received';
    END IF;

    SELECT d.received_qty, d.qty
    INTO v_received, v_total
    FROM public.stock_voucher_details d
    WHERE d.voucher_id = (v_create->>'voucher_id')::uuid
      AND d.item_code = '1004';

    IF v_received <> v_total OR v_total <> 2 THEN
        RAISE EXCEPTION 'TASK-019 FAIL — cumulative received_qty';
    END IF;

    SELECT status INTO v_status
    FROM public.stock_vouchers
    WHERE voucher_code = v_code;

    IF v_status <> 'Received' THEN
        RAISE EXCEPTION 'TASK-019 FAIL — final status';
    END IF;

    SELECT COUNT(*) INTO v_logs
    FROM public.inventory_log
    WHERE voucher_id = v_code;

    IF v_logs <> 2 THEN
        RAISE EXCEPTION 'TASK-019 FAIL — expected 2 inventory log rows, got %', v_logs;
    END IF;

    BEGIN
        PERFORM public.receive_manual_stock_voucher_v2(
            v_company,
            v_code,
            'test-operator@rawaea.local',
            '[{"itemCode":"1004","receivedQty":1}]'::jsonb
        );
        RAISE EXCEPTION 'TASK-019 FAIL — over-receive unexpectedly succeeded';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE 'TASK-019 FAIL — over-receive unexpectedly succeeded' THEN
                RAISE;
            END IF;
    END;

    RAISE NOTICE 'TASK-019 — RECEIVE VOUCHER PASS';
END
$$;

ROLLBACK TO SAVEPOINT task019_test;

DO $$
BEGIN
    IF to_regprocedure('public.receive_manual_stock_voucher_v2(uuid,text,text,jsonb)') IS NULL THEN
        RAISE EXCEPTION 'TASK-019 FAIL — Receive RPC not deployed';
    END IF;
END
$$;

COMMIT;

SELECT 'TASK-019 — RECEIVE VOUCHER PASS' AS task_019_result;
