# RAWAEA ERP — CURRENT STATE

# LATEST VERIFIED SNAPSHOT — 2026-09-17 — RW_HR FORENSIC RE-EXECUTION

> هذه الصفحة هي نقطة البدء للجلسة التالية. التقارير الأقدم مرجعية وليست مصدر الحقيقة الحالي. يجب إعادة التحقق من Git وMother وProduction وDatabase وDeployment عند بداية أي Closure جديد.

## 1. Git

### System repository

`papamohammed77-glitch/rawaie-erp-New`

آخر commits في تسلسل RW_HR:

```text
11b74a8f4fa57006595bbb155f8db4d7a48d42d8
 docs(hr): record canonical legacy adapter closure

2b310539e7b5999d8475010a0452b262ef3e3ae0
 chore(hr): canonicalize HR runtime hardening migration

083e52b9866d92eb6cd57583f06b38958b8795c8
 docs(hr): update current state after 2026-09-17 RW_HR closure

489807f777c8578dfe5fca4294ece634e02b3f89
 docs(hr): add full competitive HR closure and next-session evidence

e4a13bd7743b1d5820b85973d5c60e4b83dc1162
 HR Mother surgical replacement FINAL — modal resilience and complete UX closure
```

### Mother repository

`papamohammed77-glitch/erp-frontend`

HEAD:
`269d3fb7776005ae6c2d9431cf784bde4b434e92`

Parent:
`2b8ef7a26716470020bb786566210c0c41a434dd`

`main.html` لم يتم تعديله في هذه السلسلة.

## 2. Mother RW_HR source

Authoritative file:

`companies/company-1/main.html`

RW_HR boundary:

```text
Start: var RW_HR = (function() {
End:   window.RW_HR = RW_HR;
Approx. lines: 23788 .. 24064
```

الحالة الحالية للـMother: **Legacy Consumer**.

الوظائف التاريخية التي ما زال يستدعيها:

```text
hr_list_employees
hr_upsert_employee_profile
hr_save_attendance
hr_create_leave_request
hr_set_leave_status
```

ولديه أيضًا legacy direct-table behavior.

## 3. Production HR Core

Supabase project:

`fiilmooggumokxanwiyx`

Canonical read engine:

`hr_query`

Canonical write engine:

`hr_command_atomic`

Current command signature:

```text
hr_command_atomic(
  p_command text,
  p_payload jsonb,
  p_operation_id text,
  p_actor_user_id uuid,
  p_actor_email text
)
```

Overloads:
`1`

الـcommand engine يتحقق من actor/session/company ويستخدم `hr_command_log` للـoperation identity/idempotency.

## 4. HR schema موجود فعليًا في Production

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

لا توجد عائلة HR ثانية أُنشئت أثناء هذه المهمة.

## 5. Current Production data

جميع HR business tables حاليًا = `0` records.

لا توجد بيانات موظفين أو عقود أو إجازات أو رواتب أو طلبات أو مستندات مصطنعة في Production.

`dashboard.employees` قد يعكس `users` الحاليين، وهذا ليس بديلًا عن `employee_profiles`.

## 6. Production changes actually applied

### Migration 1

`20260917174950`
`hr_core_request_leave_temporal_integrity_20260917_v3`

### Migration 2

`20260917182812`
`hr_runtime_hardening_r1`

نتائجها:

```text
hr_command_atomic leave-state variable
→ public.employee_leave_requests%ROWTYPE

Direct INSERT/UPDATE/DELETE/TRUNCATE grants on HR Core
→ 0 for anon/authenticated

Direct DML grants on employee_profiles/employee_attendance/employee_leave_requests
→ 0 for anon/authenticated

Anon execution of legacy HR mutators
→ revoked
```

## 7. Legacy writer closure

وظائف Mother القديمة لم تُحذف حتى لا ينكسر الـconsumer الحالي.

لكنها الآن Compatibility Adapters فوق Core واحد:

