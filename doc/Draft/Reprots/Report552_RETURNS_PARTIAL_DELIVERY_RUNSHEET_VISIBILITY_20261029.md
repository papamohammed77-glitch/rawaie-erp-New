# Report552 — التحقيق الجنائي لاختفاء رانشيت التسليم الجزئي من تطبيق المرتجعات

**Last Verified Event:** `LVE-2026-10-29-552`  
**التاريخ:** 2026-10-29  
**النطاق:** تكامل تطبيق مندوب التوصيل مع تطبيق المرتجعات بالمخزن؛ ظهور الرانشيت الذي يحتوي أوردرًا بحالة `Partially Delivered` والكميات المتبقية.  
**الحالة النهائية:** `PARENT RETURN-TAB FILTER ROOT CAUSE CONFIRMED / OWNER-ONLY MAIN.HTML MICRO-PATCH PREPARED AND STATIC-PARSED / STANDALONE RETURNS HARDENING IN DRAFT PR / NOT DEPLOYED / E2E OPEN`

## 1. القرار التنفيذي

استُكملت المراجعة من Report545 بوصفه مرجع الحوكمة، ثم Reports546–551، وقراءة `CURRENT_STATE.md` قبل مطابقة GitHub وSupabase Production. لم يُفترض أن الحالة القديمة في ملف الاستمرارية تمثل Production الحالي.

النتيجة الحية المهمة: الرانشيت `RS-2` موجود في Production وحالته `Delivered`، ويحتوي الأوردر `ORD-1007` بحالة `Partially Delivered`. الكمية المحملة لهذا الأوردر 3، والمسلمة 1، والمتبقي 2. إجمالي الكمية غير المسلمة في `RS-2` هو 5 وحدات عبر الأوردرات الموجودة في الرانشيت.

محاكاة قراءة RLS داخل معاملة معزولة، بهوية حساب «مرتجعات» النشط، أعادت:
- `delivered_runsheets_visible = 2`
- `rs2_visible = 1`
- `rs2_details_visible = 7`
- `partial_orders_visible = 1`

أُغلقت المعاملة بـ`ROLLBACK`. لم تتغير أي بيانات أعمال. هذا يستبعد — في الحالة التي اختُبرت — غياب الرانشيت من قاعدة البيانات أو منعه بسياسات RLS الخاصة بالمخزن.

## 2. مصدر الحقيقة وحدود الإثبات

- **مستودع التشغيل:** `papamohammed77-glitch/erp-frontend`, الفرع `main`.
- **ملف المرتجعات الحالي قبل التعديل:** `companies/company-1/warehouse/returns.html`.
- **Blob SHA قبل التعديل:** `36c20e03c94dc734e015610dec1e8208697df32a`.
- **مستودع الحالة والتقارير:** `papamohammed77-glitch/rawaie-erp-New`.
- **Supabase Production:** `fiilmooggumokxanwiyx`.
- **المرجع التاريخي الحاكم:** Report545؛ وتُستخدم Reports546–551 لتحديد ما أُصلح بالفعل وعدم تكراره.

### CONFIRMED
1. `RS-2` في Production بحالة `Delivered`.
2. `ORD-1007` بحالة `Partially Delivered`: المحمّل 3، المسلّم 1، والمتبقي 2.
3. إجمالي الكمية المتبقية في `RS-2` = 5.
4. محاكاة RLS لحساب المرتجعات أعادت صف `RS-2` وتفاصيله والأوردر الجزئي.
5. واجهة المرتجعات كانت تضمّن `run_sheet_details(count)` داخل استعلامي قائمة الرانشيتات، رغم أنها تجلب التفاصيل مرة أخرى باستعلام مستقل لحساب المتبقي.
6. الواجهة كانت تتجاهل `error` الذي تعيده استعلامات Supabase؛ فتستخدم `data || []` وتستطيع عرض قائمة فارغة دون توضيح أن الاستعلام فشل.
7. مسار بدء المرتجعات الحالي يقبل الرانشيت بحالة `Delivered` فقط، ودالة `complete_return_atomic` تشترط أن يكون الرانشيت `Returning`. لم أغيّر عقد الحالات هذا.

