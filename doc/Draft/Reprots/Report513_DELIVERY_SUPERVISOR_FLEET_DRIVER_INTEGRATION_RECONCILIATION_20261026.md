# Report513 — تكامل مشرف التوصيل مع الأسطول وهوية السائق ومندوب التوصيل
**تاريخ الفحص:** 2026-10-26  
**Live Production SQL snapshot:** 2026-10-26T17:52:55.553654+00:00 (PostgreSQL 17.6)  
**الحالة:** PARTIAL — Production RPC/ACL and Fleet identity revalidated; driver login provisioning and UI/Edge consumer parity remain OPEN

## 1. PRE-CHANGE SELF-AUDIT

| المجال | التقييم المستند إلى الدليل | الحد |
|---|---:|---|
| فهم الأعمال | 98/100 | ثبت فصل مسؤولية المركبة والسائق عن مسؤولية مندوب التوصيل؛ لم تُغلق بعد دورة التحصيل والمرتجعات والدفتر المالي كاملة. |
| المعمارية | 98/100 | النظام الأم/الأسطول يملك المركبة وrunsheets.driver_id؛ مشرف التوصيل يملك runsheets.deliverer_id. |
| مزامنة Production | 100/100 لقراءة SQL الحية في هذه الجلسة | لا تعني تزامن كل PWA/Edge/Cloudflare أو إغلاق E2E. |
| فهم قاعدة البيانات | 98/100 | أُعيد فحص الأعمدة والعلاقات وRPC definitions/ACL وبيانات سائق الاختبار مباشرة. |
| Consumer tracing | 80/100 | supervisor.html وdriver.html وapp.html معروفة؛ دورة كل Edge/ledger/collection/return لم تُغلق. |
| Runtime verification | 70/100 | دليل SQL مباشر متاح من الفحص السابق؛ لم يُنفذ HTTP JWT أو Browser E2E جديد في هذه الجلسة. |
| الثقة في الإغلاق الكامل | 65/100 | لا يوجد أساس لإعلان CLOSED قبل إصلاح المستهلكين والهوية والتحقق من runtime الحقيقي. |

### Confirmed Facts
- قاعدة Production هي PostgreSQL 17.6؛ آخر قراءة SQL مباشرة في هذه الجلسة كانت 2026-10-26T17:52:55.553654+00:00.
- الدالتان delivery_supervisor_assignment_query(uuid,text) وdelivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text) موجودتان في Production، وكلتاهما SECURITY DEFINER.
- ACL الحي للدالتين: authenticated وservice_role لديهما EXECUTE؛ لا يظهر anon في ACL. هذا لا يغني عن اختبار HTTP/JWT.
- سجل Fleet للسائق التجريبي موجود: fleet_drivers.id=17be00dc-a50b-4daf-94cd-c34687b68182، code D-01، الاسم «سائق مركبة تجربة 1»، البريد driverer@rawaea.com، الحالة Active، وuser_id=NULL.
- لا يوجد سجل مطابق في public.users ولا هوية مطابقة في auth.users للبريد driverer@rawaea.com (العدد الحي = 0).
- المركبتان اللتان ظهرتا في قراءة Production (CHV-2025-01 وVHL-0422) لهما driver_id=NULL وfleet_driver_id=NULL.
- المخطط يحتوي مسبقًا على fleet_drivers.user_id → public.users.id (ON DELETE SET NULL)، وvehicles.fleet_driver_id → fleet_drivers.id، وvehicles.driver_id → public.users.id، وrunsheets.driver_id → public.users.id، وrunsheets.deliverer_id → public.users.id، وerp_operation_registry لعمليات idempotency.
- لا توجد حاجة مثبتة لإنشاء جدول أعمال جديد لهذه العلاقات؛ إنشاء جدول مكرر سيخلق مصدر حقيقة منافسًا.
- سجل الحالة الأخير LVE-2026-10-26-512 ذكر اختبار RPC داخل transaction مع rollback نجح، مع duplicate=true عند retry وبقاء driver_id وvehicle_id وstatus='Loaded' دون تغيير، وresidual_fixture_rows=0. هذا دليل SQL transaction تحت Auth claim محاكى، وليس HTTP/JWT أو browser E2E.
- الـEdge Registry أُعيدت قراءته في الجلسة: get-driver-dashboard v1، start-delivery v7، complete-delivery v4، complete-order-delivery v14، force-unassign-runsheet v1، وsave-employee v10 جميعها ACTIVE وverify_jwt=true.

## 2. Sources / Provenance

المستودع التشغيلي: papamohammed77-glitch/erp-frontend، الفرع main.

