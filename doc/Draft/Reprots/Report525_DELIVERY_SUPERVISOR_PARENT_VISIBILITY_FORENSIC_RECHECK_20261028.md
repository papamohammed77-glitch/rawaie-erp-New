# Report525 — إعادة التحقيق في ظهور تكليفات مشرف التوصيل داخل النظام الأم

**تاريخ التحقق:** 2026-10-28  
**النطاق:** إدارة التوصيل والشحن ← مناديب التوصيل؛ لا توسع إلى وحدات أخرى.  
**الحالة:** `CURRENT SOURCE + LIVE PRODUCTION RPC/DATA VERIFIED / DEPLOYED UI E2E UNVERIFIED / NO NEW SURGICAL CODE CHANGE JUSTIFIED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** إسناد مستخدم مندوب توصيل إلى رانشيت محفوظ في `runsheets.deliverer_id`. هذا ليس إنشاء سجل تعاقدي في `delivery_agents`، ولا يساوي إسناد خطة مسار.
- **Architecture Understanding — CONFIRMED:** تطبيق مشرف التوصيل يستخدم `delivery_supervisor_assign_deliverer_atomic`، بينما النظام الأم يعرض عقد قراءة `delivery_logistics_query` في تبويب مستقل.
- **Database Understanding — CONFIRMED:** أعاد Production صفّي التكليف الحاليين عبر `runsheet_assignments`; سجل `delivery_agents` النشط للشركة الحالية فارغ.
- **Historical Understanding — CONFIRMED:** تمت قراءة `CURRENT_STATE.md` وReport524 وReport523 وReport517 كأدلة تاريخية، ثم إعادة التحقق من Git وProduction مباشرة. لم تُعامل التقارير كبديل عن الحالة الحية.
- **Production Understanding — CONFIRMED:** أُعيد فحص تعريف RPC الحي وACL والبيانات واستدعاء SQL للقراءة.
- **Current Understanding — CONFIRMED:** أعيد جلب ملف النظام الأم وملف مشرف التوصيل من الفرع `main`.
- **Execution Confidence:** مرتفع في عقد Git وProduction؛ غير كافٍ لإثبات تطابق النشر أو نجاح واجهة المتصفح.

## 2. الأدلة الحالية

### Git / المصدر التشغيلي

- المستودع التشغيلي: [erp-frontend](https://github.com/papamohammed77-glitch/erp-frontend), الفرع `main`.
- ملف النظام الأم: `companies/company-1/main.html`, blob SHA `0c1745081e8d17480433ed527d77cac9f5292021`.
- ملف مشرف التوصيل: `companies/company-1/delivery/supervisor.html`, blob SHA `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- أحدث commit عُرض في سجل commits: `8843150bdde99d36d477d6bb344a24df61dd2942` — “Clarify code checkpoint versus documentation commits”، بتاريخ 2026-10-27 18:56:06 UTC. هذا commit توثيقي/توضيحي؛ لا يثبت نشر HTML.
- التغيير الوظيفي الذي أضاف عرض التكليفات موجود في commit `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`، ومصدره الحالي يتضمن التغيير بالفعل.
- ملف `supervisor.html` لم يتغير عن blob الذي وثقته المراجعات الأخيرة.

### عقد النظام الأم في المصدر الحالي

داخل `RW_DeliveryLogistics`:

1. `q(view,payload)` يستدعي `delivery_logistics_query` ويعيد `r.data` كاملة بعد فحص الخطأ.
2. `agents()` يقرأ `d.rows` لسجل `delivery_agents`، ويقرأ `d.runsheet_assignments` في متغير مستقل.
3. يبني جدولًا مستقلًا بعنوان «تعيينات الرانشيت من مشرف التوصيل»، ويعرض الرانشيت والتاريخ واسم المندوب والحالة والارتباط بسجل اللوجستيات.
4. يبقى جدول `delivery_agents` الإداري والبحث فيه منفصلين؛ لا يوجد إنشاء تلقائي لسجل Agent أو Route Plan بسبب الإسناد.

**النتيجة:** رقعة عرض التكليفات موجودة في المصدر الحالي. لا يوجد مقطع معيب مثبت في النسخة الحالية يبرر تكرار التعديل نفسه أو استبدال الدالة كاملة.

### Supabase Production — قراءة مباشرة

- المشروع: `fiilmooggumokxanwiyx` (SMART ERP).
- وقت استعلام البيانات: `2026-10-28 12:37:32 UTC`.
- `delivery_logistics_query(uuid,text,jsonb,uuid,text)`: `SECURITY DEFINER=true`، `search_path=public`، التنفيذ متاح لـ`authenticated` و`service_role`، وغير متاح لـ`anon`.
- استدعاء القراءة المباشر بـview=`agents`، ومعاملات الشركة الحالية وهوية مالك نشط مخوّل، أعاد `success=true` و`rows=[]` و`runsheet_assignments` تتضمن:
  - `RS-2` — «مندوب توصيل 3» — `Loaded` — 2026-10-12.
  - `RS-1` — «مندوب توصيل» — `Loaded` — 2026-10-10.
