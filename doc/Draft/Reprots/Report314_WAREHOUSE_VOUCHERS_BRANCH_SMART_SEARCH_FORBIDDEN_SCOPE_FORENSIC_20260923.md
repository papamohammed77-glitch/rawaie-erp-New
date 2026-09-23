# تقرير 314 — التحقيق الجنائي وإغلاق فجوة نطاق البحث الذكي في تطبيق الأذونات المخزنية
## التاريخ: 2026-09-23
## النطاق: Warehouse → Inventory Management → Stock Vouchers → Transfer / DirectSale / DirectReturn
## الحالة: PRODUCTION VERIFIED / CURRENT SOURCE VERIFIED / ROOT CAUSE PROVEN / SURGICAL OWNER PATCH READY / PERSISTENT QA VERIFIED / BROWSER E2E OPEN

---

## 1. قاعدة الحوكمة

تم البدء من آخر حالة مثبتة، وليس من الصفر، ولم تتم إعادة فتح إصلاحات ثبت إغلاقها في Reports 300–313.

مصادر الحقيقة لهذه الجلسة:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت لاستعادة السياق التاريخي فقط، ثم تمت مطابقتها مع المصدر الحالي وProduction الحالية.

النطاق مقصور على تطبيق:

companies/company-1/warehouse/vouchers.html

ولم يتم تعديل:

- companies/company-1/main.html
- companies/company-1/sales/van-sales.html
- companies/company-1/warehouse/vouchers.html

أي أن هذه الجلسة لا تحتوي على Owner Source Write في تطبيق الأذونات.

---

## 2. آخر Git والـparent

### System repository

Repository:
papamohammed77-glitch/rawaie-erp-New

Current HEAD:
b3cc3c7fe405e502c243f4d74ac5680304e5259e

HEAD message:
CTO: reconcile CURRENT_STATE checkpoint for Report313

HEAD parent:
23ff77cf170771221293163e938d708c51ea5032

### Frontend repository

Repository:
papamohammed77-glitch/erp-frontend

Current HEAD:
751f6175675ffe99023337e523501bd35e9553c6

HEAD message:
Update vouchers.html

HEAD parent:
f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3

Current vouchers.html blob:
751e7b4fc814dd7011ee903e1703dc8df9896f0c

Current van-sales.html reference remains:
8d61382a8e0025a0d079e71dd94f33d106d9088e

### نتيجة الـcommit lineage

الـfrontend HEAD الأخير هو بالفعل Update vouchers.html ويحتوي على تحديثات البحث الذكي والpagination/ordering، لذلك لا يجوز إعادة تطبيق إصلاحات Report313 السابقة عليه.

---

## 3. استعادة دور التطبيق في النظام الأم

### Mother ERP

النظام الأم يحتوي داخل RW_Warehouse على:

- loadVouchers()
- loadVoucherForm('Transfer')
- loadVoucherForm('DirectSale')
- loadVoucherForm('DirectReturn')
- loadVoucherForm('SupplierReturn')
- inventory/count/reporting/routing functions

والـRW_Views يربط:

vouchers
→ RW_Warehouse.loadVouchers()

transfer
→ RW_Warehouse.loadVoucherForm('Transfer')

direct-sale
→ RW_Warehouse.loadVoucherForm('DirectSale')

direct-return
→ RW_Warehouse.loadVoucherForm('DirectReturn')

supplier-return
→ RW_Warehouse.loadVoucherForm('SupplierReturn')

### Standalone Vouchers App

التطبيق المنفصل هو Execution Surface للعمليات المخزنية غير المرتبطة مباشرة بدورة Order/Runsheet:

Transfer
DirectSale
DirectReturn
SupplierReturn
والوظائف المخزنية غير المرتبطة مباشرة بالتسليم.

التدفق المعتمد:

Mother ERP
→ Warehouse / Inventory
→ Stock Vouchers
→ Existing RPC/Capability
→ Canonical Stock Contract
→ post_stock_movement
→ stock_branches + inventory_log
→ Audit / KPI / Accounting / Custody effects

### Order / Runsheet

تبقى دورة:

Order
→ Picking
→ Loading
→ Delivery
→ Return

مستقلة عن Voucher UI، ولا يوجد مبرر لدمجها داخل هذا الإغلاق.

### Van Sales

