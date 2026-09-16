# تقرير 208 — التحقيق الجنائي وربط إدارة المخازن والمخزون بالنظام الأم

**التاريخ:** 2026-09-16  
**النطاق:** Mother ERP + Inventory / Warehouse + Production Supabase  
**الحالة:** Production hardening تم تنفيذه والتحقق منه؛ دمج Consumer داخل Mother ما زال ينتظر Owner Surgical Patch ثم Browser/Network E2E مصادق.

## 1. مبدأ الحقيقة الحاكم

**الهدف ليس مجرد وجود تبويبات أو بنية شكلية. الهدف أن تصبح وظائف إدارة المخازن والمخزون مكتملة وظيفيًا ومتصلة فعليًا بالقلب المركزي وبالتطبيقات التنفيذية المنفصلة، دون كسر دورة الرانشيت والتحضير والتحميل والتوصيل والمرتجعات والتفريغ والجرد والتسويات.**

مصدر الحقيقة الحالي هو فقط:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولـFull Browser E2E يلزم أيضًا:

`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

Source of Truth للنظام الأم:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

الأجزاء التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` وNew-main ليست Source of Truth.

## 2. Git الحالي والـParent

Current frontend HEAD وقت التحقيق:

`d3b411cd0d7557ba0948ce9823fa2465e422ad80`

وقبل تعديلات أدوات التحقيق كان:

`898a31dc65ea0e2d91b3c8ba292fc26c9b0c4d39`

والـparent السابق له:

`5f88f5c3c81bc389e953a9b18e7231c8da6f43c1`

تم فحص الـparent وليس الاعتماد على رقم HEAD فقط.

آخر التغييرات في frontend خلال هذه الجلسة تخص أدوات التحقيق والحماية فقط، ولم يتم تعديل Mother HTML نفسه.

## 3. Mother الحالي — أدلة مباشرة

الملف الحالي:

`companies/company-1/main.html`

حجمه المثبت بواسطة workflow:

`1,254,016 bytes`

اختبار Browser Smoke الحالي:

`MOTHER_BROWSER_SMOKE=PASS`

`Console errors = 0`

`Page errors = 0`

### Inventory Menu

الموقع الحالي المثبت:

`line 1145`

ويضم حاليًا:

الأصناف، المخازن والفروع، العمليات المخزنية، الأذونات المخزنية، والجرد.

### Current Dispatcher

القسم الحالي المثبت:

`20932+`

وأهم الأسطر:

`20953` → picking → `RW_Warehouse.loadPicking()`

`20954` → loading → `RW_Warehouse.loadLoading()`

`20955` → delivery → `RW_Warehouse.loadDelivery()`

`20956` → return → `RW_Warehouse.loadReturn()`

`20961` → unloading → `RW_Warehouse.loadUnloading()`

`20962` → receiving → `RW_Warehouse.loadReceiving()`

`20963` → vouchers → `RW_Warehouse.loadVouchers()`

`20964` → transfer → `RW_Warehouse.loadVoucherForm('Transfer')`

`20965` → direct-sale → `RW_Warehouse.loadVoucherForm('DirectSale')`

`20966` → direct-return → `RW_Warehouse.loadVoucherForm('DirectReturn')`

`20967` → supplier-return → `RW_Warehouse.loadVoucherForm('SupplierReturn')`

`20968` → vehicle-count → `RW_Warehouse.loadVehicleCount()`

`20969` → branch-count → `RW_Warehouse.loadBranchCount()`

`20970` → general-count → `RW_Warehouse.loadGeneralCount()`

`20971` → settlement → `RW_Warehouse.loadSettlement()`

الفحص الثابت الحالي لم يجد `قيد التطوير` أو `جاري التطوير` أو `TODO` أو `FIXME` داخل Mother.

## 4. Production — ما ثبت الآن

### Physical Stock Contract

```text
Physical Movement
      ↓
post_stock_movement
      ↓
stock_branches + inventory_log
```

`reserve_stock` و`release_stock_reservation` Reservation Engines فقط.

