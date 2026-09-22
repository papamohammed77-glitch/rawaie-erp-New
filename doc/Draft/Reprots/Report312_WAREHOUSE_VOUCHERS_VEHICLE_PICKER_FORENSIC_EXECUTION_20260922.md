# Report312 — الإغلاق الجنائي لرجوع البحث الذكي عن المركبات في الأذونات المخزنية
## التاريخ: 2026-09-22
## النطاق
Warehouse → Inventory Management → Stock Vouchers → DirectSale / DirectReturn → Vehicle Picker
## الحالة
ROOT CAUSE PROVEN / CURRENT SOURCE VERIFIED / PRODUCTION VERIFIED / PERSISTENT QA CREATED AND RETAINED / SURGICAL PATCH READY / DETERMINISTIC E2E PASS / AUTHENTICATED BROWSER E2E OPEN

---

# 1. قاعدة الحوكمة

تم تنفيذ هذه الجولة من آخر حالة مثبتة، لا من الصفر.

مصادر الحقيقة المستخدمة:
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

التقارير السابقة استُخدمت كقرائن تاريخية، ثم تم اختبار الادعاءات الحساسة على المصدر الحالي.

لم يتم:
- تعديل main.html.
- تعديل vouchers.html.
- تعديل van-sales.html.
- إنشاء Edge Function جديدة.
- إنشاء Physical Stock Engine جديدة.
- تغيير RLS.
- تغيير Schema.
- إعادة فتح vehicleBranch / norm / pickSearch / pickSelect أو أي إصلاح سابق ثبتت صحته.

---

# 2. آخر Git تم إثباته

## 2.1 مستودع النظام الأم

Repository:
papamohammed77-glitch/rawaie-erp-New

CURRENT HEAD:
8ddd5efed1c56f4e6dea321cc3500ae81740cbaa

Parent:
064ec25a581f4add023bdb1e1ff3fbe65a94b319

آخر Commit:
CTO: reconcile CURRENT_STATE with Report311 latest vouchers source regression

الـParent المباشر:
CTO: add Report311 forensic closure for vouchers vehicle syntax regression

هذه السلسلة خاصة بتوثيق حالة الـclosure ولا تحتوي تغييرًا في Business Logic للتطبيق المستقل.

## 2.2 مستودع الواجهة

Repository:
papamohammed77-glitch/erp-frontend

CURRENT HEAD:
7a11af9ecba59da29fd6d8aad17053678d75c2e6

Parent:
ec8f2fe8ac7e8c6ac203ef2fafec520b0f05f10e

Current vouchers.html SHA:
49a32ac408c629ac22024c8a93713ea758b73197

Current van-sales.html SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Parent ec8f2fe... غيّر timestamp فقط.
أما 7a11af... فقد غيّر نهاية App.pickArr وأزال الفاصلة بعد:
return allBranches;

---

# 3. قراءة الحالة الحالية

تمت مراجعة:
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS
- CURRENT_STATE.md
- Report309
- Report310
- Report311
- Current vouchers.html
- Current van-sales.html
- Current mother main.html
- Production RPC definitions
- Current Edge Function deployments
- Production vehicles / branches / users
- Production voucher records

MASTER Governance يفرض:
UNDERSTAND
→ RECONSTRUCT HISTORICAL CONTRACT
→ TRACE CURRENT BEHAVIOR
→ TRACE DATA/AUTH/CONTROL FLOW
→ COMPARE TARGET
→ IDENTIFY ACTUAL GAP
→ DESIGN SAFE CHANGE
→ IMPLEMENT
→ VERIFY

وقد تم تطبيق هذا التسلسل على هذه النقطة فقط.

---

# 4. دور التبويب في النظام الأم

في current main.html ثبت أن "إدارة المخازن والمخزون" تتضمن:

- الأصناف
- المخازن والفروع
- مركز التحكم في المخزون
- العمليات المخزنية
  - الاستلام
  - التحضير
  - التحميل
  - التوصيل
  - المرتجعات
  - التفريغ
- الأذونات المخزنية
  - تحويل مخزني
  - صرف سيارة بيع مباشر
  - استلام مرتجع سيارة
  - مرتجع لمورد
  - عرض الأذونات
- الجرد
  - جرد سيارة
  - جرد فرع
  - جرد عام

الـrouting الحالي للنظام الأم يوجّه:
vouchers → RW_Warehouse.loadVouchers()
transfer → RW_Warehouse.loadVoucherForm('Transfer')
direct-sale → RW_Warehouse.loadVoucherForm('DirectSale')
direct-return → RW_Warehouse.loadVoucherForm('DirectReturn')
supplier-return → RW_Warehouse.loadVoucherForm('SupplierReturn')

