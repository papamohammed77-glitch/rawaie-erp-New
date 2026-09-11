# تقرير 124 — المراجعة الجنائية وإعادة فحص Main5
## RAWAEA ERP — Main5 Orders / Runsheets Forensic Recheck — 2026-09-12

> **الهدف الحاكم — يجب قراءته أولًا:** هناك نقص شديد في كل التبويبات، وكثير منها هيكلي فقط. الهدف ليس مجرد إكمال الشاشات، بل استكمالها وظيفيًا لتصبح منافسًا حقيقيًا لـ Odoo وDynamics وSAP وDaftra وManager.io وغيرها. هذا جزء من هدف Gold/Diamond للمشروع، ولا يجوز التعامل معه كإضافات شكلية.
>
> وهذا متسق حرفيًا مع مبدأ الحوكمة: الدراسة أولًا → إعادة بناء العقد التاريخي → تتبع السلوك الحالي → تتبع البيانات والصلاحيات والتدفق → تحديد الفجوة الفعلية → التعديل الجراحي → الاختبار → التحقق من Production → التوثيق.

---

## 1. حالة الاستكمال في هذه الجلسة

هذه الجلسة استؤنفت من آخر نقطة موثقة ولم تبدأ من الصفر. تم فتح المصادر الحالية مباشرة، ولم تُعامل التقارير السابقة كحقيقة حالية.

مصادر الحوكمة التي تم فتحها كاملة حتى EOF:

- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`
- `CURRENT_STATE.md`
- `doc/Draft/Reprots/Report123_Main4_Forensic_Recheck_20260912.md`

ثم تمت مراجعة Production الحالية وGit الحالي قبل الحكم على Main5.

لم يتم تعديل:

- `Current/PWA/New-main`
- `Original/PWA/main/main5.md`
- `Current/PWA/main2/main5.md`

لأن Main5 من ملفات النظام الأم التي يدمجها المالك يدويًا وفق حدود الملكية المعتمدة.

---

## 2. Current Source of Truth

المصدر المعتمد للجزء:

`Current/PWA/main2/main5.md`

الحالة الحالية في Git عند القراءة:

- SHA: `c4518d05ada50830e819563a55169843679d3e94`
- الحجم: `75,289 bytes`
- تم الوصول إلى EOF الفعلي، وآخر سطر هو:

```javascript
window.RW_Runsheets = RW_Runsheets;
```

كما تم التحقق من أن دليل الأجزاء canonical هو:

`Current/PWA/main2/main1.md ... main11.md`

والـassembly manifest الحالي:

`forensic_main_assembly.yml`

يشير بالفعل إلى:

`source_of_truth: Current/PWA/main2`

ويمنع:

- `Current/PWA/main`
- `Current/PWA/New-main`

ولا توجد حاجة مثبتة لتعديل مسار الـassembly في هذه الجلسة.

---

## 3. ما يحتويه Main5 فعليًا

Main5 الحالي ليس مجرد واجهة واحدة؛ بل يحتوي وحدتين تشغيليتين رئيسيتين:

### `RW_Orders`

مسؤول عن:

- عرض أوردرات المبيعات.
- الفلترة.
- الفرز.
- تأكيد الأوردر.
- حذف الأوردر وفق حدود الصلاحية والحالة.
- عرض التفاصيل.
- طباعة الفاتورة.
- إنشاء رانشيت جديد للأوردرات المحددة.
- ضم أوردرات إلى رانشيت مفتوح.
- تحديث البيانات دوريًا.
- استقبال Realtime لتغييرات الأوردرات.

### `RW_Runsheets`

مسؤول عن:

- عرض الرانشيتات.
- الفلترة حسب الرقم والحالة والسائق والتاريخ.
- عرض تفاصيل الرانشيت.
- ربط/تعديل السائق والمركبة.
- حذف/إلغاء الرانشيت ضمن الحالات المسموح بها.
- تغيير حالات تشغيلية عبر Edge Functions.
- طباعة بيان الرحلة.
- Realtime لتغييرات الرانشيتات وبياناتها المرتبطة.

لا يوجد نص `(قيد التطوير)` في المصدر الحالي وفق القراءة المباشرة، لكن غياب العبارة لا يساوي Gold/Diamond completion.

---

## 4. Historical Reconstruction

تم فتح النسخة التاريخية:

`Original/PWA/main/main5.md`

الغرض كان فهم المسؤولية الأصلية، وليس إعادة الكود القديم لمجرد الاختلاف.

التطابق الوظيفي الأساسي بين التاريخي والحالي يثبت أن Main5 كان بالفعل مسؤولًا عن محور:

`Orders → Runsheets`

وأن هذا المحور جزء أساسي من دورة التشغيل الميداني وليس مجرد جدول عرض.

لذلك لم يتم تغيير Business Flow إلى نموذج عام أو تقليدي، ولم يتم إدخال Physical Stock mutation من Main5.

---

# 5. Production Contract — Orders

تم فحص Production الحالية مباشرة.

`confirm-order` — v4 — ACTIVE — JWT required.

Production تثبت أن تأكيد الأوردر:

- يستخرج Company Context من المستخدم المصادق عليه.
- يتحقق من Active user.
- يقرأ الأوردر داخل نفس الشركة.
- يمنع التأكيد إذا كان الأوردر مربوطًا برانشيت.
- يسمح فقط بحالات Draft/Pending.
- ينفذ التحديث على الأوردر نفسه داخل Company Scope.

إذًا لا يوجد مبرر لإعادة بناء lifecycle التأكيد داخل Main5.

---

# 6. Production Contract — Create Runsheet

Production `create_runsheet_atomic` موجود ويعمل كـCore transaction.

العقد المثبت:

- Company Context مطلوب.
- الأوردرات تُقفل FOR UPDATE.
- الأوردر لا يجوز أن يكون مربوطًا برانشيت سابقًا.
- الحالة المقبولة Confirmed أو Pending.
- يتم فحص Item Identity مقابل Global Item Master.
- يتم إنشاء Runsheet بحالة Open.
- يتم ربط الأوردرات بالرانشيت وتحويلها إلى Pending.
- يتم توليد `run_sheet_details` كبيانات derived aggregate من `order_details`.

كما أن `create-runsheet` Edge الحالي هو wrapper للـRPC وليس Writerًا موازيًا.

**القرار:** لا يتم إعادة بناء Create Runsheet في Main5؛ current contract صحيح من جهة المسؤولية المركزية.

---

# 7. Critical Production Defect Found — Append Runsheet

قبل هذه الجلسة كان `append-to-runsheet` Edge ينفذ عدة كتابات مستقلة:

1. تحديث/إدخال `run_sheet_details`.
2. تحديث الأوردرات.
3. قراءة الإجمالي.
4. تحديث إجمالي الرانشيت.

وهذا كان يسمح نظريًا بـPartial Success إذا فشلت خطوة بعد نجاح خطوة سابقة.

كان ذلك تعارضًا مباشرًا مع Gold/Diamond ومع مبدأ Atomic Business Capability.

## الإصلاح التنفيذي الذي تم داخل Production

تم إنشاء RPC مركزي جديد:

`append_orders_to_runsheet_atomic`

التوقيع:

```text
(uuid, text, text[], text)
```

وظيفته:

- تثبيت Context الشركة.
- قفل الرانشيت واستعمال advisory lock خاص بالعملية.
- منع الإضافة إلى رانشيت غير Open/Confirmed.
- التحقق من كل الأوردرات داخل الشركة.
- رفض الأوردر المرتبط بالفعل برانشيت آخر.
- التحقق من حالات الأوردر.
- التحقق من Item Identity مقابل Global Item Master.
- تحديث/إضافة `run_sheet_details`.
- ربط جميع الأوردرات.
- تحديث الإجمالي.
- تنفيذ كل ذلك داخل Transaction واحدة.
- إعادة نتيجة موحدة.

ثم تم نشر:

`append-to-runsheet` — Version 8 — ACTIVE — JWT required

Deployment SHA:

`1225b25e21f36c94aa60ce6afacb3933d62e8f3f12f853466ca1fe448c0aa23c`

وأصبح Edge مجرد capability wrapper رفيع يستخرج Company Context من المستخدم ويستدعي الـRPC المركزي.

---

# 8. Production Runtime Test — Append Closure

لم يتم إنشاء أي بيانات اختبار دائمة.

تم إنشاء أوردرين مؤقتين داخل Transaction، ثم:

1. `create_runsheet_atomic` → PASS.
2. أول `append_orders_to_runsheet_atomic` → PASS.
3. الكمية بعد أول Append = `3.0000`.
4. إجمالي الرانشيت بعد أول Append = `30.00`.
5. إعادة تنفيذ نفس Append → `success=true, duplicate=true`.
6. الكمية بعد Retry بقيت `3.0000`.
7. الإجمالي بعد Retry بقي `30.00`.
8. Transaction انتهت بـ`ROLLBACK`.

هذه النتيجة تثبت عمليًا:

`APPEND + RETRY ≠ DUPLICATE QUANTITY`

ولا يوجد تضاعف للإجمالي أو السطور في نفس السيناريو.

### تجربة أولى فاشلة
أول محاولة اختبارية فشلت لأن test setup حاول إدخال قيمة يدويًا في `order_details.line_amount`، بينما العمود Generated في Production.

هذا فشل في بيانات الاختبار فقط، ولم يتسبب في تغيير دائم في Production، وتمت إعادة الاختبار باستخدام الـSchema الفعلي ونجحت النتيجة المطلوبة.

---

# 9. Main5 — Critical Source Defect 1: Driver Identity

Production Schema يثبت:

```text
runsheets.driver_id :: uuid
runsheets_driver_id_fkey → users.id
```

بينما Main5 الحالي يحوي في `loadHelpers()`:

```javascript
var dRes = await supabase.from('users').select('email, name').eq('company_id', _rwCompanyId()).in('role', ['driver','سائق','مندوب']);
```

ثم يعامل السائق أثناء العرض والاختيار كأن هويته البريد الإلكتروني:

```javascript
var sel = (rs.driver_id === d.email) ? ' selected' : '';
driverOptions += '<option value="' + d.email + '"' + sel + '>' + d.name + ' (' + d.email + ')</option>';
```

هذا غير متوافق مع Production.

الـ`manage-runsheet` Production wrapper يرسل `driver_id` للـRPC، و`manage_runsheet_atomic` يثبت أن الـdriver يجب أن يكون `users.id` UUID داخل نفس الشركة.

### النتيجة
هذا Defect مثبت، وليس افتراضًا.

---

# 10. Main5 — Critical Source Defect 2: Driver Display Mapping

في `_renderTable()` الحالي:

```javascript
if (driversCache[i].email === r.driver_id) { driverName = driversCache[i].name; break; }
```

المقارنة الصحيحة يجب أن تكون:

```text
users.id === runsheets.driver_id
```

وليس:

```text
users.email === runsheets.driver_id
```

---

# 11. Main5 — Critical Source Defect 3: Driver Filter

الفلتر الحالي يستخدم:

```javascript
if (dr) filtered = filtered.filter(function(r) { return (r.driver_id||'').toLowerCase().indexOf(dr) !== -1; });
```

لكن `driver_id` UUID وليس الاسم أو البريد.

لذلك المستخدم الذي يكتب اسم السائق لن يجد الرانشيت المتوقع.

الإصلاح يجب أن يجعل الفلتر يبحث في:

- اسم السائق.
- بريد السائق.
- ويمكن كذلك مطابقة UUID عند الحاجة.

---

# 12. Main5 — Critical Source Defect 4: Runsheet Filter in Orders

فلتر الرانشيت داخل `RW_Orders._applyFilters()` يستخدم:

```javascript
if (rs) filtered = filtered.filter(function(o) { return (o.runsheet_id || '').toLowerCase().indexOf(rs) !== -1; });
```

لكن المستخدم يُدخل **رقم الرانشيت** بينما `runsheet_id` هو UUID.

Main5 نفسه يبني `_runsheetCode` من `runsheets.runsheet_code`.

إذن الفلترة يجب أن تعتمد على:

```text
_runsheetCode
```

وليس UUID.

---

# 13. Main5 — Critical Source Defect 5: Session Guard Gaps

`_confirm()` الحالي يستخرج:

```javascript
var t = ses.data.session && ses.data.session.access_token;
```

ثم يرسل الطلب مباشرة دون فحص `t`.

والحالة نفسها موجودة في `_delete()`.

لدينا نمط صحيح بالفعل في `_confirmOrderFromDetails()`، حيث يتم التحقق من Token قبل fetch.

هذا ليس Core Business bug، ولكنه Error-path defect واضح وسيؤدي إلى request غير صالح بدل رسالة جلسة مفهومة للمستخدم.

---

# 14. Main5 — Critical Source Defect 6: HTML Output Escaping

داخل `_renderTable()` يتم عرض:

```javascript
(o.customer_name || '')
(o.area || '')
```

دون استعمال `esc()`.

بينما الملف نفسه يملك `esc()` بالفعل ويستخدمها في `_showDetails()`.

هذا عدم اتساق حقيقي ويمكن إصلاحه جراحيًا دون تغيير Business Contract.

---

# 15. Main5 — ما لم نعدله

لم يتم تعديل ما يلي لعدم وجود دليل على أنه يجب تغييره:

- POS lifecycle.
- Order → Runsheet business ownership.
- `order_details` كمصدر تفاصيل الأوردر.
- `run_sheet_details` كـderived aggregate.
- Physical Stock lifecycle داخل Main5.
- `create_runsheet_atomic`.
- `manage_runsheet_atomic`.
- Owner semantics.
- `Current/PWA/New-main`.
- `Original/PWA/main5.md`.

---

# 16. Owner Change Set — Main5-N1
## تصحيح هوية السائق في `loadHelpers()`

**FILE:**
`Current/PWA/main2/main5.md`

**CURRENT SHA:**
`c4518d05ada50830e819563a55169843679d3e94`

**FUNCTION:**
`RW_Runsheets.loadHelpers()`

**CURRENT LOCATION:**
حوالي السطور `814–821` في النسخة الحالية، مع تطابق النص التالي.

**ابحث عن هذا العنصر كاملًا:**

```javascript
    async function loadHelpers() {
        try {
            var dRes = await supabase.from('users').select('email, name').eq('company_id', _rwCompanyId()).in('role', ['driver','سائق','مندوب']);
            driversCache = dRes.data || [];
            var vRes = await supabase.from('vehicles').select('id, license_plate, model').eq('company_id', _rwCompanyId());
            vehiclesCache = vRes.data || [];
        } catch(e) { console.error(e); }
    }
