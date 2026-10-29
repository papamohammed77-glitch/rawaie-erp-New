# Report546 — إصلاح اختفاء الرانشيت في تطبيق مندوب التوصيل

**التاريخ:** 2026-10-29  
**النطاق:** السبب المباشر لاختفاء الرانشيت المسند في تطبيق المندوب، إصلاح استعلامات الواجهة وسياسة القراءة في Production، مع الحفاظ على Company Isolation.  
**الحالة:** `SOURCE FIX COMMITTED + PRODUCTION SELECT POLICY APPLIED/VERIFIED / AUTHENTICATED UI E2E AND SERVED-ARTIFACT IDENTITY UNVERIFIED / NOT CLAIMED 100% CLOSED`

## 1. PRE-CHANGE SELF-AUDIT

- **Business Understanding:** تطبيق المندوب يجب أن يعرض الرانشيت المسند إلى حساب المندوب نفسه، وليس كل رانشيت الشركة.
- **Architecture Understanding:** التطبيق المنفصل `companies/company-1/delivery/driver.html` يقرأ `public.runsheets` مباشرة باستخدام جلسة Supabase، ثم يعتمد على `public.users.id` كهوية التطبيق. مصدر التكليف الفعلي هو `runsheets.deliverer_id`.
- **Database Understanding:** تأكدت مباشرة من أعمدة `runsheets` ومن سياسة RLS الحالية، ومن صف المستخدم والرانشيت في Production.
- **Historical Understanding:** قارنت ملف `erp-frontend/companies/company-1/delivery/driver.html` مع `rawaie-erp-review/PWA/delivery/driver.html`. كلاهما كان يحمل Blob SHA `2df69860184f5a7c1b211ba059e1d6f57826c96b`؛ لذلك الخلل موجود في النسختين قبل الإصلاح.
- **Production Understanding:** فُحصت البيانات وسياسات RLS الحية في مشروع Supabase `fiilmooggumokxanwiyx`.
- **Current Understanding:** تم تعديل ثلاث استعلامات للرانشيت فقط، مع إبقاء استعلامات `driver_liabilities.driver_id` كما هي.
- **Execution Confidence:** مرتفع لسبب الخلل والإصلاح الساكن ووجود سياسة Production؛ لا أصف الإغلاق بأنه 100% لأن authenticated UI E2E وهوية الـartifact المخدوم لم يُثبتا في هذه الجلسة.

### Confirmed Facts

1. الحساب `driver@rawaea.com` نشط، ودوره `مندوب توصيل`، وصلاحياته `["delivery"]`، وشركته `00000000-0000-0000-0000-000000000001`.
2. المفتاح الأساسي للتطبيق `public.users.id` هو `0912a68e-a2d6-4e3a-b44d-41f8826fb900`، و`auth_id` منفصل عنه.
3. الرانشيت `RS-1` حالته `Loaded`، و`runsheets.deliverer_id` يساوي `public.users.id` لحساب المندوب.
4. الرانشيت `RS-2` حالته `Loaded` لكن `deliverer_id IS NULL`؛ لذلك عدم ظهوره لهذا المندوب صحيح ولا يجوز إسناده اصطناعيًا.
5. الاستعلامات الثلاثة في تطبيق المندوب كانت تستخدم `driver_id`، وليس `deliverer_id`.
6. سياسة RLS السابقة `runsheets_select_company` تسمح بالقراءة فقط لمن يملك `runsheets` أو `warehouse`; حساب المندوب يملك `delivery` فقط. لذلك كانت RLS تحجب الرانشيت حتى بعد تصحيح عمود الاستعلام، ما لم يُضف مسار قراءة آمنًا.
7. بعد تطبيق السياسة الجديدة، أعادت قراءة `pg_policies` السياسة `runsheets_select_assigned_delivery` مع `cmd=SELECT` و`roles={authenticated}`، وبشرط الشركة الحالية وهوية `deliverer_id` للمندوب النشط نفسه.
8. اختبار SQL read-only على بيانات Production وجد رانشيتًا نشطًا واحدًا مسندًا إلى `driver@rawaea.com` وفق حالات التطبيق.

## 2. ROOT CAUSE

كان هناك سببان مستقلان ومتراكبان:

### A. Contract mismatch في الواجهة

في `companies/company-1/delivery/driver.html`:

- السطر 172 قبل الإصلاح: `.eq('driver_id', self.pubUserId)`
- السطر 262 قبل الإصلاح: `.eq('driver_id', this.pubUserId)`
- السطر 1076 قبل الإصلاح: `.eq('driver_id', self.pubUserId)`

لكن التكليف الفعلي مخزن في `runsheets.deliverer_id`. حقل `driver_id` ليس بديلًا مضمونًا عن `deliverer_id`، وProduction أثبت هذا الفرق.

### B. RLS permission gap

سياسة `runsheets_select_company` الحالية قبل الإصلاح لا تمنح حساب `delivery` قراءة صفوف الرانشيت. إضافة شرط `deliverer_id` في الواجهة وحده لا تكفي؛ PostgREST سيخضع الاستعلام إلى RLS ويخفي الصفوف غير المسموح بها.

## 3. SURGICAL REPAIR

### 3.1 تطبيق المندوب

تم تغيير ثلاث مراجع فقط من `driver_id` إلى `deliverer_id` في استعلامات جدول `runsheets`:

- فحص إشعار وصول رانشيت جديد.
- تحميل الرانشيت النشط للوحة الرئيسية.
- تجميع رانشيتات الشهر في شاشة الرصيد.

لم تتغير استعلامات `driver_liabilities.driver_id` لأنها تخص هوية السائق في سجل الالتزامات وليست حقل إسناد الرانشيت.

