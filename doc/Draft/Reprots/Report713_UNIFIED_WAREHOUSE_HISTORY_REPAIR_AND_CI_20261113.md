# Report713 — إصلاح سجل العمليات المكتملة وتوافق التفريغ واختبارات المخزن الشامل
**التاريخ:** 2026-11-13  
**نقطة الاستئناف السابقة:** LVE-2026-11-13-712  
**نقطة التحقق الجديدة:** LVE-2026-11-13-713  
**الحكم:** READY WITH LIMITATIONS — إصلاحات المصدر مثبتة وCI/Browser E2E الاصطناعي ناجح؛ نشر Cloudflare وRuntime Production والصور الفعلية ما زالت غير متحققة.  
**النطاق:** Picker / Loader / Unloader — standalone originals + embedded Warehouse Hub bundles + warehouse CI workflow.

## 1. الحوكمة والصلاحية
- أُعيدت قراءة CURRENT_STATE.md ثم الدستور التشغيلي الدائم في بداية التشغيل.
- صدر من المالك في هذه المحادثة تفويض تنفيذي أحدث وصريح بتطبيق الإصلاحات الآمنة مباشرة بدل الاكتفاء بتجهيز المقاطع. طُبق التفويض على ملفات التطبيقات الثلاثة والنسخة المجمعة واختبار CI فقط.
- لم يُعدل main.html أو core.js أو أي عقد Supabase أو Migration أو RLS/GRANT أو بيانات Production.
- لم تُنفذ أي DML/DDL أو RPC أو Edge Function أو عملية مخزنية/مالية فعلية.
- المستودع التشغيلي: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Commit التطبيق: `a47dd90df1d410a84e5275a6e3295c4563689fef`.
- Commit تصحيح assertions في CI: `930c6eb1b860b74be9b08563566736e27c8a068e` (HEAD عند التحقق).
- الملفات المعدلة:
  - `companies/company-1/warehouse/picker.html`
  - `companies/company-1/warehouse/loader.html`
  - `companies/company-1/warehouse/unloader.html`
  - `companies/company-1/warehouse/warehouse.html`
  - `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`

## 2. الإصلاحات المنفذة

### CS-WH-712-A — سجل التحضير المكتمل (Picker)
**CONFIRMED — Source fixed**
- استُبدل الاعتماد على الحالة الحالية للرانشيت بمصدر أحداث الإتمام `erp_operation_registry` مع `operation_type='complete_runsheet_picking'` و`status='completed'`.
- القراءة مقيدة بـ`company_id` وبريد منفذ العملية `request_payload->>user_email`.
- تُقرأ الحالة الحالية للرانشيت منفصلة لتحديد صلاحية إعادة الفتح، ولا تُستخدم لتقرير هل حدث التحضير تاريخيًا أم لا.
- يبقى الحدث ظاهرًا بعد انتقال الرانشيت إلى Delivered أو Returned.
- زر إعادة الفتح يظهر فقط لأحدث حدث للرانشيت عندما تكون الحالة الحالية Picked و`picker_id` يطابق المستخدم الحالي. بقية الأحداث التاريخية للرانشيت لا تفتح إجراءً غير مؤهل.
- تم تطبيق المنطق نفسه على `picker.html` والنسخة المضمنة في `warehouse.html`.

### CS-WH-712-A — سجل التحميل المكتمل (Loader)
**CONFIRMED — Source fixed**
- مصدر السجل أصبح `erp_operation_registry` مع `operation_type='complete_runsheet_loading'` و`status='completed'`.
- الربط الحالي منفصل عن تاريخ الإكمال، لذلك لا تختفي عمليات التحميل بعد التفريغ أو التسليم أو الإرجاع.
- زر إعادة الفتح لا يظهر إلا لأحدث حدث عندما تكون الحالة الحالية Loaded، و`loader_id` يطابق المستخدم، و`response_payload.loading_cycle_id` يساوي `runsheets.loading_cycle_id` الحالية.
- هذا يمنع زر إعادة فتح دورة تحميل قديمة عند وجود أكثر من دورة للرانشيت.
- تم تحديث الأصل والنسخة المضمنة.

### CS-WH-712-A — سجل التفريغ المكتمل (Unloader)
**CONFIRMED — Source fixed**
- استُبدل مصدر `stock_vouchers` غير المنتج من دورة التفريغ بمصدر الحدث الفعلي `erp_operation_registry` مع `operation_type='complete_runsheet_unloading'` و`status='completed'`.
- يعرض السجل رقم الرانشيت ووقت الإكمال و`response_payload.unloaded_total`.
- القراءة مقيدة بالشركة وبريد المستخدم الذي نفذ التفريغ.
- لا ينشئ عرض السجل سندًا أو حركة مخزنية، ولا يقرأ `stock_vouchers`.
- تم تحديث الأصل والنسخة المضمنة.

