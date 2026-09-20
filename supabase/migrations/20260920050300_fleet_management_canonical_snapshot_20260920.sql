
-- RAWAEA ERP — FLEET MANAGEMENT PRODUCTION CANONICAL SNAPSHOT
-- Date: 2026-09-20
-- This file mirrors Production after:
--   fleet_management_core_20260920
--   fleet_tenant_relation_guards_20260920
--   fleet_command_idempotency_and_query_fix_20260920
-- It is intentionally self-contained for the Fleet-specific additions,
-- while relying on pre-existing RAWAEA core functions:
-- create_vehicle_atomic, setup_van_stock, erp_operation_registry, fn_vehicle_audit_trigger.

BEGIN;

CREATE TABLE IF NOT EXISTS public.fleet_drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  driver_code text NOT NULL,
  full_name text NOT NULL,
  phone text,
  email text,
  user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  employee_id text,
  employment_type text NOT NULL DEFAULT 'Employee',
  status text NOT NULL DEFAULT 'Active',
  hire_date date,
  termination_date date,
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_drivers_status_check CHECK (status IN ('Active','Inactive','Suspended','Terminated')),
  CONSTRAINT fleet_drivers_employment_check CHECK (employment_type IN ('Employee','Contractor','Outsourced','RentalDriver')),
  CONSTRAINT fleet_drivers_code_uq UNIQUE (company_id, driver_code),
  CONSTRAINT fleet_drivers_user_uq UNIQUE (company_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.fleet_driver_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  fleet_driver_id uuid NOT NULL REFERENCES public.fleet_drivers(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  document_number text,
  license_class text,
  issue_date date,
  expiry_date date,
  alert_days_before integer NOT NULL DEFAULT 30,
  document_url text,
  status text NOT NULL DEFAULT 'Active',
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_driver_documents_alert_check CHECK (alert_days_before >= 0),
  CONSTRAINT fleet_driver_documents_status_check CHECK (status IN ('Active','Expired','Cancelled'))
);

CREATE TABLE IF NOT EXISTS public.fleet_vehicle_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  fleet_driver_id uuid REFERENCES public.fleet_drivers(id) ON DELETE SET NULL,
  driver_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  start_at timestamptz NOT NULL DEFAULT now(),
  end_at timestamptz,
  assignment_type text NOT NULL DEFAULT 'Primary',
  is_primary boolean NOT NULL DEFAULT true,
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_vehicle_assignments_dates_check CHECK (end_at IS NULL OR end_at >= start_at)
);

CREATE TABLE IF NOT EXISTS public.fleet_vehicle_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  contract_number text NOT NULL,
  contract_type text NOT NULL,
  start_date date NOT NULL,
  end_date date,
  status text NOT NULL DEFAULT 'Active',
  responsible_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  monthly_cost numeric NOT NULL DEFAULT 0,
  total_contract_value numeric,
  deposit_amount numeric NOT NULL DEFAULT 0,
  included_km numeric,
  excess_km_rate numeric,
  notes text,
  document_url text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_vehicle_contracts_type_check CHECK (contract_type IN ('Lease','Rental','OperatingLease','Insurance','Other')),
  CONSTRAINT fleet_vehicle_contracts_status_check CHECK (status IN ('Draft','Active','Expired','Cancelled','Closed')),
  CONSTRAINT fleet_vehicle_contracts_dates_check CHECK (end_date IS NULL OR end_date >= start_date),
  CONSTRAINT fleet_vehicle_contracts_cost_check CHECK (monthly_cost >= 0 AND deposit_amount >= 0 AND (total_contract_value IS NULL OR total_contract_value >= 0)),
  CONSTRAINT fleet_vehicle_contracts_uq UNIQUE (company_id, contract_number)
);

CREATE TABLE IF NOT EXISTS public.fleet_fuel_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  fleet_driver_id uuid REFERENCES public.fleet_drivers(id) ON DELETE SET NULL,
  driver_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  runsheet_id uuid REFERENCES public.runsheets(id) ON DELETE SET NULL,
  transaction_date timestamptz NOT NULL DEFAULT now(),
  odometer_km integer,
  liters numeric NOT NULL,
  unit_price numeric NOT NULL,
  total_cost numeric GENERATED ALWAYS AS (round(liters * unit_price, 2)) STORED,
  fuel_type text,
  station_name text,
  fuel_card_number text,
  full_tank boolean,
  receipt_url text,
  reference text,
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_fuel_liters_check CHECK (liters > 0),
  CONSTRAINT fleet_fuel_unit_price_check CHECK (unit_price >= 0),
  CONSTRAINT fleet_fuel_odometer_check CHECK (odometer_km IS NULL OR odometer_km >= 0)
);

