# تقرير 386 — التحقيق الجنائي: فساد رأس main.html بعد إدراج عمود المندوب
## RAWAEA ERP — الأذونات المخزنية — DirectSale / DirectReturn — 2026-10-01

## 1. نقطة الاستئناف المعتمدة

تم البدء من آخر حالة مثبتة في:

- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS
- CURRENT_STATE.md حتى آخر Append
- Reports 382 → 385
- CURRENT GIT للمستودع الصحيح:
  `papamohammed77-glitch/erp-frontend`
- الملف المطلوب:
  `companies/company-1/main.html`
- CURRENT HEAD:
  `e2e9d5cdb559bd014dcc85b12fc9b89610b466d7`
- HEAD parent:
  `e373c7ad2d66d72b2919a8f153693da36ab9b7bb`
- Current main.html blob:
  `2a4b0bec5a402b1e7490a8e53b3452cc8a7d9209`

المراسلات والتقارير السابقة تعاملت معها كأدلة تاريخية. الحالة الحالية تم إثباتها مباشرة من Git وCurrent Source وProduction Database.

---

## 2. النتيجة التنفيذية

الـBusiness Capability المطلوب في Report382–385 كان قد اكتمل في المصدر الصحيح: عمود **المندوب** موجود بالفعل، ويُبنى من:

`stock_vouchers.custodian_user_id → public.users.id → name/email`

ولكن ظهر بعد ذلك عيب جديد في Current HEAD لم يكن موجودًا في Report385:

**Commit `e373c7ad2d66d72b2919a8f153693da36ab9b7bb` أدخل سطر `return ...` الخاص بإخراج صف الجدول داخل عنصر `<meta charset="UTF-8">` في رأس الصفحة.**

هذا العيب أحدث فسادًا مباشرًا في عنصر HTML في أعلى الملف، ولا يمثل تعديلًا وظيفيًا صحيحًا على `loadVouchers()`.

**هذا هو العنصر المعيب الحالي الوحيد الذي يجب حذفه واستبداله جراحيًا.**

لا حاجة لإعادة تنفيذ PATCH 1→4 من Reports 384/385 على النسخة الحالية؛ تلك الجراحة أصبحت موجودة أصلًا في Current Source.

---

## 3. سلسلة Git التي أثبتت السبب

### التغيير الصحيح السابق

`5edf6d448203b8b431086ae762df1b35699366bf`

رسالة Commit:

`Update voucher table to include custodian column`

هذا الـcommit أضاف فعليًا:

- Header: المندوب
- colspan 8→9
- lookup للمندوب
- projection إلى `_custodian_name`
- rendering لاسم المندوب

### بعده

`d5b8319b81c2236da66c25dcfc32a8f18182f249`

كان تعديلًا على ملف forensic extract فقط، وليس `main.html`.

### ثم العيب الحالي

`e373c7ad2d66d72b2919a8f153693da36ab9b77`

رسالة Commit:

`Implement dynamic row rendering for vouchers`

لكن الـdiff الفعلي يثبت أنه لم يعدل row renderer في مكانه الصحيح؛ بل نفّذ:

`<meta charset="UTF-8">`

إلى:

`<meta charset="UTF-8">return '...voucher row...';`

وأضاف سطرًا فارغًا.

الـdiff الرسمي للـcommit يثبت أن الملف الوحيد المعدل هو:

`companies/company-1/main.html`

والتغيير هو هذا الموضع فقط.

### Current HEAD

`e2e9d5cdb559bd014dcc85b12fc9b89610b466d7`

هذا الـcommit أضاف `_forensic_current_main_extract.md` فقط، ولم يعدل `main.html`.

إذن فساد `main.html` في Current HEAD مصدره المباشر هو `e373c7a...`.

---

# 4. Current Source forensic proof

Current blob:

`2a4b0bec5a402b1e7490a8e53b3452cc8a7d9209`

عدد الأسطر:

`32348`

السطر 5 الحالي كاملًا هو:

