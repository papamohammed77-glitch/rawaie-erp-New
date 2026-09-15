# تقرير 190 — إغلاق Forensic لمحرك معاملات الولاء

**التاريخ:** 2026-09-15 (UTC)  
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

### Functional Loyalty commit

`716ebf86b3c989a461cbf86151b37fcd0849b0c3`

Message:
`Add loyalty management features to main.html`

Direct parent:
`13425725f48c7decba3403ee631d8e0f2d757b0f`

Mother file blob at that functional commit:
`dd5516ea75d75e01a95d4782ec92603ecf427d2e`

### Latest repository metadata commit observed

`11b99cab424496b9691e5ad92b36bd83ed7c2664`

This commit was created accidentally during execution and GitHub read-back proves:

```text
diff = null
files = null
```

Therefore it did **not** alter `companies/company-1/main.html`.

### Current source verification

تم فتح الـmother file من Git blob المباشر ومراجعة المحتوى حتى EOF. النهاية المثبتة:

```html
</script>
</body>
</html>
```

وبذلك لا يوجد اعتماد على fragment تاريخي لاستخراج الـLoyalty code.

---

## 3. CURRENT MOTHER UI FORENSIC RESULT

الـCommit `716ebf...` أضاف Loyalty بالفعل.

### Existing navigation

منطقة navigation الحالية حول السطر `1144` تحتوي Loyalty entry بالفعل.

### Existing permission map

يحتوي routing/permission map الحالي على:

```javascript
'loyalty': 'customers',
```

### Existing routing

يحتوي dispatcher الحالي على:

```javascript
if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }
```

### Existing Loyalty module

`RW_LoyaltyMain` موجود بالفعل ويستدعي:

```javascript
RW_SUPABASE_URL + '/functions/v1/loyalty-engine'
```

### Root cause of loading state

الترتيب الحالي داخل `RW_LoyaltyMain.render()`:

```javascript
loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
renderConfig();
subscribeRealtime();
```

بينما `renderConfig()` يحتاج `currentPrograms` لتحديد البرنامج Active ثم تحميل المكافآت.

إذن المشكلة هي asynchronous ordering:

```text
renderConfig()
      ↓
currentPrograms = []
      ↓
UI = جاري التحميل...
      ↓
loadPrograms() completes
      ↓
currentPrograms populated
      ↓
renderProgramSummary() only
      ↓
renderConfig() never reruns
```

---

## 4. EXACT OWNER SURGICAL PATCH — MAIN.HTML

**هذا هو التعديل الوحيد المطلوب من المالك حاليًا. لا يعدّل Supabase هذا الجزء.**

### Current anchor

داخل `RW_LoyaltyMain.render()`، المنطقة الحالية حول **السطر 2064**.

### احذف هذا المقطع كاملًا

```javascript
loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
renderConfig();
subscribeRealtime();
```

آخر سطر في العنصر المطلوب للحذف هو بالضبط:

```javascript
subscribeRealtime();
```

### واستبدله بهذا المقطع كاملًا

```javascript
loadPrograms().then(function(){
    renderProgramSummary();
    renderConfig();
}).catch(function(e){ showToast(e.message,'error'); });
loadCustomerOptions();
subscribeRealtime();
```

### لا تحذف أو تعدّل

```javascript
window.RW_SalesTargetsMain = RW_SalesTargetsMain;
```

ولا تعدّل Navigation أو permission map أو routing أو `RW_LoyaltyMain` كاملًا، لأنها موجودة بالفعل في Current Source.

ولا تعدّل `earnSelected()`؛ فهو متعمد ألا ينشئ Earn يدويًا بدون Order ID.

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

### Core RPC

```text
loyalty_engine_atomic(uuid,text,text,jsonb,text)
```

`SECURITY DEFINER=true`

Direct execute for `PUBLIC`, `anon`, `authenticated` is removed; trusted server path remains.

---

## 6. DATABASE MODEL VERIFIED

`loyalty_programs`:
- company-scoped program master
- unique `(company_id, program_code)`
- Draft/Active/Inactive status
- earn/redeem rules

`loyalty_rewards`:
- company + program scoped
- unique `(company_id, program_id, reward_code)`
- discount/credit/free shipping/free product
- point cost and reward value

`loyalty_accounts`:
- company + customer scoped
- unique `(company_id, customer_id)`
- points balance/lifetime totals/status

`loyalty_transactions`:
- company/account/customer/order/program/reward linkage
- EARN/SYNC/REDEEM/ADJUST/EXPIRE/REVERSE
- before/after balance
- `operation_id`
- reversal relation
- actor/reason/metadata

