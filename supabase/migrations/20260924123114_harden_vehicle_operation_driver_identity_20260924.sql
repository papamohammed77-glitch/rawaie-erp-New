-- RAWAEA ERP — Harden fleet vehicle operation driver identity.
-- Production migration executed 2026-09-24.
BEGIN;

CREATE OR REPLACE FUNCTION public.enforce_stock_voucher_transfer_vehicle_context()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_vehicle public.vehicles%ROWTYPE;
  v_driver public.users%ROWTYPE;
BEGIN
  IF NEW.type <> 'Transfer' THEN
    IF NEW.vehicle_id IS NOT NULL OR NEW.driver_id IS NOT NULL THEN
      RAISE EXCEPTION 'vehicle_id/driver_id are supported only for Branch Transfer vouchers';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.vehicle_id IS NULL AND NEW.driver_id IS NULL THEN RETURN NEW; END IF;
  IF NEW.vehicle_id IS NULL OR NEW.driver_id IS NULL THEN
    RAISE EXCEPTION 'Branch Transfer vehicle and driver must be provided together';
  END IF;

  SELECT * INTO v_vehicle FROM public.vehicles
  WHERE id=NEW.vehicle_id AND company_id=NEW.company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Transfer vehicle does not belong to the voucher company'; END IF;

  SELECT * INTO v_driver FROM public.users u
  WHERE u.id=NEW.driver_id
    AND u.company_id=NEW.company_id
    AND COALESCE(u.status,'Active')='Active'
    AND (
      u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
      OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
    );
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transfer driver does not belong to the company or is not a delivery/driver identity';
  END IF;

  IF TG_OP='UPDATE'
     AND OLD.status IN ('Sent','Received','Completed')
     AND OLD.vehicle_id IS NOT NULL
     AND (
       NEW.vehicle_id IS DISTINCT FROM OLD.vehicle_id
       OR NEW.driver_id IS DISTINCT FROM OLD.driver_id
     ) THEN
    RAISE EXCEPTION 'Executed Branch Transfer vehicle/driver identity is immutable';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_stock_vouchers_transfer_vehicle_context
ON public.stock_vouchers;

CREATE TRIGGER trg_stock_vouchers_transfer_vehicle_context
BEFORE INSERT OR UPDATE OF type,company_id,vehicle_id,driver_id,status
ON public.stock_vouchers
FOR EACH ROW EXECUTE FUNCTION public.enforce_stock_voucher_transfer_vehicle_context();

DO $$
DECLARE v_def text; v_new text; v_old text; v_rep text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='fleet_command_atomic' LIMIT 1;
  IF v_def IS NULL THEN RAISE EXCEPTION 'fleet_command_atomic not found'; END IF;

  v_old := $old$
        IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id AND u.company_id=p_company_id AND coalesce(u.status,'Active')='Active'
        ) THEN RAISE EXCEPTION 'السائق التشغيلي غير صالح للشركة'; END IF;
$old$;
  v_rep := $new$
        IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND coalesce(u.status,'Active')='Active'
            AND (
              u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
              OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
            )
        ) THEN RAISE EXCEPTION 'السائق التشغيلي غير صالح أو ليس هوية سائق/توصيل'; END IF;
$new$;

  IF strpos(v_def,v_old)=0 THEN RAISE EXCEPTION 'RUNSHEET_ASSIGN driver marker not found'; END IF;
  v_new:=replace(v_def,v_old,v_rep);
  EXECUTE v_new;
END $$;

COMMIT;
