# Report471 — إعادة مطابقة Loader وPicker مع Production الحي وتثبيت التعديل الجراحي

**وقت فحص Production:** 2026-10-23 11:52:46 UTC  
**النطاق الوحيد:** معاينة الرانشيت وأصنافه في Picker لمواءمتها مع المعاينة الحالية داخل الصفحة في Loader.  
**قاعدة حماية المصدر:** لم أعدّل `loader.html` أو `picker.html` أو `main.html`. ملفات التطبيقات التشغيلية يدمجها المالك بنفسه.  
**تغييرات Production:** لا شيء؛ الفجوة المثبتة عرضية ولا تتطلب تغيير Schema أو RLS أو RPC أو Edge أو بيانات المخزون.

## PRE-CHANGE SELF-AUDIT

- **Business Understanding:** معاينة الرانشيت قراءة فقط، وتعرض الأصناف والكميات قبل بدء Picking. يجب ألا تحجز أو تحرك مخزونًا.
- **Architecture Understanding:** Loader وPicker تطبيقان منفصلان يتشاركان قاعدة البيانات وعمليات Edge الحالية. بدء التحميل والتحضير يظل عبر المسارات الحالية، ولا حاجة إلى Edge Function جديدة.
- **Database Understanding:** Production يثبت أن الوصف في `items.description` وليس في `run_sheet_details`. العلاقة الصحيحة هي `run_sheet_details.item_id → items.id` عبر `run_sheet_details_item_id_fkey`.
- **Historical Understanding:** تمت مراجعة Master Governance OS كاملًا (2606 سطرًا)، وReport465–Report470 ذات الصلة، وCURRENT_STATE.md. التقارير اعتُبرت أدلة تاريخية ثم أُعيدت المطابقة مع المصدر وProduction.
- **Production Understanding:** تمت قراءة قائمة Edge Functions الحية، ومخطط الأعمدة والـFK وسياسات RLS مباشرة من مشروع Supabase `fiilmooggumokxanwiyx`.
- **Current Understanding:** أعيد جلب الملفين من `erp-frontend/main` وتحديد مواضع الكود من النسخ الحالية.
- **Execution Confidence:** مرتفع في تشخيص فرق المعاينة وتصحيح الـDB relation؛ لا توجد أدلة نشر أو متصفح بعد التعديل لأن التعديل نفسه لم يُطبّق على ملف التشغيل.

### سجل القراءة والمصادر

| المصدر | دليل القراءة/الحالة |
|---|---|
| `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` | SHA `b03feec14a417ca9032d714774f2687b4542a373`، 2606 سطرًا؛ تمت قراءة الأجزاء حتى نهاية الملف |
| `CURRENT_STATE.md` | SHA `76bd45b5f8fde55cdc4f8503e44b3a2e220ccc84`، 1268 سطرًا؛ آخر نقاط الاستمرار كانت Reports466–470 |
| `loader.html` | SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`، 332 سطرًا |
| `picker.html` | SHA `d483bd15b36585b975b63c2ef641481a01d5d084`، 1058 سطرًا |
| Loader refactor commit | `152e5b1d22aab94d2cf01070778b357df4701aff`, parent `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| آخر Picker commit المعروف | `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7`, parent `fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407` |
| Production DB | فحص مباشر عند `2026-10-23 11:52:46.223005+00` |
| Production Edge | فحص مباشر في هذه الدورة؛ التفاصيل أدناه |

## 1. الحالة الحالية المثبتة

### Loader

- المعاينة الحالية موجودة داخل الصفحة عبر `RW_UI.safeHTML(RW_UI.byId('mainContent'), h)`.
- `App._showPreviewModal(code, rs, items)` يبدأ عند السطر 162 في المصدر الحالي، لكن المعاينة لم تعد نافذة `Swal.fire` منفصلة؛ هي صفحة معاينة داخل `mainContent`.
- المعاينة تعرض: رقم الرانشيت، التاريخ والحالة، عدد الأصناف، إجمالي الكمية المحضّرة، القيمة التقديرية، صورة/اسم/كود/وحدة الصنف، الكمية المطلوبة والمحضّرة، سعر الوحدة، إجمالي الصنف، وأزرار الرجوع وبدء التحميل.
- مصدر الصورة `RW_ImageCache`؛ زر البدء يستدعي `_startLoadingFromPreview(code)` ثم مسار التحميل الموجود.

