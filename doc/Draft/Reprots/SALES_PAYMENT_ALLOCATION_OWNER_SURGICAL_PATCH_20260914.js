/* RAWAEA ERP — OWNER-SIDE SURGICAL PATCH — Multiple / Partial Sales Payment Allocation
 * TARGET ONLY: papamohammed77-glitch/erp-frontend/companies/company-1/main.html
 * Current source SHA verified in session: aaf36b090516e057b45607444138905609018eeb
 * Current HEAD: e5176010a2bb1a246eaa9f5943a79542af42ee66
 * DO NOT modify Current/PWA/main2, New-main, or historical fragments.
 */

/* ============================================================
   PATCH A — Replace _renderReceipts() completely
   CURRENT LINE: 11264
   DELETE through the function's final line at CURRENT LINE: 11273
   Last deleted line:
       }
   (the closing brace immediately before function _buildReceiptsTable(data))
   ============================================================ */
function _renderReceipts() {
    var content = byId('finance-content');
    if (!content) return;

    content.innerHTML =
        '<div class="space-y-5">' +
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="flex flex-wrap justify-between items-center gap-3 mb-5">' +
                    '<div>' +
                        '<h2 class="text-xl font-black"><i class="fa-solid fa-file-invoice-dollar ml-2 text-green-600"></i>قبض العملاء وتخصيص الدفعات</h2>' +
                        '<p class="text-sm text-gray-500 mt-1">دفعة واحدة يمكن تخصيصها على فاتورة واحدة أو عدة فواتير، مع دعم السداد الجزئي والرصيد غير المخصص.</p>' +
                    '</div>' +
                    '<div class="flex gap-2">' +
                        '<button onclick="RW_Finance._newCustomerReceipt()" class="bg-green-600 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-hand-holding-dollar ml-1"></i> تحصيل عميل</button>' +
                        '<button onclick="RW_Finance._newReceipt()" class="bg-slate-700 text-white px-4 py-2 rounded-xl font-bold"><i class="fa-solid fa-plus ml-1"></i> سند قبض عام</button>' +
                    '</div>' +
                '</div>' +
                '<div id="sales-payment-receipts-list"><div class="text-center py-8"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل سندات التحصيل...</div></div>' +
            '</div>' +
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="flex justify-between items-center mb-3"><h3 class="font-black text-lg">السندات العامة</h3></div>' +
                '<div id="receipts-list"><div class="text-center py-6 text-gray-500">جاري التحميل...</div></div>' +
            '</div>' +
        '</div>';

    var companyId = _companyId();
    Promise.all([
        _customerPaymentFetch({ action: 'list' }),
        supabase.from('cash_box').select('*').eq('company_id', companyId).eq('type', 'Receipt').order('voucher_date', { ascending: false })
    ]).then(function(results) {
        var paymentJson = results[0];
        var cashBoxRes = results[1];
        if (cashBoxRes.error) throw cashBoxRes.error;

        _renderCustomerPaymentReceiptList(paymentJson);
        safeHTML(byId('receipts-list'), _buildReceiptsTable(cashBoxRes.data || []));
    }).catch(function(e) {
        safeHTML(byId('sales-payment-receipts-list'), '<div class="text-center py-6 text-red-500">' + _esc(e.message || 'فشل تحميل سندات التحصيل') + '</div>');
        safeHTML(byId('receipts-list'), '<div class="text-center py-6 text-red-500">' + _esc(e.message || 'فشل تحميل السندات العامة') + '</div>');
    });
}

/* ============================================================
   PATCH B — Add the complete Customer Payment Allocation module
   LOCATION: immediately ABOVE the exact current line below
       function _renderPayments() {
   CURRENT LINE: 11357
   Insert the entire block below without changing function _renderPayments().
   ============================================================ */
function _customerPaymentEndpoint() {
    return RW_SUPABASE_URL + '/functions/v1/sales-payment-allocation';
}

async function _customerPaymentFetch(payload) {
    var ses = await supabase.auth.getSession();
    var token = ses && ses.data && ses.data.session ? ses.data.session.access_token : null;
    if (!token) throw new Error('انتهت الجلسة');

    var res = await fetch(_customerPaymentEndpoint(), {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token
        },
        body: JSON.stringify(payload)
    });

    var json = await res.json().catch(function() { return null; });
    if (!res.ok || !json || json.success === false) {
        throw new Error((json && (json.msg || json.error)) || 'فشل تنفيذ عملية التحصيل');
    }
    return json;
}

