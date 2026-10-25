# تقرير التحقيق والتنفيذ — اختيار المركبة قبل بدء التحميل

**رقم الحدث:** LVE-2026-10-25-494  
**التاريخ:** 2026-10-25  
**المشروع:** RAWAEA ERP / Supabase Production `fiilmooggumokxanwiyx`  
**النطاق:** `loader.html → start-loading → start_runsheet_loading → runsheets / vehicles / VAN branch`  
**الحالة:** `BACKEND FIX DEPLOYED + VERIFIED / OWNER-ONLY HTML PATCH PREPARED / FULL E2E OPEN`

---

## 1. PRE-CHANGE SELF-AUDIT

| المجال | الحكم | الدليل المباشر |
|---|---|---|
| فهم المشكلة التشغيلية | CONFIRMED | Console يعرض HTTP 400 من `start-loading` برسالة اشتراط إسناد مركبة. |
| Production Edge قبل التغيير | CONFIRMED | Supabase live: `start-loading v5`, ACTIVE, `verify_jwt=true`, digest `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7`. |
| Production SQL قبل التغيير | CONFIRMED | تعريف `start_runsheet_loading(uuid,text,text)` يرفض `runsheets.vehicle_id IS NULL`. |
| مصدر الواجهة التشغيلي | CONFIRMED | `erp-frontend/companies/company-1/warehouse/loader.html`, blob SHA `6bc6ad2ee93396faca20576241ad3318679171ef`. |
| التطبيق المرجعي | CONFIRMED | `erp-frontend/companies/company-1/warehouse/picker.html`, blob SHA `d483bd15b36585b975b63c2ef641481a01d5d084`. |
| Core | CONFIRMED | `erp-frontend/companies/company-1/core.js`, blob SHA `ff2f581d9900543c16f7cb026e13446520c0329d`. |
| صلاحيات قراءة المركبات | CONFIRMED | Production policy `vehicles_select_company` تقصر القراءة على `app_private.current_user_company_id()`. |
| HTML deployment identity | UNKNOWN | لا يوجد في الأدلة التي جُمعت إثبات مباشر لبصمة HTML التي يقدمها Cloudflare. |
| Successful authenticated HTTP E2E | OPEN | الواجهة التشغيلية المستهدفة لم تُعدّل مباشرةً لأن `writing-block.md` يحظر ذلك صراحةً ويحدد أن المالك يطبق patch الواجهة. |

### مصادر تمت مراجعتها

- `doc/Draft/Reprots/writing-block.md` كاملًا، بما فيه المهمة التنفيذية في نهاية الوثيقة.
- تقرير `Report493_LOADING_CONTEXT_VEHICLE_ASSIGNMENT_FORENSIC_20261025.md` والحالة السابقة في `CURRENT_STATE.md`.
- Loader وPicker وCore من مستودع `erp-frontend`.
- Production Edge `start-loading` قبل النشر وبعده.
- Production SQL definitions لـ `start_runsheet_loading` والدالة الجديدة.
- Production schema وRLS policy وACL للدوال.
- Production migration registry.

---

## 2. ما أثبته التحقيق — السبب الجذري

### 2.1 الواجهة لا ترسل المركبة

في `companies/company-1/warehouse/loader.html`، الدالة الحالية عند السطر التقريبي 561:

```javascript
startLoading: function(code) {
    var self = this; if(!navigator.onLine) { RW_UI.toast('أنت غير متصل','warning'); return; }
    RW_UI.showLoader(); RW_API.call('start-loading',{runsheet_code:code},function(json) { RW_UI.hideLoader();
        if(json.success) { RW_UI.toast('تم بنجاح','success'); self.openRunsheet(code); }
        else { if(json.msg&&json.msg.indexOf('لديك بالفعل')!==-1) Swal.fire({title:'تنبيه',text:json.msg,icon:'info',customClass:{popup:'!rounded-3xl'}}); else RW_UI.showError(json.msg||'فشل'); self.renderPendingTab(); }
    });
},
```

الـpayload يحتوي `runsheet_code` فقط؛ لا يوجد `vehicle_id` ولا حقل اختيار مركبة في معاينة الرانشيت.

