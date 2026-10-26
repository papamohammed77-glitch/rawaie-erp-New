-- RAWAEA ERP: delivery supervisor / deliverer assignment contract
-- Adds authenticated company-scoped read + atomic assignment RPCs.
-- Does not create duplicate business tables: runsheets.deliverer_id and erp_operation_registry already exist.
-- Driver (runsheets.driver_id / vehicle assignment) remains owned by Parent/Fleet.
-- Delivery representative (runsheets.deliverer_id) is owned by Delivery Supervisor.
BEGIN;

CREATE OR REPLACE FUNCTION public.delivery_supervisor_assignment_query(
  p_company_id uuid,
  p_view text DEFAULT 'runsheets'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_view text := lower(btrim(coalesce(p_view,'runsheets')));
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'جلسة مصادقة مطلوبة';
  END IF;
  IF p_company_id IS NULL THEN
    RAISE EXCEPTION 'سياق الشركة مطلوب';
  END IF;

  SELECT u.* INTO v_actor
  FROM public.users u
  WHERE u.auth_id=auth.uid()
    AND u.company_id=p_company_id
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم غير نشط أو لا ينتمي إلى الشركة';
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["delivery_supervisor"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["fleet.read"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["fleet.manage"]'::jsonb
  ) THEN
    RAISE EXCEPTION 'غير مصرح بقراءة بيانات مشرف التوصيل';
  END IF;

  IF v_view='team' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',coalesce(jsonb_agg(jsonb_build_object(
        'id',u.id,'email',u.email,'name',u.name,'status',u.status
      ) ORDER BY u.name,u.email),'[]'::jsonb)
    ) INTO v_result
    FROM public.users u
    WHERE u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
      AND coalesce(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb;

  ELSIF v_view='runsheets' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',coalesce(jsonb_agg(jsonb_build_object(
        'id',r.id,'runsheet_code',r.runsheet_code,'run_date',r.run_date,
        'status',r.status,'total_amount',r.total_amount,
        'vehicle_id',r.vehicle_id,'driver_id',r.driver_id,'deliverer_id',r.deliverer_id
      ) ORDER BY r.run_date DESC,r.runsheet_code DESC),'[]'::jsonb)
    ) INTO v_result
    FROM (
      SELECT id,runsheet_code,run_date,status,total_amount,vehicle_id,driver_id,deliverer_id
      FROM public.runsheets
      WHERE company_id=p_company_id
        AND status IN ('Loaded','Delivering','Delivered','Returning')
      ORDER BY run_date DESC,runsheet_code DESC
      LIMIT 200
    ) r;

  ELSIF v_view='dashboard' THEN
    SELECT jsonb_build_object(
      'success',true,
      'total_runsheets',count(*),
      'loaded',count(*) FILTER (WHERE status='Loaded'),
      'delivering',count(*) FILTER (WHERE status='Delivering'),
      'delivered',count(*) FILTER (WHERE status='Delivered'),
      'returning',count(*) FILTER (WHERE status='Returning'),
      'active_deliverers',(SELECT count(*) FROM public.users u
        WHERE u.company_id=p_company_id
          AND coalesce(u.status,'Active')='Active'
          AND coalesce(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb)
    ) INTO v_result
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND run_date >= date_trunc('month',current_date)::date
      AND run_date <= current_date;

  ELSE
    RAISE EXCEPTION 'عرض مشرف التوصيل غير مدعوم: %',v_view;
  END IF;

  RETURN coalesce(v_result,jsonb_build_object('success',true,'rows','[]'::jsonb));
END;
$function$;

CREATE OR REPLACE FUNCTION public.delivery_supervisor_assign_deliverer_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_deliverer_user_id uuid,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_target public.users%ROWTYPE;
  v_runsheet public.runsheets%ROWTYPE;
  v_payload jsonb;
  v_key text;
  v_existing public.erp_operation_registry%ROWTYPE;
  v_rows integer;
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'جلسة مصادقة مطلوبة';
  END IF;
  IF p_company_id IS NULL OR nullif(btrim(p_runsheet_code),'') IS NULL
     OR nullif(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'الشركة والرانشيت وoperation_id حقول مطلوبة';
  END IF;

  SELECT u.* INTO v_actor
  FROM public.users u
  WHERE u.auth_id=auth.uid()
    AND u.company_id=p_company_id
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم غير نشط أو لا ينتمي إلى الشركة';
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["delivery_supervisor"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["fleet.manage"]'::jsonb
  ) THEN
    RAISE EXCEPTION 'غير مصرح بإسناد مناديب التوصيل';
  END IF;

  IF p_deliverer_user_id IS NOT NULL THEN
    SELECT u.* INTO v_target
    FROM public.users u
    WHERE u.id=p_deliverer_user_id
      AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
      AND coalesce(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
    LIMIT 1;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'مندوب التوصيل غير نشط أو غير مؤهل أو خارج الشركة';
    END IF;
  END IF;

  v_payload:=jsonb_build_object(
    'runsheet_code',btrim(p_runsheet_code),
    'deliverer_user_id',p_deliverer_user_id
  );
  v_key:='DELIVERY:DELIVERER_ASSIGN:'||btrim(p_operation_id);

  INSERT INTO public.erp_operation_registry(
    company_id,operation_type,operation_key,request_payload,status
  )
  VALUES(p_company_id,'DELIVERY',v_key,v_payload,'processing')
  ON CONFLICT (company_id,operation_type,operation_key) DO NOTHING;
  GET DIAGNOSTICS v_rows = ROW_COUNT;

  SELECT * INTO v_existing
  FROM public.erp_operation_registry
  WHERE company_id=p_company_id
    AND operation_type='DELIVERY'
    AND operation_key=v_key
  FOR UPDATE;

  IF v_existing.request_payload IS DISTINCT FROM v_payload THEN
    RAISE EXCEPTION 'operation_id conflict: أُعيد استخدام المفتاح لطلب مختلف';
  END IF;
  IF v_existing.status='completed' THEN
    RETURN coalesce(v_existing.response_payload,'{}'::jsonb)||jsonb_build_object('duplicate',true);
  END IF;
  IF v_rows=0 AND v_existing.status='processing'
     AND v_existing.created_at > now()-interval '15 minutes' THEN
    RAISE EXCEPTION 'عملية الإسناد قيد التنفيذ بالفعل';
  END IF;

  SELECT r.* INTO v_runsheet
  FROM public.runsheets r
  WHERE r.company_id=p_company_id
    AND r.runsheet_code=btrim(p_runsheet_code)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'الرانشيت غير موجود داخل الشركة المحددة';
  END IF;
  IF v_runsheet.status <> 'Loaded' THEN
    RAISE EXCEPTION 'لا يمكن إسناد/فك إسناد مندوب إلا والرانشيت في حالة Loaded';
  END IF;

  UPDATE public.runsheets
  SET deliverer_id=p_deliverer_user_id,
      updated_at=now()
  WHERE id=v_runsheet.id
    AND company_id=p_company_id
    AND status='Loaded';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'تغيرت حالة الرانشيت أثناء الإسناد؛ أعد تحميل القائمة';
  END IF;

  v_result:=jsonb_build_object(
    'success',true,
    'runsheet_code',v_runsheet.runsheet_code,
    'status',v_runsheet.status,
    'driver_id',v_runsheet.driver_id,
    'vehicle_id',v_runsheet.vehicle_id,
    'deliverer_id',p_deliverer_user_id,
    'operation_id',p_operation_id
  );

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_result,completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='DELIVERY'
    AND operation_key=v_key;

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.delivery_supervisor_assignment_query(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.delivery_supervisor_assignment_query(uuid,text) TO authenticated,service_role;
REVOKE ALL ON FUNCTION public.delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.delivery_supervisor_assign_deliverer_atomic(uuid,text,uuid,text) TO authenticated,service_role;

COMMIT;
