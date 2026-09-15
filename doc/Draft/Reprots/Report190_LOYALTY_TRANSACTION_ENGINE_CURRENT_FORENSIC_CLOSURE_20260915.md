# تقرير 190 — إغلاق Forensic لمحرك معاملات الولاء

**التاريخ:** 2026-09-15 07:xx UTC  
**المرحلة:** Loyalty Transaction Engine  
**الغرض:** استكمال الإغلاق الوظيفي لمحرك Loyalty، ثم تثبيت نقطة الاستكمال التالية دون إعادة إصلاح ما ثبت إصلاحه.

> ## تنبيه حاكم — يجب قراءته قبل أي استكمال
> **الحقيقة الحالية لا تُستمد من Report189 أو أي تقرير سابق.** التقارير Historical/Reference فقط. الحالة المعتمدة هي: `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`، ولإغلاق Browser E2E يلزم أيضًا `CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`.
>
> **النظام الأم المعتمد هو فقط:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`.
> الأجزاء التاريخية `Current/PWA/main2/*` و`Original/PWA/main/*` و`New-main` ليست Source of Truth.

---

## 1. EXECUTIVE RESULT

### النتيجة الحالية

تم إغلاق **Loyalty Transaction Engine في Production وظيفيًا** من ناحية قاعدة البيانات ودورة المعاملات.

تم إثبات الآتي مباشرة:

- `loyalty_engine_atomic` موجود ويغطي العمليات الحالية: `LIST_PROGRAMS`, `LIST_REWARDS`, `SAVE_PROGRAM`, `SAVE_REWARD`, `GET_ACCOUNT`, `LIST_TRANSACTIONS`, `EARN_ORDER`, `SYNC_ORDER`, `REDEEM`, `ADJUST`, `EXPIRE`, `REVERSE`.
- Edge Function `loyalty-engine` منشورة مع `verify_jwt=true` وتحوّل الطلب إلى الـRPC المركزي بعد استخراج `company_id` من المستخدم المصادق عليه.
- الـLoyalty tables لا تسمح بالوصول المباشر من `anon/authenticated`؛ التنفيذ من خلال طبقة محكومة.
- تمت إضافة unique idempotency index على `(company_id, operation_id)` عندما يكون `operation_id` موجودًا.
- تمت إضافة ربط تلقائي للولاء مع دورة الفاتورة: `AFTER INSERT OR UPDATE OF order_status` على `orders`، مؤجل `DEFERRABLE INITIALLY DEFERRED`، حتى تكون `order_details` مكتملة داخل نفس المعاملة قبل حساب نقاط الولاء.
- اختبار E2E لعملية Order مفوترة داخل Transaction مؤقتة نجح: كمية 15 × سعر 10 = قيمة مؤهلة 150، والبرنامج 10 جنيه = نقطة واحدة، فأُنشئت معاملة `EARN` بقيمة 15 نقطة.
- اختبار دورة البرنامج/المكافأة/الكسب/الاستبدال/العكس نجح داخل Transaction مؤقتة وتم `ROLLBACK` كامل؛ لا توجد بيانات اختبار دائمة.
- تم التحقق من وجود Audit triggers على `loyalty_programs`, `loyalty_rewards`, `loyalty_accounts`, `loyalty_transactions`.

### الإغلاق المتبقي

**Mother UI Loyalty Integration = OPEN جزئيًا فقط بسبب خطأ ترتيب Rendering في `main.html`.**

الواجهة الحالية تحتوي بالفعل على Loyalty navigation + permission map + routing + `RW_LoyaltyMain`، لذلك لا يجوز إعادة إضافة هذه الأجزاء.

الخطأ المثبت هو أن `renderConfig()` يعمل قبل اكتمال `loadPrograms()`، ثم لا يُعاد تشغيله بعد وصول البرامج. النتيجة: شبكة المكافآت تبقى على `جاري التحميل...` عندما لا يوجد `Active` program في الذاكرة لحظة أول render.

هذا هو **التعديل الوحيد اللازم حاليًا على النظام الأم** قبل Browser E2E.

---

## 2. CURRENT GIT FORENSICS

### Current mother repository

`papamohammed77-glitch/erp-frontend`

### Current HEAD أثناء المراجعة

`716ebf86b3c989a461cbf86151b37fcd0849b0c3`

Message:
`Add loyalty management features to main.html`

### Direct parent

`13425725f48c7decba3403ee631d8e0f2d757b0f`

### Mother file blob

`dd5516ea75d75e01a95d4782ec92603ecf427d2e`

### Current source verification

تم فتح الـmother file من Git blob الحالي مباشرة، ومراجعة محتواه إلى نهاية الملف، وتم إثبات EOF بالترتيب النهائي:

```html
</script>
</body>
</html>
```

وبذلك لا يوجد اعتماد على نسخة `main2` لإعطاء anchors الحالية.

### Git parent check

الـHEAD الحالي هو Commit Loyalty، وParentه هو `13425725...`، والـCommit موقع/Verified من GitHub. الـCommit أضاف Loyalty navigation/module إلى `main.html`.

### ملاحظة تنفيذية مهمة

أُنشئ بالخطأ Commit فارغ `11b99cab424496b9691e5ad92b36bd83ed7c2664` على `erp-frontend` أثناء محاولة تسجيل التنفيذ. GitHub أثبت أن `diff=null` و`files=null`، أي أنه **لم يغير `main.html`**. يجب اعتباره Git metadata residue لا Source Change.

---

## 3. CURRENT MOTHER UI FORENSIC RESULT

الـCommit الحالي أضاف:

### Navigation

السطر الحالي في المنطقة `1144` يحتوي بالفعل على:

```javascript
{ view: 'loyalty', label: 'الولاء والمكافآت', perm: ['sales_manager','sales_supervisor','general_manager','reports','customers','pos','telesales','orders','van-sales'] }
```

### Permission map

المسار الحالي يحتوي:

```javascript
'loyalty': 'customers',
```

### View routing

المسار الحالي يحتوي:

```javascript
if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }
```

### Loyalty module

`RW_LoyaltyMain` موجود حاليًا، ويستخدم:

```javascript
RW_SUPABASE_URL + '/functions/v1/loyalty-engine'
```

### سبب `جاري التحميل...`

داخل `render()` يوجد التسلسل الحالي:

```javascript
loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
renderConfig();
subscribeRealtime();
```

بينما `renderConfig()` يفعل:

```javascript
var active=currentPrograms.find(function(x){return x.status==='Active';});
if(active) loadRewards(active.id).then(renderRewards).catch(...);
```

إذن `renderConfig()` يعمل قبل وصول البرامج من `loadPrograms()`، فلا يرى `Active` program في الوقت المطلوب.

---

## 4. EXACT OWNER SURGICAL PATCH — MAIN.HTML

**لا يتم تنفيذ هذا التعديل من داخل Supabase. هذا تعديل ملف المالك فقط.**

### ابحث عن الكتلة التالية داخل `RW_LoyaltyMain.render()`.

**Current anchor:** منطقة `loadPrograms` داخل Loyalty module، بعد `safeHTML(...)` مباشرة. في النسخة الحالية الناتجة من Commit `716ebf86...` يقع هذا السطر عند نحو **2064**.

**ابحث بالنص الكامل التالي، واحذف الأسطر الأربعة كاملة كما هي، من أول `loadPrograms()` إلى آخر `subscribeRealtime();` :**

```javascript
loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
renderConfig();
subscribeRealtime();
```

**واستبدل الأسطر الأربعة كاملة بالكتلة التالية:**

```javascript
loadPrograms().then(function(){
    renderProgramSummary();
    renderConfig();
}).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
subscribeRealtime();
```

### لا تعدّل في نفس العملية

- Navigation Loyalty الموجود بالفعل.
- `'loyalty': 'customers'` الموجود بالفعل.
- Routing `if (view === 'loyalty') ...` الموجود بالفعل.
- `RW_LoyaltyMain` بالكامل؛ لا يوجد داعٍ لاستبداله.
- `earnSelected()`؛ فهو مقصود أن يرفض Earn يدويًا بدون Order ID.

---

## 5. CURRENT PRODUCTION — LOYALTY BACKEND

Supabase project:

`fiilmooggumokxanwiyx`

Name:
`SMART ERP`

Region:
`eu-west-1`

DB:
PostgreSQL 17.6.1.121

Status:
`ACTIVE_HEALTHY`

### Edge Function

`loyalty-engine`

Current deployed version:
`1`

`verify_jwt=true`

The function:

1. validates JWT;
2. resolves authenticated user;
3. resolves `company_id` from `users.auth_id`;
4. enforces active user;
5. calls `loyalty_engine_atomic`.

### Current RPC

```text
loyalty_engine_atomic(uuid,text,text,jsonb,text)
```

`SECURITY DEFINER=true`

Direct execute privilege removed from `PUBLIC`, `anon`, `authenticated`; retained for trusted server path.

---

## 6. DATABASE MODEL VERIFIED

### Loyalty Programs

`loyalty_programs`

- `company_id`
- `program_code`
- `status`
- earn/redeem rules
- expiry
- approval metadata
- unique `(company_id, program_code)`

### Loyalty Rewards

`loyalty_rewards`

- `company_id`
- `program_id`
- `reward_code`
- reward type
- points cost
- reward value
- optional product
- active flag
- unique `(company_id, program_id, reward_code)`

### Loyalty Accounts

`loyalty_accounts`

- `company_id`
- `customer_id`
- `points_balance`
- `lifetime_earned`
- `lifetime_redeemed`
- status
- unique `(company_id, customer_id)`

### Loyalty Transactions

`loyalty_transactions`

- `company_id`
- `account_id`
- `customer_id`
- `program_id`
- `reward_id`
- `order_id`
- `transaction_type`
- `points_delta`
- `balance_before`
- `balance_after`
- `reference_type`
- `reference_id`
- `operation_id`
- `reversal_of_transaction_id`
- `actor_email`
- `reason`
- `metadata`

### Compatibility cache

`customers.loyalty_points` remains compatibility cache only.

Loyalty source of truth:

```text
loyalty_accounts + loyalty_transactions
```

### Legacy table

`loyalty_points` is retained for compatibility/history and no longer exposes a permissive direct-user path.

---

## 7. PRODUCTION CHANGES EXECUTED THIS CYCLE

### A — Transaction idempotency

Created:

```sql
CREATE UNIQUE INDEX loyalty_transactions_company_operation_uidx
ON public.loyalty_transactions(company_id, operation_id)
WHERE operation_id IS NOT NULL;
```

Production read-back confirmed the index exists exactly in this form.

### B — Automatic EARN_ORDER trigger

Created function:

```text
trg_loyalty_on_invoiced_order()
```

Created trigger:

```text
trg_orders_loyalty_auto_earn
```

Definition verified in Production:

```text
AFTER INSERT OR UPDATE OF order_status
DEFERRABLE INITIALLY DEFERRED
```

The operation identity is deterministic:

```text
AUTO:EARN_ORDER:<company_id>:<order_id>
```

This prevents double earning for the same invoice lifecycle operation.

### C — Audit

Verified active audit triggers:

```text
trg_audit_loyalty_accounts
trg_audit_loyalty_programs
trg_audit_loyalty_rewards
trg_audit_loyalty_transactions
```

All call:

```text
fn_audit_trigger()
```

### D — No direct table path

Production role grants were checked. No `anon/authenticated` direct table privileges were returned for the Loyalty tables.

---

## 8. E2E PRODUCTION TRANSACTION TESTS

كل الاختبارات العملية الحساسة تمت داخل Transactions مؤقتة مع `ROLLBACK`.

### Test 1 — Automatic earning from invoiced order

تم إنشاء مؤقتًا:

- Customer داخل Company 1.
- Order بحالة `Invoiced`.
- Order detail للصنف `1001` بكمية `15` وسعر `10`.
- Loyalty program Active: كل `10` جنيه = `1` نقطة.

بعد `SET CONSTRAINTS ALL IMMEDIATE` ظهر:

```text
transaction_type = EARN
points_delta = 15
balance_before = 0
balance_after = 15
```

والـoperation_id:

```text
AUTO:EARN_ORDER:00000000-0000-0000-0000-000000000001:<order_id>
```

**النتيجة: PASS**

### Test 2 — Full transaction cycle

اختُبرت داخل Transaction مؤقتة:

```text
SAVE_PROGRAM
LIST_PROGRAMS
CREATE ORDER + DETAILS
AUTO EARN
SAVE_REWARD
DUPLICATE EARN
REDEEM
REVERSE
GET_ACCOUNT
```

النتيجة النهائية داخل الاختبار:

```text
points_balance = 15
lifetime_earned = 15
lifetime_redeemed = 10
```

**النتيجة: PASS**

تم Rollback كامل بعد الاختبار.

### Test 3 — Persistence check

بعد الاختبارات تم التحقق من Production counts:

```text
loyalty_programs = 0
loyalty_rewards = 0
loyalty_accounts = 0
loyalty_transactions = 0
loyalty_points = 0
```

**النتيجة: PASS — لا بيانات E2E متروكة في Production.**

---

## 9. WHAT FAILED DURING EXECUTION

### Failure A — Old report state was stale

Report189 كان يشير إلى Commit أقدم ويقول إن Mother UI لا تحتوي Loyalty. الواقع الحالي يثبت أن Loyalty UI موجودة بالفعل داخل `main.html` في Commit `716ebf...`.

**التقييم:** التقرير Historical clue فقط، وليس Current Truth.

### Failure B — Initial loyalty engine replacement incident

في دورة سابقة موثقة في Report189 حدث استبدال ناقص لمحرك Loyalty. تم اكتشافه من Production read-back وإعادة تعريف المحرك الكامل.

**التقييم:** لا نعتبر النسخ التاريخية مصدر الحالة الحالية.

### Failure C — `main.html` Rewards grid stuck on loading

السبب الجذري هو async render ordering، وليس فقد البنية الخلفية:

```text
renderConfig()
    ↓
loadPrograms() later
    ↓
currentPrograms updated
    ↓
renderProgramSummary() only
    ↓
renderConfig() not rerun
```

**الإصلاح الموصى به:** إعادة `renderConfig()` بعد نجاح `loadPrograms()`.

### Failure D — Empty commit residue

تم إنشاء Commit فارغ بالخطأ:

`11b99cab424496b9691e5ad92b36bd83ed7c2664`

GitHub أثبت:

```text
diff = null
files = null
```

**التقييم:** لا تغيير في Source file، لكنه يجب تسجيله وعدم اعتباره Source modification.

---

## 10. WHAT WAS NOT CHANGED

بسبب مبدأ عدم العبث بما ثبت سلامته:

- لا تعديل على Sales Targets.
- لا إعادة بناء Loyalty tables.
- لا إنشاء RPC dashboard غير مستخدم.
- لا إضافة Edge Function ثانية للولاء.
- لا تكرار Loyalty navigation.
- لا تكرار permission map.
- لا تعديل على `earnSelected()` اليدوي.
- لا تعديل على العمليات المخزنية.
- لا تعديل على Order/RunSheet business flow إلا نقطة auto-earn الضرورية والمثبتة.

---

## 11. NEXT OPEN POINT

بعد تطبيق Patch الواجهة وإعادة النشر وإجراء Browser E2E:

### النقطة التالية الدقيقة

```text
RETURN → LOYALTY REVERSAL POLICY
```

المطلوب قبل أي تنفيذ:

1. مراجعة تاريخ Return business contract.
2. تحديد متى يعود Earn السابق، ومتى يكون Reverse، ومتى يكون Sync/Adjustment.
3. ربط ذلك مع `order_details.qty_returned` وOrder financial state.
4. عدم اختراع خصم/مديونية نقاط بدون عقد تجاري مثبت.
5. تصميم العملية كـidempotent transaction عبر `loyalty_engine_atomic`.
6. اختبارها في Transaction مؤقتة.
7. نشرها فقط بعد إثبات Production contract.

**لا يبدأ هذا الجزء كـpatch مباشر قبل إعادة بناء عقد المرتجع تاريخيًا.**

---

## 12. PRE-SWEEP SELF-AUDIT

### Business Understanding

**Confirmed:** Loyalty هو customer transaction subsystem مرتبط بفواتير البيع والـorders، مع برامج ومكافآت وحسابات وسجل معاملات.

### Architecture Understanding

**Confirmed:** Edge capability → `loyalty_engine_atomic` → Loyalty tables.

### Database Understanding

**Confirmed:** الجداول والعلاقات والقيود الأساسية قرئت من Production مباشرة.

### Historical Understanding

**Confirmed enough for current closure:** تقرير 189 وCommit Loyalty السابق استُخدما كـsearch clues ثم تمت إعادة مطابقة الحالة الحالية.

### Production Understanding

**Confirmed:** RPC + Edge + indexes + triggers + grants + test transactions.

### Current Source Understanding

**Confirmed:** current mother blob `dd5516...` تمت قراءته إلى EOF، وLoyalty module موجود.

### Execution Confidence

**Backend:** High / Production verified.  
**Mother UI:** Exact patch identified but not yet merged by owner.  
**Browser E2E:** Open.

### Unknowns

لا يوجد Unknown مؤثر في سبب `جاري التحميل` الحالي.

### Conflicts

وجد تعارض بين Report189 وحالة Git الحالية؛ تم تصنيفه STALE report.

### Unverified claims

لم يتم اعتبار Browser UI pass لأن Browser Console/Network لم تكن متاحة داخل هذه الجلسة.

---

## 13. FINAL SELF-AUDIT

### What I Proved

- Production Loyalty RPC موجود.
- Edge gateway موجود ومؤمّن JWT.
- Tenant identity مأخوذة من authenticated user.
- Loyalty CRUD/read/transaction operations موجودة.
- Idempotency index موجود.
- Automatic EARN on invoiced order موجود ومجرب.
- EARN/REDEEM/REVERSE path مجرب.
- Audit triggers موجودة.
- لا توجد بيانات E2E متروكة.
- Mother Loyalty UI موجودة.
- سبب Loading state مثبت بدقة.

### What I Did Not Prove

- Browser E2E بعد Patch المالك.
- Console بعد إعادة النشر.
- Network trace من المتصفح.
- Return→Loyalty reversal contract.

### What I Fixed

- Production auto earning integration.
- Production operation identity/idempotency.
- Production security path for Loyalty.
- Production auditability verification.

### What I Initially Missed

الواجهة الحالية كانت موجودة بالفعل في Commit حديث، لكن `renderConfig()` يعتمد على `currentPrograms` قبل اكتمال `loadPrograms()`.

### What Could Still Be Wrong

أي اختلاف يظهر بعد Browser publish سيكون محصورًا مبدئيًا في:

- تطبيق Patch في `main.html`.
- Cache/Service Worker.
- Published artifact mismatch.
- Browser console/runtime integration.

### Final Closure Status

```text
LOYALTY TRANSACTION ENGINE — PRODUCTION BACKEND = 100% CLOSED
LOYALTY MOTHER UI = OPEN / ONE SURGICAL PATCH
BROWSER E2E = OPEN
```

ولا يجوز كتابة `LOYALTY = 100% CLOSED` قبل Browser E2E.

---

# 14. INSTRUCTIONS TO THE NEXT CTO / ASSISTANT

ابدأ دائمًا من **الحقيقة الحالية، لا من التقرير**.

اتبع التسلسل:

```text
1. اقرأ CURRENT_STATE.md.
2. اقرأ forensic_main_assembly.yml.
3. استخرج منه فقط مكان Source of Truth.
4. احصل على CURRENT GIT HEAD.
5. احصل على DIRECT PARENT.
6. احصل على CURRENT BLOB SHA.
7. افتح CURRENT SOURCE نفسه، وليس fragment تاريخيًا.
8. اقرأ الملف المطلوب كاملًا حتى EOF إذا طُلب ذلك.
9. خذ anchors من النسخة الحالية نفسها.
10. افحص CURRENT PRODUCTION.
11. افحص CURRENT DATABASE schema.
12. افحص CURRENT DEPLOYMENTS.
13. افحص RUNTIME evidence.
14. صنّف كل claim: CURRENT / STALE / UNKNOWN / CONFLICT.
15. لا تعيد إصلاح أي شيء ثابت الإصلاح.
16. أغلق Closure Unit واحدًا فقط.
17. قبل التنفيذ: حدد Historical Contract → Current Contract → Target Contract.
18. نفذ التعديل في الطبقة المالكة له.
19. اختبر داخل Transaction آمنة عندما يمكن ذلك.
20. تحقق من Production بعد التغيير.
21. حدّث CURRENT_STATE.md فورًا.
22. اكتب التقرير العربي الكامل.
23. حدد Next Exact Task.
24. لا تخلط Next Task مع Closure الحالي.

### في حال فتح Mother File

لا تستخدم سطرًا من Report189 كـanchor.

افتح:

```text
papamohammed77-glitch/erp-frontend/companies/company-1/main.html
```

خذ:

```text
CURRENT COMMIT
CURRENT BLOB
CURRENT LINE
CURRENT FUNCTION
CURRENT END OF BLOCK
```

ثم اطلب من المالك تعديل العنصر كاملًا من أوله إلى آخر سطر واضح، لا جزءًا مقطوعًا.

### في حال Production

لا تنشئ جدولًا أو Edge Function جديدة لمجرد أن تقريرًا قديمًا ذكر احتمال الحاجة إليها.

أثبت أولًا أن القدرة غير موجودة في Production الحالية.

### في حال Unknown

```text
UNKNOWN
→ PRIMARY SOURCE SEARCH
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ RUNTIME
→ HISTORY
→ RESOLVE
```

### القاعدة النهائية

```text
REPORT IS A CLUE.
CURRENT PRODUCTION IS EVIDENCE.
CURRENT SOURCE IS EVIDENCE.
CURRENT GIT IS EVIDENCE.
CURRENT DATABASE IS EVIDENCE.
CURRENT DEPLOYMENT IS EVIDENCE.
BROWSER E2E IS REQUIRED FOR UI CLOSURE.
```

**ولا تُعلن Closure قبل إثبات كل طبقة المطلوبة.**
