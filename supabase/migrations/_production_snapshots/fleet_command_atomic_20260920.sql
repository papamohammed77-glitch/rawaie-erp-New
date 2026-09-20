-- RAWAEA ERP Production function snapshot
-- Captured: 2026-09-20 UTC
-- Source: live Supabase PostgreSQL
-- Function: fleet_command_atomic

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
  ) THEN
    RAISE EXCEPTION 'غير مصرح بإدارة الأسطول';
  END IF;

  IF v_command='VEHICLE_CREATE' THEN
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
        expected_km_per_liter=NULLIF(p_payload->>'expected_km_per_liter','')::numeric
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
        max_volume_m3=CASE WHEN p_payload ? 'max_volume_m3' THEN NULLIF(p_payload->>'max_volume_m3','')::numeric ELSE max_volume_m3 END,
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
        expected_km_per_liter=CASE WHEN p_payload ? 'expected_km_per_liter' THEN NULLIF(p_payload->>'expected_km_per_liter','')::numeric ELSE expected_km_per_liter END
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

