# تقرير التحقيق والتنفيذ — تكامل تطبيق مندوب التوصيل مع النظام الأم

**التاريخ:** 2026-10-26  
**النطاق:** تطبيق التوصيل `companies/company-1/delivery/driver.html` وربطه بالنظام الأم `companies/company-1/main.html`، مع فحص Core وعقود Production ذات الصلة.  
**الحالة:** `FORENSIC REVIEW COMPLETE / SURGICAL PATCHES PREPARED / NOT RUNTIME-CLOSED`  
**قاعدة التغيير:** لم أعدّل `driver.html` أو `main.html` أو Edge Functions أو بيانات Production؛ المطلوب أن يطبّق المالك رقع الواجهة، ولأن عقد القراءة الحالي لا يثبت سلامة التفويض لم أغيّر Production على نحو قد يوسّع الوصول دون اختبار معزول.

## 1. SELF-AUDIT قبل التغيير

- **Business Understanding:** CONFIRMED — السائق يحتاج رؤية الرانشيت المعيّن له، وأوامره وأصنافه وكمياته وملاحظات النقص، ثم إرسال نتائج التسليم إلى العقد الخلفي، مع بقاء النظام الأم قادرًا على عرض السجل الصحيح.
- **Architecture Understanding:** CONFIRMED — `driver.html` تطبيق مستقل، و`core.js` يوفر `RW_Auth` و`get_my_effective_profile`، وEdge/RPC مسؤولان عن اعتماد نتائج التسليم.
- **Database Understanding:** CONFIRMED — فُحصت أعمدة Production وسياسات RLS وتعريف `complete_order_delivery_atomic` مباشرة.
- **Historical Understanding:** CONFIRMED جزئيًا — تمت قراءة `CURRENT_STATE.md` وآخر الأحداث LVE-504/503/502، وReport503 وReport504، وملف التوجيه التشغيلي حتى قسم أمر التنفيذ. لم يثبت سجل تاريخي كامل لكل تعديل قديم على `driver.html`.
- **Production Understanding:** CONFIRMED للنطاق الذي استُعلم عنه في الجلسة، وليس لسلوك HTML المنشور.
- **Current Understanding:** CONFIRMED — `driver.html` الحالي blob `2df69860184f5a7c1b211ba059e1d6f57826c96b`، و`core.js` blob `ff2f581d9900543c16f7cb026e13446520c0329d`، و`main.html` blob `11f29e07c10ae1767db334fe101c382eca23bd00`.
- **Execution Confidence:** مرتفعة في العيوب المصدرية وعقد البيانات المثبتة؛ غير كافية لإعلان E2E أو Production closure لأن لا يوجد رانشيت معيّن لسائق في عينة Production الحالية، ولا يوجد تحقق من HTML الذي تقدمه الاستضافة.

### المصادر التي فُتحت مباشرة

1. `rawaie-erp-New/CURRENT_STATE.md` — blob `4d4ccba2b0d787fc30ea0c4b5652bd63228e9e8e`، 320,501 حرفًا / 1,995 سطرًا.
2. `rawaie-erp-New/doc/Draft/Reprots/MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md` — blob `abfa9d376c455ad7466b9404eed6f0a2c2166ede`; قُرئت التعليمات المتعلقة بالبدء من الحالة الحالية، وفصل الأدلة، والتعديل الجراحي، والاختبارات، ونهاية أمر التنفيذ.
3. `rawaie-erp-New/doc/Draft/Reprots/Report503_PARENT_RUNSHEET_HISTORY_RETENTION_20261026.md` — blob `a6c483410ba1492ab57f068ecfac9201cd9ed5cd`.
4. `rawaie-erp-New/doc/Draft/Reprots/Report504_PARENT_RUNSHEET_HISTORY_RETENTION_PATCHES_20261026.md` — blob `1fdb88dc71e6cdd960243c2e879b73c9cb8cedb9`.
5. `erp-frontend/companies/company-1/delivery/driver.html` — blob `2df69860184f5a7c1b211ba059e1d6f57826c96b`, 114,459 حرفًا / 1,755 سطرًا.
6. `erp-frontend/companies/company-1/core.js` — blob `ff2f581d9900543c16f7cb026e13446520c0329d`.
7. `erp-frontend/companies/company-1/main.html` — استُعيد النص من Git blob مباشرة: 1,785,871 حرفًا / 33,101 سطرًا، blob `11f29e07c10ae1767db334fe101c382eca23bd00`.
8. Supabase Production: قراءة Edge Registry ومصادر Edge وPostgreSQL schema/RLS/RPC في الجلسة نفسها.

