# تقرير 315 — إغلاق تكاملي لتدفق الأذونات المخزنية ورفع نطاق Transfer للمخزني

## التاريخ
2026-09-23

## النطاق
Warehouse → Inventory Management → Stock Vouchers

تم التحقيق في:
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Smart Search
- Branch authorization
- Vehicle / representative / supplier references
- التكامل مع Mother ERP وVan Sales
- Production RPC workflow
- Persistent QA
- E2E

---

## 1. قاعدة الحوكمة

تم البدء من آخر حالة مثبتة، لا من الصفر.

مصادر الحقيقة:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت لاستعادة السياق فقط ثم تمت مطابقتها مع الواقع الحالي.

---

## 2. Git baseline

System:
- HEAD قبل التنفيذ: b3cc3c7fe405e502c243f4d74ac5680304e5259e
- Parent: 23ff77cf170771221293163e938d708c51ea5032

Frontend:
- HEAD: 751f6175675ffe99023337e523501bd35e9553c6
- Parent: f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3
- vouchers blob: 751e7b4fc814dd7011ee903e1703dc8df9896f0c
- van-sales reference: 8d61382a8e0025a0d079e71dd94f33d106d9088e

الـfrontend HEAD الأخير يحتوي بالفعل على:
- pagination 500 rows
- smart search
- إصلاحات parser السابقة

ولذلك لم تُعاد هذه الإصلاحات.

---

## 3. الدور المعماري

Mother ERP:
Control / Governance / Monitoring Surface

Standalone Vouchers:
Operational execution surface للعمليات المخزنية غير المرتبطة مباشرة بدورة Order/Runsheet.

Van Sales:
Field Sales + Vehicle Custody + Mobile Inventory + Offline/Mobile execution.

الدورة الميدانية:
Order → Picking → Loading → Delivery → Return

تظل منفصلة عن Voucher UI.

---

## 4. Business Contracts

Transfer:
Branch → Branch

DirectSale:
Branch → Vehicle

DirectReturn:
Vehicle → Branch

SupplierReturn:
Branch → Supplier

الـPhysical Stock:
Physical Movement
→ post_stock_movement
→ stock_branches + inventory_log

لم يتم إنشاء Physical Stock Engine موازٍ.

---

## 5. Current Source investigation

Smart-search موجود بالفعل في current vouchers.html.

Vehicle search:
- vehicle_code
- license_plate
- model
- mobile branch name/code

Representative:
- name
- email
- phone
- role
- default_branch_id

Supplier:
- name
- supplier_code
- phone

Branch:
- name
- branch_code
- location
- manager
- phone

loadRefs() يستخدم pagination بحجم 500.

لذلك لا يوجد مبرر لإعادة فتح loadRefs أو search engine.

---

## 6. الحقيقة الجنائية لمشكلة Branch Search

App.pickArr() الحالي يعطي Transfer:
- wsFrom → allBranches
- wsTo → allBranches

وهذا أصبح صحيحًا بالنسبة للعقد الحالي.

الخطأ كان في Authorization Lens داخل App.allowedBranch().

المستخدم:
vouchers@rawaea.com

له:
role = مخزني
active_warehouse_role = أذونات
allowed_branch_ids = BR-01

وكانت الدالة تفسر BR-2 وغيره كفرع غير مسموح حتى في Transfer.

النتيجة الظاهرة:
- الفرع يظهر
- البحث موجود
- لكن العنصر يظهر "غير مصرح"
- ثم Backend يرفض

إذن المشكلة النهائية:
BUSINESS AUTHORIZATION CONTRACT DRIFT

وليست:
Search Engine Failure

وليست:
Missing Data

وليست:
Pagination Failure

---

## 7. تناقض Report314

Report314 كان قد أوصى سابقًا:
allBranches → userBranches

لكن ذلك كان لحماية Visibility من الفروع غير المصرح بها تحت العقد القديم.

طلب المالك الحالي غيّر العقد صراحة إلى:
المخزني صاحب active_warehouse_role = أذونات
→ التحويل بين فروع الشركة.

لذلك:
PATCH314 لم يُعاد تطبيقه.

---

## 8. Production change

تم إصلاح أربع حدود Production:

1. create_manual_stock_voucher_atomic(10 args)
2. create_manual_stock_voucher_atomic(12 args)
3. send_stock_voucher_atomic
4. post_manual_stock_voucher_atomic

الاستثناء المضاف حصري:
type = Transfer
+
role = مخزني
+
active_warehouse_role = أذونات

ويظل company scope إلزاميًا.

لم يتم فتح هذا الاستثناء لـ:
- DirectSale
- DirectReturn
- SupplierReturn
- المستخدمين الآخرين

