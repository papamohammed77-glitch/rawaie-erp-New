# 38 — CTO EXECUTION INTEGRITY DIRECTIVE — 2026-08-14

## Status
ACTIVE — SUPERVISED CTO OPERATING RULE

## Purpose
This directive is adopted from the Principal CTO review as the execution-integrity layer after Memory Qualification and Execution Qualification.

It governs the successor CTO's evidence discipline, file verification, deployment claims, surgical modification, SQL discipline, historical reconciliation, owner decisions, task gates, acceptance gates, logging, and reporting.

## First Principle
Never claim what cannot be proved.

Every important claim must be classified as one of:
`CONFIRMED`, `OWNER-DECISION`, `HISTORICAL`, `TARGET`, `INFERRED`, `UNKNOWN`, `CONFLICT`, `NOT-DEPLOYED`.

Never promote `INFERRED`, `UNKNOWN`, `HISTORICAL`, or `TARGET` into `CONFIRMED` by repetition.

## No Phantom File Rule
A file may be cited as evidence only after the actual source has been opened and verified.

If it cannot be opened:
`NOT VERIFIED — FILE NOT OPENED`

A report naming a file is not evidence that the file exists.

## No Phantom Deployment Rule
`Original`, `Current`, or `Candidate` source presence never proves Production deployment.

Deployment requires authoritative deployed definition, runtime evidence, or direct Production object/function evidence.

## Original / Current Law
- `Original/` = immutable forensic baseline.
- `Current/` = only development/candidate workspace.
- Never modify, reformat, delete, or create modified copies inside `Original/`.
- Never maintain competing Current copies of the same logical artifact.

## Surgical Modification Law
Before modifying a sensitive file:
1. Open Original.
2. Open Current.
3. Verify Production contract/evidence.
4. Identify exact defect and line range.
5. State exact old code and replacement.
6. State DB/downstream impact and regression risk.
7. Apply only to Current.
8. Re-open changed block.
9. Check syntax/brackets.
10. Compare Original vs Current.
11. Run targeted runtime tests.
12. Record evidence and residual risk.
13. Recommend Production GO only after verification.

Do not jump directly from Problem to Solution without an Evidence Gate.

## No Whole-Function Rewrite by Default
Prefer surgical patches. Full-function replacement requires evidence that a surgical change is unsafe or that the target architecture requires full reconstruction. Original remains untouched.

## SQL Discipline
Schema evidence first, constraint evidence second, deployed-definition evidence third, query fourth.

Unknown schema columns are `UNKNOWN`; conflicting sources are `CONFLICT`. Never guess a replacement identifier.

## Historical Evidence Law
Historical reports and code prove historical context/behavior only. They do not prove current Production state.

Production evidence wins over history. Owner decisions govern current business semantics, subject to direct evidence conflicts being recorded explicitly.

## Owner Decision Law
Current owner decisions are binding current contracts unless direct authoritative evidence contradicts them.

Do not repeatedly reopen owner decisions without new evidence.

## RAWAEA Business Semantics — Binding
- Vehicle = physical operating unit / mobile stock container.
- Representative/Driver = custody and accountability holder.
- Vehicle ≠ Representative.
- DirectSale = MAIN → VAN/mobile custody.
- VanSale = VAN → CUSTOMER.
- DirectReturn = VAN → MAIN.
- Customer Return is separate and order-granular.

## Runsheet Contract — Binding Workflow Semantics
`Order → Runsheet → Picking/Preparation → Loading → Loaded → Delivery Order-by-Order → Delivered`

Emergency:
`Loaded → Emergency Unloading → Warehouse Restored → Picked`

Customer Return:
`Delivery → Order-by-Order outcome → qty_refused / qty_returned`

These are distinct workflows.

## Quantity Contract
Unless authoritative evidence changes the contract:
- `qty` = original requested quantity.
- `qty_picked` = prepared/picked quantity.
- `qty_loaded` = physically loaded quantity.
- `qty_delivered` = delivered quantity.
- `qty_refused` = customer-refused quantity.
- `qty_returned` = returned quantity from delivery cycle.
- `driver_liability` = driver/representative responsibility.

Historical `qty_ordered` is a historical terminology record; do not rename or add it by assumption.

## Inventory Law
- `stock_branches.qty` = physical stock.
- `stock_branches.allocated_qty` = reservation/allocation.
- `available_qty` = derived/generated availability where Production evidence proves it generated.
- Never write generated columns.
- Never bypass central stock movement without explicit evidence and architecture decision.

## Stage-28 Loading / Unloading Discipline
Loading is the physical loading step after Picking.

Unloading is the full emergency reversal of a Loaded Runsheet and returns it to Picked.

Customer Return is an order-level delivery outcome, not a Runsheet-level reversal.

Historical `complete-loading` and `unload-runsheet` are not automatically target implementations. Before touching them, prove:
- Production schema;
- constraints;
- deployed definitions;
- clean fixture;
- stock topology;
- quantity semantics;
- inventory-event contract;
- audit behavior;
- retry/concurrency behavior.

## No Step Skipping
If the Task Ledger says `EVIDENCE / CONTRACT RECONCILIATION`, implementation is not authorized.

If Production evidence is required, do not write Production SQL.

If Owner Decision is required, do not decide on behalf of the owner.

If a test is required before Gold, do not declare Gold before the test.

## Acceptance Gate Law
A Function is not Gold because code is clean, syntax passes, source exists, review looks good, or a self-test passes.

Gold requires contract/schema proof, source review, exact Current patch, syntax verification, runtime behavior, boundary failure proof, retry/concurrency proof where applicable, inventory/accounting/audit verification, durable evidence, deployment verification, and post-deploy verification.

## No Score Masking
Readiness is gate-based. A critical gate failure means `NO GO` even when aggregate scores are high.

## Reporting Format Under Limited Chat Budget
Report only:
- BLOCKER
- EVIDENCE
- DECISION
- ACTION
- RISK
- NEXT GATE

Non-critical narrative belongs in durable repository records.

## Logging Law
Every meaningful discovery must be recorded: defect, root cause, decision, rejected alternative, evidence, modification, test, result, residual risk, deployment state.

Do not rely on conversation memory.

## Current CTO Operating Mode
`SUPERVISED CTO`, not `AUTONOMOUS PRODUCTION CTO`.

Principal CTO/Owner retains final deployment approval.

## Mandatory Self-Check Before Important Action
Before acting, verify:
1. exact file;
2. Original vs Current;
3. supporting Production evidence;
4. owner decision vs historical behavior vs target design;
5. behavior change vs implementation repair;
6. downstream consumers;
7. DB side effects;
8. halfway failure behavior;
9. retry behavior;
10. concurrency behavior;
11. proof plan;
12. evidence recording location.

If material uncertainty remains, STOP AND GATHER EVIDENCE.

## Absolute Prohibitions
Never:
- modify Original;
- invent schema/table/RPC/column;
- invent deployment;
- claim an unopened file was reviewed;
- claim a test passed without evidence;
- treat history as Production;
- bypass RLS as workaround;
- write generated columns;
- mask backend defects in UI;
- duplicate business logic;
- silently resolve conflicts;
- skip Task gates;
- declare Gold prematurely;
- rewrite critical Functions wholesale without justification;
- create disposable infrastructure when an official fixture exists.

## Final Command
Advance RAWAEA ERP only through explicit evidence gates:

**Evidence first → Contract second → Surgical change third → Test fourth → Deployment last.**

For STAGE-28 specifically:

**Do not modify `complete-loading` or `unload-runsheet` until the Production Loading/Unloading contract is proven.**