async function _newCustomerReceipt() {
    var content = byId('finance-content');
    if (!content) return;

    var catalog = await _customerPaymentFetch({ action: 'catalog' }).catch(function(e) {
        _showToast(e.message || 'فشل تحميل بيانات التحصيل', 'error');
        return null;
    });
    if (!catalog) return;

    var customers = catalog.customers || [];
    var treasury = catalog.treasury || [];
    if (!customers.length) {
        _showToast('لا يوجد عملاء نشطون في الشركة الحالية', 'warning');
        return;
    }
    if (!treasury.length) {
        _showToast('لا توجد خزينة نشطة في الشركة الحالية', 'warning');
        return;
    }

    var customerOptions = customers.map(function(c) {
        return '<option value="' + _esc(c.id) + '">' + _esc(c.name || c.customer_code || c.id) + ' (' + _esc(c.customer_code || '') + ')</option>';
    }).join('');
    var treasuryOptions = treasury.map(function(t) {
        return '<option value="' + _esc(t.id) + '">' + _esc(t.account_name || t.account_code || t.id) + '</option>';
    }).join('');

    content.innerHTML =
        '<div class="space-y-5 text-right">' +
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="flex justify-between items-center mb-5">' +
                    '<div><h2 class="text-xl font-black"><i class="fa-solid fa-hand-holding-dollar ml-2 text-green-600"></i>تحصيل عميل وتخصيص الدفعة</h2><p class="text-sm text-gray-500 mt-1">اختر العميل ثم خصص الدفعة على أي عدد من الفواتير المفتوحة.</p></div>' +
                    '<button type="button" onclick="RW_Finance.renderSubTab(\'receipts\')" class="text-gray-500 hover:text-gray-800"><i class="fa-solid fa-xmark text-xl"></i></button>' +
                '</div>' +
                '<div class="grid grid-cols-1 md:grid-cols-4 gap-4">' +
                    '<div class="md:col-span-2"><label class="block text-sm font-bold mb-1">العميل *</label><select id="cp-customer" class="border-2 border-slate-200 rounded-xl p-3 w-full" onchange="RW_Finance._loadCustomerPaymentOrders(this.value)"><option value="">اختر العميل</option>' + customerOptions + '</select></div>' +
                    '<div><label class="block text-sm font-bold mb-1">الخزينة *</label><select id="cp-treasury" class="border-2 border-slate-200 rounded-xl p-3 w-full">' + treasuryOptions + '</select></div>' +
                    '<div><label class="block text-sm font-bold mb-1">تاريخ القبض *</label><input type="date" id="cp-date" class="border-2 border-slate-200 rounded-xl p-3 w-full" value="' + new Date().toISOString().slice(0,10) + '"></div>' +
                    '<div><label class="block text-sm font-bold mb-1">إجمالي الدفعة *</label><input type="number" id="cp-amount" min="0.01" step="0.01" class="border-2 border-slate-200 rounded-xl p-3 w-full font-black" oninput="RW_Finance._recalcCustomerPayment()" placeholder="0.00"></div>' +
                    '<div><label class="block text-sm font-bold mb-1">المرجع</label><input type="text" id="cp-reference" class="border-2 border-slate-200 rounded-xl p-3 w-full" placeholder="رقم شيك / تحويل / مرجع"></div>' +
                    '<div class="md:col-span-2"><label class="block text-sm font-bold mb-1">ملاحظات</label><input type="text" id="cp-notes" class="border-2 border-slate-200 rounded-xl p-3 w-full" placeholder="ملاحظات سند التحصيل"></div>' +
                '</div>' +
            '</div>' +
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="flex justify-between items-center mb-3"><h3 class="font-black text-lg">الفواتير المفتوحة للعميل</h3><span id="cp-order-count" class="text-xs bg-slate-100 px-3 py-1 rounded-full font-bold">0 فاتورة</span></div>' +
                '<div id="cp-orders"><div class="text-center py-10 text-gray-400">اختر العميل لعرض الفواتير المستحقة.</div></div>' +
            '</div>' +
            '<div class="bg-white rounded-2xl shadow-sm border p-5">' +
                '<div class="grid grid-cols-1 md:grid-cols-3 gap-3">' +
                    '<div class="bg-slate-50 rounded-xl p-4"><div class="text-xs text-gray-500">إجمالي الدفعة</div><div id="cp-total" class="text-2xl font-black">0.00</div></div>' +
                    '<div class="bg-green-50 rounded-xl p-4"><div class="text-xs text-gray-500">المخصص على الفواتير</div><div id="cp-allocated" class="text-2xl font-black text-green-700">0.00</div></div>' +
                    '<div class="bg-blue-50 rounded-xl p-4"><div class="text-xs text-gray-500">غير المخصص / رصيد دائن</div><div id="cp-unallocated" class="text-2xl font-black text-blue-700">0.00</div></div>' +
                '</div>' +
            '</div>' +
            '<div class="flex justify-end gap-3">' +
                '<button type="button" onclick="RW_Finance.renderSubTab(\'receipts\')" class="px-5 py-3 border rounded-xl font-bold">إلغاء</button>' +
                '<button type="button" id="cp-save" onclick="RW_Finance._saveCustomerPayment()" class="px-8 py-3 bg-green-600 text-white rounded-xl font-black disabled:opacity-50">حفظ وتسجيل الدفعة</button>' +
            '</div>' +
        '</div>';

    _recalcCustomerPayment();
}

