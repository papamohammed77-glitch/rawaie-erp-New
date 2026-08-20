-- RAWAEA ERP — inbound target stock-row initialization closure
-- Incident: Transfer SEND failed with `target stock row missing` when the destination
-- branch had valid master-data context but no stock_branches row for a newly introduced item.
-- Contract: source stock must already exist; inbound target stock state may be initialized at zero.
-- Physical stock mutation remains exclusively inside post_stock_movement.

BEGIN;

CREATE OR REPLACE FUNCTION public.post_stock_movement(
  p_company_id uuid,
  p_movement_type text,
  p_source_branch_id uuid,
  p_target_branch_id uuid,
  p_item_id uuid,
  p_qty numeric,
  p_voucher_id text,
  p_reference text,
  p_user_email text,
  p_idempotency_key text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  s public.stock_branches%ROWTYPE;
  t public.stock_branches%ROWTYPE;
  e public.inventory_log%ROWTYPE;
  bc uuid;
  av numeric;
BEGIN
  IF p_company_id IS NULL OR p_movement_type IS NULL OR p_qty IS NULL OR p_qty <= 0 THEN
    RAISE EXCEPTION 'invalid movement request';
  END IF;

  IF p_movement_type NOT IN (
    'PurchaseIn','TransferOut','TransferIn','DirectSale','DirectReturn',
    'SupplierReturn','POSSale','VanSale','SalesReturn','PurchaseReturn',
    'InventoryIncrease','InventoryDecrease','Loading','Unloading'
  ) THEN
    RAISE EXCEPTION 'movement type is not supported: %', p_movement_type;
  END IF;

  IF p_movement_type IN ('Loading','Unloading')
     AND NULLIF(btrim(p_idempotency_key),'') IS NULL THEN
    RAISE EXCEPTION 'event-level idempotency_key required';
  END IF;

  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO e
    FROM public.inventory_log
    WHERE company_id = p_company_id
      AND idempotency_key = p_idempotency_key
    LIMIT 1;
    IF FOUND THEN
      IF e.movement_type <> p_movement_type OR e.qty <> p_qty THEN
        RAISE EXCEPTION 'idempotency key conflict';
      END IF;
      RETURN jsonb_build_object('success',true,'duplicate',true,'log_code',e.log_code);
    END IF;
  END IF;

  IF p_source_branch_id IS NOT NULL THEN
    SELECT company_id INTO bc FROM public.branches WHERE id = p_source_branch_id;
    IF bc IS NULL OR bc <> p_company_id THEN
      RAISE EXCEPTION 'source branch context invalid';
    END IF;
  END IF;

  IF p_target_branch_id IS NOT NULL THEN
    SELECT company_id INTO bc FROM public.branches WHERE id = p_target_branch_id;
    IF bc IS NULL OR bc <> p_company_id THEN
      RAISE EXCEPTION 'target branch context invalid';
    END IF;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.items WHERE id = p_item_id) THEN
    RAISE EXCEPTION 'item reference invalid';
  END IF;

  -- Source stock is authoritative and must already exist.
  IF p_source_branch_id IS NOT NULL THEN
    PERFORM 1
    FROM public.stock_branches x
    WHERE x.item_id = p_item_id
      AND x.branch_id = p_source_branch_id
    FOR UPDATE;
  END IF;

  -- A target stock row is inventory state, not master-data configuration.
  -- Initialize it at zero atomically on first inbound movement.
  IF p_target_branch_id IS NOT NULL THEN
    INSERT INTO public.stock_branches(
      id, branch_id, item_id, qty, allocated_qty, updated_at
    )
    VALUES(
      gen_random_uuid(), p_target_branch_id, p_item_id, 0, 0, now()
    )
    ON CONFLICT (branch_id, item_id) DO NOTHING;
  END IF;

  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO e
    FROM public.inventory_log
    WHERE company_id = p_company_id
      AND idempotency_key = p_idempotency_key
    LIMIT 1;
    IF FOUND THEN
      IF e.movement_type <> p_movement_type OR e.qty <> p_qty THEN
        RAISE EXCEPTION 'idempotency key conflict';
      END IF;
      RETURN jsonb_build_object('success',true,'duplicate',true,'log_code',e.log_code);
    END IF;
  END IF;

  IF p_source_branch_id IS NOT NULL THEN
    SELECT * INTO s
    FROM public.stock_branches
    WHERE branch_id = p_source_branch_id
      AND item_id = p_item_id
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'source stock row missing';
    END IF;

    av := COALESCE(s.qty,0) - COALESCE(s.allocated_qty,0);
    IF p_movement_type = 'Loading' THEN
      IF COALESCE(s.qty,0) < p_qty OR COALESCE(s.allocated_qty,0) < p_qty THEN
        RAISE EXCEPTION 'insufficient picked reservation';
      END IF;
    ELSIF p_movement_type = 'Unloading' THEN
      IF COALESCE(s.qty,0) < p_qty THEN
        RAISE EXCEPTION 'insufficient source stock';
      END IF;
    ELSIF av < p_qty THEN
      RAISE EXCEPTION 'insufficient available stock';
    END IF;
  END IF;

  IF p_target_branch_id IS NOT NULL THEN
    SELECT * INTO t
    FROM public.stock_branches
    WHERE branch_id = p_target_branch_id
      AND item_id = p_item_id
    FOR UPDATE;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'target stock row initialization failed';
    END IF;
  END IF;

  IF p_source_branch_id IS NOT NULL THEN
    UPDATE public.stock_branches
    SET qty = s.qty - p_qty,
        allocated_qty = CASE WHEN p_movement_type='Loading' THEN s.allocated_qty-p_qty ELSE s.allocated_qty END,
        updated_at = now()
    WHERE id = s.id
      AND qty = s.qty
      AND allocated_qty = s.allocated_qty;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'source stock changed';
    END IF;
  END IF;

  IF p_target_branch_id IS NOT NULL THEN
    UPDATE public.stock_branches
    SET qty = t.qty + p_qty,
        allocated_qty = CASE WHEN p_movement_type='Unloading' THEN t.allocated_qty+p_qty ELSE t.allocated_qty END,
        updated_at = now()
    WHERE id = t.id
      AND qty = t.qty
      AND allocated_qty = t.allocated_qty;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'target stock changed';
    END IF;
  END IF;

  INSERT INTO public.inventory_log(
    company_id,log_code,movement_date,voucher_id,item_id,movement_type,
    qty,reference,user_email,idempotency_key
  )
  VALUES(
    p_company_id,
    'STM-'||replace(gen_random_uuid()::text,'-',''),
    CURRENT_DATE,
    p_voucher_id,
    p_item_id,
    p_movement_type,
    p_qty,
    p_reference,
    p_user_email,
    p_idempotency_key
  );

  RETURN jsonb_build_object('success',true,'duplicate',false,'movement_type',p_movement_type,'qty',p_qty);
END;
$function$;

REVOKE ALL ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)
  TO service_role;

COMMIT;
