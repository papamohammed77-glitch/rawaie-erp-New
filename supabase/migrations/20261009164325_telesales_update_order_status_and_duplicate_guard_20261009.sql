CREATE OR REPLACE FUNCTION public.update_order_atomic(p_company_id uuid, p_order_code text, p_user_email text, p_order_header jsonb, p_items jsonb, p_branch_code text, p_operation_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_permissions jsonb := '[]'::jsonb;
  v_role_permissions jsonb := '[]'::jsonb;
  v_role_exists boolean := false;
  v_is_privileged boolean := false;
  v_customer_uuid uuid;
  v_branch_uuid uuid;
  v_result jsonb;
  v_old_data jsonb;
  item record;
  v_item_id uuid;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'UPDATE_ORDER_COMPANY_REQUIRED'; END IF;
  IF NULLIF(btrim(p_order_code),'') IS NULL THEN RAISE EXCEPTION 'UPDATE_ORDER_CODE_REQUIRED'; END IF;
  IF NULLIF(btrim(p_user_email),'') IS NULL THEN RAISE EXCEPTION 'UPDATE_ORDER_ACTOR_REQUIRED'; END IF;
  IF p_operation_id IS NULL THEN RAISE EXCEPTION 'UPDATE_ORDER_OPERATION_ID_REQUIRED'; END IF;
  IF p_order_header IS NULL OR jsonb_typeof(p_order_header) <> 'object' THEN RAISE EXCEPTION 'UPDATE_ORDER_HEADER_INVALID'; END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'UPDATE_ORDER_ITEMS_REQUIRED'; END IF;

  SELECT * INTO v_actor
  FROM public.users
  WHERE lower(email)=lower(p_user_email)
    AND company_id=p_company_id
    AND coalesce(status,'Active')='Active'
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'UPDATE_ORDER_ACTOR_NOT_FOUND_OR_WRONG_COMPANY'; END IF;

  v_permissions := coalesce(v_actor.permissions,'[]'::jsonb);
  SELECT coalesce(r.permissions,'[]'::jsonb),true
    INTO v_role_permissions,v_role_exists
  FROM public.roles r
  WHERE r.id=v_actor.role_id
    AND r.company_id=p_company_id;
  IF v_role_exists THEN
    v_permissions := v_permissions || coalesce(v_role_permissions,'[]'::jsonb);
    SELECT coalesce(jsonb_agg(rp.permission_key),'[]'::jsonb)
      INTO v_role_permissions
    FROM public.role_permissions rp
    WHERE rp.role_id=v_actor.role_id;
    v_permissions := v_permissions || coalesce(v_role_permissions,'[]'::jsonb);
  END IF;

  v_is_privileged :=
    v_permissions @> '["*"]'::jsonb
    OR v_permissions @> '["general_manager"]'::jsonb
    OR v_permissions @> '["sales_manager"]'::jsonb
    OR v_permissions @> '["sales_supervisor"]'::jsonb;

  SELECT response_payload INTO v_result
  FROM public.erp_operation_registry
  WHERE company_id=p_company_id
    AND operation_type='update_order'
    AND operation_key=p_operation_id::text
    AND status='completed'
    AND response_payload IS NOT NULL
  ORDER BY completed_at DESC
  LIMIT 1;
  IF v_result IS NOT NULL THEN
    RETURN v_result || jsonb_build_object('duplicate',true);
  END IF;

  SELECT * INTO v_order
  FROM public.orders
  WHERE company_id=p_company_id
    AND order_code=p_order_code
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الأوردر غير موجود'; END IF;
  IF v_order.order_status NOT IN ('Draft','Confirmed') THEN
    RAISE EXCEPTION 'لا يمكن تعديل أوردر في حالة: %',v_order.order_status;
  END IF;
  IF v_order.runsheet_id IS NOT NULL THEN
    RAISE EXCEPTION 'لا يمكن تعديل أوردر مرتبط برانشيت';
  END IF;
  IF NOT v_is_privileged AND lower(coalesce(v_order.created_by,'')) <> lower(p_user_email) THEN
    RAISE EXCEPTION 'لا تملك صلاحية تعديل هذا الأوردر';
  END IF;
  v_old_data := to_jsonb(v_order);

  SELECT c.id INTO v_customer_uuid
  FROM public.customers c
  WHERE c.company_id=p_company_id
    AND c.customer_code=NULLIF(btrim(p_order_header->>'customer_code'),'')
  LIMIT 1;
  IF NULLIF(btrim(p_order_header->>'customer_code'),'') IS NOT NULL AND v_customer_uuid IS NULL THEN
    RAISE EXCEPTION 'العميل غير موجود ضمن الشركة';
  END IF;

  SELECT b.id INTO v_branch_uuid
  FROM public.branches b
  WHERE b.company_id=p_company_id
    AND b.branch_code=coalesce(NULLIF(btrim(p_branch_code),''),'MAIN')
    AND coalesce(b.is_active,true)=true
  LIMIT 1;
  IF v_branch_uuid IS NULL THEN RAISE EXCEPTION 'الفرع غير موجود ضمن الشركة'; END IF;

  FOR item IN
    SELECT *
    FROM jsonb_to_recordset(p_items)
      AS x(code text,name text,unit text,price numeric,qty numeric)
  LOOP
    IF NULLIF(btrim(item.code),'') IS NULL THEN RAISE EXCEPTION 'كود الصنف مطلوب'; END IF;
    IF item.qty IS NULL OR item.qty<=0 THEN RAISE EXCEPTION 'كمية الصنف غير صالحة: %',item.code; END IF;
    IF item.price IS NULL OR item.price<0 THEN RAISE EXCEPTION 'سعر الصنف غير صالح: %',item.code; END IF;

    SELECT i.id INTO v_item_id
    FROM public.items i
    WHERE i.company_id=p_company_id
      AND i.item_code=item.code
      AND coalesce(i.is_active,true)=true
    LIMIT 1;
    IF v_item_id IS NULL THEN RAISE EXCEPTION 'الصنف غير موجود ضمن الشركة: %',item.code; END IF;
  END LOOP;

  IF EXISTS (
    SELECT item_code
    FROM jsonb_to_recordset(p_items) AS x(code text)
    GROUP BY code
    HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'لا يمكن تكرار الصنف داخل الأوردر';
  END IF;

  INSERT INTO public.erp_operation_registry(
    company_id,operation_type,operation_key,request_payload,status
  )
  VALUES(
    p_company_id,'update_order',p_operation_id::text,
    jsonb_build_object('order_code',p_order_code,'user_email',p_user_email),
    'processing'
  )
  ON CONFLICT(company_id,operation_type,operation_key) DO UPDATE
  SET request_payload=excluded.request_payload,status='processing';

  UPDATE public.orders
  SET customer_id=coalesce(v_customer_uuid,customer_id),
      customer_name=coalesce(NULLIF(p_order_header->>'custName',''),customer_name),
      area=coalesce(p_order_header->>'area',area),
      total_amount=coalesce((p_order_header->>'total')::numeric,total_amount),
      original_total_amount=coalesce((p_order_header->>'total')::numeric,original_total_amount),
      delivery_fee=coalesce((p_order_header->>'deliveryFees')::numeric,delivery_fee),
      payment_type=coalesce(NULLIF(p_order_header->>'paymentType',''),payment_type),
      branch_id=v_branch_uuid,
      order_status='Confirmed',
      customer_phone=coalesce(p_order_header->>'customerPhone',customer_phone),
      customer_email=coalesce(p_order_header->>'customerEmail',customer_email),
      notes=coalesce(p_order_header->>'notes',notes),
      updated_at=now()
  WHERE company_id=p_company_id
    AND id=v_order.id
    AND order_status IN ('Draft','Confirmed')
    AND runsheet_id IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'فشل تحديث رأس الأوردر'; END IF;

  DELETE FROM public.order_details WHERE order_id=v_order.id;

  INSERT INTO public.order_details(
    id,order_id,item_id,item_code,item_name,unit,unit_price,qty
  )
  SELECT
    gen_random_uuid(),
    v_order.id,
    i.id,
    x.code,
    coalesce(x.name,i.name),
    coalesce(x.unit,i.unit,'حبة'),
    x.price,
    x.qty
  FROM jsonb_to_recordset(p_items) AS x(code text,name text,unit text,price numeric,qty numeric)
  JOIN public.items i
    ON i.company_id=p_company_id
   AND i.item_code=x.code
   AND coalesce(i.is_active,true)=true;

  v_result := jsonb_build_object(
    'success',true,
    'duplicate',false,
    'orderID',p_order_code,
    'order_id',v_order.id,
    'company_id',p_company_id,
    'operation_id',p_operation_id,
    'order_status','Confirmed'
  );

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_result,completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='update_order'
    AND operation_key=p_operation_id::text;

  INSERT INTO public.audit_log(
    id,user_email,action,table_name,record_id,old_data,new_data,created_at,
    company_id,actor_user_id,source_type,operation_id
  )
  VALUES(
    gen_random_uuid(),p_user_email,'update_order','orders',p_order_code,
    v_old_data,v_result,now(),p_company_id,v_actor.id,'telesales',p_operation_id::text
  );

  RETURN v_result;
EXCEPTION WHEN others THEN
  UPDATE public.erp_operation_registry
  SET status='failed',
      response_payload=jsonb_build_object('success',false,'error',sqlerrm),
      completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='update_order'
    AND operation_key=p_operation_id::text
    AND status<>'completed';
  RAISE;
END;
$function$
