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