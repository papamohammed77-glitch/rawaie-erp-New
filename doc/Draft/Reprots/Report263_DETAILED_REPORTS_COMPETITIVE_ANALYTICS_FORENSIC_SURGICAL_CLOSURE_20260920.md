# تقرير 263 — إغلاق جراحي لتطوير تبويب التقارير التفصيلية — 2026-09-20

## 1. نطاق المهمة

هذا التقرير يعيد ضبط الحقيقة التشغيلية لتبويب **التقارير التفصيلية** فقط، مع الالتزام بهرم الحقيقة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT.

لم يتم تعديل `main.html` من جهة التنفيذ المباشر. تم تنفيذ تغييرات Production اللازمة في الـRPC الموجود `public.detailed_reports_read`، وتم تجهيز تعديلات Mother الدقيقة بصيغة استبدال كاملة ليطبقها مالك المستودع.

---

## 2. نقطة البداية المثبتة

### System Repository
- HEAD قبل هذه الجلسة: `2a50e212638795705bfc064be1bbc5c0840d22ef`
- Parent: `0c26a5df952ec3017721f41f0d0809688d384cef`
- آخر تقرير تسلسلي قبل هذه الجلسة: Report262.
- CURRENT_STATE قبل هذه الجلسة: blob `2ad4d725161c1de9007b1c0baad560894b5ed7da`.

### Mother Repository
- HEAD الحالي: `ef11e87dc6177d0c39844a9878fff587254b3719`
- Parent: `97f86427d3e50cadcc59880d9d961c8c8aaf6bab`
- Commit `97f86427...` هو الإصلاح التاريخي الذي أغلق عيب عدم تنفيذ التقرير عند اختيار الـtab.
- مصدر Mother الحالي `main.html` تم التحقق منه عبر blob:
  `5a628da5417a830bf22553fa99a858521cdf6673`.

**نتيجة جنائية:** خطأ Report262 الخاص بالتنقل ليس مفتوحًا الآن ولا يجوز إعادة إصلاحه.

---

## 3. الحالة الحالية التي أثبتتها Production

لقطة Production الحالية:
- companies = 1
- branches = 2
- items = 17
- stock_branches = 20
- inventory_log = 3
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- purchase_orders = 0
- purchase_order_details = 0
- receiving = 0
- purchase_invoices = 0
- purchase_invoice_details = 0
- journal_entries = 2
- journal_lines = 0
- customers = 3
- suppliers = 1
- customer_ledger = 0
- supplier_ledger = 0
- work_orders = 0
- work_order_details = 0
- cost_centers = 3

الـRPC الحالي:
`public.detailed_reports_read`
هو SECURITY DEFINER، مع Tenant/Permission guards، ويستدعي الـinternal canonical reader للتقارير الخمسة الأصلية.

---

## 4. إعادة بناء التاريخ وعدم تكرار الإصلاح

### ما تم إغلاقه سابقًا ولا أعيد إصلاحه
1. إنشاء مركز التقارير السيادي.
2. Company context.
3. Server-side pagination.
4. Material Ledger scope/alias corrections.
5. تبويب التقارير لاختيار التقرير وتشغيله تلقائيًا بعد اختيار الـtab — مغلق تاريخيًا في Mother commit `97f86427...`.

### ما كان باقيًا فعلًا
التبويب كان يملك خمسة تقارير سيادية فقط:
- inventory_gl_reconciliation
- grni
- material_ledger
- traceability
- production_variance

مع أن Production تحتوي بالفعل على معلومات تشغيل الرحلات، المركبات، السائقين، الكميات ordered/picked/loaded/delivered/refused/returned، والمبيعات المرتبطة بالرانشيت.

كما أن المنافسين الحاليين يقدّمون تقارير تحليلية أعلى من مجرد كشف الحركة:

- Odoo يقدم Replenishment تفاعليًا يعتمد على الطلب المتوقع وقواعد إعادة الطلب وLead Time، كما يقدّم Audit Trail للحركات المحاسبية. 
- Business Central 2026 يقدم ABC Analysis قابلة للضبط، وتقارير حركة المخزون التفصيلية، وتقارير Inventory Availability تجمع الطلب والعرض، وتقارير تحليل قابلة للتخصيص. 
- SAP Material Ledger يربط حركات المواد والفواتير وتسويات الأوامر بالتقييم والتكلفة الفعلية، وBatch/Serial Management للتتبع. 
- Daftra يقدم حركة مخزون تفصيلية حسب المنتج/المخزن/نوع الحركة مع افتتاحية الفترة والتكلفة ومتوسط التكلفة والتصدير.
- Manager يقدم Reports قابلة للحفظ، وتقارير Aging/Statements، وتقارير مبيعات مقارنة بالفترات، وCustom Reports ببناء بصري.

