-- RAWAEA ERP — Sales Targets integrity guard ACL hardening
-- Date: 2026-09-14
-- Purpose: remove direct EXECUTE exposure from the trigger guard function.
-- Contract: no business behavior change; trigger execution remains server-side.

BEGIN;

REVOKE ALL ON FUNCTION public.sales_target_integrity_guard()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.sales_target_integrity_guard()
  TO postgres, service_role;

COMMIT;
