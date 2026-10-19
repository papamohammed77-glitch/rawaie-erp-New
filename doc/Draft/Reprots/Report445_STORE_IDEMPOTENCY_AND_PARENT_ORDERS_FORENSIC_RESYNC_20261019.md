# Report445 — التحقيق الحالي لتكامل المتجر وفلتر أوردرات العمليات
**التاريخ:** 2026-10-19  
**النطاق:** مراجعة المصدر الحالي للمتجر الإلكتروني، عقد Production الخاص بإنشاء طلب المتجر، وحالة فلتر «أوردرات عمليات» في النظام الأم.  
**قاعدة الملكية:** لم أعدّل `main.html` أو `store/index.html`، ولم أنفذ تغييرات DDL/RPC/ACL/Edge أو تغييرات في بيانات الأعمال. التعديلات المصدرية أدناه جراحية ويطبقها المالك.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** 98/100 — طلب المتجر يجب أن يُنشأ مرة واحدة لكل محاولة منطقية، وأن يظهر في النظام الأم بمصدر `online_store`، وأهلية ضمه للرانشيت يحكمها عقد العمليات لا مجرد مصدر الطلب.
- **Architecture Understanding:** 98/100 — المتجر العام يقرأ الكتالوج من `get_public_store_catalog` ويرسل الإنشاء إلى `submit-online-order`؛ النظام الأم يدير عرض الأوردرات والفلترة، وEdge يمرر الإنشاء إلى Core.
- **Database Understanding:** 99/100 للنطاق المفحوص — تم فحص ACL وتعريفات RPC ذات الصلة وبيانات المتجر/الأوردرات قراءةً فقط.
- **Historical Understanding:** 97/100 — تمت مراجعة Report442/443/444 والتغييرات الفعلية في commits، ولم تُعامل الحالات التاريخية على أنها الحالة الحالية.
- **Production Understanding:** 99/100 للنطاق المفحوص — فحص مباشر في 2026-10-19 16:13 UTC.
- **Current Understanding:** 99/100 — تم جلب المصدر الحالي للمتجر وقراءة مسار `submitOrder` و`loadSettings`، وفحص فروق commits الخاصة بفلتر العمليات وإصلاح syntax.
- **Execution Confidence:** 96/100 للتشخيص؛ لا يمكن إثبات Browser/HTTP E2E أو Cloudflare served-artifact parity من فحص المصدر وحده.

### Confirmed facts / Unknowns / Conflicts

**Confirmed**
1. `erp-frontend/companies/company-1/store/index.html` الحالي SHA `4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e`، 576 سطرًا.
2. المصدر الحالي يستدعي `get_public_store_catalog` مع `p_storefront_key: null`.
3. `Store.submitOrder` يرسل `user/cartItems/total/delivery/couponCode/couponDiscount` فقط؛ لا يرسل `storefront_key` أو `operation_id`، ولا `Idempotency-Key`.
4. Production Edge `submit-online-order` هو v11، ACTIVE، `verify_jwt=false`، `ezbr_sha256=172eff4fccc8bf43f920e9ab8c83dd39aa988a68c9e5b3170ce320138ff31315`.
5. Edge يولد `crypto.randomUUID()` جديدًا عند غياب `body.operation_id` وheader `idempotency-key`. لذلك لا يوجد ضمان retry idempotency بين محاولتين منفصلتين من الواجهة الحالية.
6. Production Core `submit_online_order_atomic(..., p_operation_id uuid)` يرفض `NULL` ويحتوي منطقًا يعتمد على `operation_id`. ACL: `anon=false`, `authenticated=false`, `service_role=true`. لا نفتح RPC الحساس للزوار.
7. `get_public_store_catalog(text)` متاح لـanon/authenticated بوصفه RPC قراءة عامة محدودة، مع `search_path=public, pg_temp`.
8. Production يؤكد أن `app_settings.storefront_key='company-1'` و`storefront_enabled=true` للشركة `00000000-0000-0000-0000-000000000001`.
9. لقطة Production عند 2026-10-19 16:13:44 UTC: 12 أوردرًا؛ `pos=5`, `telesales=2`, `order-taker=4`, `online_store=1`. لم تُنشأ أوردرات اختبار.
10. المصدر الحالي لـ`main.html` له blob SHA `1b38c60ff38d439d429474b17ff54b5b169c07b4`. Commit `1a60b404e1d3c9e2769036618bebf3c66947d1f1` نقل `_toggleOperationsOnly` من جسم `_refreshData()` إلى كائن التصدير، وأزال خطأ syntax الموثق في Report444.
11. Commit `159b3113a14a1f8a23be759b7085fe7ae148ce21` أضاف زر «أوردرات عمليات» وفلتر المصدر ومنطق الأهلية في `RW_Orders`. قاعدة الأهلية الحالية بالمصدر: المصدر بعد التطبيع أحد `telesales/tele-sales/order-taker/online-store`، والحالة `Confirmed/Pending`، ولا يوجد `runsheet_id`. هذا متوافق مع RPCs الحية التي تفحص المصدر والحالة والارتباط بالرانشيت.
12. Commit `16511abe1af392c0e9cb55bc9bd204d23f46e0e3` أدخل fragment مكررًا في سطر «نص الشارة» داخل `main.html`. لم يظهر في diff إصلاح لاحق لهذا السطر؛ يلزم تنظيفه جراحيًا. لا أصفه بأنه سبب خطأ syntax الحالي؛ خطأ syntax الخاص بتصدير الزر أُصلح في commit `1a60b404...`.

