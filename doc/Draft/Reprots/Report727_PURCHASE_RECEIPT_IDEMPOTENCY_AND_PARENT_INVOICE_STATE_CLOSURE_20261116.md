# Report727 — إغلاق فجوات الاستلام وربط فواتير الشراء بالنظام الأم

**التاريخ:** 2026-11-16 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-16-727  
**نقطة الاستئناف السابقة:** LVE-2026-11-15-726  
**الحالة:** IMPLEMENTED + PRODUCTION DB VERIFIED + SOURCE DEPLOY VERIFIED + ROLLBACK INTEGRATION TESTS PASS — WITH ACCOUNTING EXCEPTION OPEN

## 1. الحكم التنفيذي

أُنجزت المعالجات الآمنة التي ثبت سببها في دورة استلام أوامر الشراء وفواتير السوق السريع:

1. أصلحت قراءة مستندات الاستلام المرتبطة بأوامر شراء مستقلة في خدمة المشتريات، حتى عندما لا توجد فاتورة مرتبطة بالأمر بعد.
2. أضيفت جداول الاستلام إلى Realtime في Buyer وReceiver، بما في ذلك نسخة Receiver المضمّنة داخل المخزن الشامل.
3. أُصلحت فجوة دقة الكميات وإعادة المحاولة في استلام PO: سجل الاستلام يقبل الآن أربع منازل عشرية مثل تفاصيل PO، وبصمة التكرار تُقارن بدقة معيارية ثابتة.
4. ضُبطت سياسات قراءة RLS في جدولَي الاستلام على سياسة مجمّعة واحدة لكل جدول، تحافظ على النطاقات السابقة وتسمح للمشتريات ومنفذ الاستلام بقراءة ما يقع ضمن صلاحياتهما فقط.
5. عُدّل النظام الأم ليفصل حالة الفاتورة عن الاستلام المخزني والتسوية المالية؛ وأُزيل زر ترحيل المورد من فواتير السوق السريع التي تُسوّى من عهدة المشتري، مع إبقاء الترحيل للفواتير التي تحتاجه فعلاً.
6. نُشرت نسخة Cloudflare Production على Commit يتضمن تعديل النظام الأم.

**لم تُنشأ حركات مخزون أو قيود أو أرصدة موردين دائمة لأغراض الاختبار.** أُجريت اختبارات استلام عبر معاملة PostgreSQL متراجعة بالكامل، ثم أثبت فحص لاحق عدم بقاء أي صف اختبار.

يوجد استثناء محاسبي بقيمة 20 EGP بين حساب الموردين العام ودفتر الموردين الفرعي. تم تحديد مصدره إلى قيدي QA قديمين بلا هوية مورد أو حركة مخزنية مقابلة. لم أقم بتوليد قيد تصحيحي بالتخمين؛ لذلك يبقى هذا الاستثناء مفتوحًا للمراجعة المحاسبية المعتمدة، ولا يمنع إغلاق فجوات الاستلام البرمجية.

## 2. نقطة البداية ومصادر الحقيقة

- Operational repository: `papamohammed77-glitch/erp-frontend`.
- Operational branch: `main`.
- Current HEAD عند التحقق: `8c26511ec34f143aa0c07779bad213aa7c5f74ed`.
- Parent `main.html` بعد الإصلاح: blob `1af4430e34bb5434327cb24a3dca50b538188f42`.
- Buyer: `c986c4730da0200ff9c99eabce579b8c39a021a6`.
- Receiver: `dfae1278769c469559c18b778e1e71f6c605248b`.
- Unified Warehouse: `b9c132a6f10db7524cdc9f0767935069371d5562`.
- `save-purchase-order` source: `3d3a84cb9c0fc58be73c0617bc50bdaa83b8a4ee`.
- Supabase project: `fiilmooggumokxanwiyx`, PostgreSQL 17.6.
- Cloudflare Pages Production: `rawaea-erp.pages.dev`; Automatic deployments enabled; latest observed Production/main commit `8c26511`.