## 2. Production snapshot المباشر

**وقت فحص PostgreSQL:** `2026-10-26 13:42:38.74846+00`.

- `runsheets`: يوجد صفّان فقط في الحالة `Loaded` وقت الفحص.
- الرانشيتان الظاهرتان في العينة: `RS-1` و`RS-2`؛ `driver_id = NULL` و`deliverer_id = NULL` و`delivery_start = NULL` و`delivery_end = NULL` لكلتيهما.
- `app_settings`: صف واحد للشركة `00000000-0000-0000-0000-000000000001`.
- لم تُنشأ أو تُعدّل أي بيانات اختبار، ولم تُنفّذ حركة تسليم أو حركة مخزون.
- استعلام سجلات Edge خلال نافذة الأداة المتاحة لم يُرجع سجلات تطابق `start-delivery` أو `complete-delivery` أو `complete-order-delivery`. هذا لا يثبت عدم وجود استخدام تاريخي خارج النافذة.
- **الأثر:** لا يمكن تنفيذ HTTP E2E آمن لرحلة حقيقية من دون رانشيت معيّن لسائق أو Fixture معزول معتمد؛ لم أخترع رحلة إنتاجية ولم أغيّر بيانات التشغيل لإنشاء اختبار.

### Edge Functions ذات الصلة — Live Production

| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `start-delivery` | 7 | ACTIVE | true | `7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e` |
| `complete-delivery` | 4 | ACTIVE | true | `9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753` |
| `cancel-delivery` | 5 | ACTIVE | true | `e684aed9d0e3a49548dac7a90f2e0d135b82329d2bf6b4bc4d7503dfd4ed115a` |
| `complete-order-delivery` | 14 | ACTIVE | true | `15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2` |
| `get-driver-dashboard` | 1 | ACTIVE | true | `59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e` |

**تنبيه Provenance:** مصدر Production المعاد قراءته لـ`complete-order-delivery` يبدأ بتعليق “authoritative Production v12” بينما Registry يعرض v14. لذلك رقم الإصدار مثبت من Registry، لكن التعليق النصي لا يثبت أن محتوى المصدر يعود إلى v12 ولا يربط Git blob ببايتات النشر؛ لم أدّعِ byte parity.

## 3. العيوب المثبتة في التطبيق الحالي

### 3.1 المصادقة والهوية — خلل عالي الخطورة

في `App.init()` الحالي:
- يقرأ صلاحيات `user_metadata` من Supabase Auth بدل استدعاء `RW_Auth.init()` / `get_my_effective_profile`.
- يقرأ سجل `public.users` بواسطة البريد الإلكتروني بدل الربط الموثوق `users.auth_id = auth.uid()`.
- إذا لم يجد مستخدمًا، يحاول إنشاء سجل تلقائيًا مع `company_id` ثابت. هذا ليس إصلاحًا صالحًا لهوية الموظف وقد ينشئ سجلًا غير صحيح أو يفشل بسبب قيود التفرد.
- الدخول يُسمح بناءً على Metadata لا على الصلاحيات الفعالة في Core.
- `renderAccount()` يعتمد على `currentUser.user_metadata`، وهو غير متوافق مع كائن المستخدم الموحد الذي يعيده Core.

**القرار:** لا تُصلح هذه النقطة بإضافة Metadata أو إنشاء مستخدم تلقائي. استخدم `RW_Auth.doLogin` و`RW_Auth.init`، ثم `RW_Auth.getUser()`/المستخدم المستعاد، ولا تنشئ سجل `users` من الواجهة.

### 3.2 قراءة الرانشيت والأوامر — تعارض مع RLS

التطبيق يقرأ مباشرة من `runsheets`, `orders`, `order_details`, و`run_sheet_details`، وغالبًا لا يفحص `res.error`؛ Supabase JS قد يعيد نتيجة فيها `error` دون رفض Promise، فيُفسّر الخطأ كقائمة فارغة.