المعنى المعماري:
Mother App = Governance / Control / Monitoring / User & Permission Scope / Branch & Vehicle Master / Delegation
Standalone Voucher App = Execution Surface للعمليات المخزنية غير المرتبطة مباشرة بـOrder/Runsheet

وهذا الفصل لم يتم تغييره.

---

# 5. دور تطبيق الأذونات المخزنية

Current vouchers.html يحتوي دورة مستقلة كاملة تشمل:

Transfer
DirectSale
DirectReturn
SupplierReturn
وواجهات Adjustment/Scrap المرتبطة بعقد المخزون القائم.

في Current Source:

DirectSale:
Branch → Vehicle

DirectReturn:
Vehicle → Branch

والمركبة هنا ليست "فرع مستخدم"؛ بل Mobile Stock Custody Endpoint.

هذا يطابق العقد المعماري الثابت:

User Operational Scope
≠
Vehicle Mobile Stock Custody

---

# 6. دور Van Sales وتكامله

Current:
companies/company-1/sales/van-sales.html
SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Current runtime contracts المثبتة:

- Authentication عبر RW_Auth.
- الحصول على Vehicle Custody عبر setup-van-branch.
- vehicle → mobile_branch_id.
- قراءة مخزون السيارة من فرع العهدة.
- البيع الميداني عبر save-sales-invoice.
- الجرد عبر save-inventory-count.
- المندوب مرتبط بالمركبة.

Current deployed functions:
setup-van-branch = v4
save-sales-invoice = v15
save-inventory-count = v4

لا يوجد دليل أن العيب الحالي في van-sales.

---

# 7. سبب اختفاء البحث الذكي عن المركبة

## 7.1 البحث نفسه ليس سبب المشكلة

Current pickSearch موجود ويصنف:
type='vehicle'

ويبحث في:
vehicle_code
license_plate
model

Current norm() موجودة وتمثل normalization عربية سابقة مثبتة.

Current vehicleBranch() موجودة وتمثل mobile custody resolution.

Current pickSelect() موجودة وتمثل اختيار المركبة وربط المندوب.

إذًا:
Vehicle Search Algorithm = PRESENT

---

# 8. ROOT CAUSE — مثبت من المصدر وGit

المشكلة في Current Source هي بنية App.pickArr(key).

الجزء الحالي يبدأ:

if(key==='wsFrom'){
    if(s.type==='DirectReturn'){
    ...
    });
    }
if(key==='wsRep'){

المطلوب أن يتم إغلاق if(key==='wsFrom') الخارجي بعد DirectReturn.

ثم في نهاية App.pickArr Current Source:

return allBranches;
}
pickShow:function(key)...

وهذا غير صحيح كعضو في object App لأن الفاصلة بعد نهاية pickArr مفقودة.

## السبب الجذري النهائي

ROOT CAUSE =
malformed App.pickArr structure
+
missing object-member comma before pickShow

ثم يظهر Parser Error:

vouchers:1799
Uncaught SyntaxError: Function statements require a function name

عندما يفشل parser:
App لا يُنشأ بصورة سليمة.
وبالتالي:
load → App.init → renderWorkspace → pickShow → pickSearch

لا يعمل.

لذلك يرى المستخدم ظاهريًا أن "البحث الذكي عن المركبة اختفى"، بينما الخوارزمية نفسها لم تكن هي العيب.

---

# 9. Git lineage الذي يثبت سبب الأزمة

## 4f16494bf088b48669bbe30e8829c27c44747b7d
Message:
Refactor vehicle filtering in vouchers.html

هذه الجولة أعادت تركيب منطقة DirectReturn vehicle filter.

## 78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40
Message:
Remove unnecessary closing brace in vouchers.html

الـpatch حذف قوسًا كان يغلق البنية المطلوبة بعد منطقة vehicle filter.

## ec8f2fe8ac7e8c6ac203ef2fafec520b0f05f10e
Message:
Update HTML comment timestamp in vouchers.html

Changes:
timestamp فقط.

## 7a11af9ecba59da29fd6d8aad17053678d75c2e6
Message:
Update vouchers.html

الـdiff المهم:
-},
+}

أي أن فاصلة فصل member بعد pickArr أزيلت.

هذه الخطوة هي التي جعلت SyntaxError الحالي ظاهرًا عند pickShow.

---

# 10. التعديل الجراحي — المطلوب على الملف فقط

## الملف

erp-frontend/companies/company-1/warehouse/vouchers.html