### Picker

- `App.openRunsheet(code)` عند السطر 467.
- قراءة `run_sheet_details` عند السطر 516 وما بعده تستخدم حاليًا `.select('*')` ولا تجلب وصف الصنف من العلاقة.
- المعاينة المختصرة تبدأ عند السطر 570 وتنتهي عند السطر 580.
- `App._img(code)` عند السطر 585، و`App.showItemDetail(...)` عند السطر 590.
- فحص المصدر يثبت أن `pickerPreviewTotalQty` غير موجود في النسخة الحالية؛ أي أن Patch المعاينة الوارد في Report468/470 لم يُدمج في هذا الـblob.
- النقص الحالي: لا يوجد إجمالي واضح للكمية المطلوبة في معاينة الرانشيت، ولا يظهر الوصف بصورة دائمة داخل بطاقة الصنف؛ وتُدرج قيم الاسم/الكود/الوحدة/الوصف داخل HTML/inline handler دون escaping شامل. هذا لا يثبت وجود عطل في دورة Picking نفسها، بل فجوة عرض وأمان DOM.

## 2. Production — المطابقة الحية

### Edge Functions ذات الصلة

| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `start-picking` | 35 | ACTIVE | true | `fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a` |
| `complete-picking` | 18 | ACTIVE | true | `14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537` |
| `start-loading` | 5 | ACTIVE | true | `afcfe32707382c57a15ebb744dec61e95a4079abb9ee8d32f479f322091230c7` |
| `complete-loading` | 11 | ACTIVE | true | `c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286` |

### Schema / FK / RLS

- `items.description` موجود، وكذلك `items.image_url`.
- لا يوجد `run_sheet_details.description`.
- الـFK المباشر هو `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id`.
- FK الرانشيت هو `run_sheet_details_runsheet_id_fkey`: `run_sheet_details.runsheet_id → runsheets.id`.
- RLS الحية: `runsheets` و`items` تقيدان القراءة بالشركة الحالية والصلاحية؛ `run_sheet_details` تتطلب وجود رانشيت أب ضمن الشركة الحالية وصلاحية `runsheets` أو `warehouse` أو `reports`.
- لم تُقرأ أو تُكتب بيانات أعمال، ولم تُنشأ بيانات اختبار في Production. لا يوجد مبرر لإنشاء بيانات تجريبية لتغيير عرضي؛ يمكن اختبار المعاينة على بيانات موجودة دون تعديلها.

## 3. Git history / parent

- Commit Loader الحالي `152e5b1d22aab94d2cf01070778b357df4701aff` عنوانه `Refactor preview modal HTML generation`، وparent المثبت `e69c9af4b56d99ba29a4fa74282f78438b9f7010`.
- آخر commit Picker تمت مطابقته `eee31fe44d8fc1cee384ad66a8d7a36be2e3c1b7` عنوانه `Update picker.html`، وparent المثبت `fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407`.
- لا توجد دلالة في commit الحالي على دمج Patch المعاينة من Reports468–470 في Picker؛ فحص الـblob نفسه يثبت غيابه.

## 4. التعديل الجراحي المطلوب من المالك

**لا تلمس:** `main.html`، أو `loader.html`، أو `core.js`، أو Edge/RPC/Schema.  
**الملف الوحيد:** `erp-frontend/companies/company-1/warehouse/picker.html`  
**SHA الذي تمت مطابقته:** `d483bd15b36585b975b63c2ef641481a01d5d084`.

### Patch A — مصدر الوصف الصحيح

