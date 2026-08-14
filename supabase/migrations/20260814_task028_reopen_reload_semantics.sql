BEGIN;

-- Production-authoritative trigger boundary reproduced for staging/current schema.
CREATE OR REPLACE FUNCTION public.sync_run_sheet_details()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target_runsheet_id uuid; existing_count integer; v_item_id uuid; v_order_id uuid; v_item_code text;
BEGIN
    IF TG_OP='DELETE' THEN v_order_id:=OLD.order_id; v_item_code:=OLD.item_code; ELSE v_order_id:=NEW.order_id; v_item_code:=NEW.item_code; END IF;
    SELECT o.runsheet_id INTO target_runsheet_id FROM public.orders o WHERE o.id=v_order_id;
    IF target_runsheet_id IS NULL THEN IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
    SELECT id INTO v_item_id FROM public.items WHERE item_code=v_item_code LIMIT 1;
    SELECT COUNT(*) INTO existing_count FROM public.run_sheet_details WHERE runsheet_id=target_runsheet_id AND item_code=v_item_code;
    IF existing_count>0 THEN
        WITH agg AS (SELECT COALESCE(SUM(od.qty),0) sum_ordered,COALESCE(SUM(od.qty_picked),0) sum_picked,COALESCE(SUM(od.qty_loaded),0) sum_loaded,COALESCE(SUM(od.qty_delivered),0) sum_delivered,COALESCE(SUM(od.qty_refused),0) sum_refused,COALESCE(SUM(od.qty_returned),0) sum_returned,COALESCE(SUM(od.driver_liability),0) sum_liability,MAX(od.item_name) item_name_val,MAX(od.unit) unit_val,MAX(od.unit_price) unit_price_val FROM public.order_details od JOIN public.orders o ON od.order_id=o.id WHERE o.runsheet_id=target_runsheet_id AND od.item_code=v_item_code)
        UPDATE public.run_sheet_details SET item_name=agg.item_name_val,unit=agg.unit_val,unit_price=agg.unit_price_val,qty_ordered=agg.sum_ordered,qty_picked=agg.sum_picked,qty_loaded=agg.sum_loaded,qty_delivered=agg.sum_delivered,qty_refused=agg.sum_refused,qty_returned=agg.sum_returned,driver_liability=agg.sum_liability,updated_at=now() FROM agg WHERE runsheet_id=target_runsheet_id AND item_code=v_item_code;
    ELSE
        INSERT INTO public.run_sheet_details(runsheet_id,item_id,item_code,item_name,unit,unit_price,qty_ordered,qty_picked,qty_loaded,qty_delivered,qty_refused,qty_returned,driver_liability)
        SELECT target_runsheet_id,v_item_id,v_item_code,MAX(od.item_name),MAX(od.unit),MAX(od.unit_price),COALESCE(SUM(od.qty),0),COALESCE(SUM(od.qty_picked),0),COALESCE(SUM(od.qty_loaded),0),COALESCE(SUM(od.qty_delivered),0),COALESCE(SUM(od.qty_refused),0),COALESCE(SUM(od.qty_returned),0),COALESCE(SUM(od.driver_liability),0) FROM public.order_details od JOIN public.orders o ON od.order_id=o.id WHERE o.runsheet_id=target_runsheet_id AND od.item_code=v_item_code;
    END IF;
    IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END; $$;
DROP TRIGGER IF EXISTS trg_sync_run_sheet_details ON public.order_details;
CREATE TRIGGER trg_sync_run_sheet_details AFTER INSERT OR DELETE OR UPDATE ON public.order_details FOR EACH ROW EXECUTE FUNCTION public.sync_run_sheet_details();