`customers.loyalty_points` remains compatibility cache only.

---

## 7. PRODUCTION CHANGES EXECUTED

### A — Idempotency

Production now contains:

```sql
CREATE UNIQUE INDEX loyalty_transactions_company_operation_uidx
ON public.loyalty_transactions(company_id, operation_id)
WHERE operation_id IS NOT NULL;
```

Read-back confirmed the index.

### B — Automatic invoice earning

Created:

```text
trg_loyalty_on_invoiced_order()
trg_orders_loyalty_auto_earn
```

Trigger definition verified:

```text
AFTER INSERT OR UPDATE OF order_status
DEFERRABLE INITIALLY DEFERRED
```

Deterministic operation identity:

```text
AUTO:EARN_ORDER:<company_id>:<order_id>
```

### C — Audit

Verified active triggers:

```text
trg_audit_loyalty_accounts
trg_audit_loyalty_programs
trg_audit_loyalty_rewards
trg_audit_loyalty_transactions
```

They execute `fn_audit_trigger()`.

### D — Direct table access

Production grants returned only trusted server access for the Loyalty tables in the checked roles.

---

## 8. E2E DATABASE TESTS

كل الاختبارات الحساسة تمت داخل Transaction مؤقتة ثم `ROLLBACK`.

### Test 1 — Auto EARN

Order مفوتر + detail بكمية 15 وسعر 10 + برنامج Active بمعدل 10 جنيه/نقطة.

نتيجة Production transaction:

```text
EARN
15 points
balance 0 → 15
```

**PASS**

### Test 2 — Full Loyalty transaction cycle

```text
SAVE_PROGRAM
LIST_PROGRAMS
AUTO EARN
SAVE_REWARD
DUPLICATE EARN
REDEEM
REVERSE
GET_ACCOUNT
```

نتيجة الحساب داخل الاختبار:

```text
points_balance = 15
lifetime_earned = 15
lifetime_redeemed = 10
```

**PASS**

### Test 3 — Data hygiene

بعد rollback:

```text
loyalty_programs = 0
loyalty_rewards = 0
loyalty_accounts = 0
loyalty_transactions = 0
loyalty_points = 0
```

**PASS — لا بيانات اختبار متبقية.**

---

## 9. EXECUTION INCIDENTS / FAILED ATTEMPTS

### Incident 1 — stale report

Report189 كان مبنيًا على Commit أقدم وكان يقول إن Mother UI لا تحتوي Loyalty. Current Git أثبت العكس.

Classification:
`STALE`

### Incident 2 — historical incomplete RPC replacement

موثق في Report189؛ تم فحص Production وإعادة تعريف Loyalty engine الكامل قبل مواصلة العمل.

### Incident 3 — empty frontend commit

`11b99cab...` أنشئ بالخطأ أثناء التسجيل.

GitHub read-back:
`diff=null`, `files=null`.

التأثير على Source:
`NONE`.

### Runtime logs

محاولة جلب Edge runtime logs بواسطة الموصل الحالي فشلت على مستوى أداة الاتصال (`Resource not found: Supabase.get_logs`). لذلك **لم تستخدم هذه النتيجة لادعاء Runtime PASS**؛ الاعتماد في الإغلاق الحالي على deployment read-back + direct DB verification + transactional tests.

---

## 10. WHAT WAS NOT CHANGED

- Sales Targets لم تُعدّل.
- لم تتم إعادة بناء Loyalty schema من الصفر.
- لم تنشأ Edge Functions إضافية غير مطلوبة.
- لم تنشأ dashboard RPC غير مستهلكة.
- لم يتم تعديل العمليات المخزنية.
- لم يتم تعديل Return loyalty policy.
- لم يتم تعديل Mother File من داخل هذه الجلسة.

---

## 11. NEXT OPEN POINT

بعد تطبيق Patch المالك وإعادة النشر وإتمام Browser E2E:

```text
RETURN → LOYALTY REVERSAL POLICY
```

قبل أي Production change هناك يجب:

```text
Historical Return Contract
→ Current Return Flow
→ Order Detail / Runsheet Effects
→ Financial Effects
→ Loyalty Effect
→ Reversal/Sync Rule
→ Idempotency
→ Transaction Test
→ Production Verification
```

لا تُخترع مديونية أو خصم نقاط دون عقد تجاري مثبت.

---

## 12. PRE-SWEEP SELF-AUDIT

Business Understanding: **Confirmed**  
Architecture Understanding: **Confirmed**  
Database Understanding: **Confirmed from Production**  
Historical Understanding: **Sufficient for this closure; reports treated as clues**  
Production Understanding: **Confirmed**  
Current Source Understanding: **Confirmed, EOF verified**  
Execution Confidence: **Backend high; UI pending owner/browser**

