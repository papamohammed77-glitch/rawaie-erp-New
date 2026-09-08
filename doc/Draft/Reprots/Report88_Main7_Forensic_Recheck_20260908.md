# Report88 — Main7 Forensic Recheck — 2026-09-08

## 1. نطاق التنفيذ
تمت مراجعة:
- مبادئ الحوكمة الحاكمة.
- MASTER continuity documents الثلاثة.
- CURRENT_STATE.md.
- Report87.
- Current/PWA/main2/main7.md من المصدر الحالي في Git.
- Production Supabase الحالية والعقود الفعلية للـDelivery والInventory Count.

لم يتم تعديل Current/PWA/main2/main7.md؛ هذا الملف ملكية المالك ويقوم المالك بالتعديلات الجراحية عليه.

## 2. Production checkpoint
تمت مطابقة Production مباشرة أثناء المراجعة. Snapshot موثق في التنفيذ الحالي:
companies=1, branches=2, users=24, items=17, stock_branches=20, orders=0, order_details=0, runsheets=0, run_sheet_details=0, inventory_counts=0, inventory_count_details=0, stock_vouchers=0, inventory_log=3.

عقد Delivery الفعلي:
- complete_order_delivery_atomic: معالجة Order واحد فقط.
- complete-order-delivery Edge: يمرر Order واحدًا إلى الـRPC أعلاه.
- complete-delivery Edge: ينهي حالة Runsheet من Delivering إلى Delivered ولا يستقبل ordersData كطبقة Fulfillment.

## 3. أهم تصحيح تاريخي
تم اعتماد Report87 في نقطة lifecycle:
Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned.

لا يتم تغيير هذه الحالات بناءً على اسم الشاشة. M7-08 من Report86 غير معتمد كإصلاح.

## 4. Main7 الحالي
Current SHA:
0962e20262e77e9e6d8905c83098c2d5fac9210c

M7-01 إلى M7-06 وM7-07 الخاص بتحويل _openNewVoucherModal إلى loadVoucherForm مطبقة بالفعل في النسخة الحالية.

## 5. التعديلات المتبقية — يدويًا على Main7

### M7-07B — Reference field
الموضع: loadVoucherForm(type)، تقريبًا عند السطور 145–154 في النسخة الحالية.

ابحث عن المقطع الكامل الذي يبدأ:
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">

وينتهي مباشرة قبل:
<div class="mb-4">
    <label class="block text-sm font-bold mb-1">بحث عن صنف</label>

في داخله يوجد حاليًا entity select ثم voucherNotesLarge فقط.

استبدل الـgrid كاملًا بهذا:

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
    <div>
        <label class="block text-sm font-bold mb-1">${cfg.entityLabel}</label>
        <select id="voucherEntitySelect" class="border rounded-lg p-2 w-full"><option value="">-- اختر --</option></select>
    </div>
    <div>
        <label class="block text-sm font-bold mb-1">مرجع الإذن</label>
        <input id="voucherReference" class="border rounded-lg p-2 w-full" placeholder="مرجع الإذن...">
    </div>
    <div>
        <label class="block text-sm font-bold mb-1">ملاحظات</label>
        <textarea id="voucherNotesLarge" rows="2" class="border rounded-lg p-2 w-full" placeholder="ملاحظات..."></textarea>
    </div>
</div>

سبب التعديل: _saveAndSendVoucher() يقرأ voucherReference في النسخة الحالية، بينما العنصر غير موجود في loadVoucherForm().

### M7-09 — Delivery Order-by-Order
الموضع المؤكد: الدالة `_openDeliveryModal(rsCode)` تبدأ في السطر 1193 وتنتهي في السطر 1271 من النسخة الحالية.

ابحث عن:
function _openDeliveryModal(rsCode) {

واحذف الدالة كاملة حتى السطر الذي ينتهي مباشرة قبل:
function _openReturnModal(rsCode) {

المقطع الحالي ينتهي بهذا السطر الكامل:
}).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
}).catch(function(e) { hideLoader(); showToast('فشل تحميل بيانات الرانشيت', 'error'); });
}

