# Report179 — SALES TARGETS PRODUCTION HARDENING + MOTHER UI FORENSIC — 2026-09-14

## 0. قاعدة البداية الحاكمة

التقارير السابقة Historical/Reference فقط. لم تُعامل كحالة Production حالية.

الحالة المعتمدة أثناء هذه الجلسة:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser/System E2E يلزم أيضًا:

`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

### نقطة حاكمة يجب تكرارها للجلسات التالية

الهدف النهائي ليس وجود شاشة أو RPC أو جدول فقط. الهدف هو إكمال **Sales Targets كدورة تشغيلية حقيقية**: إنشاء هدف متغير → تخصيصه → اعتماده → القياس من المبيعات الفعلية → الترحيل → اعتماد النتيجة → العكس عند الحاجة → إمكانية إنشاء نسخة جديدة من هدف مع الحفاظ على التاريخ وعدم تعديل الخطة المعتمدة.

## 1. CURRENT GIT — تمت المراجعة المباشرة

### erp-frontend

HEAD:
`b6e48193f4042ed6625721aa484c53f6de8cb081`

Message:
`Update manager.html`

Direct Parent:
`3398d0952ea723d1de42b076ad93ae19c025bfa3`

Parent of Parent:
`8392edda5c766fa69c5faea768ca35e35b498b94`

Current mother source blob:
`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

Current mother source size:
`1,087,515 bytes`

### rawaie-erp-New

HEAD وقت بداية الجلسة:
`b71871c02f926a551894993a34205ecdd11c5286`

Direct Parent:
`93a11b7b927a3e458dfa69cd05f3e4c2d0019067`

تمت إضافة migration canonical جديدة في هذه الجلسة:
`supabase/migrations/20260914075000_sales_targets_zero_debt_hardening.sql`

## 2. MOTHER MAIN — إثبات القراءة

تم التحقق من الـblob والحجم ومن بداية ونهاية الجسم عبر GitHub transport، وتم إجراء static search داخل الجسم الحالي.

**لكن نقل جسم ملف 1.09MB كاملًا سطرًا بسطر حتى EOF مع الحفاظ على line-addressing الأصلي لم يكن ممكنًا تقنيًا من endpoint المتاح في runtime.**

النتيجة الحاكمة:

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

ولذلك لم يتم اختراع رقم سطر أو anchor رقمي غير مثبت.

تم إثبات من المصدر الحالي أن:

- `RW_Navigation.menuTree` يحتوي إدارة المبيعات لكنه لا يحتوي `sales-targets` كـTarget view مستقل.
- البحث عن `sales_target` داخل المصدر الحالي لم يعثر على module مسجل بهذا الاسم.
- جسم المصدر النهائي ينتهي عند `</script>` ثم `</body>` و`</html>`.

هذا يعني أن طبقة Mother UI ما زالت تحتاج Owner Surgery، ولم يتم تعديلها مباشرة في هذه الجلسة.

## 3. CURRENT PRODUCTION — Sales Targets

Production project:
`fiilmooggumokxanwiyx`

الجداول الحالية المثبتة مباشرة:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

آخر snapshot مباشر:
`2026-09-14 04:49:52.424248+00`

Counts:
- plans = `0`
- assignments = `0`
- runs = `0`
- run_lines = `0`

No test residue remains.

## 4. WHAT WAS ALREADY CLOSED BEFORE THIS SESSION

هذه العناصر لم يُعاد إصلاحها بلا سبب؛ تم التعامل معها كـclosed baseline ما لم يظهر Regression:

- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`
- `sales_target_engine_gateway`
- Edge `sales-target-engine`
- Edge `sales-target-dashboard`
- POST idempotency
- Production transactional lifecycle
- Target tables in Realtime publication

## 5. ACTUAL GAP FOUND IN CURRENT PRODUCTION

رغم أن الـengine كان موجودًا، كانت علاقات Tenant داخل الجداول نفسها أضعف من العقد المطلوب.

### المشكلة

كانت العلاقات مثل:

`assignment.plan_id → plan.id`

و:

`assignment.sales_rep_id → users.id`

و:

`assignment.branch_id → branches.id`

لا تمنع وحدها أن يحمل الصف Company A مع Parent من Company B.

وكانت هناك أيضًا حاجة فعلية إلى تغيير أهداف معتمدة دون تعديل التاريخ القديم.

### القرار الصحيح

تم تطبيق:

1. Composite Tenant-safe foreign keys.
2. Version metadata للخطة.
3. `supersedes_plan_id`.
4. `CLONE_PLAN` لإنشاء نسخة Draft جديدة من خطة نهائية.
5. `SET_ASSIGNMENT_ACTIVE` مع السماح بالتعديل فقط أثناء Draft.
6. التحقق الصريح من Company ownership للـSales Rep والBranch داخل RPC.

## 6. PRODUCTION CHANGES EXECUTED

### 6.1 Tenant Integrity

تم إنشاء composite parent indexes لـ:

- users `(id, company_id)`
- branches `(id, company_id)`
- sales_target_plans `(id, company_id)`
- sales_target_assignments `(id, company_id)`
- sales_target_runs `(id, company_id)`

ثم استبدال العلاقات الضعيفة بعلاقات Company-safe على:

- assignments → plans
- assignments → users
- assignments → branches
- runs → plans
- runs → reversal run
- run_lines → assignments
- run_lines → branch
- run_lines → user
- run_lines → run

### 6.2 Versioned Target Management

أُضيف:

`version_no`

`supersedes_plan_id`

وأصبح المبدأ:

`Approved/Closed target plan = immutable history`

والتغيير التشغيلي يتم عبر:

`CLONE_PLAN → Draft → edit → approve`

وليس عبر تعديل التاريخ القديم.

### 6.3 Assignment Lifecycle

أُضيفت العملية:

`SET_ASSIGNMENT_ACTIVE`

ولكن تم تقييدها على Draft فقط حتى لا نعدل خطة معتمدة بأثر رجعي.

## 7. PRODUCTION ENGINE HARDENING

تم تحديث:

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

ليدعم:

`CLONE_PLAN`

`SET_ASSIGNMENT_ACTIVE`

ويحمي:

- Company context.
- Sales Representative ownership.
- Branch ownership.
- Draft-only assignment activation changes.
- Finalized-plan cloning.

وتم تحديث:

`public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)`

بحيث يسمح فقط بالأدوار المصرح لها بالعمليات الجديدة.

### Gateway classes الحالية

Read:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `PREVIEW`

Management:
`SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `CANCEL_PLAN`