```html
  <meta charset="UTF-8">return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3">' + esc(v._custodian_name||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

هذا ليس HTML صالحًا كتعريف نظيف لعنصر `meta`، وهو ليس المكان القانوني لأي JavaScript row renderer.

---

# 5. العنصر المعيب المطلوب حذفه بالكامل

## الملف

`companies/company-1/main.html`

## الموضع

**السطر 5**

## ابحث حرفيًا عن هذا السطر كاملًا

```html
  <meta charset="UTF-8">return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3">' + esc(v._custodian_name||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

### احذفه بالكامل.

## البديل المصحح الكامل

ضع مكانه:

```html
  <meta charset="UTF-8">
```

هذه هي الجراحة المطلوبة على Current HEAD.

**لا تطبق أي PATCH آخر من Reports 382/383/384/385 إذا كان الملف الحالي هو Current HEAD نفسه، لأن عمود المندوب موجود بالفعل في الجزء الصحيح من الكود.**

---

# 6. لماذا هذا هو الإصلاح الصحيح

الـrow renderer الصحيح موجود أصلًا داخل:

`function _applyVouchers()`

والسطر الحالي الصحيح في موضعه التشغيلي هو:

```js
return '<tr class="hover:bg-gray-50"><td class="p-3 font-bold text-indigo-700">' + (v.voucher_code||'') + sourceIndicator + '</td><td class="p-3">' + (v.type||'') + '</td><td class="p-3">' + (v.voucher_date||'') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs ' + statusBadge + '">' + (v.status||'') + '</span></td><td class="p-3">' + (v.reference||'-') + '</td><td class="p-3">' + (v.from_id||'-') + '</td><td class="p-3">' + (v.to_id||'-') + '</td><td class="p-3">' + esc(v._custodian_name||'-') + '</td><td class="p-3 text-center">' + actions + '</td></tr>';
```

لذلك لا يجوز نقل هذا السطر أو نسخه مرة أخرى.

الـCurrent Source يحتوي بالفعل:

- `<th class="p-3">المندوب</th>`
- `colspan="9"`
- `custodian_user_id`
- `window._vouchersRepMap`
- `v._custodian_name`
- company-scoped users lookup
- escaped representative output

أي أن **Business Contract الأصلي محفوظ**، والعيب الحالي هو فقط وجود نسخة مكررة في المكان الخطأ.

---

# 7. تحقق عدم وجود عيب آخر في الوحدة

Current Source أثبت:

- `loadVouchers` موجودة مرة واحدة.
- `_applyVouchers` موجودة مرة واحدة.
- Header المندوب موجود مرة واحدة.
- `custodian_user_id` مستخدم في المسار الصحيح.
- row renderer الصحيح موجود داخل `_applyVouchers()`.

عدد ظهور بداية row renderer الحالية:

**2**

والسبب واضح:

1. نسخة خاطئة في line 5.
2. النسخة الصحيحة في `_applyVouchers()`.

بعد حذف السطر الملوث يصبح:

**1**

وهذا هو العدد الصحيح.

---

# 8. Production Database — إعادة التحقق

Supabase:

`SMART ERP / fiilmooggumokxanwiyx`

الحالة الحالية:

- إجمالي `stock_vouchers` = **0**
- DirectSale = **0**
- DirectReturn = **0**
- Active Direct Sales Representatives = **3**

المندوبون الحاليون الموثقون:

- `van-sales2@rawaea.com`
- `vansales@rawaea.com`
- `vansales2@rawaea.com`

وكلهم:

`permissions = ["van-sales"]`

العقد الرقابي للمندوب:

`stock_vouchers.custodian_user_id → public.users.id`

لم يتم إجراء أي mutation في Production لهذه الجراحة.

---

# 9. Production Fixture / Projection Test

تم استخدام fixture SQL قراءة فقط، دون INSERT أو UPDATE أو DELETE:

| النوع | custodian | النتيجة |
|---|---|---|
| DirectSale | مندوب مبيعات بيع مباشر | PASS |
| DirectReturn | van-sales2 | PASS |
| Transfer | null | - |
| SupplierReturn | null | - |

النتيجة تثبت أن projection الحالي صحيح.

### تنظيف البيانات

لا توجد بيانات اختبار دائمة أصلًا:

- QA voucher rows = 0
- DirectSale rows = 0
- DirectReturn rows = 0

إذن:

**Production cleanup required = 0**

---

# 10. التأثير على Workflow والمخزون والمحاسبة

