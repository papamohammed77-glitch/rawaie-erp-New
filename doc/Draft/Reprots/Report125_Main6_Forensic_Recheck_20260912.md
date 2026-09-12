# تقرير 125 — المراجعة الجنائية وإعادة فحص Main6
## RAWAEA ERP — Main6 Online Store / Purchases — 2026-09-12

> ## الهدف الحاكم — يجب قراءته أولًا
> هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.
>
> وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.
>
> **والهدف نفسه يتكرر هنا صراحة:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. المطلوب استكمالها **وظيفيًا** حتى تصبح منافسًا حقيقيًا للأنظمة المنافسة، وليس مجرد استكمال شكلي للواجهات.

---

## 1. نطاق الجلسة

تم إيقاف مسار الإصلاح السابق، وإعادة بناء الحالة لهذا الطلب فقط.

نطاق العمل:

- `Current/PWA/main2/main6.md`
- التاريخ `Original/PWA/main/main6.md` مرجع لفهم العقد السابق فقط.
- `CURRENT_STATE.md`
- `forensic_main_assembly.yml`
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `doc/Draft/Reprots/Report124_Main5_Forensic_Recheck_20260912.md`
- Production Supabase للـRPCs والـEdge Functions التي يعتمد عليها Main6.

لم يتم تعديل:

- `Current/PWA/main2/main6.md`؛ لأن تعديلات أجزاء النظام الأم من اختصاص المالك.
- `Current/PWA/main`
- `Current/PWA/New-main`
- `Original/PWA/main/main6.md`
- `forensic_main_assembly.yml`؛ لأنه مثبت حاليًا على المسار الصحيح.

---

## 2. إعادة بناء الحالة الحالية من المصادر الأولية

### 2.1 الحوكمة

تم فتح ملف:

`doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`

والقاعدة الحاكمة المثبتة منه:

`REPORT ≠ CURRENT STATE`

و:

`NO EVIDENCE = NO CLAIM`

و:

`NO FULL READ = NO FULL READ`

كما أن كل Closure Unit يجب أن تمر بـ:

`START → DISCOVERY → ROOT CAUSE → DESIGN → IMPLEMENTATION → TEST → DEPLOYMENT → PRODUCTION VERIFICATION → DATA VERIFICATION → DOCUMENTATION → CLOSED`

### 2.2 الحالة السابقة

تم فتح `CURRENT_STATE.md` مباشرة.

تبين أن جزء Main5 في ملف الحالة كان يحمل SHA تاريخية أقدم من الحالية في Git؛ لذلك تم التعامل مع هذا البند كـSTALE أثناء إعادة البناء وعدم استخدامه كحقيقة حالية.

### 2.3 Assembly Source

تم فحص `forensic_main_assembly.yml` مباشرة، وهو صحيح حاليًا:

```text
source_of_truth: Current/PWA/main2
historical_reference: Original/PWA/main
forbidden_sources:
  - Current/PWA/main
  - Current/PWA/New-main
```

ولا يوجد دليل يستوجب تغييره في هذه الجلسة.

---

# 3. Main6 — القراءة الكاملة

المصدر الحالي:

`Current/PWA/main2/main6.md`

Current Git SHA:

`3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`

الحجم:

`29,172 bytes`

القراءة المتسلسلة وصلت إلى EOF.

آخر نطاق مصدر فعلي:

```javascript
window.RW_Purchases = RW_Purchases;
```

وبعد ذلك تمت إعادة القراءة عند نطاقات ما بعد النهاية للتأكد من عدم وجود محتوى إضافي؛ النتائج كانت فارغة.

الملف الحالي يحتوي وحدتين رئيسيتين:

1. `RW_OnlineStore`
2. `RW_Purchases`

ولا يوجد نص `(قيد التطوير)` مثبت في المصدر الحالي.

لكن غياب العبارة لا يعني اكتمال Gold/Diamond.

---

# 4. Historical Reconstruction — Original Main6

تم فتح:

`Original/PWA/main/main6.md`

