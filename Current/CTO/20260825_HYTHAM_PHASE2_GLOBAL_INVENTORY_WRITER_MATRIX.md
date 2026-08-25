# RAWAEA ERP — PHASE 2 HYTHAM GLOBAL INVENTORY WRITER MATRIX

Date: 2026-08-25
Role: Hytham
Authority: Production PostgreSQL > Current main > Current CTO evidence > historical sources > reports
Production: SMART ERP / fiilmooggumokxanwiyx

## 1. Fresh Production Baseline

The baseline was re-queried during execution and is newer than prior snapshots.

- Companies: 1
- Company: `00000000-0000-0000-0000-000000000001`
- Branches: 2
- Items: 17
- Stock rows: 20
- Inventory log rows: 3
- Stock vouchers: 0
- Orders: 0
- Purchase Orders: 0
- Runsheets: 0
- Suppliers: 1
- Customers: 3
- Vehicles: 0
- Drivers: 0
- Treasury: 1
- Chart of Accounts: 17

## 2. Immutable Contract

```text
Physical Movement
    -> post_stock_movement
    -> stock_branches + inventory_log

Reservation
    -> reserve_stock / release_stock_reservation
    -> allocated_qty only
```

No parallel Physical Stock engine is authorized.

## 3. Direct Writer Sweep Result

Production `pg_proc` definitions were searched for direct writes affecting `stock_branches` and `inventory_log`.

### Canonical Physical Writer

`post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)`

Directly mutates Physical Stock and writes `inventory_log`.

### Reservation writers

`reserve_stock(uuid,uuid,uuid,numeric)`

`release_stock_reservation(uuid,uuid,uuid,numeric)`

They mutate `allocated_qty` only and do not create physical movements.

### Initialization-only writer

`setup_van_stock(uuid)` inserts zero-balance `stock_branches` rows for a VAN branch and does not write `inventory_log`.

Classification: INITIALIZATION, not Physical Movement.

### Bridges

The following operational functions were verified as bridges to the canonical physical writer rather than parallel writers:

- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `receive_purchase_atomic`
- `save_sales_invoice_atomic`
- `complete_return_atomic`
- `complete_runsheet_loading`
- `complete_runsheet_unloading`
- `complete_runsheet_reopen_loading`
- `post_inventory_adjustment_atomic`

Picking uses `reserve_stock` and does not write Physical Stock.

## 4. Trigger Sweep

Non-internal triggers were inspected for references to `stock_branches` / `inventory_log`.
No trigger writer was found that creates a parallel Physical Stock mutation path.

## 5. Manual Voucher Closure

### Production contract verified

Supported lifecycle:

```text
Draft
  -> Sent
  -> Partial Receive (remains Sent)
  -> Received
  -> Completed
```

Cancellation is allowed only from Draft and returns a Cancelled state without physical movement.

### Transactional evidence

A Production SQL transaction successfully proved:

- Create Transfer voucher
- SEND => `Sent`
- RECEIVE => `Received`
- Same receive `operation_id` repeated => `duplicate=true`
- Partial receive `0.4` => `Sent`
- Final receive `0.6` => `Received`
- Complete => `Completed`
- Rollback => no retained fixture

### Legacy retirement

`receive_manual_stock_voucher_v2` was found in Production but had no EXECUTE privilege for `anon`, `authenticated`, or `service_role`, and the current `receive-stock-voucher` Edge wrapper does not call it.
It was therefore formally retired from Production and recorded in:

`supabase/migrations/20260825210000_retire_receive_manual_stock_voucher_v2.sql`

## 6. Inventory Adjustment Closure Evidence

Production transactional canary:

- `InventoryIncrease`
- quantity `0.5`
- same deterministic adjustment key retried
- no second physical movement
- transaction rolled back

## 7. Purchase Receiving — Defect Found and Fixed

Transactional canary discovered a real Production defect:
`post_journal_entry` returns JSONB, while `receive_purchase_atomic` attempted to assign the complete JSONB directly to a UUID variable.

Observed failure:
`22P02 invalid input syntax for type uuid`

Surgical fix applied in Production:

```text
post_journal_entry(...)->>'entry_id'::uuid
```

Canonical migration recorded:

