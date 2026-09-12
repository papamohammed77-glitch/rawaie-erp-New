# Report126 — Main7 Forensic Recheck — 2026-09-12

## 1. الهدف الحاكم — يجب قراءته بعناية وتكراره

هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية.
وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.

هذا الهدف **لم يتحقق بعد على مستوى Main7 بالكامل**؛ ما تم إغلاقه هنا هو التحقيق وإعداد التعديلات الجراحية الكاملة القابلة للتطبيق، مع تنفيذ ومراجعة Production حيث يلزم، دون الادعاء بإغلاق Main7 قبل تطبيق المالك للتعديلات على source fragment وإجراء البوابات النهائية.

## 2. قاعدة العمل

لا توجد ثقة تلقائية في أي تقرير سابق. تم استخدام التقارير كسياق فقط، ثم إعادة مطابقة الوقائع مع GitHub وProduction Supabase.

المصدر التحريري المعتمد:
`Current/PWA/main2/main7.md`

المرجع التاريخي فقط:
`Original/PWA/main/main7.md`

المسارات الموقوفة ولم تعد مصدرًا:
`Current/PWA/main/*`
`Current/PWA/New-main/*`

`forensic_main_assembly.yml` ما زال يشير إلى `Current/PWA/main2` ولا توجد حاجة لتغييره في هذه الدورة.

## 3. ما تمت قراءته والتحقق منه

تم فتح `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` كاملًا من البداية إلى النهاية، وتمت مطابقة مبادئه مع المهمة.

تم فتح `CURRENT_STATE.md` كاملًا، وكان آخر Checkpoint هو Main6.

تم فتح `Report125_Main6_Forensic_Recheck_20260912.md` كاملًا.

تم فتح `Current/PWA/main2/main7.md` من أول الملف، ثم إعادة قراءة مقاطعه حتى EOF والتحقق من أن نهاية الملف الفعلية هي:

`window.RW_Warehouse = RW_Warehouse;`

SHA الحالية التي تحققت منها:
`a65969f6bdc919d4a8d62a6704a7c556b7d35e91`

تم فتح `Original/PWA/main/main7.md` للمقارنة التاريخية. تبين أن Stub الخاص بتفاصيل التفريغ موجود أيضًا في النسخة التاريخية، ولذلك فهو نقص تاريخي يحتاج استكمالًا وظيفيًا وليس Regression حديثًا.

تم فتح التطبيقات المنفصلة ذات العلاقة المباشرة، وخاصة `Current/PWA/picker.html`، كما تمت مراجعة مسارات `complete-picking` وتتابع العمليات المخزنية في Main7.

## 4. Production Snapshot — الحالة الفعلية وقت المراجعة

Production Supabase الحالية:

- `start-picking` — Version 34 — ACTIVE — JWT required.
- `complete-picking` — Version 17 — ACTIVE — JWT required، ويدعم `operation_id` ويستخدم `erp_operation_registry` عند تقديمه.
- `unload-runsheet` — Version 6 — ACTIVE — JWT required، ويستدعي `complete_runsheet_unloading`.
- `save-inventory-count` — Version 2 — ACTIVE — JWT required، ويرجع `count_id` وليس `voucherId`.
- `save-daily-settlement` — Version 4 — ACTIVE — JWT required، ويتطلب `operation_id` UUID.
- `create-stock-voucher` — Version 10 — ACTIVE — JWT required، ويدعم `rep_id` و`operation_id` ويمرر الطلب إلى `create_manual_stock_voucher_atomic`.

Production `complete_runsheet_unloading` تتحقق من:
`runsheet.status = 'Loaded'`
ثم تمرر كل Physical Movement إلى:
`post_stock_movement`
وتنهي الرانشيت إلى `Picked`.

Production `complete_runsheet_picking` تستخدم:
`reserve_stock`
وليس Physical Stock Movement مباشرًا، وتدعم `operation_id`.

Production `post_daily_settlement_atomic` هي مصدر الحقيقة للحساب النهائي للعجز، وتستخدم:
`max(0, qty_loaded - qty_delivered - qty_returned)`
من `run_sheet_details`.

Production `items.item_code` عليها `UNIQUE` عالمي رسميًا، ولذلك عقد Global Item Master مثبت من الـSchema وليس افتراضًا.

## 5. Physical Stock Centrality — نتيجة Main7

تم فحص Main7 بحثًا عن:

- تعديل مباشر لـ `stock_branches.qty`.
- كتابة مباشرة إلى `inventory_log`.

لم توجد كتابة مباشرة من Main7 نفسه.

النتيجة:

`Main7 direct Physical Stock Writers = 0`

مسارات Main7 الصحيحة تعتمد على Edge/RPC، ويظل العقد المركزي:

`PHYSICAL STOCK MOVEMENT`
→ `post_stock_movement`
→ `stock_branches + inventory_log`

ولا توجد حاجة لإعادة بناء محرك المخزون من داخل Main7.

## 6. العيوب الوظيفية المثبتة في Main7

### MAIN7-N1 — Unloading status/filter خاطئ + شاشة التفاصيل Stub

Current `loadUnloading()` تبدأ فعليًا قرب السطر 917، وتستخدم:

```javascript
.in('status', ['Open','New']);
```

بينما Production `complete_runsheet_unloading` لا تعمل إلا عندما تكون الحالة:

```text
Loaded
```

كما أن:

```javascript
async function _showUnloadingDetails(code) { showToast('التفاصيل قيد التطوير', 'info'); }
```

هو Skeleton صريح.

### MAIN7-N2 — Barcode Scanner مفقود

الأزرار الموجودة في شاشات الجرد تستدعي:

```javascript
RW_Warehouse._startBarcodeScanner('vc')
RW_Warehouse._startBarcodeScanner('bc')
RW_Warehouse._startBarcodeScanner('gc')
```

لكن تعريف `_startBarcodeScanner` غير موجود في Main7، ولم يكن مصدّرًا في `return { ... }`.

هذه وظيفة ظاهرة للمستخدم لكنها ميتة.

### MAIN7-N3 — `_saveInvCount` يستخدم عقد Response قديمًا ويمسح لوحة خاطئة

Current code يعرض `json.voucherId` رغم أن Production يعيد `count_id`.
كما أن الكود يستخدم `_renderInvCart('vc')` دائمًا حتى لو كان الجرد Branch أو General.

### MAIN7-N4 — Settlement preview لا تطابق Production authority

Current preview كانت تخلط `qty_refused` وبعض مصادر الجرد مع حساب العجز.
Production authority تستخدم فقط:
`qty_loaded - qty_delivered - qty_returned`
من `run_sheet_details`.

هذا Contract mismatch حقيقي.

### MAIN7-N5 — Settlement submit لا يرسل `operation_id`

Production `save-daily-settlement` و`post_daily_settlement_atomic` يتطلبان `operation_id` UUID.
Main7 الحالي كان يرسل `runsheet_code` و`notes` فقط.

### MAIN7-N6 — Picking completion بلا Operation Identity ثابتة

Main7 الحالي يرسل `complete-picking` بلا `operation_id`.
Production يدعم explicit idempotency عبر `erp_operation_registry`.

### MAIN7-N7 — Create Stock Voucher بلا Operation Identity

Main7 الحالي يستدعي `create-stock-voucher` دون `operation_id`.
Production الحالية تدعم صراحة `rep_id` و`operation_id` وتعيد نفس voucher عند retry بنفس Operation Identity.

### MAIN7-N8 — Receiving list تعرض `itemsCount` من حقل غير موجود

`receiving` لا تحتوي `itemsCount`.
عدد البنود موجود في `receiving_details`.
Current Main7 كان يعرض `op.itemsCount`، ما يؤدي عمليًا إلى أرقام غير صحيحة/صفرية.

## 7. ما ثبت أنه صحيح ولا يجوز إعادة تغييره بلا دليل

- `loadPicking()` تستخدم `Open/Confirmed`، وهي متوافقة مع Production `start-picking` الحالية.
- `loadLoading()` تستخدم `Loaded`، وهي متوافقة مع lifecycle.
- `_openLoadingModal()` تحدد `max` بالكمية المحضّرة.
- `_receiveVoucher()` الحالية ترسل `operation_id` وتستخدم `Idempotency-Key` بالفعل؛ لا نعيد إصلاحها دون ضرورة.
- تدفق التوصيل داخل Main7 يظل Order-by-Order، وهو جزء من التصميم التاريخي ولا يجوز استبداله بتدفق جماعي غير مثبت.
- المرتجعات الحالية تستدعي `complete-return` ولا توجد مبررات لإعادة بناء هذا المحرك في هذه الدورة.
- جرد المخزون الحالي هو Snapshot/Count Journal، وليس Physical Stock Adjustment؛ لا نحوله إلى تعديل رصيد من داخل Main7 بدون عقد معتمد.

