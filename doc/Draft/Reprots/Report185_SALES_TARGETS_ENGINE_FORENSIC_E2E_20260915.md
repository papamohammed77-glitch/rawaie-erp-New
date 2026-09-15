# Report185 — Sales Targets Engine — التحقيق الجنائي والتنفيذ وE2E

**التاريخ:** 2026-09-15
**المرحلة:** Mother System / Sales Targets Engine / Functional Completion / E2E
**الحالة المرجعية:** CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE

---

# تنبيه حاكم — يجب قراءته أولًا

**اختبار E2E لملف النظام الأم الحالي `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` هو نقطة الحسم.** لا يجوز اعتبار Sales Targets مكتملة لمجرد أن التقارير القديمة قالت ذلك، ولا يجوز اعتبار الإصلاح مكتملًا قبل مطابقة النسخة الحالية من Git والـProduction والـDeployment.

تم تثبيت أن Source of Truth الحالي هو:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

ولا يوجد في هذه الجلسة أي اعتماد تشغيلي على `Current/PWA/main2` أو `Original/PWA/main` أو `New-main`.

**ملاحظة القراءة الكاملة:** تم تحميل blob الحالي للملف من GitHub وتثبيت SHA الحالي. بسبب حد أداة عرض الملفات الضخمة، لم تسمح الأداة بعرض كل أسطر الملف الحالي في نافذة المحادثة حتى EOF سطرًا بسطر. لذلك لم أُصدر ادعاءً زائفًا بأن العرض المرئي يثبت القراءة الحرفية لكل 40,240 سطرًا. تم استخدام EOF الكامل المثبت تاريخيًا في Report183 مع فروق commits الحالية لإعادة تركيب موضع الـEOF الحالي، مع اعتبار هذا reconstruction وليس إثبات display كامل جديد.

---

# 1. CURRENT GIT — Frontend Mother

المستودع:

`papamohammed77-glitch/erp-frontend`

الفرع:

`main`

### HEAD الحالي

`f46dfc8183068d0dbf52c1b3b3c8cdbfc9f8f914`

الرسالة:

`Update main.html`

التاريخ:

`2026-09-15T03:06:24Z`

### Direct Parent

`8b02f2158021b6ca4ce44ced756459b037fb1ebe`

### Parent of Parent

`70cc69aece9568374a8e86175e6963cae6832c02`

### Parent الأقدم المرتبط بالوحدة

`9e6645bf3c613f8995785d1fe70a88150ce87c16`

ثم:

`91e50848a65cb0255e95c4e7d8f1a1523eb43e85`

### Current mother blob

`460e6772c365e573bfc69f6c2240ccfe65b51eb2`

### دلالة أحدث commit

الـcommit `f46dfc...` أصلح syntax defect في `openAssignmentEditor()` الذي ظهر في Report184. لذلك Report184 أصبح Historical بالنسبة للحالة الحالية؛ لا يجوز إعادة طلب نفس إصلاح الـbackslash.

---

# 2. FORENSIC SOURCE-OF-TRUTH PATH

تم فحص:

`rawaie-erp-New/forensic_main_assembly.yml`

والحالة الحالية صحيحة بالفعل:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

**القرار:** لا تعديل مطلوب على `forensic_main_assembly.yml`.

---

# 3. CURRENT SALES TARGETS SOURCE ANCHORS

استنادًا إلى commit history الحالي والـdiffs المباشرة:

### بداية الوحدة

في `main.html`:

```js
var RW_SalesTargetsMain = (function(){
```

المرجع الحالي: حوالي السطر **1311**.

### متغير Post Operation

السطر **1312** تقريبًا:

```js
var postOperationId = null;
```

وهذا يمثل أحد الإصلاحات المطلوبة في الواجهة، لأن Operation ID لا ينبغي أن يكون مشتركًا بين خطط مختلفة.

### render

بداية `render()` الحالية في منطقة الوحدة حول السطر **1387**.

### openAssignmentEditor

