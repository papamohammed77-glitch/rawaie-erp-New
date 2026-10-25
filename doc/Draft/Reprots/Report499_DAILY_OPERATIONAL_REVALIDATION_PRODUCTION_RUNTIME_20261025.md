
# Report499 — المراجعة التشغيلية اليومية وإعادة مطابقة التحميل مع Production

**التاريخ:** 25 أكتوبر 2026  
**نقطة البداية:** LVE-2026-10-25-498  
**الحالة:** SOURCE REVALIDATED / PRODUCTION LOAD OBSERVED / REOPEN AUTHORIZATION DEFECT CONFIRMED / STAGING INACTIVE / NOT CLOSED

## 1. نقطة البداية والحوكمة

تم جلب CURRENT_STATE.md كاملًا إلى EOF قبل أي إجراء آخر، وتحديد LVE-2026-10-25-498 بوصفه أحدث حدث في الملف. ثم أُعيدت قراءة وثيقة MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS، وبرومبت التنفيذ الحالي، وReport498، وwriting-block.md.

كشف فحص الاستمرارية أن سجل الذاكرة RAWAEA_PROJECT_MEMORY_117-02.md لا يزال ينتهي عند LVE-2026-10-24-489، رغم أن CURRENT_STATE وصل إلى LVE-2026-10-25-498. هذا تعارض في توثيق الاستمرارية، وليس دليلًا على تغير الكود.

الهدف الحالي: الحفاظ على واجهة معاينة Loader الموجودة، واستكمال التحقيق المنفصل في دورة التحميل، خصوصًا صلاحيات إعادة الفتح، وسياق الشركة، وإعادة المحاولة بعد الالتزام، مع عدم نشر تغيير غير مختبر.

## 2. GitHub / SOURCE CODE

### الهوية الحالية

- المستودع التشغيلي: papamohammed77-glitch/erp-frontend
- الفرع: main
- HEAD: 684a9fa4b157d542c4ac957cfd96edba6fbeec04
- Loader: companies/company-1/warehouse/loader.html — blob SHA f478a78b9e5999cf44f7f65e06341b3036bfdcc9، 811 سطرًا
- Picker: companies/company-1/warehouse/picker.html — blob SHA d483bd15b36585b975b63c2ef641481a01d5d084، 1,058 سطرًا
- Core: companies/company-1/core.js — blob SHA ff2f581d9900543c16f7cb026e13446520c0329d، 773 سطرًا

المقارنة من HEAD القديم 152e5b1d22aab94d2cf01070778b357df4701aff إلى HEAD الحالي تُظهر أربعة commits متتالية تخص Loader فقط: 7f691ada، 577aa96، 560b6fdd، 684a9fa. لا يوجد دليل على تعديل Picker أو Core في هذه السلسلة.

### ما هو موجود فعلًا في Loader

CONFIRMED:
- فتح الرانشيت يقيّد القراءة بـ company_id، ويمنع الدخول إلى جلسة Loading يملكها محمّل آخر.
- استعلام التفاصيل يربط items عبر items!run_sheet_details_item_id_fkey ويجلب description وimage_url وname وunit.
- معاينة الرانشيت، وبطاقات الأصناف التفاعلية، ونافذة تفاصيل الصنف ذات الصورة الكبيرة، ومعالجة الصورة البديلة، واختيار المركبة موجودة بالفعل.
- لا ينبغي إعادة بناء هذه الوظائف أو نسخ Picker كاملًا.

### فجوات دورة التحميل التي ما زالت في المصدر الحالي

CONFIRMED:
- لا توجد مسودة تحميل محفوظة عبر Dexie في Loader الحالي؛ تحميل Dexie في الصفحة وحده لا يثبت استخدامه.
- completeLoading يرسل كل العناصر، بما فيها loadedQty=0، ويرسل notes.
- محرر الكمية يحد max على qty_ordered، ويسمح عمليًا بتمرير قيمة أعلى من qty_picked إذا لم يُدخل المستخدم سببًا؛ Core يرفض تجاوز سعة التحضير.
- renderCompletedTab لا يضيف company_id صراحةً، ويستخدم loader_id مع fallback إلى البريد.
- reopenLoading يقرأ الحالة دون company_id أو تحقق ملكية صريح في استعلام الواجهة، ويرسل runsheet_code فقط؛ لا يرسل operation_id الذي تتطلبه Edge Function المنشورة.
- لا توجد دالة pauseLoading ولا آلية استعادة مسودة.
- **تصحيح سجل تاريخي:** المصدر الحالي لا يحتوي UPDATE مباشرًا على run_sheet_details.qty_loaded. ادعاء التحديث المباشر الوارد في بعض التقارير الأقدم لا ينطبق على blob Loader الحالي؛ مسار الإكمال الحالي يرسل الطلب إلى Edge فقط. صلاحية authenticated UPDATE على run_sheet_details غير ممنوحة، ولا يجب منحها كحل بديل.

