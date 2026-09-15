-- RAWAEA ERP — Loyalty Transaction Engine production closure
-- Applied to Supabase project fiilmooggumokxanwiyx during the 2026-09-15 forensic closure.
-- Purpose: make invoice-linked loyalty earning atomic and operation-idempotent.

BEGIN;

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_transactions_company_operation_uidx
  ON public.loyalty_transactions(company_id, operation_id)
  WHERE operation_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.trg_loyalty_on_invoiced_order()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_result jsonb;
  v_operation_id text;
BEGIN
  IF NEW.order_status <> 'Invoiced'
     OR NEW.customer_id IS NULL
     OR NULLIF(btrim(COALESCE(NEW.created_by,'')),'') IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND COALESCE(OLD.order_status,'') = 'Invoiced' THEN
    RETURN NEW;
  END IF;

  v_operation_id := 'AUTO:EARN_ORDER:' || NEW.company_id::text || ':' || NEW.id::text;

  v_result := public.loyalty_engine_atomic(
    NEW.company_id,
    'EARN_ORDER',
    NEW.created_by,
    jsonb_build_object(
      'order_id', NEW.id::text,
      'reference_type', 'ORDER',
      'reference_id', NEW.order_code
    ),
    v_operation_id
  );

  IF COALESCE((v_result->>'success')::boolean,false) = false THEN
    RAISE EXCEPTION 'Automatic loyalty earning failed for order %', NEW.order_code;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_orders_loyalty_auto_earn ON public.orders;

CREATE CONSTRAINT TRIGGER trg_orders_loyalty_auto_earn
AFTER INSERT OR UPDATE OF order_status ON public.orders
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION public.trg_loyalty_on_invoiced_order();

REVOKE ALL ON FUNCTION public.trg_loyalty_on_invoiced_order() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_loyalty_on_invoiced_order() TO postgres, service_role;

REVOKE ALL ON FUNCTION public.loyalty_engine_atomic(uuid,text,text,jsonb,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.loyalty_engine_atomic(uuid,text,text,jsonb,text) TO postgres, service_role;

COMMIT;
