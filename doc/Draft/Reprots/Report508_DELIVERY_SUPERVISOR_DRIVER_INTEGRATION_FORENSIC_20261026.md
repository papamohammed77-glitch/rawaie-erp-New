# تقرير 508 — تحقيق تكامل مشرف التوصيل ومندوب التوصيل مع النظام الأم وProduction

**وقت التحقيق:** 2026-10-26 16:17 UTC (قراءة PostgreSQL مباشرة)  
**الحالة:** `PARTIAL — BACKEND AUTHORIZATION/ASSIGNMENT DEFECTS CONFIRMED — AUTHENTICATED E2E NOT RUN — NOT CLOSED`  
**المستودع التشغيلي:** `papamohammed77-glitch/erp-frontend`, `main`  
**مستودع التوثيق:** `papamohammed77-glitch/rawaie-erp-New`, `main`  
**Production project:** `fiilmooggumokxanwiyx`

---

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — 96/100 (evidence-based):** المشرف يوزع الرانشيتات المحمّلة على مندوب التوصيل ويراقب الفريق؛ السائق/المندوب يبدأ رحلة الرانشيت المعيّن إليه، يسجل نتائج التسليم، ثم ينهيها. في نموذج RAWAEA يجب فصل هوية المركبة عن هوية المستخدم، والسماح للشركة بتعيين شخص واحد للدورين أو شخصين مختلفين دون خلط الحسابين.
- **Architecture Understanding — 94/100:** واجهتا Delivery مستقلتان فوق Core وEdge وPostgreSQL. وجود `service_role` في Edge يرفع أهمية التحقق الصريح من الهوية والشركة والصلاحية والتعيين والحالة في كل Endpoint/RPC.
- **Database Understanding — 95/100 للنطاق المفحوص:** تم فحص أعمدة `runsheets`، وسياسات RLS الخاصة بـ`runsheets` و`users`، وتعريف `manage_runsheet_atomic`، وعينة بيانات الرانشيتات والمستخدمين مباشرة من Production.
- **Historical Understanding — 82/100:** تمت قراءة `CURRENT_STATE.md` وآخر حدث LVE-507، وReport507، والبرومبت التنفيذي كاملًا في نطاقه، ومراجعة أحدث commits المتاحة. لم تُستكمل بعد ancestry كاملة لكل Edge/SQL artifact.
- **Production Understanding — 95/100 للنقاط المدرجة:** تم فحص Production في هذه الجلسة، لا الاكتفاء باللقطة السابقة. وقت PostgreSQL الحي المرصود: `2026-10-26 16:17:00.391819+00`.
- **Current Understanding — 94/100:** جُلب `supervisor.html` و`driver.html` من مستودع التشغيل، وفُحصت مسارات الواجهة ذات الصلة، مع مراجعة Core وEdge الحالية.
- **Execution Confidence — 90/100 للتشخيص، 0% لإثبات E2E المصادق عليه:** العيوب أدناه مثبتة من الكود/SQL/Registry. لا يوجد دليل على نجاح رحلة E2E فعلية؛ لذلك لا تُمنح نسبة إغلاق تشغيلية.

### حالة الأدلة
- **Confirmed:** مسارات direct DB access في المشرف؛ عدم دعم `Loaded` في `manage_runsheet_atomic`؛ سياسات RLS؛ هوية مستخدمي التوصيل والشركة؛ إصدارات Edge الحية المذكورة أدناه.
- **Unknown:** تطابق HTML الذي يقدمه Cloudflare مع Git في وقت هذا التحقيق؛ نتائج E2E مصادق عليه للمشرف والسائق؛ ancestry القابلة لإعادة البناء لكل حزمة Edge.
- **Conflicts:** واجهة المشرف تتعامل مع الرانشيت المحمّل كقابل للتعيين مباشرة، بينما RPC المركزي `manage_runsheet_atomic` يقبل UPDATE فقط في حالتي `Open/Confirmed`.
- **Unverified Claims:** لا أدعي أن المشكلة تؤثر في كل حساب أو كل استدعاء، ولا أدعي أن إصلاحًا نُشر أو أن Runtime E2E اجتاز.
- **Historical Opened:** `CURRENT_STATE.md`, LVE-507/Report507، `MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md`، `writing-block.md`.
- **Original Opened:** لم أجرِ مقارنة Original تاريخية كاملة لكل Edge في هذه الوحدة؛ موثقة كفجوة Provenance، لا كدليل على فقدان الملف.
- **Production Opened:** PostgreSQL time/schema/RLS/function definition/current rows + Edge Registry + deployed sources.
- **Current Opened:** `companies/company-1/delivery/supervisor.html`, `companies/company-1/delivery/driver.html`, `companies/company-1/core.js`.
- **Schema Checked:** `runsheets`, وسياسات `runsheets/users`، وRPC signature.
- **Triggers Checked:** لم أغيّر البيانات أو أطلق انتقالات تشغيلية؛ لم أُكمل جرد كل triggers ذات الصلة في هذه الدورة.
- **Dependencies Checked:** `manage-runsheet`, `manage_runsheet_atomic`, `start-delivery`, `complete-delivery`, `complete-order-delivery`, `get-driver-dashboard`, `force-unassign-runsheet`.
- **Consumers Checked:** supervisor UI + driver UI + Edge/Core call paths المحددة أدناه.

