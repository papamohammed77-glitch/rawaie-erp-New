# RAWAEA ERP — Report100
## Main9 Forensic Final Checkpoint — 2026-09-09

## 0. المبدأ الحاكم — الهدف غير قابل للتخفيض
**هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا أتعامل معه كإضافات شكلية.**

هذه النقطة حاكمة على Main9 بالكامل: لا نعتبر وجود Report ID أو بطاقة أو رسالة نجاح دليل اكتمال وظيفي. يجب أن تكون التقارير مبنية على Production Sources الحقيقية، وألا توجد placeholders تخفي فجوة تشغيلية.

---

## 1. LAST VERIFIED EVENT / CURRENT SOURCE

- Current Main9: `Current/PWA/main2/main9.md`
- Current Main9 blob SHA: `5fb184b2a16b0fde25d58dc9962641e2b31505c5`
- آخر commit مباشر غيّر Main9: `1d534169f7f758851207cb6f0879bc59543a9339`
- تاريخ آخر تعديل مباشر: `2026-09-09 04:14:28 UTC`
- مضمون ذلك commit: إضافة `_companyId()` و`_nextDate()` فقط.
- لا يوجد دليل على تطبيق M9-02..M9-09 داخل Main9 حتى هذا checkpoint.

---

## 2. SOURCES REOPENED

تمت إعادة فتح ومراجعة:

