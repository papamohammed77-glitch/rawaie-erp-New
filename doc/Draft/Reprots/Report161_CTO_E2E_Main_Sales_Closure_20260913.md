# تقرير 161 — CTO E2E للنظام الأم: إغلاق وحدة المرتجع والإشعار الدائن ومراجعة فجوات Sales Gold/Diamond

**التاريخ:** 2026-09-13
**المرحلة:** Sales / Parent System E2E
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

## 0. الرسالة الحاكمة — اقرأها أولًا

**الهدف في هذه الجلسة هو اختبار واستكمال ملف النظام الأم الحالي المنشور، وليس إعادة إصلاح ما ثبت إغلاقه.**

الحقيقة الحالية لا تُستمد من التقارير القديمة. تم اعتماد:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

والنتيجة لا تُعتبر Closure قبل مطابقة Production في نفس التحقيق.

## 1. Current Git / Parent / Source

تمت إعادة مطابقة مستودع `erp-frontend` مباشرة.

- HEAD: `3573c92026557cb56a7782babe6f6cf690243072`
- Direct Parent: `28f39b351bb44a4cd885ba784d505aadaeb13cf1`
- HEAD message: `Update main.html`
- HEAD timestamp: `2026-09-13T09:58:01Z`
- Current `main.html` blob SHA: `43ab5c85ee63939404a0c426524f92e406441f07`

آخر Commit غيّر فقط عرض فرع التحويل من `branch_name` إلى `name`/`branch_code`. لذلك هذا الإصلاح **مغلق ولا يُعاد فتحه** دون Browser/Runtime evidence جديد.

تمت إعادة فحص `forensic_main_assembly.yml`: Source of Truth صحيح ويشير إلى الملف المنشور في `erp-frontend`، بينما `main2` و`New-main` وOriginal كلها Reference/Historical فقط.

## 2. Current Production snapshot

Fresh Production enumeration أثناء هذه الجلسة:

- companies = 1
- branches = 2
- items = 17
- customers = 3
- orders = 0
- runsheets = 0
- credit_notes = 0
- installments = 0
- installment_details = 0
- loyalty_points = 0
- coupons = 0
- inventory_log = 3

`items.item_code` = UNIQUE عالميًا.
`orders` تحتوي Operation Identity (`company_id + operation_id`).

Production لا تحتوي حاليًا على جداول مستقلة مثبتة لـ:

- Quotes
- Price Lists
- Promotions Engine
- Commissions
- Targets

كما أن `coupons` لا تمثل Promotions Engine كاملًا، و`installments` و`loyalty_points` لا تمثلان transaction engines مكتملة.

## 3. دور النظام الأم والتطبيقات المنفصلة

النظام الأم الحالي ليس بديلًا عن التطبيقات التشغيلية.

العقد المعتمد:

```text
Separate Operational Apps
        ↓
Production Transactions
        ↓
Central Database
        ↓
Parent System
        ↓
Control / Monitoring / Integration / Analytics / Exceptions
```

تطبيقات Sales المنفصلة موجودة حاليًا: POS, Telesales, Order Taker, Van Sales, Sales Supervisor/Manager.

وبقية التطبيقات تنفذ Picking / Loading / Delivery / Return / Unloading / Receiving / Inventory Count وغيرها.

لذلك يجب أن يعرض النظام الأم الحالة المركزية لهذه العمليات، ولا يُنقل تشغيلها إليه لمجرد زيادة عدد التبويبات.

## 4. Sales Returns — النتيجة الحاكمة

### هل نحتاج Sales Returns في النظام الأم؟

نعم.

لكن ليس كـCRUD منفصل لمرتجعات النظام الأم فقط، بل كـ**Central Sales Returns & Credit Notes Management View** يعرض كل المرتجعات التي نفذتها التطبيقات التشغيلية المنفصلة.

السبب التشغيلي:

```text
Return executed in field / POS
        ↓
Production transaction
        ↓
orders / order_details / runsheets
        ↓
stock movement
        ↓
credit note / accounting
        ↓
Parent System Sales Returns
```

وهذا يجعل التبويب أداة رقابة وإدارة ومراجعة، وليس محركًا موازيًا.

### هل نحتاج Purchase Returns؟

نعم، لكن **داخل إدارة المشتريات وليس داخل Sales**. يجب أن يكون له في النظام الأم مسار مستقل يعرض مرتجعات الموردين المنفذة من التطبيقات التشغيلية، مع المرجع إلى PO/Receiving/Supplier/Ledger.

