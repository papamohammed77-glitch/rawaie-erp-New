# Report610 — تحقيق Buyer: فواتيري وPO والتكامل المركزي والعملة ومسح الباركود

**التاريخ:** 2026-11-04 — Africa/Cairo  
**نقطة البداية:** LVE-2026-11-03-609 / Report609.  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`.  
**مستودع الحالة والتقارير:** `papamohammed77-glitch/rawaie-erp-New` / `main`.  
**Production:** SMART ERP — `fiilmooggumokxanwiyx`.  
**النطاق:** Buyer tabs `فواتيري` و`أوامر الشراء / PO`، عرضهما في Parent `دورة المشتريات`، creator identity، currency authority، barcode camera scanner، realtime، pagination، وتجهيز E2E.  
**التصنيف:** CURRENT SOURCE + PRODUCTION READ-ONLY REVALIDATED / CHANGE SET 610 PREPARED / NO OPERATIONAL SOURCE OR PRODUCTION WRITE / NOT E2E-VERIFIED / OWNER APPROVAL GATE OPEN.

---

## 1. الحكم التنفيذي

الخلل ليس أن Buyer ينشئ مستندات في جداول منفصلة عن النظام الأم. **هذا غير صحيح**: Buyer وParent يقرآن ويكتبان إلى نفس الكيانات المركزية الحالية:

- أوامر الشراء: `public.purchase_orders` و`public.purchase_order_details`.
- فواتير الشراء: `public.purchase_invoices` و`public.purchase_invoice_details`.
- مسار الكتابة في Buyer يمر عبر Edge الحالية `save-purchase-order` v22 ثم RPCs الذرية؛ لا يوجد جدول Buyer موازٍ.
- Parent `RW_PurchaseGold` يعرض نفس الجدولين في تبويبي «أوامر الشراء» و«فواتير الشراء»، ويستمع حاليًا إلى تغييرات فواتير الشراء، لكنه **لا يشترك في تغييرات purchase_orders** في قناة Realtime الخاصة بدورة المشتريات.

إذن الربط البنيوي موجود، لكن تجربة القراءة والرقابة ناقصة. الفجوات التي ثبتت في المصدر:

1. قائمة Buyer PO لا تعرض المنشئ أو الفرع أو العملة الخاصة بكل مستند، وتستخدم عملة جلسة واحدة لكل الصفوف بدل عملة كل PO المخزنة.
2. قائمة Buyer «فواتيري» لا تعرض العملة كعمود ولا المنشئ أو الفرع أو PO المرتبط أو الرصيد المتبقي؛ مع أن تفاصيل الفاتورة تعرض العملة.
3. Parent PO list لا تعرض المنشئ ولا العملة ولا التاريخ أو الفرع، وParent Invoice list تعرض `supplier_id` كـUUID خام بدل اسم المورد، ولا تعرض المنشئ أو العملة أو PO/الفرع.
4. Parent Realtime يراقب `purchase_invoices` ولكنه لا يراقب `purchase_orders`؛ لذلك لا يوجد إثبات على تحديث جدول PO المفتوح تلقائيًا بعد إنشاء Buyer لـPO، إلا عند إعادة فتح/تحديث العرض.
5. إعدادات دورة المشتريات في Parent تتيح تعديل `purchase_settings.default_currency` بمعزل عن `app_settings.currency`. إنشاء PO والفاتورة فعليًا يقرأ العملة من `app_settings.currency`، وليس من حقل Purchase Settings. القيمتان في Production حاليًا EGP، لكن ازدواج المصدر قائم.
6. حقلا بحث الصنف في إنشاء PO والفاتورة يقبلان الاسم/الكود/الباركود كتابةً فقط؛ لا توجد أداة كاميرا في Buyer، رغم وجود ماسح كاميرا مطبق بالفعل في الجرد داخل Parent.
7. حدود القراءة الحالية تمنع اعتبار القوائم كاملة عند التوسع: Buyer يطلب 500 صف، Edge تضع حدًا أعلى 500 بلا offset/search server-side، وParent `getData()` يضع حدًا 300. هذا مهم جدًا عند كثرة المستندات والمنشئين.

**التوصية المركزية:** لا ننشئ جداول فواتير أو PO جديدة، ولا نكرر الكاتب. نطور الواجهات والاستهلاك حول نفس المستندات ونفس RPCs والـEdge الحالية. لا يوجد سبب مثبت الآن لإضافة Edge Function جديدة أو عمود creator جديد.

---

## 2. نقطة الحقيقة وبصمات المصدر

### 2.1 Git

| العنصر | القيمة |
|---|---|
| Operational HEAD | `2b94681bf0ce93ca9ea55066a3f52c0d1add1084` |
| Parent commit | `5d7b10e4fd0fdf1bb2299c87805f9c86d381cc35` |
| Buyer | `companies/company-1/purchasing/buyer.html` |
| Buyer blob SHA | `7f82fceb0b2c2470d1f112aefeaa1341de5b71a8` |
| Parent | `companies/company-1/main.html` |
| Parent blob SHA | `53b5a9e9d0433a785c3d5471a9c0d68c25497882` |
| Core | `companies/company-1/core.js` |
| Core blob SHA | `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1` |
| Buyer lines / chars | 1,004 / 132,995 |
| Parent lines / chars | 33,358 / 1,800,879 |

التقرير لا يغير هذه الملفات. وملف Parent لم يُعدل.

### 2.2 قاعدة البيانات والبوابات

- SMART ERP Production: ACTIVE_HEALTHY، PostgreSQL 17.6.1.121، 737 migrations.
- العملة في `app_settings.currency`: **EGP**، صف واحد للشركة.
- `purchase_settings.default_currency`: **EGP** حاليًا، صف واحد للشركة.
- Edge `save-purchase-order` v22: ACTIVE، `verify_jwt=true`، ومصدرها التشغيلي مطابق للنسخة الحالية.
- Edge `receive-purchase` v13: ACTIVE، `verify_jwt=true`. فجوة مصدرها التشغيلي في Git ومخاطر عقد الاستلام موثقة في Report609؛ هذه المهمة لا تستبدلها ولا توسعها.
- لا توجد حاجة مثبتة لإنشاء Edge جديدة لعرض Creator أو Currency أو لجداول Parent الحالية.

### 2.3 نشر Cloudflare — حدث أحدث من Report609

أعيد فحص GitHub Checks للـcommit الحالي `2b94681`. ظهر فحص:

- `Cloudflare Pages: rawaea-erp`
- النتيجة: `completed / success`
- النص: `Deployed successfully`
- الوقت: 2026-11-04 11:26:14 UTC
- Preview: `https://eb86b615.rawaea-erp.pages.dev`

