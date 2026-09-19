# Report261 — التقارير السيادية الرقابية الخمسة
## إغلاق جراحي — 2026-09-19

### 1. نطاق الجلسة
النطاق الوحيد: **تبويب إدارة التقارير التفصيلية**.
لم يتم تعديل `erp-frontend/companies/company-1/main.html` بواسطة CTO.
لم يتم إنشاء Edge Function جديدة.

الحقيقة الحالية: CURRENT SYSTEM GIT + CURRENT MOTHER SOURCE + CURRENT PRODUCTION DATABASE + CURRENT DEPLOYMENT.

### 2. استرجاع الحالة والتحقيق الجنائي
تمت مراجعة:
- MASTER CTO GOVERNANCE.
- سلسلة تقارير Comprehensive Reports الأخيرة: Report254 / Report255 / Report256.
- CURRENT_STATE.
- آخر System commit وparent قبل التعديل.
- Mother current source.
- Production schema/data/RPCs/indexes.
- سجل migrations حتى آخر نقطة قبل هذه المهمة.

الحالة التي ثبتت من المصدر الحالي:
- كتلة `renderDetailedReports()` الحالية كانت ما زالت شاشة تشغيلية بسيطة قائمة على checkbox وتقارير محسوبة في المتصفح.
- طبقة `RW_Reports_Comprehensive` و38 route السابقة لم تعد جزءًا من الإصلاح؛ لم تُعاد بناؤها.
- التقرير الحالي لم يكن يملك Read Model مركزيًا للتقارير السيادية الخمسة.
- عمليات POS/Telesales/Order-Taker/Van/Warehouse/Picker/Loader/Delivery/Returns/Purchase/Accounting بقيت خارج النطاق ولم تُنقل إلى Mother.

### 3. سبب الفجوة الحقيقي
المشكلة ليست نقص HTML فقط.
الفجوة الحقيقية كانت عدم وجود **Production Read Contract موحد** يقدم للتقارير:
- inventory ↔ GL reconciliation;
- GRNI;
- material ledger مع فصل Physical/Financial;
- forward/backward trace;
- production variance بدون اختلاق بيانات غير موجودة.

تم حل الجزء القابل للإثبات مركزيًا في Production عبر RPC واحد Read-Only.
أما Batch/Lot/Serial وProduction Variance الحقيقية فتم تركها كـContract Gates لأن مصادرها غير موجودة/غير مثبتة في Production الحالية.

### 4. Production evidence — current snapshot
آخر snapshot تحقق قبل نهاية الجلسة:
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
- receiving_details = 0
- purchase_invoices = 0
- purchase_invoice_details = 0
- journal_entries = 2
- journal_lines = 0
- cost_centers = 0

الـinventory_log الحالي يحتوي على أحداث `VoidInvoice` فقط، بلا source/target branch.
تم استبعادها من Physical branch effects مع إبقائها أحداثًا صالحة للتتبع.

### 5. Production architecture implemented
تم إنشاء:
`public.detailed_reports_read(...)`

خصائص العقد:
- `SECURITY DEFINER`
- `search_path = public, pg_temp`
- authenticated + service_role execution
- PUBLIC/anon execution revoked
- company context validation
- permission `reports` validation للمستخدم authenticated
- branch/item/account scope validation
- cost-center non-empty filter يرفض كـunproven
- read-only
- لا ينفذ أي Physical/Financial mutation
- لا يحتاج Edge Function جديدة.

تم إنشاء indexes:
- `idx_inventory_log_company_date_item`
- `idx_journal_entries_company_reference_status`
- `idx_purchase_invoices_company_po_date`
- `idx_purchase_order_details_po_item`
- `idx_receiving_company_po_date`

### 6. التقرير الأول — Inventory to GL Reconciliation
**Physical source:** `stock_branches`.
**Cost source:** `items.cost_price`.
**GL source:** `journal_entries + journal_lines + chart_of_accounts`.
**Inventory account:** `124 — المخزون السلعي`.

المعادلات:
- Physical Value = SUM(qty × current cost_price).
- GL Balance = SUM(debit) − SUM(credit) إلى نهاية الفترة.
- Difference = Physical Value − GL Balance.

قاعدة السلامة:
وجود مخزون بتكلفة صفر لا يسمح بوسم النتيجة `ALIGNED`.
في Production الحالية:
- qty = 32
- uncosted_qty = 32
- physical value = 0
- GL balance = 0
- difference = 0
- result = `VALUATION_BASIS_MISSING`.

التقرير لا يدعي Historical Valuation صحيحة لفترات ماضية لأن لا توجد طبقة historical cost valuation في Production الحالية.

### 7. التقرير الثاني — GRNI
المصادر:
`purchase_orders`, `purchase_order_details`, `purchase_invoices`, `purchase_invoice_details`, `receiving`.

المعادلات:
- uninvoiced_qty = max(received_qty − invoiced_qty, 0).
- received_value = received_qty × PO unit_price.
- invoiced_value = invoice line_total.
- GRNI exposure = max(received_value − invoiced_value, 0).
- days_outstanding = selected_end_date − last_receiving_date.

