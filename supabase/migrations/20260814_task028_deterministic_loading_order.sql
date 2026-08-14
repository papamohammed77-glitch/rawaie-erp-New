BEGIN;

-- Explicit ordering prevents relying on PostgreSQL's unspecified GROUP BY output order.
-- This makes multi-item transactional failure/rollback behavior deterministic.
CREATE OR REPLACE FUNCTION public.complete_runsheet_loading(p_company_id uuid,p_runsheet_id uuid,p_items jsonb,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE; v_vehicle public.vehicles%ROWTYPE; v_main uuid; v_van uuid;
    v_item_code text; v_requested numeric; v_capacity numeric; v_remaining numeric; v_item_id uuid;
    v_od record; v_total numeric:=0; v_backorders integer:=0; v_idempotency_key_base text; v_operation_hash text;
BEGIN
    IF p_company_id IS NULL OR p_runsheet_id IS NULL THEN RAISE EXCEPTION 'company_id and runsheet_id are required'; END IF;
    IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'items array is required'; END IF;
    SELECT * INTO v_rs FROM public.runsheets WHERE id=p_runsheet_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.company_id<>p_company_id THEN RAISE EXCEPTION 'runsheet outside company context'; END IF;
    IF v_rs.status<>'Loading' THEN RAISE EXCEPTION 'runsheet is not in Loading state: %',v_rs.status; END IF;
    IF v_rs.vehicle_id IS NULL OR v_rs.loader_start IS NULL THEN RAISE EXCEPTION 'loading cycle identity is missing'; END IF;
    SELECT * INTO v_vehicle FROM public.vehicles WHERE id=v_rs.vehicle_id AND company_id=p_company_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'assigned vehicle not found'; END IF;
    SELECT main_branch_id INTO v_main FROM public.app_settings WHERE company_id=p_company_id LIMIT 1;
    IF v_main IS NULL THEN RAISE EXCEPTION 'main branch not configured'; END IF;
    SELECT id INTO v_van FROM public.branches WHERE company_id=p_company_id AND branch_code='VAN-'||v_vehicle.vehicle_code AND is_active=true LIMIT 1;
    IF v_van IS NULL THEN RAISE EXCEPTION 'canonical VAN branch not found'; END IF;
    SELECT md5(COALESCE(string_agg(x.item_code||':'||x.loaded_qty::text,'|' ORDER BY x.item_code),'')) INTO v_operation_hash FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric);
    v_idempotency_key_base:='TASK-028|Loading|'||v_rs.id::text||'|'||v_rs.loader_start::text||'|'||COALESCE(v_rs.loader_end::text,'NONE')||'|'||v_operation_hash;

    FOR v_item_code,v_requested IN
        SELECT x.item_code,SUM(x.loaded_qty)
        FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric)
        GROUP BY x.item_code
        ORDER BY x.item_code
    LOOP
        IF v_item_code IS NULL OR btrim(v_item_code)='' OR v_requested IS NULL OR v_requested<=0 THEN RAISE EXCEPTION 'invalid loading item request'; END IF;
        SELECT id INTO v_item_id FROM public.items WHERE company_id=p_company_id AND item_code=v_item_code LIMIT 1;
        IF v_item_id IS NULL THEN RAISE EXCEPTION 'item not found: %',v_item_code; END IF;
        SELECT COALESCE(SUM(GREATEST(COALESCE(od.qty_picked,0),0)),0) INTO v_capacity
        FROM public.order_details od JOIN public.orders o ON o.id=od.order_id
        WHERE o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code;
        IF v_requested>v_capacity THEN RAISE EXCEPTION 'loaded quantity exceeds picked capacity for %',v_item_code; END IF;
        UPDATE public.order_details od SET qty_loaded=0,updated_at=now()
        FROM public.orders o WHERE od.order_id=o.id AND o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code;
        v_remaining:=v_requested;
        FOR v_od IN SELECT od.id,COALESCE(od.qty_picked,0) qty_picked
        FROM public.order_details od JOIN public.orders o ON o.id=od.order_id
        WHERE o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code AND COALESCE(od.qty_picked,0)>0
        ORDER BY od.id FOR UPDATE OF od LOOP
            EXIT WHEN v_remaining<=0;
            DECLARE v_delta numeric; BEGIN
                v_delta:=LEAST(v_remaining,v_od.qty_picked);
                IF v_delta>0 THEN
                    UPDATE public.order_details SET qty_loaded=v_delta,updated_at=now(),reason_loading=CASE WHEN v_delta<v_od.qty_picked THEN 'Partial Loading' ELSE reason_loading END WHERE id=v_od.id;
                    v_remaining:=v_remaining-v_delta;
                END IF;
            END;
        END LOOP;
        IF v_remaining<>0 THEN RAISE EXCEPTION 'failed to allocate loaded quantity'; END IF;
        PERFORM public.post_stock_movement(p_company_id,'Loading',v_main,v_van,v_item_id,v_requested,v_rs.runsheet_code,v_idempotency_key_base||'|'||v_item_id::text,p_user_email,v_idempotency_key_base||'|'||v_item_id::text);
        FOR v_od IN SELECT od.id order_detail_id,od.order_id,od.qty ordered_qty,od.qty_loaded,od.item_id,od.item_code
        FROM public.order_details od JOIN public.orders o ON o.id=od.order_id
        WHERE o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code AND COALESCE(od.qty,0)>COALESCE(od.qty_loaded,0)
        FOR UPDATE OF od LOOP
            INSERT INTO public.fulfillment_backorders(company_id,order_id,order_detail_id,runsheet_id,item_id,item_code,remaining_qty,status)
            VALUES(p_company_id,v_od.order_id,v_od.order_detail_id,p_runsheet_id,v_od.item_id,v_od.item_code,GREATEST(v_od.ordered_qty-COALESCE(v_od.qty_loaded,0),0),'Pending')
            ON CONFLICT(order_detail_id,runsheet_id) DO UPDATE SET remaining_qty=EXCLUDED.remaining_qty,status='Pending',updated_at=now();
            v_backorders:=v_backorders+1;
        END LOOP;
        v_total:=v_total+v_requested;
    END LOOP;
    UPDATE public.runsheets SET status='Loaded',loader_end=now(),updated_at=now() WHERE id=p_runsheet_id AND status='Loading';
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet state transition to Loaded failed'; END IF;
    UPDATE public.orders SET order_status='Loaded',updated_at=now() WHERE company_id=p_company_id AND runsheet_id=p_runsheet_id;
    RETURN jsonb_build_object('success',true,'runsheet_id',p_runsheet_id,'runsheet_code',v_rs.runsheet_code,'loaded_total',v_total,'backorder_lines',v_backorders);
END;
$$;

REVOKE ALL ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) TO service_role;
COMMIT;