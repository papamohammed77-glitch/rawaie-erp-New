# Report350 — إغلاق جنائي مرحلي لتبويب الأذونات المخزنية: مطابقة Production + Source + DB + Deployment

**التاريخ:** 2026-09-28  
**حالة التنفيذ:** Production hardening منفذ ومختبر + Source جراحي جاهز للمالك + State reconciliation  
**النطاق:** `companies/company-1/warehouse/vouchers.html` كهدف Source فقط؛ **دون تعديل الملف مباشرة** ودون لمس `main.html`.

---

## 1. نقطة الاستئناف المعتمدة

تم الاستئناف من آخر حالة مثبتة، وليس من الذاكرة:

- أحدث تقرير: Report349.
- ملف الحالة: `CURRENT_STATE.md`.
- أحدث GIT للنظام الأم: `40287849b11ded794bdb8d086d5f5af74d0e8fa6`.
- Parent للنظام الأم: `101fa746a42337930f36b7cbb41eb2da21bbc64e`.
- أحدث Source للواجهة: `f07bdcc4abbbe899af569f8bfaccde04df279416`.
- Parent للواجهة: `cc35f3a9da6ababf4c8cd87b05ab93539cdae087`.
- `vouchers.html` الحالي: blob `9e3a9cbd0124639934cdf98abc9ec579f4b19f61`، وعدد الأسطر 6074.
- `main.html` الحالي: blob `810e4f5440f5975f55099a124deb42b086a49183`.
- لم يتم تعديل `main.html`.
- لم يتم تعديل `vouchers.html` مباشرة.

هرم الحقيقة:

`CURRENT PRODUCTION > CURRENT DATABASE > CURRENT DEPLOYMENT > CURRENT GIT > CURRENT SOURCE > HISTORY > REPORTS > MEMORY`

التقارير استخدمت كمسارات بحث فقط، وكل إغلاق حالي تم مطابقته مع المصدر/Production/DB.

---

## 2. فحص آخر Commit والـParent

### System repository

HEAD:

`40287849b11ded794bdb8d086d5f5af74d0e8fa6`

رسالة:

`state: record Report349 production hardening and voucher UI closure checkpoint`

الـParent:

`101fa746a42337930f36b7cbb41eb2da21bbc64e`

والـParent هو commit Report349 الذي يحتوي التغييرات/الإثباتات الوظيفية السابقة.

### Frontend repository

HEAD:

`f07bdcc4abbbe899af569f8bfaccde04df279416`

رسالة:

`Update vouchers.html`

الـParent:

`cc35f3a9da6ababf4c8cd87b05ab93539cdae087`

التغيير الأخير في هذا Commit كان داخل `vouchers.html` فقط، ولم يغير `main.html`.

---

## 3. Production الحالي

### Edge Functions

الموجودة والمستخدمة:

- `send-stock-voucher` — ACTIVE — v20 — verify_jwt=true.
- `receive-stock-voucher` — ACTIVE — v22 — verify_jwt=true.
- `complete-stock-voucher` — ACTIVE — v4 — verify_jwt=true.
- `create-stock-voucher` — ACTIVE — v12 — verify_jwt=false.

لم يتم إنشاء Edge Function جديدة.

### التنفيذ المركزي

`public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb,text)`

- SECURITY DEFINER.
- `search_path=public`.
- لا يمتلك `anon` أو `authenticated` صلاحية EXECUTE.
- التنفيذ يتم عبر طبقة الـEdge الحالية.

### RLS

`stock_vouchers` و`stock_voucher_details` مفعّل عليهما RLS.

قراءة `stock_vouchers` للمستخدم authenticated مقيدة بالشركة عبر:

`company_id = app_private.current_user_company_id()`

وتفاصيل الإذن مربوطة بالإذن والشركة.

---

## 4. Production Transfer contract — مغلق

العقد الموجود في:

`public.enforce_transfer_responsibility_contract()`

يثبت:

- `Draft → Sent` يثبت مسؤول استلام واحد للوجهة.
- المستلم لا يكون هو المرسل.
- `Sent → Received` يتطلب `receiver_user_id` نفسه.
- `Received → Completed` وفق العقد الحالي.
- مسؤولية المستلم لا تُنقل عشوائيًا أثناء الدورة.

### Hardening السابق

Migration:

`20260928120431_harden_transfer_partial_receive_actor_20260928`

أغلقت ثغرة الاستلام الجزئي التي كانت تسمح بتعديل `received_qty` قبل الوصول إلى انتقال الحالة النهائية.

---

## 5. الفجوة الجديدة التي اكتُشفت جنائيًا

### T-12 السابق كان يحتوي خطأ

Report349 اقترح:

`Transfer + Sent → exactReceiver || privileged`

لكن Production لا يطبق `privileged` كبديل عن `receiver_user_id` في عملية RECEIVE.

إذًا كان من الممكن أن تظهر للمدير/المالك واجهة «استلام» لا يملك التنفيذ المركزي صلاحية قبولها.

**لم يتم تطبيق T-12 السابق.**

تم تصحيحه في هذه الجلسة، وسيظهر البديل المصحح لاحقًا في هذه الوثيقة.

---

## 6. فجوة Production الجديدة — DirectReturn

المراجعة الحالية كشفت أن `receive-stock-voucher` يستخرج هوية Auth الصحيحة ثم يمرر العملية إلى نفس الـRPC.

لكن قبل الإصلاح كان الـRPC يفرض نطاق الفرع على `DirectReturn` دون فرض أن المنفذ نفسه:

- `role = مخزني`
- `active_warehouse_role = أذونات`

وهذا كان Contract Gap لأن الـUI كان يخفي الزر بينما المسار التنفيذي المركزي لم يكن يفرض نفس العقد.

### الإصلاح المنفذ مباشرة في Production

تم تعديل نفس RPC، دون إنشاء Edge جديدة.

العقد الجديد لـ`DirectReturn + RECEIVE`:

- privileged / wildcard: مسموح وفق عقد الإدارة العليا.
- غير privileged: يجب أن يكون المستخدم `مخزني` + `أذونات`.
- يجب أن يكون فرع الوجهة Branch فعليًا تابعًا للشركة.
- يجب أن يكون فرع الوجهة داخل نطاق المستخدم التشغيلي.

رسائل الحماية:

`لا يملك هذا المستخدم صلاحية استلام المرتجع المباشر`

و:

`فرع المرتجع المباشر خارج نطاق مسؤول المستخدم`

