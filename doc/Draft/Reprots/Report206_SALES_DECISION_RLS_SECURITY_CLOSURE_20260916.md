# Report206 — Security Closure: Sales Decision RLS — 2026-09-16

## 0. الهدف الحاكم — اقرأ هذه النقطة بعناية

الهدف في هذه الجلسة هو **إغلاق التنبيه الأمني الحالي الخاص بالجداول الأربع `sales_decision_*` إغلاقًا حقيقيًا في Production، وليس الاكتفاء بتشخيصه أو تسجيله في تقرير**.

والقاعدة المصاحبة: ملف النظام الأم الحالي هو:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهو Source of Truth الحالي عند أي تحقق لاحق. الأجزاء التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` و`New-main` ليست Source of Truth.

هذه الوثيقة Security Closure مستقلة. لم تُستخدم لتبرير تعديل في `main.html`، ولم يُجرَ أي تعديل على ملف النظام الأم.

---

## 1. مصادر الحقيقة المستخدمة في التحقيق

تم التعامل مع التقارير كسجل تاريخي/استرشادي فقط، وليس كحالة حالية.

تمت مطابقة الحالة من:

- CURRENT Production Supabase.
- CURRENT Database metadata وPostgreSQL definitions.
- CURRENT Deployment evidence.
- CURRENT Git وCURRENT Source.
- Current Git HEAD والـdirect parent في مستودع النظام الأم.
- CURRENT_STATE.md.
- Report204 وReport205 كقرائن بحثية فقط.
- Governance document كإطار حاكم للعمل، لا كمصدر لحالة Production.

### Git الحالي للنظام الأم

Repository:
`papamohammed77-glitch/erp-frontend`

HEAD:
`befa657277fc013c4fe4d3e326ed8fc5d1040b7b`

HEAD message:
`Update HTML comment timestamp`

Direct parent:
`b6d35c5a1a362f381c9868bbc578de988b219c50`

Parent message:
`Fix button onclick syntax in main.html`

تمت إعادة قراءة commit HEAD وdirect parent. الـHEAD الحالي يغيّر timestamp فقط، بينما الـparent يحتوي إصلاح `_openPO` عند source line 9577.

### تصحيح نقطة Mother blob

الـblob الفعلي للملف الحالي في HEAD هو:

`bc268b9bb350991df64221e7f99b958264fb8d5f`

وليس `68145f77b3edc98ac37b9ec2335359d825a4be52` الذي ظهر ضمن سياق سابق. تم اعتماد ما أثبته Git الحالي على أنه الحقيقة الحالية.

### آخر Commit في مستودع RAWAEA ERP

Current latest commit في `papamohammed77-glitch/rawaie-erp-New` عند بدء هذه الدورة:

`c0a9eb79f8632014d08adebe81e56e8cf71a7645`

الرسالة:
`Create Report205`

والـparent:
`267de497322a9bb84539ca8e80f9a5bfbd03910d`

وكان هذا متسقًا مع كون Report205 آخر سجل تاريخي قبل هذه الدورة.

---

## 2. الحالة الأمنية التي وجدت في Production قبل الإصلاح

تم فحص PostgreSQL مباشرة.

الجداول الأربع الفعلية هي:

1. `public.sales_decision_approvals`
2. `public.sales_decision_evaluations`
3. `public.sales_decision_policies`
4. `public.sales_decision_policy_history`

قبل الإصلاح كانت جميعها:

```text
RLS enabled = false
Force RLS   = false
```

ولم تكن هناك أي RLS policies عليها.

تم كذلك فحص صلاحيات الجدول المباشرة، فكانت صلاحيات `SELECT` لـ`anon` و`authenticated` غير ممنوحة أصلًا.

هذه نقطة مهمة: المشكلة الأصلية كانت غياب RLS عن جداول مكشوفة ضمن schema `public`، وليس وجود قناة مباشرة مثبتة للمستخدمين من خلال table grants.

---

## 3. التحقيق الجنائي في وظيفة الجداول

تم البحث في جميع تعريفات PostgreSQL الحالية التي تشير إلى الجداول الأربع.

ظهر أن:

`public.sales_decision_engine_atomic(...)`

هو المحرك المركزي الحالي الذي يستخدم الجداول الأربع.

الوظيفة:

- `SECURITY DEFINER`.
- تتحقق من وجود Company صالح ونشط.
- تتحقق من actor داخل الشركة.
- تستخدم `sales_decision_actor_ok(...)` للتحقق من الصلاحيات.
- تقرأ policy حسب `company_id`.
- تكتب evaluation حسب `company_id + operation_id`.
- تسجل approval حسب `company_id + operation_id`.
- تكتب policy history حسب `company_id`.
- تمنع إعادة استخدام operation_id مع طلب مختلف.

تم أيضًا فحص `sales_decision_actor_ok` الحالي، واتضح أنه يقوم بالتحقق من:

`users.company_id = p_company_id`

ومقارنة البريد الإلكتروني مع المستخدم النشط والصلاحيات المناسبة.

### العلاقات الحالية

تم إثبات العلاقات الرسمية التالية:

```text
sales_decision_approvals.company_id
    → companies.id