---

## 2. مصدر الحقيقة والتغييرات منذ التقرير السابق

التقرير 507 لقطة تاريخية مفيدة، وليس مصدر الحقيقة الحالي. أُعيد التحقق مباشرة من Production في هذه الدورة.

### 2.1 Source identity

| Artifact | المصدر | Blob SHA / الدليل |
|---|---|---|
| مشرف التوصيل | `erp-frontend/companies/company-1/delivery/supervisor.html` | `4108d2330e567c432f08197013b9c3cf6221a5c7` |
| مندوب التوصيل | `erp-frontend/companies/company-1/delivery/driver.html` | `2df69860184f5a7c1b211ba059e1d6f57826c96b` |
| Core | `erp-frontend/companies/company-1/core.js` | `ff2f581d9900543c16f7cb026e13446520c0329d` |
| أحدث commit متاح من GitHub | `erp-frontend/main` | `40161bb3bef28cf6d8d2d6ba7938ee8807a63c23`؛ أحدث commits أخرى تشمل `90ba250a98bff2261721702093d46c76158abb69` و`78787abbede692c1d34176c25035b0128ee06c02`. |

هذه بصمات Git للملفات/commits، وليست بصمات HTML المنشور على Cloudflare. لا توجد هنا مطابقة served-byte للـHTML.

### 2.2 Production Edge registry — قراءة مباشرة

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

`ezbr_sha256` هو digest لحزمة Edge كما تعرضه Production registry، وليس Git commit SHA. لا أدعي provenance كاملة أو تطابقًا حرفيًا مع ملف Git.

---

## 3. Production database snapshot

وقت القراءة المباشر: `2026-10-26 16:17:00.391819+00`.

### 3.1 الرانشيتات الحالية

| runsheet_code | status | driver_id | deliverer_id | delivery_start | delivery_end | company_id |
|---|---|---|---|---|---|---|
| RS-1 | Loaded | NULL | NULL | NULL | NULL | `00000000-0000-0000-0000-000000000001` |
| RS-2 | Loaded | NULL | NULL | NULL | NULL | `00000000-0000-0000-0000-000000000001` |

لم أُسنِد RS-1/RS-2 ولم أستخدمهما كـfixtures ولم أغيّر أي بيانات أعمال.

### 3.2 هوية مستخدمي التوصيل الفعليين

قراءة `public.users` تؤكد أن `id` هو مفتاح التطبيق و`auth_id` يربط مستخدم Supabase Auth، وأن مستخدمي المشرف والسائقين في العينة ينتمون إلى الشركة نفسها. من العينة:
- مشرف التوصيل: `driver.supervisor@rawaea.com`, permissions = `delivery_supervisor, customers, runsheets`.
- مندوب: `driver@rawaea.com`, permissions = `delivery`.
- ثلاثة مستخدمين نشطين إضافيين لديهم `delivery`.

لا تعتمد هذه المعلومة على البريد وحده لتفويض العمليات؛ يجب أن تكون الهوية الموثقة هي `auth.uid()` ثم ربطها بـ`public.users.auth_id` وبالشركة.

### 3.3 RLS الحالية

