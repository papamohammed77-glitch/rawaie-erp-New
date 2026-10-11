-- Reject zero-value POS return operations before any success/credit-note result.
DO $patch$
DECLARE
  v_def text;
  v_anchor text := ' if p_order_code is not null and v_total_value>0 then';
  v_replacement text := ' if p_is_pos_return and p_order_code is not null and v_total_value<=0 then raise exception ''POS_RETURN_NO_RETURNABLE_VALUE''; end if;'||E'\n'||' if p_order_code is not null and v_total_value>0 then';
BEGIN
  SELECT pg_get_functiondef('public.complete_return_atomic(uuid,text,text,boolean,text,jsonb)'::regprocedure)
    INTO v_def;
  IF position(v_anchor in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_ZERO_VALUE_GUARD_ABORTED: anchor mismatch';
  END IF;
  v_def := replace(v_def,v_anchor,v_replacement);
  EXECUTE v_def;
END
$patch$;

REVOKE ALL ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) TO service_role;
