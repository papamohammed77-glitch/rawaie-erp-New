# Report421 — تحقيق خطأ POS pos_get_shift_summary / Production ACL & Session Contract

**التاريخ:** 2026-10-18 UTC  
**النطاق:** خطأ RPC في نقطة البيع فقط. لم يتم تعديل `main.html` أو `pos.html` أو `core.js`. لم يتم تعديل بيانات Production.

## PRE-CHANGE SELF-AUDIT

- **Business:** `pos_get_shift_summary` يعرض ملخص وردية الكاشير، ويتضمن النقد المتوقع والمبيعات والمرتجعات والعد النقدي؛ بيانات مالية حساسة.
- **Architecture:** `pos.html` يستدعي RPC مباشرة عبر Supabase client المشترك في `core.js`. لا يلزم Edge Function جديد.
- **Database:** الدالة `public.pos_get_shift_summary(p_shift_id uuid)` موجودة في Production، وهي `SECURITY DEFINER` وتتحقق داخل جسمها من `auth.uid()` وصلاحية `pos` وهوية الشركة والمستخدم النشط، وتقيّد رؤية الورديات الأخرى.
- **Historical/Current Source:** فُحص المصدر الحالي لـ `erp-frontend/companies/company-1/sales/pos.html` (blob SHA `b09320129dd04a833d1304a76fee0768ab7c52a3`) والمصدر المشترك `companies/company-1/core.js` (blob SHA `c2e0a7f4ba11f44c11dfc4728ef4a1af1b256b81`). لم يُجرَ تعديل على أي منهما.
- **Production:** فحص SQL مباشر في 2026-10-18 19:34:25 UTC أثبت وجود الدالة، وأن `authenticated` لديه EXECUTE، و`anon` لا يملكه. سجلات PostgreSQL الحديثة في 19:33:40–19:33:55 UTC أثبتت تكرار `permission denied for function pos_get_shift_summary` من PostgREST.
- **Execution confidence:** مرتفع في إثبات العطل وسلامة منع الوصول المجهول؛ غير كافٍ لتحديد سبب نهائي واحد قبل التقاط JWT role الفعلي من طلب المتصفح/اختبار HTTP مصادق.

## الأدلة الحالية

1. تعريف الدالة يتضمن:
   - رفض الجلسة غير المصادق عليها عبر `auth.uid() IS NULL`.
   - `app_private.current_user_has_permission('pos')`.
   - تقييد المستخدم النشط والشركة والوردية.
   - استدعاء `public.pos_shift_expected_cash(v_shift.id)`.
2. ACL الحالي:
   - `authenticated EXECUTE = true`
   - `anon EXECUTE = false`
   - `public.pos_get_shift_summary(uuid)` واحدة فقط ظهرت في الفحص.
3. `pos_shift_expected_cash(uuid)` لا يمنح EXECUTE إلى authenticated، لكنه يُستدعى داخل الدالة SECURITY DEFINER بصلاحية مالك الدالة؛ لا يوجد دليل يبرر منحه مباشرة إلى العميل.
4. `pos.html` يستدعي `loadShiftState()` في `_setupUser(user)` بعد نجاح `RW_Auth.init`/تحميل الملف الفعال، لكن الدالة لا تتحقق محليًا من وجود جلسة Supabase صالحة مباشرة قبل RPC.
5. لأن ACL الحالي يمنع anon ويمنح authenticated، فإن منح EXECUTE إلى anon ليس إصلاحًا آمنًا، وقد يعرّض نقطة RPC المالية لمحاولات وصول مجهولة. لم يُجرَ هذا المنح.
6. التحذير الخاص بـ Tailwind CDN و404 لـ favicon لا يفسران خطأ RPC الحالي.

## Root-cause status

