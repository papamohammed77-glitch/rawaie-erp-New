# RAWAEA ERP — Report98
## Main9 Forensic Surgical Recheck — 2026-09-09

## 0. المبدأ الحاكم — الهدف غير قابل للتخفيض
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا أتعامل معه كإضافات شكلية.**

ويظل هذا الهدف حاكمًا أثناء استكمال Main9 وما بعده: لا يُقبل وجود بطاقات وتقارير اسمية بلا بيانات سلطوية، ولا placeholder يوهم باكتمال قدرة غير موجودة.

## 1. مصادر الحقيقة التي تمت مطابقتها
- Governance: `تقرير مبادئ حاكمة`.
- CTO Directive: `برومبت استكمال مهام`.
- `MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`.
- `MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`.
- `MASTER - RAWAEA ERP.md`.
- `Report97_Main9_Forensic_Surgical_Recheck_20260909.md`.
- `CURRENT_STATE.md`.
- `Current/PWA/main2/main9.md` — المصدر الحالي الفعلي.
- `Original/PWA/main/main9.md` — تاريخي/مرجعي فقط.
- `.github/workflows/forensic_main_assembly.yml`.
- `tools/run_final_main_reconstruction_20260831.py`.
- Production Supabase schema, RPC definitions, constraints, triggers, RLS and current row counts.

## 2. Source Truth Reconciliation
الحالة الحالية تختلف عن Report97 في نقطة مهمة: `Current/PWA/main2/main9.md` الحالي يحتوي بالفعل على M9-01 (`_companyId()` و`_nextDate()`). لذلك لا يجوز إعادة تنفيذ M9-01.

Main9 الحالي blob SHA observed: `5fb184b2a16b0fde25d58dc9962641e2b31505c5`.

Report97 كان يحمل SHA سابقًا `288b...`; لذلك Report97 أصبح مرجعًا تاريخيًا وليس وصفًا حرفيًا للحالة الحالية.

## 3. Parent Source Governance
تم التحقق أن:
- Source of Truth التحريري = `Current/PWA/main2/main1.md` … `main11.md`.
- `Current/PWA/main/*` و`Original/PWA/main/*` تاريخي/مرجعي فقط.
- `Current/PWA/New-main` هدف Assembly مولّد فقط.
- `.github/workflows/forensic_main_assembly.yml` صحيح ويشير إلى `Current/PWA/main2/**`.
- `tools/run_final_main_reconstruction_20260831.py` صحيح ويعرّف `CUR=Current/PWA/main2`.

لا يوجد إصلاح للمسار أو Source of Truth مطلوب في هذه الجلسة.

## 4. Production Snapshot — direct verification 2026-09-09 04:19 UTC
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

تمت مطابقة snapshot الحالي مباشرة من Production، وليس اعتمادًا على Report97.

## 5. Production / Database Contract Verification
تم إثبات الآتي من Production:
- `items.item_code` = UNIQUE عالميًا؛ لذلك لا يجوز فرض Company scope على Item Identity نفسه بلا دليل.
- `customers.id` UUID، و`customer_ledger.customer_id` UUID.
- `orders.runsheet_id` UUID.
- `run_sheet_details.runsheet_id` UUID.
- `daily_settlements.runsheet_id` UUID.
- `chart_of_accounts.id` UUID.
- `treasury.id` UUID.
- `users.id` و`users.company_id` و`users.auth_id` موجودة.
- `inventory_log.company_id` موجود.
- `stock_branches` لا يحمل `company_id` مستقلًا؛ Company scoping للمخزون يكون عبر فرع الشركة.
- `cash_box` يحمل `company_id` و`treasury_id`.
- Finance RPCs موجودة في Production: `get_trial_balance`, `get_profit_loss`, `get_balance_sheet_data`, `get_cash_flow`, `get_pnl_by_cost_center`, `get_budget_vs_actual`.
- Production Finance RPC smoke calls أعادت نتائج فارغة حيث لا توجد حركة مالية، دون أخطاء في تعريفات RPC نفسها.
- `customer_followups` موجود فعليًا وله `company_id`، لكنه حاليًا بلا بيانات.
- HR attendance/payroll authoritative tables لم تثبت في Production؛ لذلك لم تتم صناعة بيانات وهمية.