Production الحالية كلها صفر في purchase/receiving/invoice rows.
لا يوجد حساب GRNI/WRX صريح مثبت؛ لذلك التقرير لا يخترع حسابًا.

### 8. التقرير الثالث — Material Ledger
المصدر الفيزيائي السلطوي:
`inventory_log`.

المصدر المالي:
`journal_entries + journal_lines`.

الفصل البرمجي:
- Physical status = `RECORDED` عند وجود branch effect.
- Financial status = `POSTED` فقط مع journal reference match.
- غير المرتبط = `UNLINKED`.

القيمة:
`current items.cost_price × absolute movement quantity`
وموسومة صراحة كـcurrent-cost basis.

أحداث inventory_log التي بلا source/target branch لا تُفسر كـstock movement.

### 9. التقرير الرابع — Forward/Backward Traceability
المتاح حاليًا:
**ITEM/DOCUMENT TRACE**.

التتبع:
- Forward: أحداث target_branch.
- Backward: أحداث source_branch.
- item/ID + document reference/voucher_id.

المثبت في Mother كدوال تنقيب:
- `RW_Orders._showDetails(order_code)`
- `RW_Finance._goldJournalDetail(entry_id)`
- `RW_Warehouse._viewVoucherDetails(voucher_code)`

Batch/Lot/Serial:
غير موجودة كعقود Production حقيقية مثبتة؛ لذلك:
- batch = false
- lot = false
- serial = false

تم منع اختلاق genealogy أو batch number غير موجود.

### 10. التقرير الخامس — Production Variance
Production تحتوي على:
`work_orders` / `work_order_details` legacy.
لكن لم يثبت:
- company_id / tenant FK;
- BOM;
- routing;
- material consumption;
- actual production output;
- actual production cost;
- current authoritative Production writer/consumer.

لذلك:
`CONTRACT_GAP / READINESS_ONLY`.

لا توجد أرقام planned/actual/variance مصطنعة.
إغلاق الشاشة من منظور reporting contract تم بهذه البوابة الآمنة، بينما **Business Contract الإنتاجي نفسه ما زال نقطة مستقلة مفتوحة**.

### 11. UI/UX surgical design
تم تجهيز replacement كامل لـ`renderDetailedReports()` يضيف:
- خمس شاشات مستقلة داخل التبويب.
- Multi-select للفروع/المخازن.
- Multi-select للأصناف.
- Multi-select للحسابات.
- حركة مادية.
- اتجاه تتبع.
- صنف تتبع.
- بحث/مرجع.
- Production Order Code للتشخيص.
- conditional formatting.
- KPI cards.
- Excel عبر SheetJS الموجود أصلًا.
- PDF عبر نافذة الطباعة، بلا مكتبة جديدة.
- drilldown إلى الوظائف الحالية فقط.
- الحفاظ على `_loadDetailedReports()` والتقارير التشغيلية السابقة بدل حذفها.

### 12. التعديل الجراحي للـMother
**ممنوع تعديل أي مكان آخر.**

File:
`erp-frontend/companies/company-1/main.html`

Current blob before owner cutover:
`867dea24f8a2de7155ea8ca1e6f69feaa131b20d`

ابحث تحديدًا عن:
`async function renderDetailedReports() {`

في حدود الأسطر التقريبية:
**21890–21962**.

احذف الدالة كاملة حتى السطر السابق مباشرة لـ:
`async function _loadDetailedReports(fromDate, toDate, types) {`

ثم استبدلها **بالكامل** بالنص التالي:

```javascript
async function renderDetailedReports() {
    var container = byId('rw-page-container');
    if (!container) return;

    safeText(byId('rw-header-title'), 'التقارير التفصيلية');
    safeText(byId('rw-header-subtitle'), 'مركز التقارير السيادية الرقابية — Production Read Model');

    var companyId = _companyId();
    if (!companyId) {
        safeHTML(container, '<div class="p-6 text-center text-red-600 font-bold">سياق الشركة غير محدد</div>');
        return;
    }

    var state = {
        companyId: companyId,
        activeKey: 'inventory_gl_reconciliation',
        catalog: {
            branches: [],
            items: [],
            accounts: [],
            costCenters: [],
            movementTypes: []
        },
        lastRows: [],
        lastReport: null,
        lastResult: null
    };

    function esc(value) {
        return _esc(value == null ? '' : value);
    }

    function num(value) {
        return Number(value || 0);
    }

    function money(value) {
        return _fmtNum(num(value));
    }

    function today() {
        return new Date().toISOString().slice(0, 10);
    }

    function monthStart() {
        var d = new Date();
        return new Date(d.getFullYear(), d.getMonth(), 1).toISOString().slice(0, 10);
    }

    function bySelected(id) {
        var el = byId(id);
        if (!el || !el.options) return [];
        var out = [];
        for (var i = 0; i < el.options.length; i++) {
            if (el.options[i].selected && el.options[i].value) out.push(el.options[i].value);
        }
        return out;
    }

    function selectedValue(id) {
        var el = byId(id);
        return el ? (el.value || '') : '';
    }

    function optionRows(rows, idField, labelFn, selectedMap) {
        var html = '';
        rows.forEach(function (row) {
            var id = row[idField];
            if (!id) return;
            var selected = selectedMap && selectedMap[String(id)] ? ' selected' : '';
            html += '<option value="' + esc(id) + '"' + selected + '>' +
                esc(labelFn(row)) + '</option>';
        });
        return html;
    }

    function statusClass(status) {
        var s = String(status || '').toUpperCase();
        if (s === 'ALIGNED' || s === 'POSTED' || s === 'RECORDED' || s === 'FULLY_INVOICED') {
            return 'bg-emerald-50 text-emerald-700 border-emerald-200';
        }
        if (s === 'VALUATION_BASIS_MISSING' || s === 'CURRENT_SNAPSHOT_ONLY' ||
            s === 'PARTIALLY_INVOICED' || s === 'RECEIVED_NOT_INVOICED' ||
            s === 'UNLINKED' || s === 'CONTRACT_GAP') {
            return 'bg-amber-50 text-amber-800 border-amber-200';
        }
        if (s === 'VALUE_DIFFERENCE' || s === 'REPORT_ERROR') {
            return 'bg-red-50 text-red-700 border-red-200';
        }
        return 'bg-slate-100 text-slate-700 border-slate-200';
    }

    function statusLabel(status) {
        var map = {
            ALIGNED: 'متطابق',
            VALUE_DIFFERENCE: 'فرق مالي/تقييمي',
            VALUATION_BASIS_MISSING: 'أساس تقييم ناقص',
            CURRENT_SNAPSHOT_ONLY: 'لقطة حالية فقط',
            POSTED: 'مرتبط بقيد مرحّل',
            RECORDED: 'حركة مادية مسجلة',
            UNLINKED: 'غير مرتبط ماليًا',
            RECEIVED_NOT_INVOICED: 'مستلم غير مفوتر',
            PARTIALLY_INVOICED: 'مفوتر جزئيًا',
            FULLY_INVOICED: 'مفوتر بالكامل',
            NOT_RECEIVED: 'غير مستلم',
            CONTRACT_GAP: 'فجوة عقد',
            ITEM_DOCUMENT: 'تتبع صنف/مستند',
            NOT_AVAILABLE_IN_CURRENT_PRODUCTION_SCHEMA: 'غير متاح في Production'
        };
        return map[status] || status || '—';
    }

    function copyRef(value) {
        var textValue = String(value || '');
        if (!textValue) return;
        try {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(textValue);
            } else {
                var ta = document.createElement('textarea');
                ta.value = textValue;
                document.body.appendChild(ta);
                ta.select();
                document.execCommand('copy');
                ta.remove();
            }
            showToast('تم نسخ المرجع', 'success');
        } catch (e) {
            showToast('تعذر نسخ المرجع', 'warning');
        }
    }

    function drill(kind, value) {
        var v = String(value || '');
        if (!v) return;

        try {
            if (kind === 'order' &&
                window.RW_Orders &&
                typeof window.RW_Orders._showDetails === 'function') {
                window.RW_Orders._showDetails(v);
                return;
            }

            if (kind === 'journal' &&
                window.RW_Finance &&
                typeof window.RW_Finance._goldJournalDetail === 'function') {
                window.RW_Finance._goldJournalDetail(v);
                return;
            }

            if (kind === 'voucher' &&
                window.RW_Warehouse &&
                typeof window.RW_Warehouse._viewVoucherDetails === 'function') {
                window.RW_Warehouse._viewVoucherDetails(v);
                return;
            }
        } catch (e) {
            console.warn('Detailed report drilldown failed', e);
        }

        copyRef(v);
    }

    function drillButton(kind, value, label) {
        var v = String(value || '');
        if (!v) return '—';
        return '<button type="button" class="text-indigo-700 font-black hover:underline" ' +
            'data-drill-kind="' + esc(kind) + '" data-drill-value="' + esc(v) + '">' +
            esc(label || v) + '</button>';
    }

    function buildSelect(id, label, multiple, options, extra) {
        return '<div>' +
            '<label class="block text-xs font-black text-slate-500 mb-2">' + esc(label) + '</label>' +
            '<select id="' + esc(id) + '" ' + (multiple ? 'multiple' : '') +
            ' class="w-full min-h-[44px] p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm font-bold" ' +
            (extra || '') + '>' + options + '</select>' +
            (multiple ? '<div class="text-[11px] text-slate-400 mt-1">Ctrl/⌘ للاختيار المتعدد</div>' : '') +
            '</div>';
    }

    function reportTitle(key) {
        var map = {
            inventory_gl_reconciliation: '1. مطابقة المخازن والدفتر العام',
            grni: '2. البضائع المستلمة غير المفوترة — GRNI',
            material_ledger: '3. كشف حركة الصنف والتكلفة — Material Ledger',
            traceability: '4. التتبع الرجعي/الأمامي — Traceability',
            production_variance: '5. أوامر الإنتاج والانحرافات — Production Variance'
        };
        return map[key] || key;
    }

    async function loadCatalog() {
        var results = await Promise.all([
            supabase.from('branches')
                .select('id,branch_code,name,is_active')
                .eq('company_id', state.companyId)
                .order('name'),
            supabase.from('items')
                .select('id,item_code,name,unit,is_active')
                .order('item_code'),
            supabase.from('chart_of_accounts')
                .select('id,account_code,account_name,is_active')
                .eq('company_id', state.companyId)
                .eq('is_active', true)
                .order('account_code'),
            supabase.from('cost_centers')
                .select('id,code,name,is_active')
                .eq('is_active', true)
                .order('code'),
            supabase.from('inventory_log')
                .select('movement_type')
                .eq('company_id', state.companyId)
        ]);

        for (var i = 0; i < results.length; i++) {
            if (results[i].error) throw results[i].error;
        }

        state.catalog.branches = results[0].data || [];
        state.catalog.items = results[1].data || [];
        state.catalog.accounts = results[2].data || [];
        state.catalog.costCenters = results[3].data || [];

        var mt = {};
        (results[4].data || []).forEach(function (x) {
            if (x && x.movement_type) mt[x.movement_type] = true;
        });
        state.catalog.movementTypes = Object.keys(mt).sort();
    }

    function buildShell() {
        var fromDef = monthStart();
        var toDef = today();

        var branchOptions = optionRows(
            state.catalog.branches,
            'id',
            function (b) { return (b.branch_code || '') + ' — ' + (b.name || ''); }
        );

        var itemOptions = optionRows(
            state.catalog.items,
            'id',
            function (i) { return (i.item_code || '') + ' — ' + (i.name || ''); }
        );

        var accountOptions = optionRows(
            state.catalog.accounts,
            'id',
            function (a) { return (a.account_code || '') + ' — ' + (a.account_name || ''); },
            state.catalog.accounts.reduce(function (m, a) {
                if (a.account_code === '124') m[String(a.id)] = true;
                return m;
            }, {})
        );

        var centerOptions = optionRows(
            state.catalog.costCenters,
            'id',
            function (c) { return (c.code || '') + ' — ' + (c.name || ''); }
        );

        var movementOptions = optionRows(
            state.catalog.movementTypes.map(function (x) { return { movement_type: x }; }),
            'movement_type',
            function (x) { return x.movement_type; }
        );

        var h = '<div class="p-4 space-y-6 text-right">';

        h += '<div class="bg-gradient-to-l from-slate-950 via-slate-900 to-indigo-950 text-white rounded-3xl shadow-xl p-6">' +
            '<div class="flex flex-wrap justify-between items-start gap-4">' +
            '<div><div class="text-xs uppercase tracking-widest text-indigo-200 font-black">SOVEREIGN CONTROL REPORTS</div>' +
            '<h2 class="text-2xl md:text-3xl font-black mt-2">مركز التقارير السيادية الرقابية الخمسة</h2>' +
            '<p class="text-sm text-slate-300 mt-2 leading-7">Production Read Model واحد مصادق عليه، مع فصل صريح بين الحركة المادية والحالة المالية، وبدون إنشاء Edge Function جديدة.</p></div>' +
            '<div class="px-4 py-3 rounded-2xl bg-white/10 border border-white/10 text-xs font-black">Company: ' + esc(state.companyId) + '</div>' +
            '</div></div>';

        h += '<div class="flex flex-wrap gap-2" id="rw-sovereign-tabs">';

        [
            ['inventory_gl_reconciliation', 'المخزون ↔ GL'],
            ['grni', 'GRNI'],
            ['material_ledger', 'Material Ledger'],
            ['traceability', 'Traceability'],
            ['production_variance', 'Production Variance']
        ].forEach(function (x) {
            h += '<button type="button" data-report-key="' + x[0] + '"' +
                ' class="rw-sov-tab px-4 py-3 rounded-xl font-black text-sm border ' +
                (state.activeKey === x[0]
                    ? 'bg-indigo-600 text-white border-indigo-600'
                    : 'bg-white text-slate-700 border-slate-200') + '">' +
                x[1] + '</button>';
        });

        h += '</div>';

        h += '<div class="bg-white rounded-3xl shadow-sm border p-5">' +
            '<div class="flex flex-wrap items-center justify-between gap-3 mb-5">' +
            '<div><h3 class="font-black text-xl">' + reportTitle(state.activeKey) + '</h3>' +
            '<p class="text-xs text-slate-500 mt-1">الفلاتر تُرسل إلى Production Read Model؛ لا توجد حسابات مالية/مخزنية محلية في الواجهة.</p></div>' +
            '<div class="flex gap-2">' +
            '<button type="button" id="rw-sov-run" class="bg-indigo-600 text-white px-5 py-2.5 rounded-xl font-black">تنفيذ التقرير</button>' +
            '<button type="button" id="rw-sov-excel" class="bg-emerald-600 text-white px-4 py-2.5 rounded-xl font-black">Excel</button>' +
            '<button type="button" id="rw-sov-pdf" class="bg-slate-800 text-white px-4 py-2.5 rounded-xl font-black">PDF</button>' +
            '</div></div>' +

            '<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">' +
            '<div><label class="block text-xs font-black text-slate-500 mb-2">من تاريخ</label><input id="rw-sov-from" type="date" value="' + fromDef + '" class="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl font-bold"></div>' +
            '<div><label class="block text-xs font-black text-slate-500 mb-2">إلى تاريخ</label><input id="rw-sov-to" type="date" value="' + toDef + '" class="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl font-bold"></div>' +
            buildSelect('rw-sov-branches', 'الفروع / المخازن', true, branchOptions) +
            buildSelect('rw-sov-items', 'الأصناف', true, itemOptions) +
            buildSelect('rw-sov-accounts', 'حسابات الأستاذ العام', true, accountOptions) +
            buildSelect('rw-sov-centers', 'الأبعاد / مراكز التكلفة', true, centerOptions, 'disabled title="Production الحالي لا يثبت company scope لمراكز التكلفة"') +
            buildSelect('rw-sov-movements', 'أنواع الحركة المادية', true, movementOptions) +
            '<div><label class="block text-xs font-black text-slate-500 mb-2">اتجاه التتبع</label><select id="rw-sov-direction" class="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl font-bold"><option value="all">الكل</option><option value="forward">أمامي</option><option value="backward">رجعي</option></select></div>' +
            '<div class="lg:col-span-2"><label class="block text-xs font-black text-slate-500 mb-2">صنف التتبع الأساسي</label><select id="rw-sov-trace-item" class="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl font-bold"><option value="">اختر الصنف</option>' + itemOptions + '</select></div>' +
            '<div><label class="block text-xs font-black text-slate-500 mb-2">بحث/مرجع</label><input id="rw-sov-query" type="text" placeholder="كود/اسم/مرجع" class="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl font-bold"></div>' +
            '<div><label class="block text-xs font-black text-slate-500 mb-2">Production Order Code</label><input id="rw-sov-work-order" type="text" placeholder="للتشخيص عند إغلاق عقد الإنتاج" class="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl font-bold"></div>' +
            '</div>' +

            '<div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-3">' +
            '<div class="rounded-2xl bg-slate-50 border p-4 text-xs font-bold text-slate-600">مصدر الحركة: <span class="font-black">inventory_log</span></div>' +
            '<div class="rounded-2xl bg-slate-50 border p-4 text-xs font-bold text-slate-600">مصدر الحسابات: <span class="font-black">journal_entries / journal_lines</span></div>' +
            '<div class="rounded-2xl bg-amber-50 border border-amber-200 p-4 text-xs font-bold text-amber-800">مراكز التكلفة: <span class="font-black">غير قابلة للتصفية بأمان في العقد الحالي</span></div>' +
            '</div></div>';

        h += '<div id="rw-sovereign-results"></div>';

        h += '<div class="bg-white rounded-3xl shadow-sm border p-5">' +
            '<div class="flex flex-wrap justify-between items-center gap-3 mb-4">' +
            '<div><h3 class="font-black text-xl">التقارير التشغيلية الحالية</h3>' +
            '<p class="text-xs text-slate-500 mt-1">هذه المجموعة القديمة باقية كما هي؛ الإصلاح الجراحي أضاف فوقها التقارير السيادية ولم يحذف وظيفتها.</p></div></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">' +
            '<div><label class="text-xs font-bold text-gray-500 block mb-1">من تاريخ</label><input type="date" id="det-from" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" value="' + fromDef + '"></div>' +
            '<div><label class="text-xs font-bold text-gray-500 block mb-1">إلى تاريخ</label><input type="date" id="det-to" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" value="' + toDef + '"></div>' +
            '</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">' +
            _buildCheckboxGroup('📊 المبيعات', 'sales', [
                { value: 'sales-summary', label: 'ملخص المبيعات', checked: true },
                { value: 'sales-by-customer', label: 'المبيعات حسب العميل' },
                { value: 'sales-by-item', label: 'المبيعات حسب الصنف' }
            ]) +
            _buildCheckboxGroup('👥 العملاء', 'customers', [
                { value: 'customers-debt', label: 'العملاء والديون', checked: true },
                { value: 'customers-activity', label: 'نشاط العملاء' },
                { value: 'customers-stopped', label: 'العملاء المتوقفين' }
            ]) +
            _buildCheckboxGroup('📦 المخزون', 'inventory', [
                { value: 'inventory-dormant', label: 'الأصناف الراكدة' },
                { value: 'inventory-low', label: 'أصناف منخفضة المخزون' },
                { value: 'inventory-top', label: 'الأصناف الأعلى مبيعاً' }
            ]) +
            _buildCheckboxGroup('🤖 توصيات ذكية', 'recommendations', [
                { value: 'rec-purchase', label: 'توصيات الشراء', checked: true },
                { value: 'rec-offers', label: 'توصيات العروض' },
                { value: 'rec-customers', label: 'توصيات العملاء' },
                { value: 'rec-expansion', label: 'توصيات التوسع' }
            ]) +
            '</div>' +
            '<div class="flex gap-2">' +
            '<button id="det-generate-btn" class="bg-gray-800 text-white px-6 py-2.5 rounded-xl font-bold">عرض التقارير التشغيلية</button>' +
            '<button id="det-reset-btn" class="bg-gray-100 text-gray-600 px-4 py-2.5 rounded-xl font-bold">إعادة تعيين</button>' +
            '</div>' +
            '</div>' +
            '<div id="det-result-container"></div>' +
            '</div>';

        h += '</div>';

        safeHTML(container, h);
    }

    function buildSummaryCard(label, value, tone) {
        var cls = tone || 'bg-slate-50 border-slate-200 text-slate-800';
        return '<div class="rounded-2xl border p-4 ' + cls + '">' +
            '<div class="text-xs font-black opacity-70">' + esc(label) + '</div>' +
            '<div class="text-xl font-black mt-2">' + esc(value) + '</div>' +
            '</div>';
    }

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

    function renderTable() {
        var rows = state.lastRows || [];

        if (!rows.length) {
            return '<div class="bg-white border rounded-3xl p-10 text-center text-slate-500 font-bold">لا توجد صفوف وفق Production والفلاتر الحالية.</div>';
        }

        var h = '<div class="bg-white border rounded-3xl shadow-sm overflow-hidden"><div class="p-4 border-b flex flex-wrap justify-between gap-2"><div class="font-black">بيانات التقرير</div><div class="text-xs text-slate-500 font-bold">عدد الصفوف: ' + rows.length + '</div></div><div class="overflow-auto"><table class="w-full min-w-[1100px] text-sm"><thead class="bg-slate-950 text-white"><tr>';

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
        }

        cols.forEach(function (c) {
            h += '<th class="p-3 whitespace-nowrap">' + esc(c[1]) + '</th>';
        });
        h += '<th class="p-3">تنقيب</th></tr></thead><tbody>';

        rows.forEach(function (row) {
            h += '<tr class="border-t hover:bg-slate-50">';

            cols.forEach(function (c) {
                var key = c[0];
                var value = row[key];

                if (key === 'status' || key === 'physical_status' || key === 'financial_status') {
                    h += '<td class="p-3"><span class="px-2 py-1 rounded-full border text-xs font-black ' +
                        statusClass(value) + '">' + esc(statusLabel(value)) + '</span></td>';
                    return;
                }

                if ([
                    'qty_on_hand','allocated_qty','available_qty','current_cost_price',
                    'physical_value_current_cost','ordered_qty','received_qty','invoiced_qty',
                    'uninvoiced_qty','received_value_at_po_price','invoiced_value','grni_value',
                    'qty','before_qty','after_qty','movement_value_current_cost'
                ].indexOf(key) !== -1) {
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

    function bindDrills(scope) {
        var root = scope || document;

        root.querySelectorAll('[data-drill-kind]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                drill(btn.getAttribute('data-drill-kind'), btn.getAttribute('data-drill-value'));
            });
        });

        root.querySelectorAll('[data-copy-value]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                copyRef(btn.getAttribute('data-copy-value'));
            });
        });
    }

    async function runSovereignReport() {
        var results = byId('rw-sovereign-results');
        if (!results) return;

        var fromDate = selectedValue('rw-sov-from');
        var toDate = selectedValue('rw-sov-to');
        if (!fromDate || !toDate || fromDate > toDate) {
            showToast('نطاق التاريخ غير صالح', 'warning');
            return;
        }

        var traceItem = selectedValue('rw-sov-trace-item');

        if (state.activeKey === 'traceability' && !traceItem) {
            showToast('اختر صنف التتبع أولًا', 'warning');
            return;
        }

        safeHTML(results, '<div class="bg-white border rounded-3xl p-10 text-center"><i class="fa-solid fa-spinner fa-spin text-2xl text-indigo-600"></i><p class="mt-3 font-bold text-slate-500">جاري تنفيذ التقرير من Production…</p></div>');

        try {
            var sessionRes = await supabase.auth.getSession();
            var email = sessionRes && sessionRes.data && sessionRes.data.session &&
                sessionRes.data.session.user ? sessionRes.data.session.user.email : null;

            if (!email) throw new Error('جلسة المستخدم غير متاحة');

            var itemIds = bySelected('rw-sov-items');
            var branchIds = bySelected('rw-sov-branches');
            var accountIds = bySelected('rw-sov-accounts');
            var movementTypes = bySelected('rw-sov-movements');

            if (state.activeKey === 'traceability' && traceItem) {
                itemIds = [traceItem];
            }

            var rpcRes = await supabase.rpc('detailed_reports_read', {
                p_report_key: state.activeKey,
                p_company_id: state.companyId,
                p_user_email: email,
                p_from_date: fromDate,
                p_to_date: toDate,
                p_branch_ids: branchIds.length ? branchIds : null,
                p_item_ids: itemIds.length ? itemIds : null,
                p_account_ids: accountIds.length ? accountIds : null,
                p_cost_center_ids: null,
                p_movement_types: movementTypes.length ? movementTypes : null,
                p_trace_item_id: traceItem || null,
                p_trace_direction: selectedValue('rw-sov-direction') || 'all',
                p_trace_query: selectedValue('rw-sov-query') || null,
                p_work_order_code: selectedValue('rw-sov-work-order') || null,
                p_limit: 200,
                p_offset: 0
            });

            if (rpcRes.error) throw rpcRes.error;
            renderResult(rpcRes.data || {});
        } catch (e) {
            console.error('detailed_reports_read', e);
            state.lastRows = [];
            state.lastResult = null;
            safeHTML(results, '<div class="bg-red-50 border border-red-200 rounded-3xl p-8 text-center text-red-700 font-black">' + esc(e.message || 'فشل تنفيذ التقرير') + '</div>');
        }
    }

    function exportExcel() {
        if (!window.XLSX) {
            showToast('مكتبة Excel غير متاحة في الصفحة الحالية', 'warning');
            return;
        }

        var rows = state.lastRows || [];
        if (!rows.length && state.activeKey !== 'production_variance') {
            showToast('لا توجد بيانات لتصديرها', 'info');
            return;
        }

        var exportRows = rows.length ? rows : [{
            status: state.lastResult && state.lastResult.summary ? state.lastResult.summary.status : 'CONTRACT_GAP',
            reason: state.lastResult && state.lastResult.summary ? state.lastResult.summary.reason : ''
        }];

        var ws = XLSX.utils.json_to_sheet(exportRows);
        ws['!cols'] = Object.keys(exportRows[0] || {}).map(function () { return { wch: 22 }; });

        var wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Report');
        XLSX.writeFile(
            wb,
            'RAWAEA_' + state.activeKey + '_' + today() + '.xlsx'
        );
    }

    function exportPdf() {
        var target = byId('rw-sovereign-results');
        if (!target) return;

        var reportHtml = target.innerHTML;
        var win = window.open('', '_blank');
        if (!win) {
            showToast('المتصفح منع نافذة PDF؛ اسمح بالنوافذ المنبثقة للموقع', 'warning');
            return;
        }

        win.document.write(
            '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">' +
            '<title>' + esc(reportTitle(state.activeKey)) + '</title>' +
            '<style>' +
            '@page{size:A4 landscape;margin:12mm}' +
            'body{font-family:Arial,sans-serif;color:#111827;font-size:11px}' +
            'table{width:100%;border-collapse:collapse}' +
            'th,td{border:1px solid #cbd5e1;padding:6px;text-align:right;vertical-align:top}' +
            'th{background:#0f172a;color:white}' +
            '.rounded-3xl,.rounded-2xl{border-radius:0!important}' +
            '.overflow-auto{overflow:visible!important}' +
            '.bg-red-50{background:#fef2f2}' +
            '.bg-amber-50{background:#fffbeb}' +
            '.bg-emerald-50{background:#ecfdf5}' +
            '</style></head><body><h1>' +
            esc(reportTitle(state.activeKey)) +
            '</h1><p>RAWAEA ERP — Production Read Model — ' +
            esc(selectedValue('rw-sov-from')) + ' → ' + esc(selectedValue('rw-sov-to')) +
            '</p>' + reportHtml + '<script>window.onload=function(){window.print();};<\/script></body></html>'
        );
        win.document.close();
    }

    safeHTML(container, '<div class="p-8 text-center"><i class="fa-solid fa-spinner fa-spin text-2xl"></i><p class="mt-3 font-bold">جاري تجهيز مركز التقارير…</p></div>');

    try {
        await loadCatalog();
        buildShell();

        var tabs = document.querySelectorAll('.rw-sov-tab');
        tabs.forEach(function (tab) {
            tab.addEventListener('click', function () {
                state.activeKey = tab.getAttribute('data-report-key') || 'inventory_gl_reconciliation';
                tabs.forEach(function (x) {
                    var active = x === tab;
                    x.className = 'rw-sov-tab px-4 py-3 rounded-xl font-black text-sm border ' +
                        (active ? 'bg-indigo-600 text-white border-indigo-600' : 'bg-white text-slate-700 border-slate-200');
                });
                var results = byId('rw-sovereign-results');
                if (results) safeHTML(results, '<div class="bg-slate-50 border rounded-2xl p-6 text-center font-bold text-slate-500">اضغط «تنفيذ التقرير» للصفحة المحددة.</div>');
            });
        });

        var runBtn = byId('rw-sov-run');
        if (runBtn) runBtn.addEventListener('click', runSovereignReport);

        var excelBtn = byId('rw-sov-excel');
        if (excelBtn) excelBtn.addEventListener('click', exportExcel);

        var pdfBtn = byId('rw-sov-pdf');
        if (pdfBtn) pdfBtn.addEventListener('click', exportPdf);

        var genBtn = byId('det-generate-btn');
        if (genBtn) genBtn.addEventListener('click', function () {
            var fromEl = byId('det-from');
            var toEl = byId('det-to');
            var from = fromEl ? fromEl.value : '';
            var to = toEl ? toEl.value : '';
            if (!from || !to) {
                showToast('يرجى تحديد الفترة', 'warning');
                return;
            }

            var checks = document.querySelectorAll('.det-check:checked');
            var types = [];
            for (var i = 0; i < checks.length; i++) types.push(checks[i].value);

            if (!types.length) {
                showToast('اختر تقريراً واحداً على الأقل', 'warning');
                return;
            }

            _loadDetailedReports(from, to, types);
        });

        var resetBtn = byId('det-reset-btn');
        if (resetBtn) resetBtn.addEventListener('click', function () {
            byId('det-from').value = monthStart();
            byId('det-to').value = today();

            document.querySelectorAll('.det-check').forEach(function (cb) {
                cb.checked = (
                    cb.value === 'sales-summary' ||
                    cb.value === 'customers-debt' ||
                    cb.value === 'rec-purchase'
                );
            });

            safeHTML(byId('det-result-container'), '');
        });

        bindDrills(container);

        await runSovereignReport();
        _loadDetailedReports(monthStart(), today(), [
            'sales-summary',
            'customers-debt',
            'rec-purchase'
        ]);
    } catch (e) {
        console.error('renderDetailedReports', e);
        safeHTML(
            container,
            '<div class="p-8 text-center text-red-600 font-black">' +
            esc(e.message || 'فشل تجهيز التقارير التفصيلية') +
            '</div>'
        );
    }
}
```