**Unknown / Unverified**
- لم يتم تشغيل Browser E2E على الواجهة المنشورة.
- لم يتم إثبات أن Cloudflare served artifact يطابق blob الحالي.
- لم يتم إرسال HTTP checkout حقيقي في Production؛ لم نُنشئ بيانات أعمال تجريبية.
- لا يوجد دليل يبرر حذف سجلات أو أصناف Production؛ لذلك لم تُحذف بيانات.

## 1. الحالة الحالية: ما تم إصلاحه وما بقي

### النظام الأم — `RW_Orders`
- زر «أوردرات عمليات» وفلتر المصدر موجودان في المصدر الحالي وفق diff commit `159b311...`.
- خطأ تصدير `_toggleOperationsOnly` تم إصلاحه في commit `1a60b404...`.
- لا تعِد تطبيق Report443 PATCH 1–8 على عماها؛ التغييرات موجودة في المصدر.
- بقيت عملية تنظيف fragment نص الشارة المكرر، ثم syntax/browser verification بعد تطبيق المالك.
- لا تغيير Production مطلوب لتصفية الواجهة؛ عقد إنشاء/ضم الرانشيت الحالي يطابق شروط الأهلية المذكورة.

### المتجر الإلكتروني
- الكتالوج الحالي يعمل من RPC محدود، وحصة العرض/المتبقي تأتي من Production.
- فجوة حقيقية: غياب `storefront_key` الصريح في استدعاء الكتالوج والطلب، وغياب `operation_id` ثابت عبر إعادة المحاولة.
- لا يتطلب الإصلاح تغيير Edge/RPC/ACL؛ v11 وCore يدعمان المفتاحين بالفعل.
- لا تغير قواعد المخزون: طلب المتجر لا ينشئ حجزًا أو حركة مخزون فورية؛ يبقى ضمن دورة الطلب المعتمدة.

## 2. Owner Surgical Changeset A — تنظيف السطر المكرر في النظام الأم

**الملف:** `erp-frontend/companies/company-1/main.html`  
**SHA الحالي:** `1b38c60ff38d439d429474b17ff54b5b169c07b4`  
**الموضع:** كتلة `RW_Items`، حقل «نص الشارة»، السطر التاريخي 5543؛ أعد تحديده بالمحدد أدناه لأن رقم السطر قد يتحرك.

**ابحث عن السطر الذي يبدأ وينتهي بهذا النص الكامل:**
```javascript
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="' + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>'; + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>';
```

**استبدل السطر كاملًا بهذا السطر فقط:**
```javascript
        html += '<div class="flex flex-col"><label class="text-sm font-bold">نص الشارة</label><input id="item-badge-text" value="' + _esc(item ? (item.badge_text || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg" placeholder="جديد، الأكثر مبيعاً، عرض محدود"></div>';
```

لا تستبدل كتلة التسويق أو دالة بناء المودال كاملة.

## 3. Owner Surgical Changeset B — تثبيت هوية المتجر عند قراءة الكتالوج

**الملف:** `erp-frontend/companies/company-1/store/index.html`  
**SHA:** `4af4e2f2f7727f84bdad5afb91932d5f7efe2a3e`  
**الدالة:** `self.loadSettings`، قرب السطر 122.

ابحث عن:
```javascript
    return supabase.rpc('get_public_store_catalog', { p_storefront_key: null })
```

واستبدله بـ:
```javascript
    return supabase.rpc('get_public_store_catalog', { p_storefront_key: 'company-1' })
```

هذا يربط المتجر بوضوح بمفتاحه المنشور بدل الاعتماد على وجود متجر منشور واحد فقط.

## 4. Owner Surgical Changeset C — operation_id ثابت وآمن عبر retry

### C1 — أضف helpers دون حذف أي دالة قائمة

**الموضع:** مباشرة بعد الدالة الحالية `loadCustomerData()` وقبل `self.init = function()` قرب السطر 107.

