# Report159 — CTO Forensic E2E للنظام الأم — إدارة المبيعات مقابل دفترة

**التاريخ:** 2026-09-13  
**الحالة:** تنفيذ جنائي من الحالة الحالية فقط  
**Source of Truth للواجهة:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html` على `main`

---

## 0. الهدف الحاكم — يُقرأ بعناية ويُكرر هنا

**الهدف الأصلي ليس إكمال الشاشات شكليًا. الهدف هو أن يصبح النظام الأم مكتملًا وظيفيًا، وأن تكون إدارة المبيعات منظومة متماسكة قابلة للمنافسة، وليست مجرد هيكل يحتوي POS وتلي سيلز وأوردرات.**

في هذه المهمة لم يتم اعتبار التقارير التاريخية حالة حالية. كل استنتاج مقبول بُني على أحدث ما أمكن إثباته من:

`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

التقارير السابقة استُخدمت فقط كدلائل تحديد مواقع investigation، ثم أُعيد التحقق من الواقع الحالي.

---

## 1. CURRENT GIT — HEAD وParent

### `erp-frontend`

**HEAD الحالي:**
`3573c92026557cb56a7782babe6f6cf690243072`

**الرسالة:** `Update main.html`

**Direct Parent:**
`28f39b351bb44a4cd885ba784d505aadaeb13cf1`

تمت مراجعة Parent وHEAD. التغيير المعروف المرتبط بإصلاح Transfer صار مغلقًا بالفعل في HEAD الحالي، ولا يجوز إعادة إصلاحه دون evidence جديد.

### `rawaie-erp-New`

**HEAD الحالي:**
`861723e529e792258bdc84bff72f2ad4e5fee853`

**Direct Parent:**
`ca941e3cbd9a51d1b499620b48b541e8a1a9779d`

HEAD الأخير مخصص لتحديث CURRENT_STATE بعد Report158.

---

## 2. CURRENT SOURCE — النظام الأم الحالي

تم فحص الملف المنشور الحالي:

`companies/company-1/main.html`

وهو الملف المعتمد، وليس `Current/PWA/main2`.

الملف الحالي يحمل رأس:

`<!-- 2026-09-13 13:00 UTC -->`

كما أن CURRENT_STATE الحالي يثبت أن الملف تمت قراءته حتى EOF عند السطر `35521`.

### حالة forensic assembly

