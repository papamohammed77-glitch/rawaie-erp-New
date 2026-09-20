-- RAWAEA ERP Production function snapshot
-- Captured: 2026-09-20 UTC
-- Source: live Supabase PostgreSQL
-- Function: fn_vehicle_context_guard

CREATE OR REPLACE FUNCTION public.fn_vehicle_context_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.company_id IS NULL THEN RAISE EXCEPTION 'vehicle company context is required'; END IF;
  IF NEW.driver_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id=NEW.driver_id AND u.company_id=NEW.company_id
  ) THEN
    RAISE EXCEPTION 'vehicle driver does not belong to vehicle company';
  END IF;
  IF NEW.fleet_driver_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.fleet_drivers fd
    WHERE fd.id=NEW.fleet_driver_id AND fd.company_id=NEW.company_id
  ) THEN
    RAISE EXCEPTION 'vehicle fleet driver does not belong to vehicle company';
  END IF;
  IF NEW.mobile_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id=NEW.mobile_branch_id
      AND b.company_id=NEW.company_id
      AND b.branch_code='VAN-'||NEW.vehicle_code
  ) THEN
    RAISE EXCEPTION 'vehicle mobile branch does not match company/vehicle code';
  END IF;
  NEW.updated_at:=now();
  RETURN NEW;
END;
$function$

