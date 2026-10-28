# Report538 — إعادة التحقق الحي من تكليفات التوصيل وبوابة الواجهة المنشورة

**وقت التحقق:** 2026-10-28T20:40Z تقريبًا (UTC).  
**النطاق الوحيد:** Supervisor assignment → Production runsheets → `delivery_logistics_query('agents')` → Parent `RW_DeliveryLogistics.agents()` → واجهة Cloudflare المنشورة.  
**سياسة التغيير:** قراءة فقط؛ لا تعديل تشغيلي ولا نشر في هذه الدورة.

## 1. PRE-CHANGE SELF-AUDIT

| المجال | النتيجة | الدليل الحالي |
|---|---|---|
| Business Understanding | CONFIRMED | مصدر التكليف الفعلي هو `runsheets.deliverer_id`؛ سجل `delivery_agents` الإداري منفصل. |
| Production data | CONFIRMED | Production يعيد RS-1 وRS-2 بحالة `Loaded` ولكل منهما `deliverer_id` مرتبط بمستخدم داخل الشركة نفسها. |
| Production RPC | CONFIRMED | استدعاء `public.delivery_logistics_query(company_id,'agents','{}',owner.id,owner.email)` أعاد `success=true` و`runsheet_assignments` تتضمن RS-1 وRS-2. |
| Company isolation | CONFIRMED في الاستعلام/الاستجابة الحالية | الدالة تربط المستخدم والرانشيت بالشركة، والصفان ضمن company_id المتوقع. لم يُجرَ اختبار عبور بين شركتين لأن المهمة لا تحتاج تغييرًا ولا تتوفر جلسة UI تفاعلية. |
| Production security | CONFIRMED جزئيًا | الدالة `SECURITY DEFINER` و`search_path=public`؛ `authenticated` لديه EXECUTE و`anon` ليس لديه EXECUTE. |
| Current Git source | CONFIRMED | `erp-frontend/main` HEAD هو `8843150bdde99d36d477d6bb344a24df61dd2942`؛ ملف `companies/company-1/main.html` blob `0c1745081e8d17480433ed527d77cac9f5292021`. |
| Existing consumer repair | CONFIRMED من سجل المصدر والتقرير السابق | الإصلاح في commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` يعرض `d.runsheet_assignments` في بطاقة مستقلة. لم أكرر التعديل. |
| Published browser state | UNVERIFIED كجلسة مصادق عليها حديثة | قراءة التبويب المتصل ما زالت تعرض نموذج دخول مع محتوى لوحة التحكم/القائمة أسفله؛ التبويب آخر فتح مسجل عند 2026-10-28T19:49:59Z، ولا يمكن اعتباره زيارة مصادقًا عليها حديثة للعرض المستهدف. |
| Network / DOM / Console | UNVERIFIED | أداة المتصفح المتاحة في هذه الجلسة للقراءة فقط ولا تتيح فتح العرض أو التقاط Network response/Console أو إجراء تسجيل دخول. |
| Served Cloudflare artifact identity | UNVERIFIED | لا توجد أداة Cloudflare متاحة هنا لإثبات hash/commit للـartifact المنشور. |
| Root cause النهائي | UNVERIFIED | لا دليل يميز بين عدم وجود جلسة مصادق عليها/عدم فتح العرض، أو اختلاف artifact المنشور، أو خطأ JavaScript في العرض. |

## 2. Fresh Production evidence

### Runsheets

الاستعلام المباشر عن `public.runsheets` مع `public.users`، باستخدام أسماء الأعمدة الفعلية (`runsheet_code`)، أعاد:

- **RS-1** — `Loaded` — `deliverer_id=0912a68e-a2d6-4e3a-b44d-41f8826fb900` — `driver@rawaea.com`.
- **RS-2** — `Loaded` — `deliverer_id=5fc15ecf-450c-4499-8edb-eb5bd4fbf963` — `driver3@rawaea.com`.
- كلاهما في الشركة `00000000-0000-0000-0000-000000000001`.

### RPC

الاستدعاء المباشر للدالة أعاد `success=true`، و`runsheet_assignments` بها RS-2 وRS-1. حقل `rows` فارغ لأن جدول `delivery_agents` الإداري للشركة يحتوي **0** صف؛ هذا لا ينفي التكليفات ولا يبرر إنشاء صفوف اصطناعية.

### Actor

`owner@alrawae.com` ما زال Active، وصلاحياته `["*"]` في الشركة المتوقعة. استُخدم في قراءة RPC فقط.

### RPC contract

التوقيع الحي: `delivery_logistics_query(uuid,text,jsonb,uuid,text)`، `SECURITY DEFINER`، `search_path=public`، `authenticated EXECUTE=true`، `anon EXECUTE=false`. لم تتغير الدالة أو ACL.

## 3. Source / history / deployment

- Operational repository HEAD: `8843150bdde99d36d477d6bb344a24df61dd2942`، ورسالة آخر commit: `Clarify code checkpoint versus documentation commits` (2026-10-27T18:56:06Z).
- Parent file blob: `0c1745081e8d17480433ed527d77cac9f5292021`.
- Consumer repair: `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`.
- Historical checkpoint `LVE-2026-10-28-537` ما زال صحيحًا بالنسبة إلى Production data/RPC ومصدر Git، لكن لا يثبت الواجهة المنشورة.
- تعذر جلب جسم `main.html` كاملًا عبر قناة الملفات بسبب حجمه؛ لم أستنتج منه عيبًا جديدًا، واعتمدت هوية الـblob التي أعادها GitHub ومراجعة الإصلاح الموثقة سابقًا.
- لم تُنفّذ عملية نشر أو تغيير في Cloudflare.

## 4. Root cause decision

**لا يوجد سبب جذري مثبت لعدم ظهور التكليفات في الواجهة المنشورة حتى الآن.** الأدلة تثبت أن بيانات التكليفات وRPC صحيحتان وأن إصلاح المستهلك موجود في Git. لا تثبت الأدلة أن Cloudflare يقدم هذا الـblob أو أن البطاقة بُنيت في DOM أثناء جلسة مصادق عليها.

لذلك لم أعدّل `main.html`، ولم أغير RPC/ACL/RLS أو Service Worker، ولم أنشئ سجلات `delivery_agents`، ولم أعد إسناد أي رانشيت. أي من هذه التغييرات سيكون تخمينًا في غياب دليل الواجهة.

## 5. أخطاء الفحص وسجل التغيير

- استعلام استكشافي أول استخدم `runsheet_number`، وهو عمود غير موجود؛ فشل قراءة فقط، ثم صُحح إلى `runsheet_code`. لا أثر على البيانات.
- جميع استعلامات Production المنفذة كانت قرائية. لا تغيير على البيانات أو المخطط أو RPC أو الصلاحيات أو التطبيقات أو النشر.
- لم يُنشأ fixture أو harness ولم تُمس بيانات المخزون أو الحسابات.

## 6. أقرب إجراء عملي لإغلاق البوابة

يلزم إجراء واحد من المالك داخل المتصفح المنشور، دون مشاركة أي سر:

1. افتح `https://rawaea-erp.pages.dev/companies/company-1/main` وسجّل الدخول بالطريقة الطبيعية.
2. افتح **مركز التوصيل واللوجستيات → مناديب التوصيل**.
3. من Network، انسخ **الاستجابة المنقحة فقط** لطلب `delivery_logistics_query` الخاص بـ`agents`، مع إخفاء cookies وJWT وAuthorization headers.
4. أرسل نتيجة واحدة توضح: هل `runsheet_assignments` تحتوي RS-1 وRS-2؟ وهل بطاقة «تعيينات الرانشيت من مشرف التوصيل» موجودة؟ وإذا غابت رغم وجود الصفين، أرسل أول خطأ Console ذي الصلة واسم/عنوان ملف JavaScript الظاهر فيه.