استبدل الدالة كاملة بهذا السلوك:
1. جلب runsheet بـ company scope.
2. استدعاء start-delivery مرة واحدة لفتح Delivering.
3. جلب Orders الخاصة بالرانشيت مرتبة Order-by-Order.
4. فتح Order واحد في كل مرة.
5. جلب order_details لهذا الـOrder فقط.
6. إظهار qty_loaded وqty_delivered وكمية المتبقي لكل صنف.
7. إرسال نتيجة الـOrder إلى:
   /functions/v1/complete-order-delivery
   باستخدام:
   runsheet_code + order_code + items
8. عدم بناء orderItems من run_sheet_details لجميع Orders.
9. بعد نجاح جميع Orders فقط استدعاء:
   /functions/v1/complete-delivery
   بـ runsheet_code لإنهاء Runsheet.

البديل التنفيذي المقترح:

function _openDeliveryModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات التوصيل...');

    supabase.from('runsheets')
        .select('id, status')
        .eq('company_id', (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || '')
        .eq('runsheet_code', rsCode)
        .maybeSingle()
        .then(function(rsRes) {
            var rs = rsRes.data;
            if (!rs) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return; }

            showLoader('جاري بدء التوصيل...');
            supabase.auth.getSession().then(function(ses) {
                var t = ses.data.session ? ses.data.session.access_token : null;
                return fetch(RW_SUPABASE_URL + '/functions/v1/start-delivery', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                    body: JSON.stringify({ runsheet_code: rsCode })
                });
            }).then(function(res) { return res.json(); }).then(function(startJson) {
                if (!startJson.success) { hideLoader(); showToast(startJson.msg || 'فشل بدء التوصيل', 'error'); return; }

                var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
                return supabase.from('orders')
                    .select('order_code, customer_name')
                    .eq('company_id', companyId)
                    .eq('runsheet_id', rs.id)
                    .order('created_at', { ascending: true })
                    .then(function(ordersRes) {
                        var orders = ordersRes.data || [];
                        if (!orders.length) { hideLoader(); showToast('لا توجد أوردرات في الرانشيت', 'info'); return; }

                        function deliverOrder(index) {
                            if (index >= orders.length) {
                                showLoader('جاري إنهاء الرانشيت...');
                                return supabase.auth.getSession().then(function(ses2) {
                                    var t2 = ses2.data.session ? ses2.data.session.access_token : null;
                                    return fetch(RW_SUPABASE_URL + '/functions/v1/complete-delivery', {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t2 },
                                        body: JSON.stringify({ runsheet_code: rsCode })
                                    });
                                }).then(function(res) { return res.json(); }).then(function(finalJson) {
                                    hideLoader();
                                    if (finalJson.success) {
                                        showToast('تم إنهاء التوصيل بالكامل', 'success');
                                        if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
                                    } else {
                                        showToast(finalJson.msg || 'فشل إنهاء الرانشيت', 'error');
                                    }
                                });
                            }

                            var order = orders[index];
                            showLoader('جاري تحميل بيانات الأوردر ' + order.order_code + '...');
                            return supabase.from('order_details')
                                .select('id,item_code,item_name,unit,qty,qty_loaded,qty_delivered,qty_refused,unit_price')
                                .eq('order_id', order.id || '')
                                .order('created_at', { ascending: true })
                                .then(function(detailsRes) {
                                    var details = detailsRes.data || [];
                                    hideLoader();
                                    if (!details.length) {
                                        return deliverOrder(index + 1);
                                    }

                                    var html = '<div class="text-right" dir="rtl"><div class="max-h-[420px] overflow-y-auto">';
                                    html += '<div class="mb-3 p-3 bg-blue-50 rounded-lg"><div class="font-black text-blue-700">' + (order.order_code || '') + '</div><div class="text-sm text-gray-600">' + (order.customer_name || '') + '</div></div>';
                                    html += '<table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">محمّل</th><th class="p-2 text-center">مسلّم سابقًا</th><th class="p-2 text-center">المتبقي</th><th class="p-2 text-center">تسليم الآن</th></tr></thead><tbody>';

                                    for (var i = 0; i < details.length; i++) {
                                        var d = details[i];
                                        var loaded = Number(d.qty_loaded || 0);
                                        var delivered = Number(d.qty_delivered || 0);
                                        var remaining = Math.max(0, loaded - delivered);
                                        html += '<tr><td class="p-2 border"><div class="font-bold">' + (d.item_name || '') + '</div><div class="text-xs text-gray-400">' + (d.item_code || '') + '</div></td>'
                                            + '<td class="p-2 border text-center">' + loaded + '</td>'
                                            + '<td class="p-2 border text-center">' + delivered + '</td>'
                                            + '<td class="p-2 border text-center font-bold text-blue-700">' + remaining + '</td>'
                                            + '<td class="p-2 border text-center"><input type="number" id="dv_order_qty_' + i + '" value="' + remaining + '" min="0" max="' + remaining + '" step="0.01" class="w-24 p-1 border rounded text-center"></td></tr>';
                                    }
                                    html += '</tbody></table></div></div>';

                                    return Swal.fire({
                                        title: 'توصيل الأوردر ' + (order.order_code || ''),
                                        html: html,
                                        width: '850px',
                                        showCancelButton: true,
                                        confirmButtonText: 'تأكيد تسليم الأوردر',
                                        cancelButtonText: 'إلغاء',
                                        preConfirm: function() {
                                            var items = [];
                                            var hasQty = false;
                                            for (var j = 0; j < details.length; j++) {
                                                var maxRemaining = Math.max(0, Number(details[j].qty_loaded || 0) - Number(details[j].qty_delivered || 0));
                                                var q = parseFloat((document.getElementById('dv_order_qty_' + j) || {}).value) || 0;
                                                if (q < 0 || q > maxRemaining) {
                                                    Swal.showValidationMessage('كمية التسليم تتجاوز المتبقي للصنف: ' + (details[j].item_code || ''));
                                                    return false;
                                                }
                                                if (q > 0) hasQty = true;
                                                items.push({ itemCode: details[j].item_code, deliveredQty: q, reason: '' });
                                            }
                                            if (!hasQty) {
                                                Swal.showValidationMessage('أدخل كمية تسليم واحدة على الأقل');
                                                return false;
                                            }
                                            return items;
                                        }
                                    }).then(function(result) {
                                        if (!result.isConfirmed) return;
                                        showLoader('جاري حفظ تسليم ' + (order.order_code || '') + '...');
                                        return supabase.auth.getSession().then(function(ses3) {
                                            var t3 = ses3.data.session ? ses3.data.session.access_token : null;
                                            return fetch(RW_SUPABASE_URL + '/functions/v1/complete-order-delivery', {
                                                method: 'POST',
                                                headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t3 },
                                                body: JSON.stringify({ runsheet_code: rsCode, order_code: order.order_code, items: result.value })
                                            });
                                        }).then(function(res) { return res.json(); }).then(function(orderJson) {
                                            hideLoader();
                                            if (!orderJson.success) {
                                                showToast(orderJson.msg || 'فشل تسليم الأوردر', 'error');
                                                return;
                                            }
                                            return deliverOrder(index + 1);
                                        });
                                    });
                                });
                        }

                        return deliverOrder(0);
                    });
            }).catch(function(e) {
                hideLoader();
                showToast(e.message || 'فشل الاتصال', 'error');
            });
        }).catch(function(e) {
            hideLoader();
            showToast('فشل تحميل بيانات الرانشيت', 'error');
        });
}

