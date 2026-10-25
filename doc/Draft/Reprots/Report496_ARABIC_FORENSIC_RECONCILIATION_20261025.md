# التقرير العربي للتحقيق الجنائي: تكامل تطبيق التحميل Loader مع تطبيق التحضير Picker
## الحدث LVE-2026-10-25-496 — مراجعة مستقلة وتصحيح مواصفات الرقعة

**تاريخ المراجعة:** 25 أكتوبر 2026  
**المستودع الذي يحتوي هذا التقرير:** `papamohammed77-glitch/rawaie-erp-New`  
**المصدر التشغيلي المعتمد:** `papamohammed77-glitch/erp-frontend`، الفرع `main`  
**الملف المستهدف الذي يطبّق المالك تعديلاته عليه:** `companies/company-1/warehouse/loader.html`  
**ملف المقارنة المرجعي:** `companies/company-1/warehouse/picker.html`  
**ملف الاعتماد المشترك المقروء دون تعديل:** `companies/company-1/core.js`

> **الحالة التنفيذية:** تم تجديد قراءة مصدر Loader وPicker وCore، وقراءة بيانات Edge المنشورة مباشرة من Supabase، والاستعلام عن تعريفات Core ومخطط Production. عيوب الواجهة وعقد إعادة الفتح مؤكدة من الأدلة الحالية. لم تُعدّل ملفات HTML التشغيلية، ولم تُنشر Edge Function، ولم تُنفذ حركة مخزون أو تعديل بيانات أعمال. هذا التقرير ليس إعلان إغلاق.

---

# 1. التدقيق الذاتي قبل التغيير

| المحور | التقييم | ما يسنده |
|---|---|---|
| فهم الأعمال | مؤكد في نطاق التحميل والتحضير | انتقال الرانشيت من Picked إلى Loading ثم Loaded، مع مسار عكسي لإعادة فتح التحميل. |
| فهم المعمارية | مؤكد | الواجهة تستدعي RW_Auth وRW_API وتقرأ البيانات؛ الآثار الفعلية للمخزون يجب أن تبقى داخل PostgreSQL Core. |
| فهم قاعدة البيانات | مؤكد في العناصر التي استُعلم عنها | قراءة مباشرة لمخطط users وrunsheets وتعريفات RPC وصلاحياتها ومحفزات التزامن. |
| فهم التاريخ | مؤكد جزئيًا | تمت مراجعة سجل الحالة التاريخي الذي يجمع أحداث 492–496؛ التقارير التاريخية استُخدمت لتحديد مواضع المقارنة لا كبديل عن الفحص الحالي. |
| فهم Production | مؤكد لبيانات Edge وSQL المقروءة | تمت قراءة قائمة Edge ووحدات المصدر المنشورة والاستعلام عن تعريفات Core وACL. |
| فهم المصدر التشغيلي | مؤكد | أعيد جلب الملفات التشغيلية من erp-frontend/main. |
| الثقة في الإغلاق التشغيلي | غير كافية للإغلاق | لم يُنفذ اختبار متصفح مصادق كامل، ولم يثبت تطابق HTML الذي تقدمه Cloudflare مع Git، ولم يُنفذ اختبار E2E معزول كامل. |
| صلاحية تعديل HTML | محظورة على المساعد في هذه المهمة | الدستور التشغيلي writing-block.md يمنع تعديل loader.html وpicker.html وmain.html مباشرة ويحمّل المالك تطبيق رقعة المصدر. |
| صلاحية تعديل Production في هذه الدورة | لم تُستخدم | لم يُنشر إصلاح غير مختبر ولم تُنفذ عملية أعمال إنتاجية. |

## 1.1 سجل الأدلة التي تمت قراءتها

- `doc/Draft/Reprots/writing-block.md`، بما فيه تعريف المهمة والملفات المحظور تعديلها ومتطلبات الرقعة والتقرير.
- `CURRENT_STATE.md`، وبالأخص نقاط الحالة للأحداث LVE-492 و493 و494 و495 و496.
- `erp-frontend/main:companies/company-1/warehouse/loader.html`.
- `erp-frontend/main:companies/company-1/warehouse/picker.html`.
- `erp-frontend/main:companies/company-1/core.js`.
- سجل Edge الحي ومصدر `start-loading` و`complete-loading` و`cancel-loading` و`reopen-loading`.
- PostgreSQL Production: أعمدة `public.users` و`public.runsheets`، وتعريفات دوال التحميل وإعادة الفتح وحركة المخزون، وACL، ومحفزات `runsheets` و`order_details`.

## 1.2 توقيت قراءة Production

الاستعلام المباشر الأخير أعاد وقتًا قدره **2026-10-25 17:35:36.756 UTC**، مع PostgreSQL 17.6. هذا التوقيت يخص لقطة SQL. وقراءة سجل Edge الحي في الجلسة نفسها أعادت الإصدارات والأرقام الموضحة أدناه. لا يُعامل توقيت تقرير أقدم بوصفه دليلًا على الحالة اللحظية.

---

# 2. تحديد المصدر التشغيلي الصحيح

| الأصل | المسار التشغيلي | Git blob SHA المقروء |
|---|---|---|
| Loader | `erp-frontend/companies/company-1/warehouse/loader.html` | `f478a78b9e5999cf44f7f65e06341b3036bfdcc9` |
| Picker | `erp-frontend/companies/company-1/warehouse/picker.html` | `d483bd15b36585b975b63c2ef641481a01d5d084` |
| Core | `erp-frontend/companies/company-1/core.js` | `ff2f581d9900543c16f7cb026e13446520c0329d` |

**تصحيح منهجي مهم:** مسارات `rawaie-erp-New/Current/PWA/warehouse/loader.html` وما يماثلها ليست المصدر التشغيلي المعتمد لهذه المهمة. لا يجوز مساواة النسخة التاريخية أو المرآة الحالية بالملف الذي يجري تطويره ونشره فعليًا.

كما أن المصدر التشغيلي الحالي يحتوي بالفعل على اختيار مركبة التحميل ويرسل `{runsheet_code, vehicle_id}` إلى `start-loading`. هذا يُبطل أي ادعاء تاريخي بأن اختيار المركبة غير موجود الآن. يجب الحفاظ على هذا الإنجاز وعدم إعادة تنفيذه أو حذفه.

---

# 3. لقطة Production الحية

