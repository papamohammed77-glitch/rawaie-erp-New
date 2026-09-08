# Report91 — Main7 Gold/Diamond Surgical Recheck — 2026-09-08

## 1. نطاق الجلسة
تم استرجاع السياق من:
- `CURRENT_STATE.md`.
- `doc/Draft/medhat/MASTER - RAWAEA ERP.md`.
- `doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md`.
- `doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md`.
- `doc/Draft/medhat/تقرير مبادئ حاكمة`.
- `doc/Draft/medhat/برومبت استكمال مهام`.
- `doc/Draft/Reprots/Report87`.
- `doc/Draft/Reprots/Report89_Main7_Surgical_Review_20260908.md`.
- `doc/Draft/Reprots/Report90_Main7_Final_Tenant_Scope_Addendum_20260908.md`.
- `Current/PWA/main2/main7.md` من Git مباشرة وبـSHA الحالي `0962e20262e77e9e6d8905c83098c2d5fac9210c`.
- `Current/PWA/driver.html` من Git مباشرة.
- Production Supabase الحالية.

لم يتم تعديل `Current/PWA/main2/main7.md` لأن ملكية هذا الجزء للمستخدم، وتطبيق الجراحات عليه يتم يدويًا.

## 2. قواعد الحوكمة المستخدمة
التسلسل الحاكم:
`READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → TEST → DEPLOY → VERIFY PRODUCTION → DOCUMENT → UPDATE CURRENT_STATE`.

تم الحفاظ على:
- Historical functionality.
- Parent Application structure.
- Driver.html business workflow.
- Runsheet lifecycle.
- Physical Stock Core.
- عدم اختلاق behavior غير مثبت.

## 3. Last Verified Event
أحدث أحداث Main7 المثبتة في Git قبل هذه الجلسة هي سلسلة التوثيق:
- `ae39cc98...` — Main7 surgical forensic review.
- `2aab41c3...` — Main7 forensic checkpoint update.
- `06a6c32d...` — final tenant-scope forensic addendum.
- `b5c5b6de...` — final Main7 tenant-scope findings.

التغيير البرمجي الأخير على Main7 نفسه ما يزال من commit:
`c03e5cb8002005ec31c0d4f032cab6fff70fba63` (`Update main7.md`).

Main7 الحالي لم يُستبدل بملف تاريخي آخر.

## 4. Historical Contract — Delivery / Driver
المراجعة التاريخية مع Report87 أثبتت أن الحالات:
`Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned`
هي lifecycle contract، وليست أخطاء تسمية.

لم يتم تغيير `Picked` إلى `Picking` أو أي حالة أخرى.

تم فتح `Current/PWA/driver.html` ومراجعة مسار Delivery فيه. Driver App يرسل عملية التسليم إلى:
`/functions/v1/complete-order-delivery`
بـ`runsheet_code + order_code` الخاصة بالأوردر الحالي، وليس كدفعة Runsheet-wide.

## 5. Production Delivery Contract
Production يثبت:
- `complete_order_delivery_atomic(p_company_id, p_runsheet_code, p_order_code, p_user_email, p_items)` هو Order-level fulfillment RPC.
- `complete-order-delivery` هو Wrapper للـOrder-level RPC.
- `complete-delivery` مسؤول عن إغلاق Runsheet من `Delivering` إلى `Delivered`، وليس تنفيذ Fulfillment لجميع الأوردرات.
- `complete_order_delivery_atomic` يستخدم `erp_operation_registry` للإيدempotency ولا يعدل Physical Stock.
- `complete_return_atomic` يمرر Physical Return إلى `post_stock_movement`.

النتيجة: Main7 يجب أن يحافظ على Order-by-Order Delivery، ولا يجوز تحويله إلى Batch Payload.

## 6. Main7 Current Source Findings
الـcurrent `main7.md` يحتوي بالفعل على معظم الجراحات السابقة المطبقة:
- Receiving company scope.
- Receiving Details verification.
- Driver lookup company scope في Voucher form.
- Voucher list company scope.
- Voucher details parent lookup ثم `voucher_id`.
- Receive remaining-quantity logic.
- Idempotency-Key + operation_id في Receive.
- `_openNewVoucherModal()` → `loadVoucherForm()`.
- Picking lifecycle unchanged.

لكن البنود التالية ما زالت Open.

## 7. M7-07B — Reference input
الموضع: `loadVoucherForm(type)`، السطور الحالية التقريبية `145–154` بحسب Report89/current checkpoint.

ابحث عن الكتلة الكاملة:
`<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">`
التي تنتهي مباشرة قبل:
`<div class="mb-4">`

