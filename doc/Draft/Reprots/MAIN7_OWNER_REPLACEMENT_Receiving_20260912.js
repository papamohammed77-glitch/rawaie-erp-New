    async function loadReceiving() {
        var c = byId('rw-page-container');
        if (!c) return;

        safeText(byId('rw-header-title'), 'الاستلام (Receiving)');
        safeHTML(c, '<div class="p-4">' +
            '<div class="bg-white rounded-2xl shadow-sm border p-4 mb-4"><div class="grid grid-cols-2 md:grid-cols-6 gap-2">' +
                '<input type="text" id="rec-filter-id" placeholder="رقم العملية..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReceiving()">' +
                '<input type="text" id="rec-filter-po" placeholder="رقم أمر الشراء..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReceiving()">' +
                '<input type="text" id="rec-filter-resp" placeholder="المسؤول..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyReceiving()">' +
                '<input type="date" id="rec-filter-date-from" class="p-2 bg-slate-50 rounded text-sm" onchange="RW_Warehouse._applyReceiving()">' +
                '<input type="date" id="rec-filter-date-to" class="p-2 bg-slate-50 rounded text-sm" onchange="RW_Warehouse._applyReceiving()">' +
                '<button onclick="RW_Warehouse._applyReceiving()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>' +
            '</div></div>' +
            '<div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh"><table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr>' +
                '<th class="p-3">رقم العملية</th><th class="p-3">التاريخ</th><th class="p-3">أمر الشراء</th><th class="p-3">المسؤول</th><th class="p-3">الأصناف</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th>' +
            '</tr></thead><tbody id="rec-table"><tr><td colspan="7" class="text-center py-8">جاري التحميل...</td></tr></tbody></table></div>' +
        '</div>');

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }

        var res = await supabase.from('receiving')
            .select('*')
            .eq('company_id', companyId)
            .order('date', { ascending: false });
        if (res.error) { showToast(res.error.message, 'error'); return; }

        var rows = res.data || [];
        var opIds = rows.map(function(r) { return r.operation_id; }).filter(Boolean);
        var counts = {};
        if (opIds.length) {
            var detailsRes = await supabase.from('receiving_details')
                .select('operation_id')
                .in('operation_id', opIds);
            if (detailsRes.error) { showToast(detailsRes.error.message, 'error'); return; }
            var details = detailsRes.data || [];
            for (var i = 0; i < details.length; i++) {
                counts[details[i].operation_id] = (counts[details[i].operation_id] || 0) + 1;
            }
        }

        window._receivingData = rows.map(function(r) {
            var x = Object.assign({}, r);
            x.itemsCount = counts[r.operation_id] || 0;
            return x;
        });
        _applyReceiving();
    }

    function _applyReceiving() {
        var d = window._receivingData || [];
        var id = (byId('rec-filter-id')?.value || '').trim().toLowerCase();
        var po = (byId('rec-filter-po')?.value || '').trim().toLowerCase();
        var resp = (byId('rec-filter-resp')?.value || '').trim().toLowerCase();
        var fd = byId('rec-filter-date-from')?.value;
        var td = byId('rec-filter-date-to')?.value;

        if (id) d = d.filter(function(r) { return String(r.operation_id || '').toLowerCase().indexOf(id) !== -1; });
        if (po) d = d.filter(function(r) { return String(r.po_number || '').toLowerCase().indexOf(po) !== -1; });
        if (resp) d = d.filter(function(r) { return String(r.responsible || '').toLowerCase().indexOf(resp) !== -1; });
        if (fd) d = d.filter(function(r) { return r.date >= fd; });
        if (td) d = d.filter(function(r) { return r.date <= td; });

        var tb = byId('rec-table');
        if (!tb) return;
        if (!d.length) { safeHTML(tb, '<tr><td colspan="7" class="text-center py-8">لا توجد عمليات استلام</td></tr>'); return; }

        var h = '';
        d.forEach(function(op) {
            var opId = String(op.operation_id || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
            h += "<tr class=\"border-b hover:bg-gray-50 cursor-pointer\" onclick=\"RW_Warehouse._showReceivingDetails('" + opId + "')\">" +
                '<td class="p-3 font-bold text-blue-600">' + esc(op.operation_id || '') + '</td>' +
                '<td class="p-3">' + esc(op.date || '') + '</td>' +
                '<td class="p-3">' + esc(op.po_number || '---') + '</td>' +
                '<td class="p-3">' + esc(op.responsible || '---') + '</td>' +
                '<td class="p-3 text-center">' + Number(op.itemsCount || 0) + '</td>' +
                '<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-green-100 text-green-700">' + esc(op.status || 'مكتمل') + '</span></td>' +
                "<td class=\"p-3 text-center\"><button class=\"text-blue-600\" onclick=\"event.stopPropagation(); RW_Warehouse._showReceivingDetails('" + opId + "')\"><i class=\"fa-solid fa-eye\"></i></button></td>" +
            '</tr>';
        });
        safeHTML(tb, h);
    }
