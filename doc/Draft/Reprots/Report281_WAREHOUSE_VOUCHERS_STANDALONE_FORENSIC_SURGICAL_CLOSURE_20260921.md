# تقرير 281 — الإغلاق الجنائي لتكامل تطبيق الأذونات المخزنية
## RAWAEA ERP — Standalone Warehouse Vouchers / Production + Source Closure
**التاريخ:** 2026-09-21  
**النطاق:** `companies/company-1/warehouse/vouchers.html` فقط كمصدر واجهة، وProduction Supabase للـCore اللازم.  
**قيود هذه الجلسة:** لم يتم تعديل `main.html`، ولم يتم تعديل `erp-frontend/companies/company-1/warehouse/vouchers.html` مباشرة.  
**Edge Functions جديدة:** لا يوجد.  
**حالة الإغلاق:** Production Core مغلق للخلل المكتشف؛ Source patch جاهز للمالك؛ Browser E2E الواقعي الكامل ما زال غير ممكن لأن Production الحالية لا تحتوي أي مركبة نشطة.

---

# 1. قاعدة الحقيقة المستخدمة

لم تُعامل التقارير السابقة كحالة حالية. تم تثبيت الحالة من:

1. CURRENT GIT.
2. CURRENT SOURCE.
3. CURRENT PRODUCTION.
4. CURRENT DATABASE.
5. CURRENT DEPLOYMENT.

## System Repository

`papamohammed77-glitch/rawaie-erp-New`

قبل بداية تعديلات التوثيق:
- HEAD: `31f22601f8db94864d46d17735338bbd92d09a77`
- Parent: `4eaa290043bc527e6299fb7f1292806c3da09200`
- HEAD message: `state: record standalone vouchers summary regression forensic closure`

## Frontend Repository

`papamohammed77-glitch/erp-frontend`

Current branch `main`:
- HEAD: `71436e0e60787ad66d643b923e9b6a3e017eb498`
- HEAD message: `Refactor search function for improved performance`
- Parent: `a2de64c150c9e38f14af0c2ecafcbcd9861fa9cd`
- Earlier parent in this lineage: `f2229bec9106f1c4836769b1eccda3cc48d4a482`

Current standalone source:
- File: `companies/company-1/warehouse/vouchers.html`
- Blob SHA: `1d37820b58763a3a54a6123cfe378d9e69f0d22d`
- Size: 73,481 bytes
- Lines: 915

The `f2229…` parent version of the same standalone file was also read completely:
- Blob SHA: `887e9cbe85774c3702219a9030c3a6ed7a759bc4`
- Size: 70,099 bytes
- Lines: 740

---

# 2. التقارير التي تم فتحها

تمت قراءة واستخدام التقارير كأدلة تاريخية فقط:

- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- Report 277
- Report 278
- Report 279
- Report 280
- `CURRENT_STATE.md`
- `Architecture/الأذونات المخزنية اليدوية.md`
- النسخة القديمة `PWA/warehouse/vouchers.html`

والقاعدة التي تم الالتزام بها:
**لا يتم إعلان إصلاح أو نسبة أو Closure من التقرير؛ التقرير يفسر التاريخ فقط، بينما الحقيقة تُثبت من Source + Production.**

---

# 3. الدور الوظيفي المثبت لتطبيق الأذونات المخزنية

التطبيق ليس بديلًا عن مسار:

- Orders
- Runsheets
- Picking
- Loading
- Delivery

بل هو طبقة العمليات المخزنية اليدوية التي لا تحتاج إلى Order أو Runsheet.

العقد التاريخي يثبت أن المجال يشمل:

- `Transfer`
- `DirectSale`
- `DirectReturn`
- `SupplierReturn`
- وكان تاريخيًا يذكر أيضًا `Scrap` و`Adjustment`، بينما التصميم الحالي يفصل هذه الأخيرة داخل Inventory Engine.

القرار المعماري الذي تم الحفاظ عليه:

**Create / Draft**  
ثم  
**Send / Execute**  
ثم عند الحاجة  
**Receive**  
ثم  
**Complete**