| Artifact | Current blob SHA | نتيجة المراجعة |
|---|---|---|
| companies/company-1/delivery/supervisor.html | 4108d2330e567c432f08197013b9c3cf6221a5c7 | ما زال يقرأ runsheets/users مباشرة، ويستخدم driver_id لإسناد مندوب التوصيل وإلغاء إسناده. |
| companies/company-1/delivery/driver.html | 2df69860184f5a7c1b211ba059e1d6f57826c96b | المستهلك الحالي ما زال يعتمد على driver_id في مسارات التوصيل؛ لا يجوز إجراء replace شامل لأن حقل السائق يظل صحيحًا في سياق المركبة. |
| companies/company-1/app.html | ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4 | يوجّه إلى driver PWA عند وجود delivery، ولا يوجد route مثبت مستقل لـvehicle_driver. |
| companies/company-1/core.js | ff2f581d9900543c16f7cb026e13446520c0329d | Core مشترك؛ لم يُعدّل. |
| rawaie-erp-New/supabase/migrations/20261026170000_delivery_supervisor_deliverer_assignment_contract.sql | dff7aada5534c16fdc6394085fc28c67dd4365cd | migration canonical موجودة في Git؛ Production يحتوي الدالتين المطابقتين، كما أعيد التحقق حيًا. |

آخر حالة قبل هذا التقرير: CURRENT_STATE.md — LVE-2026-10-26-512.  
التقرير السابق: Report512_DELIVERY_SUPERVISOR_FLEET_DRIVER_IDENTITY_E2E_20261026.md.  
تقرير التنفيذ السابق: Report511_DELIVERY_SUPERVISOR_INTEGRATION_EXECUTION_20261026.md.  
هذه التقارير مصادر تاريخية فقط؛ أُعيد فحص تعريفات RPC/ACL ومخطط Fleet والهوية وبيانات المركبات في Production في هذه الجلسة. لم تتم مطابقة byte-for-byte بين كل deployed Edge source وGit blob؛ لذلك Git → Production artifact provenance ما زال UNVERIFIED.

## 3. Live Production database findings

### Fleet identity
fleet_drivers هو سجل موظف أسطول وليس حساب Auth. السجل D-01 لا يستطيع تسجيل الدخول لأن user_id فارغ ولا يوجد Auth identity أو public.users profile. لذلك عدم ظهوره في إدارة المستخدمين نتيجة متسقة مع النموذج الحالي، وليس دليلًا على تلف قائمة المستخدمين.

### Identity separation contract
- **Vehicle driver:** سجل fleet_drivers + حساب تطبيق مستقل عند الحاجة + vehicles.fleet_driver_id، وتعيين المركبة/السائق والرانشيت من النظام الأم عبر vehicles.driver_id / runsheets.driver_id وفق العقد الفعلي.
- **Delivery representative:** حساب public.users مؤهل بصلاحية delivery، ويُربط بالرانشيت في runsheets.deliverer_id عبر RPC مشرف التوصيل.
- يمكن للشخص الواحد أداء الوظيفتين إذا منحت الشركة الدورين صراحة، لكن لا يجوز دمج الهوية أو إعادة استخدام driver_id بدل deliverer_id.
- لا يجوز منح delivery لسائق مركبة فقط لمجرد إظهار التطبيق؛ ذلك يمنحه مسار مندوب التوصيل ويخالف مطلب الفصل.

### No new table
العلاقات المطلوبة ممثلة بالفعل في Production. النقص هو provisioning/linking + routing + consumer contract، لا غياب جدول. لم تُنشأ جداول جديدة.

## 4. Responsibility / Loss-Gain Matrix

| المسؤولية | الحالي المثبت | الحالة |
|---|---|---|
| سجل موظف الأسطول | fleet_drivers موجود | RETAINED |
| Auth login للسائق D-01 | لا توجد هوية | MISSING |
| ربط Fleet row بحساب التطبيق | fleet_drivers.user_id=NULL | MISSING |
| تعيين المركبة لسائق الأسطول | vehicles.fleet_driver_id=NULL في المركبات التي فُحصت | NOT ASSIGNED |
| تعيين المركبة/سائق الرانشيت من النظام الأم | حقول قائمة | RETAINED؛ التعيينات الحية للمركبات المفحوصة NULL |
| تعيين مندوب التوصيل | RPC ذري يستخدم deliverer_id | BACKEND CONTRACT PRESENT |
| واجهة المشرف | ما زالت تكتب driver_id مباشرة | CONFLICT |
| تطبيق السائق | ما زال يستهلك driver_id في التوصيل | CONFLICT / REQUIRES ROLE-AWARE TRACE |
| موجه تطبيق الموظفين | لا يوجد route منفصل مثبت لسائق المركبة | MISSING |
| دورة التحصيل/المرتجعات/دفتر السائق | لم تُطابق كاملة في هذه الوحدة | UNKNOWN / OPEN |

