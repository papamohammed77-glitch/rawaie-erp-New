# تقرير تحقيق تكامل مشرف التوصيل مع النظام الأم — Report507

**التاريخ:** 2026-10-27  
**النطاق:** Delivery Supervisor → تعيين مندوب التوصيل إلى Runsheet → النظام الأم  
**الحالة:** `ROOT CAUSE CONFIRMED / LIVE ASSIGNMENTS PERSISTED / PARENT CONTRACT MISMATCH / REPAIR NOT APPLIED / E2E NOT RUN / PARTIAL`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** CONFIRMED — يجب أن يظهر إسناد مندوب التوصيل للرانشيت في النظام الأم، مع الفصل بين مندوب التوصيل والسائق التشغيلي والمركبة.
- **Architecture Understanding:** CONFIRMED — التطبيق التشغيلي يستخدم عقد PostgreSQL مخصصًا؛ النظام الأم يحتوي أيضًا مركزًا مستقلًا لإدارة التوصيل واللوجستيات يعتمد كيانات Delivery Agent وRoute Plan.
- **Database Understanding:** CONFIRMED — توجد بالفعل الجداول `public.runsheets`, `public.users`, `public.delivery_agents`, `public.delivery_route_plans`, `public.delivery_route_stops`؛ لا توجد حاجة مثبتة لإنشاء جدول جديد.
- **Historical Understanding:** PARTIAL — تمت قراءة `CURRENT_STATE.md` و`writing-block.md` حتى نهاية التوجيه التنفيذي، ومراجعة سجل التكامل السابق. لم تكتمل مقارنة كل commit تاريخي للوظائف الثلاث في هذه الدورة.
- **Production Understanding:** CONFIRMED جزئيًا — فُحصت مباشرة تعريفات RPC والـACL ومخطط Production والبيانات الحالية بتاريخ 2026-10-27 12:57–13:00 UTC.
- **Current Understanding:** CONFIRMED — أُعيد جلب ملف المشرف الحالي من `erp-frontend/main`.
- **Execution Confidence:** مرتفعة في السبب الجذري الخاص بانفصال عقد البيانات؛ غير كافية لإعلان إصلاح أو إغلاق لأن التغيير لم يُطبّق ولم يُنفذ E2E.

### حقائق / مجهولات / تعارضات

- **CONFIRMED:** عملية المشرف تكتب `runsheets.deliverer_id` باستخدام `public.users.id`.
- **CONFIRMED:** تبويب «مناديب التوصيل» في النظام الأم يقرأ `public.delivery_agents`، ويحسب الرحلات النشطة من `public.delivery_route_plans`.
- **CONFIRMED:** سجل الرانشيت الحالي وجدول ملفات المندوبين وخطط المسارات ليست نموذجًا واحدًا؛ ربط `runsheets.deliverer_id` وحده لا ينشئ ملف Delivery Agent ولا Route Plan.
- **CONFIRMED:** لم تظهر صفوف في `delivery_agents` أو `delivery_route_plans` في قراءة Production الحالية، بينما توجد إسنادات فعلية في `runsheets.deliverer_id`.
- **UNKNOWN:** هل توجد نسخة HTML منشورة على Cloudflare تطابق Blob المصدر الحالي؛ لم يتوفر تحقق مباشر من artifact المنشور في هذه الدورة.
- **NOT RUN:** اختبار HTTP/E2E مصادق عليه؛ لم تُجرَ عملية إسناد اختبارية جديدة ولم تُستخدم RS-1 أو RS-2 كـfixtures.
- **CONFLICT:** السلوك التشغيلي الحالي يسجل الإسناد على الرانشيت، بينما عرض النظام الأم «مناديب التوصيل» يعتمد على ملفات المندوبين وخطط المسارات؛ لا يوجد ربط تلقائي بين العقدين في وظيفة الإسناد الحالية.

## 2. مصادر الحقيقة التي تمت قراءتها

### المصدر التشغيلي

- المستودع: `papamohammed77-glitch/erp-frontend`
- الفرع: `main`
- الملف: `companies/company-1/delivery/supervisor.html`
- Blob SHA الحالي: `3e6db903cd7da411f9ed40a449f9ee5bece5f387`
- الملف المسترجع كاملًا. ينادي:
  - `delivery_supervisor_assignment_query` للوحة والفريق والرانشيتات.
  - `delivery_supervisor_assign_deliverer_atomic` للإسناد وفك الإسناد.
