/* RAWAEA ERP — OWNER-SIDE SURGICAL PATCH — Promotion Engine
 * TARGET ONLY: papamohammed77-glitch/erp-frontend/companies/company-1/main.html
 * DO NOT modify Current/PWA/main2 or New-main.
 */

/* 1) NAVIGATION — main.html ~1142
   Search exactly:
   { view: 'price-lists', label: 'قوائم الأسعار' },
   Add immediately after it:
*/
{ view: 'promotions', label: 'العروض والخصومات' },

/* 2) PERMISSION MAP — main.html ~17085
   Search exactly:
   'price-lists': 'orders',
   Add immediately after it:
*/
'promotions': 'orders',

/* 3) TITLES — main.html ~17144
   Search exactly:
   'price-lists':'قوائم الأسعار',
   Add immediately after it:
*/
'promotions':'العروض والخصومات',

/* 4) ROUTING — main.html ~17192
   Search exactly:
   if (view === 'price-lists') { RW_PriceLists.render(); return; }
   Add immediately after it:
*/
if (view === 'promotions') { RW_Promotions.render(); return; }

/* 5) COMPLETE MODULE — main.html after the exact line:
   window.RW_PriceLists = RW_PriceLists;
   Insert the complete module below BEFORE the existing EVENTS & BOOT separator.
*/
var RW_Promotions = (function () {
    'use strict';

    var state = { rows: [], catalog: { items: [], categories: [], customers: [], branches: [] }, editing: null, timer: null };

    function esc(v) {
        return String(v == null ? '' : v)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            .replace(/\\"/g, '&quot;').replace(/'/g, '&#39;');
    }

    async function api(action, payload) {
        var s = await supabase.auth.getSession();
        if (!s || s.error || !s.data || !s.data.session) throw new Error('جلسة المصادقة غير صالحة');
        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/promotion-engine', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + s.data.session.access_token },
            body: JSON.stringify(Object.assign({ action: action }, payload || {}))
        });
        var json = await res.json().catch(function () { return {}; });
        if (!res.ok || json.success === false) throw new Error(json.msg || json.error || 'فشل تنفيذ عملية العرض');
        return json;
    }

    function optionHtml(rows, value, textFn) {
        return (rows || []).map(function (x) {
            var text = textFn ? textFn(x) : (x.name || x.category_name || x.customer_code || x.branch_code || x.code || x.id);
            return '<option value="' + esc(x.id) + '" ' + (String(x.id) === String(value || '') ? 'selected' : '') + '>' + esc(text) + '</option>';
        }).join('');
    }

    async function loadCatalog() {
        var r = await api('catalog');
        state.catalog = { items: r.items || [], categories: r.categories || [], customers: r.customers || [], branches: r.branches || [] };
    }

    async function loadRows() {
        var r = await api('list');
        state.rows = r.rows || [];
        draw();
    }

    function badge(active) {
        return active ? '<span class="px-2 py-1 rounded-lg bg-emerald-100 text-emerald-700 font-black">نشط</span>' : '<span class="px-2 py-1 rounded-lg bg-slate-200 text-slate-700 font-black">متوقف</span>';
    }

    function draw() {
        var host = byId('rw-page-container'); if (!host) return;
        var active = state.rows.filter(function (x) { return x.is_active; }).length;
        var code = '<div class="space-y-6">' +
            '<div class="flex items-center justify-between flex-wrap gap-3">' +
                '<div><div class="text-sm text-slate-500 font-bold">المبيعات</div><h2 class="text-3xl font-black mt-1">العروض والخصومات</h2><p class="text-sm text-slate-500 mt-2">محرك عروض تجاري مستقل يدعم الخصم، الأرخص، Buy X Get Y، الأكواد، العملاء، الفروع والقنوات.</p></div>' +
                '<button id="promo-new" class="px-5 py-3 rounded-2xl bg-blue-600 text-white font-black shadow-lg">+ عرض جديد</button>' +
            '</div>' +
            '<div class="rw-kpi-grid">' +
                '<div class="rw-kpi-card"><div class="text-sm text-slate-500">إجمالي العروض</div><div class="text-3xl font-black mt-2">' + state.rows.length + '</div></div>' +
                '<div class="rw-kpi-card"><div class="text-sm text-slate-500">العروض النشطة</div><div class="text-3xl font-black mt-2 text-emerald-600">' + active + '</div></div>' +
                '<div class="rw-kpi-card"><div class="text-sm text-slate-500">عروض أكواد</div><div class="text-3xl font-black mt-2">' + state.rows.filter(function (x) { return x.trigger_mode === 'code'; }).length + '</div></div>' +
                '<div class="rw-kpi-card"><div class="text-sm text-slate-500">عروض Buy X Get Y</div><div class="text-3xl font-black mt-2">' + state.rows.filter(function (x) { return x.promotion_type === 'buy_x_get_y'; }).length + '</div></div>' +
            '</div>' +
            '<div class="bg-white rounded-3xl border shadow-sm overflow-hidden"><div class="p-4 border-b"><h3 class="font-black text-xl">دليل العروض</h3><p class="text-xs text-slate-500 mt-1">المحرك تجاري فقط ولا ينشئ حركة مخزنية مباشرة.</p></div>' +
            '<div class="overflow-x-auto"><table class="w-full text-sm"><thead class="bg-slate-50"><tr><th class="p-3">الكود</th><th class="p-3">الاسم</th><th class="p-3">النوع</th><th class="p-3">القناة</th><th class="p-3">الأولوية</th><th class="p-3">الصلاحية</th><th class="p-3">الحالة</th><th class="p-3">الإجراءات</th></tr></thead><tbody id="promo-table">' +
                (state.rows.length ? state.rows.map(function (x) { return '<tr class="border-t hover:bg-slate-50">' +
                    '<td class="p-3 font-black">' + esc(x.code) + '</td>' +
                    '<td class="p-3">' + esc(x.name) + '</td>' +
                    '<td class="p-3">' + esc(x.promotion_type) + '</td>' +
                    '<td class="p-3">' + esc(x.channel_scope) + '</td>' +
                    '<td class="p-3">' + esc(x.priority) + '</td>' +
                    '<td class="p-3">' + esc(x.valid_from || '') + ' → ' + esc(x.valid_until || '') + '</td>' +
                    '<td class="p-3">' + badge(x.is_active) + '</td>' +
                    '<td class="p-3"><div class="flex gap-2 flex-wrap">' +
                        '<button class="px-3 py-2 rounded-xl bg-blue-50 text-blue-700 font-black" data-promo-edit="' + esc(x.id) + '">تعديل</button>' +
                        '<button class="px-3 py-2 rounded-xl bg-violet-50 text-violet-700 font-black" data-promo-detail="' + esc(x.id) + '">التفاصيل</button>' +
                        '<button class="px-3 py-2 rounded-xl ' + (x.is_active ? 'bg-rose-50 text-rose-700' : 'bg-emerald-50 text-emerald-700') + ' font-black" data-promo-toggle="' + esc(x.id) + '">' + (x.is_active ? 'تعطيل' : 'تفعيل') + '</button>' +
                    '</div></td></tr>'; }).join('') : '<tr><td colspan="8" class="p-10 text-center text-slate-400">لا توجد عروض بعد</td></tr>') +
            '</tbody></table></div></div>' +
            '<div id="promo-modal-host"></div>' +
            '</div>';
        safeHTML(host, code);
        var n = byId('promo-new'); if (n) n.onclick = function () { openEditor(null); };
        var t = byId('promo-table');
        if (t) t.addEventListener('click', function (e) {
            var el = e.target.closest ? e.target.closest('[data-promo-edit],[data-promo-detail],[data-promo-toggle]') : null;
            if (!el) return;
            var id = el.getAttribute('data-promo-edit') || el.getAttribute('data-promo-detail') || el.getAttribute('data-promo-toggle');
            if (el.hasAttribute('data-promo-edit')) openEditor(id);
            else if (el.hasAttribute('data-promo-detail')) showDetail(id);
            else toggle(id);
        });
    }

    async function showDetail(id) {
        var r = await api('detail', { promotion_id: id });
        var p = r.promotion || {};
        var html = '<div id="promo-detail-modal" class="fixed inset-0 z-[1200] bg-black/50 flex items-center justify-center p-4"><div class="bg-white rounded-3xl shadow-2xl w-full max-w-5xl max-h-[92vh] overflow-auto p-6">' +
            '<div class="flex justify-between items-center mb-5"><h3 class="text-2xl font-black">تفاصيل العرض: ' + esc(p.name) + '</h3><button id="promo-detail-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">إغلاق</button></div>' +
            '<div class="grid grid-cols-2 md:grid-cols-5 gap-3 mb-5">' +
                '<div class="p-3 bg-slate-50 rounded-xl"><small>الكود</small><div class="font-black">' + esc(p.code) + '</div></div>' +
                '<div class="p-3 bg-slate-50 rounded-xl"><small>النوع</small><div class="font-black">' + esc(p.promotion_type) + '</div></div>' +
                '<div class="p-3 bg-slate-50 rounded-xl"><small>القناة</small><div class="font-black">' + esc(p.channel_scope) + '</div></div>' +
                '<div class="p-3 bg-slate-50 rounded-xl"><small>الحد الأدنى</small><div class="font-black">' + esc(p.min_subtotal) + '</div></div>' +
                '<div class="p-3 bg-slate-50 rounded-xl"><small>الحالة</small><div class="font-black">' + badge(p.is_active) + '</div></div>' +
            '</div>' +
            '<div class="mb-4"><h4 class="font-black text-lg mb-2">قواعد العرض</h4><div class="space-y-2">' + ((r.rules || []).map(function (x) { return '<div class="border rounded-2xl p-3 grid grid-cols-2 md:grid-cols-6 gap-2 text-sm"><span>Scope: <b>' + esc(x.scope_type) + '</b></span><span>Trigger: <b>' + esc(x.trigger_qty) + '</b></span><span>Reward: <b>' + esc(x.reward_type) + '</b></span><span>Value: <b>' + esc(x.reward_value) + '</b></span><span>Reward Qty: <b>' + esc(x.reward_qty) + '</b></span><span>Active: <b>' + (x.is_active ? 'نعم' : 'لا') + '</b></span></div>'; }).join('') || '<div class="p-4 bg-amber-50 rounded-xl">لا توجد قواعد فعالة.</div>') + '</div></div>' +
            '</div></div>';
        var host = byId('promo-modal-host'); if (!host) return; safeHTML(host, html); byId('promo-detail-close').onclick = function () { safeHTML(host, ''); };
    }

    async function openEditor(id) {
        if (!state.catalog.items.length) await loadCatalog();
        var p = id ? (await api('detail', { promotion_id: id })).promotion : {};
        var detail = id ? await api('detail', { promotion_id: id }) : { rules: [] };
        var rules = detail.rules || [];
        var host = byId('promo-modal-host'); if (!host) return;
        var modal = '<div id="promo-editor-modal" class="fixed inset-0 z-[1200] bg-black/50 flex items-center justify-center p-4"><div class="bg-white rounded-3xl shadow-2xl w-full max-w-7xl max-h-[95vh] overflow-auto p-6">' +
            '<div class="flex justify-between items-center mb-5"><div><h3 class="text-2xl font-black">' + (id ? 'تعديل العرض' : 'إنشاء عرض جديد') + '</h3><p class="text-sm text-slate-500 mt-1">العروض تغيّر السعر التجاري فقط؛ لا تكتب stock مباشرة.</p></div><button id="promo-close" class="px-4 py-2 rounded-xl bg-slate-100 font-black">إغلاق</button></div>' +
            '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">' +
                '<input id="promo-code" class="p-3 border rounded-xl" placeholder="كود العرض" value="' + esc(p.code || '') + '">' +
                '<input id="promo-name" class="p-3 border rounded-xl" placeholder="اسم العرض" value="' + esc(p.name || '') + '">' +
                '<select id="promo-type" class="p-3 border rounded-xl"><option value="discount">خصم</option><option value="cheapest_item">خصم على الأرخص</option><option value="buy_x_get_y">Buy X Get Y</option></select>' +
                '<select id="promo-stack" class="p-3 border rounded-xl"><option value="exclusive">عرض حصري</option><option value="stackable">قابل للتجميع</option></select>' +
            '</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-5 gap-3 mb-4">' +
                '<select id="promo-trigger" class="p-3 border rounded-xl"><option value="automatic">تلقائي</option><option value="code">بكود</option></select>' +
                '<input id="promo-coupon" class="p-3 border rounded-xl" placeholder="Coupon Code" value="' + esc(p.coupon_code || '') + '">' +
                '<select id="promo-channel" class="p-3 border rounded-xl"><option value="all">كل القنوات</option><option value="pos">POS</option><option value="telesales">Telesales</option><option value="order-taker">Order Taker</option><option value="van-sales">Van Sales</option><option value="online-store">Online Store</option></select>' +
                '<input id="promo-priority" type="number" min="0" class="p-3 border rounded-xl" placeholder="الأولوية" value="' + esc(p.priority == null ? 100 : p.priority) + '">' +
                '<input id="promo-min-subtotal" type="number" min="0" step="0.01" class="p-3 border rounded-xl" placeholder="حد أدنى لقيمة السلة" value="' + esc(p.min_subtotal || 0) + '">' +
            '</div>' +
            '<div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">' +
                '<input id="promo-valid-from" type="date" class="p-3 border rounded-xl" value="' + esc(p.valid_from || '') + '">' +
                '<input id="promo-valid-until" type="date" class="p-3 border rounded-xl" value="' + esc(p.valid_until || '') + '">' +
                '<input id="promo-max-discount" type="number" min="0" class="p-3 border rounded-xl" placeholder="حد أقصى للخصم" value="' + esc(p.max_discount || 0) + '">' +
                '<label class="flex items-center gap-2 p-3 border rounded-xl font-black"><input id="promo-active" type="checkbox" ' + (p.is_active === false ? '' : 'checked') + '> العرض نشط</label>' +
            '</div>' +
            '<div class="flex items-center justify-between mb-2"><h4 class="text-xl font-black">قواعد العرض</h4><button id="promo-rule-add" class="px-4 py-2 rounded-xl bg-violet-50 text-violet-700 font-black">+ قاعدة</button></div>' +
            '<div id="promo-rules" class="space-y-2">' + (rules.length ? '' : '') + '</div>' +
            '<div class="flex justify-end gap-3 mt-6"><button id="promo-save" class="px-6 py-3 rounded-2xl bg-blue-600 text-white font-black">حفظ العرض</button></div>' +
            '</div></div>';
        safeHTML(host, modal);
        byId('promo-type').value = p.promotion_type || 'discount'; byId('promo-stack').value = p.stacking_policy || 'exclusive'; byId('promo-trigger').value = p.trigger_mode || 'automatic'; byId('promo-channel').value = p.channel_scope || 'all';
        rules.forEach(addRuleRow);
        byId('promo-rule-add').onclick = function () { addRuleRow({}); };
        byId('promo-close').onclick = function () { safeHTML(host, ''); };
        byId('promo-save').onclick = function () { save(id); };
    }

    function addRuleRow(r) {
        var host = byId('promo-rules'); if (!host) return;
        var row = document.createElement('div'); row.className = 'grid grid-cols-12 gap-2 p-3 border rounded-2xl bg-slate-50 items-center';
        row.innerHTML =
            '<select data-scope class="col-span-2 p-2 border rounded-xl"><option value="all">كل السلة</option><option value="item">صنف</option><option value="category">تصنيف</option></select>' +
            '<select data-item class="col-span-2 p-2 border rounded-xl"><option value="">الصنف</option>' + optionHtml(state.catalog.items) + '</select>' +
            '<select data-category class="col-span-2 p-2 border rounded-xl"><option value="">التصنيف</option>' + optionHtml(state.catalog.categories, '', function (x) { return x.category_name; }) + '</select>' +
            '<input data-trigger type="number" min="1" step="0.01" class="col-span-1 p-2 border rounded-xl" placeholder="X">' +
            '<select data-reward class="col-span-2 p-2 border rounded-xl"><option value="percent">خصم %</option><option value="fixed">خصم ثابت</option><option value="cheapest_percent">خصم % على الأرخص</option><option value="cheapest_fixed">خصم ثابت على الأرخص</option><option value="free_item">صنف مجاني</option></select>' +
            '<input data-value type="number" min="0" step="0.01" class="col-span-1 p-2 border rounded-xl" placeholder="القيمة">' +
            '<button type="button" data-remove class="col-span-1 p-2 rounded-xl bg-rose-100 text-rose-700 font-black">×</button>';
        row.querySelector('[data-scope]').value = r.scope_type || 'all'; row.querySelector('[data-item]').value = r.item_id || ''; row.querySelector('[data-category]').value = r.category_id || ''; row.querySelector('[data-trigger]').value = r.trigger_qty || 1; row.querySelector('[data-reward]').value = r.reward_type || 'percent'; row.querySelector('[data-value]').value = r.reward_value || 0; row.querySelector('[data-remove]').onclick = function () { row.remove(); }; host.appendChild(row);
    }

    function rulesPayload() {
        return Array.prototype.slice.call(document.querySelectorAll('#promo-rules > div')).map(function (row, i) {
            var scope = row.querySelector('[data-scope]').value, reward = row.querySelector('[data-reward]').value;
            return { sequence: i + 1, scope_type: scope, item_id: scope === 'item' ? (row.querySelector('[data-item]').value || null) : null, category_id: scope === 'category' ? (row.querySelector('[data-category]').value || null) : null, trigger_qty: Number(row.querySelector('[data-trigger]').value || 1), reward_type: reward, reward_value: Number(row.querySelector('[data-value]').value || 0), reward_qty: reward === 'free_item' ? Number(row.querySelector('[data-trigger]').value || 0) : 0, reward_item_id: reward === 'free_item' ? (row.querySelector('[data-item]').value || null) : null, max_discount: 0, is_active: true };
        });
    }

    async function save(id) {
        var payload = { code: byId('promo-code').value.trim(), name: byId('promo-name').value.trim(), promotion_type: byId('promo-type').value, stacking_policy: byId('promo-stack').value, trigger_mode: byId('promo-trigger').value, coupon_code: byId('promo-coupon').value.trim() || null, channel_scope: byId('promo-channel').value, customer_scope: 'all', priority: Number(byId('promo-priority').value || 100), min_subtotal: Number(byId('promo-min-subtotal').value || 0), min_qty: 0, max_discount: Number(byId('promo-max-discount').value || 0), valid_from: byId('promo-valid-from').value || null, valid_until: byId('promo-valid-until').value || null, is_active: byId('promo-active').checked, rules: rulesPayload() };
        if (!payload.code || !payload.name) throw new Error('كود واسم العرض مطلوبان');
        if (id) payload.promotion_id = id;
        await api(id ? 'update' : 'create', payload);
        safeHTML(byId('promo-modal-host'), ''); await loadRows();
        if (typeof showToast === 'function') showToast('تم حفظ العرض بنجاح', 'success');
    }

    async function toggle(id) {
        var row = state.rows.find(function (x) { return String(x.id) === String(id); }); if (!row) return;
        await api('set_active', { promotion_id: id, is_active: !row.is_active });
        await loadRows();
    }

    async function render() {
        try { await loadCatalog(); await loadRows(); } catch (e) { var c = byId('rw-page-container'); if (c) safeHTML(c, '<div class="p-10 bg-white rounded-3xl border text-red-600 font-black">' + esc(e.message) + '</div>'); return; }
        if (state.timer) clearInterval(state.timer); state.timer = setInterval(function () { if (byId('promo-table')) loadRows().catch(function () {}); }, 30000);
    }

    return { render: render };
})();
window.RW_Promotions = RW_Promotions;