سياسات `runsheets`:
- SELECT مشروط بتطابق `company_id` وبصلاحية `runsheets` أو `warehouse`.
- UPDATE مشروط بتطابق الشركة وبصلاحية `runsheets`.
- DELETE مشروط بتطابق الشركة وبصلاحية `runsheets`.
- لا تمنح السياسة للمشرف ذي `delivery_supervisor` وحدها حق SELECT/UPDATE المباشر.

سياسة `users_select_company` تسمح بقراءة سجل المستخدم لنفس `auth_id` أو بقراءة مستخدمين من الشركة لمن لديه `users`. لا تمنح `delivery_supervisor` وحدها قراءة قائمة الفريق كما تفعل الواجهة.

النتيجة: فشل الواجهة ليس مجرد مشكلة عرض؛ إنما العقد بين صلاحيات المشرف وعمليات القراءة/الكتابة المباشرة لا يتوافق مع RLS المنشورة. لا ينبغي حل ذلك بتوسيع RLS عشوائيًا أو منح كل مشرف صلاحية `runsheets/users` كاملة؛ الأفضل endpoint/RPC محدد الغرض يفحص صلاحية المشرف ونطاق الشركة.

---

## 4. Consumer trace: المشرف ↔ السائق ↔ Core/Edge/DB

### 4.1 `supervisor.html`

- `init()`: يستخدم `RW_Auth.init` ويقبل `owner` أو `delivery_supervisor` في الواجهة. هذا فحص UI فقط وليس تفويضًا خلفيًا.
- `renderDashboard()`: SELECT مباشر إلى `runsheets` و`users`.
- `renderTeam()`: SELECT مباشر إلى `users` و`runsheets`.
- `openAssignModal()`: SELECT مباشر للرانشيتات `Loaded` غير المسندة.
- `assignDriver()`: يقرأ المستخدم بالبريد ثم يكتب `runsheets.driver_id` مباشرة.
- `unassignDriver()`: يكتب `driver_id=NULL,status='Loaded'` مباشرة.
- `forceUnassign()`: يستدعي `force-unassign-runsheet`.

**النتيجة:** واجهة المشرف لا تملك عقد Backend متماسكًا لتعيين الرانشيتات المحمّلة؛ بعض القراءات قد ترجع بيانات فارغة بسبب RLS، وبعض الكتابات قد تُرفض. الواجهة كذلك لا تعرض كل أخطاء القراءة، فتستطيع تحويل خطأ صلاحيات إلى حالة «لا توجد بيانات».

### 4.2 `manage-runsheet` و`manage_runsheet_atomic`

- Edge موجود: ACTIVE v1 / JWT ON.
- يتحقق Edge من Auth، ويقرأ `public.users` بواسطة `auth_id`, ويستخرج الشركة والصلاحيات.
- لكنه يستدعي `manage_runsheet_atomic` الحالي.
- التعريف الحي يقفل صف الرانشيت، ثم يرفض UPDATE ما لم تكن الحالة `Open` أو `Confirmed`.
- لذلك لا يمكن إعادة استخدامه كما هو لتعيين `Loaded`؛ فهذا ليس تخمينًا بل شرط صريح في تعريف Production.
- لا يُعدّل RPC الحالي ولا تُغيّر حالاته لتجاوز هذا القيد دون اختبار آثار lifecycle/التحميل.

### 4.3 `driver.html`

- تسجيل الدخول يستخدم Supabase Auth مباشرة.
- بعد الدخول يقرأ `public.users` بالبريد، ويوجد fallback لإنشاء مستخدم من المتصفح مع `company_id` ثابت؛ هذا مسار غير مقبول أمنيًا ويجب إزالته في patch جراحي.
- قراءات مباشرة لـ`items`, `app_settings`, `runsheets`, `orders`, `order_details`, `run_sheet_details`, `customers` تحتاج مواءمة مع RLS أو نقلها إلى endpoints مقيّدة.
- يستخدم `start-delivery`, `complete-delivery`, `cancel-delivery`, `complete-order-delivery`; وجود endpoint لا يثبت وحده صحة التفويض الكامل.

### 4.4 Backend defects المثبتة من Production source