هذا هو الحد الأدنى الذي يحدد الإصلاح التالي:  
- **الاستجابة لا تحتوي التكليفات:** التحقيق في سياق الاستدعاء/النسخة الفعلية من RPC.  
- **الاستجابة تحتوي التكليفات والبطاقة غائبة:** تحديد خطأ العرض أو اختلاف artifact المنشور، ثم إعداد إصلاح جراحي أو مزامنة نشر مثبتة.  
- **الاستجابة والبطاقة والصفوف موجودة:** إثبات المشكلة من الشاشة/المسار الذي يستخدمه المستخدم بدل تعديل الكود.

## 7. SELF-AUDIT FINAL

- **What I Proved:** بيانات RS-1 وRS-2 وتكليفاتهما موجودة في Production؛ RPC تعيدهما؛ `delivery_agents` فارغ بشكل منفصل؛ actor owner Active وpermissions=`["*"]`; RPC ACL/SECURITY موثقان؛ مصدر Parent الحالي يحمل blob المعروف وإصلاح المستهلك التاريخي موجود.
- **What I Did Not Prove:** ظهور البطاقة في DOM المنشور، استجابة Network من جلسة مصادق عليها حديثة، Console، أو هوية artifact الذي يقدمه Cloudflare.
- **What I Fixed:** لم أجرِ إصلاحًا تشغيليًا جديدًا لعدم ثبوت عيب إضافي؛ تجنبت تكرار patch أو تغيير Production بالتخمين.
- **What I Initially Missed:** اسم عمود غير صحيح في استعلام استكشافي؛ فشل دون أثر وصُحح.
- **What Could Still Be Wrong:** اختلاف artifact المنشور عن Git أو خطأ runtime في عرض البطاقة أو عدم فتح العرض في جلسة مصادق عليها؛ تبقى احتمالات غير مثبتة.
- **Final Confidence:** مرتفع في Production data/RPC ووجود إصلاح المستهلك في Git؛ غير كافٍ لتأكيد الواجهة المنشورة.
- **Final Closure Status:** `PRODUCTION DATA/RPC VERIFIED / SOURCE CONSUMER PRESENT / PUBLISHED AUTHENTICATED UI E2E UNVERIFIED / NOT CLOSED`.
- **Next exact checkpoint:** بعد تسجيل الدخول الطبيعي وفتح «مناديب التوصيل»، فحص response + DOM + Console في نفس الجلسة؛ لا تكرار لتعديل المصدر قبل ذلك.
