-- Enforce the RAWAEA runsheet source contract in both existing atomic writers.
-- Eligible source families: telesales, order-taker, online-store (normalized for spaces/underscores).
-- Existing POS orders are invoiced/stock-posted by POS and must not enter delivery runsheets.

CREATE OR REPLACE FUNCTION public.append_orders_to_runsheet_atomic(p_company_id uuid, p_runsheet_code text, p_selected_orders text[], p_user_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_rs public.runsheets%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_order_ids uuid[] := ARRAY[]::uuid[];
  v_codes text[] := ARRAY[]::text[];
  v_expected integer;
  v_count integer := 0;
  v_additional numeric := 0;
  d record;
  existing_count integer := 0;
  linked_count integer := 0;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'company context is required'; END IF;
  IF NULLIF(btrim(p_runsheet_code),'') IS NULL THEN RAISE EXCEPTION 'runsheet_code is required'; END IF;
  IF p_selected_orders IS NULL OR cardinality(p_selected_orders)=0 THEN RAISE EXCEPTION 'at least one order is required'; END IF;

  SELECT count(*) INTO v_expected
  FROM (SELECT DISTINCT btrim(x) AS code FROM unnest(p_selected_orders) x WHERE btrim(x)<>'') s;
  IF v_expected=0 THEN RAISE EXCEPTION 'at least one valid order is required'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended('append_runsheet:'||p_company_id::text||':'||p_runsheet_code,0));

  SELECT * INTO v_rs
  FROM public.runsheets
  WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'الرانشيت غير موجود'; END IF;
  IF v_rs.status NOT IN ('Open','Confirmed') THEN RAISE EXCEPTION 'الرانشيت غير مفتوح للإضافة'; END IF;

  SELECT count(*) INTO linked_count
  FROM public.orders o
  WHERE o.company_id=p_company_id
    AND o.order_code=ANY(p_selected_orders)
    AND o.runsheet_id=v_rs.id;

  SELECT count(*) INTO existing_count
  FROM public.orders o
  WHERE o.company_id=p_company_id
    AND o.order_code=ANY(p_selected_orders);

  IF existing_count=v_expected AND linked_count=v_expected THEN
    RETURN jsonb_build_object('success',true,'duplicate',true,'rsId',p_runsheet_code,'runsheet_id',v_rs.id,'ordersCount',v_expected);
  END IF;

  FOR v_order IN
    SELECT o.*
    FROM public.orders o
    WHERE o.company_id=p_company_id
      AND o.order_code=ANY(p_selected_orders)
    ORDER BY o.id
    FOR UPDATE
  LOOP
    IF v_order.runsheet_id IS NOT NULL THEN
      RAISE EXCEPTION 'الأوردر % مرتبط برانشيت آخر',v_order.order_code;
    END IF;
    IF v_order.order_status NOT IN ('Confirmed','Pending') THEN
      RAISE EXCEPTION 'لا يمكن ضم الأوردر % في حالته الحالية: %',v_order.order_code,v_order.order_status;
    END IF;
    IF lower(regexp_replace(btrim(coalesce(v_order.source,'')), '[ _]+', '-', 'g')) NOT IN ('telesales','tele-sales','order-taker','online-store') THEN
      RAISE EXCEPTION 'مصدر الأوردر % غير مؤهل للضم في الرانشيت: %', v_order.order_code, coalesce(nullif(btrim(v_order.source),''),'(empty)');
    END IF;
    v_count:=v_count+1;
    v_order_ids:=array_append(v_order_ids,v_order.id);
    v_codes:=array_append(v_codes,v_order.order_code);
    v_additional:=v_additional+coalesce(v_order.total_amount,0);
  END LOOP;

  IF v_count<>v_expected THEN RAISE EXCEPTION 'أحد الأوردرات المحددة غير موجود في سياق الشركة'; END IF;

  IF EXISTS (
    SELECT 1 FROM public.order_details od
    WHERE od.order_id=ANY(v_order_ids) AND (od.item_id IS NULL OR od.item_code IS NULL)
  ) THEN RAISE EXCEPTION 'هوية صنف غير مكتملة في أحد الأوردرات'; END IF;

  IF EXISTS (
    SELECT 1 FROM public.order_details od
    WHERE od.order_id=ANY(v_order_ids)
      AND NOT EXISTS (SELECT 1 FROM public.items i WHERE i.id=od.item_id AND i.item_code=od.item_code)
  ) THEN RAISE EXCEPTION 'هوية صنف لا تطابق Global Item Master'; END IF;

  FOR d IN
    SELECT od.item_id,od.item_code,min(od.item_name) item_name,min(od.unit) unit,min(od.unit_price) unit_price,sum(coalesce(od.qty,0)) qty_ordered
    FROM public.order_details od
    WHERE od.order_id=ANY(v_order_ids)
    GROUP BY od.item_id,od.item_code
    ORDER BY od.item_id
  LOOP
    UPDATE public.run_sheet_details rsd
    SET qty_ordered=coalesce(rsd.qty_ordered,0)+d.qty_ordered,
        item_name=coalesce(rsd.item_name,d.item_name),
        unit=coalesce(rsd.unit,d.unit),
        unit_price=coalesce(rsd.unit_price,d.unit_price),
        updated_at=now()
    WHERE rsd.runsheet_id=v_rs.id AND rsd.item_id=d.item_id AND rsd.item_code=d.item_code;

    IF NOT FOUND THEN
      INSERT INTO public.run_sheet_details(
        runsheet_id,item_id,item_code,item_name,unit,unit_price,qty_ordered
      ) VALUES (
        v_rs.id,d.item_id,d.item_code,d.item_name,coalesce(d.unit,'حبة'),d.unit_price,d.qty_ordered
      );
    END IF;
  END LOOP;

  UPDATE public.orders
  SET runsheet_id=v_rs.id, order_status='Pending', updated_at=now()
  WHERE company_id=p_company_id AND id=ANY(v_order_ids) AND runsheet_id IS NULL;

  IF (SELECT count(*) FROM public.orders o WHERE o.id=ANY(v_order_ids) AND o.company_id=p_company_id AND o.runsheet_id=v_rs.id)=v_count THEN
    NULL;
  ELSE
    RAISE EXCEPTION 'فشل ربط أحد الأوردرات بالرانشيت';
  END IF;

  UPDATE public.runsheets
  SET total_amount=coalesce(v_rs.total_amount,0)+v_additional,
      updated_at=now()
  WHERE id=v_rs.id AND company_id=p_company_id AND status IN ('Open','Confirmed');
  IF NOT FOUND THEN RAISE EXCEPTION 'فشل تحديث إجمالي الرانشيت'; END IF;

  RETURN jsonb_build_object(
    'success',true,
    'duplicate',false,
    'rsId',p_runsheet_code,
    'runsheet_id',v_rs.id,
    'ordersCount',v_count,
    'itemsCount',(SELECT count(*) FROM public.run_sheet_details WHERE runsheet_id=v_rs.id)
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_runsheet_atomic(p_company_id uuid, p_selected_orders text[], p_user_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_order_count integer := 0;
  v_expected_count integer;
  v_total_amount numeric := 0;
  v_order_ids uuid[] := ARRAY[]::uuid[];
  v_runsheet_id uuid;
  v_new_code text;
  v_last_num integer := 0;
  r public.orders%ROWTYPE;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'company context is required'; END IF;
  IF p_selected_orders IS NULL OR cardinality(p_selected_orders) = 0 THEN RAISE EXCEPTION 'at least one order is required'; END IF;

  SELECT count(*) INTO v_expected_count
  FROM (SELECT DISTINCT trim(x) AS order_code FROM unnest(p_selected_orders) AS x WHERE trim(x) <> '') s;
  IF v_expected_count = 0 THEN RAISE EXCEPTION 'at least one valid order is required'; END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended('create_runsheet:' || p_company_id::text, 0));

  FOR r IN
    SELECT o.* FROM public.orders o
    WHERE o.company_id = p_company_id AND o.order_code = ANY(p_selected_orders)
    FOR UPDATE
  LOOP
    IF r.runsheet_id IS NOT NULL THEN RAISE EXCEPTION 'order % is already linked to runsheet', r.order_code; END IF;
    IF r.order_status NOT IN ('Confirmed', 'Pending') THEN RAISE EXCEPTION 'order % cannot be added in status %', r.order_code, r.order_status; END IF;
    IF lower(regexp_replace(btrim(coalesce(r.source,'')), '[ _]+', '-', 'g')) NOT IN ('telesales','tele-sales','order-taker','online-store') THEN
      RAISE EXCEPTION 'order % source is not eligible for runsheet: %', r.order_code, coalesce(nullif(btrim(r.source),''),'(empty)');
    END IF;
    v_order_count := v_order_count + 1;
    v_order_ids := array_append(v_order_ids, r.id);
    v_total_amount := v_total_amount + coalesce(r.total_amount, 0);
  END LOOP;

  IF v_order_count <> v_expected_count THEN RAISE EXCEPTION 'one or more selected orders were not found in company context'; END IF;

  IF EXISTS (SELECT 1 FROM public.order_details od WHERE od.order_id = ANY(v_order_ids) AND od.item_id IS NULL) THEN
    RAISE EXCEPTION 'one or more order lines have no item_id';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.order_details od WHERE od.order_id = ANY(v_order_ids)
    GROUP BY od.item_code HAVING count(DISTINCT od.item_id) > 1
  ) THEN
    RAISE EXCEPTION 'item identity is inconsistent across selected orders';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.order_details od
    WHERE od.order_id = ANY(v_order_ids)
      AND NOT EXISTS (SELECT 1 FROM public.items i WHERE i.id = od.item_id AND i.item_code = od.item_code)
  ) THEN
    RAISE EXCEPTION 'one or more order lines do not match Global Item Master';
  END IF;

  SELECT coalesce(max(NULLIF(regexp_replace(rs.runsheet_code, '^RS-', ''), '')::integer), 0)
  INTO v_last_num
  FROM public.runsheets rs
  WHERE rs.company_id = p_company_id AND rs.runsheet_code ~ '^RS-[0-9]+$';

  v_new_code := 'RS-' || (v_last_num + 1)::text;

  INSERT INTO public.runsheets(runsheet_code,run_date,total_amount,status,created_by,company_id)
  VALUES(v_new_code,CURRENT_DATE,v_total_amount,'Open',p_user_email,p_company_id)
  RETURNING id INTO v_runsheet_id;

  UPDATE public.orders
  SET runsheet_id = v_runsheet_id, order_status = 'Pending'
  WHERE id = ANY(v_order_ids) AND company_id = p_company_id AND runsheet_id IS NULL AND order_status IN ('Confirmed', 'Pending');

  IF (SELECT count(*) FROM public.orders o WHERE o.id = ANY(v_order_ids) AND o.runsheet_id = v_runsheet_id AND o.order_status = 'Pending') <> v_order_count THEN
    RAISE EXCEPTION 'runsheet order linkage verification failed';
  END IF;

  INSERT INTO public.run_sheet_details(runsheet_id,item_id,item_code,item_name,unit,unit_price,qty_ordered)
  SELECT
    v_runsheet_id,
    (array_agg(od.item_id ORDER BY od.item_id))[1],
    od.item_code,
    min(od.item_name),
    coalesce(min(od.unit),'حبة'),
    min(od.unit_price),
    sum(coalesce(od.qty,0))
  FROM public.order_details od
  WHERE od.order_id = ANY(v_order_ids)
  GROUP BY od.item_code;

  RETURN jsonb_build_object(
    'success', true,
    'rsId', v_new_code,
    'runsheet_id', v_runsheet_id,
    'ordersCount', v_order_count,
    'itemsCount', (SELECT count(*) FROM public.run_sheet_details rsd WHERE rsd.runsheet_id = v_runsheet_id)
  );
END;
$function$
;