وهذا ليس مجرد شكل واجهة؛ هو فصل بين قرار الحركة وتنفيذ الحركة، مع حماية من التلاعب وإمكانية التسجيل والمراجعة.

---

# 4. لماذا لا يجوز إعادة بناء التطبيق من الصفر

Current Source يثبت وجود وظائف سبق بناؤها وإغلاقها بالفعل:

- live company scoping
- current branch/vehicle/rep/supplier references
- separate voucher serial `voucher_code`
- mandatory human reference `reference`
- operation identity for CREATE
- operation identity for RECEIVE
- inventory before/after
- stock visibility
- smart filtering
- searchable item catalog
- barcode/scanner
- voucher detail/audit/movement view
- inventory-control read capability
- Scrap/Adjustment engine path
- current workflow state mapping
- live refresh hooks
- source/target authorization guards

لذلك لم تتم إعادة بناء أي من هذه العناصر.

---

# 5. فصل رقم الإذن عن المرجع — مثبت ومغلق

المطلوب الذي كان يشتبه في فقدانه:

> رقم سيريال مستقل عن رقم المستند المرجعي.

المثبت حاليًا:

- `voucher_code` = رقم الإذن النظامي.
- `reference` = المرجع البشري/المستندي.
- الـRPC الحالي يولد `voucher_code` مستقلًا تحت advisory lock.
- `reference` أصبح إجباريًا.

إذن هذه النقطة **مبنية بالفعل ولا تحتاج تعديلًا**.

لا تضف Serial جديدًا إلى `vouchers.html`.

---

# 6. السبب المباشر للخطأ الحالي في الواجهة

## FOUND

Current Source يحتوي call-sites التالية:

`App.send(voucher_code)`  
`App.cancel(voucher_code)`  
`App.receive(voucher_code)`  
`App.complete(voucher_code)`

لكن داخل كائن `App`:

- `receive` موجودة.
- `send` غير موجودة.
- `cancel` غير موجودة.
- `complete` غير موجودة.

## إثبات زمني

النسخة الأصلية عند parent `f2229bec9106f1c4836769b1eccda3cc48d4a482` كانت تحتوي بالفعل على:

- call-sites لـ `send`
- call-sites لـ `cancel`
- call-sites لـ `complete`

من دون implementations مطابقة لها.

وفي المقابل كانت `summary` موجودة.

إذن:

**المشكلة ليست فقدان `summary` في Current HEAD.**

ولا يجوز إعادة تطبيق إصلاح Report 280 الخاص بـ`summary`.

## ROOT CAUSE

**UI action contract drift**

تم إنشاء الأزرار/الأحداث التي تعتمد على `App.send / App.cancel / App.complete`، بينما لم يبقَ داخل object implementation لهذه methods.

وبالتالي الضغط على الزر ينتهي إلى undefined function بدل capability call.

---

# 7. التعديل الجراحي المطلوب في المصدر

## الملف المطلوب تعديله

`erp-frontend/companies/company-1/warehouse/vouchers.html`

**لا تعدل أي ملف آخر.**

## ابحث عن العنصر التالي بالاسم الدقيق

داخل كائن `App`:

`callAction:function(name,code,successText){`

ومع نهاية هذا العنصر مباشرة قبل:

`receive:function(code){`

## احذف العنصر كاملًا

احذف فقط الدالة:

`callAction:function(name,code,successText){ ... }`

الموجودة حاليًا عند حدود الأسطر التقريبية 410–453.

## واستبدلها بالكامل بالنص التالي

~~~javascript
callAction:function(name,code,successText){
    var s=this;
    var busyKey=name+':'+code;

    if(this.busy[busyKey])return;

    this.busy[busyKey]=true;

    RW_UI.showLoader();

    RW_API.call(
        name,
        {voucher_code:code},
        function(j){

            RW_UI.hideLoader();

            delete s.busy[busyKey];

            if(j&&j.success){

                RW_UI.toast(
                    j.duplicate
                        ?'تم التعرف على العملية السابقة'
                        :successText,
                    'success'
                );

                s.markSync();

                s.loadList(s.tabName);

                s.prefetchStock(true);

            }else{

                RW_UI.showError(
                    (j&&j.msg)||
                    'فشل التنفيذ'
                );
            }
        }
    );
},

