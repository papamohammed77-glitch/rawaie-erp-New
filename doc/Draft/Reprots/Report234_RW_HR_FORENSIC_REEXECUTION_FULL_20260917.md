# RAWAEA ERP — RW_HR إعادة التنفيذ الجنائي الكامل وإغلاق عقد الموارد البشرية
## التقرير التنفيذي الكامل — 2026-09-17

> **نطاق التقرير:** تبويب الموارد البشرية `RW_HR` فقط.
>
> **قاعدة العمل:** لا تُعامل التقارير السابقة كحالة حالية. الحالة المعتمدة هي ما تم إثباته من `CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`.
>
> **قيد حاكم:** لم يتم تعديل `erp-frontend/companies/company-1/main.html` في هذه الجلسة، والتعديل الجراحي الجاهز محفوظ كملف مستقل.

---

# 1. نتيجة التقرير

الحالة الحالية ليست "تصميم HR يحتاج أفكارًا"، بل نظام HR له Core حديث موجود في Production، ومصدر Mother قديم لم ينتقل إليه بعد.

تم في هذه الجلسة إعادة التحقيق من الحالة المثبتة، ثم تنفيذ Hardening فعلي على Production، وإعادة مطابقة المصدر الحالي مع Core، وإعادة فحص طبقة القراءة والصلاحيات، وإعادة صياغة نقطة التسليم للجلسة التالية.

## الحالة النهائية المثبتة في نهاية الجلسة

```text
Production HR Core                    = PRESENT + HARDENED
hr_command_atomic                    = canonical write engine
hr_query                             = canonical read engine
Modern HR direct DML via client      = CLOSED
Anonymous HR Core table DML           = CLOSED
Legacy HR RPC execution              = PRESERVED for compatibility until Mother cutover
Mother RW_HR current source          = LEGACY / NOT CUT OVER
Surgical replacement                 = READY
Mother main.html                     = UNTOUCHED
HR browser authenticated E2E         = OPEN
Production DB-level authenticated QA = PASS for exercised boundaries
HR business data                     = 0 records / no fabricated seed
Overall RW_HR Mother                 = NOT CLOSED YET
```

**لا يجوز تحويل الحالة الأخيرة إلى `100% CLOSED` قبل تنفيذ browser E2E حقيقي بجلسة مستخدم Authenticated على Mother نفسها.**

---

# 2. مصادر الحقيقة التي تم تثبيتها

## 2.1 System Repository

المستودع:

`papamohammed77-glitch/rawaie-erp-New`

أحدث HEAD أثناء إعادة التنفيذ:

`2b310539e7b5999d8475010a0452b262ef3e3ae0`

والـparent المباشر:

`083e52b9866d92eb6cd57583f06b38958b8795c8`

الأحداث الأخيرة ذات الصلة:

```text
2b310539e7b5999d8475010a0452b262ef3e3ae0
chore(hr): canonicalize HR runtime hardening migration

083e52b9866d92eb6cd57583f06b38958b8795c8
docs(hr): update current state after 2026-09-17 RW_HR closure

489807f777c8578dfe5fca4294ece634e02b3f89
docs(hr): add full competitive HR closure and next-session evidence

2aa3f2de01e8c1921b3368cf70c4f4cf5a9a4204
chore(hr): canonicalize request leave and temporal integrity closure

e4a13bd7743b1d5820b85973d5c60e4b83dc1162
HR Mother surgical replacement FINAL — modal resilience and complete UX closure
```

آخر commit `2b3105...` يحتوي فقط على ملف migration الخاص بـHR runtime hardening، ولم يمس `main.html`.

## 2.2 Mother Repository

المستودع:

`papamohammed77-glitch/erp-frontend`

أحدث HEAD:

`269d3fb7776005ae6c2d9431cf784bde4b434e92`

الـparent المباشر:

`2b8ef7a26716470020bb786566210c0c41a434dd`

آخر commitين في Mother هما commits توثيق/استخراج جنائي للمصدر، وليسا إعادة كتابة لـHR.

المصدر الفعلي المعتمد:

`companies/company-1/main.html`

نقطة `RW_HR` الحالية:

```text
Start = var RW_HR = (function() {
End   = window.RW_HR = RW_HR;
Approx. source range = 23788 .. 24064
```

البلوب/الاستخراج الجنائي الحالي للمصدر سبق تثبيته ضمن سلسلة forensic extraction، ولم يتم استبداله في Mother.

---

# 3. ما ثبت من MASTER CTO GOVERNANCE

المبدأ الحاكم ليس "أصلح الخطأ الظاهر".

التسلسل الحاكم هو:

```text
UNDERSTAND
  ↓
RECONSTRUCT HISTORICAL CONTRACT
  ↓
TRACE CURRENT BEHAVIOR
  ↓
TRACE DATA / AUTH / CONTROL FLOW
  ↓
COMPARE WITH TARGET ARCHITECTURE
  ↓
IDENTIFY ACTUAL GAP
  ↓
DESIGN MINIMAL SAFE CHANGE
  ↓
IMPLEMENT
  ↓
VERIFY AGAINST HISTORICAL + TARGET CONTRACTS
```