النسخة الأصلية تؤكد أن Main6 تاريخيًا مسؤول عن محورين:

```text
Online Store
Purchasing / Purchase Receiving
```

كما تثبت أن النسخة القديمة كانت تحتوي على Lookup عالمي لـ`app_settings` بدون company scope في المتجر، وأن تتبع الطلب كان غير company-scoped.

هذه الملاحظات لا تعني إعادة القديم؛ بل تثبت أن Current بالفعل أدخل بعض التحسينات التاريخية، وتم الحفاظ عليها وعدم الرجوع إلى الأصل.

---

# 5. Production Reconstruction — Online Store

تم فحص Production الحالية مباشرة.

## `submit-online-order`

Production:

- Version `9`
- ACTIVE
- JWT required

ويستدعي:

`submit_online_order_atomic`

العقد الحالي المثبت في Production:

- `p_company_id` مطلوب.
- `p_operation_id` مطلوب.
- الطلب المكرر بنفس `company_id + operation_id` يعاد بنتيجة `duplicate=true`.
- الإعدادات `delivery_fee / tax_rate / min_invoice_amount` تؤخذ company-scoped.
- العميل company-scoped.
- Item Master يعتمد على `item_code` العالمي المثبت بالـSchema.
- `max_qty_per_order` يتم فرضه داخل الـRPC.
- السعر المحاسبي للطلب يؤخذ من `items.sales_price` داخل الـRPC، وليس من قيمة العميل المرسلة.

### الاستنتاج
Production توفر العقد المطلوب لاستقبال `operation_id` صريحًا من Main6، ولذلك لا توجد حاجة لتغيير الـRPC نفسه لهذا الإصلاح.

---

# 6. Main6 — Defects Proven in Current Source

## MAIN6-N1 — Online Order Operation Identity

الموضع داخل `RW_OnlineStore.showCart()`.

السلوك الحالي:

```javascript
body: JSON.stringify({ user: user, cartItems: arr, total: total, delivery: del })
```

ولا يوجد:

- `operation_id`
- `Idempotency-Key`

وهذا يجعل Production Edge يولد UUID عشوائيًا عند غياب العملية الصريحة.

### الخطر المثبت
إعادة إرسال نفس الطلب بعد انقطاع الشبكة ليست مضمونة الهوية من واجهة Main6.

### الإصلاح
ملف الاستبدال الكامل:

`doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_OnlineStore_20260912.js`

التصحيح فيه:

- `pendingOperationId` يحتفظ بهوية العملية حتى النجاح.
- إرسال `operation_id` في Body.
- إرسال `Idempotency-Key` في Header.
- عدم إسقاط هوية العملية عند فشل الاتصال.
- تصفير الهوية فقط بعد نجاح العملية.

---

## MAIN6-N2 — Online Store ignores existing discount contract

Production Schema يثبت وجود:

- `discount_percent`
- `discount_start`
- `discount_end`
- `is_daily_deal`
- `badge_text`
- `max_qty_per_order`

لكن Main6 الحالي يعرض `sales_price` مباشرة ولا يطبق `discount_percent` المؤهل زمنيًا.

### الإصلاح
تم إدخال حساب `effectivePrice()` في replacement.

مهم: هذا التغيير يخص **عرض UI فقط**. لم يتم تغيير `submit_online_order_atomic` ليغير الحساب النهائي؛ لأن الـRPC الحالي هو صاحب الحساب النهائي للسعر، ولذلك لم يتم خلق Backend Contract جديد بالتخمين.

---

## MAIN6-N3 — Online Store ignores `min_invoice_amount` in UI

Production `submit_online_order_atomic` يفرض الحد الأدنى.

Main6 الحالي لا يجلب هذا المتغير إلى الواجهة، ولا يعطي المستخدم validation قبل الإرسال.

### الإصلاح
replacement يجلب:

```text
delivery_fee
 tax_rate
 min_invoice_amount
```

ويعرض الحد الأدنى ويمنع الإرسال من الواجهة عندما يكون الإجمالي أقل منه.

الـBackend يبقى authoritative.

---