send:function(code){
    this.callAction(
        'send-stock-voucher',
        code,
        'تم إرسال الإذن'
    );
},

cancel:function(code){
    this.callAction(
        'cancel-stock-voucher',
        code,
        'تم إلغاء الإذن'
    );
},

complete:function(code){
    this.callAction(
        'complete-stock-voucher',
        code,
        'تم إكمال الإذن'
    );
},
~~~

## ممنوع تعديل

لا تعدل:

`receive:function(code){ ... }`

ولا `summary:function...`

ولا `updateSource...`

ولا `submit...`

ولا `loadList...`

ولا `cards...`

في هذه الجلسة.

---

# 8. تحقق Static بعد تطبيق الـpatch

تم تنفيذ الـpatch في الذاكرة فقط للتحقق، دون كتابته إلى repository.

نتائج الاختبار:

- `summary:function` = موجودة بالفعل.
- `send:function` = بعد patch تصبح 1.
- `cancel:function` = بعد patch تصبح 1.
- `complete:function` = بعد patch تصبح 1.
- undefined `App.*` calls = **0**.
- Embedded JavaScript parse = **PASS**.
- `receive` block لم يتغير.
- لم يعد هناك call-site لـ`App.send/cancel/complete` بدون implementation.

إذن الـpatch الجراحي يغلق العيب الذي تم إثباته، ولا يعيد أي إصلاح سابق.

---

# 9. Production — الفجوة الحقيقية التي تم العثور عليها

## FOUND

Historical contract:
`DirectSale` =

**Branch / MAIN → Vehicle Mobile Stock**

لكن Production `post_stock_movement` قبل الإغلاق كانت تنفذ:

`DirectSale` = source decrease only

لأنها كانت تضع `DirectSale` داخل مجموعة:

`TransferOut / POSSale / VanSale / SupplierReturn / InventoryDecrease`

وبالتالي لم تكن تستخدم `p_target_branch_id` لإنشاء/زيادة stock target.

وفي الوقت نفسه كان:

`send_stock_voucher_atomic_core_20260828`

يحسب destination vehicle branch، ويرسل target إلى `post_stock_movement`.

النتيجة:

**الـcaller كان يملك destination، لكن الـphysical writer كان يتجاهله.**

وهذه هي الفجوة التي كانت ستجعل DirectSale يخصم من MAIN دون نقل البضاعة فعليًا إلى مخزن المركبة.

---

# 10. لماذا هذا ليس اختراعًا جديدًا

سجل Production migration history يثبت أن هناك إصلاحًا سابقًا باسم:

`20260820183912 — 20260820_fix_direct_sale_voucher_target_stock`

ثم جاءت سلسلة تعديلات لاحقة على `post_stock_movement` في 28 أغسطس.

Current Production definition في لحظة هذه الجلسة لم يعد يحتفظ بالسلوك المطلوب.

إذن ما تم هنا ليس “اختراع وظيفة جديدة”، بل:

**إعادة إغلاق Contract سابق ثبت أنه تراجع أثناء إعادة بناء الـCore.**

---

# 11. Production Fix الذي تم تنفيذه

تم تطبيق migration مباشر على Production:

### Migration 1
`20260921083201`
`20260921_voucher_directsale_vehicle_stock_central_closure`

النتيجة:

1. `DirectSale` يتطلب target vehicle stock branch.
2. target stock row يتم إنشاؤه عند الحاجة.
3. physical mutation تصبح:
   - source qty ↓
   - target vehicle qty ↑
4. يسجل `inventory_log` واحدًا من نوع `DirectSale`.
5. ما زال Physical Writer الوحيد هو `post_stock_movement`.
6. لا يتم إنشاء Edge Function جديدة.

### Migration 2
`20260921083432`
`20260921_restrict_post_stock_movement_execute_surface`