- في `assignDeliverer` يرسل `p_company_id`, `p_runsheet_code`, `p_deliverer_user_id`, `p_operation_id`. بعد النجاح يعيد تحميل الفريق؛ لا ينادي `delivery_logistics_command_atomic` ولا ينشئ Delivery Agent أو Route Plan.

### النظام الأم

- المستودع: `papamohammed77-glitch/erp-frontend`, الفرع `main`.
- `companies/company-1/main.html`، Blob SHA الحالي من GitHub API: `b9bd5698c98c4b3d7e2bc388bacfbf4f43f2a919`، 33,136 سطرًا تقريبًا.
- تعذر استخدام `fetch_file` لقراءة المحتوى بسبب حجم الملف؛ استُرجع الـGit blob الكامل وفُحصت مقاطع الوظائف المستهدفة.
- في مركز «إدارة التوصيل والشحن»:
  - تبويب «مناديب التوصيل» ينادي `delivery_logistics_query({p_view:'agents'})`.
  - قائمة المندوبين مبنية على `public.delivery_agents`.
  - عدد `active_routes` مشتق من `public.delivery_route_plans` بحالات `Planned/InProgress`.
  - تبويب «الرحلات والمسارات» يعرض `delivery_route_plans` ويربط المندوب من `delivery_route_plans.delivery_agent_id`.
  - تبويب «التخطيط» يقرأ `runsheets` ويكشف وجود خطة عبر `has_route_plan`.
  - إنشاء الخطة يتم عبر `delivery_logistics_command_atomic` بالأمر `ROUTE_PLAN_CREATE`، وإسناد المندوب داخل هذا المركز يتم عبر `ROUTE_AGENT_ASSIGN` مع `delivery_agent_id`، وليس عبر `runsheets.deliverer_id` فقط.
- كذلك فإن سجل التوصيل المخزني القديم `loadDelivery()` يقرأ `deliverer_id` ضمن المرشح، لكنه يعرض `driver_id` في عمود «السائق»؛ وهذا اختلاف عرض إضافي ولا ينبغي الخلط بينه وبين تبويب ملفات مندوبي التوصيل.

### Production Supabase

- المشروع: `fiilmooggumokxanwiyx`
- وقت قراءة المخطط والوظائف: 2026-10-27 12:57–13:00 UTC.
- تعريفات RPC التي فُحصت مباشرة:
  - `delivery_supervisor_assignment_query(uuid,text)`
  - `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)`
  - `delivery_supervisor_complaints_query(uuid)`
  - `delivery_logistics_query(uuid,text,jsonb,uuid,text)`
  - `delivery_logistics_command_atomic(uuid,text,jsonb,text,uuid,text)`
- `delivery_supervisor_assign_deliverer_atomic` هو `SECURITY DEFINER`، يتحقق من `auth.uid()` ثم يطابق `public.users.auth_id=auth.uid()`، ويتحقق من الشركة والصلاحية، ويثبت idempotency في `erp_operation_registry`، ثم يحدث `runsheets.deliverer_id`. لا ينشئ أو يحدّث `delivery_agents` أو `delivery_route_plans`.
- صلاحيات EXECUTE الحالية لهذه الوظائف متاحة لـ`authenticated` و`service_role` و`postgres` بحسب قراءة ACL؛ لم يظهر منح `anon` ضمن ACL المعروضة.
- قيود Production تؤكد:
  - `runsheets.deliverer_id → users.id`
  - `delivery_route_plans.delivery_agent_id → delivery_agents.id`
  - `delivery_route_plans.runsheet_id → runsheets.id`
  - قيد فريد `UNIQUE(company_id, runsheet_id)` على خطط المسارات.
  - `delivery_agents.user_id` هو رابط اختياري بين ملف المندوب وحساب المستخدم.
- لا يوجد جدول ربط منفصل مطلوب لإنشاء العلاقة؛ الجداول الحالية توفر روابط الهوية اللازمة.

## 3. دليل الحالة الحية

