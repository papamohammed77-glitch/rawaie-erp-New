-- RAWAEA ERP — M5-13 runsheet lifecycle capability
-- UPDATE / CANCEL / DELETE are atomic, company-scoped, and authorized through the Edge capability.

CREATE OR REPLACE FUNCTION public.manage_runsheet_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_operation text,
  p_user_email text,
  p_driver_id uuid DEFAULT NULL,
  p_vehicle_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_rs public.runsheets%ROWTYPE;
  v_orders integer := 0;
  v_details integer := 0;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'company context is required'; END IF;
  IF p_operation NOT IN ('UPDATE','CANCEL','DELETE') THEN RAISE EXCEPTION 'unsupported runsheet operation'; END IF;
  IF NULLIF(btrim(p_runsheet_code),'') IS NULL THEN RAISE EXCEPTION 'runsheet_code is required'; END IF;

  PERFORM set_config('request.jwt.claims', jsonb_build_object('email', COALESCE(NULLIF(btrim(p_user_email),''),'system'))::text, true);

  SELECT * INTO v_rs
  FROM public.runsheets
  WHERE company_id = p_company_id AND runsheet_code = p_runsheet_code
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'الرانشيت غير موجود'; END IF;

  IF p_operation = 'UPDATE' THEN
    IF v_rs.status NOT IN ('Open','Confirmed') THEN
      RAISE EXCEPTION USING MESSAGE = 'لا يمكن تعديل رانشيت في حالة: ' || COALESCE(v_rs.status,'NULL');
    END IF;
    IF p_driver_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = p_driver_id AND u.company_id = p_company_id AND COALESCE(u.status,'Active') = 'Active'
    ) THEN
      RAISE EXCEPTION 'السائق غير صالح للشركة الحالية';
    END IF;
    IF p_vehicle_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.vehicles v
      WHERE v.id = p_vehicle_id AND v.company_id = p_company_id
    ) THEN
      RAISE EXCEPTION 'المركبة غير صالحة للشركة الحالية';
    END IF;

    UPDATE public.runsheets
    SET driver_id = p_driver_id,
        vehicle_id = p_vehicle_id,
        updated_at = now()
    WHERE id = v_rs.id AND company_id = p_company_id AND status IN ('Open','Confirmed');

    IF NOT FOUND THEN RAISE EXCEPTION 'فشل تحديث الرانشيت بسبب تغير الحالة'; END IF;

    RETURN jsonb_build_object('success',true,'operation','UPDATE','runsheet_code',p_runsheet_code,'status',v_rs.status,'driver_id',p_driver_id,'vehicle_id',p_vehicle_id);
  END IF;

  IF v_rs.status NOT IN ('Open','Confirmed') THEN
    RAISE EXCEPTION USING MESSAGE = 'لا يمكن تنفيذ العملية على رانشيت في حالة: ' || COALESCE(v_rs.status,'NULL');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.company_id = p_company_id AND o.runsheet_id = v_rs.id
      AND o.order_status NOT IN ('Pending','Confirmed')
  ) THEN
    RAISE EXCEPTION 'الرانشيت يحتوي على أوردرات تجاوزت مرحلة الإسناد الأولية';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.run_sheet_details d
    WHERE d.runsheet_id = v_rs.id
      AND (COALESCE(d.qty_picked,0) <> 0 OR COALESCE(d.qty_loaded,0) <> 0 OR COALESCE(d.qty_delivered,0) <> 0 OR COALESCE(d.qty_refused,0) <> 0 OR COALESCE(d.qty_returned,0) <> 0 OR COALESCE(d.driver_liability,0) <> 0)
  ) THEN
    RAISE EXCEPTION USING MESSAGE = 'لا يمكن تنفيذ ' || lower(p_operation) || ' على رانشيت بدأ فيه تنفيذ فعلي أو تسويات كمية';
  END IF;

  SELECT count(*) INTO v_orders FROM public.orders WHERE company_id = p_company_id AND runsheet_id = v_rs.id;
  SELECT count(*) INTO v_details FROM public.run_sheet_details WHERE runsheet_id = v_rs.id;

  IF p_operation = 'DELETE' THEN
    UPDATE public.orders SET runsheet_id = NULL, order_status = 'Confirmed', updated_at = now()
    WHERE company_id = p_company_id AND runsheet_id = v_rs.id;
    DELETE FROM public.run_sheet_details WHERE runsheet_id = v_rs.id;
    DELETE FROM public.runsheets WHERE id = v_rs.id AND company_id = p_company_id AND status IN ('Open','Confirmed');
    IF NOT FOUND THEN RAISE EXCEPTION 'فشل حذف الرانشيت بسبب تغير الحالة'; END IF;
    RETURN jsonb_build_object('success',true,'operation','DELETE','runsheet_code',p_runsheet_code,'released_orders',v_orders,'deleted_details',v_details);
  END IF;

  UPDATE public.orders SET runsheet_id = NULL, order_status = 'Confirmed', updated_at = now()
  WHERE company_id = p_company_id AND runsheet_id = v_rs.id;
  DELETE FROM public.run_sheet_details WHERE runsheet_id = v_rs.id;
  UPDATE public.runsheets SET status = 'Cancelled', updated_at = now()
  WHERE id = v_rs.id AND company_id = p_company_id AND status IN ('Open','Confirmed');
  IF NOT FOUND THEN RAISE EXCEPTION 'فشل إلغاء الرانشيت بسبب تغير الحالة'; END IF;

  RETURN jsonb_build_object('success',true,'operation','CANCEL','runsheet_code',p_runsheet_code,'status','Cancelled','released_orders',v_orders,'deleted_details',v_details);
END;
$function$;

REVOKE ALL ON FUNCTION public.manage_runsheet_atomic(uuid,text,text,text,uuid,uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.manage_runsheet_atomic(uuid,text,text,text,uuid,uuid) TO service_role;
