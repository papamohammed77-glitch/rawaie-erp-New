# RAWAEA ERP — KHALID PROMPT 53 FINANCIAL REPORTING CLOSURE

Date: 2026-08-23  
Role: Khalid — Financial Reporting / Accounting Consumers / Governance  
Production: SMART ERP (`fiilmooggumokxanwiyx`)  
Git: `rawaie-erp-New/main`

## 1. Governing Rule

Production runtime is the current truth. Git is the canonical change record. Historical reports are navigation evidence only. No financial contract is invented from UI labels or from competitor behavior.

## 2. Fresh Production Re-Baseline

Production query time: `2026-08-23 17:50:06 UTC`

- companies: 3
- users: 26
- branches: 5
- items: 50
- stock_branches rows: 26
- inventory_log: 3
- stock_vouchers: 0
- orders: 0
- runsheets: 0
- purchase_orders: 0
- journal_entries: 2
- journal_lines: 0
- audit_log: 1781

The earlier Prompt-53 snapshot showing `Latest migration = 20260822182733` is treated as historical evidence unless independently re-read from Production.

## 3. Production Reporting Core Forensic Findings

### `get_trial_balance`
Original signature preserved:
`get_trial_balance(date,date)`

Defect/Gap closed in this unit:
- no tenant scoping from authenticated company context;
- COA rows were not explicitly restricted to the caller company.

Production repair:
- resolve company from `app_private.current_user_company_id()`;
- fail closed when no company context exists;
- restrict COA to the caller company;
- preserve existing function signature and result shape;
- retain UUID-based internal journal-to-COA join.

### `get_profit_loss`
Original signature preserved:
`get_profit_loss(date,date)`

Production repair:
- authenticated company scoping;
- fail-closed null company context;
- journal-to-COA join remains `journal_lines.account_id = chart_of_accounts.id`;
- posted/date/company predicates remain enforced.

### `get_balance_sheet`
Original signature preserved:
`get_balance_sheet(date)`

Production repair:
- authenticated company scoping;
- fail-closed null company context;
- posted/date/company predicates remain enforced.

### `get_pnl_by_cost_center`
Original signature preserved:
`get_pnl_by_cost_center(date,date)`

Confirmed Production defect:
`journal_lines.account_id::character varying = chart_of_accounts.account_code`

This violated the actual FK contract because `journal_lines.account_id` references `chart_of_accounts.id`.

Production repair:
- exact UUID relationship restored: `journal_lines.account_id = chart_of_accounts.id`;
- authenticated company scoping added;
- posted/date/company predicates enforced;
- original public signature preserved.

### `get_cash_flow`
Original signature preserved:
`get_cash_flow(date,date)`

Confirmed Production runtime defect before repair:
The function failed with PostgreSQL `42803` because the `GROUP BY` did not include the `coa.account_type` expression needed by the selected CASE expression.

Production repair:
- corrected grouping using `coa.account_type, coa.account_code, coa.account_name`;
- company scoping added;
- original signature preserved.

IMPORTANT:
The existing cash-flow classification semantics remain structurally simple and are NOT declared accounting-grade by this closure. A future Owner/Accounting contract must prove the RAWAEA cash-flow model before redesigning it.

## 4. Production Runtime Verification

`app_private.current_user_company_id()` was verified to resolve company from `auth.uid()`.