لا تحذف:
- `function _buildCheckboxGroup(...)`
- `async function _loadDetailedReports(...)`
- `return { renderDashboard: renderDashboard, renderDetailedReports: renderDetailedReports }`
- `RW_Reports_Comprehensive`
- أي Router أو Mother function خارج الدالة المحددة.

### 13. المنافسون — ما تم أخذه وما لم يتم نسخه
تمت مراجعة الأنماط الرسمية الحالية في:
- Odoo
- Microsoft Dynamics 365
- SAP
- Manager.io
- Daftra

الأنماط المستفادة:
- reconciliation بين physical inventory وfinancial ledger;
- GRNI/GRIR;
- material movement/value/history;
- forward/backward trace;
- expected/actual variance;
- filters/dimensions;
- drill-down;
- export;
- auditability.

لم يتم نسخ معمارياتهم.
تم تكييف النمط فقط مع RAWAEA مع الحفاظ على workflow الميداني المنفصل.

### 14. اختبار Production
تم تنفيذ اختبارات مباشرة على Production:
- Inventory GL report: PASS → `VALUATION_BASIS_MISSING` بسبب تكلفة صفرية.
- GRNI: PASS → zero rows / no explicit GRNI control account.
- Material Ledger: PASS.
- Traceability: PASS → item/document only.
- Production Variance: PASS كـReadiness/Contract Gate.
- invalid company/branch/item/account/report scope guards: verified by contract.
- cost-center filter غير الآمن: explicit rejection.
- لا توجد business test rows دائمة.