### CS-WH-712-D — أهلية قائمة التفريغ
**CONFIRMED — Source fixed**
- قائمة Unloader والبحث يعرضان فقط `status='Loaded'` مع `loading_cycle_id IS NOT NULL`.
- أضيف قيد الشركة صراحةً إلى القراءة.
- أزيلت حالة Delivering من قائمة التفريغ والبحث؛ لأنها لا تجتاز عقد RPC الحالي `complete_runsheet_unloading`.
- لم يتغير RPC ولم يُنفذ أي تعديل في Production.

## 3. اختبارات القبول المضافة

### Static / Contract
- تحقّق CI من أن Picker وLoader وUnloader في الملفات الأصلية والنسخ المضمنة تقرأ سجل الأحداث الصحيح.
- تحقّق من عدم رجوع Picker إلى `status='Picked'` كشرط لتاريخ المكتملة، وعدم رجوع Loader إلى `status='Loaded'` كشرط لتاريخ المكتملة.
- تحقّق من عدم استخدام Unloader لـ`stock_vouchers` في سجل التفريغ المكتمل.
- تحقّق من تطابق قائمة التفريغ والبحث مع شرط Loaded ودورة تحميل قائمة.
- تم التحقق من JavaScript syntax للملفات المضمنة ضمن Static source step.

### Browser E2E — fixtures محلية فقط
أضيف سيناريو اصطناعي داخل CI لا يتصل ببيانات أعمال Production:
- Picker: أحداث مكتملة لرانشيتات أصبحت Delivered وReturned، مع حدث آخر مؤهل حاليًا؛ تحقّق من بقاء الأحداث الثلاثة وظهور زر إعادة الفتح لحدث واحد مؤهل فقط.
- Loader: أحداث مكتملة لرانشيتات أصبحت Delivered وReturned، ودورتان تحميل للرانشيت نفسه؛ تحقّق من بقاء السجل ومن ظهور زر إعادة الفتح للدورة الحالية فقط.
- Unloader: حدث تفريغ مكتمل يُقرأ من registry ويعرض الكمية؛ يتحقق الاختبار من عدم أي قراءة لـ`stock_vouchers`.
- Unloader queue: Loaded مع دورة تحميل يظهر؛ Delivering لا يظهر.
- جميع بيانات QA داخل Browser mock في CI، ولم تُكتب إلى Supabase.

## 4. نتيجة CI
**SUCCESS**
- Warehouse workflow Run: `43462936571`
- Commit المختبر: `930c6eb1b860b74be9b08563566736e27c8a068e`
- Static source and module contract: SUCCESS.
- Install Playwright: SUCCESS.
- Start local source server: SUCCESS.
- Browser E2E — shared identity, seven workspaces and voucher actions: SUCCESS.
- الاختبارات الجديدة:
  - `WAREHOUSE_COMPLETED_HISTORY_E2E=PASS`
  - `WAREHOUSE_UNLOADER_RPC_ELIGIBILITY_E2E=PASS`
- رابط التشغيل: https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/43462936571
- فحوصات أخرى على نفس HEAD:
  - Mother source verification + JS syntax: SUCCESS.
  - Helper forensic syntax/manifest/service-worker checks: SUCCESS.
  - Inventory forensic source and browser smoke: SUCCESS.
- نجاح هذه الاختبارات لا يثبت Cloudflare deployment أو Production authenticated runtime.

## 5. مراجعة الصور — ما ثبت وما بقي مجهولًا
- `run_sheet_details` لا يحتوي عمود `image_url`; مصدر الصورة هو `items.image_url`.
- Production SELECT أكد أن `items.company_id` للأصناف 1001 و1003 و1004 و1005 و1006 و1007 و1008 يطابق `runsheets.company_id` للرانشيتات RS-1 إلى RS-4.
- مسارات المصدر:
  - Picker يقرأ `items(item_code,image_url)` للشركة ويملأ `ITEMS_IMAGE_CACHE` ثم يستدعي `refreshVisibleImages()`.
  - Loader يقرأ `items!run_sheet_details_item_id_fkey(description,image_url,name,unit)`.
  - Returns يقرأ `items!run_sheet_details_item_id_fkey(image_url)`.
