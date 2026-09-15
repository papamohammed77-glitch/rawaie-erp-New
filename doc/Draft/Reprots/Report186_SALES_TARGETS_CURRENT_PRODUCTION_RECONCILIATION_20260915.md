# Report186 — SALES TARGETS CURRENT PRODUCTION RECONCILIATION

**التاريخ:** 2026-09-15
**النطاق:** Sales Targets Engine / Current Mother E2E readiness / Production reconciliation

## 1. قاعدة الحوكمة

تم تطبيق القاعدة الحاكمة: التقارير السابقة استُخدمت كمرجع تاريخي فقط، والحالة الحالية بُنيت من:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ومصدر الحقيقة للنظام الأم هو:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

المجلدات التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` و`New-main` لم تُستخدم كمصدر حالة حالي.

## 2. Current Git Evidence

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`

Current HEAD:
`dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`

Direct parent:
`f46dfc8183068d0dbf52c1b3b3c8cdbfc9f8f914`

Parent of parent:
`8b02f2158021b6ca4ce44ced756459b037fb1ebe`

Current mother blob from HEAD commit:
`8bf3ac606cdc2d51c2d705ff5f921e46dbbe6607`

Latest commit is signed/verified and modifies `companies/company-1/main.html`.

The latest commit already contains the Sales Targets frontend surgeries previously requested by Report185:
- `postOperationIds = {}` بدل المتغير العام الواحد.
- زر `خطة جديدة / تفريغ النموذج` بصلاحية الإدارة.
- `approvePlan()` و`cancelPlan()` باستخدام `canApprove()`.
- زر `إعادة ضبط` داخل `openAssignmentEditor()`.
- `postRun()` بهوية عملية لكل خطة.

### Current source anchors

- حوالى السطر 1309: بداية `RW_SalesTargetsMain`.
- حوالى السطر 1312: `var postOperationIds = {};`
- حوالى السطر 1578: أزرار خطة جديدة / المعاينة / إدارة الخطط.
- حوالى السطر 1670: `approvePlan()`.
- حوالى السطر 1682: `cancelPlan()`.
- حوالى السطر 1791: كتلة `showDenyButton` و`preDeny` في `openAssignmentEditor()`.
- حوالى السطر 1857: `postRun()`.

**لا يوجد في Current Git ما يبرر إعادة هذه الجراحات مرة أخرى.**

## 3. Current Mother / EOF Evidence

تمت مطابقة HEAD الحالي مع Parent وParent-of-parent، وتم التأكد من أن أحدث تعديل للنظام الأم هو commit `dddf1a...`.

القراءة الكاملة المباشرة لجسم الملف حتى EOF لم تكن قابلة لإعادة العرض سطرًا بسطر في هذه البيئة لأن GitHub يقيّد عرض هذا الـblob الكبير؛ لذلك **لا يُدّعى هنا إثبات بصري كامل جديد للـEOF**. تم الاحتفاظ بهذه النقطة كحد تحقق صريح وعدم تحويلها إلى claim غير مثبت.

## 4. Production Sales Targets — الحالي

Supabase project:
`fiilmooggumokxanwiyx`

RPCs:
- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

Edge Functions الحالية:
- `sales-target-engine` ACTIVE
- `sales-target-dashboard` ACTIVE
- verify_jwt=true حسب Production evidence السابقة المعاد مطابقتها في هذه الجلسة.

الجداول:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

بعد الاختبارات Transactional الأخيرة:
- plans = 0
- assignments = 0
- runs = 0
- run_lines = 0

أي أن اختبارات E2E لا تترك بيانات تشغيلية خلفها.

## 5. Production Fixes Executed In This Session

### 5.1 REVERSE_RUN idempotency

تم اكتشاف خلل حقيقي في ترتيب منطق الـidempotency:
كان النظام يفحص حالة الـsource run قبل البحث عن نفس `operation_id`. بعد أول Reverse تصبح العملية الأصلية `Reversed`، وبالتالي كان retry لنفس العملية يفشل بدل إرجاع `duplicate=true`.

تم التصحيح في Production إلى:

`operation_id duplicate lookup → duplicate return → source state validation → reverse`

وهذا يغلق حالة retry بعد نجاح الـReverse.

### 5.2 SAVE_PLAN edit ambiguity

النسخة المصححة الأولى كشفت أثناء الاختبار Transactional عن تعارض اسم PL/pgSQL variable `metric` مع عمود `metric` أثناء `UPDATE`.

تم إصلاح ذلك بتأهيل أعمدة `sales_target_plans` داخل UPDATE.

لم يتم Commit لأي بيانات اختبارية؛ الفشل وقع داخل Transaction وتم Rollback.