تمت استعادة CURRENT_STATE والدستور وتقرير Report726، ثم تمت مطابقة النتائج مع GitHub وSupabase. لا تُعد التقارير السابقة دليلًا على الحالة الحالية إلا حيث أكّدتها المصادر الحية.

## 3. الإصلاحات المنفذة

### 3.1 مسار قراءة الاستلام المستقل عن الفاتورة

**السبب الجذري:** `getVisibleReceivingRows()` كانت تبدأ بقائمة الفواتير المرئية للمستخدم، وتعيد قائمة فارغة مباشرة إذا لم توجد أي فاتورة. بهذا كان استلام PO مستقل غير مربوط بفاتورة يمكن أن يختفي من سجل القراءة رغم أن المستخدم يملك صلاحية المشتريات ويرى PO ضمن الشركة.

**الإصلاح:** تقرأ الخدمة الآن أوامر الشراء ضمن الشركة، وتجمع:
- استلامات الفواتير التي يستطيع المستخدم قراءتها.
- استلامات PO المستقلة التي يتطابق رقم أمرها مع PO مرئي للشركة، وتكون `purchase_invoice_id IS NULL`.

ثم تزيل التكرار اعتمادًا على `operation_id` وتعيد الترتيب الزمني. لم تُفتح قراءة عامة ولم تُستخدم صلاحية service-role كبديل لهوية المستخدم.

**Commit:** `281ca686f32f7a3ac2b79bef0a81a007b870c2ff`.

### 3.2 Realtime

أضيفت `receiving` و`receiving_details` إلى الاشتراكات/قائمة الأحداث المستهدفة في:
- `buyer.html`: تبويبا الأوامر والفواتير، مع إبطال الذاكرة وإعادة رسم التبويب المعني.
- `receiver.html`: تحديث قائمة الاستلامات المكتملة والتاريخ عند وصول رأس أو تفاصيل.
- `warehouse.html`: تحديث نسخة Receiver المضمّنة، لا الاكتفاء بإصلاح التطبيق المنفصل.

Commits:
- `739eaa6199f91588af7c5c0b7fa779b5f1c31404`
- `363836b0cd19b6915ebe6a5a80581e933b1ac518`
- `911d8b9b7cf10f111089a3f64c3be6d7ebf39580`

### 3.3 دقة الكميات وIdempotency

**السبب الجذري المثبت:** تفاصيل أمر الشراء تقبل أربع منازل عشرية، بينما `receiving_details.qty_expected/qty_received/difference` كانت بمنزلتين. كما أن دالة `receive_purchase_atomic` كانت تقارن التمثيل النصي للقيم الرقمية قبل التخزين وبعده. لذلك قد تتحول الكمية المرسلة `2` إلى `2.00` عند التخزين، فتفشل إعادة المحاولة الصحيحة لنفس `operation_id` برسالة تعارض تكرار.

**الإصلاح:**
- الأعمدة الثلاثة أصبحت `numeric(14,4)` مع تحويل يحافظ على القيم الحالية.
- بصمة الطلب وبصمة تفاصيل الإذن أصبحتا تقارنان القيم بعد تطبيعها إلى أربع منازل عشرية.
- الحمولة نفسها مع نفس `operation_id` تعود كعملية مكررة؛ الحمولة المختلفة مع المعرّف نفسه تُرفض.

**Migration:** `20261116142749_receiver_qty_precision_and_idempotency_20261116`.  
**Source commit:** `7fb6db1fd2dc6fcbe59c903bf4736552e8b2c22b`.

### 3.4 RLS وRealtime publication

أضيفت قراءة للمشتريات ضمن الشركة، وقراءة منفذ الاستلام لمستنداته، ثم جُمعت مع صلاحيات التقارير والمخازن والمالية وقراءة مشتريات السوق السريع الخاصة بالمشتري في سياسة واحدة لكل جدول. حُفظت علاقات الشركة ونطاق الدور، ولم تُمنح `anon` صلاحيات قراءة.

