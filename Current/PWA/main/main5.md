// ============================================================
// RAWAEA ERP — MAIN5 GOVERNED RECONSTRUCTION
// Scope: Orders + Runsheets
// Tenant authority: RW_ShellContext.getCompanyId()
// Workflow writers: canonical Edge Functions / RPCs only
// Physical stock authority: NOT present in this fragment
// ============================================================
(function () {
    'use strict';

    if (!window.RW_ShellContext || typeof window.RW_ShellContext.getCompanyId !== 'function') {
        throw new Error('MAIN5_REQUIRES_RW_SHELL_CONTEXT');
    }
    if (typeof window.supabase === 'undefined' && typeof supabase === 'undefined') {
        throw new Error('MAIN5_REQUIRES_SUPABASE_CLIENT');
    }

    var sb = window.supabase || supabase;
    var ordersRealtimeChannel = null;

    function getCompanyId() {
        var id = window.RW_ShellContext.getCompanyId();
        if (!id) throw new Error('TENANT_CONTEXT_UNAVAILABLE');
        return id;
    }

    function esc(value) {
        return String(value == null ? '' : value).replace(/[&<>"']/g, function (m) {
            return ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' })[m];
        });
    }

    function escAttr(value) { return esc(value); }

    function byLocalId(id) {
        return document.getElementById(id);
    }

    function notifyError(err, fallback) {
        var msg = String((err && err.message) || err || fallback || 'حدث خطأ غير متوقع');
        console.error(msg, err);
        if (typeof showToast === 'function') showToast(msg, 'error');
    }

    async function getToken() {
        var r = await sb.auth.getSession();
        var token = r && r.data && r.data.session ? r.data.session.access_token : null;
        if (!token) throw new Error('انتهت الجلسة. يرجى إعادة تسجيل الدخول.');
        return token;
    }

    async function edgeCall(name, body) {
        var token = await getToken();
        var response = await fetch(RW_SUPABASE_URL + '/functions/v1/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
            body: JSON.stringify(body || {})
        });
        var payload = await response.json().catch(function () { return {}; });
        if (!response.ok || payload.success === false) throw new Error(payload.msg || payload.error || ('فشل تنفيذ ' + name));
        return payload;
    }

    function safeAudit(action, tableName, recordId, oldData, newData) {
        try { if (typeof RW_Audit_log === 'function') RW_Audit_log(action, tableName, recordId, oldData || null, newData || null); }
        catch (e) { console.warn('Audit helper failed:', e); }
    }

    function safeWorkflow(tableName, action, code, payload) {
        try { if (window.RW_Workflow && typeof RW_Workflow.evaluate === 'function') RW_Workflow.evaluate(tableName, action, code, payload || {}); }
        catch (e) { console.warn('Workflow helper failed:', e); }
    }

    function safeNotification(type, payload) {
        try {
            if (window.RW_Notification && typeof RW_Notification.send === 'function') {
                var email = RW_STATE && RW_STATE.app && RW_STATE.app.currentUser ? RW_STATE.app.currentUser.email : '';
                RW_Notification.send(type, payload || {}, email);
            }
        } catch (e) { console.warn('Notification helper failed:', e); }
    }

    function formatDate(value) {
        if (!value) return '';
        try { return new Date(value).toLocaleDateString('ar-EG'); } catch (e) { return String(value); }
    }

    function formatNumber(value) { return Number(value || 0).toLocaleString('en-US'); }

    function statusClassOrder(status) {
        if (status === 'Draft') return 'bg-yellow-100 text-yellow-700';
        if (status === 'Confirmed') return 'bg-blue-100 text-blue-700';
        if (status === 'Pending') return 'bg-purple-100 text-purple-700';
        if (status === 'Invoiced' || status === 'Delivered') return 'bg-green-100 text-green-700';
        if (status === 'Returned' || status === 'Partially Returned') return 'bg-orange-100 text-orange-700';
        if (status === 'Cancelled') return 'bg-red-100 text-red-700';
        return 'bg-gray-100 text-gray-700';
    }

    // ============================================================
    // RW_Orders
    // ============================================================
    var RW_Orders = (function () {
        var sortField = 'order_code';
        var sortAsc = true;
        var ordersData = [];

        async function loadData() {
            var companyId = getCompanyId();
            var ordersRes = await sb.from('orders').select('*, runsheets(runsheet_code)').eq('company_id', companyId).order('order_date', { ascending: false }).order('order_code', { ascending: true });
            if (ordersRes.error) throw ordersRes.error;
            var rows = ordersRes.data || [];
            if (!rows.length) return [];
            var orderIds = rows.map(function (o) { return o.id; }).filter(Boolean);
            var detailsRes = await sb.from('order_details').select('order_id, item_code').in('order_id', orderIds);
            if (detailsRes.error) throw detailsRes.error;
            var counts = {};
            (detailsRes.data || []).forEach(function (d) { if (d.order_id) counts[d.order_id] = (counts[d.order_id] || 0) + 1; });
            return rows.map(function (o) {
                o.itemsCount = counts[o.id] || 0;
                o._runsheetCode = o.runsheets && o.runsheets.runsheet_code ? o.runsheets.runsheet_code : null;
                return o;
            });
        }

        async function refreshRealtimeChannel() {
            if (ordersRealtimeChannel) { try { await sb.removeChannel(ordersRealtimeChannel); } catch (e) { console.warn(e); } ordersRealtimeChannel = null; }
            var companyId = getCompanyId();
            ordersRealtimeChannel = sb.channel('orders-realtime-' + companyId).on('postgres_changes', {
                event: '*', schema: 'public', table: 'orders', filter: 'company_id=eq.' + companyId
            }, function (payload) {
                var incoming = payload && payload.new ? payload.new : null;
                if (!incoming || !incoming.id) { _refreshData().catch(function (e) { console.warn(e); }); return; }
                var found = false;
                for (var i = 0; i < ordersData.length; i++) {
                    if (ordersData[i].id === incoming.id) {
                        if (payload.eventType === 'DELETE') ordersData.splice(i, 1);
                        else Object.keys(incoming).forEach(function (k) { ordersData[i][k] = incoming[k]; });
                        found = true; break;
                    }
                }
                if (!found && payload.eventType !== 'DELETE') _refreshData().catch(function (e) { console.warn(e); });
                else _applyFilters();
            }).subscribe();
        }

        async function render() {
            var container = byLocalId('rw-page-container'); if (!container) return;
            safeText(byLocalId('rw-header-title'), 'أوردرات المبيعات');
            safeText(byLocalId('rw-header-subtitle'), 'عرض وإدارة جميع أوردرات المبيعات');
            safeHTML(container, '<div class="p-4">' +
                '<div class="bg-white rounded-2xl shadow-sm border p-4 mb-4">' +
                    '<div class="flex flex-wrap justify-between items-center gap-2 mb-3"><h3 class="font-bold text-lg">فلترة الأوردرات</h3><div class="flex gap-2">' +
                    '<button onclick="RW_Orders._applyFilters()" class="bg-blue-50 text-blue-600 px-3 py-1 rounded text-sm font-bold">تحديث</button>' +
                    '<button onclick="RW_Orders._showWithoutRS()" class="bg-amber-50 text-amber-600 px-3 py-1 rounded text-sm font-bold">بدون رانشيت</button>' +
                    '<button onclick="RW_Orders._resetFilters()" class="bg-gray-50 text-gray-600 px-3 py-1 rounded text-sm font-bold">إعادة تعيين</button>' +
                    '</div></div>' +
                    '<div class="grid grid-cols-2 md:grid-cols-6 gap-2">' +
                    '<input type="date" id="f-date-from" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<input type="date" id="f-date-to" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<input type="text" id="f-cust" oninput="RW_Orders._applyFilters()" placeholder="العميل" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<select id="f-status" onchange="RW_Orders._applyFilters()" class="p-2 bg-gray-50 rounded text-sm"><option value="">الحالة</option><option>Draft</option><option>Confirmed</option><option>Pending</option><option>Invoiced</option><option>Delivered</option><option>Returned</option><option>Partially Returned</option><option>Cancelled</option></select>' +
                    '<input type="text" id="f-area" oninput="RW_Orders._applyFilters()" placeholder="المنطقة" class="p-2 bg-gray-50 rounded text-sm">' +
                    '<input type="text" id="f-rs" oninput="RW_Orders._applyFilters()" placeholder="الرانشيت" class="p-2 bg-gray-50 rounded text-sm">' +
                    '</div></div>' +
                '<div class="flex flex-wrap gap-3 mb-4"><button onclick="RW_Orders._createRS()" class="bg-blue-600 text-white px-4 py-2 rounded-lg font-bold shadow"><i class="fa-solid fa-truck-fast ml-2"></i> رانشيت جديد</button><button onclick="RW_Orders._appendRS()" class="bg-emerald-600 text-white px-4 py-2 rounded-lg font-bold shadow"><i class="fa-solid fa-folder-plus ml-2"></i> ضم لرانشيت مفتوح</button></div>' +
                '<div class="bg-white rounded-2xl shadow-sm border overflow-auto orders-table-container" style="max-height:65vh"><table class="w-full min-w-[1200px]" id="orders-main-table"><thead class="bg-gray-50 sticky top-0 z-10" id="orders-thead"><tr>' +
                '<th class="p-3 text-center"><input type="checkbox" id="check-all" onchange="var cbs=document.querySelectorAll(\'.order-checkbox\');for(var i=0;i<cbs.length;i++)cbs[i].checked=this.checked;"></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'order_code\')">رقم الأوردر <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'order_date\')">التاريخ <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'customer_name\')">العميل والمنطقة <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'itemsCount\')">عدد الأصناف <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'total_amount\')">القيمة (EGP) <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'order_status\')">الحالة <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Orders._sort(\'_runsheetCode\')">الرانشيت <i class="fa-solid fa-sort"></i></th>' +
                '<th class="p-3 text-center text-xs font-bold uppercase">إجراءات</th></tr></thead><tbody id="orders-table-body"><tr><td colspan="9" class="text-center py-8 text-gray-500">جاري التحميل...</td></tr></tbody></table><div id="orders-table-body-controls"></div></div></div>');
            showLoader('جاري تحميل الأوردرات...');
            try { ordersData = await loadData(); await refreshRealtimeChannel(); _applyFilters(); }
            catch (e) { safeHTML(byLocalId('orders-table-body'), '<tr><td colspan="9" class="text-center py-8 text-red-500">تعذر تحميل الأوردرات: ' + esc(e.message || e) + '</td></tr>'); notifyError(e); }
            finally { hideLoader(); }
            clearInterval(window._ordersRefreshInterval);
            window._ordersRefreshInterval = setInterval(function () { if (window.RW_STATE && RW_STATE.app && RW_STATE.app.currentView === 'orders') _refreshData().catch(function (e) { console.warn(e); }); }, 30000);
        }

        function _applyFilters() {
            var filtered = ordersData.slice(), fd = byLocalId('f-date-from'), td = byLocalId('f-date-to'), cust = byLocalId('f-cust'), st = byLocalId('f-status'), area = byLocalId('f-area'), rs = byLocalId('f-rs');
            var from = fd ? fd.value : '', to = td ? td.value : '', customer = cust ? String(cust.value || '').toLowerCase().trim() : '', status = st ? st.value : '', ar = area ? String(area.value || '').toLowerCase().trim() : '', run = rs ? String(rs.value || '').toLowerCase().trim() : '';
            if (from) filtered = filtered.filter(function (o) { return String(o.order_date || '') >= from; });
            if (to) filtered = filtered.filter(function (o) { return String(o.order_date || '') <= to; });
            if (customer) filtered = filtered.filter(function (o) { return String(o.customer_name || '').toLowerCase().indexOf(customer) !== -1; });
            if (status) filtered = filtered.filter(function (o) { return o.order_status === status; });
            if (ar) filtered = filtered.filter(function (o) { return String(o.area || '').toLowerCase().indexOf(ar) !== -1; });
            if (run) filtered = filtered.filter(function (o) { return String(o._runsheetCode || '').toLowerCase().indexOf(run) !== -1; });
            filtered.sort(function (a,b) { var av=a[sortField],bv=b[sortField]; if (sortField==='total_amount'||sortField==='itemsCount'){av=Number(av)||0;bv=Number(bv)||0;}else if(sortField==='order_date'){av=new Date(av||0).getTime();bv=new Date(bv||0).getTime();}else{av=String(av==null?'':av).toLowerCase();bv=String(bv==null?'':bv).toLowerCase();}return (av< bv?-1:av>bv?1:0)*(sortAsc?1:-1); });
            _renderTable(filtered);
        }

        function _resetFilters() { ['f-date-from','f-date-to','f-cust','f-status','f-area','f-rs'].forEach(function (id) { var el=byLocalId(id); if(el)el.value=''; }); _applyFilters(); }
        function _showWithoutRS() { _renderTable(ordersData.filter(function (o) { return !o.runsheet_id; })); }
        function _sort(field) { if(sortField===field)sortAsc=!sortAsc;else{sortField=field;sortAsc=true;} _applyFilters(); }

        function _renderTable(rows) {
            var tbody=byLocalId('orders-table-body'); if(!tbody)return;
            if(!rows||!rows.length){safeHTML(tbody,'<tr><td colspan="9" class="text-center py-8 text-gray-500">لا توجد أوردرات</td></tr>');var pc=byLocalId('orders-table-body-controls');if(pc)safeHTML(pc,'');return;}
            var checkAll=byLocalId('check-all');if(checkAll)checkAll.checked=false;
            RW_Table.paginate('orders-table-body', rows, 1, 50, function(o){
                var actions='';
                if(o.order_status==='Draft'||o.order_status==='Pending') actions+='<button onclick="event.stopPropagation();RW_Orders._confirm(\''+escAttr(o.order_code)+'\')" class="text-green-600 mx-1" title="تأكيد"><i class="fa-solid fa-check-circle"></i></button>';
                var canDelete=(o.order_status==='Draft'||o.order_status==='Confirmed'||o.order_status==='Pending')&&!o.runsheet_id;
                if(canDelete)actions+='<button onclick="event.stopPropagation();RW_Orders._delete(\''+escAttr(o.order_code)+'\')" class="text-red-500 mx-1" title="حذف"><i class="fa-solid fa-trash-can"></i></button>';
                return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Orders._showDetails(\''+escAttr(o.order_code)+'\')"><td class="p-3 text-center" onclick="event.stopPropagation()"><input type="checkbox" class="order-checkbox" data-id="'+escAttr(o.order_code)+'"></td><td class="p-3 text-center font-bold text-blue-600">'+esc(o.order_code)+'</td><td class="p-3 text-center">'+esc(formatDate(o.order_date))+'</td><td class="p-3 text-center"><p class="font-semibold">'+esc(o.customer_name)+'</p><p class="text-xs text-gray-500">'+esc(o.area)+'</p></td><td class="p-3 text-center font-bold">'+formatNumber(o.itemsCount)+'</td><td class="p-3 text-center font-bold">'+formatNumber(o.total_amount)+' EGP</td><td class="p-3 text-center"><span class="px-2 py-1 rounded-full text-xs font-semibold '+statusClassOrder(o.order_status)+'">'+esc(o.order_status)+'</span></td><td class="p-3 text-center">'+esc(o._runsheetCode||'---')+'</td><td class="p-3 text-center">'+actions+'</td></tr>';
            });
        }

        function _getSelectedOrders(){var selected=[],seen={};document.querySelectorAll('.order-checkbox:checked').forEach(function(cb){var code=String(cb.dataset.id||'').trim();if(code&&!seen[code]){seen[code]=true;selected.push(code);}});return selected;}

        function _validateSelected(selected){var companyId=getCompanyId();if(!selected||!selected.length)throw new Error('اختر أوردرًا واحدًا على الأقل');var rows=[];selected.forEach(function(code){var found=ordersData.find(function(o){return o.order_code===code&&o.company_id===companyId;});if(!found)throw new Error('أحد الأوردرات المحددة غير موجود في سياق الشركة الحالي');if(found.runsheet_id)throw new Error('الأوردر '+code+' مرتبط بالفعل برانشيت');if(['Confirmed','Pending'].indexOf(found.order_status)===-1)throw new Error('الأوردر '+code+' لا يمكن إدخاله في رانشيت في حالته الحالية: '+found.order_status);rows.push(found);});return rows;}

        async function _confirm(code){var found=ordersData.find(function(o){return o.order_code===code;});var cf=await Swal.fire({title:'تأكيد الأوردر',text:'تحويل '+code+' إلى مؤكد؟',icon:'question',showCancelButton:true,confirmButtonText:'تأكيد',cancelButtonText:'إلغاء'});if(!cf.isConfirmed)return;showLoader('جاري التأكيد...');try{var companyId=getCompanyId();if(!found||found.company_id!==companyId)throw new Error('الأوردر غير موجود في سياق الشركة الحالي');await edgeCall('confirm-order',{order_code:code});var oldStatus=found.order_status;found.order_status='Confirmed';safeAudit('update','orders',code,{order_status:oldStatus},{order_status:'Confirmed'});safeWorkflow('orders','update',code,{order_status:'Confirmed',order_code:code});safeNotification('order_confirmed',{order_code:code,customer_name:found.customer_name||'',table:'orders',id:code});showToast('تم التأكيد','success');_applyFilters();}catch(e){notifyError(e,'فشل تأكيد الأوردر');}finally{hideLoader();}}

        async function _delete(code){var found=ordersData.find(function(o){return o.order_code===code;});var cf=await Swal.fire({title:'تأكيد الحذف',text:'حذف الأوردر '+code+' نهائيًا؟ لا يمكن التراجع.',icon:'warning',showCancelButton:true,confirmButtonColor:'#d33',confirmButtonText:'نعم، احذف',cancelButtonText:'تراجع'});if(!cf.isConfirmed)return;showLoader('جاري الحذف...');try{var companyId=getCompanyId();if(!found||found.company_id!==companyId)throw new Error('الأوردر غير موجود في سياق الشركة الحالي');if(found.runsheet_id)throw new Error('لا يمكن حذف أوردر مرتبط برانشيت');if(['Draft','Confirmed','Pending'].indexOf(found.order_status)===-1)throw new Error('الحذف غير مسموح للأوردر في حالته الحالية');await edgeCall('delete-order',{order_code:code});safeAudit('delete','orders',code,found,null);ordersData=ordersData.filter(function(o){return o.id!==found.id;});showToast('تم الحذف','success');_applyFilters();}catch(e){notifyError(e,'فشل حذف الأوردر');}finally{hideLoader();}}
        async function _confirmOrderFromDetails(code){await _confirm(code);if(byLocalId('rw-page-container'))await _showDetails(code);}

        async function _showDetails(code){showLoader('جاري تحميل التفاصيل...');try{var companyId=getCompanyId();var oRes=await sb.from('orders').select('*').eq('company_id',companyId).eq('order_code',code).maybeSingle();if(oRes.error)throw oRes.error;var order=oRes.data;if(!order)throw new Error('الأوردر غير موجود');var iRes=await sb.from('order_details').select('*').eq('order_id',order.id);if(iRes.error)throw iRes.error;var items=iRes.data||[];var itemsTotal=0,itemsHtml='';items.forEach(function(it){var lt=Number(it.line_amount);if(!Number.isFinite(lt))lt=(Number(it.qty)||0)*(Number(it.unit_price)||0);itemsTotal+=lt;itemsHtml+='<tr><td class="p-2 font-semibold">'+esc(it.item_name)+'</td><td class="p-2 text-center">'+esc(it.unit||'حبة')+'</td><td class="p-2 text-center">'+esc(it.qty)+'</td><td class="p-2 text-center">'+formatNumber(it.unit_price)+'</td><td class="p-2 text-center font-bold">'+formatNumber(lt)+'</td></tr>';});if(!itemsHtml)itemsHtml='<tr><td colspan="5" class="text-center py-4 text-gray-500">لا توجد أصناف مسجلة لهذا الأوردر</td></tr>';var deliveryFee=Number(order.delivery_fee)||0,grandTotal=itemsTotal+deliveryFee;var warning=order.runsheet_id?'<div class="bg-amber-50 border-r-4 border-amber-500 p-3 mb-4 rounded"><p class="text-amber-700 text-sm"><i class="fa-solid fa-link ml-2"></i> مرتبط بالرانشيت: <strong>'+esc(order.runsheet_id)+'</strong></p></div>':'';var buttons='';if((order.order_status==='Draft'||order.order_status==='Pending')&&!order.runsheet_id)buttons+='<button id="btn-confirm-order-modal" class="bg-blue-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-check-circle ml-2"></i> تأكيد الأوردر</button>';if(['Draft','Confirmed','Pending'].indexOf(order.order_status)!==-1&&!order.runsheet_id)buttons+='<button id="btn-delete-order-modal" class="bg-red-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-trash ml-2"></i> حذف الأوردر</button>';buttons+='<button id="btn-print-order-modal" class="bg-emerald-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-print ml-2"></i> طباعة الفاتورة</button>';var html='<div class="text-right">'+warning+'<div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-2xl mb-4"><div><p><b>العميل:</b> '+esc(order.customer_name)+'</p><p><b>المنطقة:</b> '+esc(order.area)+'</p></div><div><p><b>الحالة:</b> <span class="font-bold">'+esc(order.order_status)+'</span></p><p><b>الرانشيت:</b> '+esc(order.runsheet_id||'---')+'</p></div></div><div class="overflow-x-auto"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">السعر</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>'+itemsHtml+'</tbody></table></div><div class="bg-gray-50 p-4 rounded-2xl mt-4"><div class="flex justify-between mb-2"><span>مجموع الأصناف:</span><span>'+formatNumber(itemsTotal)+' EGP</span></div><div class="flex justify-between mb-2"><span class="text-blue-600">رسوم التوصيل:</span><span class="text-blue-600">'+formatNumber(deliveryFee)+' EGP</span></div><div class="flex justify-between pt-2 border-t"><span class="font-bold">الإجمالي:</span><span class="font-bold text-emerald-600 text-lg">'+formatNumber(grandTotal)+' EGP</span></div></div><div class="flex justify-center gap-3 mt-6 pt-4 border-t">'+buttons+'</div></div>';Swal.fire({title:'تفاصيل الأوردر: '+esc(code),html:html,width:'900px',showCloseButton:true,showConfirmButton:false,showCancelButton:true,cancelButtonText:'إغلاق',didOpen:function(){var c=byLocalId('btn-confirm-order-modal');if(c)c.onclick=function(){Swal.close();_confirmOrderFromDetails(code);};var d=byLocalId('btn-delete-order-modal');if(d)d.onclick=function(){Swal.close();_delete(code);};var p=byLocalId('btn-print-order-modal');if(p)p.onclick=function(){_printOrder(code);};}});}catch(e){notifyError(e,'فشل تحميل التفاصيل');}finally{hideLoader();}}

        async function _printOrder(code){showLoader('جاري تحضير الطباعة...');var order=null,items=[],settings={};try{var companyId=getCompanyId();var oRes=await sb.from('orders').select('*').eq('company_id',companyId).eq('order_code',code).maybeSingle();if(oRes.error)throw oRes.error;order=oRes.data;if(!order)throw new Error('الأوردر غير موجود');var dRes=await sb.from('order_details').select('*').eq('order_id',order.id);if(dRes.error)throw dRes.error;items=dRes.data||[];var sRes=await sb.from('app_settings').select('*').eq('company_id',companyId).order('created_at',{ascending:true}).limit(1).maybeSingle();if(sRes.error)throw sRes.error;settings=sRes.data||{};_buildPrintWindow(order,items,settings);}catch(e){console.error('Print error:',e);if(order)_buildPrintWindow(order,items,{});else notifyError(e,'الأوردر غير موجود');}finally{hideLoader();}}

        function _buildPrintWindow(order,items,settings){var companyName=settings.company_name||'الروائع',taxRate=Number(settings.tax_rate)||0,vatNumber=settings.vat_number||'',registeredName=settings.registered_name||companyName,businessAddress=settings.business_address||'',itemsHtml='',itemsTotal=0;items.forEach(function(it){var lt=Number(it.line_amount);if(!Number.isFinite(lt))lt=(Number(it.qty)||0)*(Number(it.unit_price)||0);itemsTotal+=lt;itemsHtml+='<tr><td class="border p-2">'+esc(it.item_name)+'</td><td class="border p-2 text-center">'+esc(it.unit||'حبة')+'</td><td class="border p-2 text-center">'+esc(it.qty)+'</td><td class="border p-2 text-center">'+formatNumber(it.unit_price)+'</td><td class="border p-2 text-center">'+formatNumber(lt)+'</td></tr>';});var deliveryFee=Number(order.delivery_fee)||0,grandTotal=itemsTotal+deliveryFee,taxAmount=Math.round((grandTotal*taxRate/100)*100)/100,invoiceDate=order.order_date?new Date(order.order_date).toISOString():new Date().toISOString(),qrBase64=typeof generateQRInvoiceBase64==='function'?generateQRInvoiceBase64(registeredName,vatNumber,invoiceDate,String(grandTotal),String(taxAmount)):'';var printWindow=window.open('', '_blank');if(!printWindow){showToast('الرجاء السماح بالنوافذ المنبثقة','warning');return;}var html='<!DOCTYPE html><html dir="rtl"><head><meta charset="UTF-8"><title>فاتورة '+esc(order.order_code)+'</title><script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"><\\/script><style>body{font-family:Cairo,Arial,sans-serif;padding:20px;color:#111827}table{width:100%;border-collapse:collapse}th,td{border:1px solid #ddd;padding:8px;text-align:right}th{background:#f2f2f2}@media print{body{padding:0}}</style></head><body><div style="text-align:center;border-bottom:2px solid #000;padding-bottom:10px"><h1>فاتورة بيع</h1><p>رقم: '+esc(order.order_code)+'</p><p>التاريخ: '+esc(formatDate(order.order_date))+'</p></div><p><strong>البائع:</strong> '+esc(registeredName)+(vatNumber?' | <strong>رقم ضريبي:</strong> '+esc(vatNumber):'')+'</p>'+(businessAddress?'<p><strong>العنوان:</strong> '+esc(businessAddress)+'</p>':'')+'<p><strong>العميل:</strong> '+esc(order.customer_name)+'</p><p><strong>المنطقة:</strong> '+esc(order.area)+'</p><table><thead><tr><th>الصنف</th><th>الوحدة</th><th>الكمية</th><th>السعر</th><th>الإجمالي</th></tr></thead><tbody>'+itemsHtml+'</tbody></table><div style="font-weight:bold;font-size:18px;margin-top:20px">الإجمالي: '+formatNumber(order.total_amount||grandTotal)+' EGP</div><div style="text-align:center;margin-top:20px;padding-top:15px;border-top:1px dashed #ccc"><p style="font-weight:bold">رمز الفاتورة الإلكترونية</p><div id="print-qrcode-container" style="display:inline-block"></div></div><script>window.onload=function(){try{var c=document.getElementById("print-qrcode-container");if(c&&window.QRCode&&'+JSON.stringify(qrBase64||'')+'){new QRCode(c,{text:'+JSON.stringify(qrBase64||'')+',width:150,height:150});}}catch(e){}window.print();};<\\/script></body></html>';printWindow.document.write(html);printWindow.document.close();}

        async function _createRS(){try{var selected=_getSelectedOrders();_validateSelected(selected);var cf=await Swal.fire({title:'إنشاء رانشيت جديد',text:'سيتم تجميع '+selected.length+' أوردر في رانشيت جديد. متابعة؟',icon:'question',showCancelButton:true,confirmButtonText:'نعم، إنشاء',cancelButtonText:'إلغاء'});if(!cf.isConfirmed)return;showLoader('جاري إنشاء الرانشيت...');var json=await edgeCall('create-runsheet',{selectedOrders:selected});if(!json||!json.success)throw new Error((json&&json.msg)||'فشل إنشاء الرانشيت');showToast('تم إنشاء الرانشيت: '+(json.rsId||''),'success');await _refreshData();}catch(e){notifyError(e,'فشل إنشاء الرانشيت');}finally{hideLoader();}}

        async function _appendRS(){try{var selected=_getSelectedOrders();_validateSelected(selected);var companyId=getCompanyId();var rsRes=await sb.from('runsheets').select('runsheet_code,status').eq('company_id',companyId).in('status',['Open','Confirmed']).order('run_date',{ascending:false}).order('runsheet_code');if(rsRes.error)throw rsRes.error;if(!rsRes.data||!rsRes.data.length){showToast('لا توجد رانشيتات مفتوحة','info');return;}var opts={};rsRes.data.forEach(function(rs){opts[rs.runsheet_code]=rs.runsheet_code+' - '+rs.status;});var v=await Swal.fire({title:'اختر الرانشيت',input:'select',inputOptions:opts,showCancelButton:true,confirmButtonText:'ضم',cancelButtonText:'إلغاء'});if(!v.value)return;showLoader('جاري الضم...');await edgeCall('append-to-runsheet',{targetRSID:v.value,selectedOrders:selected});showToast('تم الضم','success');await _refreshData();}catch(e){notifyError(e,'فشل ضم الأوردرات');}finally{hideLoader();}}

        async function _refreshData(){ordersData=await loadData();_applyFilters();return ordersData;}
        async function _loadRunsheetCodes(){var companyId=getCompanyId();var r=await sb.from('runsheets').select('id,runsheet_code').eq('company_id',companyId);if(r.error)throw r.error;var map={};(r.data||[]).forEach(function(x){map[x.id]=x.runsheet_code;});ordersData.forEach(function(o){o._runsheetCode=o.runsheet_id&&map[o.runsheet_id]?map[o.runsheet_id]:null;});_applyFilters();return map;}

        return {render:render,_applyFilters:_applyFilters,_resetFilters:_resetFilters,_showWithoutRS:_showWithoutRS,_sort:_sort,_confirm:_confirm,_delete:_delete,_confirmOrderFromDetails:_confirmOrderFromDetails,_showDetails:_showDetails,_printOrder:_printOrder,_buildPrintWindow:_buildPrintWindow,_createRS:_createRS,_appendRS:_appendRS,_refreshData:_refreshData,_loadRunsheetCodes:_loadRunsheetCodes,_getSelectedOrders:_getSelectedOrders};
    }());
    window.RW_Orders=RW_Orders;

    // ============================================================
    // RW_Runsheets
    // ============================================================
    var RW_Runsheets=(function(){
        var sortField='runsheet_code',sortAsc=true,data=[],driversCache=[],vehiclesCache=[];
        function _esc(value){return esc(value);} function _fmtNum(value){return formatNumber(value);}

        async function loadHelpers(){var companyId=getCompanyId();var dRes=await sb.from('users').select('id,email,name,role,status').eq('company_id',companyId).in('role',['driver','سائق','مندوب']).order('name');if(dRes.error)throw dRes.error;driversCache=dRes.data||[];var vRes=await sb.from('vehicles').select('id,license_plate,model,company_id').eq('company_id',companyId).order('license_plate');if(vRes.error)throw vRes.error;vehiclesCache=vRes.data||[];}
        function decorate(rows){return(rows||[]).map(function(r){var d=driversCache.find(function(x){return x.id===r.driver_id;});var v=vehiclesCache.find(function(x){return x.id===r.vehicle_id;});r._driverName=d?(d.name||d.email||r.driver_id):(r.driver_id||'---');r._vehicleLabel=v?(v.license_plate||v.model||v.id):(r.vehicle_id||'---');return r;});}

        async function render(){var container=byLocalId('rw-page-container');if(!container)return;safeText(byLocalId('rw-header-title'),'الرانشيتات');safeText(byLocalId('rw-header-subtitle'),'إدارة الرحلات والأوردرات المرتبطة بها');showLoader('جاري تحميل الرانشيتات...');try{await loadHelpers();var companyId=getCompanyId();var res=await sb.from('runsheets').select('*').eq('company_id',companyId).order('run_date',{ascending:false}).order('runsheet_code',{ascending:true});if(res.error)throw res.error;data=decorate(res.data||[]);safeHTML(container,'<div class="p-4"><div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2"><input type="text" id="rs-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-gray-50 rounded text-sm" oninput="RW_Runsheets._apply()"><select id="rs-f-status" class="p-2 bg-gray-50 rounded text-sm" onchange="RW_Runsheets._apply()"><option value="">كل الحالات</option><option>Open</option><option>Picking</option><option>Picked</option><option>Loading</option><option>Loaded</option><option>Delivering</option><option>Delivered</option><option>Returning</option><option>Returned</option><option>Cancelled</option></select><input type="text" id="rs-f-driver" placeholder="السائق..." class="p-2 bg-gray-50 rounded text-sm" oninput="RW_Runsheets._apply()"><input type="date" id="rs-f-from" class="p-2 bg-gray-50 rounded text-sm" onchange="RW_Runsheets._apply()"><input type="date" id="rs-f-to" class="p-2 bg-gray-50 rounded text-sm" onchange="RW_Runsheets._apply()"><button onclick="RW_Runsheets._apply()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button></div></div><div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full min-w-[1200px]"><thead class="bg-gray-50 sticky top-0 z-10"><tr><th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Runsheets._sort(\'runsheet_code\')">رقم الرانشيت <i class="fa-solid fa-sort"></i></th><th class="p-3 text-center text-xs font-bold uppercase">التاريخ</th><th class="p-3 text-center text-xs font-bold uppercase">السائق</th><th class="p-3 text-center text-xs font-bold uppercase">السيارة</th><th class="p-3 text-center cursor-pointer text-xs font-bold uppercase" onclick="RW_Runsheets._sort(\'total_amount\')">القيمة <i class="fa-solid fa-sort"></i></th><th class="p-3 text-center text-xs font-bold uppercase">الحالة</th></tr></thead><tbody id="rs-table-body"><tr><td colspan="6" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div></div>');_apply();}catch(e){notifyError(e,'تعذر تحميل الرانشيتات');}finally{hideLoader();}}

        function _apply(){var filtered=data.slice(),idEl=byLocalId('rs-f-id'),stEl=byLocalId('rs-f-status'),drEl=byLocalId('rs-f-driver'),fromEl=byLocalId('rs-f-from'),toEl=byLocalId('rs-f-to');var id=idEl?String(idEl.value||'').toLowerCase().trim():'',st=stEl?stEl.value:'',dr=drEl?String(drEl.value||'').toLowerCase().trim():'',fd=fromEl?fromEl.value:'',td=toEl?toEl.value:'';if(id)filtered=filtered.filter(function(r){return String(r.runsheet_code||'').toLowerCase().indexOf(id)!==-1;});if(st)filtered=filtered.filter(function(r){return r.status===st;});if(dr)filtered=filtered.filter(function(r){return String(r._driverName||'').toLowerCase().indexOf(dr)!==-1||String(r.driver_id||'').toLowerCase().indexOf(dr)!==-1;});if(fd)filtered=filtered.filter(function(r){return String(r.run_date||'')>=fd;});if(td)filtered=filtered.filter(function(r){return String(r.run_date||'')<=td;});filtered.sort(function(a,b){var va=a[sortField],vb=b[sortField];if(sortField==='total_amount'){va=Number(va)||0;vb=Number(vb)||0;}else if(sortField==='run_date'){va=new Date(va||0).getTime();vb=new Date(vb||0).getTime();}else{va=String(va==null?'':va).toLowerCase();vb=String(vb==null?'':vb).toLowerCase();}return(va<vb?-1:va>vb?1:0)*(sortAsc?1:-1);});_renderTable(filtered);}
        function _sort(field){if(sortField===field)sortAsc=!sortAsc;else{sortField=field;sortAsc=true;}_apply();}
        function _statusClass(st){if(st==='Open'||st==='Confirmed')return'bg-blue-100 text-blue-700';if(st==='Picking'||st==='Picked')return'bg-purple-100 text-purple-700';if(st==='Loading'||st==='Loaded')return'bg-orange-100 text-orange-700';if(st==='Delivering')return'bg-cyan-100 text-cyan-700';if(st==='Delivered')return'bg-green-100 text-green-700';if(st==='Returning'||st==='Returned')return'bg-yellow-100 text-yellow-700';if(st==='Cancelled')return'bg-red-100 text-red-700';return'bg-gray-100 text-gray-600';}
        function _renderTable(rows){var tb=byLocalId('rs-table-body');if(!tb)return;if(!rows.length){safeHTML(tb,'<tr><td colspan="6" class="text-center py-8">لا توجد رانشيتات</td></tr>');return;}RW_Table.paginate('rs-table-body',rows,1,50,function(r){return'<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Runsheets._details(\''+escAttr(r.runsheet_code)+'\')"><td class="p-3 text-center font-bold text-emerald-600">'+esc(r.runsheet_code)+'</td><td class="p-3 text-center">'+esc(formatDate(r.run_date))+'</td><td class="p-3 text-center">'+esc(r._driverName)+'</td><td class="p-3 text-center">'+esc(r._vehicleLabel)+'</td><td class="p-3 text-center font-bold">'+_fmtNum(r.total_amount)+' EGP</td><td class="p-3 text-center"><span class="px-2 py-1 rounded-full text-xs '+_statusClass(r.status)+'">'+esc(r.status)+'</span></td></tr>';});}
        function buildDriverOptions(rs){var html='<option value="">اختر السائق...</option>';driversCache.forEach(function(d){html+='<option value="'+escAttr(d.id)+'"'+(rs.driver_id===d.id?' selected':'')+'>'+esc(d.name||d.email||d.id)+' ('+esc(d.email||'')+')</option>';});return html;}
        function buildVehicleOptions(rs){var html='<option value="">اختر المركبة...</option>';vehiclesCache.forEach(function(v){html+='<option value="'+escAttr(v.id)+'"'+(rs.vehicle_id===v.id?' selected':'')+'>'+esc(v.license_plate||v.id)+' - '+esc(v.model||'')+'</option>';});return html;}

        async function _details(code){showLoader('جاري تحميل تفاصيل الرانشيت...');try{var companyId=getCompanyId();var rsRes=await sb.from('runsheets').select('*').eq('company_id',companyId).eq('runsheet_code',code).maybeSingle();if(rsRes.error)throw rsRes.error;var rs=rsRes.data;if(!rs)throw new Error('الرانشيت غير موجود');var ordersRes=await sb.from('orders').select('id,order_code,customer_name,total_amount,company_id').eq('company_id',companyId).eq('runsheet_id',rs.id).order('order_code');if(ordersRes.error)throw ordersRes.error;var orders=ordersRes.data||[];var itemsRes=await sb.from('run_sheet_details').select('*').eq('runsheet_id',rs.id).order('item_code');if(itemsRes.error)throw itemsRes.error;var items=itemsRes.data||[];var ordersHtml=orders.length?'<div class="mb-4"><h4 class="font-bold text-lg mb-2">الأوردرات المرتبطة</h4><div class="bg-gray-50 rounded-lg p-3 flex flex-wrap gap-2">'+orders.map(function(o){return'<span class="inline-block bg-white rounded px-3 py-1 text-sm shadow-sm">'+esc(o.order_code)+' - '+esc(o.customer_name)+' ('+_fmtNum(o.total_amount)+' EGP)</span>';}).join('')+'</div></div>':'<div class="mb-4 text-gray-500 text-sm">لا توجد أوردرات مرتبطة</div>';var grandTotal=0;var itemsHtml=items.length?'<div class="mt-4"><h4 class="font-bold text-lg mb-2">الأصناف المجمعة</h4><div class="overflow-x-auto border rounded-lg" style="max-height:300px;overflow-y:auto;"><table class="w-full text-sm"><thead class="bg-gray-100 sticky top-0 z-10"><tr><th class="p-2 border">الكود</th><th class="p-2 border">الصنف</th><th class="p-2 border text-center">الوحدة</th><th class="p-2 border text-center">الكمية</th><th class="p-2 border text-center">السعر</th><th class="p-2 border text-center">الإجمالي</th></tr></thead><tbody>'+items.map(function(it){var total=(Number(it.qty_ordered)||0)*(Number(it.unit_price)||0);grandTotal+=total;return'<tr><td class="p-2 border">'+_esc(it.item_code)+'</td><td class="p-2 border font-semibold">'+_esc(it.item_name)+'</td><td class="p-2 border text-center">'+_esc(it.unit)+'</td><td class="p-2 border text-center font-bold">'+esc(it.qty_ordered||0)+'</td><td class="p-2 border text-center">'+_fmtNum(it.unit_price)+'</td><td class="p-2 border text-center font-bold">'+_fmtNum(total)+'</td></tr>';}).join('')+'</tbody></table></div><div class="mt-3 text-left font-bold text-lg">إجمالي الأصناف: '+_fmtNum(grandTotal)+' EGP</div></div>':'<div class="text-center py-8 text-gray-500 mt-4">لا توجد أصناف مجمعة في هذا الرانشيت بعد.</div>';var content='<div class="text-right space-y-4" style="max-height:70vh;overflow-y:auto;padding:8px;"><div class="flex justify-between items-center"><div><h3 class="font-black text-2xl">'+esc(rs.runsheet_code)+'</h3><p class="text-gray-500">التاريخ: '+esc(formatDate(rs.run_date))+'</p></div><div><span class="px-3 py-1 rounded-full text-xs font-bold '+_statusClass(rs.status)+'">'+esc(rs.status)+'</span></div></div><div class="grid grid-cols-2 md:grid-cols-4 gap-3 bg-gray-50 p-4 rounded-2xl"><div><p class="text-xs text-gray-400">السائق</p><select id="rs-driver-select" class="w-full p-2 border rounded-lg bg-white text-sm">'+buildDriverOptions(rs)+'</select></div><div><p class="text-xs text-gray-400">السيارة</p><select id="rs-vehicle-select" class="w-full p-2 border rounded-lg bg-white text-sm">'+buildVehicleOptions(rs)+'</select></div><div><p class="text-xs text-gray-400">عدد الأوردرات</p><p class="font-bold text-xl">'+formatNumber(orders.length)+'</p></div><div><p class="text-xs text-gray-400">القيمة الإجمالية</p><p class="font-bold text-xl text-emerald-600">'+_fmtNum(rs.total_amount)+' EGP</p></div></div>'+ordersHtml+itemsHtml+'<div class="flex justify-center gap-3 mt-6 pt-4 border-t"><button id="btn-delete-rs-modal" class="bg-red-600 text-white px-6 py-2 rounded-xl font-bold shadow"><i class="fa-solid fa-trash ml-2"></i> حذف الرانشيت</button></div></div>';Swal.fire({title:'تفاصيل الرانشيت: '+esc(code),html:content,width:'1000px',showCloseButton:true,showConfirmButton:true,confirmButtonText:'حفظ التغييرات',showCancelButton:true,cancelButtonText:'إلغاء',showDenyButton:true,denyButtonText:'<i class="fa-solid fa-print ml-1"></i> طباعة',denyButtonColor:'#2563eb',preConfirm:async function(){var newDriver=byLocalId('rs-driver-select').value||null,newVehicle=byLocalId('rs-vehicle-select').value||null,before={driver_id:rs.driver_id,vehicle_id:rs.vehicle_id,status:rs.status};var result=await sb.from('runsheets').update({driver_id:newDriver,vehicle_id:newVehicle}).eq('company_id',companyId).eq('id',rs.id);if(result.error)throw result.error;var verify=await sb.from('runsheets').select('driver_id,vehicle_id,status').eq('company_id',companyId).eq('id',rs.id).maybeSingle();if(verify.error)throw verify.error;if(!verify.data||verify.data.status!==before.status)throw new Error('حماية حالة الرانشيت فشلت أثناء التحديث');safeAudit('update','runsheets',code,before,verify.data);data=data.map(function(x){return x.id===rs.id?Object.assign(x,rs,verify.data):x;});_apply();showToast('تم تحديث بيانات الرانشيت','success');return true;},didOpen:function(){var denyBtn=Swal.getDenyButton();if(denyBtn)denyBtn.onclick=function(){_printManifest(code,rs,orders,items);};var deleteBtn=byLocalId('btn-delete-rs-modal');if(deleteBtn)deleteBtn.onclick=function(){Swal.close();_deleteRunsheet(code);};}});}catch(e){notifyError(e,'فشل تحميل تفاصيل الرانشيت');}finally{hideLoader();}}

        async function _deleteRunsheet(code){var companyId=getCompanyId(),found=data.find(function(x){return x.runsheet_code===code&&x.company_id===companyId;});if(!found){showToast('الرانشيت غير موجود','error');return;}if(['Open','Confirmed'].indexOf(found.status)===-1){showToast('لا يمكن حذف رانشيت بعد بدء التنفيذ. استخدم الإجراء المناسب لسير العمل.','error');return;}var cf=await Swal.fire({title:'تأكيد الحذف',text:'سيتم حذف الرانشيت '+code+' وتحرير الأوردرات المرتبطة. متابعة؟',icon:'warning',showCancelButton:true,confirmButtonText:'نعم، احذف',cancelButtonText:'تراجع',confirmButtonColor:'#dc2626'});if(!cf.isConfirmed)return;showLoader('جاري حذف الرانشيت...');try{var ordersRes=await sb.from('orders').update({order_status:'Confirmed',runsheet_id:null}).eq('company_id',companyId).eq('runsheet_id',found.id).select('id');if(ordersRes.error)throw ordersRes.error;var detailsRes=await sb.from('run_sheet_details').delete().eq('runsheet_id',found.id);if(detailsRes.error)throw detailsRes.error;var deleteRes=await sb.from('runsheets').delete().eq('company_id',companyId).eq('id',found.id).in('status',['Open','Confirmed']).select('id').maybeSingle();if(deleteRes.error)throw deleteRes.error;if(!deleteRes.data)throw new Error('لم يتم حذف الرانشيت؛ تغيرت حالته قبل التنفيذ');safeAudit('delete','runsheets',code,found,null);data=data.filter(function(x){return x.id!==found.id;});_apply();showToast('تم حذف الرانشيت وتحرير الأوردرات بنجاح','success');}catch(e){notifyError(e,'فشل حذف الرانشيت');}finally{hideLoader();}}

        async function _cancelRunsheet(code){var companyId=getCompanyId(),found=data.find(function(x){return x.runsheet_code===code&&x.company_id===companyId;});if(!found){showToast('الرانشيت غير موجود','error');return;}if(['Open','Confirmed'].indexOf(found.status)===-1){showToast('لا يمكن إلغاء رانشيت في حالة: '+found.status,'error');return;}var cf=await Swal.fire({title:'إلغاء الرانشيت',text:'سيتم إلغاء الرانشيت '+code+' وتحرير الأوردرات المرتبطة.',icon:'warning',showCancelButton:true,confirmButtonText:'نعم، إلغاء',cancelButtonText:'تراجع',confirmButtonColor:'#dc2626'});if(!cf.isConfirmed)return;showLoader('جاري إلغاء الرانشيت...');try{var before=Object.assign({},found);var rsUpdate=await sb.from('runsheets').update({status:'Cancelled'}).eq('company_id',companyId).eq('id',found.id).in('status',['Open','Confirmed']).select('id,status').maybeSingle();if(rsUpdate.error)throw rsUpdate.error;if(!rsUpdate.data)throw new Error('تعذر تغيير حالة الرانشيت');var orderUpdate=await sb.from('orders').update({order_status:'Confirmed',runsheet_id:null}).eq('company_id',companyId).eq('runsheet_id',found.id).select('id');if(orderUpdate.error)throw orderUpdate.error;var detailDelete=await sb.from('run_sheet_details').delete().eq('runsheet_id',found.id);if(detailDelete.error)throw detailDelete.error;safeAudit('update','runsheets',code,before,{status:'Cancelled'});data=data.filter(function(x){return x.id!==found.id;});_apply();showToast('تم إلغاء الرانشيت وتحرير الأوردرات بنجاح','success');}catch(e){notifyError(e,'فشل إلغاء الرانشيت');}finally{hideLoader();}}

        async function _changeStatus(code,funcName){try{var companyId=getCompanyId();var found=data.find(function(x){return x.runsheet_code===code&&x.company_id===companyId;});if(!found)throw new Error('الرانشيت غير موجود في سياق الشركة الحالي');await edgeCall(funcName,{runsheet_code:code});showToast('تم تحديث حالة الرانشيت بنجاح','success');await render();}catch(e){notifyError(e,'فشل تحديث الحالة');}finally{hideLoader();}}

        function _printManifest(code,rs,orders,items){var printWindow=window.open('', '_blank');if(!printWindow){showToast('الرجاء السماح بالنوافذ المنبثقة','warning');return;}var ordersHtml=orders&&orders.length?orders.map(function(o){return'<span style="display:inline-block;background:#fff;border-radius:8px;padding:4px 12px;margin:4px;font-size:13px;box-shadow:0 1px 3px rgba(0,0,0,0.1);">'+esc(o.order_code)+' - '+esc(o.customer_name)+' ('+_fmtNum(o.total_amount)+' EGP)</span>';}).join(''):'<p>لا توجد أوردرات مرتبطة</p>';var grandTotal=0;var itemsHtml=items&&items.length?'<table style="width:100%;border-collapse:collapse;margin-top:16px"><thead><tr style="background:#f3f4f6"><th style="padding:10px;border:1px solid #ddd;text-align:right">الكود</th><th style="padding:10px;border:1px solid #ddd;text-align:right">الصنف</th><th style="padding:10px;border:1px solid #ddd;text-align:center">الوحدة</th><th style="padding:10px;border:1px solid #ddd;text-align:center">الكمية</th><th style="padding:10px;border:1px solid #ddd;text-align:center">السعر</th><th style="padding:10px;border:1px solid #ddd;text-align:center">الإجمالي</th></tr></thead><tbody>'+items.map(function(item){var lineTotal=(Number(item.qty_ordered)||0)*(Number(item.unit_price)||0);grandTotal+=lineTotal;return'<tr><td style="padding:8px;border:1px solid #ddd">'+esc(item.item_code)+'</td><td style="padding:8px;border:1px solid #ddd;font-weight:bold">'+esc(item.item_name)+'</td><td style="padding:8px;border:1px solid #ddd;text-align:center">'+esc(item.unit)+'</td><td style="padding:8px;border:1px solid #ddd;text-align:center;font-weight:bold">'+esc(item.qty_ordered||0)+'</td><td style="padding:8px;border:1px solid #ddd;text-align:center">'+_fmtNum(item.unit_price)+'</td><td style="padding:8px;border:1px solid #ddd;text-align:center;font-weight:bold">'+_fmtNum(lineTotal)+'</td></tr>';}).join('')+'</tbody></table>':'<p style="text-align:center;color:#6b7280;margin-top:16px">لا توجد أصناف مجمعة</p>';var driver=(driversCache.find(function(d){return d.id===rs.driver_id;})||{}).name||rs.driver_id||'---';var vehicle=(vehiclesCache.find(function(v){return v.id===rs.vehicle_id;})||{}).license_plate||rs.vehicle_id||'---';var html='<!DOCTYPE html><html dir="rtl"><head><meta charset="UTF-8"><title>بيان رحلة - '+esc(code)+'</title><style>body{font-family:Cairo,Arial,sans-serif;padding:20px;color:#111827}h1{font-size:24px;margin-bottom:4px}h2{font-size:18px;color:#6b7280;margin-bottom:20px}.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;background:#f9fafb;padding:16px;border-radius:12px;margin-bottom:20px}.info-item label{font-size:12px;color:#6b7280;display:block}.info-item span{font-weight:bold;font-size:16px}@media print{body{padding:0}}</style></head><body><h1>بيان رحلة: '+esc(code)+'</h1><h2>التاريخ: '+esc(formatDate(rs.run_date))+' | الحالة: '+esc(rs.status)+'</h2><div class="info-grid"><div class="info-item"><label>السائق</label><span>'+esc(driver)+'</span></div><div class="info-item"><label>السيارة</label><span>'+esc(vehicle)+'</span></div><div class="info-item"><label>عدد الأوردرات</label><span>'+formatNumber(orders.length)+'</span></div><div class="info-item"><label>القيمة الإجمالية</label><span>'+_fmtNum(rs.total_amount)+' EGP</span></div></div><h3>الأوردرات المرتبطة</h3><div style="margin-bottom:20px">'+ordersHtml+'</div><h3>الأصناف المجمعة</h3>'+itemsHtml+'<div style="text-align:left;font-size:20px;font-weight:bold;margin-top:20px">الإجمالي: '+_fmtNum(grandTotal)+' EGP</div><p style="text-align:center;margin-top:40px;color:#9ca3af;font-size:12px">تم إنشاء هذا البيان بواسطة نظام الروائع ERP</p><script>window.print();<\\/script></body></html>';printWindow.document.write(html);printWindow.document.close();}

        return {render:render,_apply:_apply,_sort:_sort,_deleteRunsheet:_deleteRunsheet,_cancelRunsheet:_cancelRunsheet,_changeStatus:_changeStatus,_details:_details,_printManifest:_printManifest};
    }());
    window.RW_Runsheets=RW_Runsheets;
}());
