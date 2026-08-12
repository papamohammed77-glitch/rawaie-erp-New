# RAWAEA ARCHITECTURE CONSTITUTION

**Status:** ACTIVE
**Source:** `rawaie-erp-review/Architecture/RAWAEA_ARCHITECTURE_CONSTITUTION.md`

## Core laws
1. Single Source of Truth.
2. Business rules do not live in UI.
3. Applications are interfaces; Core owns business logic.
4. Inventory is a business engine, not merely quantities.
5. Accounting consumes inventory events; it does not invent inventory truth.
6. Ledger is derived from accounting and is not manually recalculated to hide upstream errors.
7. Applications are replaceable; the Business Core is protected.
8. Edge Functions represent business capabilities.
9. Duplicate business logic is a defect.
10. Migrations must preserve production data and integrity.

## Prohibited
- Duplicate business truth.
- UI business rules.
- Direct SQL from UI.
- Hidden dependencies.
- Bypassing Source of Truth.
- Destructive migrations without recovery.
- Disabling RLS as a workaround.

## Final principle
**Protect the Core. Everything else can be replaced. Never replace the Core casually.**

## CTO interpretation for the recovery repository
When this Constitution conflicts with a current Production fact, record the conflict. Do not pretend the Production system already satisfies the Constitution. The goal is controlled convergence, not retrospective rewriting of history.

## Universal Production Reality Rule
For every CTO, every phase, and every task:

1. A Contract / Evidence / Reconciliation task is not an implemented Production change unless an actual Production change occurred and was verified.
2. A task is never considered "implemented", "deployed", or "represented in Production" merely because a report, migration, source file, design, or Git commit exists.
3. Production implementation status must always be classified explicitly as one of:
   - **PRODUCTION IMPLEMENTED & VERIFIED**
   - **CONTRACT / EVIDENCE ONLY**
   - **CURRENT SOURCE ONLY**
   - **TARGET CANDIDATE / NOT DEPLOYED**
   - **UNKNOWN**
4. Before advancing past any implementation or validation gate, the CTO must verify the actual Production state and preserve the evidence proving that state.
5. No stage may be silently treated as completed in Production because its preceding analytical work was completed.
6. The execution path must remain grounded in the real system:
   **Production Evidence → Reconciliation → Target Decision → Minimal Patch → Actual Execution → Production Verification → Review → GO**.
7. When a task is analytical by design, its completion must remain explicitly classified as analytical; it must never be presented as a Production implementation.

This rule is mandatory for every future CTO and every phase of the RAWAEA ERP project.