# Report486 — تصحيح نطاق المهمة والتحقيق التنفيذي في تكامل Loader مع Picker
**التاريخ:** 2026-10-24  
**معرّف الحدث:** LVE-2026-10-24-487  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend` / `main`  
**مستودع الحوكمة:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**الحالة:** SCOPE RECONCILED / ROOT CAUSES CONFIRMED FROM SOURCE + LIVE SCHEMA / OWNER PATCH CONSOLIDATED / SOURCE NOT MODIFIED / NOT DEPLOYED / NOT CLOSED

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** Loader مسؤول عن تنفيذ التحميل للكمية التي جرى تحضيرها؛ Picker مسؤول عن التحضير والكمية المطلوبة. المقصود هو تقارب تجربة عرض تفاصيل الرانشيت والصنف، لا نقل دورة التحضير إلى التحميل ولا تغيير دلالة الكميات.
- **Architecture Understanding:** التطبيقان ملفا HTML منفصلان. Loader يعتمد `core.js` و`RW_API` و`RW_ImageCache`; Picker يستخدم Supabase client وDexie. يجب الحفاظ على واجهة Loader وعقد التحميل الحالي، مع إصلاح الاستعلام والعرض محليًا حيث يكفي ذلك.
- **Database Understanding:** فحص Production المباشر يؤكد أن الوصف والصورة في `public.items`، وأن `run_sheet_details.item_id` يرتبط بـ`items.id`. لا يوجد `description` أو `image_url` أو `notes` في `run_sheet_details`. لا توجد حاجة إلى migration لمجرد إظهار بيانات الصنف.
- **Historical Understanding:** تمت مراجعة `CURRENT_STATE.md` أولًا، ثم Report485 وReport482 وReport483 وReport481، ومصدرَي Git الحاليين والتاريخيين. التقارير السابقة أدلة تاريخية للمقارنة وليست إثباتًا على التطبيق أو النشر.
- **Production Understanding:** قراءة SQL مباشرة من مشروع SMART ERP `fiilmooggumokxanwiyx` في `2026-10-23 23:36:07 UTC`، وقراءة Registry مباشرة. لم تُجرَ أي كتابة في Production.
- **Current Understanding:** أعيد جلب الملفين كاملين من `erp-frontend/main`: Loader SHA `97b83d68a683df77c1e0557838c24a1b4fb65169` (332 سطرًا)، Picker SHA `d483bd15b36585b975b63c2ef641481a01d5d084` (1,058 سطرًا)، وCore SHA `ff2f581d9900543c16f7cb026e13446520c0329d` (773 سطرًا).
- **Execution Confidence:** مرتفعة في تحديد فجوات المصدر وعقد البيانات؛ لا يمكن إعلان الإغلاق لأن رقعة المصدر لم تُطبّق، ولم يثبت artifact المنشور أو browser E2E.

### تعارض نطاق المهمة — حُسم قبل أي تعديل

رسالة المالك الحالية تحدد صراحةً:
- **الملف المستهدف:** `companies/company-1/warehouse/loader.html`
- **المرجع للمطابقة:** `companies/company-1/warehouse/picker.html`

وهذا عكس اتجاه المهمة في القسم التنفيذي داخل `doc/Draft/Reprots/writing-block.md` (SHA `de3f4640a6e706f23eba44b3d99fae9158ffe273`) الذي يجعل Loader مرجعًا وPicker هدفًا. اتُّبع تحديد المالك الأحدث والصريح لتحديد اتجاه المقارنة، وسُجل التعارض بدل تطبيق رقعة Picker القديمة على الملف الخطأ.

لكن وثيقة الحوكمة نفسها تحظر على المساعد تعديل الملفين التشغيليين مباشرة، وتطلب تجهيز رقعة مصدرية يطبقها المالك. لذلك لم أعدّل Loader أو Picker أو Core أو Main، ولم أعدّل Production.

## 2. سجل المصادر والبصمات

| المصدر | الدليل الحالي |
|---|---|
| Operational HEAD | `152e5b1d22aab94d2cf01070778b357df4701aff` |
| Parent | `e69c9af4b56d99ba29a4fa74282f78438b9f7010` |
| HEAD commit | `Refactor preview modal HTML generation`; diff يغير `loader.html` فقط |
| Loader الحالي | SHA `97b83d68a683df77c1e0557838c24a1b4fb65169`, 332 lines |
| Picker الحالي | SHA `d483bd15b36585b975b63c2ef641481a01d5d084`, 1,058 lines |
| Core الحالي | SHA `ff2f581d9900543c16f7cb026e13446520c0329d`, 773 lines |
| Historical Picker | `rawaie-erp-review/PWA/warehouse/picker.html`, SHA `7626ba320021a607854bf219f4bacd81fc3d1d92`, 623 lines |
| Historical Loader | `rawaie-erp-review/PWA/warehouse/loader.html`, SHA `7e61b04d0d9a480d43763e8b7b21f9cbed78409a`, 266 lines |
| Prompt | `doc/Draft/Reprots/writing-block.md`, SHA `de3f4640a6e706f23eba44b3d99fae9158ffe273`, 1,410 lines |

التحقق الساكن للنسختين الحاليّتين: تم استخراج كتلة JavaScript المضمنة كاملة من كل HTML وتمريرها إلى parser في بيئة JavaScript؛ كلاهما `PARSE_OK`. هذا يثبت سلامة تحليل المصدر الحالي فقط، وليس سلامة الرقعة المستقبلية أو سلوك المتصفح.

## 3. Production — فحص حي للبيانات والعقود

**المشروع:** SMART ERP / `fiilmooggumokxanwiyx`  
**وقت الاستعلام:** `2026-10-23 23:36:07.478078+00`  
**PostgreSQL:** `17.6`

- `public.items`: 18 صفًا؛ يحتوي `description` و`image_url`.
- `public.run_sheet_details`: 12 صفًا؛ يحتوي `item_id`, `runsheet_id`, `item_code`, `item_name`, `unit`, `unit_price`, `qty_ordered`, `qty_picked`, `qty_loaded`؛ لا يحتوي `description` أو `image_url` أو `notes`.
- `public.runsheets`: صفّان، والحالتان المرصودتان `Picked=2`؛ يحتوي `company_id`, `status`, `loader_id`, `runsheet_code`.
- FK `run_sheet_details_item_id_fkey`: `run_sheet_details.item_id → items.id`.
- FK `run_sheet_details_runsheet_id_fkey`: `run_sheet_details.runsheet_id → runsheets.id`.
- سياسات RLS الحالية تتضمن SELECT للمستخدم `authenticated` على تفاصيل الرانشيت ضمن الشركة وبالصلاحيات؛ لا تمنح الواجهة سببًا لإضافة كتابة مباشرة إلى تفاصيل الرانشيت.
- امتياز UPDATE على `run_sheet_details` غير متاح لـ`authenticated` في نتائج `information_schema.role_table_grants`؛ المتاح هو `service_role` وأدوار الإدارة. لا ينبغي أن تعتمد الرقعة العرضية على تحديث هذا الجدول.

العلاقة المعتمدة لجلب الوصف والصورة هي:
```js
.select('*, items!run_sheet_details_item_id_fkey(description, image_url)')
```
لا تضف عمودًا أو FK أو RPC أو Edge Function لمعالجة نقص العرض هذا.

### Edge dependency — لقطة مباشرة

`complete-loading`: version `11`, `ACTIVE`, `verify_jwt=true`, `ezbr_sha256=c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286`.

المصدر المنشور يرسل إلى `complete_runsheet_loading` حقول `item_code` و`loaded_qty` فقط، ويرفض `loaded_qty <= 0`. هذا لا يتطلب تعديلًا لإصلاح عرض تفاصيل الصنف، لكنه تعارض تعاقدي منفصل يجب ألا يختبئ داخل رقعة الواجهة.

### Logs / Runtime

استعلام السجلات المباشر في نافذة `2026-10-23 23:00 UTC` إلى `2026-10-23 23:34 UTC` لم يُرجع أحداثًا مطابقة لـ`runsheets` أو `run_sheet_details`. توجد في الأدلة التاريخية طلبات REST ناجحة بتاريخ 2026-10-23 صباحًا، لكنها لا تحدد الصفحة التي أصدرتها ولا تثبت بصمة HTML المنشورة. لذلك:
- Cloudflare served artifact identity: **UNKNOWN**
- Authenticated browser E2E: **NOT VERIFIED**
- Production runtime after patch: **NOT RUN** لأن الرقعة لم تطبق.

## 4. الفجوات المثبتة في Loader الحالي

1. **نطاق الشركة غير صريح في قوائم الرانشيتات:** استعلاما `renderPendingTab` يرشحان الحالة والـloader، لكنهما لا يضيفان `.eq('company_id', this.currentUser.company_id)`.
2. **البحث غير مقيد بالشركة ولا يعالج الخطأ بوضوح:** `onSearchInput` يبحث في `Picked/Loading` حسب رقم الرانشيت دون `company_id`، ولا يفحص `r.error`.
3. **فتح الرانشيت غير مقيد بالشركة ولا يرفض جلسة محمّل آخر:** `openRunsheet` يقرأ برقم الرانشيت فقط؛ إذا كانت الحالة Loading لمحمّل آخر فلا يوجد رفض صريح قبل مسار العرض.
4. **استعلام التفاصيل لا يجلب علاقة الصنف:** `openRunsheet` يستخدم `.select('*')` من `run_sheet_details` فقط، فلا يصل إلى `items.description/image_url`.
5. **بطاقات معاينة Loader ليست قابلة لفتح تفاصيل الصنف:** `_showPreviewModal` يعرض ملخصات وبطاقات، لكنه لا يضيف حدث فتح التفاصيل ولا دعم لوحة المفاتيح.
6. **لا توجد نافذة تفاصيل صنف مماثلة لتجربة Picker:** لا توجد دالة `_showItemDetail` في Loader الحالي. مودال تحرير الكمية في `editLoadedItem` يعرض صورة صغيرة ولا يعرض كود الصنف أو الوصف.
7. **مسارات الصور تعتمد على Core helper:** `RW_ImageCache.getImageHTML` يُستخدم في المعاينة وreadonly والجلسة النشطة ومودال تعديل الكمية. helper الحالي يركّب URL الصورة داخل HTML مع inline error handler؛ يجب تجنب توسيع هذا السلوك في المسارات المعدلة.
8. **HTML النصي القديم خارج المعاينة:** بعض عناصر `_card`, `renderSearchDropdown`, `_renderReadonly`, و`editLoadedItem` تُدخل قيمًا ديناميكية في HTML دون حماية شاملة. الرقعة المقترحة أدناه تحصّن نقاط المسار المحدد، لكنها لا تعني اكتمال تدقيق XSS لكل الملف.

### ما يجب الحفاظ عليه

- فتح المعاينة لا يبدأ تحميلًا ولا يغير `stock_branches.qty` أو `allocated_qty` أو `inventory_log`.
- لا تغيير لدلالات `Picked` و`Loading`، أو حساب الكمية المحضّرة في Loader.
- لا تغيير لعقد `start-loading` أو `complete-loading` أو إكمال التحميل.
- تبقى جلسة التحميل النشطة، تحرير `qty_loaded`، مؤقت الجلسة، الإلغاء، وإعادة تحميل القائمة سليمة.
- لا نسخ لتطبيق Picker كاملًا ولا تعديل لـ`picker.html` أو `core.js` أو `main.html`.

## 5. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل / الإجراء |
|---|---|---|
| قائمة الرانشيتات وحالاتها الحالية | RETAINED | تبقى شروط `Loading` و`Picked` وترتيب النتائج |
| Company isolation في القراءة | MISSING / HARDENED | إضافة `company_id` إلى القائمة والبحث والفتح |
| رفض Loading المملوك لمحمّل آخر | MISSING / ADDED | فحص `loader_id` قبل فتح الجلسة أو العرض |
| جلب وصف وصورة الصنف | MISSING / MOVED TO JOIN | استعمال FK الموجود بدل عمود غير موجود في التفاصيل |
| عرض ملخص الكمية المحضّرة والقيمة | RETAINED | يبقى حساب Loader مبنيًا على `qty_picked` |
| الضغط على بطاقة الصنف | MISSING / ADDED | `data-loader-item-index` وربط أحداث click/keyboard |
| نافذة تفاصيل الصنف | MISSING / ADDED | دالة Loader-local آمنة، لا تعديل Picker |
| fallback للصور | INCOMPLETE / HARDENED | Patch G محلي في Loader بدل تعديل Core المشترك |
| حركة المخزون عند فتح المعاينة | INTENTIONALLY ABSENT | يجب أن يبقى delta صفرًا |
| عقد الصفر والملاحظات في إتمام التحميل | SEPARATE OPEN DEFECT | لا يُحل ضمن parity patch؛ يتطلب Closure Unit مستقلة |
| نشر Cloudflare/browser runtime | UNKNOWN | لا دليل artifact أو E2E بعد الرقعة |

## 6. الرقعة الجراحية المعتمدة — دون تعديل ملفات التشغيل

### Base guard

لا تطبق أي رقعة إلا بعد إعادة جلب `loader.html` والتأكد من أن SHA ما زال:
`97b83d68a683df77c1e0557838c24a1b4fb65169`.

إذا تغير SHA، أعد مقارنة المصدر الجديد قبل إعادة استخدام أي سطر أو محدد. لا تطبق رقع Report485 الخاصة بـPicker على Loader.

### ترتيب التطبيق

1. **Patch G — أمان الصور أولًا**: من Report483، القسم 8، أضف `_loaderImageHTML` و`_bindLoaderImageFallbacks` إلى كائن App، ثم استبدل استدعاءات الصور في `_showPreviewModal` و`_renderReadonly` و`renderActiveSession`، واربط fallback بعد كل `safeHTML`. عدّل فحص فشل الصورة في modal handlers التي ستُضاف في Patch E/F. النص الكامل متاح في [Report483](https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report483_LOADER_DAILY_REVALIDATION_LOADING_CONTRACT_CONFLICTS_20261023.md).
2. **Patch A1/A2 — نطاق الشركة**: من Report482، القسم 4، أضف `company_id` إلى استعلامي قائمة الرانشيتات واستعلام البحث، مع فحص `r.error` في البحث.
3. **Patch B — `openRunsheet`**: استبدل الدالة كاملة بالنص في Report482 القسم 5. هذا يضيف company scope، وفحص أخطاء القراءة، والتحقق من ملكية Loading قبل فتح الجلسة، وجلب `items.description/image_url` من FK.
4. **Patch C — `_startSession`**: استبدل الدالة بالنص في Report482 القسم 6، لحفظ وصف وصورة الصنف داخل الجلسة دون تغيير الكميات أو lifecycle.
5. **Patch D — تفاعل بطاقات المعاينة**: طبّق Report482 القسم 7 لإضافة إرشاد الضغط، و`role=button` و`tabindex`، وربط click وEnter/Space.
6. **Patch E — `_showItemDetail`**: أضف الدالة كاملة من Report482 القسم 8، مع escaping وURL validation وfallback للصورة.
7. **Patch F — `editLoadedItem`**: استخدم البديل الكامل في Report482 لقسم تعديل الكمية ليعرض صورة أكبر وكود الصنف ووصفه، مع الحفاظ على إدخال الكمية والملاحظات كما هما.
8. بعد التطبيق، راجع كامل `loader.html` من جديد ولا تطبق رقعة على محدد قد تغير.

**مهم:** تقريرا Report482 وReport483 يحتويان النصوص المصدرية الكاملة لكل patch؛ هذا التقرير يصحح اتجاه النطاق ويربطها بترتيب واحد. لم يُكتب أي من هذه البدائل إلى ملف التشغيل في هذه الدورة.

## 7. الاختبارات المطلوبة بعد تطبيق المالك

1. فحص JavaScript الكامل في HTML بعد دمج جميع الرقع، لا المقاطع المنفردة فقط.
2. اختبر قائمة `Picked` و`Loading`، والبحث، والفتح، والعودة للقائمة.
3. اختبر بطاقة صنف بالنقر وEnter وSpace؛ تحقق من الاسم والكود والوحدة والوصف والصورة والكمية المطلوبة والمحضّرة والسعر والإجمالي.
4. اختبر مستخدمًا من الشركة الصحيحة ومستخدمًا من شركة أخرى، وLoading مسندًا إلى محمّل آخر؛ المتوقع رفض الوصول/الفتح غير المسموح.
5. اختبر رابط صورة HTTPS صالحًا، ورابطًا نسبيًا يبدأ بـ`/`، ورابطًا تالفًا، و`javascript:` و`data:` و`//host`; يجب عدم إدراج URL غير مسموح به أو ترك صورة مكسورة دون fallback.
6. اختبر تحرير الكمية والملاحظات والمؤقت والإلغاء وإعادة فتح التطبيق؛ تأكد أن تعديل العرض لم يكسر الجلسة النشطة.
7. قارن قبل/بعد المعاينة `stock_branches.qty` و`allocated_qty` و`inventory_log`: المتوقع **صفر تغيير**.
8. لا تختبر على Production بإنشاء بيانات تشغيلية. بيئة `rawaea-staging` وردت في آخر الأدلة على أنها INACTIVE؛ لا تدّعِ Staging PASS ما لم يُثبت أنها أصبحت نشطة.
9. بعد تطبيق المالك: انشر عبر مسار Cloudflare الحالي، ثم أثبت artifact المنشور والـcommit، ونفذ browser E2E مصادقًا عليه.
10. افحص عقد الصفر/الملاحظات منفصلًا في Closure Unit مستقلة؛ لا تُدخل تغييره في هذه الرقعة العرضية.

