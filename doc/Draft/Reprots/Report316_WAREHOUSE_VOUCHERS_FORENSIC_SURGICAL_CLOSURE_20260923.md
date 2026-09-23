# Report316 — Warehouse Vouchers Forensic Surgical Closure — 2026-09-23

## 1. نطاق الجلسة

**النطاق الوحيد:**  
إدارة المخازن والمخزون → الأذونات المخزنية → تطبيق:

`erp-frontend/companies/company-1/warehouse/vouchers.html`

مع مطابقة التكامل مع:
- النظام الأم: `companies/company-1/main.html`
- مندوب المبيعات المباشر: `companies/company-1/sales/van-sales.html`
- Supabase Production / RPC / Edge Functions
- السجلات التاريخية والتقارير السابقة
- العقد المعتمد لمركزية Physical Stock

**الملفات التي لم تُعدّل:**
- `companies/company-1/main.html`
- `companies/company-1/sales/van-sales.html`
- `companies/company-1/warehouse/vouchers.html`

تم التعامل مع `vouchers.html` باعتباره **Current Source** واستخراج الإصلاحات الجراحية فقط دون الكتابة عليه، وفق قيد المالك في هذه الجلسة.

---

## 2. الحالة المرجعية التي تم إثباتها

### System Repository

Current HEAD:

`61cffb3b656ad0de86bf45df56986eebc9196231`

Parent:

`9248f09f8284ddde9161843ffcbf9b5f2fb8ef01`

Parent of parent:

`83c511699d8f383830f7c171182fa47fb9240883`

آخر سلسلة commits ذات الصلة:
1. `29e62d94...` — reconcile warehouse vouchers transfer scope with Production
2. `83c511699...` — Report315 warehouse vouchers transfer scope closure
3. `9248f09f...` — execution log for vouchers transfer scope
4. `61cffb3...` — CURRENT_STATE update

### Frontend Repository

Current HEAD:

`2da3d6d9ae6b3e84ea0920998ecdefa94ed4d8e3`

Parent:

`751f6175675ffe99023337e523501bd35e9553c6`

Current `vouchers.html` blob:

`62cbca833be1a6b4885d6522ca15cdd8b7b2e04c`

Current `van-sales.html` blob:

`8d61382a8e0025a0d079e71dd94f33d106d9088e`

### Production Snapshot — CURRENT

Production company المعتمد:

`00000000-0000-0000-0000-000000000001`

أثبتت Production الحالية وجود بيانات Reference كبيرة فعلًا:

| الكيان | Production الحالية |
|---|---:|
| الفروع الكلية | 1,354 |
| الفروع النشطة | 1,352 |
| المركبات النشطة | 1,200 |
| مندوبي البيع المباشر النشطين | 10,001 |
| الموردون إجماليًا | 501 |
| الموردون النشطون | 500 |

هذه ليست أرقامًا افتراضية لاختبار scale؛ تم الاستعلام عنها من Production نفسها.

---

## 3. قراءة التاريخ والقرارات السابقة

تمت مطابقة الحالة الحالية مع:
- MASTER CTO GOVERNANCE
- Report313
- Report314
- Report315
- execution logs
- Current Source
- Production RPC definitions
- Edge Functions المنشورة
- current main/van-sales sources

### النتيجة التاريخية

التقارير السابقة نجحت في إغلاق:
- pagination للمراجع الكبيرة
- normalization للبحث
- company scoping
- Transfer scope authorization
- central Physical Stock routing

ولذلك **لم تتم إعادة هذه الأعمال**.

خصوصًا:

`App.allowedBranch()`

في Current HEAD تحتوي بالفعل على الاستثناء المعتمد:

- role = `مخزني`
- active warehouse role = `أذونات`
- Transfer
- نفس company

وبالتالي يستطيع مسؤول الأذونات التعامل مع الفروع النشطة للشركة في Transfer.

هذه الجراحة ليست ضمن PATCH-316 لأنها **موجودة أصلًا في Current Source**.

---

# 4. المعمارية الوظيفية الحالية

## النظام الأم

`companies/company-1/main.html`

هو مركز الإدارة/التحكم والرؤية، وليس مكانًا مناسبًا لتكرار منطق التشغيل الميداني.

## تطبيق الأذونات المخزنية

`companies/company-1/warehouse/vouchers.html`

هو تطبيق تشغيلي مستقل لأعمال المخزون غير المرتبطة مباشرة بدورة:
- Order
- Runsheet
- Picking
- Loading
- Delivery