## 5. Offers — أين مكان التحكم؟

الملف الحالي يحتوي بالفعل داخل Item Modal على حقول:

```text
discount_percent
discount_start
discount_end
is_daily_deal
badge_text
```

هذه مناسبة للتحكم **في عرض الصنف وتسعير/خصم الصنف المباشر**.

لكنها ليست Promotion Engine مؤسسيًا.

لا ينبغي تحويل Item Modal إلى محرك عروض شامل.

المعمارية الصحيحة:

```text
Item Modal
= item-level merchandising / quick offer fields

Sales Promotions Engine
= rules across item/category/customer/branch/date/quantity/priority/stacking
```

## 6. Daftra — Sales comparison (مراجعة خارجية محدثة)

الموقع الرسمي الحالي لدفترة يثبت وجود منظومة Sales تشمل الفواتير وعروض الأسعار، POS، العروض، الأقساط، المبيعات المستهدفة والعمولات، وقوائم الأسعار. كما يذكر خيارات دفع متنوعة وتقسيط وفاتورة مرتجعة/إشعارات ائتمان، إضافة إلى عروض وخصومات ولاء العملاء. citehttps://www.daftra.com/

دفترة يوضح أيضًا إمكانية إنشاء Quote وإرساله ثم تحويله إلى Invoice بعد الموافقة، ويدعم Price Lists مخصصة حسب العميل/المنتج/قناة البيع، ويقدم عروضًا زمنية وخصومات متنوعة، كما يدعم أهداف المبيعات والعمولات والأقساط والدفع الجزئي. citehttps://www.daftra.com/%D8%A8%D8%B1%D9%86%D8%A7%D9%85%D8%AC-%D8%A7%D9%84%D9%85%D8%A8%D9%8A%D8%B9%D8%A7%D8%AA-%D9%88%D8%A5%D8%AF%D8%A7%D8%B1%D8%A9-%D8%A7%D9%84%D9%81%D9%88%D8%A7%D8%AA%D9%8A%D8%B1/

الميزات الحالية المعروضة من دفترة تشمل Price Lists وOffers وInstallments وTargets/Commissions وLoyalty. citehttps://www.daftra.com/plans

### مقارنة

| المجال | RAWAEA الحالي | Daftra | الحكم |
|---|---|---|---|
| POS | موجود | موجود | متقارب |
| Telesales / Order workflows | موجود | موجود | RAWAEA قوي تشغيليًا |
| Sales Orders | موجود | موجود | متقارب |
| Runsheet/Field Fulfillment | متكامل مع التطبيقات التشغيلية | ليس بنفس النموذج المتخصص | **ميزة RAWAEA** |
| Quote | غير مكتمل | موجود | فجوة |
| Price Lists | غير موجود كـengine مستقل | موجود | فجوة |
| Promotions | Item-level/coupon foundations فقط | موجود | فجوة |
| Multiple/Partial Payment | لا يوجد Sales allocation contract كامل | موجود | فجوة |
| Installments | جداول فقط | موجود | فجوة |
| Commissions | غير موجود كـengine | موجود | فجوة |
| Targets | غير موجود كـengine | موجود | فجوة |
| Loyalty | table فقط | موجود | فجوة |
| Returns/Credit Notes | Backend atomic الآن، Parent UI ما زال مطلوبًا | موجود | Backend أغلق، UI مفتوح |
| Sales Analytics | تقارير أساسية موجودة | أوسع | فجوة متوسطة |

## 7. Production Sales Contracts — ما تم إثباته

Production الحالية تحتوي:

- `save_sales_invoice_atomic`
- `complete_return_atomic`
- `complete_order_delivery_atomic`
- `post_cash_payment_atomic`
- `delete_order_atomic`
- `submit_online_order_atomic`
- `append_orders_to_runsheet_atomic`

ولا توجد Production functions مستقلة مثبتة لـ Quote/Price List/Promotion/Commission/Target/Loyalty.

## 8. Closure تم تنفيذه فعليًا في Production — Sales Return + Credit Note

تم إنشاء contract جديد موحد:

`complete_sales_return_credit_note_atomic`

وظيفته:

1. التحقق من Company/User/Items.
2. توليد Operation Key حتمي.
3. إرجاع نفس Credit Note عند retry لنفس العملية.
4. استدعاء `complete_return_atomic` لتنفيذ Business Return.
5. الحفاظ على Physical Stock داخل `post_stock_movement`.
6. إنشاء Credit Note في نفس transaction.
7. تسجيل Audit للـCredit Note.

