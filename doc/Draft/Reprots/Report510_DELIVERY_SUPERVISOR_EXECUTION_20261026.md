# Report510 — تنفيذ عقد إسناد مندوب التوصيل واختبار التكامل
**التاريخ:** 2026-10-26  
**الحالة التنفيذية:** `PARTIAL — STAGING CONTRACT TEST PASS / PRODUCTION NOT DEPLOYED / UI+EDGE CONSUMER PARITY OPEN`  
**Production:** Supabase `fiilmooggumokxanwiyx` (SMART ERP)  
**Staging:** Supabase `hfzznsiprnwkpayskzhu` (rawaea-staging)  
**Operational repository:** `papamohammed77-glitch/erp-frontend`, branch `main`  
**Documentation repository:** `papamohammed77-glitch/rawaie-erp-New`, branch `main`

---

## 1. PRE-CHANGE SELF-AUDIT

| المجال | التقييم المدعوم | الدليل/الحد |
|---|---:|---|
| Business Understanding | 98/100 | العقد يفرق بين سائق المركبة ومندوب التوصيل؛ لا يخلط الدورين. |
| Architecture Understanding | 96/100 | Parent/Fleet يحتفظ بتعيين المركبة والسائق؛ Delivery Supervisor مسؤول عن deliverer_id. |
| Database Understanding | 95/100 | Production schema في تقرير509 أثبتت الأعمدة والعقود؛ Staging schema فُحصت مباشرة أيضًا. |
| Historical Understanding | 91/100 | تمت مراجعة CURRENT_STATE وReport509 والبرومبت التشغيلي ومصدر migration الأساسي. لم تُغلق ancestry لكل Edge/كل migration. |
| Production Synchronization | 97/100 للقراءة؛ 0% لنشر التغيير | قراءة Live جديدة عند 16:42:52 و16:48:34 UTC. Migration غير موجودة في Production عند 16:48:34 UTC. |
| Security/ACL | 90/100 للنطاق الذي عُرف | RPCs الجديدة تقيد Auth UID/company/permissions وتمنع anon؛ لم تُختبر PostgREST JWT E2E. |
| Consumer Trace | 88/100 | مشرف التوصيل وDriver Edge/Parent trace محدد؛ كل consumers غير المباشرين وHTML المنشور لم تُغلق. |
| Execution Confidence | 95/100 لصحة اختبار SQL على Staging؛ 0% لنجاح Production E2E | لا ادعاء Browser/HTTP E2E أو Production closure. |

### الأدلة والحالة
- **CONFIRMED:** Production يحتوي `runsheets.driver_id` و`runsheets.deliverer_id` منفصلين. لا حاجة لإنشاء عمود أو جدول مكرر لإسناد المندوب.
- **CONFIRMED:** `supervisor.html` يقرأ `runsheets/users` مباشرة ويكتب `runsheets.driver_id`; ذلك يخلط دور المندوب بالسائق ويخالف RLS الحالية.
- **CONFIRMED:** `get-driver-dashboard` المنشورة v1 تستعلم عن `users.vehicle_id` رغم أن العمود غير موجود، وتستخدم `activeRS.id` مع أن `id` غير موجود في SELECT؛ لذلك هي معيبة مستقلًا عن واجهة المشرف.
- **CONFIRMED:** Migration جديدة أُضيفت إلى مستودع التوثيق/المصدر المرجعي، وطُبقت على Staging واختبرت ضمن معاملة مع rollback.
- **CONFLICT:** تطبيق المشرف الحالي يسند `driver_id`، بينما عقد المالك يتطلب إسناد مندوب التوصيل عبر `deliverer_id`.
- **UNKNOWN/UNVERIFIED:** Browser/HTTP E2E حقيقي بهوية مستخدم مصادق عليها؛ Cloudflare served-HTML parity؛ Git-to-deployed provenance الكامل.
- **NOT CLOSED:** Production لم يتلقَّ migration أو Edge deploy في هذه الدورة، والواجهة الحالية لم تُحدّث، ولا يزال driver lifecycle يستهلك `driver_id`.

## 2. Live Production Reconciliation

- وقت SQL المباشر: `2026-10-26 16:42:52.200006+00`؛ وقت تأكيد وجود الدوال الجديدة غير المنشورة: `2026-10-26 16:48:34.583217+00`.
- `public.runsheets` يحتوي: `id, company_id, runsheet_code, driver_id, vehicle_id, status, deliverer_id, delivery_start, delivery_end, updated_at`.
- استعلام مباشر عن `delivery_supervisor_assignment_query` و`delivery_supervisor_assign_deliverer_atomic` أعاد **0 rows** في Production؛ هذا يثبت أن Migration الجديدة لم تُنشر هناك.
- تقرير509 وثّق أن RS-1 وRS-2 هما Loaded مع vehicle_id موجود وdriver_id/deliverer_id NULL في snapshot السابق؛ لم تُستخدم هذه الرانشيتات كـfixtures ولم تُعدّل بيانات Production.
- Edge Registry الموثق في Report509: `start-delivery v7`, `complete-delivery v4`, `complete-order-delivery v14`, `get-driver-dashboard v1`, `force-unassign-runsheet v1`, `manage-runsheet v1`; كلها ACTIVE و`verify_jwt=true` في snapshot السابق. لم يُنشر أي Edge جديد في هذه الدورة.