## 6. Main9 Current Defects Proven
### A. M9-01 — DONE / ALREADY PRESENT
الـhelpers `_companyId()` و`_nextDate()` موجودة فعليًا في المصدر الحالي.
لا تطبق أي تعديل عليها مرة أخرى.

### B. M9-02 — Dashboard
Current function signature: `async function _loadDashboardData(fromDate, toDate) {` في المصدر الحالي حول السطر 67.
المشكلة: queries لـ`orders`, `items`, `stock_branches`, `customers` غير tenant-safe في مواضعها الحالية، ومنطق inactive customers يقارن `customer_code` مع مفاتيح `customer_id`.

### C. M9-03 — Dropdown identity
Current `_loadDropdowns(params)` يبدأ عند السطر 589 تقريبًا؛ anchor الحالي المؤكد يبدأ بالسطر التالي:
`    async function _loadDropdowns(params) {`
ويجب إنهاؤه بالكامل قبل anchor:
`    // ==================== دوال التفاصيل (Drill-Down) ====================`
المشكلة: customer/supplier/account/treasury/driver selectors تستخدم Codes/Emails في حين أن الـdownstream authoritative identities هي UUIDs. item_code استثناء صحيح لأنه Global UNIQUE.

### D. M9-04 — Customer Ledger Drill-Down
Current signature: `async function _showCustomerLedgerDetail(customerCode, customerName) {` عند السطر 614.
يجب أن يصبح:
- parameter = `customerId`;
- query = `customer_ledger.customer_id = customerId`;
- customer identity يجب أن تكون UUID القادمة من M9-03.

### E. M9-05 — Item Movement Drill-Down
Current signature: `async function _showItemMovementDetail(itemCode, itemName) {` عند السطر 631.
المشكلة: `inventory_log` يقرأ بـ`item_code` فقط.
المطلوب: `company_id = _companyId()` + `item_code` + chronology بـ`created_at desc`.

### F. M9-06 — Runsheet Drill-Down
Current signature: `async function _showRunsheetDetail(runsheetCode) {` عند السطر 648.
المشكلة المثبتة: `orders.runsheet_id` UUID لكن الكود الحالي يقارنه بـ`runsheetCode`.
المطلوب:
- `runsheets` company-scoped؛
- `run_sheet_details` by `rs.id`؛
- `orders.eq('runsheet_id', rs.id)`.

### G. M9-07 — Settlement Drill-Down
Current signature: `async function _showSettlementDetail(settlementCode) {` عند السطر 676.
المطلوب: `daily_settlements.eq('company_id', companyId).eq('settlement_code', settlementCode)` مع الحفاظ على runsheet/driver UUIDs.

### H. M9-08 — Comprehensive Report Generator
Current signature: `async function _generateReport(sectionKey, reportId) {` عند السطر 696.
يجب استبدالها كدالة كاملة حتى قبل الـanchor الحرفي:
`    function _printReport() {`

المطلوب داخل النسخة الجديدة:
- Company scope صريح لكل operational query.
- Order detail reads تستخدم `orders!inner(...)` وتفلتر `orders.company_id` و`orders.order_date`.
- Timestamp ranges تستخدم `< _nextDate(toDate)`.
- customer/account/treasury selectors تستعمل UUIDs.
- Balance Sheet يستخدم Production `get_balance_sheet_data` فعليًا.
- Cash Flow يستخدم Production `get_cash_flow` فعليًا.
- HR attendance/salary وTax تبقى capability-gated إذا كان المصدر السلطوي غير موجود، دون fake completion.
- CRM followups يقرأ `customer_followups` الفعلي بدل placeholder.
- لا تُعاد كتابة Business Logic الخاص بالمبيعات/المخازن؛ المطلوب إصلاح القراءة والهوية فقط.