### 2.2 Production Edge كان يستدعي عقدًا لا يستطيع إسناد المركبة

النسخة الحية السابقة `start-loading v5` استخرجت هوية المستخدم وسياق الشركة، ثم استدعت فقط:

```typescript
supabase.rpc("start_runsheet_loading", {
  p_company_id: pubUser.company_id,
  p_runsheet_code: body.runsheet_code,
  p_user_email: pubUser.email || user.email,
})
```

### 2.3 قاعدة البيانات كانت تمنع الانتقال غير الصالح — وهذا صحيح

Production `start_runsheet_loading` يرفض الرانشيت إذا كان `vehicle_id IS NULL`، ثم يتحقق من نشاط المركبة ومن `mobile_stock_enabled` وصحة فرع VAN. لذلك فإن HTTP 400 ليس خطأً شكليًا في Console؛ بل رفض صحيح من قاعدة البيانات لمسار واجهة لا يرسل اختيار المركبة.

**التمييز عن تقرير LVE-493:** إصلاح الحماية المركزية السابق كان صحيحًا ويجب الإبقاء عليه. المطلوب الآن هو توفير مسار آمن لاختيار المركبة وربطها بالرانشيت قبل بدء التحميل، لا إزالة الحماية أو تجاوزها.

### 2.4 تحذير Tailwind

رسالة `cdn.tailwindcss.com should not be used in production` تحذير بناء/أداء مستقل وليست سبب HTTP 400. إزالة CDN وحدها من ملف يعتمد على Tailwind utility classes ستكسر التنسيق ما لم يوجد بديل CSS مبني ومختبر؛ لذلك لم أحذفها كحل تجميلي غير آمن.

---

## 3. التغيير الخلفي المنفذ

### 3.1 Migration canonical

- الملف: `supabase/migrations/20261025_start_runsheet_loading_vehicle_selection.sql`
- Git blob SHA: `4e5421c1e5eaa0a50f33b48f49fdc7ea0d4a4f2e`
- Commit: `f7607a44ddd8a5f87f2740ed9e13d408e92bfb3a`
- Production migration registry: `20261025160441 / start_runsheet_loading_vehicle_selection`
- تطبيق Migration: SUCCESS.

أُنشئت الدالة `public.start_runsheet_loading_with_vehicle(uuid,text,text,uuid)`. تقوم داخل معاملة واحدة بـ:
1. التحقق من اكتمال الشركة والرانشيت والمستخدم والمركبة.
2. قفل المركبة المختارة والتحقق من أنها نشطة، ضمن الشركة نفسها، ومفعّل لها `mobile_stock_enabled`.
3. قفل الرانشيت والتحقق من أن حالته `Picked`.
4. إسناد `vehicle_id` للرانشيت.
5. استدعاء `start_runsheet_loading` المعتمدة لإكمال جميع حواجز دورة التحميل، بما فيها صحة فرع VAN ومنع استخدام مركبة مشغولة.
6. إعادة `vehicle_id` في النتيجة.

أي فشل في الدالة الأساسية يلغي إسناد المركبة ضمن المعاملة نفسها؛ لا يبقى ربط جزئي.

### 3.2 ACL

التحقق المباشر بعد النشر:

| الدور | EXECUTE |
|---|---|
| `anon` | false |
| `authenticated` | false |
| `service_role` | true |

هذا يتسق مع سلسلة الاستدعاء الحالية: واجهة مصادق عليها → Edge مع JWT → تحقق المستخدم والشركة → RPC بواسطة `service_role`.

### 3.3 Edge Function Production

تم نشر `start-loading` من المصدر الحي مع المحافظة على التحقق من JWT:

| الحقل | قبل | بعد |
|---|---:|---:|
| Version | 5 | **6** |
| Status | ACTIVE | **ACTIVE** |
| verify_jwt | true | **true** |
| ezbr_sha256 | `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7` | **`b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1`** |

يدعم v6 الآن `body.vehicle_id`. إذا أُرسلت المركبة، يستدعي `start_runsheet_loading_with_vehicle`؛ وإذا لم تُرسل، يحافظ على عقد الاستدعاء القديم، والذي سيظل يرفض الرانشيت غير المسند بدل تجاوز الحماية.

### 3.4 Current artifact