---

## 9. Edge Functions

لم يتم إنشاء Edge Function جديدة.

الحالي:
create-stock-voucher
→ create_manual_stock_voucher_atomic

send-stock-voucher
→ send_stock_voucher_atomic

receive-stock-voucher
→ post_manual_stock_voucher_atomic

وهذا هو المسار المطلوب تحت Functions/Spend Cap.

---

## 10. Persistent QA

تم الإبقاء على:
IN-28
IN-29
IN-30
IN-31

وتم إنشاء:
IN-32
IN-33

كل بيانات QA الحالية مقصودة للبقاء ولا يتم حذفها.

---

## 11. Forward E2E

IN-32

Reference:
QA-TRANSFER-ALL-BRANCHES-20260923

User:
vouchers@rawaea.com

From:
BR-01

To:
BR-2

Item:
1001

Qty:
1

Operation:
QA-OP-TRANSFER-ALL-BRANCHES-20260923-01

نتائج Production:
Create = PASS
Send = PASS
Receive = PASS
Complete = PASS

Final:
Completed

Inventory Log:
2 rows
TransferOut + TransferIn

---

## 12. Reverse E2E

IN-33

Reference:
QA-TRANSFER-REVERSE-20260923

From:
BR-2

To:
BR-01

User:
vouchers@rawaea.com

نتائج:
Create = PASS
Send = PASS
Receive = PASS
Complete = PASS

Final:
Completed

Inventory Log:
2 rows

وهذا يثبت الاتجاهين.

---

## 13. Idempotency

تم إعادة نفس operation_id الخاص بـIN-32 بنفس fingerprint.

النتيجة:
لا Voucher إضافي.

عدد السجلات:
QA-TRANSFER-ALL-BRANCHES-20260923 = 1

---

## 14. Unauthorized actor

المستخدم:
vansales@rawaea.com

حاول:
BR-01 → BR-2

النتيجة:
REJECTED

السبب:
الفرع خارج نطاق فروع المستخدم المسموح بها

وهذا يثبت أن الاستثناء ليس صلاحية عامة.

---

## 15. Stock conservation

قبل عمليات IN-32/IN-33:
Item 1001 total = 79

بعد:
BR-01 = 2
BR-2 = 0
Vehicle QA = 77
Vehicle Test = 0

الإجمالي = 79

إذن:
Forward Transfer + Reverse Transfer
لم يغيرا ملكية الشركة الكلية.

---

## 16. Audit

IN-32:
4 audit rows

IN-33:
4 audit rows

لم تُحذف بيانات تاريخية.

---

## 17. Production final snapshot

companies = 1
branches = 4
vehicles = 2
suppliers = 1
direct_reps = 1
stock_vouchers = 33
stock_voucher_details = 35
inventory_log = 30
audit_log = 2123

هذا هو snapshot النهائي بعد التنفيذ.

---

## 18. مقارنة الأنظمة المنافسة

Odoo 19 يعرض Moves History بسجلات تشمل التاريخ والمرجع والمنتج والمصدر والوجهة والكمية والحالة، ويدعم عمليات النقل بالباركود. كما يميز Internal Moves عن العمليات التي تغير الكمية المملوكة للشركة. citeturn682741search1turn682741search3turn682741search2

Dynamics 365 يستخدم Transfer Journal مع From/To dimensions ثم Posting ومراجعة Inventory Transactions. citeturn682741search0

الاستنتاج المعماري لـRAWAEA:
- Transfer يجب أن يبقى عقدًا مستقلًا عن Sale.
- From/To جزء من transaction identity.
- البحث القوي يجب أن يصل إلى الكيان الصحيح بسرعة.
- سجل الحركة والتحقيق اللاحق يجب أن يكونا جزءًا من المنظومة وليس الشاشة فقط.

عناصر التنافسية التالية:
- Available Before / After
- Timeline
- Barcode execution
- Advanced filtering
- Attachments / approval عند فتح عقد مستقل
- Lot / Serial / Expiry عند فتح عقد مستقل

لم تتم إضافتها كترقيعات داخل هذه الجلسة.

---

## 19. Owner Surgical Patch

### الملف
companies/company-1/warehouse/vouchers.html

### Current SHA
751e7b4fc814dd7011ee903e1703dc8df9896f0c

### العنصر
App.allowedBranch

### النطاق
تقريبًا السطر 1700

### الإجراء
ابحث عن:
allowedBranch:function(u,b)

واحذف الدالة كاملة.

ثم استبدلها بالكامل بـ:

