# تقرير 506 — التحقيق الجنائي لتكامل مشرف التوصيل ومندوب التوصيل مع RAWAEA ERP

**التاريخ:** 2026-10-26  
**النطاق:** companies/company-1/delivery/supervisor.html وcompanies/company-1/delivery/driver.html، مع مراجعة Core وEdge Functions وPostgreSQL/RLS وعقود النظام الأم ذات الصلة.  
**الحالة:** FORENSIC REVIEW COMPLETE / STATIC PASS / PRODUCTION CONTRACT DEFECTS CONFIRMED / NO OPERATIONAL MUTATION / AUTHENTICATED E2E NOT RUN  
**قاعدة التغيير:** لم أعدّل أي HTML تشغيلي، أو Edge Function، أو RPC، أو Schema/RLS، أو بيانات أعمال في Production. هذه ليست دعوى إغلاق؛ بل إتمام التحقيق الممكن بأمان وتجهيز خطة إغلاق قابلة للتنفيذ.

---

## 1. SELF-AUDIT قبل التنفيذ

- **Business Understanding — CONFIRMED:** مشرف التوصيل يراجع السائقين والرانشيتات المحمّلة، يعيّن الرانشيت للسائق، ويتابع الرحلة؛ والسائق يستلم الرانشيت المعيّن له، يبدأ الرحلة، يسجل نتيجة كل أوردر/صنف، وينهي الرحلة. يجب أن تعود الحالة والتوقيتات وأسباب النقص إلى النظام الأم من خلال عقد خلفي موثوق.
- **Architecture Understanding — CONFIRMED:** التطبيقان مستقلان داخل erp-frontend ويحمّلان core.js، لكن بعض مساراتهما تتجاوز Core/RLS وتستدعي الجداول مباشرة. Edge Functions تستخدم service_role؛ لذلك أي تحقق ناقص في Edge يصبح تجاوزًا فعليًا لـRLS.
- **Database Understanding — CONFIRMED للنطاق المفحوص:** تمت قراءة مخطط الجداول وسياسات RLS وتعريفات RPC/Triggers ذات الصلة مباشرة من Production.
- **Historical Understanding — PARTIAL:** تمت قراءة CURRENT_STATE.md وآخر حدث LVE-505، وReport505 وReport504، والبرومبت التشغيلي. نسخة supervisor.html في rawaie-erp-review/PWA/delivery/supervisor.html تطابق Blob SHA الحالي. لم يثبت في هذه الدورة تاريخ كل تعديل تاريخي على ملف المشرف أو كامل lineage لكل Edge.
- **Production Understanding — CONFIRMED للنقاط التي استُعلم عنها:** Registry وSource لعدد من Edge Functions، وسياسات RLS، وتعريفات RPC، وحالة الرانشيتات قُرئت مباشرة في هذه الجلسة.
- **Current Understanding — CONFIRMED:** تم جلب الملفين كاملين من erp-frontend/main، وفحص JavaScript المضمن كاملًا من ناحية Syntax.
- **Execution Confidence:** مرتفعة في العيوب المصدرية/العقود التي تم إثباتها أدناه؛ غير كافية لادعاء Production Runtime PASS لأن لا يوجد رانشيت معيّن لسائق في عينة Production، ولم يُنفّذ Browser/HTTP E2E مصادق عليه.

### أدلة المصدر الحالية

| المصدر | Blob SHA | الحجم |
|---|---|---:|
| erp-frontend/companies/company-1/delivery/supervisor.html | 4108d2330e567c432f08197013b9c3cf6221a5c7 | 229 سطرًا |
| erp-frontend/companies/company-1/delivery/driver.html | 2df69860184f5a7c1b211ba059e1d6f57826c96b | 1,755 سطرًا |
| erp-frontend/companies/company-1/core.js | ff2f581d9900543c16f7cb026e13446520c0329d | 773 سطرًا |
| rawaie-erp-New/doc/Draft/Reprots/Report505_DELIVERY_DRIVER_PARENT_INTEGRATION_FORENSIC_20261026.md | 48684daf3988caa3b37f252cf98de7e881150213 | 363 سطرًا |
| rawaie-erp-New/doc/Draft/Reprots/Report504_PARENT_RUNSHEET_HISTORY_RETENTION_PATCHES_20261026.md | 1fdb88dc71e6cdd960243c2e879b73c9cb8cedb9 | مرجع تاريخي |

