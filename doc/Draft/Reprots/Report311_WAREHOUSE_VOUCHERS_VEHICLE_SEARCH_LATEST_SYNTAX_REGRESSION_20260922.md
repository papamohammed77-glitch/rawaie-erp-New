# Report311 — التحقيق الجنائي النهائي لتطبيق الأذونات المخزنية / Vehicle Picker / Syntax Regression
## التاريخ: 2026-09-22
## النطاق: Warehouse → Inventory Management → Stock Vouchers → DirectSale / DirectReturn
## الحالة التنفيذية: ROOT CAUSE PROVEN / PRODUCTION CONTRACT VERIFIED / SURGICAL OWNER PATCH READY / DETERMINISTIC E2E PASS / AUTHENTICATED BROWSER E2E OPEN

---

## 0. قاعدة الحوكمة المطبقة

تم التعامل مع هذه الجولة باعتبارها استكمالًا لحالة مثبتة، لا بداية جديدة.

مرجع الحقيقة في هذه الجولة:

CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE

التقارير التاريخية استُخدمت كدلائل جنائية فقط، وتمت مطابقة الادعاءات الحساسة مع المصدر الحالي قبل أي قرار.

لم يتم:
- إعادة إصلاح أي نقطة ثبت أنها صحيحة.
- تعديل main.html.
- تعديل vouchers.html.
- تعديل van-sales.html.
- إنشاء Edge Function جديدة.
- إنشاء Physical Stock Engine ثانية.
- تغيير عقد post_stock_movement.
- تغيير RLS أو صلاحيات Production لهذه الأزمة.

---

# 1. آخر حالة Git المثبتة

## 1.1 المستودع الأم للنظام

Repository:
papamohammed77-glitch/rawaie-erp-New

CURRENT HEAD:
224f53961c667553d5d853016d9013eb91944bab

Commit:
state: reconcile authoritative current heads

Parent:
5efcbae22691a7d09574412056faf5a6494765ce

هذا الـcommit نفسه كان تحديث حالة فقط، ولم يُعتبر مصدرًا لتغيير Business Logic.

## 1.2 مستودع الواجهة التشغيلية

Repository:
papamohammed77-glitch/erp-frontend

CURRENT HEAD:
7a11af9ecba59da29fd6d8aad17053678d75c2e6

Parent:
ec8f2fe8ac7e8c6ac203ef2fafec520b0f05f10e

Current vouchers.html blob:
49a32ac408c629ac22024c8a93713ea758b73197

Current van-sales.html blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

---

# 2. Git lineage الذي تسبب في الأزمة

السلسلة المباشرة المؤثرة في App.pickArr هي:

## Commit 4f16494bf088b48669bbe30e8829c27c44747b7d
Message:
Refactor vehicle filtering in vouchers.html

أدخل إعادة تركيب لمرشح DirectReturn للمركبات، وكانت البنية في تلك الجولة معرضة للخلل البنيوي.

## Commit 78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40
Message:
Remove unnecessary closing brace in vouchers.html

أزال قوسًا إضافيًا داخل نفس المنطقة.

## Commit ec8f2fe8ac7e8c6ac203ef2fafec520b0f05f10e
غيّر timestamp فقط.

## Commit 7a11af9ecba59da29fd6d8aad17053678d75c2e6
Message:
Update vouchers.html

والـdiff المباشر فيه:

return allBranches;
-},
+}
pickShow:function(key)...

أي أنه أزال الفاصلة التي تفصل عضو pickArr عن العضو التالي.

هذه آخر خطوة جعلت خطأ Parser ظاهرًا بشكل مباشر عند:

vouchers:1799

---

# 3. CURRENT SOURCE — الحقيقة الفعلية الآن

تم فتح:

companies/company-1/warehouse/vouchers.html

والـApp.pickArr الحالي في المنطقة الحرجة هو:

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
    if(key==='wsRep'){
        ...
    }

...

    return allBranches;
}
pickShow:function(key){...}

## النتيجة الجنائية

يوجد عيبان تركيبيان متداخلان:

1. بعد نهاية DirectReturn vehicle filter يوجد قوس يغلق if الداخلي فقط، بينما if(key==='wsFrom') الخارجي ما زال مفتوحًا.

2. النهاية الحالية لـpickArr أصبحت:

return allBranches;
}

بدون الفاصلة:

},

وعليه فإن parser لا يرى نهاية عضو object سليمة قبل:

pickShow:function(...)

فتتعامل JavaScript مع function declaration في موضع غير صالح داخل جسم الدالة، وتظهر:

Function statements require a function name

عند السطر 1799.

---

# 4. سبب اختفاء البحث الذكي عن المركبة

الاختفاء الظاهر للبحث ليس عيبًا في pickSearch.

السبب الحالي هو أن JavaScript يفشل في parsing الملف قبل إنشاء App بصورة سليمة.

عند ذلك لا تعمل سلسلة:

load → App.init → renderWorkspace → pickShow → pickSearch

وبالتالي لا توجد قائمة smart picker أصلًا.

## نقطة مهمة

في الحالة السابقة كان هناك أيضًا خطأ Business Logic مختلف:

mobile branch الخاصة بالمركبة كانت تُعامل كأنها فرع تشغيل للمستخدم.

هذا الخطأ تم إصلاحه بالفعل في المصدر الحالي.

المصدر الحالي لDirectReturn لا يحتوي الآن على:

s.allowedBranch(s.user,vb)

والـDirectSale الحالي كذلك لا يحتوي هذا الشرط.

لذلك لا يجوز إعادة فتح هذا الإصلاح.

المشكلة الحالية = Syntax Regression.

---

# 5. العناصر التي ثبت أنها صحيحة ولا تُعدّل

## vehicleBranch()

الحالة: VERIFIED

وظيفتها:

1. رفض المركبة إذا كانت غير صالحة أو mobile_stock_enabled=false.
2. استخدام mobile_branch_id أولًا.
3. التحقق من company + branch activity.
4. fallback إلى VAN-{vehicle_code}.

لا تغيير.

## pickSearch()

الحالة: VERIFIED

عندما يكون type = vehicle تبحث في:

- vehicle_code
- license_plate
- model

وتستخدم norm() الحالية.

لا تغيير.

## norm()

الحالة: VERIFIED

Arabic normalization الحالية جزء من إصلاح سابق مثبت.

لا تغيير.

## pickSelect()

الحالة: VERIFIED

DirectReturn:
- يختار المركبة.
- يملأ المركبة.
- يملأ المندوب المرتبط بالمركبة.
- يجعل حقل المندوب readonly.

DirectSale:
- يتحقق من المركبة.
- يتحقق من المندوب.
- يتحقق من الفرع التشغيلي.
- يحافظ على العلاقة Vehicle ↔ Representative.

لا تغيير.

---

# 6. Production reality — vehicle contract

تمت مطابقة الحالة مباشرة مع Production Supabase.

## Vehicle

vehicle_code:
VCH-QA-260922

vehicle_id:
61dc5bd4-2d78-473e-b62b-a36bca0b45bf

license_plate:
س م ج 26922

model:
QA Van

status:
Active

driver_id:
111b0730-a977-4d11-bcd0-2427b178a9e5

mobile_branch_id:
d1b1ea56-5674-4e5e-9733-5f5b11c88f13

mobile_stock_enabled:
true

## Vehicle second QA/field fixture

vehicle_code:
VEH-TEST-260921

vehicle_id:
5fe9d0b6-fc54-4cc6-9bff-ede0e8557dd8

license_plate:
س ن ر 6021

model:
Suzuki Carry 2024

status:
Active

driver_id:
111b0730-a977-4d11-bcd0-2427b178a9e5

mobile_stock_enabled:
true

---

# 7. Production users / operational branch scope

## Voucher operator

vouchers@rawaea.com

role:
مخزني

company:
00000000-0000-0000-0000-000000000001

allowed_branch_ids:
BR-01

permissions:
["warehouse"]

status:
Active

## Direct Sales Representative

vansales@rawaea.com

role:
مندوب بيع مباشر

company:
00000000-0000-0000-0000-000000000001

allowed_branch_ids:
BR-01

permissions:
["van-sales"]

status:
Active

## Main operational branch

BR-01

id:
a38332b6-6cea-480a-ada1-6eb6ab0590db

---

# 8. التمييز المعماري المهم

تم إثبات التمييز الآتي:

User Operational Scope
≠
Vehicle Mobile Stock Custody

المركبة يمكن أن تكون:

- مرتبطة بالمستخدم/المندوب الصحيح.
- ذات mobile stock صحيح.
- ذات mobile branch صحيحة.
- لكنها لا تصبح فرع تشغيل للمستخدم.

لذلك يجب أن يبقى:

allowedBranch(user, operational_branch)

مختلفًا عن:

vehicleBranch(vehicle)

وهذا هو العقد الصحيح في RAWAEA.

---

# 9. دور تطبيق الأذونات المخزنية

