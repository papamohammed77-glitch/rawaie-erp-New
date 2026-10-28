# Report540 — إعادة فحص حي لتكليفات مندوبي التوصيل وConsumer/Authentication Gate

**وقت الرصد:** 2026-10-28T21:00Z تقريبًا (UTC).  
**المهمة:** ظهور تكليفات الرانشيتات في النظام الأم — مركز التوصيل واللوجستيات → مناديب التوصيل.  
**القرار:** لا تعديل تخميني في HTML أو Production؛ عُثر على دليل يفسر فشل استدعاء RPC من سياق SQL غير المصادق، لكن هذا وحده لا يثبت فشل الاستدعاء من جلسة HTTP مصادق عليها.

## PRE-CHANGE SELF-AUDIT

| المجال | الحالة | الدليل |
|---|---|---|
| Business understanding | CONFIRMED | التكليف الحقيقي مصدره `runsheets.deliverer_id`؛ سجل `delivery_agents` سجل إداري مستقل. |
| Production data | CONFIRMED | فحص مباشر عند 2026-10-28 20:57:33Z: RS-1 وRS-2 بحالة `Loaded` ولكل منهما `deliverer_id` صالح مرتبط بمستخدم من الشركة نفسها. |
| Production RPC | CONFIRMED | استدعاء مباشر أعاد `success=true` و`runsheet_assignments=[RS-2, RS-1]` و`rows=[]`. |
| Empty `delivery_agents` registry | CONFIRMED | العدد 0؛ لا يُنشأ سجل اصطناعي ولا يُغيّر التكليف لمعالجة العرض. |
| Parent source identity | CONFIRMED | المستودع `erp-frontend`, الفرع `main`; blob `0c1745081e8d17480433ed527d77cac9f5292021`. |
| Full source review | CONFIRMED | تمت قراءة محتوى GitHub file textarea كاملًا: 33,153 سطرًا، 1,788,154 حرفًا. |
| Existing consumer repair | CONFIRMED | commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` موجود في سجل الملف؛ كود `agents()` الحالي يقرأ `d.runsheet_assignments` ويرسم بطاقة مستقلة. |
| Production authenticated UI | UNVERIFIED | التبويب المنشور المتاح يعرض شاشة الدخول؛ لا توجد جلسة مصادق عليها مفتوحة في العرض المستهدف. |
| Network body / DOM / Console | UNVERIFIED | واجهة Browser المتاحة هنا للقراءة فقط ولا توفر أدوات Network/Console أو التفاعل لتسجيل الدخول. |
| Served Cloudflare artifact identity | UNVERIFIED | لا يوجد إثبات مستقل أن artifact الذي يقدمه Cloudflare يطابق blob الحالي. |

## 1. Fresh Production snapshot

استعلام القراءة المباشر عند `2026-10-28 20:57:33.798885+00` أثبت:

- `RS-1`: `Loaded`, `deliverer_id=0912a68e-a2d6-4e3a-b44d-41f8826fb900`, المستخدم `driver@rawaea.com`.
- `RS-2`: `Loaded`, `deliverer_id=5fc15ecf-450c-4499-8edb-eb5bd4fbf963`, المستخدم `driver3@rawaea.com`.
- الشركة: `00000000-0000-0000-0000-000000000001`.
- عدد صفوف `delivery_agents` للشركة: `0`.

والاستدعاء المباشر لـ`delivery_logistics_query(company,'agents',payload,owner.id,owner.email)` أعاد التكليفين في `runsheet_assignments`. لذلك لا يوجد دليل يبرر تعديل البيانات أو إنشاء سجلات مندوبين جديدة.

## 2. مراجعة المصدر الحالي كاملًا

- الملف: `companies/company-1/main.html`
- Blob SHA: `0c1745081e8d17480433ed527d77cac9f5292021`
- الحجم المعروض على GitHub: 33,153 سطرًا / 1.79 MB.
- المواضع ذات الصلة:
  - `RW_DeliveryLogistics`: يبدأ عند السطر 30411.
  - `q(view,payload)`: السطور 30513–30522.
  - `agents()`: يبدأ عند السطر 30668.
  - `refresh()`: السطور 30741–30754.
  - التوجيه إلى `RW_DeliveryLogistics.render()`: السطر 31055.

الدالة `agents()` الحالية تستدعي `q('agents',...)`، ثم تقرأ `d.runsheet_assignments` وتبني جدول «تعيينات الرانشيت من مشرف التوصيل» مستقلًا عن جدول `delivery_agents`. وفي حال فشل القراءة، يعرض `refresh()` رسالة الخطأ وحل إعادة المحاولة. لم أجد في هذا المسار عيبًا جديدًا مثبتًا يبرر تكرار تعديل commit `cb62612...`.

## 3. Security / identity contract — نتيجة مهمة وحدودها

تعريف Production الحالي لـ`delivery_logistics_query(uuid,text,jsonb,uuid,text)`:

- `SECURITY DEFINER`, `search_path=public`.
- إذا كان `auth.uid()` غير NULL، يحل هوية المستخدم من `public.users.auth_id=auth.uid()` مع مطابقة `company_id` والحالة النشطة.
- إذا كان `auth.uid()` NULL، يعتمد على `p_actor_user_id` و`company_id`.
- يتحقق من تطابق `p_actor_email` مع بريد المستخدم المحلول.

المصدر الحالي في `q()` يرسل `p_actor_user_id:null` و`p_actor_email:u.email`. هذا **ليس عيبًا مثبتًا في جلسة مصادق عليها**، لأن الدالة تستخدم `auth.uid()` عند وجود JWT صالح. لكن تنفيذ الاستدعاء نفسه من SQL Editor بلا سياق Auth، مع `p_actor_user_id=NULL`, فشل برسالة `هوية المستخدم أو سياق الشركة غير صالح` كما يتوقع هذا الفرع من العقد. هذا الاختبار لا يحاكي HTTP RPC مصادقًا عليه ولا يجوز استخدامه دليلًا على فشل المستخدم داخل التطبيق.

استعلام السجلات خلال الفترة المحددة أظهر هذا الخطأ الخاص باستعلام SQL التشخيصي نفسه عند 20:59:50Z؛ لم يظهر من هذا الاستعلام دليل يربطه بطلب واجهة مصادق عليه. لا أخلط بين الخطأ التشخيصي وRuntime المستخدم.

## 4. Published runtime

السياق المتاح للصفحة المنشورة `https://rawaea-erp.pages.dev/companies/company-1/main` يعرض نموذج تسجيل الدخول فوق هيكل التطبيق، مع `owner@alrawae.com` مملوءًا في حقل البريد، وحقل كلمة المرور فارغًا. هذا يثبت فقط أن **علامة التبويب المتاحة حاليًا غير مثبتة المصادقة**؛ ولا يثبت أن التكليفات لا تظهر بعد تسجيل الدخول.