## 6. Production E2E Executed

تم تنفيذ E2E Transactional كامل على Production، باستخدام بيانات اختبارية داخل Transaction واحدة مع Rollback في النهاية.

التسلسل الناجح:

`SAVE_PLAN`
→ `EDIT_PLAN`
→ `SAVE_ASSIGNMENT`
→ `SET_ASSIGNMENT_ACTIVE(false)`
→ `SET_ASSIGNMENT_ACTIVE(true)`
→ `DASHBOARD`
→ `APPROVE_PLAN`
→ `CLOSE_PLAN`
→ `CLONE_PLAN`
→ `APPROVE_CLONE`
→ `POST`
→ `POST duplicate`
→ `APPROVE_RUN`
→ `REVERSE_RUN`
→ `REVERSE duplicate`
→ `SAVE_PLAN(cancel setup)`
→ `CANCEL_PLAN`
→ `ROLLBACK`

النتيجة: **PASS** بدون أخطاء Production في الدورة النهائية.

تم التحقق بعد ذلك من أن بيانات الاختبار عادت إلى:
`plans=0, assignments=0, runs=0, run_lines=0`.

## 7. Important Failed Attempts And Root Causes

### Failure A — Reverse duplicate

السبب: فحص حالة source قبل idempotency lookup.

الحل: تقديم البحث عن `operation_id` على فحص حالة المصدر.

### Failure B — Edit Plan

السبب: ambiguity بين متغير PL/pgSQL `metric` وعمود table `metric`.

الحل: تأهيل أعمدة جدول `sales_target_plans` داخل UPDATE.

### Failure C — Browser Console `RW_SalesTargetsMain is not defined`

المصدر الحالي في Git يحتوي فعليًا على:
`var RW_SalesTargetsMain = (function(){...`.

لذلك فإن رسالة Console القديمة لا تكفي لإثبات أن Current Source ما زال يحتوي العيب.

لم يتم إجراء تعديل جديد على هذا الجزء من الملف بناءً على هذه الرسالة وحدها؛ لأن ذلك سيكون تخمينًا.

## 8. Current Frontend Decision

لا يوجد Owner Surgery جديد مبرر في هذه الجلسة حتى تظهر Browser/Network evidence جديدة من النسخة المنشورة الحالية بعد HEAD:
`dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`

الجراحات السابقة موجودة بالفعل في Current Git.

يجب عدم إعادة تعديل:
- `postOperationIds`
- `postRun()`
- `approvePlan()`
- `cancelPlan()`
- زر `خطة جديدة / تفريغ النموذج`
- كتلة `إعادة ضبط`

إلا إذا أثبت Browser/Source الحالي اختلافًا عن HEAD.

## 9. Forensic Assembly Path

تمت مطابقة المسار الموجود في repository:
`forensic_main_assembly.yml`

وهو مرتبط بالنظام الأم المنشور، ولم تظهر في Current Git حاجة لتغيير المسار في هذه الجلسة. أي تعديل لمسار صحيح سيكون تغييرًا بلا أساس مثبت.

## 10. Final Self Audit

### What was proved

- Current Git HEAD وParent وParent-of-parent.
- Current mother file identity from HEAD.
- Current Sales Targets frontend anchors الموجودة في source diff الحالي.
- Production RPC structure.
- Production E2E الكامل بعد إصلاحات هذه الجلسة.
- Reverse idempotency الصحيح.
- Edit Plan correctness.
- Clone / Approve / Post / duplicate / Approve Run / Reverse / duplicate Reverse.
- Production test cleanup إلى صفر بيانات.

### What was not proved

- Browser E2E حقيقي من متصفح خفي جديد.
- Console/Network evidence من النسخة المنشورة بعد HEAD `dddf...`.
- قراءة بصرية مستقلة لكل سطر من Current Mother حتى EOF داخل واجهة الأداة، بسبب حد عرض الـblob الكبير.

### Current closure

`Sales Targets Production Engine = VERIFIED`
`Sales Targets Production E2E = VERIFIED`
`Current Git/source baseline = VERIFIED`
`Mother browser E2E = OPEN`
`Full Mother UI closure = OPEN until fresh browser/served-source proof`

## 11. Decision For Next Session

لا تعُد إلى الإصلاحات التي ثبت أنها موجودة في Current Git.

الخطوة التالية الصحيحة هي مقارنة النسخة التي يقدمها المتصفح فعليًا مع:
- HEAD `dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`
- blob `8bf3ac606cdc2d51c2d705ff5f921e46dbbe6607`

ثم تسجيل Console + Network + served-source proof قبل أي Owner Surgery جديد.