المعالجة شملت:
- Publication لـ `receiving` و`receiving_details`.
- سياسة مجمعة لـ `receiving`.
- سياسة مجمعة لـ `receiving_details`.
- تقييم سياق الهوية مرة على مستوى statement باستخدام scalar subqueries.
- فهرسان لأعمدة FK الخاصة بربط الاستلام بالفاتورة وتفاصيلها.

Migrations:
- `20261116141323_receiving_read_scope_realtime_20261116`
- `20261116144005_receiving_read_policy_consolidation_20261116`
- `20261116144311_receiving_rls_context_and_fk_index_opt_20261116`

Commits:
- `c75a07b86a105e640d015eacb482c875b74b45d2`
- `3ff7454af8a57921869b0832d31736960d54076e`
- `139eb41e83b7db705a5d814fdda3a6fd2a330bf8`

**ملاحظة أداء:** تحذير Advisor العام عن كثرة المفاتيح الأجنبية غير المفهرسة انخفض من 253 إلى 251 في الفحص التالي. لم تُجرَ معالجة جماعية لبقية الفهارس أو سياسات النظام.

### 3.5 نشر Edge Function الحالية

تم تحديث Edge Function الموجودة `save-purchase-order` فقط، ولم تُنشأ وظيفة جديدة:
- Version: **42**
- Status: **ACTIVE**
- `verify_jwt=true`
- Live source hash: `8e18ad9372a84b6aa81f6a88e802abdea80f2c556f27ebabe0c195608b65cab6`
- SHA المحتوى الحي مطابق لمصدر GitHub بعد التعديل.

## 4. قرار PINV-1004: لماذا بقيت Draft؟

هذه الحالة ليست فشل استلام. السجلات الحية تثبت:

| الحقل | القيمة |
|---|---|
| `invoice_code` | `PINV-1004` |
| `status` | `Draft` |
| `purchase_source` | `QUICK_MARKET` |
| `settlement_source` | `EMPLOYEE_CUSTODY` |
| `receipt_status` | `RECEIVED` |
| `settlement_status` | `UNSETTLED` |
| `is_received` | `true` |
| قيمة الفاتورة | 2,240 EGP |
| الوحدة | 5 كراتين |
| معامل التحويل | 24 علبة لكل كرتونة |
| الكمية الداخلة للمخزون | 120 علبة أساس |

المستند المرتبط يسجل قبول 5 كراتين في Receiver. وحركة `PurchaseIn` واحدة أدخلت 120 وحدة أساس إلى الفرع الرئيسي. كما سُجل حدث `BUYER_TO_WAREHOUSE_ACCEPTED` بكمية `-5` من عهدة بضاعة المشتري.

لا توجد قيود يومية ولا قيود في `supplier_ledger` لهذه الفاتورة، ولا توجد دفعة مسجلة لها. وهذا هو السلوك الصحيح لمشتريات السوق السريع المسوّاة من عهدة المشتري: الاستلام ينقل البضاعة من عهدة المشتري إلى المخزن، ولا ينشئ تلقائيًا ذممًا دائنة على المورد.

دالة `purchase_post_buyer_invoice_atomic` تشترط صلاحية المشتريات والمالية، لكنها ترفض `QUICK_MARKET` عمدًا ولا تسمح بتحويل فاتورة عهدة المشتري إلى مسار ذمم المورد. أما `purchase_post_invoice_atomic` للفواتير المرتبطة بـPO فيتحقق من الاستلام والكميات والوحدات والأسعار، ثم يغيّر حالة الفاتورة إلى `Posted` **دون إعادة حركة المخزون أو التزام المورد**؛ لأن الاستلام الفعلي في مسار PO أنشأ تلك الآثار بالفعل.