أضف الكتلة التالية كاملة:
```javascript
    function _createStoreOperationUuid() {
        var cryptoApi = window.crypto;
        if (!cryptoApi || typeof cryptoApi.getRandomValues !== 'function') {
            throw new Error('المتصفح لا يدعم إنشاء مفتاح طلب آمن؛ لم يتم إرسال الطلب.');
        }
        if (typeof cryptoApi.randomUUID === 'function') return cryptoApi.randomUUID();

        var bytes = new Uint8Array(16);
        cryptoApi.getRandomValues(bytes);
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        var hex = Array.prototype.map.call(bytes, function (b) {
            return ('0' + b.toString(16)).slice(-2);
        }).join('');
        return hex.slice(0, 8) + '-' + hex.slice(8, 12) + '-' +
            hex.slice(12, 16) + '-' + hex.slice(16, 20) + '-' + hex.slice(20);
    }

    function _getOrCreateStoreOperationId(payload) {
        if (!window.crypto || !window.crypto.subtle || typeof TextEncoder === 'undefined') {
            return Promise.reject(new Error('تعذر إنشاء بصمة آمنة للطلب؛ حدّث المتصفح ثم أعد المحاولة.'));
        }

        var serialized = JSON.stringify(payload);
        var storageKey = 'rw_store_pending_checkout_v1';
        return window.crypto.subtle.digest('SHA-256', new TextEncoder().encode(serialized)).then(function (hashBuffer) {
            var fingerprint = Array.prototype.map.call(new Uint8Array(hashBuffer), function (b) {
                return ('0' + b.toString(16)).slice(-2);
            }).join('');
            var saved = null;

            try {
                saved = JSON.parse(localStorage.getItem(storageKey) || 'null');
            } catch (e) {
                saved = null;
            }

            var uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
            if (saved && saved.fingerprint === fingerprint && uuidPattern.test(saved.operation_id || '')) {
                return saved.operation_id;
            }

            var operationId = _createStoreOperationUuid();
            try {
                localStorage.setItem(storageKey, JSON.stringify({
                    fingerprint: fingerprint,
                    operation_id: operationId,
                    created_at: new Date().toISOString()
                }));
            } catch (e) {
                throw new Error('تعذر حفظ مفتاح منع تكرار الطلب؛ لم يتم إرسال الطلب.');
            }
            return operationId;
        });
    }

    function _clearStoreOperationId(operationId) {
        var storageKey = 'rw_store_pending_checkout_v1';
        try {
            var saved = JSON.parse(localStorage.getItem(storageKey) || 'null');
            if (saved && saved.operation_id === operationId) {
                localStorage.removeItem(storageKey);
            }
        } catch (e) {
            console.warn('تعذر تنظيف مفتاح الطلب المكتمل:', e);
        }
    }
```

### C2 — أرسل المفتاح الصريح مع جسم الطلب

داخل `self.submitOrder`، ابحث عن كائن `bodyPayload` الحالي:
```javascript
    var bodyPayload = {
        user: customer,
        cartItems: itemsList,
        total: total,
        delivery: settings.deliveryFee || 0,
        couponCode: couponCode,
        couponDiscount: couponDiscount
    };
```

استبدله كاملًا بـ:
```javascript
    var bodyPayload = {
        storefront_key: 'company-1',
        user: customer,
        cartItems: itemsList,
        total: total,
        delivery: settings.deliveryFee || 0,
        couponCode: couponCode,
        couponDiscount: couponDiscount
    };
```

### C3 — احصل على operation_id قبل HTTP

ابحث عن بداية الطلب الحالية:
```javascript
    fetch(SUPABASE_URL + '/functions/v1/submit-online-order', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_KEY,
            'Authorization': 'Bearer ' + SUPABASE_KEY
        },
        body: JSON.stringify(bodyPayload)
    }).then(function(res) {
```

استبدل هذا المقطع كاملًا بـ:
```javascript
    _getOrCreateStoreOperationId(bodyPayload).then(function (operationId) {
        bodyPayload.operation_id = operationId;
        return fetch(SUPABASE_URL + '/functions/v1/submit-online-order', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': SUPABASE_KEY,
                'Authorization': 'Bearer ' + SUPABASE_KEY,
                'Idempotency-Key': operationId,
                'x-storefront-key': 'company-1'
            },
            body: JSON.stringify(bodyPayload)
        });
    }).then(function(res) {
```

اترك كل معالجات الاستجابة الحالية بعد `.then(function(res)` كما هي.

### C4 — نظّف مفتاح العملية بعد تأكيد نجاح الطلب ومسح السلة

داخل معالج النجاح الحالي:
```javascript
            }).then(function() {
                cart = [];
```

