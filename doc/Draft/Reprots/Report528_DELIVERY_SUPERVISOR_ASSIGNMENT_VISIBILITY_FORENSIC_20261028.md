# Report528 — التحقيق الجنائي لتكامل مندوب التوصيل بين المشرف والنظام الأم

**تاريخ الفحص:** 2026-10-28  
**نطاق المهمة:** `delivery/supervisor.html` → `runsheets.deliverer_id` → `delivery_logistics_query(view='agents')` → جدول النظام الأم «مناديب التوصيل».  
**الحالة:** `PRODUCTION DATA/RPC VERIFIED / SOURCE PATCH PRESENT / AUTHENTICATED PUBLISHED UI E2E NOT VERIFIED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** تعيين مندوب إلى رانشيت هو تكليف تشغيلي على `runsheets.deliverer_id`. وهو ليس إنشاء سجل إداري/تعاقدي جديد في `delivery_agents`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يستدعي `delivery_supervisor_assign_deliverer_atomic`. النظام الأم يستدعي `delivery_logistics_query`. الـRPC يعيد `rows` لسجل مناديب اللوجستيات و`runsheet_assignments` مستقلة لتكليفات الرانشيت.
- **Database Understanding — CONFIRMED:** فحص Production للقراءة فقط في `2026-10-28 13:28:02.621062+00` أثبت وجود تكليفين، ووجود صفر من سجلات `delivery_agents` النشطة.
- **Historical Understanding — CONFIRMED:** تمت مراجعة LVE-524 إلى LVE-527 وتقارير 524–527، وتحديد الإصلاح السابق في commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`. لم يُكرر الإصلاح الموجود.
- **Production Understanding — CONFIRMED:** تعريف Production الحالي لـ`delivery_logistics_query(uuid,text,jsonb,uuid,text)` يحتوي `runsheet_assignments`; ACL يسمح بـEXECUTE لـ`authenticated` و`service_role` ولا يمنحه لـ`anon`.
- **Current Understanding — CONFIRMED:** Parent source blob `0c1745081e8d17480433ed527d77cac9f5292021`; Supervisor source blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Deployment Understanding — CONFIRMED:** صفحة Cloudflare المفتوحة تعرض Production deployment على commit `8843150bdde99d36d477d6bb344a24df61dd2942`. مقارنة Git تثبت أن هذا commit يقع بعد commit الإصلاح `cb62612...` بخمسة commits، أي إن سجل النشر المعروض يتضمن تاريخيًا commit الإصلاح. هذا لا يثبت وحده تطابق ملفات Pages المنشورة بايتًا ببايت.
- **Execution Confidence:** مرتفع لعقد المصدر وبيانات/RPC Production؛ غير كافٍ لإثبات العرض البصري في جلسة مصادق عليها.

## 2. الأدلة الحالية

### 2.1 Production SQL — قراءة فقط

الاستعلام المباشر لـ`delivery_logistics_query(..., 'agents', '{}', owner.id, owner.email)` أعاد:

- `master_agent_rows = []`
- `active_delivery_agents = 0`
- `runsheet_assignments`: صفان:
  - `RS-2` — «مندوب توصيل 3» — الحالة `Loaded` — `deliverer_user_id=5fc15ecf-450c-4499-8edb-eb5bd4fbf963`
  - `RS-1` — «مندوب توصيل» — الحالة `Loaded` — `deliverer_user_id=0912a68e-a2d6-4e3a-b44d-41f8826fb900`
- `delivery_agent_code` فارغ لكلا التكليفين، وهو متوقع ما دامت لا توجد سجلات مطابقة في سجل `delivery_agents`.

### 2.2 مصدر تطبيق المشرف

`companies/company-1/delivery/supervisor.html` يستدعي `delivery_supervisor_assign_deliverer_atomic` مع `p_company_id`, `p_runsheet_code`, `p_deliverer_user_id`, و`p_operation_id`. الدالة المركزية تحفظ `runsheets.deliverer_id` ولا تنشئ صفًا في `delivery_agents`، كما تحافظ على `driver_id` و`vehicle_id`.

### 2.3 النظام الأم

مصدر `companies/company-1/main.html` يحتوي إصلاحًا سابقًا يضيف جدولًا مستقلًا لتكليفات الرانشيت من مشرف التوصيل، ويحتفظ بسجل `delivery_agents` الإداري منفصلًا. الـmigration المرجعي:
`supabase/migrations/20261027_delivery_supervisor_parent_runsheet_assignments.sql`.

### 2.4 Runtime

لقطة المتصفح المتصلة لصفحة الإنتاج `https://rawaea-erp.pages.dev/companies/company-1/main` تعرض نموذج الدخول مع البريد `owner@alrawae.com` وكلمة مرور فارغة، كما تعرض جدول سجل مناديب اللوجستيات الفارغ، ولا تعرض جدول التكليفات. لذلك هذه اللقطة **ليست جلسة مصادقًا عليها** ولا تثبت أن جدول التكليفات يفشل بعد تسجيل الدخول. سجلات Supabase السابقة أظهرت HTTP 200 لاستدعاءات RPC، لكنها لا تحتوي جسم الاستجابة ولا تثبت اكتمال الرسم في الواجهة.