`supabase/migrations/20260825214500_fix_receive_purchase_journal_result_cast.sql`

After the fix, a Production transaction proved:

- Purchase Order exists
- PurchaseIn movement is posted through `post_stock_movement`
- Journal posting succeeds
- Supplier ledger posting succeeds
- first operation succeeds
- exact same operation_id returns `duplicate=true`
- transaction rollback leaves no test residue

## 8. Picking / Reservation Evidence

Production transactional canary proved:

- `complete_runsheet_picking` reserves stock through `reserve_stock`
- `inventory_log_written=false`
- exact same `operation_id` returns `duplicate=true`
- no Physical Stock movement is produced by Picking
- rollback leaves reservation/data clean

## 9. POS / Return / Loading / Unloading / Van Sales

Production definitions confirm these paths bridge to `post_stock_movement`.
However, current Production has:

- Vehicles: 0
- Drivers: 0
- Orders: 0
- Runsheets: 0

Therefore full authenticated runtime proof for Van Sales, Returns, Loading, Unloading, and Delivery cannot be truthfully claimed from the current data set.
Their SQL contract and writer classification are verified; their operational closure remains runtime-gated.

## 10. Tenant / Item Identity

Production is currently single-company.
`item_code` is globally unique in the current schema and remains global identity.
Movement boundaries validate branch/company context.

## 11. Financial Security Boundary Fixed

Direct DML privileges on the following financial tables were removed from `anon` and `authenticated` while preserving SELECT:

- `journal_entries`
- `journal_lines`
- `customer_ledger`
- `supplier_ledger`
- `driver_ledger`
- `treasury`
- `cash_box`
- `daily_settlements`

Migration:

`supabase/migrations/20260825213000_financial_table_dml_boundary.sql`

Post-change verification confirms `anon/authenticated = SELECT only` on these tables.

## 12. Self-Audit

### Confirmed facts

- Physical writer outside `post_stock_movement`: 0
- Reservation is separate
- Manual Voucher lifecycle tested transactionally
- Manual receive duplicate tested
- Partial receive tested
- Adjustment retry tested
- Purchase Receiving defect discovered and fixed
- Purchase duplicate tested
- Picking reservation/duplicate tested
- Legacy receive V2 retired after consumer/reachability proof
- Financial direct DML boundary tightened
- Current COA = 17

### Unknown / still unverified

- Authenticated HTTP E2E for every critical writer
- Two independent concurrent HTTP sessions for every critical writer
- Full deployed Edge byte/hash parity for every inventory consumer
- Full Current/PWA consumer runtime proof for each closure unit
- Van/Return/Loading/Unloading runtime proof with real operational fixtures
- Full end-to-end reconciliation of stock branches versus inventory logs versus business documents after live workloads

### Current Production verified

Yes for SQL-level core, identity, state transition, idempotency, and rollback canaries.

### Runtime verified

Only SQL transactional canaries are currently proven. HTTP runtime and two-session concurrency remain open because the current Production dataset has no vehicles/orders/runsheets and the available execution channel does not expose independent authenticated HTTP sessions.

## 13. Current Phase 2 Status

`GLOBAL WRITER DISCOVERY = VERIFIED AT SQL LEVEL`

`MANUAL VOUCHER = SUBSTANTIVELY CLOSED, RUNTIME GATE OPEN`

`PURCHASE RECEIVING = CORE CLOSED AFTER DEFECT FIX, RUNTIME GATE OPEN`

`INVENTORY ADJUSTMENT = CORE CLOSED, RUNTIME GATE OPEN`

`PICKING / RESERVATION = CORE CLOSED, RUNTIME GATE OPEN`

`POS / VAN SALES / RETURNS / LOADING / UNLOADING = SQL CONTRACT VERIFIED, RUNTIME GATE OPEN`

`PHASE 2 GLOBAL ZERO-DEBT = NOT CLOSED`

## 14. Rule for Continuation

Continue directly into the remaining independent work. Do not rebuild Inventory Core. Any new Production defect discovered by canary becomes an immediate surgical fix with:

`DISCOVER -> ROOT CAUSE -> FIX -> TEST -> ROLLBACK/VERIFY -> MIGRATION -> RECORD -> CONTINUE`

