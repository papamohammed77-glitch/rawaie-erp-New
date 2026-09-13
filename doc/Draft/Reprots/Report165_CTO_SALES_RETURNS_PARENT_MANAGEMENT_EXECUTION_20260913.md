# تقرير 165 — تنفيذ Sales Returns Parent Management UI / Backend Closure

## 0. الرسالة الحاكمة — اقرأها أولًا

**النقطة الأهم هي أن الهدف النهائي لهذا الجزء هو اختبار E2E الحقيقي لملف النظام الأم الحالي المنشور:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهذا الملف وحده هو **Source of Truth** الحالي. لم أعدل هذا الملف بنفسي؛ تعديل Parent UI من اختصاص المالك، ولذلك تم تنفيذ Production/backend هنا مباشرة، وتم إعداد التعديل الجراحي الكامل للمالك في هذا التقرير.

الحالة التي اعتمدت عليها أثناء التنفيذ لم تُبنَ على أرقام التقارير القديمة؛ بدأت بمطابقة CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE. التقارير السابقة استُخدمت فقط كـpointer تاريخي.

**لا يوجد Browser E2E PASS في هذا التقرير.** عدم توفر authenticated browser automation موثوق يعني أن Source/Database/Deployment tests لا تتحول إلى Browser E2E.

---

## 1. CURRENT GIT — VERIFIED BEFORE EXECUTION

Repository:
`papamohammed77-glitch/erp-frontend`

Branch:
`main`

HEAD:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`

HEAD message:
`Refactor orderHeader creation with operation IDs`

Direct Parent:
`3573c92026557cb56a7782babe6f6cf690243072`

Direct Parent message:
`Update main.html`

Parent of Parent:
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

تمت مراجعة HEAD وDirect Parent وParent of Parent. الـHEAD يغير فقط `companies/company-1/main.html` في Operation Identity لـPOS/Telesales. لم تتم إعادة فتح هذه الجزئية.

Current Source blob قبل أي owner-side UI change:
`1cc6f17b8531a8353b28f89acdfde2e992774931`

---

## 2. CURRENT SOURCE FORENSICS

الملف الحالي يحتوي بالفعل على شاشة تشغيل المرتجعات الميدانية:
`RW_Warehouse.loadReturn()`

وتظل هذه الشاشة كما هي.

Route الحالي:
`if (view === 'return') { RW_Warehouse.loadReturn(); return; }`

هذا route يمثل Operational Returns وليس Parent Management.

الحكم الجراحي:
**لا نستبدل `loadReturn()` ولا ننقل التنفيذ الميداني إلى Parent.**

Parent Management الجديد هو طبقة رقابة وإدارة أعلى، تقرأ Credit Notes/Order Details/Run Sheet Details/Inventory Evidence، وتضيف مراجعة إدارية وحالة وتكليف وسجل أحداث.

وهذا يمنع خلط مسؤوليات التطبيقات الميدانية مع النظام الأم.

---

## 3. CURRENT PRODUCTION — WHAT WAS ACTUALLY VERIFIED

Supabase project:
`fiilmooggumokxanwiyx`

Facts directly checked:

- `credit_notes` موجود فعليًا ويدعم `company_id`, `order_id`, `runsheet_id`, `customer_id`, `total_amount`, `reason`, `status`, `created_by`, `operation_key`.
- `credit_notes.operation_key` موجود وعليه uniqueness contract ضمن الشركة.
- `items.item_code` عليه `UNIQUE` عالمي.
- `stock_branches(branch_id,item_id)` عليه `UNIQUE`.
- `receiving.operation_id` عليه `UNIQUE`.
- `audit_log` موجود.
- `stock_vouchers` عليه trigger تدقيق: `trg_audit_stock_vouchers` → `fn_audit_trigger()`.
- تم التحقق أن المستخدم المكلف بالصلاحيات يجب أن يكون Active داخل نفس الشركة.
- تم اختبار رفض مستخدم بلا صلاحية `return`، ورفضه النظام كما هو مطلوب.

الحالة الحالية بعد كل الاختبارات:
- `credit_notes = 0` persistent rows.
- `sales_return_reviews = 0` persistent rows.
- `sales_return_review_events = 0` persistent rows.

لا توجد بيانات اختبار متروكة في Production.

---

## 4. WHAT WAS IMPLEMENTED IN PRODUCTION

### 4.1 Management Review Header

تم إنشاء:
`public.sales_return_reviews`

المسؤوليات:
- ربط Credit Note واحد بحالة مراجعة إدارية واحدة.
- `open`
- `reviewing`
- `resolved`
- `disputed`
- `cancelled`
- assigned user داخل نفس الشركة.
- note / resolution.
- reviewed_by / reviewed_at.
- created_at / updated_at.

العلاقة:
`company_id → companies`
`credit_note_id → credit_notes`
`assigned_to → users`

Unique contract:
`(company_id, credit_note_id)`

### 4.2 Review Event History

تم إنشاء:
`public.sales_return_review_events`

المسؤولية:
حفظ التاريخ الإداري لكل تغيير في حالة المرتجع أو التكليف أو الملاحظة أو التسوية.

العلاقات:
`company_id → companies`
`review_id → sales_return_reviews`
`assigned_to → users`

### 4.3 Production RPC Contract

تم إنشاء/تثبيت:

`get_sales_return_management_summary`

`list_sales_return_management`

`get_sales_return_management_detail`

`save_sales_return_review`

كلها:
- `SECURITY DEFINER`
- `search_path = public`
- ممنوعة عن `PUBLIC`
- ممنوعة عن `anon`
- ممنوعة عن `authenticated`
- التنفيذ المباشر محصور في `service_role`
- Actor validation company-scoped
- Permission gate: `permissions contains '*' OR 'return'`

### 4.4 Edge Function

تم إنشاء ونشر:
`sales-return-management`

الإصدار الحالي:
`v2`

`verify_jwt = true`

Capabilities:
- `list`
- `summary`
- `detail`
- `review`
- `assignees`

Company context لا يأتي من Frontend input؛ يتم أخذه من `users` عن طريق `auth_id` للمستخدم المصادق عليه.

---

## 5. WHY THIS IS NOT A SECOND RETURNS ENGINE

تم عدم لمس `stock_branches` من Parent Management.

تم عدم تنفيذ Physical Stock Movement في أي RPC جديد.

تم عدم إعادة تنفيذ Return Movement من جديد.

العقد يبقى:

`Operational Return App`
`→ existing return execution`
`→ existing Credit/Inventory contracts`

بينما:

`Parent Management`
`→ read current return evidence`
`→ review / assign / resolve / dispute`
`→ administrative event history

