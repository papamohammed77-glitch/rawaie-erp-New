# RAWAEA ERP — CURRENT STATE

# LATEST VERIFIED SNAPSHOT — 2026-09-17 — HR LOGIN FORENSIC RE-EXECUTION

> هذه الصفحة هي نقطة البدء للجلسة التالية. التقارير الأقدم مرجعية وليست مصدر الحقيقة الحالي. يجب إعادة التحقق من Git وMother وProduction وDatabase وDeployment عند بداية أي Closure جديد.

## 1. Git

### System repository

`papamohammed77-glitch/rawaie-erp-New`

آخر commit تم أثناء هذه الجلسة:

```text
3d368c830d3986e289d6c97b114967ea83cf6463
 docs(hr): record login blocker forensic non-causality
```

### Mother repository

`papamohammed77-glitch/erp-frontend`

HEAD:
`269d3fb7776005ae6c2d9431cf784bde4b434e92`

Parent:
`2b8ef7a26716470020bb786566210c0c41a434dd`

The latest Mother commits persisted forensic extracts only; `companies/company-1/main.html` was not modified by those two forensic commits.

## 2. Mother current source evidence

Authoritative file:

`companies/company-1/main.html`

Exact persisted forensic extract:

`_forensic_current_main_extract.md`

Evidence:

```text
FILE_LINES=25374
FILE_BYTES=1462518
SHA256=ba703e44c5f55ddd55d73df9afed72273f4e64ae6fb76a593ad43d699922b954
RW_HR start = 23788
```

Current RW_HR contract in the extracted Mother source:

```text
Authentication context → supabase.auth.getUser()
Application user       → public.users.auth_id
Reads                  → hr_query
Writes                 → hr_command_atomic
```

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

The command engine verifies actor/session/company and uses `hr_command_log` for operation identity/idempotency.

## 4. HR Production schema

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

Current captured HR business data remains empty; this is not treated as an authentication failure.

## 5. Production hardening already applied

```text
20260917174950 — hr_core_request_leave_temporal_integrity_20260917_v3
20260917182812 — hr_runtime_hardening_r1
```

Confirmed effects from prior verified evidence:

```text
Direct INSERT/UPDATE/DELETE/TRUNCATE grants on HR Core → 0 for anon/authenticated
Anon execution of legacy HR mutators → revoked
Legacy writer functions → compatibility adapters over hr_command_atomic
```

## 6. Previous HR verification

```text
hr_query read surface → 24 / 24 PASS
employee.profile.upsert → PASS then rollback
Legacy adapter runtime → PASS then rollback
Post-rollback HR business tables → 0
```

## 7. Surgical Mother replacement

Canonical replacement artifact:

`doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`

SHA:
`d02050f9f8131156b5dc283d5229cb1ffff5e5fd`

It is a complete RW_HR replacement and uses:

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

## 8. CRITICAL — HR LOGIN FORENSIC FINDING — 2026-09-17

New report:

`doc/Draft/Reprots/HR_LOGIN_FORENSIC_CLOSURE_20260917.md`

### Proven

The current Mother forensic extract shows `RW_HR` as a view-level module routed by `RW_Views`. The HR module itself begins at line 23788. It is not the authentication engine.

The current HR module resolves its actor from `supabase.auth.getUser()` and `public.users.auth_id`, then uses `hr_query` and `hr_command_atomic`.

The module has an internal render error boundary.

### NOT proven

It has NOT been proven that `RW_HR.render()` is awaited before the login-to-application-shell transition.

Therefore:

```text
RW_HR is NOT currently proven to be the cause of the login blocker.
```

No speculative HR patch was applied.

### Mandatory next investigation

The next target is the exact current authentication/bootstrap path in Mother:

```text
login submit
→ Supabase Auth sign-in
→ session/user resolution
→ application-user resolution
→ permissions
→ application-shell transition
→ initial view
```

Only after proving the call order may we determine whether HR participates in the login critical path.

## 9. Current closure status

```text
Production HR Core             = VERIFIED / HARDENED
HR DB contract                 = VERIFIED at captured scope
HR legacy writers              = CLOSED as independent writers
Mother RW_HR source            = VERIFIED CURRENT EXTRACT
Mother RW_HR login causality   = NOT PROVEN
Global login blocker           = OPEN / NOT YET LOCATED
main.html                      = UNTOUCHED
```

## 10. Next-session protocol

```text
1. Verify latest System HEAD + parent.
2. Verify latest Mother HEAD + parent.
3. Open current Mother main.html authentication/bootstrap block.
4. Prove exact RW_HR invocation order relative to login shell transition.
5. Capture first browser console/network error during login.
6. Correlate error to exact current source.
7. Patch only the proven cause; do not modify main.html directly unless explicitly authorized.
8. Re-run login E2E.
9. Re-run all HR tab E2E.
10. Re-read Production after browser execution.
11. Record evidence and update CURRENT_STATE.
```

## 11. Governance

```text
Reports are reference only.
CURRENT_STATE is a starting snapshot, not a substitute for live verification.
Do not infer current Production from old reports.
Do not infer browser behavior from SQL tests.
Do not repeat a historical repair without new live evidence.
Do not create duplicate HR tables.
Do not seed fabricated HR data.
Do not create a second HR command engine.
Do not declare closure without the required browser gate.
```
