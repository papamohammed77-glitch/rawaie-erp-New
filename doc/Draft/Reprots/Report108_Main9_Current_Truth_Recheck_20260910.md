# RAWAEA ERP — Report108
## Main9 Current Truth Recheck + Surgical Reconciliation — 2026-09-10

## 0. Governing rule

This record follows the active Successor CTO governance hierarchy:

`CURRENT VERIFIED REALITY > CURRENT PRODUCTION > CURRENT DATABASE CONTRACTS > CURRENT DEPLOYMENTS > CURRENT GIT > CURRENT SOURCE > VERIFIED ARTIFACTS > HISTORICAL CONTRACTS > HISTORICAL SOURCE > HISTORICAL REPORTS > HISTORICAL PROMPTS > MEMORY > ASSUMPTION`

Historical reports are evidence only. They are not current truth.

`Current/PWA/main2/main9.md` remains Owner Source Surgery territory. The assistant does not directly modify this file under the active governing directive; exact surgery must be applied by the Owner, then re-read to EOF and validated.

---

## 1. Current Git truth

Latest repository commit verified directly:

- HEAD: `63bcf12655424e53c0723bc0976b0860c114ae6d`
- Commit message: `Update main9.md`
- Commit time: `2026-09-10 04:12:14 UTC`

Current Main9 source:

- File: `Current/PWA/main2/main9.md`
- Blob SHA: `08b5eed395b49843db6bce56d73565b98991db30`
- Size from current Git listing: `113758` bytes

Report107 was committed before this Main9 source update and therefore is historical guidance only.

Report107 recorded a different Main9 SHA `a72b970709ce69192bd47824685e99962aaf9fd8` and size `95180` bytes. That source is no longer the current Main9.

---

## 2. Current Production truth

Fresh read-only Production snapshot verified directly at:

`2026-09-10 04:34:33.000217 UTC`

- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- orders = 0
- runsheets = 0
- purchase_orders = 0
- stock_vouchers = 0
- stock_branches = 20
- inventory_log = 3
- receiving = 0
- journal_entries = 2
- audit_log = 1869

Current Production finance RPCs were also re-queried directly and exist with the current company-context contract:

- `get_trial_balance(p_from_date date, p_to_date date)`
- `get_profit_loss(p_from_date date, p_to_date date)`
- `get_balance_sheet_data(p_as_of date)`
- `get_cash_flow(p_from_date date, p_to_date date)`
- `get_pnl_by_cost_center(p_from_date date, p_to_date date)`
- `get_budget_vs_actual(p_year integer, p_month integer, p_cost_center_id uuid default null)`

The Production finance RPCs derive company context through the current authenticated company context and are suitable as authoritative finance report engines.

---

## 3. Governing source and parent integration re-read

`Current/PWA/main2/main2.md` was reopened from its current Git blob and its parent contracts were rechecked.

Main2 defines:

```javascript
function _rwCompanyId() {
    return window.RW_STATE && RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id ? RW_STATE.app.company.id : null;
}
```

Main1 defines the actual current `RW_STATE` shape as:

```javascript
RW_STATE.app.company.id
```

and sets that value from `users.company_id` after authentication.

Main2 owns `RW_Dashboard` and `RW_Items` and exposes the centralized inventory reporting pattern using `inventory_log.company_id + item_id`.

Therefore Main9 must consume the current parent company identity as `RW_STATE.app.company.id` unless a fully proven compatibility path exists.

---

## 4. Main9 complete source re-read

The current Main9 blob was reopened from byte/source beginning through its terminal module assignment.

The file still consists of the two governed modules:

1. `RW_Reports`
2. `RW_Reports_Comprehensive`

The file terminates at:

`window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;`

No extra script wrapper, tail block, or assembly markup was added to Main9.

---

## 5. Latest Main9 change was materially real

The latest commit `63bcf126...` directly changes `_loadDashboardData` from the older implementation that used `RW_STATE.data.items`, forecast/confidence values, and a calculated monthly forecast, to a newer direct-Production implementation.