## 3. Supabase Production — المخطط والعقود والصلاحيات

المشروع: SMART ERP، ref fiilmooggumokxanwiyx.  
آخر قراءة مباشرة للمخطط والبيانات: 2026-10-25 19:11:08 UTC تقريبًا، PostgreSQL 17.6.

### الحالة المرصودة

- runsheets: صفّان؛ واحد Loaded وواحد Picked؛ لا توجد جلسة Loading حاليًا.
- items: 18 صفًا.
- run_sheet_details: 12 صفًا.
- app_settings: صف واحد وشركة واحدة في اللقطة الحالية؛ كما أن المستخدمين المرصودين ينتمون إلى شركة واحدة. هذا لا يجعل استخدام app_settings.limit(1) عقدًا صحيحًا لتعدد الشركات.
- الرانشيت RS-1: Loaded، وله vehicle_id وloader_id وloader_start وloader_end وloading_cycle_id.
- الرانشيت RS-2: Picked، بلا مركبة أو محمّل أو أوقات تحميل، لكنه ما زال يحمل loading_cycle_id. هذه حالة بيانات غير متسقة مع دورة التحميل المعتادة، ومصدرها التاريخي غير مثبت. لم أعدّلها.
- تفاصيل RS-1: خمسة صفوف run_sheet_details؛ إجمالي المطلوب 14، والمحضّر 13، والمحمّل 13. وفي order_details: 11 صفًا، وإجمالي المحضّر/المحمّل 13.
- لا توجد قيمة reason_loading مسجلة في تفاصيل الطلبات التابعة للرانشيت Loaded المرصود. لا يثبت ذلك وحده أن المستخدم أدخل ملاحظات، لكنه يتوافق مع عقد Edge الحالي الذي لا يحفظ notes.

### العقود والصلاحيات

- start-loading v6 وRPC start_runsheet_loading_with_vehicle(uuid,text,text,uuid) يعملان معًا: الـEdge يربط JWT بـ public.users.auth_id، ثم يمرر company_id، والـRPC يتحقق من المركبة وفرع VAN وحالة Picked وينفذ إسناد المركبة وبدء التحميل داخل معاملة واحدة.
- start_runsheet_loading_with_vehicle وcomplete_runsheet_loading وcomplete_runsheet_reopen_loading وcancel_runsheet_loading هي SECURITY DEFINER، وACL المقروءة لا تمنح anon/authenticated تنفيذًا مباشرًا؛ التنفيذ المركزي يمر عبر service_role.
- post_stock_movement ذو 10 معاملات، بما فيها idempotency key، يمنح EXECUTE لـ postgres وservice_role فقط. نسخة 9 معاملات لا تمنح إلا postgres.
- trg_sync_run_sheet_details ما زال يعمل بعد INSERT/UPDATE/DELETE على order_details. تحديثات الكميات المركزية تنعكس إلى run_sheet_details عبر هذا المسار.
- authenticated يملك SELECT ولا يملك UPDATE على run_sheet_details؛ كما لا يملك UPDATE على order_details.

## 4. CONFLICT — Edge source مقابل Production

### start-loading

- Production: v6، ACTIVE، verify_jwt=true، digest b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1.
- Current/Edge_Functions/start-loading: blob 5fc6b01826ad098d6621d7f80ea8efb4eba8d5a0.
- المقارنة النصية المباشرة: تطابق كامل.

### complete-loading

- Production: v11، ACTIVE، verify_jwt=true، digest c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286.
- Current/Edge_Functions/complete-loading: blob 0dd221173aee7f3aa15d16202f034ae94f4104f3.
- المقارنة النصية المباشرة: **لا يوجد تطابق**. نسخة Git تتضمن معالجة JSON غير الصالح، وتطبيع runsheet_code، وتحويلًا افتراضيًا لقائمة items؛ النسخة المنشورة تستخدم قراءة JSON مباشرة ولا تطبّع code بالطريقة نفسها. بقية عقد الإكمال الأساسي متقارب، لكن لا يجوز اعتبار ملف Git بصمة للمصدر المنشور.