---

## 7. اختبار Production الجديد — DirectReturn Security Regression

تم إنشاء Fixture مؤقت داخل Transaction فقط، ثم Rollback كامل.

الإذن التجريبي:

`QA-DR-SEC-20260928-01`

الصنف:

`1001 — جو كيك 5ج`

الوجهة:

`BR-01`

### مستخدم غير مخول

`vouchers2@rawaea.com`

- role = مخزني.
- active_warehouse_role = null.
- allowed branch = BR-01.

النتيجة:

**BLOCKED**

بالرسالة:

`لا يملك هذا المستخدم صلاحية استلام المرتجع المباشر`

### المستخدم المخزني الصحيح

`vouchers@rawaea.com`

- role = مخزني.
- active_warehouse_role = أذونات.
- allowed branch = BR-01.

النتيجة:

**PASS**

الحالة أصبحت مؤقتًا:

`Received`

والاختبار الكامل تم عمله داخل Transaction مع Rollback.

### الأثر بعد الاختبار

- لا Voucher تجريبي.
- لا حركة مخزنية تجريبية.
- لا قيد عهدة تجريبي.
- لا تغير دائم في الأرصدة.

---

## 8. الوضع الحالي للبيانات

بعد تنظيف QA السابق، الاستعلام الحالي لـManual vouchers يثبت:

- Completed = 5.
- Draft = 0.
- Transfer = 0.
- DirectReturn = 0.

الأذونات المكتملة القديمة ذات الأثر المالي/المخزني لم تُحذف عشوائيًا.

---

## 9. Source inspection — vouchers.html

الملف الحالي لم يتغير:

`9e3a9cbd0124639934cdf98abc9ec579f4b19f61`

أهم المواقع الحالية:

| العنصر | السطر |
|---|---:|
| `actionFor:function(v)` | 434 |
| `loadList:function(scope)` | 475 |
| `renderList:function(scope)` | 476 |
| `cards:function(rows,scope)` | 795 |
| `details:function(code)` | 1653 |
| `receive:function(code,full)` | 2148 |
| `exitVoucherDetails:function()` | 2065 |
| `allowedBranch:function(u,b)` | 2999 |
| `pickArr:function(key)` | 3245 |
| `pickSelect:function(key,id)` | 3814 |
| `printDraftVoucher:function(code)` | 1216 |
| إجمالي الأسطر | 6074 |

الـreceive engine الحالي **سليم وظيفيًا** من حيث partial/full/idempotency، لذلك لا يُعاد بناؤه.

---

## 10. Source inspection — picker.html

المصدر الحالي:

`c7ad267d852d415b680aed7716833eea9bcffdf6`

المسار التشغيلي الحالي يثبت:

- `startPicking()` يبدأ دورة التحضير عبر Edge الحالية.
- الشاشة تعرض `qty_ordered` و`qty_picked`.
- العامل يضغط على الصنف ويدخل الكمية الفعلية.
- عند الإكمال تنتهي دورة التحضير، وليس مجرد عرض نظري للكميات.

المبدأ المستخلص للتكامل:

**الكميات الفعلية المنفذة أهم من الكميات النظرية، مع الاحتفاظ بالفرق كحالة تشغيلية.**

---

## 11. Source inspection — van-sales.html

المصدر الحالي:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

الملف يثبت أن تطبيق البيع المباشر:

- يحدد مخزن السيارة عبر `setup-van-branch`.
- يحمّل `stock_branches` مع بيانات الأصناف/الفروع.
- ينفذ البيع من خلال `save-sales-invoice`.
- لا يبني مخزنًا مستقلاً خارج قاعدة الحركة المركزية.
- يستخدم `operation_id` لمنع تكرار عمليات البيع.

وبالتالي:

`vouchers.html DirectSale`

ينشئ ويحمّل عهدة السيارة، بينما:

`van-sales.html`

ينفذ البيع الفعلي من مخزن السيارة.

هذا هو التكامل الصحيح؛ لا يجب تحويل أحدهما إلى بديل عن الآخر.

---

## 12. دور النظام الأم

`main.html` هو Control Plane وليس بديلًا عن التطبيقات الميدانية.

المبدأ الحالي:

- النظام الأم يملك التعريفات والصلاحيات والأدوار والفروع والمستخدمين.
- التطبيقات الميدانية تنفذ العملية في السياق الميداني.
- Production RPC/Triggers تحرس العقد.
- المخزون المركزي يسجل الحركة.
- النظام الأم يراقب النتائج ولا يُدخل منطقًا ميدانيًا داخل كل صفحة مستقلة.

تم التحقق من Hash الحالي لـ`main.html` ولم يتم تغييره.

---

## 13. التبويب المستهدف — العقد المطلوب

### «معلقة»

يجب أن يكون العرض **جدولًا** وليس Cards.

الترتيب:

1. تحويل فرع — إرسال.
2. تحويل فرع — استلام.
3. صرف مندوب.
4. مرتجع مباشر.
5. مرتجع مورد.

### «مكتملة»

نفس نموذج الجدول مع حالات مكتملة.

### العرض

Click على سطر الإذن:

`App.details(voucher_code)`

ثم Modal.

### التحكم

كل Edit / Delete / Send / Receive / Complete / Print داخل Modal.

لا توجد أزرار تشغيل داخل القائمة.

---

## 14. المقارنة التنافسية

### Odoo 19

Odoo يميز التحويلات الداخلية كحركات مخزنية من موقع إلى آخر، ويوفر تمثيلًا واضحًا للمواقع، بما فيها مواقع Transit، كما يدعم عرض تاريخ الحركات والحالات الجزئية.  
مصادر رسمية:
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/product_management/configure/type.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html
- https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

### Dynamics 365

Microsoft يوثق Transfer Orders مع Warehouse levels وTransport lead time، كما أن Transfer Order products تحتوي Shipping/Receiving information وحالات Shipped/Received.  
مصادر:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse
- https://learn.microsoft.com/en-us/dynamics365/intelligent-order-management/integrate-transfer-orders
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

### SAP

SAP يطبق فصلًا واضحًا بين Stock Transport Order وGoods Issue وGoods Receipt، ويدعم Stock in Transit، كما أن الاستلام يمكن أن يكون جزئيًا.  
مصادر:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/95f56a29a41e4861ba3424598848ee2b/4d6ed2bb174a74dbe10000000a42189c.html
- https://help.sap.com/docs/PRODUCT_ID/0f4ab800d01c4366b0c9aaff06a64320/bf83cf535b804808e10000000a174cb4.html
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/2d95c3180a974e0aad07556ee4d28e94/f960b6531de6b64ce10000000a174cb4.html