1. `force-unassign-runsheet v1`: يبحث عن المستخدم بالبريد بدل ربط موثوق بـ`auth_id`، ولا يقرأ `company_id`/permissions/status لفرض تفويض المشرف؛ يجلب الرانشيت بالكود دون company scope، ثم يحدثه بالـid فقط. يستخدم `service_role`، لذلك يجب أن يتحقق بنفسه من الشركة والصلاحية.
2. `complete-delivery v4`: يتحقق من أن الحالة `Delivering` ومن الشركة، لكنه لا يتحقق أن المستخدم هو `runsheets.driver_id` قبل إنهاء الرحلة.
3. `start-delivery v7`: يربط المستخدم بالبريد ويقيد الرانشيت بالشركة والحالة والتعيين؛ لكنه لا يفرض permission `delivery` صراحةً، كما أن lookup بالبريد أقل موثوقية من `auth_id`.
4. `complete-order-delivery v14`: يربط المستخدم بـ`auth_id` ويقيد الشركة، لكنه لا يفرض صراحة صلاحية `delivery` أو تعيين السائق أو حالة الرانشيت داخل Edge قبل استدعاء `complete_order_delivery_atomic`. يجب فرض invariants داخل المعاملة نفسها حتى لا يمكن تجاوزها بمستدعي RPC آخر.
5. `get-driver-dashboard v1`: الاستعلام عن الرانشيت النشط يختار `runsheet_code,status,run_date,vehicle_id,delivery_start,total_amount` لكنه لا يختار `id`، ثم يستخدم `activeRS.id` في جلب `orders` و`run_sheet_details`. كما لا يفحص أخطاء الاستعلامات أو صلاحية المستخدم/الشركة بما يكفي. هذا defect في المصدر المنشور.
6. `cancel-delivery v5`: يحتاج توحيد الهوية والتفويض والتحقق من حالة/تعيين الرانشيت ومعالجة أخطاء الكتابة. لم أختبره runtime.
7. في الواجهة، `driver.html` يقرأ `order_details.notes` بينما المسار الخلفي الموثق يكتب `reason_delivery`؛ لذلك سبب الرفض قد لا يبقى ظاهرًا بعد إعادة التحميل.
8. `amount_paid` في payload لا يثبت أنه حُفظ كتحصيل أو قيد مالي؛ لا يجوز إظهار تحصيل مؤكد دون عقد مالي/ledger فعلي.
9. بيانات `driver_id` تخص مندوب/مستخدم التنفيذ في المسار الحالي؛ لا يجوز تفسيرها على أنها `vehicle_id`. المركبة تبقى كيانًا مستقلًا في `runsheets.vehicle_id`.

---

## 5. LOSS / GAIN / RESPONSIBILITY MATRIX

| المسؤولية | الحالة | الدليل / الإجراء |
|---|---|---|
| مصادقة المشرف عبر Core | RETAINED جزئيًا | `RW_Auth` في supervisor؛ لا يغني عن تفويض الخادم. |
| قراءة لوحة المشرف | CONFLICT | Direct SELECT لا يطابق RLS لصلاحية `delivery_supervisor` فقط. |
| قراءة فريق السائقين | CONFLICT | Direct SELECT إلى `users` لا تمنحه السياسة للمشرف وحده. |
| إسناد Loaded | MISSING في العقد الحالي | الواجهة تكتب مباشرة؛ `manage_runsheet_atomic` يرفض Loaded. |
| فك الإسناد العادي | CONFLICT | Direct UPDATE؛ لا توجد معاملة/تدقيق موثوق مثبتان في الواجهة. |
| السحب الاضطراري | MISSING / SECURITY DEFECT | Edge لا يثبت صلاحية/شركة المستخدم أو نطاق الرانشيت. |
| بدء الرحلة | HARDENED جزئيًا | الشركة والحالة والتعيين مفحوصة، لكن هوية المستخدم والصلاحية تحتاج توحيدًا. |
| إنهاء الرحلة | MISSING guard | لا يثبت تطابق المستخدم مع السائق المعيّن. |
| إكمال كل طلب | CONFLICT / MISSING guards | يجب فرض assignment/status داخل Core transaction. |
| لوحة السائق | MISSING / DEFECT | `activeRS.id` غير موجود في SELECT المستخدم. |
| تحصيل الأموال | UNKNOWN | لا يوجد إثبات كافٍ على ledger/receipt effect من payload الحالي. |
| Physical stock | RETAINED by architecture | التوصيل لا ينبغي أن يكرر حركة المخزون التي تمت عند Loading. |
| فصل السائق عن المركبة | RETAINED in schema | `driver_id` و`vehicle_id` حقلاّن منفصلان؛ يجب الحفاظ على الفصل في التعيين. |