ابحث داخل `App.openRunsheet(code)` عن المقطع:

```js
    .from('run_sheet_details')
    .select('*')
    .eq('runsheet_id', rs.id)
```

استبدل هذه الأسطر فقط بـ:

```js
    .from('run_sheet_details')
    .select('*, items!run_sheet_details_item_id_fkey(description)')
    .eq('runsheet_id', rs.id)
```

لا تضف عمودًا ولا تغير Schema.

### Patch B — المعاينة داخل الصفحة

داخل `App.openRunsheet(code)`، بعد فرع استعادة جلسة Picking النشطة، استبدل المقطع الذي يبدأ عند `var html = '';` (السطر 570 حاليًا) وينتهي عند `safeHTML(byId('mainContent'), html);` (السطر 580 حاليًا) بكتلة المعاينة الكاملة الموجودة في:

[Report468 — Patch B الكامل](Report468_PICKER_PREVIEW_PARITY_SCHEMA_CORRECTED_20261023.md)

قبل لصق الكتلة، طبّق تصحيحي الحالة والنص الفرعي من [Report469](Report469_PICKER_PREVIEW_PARITY_FINAL_REVALIDATION_20261023.md)، أو استخدم النسخة الموحّدة في [Report470](Report470_PICKER_PREVIEW_PARITY_FRESH_REVALIDATION_20261023.md). **Report470 هو المرجع المفضل لأنه يجمع التعديلات والتصحيحات.**

التصحيح الحاسم: حالة `Picked` تعرض `مكتمل التحضير`، ولا تعرض زر `بدء التحضير`. الزر متاح فقط لحالتي `Open` و`Confirmed`.

### Patch C — `App._img(code)`

استبدل الدالة وحدها إذا كانت ما زالت على جسمها الحالي عند السطر 585؛ النص الكامل موجود في القسم 6 من Report468 ومثبت ضمن مجموعة Report470. لا تكرر التعديل إذا كان قد دُمج بالفعل.

### Patch D — `App.showItemDetail(code, name, unit, qty, desc)`

استبدل الدالة وحدها إذا كانت ما زالت على جسمها الحالي عند السطر 590؛ النص الكامل موجود في القسم 7 من Report468 ومثبت ضمن مجموعة Report470. لا تكرر التعديل إذا كان قد دُمج بالفعل.

**قاعدة التطبيق:** أعد جلب Picker قبل التعديل، وتحقق من SHA. إذا تغيّر SHA، أعد تحديد المحددات من النسخة الجديدة؛ لا تطبق أرقام الأسطر القديمة عميانيًا.

## 5. أثر التعديل

- يعرض Picker رقم الرانشيت وتاريخه وحالته وعدد الأصناف وإجمالي الكمية المطلوبة.
- يعرض صورة الصنف واسمه وكوده ووحدته وكميته المطلوبة ووصفه، مع تهريب HTML وحماية رابط الصورة.
- النقر على بطاقة الصنف يفتح تفاصيله دون تحويل بيانات قاعدة البيانات إلى HTML قابل للتنفيذ.
- الرجوع يعيد قائمة الرانشيتات.
- بدء التحضير يظل عبر `startPicking(code)` الحالية فقط.
- لا تغيير في حجز المخزون أو حركة المخزون أو دورة Picking/Loading.
- لا توجد حاجة إلى RPC أو Edge Function أو Migration جديدة، ولا إلى بيانات Production تجريبية.

## 6. اختبارات ما بعد الدمج والنشر