احذف الكتلة كاملة، وآخر سطر للحذف هو:
`</div>`
الخاص بالشبكة نفسها، قبل كتلة `بحث عن صنف` مباشرة.

استبدلها بـ:
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

ولا تعدل كتلة `بحث عن صنف` التالية.

## 8. M7-09 — Delivery Order-by-Order
الدالة كاملة:
`function _openDeliveryModal(rsCode) {`
تبدأ حاليًا عند السطر `1193` تقريبًا، وتنتهي مباشرة قبل:
`function _openReturnModal(rsCode) {`

احذف الدالة كاملة حتى القوس `}` الأخير قبل `function _openReturnModal(rsCode) {`.

استبدل الدالة كاملة بالنسخة التي تثبت في Report89 والتي تنفذ:
1. Runsheet lookup بـ`company_id + runsheet_code`.
2. `start-delivery` مرة واحدة.
3. Orders lookup بواسطة `company_id + runsheet_id` وبترتيب `created_at ASC` مع الحقول `id,order_code,customer_name`.
4. فتح Order واحد في كل مرة.
5. قراءة `order_details` بـ`order_id` فقط.
6. حساب `remaining = qty_loaded - qty_delivered` لكل item.
7. إرسال Order الحالي فقط إلى `/functions/v1/complete-order-delivery` باستخدام:
   `runsheet_code`, `order_code`, `items`.
8. الانتقال إلى Order التالي فقط بعد نجاح الحالي.
9. بعد نجاح جميع Orders، استدعاء `/functions/v1/complete-delivery` بـ`{ runsheet_code: rsCode }` فقط.
10. حذف `ordersData` بالكامل من هذا المسار.
11. عدم استخدام `run_sheet_details` لاشتقاق كميات Order.

لا يتم تغيير lifecycle.

## 9. M7-10 / M7-10A / M7-10B / M7-10C — Settlement
### M7-10
الموضع: `_onSettlementRsChange()`، السطر المثبت في Report89/current checkpoint تقريبًا `962`:
`itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: 0, unitPrice: Number(it.unit_price) || 0 };`

أزل `countedQty: 0` من منطق البناء، ثم:
- resolve `rs.vehicle_id` داخل Company Scope.
- resolve `vehicles.id,mobile_branch_id` داخل نفس Company.
- `inventoryEntityId = mobile_branch_id || vehicle.id`.
- latest `inventory_counts`: `company_id`, `type='vehicle'`, `entity_id=inventoryEntityId`, `created_at DESC`.
- اقرأ `inventory_count_details` بواسطة `count_id`.
- ابنِ `countedByItem[item_code]`.
- استخدم `countedByItem[item_code] || 0` في `itemsMap`.

### M7-10A
في `loadSettlement()`، ابحث عن السطر الكامل:
`var runsheetsRes = await supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Delivered', 'Returned']);`