### Inventory capabilities الموجودة

`inventory_stock_snapshot`

`inventory_replenishment_report`

`inventory_movement_report`

`inventory_count_engine`

`inventory_stock_request_engine`

### Stock Request Control Plane

الجداول الحالية:

`inventory_stock_requests`

`inventory_stock_request_details`

والـengine يدعم:

`CREATE / GET / APPROVE / REJECT / CONVERT / CANCEL`

والـCONVERT ينشئ Stock Voucher ولا يحرك Physical Stock بنفسه.

### Gateway

تم التحقق من أن Edge capacity لا تستلزم Edge Function جديدة لهذه القدرات.

Gateway الحالي:

`save-inventory-count` — `version 4`

ويدعم:

`COUNT_*`
`REQUEST_*`
`SNAPSHOT`
`MOVEMENTS`
`REPLENISHMENT`

### Realtime

تمت إضافة:

`inventory_stock_requests`

`inventory_stock_request_details`

إلى `supabase_realtime`.

## 5. Receive Purchase — الوضع النهائي الحالي في Production

Production تحتوي:

`receive_purchase_atomic(p_company_id, p_po_code, p_user_email, p_items, p_operation_id uuid)`

والـEdge الحالي:

`receive-purchase` — `version 12`

وهو يقبل `operation_id` من Body أو `Idempotency-Key`، مع deterministic fallback.

تمت حماية الـRPC من:

- اختلاف الشركة عن المستخدم.
- المستخدم غير النشط.
- العملية بدون `operation_id`.
- Item identity غير المتسقة.
- استلام أكبر من المتبقي.
- إعادة استخدام نفس operation id مع payload مختلف.

الـPhysical receive يمر في النهاية عبر:

`post_stock_movement`.

كما تم الحفاظ على المسؤولية المحاسبية:

`Journal Entry + Journal Lines + Supplier Ledger`

داخل نفس المعاملة الذرية.

### اختبار Production transactional

تم تنفيذ اختبار:

`CREATE temporary PO → RECEIVE → RECEIVE retry بنفس operation_id → ROLLBACK`

وتم التحقق بعد الاختبار من عدم وجود:

`PO residual rows`

`Receiving residual rows`

`Movement residual rows`

والنتيجة النهائية:

`0 / 0 / 0`

أي أن الاختبار لم يلوث Production.

## 6. Manual Voucher CREATE

تم تشديد `create_manual_stock_voucher_atomic` لتصحيح Tenant Context وعدم الاعتماد على `app_settings LIMIT 1` كسياق الشركة.

تم إجراء اختبار transactional على Company ذات ثلاثة فروع باستخدام Item `1001` الموجود في Global Item Master، ثم rollback.

الاختبار نجح، ولا توجد آثار اختبارية باقية.

## 7. النتيجة الخاصة بالمقارنة مع Daftra

المصادر الحالية المنشورة من Daftra تؤكد وجود:

- Product Management
- Purchase Cycle
- Suppliers
- Requisitions
- Stocktaking
- Multi-Warehouse Stock
- Stock Movement Tracking
- Low-Stock/Replenishment
- Actual-vs-Recorded Stock Reconciliation
- Reports and snapshot views

كما توثق Daftra إظهار الكميات قبل/بعد نقل المخزون، وإجراء جرد فعلي مقابل الرصيد المسجل، وإنشاء فروقات وتعديلات عند الحاجة.

مصادر المقارنة:

https://www.daftra.com/en/inventory/

https://docs.daftra.com/en/tutorial/transferring-stock/

https://docs.daftra.com/en/tutorial/adding-a-stocktaking-sheet/

https://docs.daftra.com/en/user_manual/the-inventory-stocktaking-method-used-in-the-system-and-its-features/

الفجوة الحالية في RAWAEA ليست غياب الـbackend capability الأساسي، بل عدم اكتمال **Mother Consumer Plane** الذي يربط هذه القدرات في شاشة تحكم واحدة مع التنفيذ الميداني.

## 8. OWNER SURGICAL PATCH — PATCH-A