تمت مراجعة `forensic_main_assembly.yml` وثبت أن Source of Truth صحيح:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status: reference_only; published_main_is_authoritative
```

**القرار:** لا تعديل مطلوب في هذا الملف، لأنه صحيح بالفعل.

---

## 3. CURRENT PRODUCTION / DATABASE — المطابقة الحالية

Production Supabase:
`fiilmooggumokxanwiyx`

القراءة الحالية للـschema أثبتت أن قاعدة الإنتاج الحالية تختلف في الحجم عن بعض التقارير التاريخية، ولذلك لم يتم استخدام أعداد تاريخية كحالة حالية.

حقائق حالية مثبتة:

- `companies`: صف إنتاجي واحد.
- `branches`: صفان.
- `items`: 17.
- `customers`: 3.
- `orders`: 0.
- `runsheets`: 0.
- `stock_vouchers`: 0.
- `inventory_log`: 3.
- `credit_notes`: موجودة ككيان إنتاجي.
- `loyalty_points`: موجودة ككيان إنتاجي.
- `installments` و`installment_details`: موجودتان ككيانين إنتاجيين.
- `coupons`: موجودة ككيان إنتاجي.
- `fulfillment_backorders`: موجودة ككيان إنتاجي.
- `orders.operation_id`: موجود وحاكم لمسار idempotency على مستوى أمر المبيعات.

### Item Identity

`items.item_code` عليه `UNIQUE` constraint عالمي في schema الحالي.

هذا مهم جدًا في التقييم؛ لا يجوز بناء استنتاج جديد يقول إن `item_code` يجب أن يكون Company-scoped في هذه القاعدة، لأن الـschema الفعلي الحالي يقول إنه unique عالميًا.

---

## 4. CURRENT DEPLOYMENT EVIDENCE — مسارات المبيعات الحالية

### `save-sales-invoice`

**Production version:** 15  
**verify_jwt:** true

الـEdge Function الحالي يدعم operation identity عبر:

1. `body.operation_id`.
2. `orderHeader.operation_id`.
3. HTTP `Idempotency-Key`.
4. وإلا يولد UUID حتميًا من هوية المستخدم ومحتوى الطلب.

ثم يمرر العملية إلى:

`save_sales_invoice_atomic`

وهذا يعني أن طبقة Production الحالية لديها أساس حقيقي للـidempotent invoice save، وليس مجرد Frontend flag.

### `confirm-order`

**Production version:** 4  
**verify_jwt:** true

الـFunction الحالية:
- تستخرج `company_id` من المستخدم المرتبط بـAuth.
- تبحث عن الـorder داخل الشركة.
- تمنع التأكيد إذا كان مرتبطًا بـrunsheet.
- تسمح بتحويل Draft/Pending إلى Confirmed.

### `update-order`

**Production version السابق:** 2  
**Production version الحالي بعد إصلاح هذه الجلسة:** **3**

تم إصلاحه مباشرة في Production لأنه كان يحتوي على global lookups غير كافية للسياق في:
- order lookup.
- customer lookup.
- branch lookup.
- item lookup.

الإصدار الحالي يفرض company scope من المستخدم المصادق عليه ويمنع تكرار الصنف داخل الطلب ويربط item identity بالـglobal Item Master الحالي.

### `create-credit-note`

**Production version السابق:** 1  
**Production version الحالي بعد إصلاح هذه الجلسة:** **2**

تم إصلاحه مباشرة في Production لأنه كان:
- لا يفرض Company scope على order/runsheet.
- لا يسجل `company_id` داخل `credit_notes` على نحو صريح.
- لا يتحقق من أن order وrunsheet متوافقان مع نفس الشركة.
- لا يتحقق من أن الصنف المرجعي جزء من تفاصيل order قبل إنشاء الإشعار.

الإصدار 2 الحالي:
- يأخذ الشركة من المستخدم المصادق عليه.
- يبحث عن order وrunsheet داخل نفس الشركة.
- يطابق runsheet مع order.
- يتحقق من order_details قبل إنشاء credit note.
- يرفض المرتجع الذي يتجاوز الكمية المباعة.
- يكتب `company_id` في `credit_notes`.

**ملاحظة:** `create-credit-note` ما زال capability لإشعار دائن، وليس وحده محرك Physical Stock Return. محرك المرتجعات الفعلي الحالي موجود في `complete-return`، والذي يمرر العملية إلى `complete_return_atomic` وفق Deployment Evidence الحالية.

---

## 5. CURRENT SOURCE — ما هو موجود فعليًا في المبيعات

### Navigation الحالية

النص الفعلي الحالي في `RW_Navigation` هو:

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [
  { view: 'telesales', label: 'التلي سيلز' },
  { view: 'customers', label: 'العملاء' },
  { view: 'online-store', label: 'المتجر الإلكتروني' },
  { view: 'pos', label: 'نقطة البيع' },
  { view: 'orders', label: 'أوردرات المبيعات' },
  { view: 'runsheets', label: 'الرانشيتات' }
] }
```

### POS

يوجد `RW_POS`، ويتضمن:
- اختيار عميل.
- البحث عن صنف.
- السعر والكمية.
- إجمالي.
- ضريبة.
- رسوم توصيل.
- حفظ فاتورة.

لكن في مسار الحفظ الحالي داخل المصدر، يتم تكوين header بقيم:

```javascript
status: 'Invoiced',
paymentType: 'نقدي'
```

ويتم استدعاء:

`/functions/v1/save-sales-invoice`

### Telesales

يوجد `RW_TeleSales` ويحتوي على:
- البحث عن عميل.
- إنشاء عميل.
- البحث عن صنف.
- Cart.
- رسوم التوصيل.
- الضريبة.
- حفظ الأوردر.

### Orders