## MAIN6-N4 — Online Cart does not honor `max_qty_per_order` client-side

الـRPC يفرض `max_qty_per_order` بالفعل.

Main6 الحالي يسمح للمستخدم برفع الكمية بلا حد إلى أن يرفضها Backend.

### الإصلاح
replacement يفرض الحد في:

- Add to cart.
- Increment.
- Product display.

وهذا تحسين UX وليس بديلًا عن Backend validation.

---

## MAIN6-N5 — Online Store output escaping inconsistency

الملف الحالي يملك `esc()` لكنه يستخدمه بصورة غير متسقة.

توجد حقول مثل اسم الصنف والوصف والقيم المعروضة داخل HTML بدون contract موحد للإخراج.

### الإصلاح
replacement يستخدم:

- `esc()` للإخراج HTML.
- `escJs()` لقيم inline handlers.

ولم يتم تغيير `safeHTML()` أو أي Core utility خارجي.

---

# 7. Production Reconstruction — Purchasing

تم فحص Production:

## `save-purchase-order`

Production:

- Version `3`
- ACTIVE
- JWT required

ويستدعي:

`save_purchase_order_atomic`

العقد المثبت:

```text
p_supplier_id uuid
p_items jsonb
```

والـRPC:

- يثبت Supplier داخل `company_id`.
- يستخدم `supplier.id` كهوية المورد.
- يبحث عن Item Master بالـ`item_code` العالمي.
- يخزن `qty` و`unit_price` في `purchase_order_details`.

## `receive-purchase`

Production:

- Version `12`
- ACTIVE
- JWT required

ويستدعي:

`receive_purchase_atomic`

مع:

`p_operation_id uuid`

ويستخدم `receiving.operation_id` كهوية UNIQUE للعملية.

### الاستنتاج
Production Contracts المطلوبة موجودة بالفعل؛ المطلوب الأساسي في Main6 هو جعل الواجهة تستخدمها بصورة صحيحة وثابتة، وليس إعادة بناء الـRPC.

---

# 8. Main6 — Purchasing Defects Proven

## MAIN6-N6 — Supplier identity is wrong in current CREATE UI

في Main6 الحالي:

```javascript
<option value="supplier_code">...</option>
```

بينما Production `save_purchase_order_atomic` يتطلب:

```text
supplier_id uuid
```

وهذا Defect حقيقي.

### الإصلاح
replacement يستخدم:

```text
supplier.id
```

كقيمة `<option>`، ثم يرسل هذا UUID إلى Edge.

---

## MAIN6-N7 — Purchase price uses sales price

Main6 الحالي يضيف العنصر إلى Cart باستخدام:

```javascript
Number(item.sales_price)
```

وهذا ليس السعر الصحيح لأمر الشراء.

Production `purchase_order_details.unit_price` هو سعر الشراء الفعلي المُدخل.

### الإصلاح
replacement يستخدم:

```javascript
Number(item.cost_price)
```

مع إمكانية تعديل سعر الشراء داخل السطر قبل الحفظ.

---

## MAIN6-N8 — Item search is too weak

Main6 الحالي يبحث بالاسم فقط.

### الإصلاح
replacement يدعم:

- الاسم.
- `item_code`.
- `barcode`.

مع إظهار الكود والباركود عند وجوده.

---

## MAIN6-N9 — Purchase Orders list is structurally thin

Current Main6 يعرض قائمة أوامر شراء فقط.

لا توجد:

- Search.
- Status filter.
- Summary count.
- Detailed order viewer.
- واضح للمستلم/المتبقي في القائمة.

### الإصلاح الوظيفي
replacement يضيف:

- بحث برقم الأمر أو المورد.
- فلترة بالحالة.
- تفاصيل الأمر.
- تفاصيل المطلوب/المستلم/المتبقي.
- فتح دورة الاستلام من القائمة.

هذا جزء من هدف Gold/Diamond الوظيفي، وليس تجميلًا بصريًا فقط.

---

## MAIN6-N10 — Receive screen lacks receiving history visibility

Main6 الحالي يعرض فقط:

```text
المطلوب
المستلم الآن
```

ولا يجعل:

```text
المستلم سابقًا
المتبقي
سبب/ملاحظة
```

واضحة أثناء التنفيذ.

### الإصلاح
replacement يعرض:

- المطلوب.
- المستلم حتى اللحظة.
- المتبقي.
- الاستلام الآن.
- سبب/ملاحظة لكل سطر.

---

## MAIN6-N11 — Receive operation identity

Main6 الحالي يولد:

```javascript
crypto.randomUUID()
```

داخل submit handler.

هذا أفضل من غياب الهوية، لكنه لا يجعل الهوية قابلة لإعادة البناء بعد خروج المستخدم من العملية أو إعادة فتحها.

### قرار الحوكمة
لم يتم اختراع deterministic hash جديد.

تم الإبقاء على explicit UUID للعملية داخل نفس execution attempt، لأن Production نفسها تستخدم `receiving.operation_id` كهوية عملية UNIQUE.

أما persistence عبر إعادة فتح الشاشة فهي مسألة أوسع تخص offline/outbox workflow، ولم يُثبت عقدها التاريخي في Main6 بما يكفي لإنشائه بالتخمين داخل هذه الجلسة.

---

# 9. Main6 — Owner Surgical Instructions

## MAIN6-O1 — Replace `RW_OnlineStore` بالكامل

**FILE:**

`Current/PWA/main2/main6.md`

**CURRENT LOCATION:**

السطر `1` حتى السطر `269`.

**احذف المقطع كاملًا:**

```text
من أول سطر في الملف:
// ============================================================
```

**حتى آخر سطر للمقطع:**

```javascript
window.RW_OnlineStore = RW_OnlineStore;
```

لا تحذف أي شيء بعد هذا السطر.

**استبدله كاملًا بمحتوى الملف:**

`doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_OnlineStore_20260912.js`

---

## MAIN6-O2 — Replace `RW_Purchases` بالكامل

**FILE:**

`Current/PWA/main2/main6.md`

**CURRENT LOCATION:**

من السطر `270` حتى السطر `439`.

**احذف المقطع كاملًا:**

من:

```javascript
// RW_Purchases – المشتريات (أمر شراء + استلام)
```

حتى آخر سطر:

```javascript
window.RW_Purchases = RW_Purchases;
```

لا تحذف أي شيء قبل بداية هذا المقطع.

**استبدله كاملًا بمحتوى الملف:**

`doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_Purchases_20260912.js`

---

# 10. Syntax Validation

تم إنشاء بديلين كاملين مطابقين لحدود الوحدتين.

تم تشغيل:

```text
node --check MAIN6_OWNER_REPLACEMENT_OnlineStore_20260912.js
node --check MAIN6_OWNER_REPLACEMENT_Purchases_20260912.js
```

النتيجة:

```text
SYNTAX_OK
```

### Current Source Syntax Gate

لم يتم الادعاء أن الـcurrent `main6.md` نفسه أصبح Syntax PASS بعد التعديل؛ لأنه لم يتم تغييره بعد من المالك.

النتيجة الصحيحة الحالية:

```text
CURRENT MAIN6 = NOT MODIFIED
OWNER REPLACEMENT MODULES = SYNTAX PASS
FINAL MAIN6 = PENDING OWNER APPLY
```

---

# 11. Production Changes

**لا توجد Production changes جديدة في هذه الجلسة.**

السبب ليس التوقف؛ بل لأن التحقيق أثبت أن Production Contracts اللازمة لهذه الإصلاحات موجودة بالفعل:

- `submit_online_order_atomic` يقبل `operation_id` ويطبقه كidempotency.
- `save_purchase_order_atomic` يأخذ `supplier_id uuid` ويثبت Supplier داخل company.
- `receive_purchase_atomic` يقبل `operation_id uuid` ويستخدم `receiving.operation_id` كهوية UNIQUE.

لذلك كان إجراء Production الصحيح هو **عدم تغيير Backend بدون دليل**، وإصلاح الـowner source لاستخدام العقود الموجودة.

