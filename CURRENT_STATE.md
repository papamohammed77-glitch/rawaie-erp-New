# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report103 Main9 Forensic Recheck

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
- `.github/workflows/forensic_main_assembly.yml` already points to `Current/PWA/main2/**`; this is correct and must not be changed without new evidence.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.

## CURRENT MAIN9 — DIRECT GIT VERIFICATION
- File: `Current/PWA/main2/main9.md`
- Current Git blob SHA: `a72b970709ce69192bd47824685e99962aaf9fd8`
- Latest direct Main9 commits inspected: `0748e00b...` then `ef201a62...` on 2026-09-09.
- The current source still contains the older implementations for M9-02..M9-09. The previously documented replacements are not actually present in the current Main9 source.
- M9-01 (`_companyId` + `_nextDate`) already exists and must not be repeated.

## MAIN9 SURGERY STATUS
- `M9-01 = SOURCE CLOSED / DO NOT REPEAT`
- `M9-02` `_loadDashboardData(fromDate,toDate)` = OPEN / OWNER SOURCE SURGERY REQUIRED.
- `M9-03` `_loadDropdowns(params)` = OPEN / OWNER SOURCE SURGERY REQUIRED.
- `M9-04` `_showCustomerLedgerDetail(customerCode,customerName)` = OPEN / OWNER SOURCE SURGERY REQUIRED.
- `M9-05` `_showItemMovementDetail(itemCode,itemName)` = OPEN / OWNER SOURCE SURGERY REQUIRED.
- `M9-06` `_showRunsheetDetail(runsheetCode)` = OPEN / OWNER SOURCE SURGERY REQUIRED.
- `M9-07` `_showSettlementDetail(settlementCode)` = OPEN / OWNER SOURCE SURGERY REQUIRED.
- `M9-08` `_generateReport(sectionKey,reportId)` = OPEN / OWNER SOURCE SURGERY REQUIRED / FUNCTIONAL COMPLETENESS.
- `M9-09` `_loadDetailedReports(fromDate,toDate,types)` = OPEN / OWNER SOURCE SURGERY REQUIRED.

Exact surgical boundaries and replacement contracts are recorded in:
- `doc/Draft/Reprots/Report101_main9`
- `doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md`
- `doc/Draft/Reprots/Report103_Main9_Forensic_Recheck_20260909.md`

Owner-source protocol remains active: assistant does not edit `Current/PWA/main2/main9.md` directly.

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

The earlier historical note claiming 3 companies is stale relative to this direct Production measurement. Current Production truth is 1 company.

## PRODUCTION DATABASE CONTRACTS — DIRECTLY VERIFIED
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; tenant scope is via `branch_id -> branches.company_id`.
- `get_trial_balance(p_from_date,p_to_date)` exists.
- `get_profit_loss(p_from_date,p_to_date)` exists.
- `get_balance_sheet_data(p_as_of)` exists.
- `get_cash_flow(p_from_date,p_to_date)` exists.
- `receive_purchase_atomic(p_company_id,p_po_code,p_user_email,p_items,p_operation_id uuid)` exists.
- `complete_return_atomic(...)` exists.
- `complete_order_delivery_atomic(...)` exists.
- Physical inventory movement remains owned by `post_stock_movement`.

## INVENTORY CORE — DO NOT REPEAT CLOSED REPAIRS WITHOUT NEW EVIDENCE
The Main9 recheck found no new Production evidence requiring another Inventory Core rewrite. Existing conclusions remain:
- `post_stock_movement` is the authoritative Physical Movement Writer.
- `reserve_stock` / `release_stock_reservation` are reservation writers only.
- Bootstrap stock-row creation is not a Physical Movement engine.
- No new duplicate Physical Stock engine is justified by the present Main9 evidence.

## ASSEMBLY GOVERNANCE
- Canonical editable source: `Current/PWA/main2/main1.md` through `main11.md`.
- Historical source: `Original/PWA/main/*` only.
- Generated target: `Current/PWA/New-main`.
- `.github/workflows/forensic_main_assembly.yml` is already correctly configured around `Current/PWA/main2/**`.
- Main2 assembly remains blocked until owner completes Main9 surgery and validation.

## VALIDATION STATUS
- Governance masters reopened.
- Governing principle reopened.
- Report101 reopened.
- Report102 reopened.
- Current State reconciled against Production.
- Current Main9 reopened from Git.
- Original Main9 opened for historical comparison only.
- Latest Main9 commits inspected.
- Production current snapshot directly verified.
- Main9 source surgery = NOT YET EXECUTED by owner.
- Main9 post-surgery syntax = NOT YET PROVEN.
- Full Main2 assembly = NOT YET RUN.
- Browser/PWA smoke after final assembly = NOT YET RUN.
- Full report-by-report Production UI smoke = NOT YET RUN.
- Gold/Diamond parent closure = NOT YET PROVEN.

## LATEST REPORT
`doc/Draft/Reprots/Report103_Main9_Forensic_Recheck_20260909.md`

## LAST VERIFIED EVENT
- EVENT: `M9-FORENSIC-RECHECK-20260909-0719Z`
- UTC timestamp: `2026-09-09 07:19:19.093393`
- Git Main9 SHA: `a72b970709ce69192bd47824685e99962aaf9fd8`
- Result: current Main9 source still does not contain M9-02..M9-09 replacements; no Main2 assembly was run.
- Next authorized action: owner executes exact Main9 source surgery from Report101/102/103; then reread Main9 EOF-to-EOF, validate syntax/integration, match Main2, and only then assemble.

## SELF-AUDIT
### What I Proved
- Current Production snapshot was directly measured and is 1 company.
- Current Git Main9 SHA is `a72b970...`.
- Current Main9 source still contains older report implementations.
- Historical Original Main9 is not the current Source of Truth.
- Assembly path is already correct.
- Required Finance and operational RPC capabilities exist in Production.
- No new Inventory Core repair is justified by current evidence.

### What I Did Not Prove
- Owner completion of M9-02..M9-09.
- Post-surgery Main9 syntax validity.
- Main2 assembly validity after surgery.
- Browser/PWA runtime after assembly.
- Full Production UI report smoke.
- Gold/Diamond closure.

### What Was Corrected
- Previous continuity optimism was rejected by direct Git inspection.
- Historical company-count conflict was reconciled against current Production.
- Main9 remains OPEN until the actual source file changes are visible in Git and pass validation.

### FINAL CLOSURE
`M9-01 = SOURCE CLOSED / DO NOT REPEAT`
`M9-02..M9-09 = OPEN / OWNER SOURCE SURGERY REQUIRED`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
`GLOBAL INVENTORY CORE = VERIFIED / NO NEW REPAIR JUSTIFIED`
