-- RAWAEA ERP — Inventory Voucher Stock Context
-- Read-only authenticated RPC for voucher movement stock-before/after visibility.
-- Physical Stock writer remains post_stock_movement; this function never mutates stock.

BEGIN;

CREATE OR REPLACE FUNCTION public.inventory_voucher_stock_context(
  p_voucher_code text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_voucher public.stock_vouchers%ROWTYPE;
  v_company_id uuid;
  v_rows jsonb := '[]'::jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'غير مصرح';
  END IF;

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.auth_id=auth.uid()
    AND coalesce(u.status,'Active')='Active'
  ORDER BY u.id
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم الحالي غير صالح';
  END IF;

  v_company_id:=v_actor.company_id;

  SELECT * INTO v_voucher
  FROM public.stock_vouchers v
  WHERE v.company_id=v_company_id
    AND v.voucher_code=btrim(p_voucher_code)
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الإذن غير موجود';
  END IF;

  WITH moves AS (
    SELECT
      il.id,
      il.created_at,
      il.item_id,
      il.item_code,
      il.item_name,
      il.movement_type,
      il.qty,
      il.source_branch_id,
      il.target_branch_id,
      il.idempotency_key,
      il.user_email
    FROM public.inventory_log il
    WHERE il.company_id=v_company_id
      AND il.voucher_id=v_voucher.voucher_code
  ),
  events AS (
    SELECT
      il.id AS movement_id,
      il.created_at,
      il.item_id,
      e.branch_id,
      e.delta
    FROM public.inventory_log il
    CROSS JOIN LATERAL (
      VALUES
        (il.source_branch_id,-il.qty),
        (il.target_branch_id, il.qty)
    ) e(branch_id,delta)
    WHERE il.company_id=v_company_id
      AND e.branch_id IS NOT NULL
  ),
  current_stock AS (
    SELECT sb.branch_id,sb.item_id,sb.qty
    FROM public.stock_branches sb
    JOIN (
      SELECT DISTINCT item_id,branch_id
      FROM events
    ) x
      ON x.item_id=sb.item_id
     AND x.branch_id=sb.branch_id
  )
  SELECT coalesce(
    jsonb_agg(to_jsonb(x) ORDER BY x.created_at,x.id),
    '[]'::jsonb
  )
  INTO v_rows
  FROM (
    SELECT
      m.id,
      m.item_id,
      m.item_code,
      m.item_name,
      m.movement_type,
      m.qty,
      m.source_branch_id,
      m.target_branch_id,
      m.idempotency_key,
      m.user_email,
      m.created_at,
      src.qty_before AS source_stock_before,
      CASE
        WHEN m.source_branch_id IS NOT NULL
        THEN src.qty_before-m.qty
        ELSE NULL
      END AS source_stock_after,
      tgt.qty_before AS target_stock_before,
      CASE
        WHEN m.target_branch_id IS NOT NULL
        THEN tgt.qty_before+m.qty
        ELSE NULL
      END AS target_stock_after,
      CASE
        WHEN (m.source_branch_id IS NOT NULL AND src.qty_before IS NULL)
          OR (m.target_branch_id IS NOT NULL AND tgt.qty_before IS NULL)
        THEN false
        ELSE true
      END AS reconstruction_complete
    FROM moves m
    LEFT JOIN LATERAL (
      SELECT
        cs.branch_id,
        cs.qty-coalesce((
          SELECT sum(ev.delta)
          FROM events ev
          WHERE ev.item_id=m.item_id
            AND ev.branch_id=m.source_branch_id
            AND (
              ev.created_at>m.created_at
              OR (
                ev.created_at=m.created_at
                AND ev.movement_id>=m.id
              )
            )
        ),0) AS qty_before
      FROM current_stock cs
      WHERE cs.branch_id=m.source_branch_id
        AND cs.item_id=m.item_id
    ) src ON true
    LEFT JOIN LATERAL (
      SELECT
        cs.branch_id,
        cs.qty-coalesce((
          SELECT sum(ev.delta)
          FROM events ev
          WHERE ev.item_id=m.item_id
            AND ev.branch_id=m.target_branch_id
            AND (
              ev.created_at>m.created_at
              OR (
                ev.created_at=m.created_at
                AND ev.movement_id>=m.id
              )
            )
        ),0) AS qty_before
      FROM current_stock cs
      WHERE cs.branch_id=m.target_branch_id
        AND cs.item_id=m.item_id
    ) tgt ON true
  ) x;

  RETURN jsonb_build_object(
    'success',true,
    'voucher_code',v_voucher.voucher_code,
    'movement_count',jsonb_array_length(v_rows),
    'movements',v_rows,
    'basis','current_stock_reconciled_against_all_inventory_log_events'
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.inventory_voucher_stock_context(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.inventory_voucher_stock_context(text) TO authenticated;

COMMIT;