## 3. السبب الجذري والحكم

- **CONFIRMED:** تكليفات المشرف محفوظة في Production وتُعاد من الـRPC تحت `runsheet_assignments`.
- **CONFIRMED:** سجل `delivery_agents` الإداري منفصل؛ لا توجد سجلات نشطة حاليًا، ولذلك فإن جدول السجل الرئيسي وحده سيعرض حالة فارغة. لا يجوز إنشاء صفوف `delivery_agents` تلقائيًا لمجرد تعيين مندوب لرانشيت، لأن ذلك يخلط بين التكليف التشغيلي والسجل الإداري/التعاقدي.
- **CONFIRMED:** الإصلاح المصدري الذي يضيف جدول التكليفات موجود في Git. commit `8843150...` المعروض في Cloudflare يقع بعد commit الإصلاح في تاريخ Git.
- **UNVERIFIED:** هل يختفي جدول التكليفات بعد تسجيل الدخول فعليًا؟ لقطة المتصفح الحالية غير مصادق عليها، فلا يمكن استنتاج خطأ نشر أو خطأ رسم من هذه اللقطة.
- **ROOT CAUSE STATUS:** أصل مشكلة فصل مصدر البيانات كان معروفًا وعولج في المصدر والـRPC. العرض المتبقي لا يمكن تصنيفه كخلل في الـRPC أو النشر أو JavaScript قبل اختبار صفحة الإنتاج في جلسة مصادق عليها.

## 4. الإصلاحات والتغييرات

- لم يتم تعديل `main.html` أو `supervisor.html`، احترامًا لحدود المهمة.
- لم تُعدّل قاعدة البيانات أو البيانات التشغيلية أو الـRPC أو ACL/RLS.
- لم تُنشأ بيانات اختبار ولم يُغيّر أي رانشيت.
- لم يُجرَ نشر جديد؛ أدوات الجلسة لا توفر إجراء Cloudflare deploy مباشرًا، كما لم يثبت وجود خلل جديد يستدعي تغييرًا تشغيليًا.
- لا يوجد نص استبدال جراحي جديد مبرر بالأدلة الحالية؛ التعديل المعروف موجود بالفعل، وتكراره قد ينتج ازدواجية.

## 5. خطوة الإغلاق المطلوبة بدقة

في جلسة متصفح الإنتاج، سجّل الدخول بالطريقة الاعتيادية ثم افتح **إدارة التوصيل والشحن → مناديب التوصيل**:

1. تحقق من ظهور القسم/الجدول المستقل «تعيينات الرانشيت من مشرف التوصيل».
2. في Network، افتح استجابة `delivery_logistics_query` للعرض `agents` وتأكد من وجود `runsheet_assignments` وبداخله `RS-1` و`RS-2`.
3. إذا كانت الاستجابة تحتوي الصفين والجدول غير ظاهر: التقط أول خطأ Console، ثم يُعزل خطأ الرسم في `RW_DeliveryLogistics.agents()`; لا تغيّر SQL.
4. إذا كانت الاستجابة لا تحتوي الصفين: احتفظ بالطلب والاستجابة الفعليين، وافحص RPC/المعاملات التي استدعاها العميل قبل أي تعديل.
5. إذا لم يتضمن DOM المصادق عليه القسم، افحص الـHTML الذي خدمته Pages وقارنه بمصدر `main.html` الحالي قبل اتخاذ قرار إعادة النشر.

لا حاجة إلى تعديل أي سجل تجاري أو إنشاء مندوب إداري لأجل الاختبار. بعد التحقق، أعد تحميل الصفحة وتأكد من بقاء الصفين ومن عدم تغيير السائق أو المركبة.

## 6. SELF-AUDIT FINAL

- **What I Proved:** Production يحفظ تكليفَي RS-1 وRS-2؛ الـRPC يعيدهما في `runsheet_assignments`; مصدر المشرف يكتب إلى العقد الصحيح؛ المصدر الحالي يتضمن جدول التكليفات المنفصل؛ ACL يمنع `anon` ويسمح للمستخدم المصادق.
- **What I Did Not Prove:** العرض البصري في جلسة Parent مصادق عليها، جسم استجابة HTTP حية من المتصفح المصادق، أو تطابق artifact المنشور بايتًا ببايت مع Git.
- **What I Fixed:** لم أضف إصلاحًا تشغيليًا مكررًا؛ أضفت هذا التقرير التوثيقي فقط.
- **What I Initially Missed:** الجدول الإداري `delivery_agents` وتكليف الرانشيت `runsheets.deliverer_id` كيانان منفصلان؛ فراغ الأول لا يعني ضياع التكليف الثاني.
- **What Could Still Be Wrong:** قد يوجد خطأ في رسم واجهة التكليفات داخل جلسة مصادق عليها، لكن الدليل المتاح حاليًا لا يثبته.
- **Final Confidence:** مرتفع في صحة عقد Production والمصدر؛ غير مكتمل في تحقق واجهة الإنتاج.
- **Final Closure Status:** `SOURCE + PRODUCTION DATA/RPC VERIFIED / AUTHENTICATED PUBLISHED UI E2E OPEN`.
