BEGIN;

CREATE TABLE IF NOT EXISTS public.employee_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    employee_number text,
    department text,
    job_title text,
    hire_date date,
    employment_type text,
    basic_salary numeric NOT NULL DEFAULT 0 CHECK (basic_salary >= 0),
    housing_allowance numeric NOT NULL DEFAULT 0 CHECK (housing_allowance >= 0),
    transport_allowance numeric NOT NULL DEFAULT 0 CHECK (transport_allowance >= 0),
    other_allowance numeric NOT NULL DEFAULT 0 CHECK (other_allowance >= 0),
    default_deduction numeric NOT NULL DEFAULT 0 CHECK (default_deduction >= 0),
    status text NOT NULL DEFAULT 'active',
    notes text,
    created_by text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT employee_profiles_company_employee_key UNIQUE (company_id, employee_id),
    CONSTRAINT employee_profiles_employee_number_key UNIQUE (company_id, employee_number)
);

CREATE INDEX IF NOT EXISTS idx_employee_profiles_company_status ON public.employee_profiles(company_id, status);

CREATE TABLE IF NOT EXISTS public.employee_attendance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    attendance_date date NOT NULL,
    status text NOT NULL DEFAULT 'present',
    check_in timestamptz,
    check_out timestamptz,
    notes text,
    created_by text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT employee_attendance_day_key UNIQUE (company_id, employee_id, attendance_date),
    CONSTRAINT employee_attendance_time_order CHECK (check_out IS NULL OR check_in IS NULL OR check_out >= check_in)
);

CREATE INDEX IF NOT EXISTS idx_employee_attendance_company_date ON public.employee_attendance(company_id, attendance_date DESC);

CREATE TABLE IF NOT EXISTS public.employee_leave_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    leave_type text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    reason text,
    status text NOT NULL DEFAULT 'pending',
    requested_by text,
    approved_by text,
    approved_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT employee_leave_dates_check CHECK (end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_employee_leave_company_dates ON public.employee_leave_requests(company_id, start_date, end_date);

CREATE OR REPLACE FUNCTION public.employee_hr_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_employee_profiles_updated_at ON public.employee_profiles;
CREATE TRIGGER trg_employee_profiles_updated_at BEFORE UPDATE ON public.employee_profiles FOR EACH ROW EXECUTE FUNCTION public.employee_hr_touch_updated_at();
DROP TRIGGER IF EXISTS trg_employee_attendance_updated_at ON public.employee_attendance;
CREATE TRIGGER trg_employee_attendance_updated_at BEFORE UPDATE ON public.employee_attendance FOR EACH ROW EXECUTE FUNCTION public.employee_hr_touch_updated_at();
DROP TRIGGER IF EXISTS trg_employee_leave_requests_updated_at ON public.employee_leave_requests;
CREATE TRIGGER trg_employee_leave_requests_updated_at BEFORE UPDATE ON public.employee_leave_requests FOR EACH ROW EXECUTE FUNCTION public.employee_hr_touch_updated_at();

DROP TRIGGER IF EXISTS trg_audit_employee_profiles ON public.employee_profiles;
CREATE TRIGGER trg_audit_employee_profiles AFTER INSERT OR UPDATE OR DELETE ON public.employee_profiles FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
DROP TRIGGER IF EXISTS trg_audit_employee_attendance ON public.employee_attendance;
CREATE TRIGGER trg_audit_employee_attendance AFTER INSERT OR UPDATE OR DELETE ON public.employee_attendance FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
DROP TRIGGER IF EXISTS trg_audit_employee_leave_requests ON public.employee_leave_requests;
CREATE TRIGGER trg_audit_employee_leave_requests AFTER INSERT OR UPDATE OR DELETE ON public.employee_leave_requests FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();

ALTER TABLE public.employee_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_leave_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS employee_profiles_select_hr ON public.employee_profiles;
CREATE POLICY employee_profiles_select_hr ON public.employee_profiles FOR SELECT TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_profiles_write_hr ON public.employee_profiles;
CREATE POLICY employee_profiles_write_hr ON public.employee_profiles FOR INSERT TO authenticated WITH CHECK (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_profiles_update_hr ON public.employee_profiles;
CREATE POLICY employee_profiles_update_hr ON public.employee_profiles FOR UPDATE TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr')) WITH CHECK (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_profiles_delete_hr ON public.employee_profiles;
CREATE POLICY employee_profiles_delete_hr ON public.employee_profiles FOR DELETE TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));

