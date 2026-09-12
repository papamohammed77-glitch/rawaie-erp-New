# Report129 — إعادة الفحص الجنائي لـ Main9 وتنفيذ حزمة الإكمال — 2026-09-12

## 0. الهدف الحاكم — يجب قراءته بعناية وتكراره

**هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

## 1. النطاق وقاعدة الملكية

تم إيقاف المسارات السابقة والتركيز على `Current/PWA/main2/main9.md`.

`Current/PWA/main2/main9.md` هو Source Fragment مملوك للمالك؛ لذلك **لم يتم تعديل Main9 نفسه بواسطة المساعد**. تم إنشاء حزمة Owner Surgical Replacement كاملة ومحددة. لم يثبت احتياج Production DDL/Data migration جديد خاص بـMain9؛ القدرات المطلوبة موجودة أصلًا في Production.

## 2. استرجاع الحالة والمصادر

تمت إعادة قراءة وثيقة `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP`، وReport128، و`CURRENT_STATE.md`، ثم فتح Main9 الحالي والتاريخي والتحقق من `forensic_main_assembly.yml`.

Source of Truth المثبت:

`Current/PWA/main2/main1.md` … `main11.md`

Historical reference:

`Original/PWA/main/main*`

Forbidden/retired:

`Current/PWA/main/*`

`Current/PWA/New-main/*`

و`forensic_main_assembly.yml` ما زال موجهًا إلى `Current/PWA/main2` وAssembly مؤجلًا. fileciteturn1321file0L2-L6

تمت مطابقة هويات الأجزاء الحالية Main1..Main11، ومنها Main1–Main7 وMain8 وMain9 وMain10 وMain11 بالـSHAs الحالية المباشرة. Main9 الحالي هو:

`b9f10ae4e727cb9495aaec2d752dabf13ec776` fileciteturn1356file0L2-L6

وMain8 الحالي المثبت مباشرة:

`f67c0217a804d2cb2388ce48fb7f95176c075fb3` fileciteturn1348file0L2-L6

تم تحديث `CURRENT_STATE.md` وتصحيح Main8 SHA القديم، وأصبح SHA الحالة:

`599419ab02a6b3848a73c50e37706ae076657def` fileciteturn1354file0L2-L6

## 3. Main9 — القراءة الكاملة

تمت إعادة قراءة Main9 من البداية عبر حدود متتابعة، ثم اختبار القراءة بعد نهاية الملف؛ القراءة اللاحقة أعادت محتوى فارغًا، فأثبت ذلك الوصول إلى EOF. fileciteturn1323file0L2-L6

تم فتح `Original/PWA/main/main9.md` للمقارنة التاريخية، ولم يتم الرجوع إليه كمصدر تحرير لأن النسخة التاريخية أبسط ولا تمثل عقد Main9 الحالي. fileciteturn1288file0L2-L6

## 4. ما هو صحيح حاليًا ولا يحتاج جراحة مكررة

- `_companyId()` لديه مسار Company Context واضح.
- `_loadDropdowns(params)` يستخدم Company Scope.
- `_showCustomerLedgerDetail` و`_showItemMovementDetail` و`_showRunsheetDetail` و`_showSettlementDetail` تتحقق من company context.
- لا توجد مطابقة جديدة مطلوبة لهذه الأجزاء دون دليل إضافي.

## 5. الفجوات الفعلية المثبتة في Main9

### MAIN9-N1 — Finance underexposure

Main9 يعرض تقارير مالية أساسية، بينما Production يحتوي RPCs رقابية/تحليلية إضافية جاهزة:

`accountant_customer_aging`

`accountant_supplier_aging`

`accountant_gl_account_activity`

`accountant_period_readiness`

`accountant_reconciliation_summary`

`accountant_exception_center`

إخفاؤها يجعل الشاشة أقل من العقد الحالي المثبت في Production.

### MAIN9-N2 — CRM followups

الكتلة الحالية `crm-customer-followups` عبارة عن Capability Gate، رغم أن جدول `customer_followups` موجود في Production. آخر فحص مباشر:

`2026-09-12 06:45:28 UTC`

`followups_total = 0`

`null_company = 0`

المصدر موجود، لكن لا توجد بيانات أعمال مسجلة حاليًا.

### MAIN9-N3 — Runsheet performance

التنفيذ الحالي لا يقدم عمق KPI الذي يصفه التقرير. تم إعداد بديل يعتمد على:

`runsheets → orders → order_details`

ويحسب:

الأوردرات، الكمية المطلوبة، المسلم، نسبة التسليم، المرفوض، المرتجع، قيمة التسليم، قيمة المرتجع.

هذا يحافظ على `order_details` كمصدر fulfillment detail ولا ينشئ aggregate موازيًا.

### MAIN9-N4 — Driver performance

التنفيذ الحالي كان سطحيًا. تم إعداد بديل يشتق KPI السائقين من نفس تدفق `runsheets → orders → order_details`.

### MAIN9-N5 — Returns compatibility

Main9 الحالي يقرأ `SalesReturn` و`DirectReturn` فقط. تم إعداد إضافة `Return` إلى نفس قائمة القراءة بدون حذف الأنواع الحالية.

### MAIN9-N6 — generic fallback

يوجد fallback عام `هذا التقرير غير متوفر بعد`. هذا fallback خاص بمعرّف تقرير غير معروف، وليس Capability Gate خاصًا بعمل غير مكتمل.

## 6. Production truth — بدون تخمين

تم فحص `post_stock_movement` مباشرة في Production.

ثبت أن:

- `items.item_code` عليه UNIQUE constraint رسمي.
- Physical stock mutations تمر عبر `post_stock_movement`.
- Branch source/target validation مرتبطة بـ`company_id`.
- Item Master يُحل بالـ`item_id` داخل المحرك المركزي.

وبسبب وجود بيانات cross-company stock rows في Production، لم يتم اتخاذ قرار data repair أو تعديل Item Master scoping داخل Main9 من تلقاء النفس. هذا يحتاج closure مستقل مبني على historical contract، لا استنتاج من شكل البيانات وحده.

## 7. Production execution result

لم يتم تنفيذ Production migration خاص بـMain9 لأن ذلك غير مطلوب ولم يثبت وجود backend gap يجب ترقيعه.

تم الاكتفاء بالمطابقة والـcontract tracing المباشر، مع عدم إنشاء reporting engine موازي.

## 8. Owner Surgical Replacement Package

تم إنشاء:

