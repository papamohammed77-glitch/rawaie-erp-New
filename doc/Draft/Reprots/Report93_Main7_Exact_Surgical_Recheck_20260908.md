# Report93 — Main7 Exact Surgical Recheck — 2026-09-08

## 1. نتيجة الاسترجاع والتحقق
تمت إعادة قراءة مصادر الحوكمة المطلوبة قبل أي قرار:
- `MASTER - RAWAEA ERP.md`
- `MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `تقرير مبادئ حاكمة`
- `برومبت استكمال مهام`
- `CURRENT_STATE.md`
- Report89 / Report90 / Report91 / Report92
- `.github/workflows/forensic_main_assembly.yml`
- `Current/PWA/main2/main7.md`
- `Current/PWA/driver.html`
- Production Supabase الحالي.

الحوكمة المستخدمة تؤكد أن الدراسة التاريخية والسلوك الفعلي في Production يسبقان أي تعديل، وأن UNKNOWN ليس BUG تلقائيًا، وأن كل Closure Unit تعالج منفردة، وأن Physical Stock لا يتغير إلا عبر `post_stock_movement`.  fileciteturn1321file0 fileciteturn1323file0 fileciteturn1324file0

## 2. اكتشاف مهم: Report92 لم يعد يصف SHA الحالي
Report92 كان مبنيًا على Main7 SHA `0962e20262e77e9e6d8905c83098c2d5fac9210c`. عند بدء هذه الجلسة تم فحص المصدر الحالي مباشرة، وSHA الحالي أصبح:
`b6d19e0b9c775d02594e4cba868e63455b009824`.
لذلك تم اعتبار Report92 سجلًا تاريخيًا وليس Truth حاليًا. fileciteturn1306file0 fileciteturn1326file0

## 3. ما تم إثباته في Production الآن
آخر Snapshot مباشر في هذه الجلسة:
`2026-09-08 11:31:28.54266+00 UTC`

القيم الحالية:
- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_rows = 20
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- stock_vouchers = 0
- inventory_log = 3
- inventory_counts = 0
- inventory_count_details = 0

تم التحقق من وجود:
- `complete_order_delivery_atomic(...)`
- `complete_return_atomic(...)`
- `post_inventory_adjustment_atomic(...)`
- `post_stock_movement(...)` بتوقيع 10 معاملات idempotent، بالإضافة إلى overload أقدم 9 معاملات
- `receive_purchase_atomic(...)` بتوقيع حالي يضم `p_operation_id uuid`

وتم إثبات أن `items.item_code` لديه قيد `UNIQUE` عالمي، وأن `stock_voucher_details` يرتبط بالـvoucher بواسطة `voucher_id`. كما أن `vehicles.id` و`mobile_branch_id` معرفات UUID. 

## 4. Delivery / Driver contract — Protected and Proven
لم يتم تعديل `driver.html` ولم يتم تعديل فكرة التوصيل.

Production الحالي:
- `start-delivery` يحدد الشركة من المستخدم المصادق عليه، ويتحقق من `runsheet_code + company_id` ومن أن الحالة `Loaded` وأن الرانشيت تابع للسائق.
- `complete-order-delivery` يحدد الشركة من المستخدم المصادق عليه، ثم ينفذ `complete_order_delivery_atomic(...)` بمستوى Order.
- `complete-delivery` يحدد الشركة من المستخدم المصادق عليه وينهي الرانشيت فقط.
- `complete-return` يحدد الشركة من المستخدم المصادق عليه وينفذ `complete_return_atomic(...)`.

`driver.html` نفسه يرسل `runsheet_code + order_code` إلى `/functions/v1/complete-order-delivery`، وهو ما يثبت أن Delivery Order-by-Order جزء من العقد التشغيلي ولا يجب تبسيطه إلى معالجة جماعية. fileciteturn1289file0

Main7 الحالي يحتوي بالفعل على النسخة Order-by-Order من `_openDeliveryModal(rsCode)`، لذلك **M7-09 لا يُعاد طلبه**. هذه النسخة تنفذ: Runsheet scoped -> start-delivery مرة واحدة -> Orders بترتيب `created_at ASC` -> Order واحد لكل modal -> `order_details` بواسطة `order_id` -> `remaining = qty_loaded - qty_delivered` -> `complete-order-delivery` لكل Order -> `complete-delivery` بعد آخر Order فقط.

## 5. Main7 items التي أصبحت مطبقة بالفعل ولا تُعاد
1. M7-07B — `voucherReference` موجود حاليًا داخل grid النماذج في `loadVoucherForm(type)`؛ لا إعادة تنفيذ.
2. M7-09 — Order-by-Order Delivery موجود في Main7 الحالي؛ لا إعادة تنفيذ.
3. بعض company scopes في Receiving/Voucher list/Voucher details موجودة بالفعل.
4. receive remaining-quantity وIdempotency-Key payload في receive voucher موجودان بالفعل.
5. `_openNewVoucherModal()` يوجّه إلى `loadVoucherForm()`.
6. Picking status list تعرض `Open / Confirmed`.

## 6. Main7 Owner Surgeries — المطلوب منك تنفيذه يدويًا
**مهم:** هذه التعديلات لم ينفذها المساعد في Git. المطلوب هو تطبيقها يدويًا على `Current/PWA/main2/main7.md`.

### M7-10 — `loadSettlement()` + `_onSettlementRsChange()`
سبب الإصلاح: النسخة الحالية ما زالت تحتوي على lookup غير scoped، وlookup خاطئ لـ`order_details.runsheet_id` رغم أن `order_details` لا يحتوي هذا العمود، وlookup خاطئ لـ`stock_voucher_details` بواسطة `voucher_code`، واستخدام `countedByItem` قبل تعريفه.

#### M7-10A — `loadSettlement()`
مرجع السطر الحالي المثبت في Report92: حوالي **930**.

ابحث عن السطر الكامل:
```javascript
var runsheetsRes = await supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Delivered', 'Returned']);
```

احذف السطر كاملًا واستبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Delivered', 'Returned']);
```