## 8. Owner Surgical Change Set — التنفيذ المطلوب على Main7

### MAIN7-O1 — Replace `loadReceiving()` بالكامل

**FILE:**
`Current/PWA/main2/main7.md`

**الموضع الحالي:** بداية الدالة `async function loadReceiving()` قرب السطر 7.

**ابحث عن هذا العنصر بالكامل:**

`async function loadReceiving() {`

**احذف الدالة كاملة حتى آخر `}` مباشرة قبل:**

`function _applyReceiving() {`

**البديل الكامل:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Receiving_20260912.js`

البديل يستخرج عدد البنود من `receiving_details` ويحافظ على الفلاتر الحالية ويضيف escaping صحيحًا.

### MAIN7-O2 — Replace `_saveAndSendVoucher()` بالكامل

**الموضع الحالي:** يبدأ عند السطر 319 تقريبًا وينتهي عند السطر 442 تقريبًا، وقبل تعليق:

`// ==================== VOUCHERS LIST – عرض الأذونات مع فصل ====================`

**ابحث عن:**

`async function _saveAndSendVoucher() {`

**احذف الدالة كاملة حتى آخر `}` قبل تعليق VOUCHERS LIST.**

**البديل الكامل:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_VoucherSave_20260912.js`

هذا البديل يرسل:
- `operation_id`
- `rep_id`
- `Idempotency-Key`

ويعيد استخدام Operation Identity عند فشل الإرسال بعد نجاح الإنشاء.

### MAIN7-O3 — Replace `loadUnloading() + _applyUnloading() + _showUnloadingDetails()`

**الموضع الحالي:** يبدأ عند السطر 917.

**آخر عنصر في المجموعة الحالية:**

`async function _showUnloadingDetails(code) { showToast('التفاصيل قيد التطوير', 'info'); }`

**نطاق الحذف:** من:

`async function loadUnloading() {`

حتى آخر `}` للدالة `_showUnloadingDetails`، أي قبل تعليق:

`// ==================== COUNT (الجرد) & SETTLEMENT (إغلاق اليومية) ====================`

وهو حاليًا يمر تقريبًا بالأسطر 917–946.

