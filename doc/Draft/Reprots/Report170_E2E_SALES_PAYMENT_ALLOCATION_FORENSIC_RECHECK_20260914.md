# تقرير 170 — التحقيق التنفيذي وإعادة التحقق الجنائي لـ E2E — Multiple / Partial Sales Payment Allocation

**التاريخ:** 14 سبتمبر 2026

> **النقطة الأهم:** الهدف التنفيذي في هذه الجلسة هو **اختبار E2E لملف النظام الأم الحالي**:
> `https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`
>
> وهذا الملف وحده هو Source of Truth للنظام الأم. مجلد `Current/PWA/main2` و`New-main` وملفات الـPatch التاريخية مرجع استدلالي فقط، وليست حالة حالية.

## 1. قاعدة الحقيقة المعتمدة

تم تجاهل التقارير السابقة كحالة حالية، واستخدامها كأدلة تاريخية فقط.

الحالة المعتمدة في هذه الجلسة هي:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

والقاعدة التنفيذية:

`REPORT != CURRENT STATE`

`COMMIT != DEPLOYMENT`

`DEPLOYMENT != RUNTIME SUCCESS`

`RUNTIME SUCCESS != PRODUCTION VERIFIED`

`PRODUCTION VERIFIED != FULLY CLOSED`

## 2. Git Forensic Reconciliation

### Frontend current HEAD

Repository:
`papamohammed77-glitch/erp-frontend`

Current HEAD:
`c379674711d6e67d5c2c01305ae8449dd3c0947e`

Message:
`Add real-time customer payment updates functionality`

Direct Parent:
`4eb99edff261ae350d21c277d51adcaf75d02def`

Parent message:
`Update main.html`

Current `main.html` blob:
`a41903730c302ddef82b91edfec4a4a3a400d76c`

### أهم نتيجة في الـDiff

الـHEAD الحالي لم يضف Payment Core جديدًا؛ التغيير كان إضافة Realtime Consumer داخل `main.html`.

لكن الـDiff أدخل:

1. `function _startCustomerPaymentRealtime()`.
2. استدعاء `_startCustomerPaymentRealtime()` داخل مسار `_loadDashboardData()`.

وتم التحقق من أن متغير:

`_customerPaymentRealtimeChannel`

مستخدم داخل الدالة، لكن لا توجد له declaration في `main.html` الحالي.

هذه ليست ملاحظة نظرية؛ هي فجوة Runtime حقيقية قابلة لإحداث `ReferenceError` عند استدعاء الدالة.

## 3. التحقق من وجود Patch الدفع داخل النظام الأم الحالي

تم فتح `main.html` الحالي وليس ملفًا تاريخيًا.

### PATCH A

`_renderReceipts()` موجود فعليًا في الملف الحالي ويعرض:

- تحصيل عميل.
- سند قبض عام.
- قائمة تحصيل العملاء.
- واجهة تخصيص الدفعة.

### PATCH B

الموديول موجود فعليًا، ويشمل:

- `_customerPaymentEndpoint`
- `_customerPaymentFetch`
- `_newCustomerReceipt`
- `_loadCustomerPaymentOrders`
- `_recalcCustomerPayment`
- `_saveCustomerPayment`
- `_renderCustomerPaymentReceiptList`
- `_showCustomerPaymentDetail`

### PATCH C

الـRW_Finance return object يحتوي فعليًا على:

`_newCustomerReceipt`
`_loadCustomerPaymentOrders`
`_recalcCustomerPayment`
`_saveCustomerPayment`
`_showCustomerPaymentDetail`

وبالتالي لم تتم إعادة إضافة Patch C.

## 4. Production Database — الحالة الحالية

Supabase project:
`fiilmooggumokxanwiyx`

الجداول المطلوبة موجودة فعليًا:

- `sales_payment_receipts`
- `sales_payment_allocations`
- `erp_operation_registry`
- `orders.amount_paid`

### Constraints / Indexes المثبتة

`erp_operation_registry`:

- UNIQUE `(company_id, operation_type, operation_key)`

`sales_payment_receipts`:

- UNIQUE `(company_id, receipt_code)`
- UNIQUE `(company_id, operation_id)`

`sales_payment_allocations`:

- UNIQUE `(receipt_id, order_id)`
- Index `(order_id)`
- Index `(receipt_id)`

## 5. Production RPCs

تم فحص التعريفات الفعلية المنشورة في Production.

### `post_sales_payment_allocation_atomic`

العقد الحالي:

- Company-scoped Customer.
- Company-scoped Treasury.
- Company-scoped Orders.
- تحقق من Customer/Order mismatch.
- رفض الإلغاء كفاتورة قابلة للتحصيل.
- منع تخصيص يتجاوز outstanding.
- دعم أكثر من فاتورة داخل Receipt واحد.
- دعم Partial Allocation.
- حساب Unallocated = Amount - Allocated.
- Idempotency عبر `erp_operation_registry`.
- Fingerprint لمنع إعادة استخدام Operation ID مع Payload مختلف.
- Stale processing guard.
- إنشاء receipt وallocations وتحديث `orders.amount_paid` داخل المسار الذري.
- تحديث Customer Ledger.
- إنشاء Audit entry.

### `post_cash_receipt_atomic`

العقد الحالي:

- Company-scoped Treasury.
- Company-scoped Cash Account.
- Company-scoped Offset Account.
- Idempotency عبر نفس `erp_operation_registry` ولكن تحت Operation Type مستقل.
- إنشاء `cash_box`.
- إنشاء القيد المحاسبي عبر `post_journal_entry`.
- تحديث رصيد الخزينة.

لم يتم إنشاء Writer بديل ولم تتم إضافة Core منافس.

## 6. Production Edge Deployment

Edge Function:
`sales-payment-allocation`

Status:
`ACTIVE`

Version:
`1`

`verify_jwt=true`

Deployment SHA:
`9df011f54b67afc9c3e1c73a9948fcb0c77673844a0441cfd54685704fdf2f85`

الـEdge الحالي يقوم بـ:

`JWT -> users.auth_id -> company_id -> action -> RPC`

والـActions المثبتة:

`catalog`
`open_orders`
`list`
`detail`
`create`

## 7. Realtime Production Evidence

تم التحقق من أن:

`sales_payment_receipts`

و

`sales_payment_allocations`

موجودتان داخل publication:

`supabase_realtime`

وبالتالي طبقة Realtime Database-side موجودة فعليًا في Production.

## 8. Production E2E Transactional Test

تم إنشاء بيانات اختبار مؤقتة في Production لاختبار المسار الحقيقي، وليس Mock.

### السيناريو

Receipt:
`150`

Allocation #1:
`60`

Allocation #2:
`50`

Expected Unallocated:
`40`

### النتيجة الأولى

`success=true`
`duplicate=false`
`allocated_amount=110`
`unallocated_amount=40`
`allocation_count=2`

### Retry بنفس Operation ID

النتيجة:

`success=true`
`duplicate=true`

مع نفس Receipt والنتيجة المالية، دون إنشاء عملية ثانية.

هذا يثبت Production runtime للـCore في مسار Multiple + Partial + Idempotent retry.

### Cleanup

تم حذف:

- Customer test.
- Orders test.
- Sales payment receipt.
- Allocations.
- Cash box record.
- Customer ledger test record.
- Journal test entry/lines.
- Operation registry test records.

وتم التحقق النهائي من أن جميع بيانات الاختبار أصبحت:

`0`

ولا توجد آثار اختبار في الجداول المستهدفة.

## 9. ما لم يحتج تعديلًا في Production

بعد مطابقة Production الحالية مع Source وDeployment:

- لم يتم إعادة إنشاء Payment Core.
- لم يتم إنشاء جداول بديلة.
- لم يتم إنشاء Edge Function ثانية.
- لم يتم تغيير RPCs الموجودة لأنها أثبتت نجاحها في اختبار Production الحقيقي.
- لم يتم إنشاء Writer موازي.
- لم يتم تعديل Realtime publication لأنها مثبتة بالفعل.

هذا القرار متعمد لمنع إصلاح ما ثبت أنه مُصلح أصلًا.

## 10. العيب الحالي الفعلي في النظام الأم

### العيب الأول — متغير القناة غير معرّف

في `main.html` الحالي توجد الدالة:

`function _startCustomerPaymentRealtime() {`

وتستخدم مباشرة:

`_customerPaymentRealtimeChannel`

لكن لا توجد declaration مقابلة من نوع:

`var _customerPaymentRealtimeChannel = null;`

### العيب الثاني — الاستدعاء في المكان الخطأ

الـHEAD الحالي وضع:

`_startCustomerPaymentRealtime()`

داخل:

`async function _loadDashboardData(fromDate, toDate) {`

بعد:

`var companyId = _companyId();`

وهذا ليس مكان تشغيل Consumer الخاص بتبويب سندات القبض.