أحدث commit ظهر في سجل المستودع التشغيلي أثناء هذه المراجعة هو 40161bb3bef28cf6d8d2d6ba7938ee8807a63c23 بتاريخ 2026-10-26؛ كما ظهر commit 90ba250a98bff2261721702093d46c76158abb69 الخاص بتعديل مرشحات حالات الرانشيت. هذا لا يثبت أن Cloudflare يقدّم نفس الـBlob.

### قراءة JavaScript كاملة — Static Parse

| الملف | Inline scripts | النتيجة |
|---|---:|---|
| supervisor.html | 2 | PASS — كلا النصين قابلان للتحليل |
| driver.html | 2 | PASS — كلا النصين قابلان للتحليل |

هذا فحص Syntax فقط؛ ليس اختبار DOM أو Browser أو HTTP أو Production runtime.

---

## 2. Live Production Snapshot

**وقت استعلام PostgreSQL:** 2026-10-26T14:02:03.503615+00:00.

- يوجد حاليًا في العينة المستعلم عنها رانشيتان: RS-1 وRS-2.
- كلاهما Loaded، ولكل منهما driver_id = NULL وdeliverer_id = NULL وdelivery_start = NULL وdelivery_end = NULL.
- كلاهما تابع للشركة 00000000-0000-0000-0000-000000000001.
- أظهر الاستعلام 4 مستخدمين نشطين يحملون permissions @> ["delivery"]، وصف إعدادات واحدًا على مستوى الشركة.
- لا توجد رحلة مسندة لسائق في هذه العينة يمكن استخدامها لاختبار دورة تسليم حقيقية بأمان. لم أعيّن RS-1 أو RS-2، ولم أنشئ بيانات أعمال أو أغيّر حالة/كميات/قيودًا لاختبار الواجهة.

### Edge Registry — القراءة الحية

| Edge Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| start-delivery | 7 | ACTIVE | true | 7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e |
| complete-delivery | 4 | ACTIVE | true | 9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753 |
| cancel-delivery | 5 | ACTIVE | true | e684aed9d0e3a49548dac7a90f2e0d135b82329d2bf6b4bc4d7503dfd4ed115a |
| complete-order-delivery | 14 | ACTIVE | true | 15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2 |
| get-driver-dashboard | 1 | ACTIVE | true | 59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e |
| force-unassign-runsheet | 1 | ACTIVE | true | 4fec814c60d3899ba12b1a6f7af07228a954cf56fe3ce0eb617abdeb8af514b9 |
| start-order-delivery | 1 | ACTIVE | true | 012f61454742aa122409cf9a12f869b7a1a2b2d8dea8b7b9aa8d8ebfc40c2832 |
| save-delivery-item | 4 | ACTIVE | true | d8d3b4843b1da2d2735f7a3483d674b97995510406c95172ff69589cc91938ff |
| manage-runsheet | 1 | ACTIVE | true | c065bcec8e5d8fc432ea04fc6f2c0e4fb3bdea4f4ed9f64cf401ecab4ccf6891 |

ملاحظة Provenance: مصدر complete-order-delivery المنشور يبدأ بتعليق يذكر v12، بينما Registry يثبت v14. رقم Registry مثبت، لكن التعليق لا يثبت مصدر Git ولا byte parity. لم أساوِ ezbr_sha256 بـGit SHA.

---

## 3. النتائج المثبتة — مشرف التوصيل

### 3.1 تعارض بين صلاحية التطبيق وسياسات RLS

في supervisor.html:
- App.init() يسمح بالدخول للمالك أو من يحمل delivery_supervisor (الأسطر 112–118).
- renderDashboard() يقرأ runsheets وusers مباشرة (137–147).
- renderTeam() يقرأ users وrunsheets مباشرة (154–166).
- openAssignModal() يبحث عن الرانشيتات Loaded غير المسندة مباشرة (169–176).
- assignDriver() يقرأ المستخدم بالبريد ثم يحدث runsheets.driver_id مباشرة من المتصفح (178–181).
- unassignDriver() يغيّر driver_id وstatus مباشرة (183–186).

سياسات Production الحالية على runsheets تسمح بالقراءة عند صلاحية runsheets أو warehouse، والتحديث عند runsheets، وليس delivery_supervisor وحدها. وسياسات قراءة users لا تمنح delivery_supervisor وحدها حق قراءة قائمة الموظفين.

