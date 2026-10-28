# Report530 — إعادة التحقيق في تكامل مشرف التوصيل والنظام الأم — 2026-10-28

**وقت التحقق:** 2026-10-28، تقريبًا 16:43 UTC  
**النطاق:** `supervisor.html` → `runsheets.deliverer_id` → Production RPC → `main.html` → Cloudflare Pages  
**الحالة:** `PRODUCTION ASSIGNMENTS CONFIRMED / RPC CONTRACT CONFIRMED / SOURCE PATCH PRESENT / LIVE TAB RELOAD REQUIRED TO VERIFY / NOT CLOSED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** تكليف مندوب التوصيل هو ارتباط تشغيلي بين مستخدم مؤهل ورانشيت؛ لا يعني تلقائيًا إنشاء سجل مستقل في `delivery_agents`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يقرأ من `delivery_supervisor_assignment_query` ويكتب عبر `delivery_supervisor_assign_deliverer_atomic`. مركز النظام الأم يقرأ عبر `delivery_logistics_query`، وعقد `agents` يعيد `rows` و`runsheet_assignments` كحقلين مستقلين.
- **Database Understanding — CONFIRMED:** Production يحتوي حاليًا تكليفَي RS-1 وRS-2 في الشركة `00000000-0000-0000-0000-000000000001`، وكلاهما `Loaded` وله `deliverer_id`.
- **Historical Understanding — CONFIRMED:** تمت مراجعة `CURRENT_STATE.md` وسلسلة تقارير Report508–Report529 ذات الصلة، بما فيها Report529، ولم يُكرر إصلاح `main.html` الموجود بالفعل في Git.
- **Production Understanding — CONFIRMED:** تعريف Production لـ`delivery_logistics_query` يتضمن `runsheet_assignments`; دالتا المشرف موجودتان بصلاحيات تنفيذ لـ`authenticated`، وطلبات HTTP المرصودة للدالتين عادت 200.
- **Current Source — CONFIRMED:** `main.html` blob SHA `0c1745081e8d17480433ed527d77cac9f5292021`. ملف المشرف blob SHA `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Execution Confidence:** مرتفع في سلامة البيانات وعقد RPC ومصدر Git؛ متوسط فقط في حالة DOM المنشور لأن التبويب المتاح لم يُحدَّث ولم تُنفّذ فيه عملية تسجيل دخول/تحديث تفاعلية.

## 2. الأدلة الحية

وقت SQL المرصود: `2026-10-28 16:42:55+00`.

| الرانشيت | الحالة | المندوب | النتيجة |
|---|---|---|---|
| RS-2 | Loaded | مندوب توصيل 3 / `driver3@rawaea.com` | موجود في `runsheets.deliverer_id` |
| RS-1 | Loaded | مندوب توصيل / `driver@rawaea.com` | موجود في `runsheets.deliverer_id` |

- استعلام join مباشر على `runsheets` و`users` أعاد RS-1 وRS-2.
- طلبات Production المرصودة من `https://rawaea-erp.pages.dev/`:
  - `delivery_logistics_query`: HTTP 200 عند `2026-10-28T16:25:58Z`.
  - `delivery_supervisor_assignment_query`: HTTP 200 عند `2026-10-28T16:24:48Z`.
- تعريف `delivery_logistics_query` الحالي يضع تكليفات الرانشيت في `runsheet_assignments`، ولا يضعها داخل `rows`.
- عدد سجلات `delivery_agents` النشطة صفر، ولذلك ظهور رسالة «لا يوجد مناديب مسجلون» في الجدول الإداري وحده لا يثبت فقد التكليفات.
- المندوبان المسندان لا يرتبطان حاليًا بسجل `delivery_agents`؛ `delivery_agent_code` يرجع NULL. هذا انفصال بين هوية المستخدم التشغيلية وسجل مندوب اللوجستيات، وليس دليلًا على فشل إسناد الرانشيت.

## 3. التحقق من مصدر Git والنشر