1. `Open` و`Confirmed`: معاينة داخل الصفحة، التاريخ والحالة وعدد الأصناف وإجمالي الكمية المطلوبة.
2. `Picked` المسموح بعرضه: يظهر «مكتمل التحضير» ولا يظهر زر البدء.
3. الوصف يأتي من `items.description` عبر FK الصحيح.
4. أسماء/أوصاف تحتوي HTML أو اقتباسات تظهر كنص؛ لا تنفيذ للـmarkup.
5. الصور المفقودة أو ذات الروابط غير المقبولة تعرض placeholder دون كسر الصفحة.
6. الرانشيت الفارغ يعرض empty state.
7. Back وStart يعملان؛ Start فقط للحالات المسموح بها ويستدعي المسار الحالي.
8. جلسة Picking النشطة واستعادة Dexie لا تتأثران.
9. تحقق من الهاتف وسطح المكتب وعدم وجود تمرير أفقي.
10. تحقق من company isolation.
11. بعد نشر المالك: افحص HTML الذي يخدمه Cloudflare وقارنه بالمصدر، ثم نفذ Browser E2E.
12. قارن المخزون والحجوزات قبل/بعد فتح المعاينة؛ يجب ألا يتغيرا. لا تستخدم معاملات حية كـfixtures ولا تنشئ بيانات إنتاجية اصطناعية لمجرد اختبار شاشة قراءة.

## 7. ما نُفذ وما لم يُنفذ

- **نُفذ:** قراءة Master OS؛ مراجعة التقارير المتسلسلة 465–470؛ إعادة جلب Loader وPicker؛ قراءة Git commits والـparents؛ مطابقة Edge وSchema وFK وRLS في Production.
- **لم يُنفذ:** تعديل ملفات التطبيق (لأن المالك هو من يدمجها)، أو أي تغيير Production، أو نشر Cloudflare، أو Browser E2E بعد Patch.
- **لم تتغير:** بيانات الأعمال والمخزون والحجوزات وSchema/RLS/RPC/Edge.
- **السبب في عدم إجراء تعديل Production:** العيب المثبت عرضي في Picker، وكل متطلبات البيانات اللازمة متاحة من Schema الحالي وسياسات القراءة الحالية.

## SELF-AUDIT FINAL

- **What I Proved:** Loader الحالي يعرض معاينة داخل الصفحة وبحقول أكثر؛ Picker الحالي ما زال يملك معاينة مختصرة؛ الـFK والوصف وسياسات RLS ونسخ Edge الحالية مثبتة مباشرة.
- **What I Did Not Prove:** أن المالك طبق التعديلات، أو أن Cloudflare يخدم نسخة مطابقة، أو أن Browser E2E بعد التعديل نجح.
- **What I Fixed:** لم أعدّل ملفات التشغيل؛ أعدت تثبيت التعديل الجراحي الصحيح، ومصدر الوصف الصحيح، وحالة `Picked`، وحددت مواضع التطبيق الدقيقة.
- **What I Initially Missed:** تقارير سابقة أقدم كانت تستهدف SHA أقدم لـLoader؛ أُعيد التحقق من SHA الحالي وcommit/parent بدل الاعتماد على تلك الأرقام.
- **What Could Still Be Wrong:** بعد تطبيق Patch قد يظهر اختلاف في PostgREST nested relation أو في HTML المنشور؛ يجب التحقق منهما بعد النشر.
- **Final Confidence:** مرتفع في التشخيص ومجموعة التعديلات المقترحة؛ التحقق التشغيلي بعد التطبيق ما زال مفتوحًا.
- **Final Closure Status:** `OWNER SURGICAL PATCH READY / CLOUDflare SERVED PARITY + BROWSER E2E OPEN / NOT CLOSED`.

## نقطة الاستئناف الدقيقة للمساعد القادم

1. أعد جلب `erp-frontend/companies/company-1/warehouse/picker.html` من `main` وتحقق من SHA.
2. إذا لم يتغير، طبّق Patch A ثم Patch B وC وD كما هي في Report470/468، مع تصحيحات Report469 المدمجة.
3. لا تعدّل Loader أو main.html أو Supabase لهذه الفجوة.
4. بعد دمج المالك ونشر الواجهة، تحقق من served HTML ثم نفذ اختبارات المتصفح الـ12 أعلاه.
5. لا تغلق المهمة قبل إثبات Browser E2E وserved-artifact parity.