في القراءة المباشرة بتاريخ 2026-10-27 12:58:57 UTC ظهرت رانشيتان ضمن الشركة `00000000-0000-0000-0000-000000000001`:

| Runsheet | الحالة | deliverer_id | driver_id | vehicle_id |
|---|---|---|---|---|
| RS-1 | Loaded | `0912a68e-a2d6-4e3a-b44d-41f8826fb900` | NULL | موجود |
| RS-2 | Loaded | `5fc15ecf-450c-4499-8edb-eb5bd4fbf963` | NULL | موجود |

والـ`deliverer_id` لكل منهما يطابق `public.users.id` لمستخدم نشط يحمل صلاحية `delivery`. هذه حقيقة قاعدة بيانات حالية، لكنها لا تثبت أن المستخدم رأى النتيجة في المتصفح أو أن آخر عملية إسناد تمت من واجهة المشرف في هذه الجلسة.

في الاستعلام نفسه، أعادت `delivery_agents` و`delivery_route_plans` قيمة فارغة (`null` في ملخص الاستعلام)، ما يتسق مع كون مركز النظام الأم لا يملك ملفات مندوبين أو خططًا يقرأ منها العرض الحالي.

## 4. السبب الجذري

**السبب الجذري المثبت هو انفصال عقد الإسناد عن عقد عرض النظام الأم، وليس فشل حفظ `runsheets.deliverer_id`.**

التدفق الحالي:

```
Delivery Supervisor
  → delivery_supervisor_assign_deliverer_atomic
  → runsheets.deliverer_id = users.id
```

بينما يتوقع مركز النظام الأم:

```
Delivery Logistics
  → delivery_agents.id / delivery_agents.user_id
  → delivery_route_plans.delivery_agent_id
  → delivery_route_plans.runsheet_id
  → delivery_logistics_query('agents' | 'routes')
```

لا تقوم وظيفة الإسناد الحالية بإنشاء/مطابقة ملف `delivery_agents` ولا بربط `delivery_route_plans`. ولذلك يمكن أن تكون عملية الإسناد ناجحة ومحفوظة في `runsheets`، بينما تظل قائمة «مناديب التوصيل» وخطط المسارات غير متأثرة. إنشاء جدول جديد لن يعالج السبب؛ المطلوب توحيد العقد الحالي مع الحفاظ على فصل هوية السائق والمندوب.

## 5. تقييم التعديلات الحالية على supervisor.html

- **RETAINED:** استخدام Core المشترك للمصادقة `RW_Auth`، والتحقق من `company_id`، وعدم تغيير `driver_id` أو `vehicle_id` أثناء إسناد مندوب التوصيل.
- **RETAINED:** استخدام RPC ذري بدل الكتابة المباشرة من HTML.
- **CONFIRMED DEFECT:** المستهلك يرسل User ID، والـRPC يخزن هذا الـID في `runsheets.deliverer_id` فقط؛ لا يوجد أثر تكامل إلى نموذج Delivery Agent/Route Plan.
- **SECURITY NOTE:** التحقق من الصلاحيات ونطاق الشركة موجود داخل RPC، لكن يجب أن يبقى هذا التحقق على الخادم. لا ينبغي منح وصول مباشر واسع إلى الجداول لإخفاء مشكلة التكامل.
- لم يُعدّل ملف HTML في هذه الدورة، وفق قاعدة المشروع التي تسند تعديل ملفات HTML التشغيلية إلى المالك. لا أدّعي أن نسخة Cloudflare تطابق Blob الحالي.

## 6. مصفوفة Loss / Gain / Responsibility

