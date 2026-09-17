-- RAWAEA ERP — HR legacy adapter closure — 2026-09-17
-- Legacy HR mutation RPCs remain callable by the current Mother consumer,
-- but delegate to the canonical hr_command_atomic engine.
-- They do not perform direct HR table mutation.

CREATE OR REPLACE FUNCTION public.hr_upsert_employee_profile(p_employee_id uuid,p_employee_number text DEFAULT NULL,p_department text DEFAULT NULL,p_job_title text DEFAULT NULL,p_hire_date date DEFAULT NULL,p_employment_type text DEFAULT NULL,p_basic_salary numeric DEFAULT 0,p_housing_allowance numeric DEFAULT 0,p_transport_allowance numeric DEFAULT 0,p_other_allowance numeric DEFAULT 0,p_default_deduction numeric DEFAULT 0,p_status text DEFAULT 'active',p_notes text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid:=app_private.current_user_company_id(); v_actor public.users%ROWTYPE; v_payload jsonb; v_operation_id text;
BEGIN
 IF v_company_id IS NULL OR auth.uid() IS NULL THEN RAISE EXCEPTION 'جلسة HR غير صالحة'; END IF;
 SELECT * INTO v_actor FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id AND u.status IS DISTINCT FROM 'Inactive' LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم الحالية غير صالحة'; END IF;
 v_payload:=jsonb_build_object('employee_id',p_employee_id,'employee_number',p_employee_number,'department',p_department,'job_title',p_job_title,'hire_date',p_hire_date,'employment_type',p_employment_type,'basic_salary',coalesce(p_basic_salary,0),'housing_allowance',coalesce(p_housing_allowance,0),'transport_allowance',coalesce(p_transport_allowance,0),'other_allowance',coalesce(p_other_allowance,0),'default_deduction',coalesce(p_default_deduction,0),'status',coalesce(p_status,'active'),'notes',p_notes);
 v_operation_id:='LEGACY-HR:employee.profile.upsert:'||v_company_id::text||':'||md5(v_payload::text);
 RETURN public.hr_command_atomic('employee.profile.upsert',v_payload,v_operation_id,v_actor.id,v_actor.email);
END;$function$;

CREATE OR REPLACE FUNCTION public.hr_save_attendance(p_employee_id uuid,p_attendance_date date,p_status text DEFAULT 'present',p_check_in timestamptz DEFAULT NULL,p_check_out timestamptz DEFAULT NULL,p_notes text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid:=app_private.current_user_company_id(); v_actor public.users%ROWTYPE; v_payload jsonb; v_operation_id text;
BEGIN
 IF v_company_id IS NULL OR auth.uid() IS NULL THEN RAISE EXCEPTION 'جلسة HR غير صالحة'; END IF;
 SELECT * INTO v_actor FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id AND u.status IS DISTINCT FROM 'Inactive' LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم الحالية غير صالحة'; END IF;
 v_payload:=jsonb_build_object('employee_id',p_employee_id,'attendance_date',p_attendance_date,'status',coalesce(p_status,'present'),'check_in',p_check_in,'check_out',p_check_out,'notes',p_notes,'source','legacy_adapter');
 v_operation_id:='LEGACY-HR:attendance.day.upsert:'||v_company_id::text||':'||md5(v_payload::text);
 RETURN public.hr_command_atomic('attendance.day.upsert',v_payload,v_operation_id,v_actor.id,v_actor.email);
END;$function$;

CREATE OR REPLACE FUNCTION public.hr_create_leave_request(p_employee_id uuid,p_leave_type text,p_start_date date,p_end_date date,p_reason text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid:=app_private.current_user_company_id(); v_actor public.users%ROWTYPE; v_payload jsonb; v_operation_id text;
BEGIN
 IF v_company_id IS NULL OR auth.uid() IS NULL THEN RAISE EXCEPTION 'جلسة HR غير صالحة'; END IF;
 SELECT * INTO v_actor FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id AND u.status IS DISTINCT FROM 'Inactive' LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم الحالية غير صالحة'; END IF;
 v_payload:=jsonb_build_object('employee_id',p_employee_id,'leave_type',p_leave_type,'start_date',p_start_date,'end_date',p_end_date,'reason',p_reason);
 v_operation_id:='LEGACY-HR:leave.request.create:'||v_company_id::text||':'||md5(v_payload::text);
 RETURN public.hr_command_atomic('leave.request.create',v_payload,v_operation_id,v_actor.id,v_actor.email);
END;$function$;

CREATE OR REPLACE FUNCTION public.hr_set_leave_status(p_leave_request_id uuid,p_status text,p_notes text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid:=app_private.current_user_company_id(); v_actor public.users%ROWTYPE; v_command text; v_payload jsonb; v_operation_id text;
BEGIN
 IF v_company_id IS NULL OR auth.uid() IS NULL THEN RAISE EXCEPTION 'جلسة HR غير صالحة'; END IF;
 SELECT * INTO v_actor FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id AND u.status IS DISTINCT FROM 'Inactive' LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم الحالية غير صالحة'; END IF;
 v_command:=CASE lower(coalesce(p_status,'')) WHEN 'approved' THEN 'leave.request.approve' WHEN 'rejected' THEN 'leave.request.reject' ELSE NULL END;
 IF v_command IS NULL THEN RAISE EXCEPTION 'حالة الإجازة غير مدعومة'; END IF;
 v_payload:=jsonb_build_object('leave_request_id',p_leave_request_id,'notes',p_notes,'reason',p_notes);
 v_operation_id:='LEGACY-HR:'||v_command||':'||v_company_id::text||':'||p_leave_request_id::text||':'||md5(v_payload::text);
 RETURN public.hr_command_atomic(v_command,v_payload,v_operation_id,v_actor.id,v_actor.email);
END;$function$;

REVOKE EXECUTE ON FUNCTION public.hr_upsert_employee_profile(uuid,text,text,text,date,text,numeric,numeric,numeric,numeric,numeric,text,text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.hr_save_attendance(uuid,date,text,timestamptz,timestamptz,text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.hr_create_leave_request(uuid,text,date,date,text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.hr_set_leave_status(uuid,text,text) FROM anon;
GRANT EXECUTE ON FUNCTION public.hr_upsert_employee_profile(uuid,text,text,text,date,text,numeric,numeric,numeric,numeric,numeric,text,text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hr_save_attendance(uuid,date,text,timestamptz,timestamptz,text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hr_create_leave_request(uuid,text,date,date,text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.hr_set_leave_status(uuid,text,text) TO authenticated, service_role;
