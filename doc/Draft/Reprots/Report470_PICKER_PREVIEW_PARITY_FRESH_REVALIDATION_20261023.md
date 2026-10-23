# Report470 — إعادة مطابقة معاينة Picker مع Loader وتثبيت التعديل الجراحي النهائي

**التاريخ:** 2026-10-23  
**النطاق الوحيد:** معاينة الرانشيت في `erp-frontend/companies/company-1/warehouse/picker.html` لتصبح أغنى وأكثر أمانًا ومتسقة بصريًا مع نمط المعاينة الحالي في Loader.  
**قاعدة التغيير:** المالك يطبق تعديل ملف التطبيق. لم يُعدّل المساعد `picker.html` أو `loader.html` أو `main.html`. لا يوجد تغيير مطلوب في Supabase Production لهذا التغيير العرضي.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المعاينة قراءة فقط؛ يجب أن تعرض معلومات الرانشيت وأصنافه بوضوح، ولا تبدأ دورة Picking أو تحجز المخزون إلا بعد ضغط زر البدء المسموح به.
- **Architecture Understanding:** Picker يستخدم استعلامات Supabase الحالية وEdge `start-picking` الحالية. لا نضيف Edge Function أو RPC أو مسار كتابة جديدًا.
- **Database Understanding:** أثبت فحص Production أن `run_sheet_details` يحتوي `item_id` ولا يحتوي `description`. وصف الصنف موجود في `items.description` ويُقرأ عبر FK `run_sheet_details_item_id_fkey` من `run_sheet_details.item_id` إلى `items.id`.
- **Historical Understanding:** Report466 وثّق نقل معاينة Loader إلى `mainContent`. Reports467–469 تتبعت النقص المقابل في Picker وصححت افتراض حقل الوصف وتسميات حالة الرانشيت. هذه التقارير أدلة تاريخية؛ تمت مطابقة المصدر والـProduction مجددًا في هذه الدورة.
- **Production Understanding:** المشروع `fiilmooggumokxanwiyx`. فحص Edge الحالي: `start-picking v35`, `start-loading v5`, `complete-loading v11`؛ الثلاثة `ACTIVE` و`verify_jwt=true`. لا يتطلب تغيير عرض المعاينة تعديل هذه الوظائف.
- **Current Understanding:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Core SHA السابق في سجل المشروع `ff2f581d9900543c16f7cb026e13446520c0329d` ويجب إعادة مطابقته إذا تغيّر قبل التطبيق.
- **Execution Confidence:** مرتفع في سبب النقص ومجموعة التعديل المقترحة. لا يوجد إثبات بأن المالك طبق التعديل أو أن Cloudflare يخدم الـSHA نفسه أو أن Browser E2E نجح.

## 1. الأدلة الحالية

| العنصر | نتيجة التحقق |
|---|---|
| Loader | `companies/company-1/warehouse/loader.html`, SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` |
| Picker | `companies/company-1/warehouse/picker.html`, SHA `d483bd15b36585b975b63c2ef641481a01d5d084` |
| آخر commit غيّر معاينة Loader | `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010`; غيّر `App._showPreviewModal` ليعرض داخل الصفحة |
| Production FK | `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id` |
| Production columns | `items.description` موجود؛ `run_sheet_details.description` غير موجود |
| Production RLS | قراءات `runsheets` و`run_sheet_details` و`items` محكومة بسياق الشركة والصلاحيات |
| Production Edge | `start-picking v35`, `start-loading v5`, `complete-loading v11`; كلها `verify_jwt=true` |
| بيانات الأعمال | لا توجد كتابة أو تعديل أو حذف بيانات في هذه الدورة؛ لم تُنشأ بيانات تجريبية في Production |

## 2. السبب الجذري

فرع المعاينة في `App.openRunsheet(code)` في Picker ما زال يبني عنوانًا وقائمة أصناف مختصرة. لا يعرض إجمالي الكمية المطلوبة ولا وصف الصنف بشكل دائم، ويُدرج قيمًا من قاعدة البيانات داخل HTML وinline handlers دون escaping موثوق.

كما أن مقترح Report467 استخدم `it.description` رغم أن هذا العمود غير موجود في `run_sheet_details`. المسار الصحيح هو جلب `items.description` عبر العلاقة المثبتة. وأظهر التدقيق أن معاينة Picker قد تُفتح أيضًا لرانشيت `Picked`؛ لذلك يجب ألا تعرض الحالة على أنها «مفتوح» وألا تعرض زر بدء التحضير في هذه الحالة.

## 3. التعديل الجراحي المعتمد

### الملف والدالة

- **الملف:** `companies/company-1/warehouse/picker.html`
- **SHA الذي تمت مطابقته:** `d483bd15b36585b975b63c2ef641481a01d5d084`
- **الدالة:** `App.openRunsheet(code)`
- **المالك يطبق التعديل؛ لا تستبدل الملف كاملًا.**

### Patch A — جلب الوصف من العلاقة الصحيحة

ابحث عن:

```js
    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)
```

واستبدل الأسطر الثلاثة فقط بـ:

```js
    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)
```

لا تضف عمودًا جديدًا ولا تعدّل Schema؛ الوصف موجود في جدول `items`.

### Patch B — معاينة Picker داخل الصفحة

داخل `App.openRunsheet(code)`، بعد فرع استعادة جلسة Picking النشطة، استبدل المقطع الذي يبدأ عند `var html = '';` وينتهي عند `safeHTML(byId('mainContent'), html);` بالبديل الكامل الوارد في:

[Report468 — كتلة الاستبدال الكاملة لمعاينة Picker](Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md)

**عند نسخ كتلة Report468، طبّق التصحيحين الإلزاميين التاليين داخل الكتلة نفسها قبل اللصق.**

التصحيح الأول: استبدل سطر تسمية الحالة المقترح في Report468:

```js
html += '<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + (rs.status === 'Confirmed' ? 'مؤكد' : 'مفتوح') + '</span></div></div>';
```

بالنص التالي:

```js
var previewStatusLabel = rs.status === 'Picked'
    ? 'مكتمل التحضير'
    : (rs.status === 'Confirmed' ? 'مؤكد' : 'مفتوح');

