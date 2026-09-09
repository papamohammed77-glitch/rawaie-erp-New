# RAWAEA ERP — Report103
## إعادة الفحص الجنائي الأخير لـ Main9 — 2026-09-09

## 0. المبدأ الحاكم — مؤكد مرة أخرى

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond، ولا يجوز التعامل معه كإضافات شكلية.**

التسلسل الحاكم: UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH/CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

## 1. Current Truth

### Git
- Current editable source: `Current/PWA/main2/main9.md`
- Current blob SHA: `a72b970709ce69192bd47824685e99962aaf9fd8`
- آخر commits مباشرة على Main9 في 2026-09-09: `0748e00b...` ثم `ef201a62...`.
- الملف الحالي **لم تُطبّق عليه** جراحات M9-02..M9-09 رغم وجودها في التقارير السابقة؛ ما زالت النسخ القديمة موجودة فعليًا.

### Production snapshot — direct verification
Timestamp UTC: `2026-09-09 07:19:19.093393+00`
- companies 1
- branches 2
- users 24
- items 17
- customers 3
- suppliers 1
- treasury 1
- chart_of_accounts 17
- orders 0
- runsheets 0
- purchase_orders 0
- stock_vouchers 0
- stock_branches 20
- inventory_log 3
- receiving 0
- receiving_details 0
- journal_entries 2

Company current: `00000000-0000-0000-0000-000000000001` / الروائع.

### Database contracts directly verified
- `items.item_code` = globally UNIQUE.
- `stock_branches` لا يحتوي `company_id`; Company scope يمر عبر `branch_id -> branches.company_id`.
- Finance authoritative RPCs الموجودة: `get_trial_balance`, `get_profit_loss`, `get_balance_sheet_data`, `get_cash_flow`.
- `complete_return_atomic`, `complete_order_delivery_atomic`, `receive_purchase_atomic(..., p_operation_id uuid)` موجودة في Production.
- Physical stock contract remains `post_stock_movement -> stock_branches + inventory_log`.
- No change required now to the assembly source path: `.github/workflows/forensic_main_assembly.yml` already uses `Current/PWA/main2/**` and `Current/PWA/New-main` as generated output.

## 2. Historical findings that MUST NOT be repeated

`Original/PWA/main/main9.md` is historical reference only. It differs materially from Current Main9. Do not copy it wholesale.

`CURRENT_STATE.md`, Report101 and Report102 are evidence, not current truth. They were reconciled against Git and Production. In particular, the current Production company count is **1**, not 3.

## 3. Main9 actual current defects

The current file still contains:

1. Old `_loadDashboardData` with weaker inventory aggregation and global Item fallback.
2. Old `_loadDetailedReports` using `RW_STATE` as a data source and several unscoped reads.
3. `_loadDropdowns` without a reset guard; reopening a report can duplicate options.
4. `_showCustomerLedgerDetail` without current-company verification.
5. `_showItemMovementDetail` without company-scoped identity verification.
6. `_showRunsheetDetail` with unscoped runsheet lookup and a current bug where Orders were historically queried using `runsheetCode` rather than the UUID `rs.id`.
7. `_showSettlementDetail` without company scope.
8. `_generateReport` with multiple unscoped reads, placeholder Finance outputs, placeholder CRM Followups, placeholder HR Attendance/Salary, and an incorrect Returns source assumption using `stock_vouchers type=Return`.

These are source defects in Main9. They are **not** proof of a Production defect in the underlying inventory engine.

## 4. Owner-source surgery — exact operations

The assistant must NOT edit `Current/PWA/main2/main9.md` directly. The owner must execute these source edits.

### M9-01 — CLOSED / DO NOT REPEAT
Keep exactly:
- `function _companyId()`
- `function _nextDate(dateText)`

### M9-02 — OPEN
Current position: approximately line 67 in the present Git file.

Search exactly:
`    async function _loadDashboardData(fromDate, toDate) {`

Delete the complete function through the closing `}` immediately before:
`    // ========== التقارير التفصيلية (Checkbox) ==========`

Replace with the **full M9-02 replacement block recorded in Report101_main9**. Do not copy a partial snippet.

### M9-03 — OPEN
Current position: approximately line 589–650 depending on the exact editor line count.

Search exactly:
`    async function _loadDropdowns(params) {`

Delete the complete function through the closing `}` immediately before:
`    // ==================== دوال التفاصيل (Drill-Down) ====================`

Replace with the **full M9-03 replacement block recorded in Report101_main9**.

Critical expected behavior: reset each select before appending; company-scope Customer/Supplier/Treasury/Account/Driver/Area; Item uses globally unique `item_code`.

### M9-04 — OPEN
Current position: approximately line 614–800 depending on current editor numbering.

Search exactly:
`    async function _showCustomerLedgerDetail(customerCode, customerName) {`

