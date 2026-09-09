# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report105 Main9 Forensic Recheck

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
- Current repository HEAD: `c994800ed90cc146207e45ab9ef16da3a5548b2f`
- Main9 has not been edited by the assistant; Owner Source Surgery protocol remains active.
- M9-01 (`_companyId` + `_nextDate`) is already closed and must not be repeated.
- M9-02..M9-09 remain open until their replacements are physically present in the current Git source.

## MAIN9 SURGERY STATUS
- `M9-01 = SOURCE CLOSED / DO NOT REPEAT`
- `M9-02` `_loadDashboardData(fromDate,toDate)` = OPEN / corrected surgical package issued and revalidated in Report105.
- `M9-03` `_loadDropdowns(params)` = OPEN / surgical package revalidated.
- `M9-04` `_showCustomerLedgerDetail(customerId,customerName)` = OPEN / surgical package revalidated.
- `M9-05` `_showItemMovementDetail(itemCode,itemName)` = OPEN / surgical package revalidated.
- `M9-06` `_showRunsheetDetail(runsheetCode)` = OPEN / surgical package revalidated.
- `M9-07` `_showSettlementDetail(settlementCode)` = OPEN / surgical package revalidated.
- `M9-08` `_generateReport(sectionKey,reportId)` = OPEN / corrected functional package revalidated.
- `M9-09` `_loadDetailedReports(fromDate,toDate,types)` = OPEN / corrected functional package revalidated.

## REPORT CHAIN
- `doc/Draft/Reprots/Report101_main9` = original Main9 surgical package.
- `doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md` = forensic recheck and Production reconciliation.
- `doc/Draft/Reprots/Report103_Main9_Forensic_Recheck_20260909.md` = pre-recheck state proving old Main9 source was still present.
- `doc/Draft/Reprots/Report104_Main9_Forensic_Recheck_20260909.md` = corrected surgical handoff.
- `doc/Draft/Reprots/Report105_Main9_Forensic_Recheck_20260909.md` = latest direct recheck, Production reconciliation, and closure status.

## PRODUCTION SNAPSHOT — DIRECT VERIFICATION
Observed at UTC `2026-09-09 08:42:57.712837`:
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

## INVENTORY INVARIANTS — DIRECT VERIFICATION
Checked at UTC `2026-09-09 08:44:38.440623`:
- negative_stock = `0`
- invalid_reservation = `0`
- available_mismatch = `0`

## ASSEMBLY GOVERNANCE
- Canonical editable source: `Current/PWA/main2/main1.md` through `main11.md`.
- Historical source: `Original/PWA/main/*` only.
- Generated target: `Current/PWA/New-main`.
- `.github/workflows/forensic_main_assembly.yml` is already correctly configured around `Current/PWA/main2/**`.
- Main2 assembly remains blocked until owner completes Main9 surgery and the post-surgery validation gate passes.

## CURRENT REPORTING GOVERNANCE
- `RW_STATE` is not an authoritative reporting data source when direct Production queries are available.
- Item Master reporting should use Production data directly; `max_qty` must be selected where recommendation logic uses it.
- Returns reporting must use only Production-supported movement types (`SalesReturn`, `DirectReturn`) unless a new type is directly proven.
- Threshold/reorder recommendations are `policy-based recommendation`, not AI demand forecasts without sufficient historical demand evidence.
- Tax and HR Attendance/Salary remain capability-gated where no authoritative Production source is proven.

## VALIDATION STATUS
- Governance masters reopened and reconciled.
- Report101 reopened.
- Report102 reopened.
- Report103 reopened.
- Report104 reopened.
- Report105 created and committed.
- Current Main9 reopened directly from Git.
- Current Production snapshot refreshed directly.
- Current `post_stock_movement` contract re-checked directly.
- Current inventory invariants refreshed directly.
- Main9 owner source surgery = NOT YET EXECUTED.
- Main9 post-surgery syntax = NOT YET PROVEN.
- Full Main2 assembly = NOT YET RUN.
- Browser/PWA smoke after final assembly = NOT YET RUN.
- Full report-by-report Production UI smoke = NOT YET RUN.
- Gold/Diamond parent closure = NOT YET PROVEN.

## LATEST REPORT
`doc/Draft/Reprots/Report105_Main9_Forensic_Recheck_20260909.md`

## LAST VERIFIED EVENT
- EVENT: `M9-FORENSIC-RECHECK-20260909-REPORT105`
- UTC timestamp: `2026-09-09 08:44:38.440623`
- Git Main9 SHA verified: `a72b970709ce69192bd47824685e99962aaf9fd8`
- Git repository HEAD verified before Report105 documentation commit: `c994800ed90cc146207e45ab9ef16da3a5548b2f`
- Production snapshot verified at `2026-09-09 08:42:57.712837 UTC`.
- Result: Main9 source remains unchanged; M9-02..M9-09 remain owner-source operations. Production Inventory Core is currently healthy and does not justify another rewrite.
- Next authorized action: owner executes the complete M9-02..M9-09 surgical package on `Current/PWA/main2/main9.md`; then reread Main9 to EOF, validate syntax/integration, match Main2, assemble, run node/browser gates, and only then perform Production UI smoke.

## SELF-AUDIT
### What I Proved
- Current Git HEAD and current Main9 SHA were refreshed directly.
- Current Main9 still contains the old implementations for M9-02..M9-09.
- Production current counts were refreshed directly.
- Production inventory invariants are clean.
- PostgreSQL reporting/inventory contracts were revalidated.
- Assembly path remains correct.
- No new Inventory Core rewrite is justified.
- Report105 was committed as the current forensic handoff.

### What I Did Not Prove
- Owner completion of M9-02..M9-09.
- Main9 syntax after owner surgery.
- Main2 integration after surgery.
- Generated New-main validity after assembly.
- Browser/PWA runtime after assembly.
- Full Production UI report smoke.
- Gold/Diamond closure.

### What Was Corrected
- Current Production time was updated from the stale Report104 checkpoint.
- Current Git HEAD was updated.
- Report104 was not treated as infallible.
- No `Return` movement type was introduced.
- No fake Forecast/AI semantics were introduced.
- No unnecessary Inventory Core changes were introduced.

### FINAL CLOSURE
`M9-01 = SOURCE CLOSED`
`M9-02..M9-09 = OPEN / OWNER SOURCE SURGERY REQUIRED`
`MAIN9 SOURCE = OPEN`
`MAIN2 ASSEMBLY = BLOCKED`
`PRODUCTION INVENTORY CORE = VERIFIED / NO NEW REPAIR JUSTIFIED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