### UNKNOWN / UNVERIFIED
1. **تبويب المرتجعات في النظام الأم:** السبب الجذري المؤكد هو فلتر `loadReturn()` الذي يستبعد `Delivered` بلا بيانات بدء مرتجع؛ لكن تطبيق Owner Patch ونشره لم يحدثا بعد.
2. **تطبيق المرتجعات المستقل:** السبب الدقيق للواقعة في المتصفح لم يُثبت من Network/Runtime. عيب تجاهل أخطاء الاستعلام مؤكد، والتعديل المساعد ما زال في Draft PR.
3. هوية Artifact الذي كان Cloudflare يخدمه وقت الواقعة وبعد التعديلات غير مثبتة.
4. لم يُجرَ Browser E2E مصادق عليه بعد التعديل؛ لا يُدّعى إغلاق المشكلة في Production.

## 3. تحليل السبب الجذري

### 3.1 ما استُبعد بالأدلة

- **عدم وجود بيانات الرانشيت:** مستبعد للحالة الحية المفحوصة؛ الرانشيت والأوردر الجزئي والكميات موجودة.
- **حجب RLS لحساب المرتجعات:** مستبعد في محاكاة RLS المعزولة؛ الحساب استطاع رؤية الرانشيت وتفاصيله.
- **عدم حساب الكمية المتبقية في مصدر البيانات:** غير مثبت؛ الاستعلام الحي حسب `qty_loaded - qty_delivered - qty_returned` أعاد 5 وحدات متبقية للرانشيت، منها وحدتان في `ORD-1007`.

### 3.2 العيب المؤكد في الواجهة

الدالة `App.loadRunsheets()` كانت:
- تطلب علاقة `run_sheet_details(count)` ضمن استعلامي `runsheets` الأساسيين، مع أن بطاقات القائمة لا تستخدم تلك العلاقة.
- لا تفحص `results[0].error` أو `results[1].error`.
- لا تفحص خطأ استعلام `run_sheet_details` المستخدم لحساب الأصناف المتبقية.
- تحول `data=null` إلى مصفوفة فارغة، وهو ما يخفي فشل القراءة ويشبه «لا توجد رانشيتات».

هذا خلل مثبت في معالجة الأخطاء واعتماد غير ضروري في عقد الاستعلام داخل تطبيق المرتجعات المستقل. وهو تحسين وقائي مستقل عن السبب الجذري المؤكد في تبويب المرتجعات بالنظام الأم.

## 3.3 السبب الجذري المؤكد — تبويب المرتجعات في النظام الأم

المصدر الحالي لـ`companies/company-1/main.html`، Blob SHA `2951813e53ef7e24d79917bc272f13c95e111cb0`، يحتوي في `loadReturn()` على الفلتر:

```javascript
.or('status.eq.Returned,return_handler_id.not.is.null,return_start.not.is.null,return_end.not.is.null')
```

هذا الشرط لا يتضمن `status.eq.Delivered`. لذلك فإن الرانشيت المسلّم الذي يحتوي كمية غير مسلّمة، لكنه لم يبدأ بعد في دورة المرتجعات (`return_handler_id`, `return_start`, `return_end` ما زالت NULL)، يُستبعد قبل وصوله إلى `_applyReturn()`. وهذا يطابق حالة `RS-2` الحية.

**دليل Network المباشر:** سجل `edge_logs` في `2026-10-29T16:09:14.435Z` يحتوي طلب GET ناجحًا إلى `runsheets` مع `or=(status.eq.Returned,return_handler_id.not.is.null,return_start.not.is.null,return_end.not.is.null)`. الاستجابة HTTP كانت 200، لكن شرط الطلب نفسه يستبعد `RS-2` لأنه `Delivered` وحقول بدء المرتجع فارغة. لم يكن ذلك فشل RLS أو غياب بيانات.