تم إضافة:

```text
credit_notes.operation_key
```

مع Unique Partial Index:

```text
(company_id, operation_key)
```

وتم حذف الـduplicate index الزائد على:

```text
orders(company_id, operation_id)
```

مع الإبقاء على index canonical واحد.

## 9. Edge Deployment — Current

تم نشر:

```text
create-credit-note = v3
complete-return    = v26
```

والاثنان JWT-protected ويستخرجان Company Context من `users.auth_id`، ثم يستدعيان الـtransaction الموحد.

بهذا أصبحت تطبيقات التشغيل التي تستدعي `complete-return`، وكذلك مسار `create-credit-note`، تستخدم نفس transaction boundary.

## 10. Production Runtime Verification

تم تنفيذ E2E transactional test حقيقي داخل Production باستخدام سجلات مؤقتة فقط:

1. إنشاء Order مؤقت.
2. إنشاء Order Detail حقيقي.
3. تنفيذ Sales Return بمقدار 1.
4. التحقق من نجاح العملية وإنشاء Credit Note.
5. إعادة نفس العملية حرفيًا.
6. التحقق من `duplicate=true` وإرجاع نفس Credit Note.
7. تنظيف جميع بيانات الاختبار.

نتيجة الاختبار الأول:

```text
success = true
duplicate = false
total_returned_value = 10
creditNoteCode = CN-970fb1d3d63653047774fb004ef64461
new_order_status = Partially Returned
```

نتيجة retry:

```text
success = true
duplicate = true
same creditNoteId
same creditNoteCode
same amount
```

بعد التنظيف:

```text
E2E order = 0
E2E credit note = 0
E2E inventory log = 0
E2E operation registry = 0
E2E audit actor test records = 0
```

إذن الاختبار لا يترك بيانات تشغيلية وهمية في Production.

## 11. ما لم يتم إغلاقه لأن frontend هو اختصاص المالك

### POS Idempotency

**الملف:**
`erp-frontend/companies/company-1/main.html`

**الدالة:** `RW_POS.save()`

**الموضع الحالي:** منطقة السطر **22750 تقريبًا**.

ابحث عن هذا المقطع الكامل داخل `RW_POS.save()`:

```javascript
var orderHeader = {
    operation_id: crypto.randomUUID(),
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

**احذفه كاملًا حتى آخر سطر `};` واستبدله كاملًا بهذا:**

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

ثم داخل نفس نجاح `RW_POS.save()`، **بعد سطر:**

```javascript
cart = [];
```

أضف مباشرة:

```javascript
window.__rwPosOperationId = null;
```

**مهم:** لا تضف تصفير Operation ID في catch/error.

### Telesales Idempotency

**الدالة:** `RW_TeleSales._saveOrder()`

**الموضع الحالي:** منطقة السطر **23740 تقريبًا**.

ابحث عن `var orderHeader = {` داخل `RW_TeleSales._saveOrder()` تحديدًا، ثم احذف الكتلة كاملة حتى آخر سطر `};` واستبدلها بـ:

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

ثم داخل نجاح `RW_TeleSales._saveOrder()`، **بعد تصفير السلة/العميل وقبل نهاية النجاح** أضف:

```javascript
window.__rwTeleSalesOperationId = null;
```

ولا تمسح Operation ID في مسار الخطأ.

## 12. لا تعيد إصلاح ما هو مغلق

لا تعدل الآن:

- Transfer branch_name fix.
- Inventory Writer Core.
- `post_stock_movement` المركزي.
- `complete_return_atomic` نفسه إلا بدليل جديد.
- `save_sales_invoice_atomic` لمجرد أن frontend idempotency يحتاج إصلاحًا.
- Runsheet/Picking/Loading/Delivery backend closures المغلقة سابقًا.

## 13. Quote / Price List / Promotion / Payment / Installment / Commission / Target / Loyalty

الحالة الحالية:

```text
Quote lifecycle                        = OPEN
Price List engine                      = OPEN
Promotion engine                       = OPEN
Unified Sales Return/Credit Note UI    = BACKEND CLOSED / UI OPEN
Multiple/Partial Sales Payments        = OPEN
Installment lifecycle                  = OPEN
Commission engine                      = OPEN
Targets engine                         = OPEN
Loyalty engine                         = OPEN
Full Sales Decision Center             = OPEN
Browser Click-by-Click E2E             = OPEN
```

### Quote lifecycle

لا توجد Production Quote table/engine مستقلة مثبتة. لا يجوز إضافة تبويب Quote شكلي فوق `orders` قبل إثبات عقد Quote مستقل أو اعتماد extension رسمي لنموذج الوثائق.

الهدف الوظيفي:

`Quote → Revision/Approval → Sales Order → Invoice`

### Price List engine

لا توجد حاليًا Price List contract مستقلة. المطلوب لاحقًا:

`Base Price + Customer/Group + Branch/Channel + Quantity Tier + Validity + Priority`

### Promotion engine

`coupons` الحالي لا يكفي. المطلوب لاحقًا:

`Percentage / Fixed / Qty Break / Buy-X-Get-Y / Item-Category-Customer scope / Date-Time / Priority / Stacking`

### Multiple/Partial Sales Payments

`post_cash_payment_atomic` موجود، لكنه ليس بمفرده Sales Allocation Engine مكتملًا. قبل UI يجب إثبات contract يربط عدة دفعات بالفاتورة، partial allocation، settlement، refund/reconciliation.

### Installment lifecycle

الجداول موجودة لكنها فارغة في Production الحالية. كما أن `installments` لا تحمل Company ID ولا FK مباشر مثبت إلى orders؛ لذلك لا يجوز بناء UI فوقها قبل إعادة بناء contract آمن.

### Commission / Targets

لا توجد Production engines مستقلة. المطلوب عقد periods/rules/employee-target/achievement/returns-impact/approval/payout.

### Loyalty

`loyalty_points` موجود لكنه بلا Company ID وبلا engine مثبت للـearn/redeem/expiry/rollback. لا يجوز اعتباره مكتملًا.

## 14. لماذا لا نكمل كل التبويبات الآن في دفعة واحدة؟

لأن الحوكمة تمنع إنشاء واجهات فوق Business Contracts غير مثبتة. Gold/Diamond ليس كثرة تبويبات؛ بل اكتمال:

`UI + Contract + Transaction + Security + Accounting + Realtime + Audit + E2E`

ولذلك فإن بناء Quote/Pricing/Promotions/Payments/Installments الآن بدون عقود Production سيكون **دينًا جديدًا** وليس استكمالًا.

## 15. Browser E2E

لم يتم الادعاء بإغلاق Click-by-Click Browser E2E؛ لا توجد في هذه الجلسة قناة Browser Automation متاحة.

تم تنفيذ ما يمكن إثباته بدون متصفح:

- Current Git/Parent
- Current Source SHA
- Current Production schema/data
- Current Edge versions/source
- Production runtime transactional E2E
- Retry/idempotency verification
- cleanup verification

وبالتالي:

```text
Browser Click-by-Click E2E = OPEN
```

ولا يجوز تحويل Production runtime verification إلى Browser PASS.

## 16. حالة `forensic_main_assembly.yml`

لا تعديل مطلوب.

المسار الحالي صحيح:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
```

## 17. ما تم تعديله فعليًا في هذه الجلسة

### Production

تم تنفيذ:

1. Migration `20260913_unify_sales_return_credit_note_atomic`.
2. إضافة `credit_notes.operation_key`.
3. إضافة uniqueness على operation key.
4. إنشاء `complete_sales_return_credit_note_atomic`.
5. حذف redundant orders operation index.
6. Deployment `create-credit-note` v3.
7. Deployment `complete-return` v26.
8. تنظيف بيانات E2E المؤقتة.

### Git

تمت كتابة canonical backend artifacts في `rawaie-erp-New`:

- `supabase/migrations/20260913_unify_sales_return_credit_note_atomic.sql`
- `Current/Edge_Functions/create-credit-note`
- `Current/Edge_Functions/complete-return`

### Parent main.html

**لم يتم تعديله بواسطة المساعد.**

## 18. Initial failures during execution

أثناء اختبار Purchase Receiving السابق ظهر أن idempotency لا يمكن بناؤه بشكل موثوق على `qty_received_before` وحده، وأن retry يحتاج Operation Identity ثابتة من العميل. لم يتم إخفاء هذا الخلل بالتحايل، ولم تتم إضافة عمود جديد عشوائيًا.

هذه الملاحظة تبقى مفتوحة لوحدة Purchase Receiving وليست جزءًا من Sales closure الحالي.

## 19. Final Self-Audit

### What I Proved