وبالتالي لا يوجد محرك مخزون موازٍ ولا Dual Write للمرتجع الميداني.

---

## 6. TESTS — WHAT PASSED AND WHAT FAILED

### Test A — Summary/List empty Production

تم استدعاء:
`get_sales_return_management_summary`
و
`list_sales_return_management`

بـowner active داخل الشركة.

النتيجة:
PASS

القيمة الحالية صحيحة لأنها Production بالفعل لا تحتوي Credit Notes مستديمة.

### Test B — Transactional End-to-End Parent Management

داخل transaction واحدة فقط:
1. إنشاء Credit Note اختبارية.
2. إنشاء Review.
3. قراءة Detail.
4. قراءة List.
5. التحقق من Event History.
6. `ROLLBACK`.

النتيجة:
PASS

بعد الاختبار:
لا توجد صفوف اختبارية مستديمة.

### Test C — Authorization

تم الاختبار بمستخدم من شركة لا يحمل `return` permission.

النتيجة:
PASS — رفض التنفيذ برسالة:
`غير مصرح بإدارة المرتجعات`

### Test D — Production Function Presence

تم التحقق من وجود الـ4 RPCs وأنها `SECURITY DEFINER`.

النتيجة:
PASS

### Test E — Edge Deployment

تم نشر `sales-return-management` بنجاح.

النتيجة:
PASS — current deployed version = v2.

### Test F — Browser Click-by-Click E2E

لم يتم التنفيذ بسبب عدم توفر authenticated browser automation موثوق في هذه البيئة.

النتيجة:
**OPEN / NOT VERIFIED**

لا يوجد تزوير لـPASS.

---

## 7. FAILURE THAT OCCURRED DURING IMPLEMENTATION

أثناء أول نشر لدالة Summary حدث خطأ PL/pgSQL بسبب استخدام `r` كاسم record variable في نفس النطاق الذي ظهر فيه alias `r` لجدول `sales_return_reviews`.

تم تشخيص السبب مباشرة من تعريف Production، ثم إعادة بناء الدالة مع:
`v_kpi`
بدل alias المتعارض.

بعد ذلك أعيد الاختبار ونجح.

لم ينتج عن الفشل بيانات ناقصة أو بيانات اختبار متروكة.

هذا الخطأ أغلقناه كـclosure وليس كدين مفتوح.

---

## 8. CURRENT SOURCE MAPPING — USER-SIDE ONLY

**لا تعدل أي Fragment تاريخي.**

**لا تعدل:**
- `Current/PWA/main2/*`
- `Original/PWA/main/*`
- `Current/PWA/New-main`

**المطلوب تعديل الملف الوحيد:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

