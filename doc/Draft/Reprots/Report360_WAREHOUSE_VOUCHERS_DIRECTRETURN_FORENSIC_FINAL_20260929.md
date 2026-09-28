# Report360 — التحقيق الجنائي النهائي واستكمال عقد Master Assignment في تطبيق الأذونات المخزنية
**التاريخ:** 2026-09-29  
**النطاق:** RAWAEA ERP / Stock Vouchers / DirectReturn Master Assignment  
**المرجع السابق:** Report359_WAREHOUSE_VOUCHERS_DIRECTRETURN_MASTER_ASSIGNMENT_FORENSIC_CLOSURE_20260928.md

---

## 1. قاعدة الاستكمال

هذه الجلسة بدأت من آخر حالة مثبتة، ولم تُعامل التقارير السابقة كحالة حالية.

ترتيب مصادر الحقيقة المستخدم:

1. CURRENT GIT
2. CURRENT SOURCE
3. CURRENT PRODUCTION
4. CURRENT DATABASE
5. CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت فقط لفهم التاريخ والعقد والغرض من التعديلات.

الملفان المحميان في هذه الجلسة:
- `Current/PWA/main.html`
- `companies/company-1/warehouse/vouchers.html`

لم يتم تعديل أي منهما.

`van-sales.html` تمت مراجعته ولم يتم تعديله.

---

# 2. CURRENT GIT — إثبات آخر نقطة

## 2.1 النظام الأم

**Repository:** `papamohammed77-glitch/rawaie-erp-New`

HEAD قبل توثيق هذه الجلسة:

`817aa8851e9fdd837ad11e994d2ce09c87acef1c`

الرسالة:

`state: checkpoint Report359 forensic continuation`

Parent:

`e5d0a760bc60345458ad6a261a9094072d48133d`

هذا يثبت أن آخر نقطة معتمدة قبل هذه الجلسة كانت Checkpoint تقرير 359.

## 2.2 التطبيق التشغيلي

**Repository:** `papamohammed77-glitch/erp-frontend`

HEAD الحالي:

`386b003ccd1650444062844394a7ec6ac2f7032f`

Parent:

`56fee06ac0145faffbc4f71d3d6031fcd3b46f87`

Commit message:

`Update vouchers.html`

هذا الـCommit هو الذي حاول فيه المالك تنفيذ الترقيعات السابقة جزئيًا.

## 2.3 ملف الأذونات الحالي

`companies/company-1/warehouse/vouchers.html`

Blob:

`9b538a49b9ee520aaa17a097fe881167a9230abf`

عدد الأسطر:

**6599**

## 2.4 النظام الأم

`Current/PWA/main.html`

Blob:

`27b777528665dcc985809648f006452c861ae36e`

لم يتغير.

## 2.5 تطبيق مندوب البيع المباشر

`companies/company-1/sales/van-sales.html`

Blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

لم يتغير.

---

# 3. التاريخ الحقيقي للتعديل

الـCommit التاريخي:

`826cfb658f7a35d9e55bb00b7653d447c047a1cf`

الرسالة:

`Refactor wsRep handling in vouchers.html`

هذا التعديل هو الذي نقل DirectReturn من افتراض:

`Vehicle.driver_id -> Rep`

إلى العقد الصحيح:

`Master Assignment -> Vehicle -> Rep`

مع الإبقاء على:

`vehicles.driver_id`

كـlegacy fallback للتوافق مع البيانات القديمة.

هذا البناء ليس خطأ تصميميًا.

السبب الوظيفي:
- المركبات في Production أصبح تعيينها الرسمي عبر `fleet_vehicle_sales_rep_assignments`.
- `driver_id` أصبح فارغًا في المركبات الحديثة.
- التطبيقات التشغيلية تحتاج Source of Truth موحدًا لا حقلًا قديمًا قد لا يحمل التعيين الحالي.

---

# 4. لماذا لا يجوز إعادة بناء DirectReturn

العقد الحالي:

**Master Assignment**
↓
**Vehicle**
↓
**Sales Rep**
↓
**Mobile Branch**

وهو العقد الذي يستهلكه:
- الأذونات المخزنية
- البيع المباشر
- مخزون المركبة
- العهدة
- العمليات الخلفية
- التحقق الأمني

ولا يجوز تحويله إلى:

**Vehicle.driver_id**

لأن Production الحالي يثبت أن `driver_id = NULL` في المركبات الفعلية.

---

# 5. CURRENT PRODUCTION — إثبات العقد

الشركة:

`00000000-0000-0000-0000-000000000001`

## 5.1 المركبة CHV-2025-01

Vehicle:

`69b08188-60ee-43af-9644-e1626a85bfa0`

الحالة:
- Active
- mobile_stock_enabled = true
- driver_id = NULL
- mobile_branch_id = `2fffcf58-be04-4599-a289-8791362398ff`

Master Assignment:

`sales_rep_user_id = 111b0730-a977-4d11-bcd0-2427b178a9e5`

المندوب:

`vansales@rawaea.com`

Primary = true

## 5.2 المركبة VHL-0422

Vehicle:

`7e58a39d-e1f4-435f-a6f7-fa625a234333`

الحالة:
- Active
- mobile_stock_enabled = true
- driver_id = NULL
- mobile_branch_id = `9a8a10b5-8d46-4e64-a33f-5ab46af542ac`

Master Assignment:

`sales_rep_user_id = cb086d71-ba61-4392-8d3d-c4bec02ec913`

المندوب:

`vansales2@rawaea.com`

Primary = true

إذن:

**VHL-0422 لا يمكن حلها بشكل صحيح من `driver_id`.**

الحل الصحيح هو `vehicleRepMap`.

---

# 6. CURRENT SOURCE — ماذا نفذ المالك بالفعل؟

الـCommit `386b...` ليس فاشلًا بالكامل.

تم تنفيذ أجزاء صحيحة:

## تم تنفيذه صحيحًا

### DR-UI-03A
في `pickSearch:function(key,q)`

الـvehicleRep أصبح يعتمد على:

`vehicleRepMap -> driver_id fallback`

وهذا صحيح.

### routeHtml
في `routeHtml:function()`

DirectReturn أصبح:

`المركبة المصدر + المندوب + الفرع الوجهة`

بدون readonly إجباري في تعريف الحقل.

هذا صحيح ولا يجب تعديله.

### submit
منطق الإرسال الحالي أصبح:
- يقرأ Master Assignment.
- يقارن المندوب بالمركبة.
- يستخدم `driver_id` فقط كـfallback.
- يرفض mismatch.

هذا جزء مغلق ولا يعاد إصلاحه.

---

# 7. CURRENT SOURCE — العيوب المكتشفة

تم اكتشاف **أربعة مواضع فقط**.

---

## العيب 1 — DR-UI-01

**الدالة:**
`pickArr:function(key)`

**الموضع الحالي التقريبي:** السطر 3491–3515.

الجزء الذي تم إدخاله حاليًا يستخدم:

`String(v.id)`

قبل دخول `v` إلى نطاق:

`filter(function(v){...})`

وهذا خطأ Scope.

النتيجة المحتملة عند تنفيذ الفرع:

**ReferenceError / Runtime failure**

### التعديل الجراحي

ابحث داخل:

`pickArr:function(key)`

عن هذا العنصر كاملًا واحذفه:

```javascript
var currentUserId= String( (s.user||{}).id|| '' );

var vehicleRepMap= s.refs.vehicleRepMap|| Object.create(null);
              var linkedRepId=
    vehicleRepMap[
        String(v.id)
    ]||
    v.driver_id||
    '';

                return (
                    s.refs.vehicles||[]
                )
                .filter(function(v){

                    return (
                        v.status==='Active' &&
                        v.mobile_stock_enabled!==false &&
                        String(linkedRepId)===
                            currentUserId &&
                        !!s.vehicleBranch(v)
                    );
                });
```

### استبدله بالكامل بهذا العنصر

