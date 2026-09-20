-- RAWAEA ERP — Delivery & Logistics Management Control Plane
-- Canonical production migration for the 2026-09-20 closure.
-- No new Edge Function. All writes flow through delivery_logistics_command_atomic.
-- Physical stock, fulfillment and runsheet mutation remain owned by existing canonical engines.

BEGIN;

CREATE TABLE IF NOT EXISTS public.delivery_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  agent_code text NOT NULL,
  full_name text NOT NULL,
  phone text,
  email text,
  user_id uuid,
  employment_type text NOT NULL DEFAULT 'Employee' CHECK (employment_type IN ('Employee','Contractor','Outsourced','PerTrip','Monthly','Other')),
  status text NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Inactive','Suspended')),
  default_branch_id uuid,
  notes text,
  created_by text,
  updated_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT delivery_agents_company_code_key UNIQUE (company_id,agent_code)
);

CREATE TABLE IF NOT EXISTS public.delivery_route_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  plan_code text NOT NULL,
  runsheet_id uuid NOT NULL REFERENCES public.runsheets(id) ON DELETE RESTRICT,
  delivery_agent_id uuid REFERENCES public.delivery_agents(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft','Planned','InProgress','Completed','Cancelled')),
  optimization_strategy text NOT NULL DEFAULT 'Manual' CHECK (optimization_strategy IN ('Manual','GeographicNearest','CapacityFirst','TimeWindowFirst')),
  optimization_status text NOT NULL DEFAULT 'NOT_RUN' CHECK (optimization_status IN ('NOT_RUN','OPTIMIZED','INCOMPLETE_DATA','BLOCKED')),
  planned_start_at timestamptz,
  actual_start_at timestamptz,
  planned_end_at timestamptz,
  actual_end_at timestamptz,
  start_latitude numeric,
  start_longitude numeric,
  end_latitude numeric,
  end_longitude numeric,
  planned_speed_kmh numeric CHECK (planned_speed_kmh IS NULL OR planned_speed_kmh>0),
  default_service_minutes integer NOT NULL DEFAULT 0 CHECK (default_service_minutes>=0),
  planned_total_km numeric,
  actual_total_km numeric,
  planned_duration_minutes numeric,
  actual_duration_minutes numeric,
  notes text,
  created_by text,
  updated_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT delivery_route_plans_company_code_key UNIQUE (company_id,plan_code),
  CONSTRAINT delivery_route_plans_company_runsheet_key UNIQUE (company_id,runsheet_id)
);

CREATE TABLE IF NOT EXISTS public.delivery_route_stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  route_plan_id uuid NOT NULL REFERENCES public.delivery_route_plans(id) ON DELETE CASCADE,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
  stop_sequence integer NOT NULL CHECK (stop_sequence>0),
  status text NOT NULL DEFAULT 'Planned' CHECK (status IN ('Planned','EnRoute','Arrived','Delivered','Partial','Refused','Returned','Skipped')),
  planned_distance_km numeric,
  planned_arrival_at timestamptz,
  actual_arrival_at timestamptz,
  delivery_completed_at timestamptz,
  planned_service_minutes integer NOT NULL DEFAULT 0 CHECK (planned_service_minutes>=0),
  actual_latitude numeric,
  actual_longitude numeric,
  recipient_name text,
  pod_method text CHECK (pod_method IS NULL OR pod_method IN ('OTP','Signature','Photo','Reference','None')),
  pod_reference text,
  pod_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT delivery_route_stops_plan_order_key UNIQUE (route_plan_id,order_id),
  CONSTRAINT delivery_route_stops_plan_sequence_key UNIQUE (route_plan_id,stop_sequence)
);

CREATE TABLE IF NOT EXISTS public.delivery_collection_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  receipt_code text NOT NULL,
  route_plan_id uuid NOT NULL REFERENCES public.delivery_route_plans(id) ON DELETE RESTRICT,
  route_stop_id uuid NOT NULL REFERENCES public.delivery_route_stops(id) ON DELETE RESTRICT,
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
  delivery_agent_id uuid NOT NULL REFERENCES public.delivery_agents(id) ON DELETE RESTRICT,
  collected_at timestamptz NOT NULL DEFAULT now(),
  amount numeric NOT NULL CHECK (amount>0),
  payment_method text NOT NULL,
  reference text,
  status text NOT NULL DEFAULT 'Collected' CHECK (status IN ('Collected','Settled','Voided')),
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  operation_id text,
  CONSTRAINT delivery_collection_receipts_company_code_key UNIQUE (company_id,receipt_code)
);

CREATE INDEX IF NOT EXISTS idx_delivery_agents_company_status ON public.delivery_agents(company_id,status,full_name);
CREATE INDEX IF NOT EXISTS idx_delivery_route_plans_company_date ON public.delivery_route_plans(company_id,created_at DESC,status);
CREATE INDEX IF NOT EXISTS idx_delivery_route_plans_runsheet ON public.delivery_route_plans(company_id,runsheet_id);
CREATE INDEX IF NOT EXISTS idx_delivery_route_stops_company_plan ON public.delivery_route_stops(company_id,route_plan_id,stop_sequence);
CREATE INDEX IF NOT EXISTS idx_delivery_route_stops_order ON public.delivery_route_stops(company_id,order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_collection_company_agent ON public.delivery_collection_receipts(company_id,delivery_agent_id,collected_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_collection_order ON public.delivery_collection_receipts(company_id,order_id,status);

CREATE OR REPLACE FUNCTION public.fn_delivery_relation_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_TABLE_NAME='delivery_agents' THEN
    IF NEW.default_branch_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=NEW.default_branch_id AND b.company_id=NEW.company_id) THEN
      RAISE EXCEPTION 'Delivery agent branch does not belong to company';
    END IF;
    IF NEW.user_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=NEW.user_id AND u.company_id=NEW.company_id) THEN
      RAISE EXCEPTION 'Delivery agent user does not belong to company';
    END IF;
  ELSIF TG_TABLE_NAME='delivery_route_plans' THEN
    IF NOT EXISTS(SELECT 1 FROM public.runsheets r WHERE r.id=NEW.runsheet_id AND r.company_id=NEW.company_id) THEN
      RAISE EXCEPTION 'Route plan runsheet context invalid';
    END IF;
    IF NEW.delivery_agent_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.delivery_agents a WHERE a.id=NEW.delivery_agent_id AND a.company_id=NEW.company_id) THEN
      RAISE EXCEPTION 'Route plan delivery agent context invalid';
    END IF;
  ELSIF TG_TABLE_NAME='delivery_route_stops' THEN
    IF NOT EXISTS(SELECT 1 FROM public.delivery_route_plans p WHERE p.id=NEW.route_plan_id AND p.company_id=NEW.company_id) THEN
      RAISE EXCEPTION 'Route stop plan context invalid';
    END IF;
    IF NOT EXISTS(
      SELECT 1 FROM public.orders o
      WHERE o.id=NEW.order_id AND o.company_id=NEW.company_id
        AND o.runsheet_id=(SELECT runsheet_id FROM public.delivery_route_plans WHERE id=NEW.route_plan_id)
    ) THEN
      RAISE EXCEPTION 'Route stop order context invalid';
    END IF;
  ELSIF TG_TABLE_NAME='delivery_collection_receipts' THEN
    IF NOT EXISTS(
      SELECT 1 FROM public.delivery_route_plans p
      WHERE p.id=NEW.route_plan_id AND p.company_id=NEW.company_id
    ) THEN RAISE EXCEPTION 'Collection route plan context invalid'; END IF;
    IF NOT EXISTS(
      SELECT 1 FROM public.delivery_route_stops s
      WHERE s.id=NEW.route_stop_id AND s.company_id=NEW.company_id
        AND s.route_plan_id=NEW.route_plan_id AND s.order_id=NEW.order_id
    ) THEN RAISE EXCEPTION 'Collection route stop context invalid'; END IF;
    IF NOT EXISTS(
      SELECT 1 FROM public.delivery_agents a
      WHERE a.id=NEW.delivery_agent_id AND a.company_id=NEW.company_id
        AND a.id=(SELECT delivery_agent_id FROM public.delivery_route_plans WHERE id=NEW.route_plan_id)
    ) THEN RAISE EXCEPTION 'Collection agent is not assigned to route'; END IF;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_delivery_relation_guard_agents ON public.delivery_agents;
