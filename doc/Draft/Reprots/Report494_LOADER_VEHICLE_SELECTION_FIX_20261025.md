# تقرير التحقيق والتنفيذ — اختيار المركبة بعد الضغط على «بدء التحميل»

**رقم الحدث:** LVE-2026-10-25-494-R1  
**التاريخ:** 2026-10-25  
**المشروع:** RAWAEA ERP / Supabase Production `fiilmooggumokxanwiyx`  
**النطاق:** `erp-frontend/companies/company-1/warehouse/loader.html → start-loading → start_runsheet_loading_with_vehicle → start_runsheet_loading`  
**حالة التقرير:** `PRODUCTION BACKEND VERIFIED / OWNER-APPLIED HTML PATCH READY / UI RUNTIME E2E OPEN`

> **تصحيح تصميمي إلزامي:** لا يظهر حقل المركبة داخل معاينة الرانشيت قبل الضغط على «بدء التحميل». المطلوب أن يضغط المستخدم أولًا على «بدء التحميل»، ثم يظهر حقل اختيار المركبة في أعلى صفحة التحميل، قبل بدء أي انتقال إلى حالة `Loading`. بعد اختيار المركبة والضغط على «تأكيد المركبة وبدء التحميل» فقط، يُرسل الطلب إلى Edge Function.

---

## 1. PRE-CHANGE SELF-AUDIT

| المجال | الحالة | الدليل والحدود |
|---|---|---|
| فهم العرض الظاهر | CONFIRMED | Console أظهر HTTP 400 من `start-loading` ورسالة «لا يمكن بدء التحميل قبل إسناد مركبة للرانشيت». |
| مصدر Loader التشغيلي | CONFIRMED | `papamohammed77-glitch/erp-frontend`, `companies/company-1/warehouse/loader.html`, blob SHA `6bc6ad2ee93396faca20576241ad3318679171ef`. |
| Production Edge | CONFIRMED | قراءة مباشرة في هذه الجلسة: `start-loading v6`, `ACTIVE`, `verify_jwt=true`, `ezbr_sha256=b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1`. |
| مطابقة Edge Current/Production | CONFIRMED | تمت مقارنة نص `Current/Edge_Functions/start-loading` مع مصدر Production المسترجع؛ التطابق النصي الكامل `true`، والطول 2,587 حرفًا، وCurrent blob SHA `5fc6b01826ad098d6621d7f80ea8efb4eba8d5a0`. |
| Production Core | CONFIRMED | `start_runsheet_loading_with_vehicle(uuid,text,text,uuid)` موجودة في Production ومهمتها إسناد المركبة ثم استدعاء `start_runsheet_loading` داخل المعاملة نفسها. |
| Migration lineage | CONFIRMED | سجل Production يحتوي `20261025154530 / start_loading_vehicle_context_guard_20261025` و`20261025160441 / start_runsheet_loading_vehicle_selection`. |
| صلاحية قراءة المركبات | CONFIRMED | Production policy `vehicles_select_company` تسمح بقراءة مركبات الشركة الحالية للمستخدم المصادق عليه. |
| واجهة المستخدم بعد التغيير | UNVERIFIED | لا يمكن ادعاء أنها تغيرت أو نُشرت؛ سياسة المهمة تمنع تعديل `loader.html` مباشرةً، والمالك يطبق الـpatch المصدرّي. |
| Cloudflare served artifact | UNKNOWN | لم يتوفر في الأدلة الحالية إثبات مباشر لبصمة HTML التي يخدمها Cloudflare. |
| HTTP E2E ناجح من الواجهة | UNVERIFIED | لم يُنفذ بعد تطبيق patch الواجهة ونشرها. |

### مصادر تمت مراجعتها

- `doc/Draft/Reprots/writing-block.md`، وبالأخص نطاق المهمة التنفيذية وسياسة منع تعديل `loader.html` مباشرةً.
- التقرير السابق `Report494_LOADER_VEHICLE_SELECTION_FIX_20261025.md`، والتقرير السابق المرتبط `Report493_LOADING_CONTEXT_VEHICLE_ASSIGNMENT_FORENSIC_20261025.md`.
- Loader المنشور في مستودع `erp-frontend`، بما فيه `openRunsheet`, `_showPreviewModal`, `_startLoadingFromPreview`, `startLoading`.
- مصدر Edge الحالي ومصدر Edge المنشور في Production، مع مقارنة نصية مباشرة.
- Production SQL لتعريفات `start_runsheet_loading` و`start_runsheet_loading_with_vehicle`، وسجل migrations وسياسة قراءة `vehicles`.
- Production Edge snapshot في نفس جلسة التقرير.

