# TASK-028 — STATIC VALIDATION RESULT

**Date:** 2026-08-14
**Branch:** `task-028-loading-unloading-refactor`
**PR:** #3
**Production:** UNCHANGED
**Original:** UNCHANGED

## Result

**STATIC VALIDATION = PASS WITH EXECUTION GATE OPEN**

The final repository migration is now a single file:

`supabase/migrations/20260814_task028_loading_unloading_atomic_core_final.sql`

The obsolete `20260814_task028_central_stock_engine_rewire_v2.sql` and the superseded v1 migration were removed from this branch.

## Verified

- `post_stock_movement` includes `Loading` and `Unloading`.
- Loading validates and consumes picked reservation (`allocated_qty`), not `available_qty`.
- Loading mutates `MAIN.qty - qty`, `MAIN.allocated_qty - qty`, `VAN.qty + qty`.
- Unloading mutates `VAN.qty - qty`, `MAIN.qty + qty`, `MAIN.allocated_qty + qty`.
- Loading/Unloading use the same central stock mutation engine.
- `available_qty` is never written directly.
- `order_details` is the authoritative fulfillment layer; `sync_run_sheet_details()` remains the derived aggregation path.
- No COGS/journal posting is created by Loading/Unloading.
- Core functions and wrappers require authenticated execution and production function grants remain untouched.
- `fulfillment_backorders` has FK relationships to company/order/order_detail/runsheet/item plus unique `(order_detail_id, runsheet_id)`.
- Backorder table has RLS enabled; service role owns the write path.
- Failure paths occur inside one PostgreSQL function transaction and therefore roll back together.
- Retry safety at the runsheet boundary is state-gated: a completed Loading/Unloading request cannot execute again because the required state is no longer present.

## Remaining Execution Validation

Static repository review cannot prove PostgreSQL parser acceptance, live trigger behavior, locking behavior, or runtime rollback. Those require the authorized non-production Supabase environment.

**Next gate:** apply final migration to `rawaea-staging`, inspect deployed definitions, then execute the full TASK-028 runtime matrix.