CREATE TRIGGER trg_delivery_relation_guard_agents BEFORE INSERT OR UPDATE ON public.delivery_agents FOR EACH ROW EXECUTE FUNCTION public.fn_delivery_relation_guard();
DROP TRIGGER IF EXISTS trg_delivery_relation_guard_plans ON public.delivery_route_plans;
CREATE TRIGGER trg_delivery_relation_guard_plans BEFORE INSERT OR UPDATE ON public.delivery_route_plans FOR EACH ROW EXECUTE FUNCTION public.fn_delivery_relation_guard();
DROP TRIGGER IF EXISTS trg_delivery_relation_guard_stops ON public.delivery_route_stops;
CREATE TRIGGER trg_delivery_relation_guard_stops BEFORE INSERT OR UPDATE ON public.delivery_route_stops FOR EACH ROW EXECUTE FUNCTION public.fn_delivery_relation_guard();
DROP TRIGGER IF EXISTS trg_delivery_relation_guard_collections ON public.delivery_collection_receipts;
CREATE TRIGGER trg_delivery_relation_guard_collections BEFORE INSERT OR UPDATE ON public.delivery_collection_receipts FOR EACH ROW EXECUTE FUNCTION public.fn_delivery_relation_guard();

DROP TRIGGER IF EXISTS trg_audit_delivery_agents ON public.delivery_agents;
CREATE TRIGGER trg_audit_delivery_agents AFTER INSERT OR UPDATE OR DELETE ON public.delivery_agents FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
DROP TRIGGER IF EXISTS trg_audit_delivery_route_plans ON public.delivery_route_plans;
CREATE TRIGGER trg_audit_delivery_route_plans AFTER INSERT OR UPDATE OR DELETE ON public.delivery_route_plans FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
DROP TRIGGER IF EXISTS trg_audit_delivery_route_stops ON public.delivery_route_stops;
CREATE TRIGGER trg_audit_delivery_route_stops AFTER INSERT OR UPDATE OR DELETE ON public.delivery_route_stops FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();
DROP TRIGGER IF EXISTS trg_audit_delivery_collections ON public.delivery_collection_receipts;
CREATE TRIGGER trg_audit_delivery_collections AFTER INSERT OR UPDATE OR DELETE ON public.delivery_collection_receipts FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();

ALTER TABLE public.delivery_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_route_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_collection_receipts ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.delivery_agents,public.delivery_route_plans,public.delivery_route_stops,public.delivery_collection_receipts FROM PUBLIC,anon,authenticated;
GRANT ALL ON TABLE public.delivery_agents,public.delivery_route_plans,public.delivery_route_stops,public.delivery_collection_receipts TO service_role;

