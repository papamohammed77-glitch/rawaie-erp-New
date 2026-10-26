# تقرير 507 — مراجعة تكامل مشرف التوصيل ومندوب التوصيل

**التاريخ:** 2026-10-26  
**الحالة:** PARTIAL — SECURITY/ASSIGNMENT CONTRACT OPEN — AUTHENTICATED E2E NOT RUN — NOT CLOSED  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend`, branch `main`  
**Production:** Supabase project `fiilmooggumokxanwiyx`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** مشرف التوصيل يعيّن الرانشيتات المحمّلة إلى مندوبي الشركة ويراقبها؛ المندوب يرى الرانشيت المعيّن إليه، يبدأ الرحلة، يسجل نتائج التسليم، وينهيها.
- **Architecture Understanding — CONFIRMED:** التطبيقان مستقلان ويحملان `core.js`، لكنهما يستخدمان قراءات/كتابات مباشرة إلى PostgreSQL في مسارات حرجة. Edge Functions تستخدم `service_role`، لذلك يجب أن تفرض الهوية والصلاحية والشركة وتعيين السائق والحالة.
- **Database Understanding — CONFIRMED للنطاق المستعلم عنه:** تمت قراءة جداول الرانشيتات وسياسات RLS وتعريفات RPC/Triggers ذات الصلة مباشرة من Production.
- **Historical Understanding — PARTIAL:** تمت قراءة `CURRENT_STATE.md` وآخر حدث LVE-506 وتقارير 505/506 و`writing-block.md` والبرومبت التنفيذي. لم يكتمل Git ancestry لكل تعديل تاريخي ولكل Edge.
- **Production Understanding — CONFIRMED للنقاط المدرجة أدناه:** جرى جلب Edge registry ومصادر الوظائف الحية وSQL من Production في الجلسة نفسها.
- **Current Understanding — CONFIRMED:** جُلب الملفان التشغيليان كاملين من `erp-frontend/main` وفُحصت نقاط الاستدعاء الفعلية.
- **Execution Confidence:** مرتفعة في العيوب المدعومة بمصدر حي وRLS/SQL؛ غير كافية لإعلان Runtime PASS لأن E2E المصادق عليه لم يُنفّذ.

## 2. أدلة المصدر وProduction

### الملفات
| الملف | Blob SHA | الحجم |
|---|---|---:|
| `companies/company-1/delivery/supervisor.html` | `4108d2330e567c432f08197013b9c3cf6221a5c7` | 229 سطرًا |
| `companies/company-1/delivery/driver.html` | `2df69860184f5a7c1b211ba059e1d6f57826c96b` | 1,755 سطرًا |
| `companies/company-1/core.js` | `ff2f581d9900543c16f7cb026e13446520c0329d` | 773 سطرًا |

### Production database
وقت اللقطة: `2026-10-26 14:26:02.565921+00`.
- `RS-1` و`RS-2` كلاهما `Loaded`.
- `driver_id=NULL`, `deliverer_id=NULL`, `delivery_start=NULL`, `delivery_end=NULL` لكليهما.
- الرانشيتات Loaded غير المسندة: 2.
- المستخدمون النشطون: 29؛ أصحاب `delivery`: 4؛ أصحاب `delivery_supervisor`: 1.
لم يتم تعديل RS-1/RS-2 ولم يُستخدما كـtest fixtures.

### Edge registry — قراءة مباشرة
| Function | Version | Status | verify_jwt | ezbr_sha256 |
|---|---:|---|---|---|
| `start-delivery` | 7 | ACTIVE | true | `7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e` |
| `complete-delivery` | 4 | ACTIVE | true | `9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753` |
| `cancel-delivery` | 5 | ACTIVE | true | `e684aed9d0e3a49548dac7a90f2e0d135b82329d2bf6b4bc4d7503dfd4ed115a` |
| `complete-order-delivery` | 14 | ACTIVE | true | `15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2` |
| `get-driver-dashboard` | 1 | ACTIVE | true | `59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e` |
| `force-unassign-runsheet` | 1 | ACTIVE | true | `4fec814c60d3899ba12b1a6f7af07228a954cf56fe3ce0eb617abdeb8af514b9` |
| `start-order-delivery` | 1 | ACTIVE | true | `012f61454742aa122409cf9a12f869b7a1a2b2d8dea8b7b9aa8d8ebfc40c2832` |
| `save-delivery-item` | 4 | ACTIVE | true | `d8d3b4843b1da2d2735f7a3483d674b97995510406c95172ff69589cc91938ff` |
| `manage-runsheet` | 1 | ACTIVE | true | `c065bcec8e5d8fc432ea04fc6f2c0e4fb3bdea4f4ed9f64cf401ecab4ccf6891` |

`ezbr_sha256` هو digest لحزمة Edge وليس Git SHA؛ لم أدّعِ byte parity أو Git provenance كاملة.

## 3. Consumer trace

### `supervisor.html`
- `renderDashboard()`: يقرأ `runsheets` و`users` مباشرة.
- `renderTeam()`: يقرأ `users` و`runsheets` مباشرة.
- `openAssignModal()`: يبحث مباشرة عن `Loaded` غير المسند.
- `assignDriver()`: يبحث بالبريد ثم يحدّث `runsheets.driver_id` مباشرة.
- `unassignDriver()`: يغيّر `driver_id/status` مباشرة.
- السحب الاضطراري يستدعي `force-unassign-runsheet`.
**المتوقع:** Core Auth/Profile → endpoint موثوق مقيّد بالشركة والصلاحية والحالة → تحديث ذري/Audit → رد موثوق. **الفعلي:** direct table reads/writes لا تطابق عقد RLS ولا تثبت ذرية الإسناد.

### `driver.html`
- يستخدم `supabase.auth` مباشرة بدل اعتماد كامل على `RW_Auth`.
- lookup لـ`public.users` بالبريد، مع fallback لإنشاء سجل من المتصفح يتضمن `company_id` ثابتًا.
- قراءات مباشرة من `items`, `app_settings`, `runsheets`, `orders`, `order_details`, `run_sheet_details`, `customers`.
- يستدعي `start-delivery`, `complete-delivery`, `cancel-delivery`, `complete-order-delivery`; بعض بدء/إلغاء الأوردرات تغييرات محلية لا تثبت عملية backend مقابلة.
- يرسل `summary/amount_paid` لكن Edge/RPC المفحوصين لا يثبتان حفظ التحصيل.
- UI يقرأ `order_details.notes` بينما Core يكتب `reason_delivery`.
- حقول صورة العداد لا تثبت رفع الصورة إلى backend.
لا يجوز أن ينشئ تطبيق السائق Physical Movement ثانية؛ حركة المخزون الفعلية مرتبطة بالتحميل.

## 4. العيوب المثبتة

1. **RLS/المشرف:** صلاحية `delivery_supervisor` لا تمنح بذاتها SELECT/UPDATE المباشر الذي تستخدمه الواجهة على `runsheets/users` وفق السياسات المفحوصة. بعض المسارات تخفي `res.error` وتعرض نتيجة فارغة.
2. **إسناد Loaded:** `manage_runsheet_atomic` يقبل التعديل في حالات Open/Confirmed ويرفض Loaded؛ لا يوجد أمر إسناد Loaded مثبت في `delivery_logistics_command_atomic`.
3. **سحب اضطراري:** `force-unassign-runsheet v1` لا يتحقق بما يكفي من صلاحية المشرف/نشاطه/الشركة، ويقرأ الرانشيت بالكود دون company scope ثم يحدّث بالـid فقط. استخدام service_role يجعل ذلك عيب تفويض حقيقيًا.
4. **إنهاء الرحلة:** `complete-delivery v4` يتحقق من الحالة والشركة لكنه لا يثبت أن المستخدم هو `runsheets.driver_id`.
5. **إنهاء الأوردر:** `complete-order-delivery v14` يستخدم `auth_id` للهوية لكنه لا يفرض صلاحية delivery أو تعيين السائق أو حالة Delivering قبل RPC؛ وتعريف `complete_order_delivery_atomic` لا يفرض assignment/status داخل المعاملة حسب المصدر المفحوص.
6. **لوحة السائق:** `get-driver-dashboard v1` يبحث بالبريد، لا يختار `runsheets.id` قبل استخدام `activeRS.id` في استعلامات لاحقة، ويفتقد فحوص الشركة/السائق/الصلاحية وأخطاء القراءة.
7. **بدء/إلغاء:** `start-delivery v7` lookup بالبريد ولا يثبت صلاحية delivery صراحة؛ `cancel-delivery v5` يحتاج عقدًا ذريًا موثقًا وفحصًا كاملًا للأخطاء.
8. **سبب الرفض والتحصيل:** `reason_delivery/notes` mismatch قد يفقد السبب بعد reload؛ `amount_paid` لا يثبت إيصالًا أو قيدًا ماليًا.
9. **Runtime log:** سجل Supabase يثبت طلب GET حقيقيًا من `rawaea-erp.pages.dev` إلى `runsheets` مع filter على driver وLoaded، HTTP 200 وجسم استجابة بطول 2 bytes عند `2026-10-26T14:24:53.719Z`. يثبت أن عميلًا منشورًا استعلم مباشرة، ولا يثبت أن كل الحسابات تفشل.

## 5. الاختبارات

| الاختبار | النتيجة |
|---|---|
| جلب المصدر الكامل وفحص مواضع الاستدعاء | PASS |
| قراءة Edge Registry/Source للوظائف المحددة | PASS |
| Production schema/RLS/RPC/triggers للنطاق المفحوص | PASS |
| Production baseline | PASS: RS-1/RS-2 Loaded غير مسندين |
| Consumer trace | عيوب مثبتة |
| Static parse | تقرير 506 السابق يسجل PASS؛ لم يُعد تشغيل Browser parser هنا |
| Authenticated supervisor/driver E2E | NOT RUN |
| wrong-company/wrong-driver/retry/concurrency | NOT RUN |
| Cloudflare-served HTML parity | UNVERIFIED |
| Fixture cleanup | NONE CREATED |

## 6. القرار التنفيذي والإصلاح التالي

لم أغيّر HTML أو Core أو Edge أو RPC/RLS أو بيانات أعمال في هذه الدورة. لا أُسند RS-1/RS-2 ولا أختبر سحب/إنهاء رحلة حقيقية. لا توجد جلسة Browser مصادق عليها أو staging fixture معزول مثبت؛ نشر تغييرات تفويض مباشرة دون اختبار آمن قد يسمح بتجاوز صلاحيات أو يعطل عملية فعلية. هذا قيد محدد على E2E وليس مبررًا لإيقاف الأعمال الساكنة.

ترتيب الإغلاق:
1. إصلاح `force-unassign-runsheet`, `complete-delivery`, `complete-order-delivery` وCore `complete_order_delivery_atomic` لفرض auth_id، الشركة، نشاط المستخدم، الصلاحية، driver assignment وحالة Delivering ذريًا.
2. توفير عقد ذري لإسناد Loaded للمشرف؛ لا تستخدم `manage_runsheet_atomic` الحالي كما هو.
3. إصلاح `get-driver-dashboard` الموجود بدل إنشاء endpoint مكرر.
4. بعد ثبات الخلفية، تعديل واجهتي المشرف والسائق جراحيًا لإزالة direct writes/reads غير الآمنة، وإظهار الأخطاء، ومطابقة `reason_delivery` وعقد التحصيل.
5. إعداد staging/fixtures معزولة لشركتين وسائقين ورانشيتات اختبار، ثم normal/retry/duplicate/concurrent/wrong-company/wrong-driver/partial/refused/rollback tests.
6. بعد نجاح الاختبارات المعزولة: deploy منفصل، إعادة قراءة Production Registry/SQL، HTTP E2E مصادق عليه، baseline restoration، والتأكد من عدم إنشاء حركة مخزون ثانية.
7. ربط Git commit/blob مع Production version و`ezbr_sha256` بسلسلة provenance موثقة.

## 7. Mutation ledger
لم يتغير `supervisor.html` أو `driver.html` أو `core.js` أو Edge/RPC/schema/RLS أو بيانات runsheets/orders/inventory/finance. التغييرات في هذه الدورة توثيقية فقط.

## 8. SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي وSHA؛ مسارات direct table access؛ عيوب التفويض المحددة؛ baseline الحي؛ وجود سجل REST حقيقي لقراءة مباشرة من العميل المنشور.
- **What I Did Not Prove:** authenticated E2E، Cloudflare/Git parity، lineage الكاملة، تحصيل مالي فعلي، فشل كل حساب مشرف/سائق.
- **What I Fixed:** لا إصلاح تشغيلي؛ تم تحديث التقرير والحالة فقط.
- **What I Initially Missed:** تعارض صلاحية المشرف مع RLS؛ ثغرة تفويض force-unassign؛ عدم تحقق السائق المعيّن في إنهاء الرحلة/الأوردر.
- **What Could Still Be Wrong:** consumers أخرى خارج النطاق المفحوص؛ Cloudflare قد يختلف عن Git؛ آثار مالية خارج العقد؛ provenance غير مكتملة.
- **Final Confidence:** مرتفعة للعيوب المدعومة مباشرة؛ متوسطة لشمول consumer sweep؛ غير كافية لإثبات runtime.
- **Final Closure Status:** `PARTIAL / SECURITY & ASSIGNMENT CONTRACT OPEN / AUTHENTICATED E2E NOT RUN / NOT CLOSED`.

### تعليمات الاستئناف
أعد جلب Production Registry وSQL في جلسة الإصلاح. لا تستخدم RS-1/RS-2 كـfixtures. لا تعدّل HTML قبل إغلاق التفويض الخلفي، ولا تعلن الإغلاق قبل E2E مصادق عليه مع fixture معزول واستعادة baseline.