سياسات Production الحالية:
- `runsheets_select_company` يسمح بالقراءة للشركة عندما تكون الصلاحية `runsheets` أو `warehouse`.
- `orders_select_current_tenant` و`order_details_select_current_tenant` يسمحان عند `orders` أو `runsheets` أو `warehouse` أو `reports`، مع سياسات إضافية محددة للمبيعات.
- `run_sheet_details_select_current_tenant` يسمح عند `runsheets` أو `warehouse` أو `reports`.
- لا تتضمن هذه السياسات `delivery` وحدها.

**النتيجة المثبتة:** حساب لديه صلاحية `delivery` فقط قد يفشل في قراءة قوائم السائق مباشرة من هذه الجداول. لا أعمّم أن كل حساب سيفشل؛ ذلك يعتمد على صلاحياته الفعلية. كما أن واجهة التطبيق لا تعرض خطأ RLS بصورة موثوقة في عدة مسارات.

### 3.3 Edge read endpoint موجود لكنه غير صالح للاعتماد عليه دون إصلاح

`get-driver-dashboard v1` موجود في Production، لكنه:
- يبحث عن المستخدم بالبريد لا بـ`auth_id` ولا يثبت الشركة/حالة المستخدم/صلاحية `delivery`.
- لا يطلب `id` ضمن `select` للرانشيت النشط، ثم يستخدم `activeRS.id` في استعلام الأوامر والتفاصيل.
- لا يفحص أخطاء عدة استعلامات.
- لا يثبت حدود الشركة على كل قراءة.
  
لذلك لا أوصي بتحويل الواجهة إليه قبل إصلاح هذا الـendpoint الموجود واختباره. هذا إصلاح Dependency مطلوب لإكمال E2E بأمان، وليس مبررًا لإضافة Edge Function جديدة.

### 3.4 اختلاف عقد ملاحظات التسليم

الواجهة الحالية تقرأ `order_details.notes` فقط وتعرضها باعتبارها سبب النقص. لكن Production RPC `complete_order_delivery_atomic` يكتب السبب إلى `order_details.reason_delivery`، لا إلى `notes`.

**النتيجة:** سبب النقص المرسل عبر `complete-order-delivery` قد يُحفظ في `reason_delivery` ولا يظهر في واجهة السائق الحالية؛ وتفاصيل التوصيل في النظام الأم تعرض `run_sheet_details` المجمعة فقط، ولا تعرض أسباب النقص لكل Order/Item.

### 3.5 المبلغ المعروض لا يثبت التحصيل

`finishOrderDelivery()` يرسل `summary` و`amount_paid`، لكن Edge v14 لا يمررهما إلى `complete_order_delivery_atomic`. الـRPC يستقبل الشركة والرانشيت والأوردر والبريد و`items` فقط، ويحدّث كميات التسليم وحالة الأوردر وتجميع `run_sheet_details` وسجل العملية. لا يثبت هذا المسار تسجيل `amount_paid` أو إنشاء قيد تحصيل.

لذلك عبارة الواجهة `تم التحصيل` مضللة ما لم يوجد عقد تحصيل آخر مثبت. لا ينبغي وصف القيمة المحسوبة في المتصفح بأنها مبلغ محصّل فعليًا.

### 3.6 اختلاف أساس الكمية المرفوضة

الـRPC يحدّ التسليم وفق `qty_loaded - qty_delivered`. لكن عدة أجزاء من الواجهة تحسب المرفوض باستخدام `qty - qty_delivered` (الكمية المطلوبة، لا المحملة)، والتحقق النهائي من سبب النقص يقارن بالكمية المطلوبة. يجب توحيد عرض المرفوض والتحقق من السبب مع `qty_loaded` حتى لا تختلف الواجهة عن القيد الخلفي.

### 3.7 النظام الأم لا يعرض سجل التوصيل كاملًا

في `main.html` الحالي، `loadDelivery()` يستعلم عن `status = Delivered` فقط؛ وهذا يخفي الرانشيت أثناء `Delivering` ويستبعد الحالات التاريخية التي انتقلت إلى `Returned`. كما أن `_applyDelivery()` يعرض `driver_id` الخام بدل اسم السائق، ويكتب الحالة الثابتة `Delivered` بدل الحالة الفعلية. الإصلاح المقترح في Report504 ما زال مقترحًا ولم يُثبت أنه طُبق في المصدر الحالي.

### 3.8 ملاحظات التحميل

