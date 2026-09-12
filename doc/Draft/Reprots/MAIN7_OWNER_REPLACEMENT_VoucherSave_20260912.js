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

    window._warehouseVoucherOperations = window._warehouseVoucherOperations || {};
    var fingerprint = [
        companyId,
        currentVoucherType,
        entity,
        reference,
        notes,
        repId || '',
        JSON.stringify(items)
    ].join('|');
    var operationId = window._warehouseVoucherOperations[fingerprint];
    if (!operationId) {
        operationId = (window.crypto && window.crypto.randomUUID) ? window.crypto.randomUUID() : ('WHV-' + Date.now() + '-' + Math.random().toString(36).slice(2));
        window._warehouseVoucherOperations[fingerprint] = operationId;
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
            rep_id: repId,
            operation_id: operationId
        };

        var createRes = await fetch(RW_SUPABASE_URL + '/functions/v1/create-stock-voucher', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token,
                'Idempotency-Key': operationId
            },
            body: JSON.stringify(createBody)
        });

        var createJson = await createRes.json().catch(function() { return {}; });
        if (!createRes.ok || !createJson.success) {
            throw new Error(createJson.msg || createJson.error || 'فشل حفظ الإذن');
        }

        var voucherCode = createJson.voucherId || createJson.voucher_code;
        if (!voucherCode) throw new Error('لم يُرجع إنشاء الإذن رقمًا صالحًا');

        var sendRes = await fetch(RW_SUPABASE_URL + '/functions/v1/send-stock-voucher', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token,
                'Idempotency-Key': operationId
            },
            body: JSON.stringify({ voucher_code: voucherCode })
        });

        var sendJson = await sendRes.json().catch(function() { return {}; });
        if (!sendRes.ok || !sendJson.success) {
            throw new Error(sendJson.msg || sendJson.error || 'فشل الإرسال');
        }

        hideLoader();
        delete window._warehouseVoucherOperations[fingerprint];
        showToast(sendJson.duplicate ? 'تم استرجاع نتيجة الإذن السابقة' : ('تم إنشاء وإرسال الإذن ' + voucherCode), 'success');
        voucherCart = [];
        _renderVoucherCart();
        if (typeof loadVouchers === 'function') await loadVouchers();
    } catch (e) {
        hideLoader();
        showToast(e.message || 'فشل الاتصال؛ يمكن إعادة المحاولة بنفس العملية', 'error');
    }
}