---

## 6. المعايير الصناعية — ماذا نستفيد دون نسخ أعمى

- توثيق SAP Transportation Management يصف تخطيط النقل بوصفه مسارًا يشمل الطلبات/التسليمات، التخطيط، تعيين الموارد/المركبات، الإرسال، ومراقبة التنفيذ؛ كما يتيح تخطيطًا يدويًا أو آليًا وفق قيود السعة والموعد والتكلفة. المصدر: https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/e3dc5400c1cc41d1bc0ae0e7fd9aa5a2/9c27c9535f267414e10000000a174cb4.html وhttps://help.sap.com/docs/SAP_SUPPLY_CHAIN_MANAGEMENT/49dd58c18be2493b80f84359d659f4a4/764cc95360267614e10000000a174cb4.html
- توثيق Microsoft Dynamics 365 يوضح أن بناء الحمولة/الشحنة والتخطيط ثم التوجيه والتعيين خطوات مترابطة، وأن العمل على الحمولة يجب أن يستند إلى الطلبات والسعة وقواعد النقل، لا إلى تحديث UI منفصل. المصدر: https://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/transportation-management-overview وhttps://learn.microsoft.com/en-us/dynamics365/supply-chain/transportation/use-load-planning-workbench-plan-loads-shipments
- توثيق Oracle Transportation Management يميّز بين السائقين والمركبات/معدات النقل ويدعم work assignments لإسناد الشحنات للسائقين مع مراعاة ساعات عملهم. المصدر: https://docs.oracle.com/en/cloud/saas/transportation/26c/otmol/asset_mgt/about_fleet_management.htm

**تطبيق هذه المبادئ على RAWAEA:** الإسناد كيان تشغيلي ذري ومؤرشف، وليس UPDATE مباشرًا من الواجهة. يجب أن تكون المركبة والسائق/المندوب كيانين مستقلين، مع دعم نمط موظف واحد يؤدي الدورين أو موظفين منفصلين. تعيين الرانشيت يثبت على مستوى الشركة والحالة والسعة، ثم يُنشر للمندوب، ويُمنع تغيير الإسناد أثناء التسليم إلا عبر أمر سحب اضطراري مصرح به ومؤرخ يحفظ الكميات المنفذة.

---

## 7. خطة الإصلاح الصحيحة (مرتبة، قابلة للإغلاق)

### Closure Unit A — عقد الإسناد الذري لـLoaded Runsheet
1. لا توسع RLS مباشرةً لتجاوز المشكلة.
2. أضف/وسّع أمرًا صريحًا في `delivery_logistics_command_atomic` أو RPC معتمد مكافئ، بعد قراءة تعريفه كاملًا وACL والـtriggers.
3. مدخلات العقد: company_id من سياق Auth الموثوق، runsheet_id/code، driver user ID، vehicle_id اختياري وفق سياسة الشركة، operation_id، actor identity.
4. داخل transaction: lock على الرانشيت؛ تحقق الشركة؛ الحالة Loaded؛ عدم وجود driver تعيين متعارض؛ تحقق أن المندوب نشط ولديه `delivery`؛ تحقق المركبة النشطة من نفس الشركة؛ تحقق عدم ازدواج إسناد المركبة/السائق وفق سياسة الجدولة؛ سجل audit event؛ ثم تحديث ذري وإرجاع snapshot.
5. اجعل retry بنفس `operation_id` idempotent، وارفض operation_id نفسه بمحتوى مختلف.
6. Edge موجود/مخصص يتحقق من `auth.getUser(token)` ثم يربط `auth.uid()` بـ`public.users.auth_id`، ويطلب `delivery_supervisor` أو owner policy صريحة، ولا يثق في `company_id` من payload.
7. اختبر normal/duplicate/retry/concurrent/wrong-company/inactive-driver/invalid-vehicle، ثم deploy بعد نجاح الاختبارات.