sales_decision_approvals.evaluation_id
    → sales_decision_evaluations.id

sales_decision_evaluations.company_id
    → companies.id

sales_decision_evaluations.policy_id
    → sales_decision_policies.id

sales_decision_policies.company_id
    → companies.id

sales_decision_policy_history.company_id
    → companies.id

sales_decision_policy_history.policy_id
    → sales_decision_policies.id
```

إذن الـtenant boundary موجود داخل نموذج البيانات نفسه.

---

## 4. لماذا لم ننشئ Tables أو Edge Functions جديدة

لم يتم إنشاء أي جدول جديد.

لم يتم إنشاء أي Edge Function جديدة.

لم يتم إنشاء أي RPC جديد.

السبب مثبت وليس افتراضًا:

الـSales Decision infrastructure موجودة بالفعل في Production، والمسار الحالي يمر عبر `sales_decision_engine_atomic`.

إنشاء Gateway ثانٍ أو Edge Function ثانية لمعالجة RLS كان سيضيف business path موازيًا ويزيد احتمال الـdrift.

الحل الصحيح هو Security Closure على البيانات نفسها مع الحفاظ على الـengine الحالي.

---

## 5. التصميم الأمني المعتمد

تم اعتماد طبقتين:

### الطبقة الأولى — RLS

تم تفعيل RLS على الجداول الأربع:

```sql
ALTER TABLE public.sales_decision_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_decision_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_decision_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_decision_policy_history ENABLE ROW LEVEL SECURITY;
```

### الطبقة الثانية — عدم وجود Direct Table API

تم سحب صلاحيات الجدول من:

```text
anon
authenticated
```

بما يتفق مع التصميم الحالي الذي يعتبر `sales_decision_engine_atomic` بوابة التحكم.

### الطبقة الثالثة — Explicit Deny RLS Policies

تم إنشاء Policy واحدة Restrictive لكل جدول:

```text
TO anon, authenticated
USING (false)
WITH CHECK (false)
```

الهدف ليس السماح للمستخدمين بالوصول إلى الجداول، بل جعل المنع صريحًا حتى لو حدث منح صلاحية مباشرة مستقبلًا بالخطأ.

`service_role` لم يتم وضعه ضمن هذه policies، والـ`SECURITY DEFINER` engine الحالي استمر في العمل.

---

## 6. التغييرات التي نُفذت فعليًا في Production

### Migration 1

Name:
`20260916042958_sales_decision_rls_security_closure_20260916`

نفذت:

- ENABLE RLS للجداول الأربع.
- REVOKE ALL من `anon` و`authenticated`.

### Migration 2

Name:
`20260916043051_sales_decision_rls_explicit_deny_20260916`

نفذت:

- إنشاء Restrictive RLS deny policy لكل جدول من الجداول الأربع.

تم تسجيل الهجرتين أيضًا في migration registry الحالي في Supabase Production.

---

## 7. الاختبارات التي أُجريت

### Test A — RLS state

تمت إعادة قراءة PostgreSQL metadata بعد التنفيذ.

النتيجة لكل جدول:

```text
RLS enabled = true
Force RLS   = false
Policy count = 1
anon SELECT = false
enticated SELECT = false
```

الحالة الفعلية التي تم إثباتها:

```text
sales_decision_approvals        RLS = ON
sales_decision_evaluations      RLS = ON
sales_decision_policies         RLS = ON
sales_decision_policy_history   RLS = ON
```

### Test B — Direct-user denial through RLS

لإثبات RLS نفسه وليس مجرد عدم وجود grants، تم داخل Transaction مؤقتة:

1. منح `SELECT` مؤقتًا لـ`authenticated`.
2. `SET LOCAL ROLE authenticated`.
3. قراءة الجداول الأربع.
4. أخذ النتيجة.
5. `ROLLBACK`.

النتيجة:

```text
effective_role = authenticated
approvals_visible = 0
evaluations_visible = 0
policies_visible = 0
history_visible = 0
```

وبالتالي تم إثبات أن RLS يمنع الصفوف حتى عند وجود SELECT grant داخل اختبار معزول.

بعد الـROLLBACK لم يبقَ grant إضافي.

### Test C — Sales Decision Engine بعد Security Closure

تم استدعاء:

`sales_decision_engine_atomic`

بالعملية:

`GET_POLICY`

باستخدام مستخدم Owner حالي داخل Company 00000000-0000-0000-0000-000000000001.

النتيجة:

```text
success = true
status = Active
version_no = 1
```

وبالتالي لم يؤدِ تفعيل RLS والـdeny policies إلى كسر مسار الـSales Decision Engine.

### Test D — Security Advisor

تم تشغيل Supabase Security Advisor بعد التنفيذ.

قبل الإغلاق كان من بين findings:

```text
sales_decision_approvals  — RLS Enabled No Policy
sales_decision_evaluations — RLS Enabled No Policy
sales_decision_policies — RLS Enabled No Policy
sales_decision_policy_history — RLS Enabled No Policy
```

بعد إضافة الـexplicit deny policies اختفت الجداول الأربع من هذا الـfinding.

بقيت findings أخرى في Security Advisor تخص مكونات أخرى، ومنها Security Definer Views وSecurity Definer RPCs وAuth password protection. لم يتم خلطها بهذه الوحدة ولم نعدّها مغلقة.

---

## 8. حالة بيانات Sales Decision الحالية

تم فحص counts في Production:

```text
sales_decision_policies         = 1
sales_decision_evaluations      = 0
sales_decision_approvals        = 0
sales_decision_policy_history   = 1
```

لم يتم تعديل هذه البيانات أثناء Security Closure.

لم نحتج إلى Data Repair لأن التحقيق لم يثبت وجود data defect ضمن هذه الوحدة.

---

## 9. Triggers وAudit

تم فحص Triggers الحالية على هذه الجداول.

المثبت في Production:

```text
trg_sales_decision_approval_audit
    AFTER INSERT OR DELETE OR UPDATE
    → sales_decision_approval_audit_trigger()

