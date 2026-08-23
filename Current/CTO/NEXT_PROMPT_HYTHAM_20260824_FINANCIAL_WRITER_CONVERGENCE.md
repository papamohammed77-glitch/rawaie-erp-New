# HYTHAM — NEXT EXECUTION DIRECTIVE
# WRITE-SIDE FINANCIAL CONVERGENCE

## Mission

Close distributed financial writers without changing Company Identity, COA Master Data ownership, or Treasury ownership.

## Authority

Current Production PostgreSQL > Current Git main > Current evidence > Historical sources > reports.

Before touching any writer, re-read its current deployed definition and current Git source.

## Current architectural target

Transaction Originator
→ Domain Core
→ post_journal_entry / ledger core / treasury core

No direct journal writes outside the canonical journal engine.
No direct ledger writes outside the canonical ledger engine once the ledger contract is proven.

Inventory remains untouched:
Physical Movement → post_stock_movement.

## First step: GLOBAL WRITE-SIDE DISCOVERY

Re-query Production and classify every function/Edge path that:

- inserts/updates journal_entries
- inserts/updates journal_lines
- inserts/updates customer_ledger
- inserts/updates supplier_ledger
- inserts/updates driver_ledger
- mutates treasury/cash_box as part of a transaction

Do not rely on the historical writer list.

## Known historical open writers

Re-verify, do not assume:

- receive_purchase_atomic
- complete_return_atomic
- save_sales_invoice_atomic / Van Credit driver ledger path
- save-receipt-voucher
- save-payment-voucher
- save-daily-settlement
- update-driver-ledger

The Production database is the final authority over whether each remains open.

## Closure order

1. Driver Ledger ownership/identity contract
2. Git ↔ Production deployment lineage
3. Authenticated HTTP E2E
4. Two-session concurrency proof
5. Driver Ledger Core
6. Receipt Writer
7. Payment Writer
8. Purchase Receiving Writer
9. Return Writer
10. Daily Settlement Writer
11. Global Financial Writer Zero-Debt

Do not skip ahead because a core function exists.

## Driver Ledger — special gate

Current `driver_ledger` schema does not expose company_id directly.
Do NOT add company ownership, move rows, or build a core until its ownership contract is proven from schema/business behavior and current users/drivers.

A proposed core that cannot prove tenant ownership is not a valid closure.

## Idempotency

Use explicit operation identity.
Do not derive operation identity from mutable quantities, balances, timestamps, or current state.

For each writer:

same operation identity + same payload → duplicate/no-op
same operation identity + different payload → conflict
new operation identity → new transaction

## Staging first

Use `rawaea-staging` as the first replay/test environment.
Current staging company:
`b4cc737e-6431-474e-af9e-92a427a44911`.

Financial master state there currently includes recovered `CASH-01` treasury only; COA is still unresolved.

Do not manufacture COA just to make a financial writer test pass.

Where a writer requires COA accounts, use only verified current-company accounts after Khalid's recovery gate is closed, or isolate the test to a proven non-financial path.

## Required proof for each writer

- Historical contract
- Current Production definition
- Current Git definition
- Consumer(s)
- Direct writes before
- Core calls after
- Responsibility migration
- Idempotency
- Company isolation
- Atomic rollback
- Authenticated HTTP runtime
- Two-session concurrency where applicable
- Production deployment
- Production runtime verification

## Prohibited

- changing company ownership;
- inventing COA accounts;
- inventing treasury mappings;
- changing POS UI merely to hide backend gaps;
- changing Inventory Core;
- declaring CLOSED from SQL-only testing when HTTP runtime is still unverified;
- declaring Financial Writer Zero-Debt while any direct writer remains.

## Final closure

FINANCIAL WRITER ZERO-DEBT = CLOSED only when:

all writers discovered
+
all writers routed to canonical cores
+
no direct journal/ledger writers remain outside approved cores
+
company isolation verified
+
idempotency verified
+
authenticated HTTP E2E verified
+
concurrency verified
+
Git/Production lineage aligned

Then update the authoritative Current/CTO ledger with exact evidence.