## الدالة

App.pickArr(key)

---

## الجراحة رقم 1 — عنصر مركبات DirectReturn

### ابحث حرفيًا عن:

if(key==='wsFrom'){

ثم حتى قبل:

if(key==='wsRep'){

### احذف العنصر الحالي بالكامل:

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

### واستبدله بهذا العنصر فقط:

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
}

هذا هو العنصر المسؤول عن قائمة المركبات في DirectReturn.

---

# 11. الجراحة رقم 2 — نهاية App.pickArr

### ابحث حرفيًا عن:

return allBranches;
}
pickShow:function(key)

### استبدله حرفيًا بـ:

return allBranches;
},
pickShow:function(key)

هذا إصلاح Parser structure فقط.

لا تضف أي logic آخر.

---

# 12. ممنوع تعديل هذه العناصر

لا تعدل:

main.html

van-sales.html

vehicleBranch()

norm()

pickSearch()

pickSelect()

loadRefs()

submit()

DirectSale vehicle filter

Production RPCs

Production Edge Functions

RLS

Permissions

سبب المنع:
هذه العناصر راجعتها في Current Source/Production وثبت أنها تمثل الإصلاحات/العقود الصحيحة بالفعل.

---

# 13. Production — الوضع الحالي

Company:
00000000-0000-0000-0000-000000000001

Voucher operator:
vouchers@rawaea.com
role = مخزني
allowed_branch_ids = BR-01
permissions = [warehouse]
status = Active

Direct Sales Representative:
vansales@rawaea.com
role = مندوب بيع مباشر
permissions = [van-sales]
allowed_branch_ids = BR-01
status = Active

Main branch:
BR-01
id = a38332b6-6cea-480a-ada1-6eb6ab0590db

---

# 14. Production Vehicles

Vehicle 1:
vehicle_code = VCH-QA-260922
id = 61dc5bd4-2d78-473e-b62b-a36bca0b45bf
license_plate = س م ج 26922
model = QA Van
status = Active
driver_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
mobile_branch_id = d1b1ea56-5674-4e5e-9733-5f5b11c88f13
mobile_stock_enabled = true

Vehicle 2:
vehicle_code = VEH-TEST-260921
id = 5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8
license_plate = س ن ر 6021
model = Suzuki Carry 2024
status = Active
driver_id = 111b0730-a977-4d11-bcd0-2427b178a9e5
mobile_branch_id = 5372503d-f638-4e7f-808d-bda585825b2f
mobile_stock_enabled = true

---

# 15. Persistent QA data — تم إنشاؤها ولن تُحذف

تم إنشاء بيانات إضافية دائمة لاختبار نفس العقد دون توليد حركة مخزنية:

IN-26
type = DirectSale
status = Draft
reference = QA-E2E-VEHICLE-SEARCH-DS-260922
from = BR-01
to = vehicle VCH-QA-260922
item = 1001
qty = 1
rep = vansales@rawaea.com
operation_id = QA-E2E-VEHICLE-SEARCH-DS-260922

IN-27
type = DirectReturn
status = Draft
reference = QA-E2E-VEHICLE-SEARCH-DR-260922
from = vehicle VCH-QA-260922
to = BR-01
item = 1001
qty = 1
rep = vansales@rawaea.com
operation_id = QA-E2E-VEHICLE-SEARCH-DR-260922

كما تم الحفاظ على QA السابق:

IN-24 = DirectSale / Draft / QA-SMART-VEHICLE-DS-260922
IN-25 = DirectReturn / Draft / QA-SMART-VEHICLE-DR-260922

حالة QA الحالية:
- كل الأربع Draft.
- لا توجد inventory movements مرتبطة بها.
- Audit rows = 4.

هذه البيانات جزء من QA fixture الدائم ولا تُحذف.

---

# 16. Production snapshot بعد إنشاء QA

stock_vouchers = 27
stock_voucher_details = 29
inventory_log = 26
audit_log = 2111

QA inventory movements:
0

QA audit rows:
4

---

# 17. Runtime Edge Functions — تم التحقق من الموجود

create-stock-voucher = v10
verify_jwt = true

send-stock-voucher = v20
verify_jwt = true

receive-stock-voucher = v22
verify_jwt = true

setup-van-branch = v4
verify_jwt = true

save-sales-invoice = v15
verify_jwt = true

save-inventory-count = v4
verify_jwt = true

لا توجد حاجة إلى Edge Function جديدة.

لا توجد حاجة إلى رفع Function جديدة بسبب هذه الأزمة.

---

# 18. Production/RPC conclusion