تمت مطابقة التطبيق الحالي مع النظام الأم وProduction.

التطبيق المنفصل هو Execution Surface للعمليات المخزنية غير المرتبطة مباشرة بـOrder/Runsheet:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Adjustment/Scrap بحسب العقد القائم

في DirectSale:

Branch → Vehicle

وفي DirectReturn:

Vehicle → Branch

المركبة هنا هي stock custody endpoint.

## دور النظام الأم

main.html يقوم بدور:

- governance/control
- company identity
- users
- permissions
- branches
- vehicles
- representatives
- monitoring
- reporting
- delegation to specialized applications

والـmain contract ledger الحالي يصف:

stock_vouchers = delegated-to-vouchers.html
Van_Sales = delegated-to-van-sales.html

لذلك لم يتم نقل تنفيذ العمليات إلى main.html.

---

# 10. دور Van Sales والتكامل معه

تم فتح:

companies/company-1/sales/van-sales.html

CURRENT SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

الحالة الحالية تثبت:

1. Authentication عبر RW_Auth.
2. الحصول على vehicle custody branch عبر setup-van-branch.
3. حفظ vanBranchId محليًا بعد التحقق.
4. قراءة مخزون السيارة من فرع العهدة.
5. تنفيذ البيع الميداني عبر save-sales-invoice.
6. تنفيذ الجرد السريع عبر save-inventory-count.
7. الربط بالمندوب الحالي.

لم يتم تعديل van-sales.html لأن العيب الحالي ليس هناك.

التكامل الصحيح:

Mother Control
→ Voucher Execution
→ Vehicle Custody
→ Van Sales Field Execution

مع بقاء Order/Runsheet fulfillment كسلسلة موازية للعمليات المرتبطة بالأوردرات.

---

# 11. Production Edge Functions الحالية

تم التحقق من الموجود بدل إنشاء جديد.

### create-stock-voucher
Version:
10

verify_jwt:
true

الوظيفة الحالية تستخرج company_id من users عبر auth_id، ثم تستدعي:

create_manual_stock_voucher_atomic

وتُمرر:

p_rep_id
p_operation_id

### send-stock-voucher
Version:
20

verify_jwt:
true

### receive-stock-voucher
Version:
22

verify_jwt:
true

يدعم operation_id صريحًا.

### complete-stock-voucher
Version:
4

### cancel-stock-voucher
Version:
4

## قرار Production

لا توجد حاجة لتعديل أي Edge Function من أجل هذا العطل.

لا توجد حاجة لـRLS change.

لا توجد حاجة لـschema change.

لا توجد حاجة لـRPC جديد.

هذا يحافظ على حد Functions/Spend Cap.

---

# 12. QA data — persistent and retained

Production تحتوي بالفعل على بيانات اختبار مخصصة لهذا Closure، ولذلك لم يتم إنشاء نسخ مكررة.

البيانات الحالية:

Vehicle:
VCH-QA-260922

Persistent Draft:
IN-24
DirectSale
reference:
QA-SMART-VEHICLE-DS-260922

Persistent Draft:
IN-25
DirectReturn
reference:
QA-SMART-VEHICLE-DR-260922

Audit rows الخاصة بهما:
2

Inventory movements الخاصة بهما:
0

والحالتان Draft مقصودتان حتى لا يتحول الاختبار إلى حركة مخزنية تشغيلية فعلية.

هذه البيانات مطلوبة للاختبارات اللاحقة ويجب عدم حذفها.

---

# 13. CURRENT Production snapshot

آخر snapshot مباشر:

stock_vouchers:
25

stock_voucher_details:
27

inventory_log:
26

audit_log:
2109

QA DirectSale:
IN-24 = Draft

QA DirectReturn:
IN-25 = Draft

QA Inventory movements:
0

QA Audit rows:
2

---

# 14. Deterministic E2E

تم تشغيل اختبارات حتمية باستخدام بيانات Production الفعلية/المثبتة ونفس منطق picker الحالي.

## DirectReturn

Candidates:
2

Vehicle-code search:
PASS

Arabic plate search:
PASS

## DirectSale

Candidates:
2

Vehicle-code search:
PASS

Arabic plate search:
PASS

## JavaScript parser regression

Malformed structure:
FAIL

الخطأ الناتج:
Function statements require a function name

Corrected structure:
PASS

اختبار Node syntax على الهيكل المصحح أعاد exit code 0.

---

# 15. Browser E2E

الحالة:

OPEN

