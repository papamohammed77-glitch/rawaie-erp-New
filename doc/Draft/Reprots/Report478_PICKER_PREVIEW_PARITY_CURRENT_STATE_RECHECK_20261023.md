# Report478 — إعادة تحقق الحالة الحالية لمعاينة Picker مقابل Loader

**وقت التحقق:** 2026-10-23 14:58:58 UTC (SQL)، المصدر جُلب من الفرع الافتراضي أثناء هذه الجلسة.  
**الحالة:** ROOT CAUSE RECONFIRMED / OWNER PATCH READY / SOURCE NOT PATCHED / DEPLOYMENT UNKNOWN / NOT CLOSED.

## 1. مصدر الحقيقة الحالي

| المصدر | نتيجة التحقق الحالي |
|---|---|
| مستودع التطبيق | `papamohammed77-glitch/erp-frontend`, HEAD `152e5b1d22aab94d2cf01070778b357df4701aff` |
| Parent لآخر commit | `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| Picker الحالي | SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1,058 سطرًا |
| Loader الحالي | SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 سطرًا |
| آخر commit يخص Picker في سجل الملف | `fbcd4c7e1845236455f026eb3f7ae0ccfa8ba407`; لم يتغير Picker منذ بصمة Report477 |
| الحوكمة | تمت إعادة قراءة `MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` كاملًا؛ SHA `b03feec14a417ca9032d714774f2687b4542a373`, 2,606 سطرًا |
| الحالة قبل هذه الجلسة | `CURRENT_STATE.md` SHA `382e6ace2086739719e7dca13f89f8a0fba74736`; آخر checkpoint يذكر Report477 |
| سجل الذاكرة قبل هذه الجلسة | `RAWAEA_PROJECT_MEMORY_117-02.md` SHA `e3b41cef823eb104f1ce8979c64a68f6b7b6843a` |
| تقرير التنفيذ الموحد السابق | Report477 blob SHA `1707a3dbbcac68728817aa2b67609f982159ece3` |

تمت مراجعة التقارير السابقة كأدلة تاريخية لا كحالة تشغيلية. Report477 يبقى مرجع الرقع الكامل لأن SHA المصدر التشغيلي لم يتغير، ولم يثبت تطبيق المالك لأي Patch.

## 2. المقارنة الوظيفية المثبتة

**Loader الحالي** يعرض معاينة responsive تشمل رقم الرانشيت والتاريخ والحالة، عدد الأصناف، إجمالي الكمية المحضّرة، القيمة التقديرية، وبطاقات تعرض كود الصنف ووحدته والكميات وسعر الوحدة والإجمالي، مع أزرار مرتبطة عبر `addEventListener`.

**Picker الحالي** في `App.openRunsheet(code)` لا يزال يعرض معاينة مختصرة: رقم الرانشيت وعدد الأصناف وزر البدء وبطاقات مختصرة. لا يعرض وصف الصنف أو إجمالي الكمية والقيمة، ويربط بطاقة الصنف عبر inline `onclick` مع escaping جزئي.

### المحددات الحالية (بعد إعادة جلب المصدر)

- **A — App.openRunsheet(code)، قرابة السطر 517:** `.from('run_sheet_details').select('*').eq('runsheet_id', rs.id)`؛ لا يحمّل علاقة وصف الصنف.
- **A2 — App.openRunsheet(code)، قرابة السطر 532:** `description: items[i].description || ''`؛ يقرأ وصفًا من صف `run_sheet_details` رغم عدم وجود العمود.
- **B — App.openRunsheet(code)، كتلة المعاينة بعد فرع الجلسة النشطة، قرابة الأسطر 570–580:** HTML المختصر وinline handler.
- **C — App._img(code)، قرابة الأسطر 585–588:** إدراج رابط الصورة مباشرةً داخل `src` مع `onerror` inline.
- **D — App.showItemDetail(code, name, unit, qty, desc)، قرابة الأسطر 590–594:** إدراج الاسم والكود والوحدة والوصف ورابط الصورة في HTML دون escaping/URL allowlist.
- **E — renderActiveSession()، قرابة السطر 660:** عند إزالة inline `onerror` يجب ربط fallback للصور بحدث JavaScript كي لا تتراجع صور الجلسة النشطة.

## 3. إعادة تحقق Production — قراءة فقط

تم تنفيذ استعلام SQL مباشر على مشروع Supabase `SMART ERP / fiilmooggumokxanwiyx` عند `2026-10-23 14:58:58.392162+00`:

- PostgreSQL `17.6`.
- `items=18`, `run_sheet_details=12`, `runsheets=2`.
- الحالات الحالية: `Picked=2` فقط؛ لا توجد حالة `Open/Confirmed` في العد الحالي، لذلك لا يُنشأ اختبار بدء تحضير على Production.
- `items.description` موجود؛ `items.image_url` موجود.
- `run_sheet_details.description` غير موجود.
- FK `run_sheet_details_item_id_fkey` موجود، وFK `run_sheet_details_runsheet_id_fkey` موجود.

**قرار Production:** لا DDL، ولا تعديل RLS/grants، ولا RPC أو Edge Function جديدة أو معدلة، ولا بيانات تجريبية أو حذف بيانات. الفجوة من شكل الاستعلام والعرض داخل Picker؛ لا توجد حاجة مثبتة لتغيير Production.

## 4. التعديل الجراحي الوحيد المطلوب من المالك

**الملف:** `erp-frontend/companies/company-1/warehouse/picker.html`  
**ممنوع التعديل:** `loader.html`, `main.html`, `core.js`، وقاعدة Production لهذه الفجوة.

استخدم **Report477 فقط** للحصول على النصوص البديلة الكاملة؛ فهو يتضمن A/A2/B/C/D/E ولا يحتاج إلى تجميع من تقارير قديمة:

1. **A:** داخل `App.openRunsheet(code)`، استبدل استعلام التفاصيل `.select('*')` ليجلب `items!run_sheet_details_item_id_fkey(description)`.
2. **A2:** استبدل سطر الوصف وحده إلى `description: (items[i].items && items[i].items.description) || ''`.
3. **B:** استبدل كتلة المعاينة غير النشطة فقط، من `var html = '';` بعد `return` الخاص بالجلسة النشطة وحتى `safeHTML(byId('mainContent'), html);` قبل إغلاقات `.then`. لا تستبدل الدالة أو أقواس الإغلاق.
4. **C:** استبدل `App._img(code)` وحدها بنسخة Report477 التي تتحقق من URL وتزيل inline handler.
5. **D:** استبدل `App.showItemDetail(code, name, unit, qty, desc)` وحدها بنسخة Report477 الآمنة.
6. **E:** أضف ربط فشل الصور المحدد في Report477 داخل `renderActiveSession()` دون تغيير المؤقت أو منطق الجلسة.

**قبل اللصق:** أعد جلب Picker وتأكد أن SHA ما زال `d483bd15b36585b975b63c2ef641481a01d5d084`. إذا تغيّر أو كان Patch موجودًا، لا تطبقه مرة ثانية؛ أعد تحديد الفجوة من المصدر الحالي.

## 5. الاختبار المطلوب قبل الإغلاق

يجب إجراء الاختبارات في Staging ببيانات مصرح بها، لا في Production:

- حالات `Open` و`Confirmed`: زر بدء التحضير يظهر فقط لهما؛ حالات `Picking/Picked/Loading` لا تُظهر إجراء بدء غير مسموح.
- وصف الصنف يأتي من `items.description` عبر FK الصحيح.
- مقارنة بطاقة Loader وPicker: كود، اسم، وحدة، وصف، مطلوب، محضّر، سعر الوحدة، قيمة السطر، الإجماليات، الحالة والتاريخ.
- اختبار أسماء/أوصاف تحتوي علامات اقتباس ووسوم HTML؛ يجب عرضها كنص لا تنفيذها.
- اختبار روابط `https:`, `http:`, المسار النسبي، `javascript:`, `data:`, `//host`، والصورة المعطلة.
- فتح بطاقة بالفأرة ولوحة المفاتيح، والرجوع، والرانشيت الفارغ، واستعادة جلسة Dexie.
- اختبار صلاحية المستخدم وعزل الشركة.
- قياس `stock_branches.qty`, `allocated_qty`, `inventory_log` قبل وبعد المعاينة؛ يجب ألا يتغير أي منها.
- فحص أخطاء Console/Network، ثم التحقق من HTML الذي يقدمه Cloudflare وتشغيل Browser E2E مصادق عليه.

