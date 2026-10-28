# Report537 — إعادة مزامنة Production ومسار ظهور تكليفات الرانشيت في النظام الأم

**وقت الفحص:** 2026-10-28T20:32:58.176304Z (UTC) — Production SQL/RPC مباشر، مع إعادة فحص جلسة المتصفح المتاحة.  
**النطاق:** تطبيق مشرف التوصيل → `runsheets.deliverer_id` → `public.delivery_logistics_query(..., 'agents', ...)` → `RW_DeliveryLogistics.agents()` → واجهة Cloudflare المنشورة.  
**سياسة التغيير:** قراءة فقط. لا تعديل على ملفات HTML أو قاعدة البيانات أو RPC/ACL/RLS أو البيانات التشغيلية أو النشر.

## 1. PRE-CHANGE SELF-AUDIT

| المجال | الحالة | دليل مباشر |
|---|---|---|
| Business Understanding | CONFIRMED | التكليف الفعلي محفوظ في `runsheets.deliverer_id`، وليس في سجل `delivery_agents` الإداري. |
| Architecture / Consumer | CONFIRMED | إصلاح المصدر موجود في commit [cb62612](https://github.com/papamohammed77-glitch/erp-frontend/commit/cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc)، ويضيف بطاقة مستقلة مبنية على `d.runsheet_assignments`. |
| Current source identity | CONFIRMED | `companies/company-1/main.html`، blob `0c1745081e8d17480433ed527d77cac9f5292021`. |
| Production actor | CONFIRMED | `owner@alrawae.com` نشط، الشركة `00000000-0000-0000-0000-000000000001`، والصلاحيات `["*"]`. استُخدمت الهوية للقراءة فقط. |
| Production data | CONFIRMED | RS-1 وRS-2 بحالة `Loaded` ولكل منهما `deliverer_id` صالح مرتبط بمستخدم. |
| Production RPC | CONFIRMED | الاستدعاء الحي أعاد `success=true` و`runsheet_assignments` فيها RS-2 وRS-1. `rows=[]` تخص سجل `delivery_agents` الفارغ فقط. |
| RPC security | CONFIRMED | `SECURITY DEFINER` مع `search_path=public`؛ EXECUTE ظاهر لـ`authenticated` و`service_role` ومالك قاعدة البيانات، ولا يظهر grant لـ`anon`. |
| Published artifact identity | UNVERIFIED | لا تتوفر أداة Cloudflare/HTTP هنا لإثبات SHA أو هوية HTML المنشورة. |
| Authenticated UI E2E | UNVERIFIED | لقطة التبويب المنشور المتاحة تعرض نموذج الدخول، وليست جلسة مصادقًا عليها وحديثة في صفحة «مناديب التوصيل». لا تتوفر Network response body أو DOM للعرض المستهدف أو Console حديث. |
| Active root cause | UNVERIFIED | لا يمكن التمييز بالأدلة المتاحة بين artifact قديم/غير متزامن، أو عدم فتح العرض المستهدف، أو خطأ JavaScript أثناء العرض. |

**Execution confidence:** مرتفع لعقد Production والبيانات ومصدر Git؛ غير كافٍ لإثبات ظهور البطاقة في الواجهة المنشورة.

## 2. Fresh Production evidence

عند `2026-10-28 20:32:58.176304+00`:

- `owner@alrawae.com` نشط في الشركة المتوقعة، وصلاحياته `["*"]`.
- RS-1: `Loaded`، مسند إلى `driver@rawaea.com`.
- RS-2: `Loaded`، مسند إلى `driver3@rawaea.com`.
- عدد سجلات `delivery_agents` للشركة = 0.
- الاستدعاء الفعلي لـ`delivery_logistics_query(company_id,'agents','{}',owner.id,owner.email)` أعاد `success=true` وصفّي التكليفين داخل `runsheet_assignments`.

**النتيجة:** لا يوجد دليل يبرر إنشاء سجلات `delivery_agents` اصطناعية؛ فهذا سجل منفصل ولا يمثل مصدر الحقيقة للتكليفات.

## 3. Historical / Current consumer review

الإصلاح التاريخي في commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` غيّر `RW_DeliveryLogistics.agents()` بحيث:

1. يقرأ `d.runsheet_assignments` منفصلًا عن `d.rows`.
2. يبني `assignmentRows` و`assignmentTable`.
3. يمرر بطاقة «تعيينات الرانشيت من مشرف التوصيل» إلى `set(shell(...))) بصورة مستقلة عن جدول سجل المندوبين.

إذًا، العيب التاريخي المعروف — عرض سجل `delivery_agents` فقط رغم أن التكليف محفوظ على `runsheets.deliverer_id` — تمت معالجته في مصدر Git. **هذا لا يثبت أن Cloudflare يخدم ذلك المصدر الآن.**

