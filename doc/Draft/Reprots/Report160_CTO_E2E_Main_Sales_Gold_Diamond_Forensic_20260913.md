# تقرير 160 — CTO Forensic E2E للنظام الأم ومراجعة المبيعات Gold / Diamond

**التاريخ:** 2026-09-13  
**الحالة:** تنفيذ جنائي من مصادر الحالة الحالية فقط  
**المرحلة:** Sales / Parent System E2E  
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  

---

# 0. الرسالة الحاكمة — اقرأها أولًا

**الهدف في هذه المهمة هو قراءة الحالة الحالية الحقيقية للنظام الأم كما هي منشورة الآن، لا إعادة تنفيذ إصلاحات تاريخية ثبت إغلاقها، ولا اعتبار أي تقرير سابق مرجعًا للحالة الحالية.**

الحالة المعتمدة في هذا التقرير بُنيت فقط من:

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
```

التقارير التاريخية استُخدمت فقط للوصول إلى المصادر والبحث عن السياق، ولم تُستخدم كإثبات لحالة Production الحالية.

ويُكرر المبدأ هنا لأن أي Closure لاحق يجب أن يبدأ منه:

> **لا قيمة لأي تقرير أو نسبة اكتمال قبل مطابقة CURRENT PRODUCTION في نفس التحقيق.**

---

# 1. نتيجة التنفيذ

تم تنفيذ مراجعة Forensic/E2E على النظام الأم الحالي، مع التحقق المتقاطع من:

- أحدث Commit في `erp-frontend` وParent المباشر.
- النسخة الحالية المنشورة من `main.html`.
- `CURRENT_STATE.md` كسجل حي ثم إعادة مطابقة المعلومات الواردة فيه مع المصادر الحالية.
- `forensic_main_assembly.yml`.
- بنية التطبيقات التشغيلية المنفصلة داخل `erp-frontend`.
- Production Supabase schema الحالية.
- Production Edge Functions الحالية وإصداراتها.
- Production PostgreSQL RPCs ذات الصلة بالمبيعات.
- Daftra كمرجع منافس خارجي محدث.

**النتيجة الأساسية:**

النظام الأم الحالي ليس مجرد هيكل فارغ، ولديه أساس Sales تشغيلي حقيقي، كما أن التطبيقات المنفصلة تؤدي أدوارًا تشغيلية تكاملية. لكن **Sales Gold/Diamond لم يكتمل**؛ توجد فجوات وظيفية مؤسسية مثبتة في الـSource والـProduction، وأبرزها عروض الأسعار، إدارة قوائم الأسعار والتسعير المتقدم، العروض التجارية، العمولات والأهداف، واجهة الأقساط، واجهة الولاء، ومسار Sales Returns/Credit Notes المستقل داخل Sales.

كما تم إثبات أن بعض قدرات Production موجودة بالفعل ويجب عدم إعادة إصلاحها بلا دليل جديد.

---

# 2. Current Git — آخر حالة مثبتة

## 2.1 `erp-frontend`

**HEAD الحالي:**

```text
3573c92026557cb56a7782babe6f6cf690243072
```

**Commit:** `Update main.html`  
**التاريخ:** `2026-09-13T09:58:01Z`

**Parent المباشر:**

```text
28f39b351bb44a4cd885ba784d505aadaeb13cf1
```

المقارنة بين HEAD والـParent الحاليين تثبت أن آخر تغيير على `main.html` كان تغييرًا محدودًا في عرض بيانات فرع التحويل، وأن إصلاح `branch_name` التاريخي موجود بالفعل في HEAD الحالي.

**لا يجوز إعادة هذا الإصلاح دون دليل Browser/Runtime جديد.**

---

# 3. Current Source — النظام الأم

المصدر الحالي:

`https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html`

**Blob SHA الحالي:**

```text
43ab5c85ee63939404a0c426524f92e406441f07
```

الحجم المثبت من GitHub API:

```text
947023 bytes
```

ملف النظام الأم هو **Source of Truth المنشور**، وليس `Current/PWA/main` ولا `Current/PWA/New-main` ولا أجزاء `main2`.

`Current/PWA/main2` أُعيد التحقق من وجوده في مستودع `rawaie-erp-New` باعتباره **Reference-only** كما ينص `forensic_main_assembly.yml`، وليس مصدرًا للحالة الحالية.

---

# 4. `forensic_main_assembly.yml`

تم فحص الملف الحالي مباشرة.

القيمة المثبتة:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main

assembly_status: reference_only; published_main_is_authoritative
```

**النتيجة: المسار صحيح، ولا يوجد تعديل مطلوب عليه في هذه الجلسة.**

الـFragments التاريخية ما زالت محددة كمرجع فقط، وهذا هو السلوك الصحيح.

---

# 5. دور النظام الأم — النتيجة المعتمدة