```

**احذفه كاملًا واستبدله بهذا العنصر كاملًا:**

```javascript
    async function loadHelpers() {
        try {
            var companyId = _rwCompanyId();
            if (!companyId) {
                driversCache = [];
                vehiclesCache = [];
                return;
            }
            var dRes = await supabase
                .from('users')
                .select('id, email, name, status')
                .eq('company_id', companyId)
                .in('role', ['driver', 'سائق', 'مندوب']);
            driversCache = (dRes.data || []).filter(function(d) {
                return !d.status || d.status === 'Active';
            });
            var vRes = await supabase
                .from('vehicles')
                .select('id, license_plate, model')
                .eq('company_id', companyId);
            vehiclesCache = vRes.data || [];
            if (dRes.error) console.error('Drivers load failed:', dRes.error);
            if (vRes.error) console.error('Vehicles load failed:', vRes.error);
        } catch(e) {
            driversCache = [];
            vehiclesCache = [];
            console.error('Runsheet helpers load failed:', e);
        }
    }
```

**المسؤولية:** جعل بيانات السائق المستخدمة في UI متوافقة مع `runsheets.driver_id → users.id`.

---

# 17. Owner Change Set — Main5-N2
## تصحيح عرض السائق في `_renderTable()`

**الموضع:** داخل `RW_Runsheets._renderTable()`، حوالي السطور `984–986`.

**ابحث عن هذا المقطع كاملًا:**

```javascript
            var driverName = r.driver_id || '---';
            for (var i = 0; i < driversCache.length; i++) {
                if (driversCache[i].email === r.driver_id) { driverName = driversCache[i].name; break; }
            }