## 4. Logs / failed exploratory queries

ظهرت في سجل PostgreSQL أخطاء استعلامات استكشافية للقراءة فقط بسبب استعمال أسماء غير موجودة في المخطط (`runsheet_number` ثم `users.full_name`). تم تصحيح الاستعلام إلى `runsheet_code` وربط المستخدم عبر `users.email`. لم تنفذ أي كتابة أو تغيير بيانات نتيجة لهذه الاستعلامات.

## 5. Surgical repair decision

**لا يوجد تعديل إضافي آمن ومثبت في المصدر أو قاعدة البيانات يمكن تطبيقه الآن.** تكرار تعديل `main.html` سيكون غير مبرر؛ الإصلاح موجود بالفعل في المصدر الحالي. كما أن إنشاء سجلات مناديب، أو تغيير RPC/ACL، أو تغيير Service Worker، أو إعادة النشر دون إثبات هوية الـartifact قد يخفي المشكلة بدل تحديدها.

لا يوجد Owner Changeset جديد في هذه الدورة لأن العيب الحالي لم يُحصر بعد في عنصر مصدر بعينه. لا يُعد هذا إغلاقًا للمهمة.

## 6. الإجراء الدقيق المتبقي لإثبات السبب والإغلاق

من جلسة دخول طبيعية ومصادق عليها في `https://rawaea-erp.pages.dev/companies/company-1/main`:

1. افتح **مركز التوصيل واللوجستيات → مناديب التوصيل**.
2. من Network، التقط الطلب والاستجابة المنقحة لـ`delivery_logistics_query` مع view `agents`، من دون cookies أو JWT أو Authorization headers.
3. تحقق من وجود RS-1 وRS-2 في `runsheet_assignments`.
4. تحقق هل DOM يحتوي بطاقة «تعيينات الرانشيت من مشرف التوصيل» والصفين.
5. إذا كانت الاستجابة تحتوي الصفين والبطاقة غير موجودة، التقط أول خطأ Console مع عنوان/هوية الملف الذي يخدمه Cloudflare.
6. قارن artifact المنشور مع blob `0c1745081e8d17480433ed527d77cac9f5292021`. بعد ذلك فقط يمكن تحديد هل الإصلاح هو تصحيح مصدر إضافي أو نشر/مزامنة artifact أو إصلاح runtime محدد.

اللقطة المتاحة عبر أداة المتصفح للقراءة فقط لا تسمح بتسجيل الدخول أو فتح العرض أو قراءة Network/Console؛ لذلك لم أزعم أن هذه الخطوات نُفذت.

## 7. Mutation ledger

- Parent `main.html`: **لم يتغير**.
- تطبيق `supervisor.html`: **لم يتغير**.
- Production schema/data/RPC/ACL/RLS: **لم تتغير**.
- Runsheets / inventory / accounting: **لم تتغير**.
- Cloudflare / Service Worker: **لم يتغيرا**.
- Test fixtures: **لم تُنشأ**.
- Documentation: هذا التقرير وسجل `CURRENT_STATE.md) فقط.

## 8. SELF-AUDIT FINAL

- **What I Proved:** Production يحتوي التكليفين؛ RPC الفعلية تعيدهما؛ مصدر Parent الحالي يتضمن بطاقة منفصلة؛ هوية المالك وصلاحياته تسمح بالقراءة في اختبار RPC؛ لا يوجد سبب لإنشاء master-agent rows.
- **What I Did Not Prove:** هوية artifact المنشور، HTTP E2E مصادق عليه من المتصفح، DOM النهائي، أو خطأ Console.
- **What I Fixed:** لا تعديل تشغيلي جديد؛ الإصلاح المعروف موجود بالفعل في Git. لم أكرر تعديلًا غير مثبت.
- **What I Initially Missed:** استعلامان استكشافيان استخدما أسماء أعمدة غير موجودة؛ رُفضا دون أثر على البيانات ثم صُححا.
- **What Could Still Be Wrong:** قد يكون artifact المنشور غير متزامن مع Git، أو توجد مشكلة runtime/client-side، أو أن العرض المستهدف لم يُفتح في جلسة مصادق عليها؛ كلها احتمالات وليست حقائق مثبتة.
- **Final Confidence:** مرتفع في Production RPC/data + Current Git consumer؛ غير كافٍ لنجاح الواجهة المنشورة.
- **Final Closure Status:** `PRODUCTION DATA/RPC + SOURCE CONSUMER VERIFIED / PUBLISHED AUTHENTICATED UI E2E OPEN / NOT CLOSED`.
- **Next exact checkpoint:** تنفيذ خطوات القسم 6 من جلسة مصادق عليها، ثم اتخاذ الإصلاح بناءً على استجابة Network وDOM وConsole وهوية artifact، وليس بالتخمين.