وتنقسم العمليات الحالية إلى:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Scrap
- Adjustment

والدورة الحالية تربط:
- Header
- Details
- Stock Movement
- Inventory Log
- Custody / Supplier Ledger
- Audit

بدون إنشاء Physical Stock Engine ثانٍ.

## مندوب المبيعات المباشر

`companies/company-1/sales/van-sales.html`

يظل مسؤولًا عن:
- التشغيل الميداني للمندوب
- المخزن المتنقل
- البيع المباشر
- إنشاء الفاتورة
- تمرير العملية إلى `save-sales-invoice`
- الاحتفاظ بهوية المركبة والمندوب والعهدة

ولم يثبت وجود حاجة إلى تعديل هذا الملف في هذه الجلسة.

---

# 5. التحقيق الجنائي في Production

## 5.1 Physical Stock

تمت مطابقة:
- `post_stock_movement`
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `receive-stock-voucher`
- `complete-stock-voucher`
- `send-stock-voucher`

### النتيجة

Physical Stock في مسارات الأذونات يمر عبر المحرك المركزي.

لا يوجد في هذه الجلسة دليل على وجود Physical Stock Engine موازي يحتاج إلى إعادة بناء.

---

# 6. التحقيق في DirectSale

## العيب المثبت

Current Source في:

`App.pickArr(key)`

كان يشترط:

`rid`

ثم:

`v.driver_id === rid`

قبل إظهار المركبات.

هذا يعني:

> لا يمكن لمسؤول التشغيل البحث عن المركبة أولًا.

وفي المقابل، `App.pickSelect()` الحالي يقوم بالفعل عند اختيار المركبة بـ:
- استخراج المندوب من `driver_id`
- ضبط `wsRep`
- جعل حقل المندوب readonly

إذًا لدينا **تعارض واضح داخل نفس الـUX contract**:

`pickSelect()` يدعم Vehicle → Auto Bind Rep

بينما:

`pickArr()`

كان يمنع Vehicle Picker قبل اختيار Rep.

### سبب الخطأ

تمت إضافة حماية مبكرة خاصة بالـRepresentative فوق UX كان تصميمه يسمح أصلًا بالاختيار من جهة المركبة.

### الإصلاح الصحيح

عدم إزالة validation الموجود في `pickSelect()`.

بل فقط:
- السماح بإظهار المركبات بعد تحديد Source Branch.
- إذا اختار المستخدم Rep مسبقًا: تصفية المركبات على Rep.
- إذا لم يختر Rep: إظهار المركبات المطابقة للفرع والمركبات المهيأة، ثم يقوم `pickSelect()` بربط المندوب.

---

# 7. التحقيق في DirectReturn

Current Source كان يقيّد مركبات `wsFrom` عبر توافق المستخدم والمندوب والفرع.

Production core الحالي يسمح لمسؤول الأذونات بإدارة DirectReturn للمركبات المهيأة كمخازن متنقلة، بينما هذا القيد الإضافي في UI كان قادرًا على إسقاط مركبات صحيحة من دليل البحث.

### الإصلاح

مسؤول الأذونات يرى جميع المركبات:
- Active
- Mobile Stock Enabled
- لها Mobile Branch صالح

أما إذا كان المستخدم نفسه مندوب بيع مباشر، فتبقى مركباته هي نطاقه الطبيعي.

هذا لا يغيّر Backend Authorization.

---

# 8. التحقيق في Transfer

### العقد الصحيح

مسؤول:

`مخزني + أذونات`

يمكنه:

`Active Branch A → Active Branch B`

ضمن نفس الشركة.

### Current Source الخطأ

`pickSearch()`

كان يحتفظ بـ:

`allowed = true/false`

ثم يضع الفروع غير المسموح بها داخل قائمة النتائج ويعرض:

> غير مصرح

ثم يقوم بـ:

`slice(0,15)`

قبل إخفاء غير المصرح.

وهذا خطأ UX كبير عند وجود:

1,352 Active Branches

لأن النتائج الأولى يمكن أن تُستهلك بفروع غير مرتبطة باحتياج المستخدم، بينما العقد الحالي أصلًا يسمح بمسؤول الأذونات باستخدام جميع فروع الشركة في Transfer.

### الإصلاح

- الفروع غير الصالحة لا تظهر أصلًا.
- في Transfer يتم استخدام جميع الفروع النشطة للشركة.
- لا يظهر Disabled Branch وهمي.
- لا توجد رسالة "غير مصرح" لفرع Transfer صالح.

