# Report277 — OWNER SURGICAL PATCH — Mother Voucher Type Reporting
File: papamohammed77-glitch/erp-frontend/companies/company-1/main.html
Current Mother blob: e2b0dcb8317034363365fe728e8b4c33d1bf08da
Mother HEAD: 4aebf36b6da684ecb1e09d8f83063e0231c70866

## PATCH M1
ابحث تحديدًا عن الدالة function loadVoucherForm(type) داخل var RW_Warehouse = (function() { في الأسطر الحالية 13900–13956.
احذف الدالة كاملة ثم استبدلها بالكامل بالنص التالي:

```javascript
function loadVoucherForm(type) {
    voucherCart = [];
    currentVoucherType = type;
    var configs = {
        'Transfer':      { title: 'تحويل مخزني', entityLabel: 'الفرع المحول إليه', showPrice: false, fromType: 'Branch', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
        'DirectSale':    { title: 'صرف سيارة بيع مباشر', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Branch', fromId: null, toType: 'Vehicle', toId: null, endpoint: 'save-voucher' },
        'DirectReturn':  { title: 'استلام مرتجع سيارة', entityLabel: 'المندوب / السيارة', showPrice: true, fromType: 'Vehicle', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
        'SupplierReturn':{ title: 'مرتجع لمورد', entityLabel: 'المورد', showPrice: true, fromType: 'Branch', fromId: null, toType: 'Supplier', toId: null, endpoint: 'save-voucher' }
    };
    var cfg = configs[type];
    if (!cfg) { showToast('نوع غير معروف', 'error'); return; }
    currentVoucherConfig = cfg;
    var c = byId('rw-page-container');
    if (!c) return;
    safeText(byId('rw-header-title'), cfg.title);
    safeHTML(c, \`<div class="p-4">
        <div class="bg-white rounded-2xl shadow-sm border p-4">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-xl font-bold"><i class="fa-solid fa-file-signature ml-2 text-indigo-600"></i>\${cfg.title}</h2>
                <button onclick="RW_Warehouse.loadVouchers()" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                    <label class="block text-sm font-bold mb-1">\${cfg.entityLabel}</label>
                    <select id="voucherEntitySelect" class="border rounded-lg p-2 w-full"><option value="">-- اختر --</option></select>
                </div>
                <div>
                    <label class="block text-sm font-bold mb-1">مرجع الإذن</label>
                    <input id="voucherReference" class="border rounded-lg p-2 w-full" placeholder="مرجع الإذن...">
                </div>
                <div>
                    <label class="block text-sm font-bold mb-1">ملاحظات</label>
                    <textarea id="voucherNotesLarge" rows="2" class="border rounded-lg p-2 w-full" placeholder="ملاحظات..."></textarea>
                </div>
            </div>
            <label class="block text-sm font-bold mb-1">بحث عن صنف</label>
            <div class="relative">
                <input type="text" id="voucherItemSearch" oninput="RW_Warehouse._searchVoucherItem(this.value)" autocomplete="off" placeholder="ابحث بالاسم أو الباركود..." class="border rounded-lg p-2 w-full">
                <div id="voucherSearchResults" class="absolute z-50 left-0 right-0 mt-1 bg-white shadow-xl rounded-xl max-h-60 overflow-y-auto hidden border"></div>
            </div>
            <div class="mb-4 overflow-y-auto" style="max-height:300px;" id="voucherItemsTable">
                <div class="text-center py-8 text-gray-400">أضف أصنافاً</div>
            </div>
            <div class="p-3 bg-gray-50 rounded-lg flex justify-between items-center mb-4">
                <span class="font-bold">عدد الأصناف: <span id="voucherTotalItems">0</span></span>
            </div>
            <div class="flex justify-end gap-3">
                <button onclick="RW_Warehouse._clearVoucherCart()" class="px-4 py-2 bg-gray-500 text-white rounded-lg font-bold">مسح الكل</button>
                <button onclick="RW_Warehouse._saveAndSendVoucher()" class="px-6 py-2 bg-indigo-600 text-white rounded-lg font-bold">حفظ وإرسال (Sent)</button>
            </div>
        </div>
        <div id="rw-voucher-history-panel" class="mt-6"></div>
    </div>\`);
    _loadVoucherEntityOptions(type);
    _renderVoucherCart();
    _renderVoucherHistory(type);
}
```

## PATCH M2
بعد نهاية loadVoucherForm(type) الجديدة مباشرة، وقبل السطر async function _loadVoucherEntityOptions(type) {، أضف الدالة التالية كاملة:

```javascript
async function _renderVoucherHistory(type) {
    var root = byId('rw-voucher-history-panel');
    if (!root) return;
    var labels = {'Transfer':'تحويل مخزني','DirectSale':'صرف سيارة بيع مباشر','DirectReturn':'استلام مرتجع سيارة','SupplierReturn':'مرتجع لمورد'};
    var title = labels[type] || type;
    var state = {page:0,limit:25,busy:false,total:0,rows:[],summary:{statuses:[]},timer:null};

    function readFilters() {
        return {
            search:(byId('rw-vr-search')?.value || '').trim(),
            status:byId('rw-vr-status') ? byId('rw-vr-status').value : '',
            from_date:byId('rw-vr-from') ? byId('rw-vr-from').value : '',
            to_date:byId('rw-vr-to') ? byId('rw-vr-to').value : ''
        };
    }

    function statusLabel(v) {
        return {'Draft':'مسودة','Sent':'مُرسل','Received':'مُستلم','Completed':'مكتمل','Cancelled':'ملغى'}[v] || v || '—';
    }

    function statusClass(v) {
        return {'Draft':'bg-gray-100 text-gray-700','Sent':'bg-blue-100 text-blue-700','Received':'bg-purple-100 text-purple-700','Completed':'bg-green-100 text-green-700','Cancelled':'bg-red-100 text-red-700'}[v] || 'bg-slate-100 text-slate-700';
    }

    function render() {
        var start = state.total ? (state.page*state.limit+1) : 0;
        var end = Math.min((state.page+1)*state.limit,state.total);
        var summary = {};
        (state.summary.statuses || []).forEach(function(x){summary[x.status]=Number(x.count||0);});
        var rowsHtml = '';
        if (!state.rows.length) {
            rowsHtml = '<tr><td colspan="10" class="p-8 text-center text-slate-400">لا توجد عمليات مطابقة للفلاتر الحالية</td></tr>';
        } else {
            for (var i=0;i<state.rows.length;i++) {
                var r=state.rows[i], code=encodeURIComponent(String(r.voucher_code||''));
                rowsHtml += '<tr class="border-b hover:bg-indigo-50/40">' +
                    '<td class="p-3 font-black text-indigo-700 whitespace-nowrap">'+esc(r.voucher_code||'')+'</td>' +
                    '<td class="p-3 whitespace-nowrap">'+esc(r.voucher_date||'')+'</td>' +
                    '<td class="p-3"><span class="px-2.5 py-1 rounded-full text-xs font-black '+statusClass(r.status)+'">'+esc(statusLabel(r.status))+'</span></td>' +
                    '<td class="p-3">'+esc(r.reference||'—')+'</td>' +
                    '<td class="p-3 max-w-[220px]">'+esc(r.from_label||'—')+'</td>' +
                    '<td class="p-3 max-w-[220px]">'+esc(r.to_label||'—')+'</td>' +
                    '<td class="p-3">'+esc(r.created_by||'—')+'</td>' +
                    '<td class="p-3 text-center font-bold">'+Number(r.item_lines||0)+'</td>' +
                    '<td class="p-3 text-center font-bold">'+Number(r.total_qty||0)+'</td>' +
                    '<td class="p-3 text-center whitespace-nowrap"><button type="button" data-rw-vr-action="details" data-rw-vr-code="'+code+'" class="text-blue-600 mx-1" title="التفاصيل والرقابة"><i class="fa-solid fa-eye"></i></button><span class="text-xs text-slate-400 mx-1" title="حركات المخزون / سجلات المراجعة">'+Number(r.movement_count||0)+' / '+Number(r.audit_count||0)+'</span></td>' +
                '</tr>';
            }
        }
        var totalPages=Math.max(1,Math.ceil(state.total/state.limit)), f=readFilters();
        safeHTML(root,
            '<div class="bg-gradient-to-r from-slate-900 to-indigo-900 text-white rounded-3xl p-5 shadow-lg mb-4"><div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4"><div><div class="text-xs font-black text-indigo-200">WAREHOUSE VOUCHER CONTROL</div><h3 class="text-xl sm:text-2xl font-black mt-1">السجل والرقابة — '+esc(title)+'</h3><p class="text-sm text-slate-200 mt-1">تاريخ الأذونات من نفس مستند Production مع drill-down للتفاصيل والحركة والمراجعة.</p></div><button type="button" data-rw-vr-action="refresh" class="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/20 font-black"><i class="fa-solid fa-rotate ml-1"></i> تحديث</button></div></div>' +
            '<div class="grid grid-cols-2 md:grid-cols-5 gap-3 mb-4">' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-slate-400 font-bold">الإجمالي</div><div class="text-2xl font-black text-slate-800 mt-1">'+Number(state.total)+'</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-slate-400 font-bold">مسودة</div><div class="text-2xl font-black mt-1">'+Number(summary.Draft||0)+'</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-slate-400 font-bold">مُرسل</div><div class="text-2xl font-black text-blue-700 mt-1">'+Number(summary.Sent||0)+'</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-slate-400 font-bold">مُستلم</div><div class="text-2xl font-black text-purple-700 mt-1">'+Number(summary.Received||0)+'</div></div>' +
            '<div class="bg-white rounded-2xl border p-4"><div class="text-xs text-slate-400 font-bold">مكتمل</div><div class="text-2xl font-black text-green-700 mt-1">'+Number(summary.Completed||0)+'</div></div></div>' +
            '<div class="bg-white rounded-2xl border p-4 mb-4"><div class="grid grid-cols-1 md:grid-cols-4 gap-3"><input id="rw-vr-search" value="'+esc(f.search)+'" placeholder="بحث ذكي: رقم، مرجع، صنف، فرع، سيارة، مورد، منشئ، ملاحظات" class="p-3 border-2 border-slate-100 rounded-xl font-semibold">' +
            '<select id="rw-vr-status" class="p-3 border-2 border-slate-100 rounded-xl font-semibold"><option value="">كل الحالات</option><option value="Draft"'+(f.status==='Draft'?' selected':'')+'>مسودة</option><option value="Sent"'+(f.status==='Sent'?' selected':'')+'>مُرسل</option><option value="Received"'+(f.status==='Received'?' selected':'')+'>مُستلم</option><option value="Completed"'+(f.status==='Completed'?' selected':'')+'>مكتمل</option><option value="Cancelled"'+(f.status==='Cancelled'?' selected':'')+'>ملغى</option></select>' +
            '<input id="rw-vr-from" type="date" value="'+esc(f.from_date)+'" class="p-3 border-2 border-slate-100 rounded-xl font-semibold"><input id="rw-vr-to" type="date" value="'+esc(f.to_date)+'" class="p-3 border-2 border-slate-100 rounded-xl font-semibold"></div>' +
            '<div class="flex flex-wrap items-center gap-2 mt-3"><span class="text-xs font-black text-slate-500">النوع الحالي: '+esc(title)+'</span><span class="text-xs font-black text-slate-400">• المصدر: Manual / المستند الموحد في Production</span></div></div>' +
            '<div class="bg-white rounded-2xl border overflow-auto"><table class="w-full min-w-[1050px]"><thead class="bg-slate-900 text-white"><tr><th class="p-3 text-right">رقم الإذن</th><th class="p-3 text-right">التاريخ</th><th class="p-3 text-right">الحالة</th><th class="p-3 text-right">المرجع</th><th class="p-3 text-right">من</th><th class="p-3 text-right">إلى</th><th class="p-3 text-right">المنشئ</th><th class="p-3 text-center">بنود</th><th class="p-3 text-center">كميات</th><th class="p-3 text-center">رقابة</th></tr></thead><tbody>'+rowsHtml+'</tbody></table></div>' +
            '<div class="flex flex-col sm:flex-row items-center justify-between gap-3 mt-4"><div class="text-sm text-slate-500 font-bold">عرض '+start+' — '+end+' من '+Number(state.total)+' • صفحة '+(state.page+1)+' من '+totalPages+'</div><div class="flex gap-2"><button type="button" data-rw-vr-action="prev" class="px-4 py-2 rounded-xl border font-black" '+(state.page<=0?'disabled':'')+'>السابق</button><button type="button" data-rw-vr-action="next" class="px-4 py-2 rounded-xl border font-black" '+(!state.total || (state.page+1)*state.limit>=state.total?'disabled':'')+'>التالي</button></div></div>'
        );
    }

    async function showAudit(code) {
        showLoader('جاري تحميل الرقابة...');
        try {
            var result=await supabase.rpc('inventory_control',{p_operation:'VOUCHER_AUDIT',p_payload:{voucher_code:code}});
            if(result.error) throw result.error;
            var data=result.data||{}, voucher=data.voucher||{}, details=Array.isArray(data.details)?data.details:[], movements=Array.isArray(data.movements)?data.movements:[], audit=Array.isArray(data.audit)?data.audit:[];
            var h='<div class="text-right space-y-5"><div class="grid grid-cols-2 md:grid-cols-4 gap-3"><div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-400">الإذن</div><div class="font-black">'+esc(voucher.voucher_code||code)+'</div></div><div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-400">التاريخ</div><div class="font-black">'+esc(voucher.voucher_date||'—')+'</div></div><div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-400">الحالة</div><div class="font-black">'+esc(statusLabel(voucher.status))+'</div></div><div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-400">المنشئ</div><div class="font-black text-xs break-all">'+esc(voucher.created_by||'—')+'</div></div></div>';
            h+='<div><h4 class="font-black mb-2">بنود الإذن</h4><div class="overflow-auto"><table class="w-full border text-sm"><thead class="bg-slate-100"><tr><th class="p-2 border">الكود</th><th class="p-2 border">الصنف</th><th class="p-2 border">الكمية</th><th class="p-2 border">المستلم</th></tr></thead><tbody>';
            details.forEach(function(d){h+='<tr><td class="p-2 border">'+esc(d.item_code||'')+'</td><td class="p-2 border font-semibold">'+esc(d.item_name||'')+'</td><td class="p-2 border text-center">'+Number(d.qty||0)+'</td><td class="p-2 border text-center">'+Number(d.received_qty||0)+'</td></tr>';});
            h+='</tbody></table></div></div><div><h4 class="font-black mb-2">الحركات الفعلية</h4><div class="overflow-auto"><table class="w-full border text-sm"><thead class="bg-slate-100"><tr><th class="p-2 border">التاريخ</th><th class="p-2 border">الحركة</th><th class="p-2 border">الصنف</th><th class="p-2 border">الكمية</th><th class="p-2 border">المستخدم</th></tr></thead><tbody>';
            movements.forEach(function(m){h+='<tr><td class="p-2 border whitespace-nowrap">'+esc(m.created_at||'')+'</td><td class="p-2 border">'+esc(m.movement_type||'')+'</td><td class="p-2 border">'+esc(m.item_code||m.item_name||'')+'</td><td class="p-2 border text-center font-bold">'+Number(m.qty||0)+'</td><td class="p-2 border">'+esc(m.user_email||'—')+'</td></tr>';});
            h+='</tbody></table></div></div><div><h4 class="font-black mb-2">سجل المراجعة</h4><div class="overflow-auto"><table class="w-full border text-sm"><thead class="bg-slate-100"><tr><th class="p-2 border">التاريخ</th><th class="p-2 border">العملية</th><th class="p-2 border">المستخدم</th><th class="p-2 border">Operation ID</th></tr></thead><tbody>';
            audit.forEach(function(a){h+='<tr><td class="p-2 border whitespace-nowrap">'+esc(a.created_at||'')+'</td><td class="p-2 border">'+esc(a.action||'')+'</td><td class="p-2 border">'+esc(a.user_email||'—')+'</td><td class="p-2 border text-xs break-all">'+esc(a.operation_id||'—')+'</td></tr>';});
            h+='</tbody></table></div></div></div>';
            await Swal.fire({title:'رقابة الإذن: '+esc(code),html:h,width:'1100px',showCloseButton:true,showConfirmButton:false});
        } catch(e) {
            showToast(e.message||'تعذر تحميل رقابة الإذن','error');
        } finally { hideLoader(); }
    }

    async function query() {
        if(state.busy) return;
        state.busy=true;
        var f=readFilters();
        try {
            var payload={type:type,source:'Manual',status:f.status||null,search:f.search||null,from_date:f.from_date||null,to_date:f.to_date||null,limit:state.limit,offset:state.page*state.limit};
            var summaryPayload={type:type,source:'Manual',status:f.status||null,search:f.search||null,from_date:f.from_date||null,to_date:f.to_date||null};
            var pair=await Promise.all([
                supabase.rpc('inventory_voucher_report',{p_operation:'LIST',p_payload:payload}),
                supabase.rpc('inventory_voucher_report',{p_operation:'SUMMARY',p_payload:summaryPayload})
            ]);
            if(pair[0].error) throw pair[0].error;
            if(pair[1].error) throw pair[1].error;
            var data=pair[0].data||{}, sum=pair[1].data||{};
            state.rows=Array.isArray(data.rows)?data.rows:[];
            state.total=Number(data.total||0);
            state.summary=(sum.summary&&Array.isArray(sum.summary.statuses))?sum.summary:{statuses:[]};
        } catch(e) {
            state.rows=[]; state.total=0;
            showToast(e.message||'تعذر تحميل سجل الأذونات','error');
        } finally {
            state.busy=false;
            render();
        }
    }

    function schedule() {
        clearTimeout(state.timer);
        state.page=0;
        state.timer=setTimeout(query,350);
    }

    root.oninput=function(e){if(e.target&&e.target.id==='rw-vr-search') schedule();};
    root.onchange=function(e){if(e.target&&['rw-vr-status','rw-vr-from','rw-vr-to'].indexOf(e.target.id)!==-1) schedule();};
    root.onclick=async function(e){
        var btn=e.target.closest&&e.target.closest('[data-rw-vr-action]');
        if(!btn) return;
        var action=btn.getAttribute('data-rw-vr-action');
        if(action==='refresh') return query();
        if(action==='prev'&&state.page>0){state.page--;return query();}
        if(action==='next'&&(state.page+1)*state.limit<state.total){state.page++;return query();}
        if(action==='details'){
            var code=decodeURIComponent(btn.getAttribute('data-rw-vr-code')||'');
            return showAudit(code);
        }
    };
    render();
    await query();
}
```

## لا تعدل
- لا تعدل main.html إلا بهذين البلوكين.
- لا تعدل Router أو Permission Map.
- لا تعدل loadVouchers() الموحد.
- لا تعدل _loadVoucherEntityOptions() أو _renderVoucherCart() أو _saveAndSendVoucher().
- لا تنشئ Edge Function جديدة.

## النتيجة
- كل route من الأنواع الأربعة يعرض Form الحالي كما هو، وتحتَه سجل تاريخي لنفس النوع.
- التقرير يعتمد على inventory_voucher_report في Production.
- البحث Server-side، مع status/date filtering وpagination.
- زر الرقابة يفتح Voucher details + Physical movements + Audit history.

END PATCH