html += '<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + previewStatusLabel + '</span></div></div>';
```

التصحيح الثاني: استبدل العنوان الفرعي:

```js
html += '<p class="text-xs text-slate-400 mt-1">راجع الأصناف والكميات والوصف قبل بدء التحضير</p></div></div>';
```

بالنص التالي:

```js
html += '<p class="text-xs text-slate-400 mt-1">' + (canStart ? 'راجع الأصناف والكميات والوصف قبل بدء التحضير' : 'عرض تفاصيل الرانشيت') + '</p></div></div>';
```

تبقى قاعدة ظهور زر البدء كما هي: يظهر فقط عندما تكون حالة الرانشيت `Open` أو `Confirmed`. لا يظهر في `Picked`.

### Patch C — تأمين مصدر الصورة

استبدل الدالة `App._img(code)` وحدها بالبديل الكامل الوارد في القسم 6 من Report468. هذا يقيد مصدر الصورة إلى HTTP(S) أو مسار مطلق ويعرض صورة بديلة إذا كان الرابط غير مقبول.

### Patch D — تأمين تفاصيل الصنف

استبدل الدالة `App.showItemDetail(code, name, unit, qty, desc)` وحدها بالبديل الكامل الوارد في القسم 7 من Report468. لا تغيّر مسار التحضير النشط أو دوال حفظ الكميات.

## 4. طريقة التطبيق

1. أعد فتح الملف الحالي وتحقق أن SHA ما زال `d483bd15b36585b975b63c2ef641481a01d5d084`. إذا تغيّر، أعد تحديد المقطع من المصدر الجديد ولا تطبق أرقام أسطر قديمة.
2. طبّق Patch A.
3. انسخ كتلة المعاينة الكاملة من Report468 مع تصحيحي الحالة والعنوان أعلاه وطبّق Patch B.
4. طبّق Patch C وPatch D فقط إذا كانت الدالتان لا تزالان على النص الحالي الذي استهدفه Report468؛ لا تكرر تعديلًا موجودًا.
5. لا تلمس `main.html` أو `loader.html` أو `core.js` أو Edge Functions أو قاعدة البيانات لهذا التغيير.
6. انشر التطبيق عبر المسار المعتمد ثم نفّذ الاختبارات أدناه.

## 5. الاختبارات المطلوبة بعد التطبيق

- رانشيت `Open` و`Confirmed`: يظهر رقم الرانشيت والتاريخ والحالة وعدد الأصناف وإجمالي الكمية المطلوبة.
- الوصف يأتي من `items.description` عبر FK الصحيح.
- رانشيت `Picked` الذي يحق للمستخدم عرضه: تظهر حالة «مكتمل التحضير»، ويختفي زر بدء التحضير.
- زر الرجوع يعيد قائمة الرانشيتات؛ زر البدء فقط للحالات المسموح بها ويستدعي `startPicking(code)`.
- النصوص التي تحتوي HTML أو علامات اقتباس تظهر كنص ولا تنفذ.
- الرانشيت الفارغ والصور المفقودة/غير الآمنة لا تسبب خطأ.
- جلسة Picking النشطة واستعادة Dexie لا تتأثران.
- اختبر الهاتف وسطح المكتب، وراقب Network وCloudflare served HTML.
- قارن المخزون والحجوزات قبل/بعد فتح المعاينة: يجب ألا يحدث أي تغيير.
- لا تستخدم رانشيتًا حيًا كبيانات اختبار ولا تُدخل معاملات تجريبية في Production.

## 6. ما لم يتم إثباته

- تطبيق المالك للتعديل: **UNVERIFIED**.
- نشر نسخة Picker بعد التعديل: **UNVERIFIED**.
- تطابق HTML الذي يقدمه Cloudflare مع Git: **UNVERIFIED**.
- Browser E2E: **UNVERIFIED**.
- لا يوجد تغيير في Production أو البيانات؛ لا توجد حاجة مثبتة إلى تعديل بنية Production لهذه المهمة العرضية.

## SELF-AUDIT FINAL

- **What I Proved:** SHA الحالي للملفين؛ commit معاينة Loader وparent الخاص به؛ علاقة FK وحقول الوصف الفعلية في Production؛ نسخ Edge الحالية؛ أن Picker الحالي لا يزال على فرع المعاينة المختصر.
- **What I Did Not Prove:** تطبيق التعديل، نشره، تطابق HTML المنشور، أو نجاح اختبار المتصفح.
- **What I Fixed:** صححت مجموعة تعليمات Patch المعاينة لتجلب الوصف من العلاقة الفعلية وتعرض حالة `Picked` بشكل صحيح، مع تثبيت تعليمات حماية HTML والصور.
- **What I Initially Missed:** تقرير Report468 لم يميز حالة `Picked` عند تسمية الحالة والنص الفرعي.
- **What Could Still Be Wrong:** قد يتغير المصدر قبل التطبيق أو يختلف HTML المنشور عن Git؛ لذلك يلزم إعادة مطابقة SHA واختبار المتصفح بعد النشر.
- **Final Confidence:** مرتفع في دقة التشخيص والتعديل المقترح؛ لا دليل على الإغلاق التشغيلي.
- **Final Closure Status:** `OWNER SURGICAL PATCH READY / PRODUCTION UI E2E OPEN / NOT CLOSED`.