---

## 2. السبب الجذري — ما الذي حدث فعليًا؟

### 2.1 الواجهة لا ترسل `vehicle_id`

في Loader المنشور، زر المعاينة مرتبط بـ`_startLoadingFromPreview(code)`، والدالة الحالية تستدعي:

```javascript
_startLoadingFromPreview: function(code) {
    Swal.close(); this.startLoading(code);
},
```

ثم تقوم `startLoading(code)` بإرسال:

```javascript
RW_API.call('start-loading', { runsheet_code: code }, callback);
```

إذن الطلب لا يتضمن `vehicle_id`، ولا توجد خطوة اختيار مركبة بين ضغط المستخدم على «بدء التحميل» وإرسال طلب بدء التحميل.

### 2.2 رفض قاعدة البيانات صحيح ولا ينبغي إزالته

Production `start_runsheet_loading` يتحقق من أن الرانشيت في حالة `Picked` وأنه مرتبط بمركبة صحيحة ونشطة ضمن الشركة، ومفعّل لها `mobile_stock_enabled`، وأن فرع VAN صالح ونشط. عند غياب المركبة يرفض الانتقال قبل إنشاء دورة تحميل جديدة.

هذا الرفض حماية صحيحة. **لا يجوز إصلاح المشكلة بإزالة شرط المركبة أو السماح ببدء تحميل بلا مركبة.** الإصلاح الصحيح هو إضافة خطوة اختيار المركبة في الواجهة وإرسال معرفها إلى المسار الخلفي المعتمد.

### 2.3 المسار الخلفي موجود بالفعل

Production `start-loading v6` يقرأ `body.vehicle_id`؛ عند وجوده يستدعي `start_runsheet_loading_with_vehicle`، وعند غيابه يبقى المسار القديم محميًا ويرفض الرانشيت غير المسند. لا توجد حاجة مثبتة إلى Edge Function جديدة.

الدالة الخلفية الجديدة تتحقق من المركبة والشركة والحالة ودعم المخزون المتنقل، وتقفل السجلات اللازمة، ثم تسند المركبة وتستدعي `start_runsheet_loading`. فشل بدء التحميل يلغي إسناد المركبة ضمن المعاملة نفسها. لم يُثبت في هذا التقرير أي داعٍ لتغيير هذا العقد الخلفي مرة أخرى.

---

## 3. Production snapshot — تحقق مباشر

### Edge Function `start-loading`

| الحقل | القيمة الحية |
|---|---|
| Version | `6` |
| Status | `ACTIVE` |
| `verify_jwt` | `true` |
| `ezbr_sha256` | `b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1` |
| Current source | `Current/Edge_Functions/start-loading` |
| Current blob SHA | `5fc6b01826ad098d6621d7f80ea8efb4eba8d5a0` |
| Current vs Production source | `EXACT TEXT MATCH` في الاسترجاع المباشر لهذه الجلسة |

`ezbr_sha256` بصمة حزمة النشر وليست Git SHA، ولم تُعامل على أنها commit أو blob SHA.

### Production migrations

| Version | Name | الدلالة |
|---|---|---|
| `20261025154530` | `start_loading_vehicle_context_guard_20261025` | يمنع دخول حالة Loading بلا سياق مركبة/VAN صالح. |
| `20261025160441` | `start_runsheet_loading_vehicle_selection` | يضيف مسار إسناد مركبة ذريًا ثم يستدعي عقد بدء التحميل المركزي. |

### Security / company isolation