```

**احذفه كاملًا واستبدله بهذا المقطع الكامل:**

```javascript
            var driverName = '---';
            for (var i = 0; i < driversCache.length; i++) {
                if (driversCache[i].id === r.driver_id) {
                    driverName = driversCache[i].name || driversCache[i].email || '---';
                    break;
                }
            }
            if (driverName === '---' && r.driver_id) {
                driverName = String(r.driver_id);
            }
```

---

# 18. Owner Change Set — Main5-N3
## تصحيح اختيار السائق داخل `_details()`

**الموضع:** داخل `RW_Runsheets._details()`، حوالي السطور `1024–1026`.

**ابحث عن هذا المقطع كاملًا:**

```javascript
        for (var i = 0; i < driversCache.length; i++) {
            var d = driversCache[i];
            var sel = (rs.driver_id === d.email) ? ' selected' : '';
            driverOptions += '<option value="' + d.email + '"' + sel + '>' + d.name + ' (' + d.email + ')</option>';
        }
```

**احذفه كاملًا واستبدله بهذا المقطع الكامل:**

```javascript
        for (var i = 0; i < driversCache.length; i++) {
            var d = driversCache[i];
            var driverId = d.id || '';
            var driverLabel = d.name || d.email || driverId;
            if (d.email) driverLabel += ' (' + d.email + ')';
            var sel = (rs.driver_id === driverId) ? ' selected' : '';
            driverOptions += '<option value="' + _esc(driverId) + '"' + sel + '>' + _esc(driverLabel) + '</option>';
        }
