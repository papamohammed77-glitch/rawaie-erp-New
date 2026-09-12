BEGIN;

CREATE OR REPLACE FUNCTION public.hr_set_leave_status(
    p_leave_request_id uuid,
    p_status text,
    p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_company_id uuid;
    v_actor_email text;
    v_request public.employee_leave_requests%ROWTYPE;
BEGIN
    v_company_id := app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN
        RAISE EXCEPTION 'غير مصرح بإدارة الإجازات';
    END IF;
    IF p_status NOT IN ('approved','rejected') THEN
        RAISE EXCEPTION 'حالة الإجازة غير مدعومة';
    END IF;
    SELECT * INTO v_request
    FROM public.employee_leave_requests
    WHERE id=p_leave_request_id AND company_id=v_company_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'طلب الإجازة غير موجود ضمن الشركة الحالية';
    END IF;
    IF v_request.status <> 'pending' THEN
        RAISE EXCEPTION 'لا يمكن تغيير حالة طلب غير معلق';
    END IF;
    SELECT u.email INTO v_actor_email
    FROM public.users u
    WHERE u.auth_id=auth.uid()
      AND u.company_id=v_company_id
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
    UPDATE public.employee_leave_requests
    SET status=p_status,
        approved_by=v_actor_email,
        approved_at=now(),
        notes=COALESCE(p_notes,notes),
        updated_at=now()
    WHERE id=v_request.id
      AND company_id=v_company_id
      AND status='pending';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'فشل تحديث حالة طلب الإجازة';
    END IF;
    RETURN jsonb_build_object('success',true,'leave_request_id',v_request.id,'status',p_status,'approved_by',v_actor_email);
END;
$function$;

REVOKE ALL ON FUNCTION public.hr_set_leave_status(uuid,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hr_set_leave_status(uuid,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.hr_save_attendance(
    p_employee_id uuid,
    p_attendance_date date,
    p_status text DEFAULT 'present',
    p_check_in timestamptz DEFAULT NULL,
    p_check_out timestamptz DEFAULT NULL,
    p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid; v_id uuid; v_actor_email text;
BEGIN
    v_company_id:=app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN RAISE EXCEPTION 'غير مصرح بإدارة الحضور والانصراف'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=p_employee_id AND u.company_id=v_company_id) THEN RAISE EXCEPTION 'الموظف غير موجود ضمن الشركة الحالية'; END IF;
    IF p_attendance_date IS NULL THEN RAISE EXCEPTION 'تاريخ الحضور مطلوب'; END IF;
    IF p_check_out IS NOT NULL AND p_check_in IS NOT NULL AND p_check_out<p_check_in THEN RAISE EXCEPTION 'وقت الانصراف لا يمكن أن يسبق وقت الحضور'; END IF;
    SELECT u.email INTO v_actor_email
    FROM public.users u
    WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
    INSERT INTO public.employee_attendance(company_id,employee_id,attendance_date,status,check_in,check_out,notes,created_by)
    VALUES(v_company_id,p_employee_id,p_attendance_date,COALESCE(NULLIF(btrim(p_status),''),'present'),p_check_in,p_check_out,p_notes,v_actor_email)
    ON CONFLICT (company_id,employee_id,attendance_date) DO UPDATE SET status=EXCLUDED.status,check_in=EXCLUDED.check_in,check_out=EXCLUDED.check_out,notes=EXCLUDED.notes,updated_at=now()
    RETURNING id INTO v_id;
    RETURN jsonb_build_object('success',true,'attendance_id',v_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.hr_upsert_employee_profile(
    p_employee_id uuid,
    p_employee_number text DEFAULT NULL,
    p_department text DEFAULT NULL,
    p_job_title text DEFAULT NULL,
    p_hire_date date DEFAULT NULL,
    p_employment_type text DEFAULT NULL,
    p_basic_salary numeric DEFAULT 0,
    p_housing_allowance numeric DEFAULT 0,
    p_transport_allowance numeric DEFAULT 0,
    p_other_allowance numeric DEFAULT 0,
    p_default_deduction numeric DEFAULT 0,
    p_status text DEFAULT 'active',
    p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid; v_id uuid; v_actor_email text;
BEGIN
    v_company_id:=app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN RAISE EXCEPTION 'غير مصرح لإدارة ملف الموظف'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=p_employee_id AND u.company_id=v_company_id) THEN RAISE EXCEPTION 'الموظف غير موجود ضمن الشركة الحالية'; END IF;
    IF COALESCE(p_basic_salary,0)<0 OR COALESCE(p_housing_allowance,0)<0 OR COALESCE(p_transport_allowance,0)<0 OR COALESCE(p_other_allowance,0)<0 OR COALESCE(p_default_deduction,0)<0 THEN RAISE EXCEPTION 'قيم الرواتب والبدلات والخصومات يجب ألا تكون سالبة'; END IF;
    SELECT u.email INTO v_actor_email
    FROM public.users u
    WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
    INSERT INTO public.employee_profiles(company_id,employee_id,employee_number,department,job_title,hire_date,employment_type,basic_salary,housing_allowance,transport_allowance,other_allowance,default_deduction,status,notes,created_by)
    VALUES(v_company_id,p_employee_id,NULLIF(btrim(p_employee_number),''),NULLIF(btrim(p_department),''),NULLIF(btrim(p_job_title),''),p_hire_date,NULLIF(btrim(p_employment_type),''),COALESCE(p_basic_salary,0),COALESCE(p_housing_allowance,0),COALESCE(p_transport_allowance,0),COALESCE(p_other_allowance,0),COALESCE(p_default_deduction,0),COALESCE(NULLIF(btrim(p_status),''),'active'),p_notes,v_actor_email)
    ON CONFLICT (company_id,employee_id) DO UPDATE SET employee_number=EXCLUDED.employee_number,department=EXCLUDED.department,job_title=EXCLUDED.job_title,hire_date=EXCLUDED.hire_date,employment_type=EXCLUDED.employment_type,basic_salary=EXCLUDED.basic_salary,housing_allowance=EXCLUDED.housing_allowance,transport_allowance=EXCLUDED.transport_allowance,other_allowance=EXCLUDED.other_allowance,default_deduction=EXCLUDED.default_deduction,status=EXCLUDED.status,notes=EXCLUDED.notes,updated_at=now()
    RETURNING id INTO v_id;
    RETURN jsonb_build_object('success',true,'profile_id',v_id,'company_id',v_company_id);
END;
$function$;

COMMIT;