### I. M9-09 — NEWLY DISCOVERED AND REQUIRED
لم يكن موجودًا في Report97 ويجب ألا يُترك خلفنا.
Current signature:
`async function _loadDetailedReports(fromDate, toDate, types) {`
وهو جزء مستقل من `RW_Reports` قبل `return { renderDashboard: ..., renderDetailedReports: ... }`.

المشكلات المثبتة داخله:
- fallback `items` و`customers` غير company-scoped.
- `stock_branches` read غير مقيد بفروع الشركة.
- `orders` غير company-scoped.
- `order_details` read عالمي، وبالتالي لا يلتزم بـauthoritative order context.
- detailed report layer يمكن أن يعيد بيانات خارج tenant رغم أن `_generateReport` تمت معالجتها لاحقًا.

M9-09 لازم يستعمل:
1. `companyId = _companyId()`.
2. Company-scoped customers/orders.
3. Branch IDs الخاصة بالشركة ثم `stock_branches.in('branch_id', branchIds)`.
4. `order_details` عبر `orders!inner(company_id,order_date)` مع tenant/date filters.
5. `items` تُعامل كـGlobal Item Master عند Item Identity، ثم تعرض وفق stock الشركة؛ لا تفرض Company filter على `items` لمجرد الاسم.

## 7. Exact Owner Surgical Instructions
### M9-02
ابحث عن:
`    async function _loadDashboardData(fromDate, toDate) {`
وهو حاليًا عند السطر 67.
احذف الدالة كاملة.
توقف قبل السطر:
`    // ========== التقارير التفصيلية (Checkbox) ==========`
ثم استبدلها بنسخة company-scoped تستخدم:
`var companyId = _companyId();`
مع `orders.eq('company_id', companyId)` و`customers.eq('company_id', companyId)`، ومع stock عبر Company Branch IDs، ومع مقارنة inactive customers باستخدام `customers.id` وليس `customer_code`.

### M9-03
ابحث عن السطر 589:
`    async function _loadDropdowns(params) {`
احذف الدالة كاملة.
توقف قبل السطر الكامل:
`    // ==================== دوال التفاصيل (Drill-Down) ====================`
الاستبدال يجب أن يجعل:
- customer option value = `customers.id`;
- supplier option value = `suppliers.id`;
- item option value = `items.item_code`;
- account option value = `chart_of_accounts.id`;
- treasury option value = `treasury.id`;
- driver option value = `users.id`;
- drivers/customers/suppliers/accounts/treasury كلها `company_id = companyId`؛
- areas مشتقة من customers الخاصة بالشركة.

### M9-04
ابحث عن السطر 614:
`    async function _showCustomerLedgerDetail(customerCode, customerName) {`
احذف الدالة كاملة.
توقف قبل:
`    async function _showItemMovementDetail(itemCode, itemName) {`
واستبدلها بدالة parameter الخاصة بها `customerId` وتستخدم:
`supabase.from('customer_ledger').select('*').eq('customer_id', customerId)`
بعد التحقق من أن `customerId` هو UUID لعميل الشركة الحالية.

### M9-05
ابحث عن السطر 631:
`    async function _showItemMovementDetail(itemCode, itemName) {`
احذف الدالة كاملة.
توقف قبل:
`    async function _showRunsheetDetail(runsheetCode) {`
واستبدلها باستخدام:
`var companyId = _companyId();`
ثم query تحتوي على:
`.eq('company_id', companyId).eq('item_code', itemCode).order('created_at', { ascending: false })`

### M9-06
ابحث عن السطر 648:
`    async function _showRunsheetDetail(runsheetCode) {`
احذف الدالة كاملة.
توقف قبل:
`    async function _showSettlementDetail(settlementCode) {`
واستبدلها بحيث يكون استعلام runsheets:
`.eq('company_id', companyId).eq('runsheet_code', runsheetCode)`
ثم orders:
`.eq('runsheet_id', rs.id)`
وليس `runsheetCode`.