أضف سطر التنظيف قبل تفريغ السلة:
```javascript
            }).then(function() {
                _clearStoreOperationId(bodyPayload.operation_id);
                cart = [];
```

هذا يضمن أن retry لنفس جسم الطلب يستخدم UUID نفسه، وأن المفتاح لا يُزال قبل عرض نجاح الطلب وتفريغ السلة بالطريقة الحالية. إذا فشل الاتصال أو انتهت مهلة العميل، يبقى المفتاح محفوظًا لإعادة المحاولة. إذا تغير جسم الطلب، تنشأ عملية جديدة بمفتاح جديد.

## 5. Production / Data safety

- لم أغير Production لأن Edge v11 وRPC الحالي يدعمان `storefront_key` و`operation_id`؛ المشكلة في عدم تمريرهما من المستهلك.
- ACL بقي كما هو: الزوار لا يستطيعون استدعاء `submit_online_order_atomic` مباشرة.
- لم أرسل HTTP checkout تجريبيًا ولم أنشئ أوردرات دائمة. هذه خطوة مقصودة لحماية بيانات الأعمال في غياب بيئة Staging/Fixture معزولة مثبتة.
- لم أحذف أي سجل أو صنف. لقطة Production تتضمن صنفًا بحصة عرض محددة ومبيعات متجر قائمة؛ لا يوجد دليل يثبت أنها بيانات خاطئة أو تجريبية، لذا حذفها سيكون تخمينًا غير مقبول.
- لم أعدّل أي Edge Function أو أنشئ Function جديدة، ولم أغير عقد المخزون أو الرانشيت.

## 6. اختبارات الإغلاق بعد تطبيق المالك

1. **Static:** افحص syntax للملفين بعد PATCH A–C، وتأكد أن `_toggleOperationsOnly` مُصدّر مرة واحدة فقط داخل كائن `RW_Orders`.
2. **Parent filters:** افتح أوردرات المبيعات؛ فلتر المصدر يعرض `online_store` تحت تسمية المتجر الإلكتروني بعد التطبيع، وزر «أوردرات عمليات» يطابق أهلية checkbox وRPC. اختبر التفعيل/الإلغاء/إعادة التعيين/Realtime/الفرز.
3. **Store catalog scope:** تحقق من نجاح `get_public_store_catalog('company-1')` وظهور المنتجات المنشورة للشركة المقصودة فقط.
4. **Idempotency:** في بيئة اختبار معزولة، أرسل نفس payload و`operation_id` مرتين؛ يجب أن يعيد الطلب الثاني نتيجة duplicate لنفس الأوردر، دون أوردر أو حركة إضافية. ثم غيّر payload عمدًا وتأكد من إنشاء operation ID جديد.
5. **Failure/retry:** افصل الاستجابة بعد إرسال الطلب ثم أعد نفس الطلب؛ يجب ألا ينشأ أوردر ثانٍ.
6. **Data baseline:** سجّل العدد والتوزيع قبل الاختبار وبعد تنظيف Fixture؛ يجب ألا يبقى أثر اختبار.
7. **Production/browser:** افحص Cloudflare served artifact وجرّب المسار المنشور. لا تدّعِ نجاح HTTP E2E من SQL فقط.

## SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي لا يرسل مفتاح idempotency ثابتًا؛ Edge v11 يولد UUID جديدًا عند غياب المفتاح؛ Core يتطلب operation ID؛ المفتاح المنشور `company-1` مفعّل؛ ACL تمنع وصول الزوار المباشر إلى Core؛ زر العمليات وفلتر المصدر موجودان في Git، وخطأ تصدير الزر عولج في commit `1a60b404...`.
- **What I Did Not Prove:** لم أنفذ Browser/HTTP E2E أو اختبار Cloudflare artifact؛ لم أرسل طلبًا إلى Production ولم أنشئ fixture.
- **What I Fixed:** لم أعدل الملفات التشغيلية أو Production؛ وثقت الحالة الحالية والتعديلات الجراحية الدقيقة.
- **What I Initially Missed:** Report444 كان snapshot قبل إصلاح syntax؛ كما أن اعتماد Edge على متجر منشور وحيد لا يغني عن تمرير storefront key صريح.
- **What Could Still Be Wrong:** قد تظهر أخطاء runtime أخرى بعد تطبيق التغييرات؛ يلزم اختبار HTTP/browser حقيقي في بيئة معزولة.
- **Final Confidence:** 96/100 في التشخيص؛ runtime غير مثبت.
- **Final Closure Status:** `CURRENT SOURCE + PRODUCTION CONTRACT VERIFIED / OWNER SURGICAL PATCHES READY / BROWSER E2E + SERVED ARTIFACT OPEN / NOT CLOSED`.