```javascript
var currentUserId=
    String(
        (s.user||{}).id||
        ''
    );

var vehicleRepMap=
    s.refs.vehicleRepMap||
    Object.create(null);

return (
    s.refs.vehicles||[]
)
.filter(function(v){

    var linkedRepId=
        vehicleRepMap[
            String(v.id)
        ]||
        v.driver_id||
        '';

    return (
        v.status==='Active' &&
        v.mobile_stock_enabled!==false &&
        String(linkedRepId)===
            currentUserId &&
        !!s.vehicleBranch(v)
    );
});
```

**لا تحذف `pickArr` بالكامل.**

---

# 8. العيب 2 — DR-UI-02

**الدالة:**
`pickSelect:function(key,id)`

**الموضع الحالي التقريبي:** السطر 4260–4285.

الـCommit الحالي أدخل:

`mappedVehicle = ...`

داخل شرط `if` بطريقة معيبة.

النتيجة الفعلية التي ثبتت باختبار Syntax:

**SyntaxError: Invalid left-hand side in assignment**

إذن الملف الحالي نفسه لا يمر بوابة Syntax JavaScript.

### التعديل الجراحي

ابحث داخل:

`if (s.type==='DirectReturn')`

عن هذا العنصر كاملًا:

```javascript
if(
            !mappedVehicle ||
          mappedVehicle=
    (s.refs.vehicles||[])
        .find(function(v){

            return (
                String(
                    v.driver_id||
                    ''
                )===
                String(x.id) &&

                v.status==='Active' &&
                v.mobile_stock_enabled!==false &&
                !!s.vehicleBranch(v)
            );
        })||
    null;
      }
```

### استبدله بالكامل بهذا العنصر

```javascript
if(!mappedVehicle){

    mappedVehicle=
        (s.refs.vehicles||[])
            .find(function(v){

                return (
                    String(
                        v.driver_id||
                        ''
                    )===
                    String(x.id) &&

                    v.status==='Active' &&
                    v.mobile_stock_enabled!==false &&
                    !!s.vehicleBranch(v)
                );
            })||
        null;
}
```

هذا يبقي:
- Master Assignment أولًا.
- Legacy fallback ثانيًا.
- نفس شروط Active/Mobile/Branch.

---

# 9. العيب 3 — DR-UI-03B

**الدالة:**
`pickSearch:function(key,q)`

هناك موضعان في الدالة.

الموضع الأول تم إصلاحه في Commit 386.

الموضع الثاني لم يُصلح.

**الموضع الحالي التقريبي:** السطر 4078.

### ابحث عن العنصر التالي كاملًا

```javascript
vehicleRep=
                            type==='vehicle' &&
                            repById
                                ?(
                                    repById[
                                        String(
                                            x.driver_id||''
                                        )
                                    ]||
                                    null
                                )
                                :null,
```

### استبدله بالكامل بهذا العنصر

```javascript
vehicleRep=
                            type==='vehicle' &&
                            repById
                                ?(
                                    repById[
                                        String(
                                            (
                                                s.refs.vehicleRepMap &&
                                                s.refs.vehicleRepMap[
                                                    String(x.id)
                                                ]
                                            )||
                                            x.driver_id||
                                            ''
                                        )
                                    ]||
                                    null
                                )
                                :null,
```

لا تُعدّل الـoccurrence الأول الذي أصبح صحيحًا.

---

# 10. العيب 4 — DR-UI-04

**الدالة:**
`editVoucher:function(code)`

**الموضع الحالي التقريبي:** السطر 2860.

المشكلة:

إعادة فتح Draft DirectReturn ما زالت تبحث عن المندوب من:

`vv.driver_id`

بينما Production الحالي يعتمد على Master Assignment.

### ابحث عن هذا العنصر كاملًا

```javascript
var rr=
                            vv&&
                            (s.refs.reps||[])
                            .find(function(x){
                                return x.id===vv.driver_id;
                            });
```

### استبدله بالكامل بهذا العنصر