هذا يصحح حالة الفشل السابقة المسجلة في Report609 بالنسبة إلى **فحص النشر الآلي** لهذا المشروع والـcommit. لكنه لا يثبت وحده تطابق الـHTML الذي يقدمه المتصفح مع Blob Buyer، ولا يثبت تسجيل دخول Buyer أو عمل كاميرا الهاتف أو تفاعل Realtime الفعلي. حاولت قراءة صفحة Buyer من عنوان الـPreview مباشرة ولم تكن الصفحة متاحة عبر أداة الفحص المستخدمة؛ لذلك تبقى مطابقة Artifact/Runtime غير مؤكدة.

---

## 3. Buyer — فواتيري: الحالة والفجوات

**المواضع الحالية في Buyer:**

- `renderInvoices()`: الأسطر 486–499 تقريبًا.
- `openInvoice()`: 500–514.
- `createPurchaseInvoice()`: 663–719.
- `quickPurchase()`: 719.
- `loadSystemCurrency()`: 159–165.

### 3.1 ما يعمل بالفعل

- القائمة تقرأ `purchase_invoices` مع دليل الموردين من بوابة `GET_DATA`.
- البحث الحالي يطابق رقم النظام، رقم فاتورة المورد، اسم/كود المورد والحالة.
- عوامل التاريخ والحالة موجودة.
- الإجمالي يظهر باستخدام `x.currency` المخزن في كل فاتورة.
- نافذة التفاصيل تعرض المورد، الحالة، التاريخ، رقم المورد، رقم النظام، الاستحقاق، PO المرتبط، العملة، الإجمالي، المدفوع، البنود، وسجل الحالة.
- إنشاء/تعديل الفاتورة يمر عبر `CREATE_INVOICE` / `UPDATE_DRAFT_INVOICE` في Edge v22.
- الفاتورة الجديدة Draft؛ RPC المركزي يقرأ عملة الشركة من `app_settings.currency` ويخزنها، ولا يعتمد على قيمة العملة المرسلة من الواجهة وحدها.
- المنشئ محفوظ بالفعل في `purchase_invoices.created_by`.

### 3.2 النقص المثبت

قائمة «فواتيري» لا تعرض الأعمدة الضرورية للرقابة التشغيلية:

| الحقل | المصدر الموجود | النقص |
|---|---|---|
| المنشئ | `purchase_invoices.created_by` | لا يظهر في القائمة |
| العملة | `purchase_invoices.currency` | لا توجد خلية مستقلة للعملة |
| PO المرتبط | `purchase_order_id` | لا يظهر في القائمة |
| الفرع | `branch_id` | لا يظهر في القائمة |
| الاستلام | `is_received`, `received_date` | لا يظهر كحالة مستقلة |
| الرصيد المتبقي | `total_amount - paid_amount` | لا يظهر |
| الاستحقاق | `due_date` | لا يظهر |
| كمية البنود | `purchase_invoice_details` | لا يظهر ملخصها في القائمة |

اسم «فواتيري» قد يوحي بأن القائمة تخص منشئ الجلسة فقط، لكن القراءة الحالية تعيد فواتير الشركة في النطاق المسموح. **لا أوصي بفلترة القائمة إلى created_by للمستخدم الحالي**؛ ذلك سيحجب عمليات بقية مسؤولي المشتريات عن Finance/Audit ويقوض رقابة النظام الأم. الأنسب إظهار عمود المنشئ، مع استمرار نطاق الرؤية المؤسسي الخاضع للصلاحيات.

### 3.3 تحسين تجربة إنشاء الفاتورة

الحقول الحالية جيدة كأساس: المورد المركزي، الفرع، PO اختياري، الاستحقاق، رقم المورد، الملاحظات، الأصناف والكمية والسعر والخصم والضريبة. لكن التجربة ينقصها:

- ملخص أعلى النموذج يوضح المورد، مصدر المستند (مرتبط بـPO أو فاتورة سوق بلا PO)، الفرع، العملة المركزية، المنشئ، حالة Draft، والإجمالي الحي.
- بيان الفرق بين فاتورة مرتبطة بأمر شراء وفاتورة سوق بلا PO. لا يجوز إظهار أن Quick Market أصبح مستلمًا أو مرحلًا قبل وجود عقد Receiver المعتمد.
- إظهار إجمالي البنود، الخصم، الضريبة، والصافي مع التقريب/العملة نفسها.
- وضع حالة واضحة لكل بند: الكمية المفوترة، المستلمة، والمتبقية متى كانت بيانات الاستلام موجودة.
- إضافة كاميرا بجوار بحث الصنف؛ لا تضاف كمية تلقائيًا بمجرد المسح، بل يُحدد الصنف في حقل الإدخال ويظل زر «إضافة بند» هو نقطة تأكيد الاختيار.
- منع تغيير العملة من Buyer؛ تعرض عملة النظام فقط للإنشاءات الجديدة، بينما المستندات القديمة تعرض عملتها المخزنة.