لا يوجد دليل أن `driver.html` هو مالك ملاحظات التحميل. الحالة التاريخية المثبتة في Report502/503/504 تقول إن ملاحظات الأصناف المحلية في Loader لا تُرسل في عقد `complete-loading`، وإن `runsheets.notes` ليست بديلًا مثبتًا عنها. لا ينبغي محاولة عرضها في شاشة التوصيل أو النظام الأم من حقل عام غير متفق على معناه. تحتاج ملاحظات التحميل إلى عقد تخزين مستقل متفق عليه؛ لم أغيّر schema أو أكتب ملاحظات في Production.

## 4. رقع جراحية مقترحة للمالك — driver.html

المستودع: `papamohammed77-glitch/erp-frontend`, الفرع `main`.  
الملف: [driver.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/delivery/driver.html).  
SHA قبل التعديل: `2df69860184f5a7c1b211ba059e1d6f57826c96b`.  
**لا تطبق الرقع قبل إعادة جلب SHA والتأكد أن الملف لم يتغير.**

### Patch A — استبدال طريقتي doLogin وinit وإضافة acceptAuthenticatedUser

**محدد البحث:** `doLogin: function()` حتى نهاية `init: function()` مباشرة قبل `enterApp: function()`.

استبدل الطريقتين الحاليتين وأضف الطريقة التالية بين `init` و`enterApp`:

    doLogin: function() {
        var email = byId('loginEmail').value.trim();
        var pass = byId('loginPass').value;
        var self = this;
        if (!email || !pass) {
            byId('loginMsg').innerText = 'أدخل البيانات';
            byId('loginMsg').classList.remove('hidden');
            return;
        }
        byId('loginMsg').classList.add('hidden');
        RW_Auth.doLogin(email, pass, function(user, error) {
            if (error || !user) {
                byId('loginMsg').innerText = error || 'تعذر تحميل ملف المستخدم';
                byId('loginMsg').classList.remove('hidden');
                return;
            }
            self.acceptAuthenticatedUser(user);
        });
    },

    init: function() {
        var self = this;
        RW_Auth.init(function(user, error) {
            if (error) {
                if (error !== 'NO_SESSION') {
                    byId('loginMsg').innerText = error;
                    byId('loginMsg').classList.remove('hidden');
                }
                return;
            }
            if (user) self.acceptAuthenticatedUser(user);
        });
    },

    acceptAuthenticatedUser: function(user) {
        var self = this;
        if (!user || !user.id || !user.company_id) {
            RW_Auth.doLogout();
            byId('loginMsg').innerText = 'لا يوجد ملف موظف صالح مرتبط بحساب المصادقة';
            byId('loginMsg').classList.remove('hidden');
            return;
        }
        if (!user.isOwner && !RW_Auth.checkPermission('delivery')) {
            RW_Auth.doLogout();
            Swal.fire({ title: 'غير مصرح', icon: 'error', customClass: { popup: '!rounded-3xl' } });
            return;
        }

        this.currentUser = user;
        this.pubUserId = user.id;
        safeText(byId('headerUserName'), user.name || user.email || '');

        Promise.all([
            supabase.from('items')
                .select('item_code, image_url, description')
                .eq('company_id', user.company_id),
            supabase.from('app_settings')
                .select('tax_rate, delivery_fee, currency')
                .eq('company_id', user.company_id)
                .maybeSingle()
        ]).then(function(results) {
            if (results[0].error) throw results[0].error;
            if (results[1].error) throw results[1].error;

            ITEMS_IMAGE_CACHE = {};
            var imgs = results[0].data || [];
            for (var i = 0; i < imgs.length; i++) {
                if (imgs[i].item_code) {
                    ITEMS_IMAGE_CACHE[imgs[i].item_code] = {
                        image_url: imgs[i].image_url || '',
                        description: imgs[i].description || ''
                    };
                }
            }

            var settings = results[1].data;
            if (settings) {
                self.settings.tax_rate = Number(settings.tax_rate) || 0;
                self.settings.delivery_fee = Number(settings.delivery_fee) || 0;
                self.settings.currency = settings.currency || 'SAR';
            }
            self.enterApp();
        }).catch(function(error) {
            self.handleError('تهيئة بيانات التوصيل', error);
        });
    },