**النتيجة:** حساب مشرف يملك delivery_supervisor فقط قد يرى قوائم فارغة أو لا يستطيع التعيين؛ والواجهة تستخدم res.data || [] أو لا تتحقق من res.error في عدة مسارات، فتستطيع إخفاء خطأ RLS وكأنه «لا توجد بيانات». إذا كان الحساب يحمل صلاحيات إضافية فقد يختلف السلوك؛ لم أختبر جلسة مصادقًا عليها، لذلك لا أعمم على كل الحسابات.

### 3.2 لا يوجد مسار آمن حاليًا مثبت لإسناد رانشيت Loaded

التعيين الحالي كتابة مباشرة من PWA. البديل الموجود manage-runsheet v1 لا يطابق العملية المطلوبة كما هو:
- Edge يتطلب * أو runsheets، لا delivery_supervisor وحدها.
- RPC manage_runsheet_atomic يقبل UPDATE فقط عندما تكون حالة الرانشيت Open/Confirmed، ويرفض الحالات الأخرى. لذلك لا يصح توجيه تعيين Loaded إليه كما هو.
- RPC delivery_logistics_command_atomic يقبل delivery_supervisor، لكن جرد الأوامر في تعريف Production لا يحتوي أمر إسناد رانشيت؛ الأوامر المثبتة هي إدارة مندوب، وخطة مسار، ونقاط توقف، وحالة المسار والتحصيل.

**القرار:** لا تغيّر الواجهة لتستدعي manage-runsheet قبل إضافة/إثبات عقد خلفي صريح لتعيين رانشيت Loaded. المطلوب عقد ذري يشتق الشركة من المستخدم المصادق عليه، ويتحقق من صلاحية المشرف، والسائق النشط داخل الشركة نفسها، وحالة الرانشيت وعدم وجود تعيين متزامن، ثم يحدث driver_id بشرط الحالة/التعيين داخل المعاملة.

### 3.3 سحب التكليف الاضطراري — فجوة أمنية حرجة

واجهة المشرف تستدعي force-unassign-runsheet. المصدر الحي:
- يتحقق من وجود Authorization ومستخدم public.users بالبحث عن البريد.
- لا يثبت أن المستخدم نشط، أو يحمل delivery_supervisor/صلاحية إدارة مناسبة، أو أن الرانشيت تابع لشركته.
- يقرأ الرانشيت باستخدام runsheet_code دون company_id، ثم يحدّثه باستخدام id فقط.
- يستخدم Service Role؛ لذا لا تحمي RLS هذا المسار من نقص التفويض في Edge.

**التصنيف:** CONFIRMED SECURITY DEFECT. لا يجوز استخدام endpoint الحالي كحد أمني موثوق قبل إصلاحه. الإصلاح يجب أن يتحقق من auth_id، حالة المستخدم، الصلاحية الفعلية، نطاق الشركة، والرانشيت ضمن الشركة، وأن يسجل Audit ويجري الانتقال الذري المشروط بالحالة. لا أرسل طلبًا فعليًا لتجربة هذا المسار لأنه يغيّر بيانات تشغيلية.

---

## 4. النتائج المثبتة — مندوب التوصيل

### 4.1 المصادقة وسياق الشركة

النسخة الحالية تستخدم supabase.auth.getSession() وuser_metadata مباشرة في تهيئة التطبيق، وتحتوي مسارًا ينشئ سجل public.users تلقائيًا عند عدم العثور على المستخدم، مع company_id ثابت. هذا يتجاوز نموذج RW_Auth/get_my_effective_profile، وقد ينشئ سجلًا غير صحيح أو يفشل بسبب قيود التفرد.

**الإجراء الصحيح:** استخدام Core للتحقق من auth.users.id → public.users.auth_id → public.users.id/company_id/permissions، وعدم إنشاء سجل مستخدم من PWA، وعدم اعتبار metadata سلطة للصلاحيات.

### 4.2 قراءة البيانات تتعارض مع RLS

التطبيق يقرأ مباشرة من runsheets, orders, order_details, run_sheet_details, customers, items وapp_settings. سياسات Production التي فُحصت لا تمنح delivery وحدها قراءة runsheets أو run_sheet_details، كما أن سياسة قراءة orders/order_details تعتمد على orders/runsheets/warehouse/reports أو حالات خاصة للمبيعات. عدة مسارات تخفي res.error وتتعامل مع res.data || [] كأنها نتيجة صحيحة.

