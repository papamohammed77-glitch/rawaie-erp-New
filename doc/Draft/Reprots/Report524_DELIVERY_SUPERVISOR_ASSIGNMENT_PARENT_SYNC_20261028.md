# Report524 — التحقيق الجنائي لتكامل إسناد مندوب التوصيل مع تبويب النظام الأم

**وقت التحقق:** 2026-10-28 (جلسة التنفيذ الحالية)  
**النطاق الوحيد:** ظهور إسناد مندوب التوصيل الذي ينفذه تطبيق مشرف التوصيل داخل تبويب «مناديب التوصيل» في مركز إدارة التوصيل والشحن بالنظام الأم.  
**الحالة:** `SOURCE + PRODUCTION RPC/DATA CONTRACT VERIFIED / PARENT RUNTIME DEPLOYMENT UNVERIFIED / NO NEW CODE PATCH JUSTIFIED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** مؤكد أن هوية مندوب التوصيل منفصلة عن هوية سائق المركبة، وأن إسناد المندوب إلى الرانشيت يُحفظ في `runsheets.deliverer_id`.
- **Architecture Understanding:** مؤكد أن سجل مندوب اللوجستيات `delivery_agents` كيان مستقل عن إسناد مستخدم إلى رانشيت. لا يجوز إنشاء سجل لوجستي تلقائيًا لمجرد إسناد مستخدم إلى رانشيت دون عقد صريح.
- **Database Understanding:** مؤكد من Production: RPC المركزي `delivery_logistics_query(uuid,text,jsonb,uuid,text)` يعيد `runsheet_assignments` في view=`agents` ويقرأ `runsheets.deliverer_id` مع ربط المستخدم داخل الشركة.
- **Historical Understanding:** تمت مراجعة آخر نقطة استمرار موثقة في `CURRENT_STATE.md` وReport523. هذه تقارير استرشادية؛ أُعيد فحص Git وProduction مباشرة.
- **Production Understanding:** مؤكد من تعريف RPC الحي ومن استدعاء SQL مباشر للقراءة فقط.
- **Current Understanding:** مؤكد من Git blob الحالي لـ`companies/company-1/main.html`، SHA `0c1745081e8d17480433ed527d77cac9f5292021`.
- **Execution Confidence:** مرتفع لعقد المصدر وقاعدة البيانات؛ غير كافٍ لإثبات واجهة Cloudflare المنشورة دون artifact/جلسة Runtime مباشرة.

### الأدلة التي فُحصت

- `erp-frontend/companies/company-1/main.html`: blob `0c1745081e8d17480433ed527d77cac9f5292021`، 1,788,467 حرفًا، 33,154 سطرًا.
- `erp-frontend/companies/company-1/delivery/supervisor.html`: blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- `rawaie-erp-New/CURRENT_STATE.md`: blob `d12b773cfb6df42e2a44ff9a79069b8ed735e8a8`.
- تقرير الاستمرارية السابق: `Report523_DAILY_OPERATIONAL_REVALIDATION_20261027.md`.
- Migration مصدرية: `erp-frontend/supabase/migrations/20261027_delivery_supervisor_parent_runsheet_assignments.sql`.
- Production: تعريف `delivery_logistics_query`، سجل migrations، صفوف `runsheets` و`users` و`delivery_agents`.

## 2. ما يفعله تطبيق مشرف التوصيل فعليًا

في `supervisor.html`:

- `renderTeam()` يقرأ قائمة المستخدمين المؤهلين من view=`team` ويقرأ الرانشيتات من view=`runsheets`.
- `assignDeliverer()` يستدعي `delivery_supervisor_assign_deliverer_atomic` بوسائط الشركة والرانشيت ومعرّف المستخدم و`operation_id`.
- عقد Production للدالة يحدّث `runsheets.deliverer_id` فقط، ويحافظ على `driver_id` و`vehicle_id` منفصلين.
- هذا المسار **لا ينشئ** سجلًا جديدًا في `public.delivery_agents`، وهو سلوك منفصل عن تسجيل مندوب لوجستي/تعاقدي.

## 3. ما يفعله النظام الأم في المصدر الحالي

في `companies/company-1/main.html`:

- `q(view,payload)` عند الأسطر 30513–30521 يستدعي `delivery_logistics_query` ويعيد `r.data` كاملًا، بما فيه الحقول خارج `rows`.
- `agents()` عند الأسطر 30668–30700 يقرأ `d.rows` لجدول سجل `delivery_agents`، ويقرأ `d.runsheet_assignments` بشكل مستقل.
- جدول تكليفات الرانشيت يعرض `runsheet_code` و`run_date` و`deliverer_name` و`status` و`delivery_agent_code`. وعندما لا يوجد سجل لوجستي مرتبط، يعرض `غير مرتبط بسجل مناديب اللوجستيات` بدل إنشاء سجل أو إخفاء حقيقة العلاقة.
- المصدر الحالي يحتوي بالفعل على فصل الجدولين؛ لا يوجد دليل يبرر تعديل `main.html` أو `supervisor.html` مرة أخرى.

## 4. Production — فحص حي

- مشروع Supabase: `fiilmooggumokxanwiyx`.
- تعريف Production الحالي لـ`delivery_logistics_query(uuid,text,jsonb,uuid,text)` يتضمن view=`agents` و`runsheet_assignments`، ويربط `runsheets.deliverer_id` بـ`users.id` داخل `company_id` نفسه، ويقيّد النتائج بالحالات `Loaded/Delivering/Delivered/Returning`.
- سجل migrations الحي يتضمن `20261027170454 / delivery_supervisor_parent_runsheet_assignments`.
- استدعاء SQL مباشر للقراءة فقط في هذه الجلسة أعاد `success=true` و`rows=[]` و**تكليفين فعليين** في `runsheet_assignments`:
  - `RS-2`: المندوب «مندوب توصيل 3»، الحالة `Loaded`.
  - `RS-1`: المندوب «مندوب توصيل»، الحالة `Loaded`.
- كلا التكليفين له `deliverer_user_id`، بينما `delivery_agent_code=NULL`؛ أي أن هوية المستخدم مسندة، لكن لا يوجد سجل مقابل في سجل مناديب اللوجستيات.
- عدد سجلات `delivery_agents` النشطة للشركة الحالية = **0** وفق استعلام Production. هذا يفسر لماذا قد يكون جدول «سجل المندوبين التشغيلي والتعاقدي» فارغًا، لكنه لا يفسر غياب جدول «تعيينات الرانشيت من مشرف التوصيل» إذا كانت الواجهة المنشورة تطابق المصدر الحالي.

## 5. Root Cause — التمييز الحاسم

هناك جدولان مختلفان في تبويب النظام الأم:

1. **سجل المندوبين التشغيلي والتعاقدي**: مصدره `delivery_agents`. لا يحتوي حاليًا على سجلات نشطة. إسناد مستخدم إلى رانشيت لا يضيف سجلًا لهذا الجدول.
2. **تعيينات الرانشيت من مشرف التوصيل**: مصدره `runsheets.deliverer_id` عبر `runsheet_assignments`. Production يعيد حاليًا صفّي RS-1 وRS-2 لهذا الجدول.

إذن عقد البيانات الحالي يعمل على مستوى Production SQL، ومصدر النظام الأم الحالي يستهلك نتيجة التكليفات. **لا يوجد أساس مثبت لتغيير RPC أو إنشاء Edge Function أو إنشاء سجل `delivery_agents` تلقائيًا.** إذا كانت المشكلة المرئية هي غياب صفوف RS-1/RS-2 من جدول التكليفات، فإن الاحتمال المتبقي الذي لم يُحسم هو أن الصفحة المنشورة لا تقدم blob المصدر الحالي أو أن هناك فشل Runtime/صلاحيات في جلسة المتصفح؛ لا يجوز وصف ذلك بأنه ثابت دون اختبار الواجهة المنشورة.

## 6. القرار الجراحي

**لا تعديل كود جديد في هذه الجولة.** هذا قرار مبني على الأدلة، وليس إيقافًا للمهمة أو افتراضًا أن Runtime سليم.

- لا تلمس `main.html` أو `supervisor.html`؛ كلاهما مصدر مالك، والمصدر الحالي يتضمن بالفعل جدول التكليفات والعقد المناسب.
- لا تعدّل Production RPC أو البيانات؛ الاستدعاء المباشر أثبت أن التكليفين يُعادان بالفعل، والتعديل قد يكرر مسؤولية موجودة أو يخلط سجل المستخدم بسجل اللوجستيات.
- الاختبار الفاصل المطلوب قبل أي تعديل: فتح نسخة النظام الأم المنشورة، والدخول إلى مركز إدارة التوصيل والشحن ← «مناديب التوصيل»، ثم فحص **جدول «تعيينات الرانشيت من مشرف التوصيل»** تحديدًا. يجب أن يظهر RS-1 وRS-2. إذا كان الجدول فارغًا رغم أن استدعاء RPC المصادق عليه يعيد الصفين، قارن HTML/JS المخدوم مع blob الحالي ثم أصلح فرق النشر/Runtime. لا تنشئ سجلات تجريبية ولا تعدّل RS-1/RS-2.

## 7. ما تم وما لم يتم

### CONFIRMED
- مصدر Parent الحالي يقرأ `runsheet_assignments` مستقلًا عن `delivery_agents`.
- Production RPC يعيد صفّي الإسناد الحاليين.
- `delivery_agents` لا يحتوي سجلات نشطة للشركة الحالية.
- `driver_id` و`vehicle_id` منفصلان عن `deliverer_id` في عقد التكليف.

### UNVERIFIED
- هل الصفحة المنشورة حاليًا تطابق blob `0c1745081e8d17480433ed527d77cac9f5292021`.
- هل يظهر الجدول في جلسة مستخدم حقيقية مصادق عليها، وهل توجد أخطاء Console/Network.
- اختبار HTTP/Browser E2E؛ لم يُنفّذ في هذه الجولة لعدم توفر سياق Runtime منشور يمكن التحقق منه مباشرة.

### لم يُنفذ
- لا تغييرات على بيانات الأعمال أو مخزون أو محاسبة.
- لا تعديلات على `main.html` أو `supervisor.html`.
- لا تغييرات على RPC أو Edge Functions أو ACL.
- لا بيانات تجريبية؛ صفوف Production الموجودة استُخدمت كدليل قراءة فقط.

## 8. SELF-AUDIT FINAL

- **What I Proved:** المصدر الحالي يحتوي جدولًا منفصلًا لتعيينات الرانشيت؛ Production يعيد RS-1 وRS-2 عبر `runsheet_assignments`.
- **What I Did Not Prove:** تطابق HTML المنشور مع Git وظهور الصفوف في Browser E2E.
- **What I Fixed:** لا إصلاح كود جديد؛ لا يوجد Defect جديد مثبت في العقد الحالي. سيُسجل هذا القرار لمنع إعادة فتح الإصلاح الصحيح.
- **What I Initially Missed:** يجب التفريق بين جدول سجل `delivery_agents` وجدول تكليفات `runsheets.deliverer_id`; الأول فارغ والثاني لديه صفان.
- **What Could Still Be Wrong:** قد تكون الصفحة المنشورة أقدم من المصدر الحالي، أو قد يفشل الطلب من جلسة Runtime بسبب المصادقة/التفويض/الشبكة.
- **Final Confidence:** مرتفع في Git + Production SQL؛ غير محسوم في النشر/واجهة المستخدم.
- **Final Closure Status:** `PARTIALLY VERIFIED — PARENT DEPLOYMENT / AUTHENTICATED RUNTIME E2E OPEN`.
- **LAST VERIFIED CHECKPOINT:** Production RPC `delivery_logistics_query` أعاد RS-1 وRS-2 في `runsheet_assignments` في جلسة 2026-10-28.
- **NEXT EXACT STEP:** تحقق من artifact المنشور وصفحة «تعيينات الرانشيت من مشرف التوصيل». لا تعدّل المصدر قبل إثبات أن HTML المنشور يطابق blob الحالي أو تحديد الخطأ في Runtime.