### Daftra

Daftra يوثق Manual Transfer بين المستودعات مع التاريخ، المستودع المصدر/الوجهة، الكمية، والملاحظات، ويعرض قبل/بعد المخزون. كما يتيح ربط المستخدمين بالفروع والأذونات التشغيلية.  
مصادر:
- https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/
- https://docs.daftra.com/en/tutorial/transferring-stock/
- https://docs.daftra.com/en/tutorial/branches-management/

### Manager

Manager يميز Inventory Locations وInventory Transfers، ويربط انتقال المخزون بالموقع من وإلى ويعرض الكمية حسب الموقع.  
مصادر:
- https://www2.manager.io/guides/10707
- https://www2.manager.io/guides/10677

### الخلاصة المعمارية المقارنة

RAWAEA يملك أساسًا مميزًا: **تطبيقات ميدانية منفصلة + قلب مركزي واحد للحركة**.

لكن للاقتراب من النضج المؤسسي يجب لاحقًا استكمال:

- In-Transit صريحة.
- ETA/SLA.
- Discrepancy reasons.
- Backorder/remaining transfer.
- Barcode receiving.
- Proof of delivery / attachments.
- Branch transfer dashboard.
- Transit/reconciliation reporting.

هذه نقاط Backlog وليست سببًا لإعادة بناء التبويب الحالي.

---

## 15. المبادئ الحاكمة الجديدة

### P-09 — UI authority ≠ execution authority

إظهار الزر في الواجهة لا يمنح السلطة.

### P-10 — كل mutation الحرجة تُحرس مركزيًا

Partial Receive يجب أن يمر بنفس حراسة Full Receive.

### P-11 — Transfer RECEIVE = receiver-bound

لا يكفي role أو wildcard؛ يجب أن يكون المستخدم هو `receiver_user_id`.

### P-12 — DirectReturn RECEIVE = warehouse custody

غير privileged يجب أن يكون `مخزني + أذونات + branch scope`.

### P-13 — Destination scope مختلف عن source scope

صلاحيات المرسل تحدد مصدره، ولا تستخدم لحظر وجهة التحويل.

### P-14 — القائمة Navigation فقط

الجدول يستعرض، والـModal ينفذ.

### P-15 — عدم خلق Edge جديدة عند وجود capability مركزية

المسار يمر عبر الـRPC الموجود.

### P-16 — لا حذف لتاريخ ذي أثر

سجلات لها أثر مالي/مخزني لا تُحذف كـQA بدون Reverse contract.

### P-17 — كل E2E تخريبي يجب أن يكون zero-residue

Fixture → test → assertion → rollback.

### P-18 — لا Closure بدون مطابقة Production/DB/Source

لا تعتمد على التقرير القديم كحالة حالية.

---

## 16. حزمة التعديل الجراحي المطلوبة من المالك

`vouchers.html` فقط.

**لا تعديل على `main.html`.**

**لا تعديل مباشر من جهة المراجعة على `vouchers.html`.**

الأجزاء التالية هي البدائل الكاملة الجاهزة:

# 9. العيوب Source التي ما زالت مفتوحة

## T-09 — allowedBranch

### العنصر المعيب

الملف:

`companies/company-1/warehouse/vouchers.html`

الدالة:

`allowedBranch:function(u,b)`

الموضع الحالي يبدأ تقريبًا عند line 2999.

### الخطأ

ابحث عن بداية الدالة:

```javascript
allowedBranch:function(u,b){
```

واحذف **الدالة كاملة** حتى الفاصل:

```javascript
},
```

قبل `pickArr`.

### البديل الكامل

```javascript
allowedBranch:function(u,b){
    if(!u||!b)return false;

    if(String(u.default_branch_id||'')===String(b.id)){
        return true;
    }

    var a=u.allowed_branch_ids;

    if(a===null||typeof a==='undefined'){
        return true;
    }

    if(Array.isArray(a)){
        a=a.map(String);
    }else if(typeof a==='string'&&a.trim()){
        var raw=a.trim(),
            parsed=null;

        try{
            parsed=JSON.parse(raw);
        }catch(e){
            parsed=null;
        }

        if(Array.isArray(parsed)){
            a=parsed.map(String);
        }else if(typeof parsed==='string'){
            a=[parsed.trim()];
        }else{
            a=raw
                .split(/[,|]/)
                .map(function(x){
                    return x
                        .trim()
                        .replace(/^"|"$/g,'');
                })
                .filter(Boolean);
        }
    }else{
        return false;
    }

    a=a.map(function(x){
        return String(x)
            .trim()
            .replace(/^"|"$/g,'');
    });

    if(a.indexOf('*')>=0){
        return true;
    }

    return (
        a.indexOf(String(b.id))>=0 ||
        a.indexOf(String(b.branch_code||''))>=0
    );
},
```

### سبب التعديل

إزالة bypass الخاص بـ`Transfer` الذي كان يجعل مخزني/أذونات يرى كل فروع الشركة.

---

# 10. T-10 — pickArr

### العنصر المعيب

الدالة:

`pickArr:function(key)`

موضعها الحالي يبدأ تقريبًا line 3245.

### الخطأ

داخل:

```javascript
if(
    s.type==='Transfer'
){
    return allBranches;
}
```

يُسمح للمرسل باختيار كل فروع الشركة كمصدر.

### الإجراء

ابحث عن **الدالة كاملة**:

```javascript
pickArr:function(key){
```

واستبدلها كاملة بالآتي:

