# التعديل الجراحي الوحيد المعتمد — Main9

## العنصر المعيب المطلوب حذفه بالكامل
احذف من Main9 الدالة الحالية كاملة:

`async function _generateReport(sectionKey, reportId) { ... }`

حتى قوس الإغلاق النهائي للدالة وقبل:

`function _printReport() {`

## البديل الكامل
استبدل الدالة كاملة بالنص التالي:

```javascript
async function _generateReport(sectionKey, reportId) {
    var resultDiv = byId('report-result');
    if (!resultDiv) return;

    safeHTML(
        resultDiv,
        '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin text-2xl"></i> جاري تحميل التقرير...</div>'
    );

    var fromDate = (byId('rp-date-from') ? byId('rp-date-from').value : '');
    var toDate = (byId('rp-date-to') ? byId('rp-date-to').value : '');
    var customer = (byId('rp-customer') ? byId('rp-customer').value : '');
    var supplier = (byId('rp-supplier') ? byId('rp-supplier').value : '');
    var itemCode = (byId('rp-item') ? byId('rp-item').value : '');
    var account = (byId('rp-account') ? byId('rp-account').value : '');
    var treasury = (byId('rp-treasury') ? byId('rp-treasury').value : '');
    var driver = (byId('rp-driver') ? byId('rp-driver').value : '');
    var area = (byId('rp-area') ? byId('rp-area').value : '');

    try {
        var companyId = _companyId();
        var data = [];
        var html = '';

        if (fromDate && toDate && fromDate > toDate) {
            throw new Error('نطاق التاريخ غير صالح');
        }

        async function _companyOrders(selectClause) {
            var q = supabase
                .from('orders')
                .select(selectClause)
                .eq('company_id', companyId)
                .gte('order_date', fromDate)
                .lt('order_date', _nextDate(toDate));
            if (customer) q = q.eq('customer_id', customer);
            if (area) q = q.eq('area', area);
            var r = await q;
            if (r.error) throw r.error;
            return r.data || [];
        }

        async function _companyOrderIds() {
            var r = await supabase
                .from('orders')
                .select('id')
                .eq('company_id', companyId)
                .gte('order_date', fromDate)
                .lt('order_date', _nextDate(toDate));
            if (r.error) throw r.error;
            return (r.data || []).map(function (x) { return x.id; }).filter(Boolean);
        }

        async function _resolveCustomer(id) {
            if (!id) return null;
            var r = await supabase
                .from('customers')
                .select('id, customer_code, name')
                .eq('id', id)
                .eq('company_id', companyId)
                .maybeSingle();
            if (r.error) throw r.error;
            return r.data || null;
        }

        async function _resolveItem(code) {
            if (!code) return null;
            var r = await supabase
                .from('items')
                .select('id, item_code, name, unit, reorder_point, max_qty, sales_price')
                .eq('item_code', code)
                .maybeSingle();
            if (r.error) throw r.error;
            return r.data || null;
        }

        if (reportId === 'sales-summary') {
            data = await _companyOrders('total_amount');
            var totalSales = 0;
            for (var i = 0; i < data.length; i++) totalSales += Number(data[i].total_amount) || 0;
            var avg = data.length ? Math.round(totalSales / data.length) : 0;
            html = '<h4 class="font-bold mb-3">ملخص المبيعات</h4>' +
                '<div class="grid grid-cols-3 gap-4">' +
                '<div class="bg-blue-50 p-4 rounded-xl text-center"><p class="text-xs">عدد الأوردرات</p><p class="text-2xl font-black">' + data.length + '</p></div>' +
                '<div class="bg-green-50 p-4 rounded-xl text-center"><p class="text-xs">الإجمالي</p><p class="text-2xl font-black">' + _fmtNum(totalSales) + ' EGP</p></div>' +
                '<div class="bg-amber-50 p-4 rounded-xl text-center"><p class="text-xs">متوسط الأوردر</p><p class="text-2xl font-black">' + _fmtNum(avg) + ' EGP</p></div>' +
                '</div>';
        }
        else if (reportId === 'sales-by-customer') {
            data = await _companyOrders('customer_id, customer_name, total_amount');
            var customerMap = {};
            for (var j = 0; j < data.length; j++) {
                var cid = data[j].customer_id || 'غير محدد';
                var cname = data[j].customer_name || cid;
                if (!customerMap[cid]) customerMap[cid] = { name: cname, total: 0, count: 0 };
                customerMap[cid].total += Number(data[j].total_amount) || 0;
                customerMap[cid].count += 1;
            }
            var customerArr = Object.keys(customerMap).map(function (k) { return { id: k, name: customerMap[k].name, total: customerMap[k].total, count: customerMap[k].count }; }).sort(function (a, b) { return b.total - a.total; });
            var grandCustomerTotal = customerArr.reduce(function (s, a) { return s + a.total; }, 0);
            html = '<h4 class="font-bold mb-3">المبيعات حسب العميل (اضغط على الصف للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود العميل</th><th class="p-2">اسم العميل</th><th class="p-2 text-center">عدد الفواتير</th><th class="p-2 text-center">إجمالي المبيعات</th><th class="p-2 text-center">نسبة من الإجمالي</th></tr></thead><tbody>';
            for (var ca = 0; ca < customerArr.length; ca++) {
                var pct = grandCustomerTotal > 0 ? Math.round((customerArr[ca].total / grandCustomerTotal) * 100) : 0;
                html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showCustomerLedgerDetail(\'' + _esc(customerArr[ca].id) + '\', \'' + _esc(customerArr[ca].name).replace(/'/g, "\\'") + '\')">' +
                    '<td class="p-2">' + _esc(customerArr[ca].id) + '</td><td class="p-2 font-semibold">' + _esc(customerArr[ca].name) + '</td><td class="p-2 text-center">' + customerArr[ca].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(customerArr[ca].total) + ' EGP</td><td class="p-2 text-center">' + pct + '%</td></tr>';
            }
            html += '</tbody></table>';
        }
        else if (reportId === 'sales-by-item') {
            var orderIds = await _companyOrderIds();
            var detailRows = [];
            if (orderIds.length) {
                var detailRes = await supabase.from('order_details').select('item_code, item_name, qty, unit_price, order_id').in('order_id', orderIds);
                if (detailRes.error) throw detailRes.error;
                detailRows = detailRes.data || [];
            }
            var itemMap = {};
            for (var di = 0; di < detailRows.length; di++) {
                var code = detailRows[di].item_code || detailRows[di].item_name || 'غير محدد';
                if (!itemMap[code]) itemMap[code] = { name: detailRows[di].item_name || code, qty: 0, total: 0 };
                itemMap[code].qty += Number(detailRows[di].qty) || 0;
                itemMap[code].total += (Number(detailRows[di].qty) || 0) * (Number(detailRows[di].unit_price) || 0);
            }
            var itemArr = Object.keys(itemMap).map(function (k) { return { code: k, name: itemMap[k].name, qty: itemMap[k].qty, total: itemMap[k].total }; }).sort(function (a, b) { return b.total - a.total; });
            html = '<h4 class="font-bold mb-3">المبيعات حسب الصنف (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود الصنف</th><th class="p-2">اسم الصنف</th><th class="p-2 text-center">الكمية المباعة</th><th class="p-2 text-center">إجمالي المبيعات</th></tr></thead><tbody>';
            for (var ia = 0; ia < itemArr.length; ia++) {
                html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' + _esc(itemArr[ia].code) + '\', \'' + _esc(itemArr[ia].name).replace(/'/g, "\\'") + '\')"><td class="p-2">' + _esc(itemArr[ia].code) + '</td><td class="p-2 font-semibold">' + _esc(itemArr[ia].name) + '</td><td class="p-2 text-center">' + itemArr[ia].qty + '</td><td class="p-2 text-center font-bold">' + _fmtNum(itemArr[ia].total) + ' EGP</td></tr>';
            }
            html += '</tbody></table>';
        }
        else if (reportId === 'sales-by-area') {
            data = await _companyOrders('area, total_amount');
            var areaMap = {};
            for (var ai = 0; ai < data.length; ai++) { var areaName = data[ai].area || 'غير محدد'; areaMap[areaName] = (areaMap[areaName] || 0) + (Number(data[ai].total_amount) || 0); }
            var areaArr = Object.keys(areaMap).map(function (k) { return { area: k, total: areaMap[k] }; }).sort(function (a, b) { return b.total - a.total; });
            html = '<h4 class="font-bold mb-3">المبيعات حسب المنطقة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">المنطقة</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
            for (var ar = 0; ar < areaArr.length; ar++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(areaArr[ar].area) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(areaArr[ar].total) + ' EGP</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'sales-order-status') {
            data = await _companyOrders('order_status');
            var statusMap = {};
            for (var st = 0; st < data.length; st++) { var status = data[st].order_status || 'غير محدد'; statusMap[status] = (statusMap[status] || 0) + 1; }
            html = '<h4 class="font-bold mb-3">حالة الأوردرات</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الحالة</th><th class="p-2 text-center">العدد</th></tr></thead><tbody>';
            for (var sk in statusMap) html += '<tr class="border-t"><td class="p-2">' + _esc(sk) + '</td><td class="p-2 text-center font-bold">' + statusMap[sk] + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'sales-customer-ledger') {
            if (!customer) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار عميل</div>'); return; }
            var validCustomer = await _resolveCustomer(customer);
            if (!validCustomer) throw new Error('العميل غير موجود ضمن الشركة الحالية');
            var ledgerRes = await supabase.from('customer_ledger').select('*').eq('customer_id', validCustomer.id).order('entry_date', { ascending: false });
            if (ledgerRes.error) throw ledgerRes.error;
            data = ledgerRes.data || [];
            html = '<h4 class="font-bold mb-3">كشف حساب العميل</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">البيان</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th><th class="p-2 text-center">الرصيد</th></tr></thead><tbody>';
            for (var cl = 0; cl < data.length; cl++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[cl].entry_date) + '</td><td class="p-2">' + _esc(data[cl].description) + '</td><td class="p-2 text-center">' + _fmtNum(data[cl].debit) + '</td><td class="p-2 text-center">' + _fmtNum(data[cl].credit) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[cl].balance) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'sales-runsheet-performance') {
            var rsRes = await supabase.from('runsheets').select('runsheet_code, run_date, total_amount, status, driver_id, vehicle_id').eq('company_id', companyId).gte('run_date', fromDate).lt('run_date', _nextDate(toDate));
            if (rsRes.error) throw rsRes.error;
            data = rsRes.data || [];
            if (driver) data = data.filter(function (x) { return String(x.driver_id || '') === String(driver); });
            html = '<h4 class="font-bold mb-3">أداء الرانشيتات (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود الرانشيت</th><th class="p-2">التاريخ</th><th class="p-2">السائق</th><th class="p-2 text-center">القيمة</th><th class="p-2 text-center">الحالة</th></tr></thead><tbody>';
            for (var rp = 0; rp < data.length; rp++) html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showRunsheetDetail(\'' + _esc(data[rp].runsheet_code) + '\')"><td class="p-2 font-bold text-blue-600">' + _esc(data[rp].runsheet_code) + '</td><td class="p-2">' + _esc(data[rp].run_date) + '</td><td class="p-2">' + _esc(data[rp].driver_id) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[rp].total_amount) + '</td><td class="p-2 text-center">' + _esc(data[rp].status) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'inventory-stock' || reportId === 'inventory-low-stock' || reportId === 'inventory-dormant') {
            var itemRes = await supabase.from('items').select('id, item_code, name, unit, reorder_point, max_qty, sales_price').order('item_code', { ascending: true });
            if (itemRes.error) throw itemRes.error;
            var masterItems = itemRes.data || [];
            var branchRes = await supabase.from('branches').select('id').eq('company_id', companyId).eq('is_active', true);
            if (branchRes.error) throw branchRes.error;
            var branchIds = (branchRes.data || []).map(function (b) { return b.id; }).filter(Boolean);
            var stockRows = [];
            if (branchIds.length) {
                var stockRes = await supabase.from('stock_branches').select('item_id, branch_id, qty, allocated_qty').in('branch_id', branchIds);
                if (stockRes.error) throw stockRes.error;
                stockRows = stockRes.data || [];
            }
            var stockMap = {};
            for (var sr = 0; sr < stockRows.length; sr++) {
                var srow = stockRows[sr];
                if (!srow.item_id) continue;
                if (!stockMap[srow.item_id]) stockMap[srow.item_id] = { qty: 0, allocated: 0 };
                stockMap[srow.item_id].qty += Number(srow.qty) || 0;
                stockMap[srow.item_id].allocated += Number(srow.allocated_qty) || 0;
            }
            if (reportId === 'inventory-stock') {
                html = '<h4 class="font-bold mb-3">جرد المخزون الحالي (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود الصنف</th><th class="p-2">اسم الصنف</th><th class="p-2">الوحدة</th><th class="p-2 text-center">الكمية الفعلية</th><th class="p-2 text-center">المحجوزة</th><th class="p-2 text-center">المتاحة</th><th class="p-2 text-center">سعر البيع</th><th class="p-2 text-center">قيمة المخزون</th></tr></thead><tbody>';
                for (var ii = 0; ii < masterItems.length; ii++) {
                    var mi = masterItems[ii]; var q = stockMap[mi.id] ? stockMap[mi.id].qty : 0; var al = stockMap[mi.id] ? stockMap[mi.id].allocated : 0; var av = Math.max(0, q - al); var val = q * (Number(mi.sales_price) || 0);
                    html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' + _esc(mi.item_code) + '\', \'' + _esc(mi.name).replace(/'/g, "\\'") + '\')"><td class="p-2">' + _esc(mi.item_code) + '</td><td class="p-2 font-semibold">' + _esc(mi.name) + '</td><td class="p-2">' + _esc(mi.unit) + '</td><td class="p-2 text-center">' + q + '</td><td class="p-2 text-center">' + al + '</td><td class="p-2 text-center font-bold">' + av + '</td><td class="p-2 text-center">' + _fmtNum(mi.sales_price) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(val) + ' EGP</td></tr>';
                }
                html += '</tbody></table>';
            }
            else if (reportId === 'inventory-low-stock') {
                var lowRows = masterItems.filter(function (it) { var q0 = stockMap[it.id] ? stockMap[it.id].qty : 0; var a0 = stockMap[it.id] ? stockMap[it.id].allocated : 0; return Math.max(0, q0 - a0) <= (Number(it.reorder_point) || 5); });
                html = '<h4 class="font-bold mb-3">الأصناف الأقل من حد الطلب</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الصنف</th><th class="p-2 text-center">المتاح</th><th class="p-2 text-center">حد الطلب</th></tr></thead><tbody>';
                for (var li = 0; li < lowRows.length; li++) { var lq = stockMap[lowRows[li].id] ? stockMap[lowRows[li].id].qty : 0; var la = stockMap[lowRows[li].id] ? stockMap[lowRows[li].id].allocated : 0; html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(lowRows[li].name) + '</td><td class="p-2 text-center font-bold text-red-600">' + Math.max(0, lq - la) + '</td><td class="p-2 text-center">' + (Number(lowRows[li].reorder_point) || 5) + '</td></tr>'; }
                html += '</tbody></table>';
            }
            else {
                var orderIdForDormant = await _companyOrderIds();
                var sold = {};
                if (orderIdForDormant.length) {
                    var soldRes = await supabase.from('order_details').select('item_code').in('order_id', orderIdForDormant);
                    if (soldRes.error) throw soldRes.error;
                    (soldRes.data || []).forEach(function (x) { if (x && x.item_code) sold[x.item_code] = true; });
                }
                var dormantRows = masterItems.filter(function (it) { var dq = stockMap[it.id] ? stockMap[it.id].qty : 0; var da = stockMap[it.id] ? stockMap[it.id].allocated : 0; return Math.max(0, dq - da) > 0 && !sold[it.item_code]; }).slice(0, 30);
                html = '<h4 class="font-bold mb-3">تحليل دوران المخزون (راكدة)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الصنف</th><th class="p-2 text-center">المتاح</th></tr></thead><tbody>';
                for (var dr = 0; dr < dormantRows.length; dr++) { var dq2 = stockMap[dormantRows[dr].id] ? stockMap[dormantRows[dr].id].qty : 0; var da2 = stockMap[dormantRows[dr].id] ? stockMap[dormantRows[dr].id].allocated : 0; html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(dormantRows[dr].name) + '</td><td class="p-2 text-center font-bold text-red-600">' + Math.max(0, dq2 - da2) + '</td></tr>'; }
                html += '</tbody></table>';
            }
        }
        else if (reportId === 'inventory-movement') {
            if (!itemCode) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار صنف</div>'); return; }
            var itemIdentity = await _resolveItem(itemCode);
            if (!itemIdentity) throw new Error('الصنف غير موجود');
            var movementRes = await supabase.from('inventory_log').select('id, log_code, movement_date, voucher_id, item_id, item_code, item_name, movement_type, qty, reference, user_email, created_at').eq('company_id', companyId).eq('item_id', itemIdentity.id).order('movement_date', { ascending: false }).order('created_at', { ascending: false });
            if (movementRes.error) throw movementRes.error;
            data = movementRes.data || [];
            if (!data.length) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">لا توجد حركات لهذا الصنف</div>'); return; }
            html = '<h4 class="font-bold mb-3">حركة الصنف</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2 text-center">الكمية</th><th class="p-2">المرجع</th></tr></thead><tbody>';
            for (var im = 0; im < data.length; im++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[im].movement_date) + '</td><td class="p-2">' + _esc(data[im].movement_type) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[im].qty) + '</td><td class="p-2">' + _esc(data[im].reference || data[im].voucher_id || '') + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'purchase-by-supplier' || reportId === 'purchase-order-status') {
            var poQuery = supabase.from('purchase_orders').select(reportId === 'purchase-by-supplier' ? 'supplier_id, supplier_name, total_amount' : 'status').eq('company_id', companyId).gte('po_date', fromDate).lt('po_date', _nextDate(toDate));
            if (supplier) poQuery = poQuery.eq('supplier_id', supplier);
            var poRes = await poQuery;
            if (poRes.error) throw poRes.error;
            data = poRes.data || [];
            if (reportId === 'purchase-by-supplier') {
                var supplierMap = {};
                for (var ps = 0; ps < data.length; ps++) { var sid = data[ps].supplier_id || 'غير محدد'; if (!supplierMap[sid]) supplierMap[sid] = { name: data[ps].supplier_name || sid, total: 0, count: 0 }; supplierMap[sid].total += Number(data[ps].total_amount) || 0; supplierMap[sid].count += 1; }
                var supplierArr = Object.keys(supplierMap).map(function (k) { return { id: k, name: supplierMap[k].name, total: supplierMap[k].total, count: supplierMap[k].count }; }).sort(function (a, b) { return b.total - a.total; });
                html = '<h4 class="font-bold mb-3">المشتريات حسب المورد</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود المورد</th><th class="p-2">اسم المورد</th><th class="p-2 text-center">عدد الأوامر</th><th class="p-2 text-center">إجمالي المشتريات</th></tr></thead><tbody>';
                for (var sa = 0; sa < supplierArr.length; sa++) html += '<tr class="border-t"><td class="p-2">' + _esc(supplierArr[sa].id) + '</td><td class="p-2 font-semibold">' + _esc(supplierArr[sa].name) + '</td><td class="p-2 text-center">' + supplierArr[sa].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(supplierArr[sa].total) + ' EGP</td></tr>';
                html += '</tbody></table>';
            } else {
                var poStatusMap = {};
                for (var pos = 0; pos < data.length; pos++) { var pst = data[pos].status || 'غير محدد'; poStatusMap[pst] = (poStatusMap[pst] || 0) + 1; }
                html = '<h4 class="font-bold mb-3">حالة أوامر الشراء</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الحالة</th><th class="p-2 text-center">العدد</th></tr></thead><tbody>';
                for (var psk in poStatusMap) html += '<tr class="border-t"><td class="p-2">' + _esc(psk) + '</td><td class="p-2 text-center font-bold">' + poStatusMap[psk] + '</td></tr>';
                html += '</tbody></table>';
            }
        }
        else if (reportId === 'purchase-receiving') {
            var receivingRes = await supabase.from('receiving').select('operation_id, po_number, date').eq('company_id', companyId).gte('date', fromDate).lt('date', _nextDate(toDate));
            if (receivingRes.error) throw receivingRes.error;
            var receivingRows = receivingRes.data || [];
            var operationIds = receivingRows.map(function (x) { return x.operation_id; }).filter(Boolean);
            data = [];
            if (operationIds.length) {
                var receivingDetailsRes = await supabase.from('receiving_details').select('operation_id, item_code, item_name, qty_expected, qty_received').in('operation_id', operationIds);
                if (receivingDetailsRes.error) throw receivingDetailsRes.error;
                data = receivingDetailsRes.data || [];
            }
            html = '<h4 class="font-bold mb-3">استلام البضاعة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الصنف</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">المستلم</th><th class="p-2 text-center">الفرق</th></tr></thead><tbody>';
            for (var rd = 0; rd < data.length; rd++) { var diff = (Number(data[rd].qty_received) || 0) - (Number(data[rd].qty_expected) || 0); html += '<tr class="border-t"><td class="p-2">' + _esc(data[rd].item_name || data[rd].item_code) + '</td><td class="p-2 text-center">' + _fmtNum(data[rd].qty_expected) + '</td><td class="p-2 text-center">' + _fmtNum(data[rd].qty_received) + '</td><td class="p-2 text-center ' + (diff < 0 ? 'text-red-600' : 'text-green-600') + '">' + _fmtNum(diff) + '</td></tr>'; }
            html += '</tbody></table>';
        }
        else if (reportId === 'finance-trial-balance') {
            var tbRes = await supabase.rpc('get_trial_balance', { p_from_date: fromDate, p_to_date: toDate });
            if (tbRes.error) throw tbRes.error;
            data = tbRes.data || [];
            html = '<h4 class="font-bold mb-3">ميزان المراجعة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الاسم</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th><th class="p-2 text-center">الرصيد</th></tr></thead><tbody>';
            for (var tb = 0; tb < data.length; tb++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[tb].account_id) + '</td><td class="p-2">' + _esc(data[tb].account_name) + '</td><td class="p-2 text-center">' + _fmtNum(data[tb].total_debit) + '</td><td class="p-2 text-center">' + _fmtNum(data[tb].total_credit) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[tb].net_balance) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'finance-profit-loss') {
            var plRes = await supabase.rpc('get_profit_loss', { p_from_date: fromDate, p_to_date: toDate });
            if (plRes.error) throw plRes.error;
            data = plRes.data || [];
            html = '<h4 class="font-bold mb-3">قائمة الدخل</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">النوع</th><th class="p-2">الكود</th><th class="p-2">الحساب</th><th class="p-2 text-center">المبلغ</th></tr></thead><tbody>';
            for (var pl = 0; pl < data.length; pl++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[pl].account_type) + '</td><td class="p-2">' + _esc(data[pl].account_id) + '</td><td class="p-2">' + _esc(data[pl].account_name) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[pl].total_amount) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'finance-balance-sheet') {
            var bsRes = await supabase.rpc('get_balance_sheet_data', { p_as_of: toDate });
            if (bsRes.error) throw bsRes.error;
            var bs = bsRes.data || {};
            function _bsTable(title, rows) {
                var out = '<div class="mb-4"><h5 class="font-bold mb-2">' + title + '</h5><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الحساب</th><th class="p-2 text-center">الرصيد</th></tr></thead><tbody>';
                rows = Array.isArray(rows) ? rows : [];
                for (var bi = 0; bi < rows.length; bi++) out += '<tr class="border-t"><td class="p-2">' + _esc(rows[bi].account_code) + '</td><td class="p-2">' + _esc(rows[bi].account_name) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(rows[bi].balance) + '</td></tr>';
                return out + '</tbody></table></div>';
            }
            html = _bsTable('الأصول', bs.assets) + _bsTable('الخصوم', bs.liabilities) + _bsTable('حقوق الملكية', bs.equity);
        }
        else if (reportId === 'finance-cash-flow') {
            var cfRes = await supabase.rpc('get_cash_flow', { p_from_date: fromDate, p_to_date: toDate });
            if (cfRes.error) throw cfRes.error;
            data = cfRes.data || [];
            html = '<h4 class="font-bold mb-3">قائمة التدفقات النقدية</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التصنيف</th><th class="p-2">الحساب</th><th class="p-2 text-center">المبلغ</th></tr></thead><tbody>';
            for (var cf = 0; cf < data.length; cf++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[cf].category) + '</td><td class="p-2">' + _esc(data[cf].account_name) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[cf].amount) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'finance-general-ledger') {
            if (!account) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار حساب</div>'); return; }
            var accountRes = await supabase.from('chart_of_accounts').select('id, account_code, account_name').eq('id', account).eq('company_id', companyId).eq('is_active', true).maybeSingle();
            if (accountRes.error) throw accountRes.error;
            if (!accountRes.data) throw new Error('الحساب غير موجود ضمن الشركة الحالية');
            var entryRes = await supabase.from('journal_entries').select('id, entry_date, reference, description').eq('company_id', companyId).eq('status', 'Posted').gte('entry_date', fromDate).lt('entry_date', _nextDate(toDate));
            if (entryRes.error) throw entryRes.error;
            var entryIds = (entryRes.data || []).map(function (x) { return x.id; }).filter(Boolean);
            data = [];
            if (entryIds.length) {
                var lineRes = await supabase.from('journal_lines').select('entry_id, debit, credit').eq('account_id', accountRes.data.id).in('entry_id', entryIds);
                if (lineRes.error) throw lineRes.error;
                var lineMap = {};
                (lineRes.data || []).forEach(function (x) { lineMap[x.entry_id] = x; });
                (entryRes.data || []).forEach(function (e) { if (lineMap[e.id]) data.push({ entry: e, line: lineMap[e.id] }); });
            }
            html = '<h4 class="font-bold mb-3">دفتر الأستاذ العام – ' + _esc(accountRes.data.account_name) + '</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">المرجع</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th></tr></thead><tbody>';
            for (var gl = 0; gl < data.length; gl++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[gl].entry.entry_date) + '</td><td class="p-2">' + _esc(data[gl].entry.reference) + '</td><td class="p-2 text-center">' + _fmtNum(data[gl].line.debit) + '</td><td class="p-2 text-center">' + _fmtNum(data[gl].line.credit) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'finance-treasury') {
            if (!treasury) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار خزينة</div>'); return; }
            var treasuryRes = await supabase.from('treasury').select('id, account_code, account_name').eq('id', treasury).eq('company_id', companyId).maybeSingle();
            if (treasuryRes.error) throw treasuryRes.error;
            if (!treasuryRes.data) throw new Error('الخزينة غير موجودة ضمن الشركة الحالية');
            var cashRes = await supabase.from('cash_box').select('*').eq('treasury_id', treasuryRes.data.id).gte('voucher_date', fromDate).lt('voucher_date', _nextDate(toDate)).order('voucher_date', { ascending: false });
            if (cashRes.error) throw cashRes.error;
            data = cashRes.data || [];
            html = '<h4 class="font-bold mb-3">كشف حساب الخزينة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2 text-center">المبلغ</th></tr></thead><tbody>';
            for (var cb = 0; cb < data.length; cb++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[cb].voucher_date) + '</td><td class="p-2">' + _esc(data[cb].type) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[cb].amount) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'finance-tax') {
            html = '<div class="text-center py-4 text-gray-500">تقرير الضرائب قيد التطوير</div>';
        }
        else if (reportId === 'crm-customer-list') {
            var crmCustomersRes = await supabase.from('customers').select('customer_code, name, phone, area').eq('company_id', companyId).order('name', { ascending: true });
            if (crmCustomersRes.error) throw crmCustomersRes.error;
            data = crmCustomersRes.data || [];
            html = '<h4 class="font-bold mb-3">قائمة العملاء</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الاسم</th><th class="p-2">الهاتف</th><th class="p-2">المنطقة</th></tr></thead><tbody>';
            for (var cc = 0; cc < data.length; cc++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[cc].customer_code) + '</td><td class="p-2 font-semibold">' + _esc(data[cc].name) + '</td><td class="p-2">' + _esc(data[cc].phone) + '</td><td class="p-2">' + _esc(data[cc].area) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'crm-customer-analysis') {
            data = await _companyOrders('customer_id, customer_name, total_amount');
            var crmMap = {};
            for (var cma = 0; cma < data.length; cma++) { var cn = data[cma].customer_name || 'غير محدد'; if (!crmMap[cn]) crmMap[cn] = { name: cn, total: 0, count: 0 }; crmMap[cn].total += Number(data[cma].total_amount) || 0; crmMap[cn].count += 1; }
            var crmArr = Object.keys(crmMap).map(function (k) { return crmMap[k]; }).sort(function (a, b) { return b.total - a.total; }).slice(0, 20);
            html = '<h4 class="font-bold mb-3">تحليل العملاء</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">العميل</th><th class="p-2 text-center">عدد الأوردرات</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
            for (var crm = 0; crm < crmArr.length; crm++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(crmArr[crm].name) + '</td><td class="p-2 text-center">' + crmArr[crm].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(crmArr[crm].total) + ' EGP</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'crm-customer-followups') {
            html = '<div class="text-center py-4 text-gray-500">سجل المتابعات غير متوفر حالياً</div>';
        }
        else if (reportId === 'crm-customer-by-area') {
            var crmAreaRes = await supabase.from('customers').select('area').eq('company_id', companyId).order('area', { ascending: true });
            if (crmAreaRes.error) throw crmAreaRes.error;
            var crmAreaMap = {};
            (crmAreaRes.data || []).forEach(function (x) { var n = x.area || 'غير محدد'; crmAreaMap[n] = (crmAreaMap[n] || 0) + 1; });
            html = '<h4 class="font-bold mb-3">العملاء حسب المنطقة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">المنطقة</th><th class="p-2 text-center">عدد العملاء</th></tr></thead><tbody>';
            for (var cak in crmAreaMap) html += '<tr class="border-t"><td class="p-2">' + _esc(cak) + '</td><td class="p-2 text-center font-bold">' + crmAreaMap[cak] + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'logistics-loading-unloading') {
            var luRes = await supabase.from('stock_vouchers').select('voucher_code, type, voucher_date').eq('company_id', companyId).in('type', ['Loading', 'Unloading']).gte('voucher_date', fromDate).lt('voucher_date', _nextDate(toDate));
            if (luRes.error) throw luRes.error;
            data = luRes.data || [];
            html = '<h4 class="font-bold mb-3">سجل التحميل والتفريغ</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">رقم الإذن</th><th class="p-2">النوع</th><th class="p-2">التاريخ</th></tr></thead><tbody>';
            for (var lu = 0; lu < data.length; lu++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[lu].voucher_code) + '</td><td class="p-2">' + _esc(data[lu].type) + '</td><td class="p-2">' + _esc(data[lu].voucher_date) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'logistics-returns') {
            var returnRes = await supabase.from('inventory_log').select('log_code, movement_date, movement_type, item_code, item_name, qty, reference').eq('company_id', companyId).in('movement_type', ['SalesReturn', 'DirectReturn']).gte('movement_date', fromDate).lt('movement_date', _nextDate(toDate)).order('movement_date', { ascending: false });
            if (returnRes.error) throw returnRes.error;
            data = returnRes.data || [];
            html = '<h4 class="font-bold mb-3">سجل المرتجعات</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">السجل</th><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th><th class="p-2">المرجع</th></tr></thead><tbody>';
            for (var ret = 0; ret < data.length; ret++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[ret].log_code) + '</td><td class="p-2">' + _esc(data[ret].movement_date) + '</td><td class="p-2">' + _esc(data[ret].movement_type) + '</td><td class="p-2">' + _esc(data[ret].item_name || data[ret].item_code) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[ret].qty) + '</td><td class="p-2">' + _esc(data[ret].reference) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'logistics-settlement') {
            var dsRes = await supabase.from('daily_settlements').select('*').eq('company_id', companyId).gte('settlement_date', fromDate).lt('settlement_date', _nextDate(toDate));
            if (dsRes.error) throw dsRes.error;
            data = dsRes.data || [];
            html = '<h4 class="font-bold mb-3">إغلاق اليومية (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود التسوية</th><th class="p-2">التاريخ</th><th class="p-2">الرانشيت</th><th class="p-2 text-center">العجز</th><th class="p-2 text-center">قيمة العجز</th></tr></thead><tbody>';
            for (var ds = 0; ds < data.length; ds++) html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showSettlementDetail(\'' + _esc(data[ds].settlement_code) + '\')"><td class="p-2 font-bold">' + _esc(data[ds].settlement_code) + '</td><td class="p-2">' + _esc(data[ds].settlement_date) + '</td><td class="p-2">' + _esc(data[ds].runsheet_id) + '</td><td class="p-2 text-center">' + _fmtNum(data[ds].total_shortage) + '</td><td class="p-2 text-center font-bold text-red-600">' + _fmtNum(data[ds].total_shortage_value) + ' EGP</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'logistics-driver-performance') {
            var drvRes = await supabase.from('runsheets').select('driver_id, total_amount').eq('company_id', companyId).gte('run_date', fromDate).lt('run_date', _nextDate(toDate));
            if (drvRes.error) throw drvRes.error;
            data = drvRes.data || [];
            if (driver) data = data.filter(function (x) { return String(x.driver_id || '') === String(driver); });
            var driverMap = {};
            for (var dv = 0; dv < data.length; dv++) { var did = data[dv].driver_id || 'غير محدد'; if (!driverMap[did]) driverMap[did] = { total: 0, count: 0 }; driverMap[did].total += Number(data[dv].total_amount) || 0; driverMap[did].count += 1; }
            var driverArr = Object.keys(driverMap).map(function (k) { return { driver: k, total: driverMap[k].total, count: driverMap[k].count }; }).sort(function (a, b) { return b.total - a.total; });
            html = '<h4 class="font-bold mb-3">أداء السائقين</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">السائق</th><th class="p-2 text-center">عدد الرانشيتات</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
            for (var dvr = 0; dvr < driverArr.length; dvr++) html += '<tr class="border-t"><td class="p-2">' + _esc(driverArr[dvr].driver) + '</td><td class="p-2 text-center">' + driverArr[dvr].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(driverArr[dvr].total) + ' EGP</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'hr-employee-list') {
            var hrRes = await supabase.from('users').select('name, email, role, status').eq('company_id', companyId).order('name', { ascending: true });
            if (hrRes.error) throw hrRes.error;
            data = hrRes.data || [];
            html = '<h4 class="font-bold mb-3">قائمة الموظفين</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الاسم</th><th class="p-2">البريد</th><th class="p-2">الدور</th><th class="p-2">الحالة</th></tr></thead><tbody>';
            for (var hr = 0; hr < data.length; hr++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(data[hr].name) + '</td><td class="p-2">' + _esc(data[hr].email) + '</td><td class="p-2">' + _esc(data[hr].role) + '</td><td class="p-2">' + _esc(data[hr].status) + '</td></tr>';
            html += '</tbody></table>';
        }
        else if (reportId === 'hr-attendance' || reportId === 'hr-salary') {
            html = '<div class="text-center py-4 text-gray-500">البيانات غير متوفرة حالياً (قيد التطوير)</div>';
        }
        else {
            html = '<div class="text-center py-4 text-gray-500">هذا التقرير غير متوفر بعد</div>';
        }

        safeHTML(resultDiv, html);
    } catch (e) {
        console.error('RW_Reports_Comprehensive._generateReport', e);
        safeHTML(resultDiv, '<div class="text-center py-8 text-red-500">فشل تحميل التقرير: ' + _esc(e.message || 'حدث خطأ غير معروف') + '</div>');
    }
}
```

## ممنوع لمس أي عنصر آخر
- `_companyId()`
- `_appendOptions()`
- `_loadDashboardData()`
- `_loadDetailedReports()`
- دوال التفاصيل
- `return {...}`
- `window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;`

## الفحص المنفذ للبديل
`node --check main9_generateReport_replacement.js` = PASS
