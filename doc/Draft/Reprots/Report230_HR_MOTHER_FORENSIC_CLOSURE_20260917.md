# Report230 — MOTHER HR FORENSIC REVIEW / PRODUCTION CLOSURE

**التاريخ:** 2026-09-17  
**النطاق الوحيد:** تبويب الموارد البشرية في النظام الأم Mother  
**Source of Truth:** `papamohammed77-glitch/erp-frontend/companies/company-1/main.html`  
**المستودع المرجعي التاريخي:** `papamohammed77-glitch/rawaie-erp-New`  
**Production:** Supabase project `fiilmooggumokxanwiyx`  

## 1. قاعدة الحوكمة

التقارير السابقة استُخدمت كدلائل بحث فقط. الحالة الحالية بُنيت من التحقيق المباشر في:

```text
CURRENT GIT
CURRENT SOURCE
CURRENT PRODUCTION
CURRENT DATABASE
CURRENT DEPLOYMENT EVIDENCE
```

تمت مراجعة أحدث HEAD في `erp-frontend` وهو:

`269d3fb7776005ae6c2d9431cf784bde4b434e92`

والـdirect parent هو:

`2b8ef7a26716470020bb786566210c0c41a434dd`

وكلاهما تغييرات forensic extraction وليسا إعادة بناء وظيفية لـMother HR. لذلك لم يُعتبر أي منهما بديلًا عن المصدر الحالي.

تم التحقق أيضًا من أن `forensic_main_assembly.yml` في المستودع المرجعي يعلن بصورة صحيحة:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

## 2. الحقيقة الحالية للـMother HR

في المصدر الحالي، كتلة HR تبدأ عند:

`var RW_HR = (function() {` — **السطر 23788**

وتنتهي عند:

`window.RW_HR = RW_HR;` — **السطر 24064**

الكتلة الحالية تعتمد على العقد القديم:

- `hr_list_employees`
- `hr_upsert_employee_profile`
- `hr_save_attendance`
- `hr_create_leave_request`
- `hr_set_leave_status`
- قراءات مباشرة من `employee_documents` و`employee_attendance` و`employee_leave_requests`

ولا تستخدم العقد المركزي الحديث:

- `hr_query`
- `hr_command_atomic`
- `hr_command_log`
- بنية المنظمة والعقود والجداول والرواتب والمكونات والمستندات المتقدمة.

هذا يعني أن المشكلة ليست أن HR schema غير موجود؛ المشكلة أن Mother لا تستعمل البنية الحديثة.

## 3. الحقيقة الحالية في Production

البنية الحديثة موجودة بالفعل في Production، ومنها:

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

وجميع جداول HR الحديثة موجودة أصلًا في `supabase_realtime`; لم تُنشأ جداول مكررة.

حالة شركة الروائع الحالية قبل إدخال بيانات تشغيلية جديدة:

```text
users                 = 24
employee_profiles     = 0
hr_departments        = 0
hr_positions          = 0
hr_contracts          = 0
employee_attendance   = 0
hr_attendance_events  = 0
employee_leave_requests = 0
hr_leave_types        = 0
hr_leave_balances     = 0
hr_requests           = 0
hr_salary_advances    = 0
hr_payroll_periods    = 0
hr_payroll_runs       = 0
hr_payslips           = 0
employee_documents    = 0
```

هذا الفراغ لا يجوز ملؤه ببيانات افتراضية أو رواتب أو عقود مخمّنة؛ البيانات التشغيلية يجب إدخالها من النظام الأم بعد توفر المستخدمين والمستندات الفعلية.

## 4. القلب المركزي الصحيح

Production تحتوي على:

`hr_command_atomic(p_command, p_payload, p_operation_id, p_actor_user_id, p_actor_email)`

وهو `SECURITY DEFINER`، ويقوم باشتقاق `company_id` من المستخدم الفعلي، ويتحقق من تطابق `auth.uid()` مع `users.auth_id` عند الاستخدام الطبيعي، ويستخدم `hr_command_log` لضمان idempotency.

كما أن `hr_query(p_view,p_payload)` يوفّر القراءة الموحدة للوحة HR وجميع الوحدات.

تم منح:

```sql
GRANT EXECUTE ON FUNCTION public.hr_command_atomic(text,jsonb,text,uuid,text)
TO authenticated, service_role;
```

مع سحب التنفيذ من `PUBLIC` و`anon`.

لم تُنشأ Edge Function جديدة باسم HR لأن Production وصلت إلى حد عدد Edge Functions المسموح به؛ محاولة النشر أعادت:

`PaymentRequiredException: Max number of functions reached for project`