get-driver-dashboard v1 موجود بالفعل لكنه غير صالح للاعتماد قبل إصلاحه:
- يبحث عن المستخدم بالبريد لا auth_id.
- لا يتحقق من الشركة/الحالة/صلاحية delivery على نحو كافٍ.
- يطلب من runsheets حقولًا لا تتضمن id ثم يستخدم activeRS.id في استعلامات لاحقة.
- لا يفحص أخطاء عدة استعلامات.
- يجب أن يقيّد كل قراءة بالـcompany والسائق المعيّن.

لا تنشئ Endpoint جديدًا قبل إصلاح الموجود.

### 4.3 Lifecycle التوصيل غير موحّد أمنيًا

- start-delivery v7: يتحقق من حالة Loaded ومن rs.driver_id = public.users.id، لكنه يبحث عن المستخدم بالبريد بدل auth_id، ولا يثبت صلاحية delivery صراحة.
- complete-delivery v4: يتحقق أن الرانشيت Delivering، لكنه **لا يتحقق أن rs.driver_id = pubUser.id** قبل تحويله إلى Delivered. لذلك لا يثبت أن منفذ الإنهاء هو السائق المعيّن.
- complete-order-delivery v14: يربط Auth بالمستخدم عبر users.auth_id، لكنه لا يتحقق من صلاحية delivery أو تعيين السائق أو حالة الرانشيت قبل استدعاء Core.
- complete_order_delivery_atomic: يتحقق من الشركة ووجود الرانشيت وارتباط الأوردر به وعدم إلغائه، لكنه لا يتحقق من runsheets.driver_id أو أن حالة الرانشيت Delivering. صلاحية RPC محصورة في service_role؛ لذلك يجب أن يكون تفويض Edge→Core كاملًا، ولا يمكن افتراض أن RLS ستحميه.
- cancel-delivery v5: يستخدم lookup بالبريد، ويقرأ الرانشيت برقم الكود دون نطاق شركة، ويجري عدة تحديثات منفصلة ويتجاهل بعض أخطاء الكتابة؛ لا يصلح كمعاملة إلغاء موثوقة كما هو.
- start-order-delivery v1 وsave-delivery-item v4 موجودتان في Production لكنهما مساران أقدم: lookup بالبريد، واستعلامات غير مقيدة بالشركة في مواضع، وكتابات مباشرة متعددة مع فحص أخطاء غير مكتمل. يجب عدم تحويل التطبيق إليهما لمجرد وجودهما.

**الخطر:** خدمة Edge تستخدم service_role، وCore الحالي لا يفرض وحده ملكية السائق/حالة الرحلة في مسار إنهاء الأوردر. هذا عيب تفويض Backend مثبت من الكود الحي، وليس مجرد مشكلة عرض.

### 4.4 بدء الأوردر والإلغاء على مستوى الأوردر

- startOrderDelivery() في الواجهة يغيّر حالة الجلسة المحلية وlocalStorage، ولا يستدعي start-order-delivery.
- cancelOrderDelivery() يعيد القيم المحلية إلى الصفر ولا ينفذ طلب إلغاء خلفيًا.
- finishOrderDelivery() يستدعي complete-order-delivery ويرسل summary وamount_paid، لكن Edge/RPC لا يستقبلان/يحفظان هذين الحقلين.
- رسالة النجاح في الواجهة تقول «تم التحصيل» مع أن هذا المسار لا يثبت إنشاء إيصال تحصيل أو قيد مالي. يجب حذف هذا الادعاء أو تغييره إلى قيمة محسوبة غير محصلة حتى يُربط بعقد التحصيل الصحيح.
- Core يكتب سبب النقص إلى order_details.reason_delivery، بينما واجهة السائق تقرأ order_details.notes. لذلك قد يختفي سبب النقص بعد إعادة تحميل الصفحة.
- في بعض أجزاء الواجهة تُحسب الكمية المرفوضة/سبب النقص مقارنة بـqty المطلوبة بدل qty_loaded، بينما Core يحد التسليم بالكمية المحملة.
- حقلا صورة العداد ظاهرين في الواجهة، لكن طلبات start-delivery/complete-delivery ترسل قراءة العداد فقط؛ لا يوجد في هذا المسار إثبات رفع صورة العداد.

