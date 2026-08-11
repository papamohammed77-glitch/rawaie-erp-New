-- RAWAEA ERP — EVIDENCE-015
-- Full Production Schema Dependency Closure
-- PURPOSE: prove the actual Production contract for Inventory Core tables.
-- RUN IN SUPABASE SQL EDITOR AGAINST THE PRODUCTION DATABASE.
-- READ-ONLY: SELECT / WITH statements only. No INSERT / UPDATE / DELETE / ALTER / DROP.
--
-- Save the complete result as:
-- SQL_Evidence/diagnostics/EVIDENCE-015-Full-Production-Schema-Dependency-Closure.csv
-- or, if multiple result sets are exported separately, keep the same EVIDENCE-015 prefix.

-- ============================================================
-- 1) Exact table columns + defaults + generated expressions
-- ============================================================
SELECT
  c.table_schema,
  c.table_name,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_schema,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  c.is_identity,
  c.identity_generation,
  c.is_generated,
  c.generation_expression
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY c.table_name, c.ordinal_position;

-- ============================================================
-- 2) Primary keys / unique constraints / check constraints / FKs
-- ============================================================
SELECT
  tc.table_schema,
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  kcu.ordinal_position,
  ccu.table_schema AS referenced_schema,
  ccu.table_name AS referenced_table,
  ccu.column_name AS referenced_column,
  cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
  ON tc.constraint_schema = kcu.constraint_schema
 AND tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
 AND tc.table_name = kcu.table_name
LEFT JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_schema = ccu.constraint_schema
 AND tc.constraint_name = ccu.constraint_name
LEFT JOIN information_schema.check_constraints cc
  ON tc.constraint_schema = cc.constraint_schema
 AND tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY tc.table_name, tc.constraint_name, kcu.ordinal_position;

-- ============================================================
-- 3) Index definitions — exact Production definitions
-- ============================================================
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY tablename, indexname;

-- ============================================================
-- 4) Foreign-key dependencies in both directions
-- ============================================================
SELECT
  con.conname AS constraint_name,
  nsp.nspname AS table_schema,
  cls.relname AS table_name,
  att.attname AS column_name,
  fnsp.nspname AS referenced_schema,
  fcls.relname AS referenced_table,
  fatt.attname AS referenced_column,
  pg_get_constraintdef(con.oid, true) AS constraint_definition
FROM pg_constraint con
JOIN pg_class cls ON cls.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = cls.relnamespace
JOIN pg_class fcls ON fcls.oid = con.confrelid
JOIN pg_namespace fnsp ON fnsp.oid = fcls.relnamespace
LEFT JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ord) ON true
LEFT JOIN LATERAL unnest(con.confkey) WITH ORDINALITY AS fcols(attnum, ord)
  ON fcols.ord = cols.ord
LEFT JOIN pg_attribute att
  ON att.attrelid = con.conrelid AND att.attnum = cols.attnum
LEFT JOIN pg_attribute fatt
  ON fatt.attrelid = con.confrelid AND fatt.attnum = fcols.attnum
WHERE con.contype = 'f'
  AND (
       cls.relname IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
       OR fcls.relname IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
  )
ORDER BY table_name, constraint_name, cols.ord;

-- ============================================================
-- 5) Triggers on the Inventory/Voucher tables
-- ============================================================
SELECT
  n.nspname AS table_schema,
  c.relname AS table_name,
  t.tgname AS trigger_name,
  pg_get_triggerdef(t.oid, true) AS trigger_definition,
  p.proname AS trigger_function
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_proc p ON p.oid = t.tgfoid
WHERE NOT t.tgisinternal
  AND n.nspname = 'public'
  AND c.relname IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY c.relname, t.tgname;

-- ============================================================
-- 6) RLS status + policies
-- ============================================================
SELECT
  n.nspname AS table_schema,
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS force_rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY c.relname;

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY tablename, policyname;

-- ============================================================
-- 7) Views / rules / dependencies referencing Inventory Core
-- ============================================================
SELECT
  n.nspname AS dependent_schema,
  c.relname AS dependent_object,
  c.relkind,
  pg_get_viewdef(c.oid, true) AS view_definition
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class c ON c.oid = r.ev_class
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_class referenced ON referenced.oid = d.refobjid
JOIN pg_namespace rn ON rn.oid = referenced.relnamespace
WHERE rn.nspname = 'public'
  AND referenced.relname IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
  AND c.relkind IN ('v','m')
ORDER BY dependent_schema, dependent_object;

-- ============================================================
-- 8) Functions/RPCs whose stored source references Inventory Core
-- ============================================================
SELECT
  n.nspname AS routine_schema,
  p.proname AS routine_name,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND (
       pg_get_functiondef(p.oid) ILIKE '%stock_branches%'
    OR pg_get_functiondef(p.oid) ILIKE '%inventory_log%'
    OR pg_get_functiondef(p.oid) ILIKE '%stock_vouchers%'
    OR pg_get_functiondef(p.oid) ILIKE '%stock_voucher_details%'
    OR pg_get_functiondef(p.oid) ILIKE '%allocated_qty%'
  )
ORDER BY p.proname, identity_arguments;

-- ============================================================
-- 9) Sequence/identity ownership for relevant columns
-- ============================================================
SELECT
  table_schema,
  table_name,
  column_name,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
  AND (
       column_default LIKE 'nextval%'
    OR is_identity = 'YES'
  )
ORDER BY table_name, ordinal_position;

-- ============================================================
-- 10) Table row estimates — context only, NOT balances
-- ============================================================
SELECT
  schemaname,
  relname AS table_name,
  n_live_tup AS estimated_rows,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND relname IN ('stock_branches','inventory_log','stock_vouchers','stock_voucher_details')
ORDER BY relname;

-- END EVIDENCE-015
