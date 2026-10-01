-- RAWAEA ERP — DirectReturn receive direction contract closure
-- 2026-10-01
--
-- Current Production evidence proved that DirectReturn is a two-stage movement:
-- SEND removes custody stock from the vehicle mobile branch.
-- RECEIVE must therefore add the returned quantity to the destination branch
-- without attempting a second decrement from a NULL source.
--
-- Guarded surgical replacement: fail fast if the canonical function body has
-- drifted and the exact historical fragment is no longer uniquely present.

DO $$
DECLARE
  v_definition text;
  v_old text :=
$frag$      movement:=CASE v.type
        WHEN 'Transfer' THEN 'TransferIn'
        WHEN 'DirectReturn' THEN 'DirectReturn'
      END;$frag$;
  v_new text :=
$frag$      movement:=CASE v.type
        WHEN 'Transfer' THEN 'TransferIn'
        WHEN 'DirectReturn' THEN 'InventoryIncrease'
      END;$frag$;
  v_count integer;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO v_definition
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.prokind='f'
    AND p.proname='post_manual_stock_voucher_atomic_core_20260828'
    AND p.oid::regprocedure::text=
      'post_manual_stock_voucher_atomic_core_20260828(uuid,text,text,text,jsonb,text)';

  IF v_definition IS NULL THEN
    RAISE EXCEPTION 'RAWAEA_DIRECTRETURN_RECEIVE_TARGET_RPC_NOT_FOUND';
  END IF;

  v_count := (
    length(v_definition)-length(replace(v_definition,v_old,''))
  ) / length(v_old);

  IF v_count <> 1 THEN
    RAISE EXCEPTION
      'RAWAEA_DIRECTRETURN_RECEIVE_TARGET_FRAGMENT_DRIFT: count=%',
      v_count;
  END IF;

  v_definition := replace(v_definition,v_old,v_new);
  EXECUTE v_definition;
END $$;

-- Post-migration assertion.
DO $$
DECLARE
  v_definition text;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO v_definition
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.prokind='f'
    AND p.proname='post_manual_stock_voucher_atomic_core_20260828'
    AND p.oid::regprocedure::text=
      'post_manual_stock_voucher_atomic_core_20260828(uuid,text,text,text,jsonb,text)';

  IF v_definition NOT LIKE '%WHEN ''DirectReturn'' THEN ''InventoryIncrease''%' THEN
    RAISE EXCEPTION 'RAWAEA_DIRECTRETURN_RECEIVE_FIX_ASSERTION_FAILED';
  END IF;
END $$;
