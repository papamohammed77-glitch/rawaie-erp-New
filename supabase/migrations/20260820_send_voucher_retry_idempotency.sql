-- RAWAEA ERP — SEND retry idempotency closure
-- A previously successful SEND must return duplicate=true on network retry.

BEGIN;

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
  v public.stock_vouchers%ROWTYPE;
  d record;
  v_source uuid;
  v_target uuid;
  v_voucher_branch_target uuid;
  v_move_type text;
  v_key text;
  v_result jsonb;
  v_count integer:=0;
  expected_count integer:=0;
  existing_count integer:=0;
  payload_conflict boolean:=false;
BEGIN
  SELECT * INTO v FROM public.stock_vouchers WHERE company_id=p_company_id AND voucher_code=p_voucher_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Voucher not found'; END IF;

  SELECT count(*) INTO expected_count
  FROM (
    SELECT svd.item_id, SUM(svd.qty) qty
    FROM public.stock_voucher_details svd
    WHERE svd.voucher_id=v.id AND COALESCE(svd.qty,0)>0
    GROUP BY svd.item_id
  ) q;

  SELECT count(*) INTO existing_count
  FROM public.inventory_log il
  WHERE il.company_id=p_company_id
    AND il.idempotency_key LIKE 'StockVoucherSend:'||p_company_id::text||':'||v.id::text||':%';

  IF v.status<>'Draft' THEN
    SELECT EXISTS(
      SELECT 1
      FROM public.stock_voucher_details svd
      WHERE svd.voucher_id=v.id AND COALESCE(svd.qty,0)>0
        AND NOT EXISTS(
          SELECT 1 FROM public.inventory_log il
          WHERE il.company_id=p_company_id
            AND il.idempotency_key='StockVoucherSend:'||p_company_id::text||':'||v.id::text||':'||svd.item_id::text
            AND il.item_id=svd.item_id
            AND il.qty=svd.qty
            AND il.movement_type=CASE v.type
              WHEN 'Transfer' THEN 'TransferOut'
              WHEN 'DirectSale' THEN 'DirectSale'
              WHEN 'DirectReturn' THEN 'DirectReturn'
              WHEN 'SupplierReturn' THEN 'SupplierReturn'
            END
        )
    ) INTO payload_conflict;

    IF expected_count>0 AND existing_count=expected_count AND NOT payload_conflict THEN
      RETURN jsonb_build_object('success',true,'duplicate',true,'voucher_id',v.id,'voucher_code',p_voucher_code,'status',v.status,'movement_count',existing_count);
    END IF;

    RAISE EXCEPTION 'Voucher is not Draft';
  END IF;

  IF v.type NOT IN ('Transfer','DirectSale','DirectReturn','SupplierReturn') THEN
    RAISE EXCEPTION 'Unsupported send movement type: %',v.type;
  END IF;

  IF v.type='Transfer' THEN
    IF v.from_type<>'Branch' OR v.to_type<>'Branch' OR v.from_id IS NULL OR v.to_id IS NULL THEN RAISE EXCEPTION 'Transfer requires Branch source and Branch target'; END IF;
    v_source:=v.from_id; v_target:=v.to_id; v_move_type:='TransferOut';
  ELSIF v.type='DirectSale' THEN
    IF v.from_type<>'Branch' OR v.to_type<>'Vehicle' OR v.from_id IS NULL OR v.to_id IS NULL THEN RAISE EXCEPTION 'DirectSale requires Branch source and Vehicle target'; END IF;
    SELECT b.id INTO v_voucher_branch_target
    FROM public.branches b JOIN public.vehicles vh ON vh.company_id=b.company_id
    WHERE vh.id=v.to_id AND b.company_id=p_company_id AND b.branch_code='VAN-'||vh.vehicle_code;
    IF v_voucher_branch_target IS NULL THEN RAISE EXCEPTION 'Vehicle stock branch is not initialized'; END IF;
    v_source:=v.from_id; v_target:=v_voucher_branch_target; v_move_type:='DirectSale';
  ELSIF v.type='DirectReturn' THEN
    IF v.from_type<>'Vehicle' OR v.to_type<>'Branch' OR v.from_id IS NULL OR v.to_id IS NULL THEN RAISE EXCEPTION 'DirectReturn requires Vehicle source and Branch target'; END IF;
    SELECT b.id INTO v_source
    FROM public.branches b JOIN public.vehicles vh ON vh.company_id=b.company_id
    WHERE vh.id=v.from_id AND b.company_id=p_company_id AND b.branch_code='VAN-'||vh.vehicle_code;
    IF v_source IS NULL THEN RAISE EXCEPTION 'Vehicle stock branch is not initialized'; END IF;
    v_target:=v.to_id; v_move_type:='DirectReturn';
  ELSE
    IF v.from_type<>'Branch' OR v.from_id IS NULL THEN RAISE EXCEPTION 'SupplierReturn requires Branch source'; END IF;
    v_source:=v.from_id; v_target:=NULL; v_move_type:='SupplierReturn';
  END IF;

  IF NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=v_source AND b.company_id=p_company_id) THEN RAISE EXCEPTION 'Source branch context invalid'; END IF;
  IF v_target IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=v_target AND b.company_id=p_company_id) THEN RAISE EXCEPTION 'Target branch context invalid'; END IF;

  FOR d IN SELECT svd.item_id,svd.item_code,SUM(svd.qty) qty FROM public.stock_voucher_details svd WHERE svd.voucher_id=v.id AND COALESCE(svd.qty,0)>0 GROUP BY svd.item_id,svd.item_code ORDER BY svd.item_id LOOP
    v_key:='StockVoucherSend:'||p_company_id::text||':'||v.id::text||':'||d.item_id::text;
    SELECT public.post_stock_movement(p_company_id,v_move_type,v_source,v_target,d.item_id,d.qty,p_voucher_code,p_voucher_code,p_user_email,v_key) INTO v_result;
    v_count:=v_count+1;
  END LOOP;

  UPDATE public.stock_vouchers
  SET status=CASE WHEN v.type='Transfer' THEN 'Sent' ELSE 'Completed' END,
      sent_date=now(),
      completed_at=CASE WHEN v.type='Transfer' THEN completed_at ELSE now() END,
      completed_by=CASE WHEN v.type='Transfer' THEN completed_by ELSE p_user_email END
  WHERE id=v.id AND company_id=p_company_id AND status='Draft';
  IF NOT FOUND THEN RAISE EXCEPTION 'Failed to update voucher state'; END IF;

  RETURN jsonb_build_object('success',true,'duplicate',false,'voucher_id',v.id,'voucher_code',p_voucher_code,'status',(SELECT status FROM public.stock_vouchers WHERE id=v.id),'movement_count',v_count);
END;
$function$;

REVOKE ALL ON FUNCTION public.send_stock_voucher_atomic(uuid,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.send_stock_voucher_atomic(uuid,text,text) TO service_role;

COMMIT;
