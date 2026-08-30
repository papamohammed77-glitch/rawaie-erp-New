// ============================================================
// RW_OnlineStore – المتجر الإلكتروني
// ============================================================
var RW_OnlineStore = (function() {
  var cart = {};
  var activeCat = 'الكل';
  var deliveryFee = 0;
  var taxRate = 0;

  function esc(s) {
    return String(s || '').replace(/[&<>]/g, function(m) {
      return m === '&' ? '&amp;' : m === '<' ? '&lt;' : '&gt;';
    });
  }

  async function render() {
    var c = byId('rw-page-container');
    if (!c) return;
    safeText(byId('rw-header-title'), 'المتجر الإلكتروني');
    cart = {};
    try {
      var sRes = await supabase.from('app_settings').select('*').limit(1).single();
      if (!sRes.error && sRes.data) {
        deliveryFee = Number(sRes.data.delivery_fee) || 0;
        taxRate = Number(sRes.data.tax_rate) || 0;
      }
    } catch(e) {}
    if (!RW_STATE.data.items || !RW_STATE.data.items.length) {
      showLoader('جاري تحميل المنتجات...');
      await RW_Data.loadItems();
      hideLoader();
    }
    safeHTML(c, '<div class="p-4"><div class="flex flex-wrap justify-between items-center mb-4 gap-3"><div class="flex overflow-x-auto gap-2 pb-2" id="store-cats"></div><div class="flex gap-2"><button onclick="RW_OnlineStore._trackOrder()" class="bg-white border border-blue-200 text-blue-600 px-4 py-2 rounded-xl font-bold text-sm"><i class="fa-solid fa-magnifying-glass ml-1"></i> تتبع الطلب</button><button onclick="RW_OnlineStore._showCart()" class="bg-slate-100 px-4 py-2 rounded-xl font-bold relative">🛒 <span id="store-cart-badge">0</span></button></div></div><input type="text" id="store-search" class="w-full p-3 bg-white rounded-xl border mb-4" placeholder="ابحث عن منتج..." oninput="RW_OnlineStore._renderCards()"><div class="grid grid-cols-2 md:grid-cols-4 gap-4" id="store-grid"></div></div>');
    buildCats();
    renderCards();
  }

  function buildCats() {
    var bar = byId('store-cats');
    if (!bar) return;
    var cats = ['الكل'];
    var items = RW_STATE.data.items || [];
    for (var i = 0; i < items.length; i++) {
      if (items[i].category && cats.indexOf(items[i].category) === -1) cats.push(items[i].category);
    }
    var h = '';
    for (var j = 0; j < cats.length; j++) {
      h += '<button class="sub-tab-btn ' + (activeCat === cats[j] ? 'active-sub' : '') + '" onclick="RW_OnlineStore._setCat(\'' + esc(cats[j]) + '\')">' + cats[j] + '</button>';
    }
    safeHTML(bar, h);
  }

  function setCat(cat) {
    activeCat = cat;
    renderCards();
  }

  function renderCards() {
    var grid = byId('store-grid');
    if (!grid) return;
    var items = RW_STATE.data.items || [];
    var q = (byId('store-search') ? byId('store-search').value : '').toLowerCase();
    var filtered = items.filter(function(i) {
      var mc = activeCat === 'الكل' || i.category === activeCat;
      var ms = !q || (i.name || '').toLowerCase().indexOf(q) !== -1 || (i.item_code || '').toLowerCase().indexOf(q) !== -1;
      var show = i.show_in_store !== false && i.is_active !== false;
      return mc && ms && show;
    });
    if (!filtered.length) {
      safeHTML(grid, '<div class="col-span-full text-center py-10 text-gray-400">لا توجد منتجات</div>');
      return;
    }
    var h = '';
    for (var i = 0; i < filtered.length; i++) {
      var it = filtered[i];
      var qty = cart[it.item_code] || 0;
      var img = it.image_url || 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22%3E📦%3C/text%3E%3C/svg%3E';
      h += '<div class="bg-white rounded-xl p-3 border cursor-pointer shadow-sm hover:shadow-md" onclick="RW_OnlineStore._showProduct(\'' + it.item_code + '\')"><img src="' + img + '" class="w-full h-35 object-cover rounded-lg mb-2" onerror="this.src=\'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22%3E📦%3C/text%3E%3C/svg%3E\'"><div class="font-bold text-sm">' + (it.name || '') + '</div><div class="font-black text-blue-600 mb-2">' + Number(it.sales_price || 0).toLocaleString() + ' EGP</div>';
      if (qty === 0) h += '<button onclick="event.stopPropagation();RW_OnlineStore._addToCart(\'' + it.item_code + '\')" class="bg-blue-600 text-white w-full py-1 rounded-lg text-sm font-bold">إضافة للسلة</button>';
      else h += '<div class="flex items-center justify-between bg-slate-100 rounded-lg px-2 py-1"><button onclick="event.stopPropagation();RW_OnlineStore._updateCart(\'' + it.item_code + '\',-1)" class="text-lg font-bold text-gray-500">-</button><span class="font-black text-blue-600">' + qty + '</span><button onclick="event.stopPropagation();RW_OnlineStore._updateCart(\'' + it.item_code + '\',1)" class="text-lg font-bold text-gray-500">+</button></div>';
      h += '</div>';
    }
    safeHTML(grid, h);
    updateBadge();
  }

  function addToCart(code) {
    cart[code] = (cart[code] || 0) + 1;
    renderCards();
  }

  function updateCart(code, d) {
    var n = (cart[code] || 0) + d;
    if (n <= 0) delete cart[code];
    else cart[code] = n;
    renderCards();
  }

  function updateBadge() {
    var t = 0;
    for (var k in cart) t += cart[k];
    var b = byId('store-cart-badge');
    if (b) safeText(b, t);
  }

  function showProduct(code) {
    var items = RW_STATE.data.items || [];
    var it = null;
    for (var i = 0; i < items.length; i++) {
      if (items[i].item_code === code) { it = items[i]; break; }
    }
    if (!it) return;
    Swal.fire({
      imageUrl: it.image_url || 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22%3E📦%3C/text%3E%3C/svg%3E',
      imageWidth: 200,
      title: it.name,
      text: it.description || '',
      showCancelButton: true,
      confirmButtonText: (cart[code] || 0) > 0 ? 'الكمية: ' + (cart[code] || 0) : 'إضافة للسلة',
      cancelButtonText: 'إغلاق'
    }).then(function(r) {
      if (r.isConfirmed && (cart[code] || 0) === 0) addToCart(code);
    });
  }

  function showCart() {
    var items = RW_STATE.data.items || [];
    var arr = [];
    var subtotal = 0;
    for (var code in cart) {
      var it = null;
      for (var i = 0; i < items.length; i++) {
        if (items[i].item_code === code) { it = items[i]; break; }
      }
      if (!it) continue;
      var q = cart[code];
      var p = Number(it.sales_price) || 0;
      var ln = p * q;
      subtotal += ln;
      arr.push({ code: code, name: it.name, qty: q, price: p });
    }
    if (!arr.length) { showToast('السلة فارغة', 'info'); return; }
    var del = deliveryFee || 0;
    var beforeTax = subtotal + del;
    var taxAmt = Math.round(beforeTax * taxRate) / 100;
    var total = beforeTax + taxAmt;
    var itemsH = '';
    for (var j = 0; j < arr.length; j++) {
      var ci = arr[j];
      itemsH += '<div class="flex justify-between p-3 bg-slate-50 rounded-xl mb-2"><span>' + ci.name + '</span><span>' + ci.qty + ' × ' + ci.price.toLocaleString() + ' = ' + (ci.qty * ci.price).toLocaleString() + ' EGP</span></div>';
    }
    var h = '<div class="text-right">' + itemsH + '<div class="border-t pt-3 mt-3"><div class="flex justify-between mb-2"><span>المجموع:</span><span>' + subtotal.toLocaleString() + ' EGP</span></div>' + (del > 0 ? '<div class="flex justify-between mb-2"><span>رسوم التوصيل:</span><span>' + del.toLocaleString() + ' EGP</span></div>' : '') + (taxRate > 0 ? '<div class="flex justify-between mb-2"><span>الضريبة (' + taxRate + '%):</span><span>' + taxAmt.toLocaleString() + ' EGP</span></div>' : '') + '<div class="flex justify-between mb-4"><span class="font-black text-lg">الإجمالي:</span><span class="font-black text-lg text-emerald-600">' + total.toLocaleString() + ' EGP</span></div></div><input id="oc-name" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="الاسم الكامل"><input id="oc-phone" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="رقم الهاتف"><input id="oc-area" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="العنوان / المنطقة"></div>';
    Swal.fire({
      title: 'سلة التسوق',
      html: h,
      width: '600px',
      showCancelButton: true,
      confirmButtonText: 'إرسال الطلب',
      cancelButtonText: 'متابعة التسوق',
      preConfirm: function() {
        var nm = document.getElementById('oc-name').value.trim();
        var ph = document.getElementById('oc-phone').value.trim();
        var ar = document.getElementById('oc-area').value.trim();
        if (!nm || !ph || !ar) { Swal.showValidationMessage('الرجاء إكمال البيانات'); return false; }
        return { name: nm, phone: ph, area: ar };
      }
    }).then(function(r) {
      if (!r.isConfirmed) return;
      showLoader('جاري إرسال الطلب...');
      var user = { name: r.value.name, area: r.value.area, phone: r.value.phone, notes: '' };
      supabase.auth.getSession().then(function(ses) {
        var token = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
        if (!token) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }
        return fetch(SUPABASE_URL + '/functions/v1/submit-online-order', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
          body: JSON.stringify({ user: user, cartItems: arr, total: total, delivery: del })
        });
      }).then(function(res) {
        if (!res) return;
        if (!res.ok) return res.json().then(function(err) { throw new Error(err.msg || 'خطأ'); });
        return res.json();
      }).then(function(json) {
        hideLoader();
        if (json && json.success) { showToast('تم إرسال الطلب بنجاح', 'success'); cart = {}; renderCards(); }
        else { showToast((json && json.msg) || 'فشل', 'error'); }
      }).catch(function(err) { hideLoader(); showToast('فشل الاتصال', 'error'); });
    });
  }

  async function trackOrder() {
    var input = await Swal.fire({
      title: 'تتبع حالة الطلب',
      input: 'text',
      inputLabel: 'أدخل رقم الطلب',
      inputPlaceholder: 'مثلاً: ORD-...',
      showCancelButton: true,
      confirmButtonText: 'استعلام',
      cancelButtonText: 'إلغاء'
    });
    if (!input.value) return;
    showLoader('جاري جلب حالة الطلب...');
    try {
      var o = await supabase.from('orders').select('*').eq('order_code', input.value).maybeSingle();
      if (o.error || !o.data) { hideLoader(); Swal.fire({ title: 'الطلب غير موجود', text: 'لم يتم العثور على طلب بهذا الرقم', icon: 'error' }); return; }
      var it = await supabase.from('order_details').select('*').eq('order_code', input.value);
      hideLoader();
      var order = o.data;
      var statusLabel = '';
      var statusColor = '';
      switch(order.order_status) {
        case 'Pending': statusLabel = 'قيد الانتظار'; statusColor = 'text-yellow-600'; break;
        case 'Confirmed': statusLabel = 'مؤكد'; statusColor = 'text-blue-600'; break;
        case 'Invoiced': statusLabel = 'تمت الفوترة'; statusColor = 'text-green-600'; break;
        case 'Delivered': statusLabel = 'تم التوصيل'; statusColor = 'text-green-700'; break;
        case 'Cancelled': statusLabel = 'ملغي'; statusColor = 'text-red-600'; break;
        default: statusLabel = order.order_status; statusColor = 'text-gray-600';
      }
      var itemsH = '';
      var total = 0;
      if (it.data && it.data.length) {
        itemsH = '<table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">السعر</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
        it.data.forEach(function(i) {
          var lt = Number(i.line_amount) || (Number(i.qty) * Number(i.unit_price));
          total += lt;
          itemsH += '<tr><td class="p-2">' + (i.item_name || '') + '</td><td class="p-2 text-center">' + i.qty + '</td><td class="p-2 text-center">' + Number(i.unit_price).toLocaleString() + '</td><td class="p-2 text-center font-bold">' + lt.toLocaleString() + '</td></tr>';
        });
        itemsH += '</tbody></table>';
      }
      var detailH = '<div class="text-right"><p class="mb-3"><strong>حالة الطلب:</strong> <span class="font-bold ' + statusColor + '">' + statusLabel + '</span></p><p class="mb-2"><strong>العميل:</strong> ' + (order.customer_name || 'غير محدد') + '</p><p class="mb-2"><strong>المنطقة:</strong> ' + (order.area || '-') + '</p>' + itemsH + '<div class="mt-4 font-bold text-lg">الإجمالي: ' + Number(order.total_amount || 0).toLocaleString() + ' EGP</div></div>';
      Swal.fire({ title: 'تفاصيل الطلب: ' + input.value, html: detailH, width: '700px', showCloseButton: true, showConfirmButton: false });
    } catch(e) { hideLoader(); showToast('فشل جلب البيانات', 'error'); }
  }

  return {
    render: render,
    _setCat: setCat,
    _renderCards: renderCards,
    _addToCart: addToCart,
    _updateCart: updateCart,
    _showCart: showCart,
    _showProduct: showProduct,
    _trackOrder: trackOrder
  };
})();
window.RW_OnlineStore = RW_OnlineStore;
// ============================================================
// RW_Purchases – المشتريات (أمر شراء + استلام)
// ============================================================
var RW_Purchases = (function() {
  var poData=[], cart=[];
  function esc(s){ return String(s||'').replace(/[&<>]/g, function(m){ return m==='&'?'&amp;':m==='<'?'&lt;':'&gt;'; }); }
  async function renderOrders(){
    var c=byId('rw-page-container'); if(!c)return;
    safeText(byId('rw-header-title'),'أوردرات الشراء');
    safeHTML(c,'<div class="p-4"><div class="flex justify-between mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-truck-fast ml-2"></i> أوامر الشراء</h2><button onclick="RW_Navigation.navigate(\'purchase-pos\')" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-plus ml-1"></i> أمر شراء جديد</button></div><div class="bg-white rounded-2xl shadow-sm border overflow-y-auto" id="po-table-wrapper" style="max-height:65vh"><div class="text-center py-8">جاري التحميل...</div></div></div>');
    var res=await supabase.from('purchase_orders').select('*'); poData=res.data||[]; renderPOTable(poData);
  }
  function renderPOTable(data){
    var w=byId('po-table-wrapper'); if(!w)return;
    if(!data.length){ safeHTML(w,'<div class="text-center py-8">لا توجد أوامر شراء</div>'); return; }
    var h='<table class="w-full text-sm"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">رقم الأمر</th><th class="p-3">التاريخ</th><th class="p-3">المورد</th><th class="p-3 text-center">القيمة</th><th class="p-3 text-center">الحالة</th><th class="p-3 text-center">استلام</th></tr></thead><tbody>';
    data.forEach(function(o){ h+='<tr class="border-b hover:bg-gray-50"><td class="p-3 font-bold text-emerald-700">'+(o.po_code||'')+'</td><td class="p-3">'+(o.po_date||'')+'</td><td class="p-3">'+(o.supplier_name||'')+'</td><td class="p-3 text-center font-bold">'+Number(o.total_amount||0).toLocaleString()+' EGP</td><td class="p-3 text-center">'+(o.status||'')+'</td><td class="p-3 text-center"><button onclick="RW_Purchases._openReceive(\''+o.po_code+'\')" class="text-blue-600"><i class="fa-solid fa-truck-loading"></i></button></td></tr>'; });
    h+='</tbody></table>'; safeHTML(w,h);
  }
async function openReceive(poCode){
    showLoader('جاري جلب التفاصيل...');
    var poRes=await supabase.from('purchase_orders').select('*').eq('po_code',poCode).maybeSingle();
    var itemsRes=await supabase.from('purchase_order_details').select('*').eq('po_id',poRes.data?poRes.data.id:null);
    hideLoader();
    if(!poRes.data){ showToast('أمر الشراء غير موجود','error'); return; }
    var items=itemsRes.data||[];
    var itemsH='';
    if(items.length){
      itemsH='<table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">المستلم الآن</th></tr></thead><tbody>';
      items.forEach(function(it,idx){ itemsH+='<tr><td class="p-2 font-semibold">'+(it.item_name||'')+'</td><td class="p-2 text-center font-bold">'+(it.qty_ordered||0)+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+(it.qty_ordered||0)+'" class="w-20 p-1 border rounded text-center" min="0"></td></tr>'; });
      itemsH+='</tbody></table>';
    }
    var h='<div class="text-right">'+itemsH+'<div class="mt-4"><textarea id="rec-notes" class="w-full p-2 border rounded-lg" placeholder="ملاحظات الاستلام..." rows="2"></textarea></div></div>';
    Swal.fire({ title:'استلام بضاعة: '+poCode, html:h, width:'700px', showCancelButton:true, confirmButtonText:'اعتماد الاستلام', confirmButtonColor:'#10b981', cancelButtonText:'إلغاء',
      preConfirm:function(){
        var received=[];
        items.forEach(function(it,idx){ var q=parseFloat(document.getElementById('rec-qty-'+idx).value)||0; if(q>0) received.push({ itemCode:it.item_code, itemName:it.item_name, unit:it.unit, receivedQty:q, orderedQty:it.qty_ordered }); });
        return received;
      }
    }).then(function(r){
      if(!r.isConfirmed||!r.value.length)return;
      showLoader('جاري حفظ الاستلام...');
      var notes=document.getElementById('rec-notes')?document.getElementById('rec-notes').value:'';
      supabase.auth.getSession().then(function(ses) {
          var token = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
          if (!token) {
              hideLoader();
              showToast('انتهت الجلسة', 'error');
              return;
          }
          return fetch(SUPABASE_URL + '/functions/v1/receive-purchase', {
              method: 'POST',
              headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ' + token
              },
              body: JSON.stringify({
                  po_code: poCode,
                  itemsReceived: r.value,
                  notes: notes,
                  operation_id: crypto.randomUUID()
              })
          });
      }).then(function(res) {
          if (!res) return;
          if (!res.ok) {
              return res.json().then(function(err) {
                  throw new Error(err.msg || err.error || 'خطأ في الخادم');
              });
          }
          return res.json();
      }).then(function(json) {
          hideLoader();
          if (json.success) {
              showToast('تم الاستلام', 'success');
              supabase.from('purchase_orders').select('*').then(function(d) {
                  poData = d.data || [];
                  renderPOTable(poData);
              });
          } else {
              showToast(json.msg || json.error || 'فشل', 'error');
          }
      }).catch(function() {
          hideLoader();
          showToast('فشل الاتصال', 'error');
      });
    });
}
  async function renderPOS(){
    var c=byId('rw-page-container'); if(!c)return;
    safeText(byId('rw-header-title'),'نقطة شراء');
    if (!RW_STATE.data.items || !RW_STATE.data.items.length) { showLoader('جاري تحميل الأصناف...'); await RW_Data.loadItems(); hideLoader(); }
    if (!RW_STATE.data.suppliers || !RW_STATE.data.suppliers.length) { try { var sRes = await supabase.from('suppliers').select('*'); RW_STATE.data.suppliers = sRes.data || []; } catch(e) {} }
    safeHTML(c,'<div class="grid grid-cols-1 lg:grid-cols-4 gap-6 p-4"><div class="lg:col-span-1 space-y-4"><div class="bg-white p-4 rounded-xl shadow-sm"><label class="text-sm font-bold">اختيار المورد</label><select id="po-supplier" class="w-full p-2.5 bg-gray-50 border rounded-lg"></select></div><div class="bg-white p-4 rounded-xl shadow-sm"><label class="text-sm font-bold">البحث عن صنف</label><input type="text" id="po-search" oninput="RW_Purchases._searchItem(this.value)" placeholder="ابحث..." class="w-full p-2.5 bg-gray-50 border rounded-lg"><div id="po-dropdown" class="absolute z-50 bg-white shadow-xl rounded-xl max-h-60 overflow-y-auto hidden border"></div></div></div><div class="lg:col-span-3 bg-white rounded-xl shadow-md overflow-hidden flex flex-col min-h-[500px]"><div class="bg-emerald-700 text-white p-4 flex justify-between"><h2 class="font-bold text-lg">أمر شراء جديد</h2><span id="po-count">0</span></div><div class="flex-1 overflow-y-auto p-4"><table class="w-full text-right"><thead><tr class="text-xs text-gray-500"><th class="p-2">الصنف</th><th class="p-2 text-center">السعر</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">الإجمالي</th><th></th></tr></thead><tbody id="po-cart-body"><tr><td colspan="5" class="p-8 text-center">لا توجد أصناف</td></tr></tbody></table></div><div class="p-4 bg-gray-50 border-t flex justify-between"><div><span class="text-gray-500">الإجمالي:</span><span id="po-total" class="text-3xl font-bold">0</span></div><div class="flex gap-2"><button onclick="RW_Purchases._clearCart()" class="px-4 py-2 bg-red-500 text-white rounded-lg">مسح</button><button onclick="RW_Purchases._savePO()" class="px-6 py-2 bg-emerald-600 text-white rounded-lg">حفظ</button></div></div></div></div>');
    loadSuppliers(); renderPOCart();
  }
  function loadSuppliers(){ var sel=byId('po-supplier'); if(!sel)return; var suppliers=RW_STATE.data.suppliers||[]; var h='<option value="">-- اختر مورداً --</option>'; suppliers.forEach(function(s){ h+='<option value="'+(s.supplier_code||s.code||'')+'">'+(s.name||'')+'</option>'; }); safeHTML(sel,h); }
  function searchItem(q){ var dd=byId('po-dropdown'); if(!dd)return; if(!q||!q.trim()){ dd.classList.add('hidden'); return; } var items=RW_STATE.data.items||[],f=items.filter(function(i){ return (i.name||'').toLowerCase().indexOf(q.toLowerCase())!==-1; }); if(!f.length){ safeHTML(dd,'<div class="p-3 text-center">لا توجد نتائج</div>'); dd.classList.remove('hidden'); return; } var h=''; f.forEach(function(i){ h+='<div onclick="RW_Purchases._addToCart(\''+i.item_code+'\')" class="p-3 hover:bg-emerald-50 cursor-pointer flex justify-between border-b"><div><div class="font-bold">'+(i.name||'')+'</div></div><div class="text-emerald-600 font-bold">'+Number(i.sales_price||0).toLocaleString()+' EGP</div></div>'; }); safeHTML(dd,h); dd.classList.remove('hidden'); }
  function addToCart(code){ var items=RW_STATE.data.items||[],item=null; for(var i=0;i<items.length;i++){ if(items[i].item_code===code){ item=items[i]; break; } } if(!item)return; var ex=null; for(var j=0;j<cart.length;j++){ if(cart[j].code===code){ ex=cart[j]; break; } } if(ex)ex.qty++; else cart.push({code:item.item_code,name:item.name,price:Number(item.sales_price)||0,unit:item.unit||'حبة',qty:1}); byId('po-search').value=''; byId('po-dropdown').classList.add('hidden'); renderPOCart(); }
  function updateQty(idx,v){ var q=parseInt(v); if(q>0)cart[idx].qty=q; else cart.splice(idx,1); renderPOCart(); }
  function removeItem(idx){ cart.splice(idx,1); renderPOCart(); }
  function clearCart(){ cart=[]; renderPOCart(); }
  function renderPOCart(){
    var tb=byId('po-cart-body'),total=0;
    if(!cart.length){ safeHTML(tb,'<tr><td colspan="5" class="p-8 text-center">لا توجد أصناف</td></tr>'); safeText(byId('po-total'),'0'); safeText(byId('po-count'),'0'); return; }
    var h=''; cart.forEach(function(it,i){ var lt=it.price*it.qty; total+=lt; h+='<tr class="border-b"><td class="p-2 font-bold">'+it.name+'</td><td class="p-2 text-center">'+it.price.toLocaleString()+'</td><td class="p-2 text-center"><input type="number" value="'+it.qty+'" onchange="RW_Purchases._updateQty('+i+',this.value)" class="w-16 p-1 border rounded text-center" min="1"></td><td class="p-2 text-center font-bold">'+lt.toLocaleString()+'</td><td class="p-2 text-center"><button onclick="RW_Purchases._removeItem('+i+')" class="text-red-500"><i class="fa-solid fa-trash"></i></button></td></tr>'; });
    safeHTML(tb,h); safeText(byId('po-total'),total.toLocaleString()); safeText(byId('po-count'),String(cart.length));
  }
  async function savePO(){
    var supp=byId('po-supplier')?byId('po-supplier').value:''; if(!supp){ showToast('اختر مورداً','warning'); return; }
    if(!cart.length){ showToast('أضف أصنافاً','warning'); return; }
    var total=0; cart.forEach(function(i){ total+=i.price*i.qty; });
    var suppliers=RW_STATE.data.suppliers||[],sName=''; for(var i=0;i<suppliers.length;i++){ if(suppliers[i].supplier_code===supp||suppliers[i].code===supp){ sName=suppliers[i].name||''; break; } }
    showLoader('جاري الحفظ...');
    var ses=await supabase.auth.getSession(),t=ses.data.session&&ses.data.session.access_token;
    try{
      var res=await fetch(RW_SUPABASE_URL+'/functions/v1/save-purchase-order',{ method:'POST', headers:{'Content-Type':'application/json', Authorization:'Bearer '+t}, body:JSON.stringify({ orderHeader:{supplierId:supp, supplierName:sName, total:total}, itemsList:cart }) });
      var json=await res.json(); hideLoader();
      if(json.success){ showToast('تم الحفظ: '+json.poID,'success'); cart=[]; renderPOCart(); }
      else showToast(json.msg||'فشل','error');
    }catch(e){ hideLoader(); showToast('فشل الاتصال','error'); }
  }
  return { renderOrders:renderOrders, renderPOS:renderPOS, _searchItem:searchItem, _addToCart:addToCart, _updateQty:updateQty, _removeItem:removeItem, _clearCart:clearCart, _savePO:savePO, _openReceive:openReceive };
})();
window.RW_Purchases = RW_Purchases;