وبالتحقيق في RPC تبيّن أن Security Context موجود بالفعل داخل `hr_command_atomic`، ولذلك كان استخدام الـRPC الموثق من جلسة `authenticated` هو الحل الأقل سطحًا والأقل هجومًا، بدل إعادة استخدام canary/E2E functions أو إنشاء مسار موازي.

## 5. إصلاحات Production المنفذة في هذه الجلسة

### 5.1 إصلاح عقد اعتماد/إلغاء الإجازة

تم إصلاح `hr_command_atomic` بحيث:

- يستخدم `leave_type_id` كـUUID فعلي.
- يتحقق من الشركة.
- عند اعتماد إجازة مدفوعة، يخصم الأيام من `hr_leave_balances.used`.
- عند إلغاء إجازة مدفوعة معتمدة، يعكس الأيام من `used`.
- يمنع الاعتماد إذا كان الرصيد غير كافٍ.

تم اختبار دورة approve → cancel على Production داخل Transaction ثم `ROLLBACK`.

النتيجة المثبتة:

```text
Approve  = success
Days     = 2
Used     = +2
Cancel   = success
Reverse  = true
Used     = 0
Persistent test rows = 0
```

### 5.2 تشديد مستندات الموظفين

تم تضييق INSERT/UPDATE على `employee_documents` بحيث يكون:

```text
HR permission
OR
employee نفسه
```

مع الحفاظ على company isolation ومسار employee داخل الشركة.

تم التحقق من الـpolicies بعد النشر.

### 5.3 عدم إنشاء بيانات HR وهمية

لم يتم seed للرواتب أو العقود أو الأقسام أو أرصدة الإجازات من غير مصدر تشغيلي مثبت، لأن ذلك يخالف مبدأ عدم التخمين.

## 6. Production E2E evidence

### HR command / permissions

اختبار HR transactional أثبت تنفيذ:

- `employee.profile.upsert`
- `org.department.upsert`
- idempotency لنفس `operation_id`
- `leave.type.upsert`
- `attendance.event.record`

الاختبار تم داخل Transaction ثم `ROLLBACK`.

كما تم اختبار مستخدم غير HR:

```text
employee.profile.upsert على موظف آخر = مرفوض حسب صلاحيات HR
attendance.event.record للموظف نفسه = نجح
```

وهذا يثبت أن self-service وHR-admin ليستا صلاحية واحدة.

### hr_query

تم استدعاء views الحالية من Production داخل جلسة HR محاكاةً للـJWT، وجميعها رجعت بنجاح:

```text
dashboard
employees
departments
positions
assignments
contracts
schedules
schedule_assignments
attendance
attendance_events
leaves
leave_balances
leave_types
requests
request_approvals
advances
salary_components
contract_components
payroll_periods
payroll_runs
payslips
documents
work_entries
self
```

## 7. الفجوة الوظيفية الحقيقية

Mother HR الحالية هي Employee List + basic attendance/leave/documents.

Production HR الحديثة أصبحت HR Core لكن Mother لم تلتحق بها.

الفجوات الفعلية التي يجب أن تغلقها Mother:

```text
Employee 360
Organization
Departments
Positions
Assignments
Contracts
Schedules
Salary Components
Attendance Events
Attendance Days
Leave Types
Leave Balances
Leave Requests + Approval + Cancel
Employee Requests + Multi-step Approval
Salary Advances
Payroll Periods
Payroll Calculation
Payroll Approval
Payroll Posting
Payslips
Documents + expiry
HR Dashboard / Alerts / Realtime
```

## 8. المقارنة الوظيفية الخارجية

المقارنة التالية ليست ترتيبًا أو تصنيفًا، وإنما مرجع فجوات UX/Business Coverage.

| Capability | RAWAEA Mother الحالي | RAWAEA Production Core الحالي | Daftra | Odoo | Dynamics 365 | SAP/SuccessFactors |
|---|---|---|---|---|---|---|
| Employee master | أساسي | Employee/Profile + identity | موجود | موجود | موجود | موجود |
| Organization | محدود جدًا | Departments/Positions/Assignments | موجود | موجود | موجود | موجود |
| Contracts | غير مستهلك في Mother | HR contracts + expiry metadata | موجود | موجود | موجود | موجود |
| Work schedules | غير مستهلك | schedules + assignments | shifts/rules | working hours | calendars/leave setup | time recording/calendar |
| Attendance | جدول قديم | events + day + worked/late/overtime | attendance rules/reports | attendance/work hours | time/attendance | time recording/approvals |
| Leave types/balances | أساسي | types + balances | موجود | موجود | موجود | موجود |
| Leave workflow | قديم | approve/reject/cancel + balance mutation | single/multi-level workflows | one/two approvals | workflow + manager approval | workflow/approval |
| Employee requests | غير موجود في Mother | hr_requests + approvals | موجود | extensible workflows | self-service/workflow | workflow |
| Advances | غير موجود | salary advances lifecycle | موجود | حسب التطبيقات | موجود ضمن HR ecosystem | موجود ضمن ecosystem |
| Payroll | غير موجود | period/calculate/approve/post/payslips | payroll | payroll ecosystem | payroll ecosystem | payroll integration |
| Accounting link | غير موجود | payroll accounting map/post path | payroll integration | accounting integration | finance/HR integration | finance/payroll integration |
| Documents | basic direct write | metadata + private storage + expiry | contracts/documents | employee documents | attachments | attachments/documents |
| Employee self-service | محدود | backend contract جاهز | موجود | موجود | موجود | موجود |
| Reporting | 4 KPIs فقط | dashboard/query foundation | detailed HR reports | time-off reports | leave analytics | time statements/analytics |