#### M7-10B + M7-10C + M7-10D — استبدال الدالة `_onSettlementRsChange()` كاملة
ابحث عن:
```javascript
async function _onSettlementRsChange() {
```

احذف **الدالة كاملة** بداية من هذا السطر وحتى السطر `}` الكامل الذي يأتي مباشرة قبل:
```javascript
function _saveSettlement() {
```

استبدل الدالة كاملة بالنص التالي:
```javascript
async function _onSettlementRsChange() {
    var rsCode = byId('settlement-rs-select')?.value;
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!rsCode) {
        byId('settlement-details-container').classList.add('hidden');
        return;
    }
    if (!companyId) {
        showToast('سياق الشركة غير محدد', 'error');
        return;
    }

    showLoader('جاري تحميل بيانات التسوية...');

    try {
        var rsRes = await supabase.from('runsheets')
            .select('*')
            .eq('company_id', companyId)
            .eq('runsheet_code', rsCode)
            .maybeSingle();
        if (rsRes.error) throw rsRes.error;

        var rs = rsRes.data;
        if (!rs) {
            hideLoader();
            showToast('الرانشيت غير موجود', 'error');
            return;
        }

        var loadedRes = await supabase.from('run_sheet_details')
            .select('*')
            .eq('runsheet_id', rs.id);
        if (loadedRes.error) throw loadedRes.error;
        var loadedItems = loadedRes.data || [];

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

        var vouchersRes = await supabase.from('stock_vouchers')
            .select('id, voucher_code')
            .eq('company_id', companyId)
            .eq('reference', rsCode)
            .eq('type', 'Return');
        if (vouchersRes.error) throw vouchersRes.error;

        var voucherIds = (vouchersRes.data || []).map(function(v) { return v.id; });
        var returnDetails = [];
        if (voucherIds.length > 0) {
            var retRes = await supabase.from('stock_voucher_details')
                .select('*')
                .in('voucher_id', voucherIds);
            if (retRes.error) throw retRes.error;
            returnDetails = retRes.data || [];
        }

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

        var itemsMap = {};
        for (var i = 0; i < loadedItems.length; i++) {
            var it = loadedItems[i];
            itemsMap[it.item_code] = {
                itemCode: it.item_code,
                itemName: it.item_name,
                unit: it.unit,
                loadedQty: Number(it.qty_loaded) || 0,
                deliveredQty: 0,
                returnedQty: 0,
                countedQty: Number(countedByItem[it.item_code]) || 0,
                unitPrice: Number(it.unit_price) || 0
            };
        }

        for (var j = 0; j < orderDetails.length; j++) {
            var od = orderDetails[j];
            if (itemsMap[od.item_code]) {
                itemsMap[od.item_code].deliveredQty += Number(od.qty_delivered) || 0;
                itemsMap[od.item_code].returnedQty += Number(od.qty_refused) || 0;
            }
        }

        for (var k = 0; k < returnDetails.length; k++) {
            var rd = returnDetails[k];
            if (itemsMap[rd.item_code]) {
                itemsMap[rd.item_code].returnedQty += Number(rd.qty) || 0;
            }
        }

        var html = '';
        var totalShortage = 0;
        var totalShortageValue = 0;

        for (var code in itemsMap) {
            var itm = itemsMap[code];
            var shortage = itm.loadedQty - itm.deliveredQty - itm.returnedQty - itm.countedQty;
            var shortageValue = shortage * itm.unitPrice;

            if (shortage > 0) {
                totalShortage += shortage;
                totalShortageValue += shortageValue;
            }

            html += '<tr class="border-b"><td class="p-2"><div class="font-bold">' + itm.itemName + '</div><div class="text-xs text-gray-400">' + itm.itemCode + '</div></td><td class="p-2 text-center">' + itm.loadedQty + '</td><td class="p-2 text-center">' + itm.deliveredQty + '</td><td class="p-2 text-center">' + itm.returnedQty + '</td><td class="p-2 text-center font-bold">' + itm.countedQty + '</td><td class="p-2 text-center font-bold text-red-600">' + shortage + '</td><td class="p-2 text-center">' + Math.abs(shortageValue).toLocaleString() + ' EGP</td></tr>';
        }

        safeHTML(byId('settlement-items-body'), html || '<tr><td colspan="7" class="p-6 text-center">لا توجد بيانات</td></tr>');
        safeHTML(byId('settlement-rs-info'), '<strong>المندوب:</strong> ' + (rs.driver_id || '---') + ' | <strong>السيارة:</strong> ' + (rs.vehicle_id || '---') + ' | <strong>التاريخ:</strong> ' + (rs.run_date || '---'));
        byId('settlement-details-container').classList.remove('hidden');

        window._settlementData = {
            rs: rs,
            items: itemsMap,
            totalShortage: totalShortage,
            totalShortageValue: totalShortageValue
        };

        hideLoader();
    } catch (e) {
        hideLoader();
        showToast('فشل تحميل البيانات: ' + (e.message || ''), 'error');
    }
}
```

