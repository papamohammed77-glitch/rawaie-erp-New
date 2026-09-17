# Report231 — HR Mother Execution Baseline

**Date:** 2026-09-17
**Scope:** RAWAEA ERP Mother System — Human Resources only
**Status:** FORENSIC BASELINE / NO GO FOR UI PATCH YET

## 1. Authority
This report records facts obtained from the current SMART ERP Supabase Production database during the active CTO investigation. Reports are evidence records, not substitutes for live verification.

## 2. Current Production Target
Supabase Production project:
- Name: `SMART ERP`
- Project ref: `fiilmooggumokxanwiyx`
- Region: `eu-west-1`
- PostgreSQL: `17.6.1.121`
- Project status: `ACTIVE_HEALTHY`

## 3. Live HR Table Inventory
The live Production database currently contains 25 HR-related tables inspected in the CTO query:

`employee_attendance`
`employee_documents`
`employee_leave_requests`
`employee_profiles`
`hr_attendance_events`
`hr_command_log`
`hr_contract_components`
`hr_contracts`
`hr_departments`
`hr_employee_assignments`
`hr_employee_schedule_assignments`
`hr_leave_balances`
`hr_leave_types`
`hr_payroll_accounting_map`
`hr_payroll_periods`
`hr_payroll_runs`
`hr_payslip_lines`
`hr_payslips`
`hr_positions`
`hr_request_approvals`
`hr_requests`
`hr_salary_advances`
`hr_salary_components`
`hr_work_entries`
`hr_work_schedules`

## 4. Live Production Row State
All 25 inspected HR tables currently contain **0 rows**.

Therefore the current Production HR state is structurally populated but has no HR operational/sample records.

## 5. Critical Confirmed Schema Facts
### `public.hr_attendance_events`
Confirmed fields include:
- `id uuid NOT NULL DEFAULT gen_random_uuid()`
- `company_id uuid NOT NULL`
- `employee_id uuid NOT NULL`
- `event_type text NOT NULL`
- `occurred_at timestamptz NOT NULL`
- `source text NOT NULL DEFAULT 'manual'`
- `device_id text NULL`
- `latitude numeric NULL`
- `longitude numeric NULL`
- `metadata jsonb NOT NULL DEFAULT '{}'`
- `operation_id text NOT NULL`
- `created_by text NULL`
- `created_at timestamptz NOT NULL DEFAULT now()`

**Important:** `operation_id` is present in the live Production attendance event table and must be considered before designing or adding any idempotency mechanism.

### `public.hr_requests`
Confirmed to contain `operation_id text NOT NULL`.

### `public.hr_salary_advances`
Confirmed to contain `operation_id text NOT NULL`.

### `public.hr_contracts`
Confirmed contract model includes employee, position, contract type, dates, status, pay cycle, currency, basic salary, allowances, default deduction, schedule, signed document, renewal notice and audit timestamps/actor fields.

### `public.hr_departments`
Confirmed company-scoped organization model with parent department and manager employee references.

### `public.hr_employee_assignments`
Confirmed company/employee/branch/department/position/manager assignment history with effective date range and primary flag.

### `public.hr_employee_schedule_assignments`
Confirmed employee-to-schedule assignments with effective date range.

### `public.hr_leave_types`
Confirmed leave policy model includes paid flag, annual quota, continuous-day limit, attachment requirement and half-day allowance.

### `public.hr_leave_balances`
Confirmed annual leave balance model includes opening, accrued, used and adjusted amounts.

### `public.hr_salary_components`
Confirmed configurable payroll component model with component type, calculation type, default value, taxability and pensionability.

### `public.hr_payroll_accounting_map`
Confirmed payroll accounting mapping model with expense and liability account references.

### `public.hr_payroll_periods`
Confirmed payroll period model with code, dates, pay date and lifecycle status.

### `public.hr_payroll_runs`
Confirmed payroll run model with period, run number, status, employee count, gross, deductions, net, journal entry reference and approval/posting fields.

### `public.hr_payslips`
Confirmed payslip model with payroll run, employee, contract, days, absence, leave, overtime, gross, deductions, net and status.

### `public.hr_payslip_lines`
Confirmed payslip line model with line code/name/type/amount/source/notes.

### `public.hr_work_entries`
Confirmed work-entry model with employee, date, type, hours, source/source_id, status and notes.

### `public.hr_work_schedules`
Confirmed schedule model includes timezone (`Africa/Cairo` default), weekly template, shift times, breaks, daily hours, grace, overtime multiplier, auto-checkout and active flag.

## 6. Immediate CTO Implication
The live HR database is not a four-table skeleton. It already contains a substantially expanded HR domain model, including:
- employee master/profile
- attendance events
- work entries
- organization/departments
- positions
- employee assignments
- work schedules
- leave types
- leave balances
- leave requests
- contracts
- salary components
- salary advances
- payroll periods/runs
- payslips/lines
- payroll accounting mapping
- documents
- approval requests/steps
- command log

The correct strategy is therefore **integration and closure of the existing HR platform**, not wholesale schema replacement.

## 7. Next Evidence Required
The following live Production evidence must be obtained before any HR command-core repair or UI patch:
1. Full definitions of all `public.hr_*` RPCs, especially `hr_command_atomic` and `hr_query`.
2. Live RLS policies and grants for all HR tables.
3. Live Realtime publication/table membership for HR tables.
4. Live Edge Functions list and source for HR-related functions.
5. Live database constraints, primary keys, unique indexes and foreign keys for HR tables.
6. Current `erp-frontend` mother-system HR block and exact `RW_HR` source boundaries.
7. Old `Current/PWA/main2/main11.md` as reference only.
8. Deployment/current HEAD and parent commit relationship for the mother system.

## 8. Execution Rule
No HR business rule is promoted from historical reports to current truth unless confirmed by current Git/source/Production/database/deployment evidence.

No production DDL or DML is authorized by this report.