### التعديل 1 — Sales Management navigation

ابحث في `RW_Navigation.menuTree` عن **السطر الذي يحتوي حرفيًا** على:

`{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }] },`

في نسخة Current 2026-09-13 الحالية يظهر هذا الجزء قبل `RW_Views`، وهو ضمن بنية الملاحة وليس داخل `RW_Warehouse`.

احذف **السطر الكامل كما هو** واستبدله بالسطر التالي كاملًا:

`{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },`

لا تغيّر أي submenu آخر.

### التعديل 2 — Permission Map

ابحث داخل:
`var permissionMap = {`
في `RW_Views.render` عن السطر الكامل:

`'return': 'return',`

ضع **أسفله مباشرة**:

`'sales-returns': 'return',`

### التعديل 3 — Titles

ابحث داخل:
`var titles = {`
في `RW_Views.render` عن السطر الكامل:

`'return':'المرتجعات',`

ضع **أسفله مباشرة**:

`'sales-returns':'إدارة مرتجعات المبيعات',`

### التعديل 4 — Route

ابحث داخل `RW_Views.render` عن هذا المقطع الكامل:

`if (view === 'return') { RW_Warehouse.loadReturn(); return; }`

ضع **أسفله مباشرة**:

`if (view === 'sales-returns') { RW_SalesReturnsManagement.render(); return; }`

لا تحذف route `return`.

### التعديل 5 — إضافة Module كامل

ابحث عن **هذا التعليق الكامل** الذي يأتي بعد إغلاق وحدة `RW_CRM` وقبل قسم التشغيل النهائي:

`// ============================================================`
`// EVENTS & BOOT`
`// ============================================================`

**ضع الكود التالي كاملًا فوق هذا التعليق مباشرة.**

---

## 9. FULL OWNER-SIDE MODULE — RW_SalesReturnsManagement

انسخ الكتلة التالية كاملة كما هي دون تقطيع:

