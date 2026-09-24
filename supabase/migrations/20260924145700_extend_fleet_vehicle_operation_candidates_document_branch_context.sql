-- RAWAEA ERP — Fleet candidate read-model branch/document context
-- Production-applied: 2026-09-24
-- Scope: extend existing fleet_query(vehicle_operation_candidates) only.
-- No new Edge Function. No physical stock mutation. No command contract change.
BEGIN;
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
    OR v_actor.role IN ('مدير عام','مدير مخازن','مدير مالي','مشرف توصيل')
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

COMMIT;