**لماذا:** يستعمل هوية وصلاحيات Core الفعلية، يوقف إنشاء سجل مستخدم تلقائيًا، ويقيّد الإعدادات والأصناف بالشركة. هذه الرقعة لا تتجاوز RLS ولا تصلح وحدها مسارات قراءة الرانشيت؛ انظر Dependency Gate في القسم 6.

### Patch B — إظهار سبب النقص المخزّن فعليًا

**محدد البحث الأصلي:**

    .select('item_code, item_name, unit, price, qty, qty_loaded, qty_delivered, qty_refused, notes')

ملاحظة: النص الفعلي في الملف هو `unit_price` لا `price`. استخدم النص الفعلي التالي للبحث:

    .select('item_code, item_name, unit, unit_price, qty, qty_loaded, qty_delivered, qty_refused, notes')

**استبدله بـ:**

    .select('item_code, item_name, unit, unit_price, qty, qty_loaded, qty_delivered, qty_refused, notes, reason_delivery')

وبعد السطر:

    var items = res.data || [];

أضف مباشرة:

    for (var ni = 0; ni < items.length; ni++) {
        items[ni].notes = items[ni].reason_delivery || items[ni].notes || '';
    }

**لماذا:** مصدر Production يكتب سبب التسليم إلى `reason_delivery`. تبقى `notes` fallback للبيانات التاريخية، دون تغيير قاعدة البيانات.

### Patch C — توحيد حساب المرفوض والتحقق من سبب النقص

داخل `finishOrderDelivery()`، ابحث عن:

    var ordered = Number(items[i].qty) || 0;

واستبدله بـ:

    var ordered = Number(items[i].qty_loaded) || 0;

هذا يجعل التحقق من إلزام سبب النقص مطابقًا للـRPC الذي يرفض تجاوز الكمية المحملة.

داخل `renderOrderView()`، ابحث عن:

    var refused = Math.max(0, ordered - delivered);

واستبدله بـ:

    var refused = Math.max(0, loaded - delivered);

داخل `editDeliveryItem()` في وضع العرض فقط، ابحث عن:

    var refused = Math.max(0, (Number(it.qty) || 0) - (Number(it.qty_delivered) || 0));

واستبدله بـ:

    var refused = Math.max(0, (Number(it.qty_loaded) || 0) - (Number(it.qty_delivered) || 0));

لا تغيّر أي كمية فعلية في قاعدة البيانات بهذه الرقعة؛ إنها تصحيح عرض/تحقق.

### Patch D — عدم عرض قيمة محسوبة على أنها تحصيل مثبت

في Toast النجاح داخل `finishOrderDelivery()`، السطر الذي يكتب `تم التحصيل` غير مدعوم بعقد Production الحالي. احذف عنصر HTML الخاص بعرض “تم التحصيل” من رسالة النجاح، أو غيّر النص إلى “القيمة المحسوبة للتسليم — ليست إثبات تحصيل”. لا تُضف كتابة مالية من الواجهة؛ يحتاج تسجيل التحصيل عقدًا محاسبيًا/ماليًا مستقلًا واختبارًا خاصًا.

### Patch E — اسم المستخدم في صفحة الحساب

داخل `renderAccount()`، استبدل:

    var userName = (this.currentUser && this.currentUser.user_metadata) ? (this.currentUser.user_metadata.name || this.currentUser.email) : '';

بـ:

    var userName = this.currentUser ? (this.currentUser.name || this.currentUser.email || '') : '';

هذا يتوافق مع كائن المستخدم الموحد من Core.

## 5. رقعة تكامل مطلوبة في النظام الأم — لا تُطبّق ضمن driver.html

المصدر الحالي لـ`main.html` ما زال يستخدم `status = Delivered` فقط، ويعرض `driver_id` الخام ويثبّت نص الحالة. يجب أن تبقى قائمة الإجراءات منفصلة عن السجل التاريخي؛ لا توسّع قائمة الإجراءات لتشمل حالات نهائية قابلة لإعادة التنفيذ.

في `RW_Warehouse.loadDelivery()`، محدد البحث هو `async function loadDelivery()`، ويجب أن يستعلم السجل عن الرانشيتات ذات دليل مرحلة التوصيل (الحالة النهائية أو `deliverer_id/delivery_start/delivery_end`) مع فحص `res.error`، كما هو موثق في رقعة Delivery ضمن Report504. في `_applyDelivery()` يجب عرض `esc(r.status || '—')` بدل النص الثابت `Delivered`.