CREATE OR REPLACE FUNCTION public.delivery_logistics_command_atomic(p_company_id uuid, p_command text, p_payload jsonb DEFAULT '{}'::jsonb, p_operation_id text DEFAULT NULL::text, p_actor_user_id uuid DEFAULT NULL::uuid, p_actor_email text DEFAULT NULL::text)
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
  v_rows integer;
  v_operation_key text;
  v_plan public.delivery_route_plans%ROWTYPE;
  v_stop public.delivery_route_stops%ROWTYPE;
  v_agent public.delivery_agents%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_receipt public.delivery_collection_receipts%ROWTYPE;
  v_existing numeric;
  v_allowed numeric;
  v_receipt_code text;
  v_status text;
  v_actual_at timestamptz;

  v_runsheet public.runsheets%ROWTYPE;

  v_missing integer;
  v_total_stops integer;
  v_seq integer;
  v_prev_lat numeric;
  v_prev_lon numeric;
  v_next_id uuid;
  v_next_lat numeric;
  v_next_lon numeric;
  v_dist numeric;
  v_total_km numeric := 0;
  v_elapsed timestamptz;
  v_service_minutes integer;
  v_speed numeric;
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'سياق الشركة مطلوب'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.companies c WHERE c.id=p_company_id AND c.is_active=true) THEN
    RAISE EXCEPTION 'الشركة غير موجودة أو غير نشطة';
  END IF;

  IF auth.uid() IS NOT NULL THEN
    SELECT * INTO v_actor
    FROM public.users u
    WHERE u.auth_id=auth.uid()
      AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
    LIMIT 1;
  ELSE
    SELECT * INTO v_actor
    FROM public.users u
    WHERE u.id=p_actor_user_id
      AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
    LIMIT 1;
  END IF;
  IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم أو سياق الشركة غير صالح'; END IF;

  IF p_actor_email IS NOT NULL AND lower(p_actor_email)<>lower(v_actor.email) THEN
    RAISE EXCEPTION 'بريد المنفذ لا يطابق هوية المستخدم';
  END IF;

  IF NULLIF(btrim(v_command),'') IS NULL THEN RAISE EXCEPTION 'الأمر مطلوب'; END IF;
  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id مطلوب لإعادة المحاولة الآمنة'; END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["delivery_supervisor"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["fleet.manage"]'::jsonb
    OR v_actor.role IN ('مدير عام','مدير مخازن','مدير مالي')
  ) THEN
    RAISE EXCEPTION 'غير مصرح بإدارة التوصيل واللوجستيات';
  END IF;

  v_operation_key := 'DELIVERY:'||p_operation_id;

  INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
  VALUES(p_company_id,'DELIVERY',v_operation_key,coalesce(p_payload,'{}'::jsonb),'processing')
  ON CONFLICT (company_id,operation_type,operation_key) DO NOTHING;
  GET DIAGNOSTICS v_rows = ROW_COUNT;

  SELECT * INTO v_registry
  FROM public.erp_operation_registry
  WHERE company_id=p_company_id
    AND operation_type='DELIVERY'
    AND operation_key=v_operation_key
  FOR UPDATE;

  IF v_registry.request_payload <> coalesce(p_payload,'{}'::jsonb) THEN
    RAISE EXCEPTION 'operation_id conflict: نفس الهوية استُخدمت بطلب مختلف';
  END IF;
  IF v_registry.status='completed' THEN
    RETURN coalesce(v_registry.response_payload,'{}'::jsonb) || jsonb_build_object('duplicate',true);
  END IF;
  IF v_rows=0 AND v_registry.status='processing' AND v_registry.created_at > now()-interval '15 minutes' THEN
    RAISE EXCEPTION 'delivery operation is already processing';
  END IF;

  PERFORM set_config('request.jwt.claims', jsonb_build_object('email',v_actor.email)::text, true);

  IF v_command='AGENT_CREATE' THEN
    IF nullif(btrim(p_payload->>'agent_code'),'') IS NULL OR nullif(btrim(p_payload->>'full_name'),'') IS NULL THEN
      RAISE EXCEPTION 'كود واسم مندوب التوصيل مطلوبان';
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.delivery_agents
      WHERE company_id=p_company_id AND lower(agent_code)=lower(btrim(p_payload->>'agent_code'))
    ) THEN
      RAISE EXCEPTION 'كود مندوب التوصيل مستخدم بالفعل';
    END IF;
    INSERT INTO public.delivery_agents(
      company_id,agent_code,full_name,phone,email,user_id,employment_type,status,default_branch_id,notes,created_by,updated_by
    )
    VALUES(
      p_company_id,btrim(p_payload->>'agent_code'),btrim(p_payload->>'full_name'),
      nullif(btrim(p_payload->>'phone'),''),
      nullif(btrim(p_payload->>'email'),''),
      nullif(p_payload->>'user_id','')::uuid,
      coalesce(nullif(p_payload->>'employment_type',''),'Employee'),
      coalesce(nullif(p_payload->>'status',''),'Active'),
      nullif(p_payload->>'default_branch_id','')::uuid,
      nullif(p_payload->>'notes',''),
      v_actor.email,v_actor.email
    )
    RETURNING * INTO v_agent;
    v_response:=jsonb_build_object('success',true,'command',v_command,'agent',to_jsonb(v_agent));

  ELSIF v_command='AGENT_UPDATE' THEN
    SELECT * INTO v_agent
    FROM public.delivery_agents
    WHERE id=nullif(p_payload->>'agent_id','')::uuid AND company_id=p_company_id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'مندوب التوصيل غير موجود'; END IF;
    UPDATE public.delivery_agents
    SET agent_code=coalesce(nullif(btrim(p_payload->>'agent_code'),''),agent_code),
        full_name=coalesce(nullif(btrim(p_payload->>'full_name'),''),full_name),
        phone=case when p_payload ? 'phone' then nullif(btrim(p_payload->>'phone'),'') else phone end,
        email=case when p_payload ? 'email' then nullif(btrim(p_payload->>'email'),'') else email end,
        user_id=case when p_payload ? 'user_id' then nullif(p_payload->>'user_id','')::uuid else user_id end,
        employment_type=coalesce(nullif(p_payload->>'employment_type',''),employment_type),
        status=coalesce(nullif(p_payload->>'status',''),status),
        default_branch_id=case when p_payload ? 'default_branch_id' then nullif(p_payload->>'default_branch_id','')::uuid else default_branch_id end,
        notes=case when p_payload ? 'notes' then p_payload->>'notes' else notes end,
        updated_by=v_actor.email,updated_at=now()
    WHERE id=v_agent.id AND company_id=p_company_id
    RETURNING * INTO v_agent;
    v_response:=jsonb_build_object('success',true,'command',v_command,'agent',to_jsonb(v_agent));

  ELSIF v_command='ROUTE_PLAN_CREATE' THEN
    SELECT * INTO v_runsheet
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND (
        id=nullif(p_payload->>'runsheet_id','')::uuid
        OR runsheet_code=nullif(btrim(p_payload->>'runsheet_code'),'')
      )
    LIMIT 1
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'الرانشيت غير موجود'; END IF;
    IF v_runsheet.status IN ('Cancelled','Completed','Deleted') THEN
      RAISE EXCEPTION 'لا يمكن تخطيط رانشيت في حالته الحالية: %',v_runsheet.status;
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.delivery_route_plans
      WHERE company_id=p_company_id AND runsheet_id=v_runsheet.id AND status<>'Cancelled'
    ) THEN
      SELECT * INTO v_plan FROM public.delivery_route_plans
      WHERE company_id=p_company_id AND runsheet_id=v_runsheet.id AND status<>'Cancelled'
      ORDER BY created_at DESC LIMIT 1;
      RETURN jsonb_build_object('success',true,'duplicate',true,'plan_id',v_plan.id,'plan_code',v_plan.plan_code,'status',v_plan.status);
    END IF;

    INSERT INTO public.delivery_route_plans(
      company_id,plan_code,runsheet_id,status,optimization_strategy,planned_start_at,
      start_latitude,start_longitude,end_latitude,end_longitude,planned_speed_kmh,
      default_service_minutes,notes,created_by,updated_by
    )
    VALUES(
      p_company_id,
      'DLP-'||v_runsheet.runsheet_code||'-'||substr(replace(gen_random_uuid()::text,'-',''),1,6),
      v_runsheet.id,'Draft',
      coalesce(nullif(p_payload->>'optimization_strategy',''),'Manual'),
      nullif(p_payload->>'planned_start_at','')::timestamptz,
      nullif(p_payload->>'start_latitude','')::numeric,
      nullif(p_payload->>'start_longitude','')::numeric,
      nullif(p_payload->>'end_latitude','')::numeric,
      nullif(p_payload->>'end_longitude','')::numeric,
      nullif(p_payload->>'planned_speed_kmh','')::numeric,
      coalesce(nullif(p_payload->>'default_service_minutes','')::integer,0),
      nullif(p_payload->>'notes',''),
      v_actor.email,v_actor.email
    )
    RETURNING * INTO v_plan;

    INSERT INTO public.delivery_route_stops(company_id,route_plan_id,order_id,stop_sequence,planned_service_minutes)
    SELECT p_company_id,v_plan.id,o.id,
           row_number() over(order by o.order_date,o.created_at,o.order_code),
           coalesce(v_plan.default_service_minutes,0)
    FROM public.orders o
    WHERE o.company_id=p_company_id AND o.runsheet_id=v_runsheet.id;

    SELECT count(*) INTO v_total_stops FROM public.delivery_route_stops WHERE route_plan_id=v_plan.id;
    IF v_total_stops=0 THEN
      RAISE EXCEPTION 'الرانشيت لا يحتوي أوردرات قابلة للتوصيل';
    END IF;

    v_response:=jsonb_build_object(
      'success',true,'duplicate',false,'command',v_command,
      'plan_id',v_plan.id,'plan_code',v_plan.plan_code,'runsheet_code',v_runsheet.runsheet_code,
      'stop_count',v_total_stops
    );

  ELSIF v_command='ROUTE_OPTIMIZE' THEN
    SELECT * INTO v_plan
    FROM public.delivery_route_plans
    WHERE id=nullif(p_payload->>'plan_id','')::uuid
      AND company_id=p_company_id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'خطة الرحلة غير موجودة'; END IF;
    IF v_plan.status='Cancelled' THEN RAISE EXCEPTION 'خطة الرحلة ملغاة'; END IF;

    IF v_plan.start_latitude IS NULL OR v_plan.start_longitude IS NULL
       OR v_plan.planned_start_at IS NULL OR v_plan.planned_speed_kmh IS NULL OR v_plan.planned_speed_kmh<=0 THEN
      v_response:=jsonb_build_object(
        'success',true,'status','INCOMPLETE_DATA','code','ROUTE_PLAN_INPUT_INCOMPLETE',
        'msg','نقطة البداية ووقت البداية والسرعة المخططة مطلوبة قبل تحسين المسار'
      );
    ELSE
      SELECT count(*) INTO v_missing
      FROM public.delivery_route_stops s
      JOIN public.orders o ON o.id=s.order_id AND o.company_id=p_company_id
      WHERE s.route_plan_id=v_plan.id
        AND (o.latitude IS NULL OR o.longitude IS NULL);
      IF v_missing>0 THEN
        v_response:=jsonb_build_object(
          'success',true,'status','INCOMPLETE_DATA','code','ORDER_GEO_INCOMPLETE',
          'missing_geo_orders',v_missing,
          'msg','بعض أوردرات الرحلة لا تحتوي إحداثيات توصيل مثبتة'
        );
      ELSE
        CREATE TEMP TABLE IF NOT EXISTS _delivery_opt_stops(
          id uuid PRIMARY KEY, lat numeric, lon numeric, used boolean NOT NULL DEFAULT false
        ) ON COMMIT DROP;
        DELETE FROM _delivery_opt_stops;
        INSERT INTO _delivery_opt_stops(id,lat,lon)
        SELECT s.id,o.latitude,o.longitude
        FROM public.delivery_route_stops s
        JOIN public.orders o ON o.id=s.order_id AND o.company_id=p_company_id
        WHERE s.route_plan_id=v_plan.id;

        SELECT count(*) INTO v_total_stops FROM _delivery_opt_stops;
        IF v_total_stops=0 THEN
          v_response:=jsonb_build_object('success',true,'status','BLOCKED','code','NO_STOPS','msg','لا توجد نقاط توصيل');
        ELSE
          v_seq:=0;
          v_prev_lat:=v_plan.start_latitude;
          v_prev_lon:=v_plan.start_longitude;
          v_elapsed:=v_plan.planned_start_at;
          v_speed:=v_plan.planned_speed_kmh;
          v_service_minutes:=v_plan.default_service_minutes;
          v_total_km:=0;

          WHILE EXISTS(SELECT 1 FROM _delivery_opt_stops WHERE used=false) LOOP
            SELECT x.id,x.lat,x.lon,x.dist_km
            INTO v_next_id,v_next_lat,v_next_lon,v_dist
            FROM (
              SELECT t.id,t.lat,t.lon,
                6371.0088*2*asin(
                  sqrt(
                    power(sin(radians(t.lat-v_prev_lat)/2),2)
                    + cos(radians(v_prev_lat))*cos(radians(t.lat))*power(sin(radians(t.lon-v_prev_lon)/2),2)
                  )
                ) AS dist_km
              FROM _delivery_opt_stops t
              WHERE t.used=false
            ) x
            ORDER BY x.dist_km,x.id
            LIMIT 1;

            v_seq:=v_seq+1;
            v_total_km:=v_total_km+coalesce(v_dist,0);
            v_elapsed:=v_elapsed + (coalesce(v_dist,0)/v_speed*interval '1 hour');
            UPDATE public.delivery_route_stops
            SET stop_sequence=v_seq,
                planned_distance_km=round(coalesce(v_dist,0),3),
                planned_arrival_at=v_elapsed,
                planned_service_minutes=v_service_minutes,
                updated_at=now()
            WHERE id=v_next_id AND company_id=p_company_id AND route_plan_id=v_plan.id;

            UPDATE _delivery_opt_stops SET used=true WHERE id=v_next_id;
            v_elapsed:=v_elapsed + make_interval(mins=>v_service_minutes);
            v_prev_lat:=v_next_lat;
            v_prev_lon:=v_next_lon;
          END LOOP;

          IF v_plan.end_latitude IS NOT NULL AND v_plan.end_longitude IS NOT NULL THEN
            v_dist := 6371.0088*2*asin(
              sqrt(
                power(sin(radians(v_plan.end_latitude-v_prev_lat)/2),2)
                + cos(radians(v_prev_lat))*cos(radians(v_plan.end_latitude))*power(sin(radians(v_plan.end_longitude-v_prev_lon)/2),2)
              )
            );
            v_total_km:=v_total_km+coalesce(v_dist,0);
          END IF;

          UPDATE public.delivery_route_plans
          SET optimization_strategy='GeographicNearest',
              optimization_status='OPTIMIZED',
              status=case when status='Draft' then 'Planned' else status end,
              planned_total_km=round(v_total_km,3),
              planned_duration_minutes=round(extract(epoch from (v_elapsed-v_plan.planned_start_at))/60.0,2),
              updated_by=v_actor.email,updated_at=now()
          WHERE id=v_plan.id AND company_id=p_company_id;

          v_response:=jsonb_build_object(
            'success',true,'status','OPTIMIZED','plan_id',v_plan.id,'plan_code',v_plan.plan_code,
            'stop_count',v_total_stops,'planned_total_km',round(v_total_km,3),
            'planned_duration_minutes',round(extract(epoch from (v_elapsed-v_plan.planned_start_at))/60.0,2)
          );
        END IF;
      END IF;
    END IF;

  ELSIF v_command='ROUTE_AGENT_ASSIGN' THEN
    SELECT * INTO v_plan FROM public.delivery_route_plans
    WHERE id=nullif(p_payload->>'plan_id','')::uuid AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'خطة الرحلة غير موجودة'; END IF;
    SELECT * INTO v_agent FROM public.delivery_agents
    WHERE id=nullif(p_payload->>'delivery_agent_id','')::uuid AND company_id=p_company_id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'مندوب التوصيل غير موجود'; END IF;
    IF v_agent.status<>'Active' THEN RAISE EXCEPTION 'مندوب التوصيل غير نشط'; END IF;
    UPDATE public.delivery_route_plans
    SET delivery_agent_id=v_agent.id,
        updated_by=v_actor.email,updated_at=now(),
        status=case when status='Draft' then 'Planned' else status end
    WHERE id=v_plan.id AND company_id=p_company_id;
    v_response:=jsonb_build_object('success',true,'plan_id',v_plan.id,'plan_code',v_plan.plan_code,'delivery_agent_id',v_agent.id);

  ELSIF v_command='STOP_ARRIVE' THEN
    SELECT * INTO v_stop FROM public.delivery_route_stops
    WHERE id=nullif(p_payload->>'stop_id','')::uuid AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'نقطة التوصيل غير موجودة'; END IF;
    v_actual_at:=coalesce(nullif(p_payload->>'actual_at','')::timestamptz,now());
    UPDATE public.delivery_route_stops
    SET actual_arrival_at=v_actual_at,
        status=case when status in ('Delivered','Partial','Refused','Returned') then status else 'Arrived' end,
        updated_at=now()
    WHERE id=v_stop.id AND company_id=p_company_id;
    UPDATE public.delivery_route_plans
    SET status=case when status='Planned' then 'InProgress' else status end,
        actual_start_at=coalesce(actual_start_at,v_actual_at),
        updated_by=v_actor.email,updated_at=now()
    WHERE id=v_stop.route_plan_id AND company_id=p_company_id;
    v_response:=jsonb_build_object('success',true,'stop_id',v_stop.id,'actual_arrival_at',v_actual_at);

  ELSIF v_command='STOP_POD' THEN
    SELECT * INTO v_stop FROM public.delivery_route_stops
    WHERE id=nullif(p_payload->>'stop_id','')::uuid AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'نقطة التوصيل غير موجودة'; END IF;
    IF nullif(btrim(p_payload->>'pod_method'),'') IS NULL THEN RAISE EXCEPTION 'طريقة إثبات التسليم مطلوبة'; END IF;
    IF p_payload->>'pod_method' NOT IN ('OTP','Signature','Photo','Reference','None') THEN RAISE EXCEPTION 'طريقة إثبات التسليم غير مدعومة'; END IF;
    v_status:=coalesce(nullif(p_payload->>'delivery_result',''),'Delivered');
    IF v_status NOT IN ('Delivered','Partial','Refused','Returned') THEN RAISE EXCEPTION 'نتيجة التسليم غير مدعومة'; END IF;
    v_actual_at:=coalesce(nullif(p_payload->>'captured_at','')::timestamptz,now());
    UPDATE public.delivery_route_stops
    SET recipient_name=case when p_payload ? 'recipient_name' then nullif(btrim(p_payload->>'recipient_name'),'') else recipient_name end,
        pod_method=p_payload->>'pod_method',
        pod_reference=case when p_payload ? 'pod_reference' then nullif(btrim(p_payload->>'pod_reference'),'') else pod_reference end,
        pod_note=case when p_payload ? 'pod_note' then p_payload->>'pod_note' else pod_note end,
        actual_latitude=case when p_payload ? 'latitude' then nullif(p_payload->>'latitude','')::numeric else actual_latitude end,
        actual_longitude=case when p_payload ? 'longitude' then nullif(p_payload->>'longitude','')::numeric else actual_longitude end,
        actual_arrival_at=coalesce(actual_arrival_at,v_actual_at),
        delivery_completed_at=v_actual_at,
        status=v_status,
        updated_at=now()
    WHERE id=v_stop.id AND company_id=p_company_id;
    UPDATE public.delivery_route_plans
    SET status='InProgress',
        actual_start_at=coalesce(actual_start_at,v_actual_at),
        updated_by=v_actor.email,updated_at=now()
    WHERE id=v_stop.route_plan_id AND company_id=p_company_id AND status<>'Completed';
    v_response:=jsonb_build_object('success',true,'stop_id',v_stop.id,'status',v_status,'captured_at',v_actual_at);

  ELSIF v_command='ROUTE_STATUS' THEN
    SELECT * INTO v_plan FROM public.delivery_route_plans
    WHERE id=nullif(p_payload->>'plan_id','')::uuid AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'خطة الرحلة غير موجودة'; END IF;
    v_status:=coalesce(nullif(p_payload->>'status',''),v_plan.status);
    IF v_status NOT IN ('Draft','Planned','InProgress','Completed','Cancelled') THEN RAISE EXCEPTION 'حالة الخطة غير مدعومة'; END IF;
    UPDATE public.delivery_route_plans
    SET status=v_status,
        actual_end_at=case when v_status='Completed' then coalesce(actual_end_at,now()) else actual_end_at end,
        updated_by=v_actor.email,updated_at=now()
    WHERE id=v_plan.id AND company_id=p_company_id;
    v_response:=jsonb_build_object('success',true,'plan_id',v_plan.id,'status',v_status);

  ELSIF v_command='COLLECTION_RECORD' THEN
    SELECT * INTO v_stop FROM public.delivery_route_stops
    WHERE id=nullif(p_payload->>'stop_id','')::uuid AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'نقطة التوصيل غير موجودة'; END IF;
    SELECT * INTO v_plan FROM public.delivery_route_plans
    WHERE id=v_stop.route_plan_id AND company_id=p_company_id
    FOR UPDATE;
    IF NOT FOUND OR v_plan.delivery_agent_id IS NULL THEN RAISE EXCEPTION 'لا يوجد مندوب توصيل مرتبط بالرحلة'; END IF;
    SELECT * INTO v_order FROM public.orders
    WHERE id=v_stop.order_id AND company_id=p_company_id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'الأوردر غير موجود'; END IF;

    SELECT coalesce(sum(r.amount),0) INTO v_existing
    FROM public.delivery_collection_receipts r
    WHERE r.company_id=p_company_id AND r.order_id=v_order.id AND r.status<>'Voided';

    v_allowed:=greatest(0,coalesce(v_order.total_amount,0)-coalesce(v_order.amount_paid,0)-v_existing);
    IF coalesce((p_payload->>'amount')::numeric,0)<=0 THEN RAISE EXCEPTION 'قيمة التحصيل يجب أن تكون أكبر من صفر'; END IF;
    IF (p_payload->>'amount')::numeric > v_allowed THEN
      RAISE EXCEPTION 'قيمة التحصيل تتجاوز المتبقي على الأوردر: %',round(v_allowed,2);
    END IF;

    v_receipt_code:='COL-'||substr(replace(gen_random_uuid()::text,'-',''),1,12);
    INSERT INTO public.delivery_collection_receipts(
      company_id,receipt_code,route_plan_id,route_stop_id,order_id,delivery_agent_id,
      collected_at,amount,payment_method,reference,status,notes,created_by,updated_at,operation_id
    )
    VALUES(
      p_company_id,v_receipt_code,v_plan.id,v_stop.id,v_order.id,v_plan.delivery_agent_id,
      coalesce(nullif(p_payload->>'collected_at','')::timestamptz,now()),
      (p_payload->>'amount')::numeric,
      coalesce(nullif(btrim(p_payload->>'payment_method'),''),'Cash'),
      nullif(btrim(p_payload->>'reference'),''),
      'Collected',
      nullif(p_payload->>'notes',''),
      v_actor.email,now(),p_operation_id
    )
    RETURNING * INTO v_receipt;
    v_response:=jsonb_build_object('success',true,'receipt',to_jsonb(v_receipt),'remaining_after',round(v_allowed-v_receipt.amount,2));

  ELSIF v_command='COLLECTION_VOID' THEN
    SELECT * INTO v_receipt
    FROM public.delivery_collection_receipts
    WHERE id=nullif(p_payload->>'receipt_id','')::uuid AND company_id=p_company_id
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'سند التحصيل غير موجود'; END IF;
    IF v_receipt.status='Voided' THEN
      v_response:=jsonb_build_object('success',true,'duplicate',true,'receipt_id',v_receipt.id,'status','Voided');
    ELSE
      UPDATE public.delivery_collection_receipts
      SET status='Voided',updated_at=now()
      WHERE id=v_receipt.id AND company_id=p_company_id;
      v_response:=jsonb_build_object('success',true,'receipt_id',v_receipt.id,'status','Voided');
    END IF;

  ELSE
    RAISE EXCEPTION 'أمر Delivery غير مدعوم: %',v_command;
  END IF;

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_response,completed_at=now()
  WHERE company_id=p_company_id AND operation_type='DELIVERY' AND operation_key=v_operation_key;

  RETURN v_response;
