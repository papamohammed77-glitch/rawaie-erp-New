# RAWAEA ERP — CURRENT STATE

# LATEST VERIFIED SNAPSHOT — 2026-09-17 — HR LOGIN SURGICAL ROOT-CAUSE CLOSURE

> نقطة البدء للجلسة التالية: التقارير مرجعية، والحالة الحالية تُعاد مطابقتها مع Git وMother وProduction وDatabase وDeployment.

## 1. Git

### System repository
`papamohammed77-glitch/rawaie-erp-New`

Latest closure artifacts committed:
```text
c0f8a65c1f49babb56ef0df56911faef169f401b
 docs(hr): update current state after surgical login root-cause closure

aaf06a7988c7c7ecf58b79a93691ae18cd37bc67
 docs(hr): add exact payroll syntax surgical patch

7f97f28b1c6678e89e59081e66f2a8e08505c1e4
 docs(hr): record RW_HR login surgical closure
```

Relevant forensic commits:
```text
8c4b55a8cf3e13cfcafc44ddd86e0a0916222b17
3d368c830d3986e289d6c97b114967ea83cf6463
265e0b36e6196e4dee812a52a39a720c34d7efa2
ec6ac7c5889d0e4ff4fef849ca1cfda0a85a61ab
9b97ef495986e1d92a0448985fbb376f1b936a6f
```

### Mother repository
`papamohammed77-glitch/erp-frontend`

HEAD: `269d3fb7776005ae6c2d9431cf784bde4b434e92`
Parent: `2b8ef7a26716470020bb786566210c0c41a434dd`

`companies/company-1/main.html` was not modified by the forensic commits reviewed.

## 2. Mother current source evidence

Authoritative file:
`companies/company-1/main.html`

Persisted forensic extract:
`_forensic_current_main_extract.md`

```text
FILE_LINES=25374
FILE_BYTES=1462518
SHA256=ba703e44c5f55ddd55d73df9afed72273f4e64ae6fb76a593ad43d699922b954
RW_HR start=23788
RW_HR approximate end=24064
```

Current RW_HR contract:
```text
Authentication context → supabase.auth.getUser()
Application user       → public.users.auth_id
Reads                  → hr_query
Writes                 → hr_command_atomic
```

RW_HR is a routed application view, not the authentication engine.

## 3. Production HR Core

Supabase project: `fiilmooggumokxanwiyx`

Canonical read engine: `hr_query`
Canonical write engine: `hr_command_atomic`

Signature:
```text
hr_command_atomic(p_command text, p_payload jsonb, p_operation_id text, p_actor_user_id uuid, p_actor_email text)
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

Current captured HR business data remains empty; no fabricated HR seed data is approved.

## 5. Production hardening already applied

```text
20260917174950 — hr_core_request_leave_temporal_integrity_20260917_v3
20260917182812 — hr_runtime_hardening_r1
```

Confirmed:
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

Canonical complete replacement:
`doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`

SHA:
`d02050f9f8131156b5dc283d5229cb1ffff5e5fd`

Exact one-line surgical patch reference:
`doc/Draft/Reprots/HR_MOTHER_LOGIN_SYNTAX_SURGICAL_PATCH_20260917.diff`

Complete replacement aligned to:
```text
Reads → hr_query
Writes → hr_command_atomic
```

Capabilities:
```text
dashboard / employees / Employee 360 / organization / contracts
attendance / leaves / requests / advances / payroll / documents / realtime
```

## 8. CRITICAL — HR LOGIN ROOT CAUSE — 2026-09-17

Final report:
`doc/Draft/Reprots/Report237_RW_HR_LOGIN_SURGICAL_CLOSURE_20260917.md`

### Proven root cause

The login-blocking parser failure is an extra closing parenthesis in the `payrollTab` rendering expression inside the RW_HR block of the Mother monolithic script.

Defective:
```javascript
esc(x.status||'-')]))));
```

Correct:
```javascript
esc(x.status||'-')])));
```

The Tailwind CDN message is a production-hygiene warning, not the parser blocker.

### Critical distinction
```text
RW_HR itself ≠ authentication engine
```

But RW_HR is embedded inside the Mother monolithic JavaScript runtime. A syntax error inside RW_HR prevents the enclosing script from parsing/executing and can therefore block global login/bootstrap handlers.

## 9. Current closure status

```text
Production HR Core           = VERIFIED / HARDENED
HR DB contract               = VERIFIED at captured scope
HR legacy writers            = CLOSED as independent writers
Mother RW_HR source          = VERIFIED CURRENT EXTRACT
Login parser root cause      = IDENTIFIED / PROVEN
Surgical replacement         = READY
Artifact syntax guard        = PRESENT
Mother main.html cutover     = OPEN
Served artifact verification = OPEN
Authenticated browser E2E    = OPEN
Full HR browser E2E          = OPEN
Overall RW_HR                = NOT CLOSED YET
```

## 10. What is NOT approved

```text
No modification to main.html has been performed by this closure.
No Production HR migration is required for this JavaScript syntax incident.
No new HR table.
No new HR Edge Function.
No new authentication engine.
No fabricated HR business data.
No closure claim before browser verification.
```

## 11. Next-session protocol

```text
1. Verify latest System HEAD + parent.
2. Verify latest Mother HEAD + parent.
3. Open current Mother main.html authentication/bootstrap area.
4. Verify the RW_HR boundary against the canonical surgical artifact.
5. Replace ONLY the RW_HR block when the authorized cutover is executed.
6. Run full-file JavaScript syntax validation on the assembled main.html.
7. Prove no collateral main.html changes outside RW_HR.
8. Deploy through the approved Mother deployment path.
9. Verify served artifact identity/hash.
10. Run authenticated Login → Company Context → Application Shell.
11. Confirm absence of the SyntaxError.
12. Open HR and verify all HR tabs and Employee 360.
13. Verify realtime behavior.
14. Re-read Production after browser execution.
15. Check for unintended HR data, duplicate operations and tenant bleed.
16. Update CURRENT_STATE.md.
17. Add the final closure report.
18. Only then mark RW_HR CLOSED.
```

## 12. Governance

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