```

هذا يضمن أن قيمة `<option>` هي `users.id` وليس البريد الإلكتروني.

---

# 19. Owner Change Set — Main5-N4
## إصلاح فلتر السائق

**الموضع:** داخل `RW_Runsheets._apply()`.

**ابحث عن هذا السطر الكامل:**

```javascript
        if (dr) filtered = filtered.filter(function(r) { return (r.driver_id||'').toLowerCase().indexOf(dr) !== -1; });
```

**احذفه واستبدله بهذا السطر الكامل:**

```javascript
        if (dr) filtered = filtered.filter(function(r) {
            var driver = null;
            for (var i = 0; i < driversCache.length; i++) {
                if (driversCache[i].id === r.driver_id) {
                    driver = driversCache[i];
                    break;
                }
            }
            var driverIdText = String(r.driver_id || '').toLowerCase();
            var driverNameText = String(driver && driver.name || '').toLowerCase();
            var driverEmailText = String(driver && driver.email || '').toLowerCase();
            return driverIdText.indexOf(dr) !== -1 || driverNameText.indexOf(dr) !== -1 || driverEmailText.indexOf(dr) !== -1;
        });
```

---

# 20. Owner Change Set — Main5-N5
## إصلاح فلتر رقم الرانشيت داخل Orders

**الموضع:** `RW_Orders._applyFilters()` — السطر الحالي `185` تقريبًا.

**ابحث عن هذا السطر الكامل:**

```javascript
        if (rs) filtered = filtered.filter(function(o) { return (o.runsheet_id || '').toLowerCase().indexOf(rs) !== -1; });
```

**احذفه واستبدله بهذا السطر الكامل:**

```javascript
        if (rs) filtered = filtered.filter(function(o) { return String(o._runsheetCode || '').toLowerCase().indexOf(rs) !== -1; });
```

---

# 21. Owner Change Set — Main5-N6
## إضافة Session Guard إلى `_confirm()`

**الموضع:** داخل `RW_Orders._confirm()`، حاليًا مباشرة بعد هذا السطر:

```javascript
                var t = ses.data.session && ses.data.session.access_token;
```

**أضف مباشرة بعده:**

```javascript
                if (!t) {
                    hideLoader();
                    showToast('انتهت الجلسة. يرجى إعادة تسجيل الدخول.', 'error');
                    return null;
                }
