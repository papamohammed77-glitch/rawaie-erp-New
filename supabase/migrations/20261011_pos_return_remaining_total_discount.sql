-- Keep the remaining POS invoice total net of the original order-level discount.
DO $patch$
DECLARE
  v_def text;
  v_anchor text := 'v_order_new_status:=case when v_order_total_original>0 and v_order_total_returned>=v_order_total_original then ''Returned'' else ''Partially Returned'' end;';
  v_replacement text := 'IF p_is_pos_return AND lower(coalesce(v_order.source, ''''))=''pos'' AND v_pos_gross_total>0 THEN v_order_new_total:=round(greatest(0,v_order_new_total-coalesce(v_order.discount_amount,0)*v_order_new_total/v_pos_gross_total),2); END IF;'||E'\n'||v_anchor;
BEGIN
  SELECT pg_get_functiondef('public.complete_return_atomic(uuid,text,text,boolean,text,jsonb)'::regprocedure)
    INTO v_def;
  IF position(v_anchor in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_REMAINING_TOTAL_PATCH_ABORTED: anchor mismatch';
  END IF;
  v_def := replace(v_def,v_anchor,v_replacement);
  EXECUTE v_def;
END
$patch$;

REVOKE ALL ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) TO service_role;
