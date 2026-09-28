/*
 * Harden DirectReturn receiving in the existing central RPC.
 * No new Edge Function.
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
  v_add text := $ADD$
  if p_operation='RECEIVE' and v_voucher.type='DirectReturn' then
    if not (
      coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
      or v_actor.role in ('مدير النظام','مدير عام','مدير مخازن','مشرف مخازن')
    ) then
      if v_actor.role<>'مخزني'
         or coalesce(v_actor.active_warehouse_role,'')<>'أذونات' then
        raise exception 'لا يملك هذا المستخدم صلاحية استلام المرتجع المباشر';
      end if;

      if v_voucher.to_type<>'Branch'
         or v_voucher.to_id is null then
        raise exception 'وجهة المرتجع المباشر غير صالحة';
      end if;

      if not exists (
        select 1
        from public.branches b
        where b.id=v_voucher.to_id
          and b.company_id=p_company_id
          and b.is_active=true
          and (
            v_actor.default_branch_id=b.id
            or v_actor.allowed_branch_ids is null
            or v_actor.allowed_branch_ids='[]'::jsonb
            or coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
            or (
              jsonb_typeof(v_actor.allowed_branch_ids)='array'
              and (
                v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
                or v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              )
            )
            or (
              jsonb_typeof(v_actor.allowed_branch_ids)='string'
              and trim(both '"' from v_actor.allowed_branch_ids::text)
                  in (b.id::text,b.branch_code,'*')
            )
          )
      ) then
        raise exception 'فرع المرتجع المباشر خارج نطاق مسؤول المستخدم';
      end if;
    end if;
  end if;
$ADD$;
BEGIN
  SELECT pg_get_functiondef(
    'public.post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb,text)'::regprocedure
  )
  INTO v_def;

  IF position(v_old in v_def)=0 THEN
    RAISE EXCEPTION 'EXPECTED TRANSFER RECEIVE GUARD NOT FOUND';
  END IF;

  IF position('p_operation=''RECEIVE'' and v_voucher.type=''DirectReturn''' in v_def)>0 THEN
    RAISE NOTICE 'DirectReturn receive guard already present; no change required';
    RETURN;
  END IF;

  EXECUTE replace(
    v_def,
    v_old,
    v_old || E'\n' || v_add
  );
END
$RW$;
