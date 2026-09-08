# Report89 — Main7 Surgical Forensic Review — 2026-09-08

## 1. نطاق المراجعة
تمت إعادة بناء السياق من ملفات الحوكمة والـMASTER وReport87 وReport88 وCURRENT_STATE، ثم مطابقة `Current/PWA/main2/main7.md` مباشرة من Git مع Production Supabase الحالية.

المبدأ التنفيذي المستخدم:
`UNDERSTAND → HISTORICAL CONTRACT → CURRENT PRODUCTION → GAP → SURGICAL FIX → VERIFY`

لم يتم تعديل `Current/PWA/main2/main7.md` لأن ملكية هذا الجزء للمستخدم، والتعديل عليه يتم يدويًا وفق الإجراء المحدد.

## 2. Production checkpoint
الاستعلام المباشر الحالي أعطى:
- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_branches = 20
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- inventory_counts = 0
- inventory_count_details = 0
- stock_vouchers = 0
- inventory_log = 3

تمت إعادة التحقق بعد ظهور قراءة سابقة مختلفة؛ القراءة الأخيرة المباشرة هي المعتمدة.

## 3. Delivery contract proven in Production
`complete_order_delivery_atomic` يعمل على Order واحد مع `runsheet_code + order_code + items`، ويعدل `order_details` حسب `order_id`، ثم يعيد اشتقاق `run_sheet_details` من `order_details`.

`complete-order-delivery` Production v14 هو Wrapper للـOrder-level RPC.

`complete-delivery` Production v4 يغلق حالة Runsheet من `Delivering` إلى `Delivered` ولا يمثل طبقة Fulfillment للأوردرات.

بالتالي فإن Delivery في Main7 يجب أن يكون Order-by-Order، وليس Runsheet-wide batch payload.

## 4. Historical lifecycle decision
تم تثبيت العقد التالي وعدم تغييره:
`Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned`

M7-08 ليس إصلاحًا، ولا يتم تعديل مسميات الحالات بسبب اسم التبويب.

## 5. Main7 current identity
Current SHA:
`0962e20262e77e9e6d8905c83098c2d5fac9210c`

المصدر المعتمد:
`Current/PWA/main2/main7.md`

وليس:
`Current/PWA/main/main7.md`

ولا:
`Current/PWA/New-main`

## 6. Main7 surgical actions — OWNER ONLY

### M7-07B — Reference input
الموضع: `loadVoucherForm(type)`، السطور الحالية تقريبًا 145–154.

ابحث عن الـ`<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">` الكامل الذي ينتهي مباشرة قبل:
`<div class="mb-4">`
ثم استبدله بــ:

```html
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
```

لا تعدل كتلة `بحث عن صنف` التالية.

### M7-09 — Delivery Order-by-Order
الموضع: الدالة `_openDeliveryModal(rsCode)`، تبدأ حاليًا عند السطر 1193، وتنتهي قبل السطر الذي يبدأ:
`function _openReturnModal(rsCode) {`

احذف الدالة كاملة، وآخر سطر للحذف هو بالضبط:
```text
}
```
الذي يأتي مباشرة قبل:
```text
function _openReturnModal(rsCode) {
```

استبدل الدالة كاملة بهذه النسخة:

```javascript
function _openDeliveryModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    showLoader('جاري تحميل بيانات التوصيل...');

    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }

    supabase.from('runsheets')
        .select('id,status')
        .eq('company_id', companyId)
        .eq('runsheet_code', rsCode)
        .maybeSingle()
        .then(function(rsRes) {
            if (rsRes.error) throw rsRes.error;
            var rs = rsRes.data;
            if (!rs) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return null; }

            showLoader('جاري بدء التوصيل...');
            return supabase.auth.getSession().then(function(ses) {
                var t = ses.data.session ? ses.data.session.access_token : null;
                if (!t) throw new Error('انتهت الجلسة');
                return fetch(RW_SUPABASE_URL + '/functions/v1/start-delivery', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
                    body: JSON.stringify({ runsheet_code: rsCode })
                });
            }).then(function(res) {
                return res.json();
            }).then(function(startJson) {
                if (!startJson.success) { hideLoader(); showToast(startJson.msg || 'فشل بدء التوصيل', 'error'); return null; }

                return supabase.from('orders')
                    .select('id,order_code,customer_name')
                    .eq('company_id', companyId)
                    .eq('runsheet_id', rs.id)
                    .order('created_at', { ascending: true })
                    .then(function(ordersRes) {
                        if (ordersRes.error) throw ordersRes.error;
                        var orders = ordersRes.data || [];
                        if (!orders.length) { hideLoader(); showToast('لا توجد أوردرات في الرانشيت', 'info'); return null; }

                        function deliverOrder(index) {
                            if (index >= orders.length) {
                                showLoader('جاري إنهاء الرانشيت...');
                                return supabase.auth.getSession().then(function(ses2) {
                                    var t2 = ses2.data.session ? ses2.data.session.access_token : null;
                                    if (!t2) throw new Error('انتهت الجلسة');
                                    return fetch(RW_SUPABASE_URL + '/functions/v1/complete-delivery', {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t2 },
                                        body: JSON.stringify({ runsheet_code: rsCode })
                                    });
                                }).then(function(res) {
                                    return res.json();
                                }).then(function(finalJson) {
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
                            showLoader('جاري تحميل بيانات الأوردر ' + (order.order_code || '') + '...');
                            return supabase.from('order_details')
                                .select('id,item_code,item_name,unit,qty,qty_loaded,qty_delivered,qty_refused,unit_price')
                                .eq('order_id', order.id)
                                .order('created_at', { ascending: true })
                                .then(function(detailsRes) {
                                    if (detailsRes.error) throw detailsRes.error;
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
                                            if (!t3) throw new Error('انتهت الجلسة');
                                            return fetch(RW_SUPABASE_URL + '/functions/v1/complete-order-delivery', {
                                                method: 'POST',
                                                headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t3 },
                                                body: JSON.stringify({ runsheet_code: rsCode, order_code: order.order_code, items: result.value })
                                            });
                                        }).then(function(res) {
                                            return res.json();
                                        }).then(function(orderJson) {
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
            });
        })
        .catch(function(e) {
            hideLoader();
            showToast(e.message || 'فشل تحميل بيانات التوصيل', 'error');
        });
}
```

### M7-10A — Settlement Runsheet company scope
الموضع: `loadSettlement()`, السطر الحالي تقريبًا 924.

ابحث عن هذا السطر الكامل:
```javascript
var runsheetsRes = await supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Delivered', 'Returned']);
```

استبدله بالكامل بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Delivered', 'Returned']);
```

### M7-10B — Voucher detail linkage
الموضع: `_onSettlementRsChange()`، الأسطر الحالية تقريبًا 950–955.

احذف هذا المقطع كاملًا:
```javascript
var vouchersRes = await supabase.from('stock_vouchers').select('voucher_code').eq('reference', rsCode).eq('type', 'Return');
var voucherIds = (vouchersRes.data || []).map(function(v) { return v.voucher_code; });
var returnDetails = [];
if (voucherIds.length > 0) {
    var retRes = await supabase.from('stock_voucher_details').select('*').in('voucher_code', voucherIds);
    returnDetails = retRes.data || [];
}
```

واستبدله بـ:
```javascript
var vouchersRes = await supabase.from('stock_vouchers')
    .select('id, voucher_code')
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
```

Production schema يثبت أن Parent key هو `voucher_id`.

### M7-10C — Settlement Order Details lookup
الموضع: `_onSettlementRsChange()`، السطر الحالي الذي يحتوي:
```javascript
var orderDetailsRes = await supabase.from('order_details').select('*').eq('runsheet_id', rs.id);
```

احذف السطر كاملًا واستبدله بـ:
```javascript
var ordersForRsRes = await supabase.from('orders')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_id', rs.id);
if (ordersForRsRes.error) throw ordersForRsRes.error;
var orderIdsForRs = (ordersForRsRes.data || []).map(function(o) { return o.id; });
var orderDetails = [];
if (orderIdsForRs.length > 0) {
    var orderDetailsRes = await supabase.from('order_details')
        .select('*')
        .in('order_id', orderIdsForRs);
    if (orderDetailsRes.error) throw orderDetailsRes.error;
    orderDetails = orderDetailsRes.data || [];
}
```

السبب: `order_details` في Production لا يحتوي `runsheet_id`; العلاقة تمر عبر `orders.runsheet_id → orders.id → order_details.order_id`.

### M7-10D — Latest Vehicle Inventory Count داخل `_onSettlementRsChange()`
قبل بناء `itemsMap` مباشرة، وبعد `loadedItems` و`orderDetails` و`returnDetails`، أضف:
```javascript
var vehicleRes = await supabase.from('vehicles')
    .select('id, mobile_branch_id')
    .eq('company_id', companyId)
    .eq('id', rs.vehicle_id)
    .maybeSingle();
