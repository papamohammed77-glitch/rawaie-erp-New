# Report533 — تكامل مشرف التوصيل مع النظام الأم: إعادة مطابقة Production وسجل التشغيل

**وقت الفحص الحي:** 2026-10-28 16:57:17 UTC  
**النطاق الوحيد:** `supervisor.html` → تعيين المندوب في `runsheets.deliverer_id` → Production RPC `delivery_logistics_query(view='agents')` → واجهة النظام الأم المنشورة.  
**سياسة التغيير:** لا تعديل تشغيلي في هذه الدورة؛ الأدلة لا تعزل حتى الآن عيبًا جديدًا في المصدر أو قاعدة البيانات، ولا تتوفر أداة نشر Cloudflare/تفاعل المتصفح في وضع القراءة الحالي.

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** التكليف الفعلي للرحلة مخزّن في `runsheets.deliverer_id`. وهو مختلف عن سجل المندوب الإداري/التعاقدي في `delivery_agents`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يقرأ من `delivery_supervisor_assignment_query` ويُسند عبر `delivery_supervisor_assign_deliverer_atomic`. النظام الأم يقرأ من `delivery_logistics_query`. يجب عرض `runsheet_assignments` مستقلة عن `rows` الخاصة بسجل المندوبين.
- **Database Understanding — CONFIRMED:** Production يحتوي حاليًا على RS-1 وRS-2 بحالة Loaded ومندوب مسند لكل منهما؛ لا توجد سجلات `delivery_agents` للشركة الحالية.
- **Historical Understanding — CONFIRMED:** راجعت `CURRENT_STATE.md` وReport531 وReport532، وقرأت patch commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` وparent commit `41475240d2685cb7a7919e372e1e9ba10539f3e6)، وتحققت من أن مصدر النظام الأم الحالي يحتوي التعديل المسجل في ذلك الـcommit.
- **Production Understanding — CONFIRMED للبيانات وتعريف RPC؛ UI E2E غير مغلق:** استعلام SQL مباشر في 16:57:17 UTC أعاد صفّي التكليف الحاليين. تعريف Production للدالة راجعته مباشرة.
- **Current Source Understanding — CONFIRMED:** Parent `main.html` blob `0c1745081e8d17480433ed527d77cac9f5292021`; Supervisor `supervisor.html` blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Execution Confidence:** مرتفع بشأن اتساق بيانات التكليف وعقد RPC ووجود إصلاح المصدر؛ غير كافٍ لإعلان إصلاح الواجهة المنشورة.

### Confirmed / Unknown / Conflict / Unverified

**CONFIRMED**
1. Production يحتوي:
   - RS-2، تاريخ 2026-10-12، الحالة Loaded، المندوب «مندوب توصيل 3»، البريد `driver3@rawaea.com`.
   - RS-1، تاريخ 2026-10-10، الحالة Loaded، المندوب «مندوب توصيل»، البريد `driver@rawaea.com`.
