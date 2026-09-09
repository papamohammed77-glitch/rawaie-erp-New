# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report98 Main9 Forensic Surgical Recheck

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
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.

## Current Main9 Source
- File: `Current/PWA/main2/main9.md`
- Current blob SHA observed: `5fb184b2a16b0fde25d58dc9962641e2b31505c5`
- M9-01 (`_companyId()` + `_nextDate()`) is already present. DO NOT repeat.
- Report97 is stale for exact current Main9 state; current source wins.

## Main9 Open Surgery Units
- M9-02 `_loadDashboardData(fromDate,toDate)` — current line 67.
- M9-03 `_loadDropdowns(params)` — current line 589.
- M9-04 `_showCustomerLedgerDetail(customerCode, customerName)` — current line 614.
- M9-05 `_showItemMovementDetail(itemCode,itemName)` — current line 631.
- M9-06 `_showRunsheetDetail(runsheetCode)` — current line 648.
- M9-07 `_showSettlementDetail(settlementCode)` — current line 676.
- M9-08 `_generateReport(sectionKey,reportId)` — current line 696.
- M9-09 `_loadDetailedReports(fromDate,toDate,types)` — additional defect discovered during Report98 forensic recheck.

The exact delete/replacement instructions are recorded in:
`doc/Draft/Reprots/Report98_Main9_Forensic_Surgical_Recheck_20260909.md`

The assistant must NOT edit `Current/PWA/main2/main9.md`; these are Owner Source edits.

## Production Snapshot — direct verification 2026-09-09
- companies = 1
- branches = 2
- users = 24
- items = 17
- treasury = 1
- chart_of_accounts = 17
- orders = 0
- runsheets = 0
- stock_branches = 20
- inventory_log = 3
- receiving = 0
- receiving_details = 0
- customer_followups = 0

## Production Contract Evidence
- `items.item_code` is globally UNIQUE.
- `customers.id` / `customer_ledger.customer_id` are UUIDs.
- `runsheets.id` / `orders.runsheet_id` / `run_sheet_details.runsheet_id` / `daily_settlements.runsheet_id` are UUID relationships.
- `chart_of_accounts.id` / `treasury.id` are UUIDs.
- `cash_box` has `company_id` and `treasury_id`.
- Finance RPCs available: `get_trial_balance`, `get_profit_loss`, `get_balance_sheet_data`, `get_cash_flow`, `get_pnl_by_cost_center`, `get_budget_vs_actual`.
- `customer_followups` exists with `company_id`; current rows = 0.
- HR attendance/payroll authoritative Production sources are not proven and must not be fabricated.

## Production Repairs Already Closed
- Receiving tenant isolation: migration `20260909035915 / 20260909_tenant_lock_receiving_report_reads`; RLS remains enabled.
- CRM followups tenant contract: migration `20260909040231 / 20260909_crm_followups_tenant_contract`; current rows = 0.

## Assembly
`.github/workflows/forensic_main_assembly.yml` remains correct:
- canonical source = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical evidence = `Current/PWA/main/**`, `Original/PWA/main/**`

## Status
`M9-01 = PRESENT / DO NOT REPEAT`
`M9-02..M9-09 = OPEN / OWNER SURGERY REQUIRED`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
`GLOBAL INVENTORY CORE INTEGRITY = SEPARATE GOVERNED WORKSTREAM`

## Latest Report
`doc/Draft/Reprots/Report98_Main9_Forensic_Surgical_Recheck_20260909.md`

## Self-Audit
### Proved
- Governing documents were reopened and reconciled.
- Current Main9 source was reread directly.
- M9-01 is present in the current source.
- Production was resnapshotted immediately before reporting.
- Assembly path is correct.
- M9-09 was discovered and added so the detailed reporting path is not left as a parallel unscoped path.
- Finance/CRM Production sources were verified sufficiently to avoid fake completion.

### Not Yet Proved
- Owner application of M9-02..M9-09.
- Final Main2 assembly syntax/runtime.
- Browser/E2E after Main9 source surgery.
- Gold/Diamond closure.