مراجع رسمية حالية تمت مراجعتها:

- Daftra HRM: https://www.daftra.com/en/hrm/
- Daftra Attendance/Leave: https://www.daftra.com/en/attendance-leave-management/
- Odoo Time Off: https://www.odoo.com/documentation/19.0/applications/hr/time_off.html
- Odoo Allocations: https://www.odoo.com/documentation/19.0/applications/hr/time_off/allocations.html
- Odoo Management/Approvals: https://www.odoo.com/documentation/19.0/applications/hr/time_off/management.html
- Dynamics Leave: https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-employee-self-service-request-time-off
- Dynamics Workflow: https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-leave-and-absence-workflow
- Dynamics Absence Manager: https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-configure-absence-manager

الخلاصة الوظيفية للمقارنة: الأنظمة المرجعية لا تكتفي بقائمة الموظفين؛ هي تربط Employee Master بالهيكل والتنظيم والعقد والوقت والإجازة والطلبات والاعتماد والتقارير والـself-service. هذا هو معيار الاستكمال المطلوب في Mother.

## 9. الحزمة الجراحية المطلوبة في Mother

**لا تعدّل أي ملف آخر.**

في:

`erp-frontend/companies/company-1/main.html`

ابحث حرفيًا عن:

```js
var RW_HR = (function() {
```

وهو عند **السطر 23788** في النسخة الحالية التي تم التحقيق فيها.

احذف **الكتلة كاملة** حتى آخر السطر:

```js
window.RW_HR = RW_HR;
```

وهو عند **السطر 24064**.

لا تحذف بداية فقط أو نهاية فقط؛ هذه هي كتلة `RW_HR` الحالية كاملة.

استبدلها بملف:

`HR_MOTHER_SURGICAL_REPLACEMENT_20260917.js`

المرفق بهذه الجلسة.

الرابط:

`[sandbox:/mnt/data/HR_MOTHER_SURGICAL_REPLACEMENT_20260917.js]`

البديل الجديد يستعمل مباشرة:

```text
hr_query
hr_command_atomic
```

ويغطي داخليًا:

```text
dashboard
employees
organization
contracts
attendance
leaves
requests
advances
payroll
documents
Employee 360
Realtime
```

ولا ينشئ أي Physical/Field Operations بديلة، ولا يلمس Order/Runsheet/Picking/Loading/Delivery/Return.

## 10. تدفق HR المستهدف بعد الاستبدال

```text
Mother HR UI
      ↓
Authenticated Supabase session
      ↓
hr_query  ← القراءة الموحدة
      ↓
hr_command_atomic ← كل كتابة/انتقال حالة
      ↓
HR tables + hr_command_log
      ↓
Realtime publication
      ↓
Mother refresh / Employee 360 / dashboards
```

وبهذا يصبح Mother هو مركز التحكم، بينما التطبيقات التنفيذية يمكنها استدعاء نفس العقد المركزي، بدون dual write أو واجهة منفصلة بقواعد متعارضة.

## 11. ما لم يتم تغييره عن قصد

لم يتم:

- تعديل `main.html` من طرف المساعد.
- تعديل `New-main`.
- تعديل `Current/PWA/main2`.
- إعادة بناء HR tables من الصفر.
- زرع بيانات موظفين أو رواتب تخمينية.
- إنشاء Edge Function إضافية موازية لمجرد وجود طلب عام بذلك، لأن البنية المركزية الآمنة موجودة أصلًا ولأن Production reached function cap.
- لمس العمليات الميدانية الأساسية أو مخزون RAWAEA.

## 12. لماذا لا تعتبر Mother HR مغلقة 100% بعد

Production HR Core أصبحت قابلة للاستخدام ومحصنة في النقاط التي تم إصلاحها، لكن **Mother UI نفسها تنتظر تطبيق الجراحة من المالك** ثم يجب إجراء browser E2E فعلي على الملف المنشور.

إذًا الحالة الصادقة الآن:

```text
Production HR infrastructure = READY / VERIFIED
HR core contract             = READY / VERIFIED
HR document write scope      = HARDENED / VERIFIED
Mother HR                    = OPEN / OWNER SURGERY REQUIRED
Browser E2E                  = OPEN
```

لا يجوز تحويل هذه الحالة إلى 100% Closed قبل تجربة الملف المنشور بالفعل.

## 13. Self-Audit النهائي

### What I Proved

- Source of Truth الحالي هو Mother في `erp-frontend`.
- Latest HEAD والـparent تم التحقق منهما.
- `forensic_main_assembly.yml` يشير إلى المصدر الصحيح.
- Mother HR الحالي يعتمد على العقد القديم.
- Production HR Core الحديثة موجودة وليست بحاجة إلى جداول مكررة.
- `hr_query` يعمل في Production.
- `hr_command_atomic` يعمل مع company isolation وactor binding وidempotency.
- إصلاح approve/cancel للإجازة تم نشره واختباره Transactionally.
- مستندات الموظفين تم تشديد WRITE scope لها.
- self-service وHR admin منفصلان في permission contract.
- بيانات HR الحالية للشركة شبه فارغة؛ لذلك لم يتم اختلاق بيانات.

### What I Did Not Prove

- لم يتم تشغيل browser E2E فعلي على متصفح المستخدم/Production Mother بعد تطبيق الجراحة.
- لم يتم إثبات payroll posting end-to-end ببيانات فعلية لأن Production لا تحتوي حاليًا على عقد/فترات/رواتب تشغيلية فعلية صالحة للاختبار دون اختلاق بيانات.
- لم يتم إثبات document upload end-to-end عبر browser لأن ذلك يحتاج ملفًا حقيقيًا من واجهة المستخدم.

### What I Fixed

- leave approval/cancel balance contract.
- HR command authenticated execution boundary.
- employee document INSERT/UPDATE scope.
- إعداد حزمة Mother HR كاملة للانتقال إلى HR Core.

### What I Initially Missed

التحقيق أظهر أن وجود HR tables/RPCs لا يعني أن Mother تستعملها. الفجوة الأساسية كانت **Consumer Drift** بين UI قديم وCore حديث.

### What Could Still Be Wrong

الـMother replacement يحتاج تطبيقًا حرفيًا ثم Browser E2E. كما يجب عند ظهور أي Console/HTTP/SQL error إعادة التحقيق في المصدر الحالي وProduction وليس الرجوع تلقائيًا إلى main2.

## 14. تعليمات البدء للمساعد التالي

ابدأ بهذا التسلسل ولا تغيره:

```text
1. لا تثق في Report230 أو CURRENT_STATE كحالة راهنة.
2. احصل على أحدث HEAD في erp-frontend والـdirect parent.
3. افتح CURRENT main.html نفسه.
4. تحقق أن RW_HR ما زال عند نفس boundary أم تغيّر بعد تطبيق المالك.
5. افحص CURRENT Production: hr_command_atomic + hr_query + HR tables + policies + realtime.
6. لا تعيد إصلاح leave approval/cancel أو document policy إذا كانت ما زالت كما أثبتها Production.
7. إذا كانت جراحة Mother لم تُطبق: اطلب فقط تنفيذها بالحذف الكامل من 23788 حتى 24064 حسب المصدر الحالي، باستخدام البديل المسجل في هذه الجلسة.
8. بعد تطبيق الجراحة شغّل JavaScript syntax check على الملف المجمع نفسه.
9. نفّذ Browser E2E: Login → HR → Dashboard → Employees → Employee 360 → Organization → Contract → Attendance → Leave → Request → Advance → Payroll → Documents.
10. بعد كل mutation أعد الاستعلام من Production في نفس closure cycle.
11. لا تستخدم بيانات اختبار دائمة؛ استخدم transaction/rollback أو identity تشغيلية آمنة.
12. لا تنشئ جدولًا أو Edge Function جديدًا قبل إثبات أنه مفقود فعليًا.
13. لا تستخدم app_settings LIMIT 1 في أي سياق company-bound.
14. لا تخلط HR Core مع عمليات Warehouse/Order/Runsheet/Field Operations.
15. بعد نجاح E2E فقط انتقل إلى فجوة HR التالية أو أعلن HR Mother مغلقًا.
```

## 15. الحالة النهائية لهذه الجلسة

```text
Historical reports           = reference only
Current source               = verified
Current Production HR Core   = verified
HR security boundary         = improved and verified
HR leave balance contract    = fixed and verified
HR document scope            = hardened and verified
Edge capacity                = full; no new HR Edge needed
Mother HR                    = surgically prepared, owner must apply
Browser E2E                  = next closure gate
Overall HR Mother            = OPEN pending owner surgery + E2E
```
