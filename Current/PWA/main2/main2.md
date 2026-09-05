function _rwCompanyId() {
    return window.RW_STATE && RW_STATE.app && RW_STATE.app.company && RW_STATE.app.company.id ? RW_STATE.app.company.id : null;
}

// ============================================================
// RW_Dashboard – لوحة التحكم الاحترافية (الإنترو)
// ============================================================
var RW_Dashboard = (function() {
    function _fmtNum(n) { return Number(n || 0).toLocaleString(); }
    var _charts = {};
    var _currentFrom = '';
    var _currentTo = '';

    function render() {
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), 'لوحة التحكم');
        safeText(byId('rw-header-subtitle'), 'نظرة عامة على أداء المؤسسة');

        var today = new Date().toISOString().split('T')[0];
        var firstDay = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];

        var html = '<div class="p-4 space-y-6">';
        // صف الترحيب
        html += '<div class="bg-gradient-to-r from-blue-700 to-indigo-800 rounded-3xl p-8 text-white shadow-xl">';
        html += '<h1 class="text-3xl font-black mb-2">مرحباً بك في الروائع ERP</h1>';
        html += '<p class="text-blue-100 text-lg">نظام إدارة موارد المؤسسات المتكامل – جميع عملياتك في مكان واحد</p>';
        html += '</div>';

        // مؤشرات الأداء – 5 بطاقات
        html += '<div class="grid grid-cols-2 md:grid-cols-5 gap-4">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 text-center"><p class="text-gray-400 text-xs font-bold mb-1">إجمالي المبيعات</p><p class="text-2xl font-black text-blue-600" id="dash-total-sales">---</p><p class="text-xs mt-1" id="dash-sales-change"></p></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 text-center"><p class="text-gray-400 text-xs font-bold mb-1">عدد الأوردرات</p><p class="text-2xl font-black text-emerald-600" id="dash-order-count">---</p><p class="text-xs mt-1" id="dash-order-change"></p></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 text-center"><p class="text-gray-400 text-xs font-bold mb-1">صافي الربح</p><p class="text-2xl font-black text-teal-600" id="dash-net-profit">---</p></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 text-center"><p class="text-gray-400 text-xs font-bold mb-1">العملاء</p><p class="text-2xl font-black text-orange-600" id="dash-customer-count">---</p></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 text-center"><p class="text-gray-400 text-xs font-bold mb-1">الأصناف</p><p class="text-2xl font-black text-purple-600" id="dash-item-count">---</p></div>';
        html += '</div>';

        // فلاتر زمنية
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 flex flex-wrap items-center gap-3">';
        html += '<span class="text-sm font-bold text-gray-600">الفترة:</span>';
        html += '<input type="date" id="dash-date-from" value="' + firstDay + '" class="p-2 bg-gray-50 border rounded-lg text-sm">';
        html += '<span class="text-gray-400">إلى</span>';
        html += '<input type="date" id="dash-date-to" value="' + today + '" class="p-2 bg-gray-50 border rounded-lg text-sm">';
        html += '<button id="dash-apply-btn" class="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-bold">تطبيق</button>';
        html += '</div>';

        // رسوم بيانية – صف 1
        html += '<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6"><h3 class="font-bold text-lg mb-4">المبيعات اليومية</h3><div style="height:300px"><canvas id="chart-sales"></canvas></div></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6"><h3 class="font-bold text-lg mb-4">المبيعات حسب المنطقة (اضغط للتفاصيل)</h3><div style="height:300px"><canvas id="chart-region"></canvas></div></div>';
        html += '</div>';

        // رسوم بيانية – صف 2
        html += '<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6"><h3 class="font-bold text-lg mb-4">أفضل 10 أصناف (اضغط للتفاصيل)</h3><div style="height:300px"><canvas id="chart-items"></canvas></div></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6"><h3 class="font-bold text-lg mb-4">أفضل 10 عملاء (اضغط للتفاصيل)</h3><div style="height:300px"><canvas id="chart-customers"></canvas></div></div>';
        html += '</div>';

        html += '</div>';
        safeHTML(container, html);

        byId('dash-apply-btn').addEventListener('click', function() {
            loadAll(byId('dash-date-from').value, byId('dash-date-to').value);
        });

        loadAll(firstDay, today);
    }

    function destroyCharts() {
        var ids = ['chart-sales', 'chart-region', 'chart-items', 'chart-customers'];
        for (var i = 0; i < ids.length; i++) {
            if (_charts[ids[i]]) { _charts[ids[i]].destroy(); _charts[ids[i]] = null; }
        }
    }

    function loadAll(fromDate, toDate) {
        _currentFrom = fromDate;
        _currentTo = toDate;
        safeText(byId('dash-total-sales'), '...');
        safeText(byId('dash-order-count'), '...');
        safeText(byId('dash-net-profit'), '...');
        safeText(byId('dash-customer-count'), '...');
        safeText(byId('dash-item-count'), '...');
        destroyCharts();

        // 1. الأوردرات
        supabase.from('orders').select('id, order_code, customer_id, customer_name, total_amount, order_date, area').eq('company_id', companyId).gte('order_date', fromDate).lte('order_date', toDate).then(function(res) {
            var orders = res.data || [];
            var totalSales = 0;
            for (var i = 0; i < orders.length; i++) { totalSales += Number(orders[i].total_amount) || 0; }
            safeText(byId('dash-total-sales'), _fmtNum(totalSales) + ' EGP');
            safeText(byId('dash-order-count'), orders.length);

            // مقارنة بالفترة السابقة
            var prevFrom = shiftDate(fromDate, -30);
            var prevTo = shiftDate(toDate, -30);
            supabase.from('orders').select('total_amount').eq('company_id', companyId).gte('order_date', prevFrom).lte('order_date', prevTo).then(function(prevRes) {
                var prevOrders = prevRes.data || [];
                var prevTotal = 0;
                for (var p = 0; p < prevOrders.length; p++) { prevTotal += Number(prevOrders[p].total_amount) || 0; }
                var change = prevTotal > 0 ? Math.round((totalSales - prevTotal) / prevTotal * 100) : 0;
                var changeEl = byId('dash-sales-change');
                if (changeEl) {
                    if (change > 0) { changeEl.innerHTML = '<span class="text-green-600 font-bold">▲ ' + change + '%</span>'; }
                    else if (change < 0) { changeEl.innerHTML = '<span class="text-red-600 font-bold">▼ ' + Math.abs(change) + '%</span>'; }
                    else { changeEl.innerHTML = '<span class="text-gray-400">0%</span>'; }
                }
                var orderChangeEl = byId('dash-order-change');
                if (orderChangeEl) {
                    var orderChange = prevOrders.length > 0 ? Math.round((orders.length - prevOrders.length) / prevOrders.length * 100) : 0;
                    if (orderChange > 0) { orderChangeEl.innerHTML = '<span class="text-green-600 font-bold">▲ ' + orderChange + '%</span>'; }
                    else if (orderChange < 0) { orderChangeEl.innerHTML = '<span class="text-red-600 font-bold">▼ ' + Math.abs(orderChange) + '%</span>'; }
                    else { orderChangeEl.innerHTML = '<span class="text-gray-400">0%</span>'; }
                }
            }).catch(function() {});

            renderSalesChart(orders, fromDate, toDate);
            renderRegionChart(orders);
            renderTopCustomersChart(orders);

            var topOrderIds = [];
            for (var oi = 0; oi < orders.length; oi++) { if (orders[oi].id) topOrderIds.push(orders[oi].id); }
            if (topOrderIds.length) {
                supabase.from('order_details').select('item_code, item_name, qty, unit_price').in('order_id', topOrderIds).then(function(res) {
                    renderTopItemsChart(res.data || []);
                }).catch(function() { renderTopItemsChart([]); });
            } else {
                renderTopItemsChart([]);
            }
        }).catch(function() {});

        // 2. المشتريات لصافي الربح
        supabase.from('purchase_orders').select('total_amount').eq('company_id', companyId).gte('po_date', fromDate).lte('po_date', toDate).then(function(poRes) {
            var poData = poRes.data || [];
            var totalPurchases = 0;
            for (var i = 0; i < poData.length; i++) { totalPurchases += Number(poData[i].total_amount) || 0; }
            supabase.from('orders').select('total_amount').eq('company_id', companyId).gte('order_date', fromDate).lte('order_date', toDate).then(function(ordRes) {
                var ordData = ordRes.data || [];
                var totalSales = 0;
                for (var j = 0; j < ordData.length; j++) { totalSales += Number(ordData[j].total_amount) || 0; }
                var net = totalSales - totalPurchases;
                safeText(byId('dash-net-profit'), _fmtNum(net) + ' EGP');
                var profitEl = byId('dash-net-profit');
                if (profitEl) {
                    if (net >= 0) { profitEl.className = 'text-2xl font-black text-teal-600'; }
                    else { profitEl.className = 'text-2xl font-black text-red-600'; }
                }
            }).catch(function() {});
        }).catch(function() {});

        // 3. العملاء
        supabase.from('customers').select('customer_code').eq('company_id', companyId).then(function(res) {
            safeText(byId('dash-customer-count'), (res.data || []).length);
        }).catch(function() {});

        // 4. الأصناف
        supabase.from('items').select('item_code').eq('company_id', companyId).then(function(res) {
            safeText(byId('dash-item-count'), (res.data || []).length);
        }).catch(function() {});

    }

    function shiftDate(dateStr, days) {
        var d = new Date(dateStr);
        d.setDate(d.getDate() + days);
        return d.toISOString().split('T')[0];
    }

    function renderSalesChart(orders, fromDate, toDate) {
        var canvas = byId('chart-sales');
        if (!canvas) return;
        var ctx = canvas.getContext('2d');
        if (!ctx) return;
        var days = [];
        var sales = [];
        var start = new Date(fromDate);
        var end = new Date(toDate);
        for (var d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
            var label = d.toISOString().split('T')[0];
            days.push(label);
            var total = 0;
            for (var i = 0; i < orders.length; i++) {
                if (orders[i].order_date === label) total += Number(orders[i].total_amount) || 0;
            }
            sales.push(total);
        }
        if (typeof Chart === 'undefined') return;
        _charts['chart-sales'] = new Chart(ctx, {
            type: 'line',
            data: {
                labels: days,
                datasets: [{ label: 'المبيعات (EGP)', data: sales, borderColor: '#2563eb', backgroundColor: 'rgba(37,99,235,0.1)', fill: true, tension: 0.4 }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: true, position: 'top' } } }
        });
    }

    function renderRegionChart(orders) {
        var canvas = byId('chart-region');
        if (!canvas) return;
        var ctx = canvas.getContext('2d');
        if (!ctx) return;
        var map = {};
        for (var i = 0; i < orders.length; i++) {
            var area = orders[i].area || 'غير محدد';
            map[area] = (map[area] || 0) + Number(orders[i].total_amount) || 0;
        }
        var labels = [], data = [];
        for (var k in map) { labels.push(k); data.push(map[k]); }
        if (typeof Chart === 'undefined') return;
        _charts['chart-region'] = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [{ data: data, backgroundColor: ['#2563eb','#10b981','#f59e0b','#ef4444','#8b5cf6','#ec4899','#06b6d4','#84cc16'] }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { display: true, position: 'right' } },
                onClick: function(e, elements) {
                    if (elements.length > 0) {
                        var index = elements[0].index;
                        var region = labels[index];
                        RW_Navigation.navigate('orders');
                        setTimeout(function() {
                            var areaInput = byId('f-area');
                            if (areaInput) { areaInput.value = region; RW_Orders._applyFilters(); }
                        }, 500);
                    }
                }
            }
        });
    }

    function renderTopItemsChart(details) {
        var canvas = byId('chart-items');
        if (!canvas) return;
        var ctx = canvas.getContext('2d');
        if (!ctx) return;
        var map = {};
        for (var i = 0; i < details.length; i++) {
            var code = details[i].item_code || details[i].item_name;
            var name = details[i].item_name || code;
            var total = (Number(details[i].qty) || 0) * (Number(details[i].unit_price) || 0);
            if (!map[code]) map[code] = { name: name, total: 0, code: code };
            map[code].total += total;
        }
        var arr = [];
        for (var k in map) arr.push(map[k]);
        arr.sort(function(a,b){ return b.total - a.total; });
        arr = arr.slice(0, 10);
        if (typeof Chart === 'undefined') return;
        _charts['chart-items'] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: arr.map(function(a){ return a.name; }),
                datasets: [{ label: 'الإجمالي (EGP)', data: arr.map(function(a){ return a.total; }), backgroundColor: '#8b5cf6' }]
            },
            options: {
                indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } },
                onClick: function(e, elements) {
                    if (elements.length > 0) {
                        var index = elements[0].index;
                        var itemName = arr[index].name;
                        RW_Navigation.navigate('items');
                    }
                }
            }
        });
    }

    function renderTopCustomersChart(orders) {
        var canvas = byId('chart-customers');
        if (!canvas) return;
        var ctx = canvas.getContext('2d');
        if (!ctx) return;
        var map = {};
        for (var i = 0; i < orders.length; i++) {
            var name = orders[i].customer_name || 'غير محدد';
            map[name] = (map[name] || 0) + Number(orders[i].total_amount) || 0;
        }
        var arr = [];
        for (var k in map) arr.push({ name: k, total: map[k] });
        arr.sort(function(a,b){ return b.total - a.total; });
        arr = arr.slice(0, 10);
        if (typeof Chart === 'undefined') return;
        _charts['chart-customers'] = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: arr.map(function(a){ return a.name; }),
                datasets: [{ label: 'الإجمالي (EGP)', data: arr.map(function(a){ return a.total; }), backgroundColor: '#f59e0b' }]
            },
            options: {
                indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } },
                onClick: function(e, elements) {
                    if (elements.length > 0) {
                        var index = elements[0].index;
                        var custName = arr[index].name;
                        RW_Navigation.navigate('orders');
                        setTimeout(function() {
                            var custInput = byId('f-cust');
                            if (custInput) { custInput.value = custName; RW_Orders._applyFilters(); }
                        }, 500);
                    }
                }
            }
        });
    }

    return { render: render };
})();
window.RW_Dashboard = RW_Dashboard;
// ============================================================
// RW_Items – الأصناف (صفحة تعديل كاملة، 3 تبويبات، جميع الحقول)
// ============================================================
var RW_Items = (function() {
    var sortField = 'item_code';
    var sortAsc = true;
    var itemsData = [];
    var currentSubTab = 'list';

    function _esc(s) {
    return esc(s == null ? '' : String(s));
}

function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}

function _jsAttr(s) {
    return _esc(_jsString(s));
}
    function _fmtNum(n) {
        return Number(n || 0).toLocaleString();
    }

    function _getStockStatus(item) {
        var total = item._totalStock || 0;
        var reorder = Number(item.reorder_point) || 5;
        var maxQty = Number(item.max_qty) || 0;
        if (total <= 0) return { label: 'نافد', color: 'bg-red-100 text-red-700', cls: 'critical' };
        if (total <= reorder) return { label: 'منخفض', color: 'bg-orange-100 text-orange-700', cls: 'low' };
        if (maxQty > 0 && total > maxQty) return { label: 'متكدس', color: 'bg-purple-100 text-purple-700', cls: 'overstock' };
        return { label: 'متوفر', color: 'bg-green-100 text-green-700', cls: 'normal' };
    }

    async function _loadStockData() {
        var branches = window._itemsBranches || RW_STATE.data.branches || [];
        if (!branches.length) {
            try { branches = await RW_Data.loadBranches(); } catch(e) {}
        }
        var branchIds = [];
        for (var b = 0; b < branches.length; b++) branchIds.push(branches[b].id || branches[b].branch_code);
        var stockRes = branchIds.length ? await supabase.from('stock_branches').select('item_id, branch_id, qty, allocated_qty').in('branch_id', branchIds) : { data: [], error: null };
        if (stockRes.error) throw stockRes.error;
        var stockRows = stockRes.data || [];
        var stockMap = {};
        for (var s = 0; s < stockRows.length; s++) {
            var row = stockRows[s];
            if (!stockMap[row.item_id]) stockMap[row.item_id] = {};
            stockMap[row.item_id][row.branch_id] = { qty: Number(row.qty) || 0, allocated: Number(row.allocated_qty) || 0 };
        }
        window._itemsBranchIds = branchIds;
        window._itemsBranches = branches;
        for (var i = 0; i < itemsData.length; i++) {
            var item = itemsData[i];
            var itemStock = stockMap[item.id] || {};
            var branchStock = {};
            var totalQty = 0;
            for (var j = 0; j < branchIds.length; j++) {
                var bid = branchIds[j];
                var st = itemStock[bid] || { qty: 0, allocated: 0 };
                branchStock[bid] = { qty: st.qty, allocated: st.allocated };
                totalQty += st.qty;
            }
            item._branchStock = branchStock;
            item._totalStock = totalQty;
            item._branches = branchIds;
        }
    }

    async function render() {
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), 'الأصناف والمخزون');
        safeText(byId('rw-header-subtitle'), 'مركز إدارة المخزون المتكامل');
        currentSubTab = 'list';
        showLoader('جاري تحميل الأصناف والمخزون...');
        try {
            itemsData = await RW_Data.loadItems();
            await _loadStockData();
            hideLoader();
        } catch(e) {
            hideLoader();
            console.error('فشل تحميل بيانات المخزون', e);
        }
        _renderSubTabs();
        _renderListView();
    }

    function _renderSubTabs() {
        var container = byId('rw-page-container');
        if (!container) return;
        var html = '<div class="p-4">';
        html += '<div class="flex flex-wrap gap-2 border-b pb-3 mb-4">';
        var tabs = [
            { id: 'list', label: '📋 قائمة الأصناف' },
            { id: 'movement', label: '📊 حركة صنف' },
            { id: 'matrix', label: '📍 الأرصدة حسب الفروع' }
        ];
        var isOwner = (RW_STATE.app.currentUser && RW_STATE.app.currentUser.isOwner === true);
        if (isOwner || RW_Permissions_check('warehouse_manager') || RW_Permissions_check('stock_adjustment')) {
            tabs.push({ id: 'upload', label: '📤 تحديث الأرصدة' });
        }
        for (var t = 0; t < tabs.length; t++) {
            var activeClass = currentSubTab === tabs[t].id ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200';
            html += '<button onclick="RW_Items._switchSubTab(\'' + tabs[t].id + '\')" class="px-4 py-2 rounded-xl font-bold text-sm transition ' + activeClass + '">' + tabs[t].label + '</button>';
        }
        html += '</div>';
        html += '<div id="items-sub-content"></div>';
        html += '</div>';
        safeHTML(container, html);
    }

    function _switchSubTab(tabId) {
        currentSubTab = tabId;
        _renderSubTabs();
        if (tabId === 'list') _renderListView();
        else if (tabId === 'movement') _renderStockMovementReport(null, null, null);
        else if (tabId === 'matrix') _renderBranchStockMatrix();
        else if (tabId === 'upload') _renderUploadTab();
    }

    // ==================== قائمة الأصناف ====================
    function _renderListView() {
        var content = byId('items-sub-content');
        if (!content) return;
        var html = '';
        html += '<div class="bg-white rounded-2xl shadow-sm border p-4 mb-4">';
        html += '<div class="grid grid-cols-2 md:grid-cols-4 gap-2">';
        html += '<input type="text" id="items-search" placeholder="🔍 بحث بالاسم، الكود، الباركود..." class="p-2.5 bg-gray-50 border rounded-lg text-sm" oninput="RW_Items._applyFilters()">';
        html += '<select id="items-cat-filter" class="p-2.5 bg-gray-50 border rounded-lg text-sm" onchange="RW_Items._applyFilters()"><option value="">كل التصنيفات</option></select>';
        html += '<select id="items-status-filter" class="p-2.5 bg-gray-50 border rounded-lg text-sm" onchange="RW_Items._applyFilters()"><option value="">كل الحالات</option><option value="low">🔴 منخفض</option><option value="normal">🟢 متوفر</option><option value="overstock">🟣 متكدس</option><option value="critical">⚫ نافد</option></select>';
        html += '<button onclick="RW_Items._resetFilters()" class="p-2.5 bg-gray-100 border rounded-lg text-sm font-bold hover:bg-gray-200">إعادة تعيين</button>';
        html += '</div>';
        html += '<div class="flex gap-2 mt-2">';
        html += '<button id="btn-add-item-main" class="p-2.5 bg-blue-600 text-white rounded-lg text-sm font-bold"><i class="fa-solid fa-plus ml-1"></i> صنف جديد</button>';
        html += '<button onclick="RW_Items._openCategoryModal()" class="p-2.5 bg-indigo-100 text-indigo-700 rounded-lg text-sm font-bold hover:bg-indigo-200"><i class="fa-solid fa-layer-group ml-1"></i> تصنيفات</button>';
        html += '</div></div>';
        html += '<div class="bg-white rounded-2xl shadow-sm border overflow-auto" id="items-table-wrapper" style="max-height:60vh"></div>';
        safeHTML(content, html);
        var addBtn = byId('btn-add-item-main');
        if (addBtn) addBtn.addEventListener('click', function() { openItemPage(null); });
        _buildCategoryFilterFromDB();
        _applyFilters();
    }

    function _applyFilters() {
        var q = (byId('items-search') ? byId('items-search').value : '').toLowerCase();
        var cat = byId('items-cat-filter') ? byId('items-cat-filter').value : '';
        var st = byId('items-status-filter') ? byId('items-status-filter').value : '';
        var filtered = itemsData.slice();
        if (q) {
            filtered = filtered.filter(function(i) {
                return (i.name||'').toLowerCase().indexOf(q) !== -1 ||
                       (i.item_code||'').toLowerCase().indexOf(q) !== -1 ||
                       (i.barcode||'').toLowerCase().indexOf(q) !== -1;
            });
        }
        if (cat) {
            filtered = filtered.filter(function(i) { return (i.category||'') === cat; });
        }
        if (st) {
            filtered = filtered.filter(function(i) {
                var status = _getStockStatus(i);
                return status.cls === st;
            });
        }
        _renderTable(filtered);
    }

    function _resetFilters() {
        var searchEl = byId('items-search');
        var catEl = byId('items-cat-filter');
        var stEl = byId('items-status-filter');
        if (searchEl) searchEl.value = '';
        if (catEl) catEl.value = '';
        if (stEl) stEl.value = '';
        _applyFilters();
    }

    function _renderTable(data) {
        var w = byId('items-table-wrapper');
        if (!w) return;
        if (!data.length) { safeHTML(w, '<div class="text-center p-10 text-gray-500">لا توجد أصناف</div>'); return; }

        var sorted = data.slice().sort(function(a,b) {
            var va = a[sortField] || '', vb = b[sortField] || '';
            if (sortField === 'totalStock' || sortField === 'sales_price' || sortField === 'max_qty') {
                va = Number(va); vb = Number(vb);
            } else if (sortField && sortField.indexOf('branch_') === 0) {
                var bid = sortField.replace('branch_', '');
                var bsa = (a._branchStock && a._branchStock[bid]) ? (a._branchStock[bid].qty || 0) : 0;
                var bsb = (b._branchStock && b._branchStock[bid]) ? (b._branchStock[bid].qty || 0) : 0;
                va = Number(bsa); vb = Number(bsb);
            } else {
                va = String(va).toLowerCase(); vb = String(vb).toLowerCase();
            }
            return (va < vb ? -1 : va > vb ? 1 : 0) * (sortAsc ? 1 : -1);
        });

        var branchIds = window._itemsBranchIds || [];
        var branches = window._itemsBranches || [];
        var iconSuffix = sortAsc ? 'fa-sort-up' : 'fa-sort-down';

        var html = '<table class="w-full text-sm"><thead class="sticky top-0 bg-gray-100 z-20"><tr>' +
            '<th class="p-3 text-center text-xs">#</th>' +
            '<th class="p-4 cursor-pointer font-bold" onclick="RW_Items._sort(\'name\')">الصنف <i class="fa-solid ' + (sortField==='name'?iconSuffix:'fa-sort') + '"></i></th>' +
            '<th class="p-4 cursor-pointer font-bold" onclick="RW_Items._sort(\'category\')">التصنيف <i class="fa-solid ' + (sortField==='category'?iconSuffix:'fa-sort') + '"></i></th>' +
            '<th class="p-4 cursor-pointer font-bold text-center" onclick="RW_Items._sort(\'sales_price\')">السعر <i class="fa-solid ' + (sortField==='sales_price'?iconSuffix:'fa-sort') + '"></i></th>' +
            '<th class="p-4 cursor-pointer font-bold text-center" onclick="RW_Items._sort(\'totalStock\')">إجمالي المخزون <i class="fa-solid ' + (sortField==='totalStock'?iconSuffix:'fa-sort') + '"></i></th>';

        for (var b = 0; b < branchIds.length; b++) {
            var bid = branchIds[b];
            var branchName = '';
            for (var bn = 0; bn < branches.length; bn++) {
                if ((branches[bn].id || branches[bn].branch_code) === bid) {
                    branchName = branches[bn].name || branches[bn].branch_code || bid;
                    break;
                }
            }
            html += '<th class="p-4 cursor-pointer font-bold text-center text-xs" onclick="RW_Items._sort(\'branch_' + bid + '\')">' + (branchName || bid) + ' <i class="fa-solid ' + (sortField===('branch_'+bid)?iconSuffix:'fa-sort') + '"></i></th>';
        }
        html += '<th class="p-4 text-center text-xs font-bold">الحالة</th></tr></thead><tbody id="items-tbody"></tbody></table>';
        var controlsHtml = '<div id="items-tbody-controls"></div>';
        safeHTML(w, html + controlsHtml);

        RW_Table.paginate('items-tbody', sorted, 1, 50, function(item, idx) {
            var img = item.image_url || 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E';
            var status = _getStockStatus(item);
            var rowHtml = '<tr class="hover:bg-blue-50"><td class="p-3 text-center text-xs text-gray-400">' + (idx + 1) + '</td>' +
                '<td class="p-4 cursor-pointer" onclick="RW_Items.openItemPage(' + _jsAttr(item.item_code) + ')"><div class="flex items-center gap-3">' +
                '<img src="' + _esc(img) + '" class="h-24 w-24 rounded-xl object-cover border-2 border-gray-100 shadow-sm cursor-pointer" onerror="this.src=\'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22150%22 height=%22150%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22150%22 height=%22150%22/%3E%3Ctext fill=%22%2394a3b8%22 font-family=%22Arial%22 font-size=%2214%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E\'" onclick="event.stopPropagation(); RW_Items._viewImage(' + _jsAttr(img) + ')" title="اضغط لتكبير الصورة">' +
                '<div><span class="font-bold text-base">' + _esc(item.name||'') + '</span><br><span class="text-xs text-gray-400">' + _esc(item.item_code||'') + '</span></div></div></td>' +
                '<td class="p-4 text-gray-500">' + _esc(item.category||'-') + '</td>' +
                '<td class="p-4 text-center font-bold text-blue-600">' + _fmtNum(item.sales_price) + ' EGP</td>';
            var totalStock = item._totalStock || 0;
            rowHtml += '<td class="p-4 text-center font-bold cursor-pointer underline text-blue-600" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + totalStock + '</td>';
            var branchStock = item._branchStock || {};
            for (var b2 = 0; b2 < branchIds.length; b2++) {
                var bid2 = branchIds[b2];
                var st = branchStock[bid2] || { qty: 0, allocated: 0 };
                var branchName2 = '';
                for (var bn2 = 0; bn2 < branches.length; bn2++) {
                    if ((branches[bn2].id || branches[bn2].branch_code) === bid2) { branchName2 = branches[bn2].name || branches[bn2].branch_code || bid2; break; }
                }
                rowHtml += '<td class="p-4 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\\'movement\\'); setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',' + _jsAttr(bid2) + ',' + _jsAttr(branchName2) + '); },200);">' + st.qty + '</td>';
            rowHtml += '<td class="p-4 text-center"><span class="px-2 py-1 rounded-full text-xs font-bold ' + status.color + '">' + status.label + '</span></td></tr>';
            return rowHtml;
        });
    }

    function _sort(field) {
        if (sortField === field) sortAsc = !sortAsc;
        else { sortField = field; sortAsc = true; }
        if (currentSubTab === 'list') _applyFilters();
        else if (currentSubTab === 'matrix') _renderBranchStockMatrix();
    }

    // ==================== حركة صنف – بدون تغيير ====================
    function _renderStockMovementReport(itemCode, itemName, branchId, branchName) {
        var content = byId('items-sub-content');
        if (!content) return;
        var html = '<div class="bg-white rounded-2xl shadow-sm border p-6"><h3 class="text-xl font-black mb-4"><i class="fa-solid fa-timeline ml-2 text-indigo-600"></i>تقرير حركة صنف</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">';
        html += '<div><label class="text-xs font-bold block mb-1">الصنف</label><select id="mov-item-select" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="">اختر صنفاً</option></select></div>';
        html += '<div><label class="text-xs font-bold block mb-1">من تاريخ</label><input type="date" id="mov-date-from" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"></div>';
        html += '<div><label class="text-xs font-bold block mb-1">إلى تاريخ</label><input type="date" id="mov-date-to" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"></div>';
        html += '<div class="flex items-end"><button onclick="RW_Items._loadMovementReport()" class="w-full p-2.5 bg-indigo-600 text-white rounded-lg text-sm font-bold"><i class="fa-solid fa-search ml-1"></i> عرض الحركات</button></div>';
        html += '</div><div id="movement-report-result" class="overflow-auto" style="max-height:55vh"><div class="text-center py-8 text-gray-400">اختر صنفاً واضغط "عرض الحركات"</div></div></div>';
        safeHTML(content, html);
        var sel = byId('mov-item-select');
        if (sel) {
            for (var i = 0; i < itemsData.length; i++) {
                var it = itemsData[i];
                var selected = '';
                if (itemCode && it.item_code === itemCode) selected = ' selected';
                sel.innerHTML += '<option value="' + _esc(it.item_code) + '"' + selected + '>' + _esc(it.name||'') + ' (' + _esc(it.item_code||'') + ')</option>';
            }
        }
            window._movementItemCode = itemCode;
            window._movementItemName = itemName || '';
            window._movementBranchId = branchId || null;
            window._movementBranchName = branchName || '';
		
		if (itemCode) {
            setTimeout(function() { _loadMovementReport(); }, 300);
        }
    }

    async function _loadMovementReport() {
        var itemCode = byId('mov-item-select') ? byId('mov-item-select').value : '';
        if (!itemCode) { showToast('يرجى اختيار صنف', 'warning'); return; }
        var fromDate = byId('mov-date-from') ? byId('mov-date-from').value : '';
        var toDate = byId('mov-date-to') ? byId('mov-date-to').value : '';
        showLoader('جاري تحميل الحركات...');
        try {
            var vouchersQuery = supabase.from('stock_vouchers')
    .select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id')
    .eq('company_id', companyId);

if (fromDate) {
    vouchersQuery = vouchersQuery.gte('voucher_date', fromDate);
}
if (toDate) {
    vouchersQuery = vouchersQuery.lte('voucher_date', toDate);
}
if (window._movementBranchId) {
    vouchersQuery = vouchersQuery.or(
        'from_branch_id.eq.' + window._movementBranchId + ',to_branch_id.eq.' + window._movementBranchId
    );
}

var vouchersRes = await vouchersQuery.order('voucher_date', { ascending: true });
            var vouchers = vouchersRes.data || [];
            var voucherIds = vouchers.map(function(v) { return v.id; });
            if (voucherIds.length === 0) { hideLoader(); safeHTML(byId('movement-report-result'), '<div class="text-center py-8 text-gray-500">لا توجد حركات مسجلة بعد</div>'); return; }
            var detailsRes = await supabase.from('stock_voucher_details').select('*').in('voucher_id', voucherIds).eq('item_code', itemCode);
            var details = detailsRes.data || [];
            if (details.length === 0) { hideLoader(); safeHTML(byId('movement-report-result'), '<div class="text-center py-8 text-gray-500">لا توجد حركات لهذا الصنف</div>'); return; }
            var voucherMap = {};
            for (var v = 0; v < vouchers.length; v++) { voucherMap[vouchers[v].id] = vouchers[v]; }
            var branchIds = window._itemsBranchIds || [];
            var branches = window._itemsBranches || [];
            var html = '<table class="w-full text-sm border"><thead><tr class="bg-gray-100"><th class="p-2">#</th><th class="p-2">التاريخ</th><th class="p-2">نوع الحركة</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">الرصيد التراكمي</th><th class="p-2">الفرع</th><th class="p-2">المرجع</th></tr></thead><tbody>';
            var runningBalance = 0;
            for (var d = 0; d < details.length; d++) {
                var det = details[d]; var qty = Number(det.qty) || 0; var voucher = voucherMap[det.voucher_id] || {};
                var branchName = ''; var isOut = false;
                for (var b = 0; b < branches.length; b++) {
                    var bid = branches[b].id || branches[b].branch_code;
                    if (bid === voucher.from_branch_id) { branchName = branches[b].name || bid; isOut = true; break; }
                    if (bid === voucher.to_branch_id) { branchName = branches[b].name || bid; isOut = false; break; }
                }
                var movementQty = isOut ? -qty : qty;
                runningBalance += movementQty;
                html += '<tr class="border-t"><td class="p-2 text-xs">' + (d+1) + '</td><td class="p-2">' + _esc(voucher.voucher_date||'') + '</td><td class="p-2">' + _esc(voucher.type||'') + '</td><td class="p-2 text-center font-bold ' + (movementQty>=0?'text-green-600':'text-red-600') + '">' + (movementQty>=0?'+':'') + movementQty + '</td><td class="p-2 text-center font-bold">' + runningBalance + '</td><td class="p-2">' + (branchName||'-') + '</td><td class="p-2 text-xs">' + _esc(voucher.voucher_code||'') + '</td></tr>';
            }
            html += '</tbody></table>';
            hideLoader();
            safeHTML(byId('movement-report-result'), html);
        } catch(e) { hideLoader(); console.error(e); showToast('فشل تحميل الحركات', 'error'); }
    }

    // ==================== مصفوفة الفروع – بدون تغيير ====================
    function _renderBranchStockMatrix() {
        var content = byId('items-sub-content');
        if (!content) return;
        var branchIds = window._itemsBranchIds || [];
        var branches = window._itemsBranches || [];
        if (branchIds.length === 0 || !itemsData.length) { safeHTML(content, '<div class="text-center py-10 text-gray-500">لا توجد بيانات كافية لعرض المصفوفة</div>'); return; }
        var sorted = itemsData.slice().sort(function(a,b) {
            var va = a[sortField] || '', vb = b[sortField] || '';
            if (sortField === 'totalStock') { va = Number(a._totalStock||0); vb = Number(b._totalStock||0); }
            else { va = String(va).toLowerCase(); vb = String(vb).toLowerCase(); }
            return (va < vb ? -1 : va > vb ? 1 : 0) * (sortAsc ? 1 : -1);
        });
        // بناء قائمة منسدلة للفروع
        var branchSelectHTML = '<select id="matrix-branch-select" class="p-2.5 bg-gray-50 border rounded-lg text-sm w-full md:w-60" onchange="RW_Items._filterMatrix()"><option value="">جميع الفروع</option>';
        for (var bi = 0; bi < branches.length; bi++) {
            branchSelectHTML += '<option value="' + _esc(branches[bi].id) + '">' + _esc(branches[bi].name || branches[bi].branch_code) + '</option>';
        }
        branchSelectHTML += '</select>';

        var html = '<div class="bg-white rounded-2xl shadow-sm border p-6"><h3 class="text-xl font-black mb-4"><i class="fa-solid fa-table ml-2 text-emerald-600"></i>الأرصدة حسب الفروع</h3><div class="flex flex-wrap items-center gap-3 mb-4"><input type="text" id="matrix-search" placeholder="🔍 بحث عن صنف..." class="p-2.5 bg-gray-50 border rounded-lg text-sm w-full md:w-80" oninput="RW_Items._filterMatrix()">' + branchSelectHTML + '<button onclick="RW_Items._exportMatrixToExcel()" class="p-2.5 bg-emerald-600 text-white rounded-lg text-sm font-bold hover:bg-emerald-700"><i class="fa-solid fa-file-excel ml-1"></i> تحميل Excel</button></div><div class="overflow-auto" style="max-height:55vh"><table class="w-full text-sm border" id="matrix-table"><thead class="sticky top-0 bg-gray-100"><tr><th class="p-3 cursor-pointer font-bold" onclick="RW_Items._sort(\'name\')">الصنف</th><th class="p-3 cursor-pointer font-bold text-center" onclick="RW_Items._sort(\'totalStock\')">إجمالي المخزون</th>';
        for (var b = 0; b < branchIds.length; b++) {
            var bid = branchIds[b]; var branchName = '';
            for (var bn = 0; bn < branches.length; bn++) { if ((branches[bn].id || branches[bn].branch_code) === bid) { branchName = branches[bn].name || bid; break; } }
            html += '<th class="p-3 text-center text-xs font-bold">' + (branchName||bid) + '</th>';
        }
        html += '</tr></thead><tbody id="matrix-tbody"></tbody></table></div></div>';
        var controlsHtml = '<div id="matrix-tbody-controls"></div>';
        safeHTML(content, html + controlsHtml);
        RW_Table.paginate('matrix-tbody', sorted, 1, 50, function(item, idx) {
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); 
 setTimeout(function(){ RW_Items._renderStockMovementReport(' + _jsAttr(item.item_code) + ',' + _jsAttr(item.name) + ',null); },200);">' + _esc(item.name||'') + ' <span class="text-xs text-gray-400">(' + (item.item_code||'') + ')</span></td><td class="p-3 text-center font-bold">' + (item._totalStock||0) + '</td>';
            var branchStock = item._branchStock || {};
            for (var b2 = 0; b2 < branchIds.length; b2++) {
                var bid2 = branchIds[b2]; var st = branchStock[bid2] || { qty: 0, allocated: 0 }; var branchName2 = '';
                for (var bn2 = 0; bn2 < branches.length; bn2++) { if ((branches[bn2].id || branches[bn2].branch_code) === bid2) { branchName2 = branches[bn2].name || bid2; break; } }
                rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(\'' + _esc(item.item_code) + '\',\'' + _esc(item.name).replace(/'/g, "\\'") + '\',\'' + _esc(bid2) + '\',\'' + _esc(branchName2).replace(/'/g, "\\'") + '\'); },200);">' + st.qty + '</td>';
            }
            rowHtml += '</tr>'; return rowHtml;
        });
    }


    function _filterMatrix() {
        var q = (byId('matrix-search') ? byId('matrix-search').value : '').toLowerCase();
        var selectedBranch = (byId('matrix-branch-select') ? byId('matrix-branch-select').value : '');
        var filtered = itemsData;
        if (q) { filtered = itemsData.filter(function(i) { return (i.name||'').toLowerCase().indexOf(q) !== -1 || (i.item_code||'').toLowerCase().indexOf(q) !== -1; }); }
        
        // فلترة حسب الفرع (إظهار الأصناف التي لها رصيد في هذا الفرع فقط)
        if (selectedBranch) {
            filtered = filtered.filter(function(item) {
                var bs = item._branchStock || {};
                return bs.hasOwnProperty(selectedBranch) && (bs[selectedBranch].qty > 0);
            });
        }
        _renderBranchStockMatrixFiltered(filtered);
    }

    function _renderBranchStockMatrixFiltered(data) {
        var tbody = byId('matrix-tbody'); if (!tbody) return;
        var branchIds = window._itemsBranchIds || [];
        var branches = window._itemsBranches || [];
        RW_Table.paginate('matrix-tbody', data, 1, 50, function(item, idx) {
            var rowHtml = '<tr class="border-t hover:bg-gray-50"><td class="p-3 cursor-pointer font-bold text-blue-600" onclick="RW_Items._switchSubTab(\\'movement\\'); 
            var branchStock = item._branchStock || {};
            for (var b2 = 0; b2 < branchIds.length; b2++) {
                var bid2 = branchIds[b2]; var st = branchStock[bid2] || { qty: 0, allocated: 0 }; var branchName2 = '';
                for (var bn2 = 0; bn2 < branches.length; bn2++) { if ((branches[bn2].id || branches[bn2].branch_code) === bid2) { branchName2 = branches[bn2].name || bid2; break; } }
                rowHtml += '<td class="p-3 text-center cursor-pointer underline text-blue-600 text-xs" onclick="RW_Items._switchSubTab(\'movement\'); setTimeout(function(){ RW_Items._renderStockMovementReport(\'' + _esc(item.item_code) + '\',\'' + _esc(item.name).replace(/'/g, "\\'") + '\',\'' + _esc(bid2) + '\',\'' + _esc(branchName2).replace(/'/g, "\\'") + '\'); },200);">' + st.qty + '</td>';
            }
            rowHtml += '</tr>'; return rowHtml;
        });
    }

    function _viewImage(url) {
        Swal.fire({ imageUrl: url, imageWidth: 800, imageAlt: 'صورة الصنف', showCloseButton: true, showConfirmButton: false, customClass: { popup: '!bg-transparent !shadow-none !p-0' } });
    }

    // ==================== صفحة تعديل الصنف كاملة (3 تبويبات) ====================
    function openItemPage(itemCode) {
        var item = itemCode ? itemsData.find(function(i) { return i.item_code === itemCode; }) : null;
        var isEdit = !!item;
        var title = isEdit ? 'تعديل الصنف' : 'إضافة صنف جديد';
        var branches = window._itemsBranches || RW_STATE.data.branches || [];
        var branchOptions = '';
        for (var br = 0; br < branches.length; br++) {
            var bv = branches[br].branch_code || branches[br].id || '';
            var bn = branches[br].name || bv;
            branchOptions += '<option value="' + _esc(bv) + '">' + _esc(bn) + '</option>';
        }
        var container = byId('rw-page-container');
        if (!container) return;
        safeText(byId('rw-header-title'), title);
        safeText(byId('rw-header-subtitle'), isEdit ? 'تعديل بيانات الصنف' : 'إضافة صنف جديد للمخزون');
        var html = '<div class="p-4 max-w-4xl mx-auto">';
        html += '<div class="flex justify-between items-center mb-6"><h2 class="text-xl font-black"><i class="fa-solid fa-box-open ml-2 text-blue-600"></i>' + title + '</h2><button onclick="RW_Items.render()" class="bg-gray-100 text-gray-600 px-4 py-2 rounded-xl font-bold hover:bg-gray-200"><i class="fa-solid fa-arrow-right ml-1"></i> عودة للقائمة</button></div>';
        html += '<div class="flex flex-wrap gap-2 border-b pb-3 mb-6">';
        html += '<button onclick="RW_Items._switchItemTab(\'basic\')" class="px-4 py-2 rounded-xl font-bold text-sm bg-blue-600 text-white" id="item-tab-basic">البيانات الأساسية</button>';
        html += '<button onclick="RW_Items._switchItemTab(\'pricing\')" class="px-4 py-2 rounded-xl font-bold text-sm text-gray-500" id="item-tab-pricing">الأسعار والمخزون</button>';
        html += '<button onclick="RW_Items._switchItemTab(\'marketing\')" class="px-4 py-2 rounded-xl font-bold text-sm text-gray-500" id="item-tab-marketing">العروض والتسويق</button>';
        html += '</div>';
        // تبويب الأساسي
        html += '<div id="item-panel-basic"><div class="bg-white rounded-2xl shadow-sm border p-6 space-y-4"><input type="hidden" id="item-code-hidden" value="' + _esc(item ? item.item_code : '') + '"><input type="hidden" id="item-existing-image" value="' + _esc(item ? (item.image_url || '') : '') + '"><div class="grid grid-cols-1 md:grid-cols-2 gap-4">';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الباركود</label><input id="item-barcode" value="' + _esc(item ? (item.barcode || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">اسم المنتج *</label><input id="item-name" value="' + _esc(item ? (item.name || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">التصنيف</label><select id="item-cat" class="p-2.5 bg-gray-50 border rounded-lg"><option value="">بدون تصنيف</option></select></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة الأساسية</label><input id="item-unit" value="' + _esc(item ? (item.alt_unit || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة البديلة</label><input id="item-altunit" value="' + _esc(item ? (item.alt_unit || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">عدد الوحدات البديلة</label><input id="item-altqty" type="number" value="'+ _esc(item ? (item.alt_unit_qty || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الوزن</label><input id="item-weight" value="' + _esc(item ? (item.weight_kg || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الحجم</label><input id="item-vol" value="' + _esc(item ? (item.volume_m3 || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="md:col-span-2 flex flex-col"><label class="text-sm font-bold">الوصف</label><textarea id="item-desc" rows="3" class="p-2.5 bg-gray-50 border rounded-lg">' + _esc(item ? (item.description || '') : '') + '</textarea></div>';
        html += '</div></div></div>';
        // تبويب الأسعار والمخزون
        html += '<div id="item-panel-pricing" class="hidden"><div class="bg-white rounded-2xl shadow-sm border p-6 space-y-4"><div class="grid grid-cols-1 md:grid-cols-2 gap-4">';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">سعر البيع</label><input id="item-price" type="number" value="' + _esc(item ? (item.sales_price || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">السعر القديم</label><input id="item-oprice" type="number" value="' + _esc(item ? (item.old_price || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">حد إعادة الطلب</label><input id="item-reorder" type="number" value="' + _esc(item ? (item.reorder_point || 5) : 5) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الحد الأقصى للطلب</label><input id="item-maxqty" type="number" value="' + _esc(item ? (item.max_qty || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الحد الأقصى في الطلب الواحد</label><input id="item-maxqty-per-order" type="number" value="' + _esc(item ? (item.max_qty_per_order || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الترتيب في المتجر</label><input id="item-sort-order" type="number" value="' + _esc(item ? (item.sort_order || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '</div>';
        if (!isEdit) {
            html += '<div class="bg-amber-50 border border-amber-200 rounded-xl p-4 mt-4"><h4 class="font-bold text-amber-700 mb-3"><i class="fa-solid fa-boxes-stacked ml-2"></i>الرصيد الافتتاحي (اختياري)</h4><div class="grid grid-cols-2 gap-4"><div class="flex flex-col"><label class="text-sm text-amber-700">الفرع</label><select id="item-opening-branch" class="p-2.5 bg-white border rounded-lg"><option value="">-- اختر فرعاً --</option>' + branchOptions + '</select></div><div class="flex flex-col"><label class="text-sm text-amber-700">الكمية الافتتاحية</label><input id="item-opening-qty" type="number" value="0" min="0" class="p-2.5 bg-white border rounded-lg"></div></div></div>';
        }
        html += '</div></div>';
        // تبويب العروض والتسويق
        html += '<div id="item-panel-marketing" class="hidden"><div class="bg-white rounded-2xl shadow-sm border p-6 space-y-4"><h3 class="font-bold text-lg text-indigo-600"><i class="fa-solid fa-rectangle-ad ml-2"></i>إعدادات العروض والتسويق</h3><div class="grid grid-cols-1 md:grid-cols-2 gap-4">';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نسبة الخصم (%)</label><input id="item-discount-percent" type="number" value="' + _esc(item ? (item.discount_percent || 0) : 0) + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="' + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">تاريخ بداية العرض</label><input id="item-discount-start" type="date" value="' + _esc(item ? (item.discount_start || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '<div class="flex flex-col"><label class="text-sm font-bold">تاريخ نهاية العرض</label><input id="item-discount-end" type="date" value="' + _esc(item ? (item.discount_end || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
        html += '</div><div class="flex items-center gap-8 p-4 bg-gray-50 rounded-xl mt-4">';
        html += '<label class="flex items-center gap-2 cursor-pointer"><input type="checkbox" id="item-is-daily-deal" ' + (item && item.is_daily_deal ? 'checked' : '') + '><span class="font-bold text-sm">عرض اليوم</span></label>';
        html += '<label class="flex items-center gap-2 cursor-pointer"><input type="checkbox" id="item-is-active" ' + (item && item.is_active !== false ? 'checked' : '') + '><span class="font-bold text-sm">نشط</span></label>';
        html += '<label class="flex items-center gap-2 cursor-pointer"><input type="checkbox" id="item-show-in-store" ' + (item && item.show_in_store !== false ? 'checked' : '') + '><span class="font-bold text-sm">الظهور في المتجر الإلكتروني</span></label>';
        html += '</div></div></div>';
        // قسم الصورة
        html += '<div class="bg-white rounded-2xl shadow-sm border p-6 mt-4"><h4 class="font-bold mb-3">صورة المنتج</h4><div class="flex items-center gap-4"><div class="w-32 h-32 rounded-xl border-2 border-dashed bg-gray-50 flex items-center justify-center overflow-hidden"><img id="item-img-preview" src="' + _esc(item && item.image_url ? item.image_url : 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22128%22 height=%22128%22%3E%3Crect fill=%22%23e2e8f0%22 width=%22128%22 height=%22128%22/%3E%3Ctext fill=%22%2394a3b8%22 font-size=%2216%22 x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22%3E📦%3C/text%3E%3C/svg%3E') + '" class="max-w-full max-h-full object-contain"></div><div><input type="file" id="item-image-file" accept="image/*" class="text-xs file:py-2 file:px-4 file:rounded-lg file:bg-blue-50 file:text-blue-700"><p class="text-xs text-gray-500 mt-1">يفضل صورة مربعة</p></div></div></div>';
        // أزرار
        html += '<div class="flex justify-end gap-3 mt-6">';
        if (isEdit) html += '<button onclick="RW_Items._handleDeleteFromPage()" class="px-5 py-2.5 bg-red-600 text-white rounded-xl font-bold mr-auto"><i class="fa-solid fa-trash ml-1"></i> حذف الصنف</button>';
        html += '<button onclick="RW_Items.render()" class="px-5 py-2.5 border rounded-xl font-bold">إلغاء</button>';
        html += '<button onclick="RW_Items._handleSaveFromPage(' + (isEdit ? 'true' : 'false') + ')" class="px-6 py-2.5 bg-blue-600 text-white rounded-xl font-bold shadow"><i class="fa-solid fa-check ml-1"></i> حفظ</button>';
        html += '</div></div>';
        safeHTML(container, html);
        var fileInput = byId('item-image-file');
        if (fileInput) { fileInput.addEventListener('change', function() { var file = this.files[0]; if (file) { var reader = new FileReader(); reader.onload = function(e) { var p = byId('item-img-preview'); if (p) p.src = e.target.result; }; reader.readAsDataURL(file); } }); }
        _loadCategoriesIntoSelect();
        window._currentEditItem = item;
    }

    function _switchItemTab(tabId) {
        var panels = ['basic', 'pricing', 'marketing'];
        for (var i = 0; i < panels.length; i++) {
            var panel = byId('item-panel-' + panels[i]); var tab = byId('item-tab-' + panels[i]);
            if (panel) panel.classList.add('hidden');
            if (tab) { tab.classList.remove('bg-blue-600', 'text-white'); tab.classList.add('text-gray-500'); }
        }
        var activePanel = byId('item-panel-' + tabId); var activeTab = byId('item-tab-' + tabId);
        if (activePanel) activePanel.classList.remove('hidden');
        if (activeTab) { activeTab.classList.add('bg-blue-600', 'text-white'); activeTab.classList.remove('text-gray-500'); }
    }

	    async function _handleSaveFromPage(isEditFlag) {
	        var nameInput = byId('item-name'); if (!nameInput) { showToast('خطأ', 'error'); return; }
	        var name = nameInput.value.trim(); if (!name) { showToast('اسم الصنف مطلوب', 'error'); return; }
	        showLoader('جاري الحفظ...');
	        
	        var item = window._currentEditItem;
	        var fileInput = byId('item-image-file');
	        var hasNewImage = fileInput && fileInput.files.length > 0;

	        // الدالة المضمونة لحل مشكلة undefined وانتظار الرفع
function resolveImageUrlAndSave(item, fileInput, callback) {
    var file = (fileInput && fileInput.files.length > 0) ? fileInput.files[0] : null;
    
    if (!file) {
        var existingUrl = (item && item.image_url != null) ? item.image_url : null;
        console.log('📸 لا توجد صورة جديدة. استخدام:', existingUrl);
        callback(existingUrl);
        return;
    }
    
    console.log('📤 بدء رفع الصورة:', file.name, file.size);
    
    // ✅ اسم ملف آمن – ASCII فقط مع الحفاظ على الامتداد
    var lastDot = file.name.lastIndexOf('.');
    var fileExt = lastDot > -1 ? file.name.substring(lastDot) : '.jpg';
    var safeName = encodeURIComponent(file.name.substring(0, lastDot > -1 ? lastDot : file.name.length));
    var fileName = Date.now() + '-' + safeName + fileExt;
    
    supabase.storage.from('product-images').upload(fileName, file, { upsert: true })
        .then(function(res) {
            if (res.error) {
                console.error('❌ فشل الرفع:', res.error.message);
                showToast('فشل رفع الصورة: ' + res.error.message, 'error');
                var fallbackUrl = (item && item.image_url != null) ? item.image_url : null;
                callback(fallbackUrl);
                return;
            }
            
            console.log('✅ رفع ناجح. جاري توليد الرابط العام...');
            var publicUrl = supabase.storage.from('product-images').getPublicUrl(fileName).data.publicUrl;
            console.log('✅ الرابط العام:', publicUrl);
            callback(publicUrl);
        })
        .catch(function(err) {
            console.error('❌ خطأ شبكة:', err.message);
            showToast('فشل رفع الصورة: ' + err.message, 'error');
            var fallbackUrl = (item && item.image_url != null) ? item.image_url : null;
            callback(fallbackUrl);
        });
}
	        // دالة الحفظ الفعلية – تستقبل imageUrl كمعامل
	        function executeSave(imageUrl) {
	            // نضمن أن imageUrl ليست undefined أبداً
	            var finalImageUrl = (imageUrl != null) ? imageUrl : null;
	            
	            var payload = {
	                name: name,
	                barcode: (byId('item-barcode') ? byId('item-barcode').value : '').trim(),
	                category: (byId('item-cat') ? byId('item-cat').value : '').trim(),
	                category_id: (byId('item-cat') ? byId('item-cat').value : '') || null,
	                unit: (byId('item-unit') ? byId('item-unit').value : '').trim(),
	                alt_unit: (byId('item-altunit') ? byId('item-altunit').value : '').trim(),
	                alt_unit_qty: parseFloat(byId('item-altqty') ? byId('item-altqty').value : 0) || 0,
	                sales_price: parseFloat(byId('item-price') ? byId('item-price').value : 0) || 0,
	                old_price: parseFloat(byId('item-oprice') ? byId('item-oprice').value : 0) || 0,
	                reorder_point: parseFloat(byId('item-reorder') ? byId('item-reorder').value : 5) || 5,
	                max_qty: parseFloat(byId('item-maxqty') ? byId('item-maxqty').value : 0) || 0,
	                max_qty_per_order: parseFloat(byId('item-maxqty-per-order') ? byId('item-maxqty-per-order').value : 0) || 0,
	                sort_order: parseFloat(byId('item-sort-order') ? byId('item-sort-order').value : 0) || 0,
	                weight_kg: parseFloat(byId('item-weight') ? byId('item-weight').value : 0) || 0,
	                volume_m3: parseFloat(byId('item-vol') ? byId('item-vol').value : 0) || 0,
	                description: (byId('item-desc') ? byId('item-desc').value : '').trim(),
	                image_url: finalImageUrl,
	                is_active: byId('item-is-active') ? byId('item-is-active').checked : true,
	                show_in_store: byId('item-show-in-store') ? byId('item-show-in-store').checked : true,
	                discount_percent: parseFloat(byId('item-discount-percent') ? byId('item-discount-percent').value : 0) || 0,
	                discount_start: (byId('item-discount-start') ? byId('item-discount-start').value : '') || null,
	                discount_end: (byId('item-discount-end') ? byId('item-discount-end').value : '') || null,
	                is_daily_deal: byId('item-is-daily-deal') ? byId('item-is-daily-deal').checked : false,
	                badge_text: (byId('item-badge-text') ? byId('item-badge-text').value : '').trim() || null
	            };

	            console.log('📤 الصورة المُرسلة:', payload.image_url);
	            console.log('📤 البيانات الكاملة:', JSON.stringify(payload));

	            supabase.auth.getSession().then(function(ses) {
	                var token = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
	                if (!token) { hideLoader(); showToast('جلسة غير صالحة', 'error'); return; }
	                return fetch(RW_SUPABASE_URL + '/functions/v1/save-item', {
	                    method: 'POST',
	                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
	                    body: JSON.stringify({
	                        item: payload,
	                        isEdit: isEditFlag,
	                        item_code: item ? item.item_code : null,
	                        openingBranch: (byId('item-opening-branch') ? byId('item-opening-branch').value : '') || null,
	                        openingQty: parseFloat(byId('item-opening-qty') ? byId('item-opening-qty').value : 0) || 0
	                    })
	                });
	            }).then(function(res) { if (!res) return; return res.json(); }).then(function(json) {
	                if (json && json.success) {
	                    RW_Audit_log(isEditFlag ? 'update' : 'create', 'items', json.item_code || (item ? item.item_code : ''), isEditFlag ? item : null, payload);
	                    hideLoader();
	                    showToast(isEditFlag ? 'تم التعديل' : 'تمت الإضافة', 'success');
	                    RW_Data.loadItems().then(function(nd) {
	                        itemsData = nd;
	                        _loadStockData().then(function() { if (currentSubTab === 'list') _applyFilters(); });
	                    });
	                    RW_Items.render();
	                } else {
	                    hideLoader();
	                    showToast((json && json.error) || 'فشل الحفظ', 'error');
	                }
	            }).catch(function(e) { hideLoader(); console.error(e); showToast('فشل الاتصال', 'error'); });
	        }

	        // بدء العملية: انتظر الرفع ثم احفظ
	        resolveImageUrlAndSave(item, fileInput, function(imageUrl) {
	            executeSave(imageUrl);
	        });
	    }
    function _handleDeleteFromPage() {
        var item = window._currentEditItem; if (!item) { showToast('الصنف غير محدد', 'error'); return; }
        Swal.fire({ title: 'تأكيد الحذف', text: 'حذف هذا الصنف؟', icon: 'warning', showCancelButton: true, confirmButtonText: 'حذف', cancelButtonText: 'إلغاء' }).then(function(cf) {
            if (!cf.isConfirmed) return;
            showLoader('جاري الحذف...');
            supabase.auth.getSession().then(function(ses) {
                var token = (ses&&ses.data&&ses.data.session)?ses.data.session.access_token:null;
                return fetch(RW_SUPABASE_URL+'/functions/v1/delete-item',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:JSON.stringify({item_code:item.item_code})}).then(function(res){return res.json();});
            }).then(function(json) {
                hideLoader();
                if (json.success) { RW_Audit_log('delete','items',item.item_code,item,null); showToast('تم الحذف','success'); RW_Data.loadItems().then(function(nd){itemsData=nd;_loadStockData().then(function(){if(currentSubTab==='list')_applyFilters();});}); RW_Items.render(); }
                else { showToast(json.error||'فشل الحذف','error'); }
            }).catch(function(e){hideLoader();showToast('فشل الاتصال','error');});
        });
    }

    async function _showBranchStockMovement(itemCode, itemName, branchId, branchName) {
        showLoader('جاري تحميل حركة المخزون...');
        try {
            var vouchersRes = await supabase.from('stock_vouchers').select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id').eq('company_id', companyId).or('from_branch_id.eq.'+branchId+',to_branch_id.eq.'+branchId).order('voucher_date',{ascending:true});
            var vouchers = vouchersRes.data||[]; if(vouchers.length===0){hideLoader();Swal.fire({title:'حركة المخزون',text:'لا توجد حركات لهذا الفرع',icon:'info'});return;}
            var voucherIds=vouchers.map(function(v){return v.id;});
            var detailsRes=await supabase.from('stock_voucher_details').select('*').in('voucher_id',voucherIds).eq('item_code',itemCode);
            var details=detailsRes.data||[]; if(details.length===0){hideLoader();Swal.fire({title:'حركة المخزون',text:'لا توجد حركات لهذا الصنف في الفرع',icon:'info'});return;}
            var voucherMap={}; for(var v=0;v<vouchers.length;v++){voucherMap[vouchers[v].id]=vouchers[v];}
            var html='<div class="text-right"><h4 class="font-bold mb-3">حركة: '+_esc(itemName)+' - '+_esc(branchName)+'</h4><table class="w-full border text-sm"><thead><tr class="bg-gray-100"><th class="p-2">التاريخ</th><th class="p-2">النوع</th><th class="p-2 text-center">الكمية</th><th class="p-2">المرجع</th></tr></thead><tbody>';
            var rb=0;
            for(var d=0;d<details.length;d++){var det=details[d];var qty=Number(det.qty)||0;var voucher=voucherMap[det.voucher_id]||{};var isOut=(voucher.from_branch_id===branchId);var mq=isOut?-qty:qty;rb+=mq;html+='<tr class="border-t"><td class="p-2">'+(voucher.voucher_date||'')+'</td><td class="p-2">'+(voucher.type||'')+'</td><td class="p-2 text-center font-bold '+(mq>=0?'text-green-600':'text-red-600')+'">'+(mq>=0?'+':'')+mq+'</td><td class="p-2">'+(voucher.voucher_code||'')+'</td></tr>';}
            html+='<tr class="font-bold bg-gray-50"><td colspan="3" class="p-2 text-left">الرصيد النهائي</td><td class="p-2 text-center">'+rb+'</td></tr></tbody></table></div>';
            hideLoader(); Swal.fire({title:'حركة المخزون',html:html,width:'800px',showCloseButton:true,showConfirmButton:false});
        } catch(e) { hideLoader(); console.error(e); showToast('فشل التحميل','error'); }
    }

    function _loadCategoriesIntoSelect() {
      var select = byId('item-cat');
      if (!select) return;
      
      supabase.from('categories').select('id, category_name').eq('company_id', companyId).order('category_name').then(function(res) {
        var categories = res.data || [];
        var html = '<option value="">بدون تصنيف</option>';
        var currentCategoryId = window._currentEditItem ? window._currentEditItem.category_id : null;
        var currentCategoryText = window._currentEditItem ? window._currentEditItem.category : '';
        
        for (var i = 0; i < categories.length; i++) {
          var selected = '';
          if (currentCategoryId && categories[i].id === currentCategoryId) selected = ' selected';
          if (!currentCategoryId && currentCategoryText && categories[i].category_name === currentCategoryText) selected = ' selected';
          html += '<option value="' + _esc(categories[i].id) + '"' + selected + '>' + _esc(categories[i].category_name) + '</option>';
        }
        safeHTML(select, html);
      });
    }

    function _openCategoryModal() {
      supabase.from('categories').select('id, category_name').eq('company_id', companyId).order('category_name').then(function(res) {
        var categories = res.data || [];
        
        var html = '<div class="text-right" dir="rtl">';
        html += '<h3 class="font-bold text-lg mb-3">🗂️ إدارة التصنيفات</h3>';
        
        if (categories.length === 0) {
          html += '<div class="text-center py-6 text-gray-400">لا توجد تصنيفات</div>';
        } else {
          html += '<div class="max-h-48 overflow-y-auto mb-4 space-y-1">';
          for (var i = 0; i < categories.length; i++) {
            var catId = categories[i].id;
            var catName = categories[i].category_name || '';
            html += '<div class="flex justify-between items-center p-2 bg-gray-50 rounded-lg cursor-pointer hover:bg-indigo-50" onclick="RW_Items._editCategory(' + _jsAttr(catId) + ', ' + _jsAttr(catName) + ')">';
            html += '<span class="font-bold text-sm">' + _esc(catName) + '</span>';
            html += '</div>';
          }
          html += '</div>';
        }
        
        html += '<div class="flex gap-2 mt-3">';
        html += '<input type="text" id="new-category-name" class="flex-1 p-2.5 border rounded-lg text-sm" placeholder="اسم التصنيف الجديد">';
        html += '<button onclick="RW_Items._addCategory()" class="bg-indigo-600 text-white px-4 py-2 rounded-lg font-bold text-sm whitespace-nowrap">إضافة</button>';
        html += '</div>';
        html += '</div>';
        
        Swal.fire({
          title: '',
          html: html,
          width: '500px',
          showCloseButton: true,
          showConfirmButton: false,
          customClass: { popup: '!rounded-3xl' }
        });
      });
    }

    function _addCategory() {
      var popup = Swal.getPopup();
      if (!popup) return;
      var nameInput = popup.querySelector('#new-category-name');
      var name = nameInput ? nameInput.value.trim() : '';
      if (!name) { showToast('أدخل اسم التصنيف', 'warning'); return; }
      
      showLoader('جاري الإضافة...');
      
      supabase.auth.getSession().then(function(sessionRes) {
        var session = sessionRes.data && sessionRes.data.session;
        if (!session) {
          hideLoader();
          showToast('انتهت الجلسة. يرجى إعادة تسجيل الدخول.', 'error');
          return;
        }
        var token = session.access_token;
        return fetch(RW_SUPABASE_URL + '/functions/v1/save-category', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token
          },
          body: JSON.stringify({ action: 'create', category_name: name })
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
        if (json && json.success) {
          showToast('تمت الإضافة', 'success');
                     _buildCategoryFilterFromDB(); // <-- أضف هذا السطر هنا
          Swal.close();
          RW_Items._openCategoryModal();
        } else {
          showToast((json && json.msg) || 'فشل', 'error');
        }
      }).catch(function(e) {
        hideLoader();
        console.error('Error adding category:', e);
        showToast('فشل الاتصال: ' + (e.message || 'خطأ غير معروف'), 'error');
      });
    }

    function _editCategory(id, currentName) {
      Swal.fire({
        title: 'تعديل التصنيف',
        html: '<div class="text-right"><label class="block text-sm font-bold mb-2">الاسم</label><input id="swal-edit-cat-name" class="swal2-input w-full text-right rounded-xl" value="' + _esc(currentName || '') + '"></div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        showDenyButton: true,
        denyButtonText: '🗑️ حذف',
        denyButtonColor: '#ef4444',
        customClass: { popup: '!rounded-3xl', confirmButton: '!rounded-xl !bg-indigo-600', cancelButton: '!rounded-xl', denyButton: '!rounded-xl' },
        preConfirm: function() {
          var popup = Swal.getPopup();
          var input = popup ? popup.querySelector('#swal-edit-cat-name') : null;
          var newName = input ? input.value.trim() : '';
          if (!newName) { Swal.showValidationMessage('الاسم مطلوب'); return false; }
          return newName;
        }
      }).then(function(result) {
        if (result.isConfirmed) {
          showLoader('جاري الحفظ...');
          supabase.auth.getSession().then(function(sessionRes) {
            var session = sessionRes.data && sessionRes.data.session;
            if (!session) {
              hideLoader();
              showToast('انتهت الجلسة', 'error');
              return;
            }
            var token = session.access_token;
            return fetch(RW_SUPABASE_URL + '/functions/v1/save-category', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
              },
              body: JSON.stringify({ action: 'update', category_id: id, category_name: result.value })
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
            if (json && json.success) {
              showToast('تم التعديل', 'success');
                  _buildCategoryFilterFromDB(); // <-- أضف هذا السطر هنا
              RW_Items._openCategoryModal();
            } else {
              showToast((json && json.msg) || 'فشل', 'error');
            }
          }).catch(function(e) {
            hideLoader();
            showToast('فشل الاتصال', 'error');
          });
        } else if (result.isDenied) {
          RW_Items._deleteCategory(id, currentName);
        }
      });
    }

    function _deleteCategory(id, name) {
      supabase.from('items').select('id').eq('company_id', companyId).eq('category_id', id).limit(1).then(function(checkRes) {
        var hasItems = checkRes.data && checkRes.data.length > 0;
        
        if (hasItems) {
          supabase.from('categories').select('id, category_name').eq('company_id', companyId).neq('id', id).order('category_name').then(function(catRes) {
            var cats = catRes.data || [];
            var options = '';
            for (var i = 0; i < cats.length; i++) {
              options += '<option value="' + _esc(cats[i].id) + '">' + _esc(cats[i].category_name) + '</option>';
            }
            
            Swal.fire({
              title: 'لا يمكن حذف التصنيف',
              html: '<p class="text-sm">يوجد أصناف تستخدم تصنيف "' + _esc(name) + '".</p><p class="text-sm mt-2">اختر تصنيفًا بديلاً لنقلها إليه:</p><select id="replacement-cat" class="swal2-input">' + options + '</select>',
              showCancelButton: true,
              confirmButtonText: 'نقل وحذف',
              cancelButtonText: 'إلغاء',
              customClass: { popup: '!rounded-3xl' },
              preConfirm: function() {
                var sel = document.getElementById('replacement-cat');
                return sel ? sel.value : null;
              }
            }).then(function(r) {
              if (!r.isConfirmed || !r.value) return;
              RW_Items._executeDeleteCategory(id, r.value);
            });
          });
        } else {
          Swal.fire({
            title: 'تأكيد الحذف',
            text: 'حذف تصنيف "' + name + '"؟',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'حذف',
            cancelButtonText: 'إلغاء',
            customClass: { popup: '!rounded-3xl', confirmButton: '!rounded-xl !bg-red-600' }
          }).then(function(r) {
            if (!r.isConfirmed) return;
            RW_Items._executeDeleteCategory(id, null);
          });
        }
      });
    }

    function _executeDeleteCategory(id, replacementId) {
      showLoader('جاري الحذف...');
      var payload = { action: 'delete', category_id: id };
      if (replacementId) payload.replacement_category_id = replacementId;
      
      supabase.auth.getSession().then(function(sessionRes) {
        var session = sessionRes.data && sessionRes.data.session;
        if (!session) {
          hideLoader();
          showToast('انتهت الجلسة', 'error');
          return;
        }
        var token = session.access_token;
        return fetch(RW_SUPABASE_URL + '/functions/v1/save-category', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token
          },
          body: JSON.stringify(payload)
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
        if (json && json.success) {
          showToast('تم الحذف', 'success');
              _buildCategoryFilterFromDB(); // <-- أضف هذا السطر هنا
          RW_Items._openCategoryModal();
          RW_Items.render();
        } else {
          showToast((json && json.msg) || 'فشل', 'error');
        }
      }).catch(function(e) {
        hideLoader();
        showToast('فشل الاتصال', 'error');
      });
    }
    
        // دالة بناء قائمة التصنيفات من جدول categories مباشرة
    function _buildCategoryFilterFromDB() {
        var sel = byId('items-cat-filter');
        if (!sel) return;
        supabase.from('categories').select('id, category_name').eq('company_id', companyId).order('category_name').then(function(res) {
            var categories = res.data || [];
            var html = '<option value="">كل التصنيفات</option>';
            for (var i = 0; i < categories.length; i++) {
                html += '<option value="' + _esc(categories[i].category_name) + '">' + _esc(categories[i].category_name) + '</option>';
            }
            safeHTML(sel, html);
        });
    }
    // ==================== تبويب تحديث الأرصدة ====================
    var _uploadFileData = []; // تخزين بيانات الملف بعد التحليل
    var _uploadOperationId = null;
    var _uploadOperationFingerprint = null;

    function _renderUploadTab() {
        var content = byId('items-sub-content');
        if (!content) return;
        var branches = window._itemsBranches || RW_STATE.data.branches || [];
        var branchOpts = '<option value="">-- اختر الفرع --</option>';
        for (var i = 0; i < branches.length; i++) {
            branchOpts += '<option value="' + branches[i].id + '">' + (branches[i].name || branches[i].branch_code) + '</option>';
        }

        var html = '<div class="bg-white rounded-2xl shadow-sm border p-6">';
        html += '<h3 class="text-xl font-black mb-4"><i class="fa-solid fa-file-import ml-2 text-indigo-600"></i>تحديث الأرصدة عبر ملف</h3>';
        html += '<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">';
        html += '<div><label class="text-xs font-bold block mb-1">الفرع *</label><select id="upload-branch" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm">' + branchOpts + '</select></div>';
        html += '<div><label class="text-xs font-bold block mb-1">نوع التسوية *</label><select id="upload-type" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm"><option value="replace">استبدال كامل</option><option value="add">إضافة (+)</option><option value="deduct">خصم (-)</option></select></div>';
        html += '<div><label class="text-xs font-bold block mb-1">سبب التسوية *</label><input type="text" id="upload-reason" class="w-full p-2.5 bg-gray-50 border rounded-lg text-sm" placeholder="مثال: جرد دوري ربع سنوي"></div>';
        html += '<div class="flex items-end"><button id="btn-upload-file" class="w-full p-2.5 bg-indigo-600 text-white rounded-lg text-sm font-bold"><i class="fa-solid fa-folder-open ml-1"></i> اختر ملف</button><input type="file" id="upload-file-input" accept=".csv,.xlsx,.xls" class="hidden" onchange="RW_Items._handleFileSelect(this)"></div>';
        html += '</div>';
        html += '<div id="upload-preview-area" class="hidden mt-6"><h4 class="font-bold text-lg mb-3">معاينة البيانات</h4><div class="overflow-auto max-h-96 border rounded-lg" id="upload-preview-table"></div><div class="mt-3 flex justify-between items-center"><span id="upload-summary" class="text-sm text-gray-500"></span><button id="btn-execute-upload" class="bg-green-600 text-white px-6 py-2 rounded-lg font-bold disabled:opacity-50" disabled onclick="RW_Items._executeUpload()"><i class="fa-solid fa-check ml-1"></i> تنفيذ التحديث</button></div></div>';
        html += '</div>';
        safeHTML(content, html);

        var btn = byId('btn-upload-file');
        if (btn) btn.addEventListener('click', function() { var inp = byId('upload-file-input'); if (inp) inp.click(); });
    }

    function _handleFileSelect(input) {
        var file = input.files[0];
        if (!file) return;
		_uploadFileData = [];
        _uploadOperationId = null;
        _uploadOperationFingerprint = null;

        var reader = new FileReader();
        reader.onload = function(e) {
            try {
                var data = new Uint8Array(e.target.result);
                var workbook = XLSX.read(data, { type: 'array' });
                var sheet = workbook.Sheets[workbook.SheetNames[0]];
                var rows = XLSX.utils.sheet_to_json(sheet, { header: 1 });
                if (rows.length < 2) { showToast('الملف فارغ أو لا يحتوي على بيانات', 'warning'); return; }
                
                // البحث عن الأعمدة الصحيحة (باركود وكمية)
                var headers = rows[0];
                var barcodeCol = -1, qtyCol = -1;
                for (var h = 0; h < headers.length; h++) {
                    var headerStr = String(headers[h] || '').toLowerCase().trim();
                    if (headerStr === 'barcode' || headerStr === 'item_code' || headerStr === 'باركود' || headerStr === 'الكود') barcodeCol = h;
                    if (headerStr === 'qty' || headerStr === 'quantity' || headerStr === 'كمية' || headerStr === 'الكمية') qtyCol = h;
                }
                if (barcodeCol === -1 || qtyCol === -1) { showToast('لم يتم التعرف على أعمدة الباركود والكمية. تأكد من وجود ترويسات Barcode و Qty', 'error'); return; }

                _uploadFileData = [];
                for (var r = 1; r < rows.length; r++) {
                    var row = rows[r];
                    var barcode = String(row[barcodeCol] || '').trim();
                    var qty = parseFloat(String(row[qtyCol] || '').replace(/[^\d.]/g, ''));
                    if (barcode && !isNaN(qty)) {
                        // تجميع الباركودات المتكررة
                        var found = false;
                        for (var f = 0; f < _uploadFileData.length; f++) {
                            if (_uploadFileData[f].barcode === barcode) { _uploadFileData[f].qty += qty; found = true; break; }
                        }
                        if (!found) _uploadFileData.push({ barcode: barcode, qty: qty });
                    }
                }
                _renderUploadPreview();
            } catch (err) { showToast('فشل قراءة الملف: ' + err.message, 'error'); console.error(err); }
        };
        reader.readAsArrayBuffer(file);
    }

    function _renderUploadPreview() {
        var previewArea = byId('upload-preview-area');
        var previewTable = byId('upload-preview-table');
        var summary = byId('upload-summary');
        var executeBtn = byId('btn-execute-upload');
        if (!previewArea || !previewTable) return;

        previewArea.classList.remove('hidden');
        if (_uploadFileData.length === 0) {
            safeHTML(previewTable, '<div class="text-center py-8 text-gray-500">لا توجد بيانات صالحة في الملف</div>');
            safeText(summary, '');
            if (executeBtn) executeBtn.disabled = true;
            return;
        }

        safeHTML(previewTable, '<div class="text-center py-8 text-gray-500"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحقق من الأصناف...</div>');

        var barcodes = [];
        for (var b = 0; b < _uploadFileData.length; b++) { barcodes.push(_uploadFileData[b].barcode); }

        var branchId = byId('upload-branch') ? byId('upload-branch').value : '';
        if (!branchId) { safeHTML(previewTable, '<div class="text-center py-8 text-red-500">يرجى اختيار الفرع أولاً</div>'); if (executeBtn) executeBtn.disabled = true; return; }

        // جلب الأصناف
        supabase.from('items').select('id, item_code, barcode, name').eq('company_id', companyId).in('barcode', barcodes).then(function(itemsRes) {
var itemMap = {};
var duplicateBarcodeMap = {};
for (var im = 0; im < (itemsRes.data || []).length; im++) {
    var it = itemsRes.data[im];
    if (!it.barcode) continue;
    if (itemMap[it.barcode]) {
        duplicateBarcodeMap[it.barcode] = true;
    } else {
        itemMap[it.barcode] = it;
    }
}

for (var f = 0; f < _uploadFileData.length; f++) {
    var barcodeValue = _uploadFileData[f].barcode;
    if (duplicateBarcodeMap[barcodeValue]) {
        _uploadFileData[f]._invalidReason = 'باركود غير فريد';
        delete _uploadFileData[f].item_code;
    } else {
        var mappedItem = itemMap[barcodeValue];
        if (mappedItem) _uploadFileData[f].item_code = mappedItem.item_code;
    }
}
            // جلب الأرصدة الحالية
            supabase.from('stock_branches').select('item_id, qty').eq('branch_id', branchId).in('item_id', (itemsRes.data || []).map(function(x) { return x.id; })).then(function(stockRes) {
                var stockMap = {};
                for (var st = 0; st < (stockRes.data || []).length; st++) { stockMap[stockRes.data[st].item_id] = stockRes.data[st].qty; }

                var html = '<table class="w-full text-sm border"><thead class="bg-gray-100 sticky top-0"><tr><th class="p-2">الباركود</th><th class="p-2">الصنف</th><th class="p-2 text-center">الرصيد الحالي</th><th class="p-2 text-center">الكمية المدخلة</th><th class="p-2 text-center">الرصيد الجديد</th><th class="p-2 text-center">الحالة</th></tr></thead><tbody>';
                var validCount = 0, invalidCount = 0;
                var adjType = byId('upload-type') ? byId('upload-type').value : 'replace';

                for (var d = 0; d < _uploadFileData.length; d++) {
                    var entry = _uploadFileData[d];
                    var item = itemMap[entry.barcode];
                    var currentQty = item ? (Number(stockMap[item.id]) || 0) : 0;
                    var inputQty = Number(entry.qty) || 0;
                    var newQty = currentQty;
                    var status = '', statusClass = '';

                    if (duplicateBarcodeMap[entry.barcode]) {
    status = '❌ الباركود غير فريد';
    statusClass = 'bg-red-50';
    invalidCount++;
} else if (!item) {
    status = '❌ باركود غير موجود';
    statusClass = 'bg-red-50';
    invalidCount++;
} else {
                        if (adjType === 'replace') newQty = inputQty;
                        else if (adjType === 'add') newQty = currentQty + inputQty;
                        else if (adjType === 'deduct') { newQty = currentQty - inputQty; if (newQty < 0) { status = '⚠️ سيصبح الرصيد سالباً'; statusClass = 'bg-yellow-50'; } }
                        if (!status) { status = '✅ صالح'; statusClass = 'bg-green-50'; validCount++; }
                    }
                    entry._valid = !!item && !status;
                    html += '<tr class="' + statusClass + '"><td class="p-2 font-mono">' + entry.barcode + '</td><td class="p-2">' + (item ? item.name : '---') + '</td><td class="p-2 text-center font-bold">' + currentQty + '</td><td class="p-2 text-center font-bold text-indigo-600">' + inputQty + '</td><td class="p-2 text-center font-bold">' + newQty + '</td><td class="p-2 text-center text-xs">' + status + '</td></tr>';
                }
                html += '</tbody></table>';
                safeHTML(previewTable, html);
                safeText(summary, 'صالح: ' + validCount + ' | أخطاء: ' + invalidCount + ' | إجمالي: ' + _uploadFileData.length);
                if (executeBtn) executeBtn.disabled = (validCount === 0);
            }).catch(function(err) { safeHTML(previewTable, '<div class="text-center py-8 text-red-500">فشل جلب الأرصدة: ' + err.message + '</div>'); });
        }).catch(function(err) { safeHTML(previewTable, '<div class="text-center py-8 text-red-500">فشل جلب الأصناف: ' + err.message + '</div>'); });
    }

    function _executeUpload() {
        var branchId = byId('upload-branch') ? byId('upload-branch').value : '';
        var adjType = byId('upload-type') ? byId('upload-type').value : 'replace';
        var reason = byId('upload-reason') ? byId('upload-reason').value.trim() : '';
        if (!branchId) { showToast('يرجى اختيار الفرع', 'warning'); return; }
        if (!reason) { showToast('يرجى إدخال سبب التسوية', 'warning'); return; }
        if (_uploadFileData.length === 0) { showToast('لا توجد بيانات للتنفيذ', 'warning'); return; }

        var items = [];
        for (var u = 0; u < _uploadFileData.length; u++) {
            var row = _uploadFileData[u];
            if (!row._valid || !row.item_code) continue;
            items.push({ item_code: row.item_code, qty: row.qty });
        }

        if (!items.length) {
            showToast('لا توجد صفوف صالحة للتنفيذ', 'warning');
            return;
        }

        var operationFingerprint = branchId + '|' + adjType + '|' + reason + '|' + items.map(function(x) { return x.item_code + ':' + x.qty; }).sort().join('|');
        if (!_uploadOperationId || _uploadOperationFingerprint !== operationFingerprint) {
            var randomPart = (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') ? crypto.randomUUID() : (Date.now() + '-' + Math.floor(Math.random() * 1000000));
            _uploadOperationId = 'ADJ-' + new Date().toISOString().split('T')[0].replace(/-/g, '') + '-' + randomPart;
            _uploadOperationFingerprint = operationFingerprint;
        }
        var voucherCode = _uploadOperationId;
        var payload = { branch_id: branchId, adjustment_type: adjType, voucher_code: voucherCode, reason: reason, items: items };

        var executeBtn = byId('btn-execute-upload');
        if (executeBtn) { executeBtn.disabled = true; executeBtn.innerText = 'جارٍ...'; }
        showLoader('جاري تحديث الأرصدة...');

        supabase.auth.getSession().then(function(ses) {
            var token = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
            if (!token) { hideLoader(); showToast('جلسة غير صالحة', 'error'); if (executeBtn) { executeBtn.disabled = false; executeBtn.innerText = 'تنفيذ التحديث'; } return; }
            return fetch(RW_SUPABASE_URL + '/functions/v1/bulk-stock-adjustment', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
                body: JSON.stringify(payload)
            });
        }).then(function(res) {
            if (!res) return;
            if (!res.ok) return res.json().then(function(err) { throw new Error(err.msg || err.error || 'خطأ في الخادم'); });
            return res.json();
        }).then(function(json) {
            hideLoader();
            if (json && json.success) {
                var successCount = Number(json.movement_count || 0);
                var failCount = 0;
                showToast('تم تحديث ' + successCount + ' صنف بنجاح', successCount > 0 ? 'success' : 'warning');
                
                // ✅ إعادة تحميل الأصناف والمخزون فوراً بعد التحديث
                showLoader('جاري تحديث البيانات...');
				_uploadFileData = [];
                _uploadOperationId = null;
                _uploadOperationFingerprint = null;
				var uploadFileInput = byId('upload-file-input');
				if (uploadFileInput) uploadFileInput.value = '';
                RW_Data.loadItems().then(function(newData) {
                    itemsData = newData;
                    return _loadStockData();
                }).then(function() {
                    hideLoader();
                    // تحديث التبويب الحالي (إذا كان مفتوحاً على الأرصدة أو القائمة)
                    if (currentSubTab === 'matrix') {
                        _renderBranchStockMatrix();
                    } else {
                        _renderListView();
                    }
                }).catch(function() {
                    hideLoader();
                    _renderUploadTab();
                });
            } else { showToast((json && json.msg) || 'فشل التحديث', 'error'); if (executeBtn) { executeBtn.disabled = false; executeBtn.innerText = 'تنفيذ التحديث'; } }
        }).catch(function(e) { hideLoader(); showToast('فشل الاتصال: ' + e.message, 'error'); if (executeBtn) { executeBtn.disabled = false; executeBtn.innerText = 'تنفيذ التحديث'; } });
    }
    // دالة تصدير جدول الأرصدة إلى ملف Excel
    function _exportMatrixToExcel() {
        // 1. جلب البيانات المطلوبة
        var branches = window._itemsBranches || [];
        var branchIds = window._itemsBranchIds || [];
        
        // قراءة الفلاتر الحالية
        var q = (byId('matrix-search') ? byId('matrix-search').value : '').toLowerCase();
        var selectedBranch = (byId('matrix-branch-select') ? byId('matrix-branch-select').value : '');
        
        // تصفية البيانات (نسخة طبق الأصل من _filterMatrix)
        var filtered = itemsData.slice();
        if (q) {
            filtered = filtered.filter(function(i) {
                return (i.name||'').toLowerCase().indexOf(q) !== -1 || (i.item_code||'').toLowerCase().indexOf(q) !== -1;
            });
        }
        if (selectedBranch) {
            filtered = filtered.filter(function(item) {
                var bs = item._branchStock || {};
                return bs.hasOwnProperty(selectedBranch) && (bs[selectedBranch].qty > 0);
            });
        }

        if (filtered.length === 0) {
            showToast('لا توجد بيانات للتصدير', 'warning');
            return;
        }

        // 2. بناء مصفوفة التصدير (Array of Arrays)
        var exportData = [];
        
        // صف الرؤوس
        var headers = ['الباركود', 'كود الصنف', 'اسم الصنف', 'إجمالي المخزون'];
        for (var h = 0; h < branchIds.length; h++) {
            var branchName = '';
            for (var bn = 0; bn < branches.length; bn++) {
                if ((branches[bn].id || branches[bn].branch_code) === branchIds[h]) {
                    branchName = branches[bn].name || branches[bn].branch_code || branchIds[h];
                    break;
                }
            }
            headers.push(branchName);
        }
        exportData.push(headers);

        // صفوف البيانات
        for (var i = 0; i < filtered.length; i++) {
            var item = filtered[i];
            var row = [
                item.barcode || '', // الباركود
                item.item_code || '', // كود الصنف
                item.name || '', // اسم الصنف
                item._totalStock || 0 // إجمالي المخزون
            ];
            
            var branchStock = item._branchStock || {};
            for (var j = 0; j < branchIds.length; j++) {
                var bid = branchIds[j];
                var st = branchStock[bid] || { qty: 0 };
                row.push(st.qty);
            }
            exportData.push(row);
        }

        // 3. إنشاء ملف Excel
        try {
            var ws = XLSX.utils.aoa_to_sheet(exportData);
            var wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, "ارصدة الفروع");
            XLSX.writeFile(wb, "ارصدة_الفروع_" + new Date().toISOString().split('T')[0] + ".xlsx");
            showToast('تم تحميل الملف بنجاح', 'success');
        } catch (e) {
            console.error(e);
            showToast('فشل التصدير', 'error');
        }
    }

    return {
        // الدوال الأساسية
        render: render,
        _openModal: openItemPage,
        openItemPage: openItemPage,

        // تبويبات الصنف والفرز
        _switchItemTab: _switchItemTab,
        _sort: _sort,

        // إدارة التصنيفات
        _openCategoryModal: _openCategoryModal,
        _addCategory: _addCategory,
        _editCategory: _editCategory,
        _deleteCategory: _deleteCategory,
        _executeDeleteCategory: _executeDeleteCategory,

        // حفظ وحذف الصنف
        _handleSaveFromPage: _handleSaveFromPage,
        _handleDeleteFromPage: _handleDeleteFromPage,

        // عرض الصور وحركة المخزون
        _viewImage: _viewImage,
        _showBranchStockMovement: _showBranchStockMovement,

        // التبويبات الفرعية والفلاتر
        _switchSubTab: _switchSubTab,
        _applyFilters: _applyFilters,
        _resetFilters: _resetFilters,

        // تقارير حركة الصنف
        _renderStockMovementReport: _renderStockMovementReport,
        _loadMovementReport: _loadMovementReport,

        // مصفوفة الفروع
        _filterMatrix: _filterMatrix,
        _exportMatrixToExcel: _exportMatrixToExcel,

        // تحديث الأرصدة عبر ملف
        _handleFileSelect: _handleFileSelect,
        _executeUpload: _executeUpload
    };
})();
window.RW_Items = RW_Items;