**البديل الكامل:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Unloading_20260912.js`

هذا البديل يحصر قائمة التفريغ في `Loaded` ويجعل تفاصيل التفريغ كاملة للعرض فقط دون أي Physical Stock Write من الواجهة.

### MAIN7-O4 — Add `_startBarcodeScanner(prefix)`

**لا تحذف `_searchInvItem`.**

**ابحث عن السطر الحالي قرب 1033:**

`function _searchInvItem(prefix, query) {`

**أضف فوقه مباشرة العنصر الكامل الموجود في بداية الملف:**

`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Inventory_20260912.js`

والعنصر المطلوب إضافته تحديدًا هو الدالة:

`async function _startBarcodeScanner(prefix) { ... }`

يجب إدخال الدالة كاملة حتى آخر `}` الخاص بها، وليس جزءًا منها.

الدالة تدعم:
- BarcodeDetector.
- الكاميرا الخلفية.
- `ean_13 / ean_8 / code_128 / code_39 / upc_a / upc_e / qr_code` حسب دعم المتصفح.
- البحث بالـbarcode أو `item_code`.
- fallback إلى البحث اليدوي عند عدم دعم الكاميرا.

### MAIN7-O5 — Replace `_saveInvCount()` بالكامل

**الموضع الحالي:** السطر 1129 تقريبًا.

**الحذف:** من:

`async function _saveInvCount(type, entityId, reference) {`

حتى آخر `}` مباشرة قبل:

`async function loadBranchCount() {`

النطاق الحالي يقارب 1129–1143.

**البديل الكامل موجود في:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Inventory_20260912.js`

ملاحظة: الملف نفسه يحتوي دالة `_startBarcodeScanner` التي يجب إضافتها في موضع O4، بالإضافة إلى `_saveInvCount` التي تحل عقد Response وCart clearing.

### MAIN7-O6 — Replace `_onSettlementRsChange()` بالكامل

**الموضع الحالي:** يبدأ عند السطر 1241.

**ابحث عن:**

`async function _onSettlementRsChange() {`

**احذف حتى آخر `}` مباشرة قبل:**

`function _saveSettlement() {`

**البديل الكامل:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Settlement_20260912.js`

البديل يجعل preview مطابقًا حرفيًا لقاعدة Production authority:

`Loaded - Delivered - Returned`

ويعرض Latest Vehicle Count كمرجع فقط، ولا يخلطه في الحساب النهائي للعجز.

### MAIN7-O7 — Replace `_saveSettlement()` بالكامل

**الموضع الحالي:** يبدأ بعد `_onSettlementRsChange()` مباشرة، قرب السطر 1404.

**احذف حتى آخر `}` مباشرة قبل:**

`function _openPickingModal(rsCode) {`

والذي يبدأ حاليًا قرب السطر 1451.

**البديل الكامل:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Settlement_20260912.js`

البديل:
- ينشئ Operation Identity واحدة للـexecution attempt.
- يرسل `operation_id`.
- يرسل `Idempotency-Key`.
- يحتفظ بالعملية pending عند فشل الشبكة.
- يمسحها بعد success/duplicate فقط.

### MAIN7-O8 — Replace `_openPickingModal()` بالكامل

**الموضع الحالي:** قرب السطر 1451.

**احذف حتى آخر `}` مباشرة قبل بداية:**

`function _openLoadingModal(rsCode) {`

والتي تبدأ حاليًا قرب السطر 1539.

**البديل الكامل:**
`doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Picking_20260912.js`

البديل:
- يحافظ على Start Picking الحالي.
- يضيف `operation_id`.
- يضيف `Idempotency-Key`.
- يتحقق من عدم تجاوز `qty_ordered`.
- يحتفظ بالـOperation Identity عند فشل الشبكة.
- يلغي identity عند إلغاء العملية يدويًا.

### MAIN7-O9 — Export `_startBarcodeScanner`

داخل `return { ... }` في نهاية `RW_Warehouse`.

**ابحث عن السطر الحالي قرب 1940:**

`_searchInvItem: _searchInvItem,`

**أضف فوقه مباشرة:**

```javascript
    _startBarcodeScanner: _startBarcodeScanner,
```

لا تغيّر أي سطر آخر في `return`.

## 9. Syntax Gate

تم اختبار كل replacement file مستقلًا باستخدام:

```text
node --check MAIN7_OWNER_REPLACEMENT_Unloading_20260912.js
node --check MAIN7_OWNER_REPLACEMENT_Inventory_20260912.js
node --check MAIN7_OWNER_REPLACEMENT_Settlement_20260912.js
node --check MAIN7_OWNER_REPLACEMENT_VoucherSave_20260912.js
node --check MAIN7_OWNER_REPLACEMENT_Receiving_20260912.js
node --check MAIN7_OWNER_REPLACEMENT_Picking_20260912.js
```

النتيجة النهائية بعد تصحيح خطأ صياغة مبكر في كتلة HTML/onclick:

`ALL_SYNTAX_OK`

لم يتم تحويل هذا إلى Final Main7 Syntax PASS لأن `main7.md` نفسه لم يُعد تركيبه بعد.

## 10. Production Changes in this Main7 cycle

لم يتم إجراء Migration Production جديدة خاصة بـMain7 بعد هذا التحقيق، لأن Production الحالية تحتوي بالفعل على العقود المطلوبة ولم يثبت نقص Backend يستدعي Mutation جديدة داخل هذه المرحلة.

القرار الحاكم:

`NO PRODUCTION CHANGE WITHOUT PROVEN GAP`

وأي Production execution إضافي بعد تطبيق owner source سيحدث فقط كـRuntime verification على المسار النهائي.

## 11. Related Applications / Field Operations

Main7 لا يملك Field Operations مستقلة عن التطبيقات المنفصلة؛ دوره في النظام الأم هو:

- عرض الحالة.
- متابعة العمليات.
- فتح dialogs للتنفيذ عند الحاجة.
- إرسال الطلبات إلى Edge Functions.
- إعادة قراءة النتائج.

Picker app الحالية تؤكد أن Picking persistence لا يجب أن تتم عبر UI مباشرة، بل:

`complete-picking`
→ `complete_runsheet_picking()`
→ `reserve_stock()`

والتعليمات التاريخية في التطبيق المنفصل تؤكد أن `run_sheet_details` Derived Data ولا ينبغي للواجهة أن تكتبها مباشرة.

Delivery الحالي يبقى Order-by-Order، وهي خاصية عملية مقصودة لا يجب تحويلها إلى batch flow شكلي.

## 12. ما تم إثبات عدم الحاجة لتعديله الآن

- لا تعديل لـ`core.js`.
- لا تعديل لـ`sw.js`.
- لا تعديل لـ`register-sw.js`.
- لا تعديل لـ`manifest.json`.
- لا تعديل لـ`Original/PWA/main`.
- لا تعديل لـ`Current/PWA/New-main`.
- لا تعديل لـ`forensic_main_assembly.yml`.
- لا إعادة بناء لـ`post_stock_movement`.
- لا إعادة بناء لـ`reserve_stock`.
- لا تغيير في Lifecycle التاريخي لـPicking/Loading/Delivery/Return إلا في الحدود المثبتة أعلاه.

## 13. ما لم يُغلق بعد

- Owner Apply لجميع التسع Owner Surgeries أعلاه.
- إعادة قراءة Main7 النهائي بعد الدمج من أول حرف حتى EOF.
- Final syntax check على Main7 النهائي.
- كشف duplicate declarations بعد الدمج.
- Runtime E2E authenticated على Picking.
- Runtime E2E authenticated على Unloading.
- Runtime E2E authenticated على Inventory Count.
- Runtime E2E authenticated على Settlement.
- Runtime E2E authenticated على Voucher Create/Send.
- التحقق من عدم وجود duplicate records بعد retries.
- Main7 Gold/Diamond closure.

## 14. Self Audit

### ما تم إثباته
- Main7 الحالي هو `Current/PWA/main2/main7.md`.
- SHA الحالية `a65969f6bdc919d4a8d62a6704a7c556b7d35e91`.
- EOF تمت مراجعته.
- Production contracts ذات الصلة تمت مطابقتها.
- Physical Stock Writer مباشر داخل Main7 = صفر.
- Unloading stub حقيقي.
- Barcode Scanner مفقود فعليًا.
- Inventory Count response contract mismatch مثبت.
- Settlement preview mismatch مثبت.
- Settlement operation_id missing مثبت.
- Picking operation_id missing مثبت.
- Voucher create operation_id missing مثبت.
- Receiving itemsCount مصدره غير موجود في Schema.

### ما لم يُثبت
- Final integrated syntax بعد owner merge.
- Browser E2E بعد owner merge.
- Gold/Diamond closure الكامل لـMain7.

### ما يمكن أن يكون خطأً إن لم يُراجع بعد الدمج
- أي خطأ نسخ/لصق أثناء Owner surgery.
- أي duplicate declaration ناتج عن ترك جزء من الدالة القديمة.
- أي mismatch مع Main8/Main6 بعد assembly.

## 15. Closure Status

```text
MAIN7 FORENSIC RECHECK = COMPLETED
MAIN7 HISTORICAL REVIEW = COMPLETED
MAIN7 PRODUCTION CONTRACT RECHECK = COMPLETED
MAIN7 RELATED APP TRACE = COMPLETED
MAIN7 DIRECT PHYSICAL WRITERS = 0
MAIN7 OWNER SURGERIES = PREPARED
MAIN7 REPLACEMENT SYNTAX = PASS
MAIN7 SOURCE FRAGMENT = OWNER ACTION REQUIRED
MAIN7 FINAL INTEGRATED SYNTAX = PENDING
MAIN7 RUNTIME E2E = PENDING
MAIN7 GOLD/DIAMOND = NOT CLOSED
FINAL ASSEMBLY = DEFERRED
```

## 16. Exact Artifacts

- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Receiving_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_VoucherSave_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Unloading_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Inventory_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Settlement_20260912.js`
- `doc/Draft/Reprots/MAIN7_OWNER_REPLACEMENT_Picking_20260912.js`

## 17. Next Exact Checkpoint

بعد تطبيق O1→O9 على `Current/PWA/main2/main7.md`:

1. اقرأ Main7 مرة أخرى من أول حرف حتى EOF.
2. احسب SHA الجديدة.
3. شغّل `node --check` على Main7 النهائي.
4. افحص duplicate `RW_Warehouse`, duplicate function declarations، وdelimiter balance.
5. اختبر Owner-visible flows.
6. اختبر Production Runtime لكل مسار متأثر.
7. نفذ retry tests لكل Operation Identity.
8. أغلق Main7 فقط عند نجاح كل Gates.
9. لا تبدأ Assembly قبل ذلك.
