# Report529 — إعادة تحقق إنتاجية لتكامل تكليف مندوب التوصيل مع النظام الأم

**وقت إعادة التحقق:** 2026-10-28 13:37 UTC (وقت قاعدة البيانات)، مع قراءة لقطة المتصفح المتصل في الجلسة الحالية.  
**النطاق:** تطبيق مشرف التوصيل → `runsheets.deliverer_id` → `delivery_logistics_query(view='agents')` → واجهة النظام الأم.  
**الحالة:** `PRODUCTION DATA/RPC VERIFIED / PUBLISHED DOM DISCREPANCY OBSERVED / AUTHENTICATED UI E2E UNVERIFIED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding — CONFIRMED:** إسناد مندوب لرانشيت هو تكليف تشغيلي؛ ليس إنشاء سجل إداري في `delivery_agents`.
- **Architecture Understanding — CONFIRMED:** تطبيق المشرف يستخدم `delivery_supervisor_assign_deliverer_atomic`. النظام الأم يقرأ عبر `delivery_logistics_query`، ويجب أن يستهلك `runsheet_assignments` منفصلًا عن `rows`.
- **Database Understanding — CONFIRMED:** فحص Production للقراءة فقط أعاد تكليفَي RS-1 وRS-2.
- **Historical Understanding — CONFIRMED:** تمت قراءة `CURRENT_STATE.md` وReport528 ومرجع الحوكمة `MASTER_CTO_GOVERNANCE_CONTINUITY_PROTOCOL.md`. الإصلاح المصدري السابق في `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc` لا ينبغي تكراره بلا دليل جديد.
- **Production Understanding — CONFIRMED:** تعريف `delivery_logistics_query(uuid,text,jsonb,uuid,text)` الحي في Production يعيد `runsheet_assignments`، و`SECURITY DEFINER` مع `search_path=public`. صلاحية EXECUTE متاحة لـ`authenticated` وغير متاحة لـ`anon`.
- **Current Source — CONFIRMED:** Parent blob `0c1745081e8d17480433ed527d77cac9f5292021`؛ Supervisor blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`.
- **Execution Confidence:** مرتفع في عقد البيانات والـRPC؛ غير كافٍ لإثبات عرض واجهة الإنتاج داخل جلسة مصادق عليها.

## 2. أدلة Production الجديدة

في `2026-10-28 13:37:59.723361+00` نفّذ استعلام قراءة فقط باستخدام هوية المالك وسياق الشركة، واستدعى `delivery_logistics_query(company_id,'agents','{}',actor_id,actor_email)`.

النتيجة:
- `success=true`
- `rows=[]` — سجل `delivery_agents` الإداري النشط فارغ.
- `runsheet_assignments` يحتوي:
  - `RS-2`، الاسم «مندوب توصيل 3»، الحالة `Loaded`.
  - `RS-1`، الاسم «مندوب توصيل»، الحالة `Loaded`.
- عدد الرانشيتات المؤهلة والمسندة = 2.
- عدد سجلات `delivery_agents` النشطة = 0.

كما أعيد فحص تعريفَي:
- `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)`
- `delivery_supervisor_assignment_query(uuid,text)`

الأول يشترط جلسة مصادقة، ويتحقق من الشركة وصلاحيات الممثل وأهلية المندوب، ثم يحدّث `runsheets.deliverer_id` فقط، ولا يغير `driver_id` أو `vehicle_id`. وهو يستخدم `operation_id` مع سجل عمليات لمنع التكرار/تعارض إعادة المحاولة. لا يوجد من الدليل الحالي ما يبرر تعديل هذه الدوال.

## 3. فحص صفحة Production المنشورة

قراءة لقطة التبويب المتصل على `https://rawaea-erp.pages.dev/companies/company-1/main` أظهرت:
- نموذج تسجيل الدخول ظاهرًا، والبريد `owner@alrawae.com` موجود، لكن كلمة المرور فارغة.
- محتوى صفحة إدارة التوصيل ظاهرًا خلف حالة الدخول، بما فيه جدول «مناديب التوصيل» الإداري الفارغ.
- لقطة DOM النصية لا تعرض قسم «تعيينات الرانشيت من مشرف التوصيل» الذي يصفه مصدر Git الحالي.