- Commit المصدر الذي أضاف جدول التكليفات في النظام الأم:
  [`cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`](https://github.com/papamohammed77-glitch/erp-frontend/commit/cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc)
- هذا التعديل يضيف عرضًا مستقلًا لـ`runsheet_assignments` ويُبقي جدول `delivery_agents` منفصلًا.
- لقطة لوحة Cloudflare تعرض نشرًا للـProduction على commit `8843150bdde99d36d477d6bb344a24df61dd2942`. مقارنة Git أثبتت أن هذا commit متقدم بخمسة commits على `cb62612` وليس متأخرًا عنه؛ إذن شجرة المصدر لذلك النشر تتضمن commit الإصلاح.
- رابط نشر commit الإصلاح:
  [https://7462107e.rawaea-erp.pages.dev/](https://7462107e.rawaea-erp.pages.dev/)
- لقطة التبويب المفتوح حاليًا للنظام الأم ما زالت تعرض طبقة تسجيل الدخول فوق DOM قديم لا يحتوي عنوان «تعيينات الرانشيت من مشرف التوصيل». لم يُجرَ refresh أو login تفاعلي في هذا الفحص؛ لذلك لا يجوز الجزم أن HTML الذي يقدمه Cloudflare حاليًا قديم. الاحتمال الأقوى هو أن التبويب المفتوح يحتفظ بواجهة مرسومة قبل نشر/تحميل التعديل، لكن هذا **استنتاج يحتاج اختبارًا** وليس حقيقة مغلقة.
- لم يتم إثبات byte-for-byte identity بين HTML المخدوم وGit، ولم يتم تنفيذ authenticated browser E2E.

## 4. التشخيص

### ما ثبت

1. الإسناد محفوظ في Production.
2. عقد القراءة المركزي يعيد حقل `runsheet_assignments`.
3. مصدر `main.html` في Git يحتوي بالفعل على جدول «تعيينات الرانشيت من مشرف التوصيل».
4. أحدث commit ظاهر في لوحة Cloudflare متقدم على commit إصلاح الجدول؛ لا توجد قرينة أن شجرة النشر أقدم من الإصلاح.
5. الطلبات الأخيرة للدالتين نجحت HTTP 200.

### ما لم يثبت

- هل التبويب المفتوح حمّل HTML الحالي بعد commit الإصلاح.
- هل الجدول يظهر بعد تسجيل الدخول وتحديث الصفحة.
- هل استجابة RPC في نفس جلسة الواجهة تحتوي RS-1 وRS-2.
- هل توجد حاجة لاحقة لربط سجلات `delivery_agents` بحسابات المستخدمين. هذا تحسين تكاملي منفصل ولا ينبغي فرضه باعتباره شرطًا لعرض التكليف الفعلي.

### Root Cause الحالي

**لم يثبت عيب جديد في Production RPC أو بيانات الإسناد.** العيب المؤكد سابقًا كان غياب عرض `runsheet_assignments` في نسخة مصدر قديمة؛ وقد أُضيف العرض في commit `cb62612`. ما تبقى هو إثبات أن التبويب المفتوح يعرض النسخة الحالية. لا مبرر لتعديل SQL أو إعادة كتابة `main.html` بالتخمين قبل هذا التحقق.

## 5. الإجراء التنفيذي المحدد التالي

لأن أداة المتصفح المتاحة في هذه الجلسة قراءة فقط ولا تتيح refresh/click/login، فإن الخطوة الوحيدة التي تتطلب تفاعلًا محليًا هي:

1. في تبويب النظام الأم المفتوح، نفّذ تحديثًا قسريًا للصفحة (`Ctrl+Shift+R`).
2. سجّل الدخول بالطريقة المعتادة.
3. افتح «مركز التوصيل واللوجستيات → مناديب التوصيل».
4. تحقق من ظهور جدول «تعيينات الرانشيت من مشرف التوصيل» وفيه RS-1 وRS-2.
5. إذا لم يظهر، أرسل فقط استجابة Network لطلب `delivery_logistics_query` بعرض `agents`، مع إخفاء Authorization/cookies/أي أسرار. لا ترسل كلمة مرور أو رمز جلسة.

**قرار المسار بعد الاختبار:**
- إذا ظهرت RS-1 وRS-2 بعد التحديث: السبب كان تبويبًا قديمًا؛ تُغلق مشكلة العرض بعد توثيق الصورة/DOM.
- إذا أعادت RPC التكليفين والجدول غائب: يُصلح مسار render/DOM في `main.html` جراحيًا.
- إذا لم تتضمن الاستجابة التكليفين: تُراجع معاملات الطلب ونسخة RPC المخدومة، ثم يُصلح السبب في SQL بعد إثباته.
- لا تُنشأ بيانات اختبار ولا تُلمس RS-1/RS-2؛ فهما بيانات موجودة ويجب الحفاظ عليهما.

## 6. سجل التغييرات

- لا تعديل على `main.html` أو `supervisor.html`.
- لا تعديل على Production SQL/RPC/ACL/RLS أو بيانات الأعمال.
- لا Edge Function جديدة.
- لم تُنشأ fixtures ولم تُغيّر أرصدة المخزون أو الحجوزات أو القيود المحاسبية.
- أُضيف هذا التقرير لتوثيق الأدلة الجديدة ومنع إعادة إصلاح المصدر الموجود بالفعل.

## 7. SELF-AUDIT FINAL

- **What I Proved:** تكليفان حقيقيان في Production؛ نجاح HTTP للدالتين؛ وجود حقل التكليف في تعريف RPC؛ وجود إصلاح واجهة التكليفات في Git؛ سلسلة commits المنشورة تتضمن commit الإصلاح.
- **What I Did Not Prove:** ظهور الجدول بعد تحديث/تسجيل دخول؛ مطابقة HTML المخدوم بايتًا ببايت؛ نجاح authenticated UI E2E.
- **What I Fixed:** لا إصلاح تشغيلي جديد؛ إصلاح المصدر موجود بالفعل ولم أكرر تغييره.
- **What I Initially Missed:** `delivery_agents` سجل إداري منفصل عن `public.users` وهوية المندوب المسند؛ فراغ الأول لا يعني أن التكليف غير موجود.
- **What Could Still Be Wrong:** التبويب قديم في الذاكرة؛ أو خطأ render/استجابة مختلفة في جلسة فعلية بعد refresh.
- **Final Confidence:** مرتفع لقاعدة البيانات وRPC وGit؛ متوسط لواقع DOM حتى إعادة الاختبار.
- **Final Closure Status:** `NOT CLOSED — FINAL AUTHENTICATED UI CHECK REQUIRED`.
