-- RAWAEA ERP — operational setup access for vehicle operation binding
-- Production truth: existing fleet control plane only; no new Edge Function.
-- Scope: allow operational users to read Fleet and execute VEHICLE_OPERATION_BIND during setup.
-- All other Fleet commands retain their existing permission gate.

CREATE OR REPLACE FUNCTION public.fleet_command_atomic(p_company_id uuid, p_command text, p_payload jsonb DEFAULT '{}'::jsonb, p_operation_id text DEFAULT NULL::text, p_actor_user_id uuid DEFAULT NULL::uuid, p_actor_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_command text := upper(btrim(coalesce(p_command,'')));
  v_registry public.erp_operation_registry%ROWTYPE;
  v_response jsonb;
  v_vehicle public.vehicles%ROWTYPE;
  v_vehicle2 public.vehicles%ROWTYPE;
  v_driver public.fleet_drivers%ROWTYPE;
  v_assignment public.fleet_vehicle_assignments%ROWTYPE;
  v_plan public.fleet_maintenance_plans%ROWTYPE;
  v_doc_id uuid;
  v_driver_id uuid;
  v_vehicle_id uuid;
  v_runsheet public.runsheets%ROWTYPE;
  v_prev_odo integer;
  v_new_odo integer;
  v_old_status text;
  v_new_status text;
  v_branch_id uuid;
  v_branch_code text;
  v_rows integer;
  v_user_id uuid;
  v_supplier_id uuid;
  v_plan_id uuid;
  v_incident_id uuid;
  v_assignment_start timestamptz := COALESCE(NULLIF(p_payload->>'start_at','')::timestamptz,now());
  v_operation_key text;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'سياق الشركة مطلوب'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.companies WHERE id=p_company_id AND is_active=true) THEN
    RAISE EXCEPTION 'الشركة غير موجودة أو غير نشطة';
  END IF;

  IF auth.uid() IS NOT NULL THEN
    SELECT * INTO v_actor
    FROM public.users u
    WHERE u.auth_id=auth.uid()
      AND u.company_id=p_company_id
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
  ELSE
    SELECT * INTO v_actor
    FROM public.users u
    WHERE u.id=p_actor_user_id
      AND u.company_id=p_company_id
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
  END IF;
  IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم أو سياق الشركة غير صالح'; END IF;

  IF p_actor_email IS NOT NULL AND lower(p_actor_email) <> lower(v_actor.email) THEN
    RAISE EXCEPTION 'بريد المنفذ لا يطابق هوية المستخدم';
  END IF;

  IF v_command IS NULL OR v_command='' THEN RAISE EXCEPTION 'الأمر مطلوب'; END IF;
  IF p_operation_id IS NULL OR NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'operation_id مطلوب لضمان إعادة المحاولة الآمنة';
  END IF;

  v_operation_key := 'FLEET:'||p_operation_id;

  INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
  VALUES(p_company_id,'FLEET',v_operation_key,coalesce(p_payload,'{}'::jsonb),'processing')
  ON CONFLICT (company_id,operation_type,operation_key) DO NOTHING;

  GET DIAGNOSTICS v_rows = ROW_COUNT;

  SELECT * INTO v_registry
  FROM public.erp_operation_registry
  WHERE company_id=p_company_id AND operation_type='FLEET' AND operation_key=v_operation_key
  FOR UPDATE;

  IF v_registry.request_payload <> coalesce(p_payload,'{}'::jsonb) THEN
    RAISE EXCEPTION 'operation_id conflict: نفس الهوية استُخدمت بطلب مختلف';
  END IF;

  IF v_registry.status='completed' THEN
    RETURN COALESCE(v_registry.response_payload,'{}'::jsonb) || jsonb_build_object('duplicate',true);
  END IF;
  IF v_rows=0 AND v_registry.status='processing' AND v_registry.created_at > now()-interval '15 minutes' THEN
    RAISE EXCEPTION 'fleet operation is already processing';
  END IF;

  -- Core command permissions.
  IF NOT (
    COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "*" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "fleet.manage" ]'::jsonb
    OR v_actor.role IN ('مدير عام','مدير مخازن')
    OR (
      v_command='VEHICLE_OPERATION_BIND'
      AND (
        COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "warehouse" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "warehouse_supervisor" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "warehouse_manager" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "vouchers" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "transfer" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "direct-sale" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "van-sales" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "delivery" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "delivery_supervisor" ]'::jsonb
        OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "vehicle-count" ]'::jsonb
        OR v_actor.role IN ('مشرف مخازن','مخزني','مندوب بيع مباشر','مندوب توصيل','مشرف توصيل')
      )
    )
  ) THEN
    RAISE EXCEPTION 'غير مصرح بإدارة الأسطول';
  END IF;

  IF v_command='VEHICLE_CREATE' THEN
    IF NULLIF(p_payload->>'ownership_type','') IS NOT NULL
       AND p_payload->>'ownership_type' NOT IN ('Owned','RentedPerTrip','RentedMonthly','Other')
    THEN RAISE EXCEPTION 'نوع ملكية المركبة غير مدعوم'; END IF;
    IF NULLIF(p_payload->>'operational_condition','') IS NOT NULL
       AND p_payload->>'operational_condition' NOT IN ('Excellent','Good','Fair','Poor')
    THEN RAISE EXCEPTION 'حالة المركبة غير مدعومة'; END IF;
    IF NULLIF(p_payload->>'route_capability','') IS NOT NULL
       AND p_payload->>'route_capability' NOT IN ('LocalOnly','Regional','LongHaul','Any')
    THEN RAISE EXCEPTION 'قدرة المسار غير مدعومة'; END IF;
    IF NULLIF(p_payload->>'max_weight_kg','') IS NOT NULL AND (p_payload->>'max_weight_kg')::numeric<=0
    THEN RAISE EXCEPTION 'سعة الوزن يجب أن تكون أكبر من صفر'; END IF;
    IF NULLIF(p_payload->>'cargo_length_m','') IS NOT NULL AND (p_payload->>'cargo_length_m')::numeric<=0
    THEN RAISE EXCEPTION 'طول الصندوق يجب أن يكون أكبر من صفر'; END IF;
    IF NULLIF(p_payload->>'cargo_width_m','') IS NOT NULL AND (p_payload->>'cargo_width_m')::numeric<=0
    THEN RAISE EXCEPTION 'عرض الصندوق يجب أن يكون أكبر من صفر'; END IF;
    IF NULLIF(p_payload->>'cargo_height_m','') IS NOT NULL AND (p_payload->>'cargo_height_m')::numeric<=0
    THEN RAISE EXCEPTION 'ارتفاع الصندوق يجب أن يكون أكبر من صفر'; END IF;
    v_response:=public.create_vehicle_atomic(
      p_company_id,
      p_payload->>'vehicle_code',
      p_payload->>'model',
      p_payload->>'license_plate',
      NULLIF(p_payload->>'driver_user_id','')::uuid,
      NULLIF(p_payload->>'max_weight_kg','')::numeric,
      NULLIF(p_payload->>'max_volume_m3','')::numeric,
      NULLIF(p_payload->>'min_trip_value','')::numeric,
      COALESCE(NULLIF(p_payload->>'status',''),'Active'),
      p_payload->>'notes',
      COALESCE(NULLIF(p_payload->>'vehicle_type',''),'Delivery'),
      COALESCE(NULLIF(p_payload->>'operation_mode',''),'Mixed'),
      COALESCE(NULLIF(p_payload->>'ownership_type',''),'Owned'),
      NULLIF(p_payload->>'model_year','')::integer,
      p_payload->>'vin',
      p_payload->>'fuel_type',
      COALESCE((p_payload->>'refrigerated')::boolean,false),
      COALESCE((p_payload->>'mobile_stock_enabled')::boolean,true),
      v_actor.email
    );
    v_vehicle_id:=(v_response->>'vehicle_id')::uuid;

    IF NULLIF(p_payload->>'fleet_driver_id','') IS NOT NULL THEN
      v_driver_id:=(p_payload->>'fleet_driver_id')::uuid;
      IF NOT EXISTS(SELECT 1 FROM public.fleet_drivers fd WHERE fd.id=v_driver_id AND fd.company_id=p_company_id) THEN
        RAISE EXCEPTION 'السائق الإداري لا يتبع الشركة';
      END IF;
      UPDATE public.vehicles SET fleet_driver_id=v_driver_id WHERE id=v_vehicle_id AND company_id=p_company_id;
    END IF;

    UPDATE public.vehicles
    SET registration_date=NULLIF(p_payload->>'registration_date','')::date,
        commission_date=NULLIF(p_payload->>'commission_date','')::date,
        engine_number=COALESCE(NULLIF(p_payload->>'engine_number',''),engine_number),
        color=COALESCE(NULLIF(p_payload->>'color',''),color),
        fuel_tank_capacity_l=NULLIF(p_payload->>'fuel_tank_capacity_l','')::numeric,
        expected_km_per_liter=NULLIF(p_payload->>'expected_km_per_liter','')::numeric,
        cargo_length_m=NULLIF(p_payload->>'cargo_length_m','')::numeric,
        cargo_width_m=NULLIF(p_payload->>'cargo_width_m','')::numeric,
        cargo_height_m=NULLIF(p_payload->>'cargo_height_m','')::numeric,
        max_volume_m3=CASE
          WHEN NULLIF(p_payload->>'cargo_length_m','') IS NOT NULL
           AND NULLIF(p_payload->>'cargo_width_m','') IS NOT NULL
           AND NULLIF(p_payload->>'cargo_height_m','') IS NOT NULL
          THEN (p_payload->>'cargo_length_m')::numeric*(p_payload->>'cargo_width_m')::numeric*(p_payload->>'cargo_height_m')::numeric
          ELSE NULLIF(p_payload->>'max_volume_m3','')::numeric
        END,
        operational_condition=COALESCE(NULLIF(p_payload->>'operational_condition',''),'Good'),
        route_capability=COALESCE(NULLIF(p_payload->>'route_capability',''),'Any')
    WHERE id=v_vehicle_id AND company_id=p_company_id;

  ELSIF v_command='VEHICLE_UPDATE' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    SELECT * INTO v_vehicle FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'المركبة غير موجودة'; END IF;
    v_old_status:=v_vehicle.status;
    v_new_status:=COALESCE(NULLIF(p_payload->>'status',''),v_vehicle.status);

    IF NULLIF(p_payload->>'driver_user_id','') IS NOT NULL
       AND NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=(p_payload->>'driver_user_id')::uuid AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active') THEN
      RAISE EXCEPTION 'السائق التشغيلي غير صالح للشركة';
    END IF;

    IF NULLIF(p_payload->>'fleet_driver_id','') IS NOT NULL
       AND NOT EXISTS(SELECT 1 FROM public.fleet_drivers fd WHERE fd.id=(p_payload->>'fleet_driver_id')::uuid AND fd.company_id=p_company_id) THEN
      RAISE EXCEPTION 'السائق الإداري غير صالح للشركة';
    END IF;

    IF p_payload ? 'mobile_stock_enabled'
       AND COALESCE((p_payload->>'mobile_stock_enabled')::boolean,false)=false
       AND v_vehicle.mobile_branch_id IS NOT NULL
       AND EXISTS (
         SELECT 1 FROM public.stock_branches sb
         WHERE sb.branch_id=v_vehicle.mobile_branch_id
           AND (COALESCE(sb.qty,0)<>0 OR COALESCE(sb.allocated_qty,0)<>0)
       ) THEN
      RAISE EXCEPTION 'لا يمكن تعطيل مخزون المركبة قبل تصفير الرصيد والحجوزات';
    END IF;

    UPDATE public.vehicles
    SET model=COALESCE(NULLIF(p_payload->>'model',''),model),
        license_plate=COALESCE(NULLIF(p_payload->>'license_plate',''),license_plate),
        driver_id=CASE WHEN p_payload ? 'driver_user_id' THEN NULLIF(p_payload->>'driver_user_id','')::uuid ELSE driver_id END,
        fleet_driver_id=CASE WHEN p_payload ? 'fleet_driver_id' THEN NULLIF(p_payload->>'fleet_driver_id','')::uuid ELSE fleet_driver_id END,
        max_weight_kg=CASE WHEN p_payload ? 'max_weight_kg' THEN NULLIF(p_payload->>'max_weight_kg','')::numeric ELSE max_weight_kg END,
        max_volume_m3=CASE
          WHEN NULLIF(p_payload->>'cargo_length_m','') IS NOT NULL
           AND NULLIF(p_payload->>'cargo_width_m','') IS NOT NULL
           AND NULLIF(p_payload->>'cargo_height_m','') IS NOT NULL
          THEN (p_payload->>'cargo_length_m')::numeric*(p_payload->>'cargo_width_m')::numeric*(p_payload->>'cargo_height_m')::numeric
          WHEN p_payload ? 'max_volume_m3' THEN NULLIF(p_payload->>'max_volume_m3','')::numeric
          ELSE max_volume_m3
        END,
        min_trip_value=CASE WHEN p_payload ? 'min_trip_value' THEN NULLIF(p_payload->>'min_trip_value','')::numeric ELSE min_trip_value END,
        status=v_new_status,
        notes=CASE WHEN p_payload ? 'notes' THEN p_payload->>'notes' ELSE notes END,
        vehicle_type=COALESCE(NULLIF(p_payload->>'vehicle_type',''),vehicle_type),
        operation_mode=COALESCE(NULLIF(p_payload->>'operation_mode',''),operation_mode),
        ownership_type=COALESCE(NULLIF(p_payload->>'ownership_type',''),ownership_type),
        model_year=CASE WHEN p_payload ? 'model_year' THEN NULLIF(p_payload->>'model_year','')::integer ELSE model_year END,
        vin=CASE WHEN p_payload ? 'vin' THEN NULLIF(p_payload->>'vin','') ELSE vin END,
        fuel_type=CASE WHEN p_payload ? 'fuel_type' THEN NULLIF(p_payload->>'fuel_type','') ELSE fuel_type END,
        refrigerated=CASE WHEN p_payload ? 'refrigerated' THEN COALESCE((p_payload->>'refrigerated')::boolean,false) ELSE refrigerated END,
        registration_date=CASE WHEN p_payload ? 'registration_date' THEN NULLIF(p_payload->>'registration_date','')::date ELSE registration_date END,
        commission_date=CASE WHEN p_payload ? 'commission_date' THEN NULLIF(p_payload->>'commission_date','')::date ELSE commission_date END,
        retirement_date=CASE WHEN p_payload ? 'retirement_date' THEN NULLIF(p_payload->>'retirement_date','')::date ELSE retirement_date END,
        engine_number=CASE WHEN p_payload ? 'engine_number' THEN NULLIF(p_payload->>'engine_number','') ELSE engine_number END,
        color=CASE WHEN p_payload ? 'color' THEN NULLIF(p_payload->>'color','') ELSE color END,
        fuel_tank_capacity_l=CASE WHEN p_payload ? 'fuel_tank_capacity_l' THEN NULLIF(p_payload->>'fuel_tank_capacity_l','')::numeric ELSE fuel_tank_capacity_l END,
        expected_km_per_liter=CASE WHEN p_payload ? 'expected_km_per_liter' THEN NULLIF(p_payload->>'expected_km_per_liter','')::numeric ELSE expected_km_per_liter END,
        cargo_length_m=CASE WHEN p_payload ? 'cargo_length_m' THEN NULLIF(p_payload->>'cargo_length_m','')::numeric ELSE cargo_length_m END,
        cargo_width_m=CASE WHEN p_payload ? 'cargo_width_m' THEN NULLIF(p_payload->>'cargo_width_m','')::numeric ELSE cargo_width_m END,
        cargo_height_m=CASE WHEN p_payload ? 'cargo_height_m' THEN NULLIF(p_payload->>'cargo_height_m','')::numeric ELSE cargo_height_m END,
        operational_condition=CASE WHEN p_payload ? 'operational_condition' THEN COALESCE(NULLIF(p_payload->>'operational_condition',''),'Good') ELSE operational_condition END,
        route_capability=CASE WHEN p_payload ? 'route_capability' THEN COALESCE(NULLIF(p_payload->>'route_capability',''),'Any') ELSE route_capability END
    WHERE id=v_vehicle_id AND company_id=p_company_id;

    IF p_payload ? 'mobile_stock_enabled' THEN
      IF COALESCE((p_payload->>'mobile_stock_enabled')::boolean,false)=true AND v_vehicle.mobile_branch_id IS NULL THEN
        v_branch_code:='VAN-'||v_vehicle.vehicle_code;
        SELECT id INTO v_branch_id FROM public.branches WHERE company_id=p_company_id AND branch_code=v_branch_code FOR UPDATE;
        IF v_branch_id IS NULL THEN
          INSERT INTO public.branches(id,branch_code,name,is_active,company_id,created_at,updated_at)
          VALUES(gen_random_uuid(),v_branch_code,'سيارة '||v_vehicle.vehicle_code||' - '||v_vehicle.license_plate,true,p_company_id,now(),now())
          RETURNING id INTO v_branch_id;
        END IF;
        PERFORM public.setup_van_stock(v_branch_id);
        UPDATE public.vehicles SET mobile_stock_enabled=true,mobile_branch_id=v_branch_id WHERE id=v_vehicle_id AND company_id=p_company_id;
      ELSIF COALESCE((p_payload->>'mobile_stock_enabled')::boolean,false)=false THEN
        UPDATE public.vehicles SET mobile_stock_enabled=false WHERE id=v_vehicle_id AND company_id=p_company_id;
      END IF;
    END IF;

    IF v_old_status IS DISTINCT FROM v_new_status THEN
      INSERT INTO public.vehicle_status_history(company_id,vehicle_id,old_status,new_status,reason,changed_by)
      VALUES(p_company_id,v_vehicle_id,v_old_status,v_new_status,p_payload->>'status_reason',v_actor.email);
    END IF;

    v_response:=jsonb_build_object('success',true,'command',v_command,'vehicle_id',v_vehicle_id,'status',(SELECT status FROM public.vehicles WHERE id=v_vehicle_id));

  ELSIF v_command='DRIVER_CREATE' THEN
    IF NULLIF(p_payload->>'employment_type','') IS NOT NULL
       AND p_payload->>'employment_type' NOT IN ('Employee','PerTrip','Monthly','Contractor','Outsourced','Other')
    THEN RAISE EXCEPTION 'نوع التعاقد غير مدعوم'; END IF;
    IF NULLIF(p_payload->>'license_type','') IS NOT NULL
       AND p_payload->>'license_type' NOT IN ('Private','ProfessionalFirst','ProfessionalSecond','ProfessionalThird')
    THEN RAISE EXCEPTION 'نوع رخصة القيادة غير مدعوم'; END IF;
    INSERT INTO public.fleet_drivers(company_id,driver_code,full_name,phone,email,user_id,employee_id,employment_type,status,hire_date,notes,created_by)
    VALUES(
      p_company_id,
      btrim(p_payload->>'driver_code'),
      btrim(p_payload->>'full_name'),
      NULLIF(btrim(p_payload->>'phone'),''),
      NULLIF(btrim(p_payload->>'email'),''),
      NULLIF(p_payload->>'user_id','')::uuid,
      NULLIF(btrim(p_payload->>'employee_id'),''),
      COALESCE(NULLIF(p_payload->>'employment_type',''),'Employee'),
      COALESCE(NULLIF(p_payload->>'status',''),'Active'),
      NULLIF(p_payload->>'hire_date','')::date,
      p_payload->>'notes',
      v_actor.email
    )
    RETURNING * INTO v_driver;

    IF NULLIF(p_payload->>'license_type','') IS NOT NULL
       OR NULLIF(p_payload->>'license_number','') IS NOT NULL
       OR NULLIF(p_payload->>'license_issue_date','') IS NOT NULL
       OR NULLIF(p_payload->>'license_expiry_date','') IS NOT NULL
    THEN
      INSERT INTO public.fleet_driver_documents(
        company_id,fleet_driver_id,document_type,document_number,license_class,
        issue_date,expiry_date,alert_days_before,status,created_by
      )
      VALUES(
        p_company_id,v_driver.id,'DriverLicense',
        NULLIF(btrim(p_payload->>'license_number'),''),
        NULLIF(p_payload->>'license_type',''),
        NULLIF(p_payload->>'license_issue_date','')::date,
        NULLIF(p_payload->>'license_expiry_date','')::date,
        30,'Active',v_actor.email
      );
    END IF;

    v_response:=jsonb_build_object('success',true,'driver_id',v_driver.id,'driver_code',v_driver.driver_code);

  ELSIF v_command='DRIVER_UPDATE' THEN
    v_driver_id:=(p_payload->>'driver_id')::uuid;
    SELECT * INTO v_driver FROM public.fleet_drivers WHERE id=v_driver_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'ملف السائق غير موجود'; END IF;
    UPDATE public.fleet_drivers
    SET full_name=COALESCE(NULLIF(btrim(p_payload->>'full_name'),''),full_name),
        phone=CASE WHEN p_payload ? 'phone' THEN NULLIF(btrim(p_payload->>'phone'),'') ELSE phone END,
        email=CASE WHEN p_payload ? 'email' THEN NULLIF(btrim(p_payload->>'email'),'') ELSE email END,
        user_id=CASE WHEN p_payload ? 'user_id' THEN NULLIF(p_payload->>'user_id','')::uuid ELSE user_id END,
        employee_id=CASE WHEN p_payload ? 'employee_id' THEN NULLIF(btrim(p_payload->>'employee_id'),'') ELSE employee_id END,
        employment_type=COALESCE(NULLIF(p_payload->>'employment_type',''),employment_type),
        status=COALESCE(NULLIF(p_payload->>'status',''),status),
        hire_date=CASE WHEN p_payload ? 'hire_date' THEN NULLIF(p_payload->>'hire_date','')::date ELSE hire_date END,
        termination_date=CASE WHEN p_payload ? 'termination_date' THEN NULLIF(p_payload->>'termination_date','')::date ELSE termination_date END,
        notes=CASE WHEN p_payload ? 'notes' THEN p_payload->>'notes' ELSE notes END,
        updated_at=now()
    WHERE id=v_driver_id AND company_id=p_company_id;

    IF NULLIF(p_payload->>'license_type','') IS NOT NULL
       OR NULLIF(p_payload->>'license_number','') IS NOT NULL
       OR NULLIF(p_payload->>'license_issue_date','') IS NOT NULL
       OR NULLIF(p_payload->>'license_expiry_date','') IS NOT NULL
    THEN
      IF NULLIF(p_payload->>'license_type','') IS NOT NULL
         AND p_payload->>'license_type' NOT IN ('Private','ProfessionalFirst','ProfessionalSecond','ProfessionalThird')
      THEN RAISE EXCEPTION 'نوع رخصة القيادة غير مدعوم'; END IF;

      SELECT id INTO v_doc_id
      FROM public.fleet_driver_documents
      WHERE company_id=p_company_id AND fleet_driver_id=v_driver_id AND document_type='DriverLicense'
      ORDER BY created_at DESC,id LIMIT 1 FOR UPDATE;

      IF v_doc_id IS NULL THEN
        INSERT INTO public.fleet_driver_documents(
          company_id,fleet_driver_id,document_type,document_number,license_class,
          issue_date,expiry_date,alert_days_before,status,created_by
        )
        VALUES(
          p_company_id,v_driver_id,'DriverLicense',
          NULLIF(btrim(p_payload->>'license_number'),''),
          NULLIF(p_payload->>'license_type',''),
          NULLIF(p_payload->>'license_issue_date','')::date,
          NULLIF(p_payload->>'license_expiry_date','')::date,
          30,COALESCE(NULLIF(p_payload->>'license_status',''),'Active'),v_actor.email
        ) RETURNING id INTO v_doc_id;
      ELSE
        UPDATE public.fleet_driver_documents
        SET license_class=CASE WHEN p_payload ? 'license_type' THEN NULLIF(p_payload->>'license_type','') ELSE license_class END,
            document_number=CASE WHEN p_payload ? 'license_number' THEN NULLIF(btrim(p_payload->>'license_number'),'') ELSE document_number END,
            issue_date=CASE WHEN p_payload ? 'license_issue_date' THEN NULLIF(p_payload->>'license_issue_date','')::date ELSE issue_date END,
            expiry_date=CASE WHEN p_payload ? 'license_expiry_date' THEN NULLIF(p_payload->>'license_expiry_date','')::date ELSE expiry_date END,
            status=CASE WHEN p_payload ? 'license_status' THEN COALESCE(NULLIF(p_payload->>'license_status',''),'Active') ELSE status END,
            updated_at=now()
        WHERE id=v_doc_id AND company_id=p_company_id AND fleet_driver_id=v_driver_id;
      END IF;
    END IF;

    v_response:=jsonb_build_object('success',true,'driver_id',v_driver_id);

  ELSIF v_command='DRIVER_DOCUMENT_UPSERT' THEN
    v_driver_id:=(p_payload->>'fleet_driver_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.fleet_drivers WHERE id=v_driver_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'السائق غير صالح'; END IF;
    IF NULLIF(p_payload->>'document_id','') IS NOT NULL THEN
      UPDATE public.fleet_driver_documents
      SET document_type=COALESCE(NULLIF(p_payload->>'document_type',''),document_type),
          document_number=CASE WHEN p_payload ? 'document_number' THEN NULLIF(p_payload->>'document_number','') ELSE document_number END,
          license_class=CASE WHEN p_payload ? 'license_class' THEN NULLIF(p_payload->>'license_class','') ELSE license_class END,
          issue_date=CASE WHEN p_payload ? 'issue_date' THEN NULLIF(p_payload->>'issue_date','')::date ELSE issue_date END,
          expiry_date=CASE WHEN p_payload ? 'expiry_date' THEN NULLIF(p_payload->>'expiry_date','')::date ELSE expiry_date END,
          alert_days_before=COALESCE(NULLIF(p_payload->>'alert_days_before','')::integer,alert_days_before),
          document_url=CASE WHEN p_payload ? 'document_url' THEN NULLIF(p_payload->>'document_url','') ELSE document_url END,
          status=COALESCE(NULLIF(p_payload->>'status',''),status),
          notes=CASE WHEN p_payload ? 'notes' THEN p_payload->>'notes' ELSE notes END,
          updated_at=now()
      WHERE id=(p_payload->>'document_id')::uuid AND company_id=p_company_id AND fleet_driver_id=v_driver_id;
    ELSE
      INSERT INTO public.fleet_driver_documents(company_id,fleet_driver_id,document_type,document_number,license_class,issue_date,expiry_date,alert_days_before,document_url,status,notes,created_by)
      VALUES(
        p_company_id,v_driver_id,
        COALESCE(NULLIF(p_payload->>'document_type',''),'DriverLicense'),
        p_payload->>'document_number',
        p_payload->>'license_class',
        NULLIF(p_payload->>'issue_date','')::date,
        NULLIF(p_payload->>'expiry_date','')::date,
        COALESCE(NULLIF(p_payload->>'alert_days_before','')::integer,30),
        p_payload->>'document_url',
        COALESCE(NULLIF(p_payload->>'status',''),'Active'),
        p_payload->>'notes',
        v_actor.email
      ) RETURNING id INTO v_doc_id;
    END IF;
    v_response:=jsonb_build_object('success',true,'driver_document_id',COALESCE(v_doc_id,(p_payload->>'document_id')::uuid));

  ELSIF v_command='VEHICLE_DOCUMENT_UPSERT' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;
    IF NULLIF(p_payload->>'document_id','') IS NOT NULL THEN
      UPDATE public.vehicle_documents
      SET document_type=COALESCE(NULLIF(p_payload->>'document_type',''),document_type),
          document_number=CASE WHEN p_payload ? 'document_number' THEN NULLIF(p_payload->>'document_number','') ELSE document_number END,
          issue_date=CASE WHEN p_payload ? 'issue_date' THEN NULLIF(p_payload->>'issue_date','')::date ELSE issue_date END,
          expiry_date=CASE WHEN p_payload ? 'expiry_date' THEN NULLIF(p_payload->>'expiry_date','')::date ELSE expiry_date END,
          alert_days_before=COALESCE(NULLIF(p_payload->>'alert_days_before','')::integer,alert_days_before),
          document_url=CASE WHEN p_payload ? 'document_url' THEN NULLIF(p_payload->>'document_url','') ELSE document_url END,
          status=COALESCE(NULLIF(p_payload->>'status',''),status),
          notes=CASE WHEN p_payload ? 'notes' THEN p_payload->>'notes' ELSE notes END
      WHERE id=(p_payload->>'document_id')::uuid AND company_id=p_company_id AND vehicle_id=v_vehicle_id;
    ELSE
      INSERT INTO public.vehicle_documents(company_id,vehicle_id,document_type,document_number,issue_date,expiry_date,document_url,status,notes,created_by,alert_days_before)
      VALUES(
        p_company_id,v_vehicle_id,
        COALESCE(NULLIF(p_payload->>'document_type',''),'Registration'),
        p_payload->>'document_number',
        NULLIF(p_payload->>'issue_date','')::date,
        NULLIF(p_payload->>'expiry_date','')::date,
        p_payload->>'document_url',
        COALESCE(NULLIF(p_payload->>'status',''),'Active'),
        p_payload->>'notes',
        v_actor.email,
        COALESCE(NULLIF(p_payload->>'alert_days_before','')::integer,30)
      ) RETURNING id INTO v_doc_id;
    END IF;
    v_response:=jsonb_build_object('success',true,'vehicle_document_id',COALESCE(v_doc_id,(p_payload->>'document_id')::uuid));

  ELSIF v_command='VEHICLE_CONTRACT_UPSERT' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;
    IF NULLIF(p_payload->>'contract_id','') IS NOT NULL THEN
      UPDATE public.fleet_vehicle_contracts
      SET supplier_id=CASE WHEN p_payload ? 'supplier_id' THEN NULLIF(p_payload->>'supplier_id','')::uuid ELSE supplier_id END,
          contract_number=COALESCE(NULLIF(p_payload->>'contract_number',''),contract_number),
          contract_type=COALESCE(NULLIF(p_payload->>'contract_type',''),contract_type),
          start_date=COALESCE(NULLIF(p_payload->>'start_date','')::date,start_date),
          end_date=CASE WHEN p_payload ? 'end_date' THEN NULLIF(p_payload->>'end_date','')::date ELSE end_date END,
          status=COALESCE(NULLIF(p_payload->>'status',''),status),
          responsible_user_id=CASE WHEN p_payload ? 'responsible_user_id' THEN NULLIF(p_payload->>'responsible_user_id','')::uuid ELSE responsible_user_id END,
          monthly_cost=COALESCE(NULLIF(p_payload->>'monthly_cost','')::numeric,monthly_cost),
          total_contract_value=CASE WHEN p_payload ? 'total_contract_value' THEN NULLIF(p_payload->>'total_contract_value','')::numeric ELSE total_contract_value END,
          deposit_amount=COALESCE(NULLIF(p_payload->>'deposit_amount','')::numeric,deposit_amount),
          included_km=CASE WHEN p_payload ? 'included_km' THEN NULLIF(p_payload->>'included_km','')::numeric ELSE included_km END,
          excess_km_rate=CASE WHEN p_payload ? 'excess_km_rate' THEN NULLIF(p_payload->>'excess_km_rate','')::numeric ELSE excess_km_rate END,
          notes=CASE WHEN p_payload ? 'notes' THEN p_payload->>'notes' ELSE notes END,
          document_url=CASE WHEN p_payload ? 'document_url' THEN NULLIF(p_payload->>'document_url','') ELSE document_url END,
          updated_at=now()
      WHERE id=(p_payload->>'contract_id')::uuid AND company_id=p_company_id AND vehicle_id=v_vehicle_id;
      v_doc_id:=(p_payload->>'contract_id')::uuid;
    ELSE
      INSERT INTO public.fleet_vehicle_contracts(company_id,vehicle_id,supplier_id,contract_number,contract_type,start_date,end_date,status,responsible_user_id,monthly_cost,total_contract_value,deposit_amount,included_km,excess_km_rate,notes,document_url,created_by)
      VALUES(
        p_company_id,v_vehicle_id,NULLIF(p_payload->>'supplier_id','')::uuid,
        btrim(p_payload->>'contract_number'),
        COALESCE(NULLIF(p_payload->>'contract_type',''),'Lease'),
        NULLIF(p_payload->>'start_date','')::date,
        NULLIF(p_payload->>'end_date','')::date,
        COALESCE(NULLIF(p_payload->>'status',''),'Active'),
        NULLIF(p_payload->>'responsible_user_id','')::uuid,
        COALESCE(NULLIF(p_payload->>'monthly_cost','')::numeric,0),
        NULLIF(p_payload->>'total_contract_value','')::numeric,
        COALESCE(NULLIF(p_payload->>'deposit_amount','')::numeric,0),
        NULLIF(p_payload->>'included_km','')::numeric,
        NULLIF(p_payload->>'excess_km_rate','')::numeric,
        p_payload->>'notes',
        p_payload->>'document_url',
        v_actor.email
      ) RETURNING id INTO v_doc_id;
    END IF;
    v_response:=jsonb_build_object('success',true,'contract_id',v_doc_id);

  ELSIF v_command='DRIVER_ASSIGN' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    v_driver_id:=NULLIF(p_payload->>'fleet_driver_id','')::uuid;
    v_user_id:=NULLIF(p_payload->>'driver_user_id','')::uuid;
    SELECT * INTO v_vehicle FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'المركبة غير موجودة'; END IF;
    IF v_driver_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.fleet_drivers WHERE id=v_driver_id AND company_id=p_company_id AND status='Active') THEN RAISE EXCEPTION 'السائق الإداري غير صالح'; END IF;
    IF v_user_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users WHERE id=v_user_id AND company_id=p_company_id AND status='Active') THEN RAISE EXCEPTION 'السائق التشغيلي غير صالح'; END IF;

    UPDATE public.fleet_vehicle_assignments
    SET end_at=COALESCE(NULLIF(p_payload->>'end_at','')::timestamptz,now())
    WHERE company_id=p_company_id AND vehicle_id=v_vehicle_id AND end_at IS NULL AND is_primary=true;

    INSERT INTO public.fleet_vehicle_assignments(company_id,vehicle_id,fleet_driver_id,driver_user_id,start_at,assignment_type,is_primary,notes,created_by)
    VALUES(p_company_id,v_vehicle_id,v_driver_id,v_user_id,v_assignment_start,COALESCE(NULLIF(p_payload->>'assignment_type',''),'Primary'),true,p_payload->>'notes',v_actor.email)
    RETURNING id INTO v_doc_id;

    UPDATE public.vehicles
    SET fleet_driver_id=v_driver_id,
        driver_id=v_user_id
    WHERE id=v_vehicle_id AND company_id=p_company_id;

    v_response:=jsonb_build_object('success',true,'assignment_id',v_doc_id,'vehicle_id',v_vehicle_id,'fleet_driver_id',v_driver_id,'driver_user_id',v_user_id);

  ELSIF v_command='ODOMETER_RECORD' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    v_new_odo:=(p_payload->>'meter_reading')::integer;
    IF v_new_odo IS NULL OR v_new_odo<0 THEN RAISE EXCEPTION 'قراءة العداد غير صالحة'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;

    SELECT GREATEST(
      COALESCE((SELECT max(vt.meter_reading) FROM public.vehicle_tracking vt WHERE vt.vehicle_id=v_vehicle_id AND vt.company_id=p_company_id),0),
      COALESCE((SELECT max(GREATEST(COALESCE(r.meter_start,0),COALESCE(r.meter_end,0))) FROM public.runsheets r WHERE r.vehicle_id=v_vehicle_id AND r.company_id=p_company_id),0)
    )::integer INTO v_prev_odo;

    IF v_new_odo < v_prev_odo THEN
      RAISE EXCEPTION 'قراءة العداد الجديدة أقل من آخر قراءة موثقة (% كم)',v_prev_odo;
    END IF;

    INSERT INTO public.vehicle_tracking(vehicle_id,driver_id,runsheet_code,meter_reading,meter_photo_url,tracking_date,company_id,reading_type,source_type,source_id,reference,notes,recorded_by)
    VALUES(v_vehicle_id,v_user_id,p_payload->>'runsheet_code',v_new_odo,p_payload->>'meter_photo_url',COALESCE(NULLIF(p_payload->>'tracking_date','')::date,current_date),p_company_id,'Odometer',COALESCE(NULLIF(p_payload->>'source_type',''),'Manual'),NULLIF(p_payload->>'source_id','')::uuid,p_payload->>'reference',p_payload->>'notes',v_actor.email);

    v_response:=jsonb_build_object('success',true,'vehicle_id',v_vehicle_id,'meter_reading',v_new_odo,'previous_meter',v_prev_odo);

  ELSIF v_command='FUEL_RECORD' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;
    IF NULLIF(p_payload->>'runsheet_id','') IS NOT NULL THEN
      SELECT * INTO v_runsheet FROM public.runsheets WHERE id=(p_payload->>'runsheet_id')::uuid AND company_id=p_company_id;
      IF NOT FOUND OR v_runsheet.vehicle_id<>v_vehicle_id THEN RAISE EXCEPTION 'الرانشيت لا يتبع المركبة/الشركة'; END IF;
    END IF;
    v_new_odo:=NULLIF(p_payload->>'odometer_km','')::integer;
    IF v_new_odo IS NOT NULL THEN
      SELECT GREATEST(
        COALESCE((SELECT max(vt.meter_reading) FROM public.vehicle_tracking vt WHERE vt.vehicle_id=v_vehicle_id AND vt.company_id=p_company_id),0),
        COALESCE((SELECT max(GREATEST(COALESCE(r.meter_start,0),COALESCE(r.meter_end,0))) FROM public.runsheets r WHERE r.vehicle_id=v_vehicle_id AND r.company_id=p_company_id),0)
      )::integer INTO v_prev_odo;
      IF v_new_odo<v_prev_odo THEN RAISE EXCEPTION 'عداد الوقود أقل من آخر قراءة موثقة'; END IF;
    END IF;
    INSERT INTO public.fleet_fuel_transactions(company_id,vehicle_id,fleet_driver_id,driver_user_id,runsheet_id,transaction_date,odometer_km,liters,unit_price,fuel_type,station_name,fuel_card_number,full_tank,receipt_url,reference,notes,created_by)
    VALUES(
      p_company_id,v_vehicle_id,NULLIF(p_payload->>'fleet_driver_id','')::uuid,NULLIF(p_payload->>'driver_user_id','')::uuid,
      NULLIF(p_payload->>'runsheet_id','')::uuid,
      COALESCE(NULLIF(p_payload->>'transaction_date','')::timestamptz,now()),
      v_new_odo,
      NULLIF(p_payload->>'liters','')::numeric,
      COALESCE(NULLIF(p_payload->>'unit_price','')::numeric,0),
      NULLIF(p_payload->>'fuel_type',''),
      p_payload->>'station_name',
      p_payload->>'fuel_card_number',
      (p_payload->>'full_tank')::boolean,
      p_payload->>'receipt_url',p_payload->>'reference',p_payload->>'notes',v_actor.email
    ) RETURNING id INTO v_doc_id;
    v_response:=jsonb_build_object('success',true,'fuel_transaction_id',v_doc_id);

  ELSIF v_command='MAINTENANCE_PLAN_UPSERT' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;
    IF NULLIF(p_payload->>'plan_id','') IS NOT NULL THEN
      v_plan_id:=(p_payload->>'plan_id')::uuid;
      UPDATE public.fleet_maintenance_plans
      SET name=COALESCE(NULLIF(p_payload->>'name',''),name),
          maintenance_type=COALESCE(NULLIF(p_payload->>'maintenance_type',''),maintenance_type),
          active=COALESCE((p_payload->>'active')::boolean,active),
          interval_km=CASE WHEN p_payload ? 'interval_km' THEN NULLIF(p_payload->>'interval_km','')::integer ELSE interval_km END,
          interval_days=CASE WHEN p_payload ? 'interval_days' THEN NULLIF(p_payload->>'interval_days','')::integer ELSE interval_days END,
          alert_km_before=COALESCE(NULLIF(p_payload->>'alert_km_before','')::integer,alert_km_before),
          alert_days_before=COALESCE(NULLIF(p_payload->>'alert_days_before','')::integer,alert_days_before),
          next_service_date=CASE WHEN p_payload ? 'next_service_date' THEN NULLIF(p_payload->>'next_service_date','')::date ELSE next_service_date END,
          next_service_odometer_km=CASE WHEN p_payload ? 'next_service_odometer_km' THEN NULLIF(p_payload->>'next_service_odometer_km','')::integer ELSE next_service_odometer_km END,
          notes=CASE WHEN p_payload ? 'notes' THEN p_payload->>'notes' ELSE notes END,
          updated_at=now()
      WHERE id=v_plan_id AND company_id=p_company_id AND vehicle_id=v_vehicle_id;
    ELSE
      INSERT INTO public.fleet_maintenance_plans(company_id,vehicle_id,plan_code,name,maintenance_type,active,interval_km,interval_days,alert_km_before,alert_days_before,next_service_date,next_service_odometer_km,notes,created_by)
      VALUES(
        p_company_id,v_vehicle_id,btrim(p_payload->>'plan_code'),btrim(p_payload->>'name'),
        COALESCE(NULLIF(p_payload->>'maintenance_type',''),'Preventive'),
        COALESCE((p_payload->>'active')::boolean,true),
        NULLIF(p_payload->>'interval_km','')::integer,
        NULLIF(p_payload->>'interval_days','')::integer,
        COALESCE(NULLIF(p_payload->>'alert_km_before','')::integer,500),
        COALESCE(NULLIF(p_payload->>'alert_days_before','')::integer,30),
        NULLIF(p_payload->>'next_service_date','')::date,
        NULLIF(p_payload->>'next_service_odometer_km','')::integer,
        p_payload->>'notes',v_actor.email
      ) RETURNING id INTO v_plan_id;
    END IF;
    v_response:=jsonb_build_object('success',true,'plan_id',v_plan_id);

  ELSIF v_command='MAINTENANCE_RECORD' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;
    INSERT INTO public.vehicle_maintenance(company_id,vehicle_id,maintenance_type,service_date,odometer_km,vendor_name,description,cost,next_service_date,next_service_odometer_km,status,notes,created_by,maintenance_plan_id,priority,parts_cost,labor_cost,downtime_hours,work_order_reference,incident_id)
    VALUES(
      p_company_id,v_vehicle_id,COALESCE(NULLIF(p_payload->>'maintenance_type',''),'Preventive'),
      COALESCE(NULLIF(p_payload->>'service_date','')::date,current_date),
      NULLIF(p_payload->>'odometer_km','')::integer,
      p_payload->>'vendor_name',p_payload->>'description',
      COALESCE(NULLIF(p_payload->>'cost','')::numeric,0),
      NULLIF(p_payload->>'next_service_date','')::date,
      NULLIF(p_payload->>'next_service_odometer_km','')::integer,
      COALESCE(NULLIF(p_payload->>'status',''),'Completed'),
      p_payload->>'notes',v_actor.email,
      NULLIF(p_payload->>'maintenance_plan_id','')::uuid,
      COALESCE(NULLIF(p_payload->>'priority',''),'Medium'),
      COALESCE(NULLIF(p_payload->>'parts_cost','')::numeric,0),
      COALESCE(NULLIF(p_payload->>'labor_cost','')::numeric,0),
      COALESCE(NULLIF(p_payload->>'downtime_hours','')::numeric,0),
      p_payload->>'work_order_reference',
      NULLIF(p_payload->>'incident_id','')::uuid
    ) RETURNING id INTO v_doc_id;

    IF NULLIF(p_payload->>'maintenance_plan_id','') IS NOT NULL AND COALESCE(NULLIF(p_payload->>'status',''),'Completed')='Completed' THEN
      UPDATE public.fleet_maintenance_plans
      SET last_service_date=COALESCE(NULLIF(p_payload->>'service_date','')::date,current_date),
          last_service_odometer_km=NULLIF(p_payload->>'odometer_km','')::integer,
          next_service_date=NULLIF(p_payload->>'next_service_date','')::date,
          next_service_odometer_km=NULLIF(p_payload->>'next_service_odometer_km','')::integer,
          updated_at=now()
      WHERE id=(p_payload->>'maintenance_plan_id')::uuid AND company_id=p_company_id AND vehicle_id=v_vehicle_id;
    END IF;
    v_response:=jsonb_build_object('success',true,'maintenance_id',v_doc_id);

  ELSIF v_command='INCIDENT_CREATE' THEN
    v_vehicle_id:=NULLIF(p_payload->>'vehicle_id','')::uuid;
    IF v_vehicle_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير صالحة'; END IF;
    INSERT INTO public.fleet_incidents(company_id,vehicle_id,fleet_driver_id,driver_user_id,runsheet_id,occurred_at,incident_type,severity,status,description,root_cause,corrective_action,customer_impact,product_loss_value,vehicle_damage_cost,insurance_reference,created_by)
    VALUES(
      p_company_id,v_vehicle_id,NULLIF(p_payload->>'fleet_driver_id','')::uuid,NULLIF(p_payload->>'driver_user_id','')::uuid,
      NULLIF(p_payload->>'runsheet_id','')::uuid,
      COALESCE(NULLIF(p_payload->>'occurred_at','')::timestamptz,now()),
      btrim(p_payload->>'incident_type'),COALESCE(NULLIF(p_payload->>'severity',''),'Medium'),
      COALESCE(NULLIF(p_payload->>'status',''),'Open'),btrim(p_payload->>'description'),
      p_payload->>'root_cause',p_payload->>'corrective_action',p_payload->>'customer_impact',
      COALESCE(NULLIF(p_payload->>'product_loss_value','')::numeric,0),
      COALESCE(NULLIF(p_payload->>'vehicle_damage_cost','')::numeric,0),
      p_payload->>'insurance_reference',v_actor.email
    ) RETURNING id INTO v_incident_id;
    v_response:=jsonb_build_object('success',true,'incident_id',v_incident_id);

  ELSIF v_command='PERFORMANCE_EVENT_CREATE' THEN
    INSERT INTO public.fleet_driver_performance_events(company_id,fleet_driver_id,driver_user_id,vehicle_id,runsheet_id,incident_id,event_date,category,severity,points,repeat_key,description,corrective_action,status,created_by)
    VALUES(
      p_company_id,NULLIF(p_payload->>'fleet_driver_id','')::uuid,NULLIF(p_payload->>'driver_user_id','')::uuid,
      NULLIF(p_payload->>'vehicle_id','')::uuid,NULLIF(p_payload->>'runsheet_id','')::uuid,NULLIF(p_payload->>'incident_id','')::uuid,
      COALESCE(NULLIF(p_payload->>'event_date','')::timestamptz,now()),
      btrim(p_payload->>'category'),COALESCE(NULLIF(p_payload->>'severity',''),'Medium'),
      COALESCE(NULLIF(p_payload->>'points','')::integer,0),
      NULLIF(p_payload->>'repeat_key',''),btrim(p_payload->>'description'),
      p_payload->>'corrective_action',COALESCE(NULLIF(p_payload->>'status',''),'Open'),v_actor.email
    ) RETURNING id INTO v_doc_id;
    v_response:=jsonb_build_object('success',true,'performance_event_id',v_doc_id);

  ELSIF v_command='EXPENSE_CREATE' THEN
    INSERT INTO public.fleet_expenses(company_id,vehicle_id,fleet_driver_id,driver_user_id,runsheet_id,expense_date,category,amount,supplier_id,reference,accounting_reference,notes,created_by)
    VALUES(
      p_company_id,NULLIF(p_payload->>'vehicle_id','')::uuid,NULLIF(p_payload->>'fleet_driver_id','')::uuid,NULLIF(p_payload->>'driver_user_id','')::uuid,
      NULLIF(p_payload->>'runsheet_id','')::uuid,
      COALESCE(NULLIF(p_payload->>'expense_date','')::timestamptz,now()),
      btrim(p_payload->>'category'),NULLIF(p_payload->>'amount','')::numeric,
      NULLIF(p_payload->>'supplier_id','')::uuid,p_payload->>'reference',p_payload->>'accounting_reference',p_payload->>'notes',v_actor.email
    ) RETURNING id INTO v_doc_id;
    v_response:=jsonb_build_object('success',true,'expense_id',v_doc_id);

  ELSIF v_command='RUNSHEET_ASSIGN' THEN
    DECLARE
      v_rs_id uuid;
      v_fleet_driver_id uuid;
      v_driver_user_id uuid;
      v_load_weight numeric:=0;
      v_load_volume numeric:=0;
      v_missing_weight integer:=0;
      v_missing_volume integer:=0;
      v_manage jsonb;
      v_warning text:=NULL;
    BEGIN
      v_rs_id:=(p_payload->>'runsheet_id')::uuid;
      v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
      v_driver_user_id:=NULLIF(p_payload->>'driver_user_id','')::uuid;
      v_fleet_driver_id:=NULLIF(p_payload->>'fleet_driver_id','')::uuid;

      SELECT * INTO v_runsheet FROM public.runsheets
      WHERE id=v_rs_id AND company_id=p_company_id FOR UPDATE;
      IF NOT FOUND THEN RAISE EXCEPTION 'الرانشيت غير موجود'; END IF;
      IF v_runsheet.status NOT IN ('Open','Confirmed') THEN
        RAISE EXCEPTION 'لا يمكن إسناد مركبة/سائق لرانشيت في حالة: %',v_runsheet.status;
      END IF;

      SELECT * INTO v_vehicle FROM public.vehicles
      WHERE id=v_vehicle_id AND company_id=p_company_id FOR UPDATE;
      IF NOT FOUND THEN RAISE EXCEPTION 'المركبة غير موجودة ضمن الشركة'; END IF;
      IF lower(coalesce(v_vehicle.status,'Active')) IN ('inactive','retired','maintenance','out_of_service') THEN
        RAISE EXCEPTION 'المركبة غير متاحة للتشغيل: %',coalesce(v_vehicle.status,'NULL');
      END IF;
      IF lower(coalesce(v_vehicle.operational_condition,'Good'))='Poor' THEN
        v_warning:='حالة المركبة Poor — الإسناد مسموح لكن غير موصى به للمسارات الثقيلة/البعيدة';
      END IF;

      IF v_fleet_driver_id IS NOT NULL THEN
        IF NOT EXISTS(
          SELECT 1 FROM public.fleet_drivers fd
          WHERE fd.id=v_fleet_driver_id AND fd.company_id=p_company_id AND fd.status='Active'
        ) THEN RAISE EXCEPTION 'السائق الإداري غير صالح للشركة'; END IF;
        IF v_driver_user_id IS NULL THEN
          SELECT fd.user_id INTO v_driver_user_id
          FROM public.fleet_drivers fd
          WHERE fd.id=v_fleet_driver_id AND fd.company_id=p_company_id LIMIT 1;
        END IF;
      END IF;

      IF v_driver_user_id IS NULL THEN v_driver_user_id:=v_runsheet.driver_id; END IF;

      IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
        SELECT 1 FROM public.users u
        WHERE u.id=v_driver_user_id
          AND u.company_id=p_company_id
          AND coalesce(u.status,'Active')='Active'
          AND (
            u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
            OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
          )
      ) THEN RAISE EXCEPTION 'السائق التشغيلي غير صالح أو ليس هوية سائق/توصيل'; END IF;

      IF v_fleet_driver_id IS NOT NULL THEN
        DECLARE
          v_license_expiry date;
        BEGIN
          SELECT d.expiry_date INTO v_license_expiry
          FROM public.fleet_driver_documents d
          WHERE d.company_id=p_company_id
            AND d.fleet_driver_id=v_fleet_driver_id
            AND d.document_type='DriverLicense'
            AND coalesce(d.status,'Active')='Active'
          ORDER BY d.expiry_date DESC NULLS LAST,d.created_at DESC
          LIMIT 1;

          IF v_license_expiry IS NOT NULL AND v_license_expiry < current_date THEN
            RAISE EXCEPTION 'رخصة السائق منتهية في %',v_license_expiry;
          END IF;
          IF v_license_expiry IS NULL THEN
            v_warning:=coalesce(v_warning || ' | ','') || 'صلاحية رخصة السائق غير مؤكدة';
          END IF;
        END;
      END IF;

      SELECT
        COALESCE(sum(COALESCE(rsd.qty_ordered,0)*COALESCE(i.weight_kg,0)),0),
        COALESCE(sum(COALESCE(rsd.qty_ordered,0)*COALESCE(i.volume_m3,0)),0),
        count(*) FILTER (WHERE i.weight_kg IS NULL),
        count(*) FILTER (WHERE i.volume_m3 IS NULL)
      INTO v_load_weight,v_load_volume,v_missing_weight,v_missing_volume
      FROM public.run_sheet_details rsd
      LEFT JOIN public.items i ON i.id=rsd.item_id AND i.item_code=rsd.item_code
      WHERE rsd.runsheet_id=v_rs_id;

      IF v_vehicle.max_weight_kg IS NOT NULL AND v_vehicle.max_weight_kg>0 AND v_load_weight>v_vehicle.max_weight_kg THEN
        RAISE EXCEPTION 'السعة الوزنية للمركبة غير كافية: الحمل % كجم / السعة % كجم',round(v_load_weight,2),round(v_vehicle.max_weight_kg,2);
      END IF;
      IF v_vehicle.max_volume_m3 IS NOT NULL AND v_vehicle.max_volume_m3>0 AND v_load_volume>v_vehicle.max_volume_m3 THEN
        RAISE EXCEPTION 'حجم صندوق المركبة غير كافٍ: الحمل % م³ / السعة % م³',round(v_load_volume,3),round(v_vehicle.max_volume_m3,3);
      END IF;

      IF v_missing_weight>0 OR v_missing_volume>0 THEN
        v_warning:=COALESCE(v_warning || ' | ','') || 'بيانات وزن/حجم غير مكتملة لبعض أصناف الرانشيت؛ المطابقة الكاملة غير مؤكدة';
      END IF;

      v_manage:=public.manage_runsheet_atomic(
        p_company_id,v_runsheet.runsheet_code,'UPDATE',
        COALESCE(p_actor_email,v_actor.email),v_driver_user_id,v_vehicle_id
      );

      v_response:=v_manage || jsonb_build_object(
        'command','RUNSHEET_ASSIGN',
        'runsheet_id',v_rs_id,'vehicle_id',v_vehicle_id,
        'driver_user_id',v_driver_user_id,'fleet_driver_id',v_fleet_driver_id,
        'load_weight_kg',round(v_load_weight,2),'load_volume_m3',round(v_load_volume,3),
        'vehicle_max_weight_kg',v_vehicle.max_weight_kg,'vehicle_max_volume_m3',v_vehicle.max_volume_m3,
        'planning_warning',v_warning
      );
    END;


  ELSIF v_command='VEHICLE_OPERATION_BIND' THEN
    DECLARE
      v_operation_type text := upper(btrim(coalesce(p_payload->>'operation_type','')));
      v_vehicle_bind_id uuid := NULLIF(btrim(p_payload->>'vehicle_id'),'')::uuid;
      v_runsheet_id uuid := NULLIF(btrim(p_payload->>'runsheet_id'),'')::uuid;
      v_voucher_id uuid := NULLIF(btrim(p_payload->>'voucher_id'),'')::uuid;
      v_driver_user_id uuid := NULLIF(btrim(p_payload->>'driver_user_id'),'')::uuid;
      v_delivery_rep_user_id uuid := NULLIF(btrim(p_payload->>'delivery_rep_user_id'),'')::uuid;
      v_direct_sales_rep_id uuid := NULLIF(btrim(p_payload->>'direct_sales_rep_id'),'')::uuid;
      v_voucher public.stock_vouchers%ROWTYPE;
      v_rs public.runsheets%ROWTYPE;
      v_driver_name text;
      v_delivery_name text;
      v_rep_name text;
      v_manage jsonb;
    BEGIN
      IF v_vehicle_bind_id IS NULL THEN
        RAISE EXCEPTION 'المركبة مطلوبة لربط العملية';
      END IF;

      SELECT * INTO v_vehicle2
      FROM public.vehicles
      WHERE id=v_vehicle_bind_id
        AND company_id=p_company_id
      FOR UPDATE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'المركبة غير موجودة ضمن الشركة';
      END IF;

      IF lower(coalesce(v_vehicle2.status,'Active')) IN ('inactive','retired','maintenance','out_of_service') THEN
        RAISE EXCEPTION 'المركبة غير متاحة للتشغيل: %',coalesce(v_vehicle2.status,'NULL');
      END IF;

      IF v_operation_type='RUNSHEET' THEN
        IF v_runsheet_id IS NULL THEN
          RAISE EXCEPTION 'الرانشيت مطلوب';
        END IF;

        SELECT * INTO v_runsheet
        FROM public.runsheets
        WHERE id=v_runsheet_id
          AND company_id=p_company_id
        FOR UPDATE;

        IF NOT FOUND THEN
          RAISE EXCEPTION 'الرانشيت غير موجود';
        END IF;

        IF v_runsheet.status NOT IN ('Open','Confirmed') THEN
          RAISE EXCEPTION 'لا يمكن ربط مركبة برانشيت في الحالة: %',v_runsheet.status;
        END IF;

        IF v_driver_user_id IS NULL THEN
          v_driver_user_id:=v_runsheet.driver_id;
        END IF;

        IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND (
              u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
              OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
            )
        ) THEN
          RAISE EXCEPTION 'السائق التشغيلي غير صالح أو ليس هوية سائق/توصيل';
        END IF;

        IF v_delivery_rep_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_delivery_rep_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND (u.role IN ('مندوب توصيل','مشرف توصيل') OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb)
        ) THEN
          RAISE EXCEPTION 'مندوب التوصيل غير صالح للشركة';
        END IF;

        v_manage:=public.manage_runsheet_atomic(
          p_company_id,
          v_runsheet.runsheet_code,
          'UPDATE',
          COALESCE(p_actor_email,v_actor.email),
          v_driver_user_id,
          v_vehicle_bind_id
        );

        IF v_delivery_rep_user_id IS NOT NULL THEN
          UPDATE public.runsheets
          SET deliverer_id=v_delivery_rep_user_id,
              updated_at=now()
          WHERE id=v_runsheet.id
            AND company_id=p_company_id
            AND status IN ('Open','Confirmed');

          IF NOT FOUND THEN
            RAISE EXCEPTION 'تعذر حفظ مندوب التوصيل للرانشيت';
          END IF;
        END IF;

        SELECT coalesce(u.name,u.email) INTO v_driver_name
        FROM public.users u
        WHERE u.id=(SELECT driver_id FROM public.runsheets WHERE id=v_runsheet.id);

        SELECT coalesce(u.name,u.email) INTO v_delivery_name
        FROM public.users u
        WHERE u.id=(SELECT deliverer_id FROM public.runsheets WHERE id=v_runsheet.id);

        PERFORM set_config(
          'request.jwt.claims',
          jsonb_build_object('email',v_actor.email)::text,
          true
        );

        v_response:=v_manage || jsonb_build_object(
          'command','VEHICLE_OPERATION_BIND',
          'operation_type','RUNSHEET',
          'runsheet_id',v_runsheet.id,
          'runsheet_code',v_runsheet.runsheet_code,
          'vehicle_id',v_vehicle_bind_id,
          'driver_user_id',(SELECT driver_id FROM public.runsheets WHERE id=v_runsheet.id),
          'driver_name',v_driver_name,
          'delivery_rep_user_id',(SELECT deliverer_id FROM public.runsheets WHERE id=v_runsheet.id),
          'delivery_rep_name',v_delivery_name
        );

      ELSIF v_operation_type='BRANCH_TRANSFER' THEN
        IF v_voucher_id IS NULL THEN
          RAISE EXCEPTION 'إذن تحويل الفرع مطلوب';
        END IF;

        IF v_driver_user_id IS NULL THEN
          RAISE EXCEPTION 'سائق تحويل الفرع مطلوب';
        END IF;

        SELECT * INTO v_voucher
        FROM public.stock_vouchers
        WHERE id=v_voucher_id
          AND company_id=p_company_id
        FOR UPDATE;

        IF NOT FOUND THEN
          RAISE EXCEPTION 'إذن التحويل غير موجود';
        END IF;

        IF v_voucher.type<>'Transfer' THEN
          RAISE EXCEPTION 'الوثيقة المحددة ليست تحويل فرع';
        END IF;

        IF NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND (
              u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
              OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
            )
        ) THEN
          RAISE EXCEPTION 'سائق التحويل غير صالح أو ليس هوية سائق/توصيل';
        END IF;

        IF v_voucher.vehicle_id IS NOT NULL
           AND (
             v_voucher.vehicle_id IS DISTINCT FROM v_vehicle_bind_id
             OR v_voucher.driver_id IS DISTINCT FROM v_driver_user_id
           )
           AND v_voucher.status<>'Draft' THEN
          RAISE EXCEPTION 'تحويل الفرع المنفذ لا يمكن تغيير هوية مركبته/سائقه';
        END IF;

        PERFORM set_config(
          'request.jwt.claims',
          jsonb_build_object('email',v_actor.email)::text,
          true
        );

        UPDATE public.stock_vouchers
        SET vehicle_id=v_vehicle_bind_id,
            driver_id=v_driver_user_id,
            updated_at=now()
        WHERE id=v_voucher.id
          AND company_id=p_company_id;

        IF NOT FOUND THEN
          RAISE EXCEPTION 'فشل ربط المركبة بتحويل الفرع';
        END IF;

        SELECT coalesce(u.name,u.email) INTO v_driver_name
        FROM public.users u
        WHERE u.id=v_driver_user_id;

        v_response:=jsonb_build_object(
          'success',true,
          'command','VEHICLE_OPERATION_BIND',
          'operation_type','BRANCH_TRANSFER',
          'voucher_id',v_voucher.id,
          'voucher_code',v_voucher.voucher_code,
          'vehicle_id',v_vehicle_bind_id,
          'driver_user_id',v_driver_user_id,
          'driver_name',v_driver_name,
          'status',(SELECT status FROM public.stock_vouchers WHERE id=v_voucher.id)
        );

      ELSIF v_operation_type='DIRECT_SALE' THEN
        IF v_voucher_id IS NULL THEN
          RAISE EXCEPTION 'إذن البيع المباشر مطلوب';
        END IF;

        SELECT * INTO v_voucher
        FROM public.stock_vouchers
        WHERE id=v_voucher_id
          AND company_id=p_company_id
        FOR UPDATE;

        IF NOT FOUND THEN
          RAISE EXCEPTION 'إذن البيع المباشر غير موجود';
        END IF;

        IF v_voucher.type<>'DirectSale' THEN
          RAISE EXCEPTION 'الوثيقة المحددة ليست بيعًا مباشرًا';
        END IF;

        IF v_direct_sales_rep_id IS NULL THEN
          v_direct_sales_rep_id:=v_voucher.custodian_user_id;
        END IF;

        IF v_direct_sales_rep_id IS NULL OR NOT EXISTS(
          SELECT 1
          FROM public.users u
          WHERE u.id=v_direct_sales_rep_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND u.role='مندوب بيع مباشر'
            AND COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
        ) THEN
          RAISE EXCEPTION 'مندوب البيع المباشر غير صالح للشركة';
        END IF;

        PERFORM set_config(
          'request.jwt.claims',
          jsonb_build_object('email',v_actor.email)::text,
          true
        );

        IF v_voucher.status='Draft' THEN
          UPDATE public.stock_vouchers
          SET to_type='Vehicle',
              to_id=v_vehicle_bind_id,
              custodian_user_id=v_direct_sales_rep_id,
              updated_at=now()
          WHERE id=v_voucher.id
            AND company_id=p_company_id
            AND status='Draft';
        ELSE
          IF v_voucher.to_type<>'Vehicle'
             OR v_voucher.to_id IS DISTINCT FROM v_vehicle_bind_id
             OR v_voucher.custodian_user_id IS DISTINCT FROM v_direct_sales_rep_id THEN
            RAISE EXCEPTION 'البيع المباشر المنفذ مرتبط بالفعل بمركبة/مندوب مختلف';
          END IF;
        END IF;

        SELECT coalesce(u.name,u.email) INTO v_rep_name
        FROM public.users u
        WHERE u.id=v_direct_sales_rep_id;

        v_response:=jsonb_build_object(
          'success',true,
          'command','VEHICLE_OPERATION_BIND',
          'operation_type','DIRECT_SALE',
          'voucher_id',v_voucher.id,
          'voucher_code',v_voucher.voucher_code,
          'vehicle_id',v_vehicle_bind_id,
          'direct_sales_rep_id',v_direct_sales_rep_id,
          'direct_sales_rep_name',v_rep_name,
          'status',(SELECT status FROM public.stock_vouchers WHERE id=v_voucher.id)
        );

      ELSE
        RAISE EXCEPTION 'نوع ربط العملية غير مدعوم: %',v_operation_type;
      END IF;
    END;

  ELSIF v_command='STATUS_CHANGE' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    SELECT status INTO v_old_status FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'المركبة غير موجودة'; END IF;
    v_new_status:=btrim(p_payload->>'status');
    IF NULLIF(v_new_status,'') IS NULL THEN RAISE EXCEPTION 'الحالة الجديدة مطلوبة'; END IF;
    UPDATE public.vehicles SET status=v_new_status WHERE id=v_vehicle_id AND company_id=p_company_id;
    INSERT INTO public.vehicle_status_history(company_id,vehicle_id,old_status,new_status,reason,changed_by)
    VALUES(p_company_id,v_vehicle_id,v_old_status,v_new_status,p_payload->>'reason',v_actor.email);
    v_response:=jsonb_build_object('success',true,'vehicle_id',v_vehicle_id,'old_status',v_old_status,'new_status',v_new_status);

  ELSE
    RAISE EXCEPTION 'أمر Fleet غير مدعوم: %',v_command;
  END IF;

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_response,completed_at=now()
  WHERE id=v_registry.id;

  RETURN v_response;