```javascript
var linkedRepId=
                            v.custodian_user_id||
                            (
                                s.refs.vehicleRepMap &&
                                s.refs.vehicleRepMap[
                                    String(v.from_id)
                                ]
                            )||
                            (vv&&vv.driver_id)||
                            '';

                        var rr=
                            (s.refs.reps||[])
                            .find(function(x){
                                return String(x.id)===
                                    String(linkedRepId);
                            })||
                            null;
```

هذا يحافظ على:
1. `custodian_user_id` المحفوظ في الوثيقة.
2. Master Assignment.
3. Legacy `driver_id` fallback.

---

# 11. ما لا يجب تعديله

## لا تعدل

### main.html

الوضع الحالي:

- Owner semantics صحيحة.
- Wildcard `*` مدعوم.
- `vouchers:view` مربوط.
- نظام التطبيقات المنفصلة delegation صحيح.
- الأذونات المخزنية delegated إلى `vouchers.html`.

المقطع المركزي:

`stock_vouchers -> delegated to vouchers.html`

مغلق.

### van-sales.html

التطبيق التشغيلي مستقل.

صلاحية الدخول:
- Owner
- أو `van-sales`
- أو `orders`

بيع السيارة يمر عبر `save-sales-invoice`.

تطبيق المندوب لا ينشئ manual stock vouchers.

لا يوجد defect مثبت يستدعي تعديله في هذه الأزمة.

### routeHtml

لا تعديل.

### submit

لا تعديل.

### loadRefs

لا تعديل.

الـMaster Assignment يتم تحميله من:

`fleet_query`

والخرائط:

- `repVehicleMap`
- `vehicleRepMap`

موجودة بالفعل.

---

# 12. Production Backend — لا يوجد نقص بنيوي

الحالة الحالية في Production تحتوي على:

### Create

`create_manual_stock_voucher_atomic`

بنسخة 12 parameter:

- p_company_id
- p_type
- p_reference
- p_from_type
- p_from_id
- p_to_type
- p_to_id
- p_notes
- p_created_by
- p_items
- p_rep_id
- p_operation_id

### Core

`create_manual_stock_voucher_atomic_core_12_20260828`

### Update

`update_manual_stock_voucher_atomic`

### Send

`send_stock_voucher_atomic`

### Receive

Edge Function:

`receive-stock-voucher`

الإصدار الحالي:

**v22**

وهو JWT protected.

### Complete

`complete_manual_stock_voucher_atomic`

### Cancel

`cancel_manual_stock_voucher_atomic`

إذن:

**لا توجد حاجة لإنشاء Edge Function جديدة.**

ولا توجد حاجة إلى RPC جديدة.

ولا توجد حاجة إلى جدول جديد.

ولا يوجد سبب لتجاوز Function limit بإنشاء بنية أخرى.

---

# 13. Production DirectReturn contract

Production الحالي يتحقق من:

1. Vehicle مصدر.
2. Branch وجهة.
3. Vehicle Active.
4. Mobile stock enabled.
5. Mobile branch صالح.
6. Rep مطلوب.
7. Rep Active.
8. Rep role = `مندوب بيع مباشر`.
9. Rep يمتلك `van-sales`.
10. Master Assignment:
   - `vehicle_id = p_from_id`
   - `sales_rep_user_id = p_rep_id`
   - `end_at IS NULL`
   - `is_primary = true`
11. Legacy `driver_id` fallback.
12. Company isolation.
13. Branch authorization.
14. Operation idempotency.

هذا العقد مغلق.

---

# 14. Production Send — الأثر

`send_stock_voucher_atomic` يستخدم:

`send_stock_voucher_atomic_core_20260828`

وبالنسبة إلى DirectReturn:

- التشغيل مرتبط بالفرع التشغيلي المستخرج من وجهة المرتجع.
- الـmovement يُنفذ عبر الـCore.
- لا يتم التعامل مع DirectReturn كفاتورة بيع.
- لا يتم إنشاء Sales Invoice.
- لا يجب تحويله إلى قبض/خزينة بسبب كونه حركة مخزنية.