```javascript
pickArr:function(key){

    var s=this,

        allBranches=
            (s.refs.branches||[])
            .filter(function(x){

                return (
                    String(
                        x.company_id||''
                    )===
                    String(
                        s.company||''
                    ) &&
                    x.is_active!==false
                );
            }),

        userBranches=
            allBranches.filter(
                function(x){
                    return s.allowedBranch(
                        s.user,
                        x
                    );
                }
            ),

        bid=
            (RW_UI.byId('wsFrom')||{})
            .value||
            '',

        b=
            allBranches.find(
                function(x){
                    return (
                        String(x.id)===
                        String(bid)
                    );
                }
            );

    if(key==='wsFrom'){

        if(
            s.type==='DirectReturn'
        ){

            if(
                s.user &&
                s.user.role===
                    'مندوب بيع مباشر'
            ){

                return (
                    s.refs.vehicles||[]
                )
                .filter(function(v){

                    return (
                        v.status==='Active' &&
                        v.mobile_stock_enabled!==false &&
                        v.driver_id===
                            s.user.id &&
                        !!s.vehicleBranch(v)
                    );
                });
            }

            return (
                s.refs.vehicles||[]
            )
            .filter(function(v){

                return (
                    v.status==='Active' &&
                    v.mobile_stock_enabled!==false &&
                    !!s.vehicleBranch(v)
                );
            });
        }

        if(
            s.type==='Transfer'
        ){
            return userBranches;
        }

        return userBranches;
    }

    if(key==='wsRep'){
    
        return (
            s.refs.reps||[]
        )
        .filter(function(r){
    
            if(!b){
                return false;
            }
    
            if(
                s.type==='DirectSale' &&
                !s.refs.repVehicleMap[
                    String(r.id)
                ]
            ){
                return false;
            }
    
            return (
                s.allowedBranch(
                    s.user,
                    b
                ) &&
                s.allowedBranch(
                    r,
                    b
                )
            );
        });
    }

    if(
        key==='wsTo' &&
        s.type==='Transfer'
    ){
        return allBranches;
    }

    if(
        key==='wsTo' &&
        s.type==='DirectSale'
    ){

        var rid=
            (RW_UI.byId('wsRep')||{})
                .value||
            '';

        var mappedVehicleId=
            rid
                ?s.refs.repVehicleMap[
                    String(rid)
                ]||''
                :'';

        return (
            s.refs.vehicles||[]
        )
        .filter(function(v){

            var vb=
                s.vehicleBranch(v);

            var repId=
                s.refs.vehicleRepMap[
                    String(v.id)
                ]||
                '';

            var rep=
                (s.refs.reps||[])
                    .find(function(r){
                        return String(r.id)===
                            String(repId);
                    });

            return (
                v.status==='Active' &&
                v.mobile_stock_enabled!==false &&
                !!vb &&
                !!b &&
                s.allowedBranch(
                    s.user,
                    b
                ) &&
                !!rep &&
                s.allowedBranch(
                    rep,
                    b
                ) &&
                (
                    !rid ||
                    String(v.id)===
                        String(mappedVehicleId)
                )
            );
        });
    }

    if(
        key==='wsTo' &&
        s.type==='DirectReturn'
    ){
        return userBranches;
    }

    if(
        key==='wsTo' &&
        s.type==='SupplierReturn'
    ){

        return (
            s.refs.suppliers||[]
        )
        .filter(function(x){

            return (
                x &&
                x.is_active!==false
            );
        });
    }

    return [];
},
```

### العقد الناتج

- المصدر Transfer = فروع المستخدم فقط.
- الوجهة Transfer = كل فروع الشركة المسموح بها من حيث company، لأن الوجهة ليست ملكية المرسل.
- Production هو الذي يحدد عند الإرسال أن المرسل مصرح له بالمصدر.
- Production هو الذي يربط مسؤول استلام الوجهة.

---

# 11. T-11 — pickSelect

### العنصر المعيب

الدالة:

`pickSelect:function(key,id)`

موضعها الحالي يبدأ تقريبًا line 3814.

### الخطأ

الشرط الحالي يفرض `allowedBranch` على وجهة Transfer:

```javascript
(key==='wsTo'&&(
    s.type==='Transfer' ||
    s.type==='DirectReturn'
))
```

وهذا قد يمنع اختيار فرع الوجهة المختلف عن فرع المرسل.

### الإجراء

ابحث عن **الدالة كاملة**:

```javascript
pickSelect:function(key,id){
```

واستبدلها بالنسخة الحالية نفسها مع تعديل عقد branchSelection فقط إلى:

```javascript
pickSelect:function(key,id){
    var s=this,
        arr=this.pickArr(key)||[],
        x=arr.find(function(z){
            return z.id===id;
        });

    if(!x){
        return;
    }

    var branchSelection=
        (key==='wsFrom'&&s.type!=='DirectReturn') ||
        (key==='wsTo'&&s.type==='DirectReturn');

    if(branchSelection){
        var selectedBranch=
            (s.refs.branches||[]).find(function(branch){
                return branch.id===id;
            });

        if(
            !selectedBranch ||
            !s.allowedBranch(s.user,selectedBranch)
        ){
            RW_UI.toast(
                'هذا الفرع ظاهر للبحث، لكنه خارج نطاق فروع المستخدم المسموح بها',
                'error'
            );
            return;
        }
    }

    if(key==='wsFrom'&&s.type==='DirectReturn'){
        var vb=s.vehicleBranch(x);

        if(!vb){
            RW_UI.toast(
                'المركبة لا تملك مخزنًا متنقلًا صالحًا',
                'error'
            );
            return;
        }

        RW_UI.byId('wsFrom').value=x.id;
        RW_UI.byId('wsFromSearch').value=
            x.vehicle_code||x.license_plate;

        RW_UI.byId('wsFromMenu').classList.add('hidden');

        var r=
            s.refs.reps.find(function(rp){
                return rp.id===x.driver_id;
            });

        RW_UI.byId('wsRep').value=r?r.id:'';
        RW_UI.byId('wsRepSearch').value=
            r?(r.name||r.email):'';

        if(r){
            RW_UI.byId('wsRepSearch').setAttribute(
                'readonly',
                'readonly'
            );
        }else{
            RW_UI.byId('wsRepSearch').removeAttribute(
                'readonly'
            );
        }

        s.summary();
        s.renderProducts();

        return;
    }

    RW_UI.byId(key).value=x.id;

    if(key==='wsRep'){

        RW_UI.byId(key+'Search').value=
            x.name||
            x.email||
            '';

        if(
            s.type==='DirectSale'
        ){

            var synced=
                s.syncDirectSaleVehicleWithRep(
                    x.id
                );

            if(!synced){
                RW_UI.byId('wsRep').value='';
                RW_UI.byId('wsRepSearch').value='';

                RW_UI.toast(
                    'لا توجد مركبة نشطة معينة لهذا المندوب في إدارة الأسطول',
                    'error'
                );

                return;
            }
        }

    }else if(
        key==='wsTo' &&
        s.type==='SupplierReturn'
    ){
        RW_UI.byId(key+'Search').value=
            x.name||
            x.supplier_code||
            '';

    }else{
        RW_UI.byId(key+'Search').value=
            x.name||
            x.vehicle_code||
            x.supplier_code||
            x.branch_code||
            '';
    }

    RW_UI.byId(key+'Menu').classList.add('hidden');

    if(
        key==='wsFrom' &&
        s.type==='DirectSale'
    ){

        var selectedRepId=
            (RW_UI.byId('wsRep')||{})
                .value||
            '';

        var selectedRep=
            (s.refs.reps||[])
                .find(function(rp){
                    return String(rp.id)===
                        String(selectedRepId);
                });

        var keepRep=
            !!selectedRep &&
            s.allowedBranch(
                selectedRep,
                x
            );

        if(!keepRep){

            RW_UI.byId('wsRep').value='';
            RW_UI.byId('wsRepSearch').value='';

            RW_UI.byId('wsTo').value='';
            RW_UI.byId('wsToSearch').value='';
            RW_UI.byId('wsToSearch')
                .removeAttribute('readonly');

        }else{

            s.syncDirectSaleVehicleWithRep(
                selectedRep.id
            );
        }

        RW_UI.byId('wsRepSearch')
            .removeAttribute('readonly');
    }

    if(
        key==='wsRep' &&
        s.type==='DirectSale'
    ){
        RW_UI.byId('wsTo').value='';
        RW_UI.byId('wsToSearch').value='';
        RW_UI.byId('wsRepSearch').removeAttribute(
            'readonly'
        );
    }

    s.updateSource();
},
```