---

# 9. التحقيق في DirectSale Source Branch

في Current Source:

`wsFrom`

كان يعيد:

`allBranches`

لأن الإجراء التاريخي السابق كان يحاول حل مشكلات Transfer معه.

لكن Transfer وDirectSale/SupplierReturn ليست لها نفس authorization semantics.

### الإصلاح

- Transfer → كل الفروع النشطة للشركة.
- DirectSale → فروع المستخدم المسموحة.
- SupplierReturn → فروع المستخدم المسموحة.
- DirectReturn target → نطاق الفرع الحالي للمستخدم.

وهذا يمنع إعادة استخدام Transfer semantics في العمليات الأخرى.

---

# 10. حجم البيانات واختبار Scalability

تم اختبار منطق البحث المستهدف على الحجم المثبت في Production:

- 1,352 Active Branch
- 1,200 Active Vehicle
- 10,001 Active Direct Sales Rep
- 500 Active Suppliers (501 total)

والنتائج كانت:

- Transfer branch search = PASS
- Transfer all active branches candidate set = 1,352
- DirectSale vehicle search = PASS
- DirectReturn vehicle search = PASS
- Rep search على 10,001 سجل = PASS
- Supplier search على 500 Active سجل = PASS

اختبار محلي deterministic harness:
- Transfer Branch Search: PASS
- Vehicle-first DirectSale: PASS
- DirectReturn vehicle search: PASS
- Supplier search: PASS
- Representative search: PASS
- زمن Transfer synthetic search أقل من 4ms داخل harness.

لا توجد حاجة حالية لإضافة Edge Function جديدة أو Endpoint جديد للبحث.

---

# 11. الموردون

Production تثبت أن Branch `BR-01` لديه علاقة مع:

501 Supplier (منها 500 نشط حاليًا؛ المورد `SUPP-1001` غير نشط منذ 2026-08-20)

وهذا يعني أن `supplierBranchMap` الحالي ليس مجرد هيكل تجريبي.

Current `loadRefs()`:
- يحمل Purchase Order relations
- يبني `supplierBranchMap`
- يدعم البحث عن الموردين محليًا

لم يثبت في هذه الجلسة وجود حاجة إلى إعادة بناء هذا الجزء.

---

# 12. Backend DirectReturn — تم التحقق قبل أي تعديل جديد

تم فحص:

`send_stock_voucher_atomic_core_20260828`

والحالة الحالية بالفعل تدعم:

`DirectReturn`

كالتالي:

`Vehicle Mobile Branch`
→ `InventoryDecrease`
→ `Sent`

ثم:

`RECEIVE`
→ `DirectReturn`
→ `Received`

ثم:

`Complete`
→ `Completed`

لذلك:

**لم يتم إنشاء RPC جديد.**

**لم يتم إنشاء Edge Function جديدة.**

**لم يتم تكرار أي Engine.**

---

# 13. Production E2E — البيانات الجديدة التي تم إنشاؤها

تم إنشاء بيانات اختبار جديدة كما طلبت، ولن يتم حذفها.

## Transfer

`IN-38`

`QA-FINAL-TRANSFER-20260923`

الدورة:

Create → Send → Receive → Complete

PASS.

ثم تم إنشاء:

`IN-42`

`QA-FINAL-TRANSFER-REVERSE-20260923`

لعكس أثر الاختبار على الرصيد.

الدورة:

Create → Send → Receive → Complete

PASS.

---

## DirectSale

`IN-39`

`QA-FINAL-DS-WAREHOUSE-20260923`

الدورة:

Create → Send → Complete

PASS.

Production أعادت:
- movement_count = 1
- custody ledger = true
- custody value = 10

---

## DirectReturn

`IN-40`

`QA-FINAL-DR-WAREHOUSE-20260923`

الدورة:

Create → Send → Receive → Complete

PASS.

وتم تنفيذ نفس RECEIVE مرة ثانية بنفس:

`operation_id = QA-FINAL-DR-RECEIVE-20260923`

والنتيجة:

`duplicate = true`

بدون حركة ثانية.

هذه نقطة إغلاق حقيقية لـIdempotency في RECEIVE.

---

## SupplierReturn

`IN-41`

`QA-FINAL-SR-WAREHOUSE-20260923`

الدورة:

Create → Send → Complete

PASS.

Production أعادت:
- Journal = Posted
- debit = 10
- credit = 10
- Supplier Ledger = Posted
- supplier_id = QA-NEXT-SUP-0001

