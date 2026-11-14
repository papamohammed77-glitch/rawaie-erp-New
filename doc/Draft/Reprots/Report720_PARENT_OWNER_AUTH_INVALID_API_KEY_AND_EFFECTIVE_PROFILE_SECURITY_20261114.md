# Report720 — تشخيص فشل دخول المالك ومفتاح Supabase وتوحيد عقد هوية Parent
**التاريخ:** 2026-11-14 (Africa/Cairo)  
**Last Verified Event:** LVE-2026-11-14-720  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Operational HEAD:** `d7caf2eafd37ecc7777ccd6aa37856c7918b02dd`  
**Target:** `companies/company-1/main.html` + `companies/company-1/core.js`  
**SMART ERP:** `fiilmooggumokxanwiyx`  
**Status:** ROOT CAUSES CONFIRMED; PRECISE CHANGESET PREPARED; IMPLEMENTATION HELD FOR THE SPECIFIC OWNER APPROVAL REQUIRED BY GOVERNANCE §77.2.

> ملاحظة ضبط المصدر: Operational HEAD verified in this event is `d7caf2eafd37ecc7777ccd6aa37856c7918b02dd` (full SHA: `d7caf2eafd37ecc7777ccd6aa37856c7918b02dd`). لا تعتمد هذا الحقل المختصر قبل قراءة Git HEAD مباشرة.

## 1. النتيجة التنفيذية

السجل المرسل لا يدل على أن Core لم يُحمّل أو أن Parent لم يبدأ Boot. الرسائل `core.js loaded`, `Parent and Core share one Supabase client`, `RAWAEA ERP BOOTING` و`SYSTEM READY` تثبت تحميل المكتبات وتنفيذ bootstrap، لكنها لا تثبت وجود جلسة مستخدم صالحة أو اكتمال تحميل ملف المستخدم والصلاحيات.

تم تأكيد أربعة عيوب منفصلة:

1. **P0 — API key mismatch داخل Bootstrap Parent:** عميل Supabase المشترك يُنشأ بمفتاح JWT غير صالح للمشروع؛ بينما المفتاح الصحيح موجود بالفعل في `RW_SUPABASE_ANON_KEY` وفي `core.js`. لأن Core يعيد استخدام عميل Parent، ينتقل المفتاح الخاطئ إلى Auth وRealtime وكل طلبات العميل المشترك.
2. **P1 — Parent يشتق صلاحيات الدخول من user_metadata في مسار استعادة الجلسة:** ويمنح `['*']` افتراضيًا عند غياب قائمة metadata. هذا مسار تفويض غير آمن، ويمكن أن يضع مستخدمًا عاديًا في وضع المالك أو يمنحه كل الصلاحيات عند نقص metadata.
3. **P1 — Parent login يشتق isOwner من wildcard وحده:** لا يستعمل عقد Core الفعّال الكامل الذي يشترط `isOwner` الموثق و`permissions=['*']` ووجود `owner_profile`.
4. **P2 — log-action 401 بعد فشل الدخول:** الكود يحاول تسجيل `failed_login` بلا Authorization token، لكن Edge Function الحالية منشورة مع `verify_jwt=true`. لذلك يرفضها بوابة Edge قبل وصولها إلى فرع `failed_login` داخل الدالة. هذا خطأ تبعي في سجل المحاولات وليس سبب فشل تسجيل الدخول الأساسي.

لا دليل على أن سجل المالك أو حسابه أو رخصته معطل. فشل Auth/Realtime يتفق مع المفتاح غير الصحيح؛ كما أن حساب المالك نفسه نجح في تسجيل الدخول في SMART ERP في 2026-11-14 الساعة 12:34:00 UTC.

## 2. دليل المفتاح غير الصحيح — السبب الجذري المؤكد

### موضع الكود

في `companies/company-1/main.html`:

- سطر 153 داخل Bootstrap الذي يسبق تحميل `core.js` يضع قيمة `key` غير مطابقة لمفتاح المشروع.
- سطر 170 داخل Parent IIFE يعرّف `RW_SUPABASE_ANON_KEY` بالقيمة الصحيحة.
- `companies/company-1/core.js` يستخدم القيمة الصحيحة نفسها.
- `get_publishable_keys` من مشروع SMART ERP أعاد المفتاح legacy anon الصحيح بوصفه enabled، إلى جانب publishable key جديد لا يلزم إدخاله في هذا الإصلاح.

### مقارنة JWT claims