إذًا الإجراء المسمى «ترحيل» ليس زائدًا لكل فواتير الشراء:
- **Quick Market / Employee Custody:** لا يحتاج ترحيلًا إلى ذمم المورد؛ الاستلام والتسوية المالية حالتان منفصلتان.
- **PO-linked invoice:** الترحيل ضروري لإكمال مطابقة الفاتورة مع PO بعد الاستلام، ولا يجوز أن يكرر المخزون أو قيد المورد.
- **Legacy non-PO purchase:** يبقى له المسار القديم بعد التحقق من عقده وحالته.

### تعديل النظام الأم

في `main.html` تم تعديل تبويب فواتير الشراء لعرض ثلاثة أعمدة منفصلة:
1. حالة المستند: مسودة / مرحل / مدفوع...
2. الاستلام المخزني: مستلم بالكامل / استلام جزئي / بانتظار Receiver.
3. التسوية المالية: غير مسوّاة / بانتظار المالية / ذمة مورد مفتوحة / تمت التسوية...

لفواتير `QUICK_MARKET` التي مصدرها `EMPLOYEE_CUSTODY` يظهر توضيح «شراء سوق سريع — لا يُرحّل إلى ذمم المورد»، ولا يظهر زر ترحيل المورد. وتبقى أزرار الفواتير الأخرى المؤهلة للترحيل متاحة. كما صُححت رسالة نجاح الترحيل حتى لا تعد المستخدم بأن المخزون والقيد المالي أُنشئا مرة أخرى.

**Commit:** `d06affa82ca640b633c4ac33c457235bcbb29f21`.  
**Commit لاحق على main:** `8c26511ec34f143aa0c07779bad213aa7c5f74ed`.

## 5. اختبارات التحقق ونتائجها

### 5.1 Static / JavaScript

- Buyer scripts: parse success.
- Receiver standalone script: parse success.
- Receiver embedded module inside Warehouse: parse success.
- Parent `main.html`: two inline scripts parsed successfully بعد تعديل جدول الفواتير.
- اختبارات source assertions أكدت فصل الحالات، اختفاء زر ترحيل المورد عن Quick Market، بقاء ترحيل الفواتير الأخرى، وربط زر الترحيل دون inline handler.
- استُخرج renderer نفسه إلى harness ذاكرة محلية ببيانات مصطنعة: PINV-1004 ظهرت Draft + RECEIVED + UNSETTLED دون زر ترحيل مورد؛ وفاتورة PO Draft منفصلة احتفظت بزر الترحيل. PASS؛ لم تُكتب هذه البيانات إلى Supabase.

### 5.2 Edge read-model harness

اختُبرت دالة `getVisibleReceivingRows` بمحاكاة Supabase Query Builder:
- PO-only receipt returned when visible invoice list is empty: PASS.
- Merge visible QMP invoice receipts and standalone PO receipts: PASS.
- Deduplication by `operation_id`: PASS.

### 5.3 RLS read simulation

أُجريت قراءات داخل معاملات `BEGIN/ROLLBACK` مع JWT claims محلية:
- Buyer user with `purchases`: 7 receipt headers / 10 details visible.
- Receiver user: 7 headers / 10 details visible.
- `anon`: 0 / 0.
- Unauthorized authenticated subject: 0 / 0.

هذا يثبت شروط RLS في محاكاة سياق الهوية داخل قاعدة البيانات؛ ولا يُقدّم على أنه اختبار جلسة متصفح حقيقية.

### 5.4 Atomic receipt integration — rollback only

أُجري سيناريوهَا استلام داخل `DO` block في PostgreSQL، وتُركت جميع كتابات الاختبار داخل subtransaction انتهت بالـrollback:
- PO جزئي بكمية مرسلة 2.1234 ومقبولة 1.1234: سجل الحركة المقبولة فقط.
- القيد الناتج متوازن: مدين 50.55 ودائن 50.55.
- دفتر المورد سجل 50.55 مرة واحدة.
- نفس `operation_id` ونفس payload: `duplicate=true`.
- نفس `operation_id` مع payload مختلفة: رفض تعارض idempotency المتوقع.
- بعد retry لم تتكرر حركة المخزون.
- صفر كمية مقبولة: مستند الاستلام وتفاصيله سُجلا بدقة 4 منازل، وبقي PO معتمدًا؛ دون حركة مخزون أو قيد يومية أو دفتر مورد.

