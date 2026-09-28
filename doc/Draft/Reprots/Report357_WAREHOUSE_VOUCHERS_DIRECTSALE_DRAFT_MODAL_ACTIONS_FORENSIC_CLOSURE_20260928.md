
# Report357 — السبب الجذري لمشكلة إجراءات مسودة «صرف مباشر» داخل مودال الأذونات المخزنية
تاريخ التنفيذ: 2026-09-28

## 1. نقطة البداية والحقيقة الحالية

تم استئناف العمل من آخر حالة مثبتة، مع اعتبار التقارير تاريخية فقط ثم إعادة التحقق من المصدر الحالي وProduction وDatabase وGit.

### Current Git — System
- آخر System HEAD قبل هذا التقرير: b99dc6f57ea43a3d19a23188da5377cb296745a6
- الـparent: 10ff4e0bc930a409a860b3722849621dcdf1ff72

### Current Git — Frontend
- أحدث Frontend HEAD: 8b6b32145aafdb49ae10af8f36aa888e4d25d412
- الـparent المباشر: cd125b126cd40527a81f20508139506b8e48031f
- vouchers.html blob: bb0dd32e790fc55161a409e746f2ea778e44ae3b
- vouchers.html: 6327 سطرًا / 208151 حرفًا
- main.html blob: 810e4f5440f5975f55099a124deb42b086a49183
- van-sales.html blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

Commit 8b6b321 نقل loadList إلى RPC inventory_voucher_report. هذا هو المصدر الحالي وي supersede الحالات الأقدم التي كانت تشير إلى cd125 كآخر حالة.

main.html لم يُلمس.
van-sales.html لم يُلمس.
vouchers.html لم يُعدل من طرف المساعد؛ التعديل المطلوب أدناه Owner Source Change Set فقط.

---

## 2. القراءة التاريخية

تمت قراءة MASTER CTO GOVERNANCE بالكامل حتى EOF على دفعات. كما تمت إعادة قراءة CURRENT_STATE والتحقق من آخر checkpoints ومقارنتها بالحالة الفعلية الحالية.

القواعد الحاكمة التي تنطبق هنا:
- REPORTS = HISTORICAL CLUES وليس Current Truth.
- BUSINESS CAPABILITY وليس مجرد وجود الشاشة هو وحدة الإغلاق.
- لا يوجد FALSE CLOSURE.
- Production وDatabase وCurrent Source وDeployment evidence يجب فصلها.
- Owner Source changes يجب أن تكون Surgical وFull Replacement للعنصر المعيب فقط.
- لا يجوز إعادة تنفيذ إصلاح سبق إثباته.
- لا إنشاء Edge Function جديدة عند كفاية البنية الحالية.

---

## 3. تاريخ آخر Commits والـparent

تم فحص التسلسل الأخير في Frontend:

1d2103a8903296a33110e83803a355f224c489c5
→ 880abe25c42d7c82c79cf133b9880d09ebfc416f
→ 85e825de61333f3b7da014580dd7275146818b2a
→ cd125b126cd40527a81f20508139506b8e48031f
→ 8b6b32145aafdb49ae10af8f36aa888e4d25d412

الـparent المباشر المؤكد لـ8b6 هو cd125، و8b6 غيّر loadList فقط إلى RPC مركزي، مع تعديلات سبق تنفيذها في modal contract.

---

## 4. دور النظام الأم والتطبيقات المنفصلة

النظام الأم هو Control Plane الذي يحكم الهوية والصلاحيات والسياق والوظائف الأبوية والتكامل العام.

vouchers.html هو operational execution surface للأذونات والحركات المخزنية المستقلة عن Order/Runsheet. دوره ليس استبدال دورة الطلب/الرانشيت، وإنما معالجة الوثائق المخزنية غير المرتبطة بها مع تمرير التنفيذ الفعلي عبر البنية المركزية الحالية.

