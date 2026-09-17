# RAWAEA ERP — CURRENT STATE

## 2026-09-17 — Mother HR Forensic / Production Core Closure

### Current Source of Truth

The authoritative Mother file remains:

`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments under `Current/PWA/main2` are reference-only. `New-main` remains out of scope.

### Current Git baseline verified

`erp-frontend` latest HEAD:

`269d3fb7776005ae6c2d9431cf784bde4b434e92`

Direct parent:

`2b8ef7a26716470020bb786566210c0c41a434dd`

The two latest commits were forensic extraction commits; no functional Mother HR rewrite was inferred from them.

### Assembly governance

`forensic_main_assembly.yml` was verified and already points to:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

No change required.

## Mother HR — current verified source

Current `RW_HR` block in Mother:

- start: `var RW_HR = (function() {` around line `23788`
- end: `window.RW_HR = RW_HR;` around line `24064`

Current block is a legacy/basic HR consumer using:

`hr_list_employees`, `hr_upsert_employee_profile`, `hr_save_attendance`, `hr_create_leave_request`, `hr_set_leave_status`, plus direct legacy HR table reads/writes.

It does not consume the modern HR Core contract.

## Production HR — verified current infrastructure

Production project: `fiilmooggumokxanwiyx`

Modern HR schema exists already:

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

Realtime publication already includes the HR tables. No duplicate HR table family was created.

Current company `00000000-0000-0000-0000-000000000001` has 24 users but no active HR profile/contract/attendance/leave/payroll/document records to seed safely without real business data.

## Production HR core verified

`hr_query` provides current dashboard and HR views.

`hr_command_atomic` is the central authenticated write contract and now has execution granted to `authenticated` and `service_role`, with public/anon revoked.

The command contract derives company from the actor and checks authenticated actor identity. It also uses `hr_command_log` for operation identity/idempotency.

## Production changes completed in earlier HR closure sequence

### 1. Leave approval/cancel contract

Previously fixed in Production so:

- `leave_type_id` is handled as UUID.
- Paid leave approval consumes `hr_leave_balances.used`.
- Cancellation of an approved paid leave reverses the used balance.
- Insufficient balance is rejected.

### 2. HR command authenticated boundary

Applied:

```sql
REVOKE ALL ON FUNCTION public.hr_command_atomic(text,jsonb,text,uuid,text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.hr_command_atomic(text,jsonb,text,uuid,text)
TO authenticated, service_role;
```

### 3. Employee document write scope

INSERT/UPDATE policies on `employee_documents` were hardened so writing is allowed only to HR or to the employee themself, within company scope.

### 4. No new HR Edge Function

The selected HR architecture remains direct authenticated RPC consumption. No HR Edge Function was added.

## 2026-09-17 — Current RW_HR closure update

### Production migration applied

Live migration registry contains:

```text
20260917174950
hr_core_request_leave_temporal_integrity_20260917_v3
```

Canonical Git migration file:

`supabase/migrations/20260917_hr_core_request_leave_temporal_integrity.sql`

Commit:

`2aa3f2de01e8c1921b3368cf70c4f4cf5a9a4204`

### New Production command capabilities closed

`hr_command_atomic` now contains the following additional contract closures:

```text
request.create
leave.request.approve
leave.request.reject
leave.request.cancel
```

The same Production function also contains the strengthened request final-step semantics and effective-dated integrity guards.

### Request creation contract

Validated centrally:

- employee belongs to actor company;
- employee is active;
- request type and subject are present;
- at least one approval step exists;
- steps are sequential;
- each step has an explicit employee approver or role;
- explicit approvers belong to the same company and are active;
- parent request and approval-step records are created by the command engine;
- operation identity is preserved through `hr_command_log`.

### Leave lifecycle contract

Approved/rejected/cancelled states are now explicit central commands.

Paid leave consumes and reverses `hr_leave_balances.used` by calendar year, with overlap and insufficient-balance guards.

### Effective-dated integrity

The central command now rejects:

- overlapping primary employee assignments;
- overlapping employee schedule assignments;
- invalid contract date ranges;
- negative contract salary/allowance/deduction values;
- overlapping active contracts for the same employee with different contract numbers.

### Post-deployment structural verification

Current Production verification returned:

```text
hr_command_atomic overloads = 1
request.create           = present
leave lifecycle          = present
final-step cap           = present
authenticated EXECUTE    = true
service_role EXECUTE     = true
anon EXECUTE             = false
```

Current `hr_command_atomic` PostgreSQL definition length check:

```text
56106
```

### Current HR data integrity snapshot

All HR business tables remain empty:

```text
employee_profiles                    = 0
employee_attendance                  = 0
employee_leave_requests             = 0
employee_documents                  = 0
hr_departments                       = 0
hr_positions                        = 0
hr_employee_assignments             = 0
hr_employee_schedule_assignments    = 0
hr_work_schedules                    = 0
hr_attendance_events                = 0
hr_work_entries                     = 0
hr_leave_types                       = 0
hr_leave_balances                   = 0
hr_requests                         = 0
hr_request_approvals                = 0
hr_salary_advances                  = 0
hr_salary_components                = 0
hr_contracts                        = 0
hr_contract_components              = 0
hr_payroll_periods                  = 0
hr_payroll_runs                     = 0
hr_payslips                         = 0
hr_payslip_lines                    = 0
hr_payroll_accounting_map           = 0
hr_command_log                      = 0
```

No fabricated HR business data remains in Production.

### Current Mother surgical package

Final replacement artifact:

`doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js`

Blob SHA:

`d02050f9f8131156b5dc283d5229cb1ffff5e5fd`

The replacement is intended to replace ONLY the current Mother `RW_HR` block.

Exact current surgical boundary:

```text
Start:
var RW_HR = (function() {

End:
window.RW_HR = RW_HR;
```

Approximate source range:

```text
23788 .. 24064
```

The assistant did not modify Mother `main.html`.

### Current RW_HR capability surface in replacement

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

Reads use `hr_query`.

Mutations use `hr_command_atomic`.

No second HR command engine is introduced.

### Competitive benchmark incorporated

The final HR report compares current RAWAEA capabilities with documented capabilities in:

```text
Odoo
Microsoft Dynamics 365 Human Resources
SAP SuccessFactors
Daftra
Manager.io
```

Current target is a competitive Core HR baseline, not an invented claim of complete HCM parity.

Explicit roadmap gaps remain for areas such as recruiting/onboarding, performance, training/certification, advanced benefits, advanced accrual/carryover, statutory/local payroll rules, advanced cross-midnight policy handling, commission-to-payroll linkage, and dedicated Employee/Manager ESS surfaces.

These were not implemented without an explicit business/data contract.

## Current Production runtime verification boundary

### Proven in Production

- current HR schema;
- current `hr_command_atomic` signature and single-overload state;
- new request and leave command branches present;
- final-step state cap;
- authenticated/service-role execution boundary;
- anon denial;
- HR data remains empty/no fabricated seeds;
- document storage security policies remain tenant-aware;
- migration registry contains the applied HR closure migration.

### Not proven yet

A real authenticated browser E2E for the newly changed branches has not been completed in this session.

The Mother `main.html` remains intentionally untouched.

Therefore:

```text
Production structural verification = PASS
Production authenticated runtime E2E = OPEN
Mother browser E2E = OPEN
```

These must not be collapsed into a false 100% runtime closure.

## Session report

Final report:

`doc/Draft/Reprots/Report233_HR_FULL_COMPETITIVE_CLOSURE_20260917.md`

Commit:

`489807f777c8578dfe5fca4294ece634e02b3f89`

## Current status

```text
Historical reports              = reference only
Current Git baseline            = verified
Current Mother source           = verified
Current Production HR Core      = structurally closed for this contract
Current HR command contract     = single canonical engine
Current HR data                 = clean / no fabricated records
HR surgical replacement         = READY
Mother main.html                = UNTOUCHED BY DESIGN
Mother browser E2E              = OPEN
Legacy HR RPC retirement        = OPEN UNTIL CUTOVER PROOF
Overall RW_HR Mother            = NOT CLOSED YET
```

## Next session start protocol

Do not trust this file or Report233 as the current state by themselves.

Start again from live evidence in this order:

```text
1. Latest rawaie-erp-New HEAD and direct parent.
2. Latest erp-frontend HEAD and direct parent.
3. Current Mother main.html.
4. Current RW_HR boundary and current assembled code.
5. Confirm whether HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js was applied.
6. Verify current Production hr_command_atomic and hr_query definitions again.
7. Verify current HR schema, RLS, storage and realtime state.
8. Run syntax validation on the assembled Mother source.
9. Run browser E2E with a real authenticated HR session across every HR tab.
10. Run Employee 360 and all write modals.
11. Exercise request multi-step approval.
12. Exercise leave approve/reject/cancel and balance reversal.
13. Exercise assignment/schedule/contract temporal guards.
14. Exercise attendance event/day and payroll lifecycle.
15. Exercise document upload and signed-open flow.
16. Re-read Production immediately after browser execution.
17. Verify no duplicate records and no orphan storage files.
18. Only after consumer proof, retire legacy HR RPC execution surfaces that are no longer needed.
19. Re-run security advisors and record remaining HR findings.
20. Update this file and add the next report.
21. Mark RW_HR Mother CLOSED only after authenticated browser E2E passes.
```

The next session must not restart HR design.

It must prove the existing surgical package against the live Mother and live Production contract, then close only the remaining verified gaps.