الجراحة الحالية تقع في Header HTML فقط.

لا يوجد:

- INSERT
- UPDATE
- DELETE
- RPC mutation
- Edge Function
- stock movement
- custody posting
- ledger posting
- journal posting
- treasury mutation
- workflow transition

إذن التأثير المباشر:

| المجال | التأثير |
|---|---:|
| رصيد الفرع | 0 |
| رصيد السيارة | 0 |
| العهدة | 0 |
| inventory_log | 0 |
| driver_ledger | 0 |
| general journal | 0 |
| customer ledger | 0 |
| supplier ledger | 0 |
| treasury | 0 |
| workflow | 0 |

وهذا متعمد؛ لأن المشكلة UI/HTML corruption فقط.

---

# 11. DirectSale / DirectReturn contract

لا يتم فتح أو تعديل العقد الذي ثبت في Report382:

### DirectSale

`CREATE → SEND → Branch stock decrease → Mobile stock increase → Custody debit`

### DirectReturn

`CREATE → SEND → Mobile stock decrease`

ثم:

`RECEIVE → Branch stock increase → Custody credit`

والـDirectReturn RECEIVE الحالي في Production ما زال:

`InventoryIncrease`

ولا توجد حاجة لإعادة إصلاحه.

---

# 12. لماذا لم يتم إنشاء Edge Function أو RPC

المشكلة ليست Backend.

المشكلة ليست DB schema.

المشكلة ليست authorization.

المشكلة ليست workflow.

إذن إنشاء بنية Production جديدة سيكون تغييرًا خارج السبب الجذري.

القرار:

- Edge Functions جديدة = **لا**
- RPC جديد = **لا**
- تعديل RPC = **لا**
- تعديل Schema = **لا**
- تعديل RLS = **لا**
- تعديل `vouchers.html` = **لا**
- تعديل `van-sales.html` = **لا**

---

# 13. Owner Surgical Change

## المطلوب من المالك فقط

### ابحث

في:

`companies/company-1/main.html`

عن:

`  <meta charset="UTF-8">return '<tr class="hover:bg-gray-50">...`

ويجب أن يكون هذا العنصر **في السطر 5**.

### احذف

السطر كاملًا.

### استبدل

بـ:

```html
  <meta charset="UTF-8">
```

### لا تلمس

- `loadVouchers()` كاملة
- `_applyVouchers()` كاملة
- `_viewVoucherDetails()`
- `_sendVoucher()`
- `_receiveVoucher()`
- `_openNewVoucherModal()`
- `warehouse/vouchers.html`
- أي RPC
- أي Edge Function
- أي جدول

---

# 14. Static verification after owner patch

بعد الاستبدال يجب أن تصبح بداية الملف:

```html
<!DOCTYPE html>
<!-- 2026-09-24 22:00 UTC -->
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
```

ويجب ألا يظهر row renderer في `head`.

ويجب أن يبقى row renderer مرة واحدة فقط داخل:

`function _applyVouchers()`

---

# 15. Current Source validation

تم التحقق قبل الإصلاح من:

- Current blob = `2a4b0bec5a402b1e7490a8e53b3452cc8a7d9209`
- Current lines = 32348
- Header المندوب = موجود
- `custodian_user_id` = موجود
- `_vouchersRepMap` = موجود
- `v._custodian_name` = موجود
- company-scoped users lookup = موجود
- loadVouchers = 1
- _applyVouchers = 1
- misplaced row renderer = 1
- correctly placed row renderer = 1

بعد حذف line 5:

- misplaced row renderer = 0
- correctly placed row renderer = 1
- header remains
- mapping remains
- workflow remains untouched

---

# 16. Browser / Deployment evidence

لم يتم تشغيل Browser E2E في هذه الدورة بعد إصلاح المالك، لأن:

1. `main.html` ملف Owner-side لا يتم تعديله تلقائيًا.
2. Current HEAD لم يتم استبداله من جانبي.
3. أداة Workflow Dispatch غير متاحة في جلسة التنفيذ الحالية.
4. الـcommit الحالي الذي أضاف corruption لم يكن له PR-triggered workflow run متاح عبر الـconnector.

إذن:

**Browser E2E = OPEN**

**Served Production artifact verification = OPEN**