الدراسة الحالية لا تدعم اعتبار النظام الأم بديلًا عن التطبيقات التشغيلية المنفصلة.

العقد الصحيح هو:

```text
النظام الأم
= Control / Oversight / Integration / Administration / Exception Handling

التطبيقات المنفصلة
= Operational Execution
```

الدليل الحالي من مستودع `erp-frontend` يثبت وجود تطبيقات مبيعات منفصلة:

```text
companies/company-1/sales/manager.html
companies/company-1/sales/order-taker.html
companies/company-1/sales/pos.html
companies/company-1/sales/supervisor.html
companies/company-1/sales/telesales.html
companies/company-1/sales/van-sales.html
```

كما يوضح `app.html` الحالي مسارات التوجيه للـPOS وTelesales وOrder Taker وVan Sales والمبيعات الإدارية، إضافة إلى تطبيقات المخازن والتوصيل والمشتريات والمكتب.

لذلك فإن معيار تقييم `main.html` الصحيح ليس: "هل يحتوي على كل عملية تشغيلية؟".

بل:

```text
هل يدير ويراقب ويتكامل مع العمليات التشغيلية؟
هل يمكن للإدارة المركزية فهم الحالة؟
هل يمكنها التدخل عندما يلزم؟
هل تعكس بيانات التطبيقات المنفصلة الحالة المركزية؟
هل توجد فجوات Sales إدارية/مؤسسية لا تغطيها التطبيقات الأخرى؟
```

---

# 6. Current Sales Navigation — مثبت من Source

في `main.html` الحالي، داخل:

```text
const RW_Navigation
```

يقع تعريف المبيعات حاليًا في منطقة تقارب **السطر 18904**، والنص الحالي هو:

```text
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }] },
```

وهذا هو **النطاق الحالي الفعلي** لإدارة المبيعات داخل النظام الأم.

لا توجد داخله بشكل مستقل:

- عروض الأسعار.
- إدارة قوائم الأسعار.
- إدارة عروض وتسعير مبيعات متقدم.
- عمولات المبيعات.
- أهداف المبيعات.
- أقساط المبيعات.
- إدارة الولاء.
- Sales Returns / Credit Notes كمسار مستقل تحت Sales.

كما أن البحث الجنائي في المصدر الحالي لم يعثر على:

```text
عروض الأسعار
قائمة الأسعار
commission
quotation
price_list
(قيد التطوير)
```

وهذا ليس استنتاجًا من تقرير قديم؛ بل نتيجة فحص مباشر للمصدر الحالي.

---

# 7. ما الذي يعمل بالفعل داخل Sales

## 7.1 POS

الوحدة الحالية:

```text
RW_POS
```

ومسار التوجيه موجود فعليًا.

النموذج الحالي يدعم:

- اختيار العميل.
- اختيار الفرع الرئيسي.
- البحث عن الصنف.
- الكمية.
- رسوم التوصيل.
- الضريبة.
- الإجمالي.
- حفظ الفاتورة.

في `save()` الحالي يظهر:

```text
operation_id: crypto.randomUUID()
```

ثم:

```text
status: 'Invoiced'
paymentType: 'نقدي'
```

وترسل العملية إلى:

```text
/functions/v1/save-sales-invoice
```

Production الحالية لديها بالفعل `save-sales-invoice` بإصدار **15** وتعمل JWT-protected.

## 7.2 Telesales

الوحدة الحالية:

```text
RW_TeleSales
```

وتثبت وجود:

- البحث عن العميل.
- إنشاء/اختيار العميل.
- تحديد الفرع المصروف منه.
- البحث عن الصنف بالاسم/الكود/الباركود.
- فحص الرصيد المتاح.
- حدود الكمية.
- سلة طلب.
- رسوم توصيل.
- ضريبة.
- حفظ الأوردر.

والـSave الحالي يرسل:

```text
status: 'Confirmed'
```

مع `operation_id` generated per save attempt.

## 7.3 Sales Orders

`RW_Orders` موجود فعليًا ويدعم إدارة الأوردرات والفلترة والفرز والتأكيد والحذف وربط الرانشيت.

ويحتوي حاليًا على realtime subscriptions على:

```text
orders
order_details
app_settings
```

بـCompany filtering مناسب للأوردرات والإعدادات.

هذا جزء مهم يجب الحفاظ عليه لأنه يمثل الطبقة المركزية التي تراقب العمليات التشغيلية المنفذة من تطبيقات أخرى.

---

# 8. Production Sales — Current Database Reality

تم تنفيذ enumeration مباشر على Production Supabase، وكانت النتائج الحالية:

```text
companies       = 1
branches        = 2
items           = 17
customers       = 3
orders          = 0
runsheets       = 0
stock_vouchers  = 0
inventory_log   = 3
credit_notes    = 0
installments    = 0
loyalty_points  = 0
coupons         = 0
```