Confirmed Facts:
- Loyalty engine exists.
- Loyalty Edge exists and requires JWT.
- Auto earning is deployed.
- Operation idempotency index is deployed.
- Audit triggers are active.
- Current Mother UI has the Loyalty module.
- Loading defect is caused by render ordering.

Unknowns / unverified:
- Browser Console/Network after owner patch.
- Runtime logs could not be obtained through the current connector path.
- Return→Loyalty policy remains unproven.

---

## 13. FINAL SELF-AUDIT

### What I Proved

- Current Git identity and parent for the Loyalty commit.
- Current Mother source reached EOF.
- Production Loyalty schema and RPC are present.
- Production Edge Function is deployed and JWT protected.
- Production idempotency is enforced.
- Invoice EARN is atomic and deferred.
- Full Loyalty transaction cycle works transactionally.
- Audit triggers are present.
- No E2E test data remains.
- Mother UI contains Loyalty and has one precise loading-order defect.

### What I Did Not Prove

- Browser E2E after owner patch.
- Browser Console/Network pass.
- Return→Loyalty business contract.
- Production runtime logs through the current connector because that connector path was unavailable.

### What I Fixed

Production:
- invoice-linked automatic EARN;
- transaction operation idempotency;
- trusted Loyalty execution boundary.

Documentation:
- current source/commit state;
- canonical migration source;
- current-state reconstruction;
- next exact closure point.

### Final Closure Status

```text
LOYALTY TRANSACTION ENGINE — PRODUCTION BACKEND = 100% CLOSED
LOYALTY DATABASE INTEGRITY = CLOSED
LOYALTY EDGE DEPLOYMENT = CLOSED
LOYALTY DB TRANSACTION E2E = PASS
LOYALTY MOTHER UI = OPEN / ONE OWNER PATCH
BROWSER E2E = OPEN
GLOBAL LOYALTY = NOT YET FULLY CLOSED
```

لا يجوز تحويل هذا إلى `LOYALTY = 100% CLOSED` قبل Browser E2E.

---

# 14. INSTRUCTIONS TO THE NEXT CTO / ASSISTANT

ابدأ من الحقيقة الحالية، لا من Report190.

```text
CURRENT_STATE.md
→ FORENSIC ASSEMBLY
→ CURRENT GIT HEAD
→ DIRECT PARENT
→ CURRENT MOTHER BLOB
→ FULL READ TO EOF
→ CURRENT SOURCE ANCHOR
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ RUNTIME EVIDENCE
→ CLASSIFY STALE/UNKNOWN/CONFLICT
→ CLOSE ONE UNIT
→ TEST
→ PRODUCTION VERIFY
→ UPDATE STATE
→ WRITE REPORT
→ NEXT EXACT TASK
```

### قواعد أساسية

1. لا ترث line anchor من تقرير قديم.
2. لا تصلح شيئًا ثبت أنه أصلح بالفعل.
3. لا تعتبر Commit = Deployment.
4. لا تعتبر Deployment = Runtime PASS.
5. لا تعتبر Runtime PASS = Full Closure.
6. لا تعتبر Browser UI صالحًا دون Browser E2E.
7. لا تنشئ Backend capability قبل إثبات غيابها.
8. لا تنقل business responsibility من طبقة إلى أخرى دون إثبات أين انتقلت.
9. عند ظهور Unknown، حوّله إلى Evidence task ولا تخمّن.
10. عند انتهاء Loyalty UI، انتقل إلى `RETURN → LOYALTY REVERSAL POLICY` وليس إلى إعادة بناء Loyalty من جديد.

### عند استئناف Mother File

ابحث عن السطر داخل `RW_LoyaltyMain.render()` الذي يبدأ بالنص الكامل:

```javascript
loadPrograms().then(function(){ renderProgramSummary(); }).catch(function(e){ showToast(e.message,'error'); });
```

والمقطع الذي ينتهي بـ:

```javascript
subscribeRealtime();
```

إذا كان موجودًا كما هو، نفّذ الـ4-line replacement المسجل في هذا التقرير فقط.

بعد النشر:

```text
open Loyalty
→ wait for LIST_PROGRAMS
→ verify config panel exits loading state
→ LIST_REWARDS
→ SAVE/READ program
→ open customer
→ verify account
→ verify realtime refresh
→ browser console = no error
→ browser network = expected loyalty-engine calls
→ Production counts/results = consistent
```

ثم أغلق Mother UI فقط إذا أثبتت الأدلة ذلك.
