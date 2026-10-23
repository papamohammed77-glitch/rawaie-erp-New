# Report469 — تصحيح حالة الرانشيت في Patch معاينة Picker

**التاريخ:** 2026-10-23  
**النطاق:** مراجعة تقرير Report468 وتدقيقه مقابل المصدر الحالي وProduction.  
**القاعدة:** لا تعديل على `main.html` أو `loader.html` أو `picker.html` التشغيلي. لا تغيير في Supabase Production لهذا التغيير العرضي.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المطلوب جعل معاينة Picker أكثر اكتمالًا مثل معاينة Loader مع الحفاظ على دورة Picking الحالية.
- **Architecture Understanding:** المعاينة قراءة فقط؛ بدء التحضير يظل عبر Edge Function الحالية `start-picking` ولا يُنشأ مسار جديد.
- **Database Understanding:** Production يؤكد أن `run_sheet_details` لا يحتوي `description`; مصدر الوصف الصحيح `items.description` عبر FK `run_sheet_details_item_id_fkey` من `run_sheet_details.item_id` إلى `items.id`.
- **Historical Understanding:** Report466 وثّق معاينة Loader داخل الصفحة؛ Report467 اقترح معاينة Picker لكنه افترض حقل وصف غير موجود؛ Report468 صحّح علاقة قاعدة البيانات وقدّم patch آمنًا للـHTML والصور.
- **Production Understanding:** القراءة المباشرة في هذه الدورة أكدت Edge `start-picking v35`, `start-loading v5`, `complete-loading v11` وكلها `verify_jwt=true`. RPCs الأساسية الخاصة بالحجز/الحركة محمية من `anon/authenticated` وفق فحص ACL السابق والجاري؛ لم يظهر احتياج لتغييرها في مهمة العرض.
- **Current Understanding:** Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`; Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084`; Core SHA `ff2f581d9900543c16f7cb026e13446520c0329d`. المصدر الحالي ما زال يحتوي فرع المعاينة المختصر، ولم يُثبت تطبيق Report468.
- **Execution Confidence:** مرتفع في تشخيص المصدر وعلاقة البيانات؛ لا يوجد إثبات نشر أو Browser E2E.
- **Confirmed Facts:** SHA للملفات، وجود FK وعمود الوصف في items، سياسات SELECT الحالية، ونسخ Edge الحالية.
- **Unknowns:** نسخة HTML التي يخدمها Cloudflare بعد تطبيق المالك، ونجاح التفاعل الفعلي في المتصفح.
- **Conflicts:** اكتشفت نقطة عرض صغيرة في Report468: تسمية الحالة المقترحة تعرض كل حالة ليست Confirmed على أنها «مفتوح»، بينما مسار Picker الحالي يسمح للمستخدم نفسه بفتح تفاصيل رانشيت حالته Picked.
- **Unverified Claims:** لم أزعم أن التعديل طُبق أو نُشر أو اجتاز E2E.

## 1. المصادر التي تمت إعادة مطابقتها

- Current Loader: `companies/company-1/warehouse/loader.html`, SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`.
- Current Picker: `companies/company-1/warehouse/picker.html`, SHA `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Report468: `doc/Draft/Reprots/Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md`, blob SHA `57066e3d602549afe2655e7988c92f5bad5ab862`.
- أحدث Picker commit المذكور في سجل Git: `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7`، بعنوان `Update picker.html`، بتاريخ `2026-10-21T16:43:32Z`. أداة commit المتاحة لم تُظهر parent SHA في النتيجة؛ لذلك لا أدعي التحقق من parent.
- Production FK المؤكد: `run_sheet_details_item_id_fkey`: `FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT`.
- Production RLS: قراءة `runsheets` محكومة بالشركة والصلاحيات؛ وقراءة `run_sheet_details` تتطلب أن يكون الرانشيت تابعًا للشركة الحالية وأن يملك المستخدم صلاحية مناسبة.
- Production Edge: `start-picking v35`، `start-loading v5`، `complete-loading v11`، وكلها نشطة مع `verify_jwt=true`.

## 2. التصحيح الوحيد المطلوب فوق Report468

Report468 صحيح في جوهره، ولا حاجة لإعادة كتابة Patch المعاينة أو تغيير قاعدة البيانات. لكن يجب تصحيح تسمية الحالة في مقطع المعاينة المقترح.

**الملف:** `erp-frontend/companies/company-1/warehouse/picker.html`  
**الدالة:** `App.openRunsheet(code)`، داخل مقطع المعاينة المقترح في Report468.  
**محدد البحث عن النص المقترح داخل Patch Report468:**