يوجد `RW_Orders` لإدارة أوردرات المبيعات والتأكيد والحذف وربطها بالرانشيت.

### Returns

لا يوجد في Sales Navigation الحالية view مستقل باسم مرتجعات المبيعات.  
المرتجعات الحالية داخل Navigation توجد تحت:

`إدارة المخازن والمخزون → العمليات المخزنية → المرتجعات`

وهذا يعكس أن مسار المرتجع موجود تشغيليًا، لكنه ليس مكشوفًا كـSales Return / Credit Note management داخل إدارة المبيعات نفسها.

### ما لم يثبت وجوده في CURRENT SOURCE

بحث مباشر في الملف الحالي لم يجد وظائف/تبويبات مستقلة تحمل:

- عروض الأسعار.
- قائمة الأسعار.
- عمولات المبيعات.
- أهداف المبيعات.
- أقساط المبيعات.
- واجهة برنامج ولاء.
- واجهة مستقلة لمرتجعات المبيعات/الإشعارات الدائنة.

كما لم يجد محرك عروض مبيعات مستقل؛ الموجود في `items` هو إعدادات تسويق على مستوى الصنف مثل:

- `discount_percent`
- `discount_start`
- `discount_end`
- `is_daily_deal`
- `badge_text`

وهذا ليس في حد ذاته Price List / Promotion Engine كامل.

---

## 6. مقارنة تدقيقية — RAWAEA مقابل دفترة في المبيعات فقط

| المجال | RAWAEA الحالي | دفترة | التقييم |
|---|---|---|---|
| POS | موجود | موجود | ✅ أساس قوي |
| Telesales | موجود | مدعوم ضمن منظومة البيع | ✅ |
| Customers | موجود | موجود | ✅ |
| Sales Orders | موجود كـorders operational | كيان واضح ضمن دورة المبيعات | ⚠️ يحتاج Contract أوضح |
| Quotes / Estimates | غير مثبت في CURRENT SOURCE | موجودة كمرحلة رسمية | 🔴 فجوة |
| Quote → Order | غير مثبت | مدعوم | 🔴 فجوة |
| Quote → Invoice | غير مثبت | مدعوم | 🔴 فجوة |
| Order → Invoice | backend identity/confirmation موجود، لكن تحويل UI رسمي غير مثبت | مدعوم | 🟠 فجوة UI/contract |
| Price Lists | غير مثبت | موجودة حسب العميل/المنتج/القناة | 🔴 فجوة |
| Promotions | توجد item-level discount fields فقط | نظام عروض مرن بفترات وشروط | 🔴 فجوة |
| Multiple Payments | CURRENT POS source لا يثبت ذلك | مدعوم | 🔴 فجوة |
| Partial Payment | غير مثبت في UI | مدعوم | 🔴 فجوة |
| Installments | schema موجود، UI/transaction contract غير مثبت | مدعوم | 🟠 backend foundation فقط |
| Sales Returns | return process موجود تشغيليًا خارج Sales menu | كامل/جزئي مع Refund | 🟠/🔴 واجهة المبيعات ناقصة |
| Credit Note | backend capability موجود ومُؤمّن الآن | مدعوم ضمن دورة المرتجع/المبيعات | 🟠 يحتاج UI حاكم |
| Sales Commission | غير مثبت | موجود | 🔴 فجوة |
| Sales Targets | غير مثبت | موجود | 🔴 فجوة |
| Loyalty | schema موجود، UI/contract غير مثبت | موجود | 🟠 foundation فقط |
| Sales Profit on document | التكلفة موجودة في backend، لكن UI document profit غير مثبت | متوفر | 🟠 |
| Sales reports | يوجد Smart Reports عامة | تقارير مبيعات تفصيلية | 🟠 يحتاج Sales reporting layer أوضح |
| Session reconciliation | يوجد settlement/financial infrastructure في النظام ككل | POS session management | 🟠 |
| Offline POS | توجد offline infrastructure في المشروع لكن لم تُثبت هنا كـsales browser E2E | مدعوم | 🟠 غير مثبت في هذه الجلسة |

