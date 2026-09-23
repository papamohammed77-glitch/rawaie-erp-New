-- RAWAEA ERP — Fleet vehicles projection closure
-- Purpose: expose existing vehicle operational fields already consumed by Mother ERP.
-- No UI change. No new Edge Function. No business-contract change.

DO $migration$
DECLARE
  v_sql text;
  v_old text := E'v.driver_id,v.fleet_driver_id,\n                       COALESCE(';
  v_new text := E'v.driver_id,v.fleet_driver_id,\n                       v.expected_km_per_liter,\n                       v.operational_condition,\n                       v.route_capability,\n                       COALESCE(';
  v_count integer;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO v_sql
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='fleet_query'
  ORDER BY p.oid DESC
  LIMIT 1;

  IF v_sql IS NULL THEN
    RAISE EXCEPTION 'fleet_query definition not found';
  END IF;

  SELECT count(*) INTO v_count
  FROM generate_series(1,length(v_sql)) g(i)
  WHERE substring(v_sql from i for length(v_old))=v_old;

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Unexpected vehicle projection anchor count: %',v_count;
  END IF;

  IF position(v_new in v_sql)>0 THEN
    RETURN;
  END IF;

  v_sql := replace(v_sql,v_old,v_new);
  EXECUTE v_sql;
END
$migration$;
