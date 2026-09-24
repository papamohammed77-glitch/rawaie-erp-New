CREATE OR REPLACE FUNCTION public.supplier_purchase_rep_search(p_query text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'app_private', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
  v_query text := lower(btrim(coalesce(p_query,'')));
  v_rows jsonb;
BEGIN
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'سياق الشركة غير صالح';
  END IF;
  IF NOT (app_private.current_user_has_permission('suppliers') OR app_private.current_user_has_permission('purchases')) THEN
    RAISE EXCEPTION 'لا تملك صلاحية البحث عن مسؤولي المشتريات';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object('id',x.id,'name',x.name,'email',x.email,'role',x.role,'employee_id',x.employee_id) ORDER BY x.name,x.email),'[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT u.id,u.name,u.email,u.role,u.employee_id
    FROM public.users u
    LEFT JOIN public.roles r ON r.id=u.role_id AND r.company_id=v_company_id
    WHERE u.company_id=v_company_id
      AND coalesce(u.status,'Active')='Active'
      AND lower(btrim(coalesce(u.role,''))) LIKE '%مشتريات%'
      AND (v_query='' OR lower(coalesce(u.name,'')||' '||coalesce(u.email,'')||' '||coalesce(u.role,'')) LIKE '%'||v_query||'%')
    ORDER BY u.name,u.email
    LIMIT 50
  ) x;
  RETURN jsonb_build_object('success',true,'rows',v_rows);
END;
$function$;
REVOKE ALL ON FUNCTION public.supplier_purchase_rep_search(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.supplier_purchase_rep_search(text) TO authenticated;