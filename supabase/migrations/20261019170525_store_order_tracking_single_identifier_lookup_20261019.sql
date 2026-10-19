-- Public storefront tracking: allow either order code or phone for status-only lookup.
-- Full order/customer/item details require both values.
CREATE OR REPLACE FUNCTION public.get_public_store_order_tracking(
  p_storefront_key text,
  p_order_code text,
  p_customer_phone text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
DECLARE
  v_company_ids uuid[];
  v_phone_digits text;
  v_order_code text := nullif(btrim(coalesce(p_order_code, '')), '');
  v_phone_input text := btrim(coalesce(p_customer_phone, ''));
  v_result jsonb;
  v_orders jsonb;
BEGIN
  v_phone_digits := regexp_replace(coalesce(p_customer_phone, ''), '[^0-9]', '', 'g');

  IF nullif(btrim(coalesce(p_storefront_key, '')), '') IS NULL
     OR (v_order_code IS NULL AND v_phone_input = '') THEN
    RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
  END IF;

  IF v_phone_input <> '' AND length(v_phone_digits) < 7 THEN
    RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
  END IF;

  SELECT array_agg(DISTINCT s.company_id)
    INTO v_company_ids
  FROM public.app_settings AS s
  WHERE s.storefront_key = btrim(p_storefront_key)
    AND s.storefront_enabled IS TRUE
    AND s.company_id IS NOT NULL;

  IF coalesce(cardinality(v_company_ids), 0) <> 1 THEN
    RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
  END IF;

  -- Full details require both independent lookup values.
  IF v_order_code IS NOT NULL AND v_phone_input <> '' THEN
    SELECT jsonb_build_object(
      'success', true,
      'lookup_mode', 'full',
      'order', jsonb_build_object(
        'order_code', o.order_code,
        'order_date', o.order_date,
        'order_status', o.order_status,
        'customer_name', o.customer_name,
        'area', o.area,
        'total_amount', o.total_amount
      ),
      'items', coalesce((
        SELECT jsonb_agg(
          jsonb_build_object(
            'item_name', od.item_name,
            'qty', od.qty,
            'unit_price', od.unit_price,
            'line_amount', coalesce(od.line_amount, od.qty * od.unit_price)
          )
          ORDER BY od.created_at NULLS LAST, od.id
        )
        FROM public.order_details AS od
        WHERE od.order_id = o.id
      ), '[]'::jsonb)
    )
    INTO v_result
    FROM public.orders AS o
    WHERE o.company_id = v_company_ids[1]
      AND o.source = 'online_store'
      AND o.order_code = v_order_code
      AND regexp_replace(coalesce(o.customer_phone, ''), '[^0-9]', '', 'g') = v_phone_digits
    LIMIT 1;

    IF v_result IS NULL THEN
      RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
    END IF;

    RETURN v_result;
  END IF;

  -- Order-code-only lookup deliberately returns a public-safe status projection.
  -- It does not disclose customer identity, area, amount, or line items.
  IF v_order_code IS NOT NULL THEN
    SELECT jsonb_build_object(
      'success', true,
      'lookup_mode', 'order_code',
      'order', jsonb_build_object(
        'order_code', o.order_code,
        'order_date', o.order_date,
        'order_status', o.order_status
      )
    )
    INTO v_result
    FROM public.orders AS o
    WHERE o.company_id = v_company_ids[1]
      AND o.source = 'online_store'
      AND o.order_code = v_order_code
    LIMIT 1;

    IF v_result IS NULL THEN
      RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
    END IF;

    RETURN v_result;
  END IF;

  -- Phone-only lookup returns at most 10 recent order summaries, never customer PII,
  -- monetary values, or item details. Full details require both values above.
  SELECT jsonb_agg(
    jsonb_build_object(
      'order_code', x.order_code,
      'order_date', x.order_date,
      'order_status', x.order_status
    )
    ORDER BY x.created_at DESC
  )
  INTO v_orders
  FROM (
    SELECT o.order_code, o.order_date, o.order_status, o.created_at
    FROM public.orders AS o
    WHERE o.company_id = v_company_ids[1]
      AND o.source = 'online_store'
      AND regexp_replace(coalesce(o.customer_phone, ''), '[^0-9]', '', 'g') = v_phone_digits
    ORDER BY o.created_at DESC, o.id DESC
    LIMIT 10
  ) AS x;

  IF coalesce(jsonb_array_length(v_orders), 0) = 0 THEN
    RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'lookup_mode', 'phone',
    'orders', v_orders
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_public_store_order_tracking(text, text, text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_public_store_order_tracking(text, text, text) TO anon, authenticated;
