# Report472 — إعادة التحقق الحي من فجوة معاينة Loader / Picker

**التاريخ:** 2026-10-23  
**وقت Production SQL:** 2026-10-23 12:02:10 UTC  
**النطاق:** معاينة الرانشيت وأصنافه فقط. لم يُعدّل المساعد main.html أو loader.html أو picker.html.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** المعاينة قراءة فقط؛ فتحها لا يبدأ Picking ولا يحجز المخزون.
- **Architecture Understanding:** التطبيقان يستخدمان Supabase الحالي، وبدء التحضير يظل عبر Edge start-picking الحالية.
- **Database Understanding:** الوصف في items.description وليس run_sheet_details.description. العلاقة الصحيحة هي run_sheet_details.item_id → items.id.
- **Historical Understanding:** تمت قراءة Master CTO Governance OS كاملًا (2606 سطرًا)، وCURRENT_STATE الحالي، ومراجعة Reports468–471. التقارير أدلة تاريخية وليست حالة حالية.
- **Production Understanding:** أعيد فحص أعمدة الجداول والـFK وقائمة Edge Functions الحية في مشروع fiilmooggumokxanwiyx.
- **Current Understanding:** أعيد جلب الملفين من erp-frontend/main؛ SHA مطابق للتحقق السابق.
- **Execution Confidence:** مرتفع في التشخيص والتعديل المقترح؛ لا أدعي نشر التعديل أو نجاح Browser E2E.

## سجل المصادر الحالية

| المصدر | النتيجة |
|---|---|
| erp-frontend/companies/company-1/warehouse/loader.html | SHA 97b83d68a683df77c1e0557838c24a1b4fb65169، 332 سطرًا |
| erp-frontend/companies/company-1/warehouse/picker.html | SHA d483bd15b36585b975b63c2ef641481a01d5d084، 1058 سطرًا |
| Report471 | SHA f07c51491a9444e9859516ac4d757dffab4c952f |
| Report470 | SHA 2d9a99f3004e1502aa1e0f088a4f1ec1bad73474 |
| CURRENT_STATE قبل هذا التحديث | SHA 3ac7f3d978dd86e3c2c93f6bdb4d99cea7972b1e |
| Production database | 2026-10-23 12:02:10.368502+00 |
| start-picking | ACTIVE v35، verify_jwt=true، SHA fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a |
| complete-picking | ACTIVE v18، verify_jwt=true، SHA 14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537 |
| start-loading | ACTIVE v5، verify_jwt=true، SHA afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7 |
| complete-loading | ACTIVE v11، verify_jwt=true، SHA c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286 |

## ما أثبته الفحص

1. معاينة Loader الحالية داخل App._showPreviewModal تعرض رقم الرانشيت وتاريخه وحالته وعدد الأصناف وإجمالي الكمية المحضّرة والقيمة التقديرية وصورة/اسم/كود/وحدة الصنف والكمية المطلوبة والمحضّرة وسعر الوحدة وإجمالي السطر، مع الرجوع وبدء التحميل.
2. Picker الحالي داخل App.openRunsheet لا يزال يستخدم .select('*') لقراءة run_sheet_details، ويعرض فرع المعاينة المختصر؛ لا يوجد pickerPreviewTotalQty في الـblob الحالي.
3. Picker الحالي يدرج بيانات الأصناف داخل HTML وinline handlers دون escaping شامل. هذه فجوة DOM في العرض، وليست دليلًا على فشل دورة Picking نفسها.
4. Production يحتوي items.description وitems.image_url؛ ولا يحتوي run_sheet_details.description. الـFK المؤكد run_sheet_details_item_id_fkey يربط run_sheet_details.item_id بـitems.id.
5. لم يثبت احتياج لأي Migration أو RPC أو Edge Function جديدة.
6. Patch الموصوف في Reports468–471 غير موجود في SHA الحالي لـPicker؛ لا يجوز وصفه بأنه مطبق أو منشور.

## التعديل الجراحي المطلوب من المالك

**لا تعدّل:** main.html أو loader.html أو core.js أو أي Edge/RPC/Schema.  
**الملف الوحيد:** erp-frontend/companies/company-1/warehouse/picker.html  
**SHA المستهدف حاليًا:** d483bd15b36585b975b63c2ef641481a01d5d084.

### Patch A — علاقة الوصف

داخل App.openRunsheet(code)، ابحث عن الأسطر التالية:

    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)

واستبدل الأسطر الثلاثة فقط بـ:

    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)

### Patch B — كتلة المعاينة

