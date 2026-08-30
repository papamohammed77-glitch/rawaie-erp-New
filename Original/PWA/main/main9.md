// ============================================================
// RW_Reports – التقارير الذكية (مبسط)
// ============================================================
var RW_Reports = (function() {
    function _fmtNum(n) { return Number(n || 0).toLocaleString(); }
    function _esc(s) { return String(s||'').replace(/[&<>]/g, function(m) { return m==='&'?'&amp;':m==='<'?'&lt;':'&gt;'; }); }

    // ========== لوحة القيادة ==========
    async function renderDashboard() {
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), 'التقارير الذكية');
        safeText(byId('rw-header-subtitle'), 'لوحة قيادة تفاعلية لمراقبة أداء الأعمال');

        var today = new Date();
        var firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
        var fromDef = firstDay.toISOString().split('T')[0];
        var toDef = today.toISOString().split('T')[0];

        var html = '<div class="p-4 space-y-6 text-right">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6">';
        html += '<h3 class="font-bold text-lg mb-4"><i class="fa-solid fa-calendar-range ml-2 text-indigo-600"></i> تحديد الفترة</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">';
        html += '<div><label class="text-xs font-bold text-gray-500 block mb-1">من تاريخ</label><input type="date" id="dash-date-from" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" value="' + fromDef + '"></div>';
        html += '<div><label class="text-xs font-bold text-gray-500 block mb-1">إلى تاريخ</label><input type="date" id="dash-date-to" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" value="' + toDef + '"></div>';
        html += '<div><button id="dash-analyze-btn" class="w-full bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-bold shadow"><i class="fa-solid fa-magnifying-glass-chart ml-1"></i> تحليل الفترة</button></div>';
        html += '<div><button id="dash-reset-btn" class="w-full bg-gray-100 text-gray-600 px-4 py-2.5 rounded-xl font-bold">إعادة تعيين</button></div>';
        html += '</div></div>';
        html += '<div id="dash-result-container"><div class="text-center py-10"><i class="fa-solid fa-spinner fa-spin text-2xl text-indigo-600"></i><p class="mt-2 text-gray-500">جاري تحميل التحليلات...</p></div></div>';
        html += '</div>';

        safeHTML(container, html);

        var analyzeBtn = byId('dash-analyze-btn');
        if (analyzeBtn) analyzeBtn.addEventListener('click', function() {
            var fromEl = byId('dash-date-from'), from = fromEl ? fromEl.value : '';
            var toEl = byId('dash-date-to'), to = toEl ? toEl.value : '';
            if (!from || !to) { showToast('يرجى تحديد الفترة', 'warning'); return; }
            _loadDashboardData(from, to);
        });
        var resetBtn = byId('dash-reset-btn');
        if (resetBtn) resetBtn.addEventListener('click', function() {
            byId('dash-date-from').value = fromDef;
            byId('dash-date-to').value = toDef;
            _loadDashboardData(fromDef, toDef);
        });

        _loadDashboardData(fromDef, toDef);
    }

    async function _loadDashboardData(fromDate, toDate) {
        var container = byId('dash-result-container');
        if (!container) return;
        safeHTML(container, '<div class="text-center py-10"><i class="fa-solid fa-spinner fa-spin text-2xl text-indigo-600"></i><p class="mt-2 text-gray-500">جاري تحليل البيانات للفترة...</p></div>');

        try {
            var ordersRes = await supabase.from('orders').select('total_amount, order_date').gte('order_date', fromDate).lte('order_date', toDate);
            var orders = ordersRes.data || [];
            var totalSales = 0, orderCount = orders.length;
            for (var i = 0; i < orders.length; i++) { totalSales += Number(orders[i].total_amount) || 0; }
            var averageOrder = orderCount > 0 ? Math.round(totalSales / orderCount) : 0;
            var forecast = averageOrder * 30;
            var confidence = orderCount > 50 ? 'عالية' : (orderCount > 20 ? 'متوسطة' : 'منخفضة');

            var items = RW_STATE.data.items;
            if (!items || !items.length) { var itemsRes = await supabase.from('items').select('*'); items = itemsRes.data || []; }
            var stockRes = await supabase.from('stock_branches').select('item_id, qty');
            var stockData = stockRes.data || [];
            var stockMap = {};
            for (var s = 0; s < stockData.length; s++) { stockMap[stockData[s].item_id] = (stockMap[stockData[s].item_id] || 0) + (Number(stockData[s].qty) || 0); }
            var lowStockCount = 0;
            for (var j = 0; j < items.length; j++) { if ((stockMap[items[j].id] || 0) <= (Number(items[j].reorder_point) || 5)) lowStockCount++; }

            var sixtyDaysAgo = new Date(); sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);
            var recentRes = await supabase.from('orders').select('customer_id').gte('order_date', sixtyDaysAgo.toISOString().split('T')[0]);
            var recentCustomers = {};
            (recentRes.data || []).forEach(function(r) { if (r.customer_id) recentCustomers[r.customer_id] = true; });
            var customers = RW_STATE.data.customers;
            if (!customers || !customers.length) { var custRes = await supabase.from('customers').select('customer_code'); customers = custRes.data || []; }
            var inactiveCount = 0;
            for (var c = 0; c < customers.length; c++) { if (!recentCustomers[customers[c].customer_code]) inactiveCount++; }

            var html = '<div class="text-right space-y-6 p-4">';
            html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4">';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">المبيعات المتوقعة (شهرياً)</p><p class="text-3xl font-black text-indigo-600">' + _fmtNum(forecast) + ' EGP</p><p class="text-xs text-gray-400 mt-1">مستوى الثقة: ' + confidence + '</p></div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">إجمالي المبيعات</p><p class="text-3xl font-black text-emerald-600">' + _fmtNum(totalSales) + ' EGP</p><p class="text-xs text-gray-400 mt-1">' + orderCount + ' أوردر</p></div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">أصناف منخفضة</p><p class="text-3xl font-black text-red-600">' + lowStockCount + '</p></div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5 text-center"><p class="text-xs text-gray-400 font-bold mb-1">عملاء غير نشطين</p><p class="text-3xl font-black text-amber-600">' + inactiveCount + '</p></div>';
            html += '</div>';
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><p class="text-sm text-gray-500"><strong>الفترة:</strong> من ' + fromDate + ' إلى ' + toDate + '</p></div>';
            html += '</div>';
            safeHTML(container, html);
        } catch(e) { console.error(e); safeHTML(container, '<div class="text-center py-10 text-red-500">فشل تحميل التحليلات</div>'); }
    }

    // ========== التقارير التفصيلية (Checkbox) ==========
    function _buildCheckboxGroup(title, prefix, items) {
        var html = '<div class="bg-gray-50 rounded-xl p-4 border">';
        html += '<h4 class="font-bold text-sm mb-3 text-gray-700">' + title + '</h4>';
        for (var i = 0; i < items.length; i++) {
            var checked = items[i].checked ? 'checked' : '';
            html += '<label class="flex items-center gap-2 mb-2 cursor-pointer hover:bg-white rounded-lg px-2 py-1 transition">';
            html += '<input type="checkbox" class="det-check" value="' + items[i].value + '" ' + checked + '>';
            html += '<span class="text-sm">' + items[i].label + '</span></label>';
        }
        html += '</div>'; return html;
    }

    async function renderDetailedReports() {
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), 'التقارير التفصيلية');
        safeText(byId('rw-header-subtitle'), 'تحليلات متقدمة وتوصيات ذكية');

        var today = new Date();
        var firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
        var fromDef = firstDay.toISOString().split('T')[0];
        var toDef = today.toISOString().split('T')[0];

        var html = '<div class="p-4 space-y-6 text-right">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6">';
        html += '<h3 class="font-bold text-lg mb-4"><i class="fa-solid fa-sliders ml-2 text-indigo-600"></i> التقارير التفصيلية</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">';
        html += '<div><label class="text-xs font-bold text-gray-500 block mb-1">من تاريخ</label><input type="date" id="det-from" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" value="' + fromDef + '"></div>';
        html += '<div><label class="text-xs font-bold text-gray-500 block mb-1">إلى تاريخ</label><input type="date" id="det-to" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" value="' + toDef + '"></div>';
        html += '</div>';

        html += '<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">';
        html += _buildCheckboxGroup('📊 المبيعات', 'sales', [
            { value: 'sales-summary', label: 'ملخص المبيعات', checked: true },
            { value: 'sales-by-customer', label: 'المبيعات حسب العميل' },
            { value: 'sales-by-item', label: 'المبيعات حسب الصنف' }
        ]);
        html += _buildCheckboxGroup('👥 العملاء', 'customers', [
            { value: 'customers-debt', label: 'العملاء والديون', checked: true },
            { value: 'customers-activity', label: 'نشاط العملاء' },
            { value: 'customers-stopped', label: 'العملاء المتوقفين' }
        ]);
        html += _buildCheckboxGroup('📦 المخزون', 'inventory', [
            { value: 'inventory-dormant', label: 'الأصناف الراكدة' },
            { value: 'inventory-low', label: 'أصناف منخفضة المخزون' },
            { value: 'inventory-top', label: 'الأصناف الأعلى مبيعاً' }
        ]);
        html += _buildCheckboxGroup('🤖 توصيات ذكية', 'recommendations', [
            { value: 'rec-purchase', label: 'توصيات الشراء', checked: true },
            { value: 'rec-offers', label: 'توصيات العروض' },
            { value: 'rec-customers', label: 'توصيات العملاء' },
            { value: 'rec-expansion', label: 'توصيات التوسع' }
        ]);
        html += '</div>';

        html += '<div class="flex gap-2">';
        html += '<button id="det-generate-btn" class="bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-bold shadow"><i class="fa-solid fa-chart-simple ml-1"></i> عرض التقارير المحددة</button>';
        html += '<button id="det-reset-btn" class="bg-gray-100 text-gray-600 px-4 py-2.5 rounded-xl font-bold">إعادة تعيين</button>';
        html += '</div></div>';
        html += '<div id="det-result-container"></div></div>';

        safeHTML(container, html);

        var genBtn = byId('det-generate-btn');
        if (genBtn) genBtn.addEventListener('click', function() {
            var fromEl = byId('det-from'), from = fromEl ? fromEl.value : '';
            var toEl = byId('det-to'), to = toEl ? toEl.value : '';
            if (!from || !to) { showToast('يرجى تحديد الفترة', 'warning'); return; }
            var checks = document.querySelectorAll('.det-check:checked');
            var types = [];
            for (var i = 0; i < checks.length; i++) { types.push(checks[i].value); }
            if (!types.length) { showToast('اختر تقريراً واحداً على الأقل', 'warning'); return; }
            _loadDetailedReports(from, to, types);
        });
        var resetBtn = byId('det-reset-btn');
        if (resetBtn) resetBtn.addEventListener('click', function() {
            byId('det-from').value = fromDef;
            byId('det-to').value = toDef;
            document.querySelectorAll('.det-check').forEach(function(cb) {
                cb.checked = (cb.value === 'sales-summary' || cb.value === 'customers-debt' || cb.value === 'rec-purchase');
            });
            safeHTML(byId('det-result-container'), '');
        });

        _loadDetailedReports(fromDef, toDef, ['sales-summary', 'customers-debt', 'rec-purchase']);
    }