- قراءة المركبات في الواجهة يجب أن تُقيّد بـ`currentUser.company_id`.
- سياسة Production `vehicles_select_company` تقيّد القراءة بشركة المستخدم المصادق عليه.
- Edge `start-loading` يتطلب Authorization صالحًا ويستخرج المستخدم من JWT، ثم يقرأ سجل `public.users` عبر `auth_id` ويستمد `company_id` من سجل المستخدم؛ لا تقبل الواجهة إرسال `company_id` باعتباره مصدر حقيقة.
- RPC الجديد غير ممنوح لـ`anon` أو `authenticated`، ومتاح لـ`service_role`؛ الاستدعاء يتم عبر Edge بعد التحقق من الهوية والسياق.
- اختيار مركبة من شركة أخرى أو مركبة غير نشطة أو لا تدعم المخزون المتنقل يجب أن يُرفض من الخلفية حتى لو حاول العميل تجاوز الواجهة.

---

## 4. تجربة المستخدم المطلوبة — الترتيب الصحيح

1. يفتح المستخدم رانشيت حالته `Picked` ويعاين الأصناف والكميات كالمعتاد.
2. يضغط على زر **«بدء التحميل»**.
3. لا تُرسل الواجهة طلب `start-loading` في هذه اللحظة.
4. يظهر **في أعلى صفحة الرانشيت** صندوق واضح لاختيار المركبة، قبل تفاصيل الأصناف، مع قائمة المركبات النشطة التي تدعم المخزون المتنقل ضمن الشركة الحالية.
5. تظهر أزرار **«تأكيد المركبة وبدء التحميل»** و**«إلغاء الاختيار»**.
6. لا يبدأ التحميل ولا تتغير حالة الرانشيت قبل اختيار مركبة والضغط على التأكيد.
7. عند التأكيد، ترسل الواجهة `{ runsheet_code, vehicle_id }` إلى `start-loading`.
8. بعد النجاح، تعيد الواجهة فتح الرانشيت في جلسة التحميل النشطة، وتعرض واجهة إدخال الكميات الحالية كما هي.
9. عند الفشل، تعرض رسالة واضحة وتبقي المستخدم في السياق نفسه، دون إخفاء السبب أو إنشاء حالة جزئية.
10. لا تتغير كميات المخزون لمجرد اختيار المركبة أو بدء جلسة التحميل؛ حركة المخزون الفعلية تبقى ضمن عقد إكمال التحميل المركزي.

**مهم:** لا يوضع حقل المركبة في معاينة الرانشيت قبل الضغط على «بدء التحميل». ظهوره في أعلى الصفحة هو استجابة مباشرة لذلك الضغط، وهذا هو التعديل المطلوب من المالك.

---

## 5. التعديل الجراحي المصدرّي الجاهز للمالك

الملف المستهدف والمحظور تعديله مباشرةً من هذه المهمة:

`papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/loader.html`

SHA الذي تمت مراجعته: `6bc6ad2ee93396faca20576241ad3318679171ef`.

**هذه تغييرات مقترحة للمالك وليست ادعاءً بأنها طُبقت على الملف المنشور.** قبل التطبيق، يعاد جلب الملف والتأكد من بقاء SHA كما هو؛ إذا تغير، تُعاد مواءمة الـpatch مع النص الحالي.

### Patch A — إضافة دالة تحميل المركبات

**محدد الإدراج:** قبل `_startLoadingFromPreview: function(code)` مباشرة.

أدرج:

```javascript
    _loadEligibleVehicles: function(callback) {
        var companyId = this.currentUser && this.currentUser.company_id;

        if (!companyId) {
            callback(null, 'تعذر تحديد الشركة الحالية؛ لم يتم تحميل المركبات.');
            return;
        }

        supabase.from('vehicles')
            .select('id,vehicle_code,model,license_plate,status,mobile_stock_enabled,mobile_branch_id')
            .eq('company_id', companyId)
            .eq('status', 'Active')
            .eq('mobile_stock_enabled', true)
            .order('vehicle_code', { ascending: true })
            .then(function(res) {
                if (res.error) {
                    callback(null, 'تعذر تحميل المركبات: ' + res.error.message);
                    return;
                }
                callback(res.data || [], null);
            })
            .catch(function(err) {
                callback(null, 'تعذر تحميل المركبات: ' +
                    (err && err.message || 'خطأ غير معروف'));
            });
    },
```

### Patch B — استبدال `_startLoadingFromPreview` كاملة

**محدد البحث:** `_startLoadingFromPreview: function(code) {`

استبدل الدالة فقط بالنص التالي. هذا التغيير يُظهر الاختيار أعلى الصفحة بعد الضغط على الزر، ويمنع استدعاء Edge حتى التأكيد:

```javascript
    _startLoadingFromPreview: function(code) {
        var self = this;
        var root = RW_UI.byId('mainContent');
        var existing = RW_UI.byId('loaderVehicleSelectionPanel');

        if (!navigator.onLine) {
            RW_UI.toast('أنت غير متصل', 'warning');
            return;
        }

        if (!root) {
            RW_UI.toast('تعذر عرض اختيار المركبة', 'error');
            return;
        }

        if (existing) {
            existing.scrollIntoView({ behavior: 'smooth', block: 'start' });
            return;
        }

        var startButton = RW_UI.byId('loaderPreviewStart');
        if (startButton) startButton.disabled = true;

        RW_UI.showLoader();
        this._loadEligibleVehicles(function(vehicles, err) {
            RW_UI.hideLoader();

            if (err) {
                if (startButton) startButton.disabled = false;
                RW_UI.showError(err);
                return;
            }

            if (!vehicles || !vehicles.length) {
                if (startButton) startButton.disabled = false;
                RW_UI.showError('لا توجد مركبة نشطة تدعم المخزون المتنقل ضمن الشركة الحالية.');
                return;
            }

            function esc(value) {
                return String(value == null ? '' : value)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;')
                    .replace(/'/g, '&#39;');
            }

            var html = '<section id="loaderVehicleSelectionPanel" ' +
                'class="card border-2 border-orange-200 bg-orange-50 mb-5 slide-in" ' +
                'aria-labelledby="loaderVehicleSelectionTitle">';
            html += '<div class="flex items-start gap-3">';
            html += '<div class="w-11 h-11 rounded-2xl bg-white text-orange-600 ' +
                'flex items-center justify-center shadow-sm shrink-0">' +
                '<i class="fa-solid fa-truck text-lg"></i></div>';
            html += '<div class="min-w-0 flex-1">';
            html += '<h3 id="loaderVehicleSelectionTitle" ' +
                'class="font-black text-lg text-slate-800">اختيار مركبة التحميل</h3>';
            html += '<p class="text-sm text-slate-600 mt-1">اختر المركبة التي ستستلم مخزون هذا الرانشيت. ' +
                'لن يبدأ التحميل قبل تأكيد الاختيار.</p></div></div>';
            html += '<label for="loaderVehicleSelect" ' +
                'class="block text-sm font-bold text-slate-700 mt-4 mb-2">المركبة</label>';
            html += '<select id="loaderVehicleSelect" ' +
                'class="w-full p-3 bg-white rounded-xl border-2 border-orange-200 ' +
                'focus:border-orange-500 outline-none font-bold">';
            html += '<option value="">— اختر المركبة —</option>';

            for (var i = 0; i < vehicles.length; i++) {
                var v = vehicles[i];
                var label = (v.vehicle_code || 'مركبة') +
                    (v.license_plate ? ' — ' + v.license_plate : '') +
                    (v.model ? ' — ' + v.model : '');
                html += '<option value="' + esc(v.id) + '">' + esc(label) + '</option>';
            }

            html += '</select>';
            html += '<p class="text-xs text-slate-500 mt-2">سيُتحقق الخادم مرة أخرى من الشركة، ' +
                'وحالة المركبة، وفرع VAN قبل بدء دورة التحميل.</p>';
            html += '<div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mt-4">';
            html += '<button type="button" id="loaderConfirmVehicleStart" class="btn-primary">' +
                '<i class="fa-solid fa-play ml-2"></i> تأكيد المركبة وبدء التحميل</button>';
            html += '<button type="button" id="loaderCancelVehicleSelection" ' +
                'class="w-full rounded-xl border border-slate-200 bg-white py-3 font-bold text-slate-600">' +
                'إلغاء الاختيار</button></div></section>';

            var wrapper = document.createElement('div');
            wrapper.innerHTML = html;
            var panel = wrapper.firstElementChild;
            root.insertBefore(panel, root.firstChild);
            panel.scrollIntoView({ behavior: 'smooth', block: 'start' });

            var confirmButton = RW_UI.byId('loaderConfirmVehicleStart');
            var cancelButton = RW_UI.byId('loaderCancelVehicleSelection');
            var vehicleSelect = RW_UI.byId('loaderVehicleSelect');

            if (confirmButton) {
                confirmButton.addEventListener('click', function() {
                    var vehicleId = vehicleSelect && vehicleSelect.value;
                    if (!vehicleId) {
                        RW_UI.toast('اختر المركبة أولاً قبل بدء التحميل', 'warning');
                        if (vehicleSelect) vehicleSelect.focus();
                        return;
                    }

                    confirmButton.disabled = true;
                    confirmButton.innerHTML =
                        '<i class="fa-solid fa-spinner fa-spin ml-2"></i> جارٍ بدء التحميل...';
                    if (cancelButton) cancelButton.disabled = true;
                    self.startLoading(code, vehicleId);
                });
            }

            if (cancelButton) {
                cancelButton.addEventListener('click', function() {
                    panel.remove();
                    if (startButton) startButton.disabled = false;
                });
            }
        });
    },
```