بعد الاختبار، أكدت استعلامات مستقلة أن عدد صفوف الاختبار المتبقية صفر في:
- `purchase_orders`
- `receiving`
- `inventory_log`
- `journal_entries`
- `supplier_ledger`

كما ظلت عدادات بيانات الأعمال كما كانت:
- receiving = 7
- receiving_details = 10
- PurchaseIn rows = 15
- PurchaseIn quantity = 219
- posted journals = 19
- supplier ledger net = 4,670 EGP

### 5.5 GitHub CI

على commit `d06affa82ca640b633c4ac33c457235bcbb29f21` نجحت:
- Mother System Browser E2E — run `43890920592`.
- Mother Inventory Forensic E2E — run `43890920335`.
- Standalone Unified Warehouse E2E — run `43890920281`.
- Mother full-file forensic gate — run `43890920397`.

Mother Browser E2E وWarehouse E2E استخدما Playwright وخادم مصدر محلي بحسب خطوات الـworkflow. هذا دليل CI Browser E2E على المصدر المختبر، وليس إثباتًا أن جلسة إنتاج مصادقًا عليها للمستخدم جُربت مباشرةً داخل متصفح المالك.

### 5.6 Cloudflare Production

لوحة Cloudflare أظهرت:
- Project: `rawaea-erp`
- Environment: Production
- Branch: `main`
- Automatic deployments: enabled
- Latest observed production commit: `8c26511ec34f143aa0c07779bad213aa7c5f74ed`
- Preview deployment: `https://761f3d4d.rawaea-erp.pages.dev/`

وبما أن `8c26511` لاحق لـ`d06affa` على نفس main، فإن إصلاح جدول فواتير الشراء موجود في النشر الذي ظهر في لوحة Production. لم تُثبت جلسة مستخدم حقيقية مصادق عليها بعد تحديث الصفحة؛ لذلك يبقى قبول المتصفح الفعلي بحساب مالك/مالية **غير منفذ في هذه الجلسة**.

## 6. استثناء محاسبي مفتوح — فرق 20 EGP

المطابقة السابقة أظهرت:
- حساب الذمم الدائنة 211 في الأستاذ العام: 4,690 EGP.
- صافي دفتر الموردين الفرعي: 4,670 EGP.
- الفرق: 20 EGP.

تم تحديد القيدين المصدر:
- `JE-4F149BF343BD4A55BC6B`، المرجع `QA-CLEANUP-20260923:IN-12`: مدين مخزون 124 بقيمة 10، ودائن موردين 211 بقيمة 10.
- `JE-B7DEBA9686E74629A6B9`، المرجع `QA-CLEANUP-20260923:IN-22`: مدين مخزون 124 بقيمة 10، ودائن موردين 211 بقيمة 10.

القيدان مرحّلان، لكن لا يحتوي سطرا الموردين على `party_id` أو `party_type`، ولم يوجد سجل `inventory_log` مطابق لـIN-12 أو IN-22. لذلك لا يوجد دليل يحدد أي مورد ينبغي أن يُحمّل المبلغ.

**القرار:** لم أحذف أو أعدل القيود، ولم أضف رصيدًا لمورد افتراضي، ولم أُنشئ قيد موازنة. يلزم تحديد مستند/مورد المصدر أو اعتماد حساب التسوية المناسب من المسؤول المحاسبي قبل أي قيد تصحيحي. هذا استثناء محاسبي حقيقي ما زال OPEN.

## 7. بيانات QA المحمية

- `QA-SR-PO-20260927` ومرجعه مرتبطان باختبار دائم لعقد SupplierReturn، وملاحظة الأمر تنص على أنه Permanent QA reference.
- الأمر يظهر `qty_received=5` دون مستند receiving أو حركة مخزون أو قيد؛ لم أعدّل الكمية أو الحالة ولم أنشئ استلامًا افتراضيًا.
- لم يتم تعديل `QA-SR-INV-20260927` أو حذفها؛ حالتها Legacy Unverified وتحتاج تحقيق منشأ منفصل.