## 8. حالة التنفيذ الفعلية

| البند | الحالة |
|---|---|
| قراءة prompt وCURRENT_STATE والتقارير ذات الصلة | VERIFIED |
| قراءة Loader وPicker كاملين | VERIFIED |
| قراءة Historical baselines | VERIFIED |
| فحص HEAD/Parent/Diff | VERIFIED |
| قراءة Production schema/constraints/grants/policies | VERIFIED |
| فحص Production Edge registry وcomplete-loading source | VERIFIED |
| Parse للـJavaScript الحالي في الملفين | PASS |
| تحديد السبب والرقعة | CONFIRMED / OWNER PATCH READY |
| تطبيق Loader patch | NOT APPLIED — مقيد بقاعدة owner-only source patch |
| تغيير Production DB/Edge/RPC | NONE — غير مطلوب لعرض البيانات |
| Staging E2E | NOT RUN |
| Cloudflare deployed artifact identity | UNKNOWN |
| Authenticated browser E2E | NOT RUN |
| Baseline restoration / test residue | لا توجد fixtures أو بيانات اختبار أُنشئت في هذه الدورة |
| الإغلاق النهائي | NOT CLOSED |

## 9. SELF-AUDIT FINAL

- **What I Proved:** اتجاه المهمة الحالي هو تعديل Loader ومقارنته بـPicker؛ SHA المصدر الحالي؛ أن آخر commit عدّل Loader فقط؛ شكل FK ومكان الوصف/الصورة في Production؛ فجوات company scoping وownership وitem-detail UX؛ وعدم وجود دليل حديث على HTML المنشور أو browser E2E.
- **What I Did Not Prove:** تطابق Cloudflare HTML مع Git، تطبيق الرقعة، سلوك المتصفح بعد التعديل، أو إغلاق عقد التحميل ذي الكمية صفر والملاحظات.
- **What I Fixed:** صححت اتجاه المهمة في هذا التقرير مقارنةً بـReport485، وجمعت ترتيب التنفيذ من Report482 وPatch G في Report483. لم أغيّر مصدرًا تشغيليًا أو قاعدة Production.
- **What I Initially Missed:** Report485 اتبع اتجاه المهمة داخل البرومبت بدل تعليمات المالك الصريحة، فجهّز رقعة Picker لا تنطبق على المطلوب الحالي. لا تستخدم تلك الرقعة لهذه المهمة.
- **What Could Still Be Wrong:** قد يتغير SHA قبل التطبيق؛ قد تكون نسخة Cloudflare مختلفة؛ قد تظهر مشكلة runtime أو company policy لا يثبتها المصدر وحده؛ وتظل مشكلة zero-quantity/notes مستقلة ومفتوحة.
- **Final Confidence:** مرتفعة في تشخيص المصدر وعقد البيانات؛ غير كافية للإغلاق التشغيلي.
- **Final Closure Status:** `OWNER PATCH READY / NOT APPLIED / NOT DEPLOYED / NOT CLOSED`.

## 10. التعليمات الدقيقة للدورة التالية

1. اقرأ هذا التقرير و`CURRENT_STATE.md`، ثم أعد جلب Loader وتحقق من SHA.
2. إن ظل SHA مطابقًا، طبّق Patch G ثم A1/A2 ثم B ثم C ثم D ثم E ثم F، باستخدام النص الكامل في Report482/483.
3. نفّذ الاختبارات من القسم 7 في بيئة معزولة نشطة.
4. لا تعدل Picker أو Core أو Main لهذه المهمة.
5. لا تسجل APPLIED/DEPLOYED/VERIFIED/CLOSED قبل وجود الدليل المباشر.
6. اترك تعارض zero-quantity/notes مسجلًا كمسألة منفصلة، ولا تُدخل إصلاحًا غير مختبر في Production.

**نهاية Report486.**