**ملاحظة جراحية:** لا تُعدّل أي جزء آخر من `pickSelect`.

---

# 12. T-12 — actionFor (تصحيح التقرير السابق)

### العنصر المعيب

الملف:

`companies/company-1/warehouse/vouchers.html`

الدالة:

`actionFor:function(v)`

الموضع الحالي: **line 434**.

### الخطأ المثبت جنائيًا

النسخة الواردة في Report349 كانت تمنح privileged users فعل `receive` لتحويل `Transfer/Sent` عبر:

`exactReceiver || privileged`

بينما Production Trigger الحالي يشترط **المستخدم المحدد في `receiver_user_id` بالضبط** لأي `Sent → Receive`.

إذًا النسخة السابقة كانت ستُظهر زرًا لا تملكه السلطة التنفيذية فعليًا. هذا تم اكتشافه من مطابقة Source مع Production، ولم تُطبق نسخة T-12 السابقة.

### الإجراء

ابحث عن:

```javascript
actionFor:function(v){
```

واحذف **الدالة كاملة** ثم استبدلها بالبديل التالي:

```javascript
actionFor:function(v){
    var s=this;

    if(!v||!s.user){
        return '';
    }

    var user=s.user;

    var email=
        String(user.email||'')
            .trim()
            .toLowerCase();

    var creator=
        email &&
        String(v.created_by||'')
            .trim()
            .toLowerCase()===email;

    var permissions=user.permissions;

    if(typeof permissions==='string'){
        try{
            permissions=JSON.parse(permissions);
        }catch(e){
            permissions=
                permissions
                    .split(/[,|]/)
                    .map(function(x){
                        return x.trim();
                    })
                    .filter(Boolean);
        }
    }

    permissions=
        Array.isArray(permissions)
            ?permissions.map(String)
            :[];

    var wildcard=
        permissions.indexOf('*')>=0;

    var privileged=
        wildcard||
        [
            'مدير النظام',
            'مدير عام',
            'مدير مخازن',
            'مشرف مخازن'
        ].indexOf(String(user.role||''))>=0;

    var warehouseVoucherRole=
        String(
            user.activeWarehouseRole||
            user.active_warehouse_role||
            ''
        )==='أذونات';

    function branchInScope(branchId){

        if(!branchId){
            return false;
        }

        if(privileged){
            return true;
        }

        if(
            String(user.default_branch_id||'')===
            String(branchId)
        ){
            return true;
        }

        var branch=
            (s.refs.branches||[])
                .find(function(b){
                    return String(b.id)===
                        String(branchId);
                });

        if(!branch){
            return false;
        }

        var a=user.allowed_branch_ids;

        if(a===null||typeof a==='undefined'){
            return true;
        }

        if(Array.isArray(a)){
            a=a.map(String);
        }else if(typeof a==='string'&&a.trim()){

            var raw=a.trim(),
                parsed=null;

            try{
                parsed=JSON.parse(raw);
            }catch(e){
                parsed=null;
            }

            if(Array.isArray(parsed)){
                a=parsed.map(String);
            }else if(typeof parsed==='string'){
                a=[parsed.trim()];
            }else{
                a=raw
                    .split(/[,|]/)
                    .map(function(x){
                        return x
                            .trim()
                            .replace(/^"|"$/g,'');
                    })
                    .filter(Boolean);
            }

        }else{
            return false;
        }

        a=a.map(function(x){
            return String(x)
                .trim()
                .replace(/^"|"$/g,'');
        });

        return(
            a.indexOf('*')>=0||
            a.indexOf(String(branch.id))>=0||
            a.indexOf(String(branch.branch_code||''))>=0
        );
    }

    var exactReceiver=
        user.id&&
        v.receiver_user_id&&
        String(user.id)===
        String(v.receiver_user_id);

    if(v.type==='Transfer'){

        if(v.status==='Draft'){
            return(
                creator||
                privileged
            )?'draft':'';
        }

        if(v.status==='Sent'){
            /*
             * Production contract is receiver-bound for every RECEIVE,
             * including partial RECEIVE while the voucher remains Sent.
             */
            return exactReceiver
                ?'receive'
                :'';
        }

        if(v.status==='Received'){
            return(
                creator||
                privileged
            )?'complete':'';
        }

        return '';
    }

    if(v.status==='Draft'){
        return(
            creator||
            privileged
        )?'draft':'';
    }

    if(v.status==='Sent'){

        if(v.type==='DirectReturn'){
            return(
                privileged||
                (
                    warehouseVoucherRole&&
                    branchInScope(v.to_id)
                )
            )?'receive':'';
        }

        if(
            v.type==='DirectSale'||
            v.type==='SupplierReturn'
        ){
            return(
                creator||
                privileged
            )?'complete':'';
        }
    }

    if(v.status==='Received'){
        return(
            creator||
            privileged
        )?'complete':'';
    }

    return '';
},
```

### النتيجة

