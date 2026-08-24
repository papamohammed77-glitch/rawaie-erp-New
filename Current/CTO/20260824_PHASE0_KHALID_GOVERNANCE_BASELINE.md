# PHASE 0 — KHALID EXECUTION ASSIGNMENT

## Role
Financial / Governance / Evidence Baseline Owner.

## Mission
Do NOT modify business logic. Build the governance side of the single authoritative Phase 0 baseline.

## Required work

1. Re-read current Production directly at execution time.
2. Capture exact timestamp, company topology, core table counts, current Treasury, COA state, and critical financial data state.
3. Capture current Git `main` HEAD and latest relevant commits.
4. Inventory all relevant branches and PRs, including draft/closed/unmerged status. Treat PR #24 as historical/non-current unless independently reconciled.
5. Build a Git-to-Production lineage table for:
   - migrations
   - RPC/core definitions
   - critical Edge consumers
   - current CTO evidence records
6. Normalize all existing Open/Unknown/Conflict/Drift/Legacy/Unverified items into one register.
7. Explicitly separate:
   - Historical Truth
   - Current Production Truth
   - Current Git Truth
   - Target Architecture
8. Detect stale claims in prior Khalid/Hytham reports and mark them historical rather than silently deleting them.
9. Preserve the existing `EXACT 87 COA RECOVERY = OPEN` / `SOURCE EXHAUSTION = CLOSED` distinction. Do not create or reconstruct COA.
10. Produce:
   - `Current/CTO/20260824_PHASE0_KHALID_GOVERNANCE_BASELINE.md`
   - `Current/CTO/20260824_PHASE0_OPEN_DEBT_REGISTER.md`

## Mandatory tables

### Current Truth Matrix
| Item | Production | Git main | Historical claim | Status |
|---|---|---|---|---|

### Lineage Matrix
| Object | Production version/state | Git path | Git revision | Deployed? | Runtime verified? |
|---|---|---|---|---|---|

### Open Debt Register
| ID | Area | Evidence | Current state | Risk | Blocker | Owner | Next evidence |
|---|---|---|---|---|---|---|---|

## Restrictions

- No schema changes.
- No data changes.
- No PWA changes.
- No Financial Writer changes.
- No COA creation.
- No Treasury changes.
- No closure claim based on a report alone.

## Completion condition

Khalid's deliverables are complete only when every material current-state claim has either:

`PRODUCTION VERIFIED`

or

`GIT VERIFIED`

or

`HISTORICAL ONLY`

or

`UNKNOWN / REQUIRES EVIDENCE`

No fourth state is allowed.
