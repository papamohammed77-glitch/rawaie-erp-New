/*
 * SOURCE RECONCILIATION
 * Applied in Production as:
 * 20260928120431_harden_transfer_partial_receive_actor_20260928
 *
 * This file is added to keep CURRENT GIT reproducible with CURRENT DATABASE.
 * The migration is idempotent relative to the guard it introduces.
 */
DO $RW$
DECLARE
  v_def text;
  v_old text := $OLD$
  if p_operation='RECEIVE' and v_voucher.type='Transfer' then
    if v_voucher.receiver_user_id is null
       or v_actor.id is distinct from v_voucher.receiver_user_id then
      raise exception 'لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع';
    end if;
  end if;
$OLD$;
  v_new text := $NEW$
  if p_operation='RECEIVE' and v_voucher.type='Transfer' then
    if v_voucher.receiver_user_id is null
       or v_actor.id is distinct from v_voucher.receiver_user_id then
      raise exception 'لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع';
    end if;
  end if;
$NEW$;
BEGIN
  SELECT pg_get_functiondef(
    'public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb,text)'::regprocedure
  )
  INTO v_def;

  IF position(v_old in v_def)>0 THEN
    RETURN;
  END IF;

  v_def := replace(
    v_def,
    '  v_result:=public.post_manual_stock_voucher_atomic_core_20260828(',
    v_new || E'\n\n  v_result:=public.post_manual_stock_voucher_atomic_core_20260828('
  );

  EXECUTE v_def;
END
$RW$;