Van Sales هو Field Sales + Vehicle Custody + Mobile Inventory.

ثبت من المصدر الحالي أنه يستخدم:

setup-van-branch
save-sales-invoice
save-inventory-count

ويحمل هوية السيارة/المندوب من العقد الحالي.

لم يظهر عيب جديد في Van Sales يستوجب تعديله في هذه الجولة.

---

## 4. Business Contract للأذونات

### Transfer

Branch
→ Branch

### DirectSale

Branch
→ Vehicle

والمركبة يجب أن تكون:

Active
+
mobile_stock_enabled
+
مرتبطة بمندوب البيع المباشر الصحيح
+
المندوب مصرح له بفرع المصدر

### DirectReturn

Vehicle
→ Branch

المركبة يجب أن تكون:

Active
+
mobile_stock_enabled
+
مهيأة كمخزن متنقل

### SupplierReturn

Branch
→ Supplier

وعلاقة المورد بفرع المصدر يجب أن تكون موجودة ضمن العقد الحالي.

لا يجوز لهذه الجلسة تغيير هذه العقود.

---

## 5. Current Production Snapshot

تم الالتقاط عند:

2026-09-23 05:45:45.724837+00

Company:
00000000-0000-0000-0000-000000000001

Counters:

companies = 1
branches = 4
vehicles = 2
suppliers = 1
direct_reps = 1
stock_vouchers = 31
stock_voucher_details = 33
inventory_log = 26
audit_log = 2115

هذه القيم هي Production الحالية لحظة الإغلاق، وليست قيم التقرير التاريخي.

---

## 6. Production identities المستخدمة في التحقيق

### Branches

BR-01
id = a38332b6-6cea-480a-ada1-6eb6ab0590db
name = الفرع الرئيسي
status = Active

BR-2
id = f1bb941a-5a83-46fb-8ba3-4f0aa0c1edd2
name = فرع إسكندرية
status = Active

VAN-VCH-QA-260922
id = d1b1ea56-5674-4e5e-9733-5f5b11c88f13
status = Active

VAN-VEH-TEST-260921
id = 5372503d-f638-4e7f-808d-bda585825b2f
status = Active

### Vehicles

VCH-QA-260922
id = 61dc5bd4-2d78-473e-b62b-a36bca0b45bf
license_plate = س م ج 26922
model = QA Van
driver_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
mobile_stock_enabled = true

VEH-TEST-260921
id = 5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8
license_plate = س ن ر 6021
model = Suzuki Carry 2024
driver_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
mobile_stock_enabled = true

### Direct Sales Representative

id = 111b0730-a977-4d11-bcd0-2427b178a9e5
email = vansales@rawaea.com
role = مندوب بيع مباشر
status = Active
allowed_branch_ids = BR-01
permissions = ["van-sales"]

### Supplier

id = 87c5a847-8e05-492e-a15d-30e0a5cc93cc
supplier_code = SUPP-1001
name = ابراهيم الأبيض
status = Active

---

## 7. التحقيق الجنائي في Current vouchers.html

### العناصر الحالية التي يجب عدم إعادة إصلاحها

Current source يثبت وجود:

App.loadRefs()
App.allowedBranch()
App.vehicleBranch()
App.pickArr()
App.pickSearch()
App.pickSelect()

كما أن search engine الحالي يبحث في:

### Vehicle

vehicle_code
license_plate
model
mobile branch name/code

### Representative

name
email
phone
role
default_branch_id

### Supplier

name
supplier_code
phone

### Branch

name
branch_code
location
manager
phone

إذن البحث الذكي لم يُحذف من المصدر الحالي.

---

## 8. Scalability — لا تعاد

Current App.loadRefs() يستخدم pagination صراحة:

pageSize = 500

وreadAll(makeQuery) يكرر:

.range(offset, offset + pageSize - 1)

لتحميل:

branches
vehicles
suppliers
direct-sales reps
purchase_orders

وكلها Company-scoped.

بالتالي:

100+ branch
1000+ vehicle
1000+ supplier
10000+ representative

لم تعد تعتمد على SELECT واحد مقطوع عند حد الاستجابة.

هذه الجراحة مثبتة بالفعل في Current HEAD ولا يجوز إعادتها.

---

## 9. ROOT CAUSE الحالي — Branch Search

### العنصر المعيب بالتحديد

