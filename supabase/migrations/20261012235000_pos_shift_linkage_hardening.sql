-- Harden shift linkage: prevent cross-order/cross-shift assignment through the cash ledger.
CREATE OR REPLACE FUNCTION public.pos_assign_order_shift()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cashier_user_id uuid;
  v_shift public.pos_shifts%ROWTYPE;
BEGIN
  IF lower(btrim(COALESCE(NEW.source, ''))) <> 'pos' THEN
    IF NEW.shift_id IS NOT NULL THEN
      RAISE EXCEPTION 'POS_SHIFT_CAN_ONLY_ATTACH_TO_POS_ORDERS';
    END IF;
    RETURN NEW;
  END IF;

  SELECT u.id INTO v_cashier_user_id
  FROM public.users u
  WHERE u.company_id = NEW.company_id
    AND lower(u.email) = lower(COALESCE(NEW.created_by, ''))
    AND COALESCE(u.status, 'Active') = 'Active'
  LIMIT 1;

  IF NEW.shift_id IS NOT NULL THEN
    SELECT * INTO v_shift
    FROM public.pos_shifts s
    WHERE s.id = NEW.shift_id
      AND s.company_id = NEW.company_id
      AND s.branch_id = NEW.branch_id
      AND s.status = 'open'
      AND s.cashier_user_id = v_cashier_user_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'POS_SHIFT_INVALID_OR_NOT_OWNED'; END IF;
    RETURN NEW;
  END IF;

  IF v_cashier_user_id IS NULL OR NEW.branch_id IS NULL THEN RETURN NEW; END IF;

  SELECT * INTO v_shift
  FROM public.pos_shifts s
  WHERE s.company_id = NEW.company_id
    AND s.branch_id = NEW.branch_id
    AND s.cashier_user_id = v_cashier_user_id
    AND s.status = 'open'
  ORDER BY s.opened_at DESC
  LIMIT 1;

  IF FOUND THEN NEW.shift_id := v_shift.id; END IF;
  -- Rollout remains backward compatible until owner applies the POS UI guard.
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.pos_assign_cash_box_shift()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_order_shift_id uuid;
BEGIN
  IF upper(COALESCE(NEW.source_type, '')) IN ('POS','POS_RETURN_REFUND')
     AND NEW.source_id IS NOT NULL THEN
    SELECT o.shift_id INTO v_order_shift_id
    FROM public.orders o
    WHERE o.id = NEW.source_id AND o.company_id = NEW.company_id
    LIMIT 1;

    IF NEW.shift_id IS NOT NULL AND NEW.shift_id IS DISTINCT FROM v_order_shift_id THEN
      RAISE EXCEPTION 'POS_CASH_ENTRY_SHIFT_MISMATCH';
    END IF;
    IF NEW.shift_id IS NULL THEN NEW.shift_id := v_order_shift_id; END IF;
    RETURN NEW;
  END IF;

  IF NEW.shift_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.pos_shifts s
    WHERE s.id = NEW.shift_id AND s.company_id = NEW.company_id
  ) THEN
    RAISE EXCEPTION 'POS_SHIFT_COMPANY_MISMATCH';
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.pos_assign_order_shift() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.pos_assign_cash_box_shift() FROM PUBLIC, anon, authenticated, service_role;