- عينة الروابط الحالية من الأصناف المعروضة تستخدم `lh3.googleusercontent.com`; والتقرير السابق سجل 17 رابط Googleusercontent ورابطين Supabase Storage.
- اختبار الصور الحالي في CI يثبت عرض الصور الصحيحة وإظهار fallback عند رابط QA معطوب باستخدام mock URLs فقط.
- لم تتوفر جلسة متصفح مصادق عليها. أداة التصفح أعادت أن الوصول يحتاج originating browser context، وفتح Cloudflare Pages عبر Web لم يكن متاحًا. لم يمكن قياس HTTP status أو `naturalWidth` للروابط الحقيقية.
- **الحكم:** وجود روابط الصور ومصدرها CONFIRMED؛ وصول المتصفح للصور الحقيقية وظهورها في Production RUNTIME UNKNOWN/UNVERIFIED. لم تُغير روابط أو بيانات الصور ولم تُنقل إلى Storage.

## 6. مصفوفة الأدلة
| الطبقة | النتيجة | الدليل |
|---|---|---|
| GitHub Source | CONFIRMED — fixed | Commit `a47dd90`; HEAD `930c6eb`; originals + embedded bundles |
| Supabase Production | CONFIRMED — read only | Registry/RPC contracts and item image_url reads; no writes |
| CI Static | SUCCESS | Run `43462936571` |
| CI Browser E2E | SUCCESS | Local source + QA fixtures/mocks |
| Deployed Artifact | UNKNOWN | لا وصول مباشر إلى bytes أو Cloudflare deployment record |
| Production Runtime / authenticated browser | UNVERIFIED | لا originating browser context |
| Business-data effects | CONFIRMED — no changes by this task | لا DML/DDL/RPC/Edge ولا عمليات مخزنية/مالية |
| Images live network | UNVERIFIED | لم يمكن قياس روابط Googleusercontent/Storage الحقيقية |

## 7. ما لم يُنفذ
- CS-WH-712-B (DOM isolation fallback) لم يُعدل؛ لا يوجد إثبات Runtime لتسرب DOM، ويحتاج اختبارًا منفصلًا قبل أي تغيير.
- CS-WH-712-C (تحويل مصدر الصور أو تغيير التخزين) لم يُطبق؛ لا دليل كافٍ على أن الرابط نفسه معطوب، ولا يجوز تغيير بيانات الصور اعتمادًا على التخمين.
- لم يُنشر تغيير يدوي ولم يُختبر التطبيق على جلسة مستخدم Production.
- لم تُنفذ عمليات إكمال أو إعادة فتح أو تفريغ حقيقية.
- لم يتم فحص جميع تبويبات Warehouse Hub وكل دورة المستندات في هذه الدفعة؛ التغطية محددة لسجلات الإتمام وأهلية Unloader مع الاحتفاظ باختبارات CI السابقة.

## 8. الأثر والمخاطر
- الخطر P1 المتعلق باختفاء سجل التحضير والتحميل والتفريغ عولج على مستوى المصدر واختُبر في Browser E2E المحلي.
- خطر إظهار Delivering كعملية قابلة للتفريغ عولج على مستوى القائمة والبحث.
- لا توجد تغييرات على حركة المخزون أو الخزينة أو الحسابات أو الأرصدة.
- يظل خطر الصور الحقيقية P2/UNVERIFIED إلى حين Runtime check؛ لا ينبغي إعلان إغلاقه.
- يظل نشر Cloudflare ونسخة Artifact الفعلية UNVERIFIED حتى فحص النشر والصفحة الحية.

## 9. نقطة الاستئناف التالية
**LVE-2026-11-13-713 — Source repair + CI passed / runtime and real images pending.**

الخطوة التالية ذات الأولوية: فحص نشر Cloudflare والصفحة المنشورة بجلسة متصفح مصادق عليها، ثم اختبار الصور الحقيقية في Picker/Loader/Returns بقياس HTTP status و`naturalWidth`، مع إعادة التحقق من ظهور السجلات في التبويبات المناسبة داخل النظام الأم. لا تغييرات على صور Production أو بيانات الأعمال قبل ثبوت السبب وخطة تغيير محددة.


## 10. سجل فشل الاختبار والتصحيح (محفوظ)
- أول تشغيل بعد Commit التطبيق `a47dd90`، Run `43462877239`، فشل في Static contract assertion فقط.
- السبب الجذري: assertion الجديد كان يبحث عن النص `response.loading_cycle_id` بينما اسم متغير نتيجة RPC في التطبيق هو `v`، وبالتالي الكود الصحيح يحتوي `v.loading_cycle_id`. كذلك احتاجت assertions لقائمة Unloader إلى مطابقة تنسيق الاستعلام compact.
- لم يكن الفشل ناتجًا عن JavaScript syntax أو Runtime behavior؛ توقفت الخطوة قبل Playwright.
- تم تصحيح assertions في Commit `930c6eb`، ثم نجح Run `43462936571` بالكامل بما فيه Browser E2E. لم تُخفَ نتيجة الفشل الأولى ولم يُعدّل التطبيق لإرضاء assertion خاطئ.