تم به إلغاء تنفيذ الـphysical writer من:

- PUBLIC
- anon
- authenticated

والإبقاء على:

- service_role

حتى لا يتحول الإصلاح نفسه إلى توسيع غير مقصود لسطح الكتابة.

---

# 12. حماية علاقة المركبة بالمخزن

Current Production Schema يحتوي:

`vehicles.mobile_branch_id`

بالإضافة إلى:

`mobile_stock_enabled`

ويوجد Trigger:

`fn_vehicle_context_guard()`

يثبت أن:

`mobile_branch_id`

يجب أن يتطابق مع:

`VAN-<vehicle_code>`

لذلك تم اعتماد:

1. `mobile_branch_id` canonical أولًا.
2. legacy `VAN-<vehicle_code>` fallback فقط عند الحاجة.
3. company scope.
4. active branch.
5. active vehicle.
6. mobile stock enabled.

لم يتم تجاوز الـTrigger.

---

# 13. Production Test — DirectSale

تم الاختبار داخل Transaction مؤقتة بالكامل ثم Rollback.

Scenario:

- Existing company.
- Existing MAIN branch.
- Existing active item `1001`.
- Source stock = 2.
- Temporary vehicle branch.
- Temporary DirectSale voucher.
- Temporary detail quantity = 1.
- User = warehouse manager.

Expected:

MAIN:
`2 → 1`

Vehicle mobile branch:
`0 → 1`

Inventory log:
`1 DirectSale`

Observed:

- Source stock decreased by exactly 1.
- Vehicle target stock increased by exactly 1.
- Exactly one DirectSale inventory movement recorded.
- Transaction rollback completed.
- Persistent `stock_vouchers` remained 0.
- Persistent `stock_voucher_details` remained 0.
- Persistent `inventory_log` remained 3.
- Temporary vehicle residue = 0.

**Production DirectSale central movement test = PASS.**

---

# 14. DirectReturn — لا تعدّل ما تم إثباته

Current workflow له تصميم مرحلي:

### SEND
Vehicle stock:
`qty ↓`

Movement:
`InventoryDecrease`

State:
`Draft → Sent`

### RECEIVE
Branch stock:
`qty ↑`

Movement:
`DirectReturn`

State:
`Sent → Received`

### COMPLETE
`Received → Completed`

اختبار RPC-only أظهر أن:

`post_stock_movement('DirectReturn')`

هو **Inbound/target movement** وليس source-out.

وهذا متسق مع كون SEND في `send_stock_voucher_atomic_core_20260828` يستخدم `InventoryDecrease` لخصم المركبة أولًا.

لذلك:

**لم يتم تغيير DirectReturn.**

أي تعديل عليه الآن سيكون إعادة بناء شيء أثبتت الـProduction الحالية أن له عقدًا مرحليًا مختلفًا.

---

# 15. create-stock-voucher — لا يوجد خلل يحتاج إعادة بناء

Current deployed `create-stock-voucher`:

- authenticates user.
- extracts `company_id` from `users.auth_id`.
- normalizes items.
- accepts `rep_id`.
- accepts `operation_id`.
- calls `create_manual_stock_voucher_atomic`.

إذن المسار الحالي بالفعل:

UI
→ existing Edge capability
→ canonical create RPC
→ operation identity
→ stock voucher

ولا يجب إعادة بنائه.

---

# 16. Audit

Production trigger:

`trg_audit_stock_vouchers`

يغطي:

- INSERT
- UPDATE
- DELETE

ويستدعي:

`fn_audit_trigger()`

الـaudit actor يستخدم JWT email، مع fallback `system`.

والـInventory Control الحالي يقرأ:

- voucher
- details
- audit
- physical movements

من capability واحدة company-scoped.

لم يتم إنشاء audit engine جديد.

---

# 17. البيانات الحالية

Production snapshot بعد الإغلاق:

- Active companies: 1
- Active branches: 2
- Active items: 16
- Vehicles: 0
- Stock vouchers: 0
- Stock voucher details: 0
- Inventory log: 3
- Audit log: 2023
- ERP operation registry: 5
- Stock voucher operations: 0

