# Report530 — تحقيق تكامل مشرف التوصيل، Service Worker، واختبار المتصفح

**وقت فحص Production:** 2026-10-28 16:24:19 UTC  
**النطاق:** `delivery/supervisor.html` → `runsheets.deliverer_id` → `delivery_logistics_query(view='agents')` → واجهة النظام الأم، مع تقييم مقترح Service Worker وGitHub Actions.  
**قيد التغيير:** لم يتم تعديل `main.html` أو `supervisor.html`، ولم تُعدّل قاعدة البيانات أو البيانات التشغيلية أو Service Worker أو Workflow في هذه الجولة. التغيير الوحيد المقصود هو التوثيق وتحديث سجل الاستمرارية.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** تعيين مندوب إلى رانشيت هو تكليف تشغيلي محفوظ في `runsheets.deliverer_id`، وليس إنشاء سجل إداري جديد في `delivery_agents`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يكتب عبر `delivery_supervisor_assign_deliverer_atomic`; النظام الأم يقرأ عبر `delivery_logistics_query` ويجب أن يعرض `runsheet_assignments` منفصلًا عن سجل المندوبين الإداري.
- **Database Understanding — CONFIRMED:** استدعاء Production للقراءة فقط أعاد تكليفين؛ سجل `delivery_agents` النشط فارغ.
- **Historical Understanding — CONFIRMED:** راجعت `CURRENT_STATE.md` وReport529 وReport528 وReport527، ثم قارنت مصدر الإصلاح السابق وتاريخ Git.
- **Production Understanding — CONFIRMED:** تعريف `delivery_logistics_query(uuid,text,jsonb,uuid,text)` الحالي هو `SECURITY DEFINER` مع `search_path=public`; EXECUTE مسموح لـ`authenticated` وغير مسموح لـ`anon`.
- **Current Source — CONFIRMED:** Parent blob `0c1745081e8d17480433ed527d77cac9f5292021`; Supervisor blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Execution Confidence:** مرتفع لعقد Production ووجود إصلاح المصدر في Git؛ غير كافٍ لتحديد سبب غياب الجدول من واجهة منشورة في جلسة مصادق عليها.

## 2. Fresh Production — قراءة فقط

قاعدة البيانات أعادت وقت الفحص `2026-10-28 16:24:19.149251+00`.

- الممثل المستخدم في استدعاء عقد القراءة: `owner@alrawae.com` ضمن الشركة المحددة.
- `delivery_logistics_query(..., 'agents', ...)`: `success=true`.
- `rows` (سجل `delivery_agents`): صفر.
- `runsheet_assignments`: صفان:
  - `RS-2` — «مندوب توصيل 3» — `Loaded`.
  - `RS-1` — «مندوب توصيل» — `Loaded`.
- `delivery_agent_code` فارغ في التكليفين، وهو متسق مع عدم وجود سجل مطابق في `delivery_agents`.

لم تُعدّل أي بيانات أو صلاحيات أو دوال في Production. هذا فحص عقد SQL مباشر للقراءة فقط، وليس HTTP E2E من جلسة متصفح مصادق عليها.

## 3. Current Git / Historical repair