---

## 4. Buyer — أوامر PO: الحالة والفجوات

**المواضع الحالية:**

- `renderOrders()`: الأسطر 586–599 تقريبًا.
- `createPO()`: 601–637.
- `openPO()`: 651–661.

### 4.1 ما يعمل بالفعل

- PO يقرأ `purchase_orders` و`purchase_quotations`.
- إنشاء PO يطلب المورد النشط، الفرع، موعد التوريد، شروط الدفع، الملاحظات وبنود الأصناف.
- بحث الصنف يقبل الاسم والكود والباركود يدويًا.
- RPC `purchase_create_po_atomic` يتحقق من المستخدم المصادق عليه، الشركة، صلاحية `purchases`، المورد النشط، الفرع، بنود الصنف، و`operation_id`.
- RPC يقرأ العملة من `app_settings.currency`، ويحفظ `purchase_orders.currency`، ويكتب `created_by = v_actor.email`.
- حالة الإنشاء Draft؛ الإنشاء لا يخصم المخزون ولا يولد AP/قيدًا ماليًا.
- نافذة التفاصيل تعرض البنود والكميات المطلوبة والمستلمة والمتبقية وسجل الحالة.

### 4.2 النقص المثبت

قائمة PO لا تعرض:

- المنشئ `created_by`.
- العملة المخزنة لكل PO؛ فهي تعرض كل الصفوف باستخدام `this.currency` الحالي بدل `o.currency`.
- الفرع.
- موعد التوريد المتوقع.
- تقدم الاستلام (الكمية المطلوبة/المستلمة/المتبقية) في القائمة.
- الفاتورة أو الفواتير المرتبطة بأمر الشراء.
- فلاتر الحالة والفرع والمورد والمنشئ والتاريخ/المتأخر.
- ترقيم صفحات حقيقي؛ القراءة الحالية تقتصر على 500 سجل في Buyer.

وفي `renderOrders()` لا يتم تحديث العملة من `GET_SETTINGS` قبل عرض القائمة. لذلك قد تبقى `this.currency` قديمة في الجلسة أو تستخدم EGP كقيمة احتياطية، بينما لكل مستند عملته الفعلية المخزنة.

### 4.3 تحسين تجربة إنشاء PO

أوصي أن يتضمن نموذج PO:

- رأسًا واضحًا يتضمن المورد، الفرع، العملة المركزية read-only، الموعد المتوقع، شروط الدفع، والمنشئ.
- زر كاميرا بجوار بحث الصنف.
- نتائج بحث مرتبة: تطابق الباركود/الكود الكامل أولًا، ثم بادئة الكود، ثم الاسم.
- بطاقة بند تعرض صورة الصنف إن كانت الصورة متاحة عبر مصدر الأصناف المعتمد، والكود والباركود والوحدة.
- معاينة بنود أقوى: تعديل الكمية والسعر، قيمة البند، إجمالي المستند، إزالة البند، ومنع تكرار الصنف بصمت.
- معاينة صريحة أن PO Draft لا يحجز المخزون ولا يرحل AP/GL.
- عند فتح PO: Timeline، حالة الإرسال/الاعتماد، تقدم الاستلام، والفواتير المرتبطة به.
- لا يُعاد بناء دورة PO أو استبدال تحويل عرض السعر المقبول؛ تبقى المسارات الحالية متصلة.

---

## 5. التكامل مع Parent — ما يحدث اليوم فعليًا

### 5.1 نفس الكيانات وليست جزرًا منفصلة

ثبت من المصدر والـRPC أن Buyer لا ينشئ دفترًا منفصلًا:

- PO: Edge v22 `CREATE_PO` تستدعي `purchase_create_po_atomic`، الذي يكتب في `purchase_orders` و`purchase_order_details`.
- Invoice: Edge v22 `CREATE_INVOICE` تستدعي `purchase_create_invoice_atomic_v2`، والذي يستدعي الكاتب المركزي `purchase_create_invoice_atomic` ويكتب في `purchase_invoices` و`purchase_invoice_details`.
- `created_by` في PO يكتب من هوية المستخدم داخل RPC؛ وفي الفاتورة يمر `user.email` من Edge المصادق عليها إلى RPC. لا حاجة إلى عمود Creator جديد.
- Parent `RW_PurchaseGold.orders()` يقرأ `purchase_orders`.
- Parent `RW_PurchaseGold.invoices()` يقرأ `purchase_invoices`.

إذن المستند المنشأ من Buyer موجود في نفس المصدر الذي يقرأه Parent. المشكلة في العرض والتحديث اللحظي والحقول المعروضة، وليست نقص جدول تكامل.

### 5.2 Parent Orders table — CONFIRMED gaps

في `main.html` داخل `RW_PurchaseGold.orders()`، الأسطر 13235–13261 تقريبًا، الجدول الحالي يعرض فقط: الكود، المورد، القيمة، الحالة، إجراء العرض.

ولا يعرض `created_by` أو العملة أو تاريخ PO أو الفرع أو الموعد المتوقع.

### 5.3 Parent Invoices table — CONFIRMED gaps

في `RW_PurchaseGold.invoices()`، الأسطر 13263–13290 تقريبًا، الجدول يعرض: الكود، المورد، القيمة، المدفوع، الحالة، إجراء.

