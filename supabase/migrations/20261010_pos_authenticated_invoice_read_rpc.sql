-- POS invoice read contract: company + authorized branch scope, without widening table RLS.
CREATE OR REPLACE FUNCTION public.get_pos_invoice_data(
  p_action text,
  p_order_code text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_company_id uuid;
  v_email text;
  v_branch_ids uuid[] := ARRAY[]::uuid[];
  v_order public.orders%ROWTYPE;
  v_details jsonb := '[]'::jsonb;
  v_action text := lower(btrim(COALESCE(p_action, '')));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;

  IF NOT app_private.current_user_has_permission('pos') THEN
    RAISE EXCEPTION 'POS permission required' USING ERRCODE = '42501';
  END IF;

  v_company_id := app_private.current_user_company_id();
  v_email := lower(btrim(COALESCE(auth.jwt() ->> 'email', '')));

  IF v_company_id IS NULL OR v_email = '' THEN
    RAISE EXCEPTION 'active POS user/company context not found' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(array_agg(b.id), ARRAY[]::uuid[])
    INTO v_branch_ids
  FROM public.get_pos_branches() AS b;

  IF v_action = 'today' THEN
    RETURN jsonb_build_object(
      'success', true,
      'action', 'today',
      'business_date', (now() AT TIME ZONE 'Africa/Cairo')::date,
      'invoices',
      COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', o.id,
            'order_code', o.order_code,
            'order_date', o.order_date,
            'customer_id', o.customer_id,
            'customer_name', o.customer_name,
            'total_amount', o.total_amount,
            'order_status', o.order_status,
            'created_by', o.created_by,
            'source', o.source,
            'branch_id', o.branch_id,
            'payment_type', o.payment_type
          )
          ORDER BY o.created_at DESC NULLS LAST, o.order_code DESC
        )
        FROM public.orders AS o
        WHERE o.company_id = v_company_id
          AND o.branch_id = ANY(v_branch_ids)
          AND lower(COALESCE(o.source, '')) = 'pos'
          AND lower(btrim(COALESCE(o.created_by, ''))) = v_email
          AND o.order_date = (now() AT TIME ZONE 'Africa/Cairo')::date
      ), '[]'::jsonb)
    );
  END IF;

  IF v_action NOT IN ('detail', 'return_lookup') THEN
    RAISE EXCEPTION 'unsupported POS invoice action' USING ERRCODE = '22023';
  END IF;

  IF NULLIF(btrim(COALESCE(p_order_code, '')), '') IS NULL THEN
    RAISE EXCEPTION 'order_code is required' USING ERRCODE = '22023';
  END IF;

  SELECT o.*
    INTO v_order
  FROM public.orders AS o
  WHERE o.company_id = v_company_id
    AND o.branch_id = ANY(v_branch_ids)
    AND lower(COALESCE(o.source, '')) = 'pos'
    AND o.order_code = btrim(p_order_code)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'action', v_action,
      'order', NULL,
      'details', '[]'::jsonb
    );
  END IF;

  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', d.id,
      'order_id', d.order_id,
      'item_id', d.item_id,
      'item_code', d.item_code,
      'item_name', d.item_name,
      'unit', d.unit,
      'unit_price', d.unit_price,
      'qty', d.qty,
      'qty_delivered', d.qty_delivered,
      'qty_returned', d.qty_returned,
      'line_amount', d.line_amount
    )
    ORDER BY d.created_at NULLS LAST, d.id
  ), '[]'::jsonb)
    INTO v_details
  FROM public.order_details AS d
  WHERE d.order_id = v_order.id;

  RETURN jsonb_build_object(
    'success', true,
    'action', v_action,
    'order', jsonb_build_object(
      'id', v_order.id,
      'company_id', v_order.company_id,
      'order_code', v_order.order_code,
      'order_date', v_order.order_date,
      'customer_id', v_order.customer_id,
      'customer_name', v_order.customer_name,
      'total_amount', v_order.total_amount,
      'order_status', v_order.order_status,
      'created_by', v_order.created_by,
      'source', v_order.source,
      'branch_id', v_order.branch_id,
      'payment_type', v_order.payment_type
    ),
    'details', v_details
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_pos_invoice_data(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_pos_invoice_data(text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_pos_invoice_data(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pos_invoice_data(text, text) TO service_role;
