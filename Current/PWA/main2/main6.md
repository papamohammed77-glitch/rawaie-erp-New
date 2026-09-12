// ============================================================
// RW_OnlineStore – المتجر الإلكتروني — Gold/Diamond owner replacement
// ============================================================
var RW_OnlineStore = (function() {
  var cart = {};
  var activeCat = 'الكل';
  var deliveryFee = 0;
  var taxRate = 0;
  var minInvoiceAmount = 0;
  var pendingOperationId = null;

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function escJs(s) {
    return String(s == null ? '' : s)
      .replace(/\\/g, '\\\\')
      .replace(/'/g, "\\'")
      .replace(/\r/g, '\\r')
      .replace(/\n/g, '\\n');
  }

  function todayIso() {
    return new Date().toISOString().slice(0, 10);
  }

  function effectivePrice(item) {
    var price = Number(item && item.sales_price) || 0;
    var pct = Number(item && item.discount_percent) || 0;
    var today = todayIso();
    var validStart = !item.discount_start || item.discount_start <= today;
    var validEnd = !item.discount_end || item.discount_end >= today;
    if (pct > 0 && validStart && validEnd) price = price - (price * Math.min(100, pct) / 100);
    return Math.max(0, price);
  }

  function findItem(code) {
    var items = RW_STATE.data.items || [];
    for (var i = 0; i < items.length; i++) if (items[i] && items[i].item_code === code) return items[i];
    return null;
  }

  async function loadSettings() {
    var companyId = _rwCompanyId();
    if (!companyId) throw new Error('سياق الشركة غير محدد');
    var res = await supabase.from('app_settings').select('delivery_fee, tax_rate, min_invoice_amount').eq('company_id', companyId).order('created_at', { ascending: true }).limit(1).maybeSingle();
    if (res.error) throw res.error;
    deliveryFee = Number(res.data && res.data.delivery_fee) || 0;
    taxRate = Number(res.data && res.data.tax_rate) || 0;
    minInvoiceAmount = Number(res.data && res.data.min_invoice_amount) || 0;
  }

  async function render() {
    var c = byId('rw-page-container');
    if (!c) return;
    safeText(byId('rw-header-title'), 'المتجر الإلكتروني');
    cart = {};
    pendingOperationId = null;
    try { await loadSettings(); } catch (e) { deliveryFee = 0; taxRate = 0; minInvoiceAmount = 0; console.error('Online Store settings load failed:', e); }
    if (!RW_STATE.data.items || !RW_STATE.data.items.length) {
      showLoader('جاري تحميل المنتجات...');
      try { await RW_Data.loadItems(); } finally { hideLoader(); }
    }
    safeHTML(c, '<div class="p-4"><div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4"><div class="bg-white rounded-2xl p-4 border"><div class="text-xs text-gray-500">رسوم التوصيل</div><div class="font-black text-lg">' + deliveryFee.toLocaleString() + ' EGP</div></div><div class="bg-white rounded-2xl p-4 border"><div class="text-xs text-gray-500">الضريبة</div><div class="font-black text-lg">' + taxRate + '%</div></div><div class="bg-white rounded-2xl p-4 border"><div class="text-xs text-gray-500">الحد الأدنى للطلب</div><div class="font-black text-lg">' + minInvoiceAmount.toLocaleString() + ' EGP</div></div></div><div class="flex flex-wrap justify-between items-center mb-4 gap-3"><div class="flex overflow-x-auto gap-2 pb-2" id="store-cats"></div><div class="flex gap-2"><button onclick="RW_OnlineStore._trackOrder()" class="bg-white border border-blue-200 text-blue-600 px-4 py-2 rounded-xl font-bold text-sm"><i class="fa-solid fa-magnifying-glass ml-1"></i> تتبع الطلب</button><button onclick="RW_OnlineStore._showCart()" class="bg-slate-100 px-4 py-2 rounded-xl font-bold relative">🛒 <span id="store-cart-badge">0</span></button></div></div><input type="text" id="store-search" class="w-full p-3 bg-white rounded-xl border mb-4" placeholder="ابحث بالاسم أو الكود..." oninput="RW_OnlineStore._renderCards()"><div class="grid grid-cols-2 md:grid-cols-4 gap-4" id="store-grid"></div></div>');
    buildCats();
    renderCards();
  }

  function buildCats() {
    var bar = byId('store-cats');
    if (!bar) return;
    var cats = ['الكل'];
    var items = RW_STATE.data.items || [];
    for (var i = 0; i < items.length; i++) { var cat = items[i] && items[i].category; if (cat && cats.indexOf(cat) === -1) cats.push(cat); }
    var h = '';
    for (var j = 0; j < cats.length; j++) h += '<button class="sub-tab-btn ' + (activeCat === cats[j] ? 'active-sub' : '') + '" onclick="RW_OnlineStore._setCat(\'' + escJs(cats[j]) + '\')">' + esc(cats[j]) + '</button>';
    safeHTML(bar, h);
  }

  function setCat(cat) { activeCat = cat; renderCards(); }

  function renderCards() {
    var grid = byId('store-grid');
    if (!grid) return;
    var items = RW_STATE.data.items || [];
    var q = (byId('store-search') ? byId('store-search').value : '').trim().toLowerCase();
    var filtered = items.filter(function(item) {
      if (!item || item.show_in_store === false || item.is_active === false) return false;
      var mc = activeCat === 'الكل' || item.category === activeCat;
      var text = ((item.name || '') + ' ' + (item.item_code || '') + ' ' + (item.barcode || '')).toLowerCase();
      return mc && (!q || text.indexOf(q) !== -1);
    });
    if (!filtered.length) { safeHTML(grid, '<div class="col-span-full text-center py-10 text-gray-400">لا توجد منتجات مطابقة</div>'); updateBadge(); return; }
    var h = '';
    for (var i = 0; i < filtered.length; i++) {
      var it = filtered[i], code = it.item_code || '', qty = Number(cart[code]) || 0, price = effectivePrice(it), original = Number(it.sales_price) || 0, maxQty = Number(it.max_qty_per_order) || 0;
      var image = esc(it.image_url || 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22%3E📦%3C/text%3E%3C/svg%3E');
      h += '<div class="bg-white rounded-xl p-3 border cursor-pointer shadow-sm hover:shadow-md"><div onclick="RW_OnlineStore._showProduct(\'' + escJs(code) + '\')"><img src="' + image + '" class="w-full h-35 object-cover rounded-lg mb-2" onerror="this.style.display=\'none\'"><div class="font-bold text-sm">' + esc(it.name || code) + '</div><div class="text-xs text-gray-400 mb-1">' + esc(code) + '</div><div class="flex items-center gap-2 mb-2"><span class="font-black text-blue-600">' + price.toLocaleString() + ' EGP</span>' + (price < original ? '<span class="text-xs text-gray-400 line-through">' + original.toLocaleString() + '</span>' : '') + '</div>' + (maxQty > 0 ? '<div class="text-[11px] text-gray-400 mb-2">الحد الأقصى: ' + maxQty + '</div>' : '') + '</div>' + (qty === 0 ? '<button onclick="event.stopPropagation();RW_OnlineStore._addToCart(\'' + escJs(code) + '\')" class="bg-blue-600 text-white w-full py-2 rounded-lg text-sm font-bold">إضافة للسلة</button>' : '<div class="flex items-center justify-between bg-slate-100 rounded-lg px-2 py-1"><button onclick="event.stopPropagation();RW_OnlineStore._updateCart(\'' + escJs(code) + '\',-1)" class="text-lg font-bold text-gray-500">-</button><span class="font-black text-blue-600">' + qty + '</span><button onclick="event.stopPropagation();RW_OnlineStore._updateCart(\'' + escJs(code) + '\',1)" class="text-lg font-bold text-gray-500">+</button></div>') + '</div>';
    }
    safeHTML(grid, h); updateBadge();
  }

  function addToCart(code) {
    var item = findItem(code);
    if (!item) { showToast('الصنف غير موجود', 'error'); return; }
    var current = Number(cart[code]) || 0, maxQty = Number(item.max_qty_per_order) || 0;
    if (maxQty > 0 && current >= maxQty) { showToast('تم الوصول للحد الأقصى للصنف', 'warning'); return; }
    cart[code] = current + 1; renderCards();
  }

  function updateCart(code, d) {
    var item = findItem(code); if (!item) return;
    var next = (Number(cart[code]) || 0) + Number(d || 0), maxQty = Number(item.max_qty_per_order) || 0;
    if (next <= 0) delete cart[code]; else if (maxQty > 0 && next > maxQty) showToast('تم الوصول للحد الأقصى للصنف', 'warning'); else cart[code] = next;
    renderCards();
  }

  function updateBadge() { var t = 0; for (var k in cart) t += Number(cart[k]) || 0; var b = byId('store-cart-badge'); if (b) safeText(b, t); }

  function showProduct(code) {
    var it = findItem(code); if (!it) return;
    var maxQty = Number(it.max_qty_per_order) || 0, text = it.description || '';
    if (maxQty > 0) text += '\n\nالحد الأقصى للطلب: ' + maxQty;
    Swal.fire({ imageUrl: it.image_url || undefined, imageWidth: 220, title: esc(it.name || code), text: text, showCancelButton: true, confirmButtonText: (cart[code] || 0) > 0 ? 'الكمية: ' + (cart[code] || 0) : 'إضافة للسلة', cancelButtonText: 'إغلاق' }).then(function(r) { if (r.isConfirmed) addToCart(code); });
  }

  function buildCartData() {
    var arr = [], subtotal = 0;
    for (var code in cart) { var it = findItem(code); if (!it) continue; var qty = Number(cart[code]) || 0; if (qty <= 0) continue; var price = effectivePrice(it); subtotal += price * qty; arr.push({ code: code, name: it.name || code, qty: qty, price: price, unit: it.unit || 'حبة' }); }
    return { items: arr, subtotal: subtotal };
  }

  function showCart() {
    var built = buildCartData(); if (!built.items.length) { showToast('السلة فارغة', 'info'); return; }
    var del = deliveryFee || 0, beforeTax = built.subtotal + del, taxAmt = Math.round(beforeTax * taxRate) / 100, total = beforeTax + taxAmt, itemsH = '';
    for (var i = 0; i < built.items.length; i++) { var ci = built.items[i]; itemsH += '<div class="flex justify-between items-center p-3 bg-slate-50 rounded-xl mb-2"><span>' + esc(ci.name) + '</span><span>' + ci.qty + ' × ' + ci.price.toLocaleString() + ' = ' + (ci.qty * ci.price).toLocaleString() + ' EGP</span></div>'; }
    var h = '<div class="text-right">' + itemsH + '<div class="border-t pt-3 mt-3"><div class="flex justify-between mb-2"><span>المجموع:</span><span>' + built.subtotal.toLocaleString() + ' EGP</span></div>' + (del > 0 ? '<div class="flex justify-between mb-2"><span>رسوم التوصيل:</span><span>' + del.toLocaleString() + ' EGP</span></div>' : '') + (taxRate > 0 ? '<div class="flex justify-between mb-2"><span>الضريبة (' + taxRate + '%):</span><span>' + taxAmt.toLocaleString() + ' EGP</span></div>' : '') + '<div class="flex justify-between mb-4"><span class="font-black text-lg">الإجمالي:</span><span class="font-black text-lg text-emerald-600">' + total.toLocaleString() + ' EGP</span></div></div><input id="oc-name" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="الاسم الكامل"><input id="oc-phone" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="رقم الهاتف"><input id="oc-area" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="العنوان / المنطقة"></div>';
    Swal.fire({ title: 'سلة التسوق', html: h, width: '620px', showCancelButton: true, confirmButtonText: 'إرسال الطلب', cancelButtonText: 'متابعة التسوق', preConfirm: function() { var nm = document.getElementById('oc-name').value.trim(), ph = document.getElementById('oc-phone').value.trim(), ar = document.getElementById('oc-area').value.trim(); if (!nm || !ph || !ar) { Swal.showValidationMessage('الرجاء إكمال البيانات'); return false; } if (minInvoiceAmount > 0 && total < minInvoiceAmount) { Swal.showValidationMessage('قيمة الطلب أقل من الحد الأدنى: ' + minInvoiceAmount.toLocaleString() + ' EGP'); return false; } return { name: nm, phone: ph, area: ar, total: total, delivery: del, items: built.items }; } }).then(async function(r) {
      if (!r.isConfirmed || !r.value) return;
      showLoader('جاري إرسال الطلب...');
      try {
        var ses = await supabase.auth.getSession(), token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
        if (!token) throw new Error('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');
        if (!pendingOperationId) pendingOperationId = (crypto && crypto.randomUUID) ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random();
        var user = { name: r.value.name, area: r.value.area, phone: r.value.phone, notes: '' };
        var res = await fetch(SUPABASE_URL + '/functions/v1/submit-online-order', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token, 'Idempotency-Key': pendingOperationId }, body: JSON.stringify({ user: user, cartItems: r.value.items, total: r.value.total, delivery: r.value.delivery, operation_id: pendingOperationId }) });
        var json = await res.json(); if (!res.ok || !json || !json.success) throw new Error((json && json.msg) || 'فشل إرسال الطلب');
        pendingOperationId = null; cart = {}; hideLoader(); showToast(json.duplicate ? 'تم استرجاع نتيجة الطلب السابق' : 'تم إرسال الطلب بنجاح', 'success'); renderCards();
      } catch (e) { hideLoader(); showToast(e.message || 'فشل الاتصال', 'error'); }
    });
  }

  async function trackOrder() {
    var input = await Swal.fire({ title: 'تتبع حالة الطلب', input: 'text', inputLabel: 'أدخل رقم الطلب', inputPlaceholder: 'مثلاً: ORD-...', showCancelButton: true, confirmButtonText: 'استعلام', cancelButtonText: 'إلغاء' });
    if (!input.isConfirmed || !input.value) return;
    showLoader('جاري جلب حالة الطلب...');
    try {
      var companyId = _rwCompanyId(); if (!companyId) throw new Error('سياق الشركة غير محدد');
      var code = String(input.value).trim();
      var o = await supabase.from('orders').select('id, order_code, customer_name, area, total_amount, order_status, delivery_fee').eq('company_id', companyId).eq('order_code', code).maybeSingle();
      if (o.error || !o.data) throw new Error('لم يتم العثور على طلب بهذا الرقم');
      var it = await supabase.from('order_details').select('item_name, qty, unit_price, line_amount').eq('order_id', o.data.id); if (it.error) throw it.error;
      var itemsH = '';
      if (it.data && it.data.length) { itemsH = '<table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">السعر</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>'; for (var i = 0; i < it.data.length; i++) { var row = it.data[i], lineTotal = Number(row.line_amount); if (!Number.isFinite(lineTotal)) lineTotal = (Number(row.qty) || 0) * (Number(row.unit_price) || 0); itemsH += '<tr><td class="p-2">' + esc(row.item_name || '') + '</td><td class="p-2 text-center">' + (Number(row.qty) || 0) + '</td><td class="p-2 text-center">' + (Number(row.unit_price) || 0).toLocaleString() + '</td><td class="p-2 text-center font-bold">' + lineTotal.toLocaleString() + '</td></tr>'; } itemsH += '</tbody></table>'; }
      var statusMap = { Pending: ['قيد الانتظار', 'text-yellow-600'], Confirmed: ['مؤكد', 'text-blue-600'], Invoiced: ['تمت الفوترة', 'text-green-600'], Delivered: ['تم التوصيل', 'text-green-700'], Cancelled: ['ملغي', 'text-red-600'] }, status = statusMap[o.data.order_status] || [o.data.order_status || '-', 'text-gray-600'];
      hideLoader(); Swal.fire({ title: 'تفاصيل الطلب: ' + esc(code), html: '<div class="text-right"><p class="mb-3"><strong>حالة الطلب:</strong> <span class="font-bold ' + status[1] + '">' + esc(status[0]) + '</span></p><p class="mb-2"><strong>العميل:</strong> ' + esc(o.data.customer_name || 'غير محدد') + '</p><p class="mb-2"><strong>المنطقة:</strong> ' + esc(o.data.area || '-') + '</p>' + itemsH + '<div class="mt-4 font-bold text-lg">الإجمالي: ' + (Number(o.data.total_amount) || 0).toLocaleString() + ' EGP</div></div>', width: '720px', showCloseButton: true, showConfirmButton: false });
    } catch (e) { hideLoader(); showToast(e.message || 'فشل جلب البيانات', 'error'); }
  }

  return { render: render, _setCat: setCat, _renderCards: renderCards, _addToCart: addToCart, _updateCart: updateCart, _showCart: showCart, _showProduct: showProduct, _trackOrder: trackOrder };
})();
window.RW_OnlineStore = RW_OnlineStore;
// ============================================================
// RW_Purchases – المشتريات — Gold/Diamond owner replacement
// ============================================================
var RW_Purchases = (function() {
  var poData = [];
  var cart = [];
  var poSearch = '';
  var poStatus = '';

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function escJs(s) {
    return String(s == null ? '' : s)
      .replace(/\\/g, '\\\\')
      .replace(/'/g, "\\'")
      .replace(/\r/g, '\\r')
      .replace(/\n/g, '\\n');
  }

  function companyIdOrFail() {
    var id = _rwCompanyId();
    if (!id) throw new Error('سياق الشركة غير محدد');
    return id;
  }

  async function renderOrders() {
    var c = byId('rw-page-container');
    if (!c) return;
    safeText(byId('rw-header-title'), 'أوردرات الشراء');
    safeHTML(c, '<div class="p-4"><div class="flex flex-wrap justify-between items-center mb-4 gap-3"><h2 class="text-xl font-bold"><i class="fa-solid fa-truck-fast ml-2"></i> أوامر الشراء</h2><button onclick="RW_Navigation.navigate(\'purchase-pos\')" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-plus ml-1"></i> أمر شراء جديد</button></div><div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4"><input id="po-list-search" class="p-3 bg-white rounded-xl border" placeholder="بحث برقم الأمر أو المورد..." oninput="RW_Purchases._filterOrders()"><select id="po-list-status" class="p-3 bg-white rounded-xl border" onchange="RW_Purchases._filterOrders()"><option value="">كل الحالات</option><option value="Draft">مسودة</option><option value="Partially Received">استلام جزئي</option><option value="Received">مستلم</option></select><div id="po-list-summary" class="bg-white rounded-xl border p-3 font-bold text-center">0 أمر</div></div><div class="bg-white rounded-2xl shadow-sm border overflow-y-auto" id="po-table-wrapper" style="max-height:65vh"><div class="text-center py-8">جاري التحميل...</div></div></div>');
    var companyId = companyIdOrFail();
    var res = await supabase.from('purchase_orders').select('*').eq('company_id', companyId).order('po_date', { ascending: false }).order('created_at', { ascending: false });
    if (res.error) { showToast('تعذر تحميل أوامر الشراء', 'error'); return; }
    poData = res.data || [];
    renderPOTable(poData);
  }

  function filterOrders() {
    poSearch = ((byId('po-list-search') && byId('po-list-search').value) || '').trim().toLowerCase();
    poStatus = (byId('po-list-status') && byId('po-list-status').value) || '';
    renderPOTable(poData.filter(function(o) {
      var text = ((o.po_code || '') + ' ' + (o.supplier_name || '')).toLowerCase();
      return (!poSearch || text.indexOf(poSearch) !== -1) && (!poStatus || o.status === poStatus);
    }));
  }

  function renderPOTable(data) {
    var w = byId('po-table-wrapper');
    if (!w) return;
    safeText(byId('po-list-summary'), data.length + ' أمر');
    if (!data.length) { safeHTML(w, '<div class="text-center py-8 text-gray-400">لا توجد أوامر شراء</div>'); return; }
    var h = '<table class="w-full text-sm"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">رقم الأمر</th><th class="p-3">التاريخ</th><th class="p-3">المورد</th><th class="p-3 text-center">القيمة</th><th class="p-3 text-center">الحالة</th><th class="p-3 text-center">إجراءات</th></tr></thead><tbody>';
    for (var i = 0; i < data.length; i++) {
      var o = data[i], status = o.status || '-', canReceive = status === 'Draft' || status === 'Sent' || status === 'Partially Received';
      h += '<tr class="border-b hover:bg-gray-50"><td class="p-3 font-bold text-emerald-700">' + esc(o.po_code) + '</td><td class="p-3">' + esc(o.po_date) + '</td><td class="p-3">' + esc(o.supplier_name) + '</td><td class="p-3 text-center font-bold">' + (Number(o.total_amount) || 0).toLocaleString() + ' EGP</td><td class="p-3 text-center">' + esc(status) + '</td><td class="p-3 text-center"><div class="flex justify-center gap-2"><button onclick="RW_Purchases._openPO(\'' + escJs(o.po_code) + '\')" class="text-slate-600" title="تفاصيل"><i class="fa-solid fa-eye"></i></button>' + (canReceive ? '<button onclick="RW_Purchases._openReceive(\'' + escJs(o.po_code) + '\')" class="text-blue-600" title="استلام"><i class="fa-solid fa-truck-loading"></i></button>' : '') + '</div></td></tr>';
    }
    h += '</tbody></table>'; safeHTML(w, h);
  }

  async function openPO(poCode) {
    showLoader('جاري جلب تفاصيل أمر الشراء...');
    try {
      var companyId = companyIdOrFail();
      var poRes = await supabase.from('purchase_orders').select('*').eq('company_id', companyId).eq('po_code', poCode).maybeSingle();
      if (poRes.error || !poRes.data) throw new Error('أمر الشراء غير موجود');
      var dRes = await supabase.from('purchase_order_details').select('*').eq('po_id', poRes.data.id).order('created_at', { ascending: true });
      if (dRes.error) throw dRes.error;
      var rows = dRes.data || [], h = '<div class="text-right"><div class="grid grid-cols-2 gap-3 mb-4"><div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-gray-500">المورد</div><div class="font-bold">' + esc(poRes.data.supplier_name) + '</div></div><div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-gray-500">الحالة</div><div class="font-bold">' + esc(poRes.data.status) + '</div></div></div><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">المستلم</th><th class="p-2 text-center">المتبقي</th><th class="p-2 text-center">السعر</th></tr></thead><tbody>';
      for (var i = 0; i < rows.length; i++) { var r = rows[i], ordered = Number(r.qty_ordered) || 0, received = Number(r.qty_received) || 0; h += '<tr class="border-b"><td class="p-2 font-semibold">' + esc(r.item_name || r.item_code) + '</td><td class="p-2 text-center">' + ordered + '</td><td class="p-2 text-center">' + received + '</td><td class="p-2 text-center font-bold">' + Math.max(0, ordered - received) + '</td><td class="p-2 text-center">' + (Number(r.unit_price) || 0).toLocaleString() + '</td></tr>'; }
      h += '</tbody></table><div class="mt-4 font-black text-lg">الإجمالي: ' + (Number(poRes.data.total_amount) || 0).toLocaleString() + ' EGP</div></div>';
      hideLoader(); Swal.fire({ title: 'تفاصيل ' + esc(poCode), html: h, width: '820px', showConfirmButton: false, showCloseButton: true });
    } catch (e) { hideLoader(); showToast(e.message || 'فشل تحميل التفاصيل', 'error'); }
  }

  async function openReceive(poCode) {
    showLoader('جاري جلب تفاصيل الاستلام...');
    try {
      var companyId = companyIdOrFail();
      var poRes = await supabase.from('purchase_orders').select('*').eq('company_id', companyId).eq('po_code', poCode).maybeSingle();
      if (poRes.error || !poRes.data) throw new Error('أمر الشراء غير موجود');
      var itemsRes = await supabase.from('purchase_order_details').select('*').eq('po_id', poRes.data.id).order('created_at', { ascending: true });
      if (itemsRes.error) throw itemsRes.error;
      hideLoader();
      var items = itemsRes.data || [], html = '<div class="text-right"><div class="mb-3 text-sm text-gray-500">يمكن استلام الكمية المتبقية فقط. إعادة المحاولة تستخدم نفس هوية العملية إذا بقيت النافذة مفتوحة.</div><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">المستلم</th><th class="p-2 text-center">المتبقي</th><th class="p-2 text-center">الاستلام الآن</th><th class="p-2">سبب/ملاحظة</th></tr></thead><tbody>';
      for (var i = 0; i < items.length; i++) { var it = items[i], ordered = Number(it.qty_ordered) || 0, received = Number(it.qty_received) || 0, remaining = Math.max(0, ordered - received); html += '<tr class="border-b"><td class="p-2 font-semibold">' + esc(it.item_name || it.item_code) + '<div class="text-xs text-gray-400">' + esc(it.item_code) + '</div></td><td class="p-2 text-center">' + ordered + '</td><td class="p-2 text-center">' + received + '</td><td class="p-2 text-center font-bold">' + remaining + '</td><td class="p-2 text-center"><input type="number" id="rec-qty-' + i + '" value="' + remaining + '" max="' + remaining + '" min="0" step="0.01" class="w-24 p-1 border rounded text-center"></td><td class="p-2"><input type="text" id="rec-note-' + i + '" class="w-36 p-1 border rounded" placeholder="اختياري"></td></tr>'; }
      html += '</tbody></table></div>';
      Swal.fire({ title: 'استلام بضاعة: ' + esc(poCode), html: html, width: '1000px', showCancelButton: true, confirmButtonText: 'اعتماد الاستلام', confirmButtonColor: '#10b981', cancelButtonText: 'إلغاء', preConfirm: function() { var received = [], hasQty = false; for (var i = 0; i < items.length; i++) { var q = Number(document.getElementById('rec-qty-' + i).value) || 0, remaining = Math.max(0, (Number(items[i].qty_ordered) || 0) - (Number(items[i].qty_received) || 0)); if (q < 0 || q > remaining) { Swal.showValidationMessage('الكمية غير صالحة للصنف: ' + (items[i].item_code || '')); return false; } if (q > 0) { hasQty = true; received.push({ itemCode: items[i].item_code, itemName: items[i].item_name, unit: items[i].unit, receivedQty: q, reason: (document.getElementById('rec-note-' + i).value || '').trim() }); } } if (!hasQty) { Swal.showValidationMessage('أدخل كمية استلام واحدة على الأقل'); return false; } return received; } }).then(async function(r) {
        if (!r.isConfirmed || !r.value || !r.value.length) return;
        showLoader('جاري حفظ الاستلام...');
        try {
          var ses = await supabase.auth.getSession(), token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
          if (!token) throw new Error('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');
          var receiveOperationId = (crypto && crypto.randomUUID) ? crypto.randomUUID() : String(Date.now()) + '-' + Math.random();
          var res = await fetch(SUPABASE_URL + '/functions/v1/receive-purchase', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token, 'Idempotency-Key': receiveOperationId }, body: JSON.stringify({ po_code: poCode, itemsReceived: r.value, operation_id: receiveOperationId }) });
          var json = await res.json();
          if (!res.ok || !json || !json.success) throw new Error((json && json.msg) || 'فشل الاستلام');
          hideLoader(); showToast(json.duplicate ? 'تم استرجاع نتيجة الاستلام السابق' : 'تم الاستلام بنجاح', 'success'); await renderOrders();
        } catch (e) { hideLoader(); showToast(e.message || 'فشل الاتصال', 'error'); }
      });
    } catch (e) { hideLoader(); showToast(e.message || 'فشل تحميل الاستلام', 'error'); }
  }

  async function renderPOS() {
    var c = byId('rw-page-container'); if (!c) return;
    safeText(byId('rw-header-title'), 'نقطة شراء');
    if (!RW_STATE.data.items || !RW_STATE.data.items.length) { showLoader('جاري تحميل الأصناف...'); try { await RW_Data.loadItems(); } finally { hideLoader(); } }
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) {
      var companyId = companyIdOrFail(), sRes = await supabase.from('suppliers').select('*').eq('company_id', companyId).eq('is_active', true).order('name', { ascending: true });
      if (sRes.error) { showToast('تعذر تحميل الموردين', 'error'); RW_STATE.data.suppliers = []; } else RW_STATE.data.suppliers = sRes.data || [];
    }
    safeHTML(c, '<div class="grid grid-cols-1 lg:grid-cols-4 gap-6 p-4"><div class="lg:col-span-1 space-y-4"><div class="bg-white p-4 rounded-xl shadow-sm"><label class="text-sm font-bold">اختيار المورد</label><select id="po-supplier" class="w-full p-2.5 bg-gray-50 border rounded-lg"></select></div><div class="bg-white p-4 rounded-xl shadow-sm"><label class="text-sm font-bold">البحث عن صنف بالاسم أو الكود أو الباركود</label><input type="text" id="po-search" oninput="RW_Purchases._searchItem(this.value)" placeholder="ابحث..." class="w-full p-2.5 bg-gray-50 border rounded-lg"><div id="po-dropdown" class="absolute z-50 bg-white shadow-xl rounded-xl max-h-72 overflow-y-auto hidden border"></div></div></div><div class="lg:col-span-3 bg-white rounded-xl shadow-md overflow-hidden flex flex-col min-h-[520px]"><div class="bg-emerald-700 text-white p-4 flex justify-between"><h2 class="font-bold text-lg">أمر شراء جديد</h2><span id="po-count">0</span></div><div class="flex-1 overflow-y-auto p-4"><table class="w-full text-right"><thead><tr class="text-xs text-gray-500"><th class="p-2">الصنف</th><th class="p-2 text-center">سعر الشراء</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">الإجمالي</th><th></th></tr></thead><tbody id="po-cart-body"><tr><td colspan="5" class="p-8 text-center">لا توجد أصناف</td></tr></tbody></table></div><div class="p-4 bg-gray-50 border-t flex justify-between"><div><span class="text-gray-500">الإجمالي:</span><span id="po-total" class="text-3xl font-bold">0</span></div><div class="flex gap-2"><button onclick="RW_Purchases._clearCart()" class="px-4 py-2 bg-red-500 text-white rounded-lg">مسح</button><button onclick="RW_Purchases._savePO()" class="px-6 py-2 bg-emerald-600 text-white rounded-lg">حفظ أمر الشراء</button></div></div></div></div>');
    loadSuppliers(); renderPOCart();
  }

  function loadSuppliers() {
    var sel = byId('po-supplier'); if (!sel) return;
    var suppliers = RW_STATE.data.suppliers || [], h = '<option value="">-- اختر مورداً --</option>';
    for (var i = 0; i < suppliers.length; i++) h += '<option value="' + esc(suppliers[i].id) + '">' + esc(suppliers[i].name || suppliers[i].supplier_code || '') + '</option>';
    safeHTML(sel, h);
  }

  function searchItem(q) {
    var dd = byId('po-dropdown'); if (!dd) return; var query = (q || '').trim().toLowerCase(); if (!query) { dd.classList.add('hidden'); return; }
    var items = RW_STATE.data.items || [], f = items.filter(function(i) { return (((i.name || '') + ' ' + (i.item_code || '') + ' ' + (i.barcode || '')).toLowerCase().indexOf(query) !== -1); }).slice(0, 25);
    if (!f.length) { safeHTML(dd, '<div class="p-3 text-center text-gray-500">لا توجد نتائج</div>'); dd.classList.remove('hidden'); return; }
    var h = '';
    for (var i = 0; i < f.length; i++) { var item = f[i]; h += '<div onclick="RW_Purchases._addToCart(\'' + escJs(item.item_code) + '\')" class="p-3 hover:bg-emerald-50 cursor-pointer flex justify-between border-b"><div><div class="font-bold">' + esc(item.name || item.item_code) + '</div><div class="text-xs text-gray-400">' + esc(item.item_code) + (item.barcode ? ' | ' + esc(item.barcode) : '') + '</div></div><div class="text-emerald-600 font-bold">' + (Number(item.cost_price) || 0).toLocaleString() + ' EGP</div></div>'; }
    safeHTML(dd, h); dd.classList.remove('hidden');
  }

  function addToCart(code) {
    var items = RW_STATE.data.items || [], item = null;
    for (var i = 0; i < items.length; i++) if (items[i].item_code === code) { item = items[i]; break; }
    if (!item) return;
    for (var j = 0; j < cart.length; j++) if (cart[j].code === code) { cart[j].qty++; renderPOCart(); return; }
    cart.push({ code: item.item_code, name: item.name, price: Number(item.cost_price) || 0, unit: item.unit || 'حبة', qty: 1 });
    if (byId('po-search')) byId('po-search').value = '';
    if (byId('po-dropdown')) byId('po-dropdown').classList.add('hidden');
    renderPOCart();
  }

  function updateQty(idx, v) { var q = Number(v); if (!Number.isFinite(q) || q <= 0) cart.splice(idx, 1); else cart[idx].qty = q; renderPOCart(); }
  function updatePrice(idx, v) { var price = Number(v); if (!Number.isFinite(price) || price < 0) return; cart[idx].price = price; renderPOCart(); }
  function removeItem(idx) { cart.splice(idx, 1); renderPOCart(); }
  function clearCart() { cart = []; renderPOCart(); }

  function renderPOCart() {
    var tb = byId('po-cart-body'), totalEl = byId('po-total'), countEl = byId('po-count'); if (!tb) return;
    if (!cart.length) { safeHTML(tb, '<tr><td colspan="5" class="p-8 text-center">لا توجد أصناف</td></tr>'); safeText(totalEl, '0'); safeText(countEl, '0'); return; }
    var total = 0, h = '';
    for (var i = 0; i < cart.length; i++) { var it = cart[i], line = (Number(it.price) || 0) * (Number(it.qty) || 0); total += line; h += '<tr class="border-b"><td class="p-2 font-bold">' + esc(it.name) + '<div class="text-xs text-gray-400">' + esc(it.code) + '</div></td><td class="p-2 text-center"><input type="number" min="0" step="0.01" value="' + (Number(it.price) || 0) + '" onchange="RW_Purchases._updatePrice(' + i + ',this.value)" class="w-24 p-1 border rounded text-center"></td><td class="p-2 text-center"><input type="number" min="0.01" step="0.01" value="' + (Number(it.qty) || 0) + '" onchange="RW_Purchases._updateQty(' + i + ',this.value)" class="w-20 p-1 border rounded text-center"></td><td class="p-2 text-center font-bold">' + line.toLocaleString() + '</td><td class="p-2 text-center"><button onclick="RW_Purchases._removeItem(' + i + ')" class="text-red-500"><i class="fa-solid fa-trash"></i></button></td></tr>'; }
    safeHTML(tb, h); safeText(totalEl, total.toLocaleString()); safeText(countEl, String(cart.length));
  }

  async function savePO() {
    var supplierId = byId('po-supplier') ? byId('po-supplier').value : '';
    if (!supplierId) { showToast('اختر مورداً', 'warning'); return; }
    if (!cart.length) { showToast('أضف أصنافاً', 'warning'); return; }
    var supplier = null, suppliers = RW_STATE.data.suppliers || [];
    for (var i = 0; i < suppliers.length; i++) if (suppliers[i].id === supplierId) { supplier = suppliers[i]; break; }
    if (!supplier) { showToast('المورد غير موجود', 'error'); return; }
    showLoader('جاري الحفظ...');
    try {
      var ses = await supabase.auth.getSession(), token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
      if (!token) throw new Error('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');
      var res = await fetch(SUPABASE_URL + '/functions/v1/save-purchase-order', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }, body: JSON.stringify({ orderHeader: { supplierId: supplier.id, supplierName: supplier.name || supplier.supplier_code || '' }, itemsList: cart }) });
      var json = await res.json();
      if (!res.ok || !json || !json.success) throw new Error((json && json.msg) || 'فشل حفظ أمر الشراء');
      hideLoader(); showToast('تم الحفظ: ' + (json.poID || ''), 'success'); cart = []; renderPOCart();
    } catch (e) { hideLoader(); showToast(e.message || 'فشل الاتصال', 'error'); }
  }

  return { renderOrders: renderOrders, renderPOS: renderPOS, _filterOrders: filterOrders, _openPO: openPO, _openReceive: openReceive, _searchItem: searchItem, _addToCart: addToCart, _updateQty: updateQty, _updatePrice: updatePrice, _removeItem: removeItem, _clearCart: clearCart, _savePO: savePO };
})();
window.RW_Purchases = RW_Purchases;

