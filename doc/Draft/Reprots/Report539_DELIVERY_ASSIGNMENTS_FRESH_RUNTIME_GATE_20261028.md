# Report539 — إعادة التحقيق الحي في ظهور تكليفات التوصيل بعد Report538

**وقت التحقق:** 2026-10-28T20:45:21Z (UTC، وقت قراءة Production).  
**النطاق:** تكليفات مشرف التوصيل → `runsheets.deliverer_id` → `delivery_logistics_query(...,'agents',...)` → `RW_DeliveryLogistics.agents()` → Cloudflare Parent UI.  
**سياسة التغيير:** فحص Production قرائي فقط؛ لا تعديل بيانات أو RPC/ACL/RLS أو HTML أو نشر.

## 1. PRE-CHANGE SELF-AUDIT

| المجال | الحالة | الإثبات |
|---|---|---|
| Business contract | CONFIRMED | التكليف الفعلي محفوظ في `runsheets.deliverer_id`; سجل `delivery_agents` إداري منفصل. |
| Production data | CONFIRMED | القراءة المباشرة في 20:45:21Z أعادت RS-1 وRS-2 بحالة `Loaded` مع `deliverer_id` مرتبط بمستخدم نشط من الشركة نفسها. |
| Production RPC | CONFIRMED | استدعاء حي للدالة أعاد `success=true` و`runsheet_assignments=[RS-2, RS-1]`. |
| Empty master registry | CONFIRMED | `delivery_agents` يحتوي 0 صفوف للشركة؛ لا يثبت ذلك غياب التكليفات ولا يبرر إدخال سجلات اصطناعية. |
| Owner actor | CONFIRMED | `owner@alrawae.com` نشط و`permissions=["*"]`؛ استُخدمت هويته الممررة للقراءة فقط. |
| RPC security metadata | CONFIRMED جزئيًا | التوقيع `delivery_logistics_query(uuid,text,jsonb,uuid,text)`، `SECURITY DEFINER`، `search_path=public`. لا تغيير أمني نُفّذ. |
| Current Git source | CONFIRMED من هوية GitHub | HEAD `8843150bdde99d36d477d6bb344a24df61dd2942`؛ Blob `companies/company-1/main.html` = `0c1745081e8d17480433ed527d77cac9f5292021`. |
| Existing Parent consumer repair | CONFIRMED | Commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` يقرأ `d.runsheet_assignments` ويرسم بطاقة منفصلة. Diff المباشر يثبت ذلك. |
| Fresh authenticated UI | UNVERIFIED | قراءة المتصفح المتصل تعرض نموذج الدخول فوق هيكل التطبيق؛ لا توجد جلسة حديثة مثبتة داخل العرض المستهدف. |
| Network response / DOM / Console | UNVERIFIED | أداة المتصفح المتاحة هنا للقراءة فقط ولا توفر التحكم أو استخراج Network/Console. |
| Served Cloudflare artifact identity | UNVERIFIED | لا توجد أداة Cloudflare تحكم/نشر متاحة في سياق التنفيذ الحالي، والوصول المباشر عبر أداة الويب لم يُرجع artifact. |
| Root cause of visible symptom | UNVERIFIED | لا يوجد دليل يميز بين عدم اكتمال المصادقة/عدم فتح العرض، أو اختلاف artifact المنشور، أو خطأ عرض runtime. |

## 2. Fresh Production snapshot

### Runsheets and users

- `RS-1`: `Loaded`; `deliverer_id=0912a68e-a2d6-4e3a-b44d-41f8826fb900`; المستخدم `driver@rawaea.com`; الشركة `00000000-0000-0000-0000-000000000001`.
- `RS-2`: `Loaded`; `deliverer_id=5fc15ecf-450c-4499-8edb-eb5bd4fbf963`; المستخدم `driver3@rawaea.com`; الشركة نفسها.
- كلا المستخدمين نشطان وصلاحياتهما `["delivery"]`.
- `owner@alrawae.com` نشط وصلاحياته `["*"]`.
- عدد سجلات `delivery_agents` للشركة: `0`.

### RPC result

الاستدعاء المباشر:

```sql
select public.delivery_logistics_query(
  '00000000-0000-0000-0000-000000000001'::uuid,
  'agents'::text,
  '{}'::jsonb,
  '3196bcda-a553-4de2-8cd6-8b5003522e7e'::uuid,
  'owner@alrawae.com'::text
);
```

أعاد `success=true` و`runsheet_assignments` تتضمن RS-2 وRS-1، بينما `rows=[]` بسبب خلو سجل `delivery_agents` الإداري. لا توجد حاجة مثبتة لتعديل البيانات أو إنشاء سجلات إضافية.

## 3. Parent consumer / Git history

الـHEAD التشغيلي المسجل ما زال `8843150bdde99d36d477d6bb344a24df61dd2942`، وBlob الملف `0c1745081e8d17480433ed527d77cac9f5292021`.

الـdiff المباشر للـcommit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` يثبت أن `RW_DeliveryLogistics.agents()`:
1. يستدعي `q('agents',...)`.
2. يقرأ `d.runsheet_assignments` بصورة منفصلة عن `d.rows`.
3. يبني جدول تكليفات مستقلًا بعنوان «تعيينات الرانشيت من مشرف التوصيل».
4. يعرض هذا الجدول حتى عندما تكون قائمة `delivery_agents` فارغة.

