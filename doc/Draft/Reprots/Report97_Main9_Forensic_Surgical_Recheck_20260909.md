# RAWAEA ERP — Report97
## Main9 Forensic Surgical Recheck — 2026-09-09

## 0. المبدأ الحاكم والهدف
هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجب التعامل معه كإضافات شكلية.

## 1. مصادر الحقيقة التي تمت مراجعتها
- Governance: `تقرير مبادئ حاكمة`
- CTO Directive: `برومبت استكمال مهام`
- `MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `MASTER - RAWAEA ERP.md`
- `Report96_Main8_Exact_Surgical_Recheck_20260909.md`
- `CURRENT_STATE.md`
- `Current/PWA/main2/main8.md`
- `Current/PWA/main2/main9.md`
- `Original/PWA/main/main9.md`
- `.github/workflows/forensic_main_assembly.yml`
- Production Supabase schema, policies, functions and current row counts.

## 2. Git / Source Reconciliation
- Current Git HEAD at the beginning of this session: `09bd2e86e862981e7f54283cf450610f36fb4d2f`.
- Current `main8.md` source SHA observed: `2131fbf3096d926b2486acb2ab58a4266ddd1bbc`.
- Current `main9.md` source SHA observed: `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03`.
- `CURRENT_STATE.md` was stale at the start: it still recorded Main8 SHA `b3cdbbc79e04f5be9b2e92f9c4e98ce1e7cee64d` and the old HEAD `694245eb...`.
- Assembly workflow source path is correct: `Current/PWA/main2/**`; generated target is `Current/PWA/New-main`.

## 3. Main8 Result
The current Main8 file was re-read from current Git. The previously pending M8-11 payment and M8-13 transfer surgeries are present in the latest source commit.

Important limitation: `main8.md` is a fragment of the parent JS source rather than the final assembled HTML. Therefore a standalone `node --check main8.md` is not a valid final certificate of the deployed parent. The authoritative syntax gate remains the full Main2 assembly/runtime check. No Main8 source edit was made by this session.

## 4. Production Current Snapshot
Direct Production verification returned:
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

The snapshot matches the previous Report96 counts at this checkpoint.

## 5. Production Repair Executed
A real Production tenant-isolation defect was found in `receiving` and `receiving_details`: both tables had permissive `public` policies equivalent to `ALL USING(true) WITH CHECK(true)`.

Repair applied directly to Production:
- removed permissive public policies;
- added authenticated company-scoped SELECT policies;
- preserved service-role based Edge/RPC write path;
- kept RLS enabled.

Migration recorded in Production:
`20260909035915 / 20260909_tenant_lock_receiving_report_reads`

Post-deployment verification confirmed RLS remains enabled on both tables.

## 6. Main9 — What Was Proved
Main9 is historically a simple reporting module; the current file is structurally expanded but still contains functional and identity defects.

Verified defects in current source:
1. Multiple reads are not explicitly company-scoped.
2. Customer report selectors use `customer_code`, while `customer_ledger.customer_id` is UUID.
3. General-ledger and treasury selectors use codes while the target columns are UUIDs.
4. `runsheets` lookup is global and the drill-down queries `orders.runsheet_id` against a runsheet code even though `orders.runsheet_id` is UUID.
5. Inventory movement reads `inventory_log` by item_code without explicit company filter.
6. Detailed item-sales date filtering is incomplete and uses `created_at <= date` rather than a proper exclusive next-day boundary.
7. Finance Balance Sheet, Cash Flow, Tax are still represented partly as placeholders in the Main9 reporting surface even though Production already provides real financial cores/RPCs.
8. CRM followups are represented as unavailable even though Production contains `customer_followups`.
9. HR attendance and salary cannot be honestly implemented from current Production because no corresponding attendance/payroll tables were found.
10. Current Main9 report descriptions overstate delivery/return analytics that are not actually calculated by the present implementation.

## 7. Production Contract Evidence
- `items.item_code` is globally UNIQUE in Production; therefore company scoping must not be invented for item identity where the contract is global.
- `customer_ledger.customer_id` -> `customers.id` UUID.
- `orders.runsheet_id` -> `runsheets.id` UUID.
- `run_sheet_details.runsheet_id` -> `runsheets.id` UUID.
- `daily_settlements.runsheet_id` -> `runsheets.id` UUID.
- Finance RPCs such as `get_trial_balance`, `get_profit_loss`, `get_balance_sheet_data`, `get_cash_flow`, `get_pnl_by_cost_center`, `get_budget_vs_actual` are company-aware through Production context.

## 8. Main9 Owner Surgical Package — NOT APPLIED BY ASSISTANT
Per the project governance, `Current/PWA/main2/main9.md` remains an Owner Source edit. The assistant does not modify Main9 directly.

### Surgery M9-01 — company context helper
Location: current `main9.md` lines 4-6.

Find the exact current line:
`    function _esc(s) { return String(s||'').replace(/[&<>]/g, function(m) { return m==='&'?'&amp;':m==='<'?'&lt;':'&gt;'; }); }`

Add immediately BELOW it:
```javascript
    function _companyId() {
        var id = null;
        if (typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.app) id = RW_STATE.app.companyId || null;
        if (!id && typeof RW_STATE !== 'undefined' && RW_STATE && RW_STATE.user) id = RW_STATE.user.companyId || null;
        if (!id) throw new Error('سياق الشركة غير محدد');
        return id;
    }

    function _nextDate(dateText) {
        var d = new Date(dateText + 'T00:00:00');
        d.setDate(d.getDate() + 1);
        return d.toISOString().slice(0, 10);
    }
```

### Surgery M9-02 — dashboard company isolation
Current function starts at line 48:
`    async function _loadDashboardData(fromDate, toDate) {`

Delete the COMPLETE function and stop immediately before the exact next line:
`    // ========== التقارير التفصيلية (Checkbox) ==========`

Replace it with a company-scoped implementation that reads `orders`, `items`, `stock_branches`, and `customers` in the current tenant. Do not use any global fallback query without `.eq('company_id', companyId)` or an equivalent branch/company relationship.

### Surgery M9-03 — dropdown identity correction
Current `_loadDropdowns` starts at line 573:
`    async function _loadDropdowns(params) {`

Delete the COMPLETE function and stop immediately before:
`    // ==================== دوال التفاصيل (Drill-Down) ====================`

Replace with a version that:
- obtains `companyId = _companyId()`;
- customer option value = `customers.id` UUID;
- supplier option value = `suppliers.id` UUID;
- item option value = `items.item_code` (global item key) or item UUID consistently with the downstream branch;
- account option value = `chart_of_accounts.id` UUID;
- treasury option value = `treasury.id` UUID;
- driver query is `.eq('company_id', companyId)`;
- area options are loaded from company-scoped customers;
- every direct table query carries tenant scope where applicable.

### Surgery M9-04 — customer ledger drill-down
Current function starts at line 597:
`    async function _showCustomerLedgerDetail(customerCode, customerName) {`

Delete it through the line immediately BEFORE this exact next signature:
`    async function _showItemMovementDetail(itemCode, itemName) {`

Replace with a UUID-safe company-scoped query using:
`customer_ledger.customer_id = customerId`
and the existing FK to `customers.id`.

### Surgery M9-05 — item movement drill-down
Current function starts at line 615 (current source location around the shown block):
`    async function _showItemMovementDetail(itemCode, itemName) {`

Delete it through the line immediately BEFORE:
`    async function _showRunsheetDetail(runsheetCode) {`

Replace so `inventory_log` is filtered by `company_id = _companyId()` and sorted by `created_at` when chronology is required, while retaining item-code identity.

### Surgery M9-06 — runsheet drill-down
Current function starts at line 631:
`    async function _showRunsheetDetail(runsheetCode) {`

Delete it through the line immediately BEFORE:
`    async function _showSettlementDetail(settlementCode) {`

Replace so:
- `runsheets` is company-scoped;
- `run_sheet_details` uses `runsheet_id = rs.id`;
- `orders` uses `runsheet_id = rs.id` (NOT `runsheetCode`);
- all reads remain in the current company context.

### Surgery M9-07 — settlement drill-down
Current function starts at line 660-area:
`    async function _showSettlementDetail(settlementCode) {`

Delete it through the line immediately BEFORE:
`    // ==================== توليد التقرير (مع Drill-Down) ====================`

Replace with a company-scoped `daily_settlements` read and include the runsheet/driver identity already present in the row.

### Surgery M9-08 — report generator
Current `_generateReport` starts at line 678-area with the exact line:
`    async function _generateReport(sectionKey, reportId) {`

This is the principal Main9 surgery. Do not patch one arbitrary occurrence. Replace the COMPLETE `_generateReport` function, stopping immediately BEFORE the exact line:
`    function _printReport() {`

Required behavior inside the replacement:
- every `orders` query has `.eq('company_id', companyId)`;
- every `purchase_orders` query has `.eq('company_id', companyId)`;
- every `stock_vouchers` query has `.eq('company_id', companyId)`;
- every `daily_settlements` query has `.eq('company_id', companyId)`;
- every `runsheets` query has `.eq('company_id', companyId)`;
- every `users` query has `.eq('company_id', companyId)`;
- `inventory_log` query has `.eq('company_id', companyId)`;
- `order_details` queries join `orders!inner(company_id,order_date)` and filter tenant/date there;
- date ranges use `< nextDate(toDate)` for timestamp fields;
- customer ledger receives UUID customer id from M9-03;
- account and treasury reports receive UUID selectors from M9-03;
- balance sheet uses the actual Production JSON result rather than a placeholder;
- cash flow displays actual Production RPC data rather than a confirmation-only message;
- tax/attendance/salary remain explicitly capability-gated if the required Production source tables do not exist; do not fabricate data.

## 9. Gold/Diamond Interpretation for Main9
Main9 should not be accepted merely because section cards and report names exist. Reports must produce authoritative, tenant-safe, drill-down-capable data. The current Production already provides a sufficiently rich foundation for Finance, Inventory, Sales, Logistics and CRM reporting. HR attendance/payroll are blocked by missing Production data structures and therefore must be implemented as a proper future functional capability, not as a fake “completed” screen.

## 10. Self-Audit
### Confirmed
- Current Production snapshot matches Report96 at this checkpoint.
- Main8 latest owner surgeries are present in current Git.
- Main2 assembly source path is correct.
- Main9 current SHA is `288b642d...`.
- Production receiving RLS defect was fixed and migration recorded.
- Main9 has real functional gaps, not merely cosmetic gaps.

### Not yet proved
- Main8 final assembled syntax/runtime.
- Main9 owner surgery has been applied.
- Main9 browser/E2E behavior after owner surgery.
- Full Main2 assembly after Main7/Main8/Main9 source state is reconciled.
- HR attendance/payroll capability because its Production data model is absent.

### Closure Status
`GLOBAL INVENTORY CORE INTEGRITY` remains governed by the separate Inventory sweep.
`MAIN9 SOURCE = OPEN / OWNER SURGERY REQUIRED`.
`MAIN2 ASSEMBLY = NOT AUTHORIZED FROM THIS CHECKPOINT` until owner applies the exact Main9 source surgeries and the full reconstruction gate is run.