### لماذا لم أنشر Production migration؟
تم إنشاء Migration إضافية آمنة من ناحية التصميم، وتطبيقها واختبارها على Staging. أداة Supabase رفضت طلب `apply_migration` على Production برسالة safety-check، ولم أتجاوز هذا الحاجز بطريقة التفافية. أعدت الاستعلام مباشرةً وتأكدت أن الدالتين غير موجودتين في Production. لم يحدث DDL/DML أو Edge deployment على Production. استمر العمل المستقل على Artifact والاختبارات والتوثيق بدل الادعاء بالنشر.

## 3. Migration Artifact

المسار:
`supabase/migrations/20261026170000_delivery_supervisor_deliverer_assignment_contract.sql`

Commit الذي أضاف الملف:
`40fae5af069094210dce6e0f08a83d5fd442754c`

### ما تضيفه Migration
1. `delivery_supervisor_assignment_query(p_company_id,p_view)`: قراءة محكومة بنطاق الشركة والصلاحية لثلاثة views: `dashboard`, `team`, `runsheets`.
2. `delivery_supervisor_assign_deliverer_atomic(p_company_id,p_runsheet_code,p_deliverer_user_id,p_operation_id)`: تعيين/فك إسناد ذري لمندوب التوصيل على رانشيت `Loaded` فقط.
3. تحقق `auth.uid() → public.users.auth_id` ثم `public.users.id`، والشركة، وحالة المستخدم، والصلاحيات.
4. يتحقق الهدف من نفس الشركة، Active، وصلاحية `delivery`.
5. يقفل الرانشيت `FOR UPDATE`، ويستخدم `erp_operation_registry` لتمييز retry/duplicate وتعارض operation_id.
6. يحدّث `deliverer_id` وحده. لا يغيّر `driver_id`, `vehicle_id`, `status`, `stock_branches`, `allocated_qty`, `inventory_log`، ولا ينشئ قيدًا ماليًا.
7. يسحب EXECUTE من `PUBLIC/anon` ويمنح `authenticated/service_role`.

**لا توجد جداول جديدة في هذه Migration** لأن العقد الحالي يملك `runsheets.deliverer_id` و`erp_operation_registry`. إنشاء جدول مكرر سيزيد تعدد مصادر الحقيقة دون حاجة مثبتة.

## 4. Staging Application + Test Results

Migration طُبقت بنجاح على `rawaea-staging`، ونجح اختبار SQL داخل معاملة تنتهي بـROLLBACK.

| الاختبار | النتيجة | الدليل |
|---|---|---|
| Migration compilation/application | PASS | `apply_migration` أعاد `success:true` على Staging. |
| Company-scoped team query | PASS | الاختبار أعاد المندوب التجريبي داخل الشركة فقط. |
| Company-scoped runsheet query | PASS | ظهر fixture `ZZ-E2E-RS` في شركة الاختبار. |
| Assign Loaded runsheet | PASS | `deliverer_id` أصبح هو مستخدم مندوب الاختبار. |
| Duplicate retry | PASS | نفس `operation_id` أعاد `duplicate=true` دون تكرار الأثر. |
| Wrong-company attempt | PASS | محاولة الشركة الثانية رُفضت. |
| Unassign on Loaded | PASS | عاد `deliverer_id=NULL` فقط. |
| Lifecycle isolation | PASS | `driver_id`, `vehicle_id`, `status='Loaded'` لم تتغير. |
| Fixture cleanup / baseline | PASS | بعد rollback: 0 fixture companies/users/runsheets/operation registry rows. |
| Authenticated PostgREST/Browser E2E | NOT RUN | اختبار SQL يختبر منطق الدوال ولا يثبت مرور HTTP/JWT/UI كاملًا. |
| Concurrent two-session assignment | NOT RUN | لم يُنفذ اختبار جلستين متزامنتين. |
| Production E2E | NOT RUN | Migration غير منشورة وواجهات المستهلك لم تُوائم. |

### تحذير أمني مهم عن Staging
فحص `list_tables` على `rawaea-staging` أظهر 65 جدولًا مع RLS disabled، بما فيها جداول مستخدمين ومخزون وحسابات. لم أفعّل RLS جماعيًا؛ تفعيله دون سياسات مدروسة قد يعطل الوصول المشروع، لكنه **دين أمني حرج يجب أن يُعالج بخطة RLS وسياسات لكل جدول**. لهذا لا تُعد Staging حاليًا ممثلًا صالحًا لاختبار حدود RLS Production، حتى مع نجاح اختبار منطق الدوال.