```javascript
// ============================================================
// RW_SalesReturnsManagement – Parent Management for Sales Returns
// ============================================================
var RW_SalesReturnsManagement = (function() {
    'use strict';

    var state = {
        rows: [],
        assignees: [],
        page: 0,
        limit: 50,
        timer: null
    };

    function _esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function _companyId() {
        if (typeof _rwCompanyId === 'function') return _rwCompanyId();
        if (typeof RW_STATE !== 'undefined' && RW_STATE) {
            if (RW_STATE.app && RW_STATE.app.companyId) return RW_STATE.app.companyId;
            if (RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id) return RW_STATE.app.company.id;
            if (RW_STATE.user && RW_STATE.user.companyId) return RW_STATE.user.companyId;
        }
        return null;
    }

    function _today() {
        return new Date().toISOString().slice(0, 10);
    }

    async function _token() {
        var s = await supabase.auth.getSession();
        if (!s || s.error || !s.data || !s.data.session || !s.data.session.access_token) {
            throw new Error('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');
        }
        return s.data.session.access_token;
    }

    async function _api(action, payload) {
        var token = await _token();
        var body = payload || {};
        body.action = action;
        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/sales-return-management', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify(body)
        });
        var json = await res.json().catch(function() { return {}; });
        if (!res.ok || !json.success) {
            throw new Error(json.msg || json.error || 'فشل تنفيذ العملية');
        }
        return json;
    }

    function _filters() {
        return {
            from_date: byId('srm-from') ? byId('srm-from').value || null : null,
            to_date: byId('srm-to') ? byId('srm-to').value || null : null,
            review_status: byId('srm-status') ? byId('srm-status').value || null : null,
            source_type: byId('srm-source') ? byId('srm-source').value || null : null,
            query: byId('srm-query') ? byId('srm-query').value.trim() || null : null
        };
    }

    async function _loadAssignees() {
        var res = await _api('assignees');
        state.assignees = res.rows || [];
    }

    async function _load() {
        var f = _filters();
        var list = await _api('list', {
            from_date: f.from_date,
            to_date: f.to_date,
            review_status: f.review_status,
            source_type: f.source_type,
            query: f.query,
            limit: state.limit,
            offset: state.page * state.limit
        });
        var summary = await _api('summary', {
            from_date: f.from_date,
            to_date: f.to_date
        });
        state.rows = list.rows || [];
        _renderKpi(summary.kpi || {});
        _renderTable();
    }

    function _renderKpi(k) {
        var host = byId('srm-kpis');
        if (!host) return;
        var cards = [
            ['إجمالي المرتجعات', k.total || 0, 'text-indigo-600'],
            ['مفتوحة', k.open || 0, 'text-amber-600'],
            ['قيد المراجعة', k.reviewing || 0, 'text-blue-600'],
            ['تمت التسوية', k.resolved || 0, 'text-emerald-600'],
            ['متنازع عليها', k.disputed || 0, 'text-red-600'],
            ['قيمة المرتجعات', Number(k.total_value || 0).toLocaleString('ar-EG') + ' EGP', 'text-slate-800']
        ];
        var html = '';
        for (var i = 0; i < cards.length; i++) {
            html += '<div class="bg-white border rounded-2xl p-5 shadow-sm">' +
                '<div class="text-xs text-gray-500">' + _esc(cards[i][0]) + '</div>' +
                '<div class="text-2xl font-black mt-2 ' + cards[i][2] + '">' + _esc(cards[i][1]) + '</div>' +
            '</div>';
        }
        safeHTML(host, html);
    }

    function _statusLabel(s) {
        var map = {
            open: 'مفتوح',
            reviewing: 'قيد المراجعة',
            resolved: 'تمت التسوية',
            disputed: 'متنازع عليها',
            cancelled: 'ملغاة'
        };
        return map[s] || s || 'مفتوح';
    }

    function _statusClass(s) {
        if (s === 'resolved') return 'bg-emerald-100 text-emerald-700';
        if (s === 'reviewing') return 'bg-blue-100 text-blue-700';
        if (s === 'disputed') return 'bg-red-100 text-red-700';
        if (s === 'cancelled') return 'bg-slate-200 text-slate-700';
        return 'bg-amber-100 text-amber-700';
    }

    function _renderTable() {
        var host = byId('srm-table');
        if (!host) return;
        if (!state.rows.length) {
            safeHTML(host, '<tr><td colspan="10" class="p-10 text-center text-gray-400">لا توجد مرتجعات مستوفية للفلاتر الحالية.</td></tr>');
            return;
        }
        var html = '';
        for (var i = 0; i < state.rows.length; i++) {
            var r = state.rows[i];
            var source = r.source_type === 'RUNSHEET' ? 'رانشيت' : (r.source_type === 'ORDER' ? 'أوردر' : 'غير محدد');
            html += '<tr class="border-t hover:bg-slate-50 cursor-pointer" data-srm-id="' + _esc(r.credit_note_id) + '">' +
                '<td class="p-3 font-black">' + _esc(r.cn_code) + '</td>' +
                '<td class="p-3">' + _esc(r.cn_date) + '</td>' +
                '<td class="p-3">' + _esc(source) + '</td>' +
                '<td class="p-3">' + _esc(r.order_code || r.runsheet_code || '-') + '</td>' +
                '<td class="p-3">' + _esc(r.customer_name || '-') + '</td>' +
                '<td class="p-3 text-center font-bold">' + _esc(r.returned_qty || 0) + '</td>' +
                '<td class="p-3 text-left font-black">' + Number(r.returned_value || r.total_amount || 0).toLocaleString('ar-EG') + '</td>' +
                '<td class="p-3 text-center">' + Number(r.physical_return_qty || 0).toLocaleString('ar-EG') + '</td>' +
                '<td class="p-3"><span class="px-2 py-1 rounded-full text-xs font-black ' + _statusClass(r.review_status) + '">' + _esc(_statusLabel(r.review_status)) + '</span></td>' +
                '<td class="p-3">' + _esc(r.assigned_to_name || r.assigned_to_email || '-') + '</td>' +
            '</tr>';
        }
        safeHTML(host, html);
        var rows = host.querySelectorAll('[data-srm-id]');
        for (var j = 0; j < rows.length; j++) {
            rows[j].addEventListener('click', function() {
                _openDetail(this.getAttribute('data-srm-id'));
            });
        }
    }

    function _assigneeOptions(selected) {
        var html = '<option value="">بدون تكليف</option>';
        for (var i = 0; i < state.assignees.length; i++) {
            var a = state.assignees[i];
            html += '<option value="' + _esc(a.id) + '"' + (selected === a.id ? ' selected' : '') + '>' + _esc(a.name || a.email) + ' — ' + _esc(a.role || '') + '</option>';
        }
        return html;
    }

    async function _openDetail(id) {
        showLoader('جاري تحميل تفاصيل المرتجع...');
        try {
            var res = await _api('detail', { credit_note_id: id });
            hideLoader();
            var h = res.header || {};
            var lines = res.lines || [];
            var events = res.events || [];
            var lineHtml = '<div class="overflow-auto max-h-[35vh]"><table class="w-full text-sm border"><thead class="bg-slate-100"><tr>' +
                '<th class="p-2 border">الكود</th><th class="p-2 border">الصنف</th><th class="p-2 border">الوحدة</th><th class="p-2 border">الأصلي</th><th class="p-2 border">مرتجع</th><th class="p-2 border">الحالة</th></tr></thead><tbody>';
            if (!lines.length) lineHtml += '<tr><td colspan="6" class="p-6 text-center text-gray-400">لا توجد تفاصيل كمية مرتبطة بهذا المستند.</td></tr>';
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i];
                lineHtml += '<tr class="border-t"><td class="p-2">' + _esc(l.item_code) + '</td><td class="p-2 font-bold">' + _esc(l.item_name) + '</td><td class="p-2 text-center">' + _esc(l.unit) + '</td><td class="p-2 text-center">' + _esc(l.original_qty || 0) + '</td><td class="p-2 text-center font-black text-rose-600">' + _esc(l.qty_returned || 0) + '</td><td class="p-2 text-center">' + _esc(l.return_condition || '—') + '</td></tr>';
            }
            lineHtml += '</tbody></table></div>';
            var eventHtml = '<div class="max-h-[22vh] overflow-auto space-y-2">';
            if (!events.length) eventHtml += '<div class="text-center text-gray-400 py-4">لا يوجد سجل مراجعة سابق.</div>';
            for (var e = 0; e < events.length; e++) {
                var ev = events[e];
                eventHtml += '<div class="border rounded-xl p-3 bg-slate-50"><div class="flex justify-between gap-3"><b>' + _esc(ev.action) + '</b><span class="text-xs text-gray-500">' + _esc(new Date(ev.created_at).toLocaleString('ar-EG')) + '</span></div><div class="text-xs mt-1">' + _esc(ev.from_status || '—') + ' → ' + _esc(ev.to_status || '—') + ' | ' + _esc(ev.actor_email || '') + '</div><div class="text-sm mt-1">' + _esc(ev.note || ev.resolution || '') + '</div></div>';
            }
            eventHtml += '</div>';

            var html = '<div class="text-right space-y-4">' +
                '<div class="grid grid-cols-2 md:grid-cols-4 gap-3">' +
                    '<div class="bg-indigo-50 border rounded-xl p-3"><div class="text-xs text-gray-500">رقم المستند</div><div class="font-black">' + _esc(h.cn_code) + '</div></div>' +
                    '<div class="bg-slate-50 border rounded-xl p-3"><div class="text-xs text-gray-500">المصدر</div><div class="font-bold">' + _esc(h.source_type) + '</div></div>' +
                    '<div class="bg-slate-50 border rounded-xl p-3"><div class="text-xs text-gray-500">العميل</div><div class="font-bold">' + _esc(h.customer_name || '-') + '</div></div>' +
                    '<div class="bg-rose-50 border rounded-xl p-3"><div class="text-xs text-gray-500">القيمة</div><div class="font-black text-rose-700">' + Number(h.total_amount || 0).toLocaleString('ar-EG') + ' EGP</div></div>' +
                '</div>' +
                '<div><h4 class="font-black mb-2">تفاصيل الأصناف</h4>' + lineHtml + '</div>' +
                '<div class="bg-white border rounded-2xl p-4"><h4 class="font-black mb-3">المراجعة الإدارية</h4>' +
                    '<div class="grid grid-cols-1 md:grid-cols-3 gap-3">' +
                        '<div><label class="text-xs font-bold block mb-1">الحالة</label><select id="srm-modal-status" class="w-full p-3 border rounded-xl"><option value="open">مفتوح</option><option value="reviewing">قيد المراجعة</option><option value="resolved">تمت التسوية</option><option value="disputed">متنازع عليها</option><option value="cancelled">ملغاة</option></select></div>' +
                        '<div><label class="text-xs font-bold block mb-1">المكلف</label><select id="srm-modal-assignee" class="w-full p-3 border rounded-xl">' + _assigneeOptions(h.assigned_to) + '</select></div>' +
                        '<div><label class="text-xs font-bold block mb-1">الإجراء</label><button id="srm-modal-save" class="w-full p-3 bg-indigo-600 text-white rounded-xl font-black">حفظ المراجعة</button></div>' +
                    '</div>' +
                    '<input id="srm-modal-note" class="w-full p-3 border rounded-xl mt-3" placeholder="ملاحظة المراجعة" value="' + _esc(h.review_note || '') + '">' +
                    '<textarea id="srm-modal-resolution" class="w-full p-3 border rounded-xl mt-3" rows="3" placeholder="قرار / تسوية / معالجة">' + _esc(h.resolution || '') + '</textarea>' +
                '</div>' +
                '<div><h4 class="font-black mb-2">سجل المراجعة</h4>' + eventHtml + '</div>' +
            '</div>';

            Swal.fire({
                title: 'إدارة المرتجع: ' + _esc(h.cn_code || ''),
                html: html,
                width: '1100px',
                showCloseButton: true,
                showConfirmButton: false,
                didOpen: function() {
                    var st = byId('srm-modal-status');
                    if (st) st.value = h.review_status || 'open';
                    var save = byId('srm-modal-save');
                    if (save) save.addEventListener('click', async function() {
                        showLoader('جاري حفظ المراجعة...');
                        try {
                            await _api('review', {
                                credit_note_id: id,
                                status: byId('srm-modal-status').value,
                                assigned_to: byId('srm-modal-assignee').value || null,
                                note: byId('srm-modal-note').value.trim() || null,
                                resolution: byId('srm-modal-resolution').value.trim() || null
                            });
                            hideLoader();
                            Swal.close();
                            showToast('تم حفظ مراجعة المرتجع', 'success');
                            await _load();
                        } catch (e2) {
                            hideLoader();
                            showToast(e2.message || 'فشل الحفظ', 'error');
                        }
                    });
                }
            });
        } catch (e) {
            hideLoader();
            showToast(e.message || 'فشل تحميل التفاصيل', 'error');
        }
    }

    function _bind() {
        var refresh = byId('srm-refresh');
        if (refresh) refresh.addEventListener('click', function() { state.page = 0; _load().catch(function(e){showToast(e.message,'error');}); });
        var exportBtn = byId('srm-refresh-live');
        if (exportBtn) exportBtn.addEventListener('click', function() { _load().catch(function(e){showToast(e.message,'error');}); });
        ['srm-from','srm-to','srm-status','srm-source'].forEach(function(id){var el=byId(id);if(el)el.addEventListener('change',function(){state.page=0;_load().catch(function(e){showToast(e.message,'error');});});});
        var search = byId('srm-query');
        if (search) search.addEventListener('input', function(){ clearTimeout(state.searchTimer); state.searchTimer=setTimeout(function(){state.page=0;_load().catch(function(e){showToast(e.message,'error');});},350); });
    }

    async function render() {
        var c = byId('rw-page-container');
        if (!c) return;
        safeText(byId('rw-header-title'), 'إدارة مرتجعات المبيعات');
        safeText(byId('rw-header-subtitle'), 'رقابة ومراجعة ومتابعة المرتجعات المنفذة ميدانيًا دون نقل تنفيذ العمليات إلى النظام الأم');
        safeHTML(c, '<div class="p-4 space-y-5">' +
            '<div id="srm-kpis" class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-3"></div>' +
            '<div class="bg-white border rounded-2xl p-4 shadow-sm">' +
                '<div class="grid grid-cols-1 md:grid-cols-6 gap-3">' +
                    '<input id="srm-query" class="p-3 border rounded-xl" placeholder="بحث برقم المرتجع / الأوردر / الرانشيت / العميل">' +
                    '<input id="srm-from" type="date" class="p-3 border rounded-xl" value="">' +
                    '<input id="srm-to" type="date" class="p-3 border rounded-xl" value="' + _today() + '">' +
                    '<select id="srm-status" class="p-3 border rounded-xl"><option value="">كل حالات المراجعة</option><option value="open">مفتوح</option><option value="reviewing">قيد المراجعة</option><option value="resolved">تمت التسوية</option><option value="disputed">متنازع عليها</option><option value="cancelled">ملغاة</option></select>' +
                    '<select id="srm-source" class="p-3 border rounded-xl"><option value="">كل المصادر</option><option value="RUNSHEET">رانشيت</option><option value="ORDER">أوردر</option></select>' +
                    '<div class="flex gap-2"><button id="srm-refresh" class="flex-1 bg-indigo-600 text-white rounded-xl font-black">تطبيق</button><button id="srm-refresh-live" class="px-4 bg-slate-700 text-white rounded-xl font-black">تحديث</button></div>' +
                '</div>' +
            '</div>' +
            '<div class="bg-white border rounded-2xl shadow-sm overflow-hidden">' +
                '<div class="p-4 border-b flex items-center justify-between"><div><h3 class="font-black text-xl">سجل مرتجعات المبيعات</h3><p class="text-xs text-gray-500 mt-1">المصدر الإداري مرتبط بالـCredit Note مع Evidence من تفاصيل الطلب/الرانشيت والمخزون.</p></div><span class="text-xs font-bold text-slate-500">Parent Management</span></div>' +
                '<div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3">المرتجع</th><th class="p-3">التاريخ</th><th class="p-3">المصدر</th><th class="p-3">المرجع</th><th class="p-3">العميل</th><th class="p-3">كمية المرتجع</th><th class="p-3">القيمة</th><th class="p-3">حركة المخزون</th><th class="p-3">المراجعة</th><th class="p-3">المكلف</th></tr></thead><tbody id="srm-table"><tr><td colspan="10" class="p-10 text-center">جاري التحميل...</td></tr></tbody></table></div>' +
            '</div>' +
        '</div>');

        try {
            await _loadAssignees();
            _bind();
            await _load();
            clearInterval(state.timer);
            state.timer = setInterval(function(){
                if (document.getElementById('srm-table')) _load().catch(function(){});
            }, 30000);
        } catch (e) {
            showToast(e.message || 'فشل تحميل إدارة المرتجعات', 'error');
        }
    }

    return { render: render };
})();
window.RW_SalesReturnsManagement = RW_SalesReturnsManagement;
```

