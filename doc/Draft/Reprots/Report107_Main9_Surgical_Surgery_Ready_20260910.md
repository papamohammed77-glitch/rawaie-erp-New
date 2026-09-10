# RAWAEA ERP — Report107
## Main9 Full Recheck + Surgical Modification Package — 2026-09-10

## 0. Governing rule

This report follows the active Successor CTO directive:

`CURRENT VERIFIED REALITY > CURRENT PRODUCTION > DATABASE CONTRACTS > DEPLOYMENTS > GIT > SOURCE > HISTORICAL REPORTS > MEMORY > ASSUMPTION`

`Current/PWA/main2/main9.md` is Owner Source Surgery territory. It was **not modified by the assistant**. The assistant is authorized to provide exact surgical instructions and full replacements only.

## 1. Current Git reconciliation

Current repository HEAD at verification window: `24d384c403608d7f379b3cfa2188c4a2a9f8b4b9`.

The comparison from Report106 commit `1fa675e2c433e77c0f11f01879d4c7aebeef175f` to current HEAD is five commits ahead and contains documentation/master additions only; no Main2 source file change was identified in that comparison.

Main9 current SHA: `a72b970709ce69192bd47824685e99962aaf9fd8`.
Main9 size: `95180` bytes.

## 2. Current Production reconciliation

Fresh read-only Production snapshot at `2026-09-10 03:56:52.097518 UTC`:

- companies: 1
- branches: 2
- users: 24
- items: 17
- customers: 3
- orders: 0
- runsheets: 0
- purchase_orders: 0
- stock_vouchers: 0
- stock_branches: 20
- inventory_log: 3
- receiving: 0
- journal_entries: 2

No Main9 report claim in this document relies on the older 2026-09-09 Production snapshot when a current snapshot was required.

## 3. Historical surgical chain revalidated

Recent Main9 forensic chain:

- Report101 — initial Main9 forensic package.
- Report102 — Main9 recheck + surgical closure manifest.
- Report103 — Main9 forensic recheck.
- Report104 — corrected surgical package.
- Report105 — recheck and current truth.
- Report106 — final forensic surgery revalidation.

Report106 is the immediate predecessor, but historical packages are evidence only. The current source and current Production were reopened for this round.

## 4. Main9 source structure revalidated

Main9 consists of two top-level modules:

1. `RW_Reports`
2. `RW_Reports_Comprehensive`

The file terminates after:

`window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;`

No tail content after the module closing was identified.

## 5. Defect status

- M9-01 = SOURCE CLOSED; must not be re-applied.
- M9-02 = SURGERY READY
- M9-03 = SURGERY READY
- M9-04 = SURGERY READY
- M9-05 = SURGERY READY
- M9-06 = SURGERY READY
- M9-07 = SURGERY READY
- M9-08 = SURGERY READY
- M9-09 = SURGERY READY

Main9 = OWNER ACTION REQUIRED.
Main2 Assembly = BLOCKED until Owner Source Surgery is applied and re-read to EOF.

## 6. Confirmed Production contracts used by the surgery package

- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; scope is via `branch_id -> branches.company_id`.
- `inventory_log` is company-scoped and item-scoped through `company_id` and `item_id`.
- Current Finance RPCs are:
  - `get_trial_balance(p_from_date date, p_to_date date)`
  - `get_profit_loss(p_from_date date, p_to_date date)`
  - `get_balance_sheet_data(p_as_of date)`
  - `get_cash_flow(p_from_date date, p_to_date date)`
  - `get_pnl_by_cost_center(p_from_date date, p_to_date date)`
  - `get_budget_vs_actual(p_year int, p_month int, p_cost_center_id uuid default null)`
- Report106 contract: Returns reporting must use supported movement semantics (`SalesReturn` / `DirectReturn`); plain `Return` is not a supported physical movement type.
- HR Attendance/Salary and Tax do not have a proven authoritative Production source in the current evidence set; keep them capability-gated.

## 7. Required Owner Source Surgery

### M9-02 — `_loadDashboardData`

Current reference line: `67` (reference only; exact deletion boundary is the complete function from its opening to the next exact marker before `_buildCheckboxGroup`).

Action:
`SEARCH → REPLACE`

Required behavior:
- fresh Production `items` query; do not use `RW_STATE.data.items` as report source;
- fresh Production `customers` query, company-scoped;
- orders company-scoped;
- branches company-scoped;
- stock selected by branch IDs with `qty, allocated_qty`;
- available stock = `max(0, qty - allocated_qty)`;
- low-stock threshold uses available stock against `reorder_point`;
- remove unsupported forecast/confidence semantics.