المكان الصحيح وفق وظيفة الموديول نفسه هو `_renderReceipts()` بعد:

`var companyId = _companyId();`

وبالتالي فإن الاستدعاء داخل Dashboard يجب حذفه، وليس الإبقاء عليه مع إضافة declaration فقط.

## 11. تعليمات Owner Surgical Repair — النظام الأم

**ممنوع تعديل أي ملف تاريخي.**

الهدف الوحيد:
`erp-frontend/companies/company-1/main.html`

### التعديل 1 — إضافة declaration

ابحث في `main.html` الحالي عن هذا العنصر الكامل:

```text
function _startCustomerPaymentRealtime() {
```

وهو عند بداية البلوك المضاف في منطقة تقارب السطر:

`11386`

أضف فوقه مباشرة هذا السطر الكامل:

```javascript
var _customerPaymentRealtimeChannel = null;
```

لا تحذف الدالة نفسها.

### التعديل 2 — نقل استدعاء Realtime إلى `_renderReceipts()`

ابحث عن:

```javascript
function _renderReceipts() {
```

وفي نفس الدالة ابحث عن السطر الكامل:

```javascript
var companyId = _companyId();
```

أضف تحته مباشرة:

```javascript
_startCustomerPaymentRealtime();
```

### التعديل 3 — حذف الاستدعاء الخاطئ من Dashboard

ابحث عن بداية الدالة كاملة:

```javascript
async function _loadDashboardData(fromDate, toDate) {
```

واذهب إلى هذا السطر الموجود حاليًا بعدها في المسار:

```javascript
_startCustomerPaymentRealtime()
```

احذف **هذا السطر كاملًا فقط**.

لا تحذف:

```javascript
var companyId = _companyId();
```

ولا تعدل بقية `_loadDashboardData()`.

### شكل النتيجة المطلوبة

في `_renderReceipts()` يجب أن يصبح الترتيب:

```javascript
var companyId = _companyId();
_startCustomerPaymentRealtime();
Promise.all([
```

وفي `_loadDashboardData()` يجب ألا يوجد أي:

```javascript
_startCustomerPaymentRealtime()
```

## 12. ملاحظة مهمة على Commit HEAD

الـCommit:
`c379674711d6e67d5c2c01305ae8449dd3c0947e`

أدخل Consumer Realtime ولكنه لم يراعِ الوضع النهائي للملف بعد التجميع بنفس دقة Patch التاريخي؛ إذ أصبح موضع الاستدعاء مرتبطًا بـDashboard بدل Receipt Consumer، كما أن declaration لم تظهر في المصدر الحالي.

هذه هي الفجوة المحددة التي يجب إصلاحها، وليس إعادة تطبيق كامل Patch الدفع.

## 13. E2E Closure Status

### Backend/Core
`PRODUCTION DEPLOYED = YES`
`PRODUCTION RUNTIME VERIFIED = YES`
`MULTIPLE ALLOCATION = VERIFIED`
`PARTIAL ALLOCATION = VERIFIED`
`UNALLOCATED BALANCE = VERIFIED`
`IDEMPOTENT RETRY = VERIFIED`
`TENANT SCOPING = VERIFIED`
`REALTIME PUBLICATION = VERIFIED`

### Master UI
`PATCH A = PRESENT`
`PATCH B = PRESENT`
`PATCH C = PRESENT`
`Realtime declaration = MISSING`
`Realtime invocation placement = WRONG`
`Browser E2E = NOT EXECUTED IN THIS SESSION`

### Final Closure

`Multiple / Partial Sales Payment Allocation = OPEN — OWNER SURGICAL FIX REQUIRED`

وليس OPEN بسبب Backend.

سبب الفتح الحالي محصور في Consumer/UI:

1. إضافة channel declaration.
2. نقل realtime start إلى `_renderReceipts()`.
3. حذف الاستدعاء الخاطئ من `_loadDashboardData()`.
4. تشغيل Browser E2E فعلي بعد دمج المالك.

## 14. Self-Audit

### What I Proved

- Production Payment Core موجود ويعمل.
- Multiple allocation يعمل فعليًا.
- Partial allocation يعمل فعليًا.
- Unallocated amount صحيح.
- Retry idempotent فعليًا.
- Company scoping حاضر في RPC/API.
- الجداول والقيود والفهارس موجودة.
- Realtime publication موجودة.
- `main.html` الحالي يحتوي بالفعل على Payment UI patches.
- العيب الحالي في Realtime Consumer محدد نصيًا ومكانيًا.
- لا توجد بيانات اختبار متروكة.