### 4.5 تكامل النظام الأم

Report504/505 يسجلان أن main.html كان يفلتر Delivery على Delivered فقط، ويعرض driver_id الخام ويثبت نص الحالة؛ وأن رقع الاحتفاظ بتاريخ مراحل الرانشيت لم يثبت تطبيقها في آخر حالة موثقة. لم أعد بناء محتوى main.html كاملًا في هذه الدورة؛ أتعامل مع هذه النقاط بوصفها OPEN حسب آخر سجل موثق، لا كحقيقة Runtime جديدة مثبتة الآن.

---

## 5. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل/التفسير |
|---|---|---|
| مصادقة موحدة من Core | MISSING | driver.html يعتمد Auth metadata مباشرة ومسار إنشاء المستخدم ثابت الشركة |
| عرض رانشيت السائق المعيّن | CONFLICT | UI يقرأ الجداول مباشرة وRLS لا تمنح delivery وحدها القراءة؛ Edge read الحالي معيب |
| إسناد Loaded إلى السائق | MISSING | UI يكتب مباشرة؛ manage_runsheet_atomic لا يقبل Loaded، ولا يوجد command مثبت للإسناد في logistics RPC |
| سحب اضطراري محمي بالشركة والصلاحية | MISSING | force-unassign-runsheet لا يتحقق من صلاحية المشرف/الشركة |
| بدء الرحلة | HARDENED جزئيًا | Edge يتحقق من Loaded وتعيين driver_id، لكن lookup بالبريد ولا يثبت صلاحية delivery |
| إنهاء الرحلة | CONFLICT | complete-delivery لا يتحقق من تعيين السائق |
| إنهاء تسليم الأوردر | CONFLICT | Edge/Core لا يفرضان assignment/status بشكل ذري |
| تسجيل التحصيل | MISSING في هذا المسار | summary/amount_paid غير مستخدمين في Edge/RPC |
| حفظ سبب النقص وظهوره بعد التحديث | CONFLICT | Core يكتب reason_delivery والواجهة تقرأ notes |
| عزل الشركة | HARDENED جزئيًا / MISSING في endpoints | بعض Core يمرر company_id، لكن endpoints متعددة تبحث بالبريد/code دون نطاق شركة |
| حركة المخزون من تطبيق السائق | RETAINED بحسب المسار المفحوص | Core يوضح أن Physical stock posted عند Loading؛ لا يجوز أن ينشئ Driver حركة مخزون ثانية |
| سجل النظام الأم التاريخي | OPEN | Report504/505 يوثقان مرشحات عرض تفقد حالات تاريخية؛ لم يُثبت التطبيق |

---

## 6. خطة الإصلاح الصحيحة — بالترتيب

### Closure Unit A — إصلاح عقد التفويض الخلفي قبل E2E

1. إصلاح force-unassign-runsheet الحالي: auth_id، مستخدم نشط، صلاحية مشرف فعالة، company scope، وشرط تحديث ذري للحالة؛ وإعادة التحقق من ACL/Edge runtime.
2. إصلاح complete-delivery: تحقق من Auth→public.users عبر auth_id، الشركة، الحالة النشطة، صلاحية delivery، وتعيين السائق للرانشيت؛ التحديث يجب أن يكون مشروطًا بالحالة والشركة وبهوية السائق.
3. إصلاح complete-order-delivery وCore complete_order_delivery_atomic: فرض تعيين السائق وحالة Delivering داخل المعاملة نفسها، لا في Edge فقط، مع الحفاظ على idempotency وسجل العملية.
4. إصلاح cancel-delivery إلى عملية ذرية محددة النطاق، أو اعتماد عقد Core موجود يثبت أنه يغطي كل آثار الإلغاء؛ لا تترك تحديثات جزئية تتجاهل الأخطاء.
5. إصلاح get-driver-dashboard الموجود بدل إنشاء نسخة جديدة: الهوية عبر auth_id، تضمين runsheets.id، company/driver scoping، صلاحية delivery، وفحص كل أخطاء القراءة.
6. حسم هل مسارات start-order-delivery وsave-delivery-item مستهلكة فعليًا. لا تحذفها اعتمادًا على عدم ظهورها في ملف واحد؛ ابحث في كل مستهلكي المستودع قبل retirement.
7. إثبات أن أي RPC حساس لا يُنفذ من anon/authenticated مباشرة، وأن سلسلة التفويض Edge→service_role→Core تفرض القيود نفسها.

