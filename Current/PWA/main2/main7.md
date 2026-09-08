// ============================================================
// RW_Warehouse – العمليات المخزنية المتكاملة (Supabase مباشر)
// ============================================================
var RW_Warehouse = (function() {
    function esc(s) { return String(s||'').replace(/[&<>]/g, function(m) { return m==='&'?'&amp;':m==='<'?'&lt;':'&gt;'; }); }

    // ==================== RECEIVING (سجل الاستلام) ====================
    async function loadReceiving() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'الاستلام (Receiving)');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">
                <input type="text" id="rec-filter-id" placeholder="رقم العملية..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReceiving()">
                <input type="text" id="rec-filter-po" placeholder="رقم أمر الشراء..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReceiving()">
                <input type="text" id="rec-filter-resp" placeholder="المسؤول..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReceiving()">
                <input type="date" id="rec-filter-date-from" class="p-2 bg-slate-50 rounded text-sm" onchange="RW_Warehouse._applyReceiving()">
                <input type="date" id="rec-filter-date-to" class="p-2 bg-slate-50 rounded text-sm" onchange="RW_Warehouse._applyReceiving()">
                <button onclick="RW_Warehouse._applyReceiving()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>
            </div></div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">رقم العملية</th><th class="p-3">التاريخ</th><th class="p-3">أمر الشراء</th><th class="p-3">المسؤول</th><th class="p-3">الأصناف</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th></tr></thead><tbody id="rec-table"><tr><td colspan="7" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('receiving').select('*').eq('company_id', companyId).order('date', { ascending: false });
        window._receivingData = res.data || [];
        _applyReceiving();
    }
    function _applyReceiving() {
        var d = window._receivingData || [];
        var id = (byId('rec-filter-id')?.value||'').toLowerCase();
        var po = (byId('rec-filter-po')?.value||'').toLowerCase();
        var resp = (byId('rec-filter-resp')?.value||'').toLowerCase();
        var fd = byId('rec-filter-date-from')?.value;
        var td = byId('rec-filter-date-to')?.value;
        if (id) d = d.filter(r => (r.operation_id||'').toLowerCase().indexOf(id) !== -1);
        if (po) d = d.filter(r => (r.po_number||'').toLowerCase().indexOf(po) !== -1);
        if (resp) d = d.filter(r => (r.responsible||'').toLowerCase().indexOf(resp) !== -1);
        if (fd) d = d.filter(r => r.date >= fd);
        if (td) d = d.filter(r => r.date <= td);
        var tb = byId('rec-table'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="7" class="text-center py-8">لا توجد عمليات استلام</td></tr>'); return; }
        var h = '';
        d.forEach(op => {
            h += `<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showReceivingDetails('${op.operation_id}')">
                <td class="p-3 font-bold text-blue-600">${op.operation_id||''}</td>
                <td class="p-3">${op.date||''}</td>
                <td class="p-3">${op.po_number||'---'}</td>
                <td class="p-3">${op.responsible||'---'}</td>
                <td class="p-3 text-center">${op.itemsCount||0}</td>
                <td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-700">${op.status||'مكتمل'}</span></td>
                <td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td>
            </tr>`;
        });
        safeHTML(tb, h);
    }
async function _showReceivingDetails(opId) {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    showLoader('جاري التحميل...');
    var opRes = await supabase.from('receiving')
        .select('operation_id')
        .eq('company_id', companyId)
        .eq('operation_id', opId)
        .maybeSingle();

    if (opRes.error || !opRes.data) {
        hideLoader();
        showToast('عملية الاستلام غير موجودة في الشركة الحالية', 'error');
        return;
    }

    var detRes = await supabase.from('receiving_details')
        .select('*')
        .eq('operation_id', opRes.data.operation_id);

    hideLoader();

    var details = detRes.data || [];
    if (!details.length) {
        showToast('لا توجد تفاصيل', 'info');
        return;
    }

    var h = '<div class="text-right"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr>' +
        '<th class="p-2">الكود</th>' +
        '<th class="p-2">الصنف</th>' +
        '<th class="p-2 text-center">الوحدة</th>' +
        '<th class="p-2 text-center">المطلوب</th>' +
        '<th class="p-2 text-center">الفعلي</th>' +
        '<th class="p-2 text-center">الفرق</th>' +
        '<th class="p-2">السبب</th>' +
        '</tr></thead><tbody>';

    details.forEach(function(d) {
        h += '<tr>' +
            '<td class="p-2 border">' + esc(d.item_code || '') + '</td>' +
            '<td class="p-2 border font-semibold">' + esc(d.item_name || '') + '</td>' +
            '<td class="p-2 border text-center">' + esc(d.unit || '') + '</td>' +
            '<td class="p-2 border text-center">' + (d.qty_expected || 0) + '</td>' +
            '<td class="p-2 border text-center font-bold">' + (d.qty_received || 0) + '</td>' +
            '<td class="p-2 border text-center">' + (d.difference || 0) + '</td>' +
            '<td class="p-2 border">' + esc(d.reason || '') + '</td>' +
            '</tr>';
    });

    h += '</tbody></table></div>';

    Swal.fire({
        title: 'تفاصيل الاستلام: ' + esc(opRes.data.operation_id),
        html: h,
        width: '800px',
        showCloseButton: true,
        showConfirmButton: false
    });
}

    // ==================== VOUCHER FORM – نماذج الأذونات الأربعة ====================
    var voucherCart = [];
    var currentVoucherType = '';
    var currentVoucherConfig = {};

    function loadVoucherForm(type) {
        voucherCart = [];
        currentVoucherType = type;
        var configs = {            'Transfer':      { title: 'تحويل مخزني', entityLabel: 'الفرع المحول إليه', showPrice: false, fromType: 'Branch', fromId: null, toType: 'Branch', toId: null, endpoint: 'save-voucher' },
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
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-xl font-bold"><i class="fa-solid fa-file-signature ml-2 text-indigo-600"></i>${cfg.title}</h2>
                    <button onclick="RW_Warehouse.loadVouchers()" class="text-gray-500 hover:text-gray-700"><i class="fa-solid fa-xmark text-xl"></i></button>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
    <div>
        <label class="block text-sm font-bold mb-1">${cfg.entityLabel}</label>
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
        </div>`);

        _loadVoucherEntityOptions(type);
        _renderVoucherCart();
    }

async function _loadVoucherEntityOptions(type) {
    var select = byId('voucherEntitySelect');
    if (!select) return;

    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) {
        showToast('سياق الشركة غير محدد', 'error');
        return;
    }

    if (type === 'Transfer') {
        var branchRes = await supabase.from('branches')
            .select('id, branch_code, name, branch_name')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name');
        if (branchRes.error) { showToast(branchRes.error.message, 'error'); return; }

        var branchHtml = '<option value="">-- اختر فرعاً --</option>';
        var branches = branchRes.data || [];
        for (var i = 0; i < branches.length; i++) {
            branchHtml += '<option value="' + branches[i].id + '">' + (branches[i].name || branches[i].branch_name || branches[i].branch_code || '') + '</option>';
        }
        safeHTML(select, branchHtml);
        return;
    }

    if (type === 'SupplierReturn') {
        var supplierRes = await supabase.from('suppliers')
            .select('id, supplier_code, name')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name');
        if (supplierRes.error) { showToast(supplierRes.error.message, 'error'); return; }

        var supplierHtml = '<option value="">-- اختر مورداً --</option>';
        var suppliers = supplierRes.data || [];
        for (var s = 0; s < suppliers.length; s++) {
            supplierHtml += '<option value="' + suppliers[s].id + '">' + (suppliers[s].name || suppliers[s].supplier_code || '') + '</option>';
        }
        safeHTML(select, supplierHtml);
        return;
    }

    var driverRoles = type === 'DirectSale'
        ? ['مندوب بيع مباشر']
        : ['driver', 'سائق', 'مندوب', 'مندوب بيع مباشر'];

    var usersRes = await supabase.from('users')
        .select('id, email, name, role')
        .eq('company_id', companyId)
        .in('role', driverRoles)
        .eq('status', 'Active');
    if (usersRes.error) { showToast(usersRes.error.message, 'error'); return; }

    var drivers = usersRes.data || [];
    var driverIds = drivers.map(function(d) { return d.id; });
    if (!driverIds.length) {
        safeHTML(select, '<option value="">-- لا توجد سيارات متاحة --</option>');
        return;
    }

    var vehicleRes = await supabase.from('vehicles')
        .select('id, vehicle_code, license_plate, driver_id')
        .eq('company_id', companyId)
        .eq('status', 'Active')
        .in('driver_id', driverIds)
        .order('vehicle_code');
    if (vehicleRes.error) { showToast(vehicleRes.error.message, 'error'); return; }

    var driverMap = {};
    for (var d = 0; d < drivers.length; d++) driverMap[drivers[d].id] = drivers[d];

    var vehicleHtml = '<option value="">-- اختر سيارة --</option>';
    var vehicles = vehicleRes.data || [];
    for (var v = 0; v < vehicles.length; v++) {
        var vehicle = vehicles[v];
        var driver = driverMap[vehicle.driver_id] || {};
        var label = (driver.name || driver.email || '') + ' — ' + (vehicle.vehicle_code || vehicle.license_plate || vehicle.id);
        vehicleHtml += '<option value="' + vehicle.id + '">' + label + '</option>';
    }
    safeHTML(select, vehicleHtml);
}

    function _searchVoucherItem(query) {
        var div = byId('voucherSearchResults');
        if (!div) return;
        if (!query || query.trim().length < 1) { div.classList.add('hidden'); return; }
        var items = RW_STATE.data.items || [];
        var q = query.toLowerCase();
        var filtered = items.filter(function(i) { return (i.name || '').toLowerCase().indexOf(q) !== -1 || (i.item_code || '').toLowerCase().indexOf(q) !== -1; });
        if (filtered.length > 0) {
            var html = '';
            for (var idx = 0; idx < Math.min(filtered.length, 20); idx++) {
                var item = filtered[idx];
                html += '<div onclick="RW_Warehouse._addVoucherItem(\'' + item.item_code + '\')" class="p-3 hover:bg-indigo-50 cursor-pointer flex justify-between border-b"><div><div class="font-bold">' + item.name + '</div><div class="text-xs text-gray-400">' + item.item_code + '</div></div><div class="font-bold text-indigo-600">' + (item.qty || 0) + ' ' + (item.unit || '') + '</div></div>';
            }
            safeHTML(div, html); div.classList.remove('hidden');
        } else { div.classList.add('hidden'); }
    }

    function _addVoucherItem(itemCode) {
        var items = RW_STATE.data.items || [];
        var item = null;
        for (var i = 0; i < items.length; i++) { if (items[i].item_code === itemCode) { item = items[i]; break; } }
        if (!item) return;
        var existing = null;
        for (var j = 0; j < voucherCart.length; j++) { if (voucherCart[j].code === itemCode) { existing = voucherCart[j]; break; } }
        if (existing) { existing.qty++; } else {
            voucherCart.push({ code: item.item_code, name: item.name, unit: item.unit || 'حبة', qty: 1, price: currentVoucherConfig.showPrice ? (Number(item.sales_price) || 0) : 0 });
        }
        byId('voucherItemSearch').value = '';
        byId('voucherSearchResults').classList.add('hidden');
        _renderVoucherCart();
    }

    function _renderVoucherCart() {
        var tbody = byId('voucherItemsTable');
        var countSpan = byId('voucherTotalItems');
        if (voucherCart.length === 0) { safeHTML(tbody, '<div class="text-center py-8 text-gray-400">أضف أصنافاً</div>'); if (countSpan) countSpan.innerText = '0'; return; }
        var html = '<table class="w-full text-right border"><thead class="bg-gray-100 text-xs uppercase"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th>';
        if (currentVoucherConfig.showPrice) html += '<th class="p-2 text-center">السعر</th>';
        html += '<th class="p-2 text-center">حذف</th></tr></thead><tbody>';
        for (var i = 0; i < voucherCart.length; i++) {
            var item = voucherCart[i];
            html += '<tr class="border-b"><td class="p-2"><div class="font-bold">' + item.name + '</div><div class="text-xs text-gray-400">' + item.code + '</div></td><td class="p-2 text-center"><input type="number" value="' + item.qty + '" onchange="RW_Warehouse._updateVoucherQty(' + i + ', this.value)" class="w-16 p-1 border rounded text-center" min="1"></td>';
            if (currentVoucherConfig.showPrice) html += '<td class="p-2 text-center"><input type="number" value="' + item.price + '" onchange="RW_Warehouse._updateVoucherPrice(' + i + ', this.value)" class="w-20 p-1 border rounded text-center" step="0.01" min="0"></td>';
            html += '<td class="p-2 text-center"><button onclick="RW_Warehouse._removeVoucherItem(' + i + ')" class="text-red-500"><i class="fa-solid fa-trash"></i></button></td></tr>';
        }
        html += '</tbody></table>';
        safeHTML(tbody, html);
        if (countSpan) countSpan.innerText = String(voucherCart.length);
    }

    function _updateVoucherQty(idx, val) { var q = parseInt(val); if (q > 0) voucherCart[idx].qty = q; else voucherCart.splice(idx, 1); _renderVoucherCart(); }
    function _updateVoucherPrice(idx, val) { voucherCart[idx].price = parseFloat(val) || 0; _renderVoucherCart(); }
    function _removeVoucherItem(idx) { voucherCart.splice(idx, 1); _renderVoucherCart(); }
    function _clearVoucherCart() { voucherCart = []; _renderVoucherCart(); }

async function _saveAndSendVoucher() {
    if (voucherCart.length === 0) { showToast('أضف أصنافاً للإذن', 'warning'); return; }

    var entity = byId('voucherEntitySelect') ? byId('voucherEntitySelect').value : '';
    if (!entity) { showToast('يرجى اختيار ' + currentVoucherConfig.entityLabel, 'warning'); return; }

    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }

    var notes = byId('voucherNotesLarge') ? byId('voucherNotesLarge').value : '';
    var reference = byId('voucherReference') ? byId('voucherReference').value.trim() : '';
    if (!reference) { showToast('مرجع الإذن مطلوب', 'warning'); return; }

    var settingsRes = await supabase.from('app_settings')
        .select('main_branch_id')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();
    if (settingsRes.error) { showToast(settingsRes.error.message, 'error'); return; }

    var mainBranchId = settingsRes.data ? settingsRes.data.main_branch_id : null;
    if (!mainBranchId) { showToast('الفرع الرئيسي غير محدد', 'error'); return; }

    var fromId = null;
    var toId = null;
    var repId = null;

    if (currentVoucherType === 'Transfer') {
        fromId = mainBranchId;
        toId = entity;
    } else if (currentVoucherType === 'DirectSale') {
        fromId = mainBranchId;
        toId = entity;

        var directSaleVehicleRes = await supabase.from('vehicles')
            .select('id, driver_id')
            .eq('company_id', companyId)
            .eq('id', entity)
            .eq('status', 'Active')
            .maybeSingle();
        if (directSaleVehicleRes.error) { showToast(directSaleVehicleRes.error.message, 'error'); return; }
        if (!directSaleVehicleRes.data || !directSaleVehicleRes.data.driver_id) {
            showToast('المركبة المختارة لا ترتبط بمندوب بيع مباشر', 'error');
            return;
        }
        repId = directSaleVehicleRes.data.driver_id;
    } else if (currentVoucherType === 'DirectReturn') {
        fromId = entity;
        toId = mainBranchId;
    } else if (currentVoucherType === 'SupplierReturn') {
        fromId = mainBranchId;
        toId = entity;
    } else {
        showToast('نوع الإذن غير مدعوم', 'error');
        return;
    }

    var items = [];
    for (var i = 0; i < voucherCart.length; i++) {
        items.push({
            itemCode: voucherCart[i].code,
            qty: voucherCart[i].qty,
            unitPrice: voucherCart[i].price || 0,
            notes: ''
        });
    }

    showLoader('جاري حفظ وإرسال الإذن...');
    var ses = await supabase.auth.getSession();
    var token = ses.data.session ? ses.data.session.access_token : null;
    if (!token) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }

    try {
        var createBody = {
            type: currentVoucherType,
            reference: reference,
            fromType: currentVoucherType === 'DirectReturn' ? 'Vehicle' : 'Branch',
            fromId: fromId,
            toType: currentVoucherType === 'DirectSale' || currentVoucherType === 'DirectReturn' ? (currentVoucherType === 'DirectSale' ? 'Vehicle' : 'Branch') : (currentVoucherType === 'SupplierReturn' ? 'Supplier' : 'Branch'),
            toId: toId,
            items: items,
            notes: notes,
            rep_id: repId
        };

        var createRes = await fetch(RW_SUPABASE_URL + '/functions/v1/create-stock-voucher', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify(createBody)
        });

        var createJson = await createRes.json();
        if (!createJson.success) {
            hideLoader();
            showToast(createJson.msg || 'فشل الحفظ', 'error');
            return;
        }

        var sendRes = await fetch(RW_SUPABASE_URL + '/functions/v1/send-stock-voucher', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify({ voucher_code: createJson.voucherId })
        });

        var sendJson = await sendRes.json();
        hideLoader();

        if (sendJson.success) {
            showToast('تم إنشاء وإرسال الإذن ' + createJson.voucherId, 'success');
            voucherCart = [];
            _renderVoucherCart();
        } else {
            showToast(sendJson.msg || 'فشل الإرسال', 'error');
        }
    } catch (e) {
        hideLoader();
        showToast(e.message || 'فشل الاتصال', 'error');
    }
}

    // ==================== VOUCHERS LIST – عرض الأذونات مع فصل ====================
    async function loadVouchers() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'الأذونات المخزنية');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4">
                <div class="flex flex-wrap items-center gap-2 mb-3">
                    <select id="v-filter-type" onchange="RW_Warehouse._applyVouchers()" class="p-2 bg-white border rounded-lg text-sm"><option value="">كل الأنواع</option><option value="Transfer">تحويل</option><option value="DirectSale">صرف مباشر</option><option value="DirectReturn">مرتجع مباشر</option><option value="SupplierReturn">مرتجع لمورد</option><option value="Picking">تحضير</option><option value="Loading">تحميل</option><option value="Return">مرتجع</option><option value="Unloading">تفريغ</option><option value="Adjustment">جرد</option></select>
                    <select id="v-filter-status" onchange="RW_Warehouse._applyVouchers()" class="p-2 bg-white border rounded-lg text-sm"><option value="">كل الحالات</option><option value="Draft">مسودة</option><option value="Sent">مُرسل</option><option value="Received">مُستلم</option><option value="Completed">مكتمل</option></select>
                    <input type="date" id="v-filter-from" onchange="RW_Warehouse._applyVouchers()" class="p-2 bg-white border rounded-lg text-sm">
                    <input type="date" id="v-filter-to" onchange="RW_Warehouse._applyVouchers()" class="p-2 bg-white border rounded-lg text-sm">
                    <input type="text" id="v-search" oninput="RW_Warehouse._applyVouchers()" placeholder="بحث برقم الإذن..." class="p-2 bg-white border rounded-lg text-sm w-40">
                    <button onclick="RW_Warehouse._openNewVoucherModal()" class="bg-indigo-600 text-white px-4 py-2 rounded-xl font-bold text-sm"><i class="fa-solid fa-plus ml-1"></i> إذن جديد</button>
                    <label class="flex items-center gap-2 ml-3 text-sm"><input type="checkbox" id="v-show-all" onchange="RW_Warehouse._applyVouchers()"> <span class="font-bold">إظهار الكل (يشمل التلقائية)</span></label>
                </div>
            </div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh" id="vouchers-table-container">
                <table class="w-full"><thead class="bg-gray-800 text-white sticky top-0"><tr><th class="p-3">رقم الإذن</th><th class="p-3">النوع</th><th class="p-3">التاريخ</th><th class="p-3">الحالة</th><th class="p-3">المرجع</th><th class="p-3">من</th><th class="p-3">إلى</th><th class="p-3 text-center">إجراءات</th></tr></thead><tbody id="vouchers-tbody"><tr><td colspan="8" class="text-center py-8">جاري التحميل...</td></tr></tbody></table>
            </div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('stock_vouchers').select('*').eq('company_id', companyId).order('voucher_date', { ascending: false });
        window._vouchersData = res.data || [];
        _applyVouchers();
    }

    function _applyVouchers() {
        var d = window._vouchersData || [];
        var type = byId('v-filter-type') ? byId('v-filter-type').value : '';
        var status = byId('v-filter-status') ? byId('v-filter-status').value : '';
        var from = byId('v-filter-from') ? byId('v-filter-from').value : '';
        var to = byId('v-filter-to') ? byId('v-filter-to').value : '';
        var search = (byId('v-search') ? byId('v-search').value : '').toLowerCase();
        var showAll = byId('v-show-all') ? byId('v-show-all').checked : false;
        
        if (!showAll) {
            d = d.filter(function(v) { return v.source === 'Manual' || (v.source !== 'Manual' && v.type === 'Adjustment'); });
        }
        if (type) d = d.filter(function(v) { return v.type === type; });
        if (status) d = d.filter(function(v) { return v.status === status; });
        if (from) d = d.filter(function(v) { return v.voucher_date >= from; });
        if (to) d = d.filter(function(v) { return v.voucher_date <= to; });
        if (search) d = d.filter(function(v) { return (v.voucher_code||'').toLowerCase().indexOf(search) !== -1; });
        var tb = byId('vouchers-tbody'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="8" class="text-center py-8">لا توجد أذونات</td></tr>'); return; }
        RW_Table.paginate('vouchers-tbody', d, 1, 50, function(v) {
            var statusBadge = { 'Draft':'bg-gray-100 text-gray-600', 'Sent':'bg-blue-100 text-blue-700', 'Received':'bg-purple-100 text-purple-700', 'Completed':'bg-green-100 text-green-700' }[v.status] || 'bg-gray-100 text-gray-700';
            var isSystem = (v.source === 'Auto' || ['Picking','Loading','Return','Unloading'].indexOf(v.type) !== -1);
            var actions = '<button onclick="RW_Warehouse._viewVoucherDetails(\'' + v.voucher_code + '\')" class="text-blue-600 mx-1"><i class="fa-solid fa-eye"></i></button>';
            if (v.status === 'Draft' && !isSystem) actions += '<button onclick="RW_Warehouse._sendVoucher(\'' + v.voucher_code + '\')" class="text-blue-600 mx-1"><i class="fa-solid fa-paper-plane"></i></button>';
            if (v.status === 'Sent') actions += '<button onclick="RW_Warehouse._receiveVoucher(\'' + v.voucher_code + '\')" class="text-green-600 mx-1"><i class="fa-solid fa-check-circle"></i></button>';
            var sourceIndicator = isSystem ? ' <i class="fa-solid fa-robot text-gray-400 text-xs" title="تلقائي"></i>' : '';
            return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
        });
    }

async function _viewVoucherDetails(voucherCode) {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }

    showLoader('جاري التحميل...');

    var voucherRes = await supabase.from('stock_vouchers')
        .select('id,voucher_code')
        .eq('company_id', companyId)
        .eq('voucher_code', voucherCode)
        .maybeSingle();

    if (voucherRes.error || !voucherRes.data) {
        hideLoader();
        showToast('الإذن غير موجود في الشركة الحالية', 'error');
        return;
    }

    var detRes = await supabase.from('stock_voucher_details')
        .select('*')
        .eq('voucher_id', voucherRes.data.id)
        .order('item_code');

    hideLoader();

    var details = detRes.data || [];
    if (!details.length) {
        showToast('لا توجد تفاصيل', 'info');
        return;
    }

    var h = '<table class="w-full border text-sm"><thead class="bg-gray-100"><tr>' +
        '<th class="p-2">الكود</th>' +
        '<th class="p-2">الصنف</th>' +
        '<th class="p-2 text-center">الكمية</th>' +
        '<th class="p-2 text-center">المستلمة</th>' +
        '</tr></thead><tbody>';

    details.forEach(function(d) {
        h += '<tr>' +
            '<td class="p-2 border">' + esc(d.item_code || '') + '</td>' +
            '<td class="p-2 border font-semibold">' + esc(d.item_name || '') + '</td>' +
            '<td class="p-2 border text-center">' + (d.qty || 0) + '</td>' +
            '<td class="p-2 border text-center">' + (d.received_qty || 0) + '</td>' +
            '</tr>';
    });

    h += '</tbody></table>';

    Swal.fire({
        title: 'تفاصيل الإذن: ' + esc(voucherRes.data.voucher_code),
        html: h,
        width: '600px',
        showCloseButton: true,
        showConfirmButton: false
    });
}

    async function _sendVoucher(voucherCode) {
        var confirm = await Swal.fire({ title: 'تأكيد الإرسال', text: 'سيتم إرسال الإذن ' + voucherCode + ' وخصم المخزون من المصدر. متابعة؟', icon: 'warning', showCancelButton: true, confirmButtonColor: '#2563eb', confirmButtonText: 'نعم، أرسل', cancelButtonText: 'إلغاء' });
        if (!confirm.isConfirmed) return;
        showLoader('جاري إرسال الإذن...');
        var ses = await supabase.auth.getSession(), token = ses.data.session ? ses.data.session.access_token : null;
        try {
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/send-stock-voucher', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ voucher_code: voucherCode }) });
            var json = await res.json(); hideLoader();
            if (json.success) { showToast('تم إرسال الإذن بنجاح', 'success'); loadVouchers(); }
            else showToast(json.error || json.msg || 'فشل الإرسال', 'error');
        } catch(e) { hideLoader(); showToast('فشل الاتصال بـ Edge Function', 'error'); }
    }

async function _receiveVoucher(voucherCode) {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    showLoader('جاري تحميل تفاصيل الإذن...');
    var voucherRes = await supabase.from('stock_vouchers').select('id,status,voucher_code,to_id').eq('company_id', companyId).eq('voucher_code', voucherCode).maybeSingle();
    if (voucherRes.error || !voucherRes.data) { hideLoader(); showToast('الإذن غير موجود في الشركة الحالية', 'error'); return; }
    if (voucherRes.data.status !== 'Sent') { hideLoader(); showToast('الإذن غير جاهز للاستلام: ' + (voucherRes.data.status || ''), 'warning'); return; }
    var detRes = await supabase.from('stock_voucher_details').select('*').eq('voucher_id', voucherRes.data.id).order('item_code');
    var details = detRes.data || [];
    hideLoader();
    if (!details.length) { showToast('لا توجد تفاصيل لهذا الإذن', 'info'); return; }
    var html = '<div class="text-right"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2 border">الصنف</th><th class="p-2 border text-center">المرسل</th><th class="p-2 border text-center">المستلم سابقًا</th><th class="p-2 border text-center">المتبقي</th><th class="p-2 border text-center">استلام الآن</th></tr></thead><tbody>';
    for (var i = 0; i < details.length; i++) {
        var d = details[i];
        var totalQty = Number(d.qty || 0);
        var receivedBefore = Number(d.received_qty || 0);
        var remaining = Math.max(0, totalQty - receivedBefore);
        html += '<tr><td class="p-2 border font-semibold">' + esc(d.item_name || '') + ' (' + esc(d.item_code || '') + ')</td><td class="p-2 border text-center font-bold">' + totalQty + '</td><td class="p-2 border text-center">' + receivedBefore + '</td><td class="p-2 border text-center font-bold text-blue-700">' + remaining + '</td><td class="p-2 border text-center"><input type="number" id="vrec_qty_' + i + '" value="' + remaining + '" class="w-24 p-1 border rounded text-center" min="0" max="' + remaining + '" step="0.01"></td></tr>';
    }
    html += '</tbody></table></div>';
    var result = await Swal.fire({
        title: 'استلام الإذن: ' + esc(voucherCode),
        html: html,
        width: '850px',
        showCancelButton: true,
        confirmButtonText: 'تأكيد الاستلام',
        confirmButtonColor: '#10b981',
        cancelButtonText: 'إلغاء',
        preConfirm: function() {
            var items = [];
            var hasQty = false;
            for (var j = 0; j < details.length; j++) {
                var maxRemaining = Math.max(0, Number(details[j].qty || 0) - Number(details[j].received_qty || 0));
                var qty = parseFloat((document.getElementById('vrec_qty_' + j) || {}).value) || 0;
                if (qty < 0 || qty > maxRemaining) {
                    Swal.showValidationMessage('كمية الاستلام تتجاوز المتبقي للصنف: ' + (details[j].item_code || ''));
                    return false;
                }
                if (qty > 0) hasQty = true;
                items.push({ itemCode: details[j].item_code || '', itemName: details[j].item_name || '', unit: details[j].unit || 'حبة', receivedQty: qty });
            }
            if (!hasQty) { Swal.showValidationMessage('أدخل كمية واحدة على الأقل للاستلام'); return false; }
            return items;
        }
    });
    if (!result.isConfirmed) return;
    var positiveItems = (result.value || []).filter(function(x) { return Number(x.receivedQty || 0) > 0; }).sort(function(a,b) { return String(a.itemCode).localeCompare(String(b.itemCode)); });
    var operationId = 'UI-RECEIVE:' + companyId + ':' + voucherRes.data.id + ':' + positiveItems.map(function(x) { return String(x.itemCode) + ':' + Number(x.receivedQty); }).join('|');
    showLoader('جاري الاستلام...');
    var ses = await supabase.auth.getSession();
    var token = ses.data.session ? ses.data.session.access_token : null;
    if (!token) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }
    try {
        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/receive-stock-voucher', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token, 'Idempotency-Key': operationId },
            body: JSON.stringify({ voucher_code: voucherCode, receivedItems: positiveItems, operation_id: operationId })
        });
        var json = await res.json();
        hideLoader();
        if (json.success) { showToast(json.msg || (json.duplicate ? 'تم تأكيد العملية السابقة' : 'تم الاستلام'), 'success'); loadVouchers(); }
        else showToast(json.error || json.msg || 'فشل الاستلام', 'error');
    } catch (e) { hideLoader(); showToast('فشل الاتصال بـ Edge Function', 'error'); }
}

async function _openNewVoucherModal() {
    var typeOptions =
        '<option value="Transfer">تحويل داخلي</option>' +
        '<option value="DirectSale">صرف سيارة بيع مباشر</option>' +
        '<option value="DirectReturn">استلام مرتجع سيارة</option>' +
        '<option value="SupplierReturn">مرتجع لمورد</option>';

    var html =
        '<div class="text-right space-y-3">' +
            '<div>' +
                '<label class="text-xs font-bold">نوع الإذن</label>' +
                '<select id="newVoucherType" class="swal2-input w-full">' +
                    typeOptions +
                '</select>' +
            '</div>' +
        '</div>';

    var result = await Swal.fire({
        title: 'إنشاء إذن مخزني جديد',
        html: html,
        showCancelButton: true,
        confirmButtonText: 'متابعة',
        cancelButtonText: 'إلغاء',
        preConfirm: function() {
            var type = document.getElementById('newVoucherType').value;
            if (!type) {
                Swal.showValidationMessage('اختر نوع الإذن');
                return false;
            }
            return { type: type };
        }
    });

    if (!result.isConfirmed) return;

    loadVoucherForm(result.value.type);
}

    // ==================== PICKING ====================
    async function loadPicking() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'التحضير (Picking)');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">
                <input type="text" id="pk-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyPicking()">
                <select id="pk-f-st" class="p-2 bg-slate-50 rounded text-sm" onchange="RW_Warehouse._applyPicking()"><option value="">كل الحالات</option><option value="Open">Open</option>
<option value="Confirmed">Confirmed</option></select>
                <button onclick="RW_Warehouse._applyPicking()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>
            </div></div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">الرانشيت</th><th class="p-3">التاريخ</th><th class="p-3">السائق</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th></tr></thead><tbody id="pk-table"><tr><td colspan="5" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Open', 'Confirmed']);
        window._pickingData = res.data || [];
        _applyPicking();
    }
    function _applyPicking() {
        var d = window._pickingData || [];
        var id = (byId('pk-f-id')?.value||'').toLowerCase(), st = byId('pk-f-st')?.value;
        if (id) d = d.filter(function(r) { return (r.runsheet_code||'').toLowerCase().indexOf(id) !== -1; });
        if (st) d = d.filter(function(r) { return r.status === st; });
        var tb = byId('pk-table'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="5" class="text-center py-8">لا توجد رانشيتات محضّرة</td></tr>'); return; }
        RW_Table.paginate('pk-table', d, 1, 50, function(r) {
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showPickingDetails(\'' + r.runsheet_code + '\')"><td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-purple-100 text-purple-700">Picked</span></td><td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
        });
    }
    async function _showPickingDetails(code) {
        showLoader('جاري التحميل...');
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
        var itemsRes = await supabase.from('run_sheet_details').select('*').eq('runsheet_id', rsRes.data?.id);
        hideLoader();
        var items = itemsRes.data || [];
        if (!items.length) { showToast('لا توجد أصناف', 'info'); return; }
        var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المطلوبة</th><th class="p-2 text-center">الكمية المحضرة</th></tr></thead><tbody>';
        items.forEach(it => { h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_ordered||0) + '</td><td class="p-2 text-center font-bold text-purple-600">' + (it.qty_picked||0) + '</td></tr>'; });
        h += '</tbody></table></div>';
        Swal.fire({ title: 'تفاصيل التحضير: ' + code, html: h, width: '700px', showCloseButton: true, showConfirmButton: false });
    }

    // ==================== LOADING ====================
    async function loadLoading() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'التحميل (Loading)');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">
                <input type="text" id="ld-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyLoading()">
                <select id="ld-f-st" class="p-2 bg-slate-50 rounded text-sm" onchange="RW_Warehouse._applyLoading()"><option value="">كل الحالات</option><option>Loaded</option></select>
                <button onclick="RW_Warehouse._applyLoading()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>
            </div></div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">الرانشيت</th><th class="p-3">التاريخ</th><th class="p-3">السائق</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th></tr></thead><tbody id="ld-table"><tr><td colspan="5" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Loaded']);
        window._loadingData = res.data || [];
        _applyLoading();
    }
    function _applyLoading() {
        var d = window._loadingData || [];
        var id = (byId('ld-f-id')?.value||'').toLowerCase(), st = byId('ld-f-st')?.value;
        if (id) d = d.filter(function(r) { return (r.runsheet_code||'').toLowerCase().indexOf(id) !== -1; });
        if (st) d = d.filter(function(r) { return r.status === st; });
        var tb = byId('ld-table'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="5" class="text-center py-8">لا توجد رانشيتات محمّلة</td></tr>'); return; }
        RW_Table.paginate('ld-table', d, 1, 50, function(r) {
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showLoadingDetails(\'' + r.runsheet_code + '\')"><td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-orange-100 text-orange-700">Loaded</span></td><td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
        });
    }
    async function _showLoadingDetails(code) {
        showLoader('جاري التحميل...');

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) {
            hideLoader();
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        try {
            var rsRes = await supabase.from('runsheets')
                .select('id')
                .eq('company_id', companyId)
                .eq('runsheet_code', code)
                .maybeSingle();

            if (rsRes.error) throw rsRes.error;
            if (!rsRes.data) {
                hideLoader();
                showToast('الرانشيت غير موجود في الشركة الحالية', 'error');
                return;
            }

            var itemsRes = await supabase.from('run_sheet_details')
                .select('*')
                .eq('runsheet_id', rsRes.data.id);

            if (itemsRes.error) throw itemsRes.error;

            hideLoader();

            var items = itemsRes.data || [];
            if (!items.length) {
                showToast('لا توجد أصناف', 'info');
                return;
            }

            var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المحضّرة</th><th class="p-2 text-center">الكمية المحمّلة</th></tr></thead><tbody>';
            items.forEach(it => {
                h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_picked||0) + '</td><td class="p-2 text-center font-bold text-orange-600">' + (it.qty_loaded||0) + '</td></tr>';
            });
            h += '</tbody></table></div>';

            Swal.fire({
                title: 'تفاصيل التحميل: ' + code,
                html: h,
                width: '700px',
                showCloseButton: true,
                showConfirmButton: false
            });
        } catch (e) {
            hideLoader();
            showToast('فشل تحميل تفاصيل التحميل: ' + (e.message || ''), 'error');
        }
    }

    // ==================== DELIVERY ====================
    async function loadDelivery() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'التوصيل (Delivery)');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">
                <input type="text" id="dv-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyDelivery()">
                <button onclick="RW_Warehouse._applyDelivery()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>
            </div></div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">الرانشيت</th><th class="p-3">التاريخ</th><th class="p-3">السائق</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th></tr></thead><tbody id="dv-table"><tr><td colspan="5" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Delivered']);
        window._deliveryData = res.data || [];
        _applyDelivery();
    }
    function _applyDelivery() {
        var d = window._deliveryData || [];
        var id = (byId('dv-f-id')?.value||'').toLowerCase();
        if (id) d = d.filter(function(r) { return (r.runsheet_code||'').toLowerCase().indexOf(id) !== -1; });
        var tb = byId('dv-table'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="5" class="text-center py-8">لا توجد رانشيتات موصّلة</td></tr>'); return; }
        RW_Table.paginate('dv-table', d, 1, 50, function(r) {
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showDeliveryDetails(\'' + r.runsheet_code + '\')"><td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-700">Delivered</span></td><td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
        });
    }
    async function _showDeliveryDetails(code) {
        showLoader('جاري التحميل...');
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
        var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
        var itemsRes = await supabase.from('run_sheet_details').select('*').eq('runsheet_id', rsRes.data?.id);
        hideLoader();
        var items = itemsRes.data || [];
        if (!items.length) { showToast('لا توجد أصناف', 'info'); return; }
        var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المحمّلة</th><th class="p-2 text-center">الكمية المسلّمة</th></tr></thead><tbody>';
        items.forEach(it => { h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_loaded||0) + '</td><td class="p-2 text-center font-bold text-green-600">' + (it.qty_delivered||0) + '</td></tr>'; });
        h += '</tbody></table></div>';
        Swal.fire({ title: 'تفاصيل التوصيل: ' + code, html: h, width: '700px', showCloseButton: true, showConfirmButton: false });
    }

    // ==================== RETURN ====================
    async function loadReturn() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'المرتجعات (Return)');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">
                <input type="text" id="rt-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReturn()">
                <button onclick="RW_Warehouse._applyReturn()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>
            </div></div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">الرانشيت</th><th class="p-3">التاريخ</th><th class="p-3">السائق</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th></tr></thead><tbody id="rt-table"><tr><td colspan="5" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Returned']);
        window._returnData = res.data || [];
        _applyReturn();
    }
    function _applyReturn() {
        var d = window._returnData || [];
        var id = (byId('rt-f-id')?.value||'').toLowerCase();
        if (id) d = d.filter(function(r) { return (r.runsheet_code||'').toLowerCase().indexOf(id) !== -1; });
        var tb = byId('rt-table'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="5" class="text-center py-8">لا توجد رانشيتات مرتجعة</td></tr>'); return; }
        RW_Table.paginate('rt-table', d, 1, 50, function(r) {
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showReturnDetails(\'' + r.runsheet_code + '\')"><td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">Returned</span></td><td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
        });
    }
    async function _showReturnDetails(code) {
        showLoader('جاري التحميل...');
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
        var itemsRes = await supabase.from('run_sheet_details').select('*').eq('runsheet_id', rsRes.data?.id);
        hideLoader();
        var items = itemsRes.data || [];
        if (!items.length) { showToast('لا توجد أصناف', 'info'); return; }
        var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المسلّمة</th><th class="p-2 text-center">الكمية المرتجعة</th></tr></thead><tbody>';
        items.forEach(it => { h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + (it.qty_delivered||0) + '</td><td class="p-2 text-center font-bold text-rose-600">' + (it.qty_returned||0) + '</td></tr>'; });
        h += '</tbody></table></div>';
        Swal.fire({ title: 'تفاصيل المرتجعات: ' + code, html: h, width: '700px', showCloseButton: true, showConfirmButton: false });
    }

    // ==================== UNLOADING ====================
    async function loadUnloading() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'التفريغ (Unloading)');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">
                <input type="text" id="ul-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyUnloading()">
                <button onclick="RW_Warehouse._applyUnloading()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>
            </div></div>
            <div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr><th class="p-3">الرانشيت</th><th class="p-3">التاريخ</th><th class="p-3">السائق</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th></tr></thead><tbody id="ul-table"><tr><td colspan="5" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>
        </div>`);
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Open','New']);
        window._unloadingData = res.data || [];
        _applyUnloading();
    }
    function _applyUnloading() {
        var d = window._unloadingData || [];
        var id = (byId('ul-f-id')?.value||'').toLowerCase();
        if (id) d = d.filter(function(r) { return (r.runsheet_code||'').toLowerCase().indexOf(id) !== -1; });
        var tb = byId('ul-table'); if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="5" class="text-center py-8">لا توجد رانشيتات مفرّغة</td></tr>'); return; }
        RW_Table.paginate('ul-table', d, 1, 50, function(r) {
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showUnloadingDetails(\'' + r.runsheet_code + '\')"><td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-gray-100 text-gray-700">' + (r.status||'') + '</span></td><td class="p-3 text-center"><button class="text-blue-600" onclick="RW_Warehouse._showUnloadingDetails(\'' + r.runsheet_code + '\')"><i class="fa-solid fa-eye"></i></button></td></tr>';
        });
    }
    async function _showUnloadingDetails(code) { showToast('التفاصيل قيد التطوير', 'info'); }

    // ==================== COUNT (الجرد) & SETTLEMENT (إغلاق اليومية) ====================
    async function loadVehicleCount() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'جرد سيارة');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4 grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="text-xs font-bold block mb-1">المندوب</label>
                    <input type="text" id="vc-driver-search" oninput="RW_Warehouse._searchDriver(this.value)" autocomplete="off" placeholder="ابحث باسم أو بريد المندوب..." class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200 focus:border-blue-500 outline-none">
                    <div id="vc-driver-results" class="absolute z-50 bg-white shadow-xl rounded-xl max-h-48 overflow-y-auto hidden border mt-1" style="width:calc(33%-2rem);"></div>
                </div>
                <div>
                    <label class="text-xs font-bold block mb-1">الرانشيت (اختياري)</label>
                    <select id="vc-runsheet-select" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200 font-bold"><option value="">-- اختر --</option></select>
                </div>
                <div>
                    <label class="text-xs font-bold block mb-1">ملاحظات</label>
                    <input id="vc-notes" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200" placeholder="ملاحظات...">
                </div>
            </div>
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4 relative">
                <label class="text-xs font-bold block mb-2">البحث عن صنف</label>
                <div class="relative">
                    <input type="text" id="vc-item-search" oninput="RW_Warehouse._searchInvItem('vc', this.value)" autocomplete="off" placeholder="امسح الباركود أو ابحث..." class="w-full p-4 bg-slate-50 rounded-xl border-2 focus:border-emerald-500 outline-none font-bold text-lg">
                    <button onclick="RW_Warehouse._startBarcodeScanner('vc')" class="absolute left-2 top-2 bg-emerald-600 text-white p-3 rounded-xl"><i class="fa-solid fa-camera"></i></button>
                </div>
                <div id="vc-item-results" class="absolute z-50 left-0 right-0 mt-1 bg-white shadow-xl rounded-xl max-h-60 overflow-y-auto hidden border"></div>
            </div>
            <div class="bg-white rounded-xl shadow-sm overflow-auto" style="max-height:50vh;">
                <table class="w-full"><thead class="bg-slate-800 text-white"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">حذف</th></tr></thead><tbody id="vc-cart-table"><tr><td colspan="4" class="p-6 text-center">أضف أصنافاً</td></tr></tbody></table>
            </div>
            <div class="mt-2">عدد الأصناف: <span id="vc-cart-count">0</span></div>
            <div class="mt-4 flex justify-end gap-3">
                <button onclick="window._invCart=[]; RW_Warehouse._renderInvCart('vc')" class="bg-gray-500 text-white px-4 py-2 rounded-xl font-bold text-sm">مسح الكل</button>
                <button onclick="RW_Warehouse._saveVehicleCount()" class="bg-blue-600 text-white px-8 py-3 rounded-2xl font-black text-lg shadow-lg"><i class="fa-solid fa-check ml-2"></i> حفظ الجرد</button>
            </div>
        </div>`);
        
        window._selectedDriver = null;
        window._invCart = [];
        _renderInvCart('vc');
        
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Loaded', 'Delivering', 'Delivered', 'Returning']);
        var sel = byId('vc-runsheet-select');
        if (sel && runsheetsRes.data) {
            for (var i = 0; i < runsheetsRes.data.length; i++) {
                var r = runsheetsRes.data[i];
                sel.innerHTML += '<option value="' + r.runsheet_code + '">' + r.runsheet_code + ' - ' + (r.driver_id || '') + '</option>';
            }
        }
    }

    async function _searchDriver(query) {
        var div = byId('vc-driver-results'); if (!div) return;
        if (!query || query.trim().length < 1) { div.classList.add('hidden'); return; }
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { div.classList.add('hidden'); return; }
var res = await supabase.from('users')
    .select('email, name')
    .eq('company_id', companyId)
    .in('role', ['driver','سائق','مندوب'])
    .ilike('name', '%' + query + '%');
        var drivers = res.data || [];
        var q = query.toLowerCase();
        var filtered = drivers.filter(function(d) { return (d.name || '').toLowerCase().indexOf(q) !== -1 || (d.email || '').toLowerCase().indexOf(q) !== -1; });
        if (filtered.length > 0) {
            var html = '';
            for (var i = 0; i < filtered.length; i++) {
                var d = filtered[i];
                html += '<div onclick="RW_Warehouse._selectDriver(\'' + d.email + '\', \'' + (d.name || '').replace(/'/g, "\\'") + '\')" class="p-3 hover:bg-blue-50 cursor-pointer border-b"><div class="font-bold">' + d.name + '</div><div class="text-xs text-slate-400">' + d.email + '</div></div>';
            }
            safeHTML(div, html); div.classList.remove('hidden');
        } else { div.classList.add('hidden'); }
    }

    function _selectDriver(email, name) {
        window._selectedDriver = email;
        byId('vc-driver-search').value = name + ' (' + email + ')';
        byId('vc-driver-results').classList.add('hidden');
    }

    function _searchInvItem(prefix, query) {
        var div = byId(prefix + '-item-results'); if (!div) return;
        if (!query || query.trim().length < 1) { div.classList.add('hidden'); return; }
        var items = RW_STATE.data.items || [];
        var q = query.toLowerCase();
        var filtered = items.filter(function(i) { return (i.name || '').toLowerCase().indexOf(q) !== -1 || (i.item_code || '').toLowerCase().indexOf(q) !== -1 || (i.barcode || '').toLowerCase().indexOf(q) !== -1; });
        if (filtered.length > 0) {
            var html = '';
            for (var idx = 0; idx < Math.min(filtered.length, 30); idx++) {
                var item = filtered[idx];
                html += '<div onclick="RW_Warehouse._addToInvCart(\'' + prefix + '\', \'' + item.item_code + '\')" class="p-3 hover:bg-blue-50 cursor-pointer border-b flex items-center"><div><div class="font-bold">' + item.name + '</div><div class="text-xs text-slate-400">كود: ' + item.item_code + ' | رصيد: ' + (item.qty || 0) + '</div></div></div>';
            }
            safeHTML(div, html); div.classList.remove('hidden');
        } else { safeHTML(div, '<div class="p-3 text-center text-gray-400">لا توجد نتائج</div>'); div.classList.remove('hidden'); }
    }

    function _addToInvCart(prefix, itemCode) {
        var items = RW_STATE.data.items || [], item = null;
        for (var i = 0; i < items.length; i++) { if (items[i].item_code === itemCode) { item = items[i]; break; } }
        if (!item) return;
        var existing = null;
        for (var j = 0; j < window._invCart.length; j++) { if (window._invCart[j].code === itemCode) { existing = window._invCart[j]; break; } }
        if (existing) { existing.qty = (parseInt(existing.qty) || 0) + 1; } else { window._invCart.push({ code: item.item_code, name: item.name, unit: item.unit || 'حبة', qty: 1 }); }
        byId(prefix + '-item-search').value = '';
        byId(prefix + '-item-results').classList.add('hidden');
        _renderInvCart(prefix);
    }

    function _renderInvCart(prefix) {
        var tbody = byId(prefix + '-cart-table'), countSpan = byId(prefix + '-cart-count');
        if (!tbody) return;
        if (window._invCart.length === 0) { safeHTML(tbody, '<tr><td colspan="4" class="p-6 text-center">أضف أصنافاً</td></tr>'); if (countSpan) countSpan.innerText = '0'; return; }
        var html = '';
        for (var i = 0; i < window._invCart.length; i++) {
            var it = window._invCart[i];
            html += '<tr class="border-b hover:bg-slate-50"><td class="p-2"><div class="font-bold">' + it.name + '</div><div class="text-xs">' + it.code + '</div></td><td class="p-2 text-center">' + it.unit + '</td><td class="p-2 text-center"><input type="number" value="' + it.qty + '" onchange="RW_Warehouse._updateInvCartQty(' + i + ', this.value, \'' + prefix + '\')" class="w-20 p-1 border rounded text-center" min="0"></td><td class="p-2 text-center"><button onclick="RW_Warehouse._removeInvCartItem(' + i + ', \'' + prefix + '\')" class="text-red-500"><i class="fa-solid fa-trash"></i></button></td></tr>';
        }
        safeHTML(tbody, html);
        if (countSpan) countSpan.innerText = String(window._invCart.length);
    }

    function _updateInvCartQty(idx, val, prefix) {
        var q = parseInt(val);
        if (isNaN(q) || q <= 0) { window._invCart.splice(idx, 1); } else { window._invCart[idx].qty = q; }
        _renderInvCart(prefix);
    }

    function _removeInvCartItem(idx, prefix) { window._invCart.splice(idx, 1); _renderInvCart(prefix); }

async function _saveVehicleCount() {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    var selectedDriver = window._selectedDriver || '';
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    if (!selectedDriver) { showToast('يجب اختيار مندوب', 'warning'); return; }

    var reference = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';
    var notes = (byId('vc-notes') ? byId('vc-notes').value : '') || '';
    if (notes) reference = reference ? reference + ' | ' + notes : notes;

    var selectedRunsheet = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';
    var vehicleId = null;

    var userRes = await supabase.from('users')
        .select('id')
        .eq('company_id', companyId)
        .eq('email', selectedDriver)
        .maybeSingle();
    if (userRes.error) { showToast(userRes.error.message, 'error'); return; }
    var driverId = userRes.data ? userRes.data.id : null;

    if (selectedRunsheet) {
        var rsRes = await supabase.from('runsheets')
            .select('vehicle_id')
            .eq('company_id', companyId)
            .eq('runsheet_code', selectedRunsheet)
            .maybeSingle();
        if (rsRes.error) { showToast(rsRes.error.message, 'error'); return; }
        vehicleId = rsRes.data ? rsRes.data.vehicle_id : null;
    }

    if (!vehicleId && driverId) {
        var vehicleRes = await supabase.from('vehicles')
            .select('id')
            .eq('company_id', companyId)
            .eq('driver_id', driverId)
            .limit(1)
            .maybeSingle();
        if (vehicleRes.error) { showToast(vehicleRes.error.message, 'error'); return; }
        vehicleId = vehicleRes.data ? vehicleRes.data.id : null;
    }

    if (!vehicleId) { showToast('لا توجد مركبة مرتبطة بهذا المندوب', 'warning'); return; }
    await _saveInvCount('vehicle', vehicleId, reference || 'جرد سيارة');
}

    async function _saveInvCount(type, entityId, reference) {
        if (!window._invCart || window._invCart.length === 0) { showToast('أضف أصنافاً', 'warning'); return; }
        var items = [];
        for (var i = 0; i < window._invCart.length; i++) {
            items.push({ itemCode: window._invCart[i].code, itemName: window._invCart[i].name, unit: window._invCart[i].unit, qty: parseInt(window._invCart[i].qty) || 0, unitPrice: 0, notes: '' });
        }
        showLoader('جاري حفظ الجرد...');
        try {
            var ses = await supabase.auth.getSession(), token = ses.data.session ? ses.data.session.access_token : null;
            var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-inventory-count', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ type: type, entityId: entityId, reference: reference, items: items }) });
            var json = await res.json(); hideLoader();
            if (json.success) { showToast(json.msg + ' (' + json.voucherId + ')', 'success'); window._invCart = []; _renderInvCart('vc'); }
            else showToast(json.msg || 'فشل الحفظ', 'error');
        } catch(e) { hideLoader(); showToast('فشل الاتصال', 'error'); }
    }

    async function loadBranchCount() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'جرد فرع');
        var branches = RW_STATE.data.branches || [];
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4 grid grid-cols-1 md:grid-cols-3 gap-4">
                <div><label class="text-xs font-bold block mb-1">الفرع</label><select id="bc-branch-select" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200 font-bold"><option value="">-- اختر --</option>${branches.map(b => '<option value="' + (b.id || b.branch_code || '') + '">' + (b.name || b.branch_name || '') + '</option>').join(''))}</select></div>
                <div><label class="text-xs font-bold block mb-1">القسم / الرف</label><input id="bc-section" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200" placeholder="مثلاً: رف A-1"></div>
                <div><label class="text-xs font-bold block mb-1">ملاحظات</label><input id="bc-notes" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200" placeholder="ملاحظات..."></div>
            </div>
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4 relative">
                <label class="text-xs font-bold block mb-2">البحث عن صنف</label>
<div class="relative"><input type="text" id="bc-item-search" oninput="RW_Warehouse._searchInvItem('bc', this.value)" autocomplete="off" placeholder="امسح الباركود أو ابحث..." class="w-full p-4 bg-slate-50 rounded-xl border-2 focus:border-emerald-500 outline-none font-bold text-lg"><button onclick="RW_Warehouse._startBarcodeScanner('bc')" class="absolute left-2 top-2 bg-emerald-600 text-white p-3 rounded-xl"><i class="fa-solid fa-camera"></i></button></div>
            </div>
            <div class="bg-white rounded-xl shadow-sm overflow-auto" style="max-height:50vh;"><table class="w-full"><thead class="bg-slate-800 text-white"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">حذف</th></tr></thead><tbody id="bc-cart-table"><tr><td colspan="4" class="p-6 text-center">أضف أصنافاً</td></tr></tbody></table></div>
            <div class="mt-2">عدد الأصناف: <span id="bc-cart-count">0</span></div>
            <div class="mt-4 flex justify-end gap-3"><button onclick="window._invCart=[]; RW_Warehouse._renderInvCart('bc')" class="bg-gray-500 text-white px-4 py-2 rounded-xl font-bold text-sm">مسح الكل</button><button onclick="RW_Warehouse._saveBranchCount()" class="bg-blue-600 text-white px-8 py-3 rounded-2xl font-black text-lg shadow-lg"><i class="fa-solid fa-check ml-2"></i> حفظ الجرد</button></div>
        </div>`);
        window._invCart = []; _renderInvCart('bc');
    }

    async function _saveBranchCount() {
        var entityId = (byId('bc-branch-select') ? byId('bc-branch-select').value : '') || '';
        if (!entityId) { showToast('يجب اختيار فرع', 'warning'); return; }
        var section = (byId('bc-section') ? byId('bc-section').value : '') || '';
        var notes = (byId('bc-notes') ? byId('bc-notes').value : '') || '';
        var reference = section ? ('قسم: ' + section) : '';
        if (notes) reference = reference ? reference + ' | ' + notes : notes;
        await _saveInvCount('branch', entityId, reference || 'جرد فرع');
    }

    async function loadGeneralCount() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'جرد عام');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><input id="gc-notes" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200" placeholder="ملاحظات الجرد العام..."></div>
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4 relative">
                <label class="text-xs font-bold block mb-2">البحث عن صنف</label>
