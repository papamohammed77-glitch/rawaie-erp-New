-- Complete the immutable Z-report snapshot with the same cash metrics exposed by X-report.
CREATE OR REPLACE FUNCTION public.pos_close_shift(
  p_shift_id uuid,
  p_counted_cash numeric,
  p_counts jsonb,
  p_operation_id uuid,
  p_discrepancy_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_auth_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_shift public.pos_shifts%ROWTYPE;
  v_expected numeric(14,2);
  v_count_sum numeric(14,2) := 0;
  v_denom numeric(12,2);
  v_qty_numeric numeric;
  v_qty integer;
  v_item jsonb;
  v_fingerprint text;
  v_summary jsonb;
  v_cash_sales numeric(14,2) := 0;
  v_cash_refunds numeric(14,2) := 0;
  v_sale_count integer := 0;
  v_closed_at timestamptz;
BEGIN
  IF v_auth_id IS NULL THEN RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '42501'; END IF;
  IF NOT app_private.current_user_has_permission('pos') THEN RAISE EXCEPTION 'POS_PERMISSION_REQUIRED' USING ERRCODE = '42501'; END IF;
  v_company_id := app_private.current_user_company_id();
  SELECT u.id INTO v_user_id FROM public.users u
  WHERE u.auth_id=v_auth_id AND u.company_id=v_company_id AND COALESCE(u.status,'Active')='Active' LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_USER_PROFILE_REQUIRED' USING ERRCODE = '42501'; END IF;

  IF p_shift_id IS NULL OR p_operation_id IS NULL THEN RAISE EXCEPTION 'SHIFT_CLOSE_IDENTIFIERS_REQUIRED'; END IF;
  IF p_counted_cash IS NULL OR p_counted_cash < 0 OR round(p_counted_cash,2) <> p_counted_cash THEN
    RAISE EXCEPTION 'SHIFT_COUNTED_CASH_INVALID';
  END IF;
  IF p_counts IS NULL OR jsonb_typeof(p_counts) <> 'array' THEN RAISE EXCEPTION 'SHIFT_CASH_COUNTS_MUST_BE_ARRAY'; END IF;

  v_fingerprint := md5(concat_ws('|',p_shift_id,p_counted_cash,p_counts::text,COALESCE(p_discrepancy_reason,'')));

  SELECT * INTO v_shift FROM public.pos_shifts s
  WHERE s.id=p_shift_id AND s.company_id=v_company_id AND s.cashier_user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'SHIFT_NOT_FOUND_OR_NOT_OWNED' USING ERRCODE = '42501'; END IF;

  IF v_shift.status='closed' THEN
    IF v_shift.close_operation_id=p_operation_id AND v_shift.close_fingerprint=v_fingerprint THEN
      RETURN COALESCE(v_shift.close_summary,'{}'::jsonb) || jsonb_build_object('success',true,'duplicate',true);
    END IF;
    RAISE EXCEPTION 'SHIFT_ALREADY_CLOSED';
  END IF;
  IF v_shift.status <> 'open' THEN RAISE EXCEPTION 'SHIFT_NOT_OPEN'; END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_counts) LOOP
    IF jsonb_typeof(v_item) <> 'object' OR NULLIF(v_item->>'denomination','') IS NULL
      OR NULLIF(v_item->>'quantity','') IS NULL THEN RAISE EXCEPTION 'SHIFT_CASH_COUNT_ITEM_INVALID'; END IF;
    v_denom := (v_item->>'denomination')::numeric;
    v_qty_numeric := (v_item->>'quantity')::numeric;
    IF v_denom <= 0 OR round(v_denom,2) <> v_denom OR v_qty_numeric < 0 OR v_qty_numeric <> trunc(v_qty_numeric) THEN
      RAISE EXCEPTION 'SHIFT_CASH_COUNT_VALUE_INVALID';
    END IF;
    v_qty := v_qty_numeric::integer;
    v_count_sum := v_count_sum + v_denom * v_qty;
  END LOOP;

  IF round(v_count_sum,2) <> p_counted_cash THEN
    RAISE EXCEPTION 'SHIFT_DENOMINATION_TOTAL_MISMATCH: expected %, received %', v_count_sum, p_counted_cash;
  END IF;

  v_expected := public.pos_shift_expected_cash(v_shift.id);
  IF v_expected IS NULL THEN RAISE EXCEPTION 'SHIFT_EXPECTED_CASH_UNAVAILABLE'; END IF;
  IF round(p_counted_cash-v_expected,2) <> 0 AND NULLIF(btrim(COALESCE(p_discrepancy_reason,'')),'') IS NULL THEN
    RAISE EXCEPTION 'SHIFT_DISCREPANCY_REASON_REQUIRED';
  END IF;

  SELECT COALESCE(SUM(cb.amount) FILTER (WHERE cb.type='Receipt' AND upper(COALESCE(cb.source_type,''))='POS'),0),
         COALESCE(SUM(cb.amount) FILTER (WHERE cb.type='Payment' AND upper(COALESCE(cb.source_type,''))='POS_RETURN_REFUND'),0)
  INTO v_cash_sales, v_cash_refunds
  FROM public.cash_box cb
  WHERE cb.company_id=v_company_id AND cb.shift_id=v_shift.id
    AND COALESCE(cb.status,'Active') NOT IN ('Voided','Cancelled','Inactive');

  SELECT count(*)::integer INTO v_sale_count
  FROM public.orders o
  WHERE o.company_id=v_company_id AND o.shift_id=v_shift.id
    AND lower(COALESCE(o.source,''))='pos'
    AND o.order_status IN ('Invoiced','Partially Returned');

  INSERT INTO public.pos_shift_cash_counts(company_id,shift_id,denomination,quantity)
  SELECT v_company_id,p_shift_id,(x.value->>'denomination')::numeric,(x.value->>'quantity')::integer
  FROM jsonb_array_elements(p_counts) x;

  v_closed_at := now();
  v_summary := jsonb_build_object(
    'shift_id',v_shift.id,'status','closed','closed_at',v_closed_at,
    'closed_by_user_id',v_user_id,
    'opening_float',v_shift.opening_float,'cash_sales',v_cash_sales,'cash_refunds',v_cash_refunds,
    'sale_count',v_sale_count,'expected_cash',v_expected,
    'counted_cash',p_counted_cash,'cash_difference',round(p_counted_cash-v_expected,2),
    'discrepancy_reason',NULLIF(btrim(COALESCE(p_discrepancy_reason,'')),''),
    'denomination_total',v_count_sum
  );

  UPDATE public.pos_shifts
  SET status='closed',closed_at=v_closed_at,expected_cash=v_expected,counted_cash=p_counted_cash,
      cash_difference=round(p_counted_cash-v_expected,2),
      discrepancy_reason=NULLIF(btrim(COALESCE(p_discrepancy_reason,'')),''),
      close_operation_id=p_operation_id,close_fingerprint=v_fingerprint,
      close_summary=v_summary,updated_at=v_closed_at
  WHERE id=v_shift.id AND company_id=v_company_id;

  INSERT INTO public.pos_shift_events(company_id,shift_id,event_type,operation_id,actor_user_id,payload)
  VALUES (v_company_id,v_shift.id,'closed',p_operation_id,v_user_id,v_summary);

  RETURN v_summary || jsonb_build_object('success',true,'duplicate',false);
END;
$function$;

REVOKE ALL ON FUNCTION public.pos_close_shift(uuid,numeric,jsonb,uuid,text) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.pos_close_shift(uuid,numeric,jsonb,uuid,text) TO authenticated;