| الحقل | المفتاح في Bootstrap (سطر 153) | المفتاح الصحيح في Parent/Core |
|---|---|---|
| `iss` | `fiilmooggumokxanwiyx` | `supabase` |
| `ref` | غير موجود | `fiilmooggumokxanwiyx` |
| `role` | `anon` | `anon` |
| `iat` | متطابق | متطابق |
| `exp` | متقارب زمنيًا | متقارب زمنيًا |

التوقيع الظاهر للمفتاحين متماثل بينما الـpayload مختلف؛ نسخة Bootstrap ليست JWT anon الصحيحة للمشروع.

**الأثر المباشر:** Parent ينشئ `RW_SUPABASE_CLIENT` مرة واحدة بالمفتاح الخطأ، ثم يضعه في `window.RW_SHARED_SUPABASE`. بعد ذلك يحمل `core.js` ويعيد استخدام نفس العميل. لذلك لا ينشئ Core عميلًا صحيحًا احتياطيًا. هذا يفسر اجتماع:
- `POST /auth/v1/token?grant_type=password → 401`
- Realtime WebSocket `HTTP Authentication failed`
- أخطاء الطلبات التابعة لهذا العميل.

**التصنيف:** CONFIRMED من source + active project key metadata.

## 3. فشل log-action 401 — سبب مستقل وتبعي

في `main.html` داخل `RW_Audit_log()`، إذا كان الإجراء `failed_login` يسمح الكود بإرسال الطلب حتى عندما لا يوجد access token:

- يقرأ `getSession()`.
- يستخرج `token=null`.
- شرط الكود الحالي يسمح بالمرور عند `failed_login`.
- يرسل طلب `POST /functions/v1/log-action` دون `Authorization: Bearer ...`.

في المقابل، SMART ERP يعرض Edge Function `log-action`:
- Version 5.
- Status ACTIVE.
- `verify_jwt=true`.

إذًا ترفض Edge Gateway الطلب قبل تنفيذ فرع `failed_login` في جسم الدالة. ذلك الفرع موجود فعلًا في source/deployment ويستخدم service-role لإدراج سجل فشل مجهول الهوية، لكنه لا يصل إليه الطلب غير الموثق بسبب إعداد التحقق السابق لتنفيذ الدالة.

**المعالجة المقترحة:** عدم إرسال `log-action` عندما لا توجد جلسة/رمز صالح. تظل محاولات Auth الفاشلة مسجلة في سجلات Supabase Auth. لا أوصي بتغيير `verify_jwt` إلى false؛ لأن ذلك يفتح واجهة عامة لكتابة سجلات عبر عميل service-role من داخل الدالة ويحتاج تصميم حماية منفصلًا ضد إساءة الاستخدام.

## 4. مراجعة حساب المالك في SMART ERP — لا يوجد عطل في سجل الهوية

نتيجة SELECT من المشروع `fiilmooggumokxanwiyx`:

| الحقل | القيمة الحالية |
|---|---|
| Auth email | `owner@alrawae.com` |
| الاسم | المالك العام |
| الدور الوظيفي | مدير النظام |
| حالة Public User | Active |
| `public.users.permissions` | `["*"]` |
| `active_warehouse_role` | NULL |
| Owner profile | موجود |
| Owner license | active |
| Email confirmed | نعم |
| banned_until | NULL |
| `auth.users.last_sign_in_at` | 2026-11-14 12:34:00.783353+00 |
| ربط `owner_profile.auth_user_id` مع `auth.users.id` | متطابق |
| ربط `public.users.auth_id` مع `auth.users.id` | متطابق |

المستخدم المطلوب للمالك هو `owner@alrawae.com`؛ لا تستنتج حسابًا آخر من عبارة «المالك العام».

سجلات Auth تحتوي نجاح password login لهذا الحساب عند 12:34:00 UTC في اليوم نفسه. لذلك:
- سجل Auth موجود وغير محظور.
- الربط مع `public.users` و`owner_profile` سليم.
- كلمة المرور نجحت في محاولة سابقة في اليوم نفسه.
- لا يتم تغيير كلمة المرور أو إعادة إنشاء الحساب أو المساس بـ`owner_profile`.

لا أستنتج أن كلمة المرور التي سيُدخلها المستخدم الآن صحيحة؛ فـSupabase Auth لا يكشف ما إذا كان خطأ تسجيل الدخول ناتجًا عن بريد غير موجود أو كلمة مرور غير صحيحة أو طريقة دخول مختلفة. بعد إصلاح API key يجب اختبار الاعتماد الفعلي من شاشة الدخول.

## 5. مراجعة عقد المالك والصلاحيات التاريخي