### Patch C — تعديل عقد استدعاء الواجهة `startLoading`

**محدد البحث:** `startLoading: function(code) {`

استبدل الدالة كاملة:

```javascript
    startLoading: function(code, vehicleId) {
        var self = this;

        if (!navigator.onLine) {
            RW_UI.toast('أنت غير متصل', 'warning');
            return;
        }

        if (!vehicleId) {
            RW_UI.toast('اختر المركبة أولاً قبل بدء التحميل', 'warning');
            var confirmButton = RW_UI.byId('loaderConfirmVehicleStart');
            if (confirmButton) confirmButton.disabled = false;
            return;
        }

        RW_UI.showLoader();
        RW_API.call('start-loading', {
            runsheet_code: code,
            vehicle_id: vehicleId
        }, function(json) {
            RW_UI.hideLoader();

            if (json && json.success) {
                RW_UI.toast('تم إسناد المركبة وبدء التحميل بنجاح', 'success');
                self.openRunsheet(code);
                return;
            }

            var message = (json && json.msg) || 'فشل بدء التحميل';
            RW_UI.showError(message);

            var confirmButton = RW_UI.byId('loaderConfirmVehicleStart');
            var cancelButton = RW_UI.byId('loaderCancelVehicleSelection');
            if (confirmButton) {
                confirmButton.disabled = false;
                confirmButton.innerHTML =
                    '<i class="fa-solid fa-play ml-2"></i> تأكيد المركبة وبدء التحميل';
            }
            if (cancelButton) cancelButton.disabled = false;
        });
    },
```

### لماذا هذا الـpatch يطابق المطلوب؟

- لا يظهر الاختيار إلا بعد ضغط «بدء التحميل».
- يُدرج الصندوق في بداية `mainContent`، أي أعلى صفحة الرانشيت.
- تبقى معاينة الرانشيت والأصناف ظاهرة أسفل الصندوق.
- لا يُرسل HTTP request قبل اختيار المركبة وتأكيدها.
- تُقيد قائمة المركبات بالشركة الحالية وبالمركبات النشطة التي تدعم المخزون المتنقل.
- يبقى التحقق النهائي في Production SQL؛ لا تُعتبر قيود الواجهة بديلًا عن التحقق الخلفي.
- يُرسل `vehicle_id` إلى Edge v6 الموجود بالفعل.
- لا توجد حركة مخزون من مجرد إظهار القائمة أو اختيار مركبة.

---

## 6. تحذير Tailwind في Console

الرسالة:

`cdn.tailwindcss.com should not be used in production`

هي **تحذير نشر/أداء** منفصل عن خطأ HTTP 400. ليست سبب رفض بدء التحميل. لا يجوز حذف:

`<script src="https://cdn.tailwindcss.com"></script>`

على نحو منفرد، لأن الملف يستخدم Tailwind utility classes في معظم الواجهة؛ حذفه دون CSS بديل مبني سيكسر التصميم.

المعالجة الصحيحة على مستوى الإنتاج هي إعداد Tailwind build output ثابتًا (CLI أو PostCSS ضمن pipeline المشروع)، والتأكد من أن جميع الأصناف المستخدمة في HTML مشمولة في الناتج، ثم نشر CSS واختبار الواجهة بصريًا ووظيفيًا قبل إزالة CDN. هذا تغيير في build/deployment pipeline وليس جزءًا من patch اختيار المركبة، ولا يوجد دليل هنا على أن مستودع الواجهة لديه pipeline جاهز يمكن استخدامه مباشرة. لذلك الحالة الحالية للتحذير: `KNOWN / NOT FIXED IN THIS UI PATCH`؛ لا يُسجّل باعتباره سبب خطأ التحميل.