| المسؤولية | الحالة | الدليل / القرار |
|---|---|---|
| إسناد المندوب إلى الرانشيت في runsheets | RETAINED | `runsheets.deliverer_id` موجود ويُحدّث عبر RPC ذري |
| هوية مستخدم المندوب | RETAINED | `users.id`، مع ربط Auth عبر `users.auth_id` |
| ملف المندوب الإداري | MISSING DATA / STRUCTURE EXISTS | `delivery_agents` موجود لكنه بلا صفوف ظاهرة في الاستعلام الحالي |
| الربط بين ملف المندوب وحساب المستخدم | MISSING DATA / STRUCTURE EXISTS | `delivery_agents.user_id` موجود؛ لا يوجد ملف مطابق مثبت في البيانات المقروءة |
| خطة الرحلة المرتبطة بالرانشيت | MISSING DATA / STRUCTURE EXISTS | `delivery_route_plans` موجود لكنه بلا صفوف ظاهرة في الاستعلام الحالي |
| إظهار المندوب في قائمة النظام الأم | CONFLICT | العرض يعتمد `delivery_agents` لا `runsheets.deliverer_id` |
| إظهار إسناد الرانشيت في صفحة المسارات | CONFLICT | العرض يعتمد `delivery_route_plans.delivery_agent_id` |
| إنشاء جدول جديد | INTENTIONALLY NOT DONE | لا توجد حاجة مثبتة؛ الجداول الحالية تكفي لتمثيل العلاقات |

## 7. الإصلاح المطلوب — لم يُطبّق بعد

الإصلاح الدائم يجب أن يستخدم نموذج البيانات الحالي لا أن ينشئ جداول مكررة:

1. **حسم عقد الإسناد:** يجب أن تنتقل عملية إسناد المشرف من مجرد تحديث `runsheets.deliverer_id` إلى تكامل ذري مع `delivery_agents` و`delivery_route_plans`، أو أن يُعدّل عرض النظام الأم ليعرض الإسنادات المباشرة من `runsheets` بوضوح. لا يجوز تنفيذ الخيارين معًا بصورة متضاربة.
2. **مطابقة هوية المندوب:** `p_deliverer_user_id` هو `public.users.id`؛ يجب إيجاد ملف `delivery_agents` عبر `company_id + user_id`، أو إنشاء الملف من خلال عقد إنشاء معتمد مع كود فريد وتحقق من التكرار. لا تستخدم `auth.users.id` بدل `users.id`.
3. **خطة الرحلة:** لا تُنشئ خطة تشغيلية مكتملة آليًا دون استيفاء عقد التخطيط. إن كانت الخطة شرطًا لعرض الإسناد، فأنشئ/اربط Draft وفق عقد `ROUTE_PLAN_CREATE` المثبت، ثم اربط المندوب بها مع الحفاظ على `UNIQUE(company_id,runsheet_id)`، أو عدّل Read Model لعرض الإسناد المباشر دون اختراع خطة.
4. **المعاملات والتكرار:** تحديث `runsheets.deliverer_id` وربط `delivery_route_plans.delivery_agent_id` يجب أن يكونا ذريين، مع قفل الرانشيت والخطة، والتحقق من الشركة والحالة، و`operation_id` idempotency.
5. **فك الإسناد:** يجب أن يزيل الربط من النموذجين المتفق عليهما دون تغيير السائق أو المركبة أو حالة الرانشيت.
6. **ملف HTML التشغيلي:** لا بد من تطبيق/التحقق من أي رقعة HTML وفق حوكمة المشروع؛ لا يمكن الادعاء أن التغيير منشور دون فحص Cloudflare.

### لماذا لم أُجرِ DDL/DML في هذه الدورة؟

المشكلة لا تحتاج جدولًا جديدًا، والـRPC الحالية تعدّل بيانات تشغيلية حقيقية. لم تتوفر بيئة Staging نشطة أو fixture معزول مثبت في هذه الدورة، كما لم يُنفذ HTTP E2E مصادق عليه. لذلك لم أغيّر وظيفة Production أو بيانات الأعمال بصورة غير قابلة للتحقق، ولم أستخدم RS-1 أو RS-2 كبيانات اختبار. هذا ليس إغلاقًا للمشكلة؛ بل توثيق لسبب عدم إجراء تغيير إنتاجي غير مختبر، مع إثبات السبب الجذري ومسار الإصلاح المحدد.

## 8. مصفوفة الاختبارات