### العقد المرجعي

التاريخ السابق، ومنها:
- Migration `20260819005000_restore_owner_wildcard_authorization.sql`.
- `Current/CTO/OWNER-RECOVERY-AND-GATE-STATUS-20260818.md`.
- Report252 — Owner License forensic closure.

يثبت أن المالك ليس مجرد مستخدم يحمل النص «مدير النظام». العقد هو:
1. Auth principal صحيح ومؤكد البريد.
2. `raw_user_meta_data.isOwner=true` كجزء من إثبات هوية المالك التاريخي.
3. `public.users.permissions` تحتوي `*`.
4. وجود صف مطابق في `public.owner_profile`.
5. `public.users.auth_id` يطابق `auth.users.id`.
6. الملف نشط.

### العقد الحالي في Core

`public.get_my_effective_profile()` يعيد `isOwner=true` فقط عندما:
- metadata تحمل `isOwner=true`.
- `public.users.permissions` مصفوفة وتحتوي `*`.
- يوجد `owner_profile` مرتبط بـ`auth.uid()`.

Core `RW_Auth` يستهلك هذه القيمة المحسوبة من RPC ويعيد الملف الفعّال، ثم يسمح المالك عبر `checkPermission` من دون الاعتماد على النص الوظيفي.

### الخلل في Parent

مسار تسجيل الدخول المحلي:
- يحسب `isOwner` من `public.users.permissions` wildcard وحده.
- يستخدم `meta.role || 'مدير النظام'` كقيمة عرض افتراضية.
- يقرأ صلاحيات `users.permissions` فقط، ويتجاهل ملف الصلاحيات الفعّال الذي يجمع user/role/role_permissions.

مسار استعادة الجلسة المحلي:
- يضع `isOwner` من `user_metadata` مباشرة.
- يضع `RW_STATE.permissions = meta.permissions || ['*']`.
- يضع `role = meta.role || 'مدير النظام'` لأي مستخدم metadata لديه ناقصة.
- لا يستدعي `get_my_effective_profile()` أو `window.RW_Auth.init()` لاستعادة الملف الموثق.

هذا مخالف لحدود الصلاحيات الحالية:
- الاسم «مدير النظام» لا يجعل المستخدم مالكًا.
- غياب metadata لا يمنح wildcard.
- `user_metadata` لا ينبغي أن تكون المصدر النهائي لصلاحيات المستخدم؛ المصدر الموثوق هو ملف Core الفعّال.
- المالك فقط الذي يجتاز عقد owner_profile + wildcard + isOwner يحصل على مزايا المالك.
- المدير العام ومدير المخازن ومشرف المخازن يظلون أدوارًا وظيفية بصلاحياتهم الصريحة؛ لا يتحولون إلى مالك بسبب تسمية الدور.

## 6. مصفوفة الأدوار الحالية

| الحساب | الدور | حالة الصلاحيات | حدود الدور |
|---|---|---|---|
| `owner@alrawae.com` | مدير النظام | `*` + owner_profile | مالك النظام الحقيقي؛ صلاحيات المالك العامة |
| `general.manager@rawaea.com` | مدير عام | مفاتيح متعددة صريحة بلا `*` | إدارة عامة وفق مفاتيح الدور |
| `warehouse.manager@rawaea.com` | مدير مخازن | مفاتيح المخازن/العمليات صريحة بلا `*` | إدارة مخازن، لا يساوي مالك النظام |
| `warehouse.supervisor@rawaea.com` | مشرف مخازن | مفاتيح عمليات صريحة بلا `*` | إشراف مخازن فقط وفق مفاتيح النظام الأم |
| `storekeeper@rawaea.com` | أمين مخزن | `warehouse` فقط، active role = مخزن شامل | تطبيق المخزن الشامل ونطاق الفروع المعين فقط |
| `picker@rawaea.com` | مخزني / تحضير | دور تشغيل التحضير | Picker وفق دور التحضير |
| `receiver@rawaea.com` | مخزني / استلام | دور تشغيل الاستلام | Receiver وفق دور الاستلام |
| `loader@rawaea.com` | مخزني / تحميل | دور تشغيل التحميل | Loader وفق دور التحميل |
| `returns@rawaea.com` | مخزني / مرتجعات | دور تشغيل المرتجعات | Returns وفق دور المرتجعات |

لا يتطلب هذا الإصلاح تغيير أذونات هذه الحسابات في قاعدة البيانات.

## 7. ChangeSet الجراحي المقترح — CS-AUTH-720-A