استبدله بـ:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Delivered', 'Returned']);
```

### M7-10B
داخل `_onSettlementRsChange()` ابحث عن الكتلة الكاملة التي تبدأ:
`var vouchersRes = await supabase.from('stock_vouchers').select('voucher_code').eq('reference', rsCode).eq('type', 'Return');`

وتنتهي عند:
`returnDetails = retRes.data || [];`

احذفها كاملة.

استبدلها بـlookup لـ`stock_vouchers` بـ`company_id` و`reference` و`type` مع الحقول `id,voucher_code`، ثم:
`voucherIds = rows.map(v => v.id)`
ثم query لـ`stock_voucher_details` باستخدام:
`.in('voucher_id', voucherIds)`.

### M7-10C
احذف السطر الكامل:
`var orderDetailsRes = await supabase.from('order_details').select('*').eq('runsheet_id', rs.id);`

واستبدله بتسلسل:
`orders` lookup بـ`company_id + runsheet_id`
→ استخراج `orders.id`
→ `order_details` بـ`.in('order_id', orderIds)`.

## 10. M7-12 — Vehicle Count Entity Identity
الدالة:
`async function _saveVehicleCount()`
تبدأ تقريبًا عند السطر `835`.

احذف الدالة كاملة حتى السطر:
`}`
الذي يسبق مباشرة:
`async function _saveInvCount(type, entityId, reference) {`

واستبدلها بدالة تقوم تحديدًا بـ:
- قراءة `companyId` من `RW_STATE.app.companyId`.
- الاحتفاظ بـ`window._selectedDriver` كهوية UI للمندوب.
- resolve driver → `users.id` داخل company.
- عند اختيار Runsheet: resolve `vehicle_id` من Runsheet داخل company.
- عند عدم وجود Runsheet: resolve vehicle من `vehicles.driver_id` داخل company.
- إرسال `vehicle.id` فقط إلى `_saveInvCount('vehicle', ...)`.

لا ترسل بريد المندوب أو driver id إلى `entityId`.

## 11. M7-11 — Branch Count Entity
في `loadBranchCount()` ابحث عن التعبير الكامل:
`(b.branch_code || b.id || '')`
داخل `option value`.

استبدله بـ:
`(b.id || b.branch_code || '')`

الهدف: إرسال UUID الخاص بالفرع إلى `save-inventory-count`.

## 12. M7-13 — General Count Entity
الدالة:
`async function _saveGeneralCount()`

احذف السطر الكامل:
`await _saveInvCount('general', 'MAIN', 'جرد عام' + (notes ? ' | ' + notes : ''));`

استبدله بتسلسل:
- `companyId = RW_STATE.app.companyId`.
- query `app_settings` بـ`.eq('company_id', companyId)` لاختيار `main_branch_id`.
- reject إذا لم يوجد `main_branch_id`.
- `await _saveInvCount('general', mainBranchId, 'جرد عام' + ...)`.

## 13. M7-14 — Additional Tenant Scope
نفذ الجراحات التالية كل واحدة في موضعها:

### `loadPicking()`
السطر الكامل الحالي:
`var res = await supabase.from('runsheets').select('*').in('status', ['Open', 'Confirmed']);`

استبدله بإضافة `companyId` والتحقق منه ثم:
`.eq('company_id', companyId)`.

### `_showPickingDetails(code)`
السطر الحالي:
`supabase.from('runsheets').select('id').eq('runsheet_code', code).maybeSingle()`

أضف:
`.eq('company_id', companyId)`
مع التحقق من `companyId` قبل الاستعلام.

### `loadVehicleCount()`
السطر الحالي:
`var runsheetsRes = await supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Loaded', 'Delivering', 'Delivered', 'Returning']);`

استبدله بإضافة:
`.eq('company_id', companyId)`.

### `_searchDriver(query)`
السطر الحالي:
`var res = await supabase.from('users').select('email, name').in('role', ['driver','سائق','مندوب']).ilike('name', '%' + query + '%');`

استبدله بإضافة Company Scope:
`.eq('company_id', companyId)`
مع التحقق من `companyId`.

### `loadUnloading()`
السطر الحالي:
`var res = await supabase.from('runsheets').select('*').in('status', ['Open','New']);`

استبدله بإضافة Company Scope:
`.eq('company_id', companyId)`
مع التحقق من `companyId`.

## 14. M7-15 — NEW: Voucher Entity Identity / UUID Contract
### السبب المثبت
Production Schema يثبت:
- `stock_vouchers.from_id` = `uuid`.
- `stock_vouchers.to_id` = `uuid`.
- `vehicles.id` = `uuid`.
- `branches.id` = `uuid`.

والـcurrent Main7 يرسل حاليًا في بعض الحالات:
- `fromId: 'MAIN'`.
- `branch_code` كـoption value قبل الإرسال.
- `driver email` كـentity عند DirectSale / DirectReturn.

كما أن Production `create-stock-voucher` يمرر `fromId/toId` إلى insert في أعمدة UUID مباشرة.

إذًا هذا **Integration Defect مثبت** وليس تفضيلًا أسلوبيًا.

### M7-15A — `loadVoucherForm(type)` config
في `loadVoucherForm(type)` ابحث عن config object الذي يحتوي:
`'Transfer': { ... fromId: 'MAIN', ... }`
و:
`'DirectSale': { ... fromId: 'MAIN', ... }`
و:
`'DirectReturn': { ... toId: 'MAIN', ... }`
و:
`'SupplierReturn': { ... fromId: 'MAIN', ... }`

احذف literals `MAIN` من `fromId/toId`.

اجعل `fromId` و`toId` يتم تحديدهما بعد resolve للـentity UUID داخل `_saveAndSendVoucher()`.

### M7-15B — `_loadVoucherEntityOptions(type)`
الدالة الحالية تعطي:
- Branch: `branch_code || id`.
- DirectSale/DirectReturn: `users.email`.

هذا غير متوافق مع UUID contract.

أعد بناء الخيارات بحيث:
- Transfer: option value = `branches.id`، مع `company_id` scope.
- DirectSale: option value = `vehicles.id`، مع `company_id` scope، ويظهر اسم/كود المركبة وبيانات السائق للعرض فقط.
- DirectReturn: option value = `vehicles.id`، مع `company_id` scope.
- SupplierReturn: option value = supplier identity التي يقبلها Production contract؛ لا تغيّر supplier business contract دون مصدر مباشر.

### M7-15C — `_saveAndSendVoucher()`
استبدل منطق:
`var toId = cfg.toId || entity;`
`var fromId = cfg.fromId || entity;`

بمنطق يعتمد على UUID الذي أُعيد من selector، ثم يمرره كما هو إلى Edge Function.

لا ترسل `MAIN`.
لا ترسل `branch_code` إلى UUID column.
لا ترسل `driver email` إلى `vehicles.id`.

## 15. ما لا يتم تغييره
- `M7-08` lifecycle labels.
- `Current/PWA/driver.html` business workflow.
- `complete_order_delivery_atomic`.
- `complete_return_atomic`.
- Physical Stock Core.
- `_showUnloadingDetails()` placeholder؛ لا behavior جديد دون contract مثبت.
- `forensic_main_assembly.yml`؛ المسار canonical الحالي صحيح ويشير إلى `Current/PWA/main2/**`.

## 16. Production status
لا يوجد Production change مطلوب بسبب M7-09 / M7-10 / M7-11 / M7-12 / M7-13 / M7-14 / M7-15؛ هذه Parent/Main7 integration surgeries.

Production contracts التي تحتاجها Main7 verified مباشرة في هذه الجلسة ولم يثبت فيها contradiction:
- Order Delivery contract.
- Runsheet Delivery finalization contract.
- Vehicle Inventory Count contract.
- Voucher UUID schema.
- Item global uniqueness.
- Order-to-Runsheet relational path.

## 17. Tests performed
### Passed / proved
- Main7 current SHA verified directly.
- Main7 EOF structurally intact: `})();` ثم `window.RW_Warehouse = RW_Warehouse;`.
- Delivery Order-level contract verified in Production.
- Driver.html Order-level Delivery call verified.
- Runsheet finalization distinguished from Order fulfillment.
- Vehicle Inventory Count identity contract verified.
- Stock Voucher UUID columns verified.
- `stock_voucher_details` parent linkage via `voucher_id` verified.
- `items.item_code` global UNIQUE verified.
- `order_details` does not contain `runsheet_id`.

### Not performed
- Browser/runtime Main7 verification, لأن Source surgery لم تُطبّق بعد من المالك.
- Full Main2 assembly verification، لأنها تتطلب اكتمال جميع الجراحات اليدوية.
- Persistent Delivery fixture test، وتم الامتناع عنه عمدًا.

## 18. Final Self-Audit
### What was proved
- Main7 source identity/current location.
- Historical lifecycle.
- Delivery ownership split.
- Driver.html Order-by-Order compatibility.
- Settlement data sources.
- Voucher UUID contract.
- Tenant-scope open items.

### What was not proved
- Browser integration بعد تطبيق الجراحات الجديدة.
- Final assembled Parent runtime.

### What was fixed in Production
- لا يوجد تعديل Production خاص بـMain7 في هذه الجلسة.

### What was initially missed
- M7-15: Voucher `from_id/to_id` UUID contract versus Main7 `MAIN/branch_code/driver email` values.

### What could still be wrong
- أي اختلاف بين Main7 بعد التعديل اليدوي وبين النصوص البديلة المقدمة هنا.
- أي Consumer خارج Main7 يعتمد على contract لم يظهر أثناء search.

## 19. Closure Status
`MAIN7 FORENSIC REVIEW = COMPLETE`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`DELIVERY CONTRACT = PROVEN`
`INVENTORY COUNT CONTRACT = PROVEN`
`TENANT SCOPE = OPEN UNTIL SURGERY APPLICATION`
`VOUCHER UUID INTEGRATION = OPEN UNTIL SURGERY APPLICATION`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`
`PARENT GOLD/DIAMOND = NOT CLOSED`

## 20. Next Authorized Action
المالك يطبق فقط الجراحات M7-07B, M7-09, M7-10, M7-10A, M7-10B, M7-10C, M7-11, M7-12, M7-13, M7-14, M7-15 على:
`Current/PWA/main2/main7.md`

ثم:
1. Read SOF→EOF.
2. Validate JavaScript syntax.
3. Verify function boundaries and delimiters.
4. Verify no `ordersData` in Delivery.
5. Verify Order-by-Order detail lookup.
6. Verify Vehicle Count UUID identity.
7. Verify Branch/General Count entity UUID identity.
8. Verify Voucher `from_id/to_id` UUID identity.
9. Verify all open operational queries are company-scoped.
10. Run canonical assembly from `Current/PWA/main2/main1..main11`.
11. Only after assembly passes, continue to Browser/Runtime gate.