لم أستبدل ملف Git الحالي؛ فهو يحتوي تحسينات مرشحة قد تكون مقصودة ولم تُختبر بعد. يجب فصل نسخة Production المثبتة عن أي مرشح قبل النشر بدل إخفاء التعارض.

### cancel-loading وreopen-loading — استعادة المصدر المفقود

لم يكن أي من الملفين موجودًا في شجرة Current/Edge_Functions، ولم يظهر لهما مسار آخر في الشجرة الحالية لمستودع التوثيق. استُعيد النص المنشور حرفيًا من Supabase إلى المسارين القياسيين:

- Current/Edge_Functions/cancel-loading — Production v5، digest 65fdfe2066dac1779c1e82b27a958a13d71604808af8a33ca12779ac5b7c0c89؛ commit الاستعادة c400673abfede2a33f59510fa25203866de8d4cc؛ Git blob بعد الاستعادة e23022972a2898217ea48356913dacbc4665e309.
- Current/Edge_Functions/reopen-loading — Production v2، digest 89cac4219673154832b294d74b810c98154b7a46464a893eb8f119439e358350؛ commit الاستعادة e5bf4c9f5bb4ec7dfe14bc460c76deefcef0c974؛ Git blob بعد الاستعادة 182384633d02da18a6cd3ab0d1e7e659bbfb68af.

أُعيد جلب الملفين ومقارنة النص الكامل بمصدر Production؛ التطابق النصي CONFIRMED. هذه استعادة توثيقية فقط، وليست نشرًا أو تغييرًا في Supabase.

## 5. CONFIRMED — عيب تفويض إعادة الفتح

مصدر Production المنشور لـ reopen-loading v2:
- يتحقق من وجود JWT صالح عبر Supabase Auth.
- لا يربط المستخدم المصادق عليه بسجل public.users عبر auth_id.
- لا يتحقق من company_id الخاص بالمستخدم أو دوره/صلاحية المخزن أو ملكيته للرانشيت.
- يستخرج company_id من app_settings.limit(1)، ثم يستدعي RPC بصلاحية service_role.

تعريف complete_runsheet_reopen_loading(uuid,text,text,text):
- يتحقق من وجود الرانشيت وحالة Loaded ووجود loading_cycle_id والمركبة وفرع VAN.
- يستخدم operation_id لمنع تكرار حركات الإرجاع.
- لا يتحقق من هوية المستخدم أو ملكية loader_id داخل الدالة.

الاستنتاج الأمني: **يوجد نقص تفويض مؤكد في مسار إعادة الفتح**؛ صحة JWT وحدها لا تعني امتلاك صلاحية إعادة فتح رانشيت. مع وجود رانشيت Loaded حاليًا، لا يجوز إعلان هذا المسار آمنًا أو متعدد الشركات. لم أجرّب استغلاله، ولم أرسل طلبًا مصادقًا أو أغير صلاحياته. استخدام app_settings.limit(1) في cancel-loading أيضًا ليس حلًا صالحًا لتحديد مستأجر المستخدم؛ غير أن cancel_runsheet_loading يفحص سجل المستخدم والبريد والشركة وloader_id، لذا يختلف نطاق الخطر عن reopen.

## 6. CONFIRMED — Runtime وBusiness-data effects المرصودة

سجلات Edge في نافذة 24 ساعة من 2026-10-24 19:11 إلى 2026-10-25 19:11 UTC أظهرت:
- start-loading v6: POST HTTP 200 عند 2026-10-25 16:36:55.401 UTC.
- complete-loading v11: POST HTTP 200 عند 16:37:29.891 UTC.
- complete-loading v11: POST HTTP 400 عند 15:24:26.711 UTC؛ سجل PostgreSQL المقابل يعرض invalid Loading context.
- cancel-loading v5: POST HTTP 200 عند 15:23:35.038 UTC.
- ظهرت كذلك محاولتا POST HTTP 400 على start-loading v5 عند 15:54 و15:56 UTC.
- لم يظهر أي طلب reopen-loading في الاستعلام المحدد لهذه النافذة.

قاعدة البيانات تؤكد سجلًا واحدًا completed في erp_operation_registry من النوع complete_runsheet_loading عند 16:37:29.632 UTC. كما أظهر inventory_log خمسة حركات Loading بمجموع 13 وحدة في النافذة نفسها، وتطابقت كميات RS-1 المحمّلة مع 13 وحدة في التفاصيل.

هذه أدلة على نشاط تحميل فعلي في Production، لكنها **ليست اختبار E2E نفذته هذه المراجعة**؛ نية المستخدم من العملية (عمل تجاري أم اختبار) UNKNOWN. لم أنشئ هذه الحركات ولم أغيّر أي سجل أو كمية مخزون.

