BEGIN;

-- Canonical Production closure for TASK-028 Loading/Unloading.
-- Physical stock remains exclusively owned by post_stock_movement.
-- Operation identity is persisted in erp_operation_registry.

CREATE OR REPLACE FUNCTION public.complete_runsheet_loading(p_company_id uuid,p_runsheet_id uuid,p_items jsonb,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE r public.runsheets%ROWTYPE; v public.vehicles%ROWTYPE; m uuid; van uuid; code text; req numeric; cap numeric; rem numeric; iid uuid; d record; keybase text; total numeric:=0; payload jsonb; op_key text; reg_id uuid; old_status text; old_payload jsonb; old_request jsonb; response jsonb;
BEGIN
 IF p_company_id IS NULL OR p_runsheet_id IS NULL OR NULLIF(btrim(p_user_email),'') IS NULL THEN RAISE EXCEPTION 'invalid Loading request'; END IF;
 IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'items are required'; END IF;
 SELECT * INTO r FROM public.runsheets WHERE id=p_runsheet_id FOR UPDATE;
 IF NOT FOUND OR r.company_id<>p_company_id OR r.status<>'Loading' OR r.vehicle_id IS NULL OR r.loader_start IS NULL OR r.loading_cycle_id IS NULL THEN RAISE EXCEPTION 'invalid Loading context'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('item_code',x.item_code,'loaded_qty',greatest(coalesce(x.loaded_qty,0),0)) ORDER BY x.item_code),'[]'::jsonb) INTO payload FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric) WHERE NULLIF(btrim(x.item_code),'') IS NOT NULL;
 IF payload='[]'::jsonb THEN RAISE EXCEPTION 'no valid loading items'; END IF;
 op_key:='TASK-028|Loading|'||r.loading_cycle_id::text;
 INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'complete_runsheet_loading',op_key,jsonb_build_object('runsheet_id',r.id,'runsheet_code',r.runsheet_code,'items',payload,'user_email',lower(p_user_email)),'processing') ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING RETURNING id INTO reg_id;
 IF reg_id IS NULL THEN SELECT status,response_payload,request_payload INTO old_status,old_payload,old_request FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='complete_runsheet_loading' AND operation_key=op_key FOR UPDATE; IF old_request IS DISTINCT FROM jsonb_build_object('runsheet_id',r.id,'runsheet_code',r.runsheet_code,'items',payload,'user_email',lower(p_user_email)) THEN RAISE EXCEPTION 'idempotency key conflict: loading cycle was used with a different request'; END IF; IF old_status='completed' AND old_payload IS NOT NULL THEN RETURN old_payload||jsonb_build_object('duplicate',true); END IF; IF old_status='processing' THEN RAISE EXCEPTION 'loading operation is already processing'; END IF; RAISE EXCEPTION 'invalid loading operation registry state'; END IF;
 SELECT * INTO v FROM public.vehicles WHERE id=r.vehicle_id AND company_id=p_company_id; IF NOT FOUND THEN RAISE EXCEPTION 'vehicle not found'; END IF;
 SELECT main_branch_id INTO STRICT m FROM public.app_settings WHERE company_id=p_company_id ORDER BY created_at ASC,id LIMIT 1;
 SELECT id INTO van FROM public.branches WHERE company_id=p_company_id AND branch_code='VAN-'||v.vehicle_code AND is_active=true LIMIT 1; IF van IS NULL THEN RAISE EXCEPTION 'VAN branch not found'; END IF;
 keybase:=op_key;
 FOR code,req IN SELECT x.item_code,SUM(x.loaded_qty) FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric) WHERE NULLIF(btrim(x.item_code),'') IS NOT NULL GROUP BY x.item_code ORDER BY x.item_code LOOP
   SELECT id INTO iid FROM public.items WHERE item_code=code LIMIT 1; IF iid IS NULL OR req<=0 THEN RAISE EXCEPTION 'invalid item request'; END IF;
   SELECT coalesce(sum(greatest(coalesce(od.qty_picked,0),0)),0) INTO cap FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=r.id AND od.item_code=code;
   IF req>cap THEN RAISE EXCEPTION 'loaded quantity exceeds picked capacity'; END IF;
   UPDATE public.order_details od SET qty_loaded=0,updated_at=now() FROM public.orders o WHERE od.order_id=o.id AND o.company_id=p_company_id AND o.runsheet_id=r.id AND od.item_code=code;
   rem:=req;
   FOR d IN SELECT od.id,coalesce(od.qty_picked,0) picked FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=r.id AND od.item_code=code AND coalesce(od.qty_picked,0)>0 ORDER BY od.id FOR UPDATE OF od LOOP EXIT WHEN rem<=0; UPDATE public.order_details SET qty_loaded=least(rem,d.picked),updated_at=now() WHERE id=d.id; rem:=rem-least(rem,d.picked); END LOOP;
   IF rem<>0 THEN RAISE EXCEPTION 'failed to allocate loaded quantity'; END IF;
   PERFORM public.post_stock_movement(p_company_id,'Loading',m,van,iid,req,r.runsheet_code,keybase||'|'||iid::text,p_user_email,keybase||'|'||iid::text);
   INSERT INTO public.fulfillment_backorders(company_id,order_id,order_detail_id,runsheet_id,item_id,item_code,remaining_qty,status) SELECT p_company_id,od.order_id,od.id,r.id,od.item_id,od.item_code,od.qty-coalesce(od.qty_loaded,0),'Pending' FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE o.company_id=p_company_id AND o.runsheet_id=r.id AND od.item_code=code AND od.qty>coalesce(od.qty_loaded,0) ON CONFLICT(order_detail_id,runsheet_id) DO UPDATE SET remaining_qty=EXCLUDED.remaining_qty,status='Pending',updated_at=now();
   total:=total+req;
 END LOOP;
 UPDATE public.fulfillment_backorders fb SET remaining_qty=greatest(od.qty-coalesce(od.qty_loaded,0),0),status=case when od.qty<=coalesce(od.qty_loaded,0) then 'Consumed' else 'Pending' end,updated_at=now() FROM public.order_details od JOIN public.orders o ON o.id=od.order_id WHERE fb.order_detail_id=od.id AND fb.runsheet_id=r.id AND o.company_id=p_company_id;
 UPDATE public.runsheets SET status='Loaded',loader_end=clock_timestamp(),updated_at=now() WHERE id=r.id AND status='Loading'; IF NOT FOUND THEN RAISE EXCEPTION 'Load transition failed'; END IF;
 UPDATE public.orders SET order_status='Loaded',updated_at=now() WHERE company_id=p_company_id AND runsheet_id=r.id;
 response:=jsonb_build_object('success',true,'duplicate',false,'runsheet_id',r.id,'loaded_total',total,'loading_cycle_id',r.loading_cycle_id,'operation_id',op_key);
 UPDATE public.erp_operation_registry SET status='completed',response_payload=response,completed_at=now() WHERE id=reg_id;
 INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data) VALUES(p_user_email,'update','erp_operation_registry',op_key,response);
 RETURN response;
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_unloading(p_company_id uuid,p_runsheet_code text,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE r public.runsheets%ROWTYPE; v public.vehicles%ROWTYPE; m uuid; van uuid; d record; total numeric:=0; op_key text; payload jsonb; reg_id uuid; old_status text; old_payload jsonb; old_request jsonb; response jsonb;
BEGIN
 IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code),'') IS NULL OR NULLIF(btrim(p_user_email),'') IS NULL THEN RAISE EXCEPTION 'invalid Unloading request'; END IF;
 SELECT * INTO r FROM public.runsheets WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
 IF r.status='Loaded' AND r.loading_cycle_id IS NOT NULL THEN
   op_key:='TASK-028|Unloading|'||r.runsheet_code||'|'||r.loading_cycle_id::text;
   payload:=jsonb_build_object('runsheet_code',r.runsheet_code,'loading_cycle_id',r.loading_cycle_id,'user_email',lower(p_user_email));
   INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) VALUES(p_company_id,'complete_runsheet_unloading',op_key,payload,'processing') ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING RETURNING id INTO reg_id;
   IF reg_id IS NULL THEN SELECT status,response_payload,request_payload INTO old_status,old_payload,old_request FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='complete_runsheet_unloading' AND operation_key=op_key FOR UPDATE; IF old_request IS DISTINCT FROM payload THEN RAISE EXCEPTION 'idempotency key conflict: unloading cycle was used with a different request'; END IF; IF old_status='completed' AND old_payload IS NOT NULL THEN RETURN old_payload||jsonb_build_object('duplicate',true); END IF; IF old_status='processing' THEN RAISE EXCEPTION 'unloading operation is already processing'; END IF; RAISE EXCEPTION 'invalid unloading operation registry state'; END IF;
 ELSE
   SELECT status,response_payload INTO old_status,old_payload FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='complete_runsheet_unloading' AND operation_key LIKE 'TASK-028|Unloading|'||r.runsheet_code||'|%' AND status='completed' ORDER BY created_at DESC LIMIT 1;
   IF FOUND AND old_payload IS NOT NULL THEN RETURN old_payload||jsonb_build_object('duplicate',true); END IF;
   RAISE EXCEPTION 'runsheet not Loaded';
 END IF;
 SELECT * INTO v FROM public.vehicles WHERE id=r.vehicle_id AND company_id=p_company_id; IF NOT FOUND THEN RAISE EXCEPTION 'vehicle not found'; END IF;
 SELECT main_branch_id INTO STRICT m FROM public.app_settings WHERE company_id=p_company_id ORDER BY created_at ASC,id LIMIT 1;
 SELECT id INTO van FROM public.branches WHERE company_id=p_company_id AND branch_code='VAN-'||v.vehicle_code AND is_active=true LIMIT 1; IF van IS NULL THEN RAISE EXCEPTION 'VAN branch not found'; END IF;
 FOR d IN SELECT item_id,qty_loaded FROM public.run_sheet_details WHERE runsheet_id=r.id AND coalesce(qty_loaded,0)>0 ORDER BY item_id LOOP
   PERFORM public.post_stock_movement(p_company_id,'Unloading',van,m,d.item_id,d.qty_loaded,r.runsheet_code,r.runsheet_code||'|Unloading|'||r.loading_cycle_id::text||'|'||d.item_id::text,p_user_email,op_key||'|'||d.item_id::text);
   total:=total+d.qty_loaded;
 END LOOP;
 UPDATE public.order_details od SET qty_loaded=0,updated_at=now() FROM public.orders o WHERE od.order_id=o.id AND o.company_id=p_company_id AND o.runsheet_id=r.id;
 UPDATE public.fulfillment_backorders SET status='Cancelled',updated_at=now() WHERE runsheet_id=r.id AND status='Pending';
 UPDATE public.runsheets SET status='Picked',loader_end=NULL,loader_start=NULL,loading_cycle_id=NULL,updated_at=now() WHERE id=r.id AND status='Loaded'; IF NOT FOUND THEN RAISE EXCEPTION 'Unload transition failed'; END IF;
 UPDATE public.orders SET order_status='Pending',updated_at=now() WHERE company_id=p_company_id AND runsheet_id=r.id;
 response:=jsonb_build_object('success',true,'duplicate',false,'status','Picked','unloaded_total',total,'unloading_cycle',r.loading_cycle_id,'operation_id',op_key);
 UPDATE public.erp_operation_registry SET status='completed',response_payload=response,completed_at=now() WHERE id=reg_id;
 INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data) VALUES(p_user_email,'update','erp_operation_registry',op_key,response);
 RETURN response;
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_loading(uuid,uuid,jsonb,text) TO service_role;
REVOKE ALL ON FUNCTION public.complete_runsheet_unloading(uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.complete_runsheet_unloading(uuid,text,text) TO service_role;

COMMIT;