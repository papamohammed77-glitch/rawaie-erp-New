# Report535 — فحص حي لتكليفات الرانشيت في النظام الأم بعد مطابقة Production

**وقت فحص Production:** 2026-10-28T20:02:02.802010Z (من PostgreSQL مباشرة)  
**النطاق المحدد:** تطبيق مشرف التوصيل → `runsheets.deliverer_id` → `delivery_logistics_query(view='agents')` → `RW_DeliveryLogistics.agents()` في النظام الأم → صفحة Cloudflare المنشورة.  
**سياسة التغيير:** لا تعديل على `main.html` أو `supervisor.html`، ولا تغيير لبيانات الأعمال أو RPC/ACL/RLS؛ لا يوجد Defect جديد مثبت يبرر تعديلًا تشغيليًا إضافيًا.

## 1. PRE-CHANGE SELF-AUDIT

| البند | التقييم | الدليل |
|---|---|---|
| فهم العملية | CONFIRMED | إسناد مندوب التوصيل محفوظ على `runsheets.deliverer_id`، وهو منفصل عن سجل `delivery_agents` |
| مصدر النظام الأم الحالي | CONFIRMED | `companies/company-1/main.html`, blob `0c1745081e8d17480433ed527d77cac9f5292021` |
| إصلاح Consumer الحالي | CONFIRMED | commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` يضيف جدول `runsheet_assignments` إلى `RW_DeliveryLogistics.agents()` |
| عقد Production الحالي | CONFIRMED | جسم `public.delivery_logistics_query(uuid,text,jsonb,uuid,text)` يتضمن `runsheet_assignments`، ويطابق Migration الحالية بعد تطبيع المسافات البيضاء وفق Report534 |
| البيانات الحية | CONFIRMED | الاستدعاء الحي أعاد RS-1 وRS-2، كلاهما `Loaded` وله مندوب؛ عدد سجلات `delivery_agents` للشركة = 0 |
| Artifact المنشور | UNVERIFIED | تعذر إثبات commit/هوية HTML/JS التي يخدمها Cloudflare من الأدوات المتاحة |
| Browser E2E مصادق عليه | UNVERIFIED | علامة تبويب Production الحالية تعرض شاشة تسجيل الدخول؛ لم تُجرَ جلسة دخول أو تفاعل |
| السبب الحالي لغياب الجدول في المتصفح | UNVERIFIED | لا تتوفر استجابة Network مصادق عليها ولا DOM بعد فتح التبويب ولا Console حديث |

**Execution confidence:** مرتفع في طبقتي المصدر وعقد Production؛ غير كافٍ لإعلان نجاح الواجهة المنشورة.

## 2. Production — قراءة حية جديدة

استعلام SQL للقراءة فقط نُفذ عند `2026-10-28T20:02:02.802010+00:00`، واستدعى RPC الفعلية بسياق المستخدم المالك النشط والشركة الصحيحة:

- `success = true`.
- `runsheet_assignments` تحتوي صفين:
  - `RS-2` — `Loaded` — المندوب «مندوب توصيل 3».
  - `RS-1` — `Loaded` — المندوب «مندوب توصيل».
- `rows` الخاصة بسجل `delivery_agents` = 0.
- `delivery_agents` ليست مصدر الإسناد الفعلي؛ لذلك لا يجوز إنشاء سجلات مناديب اصطناعية لمجرد جعل الجدول غير فارغ.
- `delivery_logistics_query` ما زالت `SECURITY DEFINER`، مع `search_path=public`، وEXECUTE لـ`authenticated` و`service_role`؛ لا يوجد منح ظاهر لـ`anon` أو `PUBLIC`.
- Migration الحية `20261027170454 / delivery_supervisor_parent_runsheet_assignments` موجودة.
- لم تُعدّل أي بيانات أعمال أو صلاحيات أو تعريفات Production.

## 3. Git / Consumer tracing

### النظام الأم

- الملف: `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`
- Blob: `0c1745081e8d17480433ed527d77cac9f5292021`
- Consumer: `RW_DeliveryLogistics.agents()`، قرابة السطور 30666–30697.
- الدالة المشتركة `q(view,payload))، قرابة السطور 30513–30522، تستدعي `delivery_logistics_query` وتعيد `r.data` بعد فحص الخطأ.
- Commit الإصلاح `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` يقرأ `d.runsheet_assignments` ويبني جدولًا مستقلًا بعنوان «تعيينات الرانشيت من مشرف التوصيل»، منفصلًا عن جدول `delivery_agents`.
- مقارنة الإصلاح مع HEAD المرصود `8843150bdde99d36d477d6bb344a24df61dd2942` تظهر خمسة commits لاحقة؛ الملفات المتغيرة هي ملفات توثيق/استخراج، ولم يظهر `main.html` أو `supervisor.html` ضمن تلك التغييرات.
- رابط الإصلاح: https://github.com/papamohammed77-glitch/erp-frontend/commit/cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc

### تطبيق مشرف التوصيل

- الملف: `companies/company-1/delivery/supervisor.html`
- Blob: `3e6db903cd7da411f9ed40a449f9ee5bece5f387`
- المصدر يحتوي مسارات إسناد وفك إسناد تستخدم `delivery_supervisor_assign_deliverer_atomic`، ولا يوجد دليل حالي على أن تعديل التطبيق المنفصل هو الإصلاح الصحيح لمشكلة العرض في النظام الأم.