**الهدف:** إصلاح bootstrap المفتاح، توحيد مصدر هوية Parent مع Core، منع wildcard الافتراضي، ومنع طلب Audit غير موثق؛ مع إبقاء shell والـnavigation وعمليات الأعمال كما هي.

### A. إصلاح مفتاح العميل — نقطة واحدة

الملف: `companies/company-1/main.html`  
الموضع: Bootstrap قبل `<script src="core.js">`, سطر 153 حاليًا.

التعديل المقترح:
- استبدال قيمة `key` الحالية غير الصحيحة بالمفتاح legacy anon الحالي الصحيح الموجود أصلًا في `RW_SUPABASE_ANON_KEY` و`core.js`.
- عدم تبديل المشروع أو عنوان URL أو إعدادات `persistSession` أو `autoRefreshToken` أو `detectSessionInUrl`.
- عدم إنشاء عميل ثانٍ.
- عدم تغيير core.js؛ مفتاح Core الحالي صحيح.

الأثر المتوقع: Parent وCore وRealtime يستخدمون API key واحدًا صالحًا لنفس مشروع SMART ERP.

### B. جعل Auth profile هو مصدر الصلاحيات — مسار الدخول والاستعادة

الملف: `companies/company-1/main.html`، داخل IIFE الحالي.

التعديل المقترح:
- إضافة helper صغيرة مشتركة لتطبيق normalized user الذي يعيده `window.RW_Auth.init()`.
- في تسجيل الدخول: بعد نجاح `signInWithPassword`، استدعاء `window.RW_Auth.init(callback)` على نفس العميل/الجلسة لتحميل الملف الفعّال؛ لا تسجيل دخول ثانٍ.
- في boot/session restore: الاستعاضة عن قراءة metadata كهوية تفويض باستدعاء `window.RW_Auth.init(callback)`.
- ملء `RW_STATE.app.currentUser` من Core profile: `id, auth_id, company_id, name, email, role, isOwner, permissions, defaultBranchId, allowedBranchIds, activeWarehouseRole`.
- تعيين `RW_STATE.permissions` إلى مصفوفة permissions الفعّالة فقط. عند عدم توفر القائمة تستخدم `[]`، وليس `['*']`.
- `isOwner` لا يساوي wildcard وحده ولا يساوي role text؛ يقبل فقط `coreUser.isOwner === true` الذي أعاده Core بعد التحقق من العقد.
- يبقى `RW_Auth.enterSystem()` المحلي مسؤولًا عن إظهار النظام الأم وبناء القائمة، حتى لا تتغير واجهة النظام أو ترتيب boot.
- metadata تبقى بيانات عرض غير مرجعية عند الحاجة، ولا تقرر permission/owner.

### C. إيقاف طلب audit بلا token

الملف: `companies/company-1/main.html`, `RW_Audit_log()`.

التعديل المقترح:
- عندما تكون نتيجة `getSession()` بلا access token، لا تستدعِ Edge Function لأي action.
- لا تغيّر `verify_jwt=true` في `log-action`.
- تُترك سجلات محاولات Auth الفاشلة لسجلات Supabase Auth، إلى أن يُعتمد تصميم منفصل وآمن لتسجيل فشل الدخول من دون bearer token.

### D. الحفاظ على Tailwind

تحذير CDN مستقل تمامًا عن Auth/Realtime. لا يُحذف CDN في هذا ChangeSet؛ استبداله يتطلب compiled CSS وبوابة بصرية مستقلة، لأن حذف CDN قد يكسر مكونات كثيرة في Parent.

## 8. اختبار القبول قبل الدمج والنشر

### Static / Contract
- تأكيد تطابق قيمة Bootstrap API key مع مفتاح Parent/Core الحالي.
- تأكيد وجود عميل Supabase واحد فقط في Parent.
- عدم وجود `meta.permissions || ['*']` أو أي wildcard default.
- عدم اشتقاق `isOwner` من role text أو wildcard وحده.
- تأكيد استخدام `window.RW_Auth.init()` في login/restore دون sign-in ثانٍ.
- بقاء `log-action verify_jwt=true`.