### Closure Unit B — إصلاح نقاط نهاية السائق
- `get-driver-dashboard`: أضف `id` إلى select، استخدم `auth_id`، تحقق من الشركة والنشاط وصلاحية `delivery`، افحص كل أخطاء SQL، وأعد فقط البيانات التي تخص السائق المعيّن.
- `start-delivery`: وحّد lookup على `auth_id`، تحقق من permission `delivery`, واجعل تحديث الحالة conditional/atomic حتى لا يبدأ طلبان متزامنان الرحلة نفسها.
- `complete-delivery`: تحقق من `driver_id = public.users.id` ومن الشركة والحالة داخل update/transaction، وليس في UI فقط.
- `complete-order-delivery` و`complete_order_delivery_atomic`: فرض صلاحية/تعيين/حالة الرانشيت داخل المعاملة، مع قفل الصف؛ لا تعتمد على فحص Edge وحده.
- `force-unassign-runsheet`: ربط المستخدم بـ`auth_id` والتحقق من نشاطه وصلاحية المشرف والشركة، وتقييد كل قراءة/تحديث بـcompany_id وstatus؛ audit insert وupdate يجب أن يكونا في معاملة واحدة، وإلا قد يسجل الحدث دون إتمام العملية أو العكس.
- `driver.html`: إزالة إنشاء `public.users` من المتصفح نهائيًا؛ لا hardcoded company_id؛ استبدال direct reads بواجهات مقيّدة أو RLS contract مقصود؛ توحيد `reason_delivery`; عدم ادعاء تحصيل `amount_paid` قبل وجود receipt/ledger effect مؤكد.

### Closure Unit C — UI supervisor
بعد إتاحة عقد backend واختباره:
- نقل `renderDashboard/renderTeam/openAssignModal` إلى endpoint يقرأ ضمن company scope ويعيد أخطاء واضحة.
- نقل `assignDriver/unassignDriver` إلى أوامر backend ذرية.
- لا تستخدم `manage-runsheet` الحالي لإسناد Loaded لأنه يرفض الحالة صراحة.
- عرض loading/error/empty states منفصلة؛ لا تحول RLS/network error إلى قائمة فارغة.
- حافظ على `driver_id` منفصلًا عن `vehicle_id`; لا تفترض أن كل شركة تستخدم الشخص نفسه للسياقة والتوصيل.

### Closure Unit D — E2E وإثبات الإنتاج
- أنشئ fixtures معزولة في Staging أو شركة اختبار منفصلة؛ لا تستخدم RS-1/RS-2 الحالية.
- نفذ Authenticated HTTP/Browser E2E: supervisor login → team list → assign Loaded runsheet → driver login → start delivery → per-order partial/refused/delivered → complete delivery → audit/ledger checks.
- اختبر wrong company, wrong driver, inactive user, duplicate, retry, concurrent assign/start/complete.
- أثبت عدم تغير `stock_branches.qty`, `allocated_qty`, `inventory_log` بسبب delivery completion نفسها؛ المخزون الفعلي لا يُخصم مرتين.
- تحقق من baseline restoration، وعدم بقاء fixtures، ثم اقرأ Production Edge Registry/SQL والـserved HTML مرة أخرى.

---

## 8. مصفوفة الاختبارات الفعلية

| الاختبار | النتيجة | البيئة / الدليل |
|---|---|---|
| إعادة قراءة Production clock | PASS | SQL مباشر عند `2026-10-26 16:17:00.391819+00`. |
| قراءة أعمدة `runsheets` | PASS | SQL مباشر؛ `driver_id`, `vehicle_id`, `deliverer_id`, `delivery_start/end` موجودة. |
| قراءة RLS لـ`runsheets/users` | PASS للتحقيق | السياسات الحية لا تمنح `delivery_supervisor` وحدها القراءة/التحديث المباشر المستخدم بالواجهة. |
| قراءة تعريف `manage_runsheet_atomic` | PASS للتحقيق | تعريف Production يقبل UPDATE فقط في Open/Confirmed. |
| قراءة Edge registry/source | PASS للتحقيق | الوظائف التسع وإصداراتها أعلاه. |
| قراءة current supervisor/driver | PASS للتحقيق | GitHub `erp-frontend/main`؛ SHA مسجل. |
| Normal assignment في Production | NOT RUN | لا تغيير بيانات أعمال. |
| Wrong-company / wrong-driver | NOT RUN | يحتاج fixtures/credentials معزولة. |
| Authenticated supervisor/driver E2E | NOT RUN | لا يوجد في هذه الدورة سياق Browser مصادق عليه أو Staging fixture مثبت. |
| Concurrent assignment/start/complete | NOT RUN | لا تُختبر على الرانشيتات التشغيلية الحالية. |
| Cloudflare served HTML parity | UNVERIFIED | لا توجد بصمة HTML منشور موثقة في هذا التحقيق. |
| Baseline restoration | PASS — unchanged | لم تُنشأ fixtures ولم تُعدّل بيانات أعمال. |
| Production deployment | NOT PERFORMED | لم أنشر Edge/SQL أو أعدل RLS/HTML. |