لكن عمود المورد يطبع `supplier_id` كـUUID خام، ولا يعرض اسم المورد، المنشئ، العملة، التاريخ، PO المرتبط، الفرع، أو الرصيد المفتوح.

كما أن زر «ترحيل» يظهر لأي فاتورة Draft في Parent. يجب أن يوضح العرض متطلبات الاستلام قبل إتاحة الإجراء؛ فـRPC الحالي يرفض الفاتورة السريعة بلا PO حتى يكتمل عقد الاستلام السوقي. لا يكفي إخفاء الزر في الواجهة؛ تحقق الخادم هو الحاكم.

### 5.4 Parent Realtime — نقص مؤكد

قناة `ensurePurchaseRealtime()` في Parent، الأسطر 12381–12450 تقريبًا، تشترك في:

- `purchase_requests`
- `purchase_rfqs`
- `purchase_quotations`
- `purchase_invoices`
- `purchase_returns`
- `purchase_payments`

ولا تتضمن `purchase_orders`.

**الأثر:** الفاتورة لديها حدث Realtime يؤدي إلى `refresh()` إذا كان Parent على شاشة دورة المشتريات؛ أما PO فلا يوجد في القناة نفسها حدث مخصص لإعادة تحميل جدول PO. قد يظهر PO بعد إعادة فتح التبويب أو تحديث الشاشة، لكن التحديث الفوري بعد الإنشاء من Buyer غير مثبت في المصدر الحالي. يجب إضافة اشتراك `purchase_orders` إلى نفس القناة، لا إنشاء قناة/جدول جديد.

### 5.5 عمود المنشئ عندما يوجد مئات المستخدمين

الحقل الحالي `created_by` هو البريد الإلكتروني المسجل بواسطة RPC للمستخدم المصادق عليه. هذا معرّف عملي غير ملتبس حتى لو كان عدد مسؤولي المشتريات بالمئات؛ ويصلح كعمود منشئ دون إضافة بيانات مكررة.

لم يثبت أن `RW_STATE.data.users` يحتوي دليل المستخدمين كاملًا؛ سياق Parent الحالي يحمل المستخدم المصادق عليه فقط، بينما إدارة المستخدمين لها مكوّن مستقل. لذلك:

- الإصدار الآمن الأول: عرض البريد المخزن في `created_by` كما هو، مع عنوان العمود «المنشئ».
- الاسم الظاهر يمكن إضافته لاحقًا إذا أُنشئ/استُعمل Lookup مصرح به يقرأ `users.name,email` داخل نفس الشركة وبنطاق صلاحية مناسب.
- لا نكتب الاسم يدويًا في المستند ولا نستبدل قيمة `created_by` التاريخية.
- لا نفلتر قائمة Parent أو Buyer بمنشئ الجلسة؛ تبقى رؤية Finance/Audit المؤسسية خاضعة للصلاحيات.

---

## 6. العملة — المصدر الصحيح والفجوة

### 6.1 مصدر العملة الفعلي للمعاملة

**CONFIRMED:** Edge `save-purchase-order` v22 تنفذ `getSystemCurrency()` بقراءة `app_settings.currency` مع تحقق صيغة العملة. وتستدعي هذه القيمة عند إنشاء/تعديل الفاتورة. كما أن `purchase_create_po_atomic` يقرأ `app_settings.currency` ويخزنها في PO.

إذن حقل إعدادات النظام `app_settings.currency` هو مرجع العملة الجديدة. Buyer لا يرسل عملة موثوقة لفرض عملة مختلفة؛ الخادم يعيد تحديدها.

### 6.2 ازدواج الإعداد

**CONFLICT:** Parent Purchase Settings يحتوي حقلًا قابلًا للتحرير `purchase_settings.default_currency` ويُرسله `SAVE_SETTINGS` إلى `purchase_set_settings_atomic` التي تحدث هذا الحقل بصورة مستقلة. أما RPC إنشاء PO والفاتورة فيقرأ `app_settings.currency` وليس `purchase_settings.default_currency`.

القيمتان حاليًا EGP في Production، لكن يمكن أن تختلفا مستقبلًا. كذلك يعرض حقل Purchase Settings افتراضيًا SAR إذا لم يقرأ صف الإعدادات، وهو عرض مضلل في نظام عملته المركزية EGP.

**Change Set المقترح:**

1. في إعدادات دورة المشتريات، تعرض العملة المركزية القادمة من `app_settings.currency` كقيمة read-only بدل حقل مستقل قابل للتعديل.
2. لا يرسل `SAVE_SETTINGS` قيمة `default_currency` جديدة من هذه الشاشة.
3. لا نحذف عمود `purchase_settings.default_currency` الآن؛ يجب أولًا فحص كل مستهلكيه في كل المستودعات/التطبيقات. إبقاء العمود دون استعمال تحريري أقل خطرًا من Migration متسرعة.
4. Buyer PO/Favorite Invoice list يعرض `o.currency` و`i.currency` لكل مستند. العملة الحالية من إعدادات النظام تستخدم كقيمة مرجعية لمستند جديد فقط أو fallback موثق عند نقص حقل قديم.
5. لا نعدل المستندات التاريخية SAR ولا نحول القيم القديمة إلى EGP تلقائيًا.

### 6.3 بيانات Production ذات الصلة

القراءة الحالية أعادت:
- `app_settings.currency = EGP`.
- `purchase_settings.default_currency = EGP`.
- `purchase_orders`: صف Draft واحد بعملة EGP، وحقل المنشئ غير فارغ.
- `purchase_invoices`: صف Draft واحد بعملة SAR وصفان Posted بعملة SAR، وجميع الصفوف الثلاثة لديها `created_by` غير فارغ.

