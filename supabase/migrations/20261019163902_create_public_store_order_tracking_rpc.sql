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
  v_result jsonb;
BEGIN
  v_phone_digits := regexp_replace(coalesce(p_customer_phone, ''), '[^0-9]', '', 'g');

  IF nullif(btrim(coalesce(p_storefront_key, '')), '') IS NULL
     OR nullif(btrim(coalesce(p_order_code, '')), '') IS NULL
     OR length(v_phone_digits) < 7 THEN
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

  SELECT jsonb_build_object(
    'success', true,
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
    AND o.order_code = btrim(p_order_code)
    AND regexp_replace(coalesce(o.customer_phone, ''), '[^0-9]', '', 'g') = v_phone_digits
  LIMIT 1;

  IF v_result IS NULL THEN
    RETURN jsonb_build_object('success', false, 'msg', 'تعذر العثور على الطلب بهذه البيانات');
  END IF;

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_public_store_order_tracking(text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_store_order_tracking(text, text, text) TO anon, authenticated;
REVOKE ALL ON FUNCTION public.get_public_store_order_tracking(text, text, text) FROM service_role;