---

## 10. CURRENT UI CONTRACT AFTER OWNER MERGE

بعد تطبيق التعديلات الخمسة أعلاه يصبح المسار:

`إدارة المبيعات`
→ `إدارة مرتجعات المبيعات`
→ `RW_SalesReturnsManagement.render()`
→ `sales-return-management Edge Function`
→ `Production RPCs`
→ `credit_notes / order_details / run_sheet_details / inventory_log`

والـOperational Return الحالي يبقى منفصلًا:

`إدارة المخازن والمخزون`
→ `العمليات المخزنية`
→ `المرتجعات`
→ `RW_Warehouse.loadReturn()`

وبذلك لا يوجد خلط بين:
- Field Execution
- Parent Management

---

## 11. LIVE SYNCHRONIZATION DECISION

تم استخدام refresh دوري 30 ثانية + refresh فوري بعد أي Review mutation.

السبب:
لا أُنشئ Realtime trigger جديدًا دون إثبات أن publication الحالية تشمل الجداول الجديدة، لأن ذلك سيكون قرارًا غير مثبت.

بعد إثبات publication/realtime contract يمكن استبدال polling باشتراك Realtime دون تغيير Domain Contract.

---

## 12. FORENSIC ASSEMBLY — FIXED

تم تحديث:
`forensic_main_assembly.yml`

