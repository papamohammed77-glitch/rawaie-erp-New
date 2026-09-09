# RAWAEA ERP — Report99
## Main9 Forensic Surgical Recheck — 2026-09-09

## 0. المبدأ الحاكم — الهدف غير قابل للتخفيض
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا أتعامل معه كإضافات شكلية.**

وهذا ينطبق على Main9: لا يكفي إصلاح Company scoping فقط إذا بقيت تقارير تعرض رسالة نجاح مع عبارة "قيد التطوير" أو placeholder بدل القدرة الفعلية. يجب أن يصل الجزء في النهاية إلى تقرير تشغيلي قابل للاستخدام ومسنود إلى مصادر Production الحقيقية.

---

## 1. LAST VERIFIED EVENT

- Git HEAD قبل هذا التقرير: `3e5f491c6ba0d848f3403da5cae34bec1c0f903a`
- آخر commit مباشر على Main9: `1d534169f7f758851207cb6f0879bc59543a9339`
- تاريخ آخر تعديل مباشر على Main9: `2026-09-09 04:14:28 UTC`
- التعديل المثبت في هذا commit: إضافة `_companyId()` و`_nextDate()` فقط.
- Current Main9 blob SHA: `5fb184b2a16b0fde25d58dc9962641e2b31505c5`
- لم يحدث تعديل آخر على `Current/PWA/main2/main9.md` بعد هذا commit.

---

## 2. GOVERNANCE / CONTINUITY SOURCES REOPENED

تمت إعادة فتح ومراجعة مصادر الحوكمة والاستمرارية ذات الصلة:

- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`
- `CURRENT_STATE.md`
- `Report98_Main9_Forensic_Surgical_Recheck_20260909.md`
- `Current/PWA/main2/main9.md`
- `Original/PWA/main/main9.md`
- `.github/workflows/forensic_main_assembly.yml`
- `tools/run_final_main_reconstruction_20260831.py`

تم الحفاظ على القاعدة: `Current/PWA/main2` هو Source of Truth التحريري، بينما `Current/PWA/New-main` ناتج Assembly فقط، و`Original/PWA/main` و`Current/PWA/main` تاريخي/مرجعي.

---

## 3. MAIN9 COMPLETE SOURCE RE-READ

تمت إعادة قراءة Main9 الحالي من أوله إلى نهايته عبر الـblob الحالي، وليس فقط مناطق الدوال محل Report98.

### المكونات المثبتة داخل الملف

1. `RW_Reports` — Dashboard + Detailed Reports.
2. `_companyId()` و`_nextDate()` — موجودتان بالفعل ولا يجب تكرارهما.
3. `RW_Reports_Comprehensive` — هي طبقة التقارير الشاملة الحالية.
4. `_loadDropdowns()` + Drill-Downs + `_generateReport()` + `_printReport()`.
5. جميع Report IDs الحالية محفوظة في `_reportsStructure`.

### النتيجة
لا يوجد سبب لإعادة بناء Main9 من Original. التعديل يجب أن يبقى جراحيًا على `Current/PWA/main2/main9.md` فقط.

---

## 4. ORIGINAL / CURRENT RECONCILIATION

`Original/PWA/main/main9.md` يثبت الحالة التاريخية السابقة.

الاختلاف الوحيد المؤكد بين Original والحالة الحالية في بداية Main9 هو أن Current أضاف:

- `_companyId()`
- `_nextDate()`

وهو ما ثبت أيضًا في commit `1d534169...`.

لا يوجد دليل يسمح باستبدال Main9 كاملًا بالـOriginal. هذا ممنوع.

---

## 5. ASSEMBLY PATH VERIFICATION

تم فحص:

`.github/workflows/forensic_main_assembly.yml`

والـworkflow الحالي يثبت أن:

- canonical fragments = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical evidence = `Original/PWA/main/**`
- reconstruction tool يستخدم `CUR=Path('Current/PWA/main2')`

### النتيجة
لا يوجد تعديل مسار مطلوب في هذه الجولة.

---

## 6. PRODUCTION SNAPSHOT — DIRECT CURRENT VERIFICATION

**وقت اللقطة:** `2026-09-09T04:38:15.455221+00`

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

هذه اللقطة هي المرجع الحالي للتقرير، وليست قيمة من تقرير تاريخي.

---

## 7. PRODUCTION CONTRACTS RECONFIRMED

- `items.item_code` عليه `UNIQUE` عالميًا.
- `stock_branches` لا يحمل `company_id` مستقلًا؛ العزل يتم عبر `branch_id -> branches.company_id`.
- `customer_ledger.customer_id` UUID.
- `orders.runsheet_id` UUID.
- `run_sheet_details.runsheet_id` UUID.
- `daily_settlements.runsheet_id` UUID.
- `chart_of_accounts.id` UUID.
- `treasury.id` UUID.
- `customer_followups.company_id` موجود فعليًا.
- Finance RPCs المطلوبة موجودة في Production.
- HR attendance/payroll authoritative source لم يثبت، ولذلك لا يجوز تصنيع بيانات بديلة.

---

## 8. STATIC SYNTAX / CLOSURE REVIEW

### ما تم إثباته
- بنية الـIIFE الأولى (`RW_Reports`) مغلقة.
- بنية الـIIFE الثانية (`RW_Reports_Comprehensive`) مغلقة.
- `return { ... }` لكل وحدة موجود في الموضع الصحيح.
- لا يوجد في القراءة الحالية قوس/قوس مربع/قوس دالة واضح مفقود عند حدود الملف.
- `window.RW_Reports = RW_Reports;` و`window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;` موجودان.

### ما لم يتم إثباته بعد
`node --check` على **الـparent assembled application** لم ينفذ بعد، لأن Main9 fragment وحده ليس بوابة الـruntime النهائية. بوابة syntax/runtime الرسمية تظل: Assembly من Main1→Main11 ثم `node --check` وBrowser smoke على الناتج.

لذلك لا يتم تحويل static fragment review إلى `FULLY CLOSED`.

---

## 9. MAIN9 DEFECT MATRIX — CURRENT SOURCE

### M9-01 — CLOSED AT SOURCE
`_companyId()` و`_nextDate()` موجودتان بالفعل.

**الإجراء:** لا تكرر التعديل.

### M9-02 — OPEN / OWNER SURGERY
`async function _loadDashboardData(fromDate, toDate) {` — حول السطر 67.

العيوب المثبتة:
- orders غير company-scoped.
- stock_branches غير مقيد بفروع الشركة.
- fallback items غير مضبوط بمنهج identity الصحيح.
- recent orders غير company-scoped.
- fallback customers غير company-scoped.
- inactive comparison يقارن `customer_code` مع keys مصدرها `customer_id`.

### M9-03 — OPEN / OWNER SURGERY
`async function _loadDropdowns(params) {` — حول السطر 589.

العيوب:
- customer selector يستخدم `customer_code` بدل UUID.
- supplier selector يستخدم `supplier_code` بدل UUID.
- account selector يستخدم `account_code` بدل UUID.
- treasury selector يستخدم `account_code` بدل UUID.
- driver selector يستخدم email بدل UUID.
- company scoping غير مكتمل.
- items يجب أن تبقى على `item_code` لأنها Global UNIQUE.

### M9-04 — OPEN / OWNER SURGERY
`async function _showCustomerLedgerDetail(customerCode, customerName) {` — حول السطر 614.

يجب أن يصبح parameter = `customerId`، مع التحقق من أنه UUID لعميل الشركة الحالية، ثم القراءة من `customer_ledger.customer_id`.

### M9-05 — OPEN / OWNER SURGERY
`async function _showItemMovementDetail(itemCode, itemName) {` — حول السطر 631.

يجب أن تضيف:
- companyId
- `inventory_log.company_id = companyId`
- `item_code = itemCode`
- chronology بـ`created_at desc`

### M9-06 — OPEN / OWNER SURGERY
`async function _showRunsheetDetail(runsheetCode) {` — حول السطر 648.

المشكلة المؤكدة:
`orders.runsheet_id` UUID، بينما current code يقارنه بـ`runsheetCode`.

المطلوب:
- runsheet company-scoped.
- details by `rs.id`.
- orders by `.eq('runsheet_id', rs.id)`.

### M9-07 — OPEN / OWNER SURGERY
`async function _showSettlementDetail(settlementCode) {` — حول السطر 676.

المطلوب:
- companyId.
- `daily_settlements.eq('company_id', companyId).eq('settlement_code', settlementCode)`.

### M9-08 — OPEN / OWNER SURGERY — EXPANDED
`async function _generateReport(sectionKey, reportId) {` — حول السطر 696.

إضافة إلى متطلبات Report98 الأصلية، أعيد إثبات فجوات functional completeness التالية:

- `finance-balance-sheet` يعرض رسالة نجاح مع عبارة `العرض الكامل قيد التطوير` بدل تقرير فعلي.
- `finance-cash-flow` لا يعرض البيانات الناتجة فعليًا.
- `finance-tax` placeholder ثابت.
- `crm-customer-followups` placeholder رغم وجود `customer_followups` في Production.
- `crm-customer-list` يعتمد على `RW_STATE.data.customers` بلا ضمان Current company scope.
- `hr-employee-list` يقرأ users بلا company scope.
- `hr-attendance` و`hr-salary` placeholders، ويجب بقاؤهما capability-gated إذا لم يوجد authoritative source.
- `finance-general-ledger` يحتاج company scope عبر `journal_entries` بالإضافة إلى account identity.
- `finance-treasury` يستخدم `treasury_id` لكن يجب Company scope.
- `sales-by-item`, `inventory-movement`, `inventory-dormant` تحتاج order authoritative join / tenant scope.
- `sales-by-area`, `sales-order-status`, `sales-runsheet-performance`, logistics reports وغيرها تحتاج company scope.
- `receiving_details` يجب ربطه بسياق الشركة عن طريق مصدره authoritative وليس قراءة عالمية فقط.
- كل timestamp query يجب أن يستخدم `< _nextDate(toDate)` بدل `<= toDate` عندما يكون العمود timestamp.

### M9-09 — OPEN / OWNER SURGERY
`async function _loadDetailedReports(fromDate, toDate, types) {`

العيوب المثبتة:
- fallback items/customers غير company-scoped.
- stock_branches غير مقيد بفروع الشركة.
- orders غير company-scoped.
- order_details قراءة عالمية.
- detailed reporting path مستقل عن `_generateReport` ويمكنه إعادة بيانات خارج tenant.

المطلوب:
1. `companyId = _companyId()`.
2. customers/orders company-scoped.
3. branch IDs الخاصة بالشركة ثم stock scope عبر `branch_id`.
4. order_details عبر `orders!inner(company_id,order_date)` مع tenant/date filters.
5. items تبقى Global Item Master، ثم stock الشركة هو الذي يحدد الانعكاس التشغيلي.

---

## 10. FIRST AUTHORIZED OWNER SURGERY — M9-02

بسبب قاعدة `ONE CLOSURE UNIT AT A TIME`، هذه الجولة لا تطلب تنفيذ M9-03 إلى M9-09 قبل إغلاق M9-02.

### ابحث عن العنصر حرفيًا
`    async function _loadDashboardData(fromDate, toDate) {`

### الموضع
حول السطر `67` في Current Main9.

### احذف
الدالة كاملة، من السطر أعلاه حتى القوس `}` الذي يغلق نفس الدالة مباشرة قبل:
`    // ========== التقارير التفصيلية (Checkbox) ==========`

### استبدلها بالبديل الكامل التالي

```javascript
    async function _loadDashboardData(fromDate, toDate) {
        var container = byId('dash-result-container');
        if (!container) return;
        safeHTML(container, '<div class="text-center py-10"><i class="fa-solid fa-spinner fa-spin text-2xl text-indigo-600"></i><p class="mt-2 text-gray-500">جاري تحليل البيانات للفترة...</p></div>');

        try {
            var companyId = _companyId();
            var branchRes = await supabase.from('branches').select('id').eq('company_id', companyId);
            if (branchRes.error) throw branchRes.error;
            var branchIds = (branchRes.data || []).map(function(b) { return b.id; }).filter(Boolean);

            var ordersRes = await supabase
                .from('orders')
                .select('total_amount, order_date, customer_id')
                .eq('company_id', companyId)
                .gte('order_date', fromDate)
                .lt('order_date', _nextDate(toDate));
            if (ordersRes.error) throw ordersRes.error;
            var orders = ordersRes.data || [];

            var totalSales = 0;
            for (var i = 0; i < orders.length; i++) {
                totalSales += Number(orders[i].total_amount) || 0;
            }
            var orderCount = orders.length;
            var averageOrder = orderCount > 0 ? Math.round(totalSales / orderCount) : 0;
            var forecast = averageOrder * 30;
            var confidence = orderCount > 50 ? 'عالية' : (orderCount > 20 ? 'متوسطة' : 'منخفضة');

            var items = (RW_STATE && RW_STATE.data && Array.isArray(RW_STATE.data.items)) ? RW_STATE.data.items : [];
            if (!items.length) {
                var itemsRes = await supabase.from('items').select('*');
                if (itemsRes.error) throw itemsRes.error;
                items = itemsRes.data || [];
            }

            var stockData = [];
            if (branchIds.length) {
                var stockRes = await supabase
                    .from('stock_branches')
                    .select('item_id, qty')
                    .in('branch_id', branchIds);
                if (stockRes.error) throw stockRes.error;
                stockData = stockRes.data || [];
            }

            var stockMap = {};
            for (var s = 0; s < stockData.length; s++) {
                var stockItemId = stockData[s].item_id;
                if (!stockItemId) continue;
                stockMap[stockItemId] = (stockMap[stockItemId] || 0) + (Number(stockData[s].qty) || 0);
            }

            var lowStockCount = 0;
            for (var j = 0; j < items.length; j++) {
                var itemId = items[j] && items[j].id;
                if (!itemId) continue;
                if ((stockMap[itemId] || 0) <= (Number(items[j].reorder_point) || 5)) {
                    lowStockCount++;
                }
            }

            var sixtyDaysAgo = new Date();
            sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);
            var recentRes = await supabase
                .from('orders')
                .select('customer_id')
                .eq('company_id', companyId)
                .gte('order_date', sixtyDaysAgo.toISOString().split('T')[0])
                .lt('order_date', _nextDate(new Date().toISOString().split('T')[0]));
            if (recentRes.error) throw recentRes.error;

            var recentCustomers = {};
            (recentRes.data || []).forEach(function(r) {
                if (r && r.customer_id) recentCustomers[r.customer_id] = true;
            });

            var customers = (RW_STATE && RW_STATE.data && Array.isArray(RW_STATE.data.customers)) ? RW_STATE.data.customers : [];
            if (!customers.length) {
                var custRes = await supabase
                    .from('customers')
                    .select('id, customer_code, name')
                    .eq('company_id', companyId);
                if (custRes.error) throw custRes.error;
                customers = custRes.data || [];
            }

            var inactiveCount = 0;
            for (var c = 0; c < customers.length; c++) {
                var customerId = customers[c] && customers[c].id;
                if (!customerId) continue;
                if (!recentCustomers[customerId]) inactiveCount++;
            }

            var html = '<div class="text-right space-y-6 p-4">';
            html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4">';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">المبيعات المتوقعة (شهرياً)</p><p class="text-3xl font-black text-indigo-600">' + _fmtNum(forecast) + ' EGP</p><p class="text-xs text-gray-400 mt-1">مستوى الثقة: ' + confidence + '</p></div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">إجمالي المبيعات</p><p class="text-3xl font-black text-emerald-600">' + _fmtNum(totalSales) + ' EGP</p><p class="text-xs text-gray-400 mt-1">' + orderCount + ' أوردر</p></div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">أصناف منخفضة</p><p class="text-3xl font-black text-red-600">' + lowStockCount + '</p></div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">عملاء غير نشطين</p><p class="text-3xl font-black text-amber-600">' + inactiveCount + '</p></div>';
            html += '</div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><p class="text-sm text-gray-500"><strong>الفترة:</strong> من ' + _esc(fromDate) + ' إلى ' + _esc(toDate) + '</p></div>';
            html += '</div>';
            safeHTML(container, html);
        } catch (e) {
            console.error(e);
            safeHTML(container, '<div class="text-center py-10 text-red-500">فشل تحميل التحليلات</div>');
        }
    }
```

### لا تعدل شيئًا آخر في Main9 الآن
بعد الاستبدال، المطلوب فقط إعادة حفظ `main9.md` ثم إعادة التحقق من نفس الـanchor والـsyntax في الملف الحالي قبل الانتقال إلى M9-03.

---

## 11. IMPORTANT FUNCTIONAL FINDING — GOLD/DIAMOND

Main9 ليس مجرد مشكلة tenant filtering.

أثناء إعادة الفحص الكامل ثبت أن `RW_Reports_Comprehensive` يحتوي Reports مسماة كقدرات إنتاجية بينما بعضها يعرض placeholders، ومنها:

- Balance Sheet
- Cash Flow
- Tax
- CRM Followups
- HR Attendance
- HR Salary

لذلك M9-08 في النسخة القادمة يجب ألا يكون مجرد Company-scoping patch؛ يجب أن يغلق فجوة القدرة الوظيفية نفسها باستخدام Production RPCs والجداول السلطوية المتاحة، مع capability gating عند غياب المصدر السلطوي.

هذا متسق مع هدف Gold/Diamond: **عدم وجود شاشة توحي باكتمال قدرة غير موجودة فعليًا.**

---

## 12. PRODUCTION CHANGES IN THIS MAIN9 CHECKPOINT

لا يوجد DDL خاص بـMain9 مطلوب في هذه الجولة.

السبب المثبت:
- Production schema المطلوب لقراءات Main9 موجود.
- المشاكل الأساسية في هذه المرحلة تقع في Owner Source `Current/PWA/main2/main9.md`.
- لا يجوز اختراع جداول أو RPCs جديدة لمجرد إرضاء التقرير.

أي تعديل Production مستقبلي خاص بـMain9 يجب أن يمر بنفس التسلسل: read → reconcile → surgical change → test → Production verify → document.

---

## 13. SELF-AUDIT

### Confirmed Facts
- Governance reopened.
- Current Main9 blob reread.
- Original Main9 compared as historical evidence.
- M9-01 confirmed present and not repeated.
- Last direct Main9 commit identified.
- Current Production snapshot reread directly at `2026-09-09T04:38:15.455221+00`.
- Assembly canonical path confirmed as `Current/PWA/main2/**`.
- M9-02..M9-09 remain Owner Source surgeries.
- M9-08 functional completeness gap is wider than Report98’s tenant-scope requirements.

### Unknown / Not Yet Proved
- Owner application of M9-02.
- Final assembled Main2 syntax.
- Browser/E2E runtime after owner surgeries.
- Final report-by-report production smoke.

### Conflicts Resolved
- Historical reports may disagree with Current Main9; Current Main9 wins.
- Original Main9 remains historical reference; it is not the editable source.

### What was initially missed in prior analysis
- Some comprehensive report branches still contain functional placeholders even though their report IDs imply production capability.
- Several remaining operational reads inside `_generateReport` were not only tenant concerns but also failed to surface actual Production result data.

### Final Status
`M9-01 = SOURCE CLOSED`
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
