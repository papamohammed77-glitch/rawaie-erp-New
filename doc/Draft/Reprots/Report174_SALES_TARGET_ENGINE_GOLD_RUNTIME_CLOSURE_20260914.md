# تقرير 174 — Sales Targets Engine — Gold Runtime Closure / Current Reality

**التاريخ:** 14 سبتمبر 2026

## 0) النقطة الأهم — يجب قراءتها قبل أي خطوة لاحقة

الهدف المركزي في هذه الدورة هو **اختبار E2E لملف النظام الأم الحالي**:

`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

هذا الملف هو **Source of Truth الوحيد للنظام الأم**. لا يجوز اعتبار أي ملف من `Current/PWA/main2/*` أو `Original/PWA/main/*` أو أي نسخة تاريخية مصدرًا حاليًا للحالة. هذه الملفات تُستخدم فقط كمرجع تاريخي عند الحاجة لإعادة بناء Contract قديم.

والقاعدة المكررة هنا: **وجود Backend أو Edge أو Database صحي لا يساوي Browser E2E closure للنظام الأم الحالي.**

---

## 1) قاعدة الحقيقة

تم التعامل مع جميع التقارير السابقة باعتبارها:

`HISTORICAL CLUE / SEARCH POINTER / REFERENCE`

وليس باعتبارها Production State.

الحالة الحاكمة التي بُني عليها التنفيذ هي فقط:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

المبدأ الحاكم للتعديلات يفرض فهم التاريخ والعقد والسلوك الحالي قبل التعديل، ثم تحديد الفجوة، ثم تنفيذ التعديل الجراحي، ثم التحقق من النتيجة. fileciteturn1246file0L2-L5

والـExecution Directive يفرض Closure Unit واحدة في كل مرة، مع اختبار ونشر والتحقق Production قبل الانتقال للوحدة التالية. fileciteturn1247file0L2-L5

---

## 2) مراجعة Git الحالية وParent Commit

### Frontend

Repository:
`papamohammed77-glitch/erp-frontend`

HEAD الحالي المثبت:
`3398d0952ea723d1de42b076ad93ae19c025bfa3`

الرسالة:
`Fix forensic master source-of-truth path`

Direct Parent:
`8392edda5c766fa69c5faea768ca35e35b498b94`

الرسالة:
`Add commission management functionality`

Parent of Parent:
`faf18cae4b629e1b1f87fca7414a147f6befb541`

الـmaster الحالي:
`companies/company-1/main.html`

Current blob:
`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

تم تأكيد أن Commit `8392edda...` أضاف Commission functionality؛ لذلك لا يجوز إعادة فتح أو إعادة بناء Commission القديمة لمجرد أن Report أقدم ذكر أنها ناقصة.

### إعادة بناء Git في backend repository

أحدث Commits الحالية في `rawaie-erp-New` أثبتت أن Sales Targets كانت مضافة في Git قبل هذه الدورة:

- `7ed413df...` — Add Sales Target Engine Gold backend
- `ecad3f3...` — Add Sales Target Engine Edge capability
- `d9c9ef24...` — Add Report173 Sales Targets forensic execution record
- `f65da051...` — Reconcile current state after Sales Targets forensic execution

هذه السلسلة أكدت الـparent chain ولم يُعاد بناء ما هو موجود أصلًا.

---

## 3) Forensic Source-of-Truth

`erp-frontend/forensic_main_assembly.yml` حاليًا:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

وهذا هو المسار الصحيح للحقيقة الحالية. fileciteturn1360file0L2-L6

---

## 4) قراءة النظام الأم الحالي — النتيجة الصريحة

تم إثبات وجود الملف الحالي وحجمه وBlob SHA، لكن أداة Git المتاحة في هذه البيئة تُرجع `content: ""` لهذا الملف الذي يتجاوز 1MB، كما أن محاولة الوصول إلى Raw مباشرة من بيئة التنفيذ لم توفر محتوى قابلًا للقراءة.

بالتالي:

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

وهذا يعني أنني **لم أخترع أرقام أسطر أو Anchors ولم أطلب Owner Surgery غير مثبتة**.

هذه ليست موافقة على إبقاء النقص؛ بل هي نقطة Integrity تمنع إدخال كود غير معروف موضعه في ملف يبلغ حجمه أكثر من مليون بايت.

---

## 5) الفرق الحاسم بين Master UI وSales Manager UI

تم فحص `companies/company-1/sales/manager.html` لتحديد هل هناك UI موجود بالفعل يمكن اعتباره مرجعًا.

النتيجة:

- يوجد تبويب `🎯 الأهداف` في مدير المبيعات.
- الدالة الحالية `renderTargets()` تحسب هدفًا ثابتًا قدره `50000` لكل مندوب.
- الحساب مبني على `orders.created_by` و`total_amount`.

هذا **ليس** Sales Targets Engine Gold، ولا يجوز نقله أو اعتباره Source of Truth للنظام الأم.

العقد الصحيح الآن هو RPC/Edge المركزي المبني في Production.

---

## 6) Production — Sales Targets Infrastructure

تم إنشاء البنية التحتية المطلوبة مباشرة في Production Supabase project:

`fiilmooggumokxanwiyx`

الجداول:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

وتوجد العلاقات الأساسية مع:

- `companies`
- `users`
- `branches`
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`

مع مفاتيح Primary/Foreign وUnique المطلوبة.

---

## 7) Production — Engine RPC

الدالة الحالية:

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

وهي `SECURITY DEFINER` مع:

- Company isolation.
- Permission tiers.
- Plan lifecycle.
- Assignment lifecycle.
- Preview.
- Post.
- Post idempotency.
- Run approval.
- Run reversal.
- Actuals من `orders` + `order_details`.
- Net quantities عبر `qty - qty_returned`.

### Permission contract

تم استخدام permission semantics الموجودة فعليًا في المشروع، وبالأخص wildcard:

`["*"]`

مع صلاحيات Sales Manager / Sales Supervisor / General Manager، بدل اختراع role semantics جديدة.

هذا يحافظ على فكرة OWNER التاريخية التي لا يجوز استبدالها بمجرد قائمة صريحة جديدة. fileciteturn1246file0L2-L5

---

## 8) Production — RLS / Realtime / Audit / Performance

تم تنفيذ:

- RLS على الجداول الأربعة.
- قراءة Company-scoped للمستخدمين المصادق عليهم.
- Realtime publication للجداول الأربعة.
- Audit triggers للجداول الأربعة.
- منع تنفيذ trigger helper functions من `anon` و`authenticated`.
- إضافة indexes صريحة على Foreign Keys الخاصة بالـSales Target model.
- تحسين سياسات RLS لاستخدام `(select auth.uid())` بدل إعادة تقييم Auth expression صفًا بصف.

الـSupabase security advisor الحالي لم يعد يعرض `sales_target_assignment_guard` أو `sales_target_audit_trigger` ضمن تحذيرات public/authenticated execution؛ التحذيرات المتبقية تخص وظائف وكيانات أخرى خارج هذه Closure Unit.

---

## 9) Production — Edge Function

تم إنشاء ونشر:

`sales-target-engine`

الحالة:
`ACTIVE`

`verify_jwt = true`

والـEdge يعمل كـthin capability wrapper:

`JWT → users.auth_id → company_id → sales_target_engine_atomic`

وهذا يمنع وصول Browser إلى `company_id` كمصدر ثقة.

النسخة الحالية في Production:
`v1`

المصدر الحالي في Git:
`Current/Edge_Functions/sales-target-engine/index.ts`

Blob الحالي للمصدر:
`d10b57448bc850386523f22600561d1ea4b2316b`

المصدر المنشور في Edge مطابق لهذه البنية. fileciteturn1385file0L2-L6

---

## 10) الاختبارات الفعلية التي تم تنفيذها

### E2E Database Transactional Test

تم تنفيذ اختبار داخل Transaction ثم `ROLLBACK`، وبالتالي لم يتم تلويث Production بالبيانات التجريبية.

التسلسل:

`SAVE_PLAN`
→ `SAVE_ASSIGNMENT`
→ `APPROVE_PLAN`
→ `PREVIEW`
→ `POST`
→ `POST_RETRY`
→ `APPROVE_RUN`
→ `REVERSE_RUN`

النتيجة:

- `SAVE_PLAN` = PASS
- `SAVE_ASSIGNMENT` = PASS
- `APPROVE_PLAN` = PASS
- `PREVIEW` = PASS
- `POST` = PASS
- `POST_RETRY` = PASS with `duplicate=true`
- `APPROVE_RUN` = PASS
- `REVERSE_RUN` = PASS
- Full transaction = ROLLBACK

وبالتالي أثبتنا دورة Engine الأساسية كاملة داخل Production database دون إبقاء Test records.

### Production persistent sanity

آخر فحص Production:

- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`

وهذا متوقع لأن اختبارات E2E كانت Transactional وتم عمل Rollback لها.

---

## 11) أخطاء حدثت وتم إصلاحها

### الخطأ الأول — Audit trigger row-shape bug

في أول E2E run ظهر خطأ حقيقي:

`record "new" has no field "approved_by"`

السبب:
الـtrigger كان يحاول الوصول مباشرة إلى حقول ليست موجودة في جميع جداول Sales Target.

الإصلاح:
تحويل `NEW/OLD` إلى JSONB واستخراج المفاتيح اختياريًا، مع fallback إلى `system`.

هذا الإصلاح طُبق في Production، ثم أُعيد الاختبار بالكامل.

### الخطأ الثاني — Idempotency/remaining-quantity sequencing

ظهر أن retry بعد استلام/تشغيل العملية يمكن أن يصل إلى validation بعد تغيّر الحالة بدل أن يُحسم أولًا من خلال Operation Identity.

تم رفض حل ترقيعي مبني على fingerprint يخفي هذه المشكلة، وتم الحفاظ في Sales Targets على العقد الصحيح: `operation_id` صريح + Unique per company.

### الخطأ الثالث — Git/Production drift

الـProduction أصبح أحدث من migration/source الأصلي عندما أُضيف hardening.

تم إنشاء migration files مقابلة في Git، وأصبح hardening والتشدد الأمني وindexes وRLS optimizations جزءًا من المصدر القانوني للمشروع، لا تعديلًا Production-only.

---

## 12) ما تم تحديثه في Git

تم إنشاء:

`supabase/migrations/20260914_sales_target_engine_hardening.sql`

Commit:
`84aefa26b86eca43b9e14d348eaa55748d7cf490`

وتم إنشاء:

`supabase/migrations/20260914_sales_target_audit_trigger_fix.sql`

Commit:
`b4d4f8726caef468fcf479e06163f28c7846a141`

هذه الملفات ليست مجرد Documentation؛ هي canonical reconstruction للمفاتيح التي أصبح Production يعمل بها.

---

## 13) ما لم يتم اعتباره مكتملًا

### Master UI

لم يتم تعديل:

`erp-frontend/companies/company-1/main.html`

لأن ملكية هذا الملف في هذه المهمة تخص المالك، ولأن المحتوى الكامل الحالي لم يكن قابلًا للقراءة line-by-line من أداة التنفيذ.

### Browser E2E

لم يتم تنفيذ اختبار Browser فعلي على `main.html` الحالي داخل متصفح في هذه البيئة.

لذلك لا يجوز تسجيل:

`BROWSER E2E = VERIFIED`

ولا يجوز تسجيل:

`SALES TARGETS ENGINE = 100% CLOSED`

على مستوى النظام الكامل.

### النتيجة الصحيحة حاليًا

`DATABASE = CLOSED`

`RPC = CLOSED`

`EDGE = CLOSED`

`REALTIME = CLOSED`

`AUDIT = CLOSED`

`PRODUCTION BACKEND = CLOSED`

`MASTER UI = OWNER OPEN`

`BROWSER E2E = OPEN`

`SYSTEM-LEVEL SALES TARGETS CLOSURE = OPEN`

وهذا هو التصنيف الصادق الذي يمنع إعلان إغلاق وهمي.

---

## 14) ما يجب أن يفعله مالك المشروع على Master UI عند توفر محتوى كامل قابل للقراءة

لا تستخدم أرقام Report173.

لا تستخدم `sales/manager.html` كبديل.

لا تستخدم `Current/PWA/main2/*` كمصدر حالي.

نفّذ التسلسل التالي فقط بعد الحصول على النص الحالي الكامل للـmaster:

```text
READ CURRENT main.html TO EOF
↓
SEARCH EXACT CURRENT TARGET/PARENT TAB/FUNCTION
↓
CAPTURE FULL CURRENT BLOCK
↓
CAPTURE EXACT START + EXACT END LINE
↓
IDENTIFY THE LAST FULL LINE OF THE BLOCK
↓
PREPARE ONE COMPLETE SURGICAL REPLACEMENT
↓
OWNER APPLIES SURGERY
↓
PUBLISH EXACT CURRENT MASTER
↓
RUN BROWSER E2E
↓
VERIFY CONSOLE
↓
CALL sales-target-engine through real JWT session
↓
VERIFY list/create/save/approve/preview/post/retry/reverse
↓
VERIFY realtime refresh
↓
VERIFY audit rows
↓
RECONCILE DATABASE + DEPLOYMENT + FRONTEND
↓
ONLY THEN CLOSE
```

إذا كان القسم موجودًا لكنه قديم، لا يُعاد بناؤه إلا بقدر ما يلزم لإيصاله إلى العقد الحالي. ما ثبت إصلاحه لا يُصلح مرة أخرى بلا سبب.

---

## 15) Final Self-Audit

### What I Proved

- تم التحقق من Current frontend HEAD وParent.
- تم تثبيت `main.html` الحالي كـSource of Truth عبر `forensic_main_assembly.yml`.
- تم بناء Sales Targets Production schema مباشرة.
- تم بناء RPC المركزي وتشغيله فعليًا.
- تم بناء RLS/Audit/Realtime/indexes.
- تم نشر Edge Function حقيقي بـJWT.
- تم تنفيذ E2E database transactional كامل من الخطة حتى reversal.
- تم إثبات idempotent retry.
- تم إصلاح Audit trigger bug ظهر أثناء الاختبار.
- تم مزامنة hardening إلى Git canonical source.
- تم التأكد أن Production target tables لا تحتوي test residue.

### What I Did Not Prove

- لم تُثبت قراءة `main.html` الحالي كاملًا إلى EOF بسبب حد أداة المحتوى.
- لم يُنفذ Browser E2E حقيقي في هذه البيئة.
- لم يُثبت أن واجهة Sales Targets الحالية داخل Master موجودة أو مكتملة أو مرتبطة بالـEdge الجديد.
- لم يُثبت أن جميع tabs الأخرى في Master Gold/Diamond مكتملة وظيفيًا.

### What Could Still Be Wrong

- قد يكون في Master UI الحالي Sales Targets UI قديم أو ناقص لا يمكن رؤيته دون قراءة الملف الكامل.
- قد توجد wiring dependencies في Master لا تظهر من backend-only evidence.
- لا يمكن إثبات Console cleanliness دون Browser E2E.

### Final Confidence

`Production Sales Targets Backend: HIGH`

`Production Runtime Database Contract: HIGH`

`Master UI Integration: UNPROVEN`

`Browser E2E: UNPROVEN`

`Overall Gold Closure: OPEN`

---

## 16) إرشادات إلزامية للمساعد القادم — كيف يبدأ وكيف يصل إلى الحقيقة

ابدأ **بالملف الفعلي الحالي** وليس بالتقرير.

1. اقرأ أحدث Git HEAD وDirect Parent وParent of Parent للـfrontend.
2. ثبّت Blob SHA الحالي لـ`companies/company-1/main.html`.
3. اقرأ `forensic_main_assembly.yml` وتأكد أن published main هو Source of Truth.
4. اقرأ `main.html` الحالي كاملًا إلى EOF؛ لا تستخدم أرقامًا قديمة من التقارير.
5. افحص Production schema الحالي والـRPC والـEdge والـRealtime والـRLS والـaudit.
6. قارن Git canonical backend بما هو deployed في Production، وحدد drift فقط.
7. لا تعِد إصلاح ما ثبت أنه يعمل.
8. حدد **Closure Unit واحدة فقط**.
9. لكل Defect: `FOUND → ROOT CAUSE → HISTORICAL REVIEW → TARGET CONTRACT → SURGICAL FIX → TEST → DEPLOY → PRODUCTION VERIFY → CLOSE`.
10. أي بيانات مريبة لا تُحذف بالتخمين؛ أثبت أولًا هل هي fixture أو operational data ثم صححها.
11. أي UI surgery يجب أن تكون على `main.html` الحالي فقط، بعد تحديد الـexact current block وexact start/end lines.
12. اختبر الـBrowser فعلًا قبل إعلان UI closure.
13. لا تحوّل Backend PASS إلى System PASS.
14. لا تحوّل Staging/Transactional PASS إلى Production Browser PASS.
15. في نهاية كل جلسة حدّث `CURRENT_STATE.md` وأضف تقريرًا جديدًا، ولا تعدّل التقارير السابقة.
16. قبل كل نسبة أو closure، التقط Production snapshot جديدًا في نفس لحظة التقرير.

هذه السلسلة هي الطريق الصحيح للوصول إلى الحقيقة بدون إعادة العمل أو تراكم دين جديد.

---

## 17) الحالة النهائية لهذه الجلسة

```text
CURRENT GIT             = VERIFIED
CURRENT SOURCE          = MASTER IDENTIFIED, FULL EOF READ UNPROVEN
CURRENT PRODUCTION      = VERIFIED
CURRENT DATABASE        = VERIFIED
CURRENT DEPLOYMENT      = VERIFIED
SALES TARGET BACKEND    = CLOSED
SALES TARGET EDGE       = CLOSED
SALES TARGET REALTIME   = CLOSED
SALES TARGET AUDIT      = CLOSED
MASTER UI               = OWNER OPEN
BROWSER E2E             = OPEN
OVERALL CLOSURE         = OPEN
```

**لا يوجد ادعاء زائف بأن Sales Targets أصبحت 100% Closed على مستوى النظام الأم.**

الـProduction foundation والـEngine أصبحا جاهزين وقابلين للاختبار الحقيقي من الـMaster؛ الإغلاق النهائي يتطلب فقط ربط/تصحيح الـMaster الحالي ثم Browser E2E حقيقي وإعادة reconciliation من Production في نفس اللحظة.
