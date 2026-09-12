# Report131 — إعادة الفحص الجنائي لـ Main10 وتحديد الإصلاحات الجراحية — 2026-09-12

## 0. الهدف الحاكم — يجب قراءته بعناية وتكراره

**هناك نقص شديد في كل التبويبات ، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا تتعامل معه كإضافات شكلية. وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا، ثم إعادة بناء العقد التاريخي، ثم تتبع السلوك الحالي، ثم تحديد الفجوة، ثم التعديل الجراحي، ثم الاختبار والتحقق.**

وهذا مبدأ حاكم في هذه الجلسة أيضًا.

---

## 1. نطاق الجلسة

تم إيقاف أي مسار سابق، وتم تركيز الجلسة على:

`Current/PWA/main2/main10.md`

ولم يتم تعديل Source Fragment بواسطة المساعد.

الملفات التاريخية استُخدمت للاسترشاد فقط، وبالأخص:

`Original/PWA/main/main10.md`

والحزمة السابقة لـMain9 والتقارير 129 و130 استُخدمت كدليل تاريخي فقط، ولم تُعامل كـCurrent Truth.

---

## 2. استرجاع الحالة والتحقق المباشر

### Governance

تمت مراجعة وثيقة:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

والقواعد المؤثرة في هذه المهمة هي:

- التقرير ليس Production Truth.
- لا يوجد Claim دون Evidence.
- لا توجد Full Read دون EOF.
- الدراسة التاريخية تسبق التعديل.
- Owner يطبق تغييرات Main2 fragments.
- Assembly مؤجل.
- Production لا يُعد مغلقًا بمجرد إعداد الكود أو الـcommit.

### Current State

تم فتح `CURRENT_STATE.md` ومطابقته مع Git الحالي.

تم اكتشاف تعارض مهم:

الحالة القديمة كانت تسجل Main9:

`b9f10ae4e727cb9495aaec2d752dabf13ec776`

بينما Git الحالي بتاريخ 2026-09-12 يعطي:

`b68e5d8f0f52258080950add12fd7fcecbf8c0d7`

وبالتالي تم تصنيف SHA القديم على أنه **STALE** وتم تحديث `CURRENT_STATE.md`.

### Assembly Source

تم فتح:

`forensic_main_assembly.yml`

وتأكد أن:

`source_of_truth: Current/PWA/main2`

وأن الأجزاء الحالية هي:

`main1.md` … `main11.md`

ولا يوجد احتياج لتعديل هذا الملف في جلسة Main10.

---

## 3. Main10 — القراءة الكاملة والتحقق من EOF

Source:

`Current/PWA/main2/main10.md`

SHA:

`169025a6836c7fdc7281ea86523b975a84d889f1`

Git metadata:

`20018 bytes`

تمت القراءة على حدود متتابعة تغطي:

`1–80`
`81–160`
`161–240`
`241–320`
`321–400`

ثم تم اختبار النطاق التالي:

`401–480`

والنتيجة كانت محتوى فارغًا.

لذلك تم إثبات:

`MAIN10 EOF = LINE 400`

---

## 4. Historical Reconstruction — Main10

تم فتح:

`Original/PWA/main/main10.md`

وتبين أن الهيكل التاريخي يحتوي أساسًا على:

- `RW_OwnerLicense`
- `RW_Views`

مع نفس الفكرة العامة الحالية.

النسخة الحالية أضافت Company Context في قراءة الترخيص، لكنها أبقت بعض السلوكيات القديمة غير الآمنة من ناحية UX والـrouting.

لم يتم الرجوع إلى النسخة التاريخية كمصدر تحرير بديل.

---

## 5. Main10 الحالي — التكوين الفعلي

Main10 يحتوي وظيفيًا على وحدتين رئيسيتين:

### A — `RW_OwnerLicense`

المهام الحالية:

- قراءة `app_settings`.
- بناء شاشة الترخيص.
- تغيير البريد الإلكتروني.
- تغيير كلمة المرور.
- حفظ إعدادات الترخيص من خلال `save-settings`.

### B — `RW_Views`

المهام الحالية:

- permission routing.
- page titles.
- dispatch إلى وحدات النظام المختلفة.
- fallback للـviews غير المعروفة.

---

## 6. Production Trace المرتبط بـMain10

تم فحص Production Edge Function:

`save-settings`

الحالة الحالية:

- `verify_jwt = true`.
- يتم استخراج `company_id` من `users.auth_id` للمستخدم المصادق.
- license edits تتطلب Owner semantics.
- Owner verification تعتمد على:
  - `isOwner = true`
  - wildcard `*` في auth metadata
  - wildcard `*` في DB permissions
- `main_branch_id` يتم التحقق من تبعيته للشركة.

الاستنتاج:

**لا يوجد Backend Production gap مثبت يخص الإصلاحات الحالية في Main10، لذلك لم تُنفذ Production migration جديدة لهذه المهمة.**

---

## 7. الفجوات الفعلية المثبتة