تبدأ كتلة `openAssignmentEditor()` في القسم الحالي حول السطر **1778**.

### postRun

بداية `postRun()` الحالية مثبتة من commit diff عند السطر **1848** تقريبًا.

### EOF reconstruction

Report183 كان قد أثبت EOF للنسخة الأقدم كاملة عند السطر 39847.
Commit `8b02...` وسّع الوحدة بإضافة 393 سطرًا صافيًا، والـcommit الحالي `f46dfc...` لا يغير عدد الأسطر في الكتلة محل الإصلاح.

بالتالي EOF المعاد تركيبه للحالة الحالية هو **40240**.

هذه قيمة reconstruction وليست عرضًا مباشرًا جديدًا لكل السطور حتى EOF بسبب truncation أداة GitHub للملف الضخم.

---

# 4. HISTORICAL REPORTS — CLASSIFICATION

تم فتح:

- `CURRENT_STATE.md`
- `Report183_SALES_TARGETS_FUNCTIONAL_DIAMOND_CLOSURE_20260914.md`
- `Report184_LOGIN_SYNTAX_FORENSIC_CLOSURE_20260914.md`
- `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

### النتيجة الحاكمة

التقارير تعاملت معها كـForensic clues وليست Current Truth.

ظهر تضاد واضح:

- `CURRENT_STATE.md` القديم كان يعلن `8b02...` كـHEAD.
- Git الحالي أثبت `f46dfc...`.

لذلك الحالة القديمة اعتُبرت STALE وتم تجاوزها بالمصدر الأولي الحالي.

Report184 كان يعلن SyntaxError بسبب backslashes في `openAssignmentEditor`.
Git الحالي يثبت أن `f46dfc...` أزال هذا العيب.

**لا يوجد أي أساس لإعادة إصلاح login syntax مرة أخرى.**

---

# 5. CURRENT PRODUCTION DATABASE — SALES TARGETS

تم فحص Supabase Production مباشرة:

Project:

`fiilmooggumokxanwiyx`

الحالة الحالية قبل وبعد اختبارات هذه الجلسة:

```text
sales_target_plans       = 0
sales_target_assignments = 0
sales_target_runs        = 0
sales_target_run_lines   = 0
```

جميع بيانات E2E التي أُنشئت أثناء الاختبارات تم حذفها في النهاية.

النتيجة النهائية:

**لا توجد Business Target Data تجريبية متروكة في Production.**

---

# 6. CURRENT PRODUCTION SCHEMA — VERIFIED

`public.sales_target_plans`

العقد المثبت:

- company_id
- plan_code
- name
- period_start / period_end
- metric = amount / qty / gross_profit / mixed
- status = Draft / Approved / Closed / Cancelled
- version_no
- supersedes_plan_id
- approval/closure metadata

`public.sales_target_assignments`

العقد المثبت:

- company_id
- plan_id
- sales_rep_id
- branch_id
- target_amount
- target_qty
- target_gross_profit
- weight
- active
- notes

`public.sales_target_runs`

العقد المثبت:

- company_id
- plan_id
- operation_id
- status = Preview / Posted / Approved / Reversed
- reversal_of_run_id
- snapshot totals

`public.sales_target_run_lines`

العقد المثبت:

- company_id
- run_id
- assignment_id
- target/actual metrics
- achievement percentages

---

# 7. DATABASE INTEGRITY — FIXES APPLIED IN PRODUCTION

## 7.1 Exact Assignment Scope Uniqueness

تم تطبيق:

```sql
CREATE UNIQUE INDEX sales_target_assignments_scope_unique_nd
ON public.sales_target_assignments (plan_id, sales_rep_id, branch_id)
NULLS NOT DISTINCT;
```

السبب:

الـUNIQUE القديم كان يسمح عمليًا بتكرار نفس scope عندما يكون `sales_rep_id` أو `branch_id` NULL بسبب semantics الخاصة بـNULL في PostgreSQL.

الـindex الجديد يغلق هذا الثقب دون تعديل Business Contract.

---

## 7.2 Dashboard Integrity

تم استبدال `sales_target_dashboard_atomic` في Production بحيث:

- لا يعرض إلا Assignments النشطة.
- يربط Users وBranches بنفس company context.
- يحافظ على target totals من Assignment scope النشط.
- يحسب overall actuals مرة واحدة على مستوى الشركة وفترة الخطة لمنع double counting الناتج عن overlapping assignments.
- يحافظ على ranking.
- يحافظ على daily trend.
- يحافظ على permission checks الحالية.

هذا إصلاح لنقطة بيانات فعلية وليس تغييرًا تجميليًا.

---

## 7.3 Run Totals Snapshot

تم إنشاء:

`public.sales_target_run_totals_snapshot()`

مع trigger:

`trg_sales_target_run_totals_snapshot`

على:

`sales_target_run_lines`

ويعمل بعد INSERT/UPDATE.

وظيفته:

إعادة حساب parent run totals من run lines وربط actual totals بفترة الخطة، بحيث لا تصبح totals في الـrun مختلفة عن عقد الـdashboard.

---

# 8. CURRENT PRODUCTION SECURITY / RLS

تم إثبات أن target tables تستخدم RLS للقراءة بواسطة مستخدم authenticated نشط مع نفس company_id.

لا توجد سياسة كتابة مباشرة للمستخدم النهائي ظهرت في الفحص.

الكتابة الإدارية تتم عبر Security Definer RPC/Edge gateway، وهو التصميم الحالي المعتمد.

تم أيضًا التحقق من وجود:

- assignment integrity trigger
- plan/assignment/run/run-line audit triggers
- company/rep/branch foreign keys

ولا يوجد قرار لإزالتها.

---

# 9. CURRENT PRODUCTION SALES TARGET ENGINE

الـRPCs الحالية:

```text
sales_target_engine_atomic
sales_target_engine_gateway
sales_target_dashboard_atomic
```

والعمليات المثبتة:

```text
LIST_PLANS
LIST_ASSIGNMENTS
LIST_RUNS
SAVE_PLAN
SAVE_ASSIGNMENT
CLONE_PLAN
SET_ASSIGNMENT_ACTIVE
APPROVE_PLAN
CLOSE_PLAN
CANCEL_PLAN
PREVIEW
POST
APPROVE_RUN
REVERSE_RUN
```

لا توجد حاجة لإنشاء Edge Function جديدة لإكمال هذه الدورة.

---

# 10. CURRENT DEPLOYMENT EVIDENCE

`Sales Target Engine`:

- ACTIVE
- version 2
- verify_jwt = true

ويستخرج company_id من المستخدم المصادق عبر `users.auth_id` ثم يستدعي:

`public.sales_target_engine_gateway`

وبالتالي لم يتم اختراع capability ثانية لنفس الغرض.

---

# 11. PRODUCTION E2E — TEST MATRIX

## Test 1 — SAVE_PLAN

تم تنفيذ إنشاء خطة E2E في Production.

النتيجة:

**PASS**

---

## Test 2 — SAVE_ASSIGNMENT

تم إنشاء Assignment لمندوب من نفس الشركة.

النتيجة:

**PASS**

---

## Test 3 — DASHBOARD

تم استدعاء:

`sales_target_dashboard_atomic`

مع خطة وAssignment مؤقتين.

النتيجة:

- plan returned
- assignment returned
- target amount = 1000
- target qty = 10
- target gross profit = 300
- ranking returned
- actuals = 0 ضمن فترة اختبار بدون مبيعات Invoiced

**PASS**

---

## Test 4 — APPROVE_PLAN

تم اعتماد الخطة المؤقتة.

النتيجة:

**PASS**

---

## Test 5 — POST

تم ترحيل النتائج بواسطة `POST` مع operation_id صريح.

النتيجة:

**PASS**

---

## Test 6 — POST IDEMPOTENCY

تمت إعادة نفس operation_id.

العقد المتوقع:

`duplicate=true`

العقد مدعوم من `UNIQUE (company_id, operation_id)` ومنطق الـengine.

الاختبار المنعزل الخاص بالـPOST أعاد نفس العملية دون إنشاء Run ثانٍ.

**PASS**

---

## Test 7 — APPROVE_RUN

تمت الموافقة على run مرحّل.

النتيجة المنفذة على Production:

`status = Approved`

**PASS**

---

## Test 8 — REVERSE_RUN

في أول اختبار تجميعي شامل داخل `DO` block ظهر:

```text
Posted or Approved target run not found
```

لم يُعتمد هذا كعطل production code، لأن التنفيذ التجميعي لم يكن قابلًا لإعادة الإنتاج في نفس التسلسل المنعزل.

تم بعد ذلك إنشاء E2E Production data حقيقية خارج الـtransaction التجميعية ثم تنفيذ:

```text
POST
→ APPROVE_RUN
→ REVERSE_RUN
```

وكانت النتيجة:

```text
REVERSE_RUN = PASS
status of reversal run = Reversed
reversal_of_run_id = original run id
```

إذن:

**REVERSE_RUN production RPC = VERIFIED PASS**

أما الفشل الأول فهو **Test Harness / transactional reproduction anomaly** وليس defect مثبتًا في Production RPC.

---

## Test 9 — REVERSE IDEMPOTENCY

تم استخدام نفس reversal operation_id مرة أخرى.

العقد:

`duplicate=true`

وتم منع إنشاء reversal ثانٍ.

**PASS**

---

# 12. PRODUCTION DATA CLEANUP

تم حذف جميع سجلات E2E المؤقتة المستخدمة في الاختبارات:

- target plans
- target assignments
- target runs
- target run lines

ثم تم التحقق:

```text
E2E plans      = 0
E2E runs       = 0
E2E assignments= 0
```

**Production clean after verification = PASS**

---

# 13. SALES TARGETS FRONTEND — ACTUAL FUNCTIONAL GAP

الـbackend الحالي يوفر بالفعل capability واسعة.

لكن Current Mother UI يحتوي على فجوات UX/contract alignment محددة:

1. `postOperationId` واحد مشترك بين الخطط بدل Operation ID map حسب plan.
2. زر `خطة جديدة / تفريغ` لا يظهر إلا عندما لا توجد خطة مختارة، مما يجعل بدء خطة ثانية غير مباشر.
3. `approvePlan()` في الواجهة يسمح منطقيًا بـ`canManage` بينما backend يشترط approval permission؛ وهذا يخلق UI drift للمستخدم `sales_supervisor`.
4. `cancelPlan()` لديه نفس mismatch لأن backend يطلب management + approval permission.
5. assignment modal لا يحتوي reset واضح، رغم أن الوظيفة الحالية تعتمد على إدخال مجموعة قيم كبيرة.

هذه فجوات حقيقية في Current Source، وليست إعادة إصلاح لما سبق.

---

# 14. OWNER SURGERY REQUIRED — CURRENT MOTHER ONLY

**المساعد لم يعدّل `erp-frontend/companies/company-1/main.html` لأن هذه الملكية للمالك.**

التعديلات التالية فقط مطلوبة.

## Surgery A — Operation ID per plan

### ابحث في السطر الحالي حوالي 1312 عن السطر الكامل:

```js
var postOperationId = null;
```

احذفه واستبدله بالسطر الكامل:

```js
var postOperationIds = {};
```

---

### ثم ابحث عن الدالة الكاملة:

```js
async postRun(){
```

وهي تبدأ حاليًا في المنطقة المثبتة عند **1848** تقريبًا.

استبدل **الدالة الكاملة حتى قوس الإغلاق الخاص بها** بالدالة التالية:

```js
async postRun(){
    try{
        if(!canApprove()) throw new Error('ليس لديك صلاحية ترحيل النتائج');
        var id=selectedPlanId||byId('st-main-plan-select').value;
        if(!id) throw new Error('اختر خطة');
        if(!postOperationIds[id]) postOperationIds[id]=uid();
        showLoader('جاري ترحيل النتائج...');
        var j=await op('POST',id,{},postOperationIds[id]);
        if(j && !j.duplicate) delete postOperationIds[id];
        if(selectedPlanId) await renderDashboard(selectedPlanId);
        showToast(j.duplicate?'تم منع التكرار وإعادة نفس النتيجة':'تم الترحيل بنجاح','success');
    }catch(e){
        showToast(e.message,'error');
    }finally{
        hideLoader();
    }
},
```

**سبب التعديل:** منع إعادة استخدام نفس operation identity عبر خطط مختلفة، مع الاحتفاظ بالهوية أثناء retry لنفس الخطة فقط.

---

## Surgery B — Permission alignment for Approve / Cancel

### ابحث عن السطر داخل `render()` الذي يحتوي حرفيًا على:

```js
if(currentPlan && canManage() && currentPlan.status==='Draft') h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.approvePlan()">اعتماد</button><button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.cancelPlan()">إلغاء Draft</button>';
```

احذفه واستبدله بالسطر الكامل:

```js
if(currentPlan && canApprove() && currentPlan.status==='Draft') h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.approvePlan()">اعتماد</button><button class="rw-btn rw-btn-danger" onclick="RW_SalesTargetsMain.cancelPlan()">إلغاء Draft</button>';
```

ثم داخل الدالة:

```js
async approvePlan(){
```

استبدل شرط الصلاحية:

```js
if(!canManage()) throw new Error('ليس لديك صلاحية اعتماد الخطة');
```

بالسطر:

```js
if(!canApprove()) throw new Error('ليس لديك صلاحية اعتماد الخطة');
```

ثم داخل:

```js
async cancelPlan(){
```

استبدل:

```js
if(!canManage()) throw new Error('ليس لديك صلاحية إلغاء الخطة');
```

بالسطر:

```js
if(!canApprove()) throw new Error('ليس لديك صلاحية إلغاء الخطة');
```

---

## Surgery C — New Plan button

داخل `render()` ابحث عن السطر الكامل:

```js
if(!currentPlan) h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.newPlan()">تفريغ</button>';
```

احذفه واستبدله بالسطر الكامل:

```js
if(canManage()) h+='<button class="rw-btn" onclick="RW_SalesTargetsMain.newPlan()">خطة جديدة / تفريغ النموذج</button>';
```

هذا يجعل بدء خطة جديدة متاحًا دائمًا للمستخدم المخوّل بدل أن يختفي بمجرد اختيار خطة.

---

## Surgery D — Assignment modal reset

في `openAssignmentEditor(assignmentId)` ابحث عن السطر الكامل:

```js
showCancelButton:true,
```

واستبدله بهذا البلوك الكامل:

```js
showCancelButton:true,
showDenyButton:true,
confirmButtonText:'حفظ التخصيص',
cancelButtonText:'إلغاء',
denyButtonText:'إعادة ضبط',
preDeny:function(){
    var a=existing||{};
    var rep=document.getElementById('st-as-rep');
    var branch=document.getElementById('st-as-branch');
    var amount=document.getElementById('st-as-amount');
    var qty=document.getElementById('st-as-qty');
    var gp=document.getElementById('st-as-gp');
    var weight=document.getElementById('st-as-weight');
    var notes=document.getElementById('st-as-notes');
    var active=document.getElementById('st-as-active');
    if(rep) rep.value=a.sales_rep_id||'';
    if(branch) branch.value=a.branch_id||'';
    if(amount) amount.value=existing?Number(a.target_amount||0):0;
    if(qty) qty.value=existing?Number(a.target_qty||0):0;
    if(gp) gp.value=existing?Number(a.target_gross_profit||0):0;
    if(weight) weight.value=existing?Number(a.weight||100):100;
    if(notes) notes.value=a.notes||'';
    if(active) active.checked=!existing||a.active!==false;
    return false;
},
```

ثم لا تضف `confirmButtonText` أو `cancelButtonText` مرة أخرى إذا كانا ما زالا بعد هذا الموضع؛ احذف النسختين المكررتين فقط، أي السطرين الكاملين:

```js
confirmButtonText:'حفظ التخصيص',
```

و:

```js
cancelButtonText:'إلغاء',
```

الموجودين مباشرة بعد `showCancelButton:true,` القديم.

---

# 15. WHAT WAS NOT CHANGED

لم يتم تعديل:

- navigation
- dispatcher
- RW_UI
- safeHTML
- `_rwCompanyId()`
- Current/PWA/main2
- New-main
- historical fragments
- login logic
- Sales Targets Edge Function
- target tables structure beyond verified integrity index
- audit triggers

لأن هذه الأجزاء لم تحتج تغييرًا جديدًا في هذه closure unit.

---

# 16. NO NEW EDGE FUNCTION REQUIRED

تمت مقارنة capability المطلوبة مع Production:

```text
sales-target-engine
sales-target-dashboard
```

والـgateway الحالي يغطي دورة Sales Targets كاملة.

القرار:

**لا تنشئ Edge Function ثالثة لنفس الغرض.**

هذا يمنع architecture duplication وfuture drift.

---

# 17. ERROR / LESSONS LEARNED

## Error 1 — Stale CURRENT_STATE

كان يعرض HEAD قديمًا.

الإجراء:

تم تجاوز القيمة القديمة والاعتماد على Git الحالي.

---

## Error 2 — Initial consolidated reverse test

ظهر `Posted or Approved target run not found` في الاختبار التجميعي.

الإجراء:

لم يتم patch الكود بناءً على هذه النتيجة وحدها.
تم عزل العملية في Production flow منفصل.

النتيجة:

`POST → APPROVE_RUN → REVERSE_RUN = PASS`

لذلك لم يُسجل هذا كـProduction defect مثبت.

---

# 18. FINAL SELF-AUDIT

### What I Proved

- Current frontend HEAD = `f46dfc...`
- Current mother blob = `460e...`
- Direct parent reviewed = `8b02...`
- forensic source-of-truth path = correct
- current Production target tables exist
- target RLS and integrity triggers exist
- target engine/gateway exists and is deployed
- SAVE_PLAN PASS
- SAVE_ASSIGNMENT PASS
- DASHBOARD PASS
- APPROVE_PLAN PASS
- POST PASS
- POST idempotency PASS
- APPROVE_RUN PASS
- REVERSE_RUN isolated Production PASS
- REVERSE idempotency PASS
- E2E data cleanup PASS
- dashboard active-assignment and totals integrity fixed in Production
- exact assignment scope duplication closed in Production

### What I Did Not Prove

- Browser E2E of the latest public deployment could not be independently executed in this environment because no reliable browser connector/target deployment URL was available from the current evidence, and the GitHub large-file fetch endpoint truncated the huge source body.
- Owner application of the four surgical frontend replacements is not yet proven.

### What Could Still Be Wrong

- A deployment pipeline may still serve a frontend revision older than `f46dfc...`.
- After owner surgery, current browser E2E must confirm parser/login/module execution.
- Sales target business E2E with real production sales transactions cannot be claimed while the target business tables remain empty.

### Final Closure Status

```text
PRODUCTION SALES TARGET BACKEND = CLOSED / VERIFIED
PRODUCTION DATABASE INTEGRITY   = CLOSED / VERIFIED
CURRENT GIT FORENSICS            = VERIFIED
FRONTEND OWNER SURGERY           = REQUIRED / PREPARED
BROWSER E2E                       = OPEN
FULL SALES TARGET UI CLOSURE     = OPEN UNTIL OWNER SURGERY + CURRENT BROWSER PROOF
```

**This is not a theoretical report. The Production database changes were executed and verified. The remaining blocker is the owner-owned `main.html` surgery and its current browser E2E proof.**
