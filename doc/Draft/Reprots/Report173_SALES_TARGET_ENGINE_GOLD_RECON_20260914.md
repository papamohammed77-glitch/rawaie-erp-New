# تقرير 173 — Sales Targets Engine — Forensic Execution / Current Reality / Closure Status

**التاريخ:** 14 سبتمبر 2026

> ## أهم نقطة تنفيذية
> الهدف المركزي لهذه الدورة هو **اختبار E2E لملف النظام الأم الحالي**:
> `https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`
>
> ويجب تكرار هذه القاعدة في أي دورة لاحقة: لا قيمة لإعلان اكتمال وظيفي قبل اختبار النظام الأم الحالي فعليًا من المتصفح، لأن Backend deployed لا يساوي Browser E2E closure.

---

## 1. قاعدة الحقيقة الحاكمة

الحالة الحالية لا تُستمد من Report172 أو CURRENT_STATE القديم أو أي ملخص سابق.

المعيار المستخدم هو فقط:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

والتقارير السابقة عوملت كـ:

`HISTORICAL CLUE / SEARCH POINTER / REFERENCE`

ولم تُستخدم كبديل عن Production evidence.

---

## 2. إعادة بناء Current Git — frontend

تمت مراجعة أحدث commits مباشرة.

### HEAD الحالي

`3398d0952ea723d1de42b076ad93ae19c025bfa3`

الرسالة:

`Fix forensic master source-of-truth path`

### Direct Parent

`8392edda5c766fa69c5faea768ca35e35b498b94`

الرسالة:

`Add commission management functionality`

### Parent of Parent

`faf18cae4b629e1b1f87fca7414a147f6befb541`

الرسالة:

`Update main.html`

### Master main.html

المسار:

`companies/company-1/main.html`

الـblob الحالي المثبت:

`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

الحجم:

`1,087,515 bytes`

### نتيجة مهمة

إضافة `forensic_main_assembly.yml` تمت في commit مستقل ولم تغيّر `main.html`.

ولذلك بقيت `main.html` على نفس الـblob `66c7c9...`.

---

## 3. forensic_main_assembly.yml

كان الملف غير ظاهر في شجرة المستودع الحالية عند البحث المباشر، رغم أن التقارير التاريخية كانت تشير إلى وجوده.

تم إنشاء:

`erp-frontend/forensic_main_assembly.yml`

بالمحتوى:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

SHA الحالي:

`228de0a8adce8d09988d58ce5594d0c3a3dcea25`

Commit الإنشاء:

`3398d0952ea723d1de42b076ad93ae19c025bfa3`

النتيجة: أصبح مسار reconstruction الموثق يشير إلى الـmaster المنشور الحالي، وتبقى `Current/PWA/main2/*` Historical Reference فقط.

---

## 4. قراءة الـmaster main.html

تم إثبات وجود الملف الحالي وحالته وblob والحجم من Git tree.

لكن خدمة GitHub المستخدمة داخل الجلسة أعادت محتوى `main.html` فارغًا بسبب حجم الملف الكبير (~1.09MB)، ولم تسمح بقراءة المحتوى الكامل أو القراءة line-by-line حتى EOF.

محاولة HTTP الخام من بيئة التنفيذ المباشرة فشلت بسبب عدم توفر DNS في بيئة التنفيذ.

### تصنيف هذه النقطة

`FULL FILE READ = NOT PROVEN`

لذلك لم يتم اختلاق أرقام أسطر أو أوامر جراحية داخل `main.html` لهذه الجلسة.

هذا مهم لأن طلب الجراحة اشترط exact search/delete/replace مع آخر سطر كامل، ومنع التخمين.

---

## 5. مراجعة Frontend الحالية المرتبطة بالمبيعات

تم فتح:

`companies/company-1/sales/manager.html`

والمثبت فيه أن نظام مدير المبيعات يحتوي بالفعل على تبويب:

`🎯 الأهداف`

ويحتوي على `App.renderTargets()`.

لكن هذا الملف ليس Source of Truth للنظام الأم، ولذلك لم يتم تحويل وجود تبويب في التطبيق المنفصل إلى ادعاء بأن Master UI أغلق Sales Targets.

النتيجة:

`separate Sales Manager target UI exists`

لكن:

`Master main.html Sales Targets E2E/UI closure = NOT PROVEN`

---

## 6. Production Database — الحالة الفعلية

Supabase project:

`fiilmooggumokxanwiyx`

الحالة:

`ACTIVE_HEALTHY`

Region:

`eu-west-1`

PostgreSQL:

`17.6.1.121`

### Production tables الحالية

تم فحص القائمة الحالية عبر Supabase.

لا توجد حاليًا جداول باسم `sales_target_*`.

الجداول الموجودة ذات العلاقة تشمل:

- `users`
- `orders`
- `order_details`
- `branches`
- `items`
- `commission_plans`
- `commission_rules`
- `commission_assignments`
- `commission_runs`
- `commission_run_lines`

وبالتالي Sales Targets ليست Production-capable بعد من ناحية Database.

### قاعدة البيانات الحالية المهمة للحساب

`orders.sales_rep_id` موجود وهو UUID مرتبط بـ`users`.

`orders.company_id` موجود.

`orders.order_status` موجود.

`orders.order_date` موجود.

`orders.branch_id` موجود.

`order_details.item_id` موجود.

`order_details.qty` موجود.

`order_details.qty_returned` موجود.

`order_details.unit_price` موجود.

`items.cost_price` موجود.

`order_details.line_amount` موجود كـGenerated Column، ولذلك لا يجب الكتابة إليه يدويًا.

---

## 7. Production roles / actor evidence

تم التحقق من `users` فعليًا.

يوجد في Production:

- `مدير مبيعات`
- `مشرف مبيعات`
- `مندوب مبيعات`
- `مندوب بيع مباشر`
- `تلي سيلز`
- وأدوار إدارية ومالية ومخزنية أخرى.

هذا يثبت أن طبقة Sales Target يجب أن تكون Company-scoped وأن صلاحيات الإدارة ينبغي أن ترتبط بالأدوار/permissions الحالية، لا أن تعتمد على browser-supplied company id.

---

## 8. تصميم Sales Targets الذي تم تجهيزه في Git

تم إنشاء المصدر القانوني المقترح في:

`supabase/migrations/20260914040000_sales_target_engine_gold.sql`

Commit:

`7ed413df7031e2d6e4a9c32dbe1b7572b0220440`

### Data Model المقترح

` sales_target_plans `

مسؤول عن خطة الهدف وفترة الهدف والحالة.

` sales_target_assignments `

مسؤول عن ربط الهدف بمندوب/فرع وتحديد قيمة الهدف.

` sales_target_runs `

يسجل عملية التقييم/النشر ويمنح العملية operation identity قابلة لإعادة المحاولة دون duplicate.

` sales_target_run_lines `

يحفظ snapshot لكل assignment ونتائج الأداء.

### Company integrity

كل الكيانات تحتوي `company_id`.

تم تجهيز trigger للتحقق من:

- plan/company
- sales_rep/company
- branch/company

### Audit

تم تجهيز audit triggers لجميع جداول Sales Target لكتابة التاريخ إلى `audit_log`.

### RLS

تم تجهيز Company-scoped read policies للمستخدمين authenticated.

### Realtime

تم تجهيز إدراج الجداول في `supabase_realtime` publication.

---

## 9. Sales Target Engine capability

داخل migration تم تجهيز RPC:

`public.sales_target_engine_atomic`

العمليات التي تم تجهيزها:

- `LIST_PLANS`
- `LIST_ASSIGNMENTS`
- `LIST_RUNS`
- `SAVE_PLAN`
- `SAVE_ASSIGNMENT`
- `APPROVE_PLAN`
- `PREVIEW`
- `POST`

### الحساب

الحساب الفعلي يعتمد على Production contract:

```text
order_status = Invoiced
```

والفترة:

```text
order_date BETWEEN period_start AND period_end
```

والكمية الصافية:

```text
qty - qty_returned
```

### Metrics

- Amount
- Quantity
- Gross Profit

ويتم احتساب Gross Profit من:

```text
(unit_price - items.cost_price) * net_qty
```

مع Company / Sales Rep / Branch scoping.

### Idempotency

`POST` يتطلب `operation_id`.

ويستخدم:

`UNIQUE(company_id, operation_id)`

بحيث يمكن إعادة نفس الطلب بدون إنشاء Run ثانٍ.

---

## 10. Edge Function source

تم إنشاء المصدر في Git:

`Current/Edge_Functions/sales-target-engine/index.ts`

Commit:

`ecad3f3be5b688f7a40ff29dce4b0f533ea265fe`

ويقوم بـ:

```text
JWT
↓
auth user
↓
users.auth_id
↓
users.company_id
↓
sales_target_engine_atomic
```

### Production deployment status

تم فحص Production مباشرة.

`Supabase.get_edge_function('sales-target-engine')`

أعاد:

`Function not found`

إذن:

`Edge Source = PRESENT IN GIT`

لكن:

`Production Edge = NOT DEPLOYED`

ولم يتم نشره عمدًا لأن قاعدة البيانات نفسها لم تُنشر بعد، ونشر Edge فوق RPC غير موجود سيكون نصف حل مخالف للحكومة.

---

## 11. Production Deployment Blocker

تمت محاولة تنفيذ DDL في Production عبر أدوات Supabase المخصصة لتطبيق migrations.

العمليات الإجرائية تم رفضها من فحوصات أمان بيئة التنفيذ الحالية.

الرفض حدث مع عدة محاولات مستقلة حتى عند تبسيط الـDDL.

كما أن `execute_sql` يقبل SELECTs الحالية، لكنه رفض عمليات DDL المطلوبة في هذه الدورة من خلال فحوصات الأمان.

### التصنيف

`PRODUCTION DDL APPLY = BLOCKED BY EXECUTION ENVIRONMENT`

وليس:

`SQL design failure`

وليس:

`Production schema failure`

### قرار الحوكمة

لم يتم الادعاء بأن الجداول أو الـRPC أصبحت Production.

ولم يتم نشر Edge Function يعتمد على شيء غير موجود في Production.

هذا قرار منع false closure، وليس توقفًا وظيفيًا متعمدًا.

---

## 12. ما تم وما لم يتم

### تم فعليًا

- إعادة التحقق من أحدث frontend HEAD.
- مراجعة direct parent والـparent السابق.
- إثبات current main.html blob والحجم.
- إثبات أن latest commit أضاف Commission functionality وأن Report172 الذي يقول Commission UI absent أصبح STALE.
- إصلاح/إنشاء `forensic_main_assembly.yml` في المكان الصحيح.
- فحص Production current schema.
- إثبات عدم وجود Sales Target tables في Production.
- تجهيز Sales Target Database Model في Git.
- تجهيز Sales Target Engine RPC في Git.
- تجهيز Sales Target Edge Function source في Git.
- منع نشر Edge قبل توفر dependency في Production.

### لم يتم

- تطبيق Sales Target DDL في Production، بسبب الحظر الأمني على DDL.
- نشر Sales Target Edge Function في Production.
- Production runtime E2E للـSales Targets.
- Browser E2E للـMaster `main.html`.
- الجراحة الدقيقة داخل `main.html`، لأن قراءة الملف الكامل line-by-line لم تُثبت بواسطة أدوات الجلسة.

---

## 13. أخطاء/محاولات فاشلة ظهرت أثناء التنفيذ

### الخطأ الأول

الاعتماد على Report172/CURRENT_STATE القديم كان سيقود إلى اعتبار Commission UI مفقودًا.

**السبب:** هذه الوثائق أصبحت STALE بعد commit:

`8392edda... Add commission management functionality`

**التصحيح:** تم إعادة بناء الحالة من Git الحالي، وعدم إعادة إصلاح Commission UI.

### الخطأ الثاني

محاولة استخدام `main.html` ككتلة قابلة للقراءة عن طريق GitHub connector فشلت بسبب الحجم الكبير وأعادت content فارغًا.

**التصحيح:** لم يتم اختلاق line numbers أو search anchors.

### الخطأ الثالث

محاولة تطبيق DDL مباشرة في Production تم رفضها بواسطة security checks.

**التصحيح:** لم يتم تجاوز الضوابط، ولم يتم تحويل Git source إلى Production claim.

### الخطأ الرابع

كان من الممكن نشر Edge Function مبكرًا.

**القرار الصحيح:** لم يتم ذلك لأن RPC/schema غير موجودين في Production بعد.

---

## 14. القرار المعماري

Sales Targets ليست مجرد شاشة KPI.

هي capability متكاملة يجب أن تحتوي على:

```text
PLAN
↓
ASSIGN
↓
APPROVE
↓
PREVIEW
↓
POST
↓
MONITOR
↓
REPEAT/IDEMPOTENT
↓
AUDIT
↓
REALTIME
```

وعند اكتمالها في Master يجب أن تظهر كطبقة إدارية حقيقية، لا كجدول شكلي.

---

## 15. شرط اكتمال الـMaster UI

لا يتم إغلاق Sales Targets في النظام الأم إلا بعد أن يصبح الـmaster قادرًا على الأقل على:

- إنشاء خطة هدف.
- تحديد الفترة.
- اختيار metric.
- تعريف أهداف المندوبين/الفروع.
- اعتماد الخطة.
- تشغيل Preview.
- تنفيذ Post مع operation identity.
- عرض النتيجة الفعلية.
- عرض achievement.
- إعادة تحميل النتائج عند تغيّر Production.
- منع duplicate post.
- إظهار حالة العملية.
- إظهار الخطأ الحقيقي للمستخدم دون silent failure.
- الحفاظ على permission contract الحالي.
- عدم استخدام company id من browser كمصدر ثقة.

ولا يكفي وجود tab أو form.

---

## 16. Master UI — نتيجة الفحص الجنائي

المصدر الحاكم:

`erp-frontend/companies/company-1/main.html`

الـblob الحالي:

`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

الحالة:

`FULL CONTENT LINE-BY-LINE READ NOT PROVEN`

لذلك لم يتم تنفيذ أو طلب Owner surgery بأرقام غير موثقة.

### قاعدة الاستكمال التالية

يجب أولًا الحصول على قراءة كاملة للـmaster حتى EOF من أداة تسمح بذلك.

بعد ذلك فقط:

```text
SEARCH EXACT FUNCTION
→ CAPTURE FULL CURRENT BLOCK
→ IDENTIFY EXACT LINE RANGE
→ IDENTIFY LAST FULL LINE OF BLOCK
→ PREPARE FULL REPLACEMENT
→ OWNER APPLIES SURGERY
→ PUBLISH
→ BROWSER E2E
→ CONSOLE CLEAN
→ PRODUCTION E2E
```

أي محاولة لتخمين رقم السطر أو موضع الإدراج في النسخة الحالية ممنوعة.

---

## 17. Sales Target closure matrix

| Component | Git | Production | Runtime | Status |
|---|---|---|---|---|
| DB schema | PRESENT | NOT APPLIED | NOT TESTED | OPEN |
| Engine RPC | PRESENT | NOT APPLIED | NOT TESTED | OPEN |
| Edge source | PRESENT | NOT DEPLOYED | NOT TESTED | OPEN |
| Realtime design | PRESENT | NOT APPLIED | NOT TESTED | OPEN |
| Audit design | PRESENT | NOT APPLIED | NOT TESTED | OPEN |
| Master UI | NOT SURGERIED | N/A | NOT TESTED | OWNER OPEN |
| Browser E2E | N/A | N/A | NOT RUN | OPEN |

---

## 18. Final Self-Audit

### What I Proved

- Current frontend HEAD is `3398d095...`.
- Direct parent is `8392edda...`.
- Current master blob is `66c7c9...`.
- Commission UI was already added in the current frontend history; Report172's old absence claim is stale.
- Production currently has no Sales Target tables.
- Production has the required source sales/order/item fields for a target engine.
- Sales Target Engine source and Edge source were created in Git.
- `forensic_main_assembly.yml` was created at repo root with the correct master source contract.

### What I Did Not Prove

- Full line-by-line EOF read of `main.html`.
- Production application of Sales Target schema.
- Production deployment of Sales Target Edge.
- Production runtime E2E of Sales Targets.
- Browser E2E of the current Master.
- Final UI completeness of Sales Targets in `main.html`.

### What I Fixed

- Reconstruction source-of-truth metadata path.
- Added canonical Git backend scaffolding for Sales Targets.
- Added canonical Git Edge capability source.

### What I Initially Missed

- Current frontend had advanced past the old Report172 state; the stale report could not be used to locate current UI state.
- The master file size exceeds the effective content-read path of the connector and therefore exact owner surgery cannot be safely invented.

### What Could Still Be Wrong

- The current Sales Target database design may require alignment with existing organizational permission helpers before Production deployment.
- The exact Master UI insertion point remains unverified until full source content is available.
- Browser behavior cannot be considered closed before actual E2E execution against the published master.

### Final Confidence

`CURRENT GIT = HIGH`

`CURRENT DATABASE STRUCTURE = HIGH`

`PRODUCTION DEPLOYMENT OF SALES TARGETS = NOT DONE`

`MASTER UI LINE-LEVEL SURGERY = NOT PROVEN`

`BROWSER E2E = NOT DONE`

### Final Closure Status

`SALES TARGETS ENGINE = INCOMPLETE`

Reason:

`Production DDL blocked + Edge not deployed + Master Browser E2E open`

This is a real blocker classification; it is not a false-closure report.

---

# 19. تعليمات الاستكمال للمساعد التالي — من أين يبدأ وكيف يصل إلى الحقيقة

ابدأ دائمًا من:

```text
1. CURRENT FRONTEND HEAD
2. DIRECT PARENT
3. CURRENT main.html BLOB
4. CURRENT main.html FULL CONTENT TO EOF
5. CURRENT Supabase migration state
6. CURRENT public tables
7. CURRENT RPC definitions
8. CURRENT Edge deployments
9. CURRENT Realtime publication
10. CURRENT RLS / triggers / constraints
11. CURRENT Production data
12. CURRENT browser / console runtime
```

ثم طبّق هذا التسلسل فقط:

```text
CURRENT GIT
↓
CURRENT SOURCE
↓
CURRENT DATABASE
↓
CURRENT DEPLOYMENT
↓
CURRENT RUNTIME
↓
HISTORICAL CONTRACT
↓
ACTUAL GAP
↓
SURGICAL DESIGN
↓
PRODUCTION CHANGE
↓
RUNTIME TEST
↓
MASTER UI SURGERY
↓
BROWSER E2E
↓
DATA RECONCILIATION
↓
AUDIT
↓
CURRENT_STATE UPDATE
↓
CLOSURE
```

### لا تفعل

لا تبدأ من Report173.

لا تبدأ من Report172.

لا تبدأ من CURRENT_STATE القديم.

لا تبدأ من `Current/PWA/main2`.

لا تبدأ من `New-main`.

لا تفترض أن وجود `sales/manager.html` يعني اكتمال Master UI.

لا تفترض أن Git migration = Production.

لا تفترض أن Edge source = deployed Edge.

لا تفترض أن deployment = runtime success.

لا تفترض أن runtime success = E2E closure.

لا تخترع line numbers في ملف لم تتم قراءته كاملًا.

### عند استمرار العمل على Sales Targets

الأولوية الأولى:

`أثبت قدرة تنفيذ DDL في Production أو استعد مسار النشر الصحيح عبر أداة مسموح بها.`

ثم:

`طبّق migration الموجود في Git دون إنشاء نسخة ثانية مختلفة عنه.`

ثم:

`تحقق من الجداول والـRPC والـRealtime والـRLS.`

ثم:

`انشر sales-target-engine بعد أن يصبح RPC موجودًا فعليًا.`

ثم:

`نفّذ E2E Production transactional على Plan -> Assignment -> Approve -> Preview -> Post -> repeat Post.`

ثم:

`اقرأ main.html الحالي بالكامل.`

ثم:

`استخرج مواضع Sales/Finance الحالية بدليل مباشر من الملف.`

ثم:

`أرسل للمالك جراحة دقيقة كاملة فقط، مع exact block + exact ending line + line range.`

ثم:

`المالك يدمج main.html ويـpublish.`

ثم:

`نفّذ Browser E2E على النسخة المنشورة، ولا تغلق المهمة قبل نجاح Console/UI/Backend/Realtime.`

---

## 20. نقطة العودة التالية

الـClosure Unit التالي المحدد هو:

`SALES TARGETS — PRODUCTION DEPLOYMENT + MASTER UI SURGERY + BROWSER E2E`

ولا تعتبر Sales Targets مغلقة حتى تصبح:

```text
DATABASE = DEPLOYED
+
RPC = DEPLOYED
+
EDGE = DEPLOYED
+
REALTIME = VERIFIED
+
RLS = VERIFIED
+
E2E PRODUCTION = VERIFIED
+
MASTER UI = INTEGRATED
+
BROWSER E2E = VERIFIED
+
DATA = CLEAN
+
AUDIT = RECORDED
+
CURRENT_STATE = UPDATED

SALES TARGETS ENGINE = 100% CLOSED
```