لم يتم تحويل deterministic/static PASS إلى Browser PASS.

الإغلاق الكامل يتطلب:

Owner applies surgical patch
+
fresh frontend SHA
+
authenticated Browser E2E
+
fresh Production snapshot

ولا يجوز تسجيل Browser PASS قبل ذلك.

---

# 16. Competitive functional review

تمت مراجعة القدرات الرسمية ذات الصلة في الأنظمة المنافسة:

## Odoo

توثيق Odoo 19 يضع عمليات النقل والجرد والـbarcode ضمن عمليات تشغيل المخزون، ويعرض:

- Barcode-driven operations
- physical inventory
- inventory adjustments
- product/location scanning

المراجع الرسمية:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/barcode/operations/adjustments.html
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

## Dynamics 365

توثيق Microsoft يوضح:

- manual inventory movement
- from/to location
- warehouse transfer
- cycle count
- adjustment in/out
- worker/menu scope

المراجع:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/mobile-device-movement-menu
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/tasks/transfer-physical-inventory-within-warehouse

## SAP

توثيق SAP يميز بين:

- storage location
- plant
- one-step transfer
- two-step transfer
- stock in transfer
- authorization across plants

المراجع:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/a764bd534f22b44ce10000000a174cb4.html
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/9e64bd534f22b44ce10000000a174cb4.html

## Daftra

توثيق Daftra يعرض في نقل المخزون:

- date/time
- from warehouse
- to warehouse
- notes
- quantity
- Available Before
- Available After

المراجع:
https://docs.daftra.com/en/tutorial/transferring-stock/

## Manager.io

توثيق Manager يركز على:

- inventory locations
- source location
- destination location
- quantity
- transfer reference
- item identity
- stock distribution by location

المراجع:
https://www2.manager.io/guides/10677
https://www2.manager.io/guides/10707

## النتيجة القابلة للتطبيق على RAWAEA

النقص المنافساتي الحقيقي المؤجل، وليس سبب الأزمة الحالية، يتضمن:

- stock before/after visibility
- barcode-first execution
- richer vehicle/representative/source/destination filters
- print/PDF
- mobile custody dashboard
- lot/batch/expiry/serial بعد عقد Business/Schema مستقل
- richer audit surface

هذه عناصر Closure مستقلة ولا تدخل في إصلاح Syntax الحالي.

---

# 17. التعديل الجراحي المطلوب من المالك

## الملف

erp-frontend/companies/company-1/warehouse/vouchers.html

## الدالة

App.pickArr(key)

---

## الجراحة 1 — عنصر المركبة DirectReturn

ابحث بدقة عن:

if(key==='wsFrom'){

ثم حتى ما قبل:

if(key==='wsRep'){

احذف هذا العنصر الحالي بالكامل:

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

واستبدله بالكامل بهذا العنصر فقط:

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

هذا هو عنصر المركبات المطلوب.

لا تعدل:

vehicleBranch()
pickSearch()
pickSelect()
norm()
DirectSale vehicle filter

---

## الجراحة 2 — نهاية App.pickArr المطلوبة للـParser

ابحث في نهاية App.pickArr عن النص الحرفي:

return allBranches;
}

pickShow:function(key)

استبدله حرفيًا بـ:

return allBranches;
},

pickShow:function(key)

هذه الجراحة ليست تغييرًا وظيفيًا للمركبة؛ هي إغلاق صحيح لعضو object حتى يعود parser للعمل.

---

# 18. لا تلمس العناصر التالية

لا تلمس:

main.html

vouchers.html خارج الجراحتين أعلاه

van-sales.html

vehicleBranch

pickSearch

pickSelect

norm

loadRefs

submit

Production RPC

Production Edge Function

RLS

Permissions

---

# 19. لماذا الإصلاح ليس ترقيعيًا

الإصلاح لا يضيف workaround.

هو يعيد البنية الأصلية الصحيحة لـobject App:

pickArr: function(...) { ... },

pickShow: function(...) { ... },

مع الإبقاء على:

Vehicle Identity Contract
+
Operational Branch Authorization
+
Representative Authorization
+
Mobile Stock Custody
+
Current Search Engine
+
Current Production RPC Guards

لا يوجد Business Logic جديد هنا.

---

# 20. لماذا لا نعدل Production

Production backend لا يعاني من هذا العطل.

الـcurrent backend:
- company-scoped
- vehicle-scoped
- representative-scoped
- custodian-scoped
- mobile-branch validated

والـEdge layer الحالي يمر عبر RPCs القائمة.

