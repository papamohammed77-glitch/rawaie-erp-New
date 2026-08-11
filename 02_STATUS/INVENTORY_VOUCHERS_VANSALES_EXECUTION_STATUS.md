# CTO — Inventory / Vouchers / Van Sales Execution Status

## Mission
Finish the Inventory Core, `vouchers.html`, `van-sales.html`, and all related Edge Functions safely and reach a real Release Gate / GO.

## Governing Rules
- Production Schema is the final schema contract.
- No guessing, invented tables/columns/RPC signatures, or assumptions.
- Evidence-first: use persisted SQL Evidence before requesting the same query again.
- Current deployed definitions must be reconciled with migrations, current code, original code, and architecture.
- Tests executed in Production must be self-cleaning/transactional; no manual cleanup.
- Do not add schema merely to silence a test.
- Compare current implementations against `original/`; no business logic, validation, audit, or security behavior may be lost.
- RLS is not a workaround for Business Logic or Schema errors.
- No iterative V5/V6-style patch loop without root-cause reconciliation.
- CTO is the final authority; assistants do not independently modify Production.

## Execution Model
### Assistant 1 — Lead Analyst
Reconcile Production RPCs, schema, current functions, original functions, migrations, Evidence, and architecture. Produce facts, unknowns, discrepancies, root causes, and one corrective plan.

### Assistant 2 — Adversarial Reviewer
Independently challenge findings and search for missed schema mismatches, lifecycle errors, lost legacy logic, audit/security regressions, and double stock movements.

### CTO Gate
Merge both analyses, reject assumptions, select one coherent corrective patch, supervise Production execution, then validate with one comprehensive self-cleaning lifecycle test.

## Current Confirmed State
- `app_settings` company context was investigated and validated PASS for the active voucher company context.
- `BR-01` and `BR-2` exist and are active for the relevant company.
- Production `stock_vouchers` does not contain `completed_by`.
- Production `complete_manual_stock_voucher_atomic(uuid,text,text)` attempts to update `completed_by`.
- Therefore the current blocker is a confirmed RPC/Production-Schema mismatch.
- Additional lifecycle discrepancies remain to be reconciled before the final patch: DirectSale, DirectReturn, CANCEL, Partial RECEIVE idempotency, audit path, and complete Van Sales flow.

## Progress Gates
1. [x] Inventory architecture diagnosis / Distributed Business Logic identified.
2. [x] P0 direction established: centralized stock/journal/ledger engines.
3. [x] Manual Voucher RPCs retrieved from Production.
4. [x] Company context validated.
5. [x] Test branches/items context established.
6. [ ] Complete Manual Voucher contract reconciliation.
7. [ ] One coherent corrective patch.
8. [ ] Full self-cleaning Manual Voucher lifecycle test.
9. [ ] Inventory Core Release Gate.
10. [ ] `vouchers.html` integration validation.
11. [ ] Van Sales stock-flow reconciliation.
12. [ ] `van-sales.html` integration validation.
13. [ ] Related Edge Functions final reconciliation.
14. [ ] Final Production validation.
15. [ ] **GO**.

## Current Blocker
`complete_manual_stock_voucher_atomic` references missing `stock_vouchers.completed_by`.

Do not resolve this by blindly adding/removing the column. First determine the intended Audit Contract from Production behavior, original code, architecture, and Evidence.

## Target Acceleration
The intended workflow is:

`Parallel Reconciliation → CTO Merge → One Patch → One Full Test → Gate → GO`

## Status Update Rule
After each material gate, record:
- what was proven;
- what changed;
- remaining blockers;
- next gate;
- Evidence files.