| Edge Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `start-loading` | 6 | ACTIVE | true | `b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1` |
| `complete-loading` | 11 | ACTIVE | true | `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |
| `cancel-loading` | 5 | ACTIVE | true | `65fdfe2066dac1779c1e82b27a958a13d71604808af8a33ca12779ac5b7c0c89` |
| `reopen-loading` | 2 | ACTIVE | true | `89cac4219673154832b294d74b810c98154b7a46464a893eb8f119439e358350` |

هذه القيم مأخوذة من سجل Supabase المباشر. `ezbr_sha256` هو بصمة حزمة النشر وليس Git commit SHA؛ لا توجد هنا دعوى بتطابق بايت-ببايت بين Git والحزمة المنشورة.

## 3.1 حقائق قاعدة البيانات والأمن

- يحتوي `public.users` على `id` و`company_id` و`auth_id` و`email` و`status`. هوية Auth هي `auth.users.id`، ويربطها `public.users.auth_id`، بينما `public.users.id` هو معرّف المستخدم التطبيقي الذي ترتبط به حقول مثل `runsheets.loader_id`.
- دالة `complete_runsheet_loading(uuid,uuid,jsonb,text)` تعمل بصلاحية `SECURITY DEFINER`، وACL المقروء يمنع `anon` و`authenticated` من EXECUTE ويمنحه لـ`service_role` و`postgres`.
- دالة `complete_runsheet_reopen_loading(uuid,text,text,text)` تعمل بصلاحية `SECURITY DEFINER`، وتتحقق من حالة الرانشيت ودورة التحميل، وتستدعي `post_stock_movement` لعكس التحميل عبر Unloading، ثم تنشئ دورة تحميل جديدة.
- محفز `trg_sync_run_sheet_details` على `order_details` يستدعي `sync_run_sheet_details()`. لا ينبغي إدخال تحديث مباشر من المتصفح إلى `run_sheet_details.qty_loaded` كحل بديل.
- سلسلة الثقة الصحيحة هي: HTTP مصادق → Edge يتحقق من JWT ويستخرج المستخدم والشركة → استدعاء Core بواسطة service_role → Core يطبق حركة المخزون المركزية.
- القراءة كانت للبيانات والمخطط والتعريفات؛ لم يتم تعديل أي صف تشغيل أو مخزون أو سجل حركة.

---

# 4. العيوب المثبتة والسبب الجذري

## D1 — تقدم التحميل غير محفوظ محليًا

مكتبة Dexie محملة في Loader، لكن التطبيق لا يستخدمها لتخزين جلسة التحميل واستعادتها. الدالة `_startSession` تبني كائنًا في الذاكرة، وتعديل الكميات يغير ذلك الكائن ثم يعيد الرسم. إعادة تحميل الصفحة أو إغلاقها قد يفقد التعديلات المحلية التي لم تُرسل إلى الخادم.

**العلاج المطلوب:** مخزن Dexie خاص بتطبيق Loader، مع حفظ المسودة بعد كل تعديل وعند الإيقاف المؤقت. لا تستعاد المسودة إلا إذا تطابقت هوية الشركة والمستخدم والرانشيت والمركبة ودورة التحميل ووقت بدء الدورة. يجب أن تكون مفتاحية التخزين المحلية مركبة لتجنب تصادم رقم الرانشيت بين الشركات أو المستخدمين.

**تصحيح أضفته إلى مواصفات الرقعة العربية:** المقترح السابق كان يستخدم `runsheet_code` وحده كمفتاح أساسي محلي. هذا غير كافٍ في بيئة متعددة الشركات؛ قد يؤدي إلى استبدال مسودة شركة بمسودة أخرى تحمل رقم الرانشيت نفسه. النسخة المصححة تستخدم مفتاح Dexie مركبًا من `company_id + loader_id + runsheet_code`. كما تم تصحيح عمليات القراءة والحذف لتستخدم المفتاح المركب نفسه.

الإيقاف المؤقت محلي فقط: لا يغيّر حالة الرانشيت ولا يفرج عن الحجز ولا ينشئ حركة مخزون.

## D2 — إرسال أسطر كمية تحميلها صفر

تطبيق Loader يضم كل الأصناف إلى مصفوفة الإرسال، حتى إذا كانت `qty_loaded = 0`. لكن `complete-loading v11` المنشورة ترفض أي عنصر تكون `loaded_qty <= 0`. لذلك قد تفشل عملية تحميل صحيحة جزئيًا بسبب وجود صنف واحد لم يُحمّل.

**العلاج المطلوب:** إبقاء جميع الأصناف في ملخص التأكيد، لكن إرسال الأصناف ذات الكمية الموجبة فقط. إذا لم يوجد أي صنف بكمية موجبة، يجب إيقاف الإرسال وإظهار سبب واضح، لا استدعاء Edge ولا إنشاء حركة صفرية.

العقد المنشور يقبل `itemCode/loadedQty` وكذلك `item_code/loaded_qty`. إذن المشكلة المثبتة هي إرسال الأصفار، لا اختلاف حالة الأحرف في أسماء الحقول.

## D3 — الواجهة تسمح بتجاوز الكمية المحضّرة

حد الإدخال الحالي يعتمد `qty_ordered`، كما أن المسار يسمح بكمية أعلى من `qty_picked` إذا أضيفت ملاحظة. لكن Core يفرض أن الكمية المحمّلة لا تتجاوز الكمية المحضّرة. الملاحظة ليست تصريحًا لتجاوز هذا الحد.

**العلاج المطلوب:** استخدام `qty_picked` حدًا أعلى في الإدخال والتحقق قبل التأكيد، ورفض أي قيمة تتجاوزه. إذا قرر العمل التجاري مستقبلًا السماح بالزيادة، فيجب تعديل عقد الأعمال وCore صراحةً؛ لا يجوز فتح الاستثناء من الواجهة وحدها.

## D4 — طلب إعادة الفتح لا يرسل operation_id

عقد `reopen-loading v2` المنشور يشترط `runsheet_code` و`operation_id`، بينما طلب الواجهة الحالي يرسل رقم الرانشيت فقط.

**العلاج المطلوب:** إنشاء `operation_id` واحد للمحاولة المؤكدة، وإرساله مع رقم الرانشيت، وإعادة استخدام المعرف نفسه عند إعادة محاولة الطلب نفسه. لا تنشئ معرفًا جديدًا لكل retry، لأن ذلك يضعف ضمان idempotency.

## D5 — دالتا إعادة الفتح والإلغاء تستخرجان الشركة من app_settings.limit(1)

مصدر Production المنشور لـ`reopen-loading v2` و`cancel-loading v5` يستخدم استعلامًا من نوع `app_settings.select('company_id').limit(1)` بدل ربط مستخدم Auth بالمستخدم التطبيقي عبر `public.users.auth_id`. هذا عيب في تحديد سياق الشركة في نظام متعدد الشركات، وليس مجرد مشكلة عرض.

**العلاج الخلفي المطلوب لإعادة الفتح:**
1. التحقق من Bearer token بواسطة `supabase.auth.getUser(token)`.
2. قراءة صف المستخدم التطبيقي باستخدام `.eq('auth_id', user.id).maybeSingle()`.
3. اشتراط وجود `id` و`company_id` والتحقق من حالة المستخدم النشط.
4. اشتقاق `p_company_id` و`p_user_email` من الصف الموثوق؛ لا تقبل `company_id` من المتصفح كسلطة.
5. الحفاظ على عقد `runsheet_code + operation_id`.
6. التحقق من صلاحيات الملكية والانتقالات في Core قبل النشر.

**لا يجوز نشر تعديل مرتجل خاص بـProduction.** يجب استرجاع مصدر `reopen-loading` المنشور إلى مسار Current الرسمي، ومراجعته ومقارنته، ثم إصلاحه واختباره في بيئة معزولة، وبعدها فقط نشره والتحقق من النسخة الحية. لم يثبت في هذه الدورة أن هذا الإصلاح نُشر.

دالة `cancel-loading v5` تحمل نمط تحديد الشركة نفسه. يجب تسجيلها كعيب أمني مرتبط يحتاج إصلاحًا منضبطًا، لا اعتبارها سليمة لمجرد أن المهمة الأساسية تركز على إعادة الفتح.

## D6 — قائمة الرانشيتات المكتملة بلا نطاق شركة صريح

`renderCompletedTab` في Loader تصفي الحالة إلى `Loaded` وهوية المحمّل، لكنها لا تفرض `company_id` صراحةً وتسمح بمسار بديل يعتمد البريد الإلكتروني. عقد البيانات يجعل `runsheets.loader_id` مرتبطًا بمعرّف المستخدم التطبيقي `public.users.id`.

**العلاج المطلوب:** اشتراط وجود `currentUser.company_id` و`currentUser.id`، ثم تصفية الاستعلام بالشركة والحالة وهوية المحمّل معًا. يجب عرض خطأ الاستعلام صراحةً بدل تحويله إلى قائمة فارغة توحي بعدم وجود بيانات.

## D7 — الإيقاف المؤقت والإلغاء عمليتان مختلفتان

الإلغاء عبر `cancel-loading` ينفذ عملية خادمية ويعيد سياق الرانشيت إلى Picked وفق Core. أما الإيقاف المؤقت المطلوب فيحفظ مسودة محلية فقط ويعود إلى القائمة دون تغيير حالة الخادم أو دورة التحميل.

لا تُحذف المسودة المحلية إلا بعد نجاح مؤكد من الخادم في الإكمال أو الإلغاء. في حال انتهاء المهلة أو غموض النتيجة، يجب الاحتفاظ بالمسودة ومعرف العملية حتى تتضح النتيجة.

---

# 5. مصفوفة المسؤوليات

| المسؤولية | الحالة التي أثبتها الفحص | القرار |
|---|---|---|
| اختيار المركبة قبل بدء التحميل | موجود في Loader التشغيلي الحالي | **RETAINED** — يحظر التراجع عنه. |
| نطاق الشركة عند فتح الرانشيت | موجود في مسار الفتح الحالي | **RETAINED** مع إضافة نطاق صريح إلى القراءات الأخرى. |
| وصف الصنف وصورته ووحدته | يجري جلبها عبر علاقة items في الاستعلام | **RETAINED** — لا حاجة إلى تغيير المخطط لمجرد العرض. |
| حفظ مسودة التحميل محليًا | Dexie محملة لكن لا يوجد حفظ/استرجاع فعلي | **MISSING**. |
| إرسال الكميات الموجبة فقط | الواجهة ترسل صفوف الصفر | **MISSING**. |
| سقف الكمية المحمّلة | الواجهة تسمح بتجاوز الكمية المحضّرة بينما Core يرفض | **CONFLICT**. |
| operation_id عند إعادة الفتح | غير موجود في الطلب الحالي | **MISSING**. |
| تحديد الشركة في Edge لإعادة الفتح | يعتمد على أول صف إعدادات | **CONFLICT أمني**. |
| نطاق الشركة في قائمة المكتملة | غير صريح | **MISSING**. |
| حركة المخزون الفعلية | تمر عبر Core و`post_stock_movement` | **RETAINED** — لا كتابة مخزون من HTML. |
| الإيقاف المؤقت | غير موجود كحفظ محلي واستئناف | **MISSING**. |
| استمرار حفظ الملاحظات في الخادم | عقد Edge الحالي لا يحفظ الملاحظات | **UNVERIFIED / CONTRACT GAP**؛ لا تدّعِ أن الملاحظات محفوظة في الخادم. |

---

# 6. حدود التعديل: ما الذي لا يجوز تغييره

وفق `writing-block.md`:

- `main.html` محظور التعديل في هذه المهمة.
- `picker.html` مرجع للمقارنة ولا يُعدّل.
- `loader.html` التشغيلي لا يحرره المساعد مباشرة؛ المالك هو الذي يطبق رقعة المصدر.
- يجوز فحص الملفات ذات الصلة، لكن لا يُعدّل Core أو Edge أو قاعدة البيانات إلا بعد إثبات الحاجة واتباع قواعد المصدر والاختبار والنشر.

لا تنسخ Picker بالكامل إلى Loader. دور التطبيقين مختلف، والمطلوب نقل المسؤوليات الناقصة فقط مع المحافظة على التصميم البرتقالي الحالي في Loader واختيار المركبة الموجود بالفعل.

---

# 7. الرقع الجراحية المقترحة للمالك

> **مهم:** النصوص البرمجية التالية هي تعليمات تطبيق مصدرية، وليست تغييرات تم تنفيذها في المستودع التشغيلي. أُبقيت الدوال كاملة لتسهيل الاستبدال، وصُحح مفتاح التخزين المحلي ليكون مركبًا. قبل تطبيق أي رقعة، يجب إعادة جلب الملف والتحقق من أن بصمته ما زالت `f478a78b9e5999cf44f7f65e06341b3036bfdcc9`. إذا اختلفت البصمة، يجب إعادة المطابقة أولًا.

## الرقعة A — إنشاء مخزن Dexie خاص بالتحميل

**الموضع:** داخل JavaScript في Loader، مباشرة قبل `var App = {`.

يجب أن يكون المفتاح الأساسي مركبًا من الشركة والمحمّل ورقم الرانشيت. لا تستخدم رقم الرانشيت وحده، لتجنب التصادم بين الشركات والمستخدمين.

```javascript
var RW_LoaderDB = null;
try {
    if (typeof Dexie !== 'undefined') {
        RW_LoaderDB = new Dexie('RW_Loader');
        RW_LoaderDB.version(1).stores({
            sessions: '[company_id+loader_id+runsheet_code], company_id, loader_id, runsheet_id, loading_cycle_id'
        });
    }
} catch (loaderDbInitError) {
    console.error('Loader local draft database initialization failed:', loaderDbInitError);
}
```

## الرقعة B — استبدال _startSession كاملة

**المحدد:** `_startSession: function(code, rs, items) {`

تحافظ النسخة التالية على حقول الصنف والصورة والوحدة والوصف، وتستعيد الكميات والملاحظات المحلية فقط إذا تطابقت هوية الشركة والمستخدم والرانشيت والمركبة والدورة ووقت البدء. إذا لم تتطابق الهوية، تُحذف المسودة القديمة ذات المفتاح المركب فقط، ثم تُبنى جلسة جديدة من بيانات الخادم.

```javascript
_startSession: function(code, rs, items) {
    var self = this;
    var session = {
        runsheet_code: code,
        company_id: rs.company_id,
        loader_id: rs.loader_id,
        runsheet_id: rs.id,
        vehicle_id: rs.vehicle_id || null,
        loading_cycle_id: rs.loading_cycle_id || null,
        loader_start: rs.loader_start || null,
        start_time: rs.loader_start || new Date().toISOString(),
        items: []
    };

    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        var product = it.items || {};
        if (Array.isArray(product)) product = product[0] || {};

        session.items.push({
            item_code: it.item_code,
            item_name: it.item_name || product.name || '',
            unit: it.unit || product.unit || 'حبة',
            description: product.description || '',
            image_url: product.image_url || '',
            unit_price: Number(it.unit_price) || 0,
            qty_ordered: Number(it.qty_ordered) || 0,
            qty_picked: Number(it.qty_picked) || 0,
            qty_loaded: Number(it.qty_loaded) || 0,
            notes: it.notes || ''
        });
    }

    function sameIdentity(saved) {
        return !!saved &&
            saved.runsheet_code === session.runsheet_code &&
            saved.company_id === session.company_id &&
            saved.loader_id === session.loader_id &&
            saved.runsheet_id === session.runsheet_id &&
            String(saved.vehicle_id || '') === String(session.vehicle_id || '') &&
            String(saved.loading_cycle_id || '') === String(session.loading_cycle_id || '') &&
            String(saved.loader_start || '') === String(session.loader_start || '');
    }

    if (!RW_LoaderDB) {
        self.session = session;
        RW_UI.toast('الحفظ المؤقت غير متاح على هذا الجهاز؛ ستظل التعديلات في الذاكرة الحالية فقط', 'warning');
        self.renderActiveSession();
        return;
    }

    RW_LoaderDB.sessions.get([session.company_id, session.loader_id, session.runsheet_code]).then(function(saved) {
        if (sameIdentity(saved)) {
            var byCode = {};
            for (var i = 0; i < saved.items.length; i++) {
                byCode[String(saved.items[i].item_code)] = saved.items[i];
            }
            for (var j = 0; j < session.items.length; j++) {
                var current = session.items[j];
                var previous = byCode[String(current.item_code)];
                if (previous) {
                    current.qty_loaded = Number(previous.qty_loaded) || 0;
                    current.notes = previous.notes || '';
                }
            }
        } else if (saved) {
            return RW_LoaderDB.sessions.delete([session.company_id, session.loader_id, session.runsheet_code]).then(function() {
                return null;
            });
        }
        return null;
    }).then(function() {
        self.session = session;
        return RW_LoaderDB.sessions.put(session);
    }).then(function() {
        self.renderActiveSession();
    }).catch(function(err) {
        console.error('Loader draft restore/save failed:', err);
        self.session = session;
        RW_UI.toast('تعذر استعادة الحفظ المؤقت. تم عرض بيانات الخادم دون ادعاء حفظ التعديلات المحلية.', 'error');
        self.renderActiveSession();
    });
},
```

## الرقعة C — استبدال editLoadedItem كاملة

**المحدد:** `editLoadedItem: function(idx, pre) {`

تفرض الكمية المحضّرة حدًا أعلى، وتنتظر نجاح الحفظ المحلي قبل إظهار نجاح الحفظ. إذا فشل الحفظ، تُستعاد القيمة السابقة وتظهر رسالة خطأ. الملاحظات تبقى محلية فقط حتى يتغير عقد الخادم رسميًا.

```javascript
editLoadedItem: function(idx, pre) {
    var s = this;
    if (!s.session || !s.session.items[idx]) return;
    var it = s.session.items[idx];
    var cur = (typeof pre !== 'undefined') ? pre : it.qty_loaded;

    Swal.fire({
        title: '<span class="text-slate-800">' + it.item_name + '</span>',
        html: '<div class="text-center mb-3">' +
            s._loaderImageHTML(it, 'w-full max-w-xs', 'h-72', 'object-contain') +
            '</div><div class="text-right text-sm space-y-2">' +
            '<div class="flex justify-between"><span class="text-slate-400">محضّر</span><strong>' + it.qty_picked + '</strong></div>' +
            '<div class="flex justify-between"><span class="text-slate-400">مطلوب</span><strong>' + it.qty_ordered + '</strong></div>' +
            (it.unit ? '<div class="flex justify-between"><span class="text-slate-400">الوحدة</span><strong>' + it.unit + '</strong></div>' : '') +
            '</div><div class="mt-4 text-right">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2">الكمية المحمّلة</label>' +
            '<input id="swal-qty" type="number" class="swal2-input !rounded-xl !text-center !font-bold !text-lg" value="' + cur + '" min="0" max="' + it.qty_picked + '">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2 mt-4">ملاحظات محلية</label>' +
            '<input id="swal-notes" class="swal2-input !rounded-xl" value="' + (it.notes || '') + '" placeholder="سبب النقص (يحفظ محليًا فقط)"> </div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        },
        didOpen: function() {
            s._bindLoaderImageFallbacks(Swal.getPopup());
        },
        preConfirm: function() {
            var p = Swal.getPopup();
            var qe = p ? p.querySelector('#swal-qty') : null;
            var ne = p ? p.querySelector('#swal-notes') : null;
            var value = qe ? Number(qe.value) : NaN;
            if (!Number.isFinite(value) || value < 0 || value > Number(it.qty_picked)) {
                Swal.showValidationMessage('الكمية يجب أن تكون بين صفر والكمية المحضّرة.');
                return false;
            }
            return { qty: Math.floor(value), notes: ne ? ne.value.trim() : '' };
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;
        var oldQty = it.qty_loaded;
        var oldNotes = it.notes;
        s.session.items[idx].qty_loaded = r.value.qty;
        s.session.items[idx].notes = r.value.notes;

        if (!RW_LoaderDB) {
            s.renderActiveSession();
            RW_UI.toast('تم التعديل في الجلسة الحالية فقط؛ الحفظ الدائم المحلي غير متاح', 'warning');
            return;
        }

        RW_LoaderDB.sessions.put(s.session).then(function() {
            s.renderActiveSession();
            if (r.value.qty < it.qty_picked && !r.value.notes) {
                Swal.fire({
                    title: 'تنبيه',
                    text: 'الكمية المحمّلة أقل من المحضّرة. هل تريد إضافة سبب؟',
                    icon: 'question',
                    showCancelButton: true,
                    confirmButtonText: 'إضافة سبب',
                    cancelButtonText: 'تخطي',
                    customClass: {
                        popup: '!rounded-3xl',
                        confirmButton: '!rounded-xl !bg-amber-500 !px-6',
                        cancelButton: '!rounded-xl'
                    }
                }).then(function(r2) {
                    if (r2.isConfirmed) s.editLoadedItem(idx, r.value.qty);
                });
            }
        }).catch(function(err) {
            s.session.items[idx].qty_loaded = oldQty;
            s.session.items[idx].notes = oldNotes;
            console.error('Loader draft write failed:', err);
            s.renderActiveSession();
            RW_UI.showError('تعذر حفظ التعديل محليًا؛ أُعيدت القيمة السابقة.');
        });
    });
},
```

## الرقعة D — إضافة pauseLoading

**الموضع:** بجوار `cancelLoading` داخل كائن App.

هذه العملية تحفظ المسودة ثم توقف المؤقت وتعيد المستخدم إلى القائمة. لا تستدعي `cancel-loading` ولا تغير حالة الخادم.

```javascript
pauseLoading: function() {
    var s = this;
    if (!s.session) return;
    if (!RW_LoaderDB) {
        RW_UI.showError('الحفظ المؤقت غير متاح؛ لن يتم إنهاء الجلسة أو مسح بياناتها.');
        return;
    }
    RW_LoaderDB.sessions.put(s.session).then(function() {
        if (s.timerInterval) clearInterval(s.timerInterval);
        s.timerInterval = null;
        s.session = null;
        RW_UI.toast('تم حفظ التحميل مؤقتًا على هذا الجهاز', 'success');
        s.renderPendingTab();
    }).catch(function(err) {
        console.error('Loader pause draft write failed:', err);
        RW_UI.showError('تعذر حفظ الجلسة؛ بقيت الجلسة مفتوحة ولم يتم تغيير حالة الرانشيت.');
    });
},
```

أضف الزر التالي في `renderActiveSession` قبل زر الإلغاء الحالي:

```javascript
h += '<button onclick="App.pauseLoading()" class="w-full mt-3 bg-amber-50 border border-amber-200 text-amber-700 py-3 rounded-2xl font-bold"><i class="fa-solid fa-pause ml-2"></i> حفظ مؤقت والعودة للقائمة</button>';
```

## الرقعة E — استبدال completeLoading كاملة

**المحدد:** `completeLoading: function() {`

يظل الملخص مبنيًا على كل الأصناف، لكن طلب HTTP لا يحتوي إلا الكميات الموجبة. تُرفض الكمية السالبة أو التي تتجاوز `qty_picked`. عند نجاح الخادم تُحذف المسودة باستخدام المفتاح المركب. عند الفشل أو النتيجة غير المؤكدة، لا تُمسح المسودة.

```javascript
completeLoading: function() {
    var s = this;
    if (!s.session) return;
    if (!navigator.onLine) {
        RW_UI.toast('غير متصل', 'warning');
        return;
    }

    var requestItems = [];
    var fullCount = 0, partialCount = 0, zeroCount = 0;
    var allItems = s.session.items;

    for (var i = 0; i < allItems.length; i++) {
        var it = allItems[i];
        if (it.qty_loaded < 0 || it.qty_loaded > it.qty_picked) {
            RW_UI.showError('الكمية المحمّلة يجب ألا تتجاوز الكمية المحضّرة.');
            return;
        }
        if (it.qty_loaded > 0) {
            requestItems.push({ itemCode: it.item_code, loadedQty: it.qty_loaded });
        }
        if (it.qty_loaded >= it.qty_ordered) fullCount++;
        else if (it.qty_loaded > 0) partialCount++;
        else zeroCount++;
    }

    if (!requestItems.length) {
        RW_UI.showError('لا يمكن إنهاء التحميل دون كمية موجبة واحدة على الأقل. لم يتم إرسال أي طلب.');
        return;
    }

    var summary = '<div class="text-right text-sm"><p>أنت على وشك إنهاء تحميل الرانشيت <strong>' +
        s.session.runsheet_code + '</strong>.</p><div class="mt-3 space-y-1">' +
        '<div>✅ <strong>' + fullCount + '</strong> أصناف مكتملة</div>' +
        '<div>⚠️ <strong>' + partialCount + '</strong> أصناف محمّلة جزئيًا</div>' +
        '<div>❌ <strong>' + zeroCount + '</strong> أصناف لم تُحمّل</div></div>' +
        '<p class="text-xs text-amber-700 mt-3">ملاحظات النقص محلية ولا تُرسل إلى عقد التحميل الحالي.</p></div>';

    Swal.fire({
        title: 'تأكيد إنهاء التحميل',
        html: summary,
        icon: 'info',
        showCancelButton: true,
        confirmButtonText: 'تأكيد',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;
        var cb = document.querySelector('.swal2-confirm');
        if (cb) {
            cb.disabled = true;
            cb.innerText = 'جارٍ...';
        }
        RW_UI.showLoader();
        RW_API.call('complete-loading', {
            runsheet_code: s.session.runsheet_code,
            items: requestItems
        }, function(json) {
            RW_UI.hideLoader();
            if (json && json.success) {
                var tq = 0, tv = 0;
                for (var j = 0; j < requestItems.length; j++) {
                    tq += requestItems[j].loadedQty;
                    for (var k = 0; k < allItems.length; k++) {
                        if (allItems[k].item_code === requestItems[j].itemCode) {
                            tv += requestItems[j].loadedQty * (Number(allItems[k].unit_price) || 0);
                            break;
                        }
                    }
                }
                var code = s.session.runsheet_code;
                var draftKey = [s.session.company_id, s.session.loader_id, code];
                function finishUi() {
                    Swal.fire({
                        icon: 'success',
                        title: 'تم إنهاء التحميل',
                        html: '<div class="text-right"><p>تم تحميل <strong>' + requestItems.length +
                            ' صنف</strong></p><p>إجمالي الكمية: <strong>' + tq +
                            '</strong></p><p>القيمة التقديرية: <strong>' +
                            RW_UI.formatNumber(tv) + ' EGP</strong></p></div>',
                        confirmButtonText: 'حسنًا',
                        customClass: { popup: '!rounded-3xl', confirmButton: '!rounded-xl !bg-orange-600' }
                    });
                    s.session = null;
                    if (s.timerInterval) clearInterval(s.timerInterval);
                    s.timerInterval = null;
                    s.renderPendingTab();
                }
                if (RW_LoaderDB) {
                    RW_LoaderDB.sessions.delete(draftKey).then(finishUi).catch(function(err) {
                        console.error('Loader completed draft cleanup failed:', err);
                        finishUi();
                        RW_UI.toast('اكتمل التحميل، لكن تعذر حذف المسودة المحلية القديمة', 'warning');
                    });
                } else {
                    finishUi();
                }
            } else {
                RW_UI.showError((json && json.msg) || 'فشل إنهاء التحميل. احتُفظ بالمسودة المحلية.');
            }
        });
    });
},
```

## الرقعة F — استبدال cancelLoading كاملة

**المحدد:** `cancelLoading: function(code) {`

لا تُمسح المسودة إلا بعد رد نجاح مؤكد. يستخدم الحذف المفتاح المركب للشركة والمحمّل والرانشيت؛ ولا يحذف مسودة تخص مستخدمًا آخر لمجرد تطابق رقم الرانشيت.

```javascript
cancelLoading: function(code) {
    var s = this;
    var u = s.currentUser;
    var draftKey = (u && u.company_id && u.id) ? [u.company_id, u.id, code] : null;
    RW_UI.showConfirm('إلغاء تحميل ' + code + '؟ ستعود حالة الرانشيت إلى جاهز للتحضير.', function() {
        RW_UI.showLoader();
        RW_API.call('cancel-loading', { runsheet_code: code }, function(json) {
            RW_UI.hideLoader();
            if (json && json.success) {
                function resetUi() {
                    RW_UI.toast('تم الإلغاء', 'success');
                    s.session = null;
                    if (s.timerInterval) clearInterval(s.timerInterval);
                    s.timerInterval = null;
                    s.renderPendingTab();
                }
                if (RW_LoaderDB && draftKey) {
                    RW_LoaderDB.sessions.delete(draftKey).then(resetUi).catch(function(err) {
                        console.error('Loader cancelled draft cleanup failed:', err);
                        resetUi();
                        RW_UI.toast('أُلغيت العملية، لكن تعذر حذف المسودة المحلية القديمة', 'warning');
                    });
                } else {
                    resetUi();
                }
            } else {
                RW_UI.showError((json && json.msg) || 'تعذر تأكيد الإلغاء؛ احتُفظ بالمسودة المحلية.');
            }
        });
    });
},
```

## الرقعة G — استبدال renderCompletedTab كاملة

**المحدد:** `renderCompletedTab: function() {`

الاستعلام يتطلب الشركة والمستخدم التطبيقي والحالة، ويتعامل مع خطأ القراءة باعتباره خطأ لا قائمة فارغة.

```javascript
renderCompletedTab: function() {
    var s = this;
    var u = s.currentUser;
    if (!u || !u.company_id || !u.id) {
        RW_UI.showError('تعذر تحديد الشركة أو المستخدم الحالي.');
        return;
    }
    RW_UI.showSkeleton('mainContent', 1, 'card');
    supabase.from('runsheets')
        .select('runsheet_code,run_date,status')
        .eq('company_id', u.company_id)
        .eq('status', 'Loaded')
        .eq('loader_id', u.id)
        .order('run_date', { ascending: false })
        .limit(50)
        .then(function(r) {
            if (r.error) {
                console.error('Loader completed runsheets query failed:', r.error);
                RW_UI.showError('تعذر تحميل الرانشيتات المكتملة.');
                return;
            }
            s.completedRunsheets = r.data || [];
            s.renderCompletedList(s.completedRunsheets);
        }).catch(function(err) {
            console.error('Loader completed runsheets request failed:', err);
            RW_UI.showError('تعذر تحميل الرانشيتات المكتملة.');
        });
},
```

## الرقعة H — استبدال reopenLoading كاملة

**المحدد:** `reopenLoading: function(code) {`

يضيف نطاق الشركة وهوية المحمّل إلى قراءة ما قبل التنفيذ، ويحفظ `operation_id` ويعيد استخدامه عند إعادة المحاولة. لا يرسل `company_id` من المتصفح بوصفه مصدر سلطة. إصلاح الواجهة وحده لا يعالج عيب تحديد الشركة في Edge.

```javascript
reopenLoading: function(code) {
    var s = this;
    var u = s.currentUser;
    if (!u || !u.company_id || !u.id || !code) {
        RW_UI.showError('تعذر تحديد الشركة أو المستخدم أو الرانشيت.');
        return;
    }

    supabase.from('runsheets')
        .select('status,runsheet_code,company_id,loader_id')
        .eq('company_id', u.company_id)
        .eq('runsheet_code', code)
        .eq('loader_id', u.id)
        .maybeSingle()
        .then(function(r) {
            if (r.error || !r.data || r.data.status !== 'Loaded') {
                if (r.error) console.error('Loader reopen precheck failed:', r.error);
                Swal.fire({
                    title: 'لا يمكن إعادة الفتح',
                    text: 'تعذر التحقق من أن الرانشيت مكتمل ويتبع حسابك الحالي.',
                    icon: 'warning',
                    customClass: { popup: '!rounded-3xl' }
                });
                s.renderCompletedTab();
                return;
            }

            RW_UI.showConfirm('إعادة فتح ' + code + '؟ سيتم عكس حركة التحميل وفق Core.', function() {
                var storageKey = 'rw-loader-reopen:' + u.company_id + ':' + code;
                var operationId = '';
                try {
                    operationId = localStorage.getItem(storageKey) || '';
                    if (!operationId) {
                        operationId = crypto.randomUUID();
                        localStorage.setItem(storageKey, operationId);
                    }
                } catch (storageError) {
                    RW_UI.showError('تعذر حفظ معرف العملية لإعادة المحاولة بأمان؛ لم يتم إرسال الطلب.');
                    return;
                }

                RW_UI.showLoader();
                RW_API.call('reopen-loading', {
                    runsheet_code: code,
                    operation_id: operationId
                }, function(j) {
                    RW_UI.hideLoader();
                    if (j && j.success) {
                        try { localStorage.removeItem(storageKey); } catch (_) {}
                        if (RW_LoaderDB) {
                            RW_LoaderDB.sessions.delete([u.company_id, u.id, code]).catch(function(err) {
                                console.error('Old Loader cycle draft cleanup failed:', err);
                            });
                        }
                        RW_UI.toast('تمت إعادة فتح التحميل', 'success');
                        s.renderPendingTab();
                    } else {
                        RW_UI.showError((j && j.msg) || 'فشلت إعادة الفتح؛ أُبقي معرف العملية لاستخدامه في إعادة المحاولة.');
                    }
                });
            });
        }).catch(function(err) {
            console.error('Loader reopen precheck request failed:', err);
            RW_UI.showError('تعذر التحقق من حالة الرانشيت.');
        });
},
```

---

# 8. مراجعة عقد Core وسلامة المخزون

العقد الذي يجب الحفاظ عليه:

1. يبدأ التحميل من حالة مناسبة مع مركبة صحيحة ضمن الشركة.
2. يحتفظ الرانشيت بـ`vehicle_id` و`loader_start` و`loading_cycle_id`.
3. لا تُقبل كمية محمّلة تتجاوز مجموع الكمية المحضّرة للصنف.
4. يمر الأثر الفعلي للمخزون عبر `post_stock_movement` فقط.
5. لا تُنشأ حركة مخزون لكمية صفرية.
6. يجب أن يكون إكمال التحميل متسقًا مع سجل `erp_operation_registry` ومعرّف دورة التحميل.
7. إعادة الفتح تعكس التحميل عبر Unloading ثم تنشئ دورة جديدة؛ لا يجوز للواجهة تعديل `qty` أو `allocated_qty` مباشرة.
8. لا يُقبل `company_id` المرسل من المتصفح لتحديد سياق الشركة.
9. لا يُمنح المتصفح صلاحية كتابة مباشرة على `run_sheet_details.qty_loaded` كاختصار.
10. يجب التعامل مع retry بعد انقطاع الاستجابة باعتباره احتمالًا لنجاح العملية على الخادم؛ لا تُنشأ هوية عملية جديدة للمحاولة نفسها.

**ملاحظة تحقق مهمة:** لا تزال إعادة محاولة إكمال التحميل بعد نجاح الخادم وفقدان الاستجابة بحاجة إلى اختبار فعلي يثبت سلوك Core؛ لا يُستنتج نجاح هذا السيناريو من وجود سجل idempotency وحده.

---

# 9. مصفوفة الاختبارات المطلوبة

لم تُنفّذ الاختبارات التالية في هذه الدورة، ولذلك جميعها **OPEN** حتى تنفيذها وتسجيل أدلتها.

1. **تحليل الملف الكامل:** استخراج كل السكربتات المضمنة في Loader النهائي والتحقق من عدم وجود أخطاء صياغة.
2. **بدء تحميل طبيعي:** من Picked إلى المعاينة، اختيار مركبة نشطة تتبع الشركة، ثم التأكد من إنشاء سياق Loading الصحيح.
3. **حفظ واستئناف المسودة:** تعديل كميات متعددة، حفظ مؤقت، العودة للقائمة، ثم فتح الرانشيت النشط نفسه واستعادة الكميات والملاحظات.
4. **رفض المسودة القديمة:** تغيير الشركة أو المستخدم أو المركبة أو الدورة في بيئة اختبار معزولة؛ يجب عدم استعادة مسودة بهوية مختلفة.
5. **تحميل جزئي:** صنف بكمية موجبة وآخر بصفر؛ يجب أن يحتوي الطلب الصادر على الصنف الموجب فقط، وأن تتم حركة المخزون عبر Core.
6. **كل الكميات صفر:** يجب أن تمنع الواجهة الإرسال ولا تنشئ حركة.
7. **تجاوز الكمية المحضّرة:** إدخال قيمة أعلى من `qty_picked` يجب أن يُرفض قبل الإرسال.
8. **إلغاء التحميل:** لا تُحذف المسودة إلا بعد نجاح مؤكد من Edge.
9. **إعادة فتح التحميل:** إرسال `operation_id` ثابت للمحاولة نفسها، والتحقق من انتقال Loaded → Loading ودورة جديدة وحركة Unloading صحيحة.
10. **عزل الشركات:** لا يمكن لحساب شركة قراءة أو إعادة فتح رانشيت شركة أخرى، حتى لو تطابق رقم الرانشيت.
11. **تكرار الطلب والتزامن:** إعادة الطلب نفسه بالتزامن أو بعد انقطاع الاستجابة، والتحقق من عدم مضاعفة حركة المخزون.
12. **التراجع واستعادة خط الأساس:** التأكد من عدم وجود بقايا من بيانات الاختبار، ومن مطابقة الأرصدة وسجلات الحركة قبل الاختبار وبعده.
13. **هوية النشر:** التحقق من HTML الذي تقدمه Cloudflare فعليًا، وعدم افتراض أنه يطابق Git لمجرد تحديث المصدر.
14. **اختبار مصادق كامل:** متصفح أو HTTP حقيقي باستخدام مستخدم اختبار معزول، من الواجهة إلى Edge ثم Core ثم قاعدة البيانات والعودة إلى الواجهة.
15. **فشل التخزين المحلي:** تعطيل Dexie أو محاكاة فشل الكتابة؛ يجب ألا تظهر رسالة نجاح كاذبة ولا تُمحى الجلسة.
16. **ملاحظات النقص:** التأكد من أن الواجهة لا توحي بأن الملاحظات أُرسلت إلى الخادم ما دام عقد Edge الحالي لا يحفظها.

---

# 10. سجل الحوكمة والتنفيذ

| البند | النتيجة المثبتة |
|---|---|
| إعادة قراءة Loader وPicker وCore | تمت |
| إعادة قراءة سجل Edge الحي | تمت |
| قراءة تعريفات Core وACL والمخطط والمحـفزات | تمت للعناصر المرتبطة بالمهمة |
| تصحيح مسار المصدر التشغيلي | تم توثيقه: erp-frontend/main |
| تصحيح خطأ المفتاح المحلي في المقترح | تم في هذه النسخة العربية؛ المفتاح مركب |
| تعديل Loader التشغيلي | لم يحدث، محظور على المساعد في هذه المهمة |
| تعديل Picker أو Main أو Core | لم يحدث |
| نشر Edge | لم يحدث |
| تعديل قاعدة البيانات أو بيانات التشغيل | لم يحدث |
| اختبار متصفح مصادق E2E | لم يُنفذ |
| اختبار Staging معزول | لم يُنفذ في هذه الدورة |
| التحقق من HTML الذي تقدمه Cloudflare | غير مثبت |
| استعادة خط الأساس بعد اختبار إنتاجي | لا ينطبق؛ لم ينفذ اختبار يغير بيانات التشغيل |
| حذف Harness أو Fixture | لم ينشأ أي Harness أو Fixture جديد في هذه الدورة |

---

# 11. الخلاصة التنفيذية

لا توجد أدلة تسمح بإعلان إغلاق المهمة بنسبة 100%. ما تم هو تحقيق وتأكيد العيوب وتجهيز مواصفات رقع قابلة للتطبيق، مع تصحيح مشكلة إضافية في مواصفات الحفظ المحلي.

**أول إجراء عملي تالٍ:** يعيد المالك جلب Loader من المستودع التشغيلي ويتأكد من SHA الحالي، ثم يطبق الرقع المحددة فقط. بالتوازي في المسار الخلفي، يجب استرجاع مصدر `reopen-loading` المنشور إلى Current الرسمي وإصلاح اشتقاق الشركة من هوية Auth قبل أي نشر. بعد ذلك تُنفذ اختبارات معزولة، ثم نشر موثق، ثم إعادة قراءة Production واختبار HTTP/متصفح حقيقي.

لا تُعتبر المسودة المحلية بديلًا عن مصدر الحقيقة في الخادم، ولا تُعتبر مواصفات الرقعة إصلاحًا منفذًا، ولا تُعتبر قراءة Production اختبار Runtime.

---

# 12. التدقيق الذاتي النهائي

### ما أثبته التحقيق
- المصدر التشغيلي الصحيح لـLoader وPicker هو مستودع `erp-frontend`.
- اختيار المركبة موجود بالفعل في Loader الحالي ويجب الحفاظ عليه.
- إصدارات Edge الحية في اللقطة المقروءة هي start-loading v6 وcomplete-loading v11 وcancel-loading v5 وreopen-loading v2، وجميعها ACTIVE و`verify_jwt=true`.
- Edge الخاص بالإكمال يرفض عناصر الكمية صفر.
- واجهة Loader الحالية لا تحفظ مسودة محلية رغم تحميل Dexie.
- واجهة الكمية تسمح بسلوك يتعارض مع حد Core.
- طلب إعادة الفتح لا يرسل `operation_id`.
- إعادة الفتح والإلغاء تستخرجان الشركة من أول صف إعدادات بدل ربط Auth بالمستخدم التطبيقي.
- Core هو صاحب الأثر الفعلي للمخزون، وACL المقروء يمنع التنفيذ المباشر من anon/authenticated للدوال التي فُحصت.
- المقترح القديم لمفتاح Dexie كان معرضًا لتصادم بين الشركات؛ عُدّل في هذا التقرير إلى مفتاح مركب.

### ما لم أثبته
- أن المالك طبّق رقع HTML.
- أن Cloudflare تقدم الملف المطابق لبصمة Git الحالية.
- أن اختبار E2E مصادقًا نجح.
- أن Staging نشط ومتاح للاختبار في هذه اللحظة.
- أن الملاحظات تُحفظ في الخادم.
- أن إعادة الفتح آمنة بين الشركات قبل إصلاح Edge واختبارها.
- أن سلوك retry بعد نجاح الخادم وانقطاع الاستجابة صحيح بالكامل.

### ما أصلحته في هذه الدورة
- أصلحت **مواصفات الرقعة** الخاصة بمفتاح تخزين المسودة، لتصبح مفتاحًا مركبًا `company_id + loader_id + runsheet_code` بدل رقم الرانشيت وحده.
- أعدت صياغة التقرير باللغة العربية مع الاحتفاظ بمحددات المصدر والعقود والكود القابل للتطبيق.
- لم أغيّر الملفات التشغيلية أو Production.

### ما فاتني في التقرير السابق
- خطر تصادم المسودات المحلية بسبب الاعتماد على `runsheet_code` وحده لم يكن معالجًا في مقترح Dexie السابق.
- يجب فصل إثبات المصدر الحالي عن إثبات الملف الذي تقدمه Cloudflare.
- لا يجوز اعتبار وجود idempotency في Core دليلًا كافيًا على نجاح كل حالات retry دون اختبار.

### ما قد يظل خطأ
- قد تتغير بصمة المصدر أو Edge بعد هذه القراءة.
- قد تكون هناك فروق بين المصدر في Git والملف المقدم للمستخدم.
- يحتاج سلوك التخزين المحلي ومعرّف العملية إلى اختبار فعلي في بيئة معزولة.
- لا تزال ملاحظات النقص بلا عقد حفظ خلفي موثق.

**الثقة النهائية:** مرتفعة في العيوب الساكنة وعقود HTTP/Core التي تمت قراءتها؛ متوسطة في تفسير دورة الحياة الكاملة؛ منخفضة في الإغلاق التشغيلي لأن اختبار E2E وهوية النشر لم يثبتا.

**حالة الإغلاق النهائية:**  
`NOT CLOSED — OWNER HTML PATCH + REOPEN EDGE TENANT REPAIR + ISOLATED E2E + SERVED-ARTIFACT VERIFICATION REQUIRED`

---

# الملحق أ — الكتل البرمجية الكاملة للرقع

الكتل التالية هي نصوص الاستبدال المقترحة، وليست تغييرات منفذة. يجب إعادة قراءة الملف التشغيلي والتحقق من SHA قبل التطبيق.

## أ-1. تهيئة مخزن Dexie
```javascript
var RW_LoaderDB = null;
try {
    if (typeof Dexie !== 'undefined') {
        RW_LoaderDB = new Dexie('RW_Loader');
        RW_LoaderDB.version(1).stores({
            sessions: '[company_id+loader_id+runsheet_code], company_id, loader_id, runsheet_id, loading_cycle_id'
        });
    }
} catch (loaderDbInitError) {
    console.error('Loader local draft database initialization failed:', loaderDbInitError);
}
```

## أ-2. استبدال _startSession
```javascript
_startSession: function(code, rs, items) {
    var self = this;
    var session = {
        runsheet_code: code,
        company_id: rs.company_id,
        loader_id: rs.loader_id,
        runsheet_id: rs.id,
        vehicle_id: rs.vehicle_id || null,
        loading_cycle_id: rs.loading_cycle_id || null,
        loader_start: rs.loader_start || null,
        start_time: rs.loader_start || new Date().toISOString(),
        items: []
    };

    for (var i = 0; i < items.length; i++) {
        var it = items[i];
        var product = it.items || {};
        if (Array.isArray(product)) product = product[0] || {};

        session.items.push({
            item_code: it.item_code,
            item_name: it.item_name || product.name || '',
            unit: it.unit || product.unit || 'حبة',
            description: product.description || '',
            image_url: product.image_url || '',
            unit_price: Number(it.unit_price) || 0,
            qty_ordered: Number(it.qty_ordered) || 0,
            qty_picked: Number(it.qty_picked) || 0,
            qty_loaded: Number(it.qty_loaded) || 0,
            notes: it.notes || ''
        });
    }

    function sameIdentity(saved) {
        return !!saved &&
            saved.runsheet_code === session.runsheet_code &&
            saved.company_id === session.company_id &&
            saved.loader_id === session.loader_id &&
            saved.runsheet_id === session.runsheet_id &&
            String(saved.vehicle_id || '') === String(session.vehicle_id || '') &&
            String(saved.loading_cycle_id || '') === String(session.loading_cycle_id || '') &&
            String(saved.loader_start || '') === String(session.loader_start || '');
    }

    if (!RW_LoaderDB) {
        self.session = session;
        RW_UI.toast('الحفظ المؤقت غير متاح على هذا الجهاز؛ ستظل التعديلات في الذاكرة الحالية فقط', 'warning');
        self.renderActiveSession();
        return;
    }

    RW_LoaderDB.sessions.get([session.company_id, session.loader_id, session.runsheet_code]).then(function(saved) {
        if (sameIdentity(saved)) {
            var byCode = {};
            for (var i = 0; i < saved.items.length; i++) {
                byCode[String(saved.items[i].item_code)] = saved.items[i];
            }
            for (var j = 0; j < session.items.length; j++) {
                var current = session.items[j];
                var previous = byCode[String(current.item_code)];
                if (previous) {
                    current.qty_loaded = Number(previous.qty_loaded) || 0;
                    current.notes = previous.notes || '';
                }
            }
        } else if (saved) {
            return RW_LoaderDB.sessions.delete([session.company_id, session.loader_id, session.runsheet_code]).then(function() {
                return null;
            });
        }
        return null;
    }).then(function() {
        self.session = session;
        return RW_LoaderDB.sessions.put(session);
    }).then(function() {
        self.renderActiveSession();
    }).catch(function(err) {
        console.error('Loader draft restore/save failed:', err);
        self.session = session;
        RW_UI.toast('تعذر استعادة الحفظ المؤقت. تم عرض بيانات الخادم دون ادعاء حفظ التعديلات المحلية.', 'error');
        self.renderActiveSession();
    });
},
```

## أ-3. استبدال editLoadedItem
```javascript
editLoadedItem: function(idx, pre) {
    var s = this;
    if (!s.session || !s.session.items[idx]) return;
    var it = s.session.items[idx];
    var cur = (typeof pre !== 'undefined') ? pre : it.qty_loaded;

    Swal.fire({
        title: '<span class="text-slate-800">' + it.item_name + '</span>',
        html: '<div class="text-center mb-3">' +
            s._loaderImageHTML(it, 'w-full max-w-xs', 'h-72', 'object-contain') +
            '</div><div class="text-right text-sm space-y-2">' +
            '<div class="flex justify-between"><span class="text-slate-400">محضّر</span><strong>' + it.qty_picked + '</strong></div>' +
            '<div class="flex justify-between"><span class="text-slate-400">مطلوب</span><strong>' + it.qty_ordered + '</strong></div>' +
            (it.unit ? '<div class="flex justify-between"><span class="text-slate-400">الوحدة</span><strong>' + it.unit + '</strong></div>' : '') +
            '</div><div class="mt-4 text-right">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2">الكمية المحمّلة</label>' +
            '<input id="swal-qty" type="number" class="swal2-input !rounded-xl !text-center !font-bold !text-lg" value="' + cur + '" min="0" max="' + it.qty_picked + '">' +
            '<label class="block text-xs font-bold text-slate-500 mb-2 mt-4">ملاحظات محلية</label>' +
            '<input id="swal-notes" class="swal2-input !rounded-xl" value="' + (it.notes || '') + '" placeholder="سبب النقص (يحفظ محليًا فقط)"> </div>',
        showCancelButton: true,
        confirmButtonText: 'حفظ',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        },
        didOpen: function() {
            s._bindLoaderImageFallbacks(Swal.getPopup());
        },
        preConfirm: function() {
            var p = Swal.getPopup();
            var qe = p ? p.querySelector('#swal-qty') : null;
            var ne = p ? p.querySelector('#swal-notes') : null;
            var value = qe ? Number(qe.value) : NaN;
            if (!Number.isFinite(value) || value < 0 || value > Number(it.qty_picked)) {
                Swal.showValidationMessage('الكمية يجب أن تكون بين صفر والكمية المحضّرة.');
                return false;
            }
            return { qty: Math.floor(value), notes: ne ? ne.value.trim() : '' };
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;
        var oldQty = it.qty_loaded;
        var oldNotes = it.notes;
        s.session.items[idx].qty_loaded = r.value.qty;
        s.session.items[idx].notes = r.value.notes;

        if (!RW_LoaderDB) {
            s.renderActiveSession();
            RW_UI.toast('تم التعديل في الجلسة الحالية فقط؛ الحفظ الدائم المحلي غير متاح', 'warning');
            return;
        }

        RW_LoaderDB.sessions.put(s.session).then(function() {
            s.renderActiveSession();
            if (r.value.qty < it.qty_picked && !r.value.notes) {
                Swal.fire({
                    title: 'تنبيه',
                    text: 'الكمية المحمّلة أقل من المحضّرة. هل تريد إضافة سبب؟',
                    icon: 'question',
                    showCancelButton: true,
                    confirmButtonText: 'إضافة سبب',
                    cancelButtonText: 'تخطي',
                    customClass: {
                        popup: '!rounded-3xl',
                        confirmButton: '!rounded-xl !bg-amber-500 !px-6',
                        cancelButton: '!rounded-xl'
                    }
                }).then(function(r2) {
                    if (r2.isConfirmed) s.editLoadedItem(idx, r.value.qty);
                });
            }
        }).catch(function(err) {
            s.session.items[idx].qty_loaded = oldQty;
            s.session.items[idx].notes = oldNotes;
            console.error('Loader draft write failed:', err);
            s.renderActiveSession();
            RW_UI.showError('تعذر حفظ التعديل محليًا؛ أُعيدت القيمة السابقة.');
        });
    });
},
```

## أ-4. pauseLoading
```javascript
pauseLoading: function() {
    var s = this;
    if (!s.session) return;
    if (!RW_LoaderDB) {
        RW_UI.showError('الحفظ المؤقت غير متاح؛ لن يتم إنهاء الجلسة أو مسح بياناتها.');
        return;
    }
    RW_LoaderDB.sessions.put(s.session).then(function() {
        if (s.timerInterval) clearInterval(s.timerInterval);
        s.timerInterval = null;
        s.session = null;
        RW_UI.toast('تم حفظ التحميل مؤقتًا على هذا الجهاز', 'success');
        s.renderPendingTab();
    }).catch(function(err) {
        console.error('Loader pause draft write failed:', err);
        RW_UI.showError('تعذر حفظ الجلسة؛ بقيت الجلسة مفتوحة ولم يتم تغيير حالة الرانشيت.');
    });
},
```

## أ-5. زر الحفظ المؤقت
```javascript
h += '<button onclick="App.pauseLoading()" class="w-full mt-3 bg-amber-50 border border-amber-200 text-amber-700 py-3 rounded-2xl font-bold"><i class="fa-solid fa-pause ml-2"></i> حفظ مؤقت والعودة للقائمة</button>';
```

## أ-6. استبدال completeLoading
```javascript
completeLoading: function() {
    var s = this;
    if (!s.session) return;
    if (!navigator.onLine) {
        RW_UI.toast('غير متصل', 'warning');
        return;
    }

    var requestItems = [];
    var fullCount = 0, partialCount = 0, zeroCount = 0;
    var allItems = s.session.items;

    for (var i = 0; i < allItems.length; i++) {
        var it = allItems[i];
        if (it.qty_loaded < 0 || it.qty_loaded > it.qty_picked) {
            RW_UI.showError('الكمية المحمّلة يجب ألا تتجاوز الكمية المحضّرة.');
            return;
        }
        if (it.qty_loaded > 0) {
            requestItems.push({ itemCode: it.item_code, loadedQty: it.qty_loaded });
        }
        if (it.qty_loaded >= it.qty_ordered) fullCount++;
        else if (it.qty_loaded > 0) partialCount++;
        else zeroCount++;
    }

    if (!requestItems.length) {
        RW_UI.showError('لا يمكن إنهاء التحميل دون كمية موجبة واحدة على الأقل. لم يتم إرسال أي طلب.');
        return;
    }

    var summary = '<div class="text-right text-sm"><p>أنت على وشك إنهاء تحميل الرانشيت <strong>' +
        s.session.runsheet_code + '</strong>.</p><div class="mt-3 space-y-1">' +
        '<div>✅ <strong>' + fullCount + '</strong> أصناف مكتملة</div>' +
        '<div>⚠️ <strong>' + partialCount + '</strong> أصناف محمّلة جزئيًا</div>' +
        '<div>❌ <strong>' + zeroCount + '</strong> أصناف لم تُحمّل</div></div>' +
        '<p class="text-xs text-amber-700 mt-3">ملاحظات النقص محلية ولا تُرسل إلى عقد التحميل الحالي.</p></div>';

    Swal.fire({
        title: 'تأكيد إنهاء التحميل',
        html: summary,
        icon: 'info',
        showCancelButton: true,
        confirmButtonText: 'تأكيد',
        cancelButtonText: 'إلغاء',
        customClass: {
            popup: '!rounded-3xl',
            confirmButton: '!rounded-xl !bg-orange-600 !px-8',
            cancelButton: '!rounded-xl'
        }
    }).then(function(r) {
        if (!r.isConfirmed) return;
        var cb = document.querySelector('.swal2-confirm');
        if (cb) {
            cb.disabled = true;
            cb.innerText = 'جارٍ...';
        }
        RW_UI.showLoader();
        RW_API.call('complete-loading', {
            runsheet_code: s.session.runsheet_code,
            items: requestItems
        }, function(json) {
            RW_UI.hideLoader();
            if (json && json.success) {
                var tq = 0, tv = 0;
                for (var j = 0; j < requestItems.length; j++) {
                    tq += requestItems[j].loadedQty;
                    for (var k = 0; k < allItems.length; k++) {
                        if (allItems[k].item_code === requestItems[j].itemCode) {
                            tv += requestItems[j].loadedQty * (Number(allItems[k].unit_price) || 0);
                            break;
                        }
                    }
                }
                var code = s.session.runsheet_code;
                var draftKey = [s.session.company_id, s.session.loader_id, code];
                function finishUi() {
                    Swal.fire({
                        icon: 'success',
                        title: 'تم إنهاء التحميل',
                        html: '<div class="text-right"><p>تم تحميل <strong>' + requestItems.length +
                            ' صنف</strong></p><p>إجمالي الكمية: <strong>' + tq +
                            '</strong></p><p>القيمة التقديرية: <strong>' +
                            RW_UI.formatNumber(tv) + ' EGP</strong></p></div>',
                        confirmButtonText: 'حسنًا',
                        customClass: { popup: '!rounded-3xl', confirmButton: '!rounded-xl !bg-orange-600' }
                    });
                    s.session = null;
                    if (s.timerInterval) clearInterval(s.timerInterval);
                    s.timerInterval = null;
                    s.renderPendingTab();
                }
                if (RW_LoaderDB) {
                    RW_LoaderDB.sessions.delete(draftKey).then(finishUi).catch(function(err) {
                        console.error('Loader completed draft cleanup failed:', err);
                        finishUi();
                        RW_UI.toast('اكتمل التحميل، لكن تعذر حذف المسودة المحلية القديمة', 'warning');
                    });
                } else {
                    finishUi();
                }
            } else {
                RW_UI.showError((json && json.msg) || 'فشل إنهاء التحميل. احتُفظ بالمسودة المحلية.');
            }
        });
    });
},
```

## أ-7. استبدال cancelLoading
```javascript
cancelLoading: function(code) {
    var s = this;
    var u = s.currentUser;
    var draftKey = (u && u.company_id && u.id) ? [u.company_id, u.id, code] : null;
    RW_UI.showConfirm('إلغاء تحميل ' + code + '؟ ستعود حالة الرانشيت إلى جاهز للتحضير.', function() {
        RW_UI.showLoader();
        RW_API.call('cancel-loading', { runsheet_code: code }, function(json) {
            RW_UI.hideLoader();
            if (json && json.success) {
                function resetUi() {
                    RW_UI.toast('تم الإلغاء', 'success');
                    s.session = null;
                    if (s.timerInterval) clearInterval(s.timerInterval);
                    s.timerInterval = null;
                    s.renderPendingTab();
                }
                if (RW_LoaderDB && draftKey) {
                    RW_LoaderDB.sessions.delete(draftKey).then(resetUi).catch(function(err) {
                        console.error('Loader cancelled draft cleanup failed:', err);
                        resetUi();
                        RW_UI.toast('أُلغيت العملية، لكن تعذر حذف المسودة المحلية القديمة', 'warning');
                    });
                } else {
                    resetUi();
                }
            } else {
                RW_UI.showError((json && json.msg) || 'تعذر تأكيد الإلغاء؛ احتُفظ بالمسودة المحلية.');
            }
        });
    });
},
```

## أ-8. استبدال renderCompletedTab
```javascript
renderCompletedTab: function() {
    var s = this;
    var u = s.currentUser;
    if (!u || !u.company_id || !u.id) {
        RW_UI.showError('تعذر تحديد الشركة أو المستخدم الحالي.');
        return;
    }
    RW_UI.showSkeleton('mainContent', 1, 'card');
    supabase.from('runsheets')
        .select('runsheet_code,run_date,status')
        .eq('company_id', u.company_id)
        .eq('status', 'Loaded')
        .eq('loader_id', u.id)
        .order('run_date', { ascending: false })
        .limit(50)
        .then(function(r) {
            if (r.error) {
                console.error('Loader completed runsheets query failed:', r.error);
                RW_UI.showError('تعذر تحميل الرانشيتات المكتملة.');
                return;
            }
            s.completedRunsheets = r.data || [];
            s.renderCompletedList(s.completedRunsheets);
        }).catch(function(err) {
            console.error('Loader completed runsheets request failed:', err);
            RW_UI.showError('تعذر تحميل الرانشيتات المكتملة.');
        });
},
```

## أ-9. استبدال reopenLoading
```javascript
reopenLoading: function(code) {
    var s = this;
    var u = s.currentUser;
    if (!u || !u.company_id || !u.id || !code) {
        RW_UI.showError('تعذر تحديد الشركة أو المستخدم أو الرانشيت.');
        return;
    }

    supabase.from('runsheets')
        .select('status,runsheet_code,company_id,loader_id')
        .eq('company_id', u.company_id)
        .eq('runsheet_code', code)
        .eq('loader_id', u.id)
        .maybeSingle()
        .then(function(r) {
            if (r.error || !r.data || r.data.status !== 'Loaded') {
                if (r.error) console.error('Loader reopen precheck failed:', r.error);
                Swal.fire({
                    title: 'لا يمكن إعادة الفتح',
                    text: 'تعذر التحقق من أن الرانشيت مكتمل ويتبع حسابك الحالي.',
                    icon: 'warning',
                    customClass: { popup: '!rounded-3xl' }
                });
                s.renderCompletedTab();
                return;
            }

            RW_UI.showConfirm('إعادة فتح ' + code + '؟ سيتم عكس حركة التحميل وفق Core.', function() {
                var storageKey = 'rw-loader-reopen:' + u.company_id + ':' + code;
                var operationId = '';
                try {
                    operationId = localStorage.getItem(storageKey) || '';
                    if (!operationId) {
                        operationId = crypto.randomUUID();
                        localStorage.setItem(storageKey, operationId);
                    }
                } catch (storageError) {
                    RW_UI.showError('تعذر حفظ معرف العملية لإعادة المحاولة بأمان؛ لم يتم إرسال الطلب.');
                    return;
                }

                RW_UI.showLoader();
                RW_API.call('reopen-loading', {
                    runsheet_code: code,
                    operation_id: operationId
                }, function(j) {
                    RW_UI.hideLoader();
                    if (j && j.success) {
                        try { localStorage.removeItem(storageKey); } catch (_) {}
                        if (RW_LoaderDB) {
                            RW_LoaderDB.sessions.delete([u.company_id, u.id, code]).catch(function(err) {
                                console.error('Old Loader cycle draft cleanup failed:', err);
                            });
                        }
                        RW_UI.toast('تمت إعادة فتح التحميل', 'success');
                        s.renderPendingTab();
                    } else {
                        RW_UI.showError((j && j.msg) || 'فشلت إعادة الفتح؛ أُبقي معرف العملية لاستخدامه في إعادة المحاولة.');
                    }
                });
            });
        }).catch(function(err) {
            console.error('Loader reopen precheck request failed:', err);
            RW_UI.showError('تعذر التحقق من حالة الرانشيت.');
        });
},
```