هذه الأرقام هي **لقطة هذا التحقيق فقط** وليست أرقامًا مستقبلية ثابتة.

وجود جدول لا يعني وجود Business Contract مكتمل.

---

# 9. Current Sales Database Contracts

## 9.1 Orders

جدول `orders` الحالي يتضمن، من بين الحقول المهمة:

```text
company_id
operation_id
order_code
order_date
customer_id
customer_name
branch_id
order_status
payment_type
runsheet_id
sales_rep_id
sales_rep_name
coupon_code
discount_amount
amount_paid
```

وهذا يثبت أن الـSchema الحالي يتجه إلى دعم عملية Sales متعددة المراحل، وليس مجرد فاتورة بسيطة.

## 9.2 Order Details

`order_details` هو المصدر الأقرب إلى تفاصيل fulfillment الحالية ويحتوي:

```text
qty
qty_picked
qty_loaded
qty_delivered
qty_refused
qty_returned
unit_price
reason_picking
reason_loading
reason_delivery
reason_return
driver_liability
```

وهذا يتفق مع العقود التشغيلية التي تعتمد على التطبيقات المنفصلة.

## 9.3 Credit Notes

جدول `credit_notes` موجود حاليًا، ويحتوي على:

```text
company_id
cn_code
cn_date
order_id
runsheet_id
customer_id
customer_name
total_amount
reason
status
created_by
```

لكن لا توجد حاليًا سجلات فعلية فيه.

## 9.4 Installments

الجداول:

```text
installments
installment_details
```

موجودة، لكن لا توجد بيانات حالية، ولا يوجد Production RPC يحمل عقدًا واضحًا خاصًا بدورة الأقساط.

## 9.5 Loyalty

`loyalty_points` موجود، لكنه فارغ حاليًا، ولا يوجد Production RPC مستقل مثبت لدورة earn/redeem/expiry.

## 9.6 Coupons

`coupons` موجود لكنه فارغ حاليًا.

وجوده لا يساوي اكتمال محرك Promotions/Price Lists.

---

# 10. Current Production RPC Evidence

الدوال التي تم إثباتها في Production ذات الصلة المباشرة بالمبيعات:

```text
save_sales_invoice_atomic
complete_return_atomic
post_cash_payment_atomic
```

## `save_sales_invoice_atomic`

Production الحالية تثبت:

- استخراج Company من المستخدم النشط.
- إلزام `operation_id`.
- كشف duplicate العملية عبر `orders.operation_id`.
- Company-scoped customer.
- Company-scoped branch.
- Company-scoped settings.
- الاستناد إلى `post_stock_movement` للفواتير Invoiced.
- Accounting posting.
- Cash receipt عندما تكون العملية نقدية.
- Customer ledger عندما تكون آجل.

هذا **ليس موضعًا لإعادة البناء أو إعادة الترقيع الآن** ما لم تظهر Production evidence جديدة.

## `complete_return_atomic`

Production الحالية تثبت وجود عقد حقيقي ومتكامل نسبيًا:

```text
authenticated company
→ operation registry
→ runsheet/order validation
→ order_details validation
→ return quantity control
→ driver liability
→ post_stock_movement
→ accounting
→ customer ledger
→ order status
→ runsheet aggregation
→ operation completion
```

والمصدر يثبت أن Physical Stock في المرتجع يمر عبر:

```text
post_stock_movement
```

وهذا مهم لأن Sales Return لا يجوز أن يعيد بناء محرك Stock مستقلًا.

---

# 11. Current Edge Deployment Evidence

Production الحالية تثبت الإصدارات التالية:

```text
save-sales-invoice     v15  JWT=true
confirm-order          v4   JWT=true
update-order           v3   JWT=true
create-credit-note     v2   JWT=true
complete-return        v25  JWT=true
```

`complete-return` الحالي يربط المستخدم المصادق عليه بـ`users.auth_id` ثم يأخذ Company من المستخدم، وبعدها ينادي:

```text
complete_return_atomic
```

وبذلك فإن الـEdge wrapper الحالي لا يستخدم `app_settings LIMIT 1` لاستخراج Company.

هذه الحالة **مغلقة بالنسبة للـwrapper الحالي**.

---

# 12. Sales Return / Credit Note — الحقيقة الحالية

تم التحقق من وجود مسارين منفصلين في Production:

### A. `complete_return_atomic`

ينفذ Business Return ويعيد المخزون السليم ويربط العملية بالحركة المخزنية والحسابات والـledger.

### B. `create-credit-note` v2

ينشئ سجل `credit_notes` بعد التحقق من:

- Company actor.
- Order company scope.
- Runsheet company scope.
- Order/Runsheet consistency.
- Order detail membership.
- Return quantity ceiling.

ولكن هذه القدرة **ليست حتى الآن Sales Return transaction واحدة موحدة ذات مرجع ذري واضح بين حركة المخزون وإنشاء Credit Note**.

