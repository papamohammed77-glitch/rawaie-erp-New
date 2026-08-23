# RAWAEA ERP — FORENSIC FINDINGS
## 87 COA / Treasury / Single-Tenant / Khalid / Hytham
### Date: 2026-08-23

## 1. Current Production truth

Production project: SMART ERP (`fiilmooggumokxanwiyx`)

Direct current verification:
- companies = 1
- users = 24
- branches = 2
- items = 17
- chart_of_accounts = 0
- treasury = 1
- cash_box = 0
- journal_entries = 2
- journal_lines = 0
- customer_ledger = 0
- supplier_ledger = 0
- driver_ledger = 0

Current company:
`00000000-0000-0000-0000-000000000001` / `الروائع`

`app_settings` points to the same company and its MAIN branch.

## 2. Treasury finding

The requested Treasury recreation is NOT required.

Current Production already contains exactly one Treasury row:
- id: `0a9d9357-b5f3-4dfa-886f-7c73de4f274e`
- company: `00000000-0000-0000-0000-000000000001`
- code: `CASH-01`
- name: `الخزينة الرئيسية`
- type: `Cash`
- opening_balance: 10000
- current_balance: 10000
- active: true

The Treasury UUID and balances match the row described in the current financial forensic decision record. No duplicate Treasury was created.

## 3. 87-account finding

The retired financial tenant is historically proven to have had exactly 87 `chart_of_accounts` rows.

Current Production contains zero COA rows.

Direct inspection of `audit_log` shows no row-level audit history for `chart_of_accounts` sufficient to reconstruct those 87 rows.

The application seed found in `rawaie-erp-review/PWA/main.html` contains only a small bootstrap account set and cannot be promoted to the historical 87-row source.

Repository search for a direct complete COA insert/seed has not produced an authoritative 87-row dataset.

Therefore:

**87-account creation is NOT executed.**

Creating 87 guessed accounts would violate the governing evidence rule and would corrupt the historical financial contract.

Status:
`OPEN / BLOCKED BY MISSING EXACT ROW-LEVEL SOURCE`

## 4. Critical historical error discovered

The 2026-08-23 tenant consolidation retired/deleted the old financial tenant before an exact row-level COA preservation source had been proven.

This is a data-preservation defect, not merely a UI or configuration defect.

The correct remediation is evidence recovery, not synthetic reconstruction.

## 5. Stale reports / records

Several historical/current-CTO artifacts are now superseded by later Production changes.

Example:
- older Prompt-53 material described three companies and Treasury under `da4...`;
- current Production has one company;
- the Treasury has already been restored under `000...001`;
- current COA is still empty.

Therefore old three-company financial snapshots must not be used as current truth.

## 6. Current financial writer scan

Current Production definitions still show direct financial writes outside the central journal/ledger cores:

- `receive_purchase_atomic` directly inserts `journal_entries`, `journal_lines`, `supplier_ledger`.
- `complete_return_atomic` directly inserts `journal_entries`, `journal_lines`, `customer_ledger`.
- `save_sales_invoice_atomic` still directly inserts `driver_ledger` for Van Credit.

Already established cores include:
- `post_journal_entry`
- `post_cash_receipt_atomic`
- `post_cash_payment_atomic`
- `post_customer_ledger_entry`

This confirms Financial Writer Zero-Debt is not yet closed.

## 7. Accounting identity defect that remains relevant

`journal_lines.account_id` is a UUID FK to `chart_of_accounts.id`.

Treasury `CASH-01` is not itself a Journal Line account identity.

Any Treasury → COA relation must be proven before receipt/payment/POS financial consumers can be declared accounting-complete.

## 8. Assistant assessment

### Khalid
Correct next responsibility:
- exact 87-account source recovery;
- single-company financial master-data canonicalization;
- Treasury ↔ COA contract;
- consumer/account identity evidence.

He must not fabricate accounts or redesign PWA financial consumers before the source contract is proven.

### Hytham
Correct next responsibility:
- financial writer convergence;
- Driver Ledger contract/core;
- authenticated E2E and independent-session concurrency;
- convergence of `receive_purchase_atomic`, `complete_return_atomic`, and remaining direct writers after account/Treasury prerequisites are proven;
- deployment lineage.

He must not change company membership or manufacture COA/Treasury mappings.

## 9. What is explicitly rejected

Reject any future report that claims:
- “87 accounts restored” without 87 row-level source proofs;
- “Treasury recreated” when the existing canonical Treasury is already present;
- “Financial closure complete” while direct writers remain;
- “Production verified” based solely on Staging;
- “company merge complete” when deleted historical data was not preserved row-by-row.

## 10. Final state

Single-company Production = `CONFIRMED`

Treasury under current company = `CONFIRMED`

Exact historical 87-account source = `UNKNOWN`

87-account restoration = `BLOCKED`

Financial writer zero-debt = `OPEN`

Financial consumer/deployment/concurrency closure = `OPEN`

Global zero-debt = `OPEN`