The current `_loadDashboardData` now:

- validates the date range;
- reads company-scoped branches;
- reads company-scoped orders;
- reads Item Master directly from Production;
- reads branch-scoped stock using `qty` and `allocated_qty`;
- computes available quantity as `max(0, qty - allocated_qty)`;
- evaluates reorder point against available stock;
- reads customers directly from Production;
- removes the unsupported forecast/confidence claim;
- explicitly labels the displayed source as Production.

Therefore M9-02 must NOT be replaced using the Report107 package. The current implementation is newer and must be preserved except for any defect independently proven against the current Parent contract.

---

## 6. Current defect: Main9 company identity helper

Current Main9 `_companyId()` still checks:

```javascript
RW_STATE.app.companyId
```

and then:

```javascript
RW_STATE.user.companyId
```

But current Main2/Main1 establish the active company at:

```javascript
RW_STATE.app.company.id
```

This is a current source defect and is not a historical re-open of M9-01 semantics.

### Required surgery

Do NOT reapply the historical `_companyId` package wholesale.

Replace only the helper body so that the resolution order is:

1. `RW_STATE.app.company.id` — current Parent contract.
2. `RW_STATE.app.companyId` — compatibility fallback only if proven present.
3. `RW_STATE.user.companyId` — historical fallback only.
4. throw explicit error if no company context exists.

No business behavior outside this helper should change.

---

## 7. M9-02 status

`_loadDashboardData(fromDate,toDate)`:

**CURRENT STATUS = SOURCE CURRENT / DO NOT REPLACE BLINDLY**

The major Report107 changes are already physically present in the latest Main9 source.

Remaining issue is only the current `_companyId()` parent-context mismatch described above.

---

## 8. M9-09 current state

`_loadDetailedReports(fromDate,toDate,types)` was re-read in the current source.

The current implementation already performs the important direct-Production pattern:

- Item Master direct read;
- company-scoped customers;
- company-scoped active branches;
- stock reads through company-owned branch IDs;
- company-scoped orders;
- `order_details` constrained through the current company order IDs;
- available quantity computed from `qty - allocated_qty`;
- max quantity is selected and used in recommendation policy;
- recommendations are policy-based rather than fabricated AI forecasting;
- customer/expansion recommendations remain explicitly capability-gated.

Therefore:

**M9-09 = CURRENT / DO NOT REPLACE BLINDLY**

Only defects independently proven in the current source may be surgically changed.

---

## 9. M9-03 current state — dropdowns

Current `_loadDropdowns(params)` is company-scoped for:

- customers;
- suppliers;
- treasury;
- chart of accounts;
- drivers;
- areas.

The item selector uses globally unique `item_code`, consistent with the Production `UNIQUE(item_code)` contract.

### Confirmed remaining defect

`_appendOptions()` appends to the existing `<select>` without first resetting it.

The current UI normally recreates the report parameter DOM when opening a report, which reduces duplicate risk, but the governing contract explicitly requires idempotent reopening.

### Required surgery

Before appending options to every select, preserve exactly one existing placeholder option where applicable, clear all generated options, then append the current Production result set.

Do not change value semantics:

- UUID-backed entities remain UUID values;
- item selector remains `item_code`.

**M9-03 = SURGERY REQUIRED**

---

## 10. M9-04 status

`_showCustomerLedgerDetail(customerId,customerName)` currently:

- resolves customer by `id + company_id`;
- rejects missing/out-of-company customer;
- queries ledger using the resolved `customer.id`.

No new defect was found that justifies reopening the already-correct identity contract.

**M9-04 = CURRENT / DO NOT REPLACE**

---

## 11. M9-05 status

`_showItemMovementDetail(itemCode,itemName)` currently:

- resolves Item Master by globally unique `item_code`;
- uses resolved `item.id`;
- queries `inventory_log` with `company_id + item_id`.

This aligns with the current Main2 `RW_Items` movement-report contract.

**M9-05 = CURRENT / DO NOT REPLACE**

---

## 12. M9-06 status

`_showRunsheetDetail(runsheetCode)` currently:

- resolves runsheet using `company_id + runsheet_code`;
- then uses resolved `runsheet.id` for `run_sheet_details`;
- links orders through `runsheet_id = resolved UUID` and company scope.

This satisfies the current UUID boundary.

**M9-06 = CURRENT / DO NOT REPLACE**

---

## 13. M9-07 status

`_showSettlementDetail(settlementCode)` currently:

- resolves settlement by `company_id + settlement_code`;
- resolves an attached runsheet using `company_id + UUID`;
- displays the human runsheet code only after UUID resolution.

**M9-07 = CURRENT / DO NOT REPLACE**

---

## 14. M9-08 current defects

`_generateReport(sectionKey,reportId)` remains the major open source defect.

### Confirmed unscoped reads in the current source

Sales:

- `sales-summary` reads `orders` without `company_id`.
- `sales-by-customer` reads `orders` without `company_id`.
- `sales-by-item` reads `order_details` directly by date without first constraining Order IDs to current company.
- `sales-by-area` reads `orders` without `company_id`.
- `sales-order-status` reads `orders` without `company_id`.
- `sales-customer-ledger` reads `customer_ledger` from the submitted customer UUID without first resolving and validating the current company customer.
- `sales-runsheet-performance` reads `runsheets` without `company_id`.

Inventory:

- `inventory-stock` uses `RW_STATE.data.items` as report authority and reads all `stock_branches` without company-owned branch filtering.
- `inventory-movement` reads `inventory_log` by `item_code` only; no company + item identity pair.

CRM:

- `crm-customer-list` uses `RW_STATE.data.customers` as report authority.
- `crm-customer-analysis` reads `orders` without company scope.
- `crm-customer-by-area` uses `RW_STATE.data.customers`.

Purchasing:

- `purchase-by-supplier` needs company scope on `purchase_orders`.
- `purchase-order-status` needs company scope on `purchase_orders`.
- `purchase-receiving` must scope `receiving` by company and derive `receiving_details` through company-owned operation IDs; `receiving_details` itself does not carry `company_id`.

Finance:

- `finance-general-ledger` reads `journal_lines` with only the account filter; the related `journal_entries` must be constrained to current company.
- `finance-treasury` reads `cash_box` by treasury without an independently proven company guard.
- Finance report engines should use the current authoritative Production finance RPCs directly where their contracts match the report.
- `finance-tax` remains capability-gated.

Logistics:

- `logistics-loading-unloading` reads `stock_vouchers` without company scope.
- `logistics-returns` queries unsupported `stock_vouchers.type = 'Return'`; current Production movement semantics support `SalesReturn` / `DirectReturn` and must be used instead.
- `logistics-settlement` reads `daily_settlements` without company scope.
- `logistics-driver-performance` reads `runsheets` without company scope.

HR:

- `hr-employee-list` reads `users` without company scope.
- attendance/salary remain unavailable and must stay capability-gated until a proven authoritative source exists.

### Required surgery

`_generateReport()` must be replaced as one complete function only after its exact current function boundary is extracted and reviewed against the current source.

The replacement contract must:

1. derive company context through `_companyId()`;
2. never use `RW_STATE.data.*` as authoritative report data where Production reads exist;
3. scope every tenant-owned entity by company;
4. use branch ownership for `stock_branches`;
5. use `company_id + item_id` for inventory movement;
6. constrain `order_details` through current-company order IDs;
7. use supported return movement semantics only;
8. call the current Production finance RPC contracts directly;
9. preserve capability gates instead of fabricating data;
10. preserve existing UI/output semantics unless the current contract itself is wrong.

**M9-08 = SURGERY READY / OPEN**

---

## 15. Syntax validation status

### Static source review

The current Main9 source was reopened through its module termination and its script/module boundaries were inspected.

No broken module tail or missing top-level wrapper was found.

### Formal parser gate

A formal `node --check` against the exact current Main9 source was **not independently executed in this verification window** because the available GitHub source retrieval path did not materialize the full blob into the local execution environment, and no current GitHub Action exists that checks `Current/PWA/main2/main9.md` directly. The existing New-main runtime workflow checks `Current/PWA/New-main`, not Main9.

