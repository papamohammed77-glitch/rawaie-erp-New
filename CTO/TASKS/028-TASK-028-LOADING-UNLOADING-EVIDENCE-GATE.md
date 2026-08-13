# TASK-028 — LOADING / UNLOADING CORE

## Status
ACTIVE — EVIDENCE GATE

## Objective
Establish the real Production contract for warehouse Loading and Unloading before any implementation change.

## Current authority
- Active CTO repository: `papamohammed77-glitch/rawaie-erp-New`
- Historical/original repository: `papamohammed77-glitch/rawaie-erp-review`
- Production outranks both.

## Historical source pointers already identified
The historical source map identifies inventory-impact functions including:
- `complete-loading.ts`
- `unload-runsheet.ts`
- `complete-return.ts`
- `save-sales-invoice.ts`
- `update-driver-ledger.ts`

These are behavioral references only until reconciled against current Production.

## First Production Gate — dynamic discovery
Do NOT assume table/function names. Execute the following read-only batch in Production.

```sql
-- 1. Discover tables whose names suggest loading, unloading, load, unload, runsheet,
--    delivery, return, vehicle, driver, shipment, dispatch.
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
      lower(table_name) LIKE '%load%'
      OR lower(table_name) LIKE '%unload%'
      OR lower(table_name) LIKE '%runsheet%'
      OR lower(table_name) LIKE '%delivery%'
      OR lower(table_name) LIKE '%return%'
      OR lower(table_name) LIKE '%dispatch%'
      OR lower(table_name) LIKE '%shipment%'
      OR lower(table_name) LIKE '%vehicle%'
      OR lower(table_name) LIKE '%driver%'
  )
ORDER BY table_name;

-- 2. Discover columns for the discovered operational tables.
SELECT
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    c.is_generated,
    c.generation_expression
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND (
      lower(c.table_name) LIKE '%load%'
      OR lower(c.table_name) LIKE '%unload%'
      OR lower(c.table_name) LIKE '%runsheet%'
      OR lower(c.table_name) LIKE '%delivery%'
      OR lower(c.table_name) LIKE '%return%'
      OR lower(c.table_name) LIKE '%dispatch%'
      OR lower(c.table_name) LIKE '%shipment%'
      OR lower(c.table_name) LIKE '%vehicle%'
      OR lower(c.table_name) LIKE '%driver%'
  )
ORDER BY c.table_name, c.ordinal_position;

-- 3. Discover deployed public functions with operational names.
SELECT
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    p.prosecdef AS security_definer,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.prokind = 'f'
  AND (
      lower(p.proname) LIKE '%load%'
      OR lower(p.proname) LIKE '%unload%'
      OR lower(p.proname) LIKE '%runsheet%'
      OR lower(p.proname) LIKE '%delivery%'
      OR lower(p.proname) LIKE '%return%'
      OR lower(p.proname) LIKE '%dispatch%'
  )
ORDER BY p.proname;

-- 4. Discover triggers on the discovered operational tables.
SELECT
    event_object_table,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND (
      lower(event_object_table) LIKE '%load%'
      OR lower(event_object_table) LIKE '%unload%'
      OR lower(event_object_table) LIKE '%runsheet%'
      OR lower(event_object_table) LIKE '%delivery%'
      OR lower(event_object_table) LIKE '%return%'
      OR lower(event_object_table) LIKE '%dispatch%'
      OR lower(event_object_table) LIKE '%shipment%'
  )
ORDER BY event_object_table, trigger_name;

-- 5. Discover foreign keys involving the discovered operational tables.
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND (
      lower(tc.table_name) LIKE '%load%'
      OR lower(tc.table_name) LIKE '%unload%'
      OR lower(tc.table_name) LIKE '%runsheet%'
      OR lower(tc.table_name) LIKE '%delivery%'
      OR lower(tc.table_name) LIKE '%return%'
      OR lower(tc.table_name) LIKE '%dispatch%'
      OR lower(tc.table_name) LIKE '%shipment%'
  )
ORDER BY tc.table_name, tc.constraint_name, kcu.column_name;
```

## Acceptance criteria for the Evidence Gate
Do not implement anything until the Production result is sufficient to determine:

1. Exact loading object(s).
2. Exact unloading object(s).
3. Exact runsheet object(s) involved.
4. Exact current Production RPC/function(s).
5. Exact stock-impact path.
6. Exact relation to vehicle/mobile branch.
7. Exact relation to orders/runsheets/delivery/returns.
8. Exact state transitions.
9. Exact audit/log path.
10. Exact concurrency/locking behavior.

## Next step after evidence
Compare the discovered Production contract against:
- original `complete-loading.ts`
- original `unload-runsheet.ts`
- relevant original loader/unloader PWA applications
- current source if present in `rawaie-erp-New`
- Gold reference applications

Then produce the TASK-028 Target Contract and only then prepare a permanent Production patch.

## Hard stop
If Production evidence cannot prove the loading/unloading topology, TASK-028 remains `EVIDENCE REQUIRED` and no implementation SQL is authorized.