**لا توجد بيانات Voucher تشغيلية حالية يجب إصلاحها.**

وجود 0 مركبات يعني أن Browser E2E الواقعي لمسار DirectSale لا يمكن إثباته على entity تشغيلية موجودة دون اختلاق بيانات دائمة، وهو أمر مرفوض.

---

# 18. مقارنة تنافسية

## Odoo

يوثق Odoo أن معظم عمليات المخزون تولد Stock Moves من Source Location إلى Destination Location، وأن Customer Returns تزيد المخزون، Deliveries/Vendor Returns/Scrap تنقصه، بينما Inventory Adjustments لها semantics مستقلة. كما يدعم Serial/Lot Traceability لتتبع الموقع والتاريخ والرقم الفريد.

المصادر الرسمية:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/product_tracking/serial_numbers.html

## Microsoft Dynamics 365

يدعم Inventory Journals لأنواع Movement وAdjustment وTransfer وCounting وItem Arrival، وتحدد حركة النقل Source/To inventory dimensions. Transfer Journal في النقل الفوري يغير On-hand في المصدر والوجهة، بينما Transfer Order يوفر مفهوم In-Transit.

المصادر الرسمية:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
- https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations

## SAP

SAP يفرق بين stock transfer المباشر وبين stock in transfer / stock in transit، ويعرض صراحة مفهوم النقل بخطوتين، مع Goods Issue ثم Goods Receipt، كما أن كمية المخزون مرتبطة بـPlant/Storage Location/Stock Type.

المصادر الرسمية:
- https://help.sap.com/docs/SAP_ERP_SPV/96bf9ad642cf4b26a29595e3d573fb8c/a464bd534f22b44ce10000000a174cb4.html
- https://help.sap.com/docs/SAP_S4HANA_CLOUD/0864cb07010642b3bde45a20de4975bc/557a1702cb9d46559cfddda3e45d078e.html

## دفترة

دليل دفترة يوضح نقل المخزون بين المستودعات، ويعرض:
- From Warehouse
- To Warehouse
- Quantity
- Available/Stock Before
- Available/Stock After
- Notes
- Transfer details

كما يدعم أنواع Tracking مثل Serial Number وExpiry Date.

المصادر:
- https://docs.daftra.com/en/tutorial/transferring-stock/
- https://docs.daftra.com/en/tutorial/transaction-addition/
- https://docs.daftra.com/en/user_manual/stock-inbound-outbound-requisition/

## Manager.io

Manager يدعم Inventory Locations وInventory Transfers ويجعل Location جزءًا من حركة المخزون، مع تحديث الكميات بحسب net result للحركات في المواقع المختلفة.

المصادر:
- https://www2.manager.io/guides/10677
- https://www2.manager.io/guides/10707

---

# 19. فجوات المنافسة التي لم تُخترع ولم تُفتح دون عقد

المزايا التالية مهمة تنافسيًا، لكن لا يجوز إدخالها داخل هذا Closure دون Business Contract مستقل مثبت:

1. Serial Number / Lot / Expiry traceability.
2. Attachment/document management داخل voucher.
3. Cost/currency/total-value display كنظام مالي متكامل.
4. In-transit stock model مستقل إذا أصبح مطلوبًا كحالة تشغيلية.
5. Advanced warehouse location/bin semantics.
6. Full structured warehouse workflow history للمستندات ذات الخطوتين.
7. Native adjustment/scrap voucher document lifecycle مستقل إذا قرر المعمار المستقبلي دمجهما في نفس شاشة vouchers.

هذه **ليست defects مثبتة في Current Source**، ولذلك لم يتم اختراع إصلاحات لها داخل هذه الجلسة.

---

# 20. العلاقة مع Van Sales

التحقيق أثبت فرقًا حقيقيًا يحتاج Closure منفصل:

### vouchers
يعمل مع vehicle mobile stock على أساس vehicle/mobile branch.

