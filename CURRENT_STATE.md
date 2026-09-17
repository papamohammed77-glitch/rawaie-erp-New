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

## Production changes completed this session

### 1. Leave approval/cancel contract

Fixed in Production so:

- `leave_type_id` is handled as UUID.
- Paid leave approval consumes `hr_leave_balances.used`.
- Cancellation of an approved paid leave reverses the used balance.
- Insufficient balance is rejected.

Transactional E2E was executed and rolled back.

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

A direct attempt to deploy an HR Edge Function was rejected by the current Supabase function limit. Because `hr_command_atomic` already enforces actor/auth/company security, the chosen architecture is to use the authenticated RPC directly from Mother rather than add another endpoint or reuse unrelated canary/E2E functions.

## Production tests completed

- `hr_query` views were exercised transactionally from an HR session.
- HR command operations were exercised transactionally.
- Idempotency was exercised for the same operation identity.
- Self-service attendance for a non-HR employee succeeded for the employee themself.
- HR administrative profile mutation was protected from a non-HR actor.
- Leave approve/cancel balance reversal was tested.
- All temporary test records were rolled back.

## Mother HR surgical package

Prepared complete replacement artifact:

`HR_MOTHER_SURGICAL_REPLACEMENT_20260917.js`

The owner must apply it to the current Mother only.

Exact surgical boundary:

```text
Find:
var RW_HR = (function() {

Start line:
23788

Delete through the complete line:
window.RW_HR = RW_HR;

End line:
24064
```

Then paste the replacement artifact exactly.

The replacement consumes:

```text
hr_query
hr_command_atomic
```

and provides the unified Mother HR surface for:

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

The assistant did not modify `erp-frontend/main.html`.

## Session report

`doc/Draft/Reprots/Report230_HR_MOTHER_FORENSIC_CLOSURE_20260917.md`

Report commit:

`345786cf47adaea6c4646ab129a8fd0a915eca2d`

## Current status

```text
Historical reports        = reference only
Current source            = verified
Current Production HR     = verified
HR leave contract         = fixed / verified
HR command auth boundary  = hardened / verified
HR document write scope   = hardened / verified
HR tables                 = present / not to duplicate
HR Edge capacity          = full
Mother HR UI              = OPEN / owner surgery required
Mother browser E2E        = OPEN
Overall HR Mother         = NOT CLOSED YET
```

## Next session start protocol

Do not trust this file or Report230 as the current state by themselves.

Start again from live evidence in this order:

```text
1. Latest erp-frontend HEAD + direct parent.
2. Current Mother main.html.
3. Current RW_HR boundaries and whether owner already applied the replacement.
4. Current Production hr_command_atomic + hr_query definitions.
5. Current HR table/policy/realtime state.
6. Current Edge deployment evidence.
7. Compare only the facts just verified.
8. If replacement is not applied, use the exact 23788..24064 surgical boundary and the replacement artifact.
9. Run syntax validation on the assembled main.html.
10. Run browser E2E across every HR tab and Employee 360.
11. Verify every mutation again against Production in the same closure cycle.
12. Do not seed fabricated employee/contract/payroll data.
13. Do not return to main2 as a code source; it remains historical reference only.
14. Do not touch Warehouse/Order/Runsheet field operations while closing HR.
15. Only after browser E2E passes may HR Mother be marked CLOSED.
16. Then move to the next actually-open Business Contract.
```