دفترة توثق دورة مبيعات واضحة تسمح بالبدء مباشرة بفاتورة أو البدء بعرض سعر ثم تحويله إلى أمر بيع ثم فاتورة، مع إمكانية التحويل بين المستندات. citeturn105195search0turn105195search13

كما توثق دفترة قوائم الأسعار، العروض، العمولات والأهداف، نقاط الولاء، والأقساط ضمن منظومة المبيعات. citeturn105195search1turn105195search3

وتوثق كذلك في POS تعدد وسائل الدفع والدفع الجزئي، إضافة إلى المرتجعات الكلية والجزئية واسترداد المبالغ. citeturn105195search10turn105195search6turn105195search7

---

## 7. ما الذي ثبت أنه غير آمن لإكماله الآن

لا يجوز أن نستخدم أسماء جداول Production الحالية كي نخترع UI وعقودًا غير مثبتة.

مثلًا:

وجود:
- `installments`
- `loyalty_points`
- `coupons`
- `credit_notes`

لا يثبت وحده:
- كيف تُنشأ المعاملة.
- من يملكها.
- ما الـworkflow.
- كيف تؤثر على journal/ledger.
- ما الـidempotency contract.
- ما الصلاحيات.
- هل هي جزء من UI النظام الأم أم application مستقل.

لذلك لم يتم إنشاء Quotes/Price Lists/Commissions/Installments UI من الصفر في هذه الجلسة؛ لأن ذلك سيكون خرقًا مباشرًا لمبدأ الحوكمة: **لا تعديل بلا عقد مثبت**.

---

## 8. E2E الحقيقي — ما تم وما لم يتم

### تم التحقق

- CURRENT Git HEAD وDirect Parent.
- CURRENT SOURCE في `erp-frontend`.
- CURRENT database schema وrow counts.
- CURRENT Edge Function deployments والإصدارات.
- Production security hardening لمسارين sales-related: `update-order` و`create-credit-note`.

### لم يتم التحقق

**Browser click-by-click E2E في المتصفح لم يُنفذ في هذه البيئة** لأن هذه الجلسة لا توفر Browser Automation channel.

لذلك لا يجوز كتابة:

`BROWSER E2E PASS`

ولا:

`GOLD/Diamond sales = 100%`

هذه دعوى غير مثبتة.

---

## 9. Production changes executed in this session

### Change 1 — `update-order`

Current Production version:
`3`

الغرض:
إغلاق Tenant/Item identity leakage وعدم السماح لطلب تحديث أن يبحث خارج الشركة الحالية أو يخزن Item identity غير مثبتة.

### Change 2 — `create-credit-note`

Current Production version:
`2`

الغرض:
إغلاق Company scope وربط order/runsheet/detail context قبل إنشاء الإشعار الدائن.

### Business data

لم يتم تنفيذ تنظيف أو اختلاق Production business data لتجميل نتيجة الاختبار.

---

## 10. Frontend surgical changes — ما يجب أن ينفذه المالك في `erp-frontend/companies/company-1/main.html`

**هذه التعليمات لا تنفذ في هذا المستودع بواسطة CTO. المالك هو من يحرر النظام الأم.**

### FRONTEND CHANGE A — كشف المرتجعات داخل إدارة المبيعات

