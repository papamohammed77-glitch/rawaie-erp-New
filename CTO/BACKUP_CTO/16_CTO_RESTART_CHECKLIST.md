# BACKUP CTO 16 — EMERGENCY CTO RESTART CHECKLIST

## When this is used
Use this checklist when the previous CTO session disappears, message budget is exhausted, or a new CTO is assigned.

## Phase A — establish identity
- Read `CTO/00_MASTER_CONTEXT.md`.
- Read `CTO/01_SOURCE_AUTHORITY_MAP.md`.
- Read `Governance/RAWAEA_ARCHITECTURE_CONSTITUTION.md`.
- Read `Governance/EXECUTION_PROTOCOL.md`.
- Read all `CTO/BACKUP_CTO/*.md`.
- Read `CTO/TASKS/00_CTO_PROJECT_EXECUTION_LEDGER.md`.

## Phase B — verify current checkpoint
- Confirm active repository is `rawaie-erp-New`.
- Treat `rawaie-erp-review` as historical only.
- Locate the latest task closeout.
- Locate any open PR/branch associated with the current task.
- Do not assume the latest GitHub commit is deployed.

## Phase C — Production reality
Before a modification:
1. Query object existence.
2. Query exact schema.
3. Query constraints/indexes.
4. Query deployed function definition.
5. Query relevant permissions/RLS.
6. Query current data only when needed.

## Phase D — implementation
Use:
Evidence → Reconciliation → Target Decision → Minimal Permanent Patch → Test → Production Verification → Durable Record.

## Phase E — safety
Stop immediately if:
- required schema is unknown;
- a business decision is unresolved;
- current and target behavior conflict;
- a migration is not proven deployed;
- an existing feature may be lost;
- a test could alter real data without rollback;
- security boundaries are unclear.

## Phase F — closeout
A task is CLOSED only when its exact gate conditions are met and a durable record is written.

## Final handoff
Record:
- what was proven;
- what changed;
- what did not change;
- exact Production identifiers;
- exact test result;
- remaining risks;
- next active task.