DirectReturn هو:

**مخرج من مخزون السيارة + دخول إلى مخزون الفرع**

وليس:

**بيعًا أو تحصيلًا ماليًا.**

---

# 15. Receive Edge Function

الإصدار الحالي:

`receive-stock-voucher v22`

يقوم بـ:

1. التحقق من Authorization.
2. حل المستخدم إلى الشركة.
3. حل الإذن.
4. التحقق من الوجهة.
5. إنشاء effects من النوع:
   `IN`
6. استدعاء:

`post_manual_stock_voucher_atomic`

بعملية:

`RECEIVE`

وبالتالي لا يوجد سبب لكتابة Receive core جديد.

---

# 16. اختبار Production حديث لهذه الجلسة

تم تنفيذ اختبار Transactional مباشر باستخدام:

- company = RAWAEA
- vehicle = VHL-0422
- rep = `vansales2@rawaea.com`
- item = 1003
- qty = 1
- destination = BR-01

الاختبار:

**Create DirectReturn → Send**

النتيجة قبل Rollback:

- voucher created
- type = DirectReturn
- status = Sent
- from = VHL-0422
- to = BR-01
- custodian_user_id = rep2
- movement_count = 1

ثم تم:

**ROLLBACK**

ولم يترك الاختبار أثرًا على Production.

---

# 17. Production cleanup proof

بعد الاختبار:

`voucher_code = IN-10`

المخصص للاختبار لم يعد موجودًا.

الرصيد التجريبي الذي تم إنشاؤه اختباريًا لم يُترك.

الحالة الحالية:
- DirectReturn Draft = 0
- DirectReturn Sent = 0
- DirectReturn Received = 1
- DirectReturn Completed = 0
- IN-10 residue = 0

الـReceived الموجود ليس ناتج اختبار هذه الجلسة، وإنما سجل تاريخي قائم من اختبارات سابقة.

لا يجوز حذفه قسرًا لأنه سجل تشغيلي حقيقي وله Audit/Stock effects.

---

# 18. البيانات التجريبية الحالية المناسبة

في Production يوجد حاليًا:

### مركبة اختبار حقيقية

`VHL-0422`

### مندوب

`vansales2@rawaea.com`

### Master Assignment

موجود وPrimary.

### صنف

`1003`

`شيبس تايجر طعوم 10ج`

### مخزون المركبة

Qty = 1

Allocated = 0

Available = 1

وهذا يوفر Fixture حقيقيًا ومناسبًا للاختبار بعد تطبيق PATCHs.

لا حاجة لإنشاء بيانات تشغيلية إضافية.

---

# 19. Test Harness / Syntax Gate

تمت قراءة المصدر الحالي كاملًا وتحليل الـinline script.

الحالة الحالية قبل patch:

**FAIL**

الخطأ:

`SyntaxError: Invalid left-hand side in assignment`

سبب الخطأ:

عنصر DR-UI-02 الحالي.

---

# 20. Static simulation للترقيعات الأربع

تم تطبيق DR-UI-01 → DR-UI-04 على نسخة In-Memory من المصدر فقط، بدون الكتابة إلى Git.

النتيجة:

### DR-UI-01
PATCHED

### DR-UI-02
PATCHED

### DR-UI-03B
PATCHED

### DR-UI-04
PATCHED

### JavaScript Syntax

**PASS**

### residual DR-UI-03B legacy-only lookup

**0**

### residual DR-UI-04 driver-only lookup

**0**

### DirectReturn readonly literal في routeHtml

**false**

---

# 21. Semantic test للـMaster Assignment

باستخدام Production fixture:

VHL-0422

Master Assignment:

rep2

والـexpected result:

`vehicleRepMap[VHL-0422] = vansales2`

الـpatched algorithm يعيد:

VHL-0422

عند طلب مركبات المندوب:

`vansales2`

وهذا يثبت أن خوارزمية DR-UI-01 الصحيحة تزيل الاعتماد الخاطئ على `driver_id`.