**ابحث عن العنصر الفعلي:**

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [{ view: 'telesales', label: 'التلي سيلز' }, { view: 'customers', label: 'العملاء' }, { view: 'online-store', label: 'المتجر الإلكتروني' }, { view: 'pos', label: 'نقطة البيع' }, { view: 'orders', label: 'أوردرات المبيعات' }, { view: 'runsheets', label: 'الرانشيتات' }] }
```

**احذف هذا العنصر كاملًا واستبدله بالآتي فقط بعد أن يكون Sales Return view قد تم ربطه بالـproduction return contract:**

```javascript
{ icon: 'fa-chart-line', label: 'إدارة المبيعات', submenu: [
  { view: 'telesales', label: 'التلي سيلز' },
  { view: 'customers', label: 'العملاء' },
  { view: 'online-store', label: 'المتجر الإلكتروني' },
  { view: 'pos', label: 'نقطة البيع' },
  { view: 'orders', label: 'أوردرات المبيعات' },
  { view: 'sales-returns', label: 'مرتجعات وإشعارات دائنة' },
  { view: 'runsheets', label: 'الرانشيتات' }
] }
```

**مهم:** لا تضف هذا السطر وحده ثم تترك view غير موجودة. هذا التعديل يتطلب إنشاء view/function حقيقية في نفس الملف.

### لماذا لم أقدم view جديدة كاملة هنا؟

لأن `complete-return` في Production الحالي يعتمد على `complete_return_atomic`، وعقد هذا الـRPC الحالي لم يتم استخراج تعريفه من Production في هذه الجلسة بواسطة أداة SQL المتاحة. بناء Modal جديد من تخمين payload سيكون أخطر من ترك الـUI الحالي حتى يتم إغلاق Evidence gap.

---

## 11. FRONTEND CHANGE B — POS payment model

**لم يتم إصدار patch جراحي مباشر لهذا الجزء في هذه الجلسة.**

سبب القرار ليس تقنيًا ضعيفًا، بل Governance:

CURRENT SOURCE يثبت `paymentType: 'نقدي'` في مسار الحفظ، بينما Production يحتوي على `amount_paid` وFinancial cores وpayment tables، لكن لا يوجد في current evidence هنا عقد موحد مثبت للـsplit-payment UI.

لذلك لا يجوز اختراع:
- cash/card/check allocation;
- partial amount;
- payment lines;
- reconciliation logic;

ثم نربطها بفاتورة Production دون إثبات الـfinancial contract أولًا.

---

## 12. FRONTEND CHANGE C — Quotes / Sales Orders / Price Lists / Promotions

هذه العناصر **لا تُضاف إلى main.html الآن بمجرد HTML**.

الـclosure الصحيح القادم يجب أن ينشئ أولًا contract مثبت في Production/Git لكل capability:

```text
Quote
  ↓ approve
Sales Order
  ↓ fulfill / invoice