```

لا تحذف سطر `t` الأصلي.

---

# 22. Owner Change Set — Main5-N7
## إضافة Session Guard إلى `_delete()`

**الموضع:** داخل `RW_Orders._delete()`، حاليًا مباشرة بعد هذا السطر:

```javascript
            var t = ses.data.session && ses.data.session.access_token;
```

**أضف مباشرة بعده:**

```javascript
            if (!t) {
                hideLoader();
                showToast('انتهت الجلسة. يرجى إعادة تسجيل الدخول.', 'error');
                return null;
            }
```

لا تحذف سطر `t` الأصلي.

---

# 23. Owner Change Set — Main5-N8
## منع إخراج بيانات العميل والمنطقة دون Escaping

**الموضع:** داخل `RW_Orders._renderTable()`.

**ابحث عن هذا الجزء الكامل داخل قيمة `<td>`:**

```javascript
                '<td class="p-3 text-center"><p class="font-semibold">' + (o.customer_name || '') + '</p><p class="text-xs text-gray-500">' + (o.area || '') + '</p></td>' +
```

**استبدله بهذا الجزء الكامل:**

```javascript
                '<td class="p-3 text-center"><p class="font-semibold">' + esc(o.customer_name || '') + '</p><p class="text-xs text-gray-500">' + esc(o.area || '') + '</p></td>' +