### Owner Surgical Change Set — لا تُكتب التغييرات في main.html من جانب المساعد

**شرط التطبيق:** أعد جلب الملف قبل التطبيق. الرقعة التالية تخص فقط Blob SHA `2951813e53ef7e24d79917bc272f13c95e111cb0`. إذا اختلف SHA أو لم يظهر نص البحث حرفيًا مرة واحدة، توقف وأعد بناء الرقعة على المصدر الحالي. لا تستبدل الدالة `loadReturn()` أو `_applyReturn()` أو `_showReturnDetails()` كاملة.

**Patch A — توسيع قائمة الترشيح دون تغيير الحالات التاريخية**

ابحث عن هذا السطر الوحيد داخل `loadReturn()`:

```javascript
        .or('status.eq.Returned,return_handler_id.not.is.null,return_start.not.is.null,return_end.not.is.null')
```

واستبدله بهذا السطر فقط:

```javascript
        .or('status.eq.Delivered,status.eq.Returned,return_handler_id.not.is.null,return_start.not.is.null,return_end.not.is.null')
```

**Patch B — إدراج حساب المتبقي وتصفية Delivered المكتمل فقط**

ابحث عن هذا المقطع الفريد داخل `loadReturn()`:

```javascript
    window._returnData = res.data || [];
    _applyReturn();
```

واستبدله بهذا المقطع:

```javascript
    window._returnData = res.data || [];
    var deliveredRows = window._returnData.filter(function(r) { return r.status === 'Delivered'; });
    var deliveredIds = deliveredRows.map(function(r) { return r.id; }).filter(Boolean);
    var pendingReturnByRunsheet = {};
    if (deliveredIds.length) {
        var remainingRes = await supabase.from('run_sheet_details')
            .select('runsheet_id, qty_loaded, qty_delivered, qty_returned')
            .in('runsheet_id', deliveredIds);
        if (remainingRes.error) throw remainingRes.error;
        (remainingRes.data || []).forEach(function(d) {
            var remaining = Math.max(0, (Number(d.qty_loaded) || 0) - (Number(d.qty_delivered) || 0) - (Number(d.qty_returned) || 0));
            if (remaining > 0) {
                pendingReturnByRunsheet[d.runsheet_id] = (pendingReturnByRunsheet[d.runsheet_id] || 0) + remaining;
            }
        });
        window._returnData = window._returnData.filter(function(r) {
            return r.status !== 'Delivered' || (pendingReturnByRunsheet[r.id] || 0) > 0;
        });
    }
    window._returnData.forEach(function(r) {
        r.pending_return_qty = pendingReturnByRunsheet[r.id] || 0;
    });
    _applyReturn();
```

هذا يبقي سجلات `Returned` والرانشيتات التي لها بيانات دورة مرتجعات، ويضيف فقط `Delivered` التي لديها كمية متبقية موجبة. يستخدم نفس معادلة عقد `complete_return_atomic`: `loaded - delivered - returned`. إذا فشل استعلام الكميات، يُرفع الخطأ إلى `catch` الموجود ولا تُعرض الكمية على أنها صفر.

**Patch C — إظهار إجمالي المتبقي في صف الرانشيت**

داخل `_applyReturn()` ابحث عن سطر `return` الذي يبدأ بـ:

```javascript
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showReturnDetails(\'' + r.runsheet_code + '\')">
```

لا تستبدل `_applyReturn()` كاملة. استبدل سطر `return` الواحد بهذا المقطع داخل callback نفسه:

```javascript
            var statusLabel = r.status === 'Delivered' && Number(r.pending_return_qty) > 0
                ? 'بانتظار المرتجع: ' + Number(r.pending_return_qty).toLocaleString('ar-EG') + ' وحدة'
                : esc(r.status || '—');
            return '<tr class="border-b hover:bg-gray-50 cursor-pointer" onclick="RW_Warehouse._showReturnDetails(\'' + r.runsheet_code + '\')"><td class="p-3 font-bold">' + (r.runsheet_code||'') + '</td><td class="p-3">' + (r.run_date||'') + '</td><td class="p-3">' + (r.driver_id||'---') + '</td><td class="p-3"><span class="px-2 py-1 rounded-full text-xs bg-rose-100 text-rose-700">' + statusLabel + '</span></td><td class="p-3 text-center"><button class="text-blue-600"><i class="fa-solid fa-eye"></i></button></td></tr>';
```

**Patch D — عرض الكمية المحمّلة والمسلمة والمتبقية والمرتجعة في التفاصيل**

داخل `_showReturnDetails()` استبدل سطر عنوان الجدول فقط:

```javascript
        var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المسلّمة</th><th class="p-2 text-center">الكمية المرتجعة</th></tr></thead><tbody>';
```

بهذا السطر:

```javascript
        var h = '<div class="text-right"><table class="w-full border"><thead class="bg-slate-100"><tr><th class="p-2">الصنف</th><th class="p-2 text-center">الكمية المحمّلة</th><th class="p-2 text-center">الكمية المسلّمة</th><th class="p-2 text-center">المتبقي للمرتجع</th><th class="p-2 text-center">الكمية المرتجعة</th></tr></thead><tbody>';
```

ثم استبدل سطر الحلقة الوحيد الذي يبدأ بـ`items.forEach(it => { h += '<tr>` بهذا المقطع:

```javascript
        items.forEach(it => {
            var loaded = Number(it.qty_loaded) || 0;
            var delivered = Number(it.qty_delivered) || 0;
            var returned = Number(it.qty_returned) || 0;
            var remaining = Math.max(0, loaded - delivered - returned);
            h += '<tr><td class="p-2 font-bold">' + (it.item_name||'') + '</td><td class="p-2 text-center">' + loaded + '</td><td class="p-2 text-center">' + delivered + '</td><td class="p-2 text-center font-black text-amber-700">' + remaining + '</td><td class="p-2 text-center font-bold text-rose-600">' + returned + '</td></tr>';
        });
```

تم تطبيق هذه الرقع الخمس افتراضيًا على نسخة في الذاكرة فقط للتحقق من أن كل محدد فريد، وأن التغيير لا يكتب إلى Git أو Production. فحص JavaScript للكتلة المضمنة كاملة أعاد `PASS`. **لم يُعدّل ملف `main.html` في المستودع**؛ هذه Owner Patch وفق Report545.

## 4. التعديل الجراحي المُعدّ