### Closure Unit B — إسناد المشرف

1. توفير عقد خلفي صريح لتعيين رانشيت Loaded، ذري ومقيّد بالشركة والسائق النشط والصلاحية والحالة الحالية. لا تستخدم manage-runsheet UPDATE الحالي لأنه يرفض Loaded.
2. جعل supervisor.html يقرأ البيانات عبر عقد موثوق أو RLS policies محددة بدقة؛ لا توسع SELECT/UPDATE policy عامة لتشمل delivery_supervisor بلا حدود شركة/وظيفة.
3. إضافة company_id من Core لكل استعلام ممكن، وفحص res.error قبل عرض «لا توجد بيانات».
4. استبدال assignDriver() وunassignDriver() بالـAPI المعتمد بعد ثبوت عقده، مع معالجة retry/duplicate وتحديث العرض من نتيجة الخادم لا من Toast فقط.
5. قصر forceUnassign على مشرف مخول، مع تسجيل Audit واحتفاظ الكميات المسلّمة دون إعادة تشغيل دورة المخزون.

### Closure Unit C — السائق والواجهة

1. تطبيق رقع Report505 الخاصة باستخدام Core بدل metadata/إنشاء المستخدم، ثم إصلاح استعلامات العرض ومطابقة الشركة.
2. جعل الواجهة تقرأ عبر get-driver-dashboard بعد إصلاحه، أو عقد قراءة مكافئ مثبت؛ لا تعتمد على قراءة مباشرة مرفوضة بـRLS.
3. توحيد الحقول: عرض reason_delivery، وحساب المرفوض على أساس qty_loaded - qty_delivered.
4. إزالة ادعاء «تم التحصيل» حتى يثبت عقد التحصيل المحاسبي؛ لا تنشئ قيدًا من المتصفح.
5. عدم إضافة Physical Movement من Driver؛ التحميل هو موضع الحركة الفعلية وفق العقد المركزي.

---

## 7. اختبارات الإغلاق المطلوبة

| الاختبار | الحالة الحالية | السبب |
|---|---|---|
| Static parse لكامل inline JavaScript في الملفين | PASS | تحليل النصين كاملين عبر V8 |
| Production Edge Registry snapshot | PASS | قراءات مباشرة في الجلسة |
| Production schema/RLS/RPC/triggers inspection | PASS للنطاق المستعلم عنه | استعلامات PostgreSQL مباشرة |
| Supervisor login بجلسة فعلية وصلاحية delivery_supervisor فقط | NOT RUN | لا توجد جلسة Browser مصادق عليها |
| تعيين Loaded إلى سائق داخل الشركة | NOT RUN | لا يوجد fixture آمن، والعقد الخلفي الحالي غير مناسب |
| منع تعيين سائق من شركة أخرى | NOT RUN | يحتاج جلسة/Fixture معزول |
| Driver sees assigned runsheet only | NOT RUN | لا توجد رحلة معيّنة في Production baseline |
| Driver A cannot start/finish Driver B run | NOT RUN | لا يُنفذ على بيانات أعمال بلا Fixture |
| Full/partial/zero delivery + retry/concurrency | NOT RUN | يحتاج بيئة معزولة؛ لا توجد staging فعالة حاليًا |
| Confirm no stock/reservation/inventory_log delta from delivery UI | NOT RUN | لم تُنفذ عملية أعمال |
| Parent history/status/reason display in browser | NOT RUN | HTML served parity غير مثبت |
| Cloudflare served HTML parity | UNVERIFIED | لا يوجد دليل مباشر في هذه الدورة |
| Baseline restoration / fixture cleanup | NOT APPLICABLE | لم تُنشأ Fixtures أو بيانات اختبار |

لا يجوز تحويل أي NOT RUN إلى PASS.

---

## 8. Mutation Ledger

- supervisor.html: لم يتغير.
- driver.html: لم يتغير.
- core.js: لم يتغير.
- Edge Functions / RPC / RLS / Schema: لم تتغير.
- بيانات runsheets, orders, order_details, stock_branches, inventory_log، أو القيود المالية: لم تتغير.
- تم إجراء قراءة مباشرة من Production فقط، وتحليل Static، وإعداد هذا التقرير.
- لم يتم تنفيذ HTTP E2E مصادق عليه، ولم يُجرَ deploy.

