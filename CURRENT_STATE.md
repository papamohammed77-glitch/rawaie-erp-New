# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report100 Main9 Forensic Final Checkpoint

### Latest Verified Event
- Event: Main9 complete forensic re-read + source/Original reconciliation + Production resnapshot.
- Latest Main9 direct source commit: `1d534169f7f758851207cb6f0879bc59543a9339`
- Latest Main9 direct modification: `2026-09-09 04:14:28 UTC`
- Main9 current blob SHA: `5fb184b2a16b0fde25d58dc9962641e2b31505c5`
- New reports created this session: `Report99_Main9_Forensic_Surgical_Recheck_20260909.md`, `Report100_Main9_Forensic_Final_Checkpoint_20260909.md`

### Source-of-Truth Governance
- Production Supabase is the execution reference.
- Historical reports are evidence indexes; they do not override current Production.
- No assumption-based patching.
- UNKNOWN != BUG and UNKNOWN != REMOVE.
- One Closure Unit at a time.
- Physical Stock contract: `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` are Reservation-only.
- Editable Parent Source of Truth: `Current/PWA/main2/main1.md ... main11.md`.
- `Current/PWA/main/*` and `Original/PWA/main/*` are historical evidence/reference only.
- `Current/PWA/New-main` is generated target only.

### Project Target — NON-NEGOTIABLE
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

### Current Main9 Source
- File: `Current/PWA/main2/main9.md`
- Current blob SHA observed: `5fb184b2a16b0fde25d58dc9962641e2b31505c5`
- M9-01 (`_companyId()` + `_nextDate()`) is already present. DO NOT repeat.
- Main9 was reread completely from the current Git blob.
- Original Main9 was checked as historical evidence only.
- The assistant did NOT edit Main9; all M9 source edits remain Owner Source operations.

### Main9 Surgery Units
- M9-02 `_loadDashboardData(fromDate,toDate)` — current line ~67 — OPEN / OWNER SURGERY REQUIRED.
- M9-03 `_loadDropdowns(params)` — current line ~589 — OPEN / OWNER SURGERY REQUIRED.
- M9-04 `_showCustomerLedgerDetail(customerCode, customerName)` — current line ~614 — OPEN / OWNER SURGERY REQUIRED.
- M9-05 `_showItemMovementDetail(itemCode,itemName)` — current line ~631 — OPEN / OWNER SURGERY REQUIRED.
- M9-06 `_showRunsheetDetail(runsheetCode)` — current line ~648 — OPEN / OWNER SURGERY REQUIRED.
- M9-07 `_showSettlementDetail(settlementCode)` — current line ~676 — OPEN / OWNER SURGERY REQUIRED.
- M9-08 `_generateReport(sectionKey,reportId)` — current line ~696 — OPEN / OWNER SURGERY REQUIRED; functional scope expanded beyond tenant filtering.
- M9-09 `_loadDetailedReports(fromDate,toDate,types)` — OPEN / OWNER SURGERY REQUIRED.

### FIRST NEXT AUTHORIZED OWNER ACTION
Do only M9-02 now.

Find exactly:
`    async function _loadDashboardData(fromDate, toDate) {`

Delete that entire function up to the `}` that closes it immediately before:
`    // ========== التقارير التفصيلية (Checkbox) ==========`

Replace it with the complete replacement recorded in:
`doc/Draft/Reprots/Report100_Main9_Forensic_Final_Checkpoint_20260909.md`

Do not edit M9-03..M9-09 until M9-02 is reverified.

### Main9 Functional Findings — Gold/Diamond
The complete re-read proved that `RW_Reports_Comprehensive` still contains functional placeholders or incomplete result rendering for:
- Balance Sheet
- Cash Flow
- Tax
- CRM Followups
- HR Attendance
- HR Salary

It also contains unscoped operational reads in multiple report branches and incorrect/currently unsafe identity/date handling. These must be addressed in M9-08/M9-09 with authoritative Production data and capability gating where the authoritative source does not exist.