-- A reopened Loading cycle is an edit: requested qty replaces the prior loaded quantity.
CREATE OR REPLACE FUNCTION public.complete_runsheet_loading(p_company_id uuid,p_runsheet_id uuid,p_items jsonb,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_rs public.runsheets%ROWTYPE; v_vehicle public.vehicles%ROWTYPE; v_main uuid; v_van uuid; v_item_code text; v_requested numeric; v_capacity numeric; v_remaining numeric; v_item_id uuid; v_od record; v_total numeric:=0; v_backorders integer:=0; v_idempotency_key_base text; v_operation_hash text;
BEGIN
IF p_company_id IS NULL OR p_runsheet_id IS NULL THEN RAISE EXCEPTION 'company_id and runsheet_id are required'; END IF;
IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'items array is required'; END IF;
SELECT * INTO v_rs FROM public.runsheets WHERE id=p_runsheet_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
IF v_rs.company_id<>p_company_id THEN RAISE EXCEPTION 'runsheet outside company context'; END IF; IF v_rs.status<>'Loading' THEN RAISE EXCEPTION 'runsheet is not in Loading state: %',v_rs.status; END IF; IF v_rs.vehicle_id IS NULL OR v_rs.loader_start IS NULL THEN RAISE EXCEPTION 'loading cycle identity is missing'; END IF;
SELECT * INTO v_vehicle FROM public.vehicles WHERE id=v_rs.vehicle_id AND company_id=p_company_id; IF NOT FOUND THEN RAISE EXCEPTION 'assigned vehicle not found'; END IF; SELECT main_branch_id INTO v_main FROM public.app_settings WHERE company_id=p_company_id LIMIT 1; IF v_main IS NULL THEN RAISE EXCEPTION 'main branch not configured'; END IF; SELECT id INTO v_van FROM public.branches WHERE company_id=p_company_id AND branch_code='VAN-'||v_vehicle.vehicle_code AND is_active=true LIMIT 1; IF v_van IS NULL THEN RAISE EXCEPTION 'canonical VAN branch not found'; END IF;
SELECT md5(COALESCE(string_agg(x.item_code||':'||x.loaded_qty::text,'|' ORDER BY x.item_code),'')) INTO v_operation_hash FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric); v_idempotency_key_base:='TASK-028|Loading|'||v_rs.id::text||'|'||v_rs.loader_start::text||'|'||COALESCE(v_rs.loader_end::text,'NONE')||'|'||v_operation_hash;
FOR v_item_code,v_requested IN SELECT x.item_code,SUM(x.loaded_qty) FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric) GROUP BY x.item_code LOOP
IF v_item_code IS NULL OR btrim(v_item_code)='' OR v_requested IS NULL OR v_requested<=0 THEN RAISE EXCEPTION 'invalid loading item request'; END IF;
SELECT id INTO v_item_id FROM public.items WHERE company_id=p_company_id AND item_code=v_item_code LIMIT 1; IF v_item_id IS NULL THEN RAISE EXCEPTION 'item not found: %',v_item_code; END IF;
SELECT COALESCE(SUM(GREATEST(COALESCE(od.qty_picked,0),0)),0) INTO v_capacity FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code;
IF v_requested>v_capacity THEN RAISE EXCEPTION 'loaded quantity exceeds picked capacity for %',v_item_code; END IF;
UPDATE public.order_details od SET qty_loaded=0,updated_at=now() FROM public.orders o WHERE od.order_id=o.id AND o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code;
v_remaining:=v_requested;
FOR v_od IN SELECT od.id,COALESCE(od.qty_picked,0) qty_picked FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code AND COALESCE(od.qty_picked,0)>0 ORDER BY od.id FOR UPDATE OF od LOOP EXIT WHEN v_remaining<=0; DECLARE v_delta numeric; BEGIN v_delta:=LEAST(v_remaining,v_od.qty_picked); IF v_delta>0 THEN UPDATE public.order_details SET qty_loaded=v_delta,updated_at=now(),reason_loading=CASE WHEN v_delta<v_od.qty_picked THEN 'Partial Loading' ELSE reason_loading END WHERE id=v_od.id; v_remaining:=v_remaining-v_delta; END IF; END; END LOOP;
IF v_remaining<>0 THEN RAISE EXCEPTION 'failed to allocate loaded quantity'; END IF;
PERFORM public.post_stock_movement(p_company_id,'Loading',v_main,v_van,v_item_id,v_requested,v_rs.runsheet_code,v_idempotency_key_base||'|'||v_item_id::text,p_user_email,v_idempotency_key_base||'|'||v_item_id::text);
FOR v_od IN SELECT od.id order_detail_id,od.order_id,od.qty ordered_qty,od.qty_loaded,od.item_id,od.item_code FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=p_runsheet_id AND od.item_code=v_item_code AND COALESCE(od.qty,0)>COALESCE(od.qty_loaded,0) FOR UPDATE OF od LOOP INSERT INTO public.fulfillment_backorders(company_id,order_id,order_detail_id,runsheet_id,item_id,item_code,remaining_qty,status) VALUES(p_company_id,v_od.order_id,v_od.order_detail_id,p_runsheet_id,v_od.item_id,v_od.item_code,GREATEST(v_od.ordered_qty-COALESCE(v_od.qty_loaded,0),0),'Pending') ON CONFLICT(order_detail_id,runsheet_id) DO UPDATE SET remaining_qty=EXCLUDED.remaining_qty,status='Pending',updated_at=now(); v_backorders:=v_backorders+1; END LOOP; v_total:=v_total+v_requested; END LOOP;
UPDATE public.runsheets SET status='Loaded',loader_end=now(),updated_at=now() WHERE id=p_runsheet_id AND status='Loading'; IF NOT FOUND THEN RAISE EXCEPTION 'runsheet state transition to Loaded failed'; END IF; UPDATE public.orders SET order_status='Loaded',updated_at=now() WHERE company_id=p_company_id AND runsheet_id=p_runsheet_id;
RETURN jsonb_build_object('success',true,'runsheet_id',p_runsheet_id,'runsheet_code',v_rs.runsheet_code,'loaded_total',v_total,'backorder_lines',v_backorders); END; $$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_reopen_loading(p_company_id uuid,p_runsheet_code text,p_user_email text,p_operation_id text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_rs public.runsheets%ROWTYPE; v_vehicle public.vehicles%ROWTYPE; v_main uuid; v_van uuid; v_detail record; v_total numeric:=0; v_key text; v_existing integer;
BEGIN
IF p_company_id IS NULL OR p_runsheet_code IS NULL OR NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'company_id, runsheet_code and operation_id are required'; END IF;
SELECT * INTO v_rs FROM public.runsheets WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
v_key:='TASK-028|ReopenLoading|'||p_operation_id||'|'||v_rs.id::text;
SELECT COUNT(*) INTO v_existing FROM public.inventory_log WHERE company_id=p_company_id AND idempotency_key LIKE v_key||'|%';
IF v_existing>0 THEN RETURN jsonb_build_object('success',true,'duplicate',true,'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,'qty_loaded_preserved',true,'operation_id',p_operation_id); END IF;
IF v_rs.status<>'Loaded' THEN RAISE EXCEPTION 'runsheet is not in Loaded state: %',v_rs.status; END IF; IF v_rs.vehicle_id IS NULL OR v_rs.loader_start IS NULL OR v_rs.loader_end IS NULL THEN RAISE EXCEPTION 'loading cycle identity is missing'; END IF;
SELECT * INTO v_vehicle FROM public.vehicles WHERE id=v_rs.vehicle_id AND company_id=p_company_id; IF NOT FOUND THEN RAISE EXCEPTION 'assigned vehicle not found'; END IF; SELECT main_branch_id INTO v_main FROM public.app_settings WHERE company_id=p_company_id LIMIT 1; IF v_main IS NULL THEN RAISE EXCEPTION 'main branch not configured'; END IF; SELECT id INTO v_van FROM public.branches WHERE company_id=p_company_id AND branch_code='VAN-'||v_vehicle.vehicle_code AND is_active=true LIMIT 1; IF v_van IS NULL THEN RAISE EXCEPTION 'canonical VAN branch not found'; END IF;
FOR v_detail IN SELECT item_id,item_code,COALESCE(qty_loaded,0) qty_loaded FROM public.run_sheet_details WHERE runsheet_id=v_rs.id AND COALESCE(qty_loaded,0)>0 ORDER BY item_id LOOP PERFORM public.post_stock_movement(p_company_id,'Unloading',v_van,v_main,v_detail.item_id,v_detail.qty_loaded,v_rs.runsheet_code,v_key||'|'||v_detail.item_id::text,p_user_email,v_key||'|'||v_detail.item_id::text); v_total:=v_total+v_detail.qty_loaded; END LOOP;
UPDATE public.runsheets SET status='Loading',loader_end=NULL,updated_at=now() WHERE id=v_rs.id AND status='Loaded'; IF NOT FOUND THEN RAISE EXCEPTION 'runsheet state transition to Loading failed'; END IF;
RETURN jsonb_build_object('success',true,'duplicate',false,'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,'reopened_total',v_total,'qty_loaded_preserved',true,'operation_id',p_operation_id); END; $$;

REVOKE ALL ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) FROM PUBLIC; GRANT EXECUTE ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) TO service_role;
REVOKE ALL ON FUNCTION public.complete_runsheet_reopen_loading(uuid,text,text,text) FROM PUBLIC; GRANT EXECUTE ON FUNCTION public.complete_runsheet_reopen_loading(uuid,text,text,text) TO service_role;
COMMIT;