### M7-11 — `loadBranchCount()`
مرجع السطر الموجود في Report92: داخل option الخاص بالفرع.

ابحث عن النص الكامل:
```javascript
'<option value="' + (b.branch_code || b.id || '') + '"'
```

استبدله حرفيًا بـ:
```javascript
'<option value="' + (b.id || b.branch_code || '') + '"'
```

### M7-12 — `_saveVehicleCount()`
المرجع الرقمي الحالي: بداية الدالة **حوالي السطر 835**.

ابحث عن:
```javascript
async function _saveVehicleCount() {
```

احذف الدالة كاملة حتى `}` الذي يسبق مباشرة:
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

    var selectedRunsheet = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';
    var vehicleId = null;

    var userRes = await supabase.from('users')
        .select('id')
        .eq('company_id', companyId)
        .eq('email', selectedDriver)
        .maybeSingle();
    if (userRes.error) { showToast(userRes.error.message, 'error'); return; }
    var driverId = userRes.data ? userRes.data.id : null;

    if (selectedRunsheet) {
        var rsRes = await supabase.from('runsheets')
            .select('vehicle_id')
            .eq('company_id', companyId)
            .eq('runsheet_code', selectedRunsheet)
            .maybeSingle();
        if (rsRes.error) { showToast(rsRes.error.message, 'error'); return; }
        vehicleId = rsRes.data ? rsRes.data.vehicle_id : null;
    }

    if (!vehicleId && driverId) {
        var vehicleRes = await supabase.from('vehicles')
            .select('id')
            .eq('company_id', companyId)
            .eq('driver_id', driverId)
            .limit(1)
            .maybeSingle();
        if (vehicleRes.error) { showToast(vehicleRes.error.message, 'error'); return; }
        vehicleId = vehicleRes.data ? vehicleRes.data.id : null;
    }

    if (!vehicleId) { showToast('لا توجد مركبة مرتبطة بهذا المندوب', 'warning'); return; }
    await _saveInvCount('vehicle', vehicleId, reference || 'جرد سيارة');
}
```

### M7-13 — `_saveGeneralCount()`
ابحث عن الدالة الكاملة:
```javascript
async function _saveGeneralCount() {
```

احذف حتى `}` الذي يسبق مباشرة تعليق:
```javascript
// ==================== SETTLEMENT (إغلاق اليومية) ====================
```

استبدل الدالة كاملة بـ:
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

### M7-14 + M7-16 — Company Scope Exact Patches
لا تغيّر Business Flow. غيّر الـtenant boundary فقط.

#### 1) `loadPicking()` — المرجع الحالي: السطر 540
ابحث عن السطر الكامل:
```javascript
var res = await supabase.from('runsheets').select('*').in('status', ['Open', 'Confirmed']);
```

احذفه واستبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Open', 'Confirmed']);
```