تتفق هذه القراءة مع ضرورة عرض العملة **المخزنة على المستند**؛ تغيير عملة النظام الآن لا يغير معنى فواتير SAR السابقة ولا يجوز أن يجعل الشاشة تعرضها بالجنيه المصري.

---

## 7. مسح الباركود بالكاميرا — مراجعة الجرد في Parent

### 7.1 التنفيذ الحالي الذي تمت مراجعته

Parent `main.html` يحتوي `RW_Warehouse._startBarcodeScanner(prefix)` عند الأسطر 16133–16249 تقريبًا. ويستخدم:

- `navigator.mediaDevices.getUserMedia` مع كاميرا الخلفية `facingMode: environment`.
- `window.BarcodeDetector` بعد التحقق من دعم المتصفح.
- صيغ: EAN-13، EAN-8، Code 128، Code 39، UPC-A، UPC-E، QR.
- نافذة Swal بها عنصر video وإطار مسح.
- دورة كشف كل 350ms.
- مطابقة `item.barcode` أو `item_code` مع الأصناف المحملة.
- إيقاف timer ومسارات الكاميرا عند غلق المودال أو الفشل.
- fallback واضح إذا لم يدعم المتصفح الكاميرا/BarcodeDetector.

واجهة جرد الفرع والجرد العام تضيف زر كاميرا بجانب حقل البحث وتستدعي `RW_Warehouse._startBarcodeScanner('bc')` أو `('gc')`.

### 7.2 لماذا لا نستدعي RW_Warehouse مباشرة من Buyer؟

Buyer تطبيق مستقل، وله `App.cache.items` وحقول/نماذج واختيار `selectedItem` مختلفة. ربطه بدوال `RW_Warehouse` الداخلية سيجعل Buyer يعتمد على شاشة الجرد وعلى حالة عالمية غير مضمونة في PWA منفصلة.

**التنفيذ الصحيح:** نقل النمط لا الاعتماد البرمجي: helper مستقل داخل Buyer، يحتفظ بعقد بسيط `scanBarcode(inputId, onMatch)` ويعيد الصنف المطابق. يستخدم نفس BarcodeDetector والكاميرا الخلفية ودورة التنظيف، لكنه يختار الصنف إلى نموذج PO/Invoice الحالي ولا يضيف كمية أو ينشئ حركة مخزون من عملية المسح.

### 7.3 ضوابط الماسح المقترحة

1. زر كاميرا واضح داخل حقل البحث في PO وInvoice.
2. دعم المسح بالهاتف، والبحث النصي، وقارئ USB/HID الذي يكتب داخل input.
3. مطابقة دقيقة للباركود أولًا، ثم item_code؛ ولا يُقبل تطابق جزئي على أنه باركود مؤكد.
4. عند العثور على الصنف، يُملأ حقل الصنف وتُعرض بياناته ويظل الضغط على «إضافة بند» هو تأكيد الإضافة.
5. إذا كان الصنف موجودًا في السطور بالفعل، لا يكرر النظام البند ولا يضاعف الكمية بصمت؛ يوجه المستخدم إلى السطر الموجود.
6. إن لم يتوفر BarcodeDetector أو إذن الكاميرا، تبقى الكتابة/قارئ USB متاحين مع رسالة مناسبة.
7. إيقاف جميع Camera tracks وtimers عند الإغلاق أو النجاح أو الخطأ.
8. استخدام item cache الحالي فقط إذا كان تحميل الأصناف كاملًا؛ وإلا تمديد `GET_DATA` داخل Edge v22 ببحث exact barcode/code محدود ومصرح به. لا Edge جديدة.

**ملاحظة حد البيانات:** Buyer `App.data()` يطلب حتى 500 صف. Edge `GET_DATA` لا تستخدم `offset` أو ترقيمًا؛ `rowLimit = min(p.limit,500)`. لذلك لا أعتبر مطابقة باركود محصورة في أول 500 صنف حلًا كاملًا ما لم يثبت أن دليل الأصناف أقل من ذلك. يجب إما إثبات اكتمال cache أو استخدام البحث الدقيق عبر الـgateway الحالي.

---

## 8. حزمة التغيير المقترحة — Change Set 610

هذه الحزمة مترابطة، ولا تنشئ أي جدول موازي:

### A — Buyer PO List & Detail

**الملف:** `companies/company-1/purchasing/buyer.html`  
**الدوال:** `renderOrders()`, `createPO()`, `openPO()`.

- تحميل عملة النظام من `GET_SETTINGS` عند تحديث التبويب.
- استخدام `o.currency || systemCurrency` لكل صف على حدة.
- أعمدة: PO، التاريخ، المورد، الفرع، المنشئ، موعد التوريد، الحالة، قيمة PO، العملة، تقدم الاستلام.
- مرشحات: بحث، مورد، حالة، فرع، منشئ، متأخر/غير متأخر، تاريخ.
- ملخص فوق الجدول: المفتوحة، المتأخرة، في انتظار الاستلام، إجمالي القيمة حسب العملة (لا تجمع عملات مختلفة في رقم واحد).
- ربط تفاصيل PO بالفواتير التي يحمل `purchase_invoices.purchase_order_id = po.id` وإظهار أرقامها وحالاتها.
- عدم تغيير مسار إنشاء PO أو الـRPC أو Operation ID.
- دعم pagination حقيقي عبر gateway بعد إدخال `offset/search/status` آمنين ومحددين بالـallowlist.

### B — Buyer Invoice List & Detail