**المثبت:** طلبات RPC فشلت بصلاحية تنفيذ، رغم أن ACL الحالي يمنح EXECUTE لـ authenticated.  
**غير المثبت بعد:** هل الطلب الفاشل وصل بدور JWT = anon بسبب غياب/انتهاء الجلسة، أم أن هناك اختلافًا بين حالة ACL وقت الطلب وحالتها وقت الاستعلام، أم مشكلة أخرى في مسار الطلب. سجل Postgres يعرض مستخدم اتصال PostgREST `authenticator` ولا يكشف وحده الدور النهائي المستخرج من JWT؛ لذلك لا أدّعي أن السبب الجذري حُسم.

## قرار Production

لم تُجرَ أي تغييرات DDL/ACL لأن المنح الصحيح لـ authenticated موجود بالفعل، والمنح إلى anon سيكون تخفيضًا أمنيًا. لا حاجة إلى Edge Function جديدة.

## التعديل الجراحي المقترح للمالك — المصدر فقط

- **الملف:** `erp-frontend/companies/company-1/sales/pos.html`
- **الدالة:** `self.loadShiftState = function(callback) {`
- **محدد البحث:** ابحث عن السطر الحرفي `self.loadShiftState = function(callback) {` ثم عن أول شرط داخله الذي يبدأ بـ `if (!currentUser || typeof supabase === 'undefined'`.
- **التغيير المطلوب:** قبل تنفيذ `supabase.rpc('pos_get_shift_summary', ...)` اجعل المسار يتحقق من `supabase.auth.getSession()`، وألا يرسل RPC إذا لم توجد `session` أو `session.user.id`؛ عند غياب الجلسة، يمسح حالة الوردية محليًا ويعيد `callback(false)` دون استدعاء RPC. عند وجود جلسة صالحة فقط، ينفذ الاستدعاء الحالي كما هو. يجب الحفاظ على معالجة الخطأ الحالية وعدم إظهار بيانات مالية من cache عند فقد الجلسة.
- **مهم:** لا أقدم هنا استبدالًا كاملًا للدالة؛ لأن التعديل داخلها يحتاج مطابقة بقية جسمها كاملًا قبل إنتاج بديل آمن، ولأن سياسة المشروع تمنعني من تعديل التطبيق مباشرة. التعديل لم يُطبق.
- **اختبار بعد التطبيق:** (1) مستخدم مصادق لديه صلاحية POS: RPC ناجح. (2) جلسة مفقودة/منتهية: لا يُرسل RPC مجهول، وتظهر حالة غير مصادق/إعادة تسجيل الدخول. (3) مستخدم بلا صلاحية POS: رفض آمن. (4) مستخدم شركة أخرى/وردية أخرى: رفض آمن. (5) راقب PostgreSQL logs للتأكد من اختفاء permission denied، ثم نفذ HTTP E2E بجلسة حقيقية.

## ما لم يُثبت

- لم يتم تنفيذ HTTP E2E مصادق من أداة هذه الجلسة.
- لم يتم إثبات JWT role للطلبات الفاشلة.
- لم يتم تغيير Production أو بيانات الأعمال.
- لم يتم الادعاء بأن المشكلة أُغلقت.

## SELF-AUDIT FINAL

- **What I Proved:** الدالة وتعريفها وACL الحالي؛ تكرار خطأ permission denied في Production logs؛ مصدر استدعاء RPC في POS.
- **What I Did Not Prove:** الدور الفعلي للـJWT في الطلبات الفاشلة، أو نجاح المسار بعد إصلاح المصدر.
- **What I Fixed:** لا تعديل Production مطلوب وفق ACL الحالي؛ لم أنفذ تغييرات غير مبررة.
- **What I Initially Missed:** وجود EXECUTE بالفعل لـ authenticated؛ لذلك لا يصح افتراض أن الحل هو GRANT جديد أو منح anon.
- **What Could Still Be Wrong:** قد تكون المشكلة في الجلسة/الـJWT أو في اختلاف لحظي في ACL وقت الطلب؛ يجب التقاط طلب حقيقي والتحقق من session role.
- **Final Confidence:** مرتفع في ACL والتشخيص الأمني، متوسط في تحديد السبب الجذري النهائي.
- **Final Closure Status:** OPEN — يحتاج اختبار HTTP مصادق وتحقق من الدور الفعلي قبل الإغلاق.