File:

companies/company-1/warehouse/vouchers.html

Function:

App.pickArr(key)

Current code:

~~~javascript
if(key==='wsFrom'){
    if(s.type==='DirectReturn'){
        ...
    }

    return allBranches;
}
~~~

وكذلك:

~~~javascript
if(key==='wsTo'&&s.type==='Transfer'){
    return allBranches;
}
~~~

### أثر ذلك

Current pickSearch() يعمل على:

arr = this.pickArr(key) || []

وعندما تكون الحركة:

Transfer
أو
DirectSale source branch
أو
SupplierReturn source branch

تأتي قائمة الفروع من:

allBranches

وليس:

userBranches

وبالتالي يتم إرسال الفروع المحظورة إلى طبقة البحث نفسها.

الـUI يحاول بعد ذلك تعليم بعضها:

غير مصرح

بدل عدم عرضها أصلًا.

هذا يتعارض مع متطلب UX الحالي:

لا تظهر للمستخدم فروع محظورة أثناء البحث أو الاختيار.

### الدليل الحتمي

باستخدام نفس منطق App.pickArr() مع Production-like reference set:

قبل الجراحة:

wsFrom Transfer
=
BR-01
BR-2
VAN-VCH-QA-260922
VAN-VEH-TEST-260921

wsTo Transfer
=
BR-01
BR-2
VAN-VCH-QA-260922
VAN-VEH-TEST-260921

وبعد استبدال returns المحددة من allBranches إلى userBranches:

wsFrom Transfer
=
BR-01

wsTo Transfer
=
BR-01

مع مستخدم نطاقه:

allowed_branch_ids = BR-01

PASS.

---

## 10. Backend authorization — لا يتم توسيعه

تم اختبار محاولة Transfer من:

vouchers@rawaea.com

من BR-01

إلى BR-2

والـProduction RPC رفضت العملية بالرسالة:

الفرع خارج نطاق فروع المستخدم المسموح بها

هذا يثبت:

Backend Authorization = صحيح

ولا يجوز علاج مشكلة UI بتوسيع صلاحيات النقل.

الهدف هنا:

UI visibility
=
Authorized candidates only

Server authorization
=
يبقى الحارس النهائي

ولا يوجد override.

---

## 11. البحث الذكي — E2E حتمي على Current Source

تم اختبار Current pickSearch() على نفس بنية المصدر الحالي.

### DirectSale vehicle

البحث:

VCH-QA-260922

النتيجة:
PASS

البحث:

س م ج 26922

النتيجة:
PASS

### DirectReturn vehicle

البحث:

VEH-TEST-260921

النتيجة:
PASS

البحث:

س ن ر 6021

النتيجة:
PASS

### Representative

البحث:

vansales@rawaea.com

النتيجة:
PASS

### Supplier

البحث:

SUPP-1001

النتيجة:
PASS

والبحث:

ابراهيم

النتيجة:
PASS

### Branch

البحث:

BR-01

النتيجة:
PASS

إذن البحث الذكي للمركبات والمندوب والمورد والفروع موجود ويعمل في Current Source.

المشكلة الحالية ليست فقدان search engine.

المشكلة هي مجموعة branch candidates التي تدخل search engine.

---

## 12. Persistent Production QA

حسب طلب المالك:

لم يتم حذف بيانات الاختبار.

تم إنشاء وحفظ:

### IN-28

Type:
Transfer

Status:
Draft

Reference:
QA-SEARCH-BRANCH-20260923

From:
BR-01

To:
BR-2

Created by:
owner@alrawae.com

### IN-29

Type:
DirectSale

Status:
Draft

Reference:
QA-SEARCH-VEHICLE-DS-20260923

Vehicle:
VCH-QA-260922

Created by:
vouchers@rawaea.com

### IN-30

Type:
DirectReturn

Status:
Draft

Reference:
QA-SEARCH-VEHICLE-DR-20260923

Vehicle:
VCH-QA-260922

Created by:
vouchers@rawaea.com

### IN-31

Type:
SupplierReturn

Status:
Draft

Reference:
QA-SEARCH-SUPPLIER-20260923

Supplier:
SUPP-1001

Created by:
vouchers@rawaea.com

### QA integrity

QA inventory movements:

0

QA audit rows:

4

كل الأربعة ما زالت Draft.