## 5. Live Production Edge snapshot

| Edge | Version | Status | verify_jwt | ezbr_sha256 | الفجوة المثبتة |
|---|---:|---|---|---|---|
| get-driver-dashboard | 1 | ACTIVE | true | 59f6bbd39fb8331109966c312fda3327077f17cceda8d9b4b1c9a1c6f652f58e | يطلب users.vehicle_id غير المثبت في schema، ولا يختار runsheet id ثم يستخدم activeRS.id، ويصفّي على driver_id. |
| start-delivery | 7 | ACTIVE | true | 7e87dd0a29d57d3d286c19e05aed70c8b40c7e74645fc73f593e6eee2610399e | مسار التوصيل مربوط بـdriver_id وليس deliverer_id، ويبحث عن المستخدم بالبريد بدل الربط الصريح بـauth_id وفق التقرير السابق. |
| complete-delivery | 4 | ACTIVE | true | 9510e7ef441d3b1256f860c775094c43f5102381488580d99601b26c1b482753 | لا يثبت أن المنفذ هو deliverer_id المعين للرانشيت. |
| complete-order-delivery | 14 | ACTIVE | true | 15c67bde52401897fc0ccc4156670fd5cdc026152617401aabca232c1b046fb2 | Core لا يفرض داخل المعاملة علاقة deliverer_id وحالة Delivering حسب الأدلة السابقة. |
| force-unassign-runsheet | 1 | ACTIVE | true | 4fec814c60d3899ba12b1a6f7af07228a954cf56fe3ce0eb617abdeb8af514b9 | حدود الشركة/الصلاحية غير كافية، ويمسح driver_id بدل deliverer_id. |
| save-employee | 10 | ACTIVE | true | f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75 | ينشئ Auth + public.users لكنه لا يربط سجل fleet_drivers الموجود؛ يحتاج عقد linking مصرحًا ومختبرًا قبل نشره. |

مهم: ezbr_sha256 بصمة نشر Supabase وليست Git SHA. لم أدّعِ byte parity أو provenance كاملًا.

## 6. Root cause

هناك ثلاث طبقات مختلفة تم خلطها:
1. **Fleet master row ≠ login account.** مودال إضافة سائق أنشأ سجل fleet_drivers فقط؛ لم ينشئ Auth user أو public.users profile.
2. **Driver ≠ delivery representative.** التطبيق/الموجه الحالي يفترض عمليًا أن driver_id يمثل الشخص الذي ينفذ التوصيل، بينما العقد المطلوب يفصل deliverer_id.
3. **RPC backend ≠ migrated consumer.** RPC المشرف موجود وصلاحياته متحققة في Production، لكن supervisor.html لم ينتقل لاستهلاكه، ولا تزال Edge/PWA ذات الصلة على العقد القديم.

## 7. Mutation ledger

- Production SQL: قراءة فقط في هذه الجلسة.
- Edge deploy: لم يحدث.
- DDL/DML دائم: لم يحدث.
- Business data / inventory / accounting: لم تتغير.
- Auth user جديد: لم يُنشأ.
- جداول جديدة: لم تُنشأ لأن schema الحالي يكفي.
- Operational HTML/Core: لم يتغير. هذا يتفق مع الوثيقة التشغيلية التي تمنع تعديل ملفات HTML التشغيلية وتطلب رقعًا دقيقة يطبقها المالك بعد إعادة مطابقة SHA.
- اختبارات transaction المذكورة أعلاه هي أدلة Report512 بتاريخ سابق، وليست اختبار HTTP جديدًا في هذه الجلسة.

## 8. الاختبارات

| الاختبار | النتيجة | الدليل/الحد |
|---|---|---|
| Live schema + FK inspection | PASS | قراءة Production في 17:52:55 UTC |
| Fleet test driver identity lookup | PASS — كشف عدم وجود هوية | user_id=NULL, public user rows=0, auth rows=0 |
| RPC definition + ACL | PASS على مستوى SQL catalog | SECURITY DEFINER؛ authenticated/service_role EXECUTE؛ anon غير ممنوح |
| Existing assignment RPC transactional retry/rollback | PASS في Report512 | اختبار SQL transaction سابق؛ ليس HTTP |
| Supervisor UI → RPC contract | FAIL | المصدر الحالي يكتب driver_id مباشرة |
| Driver UI + Edge → deliverer_id lifecycle | FAIL / OPEN | المصادر الحالية ما زالت على driver_id |
| Vehicle-driver login routing | FAIL / OPEN | لا يوجد route vehicle_driver مثبت |
| Authenticated HTTP E2E | NOT RUN | لم يُنفذ في هذه الجلسة |
| Browser E2E + Cloudflare served HTML parity | NOT RUN / UNVERIFIED | لم يتم اختبار النسخة المقدمة للمتصفح |
| Collections / returns / ledger end-to-end | NOT RUN | يجب إكمال consumer tracing قبل اختبار دورة الأعمال |
| Baseline restoration | PASS للـfixture السابق في Report512 | residual fixture rows=0 بعد rollback |
| Full Production closure | NOT CLOSED | المستهلكون والهوية لم يتزامنوا |