---

## 9. SELF-AUDIT FINAL

### What I Proved
- النسخ الحالية لـsupervisor.html وdriver.html ونجاح تحليل JavaScript المضمن كاملًا.
- تعارض صلاحية delivery_supervisor مع RLS المباشر المستخدم في شاشة المشرف.
- عدم ملاءمة manage-runsheet الحالي لتعيين Loaded.
- ضعف تفويض force-unassign-runsheet وغياب تحقق تعيين السائق في complete-delivery.
- غياب تحقق assignment/status داخل مسار complete-order-delivery وCore الحالي.
- عيوب get-driver-dashboard، واختلاف reason_delivery / notes، وأن amount_paid المرسل لا يثبت التحصيل.
- أن Production يحتوي حاليًا رانشيتين Loaded بلا سائق؛ لذلك لا توجد رحلة baseline مناسبة لـE2E.

### What I Did Not Prove
- لم أثبت سلوكًا فعليًا من جلسة سائق/مشرف مصادق عليها في المتصفح.
- لم أثبت أن HTML الذي يقدمه Cloudflare يطابق Git.
- لم أثبت أن جميع الحسابات تتعطل؛ قد تكون لبعضها صلاحيات إضافية.
- لم أثبت lineage كاملًا لكل إصدار Edge من Git إلى Production.
- لم أثبت تسجيل تحصيل مالي لهذا المسار.

### What I Fixed
- لم أنفذ تعديلًا تشغيليًا في هذه الدورة؛ التغيير الإنتاجي دون Fixture واختبار معزول سيزيد خطر العبث برحلات/أرصدة حقيقية. أنجزت التحقيق المباشر، والتحليل الساكن، وحددت إصلاحات محددة بالترتيب بدل تغيير واجهات أو سياسات عشوائيًا.

### What I Initially Missed
- أن صلاحية delivery_supervisor التي تقبلها الواجهة لا تمنحها RLS الحالية حق قراءة/تحديث الجداول التي تستخدمها.
- أن force-unassign-runsheet يستخدم Service Role دون تحقق فعلي من صلاحية المشرف أو نطاق الشركة.
- أن complete-delivery وcomplete-order-delivery لا يثبتان أن المنفذ هو السائق المعيّن.

### What Could Still Be Wrong
- قد توجد Endpoints/Consumers أخرى غير مكتشفة في المستودعات/الفروع غير المفحوصة.
- قد تختلف الصلاحيات الفعلية لحساب بعينه عن نموذج delivery_supervisor فقط.
- قد تختلف نسخة Cloudflare عن Git الحالي.
- قد توجد آثار مالية إضافية خارج RPC المفحوصة؛ لا يجوز استنتاجها دون فحص.

**Final Confidence:** مرتفعة في العيوب التي تدعمها مصادر Production الحالية؛ متوسطة في خطة الإصلاح حتى تُراجع كل الـConsumers والـmigration lineage؛ غير كافية لإغلاق Runtime.

**Final Closure Status:** PARTIAL — SECURITY/ASSIGNMENT CONTRACT OPEN / UI PATCHES NOT APPLIED / AUTHENTICATED E2E NOT RUN / NOT CLOSED.

### تعليمات المساعد التالي
1. ابدأ بقراءة هذا التقرير وCURRENT_STATE.md، ثم أعد جلب Edge Registry والـSource الحي قبل أي تعديل.
2. ابدأ بإصلاح عقد التفويض الخلفي force-unassign-runsheet وcomplete-delivery وcomplete-order-delivery وCore؛ لا تغيّر UI لتخفي أخطاء RLS.
3. لا تعيّن RS-1 أو RS-2 في Production بغرض الاختبار. فعّل Staging/Fixture معزولًا فقط بعد إثبات عدم مساسه ببيانات الأعمال.
4. لا تستخدم manage-runsheet لتعيين Loaded قبل إصلاح عقده، ولا توسع RLS العامة لتجاوز المشكلة.
5. بعد إغلاق التفويض، أكمل إصلاح get-driver-dashboard ثم تطبيق رقع Core/واجهة السائق والمشرف، ثم نفذ E2E مع baseline restoration.
6. لا تعلن 100% CLOSED قبل التحقق من Runtime والـserved HTML وسلامة الشركة والرانشيت والأثر المالي/المخزني.