Invoice
```

مع:

```text
Price List
Promotion Rules
Sales Rep
Commission Rule
Target Period
```

وبعدها فقط تضاف UI views/modals إلى `main.html`.

هذا ليس تأخيرًا؛ بل منعنا أن ننتج UI جميلًا فوق Business Logic غير محسوم.

---

## 13. SALES GOLD/DIAMOND GAP — النتيجة المهنية

### ما تحقق

RAWAEA لديه أساس عملي ومميز:

- POS.
- Telesales.
- Customers.
- Online Store.
- Sales Orders.
- Runsheet integration.
- Fulfillment lifecycle.
- Branch / Stock integration.
- Financial infrastructure.
- Idempotent invoice save foundation.

### ما ينقص حتى تصبح Sales منظومة مكتملة منافسة

الأولوية الأولى ليست إضافة 20 tab.

الأولوية هي بناء **Sales Document & Pricing Contract** موحد يسمح للنظام أن يتعامل مع:

`Quote → Sales Order → Invoice → Payment → Return/Credit Note`

ويربطها مع:

`Customer + Sales Rep + Price List + Promotion + Inventory + Accounting + Fulfillment`

ثم تأتي واجهات:

- Quotes.
- Sales Orders management بمعناها المؤسسي.
- Price Lists.
- Promotions.
- Returns/Credit Notes.
- Installments.
- Multiple/Partial Payments.
- Commissions & Targets.
- Loyalty.
- Sales-specific analytics.

هذه هي الفجوة الحقيقية، وليست مجرد زر أو modal.

---

## 14. أخطاء/تجارب هذه الجلسة

### تجربة فاشلة — attempt سابق على Receive Purchase

في التحقيق السابق ظهر أن اختبار retry على `receive_purchase_atomic` لم يثبت idempotency بالشكل المطلوب، لأن ترتيب guards وoperation identity كان يحتاج مراجعة. لا يُعاد استخدام تلك التجربة كحالة Production حالية دون إعادة تحقق.

### ما نجح

- current Git reconciliation.
- current main source inspection.
- current DB schema enumeration.
- current deployment inspection.
- security hardening of `update-order` to version 3.
- security hardening of `create-credit-note` to version 2.

### ما لم ينجح/لم يثبت

- Browser click-by-click E2E.
- Sales Gold/Diamond completion.
- end-to-end UI proof for Quotes/Price Lists/Payments/Installments/Commissions/Loyalty.

---

## 15. لا يوجد Patch ترميمي للمبيعات الآن

هذا القرار مقصود.

لم يتم تعديل `erp-frontend/companies/company-1/main.html` من CTO.

لم يتم الرجوع إلى `Current/PWA/main2` كمصدر تنفيذ.

لم يتم اختراع جداول أو RPCs للمبيعات.

لم يتم تعديل Business Logic التاريخي لدورة الأوردر/الرانشيت/التوصيل.

السبب: هذه المكونات هي من أهم أصول RAWAEA ولا يجوز العبث بها دون Reconstruction مثبت.

---

## 16. CURRENT STATE بعد هذه الجلسة

### Current Truth

`erp-frontend/companies/company-1/main.html` هو Source of Truth للواجهة.

`rawaie-erp-New` هو سجل governance/backend artifacts، وليس بديلًا عن ملف النظام الأم.

### Current Production sales-related deployment

- `save-sales-invoice` v15
- `confirm-order` v4
- `update-order` v3 ← **updated in this session**
- `create-credit-note` v2 ← **updated in this session**
- `complete-return` v25

### Production schema foundations

- `orders.operation_id`
- `credit_notes`
- `installments`
- `installment_details`
- `loyalty_points`
- `coupons`
- `fulfillment_backorders`

لا تعتبر هذه foundations مكتملة UI/transaction contracts حتى يتم إثبات ذلك.

---

# 17. FINAL SELF-AUDIT

## What I Proved

1. Source of Truth الحالي صحيح ولم يتغير.
2. HEAD وDirect Parent تمت مراجعتهما.
3. `main.html` الحالي يحتوي بالفعل POS/Telesales/Customers/Online Store/Orders/Runsheets.
4. Production الحالي يحتوي foundations إضافية للمبيعات مثل credit notes/installments/loyalty/coupons.
5. Sales module الحالي ليس مساويًا بعد لدورة مبيعات مؤسسية كاملة مثل دفترة.
6. `update-order` كان يحتاج Company/Item hardening وتم إصلاحه في Production إلى v3.
7. `create-credit-note` كان يحتاج Company/Order/Runsheet/Detail hardening وتم إصلاحه في Production إلى v2.
8. `forensic_main_assembly.yml` صحيح ولا يحتاج تعديل.
9. Browser E2E لم يُثبت في هذه البيئة.

## What I Did Not Prove

1. أن جميع Sales tabs الحالية تعمل click-by-click في browser.
2. أن Quotes/Price Lists/Commissions/Targets/Installments/Loyalty أصبحت مكتملة.
3. أن `complete_return_atomic` عقده الحالي يسمح ببناء Sales Return UI جديد دون استخراج التعريف الفعلي.
4. أن كل Production sales edge/function مصدره canonical Git الحالي؛ بعض functions المنشورة لا يظهر لها مسار source مطابق في بحث `rawaie-erp-New` الحالي.

## What I Fixed

- `update-order` Production → v3.
- `create-credit-note` Production → v2.

## What I Initially Risked Missing

وجود foundations في Production قد يوحي أنها complete capabilities. تم رفض هذا الاستنتاج. وجود table لا يساوي وجود business contract + UI + security + accounting + E2E.

## What Could Still Be Wrong

- Browser runtime could expose UI errors not visible in static source.
- Some existing sales flows may be implemented under generic views/functions rather than explicit names.
- Current Edge-to-Git source parity needs a separate forensic closure.

## Final Confidence

**High for the static/Production evidence conclusions recorded here.**

**Not sufficient for Browser E2E PASS.**

## Final Closure Status

```text
SALES FORENSIC COMPARISON = CLOSED
SALES FUNCTIONAL GOLD/DIAMOND = OPEN
BROWSER E2E = OPEN
SALES DOCUMENT CONTRACT = OPEN
SALES PRICING CONTRACT = OPEN
SALES PAYMENT CONTRACT = OPEN
```

---

# 18. تعليمات بداية الجلسة القادمة — للمساعد/CTO التالي

**لا تبدأ من هذا التقرير باعتباره حقيقة. ابدأ من الواقع بالطريقة التالية:**

```text
1. CURRENT GIT HEAD
   ↓