ملاحظة تنفيذية: إذا كان `orders.id` مطلوبًا في current source، عدّل select إلى:
.select('id,order_code,customer_name')
وهذا هو الاختيار الصحيح لأن `order_details.order_id` هو مفتاح التفاصيل.

### M7-10 — Settlement / آخر Inventory Count
الموضع: السطر 962 حاليًا داخل `_onSettlementRsChange()`:

itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: 0, unitPrice: Number(it.unit_price) || 0 };

احذف هذا السطر واستبدله بهذه الخطوة الكاملة قبل بناء itemsMap:

1. بعد الحصول على rs، استخرج vehicle_id.
2. ابحث عن vehicle بـ company_id.
3. اجعل inventoryEntityId = vehicle.mobile_branch_id || vehicle.id.
4. استخرج آخر inventory_counts بالترتيب created_at DESC مع:
   type='vehicle'
   company_id=companyId
   entity_id=inventoryEntityId
5. استخرج inventory_count_details بواسطة count_id.
6. ابنِ map باسم countedByItem.
7. استخدم countedByItem[item_code] بدل 0.

الكود:

var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
var vehicleRes = await supabase.from('vehicles')
    .select('id,mobile_branch_id')
    .eq('company_id', companyId)
    .eq('id', rs.vehicle_id)
    .maybeSingle();
