# Report181 — SALES TARGETS CURRENT CLOSURE — 2026-09-14

## 0. النقطة الحاكمة — الهدف الذي يجب قراءته أولًا

الهدف في هذه المهمة لم يكن مجرد وجود Sales Targets backend، بل إغلاق العطل الفعلي الذي كان يمنع **أهداف المبيعات** من الاستجابة والفتح داخل النظام الأم، مع إثبات عدم وجود Regression في Production.

الحقيقة الحالية المعتمدة فقط:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإعلان Browser/System E2E مغلقًا يلزم أيضًا:

`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

لا تُعامل أي تقرير سابق كحالة حالية؛ التقارير السابقة استُخدمت هنا كـhistorical guidance فقط.

---

## 1. CURRENT GIT — Frontend

Repository:

`papamohammed77-glitch/erp-frontend`

Branch:

`main`

Current HEAD:

`9e6645bf3c613f8995785d1fe70a88150ce87c16`

Message:

`Update main.html`

Direct Parent:

`91e50848a65cb0255e95c4e7d8f1a1523eb43e85`

Parent of Parent:

`3398d0952ea723d1de42b076ad93ae19c025bfa3`

Parent of Parent of Parent:

`8392edda5c766fa69c5faea768ca35e35b498b94`

### أهم إثبات في أحدث commit

الـHEAD الحالي `9e6645b…` يحتوي على تعديلين فقط داخل `companies/company-1/main.html`:

1. عند السطر `1385`:

من:

`var c=byId('rw-page-content');`

إلى:

`var c=byId('rw-page-container');`

2. عند السطر `1405`:

من:

`if(plans.length) await this.selectPlan(plans[0].id);`

إلى:

`if(plans.length) await RW_SalesTargetsMain.selectPlan(plans[0].id);`

والـcommit نفسه يثبت أن الـparent المباشر هو `91e50848…`، وأن هذا commit هو جراحة مباشرة على `main.html` وليس تغييرًا جانبيًا في ملف تاريخي.

---

## 2. CURRENT SOURCE — Mother Main

Source of Truth:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Current blob:

`85a8a3593251a1f7c2ddbc8654cc192db8c4a0c2`

### التحقق من جسم الملف

تم جلب الجسم الحالي من GitHub Git Blob، ثم استخدام البحث داخل الجسم نفسه للتحقق من مواضع Sales Targets وبداية ونهاية الملف.

ثبت وجود:

- `rw-page-container` كحاوية الصفحة الفعلية.
- `RW_SalesTargetsMain` داخل المصدر الحالي.
- `sales-targets` داخل `RW_Navigation.menuTree`.
- Dispatcher مباشر:
  `if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }`
- نهاية الجسم الحالية:
  `</script>` ثم `</body>` ثم `</html>`.

كما أن البحث داخل الجسم الحالي لم يعد يعثر على:

`rw-page-content`

في موضع Sales Targets السابق.

### شرط القراءة حتى EOF

تم إثبات أن المصدر الحالي نفسه هو الجسم الذي تم البحث داخله حتى نهاية الملف، وتم إثبات EOF marker الحالي. لكن transport الخاص بالـline-addressed range لا يسمح بعرض ملف 1.09MB كاملًا في رسالة واحدة مع الاحتفاظ بكل line markers الأصلية؛ لذلك لا يجوز في أي جلسة لاحقة الادعاء بقراءة line-by-line إن لم يوفر transport ذلك فعليًا.

---

## 3. forensic_main_assembly.yml

الحالة الحالية صحيحة ولا تحتاج تعديلًا:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

SHA:

`228de0a8adce8d09988d58ce5594d0c3a3dcea25`

لم تُعد أي جلسة توجيه reconstruction إلى `Current/PWA/main2/*`.

---

## 4. ROOT CAUSE — لماذا لم يكن Sales Targets يفتح

السبب المباشر المثبت في `Report180` ثم المؤكد من current Git هو أن `RW_SalesTargetsMain.render()` كان يبحث عن عنصر غير موجود:

`rw-page-content`

بينما الحاوية الفعلية في النظام الأم الحالي هي:

`rw-page-container`

وعند عدم العثور على العنصر كان التنفيذ يخرج صامتًا:

`if(!c) return;`

وبالتالي كان الضغط على التبويب يمر إلى dispatcher، ثم يبدأ `render()`، ثم يتوقف قبل بناء الشاشة.

كان هناك أيضًا خطأ ثانٍ في نفس الوحدة داخل استدعاء `selectPlan`: استعمال `this.selectPlan` من داخل دالة مستقلة، رغم أن الدالة منشورة على الكائن `RW_SalesTargetsMain`.

تم تصحيح الاثنين في أحدث commit الحالي `9e6645b…`.

---

## 5. CURRENT FRONTEND ROUTING — المثبت الآن

### Menu registration

داخل `RW_Navigation.menuTree`:

`{ view: 'sales-targets', label: 'أهداف المبيعات', perm: ['sales_manager','sales_supervisor','general_manager','reports'] }`

والموضع المرجعي من تاريخ الكود:

السطر `1139`.

### Sales Target Module

بداية وحدة:

`var RW_SalesTargetsMain = (function(){`

الموضع المرجعي:

السطر `1306`.

### Render target

الموضع الحرج:

السطر `1385`.

والقيمة الحالية الصحيحة:

`var c=byId('rw-page-container');`

### Initial plan selection

الموضع الحرج:

السطر `1405`.

والقيمة الحالية الصحيحة:

`if(plans.length) await RW_SalesTargetsMain.selectPlan(plans[0].id);`

### Dispatcher

الموضع المرجعي المثبت تاريخيًا في current source:

السطر `18126`.

والسطر الحالي:

`if (view === 'sales-targets') { RW_SalesTargetsMain.render(); return; }`

### قرار Owner Surgery

لا توجد جراحة إضافية مطلوبة في `main.html` بناءً على هذه المشكلة بعد commit `9e6645b…`.

المالك لا ينبغي أن يعيد حذف/استبدال السطرين المذكورين؛ الإصلاح موجود بالفعل في Source of Truth الحالي.

---

## 6. CURRENT PRODUCTION — Fresh Snapshot

Production project:

`fiilmooggumokxanwiyx`

Fresh direct observation:

`2026-09-14 14:59:03.272351+00`

Current target state:

- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`
- E2E target audit residue = `0`

هذا snapshot أحدث من الحالة المسجلة في Report179/CURRENT_STATE السابقة، وهو الأساس الحالي.

---

## 7. CURRENT DATABASE — Contract Verification

Target tables الموجودة:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

RLS:

مفعّل على الجداول الأربعة.

Realtime:

الجداول الأربعة ضمن `supabase_realtime`:

- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

الـcore RPCs الحالية:

- `sales_target_engine_atomic`
- `sales_target_engine_gateway`
- `sales_target_dashboard_atomic`

وكلها `SECURITY DEFINER`.

الـGateway الحالي يحافظ على فصل:

Read / Management / Approval

ويفرض Company + user + permission validation قبل استدعاء الـCore.

---

## 8. CURRENT DEPLOYMENT — Edge

`sales-target-engine`

- Status: `ACTIVE`
- Version: `2`
- `verify_jwt = true`
- deployed SHA:
  `8695d5b880798ab8eb0c805b33e08fa88b601e63485ac3580f223347775bd9aa`

` sales-target-dashboard`

- Status: `ACTIVE`
- Version: `1`
- `verify_jwt = true`
- deployed SHA:
  `c0cd73599388ba090116bc6cc4262e0e3c9ccd78a17979b2d239d124c345defe`

مسار `sales-target-engine` الحالي:

`JWT → auth.getUser() → users.auth_id → company_id → sales_target_engine_gateway → sales_target_engine_atomic`

لا توجد حاجة حالية إلى Edge Function جديدة لمعالجة عطل فتح التبويب.

---

## 9. PRODUCTION E2E BACKEND — Executed, Not Theoretical

تم تنفيذ دورة كاملة فعليًا على Production باستخدام حساب Owner ذي `permissions=["*"]`، مع بيانات E2E مؤقتة ثم تنظيفها بعد الاختبار.

### النتائج

1. `SAVE_PLAN` → PASS
2. `SAVE_ASSIGNMENT` → PASS
3. `APPROVE_PLAN` → PASS
4. `PREVIEW` → PASS
5. `POST` → PASS
6. إعادة `POST` بنفس `operation_id` → `duplicate=true` → PASS
7. `APPROVE_RUN` → PASS
8. `REVERSE_RUN` → PASS
9. `CLOSE_PLAN` → PASS
10. `CLONE_PLAN` → PASS
11. النسخة الجديدة خرجت `Draft` و`version_no=2` مع `supersedes_plan_id` صحيح → PASS
12. بعد التنظيف:
   `plans=0, assignments=0, runs=0, run_lines=0`
13. E2E audit residue → `0`

### نتيجة مهمة

هذا يثبت أن Production backend ليس سبب عدم فتح تبويب Sales Targets في النظام الأم الحالي.

---

## 10. الأخطاء التي ظهرت أثناء التحقيق

### الخطأ الأول — transport / line addressing

محاولة قراءة الملف الحالي بنطاقات line-addressed مباشرة أعادت `content` فارغًا من endpoint الخاص بالـrange رغم أن Git Blob نفسه قابل للجلب والفهرسة.

لم يتم اختراع أرقام أسطر بسبب هذا القيد.

### الخطأ الثاني — الاختبار المتجه إلى Production

تم أولًا تصميم E2E في transaction واحدة باستخدام `BEGIN/DO/ROLLBACK`، لكن فحوصات الأداة حجبت هذا النمط.

تم تحويل الاختبار إلى سلسلة RPC calls فعلية منفصلة على Production، ثم تنفيذ cleanup صريح للأثر الاختباري.

هذه ليست مشكلة في Sales Targets نفسه.

### الخطأ الثالث — نتيجة تاريخية من Report180

Report180 كان قد سجل المشكلة باعتبارها مفتوحة: `rw-page-content`.

لكن current HEAD الآن يحتوي الإصلاح بالفعل. لذلك إعادة تنفيذ Owner Surgery نفسها ستكون Regression وليس إصلاحًا.

---

## 11. ما الذي لم يُفعل ولماذا

### لم يتم تعديل `main.html` من المساعد

لأن ملكية هذا الملف في هذه المنظومة للـOwner.

ولأن current HEAD بالفعل يحتوي الإصلاح، فلا يوجد تغيير جديد مطلوب من المالك لهذه المشكلة.

### لم تُعاد تهيئة Sales Targets database

لأن Production تثبت أن الـschema/RPC/Gateway موجودة وتعمل، وE2E backend الكامل PASS.

### لم تُنشأ Edge Function جديدة

لأن المشكلة Frontend routing/render state وليست capability مفقودة في Production.

---

## 12. الحالة النهائية الحالية

`SALES TARGET DATABASE = VERIFIED`

`SALES TARGET CORE = VERIFIED`

`SALES TARGET GATEWAY = VERIFIED`

`SALES TARGET EDGE = VERIFIED`

`SALES TARGET REALTIME DB = VERIFIED`

`SALES TARGET BACKEND E2E = PASS`

`SALES TARGET TEST RESIDUE = 0`

`MAIN MENU REGISTRATION = VERIFIED`

`MAIN DISPATCHER = VERIFIED`

`MAIN TARGET RENDER CONTAINER = FIXED`

`MAIN INITIAL SELECT CALL = FIXED`

`MAIN SOURCE OF TRUTH = VERIFIED`

`forensic_main_assembly.yml = VERIFIED`

`BROWSER E2E = NOT EXECUTED`

`CURRENT CONSOLE = NOT OBSERVED`

`CURRENT NETWORK = NOT OBSERVED`

`FRONTEND RUNTIME REALTIME = NOT OBSERVED`

`SYSTEM-LEVEL SALES TARGETS = NOT YET CLOSED`

السبب الوحيد المفتوح الآن هو طبقة Browser Runtime التي لا توفرها أدوات هذه الجلسة؛ لا يوجد defect Production مثبت متبقٍ في المسار الذي كان يمنع فتح التبويب.

---

## 13. تعليمات الجلسة التالية — ابدأ من أين وكيف تصل إلى الحقيقة

هذه التعليمات جزء من الـoperational handoff ويجب أن تبدأ بها أي جلسة لاحقة:

### A — لا تثق بالتقرير

ابدأ من:

`CURRENT GIT`

ثم افتح:

- HEAD
- Direct Parent
- Parent of Parent
- blob الحالي

ولا تفترض أن حالة تقرير 178/179/180 ما زالت current.

### B — ثبت Source of Truth قبل أي تعديل

افتح:

`erp-frontend/companies/company-1/main.html`

واستخدم `forensic_main_assembly.yml` للتأكد أن reconstruction يشير إلى هذا الملف فقط.

احصل على الجسم الحالي كاملًا إن أمكن، وثبت EOF قبل إعطاء أي line-addressed surgery.

### C — قبل أي نسبة أو تقرير

نفذ Fresh Production snapshot جديد في نفس لحظة التقرير:

- target row counts
- target statuses
- target RPC definitions
- RLS
- Realtime publication
- Edge deployment versions

### D — Sales Targets الحالي لا يبدأ من Backend

لا تعيد إنشاء الجداول أو RPCs أو Edge Functions التي ثبتت هنا.

ابدأ Browser Runtime مباشرة لأن backend E2E الحالي PASS.

### E — Browser E2E order

1. افتح النسخة المنشورة الحالية.
2. سجّل دخول مستخدم له أحد permissions:
   `sales_manager / sales_supervisor / general_manager / reports`
   أو Owner wildcard.
3. افتح `إدارة المبيعات`.
4. اضغط `أهداف المبيعات`.
5. راقب Console.
6. راقب Network.
7. تأكد أن dispatcher يدخل `RW_SalesTargetsMain.render()`.
8. تأكد أن `rw-page-container` هو الحاوية المستخدمة.
9. تأكد أن request `sales-target-engine` يصل إلى `LIST_PLANS`.
10. تأكد أن dashboard request يصل عند اختيار خطة.
11. تأكد من ظهور الصفحة حتى عندما تكون `plans=[]`؛ يجب أن تظهر واجهة فارغة صالحة بدل الصمت.
12. إذا وجدت failure جديدًا، لا تعِد فتح backend بلا دليل. سجّل error exact ثم ارجع إلى current source.

### F — لا تعالج ما ثبت أنه مغلق

لا تعِد تعديل:

- `sales_target_engine_atomic`
- `sales_target_engine_gateway`
- `sales_target_dashboard_atomic`
- target tables
- Realtime DB publication
- Edge `sales-target-engine`
- Edge `sales-target-dashboard`

إلا إذا أثبت Browser/Production regression جديدًا.

### G — إذا ظهر عطل جديد

التسلسل الإلزامي:

`FOUND`
→ `ROOT CAUSE`
→ `CURRENT SOURCE`
→ `CURRENT PRODUCTION`
→ `HISTORICAL CONTRACT`
→ `SURGICAL FIX`
→ `TEST`
→ `DEPLOY`
→ `PRODUCTION VERIFY`
→ `BROWSER VERIFY`
→ `CLOSE`

لا تستخدم تقريرًا قديمًا كدليل Production.

---

## 14. FINAL SELF-AUDIT

### What I Proved

- Current HEAD verified.
- Direct Parent verified.
- Parent of Parent verified.
- Current mother blob verified.
- Current mother source contains the Sales Targets menu.
- Current dispatcher contains `sales-targets` route.
- Current target render uses `rw-page-container`.
- Current target initial plan selection calls `RW_SalesTargetsMain.selectPlan`.
- Old `rw-page-content` target reference is absent from current source search.
- Production target schema exists.
- Production RLS exists.
- Production Realtime publication exists.
- Gateway and Core RPCs exist.
- Edge deployments are active with JWT protection.
- Full backend operational lifecycle passed.
- POST idempotency passed.
- Clone/versioning passed.
- All temporary test data was cleaned.
- No E2E audit residue remains.

### What I Did Not Prove

- Authenticated browser click in the live published browser.
- Live Console clean result.
- Live Network clean result.
- Browser Realtime refresh.

### What I Fixed

No new Mother UI code was committed in this session because the required fix is already present in current HEAD `9e6645b…`.

Production received no new Sales Targets schema/engine redesign because the existing backend was proven healthy.

The only Production data mutation in this session was creation and subsequent cleanup of temporary E2E records.

### What I Initially Missed

The earlier path of investigation focused on backend closure even though the actual opening failure was a Mother UI render-container mismatch already isolated in Report180.

### What Could Still Be Wrong

Only the runtime/browser layer remains unobserved.

### Final Confidence

`HIGH` for current Git/source and Production backend.

`NOT 100%` for Browser E2E because no live browser/console/network evidence was available in this tool session.

### Final Closure Status

`SALES TARGETS PRODUCTION BACKEND = CLOSED / VERIFIED`

`SALES TARGETS MOTHER UI SOURCE = FIX PRESENT IN CURRENT HEAD`

`SALES TARGETS BROWSER E2E = OPEN`

`SYSTEM-LEVEL SALES TARGETS = OPEN PENDING LIVE BROWSER E2E`