**المستودع:** `papamohammed77-glitch/erp-frontend`  
**الملف:** `companies/company-1/delivery/driver.html`  
**Commit:** `c9eb4ad875d9bc5f1aa48f972d003c036f9b2df8`  
**Blob SHA بعد التعديل:** `dd201d23712619272e6ece120405c9a476a52aaf`  
**الرابط:** https://github.com/papamohammed77-glitch/erp-frontend/blob/main/companies/company-1/delivery/driver.html

### 3.2 Production RLS

أُضيفت سياسة قراءة محدودة للمندوبين:

`runsheets_select_assigned_delivery`

العقد الأمني للسياسة:

- `TO authenticated` فقط.
- الشركة يجب أن تطابق `app_private.current_user_company_id()`.
- يجب أن يملك المستخدم صلاحية `delivery`.
- يجب أن يكون `auth.uid()` مربوطًا بحساب نشط في `public.users` داخل الشركة.
- يجب أن يكون دور الحساب `مندوب توصيل`.
- يجب أن يساوي `runsheets.deliverer_id` مفتاح ذلك المستخدم `public.users.id`.

السياسة للقراءة فقط؛ لم تمنح المندوب صلاحية INSERT/UPDATE/DELETE ولم توسع وصوله إلى رانشيتات زملائه.

**ملف Migration canonical:**  
https://github.com/papamohammed77-glitch/erp-frontend/blob/main/supabase/migrations/20261029_runsheets_select_assigned_delivery_policy.sql

**Commit مصدر Migration:** `bc2a864e56deb1dcca13a1bc4e1ae767818f8197`  
**Production apply:** `success=true` من أداة تطبيق Migration.  
**Post-apply verification:** قراءة مباشرة من `pg_policies` أكدت السياسة وشرط `SELECT` ونطاق `authenticated`.

## 4. VALIDATION MATRIX

| الفحص | النتيجة |
|---|---|
| Live schema: `runsheets.deliverer_id` موجود | VERIFIED |
| Live identity: `users.id` مقابل `users.auth_id` | VERIFIED؛ قيمتان مختلفتان كما هو متوقع |
| Production RS-1 assignment | VERIFIED؛ مخصص لـ`driver@rawaea.com` |
| Production RS-2 assignment | VERIFIED؛ `deliverer_id=NULL`، ولا ينبغي أن يظهر للمندوب |
| Current driver.html source | VERIFIED؛ الاستعلامات الثلاثة تستخدم `deliverer_id` |
| Legacy liability queries | PRESERVED؛ ما زالت تستخدم `driver_id` في `driver_liabilities` |
| RLS policy | APPLIED + LIVE VERIFIED |
| Company/user scope in new policy | VERIFIED by live policy definition |
| Authenticated browser E2E | UNVERIFIED |
| Cloudflare served artifact SHA | UNVERIFIED |
| Browser console/network after sign-in | UNVERIFIED |
| Cross-company negative test with real authenticated session | UNVERIFIED |

## 5. WHAT WAS NOT CHANGED

- لم تُعدّل بيانات الرانشيتات أو تكليفاتها.
- لم تُنشأ بيانات اختبار أو سجل مندوب أو خطة مسار.
- لم تُغيّر صلاحيات الكتابة في `runsheets`.
- لم تُعدّل النظام الأم `main.html`.
- لم تُغيّر حقول `driver_id` في `driver_liabilities`.
- لم يُسند `RS-2` إلى مندوب دون قرار تشغيلي صريح.

## 6. SELF-AUDIT FINAL

- **What I Proved:** حقل الإسناد الخاطئ في التطبيق؛ فجوة RLS التي تمنع دور `delivery` من قراءة الرانشيت؛ وجود RS-1 في Production؛ سلامة سياسة SELECT الجديدة ونطاقها؛ حفظ الإصلاحات في Git.
- **What I Did Not Prove:** أن Cloudflare يخدم بالفعل Blob `dd201d23712619272e6ece120405c9a476a52aaf`، وأن جلسة مندوب مصادق عليها تعرض RS-1 داخل المتصفح بعد التغيير.
- **What I Fixed:** ثلاث استعلامات في تطبيق المندوب وسياسة RLS قراءة محدودة في Production.
- **What I Initially Missed:** إصلاح اسم العمود وحده لا يكفي بسبب سياسة RLS؛ التحقيق الإضافي كشف حاجز القراءة المستقل.
- **What Could Still Be Wrong:** احتمال تأخر/فشل نشر الواجهة أو وجود مشكلة متصفح/جلسة مستقلة. لا يوجد دليل يثبت ذلك حاليًا، لذلك يظل UNVERIFIED.
- **Final Confidence:** مرتفع في Root Cause والإصلاحات المصدرية وRLS؛ متوسط في اكتمال تجربة المستخدم حتى إجراء HTTP/UI E2E.
- **Final Closure Status:** `BACKEND POLICY APPLIED AND VERIFIED + SOURCE COMMITTED / PRODUCTION UI E2E OPEN / NOT 100% CLOSED`.

## 7. NEXT VERIFICATION

افتح رابط التطبيق المنشور، وسجّل الدخول بحساب المندوب المصرح به، ثم نفّذ تحديثًا قويًا/إعادة فتح للتطبيق. المتوقع أن يظهر `RS-1` لحساب `driver@rawaea.com`. إذا بقيت الشاشة فارغة، التقط نتيجة Network لاستعلام `runsheets` وحالة HTTP واسم الخطأ فقط؛ لا تشارك Authorization أو cookies أو مفاتيح سرية. يجب عندها مطابقة Cloudflare served artifact مع Blob SHA أعلاه قبل أي تعديل إضافي.