if (vehicleRes.error) throw vehicleRes.error;
var vehicle = vehicleRes.data || null;
var inventoryEntityId = vehicle ? (vehicle.mobile_branch_id || vehicle.id) : null;
var countedByItem = {};
if (inventoryEntityId) {
    var countRes = await supabase.from('inventory_counts')
        .select('id')
        .eq('company_id', companyId)
        .eq('type', 'vehicle')
        .eq('entity_id', inventoryEntityId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
    if (countRes.error) throw countRes.error;
    if (countRes.data) {
        var countDetailsRes = await supabase.from('inventory_count_details')
            .select('item_code, counted_qty')
            .eq('count_id', countRes.data.id);
        if (countDetailsRes.error) throw countDetailsRes.error;
        var countDetails = countDetailsRes.data || [];
        for (var c = 0; c < countDetails.length; c++) {
            countedByItem[countDetails[c].item_code] = Number(countDetails[c].counted_qty) || 0;
        }
    }
}
```

ثم احذف السطر الحالي في السطر 962:
```javascript
itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: 0, unitPrice: Number(it.unit_price) || 0 };
```

واستبدله بـ:
```javascript
itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: Number(countedByItem[it.item_code]) || 0, unitPrice: Number(it.unit_price) || 0 };
```

### M7-11 — Branch Inventory Count entity
الموضع: `loadBranchCount()` داخل option builder، النص الحالي:
```javascript
'<option value="' + (b.branch_code || b.id || '') + '">' +
```

ابحث عنه واستبدل فقط قيمة الـ`value` بـ:
```javascript
'<option value="' + (b.id || b.branch_code || '') + '">' +
```

الهدف: `save-inventory-count` يستقبل `branches.id` في type=`branch`.

### M7-12 — Vehicle Count entity identity
الدالة تبدأ حاليًا عند السطر 835 تقريبًا، والنص الفعلي الذي يجب حذفه هو الدالة كاملة:
```javascript
async function _saveVehicleCount() {
        var entityId = window._selectedDriver || '';
        if (!entityId) { showToast('يجب اختيار مندوب', 'warning'); return; }
        var reference = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';
        var notes = (byId('vc-notes') ? byId('vc-notes').value : '') || '';
        if (notes) reference = reference ? reference + ' | ' + notes : notes;
        await _saveInvCount('vehicle', entityId, reference || 'جرد سيارة');
    }
```

وآخر سطر للحذف هو:
```text
    }