EXCEPTION WHEN OTHERS THEN
  UPDATE public.erp_operation_registry
  SET status='failed',response_payload=jsonb_build_object('success',false,'error',SQLERRM),completed_at=now()
  WHERE company_id=p_company_id AND operation_type='DELIVERY' AND operation_key=v_operation_key;
  RAISE;
END;
$function$


CREATE OR REPLACE FUNCTION public.delivery_logistics_query(p_company_id uuid, p_view text, p_payload jsonb DEFAULT '{}'::jsonb, p_actor_user_id uuid DEFAULT NULL::uuid, p_actor_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_view text := lower(btrim(coalesce(p_view,'')));
  v_from date := coalesce(nullif(p_payload->>'from_date','')::date,current_date-30);
  v_to date := coalesce(nullif(p_payload->>'to_date','')::date,current_date);
  v_response jsonb;
  v_limit integer := greatest(1,least(coalesce((p_payload->>'limit')::integer,100),500));
  v_offset integer := greatest(0,coalesce((p_payload->>'offset')::integer,0));
BEGIN
  IF p_company_id IS NULL THEN RAISE EXCEPTION 'سياق الشركة مطلوب'; END IF;
  IF auth.uid() IS NOT NULL THEN
    SELECT * INTO v_actor
    FROM public.users u
    WHERE u.auth_id=auth.uid() AND u.company_id=p_company_id AND coalesce(u.status,'Active')='Active'
    LIMIT 1;
  ELSE
    SELECT * INTO v_actor
    FROM public.users u
    WHERE u.id=p_actor_user_id AND u.company_id=p_company_id AND coalesce(u.status,'Active')='Active'
    LIMIT 1;
  END IF;
  IF NOT FOUND THEN RAISE EXCEPTION 'هوية المستخدم أو سياق الشركة غير صالح'; END IF;
  IF p_actor_email IS NOT NULL AND lower(p_actor_email)<>lower(v_actor.email) THEN RAISE EXCEPTION 'بريد المنفذ لا يطابق هوية المستخدم'; END IF;
  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["delivery_supervisor"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["fleet.read"]'::jsonb
    OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["fleet.manage"]'::jsonb
    OR v_actor.role IN ('مدير عام','مدير مخازن','مدير مالي')
  ) THEN
    RAISE EXCEPTION 'غير مصرح بقراءة مركز التوصيل واللوجستيات';
  END IF;

  IF v_view='dashboard' THEN
    SELECT jsonb_build_object(
      'success',true,
      'plans_today',(SELECT count(*) FROM public.delivery_route_plans p WHERE p.company_id=p_company_id AND p.created_at::date=current_date AND p.status<>'Cancelled'),
      'active_plans',(SELECT count(*) FROM public.delivery_route_plans p WHERE p.company_id=p_company_id AND p.status IN ('Planned','InProgress')),
      'unassigned_plans',(SELECT count(*) FROM public.delivery_route_plans p WHERE p.company_id=p_company_id AND p.status IN ('Draft','Planned') AND p.delivery_agent_id IS NULL),
      'pending_stops',(SELECT count(*) FROM public.delivery_route_stops s WHERE s.company_id=p_company_id AND s.status IN ('Planned','EnRoute','Arrived')),
      'on_time_pct',(
        SELECT case when count(*)=0 then null
          else round(100.0*count(*) FILTER (WHERE s.actual_arrival_at<=s.planned_arrival_at)/count(*),2) end
        FROM public.delivery_route_stops s
        JOIN public.delivery_route_plans p ON p.id=s.route_plan_id AND p.company_id=p_company_id
        WHERE s.company_id=p_company_id AND s.planned_arrival_at IS NOT NULL AND s.actual_arrival_at IS NOT NULL
      ),
      'recorded_collections',(SELECT coalesce(sum(r.amount),0) FROM public.delivery_collection_receipts r WHERE r.company_id=p_company_id AND r.status<>'Voided'),
      'outstanding_order_value',(
        SELECT coalesce(sum(greatest(0,coalesce(o.total_amount,0)-coalesce(o.amount_paid,0))),0)
        FROM public.orders o
        WHERE o.company_id=p_company_id AND o.runsheet_id IS NOT NULL
          AND o.order_status NOT IN ('Cancelled')
      )
    ) INTO v_response;

  ELSIF v_view='routes' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(
        SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]'::jsonb)
        FROM (
          SELECT p.id,p.plan_code,p.status,p.optimization_strategy,p.optimization_status,
                 p.planned_start_at,p.planned_end_at,p.actual_start_at,p.actual_end_at,
                 p.planned_total_km,p.actual_total_km,p.planned_duration_minutes,p.actual_duration_minutes,
                 r.runsheet_code,r.run_date,r.status AS runsheet_status,
                 r.vehicle_id,r.driver_id,v.vehicle_code,v.license_plate,
                 a.id AS delivery_agent_id,a.agent_code,a.full_name AS delivery_agent_name,
                 (SELECT count(*) FROM public.delivery_route_stops s WHERE s.route_plan_id=p.id) AS stop_count,
                 (SELECT count(*) FROM public.delivery_route_stops s WHERE s.route_plan_id=p.id AND s.status='Delivered') AS delivered_stops,
                 (SELECT count(*) FROM public.delivery_route_stops s WHERE s.route_plan_id=p.id AND s.status='Partial') AS partial_stops,
                 (SELECT count(*) FROM public.delivery_route_stops s WHERE s.route_plan_id=p.id AND s.status='Refused') AS refused_stops,
                 (SELECT coalesce(sum(cr.amount),0) FROM public.delivery_collection_receipts cr WHERE cr.route_plan_id=p.id AND cr.status<>'Voided') AS collected_amount,
                 (SELECT coalesce(sum(greatest(0,coalesce(o.total_amount,0)-coalesce(o.amount_paid,0))),0)
                    FROM public.delivery_route_stops s
                    JOIN public.orders o ON o.id=s.order_id AND o.company_id=p_company_id
                    WHERE s.route_plan_id=p.id) AS outstanding_amount,
                 p.created_at
          FROM public.delivery_route_plans p
          JOIN public.runsheets r ON r.id=p.runsheet_id AND r.company_id=p_company_id
          LEFT JOIN public.vehicles v ON v.id=r.vehicle_id AND v.company_id=p_company_id
          LEFT JOIN public.delivery_agents a ON a.id=p.delivery_agent_id AND a.company_id=p_company_id
          WHERE p.company_id=p_company_id
            AND p.created_at::date BETWEEN v_from AND v_to
            AND (nullif(btrim(p_payload->>'status'),'') IS NULL OR p.status=p_payload->>'status')
          LIMIT v_limit OFFSET v_offset
        ) x
      )
    ) INTO v_response;

  ELSIF v_view='route_detail' THEN
    SELECT jsonb_build_object(
      'success',true,
      'plan',(
        SELECT to_jsonb(p) || jsonb_build_object(
          'runsheet_code',r.runsheet_code,
          'runsheet_status',r.status,
          'vehicle_code',v.vehicle_code,
          'license_plate',v.license_plate,
          'driver_user_id',r.driver_id,
          'delivery_agent_name',a.full_name,
          'delivery_agent_code',a.agent_code
        )
        FROM public.delivery_route_plans p
        JOIN public.runsheets r ON r.id=p.runsheet_id AND r.company_id=p_company_id
        LEFT JOIN public.vehicles v ON v.id=r.vehicle_id AND v.company_id=p_company_id
        LEFT JOIN public.delivery_agents a ON a.id=p.delivery_agent_id AND a.company_id=p_company_id
        WHERE p.id=nullif(p_payload->>'plan_id','')::uuid AND p.company_id=p_company_id
      ),
      'stops',(
        SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.stop_sequence),'[]'::jsonb)
        FROM (
          SELECT s.id,s.stop_sequence,s.status,s.planned_distance_km,s.planned_arrival_at,s.actual_arrival_at,
                 s.delivery_completed_at,s.recipient_name,s.pod_method,s.pod_reference,s.pod_note,
                 s.actual_latitude,s.actual_longitude,
                 o.order_code,o.customer_name,o.customer_phone,o.shipping_address,o.latitude,o.longitude,
                 o.total_amount,o.amount_paid,o.payment_type,o.order_status,
                 coalesce(sum(od.qty),0) AS ordered_qty,
                 coalesce(sum(od.qty_loaded),0) AS loaded_qty,
                 coalesce(sum(od.qty_delivered),0) AS delivered_qty,
                 coalesce(sum(od.qty_refused),0) AS refused_qty,
                 coalesce(sum(od.qty_returned),0) AS returned_qty,
                 coalesce((SELECT sum(cr.amount) FROM public.delivery_collection_receipts cr WHERE cr.route_stop_id=s.id AND cr.status<>'Voided'),0) AS collected_amount,
                 case when s.planned_arrival_at is not null and s.actual_arrival_at is not null
                      then (s.actual_arrival_at<=s.planned_arrival_at) end AS on_time
          FROM public.delivery_route_stops s
          JOIN public.orders o ON o.id=s.order_id AND o.company_id=p_company_id
          LEFT JOIN public.order_details od ON od.order_id=o.id
          WHERE s.company_id=p_company_id
            AND s.route_plan_id=nullif(p_payload->>'plan_id','')::uuid
          GROUP BY s.id,o.id
        ) x
      )
    ) INTO v_response;

  ELSIF v_view='planning' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(
        SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.run_date DESC,x.runsheet_code DESC),'[]'::jsonb)
        FROM (
          SELECT r.id,r.runsheet_code,r.run_date,r.status,r.vehicle_id,r.driver_id,
                 v.vehicle_code,v.license_plate,v.max_weight_kg,v.max_volume_m3,
                 count(distinct o.id) AS order_count,
                 coalesce(sum(rsd.qty_ordered),0) AS ordered_qty,
                 coalesce(sum(rsd.qty_loaded),0) AS loaded_qty,
                 coalesce(sum(rsd.qty_delivered),0) AS delivered_qty,
                 exists(SELECT 1 FROM public.delivery_route_plans p WHERE p.company_id=p_company_id AND p.runsheet_id=r.id AND p.status<>'Cancelled') AS has_route_plan
          FROM public.runsheets r
          LEFT JOIN public.vehicles v ON v.id=r.vehicle_id AND v.company_id=p_company_id
          LEFT JOIN public.orders o ON o.company_id=p_company_id AND o.runsheet_id=r.id
          LEFT JOIN public.run_sheet_details rsd ON rsd.runsheet_id=r.id
          WHERE r.company_id=p_company_id
            AND r.run_date BETWEEN v_from AND v_to
            AND r.status NOT IN ('Cancelled','Completed')
          GROUP BY r.id,v.id
          LIMIT v_limit OFFSET v_offset
        ) x
      )
    ) INTO v_response;

  ELSIF v_view='agents' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(
        SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.full_name),'[]'::jsonb)
        FROM (
          SELECT a.id,a.agent_code,a.full_name,a.phone,a.email,a.employment_type,a.status,a.user_id,
                 (SELECT count(*) FROM public.delivery_route_plans p WHERE p.delivery_agent_id=a.id AND p.company_id=p_company_id AND p.status IN ('Planned','InProgress')) AS active_routes,
                 (SELECT count(*) FROM public.delivery_route_stops s WHERE s.company_id=p_company_id AND s.route_plan_id IN (SELECT p.id FROM public.delivery_route_plans p WHERE p.delivery_agent_id=a.id AND p.company_id=p_company_id)) AS stops_total,
                 (SELECT count(*) FROM public.delivery_route_stops s WHERE s.company_id=p_company_id AND s.status='Delivered' AND s.route_plan_id IN (SELECT p.id FROM public.delivery_route_plans p WHERE p.delivery_agent_id=a.id AND p.company_id=p_company_id)) AS stops_delivered,
                 (SELECT coalesce(sum(r.amount),0) FROM public.delivery_collection_receipts r WHERE r.company_id=p_company_id AND r.delivery_agent_id=a.id AND r.status<>'Voided') AS collected_amount
          FROM public.delivery_agents a
          WHERE a.company_id=p_company_id
            AND (nullif(btrim(p_payload->>'status'),'') IS NULL OR a.status=p_payload->>'status')
            AND (nullif(btrim(p_payload->>'search'),'') IS NULL OR a.full_name ILIKE '%'||btrim(p_payload->>'search')||'%' OR a.agent_code ILIKE '%'||btrim(p_payload->>'search')||'%')
          LIMIT v_limit OFFSET v_offset
        ) x
      )
    ) INTO v_response;

  ELSIF v_view='collections' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(
        SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.collected_at DESC),'[]'::jsonb)
        FROM (
          SELECT c.id,c.receipt_code,c.collected_at,c.amount,c.payment_method,c.reference,c.status,c.notes,
                 p.plan_code,s.stop_sequence,o.order_code,o.customer_name,
                 a.agent_code,a.full_name AS delivery_agent_name
          FROM public.delivery_collection_receipts c
          JOIN public.delivery_route_plans p ON p.id=c.route_plan_id AND p.company_id=p_company_id
          JOIN public.delivery_route_stops s ON s.id=c.route_stop_id AND s.company_id=p_company_id
          JOIN public.orders o ON o.id=c.order_id AND o.company_id=p_company_id
          JOIN public.delivery_agents a ON a.id=c.delivery_agent_id AND a.company_id=p_company_id
          WHERE c.company_id=p_company_id
            AND c.collected_at::date BETWEEN v_from AND v_to
          LIMIT v_limit OFFSET v_offset
        ) x
      )
    ) INTO v_response;

  ELSIF v_view='performance' THEN
    SELECT jsonb_build_object(
      'success',true,
      'rows',(
        SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.delivered_stops DESC,x.agent_code),'[]'::jsonb)
        FROM (
          SELECT a.id AS delivery_agent_id,a.agent_code,a.full_name,
                 count(distinct s.id) AS assigned_stops,
                 count(distinct s.id) FILTER (WHERE s.status='Delivered') AS delivered_stops,
                 count(distinct s.id) FILTER (WHERE s.status='Partial') AS partial_stops,
                 count(distinct s.id) FILTER (WHERE s.status='Refused') AS refused_stops,
                 count(distinct s.id) FILTER (WHERE s.status='Returned') AS returned_stops,
                 case when count(*) FILTER (WHERE s.planned_arrival_at IS NOT NULL AND s.actual_arrival_at IS NOT NULL)=0 then null
                      else round(100.0*count(*) FILTER (WHERE s.planned_arrival_at IS NOT NULL AND s.actual_arrival_at IS NOT NULL AND s.actual_arrival_at<=s.planned_arrival_at)
                           /count(*) FILTER (WHERE s.planned_arrival_at IS NOT NULL AND s.actual_arrival_at IS NOT NULL),2) end AS on_time_pct,
                 coalesce(sum(o.total_amount),0) AS order_value,
                 coalesce(sum(cr.collected),0) AS collected_amount,
                 perf.total_distance_km,
                 perf.total_delivery_minutes,
                 case when perf.total_delivery_minutes>0 then round(perf.total_distance_km/(perf.total_delivery_minutes/60.0),2) end AS delivery_speed_kmh,
                 case when count(distinct s.id)>0 and perf.total_delivery_minutes>0
                      then round(perf.total_delivery_minutes/count(distinct s.id),2) end AS avg_minutes_per_stop
          FROM public.delivery_agents a
          LEFT JOIN public.delivery_route_plans p ON p.delivery_agent_id=a.id AND p.company_id=p_company_id
          LEFT JOIN public.delivery_route_stops s ON s.route_plan_id=p.id AND s.company_id=p_company_id
          LEFT JOIN public.orders o ON o.id=s.order_id AND o.company_id=p_company_id
          LEFT JOIN LATERAL (
            SELECT coalesce(sum(c.amount),0) AS collected
            FROM public.delivery_collection_receipts c
            WHERE c.company_id=p_company_id AND c.route_stop_id=s.id AND c.status<>'Voided'
          ) cr ON true
          LEFT JOIN LATERAL (
            SELECT
              coalesce(sum(case
                when r2.meter_start is not null and r2.meter_end is not null and r2.meter_end>=r2.meter_start
                  then r2.meter_end-r2.meter_start
                else coalesce(p2.actual_total_km,0)
              end),0) AS total_distance_km,
              coalesce(sum(case
                when r2.delivery_start is not null and r2.delivery_end is not null and r2.delivery_end>=r2.delivery_start
                  then extract(epoch from (r2.delivery_end-r2.delivery_start))/60.0
                else coalesce(p2.actual_duration_minutes,0)
              end),0) AS total_delivery_minutes
            FROM public.delivery_route_plans p2
            JOIN public.runsheets r2 ON r2.id=p2.runsheet_id AND r2.company_id=p_company_id
            WHERE p2.company_id=p_company_id
              AND p2.delivery_agent_id=a.id
              AND p2.status<>'Cancelled'
              AND p2.created_at::date BETWEEN v_from AND v_to
          ) perf ON true
          WHERE a.company_id=p_company_id
            AND (s.id IS NULL OR s.created_at::date BETWEEN v_from AND v_to)
          GROUP BY a.id,perf.total_distance_km,perf.total_delivery_minutes
        ) x
      )
    ) INTO v_response;

  ELSE
    RAISE EXCEPTION 'Delivery Logistics view غير مدعومة: %',v_view;
  END IF;

  RETURN coalesce(v_response,jsonb_build_object('success',true));
END;
$function$


REVOKE ALL ON FUNCTION public.delivery_logistics_command_atomic(uuid,text,jsonb,text,uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.delivery_logistics_command_atomic(uuid,text,jsonb,text,uuid,text) TO authenticated,service_role;
REVOKE ALL ON FUNCTION public.delivery_logistics_query(uuid,text,jsonb,uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.delivery_logistics_query(uuid,text,jsonb,uuid,text) TO authenticated,service_role;

COMMIT;