- Transfer/Sent: **زر الاستلام يظهر فقط للـ`receiver_user_id` المثبت**.
- privileged لا يحصل على زر Receive Transfer لمجرد كونه privileged.
- Transfer/Received: الإكمال يبقى وفق العقد الحالي.
- DirectReturn: زر الاستلام يبقى لمخزني «أذونات» في نطاق الفرع أو privileged، مع حارس Production الجديد الذي يمنع التنفيذ الفعلي لغير المصرح.

---

# 13. T-13 — cards

### العنصر المعيب

الدالة:

`cards:function(rows,scope)`

موضعها الحالي تقريبًا line 795.

### الخطأ

هي حاليًا تبني **Cards** وتضع أزرار التحكم داخل صف البطاقة خارج مودال الإذن.

وهذا يخالف العقد الجديد:

**قائمة = جدول عرض فقط**

**التحكم = داخل مودال الإذن فقط**

### الإجراء

ابحث عن:

```javascript
cards:function(rows,scope){
```

واحذف **الدالة كاملة** حتى:

```javascript
},
```

التي تسبق `loc:function`.

### البديل الكامل

```javascript
cards:function(rows,scope){
    var s=this;

    function dateText(v){
        if(!v){
            return '—';
        }

        var t=Date.parse(v);

        if(!Number.isFinite(t)){
            return String(v);
        }

        try{
            return new Date(t).toLocaleString(
                'ar-EG',
                {
                    year:'numeric',
                    month:'2-digit',
                    day:'2-digit',
                    hour:'2-digit',
                    minute:'2-digit'
                }
            );
        }catch(e){
            return String(v);
        }
    }

    function parseTs(v){
        var t=Date.parse(v||'');
        return Number.isFinite(t)?t:null;
    }

    function duration(from,to){
        var a=parseTs(from),
            b=parseTs(to);

        if(a===null||b===null||b<a){
            return null;
        }

        return Math.round((b-a)/1000);
    }

    function durationText(sec){
        if(sec===null||sec===undefined){
            return '—';
        }

        var n=Math.max(0,Number(sec)||0),
            d=Math.floor(n/86400);

        n-=d*86400;

        var h=Math.floor(n/3600);

        n-=h*3600;

        var m=Math.floor(n/60),
            out=[];

        if(d)out.push(d+'ي');
        if(h||d)out.push(h+'س');
        out.push(m+'د');

        return out.join(' ');
    }

    function typeLabel(v){

        if(v.type==='Transfer'){

            if(scope==='pending'&&v.status==='Draft'){
                return 'تحويل فرع — إرسال';
            }

            if(scope==='pending'&&v.status==='Sent'){
                return 'تحويل فرع — استلام';
            }

            if(scope==='pending'&&v.status==='Received'){
                return 'تحويل فرع — بانتظار الإكمال';
            }

            return 'تحويل فرع';
        }

        if(v.type==='DirectSale'){
            return 'صرف مندوب';
        }

        if(v.type==='DirectReturn'){
            return 'مرتجع مباشر';
        }

        if(v.type==='SupplierReturn'){
            return 'مرتجع مورد';
        }

        return v.type||'إذن مخزني';
    }

    function statusLabel(v){

        if(v.status==='Draft'){
            return 'مسودة';
        }

        if(v.status==='Sent'){
            return 'مُرسل';
        }

        if(v.status==='Received'){
            return 'مُستلم';
        }

        if(v.status==='Completed'){
            return 'مكتمل';
        }

        if(v.status==='Cancelled'){
            return 'ملغى';
        }

        return v.status||'—';
    }

    function statusClass(v){

        if(v.status==='Draft'){
            return 'bg-amber-100 text-amber-700';
        }

        if(v.status==='Sent'){
            return 'bg-blue-100 text-blue-700';
        }

        if(v.status==='Received'){
            return 'bg-emerald-100 text-emerald-700';
        }

        if(v.status==='Cancelled'){
            return 'bg-rose-100 text-rose-700';
        }

        return 'bg-slate-100 text-slate-700';
    }

    function rank(v){

        if(v.type==='Transfer'){

            if(scope==='pending'){
                if(v.status==='Draft')return 10;
                if(v.status==='Sent')return 20;
                if(v.status==='Received')return 25;
            }

            return 10;
        }

        if(v.type==='DirectSale'){
            return 30;
        }

        if(v.type==='DirectReturn'){
            return 40;
        }

        if(v.type==='SupplierReturn'){
            return 50;
        }

        return 90;
    }

    if(!rows.length){
        return(
            '<div class="card text-center py-14">'+
                '<div class="text-5xl mb-3">☕</div>'+
                '<b class="text-slate-400">لا توجد أذونات</b>'+
            '</div>'
        );
    }

    var ordered=
        rows
            .slice()
            .sort(function(a,b){

                var ra=rank(a),
                    rb=rank(b);

                if(ra!==rb){
                    return ra-rb;
                }

                var ta=parseTs(a.created_at)||0,
                    tb=parseTs(b.created_at)||0;

                return tb-ta;
            });

    var body=
        ordered.map(function(v){

            var codeJs=
                JSON.stringify(
                    String(v.voucher_code||'')
                );

            var fromText=
                s.loc(
                    v.from_id,
                    v.from_type
                );

            var toText=
                s.loc(
                    v.to_id,
                    v.to_type
                );

            var createdToSent=
                duration(
                    v.created_at,
                    v.sent_date
                );

            var sentToReceived=
                duration(
                    v.sent_date,
                    v.received_date
                );

            var receivedToCompleted=
                duration(
                    v.received_date,
                    v.completed_at
                );

            return(
                '<tr '+
                    'role="button" tabindex="0" '+
                    'class="border-t hover:bg-slate-50 cursor-pointer transition-colors">'+
                    '<td class="p-3 align-top" '+
                        'onclick="App.details('+s.esc(codeJs)+')" '+
                        'onkeydown="if(event.key===\\\'Enter\\\' || event.key===\\\' \\\'){App.details('+s.esc(codeJs)+')}">'+
                        '<b class="block text-sm">'+
                            s.esc(v.voucher_code||'—')+
                        '</b>'+
                        '<span class="text-[10px] text-slate-400">'+
                            'فتح التفاصيل ←'+
                        '</span>'+
                    '</td>'+
                    '<td class="p-3 align-top" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<span class="block text-xs font-black">'+
                            s.esc(typeLabel(v))+
                        '</span>'+
                        '<span class="inline-block mt-1 px-2 py-1 rounded-full text-[10px] font-bold '+statusClass(v)+'">'+
                            s.esc(statusLabel(v))+
                        '</span>'+
                    '</td>'+
                    '<td class="p-3 align-top text-xs" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<b>'+s.esc(fromText)+'</b>'+
                        '<span class="block text-slate-400 my-1">↓</span>'+
                        '<b>'+s.esc(toText)+'</b>'+
                    '</td>'+
                    '<td class="p-3 align-top text-xs" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<b>'+s.esc(v.reference||'—')+'</b>'+
                        '<span class="block mt-1 text-slate-400">'+
                            s.esc(dateText(v.voucher_date||v.created_at))+
                        '</span>'+
                    '</td>'+
                    '<td class="p-3 align-top text-xs" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<div>إنشاء → إرسال: <b>'+s.esc(durationText(createdToSent))+'</b></div>'+
                        '<div class="mt-1">إرسال → استلام: <b>'+s.esc(durationText(sentToReceived))+'</b></div>'+
                        '<div class="mt-1">استلام → إكمال: <b>'+s.esc(durationText(receivedToCompleted))+'</b></div>'+
                    '</td>'+
                    '<td class="p-3 align-top text-center" onclick="App.details('+s.esc(codeJs)+')">'+
                        '<span class="text-lg">›</span>'+
                    '</td>'+
                '</tr>'
            );

        }).join('');

    return(
        '<div class="card overflow-hidden">'+
        '<div class="px-3 py-3 border-b bg-slate-50 text-xs font-black flex justify-between gap-3 flex-wrap">'+
            '<span>'+
                (scope==='pending'
                    ?'الأذونات المعلقة'
                    :'الأذونات المكتملة')+
            '</span>'+
            '<span class="text-slate-400">اضغط على أي سطر لفتح مودال الإذن</span>'+
        '</div>'+
        '<div class="overflow-x-auto">'+
        '<table class="w-full text-right">'+
            '<thead class="bg-white">'+
                '<tr>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">الإذن</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">النوع / الحالة</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">من / إلى</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">المرجع / التاريخ</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">دورة الحياة</th>'+
                    '<th class="p-3 text-[10px] text-slate-500 whitespace-nowrap">فتح</th>'+
                '</tr>'+
            '</thead>'+
            '<tbody>'+
                body+
            '</tbody>'+
        '</table>'+
        '</div>'+
        '</div>'
    );
},
```