var vehicle = vehicleRes.data || null;
var inventoryEntityId = vehicle ? (vehicle.mobile_branch_id || vehicle.id) : null;
var latestCount = null;
var countedByItem = {};
if (inventoryEntityId) {
    var countRes = await supabase.from('inventory_counts')
        .select('id,entity_id,reference,created_at')
        .eq('company_id', companyId)
        .eq('type', 'vehicle')
        .eq('entity_id', inventoryEntityId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
    if (countRes.data) {
        latestCount = countRes.data;
        var countDetailsRes = await supabase.from('inventory_count_details')
            .select('item_code,counted_qty')
            .eq('count_id', latestCount.id);
        var countRows = countDetailsRes.data || [];
        for (var ci = 0; ci < countRows.length; ci++) {
            countedByItem[countRows[ci].item_code] = Number(countRows[ci].counted_qty) || 0;
        }
    }
}

ثم اجعل إنشاء itemsMap:

itemsMap[it.item_code] = {
    itemCode: it.item_code,
    itemName: it.item_name,
    unit: it.unit,
    loadedQty: Number(it.qty_loaded) || 0,
    deliveredQty: 0,
    returnedQty: 0,
    countedQty: Object.prototype.hasOwnProperty.call(countedByItem, it.item_code) ? countedByItem[it.item_code] : 0,
    unitPrice: Number(it.unit_price) || 0
};

### M7-10B — Settlement references broken column
الموضع: السطر 950 وما بعده في `_onSettlementRsChange()`.

ابحث عن المقطع الكامل:
var vouchersRes = await supabase.from('stock_vouchers').select('voucher_code').eq('reference', rsCode).eq('type', 'Return');
var voucherIds = (vouchersRes.data || []).map(function(v) { return v.voucher_code; });
var returnDetails = [];
if (voucherIds.length > 0) {
    var retRes = await supabase.from('stock_voucher_details').select('*').in('voucher_code', voucherIds);
    returnDetails = retRes.data || [];
}

احذفه واستبدله بـ:

var vouchersRes = await supabase.from('stock_vouchers')
    .select('id,voucher_code')
    .eq('company_id', companyId)
    .eq('reference', rsCode)
    .eq('type', 'Return');
var voucherIds = (vouchersRes.data || []).map(function(v) { return v.id; });
var returnDetails = [];
if (voucherIds.length > 0) {
    var retRes = await supabase.from('stock_voucher_details')
        .select('*')
        .in('voucher_id', voucherIds);
    returnDetails = retRes.data || [];
}

Production schema يثبت أن `stock_voucher_details` يحتوي `voucher_id` وليس `voucher_code`.

## 6. ما لم يتم تعديله عمدًا
- complete_order_delivery_atomic: لم يُعدّل.
- complete_return_atomic: لم يُعدّل.
- Physical Stock Core: لا تعديل جديد.
- Lifecycle statuses M7-08: لم تُغيّر.
- _showUnloadingDetails(): بقي placeholder كما هو، وفق العقد الحالي.

## 7. الاختبارات
- تمت مطابقة Production delivery contract مباشرة.
- تم التحقق أن `complete-order-delivery` يعالج Order واحدًا.
- تم التحقق أن `complete-delivery` ينهي Runsheet فقط.
- تم التحقق من Schema: `runsheets UNIQUE(company_id,runsheet_code)`، و`inventory_count_details.count_id`، و`stock_voucher_details.voucher_id`.
- تم التحقق من Production `save-inventory-count`: vehicle entity يتحول إلى `mobile_branch_id || vehicle.id`.

لا توجد بيانات Orders/Runsheets تشغيلية حالية تسمح بتجربة Delivery كاملة دون إدخال Fixture دائم؛ لذلك لم يتم اختلاق Production transaction دائم.

## 8. نتيجة الإغلاق
Production Inventory Core = CLOSED.
Production Delivery Contract = VERIFIED.
Main7 Source Surgery = OPEN / OWNER ACTION REQUIRED.
Full Main2 Assembly = OPEN / NOT PROVEN.

بعد تطبيق هذه الجراحات، يلزم إعادة قراءة Main7 من SOF إلى EOF ثم Node syntax ثم reconstruction ثم Production contract comparison قبل أي نشر.