`doc/Draft/Reprots/MAIN9_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

Commit:

`ccfed3c009f66ae44b42c0d5901f90effafaf4ed`

Blob SHA:

`d10803a93a9da0061bdf93481ed9cf73da4f004a` fileciteturn1355file0L2-L6

الحزمة تحتوي البدائل الكاملة، وليست snippets.

## 9. تعليمات Owner الدقيقة

### O1 — Finance structure

في `_reportsStructure` ابحث عن:

`'finance': {`

واحذف الكتلة كاملة حتى `},` الموجود مباشرة قبل:

`'crm': {`

واستبدلها بالقسم `O1_FINANCE_REPORT_STRUCTURE` كاملًا من الحزمة.

### O2 — Finance runtime

داخل `_generateReport` ابحث عن:

`else if (reportId === 'finance-tax') {`

واحذف الكتلة كاملة حتى القوس `}` الموجود مباشرة قبل بداية قسم CRM.

استبدلها بالقسم `O2_FINANCE_RUNTIME_TAIL` كاملًا من الحزمة.

### O3 — CRM followups

ابحث عن:

`else if (reportId === 'crm-customer-followups') {`

ثم احذف الكتلة كاملة حتى القوس النهائي للـbranch الحالي، واستبدلها بالقسم `O3_CRM_FOLLOWUPS` كاملًا.

### O4 — Runsheet performance

ابحث عن:

`else if (reportId === 'sales-runsheet-performance') {`

واحذف الكتلة كاملة حتى القوس النهائي الموجود مباشرة قبل تعليق:

`INVENTORY`

واستبدلها بالقسم `O4_RUNSHEET_PERFORMANCE` كاملًا.

### O5 — Driver performance

ابحث عن:

`else if (reportId === 'logistics-driver-performance') {`

واحذف الكتلة كاملة حتى القوس النهائي الموجود مباشرة قبل تعليق:

`HR`

واستبدلها بالقسم `O5_DRIVER_PERFORMANCE` كاملًا.

### O6 — Returns compatibility

داخل `logistics-returns` ابحث عن القائمة الكاملة:

```text
.in(
    'movement_type',
    [
        'SalesReturn',
        'DirectReturn'
    ]
)
```

واستبدلها فقط بـ:

```text
.in(
    'movement_type',
    [
        'Return',
        'SalesReturn',
        'DirectReturn'
    ]
)
```

ولا تغيّر أي سطر آخر في هذه الكتلة.

### O7 — لا تعِد إصلاح الصحيح

لا تعِد كتابة `_companyId()` أو `_loadDropdowns(params)` أو Drill-Down الحالية بدون دليل جديد.

## 10. اختبارات وفحوصات

### Static search

البحث في Main9 عن:

`قيد التطوير`

أعاد `0 matches`.

أما:

`غير متوفر بعد`

فموجود فقط في generic unknown-report fallback، وليس كبديل لأي Capability Gate محددة.

### Package validation

حزمة Owner Surgical Replacement تم إنشاءها ومراجعة بنيتها بعد الإصلاح.

لم يتم تسجيل `MAIN9 SYNTAX = PASS` للملف الأصلي، لأن الملف لم يتغير بعد من طرف Owner، وبالتالي لا توجد نسخة post-apply يجوز نسب syntax validation إليها.

### Runtime

لا يوجد post-owner runtime test حتى الآن، وبالتالي لم يتم تحويله إلى PASS.

## 11. Self-Audit

### What I Proved

- Main9 الحالي صحيح المسار والـSHA.
- Main9 تم الوصول فيه إلى EOF.
- Main9 التاريخي لا يصلح كمصدر تحرير بديل.
- `forensic_main_assembly.yml` يوجه إلى Main2.
- Finance Production RPCs الإضافية موجودة فعلًا.
- `customer_followups` موجودة فعلًا.
- Runsheet/Driver performance يمكن اشتقاقها من `order_details` دون إنشاء مصدر بيانات جديد.
- Main9 لديه فجوات وظيفية محددة وليست مجرد ملاحظات شكلية.

### What I Did Not Prove

- لم يتم Owner Apply بعد.
- لم يتم executable syntax validation لنسخة post-apply.
- لم يتم Browser/E2E.
- لم يتم Assembly.
- لم يتم إثبات أن كل إمكانات المشروع العالمي مكتملة؛ هذه مهمة أوسع من Main9.

### What I Fixed

- تم إنشاء Owner Surgical Package كامل.
- تم تحديث `CURRENT_STATE.md`.
- تم تصحيح Main8 SHA stale داخل state.
- تم توثيق حالة Main9 الحالية وما تبقى بدقة.

### Remaining Risks

- خطأ merge/escaping بعد Owner Apply.
- فجوات تكامل تظهر عند جمع Main1–Main11.
- HR attendance/salary وTax تبقى Capability Gates حتى يثبت Production source contract.
- Item Master data contract يحتاج closure مستقل قبل أي repair واسع للبيانات الحالية.

## 12. الحالة النهائية

```text
MASTER GOVERNANCE = READ
MAIN9 FULL SOURCE READ = PASS
MAIN9 EOF = VERIFIED
MAIN9 HISTORICAL REVIEW = PASS
MAIN1..MAIN11 SOURCE IDENTITY RECONCILIATION = PASS
FORENSIC ASSEMBLY SOURCE PATH = CORRECT
MAIN9 PRODUCTION CONTRACT TRACE = PASS
MAIN9 CRM PRODUCTION SOURCE TRACE = PASS
MAIN9 OWNER SURGICAL PACKAGE = READY
MAIN9 SOURCE EDITED BY ASSISTANT = NO
MAIN9 OWNER APPLY = PENDING
MAIN9 POST-APPLY SYNTAX = PENDING
MAIN9 BROWSER/E2E = PENDING
MAIN9 FINAL INTEGRATION = PENDING
ASSEMBLY = DEFERRED
GLOBAL GOLD/DIAMOND = OPEN
```

## 13. نقطة الاستئناف التالية

بعد Owner Apply:

1. إعادة قراءة `Current/PWA/main2/main9.md` من أول حرف إلى EOF.
2. executable syntax validation للملف الكامل.
3. duplicate declarations / braces / strings / HTML escaping audit.
4. Finance advanced reports runtime.
5. CRM followups runtime.
6. Runsheet and Driver KPI runtime.
7. Returns runtime.
8. مزامنة Production في نفس لحظة تقرير الإغلاق.
9. بعد الإغلاق فقط تستمر خطة Assembly عند اكتمال بقية الأجزاء.