- HEAD وParent الحاليان من Git مباشرة.
- Source of Truth الحالي مطابق للـHEAD.
- `forensic_main_assembly.yml` صحيح.
- Production الحالية أعيدت مطابقتها.
- Sales navigation الحالية محدودة فعلًا.
- التطبيقات المنفصلة جزء من architecture وليست خطأ.
- Daftra يحتوي طبقات Sales المؤسسية التي ما زالت ناقصة لدينا.
- `complete_return_atomic` هو المحرك الحالي للمرتجعات.
- تم إنشاء Unified Sales Return + Credit Note transaction في Production.
- retry يعيد نفس Credit Note ولا يكرر الأثر.
- تم تنظيف سجلات الاختبار.

### What I Did Not Prove

- Browser click-by-click E2E.
- Quote contract.
- Price List engine.
- Promotion engine.
- Multiple/Partial Payment transaction contract.
- Installment engine.
- Commission/Targets engine.
- Loyalty engine.

### What I Fixed

- Unified return + credit note backend transaction.
- Production Edge routes to the unified transaction.
- Backend idempotency for Sales Return/Credit Note.
- Redundant order operation index cleanup.

### What I Initially Missed

الـCredit Note كانت Capability مستقلة عن Return transaction رغم وجود الاثنين في Production.

### What Could Still Be Wrong

- Browser runtime قد يكشف أخطاء DOM أو Console.
- Owner idempotency changes لم تُدمج بعد في current main.
- Parent UI لا يزال يحتاج Sales Returns management view.
- Purchase Receiving remains a separate closure unit.

### Final Confidence

```text
Current Git/Parent              = HIGH
Current Source                  = HIGH
Current Production/Data         = HIGH
Current Deployment Evidence     = HIGH
Sales Return/Credit backend     = CLOSED
Parent Sales Returns UI         = OPEN
Browser E2E                      = OPEN
Sales Gold/Diamond              = OPEN
```

## 20. تعليمات البداية للمساعد التالي

**لا تبدأ من Report161 كحالة حالية. استخدمه كـsearch pointer فقط.**

ابدأ بهذا التسلسل الحتمي:

```text
CURRENT GIT HEAD
→ DIRECT PARENT
→ NEW COMMITS AFTER THIS REPORT
→ CURRENT main.html SHA
→ CURRENT forensic_main_assembly.yml
→ CURRENT Production schema
→ CURRENT Production data
→ CURRENT Edge versions + source
→ CURRENT PostgreSQL RPC definitions
→ CURRENT runtime/log evidence
→ classify VERIFIED / STALE / CONTRADICTED / UNKNOWN
→ لا تعيد أي closure مغلق
→ افتح فقط آخر Closure مفتوح
→ نفذ وحدة واحدة
→ test
→ deploy
→ Production verify
→ runtime verify
→ audit/security verify
→ update report
→ update CURRENT_STATE
→ next unit
```

### Sales sequence

```text
1. Owner applies POS idempotency surgical block.
2. Owner applies Telesales idempotency surgical block.
3. Re-read CURRENT main.html.
4. Browser retry E2E.
5. Production orders.operation_id verification.
6. Close idempotency unit.
7. Open Sales Document / Quote contract.
8. Build Quote only after Production contract is proven.
9. Open Price List + Promotion together only after contract mapping.
10. Open Multiple/Partial Payments.
11. Open Installments.
12. Open Commissions + Targets.
13. Open Loyalty.
14. Build Sales Decision Center last.
```

### Permanent rule

```text
REPORT = pointer
PRIMARY SOURCE = authority
CURRENT PRODUCTION = truth
NO ASSUMPTION
NO SPECULATIVE UI
NO DUPLICATE ENGINE
NO CLOSED-CLOSURE REOPEN
ONE CLOSURE AT A TIME
```

## 21. Session end status

```text
Source of Truth                       = VERIFIED
Current Git / Parent                  = VERIFIED
forensic_main_assembly.yml            = VERIFIED / NO CHANGE
Sales Forensic Assessment             = COMPLETED
Sales Return + Credit Note Backend    = CLOSED
Sales Returns Parent UI               = OPEN
POS/Telesales Idempotency Owner Work  = OPEN
Quote / Pricing / Promotion           = OPEN
Payments / Installments               = OPEN
Commissions / Targets                 = OPEN
Loyalty / Decision Center             = OPEN
Browser Click-by-Click E2E            = OPEN
```

**انتهى Report161.**
