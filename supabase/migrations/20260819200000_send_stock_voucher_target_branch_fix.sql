-- RAWAEA ERP — SEND stock voucher target-branch correction
-- Scope: Transfer + DirectSale must post MAIN/branch -> target branch.
-- SupplierReturn remains source-only.
-- This aligns send_stock_voucher_atomic with the proven custody contract.

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_voucher public.stock_vouchers%ROWTYPE;
  d record;
  v_main uuid;
  v_source uuid;
  v_target uuid;
  m text;
  move_count integer := 0;
  key text;
  r jsonb;
  expected_count integer := 0;
  existing_count integer := 0;
BEGIN
  SELECT * INTO v_voucher
  FROM public.stock_vouchers
  WHERE company_id = p_company_id
    AND voucher_code = p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Voucher not found';
  END IF;

  SELECT count(*) INTO expected_count
  FROM (
    SELECT svd.item_id, svd.item_code
    FROM public.stock_voucher_details svd
    WHERE svd.voucher_id = v_voucher.id
      AND COALESCE(svd.qty, 0) > 0
    GROUP BY svd.item_id, svd.item_code
  ) item_groups;

  SELECT count(*) INTO existing_count
  FROM public.inventory_log il
  WHERE il.company_id = p_company_id
    AND il.idempotency_key LIKE 'StockVoucherSend:' || p_company_id::text || ':' || v_voucher.id::text || ':%';

  IF expected_count > 0 AND existing_count = expected_count THEN
    RETURN jsonb_build_object(
      'success', true,
      'duplicate', true,
      'voucher_id', v_voucher.id,
      'voucher_code', p_voucher_code,
      'status', v_voucher.status,
      'movement_count', existing_count
    );
  END IF;

  IF v_voucher.status <> 'Draft' THEN
    RAISE EXCEPTION 'Voucher is not Draft';
  END IF;

  IF v_voucher.type NOT IN ('Transfer', 'DirectSale', 'SupplierReturn') THEN
    RAISE EXCEPTION 'Unsupported send movement type: %', v_voucher.type;
  END IF;

  SELECT main_branch_id INTO STRICT v_main
  FROM public.app_settings
  WHERE company_id = p_company_id
  ORDER BY created_at ASC, id
  LIMIT 1;

  v_source := COALESCE(v_voucher.from_id, v_main);

  IF NOT EXISTS (
    SELECT 1
    FROM public.branches b
    WHERE b.id = v_source
      AND b.company_id = p_company_id
  ) THEN
    RAISE EXCEPTION 'Source branch context invalid';
  END IF;

  v_target := CASE
    WHEN v_voucher.type IN ('Transfer', 'DirectSale') THEN v_voucher.to_id
    ELSE NULL
  END;

  IF v_voucher.type IN ('Transfer', 'DirectSale') THEN
    IF v_target IS NULL THEN
      RAISE EXCEPTION 'Target branch is required for voucher type %', v_voucher.type;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.branches b
      WHERE b.id = v_target
        AND b.company_id = p_company_id
    ) THEN
      RAISE EXCEPTION 'Target branch context invalid';
    END IF;

    IF v_target = v_source THEN
      RAISE EXCEPTION 'Source and target branches must differ';
    END IF;
  END IF;

  m := CASE v_voucher.type
    WHEN 'Transfer' THEN 'TransferOut'
    WHEN 'DirectSale' THEN 'DirectSale'
    WHEN 'SupplierReturn' THEN 'SupplierReturn'
  END;

  FOR d IN
    SELECT svd.item_id, svd.item_code, SUM(svd.qty) qty
    FROM public.stock_voucher_details svd
    WHERE svd.voucher_id = v_voucher.id
    GROUP BY svd.item_id, svd.item_code
    ORDER BY svd.item_id
  LOOP
    IF COALESCE(d.qty, 0) <= 0 THEN
      CONTINUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.items i
      WHERE i.id = d.item_id
        AND i.item_code = d.item_code
    ) THEN
      RAISE EXCEPTION 'Item identity invalid: %', d.item_code;
    END IF;

    key := 'StockVoucherSend:' || p_company_id::text || ':' || v_voucher.id::text || ':' || d.item_id::text;

    SELECT public.post_stock_movement(
      p_company_id,
      m,
      v_source,
      v_target,
      d.item_id,
      d.qty,
      p_voucher_code,
      p_voucher_code,
      p_user_email,
      key
    ) INTO r;

    move_count := move_count + 1;
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
    'status', 'Sent',
    'movement_count', move_count,
    'source_branch_id', v_source,
    'target_branch_id', v_target
  );
END;
$function$;