**السطر الحالي المثبت:** `1145`

ابحث عن السطر الكامل الذي يبدأ بـ:

```javascript
{ icon: 'fa-warehouse', label: 'إدارة المخازن والمخزون', submenu:
```

وينتهي عند آخر عنصر:

```javascript
{ view: 'general-count', label: 'الجرد العام' }
```

احذف السطر كاملًا واستبدله بالسطر الكامل التالي:

```javascript
{ icon: 'fa-warehouse', label: 'إدارة المخازن والمخزون', submenu: [{ view: 'items', label: 'الأصناف' }, { view: 'branches', label: 'المخازن والفروع' }, { view: 'inventory-control', label: 'مركز التحكم في المخزون' }, { label: 'العمليات المخزنية', icon: 'fa-timeline', submenu: [{ view: 'receiving', label: 'الاستلام' }, { view: 'picking', label: 'التحضير' }, { view: 'loading', label: 'التحميل' }, { view: 'delivery', label: 'التوصيل' }, { view: 'return', label: 'المرتجعات' }, { view: 'unloading', label: 'التفريغ' }] }, { label: 'الأذونات المخزنية', icon: 'fa-file-signature', submenu: [{ view: 'transfer', label: 'تحويل مخزني' }, { view: 'direct-sale', label: 'صرف سيارة بيع مباشر' }, { view: 'direct-return', label: 'استلام مرتجع سيارة' }, { view: 'supplier-return', label: 'مرتجع لمورد' }, { view: 'vouchers', label: 'عرض الأذونات' }] }, { label: 'الجرد', icon: 'fa-clipboard-check', submenu: [{ view: 'vehicle-count', label: 'جرد سيارة' }, { view: 'branch-count', label: 'جرد فرع' }, { view: 'general-count', label: 'جرد عام' }] }] },
```

لا تغير أي جزء من القائمة خارج هذا السطر.

## 9. OWNER SURGICAL PATCH — PATCH-B

السطر الحالي المثبت للـdispatcher هو `20932+`، ومواضع Inventory الحالية موثقة أعلاه.

ابحث عن السطر الكامل:

```javascript
if (view === 'branches') { RW_Branches.render(); return; }
```

ثم ابحث مباشرة بعده عن:

```javascript
if (view === 'settings') { RW_Settings.render(); return; }
```

أضف فوق سطر `settings` مباشرة:

```javascript
if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
```

فتصبح هذه المنطقة:

```javascript
if (view === 'branches') { RW_Branches.render(); return; }
if (view === 'inventory-control') { RW_Warehouse.loadInventoryControl(); return; }
if (view === 'settings') { RW_Settings.render(); return; }
```

## 10. Receive Purchase — Owner Patch غير المنفذ

المقطع المعروف من Consumer هو:

```javascript
return fetch(SUPABASE_URL + '/functions/v1/receive-purchase', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
    },
    body: JSON.stringify({
        po_code: poCode,
        itemsReceived: r.value,
        notes: notes
    })
});
```

لكن لم يتم إصدار رقم سطر حالي لهذا المقطع لأن استرجاع line-range من Blob الضخم أعاد محتوى فارغًا في المواضع المطلوبة، ولم يتم السماح بتحويل التاريخ القديم إلى Current Source.

**هذا الجزء لم يُغلق ولم يتم اختراع رقم سطر أو replacement غير مثبت.**

المطلوب النهائي عند استخراج الدالة الحالية هو أن تصبح هوية العملية ثابتة عبر retry، مثل:

```javascript
const receiveOperationId = /* existing stable operation state */;
return fetch(SUPABASE_URL + '/functions/v1/receive-purchase', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token,
        'Idempotency-Key': receiveOperationId
    },
    body: JSON.stringify({
        po_code: poCode,
        itemsReceived: r.value,
        notes: notes,
        operation_id: receiveOperationId
    })
});
```

لا يستخدم هذا النص كـOwner replacement نهائي قبل استخراج الـenclosing function الحالية. السبب أن `crypto.randomUUID()` يجب إنشاؤه مرة واحدة للعملية وحفظه في state العملية، لا توليده لكل retry.