هذا يتفق مع قاعدة:

```text
لا نعدل Production لمجرد أن UI لا يستخدم العقد الصحيح.
```

---

# 12. Data Safety

لم يتم حذف أو إعادة كتابة أي Business Data في Production بسبب Main6.

لم يتم إنشاء Test Business Records دائمة.

لم يتم تنظيف أو دمج بيانات `items.company_id` رغم وجود حالات cross-company في Production من جلسة سابقة؛ لأن تلك المهمة أُوقفت ولا علاقة لها مباشرة بإغلاق Main6.

---

# 13. Main2 Match Gate

تم فحص مجلد:

`Current/PWA/main2/`

وتأكد وجود:

```text
main1.md
main2.md
main3.md
main4.md
main5.md
main6.md
main7.md
main8.md
main9.md
main10.md
main11.md
```

Current SHA المعروفة وقت هذه الجلسة:

```text
main1  f68d47c7574c34f678cfba2aafa5ad294aadbfe5
main2  65815e23b03e29c125957e6fe283cc1e253a7f7d
main3  eeb56daf8cd01b31b8a7e5f5ada4f1a09df30bfe
main4  e9f967859aeda729cd0811739a280ceec5266d7c
main5  800ad51c88a2e80d060480990836a3c975c7435a
main6  3b20758459c28ab0b6c055f9a0ad3992f1bd07e5
main7  a65969f6bdc919d4a8d62a6704a7c556b7d35e91
main8  2131fbf3096d926b2486acb2ab58a4266ddd1bbc
main9  b9f10ae4e727cb9495aaecbe2d752dabf13ec776
main10 169025a6836c7fdc7281ea86523b975a84d889f1
main11 2adfc787c3e5f0ca56abfcc85232e7a971773c3b
```

هذا يثبت Match للمسار والوجود والـSHA المعروفة، وليس Full Functional Read للأجزاء الأخرى.

---

# 14. Assembly Gate

`forensic_main_assembly.yml` ما زال صحيحًا:

```text
source_of_truth = Current/PWA/main2
historical_reference = Original/PWA/main
forbidden = Current/PWA/main, Current/PWA/New-main
```

لا يوجد أي سبب لتغيير هذا الملف الآن.

Final Assembly:

`DEFERRED`

ولا يجوز Assembly قبل Owner Verification للأجزاء المطلوبة ثم integrated validation.

---

# 15. Functional Gold/Diamond Assessment

## السؤال الأول

هل تحقق الهدف الأصلي: استكمال ملفات النظام الأم وظيفيًا؟

**الجواب: ليس بعد.**

## السؤال الثاني

هل ما زال Main6 الحالي يحتوي وظائف ناقصة أو هيكلية؟

**نعم.**

ولذلك تم إعداد Owner replacements كاملة لمعالجة الفجوات المثبتة.

## السؤال الثالث

هل Main6 الآن Gold/Diamond؟

**لا — إلى أن يطبق المالك O1 وO2 ثم يعاد فحص الملف النهائي.**

## السؤال الرابع

هل تم العبث بعقود العمليات الميدانية أو Inventory Core؟

**لا.**

لا يوجد في Main6 مبرر مثبت لإعادة بناء:

- Runsheet lifecycle.
- Physical Stock Engine.
- Delivery/Return Engine.
- Picker/Loader operations.

وسيظل هذا الفصل محفوظًا.

---

# 16. What Was Not Done Deliberately

لم يتم:

- تعديل `main6.md` مباشرة.
- تعديل `core.js`.
- تعديل `sw.js`.
- تعديل `register-sw.js`.
- تعديل `manifest.json`.
- تغيير Assembly.
- تعديل Original.
- تعديل New-main.
- إنشاء Backend Stock writer جديد.
- تغيير `submit_online_order_atomic`.
- تغيير `save_purchase_order_atomic`.
- تغيير `receive_purchase_atomic`.

كل ذلك تم رفضه لأن الدليل الحالي لا يتطلبه داخل Closure Unit هذه.

---

