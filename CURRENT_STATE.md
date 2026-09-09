# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-09 — Report97 Main9 Forensic Recheck

### Source-of-Truth Governance
- Production Supabase is the execution reference.
- Historical reports are evidence indexes; they do not override current Production.
- No assumption-based patching.
- UNKNOWN != BUG and UNKNOWN != REMOVE.
- One Closure Unit at a time.
- Physical Stock contract remains: `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` remain Reservation-only.
- Editable Parent Source of Truth: `Current/PWA/main2/main1.md ... main11.md`.
- `Current/PWA/main/*` and `Original/PWA/main/*` are historical evidence/reference only.
- `Current/PWA/New-main` is generated target only; never Source of Truth.

### Project Target
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، وليس إضافات شكلية. لا يجوز الوصول إليه عبر تغييرات تخمينية أو شكلية تتجاوز العقود التاريخية وProduction.

## Current Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Branch: `main`
- Current Main8 source SHA observed: `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`.
- Current Main9 source SHA observed: `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03`.
- Latest checkpoint report: `doc/Draft/Reprots/Report97_Main9_Forensic_Surgical_Recheck_20260909.md`.

## Production Snapshot — direct verification 2026-09-09
- companies = 1
- branches = 2
- users = 24
- items = 17
- treasury = 1
- chart_of_accounts = 17
- cash_box = 0
- orders = 0
- runsheets = 0
- stock_branches = 20
- inventory_log = 3

## Main8 — Recheck Result
- Current source was reread from Git.
- M8-11 payment UUID/operation identity surgery is present.
- M8-13 transfer UUID/account control surgery is present.
- No Main8 source edit was made by the assistant in this checkpoint.
- Main8 is a parent fragment; final syntax/runtime certification belongs to the full Main2 assembly gate.

## Main9 — Open Source Surgery
Current Main9 source is `288b642d...` and was read directly from Git.

Confirmed issues:
- multiple report reads lack explicit tenant scoping;
- customer ledger selector uses customer_code while ledger identity is UUID;
- account/treasury selectors have code-vs-UUID mismatch;
- runsheet drill-down uses runsheet code against UUID field `orders.runsheet_id`;
- inventory log drill-down lacks explicit company filter;
- timestamp ranges use inclusive end-date semantics;
- Balance Sheet/Cash Flow are partly placeholder presentation despite existing Production finance cores;
- CRM followups was presented as unavailable despite a real Production table;
- HR attendance/payroll source tables are absent from Production;
- some descriptions promise delivery/return analytics not actually calculated.

Owner-only Main9 surgeries recorded in Report97:
- M9-01 `_companyId()` / `_nextDate()` helper after `_esc()`.
- M9-02 replace `_loadDashboardData(fromDate,toDate)` current line 48.
- M9-03 replace `_loadDropdowns(params)` current line 573.
- M9-04 replace `_showCustomerLedgerDetail(...)` current line 597.
- M9-05 replace `_showItemMovementDetail(...)` current line 615.
- M9-06 replace `_showRunsheetDetail(...)` current line 631.
- M9-07 replace `_showSettlementDetail(...)` current line ~660.
- M9-08 replace `_generateReport(...)` current line ~678 through immediately before `function _printReport() {`.

The assistant does not modify `Current/PWA/main2/main9.md`; these source changes remain Owner-applied by project rule.

## Production Repair — receiving tenant isolation
A real Production RLS defect was repaired.
- Removed permissive public `ALL` policies from `receiving` and `receiving_details`.
- Added authenticated company-scoped SELECT policies.
- RLS remains enabled.
- Service-role Edge/RPC write path remains available.
- Migration: `20260909035915 / 20260909_tenant_lock_receiving_report_reads`.
- Production migration verification confirmed the migration is recorded and RLS remains enabled.

## Production Repair — CRM followups tenant contract
`customer_followups` existed with RLS enabled but no tenant key and no policies. Production currently contains zero rows, so no historical rows required guessed attribution.
- Added `company_id uuid NOT NULL`.
- Added FK to `companies(id)`.
- Added tenant/customer/date index.
- Added authenticated company-scoped SELECT/INSERT/UPDATE/DELETE policies.
- Migration: `20260909040231 / 20260909_crm_followups_tenant_contract`.
- Verified migration is recorded and table currently has zero rows.

## Assembly
`.github/workflows/forensic_main_assembly.yml` remains correct:
- canonical source = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical evidence = `Current/PWA/main/**` and `Original/PWA/main/**`

`FULL MAIN2 ASSEMBLY = BLOCKED` because Main9 owner source surgeries are not yet applied and Main7 still requires its own current verification.

## Gold/Diamond reminder
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، وليس إضافات شكلية. هذه القاعدة تبقى حاكمة لكل الأجزاء القادمة.

## Self-Audit — 2026-09-09 Main9 Checkpoint
### What was proved
- Current Production counts match the Report96 checkpoint.
- Current Main8 contains the previously pending owner surgeries.
- Current Main9 source SHA and content were verified directly from Git.
- Main9 functional gaps were proven against Production schema.
- Existing Production finance reporting RPCs are company-aware.
- `customer_followups` exists, had zero rows, and now has a tenant contract in Production.
- Production receiving tenant-isolation defect was repaired and migration recorded.
- Production CRM followups tenant contract was repaired and migration recorded.

### What was not proved
- Main9 owner surgeries after application.
- Full Main2 syntax/runtime after assembly.
- Browser/E2E after Main9 source changes.
- HR attendance/payroll functional capability because no authoritative Production source tables exist.

### Status
`MAIN8 SOURCE = RECHECKED`
`MAIN9 SOURCE = OPEN / OWNER SURGERY REQUIRED`
`PRODUCTION RECEIVING RLS = CLOSED / DEPLOYED / VERIFIED`
`PRODUCTION CRM FOLLOWUPS TENANT CONTRACT = CLOSED / DEPLOYED / VERIFIED`
`FULL MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`

## Last Verified Event
`EVENT: MAIN9-FORENSIC-SURGICAL-RECHECK-20260909`