**لا توجد أزرار Edit/Delete/Send/Receive/Complete خارج المودال بعد هذا الاستبدال.**

---

# 14. T-14 — تفاصيل الإذن: نقل كل التحكم إلى داخل المودال

### العنصر المعيب

داخل:

`details:function(code)`

الموضع الحالي تقريبًا line 1653.

ابحث تحديدًا عن:

```javascript
var transferReceiver=
    v.type==='Transfer' &&
    v.status==='Sent' &&
    s.user&&
    s.user.id&&
    v.receiver_user_id&&
    String(s.user.id)===String(v.receiver_user_id);

var topActions=
```

واحذف هذا العنصر كاملًا حتى نهاية بناء `topActions`.

### البديل الكامل

```javascript
var transferReceiver=
    v.type==='Transfer' &&
    v.status==='Sent' &&
    s.user&&
    s.user.id&&
    v.receiver_user_id&&
    String(s.user.id)===String(v.receiver_user_id);

var act=s.actionFor(v);

var codeJs=
    JSON.stringify(
        String(v.voucher_code||'')
    );

var topActions=
    '<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">';

if(act==='draft'){

    topActions+=
        '<button type="button" onclick="App.editVoucher('+codeJs+')" class="px-3 py-2 rounded-xl bg-amber-500 text-white text-xs font-black">تعديل</button>'+
        '<button type="button" onclick="App.deleteVoucher('+codeJs+')" class="px-3 py-2 rounded-xl bg-rose-600 text-white text-xs font-black">حذف</button>'+
        '<button type="button" onclick="App.send('+codeJs+')" class="px-3 py-2 rounded-xl bg-indigo-600 text-white text-xs font-black">إرسال</button>'+
        '<button type="button" onclick="App.printDraftVoucher('+codeJs+')" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>';

}else if(act==='receive'){

    if(v.type==='Transfer'){

        topActions+=
            '<button type="button" onclick="App.receive('+codeJs+',true)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام كلي</button>'+
            '<button type="button" onclick="App.receive('+codeJs+',false)" class="px-3 py-2 rounded-xl bg-teal-600 text-white text-xs font-black">استلام تفصيلي</button>';

    }else{

        topActions+=
            '<button type="button" onclick="App.receive('+codeJs+',false)" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">استلام</button>';

    }

    topActions+=
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج بدون حفظ</button>';

}else if(act==='complete'){

    topActions+=
        '<button type="button" onclick="App.complete('+codeJs+')" class="px-3 py-2 rounded-xl bg-violet-600 text-white text-xs font-black">إكمال</button>'+
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exitVoucherDetails()" class="px-3 py-2 rounded-xl bg-slate-500 text-white text-xs font-black">خروج</button>';

}else{

    topActions+=
        '<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
        '<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>';

}

topActions+=
    '</div>';
```

ثم يبقى:

```javascript
showCloseButton:!transferReceiver
```

كما هو.

---

# 15. T-15 — Receive Modal: حفظ / استلام كلي / طباعة / خروج بدون حفظ

هذه النقطة غير مكتملة في Source الحالي رغم أن منطق الكميات الجزئية نفسه صحيح.

## الجزء الأول: مودال الاستلام الكلي

داخل `receive:function(code,full)` ابحث تحديدًا عن:

```javascript
return Swal.fire({
    title:'استلام كلي',
```

واستبدل **كتلة Swal.fire الكاملة** إلى نهاية `preConfirm`:

```javascript
return Swal.fire({
    title:'استلام كلي',
    html:fh,
    showDenyButton:true,
    denyButtonText:'🖨 طباعة',
    showCancelButton:true,
    confirmButtonText:
        'حفظ الاستلام الكلي',
    cancelButtonText:
        'خروج بدون حفظ',
    allowOutsideClick:false,
    preDeny:function(){

        Swal.close();

        setTimeout(function(){
            s.details(code);

            setTimeout(function(){
                s.printVoucher();
            },400);

        },80);

        return false;
    },
    preConfirm:function(){
        return [];
    }
});
```

## الجزء الثاني: مودال الاستلام التفصيلي