```text
hr_upsert_employee_profile
→ hr_command_atomic('employee.profile.upsert', ...)

hr_save_attendance
→ hr_command_atomic('attendance.day.upsert', ...)

hr_create_leave_request
→ hr_command_atomic('leave.request.create', ...)

hr_set_leave_status
→ hr_command_atomic('leave.request.approve' / 'leave.request.reject', ...)
```

لم تعد هذه الوظائف تنفذ HR table mutation مستقلة.

Canonical adapter source:

`doc/Draft/Reprots/HR_LEGACY_ADAPTERS_20260917.sql`

## 8. Production verification

### Read surface

`hr_query` views exercised under authenticated HR context:

```text
24 / 24 PASS
```

وشملت:

```text
dashboard
employees
departments
positions
assignments
schedules
contracts
contract_components
attendance
attendance_events
leaves
leave_balances
leave_types
requests
request_approvals
advances
payroll_periods
payroll_runs
salary_components
payroll_accounting_map
payslips
documents
documents_expiring
work_entries
```

### Central write runtime

`employee.profile.upsert`:
`PASS` ثم rollback.

`leave.request.approve` على request غير موجود:

```text
HR_COMMAND_ERROR
طلب الإجازة غير موجود ضمن الشركة الحالية
```

وهذا يثبت وصول branch إلى business validation بعد تصحيح record type.

### Legacy adapter runtime

اختُبرت الوظائف الأربع تحت authenticated HR context:

```text
hr_upsert_employee_profile  PASS
hr_save_attendance           PASS
hr_create_leave_request      PASS
hr_set_leave_status          PASS
```

ثم rollback.

بعد rollback:

```text
employee_profiles       = 0
employee_attendance     = 0
employee_leave_requests = 0
hr_command_log          = 0
```

## 9. Surgical Mother replacement

الملف الكامل الجاهز:

`doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`

SHA:
`d02050f9f8131156b5dc283d5229cb1ffff5e5fd`

Size:
`49,416 bytes`

هذه هي **Complete replacement** وليست دوال مختصرة.

الاستخدام:

```text
استبدال RW_HR فقط داخل main.html.
عدم لمس أي جزء آخر من main.html.
```

الـreplacement يستعمل:

```text
Reads     → hr_query
Mutations → hr_command_atomic
```

Capabilities:

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

## 10. Competitive benchmark

تمت مطابقة Core HR الحالي مع القدرات الموثقة الحالية في:

```text
Odoo
Microsoft Dynamics 365 Human Resources
SAP SuccessFactors Employee Central
Daftra
Manager.io
```

المنافسة استُخدمت كـbenchmark وظيفي لا كترتيب.

الفجوات الطبيعية المفتوحة للـroadmap:

```text
Recruiting / ATS
Onboarding / Offboarding full workflow
Performance / Appraisal
Learning / Training / Certifications
Skills inventory
Benefits eligibility / enrollment
Advanced leave accrual / carryover / tiered plans
Public holiday engine
Egypt / Saudi statutory payroll localization
Biometric / geofence integrations
Dedicated Employee Self Service
Dedicated Manager Self Service
Advanced workforce analytics
Advanced cross-midnight attendance rules
Commission-to-payroll advanced integration
```

لا تُنفذ هذه الفجوات بالتخمين دون domain/data contract.

## 11. Current closure status

```text
Production HR schema                 = VERIFIED
hr_query                             = VERIFIED
hr_command_atomic                    = VERIFIED
HR tenant/security core              = HARDENED
HR direct client DML                 = 0 / CLOSED
Legacy independent HR writers        = CLOSED
Legacy RPC consumer adapters         = ACTIVE / CORE DELEGATES
Mother RW_HR                         = LEGACY / NOT CUT OVER
Full surgical replacement            = READY
main.html                            = UNTOUCHED
Authenticated DB QA                  = PASS for exercised boundaries
Authenticated browser E2E             = OPEN
Overall RW_HR                         = NOT CLOSED YET
```