```
الملاصق مباشرة قبل:
```javascript
async function _saveInvCount(type, entityId, reference) {
```

استبدلها كاملة بـ:
```javascript
async function _saveVehicleCount() {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    var selectedDriver = window._selectedDriver || '';
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    if (!selectedDriver) { showToast('يجب اختيار مندوب', 'warning'); return; }

    var reference = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';
    var notes = (byId('vc-notes') ? byId('vc-notes').value : '') || '';
    if (notes) reference = reference ? reference + ' | ' + notes : notes;

    var vehicleId = null;
    var selectedRunsheet = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';

    if (selectedRunsheet) {
        var rsRes = await supabase.from('runsheets')
            .select('vehicle_id')
            .eq('company_id', companyId)
            .eq('runsheet_code', selectedRunsheet)
            .maybeSingle();
        if (rsRes.error) { showToast(rsRes.error.message, 'error'); return; }
        vehicleId = rsRes.data ? rsRes.data.vehicle_id : null;
    }

    if (!vehicleId) {
        var userRes = await supabase.from('users')
            .select('id')
            .eq('company_id', companyId)
            .eq('email', selectedDriver)
            .maybeSingle();
        if (userRes.error) { showToast(userRes.error.message, 'error'); return; }
        var driverId = userRes.data ? userRes.data.id : null;
        if (driverId) {
            var vehicleRes = await supabase.from('vehicles')
                .select('id')
                .eq('company_id', companyId)
                .eq('driver_id', driverId)
                .limit(1)
                .maybeSingle();
            if (vehicleRes.error) { showToast(vehicleRes.error.message, 'error'); return; }
            vehicleId = vehicleRes.data ? vehicleRes.data.id : null;
        }
    }

    if (!vehicleId) { showToast('لا توجد مركبة مرتبطة بهذا المندوب', 'warning'); return; }
    await _saveInvCount('vehicle', vehicleId, reference || 'جرد سيارة');
}
```

### M7-13 — General Inventory Count entity
الموضع: `_saveGeneralCount()`، السطر الحالي داخل الدالة:
```javascript
await _saveInvCount('general', 'MAIN', 'جرد عام' + (notes ? ' | ' + notes : ''));
```

احذف الدالة كاملة التي تبدأ:
```javascript
async function _saveGeneralCount() {
```

وتنتهي مباشرة بعد هذا السطر:
```javascript
}
```

واستبدلها بـ:
```javascript
async function _saveGeneralCount() {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    var notes = (byId('gc-notes') ? byId('gc-notes').value : '') || '';
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }

    var settingsRes = await supabase.from('app_settings')
        .select('main_branch_id')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();
    if (settingsRes.error) { showToast(settingsRes.error.message, 'error'); return; }
    var mainBranchId = settingsRes.data ? settingsRes.data.main_branch_id : null;
    if (!mainBranchId) { showToast('الفرع الرئيسي غير محدد', 'error'); return; }

    await _saveInvCount('general', mainBranchId, 'جرد عام' + (notes ? ' | ' + notes : ''));
}
```

## 7. ما لم يتم تعديله عمدًا
- `M7-08` lifecycle statuses.
- `complete_order_delivery_atomic`.
- `complete_return_atomic`.
- Physical Stock core.
- `_showUnloadingDetails()`.
- driver.html business workflow نفسه.

السبب: هذه العناصر إما مثبتة تاريخيًا كعقد، أو صحيحة في Production، أو تحتاج contract مستقل قبل ابتكار سلوك جديد.

## 8. Driver.html / Delivery historical conclusion
تمت مراجعة `Current/PWA/driver.html` باعتباره تطبيقًا منفصلًا لرحلة المندوب، ولا يوجد ما يبرر تغيير فكرة الرحلة الحالية لمجرد جعل Main7 أبسط.

القرار: Main7 يجب أن ينسق مع عقد Delivery الحالي؛ لا يعيد تصميم Driver workflow.

## 9. Assembly path
`.github/workflows/forensic_main_assembly.yml` يستخدم بالفعل:
`Current/PWA/main2/**`
كمصدر canonical و:
`Current/PWA/New-main`
كـgenerated target. لا يوجد تغيير مطلوب هنا.

## 10. Tests
تم تنفيذ تحقق Production مباشر للآتي:
- Production object counts.
- Delivery RPC signature/definition.
- Delivery Edge wrapper.
- start-delivery / complete-delivery deployment presence.
- Inventory Count deployment contract.
- `stock_voucher_details` parent linkage.
- `items.item_code` uniqueness.
- `order_details` schema وعدم وجود `runsheet_id`.

لم يتم إنشاء Order/Runsheet دائم في Production لغرض اصطناع PASS.

## 11. Failed/invalid evidence rejected
قراءة سابقة أظهرت ثلاث Companies، ثم أعيد الاستعلام مباشرة وانتهى إلى Company واحدة؛ القراءة الثانية فقط معتمدة.

كما أن أي تقرير سابق يحول M7-08 إلى إصلاح تم رفضه بعد إعادة بناء lifecycle من Production.

## 12. Final status
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`DELIVERY CONTRACT = PROVEN`
`INVENTORY COUNT CONTRACT = PROVEN`
`MAIN2 CANONICAL SOURCE PATH = PROVEN`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`
`PARENT GOLD/DIAMOND = NOT CLOSED`

## 13. Next evidence gate
بعد تطبيق المالك للتعديلات المحددة أعلاه:
1. قراءة `main7.md` كاملًا من SOF إلى EOF.
2. التحقق من عدد أقواس الدوال والـtemplate literals والـHTML tags.
3. فحص عدم وجود `ordersData` داخل Delivery.
4. فحص وجود `.select('id,order_code,customer_name')` في Orders.
5. فحص وجود `.eq('order_id', order.id)` في Delivery details.
6. فحص غياب `.eq('runsheet_id', rs.id)` على `order_details`.
7. فحص وجود latest vehicle count lookup.
8. إعادة حساب SHA وإغلاق Main7 قبل الانتقال إلى assembly.