---

# 22. Architecture integration

## النظام الأم

الـMain Shell هو:

- Tenant Authority
- Owner Authority
- Permission Authority
- Navigation Authority
- App Registry
- Delegation Authority

ولا يملك العمليات الميدانية التفصيلية لكل تطبيق.

## vouchers.html

هو التطبيق التنفيذي للأذونات والحركات المخزنية غير المرتبطة مباشرة بدورة Order/Runsheet.

يشمل حاليًا:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

ويتعامل مع العمليات التشغيلية المخزنية المستقلة.

## van-sales.html

يمثل التطبيق الميداني للبيع المباشر.

وظيفته:
- تنفيذ البيع المباشر.
- قراءة مخزون السيارة.
- التعامل مع المركبة والمندوب.
- تمرير الفاتورة إلى Save Sales Invoice.

ولا يحل محل Stock Voucher Engine.

---

# 23. دورة DirectSale

Branch
↓
Vehicle

الـvoucher هنا:

**صرف مخزني مباشر إلى المخزن المتنقل**

والمندوب جزء من العهدة.

Backend يربط:
- vehicle
- rep
- branch
- stock
- custody ledger

دون نقل دورة Order/Runsheet إلى vouchers.

---

# 24. دورة DirectReturn

Vehicle
↓
Branch

الـvoucher هنا:

**إرجاع مخزوني مستقل من المركبة إلى الفرع**

ولا يجب ربطه بوجود Order أو Runsheet كي يكون صالحًا.

التحقق:

Master Assignment
↓
Vehicle
↓
Rep
↓
Mobile Branch
↓
Stock Movement

ثم Receive:

Branch stock IN.

---

# 25. لماذا هذا البناء أفضل من دمج التطبيقات

الفصل الحالي ليس تفتيتًا بلا سبب.

هو يحقق:
- تشغيل ميداني أسرع.
- واجهات متخصصة.
- تقليل ازدحام Main.
- المحافظة على workflows الحقيقية.
- إبقاء Core/Production authority مركزيًا.
- منع تحول كل التطبيقات إلى Islands.

والتكامل يتم عبر:
- IDs
- RPC
- Edge Functions
- Master Assignment
- Realtime
- Core movement engine
- Audit trail

---

# 26. الفجوات التنافسية — بعد عزل الأزمة الحالية

تمت مراجعة الأنظمة المنافسة الحالية، ولم تُدخل تحسينات جديدة داخل هذه الجلسة لأنها ليست defects مثبتة في العقد الحالي.

## Odoo 19

Odoo يفصل أنواع العمليات المخزنية مثل Receipts / Delivery / Internal Transfers / Pick، ويتيح تنفيذ عمليات عبر Barcode. كما يميز داخليًا بين الحركة الداخلية وحركات الدخول والخروج، وتوضح وثائقه أن internal movement يغير الموقع دون تغيير ملكية المخزون.

المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/setup/operation_types.html

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

## Dynamics 365 Business Central

يدعم Transfer Orders مع:
- Ship
- Receive
- In-Transit quantity
- transfer routes
- handling times

المصدر:
https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations

## SAP

يوفر one-step / two-step stock transfer، والتحويل بين storage locations، ويدعم بيانات تشغيلية مثل batch/serial/UOM حسب نوع الحركة.

المصدر:
https://help.sap.com/docs/SAP_ERP_SPV/96bf9ad642cf4b26a29595e3d573fb8c/a464bd534f22b44ce10000000a174cb4.html

https://help.sap.com/docs/service-asset-manager/sap-service-and-asset-manager-user-guide-inventory-clerk-persona/adding-stock-transfer-and-transfer-posting

## Daftra

يوثق:
- Date
- From Warehouse
- To Warehouse
- Notes
- Item
- Qty
- Available Before
- Available After

ويوفر تقارير حركة مخزنية تفصيلية وسجلًا زمنيًا وتتبعًا.

المصدر:
https://docs.daftra.com/en/tutorial/transferring-stock/