هذه **ملاحظة اختلاف بين لقطة DOM المنشورة ومصدر العقد المتوقع**، لكنها ليست اختبارًا مصادقًا عليه؛ لا يمكن منها وحدها الجزم هل السبب artifact منشور قديم، أم DOM محفوظ/قديم، أم أن مسار رسم القسم لم يعمل. لا تثبت اللقطة نجاح أو فشل الواجهة بعد تسجيل الدخول.

## 4. السبب الجذري: ما ثبت وما لم يثبت

- **CONFIRMED:** تكليفات RS-1 وRS-2 موجودة في Production ويعيدها الـRPC في الحقل الصحيح.
- **CONFIRMED:** سجل `delivery_agents` الإداري كيان منفصل؛ فراغه لا يعني فقد التكليف.
- **CONFIRMED:** الإصلاح المصدري السابق موجود في Git حسب الحالة والتقارير السابقة؛ لم أكرر التعديل.
- **UNVERIFIED:** السبب الدقيق لغياب جدول التكليفات من واجهة مصادق عليها.
- **UNVERIFIED:** تطابق artifact الذي خدمته Cloudflare في هذه اللحظة بايتًا ببايت مع مصدر Git الحالي.
- **UNVERIFIED:** نتيجة HTTP/Network/Console بعد تسجيل دخول طبيعي.

## 5. التغييرات والإجراءات

- لم أعدّل `main.html` أو `supervisor.html` احترامًا لقيد عدم الكتابة عليهما.
- لم أغيّر Production schema أو البيانات أو RPC أو ACL/RLS.
- لم أنشئ Edge Function أو سجلات اختبار أو مندوبين إداريين.
- لم أنشر نسخة جديدة؛ لا توجد أداة Cloudflare deploy متاحة ضمن الأدوات المتصلة، كما أن الدليل لا يحدد بعد هل الخلل من النشر أم من العرض.
- لا يوجد تعديل جراحي جديد مبرر حاليًا. تعديل SQL أو تكرار إصلاح المصدر في هذه المرحلة سيكون تخمينًا ومخاطرة غير لازمة.

## 6. خطوة الحسم المطلوبة من المالك

يلزم إجراء واحد فقط: **افتح صفحة الإنتاج في المتصفح، سجّل الدخول بالطريقة المعتادة، ثم افتح «إدارة التوصيل والشحن → مناديب التوصيل» وأرسل نتيجة واحدة تتضمن هل ظهر قسم «تعيينات الرانشيت من مشرف التوصيل»؛ وإن لم يظهر، أرسل استجابة Network لطلب `delivery_logistics_query` للعرض `agents` مع أول خطأ Console إن وجد.**

لا ترسل كلمة مرور أو رمز جلسة أو مفاتيح سرية. بعد هذه النتيجة يمكن حسم المسار:
- إذا أعادت الاستجابة RS-1 وRS-2 والجدول غائب، يُعزل خطأ DOM/rendering أو artifact.
- إذا غابت التكليفات من الاستجابة، يُراجع الطلب/المعاملات والـRPC الفعلي.
- إذا كان الـartifact المنشور أقدم من المصدر، يلزم نشر المصدر الصحيح ثم إعادة الاختبار.

## 7. SELF-AUDIT FINAL

- **What I Proved:** عقد Production ونتيجة الـRPC وتكليفَي RS-1/RS-2؛ فصل سجل المندوب الإداري عن تكليف الرانشيت؛ قيود صلاحيات الـRPC.
- **What I Did Not Prove:** ظهور الجدول بعد المصادقة، HTTP E2E مصادق عليه، أو تطابق artifact المنشور مع Git.
- **What I Fixed:** لا إصلاح تشغيلي جديد؛ لم يثبت وجود عيب محدد جديد يمكن إصلاحه بأمان دون نتيجة الواجهة المصادق عليها.
- **What I Initially Missed:** يجب عدم تفسير `rows=[]` على أنه فقد التكليفات؛ البيانات التشغيلية موجودة في `runsheet_assignments`.
- **What Could Still Be Wrong:** نشر قديم، DOM/كاش قديم، أو خطأ rendering في جلسة مصادق عليها.
- **Final Confidence:** مرتفع لعقد Production؛ متوسط/غير مكتمل لسبب اختلاف الواجهة.
- **Final Closure Status:** `NOT CLOSED — AUTHENTICATED PUBLISHED UI E2E REQUIRED`.
