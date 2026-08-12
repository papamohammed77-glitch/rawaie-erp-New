# RAWAEA ERP — CURRENT EXECUTION PLAN & STATUS

Date: 2026-08-13

## Governing execution rule
TASK → Evidence → Decision → Implementation (when applicable) → Production Execution → Test → Verification → Gate → Next TASK.

A repository report, migration, design, or candidate file is never by itself Production implementation evidence.

## Closed through TASK-018
- TASK-001 — Project Baseline — CLOSED / GO
- TASK-002 — Inventory Data Contract — CLOSED / GO
- TASK-003 — Voucher Data Contract — CLOSED / GO
- TASK-004 — Production RPC Contract / TEST-004 — CLOSED / GO
- TASK-005 — Voucher State Machine — CLOSED / GO
- TASK-006 — Inventory Movement Matrix — CLOSED / GO
- TASK-007 — Custody Matrix — CLOSED / GO
- TASK-008 — Movement Types Contract — CLOSED / GO
- TASK-009 — Partial Receive Contract — CLOSED / GO
- TASK-010 — Idempotency Contract — CLOSED / FINDING / GO; Production proved non-idempotent repeated Partial Receive.
- TASK-011 — Concurrency Contract — CLOSED / GO; Production RPC definitions proved locking/CAS behavior.
- TASK-012 — Atomic Transaction Contract — CLOSED / GO; Production transactional test PASS.
- TASK-013 — Stock Engine Design — CLOSED / GO; design contract, not itself a code deployment.
- TASK-014 — Stock Engine Implementation — CLOSED / GO; `public.post_stock_movement(...)` was actually deployed and verified in Production.
- TASK-015 — Stock Engine Tests — CLOSED / GO; Production test suite PASS with rollback.
- TASK-016 — Stock Engine Gate — CLOSED / GO; Production Gate PASS.
- TASK-017 — Voucher RPC Refactor Design — CLOSED / GO; contract/design task closed from Production evidence and existing Target/Current reconciliation. No production code change was required by the task itself.
- TASK-018 — Send Voucher — CLOSED / GO; Production implementation/test PASS.

## Current Production facts after TASK-018
- Central engine exists in Production: `public.post_stock_movement(...)`.
- SEND adapter exists in Production: `public.send_manual_stock_voucher_v2(uuid,text,text)`.
- TASK-018 verified Draft → Sent, source stock decrement, unchanged `allocated_qty`, and one `inventory_log` row.
- TASK-018 test effects were rolled back.
- Current legacy Edge Function consumers have NOT yet been rewired to the new adapter. This is an intentional open integration boundary and must be handled by the planned Edge Function integration tasks.

## Remaining execution plan
### Phase E — Manual Vouchers
- TASK-019 Receive Voucher
- TASK-020 Partial Receive
- TASK-021 Complete Voucher
- TASK-022 Cancel Voucher
- TASK-023 Voucher Integration Tests
- TASK-024 Voucher Gate

### Phase F — vouchers.html
- TASK-025 Contract Review
- TASK-026 Implementation
- TASK-027 E2E

### Phase G — Loading / Unloading
- TASK-028 Contract
- TASK-029 Implementation
- TASK-030 Unloading Contract
- TASK-031 Implementation
- TASK-032 E2E

### Phase H — Van Sales
- TASK-033 Custody Contract
- TASK-034 Movement Contract
- TASK-035 Atomic Transaction Contract
- TASK-036 UI Review
- TASK-037 UI Implementation
- TASK-038 E2E

### Phase I — Edge Functions
- TASK-039 Dependency Map
- TASK-040 Rewire Stock Functions
- TASK-041 Rewire Voucher Functions
- TASK-042 Rewire Loading/Unloading
- TASK-043 Rewire Van Sales
- TASK-044 Remove/Disable Duplicated Stock Logic

### Phase J — Accounting / Audit / Security
- TASK-045 Accounting Impact Matrix
- TASK-046 Journal Centralization
- TASK-047 Ledger Centralization
- TASK-048 Audit Contract
- TASK-049 RLS/Security Verification

### Phase K — Final Verification / Production
- TASK-050 Full Inventory E2E
- TASK-051 Regression Test
- TASK-052 Production Readiness Gate
- TASK-053 Production Migration
- TASK-054 Post-Deployment Verification
- TASK-055 Final CTO Sign-off

## Open gaps that are NOT silently ignored
1. The current deployed legacy Edge Function consumer has not yet been rewired to `send_manual_stock_voucher_v2`. This is an intentional next integration boundary, not a hidden completion.
2. TASK-010 established a real Production idempotency finding; no patch has yet been applied. TASK-020 and/or later core design must address the contract before full voucher gate closure.
3. Complete Production proof for all Audit/Accounting effects is deferred to the designated Voucher/Accounting/Audit tasks.
4. DirectSale/DirectReturn custody semantics must remain aligned with the approved Target contract and proven through the designated integration tasks.

## Current position
**TASK-018 CLOSED / GO → NEXT TASK-019.**
No known Production-breaking change was introduced by TASK-018. The remaining items are explicit, tracked work and must not be mislabeled as closed.
