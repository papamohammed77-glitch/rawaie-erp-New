    async function _onSettlementRsChange() {
        var rsCode = byId('settlement-rs-select')?.value || '';
        var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
        var detailsContainer = byId('settlement-details-container');

        if (!rsCode) {
            if (detailsContainer) detailsContainer.classList.add('hidden');
            window._settlementData = null;
            return;
        }
        if (!companyId) {
            showToast('سياق الشركة غير محدد', 'error');
            return;
        }

        showLoader('جاري تحميل بيانات التسوية...');
        try {
            var rsRes = await supabase.from('runsheets')
                .select('id,runsheet_code,status,driver_id,vehicle_id,run_date')
                .eq('company_id', companyId)
                .eq('runsheet_code', rsCode)
                .maybeSingle();
            if (rsRes.error) throw rsRes.error;
            if (!rsRes.data) throw new Error('الرانشيت غير موجود في الشركة الحالية');
            if (['Delivered', 'Returned'].indexOf(rsRes.data.status) === -1) {
                throw new Error('التسوية متاحة فقط للرانشيتات التي وصلت إلى Delivered أو Returned');
            }

            var detailsRes = await supabase.from('run_sheet_details')
                .select('item_code,item_name,unit,qty_loaded,qty_delivered,qty_returned,unit_price')
                .eq('runsheet_id', rsRes.data.id)
                .order('item_code');
            if (detailsRes.error) throw detailsRes.error;
            var details = detailsRes.data || [];

            var countedByItem = {};
            if (rsRes.data.vehicle_id) {
                var countRes = await supabase.from('inventory_counts')
                    .select('id')
                    .eq('company_id', companyId)
                    .eq('type', 'vehicle')
                    .eq('entity_id', rsRes.data.vehicle_id)
                    .order('created_at', { ascending: false })
                    .limit(1)
                    .maybeSingle();
                if (countRes.error) throw countRes.error;
                if (countRes.data) {
                    var countDetailsRes = await supabase.from('inventory_count_details')
                        .select('item_code,counted_qty')
                        .eq('count_id', countRes.data.id);
                    if (countDetailsRes.error) throw countDetailsRes.error;
                    var countDetails = countDetailsRes.data || [];
                    for (var ci = 0; ci < countDetails.length; ci++) {
                        countedByItem[countDetails[ci].item_code] = Number(countDetails[ci].counted_qty) || 0;
                    }
                }
            }

            var items = [];
            var totalShortage = 0;
            var totalShortageValue = 0;
            var html = '';

            for (var i = 0; i < details.length; i++) {
                var d = details[i];
                var loaded = Number(d.qty_loaded) || 0;
                var delivered = Number(d.qty_delivered) || 0;
                var returned = Number(d.qty_returned) || 0;
                var counted = Object.prototype.hasOwnProperty.call(countedByItem, d.item_code) ? countedByItem[d.item_code] : null;
                var shortage = Math.max(0, loaded - delivered - returned);
                var shortageValue = shortage * (Number(d.unit_price) || 0);

                totalShortage += shortage;
                totalShortageValue += shortageValue;
                items.push({
                    itemCode: d.item_code,
                    itemName: d.item_name,
                    unit: d.unit,
                    loadedQty: loaded,
                    deliveredQty: delivered,
                    returnedQty: returned,
                    countedQty: counted,
                    shortage: shortage,
                    unitPrice: Number(d.unit_price) || 0,
                    shortageValue: shortageValue
                });

                html += '<tr class="border-b">' +
                    '<td class="p-2">' + esc(d.item_name || '') + '<div class="text-xs text-gray-400">' + esc(d.item_code || '') + '</div></td>' +
                    '<td class="p-2 text-center">' + loaded + '</td>' +
                    '<td class="p-2 text-center">' + delivered + '</td>' +
                    '<td class="p-2 text-center">' + returned + '</td>' +
                    '<td class="p-2 text-center font-bold">' + (counted == null ? '—' : counted) + '</td>' +
                    '<td class="p-2 text-center font-black ' + (shortage > 0 ? 'text-red-600' : 'text-emerald-600') + '">' + shortage + '</td>' +
                    '<td class="p-2 text-center">' + Math.abs(shortageValue).toLocaleString() + ' EGP</td>' +
                '</tr>';
            }

            safeHTML(byId('settlement-items-body'), html || '<tr><td colspan="7" class="p-6 text-center">لا توجد بيانات</td></tr>');
            safeHTML(byId('settlement-rs-info'),
                '<strong>المندوب:</strong> ' + esc(rsRes.data.driver_id || '---') +
                ' | <strong>السيارة:</strong> ' + esc(rsRes.data.vehicle_id || '---') +
                ' | <strong>التاريخ:</strong> ' + esc(rsRes.data.run_date || '---') +
                '<div class="mt-2 text-xs text-slate-500">ملاحظة: التسوية المحاسبية تعتمد على المحمّل − المسلّم − المرتجع كما يطبّقها محرك التسوية في Production. كمية الجرد المعروضة مرجعية للتحقق فقط ولا تُخصم من نتيجة العجز آليًا.</div>');

            if (detailsContainer) detailsContainer.classList.remove('hidden');
            window._settlementData = {
                rs: rsRes.data,
                items: items,
                totalShortage: totalShortage,
                totalShortageValue: totalShortageValue
            };
            hideLoader();
        } catch (e) {
            hideLoader();
            window._settlementData = null;
            if (detailsContainer) detailsContainer.classList.add('hidden');
            showToast('فشل تحميل بيانات التسوية: ' + (e.message || ''), 'error');
        }
    }

    function _saveSettlement() {
        var data = window._settlementData;
        if (!data) {
            showToast('اختر رانشيتاً أولاً', 'warning');
            return;
        }
        var rs = data.rs;
        if (!rs || !rs.runsheet_code) {
            showToast('بيانات الرانشيت غير مكتملة', 'error');
            return;
        }

        window._settlementPendingOps = window._settlementPendingOps || {};
        var operationId = window._settlementPendingOps[rs.runsheet_code];
        if (!operationId) {
            operationId = (window.crypto && window.crypto.randomUUID) ? window.crypto.randomUUID() : ('SETTLE-' + Date.now() + '-' + Math.random().toString(36).slice(2));
            window._settlementPendingOps[rs.runsheet_code] = operationId;
        }

        showLoader('جاري حفظ التسوية...');
        supabase.auth.getSession().then(function(ses) {
            var token = (ses && ses.data && ses.data.session) ? ses.data.session.access_token : null;
            if (!token) throw new Error('انتهت الجلسة');

            return fetch(RW_SUPABASE_URL + '/functions/v1/save-daily-settlement', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ' + token,
                    'Idempotency-Key': operationId
                },
                body: JSON.stringify({
                    runsheet_code: rs.runsheet_code,
                    notes: 'تسوية يومية للرانشيت ' + rs.runsheet_code,
                    operation_id: operationId
                })
            });
        }).then(function(res) {
            return res.json().catch(function() { return {}; }).then(function(json) {
                if (!res.ok || !json || !json.success) {
                    throw new Error((json && (json.msg || json.error)) || 'فشل حفظ التسوية');
                }
                return json;
            });
        }).then(function(json) {
            hideLoader();
            delete window._settlementPendingOps[rs.runsheet_code];
            showToast(json.duplicate ? 'تم استرجاع نتيجة التسوية السابقة' : ('تم حفظ التسوية: ' + (json.settlement_code || rs.runsheet_code)), 'success');
            var container = byId('settlement-details-container');
            if (container) container.classList.add('hidden');
            var sel = byId('settlement-rs-select');
            if (sel) sel.value = '';
            window._settlementData = null;
        }).catch(function(e) {
            hideLoader();
            showToast(e.message || 'فشل الاتصال؛ يمكن إعادة المحاولة بنفس رقم العملية', 'error');
        });
    }