لم يتم حذف أي منها.

الغرض:
توفير بيانات حقيقية دائمة للاختبارات اللاحقة دون توليد Physical Stock Movement.

---

## 13. Production Backend Decision

لا يوجد Defect Backend مطلوب لهذه المشكلة.

تم إثبات أن:

create_manual_stock_voucher_atomic
=
Company-scoped
+
authorization-aware
+
Vehicle aware
+
Representative aware
+
Supplier aware
+
idempotent

كما أن Physical Stock Contract ما زال:

Physical Movement
→ post_stock_movement
→ stock_branches + inventory_log

لا حاجة إلى:

- Table جديد
- Column جديد
- RPC جديد
- Edge Function جديدة
- RLS change
- Physical Stock Engine change

والسبب:
الخلل الحالي Candidate Visibility داخل frontend picker، بينما backend authorization صحيح.

---

## 14. سبب عدم إنشاء Edge Function

المشروع وصل إلى حد Functions/Spend Cap.

وبما أن المشكلة:

Reference Selection / Search Candidate Visibility

فإن فتح HTTP Function جديدة سيكون تعقيدًا بلا فائدة.

القرار:

لا Edge Function جديدة.

تظل الـexisting RPCs هي authority layer.

---

## 15. مقارنة منافسين — ما الذي يجب أن يتعلمه RAWAEA

### Odoo

Odoo يدعم Barcode inventory adjustments، وتعيين مهام الجرد لمستخدمين، ومسارًا عمليًا لعد المنتجات عبر مواقع التخزين والباركود. citeturn993596search1

الدلالة على RAWAEA:
- البحث السريع مهم.
- Mobile/barcode execution مهم.
- assignment مهم.
- الموقع/الكيان يجب أن يكون واضحًا قبل التنفيذ.

### Dynamics 365

Dynamics يستخدم Inventory Transfer Journal ويتيح تحديد From وTo dimensions في سطر الحركة. citeturn993596search6

الدلالة:
- From/To ليست مجرد dropdowns.
- هي عناصر transaction identity ويجب أن تكون مقيدة بالعقد.

### Daftra

Daftra يوفر Stock Transfer مع التاريخ/الوقت وFrom/To وNotes وAvailable Before/After، وكذلك تقارير حركة تفصيلية حسب المنتج/المخزن/نوع العملية ومصدرها. citeturn993596search7turn993596search0turn993596search2

الدلالة:
- مستقبل UI التنافسي ليس مجرد اختيار الكيان.
- القيمة التنافسية الأعلى ستكون:
  - Available Before
  - Available After
  - Timeline
  - Source/Reference
  - Detailed movement trace
  - Export/reporting

### Odoo stock valuation

Odoo يميز بين stock movements مثل receipts, customer returns, deliveries, vendor returns, scrap وبين inventory adjustments ذات سلوك مختلف في التقييم. citeturn993596search10

الدلالة:
- لا يجوز دمج الحركات غير المتشابهة داخل engine واحد من الناحية المحاسبية.
- RAWAEA يمكن أن يحتفظ بالـcentral movement engine مع بقاء Business Contracts منفصلة.

### المنافسة التي يمكن بناؤها لاحقًا في RAWAEA

لا تُفتح الآن لأنها Business Contracts مستقلة:

- Lot / Serial
- Expiry
- Attachments
- Approval workflow
- Stock-in-transit
- Available Before / After
- Barcode execution
- Advanced audit timeline

هذه عناصر مستقبلية، وليست نقصًا يجب ترقيعه داخل هذه الجلسة.

---

## 16. الجراحة المطلوبة فقط

### الملف

companies/company-1/warehouse/vouchers.html

### الدالة

App.pickArr(key)

### التعديل المطلوب

لا تعدل:

loadRefs()
vehicleBranch()
pickSearch()
pickSelect()
norm()
routeHtml()
submit()
prepare()

ولا تعدل:

main.html
van-sales.html

### طريقة التنفيذ

ابحث عن الدالة كاملة:

~~~text
pickArr:function(key){
~~~

ثم استبدل الدالة الحالية كاملة بالنسخة التالية.

---

# PATCH-314-01 — App.pickArr(key)

~~~javascript
pickArr:function(key){
    var s=this,
        bid=(RW_UI.byId('wsFrom')||{}).value||'',
        b=(s.refs.branches||[]).find(function(x){
            return x.id===bid;
        }),
        allBranches=s.refs.branches||[],
        userBranches=allBranches.filter(function(x){
            return s.allowedBranch(s.user,x);
        });

    if(key==='wsFrom'){
        if(s.type==='DirectReturn'){
            return (s.refs.vehicles||[]).filter(function(v){
                var vb=s.vehicleBranch(v),
                    rep=(s.refs.reps||[]).find(function(r){
                        return r.id===v.driver_id;
                    });

                return v.status==='Active' &&
                       !!vb &&
                       (
                           !rep ||
                           (s.refs.branches||[]).some(function(branch){
                               return s.allowedBranch(s.user,branch) &&
                                      s.allowedBranch(rep,branch);
                           })
                       );
            });
        }

        return userBranches;
    }

    if(key==='wsRep'){
        return (s.refs.reps||[]).filter(function(r){
            return !!b &&
                   s.allowedBranch(s.user,b) &&
                   s.allowedBranch(r,b);
        });
    }

    if(key==='wsTo'&&s.type==='Transfer'){
        return userBranches;
    }

    if(key==='wsTo'&&s.type==='DirectSale'){
        var rid=(RW_UI.byId('wsRep')||{}).value||'';

        return (s.refs.vehicles||[]).filter(function(v){
            var vb=s.vehicleBranch(v),
                rep=(s.refs.reps||[]).find(function(r){
                    return r.id===v.driver_id;
                });

            return v.status==='Active' &&
                   !!vb &&
                   !!b &&
                   rid &&
                   v.driver_id===rid &&
                   s.allowedBranch(s.user,b) &&
                   (!rep||s.allowedBranch(rep,b));
        });
    }

    if(key==='wsTo'&&s.type==='DirectReturn'){
        var vid=(RW_UI.byId('wsFrom')||{}).value||'',
            vv=(s.refs.vehicles||[]).find(function(x){
                return x.id===vid;
            }),
            rp=vv&&(s.refs.reps||[]).find(function(x){
                return x.id===vv.driver_id;
            });

        return userBranches.filter(function(x){
            return !rp||s.allowedBranch(rp,x);
        });
    }

    if(key==='wsTo'&&s.type==='SupplierReturn'){
        var m=(s.refs.supplierBranchMap||{})[bid];

        if(m&&Object.keys(m).length){
            return (s.refs.suppliers||[]).filter(function(x){
                return !!m[x.id];
            });
        }

        return [];
    }

    return [];
},
~~~

### الفرق المقصود فقط

السطر الأول:

~~~javascript
return allBranches;
~~~

داخل wsFrom أصبح:

~~~javascript
return userBranches;
~~~

والسطر:

~~~javascript
if(key==='wsTo'&&s.type==='Transfer'){
    return allBranches;
}
~~~

أصبح:

~~~javascript
if(key==='wsTo'&&s.type==='Transfer'){
    return userBranches;
}
~~~

ولا يوجد تغيير آخر مقصود في الدالة.

---

## 17. لماذا هذه الجراحة صحيحة

هي لا تعيد بناء picker.

ولا تغير:

- search score
- search tokens
- vehicle eligibility
- representative linkage
- supplier relation
- mobile branch
- authorization backend
- transaction engine

هي فقط تمنع تمرير Branch entities غير المسموح بها إلى search candidate set.

هذا يحقق:

Search
→ Authorized Candidates Only

ثم:

Selection
→ Existing pickSelect()

ثم:

Save
→ Existing RPC

ثم:

Physical Movement
→ post_stock_movement

---

## 18. لماذا لم يتم تعديل Main

Mother main.html هو Governance / Control Surface.

لا يوجد Defect مثبت في routing الحالي لهذه المهمة.

وRW_Views بالفعل يوجه:

vouchers
transfer
direct-sale
direct-return
supplier-return

إلى RW_Warehouse.

لذلك تعديل main.html سيضيف فرقًا بلا حاجة.

---

## 19. لماذا لم يتم تعديل Van Sales

Current Van Sales uses:

setup-van-branch
save-sales-invoice
save-inventory-count

ويحافظ على:

vehicle
+
driver
+
mobile branch
+
vehicle custody

ولا يوجد عيب جديد مثبت في هذه الجولة.

لذلك عدم لمس الملف قرار حماية، وليس نقصًا.

---

## 20. E2E Status

### PASS

- CURRENT system HEAD verified.
- CURRENT system parent verified.
- CURRENT frontend HEAD verified.
- CURRENT frontend parent verified.
- Current vouchers blob verified.
- Current Van Sales source verified.
- Current Mother routing verified.
- Current loadRefs pagination preserved.
- Current smart-search engine preserved.
- Vehicle code search PASS.
- Arabic plate search PASS.
- Representative search PASS.
- Supplier code search PASS.
- Supplier Arabic-name search PASS.
- Branch search PASS.
- Unauthorized Transfer attempt rejected by Production backend.
- Persistent QA IN-28..IN-31 created and retained.
- QA inventory movements = 0.
- QA audit rows = 4.

### OPEN

Authenticated Browser E2E against the actually served live artifact.

السبب:
لا توجد في بيئة التنفيذ الحالية أداة Browser Authenticated Runtime قادرة على تسجيل الدخول للموقع وتشغيل النقرات الحقيقية، كما أن نجاح Current Source لا يثبت وحده أن Cloudflare/served artifact يحمل آخر commit.

لذلك:

Browser E2E ≠ PASS

ولا يتم رفعه إلى PASS في هذا التقرير.

---

## 21. Final Self-Audit

### What I Proved

1. آخر System Git مع parent.
2. آخر Frontend Git مع parent.
3. Current vouchers source.
4. Current Mother routing.
5. Current Van Sales integration.
6. Current Production identities.
7. Current Production counters.
8. Current backend authorization.
9. Current search engine.
10. Current branch candidate defect.
11. Exact surgical fix.
12. Persistent QA data.
13. No QA stock movement.
14. No need for Production schema change.
15. No need for new Edge Function.

### What I Did Not Prove

Authenticated Browser E2E on the published live artifact.

### What I Did Not Change

main.html
vouchers.html
van-sales.html
Edge Functions
RLS
Physical Stock Engine

### What Must Not Be Repeated

- Report311 parser surgery.
- Report312 vehicle picker repair.
- Report313 pagination repair.
- Existing vehicleBranch / pickSearch / pickSelect work.
- Existing backend voucher authorization.

### Final technical state

SOURCE FIX:
PROVEN

PRODUCTION CONTRACT:
PROVEN

PRODUCTION QA:
PERSISTENT

BACKEND:
NO CHANGE REQUIRED

OWNER SOURCE PATCH:
READY

BROWSER E2E:
OPEN

GLOBAL INVENTORY CORE:
NOT AFFECTED

---

## 22. تعليمات المساعد التالي

ابدأ من:

CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT

ثم تحقق:

1. Frontend HEAD لم يتغير أو read current blob جديد.
2. افتح App.pickArr(key).
3. تحقق أن:
   - wsFrom non-DirectReturn → userBranches
   - Transfer wsTo → userBranches
4. لا تعيد أي إصلاح سابق.
5. لا تلمس main.html.
6. لا تلمس van-sales.html.
7. لا تنشئ Edge Function جديدة.
8. نفذ static parse.
9. نفذ browser authenticated E2E على الصفحة المنشورة.
10. تحقق أن branch forbidden لا يظهر أصلًا في نتائج البحث.
11. تحقق DirectSale vehicle code + Arabic plate.
12. تحقق DirectReturn vehicle code + Arabic plate.
13. تحقق Representative search.
14. تحقق Supplier search.
15. احفظ Draft جديد عند الحاجة باستخدام QA naming جديد.
16. تأكد أن CREATE Draft لا يولد Physical Stock Movement.
17. خذ Production snapshot في نفس وقت التقرير.
18. فقط بعدها يمكن رفع الحالة إلى Browser E2E CLOSED إذا ثبت artifact identity.

---

## 23. التوجيه التنفيذي الأخير

هذه الجلسة لا تعتبر الجراحة مكتملة في Source إلى أن يطبق المالك PATCH-314-01 في:

companies/company-1/warehouse/vouchers.html

بعد التطبيق:

Static Parse
→ Publish
→ Browser E2E
→ Production Snapshot
→ Closure Update

ولا يجوز اعتبار التقرير النظري بديلًا عن ذلك.

---

# END OF REPORT 314