DROP POLICY IF EXISTS employee_attendance_select_hr ON public.employee_attendance;
CREATE POLICY employee_attendance_select_hr ON public.employee_attendance FOR SELECT TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_attendance_write_hr ON public.employee_attendance;
CREATE POLICY employee_attendance_write_hr ON public.employee_attendance FOR INSERT TO authenticated WITH CHECK (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_attendance_update_hr ON public.employee_attendance;
CREATE POLICY employee_attendance_update_hr ON public.employee_attendance FOR UPDATE TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr')) WITH CHECK (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_attendance_delete_hr ON public.employee_attendance;
CREATE POLICY employee_attendance_delete_hr ON public.employee_attendance FOR DELETE TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));

DROP POLICY IF EXISTS employee_leave_select_hr ON public.employee_leave_requests;
CREATE POLICY employee_leave_select_hr ON public.employee_leave_requests FOR SELECT TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_leave_write_hr ON public.employee_leave_requests;
CREATE POLICY employee_leave_write_hr ON public.employee_leave_requests FOR INSERT TO authenticated WITH CHECK (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_leave_update_hr ON public.employee_leave_requests;
CREATE POLICY employee_leave_update_hr ON public.employee_leave_requests FOR UPDATE TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr')) WITH CHECK (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));
DROP POLICY IF EXISTS employee_leave_delete_hr ON public.employee_leave_requests;
CREATE POLICY employee_leave_delete_hr ON public.employee_leave_requests FOR DELETE TO authenticated USING (company_id = app_private.current_user_company_id() AND app_private.current_user_has_permission('hr'));

CREATE OR REPLACE FUNCTION public.hr_list_employees()
RETURNS TABLE (
    id uuid, company_id uuid, email varchar, name varchar, role varchar, status varchar, phone varchar,
    default_branch_id uuid, allowed_branch_ids jsonb, expiry_date date, employee_id text, role_id uuid,
    active_warehouse_role text, profile_id uuid, employee_number text, department text, job_title text,
    hire_date date, employment_type text, basic_salary numeric, housing_allowance numeric,
    transport_allowance numeric, other_allowance numeric, default_deduction numeric,
    profile_status text, profile_notes text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE v_company_id uuid;
BEGIN
    v_company_id := app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN
        RAISE EXCEPTION 'غير مصرح للوصول إلى بيانات الموارد البشرية';
    END IF;
    RETURN QUERY
    SELECT u.id,u.company_id,u.email,u.name,u.role,u.status,u.phone,u.default_branch_id,u.allowed_branch_ids,
           u.expiry_date,u.employee_id,u.role_id,u.active_warehouse_role,ep.id,ep.employee_number,ep.department,
           ep.job_title,ep.hire_date,ep.employment_type,ep.basic_salary,ep.housing_allowance,
           ep.transport_allowance,ep.other_allowance,ep.default_deduction,ep.status,ep.notes
    FROM public.users u
    LEFT JOIN public.employee_profiles ep ON ep.employee_id=u.id AND ep.company_id=u.company_id
    WHERE u.company_id=v_company_id AND COALESCE(u.status,'Active') <> 'Inactive'
    ORDER BY u.name ASC,u.email ASC;
END;
$function$;
REVOKE ALL ON FUNCTION public.hr_list_employees() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hr_list_employees() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.hr_upsert_employee_profile(
    p_employee_id uuid,p_employee_number text DEFAULT NULL,p_department text DEFAULT NULL,p_job_title text DEFAULT NULL,
    p_hire_date date DEFAULT NULL,p_employment_type text DEFAULT NULL,p_basic_salary numeric DEFAULT 0,
    p_housing_allowance numeric DEFAULT 0,p_transport_allowance numeric DEFAULT 0,p_other_allowance numeric DEFAULT 0,
    p_default_deduction numeric DEFAULT 0,p_status text DEFAULT 'active',p_notes text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE v_company_id uuid; v_id uuid;
BEGIN
    v_company_id:=app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN RAISE EXCEPTION 'غير مصرح لإدارة ملف الموظف'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=p_employee_id AND u.company_id=v_company_id) THEN RAISE EXCEPTION 'الموظف غير موجود ضمن الشركة الحالية'; END IF;
    IF COALESCE(p_basic_salary,0)<0 OR COALESCE(p_housing_allowance,0)<0 OR COALESCE(p_transport_allowance,0)<0 OR COALESCE(p_other_allowance,0)<0 OR COALESCE(p_default_deduction,0)<0 THEN RAISE EXCEPTION 'قيم الرواتب والبدلات والخصومات يجب ألا تكون سالبة'; END IF;
    INSERT INTO public.employee_profiles(company_id,employee_id,employee_number,department,job_title,hire_date,employment_type,basic_salary,housing_allowance,transport_allowance,other_allowance,default_deduction,status,notes,created_by)
    VALUES(v_company_id,p_employee_id,NULLIF(btrim(p_employee_number),''),NULLIF(btrim(p_department),''),NULLIF(btrim(p_job_title),''),p_hire_date,NULLIF(btrim(p_employment_type),''),COALESCE(p_basic_salary,0),COALESCE(p_housing_allowance,0),COALESCE(p_transport_allowance,0),COALESCE(p_other_allowance,0),COALESCE(p_default_deduction,0),COALESCE(NULLIF(btrim(p_status),''),'active'),p_notes,(SELECT email FROM public.users WHERE auth_id=auth.uid() LIMIT 1))
    ON CONFLICT (company_id,employee_id) DO UPDATE SET employee_number=EXCLUDED.employee_number,department=EXCLUDED.department,job_title=EXCLUDED.job_title,hire_date=EXCLUDED.hire_date,employment_type=EXCLUDED.employment_type,basic_salary=EXCLUDED.basic_salary,housing_allowance=EXCLUDED.housing_allowance,transport_allowance=EXCLUDED.transport_allowance,other_allowance=EXCLUDED.other_allowance,default_deduction=EXCLUDED.default_deduction,status=EXCLUDED.status,notes=EXCLUDED.notes
    RETURNING id INTO v_id;
    RETURN jsonb_build_object('success',true,'profile_id',v_id,'company_id',v_company_id);
END;
$function$;
REVOKE ALL ON FUNCTION public.hr_upsert_employee_profile(uuid,text,text,text,date,text,numeric,numeric,numeric,numeric,numeric,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hr_upsert_employee_profile(uuid,text,text,text,date,text,numeric,numeric,numeric,numeric,numeric,text,text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.hr_save_attendance(p_employee_id uuid,p_attendance_date date,p_status text DEFAULT 'present',p_check_in timestamptz DEFAULT NULL,p_check_out timestamptz DEFAULT NULL,p_notes text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE v_company_id uuid; v_id uuid;
BEGIN
    v_company_id:=app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN RAISE EXCEPTION 'غير مصرح بإدارة الحضور والانصراف'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=p_employee_id AND u.company_id=v_company_id) THEN RAISE EXCEPTION 'الموظف غير موجود ضمن الشركة الحالية'; END IF;
    IF p_attendance_date IS NULL THEN RAISE EXCEPTION 'تاريخ الحضور مطلوب'; END IF;
    IF p_check_out IS NOT NULL AND p_check_in IS NOT NULL AND p_check_out<p_check_in THEN RAISE EXCEPTION 'وقت الانصراف لا يمكن أن يسبق وقت الحضور'; END IF;
    INSERT INTO public.employee_attendance(company_id,employee_id,attendance_date,status,check_in,check_out,notes,created_by)
    VALUES(v_company_id,p_employee_id,p_attendance_date,COALESCE(NULLIF(btrim(p_status),''),'present'),p_check_in,p_check_out,p_notes,(SELECT email FROM public.users WHERE auth_id=auth.uid() LIMIT 1))
    ON CONFLICT (company_id,employee_id,attendance_date) DO UPDATE SET status=EXCLUDED.status,check_in=EXCLUDED.check_in,check_out=EXCLUDED.check_out,notes=EXCLUDED.notes
    RETURNING id INTO v_id;
    RETURN jsonb_build_object('success',true,'attendance_id',v_id);
END;
$function$;
REVOKE ALL ON FUNCTION public.hr_save_attendance(uuid,date,text,timestamptz,timestamptz,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hr_save_attendance(uuid,date,text,timestamptz,timestamptz,text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.hr_create_leave_request(p_employee_id uuid,p_leave_type text,p_start_date date,p_end_date date,p_reason text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE v_company_id uuid; v_id uuid; v_email text;
BEGIN
    v_company_id:=app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('hr') THEN RAISE EXCEPTION 'غير مصرح بإدارة الإجازات'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=p_employee_id AND u.company_id=v_company_id) THEN RAISE EXCEPTION 'الموظف غير موجود ضمن الشركة الحالية'; END IF;
    IF NULLIF(btrim(p_leave_type),'') IS NULL THEN RAISE EXCEPTION 'نوع الإجازة مطلوب'; END IF;
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_end_date<p_start_date THEN RAISE EXCEPTION 'نطاق تاريخ الإجازة غير صالح'; END IF;
    SELECT u.email INTO v_email FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id LIMIT 1;
    INSERT INTO public.employee_leave_requests(company_id,employee_id,leave_type,start_date,end_date,reason,status,requested_by)
    VALUES(v_company_id,p_employee_id,NULLIF(btrim(p_leave_type),''),p_start_date,p_end_date,p_reason,'pending',v_email)
    RETURNING id INTO v_id;
    RETURN jsonb_build_object('success',true,'leave_request_id',v_id,'status','pending');
END;
$function$;
REVOKE ALL ON FUNCTION public.hr_create_leave_request(uuid,text,date,date,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hr_create_leave_request(uuid,text,date,date,text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.crm_save_customer_followup(p_customer_code text,p_followup_date date,p_followup_type text,p_status text,p_subject text DEFAULT NULL,p_notes text DEFAULT NULL,p_assigned_to text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
DECLARE v_company_id uuid; v_id uuid; v_email text;
BEGIN
    v_company_id:=app_private.current_user_company_id();
    IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('customers') THEN RAISE EXCEPTION 'غير مصرح بإدارة متابعات العملاء'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.customers c WHERE c.customer_code=p_customer_code AND c.company_id=v_company_id) THEN RAISE EXCEPTION 'العميل غير موجود ضمن الشركة الحالية'; END IF;
    IF p_followup_date IS NULL THEN RAISE EXCEPTION 'تاريخ المتابعة مطلوب'; END IF;
    SELECT u.email INTO v_email FROM public.users u WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id LIMIT 1;
    INSERT INTO public.customer_followups(customer_id,followup_date,followup_type,subject,notes,assigned_to,status,created_by,company_id,completed_at)
    VALUES(p_customer_code,p_followup_date,COALESCE(NULLIF(btrim(p_followup_type),''),'Call'),NULLIF(btrim(p_subject),''),p_notes,NULLIF(btrim(p_assigned_to),''),COALESCE(NULLIF(btrim(p_status),''),'Open'),v_email,v_company_id,CASE WHEN lower(COALESCE(p_status,'')) IN ('completed','مكتملة') THEN now() ELSE NULL END)
    RETURNING id INTO v_id;
    RETURN jsonb_build_object('success',true,'followup_id',v_id,'company_id',v_company_id);
END;
$function$;
REVOKE ALL ON FUNCTION public.crm_save_customer_followup(text,date,text,text,text,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.crm_save_customer_followup(text,date,text,text,text,text,text) TO authenticated, service_role;

COMMIT;