async function _loadCustomerPaymentOrders(customerId) {
    var host = byId('cp-orders');
    if (!host) return;
    if (!customerId) {
        safeHTML(host, '<div class="text-center py-10 text-gray-400">اختر العميل لعرض الفواتير المستحقة.</div>');
        safeText(byId('cp-order-count'), '0 فاتورة');
        _recalcCustomerPayment();
        return;
    }

    safeHTML(host, '<div class="text-center py-10"><i class="fa-solid fa-spinner fa-spin"></i> جاري تحميل الفواتير المفتوحة...</div>');
    try {
        var json = await _customerPaymentFetch({ action: 'open_orders', customer_id: customerId });
        var orders = json.orders || [];
        safeText(byId('cp-order-count'), String(orders.length) + ' فاتورة');
        if (!orders.length) {
            safeHTML(host, '<div class="text-center py-10 text-green-700 font-bold">لا توجد فواتير مستحقة على هذا العميل.</div>');
            _recalcCustomerPayment();
            return;
        }

        var h = '<div class="overflow-x-auto"><table class="w-full text-sm border-collapse"><thead><tr class="bg-slate-50"><th class="p-3 border">الفاتورة</th><th class="p-3 border">التاريخ</th><th class="p-3 border">الإجمالي</th><th class="p-3 border">المدفوع</th><th class="p-3 border">المتبقي</th><th class="p-3 border">تخصيص الدفعة</th></tr></thead><tbody>';
        orders.forEach(function(o) {
            h += '<tr class="border-t hover:bg-slate-50">' +
                '<td class="p-3 font-black">' + _esc(o.order_code) + '</td>' +
                '<td class="p-3">' + _esc(o.order_date || '') + '</td>' +
                '<td class="p-3 text-center">' + _fmtNum(o.total_amount) + '</td>' +
                '<td class="p-3 text-center text-slate-600">' + _fmtNum(o.amount_paid) + '</td>' +
                '<td class="p-3 text-center font-black text-red-600">' + _fmtNum(o.outstanding) + '</td>' +
                '<td class="p-3"><input type="number" min="0" max="' + Number(o.outstanding || 0) + '" step="0.01" value="0" data-order-id="' + _esc(o.id) + '" data-order-code="' + _esc(o.order_code) + '" data-max="' + Number(o.outstanding || 0) + '" class="cp-allocation w-full border-2 border-slate-200 rounded-lg p-2 text-center font-bold" oninput="RW_Finance._recalcCustomerPayment()"></td>' +
                '</tr>';
        });
        h += '</tbody></table></div>';
        safeHTML(host, h);
        _recalcCustomerPayment();
    } catch (e) {
        safeHTML(host, '<div class="text-center py-10 text-red-500">' + _esc(e.message || 'فشل تحميل الفواتير') + '</div>');
    }
}