Therefore:

`MAIN9 FORMAL SYNTAX = NOT PROVEN`

This is not a claim of syntax failure. It is an explicitly unverified gate and must remain so until the Owner Source Surgery has been applied and the exact file is passed through `node --check`.

---

## 16. Main2 integration gate

Main2 was reopened from the current Git blob.

Confirmed integration constraints:

- Main2 owns `RW_Dashboard` and `RW_Items`.
- Main2 company helper is `_rwCompanyId()` and resolves `RW_STATE.app.company.id`.
- Main2 inventory drill-down uses `inventory_log.company_id + item_id`.
- Main9 must not redefine Main2-owned modules.
- Main9 remains a two-module source file.
- Main9 must not acquire `<script>` tags.
- Assembly target remains `Current/PWA/New-main`.

Therefore the parent integration contract is clear.

---

## 17. Execution status

### CLOSED / DO NOT REPEAT

- M9-04
- M9-05
- M9-06
- M9-07
- M9-02 major historical repair set already present in latest source
- M9-09 major historical repair set already present in latest source

### OPEN / CURRENT SURGERY REQUIRED

- `_companyId()` parent-context correction
- M9-03 dropdown reset/idempotency
- M9-08 complete `_generateReport()` current-company rewrite

### NOT PROVEN

- formal Main9 `node --check`
- post-surgery Main2 integration gate
- governed assembly
- New-main syntax/runtime
- browser/PWA smoke
- Production UI smoke
- Gold/Diamond closure

---

## 18. Required Owner Source Surgery sequence

The next legal sequence under the governing directive is:

`Apply exact Main9 source surgery`
→
`Read Main9 from first character to EOF again`
→
`node --check exact Main9 source`
→
`full Main2 integration match`
→
`governed assembly`
→
`node --check generated New-main inline JS`
→
`browser/PWA smoke`
→
`Production UI smoke`
→
`refresh Production snapshot`
→
`update CURRENT_STATE`
→
`closure report`

No stage may be skipped or inferred from an older report.

---

## 19. Self-audit

### What was proved

- The active Git HEAD is newer than Report107.
- Current Main9 SHA and size differ materially from Report107.
- Current Production was refreshed directly.
- Current Production finance RPC contracts were re-read directly.
- Main2 current company context was re-read directly.
- M9-02 and M9-09 historical repair content is already present in the current Main9 source and must not be blindly repeated.
- M9-04 through M9-07 are already aligned with the current company/UUID contracts.
- M9-08 remains materially unsafe because several report reads are still unscoped or use RW_STATE as report authority.

### What was not proved

- Formal parser success for current Main9.
- Post-surgery behavior, because Owner Source Surgery is not legally performed by the assistant under the active source-boundary directive.
- Full assembly and runtime.
- Production UI report smoke.

### False-closure checks

- No historical Report107 status was promoted to current truth.
- No already-fixed Main9 functions were rewritten merely because they appeared in Report107.
- No unsupported Return movement type was accepted as valid.
- No fake AI/forecast behavior was reintroduced.
- No `RW_STATE` report authority was declared acceptable where direct Production data is available.

---

## FINAL STATUS

`MAIN9 = OWNER SOURCE SURGERY REQUIRED`

`M9-02 = CURRENT / DO NOT REPEAT`

`M9-03 = SURGERY REQUIRED`

`M9-04 = CURRENT / DO NOT REPEAT`

`M9-05 = CURRENT / DO NOT REPEAT`

`M9-06 = CURRENT / DO NOT REPEAT`

`M9-07 = CURRENT / DO NOT REPEAT`

`M9-08 = SURGERY READY / OPEN`

`M9-09 = CURRENT / DO NOT REPEAT`

`MAIN9 FORMAL SYNTAX = NOT PROVEN`

`MAIN2 ASSEMBLY = BLOCKED`

`GOLD/DIAMOND = NOT CLOSED`