### M9-09 — `_loadDetailedReports`

Current reference line: `260`.

Action:
`SEARCH → REPLACE`

Required behavior:
- direct Production Item Master;
- direct Production Customers, company-scoped;
- branches and stock company-scoped via branch IDs;
- order reads company-scoped;
- `order_details` must be derived only from Order IDs belonging to the current company;
- recommendation rules must be explicit/policy-based;
- `max_qty` participates in overstock/promotion recommendation;
- no AI/forecast claim unsupported by Production data;
- unsupported capabilities remain explicitly gated rather than fabricated.

### M9-03 — `_loadDropdowns`

Current reference line: `654`.

Action:
`SEARCH → REPLACE`

Required behavior:
- reset every select before appending options;
- Customer/Supplier/Treasury/Account/Driver/Area queries are company-scoped;
- UUIDs are used for UUID-backed entities;
- Item selector uses `item_code` because the schema proves it globally unique;
- repeated opening of a report must not duplicate options.

### M9-04 — `_showCustomerLedgerDetail`

Current reference line: `811`.

Action:
`SEARCH → REPLACE`

Required behavior:
- resolve the customer by `id = supplied customer UUID` AND `company_id = current company`;
- reject missing/out-of-company customer;
- query `customer_ledger` by the resolved `customer.id`;
- never trust a display value as a tenant identity.

### M9-05 — `_showItemMovementDetail`

Current reference line: `828`.

Action:
`SEARCH → REPLACE`

Required behavior:
- resolve Item Master by globally unique `item_code`;
- query `inventory_log` with both `company_id` and resolved `item_id`;
- do not use `item_code` as the sole tenant filter.

### M9-06 — `_showRunsheetDetail`

Current reference line: `845`.

Action:
`SEARCH → REPLACE`

Required behavior:
- runsheet resolution requires `company_id`;
- `run_sheet_details` uses resolved `runsheet.id`;
- orders linkage uses `orders.runsheet_id = runsheet.id` and `orders.company_id = current company`;
- never compare UUID `runsheet_id` with human runsheet code.

### M9-07 — `_showSettlementDetail`

Current reference line: `875`.

Action:
`SEARCH → REPLACE`

Required behavior:
- settlement lookup requires `company_id`;
- if `runsheet_id` exists, resolve the runsheet by UUID + company;
- display the resolved runsheet code only after UUID resolution.

### M9-08 — `_generateReport`

Current reference line: `893`.

Action:
`SEARCH → REPLACE`

Required behavior:
- all tenant-owned reads carry company scope;
- stock is scoped through company-owned branches;
- inventory movement uses `company_id + item_id`;
- all reports use current Production data, not `RW_STATE` as authoritative source;
- sales item detail is constrained by current-company order IDs;
- returns use supported movement types only (`SalesReturn`, `DirectReturn`, and other explicitly supported semantics where proven);
- Finance reports use the authoritative current Production RPCs directly;
- CRM customer list/analysis/area are company-scoped direct reads;
- loading/unloading reads use supported Production movement/log semantics;
- HR Employee List is company-scoped;
- HR Attendance/Salary and Tax remain capability-gated because no authoritative Production source has been proven.

## 8. Integration match against complete Main2

The full `Current/PWA/main2/main2.md` source was reopened. The following integration constraints must be preserved by the Owner surgery:

- `RW_Dashboard` and `RW_Items` remain owned by Main2; Main9 must not redefine them.
- Main2's `_rwCompanyId()` remains available as the parent context helper.
- `RW_Items._loadMovementReport` already follows the centralized inventory identity pattern: company-scoped `inventory_log` + item identity + optional branch filter. M9-05 must align to this pattern.
- Main2 item/stock views use Item Master plus branch-scoped stock; Main9 must follow the same data contract and not fall back to parent state arrays as authoritative report data.
- Main9 remains two report modules and must not add script open/close tags.
- `Current/PWA/main2/**` remains the source; `Current/PWA/New-main` is assembly output only.

## 9. Syntax gate

Static source review found no need to alter Main9 script boundaries and no parser-level defect that justifies a file rewrite.

Formal post-surgery syntax is NOT PROVEN yet because Owner Source Surgery has not been applied. The mandatory sequence after Owner action remains:

`Read Main9 to EOF → syntax validation → complete Main2 match → governed Assembly → node --check → Browser/PWA smoke → Production UI smoke`.

## 10. Closure state

This record is **SURGERY READY / OWNER ACTION REQUIRED**, not Source Closed, Deployment Closed, Runtime Closed, Production Verified, or Fully Closed.

No false closure is permitted.
