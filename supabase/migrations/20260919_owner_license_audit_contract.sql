-- Applied as second migration: audit_log.action must remain within its existing contract.
-- The final owner_license_admin_atomic body is persisted by the foundation migration.
-- This file documents the surgical audit compatibility step already applied to Production.

DO $$
DECLARE
  src text;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO src
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='owner_license_admin_atomic'
    AND pg_get_function_identity_arguments(p.oid)='p_action text, p_company_id uuid, p_actor_user_id uuid, p_actor_auth_id uuid, p_actor_email text, p_payload jsonb';
  IF src IS NULL THEN RAISE EXCEPTION 'owner_license_admin_atomic definition not found'; END IF;
  src := replace(src, 'CASE WHEN v_old = v_new THEN ''license.noop'' ELSE ''license.update'' END', '''update''');
  EXECUTE src;
END $$;