van-sales.html هو mobile/direct-sales execution surface. المراجعة الحالية تثبت أن الفصل بين التطبيقين مقصود، ولم يظهر أي دليل يبرر دمجهما في هذه المشكلة.

دورة العمل الحالية للأذونات تبقى:
Pending list
→ open voucher modal
→ responsibility action
→ existing RPC/Edge transaction
→ stock/audit/reporting.

---

## 5. السبب الجذري — PROVEN

### العرض
في تبويب «معلقة»، عند فتح مودال مسودة DirectSale من حساب فرع الوجهة، لا تظهر أزرار:
- تعديل
- حذف
- إرسال
- طباعة

### العنصر المعيب
الملف:
companies/company-1/warehouse/vouchers.html

الدالة:
actionFor:function(v)

الموضع:
العنصر الثاني if(v.status==='Draft') حول السطر 608.

العنصر الحالي المعيب:

~~~~javascript
    if(v.status==='Draft'){
        return(
            creator||
            privileged
        )?'draft':'';
    }

    if(v.status==='Sent'){
~~~~

### لماذا هو السبب الجذري؟
طبقة Production الحالية inventory_voucher_report أصبحت تقوم بما يلي بصورة صحيحة:
- تتحقق من الشركة.
- تتحقق من نطاق المسؤولية.
- تُرجع Draft الخاص بالمستخدم في Pending.
- تقوم عمدًا بعمل redaction لـ created_by لغير privileged users.

نتيجة Current Production للمسودة المسموح بها أصبحت:
status = Draft
created_by = null

بينما actionFor(v) تعتمد على creator الذي يساوي مقارنة بريد المستخدم بقيمة created_by.

إذن:
creator = false
privileged = false
actionFor = ''

ولا تدخل details() إلى شرط act='draft'.

وعند عدم دخول شرط draft لا يتم بناء شريط:
Edit / Delete / Send / Print.

هذه ليست مشكلة في صلاحية المسودة نفسها، وليست مشكلة في create/send backend.

---

## 6. إثبات أن Authorization في Production سليم

تم إنشاء وإعادة فحص QA fixture باستخدام المسار الرسمي الحالي:

DirectSale
BR-01 → Vehicle VHL-0422
item 1001 qty 1
item 1003 qty 1
status Draft
operation_id = QA-VOUCHERS-DRAFT-UI-20260928-01

النتيجة:
- Pending list أعادت IN-8.
- created_by ظهر null كما يقتضي redaction.
- VOUCHER_AUDIT نجح للمستخدم المصرح.
- الحركة المخزنية قبل الإرسال = 0.
- Operation identity = 1.

ثم تمت محاولة نفس detail من مستخدم غير مخول، وكان الرفض المركزي:
غير مصرح بالوصول إلى هذا الإذن

إذن secure Pending list + VOUCHER_AUDIT يعملان، والخلل في UI decision layer فقط.

---

## 7. الاختبار قبل وبعد الإصلاح المقترح

Current source simulation:
- قبل الإصلاح مع payload Production الفعلي: actionFor = ''
- بعد الإصلاح: actionFor = 'draft'

عندما يصبح act = draft، فإن details() الحالية تبني فعليًا:
- App.editVoucher(code)
- App.deleteVoucher(code)
- App.send(code)
- App.printDraftVoucher(code)

تم التحقق من أن:
- current inline JavaScript parse = PASS
- in-memory patched source parse = PASS
- العنصر المعيب موجود مرة واحدة فقط في الموضع المستهدف
- مسودة غير موجودة في Pending لا تحصل على draft action في المحاكاة
- codeJs الحالي صحيح بالفعل ولا يحتاج إعادة إصلاح.

---

## 8. التعديل الجراحي الوحيد المطلوب من المالك

### الملف المطلوب تعديله
companies/company-1/warehouse/vouchers.html

### الدالة
actionFor:function(v)

### الموضع
حوالي السطر 608، العنصر الثاني if(v.status==='Draft').

### ابحث عن هذا العنصر بالتحديد واحذفه بالكامل

~~~~javascript
    if(v.status==='Draft'){
        return(
            creator||
            privileged
        )?'draft':'';
    }

    if(v.status==='Sent'){
~~~~

### ثم استبدله بالكامل بهذا العنصر

~~~~javascript
    if(v.status==='Draft'){
        var draftListedForCurrentUser=
            s.tabName==='pending'&&
            Array.isArray(s.vouchers)&&
            s.vouchers.some(function(row){
                return(
                    row&&
                    row.status==='Draft'&&
                    String(row.voucher_code||'')===
                    String(v.voucher_code||'')
                );
            });

        return(
            creator||
            privileged||
            draftListedForCurrentUser
        )?'draft':'';
    }

    if(v.status==='Sent'){
~~~~

### نتيجة هذا التعديل
المودال يعيد استخدام الحقيقة الآمنة الموجودة بالفعل في Pending list بدل الاعتماد على created_by الذي تم redacted منه عمدًا.

لا يوجد تغيير في business workflow.
لا يوجد تغيير في Transfer.
لا يوجد تغيير في DirectReturn.
لا يوجد تغيير في DirectSale backend.
لا يوجد تغيير في Print functions.

---

## 9. ما لم يتم لمسه

ممنوع إعادة فتح أو تعديل أي من الآتي لهذه الأزمة:

- main.html
- van-sales.html
- printDraftVoucher()
- printVoucher()
- details()
- cards()
- loadList()
- transfer source/destination contract
- transfer receiver binding
- partial/full receive backend
- SupplierReturn contract
- DirectReturn contract
- existing create/send/receive/complete/cancel path
- existing RPCs
- existing Edge Functions

لا يوجد Edge Function جديدة.
لا يوجد RPC جديدة.
لا يوجد جدول جديد.
لا توجد migration جديدة لهذه المشكلة.

---

## 10. Production / Database

لا يوجد Production defect يحتاج إصلاحًا لهذه النقطة.

Production الحالي يحتفظ بالعقود المغلقة سابقًا:
- pending responsibility scope
- redaction contract
- transfer source responsibility
- receiver binding
- partial/full receive
- DirectReturn
- existing manual voucher transactional path.

لا توجد حاجة لتجاوز عدد Edge Functions؛ البنية الحالية كافية.

---

## 11. QA Data Cleanup

تم حذف QA Draft IN-8 باستخدام delete_manual_stock_voucher_atomic الرسمي.

الحالة النهائية بعد التنظيف:
- Manual Draft = 0
- Manual Sent = 0
- Manual Received = 1
- Manual Completed = 5
- IN-8 details = 0
- IN-8 inventory movements = 0

تم الإبقاء على Operation Identity QA tombstone لأن integrity guard يمنع حذفها عمدًا. لم يتم تجاوز الحماية.

---

## 12. E2E

### مثبت
- Production RPC reproduction = PASS
- Authorization denial = PASS
- Redacted modal contract = PASS
- in-memory patched action logic = PASS
- source JavaScript parse after proposed patch = PASS

### غير مثبت
Authenticated Browser E2E = OPEN

لا يوجد سطح Browser مصادق في هذه البيئة يسمح بإثبات:
Login → Pending → open Draft → modal → click Edit/Send/Print.

لذلك لا يتم الادعاء بأن Browser E2E مكتمل.

---

## 13. نقطة أمنية منفصلة يجب عدم خلطها بهذه المشكلة

تم رصد أن editVoucher() وprintDraftVoucher() يستخدمان Direct Table Reads على stock_vouchers وstock_voucher_details، بينما RLS الحالي لهذه القراءة يثبت Company Scope أكثر من responsibility scope الموجود في inventory_control.

هذه ليست سبب اختفاء الأزرار الحالي.
ولا يجب تعديل RLS بصورة عشوائية.

الحالة:
OPEN — Separate Security Hardening Closure

وتحتاج audit لجميع consumers قبل أي تغيير، حفاظًا على عدم كسر بقية التطبيقات.

---

## 14. مقارنة وظيفية مختصرة مع المنافسين

Odoo 19 يوثق سجل حركة يحتوي تاريخ/وقت، المرجع، المنتج، lot/serial عند انطباقه، المصدر، الوجهة، الكمية والوحدة والحالة، مع Filters وGroup By. كما يربط الحركة بالتقييم وقيم المخزون والحركات المكتملة.  
المصدر:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/moves_history.html

المصدر الثاني:
https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html

Microsoft Dynamics 365 يدعم Transfer Orders بين المخازن، التواريخ، receiving process، فصل التسجيل عن الاستلام، partial receiving، ودورة warehouse/mobile workflows.
المصادر:
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/transfer-orders-warehouse
https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-transfer-order-receiving-process

Daftra يوضح في Stock Transfer وجود Date/Time وFrom Warehouse وTo Warehouse وNotes وQuantity وAvailable Before وAvailable After.
المصدر:
https://docs.daftra.com/en/tutorial/transferring-stock/

الاستنتاج للمشروع:
الـarchitecture الحالي لروائع يملك بالفعل عنصرًا مهمًا تفعله الأنظمة المنافسة: document + responsibility + source/target + item quantities + state workflow. الفجوات التنافسية المستقبلية هي عمق الوثيقة والتحقيق والتتبع، وليس تغيير هذا الإصلاح البسيط.

---

## 15. Business Contract gaps المتبقية كـBacklog

بعد إغلاق هذه المشكلة يمكن دراسة:
- وقت العملية بدقة أكبر.
- Reason/Purpose مصنف.
- Barcode/Lot/Serial/Expiry عند انطباقها.
- Stock Before / After.
- Expected versus Actual Receive.
- Shortage/Overage reason.
- Evidence/Attachment.
- Aging/SLA للمعلقات.
- Activity timeline موحد.
- تقارير وفلاتر موحدة.
- صلاحية تنفيذ منفصلة عن صلاحية الاطلاع.

لا يتم تنفيذ أي منها داخل هذه الدورة.

---

## 16. حالة الإغلاق

ROOT CAUSE: PROVEN
Production Contract: VERIFIED
Production backend repair: NOT REQUIRED
Owner Surgical Patch: READY
Current Frontend Source: NOT MODIFIED BY ASSISTANT
Browser E2E: OPEN
Served Artifact Verification: OPEN

هذه الدورة لا تعلن Full Closure لأن التعديل نفسه ما زال Owner-side ولأن Browser/served artifact لم يُثبتا.

---

## 17. التعليمات الدقيقة للمساعد التالي

ابدأ فقط من:
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE

ثم:
1. تحقق من Frontend HEAD 8b6b32145aafdb49ae10af8f36aa888e4d25d412.
2. تحقق من vouchers blob bb0dd32e790fc55161a409e746f2ea778e44ae3b.
3. لا تعيد أي إصلاح من Report349 إلى Report356.
4. داخل actionFor:function(v) ابحث عن العنصر الثاني if(v.status==='Draft') حول السطر 608.
5. طبّق البديل الكامل أعلاه فقط.
6. أعد قراءة vouchers.html كاملًا.
7. نفذ parse كامل.
8. تحقق أن draftListedForCurrentUser يظهر مرة واحدة فقط.
9. تحقق من وجود Edit/Delete/Send/Print داخل draft modal.
10. Publish/Deploy من Owner.
11. تحقق من served artifact identity.
12. نفذ Browser E2E المصادق.
13. لا تعد إلى Production backend إلا عند ظهور دليل جديد يناقض الحالة المثبتة.

### LAST VERIFIED CHECKPOINT
Root cause proven + Production reproduced + surgical patch prepared + QA cleanup completed.

### NEXT EXACT CHECKPOINT
Owner applies one element inside actionFor()
→ full parse
→ served artifact
→ authenticated Browser E2E
→ closure.

# END OF REPORT357