**نقص إضافي مثبت:** صف الجدول الحالي يعرض `r.driver_id` لا اسم السائق. قبل استبداله باسم، يجب جلب سجل `users` المطابق ضمن الشركة نفسها أو استخدام cache موثوق؛ لا تعرض UUID باعتباره اسمًا. لا أضع استبدالًا تخمينيًا للـdriver-name لأن العلاقة بين `driver_id` و`deliverer_id` يجب أن تبقى واضحة: `driver_id` هو تعيين السائق المستخدم في Edge الحالية، و`deliverer_id` علامة مرحلة أخرى في النظام الأم.

في نافذة تفاصيل التوصيل الحالية، `_showDeliveryDetails()` يعرض `run_sheet_details` المجمعة فقط، ولا يعرض أسباب النقص لكل Order/Item. لإظهارها بصورة صحيحة، يلزم استعلام تفاصيل حسب الأوردر من `orders` ثم `order_details.reason_delivery` مع تقييد كل الاستعلامات بـ`company_id` و`runsheet_id`; لا تستبدل `runsheet.notes` بملاحظات الأصناف ولا تخلطها معها.

## 6. Dependency Gate يجب إغلاقه قبل ادعاء التكامل الكامل

الرقع أعلاه تصحح أخطاء مؤكدة في الواجهة، لكنها لا تجعل المهمة 100% CLOSED وحدها، للأسباب التالية:

1. **قراءة السائق من Production:** RLS الحالية لا تمنح `delivery` وحدها قراءة الجداول اللازمة. لا تضف `delivery` إلى سياسات عامة دون تقييد صارم بالشركة والسائق المعيّن. المسار الأفضل هو إصلاح Edge `get-driver-dashboard` الموجودة لتتحقق من `auth_id`, حالة المستخدم، الشركة، صلاحية `delivery`, وتعيين الرانشيت؛ وإضافة `id` إلى `select`؛ وفحص كل الأخطاء؛ ثم جعل التطبيق يستهلك عقدها. هذه وظيفة موجودة بالفعل، فلا تنشئ Function جديدة.
2. **تناسق هوية Edge:** `complete-order-delivery v14` يربط المستخدم عبر `users.auth_id = auth.uid()`; بينما `start-delivery v7` و`complete-delivery v4` و`cancel-delivery v5` وبعض endpoints القديمة تبحث بالبريد الإلكتروني. لا توحّد ذلك بتعديل الواجهة فقط؛ يلزم إصلاح backend identity/tenant/assignment checks في كل endpoint متأثر ثم اختبارها.
3. **ملاحظات التسليم:** بعد Patch B، يجب اختبار أن `reason_delivery` تظهر في تفاصيل التطبيق؛ وتحتاج نافذة النظام الأم إلى عرض تفاصيل order/item، لا تجميع الرانشيت فقط.
4. **المبلغ والتحصيل:** `summary/amount_paid` لا يدخلان عقد RPC الحالي. يلزم تحديد عقد محاسبي صحيح قبل وصف المبلغ بأنه محصّل أو تعديل الرصيد/الدفتر.
5. **إسناد السائق وحقول المرحلة:** Edge بدء/إنهاء التوصيل الحالية تحدّث الحالة ووقت البداية/النهاية، لكنها لا تحدّث `deliverer_id`. لا تكتب `deliverer_id` من المتصفح؛ يجب تحديد ما إذا كان هذا الحقل يعني المنفّذ الفعلي أم أنه علامة إدارية أخرى، ثم توحيد العقد مع النظام الأم.
6. **ملاحظات التحميل:** تبقى فجوة مستقلة في Loader/complete-loading؛ لا يمكن حلها بتغيير driver.html أو عرض `runsheets.notes` على أنها ملاحظات تحميل.

## 7. خطة الاختبار بعد تطبيق المالك وإصلاح Dependency