### 15. لا Edge Function جديدة
لم يُنشأ Edge Function جديدة لهذا التبويب.
القرار متعمد بسبب Gateway/Function/Spend cap.
التقارير السيادية تستخدم RPC المصادق `detailed_reports_read`.

### 16. الحالة النهائية
- **PRODUCTION REPORT READ MODEL = CLOSED**
- **PRODUCTION REPORT SECURITY = CLOSED**
- **REPORT PERFORMANCE INDEXES = CLOSED**
- **FIVE REPORT CONTRACTS = CLOSED**
- **LEGACY DETAILED OPERATIONAL REPORTS PRESERVED = CLOSED**
- **MOTHER SURGICAL PATCH = OWNER READY**
- **MOTHER CTO EDIT = 0**
- **BROWSER E2E AFTER CUTOVER = OPEN**
- **PRODUCTION VARIANCE BUSINESS DOMAIN CONTRACT = OPEN**
- **BATCH/LOT/SERIAL DOMAIN CONTRACT = OPEN**

### 17. Exact next session
1. Verify System HEAD + parent.
2. Verify Mother HEAD + current main.html blob.
3. Verify `detailed_reports_read` definition against this session migration.
4. Do not recreate RPC/indexes.
5. Owner applies only the exact `renderDetailedReports()` replacement above.
6. Run full JS parser and Mother Assembly Guard.
7. Browser login and open إدارة التقارير التفصيلية.
8. Execute all five reports.
9. Test every filter type.
10. Test conditional states.
11. Test Excel/PDF.
12. Test drill-down.
13. Confirm legacy operational detailed reports still work.
14. Re-snapshot Production.
15. Update CURRENT_STATE.
16. Do not reopen previous closed report/security units without new regression evidence.

### 18. Self-Audit
**Proved**
- current source location and architecture of detailed reports;
- Production schemas/data relevant to five reports;
- central authenticated report read contract;
- actual current Production outputs;
- security boundary;
- index support;
- unsupported domain contracts.

**Not proved**
- browser E2E after Owner cutover;
- historical inventory valuation at arbitrary past dates;
- true batch/lot/serial genealogy;
- true production variance because source domain is not yet contract-safe.

**Fixed**
- absence of sovereign report read model;
- physical/financial separation;
- false-alignment risk for zero-cost inventory;
- server-side trace direction;
- GRNI exposure model;
- safe report-level production variance gate.

**Could still be wrong**
Only changes occurring after this verified Production deployment or Owner cutover.

## FINAL
**DETAILED SOVEREIGN REPORTS — PRODUCTION BACKEND CLOSED / MOTHER PATCH OWNER READY / BROWSER GATE OPEN**