وهذا هو سبب عدم إضافة مجرد زر أو Tab باسم "إشعار دائن" في النظام الأم.

المطلوب القادم هو إغلاق هذه الوحدة كـClosure Unit مستقلة، وليس اختراع UI أمام عقدين منفصلين.

---

# 13. Sales Idempotency — عيب مثبت في Current Source

الـBackend الحالي لديه operation identity صحيحة نسبيًا.

لكن `main.html` الحالي يولد `operation_id` جديدًا عند كل محاولة Save في:

```text
RW_POS.save()
```

وكذلك في:

```text
RW_TeleSales._saveOrder()
```

النمط الحالي:

```text
operation_id: crypto.randomUUID()
```

داخل كل محاولة Save.

النتيجة:

إذا ضاعت استجابة HTTP بعد أن نجحت العملية، ثم ضغط المستخدم Save مرة ثانية، فلن تكون المحاولة الثانية duplicate من منظور Backend لأنها تحمل UUID جديدًا.

**هذا عيب Frontend Contract مثبت.**

ولا يحتاج أي تغيير في Production Backend الحالية في هذه الجلسة، لأن الـBackend بالفعل يستقبل operation identity.

---

# 14. OWNER SURGICAL FIX #1 — POS Idempotency

**الملف:**

```text
companies/company-1/main.html
```

**الدالة:**

```text
RW_POS.save()
```

**الموضع الحالي التقريبي:** يبدأ في منطقة **السطر 22750 تقريبًا**، والنص الذي يجب استبداله هو كتلة بناء `orderHeader` التي تحتوي على:

```text
var orderHeader = {
    operation_id: crypto.randomUUID(),
```

**التعديل المطلوب:**

لا تُنشئ UUID جديدًا داخل كل Save attempt.

ابحث عن السطر الكامل:

```text
var orderHeader = {
```

واستبدل **كاملة كتلة `orderHeader` حتى السطر الأخير الذي ينتهي بـ `taxRate: taxRate` و `};`** بكود يستخدم Operation ID ثابتًا للعملية الحالية، مثل:

```javascript
var operationId = window.__rwPosOperationId || null;
if (!operationId) {
    operationId = crypto.randomUUID();
    window.__rwPosOperationId = operationId;
}

var orderHeader = {
    operation_id: operationId,
    custId: cust,
    custName: customer ? customer.name : '',
    area: customer ? customer.area : '',
    total: total,
    deliveryFees: del,
    status: 'Invoiced',
    paymentType: 'نقدي',
    taxAmount: taxAmt,
    taxRate: taxRate
};
```

وبعد نجاح العملية فقط، بعد:

```text
cart = [];
```

أضف:

```javascript
window.__rwPosOperationId = null;
```

وفي مسار الخطأ لا تمسح `window.__rwPosOperationId` حتى تظل إعادة المحاولة للعملية نفسها.

**لا تعدل `save-sales-invoice` Production نتيجة هذا العيب؛ backend الحالي يدعم operation identity بالفعل.**

---

# 15. OWNER SURGICAL FIX #2 — Telesales Idempotency

**الدالة:**

```text
RW_TeleSales._saveOrder()
```

**الموضع الحالي:** كتلة بناء `orderHeader` الموجودة قرب **السطر 23740 تقريبًا**.

النص الحالي يحتوي:

```text
var orderHeader = {
    operation_id: crypto.randomUUID(),
```

ابحث عن `var orderHeader = {` داخل `RW_TeleSales._saveOrder()` وليس أي `orderHeader` آخر.

احذف الكتلة كاملة واستبدلها بالآتي:

```javascript
var operationId = window.__rwTeleSalesOperationId || null;
if (!operationId) {
    operationId = crypto.randomUUID();
    window.__rwTeleSalesOperationId = operationId;
}

var orderHeader = {
    operation_id: operationId,
    customer_code: selectedCustomer.customer_code,
    custName: selectedCustomer.name,
    area: selectedCustomer.area || '',
    total: total,
    deliveryFees: deliveryFee,
    status: 'Confirmed',
    paymentType: selectedCustomer.payment_type || 'أجل',
    taxAmount: taxAmt,
    taxRate: taxRate
};
```

وبعد نجاح العملية وقبل مسح العميل/السلة أضف:

```javascript
window.__rwTeleSalesOperationId = null;
```

وفي حال الفشل لا تمسح الـOperation ID.

هذا يجعل retry بعد timeout أو فقد response يعيد نفس Business Operation بدل إنشاء Order ثانٍ.

---

# 16. لا تعدل أي شيء في POS/Telesales حاليًا غير ما سبق

لا تغير:

- تسعير الأصناف الحالي.
- Business status الحالي.
- Branch source logic.
- Tax calculation.
- Delivery fee.
- `save-sales-invoice` production RPC.
- Realtime Orders.
- Runsheet linkage.