أما `/favicon.ico 404` فهو طلب أصل منفصل لا يفسر فشل بدء التحميل؛ لم تُجرَ تغييرات على الأيقونات ضمن هذه المهمة.

---

## 7. خطة الاختبار بعد تطبيق المالك للـpatch

هذه حالات مطلوبة وليست نتائج مدعاة:

1. **قبل الضغط على «بدء التحميل»:** لا يوجد حقل مركبة في أعلى الصفحة.
2. **بعد الضغط على «بدء التحميل»:** يظهر صندوق اختيار المركبة أعلى الصفحة، وتظل معاينة الرانشيت تحته.
3. **إلغاء الاختيار:** يختفي الصندوق وتعود إمكانية الضغط على «بدء التحميل»، ولا يُستدعى Edge.
4. **قائمة فارغة أو خطأ RLS/شبكة:** تظهر رسالة واضحة، ولا تتغير حالة الرانشيت.
5. **من دون اختيار:** يمنع زر التأكيد إرسال الطلب.
6. **مركبة صحيحة من الشركة نفسها:** يرسل payload يحتوي `runsheet_code` و`vehicle_id`، ثم يفتح جلسة التحميل بعد استجابة النجاح.
7. **مركبة من شركة أخرى أو غير نشطة أو `mobile_stock_enabled=false`:** ترفضها قاعدة البيانات، وتبقى حالة الرانشيت كما كانت.
8. **فرع VAN غير صالح أو غير نشط:** ترفض العملية ذريًا ولا يبقى إسناد جزئي.
9. **مركبة مستخدمة في رانشيت آخر بحالة Loading:** يرفض العقد الخلفي التداخل.
10. **ضغط مزدوج / إعادة محاولة:** لا ينشأ أكثر من loading cycle للرانشيت نفسه؛ تحقق من سلوك الحالة في SQL وHTTP.
11. **Baseline المخزون:** اختيار المركبة وبدء دورة التحميل لا يغيّران `stock_branches.qty` أو `allocated_qty` ولا ينشئان `inventory_log` movement؛ الحركة الفعلية تبقى في `complete-loading → post_stock_movement`.
12. **Production HTTP E2E:** بعد تطبيق الواجهة، نفّذ اختبارًا مصادقًا عليه باستخدام fixture معزول مصرح به، ثم تحقق من الاستجابة والحالة وحركة المخزون المتوقعة واستعادة baseline.
13. **Deployment:** تحقق من HTML الذي يخدمه Cloudflare مباشرةً؛ commit Git وحده لا يثبت النشر.
14. **Static validation:** افحص JavaScript الكامل للملف بعد دمج patch، لا المقاطع وحدها، ثم نفذ اختبار المتصفح على الهاتف وسطح المكتب.

---

## 8. سجل التغييرات والحوكمة

| البند | الحالة الحالية المثبتة |
|---|---|
| Production migration الخاصة بحارس سياق المركبة | موجودة في سجل Production تحت `20261025154530`. |
| Production migration الخاصة باختيار المركبة | موجودة في سجل Production تحت `20261025160441`. |
| Production Edge `start-loading` | `v6 ACTIVE / verify_jwt=true`. |
| مطابقة مصدر Edge Current/Production | تطابق نصي كامل في الفحص المباشر الحالي. |
| `loader.html` في `erp-frontend` | لم يُعدّل امتثالًا لسياسة المهمة؛ المطلوب patch يطبقه المالك. |
| `main.html` و`picker.html` و`core.js` | لم تُعدّل. |
| حركة مخزون أو تعديل رانشيت تشغيلي | لم تُنفذ ضمن هذا التعديل التوثيقي. |
| Cloudflare HTML deploy identity | UNKNOWN. |
| واجهة الاختيار بعد ضغط الزر | PATCH READY / NOT APPLIED. |
| HTTP E2E من الواجهة بعد patch | UNVERIFIED. |
| تحذير Tailwind | معروف ومستقل؛ لم يُعالج ضمن patch الواجهة. |

### التراجع

