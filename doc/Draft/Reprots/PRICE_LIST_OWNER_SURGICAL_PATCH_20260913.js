/* RAWAEA ERP — OWNER-SIDE SURGICAL PATCH — Price List Engine
 * TARGET ONLY: papamohammed77-glitch/erp-frontend/companies/company-1/main.html
 * DO NOT modify Current/PWA/main2 or any historical fragment.
 */

/* ============================================================
 * 1) NAVIGATION
 * CURRENT ANCHOR (main.html line ~1142):
 * search exactly: { view: 'quotes', label: 'عروض الأسعار' },
 * ADD IMMEDIATELY AFTER IT:
 */
{ view: 'price-lists', label: 'قوائم الأسعار' },

/* ============================================================
 * 2) RW_Views.permissionMap
 * CURRENT ANCHOR (main.html line ~17084):
 * search exactly: 'quotes': 'orders',
 * ADD IMMEDIATELY AFTER IT:
 */
'price-lists': 'orders',

/* ============================================================
 * 3) RW_Views.titles
 * CURRENT ANCHOR (main.html line ~17139):
 * search exactly: 'quotes':'عروض الأسعار',
 * ADD IMMEDIATELY AFTER IT:
 */
'price-lists':'قوائم الأسعار',

/* ============================================================
 * 4) RW_Views.render routing
 * CURRENT ANCHOR (main.html line ~17188):
 * search exactly:
 * if (view === 'quotes') { RW_SalesQuotes.render(); return; }
 * ADD IMMEDIATELY AFTER IT:
 */
if (view === 'price-lists') { RW_PriceLists.render(); return; }

/* ============================================================
 * 5) COMPLETE MODULE
 * CURRENT ANCHOR (main.html line ~18388):
 * the exact complete line:
 * window.RW_SalesQuotes = RW_SalesQuotes;
 * INSERT THE FOLLOWING COMPLETE MODULE IMMEDIATELY AFTER THAT LINE
 * AND BEFORE:
 * // ============================================================
 * // EVENTS & BOOT
 * // ============================================================
 */