### Owner/Review Change Set
- **الفرع:** `fix/returns-partial-delivery-visibility-20261029`
- **Commit:** `8a4589dc99a4fda418dd61d9508743d4097941d5`
- **Draft PR:** [PR #6 — harden returns list for partially delivered runsheets](https://github.com/papamohammed77-glitch/erp-frontend/pull/6)
- **الملف الوحيد المعدّل:** `companies/company-1/warehouse/returns.html`.
- **الأساس:** `main` عند `585f629d86f6b84038d5b96d0e8851a6ca6579c6`.
- **لم يتم الدمج أو النشر.**

التغييرات المحددة:
1. إزالة `run_sheet_details(count)` غير المستخدم من استعلامي قائمة الرانشيتات الأساسيين فقط.
2. فحص أخطاء استعلامي الرانشيتات وإظهار رسالة واضحة بدل تحويل الخطأ إلى قائمة فارغة.
3. فحص خطأ استعلام الكميات المتبقية؛ عند فشله لا يُعرض الرقم على أنه صفر، ولا يُشجَّع المخزن على بدء مرتجع دون كمية موثوقة.
4. تسجيل الخطأ التقني في Console لأغراض التشخيص، مع رسالة واجهة مفهومة.
5. فشل جلب اسم المندوب يُسجل كتحذير ولا يمنع عرض الرانشيت نفسه.

### ما بقي دون تغيير
- حالات الرانشيت المسموح بعرضها: `Delivered` و`Returning` المعيّن للمستخدم الحالي.
- حساب الكمية المتبقية على مستوى الصنف: `qty_loaded - qty_delivered` في شاشة المرتجع، مع الحفاظ على `qty_returned` في عقد المعالجة الخلفي.
- دوال `start-return` و`complete-return`، و`complete_return_atomic`.
- المخزون والمحاسبة وسجلات التدقيق وحالة الرانشيت والأوردرات.
- `main.html` و`core.js` وEdge Functions.

## 5. الاختبارات

| الاختبار | النتيجة |
|---|---|
| قراءة ملف المرتجعات الحالي وSHA قبل التعديل | PASS |
| التحقق من محددات التعديل وتفردها قبل الكتابة | PASS |
| JavaScript parse للكتلة المضمنة بعد التعديل | PASS |
| Static invariants: عدم حذف عقد الحالات وحساب الكميات | PASS |
| Production SQL read-only لبيانات `RS-2` و`ORD-1007` | PASS |
| RLS simulation لحساب المرتجعات مع ROLLBACK | PASS |
| Cloudflare artifact identity | UNVERIFIED |
| Authenticated browser E2E بعد التعديل | OPEN |
| تأكيد أن الرانشيت ظهر في شاشة المرتجعات المنشورة | UNVERIFIED |

## 6. Mutation Ledger

- **Supabase Production:** لا DDL أو RPC أو ACL أو RLS أو بيانات أعمال تم تعديلها في هذه الجولة.
- **عمليات المرتجعات:** لم يتم استدعاء `start-return` أو `complete-return` أثناء الاختبار.
- **المخزون/المحاسبة:** لم تتغير أي كمية أو حركة مخزنية أو قيد مالي.
- **GitHub:** التعديل في فرع مراجعة وDraft PR فقط؛ لم يُدمج إلى `main`.
- **البيانات التجريبية:** لم تُنشأ بيانات اصطناعية.

## 7. SELF-AUDIT FINAL

- لم أكرر إصلاحات بدء رحلة المندوب أو RLS الخاصة بالأوردرات والأصناف من Reports547–549.
- لم أعدّل `main.html` أو `core.js`.
- لم أغير شرط `Delivered → Returning` أو طريقة الترحيل المخزني.
- تم إثبات السبب الجذري لاختفاء الرانشيت من تبويب المرتجعات في النظام الأم من فلتر المصدر وطلب Network المطابق. يظل سبب واجهة المرتجعات المستقلة غير محسوم على مستوى الـRuntime حتى فحصها بعد النشر.
- لم أعتبر Static PASS أو SQL PASS مساويًا لاختبار Production UI.

**Final Closure Status:** `PARENT FILTER ROOT CAUSE CONFIRMED / OWNER MAIN.HTML PATCH PREPARED AND STATIC-PARSED / STANDALONE RETURNS HARDENING IN DRAFT PR / NO DEPLOYMENT OR AUTHENTICATED E2E / NOT CLOSED`.

**Next exact action:** يطبق المالك Patches A–D على `main.html` بعد تأكيد SHA، ثم ينشر وفق سير العمل المعتمد. بعدها اختبر تبويب المرتجعات في النظام الأم وتأكد من ظهور `RS-2` بإجمالي متبقٍ 5، وظهور `ORD-1007` بمتبقٍ 2 ضمن تفاصيل الأصناف. ثم راجع PR #6 كتحسين مستقل لمعالجة أخطاء استعلام تطبيق المرتجعات المستقل، وادمجه/انشره وفق سير العمل المعتمد. إذا لم يظهر الرانشيت بعد النشر، التقط Network من التطبيقين وطابق الـArtifact المخدوم مع SHA قبل أي تعديل جديد.