ولا يجوز تسجيلهما PASS قبل النشر الفعلي.

---

# 17. أهم فرق عن Reports 384/385

Reports 384/385 كانت صحيحة تجاه الحالة التي كانت موجودة وقتها.

لكن Current Git تغيّر بعد ذلك.

لذلك:

**لا نعيد الجراحة الأربع السابقة.**

Current Source يحتويها بالفعل.

المشكلة الحالية التي لم تكن موجودة في Report385 هي:

**Corrupted line 5 introduced by e373c7a.**

وهذه هي الجراحة الوحيدة المطلوبة الآن.

---

# 18. لا توجد حاجة لتغيير أي Production structure

Current Production:

- schema contract صحيح.
- custodian FK صحيح.
- representatives موجودون.
- RLS contract قائم.
- operational voucher application قائم.
- DirectReturn stock contract قائم.
- accounting/custody contract قائم.

لا توجد فجوة Backend مرتبطة بالمشكلة الحالية.

---

# 19. SELF AUDIT

## مثبت

- المستودع الصحيح.
- الملف الصحيح.
- Current HEAD.
- HEAD parent.
- commit الذي أدخل العيب.
- diff الفعلي.
- current blob.
- exact defective line.
- correct voucher column implementation still present.
- Production representative records.
- Production voucher counts.
- custodian mapping.
- zero persistent test residue.
- no required Production mutation.

## غير مثبت

- Browser E2E بعد الإصلاح.
- Served artifact بعد النشر.

## لم يتم تغييره

- main.html
- vouchers.html
- van-sales.html
- database
- RPC
- Edge
- RLS
- workflow
- accounting
- custody

---

# 20. قرار الإغلاق الحالي

**ROOT CAUSE = PROVEN**

السبب الجذري:

`e373c7a` أدخل row-renderer داخل `meta charset`.

**CURRENT SOURCE DEFECT = PROVEN**

**OWNER SURGICAL PATCH = READY**

**PRODUCTION CHANGE = NONE REQUIRED**

**DATABASE CHANGE = NONE REQUIRED**

**DATA FIXTURE RESIDUE = NONE**

**BUSINESS CONTRACT = PRESERVED**

**BROWSER E2E = OPEN**

**DEPLOYMENT VERIFICATION = OPEN**

---

# 21. نقطة الاستكمال التالية

### يبدأ المساعد القادم من:

`erp-frontend/companies/company-1/main.html`

### ثم:

1. Verify current blob.
2. Verify line 5.
3. If exact corrupted line exists, apply only the replacement in Section 5.
4. Full source syntax gate.
5. Verify representative projection remains exactly once in `_applyVouchers()`.
6. Publish.
7. Verify served artifact.
8. Run rendered Browser E2E.
9. Test:
   - DirectSale → representative name
   - DirectReturn → representative name
   - Transfer → -
   - SupplierReturn → -
10. Close UI capability only after runtime evidence.

### لا تعيد فتح:

- DirectReturn RECEIVE direction fix.
- Master Assignment.
- custodian_user_id contract.
- owner wildcard.
- voucher operational workflow.
- historical Production E2E الذي ثبت إغلاقه.

---

# 22. إرشاد الحقيقة للمساعد التالي

ابدأ دائمًا من:

**CURRENT GIT**

ثم:

**CURRENT SOURCE**

ثم:

**CURRENT PRODUCTION**

ثم:

**CURRENT DATABASE**

ثم:

**CURRENT DEPLOYMENT EVIDENCE**

بعد ذلك فقط استخدم التقارير لتفسير التاريخ.

في هذه القضية تحديدًا:

1. لا تبحث عن عمود المندوب من جديد؛ هو موجود بالفعل.
2. لا تعيد Reports 384/385.
3. افحص أعلى الملف أولًا لأن آخر commit هو الذي غيّر Header فقط.
4. إذا وجدت row renderer داخل `<meta charset>` فهذا هو العيب، وليس row renderer داخل `_applyVouchers()`.
5. احذف النسخة الملوثة فقط.
6. اترك النسخة الصحيحة داخل `_applyVouchers()`.
7. لا تلمس Backend لأن المشكلة presentation-layer corruption فقط.

# END OF REPORT 386
