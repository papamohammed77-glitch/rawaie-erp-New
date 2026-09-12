function _openPickingModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات التحضير...');

    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }

    window._pickingPendingOps = window._pickingPendingOps || {};

    supabase.from('runsheets')
        .select('id')
        .eq('company_id', companyId)
        .eq('runsheet_code', rsCode)
        .maybeSingle()
        .then(function(rsRes) {
            if (rsRes.error) throw rsRes.error;
            if (!rsRes.data) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return; }
            var runsheetUuid = rsRes.data.id;

            return supabase.from('run_sheet_details')
                .select('*')
                .eq('runsheet_id', runsheetUuid)
                .order('item_code')
                .then(function(itemsRes) {
                    if (itemsRes.error) throw itemsRes.error;
                    var items = itemsRes.data || [];
                    if (items.length === 0) { hideLoader(); showToast('لا توجد أصناف في هذا الرانشيت', 'info'); return; }

                    showLoader('جاري بدء التحضير...');
                    return supabase.auth.getSession().then(function(ses) {
                        var token = ses.data.session ? ses.data.session.access_token : null;
                        if (!token) throw new Error('انتهت الجلسة');
                        return fetch(RW_SUPABASE_URL + '/functions/v1/start-picking', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
                            body: JSON.stringify({ runsheet_code: rsCode })
                        });
                    }).then(function(res) { return res.json().then(function(json) { if (!res.ok || !json.success) throw new Error(json.msg || json.error || 'فشل بدء التحضير'); return json; }); }).then(function(startJson) {
                        hideLoader();

                        var operationId = window._pickingPendingOps[rsCode];
                        if (!operationId) {
                            operationId = (window.crypto && window.crypto.randomUUID) ? window.crypto.randomUUID() : ('PICK-' + Date.now() + '-' + Math.random().toString(36).slice(2));
                            window._pickingPendingOps[rsCode] = operationId;
                        }

                        var html = '<div class="text-right" dir="rtl"><div class="max-h-[420px] overflow-y-auto"><table class="w-full border"><thead class="bg-slate-100"><tr>' +
                            '<th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">الكمية المطلوبة</th><th class="p-2 text-center">الكمية المحضرة</th></tr></thead><tbody>';
                        for (var i = 0; i < items.length; i++) {
                            var it = items[i];
                            var ordered = Number(it.qty_ordered) || 0;
                            var picked = Number(it.qty_picked) || 0;
                            html += '<tr><td class="p-2 border"><p class="font-bold">' + esc(it.item_name || '') + '</p><p class="text-xs">' + esc(it.item_code || '') + '</p></td>' +
                                '<td class="p-2 border text-center">' + esc(it.unit || 'حبة') + '</td>' +
                                '<td class="p-2 border text-center font-bold">' + ordered + '</td>' +
                                '<td class="p-2 border text-center"><input type="number" id="picked_qty_' + i + '" class="w-24 p-2 border rounded text-center" step="0.01" min="0" max="' + ordered + '" value="' + (picked || ordered) + '"></td></tr>';
                        }
                        html += '</tbody></table></div></div>';

                        Swal.fire({
                            title: 'تحضير الرانشيت: ' + esc(rsCode),
                            html: html,
                            width: '850px',
                            showCancelButton: true,
                            confirmButtonText: 'إنهاء التحضير',
                            cancelButtonText: 'إلغاء',
                            preConfirm: function() {
                                var itemsData = [];
                                var hasQty = false;
                                for (var j = 0; j < items.length; j++) {
                                    var orderedQty = Number(items[j].qty_ordered) || 0;
                                    var qty = parseFloat((document.getElementById('picked_qty_' + j) || {}).value);
                                    if (!Number.isFinite(qty)) qty = 0;
                                    if (qty < 0 || qty > orderedQty) {
                                        Swal.showValidationMessage('الكمية المحضرة يجب أن تكون بين 0 والكمية المطلوبة للصنف: ' + (items[j].item_code || ''));
                                        return false;
                                    }
                                    if (qty > 0) hasQty = true;
                                    itemsData.push({ itemCode: items[j].item_code, pickedQty: qty, notes: '' });
                                }
                                if (!hasQty) { Swal.showValidationMessage('يجب تحضير كمية واحدة على الأقل'); return false; }
                                return itemsData;
                            }
                        }).then(function(result) {
                            if (!result.isConfirmed) {
                                delete window._pickingPendingOps[rsCode];
                                return;
                            }
                            showLoader('جاري إنهاء التحضير...');
                            return supabase.auth.getSession().then(function(ses2) {
                                var token2 = ses2.data.session ? ses2.data.session.access_token : null;
                                if (!token2) throw new Error('انتهت الجلسة');
                                return fetch(RW_SUPABASE_URL + '/functions/v1/complete-picking', {
                                    method: 'POST',
                                    headers: {
                                        'Content-Type': 'application/json',
                                        Authorization: 'Bearer ' + token2,
                                        'Idempotency-Key': operationId
                                    },
                                    body: JSON.stringify({ runsheet_code: rsCode, items: result.value, operation_id: operationId })
                                });
                            }).then(function(res) {
                                return res.json().catch(function() { return {}; }).then(function(compJson) {
                                    if (!res.ok || !compJson.success) throw new Error(compJson.msg || compJson.error || 'فشل إنهاء التحضير');
                                    return compJson;
                                });
                            }).then(function(compJson) {
                                hideLoader();
                                delete window._pickingPendingOps[rsCode];
                                showToast(compJson.duplicate ? 'تم استرجاع نتيجة التحضير السابقة' : 'تم إنهاء التحضير بنجاح', 'success');
                                if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
                            }).catch(function(e) {
                                hideLoader();
                                showToast(e.message || 'فشل الاتصال؛ يمكن إعادة المحاولة بنفس العملية', 'error');
                            });
                        });
                    });
                });
        })
        .catch(function(e) {
            hideLoader();
            showToast(e.message || 'فشل تحميل بيانات التحضير', 'error');
        });
}