| الاختبار | النتيجة | الدليل |
|---|---|---|
| استرجاع supervisor.html من GitHub | PASS | Blob SHA أعلاه |
| تحليل مسار RPC في HTML | PASS — static inspection | `assignDeliverer` و`openAssignModal` |
| قراءة تعريفات RPC وACL الحية | PASS — inspected scope | تعريفات Production أعلاه |
| التحقق من مفاتيح الهوية والعلاقات | PASS — schema inspection | FK وunique constraints أعلاه |
| التحقق من حفظ الإسناد الحالي | PASS — DB snapshot | RS-1 وRS-2 يحملان `deliverer_id` |
| إثبات أن قائمة المندوبين تستخدم `delivery_agents` | PASS — source + SQL | `delivery_logistics_query('agents')` |
| إثبات أن عرض المسارات يستخدم `delivery_route_plans` | PASS — source + SQL | `delivery_logistics_query('routes')` |
| إنشاء جدول جديد | NOT REQUIRED | البنية المطلوبة موجودة |
| إصلاح الربط/الـRead Model | NOT APPLIED | يحتاج عقدًا ذريًا معتمدًا وتغييرًا لم يُنشر |
| اختبار Static parse كامل بعد الإصلاح | NOT RUN | لم يحدث تعديل |
| Staging E2E | NOT RUN | لم تثبت بيئة نشطة معزولة |
| Production HTTP E2E | NOT RUN | لم تنفذ عملية اختبار مصادق عليها |
| Cloudflare served-artifact parity | UNVERIFIED | لم تتوفر قراءة مباشرة للـartifact المنشور |
| Baseline restoration | NOT RUN | لم تُنشأ fixture |

## 9. سجل التغييرات

- **APPLIED:** لا تغييرات تشغيلية أو DDL/DML في هذه الدورة.
- **CREATED:** هذا التقرير فقط (توثيق).
- **NOT CHANGED:** `supervisor.html`, `main.html`, `core.js`, RPCs، الجداول، السياسات، بيانات الأعمال، المخزون والدفاتر.
- لم تُنشأ جداول مكررة أو بيانات اختبار.
- لم يُدّعَ نشر أو E2E غير منفذ.

## 10. SELF-AUDIT FINAL

- **What I Proved:** مسار الإسناد الحالي يحفظ `runsheets.deliverer_id`; النظام الأم يعرض مناديب التوصيل من `delivery_agents` وخطط الرحلات من `delivery_route_plans`; البنية اللازمة موجودة؛ سبب عدم ظهور الإسناد هو عدم الربط بين نموذج الإسناد المباشر ونموذج اللوجستيات.
- **What I Did Not Prove:** تطابق HTML المنشور مع Git؛ سلوك المتصفح بعد إصلاح؛ نجاح E2E؛ سلامة أي migration جديد تحت التزامن.
- **What I Fixed:** لم أطبق إصلاحًا تشغيليًا في هذه الدورة؛ أصلحت الالتباس التشخيصي وحددت السبب ومسار الإصلاح.
- **What I Initially Missed:** أن النظام الأم يحتوي عقدًا مستقلاً لـ`delivery_agents` و`delivery_route_plans`، بينما صفحة المشرف تستخدم `users` و`runsheets.deliverer_id` فقط.
- **What Could Still Be Wrong:** قد توجد تعديلات أحدث في مصدر HTML المنشور أو بيانات إضافية خارج النطاق الذي قُرئ؛ يلزم فحص artifact المنشور واختبار عقد الإسناد بعد تطبيقه.
- **Final Confidence:** مرتفعة في السبب الجذري المثبت؛ منخفضة في جاهزية التشغيل بعد الإصلاح لأنه لم يُطبّق.
- **Final Closure Status:** `PARTIAL — ROOT CAUSE CONFIRMED, REPAIR AND E2E OPEN`.

## 11. أول إجراء تنفيذي للجلسة التالية

صمّم migration واحدًا قابلًا للتدقيق لتوحيد `delivery_supervisor_assign_deliverer_atomic` مع نموذج `delivery_agents` و`delivery_route_plans`، أو حدّد بوضوح تعديل Read Model الذي يجعل `runsheets.deliverer_id` مرجع عرض الإسناد. افحص تاريخ الميجريشنات والـACL والتريجرات أولًا، واختبر في Staging نشط قبل Production. لا تنشئ جدولًا جديدًا، ولا تغيّر `driver_id`، ولا تنشئ خطة كاملة دون متطلبات التخطيط، ولا تستخدم RS-1/RS-2 كـfixtures.