## 5. Consumer Contract — المطلوب التالي

### Supervisor UI — owner-applied only
الملف: `papamohammed77-glitch/erp-frontend/companies/company-1/delivery/supervisor.html`  
Current blob SHA: `4108d2330e567c432f08197013b9c3cf6221a5c7`

التغييرات اللازمة بعد نشر Migration في Production:
- `renderDashboard`: استبدال القراءة المباشرة من `runsheets/users` باستدعاء `delivery_supervisor_assignment_query` view=`dashboard` و`team`.
- `renderTeam`: قراءة `team` و`runsheets` عبر RPC، وحساب إحصاءات المندوبين باستخدام `runsheets.deliverer_id` بدل `driver_id`. تسمية الواجهة «مناديب التوصيل» بدل «السائقين».
- `openAssignModal`: استهلاك `runsheets` من RPC، ثم تصفية `status='Loaded' AND deliverer_id IS NULL`.
- `assignDriver`: استدعاء `delivery_supervisor_assign_deliverer_atomic` باستخدام `p_operation_id` ثابت لإعادة المحاولة، وعدم الكتابة المباشرة إلى الجدول.
- `unassignDriver`: استدعاء RPC نفسه مع `p_deliverer_user_id=null`؛ لا يغير status ولا يمسح driver_id.
- `renderRunsheets`: استخدام `deliverer_id` للعرض وإسناد التوصيل.
- لا تُطبق تغييرات HTML قبل نشر RPC والتحقق من Consumer contract؛ هذا الملف محجوز لتعديل المالك وفق قواعد البرومبت.

### Driver app and Edge — still open
- `get-driver-dashboard v1`: يجب إصلاح `users.vehicle_id` غير الموجود، وإضافة `id` إلى select، والتحقق من الشركة والصلاحية، واستخدام `deliverer_id` للرانشيت النشط.
- `start-delivery v7`: يجب أن يتحقق من المستخدم عبر `auth_id`، وصلاحية `delivery`، والشركة، و`deliverer_id` وحالة `Loaded` مع انتقال ذري.
- `complete-delivery v4`: يجب أن يتحقق من المندوب المعيّن وحالة `Delivering` والشركة قبل الإكمال.
- `complete-order-delivery v14` وCore atomic RPC: يجب فرض actor/assignment/status داخل المعاملة.
- `force-unassign-runsheet v1`: يجب فرض permission/company scope، وقفل الرانشيت، ومسح `deliverer_id` فقط حسب lifecycle؛ لا يمسح `driver_id`.
- لا تنشأ Edge Functions جديدة. لا تُنشر نسخة متوافقة جزئيًا قد تمنع المندوبين الحاليين من الوصول إلى رانشيتاتهم.

## 6. Loss/Gain/Responsibility Matrix

| المسؤولية | الحالة | السبب |
|---|---|---|
| Parent يحدد المركبة والسائق | RETAINED | `RUNSHEET_ASSIGN → fleet_command_atomic → manage_runsheet_atomic`. |
| Supervisor يحدد مندوب التوصيل | IMPLEMENTED ON STAGING ONLY | RPC جديد مجرّب؛ غير منشور Production. |
| قراءة فريق/رانشيتات تحت صلاحية المشرف | IMPLEMENTED ON STAGING ONLY | RPC read model مجرّب SQL؛ PostgREST RLS E2E لم يُنفذ. |
| تطبيق المندوب يقرأ deliverer_id | MISSING | Edge/driver consumer الحالي يستخدم driver_id. |
| بدء/إكمال الرحلة بالهوية المعيّنة | MISSING | الحواجز لم تُوائم في كل Edge/Core. |
| Company isolation في جميع consumers | PARTIAL | RPC الجديد يحرس الشركة؛ consumers القديمة لم تُغلق. |
| فصل المخزون/المحاسبة عن إسناد المندوب | VERIFIED IN STAGING TEST | اختبار الإسناد لم يغيّر driver/vehicle/status؛ لا حركة مخزون/قيد مالي من هذه الدوال. |
| HTML served parity | UNKNOWN | لم يتم فحص HTML الذي يقدمه Cloudflare. |
| Production end-to-end | NOT STARTED | Migration غير منشورة، UI/Edge parity مفتوحة. |

## 7. Mutation Ledger

