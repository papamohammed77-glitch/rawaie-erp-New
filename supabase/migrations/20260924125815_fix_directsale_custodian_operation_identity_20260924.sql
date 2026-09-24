-- RAWAEA ERP — DirectSale / DirectReturn custodian identity convergence
-- Production migration executed 2026-09-24.
-- Closure unit: Fleet Vehicle Operation Binding / Direct Sale
-- Root cause: the legacy mobile-voucher trigger derived custodian_user_id
-- from vehicles.driver_id, conflicting with the operation-level Direct Sales Rep
-- contract introduced by the 2026-09-21 voucher guard and the 2026-09-24
-- fleet vehicle-operation binding control plane.
-- No new Edge Function. Physical Stock contract unchanged:
-- post_stock_movement -> stock_branches + inventory_log.

BEGIN;

CREATE OR REPLACE FUNCTION public.enforce_stock_voucher_custodian()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_custodian public.users%ROWTYPE;
  v_vehicle public.vehicles%ROWTYPE;
  v_vehicle_id uuid;
BEGIN
  IF NEW.type NOT IN ('DirectSale','DirectReturn') THEN
    NEW.custodian_user_id := NULL;
    RETURN NEW;
  END IF;

  IF NEW.company_id IS NULL THEN
    RAISE EXCEPTION 'Company context is required for mobile custody';
  END IF;

  v_vehicle_id := CASE
    WHEN NEW.type='DirectSale' THEN NEW.to_id
    ELSE NEW.from_id
  END;

  IF (NEW.type='DirectSale'
      AND (NEW.to_type<>'Vehicle' OR NEW.to_id IS NULL))
     OR
     (NEW.type='DirectReturn'
      AND (NEW.from_type<>'Vehicle' OR NEW.from_id IS NULL)) THEN
    RAISE EXCEPTION 'Mobile voucher requires a Vehicle endpoint';
  END IF;

  SELECT *
  INTO v_vehicle
  FROM public.vehicles v
  WHERE v.id=v_vehicle_id
    AND v.company_id=NEW.company_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Mobile voucher vehicle is invalid for the company';
  END IF;

  IF NEW.custodian_user_id IS NULL THEN
    RAISE EXCEPTION 'Mobile voucher custodian is required';
  END IF;

  SELECT *
  INTO v_custodian
  FROM public.users u
  WHERE u.id=NEW.custodian_user_id
    AND u.company_id=NEW.company_id
    AND coalesce(u.status,'Active')='Active'
    AND u.role='مندوب بيع مباشر'
    AND COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Custodian must be an active same-company direct-sales representative with van-sales permission';
  END IF;

  IF TG_OP='UPDATE'
     AND OLD.status IN ('Sent','Received','Completed')
     AND (
       NEW.type IS DISTINCT FROM OLD.type
       OR NEW.from_type IS DISTINCT FROM OLD.from_type
       OR NEW.from_id IS DISTINCT FROM OLD.from_id
       OR NEW.to_type IS DISTINCT FROM OLD.to_type
       OR NEW.to_id IS DISTINCT FROM OLD.to_id
       OR NEW.custodian_user_id IS DISTINCT FROM OLD.custodian_user_id
     ) THEN
    RAISE EXCEPTION 'Executed mobile voucher identity is immutable';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_stock_vouchers_custodian
ON public.stock_vouchers;

CREATE TRIGGER trg_stock_vouchers_custodian
BEFORE INSERT OR UPDATE OF company_id,type,from_type,from_id,to_type,to_id,custodian_user_id,status
ON public.stock_vouchers
FOR EACH ROW
EXECUTE FUNCTION public.enforce_stock_voucher_custodian();

DO $$
DECLARE bad_count integer;
BEGIN
  SELECT count(*) INTO bad_count
  FROM public.stock_vouchers sv
  WHERE sv.type IN ('DirectSale','DirectReturn')
    AND (
      sv.custodian_user_id IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id=sv.custodian_user_id
          AND u.company_id=sv.company_id
          AND COALESCE(u.status,'Active')='Active'
          AND u.role='مندوب بيع مباشر'
          AND COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
      )
    );

  IF bad_count>0 THEN
    RAISE EXCEPTION 'Existing mobile vouchers have invalid custodian identity: %',bad_count;
  END IF;
END $$;

COMMIT;