CREATE TABLE IF NOT EXISTS public.fleet_maintenance_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id uuid NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  plan_code text NOT NULL,
  name text NOT NULL,
  maintenance_type text NOT NULL DEFAULT 'Preventive',
  active boolean NOT NULL DEFAULT true,
  interval_km integer,
  interval_days integer,
  alert_km_before integer NOT NULL DEFAULT 500,
  alert_days_before integer NOT NULL DEFAULT 30,
  last_service_date date,
  last_service_odometer_km integer,
  next_service_date date,
  next_service_odometer_km integer,
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_maintenance_plans_type_check CHECK (maintenance_type IN ('Preventive','Inspection','Safety','Other')),
  CONSTRAINT fleet_maintenance_plans_interval_check CHECK ((interval_km IS NOT NULL AND interval_km > 0) OR (interval_days IS NOT NULL AND interval_days > 0)),
  CONSTRAINT fleet_maintenance_plans_alert_check CHECK (alert_km_before >= 0 AND alert_days_before >= 0),
  CONSTRAINT fleet_maintenance_plans_uq UNIQUE (company_id, plan_code)
);

CREATE TABLE IF NOT EXISTS public.fleet_incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id uuid REFERENCES public.vehicles(id) ON DELETE SET NULL,
  fleet_driver_id uuid REFERENCES public.fleet_drivers(id) ON DELETE SET NULL,
  driver_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  runsheet_id uuid REFERENCES public.runsheets(id) ON DELETE SET NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  incident_type text NOT NULL,
  severity text NOT NULL DEFAULT 'Medium',
  status text NOT NULL DEFAULT 'Open',
  description text NOT NULL,
  root_cause text,
  corrective_action text,
  customer_impact text,
  product_loss_value numeric NOT NULL DEFAULT 0,
  vehicle_damage_cost numeric NOT NULL DEFAULT 0,
  insurance_reference text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_incidents_severity_check CHECK (severity IN ('Low','Medium','High','Critical')),
  CONSTRAINT fleet_incidents_status_check CHECK (status IN ('Open','Investigating','Resolved','Closed','Cancelled')),
  CONSTRAINT fleet_incidents_cost_check CHECK (product_loss_value >= 0 AND vehicle_damage_cost >= 0)
);

CREATE TABLE IF NOT EXISTS public.fleet_driver_performance_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  fleet_driver_id uuid REFERENCES public.fleet_drivers(id) ON DELETE SET NULL,
  driver_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  vehicle_id uuid REFERENCES public.vehicles(id) ON DELETE SET NULL,
  runsheet_id uuid REFERENCES public.runsheets(id) ON DELETE SET NULL,
  incident_id uuid REFERENCES public.fleet_incidents(id) ON DELETE SET NULL,
  event_date timestamptz NOT NULL DEFAULT now(),
  category text NOT NULL,
  severity text NOT NULL DEFAULT 'Medium',
  points integer NOT NULL DEFAULT 0,
  repeat_key text,
  description text NOT NULL,
  corrective_action text,
  status text NOT NULL DEFAULT 'Open',
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_driver_perf_severity_check CHECK (severity IN ('Low','Medium','High','Critical')),
  CONSTRAINT fleet_driver_perf_status_check CHECK (status IN ('Open','Acknowledged','Resolved','Closed')),
  CONSTRAINT fleet_driver_perf_points_check CHECK (points >= -1000 AND points <= 1000)
);

CREATE TABLE IF NOT EXISTS public.fleet_expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  vehicle_id uuid REFERENCES public.vehicles(id) ON DELETE SET NULL,
  fleet_driver_id uuid REFERENCES public.fleet_drivers(id) ON DELETE SET NULL,
  driver_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  runsheet_id uuid REFERENCES public.runsheets(id) ON DELETE SET NULL,
  expense_date timestamptz NOT NULL DEFAULT now(),
  category text NOT NULL,
  amount numeric NOT NULL,
  supplier_id uuid REFERENCES public.suppliers(id) ON DELETE SET NULL,
  reference text,
  accounting_reference text,
  notes text,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fleet_expenses_amount_check CHECK (amount >= 0)
);

ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS fleet_driver_id uuid,
  ADD COLUMN IF NOT EXISTS registration_date date,
  ADD COLUMN IF NOT EXISTS commission_date date,
  ADD COLUMN IF NOT EXISTS retirement_date date,
  ADD COLUMN IF NOT EXISTS engine_number text,
  ADD COLUMN IF NOT EXISTS color text,
  ADD COLUMN IF NOT EXISTS fuel_tank_capacity_l numeric,
  ADD COLUMN IF NOT EXISTS expected_km_per_liter numeric;