1. Static: تحليل JavaScript المضمن كاملًا في driver.html بعد الرقع، والتحقق من عدم وجود أخطاء syntax أو أسماء حقول غير موجودة.
2. Auth: مستخدم delivery فعّال، مالك، مستخدم غير نشط، مستخدم بلا delivery؛ لا ينشأ أي صف `users` تلقائيًا.
3. Tenant isolation: شركة A لا تستطيع جلب رانشيت/طلب/عميل من شركة B.
4. Assignment: السائق يرى الرانشيت المعين له فقط؛ السائق الآخر لا يراه ولا يستطيع تنفيذ start/complete/cancel.
5. Lifecycle: Loaded → Delivering → Delivered؛ منع التكرار والمحاولات المتزامنة، ثم التحقق من الحالة والتوقيتات والفاعل.
6. Order delivery: تسليم كامل، تسليم جزئي، صفر تسليم مع سبب، retry للطلب نفسه، ورفض كمية أعلى من `qty_loaded`.
7. Notes: سبب النقص يكتب إلى `reason_delivery` ويظهر في driver.html وفي سجل تفاصيل النظام الأم.
8. Financial: لا يُعرض “تم التحصيل” إلا بعد إثبات قيد التحصيل/المبلغ في العقد الخلفي.
9. Baseline: مقارنة حالات الرانشيت والأوامر والكميات قبل/بعد؛ فتح الشاشات لا يغير `stock_branches.qty`, `allocated_qty`, أو `inventory_log`.
10. Served HTML: إثبات أن الاستضافة تقدم blob/commit المقصود، ثم Browser/HTTP E2E مصادق عليه.
11. Governance: لا Fixtures دائمة؛ أي Fixture اختبار يُزال ويُثبت غيابه بعد الاختبار.

## 8. Mutation Ledger

- `driver.html`: لم يتغير.
- `main.html`: لم يتغير.
- Core/Edge/RPC/RLS/Schema/Production data: لم تتغير.
- تقرير جديد فقط، مع تحديث سجل الحالة التراكمي.
- لم تُنفذ HTTP E2E مصادق عليه؛ لا توجد رانشيت مخصصة لسائق في العينة الحالية.
- لا أدّعي أن Cloudflare/HTML المنشور يطابق Git.

## 9. SELF-AUDIT FINAL

**What I Proved**
- النسخ الحالية وبصمات blobs للملفات المستهدفة.
- هوية Production المباشرة لـEdge Functions ذات الصلة.
- وجود تعارض في آلية الهوية بين Edge الحالية.
- سياسات RLS لا تسمح بصلاحية delivery وحدها بقراءة الجداول اللازمة.
- RPC يكتب أسباب النقص إلى `reason_delivery` لا `notes`.
- المبلغ الذي ترسله الواجهة لا يدخل RPC الحالي.
- النظام الأم الحالي لا يحتفظ بسجل التوصيل التاريخي كاملًا، ويعرض UUID وحالة ثابتة في الجدول.

**What I Did Not Prove**
- HTML المنشور على Cloudflare يطابق Git.
- نجاح الرقع في Browser أو HTTP E2E.
- نجاح تدفق التسليم الكامل في Production.
- وجود قيد تحصيل فعلي لهذا المسار.
- المعنى النهائي المتفق عليه لحقل `deliverer_id`.

**What I Fixed**
- لم أغيّر أي ملف تشغيلي أو Production. جهزت رقعًا محددة ليطبقها المالك، وتجنبت تجاوز RLS أو إنشاء بيانات إنتاجية مصطنعة.

**What I Initially Missed**
- وجود Edge `get-driver-dashboard` في Production؛ فُحص مصدرها وظهر أنها لا تصلح للاعتماد قبل إصلاحها.
- أن `reason_delivery` هو الحقل الذي يكتبه الـRPC الحالي بينما الواجهة تقرأ `notes`.
- أن Edge Registry يعرض `complete-order-delivery v14` بينما تعليق مصدره يذكر v12.

**What Could Still Be Wrong**
- قد توجد صلاحيات إضافية لدى بعض حسابات السائقين تسمح بقراءات مباشرة؛ لم يُختبر حساب مصادق عليه في Browser.
- قد توجد قيود أو آثار محاسبية أخرى خارج المسار الذي فُحص؛ لا تُستنتج من هذا التقرير.
- لم يثبت نشر نسخة driver.html الحالية.

**Final Confidence:** مرتفعة في تشخيص المصدر/Production المحدد؛ متوسطة في الرقع المصدرية قبل تطبيقها؛ غير كافية لادعاء Runtime pass.

**Final Closure Status:** `PARTIAL — PATCHES READY / BACKEND IDENTITY+READ CONTRACT OPEN / E2E NOT RUN / NOT 100% CLOSED`.
