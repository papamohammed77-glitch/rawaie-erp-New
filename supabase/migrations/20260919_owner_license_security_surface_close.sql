BEGIN;
REVOKE ALL ON FUNCTION public.guard_app_settings_license_fields() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_company_license_from_app_settings() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.owner_license_admin_atomic(text,uuid,uuid,uuid,text,jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.owner_license_admin_atomic(text,uuid,uuid,uuid,text,jsonb)
  TO service_role;
COMMIT;