EXCEPTION
  WHEN OTHERS THEN
    -- The registry row is rolled back together with the failed transaction.
    RAISE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fleet_query(p_company_id uuid, p_view text, p_payload jsonb DEFAULT '{}'::jsonb, p_actor_user_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_view text:=lower(btrim(coalesce(p_view,'')));
  v_vehicle_id uuid;
  v_driver_id uuid;
  v_limit integer:=LEAST(GREATEST(COALESCE((p_payload->>'limit')::integer,50),1),200);
  v_offset integer:=GREATEST(COALESCE((p_payload->>'offset')::integer,0),0);
  v_from date:=COALESCE(NULLIF(p_payload->>'from_date','')::date,current_date-interval '30 days');
  v_to date:=COALESCE(NULLIF(p_payload->>'to_date','')::date,current_date);
  v_response jsonb;
  v_branch_id uuid;
BEGIN
  IF auth.uid() IS NOT NULL THEN
    SELECT * INTO v_actor FROM public.users
    WHERE auth_id=auth.uid() AND company_id=p_company_id AND COALESCE(status,'Active')='Active' LIMIT 1;
  ELSE
    SELECT * INTO v_actor FROM public.users
    WHERE id=p_actor_user_id AND company_id=p_company_id AND COALESCE(status,'Active')='Active' LIMIT 1;
  END IF;
  IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم أو سياق الشركة غير صالح'; END IF;

  IF NOT (
    COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "*" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "fleet.manage" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "fleet.read" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "reports" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "warehouse" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "warehouse_supervisor" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "warehouse_manager" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "vouchers" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "transfer" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "direct-sale" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "van-sales" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "delivery" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "delivery_supervisor" ]'::jsonb
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "vehicle-count" ]'::jsonb
    OR v_actor.role IN ('مدير عام','مدير مخازن','مدير مالي','مشرف توصيل','مشرف مخازن','مخزني','مندوب بيع مباشر','مندوب توصيل')
  ) THEN
    RAISE EXCEPTION 'غير مصرح بقراءة إدارة الأسطول';
  END IF;

  IF v_view='dashboard' THEN
    SELECT jsonb_build_object(
      'success',true,
      'as_of',now(),
      'vehicles',(SELECT count(*) FROM public.vehicles WHERE company_id=p_company_id),
      'active_vehicles',(SELECT count(*) FROM public.vehicles WHERE company_id=p_company_id AND COALESCE(status,'Active')='Active'),
      'maintenance_due',(SELECT count(*) FROM public.fleet_maintenance_plans mp WHERE mp.company_id=p_company_id AND mp.active=true AND (
        (mp.next_service_date IS NOT NULL AND mp.next_service_date<=current_date+30)
        OR EXISTS(
          SELECT 1 FROM public.vehicles v
          WHERE v.id=mp.vehicle_id AND v.company_id=p_company_id
            AND mp.next_service_odometer_km IS NOT NULL
            AND mp.next_service_odometer_km <= GREATEST(
              COALESCE((SELECT max(vt.meter_reading) FROM public.vehicle_tracking vt WHERE vt.vehicle_id=v.id AND vt.company_id=p_company_id),0),
              COALESCE((SELECT max(GREATEST(COALESCE(r.meter_start,0),COALESCE(r.meter_end,0))) FROM public.runsheets r WHERE r.vehicle_id=v.id AND r.company_id=p_company_id),0)
            ) + mp.alert_km_before
        )
      )),
      'documents_expiring_30d',(
        SELECT count(*) FROM public.vehicle_documents d WHERE d.company_id=p_company_id AND d.expiry_date BETWEEN current_date AND current_date+30
      ) + (
        SELECT count(*) FROM public.fleet_driver_documents d WHERE d.company_id=p_company_id AND d.expiry_date BETWEEN current_date AND current_date+30
      ),
      'contracts_expiring_30d',(SELECT count(*) FROM public.fleet_vehicle_contracts c WHERE c.company_id=p_company_id AND c.status='Active' AND c.end_date BETWEEN current_date AND current_date+30),
      'fuel_cost_30d',COALESCE((SELECT sum(f.total_cost) FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.transaction_date>=now()-interval '30 days'),0),
      'fuel_liters_30d',COALESCE((SELECT sum(f.liters) FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.transaction_date>=now()-interval '30 days'),0),
      'distance_km_30d',COALESCE((
        SELECT sum(r.meter_end-r.meter_start)
        FROM public.runsheets r
        WHERE r.company_id=p_company_id AND r.run_date>=current_date-30
          AND r.vehicle_id IS NOT NULL AND r.meter_start IS NOT NULL AND r.meter_end IS NOT NULL
          AND r.meter_end>=r.meter_start
      ),0),
      'trip_fuel_efficiency',(
        SELECT avg(x.fuel_liters/x.distance_km*100)
        FROM (
          SELECT r.id,
                 (r.meter_end-r.meter_start)::numeric distance_km,
                 COALESCE((SELECT sum(f.liters) FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.runsheet_id=r.id),0) fuel_liters
          FROM public.runsheets r
          WHERE r.company_id=p_company_id
            AND r.run_date>=current_date-30
            AND r.meter_start IS NOT NULL AND r.meter_end IS NOT NULL
            AND r.meter_end>r.meter_start
            AND EXISTS(SELECT 1 FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.runsheet_id=r.id)
        ) x
        WHERE x.fuel_liters>0 AND x.distance_km>0
      )
    ) INTO v_response;

  ELSIF v_view='vehicles' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.vehicle_code),'[]'::jsonb)
              FROM (
                SELECT v.id,v.vehicle_code,v.model,v.license_plate,v.status,v.vehicle_type,v.operation_mode,
                       v.ownership_type,v.model_year,v.vin,v.fuel_type,v.refrigerated,v.max_weight_kg,v.max_volume_m3,
                       v.driver_id,v.fleet_driver_id,
                       v.expected_km_per_liter,
                       v.operational_condition,
                       v.route_capability,
                       COALESCE(
                         (SELECT max(vt.meter_reading) FROM public.vehicle_tracking vt WHERE vt.vehicle_id=v.id AND vt.company_id=p_company_id),
                         0
                       ) AS last_odometer_km,
                       (SELECT max(vm.service_date) FROM public.vehicle_maintenance vm WHERE vm.vehicle_id=v.id AND vm.company_id=p_company_id) AS last_maintenance_date,
                       (SELECT min(mp.next_service_date) FROM public.fleet_maintenance_plans mp WHERE mp.vehicle_id=v.id AND mp.company_id=p_company_id AND mp.active=true) AS next_service_date,
                       (SELECT c.end_date FROM public.fleet_vehicle_contracts c WHERE c.vehicle_id=v.id AND c.company_id=p_company_id AND c.status='Active' ORDER BY c.end_date NULLS LAST LIMIT 1) AS active_contract_end
                FROM public.vehicles v
                WHERE v.company_id=p_company_id
                  AND (NULLIF(btrim(p_payload->>'search'),'') IS NULL
                       OR v.vehicle_code ILIKE '%'||btrim(p_payload->>'search')||'%'
                       OR v.license_plate ILIKE '%'||btrim(p_payload->>'search')||'%'
                       OR COALESCE(v.model,'') ILIKE '%'||btrim(p_payload->>'search')||'%')
                ORDER BY v.vehicle_code
                LIMIT v_limit OFFSET v_offset
              ) x),
      'limit',v_limit,'offset',v_offset
    ) INTO v_response;

  ELSIF v_view='vehicle_detail' THEN
    v_vehicle_id:=(p_payload->>'vehicle_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.vehicles WHERE id=v_vehicle_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'المركبة غير موجودة'; END IF;
    SELECT jsonb_build_object(
      'success',true,
      'vehicle',(SELECT to_jsonb(v) FROM public.vehicles v WHERE v.id=v_vehicle_id AND v.company_id=p_company_id),
      'driver',(SELECT to_jsonb(fd) FROM public.fleet_drivers fd JOIN public.vehicles v ON v.fleet_driver_id=fd.id WHERE v.id=v_vehicle_id AND v.company_id=p_company_id),
      'documents',(SELECT COALESCE(jsonb_agg(to_jsonb(d) ORDER BY d.expiry_date NULLS LAST),'[]'::jsonb) FROM public.vehicle_documents d WHERE d.vehicle_id=v_vehicle_id AND d.company_id=p_company_id),
      'driver_documents',(SELECT COALESCE(jsonb_agg(to_jsonb(d) ORDER BY d.expiry_date NULLS LAST),'[]'::jsonb) FROM public.fleet_driver_documents d JOIN public.vehicles v ON v.fleet_driver_id=d.fleet_driver_id WHERE v.id=v_vehicle_id AND v.company_id=p_company_id),
      'contracts',(SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.start_date DESC),'[]'::jsonb) FROM public.fleet_vehicle_contracts c WHERE c.vehicle_id=v_vehicle_id AND c.company_id=p_company_id),
      'maintenance',(SELECT COALESCE(jsonb_agg(to_jsonb(m) ORDER BY m.service_date DESC),'[]'::jsonb) FROM public.vehicle_maintenance m WHERE m.vehicle_id=v_vehicle_id AND m.company_id=p_company_id LIMIT 50),
      'fuel',(SELECT COALESCE(jsonb_agg(to_jsonb(f) ORDER BY f.transaction_date DESC),'[]'::jsonb) FROM public.fleet_fuel_transactions f WHERE f.vehicle_id=v_vehicle_id AND f.company_id=p_company_id LIMIT 100),
      'incidents',(SELECT COALESCE(jsonb_agg(to_jsonb(i) ORDER BY i.occurred_at DESC),'[]'::jsonb) FROM public.fleet_incidents i WHERE i.vehicle_id=v_vehicle_id AND i.company_id=p_company_id LIMIT 50),
      'assignments',(SELECT COALESCE(jsonb_agg(to_jsonb(a) ORDER BY a.start_at DESC),'[]'::jsonb) FROM public.fleet_vehicle_assignments a WHERE a.vehicle_id=v_vehicle_id AND a.company_id=p_company_id LIMIT 50),
      'runsheets',(SELECT COALESCE(jsonb_agg(
        to_jsonb(r) ||
        jsonb_build_object(
          'driver_name',coalesce(du.name,du.email),
          'delivery_rep_name',coalesce(deu.name,deu.email)
        )
        ORDER BY r.run_date DESC
      ),'[]'::jsonb)
      FROM public.runsheets r
      LEFT JOIN public.users du ON du.id=r.driver_id AND du.company_id=p_company_id
      LEFT JOIN public.users deu ON deu.id=r.deliverer_id AND deu.company_id=p_company_id
      WHERE r.vehicle_id=v_vehicle_id AND r.company_id=p_company_id
      LIMIT 50),
      'transfer_operations',(SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id',sv.id,
          'voucher_code',sv.voucher_code,
          'status',sv.status,
          'reference',sv.reference,
          'operation_date',sv.voucher_date,
          'vehicle_id',sv.vehicle_id,
          'driver_id',sv.driver_id,
          'driver_name',coalesce(du.name,du.email),
          'from_branch_name',fb.name,
          'to_branch_name',tb.name
        )
        ORDER BY sv.voucher_date DESC,sv.created_at DESC
      ),'[]'::jsonb)
      FROM public.stock_vouchers sv
      LEFT JOIN public.users du ON du.id=sv.driver_id AND du.company_id=p_company_id
      LEFT JOIN public.branches fb ON fb.id=sv.from_id AND fb.company_id=p_company_id
      LEFT JOIN public.branches tb ON tb.id=sv.to_id AND tb.company_id=p_company_id
      WHERE sv.company_id=p_company_id
        AND sv.type='Transfer'
        AND sv.vehicle_id=v_vehicle_id
      LIMIT 50),
      'direct_sales',(SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id',sv.id,
          'voucher_code',sv.voucher_code,
          'status',sv.status,
          'reference',sv.reference,
          'operation_date',sv.voucher_date,
          'vehicle_id',sv.to_id,
          'direct_sales_rep_id',sv.custodian_user_id,
          'direct_sales_rep_name',coalesce(rep.name,rep.email)
        )
        ORDER BY sv.voucher_date DESC,sv.created_at DESC
      ),'[]'::jsonb)
      FROM public.stock_vouchers sv
      LEFT JOIN public.users rep ON rep.id=sv.custodian_user_id AND rep.company_id=p_company_id
      WHERE sv.company_id=p_company_id
        AND sv.type='DirectSale'
        AND sv.to_type='Vehicle'
        AND sv.to_id=v_vehicle_id
      LIMIT 50),
      'expenses',(SELECT COALESCE(jsonb_agg(to_jsonb(e) ORDER BY e.expense_date DESC),'[]'::jsonb) FROM public.fleet_expenses e WHERE e.vehicle_id=v_vehicle_id AND e.company_id=p_company_id LIMIT 50)
    ) INTO v_response;


  ELSIF v_view='vehicle_operation_candidates' THEN
    DECLARE
      v_candidate_vehicle_id uuid := NULLIF(btrim(p_payload->>'vehicle_id'),'')::uuid;
    BEGIN
      IF v_candidate_vehicle_id IS NULL THEN
        RAISE EXCEPTION 'المركبة مطلوبة لعرض العمليات المتاحة';
      END IF;

      IF NOT EXISTS(
        SELECT 1 FROM public.vehicles v
        WHERE v.id=v_candidate_vehicle_id
          AND v.company_id=p_company_id
      ) THEN
        RAISE EXCEPTION 'المركبة غير موجودة ضمن الشركة';
      END IF;

      v_branch_id := NULLIF(btrim(p_payload->>'branch_id'),'')::uuid;
      IF v_branch_id IS NOT NULL
         AND NOT EXISTS(
           SELECT 1 FROM public.branches b
           WHERE b.id=v_branch_id
             AND b.company_id=p_company_id
             AND COALESCE(b.is_active,true)=true
         ) THEN
        RAISE EXCEPTION 'فرع التصفية غير موجود أو غير نشط للشركة';
      END IF;

      SELECT jsonb_build_object(
        'success',true,
        'vehicle_id',v_candidate_vehicle_id,
        'branches',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',b.id,'branch_code',b.branch_code,'name',b.name) ORDER BY b.name,b.branch_code),'[]'::jsonb)
          FROM public.branches b
          WHERE b.company_id=p_company_id
            AND COALESCE(b.is_active,true)=true),
        'runsheets',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.run_date DESC,x.runsheet_code DESC),'[]'::jsonb)
          FROM (
            SELECT r.id,r.runsheet_code,r.run_date,r.status,r.vehicle_id,r.driver_id,r.deliverer_id,
                   coalesce(du.name,du.email) AS driver_name,
                   coalesce(deu.name,deu.email) AS delivery_rep_name
            FROM public.runsheets r
            LEFT JOIN public.users du ON du.id=r.driver_id AND du.company_id=p_company_id
            LEFT JOIN public.users deu ON deu.id=r.deliverer_id AND deu.company_id=p_company_id
            WHERE r.company_id=p_company_id
              AND r.status IN ('Open','Confirmed')
            ORDER BY r.run_date DESC,r.runsheet_code DESC
            LIMIT 50
          ) x),
        'transfers',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.voucher_date DESC,x.voucher_code DESC),'[]'::jsonb)
          FROM (
            SELECT sv.id,sv.voucher_code,sv.voucher_date,sv.status,sv.reference,
                   sv.from_id AS from_branch_id,
                   sv.to_id AS to_branch_id,
                   sv.vehicle_id,sv.driver_id,
                   coalesce(du.name,du.email) AS driver_name,
                   coalesce(vv.vehicle_code,vv.license_plate) AS current_vehicle_code,
                   coalesce(fb.name,sv.from_id::text) AS from_branch_name,
                   coalesce(tb.name,sv.to_id::text) AS to_branch_name
            FROM public.stock_vouchers sv
            LEFT JOIN public.users du ON du.id=sv.driver_id AND du.company_id=p_company_id
            LEFT JOIN public.vehicles vv ON vv.id=sv.vehicle_id AND vv.company_id=p_company_id
            LEFT JOIN public.branches fb ON fb.id=sv.from_id AND fb.company_id=p_company_id
            LEFT JOIN public.branches tb ON tb.id=sv.to_id AND tb.company_id=p_company_id
            WHERE sv.company_id=p_company_id
              AND sv.type='Transfer'
              AND sv.status<>'Cancelled'
              AND (v_branch_id IS NULL OR sv.from_id=v_branch_id OR sv.to_id=v_branch_id)
            ORDER BY sv.voucher_date DESC,sv.voucher_code DESC
            LIMIT 50
          ) x),
        'direct_sales',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.voucher_date DESC,x.voucher_code DESC),'[]'::jsonb)
          FROM (
            SELECT sv.id,sv.voucher_code,sv.voucher_date,sv.status,sv.reference,
                   sv.to_id AS vehicle_id,
                   sv.custodian_user_id AS direct_sales_rep_id,
                   coalesce(rep.name,rep.email) AS direct_sales_rep_name,
                   coalesce(vv.vehicle_code,vv.license_plate) AS current_vehicle_code
            FROM public.stock_vouchers sv
            LEFT JOIN public.users rep ON rep.id=sv.custodian_user_id AND rep.company_id=p_company_id
            LEFT JOIN public.vehicles vv ON vv.id=sv.to_id AND vv.company_id=p_company_id
            WHERE sv.company_id=p_company_id
              AND sv.type='DirectSale'
              AND sv.to_type='Vehicle'
              AND sv.status<>'Cancelled'
            ORDER BY sv.voucher_date DESC,sv.voucher_code DESC
            LIMIT 50
          ) x),
        'drivers',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.name),'[]'::jsonb)
          FROM (
            SELECT u.id,u.name,u.email,u.role
            FROM public.users u
            WHERE u.company_id=p_company_id
              AND COALESCE(u.status,'Active')='Active'
              AND (
                u.role IN ('سائق','مندوب توصيل','مشرف توصيل')
                OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
              )
            ORDER BY u.name,u.email
            LIMIT 100
          ) x),
        'delivery_reps',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.name),'[]'::jsonb)
          FROM (
            SELECT u.id,u.name,u.email,u.role
            FROM public.users u
            WHERE u.company_id=p_company_id
              AND COALESCE(u.status,'Active')='Active'
              AND (
                u.role IN ('مندوب توصيل','مشرف توصيل')
                OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
              )
            ORDER BY u.name,u.email
            LIMIT 100
          ) x),
        'direct_sales_reps',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.name),'[]'::jsonb)
          FROM (
            SELECT u.id,u.name,u.email,u.role
            FROM public.users u
            WHERE u.company_id=p_company_id
              AND COALESCE(u.status,'Active')='Active'
              AND (
                u.role='مندوب بيع مباشر'
                AND COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
              )
            ORDER BY u.name,u.email
            LIMIT 100
          ) x)
      ) INTO v_response;
    END;


  ELSIF v_view='drivers' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.driver_code),'[]'::jsonb)
              FROM (
                SELECT d.*,
                  (SELECT max(fd.expiry_date) FROM public.fleet_driver_documents fd WHERE fd.fleet_driver_id=d.id AND fd.company_id=p_company_id AND fd.document_type='DriverLicense') AS license_expiry,
                  (SELECT count(*) FROM public.fleet_driver_performance_events pe WHERE pe.fleet_driver_id=d.id AND pe.company_id=p_company_id AND pe.severity IN ('High','Critical')) AS serious_events,
                  (SELECT COALESCE(sum(pe.points),0) FROM public.fleet_driver_performance_events pe WHERE pe.fleet_driver_id=d.id AND pe.company_id=p_company_id AND pe.event_date>=current_date-90) AS performance_points,
                  (SELECT count(*) FROM public.fleet_vehicle_assignments a WHERE a.fleet_driver_id=d.id AND a.company_id=p_company_id AND a.end_at IS NULL) AS active_vehicle_count
                FROM public.fleet_drivers d
                WHERE d.company_id=p_company_id
                  AND (NULLIF(btrim(p_payload->>'search'),'') IS NULL OR d.full_name ILIKE '%'||btrim(p_payload->>'search')||'%' OR d.driver_code ILIKE '%'||btrim(p_payload->>'search')||'%')
                LIMIT v_limit OFFSET v_offset
              ) x)
    ) INTO v_response;

  ELSIF v_view='driver_detail' THEN
    v_driver_id:=(p_payload->>'driver_id')::uuid;
    IF NOT EXISTS(SELECT 1 FROM public.fleet_drivers WHERE id=v_driver_id AND company_id=p_company_id) THEN RAISE EXCEPTION 'السائق غير موجود'; END IF;
    SELECT jsonb_build_object(
      'success',true,
      'driver',(SELECT to_jsonb(d) FROM public.fleet_drivers d WHERE d.id=v_driver_id AND d.company_id=p_company_id),
      'documents',(SELECT COALESCE(jsonb_agg(to_jsonb(d) ORDER BY d.expiry_date NULLS LAST),'[]'::jsonb) FROM public.fleet_driver_documents d WHERE d.fleet_driver_id=v_driver_id AND d.company_id=p_company_id),
      'assignments',(SELECT COALESCE(jsonb_agg(to_jsonb(a) ORDER BY a.start_at DESC),'[]'::jsonb) FROM public.fleet_vehicle_assignments a WHERE a.fleet_driver_id=v_driver_id AND a.company_id=p_company_id),
      'performance',(SELECT COALESCE(jsonb_agg(to_jsonb(p) ORDER BY p.event_date DESC),'[]'::jsonb) FROM public.fleet_driver_performance_events p WHERE p.fleet_driver_id=v_driver_id AND p.company_id=p_company_id LIMIT 100),
      'incidents',(SELECT COALESCE(jsonb_agg(to_jsonb(i) ORDER BY i.occurred_at DESC),'[]'::jsonb) FROM public.fleet_incidents i WHERE i.fleet_driver_id=v_driver_id AND i.company_id=p_company_id LIMIT 100),
      'liabilities',(SELECT COALESCE(jsonb_agg(to_jsonb(l) ORDER BY l.created_at DESC),'[]'::jsonb) FROM public.driver_liabilities l WHERE l.driver_id=(SELECT user_id FROM public.fleet_drivers WHERE id=v_driver_id) AND l.company_id=p_company_id LIMIT 100)
    ) INTO v_response;

  ELSIF v_view='alerts' THEN
    SELECT jsonb_build_object(
      'success',true,
      'vehicle_documents',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.expiry_date),'[]'::jsonb) FROM (
        SELECT d.id,d.vehicle_id,d.document_type,d.document_number,d.expiry_date,d.alert_days_before
        FROM public.vehicle_documents d
        WHERE d.company_id=p_company_id AND d.expiry_date IS NOT NULL AND d.expiry_date<=current_date+GREATEST(30,d.alert_days_before)
      ) x),
      'driver_documents',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.expiry_date),'[]'::jsonb) FROM (
        SELECT d.id,d.fleet_driver_id,d.document_type,d.document_number,d.expiry_date,d.alert_days_before
        FROM public.fleet_driver_documents d
        WHERE d.company_id=p_company_id AND d.expiry_date IS NOT NULL AND d.expiry_date<=current_date+GREATEST(30,d.alert_days_before)
      ) x),
      'contracts',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.end_date),'[]'::jsonb) FROM (
        SELECT c.id,c.vehicle_id,c.contract_number,c.contract_type,c.end_date,c.status
        FROM public.fleet_vehicle_contracts c
        WHERE c.company_id=p_company_id AND c.status='Active' AND c.end_date IS NOT NULL AND c.end_date<=current_date+30
      ) x),
      'maintenance',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.due_rank),'[]'::jsonb) FROM (
        SELECT mp.id,mp.vehicle_id,mp.plan_code,mp.name,mp.next_service_date,mp.next_service_odometer_km,
          CASE WHEN mp.next_service_date IS NOT NULL AND mp.next_service_date<current_date THEN 1 ELSE 2 END AS due_rank
        FROM public.fleet_maintenance_plans mp
        WHERE mp.company_id=p_company_id AND mp.active=true AND (
          (mp.next_service_date IS NOT NULL AND mp.next_service_date<=current_date+30)
          OR EXISTS(
            SELECT 1 FROM public.vehicles v
            WHERE v.id=mp.vehicle_id AND v.company_id=p_company_id AND mp.next_service_odometer_km IS NOT NULL
              AND mp.next_service_odometer_km <= GREATEST(
                COALESCE((SELECT max(vt.meter_reading) FROM public.vehicle_tracking vt WHERE vt.vehicle_id=v.id AND vt.company_id=p_company_id),0),
                COALESCE((SELECT max(GREATEST(COALESCE(r.meter_start,0),COALESCE(r.meter_end,0))) FROM public.runsheets r WHERE r.vehicle_id=v.id AND r.company_id=p_company_id),0)
              ) + mp.alert_km_before
          )
        )
      ) x)
    ) INTO v_response;

  ELSIF v_view='trips' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.run_date DESC,x.runsheet_code DESC),'[]'::jsonb)
              FROM (
                SELECT r.id,r.runsheet_code,r.run_date,r.status,r.vehicle_id,r.driver_id,r.meter_start,r.meter_end,
                       CASE WHEN r.meter_end IS NOT NULL AND r.meter_start IS NOT NULL AND r.meter_end>=r.meter_start THEN r.meter_end-r.meter_start END AS distance_km,
                       COALESCE((SELECT sum(f.liters) FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.runsheet_id=r.id),0) AS fuel_liters,
                       COALESCE((SELECT sum(f.total_cost) FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.runsheet_id=r.id),0) AS fuel_cost,
                       CASE WHEN r.meter_end IS NOT NULL AND r.meter_start IS NOT NULL AND r.meter_end>r.meter_start
                            AND EXISTS(SELECT 1 FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.runsheet_id=r.id)
                            THEN (SELECT sum(f.liters) FROM public.fleet_fuel_transactions f WHERE f.company_id=p_company_id AND f.runsheet_id=r.id) /
                                 (r.meter_end-r.meter_start)*100
                       END AS liters_per_100km,
                       (SELECT count(*) FROM public.orders o WHERE o.runsheet_id=r.id AND o.company_id=p_company_id) AS orders_count,
                       COALESCE((SELECT sum(o.total_amount) FROM public.orders o WHERE o.runsheet_id=r.id AND o.company_id=p_company_id),0) AS sales_value
                FROM public.runsheets r
                WHERE r.company_id=p_company_id AND r.run_date BETWEEN v_from AND v_to
                  AND (NULLIF(p_payload->>'vehicle_id','') IS NULL OR r.vehicle_id=(p_payload->>'vehicle_id')::uuid)
                LIMIT v_limit OFFSET v_offset
              ) x)
    ) INTO v_response;

  ELSIF v_view='costs' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY (x.fuel_cost+x.maintenance_cost+x.other_cost+x.contract_cost) DESC),'[]'::jsonb)
              FROM (
                SELECT v.id,v.vehicle_code,v.license_plate,
                  COALESCE((SELECT sum(f.total_cost) FROM public.fleet_fuel_transactions f WHERE f.vehicle_id=v.id AND f.company_id=p_company_id AND f.transaction_date::date BETWEEN v_from AND v_to),0) AS fuel_cost,
                  COALESCE((SELECT sum(m.cost) FROM public.vehicle_maintenance m WHERE m.vehicle_id=v.id AND m.company_id=p_company_id AND m.service_date BETWEEN v_from AND v_to),0) AS maintenance_cost,
                  COALESCE((SELECT sum(e.amount) FROM public.fleet_expenses e WHERE e.vehicle_id=v.id AND e.company_id=p_company_id AND e.expense_date::date BETWEEN v_from AND v_to),0) AS other_cost,
                  COALESCE((SELECT sum(
                    CASE WHEN c.start_date<=v_to AND (c.end_date IS NULL OR c.end_date>=v_from)
                         THEN c.monthly_cost ELSE 0 END
                  ) FROM public.fleet_vehicle_contracts c WHERE c.vehicle_id=v.id AND c.company_id=p_company_id AND c.status='Active'),0) AS contract_cost
                FROM public.vehicles v
                WHERE v.company_id=p_company_id
              ) x
              CROSS JOIN LATERAL (SELECT (x.fuel_cost+x.maintenance_cost+x.other_cost+x.contract_cost) AS total_cost) t)
    ) INTO v_response;

  ELSIF v_view='performance' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.event_date DESC),'[]'::jsonb)
              FROM (
                SELECT p.* FROM public.fleet_driver_performance_events p
                WHERE p.company_id=p_company_id
                  AND p.event_date::date BETWEEN v_from AND v_to
                  AND (NULLIF(p_payload->>'driver_id','') IS NULL OR p.fleet_driver_id=(p_payload->>'driver_id')::uuid)
                LIMIT v_limit OFFSET v_offset
              ) x)
    ) INTO v_response;

  ELSIF v_view='vehicle_planning' THEN
    DECLARE
      v_runsheet public.runsheets%ROWTYPE;
      v_load_weight numeric:=0;
      v_load_volume numeric:=0;
      v_missing_weight integer:=0;
      v_missing_volume integer:=0;
    BEGIN
      SELECT * INTO v_runsheet
      FROM public.runsheets
      WHERE company_id=p_company_id
        AND (
          id=NULLIF(p_payload->>'runsheet_id','')::uuid
          OR runsheet_code=NULLIF(btrim(p_payload->>'runsheet_code'),'')
        )
      LIMIT 1;
      IF NOT FOUND THEN RAISE EXCEPTION 'الرانشيت غير موجود'; END IF;

      SELECT
        COALESCE(sum(COALESCE(rsd.qty_ordered,0)*COALESCE(i.weight_kg,0)),0),
        COALESCE(sum(COALESCE(rsd.qty_ordered,0)*COALESCE(i.volume_m3,0)),0),
        count(*) FILTER (WHERE i.weight_kg IS NULL),
        count(*) FILTER (WHERE i.volume_m3 IS NULL)
      INTO v_load_weight,v_load_volume,v_missing_weight,v_missing_volume
      FROM public.run_sheet_details rsd
      LEFT JOIN public.items i ON i.id=rsd.item_id AND i.item_code=rsd.item_code
      WHERE rsd.runsheet_id=v_runsheet.id;

      SELECT jsonb_build_object(
        'success',true,'as_of',now(),'runsheet',to_jsonb(v_runsheet),
        'load',jsonb_build_object(
          'weight_kg',round(v_load_weight,2),'volume_m3',round(v_load_volume,3),
          'missing_weight_items',v_missing_weight,'missing_volume_items',v_missing_volume
        ),
        'candidates',(
          SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY
            CASE x.planning_status WHEN 'READY' THEN 1 WHEN 'INCOMPLETE_DATA' THEN 2 ELSE 3 END,
            x.vehicle_code
          ),'[]'::jsonb)
          FROM (
            SELECT
              v.id,v.vehicle_code,v.model,v.license_plate,v.status,
              v.max_weight_kg,v.max_volume_m3,
              v.cargo_length_m,v.cargo_width_m,v.cargo_height_m,
              v.operational_condition,v.route_capability,v.ownership_type,
              v.expected_km_per_liter,
              CASE
                WHEN lower(coalesce(v.status,'Active')) IN ('inactive','retired','maintenance','out_of_service') THEN 'BLOCKED'
                WHEN v.max_weight_kg IS NOT NULL AND v.max_weight_kg>0 AND v_load_weight>v.max_weight_kg THEN 'BLOCKED'
                WHEN v.max_volume_m3 IS NOT NULL AND v.max_volume_m3>0 AND v_load_volume>v.max_volume_m3 THEN 'BLOCKED'
                WHEN v.max_weight_kg IS NULL OR v.max_weight_kg<=0 OR v.max_volume_m3 IS NULL OR v.max_volume_m3<=0
                  OR v_missing_weight>0 OR v_missing_volume>0 THEN 'INCOMPLETE_DATA'
                ELSE 'READY'
              END AS planning_status,
              CASE WHEN v.max_weight_kg IS NOT NULL AND v.max_weight_kg>0 THEN round(v_load_weight/v.max_weight_kg*100,2) END AS weight_utilization_pct,
              CASE WHEN v.max_volume_m3 IS NOT NULL AND v.max_volume_m3>0 THEN round(v_load_volume/v.max_volume_m3*100,2) END AS volume_utilization_pct,
              CASE WHEN v.max_weight_kg IS NOT NULL THEN round(v.max_weight_kg-v_load_weight,2) END AS remaining_weight_kg,
              CASE WHEN v.max_volume_m3 IS NOT NULL THEN round(v.max_volume_m3-v_load_volume,3) END AS remaining_volume_m3,
              CASE WHEN lower(coalesce(v.operational_condition,'Good'))='Poor' THEN 'حالة المركبة Poor'
                   WHEN lower(coalesce(v.route_capability,'Any'))='LocalOnly' THEN 'قدرة المسار محدودة محليًا'
                   ELSE NULL END AS planning_warning
            FROM public.vehicles v
            WHERE v.company_id=p_company_id
          ) x
        )
      ) INTO v_response;
    END;

  ELSE
    RAISE EXCEPTION 'Fleet view غير مدعومة: %',v_view;
  END IF;

  RETURN COALESCE(v_response,jsonb_build_object('success',true));
END;
$function$
;
