# RAWAEA ERP — Report104
# إعادة الفحص الجنائي وإعادة اعتماد حزمة جراحة Main9 — 2026-09-09

## 0. المبدأ الحاكم — مؤكد مرة أخرى

**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.**

التسلسل الحاكم:

UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH CONTROL FLOW → IDENTIFY ACTUAL GAP → SURGICAL FIX → TEST → PRODUCTION VERIFY.

---

## 1. مصادر الحقيقة التي أعيد فتحها

تمت إعادة فتح ومراجعة:

- `CURRENT_STATE.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- تقرير المبادئ الحاكمة.
- `doc/Draft/Reprots/Report101_main9`
- `doc/Draft/Reprots/Report102_Main9_Forensic_Recheck_20260909.md`
- `doc/Draft/Reprots/Report103_Main9_Forensic_Recheck_20260909.md`
- `Current/PWA/main2/main9.md` من Git الحالي.
- `Original/PWA/main/main9.md` للتاريخ فقط.
- `.github/workflows/forensic_main_assembly.yml`.
- تعريفات PostgreSQL الحالية المرتبطة بالتقارير والمخزون.

---

## 2. Current Truth — Main9

المصدر التحريري الحالي:

`Current/PWA/main2/main9.md`

Current Git blob SHA:

`a72b970709ce69192bd47824685e99962aaf9fd8`

الملف الحالي ما زال يحتوي فعليًا على النسخ القديمة من:

`M9-02 … M9-09`

و`M9-01` فقط هو المغلق مسبقًا.

لا يجوز إعادة تطبيق M9-01.

---

## 3. Production Truth — مباشرة

آخر Snapshot مباشر معتمد في الحالة الحالية:

UTC `2026-09-09 07:19:19.093393`

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

Company:

`00000000-0000-0000-0000-000000000001`

`الروائع`

والحالة الحالية لا تبرر إعادة فتح Inventory Core؛ عقد Physical Stock ما زال:

`post_stock_movement → stock_branches + inventory_log`

و`reserve_stock / release_stock_reservation` Reservation-only.

---

## 4. Production contracts المؤكدة ذات الصلة

- `items.item_code` = `UNIQUE` عالميًا.
- `stock_branches` لا يحتوي `company_id`; Company scope يمر عبر `branch_id -> branches.company_id`.
- `customer_followups.company_id` موجود.
- `daily_settlements.company_id` موجود.
- `journal_entries.company_id` موجود.
- `cash_box.company_id` موجود.
- `runsheets.company_id` موجود.
- `users.company_id` موجود.
- Finance RPCs الموجودة فعليًا:
  - `get_trial_balance(p_from_date,p_to_date)`
  - `get_profit_loss(p_from_date,p_to_date)`
  - `get_balance_sheet_data(p_as_of)`
  - `get_cash_flow(p_from_date,p_to_date)`
  - `get_pnl_by_cost_center(p_from_date,p_to_date)`
  - `get_budget_vs_actual(p_year,p_month,p_cost_center_id)`
- `complete_return_atomic(...)` موجود.
- `complete_order_delivery_atomic(...)` موجود.

تعريف `post_stock_movement` الحالي يثبت أن أنواع الحركة المقبولة تشمل:

`PurchaseIn, TransferOut, TransferIn, POSSale, VanSale, DirectSale, SalesReturn, DirectReturn, SupplierReturn, InventoryIncrease, InventoryDecrease, Loading, Unloading`

ولا يحتوي النوع `Return` منفردًا.

---

# 5. اكتشافات جديدة لم تكن مغلقة بشكل كافٍ في Report103

## 5.1 لا يجوز نسخ Report101 حرفيًا

Report101 هو المرجع التشغيلي للحزمة الجراحية، لكنه نفسه كان يحتاج إعادة تدقيق قبل التنفيذ.

تم إثبات أن بعض بدائله كانت ما تزال تستخدم `RW_STATE` كـfallback لمعلومات يجب أن تكون Current Production Truth داخل التقرير.

القاعدة الجديدة:

**في التقارير التشغيلية الحالية، `RW_STATE` ليس Source of Truth.**

يمكن استخدامه للـpresentation state فقط، وليس لبناء نتائج التقرير إذا كان المصدر السلطوي متاحًا في Production.

---

## 5.2 M9-08 Returns

بديل Report101 كان يشمل movement type باسم:

`Return`

لكن `post_stock_movement` الحالي لا يدعم هذا النوع.

التصحيح المعتمد:

```text
SalesReturn
DirectReturn
```

فقط، مع الإبقاء على أي نوع ثالث مستقبلي غير ظاهر حتى يثبته Production.

---

## 5.3 M9-08 / M9-09 item source

لا تستخدم:

```text
RW_STATE.data.items
```

كمصدر نتيجة نهائية إذا كان التقرير قادرًا على قراءة Item Master الحالي.

البديل هو Production query مباشر.

وفي M9-09 يجب إضافة `max_qty` إلى Item Master query لأن منطق التوصية يستخدمه فعليًا.

---

## 5.4 Recommendation semantics

لا يجوز عرض heuristic مبني فقط على `reorder_point` على أنه Forecast أو AI certainty.

النتيجة الصحيحة في الحالة الحالية:

- توصية شراء مبنية على حد إعادة الطلب = `policy-based recommendation`.
- لا يجوز تسميتها demand forecast ما لم يثبت مصدر تاريخي كافٍ.

مع Production الحالية (orders = 0) لا يجوز اختلاق توقع طلب مبني على بيانات غير موجودة.

---

# 6. Source Surgery — الحزمة النهائية التي ينفذها المالك على Main9

**المساعد لا يعدل `Current/PWA/main2/main9.md` مباشرة.**

التعديلات أدناه هي Owner Source Operations.

جميع حدود الحذف يجب أن تعتمد على:

`START EXACT HEADING + FULL FUNCTION + NEXT EXACT MARKER`

ولا تعتمد على رقم السطر وحده.

---

## M9-01 — مغلق

لا تبحث عنه ولا تعدله.

احتفظ فقط بـ:

```text
function _companyId()
function _nextDate(dateText)
```

---

## M9-02 — `_loadDashboardData(fromDate, toDate)`

### ابحث حرفيًا:

```text
    async function _loadDashboardData(fromDate, toDate) {
```

### الوضع الحالي
تقريبًا السطر 67 في Git الحالي.

### احذف
من بداية السطر أعلاه حتى `}` التي تغلق الدالة مباشرة قبل:

```text
    // ========== التقارير التفصيلية (Checkbox) ==========