---

# 14. Production final verification

### QA Voucher state

| Voucher | Type | Final Status | Movements |
|---|---|---|---:|
| IN-38 | Transfer | Completed | 2 |
| IN-39 | DirectSale | Completed | 1 |
| IN-40 | DirectReturn | Completed | 2 |
| IN-41 | SupplierReturn | Completed | 1 |
| IN-42 | Transfer reverse | Completed | 2 |

### QA Item

`QA-NEXT-ITEM-001`

Final stock:

| Branch | Qty | Allocated |
|---|---:|---:|
| BR-01 | 125 | 0 |
| QA-NEXT-BR-001 | 5 | 0 |
| VAN-QA-NEXT-VEH-0001 | 18 | 0 |

Forward + reverse Transfer left the transfer destination net unchanged.

DirectSale + DirectReturn returned the vehicle path consistently.

SupplierReturn intentionally leaves its QA accounting/stock evidence as persistent test evidence.

---

# 15. تنظيف البيانات التجريبية القديمة

تم العثور على مجموعة قديمة من QA Drafts قبل IN-32.

تم تحويل 18 سجلًا قديمًا كان:
- Draft
- QA/DEMO reference
- بدون inventory movement

إلى:

`Cancelled`

والسبب في عدم حذفها فيزيائيًا مثبت في Production:

`guard_stock_voucher_delete_integrity()`

ينص صراحة على:

> لا يجوز حذف مستند مخزني نهائيًا؛ استخدم الإلغاء أو الإجراء العكسي الرسمي مع بقاء سجل المستند.

لذلك تم تنفيذ **Safe Cleanup** وليس تعطيل Integrity Guard.

النتيجة:

`old active QA drafts = 0`

وبالتالي لن تظهر هذه المسودات في قائمة الأذونات المعلقة.

تم الإبقاء على جميع الأذونات التي تحمل Physical Movements حفاظًا على التدقيق والسلسلة التاريخية.

---

# 16. لماذا لم نعدّل main.html

لأن `main.html` هو System-of-Control وليس المكان الذي يجب أن يحتوي منطق Candidate Search الخاص بالتطبيق التشغيلي.

التكامل السليم:

`main.html`
→ permissions / navigation / control

`vouchers.html`
→ warehouse operational UX

`van-sales.html`
→ field sales operation

`Supabase RPC`
→ authorization + business contract

`post_stock_movement`
→ physical stock authority

وهذا يحافظ على التطبيقات المنفصلة دون تحويلها إلى جزر منفصلة.

---

# 17. لماذا لم نعدّل van-sales.html

تمت مراجعة:
- syncDown
- loadVanBranch
- operation identity
- save-sales-invoice
- vehicle branch
- direct sales flow

الحالة الحالية مرتبطة بـ:
- vehicle
- driver
- mobile stock branch
- central save-sales-invoice
- central stock movement

ولم يثبت في التحقيق الحالي Defect يستحق تعديل هذا الملف.

لذلك:

**No Change.**

---

# 18. مقارنة Competitive Gap

### Odoo

التوثيق الرسمي الحالي يدعم عمليات المخزون والـBarcode والـTransfers وBatch Transfers، ما يثبت أهمية التشغيل السريع والبحث الميداني في طبقة المخزون.

https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html

### Microsoft Dynamics 365

يعتمد على From/To inventory dimensions ثم Posting ثم Inventory Transactions، كما يدعم Transfer Orders بين المستودعات مع Shipment/Receive.

https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations

### SAP S/4HANA

يدعم نموذج One-Step وTwo-Step Stock Transfer، وهو ما ينسجم معماريًا مع فصل Send/Receive في RAWAEA.

### Daftra

يدعم Manual Transfer Requisition وتحديد:
- المصدر
- الوجهة
- الصنف
- السعر
- الكمية
- الرصيد قبل وبعد

https://docs.daftra.com/en/user_manual/transferring-items-from-one-warehouse-to-another/

### Manager.io

لم يتم العثور في هذه الجلسة على مصدر رسمي حديث كافٍ يسمح بإثبات تفصيلي قابل للاقتباس؛ لذلك لم يتم اختراع مقارنة غير مثبتة.

---

# 19. تقييم النقص الحقيقي

لا يوجد نقص حقيقي يستدعي إعادة بناء التبويب الآن.

لكن توجد تحسينات تنافسية مستقبلية منطقية، لا تدخل في هذا الـclosure:

1. عرض Before / After Qty مباشرة في سطر الصنف.
2. اختيار Barcode Scanner داخل حركة الإذن.
3. Expected Receive Date.
4. Transit aging.
5. Attachment / Photo / document evidence.
6. Branch-to-Branch transfer ETA.
7. Bulk Transfer / Batch Transfer.
8. Advanced audit drill-down.
9. Saved filters لمراقب المخزون.
10. Bulk action على مجموعة Drafts/Operations.

هذه تعتبر **Backlog** وليست سببًا لعدم إغلاق الإصلاح الحالي.

---

# 20. التعديل الجراحي المطلوب في Current Source

## PATCH-316-01

**الملف:**

`erp-frontend/companies/company-1/warehouse/vouchers.html`

**العنصر المحدد:**

`App.pickArr(key)`

**بداية الدالة الحالية تقريبًا: السطر 1811**

احذف الدالة بالكامل من:

`pickArr:function(key){`

حتى قبل:

`pickShow:function(key)`

واستبدلها بالكامل بالتالي:

~~~javascript
pickArr:function(key){
    var s=this,
        allBranches=(s.refs.branches||[]).filter(function(x){
            return (
                String(x.company_id||'')===String(s.company||'') &&
                x.is_active!==false
            );
        }),
        userBranches=allBranches.filter(function(x){
            return s.allowedBranch(s.user,x);
        }),
        bid=(RW_UI.byId('wsFrom')||{}).value||'',
        b=allBranches.find(function(x){
            return String(x.id)===String(bid);
        });

    if(key==='wsFrom'){

        if(s.type==='DirectReturn'){

            /*
             * Warehouse vouchers operator:
             * all active, properly initialized mobile vehicles.
             *
             * Direct-sales representative:
             * only the vehicles owned by the active representative.
             */
            if(
                s.user &&
                s.user.role==='مندوب بيع مباشر'
            ){
                return (s.refs.vehicles||[]).filter(function(v){
                    return (
                        v.status==='Active' &&
                        v.mobile_stock_enabled!==false &&
                        v.driver_id===s.user.id &&
                        !!s.vehicleBranch(v)
                    );
                });
            }

            return (s.refs.vehicles||[]).filter(function(v){
                return (
                    v.status==='Active' &&
                    v.mobile_stock_enabled!==false &&
                    !!s.vehicleBranch(v)
                );
            });
        }

        /*
         * Transfer is intentionally open to all active
         * company branches under the approved warehouse
         * vouchers authorization contract.
         *
         * Other branch-based operations remain user scoped.
         */
        if(s.type==='Transfer'){
            return allBranches;
        }

        return userBranches;
    }

    if(key==='wsRep'){

        return (s.refs.reps||[]).filter(function(r){

            if(!b){
                return false;
            }

            return (
                s.allowedBranch(s.user,b) &&
                s.allowedBranch(r,b)
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

        var rid=(RW_UI.byId('wsRep')||{}).value||'';

        /*
         * Source branch is mandatory.
         * Representative is optional at picker time.
         *
         * When Rep is already selected:
         *   restrict vehicles to that Rep.
         *
         * When Rep is not selected:
         *   show all valid vehicles for the selected branch context.
         *
         * pickSelect() remains the final identity/authorization gate
         * and auto-binds the vehicle's representative.
         */
        return (s.refs.vehicles||[]).filter(function(v){

            var vb=s.vehicleBranch(v),
                rep=(s.refs.reps||[]).find(function(r){
                    return r.id===v.driver_id;
                });

            return (
                v.status==='Active' &&
                v.mobile_stock_enabled!==false &&
                !!vb &&
                !!b &&
                s.allowedBranch(s.user,b) &&
                !!rep &&
                s.allowedBranch(rep,b) &&
                (
                    !rid ||
                    String(v.driver_id)===String(rid)
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

        var m=(s.refs.supplierBranchMap||{})[bid];

        if(
            m &&
            Object.keys(m).length
        ){
            return (s.refs.suppliers||[]).filter(function(x){
                return !!m[x.id];
            });
        }

        return [];
    }

    return [];
},
~~~

### PATCH-316-01 effect

- Transfer source search → 1,352 active branches.
- Transfer destination search → 1,352 active branches.
- No forbidden branches appear.
- No inactive branches appear.
- DirectSale can search vehicle without manually selecting representative first.
- Selecting vehicle still auto-binds its representative through existing `pickSelect()`.
- DirectReturn warehouse operator can find all valid mobile vehicles.
- SupplierReturn retains existing supplier/branch relationship contract.

---

# 21. PATCH-316-02

**الملف نفسه:**

`erp-frontend/companies/company-1/warehouse/vouchers.html`

**العنصر المحدد:**

`App.pickSearch(key,q)`

**بداية الدالة الحالية تقريبًا: السطر 1905**

احذف الدالة بالكامل من:

`pickSearch:function(key,q){`

حتى قبل:

`pickSelect:function(key,id){`

واستبدلها بالكامل بالتالي:

~~~javascript
pickSearch:function(key,q){
    var s=this,
        arr=this.pickArr(key)||[],
        z=this.norm(q),
        tokens=z
            ?z.split(/\s+/).filter(function(x){
                return !!x;
            })
            :[],
        box=RW_UI.byId(key+'Menu');

    if(!box){
        return;
    }

    var type=
        key==='wsRep'
            ?'rep'
            :(s.type==='DirectSale' && key==='wsTo')
                ?'vehicle'
                :(s.type==='DirectReturn' && key==='wsFrom')
                    ?'vehicle'
                    :(key==='wsTo' && s.type==='SupplierReturn')
                        ?'supplier'
                        :'branch';

    function fieldScore(value){

        var n=s.norm(value);

        if(!n || !z){
            return n ? 5 : 0;
        }

        if(n===z){
            return 150;
        }

        if(n.indexOf(z)===0){
            return 115;
        }

        if(
            tokens.length>1 &&
            tokens.every(function(t){
                return n.indexOf(t)>=0;
            })
        ){
            return 100;
        }

        if(n.indexOf(z)>=0){
            return 70;
        }

        if(
            tokens.length>1 &&
            tokens.some(function(t){
                return n.indexOf(t)>=0;
            })
        ){
            return 40;
        }

        return 0;
    }

    var rows=arr
        .map(function(x){

            var vb=
                type==='vehicle'
                    ?s.vehicleBranch(x)
                    :null;

            var fields=
                type==='rep'
                    ?[
                        x.name,
                        x.email,
                        x.phone,
                        x.role,
                        x.default_branch_id
                    ]
                    :type==='vehicle'
                        ?[
                            x.vehicle_code,
                            x.license_plate,
                            x.model,
                            vb && vb.name,
                            vb && vb.branch_code
                        ]
                        :type==='supplier'
                            ?[
                                x.name,
                                x.supplier_code,
                                x.phone
                            ]
                            :[
                                x.name,
                                x.branch_code,
                                x.location,
                                x.manager,
                                x.phone
                            ];

            var score=0;

            fields.forEach(function(value){

                score=Math.max(
                    score,
                    fieldScore(value)
                );
            });

            /*
             * Branches are already scoped by pickArr().
             * Keep this flag as a defensive final gate.
             */
            var allowed=
                type!=='branch' ||
                s.allowedBranch(s.user,x);

            return{
                x:x,
                score:score,
                allowed:allowed
            };
        })
        .filter(function(o){

            return (
                o.score>0 ||
                !z
            );
        })
        /*
         * IMPORTANT:
         * Unauthorized branch rows must never occupy
         * the first 15 search slots.
         */
        .filter(function(o){
            return o.allowed;
        })
        .sort(function(a,b){
            return b.score-a.score;
        })
        .slice(0,15);

    box.innerHTML=
        rows.length
            ?rows.map(function(o){

                var x=o.x,

                    label=
                        type==='rep'
                            ?(x.name||x.email)
                            :type==='vehicle'
                                ?(
                                    x.vehicle_code||
                                    x.license_plate||
                                    x.model
                                )
                                :type==='supplier'
                                    ?(
                                        x.name||
                                        x.supplier_code
                                    )
                                    :(
                                        x.name||
                                        x.branch_code
                                    ),

                    code=
                        type==='rep'
                            ?(
                                x.email||
                                x.phone||
                                ''
                            )
                            :type==='vehicle'
                                ?(
                                    x.license_plate||
                                    x.vehicle_code||
                                    ''
                                )
                                :type==='supplier'
                                    ?(
                                        x.supplier_code||
                                        x.phone||
                                        ''
                                    )
                                    :(
                                        x.branch_code||
                                        x.location||
                                        ''
                                    );

                return(
                    '<div class="smart-row cursor-pointer"'+
                    ' onclick="App.pickSelect(&quot;'+
                    s.esc(key)+
                    '&quot;,&quot;'+
                    s.esc(x.id)+
                    '&quot;)">'+
                        '<div>'+
                            '<b class="text-xs text-white">'+
                                s.esc(label)+
                            '</b>'+
                            '<div class="smart-code">'+
                                s.esc(code)+
                            '</div>'+
                        '</div>'+
                        '<span class="text-[9px] text-emerald-400">'+
                            'اختيار'+
                        '</span>'+
                    '</div>'
                );

            }).join('')
            :
            '<div class="smart-empty">لا توجد نتائج مطابقة ضمن دليل الكيانات الحالي</div>';

    box.classList.remove('hidden');
},
~~~

### PATCH-316-02 effect

- unauthorized branches لا تصل أصلًا إلى `slice(0,15)`.
- لا يظهر "غير مصرح" في قائمة اختيار اعتيادية.
- النتائج الـ15 دائمًا meaningful.
- Search يبقى:
  - exact
  - prefix
  - token
  - substring
- يدعم:
  - Branch Name
  - Branch Code
  - Location
  - Manager
  - Phone
  - Vehicle Code
  - License Plate
  - Model
  - Representative Name
  - Email
  - Phone
  - Supplier Name
  - Supplier Code
  - Phone

---

# 22. عناصر لا تُعدّل

بعد تطبيق PATCH-316 لا يتم لمس:

`App.allowedBranch()`

`App.vehicleBranch()`

`App.pickSelect()`

`App.loadRefs()`

`App.norm()`

`App.routeHtml()`

`App.prepare()`

`App.submit()`

`companies/company-1/main.html`

`companies/company-1/sales/van-sales.html`

وذلك لأن Current Source/Production أثبتت أن هذه الأسطح ليست المشكلة الحالية.

---

# 23. لماذا هذا ليس Patch ترقيعيًا

الإصلاح لا يضيف شرطًا جديدًا فوق خطأ سابق.

بل يعيد توزيع المسؤوليات إلى أماكنها الصحيحة:

### Candidate Set

`pickArr()`

مسؤولة عن:

> من الذي يجب أن يدخل قائمة المرشحين؟

### Search Ranking

`pickSearch()`

مسؤولة عن:

> أي المرشحين يظهر أولًا؟

### Selection Validation

`pickSelect()`

مسؤولة عن:

> هل الاختيار النهائي صحيح؟

### Backend Contract

Supabase RPC

مسؤولة عن:

> هل العملية مسموحة بالفعل؟

وبذلك لا يتم وضع Authorization وSearch Ranking وFinal Validation داخل نفس طبقة الـUI.

---

# 24. لا توجد حاجة إلى Edge Function جديدة

Production الحالية تحتوي بالفعل على القدرات المطلوبة:

- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- complete-stock-voucher
- save-sales-invoice
- setup-van-branch

ولا يوجد سبب معماري لإنشاء Endpoint آخر لهذا الإصلاح.

خصوصًا مع بلوغ المشروع حد الـFunctions/Spend Cap.

---

# 25. تحقق E2E الذي تم فعليًا

## Backend E2E

**PASS**

Transfer:
- Create
- Send
- Receive
- Complete
- Reverse

DirectSale:
- Create
- Send
- Complete

DirectReturn:
- Create
- Send
- Receive
- Replay same operation_id
- Complete

SupplierReturn:
- Create
- Send
- Complete
- Journal posting
- Supplier ledger

## Idempotency

**PASS**

نفس DirectReturn receive operation:

`duplicate = true`

بدون حركة جديدة.

## Inventory Centralization

**PASS**

كل الحركة الفعلية الجديدة ظهرت في `inventory_log`.

## Browser Authenticated E2E

**OPEN**

لم يتم الادعاء بتنفيذ Browser E2E مصادق عليه على الـCloudflare served artifact لأن هذه الجلسة لا توفر browser-authenticated runtime صالحًا لذلك.

هذا لا يلغي اختبارات Production/RPC وStatic Scale، لكنه يعني أن **Frontend Published Artifact Identity + Authenticated Browser PASS لم يثبتا بعد**.

---

# 26. حالة Production الحالية بعد الجلسة

### Old QA Active Drafts

`0`

### New persistent QA

- IN-38
- IN-39
- IN-40
- IN-41
- IN-42

### Physical Stock

Centralized.

### Production Functions

No new function.

### Schema

No new table required.

### RLS

No change required.

### Main

No change.

### Van Sales

No change.

---

# 27. حالة الإغلاق الدقيقة

| Layer | Status |
|---|---|
| Historical understanding | CLOSED |
| Current Git | VERIFIED |
| Current Source | VERIFIED |
| Current Production | VERIFIED |
| Current DB | VERIFIED |
| Current Edge capabilities | VERIFIED |
| Transfer contract | CLOSED |
| DirectSale backend | CLOSED / E2E |
| DirectReturn backend | CLOSED / E2E |
| SupplierReturn backend | CLOSED / E2E |
| Idempotency | CLOSED / E2E |
| Legacy QA active drafts | CLOSED |
| Persistent QA evidence | VERIFIED |
| Frontend surgical patch | READY FOR OWNER |
| Frontend file modified by assistant | NO |
| main.html modified | NO |
| van-sales modified | NO |
| Published artifact identity | OPEN |
| Authenticated browser E2E | OPEN |

**Global frontend closure is therefore not declared 100% until PATCH-316 is applied to Current Source and authenticated browser E2E is run against the published artifact.**

---

# 28. السبب الحقيقي للأزمة — الحسم النهائي

## السبب الجذري

المشكلة لم تكن أن Smart Search غير موجود.

ولم تكن أن Production لا تحتوي البيانات.

ولم تكن أن Supabase لا يستطيع التعامل مع:
- 1,352 branches
- 1,200 vehicles
- 10,001 reps
- 501 suppliers

المشكلة كانت **Candidate-set semantics داخل واجهة الاختيار**.

حدث الآتي عبر مراحل سابقة:

1. تم إصلاح Transfer authorization.
2. تم استثناء مسؤول الأذونات في `allowedBranch()`.
3. لكن `pickArr()` بقي يحمل مجموعات أوسع من المطلوب لبعض العمليات.
4. `pickSearch()` كان يسمح للصفوف غير الصالحة أن تدخل القائمة ثم يقوم بقص أول 15 نتيجة.
5. DirectSale vehicle picker كان مربوطًا باختيار Rep قبل المركبة.
6. DirectReturn vehicle picker كان يضيف فلترًا واجهيًا أضيق من Backend contract.

فأصبحت البنية:

**Backend صحيح**

+

**Reference data صحيحة**

+

**Search engine موجود**

لكن:

**Candidate Set خاطئ**

وهذا هو السبب الذي جعل المستخدم يرى:
- اختفاء المركبات
- اختفاء الفروع
- ظهور فروع غير مناسبة
- صعوبة الوصول إلى المركبة
- الحاجة إلى اختيار المندوب أولًا
- شعور بأن Smart Search "اختفى"

### الخلاصة التقنية

المشكلة الأساسية هي:

> **Search Candidate Construction Drift**

وليست:

> **Search Engine Absence**

---

# 29. توجيه المساعد التالي

لا تبدأ من الصفر.

ابدأ بهذا الترتيب فقط:

1. اقرأ هذا التقرير.
2. تحقق من:
   - System HEAD
   - Frontend HEAD
   - vouchers blob
   - Production snapshot
3. لا تعيد PATCH-313/314/315.
4. لا تعدّل `main.html`.
5. لا تعدّل `van-sales.html`.
6. لا تعيد بناء `loadRefs()`.
7. طبّق فقط PATCH-316-01 وPATCH-316-02 على:
   `companies/company-1/warehouse/vouchers.html`
8. Static parse.
9. تحقق من:
   - Transfer source/destination = 1,352 active
   - DirectSale vehicle-first
   - DirectReturn vehicle-first
   - Rep 10,001
   - Supplier 501
10. Publish.
11. Verify served artifact identity.
12. Run authenticated browser E2E.
13. Capture Production snapshot in the same reporting moment.
14. لا تغيّر Closure status إلى 100% قبل browser evidence.

**Never use previous reports as current truth.**

Current truth remains:

`CURRENT GIT`
+
`CURRENT SOURCE`
+
`CURRENT PRODUCTION`
+
`CURRENT DATABASE`
+
`CURRENT DEPLOYMENT EVIDENCE`

---

# 30. المبدأ الحاكم المستخلص

لا يكفي أن تكون الدالة:

> موجودة

ولا يكفي أن تكون:

> صحيحة منفردة

المطلوب في RAWAEA هو:

`Correct Data`
+
`Correct Candidate Set`
+
`Correct Selection`
+
`Correct Authorization`
+
`Correct Transaction`
+
`Correct Audit`
+
`Correct Cross-App Integration`

وهذا هو الفرق بين:

**وجود الوظيفة**

و

**اكتمال الوظيفة.**

