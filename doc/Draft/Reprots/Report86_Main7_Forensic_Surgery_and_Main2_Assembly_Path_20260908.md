# Report86 — Main7 Forensic Surgery and Main2 Assembly Path — 2026-09-08

## 1. نطاق الجلسة
الهدف كان استرجاع آخر حالة من المصادر الأصلية، إعادة مطابقة Production، تصحيح مسار reconstruction إلى `Current/PWA/main2`, ثم إجراء forensic review كامل لـ`Current/PWA/main2/main7.md` وتوثيق الجراحات المطلوبة دون أن يقوم المساعد بتعديل ملف Main7 نفسه، التزامًا بقاعدة ملكية الملف الأم.

## 2. المصادر المقروءة
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`
- `CURRENT_STATE.md` قبل الجلسة
- `doc/Draft/Reprots/Report85_Main6_Recheck_and_Assembly_Boundary_20260908.md`
- `Current/PWA/main2/main7.md` من Git الحالي
- `tools/run_final_main_reconstruction_20260831.py`
- `.github/workflows/forensic_main_assembly.yml`
- تاريخ Git الخاص بـMAIN7 وملفات reconstruction ذات العلاقة
- Production Supabase functions / schema / edge deployments

## 3. Production checkpoint — نفس لحظة التقرير
Production project: `fiilmooggumokxanwiyx`

وقت اللقطة:
`2026-09-08 06:12:44.498422+00`

النتيجة:
- companies: 1
- branches: 2
- users: 24
- items: 17
- stock_branches: 20
- orders: 0
- purchase_orders: 0
- stock_vouchers: 0
- inventory_log: 3

لا توجد Orders أو Purchase Orders أو Stock Vouchers تشغيلية دائمة في Production تسمح باختبار دورة أعمال كاملة دون fixture transactional.

## 4. أهم ما تم إثباته من Production
### 4.1 Physical Stock Writer boundary
المسح الجنائي للدوال الحالية أثبت أن الـdirect physical writers خارج المحركات المسموح بها = 0.

المسموح:
- `post_stock_movement` — Physical Stock Engine.
- `reserve_stock` / `release_stock_reservation` — Reservation only.
- `setup_van_stock` / `create_vehicle_atomic` — initialization of stock rows, وليس حركة مخزنية تشغيلية.

كما أن `complete_runsheet_picking` يغيّر fulfillment quantities وreservation فقط، ولا ينفذ `stock_branches.qty` movement مستقلًا.

### 4.2 Legacy core capabilities
تم إغلاق صلاحية التنفيذ في Production للـlegacy cores:
- `post_manual_stock_voucher_atomic_core_20260828`
- `send_stock_voucher_atomic_core_20260828`

تم التنفيذ عبر migration:
`revoke_legacy_inventory_core_execution_20260908`

لا تزال الـcanonical functions الحالية قابلة للاستخدام، ولا تم حذف الـlegacy definitions حتى يبقى التاريخ محفوظًا.

### 4.3 Current Return / Delivery contracts
`complete-return` Production v25 حاليًا wrapper إلى `complete_return_atomic`، و`complete_return_atomic` يمرر Physical Return عبر `post_stock_movement`.

`complete-order-delivery` Production v14 wrapper إلى `complete_order_delivery_atomic`، وDelivery يغيّر operational fulfillment state فقط؛ الـPhysical Stock تم ترحيله عند Loading.

## 5. Assembly boundary correction
Report85 أثبت أن reconstruction القديم كان يعتمد:
`Current/PWA/main/*`

بينما مصدر العمل الذي حدده المستخدم هو:
`Current/PWA/main2/main1.md ... main11.md`

تم تنفيذ التصحيح في Git:
1. `tools/run_final_main_reconstruction_20260831.py`
   - `CUR` أصبح `Current/PWA/main2`.
   - `PARTS` أصبحت مبنية من `main2/main1..main11`.
2. `.github/workflows/forensic_main_assembly.yml`
   - trigger path أصبح `Current/PWA/main2/**`.
   - canonical source assertion أصبح `main2`.
   - deep source audit أصبح يقارن `Current/PWA/main2/*` مع `Original/PWA/main/*` التاريخي.
   - حالة `Current/PWA/main/*` لم تعد Source of Truth.
3. الـworkflow persistence message أصبح يسجل صراحة أن `main2` هو canonical editable source وأن `New-main` هو generated target.

Git commits الناتجة عن هذا التصحيح:
- `97968baccaa20f42888506b1bc0e1fb5bd1c278d`
- `cd1f022d945ca62bb7668afe78027ea6d7bdcb52`
- `27740512c1da8531869e0a31cc6cee1575c25635`

## 6. CI execution result
تم إطلاق execution باستخدام `[CTO_EXECUTE_P163]` للتحقق الفعلي من المسار الجديد.

الـpush فعّل Workflow آخر موجود تاريخيًا باسم:
`CTO Single Controlled New-main UX 2026-09-03`

الـrun:
`34193895898`

والنتيجة:
`failure`

لم ينتج عن endpoint الـJobs أي Jobs قابلة للفحص (`total_count=0`) في نتيجة API الحالية؛ لذلك لا يوجد دليل كافٍ لإعلان assembly/runtime pass.

الاستنتاج الصحيح:
`MAIN2 SOURCE PATH = CORRECTED IN GIT`
لكن:
`FULL MAIN2 ASSEMBLY = NOT PROVEN CLOSED`
وذلك لأن الـgenerated target وbrowser runtime لم يحصل لهما verification ناجح مثبت من الـrun الحالي.

## 7. Main7 forensic result
الـblob الحالي لـ`Current/PWA/main2/main7.md`:
`6f7aef60ac137cd7f6b74281a17835dbd29595be`

تمت قراءة الملف من بدايته حتى نهايته، وتمت مطابقة الأجزاء الحرجة مع Production current contracts وتاريخ Git.

## 8. Main7 defects proven in source
### M7-00 — settlement syntax boundary
أداة reconstruction الحالية تحتوي إصلاحًا جراحيًا محددًا لـMain7:
`.join(''));}` → `.join('')));}`
لكن هذا الإصلاح موجود في reconstruction normalizer وليس داخل source fragment نفسه؛ لذلك يجب تثبيت الإصلاح داخل `main7.md` قبل أن يصبح Main7 source closed.

### M7-01 — Receiving query company scope
`loadReceiving()` يقرأ `receiving` بدون company scope.

### M7-02 — Receiving details scope
`_showReceivingDetails()` يعتمد operation id فقط. وبما أن `receiving.operation_id` UNIQUE فهذا ليس identity collision بحد ذاته، لكن flow يجب أن يثبت أن عملية الاستلام نفسها تابعة لـcompany الحالية قبل تحميل تفاصيلها.

### M7-03 — Drivers lookup
`_loadVoucherEntityOptions()` عند `DirectSale/DirectReturn` يقرأ users حسب role فقط دون company scope.

### M7-04 — Vouchers list scope
`loadVouchers()` يقرأ `stock_vouchers` بدون `company_id`.

### M7-05 — Voucher details scope
`_viewVoucherDetails()` يقرأ `stock_voucher_details` بـ`voucher_code` فقط، مع أن `stock_vouchers.voucher_code` UNIQUE داخل الشركة وليس عالميًا.

### M7-06 — Receive idempotency / remaining quantity
`_receiveVoucher()` لا يرسل `operation_id` ولا `Idempotency-Key`، والقيمة الافتراضية الحالية هي كامل quantity بدل remaining quantity.
Production الحالية تدعم operation identity للاستلام.

### M7-07 — Empty Voucher creation
`_openNewVoucherModal()` يحاول إنشاء Voucher بـ`items: []`، بينما canonical create contract يفرض وجود صنف واحد على الأقل. المسار الصحيح هو فتح `loadVoucherForm(type)` ثم الإضافة من نموذج الأصناف.

### M7-08 — Lifecycle status drift
في `loadPicking/loadLoading/loadDelivery/loadReturn` تظهر حالات:
- `Picked`
- `Loaded`
- `Delivered`
- `Returned`

بينما العقد التنفيذي المتحقق تاريخيًا للمرحلة الحالية يستخدم:
- `Picking`
- `Loading`
- `Delivering`
- `Returning`

### M7-09 — Delivery semantic defect
`_openDeliveryModal()` يبني `ordersData` ويضع كمية `qty_loaded` الخاصة بالـrunsheet لكل Order، ثم يرسلها إلى `complete-delivery`.
Production الحالية لا تعتبر `complete-delivery` fulfillment writer؛ هي state transition للـrunsheet.
المسار الصحيح هو:
`Order-specific remaining quantities -> complete-order-delivery -> after all orders complete -> complete-delivery`

### M7-10 — Settlement counted quantity
`countedQty` يبقى صفرًا بدون مصدر Inventory Count مثبت. لم تتم وصفة إصلاح نهائية له لعدم كفاية دليل العقد الحالي.

### M7-11 — Unloading details placeholder
`_showUnloadingDetails()` ما زالت placeholder (`التفاصيل قيد التطوير`). لم يتم اختراع سلوك جديد دون contract مثبت.

## 9. Exact Main7 surgical instructions — owner execution only
**ممنوع تعديل `Current/PWA/main2/main7.md` بواسطة المساعد.**
نفذ الجراحات التالية يدويًا بالترتيب، جراحة كاملة ثم التالية.

### M7-00
ابحث عن النص الكامل حرفيًا:
```text
.join(''));}
```
احذفه واستبدله بالنص الكامل:
```text
.join('')));}
```
لا تحذف السطر السابق ولا التالي؛ هذا الاستبدال للنص المحدد فقط.

### M7-01
ابحث عن السطر الكامل:
```js
var res = await supabase.from('receiving').select('*');
```
واستبدله بالكامل بهذا المقطع:
```js
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('receiving').select('*').eq('company_id', companyId).order('date', { ascending: false });
```

### M7-02
ابحث عن الدالة كاملة من:
```js
async function _showReceivingDetails(opId) {
```
حتى آخر سطر قبل:
```js
// ==================== VOUCHER FORM – نماذج الأذونات الأربعة ====================
```
واحذف **الدالة كاملة** واستبدلها بهذا المقطع:
```js
async function _showReceivingDetails(opId) {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    showLoader('جاري التحميل...');
    var opRes = await supabase.from('receiving').select('operation_id').eq('company_id', companyId).eq('operation_id', opId).maybeSingle();
    if (opRes.error || !opRes.data) { hideLoader(); showToast('عملية الاستلام غير موجودة في الشركة الحالية', 'error'); return; }
    var detRes = await supabase.from('receiving_details').select('*').eq('operation_id', opRes.data.operation_id);
    hideLoader();
    var details = detRes.data || [];
    if (!details.length) { showToast('لا توجد تفاصيل', 'info'); return; }
    var h = '<div class="text-right"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الكود</th><th class="p-2">الصنف</th><th class="p-2 text-center">الوحدة</th><th class="p-2 text-center">المطلوب</th><th class="p-2 text-center">الفعلي</th><th class="p-2 text-center">الفرق</th><th class="p-2">السبب</th></tr></thead><tbody>';
    details.forEach(function(d) {
        h += '<tr><td class="p-2 border">' + esc(d.item_code || '') + '</td><td class="p-2 border font-semibold">' + esc(d.item_name || '') + '</td><td class="p-2 border text-center">' + esc(d.unit || '') + '</td><td class="p-2 border text-center">' + (d.qty_expected || 0) + '</td><td class="p-2 border text-center font-bold">' + (d.qty_received || 0) + '</td><td class="p-2 border text-center">' + (d.difference || 0) + '</td><td class="p-2 border">' + esc(d.reason || '') + '</td></tr>';
    });
    h += '</tbody></table></div>';
    Swal.fire({ title: 'تفاصيل الاستلام: ' + esc(opRes.data.operation_id), html: h, width: '800px', showCloseButton: true, showConfirmButton: false });
}
```

### M7-03
ابحث عن السطر الكامل:
```js
var res = await supabase.from('users').select('email, name').in('role', ['driver', 'سائق', 'مندوب']);
```
واستبدله بالكامل بهذا:
```js
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('users').select('email, name').eq('company_id', companyId).in('role', ['driver', 'سائق', 'مندوب']);
```

### M7-04
ابحث عن السطر الكامل:
```js
var res = await supabase.from('stock_vouchers').select('*').order('voucher_date', { ascending: false });
```
واستبدله بالكامل بهذا:
```js
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var res = await supabase.from('stock_vouchers').select('*').eq('company_id', companyId).order('voucher_date', { ascending: false });
```

### M7-05
ابحث عن الدالة كاملة:
```js
async function _viewVoucherDetails(voucherCode) {
```
حتى القوس النهائي الذي يغلق هذه الدالة مباشرة قبل:
```js
async function _sendVoucher(voucherCode) {
```
واحذف الدالة كاملة واستبدلها بهذا:
```js
async function _viewVoucherDetails(voucherCode) {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    showLoader('جاري التحميل...');
    var voucherRes = await supabase.from('stock_vouchers').select('id,voucher_code').eq('company_id', companyId).eq('voucher_code', voucherCode).maybeSingle();
    if (voucherRes.error || !voucherRes.data) { hideLoader(); showToast('الإذن غير موجود في الشركة الحالية', 'error'); return; }
    var detRes = await supabase.from('stock_voucher_details').select('*').eq('voucher_id', voucherRes.data.id).order('item_code');
    hideLoader();
    var details = detRes.data || [];
    if (!details.length) { showToast('لا توجد تفاصيل', 'info'); return; }
    var h = '<table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2">الكود</th><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية</th><th class="p-2 text-center">المستلمة</th></tr></thead><tbody>';
    details.forEach(function(d) {
        h += '<tr><td class="p-2 border">' + esc(d.item_code || '') + '</td><td class="p-2 border font-semibold">' + esc(d.item_name || '') + '</td><td class="p-2 border text-center">' + (d.qty || 0) + '</td><td class="p-2 border text-center">' + (d.received_qty || 0) + '</td></tr>';
    });
    h += '</tbody></table>';
    Swal.fire({ title: 'تفاصيل الإذن: ' + esc(voucherRes.data.voucher_code), html: h, width: '600px', showCloseButton: true, showConfirmButton: false });
}
```

### M7-06
ابحث عن الدالة كاملة:
```js
async function _receiveVoucher(voucherCode) {
```
حتى القوس النهائي قبل:
```js
async function _openNewVoucherModal() {
```
واحذف **الدالة كاملة** واستبدلها بهذا المقطع:
```js
async function _receiveVoucher(voucherCode) {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    showLoader('جاري تحميل تفاصيل الإذن...');
    var voucherRes = await supabase.from('stock_vouchers').select('id,status,voucher_code,to_id').eq('company_id', companyId).eq('voucher_code', voucherCode).maybeSingle();
    if (voucherRes.error || !voucherRes.data) { hideLoader(); showToast('الإذن غير موجود في الشركة الحالية', 'error'); return; }
    if (voucherRes.data.status !== 'Sent') { hideLoader(); showToast('الإذن غير جاهز للاستلام: ' + (voucherRes.data.status || ''), 'warning'); return; }
    var detRes = await supabase.from('stock_voucher_details').select('*').eq('voucher_id', voucherRes.data.id).order('item_code');
    var details = detRes.data || [];
    hideLoader();
    if (!details.length) { showToast('لا توجد تفاصيل لهذا الإذن', 'info'); return; }
    var html = '<div class="text-right"><table class="w-full border text-sm"><thead class="bg-gray-100"><tr><th class="p-2 border">الصنف</th><th class="p-2 border text-center">المرسل</th><th class="p-2 border text-center">المستلم سابقًا</th><th class="p-2 border text-center">المتبقي</th><th class="p-2 border text-center">استلام الآن</th></tr></thead><tbody>';
    for (var i = 0; i < details.length; i++) {
        var d = details[i];
        var totalQty = Number(d.qty || 0);
        var receivedBefore = Number(d.received_qty || 0);
        var remaining = Math.max(0, totalQty - receivedBefore);
        html += '<tr><td class="p-2 border font-semibold">' + esc(d.item_name || '') + ' (' + esc(d.item_code || '') + ')</td><td class="p-2 border text-center font-bold">' + totalQty + '</td><td class="p-2 border text-center">' + receivedBefore + '</td><td class="p-2 border text-center font-bold text-blue-700">' + remaining + '</td><td class="p-2 border text-center"><input type="number" id="vrec_qty_' + i + '" value="' + remaining + '" class="w-24 p-1 border rounded text-center" min="0" max="' + remaining + '" step="0.01"></td></tr>';
    }
    html += '</tbody></table></div>';
    var result = await Swal.fire({
        title: 'استلام الإذن: ' + esc(voucherCode),
        html: html,
        width: '850px',
        showCancelButton: true,
        confirmButtonText: 'تأكيد الاستلام',
        confirmButtonColor: '#10b981',
        cancelButtonText: 'إلغاء',
        preConfirm: function() {
            var items = [];
            var hasQty = false;
            for (var j = 0; j < details.length; j++) {
                var maxRemaining = Math.max(0, Number(details[j].qty || 0) - Number(details[j].received_qty || 0));
                var qty = parseFloat((document.getElementById('vrec_qty_' + j) || {}).value) || 0;
                if (qty < 0 || qty > maxRemaining) {
                    Swal.showValidationMessage('كمية الاستلام تتجاوز المتبقي للصنف: ' + (details[j].item_code || ''));
                    return false;
                }
                if (qty > 0) hasQty = true;
                items.push({ itemCode: details[j].item_code || '', itemName: details[j].item_name || '', unit: details[j].unit || 'حبة', receivedQty: qty });
            }
            if (!hasQty) { Swal.showValidationMessage('أدخل كمية واحدة على الأقل للاستلام'); return false; }
            return items;
        }
    });
    if (!result.isConfirmed) return;
    var positiveItems = (result.value || []).filter(function(x) { return Number(x.receivedQty || 0) > 0; }).sort(function(a,b) { return String(a.itemCode).localeCompare(String(b.itemCode)); });
    var operationId = 'UI-RECEIVE:' + companyId + ':' + voucherRes.data.id + ':' + positiveItems.map(function(x) { return String(x.itemCode) + ':' + Number(x.receivedQty); }).join('|');
    showLoader('جاري الاستلام...');
    var ses = await supabase.auth.getSession();
    var token = ses.data.session ? ses.data.session.access_token : null;
    if (!token) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }
    try {
        var res = await fetch(RW_SUPABASE_URL + '/functions/v1/receive-stock-voucher', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token, 'Idempotency-Key': operationId },
            body: JSON.stringify({ voucher_code: voucherCode, receivedItems: positiveItems, operation_id: operationId })
        });
        var json = await res.json();
        hideLoader();
        if (json.success) { showToast(json.msg || (json.duplicate ? 'تم تأكيد العملية السابقة' : 'تم الاستلام'), 'success'); loadVouchers(); }
        else showToast(json.error || json.msg || 'فشل الاستلام', 'error');
    } catch (e) { hideLoader(); showToast('فشل الاتصال بـ Edge Function', 'error'); }
}
```

### M7-07
ابحث عن الدالة كاملة:
```js
async function _openNewVoucherModal() {
```
حتى القوس النهائي قبل:
```js
// ==================== PICKING ====================
```
واحذفها كاملة واستبدلها بهذا:
```js
async function _openNewVoucherModal() {
    var typeOptions = '<option value="Transfer">تحويل داخلي</option><option value="DirectSale">صرف سيارة بيع مباشر</option><option value="DirectReturn">استلام مرتجع سيارة</option><option value="SupplierReturn">مرتجع لمورد</option>';
    var html = '<div class="text-right space-y-3"><div><label class="text-xs font-bold">نوع الإذن</label><select id="newVoucherType" class="swal2-input w-full">' + typeOptions + '</select></div></div>';
    var result = await Swal.fire({ title: 'إنشاء إذن مخزني جديد', html: html, showCancelButton: true, confirmButtonText: 'متابعة', cancelButtonText: 'إلغاء', preConfirm: function() { var type = document.getElementById('newVoucherType').value; if (!type) { Swal.showValidationMessage('اختر نوع الإذن'); return false; } return { type: type }; } });
    if (!result.isConfirmed) return;
    loadVoucherForm(result.value.type);
}
```

### M7-08
نفذ هذه الاستبدالات الأربعة حرفيًا فقط:

1. ابحث عن:
```html
<option>Picked</option>
```
واستبدله بـ:
```html
<option>Picking</option>
```
ثم ابحث عن:
```js
.in('status', ['Picked'])
```
واستبدله بـ:
```js
.in('status', ['Picking'])
```
ثم ابحث عن النص داخل badge:
```text
Picked
```
داخل `loadPicking/_applyPicking` فقط واستبدله بـ:
```text
Picking
```

2. ابحث عن:
```html
<option>Loaded</option>
```
واستبدله بـ:
```html
<option>Loading</option>
```
ثم:
```js
.in('status', ['Loaded'])
```
إلى:
```js
.in('status', ['Loading'])
```
ثم badge `Loaded` داخل `loadLoading/_applyLoading` إلى `Loading`.

3. ابحث عن:
```js
.in('status', ['Delivered'])
```
واستبدله بـ:
```js
.in('status', ['Delivering'])
```
ثم badge `Delivered` داخل `loadDelivery/_applyDelivery` إلى `Delivering`.

4. ابحث عن:
```js
.in('status', ['Returned'])
```
واستبدله بـ:
```js
.in('status', ['Returning'])
```
ثم badge `Returned` داخل `loadReturn/_applyReturn` إلى `Returning`.

**لا تستبدل كل كلمة في الملف دفعة واحدة.** كل استبدال يخص الموضع المحدد أعلاه فقط.

### M7-09
ابحث عن الدالة كاملة:
```js
function _openDeliveryModal(rsCode) {
```
حتى القوس النهائي قبل:
```js
function _openReturnModal(rsCode) {
```
واحذف الدالة كاملة واستبدلها بهذا المقطع:
```js
async function _openDeliveryModal(rsCode) {
    if (!rsCode) { showToast('رقم الرانشيت غير صالح', 'error'); return; }
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    showLoader('جاري تحميل بيانات التوصيل...');
    try {
        var rsRes = await supabase.from('runsheets').select('id,status,vehicle_id').eq('company_id', companyId).eq('runsheet_code', rsCode).maybeSingle();
        var rs = rsRes.data;
        if (rsRes.error || !rs) { hideLoader(); showToast('الرانشيت غير موجود', 'error'); return; }

        var itemsRes = await supabase.from('run_sheet_details').select('item_code,item_name,unit,qty_loaded').eq('runsheet_id', rs.id).order('item_code');
        var loadedItems = itemsRes.data || [];
        if (!loadedItems.length) { hideLoader(); showToast('لا توجد أصناف في هذا الرانشيت', 'info'); return; }

        var startSes = await supabase.auth.getSession();
        var startToken = startSes.data.session ? startSes.data.session.access_token : null;
        if (!startToken) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }
        var startRes = await fetch(RW_SUPABASE_URL + '/functions/v1/start-delivery', {
            method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + startToken }, body: JSON.stringify({ runsheet_code: rsCode })
        });
        var startJson = await startRes.json();
        if (!startJson.success) { hideLoader(); showToast(startJson.msg || 'فشل بدء التوصيل', 'error'); return; }

        var ordersRes = await supabase.from('orders').select('id,order_code,customer_name').eq('company_id', companyId).eq('runsheet_id', rs.id).order('created_at', { ascending: true });
        var orders = ordersRes.data || [];
        if (!orders.length) { hideLoader(); showToast('لا توجد أوامر مرتبطة بالرانشيت', 'warning'); return; }
        var orderIds = orders.map(function(o) { return o.id; });
        var detailRes = await supabase.from('order_details').select('id,order_id,item_code,item_name,unit,qty,qty_loaded,qty_delivered').in('order_id', orderIds).order('created_at', { ascending: true });
        var allDetails = detailRes.data || [];

        var detailsByOrder = {};
        for (var oi = 0; oi < orders.length; oi++) detailsByOrder[orders[oi].id] = [];
        for (var di = 0; di < allDetails.length; di++) if (detailsByOrder[allDetails[di].order_id]) detailsByOrder[allDetails[di].order_id].push(allDetails[di]);

        var html = '<div class="text-right" dir="rtl"><div class="max-h-[500px] overflow-y-auto space-y-4">';
        var fieldIndex = 0;
        for (var o = 0; o < orders.length; o++) {
            var order = orders[o];
            var ods = detailsByOrder[order.id] || [];
            html += '<div class="border rounded-xl p-3 bg-gray-50"><h4 class="font-black text-blue-600 mb-2">' + esc(order.order_code || '') + ' - ' + esc(order.customer_name || '') + '</h4>';
            if (!ods.length) {
                html += '<div class="text-sm text-red-500">لا توجد تفاصيل للأمر.</div>';
            } else {
                html += '<table class="w-full border text-sm"><thead class="bg-white"><tr><th class="p-2 border">الصنف</th><th class="p-2 border text-center">محمّل</th><th class="p-2 border text-center">مسلّم سابقًا</th><th class="p-2 border text-center">المتبقي</th><th class="p-2 border text-center">تسليم الآن</th></tr></thead><tbody>';
                for (var li = 0; li < ods.length; li++) {
                    var od = ods[li];
                    var loaded = Number(od.qty_loaded || 0);
                    var delivered = Number(od.qty_delivered || 0);
                    var remaining = Math.max(0, loaded - delivered);
                    var fieldId = 'rw_deliver_' + fieldIndex++;
                    od._fieldId = fieldId;
                    html += '<tr><td class="p-2 border font-semibold">' + esc(od.item_name || '') + ' (' + esc(od.item_code || '') + ')</td><td class="p-2 border text-center">' + loaded + '</td><td class="p-2 border text-center">' + delivered + '</td><td class="p-2 border text-center font-bold text-blue-700">' + remaining + '</td><td class="p-2 border text-center"><input type="number" id="' + fieldId + '" value="' + remaining + '" min="0" max="' + remaining + '" step="0.01" class="w-24 p-1 border rounded text-center"></td></tr>';
                }
                html += '</tbody></table>';
            }
            html += '</div>';
        }
        html += '</div></div>';
        hideLoader();

        var result = await Swal.fire({ title: 'توصيل الرانشيت: ' + esc(rsCode), html: html, width: '950px', showCancelButton: true, confirmButtonText: 'إنهاء التوصيل', cancelButtonText: 'إلغاء', preConfirm: function() {
            var orderPayloads = [];
            for (var p = 0; p < orders.length; p++) {
                var ord2 = orders[p];
                var ods2 = detailsByOrder[ord2.id] || [];
                var payloadItems = [];
                for (var q = 0; q < ods2.length; q++) {
                    var od2 = ods2[q];
                    var input = document.getElementById(od2._fieldId);
                    var remaining2 = Math.max(0, Number(od2.qty_loaded || 0) - Number(od2.qty_delivered || 0));
                    var qty2 = parseFloat(input ? input.value : 0) || 0;
                    if (qty2 < 0 || qty2 > remaining2) { Swal.showValidationMessage('كمية التسليم غير صالحة للصنف: ' + (od2.item_code || '')); return false; }
                    if (qty2 > 0) payloadItems.push({ itemCode: od2.item_code, deliveredQty: qty2, reason: '' });
                }
                orderPayloads.push({ orderCode: ord2.order_code, items: payloadItems });
            }
            return orderPayloads;
        }});
        if (!result.isConfirmed) return;

        showLoader('جاري تحديث أوامر التوصيل...');
        var ses = await supabase.auth.getSession();
        var token = ses.data.session ? ses.data.session.access_token : null;
        if (!token) { hideLoader(); showToast('انتهت الجلسة', 'error'); return; }

        for (var pi = 0; pi < result.value.length; pi++) {
            var orderPayload = result.value[pi];
            if (!orderPayload.items.length) continue;
            var orderRes = await fetch(RW_SUPABASE_URL + '/functions/v1/complete-order-delivery', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
                body: JSON.stringify({ runsheet_code: rsCode, order_code: orderPayload.orderCode, items: orderPayload.items })
            });
            var orderJson = await orderRes.json();
            if (!orderJson.success) throw new Error(orderJson.msg || ('فشل إنهاء الطلب ' + orderPayload.orderCode));
        }

        var finishRes = await fetch(RW_SUPABASE_URL + '/functions/v1/complete-delivery', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
            body: JSON.stringify({ runsheet_code: rsCode })
        });
        var finishJson = await finishRes.json();
        hideLoader();
        if (!finishJson.success) throw new Error(finishJson.msg || 'فشل إنهاء حالة الرانشيت');
        showToast('تم إنهاء التوصيل وتحديث الأوامر بنجاح', 'success');
        if (typeof RW_Runsheets !== 'undefined' && RW_Runsheets._apply) RW_Runsheets._apply();
        loadDelivery();
    } catch (e) {
        hideLoader();
        showToast(e && e.message ? e.message : 'فشل تنفيذ دورة التوصيل', 'error');
    }
}
```

## 10. لماذا هذه الجراحات غير ترقيعية
- لا تضيف Physical Stock writer جديدًا؛ المخزون يظل عبر Production core.
- لا تستخدم `item_code` كـtenant key في الجداول المقيدة بالشركة؛ حيث توجد UNIQUE contracts عالمية أو يتم ربط السجل بالـUUID الأب أولًا.
- RECEIVE يستخدم operation identity ثابتة للـretry، ويدخل فقط الكمية المتبقية.
- Delivery يصبح Order-specific في `complete-order-delivery` ثم state transition للـrunsheet في `complete-delivery`.
- lifecycle labels أصبحت تعكس stage الحالية بدل state بعد الإنهاء.
- empty voucher creation لا يعود يخلق record ناقصًا.

## 11. What was not done
- لم يتم تعديل `Current/PWA/main2/main7.md` مباشرة، التزامًا بقاعدة ownership.
- لم يتم نشر Parent PWA إلى Production.
- لم يتم إعلان Gold/Diamond.
- لم يتم إجراء fixture دائم في Production.
- لم يتم فرض M7-10/M7-11 دون evidence كافٍ.

## 12. Failure memory
### Failure A
تم إطلاق CI من commit `[CTO_EXECUTE_P163]`، لكن Workflow تاريخي آخر على `main` انتهى `failure` دون Jobs قابلة للفحص.

### Root assessment
لا يوجد دليل كافٍ لتحديد أن failure سببه MAIN2 reconstruction نفسه؛ لذلك لم يتم اختراع سبب سببي.

## 13. Final Self-Audit
### What I proved
- Production current snapshot was queried immediately before execution.
- Physical Stock direct writers outside the allowed engine set = 0.
- Legacy manual/send inventory cores are no longer executable.
- Current Return and Order Delivery Production contracts are centralized at the capability/RPC level.
- `Current/PWA/main2` is now the configured canonical reconstruction source in Git.
- Main7 was read directly and concrete defects M7-00..M7-09 were identified.

### What I did not prove
- Successful full reconstruction from all 11 main2 fragments after the new source-path correction.
- Successful browser runtime verification of the generated parent after the correction.
- Production deployment/runtime verification of a Main2-generated parent.
- Main7 source closure after owner surgery.
- Final real-world E2E of picking/loading/delivery/return with persistent operational data.

### Current closure
`PRODUCTION INVENTORY WRITER CORE = CLOSED`
`LEGACY INVENTORY CORE EXECUTION = CLOSED`
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`FULL MAIN2 ASSEMBLY = OPEN / CI VERIFICATION FAILED`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`PARENT GOLD/DIAMOND = NOT CLOSED`
