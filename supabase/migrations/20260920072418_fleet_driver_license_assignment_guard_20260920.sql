-- RAWAEA ERP — Fleet driver license assignment guard
-- Applied to Production as migration fleet_driver_license_assignment_guard_20260920
BEGIN;

DO $block$
DECLARE
  d text;
  old text;
  new text;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO d
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='fleet_command_atomic';

  old := $q$      IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
        SELECT 1 FROM public.users u
        WHERE u.id=v_driver_user_id AND u.company_id=p_company_id AND coalesce(u.status,'Active')='Active'
      ) THEN RAISE EXCEPTION 'السائق التشغيلي غير صالح للشركة'; END IF;

      SELECT
$q$;

  IF strpos(d,old)=0 THEN
    RAISE EXCEPTION 'fleet license guard insertion anchor missing';
  END IF;

  new := $q$      IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
        SELECT 1 FROM public.users u
        WHERE u.id=v_driver_user_id AND u.company_id=p_company_id AND coalesce(u.status,'Active')='Active'
      ) THEN RAISE EXCEPTION 'السائق التشغيلي غير صالح للشركة'; END IF;

      IF v_fleet_driver_id IS NOT NULL THEN
        DECLARE
          v_license_expiry date;
        BEGIN
          SELECT d.expiry_date INTO v_license_expiry
          FROM public.fleet_driver_documents d
          WHERE d.company_id=p_company_id
            AND d.fleet_driver_id=v_fleet_driver_id
            AND d.document_type='DriverLicense'
            AND coalesce(d.status,'Active')='Active'
          ORDER BY d.expiry_date DESC NULLS LAST,d.created_at DESC
          LIMIT 1;

          IF v_license_expiry IS NOT NULL AND v_license_expiry < current_date THEN
            RAISE EXCEPTION 'رخصة السائق منتهية في %',v_license_expiry;
          END IF;

          IF v_license_expiry IS NULL THEN
            v_warning:=coalesce(v_warning || ' | ','') || 'صلاحية رخصة السائق غير مؤكدة';
          END IF;
        END;
      END IF;

      SELECT
$q$;

  d:=replace(d,old,new);
  EXECUTE d;
END $block$;

COMMIT;