### M9-07
ابحث عن السطر 676:
`    async function _showSettlementDetail(settlementCode) {`
احذف الدالة كاملة.
توقف قبل:
`    // ==================== توليد التقرير (مع Drill-Down) ====================`
واستبدلها بـ`daily_settlements` company-scoped.

### M9-08
ابحث عن السطر 696:
`    async function _generateReport(sectionKey, reportId) {`
احذف الدالة كاملة.
توقف قبل السطر الحرفي الكامل:
`    function _printReport() {`
واستبدلها بالنسخة الكاملة التي تحقق عقد الـreport generator أعلاه، مع المحافظة على جميع report IDs الحالية وعدم حذف أي تقرير موجود.

### M9-09
ابحث عن:
`async function _loadDetailedReports(fromDate, toDate, types) {`
وهو في الجزء الأول من Main9 قبل:
`    return {`
الذي يعيد `renderDashboard` و`renderDetailedReports`.
احذف الدالة كاملة حتى قوس إغلاق الدالة مباشرة قبل:
`    return {`
ثم استبدلها بنسخة Company-scoped. لا تحذف أنواع التقارير الحالية.

## 8. لا تعدل هذه العناصر
- لا تعدل `Current/PWA/main2/main9.md` مباشرة من المساعد؛ هذه Owner Source edit.
- لا تعدل `Original/PWA/main/main9.md`.
- لا تعدل `Current/PWA/main/*`.
- لا تعدل `Current/PWA/New-main` يدويًا.
- لا تعيد M9-01.
- لا تصنع HR/Tax data وهمية.
- لا تفرض company_id على `items.item_code` كـidentity محلية.

## 9. Production Changes in This Checkpoint
لم يتم تنفيذ DDL/بيانات إضافية في Production تخص Main9 خلال هذه الجولة؛ السبب ليس توقفًا، بل أن الاختبارات أثبتت أن Production schema المطلوب للقراءة موجود بالفعل، وأن التغييرات اللازمة الآن تقع في Owner Source `main9.md`.

تمت إعادة مطابقة Production مباشرة قبل تقرير هذه النتيجة.

## 10. Syntax / Assembly Status
- Main9 الحالي هو fragment وليس final assembled HTML.
- لم يتم إعلان `node --check` للـparent assembly PASS من fragment منفرد.
- final syntax/runtime gate ما زال هو full Main2 reconstruction + browser smoke بعد تطبيق M9-02..M9-09.
- لا يجوز تحويل هذا checkpoint إلى Gold/Diamond أو 100% CLOSED قبل ذلك.

## 11. Self-Audit
### Confirmed Facts
- Governance rules were re-opened and matched.
- Current Main9 source was read directly.
- M9-01 is already present.
- Report97 became stale for the exact Main9 SHA/state.
- Main9 has an additional unresolved `_loadDetailedReports` defect (M9-09).
- Production schema supports Finance/CRM reads needed by Main9.
- HR attendance/payroll authoritative sources are absent.
- Assembly path is correct: `Current/PWA/main2/**`.

### Unknown / Not Yet Proved
- Final Main2 syntax after owner surgeries.
- Browser runtime after owner surgeries.
- Full report-by-report functional smoke after owner surgeries.
- Production E2E for reports after source surgery.

### Conflicts Resolved
- Report97 said M9-01 had not been applied; current source proves it is already present. Current source wins.
- Historical `main9` SHA differs from current source SHA; current source wins.

### Failed/Incomplete Attempts
- An earlier purchase receiving idempotency test exposed incorrect retry identity/order. It was not carried into the Main9 source path and must not be mistaken for Main9 runtime proof.
- Local Git clone was unavailable in this environment; repository verification was therefore performed through the connected GitHub repository directly.

### Final Closure
`MAIN9 SOURCE = OPEN / OWNER SURGERY M9-02..M9-09 REQUIRED`
`M9-01 = PRESENT / DO NOT REPEAT`
`PRODUCTION MAIN9-SPECIFIC DDL = NONE REQUIRED AT THIS CHECKPOINT`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
`GLOBAL INVENTORY CORE INTEGRITY = SEPARATE GOVERNED WORKSTREAM`