لم أتمكن من جمع Network response أو DOM للبطاقة بعد مصادقة حديثة أو Console أو هوية artifact المنشور. لذلك لم يتم إثبات Root Cause النهائي للشكوى الأصلية، ولا أزعم إغلاق المهمة.

## 5. Root-cause decision

- **CONFIRMED:** بيانات التكليفات موجودة؛ RPC يعيدها؛ Consumer الذي يعرضها موجود في مصدر Git الحالي؛ سجل `delivery_agents` ليس مصدر التكليف.
- **CONFIRMED:** علامة التبويب المتاحة الآن تعرض نموذج الدخول وليست جلسة مصادقًا عليها في العرض المطلوب.
- **UNKNOWN:** هل تختفي البطاقة/الصفوف في جلسة مصادق عليها حديثًا؟
- **UNKNOWN:** هل artifact المنشور يطابق blob الحالي؟
- **UNVERIFIED:** Network body وDOM وConsole في الجلسة المنشورة المصادق عليها.
- **قرار التعديل:** لا تغيير SQL/ACL/RLS/بيانات، ولا تعديل HTML إضافي قبل الحصول على دليل يحدد نقطة الانقطاع. الإصلاح السابق في المصدر لم يُكرر ولم يُلغَ.

## 6. الإجراء الأدنى لإغلاق بوابة الواجهة

في الصفحة المنشورة، سجّل الدخول بالطريقة المعتادة بنفسك، ثم افتح **مركز التوصيل واللوجستيات → مناديب التوصيل**. لا ترسل أي كلمة مرور أو Cookie أو JWT أو Authorization header.

أرسل فقط:
1. هل ظهرت بطاقة «تعيينات الرانشيت من مشرف التوصيل»؟ وهل تعرض RS-1 وRS-2؟
2. إذا لم تظهر: Response body منقح لطلب `delivery_logistics_query` الخاص بـ`agents`، مع بقاء `runsheet_assignments` ظاهرًا إن وجد.
3. إذا كانت التكليفات في الاستجابة والبطاقة غائبة: أول خطأ Console ذي صلة واسم الملف/السطر.

بناءً على النتيجة:
- لا تكليفات في الاستجابة: نراجع عقد/سياق RPC الفعلي.
- التكليفات موجودة والبطاقة غائبة: نحدد خطأ العرض أو artifact drift ونجهز أصغر تعديل مثبت.
- البطاقة والصفوف ظاهرة: نحدد المسار/العرض الذي كان المستخدم يراجعه قبل تغيير أي كود.

## 7. Mutation ledger

- Production DB/RPC: قراءة فقط.
- بيانات RS-1/RS-2: لم تتغير.
- `delivery_agents`: لم تُضف سجلات.
- HTML/JavaScript/Service Worker/Cloudflare: لم تتغير.
- لا Edge Functions جديدة.
- التوثيق و`CURRENT_STATE.md` فقط هما التغييران المطلوبان في هذه الدورة.

## SELF-AUDIT FINAL

- **What I Proved:** البيانات والتكليفات وRPC؛ هوية blob الحالي؛ وجود Consumer repair؛ قراءة الملف كاملًا؛ سلوك الهوية في تعريف RPC؛ حالة علامة التبويب المتاحة.
- **What I Did Not Prove:** نجاح/فشل عرض التكليفات في جلسة HTTP مصادق عليها حديثًا؛ تطابق artifact المنشور؛ Network/DOM/Console للعرض المستهدف.
- **What I Fixed:** لم أضف إصلاحًا تشغيليًا غير مبرر؛ حافظت على إصلاح المصدر الموجود وتجنبت تغيير بيانات صحيحة.
- **What I Initially Missed:** استدعاء SQL بلا `auth.uid()` ليس اختبارًا مكافئًا لاستدعاء RPC من جلسة Auth. فشله لا يثبت عيبًا في مسار المستخدم المصادق عليه.
- **What Could Still Be Wrong:** قد تكون المشكلة في المصادقة/فتح العرض، أو artifact المنشور، أو خطأ runtime؛ لا يوجد دليل يميز بينها حتى الآن.
- **Final Confidence:** عالٍ في بيانات Production وRPC والمصدر؛ غير كافٍ في نتيجة الواجهة المنشورة.
- **Final Closure Status:** `SOURCE + PRODUCTION DATA/RPC VERIFIED / AUTHENTICATED PUBLISHED UI E2E OPEN / NOT CLOSED`.
- **Next exact checkpoint:** تسجيل دخول طبيعي في التبويب المنشور، ثم فحص بطاقة التكليفات وResponse/DOM/Console بحسب النتيجة.
