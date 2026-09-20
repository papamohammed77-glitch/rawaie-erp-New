-- RAWAEA ERP — Fleet capacity, cargo dimensions, condition and route capability
-- Applied to Production as migration fleet_capacity_route_driver_contract_closure_20260920_v2
BEGIN;

ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS cargo_length_m numeric,
  ADD COLUMN IF NOT EXISTS cargo_width_m numeric,
  ADD COLUMN IF NOT EXISTS cargo_height_m numeric,
  ADD COLUMN IF NOT EXISTS operational_condition text,
  ADD COLUMN IF NOT EXISTS route_capability text;

UPDATE public.vehicles
SET operational_condition=coalesce(nullif(operational_condition,''),'Good'),
    route_capability=coalesce(nullif(route_capability,''),'Any');

ALTER TABLE public.vehicles
  ALTER COLUMN operational_condition SET DEFAULT 'Good',
  ALTER COLUMN route_capability SET DEFAULT 'Any';

ALTER TABLE public.vehicles
  DROP CONSTRAINT IF EXISTS vehicles_ownership_type_check,
  DROP CONSTRAINT IF EXISTS vehicles_operational_condition_check,
  DROP CONSTRAINT IF EXISTS vehicles_route_capability_check,
  DROP CONSTRAINT IF EXISTS vehicles_cargo_dimensions_positive_check;

ALTER TABLE public.vehicles
  ADD CONSTRAINT vehicles_ownership_type_check
    CHECK (ownership_type IS NULL OR ownership_type IN ('Owned','RentedPerTrip','RentedMonthly','Other')),
  ADD CONSTRAINT vehicles_operational_condition_check
    CHECK (operational_condition IS NULL OR operational_condition IN ('Excellent','Good','Fair','Poor')),
  ADD CONSTRAINT vehicles_route_capability_check
    CHECK (route_capability IS NULL OR route_capability IN ('LocalOnly','Regional','LongHaul','Any')),
  ADD CONSTRAINT vehicles_cargo_dimensions_positive_check
    CHECK (
      (cargo_length_m IS NULL OR cargo_length_m>0) AND
      (cargo_width_m IS NULL OR cargo_width_m>0) AND
      (cargo_height_m IS NULL OR cargo_height_m>0)
    );

-- The deployed fleet_command_atomic definition is intentionally patched in-place
-- in Production by the closure session; the canonical deployed SQL is recorded
-- in the accompanying forensic report to avoid duplicating a generated function body here.

COMMIT;