لم يظهر في التحقيق أي Physical Stock defect متعلق بهذا Syntax regression.

لم يتم تغيير:
- schema
- RLS
- Physical Stock Engine
- stock movement contract
- current Edge Functions

وذلك متعمد لأن العيب الحالي Frontend Parser defect.

---

# 19. Deterministic E2E — تم إعادة الاختبار

تم استخدام نفس قيم Production الفعلية.

## DirectReturn

Candidates:
2

Vehicle code:
VCH-QA-260922 → PASS

Arabic plate:
س م ج 26922 → PASS

Second vehicle code:
VEH-TEST-260921 → PASS

Second Arabic plate:
س ن ر 6021 → PASS

## Candidate count

2 → PASS

## Corrected JavaScript structure

Node syntax check:
PASS

## Malformed original structure

يمثل نفس النمط الذي تسبب في:
Function statements require a function name

---

# 20. ما لم يُثبت بعد

AUTHENTICATED BROWSER E2E
=

OPEN

السبب:
Current Source ما زال على SHA:
49a32ac408c629ac22024c8a93713ea758b73197

والجراحة المطلوبة لم يتم تطبيقها على هذا الملف لأن نطاق التنفيذ الحالي يحظر تعديل الملف نفسه ويطلب تقديم الجراحة الجاهزة للمالك.

لذلك لا يجوز كتابة:
Browser PASS
ولا:
100% CLOSED

قبل:
Owner Patch
+
Fresh Frontend SHA
+
Browser E2E
+
Fresh Production snapshot

---

# 21. Tailwind warning

الرسالة:

cdn.tailwindcss.com should not be used in production

هي Warning تقنية مستقلة ناتجة عن استخدام Tailwind CDN.

لا تسبب:
Function statements require a function name

ولا تفسر اختفاء Vehicle Picker.

لم يتم إدخالها في هذه الجراحة لأن إصلاحها يحتاج مسار Technical Hardening مستقل، ولا يجوز توسيع Closure الحالي وإعادة تحميل CSS architecture أثناء إصلاح Parser regression.

---

# 22. Competitive review

## Odoo 19

الـBarcode flow يدعم:
- inventory adjustments
- scanning locations/products
- manual quantity adjustment
- transfer operations

المصدر الرسمي:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html

## Microsoft Dynamics 365

Warehouse Management mobile app يدعم:
- manual warehouse movement
- worker-controlled movement
- from/to location
- warehouse transfer
- configurable mobile workflows
- centralized mobile-device settings

المصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/mobile-device-movement-menu
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

## SAP

المعمارية التشغيلية تميز بين:
- plant
- storage location
- one-step transfer
- two-step transfer
- stock distribution by location

المصدر:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/a764bd534f22b44ce10000000a174cb4.html

## Daftra

نقل المخزون يشمل:
- date/time
- from warehouse
- to warehouse
- notes
- quantity
- Available Before
- Available After

المصدر:
https://docs.daftra.com/en/tutorial/transferring-stock/

## Manager.io

التعامل مع inventory transfer يقوم على:
- source location
- destination location
- quantity
- transfer reference
- item identity
- stock distribution

المصادر:
https://www2.manager.io/guides/10677
https://www2.manager.io/guides/10707

---

# 23. Competitive gaps الحقيقية — Backlog مستقل

بعد إغلاق Parser regression، النقص التنافسي الذي ثبت من المقارنة هو:

1. Stock Before / After visibility داخل الحركة.
2. Barcode-first execution.
3. Richer vehicle / representative / source / destination filtering.
4. Print / PDF / document export.
5. Mobile custody dashboard.
6. Richer audit surface.
7. Lot / batch / expiry / serial فقط بعد Contract + Schema مستقل.

هذه ليست إصلاحات مخفية داخل الحالية.
ولا يجوز إدخالها في هذا الملف أثناء إصلاح Syntax.

---

# 24. لماذا عدم إضافة هذه العناصر الآن صحيح

لأن التطبيق الحالي قد وصل إلى بنية تشغيلية مقصودة تقوم على:

Mother Control
→ Specialized Execution Apps
→ Shared Production Contracts

وإدخال Features جديدة أثناء Syntax regression قد يؤدي إلى:
- consumer drift
- contract drift
- duplicate behavior
- accidental re-opening of closed fixes

لذلك تم فصل:
REGRESSION FIX
عن:
COMPETITIVE ENHANCEMENT

---

# 25. Self Audit

## What I Proved

