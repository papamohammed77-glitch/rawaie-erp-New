
-- RAWAEA ERP — Fleet Security / Trigger Closure
-- Reproducible Production guard layer.

BEGIN;

CREATE OR REPLACE FUNCTION public.fn_fleet_relation_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_TABLE_NAME='fleet_drivers' THEN
    IF NEW.user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'fleet driver user/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_driver_documents' THEN
    IF NOT EXISTS (SELECT 1 FROM public.fleet_drivers d WHERE d.id=NEW.fleet_driver_id AND d.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'driver document/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_vehicle_assignments' THEN
    IF NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'assignment vehicle/company mismatch'; END IF;
    IF NEW.fleet_driver_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.fleet_drivers d WHERE d.id=NEW.fleet_driver_id AND d.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'assignment fleet driver/company mismatch'; END IF;
    IF NEW.driver_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.driver_user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'assignment user/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_vehicle_contracts' THEN
    IF NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'contract vehicle/company mismatch'; END IF;
    IF NEW.supplier_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.suppliers s WHERE s.id=NEW.supplier_id AND s.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'contract supplier/company mismatch'; END IF;
    IF NEW.responsible_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.responsible_user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'contract responsible user/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_fuel_transactions' THEN
    IF NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'fuel vehicle/company mismatch'; END IF;
    IF NEW.fleet_driver_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.fleet_drivers d WHERE d.id=NEW.fleet_driver_id AND d.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'fuel fleet driver/company mismatch'; END IF;
    IF NEW.driver_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.driver_user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'fuel driver user/company mismatch'; END IF;
    IF NEW.runsheet_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.runsheets r WHERE r.id=NEW.runsheet_id AND r.company_id=NEW.company_id AND r.vehicle_id=NEW.vehicle_id)
      THEN RAISE EXCEPTION 'fuel runsheet/vehicle/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_maintenance_plans' THEN
    IF NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'maintenance plan vehicle/company mismatch'; END IF;
    IF NEW.next_service_odometer_km IS NOT NULL AND NEW.next_service_odometer_km < 0
      THEN RAISE EXCEPTION 'next service odometer cannot be negative'; END IF;
  ELSIF TG_TABLE_NAME='vehicle_maintenance' THEN
    IF NEW.maintenance_plan_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.fleet_maintenance_plans p WHERE p.id=NEW.maintenance_plan_id AND p.company_id=NEW.company_id AND p.vehicle_id=NEW.vehicle_id
    ) THEN RAISE EXCEPTION 'maintenance plan/vehicle/company mismatch'; END IF;
    IF NEW.incident_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM public.fleet_incidents i WHERE i.id=NEW.incident_id AND i.company_id=NEW.company_id AND (i.vehicle_id IS NULL OR i.vehicle_id=NEW.vehicle_id)
    ) THEN RAISE EXCEPTION 'maintenance incident/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_incidents' THEN
    IF NEW.vehicle_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'incident vehicle/company mismatch'; END IF;
    IF NEW.fleet_driver_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.fleet_drivers d WHERE d.id=NEW.fleet_driver_id AND d.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'incident fleet driver/company mismatch'; END IF;
    IF NEW.driver_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.driver_user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'incident user/company mismatch'; END IF;
    IF NEW.runsheet_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.runsheets r WHERE r.id=NEW.runsheet_id AND r.company_id=NEW.company_id AND (NEW.vehicle_id IS NULL OR r.vehicle_id=NEW.vehicle_id))
      THEN RAISE EXCEPTION 'incident runsheet/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_driver_performance_events' THEN
    IF NEW.fleet_driver_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.fleet_drivers d WHERE d.id=NEW.fleet_driver_id AND d.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'performance fleet driver/company mismatch'; END IF;
    IF NEW.driver_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.driver_user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'performance user/company mismatch'; END IF;
    IF NEW.vehicle_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'performance vehicle/company mismatch'; END IF;
    IF NEW.runsheet_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.runsheets r WHERE r.id=NEW.runsheet_id AND r.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'performance runsheet/company mismatch'; END IF;
    IF NEW.incident_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.fleet_incidents i WHERE i.id=NEW.incident_id AND i.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'performance incident/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='fleet_expenses' THEN
    IF NEW.vehicle_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'expense vehicle/company mismatch'; END IF;
    IF NEW.fleet_driver_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.fleet_drivers d WHERE d.id=NEW.fleet_driver_id AND d.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'expense fleet driver/company mismatch'; END IF;
    IF NEW.driver_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.driver_user_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'expense user/company mismatch'; END IF;
    IF NEW.runsheet_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.runsheets r WHERE r.id=NEW.runsheet_id AND r.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'expense runsheet/company mismatch'; END IF;
    IF NEW.supplier_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.suppliers s WHERE s.id=NEW.supplier_id AND s.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'expense supplier/company mismatch'; END IF;
  ELSIF TG_TABLE_NAME='vehicle_tracking' THEN
    IF NEW.vehicle_id IS NULL OR NOT EXISTS (SELECT 1 FROM public.vehicles v WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'vehicle tracking vehicle/company mismatch'; END IF;
    IF NEW.driver_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id=NEW.driver_id AND u.company_id=NEW.company_id)
      THEN RAISE EXCEPTION 'vehicle tracking driver/company mismatch'; END IF;
  END IF;
  RETURN NEW;
END;
$function$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'fleet_drivers','fleet_driver_documents','fleet_vehicle_assignments','fleet_vehicle_contracts',
    'fleet_fuel_transactions','fleet_maintenance_plans','vehicle_maintenance','fleet_incidents',
    'fleet_driver_performance_events','fleet_expenses','vehicle_tracking'
  ] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_fleet_relation_guard ON public.%I',t);
    EXECUTE format('CREATE TRIGGER trg_fleet_relation_guard BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.fn_fleet_relation_guard()',t);
  END LOOP;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'fleet_drivers','fleet_driver_documents','fleet_vehicle_assignments','fleet_vehicle_contracts',
    'fleet_fuel_transactions','fleet_maintenance_plans','fleet_incidents','fleet_driver_performance_events','fleet_expenses'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I','deny_authenticated_'||t,t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (false) WITH CHECK (false)','deny_authenticated_'||t,t);
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.fleet_command_atomic(uuid,text,jsonb,text,uuid,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.fleet_query(uuid,text,jsonb,uuid) TO authenticated,service_role;
REVOKE ALL ON FUNCTION public.fleet_command_atomic(uuid,text,jsonb,text,uuid,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.fleet_query(uuid,text,jsonb,uuid) FROM PUBLIC,anon;

COMMIT;
