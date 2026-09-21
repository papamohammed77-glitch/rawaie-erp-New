BEGIN;

ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS custodian_user_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname='stock_vouchers_custodian_user_fk'
      AND conrelid='public.stock_vouchers'::regclass
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_custodian_user_fk
      FOREIGN KEY (custodian_user_id)
      REFERENCES public.users(id)
      ON DELETE RESTRICT;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_stock_vouchers_custodian_user_id
  ON public.stock_vouchers(custodian_user_id);

UPDATE public.stock_vouchers sv
SET custodian_user_id=v.driver_id
FROM public.vehicles v
WHERE sv.custodian_user_id IS NULL
  AND sv.type IN ('DirectSale','DirectReturn')
  AND sv.company_id=v.company_id
  AND (
    (sv.type='DirectSale' AND sv.to_type='Vehicle' AND sv.to_id=v.id)
    OR
    (sv.type='DirectReturn' AND sv.from_type='Vehicle' AND sv.from_id=v.id)
  );

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.stock_vouchers sv
    WHERE sv.type IN ('DirectSale','DirectReturn')
      AND sv.custodian_user_id IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot enforce mobile custody: existing DirectSale/DirectReturn voucher has no custodian';
  END IF;
END$$;

CREATE OR REPLACE FUNCTION public.enforce_stock_voucher_custodian()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_expected_driver uuid;
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

  v_expected_driver := v_vehicle.driver_id;

  IF v_expected_driver IS NULL THEN
    RAISE EXCEPTION 'Mobile voucher vehicle has no assigned direct-sales representative';
  END IF;

  IF NEW.custodian_user_id IS NULL THEN
    NEW.custodian_user_id := v_expected_driver;
  ELSIF NEW.custodian_user_id <> v_expected_driver THEN
    RAISE EXCEPTION 'Custodian does not match the vehicle assigned representative';
  END IF;

  SELECT *
  INTO v_custodian
  FROM public.users u
  WHERE u.id=NEW.custodian_user_id
    AND u.company_id=NEW.company_id
    AND coalesce(u.status,'Active')='Active'
    AND u.role='مندوب بيع مباشر';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Custodian must be an active direct-sales representative in the same company';
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
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname='stock_vouchers_mobile_custodian_required_ck'
      AND conrelid='public.stock_vouchers'::regclass
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_mobile_custodian_required_ck
      CHECK (
        type NOT IN ('DirectSale','DirectReturn')
        OR custodian_user_id IS NOT NULL
      );
  END IF;
END$$;

COMMIT;