لذلك لا أكرر تعديل المصدر الموجود ولا أغيّر العقد الخلفي دون دليل جديد.

## 4. Runtime evidence and limits

تبويب الإنتاج المتصل `https://rawaea-erp.pages.dev/companies/company-1/main` يعرض نموذج تسجيل الدخول واسم المستخدم المعبأ، وليس دليلًا على جلسة مصادق عليها أو فتح العرض المستهدف. هذا snapshot قراءة فقط، ولا يثبت سبب المشكلة.

لم أتمكن من جمع Network response أو DOM الخاص ببطاقة التكليفات أو Console من أدوات المتصفح المتاحة، كما لم يمكن إثبات هوية artifact الذي يقدمه Cloudflare. محاولة فتح الرابط عبر أداة الويب لم تسترجع الصفحة. لذلك لا أدّعي تنفيذ HTTP/UI E2E أو نشر أو إصلاح runtime.

## 5. Root-cause decision

**النتيجة: لا يوجد Root Cause مثبت حتى الآن.** Production data وRPC صحيحتان في الفحص الحي، وإصلاح المستهلك موجود في مصدر Git. نقطة الانقطاع غير محسومة بين المصادقة/مسار فتح العرض، والـartifact المنشور، وسلوك العرض في runtime.

لم يتم:
- تعديل `main.html` أو أي تطبيق تشغيلي.
- تعديل Production schema/data/RPC/ACL/RLS.
- إنشاء `delivery_agents` تجريبية أو تغيير تكليفات RS-1/RS-2.
- النشر على Cloudflare أو تغيير Service Worker.

## 6. الحد الأدنى المطلوب لإغلاق بوابة الواجهة

في جلسة المتصفح المنشورة بعد تسجيل الدخول الطبيعي، افتح **مركز التوصيل واللوجستيات → مناديب التوصيل** ثم أرسل الأدلة التالية فقط، مع تنقيح أي أسرار:

1. Response body لطلب `delivery_logistics_query` الخاص بـ`agents`، وبالأخص وجود `runsheet_assignments` وRS-1/RS-2.
2. هل بطاقة «تعيينات الرانشيت من مشرف التوصيل» موجودة في DOM، وهل تحتوي صفوفًا؟
3. إذا أعادت الاستجابة الرانشيتين ولم تظهر البطاقة: أول Console error ذي صلة واسم الملف/السطر.

لا ترسل كلمة مرور أو Cookie أو JWT أو Authorization header.

قرار الإصلاح بعد الدليل:
- إذا غابت التكليفات من الاستجابة: نراجع سياق الاستدعاء/النسخة الفعلية من RPC.
- إذا حضرت التكليفات وغابت البطاقة: نحدد خطأ العرض أو اختلاف artifact ثم نقدم تعديلًا جراحيًا محددًا أو نصلح النشر إذا ثبت drift.
- إذا حضرت البطاقة والصفوف: نحدد الشاشة/المسار الذي يراه المستخدم قبل تغيير أي كود.

## 7. SELF-AUDIT FINAL

- **What I Proved:** وجود تكليفات RS-1/RS-2 في Production؛ صحة RPC واستجابتها؛ فصل التكليف عن سجل `delivery_agents`؛ صلاحيات المالك النشطة؛ وجود إصلاح المستهلك في Git.
- **What I Did Not Prove:** استجابة Network من جلسة مصادق عليها، ظهور الصفوف في DOM، Console، أو هوية artifact المنشور على Cloudflare.
- **What I Fixed:** لم أجرِ تعديلًا تشغيليًا جديدًا لأن العيب في runtime لم يُثبت؛ تجنبت تكرار الإصلاح أو تعديل بيانات سليمة.
- **What I Initially Missed:** لا يوجد خلل جديد مثبت في هذه الدورة؛ استعلام السجلات الاستكشافي أخفق بسبب صيغة تاريخ غير متوافقة مع ClickHouse، ولم يغيّر بيانات ولم يُستخدم دليلًا.
- **What Could Still Be Wrong:** المصادقة/مسار العرض، artifact drift، أو خطأ runtime في العرض؛ كلها احتمالات غير محسومة.
- **Final Confidence:** مرتفع في Production data/RPC؛ مرتفع في وجود إصلاح المستهلك في Git؛ غير كافٍ للحكم على UI production.
- **Final Closure Status:** `PRODUCTION DATA/RPC VERIFIED / SOURCE CONSUMER PRESENT / PUBLISHED AUTHENTICATED UI E2E UNVERIFIED / NOT CLOSED`.
- **Next exact checkpoint:** Response + DOM + Console من جلسة إنتاج مصادق عليها حديثًا، ثم إصلاح السبب المثبت فقط.
