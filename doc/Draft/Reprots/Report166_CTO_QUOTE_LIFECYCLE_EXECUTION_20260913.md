# تقرير 166 — CTO Quote Lifecycle Execution
## التاريخ
2026-09-13

## 0) تنبيه حاكم
هذا التقرير ليس مصدر الحقيقة. التقارير السابقة Historical/Reference فقط.
الحالة المعتمدة لهذه الجلسة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

## 1) الهدف
`Quote lifecycle = OPEN`
تم تنفيذ البنية التشغيلية الفعلية في Production بدل الاكتفاء بواجهة هيكلية.

## 2) Source of Truth
المسار الحاكم:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

لم يتم تعديل هذا الملف من جانبي في هذه الجلسة لأن تعديلات النظام الأم owner-side.

## 3) Current Git / Parent Chain
Frontend HEAD:
`d0cfb6fefd1af960de336935d8eec6d831c2d101`
Direct Parent:
`aaebffbdd732b9861d96631f5d01c5a6697bd1e4`
Parent of Parent:
`3573c92026557cb56a7782babe6f6cf690243072`
Current main.html blob:
`4cc90ea87697b0e01a21900da289f3e86e1fefcb`

HEAD message:
`Implement sales returns management feature`

لم تتم إعادة استخدام HEAD القديم الموجود في CURRENT_STATE القديم لأنه أصبح STALE.

## 4) Production infrastructure
تم إنشاء:
- `sales_quotes`
- `sales_quote_details`
- `sales_quote_status_history`

العلاقات:
`company -> quote`
`customer -> quote`
`branch -> quote`
`sales_rep -> quote`
`quote -> quote_details`
`item -> quote_details`
`quote -> converted order`
`quote -> status history`

القيود والفهارس الأساسية:
- `company_id + quote_code` UNIQUE
- `company_id + operation_id` UNIQUE جزئي
- `converted_order_id` UNIQUE جزئي
- `quote_id + line_number` UNIQUE
- `quote_id + item_id` UNIQUE
- كميات موجبة
- نسب الخصم محدودة
- RLS enabled + FORCE

## 5) Lifecycle
```text
Draft
  -> Sent
      -> Accepted
          -> Converted -> Confirmed Order
      -> Rejected
      -> Expired
      -> Cancelled
  -> Cancelled
```

إنشاء Quote وتعديله لا ينتج Physical Stock Movement.
تحويل Quote إلى Order لا ينتج Physical Stock Movement.
الـOrder يدخل بعد ذلك في دورة الوفاء والمخزون الموجودة أصلًا.

## 6) RPCs
- `rawaea_quote_actor_ok`
- `create_sales_quote_atomic`
- `update_sales_quote_atomic`
- `change_sales_quote_status_atomic`
- `expire_due_sales_quotes_atomic`
- `convert_sales_quote_to_order_atomic`
- `list_sales_quotes`
- `get_sales_quote_detail`
- `get_sales_quote_summary`

كلها:
`SECURITY DEFINER`
`search_path = public`
`PUBLIC/anon/authenticated EXECUTE = revoked`
`service_role = allowed`

## 7) Edge
تم إنشاء:
`sales-quotes`

Production:
`ACTIVE`
`Version = 2`
`verify_jwt = true`

القدرات:
`catalog / list / summary / detail / create / update / send / accept / reject / cancel / expire_due / convert`

المصدر canonical:
`rawaie-erp-New/Current/Edge_Functions/sales-quotes/index.ts`

Commit:
`3ef10f9752d806563732790ca2fb34d5800c5888`

## 8) Security
الـEdge يأخذ company context من JWT ثم `users.auth_id`.
لا يتم الوثوق في `company_id` المرسل من الواجهة.
الـRPCs تتحقق من الشركة والفاعل والعميل والفرع والمندوب.
Item identity اعتمدت على `item_code` لأن Production تثبت وجود UNIQUE عالمي على `items.item_code`.

## 9) Tests
### Full transactional E2E
`CREATE -> SEND -> ACCEPT -> CONVERT -> CONVERT(RETRY)`

الناتج:
- `Converted`
- total = `90`
- qty = `2`
- unit price = `50`
- Order = `Confirmed`
- source = `quote`
- inventory log rows = `0`

تم `ROLLBACK` بالكامل.

### Create idempotency
نفس `operation_id` مرتين:
الأولى إنشاء.
الثانية `duplicate=true`.
ثم `ROLLBACK`.

### Unauthorized
مستخدم بلا صلاحية Orders:
`unauthorized_rejected`

### Expiry
Quote منتهٍ داخل Transaction:
`Expired`
ثم `ROLLBACK`.