**الملف:** `companies/company-1/purchasing/buyer.html`  
**الدوال:** `renderInvoices()`, `createPurchaseInvoice()`, `openInvoice()`.

- الإبقاء على القراءة المؤسسية المسموحة؛ لا فلترة إلى `created_by === currentUser`.
- أعمدة: كود النظام، رقم المورد، التاريخ، المورد، PO المرتبط، الفرع، المنشئ، الاستحقاق، الاستلام، الحالة، القيمة، العملة، المدفوع، المتبقي.
- فلاتر: رقم النظام/رقم المورد/المورد/PO/المنشئ، التاريخ، الحالة، الفرع، حالة الاستلام.
- عرض المستند Draft بوصفه غير مرحل؛ لا stock/AP/GL عند الإنشاء.
- تفريق واجهة «مرتبط بـPO» عن «فاتورة سوق بلا PO» دون ادعاء تفعيل الاستلام السوقي قبل إغلاق Change Set B/Report609.
- اعتماد `loadSystemCurrency()` في كل نموذج جديد مع تحقق صيغة العملة؛ الخادم يظل المصدر النهائي.
- عرض عملة كل فاتورة من `invoice.currency`؛ لا تستبدل SAR التاريخية بـEGP.
- عرض سجل الحالة والفاعل `actor_email` في التفاصيل.
- عدم إضافة زر ترحيل في Buyer للمستندات غير المستوفية؛ Server RPC يبقى الحاكم.

### C — Parent Purchase Cycle

**الملف:** `companies/company-1/main.html` — تغيير مستقبلي محدد، غير منفذ في هذه الدورة.

- `RW_PurchaseGold.orders()`: إضافة `created_by`, currency، التاريخ، الفرع، expected_delivery_date، حالة/تقدم الاستلام، وإظهار قيمة العملة على كل صف.
- `RW_PurchaseGold.invoices()`: إضافة قراءة الموردين والفروع وPO maps؛ استبدال UUID المورد بالاسم، وإظهار created_by، currency، invoice_date، PO، branch، due_date، paid/open balance، receipt state.
- إضافة اشتراك `purchase_orders` إلى قناة `ensurePurchaseRealtime()` الحالية. لا قناة جديدة ولا جدول مكرر.
- عدم حصر السجلات بمنشئها الحالي؛ يعرض النظام الأم مستندات الشركة ضمن صلاحية المستخدم، ويظهر المنشئ للتتبع.
- البحث/التصفية/الترقيم من جهة الخادم عند تجاوز 300 مستند. Parent `getData()` الحالي يضع `limit(300)` ولا يطبق pagination.
- Creator default = stored email `created_by`. لا نحتاج DB column أو trigger جديد. يمكن لاحقًا إثراء العرض بالاسم من `users` عبر Lookup مصرح به؛ الاسم ليس بديلًا عن البريد المخزن.

### D — Currency Single Authority

**الملف:** `companies/company-1/main.html` وBuyer.

- Parent Purchase Settings تعرض `app_settings.currency` read-only، وليس `purchase_settings.default_currency` كعملة مستقلة قابلة للتعديل.
- استبعاد `default_currency` من payload الواجهة عند حفظ Purchase Settings؛ لا تعديل على عملة الشركة من التبويب الفرعي.
- إبقاء العمود القديم حتى البحث الشامل عن مستهلكيه؛ لا حذف ولا Migration الآن.
- مستندات جديدة تأخذ العملة عبر النظام المركزي، ومستندات قديمة تستخدم عملتها المخزنة.
- التحقق من عدم وجود أي مسار يرسل عملة Buyer غير العملة المركزية أو يعرض مبلغًا بعملة جلسة مختلفة.

### E — Barcode Camera in Buyer

**الملف:** `companies/company-1/purchasing/buyer.html`، وامتداد محدود لبوابة `save-purchase-order` v22 عند ثبوت ضرورة server-side exact lookup.

- إنشاء helper مستقل داخل Buyer مبني على نمط `RW_Warehouse._startBarcodeScanner`، لا يستدعي RW_Warehouse.
- زر كاميرا في مدخل الصنف داخل نموذج PO والفاتورة.
- نتيجة المسح تمر بآلية اختيار الصنف الحالية وتملأ selectedItem؛ لا تحدث stock أو receiving.
- البحث exact barcode/code من المصدر الكامل، وليس أول 500 فقط إذا تجاوز دليل الأصناف هذا الحد.
- لا مكتبة خارجية جديدة، لا Edge Function جديدة، لا تغيير في main.html على مسار التنفيذ الحالي.

---

## 9. أثر قاعدة البيانات والمحاسبة والمخزون

**لا يلزم تغيير بنية DB لعرض الحقول الحالية**؛ `created_by`, `currency`, `branch_id`, `purchase_order_id`, `due_date`, `is_received`, `paid_amount` موجودة أصلًا في الجداول المعنية.

### عند إنشاء PO

