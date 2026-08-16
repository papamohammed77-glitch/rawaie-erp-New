-- RAWAEA ERP — Stage 28 canonical setup-van-branch contract
-- Vehicle owns the mobile stock location. Driver is representative metadata only.
-- Initialization creates zero-balance stock rows only; it never posts stock movement.

BEGIN;

CREATE UNIQUE INDEX IF NOT EXISTS ux_branches_company_branch_code
  ON public.branches (company_id, branch_code);

CREATE OR REPLACE FUNCTION public.setup_van_stock(p_van_branch_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_company_id uuid;
  v_main_branch_id uuid;
  v_item_count integer := 0;
BEGIN
  IF p_van_branch_id IS NULL THEN
    RAISE EXCEPTION 'van branch id is required';
  END IF;

  SELECT company_id
    INTO v_company_id
  FROM public.branches
  WHERE id = p_van_branch_id;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'van branch not found';
  END IF;

  SELECT main_branch_id
    INTO v_main_branch_id
  FROM public.app_settings
  WHERE company_id = v_company_id;

  IF v_main_branch_id IS NULL THEN
    RAISE EXCEPTION 'MAIN branch context not found for company';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.branches b
    WHERE b.id = v_main_branch_id
      AND b.company_id = v_company_id
  ) THEN
    RAISE EXCEPTION 'MAIN branch does not belong to the same company';
  END IF;

  INSERT INTO public.stock_branches (
    branch_id,
    item_id,
    qty,
    allocated_qty,
    updated_at
  )
  SELECT
    p_van_branch_id,
    sb.item_id,
    0,
    0,
    now()
  FROM public.stock_branches sb
  JOIN public.items i
    ON i.id = sb.item_id
   AND i.company_id = v_company_id
  WHERE sb.branch_id = v_main_branch_id
    AND NOT EXISTS (
      SELECT 1
      FROM public.stock_branches sb2
      WHERE sb2.branch_id = p_van_branch_id
        AND sb2.item_id = sb.item_id
    );

  GET DIAGNOSTICS v_item_count = ROW_COUNT;

  RETURN 'OK: ' || v_item_count || ' items copied';
END;
$function$;

REVOKE ALL ON FUNCTION public.setup_van_stock(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.setup_van_stock(uuid) TO service_role;

COMMIT;
