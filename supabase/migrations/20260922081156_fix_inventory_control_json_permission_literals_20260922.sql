-- RAWAEA ERP
-- inventory_control JSON permission literal repair
-- Applied to Production migration:
-- 20260922081156_fix_inventory_control_json_permission_literals_20260922
--
-- Root cause: malformed over-escaped JSON text literals inside the deployed
-- inventory_control permission guards caused PostgreSQL 22P02 before any
-- voucher-audit payload was evaluated.
--
-- Surgical contract-preserving fix: construct permission arrays with
-- jsonb_build_array() instead of JSON text literals.

BEGIN;

CREATE OR REPLACE FUNCTION public.inventory_control(
  p_operation text,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
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
  v_operations jsonb := '[]'::jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'غير مصرح';
  END IF;

  SELECT *
    INTO v_actor
  FROM public.users u
  WHERE u.auth_id = auth.uid()
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم الحالي غير مسجل أو غير نشط';
  END IF;

  v_company_id := v_actor.company_id;
  v_email := v_actor.email;

  v_privileged :=
      coalesce(v_actor.permissions,'[]'::jsonb) @> jsonb_build_array('*')
      OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام');

  v_reporting :=
      v_privileged
      OR coalesce(v_actor.permissions,'[]'::jsonb) @> jsonb_build_array('reports');

  v_warehouse :=
      v_privileged
      OR coalesce(v_actor.permissions,'[]'::jsonb) @> jsonb_build_array('warehouse')
      OR coalesce(v_actor.permissions,'[]'::jsonb) @> jsonb_build_array('warehouse_manager')
      OR coalesce(v_actor.permissions,'[]'::jsonb) @> jsonb_build_array('warehouse_supervisor');

  v_voucher_access :=
      v_warehouse
      OR v_reporting
      OR coalesce(v_actor.active_warehouse_role,'')='أذونات';

  IF v_op IN ('SNAPSHOT','MOVEMENTS','REPLENISHMENT') THEN
    IF NOT (v_reporting OR v_warehouse) THEN
      RAISE EXCEPTION 'غير مصرح بقراءة مركز التحكم في المخزون';
    END IF;

    IF v_op='SNAPSHOT' THEN
      SELECT public.inventory_stock_snapshot(
        v_company_id,
        v_email,
        nullif(p_payload->>'branch_id','')::uuid,
        nullif(p_payload->>'query',''),
        coalesce((p_payload->>'low_only')::boolean,false),
        greatest(coalesce((p_payload->>'limit')::integer,100),1),
        greatest(coalesce((p_payload->>'offset')::integer,0),0)
      ) INTO v_result;

    ELSIF v_op='MOVEMENTS' THEN
      SELECT public.inventory_movement_report(
        v_company_id,
        v_email,
        nullif(p_payload->>'from_date','')::date,
        nullif(p_payload->>'to_date','')::date,
        nullif(p_payload->>'branch_id','')::uuid,
        nullif(p_payload->>'item_id','')::uuid,
        nullif(p_payload->>'movement_type',''),
        nullif(p_payload->>'query',''),
        greatest(coalesce((p_payload->>'limit')::integer,100),1),
        greatest(coalesce((p_payload->>'offset')::integer,0),0)
      ) INTO v_result;

    ELSE
      SELECT public.inventory_replenishment_report(
        v_company_id,
        v_email,
        nullif(p_payload->>'branch_id','')::uuid,
        greatest(coalesce((p_payload->>'limit')::integer,100),1),
        greatest(coalesce((p_payload->>'offset')::integer,0),0)
      ) INTO v_result;
    END IF;

    RETURN coalesce(
      v_result,
      jsonb_build_object('success',true,'rows','[]'::jsonb)
    );
  END IF;

  IF v_op='COUNT' THEN
    v_subop := upper(btrim(coalesce(p_payload->>'operation','GET')));

    IF v_subop IN ('GET','LIST') THEN
      IF NOT v_reporting AND NOT v_warehouse THEN
        RAISE EXCEPTION 'غير مصرح بقراءة الجرد';
      END IF;
    ELSIF NOT v_warehouse THEN
      RAISE EXCEPTION 'غير مصرح بإدارة الجرد';
    END IF;

    v_operation_id := nullif(btrim(coalesce(p_payload->>'operation_id','')),'');

    SELECT public.inventory_count_engine(
      v_company_id,
      v_email,
      v_subop,
      coalesce(p_payload->'payload','{}'::jsonb),
      v_operation_id
    ) INTO v_result;

    RETURN v_result;
  END IF;

  IF v_op='REQUEST' THEN
    v_subop := upper(btrim(coalesce(p_payload->>'operation','GET')));

    IF v_subop='GET' THEN
      IF NOT v_reporting
         AND NOT v_warehouse
         AND NOT (coalesce(v_actor.permissions,'[]'::jsonb) @> jsonb_build_array('transfer'))
      THEN
        RAISE EXCEPTION 'غير مصرح بقراءة طلبات المخزون';
      END IF;
    ELSIF NOT v_warehouse THEN
      RAISE EXCEPTION 'غير مصرح بإدارة طلبات المخزون';
    END IF;

    v_operation_id := nullif(btrim(coalesce(p_payload->>'operation_id','')),'');

    SELECT public.inventory_stock_request_engine(
      v_company_id,
      v_email,
      v_subop,
      coalesce(p_payload->'payload','{}'::jsonb),
      v_operation_id
    ) INTO v_result;

    RETURN v_result;
  END IF;

  IF v_op='VOUCHER_AUDIT' THEN
    IF NOT v_voucher_access THEN
      RAISE EXCEPTION 'غير مصرح بقراءة تفاصيل الأذونات المخزنية';
    END IF;

    v_voucher_code := nullif(btrim(coalesce(p_payload->>'voucher_code','')),'');

    IF v_voucher_code IS NULL THEN
      RAISE EXCEPTION 'رقم الإذن مطلوب';
    END IF;

    SELECT *
      INTO v_voucher
    FROM public.stock_vouchers v
    WHERE v.company_id=v_company_id
      AND v.voucher_code=v_voucher_code
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'الإذن غير موجود';
    END IF;

    SELECT coalesce(
      jsonb_agg(to_jsonb(d) ORDER BY d.item_code),
      '[]'::jsonb
    )
    INTO v_details
    FROM public.stock_voucher_details d
    WHERE d.voucher_id=v_voucher.id;

    SELECT coalesce(
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
        )
        ORDER BY a.created_at DESC
      ),
      '[]'::jsonb
    )
    INTO v_audit
    FROM public.audit_log a
    WHERE a.table_name='stock_vouchers'
      AND a.record_id=v_voucher.id::text
      AND (a.company_id IS NULL OR a.company_id=v_company_id);

    SELECT coalesce(
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
        )
        ORDER BY il.created_at ASC,il.id ASC
      ),
      '[]'::jsonb
    )
    INTO v_movements
    FROM public.inventory_log il
    WHERE il.company_id=v_company_id
      AND il.voucher_id=v_voucher_code;

    SELECT coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id',o.id,
          'operation_id',o.operation_id,
          'fingerprint',o.fingerprint,
          'voucher_id',o.voucher_id,
          'created_at',o.created_at
        )
        ORDER BY o.created_at ASC,o.id asc
      ),
      '[]'::jsonb
    )
    INTO v_operations
    FROM public.stock_voucher_operations o
    WHERE o.company_id=v_company_id
      AND o.voucher_id=v_voucher.id;

    RETURN jsonb_build_object(
      'success',true,
      'voucher',to_jsonb(v_voucher),
      'details',v_details,
      'audit',v_audit,
      'movements',v_movements,
      'operations',v_operations
    );
  END IF;

  RAISE EXCEPTION 'عملية مركز التحكم غير مدعومة: %', v_op;
END;
$function$;

REVOKE ALL ON FUNCTION public.inventory_control(text,jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.inventory_control(text,jsonb) TO authenticated, service_role;

COMMIT;