### van-sales
Current source يبني Van Branch من:

`VAN-<user.email>`

كما ينشئ/يهيئ فرع السيارة عبر مسار مستقل.

وفي نفس الوقت vehicles تحتوي:

`mobile_branch_id`

وهذا يمثل وجود أكثر من contract لتسمية وربط Mobile Stock.

هذه ليست نقطة تُصلح داخل `vouchers.html` فقط دون كسر أثر التطبيقات الأخرى.

لذلك تم تسجيلها كـ:

**OPEN CROSS-APP CONTRACT — VEHICLE MOBILE BRANCH IDENTITY**

وليس كـbug تخميني يجب ترقيعه داخل صفحة واحدة.

---

# 21. لماذا لم يتم تعديل main.html

لأن المطلوب هنا Standalone Voucher Closure.

كما أن Current Mother logic لم يكن مطلوبًا تغييره، ولا توجد نتيجة جديدة تثبت regression في `main.html` مرتبطة بالخلل الحالي.

لذلك:

`main.html` = NOT TOUCHED.

---

# 22. لماذا لم يتم تعديل vouchers.html بواسطة الجلسة

لأن أمر هذه الجلسة نص صراحة على:

- لا تلمس ملف تطبيق الأذونات المخزنية.
- أعط التعديل الجراحي الجاهز فقط.
- المالك/المستخدم يطبق تعديل الملف.

لذلك:

**Source write = NOT EXECUTED BY SESSION**

لكن التعديل تم اختباره في الذاكرة وأصبح جاهزًا حرفيًا للاستبدال.

---

# 23. Current Source Integrity

بعد التحقق من Current Source:

- `summary` موجودة.
- `updateSource` موجودة.
- CREATE idempotency موجودة.
- RECEIVE idempotency موجودة.
- stock before/after موجودة.
- search/filter موجودة.
- details/audit/movements موجودة.
- company scope موجود.
- direct DML على Physical Stock داخل صفحة vouchers = غير موجود.
- physical writes تمر عبر capability/backend.
- missing methods الوحيدة المكتشفة = send/cancel/complete.

---

# 24. GLOBAL INVENTORY WRITER MATRIX — Voucher Closure

| Writer / Capability | Production | Physical Stock | Centralized? | Current Source | الحالة |
|---|---|---:|---:|---|---|
| `post_stock_movement` | deployed | نعم | نعم | backend | مغلق |
| `send_stock_voucher_atomic` | deployed | نعم عبر core | نعم | Edge capability | مغلق |
| `post_manual_stock_voucher_atomic` | deployed | نعم عبر core | نعم | Edge capability | مغلق |
| `create_manual_stock_voucher_atomic` | deployed | لا مباشرة | نعم | Edge capability | مغلق |
| `receive-stock-voucher` | deployed | نعم عبر manual core | نعم | موجود | مغلق من ناحية Central Writer |
| `complete-stock-voucher` | deployed | لا | نعم | UI call-site يحتاج wrapper | Source patch |
| `cancel-stock-voucher` | deployed | لا | نعم | UI call-site يحتاج wrapper | Source patch |
| `send-stock-voucher` | deployed | نعم عبر core | نعم | UI call-site يحتاج wrapper | Source patch |
| Legacy v2 send | deployed history | central writer historically | نعم | Legacy | غير تشغيلي حسب grants/history |
| Legacy v2 receive | retired/blocked history | central writer historically | نعم | Legacy | غير تشغيلي حسب grants/history |

---

# 25. أهم نتيجة

داخل مجال Physical Stock:

**لا يوجد Writer جديد تم اختراعه.**

العمود الفقري الحالي:

PHYSICAL STOCK  
↓  
`post_stock_movement`  
↓  
`stock_branches`  
+  
`inventory_log`

و`DirectSale` أصبح فعليًا:

BRANCH  
↓  
CENTRAL STOCK WRITER  
↓  
VEHICLE MOBILE STOCK BRANCH

وهذا الآن متوافق مع الغرض التشغيلي التاريخي.

---

# 26. Self-Audit

## What I Proved