من version 2 إلى version 3.

النسخة الجديدة تنص على:
- published parent في `erp-frontend` هو Source of Truth.
- `Current/PWA/main2/*` Historical Reference Only.
- `Original/PWA/main` Historical Reference.
- `Current/PWA/main` و`Current/PWA/New-main` forbidden sources.

Commit:
`cdfc889c36ef292e65bd34c210481e821b24cafd`

---

## 13. CANONICAL GIT CHANGES IN CURATED REPOSITORY

تم إضافة:

`Current/Edge_Functions/sales-return-management/index.ts`

وتم تحديثه ليطابق deployed v2.

Commit update:
`4ef85b1602f7e47f10cbfed91f697fae48e74378`

تم إضافة:

`supabase/migrations/20260913_sales_returns_parent_management.sql`

وتم إضافة سجل التصحيح:

`supabase/migrations/20260913_sales_return_summary_alias_fix.sql`

وذلك حتى لا تختفي واقعة التصحيح التي حدثت أثناء التنفيذ من التاريخ البرمجي.

**ملاحظة:** الـMigration الأولى تم اعتماد تعريفاتها النهائية الصحيحة، وسجل alias-fix يحفظ عملية التصحيح التي حدثت فعليًا أثناء بناء Production.

---

## 14. NO MODIFICATION TO PUBLISHED PARENT