async function _loadDetailedReports(fromDate, toDate, types) {
    var container = byId('det-result-container');
    if (!container) return;
    safeHTML(container, '<div class="text-center py-10"><i class="fa-solid fa-spinner fa-spin text-2xl"></i> جاري تحميل التقارير المحددة...</div>');

    try {
        var items = (Array.isArray(RW_STATE.data.items) ? RW_STATE.data.items : []);
        // ✅ إزالة أي عناصر فارغة من المصفوفة
        items = items.filter(function(itm) { return itm != null; });
        var customers = RW_STATE.data.customers || [];
        if (!items.length) { var iRes = await supabase.from('items').select('*'); items = iRes.data || []; }
        if (!customers.length) { var cRes = await supabase.from('customers').select('*'); customers = cRes.data || []; }
        var stockRes = await supabase.from('stock_branches').select('item_id, qty');
        var stockData = stockRes.data || [];
        var stockMap = {};
        for (var s = 0; s < stockData.length; s++) {
            if (stockData[s] && stockData[s].item_id) {
                stockMap[stockData[s].item_id] = (stockMap[stockData[s].item_id] || 0) + (Number(stockData[s].qty) || 0);
            }
        }

        var ordersRes = await supabase.from('orders').select('order_code, customer_id, customer_name, total_amount, order_date, area').gte('order_date', fromDate).lte('order_date', toDate);
        var orders = ordersRes.data || [];
        var detailsRes = await supabase.from('order_details').select('item_code, item_name, qty, unit_price, order_id');
        var details = detailsRes.data || [];
        var soldCodes = {}; // ← نُقل إلى هنا ليكون متاحاً لكل الأقسام

        var html = '<div class="text-right space-y-6">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><p class="text-sm text-gray-500"><strong>الفترة:</strong> من ' + fromDate + ' إلى ' + toDate + '</p></div>';

        // ملخص المبيعات
        if (types.indexOf('sales-summary') !== -1) {
            var totalSales = 0;
            for (var o = 0; o < orders.length; o++) { totalSales += Number(orders[o].total_amount) || 0; }
            var avgOrder = orders.length > 0 ? Math.round(totalSales / orders.length) : 0;
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-chart-line ml-2 text-indigo-600"></i> ملخص المبيعات</h3>';
            html += '<div class="grid grid-cols-3 gap-4"><div class="bg-indigo-50 rounded-xl p-4 text-center"><p class="text-xs text-indigo-400 font-bold">عدد الأوردرات</p><p class="text-2xl font-black text-indigo-700">' + orders.length + '</p></div>';
            html += '<div class="bg-emerald-50 rounded-xl p-4 text-center"><p class="text-xs text-emerald-400 font-bold">إجمالي المبيعات</p><p class="text-2xl font-black text-emerald-700">' + _fmtNum(totalSales) + ' EGP</p></div>';
            html += '<div class="bg-amber-50 rounded-xl p-4 text-center"><p class="text-xs text-amber-400 font-bold">متوسط الأوردر</p><p class="text-2xl font-black text-amber-700">' + _fmtNum(avgOrder) + ' EGP</p></div></div></div>';
        }

        // المبيعات حسب العميل
        if (types.indexOf('sales-by-customer') !== -1) {
            var custSales = {};
            for (var o2 = 0; o2 < orders.length; o2++) {
                var cid = orders[o2].customer_id || orders[o2].customer_name;
                if (!cid) continue;
                custSales[cid] = { name: orders[o2].customer_name || cid, total: (custSales[cid] ? custSales[cid].total : 0) + Number(orders[o2].total_amount || 0), count: (custSales[cid] ? custSales[cid].count : 0) + 1 };
            }
            var custArr = Object.values(custSales).sort(function(a,b){ return b.total - a.total; }).slice(0, 10);
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-user-group ml-2 text-blue-600"></i> أعلى العملاء مبيعاً</h3>';
            if (custArr.length > 0) {
                html += '<table class="w-full text-sm"><thead><tr><th class="p-2">العميل</th><th class="p-2 text-center">الأوردرات</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
                for (var cu = 0; cu < custArr.length; cu++) { html += '<tr><td class="p-2 font-semibold">' + _esc(custArr[cu].name) + '</td><td class="p-2 text-center">' + custArr[cu].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(custArr[cu].total) + ' EGP</td></tr>'; }
                html += '</tbody></table>';
            } else { html += '<div class="text-center py-4 text-gray-500">لا توجد بيانات</div>'; }
            html += '</div>';
        }

        // المبيعات حسب الصنف
        if (types.indexOf('sales-by-item') !== -1) {
            var itemSales = {};
            for (var d = 0; d < details.length; d++) {
                var det = details[d];
                if (!det || !det.item_code) continue;
                if (!itemSales[det.item_code]) itemSales[det.item_code] = { name: det.item_name || det.item_code, qty: 0, total: 0 };
                itemSales[det.item_code].qty += Number(det.qty) || 0;
                itemSales[det.item_code].total += (Number(det.qty) || 0) * (Number(det.unit_price) || 0);
            }
            var itemArr = Object.values(itemSales).sort(function(a,b){ return b.total - a.total; }).slice(0, 10);
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-boxes-stacked ml-2 text-purple-600"></i> أعلى الأصناف مبيعاً</h3>';
            if (itemArr.length > 0) {
                html += '<table class="w-full text-sm"><thead><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
                for (var it = 0; it < itemArr.length; it++) { html += '<tr><td class="p-2 font-semibold">' + _esc(itemArr[it].name) + '</td><td class="p-2 text-center">' + itemArr[it].qty + '</td><td class="p-2 text-center font-bold">' + _fmtNum(itemArr[it].total) + ' EGP</td></tr>'; }
                html += '</tbody></table>';
            } else { html += '<div class="text-center py-4 text-gray-500">لا توجد بيانات</div>'; }
            html += '</div>';
        }

        // العملاء والديون
        if (types.indexOf('customers-debt') !== -1) {
            var debtors = customers.filter(function(c){ return c && (Number(c.debt)||0) > 0; }).sort(function(a,b){ return Number(b.debt) - Number(a.debt); });
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-file-invoice-dollar ml-2 text-red-600"></i> العملاء والديون</h3>';
            if (debtors.length > 0) {
                html += '<table class="w-full text-sm"><thead><tr><th class="p-2">العميل</th><th class="p-2 text-center">الدين</th></tr></thead><tbody>';
                for (var db = 0; db < Math.min(debtors.length, 10); db++) { html += '<tr><td class="p-2 font-semibold">' + _esc(debtors[db].name) + '</td><td class="p-2 text-center font-bold text-red-600">' + _fmtNum(debtors[db].debt) + ' EGP</td></tr>'; }
                html += '</tbody></table>';
            } else { html += '<div class="text-center py-4 text-green-600">لا توجد ديون</div>'; }
            html += '</div>';
        }

        // الأصناف الراكدة – مع فحص دفاعي
        if (types.indexOf('inventory-dormant') !== -1) {
                    for (var d2 = 0; d2 < details.length; d2++) { 
                if (details[d2] && details[d2].item_code) soldCodes[details[d2].item_code] = true; 
            }
            var dormant = [];
            if (items && Array.isArray(items)) {
                dormant = items.filter(function(itm){ 
                    if (!itm || !itm.id || !itm.item_code) return false;
                    return (stockMap[itm.id]||0) > 0 && !soldCodes[itm.item_code]; 
                });
            }
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-box-archive ml-2 text-red-600"></i> الأصناف الراكدة</h3>';
            if (dormant.length > 0) {
                html += '<table class="w-full text-sm"><thead><tr><th class="p-2">الصنف</th><th class="p-2 text-center">المخزون</th></tr></thead><tbody>';
                for (var dr = 0; dr < Math.min(dormant.length, 15); dr++) { html += '<tr><td class="p-2 font-semibold">' + _esc(dormant[dr].name) + '</td><td class="p-2 text-center font-bold text-red-600">' + (stockMap[dormant[dr].id]||0) + '</td></tr>'; }
                html += '</tbody></table>';
            } else { html += '<div class="text-center py-4 text-green-600">لا توجد أصناف راكدة</div>'; }
            html += '</div>';
        }

        // توصيات ذكية – مع فحص دفاعي
        if (types.indexOf('rec-purchase') !== -1 || types.indexOf('rec-offers') !== -1) {
            var recs = [];
            // توصيات شراء
            for (var j = 0; j < items.length; j++) {
                if (!items[j] || !items[j].id) continue;
                if ((stockMap[items[j].id]||0) <= (Number(items[j].reorder_point)||5)) {
                    recs.push({ type: 'شراء', item: items[j].name, reason: 'المخزون منخفض (' + (stockMap[items[j].id]||0) + ')' });
                    if (recs.length >= 3) break;
                }
            }
            // توصيات عروض
            var dormant2 = [];
            if (items && Array.isArray(items)) {
                dormant2 = items.filter(function(itm){ 
                    if (!itm || !itm.id || !itm.item_code) return false;
                    return (stockMap[itm.id]||0) > 0 && !soldCodes[itm.item_code]; 
                });
            }
            if (dormant2.length > 0) {
                recs.push({ type: 'عرض ترويجي', item: dormant2[0].name, reason: 'راكد بقيمة ' + _fmtNum((stockMap[dormant2[0].id]||0) * (Number(dormant2[0].cost_price) || Number(dormant2[0].sales_price) || 0)) + ' EGP' });
            }
            html += '<div class="bg-white rounded-2xl shadow-sm border p-5"><h3 class="font-black text-lg mb-3"><i class="fa-solid fa-lightbulb ml-2 text-amber-500"></i> توصيات ذكية</h3>';
            if (recs.length > 0) {
                html += '<div class="space-y-3">';
                for (var rc = 0; rc < recs.length; rc++) {
                    var color = recs[rc].type === 'شراء' ? 'border-indigo-200 bg-indigo-50' : 'border-amber-200 bg-amber-50';
                    var icon = recs[rc].type === 'شراء' ? 'fa-cart-shopping' : 'fa-tag';
                    html += '<div class="border-r-4 ' + color + ' p-4 rounded-lg"><div class="flex items-center gap-2 mb-1"><i class="fa-solid ' + icon + '"></i><span class="font-bold">' + recs[rc].type + ': ' + _esc(recs[rc].item) + '</span></div><p class="text-sm text-gray-600">' + recs[rc].reason + '</p></div>';
                }
                html += '</div>';
            } else { html += '<div class="text-center py-4 text-gray-500">لا توجد توصيات حالياً</div>'; }
            html += '</div>';
        }

        html += '</div>';
        safeHTML(container, html);

    } catch(e) { console.error(e); safeHTML(container, '<div class="text-center py-10 text-red-500">فشل تحميل التقارير</div>'); }
}
    return {
        renderDashboard: renderDashboard,
        renderDetailedReports: renderDetailedReports
    };
})();
window.RW_Reports = RW_Reports;
var RW_Reports_Comprehensive = (function() {
    function _fmtNum(n) { return Number(n || 0).toLocaleString(); }
    function _esc(s) { return String(s||'').replace(/[&<>]/g, function(m) { return m==='&'?'&amp;':m==='<'?'&lt;':'&gt;'; }); }
    function _showLoader(m) { try { if (typeof showLoader === 'function') showLoader(m || 'جاري التحميل...'); } catch(e) { console.error(e); } }
    function _hideLoader() { try { if (typeof hideLoader === 'function') hideLoader(); } catch(e) { console.error(e); } }
    function _showToast(m, t) { try { if (typeof showToast === 'function') showToast(m, t || 'success'); } catch(e) { alert(m); } }

    var _container = null;
    var _currentSection = null;
    var _currentReport = null;

    var _reportsStructure = {
        'sales': {
            title: 'تقارير المبيعات والتوزيع',
            icon: 'fa-chart-line',
            color: 'text-blue-600',
            bgColor: 'bg-blue-50',
            reports: [
                { id: 'sales-summary', label: 'ملخص المبيعات اليومي/الشهري', desc: 'إجمالي المبيعات، عدد الفواتير، متوسط قيمة الفاتورة', params: ['date'] },
                { id: 'sales-by-customer', label: 'المبيعات حسب العميل', desc: 'كشف كامل بالمبيعات لكل عميل', params: ['date', 'customer'] },
                { id: 'sales-by-item', label: 'المبيعات حسب الصنف', desc: 'الأصناف الأكثر مبيعاً خلال الفترة', params: ['date'] },
                { id: 'sales-by-area', label: 'المبيعات حسب المنطقة', desc: 'توزيع المبيعات جغرافيا', params: ['date'] },
                { id: 'sales-order-status', label: 'حالة الأوردرات', desc: 'دورة حياة الأوردر من Draft إلى Delivered', params: ['date'] },
                { id: 'sales-customer-ledger', label: 'كشف حساب عميل', desc: 'جميع حركات العميل المالية', params: ['customer'] },
                { id: 'sales-runsheet-performance', label: 'أداء الرانشيتات', desc: 'عدد الطلبات، القيمة، نسب التوصيل والمرتجع', params: ['date'] }
            ]
        },
        'inventory': {
            title: 'تقارير المخازن والمشتريات',
            icon: 'fa-warehouse',
            color: 'text-emerald-600',
            bgColor: 'bg-emerald-50',
            reports: [
                { id: 'inventory-stock', label: 'جرد المخزون الحالي', desc: 'الكميات، الأرصدة، القيمة الإجمالية لكل صنف', params: [] },
                { id: 'inventory-movement', label: 'حركة صنف', desc: 'كل عمليات الدخول والخروج خلال فترة', params: ['item', 'date'] },
                { id: 'inventory-low-stock', label: 'الأصناف الأقل من حد الطلب', desc: 'تنبيهات إعادة الطلب', params: [] },
                { id: 'inventory-dormant', label: 'تحليل دوران المخزون', desc: 'الأصناف الراكدة والسريعة الحركة', params: ['date'] },
                { id: 'purchase-by-supplier', label: 'المشتريات حسب المورد', desc: 'كشف كامل بالمشتريات لكل مورد', params: ['date', 'supplier'] },
                { id: 'purchase-order-status', label: 'حالة أوامر الشراء', desc: 'Draft, Sent, Received', params: ['date'] },
                { id: 'purchase-receiving', label: 'تقرير استلام البضاعة', desc: 'مقارنة الكميات المستلمة بالمطلوبة', params: ['date'] }
            ]
        },
        'finance': {
            title: 'تقارير الحسابات والمالية',
            icon: 'fa-coins',
            color: 'text-purple-600',
            bgColor: 'bg-purple-50',
            reports: [
                { id: 'finance-trial-balance', label: 'ميزان المراجعة', desc: 'أرصدة جميع الحسابات', params: ['date'] },
                { id: 'finance-profit-loss', label: 'قائمة الدخل', desc: 'الإيرادات والمصروفات وصافي الربح', params: ['date'] },
                { id: 'finance-balance-sheet', label: 'الميزانية العمومية', desc: 'الأصول والخصوم وحقوق الملكية', params: ['date'] },
                { id: 'finance-cash-flow', label: 'قائمة التدفقات النقدية', desc: 'حركة النقد الداخلة والخارجة', params: ['date'] },
                { id: 'finance-general-ledger', label: 'دفتر الأستاذ العام', desc: 'حركات أي حساب', params: ['account', 'date'] },
                { id: 'finance-treasury', label: 'كشف حساب بنكي/خزينة', desc: 'رصيد وحركات الخزينة', params: ['treasury', 'date'] },
                { id: 'finance-tax', label: 'تقرير الضرائب', desc: 'ضريبة القيمة المضافة', params: ['date'] }
            ]
        },
        'crm': {
            title: 'تقارير العملاء (CRM)',
            icon: 'fa-users',
            color: 'text-orange-600',
            bgColor: 'bg-orange-50',
            reports: [
                { id: 'crm-customer-list', label: 'قائمة العملاء', desc: 'جميع العملاء مع التفاصيل', params: [] },
                { id: 'crm-customer-analysis', label: 'تحليل العملاء', desc: 'الجدد، الأكثر شراءً، المتوقفين', params: ['date'] },
                { id: 'crm-customer-followups', label: 'سجل المتابعات', desc: 'الاتصالات والزيارات المسجلة', params: ['customer'] },
                { id: 'crm-customer-by-area', label: 'العملاء حسب المنطقة', desc: 'توزيع العملاء جغرافيا', params: ['area'] }
            ]
        },
        'logistics': {
            title: 'تقارير التوصيل واللوجستيات',
            icon: 'fa-truck-fast',
            color: 'text-amber-600',
            bgColor: 'bg-amber-50',
            reports: [
                { id: 'logistics-loading-unloading', label: 'تقرير التحميل والتفريغ', desc: 'سجل تحميل وتفريغ الرانشيتات', params: ['date'] },
                { id: 'logistics-returns', label: 'تقرير المرتجعات', desc: 'المرتجعات حسب الصنف والعميل والمندوب', params: ['date'] },
                { id: 'logistics-settlement', label: 'تقرير إغلاق اليومية', desc: 'تسوية عهدة المندوبين', params: ['date'] },
                { id: 'logistics-driver-performance', label: 'أداء السائقين', desc: 'عدد الطلبات، قيمة التسليم، قيمة المرتجع', params: ['date', 'driver'] }
            ]
        },
        'hr': {
            title: 'تقارير الموارد البشرية (HR)',
            icon: 'fa-id-card',
            color: 'text-pink-600',
            bgColor: 'bg-pink-50',
            reports: [
                { id: 'hr-employee-list', label: 'قائمة الموظفين', desc: 'جميع الموظفين مع التفاصيل', params: [] },
                { id: 'hr-attendance', label: 'تقرير الحضور والانصراف', desc: 'سجل حضور الموظفين', params: ['date'] },
                { id: 'hr-salary', label: 'تقرير الرواتب', desc: 'مسيرات الرواتب والأجور', params: ['date'] }
            ]
        }
    };

    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;
        _container = container;
        safeText(byId('rw-header-title'), 'التقارير الشاملة');
        safeText(byId('rw-header-subtitle'), 'مركز التقارير المتكاملة لجميع إدارات المؤسسة');

        var html = '<div class="p-4 text-right">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mb-6">';
        html += '<h2 class="text-xl font-black text-gray-800 mb-2"><i class="fa-solid fa-file-invoice ml-2 text-indigo-600"></i> مركز التقارير الشاملة</h2>';
        html += '<p class="text-gray-500 text-sm">اختر القسم لعرض جميع التقارير الخاصة به. كل قسم يحتوي على مجموعة متكاملة من التقارير الجاهزة.</p>';
        html += '</div>';

        html += '<div class="grid grid-cols-1 md:grid-cols-3 gap-4" id="reports-sections">';
        var sections = [
            { key: 'sales', title: 'تقارير المبيعات', icon: 'fa-chart-line', color: 'bg-blue-500', desc: 'المبيعات، الأوردرات، الرانشيتات، العملاء' },
            { key: 'inventory', title: 'تقارير المخازن والمشتريات', icon: 'fa-warehouse', color: 'bg-emerald-500', desc: 'المخزون، الأصناف، المشتريات، الموردين' },
            { key: 'finance', title: 'تقارير الحسابات والمالية', icon: 'fa-coins', color: 'bg-purple-500', desc: 'ميزان المراجعة، الدخل، الميزانية، التدفقات' },
            { key: 'crm', title: 'تقارير العملاء (CRM)', icon: 'fa-users', color: 'bg-orange-500', desc: 'العملاء، المتابعات، التحليلات' },
            { key: 'logistics', title: 'تقارير التوصيل واللوجستيات', icon: 'fa-truck-fast', color: 'bg-amber-500', desc: 'السائقين، المرتجعات، إغلاق اليومية' },
            { key: 'hr', title: 'تقارير الموارد البشرية', icon: 'fa-id-card', color: 'bg-pink-500', desc: 'الموظفين، الحضور، الرواتب' }
        ];
        for (var i = 0; i < sections.length; i++) {
            var sec = sections[i];
            html += '<div onclick="RW_Reports_Comprehensive._openSection(\'' + sec.key + '\')" class="cursor-pointer bg-white rounded-2xl shadow-sm border p-6 hover:shadow-md transition transform hover:-translate-y-1">';
            html += '<div class="flex items-center gap-4 mb-3">';
            html += '<div class="w-16 h-16 ' + sec.color + ' rounded-2xl flex items-center justify-center text-white text-2xl"><i class="fa-solid ' + sec.icon + '"></i></div>';
            html += '<div><h3 class="font-black text-lg text-gray-800">' + sec.title + '</h3><p class="text-xs text-gray-500 mt-1">' + sec.desc + '</p></div>';
            html += '</div></div>';
        }
        html += '</div>';
        html += '<div id="section-reports-container"></div>';
        html += '</div>';

        safeHTML(container, html);
    }

    function _openSection(sectionKey) {
        var section = _reportsStructure[sectionKey];
        if (!section) return;
        _currentSection = sectionKey;

        var container = byId('section-reports-container');
        if (!container) { container = byId('rw-page-container'); if (!container) return; }

        var html = '<div class="mt-6 bg-white rounded-2xl shadow-sm border p-6">';
        html += '<div class="flex justify-between items-center mb-6">';
        html += '<div class="flex items-center gap-3">';
        html += '<i class="fa-solid ' + section.icon + ' text-2xl ' + section.color + '"></i>';
        html += '<div><h2 class="text-xl font-black text-gray-800">' + section.title + '</h2><p class="text-sm text-gray-500">اختر تقريراً لعرضه مع تحديد المعايير المطلوبة</p></div>';
        html += '</div>';
        html += '<button onclick="RW_Reports_Comprehensive._closeSection()" class="bg-gray-100 text-gray-600 px-4 py-2 rounded-xl font-bold text-sm hover:bg-gray-200"><i class="fa-solid fa-arrow-right ml-1"></i> عودة للأقسام</button>';
        html += '</div>';

        html += '<div class="grid grid-cols-1 gap-3" id="reports-list">';
        for (var i = 0; i < section.reports.length; i++) {
            var rep = section.reports[i];
            html += '<div class="border rounded-xl p-4 hover:bg-' + section.bgColor + ' cursor-pointer transition" onclick="RW_Reports_Comprehensive._openReport(\'' + sectionKey + '\', \'' + rep.id + '\')">';
            html += '<div class="flex justify-between items-center">';
            html += '<div><h4 class="font-bold text-gray-800">' + rep.label + '</h4><p class="text-xs text-gray-500 mt-1">' + rep.desc + '</p></div>';
            html += '<i class="fa-solid fa-chevron-left text-gray-400"></i>';
            html += '</div></div>';
        }
        html += '</div>';
        html += '<div id="report-detail-container" class="mt-6"></div>';
        html += '</div>';

        safeHTML(container, html);
        safeText(byId('rw-header-title'), section.title);
    }

    function _closeSection() {
        _currentSection = null;
        _currentReport = null;
        var container = byId('section-reports-container');
        if (container) safeHTML(container, '');
        safeText(byId('rw-header-title'), 'التقارير الشاملة');
    }

    function _openReport(sectionKey, reportId) {
        var section = _reportsStructure[sectionKey];
        if (!section) return;
        var report = null;
        for (var i = 0; i < section.reports.length; i++) {
            if (section.reports[i].id === reportId) { report = section.reports[i]; break; }
        }
        if (!report) return;
        _currentReport = reportId;

        var container = byId('report-detail-container');
        if (!container) return;

        var html = '<div class="border-t pt-6 mt-6">';
        html += '<h3 class="font-black text-lg mb-4"><i class="fa-solid fa-sliders ml-2 text-indigo-600"></i> معايير التقرير: ' + report.label + '</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4" id="report-params">';

        var params = report.params || [];
        if (params.indexOf('date') !== -1) {
            var today = new Date().toISOString().split('T')[0];
            var firstDay = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">من تاريخ</label><input type="date" id="rp-date-from" value="' + firstDay + '" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"></div>';
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">إلى تاريخ</label><input type="date" id="rp-date-to" value="' + today + '" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"></div>';
        }
        if (params.indexOf('customer') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">العميل</label><select id="rp-customer" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">جميع العملاء</option></select></div>';
        }
        if (params.indexOf('supplier') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">المورد</label><select id="rp-supplier" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">جميع الموردين</option></select></div>';
        }
        if (params.indexOf('item') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">الصنف</label><select id="rp-item" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">جميع الأصناف</option></select></div>';
        }
        if (params.indexOf('account') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">الحساب</label><select id="rp-account" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">اختر حساباً</option></select></div>';
        }
        if (params.indexOf('treasury') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">الخزينة</label><select id="rp-treasury" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">جميع الخزائن</option></select></div>';
        }
        if (params.indexOf('driver') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">السائق</label><select id="rp-driver" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">جميع السائقين</option></select></div>';
        }
        if (params.indexOf('area') !== -1) {
            html += '<div><label class="block text-xs font-bold text-gray-500 mb-1">المنطقة</label><select id="rp-area" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">جميع المناطق</option></select></div>';
        }

        html += '</div>';
        html += '<div class="flex gap-2">';
        html += '<button onclick="RW_Reports_Comprehensive._generateReport(\'' + sectionKey + '\', \'' + reportId + '\')" class="bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-bold shadow"><i class="fa-solid fa-play ml-1"></i> عرض التقرير</button>';
        html += '<button onclick="RW_Reports_Comprehensive._printReport()" class="bg-gray-100 text-gray-600 px-4 py-2.5 rounded-xl font-bold"><i class="fa-solid fa-print ml-1"></i> طباعة</button>';
        html += '</div>';
        html += '<div id="report-result" class="mt-6 overflow-x-auto"></div>';
        html += '</div>';

        safeHTML(container, html);
        _loadDropdowns(params);
    }

    async function _loadDropdowns(params) {
        if (params.indexOf('customer') !== -1) {
            var customers = RW_STATE.data.customers || [];
            var sel = byId('rp-customer'); if (sel) { for (var i = 0; i < customers.length; i++) { sel.innerHTML += '<option value="' + (customers[i].customer_code || '') + '">' + (customers[i].name || '') + '</option>'; } }
        }
        if (params.indexOf('supplier') !== -1) {
            var suppliers = RW_STATE.data.suppliers || [];
            var sel = byId('rp-supplier'); if (sel) { for (var i = 0; i < suppliers.length; i++) { sel.innerHTML += '<option value="' + (suppliers[i].supplier_code || '') + '">' + (suppliers[i].name || '') + '</option>'; } }
        }
        if (params.indexOf('item') !== -1) {
            var items = RW_STATE.data.items || [];
            var sel = byId('rp-item'); if (sel) { for (var i = 0; i < items.length; i++) { sel.innerHTML += '<option value="' + (items[i].item_code || '') + '">' + (items[i].name || '') + '</option>'; } }
        }
        if (params.indexOf('treasury') !== -1) {
            try { var tres = await supabase.from('treasury').select('account_code, account_name'); var tdata = tres.data || []; var sel = byId('rp-treasury'); if (sel) { for (var i = 0; i < tdata.length; i++) { sel.innerHTML += '<option value="' + (tdata[i].account_code || '') + '">' + (tdata[i].account_name || '') + '</option>'; } } } catch(e) {}
        }
        if (params.indexOf('account') !== -1) {
            try { var ares = await supabase.from('chart_of_accounts').select('account_code, account_name'); var adata = ares.data || []; var sel = byId('rp-account'); if (sel) { for (var i = 0; i < adata.length; i++) { sel.innerHTML += '<option value="' + (adata[i].account_code || '') + '">' + (adata[i].account_name || '') + '</option>'; } } } catch(e) {}
        }
        if (params.indexOf('driver') !== -1) {
            try { var dres = await supabase.from('users').select('email, name').in('role', ['driver','سائق','مندوب']); var ddata = dres.data || []; var sel = byId('rp-driver'); if (sel) { for (var i = 0; i < ddata.length; i++) { sel.innerHTML += '<option value="' + (ddata[i].email || '') + '">' + (ddata[i].name || '') + '</option>'; } } } catch(e) {}
        }
    }

    // ==================== دوال التفاصيل (Drill-Down) ====================
    async function _showCustomerLedgerDetail(customerCode, customerName) {
        _showLoader('جاري تحميل كشف حساب العميل...');
        try {
            var res = await supabase.from('customer_ledger').select('*').eq('customer_id', customerCode).order('entry_date', { ascending: false });
            var data = res.data || [];
            _hideLoader();
            if (!data.length) { _showToast('لا توجد حركات لهذا العميل', 'info'); return; }
            var html = '<div class="text-right"><h4 class="font-bold mb-3">كشف حساب: ' + _esc(customerName) + ' (' + _esc(customerCode) + ')</h4>';
            html += '<table class="w-full text-sm border"><thead><tr class="bg-gray-100"><th class="p-2">التاريخ</th><th class="p-2">البيان</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th><th class="p-2 text-center">الرصيد</th></tr></thead><tbody>';
            for (var i = 0; i < data.length; i++) {
                html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].entry_date) + '</td><td class="p-2">' + _esc(data[i].description) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].debit) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].credit) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[i].balance) + '</td></tr>';
            }
            html += '</tbody></table></div>';
            Swal.fire({ title: 'تفاصيل كشف الحساب', html: html, width: '800px', showCloseButton: true, showConfirmButton: false });
        } catch(e) { _hideLoader(); _showToast('فشل تحميل كشف الحساب', 'error'); }
    }

    async function _showItemMovementDetail(itemCode, itemName) {
        _showLoader('جاري تحميل حركة الصنف...');
        try {
            var res = await supabase.from('inventory_log').select('*').eq('item_code', itemCode).order('movement_date', { ascending: false });
            var data = res.data || [];
            _hideLoader();
            if (!data.length) { _showToast('لا توجد حركات لهذا الصنف', 'info'); return; }
            var html = '<div class="text-right"><h4 class="font-bold mb-3">حركة الصنف: ' + _esc(itemName) + ' (' + _esc(itemCode) + ')</h4>';
            html += '<table class="w-full text-sm border"><thead><tr class="bg-gray-100"><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2 text-center">الكمية</th><th class="p-2">المرجع</th></tr></thead><tbody>';
            for (var i = 0; i < data.length; i++) {
                html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].movement_date) + '</td><td class="p-2">' + _esc(data[i].movement_type) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[i].qty) + '</td><td class="p-2">' + _esc(data[i].reference) + '</td></tr>';
            }
            html += '</tbody></table></div>';
            Swal.fire({ title: 'تفاصيل حركة الصنف', html: html, width: '800px', showCloseButton: true, showConfirmButton: false });
        } catch(e) { _hideLoader(); _showToast('فشل تحميل حركة الصنف', 'error'); }
    }

    async function _showRunsheetDetail(runsheetCode) {
        _showLoader('جاري تحميل تفاصيل الرانشيت...');
        try {
            var rsRes = await supabase.from('runsheets').select('*').eq('runsheet_code', runsheetCode).maybeSingle();
            var rs = rsRes.data;
            if (!rs) { _hideLoader(); _showToast('الرانشيت غير موجود', 'error'); return; }
            var itemsRes = await supabase.from('run_sheet_details').select('*').eq('runsheet_id', rs.id);
            var items = itemsRes.data || [];
            var ordersRes = await supabase.from('orders').select('order_code, customer_name, total_amount').eq('runsheet_id', runsheetCode);
            var orders = ordersRes.data || [];
            _hideLoader();

            var html = '<div class="text-right"><h4 class="font-bold mb-3">تفاصيل الرانشيت: ' + _esc(runsheetCode) + '</h4>';
            html += '<div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-xl mb-4"><div><p><b>التاريخ:</b> ' + _esc(rs.run_date) + '</p><p><b>السائق:</b> ' + _esc(rs.driver_id) + '</p></div><div><p><b>السيارة:</b> ' + _esc(rs.vehicle_id) + '</p><p><b>الحالة:</b> ' + _esc(rs.status) + '</p></div></div>';
            if (orders.length) {
                html += '<h5 class="font-bold mb-2">الأوردرات المرتبطة:</h5><div class="flex flex-wrap gap-2 mb-4">';
                for (var o = 0; o < orders.length; o++) html += '<span class="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-xs font-bold">' + _esc(orders[o].order_code) + ' - ' + _esc(orders[o].customer_name) + ' (' + _fmtNum(orders[o].total_amount) + ')</span>';
                html += '</div>';
            }
            if (items.length) {
                html += '<table class="w-full text-sm border"><thead><tr class="bg-gray-100"><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">السعر</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
                for (var i = 0; i < items.length; i++) { var lt = (Number(items[i].qty_ordered)||0) * (Number(items[i].unit_price)||0); html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(items[i].item_name) + '</td><td class="p-2 text-center">' + (items[i].qty_ordered||0) + '</td><td class="p-2 text-center">' + _fmtNum(items[i].unit_price) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(lt) + '</td></tr>'; }
                html += '</tbody></table>';
            }
            html += '</div>';
            Swal.fire({ title: 'تفاصيل الرانشيت', html: html, width: '900px', showCloseButton: true, showConfirmButton: false });
        } catch(e) { _hideLoader(); _showToast('فشل تحميل التفاصيل', 'error'); }
    }

    async function _showSettlementDetail(settlementCode) {
        _showLoader('جاري تحميل تفاصيل التسوية...');
        try {
            var res = await supabase.from('daily_settlements').select('*').eq('settlement_code', settlementCode).maybeSingle();
            var data = res.data;
            _hideLoader();
            if (!data) { _showToast('التسوية غير موجودة', 'error'); return; }
            var html = '<div class="text-right"><h4 class="font-bold mb-3">تفاصيل التسوية: ' + _esc(settlementCode) + '</h4>';
            html += '<div class="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-xl mb-4">';
            html += '<div><p><b>التاريخ:</b> ' + _esc(data.settlement_date) + '</p><p><b>الرانشيت:</b> ' + _esc(data.runsheet_id) + '</p></div>';
            html += '<div><p><b>العجز:</b> ' + data.total_shortage + ' قطعة</p><p><b>قيمة العجز:</b> ' + _fmtNum(data.total_shortage_value) + ' EGP</p></div>';
            html += '</div>';
            html += '<p><b>ملاحظات:</b> ' + _esc(data.notes || 'لا يوجد') + '</p>';
            html += '</div>';
            Swal.fire({ title: 'تفاصيل التسوية', html: html, width: '600px', showCloseButton: true, showConfirmButton: false });
        } catch(e) { _hideLoader(); _showToast('فشل تحميل التفاصيل', 'error'); }
    }

    // ==================== توليد التقرير (مع Drill-Down) ====================
    async function _generateReport(sectionKey, reportId) {
        var resultDiv = byId('report-result');
        if (!resultDiv) return;
        safeHTML(resultDiv, '<div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin text-2xl"></i> جاري تحميل التقرير...</div>');

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
            var data, html = '';

            // ---------- المبيعات ----------
            if (reportId === 'sales-summary') {
                var q = supabase.from('orders').select('total_amount').gte('order_date', fromDate).lte('order_date', toDate);
                if (customer) q = q.eq('customer_id', customer);
                var res = await q; data = res.data || [];
                var total = 0; for (var i = 0; i < data.length; i++) total += Number(data[i].total_amount) || 0;
                var avg = data.length ? Math.round(total / data.length) : 0;
                html = '<h4 class="font-bold mb-3">ملخص المبيعات</h4><div class="grid grid-cols-3 gap-4"><div class="bg-blue-50 p-4 rounded-xl text-center"><p class="text-xs">عدد الأوردرات</p><p class="text-2xl font-black">' + data.length + '</p></div><div class="bg-green-50 p-4 rounded-xl text-center"><p class="text-xs">الإجمالي</p><p class="text-2xl font-black">' + _fmtNum(total) + ' EGP</p></div><div class="bg-amber-50 p-4 rounded-xl text-center"><p class="text-xs">متوسط الأوردر</p><p class="text-2xl font-black">' + _fmtNum(avg) + ' EGP</p></div></div>';
            }
            else if (reportId === 'sales-by-customer') {
                var q = supabase.from('orders').select('customer_id, customer_name, total_amount').gte('order_date', fromDate).lte('order_date', toDate);
                if (customer) q = q.eq('customer_id', customer);
                var res = await q; data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var cid = data[i].customer_id || 'غير محدد'; var nm = data[i].customer_name || cid; map[cid] = { name: nm, total: (map[cid] ? map[cid].total : 0) + Number(data[i].total_amount || 0), cnt: (map[cid] ? map[cid].cnt : 0) + 1 }; }
                var arr = Object.entries(map).map(function(e) { return { id: e[0], name: e[1].name, total: e[1].total, count: e[1].cnt }; }).sort(function(a,b) { return b.total - a.total; });
                html = '<h4 class="font-bold mb-3">المبيعات حسب العميل (اضغط على الصف للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود العميل</th><th class="p-2">اسم العميل</th><th class="p-2 text-center">عدد الفواتير</th><th class="p-2 text-center">إجمالي المبيعات</th><th class="p-2 text-center">نسبة من الإجمالي</th></tr></thead><tbody>';
                var grandTotal = arr.reduce(function(s, a) { return s + a.total; }, 0);
                for (var i = 0; i < arr.length; i++) {
                    var pct = grandTotal > 0 ? Math.round((arr[i].total / grandTotal) * 100) : 0;
                    html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showCustomerLedgerDetail(\'' + _esc(arr[i].id) + '\', \'' + _esc(arr[i].name).replace(/'/g, "\\'") + '\')"><td class="p-2">' + _esc(arr[i].id) + '</td><td class="p-2 font-semibold">' + _esc(arr[i].name) + '</td><td class="p-2 text-center">' + arr[i].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(arr[i].total) + ' EGP</td><td class="p-2 text-center">' + pct + '%</td></tr>';
                }
                html += '</tbody></table>';
            }
            else if (reportId === 'sales-by-item') {
                var res = await supabase.from('order_details').select('item_code, item_name, qty, unit_price').gte('created_at', fromDate).lte('created_at', toDate);
                data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var code = data[i].item_code || data[i].item_name; map[code] = { name: data[i].item_name || code, qty: (map[code] ? map[code].qty : 0) + Number(data[i].qty || 0), total: (map[code] ? map[code].total : 0) + (Number(data[i].qty || 0) * Number(data[i].unit_price || 0)) }; }
                var arr = Object.entries(map).map(function(e) { return { code: e[0], name: e[1].name, qty: e[1].qty, total: e[1].total }; }).sort(function(a,b) { return b.total - a.total; });
                html = '<h4 class="font-bold mb-3">المبيعات حسب الصنف (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود الصنف</th><th class="p-2">اسم الصنف</th><th class="p-2 text-center">الكمية المباعة</th><th class="p-2 text-center">إجمالي المبيعات</th></tr></thead><tbody>';
                for (var i = 0; i < arr.length; i++) {
                    html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' + _esc(arr[i].code) + '\', \'' + _esc(arr[i].name).replace(/'/g, "\\'") + '\')"><td class="p-2">' + _esc(arr[i].code) + '</td><td class="p-2 font-semibold">' + _esc(arr[i].name) + '</td><td class="p-2 text-center">' + arr[i].qty + '</td><td class="p-2 text-center font-bold">' + _fmtNum(arr[i].total) + ' EGP</td></tr>';
                }
                html += '</tbody></table>';
            }
            else if (reportId === 'sales-by-area') {
                var res = await supabase.from('orders').select('area, total_amount').gte('order_date', fromDate).lte('order_date', toDate);
                data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var a = data[i].area || 'غير محدد'; map[a] = (map[a] || 0) + Number(data[i].total_amount || 0); }
                var arr = Object.entries(map).map(function(e) { return { area: e[0], total: e[1] }; }).sort(function(a,b) { return b.total - a.total; });
                html = '<h4 class="font-bold mb-3">المبيعات حسب المنطقة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">المنطقة</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
                for (var i = 0; i < arr.length; i++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(arr[i].area) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(arr[i].total) + ' EGP</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'sales-order-status') {
                var res = await supabase.from('orders').select('order_status').gte('order_date', fromDate).lte('order_date', toDate);
                data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var st = data[i].order_status || 'غير محدد'; map[st] = (map[st] || 0) + 1; }
                html = '<h4 class="font-bold mb-3">حالة الأوردرات</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الحالة</th><th class="p-2 text-center">العدد</th></tr></thead><tbody>';
                for (var k in map) html += '<tr class="border-t"><td class="p-2">' + _esc(k) + '</td><td class="p-2 text-center font-bold">' + map[k] + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'sales-customer-ledger') {
                if (!customer) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار عميل</div>'); return; }
                var res = await supabase.from('customer_ledger').select('*').eq('customer_id', customer).order('entry_date', { ascending: false });
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">كشف حساب العميل</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">البيان</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th><th class="p-2 text-center">الرصيد</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].entry_date) + '</td><td class="p-2">' + _esc(data[i].description) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].debit) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].credit) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[i].balance) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'sales-runsheet-performance') {
                var res = await supabase.from('runsheets').select('runsheet_code, run_date, total_amount, status, driver_id, vehicle_id').gte('run_date', fromDate).lte('run_date', toDate);
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">أداء الرانشيتات (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود الرانشيت</th><th class="p-2">التاريخ</th><th class="p-2">السائق</th><th class="p-2 text-center">القيمة</th><th class="p-2 text-center">الحالة</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showRunsheetDetail(\'' + _esc(data[i].runsheet_code) + '\')"><td class="p-2 font-bold text-blue-600">' + _esc(data[i].runsheet_code) + '</td><td class="p-2">' + _esc(data[i].run_date) + '</td><td class="p-2">' + _esc(data[i].driver_id) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[i].total_amount) + '</td><td class="p-2 text-center">' + _esc(data[i].status) + '</td></tr>';
                html += '</tbody></table>';
            }

            // ---------- المخازن والمشتريات ----------
            else if (reportId === 'inventory-stock') {
                var items = RW_STATE.data.items || [];
                var res = await supabase.from('stock_branches').select('item_id, qty, allocated_qty');
                var stk = res.data || []; var map = {}; var allocMap = {};
                for (var i = 0; i < stk.length; i++) { map[stk[i].item_id] = (map[stk[i].item_id] || 0) + Number(stk[i].qty || 0); allocMap[stk[i].item_id] = (allocMap[stk[i].item_id] || 0) + Number(stk[i].allocated_qty || 0); }
                html = '<h4 class="font-bold mb-3">جرد المخزون الحالي (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود الصنف</th><th class="p-2">اسم الصنف</th><th class="p-2">الوحدة</th><th class="p-2 text-center">الكمية الفعلية</th><th class="p-2 text-center">المحجوزة</th><th class="p-2 text-center">المتاحة</th><th class="p-2 text-center">سعر البيع</th><th class="p-2 text-center">قيمة المخزون</th></tr></thead><tbody>';
                for (var i = 0; i < items.length; i++) {
                    var it = items[i]; var qty = map[it.id] || 0; var alloc = allocMap[it.id] || 0; var avail = Math.max(0, qty - alloc); var val = qty * (Number(it.sales_price)||0);
                    html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showItemMovementDetail(\'' + _esc(it.item_code) + '\', \'' + _esc(it.name).replace(/'/g, "\\'") + '\')"><td class="p-2">' + _esc(it.item_code) + '</td><td class="p-2 font-semibold">' + _esc(it.name) + '</td><td class="p-2">' + _esc(it.unit) + '</td><td class="p-2 text-center">' + qty + '</td><td class="p-2 text-center">' + alloc + '</td><td class="p-2 text-center font-bold">' + avail + '</td><td class="p-2 text-center">' + _fmtNum(it.sales_price) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(val) + ' EGP</td></tr>';
                }
                html += '</tbody></table>';
            }
            else if (reportId === 'inventory-movement') {
                if (!itemCode) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار صنف</div>'); return; }
                var res = await supabase.from('inventory_log').select('*').eq('item_code', itemCode).order('movement_date', { ascending: false });
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">حركة الصنف</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2 text-center">الكمية</th><th class="p-2">المرجع</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].movement_date) + '</td><td class="p-2">' + _esc(data[i].movement_type) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[i].qty) + '</td><td class="p-2">' + _esc(data[i].reference) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'inventory-low-stock') {
                var items = RW_STATE.data.items || [];
                var res = await supabase.from('stock_branches').select('item_id, qty'); var stk = res.data || [];
                var map = {}; for (var i = 0; i < stk.length; i++) map[stk[i].item_id] = (map[stk[i].item_id] || 0) + Number(stk[i].qty || 0);
                var low = items.filter(function(it) { return (map[it.id] || 0) <= (Number(it.reorder_point) || 5); });
                html = '<h4 class="font-bold mb-3">الأصناف الأقل من حد الطلب</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الصنف</th><th class="p-2 text-center">المخزون</th><th class="p-2 text-center">حد الطلب</th></tr></thead><tbody>';
                for (var i = 0; i < low.length; i++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(low[i].name) + '</td><td class="p-2 text-center font-bold text-red-600">' + (map[low[i].id] || 0) + '</td><td class="p-2 text-center">' + (low[i].reorder_point || 5) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'inventory-dormant') {
                var items = RW_STATE.data.items || [];
                var res1 = await supabase.from('order_details').select('item_code').gte('created_at', fromDate).lte('created_at', toDate);
                var sold = {}; var det = res1.data || []; for (var i = 0; i < det.length; i++) sold[det[i].item_code] = true;
                var res2 = await supabase.from('stock_branches').select('item_id, qty'); var stk = res2.data || [];
                var map = {}; for (var i = 0; i < stk.length; i++) map[stk[i].item_id] = (map[stk[i].item_id] || 0) + Number(stk[i].qty || 0);
                var dormant = items.filter(function(it) { return (map[it.id] || 0) > 0 && !sold[it.item_code]; });
                html = '<h4 class="font-bold mb-3">تحليل دوران المخزون (راكدة)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الصنف</th><th class="p-2 text-center">المخزون</th></tr></thead><tbody>';
                for (var i = 0; i < Math.min(dormant.length, 30); i++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(dormant[i].name) + '</td><td class="p-2 text-center font-bold text-red-600">' + (map[dormant[i].id] || 0) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'purchase-by-supplier') {
                var q = supabase.from('purchase_orders').select('supplier_id, supplier_name, total_amount').gte('po_date', fromDate).lte('po_date', toDate);
                if (supplier) q = q.eq('supplier_id', supplier);
                var res = await q; data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var sid = data[i].supplier_id || 'غير محدد'; var sn = data[i].supplier_name || sid; map[sid] = { name: sn, total: (map[sid] ? map[sid].total : 0) + Number(data[i].total_amount || 0), cnt: (map[sid] ? map[sid].cnt : 0) + 1 }; }
                var arr = Object.entries(map).map(function(e) { return { id: e[0], name: e[1].name, total: e[1].total, count: e[1].cnt }; }).sort(function(a,b) { return b.total - a.total; });
                html = '<h4 class="font-bold mb-3">المشتريات حسب المورد</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود المورد</th><th class="p-2">اسم المورد</th><th class="p-2 text-center">عدد الأوامر</th><th class="p-2 text-center">إجمالي المشتريات</th></tr></thead><tbody>';
                for (var i = 0; i < arr.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(arr[i].id) + '</td><td class="p-2 font-semibold">' + _esc(arr[i].name) + '</td><td class="p-2 text-center">' + arr[i].count + '</td><td class="p-2 text-center font-bold">' + _fmtNum(arr[i].total) + ' EGP</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'purchase-order-status') {
                var res = await supabase.from('purchase_orders').select('status').gte('po_date', fromDate).lte('po_date', toDate);
                data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) map[data[i].status || 'غير محدد'] = (map[data[i].status || 'غير محدد'] || 0) + 1;
                html = '<h4 class="font-bold mb-3">حالة أوامر الشراء</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الحالة</th><th class="p-2 text-center">العدد</th></tr></thead><tbody>';
                for (var k in map) html += '<tr class="border-t"><td class="p-2">' + _esc(k) + '</td><td class="p-2 text-center font-bold">' + map[k] + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'purchase-receiving') {
                var res = await supabase.from('receiving_details').select('item_code, item_name, qty_expected, qty_received').gte('created_at', fromDate).lte('created_at', toDate);
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">استلام البضاعة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الصنف</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">المستلم</th><th class="p-2 text-center">الفرق</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) { var diff = (Number(data[i].qty_received) || 0) - (Number(data[i].qty_expected) || 0); html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].item_name) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].qty_expected) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].qty_received) + '</td><td class="p-2 text-center ' + (diff < 0 ? 'text-red-600' : 'text-green-600') + '">' + _fmtNum(diff) + '</td></tr>'; }
                html += '</tbody></table>';
            }

            // ---------- الحسابات ----------
            else if (reportId === 'finance-trial-balance') {
                var ses = await supabase.auth.getSession(); var token = ses.data.session?.access_token;
                var res = await fetch(RW_SUPABASE_URL + '/functions/v1/get-trial-balance', { method:'POST', headers: { 'Content-Type':'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ fromDate, toDate }) });
                var json = await res.json();
                if (json.success) { html = '<h4 class="font-bold mb-3">ميزان المراجعة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الاسم</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th></tr></thead><tbody>'; for (var i = 0; i < json.data.length; i++) { var r = json.data[i]; html += '<tr><td class="p-2">' + r.accountId + '</td><td class="p-2">' + r.accountName + '</td><td class="p-2 text-center">' + _fmtNum(r.totalDebit) + '</td><td class="p-2 text-center">' + _fmtNum(r.totalCredit) + '</td></tr>'; } html += '</tbody></table>'; }
                else html = '<div class="text-center py-4 text-red-500">فشل تحميل ميزان المراجعة</div>';
            }
            else if (reportId === 'finance-profit-loss') {
                var ses = await supabase.auth.getSession(); var token = ses.data.session?.access_token;
                var res = await fetch(RW_SUPABASE_URL + '/functions/v1/get-profit-loss', { method:'POST', headers: { 'Content-Type':'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ fromDate, toDate }) });
                var json = await res.json();
                if (json.success) { html = '<h4 class="font-bold mb-3">قائمة الدخل</h4><table class="w-full text-sm"><thead><tr class="bg-green-100"><th class="p-2">الإيرادات</th><th class="p-2">المبلغ</th></tr></thead><tbody>'; for (var i = 0; i < json.data.revenueAccounts.length; i++) html += '<tr><td class="p-2">' + json.data.revenueAccounts[i].accountName + '</td><td class="p-2">' + _fmtNum(json.data.revenueAccounts[i].total) + '</td></tr>'; html += '</tbody></table>'; }
                else html = '<div class="text-center py-4 text-red-500">فشل تحميل قائمة الدخل</div>';
            }
            else if (reportId === 'finance-balance-sheet') {
                var ses = await supabase.auth.getSession(); var token = ses.data.session?.access_token;
                var res = await fetch(RW_SUPABASE_URL + '/functions/v1/get-balance-sheet', { method:'POST', headers: { 'Content-Type':'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ asOfDate: toDate }) });
                var json = await res.json();
                if (json.success) { html = '<div class="text-green-600 font-bold p-4">تم تحميل الميزانية العمومية (العرض الكامل قيد التطوير)</div>'; }
                else html = '<div class="text-center py-4 text-red-500">فشل تحميل الميزانية</div>';
            }
            else if (reportId === 'finance-cash-flow') {
                var ses = await supabase.auth.getSession(); var token = ses.data.session?.access_token;
                var res = await fetch(RW_SUPABASE_URL + '/functions/v1/get-cash-flow', { method:'POST', headers: { 'Content-Type':'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify({ fromDate, toDate }) });
                var json = await res.json();
                if (json.success) { html = '<div class="text-blue-600 font-bold p-4">تم تحميل قائمة التدفقات النقدية</div>'; }
                else html = '<div class="text-center py-4 text-red-500">فشل تحميل التدفقات النقدية</div>';
            }
            else if (reportId === 'finance-general-ledger') {
                if (!account) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار حساب</div>'); return; }
                var res = await supabase.from('journal_lines').select('*, journal_entries!inner(entry_date, reference, description)').eq('account_id', account).order('entry_date', { ascending: false });
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">دفتر الأستاذ العام</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">المرجع</th><th class="p-2 text-center">مدين</th><th class="p-2 text-center">دائن</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].journal_entries?.entry_date) + '</td><td class="p-2">' + _esc(data[i].journal_entries?.reference) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].debit) + '</td><td class="p-2 text-center">' + _fmtNum(data[i].credit) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'finance-treasury') {
                if (!treasury) { safeHTML(resultDiv, '<div class="text-center py-4 text-gray-500">يرجى اختيار خزينة</div>'); return; }
                var res = await supabase.from('cash_box').select('*').eq('treasury_id', treasury).order('voucher_date', { ascending: false });
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">كشف حساب الخزينة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2 text-center">المبلغ</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].voucher_date) + '</td><td class="p-2">' + _esc(data[i].type) + '</td><td class="p-2 text-center font-bold">' + _fmtNum(data[i].amount) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'finance-tax') {
                html = '<div class="text-center py-4 text-gray-500">تقرير الضرائب قيد التطوير</div>';
            }

            // ---------- العملاء CRM ----------
            else if (reportId === 'crm-customer-list') {
                var customers = RW_STATE.data.customers || [];
                html = '<h4 class="font-bold mb-3">قائمة العملاء</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الكود</th><th class="p-2">الاسم</th><th class="p-2">الهاتف</th><th class="p-2">المنطقة</th></tr></thead><tbody>';
                for (var i = 0; i < customers.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(customers[i].customer_code) + '</td><td class="p-2 font-semibold">' + _esc(customers[i].name) + '</td><td class="p-2">' + _esc(customers[i].phone) + '</td><td class="p-2">' + _esc(customers[i].area) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'crm-customer-analysis') {
                var res = await supabase.from('orders').select('customer_name, total_amount').gte('order_date', fromDate).lte('order_date', toDate);
                data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var nm = data[i].customer_name || 'غير محدد'; map[nm] = { total: (map[nm] ? map[nm].total : 0) + Number(data[i].total_amount || 0), cnt: (map[nm] ? map[nm].cnt : 0) + 1 }; }
                var arr = Object.values(map).sort(function(a,b) { return b.total - a.total; }).slice(0,20);
                html = '<h4 class="font-bold mb-3">تحليل العملاء</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">العميل</th><th class="p-2 text-center">عدد الأوردرات</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
                for (var i = 0; i < arr.length; i++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(arr[i].name) + '</td><td class="p-2 text-center">' + arr[i].cnt + '</td><td class="p-2 text-center font-bold">' + _fmtNum(arr[i].total) + ' EGP</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'crm-customer-followups') {
                html = '<div class="text-center py-4 text-gray-500">سجل المتابعات غير متوفر حالياً</div>';
            }
            else if (reportId === 'crm-customer-by-area') {
                var customers = RW_STATE.data.customers || [];
                var map = {}; for (var i = 0; i < customers.length; i++) { var a = customers[i].area || 'غير محدد'; map[a] = (map[a] || 0) + 1; }
                html = '<h4 class="font-bold mb-3">العملاء حسب المنطقة</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">المنطقة</th><th class="p-2 text-center">عدد العملاء</th></tr></thead><tbody>';
                for (var k in map) html += '<tr class="border-t"><td class="p-2">' + _esc(k) + '</td><td class="p-2 text-center font-bold">' + map[k] + '</td></tr>';
                html += '</tbody></table>';
            }

            // ---------- اللوجستيات ----------
            else if (reportId === 'logistics-loading-unloading') {
                var res = await supabase.from('stock_vouchers').select('*').in('type', ['Loading','Unloading']).gte('voucher_date', fromDate).lte('voucher_date', toDate);
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">سجل التحميل والتفريغ</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">رقم الإذن</th><th class="p-2">النوع</th><th class="p-2">التاريخ</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].voucher_code) + '</td><td class="p-2">' + _esc(data[i].type) + '</td><td class="p-2">' + _esc(data[i].voucher_date) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'logistics-returns') {
                var res = await supabase.from('stock_vouchers').select('*').eq('type', 'Return').gte('voucher_date', fromDate).lte('voucher_date', toDate);
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">سجل المرتجعات</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">رقم الإذن</th><th class="p-2">التاريخ</th><th class="p-2">المرجع</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(data[i].voucher_code) + '</td><td class="p-2">' + _esc(data[i].voucher_date) + '</td><td class="p-2">' + _esc(data[i].reference) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'logistics-settlement') {
                var res = await supabase.from('daily_settlements').select('*').gte('settlement_date', fromDate).lte('settlement_date', toDate);
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">إغلاق اليومية (اضغط للتفاصيل)</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">كود التسوية</th><th class="p-2">التاريخ</th><th class="p-2">الرانشيت</th><th class="p-2 text-center">العجز</th><th class="p-2 text-center">قيمة العجز</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t hover:bg-gray-50 cursor-pointer" onclick="RW_Reports_Comprehensive._showSettlementDetail(\'' + _esc(data[i].settlement_code) + '\')"><td class="p-2 font-bold">' + _esc(data[i].settlement_code) + '</td><td class="p-2">' + _esc(data[i].settlement_date) + '</td><td class="p-2">' + _esc(data[i].runsheet_id) + '</td><td class="p-2 text-center">' + data[i].total_shortage + '</td><td class="p-2 text-center font-bold text-red-600">' + _fmtNum(data[i].total_shortage_value) + ' EGP</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'logistics-driver-performance') {
                var q = supabase.from('runsheets').select('driver_id, total_amount').gte('run_date', fromDate).lte('run_date', toDate);
                if (driver) q = q.eq('driver_id', driver);
                var res = await q; data = res.data || [];
                var map = {}; for (var i = 0; i < data.length; i++) { var dr = data[i].driver_id || 'غير محدد'; map[dr] = { total: (map[dr] ? map[dr].total : 0) + Number(data[i].total_amount || 0), cnt: (map[dr] ? map[dr].cnt : 0) + 1 }; }
                var arr = Object.entries(map).map(function(e) { return { driver: e[0], total: e[1].total, cnt: e[1].cnt }; }).sort(function(a,b) { return b.total - a.total; });
                html = '<h4 class="font-bold mb-3">أداء السائقين</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">السائق</th><th class="p-2 text-center">عدد الرانشيتات</th><th class="p-2 text-center">الإجمالي</th></tr></thead><tbody>';
                for (var i = 0; i < arr.length; i++) html += '<tr class="border-t"><td class="p-2">' + _esc(arr[i].driver) + '</td><td class="p-2 text-center">' + arr[i].cnt + '</td><td class="p-2 text-center font-bold">' + _fmtNum(arr[i].total) + ' EGP</td></tr>';
                html += '</tbody></table>';
            }

            // ---------- HR ----------
            else if (reportId === 'hr-employee-list') {
                var res = await supabase.from('users').select('name, email, role, status');
                data = res.data || [];
                html = '<h4 class="font-bold mb-3">قائمة الموظفين</h4><table class="w-full text-sm"><thead><tr class="bg-gray-50"><th class="p-2">الاسم</th><th class="p-2">البريد</th><th class="p-2">الدور</th><th class="p-2">الحالة</th></tr></thead><tbody>';
                for (var i = 0; i < data.length; i++) html += '<tr class="border-t"><td class="p-2 font-semibold">' + _esc(data[i].name) + '</td><td class="p-2">' + _esc(data[i].email) + '</td><td class="p-2">' + _esc(data[i].role) + '</td><td class="p-2">' + _esc(data[i].status) + '</td></tr>';
                html += '</tbody></table>';
            }
            else if (reportId === 'hr-attendance' || reportId === 'hr-salary') {
                html = '<div class="text-center py-4 text-gray-500">البيانات غير متوفرة حالياً (قيد التطوير)</div>';
            }
            else {
                html = '<div class="text-center py-4 text-gray-500">هذا التقرير غير متوفر بعد</div>';
            }

            safeHTML(resultDiv, html);
        } catch(e) { console.error(e); safeHTML(resultDiv, '<div class="text-center py-8 text-red-500">فشل تحميل التقرير: ' + e.message + '</div>'); }
    }

    function _printReport() {
        var resultDiv = byId('report-result');
        if (!resultDiv || !resultDiv.innerHTML) { _showToast('لا يوجد تقرير للطباعة', 'info'); return; }
        var printWindow = window.open('', '_blank');
        if (!printWindow) { _showToast('الرجاء السماح بالنوافذ المنبثقة', 'warning'); return; }
        var html = '<!DOCTYPE html><html dir="rtl"><head><meta charset="UTF-8"><title>تقرير</title><link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;700;900&display=swap" rel="stylesheet"><style>body{font-family:Cairo,sans-serif;padding:20px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #ddd;padding:8px}th{background:#f2f2f2}</style></head><body>' + resultDiv.innerHTML + '<script>window.print();<\/script></body></html>';
        printWindow.document.write(html); printWindow.document.close();
    }

    return { render: render, _openSection: _openSection, _closeSection: _closeSection, _openReport: _openReport, _generateReport: _generateReport, _printReport: _printReport, _showCustomerLedgerDetail: _showCustomerLedgerDetail, _showItemMovementDetail: _showItemMovementDetail, _showRunsheetDetail: _showRunsheetDetail, _showSettlementDetail: _showSettlementDetail };
})();
window.RW_Reports_Comprehensive = RW_Reports_Comprehensive;