### Production Snapshot — final direct verification
Timestamp: `2026-09-09T04:39:35.141939+00`
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
- stock_branches = 20
- inventory_log = 3
- receiving = 0
- receiving_details = 0
- customer_followups = 0

### Production Contract Evidence
- `items.item_code` is globally UNIQUE.
- `stock_branches` has no independent `company_id`; company scoping is through `branch_id -> branches.company_id`.
- `customers.id` / `customer_ledger.customer_id` are UUIDs.
- `runsheets.id` / `orders.runsheet_id` / `run_sheet_details.runsheet_id` / `daily_settlements.runsheet_id` are UUID relationships.
- `chart_of_accounts.id` / `treasury.id` are UUIDs.
- `cash_box` has `company_id` and `treasury_id`.
- Finance RPCs available: `get_trial_balance`, `get_profit_loss`, `get_balance_sheet_data`, `get_cash_flow`, `get_pnl_by_cost_center`, `get_budget_vs_actual`.
- `customer_followups` exists with `company_id`; current rows = 0.
- HR attendance/payroll authoritative Production sources are not proven and must not be fabricated.

### Production Repairs Already Closed
- Receiving tenant isolation: migration `20260909035915 / 20260909_tenant_lock_receiving_report_reads`.
- CRM followups tenant contract: migration `20260909040231 / 20260909_crm_followups_tenant_contract`.

### Assembly
`.github/workflows/forensic_main_assembly.yml` remains correct:
- canonical source = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical evidence = `Current/PWA/main/**`, `Original/PWA/main/**`
- reconstruction script uses `Current/PWA/main2`

Formal final syntax/runtime gate remains full Main2 assembly + Node + Browser smoke; Main9 fragment alone cannot be declared parent/runtime closed.

### Syntax / Validation Status
- Complete Main9 source was reread.
- Static IIFE/function/return/export boundaries are internally consistent by source inspection.
- Local direct `node --check` could not be executed because this execution environment could not reach raw.githubusercontent.com to materialize the file; this is recorded as an environment limitation, not a PASS.
- No Gold/Diamond or 100% closure is claimed.

### Status
`M9-01 = SOURCE CLOSED / DO NOT REPEAT`
`M9-02 = OPEN / OWNER SURGERY REQUIRED`
`M9-03 = OPEN / OWNER SURGERY REQUIRED`
`M9-04 = OPEN / OWNER SURGERY REQUIRED`
`M9-05 = OPEN / OWNER SURGERY REQUIRED`
`M9-06 = OPEN / OWNER SURGERY REQUIRED`
`M9-07 = OPEN / OWNER SURGERY REQUIRED`
`M9-08 = OPEN / OWNER SURGERY REQUIRED — FUNCTIONAL SCOPE EXPANDED`
`M9-09 = OPEN / OWNER SURGERY REQUIRED`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
`GLOBAL INVENTORY CORE INTEGRITY = SEPARATE GOVERNED WORKSTREAM`

### Latest Report
`doc/Draft/Reprots/Report100_Main9_Forensic_Final_Checkpoint_20260909.md`

### Self-Audit
#### Proved
- Governance sources were reopened.
- Current Main9 source was read completely.
- Original Main9 was compared as historical evidence only.
- Latest Main9 direct commit was identified.
- Production was resnapshotted directly before this checkpoint.
- Assembly path is correct and points to `Current/PWA/main2/**`.
- M9-01 is present and not repeated.
- M9-02..M9-09 are still owner-source surgeries.
- Functional completeness gaps beyond tenant scoping were discovered and documented.

#### Not Yet Proved
- Owner application of M9-02.
- Post-surgery Main9 syntax.
- Full Main2 assembly syntax.
- Browser/E2E runtime after source surgery.
- Full report-by-report Production smoke.
- Gold/Diamond closure.