var RW_PriceLists = (function () {
    'use strict';

    var state = { catalog: { lists: [], items: [], categories: [], customers: [] }, rows: [], editing: null, timer: null };

    function esc(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/\"/g, '&quot;').replace(/'/g, '&#39;');
    }

    function opId() {
        if (window.crypto && crypto.randomUUID) return crypto.randomUUID();
        return 'PL-' + Date.now() + '-' + Math.floor(Math.random() * 1000000);
    }

    async function api(action, payload) {
        var s = await supabase.auth.getSession();
        if (!s || s.error || !s.data || !s.data.session) throw new Error('جلسة المصادقة غير صالحة');
        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/commercial-catalog', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + s.data.session.access_token
            },
            body: JSON.stringify(Object.assign({ action: action }, payload || {}))
        });
        var json = await res.json().catch(function () { return {}; });
        if (!res.ok || json.success === false) throw new Error(json.msg || json.error || 'فشل تنفيذ عملية قائمة الأسعار');
        return json;
    }

    async function loadCatalog() {
        var r = await api('catalog');
        state.catalog = {
            lists: r.lists || [], items: r.items || [], categories: r.categories || [], customers: r.customers || []
        };
        state.rows = state.catalog.lists;
        renderRows();
    }

    function optionHtml(rows, value, textKey) {
        return rows.map(function (x) {
            var text = textKey ? x[textKey] : (x.name || x.item_name || x.category_name || x.customer_code || x.code || x.id);
            return '<option value="' + esc(x.id) + '" ' + (String(x.id) === String(value || '') ? 'selected' : '') + '>' + esc(text) + '</option>';
        }).join('');
    }

    function listRows() {
        var body = byId('pl-table');
        if (!body) return;
        if (!state.rows.length) {
            body.innerHTML = '<tr><td colspan="8" class="p-10 text-center text-slate-500">لا توجد قوائم أسعار بعد</td></tr>';
            return;
        }
        body.innerHTML = state.rows.map(function (x) {
            return '<tr class="border-t">' +
                '<td class="p-3 font-black">' + esc(x.code) + '</td>' +
                '<td class="p-3">' + esc(x.name) + '</td>' +
                '<td class="p-3">' + esc(x.currency) + '</td>' +
                '<td class="p-3">' + esc(x.priority) + '</td>' +
                '<td class="p-3">' + (x.is_default ? '<span class="px-2 py-1 rounded-lg bg-emerald-50 text-emerald-700 font-black">افتراضية</span>' : '') + '</td>' +
                '<td class="p-3">' + (x.is_active ? 'نشطة' : 'غير نشطة') + '</td>' +
                '<td class="p-3">' + esc(x.valid_from || '') + ' → ' + esc(x.valid_until || '') + '</td>' +
                '<td class="p-3"><div class="flex gap-2 flex-wrap">' +
                    '<button class="px-3 py-2 rounded-xl bg-blue-50 text-blue-700 font-black" data-pl-edit="' + esc(x.id) + '">تعديل</button>' +
                    '<button class="px-3 py-2 rounded-xl bg-violet-50 text-violet-700 font-black" data-pl-detail="' + esc(x.id) + '">التفاصيل</button>' +
                    '<button class="px-3 py-2 rounded-xl bg-amber-50 text-amber-700 font-black" data-pl-assign="' + esc(x.id) + '">تخصيص عميل</button>' +
                    (x.is_active ? '<button class="px-3 py-2 rounded-xl bg-rose-50 text-rose-700 font-black" data-pl-disable="' + esc(x.id) + '">تعطيل</button>' : '') +
                '</div></td>' +
                '</tr>';
        }).join('');
    }

    function renderRows() {
        var body = byId('pl-table');
        if (body) listRows();
        var k = byId('pl-kpis');
        if (k) k.innerHTML =
            '<div class="rw-kpi-card"><div class="text-sm text-slate-500">إجمالي القوائم</div><div class="text-3xl font-black mt-2">' + state.rows.length + '</div></div>' +
            '<div class="rw-kpi-card"><div class="text-sm text-slate-500">النشطة</div><div class="text-3xl font-black mt-2">' + state.rows.filter(function (x) { return x.is_active; }).length + '</div></div>' +
            '<div class="rw-kpi-card"><div class="text-sm text-slate-500">الافتراضية</div><div class="text-3xl font-black mt-2">' + state.rows.filter(function (x) { return x.is_default; }).length + '</div></div>' +
            '<div class="rw-kpi-card"><div class="text-sm text-slate-500">الأصناف المرجعية</div><div class="text-3xl font-black mt-2">' + state.catalog.items.length + '</div></div>';
    }

    function addRule(rule) {
        var host = byId('pl-rules'); if (!host) return;
        rule = rule || {};
        var row = document.createElement('div');
        row.className = 'grid grid-cols-12 gap-2 p-3 border rounded-2xl bg-slate-50 items-center';
        row.innerHTML =
            '<select data-pl-scope class="col-span-2 p-2 border rounded-xl"><option value="all">كل الأصناف</option><option value="category">تصنيف</option><option value="item">صنف محدد</option></select>' +
            '<select data-pl-item class="col-span-2 p-2 border rounded-xl">' + '<option value="">الصنف</option>' + optionHtml(state.catalog.items) + '</select>' +
            '<select data-pl-category class="col-span-2 p-2 border rounded-xl">' + '<option value="">التصنيف</option>' + optionHtml(state.catalog.categories, '', 'category_name') + '</select>' +
            '<input data-pl-min type="number" min="0.01" step="0.01" class="col-span-1 p-2 border rounded-xl" placeholder="أقل كمية">' +
            '<select data-pl-method class="col-span-2 p-2 border rounded-xl"><option value="fixed">سعر ثابت</option><option value="discount_percent">خصم %</option><option value="markup_percent">زيادة %</option></select>' +
            '<input data-pl-value type="number" min="0" step="0.01" class="col-span-1 p-2 border rounded-xl" placeholder="القيمة">' +
            '<input data-pl-fee type="number" step="0.01" class="col-span-1 p-2 border rounded-xl" placeholder="رسوم">' +
            '<button type="button" data-pl-remove class="col-span-1 p-2 rounded-xl bg-rose-100 text-rose-700 font-black">×</button>';
        row.querySelector('[data-pl-scope]').value = rule.scope_type || 'all';
        row.querySelector('[data-pl-item]').value = rule.item_id || '';
        row.querySelector('[data-pl-category]').value = rule.category_id || '';
        row.querySelector('[data-pl-min]').value = rule.min_qty || 1;
        row.querySelector('[data-pl-method]').value = rule.pricing_method || 'fixed';
        row.querySelector('[data-pl-value]').value = rule.pricing_method === 'fixed' ? (rule.unit_price || 0) : (rule.percent_value || 0);
        row.querySelector('[data-pl-fee]').value = rule.extra_fee || 0;
        row.querySelector('[data-pl-remove]').addEventListener('click', function () { row.remove(); });
        host.appendChild(row);
    }

    function readRules() {
        return Array.prototype.slice.call(document.querySelectorAll('#pl-rules > div')).map(function (row) {
            var scope = row.querySelector('[data-pl-scope]').value;
            var method = row.querySelector('[data-pl-method]').value;
            var value = Number(row.querySelector('[data-pl-value]').value || 0);
            return {
                sequence: 100,
                scope_type: scope,
                item_id: scope === 'item' ? (row.querySelector('[data-pl-item]').value || null) : null,
                category_id: scope === 'category' ? (row.querySelector('[data-pl-category]').value || null) : null,
                min_qty: Number(row.querySelector('[data-pl-min]').value || 1),
                pricing_method: method,
                unit_price: method === 'fixed' ? value : 0,
                percent_value: method === 'fixed' ? 0 : value,
                extra_fee: Number(row.querySelector('[data-pl-fee]').value || 0),
                rounding_multiple: 0,
                valid_from: null,
                valid_until: null,
                is_active: true
            };
        });
    }

    async function openEditor(list) {
        var detail = list ? await api('detail', { catalog_id: list.id }) : { catalog: {}, rules: [] };
        var x = detail.catalog || {};
        var modal = document.createElement('div');
        modal.id = 'pl-modal';
        modal.className = 'fixed inset-0 z-[1200] bg-black/50 flex items-center justify-center p-4';
        modal.innerHTML = '<div class="bg-white rounded-3xl shadow-2xl w-full max-w-7xl max-h-[95vh] overflow-auto p-6">' +
            '<div class="flex items-center justify-between mb-5"><div><h3 class="text-2xl font-black">' + (x.id ? 'تعديل قائمة الأسعار' : 'قائمة أسعار جديدة') + '</h3><p class="text-sm text-slate-500 mt-1">المحرك مستقل عن حركة المخزون ويعيد السعر التجاري قبل إنشاء السطر البيعي.</p></div><button id="pl-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">إغلاق</button></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-5 gap-3 mb-5">' +
                '<input id="pl-code" class="p-3 border rounded-xl" placeholder="الكود" value="' + esc(x.code || '') + '">' +
                '<input id="pl-name" class="p-3 border rounded-xl" placeholder="اسم القائمة" value="' + esc(x.name || '') + '">' +
                '<input id="pl-currency" class="p-3 border rounded-xl" placeholder="العملة" value="' + esc(x.currency || 'SAR') + '">' +
                '<input id="pl-priority" type="number" min="0" class="p-3 border rounded-xl" placeholder="الأولوية" value="' + esc(x.priority == null ? 100 : x.priority) + '">' +
                '<label class="flex items-center gap-2 p-3 border rounded-xl font-black"><input id="pl-default" type="checkbox" ' + (x.is_default ? 'checked' : '') + '> افتراضية</label>' +
            '</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-5">' +
                '<input id="pl-from" type="date" class="p-3 border rounded-xl" value="' + esc(x.valid_from || '') + '">' +
                '<input id="pl-until" type="date" class="p-3 border rounded-xl" value="' + esc(x.valid_until || '') + '">' +
                '<input id="pl-notes" class="p-3 border rounded-xl" placeholder="ملاحظات" value="' + esc(x.notes || '') + '">' +
            '</div>' +
            '<div class="flex items-center justify-between mb-3"><h4 class="font-black text-xl">قواعد التسعير</h4><button id="pl-add-rule" class="px-4 py-2 rounded-xl bg-emerald-600 text-white font-black">+ قاعدة</button></div>' +
            '<div id="pl-rules" class="space-y-2"></div>' +
            '<div class="flex justify-end gap-2 mt-6"><button id="pl-save" class="px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ القائمة</button></div>' +
        '</div>';
        document.body.appendChild(modal);
        (detail.rules || []).forEach(addRule);
        if (!(detail.rules || []).length) addRule({});
        modal.querySelector('#pl-close').addEventListener('click', function () { modal.remove(); });
        modal.querySelector('#pl-add-rule').addEventListener('click', function () { addRule({}); });
        modal.querySelector('#pl-save').addEventListener('click', async function () {
            try {
                showLoader('جاري حفظ قائمة الأسعار...');
                var payload = {
                    code: byId('pl-code').value.trim(),
                    name: byId('pl-name').value.trim(),
                    currency: byId('pl-currency').value.trim() || 'SAR',
                    priority: Number(byId('pl-priority').value || 100),
                    is_default: byId('pl-default').checked,
                    is_active: true,
                    valid_from: byId('pl-from').value || null,
                    valid_until: byId('pl-until').value || null,
                    notes: byId('pl-notes').value || null,
                    rules: readRules()
                };
                if (!payload.code || !payload.name) throw new Error('الكود والاسم مطلوبان');
                if (x.id) {
                    payload.catalog_id = x.id;
                    await api('update', payload);
                } else {
                    payload.operation_id = opId();
                    await api('create', payload);
                }
                hideLoader(); modal.remove(); showToast('تم حفظ قائمة الأسعار بنجاح', 'success'); await loadCatalog();
            } catch (e) { hideLoader(); showToast(e.message, 'error'); }
        });
    }

    async function assign(catalogId) {
        var customers = state.catalog.customers || [];
        if (!customers.length) { showToast('لا يوجد عملاء نشطون للتخصيص', 'error'); return; }
        var html = '<div style="text-align:right"><select id="pl-assign-customer" style="width:100%;padding:12px;border:1px solid #ddd;border-radius:12px">' + optionHtml(customers, '', 'name') + '</select></div>';
        var result = await Swal.fire({ title: 'تخصيص قائمة الأسعار لعميل', html: html, showCancelButton: true, confirmButtonText: 'تخصيص', cancelButtonText: 'إلغاء' });
        if (!result.isConfirmed) return;
        var customerId = byId('pl-assign-customer').value;
        if (!customerId) { showToast('اختر العميل', 'error'); return; }
        try { showLoader('جاري التخصيص...'); await api('assign', { catalog_id: catalogId, customer_id: customerId }); hideLoader(); showToast('تم تخصيص القائمة للعميل', 'success'); }
        catch (e) { hideLoader(); showToast(e.message, 'error'); }
    }

    async function detail(id) {
        try {
            showLoader('جاري تحميل التفاصيل...');
            var r = await api('detail', { catalog_id: id });
            hideLoader();
            var lines = (r.rules || []).map(function (x) { return '<tr><td class="p-2">' + esc(x.scope_type) + '</td><td class="p-2">' + esc(x.item_id || x.category_id || 'كل الأصناف') + '</td><td class="p-2">' + esc(x.min_qty) + '</td><td class="p-2">' + esc(x.pricing_method) + '</td><td class="p-2">' + esc(x.unit_price || x.percent_value || 0) + '</td></tr>'; }).join('');
            await Swal.fire({ title: r.catalog.name, html: '<div style="max-height:55vh;overflow:auto"><table style="width:100%;text-align:right"><thead><tr><th>النطاق</th><th>الهدف</th><th>الحد الأدنى</th><th>الطريقة</th><th>القيمة</th></tr></thead><tbody>' + (lines || '<tr><td colspan="5">لا توجد قواعد</td></tr>') + '</tbody></table></div>', width: '900px', confirmButtonText: 'إغلاق' });
        } catch (e) { hideLoader(); showToast(e.message, 'error'); }
    }

    async function disable(id) {
        var yes = await Swal.fire({ title: 'تعطيل قائمة الأسعار؟', icon: 'warning', showCancelButton: true, confirmButtonText: 'تعطيل', cancelButtonText: 'إلغاء' });
        if (!yes.isConfirmed) return;
        try { showLoader('جاري التعطيل...'); await api('delete', { catalog_id: id }); hideLoader(); showToast('تم تعطيل القائمة', 'success'); await loadCatalog(); }
        catch (e) { hideLoader(); showToast(e.message, 'error'); }
    }

    function bind() {
        var root = byId('rw-page-container'); if (!root) return;
        root.onclick = function (e) {
            var el = e.target.closest('[data-pl-edit],[data-pl-detail],[data-pl-assign],[data-pl-disable]');
            if (!el) return;
            var id = el.getAttribute('data-pl-edit') || el.getAttribute('data-pl-detail') || el.getAttribute('data-pl-assign') || el.getAttribute('data-pl-disable');
            if (el.hasAttribute('data-pl-edit')) { var row = state.rows.find(function (x) { return String(x.id) === String(id); }); openEditor(row).catch(function (err) { showToast(err.message, 'error'); }); }
            else if (el.hasAttribute('data-pl-detail')) detail(id);
            else if (el.hasAttribute('data-pl-assign')) assign(id);
            else disable(id);
        };
    }

    async function render() {
        var c = byId('rw-page-container'); if (!c) return;
        safeHTML(c, '<div class="space-y-6">' +
            '<div class="flex items-center justify-between flex-wrap gap-3"><div><div class="text-sm text-slate-500 font-bold">المبيعات</div><h2 class="text-3xl font-black mt-1">قوائم الأسعار</h2><p class="text-sm text-slate-500 mt-2">محرك تسعير تجاري متعدد القوائم والشرائح والعميل والكمية والصلاحية.</p></div><button id="pl-new" class="px-5 py-3 rounded-2xl bg-blue-600 text-white font-black shadow-lg">+ قائمة أسعار جديدة</button></div>' +
            '<div id="pl-kpis" class="rw-kpi-grid"></div>' +
            '<div class="bg-white rounded-3xl border shadow-sm overflow-hidden"><div class="p-4 border-b"><h3 class="font-black text-xl">القوائم</h3><p class="text-xs text-slate-500 mt-1">السعر الأساسي يظل items.sales_price، وقائمة الأسعار تعمل كطبقة تجارية فوقه.</p></div><div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">الاسم</th><th class="p-3">العملة</th><th class="p-3">الأولوية</th><th class="p-3">افتراضية</th><th class="p-3">الحالة</th><th class="p-3">الصلاحية</th><th class="p-3">الإجراءات</th></tr></thead><tbody id="pl-table"><tr><td colspan="8" class="p-10 text-center">جاري التحميل...</td></tr></tbody></table></div></div>' +
            '</div>');
        byId('pl-new').addEventListener('click', function () { openEditor(null).catch(function (e) { showToast(e.message, 'error'); }); });
        bind();
        try { await loadCatalog(); } catch (e) { showToast(e.message, 'error'); }
        clearInterval(state.timer);
        state.timer = setInterval(function () { if (byId('pl-table')) loadCatalog().catch(function () {}); }, 30000);
    }

    return { render: render };
})();
window.RW_PriceLists = RW_PriceLists;

/* ============================================================
 * 6) OPTIONAL QUOTE CONSUMER WIRING — DO NOT APPLY IN THIS CLOSURE
 * Keep the existing RW_SalesQuotes contract unchanged until the Price List
 * UI passes its own E2E. The resolve endpoint is production-ready and can be
 * connected in a separate surgical closure without reopening Quote backend.
 */