---

## 9. Mutation ledger

**تم:**
- قراءة مباشرة لوقت Production، أعمدة الرانشيتات، سياسات RLS لـ`runsheets/users`، تعريف `manage_runsheet_atomic`، صفوف الرانشيتات، ومستخدمين نشطين للتوصيل.
- جلب مصادر Edge الحية للوظائف المحددة.
- جلب ملفات المصدر من مستودع التشغيل ومراجعة أحدث commits المتاحة.
- إعداد هذا التقرير وتحديث `CURRENT_STATE.md`.

**لم يتم:**
- لا تعديل على `supervisor.html` أو `driver.html` أو `core.js`.
- لا نشر Edge Function.
- لا DDL أو تعديل RPC/RLS/trigger.
- لا تعديل على users/runsheets/orders/stock/ledger.
- لا fixtures ولا canaries.
- لا ادعاء باجتياز HTTP E2E أو Browser E2E.

سبب عدم النشر ليس نقصًا عامًا في الصلاحية، بل غياب مسار اختبار معزول يثبت سلامة التفويض والمعاملة قبل تغيير خدمة تستخدم `service_role` على بيانات إنتاجية. الأعمال الساكنة والتحقيقات الممكنة استُكملت، والخطوة التالية محددة أعلاه.

---

## 10. SELF-AUDIT FINAL

- **What I Proved:** RLS/direct-access conflict؛ Loaded-assignment contract gap؛ defects في تفويض عدة Edge functions؛ bug `activeRS.id` في لوحة السائق؛ identity/company fields الحية؛ baseline الحالي؛ أن التوصيل يجب ألا ينشئ حركة مخزون ثانية.
- **What I Did Not Prove:** لا E2E مصادق عليه، لا concurrency runtime، لا Cloudflare HTML parity، ولا provenance كاملة من Git blob إلى حزمة Edge.
- **What I Fixed:** لا إصلاح تشغيلي نُشر في هذه الدورة؛ تم تحديث سجل الأدلة والتقرير فقط.
- **What I Initially Missed:** يجب عدم اعتبار وجود `manage-runsheet` دليلًا على إمكانية إسناد `Loaded`; تعريف RPC يرفض ذلك صراحة.
- **What Could Still Be Wrong:** قد توجد سياسات/Triggers إضافية أو تغييرات أحدث غير ظاهرة في مسارات الفحص المحددة؛ يجب فحصها عند تنفيذ كل Closure Unit. لا أستنتج أن كل حسابات التوصيل متعطلة من سجل HTTP واحد.
- **Final Confidence:** مرتفع في العيوب المحددة من source/Production؛ غير كافٍ للحكم على نجاح التشغيل end-to-end.
- **Final Closure Status:** `PARTIAL — NOT CLOSED`.
- **Remaining debt:** Backend authorization/assignment contract، dashboard endpoint، UI direct access، delivery accounting proof، runtime E2E، Cloudflare parity، full provenance.

**تعليمات المساعد التالي:** ابدأ بـClosure Unit A (Loaded assignment contract)؛ اقرأ تعريف `delivery_logistics_command_atomic` وACL/triggers كاملًا قبل تغييره، ثم نفذ اختبارًا معزولًا. لا تعاود استخدام RS-1/RS-2 كبيانات اختبار، ولا توسّع RLS لمجرد إخفاء خطأ العقد، ولا تعلن `100% CLOSED` قبل إثبات E2E والاستعادة.
