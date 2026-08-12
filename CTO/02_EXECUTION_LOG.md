# RAWAEA ERP — CENTRAL CTO EXECUTION LOG

## Purpose
Mandatory chronological record of tasks, evidence, decisions, tests, gates, and unresolved conflicts.

## Control rule
No task is considered complete unless its evidence, decision, implementation status, test status, rollback status, and gate are recorded here or in a linked durable task report.

---

## TASK-004 — Production RPC Contract / Manual Voucher Send Path

**Status:** IN PROGRESS — STAGE 3 NEXT

### Confirmed evidence captured
- `create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)` is `SECURITY DEFINER` and creates a `Draft` Manual Voucher.
- `complete_manual_stock_voucher_atomic(uuid,text,text)` is `SECURITY DEFINER` and transitions `Sent` → `Completed` for `DirectSale`/`SupplierReturn`, and `Received` → `Completed` for `Transfer`/`DirectReturn`.
- COMPLETE writes `completed_by` and `completed_at`.
- Production inventory RPC evidence includes both:
  - `send_stock_voucher_atomic(uuid,text,text)`
  - `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` with `SEND` / `RECEIVE` operations.
- A persistent test fixture was created successfully outside the earlier rollback transaction:
  - company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
  - source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
  - target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
  - item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
  - quantity `1`
  - generated voucher `IN-1`
  - current voucher id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`
  - reference `TEST-004-PERSISTENT`
  - notes `TEST-004 PERSISTENT FIXTURE`
- Previous transactional fixture `IN-1` (`4062e2c6-f683-4a9c-bdc9-89705dbc7a7e`) was verified absent from `stock_vouchers` before the persistent fixture was recreated.

### STAGE 1 — CREATE
**Result: PASS**
- `create_manual_stock_voucher_atomic(...)` returned success for the persistent fixture.
- Voucher created in `public.stock_vouchers` with initial `Draft` state.

### STAGE 2 — SEND
**Result: PASS**
- Voucher `IN-1` transitioned to `Sent`.
- `sent_date` was populated.
- BR-01 stock for item 1004 changed from `206` to `205`.
- `allocated_qty` remained `0`.
- `available_qty` became `205`.
- One `inventory_log` row was produced for voucher `IN-1`, movement type `DirectSale`, quantity `1`, user `test-operator@rawaea.local`.
- No `COMMIT` was performed as part of the controlled stage execution after the persistent fixture was created; the persistent fixture itself was intentionally created outside the rollback test transaction.

### Current decision
STAGE 2 is closed as PASS for the tested atomic SEND path.
The tested SEND engine was `post_manual_stock_voucher_atomic(...)` with `SEND` and an explicit `OUT` effect from BR-01 for item 1004 quantity 1.

### Current Gate
Proceed immediately to **STAGE 3 — COMPLETE** for the same persistent voucher fixture.

### No production patch approved
None.