Authenticated-context test for a user belonging to company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`:
- reporting company context resolved to that company;
- get_trial_balance returned 87 rows;
- get_balance_sheet returned 47 rows;
- get_cash_flow executed without the previous runtime error;
- get_pnl_by_cost_center executed without the previous account-code join defect.

Authenticated-context test for a user belonging to company `00000000-0000-0000-0000-000000000001`:
- company context resolved correctly;
- all five financial-report functions returned zero rows because the financial COA is not currently attached to that company.

This zero result is considered a security-correct outcome, not a UI fixable defect.

## 5. Critical Tenant Identity Finding

Production currently contains three companies:

- `00000000-0000-0000-0000-000000000001` — الروائع
- `73a141bd-157a-4c2c-8693-34e21325b943` — الروائع للتجارة
- `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` — الروائع للتوزيع

The financial domain currently has:
- Treasury row `CASH-01` under `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`;
- key COA accounts `121`, `124`, `41`, `51` under the same company;
- only one active user currently associated with that financial company;
- multiple operational/financial application users associated with `00000000-0000-0000-0000-000000000001`.

Therefore the system has an unresolved **Financial Tenant Identity Contract**:

Which company is the authoritative company for the accounting/treasury domain exposed to the current Finance/Accountant users?

This is an Owner Decision. No automatic migration, remapping, or company reassignment was performed.

## 6. Current/PWA Consumer Findings

### `Current/PWA/accountant.html`
Current SHA at inspection:
`a0469e81cded644fafada4df24e5628111357e74`

Current tabs:
- KPI
- سندات قبض
- سندات صرف
- قيود

Confirmed financial consumers:
- `save-receipt-voucher`
- `save-payment-voucher`

Current request shape still contains legacy identifiers such as:
- `cashBoxId: "MAIN"`
- `mainAccountName` derived from user reference
- line `accountName` derived from user reference

The Production Atomic Financial Core requires explicit Treasury/COA identity and operation identity. Therefore `accountant.html` was NOT modified in this unit.

Reason: changing these fields without a proven Consumer Contract would be an invented accounting mapping.

### `Current/PWA/finance-manager.html`
Original SHA:
`f4f4fa63692c614cc4719cf9d0e335ea0d2ccb6d`

Confirmed defect:
- dashboard calculated `profit = sales - purchases`;
- purchase-order date filter used `po_date` for the lower bound but `order_date` for the upper bound, while the observed purchase-order schema uses `po_date`.

Surgical change applied:
- ONLY `App.renderDashboard()` was replaced;
- financial KPIs now read from Production reporting RPCs:
  - `get_profit_loss`
  - `get_trial_balance`
  - `get_cash_flow`
  - `get_balance_sheet`
- treasury current balance remains a direct read for the current cash-position card;
- no other function or HTML area was rewritten.

Git commit:
`76eae6443aa3c06400aef3c67a0cb9c600d1895c`

Modified file:
`Current/PWA/finance-manager.html`

## 7. Why Accountant UI Was Not Expanded Yet

The requested professional Accountant UX is valid as a target, but the current backend contracts do not yet prove safe support for every requested module.

Target domains recorded for future implementation:
- dashboard/KPIs
- receipts
- payments
- journals
- receivables/customer balances
- payables/supplier balances
- driver settlements
- daily settlement
- treasury monitoring
- exceptions/audit

Implementation remains gated by proven backend consumer contracts.

## 8. Finance Manager UX Contract — Target

The Finance Manager should evolve toward:
- Executive financial dashboard
- revenue
- gross margin
- net result
- cash position
- receivables aging
- payables
- daily settlement control
- driver exposure
- treasury movement
- P&L
- balance sheet
- cash flow
- branch comparison
- sales vs collections
- anomalies
- incomplete/unposted journal alerts
- void/reversal alerts
- working-capital indicators

No KPI is considered production-ready until a RAWAEA source-of-truth contract exists.

## 9. Industry Benchmark Guardrail

External mature ERP systems support the general reporting hierarchy now targeted for RAWAEA:
- SAP Financial Statement Reporting exposes KPI, P&L, Balance Sheet, Cash Flow and multidimensional profitability views.
- Odoo exposes Balance Sheet, P&L, Executive Summary, General Ledger, Trial Balance, Aged Receivable, Aged Payable, Cash Flow and Audit Trail.
- Dynamics 365 provides configurable aging periods, balance/as-of dates, transaction/date criteria and collections-oriented customer aging.
- Manager provides core financial statements and customer/supplier aging reports.

These are benchmark references only. They do not override RAWAEA business contracts.

## 10. POS Handoff

`Current/PWA/pos.html` is a transaction-originating consumer of `save-sales-invoice` and is correctly identified as the next WRITE-SIDE closure unit for Hytham.

Khalid did not modify POS because Prompt 53 assigns POS Financial Closure to the transactional-finance track.

Known architectural boundary remains:
POS → save-sales-invoice → save_sales_invoice_atomic
with Inventory using `post_stock_movement` while financial journal/ledger responsibility remains distributed inside the sales atomic path.

## 11. Closure Matrix

| Unit | Status |
|---|---|
| Trial Balance tenant safety | CLOSED for current function contract |
| Profit & Loss tenant safety | CLOSED for current function contract |
| Balance Sheet tenant safety | CLOSED for current function contract |
| Cash Flow runtime failure | CLOSED |
| Cost Center UUID join defect | CLOSED |
| Cost Center tenant safety | CLOSED for current function contract |
| Financial reporting semantic contract | OPEN |
| Financial tenant identity | OPEN / OWNER DECISION |
| Accountant consumer contract | OPEN |
| Accountant UX implementation | DEFERRED |
| Finance Manager KPI consumer | SURGICALLY ALIGNED |
| Finance Manager full reporting UX | OPEN |
| Production financial security rollout | OPEN |
| POS transactional closure | HYTHAM TRACK |

## 12. Required Owner Decisions

1. Confirm the authoritative company identity for the accounting/treasury domain currently represented by `da4ef704-88ac-4120-aa0e-65b92b2aa2bc` versus operational users attached to `00000000-0000-0000-0000-000000000001`.
2. Confirm the intended RAWAEA cash-flow accounting semantics before replacing the current classification model.
3. Confirm the Accounting Consumer contract for receipt/payment account selection before modifying `accountant.html`.

## 13. Final Status

`FINANCIAL REPORTING CORE = PARTIALLY CLOSED / TENANT-SAFE FOR CURRENT CONTRACT`

`ACCOUNTANT CONSUMER = OPEN`

`FINANCE MANAGER CONSUMER = OPEN, WITH FIRST SURGICAL KPI ALIGNMENT APPLIED`

`GLOBAL FINANCIAL ZERO-DEBT = OPEN`

`AUTONOMOUS CTO READY = NO`
