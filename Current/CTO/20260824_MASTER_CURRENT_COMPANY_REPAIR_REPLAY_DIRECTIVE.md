# RAWAEA ERP — MASTER CURRENT-COMPANY REPAIR REPLAY DIRECTIVE

## STATUS

This directive supersedes historical tenant assumptions. It is an execution directive, not a report.

## CURRENT AUTHORITY

1. Current Production PostgreSQL / deployed definitions
2. Current Git main
3. Current forensic/evidence records
4. Historical sources
5. Previous reports only as chronological evidence

## CURRENT COMPANY RULE

All replayed repairs, recovered financial master data, and future accounting objects in this task MUST belong to the company that is current in the target environment.

Do not recreate retired company IDs as owners of current business data.
Do not restore historical rows under their retired company merely because that was their historical owner.
Preserve historical UUIDs where verified and safe, but reassign ownership to the CURRENT company only when the business object is explicitly approved for consolidation.

## NON-NEGOTIABLE FORENSIC RULE

Do not synthesize missing data.
A row count is not a row-level source.
A generic accounting convention is not a historical account record.
A screenshot, report statement, or previous prompt is not enough to reconstruct financial master data.

## CURRENT FINANCIAL RECOVERY FACTS

- The historical retired tenant had 87 chart-of-accounts rows.
- Exact 87 rows have not yet been recovered from a row-level authoritative source.
- The published application seed contains only 16 base accounts and is NOT proof of the historical 87.
- The historical treasury row IS exactly recoverable and may be replayed.
- On 2026-08-24 the exact historical treasury was restored in rawaea-staging under the current staging company `b4cc737e-6431-474e-af9e-92a427a44911`.
- Treasury restored: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`, `CASH-01`, `الخزينة الرئيسية`, opening/current balance `10000`, active.

## REPLAY OBJECTIVE

Re-establish every previously validated architectural repair in the current company context, while preserving:

- current Inventory Core contract
- current Accounting Core contract
- current Treasury contract
- current Authorization semantics
- current idempotency contract
- current UI/Edge consumer contracts unless a verified drift exists

## REPLAY PROCEDURE

UNDERSTAND
→ VERIFY CURRENT PRODUCTION/STAGING
→ TRACE HISTORICAL REPAIR
→ TRACE CURRENT GIT
→ IDENTIFY WHAT SURVIVED
→ IDENTIFY WHAT WAS LOST WITH RETIRED TENANTS
→ REPLAY ONLY THE VERIFIED PART
→ TEST
→ VERIFY RUNTIME
→ DOCUMENT

## INVENTORY

Physical stock movement MUST remain:

Physical Movement → post_stock_movement → stock_branches + inventory_log

reserve_stock/release_stock_reservation remain allocation-only.

No financial replay may modify this contract.

## ACCOUNTING

post_journal_entry is the canonical journal writer.
No new direct journal writer may be created.

## LEDGERS

Any ledger convergence must use an established ledger Core only after its ownership and identity contract are verified.

## TREASURY

Treasury is master data, not a journal substitute.
Treasury ownership MUST be current-company scoped.

## 87-ACCOUNT RECOVERY GATE

This gate remains OPEN until an exact row-level source is found in one of:

- historical Git blob/commit/tree
- authoritative snapshot/backup
- preserved migration/seed containing all rows
- other directly verifiable row-level source

Until then:

DO NOT fabricate the 87.
DO NOT expand 16 → 87 by accounting convention.
DO NOT infer parent/child accounts.
DO NOT infer account UUIDs from codes.

## REQUIRED OUTPUT

For each replayed repair:

Historical Contract
Current Contract
Source Evidence
Current Environment
Change Applied
Deployment
Runtime Verification
Rollback/Cleanup
Current Status
Open Gate

## FINAL RULE

A repair is not considered restored because its code still exists in Git.
It is restored only when the current company owns the resulting data/behavior and the current runtime proves it.