https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/

https://docs.daftra.com/en/tutorial/viewing-the-product-service-file/

## Manager.io

يفصل Inventory Transfers عن البيع والشراء، ويعتمد على Inventory Locations، ويستخدم:
- Date
- Reference
- Description
- Item
- Qty
- From
- To

وتُعدل الكميات تلقائيًا في المواقع.

المصدر:
https://www2.manager.io/guides/10707

https://www2.manager.io/guides/10677

---

# 27. فجوات تنافسية مستقبلية مثبتة

هذه ليست defects في العقد الحالي ولا يجب خلطها بأزمة Master Assignment.

الـBacklog الحقيقي:

1. Stock Before / Stock After ظاهر على مستوى كل سطر.
2. Barcode-first operation entry.
3. Attachments / evidence.
4. Rich reason analytics.
5. SLA aging.
6. Exception queue.
7. Transit visibility أعمق للتحويل ثنائي المرحلة.
8. Lot / Serial / Expiry عند تفعيل tracking.
9. Approval/audit visualization أكثر عمقًا.
10. Operational dashboards موحدة للتدقيق والمخزون والعمليات.

هذه النقاط تُفتح بعد إغلاق DirectReturn UI، لا قبله.

---

# 28. Business Contract Matrix

| العقد | الحالة |
|---|---|
| Owner/Wildcard | CLOSED |
| Main authorization | CLOSED |
| Main delegation | CLOSED |
| Master Assignment backend | CLOSED |
| DirectSale backend | CLOSED |
| Transfer backend | CLOSED |
| SupplierReturn backend | CLOSED |
| DirectReturn backend | CLOSED |
| DirectReturn UI DR-UI-01 | OPEN – source patch required |
| DirectReturn UI DR-UI-02 | OPEN – source patch required |
| DirectReturn UI DR-UI-03A | APPLIED |
| DirectReturn UI DR-UI-03B | OPEN – source patch required |
| DirectReturn UI DR-UI-04 | OPEN – source patch required |
| Browser E2E on current fixed source | BLOCKED until owner applies source patches |
| Production infrastructure | CLOSED / no change required |

---

# 29. لماذا لم يتم تعديل Production

لأن الأدلة الحالية تقول:

**Backend contract is already correct.**

وتم إثبات ذلك من:
- current RPC signatures
- current RPC definitions
- current assignment rows
- current vehicle rows
- current mobile stock
- current Edge Function v22
- current transactional Create → Send

أي تعديل Production الآن سيكون إعادة بناء لما هو سليم بالفعل.

---

# 30. لماذا لم يتم حذف QA التاريخي

السجلات القديمة التي تحتوي على:
- inventory movements
- audit
- driver ledger
- accounting effects

ليست "garbage rows".

هي جزء من تاريخ النظام.

حذفها مباشرة سيكسر:
- Audit
- reconciliation
- stock history
- accounting consistency

لذلك لم يتم حذفها.

أما Fixture هذه الجلسة:

**IN-10**

فقد تم Rollback بالكامل.

---

# 31. الإغلاق المطلوب من المستخدم

تنفيذ أربعة استبدالات فقط في:

`companies/company-1/warehouse/vouchers.html`

بالترتيب:

1. DR-UI-01
2. DR-UI-02
3. DR-UI-03B
4. DR-UI-04

DR-UI-03A تم بالفعل.

لا تُعدّل أي عنصر آخر.

---

# 32. اختبار ما بعد التطبيق

بعد حفظ Commit جديد في `erp-frontend`:

## Gate 1

JavaScript Syntax:

PASS

## Gate 2

تحميل DirectReturn.

## Gate 3

المندوب:

`vansales2@rawaea.com`

## Gate 4

المركبة المصدر:

`VHL-0422`

ويجب أن تظهر رغم:

`vehicles.driver_id = NULL`

## Gate 5

Smart Search باسم:
`vansales2`

ويجب أن يعرض VHL-0422 من Master Assignment.

## Gate 6