هذه كلها عقود موجودة حاليًا ويجب عدم إعادة بنائها أثناء إصلاح idempotency.

---

# 17. Sales Gold/Diamond — فجوات مثبتة

## 17.1 عروض الأسعار

**الحالة:** غير موجودة في current Sales Navigation ولا يوجد current Sales Quote transaction contract مثبت في Production.

المطلوب النهائي:

```text
Quote
→ Approval / Revision
→ Convert to Sales Order
→ Convert to Invoice
```

لكن لا يجوز إضافة UI قبل إنشاء/اكتشاف contract Production مستقل.

## 17.2 Price Lists

لا توجد current tables أو RPCs مستقلة مثبتة لإدارة Price Lists.

لا يجوز استخدام `items.sales_price` وحده لتسمية ذلك Price List Engine.

المطلوب:

```text
Base Price
+
Customer / Customer Group Price
+
Branch Price
+
Quantity Tier
+
Date Validity
+
Priority
```

## 17.3 Offers / Promotions

`coupons` موجود، لكن هذا لا يمثل Promotions Engine.

المطلوب المؤسسي:

```text
percentage
fixed amount
quantity breaks
buy X get Y
category/item scope
customer scope
date/time scope
priority / stacking policy
```

ولا يجوز إضافة ذلك إلى POS مباشرة قبل وجود Production pricing contract.

## 17.4 Sales Commissions

لا توجد current Production function مستقلة مثبتة لمحرك commissions.

المطلوب:

```text
rep/group
period
item/category
threshold
rate
approval
return reversal
payment lifecycle
```

## 17.5 Sales Targets

لا يوجد current target engine مثبت.

المطلوب:

```text
period
rep/team
target value / quantity
achievement
adjustments
returns impact
approval / lock
```

## 17.6 Installments

الجداول موجودة لكنها فارغة، والعقد التشغيلي غير مثبت.

لا يجوز بناء UI فوقها مباشرة.

## 17.7 Loyalty

الجداول موجودة لكنها فارغة والعقد earn/redeem/expiry غير مثبت.

## 17.8 Sales Analytics

التقارير الحالية موجودة، لكن Gold/Diamond يتطلب Sales Decision Center مبنيًا على transaction contracts المكتملة، وليس مجرد رسومات عامة.

---

# 18. المقارنة المهنية مع Daftra — Sales فقط

تمت مراجعة المواد الحالية المنشورة من Daftra خلال هذه المهمة.

المصدر الرسمي يوضح وجود منظومة Sales متكاملة تشمل، بحسب المنتج/الخطة:

- Quotes.
- Sales Orders والتحويل إلى Invoice.
- POS.
- Price Lists.
- Offers/Discounts.
- Multiple / Partial Payments.
- Installments.
- Sales Targets.
- Commissions.
- Loyalty.
- Returns / Credit Notes.

المصادر:

- https://daftra.com/
- https://daftra.com/ar/sales
- https://daftra.com/ar/pricing
- https://daftra.com/ar/offers
- https://help.daftra.com/

## Matrix

| المجال | RAWAEA الحالي | Daftra | الحكم |
|---|---|---|---|
| POS | موجود فعليًا | موجود | RAWAEA جيد |
| Telesales | موجود فعليًا | موجود/متكامل مع Sales | RAWAEA جيد تشغيليًا |
| Sales Orders | موجود | موجود | RAWAEA جيد |
| Runsheet integration | مميز ومتكامل مع التطبيقات التشغيلية | ليس نفس النموذج التشغيلي | **ميزة RAWAEA** |
| Field fulfillment quantities | قوي جدًا في `order_details` | موجود ضمن العملية | **ميزة RAWAEA التشغيلية** |
| Quote | غير مثبت في current main/Production | موجود | فجوة RAWAEA |
| Price Lists | غير مثبت | موجود | فجوة |
| Promotions | coupon foundation فقط | موجود بشكل أوسع | فجوة |
| Multiple/Partial Payment | غير مكتمل كـSales UI contract | موجود | فجوة |
| Installments | tables فقط | موجود | فجوة |
| Commissions | غير مثبت | موجود | فجوة |
| Targets | غير مثبت | موجود | فجوة |
| Loyalty | table فقط | موجود | فجوة |
| Returns/Credit Notes | backend contracts موجودة لكن Sales UI/atomic composition غير مكتملة | موجود | فجوة |
| Sales analytics | موجودة جزئيًا | ناضجة | فجوة متوسطة |

**الحكم النهائي:**

RAWAEA ليس أقل قيمة في Sales؛ بل لديه Workflow Field Sales / Runsheet / Picking / Loading / Delivery / Return architecture أكثر تخصصًا من تطبيق Sales مكتبي تقليدي.

