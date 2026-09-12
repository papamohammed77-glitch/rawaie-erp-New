    async function loadUnloading() {
        var c = byId('rw-page-container');
        if (!c) return;

        safeText(byId('rw-header-title'), 'التفريغ (Unloading)');
        safeHTML(c, '<div class="p-4">' +
            '<div class="bg-white rounded-2xl shadow-sm border p-4 mb-4">' +
                '<div class="grid grid-cols-2 md:grid-cols-6 gap-2">' +
                    '<input type="text" id="ul-f-id" placeholder="رقم الرانشيت..." class="p-2 bg-slate-50 rounded text-sm" oninput="RW_Warehouse._applyUnloading()">' +
                    '<button onclick="RW_Warehouse._applyUnloading()" class="bg-gray-600 text-white px-3 rounded text-sm">تطبيق</button>' +
                '</div>' +
            '</div>' +
            '<div class="bg-white rounded-2xl shadow-sm border overflow-auto" style="max-height:65vh">' +
                '<table class="w-full"><thead class="bg-gray-50 sticky top-0"><tr>' +
                    '<th class="p-3">الرانشيت</th><th class="p-3">التاريخ</th><th class="p-3">السائق</th><th class="p-3">الحالة</th><th class="p-3 text-center">عرض</th>' +
                '</tr></thead><tbody id="ul-table"><tr><td colspan="5" class="text-center py-8">جاري التحميل...</td></tr></tbody></table>' +
            '</div>' +
        '</div>');

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) {
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        var res = await supabase.from('runsheets')
            .select('id,runsheet_code,run_date,driver_id,vehicle_id,status')
            .eq('company_id', companyId)
            .eq('status', 'Loaded')
            .order('run_date', { ascending: false });

        if (res.error) {
            showToast(res.error.message, 'error');
            return;
        }

        window._unloadingData = res.data || [];
        _applyUnloading();
    }

    function _applyUnloading() {
        var d = window._unloadingData || [];
        var id = (byId('ul-f-id')?.value || '').trim().toLowerCase();
        if (id) {
            d = d.filter(function(r) {
                return String(r.runsheet_code || '').toLowerCase().indexOf(id) !== -1;
            });
        }

        var tb = byId('ul-table');
        if (!tb) return;

        if (!d.length) {
            safeHTML(tb, '<tr><td colspan="5" class="text-center py-8">لا توجد رانشيتات جاهزة للتفريغ</td></tr>');
            return;
        }

        RW_Table.paginate('ul-table', d, 1, 50, function(r) {
            var code = String(r.runsheet_code || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
            return "<tr class=\"border-b hover:bg-gray-50 cursor-pointer\" onclick=\"RW_Warehouse._showUnloadingDetails('" + code + "')\">" +
                '<td class="p-3 font-bold">' + esc(r.runsheet_code || '') + '</td>' +
                '<td class="p-3">' + esc(r.run_date || '') + '</td>' +
                '<td class="p-3">' + esc(r.driver_id || '---') + '</td>' +
                '<td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-orange-100 text-orange-700">Loaded</span></td>' +
                "<td class=\"p-3 text-center\"><button class=\"text-blue-600\" onclick=\"event.stopPropagation(); RW_Warehouse._showUnloadingDetails('" + code + "')\"><i class=\"fa-solid fa-eye\"></i></button></td>" +
            '</tr>';
        });
    }

    async function _showUnloadingDetails(code) {
        if (!code) {
            showToast('رقم الرانشيت غير صالح', 'error');
            return;
        }

        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        if (!companyId) {
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        showLoader('جاري تحميل تفاصيل التفريغ...');
        try {
            var rsRes = await supabase.from('runsheets')
                .select('id,runsheet_code,run_date,driver_id,vehicle_id,status')
                .eq('company_id', companyId)
                .eq('runsheet_code', code)
                .maybeSingle();

            if (rsRes.error) throw rsRes.error;
            if (!rsRes.data) throw new Error('الرانشيت غير موجود في الشركة الحالية');
            if (rsRes.data.status !== 'Loaded') throw new Error('الرانشيت ليس في حالة Loaded؛ لا يمكن اعتباره جاهزًا للتفريغ');

            var detailsRes = await supabase.from('run_sheet_details')
                .select('item_code,item_name,unit,qty_ordered,qty_picked,qty_loaded,qty_delivered,qty_refused,qty_returned')
                .eq('runsheet_id', rsRes.data.id)
                .order('item_code');

            if (detailsRes.error) throw detailsRes.error;

            var details = detailsRes.data || [];
            if (!details.length) {
                hideLoader();
                showToast('لا توجد تفاصيل أصناف لهذا الرانشيت', 'info');
                return;
            }

            var loadedTotal = 0;
            var remainingTotal = 0;
            var html = '<div class="text-right" dir="rtl">';
            html += '<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">' +
                '<div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-500">الرانشيت</div><div class="font-black">' + esc(rsRes.data.runsheet_code) + '</div></div>' +
                '<div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-500">السائق</div><div class="font-bold">' + esc(rsRes.data.driver_id || '---') + '</div></div>' +
                '<div class="bg-slate-50 rounded-xl p-3"><div class="text-xs text-slate-500">السيارة</div><div class="font-bold">' + esc(rsRes.data.vehicle_id || '---') + '</div></div>' +
            '</div>';
            html += '<div class="mb-3 p-3 bg-orange-50 border border-orange-100 rounded-xl text-sm font-bold text-orange-800">هذه الشاشة للعرض والتأكد من الحمولة قبل التفريغ. تنفيذ التفريغ نفسه يتم عبر <code>unload-runsheet</code> ولا يتم هنا إجراء أي تعديل مخزني.</div>';
            html += '<div class="overflow-auto max-h-[55vh]"><table class="w-full border text-sm"><thead class="bg-gray-100 sticky top-0"><tr>' +
                '<th class="p-2 border">الكود</th><th class="p-2 border">الصنف</th><th class="p-2 border text-center">الوحدة</th><th class="p-2 border text-center">محمّل</th><th class="p-2 border text-center">مسلّم</th><th class="p-2 border text-center">مرفوض</th><th class="p-2 border text-center">مرتجع</th><th class="p-2 border text-center">المتبقي</th>' +
                '</tr></thead><tbody>';

            for (var i = 0; i < details.length; i++) {
                var d = details[i];
                var loaded = Number(d.qty_loaded) || 0;
                var delivered = Number(d.qty_delivered) || 0;
                var refused = Number(d.qty_refused) || 0;
                var returned = Number(d.qty_returned) || 0;
                var remaining = Math.max(0, loaded - delivered - refused - returned);
                loadedTotal += loaded;
                remainingTotal += remaining;

                html += '<tr class="border-b">' +
                    '<td class="p-2 border">' + esc(d.item_code || '') + '</td>' +
                    '<td class="p-2 border font-semibold">' + esc(d.item_name || '') + '</td>' +
                    '<td class="p-2 border text-center">' + esc(d.unit || 'حبة') + '</td>' +
                    '<td class="p-2 border text-center font-bold text-orange-700">' + loaded + '</td>' +
                    '<td class="p-2 border text-center">' + delivered + '</td>' +
                    '<td class="p-2 border text-center">' + refused + '</td>' +
                    '<td class="p-2 border text-center">' + returned + '</td>' +
                    '<td class="p-2 border text-center font-black ' + (remaining > 0 ? 'text-red-600' : 'text-emerald-600') + '">' + remaining + '</td>' +
                '</tr>';
            }

            html += '</tbody></table></div>';
            html += '<div class="mt-4 grid grid-cols-2 gap-3">' +
                '<div class="bg-orange-50 rounded-xl p-3 text-center"><div class="text-xs text-slate-500">إجمالي المحمّل</div><div class="text-xl font-black text-orange-700">' + loadedTotal + '</div></div>' +
                '<div class="bg-slate-50 rounded-xl p-3 text-center"><div class="text-xs text-slate-500">المتبقي قبل التفريغ</div><div class="text-xl font-black">' + remainingTotal + '</div></div>' +
            '</div></div>';

            hideLoader();
            Swal.fire({
                title: 'تفاصيل التفريغ: ' + esc(code),
                html: html,
                width: '1100px',
                showCloseButton: true,
                showConfirmButton: false
            });
        } catch (e) {
            hideLoader();
            showToast(e.message || 'فشل تحميل تفاصيل التفريغ', 'error');
        }
    }
