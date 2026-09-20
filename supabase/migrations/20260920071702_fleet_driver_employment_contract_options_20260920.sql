-- RAWAEA ERP — Fleet driver employment contract options
-- Applied to Production as migration fleet_driver_employment_contract_options_20260920
BEGIN;

ALTER TABLE public.fleet_drivers
  DROP CONSTRAINT IF EXISTS fleet_drivers_employment_check;

ALTER TABLE public.fleet_drivers
  ADD CONSTRAINT fleet_drivers_employment_check
  CHECK (employment_type = ANY (ARRAY[
    'Employee'::text,
    'Contractor'::text,
    'Outsourced'::text,
    'RentalDriver'::text,
    'PerTrip'::text,
    'Monthly'::text,
    'Other'::text
  ]));

COMMIT;