لم يتم تعديل:
`erp-frontend/companies/company-1/main.html`

لأن ownership boundary في هذه المهمة واضح:

Production/backend = CTO/assistant implementation

Published Parent UI = owner-side surgical merge

هذا القرار ليس تعطيلًا للعمل؛ backend كامل وجاهز، والتعديل المطلوب على parent محدد بعبارات Search/Delete/Add وبكتلة module كاملة.

---

## 15. SELF-AUDIT

### What I Proved

- HEAD الحالي والـDirect Parent والـParent of Parent.
- Source of Truth الحالي للـParent.
- استمرار `RW_Warehouse.loadReturn()` كـOperational Return UI دون إعادة كتابة.
- Current Production schema لعقد Credit Notes.
- وجود/سلامة `items.item_code` global uniqueness.
- وجود audit path على `stock_vouchers`.
- إنشاء Production domain tables للإدارة.
- إنشاء Production RPC contract.
- نشر Edge Function `sales-return-management` v2 مع JWT.
- نجاح Summary/List.
- نجاح transactional Review/Detail/List.
- نجاح authorization rejection.
- عدم ترك test data في Production.
- تصحيح `forensic_main_assembly.yml`.
- canonical source للـEdge Function والمigrations في curated repository.

### What I Did Not Prove