- المسار: `Current/Edge_Functions/start-loading`
- Git blob SHA: `5fc6b01826ad098d6621d7f80ea8efb4eba8d5a0`
- Commit: `d7296c615dc0b58d35e99fceee35690cad8a1c66`

الـ`ezbr_sha256` خاص بحزمة النشر، وليس Git SHA؛ لم أساوِ بينهما.

---

## 4. التعديل الجراحي المطلوب من المالك — لم أعدّل HTML مباشرة

الوثيقة التنفيذية `writing-block.md` تمنع تعديل `companies/company-1/warehouse/loader.html` مباشرةً وتطلب تقديم patch جاهز للمالك. لذلك هذا القسم هو patch قابل للتطبيق، وليس ادعاءً بأن الواجهة قد نُشرت.

### Patch 1 — تحميل المركبات قبل عرض معاينة الرانشيت

**الملف:** `erp-frontend/companies/company-1/warehouse/loader.html`  
**محدد البحث:** `if (rs.status === 'Picked') {` داخل `openRunsheet`، قرب السطر 193.

**استبدل هذا المقطع:**

```javascript
if (rs.status === 'Picked') {
    self._showPreviewModal(code, rs, items);
    return;
}
```

**بهذا المقطع:**

```javascript
if (rs.status === 'Picked') {
    self._loadEligibleVehicles(function(vehicles, err) {
        if (err) {
            console.error('Loader eligible vehicles error:', err);
            RW_UI.toast(err, 'error');
            return;
        }
        self._showPreviewModal(code, rs, items, vehicles);
    });
    return;
}
```

### Patch 2 — إضافة دالة قراءة المركبات المسموح بها

**محدد الإدراج:** مباشرة قبل `_showPreviewModal: function(code, rs, items) {` قرب السطر 315.

