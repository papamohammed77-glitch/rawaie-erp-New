# Report534 — مراجعة RAWAEA اليومية: مطابقة مصدر النظام الأم مع عقد Production وبوابة Runtime المفتوحة

**وقت الفحص الحي:** 2026-10-28T18:57:09.323176Z (UTC، من ساعة PostgreSQL)  
**النطاق:** Delivery Supervisor → `runsheets.deliverer_id` → `delivery_logistics_query(view='agents')` → Parent `main.html` المنشور.  
**سياسة التغيير:** قراءة فقط في Production؛ لم يتغير أي ملف تشغيلي أو بيانات أعمال أو صلاحيات أو نشر.

## 1. نقطة البداية والاستمرارية

- أُعيد جلب وقراءة `CURRENT_STATE.md` كاملًا قبل بقية الفحوصات. Blob الحالي عند بدء المراجعة: `24887a300a2a3fb4fc9d76ef0352000fa0d99d04`، 410,347 حرفًا / 2,478 سطرًا.
- آخر حدث عند بدء المراجعة: `LVE-2026-10-28-533`، Report533.
- قُرئ مرجع الحوكمة الحالي كاملًا: `MASTER_CTO_GOVERNANCE_CONTINUITY_PROTOCOL.md`, blob `54f61542694f3d98925b43752a98b7f59a56c31f`, 66,798 حرفًا / 1,412 سطرًا.
- قُرئت تقارير 533 و532 و531. اتفقت على أن بوابة الإغلاق الوحيدة المتبقية هي إثبات العرض في جلسة Parent منشورة ومصادق عليها حديثًا؛ لا إعادة لتعديل المصدر أو RPC دون دليل جديد.

## 2. CONFIRMED — GitHub / SOURCE

المستودع التشغيلي هو `papamohammed77-glitch/erp-frontend`, الفرع الافتراضي `main`.