2. عدد سجلات `delivery_agents` للشركة = 0. هذه ليست علامة على فقد التكليف؛ فهي طبقة مختلفة عن تكليف `runsheets.deliverer_id`.
3. تعريف `delivery_logistics_query(uuid,text,jsonb,uuid,text)` في Production يستخدم `SECURITY DEFINER` و`search_path=public`، ويتحقق من المستخدم والشركة والصلاحيات، ويُرجع `runsheet_assignments` منفصلة من جدول `runsheets` مع ربط المستخدم عبر `users.id = runsheets.deliverer_id`.
4. patch commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` أضاف جدول «تعيينات الرانشيت من مشرف التوصيل» في النظام الأم، مع إبقاء جدول المندوبين المسجلين منفصلًا. لا مبرر لإعادة تطبيقه.
5. سجلات Supabase من 2026-10-28 قرابة 16:24–16:25 UTC تُظهر طلبات مصادقًا عليها إلى `delivery_supervisor_assignment_query` وإلى `delivery_logistics_query` مع HTTP 200. سجلات PostgREST لا تتضمن body الاستجابة؛ لذا لا تُثبت وحدها محتوى `runsheet_assignments` الذي استلمه المتصفح.
6. لقطة التبويب المتصل للنظام الأم ما زالت تعرض شاشة الدخول فوق واجهة تحتوي جدول المندوبين القديم فقط، ولا تعرض جدول التكليفات الجديد. اللقطة مؤرخة 16:28:45 UTC، وليست جلسة حديثة بعد إعادة تسجيل دخول وتحديث.
7. واجهة GitHub أظهرت حالة فشل قرب commit إصلاح المصدر، بينما واجهة GitHub Actions تُظهر نجاح workflow باسم `RAWAEA forensic current Mother extract` على checkpoint توثيقي لاحق. هذا الـworkflow ليس بحد ذاته دليلًا على نشر Cloudflare ناجح؛ لذلك لا أستنتج منه أن النشر نجح أو فشل.

**UNKNOWN / UNVERIFIED**
- الـHTML الفعلي الذي يقدمه Cloudflare حاليًا بعد طلب HTTP جديد، وهل يتضمن patch commit.
- body الاستجابة الذي تلقاه المتصفح من `delivery_logistics_query` في جلسة مصادق عليها حديثًا.
- أول خطأ Console عند فتح التبويب وتحديثه بعد تسجيل الدخول.
- علاقة حالة فشل commit في GitHub بحالة نشر Cloudflare الفعلية.
- التطابق البايتّي بين Git artifact والملف المنشور.

**CONFLICT**
- مصدر Git يتضمن جدول التكليفات، وProduction data/RPC contract قادر على إرجاع التكليفات، لكن لقطة DOM القديمة لا تعرض الجدول. ولأن اللقطة تعرض أيضًا شاشة الدخول وهي قديمة، فهذا تعارض بين مصادر الأدلة وليس إثباتًا نهائيًا لعيب في كود الواجهة.

## 2. النتيجة الجنائية

**لم يثبت أن أصل المشكلة في بيانات Production أو في تعريف RPC أو في غياب patch المصدر.** إعادة تعديل SQL أو ACL أو `supervisor.html` أو إعادة كتابة جدول النظام الأم ستكون تخمينًا وتكرارًا لإصلاح قائم.

الاحتمالات التي لا تزال بحاجة إلى تمييز بالدليل:
1. المتصفح يعرض جلسة/DOM قديمة.
2. Cloudflare يخدم artifact أقدم من Git.
3. المتصفح استلم payload صحيحًا لكن واجهة العرض لم تُنفّذ/لم تُحدّث بسبب خطأ JavaScript.
4. الطلب الذي ظهر في السجل لا يخص فتح صفحة «مناديب التوصيل» في دورة الاختبار المطلوبة.

لا أختار واحدًا من هذه الاحتمالات باعتباره Root Cause قبل إثباته.

## 3. مصفوفة المسؤوليات

| المسؤولية | الدليل الحالي | الحكم |
|---|---|---|
| حفظ تكليف المندوب | `runsheets.deliverer_id` يحتوي قيمًا فعلية | CONFIRMED |
| عزل الشركة والتحقق من الصلاحية | تعريف RPC الحي | CONFIRMED من التعريف |
| إرجاع التكليفات إلى النظام الأم | فرع `agents` في Production يبني `runsheet_assignments` | CONFIRMED من التعريف، مع بيانات SQL مؤيدة |
| فصل سجل المندوبين عن التكليف | `rows` و`runsheet_assignments` منفصلان | CONFIRMED |
| عرض جدول التكليفات في Git | patch موجود في مصدر Git الحالي | CONFIRMED |
| عرض الجدول في Production بعد مصادقة جديدة | لا توجد لقطة حديثة موثقة | OPEN |
| مطابقة artifact المنشور مع Git | لم يُستخرج deployment/source identity | OPEN |

## 4. اختبارات منفذة

- **Production SQL — PASS:** RS-1 وRS-2 مسندان، والشركة صحيحة، وسجل `delivery_agents` فارغ.
- **Production RPC definition/ACL review — PASS ضمن النطاق:** تمت قراءة تعريف الدالة مباشرة؛ تقارير 531/532 وثقت ACL الحي (authenticated/service_role، دون anon).
- **Git patch/history — PASS:** الإصلاح موجود في commit محدد وblob محدد.
- **Supabase HTTP logs — PARTIAL PASS:** الطلبات المصادق عليها ذات الصلة رجعت HTTP 200؛ body غير متاح في هذه السجلات.
- **Fresh authenticated browser E2E — NOT VERIFIED.**
- **Cloudflare deployment identity/parity — NOT VERIFIED.**
- **Production closure — OPEN؛ لا إعلان 100%.**

## 5. الإجراء التنفيذي التالي المحدد

لا يحتاج الأمر إلى إعادة الاستطلاع أو تغيير قاعدة البيانات. يحتاج اختبارًا واحدًا في المتصفح المنشور، لأن أداة المتصفح المتاحة هنا في وضع القراءة فقط ولا تستطيع تسجيل الدخول أو التحديث أو فتح Network/Console:

1. في تبويب النظام الأم المفتوح، سجّل الدخول بالطريقة المعتادة دون إرسال كلمة المرور أو أي token في المحادثة.
2. افتح «مركز التوصيل واللوجستيات → مناديب التوصيل» ثم حدّث الصفحة/العرض.
3. التقط فقط: هل اختفت شاشة الدخول؟ هل يظهر جدول «تعيينات الرانشيت من مشرف التوصيل»؟ وما نتيجة طلب `delivery_logistics_query` لـ`p_view='agents'` (مع حجب Authorization والبيانات الشخصية)؟ وما أول خطأ Console إن وجد؟
4. بناءً على النتيجة:
   - **الـpayload يحتوي RS-1/RS-2 والجدول غائب:** أصلح خطأ العرض المحدد أو أصلح نشر artifact إذا ثبت أنه قديم.
   - **الـpayload لا يحتوي التكليفات:** قارن arguments/signature/identity الفعلية مع الدالة الحية ثم أصلح caller فقط.
   - **الـartifact المنشور يفتقد patch:** انشر commit المصدر المقصود من Cloudflare ثم أعد اختبار المصادقة والعرض.
   - **الجدول يعرض الصفين:** سجّل دليل E2E وأغلق التكامل.

## 6. سجل التغييرات

- `erp-frontend/companies/company-1/main.html`: لم يتغير.
- `erp-frontend/companies/company-1/delivery/supervisor.html`: لم يتغير.
- Production schema/data/functions/ACL/RLS: لم تتغير.
- Cloudflare/Service Worker: لم يتغير.
- لم تُنشأ سجلات مناديب وهمية ولم تُعدّل أي رانشيت أو حركة مخزون أو قيد محاسبي.
- التغيير في هذه الدورة توثيقي فقط، حتى لا نغطي المشكلة بتعديل غير مثبت.

## 7. SELF-AUDIT FINAL

- **What I Proved:** التكليفان موجودان في Production؛ عقد RPC يفصل سجل المندوبين عن تكليفات الرانشيت؛ الإصلاح المصدرّي موجود في Git؛ توجد طلبات RPC مصادق عليها رجعت 200.
- **What I Did Not Prove:** محتوى body الذي استلمه المتصفح، ظهور الجدول في جلسة حديثة، أو هوية artifact المنشور.
- **What I Fixed:** لم أغيّر كودًا تشغيليًا لأن لا يوجد عيب جديد معزول بدليل؛ وثقت الفارق بين ما ثبت وما لم يثبت وحددت اختبار الحسم.
- **What I Initially Missed:** HTTP 200 في السجل لا يثبت أن body احتوى الصفوف، ولقطة DOM التي تعرض login overlay لا تمثل E2E مصادقًا عليه حديثًا.
- **What Could Still Be Wrong:** نشر Cloudflare قد يكون متأخرًا، أو قد توجد مشكلة runtime في العرض، أو أن اللقطة الحالية غير صالحة بسبب حالة الجلسة.
- **Final Confidence:** عالٍ لطبقة Production data/RPC/source; غير كافٍ لإغلاق UI runtime.
- **Final Closure Status:** `PRODUCTION DATA/RPC VERIFIED / SOURCE PATCH PRESENT / FRESH AUTHENTICATED UI E2E OPEN / NOT CLOSED`.