### M10-01 — Default State is invented when Company Context is missing

Current behavior:

عند عدم وجود `companyId` يتم إنشاء نموذج بحالة:

`licenseStatus: 'trial'`

هذه ليست قراءة لحالة Production، بل قيمة افتراضية.

وهذا يخالف قاعدة:

`NO ASSUMPTIONS`

الإصلاح الصحيح هو عرض عدم توفر Company Context بدل اختراع حالة ترخيص.

---

### M10-02 — Current Email is written into the NEW Email field

Current behavior داخل `_buildFullForm()`:

يتم جلب authenticated user ثم:

`byId('owner-new-email').value = currentEmail`

وهذا يملأ حقل البريد الجديد بالبريد الحالي.

النتيجة UX غير صحيحة ويمكن أن توهم المالك بأن الحقل جاهز كـnew email.

الإصلاح:

- يبدأ current email من `licenseInfo.ownerEmail`.
- بعد بناء DOM يتم تحديث `owner-current-email` من authenticated user.
- لا يتم تعبئة `owner-new-email` تلقائيًا.

---

### M10-03 — Password Confirmation is unused

يوجد حقل:

`owner-confirm-password`

لكن الكود الحالي يرسل:

`auth.updateUser({ password: newPass })`

دون مقارنة التأكيد.

الإصلاح:

- رفض الحفظ إذا كان التأكيد فارغًا.
- رفض الحفظ إذا لم تتطابق القيمتان.
- تفريغ الحقلين بعد نجاح العملية.

لم يتم اختراع Password Policy جديدة لأن ذلك غير مثبت في المصدر.

---

### M10-04 — Email syntax is not explicitly validated in click handler

وجود:

`type="email"`

لا يكفي هنا لأن handler ينفذ مباشرة دون submit validation.

الإصلاح:

إضافة basic syntax validation قبل استدعاء `auth.updateUser`.

لا يوجد تغيير في Supabase Auth policy.

---

### M10-05 — Finance route bypasses the common permission map

Current `permissionMap` لا يحتوي:

`finance`

بينما Production users يحتوي لديهم بالفعل permission:

`finance`

بالتالي:

`RW_Views.render('finance')`

يمكن أن يصل إلى:

`RW_Finance.render()`

دون المرور بنفس gate الموجود لبقية التبويبات.

الإصلاح:

`'finance': 'finance'`

---

### M10-06 — HR route uses the wrong permission key

Current mapping:

`'hr': 'users'`

بينما Production permissions تحتوي `hr` كمفتاح مستقل.

الإصلاح:

`'hr': 'hr'`

ولا يتم تغيير شاشة HR نفسها في Main10.

---

### M10-07 — Several router titles are missing

العناوين الناقصة المثبتة من الـrouter الحالي:

- `finance`
- `hr`
- `crm`
- `reports-comprehensive`

الإصلاح هو إضافة عناوين صريحة فقط.

---

### M10-08 — Unknown route is reported as "قيد التطوير"

Current fallback:

`قيد التطوير`

هذا ليس دليلًا على وجود Business Capability ناقصة، ولذلك الوصف نفسه غير دقيق.

الإصلاح:

`التبويب غير معروف`

حتى لا يخلط Router behavior مع Functional Completion status.

---

## 8. عناصر تمت مراجعتها ولم تحتاج تعديلًا

### `_saveSettings(payload, label)`

تمت مراجعته ولم يثبت احتياج تعديل جديد في Main10.

سبب الإبقاء عليه:

- الـEdge backend الحالي company-aware.
- authentication enforced.
- Owner verification موجود في Production.

لذلك لم يتم إعادة كتابة الدالة دون دليل جديد.

---

## 9. Owner Surgical Package

تم إنشاء:

`doc/Draft/Reprots/MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

Commit:

`6d289a85d6e3a8a2b71c41f242e425c808f86c0b`

الحزمة تحتوي 4 عمليات محددة فقط:

### M10-O1

تعديل كتلة:

`if (!companyId) { ... }`

داخل `_loadLicenseData()`.

### M10-O2

استبدال كامل:

`function _buildFullForm(licenseInfo)`

الموقع الحالي:

`lines 102–163`

### M10-O3

استبدال كامل:

`function _bindSaveButtons()`

الموقع الحالي:

`lines 165–221`

### M10-O4

استبدال كامل:

`var RW_Views = {`

حتى:

`window.RW_Views = RW_Views;`

الموقع الحالي:

`lines 262–400`

---

## 10. ما تم تنفيذه فعليًا في Git خلال هذه الجلسة

### تم إنشاء

`doc/Draft/Reprots/MAIN10_OWNER_SURGICAL_REPLACEMENTS_20260912.js`

### تم تحديث

`CURRENT_STATE.md`

مع:

- Main10 checkpoint.
- Main10 SHA.
- Main9 SHA reconciliation.
- Main10 exact owner locations.
- Main10 open status.

### لم يتم تعديل

`Current/PWA/main2/main10.md`

### لم يتم تعديل

`forensic_main_assembly.yml`

### لم يتم تعديل Production بسبب Main10

لا توجد Production migration مرتبطة مباشرة بمثبتات Main10 في هذه الجلسة.

---

## 11. الاختبارات والتجارب

### Test A — Main10 EOF

**PASS**

تمت قراءة Main10 حتى line 400 ثم اختبار ما بعده، والنتيجة empty content.

### Test B — Historical Main10 comparison

**PASS**

تم فتح `Original/PWA/main/main10.md` ومقارنة الهيكل العام.

### Test C — Production save-settings contract

**PASS**

تم فحص Edge Function الحالي والتأكد من authentication وcompany ownership وOwner semantics.

### Test D — Production permissions

**PASS**

تم الاستعلام من Production عن permission vocabulary والتأكد من وجود:

`finance`

و:

`hr`

وهذا يثبت أن mappings الحالية ليست مطابقة للعقد الفعلي.

### Test E — Executable `node --check` على Current Main10

**NOT CLAIMED**

الـGitHub connector سمح بقراءة Main10 عبر exact line ranges وEOF verification، لكنه لم يوفر artifact محليًا قابلًا للتنفيذ مباشرة بواسطة Node في هذه الجلسة.

لذلك لم يتم تسجيل:

`MAIN10 NODE CHECK = PASS`

حتى لا يتحول فحص بصري إلى ادعاء executable validation.

---

## 12. Self-Audit

### What I Proved

- Main10 Source of Truth الحالي هو `Current/PWA/main2/main10.md`.
- Main10 SHA الحالي هو `169025a6836c7fdc7281ea86523b975a84d889f1`.
- Main10 يصل إلى EOF عند line 400.
- Main10 التاريخي تم فتحه ومراجعته.
- Production `save-settings` الحالي company-aware وOwner-protected.
- permission `finance` موجود فعليًا في Production.
- permission `hr` موجود فعليًا في Production.
- توجد 8 فجوات وظيفية/Router/UX مثبتة في Main10.
- لا تحتاج هذه الفجوات إلى Production schema migration جديدة.
- Owner package يحتوي replacements كاملة وليست snippets مبتورة.
- `forensic_main_assembly.yml` صحيح المسار إلى Main2.

### What I Did Not Prove

- Owner Apply لم يتم بعد.
- Post-apply executable syntax لم يتم بعد.
- Browser/E2E لم يتم بعد.
- Assembly لم يتم بعد.
- Global Gold/Diamond closure للمشروع كله غير مكتمل.
- لم يتم إثبات أن بقية Main1–Main11 تحتاج أو لا تحتاج تغييرات جديدة خلال مهمة Main10 إلا على مستوى identity/path reconciliation، لأن نطاق التنفيذ المطلوب هنا Main10.

### What Could Still Be Wrong

- خطأ Owner copy/paste أثناء تطبيق replacement.
- خطأ escaping في الدمج اليدوي.
- Consumer contract إضافي لا يظهر في Main10 وحده.
- نقص وظيفي في الوحدات التي يستدعيها Main10 نفسها، وهو خارج هذا fragment ويحتاج closure خاصًا بها.

---

## 13. الحالة النهائية

```text
GOVERNANCE = READ / RECONCILED
CURRENT_STATE = UPDATED
MAIN10 SOURCE PATH = VERIFIED
MAIN10 SOURCE SHA = VERIFIED
MAIN10 FULL READ = PASS
MAIN10 EOF = VERIFIED
MAIN10 HISTORICAL READ = PASS
PRODUCTION LICENSE CONTRACT = VERIFIED
PRODUCTION PERMISSION VOCABULARY = VERIFIED
MAIN10 GAPS = IDENTIFIED
MAIN10 OWNER PACKAGE = CREATED
MAIN10 SOURCE EDITED BY ASSISTANT = NO
MAIN10 OWNER APPLY = PENDING
MAIN10 EXECUTABLE SYNTAX = PENDING OWNER APPLY
MAIN10 BROWSER/E2E = PENDING
MAIN10 PRODUCTION RUNTIME CLOSURE = PENDING
ASSEMBLY = DEFERRED
GLOBAL GOLD/DIAMOND = OPEN
```

---

## 14. نقطة الاستكمال التالية

بعد Owner Apply فقط:

1. إعادة قراءة `Current/PWA/main2/main10.md` من line 1 إلى EOF الجديد.
2. executable syntax validation على الملف الكامل.
3. structural audit للـbraces / strings / HTML escaping / duplicate globals.
4. route coverage validation.
5. permission gate verification.
6. Owner License interaction verification.
7. Browser/E2E.
8. Production sync في لحظة تقرير الإغلاق.
9. ثم فقط يمكن تغيير حالة Main10 من `PENDING` إلى `CLOSED`.

**لا يوجد في هذه الجلسة أي ادعاء بأن Main10 مغلق أو Gold/Diamond مغلق قبل تنفيذ هذه الخطوات.**