### Production persistence check
بعد الاختبارات:
`sales_quotes = 0`
`sales_quote_details = 0`
`sales_quote_status_history = 0`

## 10) Inventory integrity
تم فحص `convert_sales_quote_to_order_atomic`.
لا يحتوي:
`post_stock_movement`
ولا كتابة إلى:
`stock_branches`
ولا:
`inventory_log`

إذن لا يوجد Parallel Stock Engine.

## 11) أخطاء تم كشفها ومعالجتها
- تعارض أسماء متغيرات في نسخة PL/pgSQL أولية: تم إصلاحه قبل اعتماد المسار.
- تم اختبار ترتيب الـidempotency والـfingerprint حتى أصبحت إعادة Create آمنة.
- أضيفت مؤقتًا أعمدة تصميمية غير مستخدمة ثم حُذفت قبل الإغلاق النهائي:
  `customer_reference`
  `payment_terms`
  `price_locked`
  وذلك لمنع Schema Debt.

## 12) Owner-side UI — لم أعدل main.html
التبويب غير موجود حاليًا في الملف الحاكم، لذلك المطلوب owner-side فقط.

### 12.1 Navigation — السطر 1142
ابحث عن السطر الكامل التالي واحذفه:
```text
    { icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

واستبدله بالسطر الكامل التالي:
```text
    { icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'quotes', label: 'عروض الأسعار' }, { view: 'runsheets', label: 'الرانشيتات' }, { view: 'sales-returns', label: 'إدارة مرتجعات المبيعات' }] },
```

### 12.2 permissionMap — السطر 17082
ابحث عن:
```text
            'orders': 'orders',
```
وأضف تحته مباشرة:
```text
            'quotes': 'orders',
```

### 12.3 titles — السطر 17141
ابحث عن:
```text
            'orders':'أوردرات المبيعات',
```
وأضف تحته مباشرة:
```text
            'quotes':'عروض الأسعار',
```

### 12.4 route — السطر 17188
ابحث عن:
```text
        if (view === 'orders') { RW_Orders.render(); return; }
```
وأضف تحته مباشرة:
```text
        if (view === 'quotes') { RW_SalesQuotes.render(); return; }
