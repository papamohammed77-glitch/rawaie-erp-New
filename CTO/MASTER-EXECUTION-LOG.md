# RAWAEA ERP — CTO MASTER EXECUTION LOG

## Purpose
Central tracking record for the Inventory / Vouchers / Van Sales rescue plan.

## Operating Rule
Every Task records: Task ID → objective → evidence reviewed → findings → decision → implementation status → tests → Gate → next Task.

No task may silently overwrite a previous conclusion. Corrections must be appended with date/time and evidence reference.

## Approved Decomposition
- Phase A — Truth Baseline
  - TASK-001 Project Baseline — COMPLETE / GO
  - TASK-002 Inventory Data Contract — COMPLETE / GO
  - TASK-003 Voucher Data Contract
  - TASK-004 Production RPC Contract
- Phase B — Movement Understanding
  - TASK-005 Voucher State Machine
  - TASK-006 Inventory Movement Matrix
  - TASK-007 Custody Matrix
  - TASK-008 Movement Types Contract
- Phase C — Critical Risks
  - TASK-009 Partial Receive Contract
  - TASK-010 Idempotency Contract
  - TASK-011 Concurrency Contract
  - TASK-012 Atomic Transaction Contract
- Phase D — Inventory Core
  - TASK-013 Stock Engine Design
  - TASK-014 Stock Engine Implementation
  - TASK-015 Stock Engine Tests
  - TASK-016 Stock Engine Gate
- Phase E — Manual Vouchers
  - TASK-017 through TASK-024
- Phase F — vouchers.html
  - TASK-025 through TASK-027
- Phase G — Loading / Unloading
  - TASK-028 through TASK-032
- Phase H — Van Sales
  - TASK-033 through TASK-038
- Phase I — Edge Functions
  - TASK-039 through TASK-044
- Phase J — Accounting / Audit / Security
  - TASK-045 through TASK-049
- Phase K — Final Verification / Production
  - TASK-050 through TASK-055

## Current State
### TASK-001
Status: COMPLETE / GO.
Baseline established with explicit separation of Production Evidence, Current Source, Legacy/Historical material and Target/Unreleased candidates.

### TASK-002
Status: COMPLETE / GO.
Production Inventory Data Contract closed from EVIDENCE-015 and its split result files.

Confirmed:
- `stock_branches.qty` is the current physical stock balance.
- `stock_branches.allocated_qty` is reserved stock and is not itself a movement.
- `stock_branches.available_qty` is a database-generated column: `qty - allocated_qty`.
- `stock_branches` is unique on `(branch_id,item_id)` and references `branches` and `items`.
- `inventory_log` is the historical movement record, not the current stock balance.
- `inventory_log.branch_id` is absent from the captured Production schema.
- Inventory/Voucher PKs, relevant FKs, unique constraints and Production indexes are now captured.
- A Production audit trigger exists on `stock_vouchers`.
- Inventory Core view/materialized-view dependency query returned no rows.

Residual items are intentionally deferred:
- movement-type enforcement → TASK-008
- Voucher lifecycle → TASK-003 / TASK-005
- RPC behavior → TASK-004
- concurrency/idempotency → TASK-010 / TASK-011
- RLS/security hardening → TASK-049

## TASK-004 — Production RPC Contract
**Status:** IN PROGRESS — STAGE 3 NEXT

### STAGE 1 — CREATE
**PASS**
A persistent test fixture was created successfully using the confirmed Production CREATE RPC.
- company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
- target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
- item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
- quantity `1`
- voucher `IN-1`
- voucher id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`
- reference `TEST-004-PERSISTENT`

The earlier rollback-scoped fixture `4062e2c6-f683-4a9c-bdc9-89705dbc7a7e` was confirmed absent before the persistent fixture was recreated.

### STAGE 2 — SEND
**PASS**
The persistent fixture was sent through `post_manual_stock_voucher_atomic(..., 'SEND', ...)` using an explicit OUT effect from BR-01 for item 1004 quantity 1.

Observed result:
- voucher status: `Sent`
- `sent_date` populated
- BR-01 item 1004 qty: `206` → `205`
- `allocated_qty`: remained `0`
- `available_qty`: `205`
- `inventory_log`: one `DirectSale` movement, qty `1`, voucher `IN-1`, user `test-operator@rawaea.local`

### Current Gate
Proceed immediately to **STAGE 3 — COMPLETE** using the same persistent fixture.

### No production patch approved
None.

## Evidence
EVIDENCE-015 — Full Production Schema Dependency Closure.
Status: REVIEWED / ACCEPTED for TASK-002.
Result files are stored under `SQL_Evidence/diagnostics/` as split result sets 1–10 where available.

## CTO Gate
TASK-002 closed. No Production patch or migration was authorized by this task.

## Next Safe Step
TASK-004 STAGE 3 — COMPLETE.

## Event Log
2026-08-11 — TASK-001 completed; Project Baseline established.
2026-08-11 — TASK-002 started; Production inventory contract reviewed.
2026-08-11 — Evidence gap identified; EVIDENCE-015 required before any schema/movement decision.
2026-08-11 — EVIDENCE-015 SQL prepared for user execution.
2026-08-11 — EVIDENCE-015 result set reviewed from `SQL_Evidence/diagnostics/`.
2026-08-11 — TASK-002 closed COMPLETE / GO. Inventory Data Contract frozen from Production Evidence.
2026-08-12 — TASK-004 STAGE 1 persistent fixture created successfully; voucher `IN-1`, id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`.
2026-08-12 — TASK-004 STAGE 2 SEND passed; status `Sent`, BR-01 qty reduced `206` → `205`, one DirectSale inventory log recorded.
2026-08-12 — Next: TASK-004 STAGE 3 COMPLETE.