لكن هذا لا يعفيه من استكمال الطبقة المؤسسية الأعلى في Sales، وهي تحديدًا المنطقة التي يظهر فيها Daftra متقدمًا.

---

# 19. ما لا يجب فعله

ممنوع في الخطوة التالية:

```text
إضافة Tabs شكلية فقط.

إضافة زر Quote يفتح Modal بلا Backend Contract.

تسمية coupons = Promotions Engine.

تسمية items.sales_price = Price Lists.

تسمية loyalty_points = Loyalty Engine مكتمل.

تسمية installments + installment_details = Installments مكتملة.

نسخ منطق Daftra حرفيًا.

إعادة إصلاح save-sales-invoice.

إعادة إصلاح complete-return دون defect جديد.

إعادة فتح Inventory Writer closures المغلقة.
```

---

# 20. حالة الـE2E الحالية

```text
CURRENT GIT                 = VERIFIED
CURRENT PARENT              = VERIFIED
CURRENT MAIN SOURCE         = VERIFIED
CURRENT PRODUCTION          = VERIFIED
CURRENT DATABASE            = VERIFIED
CURRENT EDGE DEPLOYMENTS    = VERIFIED
CURRENT NAVIGATION          = VERIFIED
CURRENT SALES MODULES       = VERIFIED
CURRENT SEPARATE APPS       = VERIFIED
FORENSIC SALES GAP          = VERIFIED
DAFTRA COMPARISON           = VERIFIED

BROWSER CLICK-BY-CLICK E2E  = NOT VERIFIED
```

السبب الوحيد لبقاء Browser E2E مفتوحًا هو عدم توفر Browser Automation channel في هذه البيئة. لا يجوز تحويل Static/DB/Edge verification إلى Browser PASS.

---

# 21. Production Changes in THIS TASK

**لا توجد Production schema/data changes مطلوبة أو منفذة في هذا التكليف.**

السبب ليس عدم وجود مشاكل، بل لأن:

1. Contracts الأساسية الحالية للمبيعات موجودة.
2. Production current data فارغة من orders/credit notes/installments/loyalty، ولا يوجد business data حقيقي يسمح باختبار تلك الدورات دون اختلاق بيانات.
3. الإصلاحات التي ثبتت الحاجة إليها الآن (`POS/Telesales retry idempotency`) تقع في `main.html`، وهو ملف owner-managed وفق تعليمات المهمة.
4. لا يوجد دليل حالي يبرر إعادة تعديل `save-sales-invoice` أو `complete-return`.

---

# 22. أخطاء/تجارب هذه المهمة

## تجربة 1 — Current Git / Parent

**نجحت.**

تم التحقق من HEAD الحالي وParent المباشر، وتبين أن آخر تغيير على main محدود ولا يعيد فتح الإصلاحات السابقة.

## تجربة 2 — Current Source Sales Navigation

**نجحت.**

تم إثبات النطاق الحالي للمبيعات وعدم وجود المسارات المتقدمة المذكورة أعلاه.

## تجربة 3 — Current Production Schema

**نجحت.**

تمت مطابقة table existence + row counts الحالية.

## تجربة 4 — Current Production RPCs

**نجحت.**

تم استخراج التعريفات الحالية لـSales invoice / return / cash payment.

## تجربة 5 — Current Edge deployment

**نجحت.**

تم التحقق من الإصدارات الحالية، وعلى رأسها:

```text
save-sales-invoice v15
complete-return v25
create-credit-note v2
update-order v3
```

## تجربة 6 — Browser E2E

**لم تُنفذ Click-by-Click.**

لا توجد Browser Automation channel في هذه البيئة.

لا يجوز تسمية ذلك فشلًا في النظام؛ إنه **Evidence Gap** فقط.

---

# 23. تقييم فشل/نقص E2E

المشكلة ليست في وجود POS/Telesales/Orders من الأساس.

المشكلة الحالية هي مستويان:

### المستوى الأول — Transaction reliability

Backend operation identities موجودة، لكن الـFrontend لا يحافظ على نفس operation identity عبر retry.

### المستوى الثاني — Institutional Sales completeness

النظام يملك تنفيذًا تشغيليًا جيدًا، لكنه لا يملك بعد طبقة Sales Management المؤسسية الكاملة التي تشمل Quote/Pricing/Promotion/Targets/Commissions/Installments/Loyalty/Unified Return-Credit Note.

---

# 24. خطة الإغلاق التالية — Closure Units بالترتيب

## Closure Unit 1 — POS/Telesales Retry Idempotency

Owner action:

```text
RW_POS.save()
RW_TeleSales._saveOrder()
```

ثم:

```text
Owner merge
→ current Git verify
→ deployed main verify
→ browser retry test
→ Production duplicate check
→ close
```

## Closure Unit 2 — Sales Document Contract

ابدأ من Production الحالية، وحدد:

```text
Draft
→ Confirmed
→ Runsheet
→ Delivery
→ Invoiced
```

