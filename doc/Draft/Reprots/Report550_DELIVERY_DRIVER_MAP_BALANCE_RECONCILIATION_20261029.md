# Report550 — التحقيق الجنائي للخريطة ورصيد مندوب التوصيل

**التاريخ:** 2026-10-29  
**النطاق:** تطبيق مندوب التوصيل فقط — خريطة مواقع عملاء الرانشيت وتبويب «رصيدي».  
**Production project:** `fiilmooggumokxanwiyx`  
**الحالة:** `SOURCE PATCH COMMITTED / LIVE RLS POLICIES CONFIRMED / BALANCE READ-ONLY CHECK PASS / CUSTOMER LOCATION DATA MISSING / PUBLISHED BROWSER E2E UNVERIFIED / NOT CLOSED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** الخريطة يجب أن تعرض المواقع الحقيقية للأوردرات غير الملغاة في الرانشيت المسند للمندوب. لا يجوز وضع علامة من اسم العميل أو عنوان غير موثق. تبويب الرصيد يجب أن يميز قيمة البضاعة المحملة، وقيمة ما تم تسليمه، والمرتجع، والنقد المستحق، والفرق غير المسوّى.
- **Architecture Understanding:** `driver.html → Supabase PostgREST/RLS → orders/customers/order_details/runsheets`. التسليم والمرتجعات يحدّثان كميات `order_details` من خلال عقود Core الموجودة.
- **Database Understanding:** الحقول الفعلية تشمل `orders.latitude/longitude/shipping_address/delivery_fee`، و`customers.location_lat/location_lng/address/location/area`، و`order_details.qty_loaded/qty_delivered/qty_returned/unit_price`.
- **Historical Understanding:** تمت مقارنة Current operational source مع `Original/PWA/delivery/driver.html` في مستودع `rawaie-erp-New` ومع `rawaie-erp-review/PWA/delivery/driver.html`. النسخة التاريخية لم تكن كافية وحدها لإثبات Production.
- **Production Understanding:** أُجريت قراءة مباشرة من Supabase Production في جلسة المراجعة؛ حالة `RS-1=Delivering`، وهو مسند إلى `driver@rawaea.com`. لم تُنفذ أي عملية تسليم/مرتجع أو تغيير بيانات أعمال.
- **Current Understanding:** آخر ملف تشغيل مقروء مباشرة هو `erp-frontend/companies/company-1/delivery/driver.html`, blob قبل التعديل `d338e7df93bedf79740d9478594b9738a9e518ee`.
- **Execution Confidence:** مرتفع في إثبات حالة البيانات والكود الساكن؛ غير كافٍ لإغلاق Browser/Cloudflare Production E2E.

### حالة الإثبات قبل التعديل

- **Confirmed:** الرانشيت الحالي وأوردراته موجودة؛ سياسة قراءة العملاء للمندوب المسند موجودة في Production؛ المصدر يستخدم إحداثيات الأوردر أو العميل ولا ينبغي أن يختلق إحداثيات.
- **Unknown:** هوية ملف HTML الذي يخدمه Cloudflare بعد أحدث commit، واختبار PostgREST/Browser من جلسة مندوب حقيقية بعد الإصلاحات.
- **Conflict:** لا يوجد تعارض مثبت بين مصدر الخريطة وسياسة القراءة بعد آخر migration؛ توجد فجوة بيانات فعلية في المواقع.
- **Unverified:** عرض الخريطة المنشورة في المتصفح، وE2E المالي بعد التغيير.

## 2. مصادر الحقيقة التي فُحصت

1. `CURRENT_STATE.md` في `rawaie-erp-New`، وبدأت المراجعة من أحدث الأحداث المسجلة LVE-549 ثم 548 و547 و546 و545.
2. [Report545 — Governance/Delivery](Report545_GOVERNANCE_AUDIT_AND_DELIVERY_OWNER_PATCH_RESET_20261029.md).
3. [Report546 — Runsheet Assignment](Report546_DELIVERY_DRIVER_RUNSHEET_ASSIGNMENT_FIX_20261029.md).
4. [Report547 — Start Trip Contract](Report547_DELIVERY_DRIVER_START_TRIP_ASSIGNMENT_CONTRACT_FIX_20261029.md).
5. [Report548 — Assigned Orders RLS](Report548_DELIVERY_DRIVER_ASSIGNED_ORDERS_RLS_FIX_20261029.md).
6. [Report549 — Item Images and Vehicle Stock RLS](Report549_DELIVERY_DRIVER_ITEM_IMAGES_AND_VEHICLE_STOCK_RLS_FIX_20261029.md).
7. Current operational source: [driver.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/delivery/driver.html).
8. Historical sources: `rawaie-erp-review/PWA/delivery/driver.html` و`rawaie-erp-New/Original/PWA/delivery/driver.html`.
9. Live Production `pg_policies`, `information_schema.columns`, `runsheets/orders/customers/order_details`, `app_settings`, و`complete_return_atomic` / `complete_order_delivery_atomic`.

## 3. Live Production — خريطة مواقع العملاء

وقت القراءة المباشرة: `2026-10-29 15:16:34.7979+00 UTC`.

| الرانشيت | الحالة | أوردرات غير ملغاة | أوردرات بإحداثيات أوردر | أوردرات بإحداثيات عميل | عناوين/مواقع نصية متاحة |
|---|---|---:|---:|---:|---:|
| RS-1 | Delivering | 3 | 0 | 0 | 0 |
| RS-2 | Loaded | 3 | 0 | 0 | 0 |

لكل من الأوردرات الستة التي شملها الفحص، حقول العنوان النصي `orders.shipping_address` و`customers.address` و`customers.location` فارغة، كما أن إحداثيات الأوردر والعميل غير مكتملة. لذلك لا يوجد مصدر موثوق يمكن تحويله إلى نقطة جغرافية.

### RLS

تم التحقق مباشرة من وجود السياسات التالية في Production، وكلها `SELECT` على `authenticated`:
- `orders_select_assigned_delivery`
- `customers_select_assigned_delivery`
- `order_details_select_assigned_delivery`
- `run_sheet_details_select_assigned_delivery`

إذن لا يجوز تكرار إصلاح RLS أو توسيع الصلاحيات دون دليل جديد. لا يمكن لسياسة القراءة أن تعوّض غياب بيانات الموقع.

### تعديل المصدر الجراحي

كانت رقعة commit `8ef8a38eb94a2f4a4e8fa6bd270e2c87c54d175c` قد حسّنت الخريطة: إحداثيات الأوردر أولًا، ثم إحداثيات العميل، ورسالة واضحة عند تعذر القراءة أو غياب الموقع. لكنها كانت تبني رابط بحث تقريبي من اسم العميل عند غياب عنوان/موقع، وهو ليس موقعًا جغرافيًا وقد يرسل اسمًا شخصيًا إلى خدمة خارجية دون فائدة موثوقة.

أُصلح ذلك في المصدر:
- لم يعد اسم العميل يدخل في `searchText`.
- لا يُنشأ بحث خرائط بديل من اسم العميل عندما لا توجد حقول موقع/عنوان.
- إذا توفرت حقول عنوان/منطقة فعلية، يظل رابط البحث التقريبي ممكنًا، مع إبقاء التحذير بأنه ليس إحداثيات مؤكدة.

**مهم:** لا يمكن عرض Pin حقيقي لأي من أوردرات `RS-1` الحالية قبل تسجيل موقع/عنوان صحيح في سجل العميل أو الأوردر. لم أختلق إحداثيات ولم أغيّر بيانات العملاء. الإجراء الدائم هو استكمال الموقع الحقيقي من مصدر العمل المعتمد، ثم تظهر العلامة من المصدر الحالي تلقائيًا.

## 4. Live Production — تبويب «رصيدي»

### 4.1 عقد الكميات

قراءة `complete_return_atomic` تؤكد أن الكمية التي يمكن إرجاعها للرانشيت تُحسب على أساس:

`qty_loaded - qty_delivered - qty_returned`

وتحدّث الدالة `qty_returned` دون تجاوز الكمية المتبقية. لذلك فرق البضاعة غير المسوّى:

`loaded value - delivered value - returned value`

متوافق مع معنى كميات دورة الرانشيت في Core الحالي؛ ويجب عدم تسمية الفرق «عجزًا نهائيًا» قبل اكتمال المرتجعات.

### 4.2 قراءة فعلية للأوردرات الموجودة

| الرانشيت | قيمة المحمّل | قيمة المسلّم | قيمة المرتجع | الفرق غير المسوّى | قيمة البضاعة النقدية المسلّمة |
|---|---:|---:|---:|---:|---:|
| RS-1 | 1,113.00 | 0.00 | 0.00 | 1,113.00 | 0.00 |
| RS-2 | 578.00 | 0.00 | 0.00 | 578.00 | 0.00 |

هذه النتائج تتسق مع حالة البيانات: أوردرات `RS-1` في `Loaded` داخل الرانشيت، لكن كميات التسليم المسجلة صفر. لا يجوز تحويل قيمة المحمّل إلى نقد مطلوب توريده قبل تسجيل تسليم فعلي.

### 4.3 الإصلاح الجراحي

في commit `8ef8a38eb94a2f4a4e8fa6bd270e2c87c54d175c`، كانت `renderBalance()` تقرأ `order.delivery_fee` لكنها تحسب رسوم التوصيل من `app_settings.delivery_fee` الحالية. هذا يخلط إعدادًا افتراضيًا حاليًا مع قيمة الرسوم المسجلة على الأوردر نفسه، وقد يعيد حساب أوردر قديم برسوم تغيّرت لاحقًا.

تم تغيير سطر واحد ليستخدم الرسوم المثبتة على الأوردر:

`Math.max(0, Number(order.delivery_fee) || 0)`

وأزيل متغير الإعداد العام الذي أصبح غير مستخدم. لم تتغير كميات المخزون أو حالات الأوردرات أو القيود المالية.

### 4.4 ما لم يُدّعَ إغلاقه

- لم يتم إثبات سيناريو خصم/دفع مقدم أو فاتورة بها ضريبة غير صفرية؛ لذلك لا أزعم اكتمال جميع الحالات المحاسبية.
- لا يوجد في بيانات `RS-1` الحالية تسليم فعلي يسمح باختبار تحصيل نقدي واقعي دون إحداث تغيير أعمال.
- يجب أن يبقى أي مبلغ ضريبي محسوب من إعداد عام موضع مراجعة إذا أُضيف مستقبلًا snapshot ضريبي ثابت على مستوى الأوردر؛ لا يجوز استنتاج ذلك من قيم اليوم.

## 5. التغييرات وسجل الأثر

### Operational source

- الملف: `companies/company-1/delivery/driver.html`
- قبل التعديل: blob `d338e7df93bedf79740d9478594b9738a9e518ee`
- commit إصلاح الخريطة والرصيد السابق: `8ef8a38eb94a2f4a4e8fa6bd270e2c87c54d175c`
- commit هذا التصحيح: `97e61153dc2ed1bd346abe4e684ee2a109e4c05f`
- commit إزالة المتغير غير المستخدم: `d2f4d26ea354533ce70553edeb484f2641c757e4`
- blob النهائي: `57fe50482bfe58302fd797664dda1571b8afd724`

### Static validation

تم جلب المصدر النهائي مباشرة من GitHub، وفحص كتلتَي JavaScript المضمنتين عبر محلل JavaScript:
- Script 1: PASS
- Script 2: PASS
- لا تعديل على `main.html` أو `core.js` أو Edge Functions أو مخطط Production في هذه الجولة.

### Production mutation / baseline

- لا DDL أو ACL أو RLS أو RPC أو Edge changes في هذه الجولة.
- لا تعديل على العملاء أو الأوردرات أو الرانشيتات أو الكميات أو القيود.
- لا fixtures أو بيانات اختبار جديدة.
- لم يُضغط «بدء الرحلة» ولم يُنفذ تسليم أو مرتجع.

## 6. Remaining Gaps — لا تُخفَ

1. **Customer location data — OPEN:** يلزم إدخال الإحداثيات أو العنوان الصحيح للعملاء من مصدر موثوق. لا يمكن لأي إصلاح برمجي استنتاج مواقع صحيحة من سجلات فارغة.
2. **Published Cloudflare artifact — UNVERIFIED:** commit المصدر لا يثبت وحده أن النسخة المنشورة تخدم هذا الـblob.
3. **Authenticated browser/PostgREST E2E — UNVERIFIED:** يلزم تحديث التطبيق في جلسة مندوب حقيقية والتحقق من RS-1 دون إعادة بدء الرحلة.
4. **Full accounting edge cases — OPEN:** لم تُختبر حالات الخصم، الدفعات المقدمة، والضريبة غير الصفرية على بيانات معزولة ذات عقد مثبت.

## 7. SELF-AUDIT FINAL

- **What I Proved:** مصدر التطبيق الحالي؛ التغيير الدقيق في الرسوم والبحث؛ سياسات القراءة الحية؛ غياب إحداثيات/عناوين RS-1 وRS-2؛ اتساق معادلة الكمية المتبقية مع `complete_return_atomic`; نتائج التجميع الفعلية.
- **What I Did Not Prove:** أن Cloudflare نشر blob النهائي؛ أن الواجهة تعمل في متصفح مصادق عليه بعد النشر؛ كل حالات الحساب المالي غير الممثلة في البيانات.
- **What I Fixed:** استخدام `orders.delivery_fee` بدل الإعداد العام الحالي؛ منع إنشاء رابط بحث من اسم العميل عند غياب عنوان/موقع.
- **What I Initially Missed:** commit `8ef8a38` سبق هذه المراجعة وغيّر بالفعل الخريطة والرصيد؛ عومل كتغيير قائم وتمت مراجعته بدل تكرار العمل.
- **What Could Still Be Wrong:** وجود عقد ضريبي/دفعات مقدمة لم يُثبت من البيانات الحالية؛ عدم نشر آخر commit بعد.
- **Final Confidence:** مرتفع في التشخيص الساكن وقراءة Production؛ غير كافٍ لإغلاق E2E.
- **Final Closure Status:** `SOURCE PATCH COMMITTED / LIVE RLS CONFIRMED / LOCATION DATA MISSING / PUBLISHED E2E UNVERIFIED / NOT 100% CLOSED`.
