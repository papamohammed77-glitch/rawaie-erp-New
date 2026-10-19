# Report447 — التحقيق الجنائي وإصلاح عقد تتبع طلب المتجر الإلكتروني
**التاريخ:** 2026-10-19  
**النطاق:** `erp-frontend/companies/company-1/store/track.html` + عقد قراءة Production في Supabase فقط.  
**قيود محفوظة:** لم أعدّل `main.html`، ولم أعدّل `store/index.html` أو `store/track.html`؛ تعديل ملفات التطبيقات يطبقه المالك. لم أضف Edge Function جديدة ولم أنشئ طلبًا تجريبيًا في Production.

## 1. PRE-CHANGE SELF-AUDIT

- Business Understanding: تتبع الطلب الإلكتروني يعرض حالة الطلب والأصناف بعد إنشاء الطلب؛ لا يجوز تحويله إلى قراءة عامة لكل جدول الطلبات.
- Architecture Understanding: المتجر العام يستخدم Supabase public/anon key، أما قواعد بيانات الطلبات محمية بـRLS؛ القراءة العامة يجب أن تمر عبر RPC محدود بعقد صريح.
- Database Understanding: مثبت من Production أن `orders` و`order_details` عليهما RLS، وأن `order_details` يرتبط بالطلب عبر `order_id` وليس عبر عمود `order_code`.
- Historical Understanding: راجعت التغيير التاريخي `6f9bff32d4f6a036b199500ae8746a89abf2b48d` بتاريخ 2026-07-08. التغيير أدخل العميل المشترك من `core.js` وأبقى منطق الاستعلام القديم كما هو؛ لم يثبت أنه أصلح عقد تتبع الطلب.
- Production Understanding: تمت قراءة تعريف `submit_online_order_atomic` المنشور، وسياسات RLS، والـtriggers ذات الصلة، وفحص Edge `submit-online-order` الإصدار 11. إنشاء الطلب يستخدم المصدر `online_store` ويكتب رقم هاتف العميل في `orders.customer_phone`.
- Current Understanding: `track.html` الحالي SHA `bca9cddc3977bd4beb164acb811a0c82138a2d70`، 213 سطرًا. `store/index.html` الحالي SHA `75cca148ade533a3e6d7c73469c7a989c8016644` في الاستجابة الحالية.
- Execution Confidence: مرتفع بالنسبة إلى خلل القراءة وعقد RPC؛ تحقق Production إيجابي على طلب إلكتروني موجود وسلبي على طلب غير موجود. اختبار المتصفح بعد تطبيق تعديل المالك لم يحدث بعد.

