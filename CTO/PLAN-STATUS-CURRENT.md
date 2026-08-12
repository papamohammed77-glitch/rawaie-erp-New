# RAWAEA ERP — CURRENT CTO RESCUE PLAN

## Authority
This document is the current execution map for the Inventory / Manual Vouchers / Warehouse / Van Sales rescue workstream.

## Operating law
Every task follows:

`Task → Evidence → Self Audit → Decision → Implementation → Test → Verification → Gate → Next Task`

Production reality rule:
- Contract / Evidence tasks may close from authoritative deployed Production evidence.
- Implementation / Test tasks are NOT Production-complete merely because a migration, report, or repository file exists.
- Implementation / Test tasks close only after actual target-system execution and direct verification evidence.
- No stage is skipped.
- No unproven schema, RPC, status, movement type, consumer, or business rule is invented.
- Comprehensive evidence is preferred in one execution unit; artificial A/B/C subdivision is prohibited unless safety or dependency isolation requires it.

## Current verified state

| Task | Domain | Status |
|---|---|---|
| TASK-001 | Project Baseline | CLOSED / GO |
| TASK-002 | Inventory Data Contract | CLOSED / GO |
| TASK-003 | Voucher Data Contract | CLOSED / GO |
| TASK-004 | Production RPC Contract / TEST-004 | CLOSED / GO |
| TASK-005 | Voucher State Machine | CLOSED / GO |
| TASK-006 | Inventory Movement Matrix | CLOSED / GO |
| TASK-007 | Custody Matrix | CLOSED / GO |
| TASK-008 | Movement Types Contract | CLOSED / GO |
| TASK-009 | Partial Receive Contract | CLOSED / GO |
| TASK-010 | Idempotency Contract | CLOSED / FINDING — non-idempotent partial receive proven |
| TASK-011 | Concurrency Contract | CLOSED / GO |
| TASK-012 | Atomic Transaction Contract | CLOSED / GO |
| TASK-013 | Stock Engine Design | CLOSED / PRODUCTION DESIGN BASELINE |
| TASK-014 | Stock Engine Implementation | CLOSED / PRODUCTION IMPLEMENTED + VERIFIED |
| TASK-015 | Stock Engine Tests | CLOSED / PRODUCTION TEST PASS |
| TASK-016 | Stock Engine Gate | CLOSED / PRODUCTION GATE PASS |
| TASK-017 | Voucher RPC Refactor Design | ACTIVE / NEXT |

## Critical Production facts carried forward
- `public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text)` exists in Production and was directly exercised by TASK-013/014 and TASK-015.
- `stock_branches.qty` is physical stock state.
- `stock_branches.allocated_qty` is reservation state and is not mutated by the central movement engine.
- `inventory_log` records posted movements.
- `complete_manual_stock_voucher_atomic(...)` is lifecycle closure and does not itself perform physical stock mutation.
- Existing Manual Voucher paths still include deployed functions such as `send_stock_voucher_atomic(...)` and `post_manual_stock_voucher_atomic(...)`; consumer ownership must be reconciled before rewiring.
- `TASK-010` proved repeated logical partial RECEIVE is currently non-idempotent. No idempotency patch was introduced by that task.
- An earlier TASK-014 draft migration that treated TransferOut and TransferIn as separate independent calls was rejected and removed before Production execution. It was never deployed.

## Remaining plan

### PHASE E — MANUAL VOUCHERS
- TASK-017 — Voucher RPC Refactor Design
- TASK-018 — Send Voucher
- TASK-019 — Receive Voucher
- TASK-020 — Partial Receive
- TASK-021 — Complete Voucher
- TASK-022 — Cancel Voucher
- TASK-023 — Voucher Integration Tests
- TASK-024 — Voucher Gate

### PHASE F — VOUCHERS UI
- TASK-025 — `vouchers.html` Contract Review
- TASK-026 — `vouchers.html` Implementation
- TASK-027 — `vouchers.html` E2E Test

### PHASE G — LOADING / UNLOADING
- TASK-028 — Loading Contract
- TASK-029 — Loading Implementation
- TASK-030 — Unloading Contract
- TASK-031 — Unloading Implementation
- TASK-032 — Loading/Unloading E2E

### PHASE H — VAN SALES
- TASK-033 — Van Custody Contract
- TASK-034 — Van Stock Movement Contract
- TASK-035 — Van Sales Transaction Contract
- TASK-036 — `van-sales.html` Review
- TASK-037 — `van-sales.html` Implementation
- TASK-038 — Van Sales E2E

### PHASE I — EDGE FUNCTIONS
- TASK-039 — Edge Function Dependency Map
- TASK-040 — Rewire Stock Functions
- TASK-041 — Rewire Voucher Functions
- TASK-042 — Rewire Loading/Unloading
- TASK-043 — Rewire Van Sales
- TASK-044 — Remove / Disable Duplicated Stock Logic

### PHASE J — ACCOUNTING / AUDIT / SECURITY
- TASK-045 — Accounting Impact Matrix
- TASK-046 — Journal Entry Centralization
- TASK-047 — Ledger Centralization
- TASK-048 — Audit Contract
- TASK-049 — RLS / Security Verification

### PHASE K — FINAL PROOF / PRODUCTION
- TASK-050 — Full Inventory E2E
- TASK-051 — Regression Test
- TASK-052 — Production Readiness Gate
- TASK-053 — Production Migration
- TASK-054 — Post-Deployment Verification
- TASK-055 — Final CTO Sign-off

## Current position
`TASK-016 CLOSED / GO → TASK-017 ACTIVE`

No task after TASK-017 is considered started merely by reading this map. Each task must be executed and closed in sequence.