وبناءً عليه لم يتم اعتبار تقارير HR السابقة دليلًا على الحالة الحالية، بل تم استخدامكها كمرشد للبحث فقط ثم أعيد فحص Production وGit والمصدر مباشرة.

القاعدة التي تحكم هذه الجلسة:

```text
CURRENT GIT
+
CURRENT SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

هي الوحيدة التي تملك صلاحية إثبات الحالة.

---

# 4. Production HR — الصورة الجنائية الحالية

## 4.1 جداول HR الموجودة

Production تحتوي بالفعل على البنية الحديثة التالية:

```text
employee_profiles
employee_attendance
employee_leave_requests
employee_documents

hr_departments
hr_positions
hr_employee_assignments
hr_employee_schedule_assignments
hr_work_schedules
hr_attendance_events
hr_work_entries
hr_leave_types
hr_leave_balances
hr_requests
hr_request_approvals
hr_salary_advances
hr_salary_components
hr_contracts
hr_contract_components
hr_payroll_periods
hr_payroll_runs
hr_payslips
hr_payslip_lines
hr_payroll_accounting_map
hr_command_log
```

لا توجد عائلة HR ثانية تم إنشاؤها في هذه الجلسة.

## 4.2 حالة البيانات

جميع جداول HR التجارية/التشغيلية أعلاه بقيت في نهاية الجلسة بصفر سجلات.

هذا ليس نقصًا يجب إخفاؤه؛ بل يعني أن Production لم تُلوث ببيانات تجريبية مصطنعة.

الاستعلام النهائي أعاد:

```text
employee_profiles                    0
employee_attendance                  0
employee_leave_requests              0
employee_documents                  0
hr_departments                       0
hr_positions                         0
hr_employee_assignments              0
hr_employee_schedule_assignments     0
hr_work_schedules                    0
hr_attendance_events                 0
hr_work_entries                      0
hr_leave_types                       0
hr_leave_balances                    0
hr_requests                          0
hr_request_approvals                 0
hr_salary_advances                   0
hr_salary_components                 0
hr_contracts                         0
hr_contract_components               0
hr_payroll_periods                   0
hr_payroll_runs                      0
hr_payslips                          0
hr_payslip_lines                     0
hr_payroll_accounting_map            0
hr_command_log                       0
```

---

# 5. Production HR Core

## 5.1 القراءة

المحرك:

`hr_query`

المسؤولية:

```text
Dashboard
Employees
Departments
Positions
Assignments
Schedules
Contracts
Contract Components
Attendance
Attendance Events
Leaves
Leave Balances
Leave Types
Requests
Request Approvals
Advances
Payroll Periods
Payroll Runs
Salary Components
Payroll Accounting Map
Payslips
Documents
Documents Expiring
Work Entries
```

تم اختبار جميع هذه الـviews مباشرة من Production تحت JWT context يمثل مستخدم HR فعلي في الشركة الحالية.

النتيجة:

```text
24 view/route exercised
24 PASS
0 FAIL
```

ملحوظة دقيقة:

`dashboard` يعرض `employees = 24` لأن مصدر workforce identity هو `users`، بينما `employee_profiles = 0` لأن ملفات HR التفصيلية لم تُنشأ فعليًا بعد. هذا فرق مقصود في نموذج البيانات وليس تناقضًا.

## 5.2 الكتابة

المحرك المركزي:

`hr_command_atomic`

التوقيع الحالي:

```text
hr_command_atomic(
  p_command text,
  p_payload jsonb,
  p_operation_id text,
  p_actor_user_id uuid,
  p_actor_email text
)
returns jsonb
```

يوجد overload واحد فقط.

الوظيفة:

```text
Authentication
Authorization
Tenant derivation
Operation identity
Idempotency
Business validation
Transactional mutation
Audit command log
```

---

# 6. Command Contract الحالي

الأوامر الأساسية المثبتة في Production هي:

```text
employee.profile.upsert
org.department.upsert
org.position.upsert
org.assignment.upsert
contract.upsert
schedule.upsert
schedule.assign
salary.component.upsert
contract.component.upsert
contract.component.deactivate
leave.type.upsert
leave.balance.adjust
attendance.event.record
attendance.day.upsert
leave.request.create
leave.request.approve
leave.request.reject
leave.request.cancel
request.create
request.approve
request.reject
advance.create
advance.approve
advance.disburse
payroll.period.upsert
payroll.run.calculate
payroll.run.approve
payroll.run.post
payroll.accounting.map
document.metadata.upsert
```

هذه هي Command Surface التي يعتمد عليها الـsurgical replacement.

---

# 7. الإصلاح الفعلي الذي تم في Production هذه الجلسة

## 7.1 إصلاح نوع متغير Leave State داخل hr_command_atomic

أثناء مراجعة تعريف Production ظهر أن متغير حالة طلب الإجازة كان معرفًا كـ`text` بينما branch الاعتماد/الرفض/الإلغاء يتعامل معه كـrow record (`.status`, `.employee_id`, `.leave_type_id`, ...).

تم إصلاح التعريف جراحيًا إلى:

```sql
v_leave_status_before public.employee_leave_requests%ROWTYPE;
```

لم تتم إعادة كتابة الـfunction يدويًا من الذاكرة.

تم تنفيذ replacement ديناميكي محكوم من `pg_get_functiondef()` مع guards ترفض التنفيذ إذا لم نجد التطابق المتوقع أو وجدنا أكثر من occurrence واحد.

التحقق بعد النشر:

```text
leave-status row type fixed = TRUE
```

ثم تم تنفيذ اختبار runtime لمسار:

`leave.request.approve`

على Request ID غير موجود.

النتيجة كانت:

```text
success = false
code    = HR_COMMAND_ERROR
msg     = طلب الإجازة غير موجود ضمن الشركة الحالية
```

وهذا مهم لأن النتيجة تثبت أن branch تم compile/runtime بشكل صحيح ولم يعد يتوقف على type error.

## 7.2 إزالة direct DML capability من HR Core

تم إغلاق `INSERT / UPDATE / DELETE / TRUNCATE` على الجداول الحديثة أمام `anon` و`authenticated`.

الجداول التي أصبح Client لا يكتب إليها مباشرة:

```text
hr_departments
hr_positions
hr_employee_assignments
hr_employee_schedule_assignments
hr_work_schedules
hr_attendance_events
hr_work_entries
hr_leave_types
hr_leave_balances
hr_requests
hr_request_approvals
hr_salary_advances
hr_salary_components
hr_contracts
hr_contract_components
hr_payroll_periods
hr_payroll_runs
hr_payslips
hr_payslip_lines
hr_payroll_accounting_map
hr_command_log
```

كما تم إغلاق direct DML على:

```text
employee_profiles
employee_attendance
employee_leave_requests
```

مع إبقاء SELECT للمستخدمين المسموح لهم.

نتيجة الفحص النهائي:

```text
HR direct client DML grants = 0
```

وهذا يحول قاعدة البيانات فعليًا من:

```text
UI → tables
```

إلى:

```text
UI → hr_command_atomic → HR tables
```

بالنسبة إلى الـcanonical HR Core.

---

# 8. لماذا لم يتم تعطيل Legacy HR RPCs بالكامل

السبب ليس ترددًا.

الـMother الحالية ما زالت تستدعي:

```text
hr_list_employees
hr_upsert_employee_profile
hr_save_attendance
hr_create_leave_request
hr_set_leave_status
```

لذلك فإن تعطيل execution لهذه الواجهات قبل تطبيق الـsurgical replacement على Mother سيؤدي إلى كسر الـconsumer الحالي.

تم اتخاذ الحد الآمن التالي:

```text
anon legacy execution = CLOSED
authenticated legacy execution = PRESERVED until cutover proof
```

هذا ليس قبولًا بمحرك ثانٍ دائم؛ بل Compatibility Window.

بعد نجاح browser E2E على Mother الجديدة يجب تنفيذ:

```text
legacy interface retirement
```

أو تحويل ما يلزم إلى compatibility adapters صريحة إذا ثبت وجود consumer تاريخي يحتاجها.

---

# 9. Current Mother RW_HR — الحقيقة الحالية

المصدر الحالي في Mother لا يستخدم:

```text
hr_query
hr_command_atomic
```

في RW_HR القديم.

بل يستخدم الطبقة التاريخية:

```text
hr_list_employees
hr_upsert_employee_profile
hr_save_attendance
hr_create_leave_request
hr_set_leave_status
```

مع بعض الوصول المباشر القديم.

هذا يعني أن:

```text
Current Production HR Core = modern
Current Mother RW_HR      = legacy consumer
```

ولا يجوز وصف الـMother بأنها "أغلقت" لمجرد أن الـCore أُغلق.

---

# 10. Surgical Replacement — الحالة الجاهزة

الملف الكامل الجاهز:

`doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`

Blob SHA:

`d02050f9f8131156b5dc283d5229cb1ffff5e5fd`

حجم الملف:

`49,416 bytes`

هذا الملف هو **replacement كامل** وليس patch مختصرًا أو pseudo-code.

## حد الاستبدال الوحيد

يتم استبدال كتلة:

```text
var RW_HR = (function() {
...
window.RW_HR = RW_HR;
```

فقط.

النطاق التقريبي في Mother الحالية:

```text
23788 .. 24064
```

## ممنوع

```text
لا تعديل main.html خارج RW_HR
لا إعادة ترتيب باقي الملف
لا إضافة Edge Function جديدة
لا إنشاء HR tables جديدة
لا إعادة استخدام main2 ككود حي
```

## القدرات التي يوفرها replacement الكامل

```text
dashboard
employees
Employee 360
organization
contracts
attendance
leaves
requests
advances
payroll
documents
realtime
```

### قاعدة القراءة

```text
q(view,payload)
→ hr_query
```

### قاعدة الكتابة

```text
c(command,payload,operationKey)
→ hr_command_atomic
```

### الهوية

المصدر يحدد:

```text
Supabase Auth user
→ users.auth_id
→ actor user
→ actor company
```

ولا يعتمد على `app_settings LIMIT 1` لاستخراج Company Context.

---

# 11. مطابقة replacement مع Production

## Employees / Employee 360

Production:

```text
users
employee_profiles
employee_documents
hr_contracts
hr_employee_assignments
hr_positions
hr_departments
```

Replacement:

```text
q('employees')
q('contracts')
q('assignments')
q('positions')
q('departments')
q('documents')
```

والتعديل يمر عبر:

`employee.profile.upsert`
`contract.upsert`
`org.assignment.upsert`
`document.metadata.upsert`

## Organization

Production commands:

```text
org.department.upsert
org.position.upsert
org.assignment.upsert
```

Replacement يقدم forms لهذه المسؤوليات الثلاث.

## Contracts

Production contract engine يفرض temporal integrity.

Replacement يمرر:

```text
contract.upsert
contract.component.upsert
contract.component.deactivate
```

## Attendance

Production يدعم:

```text
attendance.event.record
attendance.day.upsert
```

ومحرك event يستطيع إنتاج:

```text
hr_attendance_events
employee_attendance
hr_work_entries
```

Replacement يقدم:

```text
attendance day
attendance events
```

## Leaves

Production يدعم:

```text
leave.type.upsert
leave.balance.adjust
leave.request.create
leave.request.approve
leave.request.reject
leave.request.cancel
```

مع:

```text
overlap guard
balance guard
attachment guard
cancel reversal
```

Replacement يغطي lifecycle كامل.

## Requests

Production يدعم:

```text
request.create
request.approve
request.reject
```

ومسار approval متعدد الخطوات.

Replacement ينشئ الخطوات ويعرض الاعتماد والرفض.

## Advances

Production يدعم:

```text
advance.create
advance.approve
advance.disburse
```

Replacement يغطي هذه الدورة.

## Payroll

Production يدعم:

```text
payroll.period.upsert
payroll.run.calculate
payroll.run.approve
payroll.accounting.map
payroll.run.post
```

Replacement يغطي cycle التشغيل.

## Documents

Production:

```text
document.metadata.upsert
storage policies
signed URL read
```

Replacement:

```text
upload file
metadata upsert
signed open
expiry view
```

ويحذف ملف storage إذا فشل metadata write، منعًا للorphan object.

---

# 12. قاعدة البيانات والـRLS والـrealtime

## RLS

تم التحقق من أن HR tables الحديثة تعمل تحت tenant/employee policy framework الموجود في Production.

## Realtime

حالة Production الحالية تتضمن نشر جداول HR المطلوبة للـrealtime.

لا توجد حاجة لإنشاء عائلة realtime ثانية.

## Storage

`employee_documents` وسياسات bucket مرتبطة بسياق الشركة والموظف.

لا يتم وضع الملفات في root عالمي.

---

# 13. QA الذي تم تنفيذه على Production

## 13.1 Read surface

تم تشغيل جميع views الخاصة بـ`hr_query` مع JWT context لمستخدم HR موجود فعليًا:

```text
PASS = dashboard
PASS = employees
PASS = departments
PASS = positions
PASS = assignments
PASS = schedules
PASS = contracts
PASS = contract_components
PASS = attendance
PASS = attendance_events
PASS = leaves
PASS = leave_balances
PASS = leave_types
PASS = requests
PASS = request_approvals
PASS = advances
PASS = payroll_periods
PASS = payroll_runs
PASS = salary_components
PASS = payroll_accounting_map
PASS = payslips
PASS = documents
PASS = documents_expiring
PASS = work_entries
```

## 13.2 Profile mutation

تم تنفيذ:

```text
employee.profile.upsert
```

مع بيانات مؤقتة داخل transaction.

النتيجة:

```text
success = true
```

ثم `ROLLBACK`.

## 13.3 Leave approval branch runtime

تم اختبار:

```text
leave.request.approve
```

على Request غير موجود بهدف التحقق من runtime compilation وليس إنشاء بيانات.

النتيجة:

```text
HR_COMMAND_ERROR
طلب الإجازة غير موجود ضمن الشركة الحالية
```

أي أن branch يعمل ويصل إلى business lookup المقصود.

## 13.4 Data cleanliness

بعد كل الاختبارات:

```text
HR business rows = 0
```

لا توجد بقايا اختبارية.

---

# 14. ما لم يتم الادعاء بإنجازه

هناك ثلاث طبقات لا يجوز دمجها في نسبة واحدة:

```text
Production structural verification
Production database-authenticated verification
Mother browser E2E
```

الأولى = PASS.

الثانية = PASS في الاختبارات التي تم تنفيذها مباشرة على RPC/database context.

الثالثة = OPEN.

لم يتم استخدام أي ادعاء من نوع:

```text
Staging PASS → Production PASS
```

ولم يتم إعلان browser E2E ناجحًا بدون Browser Session حقيقي.

---

# 15. لماذا يوجد OPEN Browser E2E

الأمر المطلوب في هذه المرحلة يحتاج تشغيل Mother نفسها بجلسة Authenticated حقيقية، والتنقل عبر جميع الـtabs والتعامل مع modals والـstorage والـrealtime.

المتاح في جلسة التحقيق الحالية يسمح بـ:

```text
Git forensic
Production SQL
Production RPC execution
Production Edge inspection
Source inspection
```

لكنه لا يوفر جلسة متصفح Authenticated حقيقية للـMother تسمح بإثبات كامل ما يلي:

```text
DOM wiring
actual click handlers
modal mount/resilience
browser storage upload
realtime UI refresh
Employee 360 live rendering
multi-step request UI
```

لذلك بقي هذا الجزء OPEN بدل تزوير الإغلاق.

---

# 16. المنافسة — Benchmark 2026

> المقارنة هنا Benchmark وظيفي، وليست ترتيبًا أو تصويتًا.

## Odoo

Odoo 19 يقدّم في HR وحدات تشمل Employees وAttendances وTime Off وPayroll وRecruitment وAppraisals وLearning/Certifications وغيرها. وثائق Odoo الحالية توضح كذلك وجود onboarding/offboarding، skills، certifications، training، equipment، وخيارات attendance kiosk والتسجيل والحسابات وربط العقود بالـworking schedules وwork entries، بالإضافة إلى payroll localizations تشمل مصر والسعودية وعدة دول أخرى.

المراجع الرسمية:

https://www.odoo.com/documentation/19.0/applications/hr/
https://www.odoo.com/documentation/19.0/applications/hr/employees.html
https://www.odoo.com/documentation/19.0/applications/hr/attendances.html
https://www.odoo.com/documentation/19.0/applications/hr/time_off.html
https://www.odoo.com/documentation/19.0/applications/hr/payroll/contracts.html
https://www.odoo.com/documentation/19.0/applications/hr/payroll/payroll_localizations.html
https://www.odoo.com/documentation/19.0/applications/hr/recruitment.html
https://www.odoo.com/documentation/19.0/applications/hr/employees/learning.html
https://www.odoo.com/documentation/19.0/applications/hr/employees/certifications.html

## Microsoft Dynamics 365 Human Resources

الوثائق الحالية لـDynamics 365 HR توضح دعم leave plans وaccruals وbalances وemployee/manager self-service وbenefits management، كما أن المنتج يربط HR بالتخطيط والـskills والـintegrations وPower Platform، ويستمر تطويره بإصدارات حديثة خلال 2026.

المراجع الرسمية:

https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-leave-and-absence-overview
https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-leave-and-absence-plans
https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-employee-manager-self-service-overview
https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-benefits-manage-program
https://learn.microsoft.com/en-us/dynamics365/guidance/business-processes/hire-to-retire-overview
https://learn.microsoft.com/en-us/dynamics365/human-resources/get-started/hr-whats-new-10-0-49

## SAP SuccessFactors Employee Central

SAP Employee Central يركز على Core HR بعمق، بما في ذلك People Profile، personal/employment/organizational/job/compensation data، effective-dated entities، workflows، Time Off، permission model، ومكوّنات HR المرتبطة بالعمليات المؤسسية.

المراجع الرسمية:

https://help.sap.com/docs/SAP_SUCCESSFACTORS_EMPLOYEE_CENTRAL/106c586d0f6941414d9684e4fae96839/employee-central-core
https://help.sap.com/docs/successfactors-employee-central/employee-central-core-configuration-guide-getting-started/check-people-profile
https://help.sap.com/docs/successfactors-employee-central/implementing-time-management-in-sap-successfactors/employee-permissions-for-time-off
https://help.sap.com/docs/successfactors-employee-central/employee-central-core-configuration-guide-getting-started/configure-workflow-for-mdf-foundation-objects-optional
https://help.sap.com/docs/successfactors-employee-central/implementing-employee-central-core/employee-data-hr-actions

## Daftra

Daftra حاليًا يقدّم Human Resource Management يجمع التنظيم والعقود والحضور والرواتب والإجازات والطلبات والتقارير، ويذكر رسميًا مميزات مثل attendance rules، overtime، leave policies، multi-level approvals، salary components، payroll، loans/advances، ESS، fingerprint integration، geofencing، IP validation، photo verification، والتقارير التشغيلية.

المراجع الرسمية:

https://www.daftra.com/en/hrm/
https://www.daftra.com/en/payroll/
https://www.daftra.com/en/attendance-leave-management/
https://www.daftra.com/en/plans
https://www.daftra.com/en/features/sub_feature/5

## Manager.io

Manager يقدّم Employee + Payslips + Payroll accounting workflow، لكنه لا يقدّم نفس عمق HRIS الحديث الموجود في Odoo/Dynamics/SAP/Daftra؛ الوظائف الرسمية الموثقة تركز على تسجيل الموظفين، payslips، deductions، contributions، والدفعات.

المراجع الرسمية:

https://www2.manager.io/guides/9751
https://www2.manager.io/guides/9752
https://www2.manager.io/guides/9753
https://www2.manager.io/guides/9667

---

# 17. Competitive Capability Matrix

| المجال | RAWAEA الحالية | Odoo | Dynamics HR | SAP EC | Daftra | Manager.io |
|---|---|---|---|---|---|---|
| Employee master | موجود | موجود | موجود | قوي | موجود | موجود |
| Employee 360 | موجود في replacement | موجود | موجود | موجود | موجود | محدود |
| Organization structure | موجود | موجود | موجود | موجود | موجود | محدود |
| Positions / assignments | موجود | موجود | موجود | موجود | موجود | محدود |
| Effective-dated controls | موجود | موجود جزئيًا حسب التطبيق | موجود | أساسي | موجود على مستويات متعددة | محدود |
| Contracts | موجود | موجود | موجود | موجود | موجود | محدود |
| Salary components | موجود | موجود | موجود | موجود | موجود | موجود كبنود payslip |
| Attendance day | موجود | موجود | موجود | موجود عبر time management | موجود | غير أساسي |
| Attendance events | موجود | kiosk/check-in/out | موجود ضمن HR ecosystem | موجود | قوي | محدود |
| Overtime logic | موجود Core | موجود | موجود ضمن ecosystem | موجود | موجود | يدوي نسبيًا |
| Leave requests | موجود | موجود | موجود | موجود | موجود | غير أساسي |
| Leave balances | موجود | موجود | موجود | موجود | موجود | غير أساسي |
| Accrual plans | **فجوة** | موجود | موجود | موجود | موجود بدرجات | غير أساسي |
| Public holiday framework | **فجوة** | موجود | موجود | موجود | موجود | محدود |
| Multi-level requests | موجود | workflows بحسب التطبيق | موجود | موجود | موجود | محدود |
| Salary advances | موجود | عبر payroll/other modules | موجود | موجود | موجود | موجود كمفهوم deduction/accounting |
| Payroll run | موجود | موجود | موجود/تكامل | موجود | موجود | موجود |
| Payroll accounting | موجود | موجود | موجود/تكامل | موجود | موجود | موجود |
| Statutory localization | **فجوة** | موجود | موجود حسب السوق | موجود | موجود حسب المنتج/السوق | محدود |
| Employee documents | موجود | موجود | موجود | موجود | موجود | custom fields أكثر من HR DMS |
| Recruiting | **فجوة** | موجود | موجود ecosystem | موجود | غير محور أساسي في هذا التقرير | غير موجود كمكوّن HRIS كامل |
| Performance / Appraisal | **فجوة** | موجود | موجود ecosystem | موجود | جزء من HRM/talent | غير موجود كمحور |
| Learning / Certifications | **فجوة** | موجود | موجود ecosystem | موجود | موجود بدرجات | غير أساسي |
| Benefits management | **فجوة جزئية** | موجود | موجود | موجود | موجود | محدود |
| ESS dedicated | **فجوة** | موجود | موجود | موجود | موجود | غير محوري |
| Biometric / kiosk / geofence | **فجوة** | kiosk/RFID/barcode خيارات | ecosystem integrations | integrations | قوي في هذا الجانب | محدود |
| Advanced HR analytics | **فجوة جزئية** | reports | Power BI ecosystem | analytics | reports | accounting-centric |
| Canonical write engine | **ميزة معمارية RAWAEA** | framework-specific | platform-specific | platform-specific | application-specific | application-specific |

الجدول أعلاه لا يزعم تكافؤًا كاملًا بين المنتجات؛ الهدف منه تعريف ما يملكه RAWAEA اليوم وما يحتاج roadmap حقيقيًا.

---

# 18. فجوات RAWAEA التي يجب عدم اختلاقها في هذه المرحلة

## Closed / Core

```text
Employee master
Organization
Assignments
Schedules
Contracts
Attendance event/day core
Leave lifecycle core
Request approvals
Advances core
Payroll core
Accounting mapping core
Documents metadata + storage scope
Tenant/security foundation
Canonical command engine
Canonical query engine
```

## Open / Roadmap — لا تُنفذ بالافتراض

```text
Recruiting / ATS
Onboarding / Offboarding workflow engine كامل
Performance / Appraisal
Learning / Training / Certifications
Skills inventory
Benefits plans / eligibility / enrollment
Advanced leave accrual / carryover / tiered plans
Public holiday calendar engine
Statutory Egypt payroll rules
Statutory Saudi payroll rules
Insurance / social benefit compliance rules
Commission-to-payroll advanced integration
Advanced geofencing / biometric integrations
Dedicated Employee Self Service application
Dedicated Manager Self Service application
Advanced HR analytics / workforce planning
Advanced cross-midnight attendance policies
```

هذه ليست "أخطاء" في Core الحالي؛ بل capabilities ليست ضمن العقد الحالي أو تحتاج domain/data contract مستقل.

---

# 19. ما لا يجب إصلاحه مرة أخرى

لا يجب إعادة فتح ما ثبت بالفعل في Production إلا إذا ظهر evidence جديد.

لا تعُد إلى:

```text
main2
historical HR reports as source of truth
old helper fragments
old direct-table HR writer assumptions
```

ولا تعُد إلى إعادة إنشاء:

```text
HR tables
hr_query
hr_command_atomic
leave balance core
request approval core
```

ما لم يظهر Production evidence مباشر يثبت drift جديد.

---

# 20. سجل القرارات الحاكمة لهذه الجلسة

```text
1. main.html لم يُمس.

2. لا Edge Function جديدة للـHR.

3. HR Core ظل داخل hr_command_atomic.

4. hr_query ظل read engine.

5. direct authenticated HR Core DML = 0.

6. legacy RPCs لم تُغلق للمستخدمين المصادق عليهم قبل cutover.

7. لم يتم إنشاء بيانات HR حقيقية أو seed data.

8. أي اختبار كتابي تم داخل transaction مع rollback.

9. browser E2E لم يُدّع نجاحه دون Browser Session حقيقية.

10. المنافسة استُخدمت لتحديد capability gaps وليس لإعادة تصميم Production بالتخمين.
```

---

# 21. Surgical Implementation — ماذا ينفذ المساعد/المالك بالضبط

## الجزء A — Mother

افتح فقط:

`erp-frontend/companies/company-1/main.html`

ابحث عن:

```text
var RW_HR = (function() {
```

واحذف الكتلة كاملة حتى السطر الذي يحتوي:

```text
window.RW_HR = RW_HR;
```

ثم الصق **الملف الكامل**:

`doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`

كما هو بدون اختصار.

لا تُجرِ أي تعديل إضافي خارج الكتلة.

## الجزء B — Production

Migration canonical:

`supabase/migrations/20260917_hr_runtime_hardening_r1.sql`

هذه migration تم تطبيقها بالفعل على Production.

Migration version المسجلة حاليًا:

`20260917182812`

## الجزء C — بعد تطبيق Mother

لا تغلق RW_HR قبل تنفيذ:

```text
Syntax validation
Browser login
HR dashboard
Employees
Employee 360
Organization
Contracts
Attendance
Leaves
Requests
Advances
Payroll
Documents
Realtime refresh
```

---

# 22. Final Closure Gate

لا يُغلق `RW_HR` إلا إذا أصبحت كل الخانات التالية `PASS`:

```text
[GIT]
Current system HEAD verified
Current Mother HEAD verified
Parent commits verified

[SOURCE]
RW_HR boundary verified
Replacement assembled
Syntax PASS
No accidental main.html collateral edits

[PRODUCTION]
hr_query current
hr_command_atomic current
RLS current
Storage current
Realtime current
Direct client DML = 0
Legacy execution surface reviewed

[RUNTIME]
Authenticated browser login PASS
Dashboard PASS
Employees PASS
Employee 360 PASS
Organization PASS
Contracts PASS
Attendance PASS
Leaves PASS
Requests PASS
Advances PASS
Payroll PASS
Documents PASS
Realtime PASS

[INTEGRITY]
No duplicate HR records
No orphan requests
No orphan approvals
No orphan storage files
No duplicate operation IDs
No tenant bleed

[FINAL]
Production re-read immediately after browser E2E
CURRENT_STATE updated
Final HR report written
RW_HR = CLOSED
```

---

# 23. Final Self-Audit

## ما تم إثباته

```text
1. أحدث Git baseline والمصدر الحالي تم التحقيق فيهما.
2. Production HR schema موجود.
3. Production hr_query يعمل في authenticated HR context.
4. Production hr_command_atomic يعمل في runtime branch الاختبارية المطلوبة.
5. خلل leave state variable تم إصلاحه فعليًا.
6. direct client DML على HR Core = 0.
7. بيانات HR التجارية بقيت نظيفة = 0.
8. surgical replacement الكامل جاهز.
9. main.html لم يتغير.
10. competitor benchmark تم التحقق منه بمصادر رسمية حديثة.
```

## ما لم يتم إثباته

```text
1. Browser E2E حقيقية على Mother بعد replacement.
2. Storage upload الفعلي داخل browser session.
3. Realtime UI refresh الفعلي داخل المتصفح.
4. Payroll post end-to-end ببيانات محاسبية حقيقية في هذه الشركة.
5. Retirement النهائي لكل legacy HR RPC execution surface.
```

## ما تم إصلاحه

```text
HR runtime hardening R1
```

## ما يمكن أن يكون لا يزال خطأ

```text
أي خطأ في consumer wiring لا يظهر إلا بعد تجميع RW_HR داخل main.html الحقيقي وتشغيله في Browser.
```

## Final Confidence

```text
Production Core confidence          = HIGH
Production DB contract confidence  = HIGH
Mother source confidence            = HIGH
Browser runtime confidence          = OPEN / not yet proven
Overall RW_HR closure               = NOT CLOSED YET
```

---

# 24. تعليمات البدء للجلسة التالية — لا تبدأ من الصفر

> **هذه هي أهم فقرة في التقرير.**

لا تبدأ بدراسة HR كأنه مشروع جديد.

ابدأ بالترتيب التالي:

```text
1. اقرأ CURRENT_STATE.md.
2. اقرأ آخر Report ضمن doc/Draft/Reprots، لكن لا تثق به كحالة حالية.
3. تحقق من أحدث HEAD في rawaie-erp-New + parent.
4. تحقق من أحدث HEAD في erp-frontend + parent.
5. افتح Mother main.html الحالي.
6. حدد RW_HR boundary الحالي.
7. قارن boundary مع HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js.
8. تحقق هل replacement تم تطبيقه أم لا.
9. اقرأ Production hr_query مباشرة.
10. اقرأ Production hr_command_atomic مباشرة.
11. اقرأ RLS + storage + realtime مباشرة.
12. تحقق أن direct HR DML grants ما زالت = 0.
13. لا تُنشئ أي بيانات HR إلا داخل transaction test مع rollback.
14. إذا كان replacement غير مطبق: نفّذه داخل RW_HR فقط.
15. لا تعد إلى main2 إلا كمرجع تاريخي.
16. لا تعُد إلى التقارير القديمة لإثبات الحالة.
17. نفّذ syntax validation على Mother بعد التجميع.
18. نفّذ Browser E2E حقيقية بجلسة Authenticated HR.
19. اختبر كل tab وكل modal وكل Employee 360 path.
20. اختبر leave approval/rejection/cancel balance reversal.
21. اختبر multi-step request approvals.
22. اختبر contract/assignment/schedule temporal guards.
23. اختبر attendance event/day.
24. اختبر payroll calculation/approve/post بحسب وجود accounting master data الحقيقي.
25. اختبر document upload + metadata + signed open + cleanup on failure.
26. اختبر realtime UI refresh.
27. أعد قراءة Production فورًا بعد E2E.
28. ابحث عن duplicate/orphan records.
29. بعدها فقط راجع legacy HR RPC retirement.
30. ثم حدّث CURRENT_STATE.md.
31. ثم أضف التقرير التالي.
32. فقط عند اكتمال كل gates: RW_HR = CLOSED.
```

**لا تكرر أي إصلاح من الماضي ما لم يظهر في Production evidence جديد.**

---

# 25. سجل Git/Production المطلوب حمله إلى الجلسة التالية

```text
System repo HEAD:
2b310539e7b5999d8475010a0452b262ef3e3ae0

System repo parent:
083e52b9866d92eb6cd57583f06b38958b8795c8

Mother HEAD:
269d3fb7776005ae6c2d9431cf784bde4b434e92

Mother parent:
2b8ef7a26716470020bb786566210c0c41a434dd

Production project:
fiilmooggumokxanwiyx

Latest applied HR runtime migration:
20260917182812
hr_runtime_hardening_r1

Surgical replacement:
HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js

Surgical replacement SHA:
d02050f9f8131156b5dc283d5229cb1ffff5e5fd

Mother RW_HR boundary:
~23788 .. 24064
```

---

# 26. المراجع الحاكمة داخل المستودع

```text
CURRENT_STATE.md

doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md

doc/Draft/Reprots/Report233_HR_FULL_COMPETITIVE_CLOSURE_20260917.md

doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js

supabase/migrations/20260917_hr_core_request_leave_temporal_integrity.sql
supabase/migrations/20260917_hr_runtime_hardening_r1.sql
```

---

# 27. قرار الإغلاق

```text
GLOBAL HR CORE INTEGRITY           = CLOSED/HARDENED
RW_HR PRODUCTION BACKEND           = CLOSED/HARDENED
RW_HR MOTHER CONSUMER               = OPEN UNTIL BROWSER CUTOVER
OVERALL RW_HR                       = NOT CLOSED YET
```

هذا هو القرار الصحيح وفق الأدلة الحالية.

أي تقرير لاحق يجب أن يبدأ من هذا snapshot ولا يعيد فتح ما تم إثباته، إلا إذا كان هناك evidence جديد من Production/Git/Source/Deployment يثبت drift.