## 12. Final open gate

الشيء الوحيد الذي لا يجوز اعتباره مثبتًا بعد هو Browser E2E على Mother بعد تركيب replacement.

يجب إثبات فعليًا داخل Browser:

```text
login
all HR tabs
Employee 360
all modals
employee profile write
organization write
contracts
attendance day/events
leave create/approve/reject/cancel
multi-step requests
advances
payroll lifecycle where live accounting config permits
documents upload/metadata/signed-open/recovery
realtime UI refresh
```

لا يجوز تحويل DB-level PASS إلى Browser PASS.

## 13. Next-session execution protocol

```text
1. Verify latest system HEAD + direct parent.
2. Verify latest Mother HEAD + direct parent.
3. Open Mother main.html directly.
4. Locate RW_HR boundary again.
5. Verify whether the full surgical replacement is installed.
6. If not installed, replace ONLY RW_HR with HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js.
7. Run syntax validation on the assembled main.html.
8. Open a real authenticated HR browser session.
9. Run every HR tab.
10. Run Employee 360.
11. Run every write modal.
12. Test request multi-step approval/rejection.
13. Test leave create/approve/reject/cancel and balance reversal.
14. Test assignment/schedule/contract temporal guards.
15. Test attendance event/day and work-entry behavior.
16. Test advances.
17. Test payroll only against real configured accounting data.
18. Test document upload + metadata + signed-open + failure cleanup.
19. Test realtime browser refresh.
20. Re-read Production immediately after browser execution.
21. Check duplicates, orphan records, orphan storage.
22. Confirm legacy adapters still delegate only to hr_command_atomic.
23. Retire adapters only after Mother cutover and consumer proof.
24. Re-run security checks.
25. Add next HR report.
26. Update CURRENT_STATE again.
27. Mark RW_HR CLOSED only after all browser gates PASS.
```

## 14. Governance rules

```text
Reports are reference only.
CURRENT_STATE is a starting snapshot, not a substitute for live verification.
Do not infer current Production from old reports.
Do not infer browser behavior from SQL tests.
Do not repeat a historical repair without new live evidence.
Do not touch main.html outside RW_HR.
Do not create duplicate HR tables.
Do not seed fabricated HR data.
Do not create a second HR command engine.
Do not declare 100% closure before authenticated browser E2E.
```

## 15. Canonical artifacts

```text
doc/Draft/Reprots/Report234_RW_HR_FORENSIC_REEXECUTION_FULL_20260917.md

doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js

doc/Draft/Reprots/HR_LEGACY_ADAPTERS_20260917.sql

supabase/migrations/20260917_hr_runtime_hardening_r1.sql

supabase/migrations/20260917_hr_core_request_leave_temporal_integrity.sql
```

## 16. Final self-audit

### Proven

```text
Current system Git baseline
Current Mother Git baseline
Current Mother RW_HR boundary
Current Production HR schema
Current hr_query
Current hr_command_atomic
Current HR security boundary
Current HR direct DML = 0
Current legacy adapter routing
Current 24/24 HR read surface
Current DB-level mutation tests
Current HR data cleanliness
Current full surgical replacement
Competitive benchmark baseline
```

### Not proven

```text
Real authenticated browser E2E after replacement
Full DOM behavior after cutover
Browser storage upload lifecycle
Browser realtime lifecycle
Full payroll E2E with live accounting data
Final retirement of adapters after cutover
```

### Final decision

```text
GLOBAL HR CORE INTEGRITY = HARDENED / CLOSED AT CORE LEVEL
RW_HR MOTHER = OPEN UNTIL AUTHENTICATED BROWSER CUTOVER
OVERALL RW_HR = NOT CLOSED YET
```

This snapshot supersedes older HR state only where it records a newer verified fact. Historical records remain preserved for traceability.