### عقد Production

- Migration: `supabase/migrations/20261027_delivery_supervisor_parent_runsheet_assignments.sql`
- Blob: `d3eed778670833ed84d68f765e336fbb7c3db3e9`
- تعريف الدالة الحي مطابق لجسم Migration بعد تطبيع المسافات البيضاء، وفق إعادة المطابقة المسجلة في Report534، وأكد الاستدعاء الحي الحالي أن الحقل يعيد صفين.

## 4. Root cause: ما ثبت وما لم يثبت

**السبب التاريخي المثبت:** كانت واجهة النظام الأم تعرض صفوف جدول `delivery_agents` فقط، بينما تكليفات مشرف التوصيل محفوظة في `runsheets.deliverer_id`. عالج commit `cb62612...` هذا الفصل بإضافة جدول مستقل لصفوف `runsheet_assignments`.

**ما ثبت الآن:** مصدر Git الحالي يحتوي الإصلاح، وProduction RPC تعيد الصفين الفعليين. لا يوجد دليل جديد يبرر تكرار تعديل المصدر أو تعديل SQL.

**ما لم يثبت:** لماذا لا يظهر الجدول في الصفحة المنشورة للمستخدم. لا تزال الاحتمالات غير محسومة بين Artifact مخدوم أقدم، أو جلسة/تبويب غير مصادق عليها، أو خطأ Runtime/DOM بعد الاستجابة. لا يجوز اختيار أحدها دون Network/DOM/Console حديث.

## 5. التعديل الجراحي

**لا يوجد تعديل جراحي جديد مبرر حاليًا. لا تحذف ولا تستبدل أي عنصر في `main.html` أو `supervisor.html`.** إصلاح `RW_DeliveryLogistics.agents()` موجود بالفعل في commit المذكور. إعادة تطبيقه ستكرر تغييرًا صحيحًا ولا تعالج فجوة إثبات النشر.

## 6. اختبار القبول المتبقي — خطوة واحدة محددة

من جلسة عادية مصادق عليها في صفحة النظام الأم المنشورة:

1. افتح «مركز التوصيل واللوجستيات → مناديب التوصيل».
2. من Network، التقط استجابة `delivery_logistics_query` لعرض `agents` بعد حجب Authorization وبيانات الجلسة.
3. تحقق من وجود RS-1 وRS-2 في `runsheet_assignments`.
4. تحقق من ظهور جدول «تعيينات الرانشيت من مشرف التوصيل» وصفَّيه في DOM.
5. إذا كانت الاستجابة تحتوي الصفين والجدول غائبًا، التقط أول خطأ Console. إذا غاب الحقل من الاستجابة، سجّل اسم RPC ومعاملات الطلب المنقحة. لا ترسل كلمات مرور أو Cookies أو JWT أو Authorization header.

بعد هذه الأدلة فقط يُحدد الإصلاح النهائي:
- payload صحيح والجدول غائب: إصلاح rendering بعد تحديد خطأ JavaScript الفعلي.
- payload لا يحتوي الحقل: تحديد RPC/Artifact المستدعى فعليًا قبل تعديل SQL.
- الملف المخدوم أقدم من Git: إصلاح النشر/cache بعد إثبات هوية Artifact.

## 7. Mutation ledger

- Source files: لم تتغير.
- Production schema/RPC/ACL/RLS: لم تتغير.
- Business data / runsheets / inventory / accounting: لم تتغير.
- Deployments / Service Worker: لم تتغير.
- Fixture أو بيانات اختبار جديدة: لم تُنشأ.
- هذا التقرير يوثق قراءة Production مباشرة ونتيجة مقارنة المصدر فقط.

## 8. SELF-AUDIT FINAL

- **What I Proved:** Production RPC تعيد RS-1 وRS-2؛ كلاهما Loaded ومُسند؛ إصلاح Consumer موجود في Git الحالي؛ Migration الحية متوافقة مع الدالة الحية وفق المطابقة السابقة؛ لا يوجد انحراف مصدر/Production مثبت في هذا المسار.
- **What I Did Not Prove:** هوية Artifact المخدوم حاليًا؛ استجابة Network من جلسة مصادق عليها؛ ظهور الجدول فعليًا في DOM؛ نجاح E2E منشور.
- **What I Fixed:** لا إصلاح تشغيلي جديد؛ الإصلاح الموجود سبق دمجه، ولم يثبت عيب جديد يبرر تغييره.
- **What I Initially Missed:** يجب فصل عدد سجلات `delivery_agents` عن عدد الإسنادات في `runsheets.deliverer_id`; هما عقدان مختلفان.
- **What Could Still Be Wrong:** قد لا تكون نسخة Git الحالية هي النسخة المخدومة، أو قد يحدث خطأ rendering بعد استجابة صحيحة؛ كلاهما UNVERIFIED.
- **Final Confidence:** المصدر وعقد Production = CONFIRMED؛ الواجهة المنشورة = UNVERIFIED.
- **Final Closure Status:** `SOURCE + PRODUCTION RPC VERIFIED / PUBLISHED AUTHENTICATED UI E2E OPEN / NOT CLOSED`.