ابحث تحديدًا عن:

```javascript
return Swal.fire({
    title:'استلام '+s.esc(v.type),
```

واستبدل **كتلة Swal.fire الكاملة** حتى نهاية `preConfirm` بهذا:

```javascript
return Swal.fire({
    title:'استلام '+s.esc(v.type),
    html:h,
    showDenyButton:true,
    denyButtonText:'🖨 طباعة',
    showCancelButton:true,
    confirmButtonText:
        'حفظ الاستلام',
    cancelButtonText:
        'خروج بدون حفظ',
    allowOutsideClick:false,
    preDeny:function(){

        Swal.close();

        setTimeout(function(){
            s.details(code);

            setTimeout(function(){
                s.printVoucher();
            },400);

        },80);

        return false;
    },
    preConfirm:function(){

        var out=[];

        d.forEach(function(x,i){

            var el=
                RW_UI.byId(
                    'rq'+i
                );

            if(!el){
                return;
            }

            var q=
                Number(el.value||0);

            var m=
                Number(el.max||0);

            if(q<0||q>m){
                throw new Error(
                    'كمية غير صالحة'
                );
            }

            if(q){
                out.push({
                    itemId:x.item_id,
                    itemCode:x.item_code,
                    receivedQty:q
                });
            }

        });

        if(!out.length){

            Swal.showValidationMessage(
                'أدخل كمية استلام'
            );

            return false;
        }

        return out;
    }
});
```

### النتيجة

داخل مودال الاستلام نفسه:

- **حفظ الاستلام**
- **استلام كلي** من المودال الرئيسي
- **طباعة**
- **خروج بدون حفظ**

ولا يوجد أي تأثير على المخزون عند الخروج بدون حفظ.

---



---

## 17. ملفات Production التي تم تغييرها فعليًا

### تم تغيير قاعدة البيانات مباشرة

`public.post_manual_stock_voucher_atomic(...)`

تمت إضافة عقد DirectReturn RECEIVE.

### تم الحفاظ على

- `send-stock-voucher` v20.
- `receive-stock-voucher` v22.
- `post_manual_stock_voucher_atomic`.
- Trigger المسؤولية.
- core الحركة.

لم يتم إنشاء Edge جديدة.

---

## 18. Migration Source reconciliation

تم اكتشاف أن Migration السابقة:

`20260928120431_harden_transfer_partial_receive_actor_20260928`

موجودة في قاعدة البيانات لكن ملفها غير موجود في شجرة Git الحالية.

تمت إضافة ملف Migration إلى المستودع لتسوية:

`CURRENT DATABASE leftrightarrow CURRENT GIT`

دون إعادة تنفيذ التغيير على Production.

كما تم إضافة Migration جديدة لعقد DirectReturn.

---

## 19. Deployment Evidence

GitHub Actions:

Workflow:

`RAWAEA — Warehouse Vouchers Browser E2E`

Run:

53

Head:

`f07bdcc4abbbe899af569f8bfaccde04df279416`

النتيجة الحالية:

**failure**

والفشل الموثق:

`INLINE_SCRIPT_NOT_FOUND`

لا يجوز تحويل هذا الفشل إلى دليل على فشل Business Workflow.

ولا يجوز تعديل منطق النظام فقط لإرضاء Harness لم يحدد العنصر داخل الملف.

Browser E2E يظل **OPEN** حتى تُطبق حزمة T-09 → T-15 ثم يُعاد الاختبار على النسخة المنشورة.

---

## 20. Closure matrix

| العقد | الحالة |
|---|---|
| Transfer receiver binding | CLOSED |
| Partial Transfer RECEIVE security | CLOSED |
| DirectReturn RECEIVE actor contract | CLOSED |
| DirectReturn unauthorized regression | PASS |
| Owner wildcard contract | PRESERVED |
| Transfer source branch UI scope | READY — T-09/T-10 |
| Transfer destination UI scope | READY — T-11 |
| Action authority UI | READY — corrected T-12 |
| Pending table | READY — T-13 |
| Modal controls | READY — T-14 |
| Partial/full receive modal UX | READY — T-15 |
| Browser E2E | OPEN — source patch pending |
| `main.html` | UNTOUCHED |
| `vouchers.html` | UNTOUCHED |

---

## 21. تعليمات بدء الجلسة التالية

ابدأ دائمًا بالترتيب:

1. اقرأ `CURRENT_STATE.md`.
2. تحقق من أحدث System HEAD والـParent.
3. تحقق من أحدث Frontend HEAD والـParent.
4. تحقق من blob `vouchers.html`.
5. تحقق من Production migrations والـRPC/Trigger.
6. لا تعد فتح Transfer partial security؛ لقد أُغلق.
7. لا تستخدم `privileged` لتجاوز receiver binding.
8. لا تعد بناء `receive()`; هو موجود ويعمل.
9. تحقق أولًا من تطبيق T-09 → T-15 في Source.
10. بعدها Browser E2E.
11. بعد PASS فقط انتقل إلى أول Business Contract Gap غير مغلق.

---

## 22. Final forensic conclusion

الحالة الحالية ليست «الشاشة ناقصة فقط».

العقد الصحيح أصبح:

`UI responsibility`
→ `Auth identity`
→ `Existing Edge`
→ `Central RPC`
→ `Business guard`
→ `Inventory movement`
→ `Audit/operation identity`
→ `System-wide visibility`

والمشكلة الأمنية التي ظهرت أثناء المراجعة الحالية تم إغلاقها في Production دون Edge جديدة.

الـSource المتبقي هو **جراحة UI فقط** حسب T-09 → T-15.

لا يجوز إعادة إصلاح ما تم إغلاقه، ولا إعلان التبويب مغلقًا قبل تطبيق Source patch وإثبات Browser E2E.

---

## 23. Self Audit

- Latest report read: PASS
- CURRENT_STATE read: PASS
- latest system HEAD + parent verified: PASS
- latest frontend HEAD + parent verified: PASS
- current vouchers blob verified: PASS
- main.html untouched: PASS
- current Production RPC verified: PASS
- current Edge versions verified: PASS
- RPC EXECUTE surface verified: PASS
- RLS verified: PASS
- DirectReturn contract hardened: PASS
- DirectReturn unauthorized test: PASS
- DirectReturn authorized test: PASS
- test residue: 0
- competitor sources refreshed: PASS
- surgical Source changes delivered in this report: PASS
- Browser E2E: OPEN pending owner source application

