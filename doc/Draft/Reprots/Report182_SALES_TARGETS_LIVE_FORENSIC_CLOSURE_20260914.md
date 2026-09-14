# Report182 — SALES TARGETS LIVE FORENSIC CLOSURE

**التاريخ:** 2026-09-14 18:xx Africa/Cairo
**الحالة المرجعية:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

## 1. تنبيه حاكم

هذا التقرير لا يعتمد على Report178 أو Report179 أو Report180 أو Report181 كحالة حالية. تلك التقارير استُخدمت فقط لفهم السياق، بينما نتائج هذا التقرير مبنية على الفحص المباشر للمصادر الحالية.

## 2. Current Git — Mother Source

تمت مراجعة مستودع `papamohammed77-glitch/erp-frontend` والفرع `main`.

- HEAD: `9e6645bf3c613f8995785d1fe70a88150ce87c16`
- Direct Parent: `91e50848a65cb0255e95c4e7d8f1a1523eb43e85`
- Parent of Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
- Mother file: `companies/company-1/main.html`
- Current blob: `85a8a3593251a1f7c2ddbc8654cc192db8c4a0c2`
- Source timestamp inside file: `2026-09-14 00:40 UTC`
- Current repository metadata previously reconciled file size: `1,087,515 bytes`

تم فحص الـblob نفسه حتى وجود EOF الفعلي داخل المحتوى، والـend markers الحالية هي `</script>` ثم `</body>` ثم `</html>`.

## 3. Current Mother Source — Sales Targets

المصدر الحالي يثبت:

1. `RW_Navigation.menuTree` يحتوي `sales-targets`.
2. Dispatcher ينفذ `RW_SalesTargetsMain.render()` عند فتح التبويب.
3. `RW_SalesTargetsMain` موجود في المصدر الحالي.
4. `render()` يستخدم `var c=byId('rw-page-container');`.
5. الاستدعاء التلقائي للخطة الأولى يستخدم `RW_SalesTargetsMain.selectPlan(plans[0].id)`.
6. لا يوجد مسار `rw-page-content` داخل Sales Targets الحالي.
7. `safeHTML` موجود كدالة عامة في المصدر.
8. Sales Targets يستخدم الاسم `RW_UI.safeHTML` رغم عدم وجود تعريف `RW_UI` في المصدر الحالي.

### Root Cause المثبت

الـConsole الحالي أعطى:

`Uncaught (in promise) ReferenceError: RW_UI is not defined`

عند `main:1390` أثناء `RW_SalesTargetsMain.render()`.

هذا يطابق المصدر الحالي مباشرة: أول عملية rendering هي:

```js
RW_UI.safeHTML(c,'<div class="rw-card"><div class="rw-loading">جاري تحميل محرك أهداف المبيعات...</div></div>');
```

وهي تستدعي كائنًا غير معرف.

المصدر الحالي يحتوي بالفعل على:

```js
const safeHTML = (el, html) => { if (!el) return; try { el.innerHTML = html; } catch(e) { console.error(e); } };
```

## 4. Owner Surgical Fix — Mother File

**لم يتم تعديل `erp-frontend/companies/company-1/main.html` بواسطة المساعد.**

الإصلاح المطلوب جراحيًا هو تعريف `RW_UI` فوق استخدامه، اعتمادًا على `safeHTML` الموجود أصلًا.

### العنصر المحدد

في `main.html` الحالي ابحث عن هذا السطر الكامل:

```js
const safeText = (el, text) => { if (!el) return; try { el.innerText = text; } catch(e) { console.error(e); } };
```

هذا السطر موجود في منطقة helpers السابقة لـ`RW_STATE`، مباشرة بعد تعريف `safeHTML`.

### الإضافة

أضف **السطر التالي مباشرة بعده**:

```js
const RW_UI = { safeHTML: safeHTML };
```

### لا تحذف أي جزء من `RW_SalesTargetsMain`.

لا تعدّل `render()` ولا `renderDashboard()` ولا `selectPlan()` في هذه المرحلة؛ الـRoot Cause المثبت هو missing symbol فقط، وأي تعديل إضافي في هذا الجزء سيكون غير مبرر حاليًا.

## 5. Current Production — Database

Supabase Production project:

`fiilmooggumokxanwiyx`

الحالة الحالية المباشرة:

- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`

أي أنه لا توجد بيانات Targets تشغيلية فعلية في Production يمكن بناء E2E business cycle كامل عليها دون إنشاء بيانات اختبارية.

## 6. Current Production — Sales Target DB Contract

تم التحقق مباشرة من Production:

- `sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)` موجود و`SECURITY DEFINER`.
- `sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)` موجود و`SECURITY DEFINER`.
- `sales_target_dashboard_atomic(uuid,uuid,text)` موجود و`SECURITY DEFINER`.
- `sales_target_integrity_guard()` موجود و`SECURITY DEFINER`.

العمليات المثبتة في الـengine تشمل:

`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

## 7. Current Production — Tenant / Authorization Evidence

المستخدم التشغيلي الموجود في Production:

`sales.manager@rawaea.com`

ولديه permission:

`sales_manager`

والـGateway يرفض المستخدم الذي لا يملك صلاحية الإدارة.

اختبار مباشر:

`sales.manager@rawaea.com` → `LIST_PLANS` = PASS، والنتيجة الحالية `plans=[]`.

`accountant@rawaea.com` → `SAVE_PLAN` = REJECTED بشكل صحيح برسالة `Sales target management permission required`.

## 8. Production Hardening المنفذ

تم اكتشاف أن `sales_target_integrity_guard()` كان يمنح `EXECUTE` إلى:

- PUBLIC
- anon
- authenticated
- postgres
- service_role

تم إصلاح ذلك مباشرة في Production عبر:

```sql
REVOKE ALL ON FUNCTION public.sales_target_integrity_guard()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.sales_target_integrity_guard()
  TO postgres, service_role;
```

ثم تم التحقق مباشرة من Production، والنتيجة أصبحت:

- postgres = EXECUTE
- service_role = EXECUTE
- لا يوجد EXECUTE لـPUBLIC
- لا يوجد EXECUTE لـanon
- لا يوجد EXECUTE لـauthenticated

والتغيير موثق في Git داخل:

`supabase/migrations/20260914_sales_target_integrity_guard_acl_hardening.sql`

## 9. Index / Constraint Review

تم فحص Indexes الحالية للـSales Targets.

الـProduction تحتوي بالفعل على indexes مناسبة للـcompany/plan/run/assignment وعلاقات الـforeign keys، منها:

- `sales_target_assignments_company_plan_idx`
- `sales_target_assignments_plan_fk_idx`
- `sales_target_assignments_rep_fk_idx`
- `sales_target_assignments_branch_fk_idx`
- `sales_target_plans_company_period_idx`
- `sales_target_runs_company_plan_idx`
- `sales_target_runs_plan_fk_idx`
- `sales_target_runs_reversal_fk_idx`
- `sales_target_run_lines_company_run_idx`
- `sales_target_run_lines_assignment_fk_idx`
- `sales_target_run_lines_rep_fk_idx`
- `sales_target_run_lines_branch_fk_idx`

لم يتم إنشاء Indexes مكررة.

## 10. Current Edge Deployment

تم التحقق من أن:

`sales-target-engine` = ACTIVE, version 2, verify_jwt=true.

`sales-target-dashboard` = ACTIVE, version 1, verify_jwt=true.

مصدر Edge الحالي في Git يستخدم `auth_id -> users.company_id` ثم يستدعي `sales_target_engine_gateway`، وهو متسق مع authorization boundary الحالية. لذلك لم يتم إنشاء version جديدة بلا تغيير وظيفي حقيقي.

## 11. Production Test Result

### نجح

- Current schema inspection.
- Current function inspection.
- Current grants inspection.
- `LIST_PLANS` عبر الـGateway بالمستخدم المصرح.
- رفض `SAVE_PLAN` لمستخدم غير مصرح.
- Security ACL hardening.
- التأكد من عدم وجود Test residue في `sales_target_plans`.

### لم يتم تنفيذه عمدًا

لم يتم إنشاء Plan/Assignment/Run اختبارية دائمة في Production لإجبار نجاح E2E business cycle؛ لأن Production الحالية لا تحتوي على Targets حقيقية، وإنشاء بيانات وهمية ثم حذفها سيشوّه سجل التدقيق ويجعل تقرير الأداء أقل موثوقية.

وبالتالي لم يتم الادعاء بأن:

`SAVE → APPROVE → PREVIEW → POST → APPROVE_RUN → REVERSE_RUN`

تم اختباره حاليًا في Production.

هذا قيد بيانات حقيقي، وليس عذرًا تقنيًا.

## 12. Forensic Conclusion

### Root Cause لعدم فتح التبويب

**Missing `RW_UI` symbol in current Mother Source.**

المحرك نفسه موجود، والـdispatcher موجود، والـcontainer الصحيح موجود، والـbackend الحالي قائم.

### Backend status

`SALES TARGET BACKEND = VERIFIED`

`SALES TARGET TENANT AUTHORIZATION = VERIFIED`

