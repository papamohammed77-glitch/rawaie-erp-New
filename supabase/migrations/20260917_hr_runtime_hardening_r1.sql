-- RAWAEA ERP — HR runtime hardening R1 — 2026-09-17
-- Scope: HR only.
-- Purpose:
--   1) Correct the live hr_command_atomic leave-status row type so the approval/rejection/cancellation
--      branch compiles against the actual employee_leave_requests record contract.
--   2) Remove direct authenticated/anonymous DML capability from canonical HR Core tables so writes
--      are forced through hr_command_atomic rather than parallel table writers.
--   3) Remove anonymous execution from legacy employee HR mutators while preserving authenticated
--      compatibility until the Mother surgical cutover is proven.
-- This migration intentionally does not edit Mother main.html and does not fabricate HR data.

DO $do$
DECLARE
  v_sql text;
  v_old text := 'v_leave_status_before text;';
  v_new text := 'v_leave_status_before public.employee_leave_requests%ROWTYPE;';
  v_occ integer;
BEGIN
  SELECT pg_get_functiondef(p.oid)
    INTO v_sql
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'hr_command_atomic'
    AND pg_get_function_identity_arguments(p.oid) =
      'p_command text, p_payload jsonb, p_operation_id text, p_actor_user_id uuid, p_actor_email text';

  IF v_sql IS NULL THEN
    RAISE EXCEPTION 'Canonical hr_command_atomic overload not found';
  END IF;

  v_occ := (length(v_sql) - length(replace(v_sql, v_old, ''))) / length(v_old);

  IF v_occ = 0 THEN
    IF position(v_new in v_sql) > 0 THEN
      RETURN;
    END IF;
    RAISE EXCEPTION 'Expected leave-status declaration not found; refusing non-surgical rewrite';
  ELSIF v_occ <> 1 THEN
    RAISE EXCEPTION 'Expected exactly one leave-status declaration, found %; refusing non-surgical rewrite', v_occ;
  END IF;

  v_sql := replace(v_sql, v_old, v_new);
  EXECUTE v_sql;
END
$do$;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE
  public.hr_departments,
  public.hr_positions,
  public.hr_employee_assignments,
  public.hr_employee_schedule_assignments,
  public.hr_work_schedules,
  public.hr_attendance_events,
  public.hr_work_entries,
  public.hr_leave_types,
  public.hr_leave_balances,
  public.hr_requests,
  public.hr_request_approvals,
  public.hr_salary_advances,
  public.hr_salary_components,
  public.hr_contracts,
  public.hr_contract_components,
  public.hr_payroll_periods,
  public.hr_payroll_runs,
  public.hr_payslips,
  public.hr_payslip_lines,
  public.hr_payroll_accounting_map,
  public.hr_command_log
FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE
  public.employee_profiles,
  public.employee_attendance,
  public.employee_leave_requests
FROM anon, authenticated;

GRANT SELECT ON TABLE
  public.hr_departments,
  public.hr_positions,
  public.hr_employee_assignments,
  public.hr_employee_schedule_assignments,
  public.hr_work_schedules,
  public.hr_attendance_events,
  public.hr_work_entries,
  public.hr_leave_types,
  public.hr_leave_balances,
  public.hr_requests,
  public.hr_request_approvals,
  public.hr_salary_advances,
  public.hr_salary_components,
  public.hr_contracts,
  public.hr_contract_components,
  public.hr_payroll_periods,
  public.hr_payroll_runs,
  public.hr_payslips,
  public.hr_payslip_lines,
  public.hr_payroll_accounting_map,
  public.hr_command_log
TO authenticated;

GRANT SELECT ON TABLE
  public.employee_profiles,
  public.employee_attendance,
  public.employee_leave_requests
TO authenticated;

REVOKE ALL ON FUNCTION public.hr_create_leave_request(uuid,text,date,date,text) FROM anon;
REVOKE ALL ON FUNCTION public.hr_save_attendance(uuid,date,text,timestamptz,timestamptz,text) FROM anon;
REVOKE ALL ON FUNCTION public.hr_set_leave_status(uuid,text,text) FROM anon;
REVOKE ALL ON FUNCTION public.hr_upsert_employee_profile(uuid,text,text,text,date,text,numeric,numeric,numeric,numeric,numeric,text,text) FROM anon;
