BEGIN;

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_voucher public.stock_vouchers%ROWTYPE;
  v_detail record;
  v_item_id uuid;
  v_source_branch uuid;
  v_movement_type text;
  v_reference text;
  v_idempotency_key text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.app_settings s WHERE s.company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'company context is not valid';
  END IF;

  SELECT * INTO v_voucher
  FROM public.stock_vouchers
  WHERE company_id = p_company_id
    AND voucher_code = p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Voucher not found';
  END IF;

  IF v_voucher.status <> 'Draft' THEN
    RAISE EXCEPTION 'Voucher is not Draft';
  END IF;

  v_source_branch := v_voucher.from_id;
  IF v_source_branch IS NULL THEN
    SELECT main_branch_id INTO STRICT v_source_branch
    FROM public.app_settings
    WHERE company_id = p_company_id;
  END IF;

  IF v_voucher.type NOT IN ('Transfer','DirectSale','SupplierReturn') THEN
    UPDATE public.stock_vouchers
    SET status = 'Sent', sent_date = now()
    WHERE id = v_voucher.id
      AND company_id = p_company_id
      AND status = 'Draft';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Failed to update voucher state';
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'voucher_id', v_voucher.id,
      'voucher_code', p_voucher_code,
      'movement_count', 0,
      'status', 'Sent'
    );
  END IF;

  v_movement_type := CASE v_voucher.type
    WHEN 'SupplierReturn' THEN 'SupplierReturn'
    ELSE 'TransferOut'
  END;

  FOR v_detail IN
    SELECT d.item_id, d.item_code, d.qty
    FROM public.stock_voucher_details d
    WHERE d.voucher_id = v_voucher.id
    ORDER BY d.id
  LOOP
    IF COALESCE(v_detail.qty, 0) <= 0 THEN
      CONTINUE;
    END IF;

    SELECT i.id INTO v_item_id
    FROM public.items i
    WHERE i.company_id = p_company_id
      AND (i.id = v_detail.item_id OR i.item_code = v_detail.item_code)
    ORDER BY (i.id = v_detail.item_id) DESC, i.id
    LIMIT 1;

    IF v_item_id IS NULL THEN
      RAISE EXCEPTION 'Item not found in company: %', v_detail.item_code;
    END IF;

    v_reference := 'StockVoucher:' || v_voucher.type || ':' || p_voucher_code;
    v_idempotency_key := 'StockVoucherSend:' || p_company_id::text || ':' || v_voucher.id::text || ':' || v_item_id::text;

    PERFORM public.post_stock_movement(
      p_company_id,
      v_movement_type,
      v_source_branch,
      NULL,
      v_item_id,
      v_detail.qty,
      p_voucher_code,
      v_reference,
      p_user_email,
      v_idempotency_key
    );
  END LOOP;

  UPDATE public.stock_vouchers
  SET status = 'Sent',
      sent_date = now()
  WHERE id = v_voucher.id
    AND company_id = p_company_id
    AND status = 'Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Failed to update voucher state';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'voucher_id', v_voucher.id,
    'voucher_code', p_voucher_code,
    'movement_count', (
      SELECT count(*)
      FROM public.stock_voucher_details d
      WHERE d.voucher_id = v_voucher.id
        AND COALESCE(d.qty, 0) > 0
    ),
    'status', 'Sent'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.send_stock_voucher_atomic(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_stock_voucher_atomic(uuid,text,text) TO service_role;

COMMIT;