~~~javascript
allowedBranch:function(u,b){
    if(!u||!b)return false;

    if(
        this.type==='Transfer' &&
        u.role==='مخزني' &&
        u.activeWarehouseRole==='أذونات' &&
        String(b.company_id||'')===String(this.company||'')
    ){
        return true;
    }

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
~~~

### لا تعدل في vouchers.html
- loadRefs()
- pickArr()
- pickSearch()
- pickSelect()
- vehicleBranch()
- norm()
- routeHtml()
- submit()
- prepare()

### لا تعدل
- main.html
- van-sales.html

---

## 20. Why this owner patch is sufficient

Transfer candidates already come from:
allBranches

لذلك لا توجد حاجة لتغيير:
pickArr()

بعد تغيير Authorization Lens:
Transfer
+
مخزني
+
أذونات
+
نفس الشركة
=
Authorized

وتستمر بقية أنواع العمليات بقواعدها الحالية.

---

## 21. Production reproducibility

تم إنشاء:

supabase/migrations/20260923_vouchers_transfer_scope_authorization_reconciliation.sql

Commit:
29e62d94fdb45de86bc61c4a2d5e7f5412e69deb

هذا الملف يوثق الـProduction contract النهائي القابل لإعادة البناء.

---

## 22. ما لم يتم تغييره

- main.html
- vouchers.html
- van-sales.html
- Physical Stock Engine
- loadRefs()
- pickArr()
- pickSearch()
- pickSelect()
- vehicleBranch()

عدم تغييرها كان قرارًا قائمًا على الأدلة الحالية.

---

## 23. E2E status

### Production RPC E2E
CLOSED / VERIFIED

### Forward Transfer
CLOSED / VERIFIED

### Reverse Transfer
CLOSED / VERIFIED

### Idempotency
PASS

### Unauthorized actor
PASS / REJECTED

### Stock conservation
PASS

### Audit
PASS

### Authenticated Browser E2E
OPEN

السبب:
لا توجد في هذه الجلسة أداة Browser مصادق لتنفيذ login حقيقي على الـserved frontend.

لا يتم تحويل RPC E2E إلى Browser PASS.

---

## 24. Closure status

Production Transfer Contract:
CLOSED

Production Transfer E2E:
CLOSED / VERIFIED

Backend:
CLOSED / VERIFIED

Frontend source:
OWNER PATCH READY

Published artifact:
OPEN

Authenticated Browser E2E:
OPEN

Warehouse Vouchers capability:
PARTIALLY CLOSED

---

## 25. Final Self-Audit

### What I Proved
- Smart search موجود.
- pagination موجود.
- previous patches لم تُعاد.
- سبب المشكلة الحالي هو authorization contract drift.
- Create/Send/Receive كلها تستخدم نفس Transfer exception.
- الاتجاهان يعملان.
- المستخدم غير المخول ما زال مرفوضًا.
- المخزون الكلي محفوظ.
- Audit محفوظ.
- لا توجد Edge Function جديدة.

### What I Fixed
Production:
- create_manual_stock_voucher_atomic
- create_manual_stock_voucher_atomic(12 args)
- send_stock_voucher_atomic
- post_manual_stock_voucher_atomic

### What I Did Not Modify
- main.html
- vouchers.html
- van-sales.html

### What Remains
Owner source patch
+
Publish
+
Authenticated Browser E2E
+
Served Artifact Verification

---

## 26. NEXT EXACT RESUMPTION POINT

1. Verify current frontend HEAD.
2. Verify vouchers blob.
3. Apply only App.allowedBranch replacement.
4. Static parse.
5. Publish frontend.
6. Verify served artifact identity.
7. Run authenticated browser E2E.
8. Test Transfer source and destination branch search.
9. Confirm all company branches selectable for vouchers role.
10. Re-test DirectSale vehicle code + Arabic plate.
11. Re-test DirectReturn vehicle code + Arabic plate.
12. Re-test SupplierReturn supplier search.
13. Verify Draft creation remains zero Physical Movements.
14. Capture fresh Production snapshot.
15. Update CURRENT_STATE and final closure.

---

## 27. إرشادات المساعد التالي

لا تبدأ من الصفر.

لا تعيد:
- Report313
- Report314
- pagination
- smart-search
- vehicleBranch
- pickArr
- pickSearch

إلا إذا ظهر دليل جديد.

ابدأ من:
CURRENT_STATE
+
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT

ثم:
Owner Patch
→ Parse
→ Publish
→ Browser E2E
→ Served Artifact
→ Fresh Production Snapshot
→ CURRENT_STATE

وعند ظهور مشكلة جديدة في البحث:
افصل دائمًا بين:
Candidate Loading
Authorization Visibility
Search Algorithm
Backend Authorization

قبل أي تعديل.

## END
