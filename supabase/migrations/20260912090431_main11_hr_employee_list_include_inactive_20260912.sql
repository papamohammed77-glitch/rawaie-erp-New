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
    SELECT
        u.id,u.company_id,u.email,u.name,u.role,u.status,u.phone,
        u.default_branch_id,u.allowed_branch_ids,u.expiry_date,u.employee_id,
        u.role_id,u.active_warehouse_role,
        ep.id,ep.employee_number,ep.department,ep.job_title,ep.hire_date,
        ep.employment_type,ep.basic_salary,ep.housing_allowance,
        ep.transport_allowance,ep.other_allowance,ep.default_deduction,
        ep.status,ep.notes
    FROM public.users u
    LEFT JOIN public.employee_profiles ep
      ON ep.employee_id=u.id
     AND ep.company_id=u.company_id
    WHERE u.company_id=v_company_id
    ORDER BY u.name ASC,u.email ASC;
END;
$function$;