---

## 5. قرار معماري

لم يتم إنشاء Edge Function جديدة.

تم تطوير **نفس**:
`detailed_reports_read`

والسبب:
- Function cap / Spend limit الحالي.
- التقرير التفصيلي أصلًا routed إلى RPC مصادق عليه.
- الإضافة قراءة فقط ولا تحتاج capability endpoint جديد.
- بذلك يبقى مركز التحكم في RPC واحد ولا تتحول التقارير إلى جزر.

---

## 6. ما تم تنفيذه فعليًا في Production

### 6.1 Inventory ABC

تمت إضافة report key:
`inventory_abc`

المصدر:
- orders
- order_details
- items

السلوك:
- يضم فقط الطلبات ذات الحالة `Invoiced` أو `Delivered`.
- يحسب `net_qty = qty - qty_returned`.
- يحسب قيمة المبيعات من الكمية الصافية × سعر البيع.
- يحسب cumulative sales share.
- يخرج A/B/C.

قاعدة A/B/C المسجلة في الـmetadata:
**80/15/5 cumulative-sales analytical convention**.

هذه ليست Purchasing Policy، وليست قيمة ضبط دائمة؛ Production لا يحتوي حاليًا إعدادًا موثّقًا لحدود ABC قابلة للتحكم.

تم أيضًا اكتشاف خطأ E2E في الحالة أحادية الصنف: كان الصنف الوحيد يحصل على C لأن cumulative share = 100%.

تم إصلاح ذلك جراحيًا داخل نفس الـRPC:
- إذا كانت قيمة الصنف مساوية لإجمالي المبيعات في المجموعة، يصنف A.
- ثم تطبق بقية قواعد 80/95.

### 6.2 Logistics Performance

تمت إضافة report key:
`logistics_performance`

المصادر:
- runsheets
- orders
- run_sheet_details
- daily_settlements
- users
- vehicles

التقرير يعرض:
- الرحلة
- السائق
- المركبة
- عدد الطلبات
- قيمة المبيعات
- المدفوع والمتبقي
- ordered/picked/loaded/delivered/refused/returned
- Pick Completion %
- Load Completion %
- Delivery Fill %
- Refusal %
- Return %
- Pick minutes
- Load minutes
- Delivery minutes
- Full cycle minutes
- settlement status/code

تم intentionally عدم اختلاق On-Time KPI؛ Production لا يملك Scheduled Delivery Date/Time مثبتًا يسمح بقياسه بأمان.

---

## 7. E2E Forensic Verification

تم إنشاء بيانات تشغيلية مؤقتة داخل جلسة PostgreSQL ثم rollback كامل.

السيناريو:
- Runsheet واحد.
- Order واحد بحالة Delivered.
- Order Detail واحد.
- تم تحديث مراحل التنفيذ.
- Trigger الحالي `trg_sync_run_sheet_details` أنشأ الـrun_sheet_detail تلقائيًا.

هذه نقطة معمارية مثبتة: `run_sheet_details` مشتق من `order_details` بواسطة المسار الحالي، لذلك لم يتم إنشاء detail يدويًا في الاختبار.

نتيجة الاختبار:
- inventory_abc success = true
- rows = 1
- first classification = A
- first sales value = 90
- logistics_performance success = true
- rows = 1
- delivery fill = 80.00%
- full cycle = 65.00 minutes
- run_sheet_detail count = 1

كما تم إعادة اختبار التقارير الخمسة السابقة:
- inventory_gl_reconciliation = true
- grni = true
- material_ledger = true
- traceability = true عند تمرير item حقيقي
- production_variance = true

بعد rollback:
- test order = 0
- test runsheet = 0
- test run_sheet_details = 0

**لا توجد بيانات اختبارية متروكة في Production.**

---

## 8. Production Runtime بعد الإغلاق

تم استدعاء الـRPC مباشرة من Production بعد آخر migration.

