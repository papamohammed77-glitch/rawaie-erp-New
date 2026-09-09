# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report104 Main9 Forensic Recheck

### GOVERNING TARGET — NON-NEGOTIABLE
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

الحوكمة التنفيذية:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

### SOURCE-OF-TRUTH GOVERNANCE
- Production Runtime / Database is the execution reference.
- Historical reports are evidence, not current truth.
- `CURRENT_STATE.md` is a continuity checkpoint and must be reconciled against Git/Production.
- Unknown != bug; Unknown != remove.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md`.
- `Original/PWA/main/*` = historical reference only.
- `Current/PWA/New-main` = generated assembly target only.
- `.github/workflows/forensic_main_assembly.yml` already points to `Current/PWA/main2/**`; this remains correct.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.

## CURRENT MAIN9 — DIRECT GIT VERIFICATION
- File: `Current/PWA/main2/main9.md`
- Current Git blob SHA: `a72b970709ce69192bd47824685e99962aaf9fd8`
- Main9 has not been edited by the assistant; Owner Source Surgery protocol remains active.
- M9-01 (`_companyId` + `_nextDate`) is already closed and must not be repeated.
- M9-02..M9-09 remain open until their replacements are physically present in the current Git source.

## MAIN9 SURGERY STATUS
- `M9-01 = SOURCE CLOSED / DO NOT REPEAT`
- `M9-02` `_loadDashboardData(fromDate,toDate)` = OPEN / corrected surgical package issued in Report104.
- `M9-03` `_loadDropdowns(params)` = OPEN / surgical package from Report101 revalidated.
- `M9-04` `_showCustomerLedgerDetail(customerId,customerName)` = OPEN / surgical package revalidated.
- `M9-05` `_showItemMovementDetail(itemCode,itemName)` = OPEN / surgical package revalidated.
- `M9-06` `_showRunsheetDetail(runsheetCode)` = OPEN / surgical package revalidated.
- `M9-07` `_showSettlementDetail(settlementCode)` = OPEN / surgical package revalidated.
- `M9-08` `_generateReport(sectionKey,reportId)` = OPEN / corrected surgical package issued in Report104.
- `M9-09` `_loadDetailedReports(fromDate,toDate,types)` = OPEN / corrected surgical package issued in Report104.

## REPORT CHAIN
- `doc/Draft/Reprots/Report101_main9` = original Main9 surgical package.
- `doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md` = forensic recheck and Production reconciliation.
- `doc/Draft/Reprots/Report103_Main9_Forensic_Recheck_20260909.md` = latest pre-recheck state proving the old Main9 source was still present.
- `doc/Draft/Reprots/Report104_Main9_Forensic_Recheck_20260909.md` = current corrected Main9 surgical handoff; Report104 supersedes earlier surgery instructions where it explicitly adds corrections.

## PRODUCTION SNAPSHOT — DIRECT VERIFICATION
Observed at UTC `2026-09-09 07:19:19.093393`:
- companies = 1
- branches = 2
- users = 24
- items = 17
- customers = 3
- suppliers = 1
- treasury = 1
- chart_of_accounts = 17
- orders = 0
- runsheets = 0
- purchase_orders = 0
- stock_vouchers = 0
- stock_branches = 20
- inventory_log = 3
- receiving = 0
- receiving_details = 0
- journal_entries = 2

Current company verified directly: `00000000-0000-0000-0000-000000000001` / `الروائع`.

## PRODUCTION DATABASE CONTRACTS — DIRECTLY VERIFIED
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; tenant scope is via `branch_id -> branches.company_id`.
- `get_trial_balance(p_from_date,p_to_date)` exists.
- `get_profit_loss(p_from_date,p_to_date)` exists.
- `get_balance_sheet_data(p_as_of)` exists.
- `get_cash_flow(p_from_date,p_to_date)` exists.
- `get_pnl_by_cost_center(p_from_date,p_to_date)` exists.
- `get_budget_vs_actual(p_year,p_month,p_cost_center_id)` exists.
- `receive_purchase_atomic(..., p_operation_id uuid)` exists.
- `complete_return_atomic(...)` exists.
- `complete_order_delivery_atomic(...)` exists.
- Physical inventory movement remains owned by `post_stock_movement`.
- Current `post_stock_movement` supported movement types include `SalesReturn` and `DirectReturn`; there is no supported movement type named plain `Return`.

## INVENTORY CORE — DO NOT REOPEN WITHOUT NEW EVIDENCE
- `post_stock_movement` remains the authoritative Physical Movement Writer.
- `reserve_stock` / `release_stock_reservation` are reservation writers only.
- Bootstrap stock-row creation is not a Physical Movement engine.
- Main9 recheck produced no new evidence requiring an Inventory Core rewrite.

## ASSEMBLY GOVERNANCE
- Canonical editable source: `Current/PWA/main2/main1.md` through `main11.md`.
- Historical source: `Original/PWA/main/*` only.
- Generated target: `Current/PWA/New-main`.
- `.github/workflows/forensic_main_assembly.yml` is already correctly configured around `Current/PWA/main2/**`.
- Main2 assembly remains blocked until owner completes Main9 surgery and the post-surgery validation gate passes.

## NEW FINDINGS FROM REPORT104
1. Report101 replacement blocks must not be copied blindly where they use `RW_STATE` as report-result source.
2. M9-02 must query current Production Item/Customer data rather than trusting cached `RW_STATE` data.
3. M9-08 must query current Item Master directly and include `max_qty` when the recommendation logic uses it.
4. M9-09 must query current Item/Customer data directly and include `max_qty`.
5. `logistics-returns` must use only movement types proven by the deployed `post_stock_movement`: `SalesReturn` and `DirectReturn`.
6. Threshold-based purchase recommendations are policy heuristics, not demand forecasts or AI conclusions; Production currently has zero orders, so no demand forecast may be invented.
7. Finance report branches must continue using the authoritative Production RPCs rather than recreating accounting calculations in the UI.

## VALIDATION STATUS
- Governance masters reopened and reconciled.
- Report101 reopened.
- Report102 reopened.
- Report103 reopened.
- Current Main9 reopened directly from Git.
- Current Production snapshot re-established from Production evidence.
- Current `post_stock_movement` contract re-checked directly.
- Report104 created and committed with corrected surgical instructions.
- Main9 owner source surgery = NOT YET EXECUTED.
- Main9 post-surgery syntax = NOT YET PROVEN.
- Full Main2 assembly = NOT YET RUN.
- Browser/PWA smoke after final assembly = NOT YET RUN.
- Full report-by-report Production UI smoke = NOT YET RUN.
- Gold/Diamond parent closure = NOT YET PROVEN.

## LATEST REPORT
`doc/Draft/Reprots/Report104_Main9_Forensic_Recheck_20260909.md`

## LAST VERIFIED EVENT
- EVENT: `M9-FORENSIC-RECHECK-20260909-REPORT104`
- UTC date: `2026-09-09`
- Git Main9 SHA verified: `a72b970709ce69192bd47824685e99962aaf9fd8`
- Result: Main9 source remains unchanged; the previous surgery package was revalidated and corrected where necessary before owner execution.
- Next authorized action: owner executes the exact M9-02..M9-09 surgery in Report104 on `Current/PWA/main2/main9.md`; then re-read Main9 to EOF, prove syntax/integration, match Main2, and only then assemble.

## SELF-AUDIT
### What I Proved
- Current Main9 source was re-opened directly from Git.
- Current Main9 SHA remains `a72b970...`.
- M9-01 is already closed.
- The old M9-02..M9-09 implementations are still present in the current source.
- Production currently has one company and the current snapshot is known.
- Production Finance RPC signatures were directly checked.
- `post_stock_movement` movement types were directly checked.
- Assembly path is correct and should not be changed.
- No new Inventory Core rewrite is justified.
- Report104 captures the corrected Owner Source Surgery package.

### What I Did Not Prove
- Owner completion of M9-02..M9-09.
- Main9 syntax after owner surgery.
- Main2 integration after surgery.
- Generated New-main validity after assembly.
- Browser/PWA runtime after assembly.
- Full Production UI report smoke.
- Gold/Diamond closure.

### What Was Corrected
- Report101 was not treated as infallible.
- `RW_STATE` was identified as an unsafe report-result source for Current Production reporting.
- The unsupported plain `Return` movement type was removed from the target contract.
- `max_qty` omission was identified in M9-09/M9-08 recommendation data.
- Recommendation semantics were clarified so that threshold heuristics are not presented as AI forecasting.

### FINAL CLOSURE
`M9-01 = SOURCE CLOSED`
`M9-02..M9-09 = OPEN / OWNER SOURCE SURGERY REQUIRED`
`MAIN9 SOURCE = OPEN`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
`GLOBAL INVENTORY CORE = VERIFIED / NO NEW REPAIR JUSTIFIED`
