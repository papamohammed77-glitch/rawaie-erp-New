# Report473 — إعادة تحقق جلسة معاينة Picker مقابل Loader

**التاريخ:** 2026-10-23  
**النطاق:** عرض معاينة الرانشيت والأصناف في Picker فقط.  
**قاعدة الملكية:** المالك وحده يطبق تعديل ملف التطبيق التشغيلي. لم يتم تعديل picker.html أو loader.html أو main.html أو core.js.  
**مصدر التعديل الجراحي الكامل:** [Report471](Report471_LOADER_PICKER_PREVIEW_PARITY_LIVE_REVALIDATION_20261023.md). Report472 تاريخي مساعد؛ عند اختلاف التعليمات، تُستخدم كتل Report471 الكاملة المصححة.

## الحالة الحالية المثبتة

| المصدر | الحالة |
|---|---|
| Loader | SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`، 1 سطرًا |
| Picker | SHA `d483bd15b36585b975b63c2ef641481a01d5d084`، 1 سطرًا |
| CURRENT_STATE قبل هذا التحديث | SHA `56c3ec867bfacc55bd3f95ae8c38c8c3702e9fc6` |
| سجل الذاكرة 117-02 قبل هذا التحديث | SHA `f848a39a3e9550e47d0b46ebd60f27ab6ca2af1c` |
| Supabase project | `fiilmooggumokxanwiyx` |
| items.description / items.image_url | موجودان؛ فحص SQL مباشر |
| run_sheet_details.description | غير موجود |
| FK `run_sheet_details_item_id_fkey` | موجود |
| FK `run_sheet_details_runsheet_id_fkey` | موجود |
| حالة الرانشيت الحالية | `Picked: 2`؛ لا توجد حالات أخرى في العد الحالي |
| تغييرات Production / البيانات | لا شيء |

## الفجوة المؤكدة

- Loader يحتوي معاينة تفصيلية داخل الصفحة تشمل ملخص الرانشيت ومعلومات الأصناف والكمية المحضّرة والقيمة.
- Picker ما زال في SHA الحالي يستخدم `.select('*')` على `run_sheet_details` ومعاينة مختصرة.
- وصف الصنف مصدره `items.description` عبر FK، وليس عمودًا في `run_sheet_details`.
- مسار جلسة Picking النشطة يقرأ حاليًا `items[i].description`؛ يلزم تصحيح هذا السطر بالتزامن مع إضافة العلاقة المتداخلة.
- لم يثبت تطبيق المالك للتعديل، ولم يثبت تطابق Cloudflare مع Git أو نجاح Browser E2E.

## التعديل الجراحي المعتمد

**الملف الوحيد:** `erp-frontend/companies/company-1/warehouse/picker.html`  
**SHA:** `d483bd15b36585b975b63c2ef641481a01d5d084`

نفّذ Patches A وA2 وB وC وD كاملةً كما هي في Report471 فقط:

1. **Patch A — App.openRunsheet(code):** استبدال استعلام التفاصيل ليطلب `items!run_sheet_details_item_id_fkey(description)`.
2. **Patch A2 — App.openRunsheet(code):** استبدال سطر وصف جلسة التحضير النشطة بقراءة `(items[i].items && items[i].items.description) || ''`.
3. **Patch B — App.openRunsheet(code):** استبدال كتلة المعاينة المختصرة فقط، من `var html = '';` حتى `safeHTML(byId('mainContent'), html);`، بالكتلة الكاملة في Report471. لا تستبدل الدالة كاملة ولا حدّ إغلاق `then`.
4. **Patch C — App._img(code):** استبدال الدالة وحدها بنسخة Report471 الآمنة للصور.
5. **Patch D — App.showItemDetail(code, name, unit, qty, desc):** استبدال الدالة وحدها بنسخة Report471 التي تهرب النصوص وتتحقق من رابط الصورة.

**مهم:** أعد جلب Picker وافحص SHA قبل اللصق. إذا تغير SHA أو أصبح أي Patch موجودًا، لا تطبّق رقعة مكررة؛ أعد تحديد المحددات من المصدر الحالي.

## Production والبيانات

لا يوجد تعديل Production مبرر لهذه الفجوة. لم تُنشأ بيانات تجريبية في Production، ولم تُحذف أي بيانات قديمة؛ لا توجد أدلة على أنها خاطئة أو تجريبية. لا تنشئ RPC أو Edge Function أو جدولًا أو RLS إضافيًا لهذه المعاينة.

## اختبارات الإغلاق المطلوبة

- Open وConfirmed في بيئة اختبار معتمدة: رقم الرانشيت وتاريخه وحالته وعدد الأصناف وإجمالي الكمية والوصف.
- Picked: عرض «مكتمل التحضير» وعدم إظهار زر بدء التحضير.
- الوصف من `items.description` عبر FK المثبت.
- قيم HTML والاقتباسات تظهر كنص؛ لا تنفيذ HTML/handlers.
- الصور المقبولة والروابط المرفوضة والصورة البديلة.
- الرانشيت الفارغ، الرجوع، واستعادة جلسة Dexie النشطة.
- صلاحيات الشركة وعزل بياناتها، الهاتف وسطح المكتب، وعدم وجود أخطاء Console/Network.
- تحقق من Cloudflare served HTML وBrowser E2E.
- مقارنة المخزون والحجوزات قبل/بعد المعاينة: لا تغيير.

## SELF-AUDIT

**CONFIRMED:** SHA الحالي للملفين؛ فرق مستوى المعاينة؛ عقد وصف الصنف وعلاقات FK؛ عدّ Production الحالي.  
**UNKNOWN:** تطابق Cloudflare مع Git.  
**UNVERIFIED:** دمج المالك، النشر، Browser E2E، وحالات Open/Confirmed في المتصفح؛ لا توجد تلك الحالات في عدّ Production الحالي.  
**CONFLICT:** تقارير أقدم تضمنت قراءة `run_sheet_details.description`؛ لا تستخدمها. Report471 هو حزمة الاستبدال الكاملة المصححة.  
**PRODUCTION CHANGE:** لا شيء.  
**CLOSURE:** `OWNER PATCH READY / SOURCE + DB CONTRACT CONFIRMED / DEPLOYMENT + BROWSER E2E UNVERIFIED / NOT CLOSED`.

## نقطة الاستئناف الدقيقة

ابدأ بقراءة CURRENT_STATE ثم هذا التقرير وReport471. أعد جلب Picker وراجع SHA. إذا بقي `d483bd15b36585b975b63c2ef641481a01d5d084`، طبّق Patches A/A2/B/C/D من Report471، ثم اطلب من المالك نشر النسخة واختبارها. لا تلمس Loader أو main.html أو core.js أو Supabase لهذه الفجوة.
