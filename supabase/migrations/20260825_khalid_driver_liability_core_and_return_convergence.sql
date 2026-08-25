BEGIN;

CREATE OR REPLACE FUNCTION public.post_driver_liability_entry(
  p_company_id uuid,
  p_operation_key text,
  p_driver_id uuid,
  p_runsheet_id uuid,
  p_item_code text,
  p_item_name text,
  p_qty_missing numeric,
  p_unit_price numeric,
  p_amount numeric,
  p_reason text,
  p_status text DEFAULT 'pending'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_existing public.erp_operation_registry%rowtype;
  v_driver public.users%rowtype;
  v_id uuid;
  v_result jsonb;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'DRIVER_LIABILITY_COMPANY_REQUIRED'; END IF;
  IF nullif(btrim(coalesce(p_operation_key,'')),'') IS NULL THEN RAISE EXCEPTION 'DRIVER_LIABILITY_OPERATION_KEY_REQUIRED'; END IF;
  IF p_driver_id IS NULL THEN RAISE EXCEPTION 'DRIVER_LIABILITY_DRIVER_REQUIRED'; END IF;
  IF p_qty_missing IS NULL OR p_qty_missing <= 0 THEN RAISE EXCEPTION 'DRIVER_LIABILITY_QTY_INVALID'; END IF;
  IF p_amount IS NULL OR p_amount < 0 THEN RAISE EXCEPTION 'DRIVER_LIABILITY_AMOUNT_INVALID'; END IF;

  INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
  VALUES(p_company_id,'post_driver_liability_entry',p_operation_key,jsonb_build_object('driver_id',p_driver_id,'runsheet_id',p_runsheet_id,'item_code',p_item_code,'qty_missing',p_qty_missing,'amount',p_amount),'processing')
  ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;

  SELECT * INTO v_existing FROM public.erp_operation_registry
  WHERE company_id=p_company_id AND operation_type='post_driver_liability_entry' AND operation_key=p_operation_key FOR UPDATE;
  IF v_existing.status='completed' AND v_existing.response_payload IS NOT NULL THEN
    RETURN v_existing.response_payload || jsonb_build_object('duplicate',true);
  END IF;

  SELECT * INTO v_driver FROM public.users
  WHERE id=p_driver_id AND company_id=p_company_id AND coalesce(status,'Active')='Active'
    AND role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver') FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'DRIVER_LIABILITY_DRIVER_NOT_FOUND_OR_WRONG_COMPANY'; END IF;

  INSERT INTO public.driver_liabilities(id,company_id,driver_id,runsheet_id,item_code,item_name,qty_missing,unit_price,amount,reason,status,created_at,updated_at)
  VALUES(gen_random_uuid(),p_company_id,p_driver_id,p_runsheet_id,p_item_code,p_item_name,p_qty_missing,p_unit_price,p_amount,p_reason,coalesce(nullif(p_status,''),'pending'),now(),now())
  RETURNING id INTO v_id;

  v_result:=jsonb_build_object('success',true,'duplicate',false,'id',v_id,'company_id',p_company_id,'operation_key',p_operation_key,'driver_id',p_driver_id,'amount',p_amount);
  UPDATE public.erp_operation_registry SET status='completed',response_payload=v_result,completed_at=now()
  WHERE company_id=p_company_id AND operation_type='post_driver_liability_entry' AND operation_key=p_operation_key;
  INSERT INTO public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at)
  VALUES(gen_random_uuid(),NULL,'create','driver_liabilities',v_id::text,v_result,now());
  RETURN v_result;
EXCEPTION WHEN others THEN
  UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now()
  WHERE company_id=p_company_id AND operation_type='post_driver_liability_entry' AND operation_key=p_operation_key AND status<>'completed';
  RAISE;
END;
$function$;

DO $rewrite$
DECLARE d text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO d
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='complete_return_atomic'
    AND pg_get_function_identity_arguments(p.oid)='p_company_id uuid, p_runsheet_code text, p_order_code text, p_is_pos_return boolean, p_user_email text, p_items jsonb';
  IF d IS NULL THEN RAISE EXCEPTION 'COMPLETE_RETURN_FUNCTION_NOT_FOUND'; END IF;
  d:=replace(d,
    'if v_shortage>0 and v_runsheet.driver_id is not null then insert into public.driver_liabilities(id,company_id,driver_id,runsheet_id,item_code,item_name,qty_missing,unit_price,amount,reason,status) values(gen_random_uuid(),p_company_id,v_runsheet.driver_id,v_runsheet.id,v_item_code,coalesce(v_item_name,v_item_code),v_shortage,case when v_shortage>0 then v_shortage_value/v_shortage else 0 end,v_shortage_value,coalesce(v_reason,''عجز غير مبرر''),''pending''); end if;',
    'if v_shortage>0 and v_runsheet.driver_id is not null then perform public.post_driver_liability_entry(p_company_id,''ReturnDriverLiability:''||v_op_key||'':''||v_item_id::text,v_runsheet.driver_id,v_runsheet.id,v_item_code,coalesce(v_item_name,v_item_code),v_shortage,case when v_shortage>0 then v_shortage_value/v_shortage else 0 end,v_shortage_value,coalesce(v_reason,''عجز غير مبرر''),''pending''); end if;');
  IF position('post_driver_liability_entry' in d)=0 THEN RAISE EXCEPTION 'COMPLETE_RETURN_DRIVER_LIABILITY_REWIRE_FAILED'; END IF;
  EXECUTE d;
END $rewrite$;
COMMIT;