#### 2) `_showPickingDetails(code)`
ابحث عن السطر الكامل:
```javascript
var rsRes = await supabase.from('runsheets').select('id').eq('runsheet_code', code).maybeSingle();
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
```

#### 3) `loadVehicleCount()` — Runsheet selector
ابحث عن السطر الكامل:
```javascript
var runsheetsRes = await supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Loaded', 'Delivering', 'Delivered', 'Returning']);
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Loaded', 'Delivering', 'Delivered', 'Returning']);
```

#### 4) `_searchDriver(query)`
ابحث عن السطر الكامل:
```javascript
var res = await supabase.from('users').select('email, name').in('role', ['driver','سائق','مندوب']).ilike('name', '%' + query + '%');
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { div.classList.add('hidden'); return; }
var res = await supabase.from('users')
    .select('email, name')
    .eq('company_id', companyId)
    .in('role', ['driver','سائق','مندوب'])
    .ilike('name', '%' + query + '%');
```

#### 5) `loadUnloading()`
ابحث عن السطر الكامل:
```javascript
var res = await supabase.from('runsheets').select('*').in('status', ['Open','New']);
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Open','New']);
```

#### 6) `loadLoading()` — المرجع الحالي: السطر 580
ابحث عن السطر الكامل:
```javascript
var res = await supabase.from('runsheets').select('*').in('status', ['Loaded']);
```

استبدله كاملًا بنفس البناء التالي:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Loaded']);
```

#### 7) `loadDelivery()` — المرجع الحالي: السطر 619
ابحث عن السطر الكامل:
```javascript
var res = await supabase.from('runsheets').select('*').in('status', ['Delivered']);
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Delivered']);
```

#### 8) `loadReturn()`
ابحث عن السطر الكامل:
```javascript
var res = await supabase.from('runsheets').select('*').in('status', ['Returned']);
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('runsheets')
    .select('*')
    .eq('company_id', companyId)
    .in('status', ['Returned']);
```

#### 9) `_showLoadingDetails(code)`
ابحث عن السطر الكامل:
```javascript
var rsRes = await supabase.from('runsheets').select('id').eq('runsheet_code', code).maybeSingle();
```

استبدله كاملًا بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
```

#### 10) `_showDeliveryDetails(code)`
ابحث عن السطر الكامل:
```javascript
var rsRes = await supabase.from('runsheets').select('id').eq('runsheet_code', code).maybeSingle();
```

هذا النص يتكرر في Main7. لا تحذف نصًا عامًا. نفّذ الاستبدال **داخل الدالة `_showDeliveryDetails(code)` فقط**، وبعد السطر:
```javascript
showLoader('جاري التحميل...');
```
أضف:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
```
ثم استبدل الـlookup داخل الدالة فقط بـ:
```javascript
var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
```

#### 11) `_showReturnDetails(code)`
نفّذ نفس الاستبدال **داخل الدالة `_showReturnDetails(code)` فقط**:
بعد:
```javascript
showLoader('جاري التحميل...');
```
أضف:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
```
واستبدل الـlookup إلى:
```javascript
var rsRes = await supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', code)
    .maybeSingle();
```

#### 12) `_openPickingModal(rsCode)`
ابحث داخل الدالة فقط عن:
```javascript
supabase.from('runsheets').select('id').eq('runsheet_code', rsCode).maybeSingle()
```