- Browser click-by-click authenticated E2E.
- Browser console/network correlation.
- Realtime publication delivery للجداول الجديدة.
- إنتاج Credit Notes تشغيلية حقيقية في الحساب الحالي؛ Production الحالية لا تحتويها.
- سلامة كل cross-company historical anomalies في المشروع كله.

### What I Fixed

- Sales Returns Parent Management Production contract.
- Review lifecycle.
- Administrative event history.
- Company-scoped authorization.
- Production Edge capability.
- Current assembly authority.

### What Initially Failed

- Summary RPC alias collision.

### What Could Still Be Wrong

- Owner UI merge may expose unrelated pre-existing frontend defects during browser E2E.
- Some current unrelated Legacy/security debt remains خارج هذه closure.
- Realtime remains a separate evidence gate.

### Final Confidence

`CURRENT GIT = HIGH`

`CURRENT SOURCE = HIGH`

`CURRENT PRODUCTION BACKEND = HIGH`

`CURRENT DATABASE CONTRACT = HIGH for this closure`

`DEPLOYMENT = VERIFIED`

`BROWSER E2E = OPEN / NOT VERIFIED`

### Closure Status

`Sales Returns Parent Management Backend = CLOSED`

`Sales Returns Parent UI = OWNER MERGE REQUIRED`

`Full Browser E2E = OPEN`

---

## 16. INSTRUCTIONS TO THE NEXT CTO / ASSISTANT — START HERE

لا تبدأ بإعادة قراءة التقارير بحثًا عن الحالة.

ابدأ دائمًا من الواقع:

`CURRENT GIT HEAD`

`→ DIRECT PARENT`

`→ CURRENT SOURCE OF TRUTH`

`→ CURRENT PRODUCTION SCHEMA`

`→ CURRENT DEPLOYMENTS`

`→ CURRENT RUNTIME`

ثم:

`historical contract`

`→ current behavior`

`→ target contract`

`→ actual gap`

`→ one surgical closure`

`→ implement`

`→ test`

`→ deploy`

`→ Production verify`

`→ runtime verify`

`→ document`

`→ close`

### لا تعيد فتح Closed Closure

إذا كان هناك:
`POS Operation Identity = VERIFIED`
فلا تعالجه مرة أخرى بدون contradictory CURRENT evidence.

إذا كان:
`Inventory Physical Writer Core = CLOSED`
فلا تنقله إلى Parent Management لإكمال الشكل.

### في Sales Returns تحديدًا

ابدأ من:
`credit_notes`

ثم:
`order_details`
`run_sheet_details`
`inventory_log`

ثم:
`sales_return_reviews`
`sales_return_review_events`

ولا تبنِ محركًا ثانيًا لتنفيذ المرتجع.

### أهم سؤال قبل أي Patch جديد

هل نحن أصلحنا:
`Capability`

أم فقط:
`UI appearance`

الهدف هو Capability كاملة مع:
`Identity + State + Security + Audit + Evidence + Ownership + Integration`

### بعد Owner Merge

نفذ Browser E2E بالنقر الحقيقي على:
`erp-frontend/companies/company-1/main.html`

وسجل:
`Console`
`Network`
`Edge response`
`Production row`
`Review event`

ولا تعتبر الصفحة ناجحة لمجرد ظهور الجدول.

---

## 17. NEXT OPEN WORK

الترتيب بعد إغلاق Parent Management UI:

1. Browser click-by-click E2E.
2. Quote Lifecycle.
3. Price List Engine.
4. Promotion Engine.
5. Multiple/Partial Payment Allocation.
6. Installment Lifecycle.
7. Commission Engine.
8. Sales Targets.
9. Loyalty Transaction Engine.
10. Sales Decision Center.

ولا يُسمح بتجاوز ترتيب Closure Units إذا أدى ذلك إلى ترك Contract نصف منفذ.

---

# FINAL RESULT

تم تنفيذ الجزء الذي يخص Production بالكامل.

تم إنشاء البنية التحتية المطلوبة.

تم إنشاء الجداول والعلاقات.

تم إنشاء RPCs.

تم إنشاء Edge Function ونشرها.

تم اختبار النجاح والفشل والأمان.

تم تحديث assembly authority.

لم يتم لمس Parent main.html احترامًا لحدود الملكية.

الـUI الجاهز للدمج محدد بدقة في Section 8 وSection 9، والملف المنشور يبقى Source of Truth الوحيد.

**الحكم النهائي الحالي:**

`BACKEND READY + OWNER UI MERGE REQUIRED + BROWSER E2E OPEN`