ثم احسم هل Quote يجب أن يكون document مستقلًا أم extension لنفس `orders` model.

## Closure Unit 3 — Unified Sales Return/Credit Note

افتح:

```text
complete_return_atomic
create-credit-note v2
complete-return v25
```

وأثبت transaction boundary المطلوبة قبل UI.

## Closure Unit 4 — Pricing Contract

لا UI قبل حسم:

```text
Price List
+ Promotion
+ Customer scope
+ Item scope
+ Branch scope
+ Date validity
+ Priority
+ Stacking
```

## Closure Unit 5 — Payment Contract

حسم:

```text
Cash
Credit
Partial
Multiple payments
Settlement
Refund
Reconciliation
```

## Closure Unit 6 — Installments

إغلاق lifecycle كامل.

## Closure Unit 7 — Commissions & Targets

إغلاق rules + periods + returns impact + approval.

## Closure Unit 8 — Loyalty

إغلاق earn/redeem/expiry/rollback.

## Closure Unit 9 — Sales Analytics

بعد إغلاق transaction contracts فقط.

---

# 25. نقطة مهمة جدًا بخصوص التطبيقات المنفصلة

لا ينبغي نقل عمليات:

```text
Picking
Loading
Delivery
Return
Unloading
Field Sales execution
```

إلى النظام الأم فقط بهدف زيادة عدد التبويبات.

المعمارية الحالية الأكثر منطقية هي:

```text
Separate Operational Apps
        ↓
Production Transactions
        ↓
Central Database
        ↓
Parent System
        ↓
Monitoring / Control / Analytics / Exceptions
```

وهذا يحافظ على ما يميز RAWAEA بدل تحويل النظام الأم إلى شاشة تشغيل عملاقة.

---

# 26. Gold / Diamond Assessment

## ما تحقق

```text
Operational Sales Foundation           = EXISTS
POS                                    = EXISTS
Telesales                              = EXISTS
Sales Orders                           = EXISTS
Runsheet integration                   = EXISTS
Field fulfillment integration          = EXISTS
Central order monitoring               = EXISTS
Current Production Sales RPCs          = EXISTS
Authenticated Company Context          = EXISTS
Sales stock centralization             = EXISTS
```

## ما لم يتحقق بعد

```text
Quote lifecycle                        = OPEN
Price List engine                      = OPEN
Promotion engine                       = OPEN
Unified Sales Return/Credit Note UI    = OPEN
Multiple/Partial Sales Payments        = OPEN
Installment lifecycle                  = OPEN
Commission engine                      = OPEN
Targets engine                         = OPEN
Loyalty engine                         = OPEN
Full Sales Decision Center             = OPEN
Browser Click-by-Click E2E             = OPEN
```

**النتيجة:**

```text
SALES GOLD / DIAMOND = NOT CLOSED
```

ولا يجوز إطلاق نسبة مئوية عامة لأن قاعدة الحوكمة الحالية تمنع ذلك قبل Production-matched closure metrics.

---

# 27. نقطة Source of Truth النهائية

من هذه اللحظة:

```text
erp-frontend/companies/company-1/main.html
```

هو المصدر الوحيد للحكم على النظام الأم المنشور.

`Current/PWA/main2/*`:

```text
HISTORICAL / REFERENCE ONLY
```

ولا يجوز أخذ أي إصلاح منها إلا بعد إثبات أنه مطلوب في current main.

---

# 28. FINAL SELF-AUDIT

## What I Proved

- HEAD الحالي وParent الحالي في `erp-frontend`.
- أن الملف المنشور الحالي هو `main.html` الحالي فعلًا.
- أن assembly path صحيح.
- أن Sales current navigation محدود بالنطاق المثبت أعلاه.
- أن POS/Telesales/Orders موجودة فعليًا.
- أن التطبيقات المنفصلة موجودة وتؤدي أدوارًا تشغيلية.
- أن Production الحالية تحتوي contracts حقيقية للفواتير والمرتجعات والدفع.
- أن `complete_return_atomic` مركزي ويرجع Physical Stock إلى `post_stock_movement`.
- أن advanced Sales tables ليست proof of completion.
- أن POS/Telesales frontend operation identity الحالية تُولد لكل محاولة.
- أن Sales Gold/Diamond مفتوح.

## What I Did Not Prove

- Browser click-by-click E2E.
- Quote transaction contract كامل.
- Price List transaction contract.
- Promotion engine contract.
- Commission/Target transaction contract.
- Installment transaction contract.
- Loyalty transaction contract.
- atomic unified return + credit note transaction.

## What I Fixed

في **هذا التكليف** لم يتم تعديل `main.html` بواسطة المساعد، التزامًا بقاعدة owner-managed.

لا توجد Production changes في هذا التكليف.

تم تثبيت المطلوب جراحيًا للمالك في هذا التقرير.

