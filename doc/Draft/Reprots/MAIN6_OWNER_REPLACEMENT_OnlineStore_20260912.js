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
