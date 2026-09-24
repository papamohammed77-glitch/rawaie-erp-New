-- RAWAEA ERP — Fleet Direct Sales Rep candidate/bind permission convergence
-- Closure unit: Fleet Vehicle Operation Binding / Direct Sale
-- Production migration executed 2026-09-24 as 20260924130417_align_fleet_direct_sales_rep_permission_20260924_v3.
-- Purpose: make the Fleet candidate list and bind guard use the same operation-level
-- Direct Sales Rep contract already enforced by the mobile-voucher custody guard:
-- active + same company + role = مندوب بيع مباشر + permission = van-sales.
-- No new Edge Function. No Physical Stock writer change.

BEGIN;

DO $$
DECLARE
  v_def text;
  v_new text;
  old_block text := E'            AND u.role=''مندوب بيع مباشر''\n';
  new_block text := E'            AND u.role=''مندوب بيع مباشر''\n            AND COALESCE(u.permissions,''[]''::jsonb) @> ''["van-sales"]''::jsonb\n';
  occurrences integer;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.prokind='f'
    AND p.proname='fleet_command_atomic'
  ORDER BY p.oid DESC
  LIMIT 1;

  occurrences := (length(v_def)-length(replace(v_def,old_block,''))) / NULLIF(length(old_block),0);
  IF occurrences<>1 THEN
    RAISE EXCEPTION 'fleet_command direct-sales role anchor count=%',occurrences;
  END IF;

  v_new:=replace(v_def,old_block,new_block);
  EXECUTE v_new;
END $$;

DO $$
DECLARE
  v_def text;
  v_new text;
  old_block text := E'                u.role=''مندوب بيع مباشر''\n                OR COALESCE(u.permissions,''[]''::jsonb) @> ''["van-sales"]''::jsonb\n';
  new_block text := E'                u.role=''مندوب بيع مباشر''\n                AND COALESCE(u.permissions,''[]''::jsonb) @> ''["van-sales"]''::jsonb\n';
  occurrences integer;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.prokind='f'
    AND p.proname='fleet_query'
  ORDER BY p.oid DESC
  LIMIT 1;

  occurrences := (length(v_def)-length(replace(v_def,old_block,''))) / NULLIF(length(old_block),0);
  IF occurrences<>1 THEN
    RAISE EXCEPTION 'fleet_query direct-sales role anchor count=%',occurrences;
  END IF;

  v_new:=replace(v_def,old_block,new_block);
  EXECUTE v_new;
END $$;

COMMIT;