<div class="relative"><input type="text" id="gc-item-search" oninput="RW_Warehouse._searchInvItem('gc', this.value)" autocomplete="off" placeholder="امسح الباركود أو ابحث..." class="w-full p-4 bg-slate-50 rounded-xl border-2 focus:border-emerald-500 outline-none font-bold text-lg"><button onclick="RW_Warehouse._startBarcodeScanner('gc')" class="absolute left-2 top-2 bg-emerald-600 text-white p-3 rounded-xl"><i class="fa-solid fa-camera"></i></button></div>
            </div>
            <div class="bg-white rounded-xl shadow-sm overflow-auto" style="max-height:50vh;"><table class="w-full"><thead class="bg-slate-800 text-white"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">حذف</th></tr></thead><tbody id="gc-cart-table"><tr><td colspan="4" class="p-6 text-center">أضف أصنافاً</td></tr></tbody></table></div>
            <div class="mt-2">عدد الأصناف: <span id="gc-cart-count">0</span></div>
            <div class="mt-4 flex justify-end gap-3"><button onclick="window._invCart=[]; RW_Warehouse._renderInvCart('gc')" class="bg-gray-500 text-white px-4 py-2 rounded-xl font-bold text-sm">مسح الكل</button><button onclick="RW_Warehouse._saveGeneralCount()" class="bg-blue-600 text-white px-8 py-3 rounded-2xl font-black text-lg shadow-lg"><i class="fa-solid fa-check ml-2"></i> حفظ الجرد</button></div>
        </div>`);
        window._invCart = []; _renderInvCart('gc');
    }

async function _saveGeneralCount() {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    var notes = (byId('gc-notes') ? byId('gc-notes').value : '') || '';
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }

    var settingsRes = await supabase.from('app_settings')
        .select('main_branch_id')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();
    if (settingsRes.error) { showToast(settingsRes.error.message, 'error'); return; }

    var mainBranchId = settingsRes.data ? settingsRes.data.main_branch_id : null;
    if (!mainBranchId) { showToast('الفرع الرئيسي غير محدد', 'error'); return; }

    await _saveInvCount('general', mainBranchId, 'جرد عام' + (notes ? ' | ' + notes : ''));
}

    // ==================== SETTLEMENT (إغلاق اليومية) ====================
    async function loadSettlement() {
        var c = byId('rw-page-container'); if (!c) return;
        safeText(byId('rw-header-title'), 'إغلاق اليومية');
        safeHTML(c, `<div class="p-4">
            <div class="bg-white rounded-2xl shadow-sm border p-4 mb-4">
                <label class="text-xs font-bold block mb-2">اختيار الرانشيت</label>
                <select id="settlement-rs-select" class="w-full p-3 bg-slate-50 rounded-xl border-2 border-slate-200 font-bold" onchange="RW_Warehouse._onSettlementRsChange()"><option value="">-- اختر رانشيتاً --</option></select>
                <div id="settlement-rs-info" class="mt-3 text-sm text-slate-500"></div>
            </div>
            <div id="settlement-details-container" class="hidden">
                <div class="bg-white rounded-xl shadow-sm overflow-auto mb-4" style="max-height:50vh;"><table class="w-full"><thead class="bg-slate-800 text-white sticky top-0"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">محمّلة</th><th class="p-2 text-center">مسلّمة</th><th class="p-2 text-center">مرتجعة</th><th class="p-2 text-center">مجرودة</th><th class="p-2 text-center">العجز</th><th class="p-2 text-center">قيمة العجز</th></tr></thead><tbody id="settlement-items-body"><tr><td colspan="7" class="p-6 text-center">اختر رانشيتاً</td></tr></tbody></table></div>
                <div class="flex justify-end gap-2"><button onclick="RW_Warehouse._saveSettlement()" class="bg-emerald-600 text-white px-8 py-3 rounded-2xl font-black shadow-lg"><i class="fa-solid fa-check ml-2"></i> حفظ التسوية وترحيل العجز</button></div>
            </div>
        </div>`);
        
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Delivered', 'Returned']);
        var sel = byId('settlement-rs-select');
        if (sel && runsheetsRes.data) {
            for (var i = 0; i < runsheetsRes.data.length; i++) {
                sel.innerHTML += '<option value="' + runsheetsRes.data[i].runsheet_code + '">' + runsheetsRes.data[i].runsheet_code + ' - ' + (runsheetsRes.data[i].driver_id || '') + '</option>';
            }
        }
    }

async function _onSettlementRsChange() {
    var rsCode = byId('settlement-rs-select')?.value;
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!rsCode) {
        byId('settlement-details-container').classList.add('hidden');
        return;
    }
    if (!companyId) {
        showToast('سياق الشركة غير محدد', 'error');
        return;
    }

    showLoader('جاري تحميل بيانات التسوية...');

    try {
        var rsRes = await supabase.from('runsheets')
            .select('*')
            .eq('company_id', companyId)
            .eq('runsheet_code', rsCode)
            .maybeSingle();
        if (rsRes.error) throw rsRes.error;

        var rs = rsRes.data;
        if (!rs) {
            hideLoader();
            showToast('الرانشيت غير موجود', 'error');
            return;
        }

        var loadedRes = await supabase.from('run_sheet_details')
            .select('*')
            .eq('runsheet_id', rs.id);
        if (loadedRes.error) throw loadedRes.error;
        var loadedItems = loadedRes.data || [];

        var ordersForRsRes = await supabase.from('orders')
            .select('id')
            .eq('company_id', companyId)
            .eq('runsheet_id', rs.id);
        if (ordersForRsRes.error) throw ordersForRsRes.error;

        var orderIdsForRs = (ordersForRsRes.data || []).map(function(o) { return o.id; });
        var orderDetails = [];
        if (orderIdsForRs.length > 0) {
            var orderDetailsRes = await supabase.from('order_details')
                .select('*')
                .in('order_id', orderIdsForRs);
            if (orderDetailsRes.error) throw orderDetailsRes.error;
            orderDetails = orderDetailsRes.data || [];
        }

        var vouchersRes = await supabase.from('stock_vouchers')
            .select('id, voucher_code')
            .eq('company_id', companyId)
            .eq('reference', rsCode)
            .eq('type', 'Return');
        if (vouchersRes.error) throw vouchersRes.error;

        var voucherIds = (vouchersRes.data || []).map(function(v) { return v.id; });
        var returnDetails = [];
        if (voucherIds.length > 0) {
            var retRes = await supabase.from('stock_voucher_details')
                .select('*')
                .in('voucher_id', voucherIds);
            if (retRes.error) throw retRes.error;
            returnDetails = retRes.data || [];
        }

        var vehicleRes = await supabase.from('vehicles')
            .select('id, mobile_branch_id')
            .eq('company_id', companyId)
            .eq('id', rs.vehicle_id)
            .maybeSingle();
        if (vehicleRes.error) throw vehicleRes.error;

        var vehicle = vehicleRes.data || null;
        var inventoryEntityId = vehicle ? (vehicle.mobile_branch_id || vehicle.id) : null;
        var countedByItem = {};

        if (inventoryEntityId) {
            var countRes = await supabase.from('inventory_counts')
                .select('id')
                .eq('company_id', companyId)
                .eq('type', 'vehicle')
                .eq('entity_id', inventoryEntityId)
                .order('created_at', { ascending: false })
                .limit(1)
                .maybeSingle();
            if (countRes.error) throw countRes.error;

            if (countRes.data) {
                var countDetailsRes = await supabase.from('inventory_count_details')
                    .select('item_code, counted_qty')
                    .eq('count_id', countRes.data.id);
                if (countDetailsRes.error) throw countDetailsRes.error;

                var countDetails = countDetailsRes.data || [];
                for (var c = 0; c < countDetails.length; c++) {
                    countedByItem[countDetails[c].item_code] = Number(countDetails[c].counted_qty) || 0;
                }
            }
        }

        var itemsMap = {};
        for (var i = 0; i < loadedItems.length; i++) {
            var it = loadedItems[i];
            itemsMap[it.item_code] = {
                itemCode: it.item_code,
                itemName: it.item_name,
                unit: it.unit,
                loadedQty: Number(it.qty_loaded) || 0,
                deliveredQty: 0,
                returnedQty: 0,
                countedQty: Number(countedByItem[it.item_code]) || 0,
                unitPrice: Number(it.unit_price) || 0
            };
        }

        for (var j = 0; j < orderDetails.length; j++) {
            var od = orderDetails[j];
            if (itemsMap[od.item_code]) {
                itemsMap[od.item_code].deliveredQty += Number(od.qty_delivered) || 0;
                itemsMap[od.item_code].returnedQty += Number(od.qty_refused) || 0;
            }
        }

        for (var k = 0; k < returnDetails.length; k++) {
            var rd = returnDetails[k];
            if (itemsMap[rd.item_code]) {
                itemsMap[rd.item_code].returnedQty += Number(rd.qty) || 0;
            }
        }

        var html = '';
        var totalShortage = 0;
        var totalShortageValue = 0;

        for (var code in itemsMap) {
            var itm = itemsMap[code];
            var shortage = itm.loadedQty - itm.deliveredQty - itm.returnedQty - itm.countedQty;
            var shortageValue = shortage * itm.unitPrice;

            if (shortage > 0) {
                totalShortage += shortage;
                totalShortageValue += shortageValue;
            }

            html += '<tr class="border-b"><td class="p-2"><div class="font-bold">' + itm.itemName + '</div><div class="text-xs text-gray-400">' + itm.itemCode + '</div></td><td class="p-2 text-center">' + itm.loadedQty + '</td><td class="p-2 text-center">' + itm.deliveredQty + '</td><td class="p-2 text-center">' + itm.returnedQty + '</td><td class="p-2 text-center font-bold">' + itm.countedQty + '</td><td class="p-2 text-center font-bold text-red-600">' + shortage + '</td><td class="p-2 text-center">' + Math.abs(shortageValue).toLocaleString() + ' EGP</td></tr>';
        }

        safeHTML(byId('settlement-items-body'), html || '<tr><td colspan="7" class="p-6 text-center">لا توجد بيانات</td></tr>');
        safeHTML(byId('settlement-rs-info'), '<strong>المندوب:</strong> ' + (rs.driver_id || '---') + ' | <strong>السيارة:</strong> ' + (rs.vehicle_id || '---') + ' | <strong>التاريخ:</strong> ' + (rs.run_date || '---'));
        byId('settlement-details-container').classList.remove('hidden');

        window._settlementData = {
            rs: rs,
            items: itemsMap,
            totalShortage: totalShortage,
            totalShortageValue: totalShortageValue
        };

        hideLoader();
    } catch (e) {
        hideLoader();
        showToast('فشل تحميل البيانات: ' + (e.message || ''), 'error');
    }
}

    function _saveSettlement() {
        var data = window._settlementData;
        if (!data) { showToast('اختر رانشيتاً أولاً', 'warning'); return; }
        var rs = data.rs;
        if (!rs || !rs.runsheet_code) { showToast('بيانات الرانشيت غير مكتملة', 'error'); return; }
        
        showLoader('جاري حفظ التسوية...');
        
        supabase.auth.getSession().then(function(ses) {
            var token = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
            if (!token) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }
            
            return fetch(RW_SUPABASE_URL + '/functions/v1/save-daily-settlement', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token
                },
                body: JSON.stringify({
                    runsheet_code: rs.runsheet_code,
                    notes: 'تسوية يومية للرانشيت ' + rs.runsheet_code
                })
            });
        }).then(function(res) {
            if (!res) return;
            return res.json();
        }).then(function(json) {
            hideLoader();
            if (json && json.success) {
                showToast('تم حفظ التسوية: ' + json.settlement_code, 'success');
                var container = byId('settlement-details-container');
                if (container) container.classList.add('hidden');
                var sel = byId('settlement-rs-select');
                if (sel) sel.value = '';
            } else {
                showToast((json && json.msg) || 'فشل الحفظ', 'error');
            }
        }).catch(function(e) {
            hideLoader();
            showToast('فشل الاتصال', 'error');
            console.error(e);
        });
    }
function _openPickingModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات التحضير...');
    
    // ✅ الإصلاح: جلب الرانشيت أولاً للحصول على id الحقيقي (UUID)
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
    supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', rsCode)
    .maybeSingle()
    .then(function(rsRes) {
        if (!rsRes.data) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return; }
        var runsheetUuid = rsRes.data.id;
        
        // ✅ استخدام runsheetUuid (UUID) للاستعلام عن التفاصيل
        supabase.from('run_sheet_details').select('*').eq('runsheet_id', runsheetUuid).then(function(itemsRes) {
            var items = itemsRes.data || [];
            if (items.length === 0) { hideLoader(); showToast('لا توجد أصناف في هذا الرانشيت', 'info'); return; }
            
            showLoader('جاري بدء التحضير...');
            supabase.auth.getSession().then(function(ses) {
                var t = ses.data.session ? ses.data.session.access_token : null;
                return fetch(RW_SUPABASE_URL + '/functions/v1/start-picking', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                    body: JSON.stringify({ runsheet_code: rsCode })
                });
            }).then(function(res) { return res.json(); }).then(function(startJson) {
                hideLoader();
                if (!startJson.success) { showToast(startJson.msg || 'فشل بدء التحضير', 'error'); return; }
                
                var html = '<div class="text-right" dir="rtl"><div class="max-h-[400px] overflow-y-auto"><table class="w-full border"><thead class="bg-slate-100"><tr>' +
                    '<th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية المطلوبة</th><th class="p-2 text-center">الكمية المحضرة</th></tr></thead><tbody>';
                for (var i = 0; i < items.length; i++) {
                    var it = items[i];
                    html += '<tr><td class="p-2 border"><p class="font-bold">' + (it.item_name || '') + '</p><p class="text-xs">' + (it.item_code || '') + '</p></td>' +
                        '<td class="p-2 border text-center">' + (it.unit || 'حبة') + '</td>' +
                        '<td class="p-2 border text-center font-bold">' + (it.qty_ordered || 0) + '</td>' +
                        '<td class="p-2 border text-center"><input type="number" id="picked_qty_' + i + '" class="w-24 p-2 border rounded text-center" step="1" min="0" value="' + (it.qty_ordered || 0) + '"></td></tr>';
                }
                html += '</tbody></table></div></div>';
                
                Swal.fire({
                    title: 'تحضير الرانشيت: ' + rsCode,
                    html: html,
                    width: '800px',
                    showCancelButton: true,
                    confirmButtonText: 'إنهاء التحضير',
                    cancelButtonText: 'إلغاء',
                    preConfirm: function() {
                        var itemsData = [];
                        var allZero = true;
                        for (var j = 0; j < items.length; j++) {
                            var qty = parseFloat(document.getElementById('picked_qty_' + j).value) || 0;
                            if (qty > 0) allZero = false;
                            itemsData.push({ itemCode: items[j].item_code, pickedQty: qty, notes: '' });
                        }
                        if (allZero) { Swal.showValidationMessage('يجب تحضير كمية واحدة على الأقل'); return false; }
                        return itemsData;
                    }
                }).then(function(result) {
                    if (!result.isConfirmed) return;
                    showLoader('جاري إنهاء التحضير...');
                    supabase.auth.getSession().then(function(ses2) {
                        var t2 = ses2.data.session ? ses2.data.session.access_token : null;
                        return fetch(RW_SUPABASE_URL + '/functions/v1/complete-picking', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t2 },
                            body: JSON.stringify({ runsheet_code: rsCode, items: result.value })
                        });
                    }).then(function(res) { return res.json(); }).then(function(compJson) {
                        hideLoader();
                        if (compJson.success) {
                            showToast('تم إنهاء التحضير بنجاح', 'success');
                            if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
                        } else {
                            showToast(compJson.msg || 'فشل إنهاء التحضير', 'error');
                        }
                    }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
                });
            }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
        }).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
    }).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
}
function _openLoadingModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات التحميل...');
    
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', rsCode)
    .maybeSingle()
    .then(function(rsRes) {
        if (!rsRes.data) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return; }
        var runsheetUuid = rsRes.data.id;
        
        supabase.from('run_sheet_details').select('*').eq('runsheet_id', runsheetUuid).then(function(itemsRes) {
            var items = itemsRes.data || [];
            if (items.length === 0) { hideLoader(); showToast('لا توجد أصناف في هذا الرانشيت', 'info'); return; }
            
            showLoader('جاري بدء التحميل...');
            supabase.auth.getSession().then(function(ses) {
                var t = ses.data.session ? ses.data.session.access_token : null;
                return fetch(RW_SUPABASE_URL + '/functions/v1/start-loading', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                    body: JSON.stringify({ runsheet_code: rsCode })
                });
            }).then(function(res) { return res.json(); }).then(function(startJson) {
                hideLoader();
                if (!startJson.success) { showToast(startJson.msg || 'فشل بدء التحميل', 'error'); return; }
                
                var html = '<div class="text-right" dir="rtl"><div class="max-h-[400px] overflow-y-auto"><table class="w-full border"><thead class="bg-slate-100"><tr>' +
                    '<th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية المحضّرة</th><th class="p-2 text-center">الكمية المحمّلة</th></tr></thead><tbody>';
                for (var i = 0; i < items.length; i++) {
                    var it = items[i];
                    var picked = it.qty_picked || 0;
                    html += '<tr><td class="p-2 border"><p class="font-bold">' + (it.item_name || '') + '</p><p class="text-xs">' + (it.item_code || '') + '</p></td>' +
                        '<td class="p-2 border text-center">' + (it.unit || 'حبة') + '</td>' +
                        '<td class="p-2 border text-center font-bold">' + picked + '</td>' +
                        '<td class="p-2 border text-center"><input type="number" id="loaded_qty_' + i + '" class="w-24 p-2 border rounded text-center" step="1" min="0" max="' + picked + '" value="' + picked + '"></td></tr>';
                }
                html += '</tbody></table></div></div>';
                
                Swal.fire({
                    title: 'تحميل الرانشيت: ' + rsCode,
                    html: html,
                    width: '800px',
                    showCancelButton: true,
                    confirmButtonText: 'إنهاء التحميل',
                    cancelButtonText: 'إلغاء',
                    preConfirm: function() {
                        var itemsData = [];
                        var allZero = true;
                        for (var j = 0; j < items.length; j++) {
                            var qty = parseFloat(document.getElementById('loaded_qty_' + j).value) || 0;
                            if (qty > 0) allZero = false;
                            itemsData.push({ itemCode: items[j].item_code, loadedQty: qty, notes: '' });
                        }
                        if (allZero) { Swal.showValidationMessage('يجب تحميل كمية واحدة على الأقل'); return false; }
                        return itemsData;
                    }
                }).then(function(result) {
                    if (!result.isConfirmed) return;
                    showLoader('جاري إنهاء التحميل...');
                    supabase.auth.getSession().then(function(ses2) {
                        var t2 = ses2.data.session ? ses2.data.session.access_token : null;
                        return fetch(RW_SUPABASE_URL + '/functions/v1/complete-loading', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t2 },
                            body: JSON.stringify({ runsheet_code: rsCode, items: result.value })
                        });
                    }).then(function(res) { return res.json(); }).then(function(compJson) {
                        hideLoader();
                        if (compJson.success) {
                            showToast('تم إنهاء التحميل بنجاح', 'success');
                            if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
                        } else {
                            showToast(compJson.msg || 'فشل إنهاء التحميل', 'error');
                        }
                    }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
                });
            }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
        }).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
    }).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
}function _openDeliveryModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات التوصيل...');

    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }

    supabase.from('runsheets')
        .select('id,status')
        .eq('company_id', companyId)
        .eq('runsheet_code', rsCode)
        .maybeSingle()
        .then(function(rsRes) {
            if (rsRes.error) throw rsRes.error;
            var rs = rsRes.data;
            if (!rs) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return null; }

            showLoader('جاري بدء التوصيل...');
            return supabase.auth.getSession().then(function(ses) {
                var t = ses.data.session ? ses.data.session.access_token : null;
                if (!t) throw new Error('انتهت الجلسة');
                return fetch(RW_SUPABASE_URL + '/functions/v1/start-delivery', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                    body: JSON.stringify({ runsheet_code: rsCode })
                });
            }).then(function(res) {
                return res.json();
            }).then(function(startJson) {
                if (!startJson.success) { hideLoader(); showToast(startJson.msg || 'فشل بدء التوصيل', 'error'); return null; }

                return supabase.from('orders')
                    .select('id,order_code,customer_name')
                    .eq('company_id', companyId)
                    .eq('runsheet_id', rs.id)
                    .order('created_at', { ascending: true })
                    .then(function(ordersRes) {
                        if (ordersRes.error) throw ordersRes.error;
                        var orders = ordersRes.data || [];
                        if (!orders.length) { hideLoader(); showToast('لا توجد أوردرات في الرانشيت', 'info'); return null; }

                        function deliverOrder(index) {
                            if (index >= orders.length) {
                                showLoader('جاري إنهاء الرانشيت...');
                                return supabase.auth.getSession().then(function(ses2) {
                                    var t2 = ses2.data.session ? ses2.data.session.access_token : null;
                                    if (!t2) throw new Error('انتهت الجلسة');
                                    return fetch(RW_SUPABASE_URL + '/functions/v1/complete-delivery', {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t2 },
                                        body: JSON.stringify({ runsheet_code: rsCode })
                                    });
                                }).then(function(res) {
                                    return res.json();
                                }).then(function(finalJson) {
                                    hideLoader();
                                    if (finalJson.success) {
                                        showToast('تم إنهاء التوصيل بالكامل', 'success');
                                        if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
                                    } else {
                                        showToast(finalJson.msg || 'فشل إنهاء الرانشيت', 'error');
                                    }
                                });
                            }

                            var order = orders[index];
                            showLoader('جاري تحميل بيانات الأوردر ' + (order.order_code || '') + '...');
                            return supabase.from('order_details')
                                .select('id,item_code,item_name,unit,qty,qty_loaded,qty_delivered,qty_refused,unit_price')
                                .eq('order_id', order.id)
                                .order('created_at', { ascending: true })
                                .then(function(detailsRes) {
                                    if (detailsRes.error) throw detailsRes.error;
                                    var details = detailsRes.data || [];
                                    hideLoader();
                                    if (!details.length) {
                                        return deliverOrder(index + 1);
                                    }

                                    var html = '<div class="text-right" dir="rtl"><div class="max-h-[420px] overflow-y-auto">';
                                    html += '<div class="mb-3 p-3 bg-blue-50 rounded-lg"><div class="font-black text-blue-700">' + (order.order_code || '') + '</div><div class="text-sm text-gray-600">' + (order.customer_name || '') + '</div></div>';
                                    html += '<table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">محمّل</th><th class="p-2 text-center">مسلّم سابقًا</th><th class="p-2 text-center">المتبقي</th><th class="p-2 text-center">تسليم الآن</th></tr></thead><tbody>';

                                    for (var i = 0; i < details.length; i++) {
                                        var d = details[i];
                                        var loaded = Number(d.qty_loaded || 0);
                                        var delivered = Number(d.qty_delivered || 0);
                                        var remaining = Math.max(0, loaded - delivered);
                                        html += '<tr><td class="p-2 border"><div class="font-bold">' + (d.item_name || '') + '</div><div class="text-xs text-gray-400">' + (d.item_code || '') + '</div></td>'
                                            + '<td class="p-2 border text-center">' + loaded + '</td>'
                                            + '<td class="p-2 border text-center">' + delivered + '</td>'
                                            + '<td class="p-2 border text-center font-bold text-blue-700">' + remaining + '</td>'
                                            + '<td class="p-2 border text-center"><input type="number" id="dv_order_qty_' + i + '" value="' + remaining + '" min="0" max="' + remaining + '" step="0.01" class="w-24 p-1 border rounded text-center"></td></tr>';
                                    }
                                    html += '</tbody></table></div></div>';

                                    return Swal.fire({
                                        title: 'توصيل الأوردر ' + (order.order_code || ''),
                                        html: html,
                                        width: '850px',
                                        showCancelButton: true,
                                        confirmButtonText: 'تأكيد تسليم الأوردر',
                                        cancelButtonText: 'إلغاء',
                                        preConfirm: function() {
                                            var items = [];
                                            var hasQty = false;
                                            for (var j = 0; j < details.length; j++) {
                                                var maxRemaining = Math.max(0, Number(details[j].qty_loaded || 0) - Number(details[j].qty_delivered || 0));
                                                var q = parseFloat((document.getElementById('dv_order_qty_' + j) || {}).value) || 0;
                                                if (q < 0 || q > maxRemaining) {
                                                    Swal.showValidationMessage('كمية التسليم تتجاوز المتبقي للصنف: ' + (details[j].item_code || ''));
                                                    return false;
                                                }
                                                if (q > 0) hasQty = true;
                                                items.push({ itemCode: details[j].item_code, deliveredQty: q, reason: '' });
                                            }
                                            if (!hasQty) {
                                                Swal.showValidationMessage('أدخل كمية تسليم واحدة على الأقل');
                                                return false;
                                            }
                                            return items;
                                        }
                                    }).then(function(result) {
                                        if (!result.isConfirmed) return;
                                        showLoader('جاري حفظ تسليم ' + (order.order_code || '') + '...');
                                        return supabase.auth.getSession().then(function(ses3) {
                                            var t3 = ses3.data.session ? ses3.data.session.access_token : null;
                                            if (!t3) throw new Error('انتهت الجلسة');
                                            return fetch(RW_SUPABASE_URL + '/functions/v1/complete-order-delivery', {
                                                method: 'POST',
                                                headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t3 },
                                                body: JSON.stringify({ runsheet_code: rsCode, order_code: order.order_code, items: result.value })
                                            });
                                        }).then(function(res) {
                                            return res.json();
                                        }).then(function(orderJson) {
                                            hideLoader();
                                            if (!orderJson.success) {
                                                showToast(orderJson.msg || 'فشل تسليم الأوردر', 'error');
                                                return;
                                            }
                                            return deliverOrder(index + 1);
                                        });
                                    });
                                });
                        }

                        return deliverOrder(0);
                    });
            });
        })
        .catch(function(e) {
            hideLoader();
            showToast(e.message || 'فشل تحميل بيانات التوصيل', 'error');
        });
}
function _openReturnModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات المرتجعات...');
    
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', rsCode)
    .maybeSingle()
    .then(function(rsRes) {
        if (!rsRes.data) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return; }
        var runsheetUuid = rsRes.data.id;
        
        supabase.from('run_sheet_details').select('*').eq('runsheet_id', runsheetUuid).then(function(itemsRes) {
            var items = itemsRes.data || [];
            if (items.length === 0) { hideLoader(); showToast('لا توجد أصناف في هذا الرانشيت', 'info'); return; }
            
            showLoader('جاري بدء المرتجعات...');
            supabase.auth.getSession().then(function(ses) {
                var t = ses.data.session ? ses.data.session.access_token : null;
                return fetch(RW_SUPABASE_URL + '/functions/v1/start-return', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                    body: JSON.stringify({ runsheet_code: rsCode })
                });
            }).then(function(res) { return res.json(); }).then(function(startJson) {
                hideLoader();
                if (!startJson.success) { showToast(startJson.msg || 'فشل بدء المرتجعات', 'error'); return; }
                
                var html = '<div class="text-right" dir="rtl"><div class="max-h-[400px] overflow-y-auto"><table class="w-full border"><thead class="bg-slate-100"><tr>' +
                    '<th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية المسلّمة</th><th class="p-2 text-center">الكمية المرتجعة</th></tr></thead><tbody>';
                for (var i = 0; i < items.length; i++) {
                    var it = items[i];
                    var delivered = it.qty_delivered || 0;
                    html += '<tr><td class="p-2 border"><p class="font-bold">' + (it.item_name || '') + '</p><p class="text-xs">' + (it.item_code || '') + '</p></td>' +
                        '<td class="p-2 border text-center">' + (it.unit || 'حبة') + '</td>' +
                        '<td class="p-2 border text-center font-bold">' + delivered + '</td>' +
                        '<td class="p-2 border text-center"><input type="number" id="returned_qty_' + i + '" class="w-24 p-2 border rounded text-center" step="1" min="0" max="' + delivered + '" value="0"></td></tr>';
                }
                html += '</tbody></table></div></div>';
                
                Swal.fire({
                    title: 'مرتجعات الرانشيت: ' + rsCode,
                    html: html,
                    width: '800px',
                    showCancelButton: true,
                    confirmButtonText: 'إنهاء المرتجعات',
                    cancelButtonText: 'إلغاء',
                    preConfirm: function() {
                        var itemsData = [];
                        var allZero = true;
                        for (var j = 0; j < items.length; j++) {
                            var qty = parseFloat(document.getElementById('returned_qty_' + j).value) || 0;
                            if (qty > 0) allZero = false;
                            itemsData.push({ itemCode: items[j].item_code, returnedQty: qty, reason: '' });
                        }
                        if (allZero) { Swal.showValidationMessage('يجب إدخال كمية مرتجعة واحدة على الأقل'); return false; }
                        return itemsData;
                    }
                }).then(function(result) {
                    if (!result.isConfirmed) return;
                    showLoader('جاري إنهاء المرتجعات...');
                    supabase.auth.getSession().then(function(ses2) {
                        var t2 = ses2.data.session ? ses2.data.session.access_token : null;
                        return fetch(RW_SUPABASE_URL + '/functions/v1/complete-return', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t2 },
                            body: JSON.stringify({ runsheet_code: rsCode, items: result.value })
                        });
                    }).then(function(res) { return res.json(); }).then(function(compJson) {
                        hideLoader();
                        if (compJson.success) {
                            showToast('تم إنهاء المرتجعات بنجاح', 'success');
                            if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
                        } else {
                            showToast(compJson.msg || 'فشل إنهاء المرتجعات', 'error');
                        }
                    }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
                });
            }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
        }).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
    }).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
}
function _confirmUnload(code) {
    Swal.fire({ title: 'تأكيد التفريغ', text: 'إعادة جميع الكميات للمخزون؟', icon: 'warning', showCancelButton: true, confirmButtonText: 'نعم', cancelButtonText: 'لا' }).then(function(cf) {
        if (!cf.isConfirmed) return;
        showLoader('جاري التفريغ...');
        supabase.auth.getSession().then(function(ses) {
            var t = ses.data.session ? ses.data.session.access_token : null;
            return fetch(RW_SUPABASE_URL + '/functions/v1/unload-runsheet', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                body: JSON.stringify({ runsheet_code: code })
            });
        }).then(function(res) { return res.json(); }).then(function(json) {
            hideLoader();
            if (json.success) {
                showToast('تم التفريغ بنجاح', 'success');
                if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
            } else {
                showToast(json.msg || 'فشل التفريغ', 'error');
            }
        }).catch(function(e) { hideLoader(); showToast('فشل الاتصال', 'error'); });
    });
}
function _changeStatus(code, funcName) {
    showLoader('جاري تحديث الحالة...');
    supabase.auth.getSession().then(function(ses) {
        var t = ses.data.session ? ses.data.session.access_token : null;
        return fetch(SUPABASE_URL + '/functions/v1/' + funcName, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
            body: JSON.stringify({ runsheet_code: code })
        });
    }).then(function(res) { return res.json(); }).then(function(json) {
        hideLoader();
        if (json.success) {
            showToast('تم بنجاح', 'success');
        } else {
            showToast(json.msg || 'فشل', 'error');
        }
    }).catch(function(e) {
        hideLoader();
        showToast('فشل الاتصال', 'error');
    });
}

    return {
            loadReceiving: loadReceiving,
    _applyReceiving: _applyReceiving,
    _showReceivingDetails: _showReceivingDetails,
    loadVouchers: loadVouchers,
    _applyVouchers: _applyVouchers,
    _viewVoucherDetails: _viewVoucherDetails,
    _sendVoucher: _sendVoucher,
    _receiveVoucher: _receiveVoucher,
    _openNewVoucherModal: _openNewVoucherModal,
    loadVoucherForm: loadVoucherForm,
    _searchVoucherItem: _searchVoucherItem,
    _addVoucherItem: _addVoucherItem,
    _renderVoucherCart: _renderVoucherCart,
    _updateVoucherQty: _updateVoucherQty,
    _updateVoucherPrice: _updateVoucherPrice,
    _removeVoucherItem: _removeVoucherItem,
    _clearVoucherCart: _clearVoucherCart,
    _saveAndSendVoucher: _saveAndSendVoucher,
    loadPicking: loadPicking,
    _applyPicking: _applyPicking,
    _showPickingDetails: _showPickingDetails,
    loadLoading: loadLoading,
    _applyLoading: _applyLoading,
    _showLoadingDetails: _showLoadingDetails,
    loadDelivery: loadDelivery,
    _applyDelivery: _applyDelivery,
    _showDeliveryDetails: _showDeliveryDetails,
    loadReturn: loadReturn,
    _applyReturn: _applyReturn,
    _showReturnDetails: _showReturnDetails,
    loadUnloading: loadUnloading,
    _applyUnloading: _applyUnloading,
    _showUnloadingDetails: _showUnloadingDetails,
    loadVehicleCount: loadVehicleCount,
    loadBranchCount: loadBranchCount,
    loadGeneralCount: loadGeneralCount,
    loadSettlement: loadSettlement,
    _searchDriver: _searchDriver,
    _selectDriver: _selectDriver,
    _searchInvItem: _searchInvItem,
    _addToInvCart: _addToInvCart,
    _renderInvCart: _renderInvCart,
    _updateInvCartQty: _updateInvCartQty,
    _removeInvCartItem: _removeInvCartItem,
    _saveVehicleCount: _saveVehicleCount,
    _saveBranchCount: _saveBranchCount,
    _saveGeneralCount: _saveGeneralCount,
    _saveInvCount: _saveInvCount,
    _onSettlementRsChange: _onSettlementRsChange,
    _saveSettlement: _saveSettlement,
    _openPickingModal: _openPickingModal,
    _openLoadingModal: _openLoadingModal,
    _openDeliveryModal: _openDeliveryModal,
    _openReturnModal: _openReturnModal,
    _startPicking: _changeStatus,
    _startLoading: _changeStatus,
    _startDelivery: _changeStatus,
    _startReturn: _changeStatus,
    _confirmUnload: _confirmUnload,
    _changeStatus: _changeStatus
    };
})();
window.RW_Warehouse = RW_Warehouse;