Draft DirectReturn:
- فتح المسودة.
- الحفاظ على custodian_user_id.
- استرجاع rep من العقد الصحيح.

## Gate 7

Create

## Gate 8

Send

## Gate 9

Receive

## Gate 10

Negative pairing:

VHL-0422 + vansales@rawaea.com

يجب رفضه.

## Gate 11

التحقق:
- stock decrement at Vehicle on Send
- stock increment at Branch on Receive
- no Sales Invoice
- no Treasury transaction created by DirectReturn itself
- custody relationship remains consistent
- audit remains present

---

# 33. Browser deployment evidence

Current frontend HEAD `386b...` لا يملك workflow run مرتبطًا به عبر endpoint المتاح الذي يعرض PR-triggered runs.

آخر evidence تاريخية كانت على:

`56fee06...`

والـrun:

`36483037124`

لذلك لا يجوز استخدام ذلك الـrun لإثبات نجاح المصدر الجديد.

بعد Commit جديد يجب استخدام run جديد مبني على الـHEAD الجديد.

---

# 34. Self Audit

تم التحقق من:

- Current System HEAD
- System parent
- Current Frontend HEAD
- Frontend parent
- Current vouchers blob
- Current main blob
- Current van-sales blob
- historical Master Assignment commit
- current main delegation
- current permission semantics
- current Production vehicle assignments
- current rep identities
- current mobile stock
- current RPC signatures
- current DirectReturn validation
- current Receive Edge Function
- current transactional Create → Send
- rollback cleanliness
- current source Syntax
- exact defective elements
- exact replacements
- no need for new Edge Function
- no need for new RPC
- no need for schema change

---

# 35. تعليمات الجلسة التالية للوصول إلى الحقيقة

لا تبدأ من Report360.

ابدأ بهذا التسلسل:

1. اقرأ CURRENT_STATE الجديد.
2. اقرأ Current Git HEAD.
3. افتح current `vouchers.html`.
4. تحقق من Commit الذي طبّق DR-UI-01/02/03B/04.
5. اعمل Syntax Gate.
6. لا تعيد تعديل العناصر إذا كانت مطابقة للبدائل المثبتة هنا.
7. شغل Browser E2E على HEAD الجديد.
8. اختبر VHL-0422 + vansales2.
9. اختبر Draft reopen.
10. اختبر Create → Send → Receive.
11. اختبر negative pairing.
12. تحقق من stock/audit/financial invariants.
13. فقط بعد نجاح كل ذلك أغلق DirectReturn UI Contract.
14. ثم انتقل إلى أول Business Contract غير مغلق فعلًا.

قاعدة الاستمرار:

**Current evidence overrides historical narrative.**

وقاعدة عدم التكرار:

**لا تعيد إصلاح ما أثبتت Git/Source/Production/Database أنه مغلق.**

---

# 36. النتيجة التنفيذية

الحالة الحالية ليست أزمة Production.

الحالة الحالية:

**Partial source patch + one syntax defect + three remaining surgical substitutions.**

والحل ليس إعادة بناء التطبيق.

الحل هو:

**DR-UI-01 + DR-UI-02 + DR-UI-03B + DR-UI-04**

فقط.

بعد تطبيقها يمر المصدر بالـSyntax Gate حسب الاختبار In-Memory.

ثم يصبح الاختبار الميداني الأخير هو Browser E2E + Production E2E.

---

## SELF AUDIT — FINAL

**لم يتم تعديل:**
- main.html
- vouchers.html
- van-sales.html
- Edge Functions
- RPC
- Tables
- schema

**تم تنفيذ Production verification حديث قابل للـrollback.**

**تم التأكد أن الاختبار لم يترك IN-10 residue.**

**تم إثبات أن defect الحالي موجود في المصدر نفسه.**

**تم تقديم البدائل الجراحية كاملة لكل عنصر معيب.**

**لا يوجد عمل Production مطلوب لهذه النقطة.**

**لا تُغلق النقطة قبل Browser E2E على HEAD الجديد.**
