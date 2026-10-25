-- RAWAEA ERP: atomically assign a valid mobile-stock vehicle and start loading.
-- Preserves the existing 3-argument RPC contract for legacy callers.
-- The selected vehicle update and start transition run in the same PostgreSQL transaction.

CREATE OR REPLACE FUNCTION public.start_runsheet_loading_with_vehicle(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text,
  p_vehicle_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v public.vehicles%ROWTYPE;
  r public.runsheets%ROWTYPE;
  result jsonb;
BEGIN
  IF p_company_id IS NULL
     OR NULLIF(btrim(p_runsheet_code), '') IS NULL
     OR NULLIF(btrim(p_user_email), '') IS NULL
     OR p_vehicle_id IS NULL THEN
    RAISE EXCEPTION 'invalid Loading start request: company, runsheet, user and vehicle are required';
  END IF;

  -- Lock the selected vehicle so concurrent attempts cannot assign it to
  -- multiple runsheets that are entering Loading at the same time.
  SELECT * INTO v
  FROM public.vehicles
  WHERE id = p_vehicle_id
    AND company_id = p_company_id
    AND status = 'Active'
    AND mobile_stock_enabled IS TRUE
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المركبة المختارة غير نشطة أو لا تتبع الشركة أو لا تدعم مخزون المركبة';
  END IF;

  -- Lock and validate the target runsheet before changing its vehicle.
  SELECT * INTO r
  FROM public.runsheets
  WHERE company_id = p_company_id
    AND runsheet_code = p_runsheet_code
  FOR UPDATE;

  IF NOT FOUND OR r.status <> 'Picked' THEN
    RAISE EXCEPTION 'لا يمكن إسناد المركبة إلا لرانشيت حالته Picked';
  END IF;

  UPDATE public.runsheets
  SET vehicle_id = p_vehicle_id,
      updated_at = now()
  WHERE id = r.id
    AND company_id = p_company_id
    AND status = 'Picked';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'تعذر إسناد المركبة للرانشيت';
  END IF;

  -- Existing canonical transition validates mobile branch identity,
  -- vehicle availability, user exclusivity, and lifecycle rules.
  -- Any exception rolls back the vehicle assignment above.
  result := public.start_runsheet_loading(
    p_company_id,
    p_runsheet_code,
    p_user_email
  );

  RETURN result || jsonb_build_object('vehicle_id', p_vehicle_id);
END;
$function$;

REVOKE ALL ON FUNCTION public.start_runsheet_loading_with_vehicle(uuid, text, text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.start_runsheet_loading_with_vehicle(uuid, text, text, uuid) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.start_runsheet_loading_with_vehicle(uuid, text, text, uuid) TO service_role;