Approval:
`APPROVE_PLAN`, `CLOSE_PLAN`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`

## 8. TESTS — SUCCESS / FAILURE

### Test A — CREATE Target

تم تنفيذ Save Plan داخل Production Transaction.

النتيجة:

`PASS`

ثم تم rollback.

### Test B — Cross-company relationship hardening

تم تثبيت العلاقات composite قبل السماح بأي target rows production.

### Test C — CLONE_PLAN

تم إنشاء خطة Approved مؤقتة ثم:

`CLONE_PLAN`

والنتيجة المثبتة:

- خطة جديدة Draft.
- `version_no = 2`.
- `supersedes_plan_id` يشير للخطة الأصلية.
- تم نسخ Assignment واحد.

ثم حدث intentional rollback sentinel.

النتيجة:

`CLONE_PLAN = PASS`

`RESIDUE = 0`

### Test D — SET_ASSIGNMENT_ACTIVE

تم اختبار محاولة التعديل على Approved plan.

النتيجة:

`REJECTED CORRECTLY`

ثم تم اختبار العملية على النسخة Draft أثناء الاختبار transaction.

النتيجة:

`PASS`

### Test E — Regression residue

آخر snapshot:

`plans=0`
`assignments=0`
`runs=0`
`run_lines=0`

وبالتالي:

`TEST RESIDUE = 0`

## 9. خطأ ظهر أثناء التنفيذ وسبب تصحيحه

ظهر أثناء اختبار النسخة الأولى من `CLONE_PLAN` خطأ:

`column reference "branch_id" is ambiguous`

السبب:

اسم متغير PL/pgSQL تعارض مع اسم عمود في `INSERT ... SELECT`.

الحل:

تم تأهيل الأعمدة بالـalias `sa` و`sa2`.

ثم أعيد الاختبار بنجاح.

هذه ليست مشكلة Business Logic؛ كانت مشكلة اسم نطاق داخل SQL وتم إغلاقها.

## 10. CURRENT DATABASE REALTIME

الجداول الأربعة ما زالت أعضاء في:

`supabase_realtime`

وهذا مثبت مباشرة من `pg_publication_tables`.

مهم:

`REALTIME DB = VERIFIED`

لكن:

`FRONTEND RUNTIME REALTIME = OPEN`

لأن الاشتراك الفعلي من Mother UI لم يتم تنفيذه بعد.

## 11. COMPETITOR PATTERN — ماذا نستلهم

Microsoft Dynamics 365 يدعم Goal hierarchy وMetrics وTargets وTime Periods وRollups ومراقبة النتائج وتأمين الوصول بحسب الأدوار. كما يسمح بأهداف stretch targets. citeturn925728search0turn925728search1

Odoo يدعم Sales Teams مع Invoicing Targets للفترة الحالية، كما أن Target-based commission plans تستخدم Targets وفترات زمنية وأهدافًا متعددة للأفراد. citeturn925728search2turn925728search5

القرار في RAWAEA ليس نسخ المنافسين حرفيًا؛ بل اعتماد ما يتفق مع طبيعة المشروع:

`Dynamic plan + scoped assignments + controlled approval + measurable actuals + immutable approved history + new version when target changes`.

## 12. CURRENT OWNER SURGERY — MOTHER MAIN

**لم يتم تعديل الملف:**

`erp-frontend/companies/company-1/main.html`

والسبب الحاكم هو عدم اختراع line numbers بدون إثبات كامل للـEOF line-addressing.

### النتيجة الحالية من المصدر

هناك Menu للمبيعات، لكن لا يوجد Target view مستقل في `RW_Navigation.menuTree`.

### Owner action required

عند توفر transport يسمح بإثبات line numbers من النسخة الحالية نفسها، ينفذ المالك ثلاث عمليات جراحية فقط:

1. إضافة View باسم `sales-targets` تحت إدارة المبيعات.
2. إضافة dispatcher route للـView.
3. إضافة module Target كامل يعتمد على Edge `sales-target-engine` و`POST` بنفس `operation_id` حتى وصول الرد، ويشترك في Realtime على:
   - `sales_target_plans`
   - `sales_target_assignments`
   - `sales_target_runs`
   - `sales_target_run_lines`
   - `orders`

لا تستخدم line number مخترعًا من تقرير سابق.

## 13. SALES MANAGER UI

الـcurrent `sales/manager.html` ما زال Owner-open حسب آخر حالة مثبتة.

عيوبه المثبتة:

- Plan selection state reset risk.
- APPROVE_RUN / REVERSE_RUN تحتاج Run ID وليس Plan ID.
- POST يخلق Operation ID جديدًا لكل click.
- Full plan/assignment management UX incomplete.
- Realtime target subscription absent.

لا يُعاد بناء backend لهذه المشاكل لأن Production backend أصبح مغلقًا إلا عند ظهور Regression جديد.

## 14. لماذا لا أعلن SYSTEM CLOSED

رغم إغلاق Production backend، لا يمكن إعلان:

`SYSTEM-LEVEL SALES TARGETS = CLOSED`

قبل:

- owner main.html surgery
- manager UI surgery
- نشر frontend
- authenticated browser E2E
- Console clean
- Network clean
- Realtime browser refresh proof
- final Production snapshot في نفس لحظة الإغلاق

## 15. FINAL SELF-AUDIT

### What I Proved

- Production target tables موجودة وسليمة.
- Production engine موجود ويعمل.
- Gateway ACL موجود ويعمل.
- Tenant-safe composite relations أصبحت جزءًا من DB contract.
- Target plan versioning أصبحت جزءًا من DB contract.
- `CLONE_PLAN` يعمل.
- assignment activation محكومة بـDraft.
- لا توجد بيانات اختبار متبقية.
- Realtime DB publication موجود.
- Current mother Source of Truth هو blob `66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`.
- current HEAD وparent تم فحصهما مباشرة.

### What I Did Not Prove

- Full 1.09MB mother body line-by-line حتى EOF عبر transport الحالي.
- Authenticated browser E2E.
- Runtime Console/Network.
- Runtime Realtime refresh من Mother.

### What I Fixed

- Tenant relational integrity.
- Version-aware target evolution.
- Finalized-plan cloning.
- Draft-only assignment activation.
- Gateway ACL for the new operations.

### What I Initially Missed

- gateway ACL had to be expanded after adding new management operations.
- clone SQL had a variable/column ambiguity caught by runtime test.

### What Could Still Be Wrong

فقط الطبقات التي لم تُثبت:

`Mother UI + Browser + Console + Network + Realtime Runtime`

ولا يوجد سبب حالي لإعادة فتح Target backend إلا إذا ظهر Regression في Production.

## 16. NEXT-ASSISTANT EXECUTION INSTRUCTIONS — يجب اتباعها حرفيًا

ابدأ دائمًا بهذا الترتيب:

`CURRENT GIT`
→ افحص HEAD
→ افحص DIRECT PARENT
→ افحص PARENT OF PARENT
→ افحص blob الحالي للـSource of Truth

ثم:

`CURRENT SOURCE`
→ احصل على الجسم الكامل إن أمكن
→ أثبت EOF
→ استخرج anchors وأرقام الأسطر من نفس النسخة

ثم:

`CURRENT PRODUCTION`
→ snapshot جديد قبل أي نسبة أو حكم

ثم:

`CURRENT DATABASE`
→ schema
→ constraints
→ functions
→ RLS
→ realtime
→ counts

ثم:

`CURRENT DEPLOYMENT EVIDENCE`
→ Edge versions
→ verify_jwt
→ deployed source hash

بعد ذلك فقط:

`CURRENT BROWSER/CONSOLE/NETWORK`

ثم:

`HISTORICAL CONTRACT`

استخدم التاريخ لفهم لماذا يوجد السلوك، وليس لإثبات أن Production ما زال بهذه الصورة.

ثم:

`ACTUAL GAP`

حدد شيئًا واحدًا فقط.

ثم:

`SURGICAL FIX`

ثم:

`TEST`

ثم:

`DEPLOY`

ثم:

`PRODUCTION VERIFY`

ثم:

`REALTIME/AUDIT`

ثم:

`FINAL SNAPSHOT`

ثم:

`CLOSE`

### قاعدة ممنوعة

لا تكرر إصلاحًا ثبت بالفعل.

لا تعلن PASS من تقرير قديم.

لا تعلن Browser PASS من Production PASS.

لا تخترع line numbers.

لا تعدل Approved Target plan مباشرة إذا كان الهدف تغييرًا مستقبليًا؛ استخدم:

`CLONE → NEW DRAFT → EDIT → APPROVE`

## 17. FINAL STATUS

`SALES TARGET DATABASE = CLOSED`

`SALES TARGET TENANT INTEGRITY = CLOSED`

`SALES TARGET VERSIONED MANAGEMENT = CLOSED`

`SALES TARGET RPC = CLOSED`

`SALES TARGET GATEWAY = CLOSED`

`SALES TARGET EDGE = CLOSED`

`SALES TARGET DB REALTIME = VERIFIED`

`SALES TARGET PRODUCTION E2E = PASS`

`SALES MANAGER UI = OPEN`

`MOTHER MAIN UI = OPEN`

`BROWSER E2E = OPEN`

`SYSTEM-LEVEL SALES TARGETS = OPEN`