- آخر System HEAD = 8ddd5...
- parent = 064ec...
- آخر Frontend HEAD = 7a11...
- parent = ec8f...
- current vouchers SHA = 49a32...
- current van-sales SHA = 8d613...
- current main source architecture reviewed.
- voucher standalone role verified.
- van-sales integration verified.
- production vehicles verified.
- production users verified.
- production branch scope verified.
- current Edge Function versions verified.
- current RPC contract verified.
- DirectReturn vehicle contract verified.
- DirectSale vehicle contract verified.
- pickSearch vehicle fields verified.
- norm verified.
- vehicleBranch verified.
- pickSelect verified.
- exact parser defect identified.
- Git commit that removed closing separator identified.
- deterministic vehicle code search PASS.
- deterministic Arabic plate search PASS.
- corrected JavaScript structure PASS.
- persistent QA data created.
- persistent QA data retained.
- QA inventory movements = 0.
- QA audit rows = 4.
- no new Edge Function needed.

## What I Did Not Prove

Authenticated Browser E2E بعد تطبيق owner patch.

## What I Did Not Change

main.html
vouchers.html
van-sales.html
Production schema
Production RLS
Production Edge Function count
Physical Stock Engine

## What Could Still Be Wrong

1. Frontend deployment may still serve the malformed SHA until owner commits the patch.
2. Browser cache / Service Worker may serve stale content after the commit.
3. Browser E2E must prove actual UI construction of picker after parser recovery.

---

# 26. Final closure state

PRODUCTION CONTRACT = VERIFIED
CURRENT SOURCE = VERIFIED
ROOT CAUSE = PROVEN
SURGICAL PATCH = READY
QA = CREATED + RETAINED
DETERMINISTIC E2E = PASS
PRODUCTION STRUCTURE CHANGE = NOT REQUIRED
NEW EDGE FUNCTION = NOT REQUIRED
AUTHENTICATED BROWSER E2E = OPEN
100% CLOSED = NO

---

# 27. Owner execution — exact and only

FILE:
companies/company-1/warehouse/vouchers.html

FUNCTION:
App.pickArr(key)

ACTION 1:
Replace the exact DirectReturn wsFrom element with the corrected element in Section 10.

ACTION 2:
Replace:
return allBranches;
}
pickShow:function(key)

with:
return allBranches;
},
pickShow:function(key)

ACTION 3:
Do not change anything else.

ACTION 4:
After commit, verify the resulting new SHA.

ACTION 5:
Run syntax validation.

ACTION 6:
Run authenticated browser E2E:
- DirectReturn + vehicle code
- DirectReturn + Arabic plate
- DirectSale + vehicle code
- DirectSale + Arabic plate
- vehicle selection
- representative linkage
- source/destination branch authorization

ACTION 7:
Verify:
CREATE Draft
does not create inventory_log movement.

ACTION 8:
Take fresh Production snapshot.

ACTION 9:
Only then mark closure:
100% CLOSED

---

# 28. تعليمات للمساعد التالي

لا تبدأ من Report310.

ابدأ من:
CURRENT GIT
+
CURRENT vouchers SHA
+
CURRENT Production snapshot

ثم تحقق أن owner patch موجود بالفعل.

بعدها:
1. Syntax check.
2. Browser authenticated E2E.
3. DirectReturn vehicle code.
4. DirectReturn Arabic plate.
5. DirectSale vehicle code.
6. DirectSale Arabic plate.
7. Vehicle ↔ Representative.
8. Operational Branch Authorization.
9. CREATE Draft.
10. inventory_log = no movement from CREATE.
11. Production snapshot.
12. Update CURRENT_STATE.
13. Close.

لا تعيد:
vehicleBranch
norm
pickSearch
pickSelect
DirectSale filter

إلا إذا أثبت Current Source regression جديد.

---

# 29. سبب الخطأ في نهاية المهمة — الحكم التنفيذي النهائي

الخطأ لم يكن في المركبات.

الخطأ لم يكن في البحث الذكي.

الخطأ لم يكن في Production.

الخطأ لم يكن في Vehicle Mobile Branch.

الخطأ كان:

App.pickArr(key)
تمت إعادة تركيبها بشكل غير متوازن،
ثم أزيلت الفاصلة التي تفصل pickArr عن pickShow.

فأصبح JavaScript parser عاجزًا عن قراءة object App،
فانهار App بالكامل،
فاختفى picker كأثر ثانوي.

إصلاح الجراحة يعيد:

pickArr: function(...) { ... },

ثم:
pickShow: function(...) { ... },

وبذلك يعود parser،
ثم يعود App،
ثم يعود picker،
ثم يعود البحث الذكي عن المركبة الموجود أصلًا.

# END OF REPORT312
