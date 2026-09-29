-- Production defect repair for inventory_voucher_report SUMMARY aggregations.
-- The existing function is preserved; this repair records the two required GROUP BY clauses.
DO $$
DECLARE
  src text;
  pos integer;
  tail text;
  inj_at integer;
BEGIN
  SELECT pg_get_functiondef('public.inventory_voucher_report(text,jsonb)'::regprocedure) INTO src;
  pos := strpos(src, 'SELECT v.type,count(*) cnt');
  IF pos = 0 THEN RAISE EXCEPTION 'type aggregation block not found'; END IF;
  tail := substr(src, pos);
  inj_at := strpos(tail, E'\n    ) x;');
  IF inj_at = 0 THEN RAISE EXCEPTION 'type aggregation terminator not found'; END IF;
  inj_at := pos + inj_at - 1;
  IF strpos(substr(src, pos, inj_at-pos), 'GROUP BY v.type') = 0 THEN
    src := left(src, inj_at-1) || E'\n      GROUP BY v.type' || substr(src, inj_at);
  END IF;
  pos := strpos(src, 'SELECT v.status,count(*) cnt');
  IF pos = 0 THEN RAISE EXCEPTION 'status aggregation block not found'; END IF;
  tail := substr(src, pos);
  inj_at := strpos(tail, E'\n    ) x;');
  IF inj_at = 0 THEN RAISE EXCEPTION 'status aggregation terminator not found'; END IF;
  inj_at := pos + inj_at - 1;
  IF strpos(substr(src, pos, inj_at-pos), 'GROUP BY v.status') = 0 THEN
    src := left(src, inj_at-1) || E'\n      GROUP BY v.status' || substr(src, inj_at);
  END IF;
  EXECUTE src;
END$$;