- **GitHub:** أُضيف ملف Migration canonical إلى `rawaie-erp-New`، commit `40fae5af069094210dce6e0f08a83d5fd442754c`.
- **Staging:** أُضيفت الدالتان عبر Migration واختُبرتا ببيانات fixtures داخل transaction ثم rollback؛ تحقق الاستعلام اللاحق من أن جميع fixture counts = 0.
- **Production:** لم تتغير schema أو البيانات أو Edge deployments. أداة النشر رفضت طلب Migration، ثم أثبتت القراءة الحية أن الدالتين غير موجودتين.
- **Operational HTML/Core:** لم تُعدّل، التزامًا بالبرومبت الذي يحصر HTML patches بالمالك.
- **RS-1/RS-2:** لم تُستخدم كـfixtures ولم تُعدّل.
- **Inventory/accounting:** لا تغيير.

## 8. Remaining Closure Gates

1. **OPEN — Production migration:** نشر Migration ذات commit المذكور عبر مسار deployment معتمد، ثم التحقق من وجود الدالتين وACL مباشرة من Production.
2. **OPEN — Supervisor HTML patch:** المالك يطبق الرقع الجراحية على SHA الحالي بعد نشر RPC.
3. **OPEN — Edge/Core lifecycle:** إصلاح consumer parity عبر الدوال الموجودة دون إنشاء Edge جديدة.
4. **OPEN — Authenticated HTTP E2E:** assignment → driver dashboard → start delivery → per-order outcomes → complete delivery، مع wrong-company/wrong-deliverer/retry/concurrency.
5. **OPEN — Production baseline:** استخدام fixture معزول فقط؛ عدم لمس RS-1/RS-2؛ إثبات cleanup.
6. **OPEN — RLS Staging:** 65 جدولًا مع RLS disabled؛ يجب تحديد السياسات المناسبة لكل جدول قبل اعتماد Staging كاختبار أمني.
7. **OPEN — Served HTML/provenance:** التحقق من Cloudflare HTML الفعلي وربطه بالـcommit المنشور.

## 9. SELF-AUDIT FINAL

**What I Proved**
- مصدر الخلل في المشرف هو direct reads/writes واستخدام `driver_id` بدل `deliverer_id`.
- أضفت عقدي RPC إلى Migration canonical وطبّقتهما على Staging.
- نجحت اختبارات القراءة، الإسناد، duplicate retry، رفض الشركة الخطأ، فك الإسناد، وعدم تغيير هوية السائق/المركبة/الحالة.
- جميع fixtures أزيلت عبر rollback وثبتت أعدادها صفرًا.
- لم أغيّر Production أو HTML التشغيلية.

**What I Did Not Prove**
- نجاح Browser/HTTP E2E مصادق عليه.
- نشر Migration على Production.
- تكامل تطبيق المندوب مع `deliverer_id` عبر كل Edge/Core.
- Cloudflare served-HTML parity أو Git-to-deployed provenance الكامل.
- نجاح اختبار concurrency بجلسات متعددة.

**What I Fixed**
- أنشأت Migration canonical بعقد قراءة/إسناد آمن، ونشرتها على Staging واختبرتها.
- لم أصلح بعد Consumers/Edge/UI في Production.

**What I Initially Missed**
- لا يكفي إنشاء `deliverer_id`; يجب أن تتغير كل مستهلكات دورة التوصيل بشكل متزامن، مع بقاء Parent مالكًا لـ`driver_id/vehicle_id`.

**What Could Still Be Wrong**
- توافق نوع `permissions` الفعلي مع المستخدمين المعتمدين على role-derived permissions بدل JSON literals.
- PostgREST JWT/ACL/RLS behavior عند استدعاء RPC من Browser.
- Consumers إضافية لـ`driver_id` خارج المجموعة المفحوصة.
- Staging RLS disabled وschema drift من Production.

**Final Confidence:** 94% في عقد RPC المختبر على Staging؛ غير كافٍ لإثبات Production runtime.  
**Final Closure Status:** `PARTIAL — NOT CLOSED`.

**قاعدة للمساعد التالي:** لا تعِد فتح تشخيص الفصل بين driver/deliverer ما لم يظهر دليل جديد. ابدأ من Migration `20261026170000_delivery_supervisor_deliverer_assignment_contract.sql` والـcommit `40fae5af069094210dce6e0f08a83d5fd442754c`. الخطوة الأولى هي نشرها عبر المسار المعتمد ثم تحديث/اختبار كل consumers في Closure Unit واحدة؛ لا تدّعِ Production closure قبل HTTP E2E حقيقي.


## 10. Post-write ACL verification addendum

At `2026-10-26` after the Staging test, the live Staging catalog query returned both signatures:
- `delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text)`
- `delivery_supervisor_assignment_query(uuid,text)`

For both functions, catalog evidence showed:
- `SECURITY DEFINER = true`
- `anon EXECUTE = false`
- `authenticated EXECUTE = true`
- `service_role EXECUTE = true`

This verifies the intended function execution boundary on Staging only. It does not establish Production ACL parity because the functions are absent from Production.