- إجمالي الرانشيتات للشركة = 2، المسند منها = 2، وسجلات `delivery_agents` ذات الحالة `Active` = 0.
- `delivery_agent_code=null` للسجلين متسق مع غياب سجلات اللوجستيات النشطة؛ لا يدل على فقدان تكليف المستخدم.
- `driver_id` و`vehicle_id` منفصلان عن `deliverer_id`; لم تُغيّر هويات السائق أو المركبة.

## 3. السبب والحسم

### ما ثبت

- **عقد حفظ الإسناد سليم في Production:** التكليفان موجودان في `runsheets.deliverer_id`.
- **عقد القراءة سليم في Production SQL:** RPC يعيد التكليفين داخل `runsheet_assignments`.
- **مصدر النظام الأم الحالي يتضمن جدول التكليفات:** لا يلزم تعديل `main.html` مرة أخرى اعتمادًا على الأدلة الحالية.
- **لا يلزم تعديل `supervisor.html` أو إنشاء Edge Function أو RPC إضافي** لإعادة تنفيذ وظيفة موجودة بالفعل.

### ما لم يثبت بعد

لم تتوفر أدلة مباشرة في هذه الجولة على:
- أن HTML/JavaScript الذي يقدمه Cloudflare يطابق blob الحالي.
- أن مستخدمًا مصادقًا فتح النسخة المنشورة ورأى RS-1 وRS-2.
- نتيجة Browser/HTTP E2E من الواجهة المنشورة.

لذلك لا يجوز اختلاق سبب نهائي مثل «Cloudflare قديم» قبل مقارنة artifact المخدوم، ولا يجوز اعتبار SQL E2E دليلًا على ظهور الواجهة.

## 4. التعديل الجراحي

**لا يوجد تعديل كود جديد مبرر في هذه اللحظة.**

لا تبحث عن مقطع لاستبداله في `main.html` أو `supervisor.html`: كود جدول التكليفات موجود بالفعل في المصدر الحالي، وتكرار الرقعة قد يكرر واجهة أو يفسد الترتيب القائم.

الإجراء الفاصل التالي، دون تغيير الكود:
1. افتح نسخة النظام الأم المنشورة ← إدارة التوصيل والشحن ← مناديب التوصيل.
2. افحص Network لطلب `delivery_logistics_query` عند فتح التبويب، وتأكد أن الاستجابة تحتوي `runsheet_assignments` بصفّين.
3. قارن HTML/JS المخدوم بالـblob `0c1745081e8d17480433ed527d77cac9f5292021`.
4. إذا كان الرد يحتوي الصفّين لكن الواجهة لا تعرضهما، حدّد خطأ Runtime في المتصفح وموقعه قبل صياغة رقعة جديدة. وإذا كان artifact قديمًا، أصلح مسار النشر/التحديث بدل تكرار تعديل المصدر.
5. لا تنشئ بيانات اختبار، ولا تعدّل RS-1 أو RS-2؛ فهما بيانات تشغيل فعلية استُخدمت للقراءة فقط.

## 5. سجل التغييرات

- **Production:** قراءة فقط؛ لا DDL/DML ولا تغيير RPC أو ACL/RLS.
- **Operational source:** لا تعديل في `main.html` أو `supervisor.html`.
- **Test data:** لم تُنشأ بيانات تجريبية ولم تُحذف بيانات أعمال.
- **Documentation:** إضافة هذا التقرير وتحديث `CURRENT_STATE.md` فقط.

## 6. SELF-AUDIT FINAL

- **What I Proved:** مصدر Parent الحالي يحتوي جدول التكليفات؛ Production RPC يعيد RS-1 وRS-2؛ صلاحيات RPC لا تسمح لـ`anon` بالتنفيذ؛ جدول `delivery_agents` النشط فارغ.
- **What I Did Not Prove:** تطابق artifact المنشور، عرض الجدول في متصفح مصادق عليه، ونجاح HTTP/Browser E2E.
- **What I Fixed:** لا إصلاح تشغيلي جديد؛ لم يُثبت عيب جديد في المصدر أو عقد Production. تم تحديث سجل الاستمرارية لتثبيت نقطة الحقيقة الحالية.
- **What I Initially Missed:** يجب عدم مساواة `rows=[]` في سجل `delivery_agents` بغياب تكليفات الرانشيت؛ التكليفات في حقل مستقل هو `runsheet_assignments`.
- **What Could Still Be Wrong:** artifact منشور قديم أو خطأ Runtime/جلسة/شبكة؛ كلاهما غير مثبت حتى الآن.
- **Final Confidence:** مرتفع في Git وProduction SQL، غير محسوم في Runtime المنشور.
- **Final Closure Status:** `SOURCE + PRODUCTION CONTRACT VERIFIED / DEPLOYED UI E2E OPEN / NOT CLAIMED 100% CLOSED`.