```

---

# 24. Production Changes in This Session

تم تنفيذ تغيير Production واحد مرتبط مباشرة بـMain5:

### Append Runsheet Atomic Closure

- RPC: `append_orders_to_runsheet_atomic`
- Edge Function: `append-to-runsheet` v8 ACTIVE.
- JWT required.
- Edge صار wrapper رفيعًا.
- لا يوجد Writer موازٍ في Edge بعد التغيير.
- Runtime transactional test passed.
- Retry duplicate path verified.
- No permanent test data retained.

لم يتم تعديل بيانات الأعمال الحالية.

---

# 25. Production / Data Safety

لا توجد عملية حذف أو نقل أو تنظيف لبيانات الأعمال بسبب Main5 في هذه الجلسة.

الـProduction الحالية تحتوي على حالات Data Integrity في مسارات Inventory تم اكتشافها في جلسة سابقة، لكن تم احترام أمر المستخدم بوقف المهمة السابقة وعدم استكمالها هنا. لم تُستخدم تلك الحالات كسبب لتعديل Main5 بالتخمين.

---

# 26. Syntax Validation

### Full Main5 read
تمت قراءة `Current/PWA/main2/main5.md` تسلسليًا حتى EOF.

### Structural review
تم التحقق من إغلاق الوحدتين الأساسيتين:

```text
window.RW_Orders = RW_Orders;
window.RW_Runsheets = RW_Runsheets;
```

### CI / node --check
لم يتوفر Run CI حديث موثوق لهذا checkpoint عبر GitHub connector، ولم يتم تنفيذ Node على المصدر الخام بسبب عدم توفر network/raw fetch من بيئة التنفيذ المحلية.

لذلك:

`CI SYNTAX PASS = NOT PROVEN`

ولم يتم تحويل المراجعة البنيوية إلى ادعاء Syntax PASS.

---

# 27. Main1–Main11 Match Gate

تم التحقق من directory canonical مباشرة في GitHub.

الأجزاء الموجودة تحت:

`Current/PWA/main2/`

هي:

`main1.md` … `main11.md`

مع وجود SHA وحجم لكل جزء.

هذه الجلسة لم تعيد قراءة نص الأجزاء العشرة الأخرى كاملًا حتى EOF؛ وبالتالي لا يُدّعى Full-read لها في هذا التقرير.

تمت فقط مطابقة المسار، الوجود، والـcanonical assembly inputs.

وهذا كافٍ لمطابقة assembly source gate، وليس كافيًا للإعلان عن functional completion للمجموعة كلها.

---

# 28. Gold / Diamond Functional Gate

### السؤال الحاكم:
هل تحقق الهدف الأصلي: استكمال ملفات النظام الأم وظيفيًا؟

**الإجابة الحالية: لا — لم يغلق بعد.**

### هل ما زالت هناك وظائف ناقصة أو هيكلية فقط؟

نعم، Main5 نفسه يحتوي قدرات حقيقية لكنه لا يزال يحتاج إغلاق العيوب المثبتة أعلاه، كما أن المشروع ككل ما زال يحتوي تبويبات مالية وHR وCRM وتقارير لم يتم إغلاق اكتمالها الوظيفي حتى الآن.

لا يجوز تسمية Main5 أو المشروع Gold/Diamond بناءً على وجود الشاشة فقط.

---

# 29. Final Self-Audit

## ما تم إثباته

- Main5 الحالي هو `Current/PWA/main2/main5.md`.
- SHA الحالية في Git = `c4518d05ada50830e819563a55169843679d3e94`.
- EOF تم إثباته.
- Main5 يحتوي Orders وRunsheets كقدرات حقيقية.
- `runsheets.driver_id` هو UUID مرتبط بـ`users.id`.
- Current Main5 يخالف هذا العقد في اختيار السائق وعرضه.
- `append-to-runsheet` كان non-atomic في Production وتم إغلاقه بـRPC ذري.
- Runtime retry لم يضاعف الكمية أو الإجمالي.
- `create-runsheet` و`confirm-order` الحاليان يعتمدان Production Core صحيحًا نسبيًا ولم توجد حاجة لإعادة بنائهما في Main5.
- Assembly manifest صحيح ومصدره `Current/PWA/main2`.

## ما لم يتم إثباته

- Browser E2E لـMain5 بعد تطبيق Owner Change Sets.
- CI `node --check` PASS.
- Gold/Diamond completion للمشروع.
- Functional completeness لجميع الأجزاء 1–11.

## ما تم إصلاحه فعليًا

- Production Atomic Append Runsheet.

## ما يحتاج تدخل المالك

`MAIN5-N1` إلى `MAIN5-N8` كما هو محدد أعلاه.

## نقطة الاستكمال التالية

بعد تنفيذ Main5-N1..N8 بواسطة المالك:

```text
1. إعادة قراءة Current/PWA/main2/main5.md كاملًا حتى EOF.
2. التحقق من SHA الجديدة.
3. Syntax/CI gate.
4. Production recheck لتعديل driver/vehicle flow.
5. Runtime check لإنشاء/ضم الرانشيت وتعديل السائق.
6. ثم فتح أول Functional Capability Gap مثبت بعد هذا الإصلاح.
```

ممنوع الانتقال إلى Assembly قبل اكتمال Owner source verification لجميع الأجزاء بحسب البوابة النهائية.

---

# 30. Closure Status

`MAIN5 FORENSIC READ = COMPLETED`

`MAIN5 PRODUCTION APPEND ATOMIC CLOSURE = PRODUCTION VERIFIED`

`MAIN5 DRIVER IDENTITY CONTRACT = DEFECT PROVEN`

`MAIN5 OWNER SOURCE SURGERY = REQUIRED`

`MAIN5 GOLD/DIAMOND = NOT CLOSED`

`FULL 11-FRAGMENT FUNCTIONAL COMPLETION = NOT CLOSED`

`FINAL ASSEMBLY = DEFERRED`

`FALSE CLOSURE = REJECTED`

---

# 31. Exact Session Continuity Record

**SESSION DATE:** 2026-09-12

**CURRENT MISSION:** Full RAWAEA ERP functional completion toward Gold/Diamond.

**CURRENT PHASE:** Main-system fragment forensic functional completion.

**CURRENT CLOSURE UNIT:** Main5 Orders / Runsheets.

**LAST VERIFIED SOURCE SHA:** `c4518d05ada50830e819563a55169843679d3e94`

**PRODUCTION APPEND EDGE:** `append-to-runsheet` v8 ACTIVE.

**PRODUCTION APPEND DEPLOYMENT SHA:** `1225b25e21f36c94aa60ce6afacb3933d62e8f3f12f853466ca1fe448c0aa23c`

**DATABASE CORE:** `append_orders_to_runsheet_atomic` present and transactionally verified.

**OWNER CHANGESET:** `MAIN5-N1..N8`.

**NEXT EXACT TASK:** Apply the exact Main5 owner source changes; then re-read Main5 and perform the syntax/Production verification gate.