قبلها مباشرة أضف:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
```

واستبدل الاستعلام كاملًا بـ:
```javascript
supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', rsCode)
    .maybeSingle()
```

#### 13) `_openLoadingModal(rsCode)`
داخل الدالة فقط، استبدل:
```javascript
supabase.from('runsheets').select('id').eq('runsheet_code', rsCode).maybeSingle()
```
بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', rsCode)
    .maybeSingle()
```

#### 14) `_openReturnModal(rsCode)`
داخل الدالة فقط، استبدل:
```javascript
supabase.from('runsheets').select('id').eq('runsheet_code', rsCode).maybeSingle()
```
بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { hideLoader(); showToast('سياق الشركة غير محدد', 'error'); return; }
supabase.from('runsheets')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_code', rsCode)
    .maybeSingle()
```

## 7. M7-15 — Voucher Entity UUID + DirectSale representative
هذا الإصلاح مطلوب لأن Production Core الحالي يفرض:
- `from_id` و`to_id` UUID.
- Transfer = Branch UUID -> Branch UUID.
- DirectSale = Branch UUID -> Vehicle UUID + `p_rep_id` صحيح.
- DirectReturn = Vehicle UUID -> Branch UUID.
- SupplierReturn = Branch UUID -> Supplier UUID.
- `items.item_code` عالمي UNIQUE.

Production `create_manual_stock_voucher_atomic(...)` الحالي لديه overload 12-arg، والـcore `create_manual_stock_voucher_atomic_core_12_20260828` يطلب `p_rep_id` عند DirectSale لمنشئ `active_warehouse_role='أذونات'` ويثبت المركبة على المندوب. لذلك مجرد تحويل email إلى UUID غير كافٍ.

### M7-15A — `loadVoucherForm(type)` config
داخل `var configs = { ... }` ابحث عن السطور الأربعة التي تحتوي على:
```javascript
fromId: 'MAIN'
```
أو:
```javascript
toId: 'MAIN'
```

احذف قيمة `'MAIN'` فقط واستبدلها بـ`null` في كل config:
- Transfer: `fromId: null, toId: null`
- DirectSale: `fromId: null, toId: null`
- DirectReturn: `fromId: null, toId: null`
- SupplierReturn: `fromId: null, toId: null`

### M7-15B — استبدال `_loadVoucherEntityOptions(type)` كاملة
ابحث عن:
```javascript
async function _loadVoucherEntityOptions(type) {
```

احذف الدالة كاملة حتى `}` الذي يسبق مباشرة:
```javascript
function _searchVoucherItem(query) {
```

استبدلها بـ:
```javascript
async function _loadVoucherEntityOptions(type) {
    var select = byId('voucherEntitySelect');
    if (!select) return;

    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) {
        showToast('سياق الشركة غير محدد', 'error');
        return;
    }

    if (type === 'Transfer') {
        var branchRes = await supabase.from('branches')
            .select('id, branch_code, name, branch_name')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name');
        if (branchRes.error) { showToast(branchRes.error.message, 'error'); return; }

        var branchHtml = '<option value="">-- اختر فرعاً --</option>';
        var branches = branchRes.data || [];
        for (var i = 0; i < branches.length; i++) {
            branchHtml += '<option value="' + branches[i].id + '">' + (branches[i].name || branches[i].branch_name || branches[i].branch_code || '') + '</option>';
        }
        safeHTML(select, branchHtml);
        return;
    }

    if (type === 'SupplierReturn') {
        var supplierRes = await supabase.from('suppliers')
            .select('id, supplier_code, name')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name');
        if (supplierRes.error) { showToast(supplierRes.error.message, 'error'); return; }

        var supplierHtml = '<option value="">-- اختر مورداً --</option>';
        var suppliers = supplierRes.data || [];
        for (var s = 0; s < suppliers.length; s++) {
            supplierHtml += '<option value="' + suppliers[s].id + '">' + (suppliers[s].name || suppliers[s].supplier_code || '') + '</option>';
        }
        safeHTML(select, supplierHtml);
        return;
    }

    var driverRoles = type === 'DirectSale'
        ? ['مندوب بيع مباشر']
        : ['driver', 'سائق', 'مندوب', 'مندوب بيع مباشر'];

    var usersRes = await supabase.from('users')
        .select('id, email, name, role')
        .eq('company_id', companyId)
        .in('role', driverRoles)
        .eq('status', 'Active');
    if (usersRes.error) { showToast(usersRes.error.message, 'error'); return; }

    var drivers = usersRes.data || [];
    var driverIds = drivers.map(function(d) { return d.id; });
    if (!driverIds.length) {
        safeHTML(select, '<option value="">-- لا توجد سيارات متاحة --</option>');
        return;
    }

    var vehicleRes = await supabase.from('vehicles')
        .select('id, vehicle_code, license_plate, driver_id')
        .eq('company_id', companyId)
        .eq('status', 'Active')
        .in('driver_id', driverIds)
        .order('vehicle_code');
    if (vehicleRes.error) { showToast(vehicleRes.error.message, 'error'); return; }

    var driverMap = {};
    for (var d = 0; d < drivers.length; d++) driverMap[drivers[d].id] = drivers[d];

    var vehicleHtml = '<option value="">-- اختر سيارة --</option>';
    var vehicles = vehicleRes.data || [];
    for (var v = 0; v < vehicles.length; v++) {
        var vehicle = vehicles[v];
        var driver = driverMap[vehicle.driver_id] || {};
        var label = (driver.name || driver.email || '') + ' — ' + (vehicle.vehicle_code || vehicle.license_plate || vehicle.id);
        vehicleHtml += '<option value="' + vehicle.id + '">' + label + '</option>';
    }
    safeHTML(select, vehicleHtml);
}
```

### M7-15C — استبدال `_saveAndSendVoucher()` كاملة
ابحث عن:
```javascript
async function _saveAndSendVoucher() {
```

احذف الدالة كاملة حتى `}` الذي يسبق مباشرة تعليق:
```javascript
// ==================== VOUCHERS LIST – عرض الأذونات مع فصل ====================
```

استبدلها كاملة بـ:
```javascript
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
            rep_id: repId
        };

        var createRes = await fetch(RW_SUPABASE_URL + '/functions/v1/create-stock-voucher', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify(createBody)
        });

        var createJson = await createRes.json();
        if (!createJson.success) {
            hideLoader();
            showToast(createJson.msg || 'فشل الحفظ', 'error');
            return;
        }

        var sendRes = await fetch(RW_SUPABASE_URL + '/functions/v1/send-stock-voucher', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify({ voucher_code: createJson.voucherId })
        });

        var sendJson = await sendRes.json();
        hideLoader();

        if (sendJson.success) {
            showToast('تم إنشاء وإرسال الإذن ' + createJson.voucherId, 'success');
            voucherCart = [];
            _renderVoucherCart();
        } else {
            showToast(sendJson.msg || 'فشل الإرسال', 'error');
        }
    } catch (e) {
        hideLoader();
        showToast(e.message || 'فشل الاتصال', 'error');
    }
}
```

**لا تغيّر** `driver.html`، ولا `_openDeliveryModal(rsCode)`، ولا `complete_order_delivery_atomic`, ولا lifecycle labels `Picking/Picked/Loading/Loaded/Delivering/Delivered/Returning/Returned`.

## 8. Production changes executed in this session
تمت مراجعة Production ومصادر Edge/RPC الحالية. لم يتم إجراء تعديل Production خاص بـMain7 في هذه الجلسة لأن Production الحالية ذات الصلة بالتوصيل والجرد موجودة في الحالة الصحيحة بالفعل، بينما الجراحات المفتوحة تخص `main7.md` الذي يملكه المستخدم.

تم توثيق أن `create-stock-voucher` الحالي v10 و`send-stock-voucher` v20 و`receive-stock-voucher` v22 تعمل كقدرات حديثة، وأن Delivery functions الحالية تستخدم authenticated company context، وأن `save-inventory-count` يستخدم vehicle `mobile_branch_id || vehicle.id` كما هو متوافق مع M7-12.

## 9. اكتشاف Inventory Core إضافي
فحص PostgreSQL لدوال المخزون أظهر:
- `post_stock_movement` هو Physical Stock writer المركزي.
- `complete_runsheet_picking` يستخدم `reserve_stock` ويغيّر fulfillment quantities؛ لا يكتب Physical Stock مباشرة.
- `post_inventory_adjustment_atomic` يفوض Physical movement إلى `post_stock_movement`.
- `post_manual_stock_voucher_atomic_core_20260828` يفوض Physical movement إلى `post_stock_movement`.
- `send_stock_voucher_atomic_core_20260828` يفوض Physical movement إلى `post_stock_movement`.
- `setup_van_stock` يهيئ صفوف `stock_branches` بكمية صفر للمخزن المتنقل، ولا ينشئ Movement أو inventory_log.

بالتالي لا يوجد في هذا الفحص دليل على Physical Stock engine ثانٍ خارج `post_stock_movement`.

## 10. أخطاء/تجارب الجلسة
1. استعلام Writer discovery أولًا فشل لأن استدعاء `pg_get_functiondef()` شمل aggregate functions؛ أعيد الاستعلام مع `prokind='f'` ونجح.
2. تم اكتشاف أن Main7 SHA تغير عن Report92، فتم إيقاف الاعتماد على تقرير قديم وإعادة قراءة blob الحالي مباشرة.
3. تم كشف أن محاولة اختبار Purchase Receipt السابقة كانت غير صالحة لإثبات retry بسبب اختلاف operation identity، وتم اعتماد مبدأ Client Operation Identity الصريح بدل خوارزمية تخمين.
4. لم يتم إنشاء بيانات تشغيلية دائمة في Delivery / Order / Runsheet.

## 11. Source of Truth
`forensic_main_assembly.yml` الحالي يثبت أن:
`Current/PWA/main2/**` هو مصدر الأجزاء القابل للتحرير، و`Current/PWA/New-main` هو هدف التجميع، و`Current/PWA/main/**` تاريخ فقط. لا يوجد تعديل مطلوب لمسار workflow. fileciteturn1325file0

## 12. حالة الإغلاق
- PRODUCTION INVENTORY WRITER CORE = CLOSED / VERIFIED BY CURRENT DB FUNCTION INVENTORY
- MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED
- DELIVERY CONTRACT = PROVEN / PROTECTED
- DRIVER ORDER-BY-ORDER CONTRACT = PROVEN / PROTECTED
- MAIN7 CURRENT SHA = `b6d19e0b9c775d02594e4cba868e63455b009824`
- M7-07B = ALREADY APPLIED IN CURRENT SOURCE
- M7-09 = ALREADY APPLIED IN CURRENT SOURCE
- M7-10 = OWNER ACTION REQUIRED
- M7-11 = OWNER ACTION REQUIRED
- M7-12 = OWNER ACTION REQUIRED
- M7-13 = OWNER ACTION REQUIRED
- M7-14 = OWNER ACTION REQUIRED
- M7-15 = OWNER ACTION REQUIRED
- M7-16 = OWNER ACTION REQUIRED
- FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN
- PARENT GOLD/DIAMOND = NOT CLOSED

## 13. Final Self-Audit
### What I Proved
- قرأت مصادر الحوكمة المطلوبة.
- قارنت Report92 مع SHA الحالي ولم أتعامل مع تقرير قديم باعتباره Truth.
- أثبتُّ عقد Delivery الحالي من Production وdriver.html.
- أثبتُّ عقد Physical Stock المركزي من PostgreSQL function inventory.
- أثبتُّ أن Main7 الحالي يحتوي بالفعل M7-07B وM7-09.
- أثبتُّ أن M7-15 يحتاج UUID + rep_id وليس مجرد UUID conversion.

### What I Did Not Prove
- لم يثبت تشغيل Delivery end-to-end في هذه الجلسة لعدم وجود Runsheet/Orders تشغيلية حالية في Production.
- لم يثبت التجميع النهائي لـMain2 لأن Main7 owner surgeries لم تُطبّق بعد.
- لم يثبت Zero-debt للـMain7 حتى تُطبق الجراحات اليدوية ويُعاد فحص Main7 النهائي.

### What I Fixed
- لا يوجد Main7 source write من المساعد في هذه الجلسة.
- تم تحديث/تدقيق Production context وعقودها، وتم الحفاظ على Delivery وdriver.html.

### Final Confidence
`FORENSIC REVIEW = HIGH`
`MAIN7 SOURCE SURGERY = PENDING OWNER EXECUTION`
`PRODUCTION DELIVERY CONTRACT = PROVEN`
`FULL GOLD/DIAMOND = NOT YET CLOSED`