### What I Did Not Prove

- لم يتم تنفيذ Browser E2E داخل متصفح فعلي في هذه الجلسة.
- لم يتم إثبات Console/DOM/network بعد دمج التعديل اليدوي للمالك.

### What I Fixed

- لم يتم تعديل Payment Core لأن Production أثبت سلامته.
- تم تنفيذ Production E2E حقيقي ثم تنظيف كامل.
- لم يتم إنشاء بنية بديلة.
- تم تحديد إصلاح Owner بدقة شديدة.

### What I Initially Missed / What The Current HEAD Revealed

- موضع استدعاء Realtime في Dashboard بدل Receipt view.
- غياب declaration للchannel variable.

### What Could Still Be Wrong

الجزء الوحيد غير المثبت حاليًا هو Browser Runtime بعد تنفيذ Owner surgery.

## 15. Forensic Assembly Source of Truth

تم فتح:
`forensic_main_assembly.yml`

وهو موجود في:
`rawaie-erp-New/forensic_main_assembly.yml`

وحالته الحالية صحيحة بالفعل:

`repository: papamohammed77-glitch/erp-frontend`

`path: companies/company-1/main.html`

`ref: main`

`mode: published_main_is_authoritative`

لذلك **لم يتم تعديل الملف** لأنه مثبت بالفعل بالشكل الصحيح.

## 16. إرشادات المساعد التالي — كيف يبدأ للوصول إلى الحقيقة

لا تبدأ من Report170 ولا Report169 ولا أي تقرير آخر كحالة حالية.

ابدأ بالترتيب التالي دائمًا:

1. اقرأ `CURRENT_STATE.md` فقط لفهم نقطة الاستئناف، وليس لإثبات الحالة.
2. اقرأ أحدث Git HEAD في `erp-frontend`.
3. افتح الـDirect Parent.
4. قارن Diff الحقيقي للـHEAD مع الـParent.
5. افتح **نفس** `companies/company-1/main.html` الحالي من Git.
6. حدد SHA الملف الحالي.
7. لا تعتمد على `Current/PWA/main2` إلا لفهم نية تاريخية عند وجود تعارض.
8. افحص Production Database في نفس اللحظة.
9. افحص schema + indexes + constraints + RLS + RPC definitions.
10. افحص Edge deployment الحالي بالنسخة والـhash وليس بالاسم فقط.
11. افحص Realtime publication إذا كان Consumer يعتمد عليه.
12. ابنِ جدولًا ذهنيًا لكل Responsibility: UI / Edge / RPC / DB / Ledger / Audit / Realtime.
13. إذا وجدت Patch تاريخيًا، قارنه مع `CURRENT SOURCE` ولا تفترض أنه ما زال مطابقًا.
14. لا تعيد إصلاح ما ثبت أنه CLOSED.
15. إذا كان الخلل في Production: أصلحه مباشرة، ثم اختبره في Production.
16. إذا كان الخلل في Master UI: لا تعدّل الملف بنفسك؛ أعطِ Owner أمرًا جراحيًا يحدد Search Token + Location + Full Replacement + Exact Delete.
17. اختبر Success + Partial + Duplicate + Wrong Tenant + Edge Failure عندما تسمح البيئة.
18. نظّف أي بيانات اختبار من Production وأثبت ذلك باستعلامات صفرية.
19. لا تعتبر Backend PASS هو E2E PASS.
20. لا تسجل `100% CLOSED` قبل Browser Runtime verification إذا كان المسار يعتمد على UI.
21. عند أي تعارض، CURRENT PRODUCTION وCURRENT SOURCE يتقدمان على التقارير القديمة.
22. بعد الإغلاق، حدّث `CURRENT_STATE.md` وسجل التقرير النهائي قبل بدء Closure جديد.

## 17. النتيجة التنفيذية

**Payment Backend / Production Core:** مغلق ومثبت.

**Payment Realtime Infrastructure:** موجود ومثبت.

**Master UI Payment module:** موجود.

**Master UI Realtime wiring:** يحتاج إصلاحين جراحيين محددين فقط.

**Browser E2E:** مفتوح حتى ينفذ المالك التعديل المحدد ويجري الاختبار الفعلي.

لا توجد حاجة لإعادة بناء Payment Core أو إنشاء Edge Function جديدة أو إنشاء جداول بديلة.
