# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-10 — Report108 Main9 Current Truth Recheck

### GOVERNING TARGET — NON-NEGOTIABLE
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

الحوكمة التنفيذية:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

### SOURCE-OF-TRUTH GOVERNANCE
- Current verified reality outranks historical reports.
- Production Runtime / Database is the execution reference.
- Historical reports are evidence, not current truth.
- `CURRENT_STATE.md` is a continuity checkpoint and must be reconciled against Git/Production.
- Unknown != bug; Unknown != remove.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` = historical reference only.
- `Current/PWA/New-main` = generated assembly target only.
- `.github/workflows/forensic_main_assembly.yml` remains the governed assembly path.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.

## CURRENT GIT TRUTH
- Latest verified repository HEAD: `63bcf12655424e53c0723bc0976b0860c114ae6d`
- Latest commit message: `Update main9.md`
- Latest commit time: `2026-09-10 04:12:14 UTC`
- Current Main9: `Current/PWA/main2/main9.md`
- Current Main9 blob SHA: `08b5eed395b49843db6bce56d73565b98991db30`
- Current Main9 size: `113758` bytes
- Report107 referenced obsolete Main9 SHA `a72b970709ce69192bd47824685e99962aaf9fd8` and must not be treated as current source truth.
- Main9 remains Owner Source Surgery territory; assistant must not directly edit the source file under the active governing directive.

## CURRENT MAIN9 STATUS
- `M9-01 = CURRENT / DO NOT REPEAT`
- `_loadDashboardData` = CURRENT HISTORICAL REPAIR ALREADY PRESENT; no blind reapplication.
- `_loadDetailedReports` = CURRENT HISTORICAL REPAIR ALREADY PRESENT; no blind reapplication.
- `_showCustomerLedgerDetail` = CURRENT / tenant and UUID boundary aligned.
- `_showItemMovementDetail` = CURRENT / global Item Master + company/item inventory identity aligned.
- `_showRunsheetDetail` = CURRENT / company + UUID boundary aligned.
- `_showSettlementDetail` = CURRENT / company + UUID boundary aligned.
- `_companyId` = OPEN / current Parent mismatch: Main2/Main1 use `RW_STATE.app.company.id`, while current Main9 helper first checks legacy `RW_STATE.app.companyId` and `RW_STATE.user.companyId`.
- `_loadDropdowns` = OPEN / reset/idempotency requirement remains.
- `_generateReport` = OPEN / multiple current tenant-scope and source-of-truth defects remain.

## CURRENT PRODUCTION SNAPSHOT — DIRECT VERIFICATION
Verified at UTC `2026-09-10 04:34:33.000217`:
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

## CURRENT PRODUCTION FINANCE CONTRACTS — DIRECTLY VERIFIED
- `get_trial_balance(p_from_date,p_to_date)` exists and derives current authenticated company context.
- `get_profit_loss(p_from_date,p_to_date)` exists and derives current authenticated company context.
- `get_balance_sheet_data(p_as_of)` exists and derives current authenticated company context.
- `get_cash_flow(p_from_date,p_to_date)` exists and derives current authenticated company context.
- `get_pnl_by_cost_center(p_from_date,p_to_date)` exists and derives current authenticated company context.
- `get_budget_vs_actual(p_year,p_month,p_cost_center_id)` exists and derives current authenticated company context.

## CURRENT DATABASE CONTRACTS
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; tenant scope is through `branch_id -> branches.company_id`.
- `inventory_log` is company-scoped and item-scoped through `company_id + item_id`.
- Main2 company context is `RW_STATE.app.company.id`.
- Current Main2 `RW_Items` inventory movement reporting uses the centralized `inventory_log.company_id + item_id` identity pattern.
- Current supported physical return semantics include `SalesReturn` and `DirectReturn`; plain `Return` must not be used as a proven movement type.

## INVENTORY CORE — DO NOT REOPEN WITHOUT NEW EVIDENCE
- `post_stock_movement` remains the authoritative Physical Movement Writer.
- `reserve_stock` / `release_stock_reservation` are reservation writers only.
- No new Main9 work justifies an Inventory Core rewrite.

## ASSEMBLY GOVERNANCE
- Canonical editable source: `Current/PWA/main2/main1.md` through `main11.md`.
- Historical source: `Original/PWA/main/*` only.
- Generated target: `Current/PWA/New-main`.
- Existing New-main runtime workflow does not validate `main9.md`; it validates generated New-main instead.
- Therefore Main9 formal syntax must be independently proven after Owner Source Surgery.
- Main2 assembly remains blocked until the source surgery and validation gates pass.

## CURRENT REPORTING GOVERNANCE
- `RW_STATE.data.*` is not authoritative report data when direct Production queries are available.
- Item Master reporting uses Production data directly.
- Stock reporting scopes through company-owned branch IDs and computes Available as `max(0, qty - allocated_qty)` where applicable.
- `order_details` reporting must be constrained by current-company Order IDs.
- Inventory movement reporting uses `company_id + item_id`.
- Finance reports use authoritative current Production finance RPCs when applicable.
- Returns reporting uses only proven supported movement semantics.
- Recommendation logic is policy-based unless historical demand evidence justifies a forecast.
- Tax and HR Attendance/Salary remain capability-gated where no authoritative Production source is proven.

## LATEST REPORT
`doc/Draft/Reprots/Report108_Main9_Current_Truth_Recheck_20260910.md`

## VALIDATION STATUS
- Governing Master directive reopened.
- Report107 reopened as historical evidence only.
- Latest Main9 commit reopened directly.
- Current Main9 source reopened from beginning through terminal module assignment.
- Current Main2 source reopened and parent integration contracts rechecked.
- Current Production snapshot refreshed directly.
- Current Finance RPC contracts refreshed directly.
- `_loadDashboardData` historical repair was found already present; no duplicate repair issued.
- `_loadDetailedReports` historical repair was found already present; no duplicate repair issued.
- M9-04..M9-07 current implementations align with their proven identity contracts; no duplicate repair issued.
- Main9 Owner Source Surgery = NOT YET EXECUTED.
- Formal Main9 `node --check` = NOT PROVEN.
- Main2 full integration gate after surgery = NOT RUN.
- Governed assembly = NOT RUN.
- New-main syntax/runtime = NOT RUN for this Main9 cycle.
- Browser/PWA smoke = NOT RUN for this Main9 cycle.
- Full Production UI report smoke = NOT RUN.
- Gold/Diamond parent closure = NOT PROVEN.

## LAST VERIFIED EVENT
- EVENT: `M9-CURRENT-TRUTH-RECHECK-20260910-REPORT108`
- UTC timestamp: `2026-09-10 04:34:33.000217`
- Git HEAD: `63bcf12655424e53c0723bc0976b0860c114ae6d`
- Main9 SHA: `08b5eed395b49843db6bce56d73565b98991db30`
- Production snapshot: `2026-09-10 04:34:33.000217 UTC`
- Result: Report107 is stale relative to the current Main9 source. The current source contains the major M9-02/M9-09 historical repairs already. New verified defects are limited to the Parent company-context helper, dropdown idempotency, and multiple tenant/source-of-truth violations in `_generateReport`.
- Next authorized action: Owner applies the exact surgical replacements to current Main9 only; then Main9 is reread to EOF, syntax-checked, matched against complete current Main2, assembled, runtime-tested, and Production UI-smoked.

## SELF-AUDIT
### What was proved
- Latest Main9 source and latest Git HEAD were refreshed directly.
- Report107 is not current source truth.
- Main2 current company context was verified directly.
- Current Production counts were refreshed directly.
- Current Finance RPC contracts were refreshed directly.
- Main9 current implementations were compared against current Parent contracts.
- Previously completed Main9 repairs were not redundantly reopened.

### What was not proved
- Formal Main9 parser success.
- Owner application of source surgery.
- Post-surgery Main2 integration.
- Governed assembly output validity.
- Browser/PWA runtime success.
- Production UI report smoke.
- Gold/Diamond closure.

### False-closure protections
- No historical report claim was promoted to current truth.
- No already-present M9-02/M9-09 repair was blindly re-applied.
- No plain `Return` movement semantics were accepted.
- No fake forecast/AI capability was introduced.
- No production status was marked closed without a runtime proof.

## FINAL CLOSURE
`M9-02 = CURRENT / DO NOT REPEAT`
`M9-03 = OPEN / SURGERY REQUIRED`
`M9-04 = CURRENT / DO NOT REPEAT`
`M9-05 = CURRENT / DO NOT REPEAT`
`M9-06 = CURRENT / DO NOT REPEAT`
`M9-07 = CURRENT / DO NOT REPEAT`
`M9-08 = OPEN / SURGERY REQUIRED`
`M9-09 = CURRENT / DO NOT REPEAT`
`MAIN9 SOURCE = OWNER SOURCE SURGERY REQUIRED`
`MAIN9 FORMAL SYNTAX = NOT PROVEN`
`MAIN2 ASSEMBLY = BLOCKED`
`PRODUCTION INVENTORY CORE = VERIFIED / NO NEW REWRITE JUSTIFIED`
`PARENT GOLD/DIAMOND = NOT CLOSED`