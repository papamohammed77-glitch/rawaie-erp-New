-- Least-privilege refinement: expose only fields required by POS.
CREATE OR REPLACE FUNCTION public.get_pos_bootstrap_data()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_company_id uuid;
  v_branch_ids uuid[] := ARRAY[]::uuid[];
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;

  IF NOT app_private.current_user_has_permission('pos') THEN
    RAISE EXCEPTION 'POS permission required' USING ERRCODE = '42501';
  END IF;

  v_company_id := app_private.current_user_company_id();
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'active company context not found' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(array_agg(b.id), ARRAY[]::uuid[])
    INTO v_branch_ids
  FROM public.get_pos_branches() AS b;

  RETURN jsonb_build_object(
    'customers',
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', c.id,
        'company_id', c.company_id,
        'customer_code', c.customer_code,
        'name', c.name,
        'area', c.area,
        'phone', c.phone,
        'debt', c.debt
      ) ORDER BY c.customer_code)
      FROM public.customers AS c
      WHERE c.company_id = v_company_id
        AND COALESCE(c.is_active, true) IS TRUE
    ), '[]'::jsonb),

    'items',
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', i.id,
        'company_id', i.company_id,
        'item_code', i.item_code,
        'barcode', i.barcode,
        'name', i.name,
        'search_label', i.search_label,
        'category', i.category,
        'unit', i.unit,
        'sales_price', i.sales_price,
        'max_qty', i.max_qty,
        'image_url', i.image_url,
        'discount_percent', i.discount_percent
      ) ORDER BY i.item_code)
      FROM public.items AS i
      WHERE i.company_id = v_company_id
        AND COALESCE(i.is_active, true) IS TRUE
    ), '[]'::jsonb),

    'stock',
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'item_id', s.item_id,
        'branch_id', s.branch_id,
        'qty', s.qty,
        'allocated_qty', s.allocated_qty
      ) ORDER BY s.branch_id, s.item_id)
      FROM public.stock_branches AS s
      WHERE s.branch_id = ANY(v_branch_ids)
    ), '[]'::jsonb),

    'branches',
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', b.id,
        'company_id', b.company_id,
        'branch_code', b.branch_code,
        'name', b.name
      ) ORDER BY b.name, b.branch_code)
      FROM public.get_pos_branches() AS b
    ), '[]'::jsonb),

    'fast_selling',
    COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'item_code', recent.item_code,
        'item_name', recent.item_name
      ) ORDER BY recent.created_at DESC)
      FROM (
        SELECT od.item_code, od.item_name, od.created_at
        FROM public.order_details AS od
        JOIN public.orders AS o ON o.id = od.order_id
        WHERE o.company_id = v_company_id
          AND od.created_at >= (date_trunc('day', now() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC')
          AND od.item_code IS NOT NULL
        ORDER BY od.created_at DESC
        LIMIT 100
      ) AS recent
    ), '[]'::jsonb),

    'currency',
    COALESCE((
      SELECT a.currency
      FROM public.app_settings AS a
      WHERE a.company_id = v_company_id
      ORDER BY a.created_at ASC, a.id
      LIMIT 1
    ), 'EGP')
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_pos_bootstrap_data() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_pos_bootstrap_data() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_pos_bootstrap_data() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pos_bootstrap_data() TO service_role;