## 7. UNKNOWN / UNVERIFIED

- لا يوجد عنوان Cloudflare Pages موثوق محدد في المصدر الذي أمكن الوصول إليه؛ بحث الويب لم يُظهر عنوانًا موثوقًا، ولا توجد أداة Cloudflare متاحة في هذه الجلسة.
- تعذر استخدام المتصفح المتصل بسبب عدم وجود originating browser context.
- لذلك تبقى بصمة HTML المخدوم، والـheaders/cache الفعلية، وسلسلة commit→build→deployment، وأخطاء Console/Network UNVERIFIED.
- مشروع rawaea-staging (hfzznsiprnwkpayskzhu) ما زال INACTIVE حسب قائمة المشاريع الحية؛ لم أستعده لتجنب تغيير مورد أو تكلفة دون مسار اختبار مصرح وآمن.
- لم يُختبر retry بعد نجاح complete_runsheet_loading وضياع الاستجابة. Core يتحقق من status='Loading' قبل الرجوع إلى سجل idempotency؛ لذلك خطر retry-after-commit مثبت في ترتيب الكود، لكن سلوك إعادة المحاولة الفعلي UNVERIFIED.
- لم يُنفذ Browser E2E أو اختبار عزل مستخدم/شركة أو مقارنة baseline قبل/بعد لحركات المخزون من هذه المراجعة.

## 8. مصفوفة التحقق

| الطبقة | الحالة | الحكم |
|---|---|---|
| GitHub/source | CONFIRMED | Loader الحالي ما زال على SHA f478…؛ UI موجود؛ فجوات دورة التحميل ما زالت قائمة |
| Supabase Production | CONFIRMED | المخطط وACL والدوال والمحفزات وبيانات الحالة فُحصت مباشرة |
| Edge source parity | CONFLICT | start-loading متطابق؛ complete-loading مختلف؛ cancel/reopen استُعيد مصدرهما المنشور |
| Deployed HTML | UNKNOWN | لا URL موثوق ولا Cloudflare/browser access |
| Runtime/E2E | PARTIAL / UNVERIFIED | سجل إنتاجي ناجح ومسار فشل سابق مرصودان؛ لا E2E نفذته المراجعة |
| Business-data effects | CONFIRMED | توجد حركة تحميل إنتاجية مرصودة؛ لم تنفذ هذه المراجعة أي كتابة أو حركة |

## 9. سجل التغييرات الفعلية

1. جلب CURRENT_STATE كاملًا وتحديد LVE-498 قبل قراءة التقارير أو إجراء فحوص أخرى.
2. إعادة قراءة الحوكمة والبرومبت وReport498 وwriting-block.md.
3. إعادة جلب HEAD وLoader وPicker وCore ومقارنة commits ذات الصلة.
4. قراءة مخطط Production وRLS وgrants وRPCs وtriggers وEdge sources والسجلات وملخص آثار المخزون قراءةً فقط.
5. استعادة المصدر الحرفي لـ cancel-loading v5 وreopen-loading v2 إلى Current/Edge_Functions في مستودع التوثيق والتحقق من التطابق بعد الكتابة.
6. لم يتغير أي ملف تشغيلي في erp-frontend، ولم يتغير Supabase Production، ولم يُنشر Edge Function، ولم تُنشأ أو تُحذف بيانات اختبار، ولم يُستعد Staging.

## 10. الخطوة التالية ذات الأولوية

**إصلاح مسار reopen-loading أمنيًا في بيئة اختبار معزولة قبل أي نشر Production.** يجب أن يربط Edge المستخدم بـ public.users.auth_id، ويتحقق من Active والـcompany والصلاحية وملكية الرانشيت، وألا يثق بـ app_settings.limit(1). يجب اختبار الرفض لمستخدم غير مسجل/غير مخول، وإعادة الفتح للمحمّل المصرح فقط، وإعادة المحاولة بنفس operation_id، مع مطابقة stock_branches وinventory_log قبل/بعد.

الـblocker الحالي: Staging غير نشط ولا يوجد Browser E2E متاح. لم أغيّر Production لتجنب تعريض عملية إعادة الفتح أو المخزون لمخاطر غير مختبرة.

**Final status:** SOURCE + PRODUCTION RECONCILED / MISSING EDGE SOURCES RECOVERED / LIVE LOADING ACTIVITY CONFIRMED / REOPEN AUTHORIZATION DEFECT OPEN / DEPLOYMENT UNKNOWN / NOT CLOSED.