```js
'<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + (rs.status === 'Confirmed' ? 'مؤكد' : 'مفتوح') + '</span></div></div>';
```

**استبدل هذا السطر فقط في Patch Report468 بالنص التالي:**

```js
var previewStatusLabel = rs.status === 'Picked'
    ? 'مكتمل التحضير'
    : (rs.status === 'Confirmed' ? 'مؤكد' : 'مفتوح');

html += '<span class="px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold">' + previewStatusLabel + '</span></div></div>';
```

واستبدل نص العنوان الفرعي في المعاينة ليعكس إمكانية عرض رانشيت مكتمل:

**ابحث عن:**
```js
html += '<p class="text-xs text-slate-400 mt-1">راجع الأصناف والكميات والوصف قبل بدء التحضير</p></div></div>';
```

**واستبدله بـ:**
```js
html += '<p class="text-xs text-slate-400 mt-1">' + (canStart ? 'راجع الأصناف والكميات والوصف قبل بدء التحضير' : 'عرض تفاصيل الرانشيت') + '</p></div></div>';
```

هذا التصحيح يمنع عرض حالة `Picked` على أنها «مفتوح» ويحافظ على كون زر البدء ظاهرًا فقط لـ`Open/Confirmed`.

## 3. بقية Report468

تظل التغييرات الأربعة في Report468 هي المجموعة المعتمدة بعد تصحيح تسمية الحالة:
1. استخدام `items!run_sheet_details_item_id_fkey(description)` في قراءة التفاصيل.
2. استبدال فرع المعاينة المختصر بالمعاينة داخل الصفحة.
3. تأمين `App._img(code)` لقبول روابط الصور الآمنة فقط.
4. تهريب قيم `App.showItemDetail(...)` قبل إدراجها في HTML.

لا تنفذ أي تعديل إضافي في `main.html` أو `loader.html` أو Supabase؛ لا يوجد دليل يبرر تغييرها في نطاق هذه المهمة.

## 4. الاختبار المطلوب بعد تطبيق المالك

1. فتح رانشيت `Open` و`Confirmed`: يظهر الوصف من علاقة `items`، وعدد الأصناف وإجمالي الكمية المطلوبة.
2. فتح رانشيت `Picked` الخاص بالمستخدم: يظهر «مكتمل التحضير» ولا يظهر زر «بدء التحضير».
3. زر الرجوع يعيد القائمة؛ زر البدء فقط لـ`Open/Confirmed` ويستدعي `startPicking(code)`.
4. النصوص التي تحتوي HTML/اقتباسات تظهر كنص ولا تنفذ.
5. اختبار رانشيت فارغ، صور مفقودة/روابط غير آمنة، الهاتف وسطح المكتب.
6. تحقق من Network وCloudflare served HTML parity.
7. قارن المخزون والحجوزات قبل/بعد المعاينة؛ يجب أن يبقيا دون تغيير.

## Production / Data Safety

- لم تُنفذ أي DDL أو ACL أو RPC أو Edge changes.
- لم تُنشأ أو تُعدّل أو تُحذف بيانات أعمال أو بيانات اختبار.
- لا يُستخدم رانشيت حي كـfixture.
- المعاينة لا تحجز المخزون ولا تحركه.

## SELF-AUDIT FINAL

- **What I Proved:** الفجوة الحالية بين معاينة Loader وPicker؛ FK الحقيقي للوصف؛ غياب `description` من `run_sheet_details`; سياسات القراءة ونسخ Edge الحالية.
- **What I Did Not Prove:** تطبيق المالك، نشر Cloudflare، مطابقة HTML المنشور، أو نجاح Browser E2E.
- **What I Fixed:** صححت مقترح Report468 في تسمية حالة `Picked) والنص الفرعي للمعاينة.
- **What I Initially Missed:** تقرير Report468 لم يميّز بصريًا حالة `Picked) التي يسمح المصدر الحالي بعرضها للمستخدم نفسه.
- **What Could Still Be Wrong:** قد تختلف نسخة Cloudflare عن Git؛ لم يُختبر PostgREST relation في جلسة متصفح فعلية بعد تطبيق patch.
- **Final Confidence:** مرتفع في تصحيح المصدر/schema؛ runtime غير مثبت.
- **Final Closure Status:** `PATCH CORRECTED / OWNER APPLY + DEPLOY + BROWSER E2E OPEN`.
