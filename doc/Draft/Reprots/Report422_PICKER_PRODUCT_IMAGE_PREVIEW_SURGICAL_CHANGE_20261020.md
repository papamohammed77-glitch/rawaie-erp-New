# Report422 — تكبير صورة الصنف في معاينة المحضّر ونافذة إدخال الكمية

**التاريخ:** 2026-10-20  
**النطاق الوحيد:** `papamohammed77-glitch/erp-frontend/companies/company-1/warehouse/picker.html`  
**طريقة التنفيذ:** تعديل جراحي يطبقه المالك؛ لم يتم تعديل ملف التطبيق أو `main.html`.  
**Production/Supabase:** لا تغيير؛ الخلل المثبت عرضي في HTML/CSS داخل SweetAlert2 ولا يتطلب تغيير قاعدة بيانات أو Edge Function أو RPC.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** صورة الصنف يجب أن تكون كبيرة بما يكفي لتمييز المنتج قبل التحضير وأثناء إدخال الكمية، دون إخفاء بيانات الكمية أو الوحدة أو الملاحظات.
- **Architecture Understanding:** `App.showItemDetail()` يعرض معاينة الصنف من تبويب الرانشيت، و`App.editPickedItem()` يعرض نافذة إدخال كمية التحضير. كلتاهما تستخدمان `ITEMS_IMAGE_CACHE`، فلا حاجة إلى مسار بيانات جديد.
- **Database Understanding:** المصدر الحالي يحمّل `items.item_code, image_url` مع قيد `company_id`; الصورة تُقرأ من cache في الواجهة. لا دليل على خلل في DB أو عقد الصورة.
- **Historical Understanding:** تمت مقارنة النسخة الحالية بالنسخة التاريخية `rawaie-erp-review/PWA/warehouse/picker.html` في المواضع ذات الصلة. التاريخ لا يبرر تغيير دورة التحضير أو عملياتها.
- **Production Understanding:** لم يُجر فحص إنتاجي حي خاص بالصورة؛ هذا التعديل لا يحتاج تغيير Production. لا أدّعي أن النسخة المنشورة أو المتصفح اختُبرا.
- **Current Understanding:** ملف Git الحالي `companies/company-1/warehouse/picker.html`، blob SHA `b85e81ef1303e6abbb086fa35acdf84bf9638075`، 1,003 أسطر. آخر commit مطابق لاسم الملف ظهر في البحث هو `15da299daa62262a7a365f58ca5ed118f905c2a7` بتاريخ 2026-10-19 23:59:07 +03:00، بعنوان `Refactor error handling in picker.html`. لم أزعم أن هذا commit نشر إلى Production.
- **Execution Confidence:** عالٍ في تحديد سبب صغر الصورة من المصدر؛ اختبار المتصفح بعد تطبيق المالك هو الذي يثبت النتيجة البصرية.

## السبب الجذري المثبت

1. في `App.showItemDetail(code, name, unit, qty, desc)`، الصورة محددة بـ`h-48` (192px) مع `object-cover`، وعرض النافذة `380px`. هذا يصغّر مساحة الفحص ويقص أجزاء من صور المنتجات ذات النسب المختلفة.
2. في `App.editPickedItem(index)`، صورة الصنف محددة بـ`w-20 h-20` (80×80px) مع `object-cover`. هذه هي نقطة الضعف الأساسية عند بدء التحضير/إدخال الكمية.
3. دالة `App._img(code)` تعرض صورة مصغرة 56×56px داخل القائمة. هذا حجم قائمة وليس موضع العطل، ولذلك **لا تعدّلها**.
4. لا يلزم تغيير `main.html` أو Edge Functions أو RPC أو schema. لا توجد حاجة إلى بيانات تجريبية أو تغييرات Production لهذه المشكلة.

## التعديل الجراحي المطلوب — يطبقه المالك

### التعديل 1: نافذة معاينة تفاصيل الصنف

- **الملف:** `erp-frontend/companies/company-1/warehouse/picker.html`
- **الدالة:** `App.showItemDetail(code, name, unit, qty, desc)`
- **الموضع الحالي:** قرب السطر 591 في blob SHA المذكور أعلاه. أعد البحث في النسخة الحالية قبل الاستبدال لأن أرقام الأسطر تتغير مع commits.
- **محدد البحث الفريد:** `showItemDetail: function(code, name, unit, qty, desc){`
- **ابحث عن السطر المعيب واحذفه بالكامل:**

```js
        var imgHtml = img ? '<img src="' + img + '" class="w-full h-48 object-cover rounded-2xl mb-4 shadow-sm" onerror="this.style.display=\'none\'">' : '<div class="w-full h-48 bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl flex items-center justify-center text-slate-400 mb-4"><i class="fa-solid fa-box text-4xl"></i></div>';
```

- **واستبدله بهذا السطر كاملًا:**

```js
        var imgHtml = img ? '<img src="' + img + '" class="w-full h-80 object-contain bg-white rounded-2xl mb-4 shadow-sm" onerror="this.style.display=\'none\'">' : '<div class="w-full h-80 bg-white rounded-2xl flex items-center justify-center text-slate-400 mb-4"><i class="fa-solid fa-box text-4xl"></i></div>';
```

- **ثم داخل استدعاء `Swal.fire({...})` في الدالة نفسها، ابحث عن:** `width: '380px'`
- **استبدل هذا الجزء فقط بـ:** `width: 'min(92vw, 560px)'`

### التعديل 2: نافذة بدء التحضير/إدخال الكمية