`SALES TARGET INTEGRITY GUARD ACL = HARDENED`

`SALES TARGET EDGE DEPLOYMENT = VERIFIED`

### Mother UI status

`SALES TARGET ROOT CAUSE = IDENTIFIED`

`SALES TARGET OWNER SURGERY = READY`

`LIVE BROWSER E2E = NOT CLOSED YET`

## 13. لماذا لم يتم تعديل أشياء أخرى

لم يتم:

- تغيير `RW_SalesTargetsMain.render()`.
- تغيير `selectPlan()`.
- تغيير dispatcher.
- إنشاء Edge Function جديدة.
- إنشاء جدول جديد.
- تعديل Schema الأعمال الحالية.
- تعديل `forensic_main_assembly.yml` لأنه صحيح بالفعل.
- إعادة إصلاح الإصلاحات السابقة الموجودة في HEAD.

السبب: لا يوجد دليل حالي يثبت أن هذه العناصر هي سبب فشل فتح التبويب.

## 14. Errors / Lessons

1. الاعتماد على تقرير سابق ادعى اكتمال E2E كان سيؤدي إلى قبول حالة غير مثبتة. تم تجاهل هذا الادعاء وإعادة التحقق من Production.
2. وجود `safeHTML` لم يكن كافيًا؛ وحدة Sales Targets استخدمت API namespace مختلفًا (`RW_UI`).
3. وجود Backend كامل لا يعني أن Mother UI يصل إليه؛ failure كان قبل أول network call داخل render.
4. لا يجوز إنشاء test data دائمة في Production فقط لإظهار PASS شكلي في التقرير.

## 15. Final Status

```text
CURRENT GIT                         = VERIFIED
CURRENT MOTHER SOURCE              = VERIFIED
CURRENT PRODUCTION                  = VERIFIED
CURRENT DATABASE                   = VERIFIED
CURRENT DEPLOYMENTS                = VERIFIED
ROOT CAUSE                         = PROVEN
PRODUCTION HARDENING               = DEPLOYED + VERIFIED
MOTHER FILE SURGERY                = OWNER ACTION REQUIRED
LIVE BROWSER E2E                   = OPEN
SYSTEM-LEVEL SALES TARGETS         = OPEN PENDING OWNER SURGERY + LIVE E2E
```

## 16. تعليمات للمساعد القادم — من أين يبدأ وكيف يصل إلى الحقيقة

ابدأ دائمًا بهذا الترتيب ولا تعكسه:

1. خذ `erp-frontend` HEAD الحالي وDirect Parent وParent of Parent.
2. خذ blob الحالي لـ`companies/company-1/main.html` وسجّل SHA والحجم وtimestamp.
3. ثبّت EOF من نفس blob، ولا تخترع line numbers. إذا لم يدعم transport line-addressing، استخدم anchor نصيًا واضحًا.
4. افحص Console الحالي قبل لمس أي كود.
5. حدّد أول exception في الـstack؛ لا تبدأ من آخر جزء من النظام.
6. افتح dispatcher ثم module نفسه ثم helper dependencies.
7. طابق كل helper مع تعريفه في نفس Source of Truth.
8. بالتوازي افحص Production function definitions وEdge deployment الحالي وdatabase schema.
9. افحص authorization وtenant scope قبل أي تعديل.
10. لا تعتبر تقريرًا تاريخيًا دليلًا على الحالة الحالية.
11. لا تعيد إصلاح ما ثبت أنه موجود في HEAD الحالي.
12. Production changes تُنفذ مباشرة فقط عندما يكون defect مثبتًا.
13. Mother file لا يُعدله المساعد؛ يقدم Owner surgery كاملًا ومحددًا بالـanchor.
14. بعد Owner surgery، شغّل Browser E2E فعلية: login → sales → sales targets.
15. راقب Console + Network، ثم اختبر Realtime refresh.
16. في النهاية خذ Production snapshot جديدة في نفس لحظة التقرير.
17. لا تجعل `PASS` في تقرير داخلي أو Staging مساويًا لـProduction PASS.
18. لا تغلق المهمة system-level إلا بعد إثبات:
   - التبويب يفتح.
   - لا يوجد Console exception.
   - Network يصل للـEdge الصحيحة.
   - Backend returns valid result.
   - Realtime يعمل.
   - Production snapshot مطابقة للحالة المبلغ عنها.

## 17. Source of Truth النهائي

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولا يُسمح بإعادة بناء الحالة من `Current/PWA/main2/*` أو `Original/PWA/main/*` إلا للاستشارة التاريخية فقط.