## 11. الأدوات التي أُنشئت/قُويت

في `erp-frontend`:

`.github/workflows/forensic_main_assembly.yml`

وهو الآن يحرس:

`companies/company-1/main.html`

ويمنع الإشارة إلى `Current/PWA/main2` داخل Mother.

كما أنشئت:

`.github/workflows/mother_inventory_source_extract_20260916.yml`

لغرض استخراج line numbers والـenclosing functions من Mother الحالي.

## 12. Writer Closure Units التي بقيت منفصلة

لا يتم خلطها مع Receive Purchase:

### complete-return

لا يزال يحتاج Writer Closure Unit مستقلًا لأن هذا المسار كان/ما زال مرتبطًا بعمليات Physical Return ويجب إثبات مركزيته في Production على حدة.

### complete-order-delivery

يحتاج Closure Unit مستقلًا كذلك، مع مطابقة RPC/Edge/Consumer/Order Details/stock effects.

### Picking / Loading / Unloading

يجب مراجعتها على نفس التسلسل:

`Consumer → Edge → RPC → Reservation/Physical Core → Database → Audit → Realtime`

## 13. Data Integrity

وجد فحص سابق 143 صفًا من `stock_branches` في Company `da4e…` حيث لا يتطابق Company ID للصنف مع Company ID للفرع، وظهرت كميات اختبارية تقريبًا 200 في عدد كبير منها.

لكن لأن `items.item_code` فريد عالميًا، لا يجوز اعتبار ذلك فسادًا تلقائيًا ولا حذف البيانات دون إثبات أن مصدرها Fixture/Residue.

القرار الحاكم:

**لا حذف ولا إعادة توزيع لهذه البيانات بدون دليل مصدر.**

## 14. Self-Audit

### ما ثبت

- Current GIT وParent تم التحقق منهما.
- Current Mother path تم التحقق منه.
- Mother Browser Smoke = PASS.
- Console/Page errors = 0 في smoke.
- Production inventory capabilities موجودة بالفعل.
- Stock Request Engine موجود ومفصول عن Physical Movement.
- Count Engine موجود ومربوط بالقلب المركزي.
- Realtime لطلبات المخزون مفعّل.
- Receive Purchase أصبح operation-aware في Production.
- Accounting responsibilities في Receive Purchase لم تُفقد بعد الإصلاح.
- اختبارات transaction لم تترك بيانات.

### ما لم يثبت

- Full authenticated Mother E2E بعد Owner merge.
- Network proof لكل عملية Inventory في Mother.
- Exact current enclosing function لـreceive-purchase داخل Mother.
- اكتمال كل parity المطلوبة مع Daftra على مستوى UI والـreports والـexport/import.
- Final Gold/Diamond closure.

### القرار النهائي

لا يُعلن:

`GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED`

قبل إغلاق Consumer Integration والـseparate Writer Closure Units والـauthenticated Browser/Network verification.

## 15. تعليمات البدء للمساعد التالي

ابدأ من:

`CURRENT GIT HEAD → parent → current Mother → current blob → current Production snapshot → current deployments → current database → current browser/network`

ثم:

`افتح RW_Warehouse الحالية كاملة`

ثم اربط كل Inventory view بقدرة Production المنشورة فعليًا.

ثم نفذ **Writer Closure Unit واحدة فقط في كل مرة**.

ثم لمالك Mother أعطِ:

`رقم السطر الحالي + أول سطر كامل + آخر سطر كامل + كتلة الحذف كاملة + كتلة الاستبدال كاملة`

ولا تستخدم أي تقرير تاريخي للحصول على رقم سطر.

بعد Owner merge:

`Re-read current Git/blob → Browser → Console → Network → DB → Realtime`

ثم حدث:

`CURRENT_STATE.md`

وأضف تقريرًا جديدًا إلى:

`doc/Draft/Reprots`

ولا تحذف أي تقرير سابق.