## 8. سلامة الإنتاج

لم يحدث في هذه المهمة:
- أي UPDATE/DELETE على فواتير أعمال حقيقية أو أوامر الشراء القائمة.
- أي حركة مخزون دائمة أو تعديل مباشر في `stock_branches`.
- أي حركة خزينة/صندوق أو صرف/قبض نقدي.
- أي قيد مالي دائم أو تغيير في دفتر مورد حقيقي.
- أي إنشاء بيانات اختبار دائمة.

تغييرات الإنتاج اقتصرت على تعريف أعمدة الاستلام، سياسات قراءة RLS، publication، الفهارس المحددة، ونشر Edge Function الحالية. أما واجهات التطبيقات فتغيرت في GitHub ثم شملها نشر Cloudflare Production.

## 9. المتبقي وشروط الإغلاق النهائي

| العنصر | الحالة | شرط الإغلاق |
|---|---|---|
| قراءة مستندات استلام PO المستقلة | CLOSED | مصدر + RLS simulation + Edge deployed |
| Realtime receiving/details | CLOSED AT SOURCE/DB | publication + subscriptions + CI |
| دقة 4 منازل وIdempotency | CLOSED IN ROLLBACK TEST | precision + same-payload duplicate + changed-payload conflict |
| استلام صفر المقبول دون أثر | CLOSED IN ROLLBACK TEST | مستند استلام فقط دون stock/GL/AP |
| حالة PINV-1004 | CLOSED BY DESIGN/UX | استلام 120 أساس مثبت، لا ترحيل مورد، الواجهة تفصل الحالات |
| ترحيل فاتورة PO بعد الاستلام | PRESERVED | يستمر كإكمال مطابقة الفاتورة دون تكرار stock/AP |
| فرق 20 EGP في حساب 211 | OPEN — ACCOUNTING REVIEW | تحديد مصدر المورد أو اعتماد حساب تسوية وقيد موثق |
| قبول المتصفح المصادق عليه للإنتاج | UNVERIFIED | فتح Parent بعد النشر بحساب مخول وفحص الجدول الفعلي |
| نشر Edge Function | CONFIRMED | Version 42 ACTIVE وsource parity |
| Cloudflare Production | CONFIRMED AT DEPLOYMENT METADATA | commit 8c26511 على Production/main |

**حكم CTO:** الإصلاحات التقنية المستهدفة لمسار الاستلام وقراءة مستنداته وإعادة المحاولة وحالة فواتير السوق السريع نُفذت وتم التحقق منها بأدلة المصدر وقاعدة البيانات واختبارات التراجع وCI. لا تُعتبر التسوية المحاسبية لفرق 20 جنيهًا مغلقة، ولا يُدعى اجتياز جلسة مستخدم إنتاجية مصادق عليها حتى تُنفذ مشاهدة المتصفح الفعلية.

## 10. المراجع

- [Parent main.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/main.html)
- [Buyer.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/purchasing/buyer.html)
- [Receiver.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/receiver.html)
- [Unified Warehouse](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/warehouse/warehouse.html)
- [save-purchase-order Edge Function](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/functions/save-purchase-order/index.ts)
- [Parent UI commit d06affa](https://github.com/papamohammed77-glitch/erp-frontend/commit/d06affa82ca640b633c4ac33c457235bcbb29f21)
- [Current operational HEAD 8c26511](https://github.com/papamohammed77-glitch/erp-frontend/commit/8c26511ec34f143aa0c07779bad213aa7c5f74ed)
- [Mother System Browser E2E run 43890920592](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43890920592)
- [Mother Inventory Forensic E2E run 43890920335](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43890920335)
- [Standalone Unified Warehouse E2E run 43890920281](https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43890920281)
- [CURRENT_STATE](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/CURRENT_STATE.md)