function _recalcCustomerPayment() {
    var amountEl = byId('cp-amount');
    var amount = Number(amountEl ? amountEl.value : 0);
    var allocated = 0;
    document.querySelectorAll('.cp-allocation').forEach(function(el) {
        var max = Number(el.dataset.max || 0);
        var value = Number(el.value || 0);
        if (!Number.isFinite(value) || value < 0) value = 0;
        if (value > max) { value = max; el.value = max; }
        allocated += value;
    });

    var unallocated = Math.max(0, amount - allocated);
    safeText(byId('cp-total'), _fmtNum(amount));
    safeText(byId('cp-allocated'), _fmtNum(allocated));
    safeText(byId('cp-unallocated'), _fmtNum(unallocated));

    var save = byId('cp-save');
    if (save) save.disabled = !(amount > 0 && byId('cp-customer') && byId('cp-customer').value && byId('cp-treasury') && byId('cp-treasury').value && allocated <= amount);
}

async function _saveCustomerPayment() {
    var host = byId('finance-content');
    if (!host || host.dataset.customerPaymentSaving === '1') return;

    var customerId = byId('cp-customer') ? byId('cp-customer').value : '';
    var treasuryId = byId('cp-treasury') ? byId('cp-treasury').value : '';
    var amount = Number(byId('cp-amount') ? byId('cp-amount').value : 0);
    var date = byId('cp-date') ? byId('cp-date').value : '';
    var reference = byId('cp-reference') ? byId('cp-reference').value.trim() : '';
    var notes = byId('cp-notes') ? byId('cp-notes').value.trim() : '';

    var allocations = [];
    document.querySelectorAll('.cp-allocation').forEach(function(el) {
        var q = Number(el.value || 0);
        if (q > 0) {
            allocations.push({ order_id: el.dataset.orderId, order_code: el.dataset.orderCode, allocated_amount: q });
        }
    });

    var allocated = allocations.reduce(function(sum, x) { return sum + Number(x.allocated_amount || 0); }, 0);
    if (!customerId) { _showToast('اختر العميل', 'warning'); return; }
    if (!treasuryId) { _showToast('اختر الخزينة', 'warning'); return; }
    if (!(amount > 0)) { _showToast('أدخل قيمة الدفعة', 'warning'); return; }
    if (allocated > amount) { _showToast('إجمالي التخصيص أكبر من قيمة الدفعة', 'error'); return; }

    var operationId = host.dataset.customerPaymentOperationId;
    if (!operationId) {
        operationId = (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : null;
        if (!operationId) { _showToast('تعذر إنشاء معرف العملية', 'error'); return; }
        host.dataset.customerPaymentOperationId = operationId;
    }

    host.dataset.customerPaymentSaving = '1';
    _showLoader('جاري تسجيل الدفعة وتخصيصها...');
    try {
        var result = await _customerPaymentFetch({
            action: 'create',
            operation_id: operationId,
            customer_id: customerId,
            treasury_id: treasuryId,
            amount: amount,
            receipt_date: date,
            reference: reference || null,
            notes: notes || null,
            allocations: allocations
        });

        delete host.dataset.customerPaymentOperationId;
        _showToast(result.duplicate ? 'العملية موجودة بالفعل ولم تُكرر.' : 'تم تسجيل الدفعة وتخصيصها بنجاح', 'success');
        renderSubTab('receipts');
    } catch (e) {
        _showToast(e.message || 'فشل تسجيل الدفعة', 'error');
    } finally {
        host.dataset.customerPaymentSaving = '0';
        _hideLoader();
    }
}

function _renderCustomerPaymentReceiptList(data) {
    var out = byId('sales-payment-receipts-list');
    if (!out) return;
    var receipts = data && data.receipts ? data.receipts : [];
    var orders = data && data.orders ? data.orders : [];
    var allocations = data && data.allocations ? data.allocations : [];

    if (!receipts.length) {
        safeHTML(out, '<div class="text-center py-8 text-gray-500">لا توجد دفعات عملاء مسجلة بعد.</div>');
        return;
    }

    var orderMap = {};
    orders.forEach(function(o) { orderMap[o.id] = o.order_code; });
    var countMap = {};
    allocations.forEach(function(a) { countMap[a.receipt_id] = (countMap[a.receipt_id] || 0) + 1; });

    var h = '<div class="overflow-x-auto"><table class="w-full text-sm border-collapse"><thead><tr class="bg-green-50"><th class="p-3 border">السند</th><th class="p-3 border">التاريخ</th><th class="p-3 border">المبلغ</th><th class="p-3 border">المخصص</th><th class="p-3 border">غير المخصص</th><th class="p-3 border">الفواتير</th><th class="p-3 border">عرض</th></tr></thead><tbody>';
    receipts.forEach(function(r) {
        h += '<tr class="border-t hover:bg-green-50/40">' +
            '<td class="p-3 font-black text-green-700">' + _esc(r.receipt_code) + '</td>' +
            '<td class="p-3">' + _esc(r.receipt_date || '') + '</td>' +
            '<td class="p-3 text-center font-black">' + _fmtNum(r.amount) + '</td>' +
            '<td class="p-3 text-center text-green-700 font-bold">' + _fmtNum(r.allocated_amount) + '</td>' +
            '<td class="p-3 text-center text-blue-700 font-bold">' + _fmtNum(r.unallocated_amount) + '</td>' +
            '<td class="p-3 text-center">' + Number(countMap[r.id] || 0) + '</td>' +
            '<td class="p-3 text-center"><button onclick="RW_Finance._showCustomerPaymentDetail(\'' + _esc(r.id) + '\')" class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td>' +
        '</tr>';
    });
    h += '</tbody></table></div>';
    safeHTML(out, h);
}

async function _showCustomerPaymentDetail(receiptId) {
    try {
        _showLoader('جاري تحميل تفاصيل الدفعة...');
        var data = await _customerPaymentFetch({ action: 'detail', receipt_id: receiptId });
        var receipt = data.receipt || {};
        var orders = data.orders || [];
        var allocations = data.allocations || [];
        var orderMap = {};
        orders.forEach(function(o) { orderMap[o.id] = o; });
        var h = '<div class="text-right">' +
            '<div class="grid grid-cols-3 gap-2 mb-4">' +
                '<div class="bg-slate-50 p-3 rounded-xl"><div class="text-xs text-gray-500">السند</div><div class="font-black">' + _esc(receipt.receipt_code) + '</div></div>' +
                '<div class="bg-green-50 p-3 rounded-xl"><div class="text-xs text-gray-500">المبلغ</div><div class="font-black text-green-700">' + _fmtNum(receipt.amount) + '</div></div>' +
                '<div class="bg-blue-50 p-3 rounded-xl"><div class="text-xs text-gray-500">غير المخصص</div><div class="font-black text-blue-700">' + _fmtNum(receipt.unallocated_amount) + '</div></div>' +
            '</div>' +
            '<table class="w-full text-sm border"><thead><tr class="bg-gray-50"><th class="p-2 border">الفاتورة</th><th class="p-2 border">الإجمالي</th><th class="p-2 border">المدفوع بعد التخصيص</th><th class="p-2 border">قيمة التخصيص</th></tr></thead><tbody>';
        allocations.forEach(function(a) {
            var o = orderMap[a.order_id] || {};
            h += '<tr><td class="p-2 border font-bold">' + _esc(o.order_code || a.order_id) + '</td><td class="p-2 border text-center">' + _fmtNum(o.total_amount) + '</td><td class="p-2 border text-center">' + _fmtNum(o.amount_paid) + '</td><td class="p-2 border text-center font-black text-green-700">' + _fmtNum(a.allocated_amount) + '</td></tr>';
        });
        h += '</tbody></table></div>';
        _hideLoader();
        Swal.fire({ title: 'تفاصيل دفعة العميل', html: h, width: '900px', showCloseButton: true, showConfirmButton: false });
    } catch (e) {
        _hideLoader();
        _showToast(e.message || 'فشل تحميل تفاصيل الدفعة', 'error');
    }
}

/* ============================================================
   PATCH C — Add public methods to RW_Finance return object
   CURRENT LINE: 12218 begins exactly with:
       return {
   Find the exact line:
       _newReceipt: _newReceipt, _addReceiptLine: _addReceiptLine, _removeReceiptLine: _removeReceiptLine, _recalcReceiptTotal: _recalcReceiptTotal, _saveReceipt: _saveReceipt,
   and REPLACE THAT ONE FULL LINE ONLY with the following full line:
   ============================================================ */
_newReceipt: _newReceipt, _addReceiptLine: _addReceiptLine, _removeReceiptLine: _removeReceiptLine, _recalcReceiptTotal: _recalcReceiptTotal, _saveReceipt: _saveReceipt, _newCustomerReceipt: _newCustomerReceipt, _loadCustomerPaymentOrders: _loadCustomerPaymentOrders, _recalcCustomerPayment: _recalcCustomerPayment, _saveCustomerPayment: _saveCustomerPayment, _showCustomerPaymentDetail: _showCustomerPaymentDetail,

/* PATCH C ends here. No other line in the return object changes. */