لذلك تنفيذ أي schema/RLS/RPC patch الآن سيكون إصلاحًا في المكان الخطأ.

---

# 21. سبب رسالة Tailwind

الرسالة:

cdn.tailwindcss.com should not be used in production...

هي warning من Tailwind CDN.

لا تسبب:

Function statements require a function name

ولا تفسر اختفاء vehicle picker.

هي technical production-hardening warning مستقلة.

لا تدخل ضمن هذه الجراحة، ولا يُسمح بتغيير ملف التطبيق لهذا السبب أثناء إغلاق هذا regression.

---

# 22. سبب الخطأ في نهاية الرسالة — الحكم النهائي

السبب النهائي المثبت هو:

1. تم إصلاح منطق vehicle filtering سابقًا.
2. أثناء إعادة تركيب App.pickArr تغيّرت الأقواس داخل DirectReturn.
3. بقي if(key==='wsFrom') الخارجي مفتوحًا.
4. ثم جاء commit 7a11af... وأزال الفاصلة بعد نهاية pickArr:
   -}, أصبحت:
   -}
5. عند الوصول إلى:
   pickShow:function(...)
   لم يعد parser داخل object method boundary صحيحة.
6. ظهر:
   vouchers:1799
   Function statements require a function name
7. توقف تحميل App.
8. توقف picker.
9. بدا للمستخدم أن "البحث الذكي عن المركبة اختفى".
10. لكن خوارزمية vehicle search نفسها لم تكن هي المشكلة.

إذن:

ROOT CAUSE = malformed App.pickArr structure + missing object-member comma

وليس:

ROOT CAUSE = vehicle search algorithm

---

# 23. SELF-AUDIT

## What I Proved

- current system HEAD verified.
- current frontend HEAD verified.
- current frontend parent verified.
- current vouchers source verified.
- current van-sales source verified.
- production users verified.
- production branches verified.
- production vehicles verified.
- production voucher contracts verified.
- current Edge Functions verified.
- persistent QA dataset verified.
- QA movements = 0 verified.
- exact parser defect reproduced conceptually and in syntax harness.
- corrected structure syntax PASS.
- vehicle code search PASS.
- Arabic plate search PASS.
- current backend requires no change.

## What I Did Not Prove

- authenticated browser E2E after owner applies the source patch.

## What I Did Not Change

- main.html
- vouchers.html
- van-sales.html
- Production schema
- Production RLS
- Production Edge Function count

## What Could Still Be Wrong

- frontend deployment/browser cache/service worker may still serve old malformed source after owner patch.

لذلك Browser E2E remains OPEN.

---

# 24. حالة الإغلاق

CURRENT STATUS:

PRODUCTION CONTRACT = VERIFIED

CURRENT SOURCE = FORENSICALLY VERIFIED

ROOT CAUSE = PROVEN

SURGICAL PATCH = READY

PRODUCTION PATCH REQUIRED = NO

PERSISTENT QA = RETAINED

DETERMINISTIC E2E = PASS

AUTHENTICATED BROWSER E2E = OPEN

100% CLOSED = NO

---

# 25. تعليمات البداية للمساعد التالي

1. لا تعتمد على Report310 كحالة source حالية.
2. افتح CURRENT GIT.
3. افتح current vouchers.html.
4. تحقق أن:
   frontend HEAD = 7a11af9...
   vouchers SHA = 49a32...
5. تحقق من:
   if(key==='wsFrom'){
6. طبق الجراحة المحددة فقط.
7. تحقق من:
   return allBranches;
   },
   pickShow:function...
8. أعد syntax check.
9. نفذ Browser E2E.
10. اختبر:
    - DirectReturn vehicle code
    - DirectReturn Arabic plate
    - DirectSale vehicle code
    - DirectSale Arabic plate
11. تحقق من اختيار المركبة.
12. تحقق من المندوب.
13. تحقق من source/destination authorization.
14. تحقق من أن CREATE Draft لا يولد inventory_log.
15. خذ Production snapshot جديد.
16. حدّث CURRENT_STATE.
17. لا تعيد أي إصلاح سابق إلا إذا أثبت المصدر الحالي regression جديدًا.

---

# 26. Owner Action — مختصر تنفيذي

FILE:
companies/company-1/warehouse/vouchers.html

FUNCTION:
App.pickArr(key)

DO:

1. Replace the exact DirectReturn wsFrom element with the supplied corrected element above.
2. Change only:
   return allBranches;
}
   إلى:
   return allBranches;
},
3. Do not change anything else.