إذا طُبق patch الواجهة وظهر خلل:
1. استعد المقاطع الأصلية الثلاثة فقط (`_startLoadingFromPreview`, `startLoading`) واحذف دالة `_loadEligibleVehicles` الجديدة.
2. لا تتراجع عن حماية Production أو Migration الجديدة لإصلاح خطأ واجهة؛ هذه الحماية تمنع إنشاء جلسة تحميل غير صالحة.
3. لا تجرِ أي تغيير مخزني يدوي للتراجع؛ لا يُفترض أن اختيار المركبة وحده أحدث حركة مخزون.

---

## 9. SELF-AUDIT FINAL

### What I Proved
- سبب HTTP 400 هو غياب اختيار المركبة من مسار الواجهة وغياب `vehicle_id` عن payload.
- رفض قاعدة البيانات لبدء تحميل بلا مركبة هو guard صحيح.
- Production `start-loading` حاليًا v6 و`ACTIVE` و`verify_jwt=true`.
- مصدر `Current/Edge_Functions/start-loading` يطابق نص مصدر Production في القراءة المباشرة.
- Production سجل migration الخاصة بحارس المركبة ومسار الاختيار الذري.
- سياسة المهمة تمنع تعديل Loader مباشرةً، وتطلب patch مصدرّيًا جاهزًا للمالك.

### What I Did Not Prove
- لم أثبت تطبيق الـpatch على Loader المنشور.
- لم أثبت أن Cloudflare يخدم بصمة HTML معينة.
- لم أنفذ HTTP E2E ناجحًا من الواجهة بعد تطبيق الـpatch.
- لم أعالج تحذير Tailwind أو أختبر build pipeline له.
- لم أختبر هذه الواجهة على fixture إنتاجي معزول في هذه الجلسة.

### What I Fixed
- صححت **خطة الإصلاح المصدرّي** بحيث يظهر حقل المركبة بعد ضغط «بدء التحميل» في أعلى الصفحة، وليس في معاينة الرانشيت قبل الضغط.
- وثقت الربط الدقيق بين UI payload وEdge v6 وRPC الخلفي الحالي.
- فصلت تحذير Tailwind عن سبب HTTP 400 ومنعت علاجًا قد يكسر التنسيق.

### What I Initially Missed
- التصميم السابق وضع اختيار المركبة في معاينة الرانشيت قبل الضغط على «بدء التحميل»، وهو مخالف لتوجيه المستخدم الحالي. تم تصحيح ترتيب التفاعل في هذا التقرير.

### What Could Still Be Wrong
- قد يختلف مصدر Loader أو سياسة النشر بعد هذه القراءة؛ يجب إعادة التحقق من SHA قبل تطبيق patch.
- قد تتغير صلاحيات قراءة المركبات أو RLS في Production.
- قد يحتاج التطبيق إلى مواءمة بسيطة إذا تغيرت أسماء العناصر أو دوال الواجهة منذ SHA الذي تمت مراجعته.
- يبقى التحذير الخاص بـTailwind حتى إعداد build pipeline واختباره ونشره.

**Final Confidence:** مرتفعة في تشخيص عقد بدء التحميل وفي مطابقة Edge الحالية؛ متوسطة في patch الواجهة إلى أن يدمجه المالك ويختبر الملف كاملًا.  
**Final Closure Status:** `BACKEND VERIFIED / OWNER PATCH READY / UI NOT APPLIED / E2E OPEN / NOT CLOSED`.

## 10. الخطوة التنفيذية التالية

1. أعد جلب Loader من `erp-frontend/main` وتحقق من أن SHA ما زال `6bc6ad2ee93396faca20576241ad3318679171ef`.
2. طبّق Patches A–C فقط في `companies/company-1/warehouse/loader.html`.
3. افحص JavaScript الكامل، ثم اختبر الحالات المذكورة في القسم 7.
4. انشر الواجهة وتحقق من HTML المقدم فعليًا من Cloudflare.
5. نفّذ HTTP E2E مصادقًا عليه على fixture معزول، وأثبت عدم وجود أثر مخزني قبل الإكمال واستعادة baseline بعد الاختبار.
6. حدّث هذا التقرير و`CURRENT_STATE.md` فقط بالأدلة الجديدة؛ لا تعلن الإغلاق الكامل قبل نجاح الخطوات السابقة.