trg_sales_decision_policy_audit
    AFTER INSERT OR DELETE OR UPDATE
    → sales_decision_audit_trigger()

trg_sales_decision_policy_updated_at
    BEFORE UPDATE
    → sales_decision_touch_updated_at()
```

إذن Security Closure لم تزل Audit responsibility ولم تغير مسارها.

---

## 10. لماذا Force RLS لم يتم تفعيله

هذه ليست خطوة ناقصة.

الجداول مملوكة حاليًا لـ`postgres`، والـSales Decision engine الحالي `SECURITY DEFINER` ويعتمد على هذا التنفيذ.

تفعيل `FORCE ROW LEVEL SECURITY` بدون إعادة تصميم Ownership/Policy boundary بالكامل كان سيغيّر Contract التنفيذي وقد يكسر الـengine.

في هذه الوحدة كان المطلوب إغلاق direct user access مع الحفاظ على الـcontrolled engine path، وتم تحقيق ذلك بدون إدخال مخاطرة غير لازمة.

---

## 11. العلاقة مع النظام الأم وmain.html

لم يتم تعديل:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولم يكن هناك سبب جراحي يفرض تعديل الملف لهذه المشكلة الأمنية الحالية.

هذا متعمد ومتسق مع فصل المسؤوليات:

```text
Production DB Security  → CTO execution
Mother HTML             → Owner surgical changes
```

لا توجد حاجة لإعطاء Owner replacement block لهذه الوحدة.

---

## 12. Production / Git alignment

تمت إضافة النسختين canonical إلى:

`papamohammed77-glitch/rawaie-erp-New`

المسارات:

```text
supabase/migrations/20260916042958_sales_decision_rls_security_closure_20260916.sql
supabase/migrations/20260916043051_sales_decision_rls_explicit_deny_20260916.sql
```

وهما يعكسان التغييرات الفعلية التي نُفذت في Production.

لم يتم تسجيل SQL نظري يختلف عن Production.

---

## 13. أخطاء أو تجارب فاشلة أثناء التنفيذ

لم يحدث فشل في تطبيق Security Closure نفسها.

ظهر أثناء قراءة الأدلة السابقة اختلاف في Mother blob:

```text
سجل سابق: 68145f77b3edc98ac37b9ec2335359d825a4be52
Git الحالي: bc268b9bb350991df64221e7f99b958264fb8d5f
```

تم حل التعارض بالرجوع إلى Git الحالي مباشرة، واعتماد الـblob الحالي.

كما أن Security Advisor بعد أول Migration أظهر أن RLS بلا Policy يُسجل كـINFO. لذلك تمت إضافة explicit deny policies بدل ترك الإغلاق ضمنيًا.

لم يتم تنفيذ أي اختبار يترك بيانات دائمة خلفه.

---

## 14. ما لم يتم تغييره عمدًا

لم يتم تغيير:

- Business logic الخاص بSales Decision.
- `sales_decision_engine_atomic`.
- `sales_decision_actor_ok`.
- أي Sales Invoice logic.
- أي main.html.
- أي Edge Function.
- أي Sales Decision data.
- أي tab أو UI.
- أي trigger أو audit function.
- أي policy أخرى خارج الجداول الأربع.

السبب: لا يوجد evidence يثبت أن هذه العناصر معيبة ضمن Security Closure الحالي.

---

## 15. FINAL SELF-AUDIT

### ما تم إثباته

- الجداول الأربع هي الجداول الفعلية الحالية.
- كانت بلا RLS قبل الإغلاق.
- ليس لديها direct SELECT grant لـ`anon/authenticated`.
- الجداول Tenant-scoped عبر `company_id`.
- Sales Decision Engine الحالي يستخدمها فعليًا.
- العلاقات المرجعية الحالية سليمة ضمن هذه الوحدة.
- RLS أصبح مفعّلًا على الجداول الأربع.
- Explicit deny policies أصبحت موجودة على الجداول الأربع.
- direct user reads تم منعها.
- RLS تم اختباره بتغيير role داخل Transaction مؤقتة.
- Sales Decision Engine استمر في العمل بعد التغيير.
- Security Advisor لم يعد يعرض الجداول الأربع ضمن `RLS Enabled No Policy`.
- migrations الفعلية أصبحت مسجلة في Production وموجودة canonical في Git.

### ما لم يتم إثباته

- لا يوجد Browser E2E جديد في هذه الجلسة لـ`main.html`، لأن Security Closure الحالية Database Security مستقلة عن Owner HTML changes.
- لم يتم إثبات أن كل Security Advisor findings الأخرى مغلقة؛ هي خارج Closure هذه.
- لم يتم إعلان Gold/Diamond للنظام الأم كله؛ تم إغلاق هذه الوحدة الأمنية فقط.

### حالة هذه الوحدة

```text
SECURITY CLOSURE
= FULLY CLOSED
```

بالنسبة للنطاق المحدد فقط:

```text
Sales Decision four-table RLS closure = CLOSED
```

---

# 16. إرشادات تنفيذية للمساعد/CTO القادم — اقرأها قبل البدء

لا تبدأ من الصفر.

ابدأ بالتسلسل التالي حرفيًا:

```text
1. READ CURRENT_STATE.md
2. DO NOT TRUST IT BLINDLY
3. READ CURRENT GIT HEAD
4. READ DIRECT PARENT
5. READ CURRENT SOURCE
6. READ DEPLOYED PRODUCTION DEFINITIONS
7. READ CURRENT DATABASE METADATA
8. READ CURRENT EDGE DEPLOYMENTS
9. READ CURRENT RUNTIME / LOG EVIDENCE
10. RECHECK THE EXACT OPEN CLOSURE UNIT
11. USE REPORTS ONLY AS SEARCH POINTERS
12. IDENTIFY THE PRIMARY SOURCE OF TRUTH
13. IDENTIFY THE EXACT DEFECT
14. IDENTIFY THE ROOT CAUSE BEFORE PATCHING
15. PRESERVE HISTORICAL BUSINESS CONTRACTS UNLESS CURRENT EVIDENCE PROVES THEY MUST CHANGE
16. CHANGE ONE CLOSURE UNIT AT A TIME
17. APPLY THE SMALLEST SAFE ARCHITECTURAL FIX
18. DO NOT CREATE DUPLICATE TABLES / RPCS / EDGES IF CURRENT INFRASTRUCTURE ALREADY EXISTS
19. RE-READ PRODUCTION DEFINITIONS AFTER EVERY DEPLOYMENT
20. TEST SUCCESS PATH
21. TEST FAILURE PATH
22. TEST RETRY / IDEMPOTENCY WHEN RELEVANT
23. TEST AUTHORIZATION
24. TEST TENANT ISOLATION
25. TEST DATA CONSISTENCY
26. TEST AUDIT PATH
27. TEST RUNTIME
28. REFRESH PRODUCTION SNAPSHOT IN THE SAME TIME WINDOW AS THE REPORT
29. UPDATE CANONICAL GIT
30. UPDATE CURRENT_STATE.md
31. WRITE THE EXECUTION REPORT
32. ONLY THEN MARK THE CLOSURE UNIT CLOSED
```

### لا تقع في الأخطاء السابقة

```text
REPORT ≠ CURRENT STATE
COMMIT ≠ DEPLOYMENT
DEPLOYMENT ≠ RUNTIME SUCCESS
RUNTIME SUCCESS ≠ FULL CLOSURE
RLS ENABLED ≠ APPROPRIATE ACCESS MODEL
TABLE EXISTS ≠ CAPABILITY COMPLETE
EDGE EXISTS ≠ CONSUMER COMPLETE
```

إذا ظهر Unknown:

```text
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ CURRENT RUNTIME
→ HISTORY
→ ORIGINAL
→ CONSUMERS
→ CALLEES
→ CALLERS
→ AUDIT
→ DATA
```

ثم نفّذ الإصلاح، ولا تحول Unknown إلى Blocker إذا كان هناك مسار داخلي آمن للوصول إلى الحقيقة.

### القاعدة النهائية

```text
DO NOT PATCH WHAT YOU HAVE NOT UNDERSTOOD
DO NOT REPORT WHAT YOU HAVE NOT VERIFIED
DO NOT CLOSE WHAT YOU HAVE NOT TESTED
DO NOT REPEAT WHAT CURRENT EVIDENCE PROVES IS ALREADY CLOSED
DO NOT CREATE NEW DEBT TO REMOVE OLD DEBT
```

والمرجع النهائي لأي جلسة لاحقة هو:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
+
CURRENT RUNTIME EVIDENCE
```
