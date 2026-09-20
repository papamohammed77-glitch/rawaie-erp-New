-- RAWAEA ERP — voucher audit capability for authenticated warehouse consumers
-- Date: 2026-09-20
-- Purpose: expose voucher details, audit trail and physical movement evidence
-- through the existing authenticated inventory_control RPC.
-- No new Edge Function. No RLS relaxation. Physical movement remains post_stock_movement.

CREATE OR REPLACE FUNCTION public.inventory_control(
  p_operation text,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
declare
  v_actor public.users%rowtype;
  v_op text := upper(btrim(coalesce(p_operation,'')));
  v_company_id uuid;
  v_email text;
  v_privileged boolean := false;
  v_reporting boolean := false;
  v_warehouse boolean := false;
  v_voucher_access boolean := false;
  v_subop text;
  v_operation_id text;
  v_result jsonb;
  v_voucher public.stock_vouchers%rowtype;
  v_voucher_code text;
  v_details jsonb := '[]'::jsonb;
  v_audit jsonb := '[]'::jsonb;
  v_movements jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then raise exception 'غير مصرح'; end if;

  select * into v_actor
  from public.users u
  where u.auth_id = auth.uid()
    and coalesce(u.status,'Active')='Active'
  limit 1;

  if not found then raise exception 'المستخدم الحالي غير مسجل أو غير نشط'; end if;

  v_company_id := v_actor.company_id;
  v_email := v_actor.email;
  v_privileged := coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
                  or v_actor.role in ('مدير مخازن','مشرف مخازن','مدير عام');
  v_reporting := v_privileged
                 or coalesce(v_actor.permissions,'[]'::jsonb) @> '["reports"]'::jsonb;
  v_warehouse := v_privileged
                 or coalesce(v_actor.permissions,'[]'::jsonb) @> '["warehouse"]'::jsonb
                 or coalesce(v_actor.permissions,'[]'::jsonb) @> '["warehouse_manager"]'::jsonb
                 or coalesce(v_actor.permissions,'[]'::jsonb) @> '["warehouse_supervisor"]'::jsonb;
  v_voucher_access := v_warehouse
                      or v_reporting
                      or coalesce(v_actor.active_warehouse_role,'')='أذونات';

  if v_op in ('SNAPSHOT','MOVEMENTS','REPLENISHMENT') then
    if not (v_reporting or v_warehouse) then raise exception 'غير مصرح بقراءة مركز التحكم في المخزون'; end if;
    if v_op='SNAPSHOT' then
      select public.inventory_stock_snapshot(
        v_company_id,v_email,
        nullif(p_payload->>'branch_id','')::uuid,
        nullif(p_payload->>'query',''),
        coalesce((p_payload->>'low_only')::boolean,false),
        greatest(coalesce((p_payload->>'limit')::integer,100),1),
        greatest(coalesce((p_payload->>'offset')::integer,0),0)
      ) into v_result;
    elsif v_op='MOVEMENTS' then
      select public.inventory_movement_report(
        v_company_id,v_email,
        nullif(p_payload->>'from_date','')::date,
        nullif(p_payload->>'to_date','')::date,
        nullif(p_payload->>'branch_id','')::uuid,
        nullif(p_payload->>'item_id','')::uuid,
        nullif(p_payload->>'movement_type',''),
        nullif(p_payload->>'query',''),
        greatest(coalesce((p_payload->>'limit')::integer,100),1),
        greatest(coalesce((p_payload->>'offset')::integer,0),0)
      ) into v_result;
    else
      select public.inventory_replenishment_report(
        v_company_id,v_email,
        nullif(p_payload->>'branch_id','')::uuid,
        greatest(coalesce((p_payload->>'limit')::integer,100),1),
        greatest(coalesce((p_payload->>'offset')::integer,0),0)
      ) into v_result;
    end if;
    return coalesce(v_result,'{"success":true,"rows":[]}'::jsonb);
  end if;

  if v_op='COUNT' then
    v_subop := upper(btrim(coalesce(p_payload->>'operation','GET')));
    if v_subop in ('GET','LIST') then
      if not v_reporting and not v_warehouse then raise exception 'غير مصرح بقراءة الجرد'; end if;
    elsif not v_warehouse then
      raise exception 'غير مصرح بإدارة الجرد';
    end if;
    v_operation_id := nullif(btrim(coalesce(p_payload->>'operation_id','')),'');
    select public.inventory_count_engine(
      v_company_id,v_email,v_subop,
      coalesce(p_payload->'payload','{}'::jsonb),
      v_operation_id
    ) into v_result;
    return v_result;
  end if;

  if v_op='REQUEST' then
    v_subop := upper(btrim(coalesce(p_payload->>'operation','GET')));
    if v_subop='GET' then
      if not v_reporting and not v_warehouse and not (coalesce(v_actor.permissions,'[]'::jsonb) @> '["transfer"]'::jsonb) then
        raise exception 'غير مصرح بقراءة طلبات المخزون';
      end if;
    elsif not v_warehouse then
      raise exception 'غير مصرح بإدارة طلبات المخزون';
    end if;
    v_operation_id := nullif(btrim(coalesce(p_payload->>'operation_id','')),'');
    select public.inventory_stock_request_engine(
      v_company_id,v_email,v_subop,
      coalesce(p_payload->'payload','{}'::jsonb),
      v_operation_id
    ) into v_result;
    return v_result;
  end if;

  if v_op='VOUCHER_AUDIT' then
    if not v_voucher_access then
      raise exception 'غير مصرح بقراءة تفاصيل الأذونات المخزنية';
    end if;

    v_voucher_code := nullif(btrim(coalesce(p_payload->>'voucher_code','')),'');
    if v_voucher_code is null then raise exception 'رقم الإذن مطلوب'; end if;

    select * into v_voucher
    from public.stock_vouchers v
    where v.company_id=v_company_id
      and v.voucher_code=v_voucher_code
    limit 1;

    if not found then raise exception 'الإذن غير موجود'; end if;

    select coalesce(jsonb_agg(to_jsonb(d) order by d.item_code),'[]'::jsonb)
      into v_details
    from public.stock_voucher_details d
    where d.voucher_id=v_voucher.id;

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'action',a.action,
          'table_name',a.table_name,
          'record_id',a.record_id,
          'user_email',a.user_email,
          'company_id',a.company_id,
          'actor_user_id',a.actor_user_id,
          'source_type',a.source_type,
          'operation_id',a.operation_id,
          'created_at',a.created_at
        ) order by a.created_at desc
      ),'[]'::jsonb
    ) into v_audit
    from public.audit_log a
    where a.table_name='stock_vouchers'
      and a.record_id=v_voucher.id::text
      and (a.company_id is null or a.company_id=v_company_id);

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id',il.id,
          'movement_type',il.movement_type,
          'qty',il.qty,
          'item_id',il.item_id,
          'item_code',il.item_code,
          'item_name',il.item_name,
          'voucher_id',il.voucher_id,
          'reference',il.reference,
          'user_email',il.user_email,
          'source_branch_id',il.source_branch_id,
          'target_branch_id',il.target_branch_id,
          'idempotency_key',il.idempotency_key,
          'created_at',il.created_at
        ) order by il.created_at asc,il.id asc
      ),'[]'::jsonb
    ) into v_movements
    from public.inventory_log il
    where il.company_id=v_company_id
      and il.voucher_id=v_voucher_code;

    return jsonb_build_object(
      'success',true,
      'voucher',to_jsonb(v_voucher),
      'details',v_details,
      'audit',v_audit,
      'movements',v_movements
    );
  end if;

  raise exception 'عملية مركز التحكم غير مدعومة: %', v_op;
end;
$function$;

REVOKE ALL ON FUNCTION public.inventory_control(text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.inventory_control(text,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.inventory_control(text,jsonb) TO service_role;