```

### 12.5 Module insertion — السطر 17929
ابحث عن المقطع الكامل:
```text
// ============================================================
// EVENTS & BOOT
// ============================================================
function bindEvents() {
```

أضف الموديول التالي كاملًا مباشرة فوقه.

## 13) Full owner-side module
```javascript
// ============================================================
// RW_SalesQuotes — إدارة دورة عروض الأسعار
// Production contract: /functions/v1/sales-quotes
// ============================================================
var RW_SalesQuotes = (function () {
    'use strict';

    var state = {
        rows: [],
        kpi: {},
        catalog: { customers: [], items: [], branches: [], sales_reps: [] },
        timer: null,
        editCode: null,
        conversionOps: {}
    };

    function esc(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function money(v) {
        return Number(v || 0).toLocaleString('ar-SA', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    function today() {
        return new Date().toISOString().slice(0, 10);
    }

    function plusDays(n) {
        var d = new Date();
        d.setDate(d.getDate() + n);
        return d.toISOString().slice(0, 10);
    }

    function apiBase() {
        if (typeof RW_SUPABASE_URL !== 'undefined' && RW_SUPABASE_URL) return RW_SUPABASE_URL;
        if (typeof SUPABASE_URL !== 'undefined' && SUPABASE_URL) return SUPABASE_URL;
        if (typeof supabaseUrl !== 'undefined' && supabaseUrl) return supabaseUrl;
        throw new Error('SUPABASE_URL غير متاح');
    }

    async function api(action, payload) {
        var sessionRes = await supabase.auth.getSession();
        if (!sessionRes.data || !sessionRes.data.session || !sessionRes.data.session.access_token) {
            throw new Error('انتهت الجلسة');
        }
        var body = Object.assign({ action: action }, payload || {});
        var res = await fetch(apiBase() + '/functions/v1/sales-quotes', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + sessionRes.data.session.access_token
            },
            body: JSON.stringify(body)
        });
        var data = await res.json().catch(function () { return {}; });
        if (!res.ok || data && data.success === false) {
            throw new Error((data && (data.msg || data.message)) || 'فشل تنفيذ عملية عروض الأسعار');
        }
        return data;
    }

    async function loadCatalog() {
        var data = await api('catalog');
        state.catalog = {
            customers: data.customers || [],
            items: data.items || [],
            branches: data.branches || [],
            sales_reps: data.sales_reps || []
        };
    }

    async function loadData() {
        try { await api('expire_due'); } catch (e) {}
        var status = byId('sq-filter-status') ? byId('sq-filter-status').value : '';
        var query = byId('sq-filter-query') ? byId('sq-filter-query').value.trim() : '';
        var result = await Promise.all([
            api('summary'),
            api('list', {
                status: status || null,
                query: query || null,
                limit: 100,
                offset: 0
            })
        ]);
        state.kpi = (result[0] && result[0].kpi) || {};
        state.rows = (result[1] && result[1].rows) || [];
        renderKPIs();
        renderRows();
    }

    function statusLabel(s) {
        var map = {
            Draft: 'مسودة',
            Sent: 'مرسل',
            Accepted: 'مقبول',
            Rejected: 'مرفوض',
            Expired: 'منتهي',
            Cancelled: 'ملغى',
            Converted: 'محوّل لأوردر'
        };
        return map[s] || s || '';
    }

    function statusClass(s) {
        var map = {
            Draft: 'bg-slate-100 text-slate-700',
            Sent: 'bg-blue-100 text-blue-700',
            Accepted: 'bg-emerald-100 text-emerald-700',
            Rejected: 'bg-rose-100 text-rose-700',
            Expired: 'bg-amber-100 text-amber-700',
            Cancelled: 'bg-gray-100 text-gray-600',
            Converted: 'bg-violet-100 text-violet-700'
        };
        return map[s] || 'bg-slate-100 text-slate-700';
    }

    function renderKPIs() {
        var el = byId('sq-kpis');
        if (!el) return;
        var k = state.kpi || {};
        safeHTML(el,
            '<div class="rw-kpi-card"><div class="text-slate-500 text-sm font-bold">إجمالي العروض</div><div class="text-3xl font-black mt-2">' + esc(k.total || 0) + '</div><div class="text-xs text-slate-400 mt-2">كل حالات دورة العرض</div></div>' +
            '<div class="rw-kpi-card"><div class="text-slate-500 text-sm font-bold">العروض المرسلة</div><div class="text-3xl font-black mt-2">' + esc(k.sent || 0) + '</div><div class="text-xs text-slate-400 mt-2">بانتظار قرار العميل</div></div>' +
            '<div class="rw-kpi-card"><div class="text-slate-500 text-sm font-bold">العروض المقبولة</div><div class="text-3xl font-black mt-2">' + esc(k.accepted || 0) + '</div><div class="text-xs text-slate-400 mt-2">جاهزة للتحويل</div></div>' +
            '<div class="rw-kpi-card"><div class="text-slate-500 text-sm font-bold">قيمة المبيعات المحولة</div><div class="text-3xl font-black mt-2">' + esc(money(k.won_value || 0)) + '</div><div class="text-xs text-slate-400 mt-2">من العروض المقبولة/المحولة</div></div>'
        );
    }

    function renderRows() {
        var body = byId('sq-table');
        if (!body) return;
        if (!state.rows.length) {
            safeHTML(body, '<tr><td colspan="8" class="p-10 text-center text-slate-500">لا توجد عروض أسعار مطابقة</td></tr>');
            return;
        }
        var html = '';
        for (var i = 0; i < state.rows.length; i++) {
            var q = state.rows[i];
            var actions = '<button class="px-3 py-2 rounded-lg bg-slate-100 font-black" data-sq-action="detail" data-code="' + esc(q.quote_code) + '">عرض</button>';
            if (q.status === 'Draft') {
                actions += ' <button class="px-3 py-2 rounded-lg bg-blue-600 text-white font-black" data-sq-action="send" data-code="' + esc(q.quote_code) + '">إرسال</button>';
                actions += ' <button class="px-3 py-2 rounded-lg bg-white border font-black" data-sq-action="edit" data-code="' + esc(q.quote_code) + '">تعديل</button>';
                actions += ' <button class="px-3 py-2 rounded-lg bg-rose-50 text-rose-700 font-black" data-sq-action="cancel" data-code="' + esc(q.quote_code) + '">إلغاء</button>';
            } else if (q.status === 'Sent') {
                actions += ' <button class="px-3 py-2 rounded-lg bg-emerald-600 text-white font-black" data-sq-action="accept" data-code="' + esc(q.quote_code) + '">قبول</button>';
                actions += ' <button class="px-3 py-2 rounded-lg bg-rose-600 text-white font-black" data-sq-action="reject" data-code="' + esc(q.quote_code) + '">رفض</button>';
                actions += ' <button class="px-3 py-2 rounded-lg bg-slate-100 font-black" data-sq-action="cancel" data-code="' + esc(q.quote_code) + '">إلغاء</button>';
            } else if (q.status === 'Accepted') {
                actions += ' <button class="px-3 py-2 rounded-lg bg-violet-600 text-white font-black" data-sq-action="convert" data-code="' + esc(q.quote_code) + '">تحويل لأوردر</button>';
            } else if (q.status === 'Converted') {
                actions += ' <button class="px-3 py-2 rounded-lg bg-violet-50 text-violet-700 font-black" data-sq-action="detail" data-code="' + esc(q.quote_code) + '">تفاصيل التحويل</button>';
            }
            html += '<tr class="border-b hover:bg-slate-50">' +
                '<td class="p-3 font-black">' + esc(q.quote_code) + '</td>' +
                '<td class="p-3">' + esc(q.quote_date) + '</td>' +
                '<td class="p-3">' + esc(q.customer_name || '—') + '</td>' +
                '<td class="p-3">' + esc(q.sales_rep_name || '—') + '</td>' +
                '<td class="p-3">' + esc(q.item_count || 0) + '</td>' +
                '<td class="p-3 font-black">' + esc(money(q.total_amount)) + '</td>' +
                '<td class="p-3"><span class="px-3 py-1 rounded-full text-xs font-black ' + statusClass(q.status) + '">' + esc(statusLabel(q.status)) + '</span></td>' +
                '<td class="p-3"><div class="flex flex-wrap gap-2">' + actions + '</div></td>' +
            '</tr>';
        }
        safeHTML(body, html);
    }

    function customerOptions(selected) {
        var h = '<option value="">اختر العميل</option>';
        for (var i = 0; i < state.catalog.customers.length; i++) {
            var c = state.catalog.customers[i];
            h += '<option value="' + esc(c.id) + '"' + (selected === c.id ? ' selected' : '') + '>' + esc(c.name) + (c.phone ? ' — ' + esc(c.phone) : '') + '</option>';
        }
        return h;
    }

    function branchOptions(selected) {
        var h = '<option value="">الفرع الرئيسي</option>';
        for (var i = 0; i < state.catalog.branches.length; i++) {
            var b = state.catalog.branches[i];
            h += '<option value="' + esc(b.id) + '"' + (selected === b.id ? ' selected' : '') + '>' + esc(b.branch_code) + ' — ' + esc(b.name) + '</option>';
        }
        return h;
    }

    function repOptions(selected) {
        var h = '<option value="">اختر المندوب</option>';
        for (var i = 0; i < state.catalog.sales_reps.length; i++) {
            var r = state.catalog.sales_reps[i];
            h += '<option value="' + esc(r.id) + '"' + (selected === r.id ? ' selected' : '') + '>' + esc(r.name || r.email) + '</option>';
        }
        return h;
    }

    function itemOptions(selected) {
        var h = '<option value="">اختر الصنف</option>';
        for (var i = 0; i < state.catalog.items.length; i++) {
            var it = state.catalog.items[i];
            h += '<option value="' + esc(it.item_code) + '"' + (selected === it.item_code ? ' selected' : '') + '>' + esc(it.item_code) + ' — ' + esc(it.name) + '</option>';
        }
        return h;
    }

    function readFormItems() {
        var rows = document.querySelectorAll('[data-sq-line]');
        var items = [];
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            var codeEl = row.querySelector('[data-sq-item]');
            var qtyEl = row.querySelector('[data-sq-qty]');
            var priceEl = row.querySelector('[data-sq-price]');
            var discEl = row.querySelector('[data-sq-disc]');
            var taxEl = row.querySelector('[data-sq-tax]');
            var item = {
                item_code: codeEl ? codeEl.value : '',
                qty: Number(qtyEl ? qtyEl.value : 0),
                unit_price: Number(priceEl ? priceEl.value : 0),
                discount_percent: Number(discEl ? discEl.value : 0),
                tax_rate: Number(taxEl ? taxEl.value : 0)
            };
            if (item.item_code && item.qty > 0) items.push(item);
        }
        return items;
    }

    function addLine(item) {
        var host = byId('sq-lines');
        if (!host) return;
        item = item || {};
        var row = document.createElement('div');
        row.setAttribute('data-sq-line', '1');
        row.className = 'grid grid-cols-12 gap-2 items-center border-b pb-3';
        row.innerHTML =
            '<div class="col-span-5"><select data-sq-item class="w-full p-3 border rounded-xl">' + itemOptions(item.item_code || '') + '</select></div>' +
            '<div class="col-span-2"><input data-sq-qty type="number" min="0.01" step="0.01" class="w-full p-3 border rounded-xl" value="' + esc(item.qty || '') + '" placeholder="الكمية"></div>' +
            '<div class="col-span-2"><input data-sq-price type="number" min="0" step="0.01" class="w-full p-3 border rounded-xl" value="' + esc(item.unit_price || '') + '" placeholder="السعر"></div>' +
            '<div class="col-span-1"><input data-sq-disc type="number" min="0" max="100" step="0.01" class="w-full p-3 border rounded-xl" value="' + esc(item.discount_percent || 0) + '" placeholder="%"></div>' +
            '<div class="col-span-1"><input data-sq-tax type="number" min="0" step="0.01" class="w-full p-3 border rounded-xl" value="' + esc(item.tax_rate || 0) + '" placeholder="%"></div>' +
            '<div class="col-span-1"><button type="button" class="w-full p-3 rounded-xl bg-rose-50 text-rose-700 font-black" data-sq-remove>×</button></div>';
        row.querySelector('[data-sq-remove]').addEventListener('click', function () { row.remove(); });
        host.appendChild(row);
    }

    async function openNew() {
        state.editCode = null;
        await loadCatalog();
        openEditor(null);
    }

    async function openEditor(quote) {
        var detail = quote;
        if (quote && quote.items) {
            detail = quote;
        } else if (quote && quote.quote_code) {
            detail = await api('detail', { quote_code: quote.quote_code });
            detail = Object.assign({}, detail.quote, { items: detail.items || [] });
        }
        var q = detail || {};
        var lines = q.items || [];
        var modal = document.createElement('div');
        modal.id = 'sq-modal';
        modal.className = 'fixed inset-0 z-[1000] bg-black/50 flex items-center justify-center p-4';
        modal.innerHTML =
            '<div class="bg-white rounded-3xl shadow-2xl w-full max-w-6xl max-h-[95vh] overflow-auto p-6">' +
                '<div class="flex items-center justify-between mb-5"><div><h3 class="text-2xl font-black">' + (q.quote_code ? 'تعديل العرض ' + esc(q.quote_code) : 'عرض سعر جديد') + '</h3><p class="text-sm text-slate-500 mt-1">العرض التجاري لا يحجز ولا يصرف مخزونًا.</p></div><button id="sq-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">إغلاق</button></div>' +
                '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-5">' +
                    '<select id="sq-customer" class="p-3 border rounded-xl">' + customerOptions(q.customer_id || '') + '</select>' +
                    '<select id="sq-branch" class="p-3 border rounded-xl">' + branchOptions(q.branch_id || '') + '</select>' +
                    '<select id="sq-rep" class="p-3 border rounded-xl">' + repOptions(q.sales_rep_id || '') + '</select>' +
                    '<input id="sq-valid" type="date" class="p-3 border rounded-xl" value="' + esc(q.valid_until || plusDays(7)) + '">' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-5">' +
                    '<input id="sq-name" class="p-3 border rounded-xl" placeholder="اسم عميل غير مسجل" value="' + esc(q.customer_name || '') + '">' +
                    '<input id="sq-phone" class="p-3 border rounded-xl" placeholder="هاتف العميل" value="' + esc(q.customer_phone || '') + '">' +
                    '<input id="sq-area" class="p-3 border rounded-xl" placeholder="المنطقة" value="' + esc(q.area || '') + '">' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-5">' +
                    '<input id="sq-discount" type="number" min="0" step="0.01" class="p-3 border rounded-xl" placeholder="خصم عام" value="' + esc(q.discount_amount || 0) + '">' +
                    '<input id="sq-delivery" type="number" min="0" step="0.01" class="p-3 border rounded-xl" placeholder="رسوم توصيل" value="' + esc(q.delivery_fee || 0) + '">' +
                    '<input id="sq-reference" class="p-3 border rounded-xl" placeholder="مرجع العميل/العرض" value="' + esc(q.reference || '') + '">' +
                '</div>' +
                '<div class="mb-5"><textarea id="sq-notes" class="w-full p-3 border rounded-xl" rows="2" placeholder="ملاحظات">' + esc(q.notes || '') + '</textarea></div>' +
                '<div class="mb-4"><div class="flex items-center justify-between mb-3"><h4 class="font-black text-lg">الأصناف</h4><button id="sq-add-line" class="px-4 py-2 rounded-xl bg-slate-900 text-white font-black">+ إضافة صنف</button></div><div class="grid grid-cols-12 gap-2 text-xs font-black text-slate-500 pb-2"><div class="col-span-5">الصنف</div><div class="col-span-2">كمية</div><div class="col-span-2">سعر</div><div class="col-span-1">خصم%</div><div class="col-span-1">ضريبة%</div><div class="col-span-1"></div></div><div id="sq-lines" class="space-y-3"></div></div>' +
                '<div class="grid grid-cols-1 md:grid-cols-2 gap-3"><input id="sq-terms" class="p-3 border rounded-xl" placeholder="الشروط" value="' + esc(q.terms || '') + '"><div class="flex justify-end gap-2"><button id="sq-save" class="px-6 py-3 rounded-xl bg-blue-600 text-white font-black">حفظ مسودة العرض</button></div></div>' +
            '</div>';
        document.body.appendChild(modal);
        for (var i = 0; i < lines.length; i++) addLine(lines[i]);
        if (!lines.length) addLine({});
        byId('sq-close').addEventListener('click', function () { modal.remove(); });
        byId('sq-add-line').addEventListener('click', function () { addLine({}); });
        byId('sq-save').addEventListener('click', async function () {
            var items = readFormItems();
            if (!items.length) return showToast('أضف صنفًا صالحًا واحدًا على الأقل', 'warning');
            try {
                showLoader('جاري حفظ العرض...');
                var customer = byId('sq-customer').value || null;
                var customerObj = state.catalog.customers.find(function (x) { return x.id === customer; }) || null;
                var payload = {
                    quote_date: q.quote_date || today(),
                    valid_until: byId('sq-valid').value || null,
                    customer_id: customer,
                    customer_name: byId('sq-name').value.trim() || (customerObj && customerObj.name) || null,
                    customer_phone: byId('sq-phone').value.trim() || (customerObj && customerObj.phone) || null,
                    area: byId('sq-area').value.trim() || (customerObj && customerObj.area) || null,
                    branch_id: byId('sq-branch').value || null,
                    sales_rep_id: byId('sq-rep').value || null,
                    currency: 'SAR',
                    discount_amount: Number(byId('sq-discount').value || 0),
                    delivery_fee: Number(byId('sq-delivery').value || 0),
                    reference: byId('sq-reference').value.trim() || null,
                    notes: byId('sq-notes').value.trim() || null,
                    terms: byId('sq-terms').value.trim() || null,
                    items: items
                };
                if (q.quote_code) {
                    payload.quote_code = q.quote_code;
                    await api('update', payload);
                } else {
                    payload.operation_id = crypto.randomUUID();
                    await api('create', payload);
                }
                hideLoader();
                modal.remove();
                showToast('تم حفظ العرض بنجاح', 'success');
                await loadData();
            } catch (e) {
                hideLoader();
                showToast(e.message || 'فشل حفظ العرض', 'error');
            }
        });
    }

    async function detail(code) {
        try {
            showLoader('جاري تحميل تفاصيل العرض...');
            var data = await api('detail', { quote_code: code });
            hideLoader();
            var q = data.quote || {};
            var lines = data.items || [];
            var history = data.history || [];
            var modal = document.createElement('div');
            modal.className = 'fixed inset-0 z-[1000] bg-black/50 flex items-center justify-center p-4';
            var lh = '';
            for (var i = 0; i < lines.length; i++) {
                lh += '<tr class="border-b"><td class="p-3">' + esc(lines[i].item_code) + '</td><td class="p-3">' + esc(lines[i].item_name) + '</td><td class="p-3">' + esc(lines[i].qty) + '</td><td class="p-3">' + esc(money(lines[i].unit_price)) + '</td><td class="p-3 font-black">' + esc(money(lines[i].line_total)) + '</td></tr>';
            }
            var hh = '';
            for (var h = 0; h < history.length; h++) {
                hh += '<div class="flex items-center justify-between border-b py-2"><div><span class="font-black">' + esc(statusLabel(history[h].to_status)) + '</span><span class="text-xs text-slate-500 mr-2">' + esc(history[h].action) + '</span></div><div class="text-xs text-slate-500">' + esc(history[h].actor_email) + ' · ' + esc(history[h].created_at) + '</div></div>';
            }
            modal.innerHTML =
                '<div class="bg-white rounded-3xl shadow-2xl w-full max-w-5xl max-h-[95vh] overflow-auto p-6">' +
                '<div class="flex items-center justify-between mb-5"><div><h3 class="text-2xl font-black">' + esc(q.quote_code) + '</h3><p class="text-sm text-slate-500">' + esc(q.customer_name || '—') + ' · ' + esc(statusLabel(q.status)) + '</p></div><button class="px-4 py-2 rounded-xl bg-slate-100 font-black" data-sq-close>إغلاق</button></div>' +
                '<div class="grid grid-cols-2 md:grid-cols-5 gap-3 mb-5">' +
                '<div class="p-4 bg-slate-50 rounded-2xl"><div class="text-xs text-slate-500">التاريخ</div><div class="font-black mt-1">' + esc(q.quote_date) + '</div></div>' +
                '<div class="p-4 bg-slate-50 rounded-2xl"><div class="text-xs text-slate-500">الصلاحية</div><div class="font-black mt-1">' + esc(q.valid_until || 'بدون') + '</div></div>' +
                '<div class="p-4 bg-slate-50 rounded-2xl"><div class="text-xs text-slate-500">الأصناف</div><div class="font-black mt-1">' + esc(lines.length) + '</div></div>' +
                '<div class="p-4 bg-slate-50 rounded-2xl"><div class="text-xs text-slate-500">الإجمالي</div><div class="font-black mt-1">' + esc(money(q.total_amount)) + '</div></div>' +
                '<div class="p-4 bg-slate-50 rounded-2xl"><div class="text-xs text-slate-500">الأوردر</div><div class="font-black mt-1">' + esc(q.converted_order_id ? 'تم التحويل' : '—') + '</div></div>' +
                '</div>' +
                '<div class="border rounded-2xl overflow-hidden mb-5"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">الكود</th><th class="p-3 text-right">الصنف</th><th class="p-3 text-right">الكمية</th><th class="p-3 text-right">السعر</th><th class="p-3 text-right">الإجمالي</th></tr></thead><tbody>' + lh + '</tbody></table></div>' +
                '<div class="border rounded-2xl p-4"><h4 class="font-black mb-2">سجل دورة الحياة</h4>' + (hh || '<div class="text-slate-500">لا يوجد سجل</div>') + '</div>' +
                '</div>';
            document.body.appendChild(modal);
            modal.querySelector('[data-sq-close]').addEventListener('click', function () { modal.remove(); });
        } catch (e) {
            hideLoader();
            showToast(e.message || 'فشل تحميل التفاصيل', 'error');
        }
    }

    async function action(code, actionName) {
        try {
            showLoader('جاري تنفيذ العملية...');
            var result = await api(actionName, { quote_code: code });
            hideLoader();
            showToast(result && result.status ? 'تم تحديث الحالة إلى ' + statusLabel(result.status) : 'تم التنفيذ', 'success');
            await loadData();
        } catch (e) {
            hideLoader();
            showToast(e.message || 'فشل تنفيذ العملية', 'error');
        }
    }

    async function convert(code) {
        if (!state.conversionOps[code]) state.conversionOps[code] = crypto.randomUUID();
        try {
            showLoader('جاري تحويل العرض إلى أوردر...');
            var result = await api('convert', {
                quote_code: code,
                operation_id: state.conversionOps[code]
            });
            hideLoader();
            if (result && result.order_code) showToast('تم التحويل إلى ' + result.order_code, 'success');
            await loadData();
        } catch (e) {
            hideLoader();
            showToast(e.message || 'فشل تحويل العرض', 'error');
        }
    }

    function bind() {
        var root = byId('rw-page-container') || document;
        root.onclick = function (e) {
            var btn = e.target.closest('[data-sq-action]');
            if (!btn) return;
            var code = btn.getAttribute('data-code');
            var a = btn.getAttribute('data-sq-action');
            if (a === 'detail') return detail(code);
            if (a === 'edit') return api('detail', { quote_code: code }).then(async function (d) {
                await loadCatalog();
                openEditor(Object.assign({}, d.quote, { items: d.items || [] }));
            }).catch(function (err) { showToast(err.message || 'فشل فتح العرض', 'error'); });
            if (a === 'convert') return convert(code);
            if (a === 'send' || a === 'accept' || a === 'reject' || a === 'cancel') return action(code, a);
        };
    }

    function render() {
        var c = byId('rw-content') || byId('rw-page-container') || document.querySelector('.rw-page-container');
        if (!c) return;
        safeHTML(c,
            '<div class="space-y-6">' +
                '<div class="flex items-center justify-between gap-4 flex-wrap"><div><div class="text-sm text-slate-500 font-bold">المبيعات</div><h2 class="text-3xl font-black mt-1">عروض الأسعار</h2><p class="text-sm text-slate-500 mt-2">دورة تجارية متكاملة من المسودة حتى التحويل إلى أوردر، بدون أي حركة مخزنية في مرحلة العرض.</p></div><button id="sq-new" class="px-5 py-3 rounded-2xl bg-blue-600 text-white font-black shadow-lg">+ عرض سعر جديد</button></div>' +
                '<div id="sq-kpis" class="rw-kpi-grid"></div>' +
                '<div class="bg-white rounded-3xl border shadow-sm p-4"><div class="flex flex-col md:flex-row gap-3"><select id="sq-filter-status" class="p-3 border rounded-xl"><option value="">كل الحالات</option><option value="Draft">مسودة</option><option value="Sent">مرسل</option><option value="Accepted">مقبول</option><option value="Rejected">مرفوض</option><option value="Expired">منتهي</option><option value="Cancelled">ملغى</option><option value="Converted">محوّل لأوردر</option></select><input id="sq-filter-query" class="flex-1 p-3 border rounded-xl" placeholder="بحث برقم العرض أو العميل أو الهاتف"><button id="sq-refresh" class="px-5 py-3 rounded-xl bg-slate-900 text-white font-black">تحديث</button></div></div>' +
                '<div class="bg-white rounded-3xl border shadow-sm overflow-hidden"><div class="p-4 border-b"><h3 class="font-black text-xl">سجل عروض الأسعار</h3><p class="text-xs text-slate-500 mt-1">العرض Snapshot تجاري مستقل؛ المخزون لا يتغير قبل تحويل الأوردر وتنفيذ دورة الوفاء.</p></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3 text-right">العرض</th><th class="p-3 text-right">التاريخ</th><th class="p-3 text-right">العميل</th><th class="p-3 text-right">المندوب</th><th class="p-3 text-right">الأصناف</th><th class="p-3 text-right">الإجمالي</th><th class="p-3 text-right">الحالة</th><th class="p-3 text-right">الإجراءات</th></tr></thead><tbody id="sq-table"><tr><td colspan="8" class="p-10 text-center text-slate-500">جاري التحميل...</td></tr></tbody></table></div></div>' +
            '</div>'
        );

        byId('sq-new').addEventListener('click', function () { openNew().catch(function (e) { showToast(e.message || 'فشل فتح نموذج العرض', 'error'); }); });
        byId('sq-refresh').addEventListener('click', function () { loadData().catch(function (e) { showToast(e.message || 'فشل التحديث', 'error'); }); });
        byId('sq-filter-status').addEventListener('change', function () { loadData().catch(function () {}); });
        byId('sq-filter-query').addEventListener('keydown', function (e) { if (e.key === 'Enter') loadData().catch(function () {}); });

        loadCatalog()
            .then(loadData)
            .catch(function (e) { showToast(e.message || 'فشل تحميل عروض الأسعار', 'error'); });

        clearInterval(state.timer);
        state.timer = setInterval(function () {
            if (byId('sq-table')) loadData().catch(function () {});
        }, 30000);
        bind();
    }

    return { render: render };
})();
window.RW_SalesQuotes = RW_SalesQuotes;

```

## 14) E2E status
`Browser click-by-click E2E = OPEN / NOT VERIFIED`

لا يتم اعتبار Backend PASS = Browser PASS.
لا يمكن إغلاق E2E قبل الدمج الفعلي للمالك.

## 15) Assembly
`forensic_main_assembly.yml` تم التحقق من أنه يشير إلى:
`erp-frontend/companies/company-1/main.html`

ولم يتم إعادته إلى `Current/PWA/main2`.

## 16) Final status
```text
Quote DB schema                 = CLOSED
Quote lifecycle RPC             = CLOSED
Quote idempotency               = CLOSED
Quote security                  = CLOSED
Quote Edge                       = DEPLOYED + VERIFIED
Quote inventory safety          = VERIFIED
Quote transactional E2E         = VERIFIED
Quote owner UI                  = OWNER MERGE REQUIRED
Browser E2E                     = OPEN
```

## 17) SELF-AUDIT
### ما تم إثباته
Production infrastructure, RPC lifecycle, security, idempotency, transactional conversion, no stock mutation.

### ما لم يتم إثباته
Browser click-by-click after owner merge.

### ما لا يجوز اعتباره مغلقًا
UI integration and browser E2E.

## 18) إرشادات للمساعد القادم
ابدأ من:
`CURRENT FRONTEND HEAD`
ثم:
`DIRECT PARENT`
ثم:
`CURRENT main.html`
ثم:
`CURRENT DATABASE`
ثم:
`CURRENT RPC DEFINITIONS`
ثم:
`CURRENT EDGE DEPLOYMENTS`
ثم:
`CURRENT RUNTIME`
ثم استخدم التقارير كـHistorical pointers فقط.

لا تعيد Quote من الصفر.
لا تعيد إصلاح ما ثبت أنه CLOSED إلا بدليل CURRENT متناقض.
لا تضف حركة مخزنية داخل Quote.
أي تعديل جديد يجب أن يمر:
`Evidence -> Contract -> Gap -> Surgical Change -> Test -> Deploy -> Production Verify -> Runtime Verify -> Document -> Close`
