# RAWAEA ERP — PHASE 1B KHALID EXECUTION
## NEW FINANCIAL MASTER DATA — PRODUCTION VERIFIED

Date: 2026-08-25
Owner: Khalid

## 1. Authority and scope

This unit changed the task from historical 87-row recovery to **NEW FINANCIAL MASTER DATA**. The historical recovery loop remains closed at Source Exhaustion; none of the new rows are represented as historical recovery.

No Treasury mutation, Inventory Core mutation, POS change, Accountant UI change, Finance Manager UI change, historical audit repair, or security weakening was performed.

## 2. Fresh Production baseline immediately before insertion

Production project: `SMART ERP` / `fiilmooggumokxanwiyx`

Current company:
`00000000-0000-0000-0000-000000000001`

Treasury:
`0a9d9357-b5f3-4dfa-886f-7c73de4f274e` / `CASH-01` / `الخزينة الرئيسية`

Pre-build `chart_of_accounts`:
`0`

Treasury current balance:
`10000.00`

## 3. Source-backed requirements

The current Production writer set explicitly requires these account codes:

- `121` — cash account used by `save_sales_invoice_atomic`
- `123` — customer receivable used by `save_sales_invoice_atomic`
- `124` — inventory used by sales, purchase receiving and returns
- `211` — supplier payable used by `receive_purchase_atomic`
- `41` — sales revenue used by `save_sales_invoice_atomic`
- `51` — COGS used by `save_sales_invoice_atomic` and `complete_return_atomic`

Parent/group accounts were added only to provide a coherent valid hierarchy for those current operational accounts. `216` is a reserved tax-liability account explicitly marked as not used by a current Production writer.

Full basis: `Current/CTO/20260825_KHALID_FINANCIAL_ACCOUNT_REQUIREMENTS_MATRIX.md`.

## 4. Production change

Applied migration:
`20260825_khalid_new_financial_master_data_v1`

Applied Production migration version observed:
`20260825013814`

Corrective migration:
`20260825_khalid_new_financial_master_data_parent_links_v1`

Applied Production migration version observed:
`20260825013838`

The corrective migration was required after post-insert verification found that parent IDs were not materialized by the original multi-row INSERT snapshot semantics. No partial hierarchy was accepted as closed; the parent relationships were corrected immediately and verified.

## 5. Final Production state

At verification `2026-08-25 01:39:02.195486 UTC`:

- Company-scoped COA rows: **16**
- Assets: **6**
- Liabilities: **4**
- Equity: **2**
- Revenue: **2**
- Expense: **2**
- Journal entries: **2** (unchanged)
- Journal lines: **0** (unchanged)
- Treasury balance: **10000.00** (unchanged)

Final hierarchy:

`1`
└── `11`, `12`
    ├── `121`
    ├── `123`
    └── `124`

`2`
└── `21`
    ├── `211`
    └── `216`

`3`
└── `31`

`4`
└── `41`

`5`
└── `51`

All child parent references resolve to the same company. No orphan parent IDs or duplicate `(company_id, account_code)` values exist.

## 6. Core compatibility proof

A transactional compatibility test called `post_journal_entry` using newly created account UUIDs `121` and `41` with a balanced 1.00 debit/credit entry.

Result:
- `success=true`
- balanced entry accepted
- `line_count=2`
- company context accepted
- account UUIDs accepted by the Core

The transaction was explicitly rolled back immediately afterward.

Therefore:
**Core UUID validation = VERIFIED**

No journal row, journal line, registry row or audit row from this dry-run remained in Production.

## 7. Treasury contract

Treasury was not modified.

Current operational contract is:
- Treasury identity = `treasury_id`
- GL cash account identity = `cash_account_id`
- Current POS writer explicitly requests GL cash account by `account_code='121'`

There is no Treasury→COA database FK, and none was invented.

`CASH-01 = 121` is therefore not asserted as a database mapping; it is two independently identified operational objects used by the current cash flow.

## 8. Git / Production lineage

Canonical migration files committed to `main`:

- `supabase/migrations/20260825013814_khalid_new_financial_master_data_v1.sql`
- `supabase/migrations/20260825013838_khalid_new_financial_master_data_parent_links_v1.sql`

The Production migration registry contains both corresponding versions.

## 9. Self-audit

### CLOSED
- historical 87-row recovery loop at Source Exhaustion
- new canonical COA created for surviving company
- explicit current writer account coverage for sales/purchase/return/cash flows
- valid company ownership
- valid parent hierarchy
- unique account codes
- normal balances
- Core UUID validation
- Treasury preserved
- Production/Git migration representation
- auditable migration sequence

### OPEN — intentionally not claimed closed
- authenticated Receipt/Payment HTTP E2E
- Accountant PWA consumer contract
- Finance Manager full UX/runtime closure
- Daily Settlement writer/runtime closure
- full Financial Writer Zero-Debt
- broad financial RLS/grant debt
- global concurrency proof
- full deployment byte/hash lineage

These are outside the COA creation unit and remain in the global debt register.

## 10. Historical integrity statement

These 16 accounts are **NEW MASTER DATA**.

They are not the recovered historical 87 accounts.
No historical continuity claim has been made.