Delete through the closing `}` immediately before:
`    async function _showItemMovementDetail(itemCode, itemName) {`

Replace with the **full M9-04 replacement block recorded in Report101_main9**.

### M9-05 — OPEN
Search exactly:
`    async function _showItemMovementDetail(itemCode, itemName) {`

Delete through the closing `}` immediately before:
`    async function _showRunsheetDetail(runsheetCode) {`

Replace with the **full M9-05 replacement block recorded in Report101_main9**.

### M9-06 — OPEN
Search exactly:
`    async function _showRunsheetDetail(runsheetCode) {`

Delete through the closing `}` immediately before:
`    async function _showSettlementDetail(settlementCode) {`

Replace with the **full M9-06 replacement block recorded in Report101_main9**.

### M9-07 — OPEN
Search exactly:
`    async function _showSettlementDetail(settlementCode) {`

Delete through the closing `}` immediately before:
`    // ==================== توليد التقرير (مع Drill-Down) ====================`

Replace with the **full M9-07 replacement block recorded in Report101_main9**.

### M9-08 — OPEN / FUNCTIONAL COMPLETENESS
Search exactly:
`    async function _generateReport(sectionKey, reportId) {`

Delete through the closing `}` immediately before:
`    function _printReport() {`

Replace with the **full M9-08 replacement block recorded in Report101_main9**.

The replacement must eliminate the current report-level global reads and the fake placeholders while preserving the existing report catalog. Finance must consume the authoritative Production RPCs. Tax and HR Attendance/Salary must be capability-gated unless an authoritative Production source is proven. Returns must be sourced from authoritative movement data, not an assumed Return voucher.

### M9-09 — OPEN
Search exactly:
`async function _loadDetailedReports(fromDate, toDate, types) {`

Delete the complete function through the closing `}` immediately before the `return {` of the surrounding `RW_Reports` module. **Do not delete the `return {` itself.**

Replace with the **full M9-09 replacement block recorded in Report101_main9**.

Keep this caller unchanged:
`_loadDetailedReports(fromDef, toDef, ['sales-summary', 'customers-debt', 'rec-purchase']);`

## 5. Important execution rule

Do not use old line numbers as delete boundaries. The exact heading + exact next marker are the authoritative selection boundaries. This prevents the previous failure mode where only part of a line/function was deleted.

Do not modify `main1..main11` through the assistant. Do not touch `Original/PWA/main/*` or `Current/PWA/New-main` as editable source.

## 6. Validation gate after owner surgery

Only after M9-02..M9-09 are actually present in Git:

1. Re-read `Current/PWA/main2/main9.md` from first character to EOF.
2. Verify each M9 function appears exactly once.
3. Verify each obsolete implementation is gone.
4. Verify braces/quotes/comments and module boundary.
5. Run syntax validation through the parent assembly gate; Main9 source alone is not sufficient runtime proof.
6. Match all Main2 fragments before any Assembly declaration.
7. Run governed assembly into `Current/PWA/New-main`.
8. Run `node --check` on the assembled runtime.
9. Run browser/PWA smoke.
10. Only then evaluate Production UI report smoke.

## 7. Production / Inventory conclusion for this session

No new Production inventory repair was justified by the Main9 recheck. The current Production database continues to show one authoritative Physical Stock Writer contract, and the current stock snapshot has no basis for repeating prior inventory repairs.

The actual open blocker is **Main9 source surgery + validation + later parent assembly**, not another inventory-engine rewrite.

## 8. SELF-AUDIT

### What I Proved
- Current Main9 Git SHA is `a72b970...`.
- Main9 still contains old implementations; prior source patches were not actually present.
- Current Production was re-snapshotted directly at `2026-09-09 07:19:19.093393+00`.
- Current Production has one company, 2 branches, 24 users, 17 items, 20 stock rows and 3 inventory-log rows.
- Main2 remains the editable parent source.
- Assembly path is already correct.
- Finance authoritative RPCs and required operational RPCs exist in Production.

### What I Did Not Prove
- Owner completion of M9-02..M9-09.
- Main9 post-surgery full-source syntax gate.
- Full Main2 assembly after surgery.
- Browser/PWA runtime after final assembly.
- Full Production UI smoke for every report.
- Gold/Diamond closure.

### Final Closure Status
- `M9-01 = SOURCE CLOSED / DO NOT REPEAT`
- `M9-02..M9-09 = OPEN / OWNER SOURCE SURGERY REQUIRED`
- `MAIN2 ASSEMBLY = BLOCKED UNTIL MAIN9 SOURCE SURGERY + VALIDATION`
- `PARENT GOLD/DIAMOND = NOT CLOSED`
- `GLOBAL INVENTORY CORE = DB WRITER CONTRACT VERIFIED; NO NEW REPAIR JUSTIFIED`