- Current frontend HEAD.
- Parent lineage.
- Current standalone blob.
- Parent standalone blob.
- Current missing UI methods.
- Existing summary is already restored.
- Current voucher creation RPC path.
- Current Edge deployment versions.
- Current physical writer.
- Current DirectSale bug.
- Current vehicle schema.
- Current vehicle guard.
- DirectSale Production transactional movement.
- Rollback/no residue.
- Post-writer execute privilege restriction.
- Current Production counts.
- Current audit trigger path.
- Current DirectReturn two-stage semantics.

## What I Did Not Prove

- Browser E2E على مركبة تشغيلية حقيقية، لأن Production تحتوي 0 vehicles.
- تكامل live end-to-end بين vouchers وvan-sales على vehicle فعلي.
- Full real-world serial/lot traceability contract، لأنه غير موجود كـcurrent vouchers contract.
- Full browser visual regression بعد patch، لأن source file لم يُكتب في هذه الجلسة.

## What I Fixed

Production:
- DirectSale target stock mutation.
- Vehicle target resolution.
- Target stock initialization.
- Physical writer execute surface.

Source:
- جهزت patch جراحيًا يعيد implementations المفقودة:
  - send
  - cancel
  - complete

## What I Initially Missed During This Session

ظهر أثناء مراجعة الـmigration security أن granting `authenticated` مباشرة على Physical Writer أوسع من العقد المطلوب؛ تم إغلاق ذلك فورًا في migration التالية قبل إنهاء الجلسة.

## What Could Still Be Wrong

- Browser-only UI behavior بعد owner patch.
- Vehicle mobile branch identity cross-app.
- Future Contract gap حول Serial/Lot/Expiry.
- أي regression خارج نطاق vouchers يجب أن يثبت من runtime evidence مستقل.

## Final Confidence

**Production DirectSale Core: HIGH / VERIFIED**

**Standalone Source surgical fix: HIGH / STATICALLY VERIFIED / OWNER PATCH REQUIRED**

**Full Browser Closure: OPEN**

**Full Cross-App Vehicle Closure: OPEN**

---

# 27. الحالة التي تبدأ منها الجلسة التالية

لا تبدأ من الصفر.

ابدأ بهذا الترتيب:

1. Fetch current `erp-frontend/main`.
2. Re-fetch `companies/company-1/warehouse/vouchers.html` SHA.
3. تأكد أن patch `send/cancel/complete` طُبق.
4. لا تعيد إصلاح `summary`.
5. لا تعيد إصلاح CREATE idempotency.
6. لا تعيد إصلاح stock before/after.
7. لا تعيد إصلاح filtering/list-window.
8. Validate embedded JS parse.
9. نفّذ Browser E2E عندما تصبح هناك مركبة تشغيلية حقيقية.
10. اختبر:
   - Transfer
   - DirectSale
   - DirectReturn
   - SupplierReturn
11. تحقق من Mother Voucher history عبر `inventory_control(VOUCHER_AUDIT)`.
12. تحقق من:
   - stock_branches
   - inventory_log
   - audit_log
   - voucher state
13. ثم افتح Closure منفصل لعقد Mobile Branch Identity بين:
   - vehicles.mobile_branch_id
   - vouchers
   - van-sales
14. لا تعلن 100% إلا عند اتفاق:
   SOURCE + PRODUCTION + DEPLOYMENT + BROWSER EVIDENCE

---

# 28. Final Closure Status

### PRODUCTION
**DirectSale Central Stock Contract = CLOSED**

### UI SOURCE
**send/cancel/complete wrapper gap = FIX READY / OWNER PATCH REQUIRED**

### DATABASE
**No voucher data repair required**

### EDGE
**No new Edge Function required**

### SECURITY
**Physical Writer direct authenticated execution = CLOSED**

### FULL STANDALONE VOUCHER APP
**NOT 100% CLOSED YET**

السبب الوحيد المتبقي داخل هذه الوحدة هو تطبيق patch المصدر ثم Browser E2E الفعلي.

---

## END REPORT 281