ALTER TABLE public.vehicle_tracking
  ADD COLUMN IF NOT EXISTS reading_type text NOT NULL DEFAULT 'Odometer',
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'Manual',
  ADD COLUMN IF NOT EXISTS source_id uuid,
  ADD COLUMN IF NOT EXISTS reference text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS recorded_by text;

ALTER TABLE public.vehicle_maintenance
  ADD COLUMN IF NOT EXISTS maintenance_plan_id uuid,
  ADD COLUMN IF NOT EXISTS priority text NOT NULL DEFAULT 'Medium',
  ADD COLUMN IF NOT EXISTS parts_cost numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS labor_cost numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS downtime_hours numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS work_order_reference text,
  ADD COLUMN IF NOT EXISTS incident_id uuid;

ALTER TABLE public.vehicle_documents
  ADD COLUMN IF NOT EXISTS alert_days_before integer NOT NULL DEFAULT 30;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='vehicles_fleet_driver_id_fkey' AND conrelid='public.vehicles'::regclass) THEN
    ALTER TABLE public.vehicles ADD CONSTRAINT vehicles_fleet_driver_id_fkey FOREIGN KEY (fleet_driver_id) REFERENCES public.fleet_drivers(id) ON DELETE SET NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='vehicle_maintenance_plan_fk' AND conrelid='public.vehicle_maintenance'::regclass) THEN
    ALTER TABLE public.vehicle_maintenance ADD CONSTRAINT vehicle_maintenance_plan_fk FOREIGN KEY (maintenance_plan_id) REFERENCES public.fleet_maintenance_plans(id) ON DELETE SET NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='vehicle_maintenance_incident_fk' AND conrelid='public.vehicle_maintenance'::regclass) THEN
    ALTER TABLE public.vehicle_maintenance ADD CONSTRAINT vehicle_maintenance_incident_fk FOREIGN KEY (incident_id) REFERENCES public.fleet_incidents(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_fleet_drivers_company_status ON public.fleet_drivers(company_id,status);
CREATE INDEX IF NOT EXISTS idx_fleet_driver_documents_company_expiry ON public.fleet_driver_documents(company_id,expiry_date);
CREATE INDEX IF NOT EXISTS idx_fleet_driver_documents_driver ON public.fleet_driver_documents(fleet_driver_id,expiry_date);
CREATE INDEX IF NOT EXISTS idx_fleet_vehicle_assignments_vehicle_open ON public.fleet_vehicle_assignments(vehicle_id,end_at);
CREATE INDEX IF NOT EXISTS idx_fleet_vehicle_assignments_driver_open ON public.fleet_vehicle_assignments(fleet_driver_id,end_at);
CREATE INDEX IF NOT EXISTS idx_fleet_vehicle_contracts_vehicle_dates ON public.fleet_vehicle_contracts(vehicle_id,start_date,end_date);
CREATE INDEX IF NOT EXISTS idx_fleet_fuel_vehicle_date ON public.fleet_fuel_transactions(vehicle_id,transaction_date);
CREATE INDEX IF NOT EXISTS idx_fleet_fuel_runsheet ON public.fleet_fuel_transactions(runsheet_id);
CREATE INDEX IF NOT EXISTS idx_fleet_plans_vehicle_due ON public.fleet_maintenance_plans(vehicle_id,next_service_date,next_service_odometer_km);
CREATE INDEX IF NOT EXISTS idx_fleet_incidents_vehicle_date ON public.fleet_incidents(vehicle_id,occurred_at);
CREATE INDEX IF NOT EXISTS idx_fleet_perf_driver_date ON public.fleet_driver_performance_events(fleet_driver_id,event_date);
CREATE INDEX IF NOT EXISTS idx_fleet_expenses_vehicle_date ON public.fleet_expenses(vehicle_id,expense_date);

CREATE UNIQUE INDEX IF NOT EXISTS uq_fleet_vehicle_primary_assignment ON public.fleet_vehicle_assignments(vehicle_id) WHERE end_at IS NULL AND is_primary=true;
CREATE UNIQUE INDEX IF NOT EXISTS uq_fleet_driver_primary_assignment ON public.fleet_vehicle_assignments(fleet_driver_id) WHERE end_at IS NULL AND is_primary=true AND fleet_driver_id IS NOT NULL;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'fleet_drivers','fleet_driver_documents','fleet_vehicle_assignments','fleet_vehicle_contracts',
    'fleet_fuel_transactions','fleet_maintenance_plans','fleet_incidents',
    'fleet_driver_performance_events','fleet_expenses'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I','deny_authenticated_'||t,t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (false) WITH CHECK (false)','deny_authenticated_'||t,t);
  END LOOP;
END $$;

COMMIT;

-- FUNCTION SNAPSHOT FETCH FAILED
