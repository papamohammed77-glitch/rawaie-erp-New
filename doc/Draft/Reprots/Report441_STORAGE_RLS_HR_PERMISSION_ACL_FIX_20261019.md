# Report441 — إصلاح ACL في سياسات Storage التي تعطل حفظ إعدادات النظام ورفع الشعار — 2026-10-19

## 1. النطاق والقيود

- النطاق: خطأ Production `permission denied for function hr_user_has_permission` أثناء حفظ إعدادات النظام، مع طلب رفع شعار عبر Storage.
- المشروع: Supabase `fiilmooggumokxanwiyx`.
- لم أعدّل `erp-frontend/companies/company-1/main.html`.
- لم أعدّل `erp-frontend/companies/company-1/store/index.html`.
- لم أنشئ Edge Function جديدة، ولم أمنح `anon` أو `authenticated` صلاحية تنفيذ دالة HR العامة.
- المرجع التاريخي الأحدث الذي أمكن إثباته قبل هذه الجلسة: Report440، الذي أصلح أساس المتجر العام في Production، مع إبقاء تعديلات الواجهة على المالك.

## 2. PRE-CHANGE SELF-AUDIT

- Business Understanding: 95/100 — مسار حفظ الإعدادات قد يرفع الشعار أولًا ثم يحفظ رابط الشعار في `app_settings`.
- Architecture Understanding: 96/100 — إعدادات الشركة محفوظة في `app_settings`؛ الملفات في Supabase Storage؛ صلاحيات التخزين محكومة بسياسات RLS.
- Database Understanding: 98/100 — فُحصت سياسات `storage.objects`، ACL للدوال، أعمدة `app_settings`، والمشغلات المرتبطة بها.
- Historical Understanding: 93/100 — تمت مراجعة `CURRENT_STATE.md` وReport440؛ التقرير السابق مرجع تاريخي وليس بديلًا عن Production الحي.
- Production Understanding: 98/100 — تمت قراءة تعريفات الدوال والسياسات وACL الحية قبل التغيير ثم التحقق بعدها.
- Current Source Understanding: 94/100 — فُحص ملف المتجر الحالي وSHA الخاص به، لكن لم يُعدّل أي ملف واجهة.
- Execution Confidence قبل التغيير: 90/100؛ بعد تحقق قاعدة البيانات: 97/100. لا أرفعها إلى 100 لأن HTTP/browser E2E لرفع الملف وحفظ الإعدادات لم يُنفّذ في هذه الجلسة.

### Confirmed Facts

1. `public.hr_user_has_permission(uuid,text)` هي `SECURITY DEFINER`، وACL الحية كانت `postgres/service_role` فقط؛ `authenticated` و`anon` لا يملكان EXECUTE.
2. أربع سياسات Storage الخاصة بمستندات الموظفين كانت تستدعي الدالة العامة مباشرة: SELECT / INSERT / UPDATE / DELETE.
3. `app_private.current_user_has_permission(text)` هي `SECURITY DEFINER`، وتستخدم `auth.uid()` لتحديد المستخدم الحالي، وصلاحية EXECUTE لـ`authenticated` موجودة بالفعل.
4. سياسات `app_settings` الحية تستخدم `app_private.current_user_has_permission('settings')` ولا تستدعي `public.hr_user_has_permission` مباشرة. كما أن مشغلات `app_settings` التي فُحصت لا تستدعي دالة HR العامة.
5. bucket `product-images` موجود وعام للقراءة؛ سياسة إدراج الصور تقيد المستخدم المصادق عليه بصلاحية `items` أو wildcard.
6. بيانات `app_settings` الحالية تتضمن `store_logo` فارغًا ورابط `company_logo` قديمًا/موجودًا. لم أغيّر بيانات الشركة أو رابط الشعار.
7. لم أستطع الحصول على سجل HTTP مفصل من أداة Logs في هذه الجلسة؛ لذلك لا أزعم أن رفع HTTP نجح بعد الإصلاح.

### Unknowns / Conflicts / Unverified

- UNVERIFIED: نجاح رفع شعار فعلي من المتصفح بعد التغيير.
- UNVERIFIED: نجاح حفظ إعدادات النظام كاملةً من واجهة المستخدم بعد الرفع.
- UNVERIFIED: ما إذا كان خطأ 400 المعروض في Console هو الخطأ الوحيد الذي منع عملية الحفظ؛ ربطه بخطأ ACL مرجح بقوة من الرسالة المطابقة وبالسياسات، لكن يلزم اختبار HTTP/Browser لإغلاق ذلك نهائيًا.

## 3. السبب الجذري

سياسات RLS في `storage.objects` تستدعي `public.hr_user_has_permission(u.id,'hr')`، بينما الدالة مقصود أن تبقى غير قابلة للاستدعاء المباشر من `authenticated` و`anon`. عند تقييم سياسات الإدراج/التعديل على جدول Storage، قد يقيّم PostgreSQL تعبير سياسة أخرى ضمن سياسات permissive حتى عندما لا يكون bucket الخاص بها هو الهدف؛ عندئذٍ قد يفشل الطلب بسبب نقص EXECUTE قبل اكتمال فحص السياسات.

