# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report102 Main9 Forensic Recheck

### Governing Target — NON-NEGOTIABLE
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

الحوكمة التنفيذية:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

### Source-of-Truth Governance
- Production Supabase is the execution reference.
- Historical reports are evidence, not authority over current Production.
- Unknown != bug; Unknown != remove.
- One Closure Unit at a time.
- Parent editable source = `Current/PWA/main2/main1.md ... main11.md`.
- `Current/PWA/main/*` = historical evidence only.
- `Current/PWA/New-main` = generated target only.
- `.github/workflows/forensic_main_assembly.yml` currently points to `Current/PWA/main2/**`; this path is correct and was not changed.
- Physical Stock contract = `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` = Reservation-only.

### Current Main9
- File: `Current/PWA/main2/main9.md`
- Current Git blob SHA observed: `a72b970709ce69192bd47824685e99962aaf9fd8`
- The previous CURRENT_STATE checkpoint SHA was stale versus the live Git file; this drift was identified and explicitly documented.
- M9-01 (`_companyId` + `_nextDate`) exists and must not be repeated.
- The assistant did NOT edit Main9 source. Owner-source surgery remains required.
- Main9 currently still contains an older `_loadDetailedReports` implementation plus incomplete/unsafe report branches in `RW_Reports_Comprehensive`.

### Main9 Surgery Units — FULL BATCH TO BE EXECUTED BY OWNER
- M9-02 `_loadDashboardData(fromDate,toDate)` — approx. current line ~67 — OPEN.
- M9-03 `_loadDropdowns(params)` — approx. current line ~589 — OPEN.
- M9-04 `_showCustomerLedgerDetail(customerCode, customerName)` — approx. current line ~614 — OPEN.
- M9-05 `_showItemMovementDetail(itemCode,itemName)` — approx. current line ~631 — OPEN.
- M9-06 `_showRunsheetDetail(runsheetCode)` — approx. current line ~648 — OPEN.
- M9-07 `_showSettlementDetail(settlementCode)` — approx. current line ~676 — OPEN.
- M9-08 `_generateReport(sectionKey,reportId)` — approx. current line ~696 — OPEN; functional completeness scope.
- M9-09 `_loadDetailedReports(fromDate,toDate,types)` — OPEN.

Exact surgery boundaries and replacement contracts are recorded in:
`doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md`

Do not use old line numbers without re-locating the exact start heading and closing marker in the current file.

### Production Snapshot — DIRECTLY VERIFIED
Observed during `2026-09-09 05:46–05:48 UTC`:
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

Stock integrity at checkpoint:
- negative stock = 0
- over allocated = 0
- available_qty mismatch = 0
- bad inventory-log source company = 0
- bad inventory-log target company = 0
- bad inventory-log item identity = 0
- bad stock-voucher branch/company context = 0
- failed core operations = 0
- processing core operations = 0

### Production Writer Discovery
Direct PostgreSQL inspection established:
- `post_stock_movement` is the authoritative Physical Movement Writer.
- `inventory_log` direct insertion is confined to `post_stock_movement`.
- `reserve_stock` and `release_stock_reservation` only mutate reservation state.
- `create_vehicle_atomic` / `setup_van_stock` only bootstrap stock rows with zero quantities; they are not movement engines.
- No independent Physical Stock Movement Writer outside `post_stock_movement` was found in the current database definition scan.

### Production RPC Integrity
Verified in current Production:
- `receive_purchase_atomic(p_company_id,p_po_code,p_user_email,p_items,p_operation_id uuid)` exists.
- `complete_return_atomic(...)` exists and delegates good-return Physical Movement to `post_stock_movement`.
- `complete_order_delivery_atomic(...)` updates fulfillment state only; Physical Stock was posted at Loading.
- Manual Voucher wrappers delegate to the current canonical core implementations.
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no `company_id`; Company identity is obtained through `branch_id -> branches.company_id`.
- Audit trigger `trg_audit_stock_vouchers` calls `fn_audit_trigger()`.

### Production DB Repair Applied This Cycle
Migration applied:
`inventory_core_zero_debt_governed_fixes_20260909`

This reasserted the governed Manual Voucher wrapper boundary without creating a second Physical Stock engine.

### Production / Git Edge Drift
Current Git contains newer Current Edge Function implementations for at least:
- `receive-purchase`
- `complete-return`
- `complete-order-delivery`
- `create-stock-voucher`

Production metadata had older deployed versions during this check. Therefore:
`Git Current != Production Runtime PASS`

This was recorded rather than falsely claiming deployment closure. A deployment result must be independently observed before marking those Edge runtimes synchronized.

### Main9 Functional Gaps Still Open
The forensic reread still proves functional work is required, not just tenancy filters:
- Finance Balance Sheet must render authoritative RPC data, not a placeholder.
- Finance Cash Flow must render authoritative RPC data, not a placeholder.
- Tax report must be capability-gated unless an authoritative tax source is proven.
- CRM Followups must query the real `customer_followups` source if capability is present.
- HR Attendance / Salary must remain capability-gated until authoritative Production sources are proven.
- Returns report must use authoritative `inventory_log` movements rather than inventing a Return Voucher source.
- Multiple report paths still require Company-scoped operational reads and correct UUID relationship handling.

### Validation Status
- Governance sources reopened.
- Report101 read from start to EOF.
- Current Main9 reopened from GitHub.
- Production re-snapshotted directly before closure reporting.
- DB writer discovery completed.
- Current stock invariants pass.
- Full Main9 syntax validation after Owner surgery is NOT yet proven.
- Full Main2 assembly is NOT yet run.
- Browser/PWA smoke is NOT yet run after final assembly.
- Full report-by-report Production UI smoke is NOT yet run.

### Latest Report
`doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md`

### Status
`M9-01 = SOURCE CLOSED / DO NOT REPEAT`
`M9-02 = OPEN / OWNER SURGERY REQUIRED`
`M9-03 = OPEN / OWNER SURGERY REQUIRED`
`M9-04 = OPEN / OWNER SURGERY REQUIRED`
`M9-05 = OPEN / OWNER SURGERY REQUIRED`
`M9-06 = OPEN / OWNER SURGERY REQUIRED`
`M9-07 = OPEN / OWNER SURGERY REQUIRED`
`M9-08 = OPEN / OWNER SURGERY REQUIRED — FUNCTIONAL SCOPE`
`M9-09 = OPEN / OWNER SURGERY REQUIRED`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
`GLOBAL INVENTORY CORE INTEGRITY = DB WRITER CONTRACT CLOSED / RUNTIME EDGE SYNC NOT CLOSED`

### Self-Audit
#### Proved
- Current Production was directly inspected.
- Main9 current Git source differs from older checkpoint and the drift was not ignored.
- Physical stock movement has one authoritative DB writer.
- Current stock and inventory-log invariants pass.
- Current Production contains the expected Return/Delivery/Purchase RPCs.
- Main2 remains the editable parent source.
- Report102 was added without deleting prior reports.

#### Not Yet Proved
- Owner completion of M9-02..M9-09.
- Parent Main2 assembly after Main9 surgery.
- Parent syntax/runtime/browser smoke.
- Full Production UI report smoke.
- Gold/Diamond closure.
- Production Edge deployment synchronization for the newer Current Git function versions.
