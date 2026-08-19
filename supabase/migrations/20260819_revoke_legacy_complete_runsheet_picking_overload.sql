-- RAWAEA ERP — retire legacy complete_runsheet_picking overload
-- Production applied during forensic verification on 2026-08-19.
-- The canonical application contract is the overload that accepts p_operation_id.

REVOKE EXECUTE ON FUNCTION public.complete_runsheet_picking(uuid,text,text,jsonb)
  FROM PUBLIC, anon, authenticated, service_role;