## What I Initially Missed

أهم اكتشاف تصحيحي هو أن وجود Backend `operation_id` لا يكفي إذا كانت واجهة النظام تنشئ ID جديدًا لكل retry.

## What Could Still Be Wrong

- Browser runtime قد يكشف مشاكل DOM أو console لا تظهر في static review.
- قد توجد modules متقدمة في applications منفصلة لا تظهر في main، وهذا جيد معماريًا لكنه يجب أن يدخل في Contract Mapping.
- Quote/Pricing/Promotion قد يكون لها artifacts تاريخية لم تثبت كـCurrent Production contracts بعد.

## Final Confidence

```text
Current architectural/sales forensic assessment = HIGH
Current Production structural evidence = HIGH
Browser runtime evidence = NOT AVAILABLE
Gold/Diamond closure = NOT ACHIEVED
```

---

# 29. تعليمات البداية للمساعد التالي — لا يبدأ من الصفر

**هذه هي الرسالة التنفيذية الأهم في نهاية التقرير.**

عند استلام هذه المهمة من مساعد آخر:

```text
1. لا تثق بهذا التقرير كحالة حالية.
2. افتح CURRENT_STATE.md.
3. خذ HEAD وParent من CURRENT GIT مباشرة.
4. افتح erp-frontend/companies/company-1/main.html مباشرة.
5. تحقق من SHA والحجم والحالة الحالية.
6. افتح forensic_main_assembly.yml وتأكد أن Source of Truth ما زال main.html المنشور.
7. تحقق من آخر Commit بعد هذا التقرير؛ لا تستخدم Report160 إذا سبقه Commit جديد.
8. طابق Production Supabase في نفس اللحظة.
9. طابق Edge Function versions الحالية.
10. طابق PostgreSQL RPC definitions الحالية.
11. صنّف كل نتيجة:
   VERIFIED CURRENT / STALE / CONTRADICTED / UNKNOWN.
12. لا تعيد إصلاح أي closure مغلق دون evidence جديد.
13. ابدأ من آخر Closure Unit المثبتة في Current State، لا من بداية المشروع.
```

ثم في Sales:

```text
14. أغلق POS/Telesales retry idempotency أولًا.
15. بعد Owner merge، تحقق من current Git وليس من النص الذي أعطاه المساعد.
16. اختبر browser retry الحقيقي.
17. طابق Production orders.operation_id.
18. أغلق الوحدة 100%.
19. بعدها افتح Sales Document Contract.
20. ثم Sales Return/Credit Note.
21. ثم Pricing/Promotion.
22. ثم Payment.
23. ثم Installments.
24. ثم Commissions/Targets.
25. ثم Loyalty.
26. ثم Sales Analytics.
```

والقاعدة الدائمة:

```text
REPORT
→ SEARCH POINTER
→ PRIMARY SOURCE
→ CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ RUNTIME
→ IMPLEMENT
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ DOCUMENT
→ CLOSE
```

ولا تعتمد أي نتيجة منطقية أو رقم أو نسبة قبل مطابقة Production الحالية في نفس التحقيق.

---

# 30. حالة نهاية الجلسة

```text
MISSION
= تقييم واستكمال Sales في النظام الأم

PHASE
= Sales / Parent System E2E

CLOSURE UNIT
= Sales Forensic Assessment + Owner Surgical Change Set

GIT HEAD
= 3573c92026557cb56a7782babe6f6cf690243072

GIT PARENT
= 28f39b351bb44a4cd885ba784d505aadaeb13cf1

MAIN.HTML SHA
= 43ab5c85ee63939404a0c426524f92e406441f07

PRODUCTION
= fiilmooggumokxanwiyx

PRODUCTION CHANGES IN THIS TASK
= NONE

OWNER CHANGES
= POS/Telesales retry idempotency

BROWSER E2E
= OPEN — no Browser Automation channel

SALES GOLD/DIAMOND
= OPEN

NEXT EXACT TASK
= Owner applies two idempotency surgical replacements, then perform browser retry E2E and production verification.
```

---

# 31. الخلاصة التنفيذية

النظام الأم الحالي وصل إلى مرحلة حقيقية وقوية في التشغيل المركزي للمبيعات، خصوصًا مع تكامل POS/Telesales/Orders/Runsheet والعمليات الميدانية المنفصلة.

لكن الخطأ القديم الذي تكرر في تقييمات سابقة هو اعتبار وجود هذه الأساسيات مساويًا لاكتمال Sales.

الواقع الحالي أدق من ذلك:

```text
الهيكل موجود
+
الدورة التشغيلية موجودة
+
الـBackend المركزي موجود
+
التطبيقات المنفصلة موجودة

لكن

الطبقة المؤسسية العليا للمبيعات ليست مكتملة بعد.
```

وهذا هو موضع العمل الحقيقي التالي.

---

**انتهى Report160.**