- INSERT في `purchase_orders` و`purchase_order_details`.
- الحالة Draft.
- `created_by` من هوية RPC المصادق عليها.
- `currency` من `app_settings.currency`.
- لا حركة `inventory_log`، لا تغيير `stock_branches)، لا Supplier Ledger، لا Journal، ولا Treasury.

### عند إنشاء Invoice Draft

- INSERT في `purchase_invoices` و`purchase_invoice_details`.
- `created_by` من بريد المستخدم المصادق عليه.
- `currency` من `app_settings.currency` مع تحقق الخادم.
- لا stock ولا AP/GL ولا Treasury عند الإنشاء.
- الارتباط بـPO محفوظ في `purchase_order_id` إن اختير.

### عند عرض المستند في Parent

- لا أثر DB/محاسبي/مخزني؛ قراءة فقط.
- Realtime يغير العرض فقط، ولا ينشئ مستندات مكررة.
- لا تحديث لـ`created_by` ولا للـcurrency التاريخية.

### أثر الماسح

- لا أثر DB أو مخزني بمجرد قراءة الباركود.
- الاختيار يملأ الصنف في النموذج؛ الأثر يبدأ فقط عند حفظ Draft من خلال RPC الحالي.
- لا حركة استلام/إضافة مخزون إلا عبر Receiver وعقده المعتمد في Change Set B.

---

## 10. مخاطر التوسع والرقابة الموحدة

| الخطر | الدليل الحالي | العلاج المقترح |
|---|---|---|
| عدم ظهور PO فورًا في Parent | قناة Parent لا تشترك في purchase_orders | إضافة Realtime subscription في القناة نفسها |
| UUID المورد في فواتير Parent | عمود invoices يطبع supplier_id | Supplier lookup map بالاسم |
| غياب منشئ المستند | العمود موجود لكن لا يعرض | عرض created_by email |
| عرض عملة خاطئة في PO history | Buyer PO list يستخدم this.currency لكل الصفوف | استخدام row.currency |
| وجود مصدرين لإعداد العملة | default_currency مستقل عن app_settings.currency | جعل app_settings المصدر الوحيد في الواجهة |
| اختفاء مستندات عند تجاوز حد القراءة | Parent limit 300 / Buyer & Edge max 500 | Server-side pagination + filters |
| فشل البحث في صنف خارج أول 500 | cache محدود | exact barcode/code lookup عبر gateway |
| إخفاء عمليات بقية الموظفين | لو تمت فلترة القائمة إلى المنشئ | إبقاء role-scoped company view |
| بيانات legacy مختلفة العملة | فواتير SAR قائمة مع نظام EGP | استخدام currency المستند وعدم تحويله آليًا |
| عدم دعم كاميرا جهاز المستخدم | BarcodeDetector/permission/HTTPS/device | fallback إلى keyboard scanner/manual search |

---

## 11. مصفوفة E2E المطلوبة

لا يمكن اعتبار أي من هذه الحالات مختبرة فعليًا في هذه الدورة. وهي شروط القبول قبل إغلاق Change Set 610:

1. **Buyer PO:** إنشاء PO Draft بمستخدم مشتريات A؛ تحقق `created_by=A.email`، وcurrency من `app_settings`، وظهوره في Parent PO table بعد Realtime.
2. **Parent Creator:** PO وInvoice من مستخدمين A وB؛ يظهر منشئ كل مستند الصحيح دون خلط أو تحويل إلى مستخدم الجلسة.
3. **Invoice:** إنشاء Draft مرتبط بـPO؛ ظهور المورد بالاسم ورقم PO والعملة والفرع والمنشئ في Buyer وParent.
4. **Quick Invoice:** إنشاء Draft بلا PO؛ يظهر كمصدر بلا PO، لا مخزون/AP/GL/خزينة، ولا يسمح Parent بترحيله قبل تحقق عقد الاستلام.
5. **Currency:** تغيير `app_settings.currency` في بيئة معزولة؛ المستند الجديد يستخدم العملة الجديدة؛ المستند القديم يحتفظ بعملة السجل؛ تغيير Purchase Settings secondary field لا يغير العملة الفعلية.
6. **Realtime PO:** إبقاء Parent على جدول PO ثم إنشاء Buyer PO بمستخدم آخر؛ يظهر الصف مرة واحدة دون Reload يدوي ولا Duplicate.
7. **Realtime Invoice:** السيناريو نفسه للفواتير، مع التحقق من تحديث نفس الجدول.
8. **Barcode EAN-13/EAN-8/Code 128:** المسح يختار الصنف الصحيح ويملأ الحقل فقط؛ لا ينشئ duplicate line ولا stock event.
9. **Camera lifecycle:** السماح/رفض الكاميرا، إغلاق المودال، نجاح المسح، إعادة فتحه؛ لا يستمر stream ولا timer بعد الإغلاق.
10. **Fallback:** متصفح لا يدعم BarcodeDetector، قارئ USB/HID، إدخال يدوي، باركود غير معروف، باركود مكرر/غير فريد.
11. **Large catalogue:** الصنف خارج أول 500؛ exact search يظل قادرًا على إيجاده، أو يثبت أن عدد الأصناف أقل من الحد.
12. **Pagination:** أكثر من 300/500 PO/Invoice؛ تنقل الصفحات لا يكرر أو يخفي أو يخلط المستندات.
13. **Authorization/Tenant:** مستخدم شركة أخرى/غير مصرح/منشئ غير معروف/فرع غير مسموح؛ لا تسرب ولا DML جانبي.
14. **Regression:** PO conversion from accepted quotation، PO receipt existing path، invoice draft update/delete guards، parent returns/payments/reports.
15. **Accounting/Inventory snapshots:** لا فرق من مجرد القراءة أو المسح؛ بعد الاستلام/الترحيل المصرح تقارن stock_branches/inventory_log/supplier_ledger/journal_entries/treasury/cash_box وفق عقد الاستلام المعتمد.

---

## 12. بيئة الاختبار وحدود التنفيذ

- Project `rawaea-staging` الحالي لديه 62 migration / 70 public tables ويفتقد جداول Buyer الأساسية مثل `purchase_invoices` و`purchase_invoice_details`؛ لا يصلح لـBuyer/PO/Invoice E2E.
- Production SMART ERP ليس مكانًا لإنشاء فواتير/PO تجريبية أو تغيير أرصدة المخزون والخزينة والموردين.
- لم توجد جلسة Browser مصادق عليها في Buyer/Parent لاختبارات تفاعلية في هذه الدورة.
- فحص Cloudflare check للـcommit الحالي نجح في 2026-11-04 11:26:14 UTC، لكن تطابق الـHTML المقدم مباشرةً للمتصفح وسلوك الكاميرا/Realtime لم يُختبرا.
- لم تُنشأ Fixtures، ولم تُنفذ معاملات PO أو Invoice، ولم يحدث DDL/RPC/RLS/ACL/Edge write أو deploy في Production.
- لم يتم تعديل Buyer أو Parent أو Core في هذه الدورة.

---

## 13. قيود الحوكمة والموافقة المطلوبة

Master CTO §77.2 يشترط اعتماد المالك للتغيير المحدد قبل كتابة Source/Edge/RPC/DB أو نشر يؤثر في Production. الطلب العام الحالي لا يفتح استثناءً لهذا الشرط.

**التغييرات التي يجب اعتمادها كحزمة واحدة أو بحزم منفصلة واضحة:**

1. Buyer list/form UX + currency display + barcode helper.
2. Parent orders/invoices columns + supplier mapping + Realtime PO subscription + currency settings display.
3. Existing `save-purchase-order` v22 extension only if needed for paginated/exact item lookup.
4. E2E Staging parity plan and isolated fixtures.

كل حزمة يجب أن تقدم Full source diff/SQL إن وجد، وأسماء الدوال والعلامات، الأثر المتوقع، صلاحيات القراءة والكتابة، حالات الفشل، acceptance, rollback, ونطاق الاختبار.

لا تنشأ Edge جديدة. ولا تلمس Parent `main.html` في هذه الدورة. وإذا أُريد لاحقًا تنفيذ Change Set يتطلب Parent، فيجب أن تكون الموافقة صريحة على المواضع المحددة في هذا التقرير، وليس إعادة كتابة عامة للملف.

---

## 14. الأعمال التي تمت والأعمال التي لم تتم

### أُنجزت فعليًا

- إعادة قراءة LVE609 وCURRENT_STATE ومصدر Buyer الحالي وParent main.html ومصدر Edge v22.
- إعادة التحقق من مشروع SMART ERP والعملة ومجاميع المستندات.
- استخراج الدالة الحية `purchase_create_po_atomic` و`purchase_create_invoice_atomic`، وإثبات كاتب المستند والعملة والـcreator.
- مطابقة Buyer وParent على نفس جداول PO/Invoice.
- إثبات نقص Parent Realtime الخاص بـpurchase_orders.
- مراجعة نمط BarcodeDetector/getUserMedia من الجرد في Parent.
- مراجعة ازدواج `purchase_settings.default_currency` مقابل `app_settings.currency`.
- التحقق من نتيجة Cloudflare check الجديدة التي نجحت للـcommit الحالي.
- إعداد Change Set 610 ومصفوفة E2E ومعايير القبول في هذا التقرير.

### لم يُنفذ

- لم يتغير `buyer.html` أو `main.html` أو `core.js`.
- لا Migration/DDL/RPC/ACL/RLS/Grant.
- لا تعديل أو نشر Edge Function.
- لا إنشاء بيانات تجريبية في Production أو Staging.
- لا عملية PO أو Invoice اختبارية.
- لا E2E مصادق عليه أو كاميرا فعلية.
- لا Cloudflare deployment جديد في هذه الدورة.
- لا تعديل لأي رصيد مخزون/مورد/خزينة/قيد.

---

## 15. نقطة الاستكمال الدقيقة لـCTO التالي

1. ابدأ من LVE610 أعلى `CURRENT_STATE.md` ثم هذا التقرير ثم Master CTO §§29 و58–60 و77.1–77.4.
2. أعد جلب Operational HEAD والـblob قبل أي patch؛ لا تعتمد على أرقام أسطر قديمة إن تغيرت البصمة.
3. اعرض Change Set 610 كاملًا على المالك للاعتماد الصريح قبل أي كتابة.
4. بعد الاعتماد، نفذ أولًا Buyer + Parent source diffs في العلامات المحددة، دون إعادة بناء التطبيقات أو تغيير جداول النظام.
5. اختبر barcode camera على هاتف فعلي وعلى browser fallback، واختبر Realtime من Buyer إلى Parent بحسابين مختلفين.
6. لا تفتح E2E مالية حتى تصبح Staging ذات schema parity ومستخدمين/أدوار/فروع معزولة. قارن snapshots قبل/بعد دون لمس حسابات Production.
7. لا تعِد فتح Quick Market receipt أو supplier-return أو goods-custody أو custody-expense workstreams ضمن هذه المهمة؛ لها عقود مستقلة موثقة في Reports605–609.
8. احفظ النتائج في تقرير جديد، ثم حدث CURRENT_STATE وProject Memory وExecution Log بعد جلب النسخ الحالية.

**الحكم النهائي:** Buyer وParent بالفعل متصلان عبر نفس جداول PO/Invoice والبوابة المركزية. أُثبتت فجوات عرض Creator/Currency/Supplier/PO linkage/Realtime/Pagination/Barcode. حزمة تحسين محددة وجاهزة للموافقة، لكن تنفيذ المصدر وE2E وProduction لم يحدث في هذه الدورة.  
**STATUS: FORENSIC REVIEW COMPLETE / CHANGE SET 610 READY FOR EXACT OWNER APPROVAL / NO OPERATIONAL OR PRODUCTION WRITE / BUYER PO-INVOICE UX NOT YET CLOSED.**
