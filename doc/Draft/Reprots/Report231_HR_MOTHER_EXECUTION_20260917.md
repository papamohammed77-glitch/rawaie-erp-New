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

## 6. Live Production HR RPC Evidence
The current Production database exposes these HR RPCs/functions under `public`:

- `hr_command_atomic(text,jsonb,text,uuid,text)` — `SECURITY DEFINER`.
- `hr_query(text,jsonb)` — `SECURITY DEFINER`.
- `hr_list_employees()` — `SECURITY DEFINER`.
- `hr_create_leave_request(uuid,text,date,date,text)` — `SECURITY DEFINER`.
- `hr_save_attendance(uuid,date,text,timestamptz,timestamptz,text)` — `SECURITY DEFINER`.
- `hr_set_leave_status(uuid,text,text)` — `SECURITY DEFINER`.
- `hr_upsert_employee_profile(uuid,text,text,text,date,text,numeric,numeric,numeric,numeric,numeric,text,text)` — `SECURITY DEFINER`.
- `hr_user_has_permission(uuid,text)` — `SECURITY DEFINER` and `STABLE`.
- `hr_payroll_calculate_impl(uuid,uuid,text)` — `SECURITY DEFINER`.
- `hr_payroll_post_impl(uuid,uuid,text)` — `SECURITY DEFINER`.
- `hr_touch_updated_at()` — trigger function, `SECURITY DEFINER`.

### `hr_command_atomic` — confirmed behavior
The live implementation is already a broad unified HR command boundary. It:
- derives company context from `public.users` using the actor user id;
- validates actor status and session identity unless execution is `service_role`;
- checks HR permission for administrative commands;
- supports command families for employee profile, organization, assignments, contracts, schedules, salary components, leave, attendance, requests, salary advances, payroll period/run, payroll accounting map and document metadata;
- persists command execution in `public.hr_command_log` using `operation_id` plus a payload hash;
- returns the stored result for a completed duplicate operation and detects idempotency conflicts;
- implements `attendance.event.record` against `public.hr_attendance_events` with `operation_id` idempotency and `ON CONFLICT(company_id,operation_id) DO NOTHING`;
- validates `attendance.event.record.occurred_at` as non-empty and parseable `timestamptz`;
- updates `public.employee_attendance` and `public.hr_work_entries` from attendance events;
- uses schedule assignment first, then active contract schedule as fallback;
- computes worked hours, late minutes, early-leave minutes and overtime hours;
- supports leave request create/approve/reject/cancel and adjusts leave balances on paid approved/cancelled flows;
- supports request approval steps;
- supports salary advances with approval/disbursement state changes;
- delegates payroll calculation/posting to `hr_payroll_calculate_impl` / `hr_payroll_post_impl`.

### `hr_query` — confirmed behavior
The live implementation already provides query views for:
- dashboard
- employees
- departments
- positions
- assignments
- contracts
- schedules
- schedule assignments
- attendance
- attendance events
- leaves
- leave balances
- requests
- request approvals
- advances
- salary components
- contract components
- payroll periods
- payroll runs
- payslips
- documents
- expiring documents
- payroll accounting map
- work entries
- leave types
- self-service employee view

It enforces company scope via `app_private.current_user_company_id()` and HR permission for management views, with self-service filtering for employee-scoped views.

### Critical forensic correction
The current live `hr_command_atomic` **already contains the previously reported attendance-event input validation and `operation_id` idempotency logic**. Therefore the historical note that this branch was necessarily still broken cannot be promoted to current truth without a fresh failing reproduction.

## 7. Current Mother Source Evidence
Current `erp-frontend` forensic extract confirms:
- current mother file logical size: **25,541 lines / 1,425,646 bytes**;
- current mother SHA256 snapshot: `e945c6244fcb7f8d85e1325a6f3d9fdd6965efb6f13bf340a85580eeefdc42ac`;
- `RW_HR` begins at mother source line **23,788** in the reviewed HEAD extract;
- `hr_list_employees` is called by the current HR UI at line **23,821**;
- current HR routing points the `hr` view to `RW_HR.render()`.

The current UI currently loads employees through `hr_list_employees()` and directly reads `employee_documents`, `employee_attendance`, and `employee_leave_requests` from the browser-side Supabase client in the reviewed HR block. Exact full HR block boundaries still require extraction beyond the truncated forensic window before producing a surgical replacement.

The old split file `Current/PWA/main2/main11.md` contains the same basic HR module shape and is reference material, not current truth.

## 8. Immediate CTO Implication
The live HR database is not a four-table skeleton. It already contains a substantially expanded HR domain model and a unified command/query core. The immediate work is therefore closure and integration, not schema rebuild.

The largest current source-level gap proven so far is that the mother HR UI remains thin compared with the live HR core: it uses the employee list plus direct browser queries for three subordinate data sets, while the live `hr_command_atomic`/`hr_query` already model a much broader HR capability surface.

This creates a likely architecture-consistency target for the mother UI, but no patch is approved until exact source boundaries and live security/RLS behavior are fully closed.

## 9. Evidence Still Required Before Patch
1. Live RLS policies and grants for all 25 HR tables.
2. Live Realtime publication membership for HR tables.
3. Exact live foreign keys, unique constraints and indexes for HR tables.
4. HR-related Edge Function inventory and exact current sources.
5. Exact `RW_HR` closing lines and export boundary in current `main.html` / forensic extract.
6. Exact old reference boundary in `main11.md` where useful.
7. Current deployment mapping for mother-system HEAD and parent commit.
8. Current Production E2E/behavior reproduction to identify the actual remaining failure, not a historical one.
9. Current competitor feature evidence only after internal current-state closure.

## 10. Execution Rule
No HR business rule is promoted from historical reports to current truth unless confirmed by current Git/source/Production/database/deployment evidence.

No production DDL/DML or UI patch is authorized by this report until the above evidence closure is complete.
