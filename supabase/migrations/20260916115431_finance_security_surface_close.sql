DO $$
DECLARE
  r record;
  sig text;
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name,
           p.proname AS function_name,
           pg_get_function_identity_arguments(p.oid) AS identity_args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'finance_%'
  LOOP
    sig := format('%I.%I(%s)', r.schema_name, r.function_name, r.identity_args);
    EXECUTE 'REVOKE ALL ON FUNCTION ' || sig || ' FROM PUBLIC, anon';
  END LOOP;
END $$;
