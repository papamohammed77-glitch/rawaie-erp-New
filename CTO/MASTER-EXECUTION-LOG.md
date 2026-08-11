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

## Evidence
EVIDENCE-015 — Full Production Schema Dependency Closure.
Status: REVIEWED / ACCEPTED for TASK-002.
Result files are stored under `SQL_Evidence/diagnostics/` as split result sets 1–10 where available.

## CTO Gate
TASK-002 closed. No Production patch or migration was authorized by this task.

## Next Safe Step
Proceed to TASK-003 — Voucher Data Contract.

## Event Log
2026-08-11 — TASK-001 completed; Project Baseline established.
2026-08-11 — TASK-002 started; Production inventory contract reviewed.
2026-08-11 — Evidence gap identified; EVIDENCE-015 required before any schema/movement decision.
2026-08-11 — EVIDENCE-015 SQL prepared for user execution.
2026-08-11 — EVIDENCE-015 result set reviewed from `SQL_Evidence/diagnostics/`.
2026-08-11 — TASK-002 closed COMPLETE / GO. Inventory Data Contract frozen from Production Evidence.
2026-08-11 — Next Task: TASK-003 — Voucher Data Contract.