لم يكن الإصلاح الصحيح هو منح EXECUTE للدالة العامة، لأن ذلك يوسّع سطح الاستدعاء لدالة HR حساسة. الإصلاح الأقل صلاحية والأضيق نطاقًا هو استبدال الاستدعاء داخل سياسات مستندات الموظفين بـ`app_private.current_user_has_permission('hr')`، مع إبقاء شروط `auth.uid()`، وحالة المستخدم، ونطاق الشركة، وملكية ملف الموظف كما هي.

## 4. التغيير الذي نُفّذ في Production

Migration المسجل في Production:

- Version: `20261018212304`
- Name: `fix_storage_employee_policy_hr_acl_leakage`

تم تعديل السياسات الأربع فقط:

- `employee_docs_storage_select`
- `employee_docs_storage_insert`
- `employee_docs_storage_update` (USING وWITH CHECK)
- `employee_docs_storage_delete`

لم تُغيّر صلاحيات الدالة العامة، ولم تُفتح صلاحية تنفيذ جديدة لـ`anon/authenticated`.

## 5. التحقق بعد التغيير

نجح التحقق المباشر من Production:

- السياسات الأربع تستخدم الآن `app_private.current_user_has_permission('hr')`.
- عدد سياسات Storage التي ما زالت تستدعي `public.hr_user_has_permission` مباشرة: **0**.
- `app_private.current_user_has_permission(text)`: `authenticated EXECUTE = true` و`anon EXECUTE = false`.
- `public.hr_user_has_permission(uuid,text)`: `authenticated EXECUTE = false` و`anon EXECUTE = false` — بقيت حدود الصلاحيات كما ينبغي.
- سياسات `app_settings` بقيت كما هي؛ لم يتم توسيع صلاحيات الجداول.
- لم تُنشأ بيانات تجريبية ولم تُغيّر بيانات الأعمال.

## 6. أثر التغيير

- يزيل سبب ACL المؤكد داخل سياسات Storage من دون كشف دالة HR العامة.
- يحافظ على قيد الشركة وعلى وصول موظف الموارد البشرية/الموظف صاحب الملف وفق السياسة الحالية.
- لا يغيّر منطق حفظ إعدادات النظام أو واجهة المتجر.
- لا يثبت وحده نجاح HTTP upload أو حفظ الإعدادات من المتصفح؛ يلزم اختبار حقيقي أخير.

## 7. ملفات المصدر والتوثيق

- Migration في المستودع: `supabase/migrations/20261018212304_fix_storage_employee_policy_hr_acl_leakage.sql`
- Commit إضافة migration: `3016d4db7d1ee2fad7f33061163d5e8f0775fe22`
- `main.html` و`store/index.html`: لم يتم تعديلهما.

## 8. اختبار الإغلاق المطلوب من المالك

1. افتح النظام الأم بحساب مصادق عليه لديه صلاحية إعدادات.
2. غيّر الشعار إلى ملف صورة صالح، ثم احفظ إعدادات النظام.
3. تحقق من أن طلب Storage إلى `/storage/v1/object/product-images/store-logos/...` يعيد 2xx، وأن سجل `app_settings.store_logo` أو الحقل الذي تستخدمه الواجهة يُحدّث بالرابط الصحيح.
4. أعد فتح الإعدادات وتحقق من ظهور الشعار بعد إعادة التحميل.
5. افحص Console/Network؛ يجب ألا يظهر `permission denied for function hr_user_has_permission`.
6. نفّذ اختبارًا مستقلًا لمستند موظف: مستخدم HR مصرح له، وموظف يصل إلى ملفه فقط، ومستخدم غير مصرح به لا يستطيع قراءة ملفات موظفين آخرين.
7. إذا بقي 400 بعد اختفاء خطأ ACL، سجّل استجابة HTTP كاملة (status + response body + request path)؛ افحص حينها قيود MIME/الحجم أو مسار التخزين بدل تغيير ACL مرة أخرى.

## 9. SELF-AUDIT FINAL

- What I Proved: ACL الحية، السياسات السابقة، استبدال الاستدعاء في السياسات الأربع، وبقاء الدالة العامة غير متاحة لـ`authenticated/anon`.
- What I Did Not Prove: نجاح HTTP upload وحفظ الإعدادات من المتصفح بعد التغيير.
- What I Fixed: سبب ACL في سياسات Storage التي كانت تستدعي دالة HR العامة.
- What I Initially Missed: التمييز بين فشل رفع الشعار وفشل UPDATE في `app_settings`؛ المشغلات والسياسات الحية لا تثبت أن UPDATE نفسه هو مصدر خطأ HR.
- What Could Still Be Wrong: قد يبقى سبب ثانٍ مستقل لرد 400، ويجب تشخيصه من Response Body إذا استمر.
- Final Confidence: 97/100 على إصلاح قاعدة البيانات؛ HTTP/browser verification ما زال غير منفذ.
- Final Closure Status: `PRODUCTION ACL REPAIR APPLIED + DB VERIFIED / HTTP E2E OPEN / NOT CLAIMED 100% CLOSED`.
