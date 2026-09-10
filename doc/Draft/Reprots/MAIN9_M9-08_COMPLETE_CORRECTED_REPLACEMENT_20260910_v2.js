// RAWAEA ERP — M9-08 complete corrected replacement v2
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

    function table(title, rows, cols) {
        rows = Array.isArray(rows) ? rows : [];
        var html = '<h4 class="font-bold mb-3">' + _esc(title) + '</h4>';
        if (!rows.length) return html + '<div class="text-center py-5 text-gray-500">لا توجد بيانات</div>';
        html += '<table class="w-full text-sm"><thead><tr class="bg-gray-50">';
        for (var i = 0; i < cols.length; i++) html += '<th class="p-2">' + _esc(cols[i].label) + '</th>';
        html += '</tr></thead><tbody>';
        for (var r = 0; r < rows.length; r++) {
            html += '<tr class="border-t">';
            for (var c = 0; c < cols.length; c++) {
                var value = rows[r] && rows[r][cols[c].key] != null ? rows[r][cols[c].key] : '';
                html += '<td class="p-2">' + _esc(String(value)) + '</td>';
            }
            html += '</tr>';
        }
        return html + '</tbody></table>';
    }

    async function query(tableName, selectText, apply) {
        var q = supabase.from(tableName).select(selectText);
        if (typeof apply === 'function') q = apply(q);
        var res = await q;
        if (res.error) throw res.error;
        return res.data || [];
    }

    async function companyOrders(selectText) {
        return query('orders', selectText, function(q) {
            q = q.eq('company_id', companyId);
            if (fromDate && toDate) q = q.gte('order_date', fromDate).lte('order_date', toDate);
            if (customer) q = q.eq('customer_id', customer);
            if (area) q = q.eq('area', area);
            return q;
        });
    }

    async function companyItems() {
        return query('items', 'id,item_code,name,unit,reorder_point,max_qty,cost_price,sales_price,barcode,is_active', function(q) {
            return q.order('item_code', { ascending: true });
        });
    }

    async function companyStock() {
        var branches = await query('branches', 'id', function(q) {
            return q.eq('company_id', companyId).eq('is_active', true);
        });
        var branchIds = branches.map(function(x) { return x.id; }).filter(Boolean);
        if (!branchIds.length) return [];
        return query('stock_branches', 'item_id,branch_id,qty,allocated_qty', function(q) {
            return q.in('branch_id', branchIds);
        });
    }

    async function financeRpc(name, args) {
        var res = await supabase.rpc(name, args);
        if (res.error) throw res.error;
        if (Array.isArray(res.data)) return res.data;
        return res.data ? [res.data] : [];
    }

    function dynamicColumns(rows) {
        if (!rows.length) return [{ key: '__empty', label: 'بيان' }];
        return Object.keys(rows[0]).map(function(key) { return { key: key, label: key }; });
    }

    try {
        var html = '';
        var data = [];

        if (reportId === 'sales-summary') {
            data = await companyOrders('total_amount');
            var totalSales = data.reduce(function(sum, row) { return sum + Number(row.total_amount || 0); }, 0);
            html = table('ملخص المبيعات', [{ count:data.length, total:totalSales, average:data.length ? Math.round(totalSales / data.length) : 0 }], [
                {key:'count',label:'عدد الأوردرات'}, {key:'total',label:'إجمالي المبيعات'}, {key:'average',label:'متوسط الأوردر'}
            ]);
        } else if (reportId === 'sales-by-customer') {
            data = await companyOrders('customer_id,customer_name,total_amount');
            var customerMap = {};
            data.forEach(function(row) { var key=row.customer_id||'غير محدد'; if(!customerMap[key]) customerMap[key]={id:key,name:row.customer_name||key,count:0,total:0}; customerMap[key].count++; customerMap[key].total+=Number(row.total_amount||0); });
            html = table('المبيعات حسب العميل', Object.keys(customerMap).map(function(k){return customerMap[k];}), [
                {key:'id',label:'كود العميل'},{key:'name',label:'اسم العميل'},{key:'count',label:'عدد الفواتير'},{key:'total',label:'إجمالي المبيعات'}
            ]);
        } else if (reportId === 'sales-by-item') {
            var saleOrders = await companyOrders('id');
            var saleOrderIds = saleOrders.map(function(x){return x.id;}).filter(Boolean);
            data = saleOrderIds.length ? await query('order_details','order_id,item_id,item_code,item_name,qty,unit_price',function(q){return q.in('order_id',saleOrderIds);}) : [];
            var itemMap = {};
            data.forEach(function(row){var key=row.item_id||row.item_code;if(!itemMap[key])itemMap[key]={code:row.item_code||'',name:row.item_name||row.item_code||'',qty:0,total:0};itemMap[key].qty+=Number(row.qty||0);itemMap[key].total+=Number(row.qty||0)*Number(row.unit_price||0);});
            html = table('المبيعات حسب الصنف', Object.keys(itemMap).map(function(k){return itemMap[k];}), [
                {key:'code',label:'الكود'},{key:'name',label:'الصنف'},{key:'qty',label:'الكمية'},{key:'total',label:'الإجمالي'}
            ]);
        } else if (reportId === 'sales-by-area') {
            data = await companyOrders('area,total_amount');
            var areaMap={};data.forEach(function(row){var key=row.area||'غير محدد';areaMap[key]=(areaMap[key]||0)+Number(row.total_amount||0);});
            html=table('المبيعات حسب المنطقة',Object.keys(areaMap).map(function(k){return {area:k,total:areaMap[k]};}),[{key:'area',label:'المنطقة'},{key:'total',label:'الإجمالي'}]);
        } else if (reportId === 'sales-order-status') {
            data=await companyOrders('order_status');var statusMap={};data.forEach(function(row){var key=row.order_status||'غير محدد';statusMap[key]=(statusMap[key]||0)+1;});
            html=table('حالة الأوردرات',Object.keys(statusMap).map(function(k){return {status:k,count:statusMap[k]};}),[{key:'status',label:'الحالة'},{key:'count',label:'العدد'}]);
        } else if (reportId === 'sales-customer-ledger') {
            if(!customer)throw new Error('يرجى اختيار عميل');
            data=await query('customer_ledger','entry_date,reference,description,debit,credit,balance',function(q){return q.eq('customer_id',customer).order('entry_date',{ascending:false});});
            html=table('كشف حساب العميل',data,[{key:'entry_date',label:'التاريخ'},{key:'reference',label:'المرجع'},{key:'description',label:'البيان'},{key:'debit',label:'مدين'},{key:'credit',label:'دائن'},{key:'balance',label:'الرصيد'}]);
        } else if (reportId === 'sales-runsheet-performance') {
            data=await query('runsheets','runsheet_code,run_date,total_amount,status,driver_id',function(q){return q.eq('company_id',companyId).gte('run_date',fromDate).lte('run_date',toDate);});
            html=table('أداء الرانشيتات',data,[{key:'runsheet_code',label:'الرانشيت'},{key:'run_date',label:'التاريخ'},{key:'driver_id',label:'السائق'},{key:'total_amount',label:'القيمة'},{key:'status',label:'الحالة'}]);
        } else if (reportId === 'inventory-stock' || reportId === 'inventory-low-stock' || reportId === 'inventory-dormant') {
            var items=await companyItems(),stock=await companyStock(),stockMap={};
            stock.forEach(function(row){if(!stockMap[row.item_id])stockMap[row.item_id]={qty:0,allocated:0};stockMap[row.item_id].qty+=Number(row.qty||0);stockMap[row.item_id].allocated+=Number(row.allocated_qty||0);});
            var inv=items.map(function(item){var s=stockMap[item.id]||{qty:0,allocated:0};return {item:item,qty:Number(s.qty||0),allocated:Number(s.allocated||0),available:Math.max(0,Number(s.qty||0)-Number(s.allocated||0)};});
            if(reportId==='inventory-stock') html=table('جرد المخزون الحالي',inv.map(function(x){return {item_code:x.item.item_code,name:x.item.name,unit:x.item.unit,qty:x.qty,allocated:x.allocated,available:x.available,value:x.qty*Number(x.item.sales_price||0)};}),[{key:'item_code',label:'الكود'},{key:'name',label:'الصنف'},{key:'unit',label:'الوحدة'},{key:'qty',label:'الكمية'},{key:'allocated',label:'المحجوزة'},{key:'available',label:'المتاحة'},{key:'value',label:'قيمة المخزون'}]);
            else if(reportId==='inventory-low-stock') html=table('الأصناف الأقل من حد الطلب',inv.filter(function(x){return x.available<=(Number(x.item.reorder_point)||5);}).map(function(x){return {item_code:x.item.item_code,name:x.item.name,available:x.available,reorder_point:Number(x.item.reorder_point)||5};}),[{key:'item_code',label:'الكود'},{key:'name',label:'الصنف'},{key:'available',label:'المتاح'},{key:'reorder_point',label:'حد الطلب'}]);
            else {var soldOrders=await companyOrders('id'),ids=soldOrders.map(function(x){return x.id;}).filter(Boolean),sold={};if(ids.length){var soldRows=await query('order_details','item_code',function(q){return q.in('order_id',ids);});soldRows.forEach(function(x){if(x.item_code)sold[x.item_code]=true;});}html=table('الأصناف الراكدة',inv.filter(function(x){return x.available>0&&!sold[x.item.item_code];}).slice(0,30).map(function(x){return {item_code:x.item.item_code,name:x.item.name,available:x.available};}),[{key:'item_code',label:'الكود'},{key:'name',label:'الصنف'},{key:'available',label:'المتاح'}]);}
        } else if (reportId === 'purchase-by-supplier' || reportId === 'purchase-order-status') {
            data=await query('purchase_orders','po_code,supplier_id,supplier_name,total_amount,status,po_date',function(q){q=q.eq('company_id',companyId).gte('po_date',fromDate).lte('po_date',toDate);if(supplier)q=q.eq('supplier_id',supplier);return q;});
            if(reportId==='purchase-order-status'){var pm={};data.forEach(function(x){var k=x.status||'غير محدد';pm[k]=(pm[k]||0)+1;});html=table('حالة أوامر الشراء',Object.keys(pm).map(function(k){return {status:k,count:pm[k]};}),[{key:'status',label:'الحالة'},{key:'count',label:'العدد'}]);}
            else {var psm={};data.forEach(function(x){var k=x.supplier_id||'غير محدد';if(!psm[k])psm[k]={id:k,name:x.supplier_name||k,count:0,total:0};psm[k].count++;psm[k].total+=Number(x.total_amount||0);});html=table('المشتريات حسب المورد',Object.keys(psm).map(function(k){return psm[k];}),[{key:'id',label:'كود المورد'},{key:'name',label:'المورد'},{key:'count',label:'عدد الأوامر'},{key:'total',label:'الإجمالي'}]);}
        } else if(reportId==='purchase-receiving'){
            var rec=await query('receiving','operation_id,date,po_number,responsible,status',function(q){return q.eq('company_id',companyId).gte('date',fromDate).lte('date',toDate);});
            html=table('استلام المشتريات',rec,[{key:'operation_id',label:'العملية'},{key:'date',label:'التاريخ'},{key:'po_number',label:'أمر الشراء'},{key:'responsible',label:'المسؤول'},{key:'status',label:'الحالة'}]);
        } else if(reportId==='finance-trial-balance'){
            data=await financeRpc('get_trial_balance',{p_from_date:fromDate,p_to_date:toDate});html=table('ميزان المراجعة',data,dynamicColumns(data));
        } else if(reportId==='finance-profit-loss'){
            data=await financeRpc('get_profit_loss',{p_from_date:fromDate,p_to_date:toDate});html=table('قائمة الدخل',data,dynamicColumns(data));
        } else if(reportId==='finance-balance-sheet'){
            data=await financeRpc('get_balance_sheet_data',{p_as_of:toDate});html=table('الميزانية العمومية',data,dynamicColumns(data));
        } else if(reportId==='finance-cash-flow'){
            data=await financeRpc('get_cash_flow',{p_from_date:fromDate,p_to_date:toDate});html=table('التدفقات النقدية',data,dynamicColumns(data));
        } else if(reportId==='finance-general-ledger'){
            if(!account)throw new Error('يرجى اختيار حساب');
            data=await query('journal_lines','entry_id,account_id,account_name,debit,credit',function(q){return q.eq('account_id',account);});
            html=table('دفتر الأستاذ العام',data,[{key:'entry_id',label:'القيد'},{key:'account_name',label:'الحساب'},{key:'debit',label:'مدين'},{key:'credit',label:'دائن'}]);
        } else if(reportId==='finance-treasury'){
            if(!treasury)throw new Error('يرجى اختيار خزينة');
            data=await query('cash_box','*',function(q){return q.eq('treasury_id',treasury);});html=table('كشف حساب الخزينة',data,dynamicColumns(data));
        } else if(reportId==='finance-tax'||reportId==='crm-customer-followups'||reportId==='hr-attendance'||reportId==='hr-salary'){
            html='<div class="text-center py-5 text-gray-500">هذه القدرة غير متاحة حاليًا من مصدر Production سلطوي مثبت</div>';
        } else if(reportId==='crm-customer-list'||reportId==='crm-customer-by-area'){
            data=await query('customers','id,customer_code,name,phone,area,debt',function(q){return q.eq('company_id',companyId);});
            if(reportId==='crm-customer-list') html=table('قائمة العملاء',data,[{key:'customer_code',label:'الكود'},{key:'name',label:'الاسم'},{key:'phone',label:'الهاتف'},{key:'area',label:'المنطقة'}]);
            else {var areaCustomers={};data.forEach(function(x){var k=x.area||'غير محدد';areaCustomers[k]=(areaCustomers[k]||0)+1;});html=table('العملاء حسب المنطقة',Object.keys(areaCustomers).map(function(k){return {area:k,count:areaCustomers[k]};}),[{key:'area',label:'المنطقة'},{key:'count',label:'عدد العملاء'}]);}
        } else if(reportId==='crm-customer-analysis'){
            data=await companyOrders('customer_name,total_amount');var ca={};data.forEach(function(x){var k=x.customer_name||'غير محدد';if(!ca[k])ca[k]={name:k,count:0,total:0};ca[k].count++;ca[k].total+=Number(x.total_amount||0);});html=table('تحليل العملاء',Object.keys(ca).map(function(k){return ca[k];}),[{key:'name',label:'العميل'},{key:'count',label:'عدد الأوردرات'},{key:'total',label:'الإجمالي'}]);
        } else if(reportId==='logistics-loading-unloading'){
            data=await query('stock_vouchers','voucher_code,type,voucher_date,reference,status',function(q){return q.eq('company_id',companyId).in('type',['Loading','Unloading']).gte('voucher_date',fromDate).lte('voucher_date',toDate);});html=table('التحميل والتفريغ',data,[{key:'voucher_code',label:'الإذن'},{key:'type',label:'النوع'},{key:'voucher_date',label:'التاريخ'},{key:'reference',label:'المرجع'},{key:'status',label:'الحالة'}]);
        } else if(reportId==='logistics-returns'){
            data=await query('inventory_log','movement_date,movement_type,qty,reference,item_code,item_name',function(q){return q.eq('company_id',companyId).in('movement_type',['SalesReturn','DirectReturn']).gte('movement_date',fromDate).lte('movement_date',toDate);});html=table('سجل المرتجعات',data,[{key:'movement_date',label:'التاريخ'},{key:'movement_type',label:'النوع'},{key:'item_code',label:'الكود'},{key:'item_name',label:'الصنف'},{key:'qty',label:'الكمية'},{key:'reference',label:'المرجع'}]);
        } else if(reportId==='logistics-settlement'){
            data=await query('daily_settlements','settlement_code,settlement_date,runsheet_id,total_shortage,total_shortage_value,status',function(q){return q.eq('company_id',companyId).gte('settlement_date',fromDate).lte('settlement_date',toDate);});html=table('إغلاق اليومية',data,[{key:'settlement_code',label:'الكود'},{key:'settlement_date',label:'التاريخ'},{key:'runsheet_id',label:'الرانشيت'},{key:'total_shortage',label:'العجز'},{key:'total_shortage_value',label:'قيمة العجز'},{key:'status',label:'الحالة'}]);
        } else if(reportId==='logistics-driver-performance'){
            data=await query('runsheets','driver_id,run_date,total_amount,status',function(q){q=q.eq('company_id',companyId);if(driver)q=q.eq('driver_id',driver);return q.gte('run_date',fromDate).lte('run_date',toDate);});var dm={};data.forEach(function(x){var k=x.driver_id||'غير محدد';if(!dm[k])dm[k]={driver:k,count:0,total:0};dm[k].count++;dm[k].total+=Number(x.total_amount||0);});html=table('أداء السائقين',Object.keys(dm).map(function(k){return dm[k];}),[{key:'driver',label:'السائق'},{key:'count',label:'عدد الرانشيتات'},{key:'total',label:'الإجمالي'}]);
        } else if(reportId==='hr-employee-list'){
            data=await query('users','name,email,role,status',function(q){return q.eq('company_id',companyId);});html=table('قائمة الموظفين',data,[{key:'name',label:'الاسم'},{key:'email',label:'البريد'},{key:'role',label:'الدور'},{key:'status',label:'الحالة'}]);
        } else {
            html='<div class="text-center py-5 text-gray-500">هذا التقرير غير متوفر بعد</div>';
        }

        safeHTML(resultDiv, html);
    } catch (e) {
        console.error('RW_Reports_Comprehensive._generateReport', e);
        safeHTML(resultDiv, '<div class="text-center py-8 text-red-500">فشل تحميل التقرير: ' + _esc(e && e.message ? e.message : 'فشل تحميل التقرير') + '</div>');
    }
}