- أحدث commit ظهر في سجل commits هو `8843150bdde99d36d477d6bb344a24df61dd2942`، ورسالة commit توضح أنه تحديث توثيقي لـ`CURRENT_STATE.md`.
- Commit إصلاح العرض: [`cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`](https://github.com/papamohammed77-glitch/erp-frontend/commit/cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc).
- Commit Migration: [`41475240d2685cb7a7919e372e1e9ba10539f3e6`](https://github.com/papamohammed77-glitch/erp-frontend/commit/41475240d2685cb7a7919e372e1e9ba10539f3e6).
- مقارنة commit الإصلاح مع `8843150bdde99d36d477d6bb344a24df61dd2942` تؤكد أن `main` متقدم بخمسة commits. الملفات التي تظهر في المقارنة هي `CURRENT_STATE.md` و`_forensic_current_main_extract.md` وتقرير الإغلاق؛ لم يظهر `main.html` أو `supervisor.html` ضمن تغييرات ما بعد الإصلاح.
- Parent `companies/company-1/main.html`: blob `0c1745081e8d17480433ed527d77cac9f5292021`, 1,788,467 حرفًا / 33,154 سطرًا.
- Supervisor `companies/company-1/delivery/supervisor.html`: blob `3e6db903cd7da411f9ed40a449f9ee5bece5f387`, 25,597 حرفًا / 307 أسطر.
- Migration المصدرية `supabase/migrations/20261027_delivery_supervisor_parent_runsheet_assignments.sql`: blob `d3eed778670833ed84d68f765e336fbb7c3db3e9`.

### تتبع المستهلك

- في Parent، الدالة `q(view,payload)` عند السطور 30513–30522 تستدعي `delivery_logistics_query` وتعيد `r.data` بعد التحقق من الخطأ.
- `agents()` عند السطور 30668–30697 تقرأ `d.runsheet_assignments` كمصفوفة، وتبني جدول «تعيينات الرانشيت من مشرف التوصيل» منفصلًا عن جدول `delivery_agents`.
- لا يوجد دليل مصدر جديد يبرر تكرار patch `cb62612...` أو تعديل `supervisor.html`.

**CI:** أعادت أداة GitHub حالات combined-status فارغة للـrepair commit و`229dff...` و`8843150...`. هذا يعني أنه لم تُرجع حالات status عبر هذه الواجهة، وليس إثباتًا لنجاح CI أو فشله، ولا دليل نشر.

## 3. CONFIRMED — Supabase Production

المشروع `SMART ERP`, ref `fiilmooggumokxanwiyx`, حالته `ACTIVE_HEALTHY`; PostgreSQL `17.6.1.121`.

### مطابقة Migration مع الدالة الحية

- سجل Migrations الحي يحتوي `20261027170454 / delivery_supervisor_parent_runsheet_assignments`.
- تعريف `public.delivery_logistics_query(uuid,text,jsonb,uuid,text)` جُلب مباشرة من Production.
- بعد استخراج جسم الدالة وتطبيع المسافات البيضاء، تطابق جسم Production مع جسم Migration الحالي **تطابقًا كاملًا**: `normalized_body_match=true`، 14,232 حرفًا بعد التطبيع.
- الدالة `SECURITY DEFINER`, `search_path=public`, والـACL الحي هو `postgres`, `authenticated`, `service_role`؛ لا يظهر منح EXECUTE إلى `anon` أو `PUBLIC`.
- الدالتان `delivery_supervisor_assignment_query(uuid,text)` و`delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)` موجودتان أيضًا كـ`SECURITY DEFINER`, مع `search_path=public, pg_temp`، وEXECUTE لـ`authenticated/service_role` دون `anon`.
- تعريف دالة الإسناد يتحقق من `auth.uid()`, الشركة، صلاحية المشرف، أهلية المستخدم الهدف، `operation_id` ومن حالة `Loaded`؛ التحديث المستهدف هو `runsheets.deliverer_id`. لم تُنفذ عملية إسناد في هذه المراجعة.
- RLS مفعّل على `runsheets`, `users`, `delivery_agents`. عدد سياسات الجداول كما قُرئ مباشرة: `runsheets=4`, `users=5`, `delivery_agents=0`; و`FORCE ROW LEVEL SECURITY=false` لهذه الجداول. لا أعتبر غياب سياسة مباشرة على `delivery_agents` سببًا مثبتًا للمشكلة؛ مسار Parent يقرأ عبر RPC المصادق عليها ذات فحوص الشركة والصلاحية.

### لقطة البيانات الحية

استعلام قراءة فقط عند `2026-10-28T18:57:09.323176+00:00` أكد:

| السجل | الحالة | `deliverer_id` |
|---|---|---|
| RS-1 | `Loaded` | موجود |
| RS-2 | `Loaded` | موجود |

- عدد سجلات `delivery_agents` للشركة `00000000-0000-0000-0000-000000000001` = `0`.
- لا يثبت هذا العدد فقد الإسناد؛ فالإسناد الفعلي محفوظ في `runsheets.deliverer_id` ويُعاد ضمن `runsheet_assignments`، بينما `rows` مخصص لسجل المندوبين الإداري.
- لم تتغير أي بيانات أو حالة رانشيت أو مخزون أو قيود مالية.

## 4. سجلات التشغيل — دليل محدود

أظهرت سجلات Supabase خلال نافذة الفحص طلبات `POST` مصادقًا عليها إلى `/rest/v1/rpc/delivery_logistics_query` من مرجع `https://rawaea-erp.pages.dev/`، مع HTTP 200؛ أحدث وقت ظاهر في نتيجة السجلات كان `2026-10-28T16:25:58.712Z`.

**حد الدليل:** السجلات لا تكشف جسم الاستجابة، ولذلك لا تثبت أن المتصفح استلم `runsheet_assignments` أو أن الجدول رُسم في DOM.

## 5. UNKNOWN / UNVERIFIED — Deployment وRuntime

حاولت الوصول إلى صفحة Parent المنشورة عبر أداة الويب، وإلى طلب HTTP مباشر عبر بيئة التنفيذ؛ تعذر جلب الصفحة (الأداة لا تتيح العنوان، ومحاولة HTTP فشلت في حل DNS). كما رفض Browser connector الوصول لعدم وجود سياق متصفح أصلي متصل. لا توجد أداة Cloudflare مباشرة ضمن الأدوات المتاحة في هذه الجولة.

لذلك لا أستطيع إثبات:
- HTML/JS الذي يقدمه Cloudflare حاليًا أو SHA/commit الخاص بالـartifact المخدوم.
- headers/cache أو lineage مباشر من Deployment إلى Git.
- جلسة مصادق عليها حديثة بعد تسجيل الدخول/التحديث.
- body طلب `delivery_logistics_query(p_view='agents')` في المتصفح.
- DOM النهائي أو أول خطأ Console/Network.

لقطة DOM القديمة المذكورة في التقارير السابقة تُظهر login overlay، ولذلك لا تُعامل كاختبار E2E حديث ولا كدليل حاسم على عيب حالي.

## 6. CONFLICT

**لا يوجد تعارض حالي مثبت بين Source وProduction RPC/Migration.** بل إن التطابق المباشر لجسم الدالة الحية مع Migration ينفي انحراف جسم هذه الدالة عن ملف Migration الحالي.

يبقى الفرق التاريخي بين المصدر/عقد البيانات وبين لقطة DOM القديمة غير حاسم؛ لأن اللقطة قديمة وتعرض شاشة الدخول، ولم يُنفذ اختبار مصادق عليه حديثًا.

## 7. مصفوفة الاختبار

| الطبقة | النتيجة | ما تثبته / ما لا تثبته |
|---|---|---|
| GitHub HEAD / ancestry | PASS ضمن حدود الواجهة | الإصلاح موجود في التاريخ الحالي؛ commits اللاحقة الظاهرة توثيقية، لا يثبت ذلك النشر |
| Parent source path | PASS بالفحص الساكن للمقطع | `q()` يعيد `r.data` و`agents()` يستهلك `runsheet_assignments`; ليس اختبار Runtime |
| Production schema / RPC / ACL | PASS | الدوال والـACL والإعدادات قُرئت مباشرة |
| Migration body ↔ Production body | PASS | تطابق جسم `delivery_logistics_query` بعد تطبيع whitespace |
| Live business data | PASS للقراءة فقط | RS-1/RS-2 Loaded ومُسندان؛ `delivery_agents=0` |
| Supabase request logs | PARTIAL | HTTP 200 مصادق عليه؛ body غير متاح |
| Deployed artifact / headers | NOT RUN / UNVERIFIED | تعذر الوصول المباشر |
| Authenticated browser E2E / Console / Network | BLOCKED / NOT RUN | لا يوجد سياق متصفح تفاعلي متاح |
| Business-data side effects | PASS / NONE | لم تُكتب أو تُعدّل أي بيانات أعمال |

## 8. القرار التنفيذي

لا أعدّل `main.html` أو `supervisor.html`، ولا أعيد تطبيق Migration، ولا أغيّر RPC/ACL/RLS، ولا أرفع Service Worker version. الدليل الحالي يثبت اتساق المصدر والعقد والبيانات، ولا يعزل عيبًا جديدًا يستحق تغييرًا تشغيليًا.

**الحالة:** `SOURCE + PRODUCTION RPC/MIGRATION PARITY CONFIRMED / PUBLISHED AUTHENTICATED UI E2E UNVERIFIED / NOT CLOSED`.

## 9. الخطوة التالية الوحيدة ذات الأولوية

في جلسة Parent منشورة ومصادق عليها حديثًا، افتح «مركز التوصيل واللوجستيات → مناديب التوصيل» والتقط:
1. استجابة `delivery_logistics_query` لعرض `agents` بعد حجب Authorization وأي بيانات شخصية.
2. وجود RS-1 وRS-2 داخل `runsheet_assignments`.
3. وجود جدول «تعيينات الرانشيت من مشرف التوصيل» في DOM.
4. أول خطأ Console إذا كانت الاستجابة تحتوي الصفين والجدول غائبًا.

بعد ذلك فقط يُختار الإصلاح حسب الطبقة المثبتة: caller/contract إذا غابت الصفوف من payload، أو rendering إذا وصلت الصفوف ولم تُعرض، أو نشر إذا ثبت أن artifact المخدوم أقدم. لا تشارك كلمات مرور أو cookies أو JWTs أو session tokens.