2. DIRECT PARENT
   ↓
3. PARENT OF PARENT إذا كان التغيير ماديًا
   ↓
4. CURRENT SOURCE OF TRUTH
   ↓
5. CURRENT DATABASE SCHEMA
   ↓
6. CURRENT DATABASE DATA
   ↓
7. CURRENT EDGE DEPLOYMENTS + VERSION + SOURCE
   ↓
8. CURRENT RUNTIME / LOG EVIDENCE
   ↓
9. REPRODUCE THE EXACT SALES SYMPTOM
   ↓
10. TRACE THE EXACT CONSUMER
   ↓
11. TRACE THE EXACT RPC / EDGE / TABLE CONTRACT
   ↓
12. OPEN HISTORICAL SOURCES فقط لتفسير لماذا أصبح العقد كذلك
   ↓
13. DEFINE ONE SALES CLOSURE UNIT
   ↓
14. SURGICAL CHANGE ONLY
   ↓
15. PRODUCTION VERIFY
   ↓
16. RUNTIME VERIFY
   ↓
17. UPDATE REPORT + CURRENT_STATE
   ↓
18. ONLY THEN MOVE TO NEXT SALES CLOSURE
```

### ترتيب الـSales closures المقترح

**Closure S1 — Sales Document Contract**

أثبت أولًا هل `orders` هو فعلاً Sales Order contract الحالي، وما علاقته بالفاتورة، والـrunsheet، والـinvoice status، والـoperation_id.

**Closure S2 — Returns / Credit Note Contract**

استخرج تعريف `complete_return_atomic` الفعلي من Production، ثم طابقه مع `complete-return` و`create-credit-note`، ثم أبنِ UI موحدة للـSales Return/Refund دون إعادة اختراع fulfillment return.

**Closure S3 — Pricing / Price List / Promotion Contract**

ابحث في Production وGit عن contract حقيقي، ثم أنشئ price decision layer بدل hard-coded item sales price.

**Closure S4 — Payment Contract**

ثبت current payment/accounting contract للمبيعات، ثم نفّذ multiple/partial payments إن كانت الرؤية المعتمدة تسمح بذلك.

**Closure S5 — Installment Contract**

لا تستخدم tables وحدها. أثبت lifecycle وledger/reconciliation ثم اربط UI.

**Closure S6 — Commission / Target Contract**

ثبّت تعريف Sales Rep performance، target period، commission calculation، approval/payment state.

**Closure S7 — Loyalty Contract**

حدد earn/redeem/expiry/source/reference وربطه بالمبيعات والمرتجعات قبل UI.

**Closure S8 — Sales Analytics**

بعد اكتمال الوثائق والعقود، ابنِ مخرجات Sales-specific: sales by customer, rep, item, branch, margin, returns, outstanding, conversion.

---

# 19. القاعدة النهائية للمساعد القادم

**لا تعتبر Sales مكتملة لأن POS يعمل.**

**ولا تعتبر جدولًا موجودًا capability مكتملة.**

**ولا تعتبر Backend PASS = Browser PASS.**

**ولا تعتبر تقريرًا سابقًا Current State.**

**ولا تعدل `main2` أو أي ملف تاريخي لإصلاح Source of Truth.**

**ولا تعيد إصلاح Transfer أو Inventory Core أو أي Closure ثبت إغلاقه، إلا إذا ظهر evidence جديد من CURRENT SOURCE/PRODUCTION.**

**المبدأ:**

`FACT → CONTRACT → GAP → SURGICAL FIX → PRODUCTION VERIFY → RUNTIME VERIFY → CLOSE`

ولا تنتقل إلى `NEXT CLOSURE` قبل إغلاق الحالية بالكامل.