### inventory_abc
- success = true
- rows = []
- total_sales_value = 0

### logistics_performance
- success = true
- rows = []
- runsheet_count = 0
- ordered/picked/loaded/delivered/refused/returned = 0
- delivery_fill_pct = null
- average_full_cycle_minutes = null

هذه القيم صحيحة بالنسبة للحالة الحالية؛ لا توجد أوامر أو رحلات Production في الفترة المختبرة.

---

## 9. لماذا لم نبنِ AR/AP Aging الآن؟

المنافسون يوفّرون Aging وStatements، لكن لا توجد حاليًا حركة Customer/Supplier Ledger فعلية في Production، كما أن `customer_ledger` و`supplier_ledger` لا يحملان company_id مباشرة.

لذلك لم يتم بناء Aging مزعوم داخل هذه الجلسة اعتمادًا على تخمين allocation للمدفوعات.

هذا Gap حقيقي لكنه يحتاج عقدًا ماليًا واضحًا لتوزيع المدفوعات والمستحقات عبر الشركة، وليس مجرد SELECT آخر.

---

## 10. الفجوات التنافسية التي ثبتت ولم تُختلق

### يمكن تطويرها فوق الموجود لاحقًا
1. Period-over-period comparison.
2. Custom Pivot/Matrix reporting.
3. Saved report definitions / report templates.
4. Availability forecast يجمع On Hand + Sales Orders + Purchase Orders + Transfers.
5. Supplier/Customer Aging بعد تثبيت payment allocation contract.
6. Logistics On-Time KPI بعد إضافة/إثبات planned delivery timestamp.
7. Driver/Vehicle utilization and trip economics.

### فجوات Business Contract حقيقية
1. Batch/Lot/Expiry/Serial identity.
2. Historical cost layers / valuation snapshots.
3. Production Order + BOM + actual consumption/output/cost.
4. Production Variance وWIP/settlement.
5. Explicit GRNI/WRX control account.

هذه ليست نقص واجهة. لا يجوز إغلاقها بإظهار أعمدة وهمية.

---

## 11. التعديل الجراحي المطلوب في Mother

**لا تعيد إصلاح event handler الحالي.** الإصلاح السابق مطبق بالفعل.

المطلوب فقط جعل الواجهة تعرض وتفهم التقريرين الجديدين.

### Patch A — reportTitle()

ابحث تحديدًا عن:
`function reportTitle(key) {`

واحذف الدالة كاملة واستبدلها بهذه الدالة:

~~~javascript
function reportTitle(key) {
    var map = {
        inventory_gl_reconciliation: '1. مطابقة المخازن والدفتر العام',
        grni: '2. البضائع المستلمة غير المفوترة — GRNI',
        material_ledger: '3. كشف حركة الصنف والتكلفة — Material Ledger',
        traceability: '4. التتبع الرجعي/الأمامي — Traceability',
        production_variance: '5. أوامر الإنتاج والانحرافات — Production Variance',
        inventory_abc: '6. ABC للأصناف حسب قيمة المبيعات',
        logistics_performance: '7. أداء الرحلات والتوصيل واللوجستيات'
    };
    return map[key] || key;
}
~~~

### Patch B — تبويبات التقرير

ابحث تحديدًا عن مصفوفة:
`[
    ['inventory_gl_reconciliation', 'المخزون ↔ GL'],
    ['grni', 'GRNI'],
    ['material_ledger', 'Material Ledger'],
    ['traceability', 'Traceability'],
    ['production_variance', 'Production Variance']
]`

واستبدلها كاملة بـ:

~~~javascript
[
    ['inventory_gl_reconciliation', 'المخزون ↔ GL'],
    ['grni', 'GRNI'],
    ['material_ledger', 'Material Ledger'],
    ['traceability', 'Traceability'],
    ['production_variance', 'Production Variance'],
    ['inventory_abc', 'ABC الأصناف'],
    ['logistics_performance', 'أداء الرحلات']
]
~~~

### Patch C — عنوان المركز

في `buildShell()` ابحث تحديدًا عن:
`مركز التقارير السيادية الرقابية الخمسة`

واستبدل النص فقط بـ:
`مركز التقارير السيادية الرقابية السبعة`

### Patch D — renderResult()

ابحث تحديدًا عن:
`function renderResult(result) {`

واحذف الدالة كاملة واستبدلها بهذه الدالة:

~~~javascript
function renderResult(result) {
    var out = byId('rw-sovereign-results');
    if (!out) return;

    state.lastResult = result || null;
    state.lastRows = (result && result.rows) || [];
    state.lastReport = state.activeKey;

    var s = result && result.summary ? result.summary : {};
    var m = result && result.meta ? result.meta : {};

    var h = '<div class="space-y-5">';

    if (state.activeKey === 'inventory_gl_reconciliation') {
        h += '<div class="grid grid-cols-2 md:grid-cols-5 gap-3">' +
            buildSummaryCard('رصيد الكمية', money(s.qty_on_hand)) +
            buildSummaryCard('كمية بلا تكلفة', money(s.uncosted_qty), num(s.uncosted_qty) > 0 ? 'bg-amber-50 border-amber-200 text-amber-900' : '') +
            buildSummaryCard('قيمة المخزون حسب التكلفة الحالية', money(s.physical_value_current_cost)) +
            buildSummaryCard('رصيد GL', money(s.gl_balance_to_date)) +
            buildSummaryCard('الفرق', money(s.difference), Math.abs(num(s.difference)) > 0.005 ? 'bg-red-50 border-red-200 text-red-800' : 'bg-emerald-50 border-emerald-200 text-emerald-800') +
            '</div>';
    }

    if (state.activeKey === 'grni') {
        h += '<div class="grid grid-cols-2 md:grid-cols-4 gap-3">' +
            buildSummaryCard('قيمة المستلم', money(s.total_received_value)) +
            buildSummaryCard('قيمة الفواتير', money(s.total_invoiced_value)) +
            buildSummaryCard('GRNI التشغيلي', money(s.total_grni_value), num(s.total_grni_value) > 0 ? 'bg-red-50 border-red-200 text-red-800' : '') +
            buildSummaryCard('حساب GRNI صريح', s.control_account_configured ? 'مُعرّف' : 'غير مُعرّف', s.control_account_configured ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-amber-50 border-amber-200 text-amber-900') +
            '</div>';
    }

    if (state.activeKey === 'material_ledger') {
        h += '<div class="grid grid-cols-2 md:grid-cols-4 gap-3">' +
            buildSummaryCard('حركات مادية', money(s.physical_recorded_rows)) +
            buildSummaryCard('مرتبطة ماليًا', money(s.financial_linked_rows), 'bg-emerald-50 border-emerald-200 text-emerald-800') +
            buildSummaryCard('غير مرتبطة ماليًا', money(s.financial_unlinked_rows), num(s.financial_unlinked_rows) > 0 ? 'bg-red-50 border-red-200 text-red-800' : '') +
            buildSummaryCard('إجمالي السجلات', money(s.row_count)) +
            '</div>';
    }

    if (state.activeKey === 'traceability') {
        h += '<div class="grid grid-cols-2 md:grid-cols-4 gap-3">' +
            buildSummaryCard('عدد الأحداث', money(s.row_count)) +
            buildSummaryCard('مستوى التتبع', statusLabel(s.traceability_level)) +
            buildSummaryCard('Batch', s.batch_tracking_supported ? 'مدعوم' : 'غير متاح', s.batch_tracking_supported ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-amber-50 border-amber-200 text-amber-900') +
            buildSummaryCard('Serial/Lot', (s.serial_tracking_supported || s.lot_tracking_supported) ? 'مدعوم' : 'غير متاح', 'bg-amber-50 border-amber-200 text-amber-900') +
            '</div>';
    }

    if (state.activeKey === 'production_variance') {
        h += '<div class="bg-amber-50 border border-amber-200 rounded-3xl p-6">' +
            '<div class="text-xs font-black text-amber-700">CONTRACT GATE</div>' +
            '<h3 class="text-xl font-black text-amber-950 mt-2">لا توجد أرقام انحراف مصطنعة</h3>' +
            '<p class="text-sm leading-7 text-amber-900 mt-3">' + esc(s.reason || '') + '</p>' +
            '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mt-5">' +
            buildSummaryCard('المخطط مقابل الفعلي', 'غير مدعوم', 'bg-white border-amber-200 text-amber-900') +
            buildSummaryCard('انحراف التكلفة', 'غير مدعوم', 'bg-white border-amber-200 text-amber-900') +
            buildSummaryCard('قرار التقرير', 'READINESS ONLY', 'bg-white border-amber-200 text-amber-900') +
            '</div></div>';
    }

    if (state.activeKey === 'inventory_abc') {
        h += '<div class="grid grid-cols-2 md:grid-cols-4 gap-3">' +
            buildSummaryCard('الأصناف', num(s.row_count)) +
            buildSummaryCard('إجمالي المبيعات', money(s.total_sales_value)) +
            buildSummaryCard('A', num(s.class_a_count), 'bg-emerald-50 border-emerald-200 text-emerald-900') +
            buildSummaryCard('B / C', num(s.class_b_count) + ' / ' + num(s.class_c_count), 'bg-slate-50 border-slate-200 text-slate-800') +
            '</div>';
    }

    if (state.activeKey === 'logistics_performance') {
        h += '<div class="grid grid-cols-2 md:grid-cols-4 gap-3">' +
            buildSummaryCard('الرحلات', num(s.runsheet_count)) +
            buildSummaryCard('Delivery Fill %', s.delivery_fill_pct == null ? '—' : num(s.delivery_fill_pct) + '%') +
            buildSummaryCard('متوسط الدورة', s.average_full_cycle_minutes == null ? '—' : num(s.average_full_cycle_minutes) + ' دقيقة') +
            buildSummaryCard('Delivered Qty', money(s.delivered_qty)) +
            '</div>' +
            '<div class="bg-slate-50 border border-slate-200 rounded-2xl p-4 text-xs font-bold text-slate-600">' +
            'On-Time KPI: غير مدعوم في Production الحالية لعدم وجود Scheduled Delivery timestamp موثّق.' +
            '</div>';
    }

    if (m && m.note) {
        h += '<div class="bg-slate-50 border border-slate-200 rounded-2xl p-4 text-xs font-bold text-slate-600">' + esc(m.note) + '</div>';
    }

    if (state.activeKey === 'grni' && s.control_account_configured === false) {
        h += '<div class="bg-amber-50 border border-amber-200 rounded-2xl p-4 text-sm font-bold text-amber-900">Production الحالي لا يثبت حساب GRNI/WRX صريحًا؛ التقرير يعرض التعرض التشغيلي فقط ولا يخترع حسابًا ماليًا.</div>';
    }

    if (state.activeKey === 'traceability') {
        h += '<div class="bg-amber-50 border border-amber-200 rounded-2xl p-4 text-sm font-bold text-amber-900">التتبع الحالي Item/Document فقط. لا توجد Batch/Lot/Serial identity في Production الحالية، ولذلك لم يتم اختلاق رقم تشغيلة أو genealogy غير موجودة.</div>';
    }

    if (state.activeKey !== 'production_variance') {
        h += renderTable();
    }

    h += '</div>';
    safeHTML(out, h);
    bindDrills(out);
}
~~~

### Patch E — renderTable()

ابحث تحديدًا عن:
`function renderTable() {`

واحذف الدالة كاملة واستبدلها بدالة التقرير في القسم التالي من هذا التقرير. هذه الدالة تضيف أعمدة التقريرين الجديدين وتفرّق بين money / percentage / duration / count بدل عرض كل الأرقام بقالب واحد.

~~~javascript
function renderTable() {
    var rows = state.lastRows || [];

    if (!rows.length) {
        return '<div class="bg-white border rounded-3xl p-10 text-center text-slate-500 font-bold">لا توجد صفوف وفق Production والفلاتر الحالية.</div>';
    }

    var h = '<div class="bg-white border rounded-3xl shadow-sm overflow-hidden"><div class="p-4 border-b flex flex-wrap justify-between gap-2"><div class="font-black">بيانات التقرير</div><div class="text-xs text-slate-500 font-bold">عدد الصفوف: ' + rows.length + '</div></div><div class="overflow-auto"><table class="w-full min-w-[1200px] text-sm"><thead class="bg-slate-950 text-white"><tr>';

    var cols = [];

    if (state.activeKey === 'inventory_gl_reconciliation') {
        cols = [
            ['branch_name','الفرع'],['item_code','كود الصنف'],['item_name','الصنف'],
            ['qty_on_hand','الكمية'],['allocated_qty','محجوز'],['available_qty','متاح'],
            ['current_cost_price','التكلفة الحالية'],['physical_value_current_cost','قيمة المخزون']
        ];
    } else if (state.activeKey === 'grni') {
        cols = [
            ['po_code','أمر الشراء'],['supplier_name','المورد'],['item_code','الصنف'],
            ['ordered_qty','المطلوب'],['received_qty','المستلم'],['invoiced_qty','المفوتر'],
            ['uninvoiced_qty','غير مفوتر'],['received_value_at_po_price','قيمة الاستلام'],
            ['invoiced_value','قيمة الفاتورة'],['grni_value','GRNI'],['days_outstanding','أيام'],['status','الحالة']
        ];
    } else if (state.activeKey === 'material_ledger') {
        cols = [
            ['movement_date','التاريخ'],['movement_type','الحركة'],['direction','الاتجاه'],
            ['branch_name','الفرع'],['item_code','الصنف'],['qty','الكمية'],
            ['before_qty','قبل'],['after_qty','بعد'],['current_cost_price','تكلفة حالية'],
            ['movement_value_current_cost','قيمة الحركة'],['reference','المرجع'],
            ['physical_status','المادي'],['financial_status','المالي'],['journal_entry_code','القيد']
        ];
    } else if (state.activeKey === 'traceability') {
        cols = [
            ['movement_date','التاريخ'],['movement_type','الحركة'],['item_code','الصنف'],
            ['qty','الكمية'],['source_branch_id','المصدر'],['target_branch_id','الوجهة'],
            ['reference','المرجع'],['voucher_id','المستند'],['chain_direction','الاتجاه'],
            ['user_email','المنفذ']
        ];
    } else if (state.activeKey === 'inventory_abc') {
        cols = [
            ['item_code','كود الصنف'],['item_name','الصنف'],['net_qty','صافي الكمية'],
            ['sales_value','قيمة المبيعات'],['sales_share_pct','حصة المبيعات %'],
            ['cumulative_share_pct','التراكمي %'],['abc_class','ABC']
        ];
    } else if (state.activeKey === 'logistics_performance') {
        cols = [
            ['runsheet_code','الرانشيت'],['run_date','التاريخ'],['status','الحالة'],
            ['driver_name','السائق'],['vehicle_code','المركبة'],['order_count','الطلبات'],
            ['sales_value','المبيعات'],['ordered_qty','مطلوب'],['picked_qty','منتقى'],
            ['loaded_qty','محمل'],['delivered_qty','مسلم'],['delivery_fill_pct','Fill %'],
            ['refused_qty','مرفوض'],['returned_qty','مرتجع'],['full_cycle_minutes','دورة كاملة'],
            ['settlement_status','التسوية']
        ];
    }

    cols.forEach(function (c) {
        h += '<th class="p-3 whitespace-nowrap">' + esc(c[1]) + '</th>';
    });
    h += '<th class="p-3">تنقيب</th></tr></thead><tbody>';

    var moneyFields = [
        'qty_on_hand','allocated_qty','available_qty','current_cost_price',
        'physical_value_current_cost','ordered_qty','received_qty','invoiced_qty',
        'uninvoiced_qty','received_value_at_po_price','invoiced_value','grni_value',
        'qty','before_qty','after_qty','movement_value_current_cost','net_qty','sales_value',
        'delivered_qty','picked_qty','loaded_qty','refused_qty','returned_qty'
    ];

    var pctFields = ['sales_share_pct','cumulative_share_pct','pick_completion_pct','load_completion_pct','delivery_fill_pct','refusal_pct','return_pct'];
    var countFields = ['order_count','delivered_order_count'];
    var durationFields = ['pick_minutes','load_minutes','delivery_minutes','full_cycle_minutes'];

    rows.forEach(function (row) {
        h += '<tr class="border-t hover:bg-slate-50">';
        cols.forEach(function (c) {
            var key = c[0];
            var value = row[key];

            if (key === 'status' || key === 'physical_status' || key === 'financial_status' || key === 'settlement_status' || key === 'abc_class') {
                h += '<td class="p-3"><span class="px-2 py-1 rounded-full border text-xs font-black ' +
                    statusClass(value) + '">' + esc(statusLabel(value)) + '</span></td>';
                return;
            }

            if (pctFields.indexOf(key) !== -1) {
                h += '<td class="p-3 font-bold whitespace-nowrap">' + (value == null ? '—' : esc(num(value) + '%')) + '</td>';
                return;
            }

            if (durationFields.indexOf(key) !== -1) {
                h += '<td class="p-3 font-bold whitespace-nowrap">' + (value == null ? '—' : esc(num(value) + ' دقيقة')) + '</td>';
                return;
            }

            if (countFields.indexOf(key) !== -1) {
                h += '<td class="p-3 font-bold whitespace-nowrap">' + (value == null ? '—' : esc(num(value))) + '</td>';
                return;
            }

            if (moneyFields.indexOf(key) !== -1) {
                h += '<td class="p-3 font-bold whitespace-nowrap">' + money(value) + '</td>';
                return;
            }

            h += '<td class="p-3 whitespace-nowrap">' + esc(value == null ? '—' : value) + '</td>';
        });

        var drillHtml = '—';
        if (row.order_link && row.order_link.order_code) {
            drillHtml = drillButton('order', row.order_link.order_code, 'فتح الأوردر');
        } else if (row.journal_entry_id) {
            drillHtml = drillButton('journal', row.journal_entry_id, 'فتح القيد');
        } else if (row.voucher_id && /^IN-/.test(String(row.voucher_id))) {
            drillHtml = drillButton('voucher', row.voucher_id, 'فتح الإذن');
        } else if (row.reference || row.voucher_id) {
            drillHtml = '<button type="button" class="text-slate-600 font-black hover:underline" data-copy-value="' +
                esc(row.reference || row.voucher_id) + '">نسخ المرجع</button>';
        }

        h += '<td class="p-3">' + drillHtml + '</td></tr>';
    });

    h += '</tbody></table></div></div>';
    return h;
}
~~~

**لا تعدل `runSovereignReport()`**؛ هو بالفعل يرسل `state.activeKey` إلى `detailed_reports_read`، وبالتالي التقريرين الجديدين يعبران عبر نفس الـRPC.

---

## 12. ملفات Production التي أصبحت Canonical في Git

1. `supabase/migrations/20260920034711_detailed_reports_competitive_analytics_extension_20260920.sql`
2. `supabase/migrations/20260920034844_detailed_reports_abc_single_item_classification_fix_20260920.sql`
3. `supabase/migrations/20260920034931_detailed_reports_logistics_driver_vehicle_context_20260920.sql`

هذه الملفات تطابق تسلسل migrations المسجل حاليًا في Supabase.

---

## 13. Self-Audit

### What I Proved
- Production RPC exists and executes.
- New report keys execute.
- Existing five keys still execute.
- ABC one-item defect was found by E2E and fixed.
- Logistics report consumes the real field workflow.
- Mother's old tab-navigation defect is already closed and was not repeated.
- No new Edge Function was created.
- Synthetic E2E rows were rolled back.

### What I Did Not Prove
- Browser UI for the two new tabs after Owner applies the Mother patch.
- True On-Time delivery KPI.
- Batch/Lot/Serial traceability.
- Historical cost-layer valuation.
- Production variance.
- Full customer/supplier aging allocation.

### What I Fixed
- Added `inventory_abc`.
- Added `logistics_performance`.
- Fixed single-item ABC classification.
- Added driver/vehicle human-readable context to logistics output.

### What Could Still Be Wrong
- The Owner may paste the Mother patch into an older/other blob. The patch must be applied to current `main.html` blob `5a628da...`.
- Browser-only behavior remains unverified until the Owner applies the source patch.

### Final Closure
**Production backend closure: CLOSED.**
**Mother source/UI closure for the new tabs: OWNER PATCH REQUIRED.**
**Detailed Reports overall browser closure: NOT YET 100% CLOSED until the Owner applies the exact patches and performs browser E2E.**

---

## 14. تعليمات بدء الجلسة التالية

ابدأ دائمًا بهذا الترتيب:
1. fetch CURRENT_STATE.
2. fetch latest System HEAD + parent.
3. fetch latest Mother HEAD + parent + current `main.html` blob.
4. query Production counts and current `detailed_reports_read` definition.
5. do not reopen Report262 navigation closure.
6. verify whether the Owner applied Patch A–E.
7. if applied: browser/E2E closure only; لا تعد بناء الـRPC.
8. if not applied: apply the exact surgical Mother patch from this report.
9. after browser closure، انتقل إلى أول Business Contract مفتوح، وليس إلى إعادة بناء ما تم إغلاقه.
10. لا تستخدم أي تقرير قديم كحقيقة حالية؛ هو evidence/history فقط.

