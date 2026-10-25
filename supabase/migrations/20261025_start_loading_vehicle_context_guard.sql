-- 20261025_start_loading_vehicle_context_guard
-- Prevents a runsheet with no valid company-scoped mobile-stock vehicle from
-- entering Loading, which otherwise makes complete_runsheet_loading fail after
-- the UI has already started a loading session.
CREATE OR REPLACE FUNCTION public.start_runsheet_loading(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  r public.runsheets%ROWTYPE;
  u public.users%ROWTYPE;
  v public.vehicles%ROWTYPE;
  new_cycle uuid;
BEGIN
  IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code), '') IS NULL
     OR NULLIF(btrim(p_user_email), '') IS NULL THEN
    RAISE EXCEPTION 'invalid Loading start request';
  END IF;

  SELECT * INTO u
  FROM public.users
  WHERE email = p_user_email
    AND company_id = p_company_id
    AND COALESCE(status, 'Active') = 'Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'user is not registered in company';
  END IF;

  SELECT runsheet_code INTO r.runsheet_code
  FROM public.runsheets
  WHERE company_id = p_company_id
    AND status = 'Loading'
    AND loader_id = u.id
  LIMIT 1;

  IF r.runsheet_code IS NOT NULL THEN
    RAISE EXCEPTION 'user already has Loading runsheet: %', r.runsheet_code;
  END IF;

  SELECT * INTO r
  FROM public.runsheets
  WHERE company_id = p_company_id
    AND runsheet_code = p_runsheet_code
  FOR UPDATE;

  IF NOT FOUND OR r.status <> 'Picked' THEN
    RAISE EXCEPTION 'runsheet is not Picked';
  END IF;

  -- A loading cycle must be tied to a real, active vehicle in the same company.
  IF r.vehicle_id IS NULL THEN
    RAISE EXCEPTION 'لا يمكن بدء التحميل قبل إسناد مركبة للرانشيت';
  END IF;

  SELECT * INTO v
  FROM public.vehicles
  WHERE id = r.vehicle_id
    AND company_id = p_company_id
    AND status = 'Active'
    AND mobile_stock_enabled IS TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المركبة المسندة غير نشطة أو لا تدعم مخزون المركبة';
  END IF;

  IF v.mobile_branch_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.branches b
    WHERE b.id = v.mobile_branch_id
      AND b.company_id = p_company_id
      AND b.is_active IS TRUE
      AND b.branch_code = 'VAN-' || v.vehicle_code
  ) THEN
    RAISE EXCEPTION 'فرع مخزون المركبة غير صالح أو غير نشط';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.runsheets other_rs
    WHERE other_rs.company_id = p_company_id
      AND other_rs.id <> r.id
      AND other_rs.vehicle_id = r.vehicle_id
      AND other_rs.status = 'Loading'
  ) THEN
    RAISE EXCEPTION 'المركبة مسندة بالفعل إلى رانشيت قيد التحميل';
  END IF;

  new_cycle := gen_random_uuid();

  UPDATE public.runsheets
  SET status = 'Loading',
      loader_id = u.id,
      loader_start = clock_timestamp(),
      loader_end = NULL,
      loading_cycle_id = new_cycle,
      updated_at = now()
  WHERE id = r.id
    AND company_id = p_company_id
    AND status = 'Picked';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'start transition failed';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'runsheet_id', r.id,
    'status', 'Loading',
    'loading_cycle_id', new_cycle,
    'vehicle_id', r.vehicle_id,
    'mobile_branch_id', v.mobile_branch_id
  );
END;
$function$;