### سجل المصادر التي فُحصت
- `rawaie-erp-New/CURRENT_STATE.md`؛ أحدث checkpoint فيه Report446، commit `da7ac6b3fd06854173f98ed4a60c0a6f0779fda3`.
- المصدر الحالي: [store/track.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/store/track.html) — SHA أعلاه.
- المصدر الحالي: [store/index.html](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/store/index.html).
- المصدر المشترك: `companies/company-1/core.js`؛ يستخدم العميل المشترك، لذلك لا ينبغي إنشاء عميل Supabase ثانٍ داخل صفحة التتبع.
- Historical commit: [6f9bff3](https://github.com/papamohammed77-glitch/erp-frontend/commit/6f9bff32d4f6a036b199500ae8746a89abf2b48d).
- Production Edge: `submit-online-order` v11، `verify_jwt=false`؛ يستخدم `submit_online_order_atomic` عبر `service_role`.
- Production SQL: `orders` و`order_details` RLS enabled؛ سياسات القراءة الموجودة موجهة إلى `authenticated` وليست عقد تتبع عام.
- Production schema: `order_details` يحوي `order_id`, `item_name`, `qty`, `unit_price`, `line_amount` ولا يحوي `order_code`.
- Production schema: `orders.tracking_token` له default `gen_random_uuid()`، لكن مسار checkout الحالي لا يعيد هذا الرمز إلى الواجهة؛ لذلك لم أبنِ التعديل على افتراض أن الواجهة تملكه.

## 2. Root cause — العيوب المثبتة

1. `Tracker.lookup()` ينفذ `supabase.from('orders').select('*')` من واجهة عامة؛ RLS الحالي لا يمنح `anon` قراءة عامة للطلبات، ولذلك لا يعتمد المسار على عقد صالح للمتجر العام.
2. الاستعلام الثاني يستخدم `.eq('order_code', orderCode)` على `order_details`، مع أن هذا العمود غير موجود في Production. الربط الصحيح في قاعدة البيانات هو `order_details.order_id = orders.id`.
3. الصفحة لا تفحص `orderRes.error` أو `detailsRes.error`، ولذلك قد تحول خطأ schema/RLS إلى «الطلب غير موجود» أو تعرض نتيجة ناقصة.
4. الصفحة تطبع `customer_name` و`area` و`item_name` داخل `innerHTML` دون escaping؛ هذه قيم قابلة للتأثر ببيانات العميل/الأصناف، وهذا يخلق stored-XSS risk.
5. طلب رقم الطلب وحده غير كافٍ لعقد تتبع عام؛ رقم الطلب تسلسلي. تمت إضافة تحقق إضافي من رقم هاتف العميل، مع تقييد النتيجة إلى الشركة التي يحددها `storefront_key` المنشور وإلى `source='online_store'`.

## 3. Production repair — تم التنفيذ والتحقق

### Migration
- Production migration: `20261019163902 / create_public_store_order_tracking_rpc`.
- الملف الموثق في Git: [20261019163902_create_public_store_order_tracking_rpc.sql](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/supabase/migrations/20261019163902_create_public_store_order_tracking_rpc.sql)
- Git commit: `80c90254678bda8773bb3a0d1b1d754ff5100314`.
- RPC: `public.get_public_store_order_tracking(text,text,text)`.
- المدخلات: `p_storefront_key`, `p_order_code`, `p_customer_phone`.
- السلوك: يحل الشركة من `app_settings` المنشور، ويرفض مفتاح المتجر غير الصالح أو الغامض، ويبحث فقط في طلبات `online_store` داخل الشركة المحددة، ويتحقق من رقم الهاتف بعد إزالة الرموز غير الرقمية.
- المخرجات: الحد الأدنى المطلوب للعرض (رقم الطلب، التاريخ، الحالة، اسم العميل، المنطقة، الإجمالي، وأصناف الطلب). لا يعيد هاتف العميل ولا `select *`.
- الأمان: `SECURITY DEFINER` مع `search_path = pg_catalog, public` وتأهيل أسماء الجداول؛ التنفيذ مسموح لـ`anon` و`authenticated` فقط، وممنوح صراحةً لهما بعد سحب الافتراضي من `PUBLIC`.
- لا توجد تغييرات في حركة المخزون أو الحجز أو دفتر الحسابات أو حالة الطلب؛ هذا RPC للقراءة فقط.

### Production verification
- بعد النشر: `anon EXECUTE=true`, `authenticated EXECUTE=true`, `service_role EXECUTE=false` على RPC الجديد.
- اختبار مفتاح متجر غير صالح: `success=false`.
- اختبار رقم طلب غير موجود: `success=false`.
- اختبار قراءة طلب إلكتروني حقيقي موجود باستخدام بياناته من داخل SQL دون إظهار بيانات العميل في نتيجة الاختبار: `success=true`، الحالة موجودة، قائمة الأصناف Array وبها 3 عناصر، و`phone_exposed=false`.
- Production data writes: صفر. لا طلبات تجريبية، لا تعديل حالة، لا حركة مخزون، ولا حذف بيانات.
- Logs: أداة الاستعلام عن Logs أعادت خطأ Backend؛ لم أستنتج منها أي نتيجة تشغيلية.

## 4. التعديل الجراحي المطلوب من المالك

### Patch A — إضافة حقل تحقق الهاتف

**الملف:** `companies/company-1/store/track.html`  
**SHA الأساس:** `bca9cddc3977bd4beb164acb811a0c82138a2d70`  
**الموضع:** الأسطر الحالية 35–42.  
**ابحث عن هذا المقطع واحذفه كاملًا:**

```html
        <label class="block text-xs font-bold text-gray-600 mb-2">رقم الطلب</label>
        <div class="flex gap-2">
            <input type="text" id="orderCodeInput" placeholder="مثلاً: ORD-12345" class="flex-1 p-3 bg-gray-50 rounded-xl border-2 border-gray-200 focus:border-blue-600 outline-none font-bold text-sm">
            <button onclick="Tracker.lookup()" class="bg-blue-600 text-white px-6 py-3 rounded-xl font-black text-sm hover:bg-blue-700 transition">
                <i class="fa-solid fa-search ml-1"></i> استعلام
            </button>
        </div>
        <p class="text-xs text-gray-400 mt-2">أدخل رقم الطلب الذي وصلك عند إتمام الشراء</p>
```

**واستبدله كاملًا بهذا:**

```html
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
                <label for="orderCodeInput" class="block text-xs font-bold text-gray-600 mb-2">رقم الطلب</label>
                <input type="text" id="orderCodeInput" autocomplete="off" placeholder="مثلاً: ORD-12345" class="w-full p-3 bg-gray-50 rounded-xl border-2 border-gray-200 focus:border-blue-600 outline-none font-bold text-sm">
            </div>
            <div>
                <label for="customerPhoneInput" class="block text-xs font-bold text-gray-600 mb-2">رقم الهاتف المستخدم في الطلب</label>
                <input type="tel" id="customerPhoneInput" inputmode="tel" autocomplete="tel" placeholder="رقم الهاتف عند الشراء" class="w-full p-3 bg-gray-50 rounded-xl border-2 border-gray-200 focus:border-blue-600 outline-none font-bold text-sm">
            </div>
        </div>
        <button type="button" onclick="Tracker.lookup()" class="mt-3 w-full bg-blue-600 text-white px-6 py-3 rounded-xl font-black text-sm hover:bg-blue-700 transition">
            <i class="fa-solid fa-search ml-1"></i> استعلام آمن عن الطلب
        </button>
        <p class="text-xs text-gray-400 mt-2">لخصوصيتك، أدخل رقم الطلب ورقم الهاتف المستخدم عند إتمام الشراء.</p>
```

### Patch B — إضافة HTML escaping

**الموضع:** بعد وسم `<script>` مباشرةً وقبل `var Tracker = {` الحالي في السطر 59 تقريبًا.  
**أدرج هذا المساعد فقط؛ لا تستبدل الكائن أو الملف:**

```javascript
function escapeHtml(value) {
    var entities = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    };
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (character) {
        return entities[character];
    });
}

```

### Patch C — استبدال دالة lookup فقط

**الملف:** `track.html`  
**الدالة:** `Tracker.lookup`، تبدأ عند السطر الحالي 60 وتنتهي عند `},` التي تسبق `showStatus`.  
**احذف دالة `lookup` الحالية كاملة واستبدلها بهذا النص:**

```javascript
    lookup: function() {
        var orderCode = (document.getElementById('orderCodeInput').value || '').trim();
        var customerPhone = (document.getElementById('customerPhoneInput').value || '').trim();

        if (!orderCode || !customerPhone) {
            Swal.fire({ icon: 'warning', title: 'أدخل رقم الطلب ورقم الهاتف المستخدم عند الشراء' });
            return;
        }

        var container = document.getElementById('resultContainer');
        container.innerHTML = '<div class="card text-center py-8"><i class="fa-solid fa-spinner fa-spin text-2xl text-blue-600"></i><p class="mt-2 text-gray-500">جاري البحث...</p></div>';

        var self = this;
        supabase.rpc('get_public_store_order_tracking', {
            p_storefront_key: 'company-1',
            p_order_code: orderCode,
            p_customer_phone: customerPhone
        }).then(function(result) {
            if (result.error) throw result.error;

            var payload = result.data;
            if (!payload || payload.success !== true || !payload.order) {
                container.innerHTML = '<div class="card text-center py-8"><i class="fa-solid fa-circle-xmark text-4xl text-red-400 mb-3"></i><p class="font-bold text-gray-700">تعذر العثور على الطلب بهذه البيانات</p><p class="text-sm text-gray-400 mt-1">راجع رقم الطلب ورقم الهاتف ثم حاول مرة أخرى.</p></div>';
                return;
            }

            self.showStatus(container, payload.order, Array.isArray(payload.items) ? payload.items : []);
        }).catch(function(error) {
            console.error('Order tracking RPC failed:', error);
            container.innerHTML = '<div class="card text-center py-8"><i class="fa-solid fa-triangle-exclamation text-4xl text-red-400 mb-3"></i><p class="font-bold text-gray-700">تعذر الاستعلام عن الطلب الآن</p><p class="text-sm text-gray-400 mt-1">تحقق من الاتصال وحاول مرة أخرى.</p></div>';
        });
    },
```

### Patch D — إصلاح عرض مراحل الطلب

**الدالة:** `Tracker.showStatus`، استبدل فقط كتلة `statusLabels` الحالية من `var statusLabels = {` حتى إغلاق الكائن `};`، وكتلة `steps` و`currentStep` الحالية، بالنص التالي:

```javascript
        var statusLabels = {
            'Draft': 'قيد المراجعة',
            'Confirmed': 'تم التأكيد',
            'Pending': 'قيد الانتظار',
            'Picking': 'جاري التجهيز',
            'Picked': 'تم التجهيز',
            'Loading': 'جاري التحميل',
            'Loaded': 'تم التحميل',
            'Delivering': 'خارج للتوصيل',
            'Delivered': 'تم التسليم',
            'Partially Delivered': 'تم التسليم جزئيًا',
            'Partially Returned': 'تم إرجاع جزء من الطلب',
            'Cancelled': 'ملغي',
            'Canceled': 'ملغي'
        };
        var statusLabel = statusLabels[order.order_status] || escapeHtml(order.order_status || 'غير محدد');

        var steps = [
            { key: 'Pending', label: 'قيد الانتظار', icon: 'fa-clock' },
            { key: 'Confirmed', label: 'تم التأكيد', icon: 'fa-check-circle' },
            { key: 'Picked', label: 'تم التجهيز', icon: 'fa-box' },
            { key: 'Loaded', label: 'تم التحميل', icon: 'fa-truck-loading' },
            { key: 'Delivering', label: 'خارج للتوصيل', icon: 'fa-truck-fast' },
            { key: 'Delivered', label: 'تم التسليم', icon: 'fa-home' }
        ];

        var currentStep = 0;
        if (order.order_status === 'Delivered' || order.order_status === 'Partially Delivered' || order.order_status === 'Partially Returned') currentStep = 5;
        else if (order.order_status === 'Delivering') currentStep = 4;
        else if (order.order_status === 'Loaded' || order.order_status === 'Loading') currentStep = 3;
        else if (order.order_status === 'Picked' || order.order_status === 'Picking') currentStep = 2;
        else if (order.order_status === 'Confirmed') currentStep = 1;
```

بعد هذا الاستبدال، في السطر الذي يحسب عرض شريط التقدم، استبدل `(currentStep / 4 * 100)` بـ`(currentStep / 5 * 100)`.

### Patch E — منع إدخال بيانات غير موثوقة في HTML

داخل `Tracker.showStatus`، غيّر هذه التعبيرات فقط:
- `(details[d].item_name || '')` إلى `escapeHtml(details[d].item_name || '')`.
- `(order.order_code || '')` إلى `escapeHtml(order.order_code || '')`.
- `' + statusLabel + '` إلى `' + escapeHtml(statusLabel) + '`.
- `(order.customer_name || '')` إلى `escapeHtml(order.customer_name || '')`.
- `(order.area || '')` إلى `escapeHtml(order.area || '')`.

لا تغيّر بناء الجدول أو بقية العرض.

### Patch F — دعم Enter في حقلي البحث

**الموضع:** داخل `DOMContentLoaded` الحالي، استبدل كتلة `var input = ...` حتى نهاية `if (input)` فقط بهذا:

```javascript
    var input = document.getElementById('orderCodeInput');
    var phoneInput = document.getElementById('customerPhoneInput');
    function submitOnEnter(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            Tracker.lookup();
        }
    }
    if (input) input.addEventListener('keydown', submitOnEnter);
    if (phoneInput) phoneInput.addEventListener('keydown', submitOnEnter);
```

## 5. الاختبارات المطلوبة بعد تطبيق المالك للتعديل

1. رقم طلب صحيح + هاتف مطابق: يعرض الحالة والأصناف.
2. رقم طلب صحيح + هاتف خاطئ: لا يعرض أي بيانات للطلب.
3. رقم طلب غير موجود: رسالة موحدة لا تكشف وجود طلب آخر.
4. متجر غير منشور أو مفتاح غير صالح: لا توجد بيانات.
5. اختبار عبر Enter من كل حقل.
6. اختبار قيم اسم/منطقة/صنف تتضمن `<script>` أو علامات HTML: تظهر كنص ولا تنفذ.
7. حالات `Pending`, `Picking`, `Loaded`, `Delivering`, `Delivered`, `Cancelled` وحالات التسليم/الإرجاع الجزئي.
8. Console/Network: استدعاء RPC واحد فقط؛ لا توجد طلبات مباشرة إلى `orders` أو `order_details` من صفحة التتبع.
9. تحقق من أن صفحة المتجر الرئيسية وcheckout و`core.js` لم تتغير.
10. نفذ اختبار المتصفح على النسخة المنشورة بعد رفع التعديل؛ لا تعتبر SQL verification إثباتًا لـbrowser E2E.

## 6. النتيجة / حدود الإغلاق

**Production RPC:** DEPLOYED + SQL VERIFIED.  
**Git migration artifact:** COMMITTED.  
**UI source:** OWNER PATCH REQUIRED — لم ألمس التطبيق التشغيلي وفق تقسيم المسؤوليات.  
**Browser E2E / served artifact parity:** OPEN حتى يطبق المالك التعديلات ويختبر الصفحة المنشورة.  
**Business data residue:** صفر؛ لم تُنشأ بيانات اختبار في Production.  
**Final status:** `PRODUCTION READ CONTRACT FIXED / UI PATCH READY / NOT END-TO-END CLOSED YET`.

## SELF-AUDIT FINAL

- What I Proved: RLS يمنع الاعتماد على القراءة العامة المباشرة؛ `order_details.order_code` غير موجود؛ RPC الجديد يعمل على طلب إلكتروني موجود دون إرجاع الهاتف؛ الاختبارات السلبية أعادت `success=false`; ACL مضبوط.
- What I Did Not Prove: browser E2E بعد تعديل المصدر، النشر الفعلي لصفحة `track.html`، ولا تطابق artifact المستضاف مع Git.
- What I Fixed: أضفت RPC قراءة عام محدودًا بالمفتاح المنشور + رقم الطلب + الهاتف، وقيّدت المصدر والشركة، وسحبت التنفيذ من `PUBLIC` ثم منحته فقط لـ`anon/authenticated`.
- What I Initially Missed: كان من الممكن الاكتفاء بقراءة RLS؛ فحص schema كشف أيضًا أن الاستعلام على `order_details.order_code` غير صالح وأن أخطاء Supabase لا تُفحص.
- What Could Still Be Wrong: قد تختلف صيغة الهاتف التي يدخلها العميل عن الصيغة المسجلة إذا تغيّر البلد/المقدمة؛ التطبيع الحالي يزيل علامات التنسيق فقط ولا يحوّل رمز البلد إلى صفر محلي. اختبار المتصفح بعد التطبيق مطلوب.
- Final Confidence: مرتفع في إصلاح Production RPC؛ متوسط في الإغلاق الكامل حتى تطبيق المالك للـUI.
- Final Closure Status: `PRODUCTION CONTRACT VERIFIED / OWNER UI PATCH PENDING / E2E OPEN`.