- `CURRENT_STATE.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `doc/Draft/medhat/تقرير مبادئ حاكمة`
- `doc/Draft/medhat/برومبت استكمال مهام`
- `doc/Draft/Reprots/Report98_Main9_Forensic_Surgical_Recheck_20260909.md`
- `doc/Draft/Reprots/Report99_Main9_Forensic_Surgical_Recheck_20260909.md`
- `Current/PWA/main2/main9.md`
- `Original/PWA/main/main9.md`
- `.github/workflows/forensic_main_assembly.yml`
- `tools/run_final_main_reconstruction_20260831.py`
- Git commit history for Main9
- Production Supabase current schema/state relevant to Main9

---

## 3. MAIN9 FULL FORENSIC RE-READ RESULT

تمت قراءة `Current/PWA/main2/main9.md` عبر الـcurrent blob من البداية إلى النهاية، مع مراجعة كل من:

- `RW_Reports`
- Dashboard
- Detailed Reports
- `RW_Reports_Comprehensive`
- `_reportsStructure`
- render/open/close flows
- `_loadDropdowns`
- جميع Drill-Down functions
- `_generateReport`
- `_printReport`
- final exports

كما تمت مقارنة الـCurrent بالـOriginal التاريخي دون اعتبار Original مصدرًا للتحرير.

النتيجة: Current Main9 ما زال هو المصدر التحريري الصحيح، وM9-01 فقط هو التعديل المثبت. لا يوجد مبرر لإعادة بناء الجزء من Original.

---

## 4. ASSEMBLY GOVERNANCE RECHECK

`forensic_main_assembly.yml` و`run_final_main_reconstruction_20260831.py` يثبتان:

- Source of Truth = `Current/PWA/main2/**`
- generated target = `Current/PWA/New-main`
- historical reference = `Original/PWA/main/**`

لا يوجد تغيير مطلوب في المسار.

---

## 5. PRODUCTION FINAL SNAPSHOT

آخر لقطة Production مباشرة قبل إعداد هذا checkpoint:

`2026-09-09T04:39:35.141939+00`

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

لا يوجد في هذه اللقطة ما يبرر اختراع بيانات HR/Tax أو إعادة تصميم schema لمجرد إظهار اكتمال شكلي.

---

## 6. MAIN9 SURGERY STATUS

### M9-01
**SOURCE CLOSED**

العنصر موجود:
`function _companyId()`
و`
function _nextDate()`

لا يعاد تطبيقه.

### M9-02
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`    async function _loadDashboardData(fromDate, toDate) {`

حول السطر 67.

### M9-03
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`    async function _loadDropdowns(params) {`

حول السطر 589.

### M9-04
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`    async function _showCustomerLedgerDetail(customerCode, customerName) {`

حول السطر 614.

### M9-05
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`    async function _showItemMovementDetail(itemCode, itemName) {`

حول السطر 631.

### M9-06
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`    async function _showRunsheetDetail(runsheetCode) {`

حول السطر 648.

### M9-07
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`    async function _showSettlementDetail(settlementCode) {`

حول السطر 676.

### M9-08
**OPEN — OWNER SURGERY REQUIRED / FUNCTIONAL SCOPE EXPANDED**

Current anchor:
`    async function _generateReport(sectionKey, reportId) {`

حول السطر 696.

لم يعد المطلوب مجرد tenant filtering؛ بل يجب إزالة fake completion في التقارير التي تعرض نجاحًا بينما لا تعرض البيانات الفعلية.

### M9-09
**OPEN — OWNER SURGERY REQUIRED**

Current anchor:
`async function _loadDetailedReports(fromDate, toDate, types) {`

قبل:
`    return {`

---

## 7. EXACT NEXT OWNER ACTION — M9-02 ONLY

**لا تنفذ M9-03 أو M9-04 أو غيرهما الآن.**

ابحث حرفيًا عن:

`    async function _loadDashboardData(fromDate, toDate) {`

وهو حول السطر 67.

احذف الدالة كاملة حتى القوس `}` الذي يغلق هذه الدالة مباشرة قبل السطر الكامل:

`    // ========== التقارير التفصيلية (Checkbox) ==========`

ثم ضع مكانها هذا المقطع كاملًا:

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

بعد الحفظ: لا تحذف أو تعدل أي دالة أخرى. أعد فحص أن بداية الدالة هي السطر أعلاه وأنها تنتهي مباشرة قبل:
`    // ========== التقارير التفصيلية (Checkbox) ==========`

---

## 8. SYNTAX VALIDATION RESULT

- تمت مراجعة بنية Main9 كاملة يدويًا عبر current Git blob.
- إغلاقات IIFE و`return` وexports متسقة ظاهريًا.
- تمت محاولة تشغيل `node --check` محليًا على النص الحالي، لكن بيئة التنفيذ لم تستطع الوصول إلى raw.githubusercontent.com، ولذلك لم يتم توليد ملف الاختبار محليًا.
- **الحالة الرسمية:** `SYNTAX PASS = NOT PROVED`.
- لا يجوز تحويل ذلك إلى `PASS` قبل Assembly الكامل Main1→Main11 وتشغيل الـworkflow الرسمي أو بوابة Node مكافئة مع وصول حقيقي إلى النص.

---

## 9. GOLD / DIAMOND FUNCTIONAL FINDINGS

حتى بعد إغلاق مشاكل tenant identity، لن تكون Main9 Gold/Diamond ما لم تعالج فعليًا:

- Balance Sheet placeholder.
- Cash Flow placeholder/result-not-rendered.
- Tax placeholder مع غياب مصدر سلطوي مثبت.
- CRM Followups placeholder رغم وجود `customer_followups` في Production.
- HR Attendance/Salary placeholder؛ capability gating مطلوب إلى أن يثبت مصدر Production سلطوي.
- General Ledger company scoping.
- Treasury company scoping.
- operational reports tenant/date scope.
- timestamp ranges باستخدام `< _nextDate(toDate)`.

هذه ليست “زينة إضافية”، بل جزء من الهدف المعلن: **استكمال التبويبات وظيفيًا لتصبح منافسًا حقيقيًا للأنظمة الكبرى، لا مجرد إكمال الشاشات.**

---

## 10. PRODUCTION ACTIONS IN THIS CHECKPOINT

لا يوجد Main9-specific Production DDL مطلوب في هذه الجولة.

لم يتم تعديل Main9 نفسه من المساعد، التزامًا بقاعدة Owner Source.

تمت المحافظة على Production كمرجع قياس فقط، مع آخر snapshot موثق في القسم 5.

---

## 11. FAILURE MEMORY

### ما فشل
- محاولة `node --check` محليًا من raw GitHub فشلت بسبب عدم توفر الشبكة في بيئة التنفيذ.

### السبب
- بيئة التنفيذ الحالية لا تستطيع resolve/connect إلى GitHub مباشرة.

### ما نجح
- GitHub connector قدم current Main9 blob كاملًا.
- تم فحص Main9 بالكامل.
- تم تحديد M9-02..M9-09 بدقة.
- تم تحديد الفجوة الوظيفية في Comprehensive Reports.

### ما لا يجب تكراره
- لا تعتمد على فشل الوصول المحلي كدليل syntax failure.
- لا تعتمد على القراءة الجزئية أو التقرير القديم لإعلان الحالة.
- لا تعدل Main9 مباشرة من المساعد.

---

## 12. SELF-AUDIT

### Confirmed Facts
- Current Main9 source verified.
- Original historical reference verified.
- Governance re-opened.
- Latest Main9 commit identified.
- Current production snapshot verified at `2026-09-09T04:39:35.141939+00`.
- Assembly path verified.
- M9-01 present.
- M9-02..M9-09 open.
- M9-08 requires functional completeness in addition to tenant safety.

### Unknown / Not Yet Proved
- Owner application of M9-02.
- Main9 post-surgery syntax.
- Main2 final assembly syntax.
- Browser/E2E runtime after surgery.
- Full report-by-report Production smoke.

### FINAL CLOSURE
`M9-01 = SOURCE CLOSED`
`M9-02..M9-09 = OPEN`
`MAIN9 = NOT FULLY CLOSED`
`MAIN2 ASSEMBLY = BLOCKED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