داخل App.openRunsheet(code)، بعد فرع استعادة جلسة Picking النشطة، استبدل فقط المقطع من var html = ''; إلى safeHTML(byId('mainContent'), html); بالكتلة الكاملة في Report470، مع تصحيحي Report469 للحالة والنص الفرعي. لا تستخدم النسخة الخام من Report468 دون هذه التصحيحات.

- المرجع الكامل: Report470_PICKER_PREVIEW_PARITY_FRESH_REVALIDATION_20261023.md
- تصحيح الحالة والنص: Report469_PICKER_PREVIEW_PARITY_FINAL_REVALIDATION_20261023.md
- أصل الكتلة والعناصر الآمنة: Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md

### Patch C — App._img(code)

استبدل الدالة وحدها بالنسخة الكاملة في القسم 6 من Report470/Report468، التي تسمح بمصادر HTTP(S) أو المسار المطلق فقط، وتهرب قيمة الخاصية وتعرض placeholder عند رفض الرابط.

### Patch D — App.showItemDetail(code, name, unit, qty, desc)

استبدل الدالة وحدها بالنسخة الكاملة في القسم 7 من Report470/Report468، التي تهرب الاسم والكود والوحدة والوصف، وتتحقق من الكمية وتؤمن رابط الصورة.

**قبل اللصق:** أعد جلب Picker وافحص SHA. إذا تغير، أعد تحديد المحددات على المصدر الجديد. لا تكرر أي Patch إذا كان موجودًا بالفعل.

## اختبارات ما بعد الدمج

1. Open وConfirmed: عرض رقم الرانشيت والتاريخ والحالة وعدد الأصناف وإجمالي الكمية المطلوبة والوصف.
2. Picked: إظهار «مكتمل التحضير» وعدم إظهار زر بدء التحضير.
3. تأكيد أن الوصف يأتي من items.description عبر الـFK الصحيح.
4. اختبار نصوص تحتوي HTML واقتباسات؛ يجب أن تظهر كنص غير منفذ.
5. اختبار صورة مفقودة أو رابط غير مقبول والرانشيت الفارغ.
6. الرجوع يعمل؛ وبدء التحضير لا يظهر إلا في Open/Confirmed ويستدعي startPicking(code).
7. التأكد من عدم تأثر استعادة Dexie للجلسة النشطة وعزل الشركة والصلاحيات.
8. فحص الهاتف وسطح المكتب، وHTML الذي يخدمه Cloudflare، ثم Browser E2E.
9. مقارنة المخزون والحجوزات قبل/بعد فتح المعاينة؛ يجب أن تكون بلا تغيير. لا تُنشأ بيانات تجريبية في Production لهذا التغيير العرضي.

## Production والتغييرات

- لا تغييرات على Production أو Supabase؛ لا حاجة مثبتة لها.
- لم تُنشأ أو تُعدّل أو تُحذف بيانات أعمال أو مخزون أو حجوزات.
- لم يُعدّل أي ملف تشغيل، التزامًا بقاعدة أن المالك يدمج تعديلات التطبيقات المنفصلة.
- تطبيق Patch من المالك، Cloudflare served-artifact parity، وBrowser E2E ما زالت غير مثبتة.

## SELF-AUDIT FINAL

- **What I Proved:** SHA الحالي للملفين؛ اختلاف المعاينة؛ أعمدة Production وعلاقة FK؛ نسخ Edge الحالية؛ استمرار غياب Patch من Picker الحالي.
- **What I Did Not Prove:** أن المالك طبق Patch أو أن Cloudflare يخدمها أو أن Browser E2E نجح.
- **What I Fixed:** لم أعدل ملفات التشغيل؛ ثبتُّ التعديل الجراحي بناءً على المصدر الحالي وفحص Production حديث.
- **What I Initially Missed:** تقارير أقدم افترضت وجود الوصف في جدول التفاصيل؛ المصدر الصحيح هو علاقة items. كما أن حالة Picked يجب ألا تعرض على أنها «مفتوح».
- **What Could Still Be Wrong:** قد تتغير SHA قبل الدمج، وقد تختلف نسخة Cloudflare عن Git، وقد تحتاج علاقة PostgREST إلى التحقق بعد النشر.
- **Final Confidence:** مرتفع في التشخيص والعقد المطلوب؛ لا دليل على التنفيذ التشغيلي.
- **Final Closure Status:** OWNER PATCH READY / DEPLOYED ARTIFACT + BROWSER E2E UNVERIFIED / NOT CLOSED.

## نقطة الاستئناف التالية

أعد جلب Picker. إذا بقي SHA كما هو، طبّق Patches A–D من Report470/468 مع تصحيح Report469، ثم انشر واختبر HTML المقدّم من Cloudflare وBrowser E2E. لا تعدّل Loader أو main.html أو Supabase لهذه الفجوة.
