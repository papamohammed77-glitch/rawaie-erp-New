# RAWAEA EXECUTION PROTOCOL

**Status:** ACTIVE
**Mode:** Controlled incremental refactoring

## Mandatory sequence
Inspect → Understand → Plan → Implement → Test → Verify → Commit → Review → Deploy only after GO.

## No-guessing
Every important fact must be classified as:
- CONFIRMED — directly evidenced.
- INFERRED — logical deduction, never a business rule without approval.
- UNKNOWN — insufficient evidence.
- CONFLICT — sources disagree.
- TARGET DECISION REQUIRED — business/architecture choice not derivable from Production evidence.

## Stop conditions
Stop before implementation when:
- a required column/table/function is not proven;
- Production and code disagree;
- Source of Truth is unclear;
- a business rule is unknown;
- a migration can destroy or rewrite data;
- RLS/auth/security boundaries would change;
- another Domain is materially affected without analysis;
- the proposed patch cannot be verified.

## Scope rule
Do not redesign unrelated domains. Inventory first, then Accounting, Ledger, Sales, Purchasing, Delivery/Runsheet, AI.

## Legacy rule
Never delete original code merely because a replacement exists. Compare → redirect/migrate consumers → validate → deprecate → delete later.

## Production rule
No SQL execution against Production from an analysis task. No GO except CTO/owner authorization after review.

## Output rule
Every task must leave a durable report containing: objective, evidence, current state, target state, changed files, SQL, tests, expected results, rollback, risks and final status.
