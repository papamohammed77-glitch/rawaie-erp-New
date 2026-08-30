// ============================================================
// RAWAEA ERP — MAIN6
// Online Store + Purchasing / Receiving
// ============================================================
(function(){
  // ============================================================
  // PRIVATE MAIN6 CONTEXT HELPERS
  // ============================================================
  var RW_Main6 = (function(){
    function companyId(){
      if(!window.RW_ShellContext || typeof window.RW_ShellContext.getCompanyId!=='function'){
        throw new Error('TENANT_CONTEXT_UNAVAILABLE');
      }
      return window.RW_ShellContext.getCompanyId();
    }
    function token(){
      return supabase.auth.getSession().then(function(r){
        var s=r&&r.data&&r.data.session;
        if(!s||!s.access_token) throw new Error('SESSION_UNAVAILABLE');
        return s.access_token;
      });
    }
    function text(v){ return v==null?'':String(v); }
    function esc(v){
      return text(v).replace(/[&<>"']/g,function(m){
        return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m];
      });
    }
    function escJs(v){ return text(v).replace(/\\/g,'\\\\').replace(/'/g,"\\'").replace(/\r?\n/g,' '); }
    function id(x){ return byId(x); }
    function money(v){ return Number(v||0).toLocaleString(); }
    return {companyId:companyId,token:token,esc:esc,escJs:escJs,id:id,money:money};
  })();

  // ============================================================
  // RW_OnlineStore — المتجر الإلكتروني
  // ============================================================
  var RW_OnlineStore = (function(){
    var cart={};
    var activeCat='الكل';
    var deliveryFee=0;
    var taxRate=0;

    function companyId(){ return RW_Main6.companyId(); }
    function esc(v){ return RW_Main6.esc(v); }
    function js(v){ return RW_Main6.escJs(v); }
    function findItem(code){
      var items=RW_STATE.data.items||[];
      for(var i=0;i<items.length;i++) if(items[i].item_code===code) return items[i];
      return null;
    }
    function fallbackImage(){
      return 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22%3E%F0%9F%93%A6%3C/text%3E%3C/svg%3E';
    }
    async function loadSettings(){
      deliveryFee=0; taxRate=0;
      try{
        var c=companyId();
        var r=await supabase.from('app_settings').select('delivery_fee,tax_rate').eq('company_id',c).order('created_at',{ascending:true}).maybeSingle();
        if(!r.error&&r.data){ deliveryFee=Number(r.data.delivery_fee)||0; taxRate=Number(r.data.tax_rate)||0; }
      }catch(e){}
    }
    async function render(){
      var c=RW_Main6.id('rw-page-container'); if(!c) return;
      safeText(RW_Main6.id('rw-header-title'),'المتجر الإلكتروني');
      cart={}; activeCat='الكل';
      await loadSettings();
      if(!RW_STATE.data.items||!RW_STATE.data.items.length){
        showLoader('جاري تحميل المنتجات...');
        try{ await RW_Data.loadItems(); }finally{ hideLoader(); }
      }
      safeHTML(c,'<div class="p-4"><div class="flex flex-wrap justify-between items-center mb-4 gap-3"><div class="flex overflow-x-auto gap-2 pb-2" id="store-cats"></div><div class="flex gap-2"><button onclick="RW_OnlineStore._trackOrder()" class="bg-white border border-blue-200 text-blue-600 px-4 py-2 rounded-xl font-bold text-sm"><i class="fa-solid fa-magnifying-glass ml-1"></i> تتبع الطلب</button><button onclick="RW_OnlineStore._showCart()" class="bg-slate-100 px-4 py-2 rounded-xl font-bold relative">🛒 <span id="store-cart-badge">0</span></button></div></div><input type="text" id="store-search" class="w-full p-3 bg-white rounded-xl border mb-4" placeholder="ابحث عن منتج..." oninput="RW_OnlineStore._renderCards()"><div class="grid grid-cols-2 md:grid-cols-4 gap-4" id="store-grid"></div></div>');
      buildCats(); renderCards();
    }
    function buildCats(){
      var bar=RW_Main6.id('store-cats'); if(!bar) return;
      var cats=['الكل'],items=RW_STATE.data.items||[];
      items.forEach(function(i){if(i.category&&cats.indexOf(i.category)===-1) cats.push(i.category);});
      var h=''; cats.forEach(function(c){
        h+='<button class="sub-tab-btn '+(activeCat===c?'active-sub':'')+'" onclick="RW_OnlineStore._setCat(\''+js(c)+'\')">'+esc(c)+'</button>';
      });
      safeHTML(bar,h);
    }
    function setCat(c){ activeCat=c; buildCats(); renderCards(); }
    function renderCards(){
      var grid=RW_Main6.id('store-grid'); if(!grid) return;
      var items=RW_STATE.data.items||[];
      var q=(RW_Main6.id('store-search')?RW_Main6.id('store-search').value:'').trim().toLowerCase();
      var f=items.filter(function(i){
        var cat=activeCat==='الكل'||i.category===activeCat;
        var search=!q||(String(i.name||'').toLowerCase().indexOf(q)!==-1)||(String(i.item_code||'').toLowerCase().indexOf(q)!==-1);
        return cat&&search&&i.show_in_store!==false&&i.is_active!==false;
      });
      if(!f.length){ safeHTML(grid,'<div class="col-span-full text-center py-10 text-gray-400">لا توجد منتجات</div>'); updateBadge(); return; }
      var h='';
      f.forEach(function(it){
        var code=js(it.item_code),qty=Number(cart[it.item_code]||0),img=it.image_url||fallbackImage();
        h+='<div class="bg-white rounded-xl p-3 border cursor-pointer shadow-sm hover:shadow-md" onclick="RW_OnlineStore._showProduct(\''+code+'\')">';
        h+='<img src="'+esc(img)+'" class="w-full h-35 object-cover rounded-lg mb-2" onerror="this.src=\''+fallbackImage().replace(/'/g,"\\'")+'\'">';
        h+='<div class="font-bold text-sm">'+esc(it.name)+'</div><div class="font-black text-blue-600 mb-2">'+money(it.sales_price)+' EGP</div>';
        if(qty===0){
          h+='<button onclick="event.stopPropagation();RW_OnlineStore._addToCart(\''+code+'\')" class="bg-blue-600 text-white w-full py-1 rounded-lg text-sm font-bold">إضافة للسلة</button>';
        }else{
          h+='<div class="flex items-center justify-between bg-slate-100 rounded-lg px-2 py-1"><button onclick="event.stopPropagation();RW_OnlineStore._updateCart(\''+code+'\',-1)" class="text-lg font-bold text-gray-500">-</button><span class="font-black text-blue-600">'+qty+'</span><button onclick="event.stopPropagation();RW_OnlineStore._updateCart(\''+code+'\',1)" class="text-lg font-bold text-gray-500">+</button></div>';
        }
        h+='</div>';
      });
      safeHTML(grid,h); updateBadge();
    }
    function addToCart(code){ if(!findItem(code)) return; cart[code]=Number(cart[code]||0)+1; renderCards(); }
    function updateCart(code,d){ if(!findItem(code)) return; var n=Number(cart[code]||0)+Number(d||0); if(n<=0) delete cart[code]; else cart[code]=n; renderCards(); }
    function updateBadge(){ var t=Object.keys(cart).reduce(function(n,k){return n+Number(cart[k]||0);},0); var b=RW_Main6.id('store-cart-badge'); if(b) safeText(b,t); }
    function showProduct(code){
      var it=findItem(code); if(!it) return;
      Swal.fire({imageUrl:it.image_url||fallbackImage(),imageWidth:200,title:it.name,text:it.description||'',showCancelButton:true,confirmButtonText:(cart[code]||0)>0?'الكمية: '+cart[code]:'إضافة للسلة',cancelButtonText:'إغلاق'}).then(function(r){ if(r.isConfirmed&&(cart[code]||0)===0) addToCart(code); });
    }
    function collectCart(){
      var arr=[],subtotal=0;
      Object.keys(cart).forEach(function(code){
        var it=findItem(code); if(!it) return;
        var qty=Number(cart[code]||0),price=Number(it.sales_price||0); subtotal+=price*qty;
        arr.push({code:code,name:it.name,qty:qty,price:price,unit:it.unit||'حبة'});
      });
      return {arr:arr,subtotal:subtotal};
    }
    function showCart(){
      var c=collectCart(); if(!c.arr.length){showToast('السلة فارغة','info');return;}
      var del=deliveryFee||0,beforeTax=c.subtotal+del,taxAmt=Math.round(beforeTax*taxRate)/100,total=beforeTax+taxAmt;
      var html=c.arr.map(function(i){return '<div class="flex justify-between p-3 bg-slate-50 rounded-xl mb-2"><span>'+esc(i.name)+'</span><span>'+i.qty+' × '+money(i.price)+' = '+money(i.qty*i.price)+' EGP</span></div>';}).join('');
      html+='<div class="border-t pt-3 mt-3"><div class="flex justify-between mb-2"><span>المجموع:</span><span>'+money(c.subtotal)+' EGP</span></div>';
      if(del>0) html+='<div class="flex justify-between mb-2"><span>رسوم التوصيل:</span><span>'+money(del)+' EGP</span></div>';
      if(taxRate>0) html+='<div class="flex justify-between mb-2"><span>الضريبة ('+esc(taxRate)+'%):</span><span>'+money(taxAmt)+' EGP</span></div>';
      html+='<div class="flex justify-between mb-4"><span class="font-black text-lg">الإجمالي:</span><span class="font-black text-lg text-emerald-600">'+money(total)+' EGP</span></div></div>';
      html+='<input id="oc-name" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="الاسم الكامل"><input id="oc-phone" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="رقم الهاتف"><input id="oc-area" class="w-full p-3 bg-slate-50 rounded-xl border mb-2" placeholder="العنوان / المنطقة">';
      Swal.fire({title:'سلة التسوق',html:html,width:'600px',showCancelButton:true,confirmButtonText:'إرسال الطلب',cancelButtonText:'متابعة التسوق',preConfirm:function(){
        var n=RW_Main6.id('oc-name').value.trim(),p=RW_Main6.id('oc-phone').value.trim(),a=RW_Main6.id('oc-area').value.trim();
        if(!n||!p||!a){Swal.showValidationMessage('الرجاء إكمال البيانات');return false;} return {name:n,phone:p,area:a};
      }}).then(function(r){
        if(!r.isConfirmed) return;
        showLoader('جاري إرسال الطلب...');
        RW_Main6.token().then(function(t){
          return fetch(RW_SUPABASE_URL+'/functions/v1/submit-online-order',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+t},body:JSON.stringify({user:{name:r.value.name,area:r.value.area,phone:r.value.phone,notes:''},cartItems:c.arr,total:total,delivery:del})});
        }).then(function(res){return res.json().then(function(j){if(!res.ok||!j.success) throw new Error(j.error||j.msg||'فشل إرسال الطلب');return j;});}).then(function(j){hideLoader();cart={};renderCards();showToast('تم إرسال الطلب بنجاح','success');if(j.orderCode) showToast('رقم الطلب: '+j.orderCode,'info');}).catch(function(e){hideLoader();showToast(e.message==='SESSION_UNAVAILABLE'?'انتهت الجلسة':(e.message||'فشل الاتصال'),'error');});
      });
    }
    async function trackOrder(){
      var input=await Swal.fire({title:'تتبع حالة الطلب',input:'text',inputLabel:'أدخل رقم الطلب',inputPlaceholder:'مثلاً: ORD-...',showCancelButton:true,confirmButtonText:'استعلام',cancelButtonText:'إلغاء'});
      var code=String(input.value||'').trim(); if(!code) return;
      showLoader('جاري جلب حالة الطلب...');
      try{
        var c=companyId();
        var o=await supabase.from('orders').select('id,order_code,customer_name,area,total_amount,order_status').eq('company_id',c).eq('order_code',code).maybeSingle();
        if(o.error||!o.data) throw new Error('الطلب غير موجود');
        var d=await supabase.from('order_details').select('item_name,qty,unit_price,line_amount').eq('order_id',o.data.id);
        if(d.error) throw d.error;
        var labels={Pending:['قيد الانتظار','text-yellow-600'],Confirmed:['مؤكد','text-blue-600'],Invoiced:['تمت الفوترة','text-green-600'],Delivered:['تم التوصيل','text-green-700'],Cancelled:['ملغي','text-red-600']};
        var s=labels[o.data.order_status]||[o.data.order_status,'text-gray-600'];
        var h='<table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2">الكمية</th><th class="p-2">السعر</th><th class="p-2">الإجمالي</th></tr></thead><tbody>';
        (d.data||[]).forEach(function(x){h+='<tr><td class="p-2">'+esc(x.item_name)+'</td><td class="p-2 text-center">'+Number(x.qty||0)+'</td><td class="p-2 text-center">'+money(x.unit_price)+'</td><td class="p-2 text-center">'+money(x.line_amount||Number(x.qty||0)*Number(x.unit_price||0))+'</td></tr>';});
        h+='</tbody></table><div class="text-right mt-4"><p class="mb-3"><strong>حالة الطلب:</strong> <span class="font-bold '+s[1]+'">'+esc(s[0])+'</span></p><p class="mb-2"><strong>العميل:</strong> '+esc(o.data.customer_name||'غير محدد')+'</p><p class="mb-2"><strong>المنطقة:</strong> '+esc(o.data.area||'-')+'</p><div class="font-bold text-lg">الإجمالي: '+money(o.data.total_amount)+' EGP</div></div>';
        hideLoader(); Swal.fire({title:'تفاصيل الطلب: '+esc(code),html:h,width:'750px',showCloseButton:true,showConfirmButton:false});
      }catch(e){hideLoader();Swal.fire({title:'تعذر الاستعلام',text:e.message||'فشل جلب البيانات',icon:'error'});}
    }
    return {render:render,_setCat:setCat,_renderCards:renderCards,_addToCart:addToCart,_updateCart:updateCart,_showCart:showCart,_showProduct:showProduct,_trackOrder:trackOrder};
  })();
  window.RW_OnlineStore=RW_OnlineStore;

  // ============================================================
  // RW_Purchases — المشتريات: أوامر شراء + استلام
  // ============================================================
  var RW_Purchases = (function(){
    var poData=[];
    var cart=[];
    function companyId(){return RW_Main6.companyId();}
    function esc(v){return RW_Main6.esc(v);}
    function js(v){return RW_Main6.escJs(v);}
    function text(v){return v==null?'':String(v);}
    function itemByCode(code){var items=RW_STATE.data.items||[];for(var i=0;i<items.length;i++)if(items[i].item_code===code)return items[i];return null;}
    function supplierById(v){var a=RW_STATE.data.suppliers||[];for(var i=0;i<a.length;i++)if(String(a[i].id)===String(v))return a[i];return null;}
    async function renderOrders(){
      var c=RW_Main6.id('rw-page-container');if(!c)return;
      safeText(RW_Main6.id('rw-header-title'),'أوردرات الشراء');
      safeHTML(c,'<div class="p-4"><div class="flex justify-between mb-4"><h2 class="text-xl font-bold"><i class="fa-solid fa-truck-fast ml-2"></i> أوامر الشراء</h2><button onclick="RW_Navigation.navigate(\'purchase-pos\')" class="bg-emerald-600 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-plus ml-1"></i> أمر شراء جديد</button></div><div class="bg-white rounded-2xl shadow-sm border overflow-y-auto" id="po-table-wrapper" style="max-height:65vh"><div class="text-center py-8">جاري التحميل...</div></div></div>');
      var r=await supabase.from('purchase_orders').select('id,po_code,po_date,supplier_name,total_amount,status').eq('company_id',companyId()).order('po_date',{ascending:false}).order('po_code',{ascending:false});
      poData=r.data||[];renderPOTable(poData);
    }
    function renderPOTable(data){
      var w=RW_Main6.id('po-table-wrapper');if(!w)return;
      if(!data.length){safeHTML(w,'<div class="text-center py-8">لا توجد أوامر شراء</div>');return;}
      var h='<table class="w-full text-sm"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">رقم الأمر</th><th class="p-3">التاريخ</th><th class="p-3">المورد</th><th class="p-3 text-center">القيمة</th><th class="p-3 text-center">الحالة</th><th class="p-3 text-center">استلام</th></tr></thead><tbody>';
      data.forEach(function(o){h+='<tr class="border-b hover:bg-gray-50"><td class="p-3 font-bold text-emerald-700">'+esc(o.po_code)+'</td><td class="p-3">'+esc(o.po_date)+'</td><td class="p-3">'+esc(o.supplier_name)+'</td><td class="p-3 text-center font-bold">'+RW_Main6.money(o.total_amount)+' EGP</td><td class="p-3 text-center">'+esc(o.status)+'</td><td class="p-3 text-center"><button onclick="RW_Purchases._openReceive(\''+js(o.po_code)+'\')" class="text-blue-600"><i class="fa-solid fa-truck-loading"></i></button></td></tr>';});
      h+='</tbody></table>';safeHTML(w,h);
    }
    async function openReceive(poCode){
      showLoader('جاري جلب التفاصيل...');
      try{
        var c=companyId();
        var p=await supabase.from('purchase_orders').select('id,po_code,status,supplier_name').eq('company_id',c).eq('po_code',poCode).maybeSingle();
        if(p.error||!p.data)throw new Error('أمر الشراء غير موجود');
        var d=await supabase.from('purchase_order_details').select('id,item_id,item_code,item_name,unit,qty_ordered,qty_received').eq('po_id',p.data.id);
        if(d.error)throw d.error;
        var items=d.data||[];hideLoader();
        if(!items.length){showToast('لا توجد تفاصيل للأمر','warning');return;}
        var h='<div class="text-right"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">تم استلامه</th><th class="p-2 text-center">المتبقي</th><th class="p-2 text-center">استلام الآن</th></tr></thead><tbody>';
        items.forEach(function(it,idx){var ordered=Number(it.qty_ordered)||0,received=Number(it.qty_received)||0,remain=Math.max(0,ordered-received);h+='<tr><td class="p-2 font-semibold">'+esc(it.item_name||it.item_code)+'</td><td class="p-2 text-center">'+ordered+'</td><td class="p-2 text-center">'+received+'</td><td class="p-2 text-center font-bold text-amber-600">'+remain+'</td><td class="p-2 text-center"><input type="number" id="rec-qty-'+idx+'" value="'+remain+'" max="'+remain+'" min="0" step="any" class="w-24 p-1 border rounded text-center" '+(remain<=0?'disabled':'')+'></td></tr>';});
        h+='</tbody></table><div class="mt-4"><textarea id="rec-notes" class="w-full p-2 border rounded-lg" placeholder="ملاحظات الاستلام..." rows="2"></textarea></div></div>';
        Swal.fire({title:'استلام بضاعة: '+esc(poCode),html:h,width:'780px',showCancelButton:true,confirmButtonText:'اعتماد الاستلام',confirmButtonColor:'#10b981',cancelButtonText:'إلغاء',preConfirm:function(){
          var received=[];
          items.forEach(function(it,idx){
            var max=Math.max(0,Number(it.qty_ordered||0)-Number(it.qty_received||0));
            var el=RW_Main6.id('rec-qty-'+idx),q=parseFloat(el?el.value:'0')||0;
            if(q<0||q>max){Swal.showValidationMessage('كمية الاستلام تتجاوز المتبقي للصنف: '+(it.item_code||it.item_name));return false;}
            if(q>0)received.push({itemCode:it.item_code,itemName:it.item_name,unit:it.unit,receivedQty:q});
          });
          if(!received.length){Swal.showValidationMessage('أدخل كمية استلام واحدة على الأقل');return false;}
          return received;
        }}).then(function(r){
          if(!r.isConfirmed||!r.value)return;
          var notes=RW_Main6.id('rec-notes')?RW_Main6.id('rec-notes').value:'';
          var opId=(window.crypto&&typeof window.crypto.randomUUID==='function')?window.crypto.randomUUID():(Date.now().toString(36)+'-'+Math.random().toString(36).slice(2));
          showLoader('جاري حفظ الاستلام...');
          RW_Main6.token().then(function(t){
            return fetch(RW_SUPABASE_URL+'/functions/v1/receive-purchase',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+t,'Idempotency-Key':opId},body:JSON.stringify({po_code:poCode,itemsReceived:r.value,notes:notes,operation_id:opId})});
          }).then(function(res){return res.json().then(function(j){if(!res.ok||!j.success)throw new Error(j.msg||j.error||'فشل الاستلام');return j;});}).then(function(){hideLoader();showToast('تم الاستلام بنجاح','success');return renderOrders();}).catch(function(e){hideLoader();showToast(e.message||'فشل الاتصال','error');});
        });
      }catch(e){hideLoader();showToast(e.message||'فشل جلب البيانات','error');}
    }
    async function renderPOS(){
      var c=RW_Main6.id('rw-page-container');if(!c)return;
      safeText(RW_Main6.id('rw-header-title'),'نقطة شراء');
      if(!RW_STATE.data.items||!RW_STATE.data.items.length){showLoader('جاري تحميل الأصناف...');try{await RW_Data.loadItems();}finally{hideLoader();}}
      try{var s=await supabase.from('suppliers').select('id,company_id,supplier_code,name,is_active').eq('company_id',companyId()).order('name');if(!s.error)RW_STATE.data.suppliers=s.data||[];}catch(e){}
      safeHTML(c,'<div class="grid grid-cols-1 lg:grid-cols-4 gap-6 p-4"><div class="lg:col-span-1 space-y-4"><div class="bg-white p-4 rounded-xl shadow-sm"><label class="text-sm font-bold">اختيار المورد</label><select id="po-supplier" class="w-full p-2.5 bg-gray-50 border rounded-lg"></select></div><div class="bg-white p-4 rounded-xl shadow-sm"><label class="text-sm font-bold">البحث عن صنف</label><input type="text" id="po-search" oninput="RW_Purchases._searchItem(this.value)" placeholder="ابحث..." class="w-full p-2.5 bg-gray-50 border rounded-lg"><div id="po-dropdown" class="absolute z-50 bg-white shadow-xl rounded-xl max-h-60 overflow-y-auto hidden border"></div></div></div><div class="lg:col-span-3 bg-white rounded-xl shadow-md overflow-hidden flex flex-col min-h-[500px]"><div class="bg-emerald-700 text-white p-4 flex justify-between"><h2 class="font-bold text-lg">أمر شراء جديد</h2><span id="po-count">0</span></div><div class="flex-1 overflow-y-auto p-4"><table class="w-full text-right"><thead><tr class="text-xs text-gray-500"><th class="p-2">الصنف</th><th class="p-2 text-center">السعر</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">الإجمالي</th><th></th></tr></thead><tbody id="po-cart-body"></tbody></table></div><div class="p-4 bg-gray-50 border-t flex justify-between"><div><span class="text-gray-500">الإجمالي:</span><span id="po-total" class="text-3xl font-bold">0</span></div><div class="flex gap-2"><button onclick="RW_Purchases._clearCart()" class="px-4 py-2 bg-red-500 text-white rounded-lg">مسح</button><button onclick="RW_Purchases._savePO()" class="px-6 py-2 bg-emerald-600 text-white rounded-lg">حفظ</button></div></div></div></div>');
      loadSuppliers();renderPOCart();
    }
    function loadSuppliers(){var sel=RW_Main6.id('po-supplier');if(!sel)return;var a=RW_STATE.data.suppliers||[],h='<option value="">-- اختر مورداً --</option>';a.forEach(function(s){if(s.is_active===false)return;h+='<option value="'+esc(s.id)+'">'+esc(s.name)+'</option>';});safeHTML(sel,h);}
    function searchItem(q){var dd=RW_Main6.id('po-dropdown');if(!dd)return;var term=text(q).trim().toLowerCase();if(!term){dd.classList.add('hidden');return;}var a=RW_STATE.data.items||[],f=a.filter(function(i){return i.is_active!==false&&((text(i.name).toLowerCase().indexOf(term)!==-1)||(text(i.item_code).toLowerCase().indexOf(term)!==-1));});if(!f.length){safeHTML(dd,'<div class="p-3 text-center">لا توجد نتائج</div>');dd.classList.remove('hidden');return;}var h='';f.slice(0,30).forEach(function(i){h+='<div onclick="RW_Purchases._addToCart(\''+js(i.item_code)+'\')" class="p-3 hover:bg-gray-100 cursor-pointer border-b"><div class="font-bold">'+esc(i.name)+'</div><div class="text-xs text-gray-500">'+esc(i.item_code)+' • '+RW_Main6.money(i.cost_price||0)+'</div></div>';});safeHTML(dd,h);dd.classList.remove('hidden');}
    function addToCart(code){var it=itemByCode(code);var dd=RW_Main6.id('po-dropdown');if(dd)dd.classList.add('hidden');if(!it)return;var x=cart.find(function(i){return i.code===code;});if(x)x.qty+=1;else cart.push({code:it.item_code,name:it.name,unit:it.unit||'حبة',price:Number(it.cost_price||0),qty:1});renderPOCart();}
    function updateQty(i,v){if(!cart[i])return;var q=parseFloat(v);if(!Number.isFinite(q)||q<=0){removeItem(i);return;}cart[i].qty=q;renderPOCart();}
    function removeItem(i){cart.splice(i,1);renderPOCart();}
    function clearCart(){cart=[];renderPOCart();}
    function renderPOCart(){var tb=RW_Main6.id('po-cart-body');if(!tb)return;var total=0;if(!cart.length){safeHTML(tb,'<tr><td colspan="5" class="p-8 text-center">لا توجد أصناف</td></tr>');safeText(RW_Main6.id('po-total'),'0');safeText(RW_Main6.id('po-count'),'0');return;}var h='';cart.forEach(function(it,i){var lt=it.price*it.qty;total+=lt;h+='<tr class="border-b"><td class="p-2 font-bold">'+esc(it.name)+'</td><td class="p-2 text-center">'+RW_Main6.money(it.price)+'</td><td class="p-2 text-center"><input type="number" value="'+it.qty+'" onchange="RW_Purchases._updateQty('+i+',this.value)" class="w-20 p-1 border rounded text-center" min="0.01" step="any"></td><td class="p-2 text-center font-bold">'+RW_Main6.money(lt)+'</td><td class="p-2 text-center"><button onclick="RW_Purchases._removeItem('+i+')" class="text-red-500"><i class="fa-solid fa-trash"></i></button></td></tr>';});safeHTML(tb,h);safeText(RW_Main6.id('po-total'),RW_Main6.money(total));safeText(RW_Main6.id('po-count'),String(cart.length));}
    async function savePO(){
      var supplierId=RW_Main6.id('po-supplier')?RW_Main6.id('po-supplier').value:'';if(!supplierId){showToast('اختر مورداً','warning');return;}if(!cart.length){showToast('أضف أصنافاً','warning');return;}
      var supplier=supplierById(supplierId);if(!supplier){showToast('المورد غير صالح لهذا السياق','error');return;}
      var items=cart.map(function(i){return {code:i.code,name:i.name,unit:i.unit,price:Number(i.price||0),qty:Number(i.qty||0)};});
      showLoader('جاري الحفظ...');
      try{
        var t=await RW_Main6.token();
        var res=await fetch(RW_SUPABASE_URL+'/functions/v1/save-purchase-order',{method:'POST',headers:{'Content-Type':'application/json','Authorization':'Bearer '+t},body:JSON.stringify({orderHeader:{supplierId:supplier.id,supplierName:supplier.name},itemsList:items})});
        var j=await res.json();if(!res.ok||!j.success)throw new Error(j.msg||j.error||'فشل حفظ أمر الشراء');
        cart=[];hideLoader();showToast('تم الحفظ: '+(j.poID||''),'success');
      }catch(e){hideLoader();showToast(e.message||'فشل الاتصال','error');}
    }
    return {renderOrders:renderOrders,renderPOS:renderPOS,_searchItem:searchItem,_addToCart:addToCart,_updateQty:updateQty,_removeItem:removeItem,_clearCart:clearCart,_savePO:savePO,_openReceive:openReceive};
  })();
  window.RW_Purchases=RW_Purchases;
})();