## 9. الإصلاح التالي المحدد — دون إنشاء جداول مكررة

1. **Account linking contract:** صمّم/نفّذ مسارًا موثوقًا لإنشاء Auth + public.users عبر save-employee أو التدفق المعتمد، ثم ربط fleet_drivers.user_id=public.users.id في عملية آمنة، مع منع ربط مستخدم من شركة أخرى، ومنع الربط المزدوج غير المقصود، وتسجيل audit/idempotency. لا تنشئ حسابًا بكلمة مرور افتراضية؛ استخدم كلمة مرور يحددها المالك أو تدفق دعوة/إعادة تعيين آمن.
2. **Distinct vehicle-driver permission/router:** أضف permission مستقلة مثل vehicle_driver فقط بعد حسم اسم العقد في roles/permissions والـconsumer mapping؛ أضف route مستقلًا أو شاشة قيادة مركبة مخصصة. لا تستخدم delivery كحل التفافي.
3. **Supervisor PWA:** استبدل direct reads/writes بعقود RPC الحالية، بحيث تُحسب مؤشرات الفريق على deliverer_id وتُسند فقط مناديب مؤهلين، مع handling للأخطاء وduplicate operation IDs.
4. **Driver PWA + Edge + Core:** راجع كل وظيفة ذات صلة. يجب أن يتحدد هل الـactor vehicle driver أم deliverer، ثم تحقق من الهوية المعينة على الخادم. لا تستبدل كل driver_id عالميًا.
5. **Security:** أصلح get-driver-dashboard، enforce assigned deliverer في start/complete delivery، أصلح force-unassign ليعمل على deliverer_id وبنطاق شركة/صلاحيات واضح، ثم طابق Core transactional guards.
6. **Business closeout:** تتبع collections, cash custody, shortages, returns, customer ledger, driver ledger/accounting impacts، ثم اختبر retry/concurrency/wrong-company/wrong-role.
7. **Deployment & E2E:** اختبر Staging، ثم deploy متناسقًا لا يكسر PWA الحالي، ثم HTTP حقيقي بـJWT واختبار Browser/Cloudflare، وأعد فحص baseline وtest residue.

### حدود التفويض الحالية
الوثيقة التشغيلية MASTER_CTO_EXECUTION_PROMPT_LOADER_PICKER_INTEGRATION_20261025.md تمنع تعديل ملفات HTML التشغيلية مباشرة، وتطلب تقديم رقع owner-applied. لذلك لم أعدّل supervisor.html أو driver.html أو app.html، ولم أنشر Edge جزئيًا؛ نشر Backend جديد قبل مزامنة المستهلكين سيخلق عقدًا منقسمًا ويعرّض التشغيل للتعطل.

## 10. SELF-AUDIT FINAL

**What I Proved**
- Production has the necessary relational columns/FKs and two delivery-supervisor RPCs.
- The Fleet test driver is a master row only, without Auth/public user identity or vehicle assignment.
- The live Edge registry still exposes consumers whose contract is driver_id-centric.

**What I Did Not Prove**
- Authenticated HTTP/JWT or browser runtime.
- Cloudflare served HTML equals the current Git blobs.
- Complete financial/collection/returns lifecycle.
- Git blob to deployed Edge byte provenance.

**What I Fixed**
- No production mutation was necessary/safe in this pass; no table was created because the live schema already models the required relationships.
- The diagnosis is now reconciled against a fresh Production snapshot.

**What I Initially Missed**
- The Fleet creation modal’s master record is not a login identity, and no current router route distinguishes vehicle-only driver from delivery representative.

**What Could Still Be Wrong**
- A later browser deployment or unseen consumer may differ from the Git source; full consumer inventory remains open.
- Current user/role configuration may not yet include the final approved vehicle_driver permission.
- Deployed Edge packages have not been byte-reconciled to Git in this report.

**Final Confidence:** 90% for the live schema/identity diagnosis; 65% for overall system integration.  
**Final Closure Status:** PARTIAL — NOT CLOSED. Do not claim 100% until account linking, distinct routing, all consumer contracts, authenticated HTTP E2E, served HTML parity, and business lifecycle tests are completed.