### Browser E2E باستخدام Mock فقط
1. Owner mock: Core يعيد `isOwner=true` و`permissions=['*']`؛ Parent يدخل ويعرض أقسام المالك.
2. General manager mock: صلاحياته الصريحة فقط؛ لا تظهر صفحات `perm='owner'`.
3. Warehouse manager/supervisor mock: مفاتيح عمليات المخازن فقط، دون owner.
4. Storekeeper mock: `warehouse` فقط و`مخزن شامل`؛ لا يحصل على باقي التطبيقات المستقلة.
5. User metadata ناقصة: لا wildcard ولا Owner، ويظل الوصول وفق Core profile.
6. Missing/invalid Core profile: إغلاق الدخول fail-closed وعدم إظهار shell.
7. Auth failure: لا يرسل `log-action` بلا token؛ لا يظهر 401 audit noise.
8. Auth success: login event يرسل token صالحًا إلى `log-action`، ثم Owner profile يمر إلى Owner navigation.
9. تسجيل الخروج وإعادة الدخول: نفس العميل ونفس session storage، دون تضاعف onAuthStateChange أو Realtime channels.

### Production acceptance بعد النشر
- اختبار Owner الحقيقي من شاشة Parent بالبريد الصحيح `owner@alrawae.com` مع كلمة المرور التي يدخلها المالك بنفسه.
- التحقق من `isOwner=true` و`permissions=['*']` من Core profile، ثم ظهور Owner navigation.
- اختبار General Manager وWarehouse Supervisor وStorekeeper للتأكد من أن حدود أدوارهم لم تتسع.
- التأكد من عدم ظهور Auth/Realtime 401 مع مفتاح API الصحيح.
- لا تنفيذ أي حركة مخزنية أو مالية أثناء هذه الاختبارات.

## 9. الأثر المتوقع وحدود المخاطر

| السطح | الأثر |
|---|---|
| Supabase schema/data | لا تغيير |
| Owner Auth/password | لا reset ولا change ولا revoke |
| users/roles/role_permissions | لا تغيير |
| Stock / Cash / GL / Custody | لا تغيير |
| Auth client | نفس العميل، تصحيح API key فقط |
| Parent boot / login | يستخدم Core profile الموثق بدل metadata |
| Parent nav | تُبنى بالقائمة/permissions الفعّالة الصحيحة |
| Realtime | يزول خطأ API-key auth إذا كان المفتاح وحده السبب؛ تُختبر القنوات بعد الإصلاح |
| Audit | لا anonymous Edge call؛ تبقى verify_jwt=true |
| Tailwind/CSS | بلا تغيير |

### Rollback
- إذا فشل اختبار boot/login في CI، لا يُنشر التغيير.
- إذا ظهر regression بعد النشر، rollback يكون إلى آخر Parent deployment/commit معروف `d7caf2e` كنسخة كاملة، لا بإرجاع أجزاء auth عشوائيًا.
- لا rollback لأي بيانات أو صلاحيات؛ لا توجد DB writes في هذه الحزمة.

## 10. ما تم وما لم يتم في هذا الحدث

**CONFIRMED**
- Source key mismatch.
- Auth and Realtime use the same wrongly initialized shared client.
- Owner account/profile/permissions/owner_profile active and correctly linked.
- Owner successful login earlier on 2026-11-14 12:34 UTC.
- Parent boot restore wildcard fallback and user_metadata-based authorization bug.
- log-action 401 is a no-token call blocked by verify_jwt=true.
- Tailwind warning is unrelated.

**NOT EXECUTED**
- No main.html/core.js code change.
- No Edge Function change or verify_jwt alteration.
- No database write, auth password operation, role mutation, or deployment change.
- No production login attempt was made by this audit.

**Owner approval required:** CS-AUTH-720-A exact changes listed above, before touching `main.html` or deploying.

## 11. Next exact checkpoint

بعد موافقة المالك على ChangeSet:
1. نفّذ A أولًا واختبر Auth/Realtime bootstrap.
2. نفّذ B واختبر Owner/General Manager/Warehouse Supervisor/Storekeeper session restoration and login.
3. نفّذ C واختبر عدم استدعاء log-action بلا token مع بقاء verify_jwt=true.
4. شغّل Mother Assembly Guard وBrowser E2E.
5. راجع source diff للتأكد من محدودية التعديل وعدم تغيير أي عملية تشغيلية.
6. انشر على Cloudflare Production بعد اجتياز الاختبارات.
7. اختبر دخول المالك الحي وكافة الأدوار، دون أي حركات أعمال.

**الحكم:** السبب المباشر لرسالة 401 Auth وRealtime مثبت في مفتاح Bootstrap. سجل المالك في قاعدة البيانات سليم؛ وعيب الاستعادة/الصلاحيات في Parent مثبت ويحتاج إغلاقًا ضمن ChangeSet مستقل محدد. لا يُصنف المالك على أنه مفقود أو موقوف، ولا يعاد إنشاء حسابه.