```

### استبدل بالبديل الكامل
استخدم بديل Report101/M9-02، ولكن طبّق التصحيحين التاليين داخله قبل الحفظ:

1. **لا تستخدم `RW_STATE.data.items` كمصدر التقرير.** استبدل هذا الجزء بالكامل باستعلام Production مباشر:

```javascript
            var itemsRes = await supabase
                .from('items')
                .select('id, item_code, name, reorder_point');

            if (itemsRes.error) throw itemsRes.error;

            var items = itemsRes.data || [];
```

2. **لا تستخدم `RW_STATE.data.customers` كمصدر التقرير.** استبدل هذا الجزء بالكامل باستعلام Production مباشر:

```javascript
            var custRes = await supabase
                .from('customers')
                .select('id, customer_code, name')
                .eq('company_id', companyId);

            if (custRes.error) throw custRes.error;

            var customers = custRes.data || [];
```

ويظل stock عبر Branch IDs التابعة للشركة، ويستخدم `available_qty`/`qty-allocated_qty`.

---

## M9-03 — `_loadDropdowns(params)`

### ابحث حرفيًا:

```text
    async function _loadDropdowns(params) {
```

### احذف
حتى `}` التي تغلق الدالة مباشرة قبل:

```text
    // ==================== دوال التفاصيل (Drill-Down) ====================
