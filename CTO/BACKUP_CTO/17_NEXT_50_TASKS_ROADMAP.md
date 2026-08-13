# BACKUP CTO 17 — NEXT 50 TASK ROADMAP

## Important
This is a roadmap, not a declaration that all listed tasks are approved or already specified. Each future task must acquire its own Evidence and owner contract.

## Immediate checkpoint
### STAGE-28 — Loading / Unloading Core
First task after TASK-027.

Required sequence:
1. Production evidence for loading/unloading tables, RPCs, functions and current consumers.
2. Original loading/unloading function review.
3. Current implementation review.
4. Stock impact mapping.
5. Target contract.
6. Atomicity/concurrency contract.
7. Production implementation.
8. Boundary tests.
9. UI parity review.
10. Closeout.

## Future domain sequence
STAGE-29+ should proceed according to the active domain order in Governance and the durable task ledger, normally:
- Loading / Unloading
- Delivery / Runsheet stock effects
- Return integration
- Accounting event engine
- Ledger engine
- Sales/Van Sales final integration
- Purchasing impact integration
- Settlement / Custody reconciliation
- Reporting/analytics contract
- AI/Decision Intelligence only after Core truth is stable.

## Never pre-close future tasks
A roadmap item is not a Production task until its exact evidence requirements and acceptance criteria are written.

## Recommended task template
TASK-NNN
Objective
Production evidence required
Original source required
Current implementation
Target contract
Risk assessment
Minimal permanent patch
Tests
Post-deploy read-only verification
Close criteria