# 17. Self-Audit

## ما تم إثباته

- Main6 الحالي موجود تحت `Current/PWA/main2`.
- SHA الحالية = `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`.
- الحجم = `29,172 bytes`.
- EOF تم التحقق منه.
- Main6 يحتوي Online Store وPurchases.
- Production Online Order Core يدعم explicit operation id.
- Production Purchase Order Core يتطلب supplier UUID.
- Production Purchase Receive Core يتطلب operation UUID.
- Main6 الحالي لا يستخدم هذه العقود بأفضل صورة في كل المواضع.
- توجد فجوات وظيفية مثبتة في المتجر والمشتريات.
- replacement modules كاملة و`node --check` PASS.
- Assembly manifest صحيح.

## ما لم يُثبت بعد

- Owner source application لـO1/O2.
- Final Main6 syntax بعد دمج البديلين.
- Browser E2E بعد التعديل.
- Production authenticated E2E للمتجر والمشتريات بعد التعديل.
- Gold/Diamond closure النهائي لـMain6.
- Functional closure لبقية Main1–Main11.

## أخطاء / إخفاقات حدثت

لا يوجد Production incident سببه Main6 في هذه الجلسة.

حدود التحقق الحالية:

- GitHub connector لا يوفر CI status مفيدًا للـcommit الحالي؛ الحالة المعروضة كانت بدون statuses.
- التحقق البنيوي للبدائل تم بـ`node --check`، أما current main6 فلم يتغير بعد، وبالتالي لا يمكن وصفه كـfinal syntax pass.

## السبب الجذري للفجوات

الفجوات ليست في وجود Production Core الأساسي، بل في عدم اكتمال استخدام Main6 لهذه العقود وفي نقص الوظائف المساندة داخل الواجهة.

---

# 18. Exact Next Checkpoint

بعد أن يطبق المالك:

`MAIN6-O1`

و:

`MAIN6-O2`

النقطة التالية هي فقط:

```text
1. إعادة قراءة Current/PWA/main2/main6.md من أول حرف إلى EOF.
2. حساب SHA الجديدة.
3. node --check على Main6 بعد الجمع.
4. فحص عدم وجود duplicate RW_OnlineStore / RW_Purchases declarations.
5. Production authenticated E2E للـOnline Order مع retry.
6. Production authenticated E2E لإنشاء Purchase Order ثم Receive.
7. التحقق من quantity_received وعدم التضاعف.
8. إغلاق Main6 إن نجح كل gate.
9. الانتقال للـFunctional Capability Gap التالي.
```

ولا يتم Assembly قبل تحقق الـOwner لجميع الأجزاء وفق البوابة النهائية.

---

# 19. Closure Status

```text
MAIN6 FORENSIC READ = COMPLETED
MAIN6 HISTORICAL RECONSTRUCTION = COMPLETED
MAIN6 PRODUCTION CONTRACT RECHECK = COMPLETED
MAIN6 FUNCTIONAL GAP DISCOVERY = COMPLETED
MAIN6 OWNER REPLACEMENTS = PREPARED
MAIN6 OWNER REPLACEMENTS SYNTAX = PASS
MAIN6 SOURCE = OWNER ACTION REQUIRED
MAIN6 PRODUCTION CHANGE = NONE REQUIRED THIS CYCLE
MAIN6 GOLD/DIAMOND = NOT CLOSED
FULL 11-FRAGMENT FUNCTIONAL COMPLETION = NOT CLOSED
FINAL ASSEMBLY = DEFERRED
FALSE CLOSURE = REJECTED
```

---

# 20. Exact Artifacts Created

1. `doc/Draft/Reprots/Report125_Main6_Forensic_Recheck_20260912.md`
2. `doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_OnlineStore_20260912.js`
3. `doc/Draft/Reprots/MAIN6_OWNER_REPLACEMENT_Purchases_20260912.js`

هذه الملفات لا تعدل مصدر Main6 نفسه؛ إنها توثيق وتنفيذ Owner-ready للتعديل الذي يجب على المالك تطبيقه.