- الإصلاح الوظيفي السابق: [`cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`](https://github.com/papamohammed77-glitch/erp-frontend/commit/cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc).
- التغيير في ذلك commit أضاف جدولًا مستقلًا لعرض `d.runsheet_assignments` داخل `RW_DeliveryLogistics.agents()`، مع إبقاء `d.rows` مخصصًا لسجل `delivery_agents`.
- المقارنة بين commit الإصلاح ولقطة commit النشر التاريخية `8843150bdde99d36d477d6bb344a24df61dd2942` تُظهر أن الثانية تتقدم على الإصلاح بخمسة commits. هذه قرينة تاريخية من تقرير سابق وليست إثباتًا أن هذا هو deployment الحالي الآن، ولا تثبت تطابق الـartifact المنشور بايتًا ببايت.
- المصدر الحالي لتطبيق المشرف يستدعي عقد الإسناد المركزي، ولا يوجد دليل حالي يبرر تغيير ذلك المسار أو إعادة كتابة الدالة.

**الاستنتاج:** لا تكرر إصلاح جدول التكليفات ولا تنشئ صفوفًا في `delivery_agents` لمجرد أن سجلها فارغ؛ ذلك سيخلط بين تكليف الرانشيت والسجل الإداري.

## 4. Published runtime — حدود الدليل

قراءة التبويب المتصل تُظهر صفحة النظام الأم وبداخلها نموذج دخول ظاهرًا، كما تظهر واجهة سجل مناديب اللوجستيات الفارغ، ولا يظهر جدول التكليفات. لكن بيانات التبويب تشير إلى أن آخر فتح كان `2026-10-28T15:28:04.980Z`، أي أن هذه لقطة متقادمة عن فحص Production الأخير، كما أنها ليست جلسة مصادقًا عليها مثبتة.

لذلك:

- **CONFIRMED:** لقطة DOM المتاحة لا تعرض جدول التكليفات.
- **UNVERIFIED:** هل تختفي اللوحة بعد تسجيل دخول طبيعي في تحميل حديث.
- **UNVERIFIED:** الـHTML والـService Worker اللذان خدمتهما Cloudflare في لحظة الاختبار.
- **UNVERIFIED:** استجابة Network الفعلية من متصفح مصادق عليه، وأول خطأ Console مرتبط بالرسم.
- **UNVERIFIED:** السبب الجذري النهائي: صفحة/DOM قديم، artifact منشور مختلف، أو مشكلة في مسار الرسم.

## 5. تقييم اقتراح تغيير Service Worker

المصدر الحالي `companies/company-1/sw.js`، blob `6123fce8b99391d70e6937bde5c4fcbd3f2d8f48`، يعلن:

- `SW_BUILD = RAWAEA_SW_P156_HR_REPUBLISH_20260918`.
- طلبات HTML/navigation تمر عبر `fetch(request)` ثم معالجة HTML؛ لا تُقرأ من Cache Storage.
- ملفات JavaScript/runtime وطلبات Supabase تمر مباشرة إلى الشبكة.
- عند تفعيل Service Worker جديد، يستدعي `skipWaiting` و`clients.claim`، ويحذف caches القديمة، ثم يعيد تحميل عملاء النطاق.

**الحكم:** تغيير `SW_BUILD` وحده ليس إصلاحًا مثبتًا لسبب المشكلة. قد يفرض تحديث الـService Worker وإعادة تحميل التبويبات بعد نشره، لكنه لا يستطيع إصلاح artifact قديم على Cloudflare إذا كان الخادم نفسه يعيد ملفًا قديمًا. وبما أن المصدر الحالي لا يخزّن HTML/JS في Cache Storage، فلا يوجد دليل كافٍ لإعلان أن Cache هو السبب.

لا أوصي بتغيير إصدار الـService Worker كحل جذري قبل مقارنة ملف `sw.js` المنشور فعليًا بالمصدر الحالي. إذا ثبت أن العامل المنشور قديم أو أن المتصفح لا يحدّثه، يصبح تغيير الإصدار مع نشره واختبار تفعيله إجراءً مبررًا، مع توثيق أنه آلية تحديث لا إصلاح لعقد البيانات.

## 6. تقييم GitHub Actions

الملف الحالي:
[`.github/workflows/browser_e2e_mother_20260915.yml`](https://github.com/papamohammed77-glitch/erp-frontend/blob/main/.github/workflows/browser_e2e_mother_20260915.yml)  
Blob SHA: `7f821b2afdcb8d15f205782218b427d06da03a6e`.

الاختبار الحالي هو **anonymous smoke test**: يتحقق من تحميل الصفحة، وجود حقل كلمة المرور وزر ظاهر، وبعض علامات المصدر والأخطاء العامة. لا يثبت أن جدول `runsheet_assignments` يُعرض بعد المصادقة، ولا يختبر عقد إسناد مندوب التوصيل نفسه.

يوجد شرط تشغيل لخادم المصدر المحلي:
```yaml
if: ${{ inputs.published_url == '' }}
```

من دون سجل تشغيل/خطأ خطوة فعلي لا يمكن إثبات أن هذا الشرط هو سبب فشل تشغيل المتصفح؛ كما أن السياق الحالي لا يوفر سجلًا يحدد الفشل الأخير. لذلك لم أعدّل الـWorkflow على أساس التخمين. إن ثبت من سجل الفشل أن الشرط يمنع تشغيل الخادم في حدث `push`، فالتعديل الجراحي المرشح هو:

```yaml
if: ${{ github.event_name != 'workflow_dispatch' || inputs.published_url == '' }}
```

هذا يجعل السلوك صريحًا: في `push` يبدأ الخادم المحلي، وفي `workflow_dispatch` يبدأ فقط عندما لا يمرر المستخدم عنوان نشر. لكنه يظل تغييرًا مقترحًا إلى أن يطابق سجل الفشل السبب.

**فجوة الاختبار الأهم:** يجب أن يكون هناك اختبار منفصل يثبت ظهور جدول التكليفات بعد مصادقة صحيحة، ووجود `RS-1` و`RS-2` في الاستجابة والرسم. لا ينبغي تحويل smoke test مجهول الهوية إلى ادعاء E2E مصادق عليه.

## 7. القرار الجراحي

1. عدم لمس `main.html` أو `supervisor.html`؛ الإصلاح السابق موجود بالفعل في المصدر الحالي.
2. عدم تعديل SQL أو البيانات أو ACL؛ عقد Production يعيد التكليفات بالفعل.
3. عدم تغيير `SW_BUILD` قبل إثبات محتوى العامل المنشور وسلوك تحديثه.
4. عدم تعديل Workflow قبل ربط الفشل الفعلي بالخطوة المحددة؛ شرط التشغيل أعلاه هو مرشح مشروط، لا Root Cause مثبت.
5. لا يُنشأ أي fixture أو مندوب أو رانشيت إضافي؛ البيانات الحقيقية الحالية تكفي لإثبات عقد SQL.
6. خطوة الإغلاق الوحيدة المتبقية هي اختبار الصفحة المنشورة بعد تسجيل دخول طبيعي: فحص استجابة `delivery_logistics_query` للعرض `agents`، ثم DOM/Console. لا تُرسل كلمة مرور أو رمز جلسة.

## 8. Mutation ledger

- Parent `main.html`: **UNCHANGED**.
- Supervisor `supervisor.html`: **UNCHANGED**.
- `sw.js` و`register-sw.js`: **UNCHANGED**.
- GitHub Actions workflow: **UNCHANGED**.
- Production schema/data/RPC/ACL/RLS: **UNCHANGED**.
- Inventory/accounting/runsheets: **UNCHANGED**.
- تم تحديث هذا التقرير وسجل الاستمرارية فقط.

## 9. SELF-AUDIT FINAL

- **What I Proved:** Production يعيد تكليفَي RS-1/RS-2؛ صلاحية RPC صحيحة وفق الفحص؛ الإصلاح المصدري السابق يضيف جدولًا مستقلًا؛ المصدر الحالي للـService Worker يجعل HTML وJS طلبات شبكية؛ اختبار Actions الحالي smoke test لا يثبت عرض التكليفات المصادق عليه.
- **What I Did Not Prove:** نجاح عرض الجدول بعد تسجيل الدخول، الـartifact الفعلي الذي خدمته Cloudflare في لحظة حديثة، أن Service Worker هو السبب، أو أن شرط Workflow تسبب في الفشل الأخير.
- **What I Fixed:** لا إصلاح تشغيلي جديد؛ وثّقت الحقيقة الحالية وحدود الإثبات بدل تكرار إصلاح صحيح أو إضافة workaround غير مثبت.
- **What I Initially Missed:** يجب التفريق بين لقطة DOM متقادمة وبين تحقق runtime حي؛ وكذلك بين نجاح RPC وبين نجاح العرض.
- **What Could Still Be Wrong:** stale DOM/served artifact أو خطأ JavaScript في العرض بعد المصادقة.
- **Final Confidence:** مرتفع لعقد البيانات والمصدر؛ غير كافٍ لتحديد سبب خلل العرض المنشور.
- **Final Closure Status:** `SOURCE + PRODUCTION RPC/DATA VERIFIED / AUTHENTICATED PUBLISHED UI E2E OPEN / NOT CLOSED`.
