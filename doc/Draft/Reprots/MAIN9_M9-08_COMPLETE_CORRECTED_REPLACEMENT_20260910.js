// RAWAEA ERP — M9-08 COMPLETE CORRECTED REPLACEMENT
// This is the complete replacement for RW_Reports_Comprehensive._generateReport.
// Surgical contract: read authority from current Main2 company context; read report data from Production directly.

async function _generateReport(sectionKey, reportId) {
    var resultDiv = byId('report-result');
    if (!resultDiv) return;

    var companyId = _companyId();
    var fromDate = byId('rp-date-from') ? byId('rp-date-from').value : '';
    var toDate = byId('rp-date-to') ? byId('rp-date-to').value : '';
    var customer = byId('rp-customer') ? byId('rp-customer').value : '';
    var supplier = byId('rp-supplier') ? byId('rp-supplier').value : '';
    var itemCode = byId('rp-item') ? byId('rp-item').value : '';
    var account = byId('rp-account') ? byId('rp-account').value : '';
    var treasury = byId('rp-treasury') ? byId('rp-treasury').value : '';
    var driver = byId('rp-driver') ? byId('rp-driver').value : '';
    var area = byId('rp-area') ? byId('rp-area').value : '';

    if (fromDate && toDate && fromDate > toDate) {
        safeHTML(resultDiv, '<div class="text-center py-6 text-red-500">نطاق التاريخ غير صالح</div>');
        return;
    }

    function table(title, rows, cols) {
        rows = Array.isArray(rows) ? rows : [];
        var html = '<h4 class="font-bold mb-3">' + _esc(title) + '</h4>';
        if (!rows.length) return html + '<div class="text-center py-5 text-gray-500">لا توجد بيانات</div>';
        html += '<table class="w-full text-sm"><thead><tr class="bg-gray-50">';
        for (var c = 0; c < cols.length; c++) html += '<th class="p-2">' + _esc(cols[c].label) + '</th>';
        html += '</tr></thead><tbody>';
        for (var r = 0; r < rows.length; r++) {
            html += '<tr class="border-t">';
            for (var cc = 0; cc < cols.length; cc++) {
                var v = rows[r] && rows[r][cols[cc].key] != null ? rows[r][cols[cc].key] : '';
                html += '<td class="p-2">' + _esc(String(v)) + '</td>';
            }
            html += '</tr>';
        }
        return html + '</tbody></table>';
    }

    async function q(tableName, selectText, apply) {
        var query = supabase.from(tableName).select(selectText);
        if (typeof apply === 'function') query = apply(query);
        var response = await query;
        if (response.error) throw response.error;
        return response.data || [];
    }

    async function companyOrders(selectText) {
        return q('orders', selectText, function(query) {
            query = query.eq('company_id', companyId);
            if (fromDate && toDate) query = query.gte('order_date', fromDate).lte('order_date', toDate);
            if (customer) query = query.eq('customer_id', customer);
            if (area) query = query.eq('area', area);
            return query;
        });
    }

    async function companyBranches() {
        return q('branches', 'id,branch_code,name', function(query) {
            return query.eq('company_id', companyId).eq('is_active', true);
        });
    }

    async function companyItems() {
        return q('items', 'id,item_code,name,unit,reorder_point,max_qty,cost_price,sales_price,barcode,is_active', function(query) {
            return query.order('item_code', { ascending: true });
        });
    }

    async function companyStock() {
        var branches = await companyBranches();
        var branchIds = branches.map(function(branch) { return branch.id; }).filter(Boolean);
        if (!branchIds.length) return [];
        return q('stock_branches', 'item_id,branch_id,qty,allocated_qty', function(query) {
            return query.in('branch_id', branchIds);
        });
    }

    async function financeRpc(name, args) {
        var response = await supabase.rpc(name, args);
        if (response.error) throw response.error;
        if (Array.isArray(response.data)) return response.data;
        if (response.data == null) return [];
        return [response.data];
    }

    try {
        var html = '';
        var data = [];

        if (reportId === 'sales-summary') {
            data = await companyOrders('total_amount');
            var salesTotal = data.reduce(function(sum, row) { return sum + Number(row.total_amount || 0); }, 0);
            var salesAverage = data.length ? salesTotal / data.length : 0;
            html = '<h4 class="font-bold mb-3">ملخص المبيعات</h4>' +
                '<div class="grid grid-cols-3 gap-4">' +
                '<div class="bg-blue-50 p-4 rounded-xl text-center"><p class="text-xs">عدد الأوردرات</p><p class="text-2xl font-black">' + data.length + '</p></div>' +
                '<div class="bg-green-50 p-4 rounded-xl text-center"><p class="text-xs">الإجمالي</p><p class="text-2xl font-black">' + _fmtNum(salesTotal) + ' EGP</p></div>' +
                '<div class="bg-amber-50 p-4 rounded-xl text-center"><p class="text-xs">متوسط الأوردر</p><p class="text-2xl font-black">' + _fmtNum(Math.round(salesAverage)) + ' EGP</p></div>' +
                '</div>';
        } else if (reportId === 'sales-by-customer') {
            data = await companyOrders('customer_id,customer_name,total_amount');
            var customerMap = {};
            data.forEach(function(row) {
                var key = row.customer_id || 'غير محدد';
                if (!customerMap[key]) customerMap[key] = { id:key, name:row.customer_name || key, count:0, total:0 };
                customerMap[key].count += 1;
                customerMap[key].total += Number(row.total_amount || 0);
            });
            html = table('المبيعات حسب العميل', Object.keys(customerMap).map(function(key){return customerMap[key];}).sort(function(a,b){return b.total-a.total;}), [
                {key:'id',label:'كود العميل'},{key:'name',label:'اسم العميل'},{key:'count',label:'عدد الفواتير'},{key:'total',label:'إجمالي المبيعات'}
            ]);
        } else if (reportId === 'sales-by-item') {
            var salesOrders = await companyOrders('id');
            var salesOrderIds = salesOrders.map(function(row){return row.id;}).filter(Boolean);
            data = salesOrderIds.length ? await q('order_details','order_id,item_id,item_code,item_name,qty,unit_price',function(query){return query.in('order_id',salesOrderIds);}) : [];
            var itemMap = {};
            data.forEach(function(row){
                var key = row.item_id || row.item_code;
                if (!itemMap[key]) itemMap[key] = {code:row.item_code || '', name:row.item_name || row.item_code || '', qty:0, total:0};
                itemMap[key].qty += Number(row.qty || 0);
                itemMap[key].total += Number(row.qty || 0) * Number(row.unit_price || 0);
            });
            html = table('المبيعات حسب الصنف', Object.keys(itemMap).map(function(key){return itemMap[key];}).sort(function(a,b){return b.total-a.total;}), [
                {key:'code',label:'كود الصنف'},{key:'name',label:'اسم الصنف'},{key:'qty',label:'الكمية'},{key:'total',label:'إجمالي المبيعات'}
            ]);
        } else if (reportId === 'sales-by-area') {
            data = await companyOrders('area,total_amount');
            var areaMap = {};
            data.forEach(function(row){var key=row.area||'غير محدد';areaMap[key]=(areaMap[key]||0)+Number(row.total_amount||0);});
            html = table('المبيعات حسب المنطقة', Object.keys(areaMap).map(function(key){return {area:key,total:areaMap[key]};}).sort(function(a,b){return b.total-a.total;}), [
                {key:'area',label:'المنطقة'},{key:'total',label:'الإجمالي'}
            ]);
        } else if (reportId === 'sales-order-status') {
            data = await companyOrders('order_status');
            var statusMap = {};
            data.forEach(function(row){var key=row.order_status||'غير محدد';statusMap[key]=(statusMap[key]||0)+1;});
            html = table('حالة الأوردرات', Object.keys(statusMap).map(function(key){return {status:key,count:statusMap[key]};}), [
                {key:'status',label:'الحالة'},{key:'count',label:'العدد'}
            ]);
        } else if (reportId === 'sales-customer-ledger') {
            if (!customer) throw new Error('يرجى اختيار عميل');
            data = await q('customer_ledger','entry_date,reference,description,debit,credit,balance',function(query){return query.eq('customer_id',customer).order('entry_date',{ascending:false});});
            html = table('كشف حساب العميل', data, [
                {key:'entry_date',label:'التاريخ'},{key:'reference',label:'المرجع'},{key:'description',label:'البيان'},{key:'debit',label:'مدين'},{key:'credit',label:'دائن'},{key:'balance',label:'الرصيد'}
            ]);
        } else if (reportId === 'sales-runsheet-performance') {
            data = await q('runsheets','runsheet_code,run_date,total_amount,status,driver_id',function(query){return query.eq('company_id',companyId).gte('run_date',fromDate).lte('run_date',toDate);});
            html = table('أداء الرانشيتات', data, [
                {key:'runsheet_code',label:'الرانشيت'},{key:'run_date',label:'التاريخ'},{key:'driver_id',label:'السائق'},{key:'total_amount',label:'القيمة'},{key:'status',label:'الحالة'}
            ]);
        } else if (reportId === 'inventory-stock' || reportId === 'inventory-low-stock' || reportId === 'inventory-dormant') {
            var inventoryItems = await companyItems();
            var stockRows = await companyStock();
            var stockMap = {};
            stockRows.forEach(function(row){if(!stockMap[row.item_id])stockMap[row.item_id]={qty:0,allocated:0};stockMap[row.item_id].qty+=Number(row.qty||0);stockMap[row.item_id].allocated+=Number(row.allocated_qty||0);});
            var inventoryRows = inventoryItems.map(function(item){var s=stockMap[item.id]||{qty:0,allocated:0};return {item:item,qty:Number(s.qty||0),allocated:Number(s.allocated||0),available:Math.max(0,Number(s.qty||0)-Number(s.allocated||0));});
            if(reportId==='inventory-stock'){
                html=table('جرد المخزون الحالي',inventoryRows.map(function(row){return {item_code:row.item.item_code,name:row.item.name,unit:row.item.unit,qty:row.qty,allocated:row.allocated,available:row.available,sales_price:row.item.sales_price,value:row.qty*Number(row.item.sales_price||0)};}),[
                    {key:'item_code',label:'الكود'},{key:'name',label:'الصنف'},{key:'unit',label:'الوحدة'},{key:'qty',label:'الكمية الفعلية'},{key:'allocated',label:'المحجوزة'},{key:'available',label:'المتاحة'},{key:'sales_price',label:'سعر البيع'},{key:'value',label:'قيمة المخزون'}
                ]);
            } else if(reportId==='inventory-low-stock'){
                html=table('الأصناف الأقل من حد الطلب',inventoryRows.filter(function(row){return row.available<=(Number(row.item.reorder_point)||5);}).map(function(row){return {item_code:row.item.item_code,name:row.item.name,available:row.available,reorder_point:Number(row.item.reorder_point)||5};}),[
                    {key:'item_code',label:'الكود'},{key:'name',label:'الصنف'},{key:'available',label:'المتاح'},{key:'reorder_point',label:'حد الطلب'}
                ]);
            } else {
                var dormantOrders=await companyOrders('id');
                var dormantIds=dormantOrders.map(function(row){return row.id;}).filter(Boolean);
                var sold={};
                if(dormantIds.length){var soldRows=await q('order_details','item_code',function(query){return query.in('order_id',dormantIds);});soldRows.forEach(function(row){if(row.item_code)sold[row.item_code]=true;});}
                html=table('تحليل دوران المخزون',inventoryRows.filter(function(row){return row.available>0&&!sold[row.item.item_code];}).sort(function(a,b){return b.available-a.available;}).slice(0,30).map(function(row){return {item_code:row.item.item_code,name:row.item.name,available:row.available};}),[
                    {key:'item_code',label:'الكود'},{key:'name',label:'الصنف'},{key:'available',label:'المتاح'}
                ]);
            }
        } else if (reportId === 'purchase-by-supplier' || reportId === 'purchase-order-status') {
            data = await q('purchase_orders','po_code,supplier_id,supplier_name,total_amount,status,po_date',function(query){query=query.eq('company_id',companyId).gte('po_date',fromDate).lte('po_date',toDate);if(supplier)query=query.eq('supplier_id',supplier);return query;});
            if(reportId==='purchase-order-status'){
                var poStatus={};data.forEach(function(row){var key=row.status||'غير محدد';poStatus[key]=(poStatus[key]||0)+1;});
                html=table('حالة أوامر الشراء',Object.keys(poStatus).map(function(key){return {status:key,count:poStatus[key]};}),[{key:'status',label:'الحالة'},{key:'count',label:'العدد'}]);
            } else {
                var poMap={};data.forEach(function(row){var key=row.supplier_id||'غير محدد';if(!poMap[key])poMap[key]={id:key,name:row.supplier_name||key,count:0,total:0};poMap[key].count++;poMap[key].total+=Number(row.total_amount||0);});
                html=table('المشتريات حسب المورد',Object.keys(poMap).map(function(key){return poMap[key];}).sort(function(a,b){return b.total-a.total;}),[{key:'id',label:'كود المورد'},{key:'name',label:'المورد'},{key:'count',label:'عدد الأوامر'},{key:'total',label:'إجمالي المشتريات'}]);
            }
        } else if (reportId === 'purchase-receiving') {
            var receiving=await q('receiving','operation_id,date,po_number,responsible,status',function(query){return query.eq('company_id',companyId).gte('date',fromDate).lte('date',toDate);});
            var opIds=receiving.map(function(row){return row.operation_id;}).filter(Boolean);
            data=opIds.length?await q('receiving_details','operation_id,item_code,item_name,qty_expected,qty_received,difference,reason',function(query){return query.in('operation_id',opIds);}):[];
            html=table('استلام المشتريات',data,[{key:'operation_id',label:'العملية'},{key:'item_code',label:'الكود'},{key:'item_name',label:'الصنف'},{key:'qty_expected',label:'المطلوب'},{key:'qty_received',label:'المستلم'},{key:'difference',label:'الفرق'},{key:'reason',label:'السبب'}]);
        } else if (reportId === 'finance-trial-balance') {
            html=table('ميزان المراجعة',await financeRpc('get_trial_balance',{p_from_date:fromDate,p_to_date:toDate}),Object.keys(data[0]||{}).map(function(key){return {key:key,label:key};}));
        } else if (reportId === 'finance-profit-loss') {
            html=table('قائمة الدخل',await financeRpc('get_profit_loss',{p_from_date:fromDate,p_to_date:toDate}),Object.keys(data[0]||{}).map(function(key){return {key:key,label:key};}));
        } else if (reportId === 'finance-balance-sheet') {
            html=table('الميزانية العمومية',await financeRpc('get_balance_sheet_data',{p_as_of:toDate}),Object.keys(data[0]||{}).map(function(key){return {key:key,label:key};}));
        } else if (reportId === 'finance-cash-flow') {
            html=table('التدفقات النقدية',await financeRpc('get_cash_flow',{p_from_date:fromDate,p_to_date:toDate}),Object.keys(data[0]||{}).map(function(key){return {key:key,label:key};}));
        } else if (reportId === 'finance-general-ledger') {
            if(!account) throw new Error('يرجى اختيار حساب');
            data=await q('journal_lines','entry_id,account_id,account_name,debit,credit',function(query){return query.eq('account_id',account);});
            var entryIds=data.map(function(row){return row.entry_id;}).filter(Boolean);
            var entries=entryIds.length?await q('journal_entries','id,entry_code,entry_date,reference,description,company_id',function(query){return query.eq('company_id',companyId).in('id',entryIds);}):[];
            var entryMap={};entries.forEach(function(row){entryMap[row.id]=row;});
            html=table('دفتر الأستاذ العام',data.filter(function(row){return !!entryMap[row.entry_id];}).map(function(row){var e=entryMap[row.entry_id];return {entry_code:e.entry_code,entry_date:e.entry_date,reference:e.reference,description:e.description,account_name:row.account_name,debit:row.debit,credit:row.credit};}),[
                {key:'entry_code',label:'القيد'},{key:'entry_date',label:'التاريخ'},{key:'reference',label:'المرجع'},{key:'description',label:'البيان'},{key:'account_name',label:'الحساب'},{key:'debit',label:'مدين'},{key:'credit',label:'دائن'}
            ]);
        } else if (reportId === 'finance-treasury') {
            if(!treasury) throw new Error('يرجى اختيار خزينة');
            data=await q('cash_box','*',function(query){return query.eq('treasury_id',treasury);});
            html=table('كشف حساب الخزينة',data,Object.keys(data[0]||{}).map(function(key){return {key:key,label:key};}));
        } else if (reportId === 'finance-tax' || reportId === 'crm-customer-followups' || reportId === 'hr-attendance' || reportId === 'hr-salary') {
            html='<div class="text-center py-5 text-gray-500">هذه القدرة غير متاحة حاليًا من مصدر Production سلطوي مثبت</div>';
        } else if (reportId === 'crm-customer-list' || reportId === 'crm-customer-analysis' || reportId === 'crm-customer-by-area') {
            data=await q('customers','id,customer_code,name,phone,area,debt',function(query){return query.eq('company_id',companyId);});
            if(reportId==='crm-customer-list') html=table('قائمة العملاء',data,[{key:'customer_code',label:'الكود'},{key:'name',label:'الاسم'},{key:'phone',label:'الهاتف'},{key:'area',label:'المنطقة'}]);
            else if(reportId==='crm-customer-by-area'){var ca={};data.forEach(function(row){var key=row.area||'غير محدد';ca[key]=(ca[key]||0)+1;});html=table('العملاء حسب المنطقة',Object.keys(ca).map(function(key){return {area:key,count:ca[key]};}),[{key:'area',label:'المنطقة'},{key:'count',label:'عدد العملاء'}]);}
            else {var csm={};var customerOrders=await companyOrders('customer_name,total_amount');customerOrders.forEach(function(row){var key=row.customer_name||'غير محدد';if(!csm[key])csm[key]={name:key,total:0,count:0};csm[key].total+=Number(row.total_amount||0);csm[key].count++;});html=table('تحليل العملاء',Object.keys(csm).map(function(key){return csm[key];}).sort(function(a,b){return b.total-a.total;}),[{key:'name',label:'العميل'},{key:'count',label:'عدد الأوردرات'},{key:'total',label:'الإجمالي'}]);}
        } else if (reportId === 'logistics-loading-unloading') {
            data=await q('stock_vouchers','voucher_code,type,voucher_date,reference,status',function(query){return query.eq('company_id',companyId).in('type',['Loading','Unloading']).gte('voucher_date',fromDate).lte('voucher_date',toDate);});
            html=table('التحميل والتفريغ',data,[{key:'voucher_code',label:'الإذن'},{key:'type',label:'النوع'},{key:'voucher_date',label:'التاريخ'},{key:'reference',label:'المرجع'},{key:'status',label:'الحالة'}]);
        } else if (reportId === 'logistics-returns') {
            data=await q('inventory_log','movement_date,movement_type,qty,reference,item_code,item_name',function(query){return query.eq('company_id',companyId).in('movement_type',['SalesReturn','DirectReturn']).gte('movement_date',fromDate).lte('movement_date',toDate);});
            html=table('سجل المرتجعات',data,[{key:'movement_date',label:'التاريخ'},{key:'movement_type',label:'النوع'},{key:'item_code',label:'الكود'},{key:'item_name',label:'الصنف'},{key:'qty',label:'الكمية'},{key:'reference',label:'المرجع'}]);
        } else if (reportId === 'logistics-settlement') {
            data=await q('daily_settlements','settlement_code,settlement_date,runsheet_id,total_shortage,total_shortage_value,status',function(query){return query.eq('company_id',companyId).gte('settlement_date',fromDate).lte('settlement_date',toDate);});
            html=table('إغلاق اليومية',data,[{key:'settlement_code',label:'الكود'},{key:'settlement_date',label:'التاريخ'},{key:'runsheet_id',label:'الرانشيت'},{key:'total_shortage',label:'العجز'},{key:'total_shortage_value',label:'قيمة العجز'},{key:'status',label:'الحالة'}]);
        } else if (reportId === 'logistics-driver-performance') {
            data=await q('runsheets','driver_id,run_date,total_amount,status',function(query){query=query.eq('company_id',companyId);if(driver)query=query.eq('driver_id',driver);return query.gte('run_date',fromDate).lte('run_date',toDate);});
            var dm={};data.forEach(function(row){var key=row.driver_id||'غير محدد';if(!dm[key])dm[key]={driver:key,count:0,total:0};dm[key].count++;dm[key].total+=Number(row.total_amount||0);});html=table('أداء السائقين',Object.keys(dm).map(function(key){return dm[key];}),[{key:'driver',label:'السائق'},{key:'count',label:'عدد الرانشيتات'},{key:'total',label:'الإجمالي'}]);
        } else if (reportId === 'hr-employee-list') {
            data=await q('users','name,email,role,status',function(query){return query.eq('company_id',companyId);});
            html=table('قائمة الموظفين',data,[{key:'name',label:'الاسم'},{key:'email',label:'البريد'},{key:'role',label:'الدور'},{key:'status',label:'الحالة'}]);
        } else {
            html='<div class="text-center py-5 text-gray-500">هذا التقرير غير متوفر بعد</div>';
        }

        safeHTML(resultDiv, html);
    } catch (e) {
        console.error('RW_Reports_Comprehensive._generateReport', e);
        safeHTML(resultDiv, '<div class="text-center py-8 text-red-500">فشل تحميل التقرير: ' + _esc(e && e.message ? e.message : 'فشل تحميل التقرير') + '</div>');
    }
}