**أدرج الدالة التالية كاملة:**

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
            callback(null, 'تعذر تحميل المركبات: ' + (err && err.message || 'خطأ غير معروف'));
        });
},
```

هذه القراءة مقيدة بـ`company_id`، وتستخدم سياسة Production الحالية `vehicles_select_company`. لا تعتمد على قائمة مركبات غير مقيدة بالشركة.

### Patch 3 — تمرير قائمة المركبات إلى المعاينة

**محدد البحث:** `_showPreviewModal: function(code, rs, items) {` قرب السطر 315.

**استبدل سطر التوقيع فقط بـ:**

```javascript
_showPreviewModal: function(code, rs, items, vehicles) {
```

ثم داخل الدالة، بعد هذا السطر الفريد الذي يعرض حالة الرانشيت:

```javascript
h += '<span class="px-3 py-1 rounded-full bg-white text-orange-600 text-xs font-bold">جاهز</span></div></div>';
```

**أدرج مباشرة بعده:**

```javascript
h += '<div class="card border border-orange-100 bg-orange-50 mb-5">';
h += '<label for="loaderVehicleSelect" class="block font-black text-slate-800 mb-2"><i class="fa-solid fa-truck ml-2 text-orange-600"></i>المركبة المخصصة لهذا التحميل</label>';
h += '<select id="loaderVehicleSelect" class="w-full p-3 bg-white rounded-xl border-2 border-orange-100 outline-none font-bold">';
h += '<option value="">— اختر المركبة قبل بدء التحميل —</option>';

vehicles = vehicles || [];
for (var vi = 0; vi < vehicles.length; vi++) {
    var vehicle = vehicles[vi];
    var vehicleLabel = (vehicle.vehicle_code || 'مركبة') +
        (vehicle.license_plate ? ' — ' + vehicle.license_plate : '') +
        (vehicle.model ? ' — ' + vehicle.model : '');
    h += '<option value="' + esc(vehicle.id) + '"' +
        (rs.vehicle_id === vehicle.id ? ' selected' : '') + '>' +
        esc(vehicleLabel) + '</option>';
}

h += '</select>';
h += '<p class="text-xs text-slate-500 mt-2">لن يبدأ التحميل إلا بعد التحقق من المركبة وفرع مخزونها وربطها بالرانشيت.</p>';
h += '</div>';
```

بهذا يظهر الاختيار في أعلى معاينة الرانشيت، قبل تفاصيل الأصناف وزر بدء التحميل.

### Patch 4 — عدم بدء التحميل دون اختيار

**محدد البحث:** `_startLoadingFromPreview: function(code) {` قرب السطر 522.

**استبدل الدالة كاملة:**

```javascript
_startLoadingFromPreview: function(code) {
    var vehicleSelect = RW_UI.byId('loaderVehicleSelect');
    var vehicleId = vehicleSelect && vehicleSelect.value;

    if (!vehicleId) {
        RW_UI.toast('اختر المركبة أولاً قبل بدء التحميل', 'warning');
        return;
    }

    Swal.close();
    this.startLoading(code, vehicleId);
},
```

### Patch 5 — إرسال هوية المركبة إلى Edge

**محدد البحث:** `startLoading: function(code) {` قرب السطر 561.

**استبدل الدالة كاملة:**

```javascript
startLoading: function(code, vehicleId) {
    var self = this;

    if (!navigator.onLine) {
        RW_UI.toast('أنت غير متصل', 'warning');
        return;
    }

    if (!vehicleId) {
        RW_UI.toast('اختر المركبة أولاً قبل بدء التحميل', 'warning');
        return;
    }

    RW_UI.showLoader();
    RW_API.call('start-loading', {
        runsheet_code: code,
        vehicle_id: vehicleId
    }, function(json) {
        RW_UI.hideLoader();

        if (json.success) {
            RW_UI.toast('تم بنجاح', 'success');
            self.openRunsheet(code);
        } else {
            if (json.msg && json.msg.indexOf('لديك بالفعل') !== -1) {
                Swal.fire({
                    title: 'تنبيه',
                    text: json.msg,
                    icon: 'info',
                    customClass: { popup: '!rounded-3xl' }
                });
            } else {
                RW_UI.showError(json.msg || 'فشل');
            }
            self.renderPendingTab();
        }
    });
},
```

---

## 5. اختبارات ما بعد تطبيق Patch الواجهة

هذه اختبارات مطلوبة، وليست نتائج مدعاة:

1. **بدون اختيار مركبة:** يجب أن تمنع الواجهة الاستدعاء وتعرض رسالة واضحة.
2. **مركبة نشطة من الشركة نفسها ويدعمها المخزون المتنقل:** يجب أن تُرسل `vehicle_id` إلى Edge وتعود نتيجة بدء ناجحة.
3. **مركبة غير نشطة أو `mobile_stock_enabled=false`:** يجب أن ترفضها قاعدة البيانات.
4. **مركبة من شركة أخرى:** يجب أن ترفضها الدالة بسبب `company_id`، دون تعديل الرانشيت.
5. **فرع VAN غير صالح:** يجب أن يرفضه `start_runsheet_loading` وتُلغى معاملة الإسناد بالكامل.
6. **المركبة مستخدمة في رانشيت آخر بحالة Loading:** يجب رفض المحاولة وعدم ترك تغيير جزئي.
7. **إعادة النقر أو إعادة إرسال الطلب بعد بدء التحميل:** يجب أن ترفض حالة الرانشيت غير `Picked` دون إنشاء دورة تحميل ثانية.
8. **Baseline:** لا يجب أن يتغير `qty` أو `allocated_qty` أو `inventory_log` عند مجرد بدء التحميل؛ الحركة الفعلية تبقى في عقد `complete-loading → post_stock_movement`.
9. **E2E حقيقي:** بعد نشر HTML، تنفيذ start → complete عبر HTTP مصادق عليه ببيانات اختبار معزولة، ثم التحقق من حركة واحدة صحيحة واستعادة baseline.
10. **Deployment:** التحقق من أن Cloudflare يقدم HTML المحدث فعليًا؛ Git commit وحده لا يثبت نشر الواجهة.

---

## 6. سجل التغييرات والحوكمة

| الحدث | النتيجة |
|---|---|
| Production migration | منفذة ومسجلة تحت `20261025160441`. |
| Production Edge | `start-loading v6 ACTIVE / verify_jwt=true`. |
| Current Edge artifact | أُنشئ في المسار الرسمي المذكور أعلاه. |
| HTML الهدف `erp-frontend/.../loader.html` | لم يُعدّل امتثالًا لمنع التعديل المباشر الوارد في المهمة. |
| مرآة تاريخية `rawaie-erp-review/PWA/warehouse/loader.html` | جرت محاولة تعديل ثم أُعيدت فورًا إلى المحتوى الأساسي؛ commit الاستعادة `b5a4a0f77c3f4835cdbd3804f36923f34379127b`، والمحتوى النهائي يطابق baseline SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`. |
| Stock baseline | لم تُنفذ حركة مخزون أو اختبار على رانشيت تشغيلي حي. |
| Cloudflare HTML deploy | UNKNOWN؛ لا يوجد إثبات نشر مباشر بعد. |

### التراجع

- Migration: لا يُنصح بحذف الدالة الجديدة بعد نشر Edge v6؛ إن لزم التراجع، أعد Edge إلى النسخة السابقة أولًا، ثم راجع الاعتماديات وACL قبل إسقاط الدالة الجديدة.
- HTML: التراجع عن Patch الواجهة هو استعادة المقاطع الخمسة الأصلية المحددة أعلاه.
- لم تُجرَ أي حركة مخزون أو تغيير على رانشيت تشغيلي في هذا التنفيذ.

---

## 7. SELF-AUDIT FINAL

### What I Proved
- سبب HTTP 400 في بدء التحميل هو عدم وجود اختيار مركبة في UI وعدم إرسال `vehicle_id`، مع وجود Guard صحيح في Production SQL.
- Production `start-loading` أصبح v6، ACTIVE، و`verify_jwt=true`، ويستدعي RPC الجديد عند وصول `vehicle_id`.
- RPC الجديد موجود في Production، وACL يسمح بالتنفيذ لـ`service_role` فقط.
- Migration مسجلة في Production، وCurrent artifact موثق في Git.

### What I Did Not Prove
- لم أثبت بعد نجاح HTTP E2E كامل باستخدام الواجهة بعد تطبيق Patch؛ الواجهة لم تُعدّل مباشرةً امتثالًا للتوجيه.
- لم أثبت أن Cloudflare يقدم HTML جديدًا.
- لم أختبر تشغيلًا ناجحًا على رانشيت إنتاج حقيقي؛ تجنبت لمس رانشيت تشغيلي دون fixture معزول.
- لم أعالج تحذير Tailwind لأنه يتطلب بديل CSS مبنيًا واختبارًا مستقلًا، وليس حذف CDN عشوائيًا.

### What I Fixed
- أضفت مسارًا خلفيًا ذريًا لاختيار المركبة وإسنادها وبدء التحميل ضمن معاملة واحدة.
- نشرت `start-loading v6` مع الحفاظ على JWT وإضافة دعم `vehicle_id`.
- حفظت مصدر Edge المنشور في `Current/Edge_Functions/start-loading`.

### What I Initially Missed
- أن `writing-block.md` يحظر تعديل ملف Loader مباشرةً ويطلب تقديم Patch للمالك. أعدت المرآة التي عدلتها إلى baseline، ولم أغيّر ملف التشغيل `erp-frontend/.../loader.html`.

### What Could Still Be Wrong
- قد تفشل قراءة المركبات من المتصفح إذا تغيّرت سياسات RLS أو لم يُنشر Patch الواجهة.
- قد تختلف الواجهة التي يخدمها Cloudflare عن Git source.
- نجاح دورة start → complete لا يزال يحتاج اختبارًا حقيقيًا مع fixture معزول.

**Final Confidence:** مرتفعة في السبب الجذري وفي نشر دعم الخلفية؛ غير كافية لإغلاق تجربة المستخدم كاملة.  
**Final Closure Status:** `PARTIAL — BACKEND DEPLOYED / OWNER HTML PATCH REQUIRED / PRODUCTION HTTP E2E OPEN`.

---

## 8. الخطوة التنفيذية التالية

طبّق Patch الواجهة أعلاه على `erp-frontend/companies/company-1/warehouse/loader.html` وفق سياسة المالك، ثم انشر الواجهة وتحقق من بصمة النشر، وبعدها نفّذ E2E مصادقًا عليه ببيانات اختبار معزولة. لا تعلن `100% CLOSED` قبل هذه الأدلة.