```

### استبدل
**بالمقطع الكامل M9-03 الموجود في Report101_main9** دون أي إعادة صياغة من الذاكرة.

الحالة المعتمدة لهذا الجزء:

- Customer = Company-scoped UUID.
- Supplier = Company-scoped UUID.
- Treasury = Company-scoped UUID.
- Account = Company-scoped UUID.
- Driver = Company-scoped UUID.
- Area = Company-scoped.
- Item = `item_code` لأن Production يثبت Global UNIQUE.
- Reset لكل select قبل append.

---

## M9-04 — `_showCustomerLedgerDetail`

### ابحث حرفيًا:

```text
    async function _showCustomerLedgerDetail(customerCode, customerName) {
```

### احذف
حتى `}` مباشرة قبل:

```text
    async function _showItemMovementDetail(itemCode, itemName) {
```

### استبدل
**بالمقطع الكامل M9-04 الموجود في Report101_main9**.

لا تغيّر الـcaller؛ الـcaller الصحيح يمرر `customer_id`.

---

## M9-05 — `_showItemMovementDetail`

### ابحث حرفيًا:

```text
    async function _showItemMovementDetail(itemCode, itemName) {
```

### احذف
حتى `}` مباشرة قبل:

```text
    async function _showRunsheetDetail(runsheetCode) {
```

### استبدل
**بالمقطع الكامل M9-05 الموجود في Report101_main9**.

العقد:

```text
item_code → items.id
items.item_code = global unique
inventory_log = company_id + item_id + item_code
```

---

## M9-06 — `_showRunsheetDetail`

### ابحث حرفيًا:

```text
    async function _showRunsheetDetail(runsheetCode) {
```

### احذف
حتى `}` مباشرة قبل:

```text
    async function _showSettlementDetail(settlementCode) {
```

### استبدل
**بالمقطع الكامل M9-06 الموجود في Report101_main9**.

الربط الصحيح:

```text
runsheets.company_id + runsheet_code
        ↓
rs.id
        ↓
run_sheet_details.runsheet_id
        ↓
orders.company_id + orders.runsheet_id = rs.id
```

لا تستخدم `runsheetCode` كـUUID.

---

## M9-07 — `_showSettlementDetail`

### ابحث حرفيًا:

```text
    async function _showSettlementDetail(settlementCode) {
```

### احذف
حتى `}` مباشرة قبل:

```text
    // ==================== توليد التقرير (مع Drill-Down) ====================
```

### استبدل
**بالمقطع الكامل M9-07 الموجود في Report101_main9**.

العقد:

```text
daily_settlements.company_id + settlement_code
        ↓
runsheet_id كـUUID
        ↓
runsheets.company_id + id
```

---

# 7. M9-08 — `_generateReport(sectionKey, reportId)`

### ابحث حرفيًا:

```text
    async function _generateReport(sectionKey, reportId) {
```

### احذف
حتى `}` التي تغلق الدالة مباشرة قبل:

```text
    function _printReport() {
```

### استبدل
**بالمقطع الكامل M9-08 الموجود في Report101_main9**، ثم نفذ التصحيحات الإلزامية التالية داخله:

### التصحيح A — Item Master
احذف كامل block الذي يبدأ بـ:

```javascript
                var masterItems =
                    RW_STATE &&
                    RW_STATE.data &&
                    Array.isArray(RW_STATE.data.items)
```

واستبدله باستعلام Production مباشر:

```javascript
                var masterRes = await supabase
                    .from('items')
                    .select(
                        'id, item_code, name, unit, cost_price, reorder_point, max_qty'
                    );

                if (masterRes.error) {
                    throw masterRes.error;
                }

                var masterItems = masterRes.data || [];
```

### التصحيح B — Returns
ابحث داخل فرع:

```text
reportId === 'logistics-returns'
```

وفي `.in('movement_type', [...])` احذف:

```text
'Return'
```

ويصبح المصفوفة:

```javascript
[\n    'SalesReturn',\n    'DirectReturn'\n]
```

ولا تضف نوعًا ثالثًا لم يثبته `post_stock_movement` الحالي.

### التصحيح C — Finance
لا تغير RPC signatures الحالية؛ Production أثبتها بهذه الأسماء والمعاملات:

```text
get_trial_balance(p_from_date,p_to_date)
get_profit_loss(p_from_date,p_to_date)
get_balance_sheet_data(p_as_of)
get_cash_flow(p_from_date,p_to_date)
```

### التصحيح D — Tax
يبقى:

```text
CAPABILITY GATED
```

ولا تُحتسب VAT من `orders.total_amount` أو `app_settings.tax_rate` بدون مصدر ضريبي سلطوي مثبت.

### التصحيح E — HR
يبقى Attendance/Salary:

```text
CAPABILITY GATED
```

إلى أن يثبت مصدر Production فعلي.

---

# 8. M9-09 — `_loadDetailedReports(fromDate, toDate, types)`

### ابحث حرفيًا:

```text
async function _loadDetailedReports(fromDate, toDate, types) {
```

### احذف
الدالة كاملة حتى `}` مباشرة قبل:

```text
    return {
        renderDashboard: renderDashboard,
        renderDetailedReports: renderDetailedReports
    };
```

**لا تحذف `return {` نفسه.**

### استبدل
**بالمقطع الكامل M9-09 الموجود في Report101_main9**، ثم طبّق التصحيحات التالية:

### التصحيح A — Items
احذف كامل fallback إلى `RW_STATE.data.items` واستبدله باستعلام Production مباشر:

```javascript
        var itemRes = await supabase
            .from('items')
            .select(
                'id, item_code, name, unit, cost_price, sales_price, reorder_point, max_qty'
            );

        if (itemRes.error) throw itemRes.error;

        var items = itemRes.data || [];
```

### التصحيح B — Customers
احذف fallback إلى `RW_STATE.data.customers` واستبدله:

```javascript
        var customerRes = await supabase
            .from('customers')
            .select(
                'id, customer_code, name, area, debt, is_active'
            )
            .eq('company_id', companyId);

        if (customerRes.error) throw customerRes.error;

        var customers = customerRes.data || [];
```

### التصحيح C — Orders
يظل:

```text
orders.company_id
+
fromDate/toDate
```

ثم `order_details` فقط للأوردرات التي تم جلبها من Company-scoped orders.

### التصحيح D — Stock
يظل stock مبنيًا على Branch IDs التابعة للشركة، لا على query global إلى `stock_branches`.

### التصحيح E — Recommendations
استخدم `max_qty` الحقيقي الذي تمت إضافته إلى Item Master query.

لا تعرض هذه النتيجة كـAI forecast؛ هي policy-based recommendation ما لم توجد بيانات طلب فعلية كافية.

---

# 9. ما لا يلمسه المالك

لا تعدل:

```text
function _companyId()
function _nextDate(dateText)
```

ولا:

```text
return {
    renderDashboard: renderDashboard,
    renderDetailedReports: renderDetailedReports
};
```

ولا:

```text
window.RW_Reports = RW_Reports;
window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;
```

ولا:

```text
function _printReport()
```

ولا:

```text
_reportsStructure
```

ولا:

`Original/PWA/main/*`

ولا:

`Current/PWA/New-main`

---

# 10. بعد الجراحة — Validation Gate

بعد اكتمال التعديلات يدويًا:

1. احفظ `Current/PWA/main2/main9.md`.
2. ارفع التعديل إلى Git على نفس المسار.
3. افتح الملف من Git مجددًا من أول حرف إلى EOF.
4. تحقق أن كل دالة من M9-02 إلى M9-09 موجودة **مرة واحدة فقط**.
5. تحقق أن النسخ القديمة اختفت.
6. تحقق أن M9-01 لم يتكرر.
7. تحقق من الأقواس والاقتباسات وتعليقات JavaScript وحدود الـIIFE.
8. لا تعتبر Main9 مغلقًا بعد هذه الخطوة وحدها.
9. طابق Main2 كاملًا قبل Assembly.
10. شغل `forensic_main_assembly.yml` بالمسار الحالي الصحيح.
11. شغل `node --check` على الناتج.
12. شغل Browser/PWA smoke.
13. بعد ذلك فقط نفذ report-by-report Production UI smoke.

---

# 11. Assembly Path — محسوم

تم فحص:

`.github/workflows/forensic_main_assembly.yml`

والـworkflow الحالي صحيح بالفعل:

```text
Current/PWA/main2/**
        ↓
assembly
        ↓
Current/PWA/New-main
```

لا يوجد سبب جديد لتغيير المسار.

لا تعود إلى:

`Current/PWA/main/main1..main11.md`

ولا تجعل:

`Current/PWA/New-main`

Source of Truth.

---

# 12. Production Action

في هذه الجلسة لم يثبت Defect Production جديد يستحق Migration إضافية تخص Main9.

الـProduction work المقصود لهذه المرحلة هو **قراءة/verfication** فقط.

لا توجد قاعدة صحيحة لتعديل بيانات Production لمجرد أن تقرير Main9 كان ناقصًا.

---

# 13. SELF-AUDIT

## What I Proved

- تم فتح masters الحاكمة.
- تم فتح Report101 و102 و103.
- تم فتح Main9 الحالي من Git.
- Current SHA = `a72b970...`.
- M9-02..M9-09 ما زالت تحتاج Owner Source Surgery.
- Production الحالية = Company واحدة.
- `items.item_code` global unique.
- Finance RPCs الحالية موجودة.
- `post_stock_movement` لا يدعم `Return` المنفرد.
- Assembly path صحيح.
- Inventory Core لا يحتاج إعادة فتح وفق الأدلة الحالية.

## What I Did Not Prove

- أن المالك نفذ الجراحات على Main9.
- أن Main9 بعد الجراحة أصبح صحيحًا نحويًا.
- أن Main2 بعد الجراحة قابل للـAssembly.
- أن New-main بعد Assembly يعمل في Browser.
- أن كل تقرير يمر في Production UI end-to-end.
- Gold/Diamond parent closure.

## What Was Corrected in This Recheck

1. Report101 لم يعد يُستخدم بصورة عمياء.
2. `RW_STATE` removed كـreport result source في M9-02/M9-08/M9-09.
3. Item Master M9-09 أصبح يتضمن `max_qty`.
4. Returns قُيدت بأنواع الحركة المثبتة في Production.
5. Recommendation semantics تم منع تضخيمها إلى AI forecast.

## Final Closure Status

```text
M9-01 = SOURCE CLOSED
M9-02..M9-09 = OWNER SURGERY REQUIRED
MAIN9 SOURCE = OPEN
MAIN2 ASSEMBLY = BLOCKED
PARENT GOLD/DIAMOND = NOT CLOSED
GLOBAL INVENTORY CORE = VERIFIED / NO NEW REPAIR JUSTIFIED
```

## NEXT AUTHORIZED ACTION

Owner executes the exact M9-02..M9-09 source surgery above, then Git re-read + syntax/integration validation. Only after that may Main2 Assembly proceed.
