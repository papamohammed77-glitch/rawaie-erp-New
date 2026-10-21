-- Diagnostic-only hardening for reservation failures.
-- Does not change reservation eligibility or stock quantities.
CREATE OR REPLACE FUNCTION public.reserve_stock(p_company_id uuid, p_branch_id uuid, p_item_id uuid, p_qty numeric)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  s public.stock_branches%rowtype;
  bc uuid;
  v_item_code text;
  v_available numeric;
BEGIN
  IF p_company_id IS NULL OR p_branch_id IS NULL OR p_item_id IS NULL OR p_qty IS NULL OR p_qty <= 0 THEN
    RAISE EXCEPTION 'invalid reservation request';
  END IF;

  SELECT company_id INTO bc
  FROM public.branches
  WHERE id = p_branch_id;

  IF bc IS NULL OR bc <> p_company_id THEN
    RAISE EXCEPTION 'branch context invalid';
  END IF;

  SELECT item_code INTO v_item_code
  FROM public.items
  WHERE id = p_item_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'item reference invalid';
  END IF;

  SELECT *
  INTO s
  FROM public.stock_branches
  WHERE branch_id = p_branch_id
    AND item_id = p_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'stock balance not found';
  END IF;

  v_available := greatest(coalesce(s.qty, 0) - coalesce(s.allocated_qty, 0), 0);

  IF v_available < p_qty THEN
    RAISE EXCEPTION
      'insufficient available stock for reservation: item_code=%, requested=%, available=%',
      coalesce(v_item_code, p_item_id::text),
      p_qty,
      v_available;
  END IF;

  UPDATE public.stock_branches
  SET allocated_qty = s.allocated_qty + p_qty,
      updated_at = now()
  WHERE id = s.id
    AND qty = s.qty
    AND allocated_qty = s.allocated_qty;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'stock changed during reservation';
  END IF;

  RETURN true;
END;
$function$;