- **الملف:** نفس الملف.
- **الدالة:** `App.editPickedItem(index)`
- **الموضع الحالي:** قرب السطر 678 في blob SHA المذكور أعلاه؛ أعد البحث قبل الاستبدال.
- **محدد البحث الفريد:** `editPickedItem: function(index){`
- **ابحث عن السطر المعيب واحذفه بالكامل:**

```js
        var imgHtml = img ? '<img src="' + img + '" class="w-20 h-20 rounded-2xl object-cover mx-auto shadow-sm mb-3" onerror="this.style.display=\'none\'">' : '<div class="w-20 h-20 bg-gradient-to-br from-slate-100 to-slate-200 rounded-2xl mx-auto flex items-center justify-center text-slate-400 mb-3"><i class="fa-solid fa-box text-2xl"></i></div>';
```

- **واستبدله بهذا السطر كاملًا:**

```js
        var imgHtml = img ? '<img src="' + img + '" class="w-full max-w-xs h-72 rounded-2xl object-contain bg-white mx-auto shadow-sm mb-3" onerror="this.style.display=\'none\'">' : '<div class="w-full max-w-xs h-72 rounded-2xl bg-white mx-auto flex items-center justify-center text-slate-400 mb-3"><i class="fa-solid fa-box text-4xl"></i></div>';
```

- **داخل `Swal.fire({...})` في الدالة نفسها، أضف خاصية واحدة** بعد `title:` مباشرة، مع فاصلة بعد الخاصية:

```js
            width: 'min(92vw, 560px)',
```

لا تستبدل الدالة كاملة، ولا تغيّر حساب الكمية أو `preConfirm` أو حفظ الجلسة أو `operation_id` أو أزرار الحفظ والإلغاء.

## التأثير المتوقع

- ارتفاع صورة المعاينة من 192px إلى 320px.
- ارتفاع صورة إدخال الكمية من 80px إلى 288px.
- استخدام `object-contain` لعرض العبوة كاملة بدل قصّها، مع خلفية بيضاء ومساحة أكبر.
- توسيع النافذة بشكل متجاوب حتى 560px مع الحفاظ على هامش 4vw على الشاشات الصغيرة.
- لا تغيير في API أو دورة حياة Picking أو الحجز أو المخزون أو المحاسبة أو صلاحيات المستخدمين.

## الاختبارات المطلوبة بعد التطبيق

1. افتح صنفًا بصورته من قائمة الرانشيت: تحقق من ظهور صورة كبيرة كاملة دون قص.
2. اضغط بدء التحضير ثم اضغط صنفًا لإدخال الكمية: تحقق من صورة كبيرة، وأن الكمية المطلوبة والوحدة والملاحظات ما زالت ظاهرة.
3. جرّب صورة مربعة وصورة طولية وصورة أفقية؛ يجب أن تظهر كل صورة كاملة داخل المساحة.
4. جرّب صنفًا بلا صورة ورابط صورة مكسورًا؛ يجب أن يظهر placeholder دون انهيار النافذة.
5. احفظ كمية وملاحظة، ثم أعد فتح الصنف؛ تحقق من بقاء السلوك السابق كما هو.
6. اختبر على شاشة هاتف بعرض 360px وعلى شاشة سطح مكتب؛ لا يحدث تجاوز أفقي أو قص للأزرار.
7. نفّذ الاختبارات على النسخة المنشورة بعد نشر المالك. لم يتم إجراء Browser E2E في هذه الجلسة، لذلك لا تُعدّ المهمة مغلقة runtime حتى يثبت ذلك.

## حدود النطاق

- لم يتم تعديل أي ملف مصدر أو Production أو Supabase.
- لم يتم إنشاء بيانات تجريبية أو حذف بيانات؛ لا حاجة لها لعيب عرضي.
- لم يتم تعديل `main.html` أو `App._img()` أو أي عقد Inventory.
- لا يوجد ادعاء بأن المقارنة البصرية المباشرة مع متجر كارفور أو المتجر الإلكتروني الخاص بالمشروع أُجريت في المتصفح؛ التصميم المقترح يحقق الهدف المحدد بوضوح: صورة كبيرة كاملة قابلة للفحص.

## SELF-AUDIT FINAL

- **What I Proved:** السبب في المصدر الحالي هو قيود الحجم `h-48` و`w-20 h-20` مع `object-cover`، ومحدودية عرض نافذة المعاينة 380px.
- **What I Did Not Prove:** لا يوجد اختبار متصفح بعد التعديل، ولا إثبات نشر النسخة المعدلة إلى Production، ولا مقارنة بصرية حيّة مع متجر كارفور.
- **What I Fixed:** لم أعدّل التطبيق؛ أعددت تغييرًا جراحيًا دقيقًا للمالك وفق قاعدة ملكية ملفات الواجهة.
- **What I Initially Missed:** يجب تكبير صورتين مختلفتين: معاينة الصنف ونافذة إدخال كمية التحضير؛ تعديل واحدة فقط لا يعالج الشكوى كاملة.
- **What Could Still Be Wrong:** قد تختلف صور بعض المنتجات أو طريقة قصّها بحسب المصدر؛ اختبارات الصور المربعة والطولية والأفقية ضرورية.
- **Final Confidence:** مرتفع في التشخيص والتعديل المقترح؛ التحقق البصري النهائي غير منفذ.
- **Final Closure Status:** `SURGICAL PATCH READY / OWNER APPLY + BROWSER VERIFICATION OPEN`.