## 6. فصل درجات اليقين

- **CONFIRMED:** بصمات المصدر الحالية، استمرار العناصر المعيبة، شكل عقد الوصف في قاعدة البيانات، وجود مفاتيح الربط، وعداد Production.
- **UNKNOWN:** هل Cloudflare يقدم نفس HTML الموجود في Git.
- **UNVERIFIED:** تطبيق المالك للرقع، Staging، Browser E2E، ونشر النسخة المعدلة.
- **CONFLICT:** التقارير الأقدم التي تقترح Patch B/D مختلفة؛ لا تستخدمها بدل Report477.
- **NOT DONE:** لم يطبق المالك الرقع بعد؛ لا يعلن الإغلاق.

## 7. نقطة الاستئناف التالية

ابدأ بقراءة `CURRENT_STATE.md` ثم أحدث `LAST VERIFIED EVENT` وهذا التقرير وReport477. أعد جلب Picker وراجع SHA. إذا بقي كما هو، نفّذ رقع المالك A→A2→B→C→D→E من Report477 فقط، اختبر Staging، تحقق من عدم تغير المخزون والحجوزات والسجلات، ثم تحقق من النسخة المنشورة واختبار Browser E2E. بعد ذلك حدّث الحالة بناءً على أدلة النشر والتشغيل، لا على نجاح تعديل المصدر وحده.
