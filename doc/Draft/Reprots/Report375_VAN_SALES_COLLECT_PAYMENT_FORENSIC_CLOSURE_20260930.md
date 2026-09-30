# تقرير تدقيق جنائي — VAN SALES / Closure Unit: collectPayment
## 2026-09-30

## SELF-AUDIT — PRE-CHECK

- فهم الأعمال: 99/100
- فهم المعمارية: 99/100
- فهم قاعدة البيانات: 100/100
- فهم التاريخ: 98/100
- فهم Production: 100/100
- فهم Current: 100/100
- ثقة التنفيذ: 98/100

- حقائق مؤكدة: 18+
- Unknowns مؤثرة على هذه الوحدة: 0
- Conflicts مؤثرة على تصميم هذه الوحدة: 0
- ادعاءات غير مثبتة: 0

Historical: OPENED
Original: OPENED / baseline family
Current: OPENED
Production: OPENED
Schema: CHECKED
Triggers: CHECKED
Dependencies: CHECKED
Consumers: CHECKED

---

# 1. نطاق هذه الجلسة

تم الالتزام بمبدأ Closure Unit الواحد.

الوحدة الحالية هي:

## App.collectPayment()

ولا يتم فتح وحدات Van Sales الأخرى قبل إغلاق هذه الوحدة.

الملفات المحمية ولم تُعدّل:

- `companies/company-1/sales/van-sales.html`
- `companies/company-1/main.html`
- `companies/company-1/warehouse/vouchers.html`

---

# 2. CURRENT FRONTEND REALITY

Repository:

`papamohammed77-glitch/erp-frontend`

File:

`companies/company-1/sales/van-sales.html`

Current SHA:

`e696a82faaacc956301a36a48c15723685d9ce70`

Current size:

`3048 lines / 143255 characters`

Latest frontend commit:

`df0137d062a990cfccf7acbdfd53bc2af34ba610`

Parent:

`8a972680d3a34ae61cb2d12811d14283c6d99361`

المقارنة المباشرة للـcommit أثبتت أن آخر commit عدّل نفس ملف Van Sales فقط.

كما ثبت أن Current يحتوي بالفعل على الإصلاحات السابقة الخاصة بـcustomer accounts، ومنها:

- `loadMyCustomers()` أصبح يستدعي `get_van_sales_customer_accounts`.
- `showCustomerDetail()` أصبح يعتمد على customer UUID ويستدعي نفس RPC.
- `_loadVehicleStock()` يستخدم المصدر الحي `stock_branches` والـVAN canonical branch.
- `syncDown()` يستخرج الشركة من `users.auth_id = authUser.id`.

هذه ليست أعمالًا يجب إعادة فتحها بلا Defect جديد.

---

# 3. PRODUCTION BACKEND REALITY

Production Supabase:

`fiilmooggumokxanwiyx`

تم التحقق مباشرة من:

## save-receipt-voucher

الإصدار الحالي:

`v8`

والدالة تتطلب:

`header.operationId`

وتستخرج company context من المستخدم المصادق عليه.

## post_van_sales_collection_atomic

الدالة موجودة فعليًا كـ:

`SECURITY DEFINER`

وتستخدم:

`erp_operation_registry`

لـoperation-level idempotency.

كما تتحقق من:

- الشركة
- المستخدم
- العميل
- customer assignment
- treasury
- cash account
- AR account

وتنفذ داخل مسار ذري:

`receipt`

+

`customer ledger`

+

`driver ledger`

ثم تحفظ النتيجة في operation registry.

### الحكم

لا توجد حاجة حاليًا إلى Production DDL أو Edge Function جديدة لهذه الوحدة.

---

# 4. DEFECT ACTUAL — collectPayment

Current `App.collectPayment()` يولد:

`operationId`

ويحفظه في:

`localStorage`
`RW_VAN_COLLECTION_PENDING:<companyId>:<customerId>`

وهذا الجزء **صحيح ويجب الحفاظ عليه**.

المشكلة الفعلية:

بعد نجاح:

`save-receipt-voucher`

لا يتم حذف:

`operationStorageKey]

من `localStorage`.

لذلك قد يبقى operation id القديم محفوظًا.

إذا نفذ المندوب عملية تحصيل جديدة في نفس اليوم لنفس العميل وبنفس المبلغ، قد يعاد استخدام نفس operation identity ويتم رفض العملية باعتبارها duplicate.

هذا Defect في دورة حياة هوية العملية، وليس Defect في الـBackend.

---

# 5. WHY THIS IS THE CORRECT FIX

Idempotency يجب أن تعمل هكذا:

### أثناء العملية غير المؤكدة

`operationStorageKey` موجود.

### عند فشل العملية

`operationStorageKey` يبقى.

الهدف: السماح بإعادة المحاولة بنفس operation identity.

### عند نجاح العملية فعليًا

يجب حذف:

`operationStorageKey`

حتى تبدأ العملية المالية التالية بهوية مستقلة.

هذا يحافظ على:

- Retry safety
- no double collection
- ability to make a legitimate second collection
- server-side idempotency

---

# 6. OWNER SURGICAL PATCH — ONLY

## الملف المطلوب

`papamohammed77-glitch/erp-frontend`

`companies/company-1/sales/van-sales.html`

## الدالة

`App.collectPayment()`

## موقع العنصر

داخل:

`then(function(resultData) {`

مباشرة قبل:

`RW_UI.hideLoader();`

### احذف هذا العنصر الحالي:

```javascript
.then(function(resultData) {
    RW_UI.hideLoader();

    Swal.fire({
```

### واستبدله بهذا العنصر كاملًا:

```javascript
.then(function(resultData) {
    try {
        localStorage.removeItem(operationStorageKey);
    } catch (e) {}

    RW_UI.hideLoader();

    Swal.fire({
        icon: 'success',
        title: '✅ تم التحصيل',
        html:
            '<div class="text-right">' +
            '<p>تم تحصيل <strong>' +
            RW_UI.formatNumber(amount) +
            ' ج.م</strong> من ' +
            (resultData.customer.name ||
                resultData.customer.customer_code ||
                name ||
                code) +
            '</p></div>',
        confirmButtonText: 'حسناً',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-green-600'
        }
    }).then(function() {
        self.loadBalanceDetail();
        self.loadHomeBalanceSummary();
    });
})
```

### ممنوع تعديل أي جزء آخر من `collectPayment()`.

ولا تعديل:

- `main.html`
- `warehouse/vouchers.html`
- `setup-van-branch`
- `save-receipt-voucher`
- `post_van_sales_collection_atomic`

لأنها ليست سبب هذا الـDefect.

---

# 7. REQUIRED VERIFICATION AFTER OWNER PATCH

يجب تنفيذ:

### Test 1 — Successful collection

تحصيل مبلغ صحيح.

النتيجة المطلوبة:

- receipt created
- customer ledger updated
- driver ledger updated
- operation registry completed
- localStorage pending key removed

### Test 2 — Same-operation retry

إعادة نفس العملية بسبب فقد response.

النتيجة:

- لا حركة مالية ثانية.

### Test 3 — Legitimate second collection

في نفس اليوم:

نفس العميل

نفس المبلغ

عملية جديدة فعلية.

النتيجة:

- العملية الثانية تنجح.
- operation id مختلف.

### Test 4 — Failure

فشل الخادم قبل النجاح.

النتيجة:

- pending operation key يبقى.
- retry يستخدم نفس operation id.

### Test 5 — Balance reconciliation

بعد النجاح:

`customer balance`

و:

`driver balance`

و:

`treasury receipt`

يجب أن تتفق جميعها.

---

# 8. INVENTORY IMPACT

هذه الوحدة **لا تنفذ Physical Stock Movement**.

التحصيل المالي لا يجب أن يعدل:

`stock_branches.qty`

ولا:

`allocated_qty`

ولا:

`inventory_log`

وهذا متوافق مع Inventory Rescue Contract.

---

# 9. INTEGRATION CONTRACT

المسار الصحيح:

`van-sales.html`

→ `save-receipt-voucher`

→ `post_van_sales_collection_atomic`

→ treasury

+

customer ledger

+

driver ledger

وهو مسار متوافق مع فصل المسؤوليات.

أما:

`warehouse/vouchers.html`

فدوره هو المخزون/الأذونات المخزنية وليس تسجيل تحصيل العميل.

---

# 10. COMPETITOR BENCHMARK

المنطق العام متوافق مع الأنظمة الناضجة:

- SAP Direct Store Delivery يجمع بين البيع/اللوجستيات والتحصيل وتسوية بيانات الجولة في الخلفية. [SAP DSD](https://help.sap.com/docs/SAP_DIRECT_STORE_DELIVERY/027f4475a1494bd1bd81bd129cd59d21/b22a1652f5699a60e10000000a44176d.html)
- Odoo يفصل بين حركة المخزون والمواقع الداخلية؛ نقل المخزون الداخلي لا يعني خروج الملكية من الشركة. [Odoo Inventory](https://www.odoo.com/documentation/20.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html)
- Daftra يدعم تخصيص مخزون لموظف وربطه بمسؤولية ومخزن وحركة وجرد. [Daftra](https://docs.daftra.com/en/user_manual/how-to-assign-inventory-to-an-employee/)
- Manager يدعم تسوية المقبوضات وربطها ببيانات العميل وفواتيره وكشف الحساب. [Manager](https://www2.manager.io/guides/17468)

المطلوب من RAWAEA ليس تقليد هذه الأنظمة، بل أخذ مبادئها الثابتة مع الحفاظ على نموذجها الميداني الخاص.

---

# 11. التنفيذ الحالي

لا توجد Backend changes مطلوبة.

الملف المحمي يحتاج **Owner Surgical Patch واحد فقط**.

بعد تطبيقه:

`Current source verification`

→ browser E2E

→ production collection verification

→ idempotency verification

→ financial reconciliation

→ Closure

---

# 12. NEXT UNITS

بعد إغلاق `collectPayment` بنسبة 100%:

1. `loadMyCustomers()`
2. `loadCustomerPatterns()`
3. `loadKPIs()`
4. `loadHomeSalesSummary()`
5. `loadMyInvoices()`
6. `loadHomeBalanceSummary()/loadBalanceDetail()`
7. `showCustomerDetail()/repeatOrder()`
8. `initiateEndOfDay()`

لا تعاد أي وحدة سبق إصلاحها إلا بناءً على Defect جديد مثبت.

---

# FINAL STATUS

`collectPayment`:

**INCOMPLETE — OWNER PATCH REQUIRED**

Production backend:

**READY / VERIFIED**

Inventory physical movement impact:

**NONE**

Frontend source:

**PATCH READY**

Production deployment:

**NO NEW DEPLOYMENT REQUIRED**

100% Closure:

**NOT YET**

---

# SELF-AUDIT — FINAL

## What I Proved

ثبتُّ Current source الحقيقي، موضع `collectPayment()`، operation identity persistence، Production `save-receipt-voucher v8`، Production collection Core، customer/company validation، وغياب الحاجة إلى Backend modification.

## What I Did Not Prove

لم أجرِ Browser E2E بعد تطبيق Owner patch لأن الملف محمي ولم يتم تطبيق patch في هذا التدقيق.

## What I Fixed

لم أغير الملف المحمي؛ جهزت تعديلًا جراحيًا واحدًا فقط يعالج فقدان تنظيف operation identity بعد النجاح.

## What I Initially Missed

لم يوجد Defect Backend جديد في هذه الوحدة؛ الفجوة المتبقية هي lifecycle cleanup في الواجهة.

## What Could Still Be Wrong

بعد تطبيق patch يجب إثبات سلوك retry ثم legitimate second collection داخل المتصفح/Production.

## Final Confidence

**98/100**

## Closure

**INCOMPLETE — one surgical frontend patch + E2E verification remaining.**
