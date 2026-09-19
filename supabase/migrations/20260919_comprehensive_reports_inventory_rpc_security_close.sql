-- RAWAEA ERP — Comprehensive Reports inventory RPC security closure
-- Applied to Production before source-surgery documentation.
-- Preserve existing signatures/result contracts.
-- Close authenticated tenant/permission gap for inventory movement/replenishment reporting.

BEGIN;

CREATE OR REPLACE FUNCTION public.inventory_movement_report(
  p_company_id uuid,
  p_user_email text DEFAULT NULL::text,
  p_from_date date DEFAULT NULL::date,
  p_to_date date DEFAULT NULL::date,
  p_branch_id uuid DEFAULT NULL::uuid,
  p_item_id uuid DEFAULT NULL::uuid,
  p_movement_type text DEFAULT NULL::text,
  p_query text DEFAULT NULL::text,
  p_limit integer DEFAULT 200,
  p_offset integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_limit integer := LEAST(GREATEST(COALESCE(p_limit,200),1),1000);
  v_offset integer := GREATEST(COALESCE(p_offset,0),0);
  v_rows jsonb;
  v_count bigint;
  v_role text := COALESCE(current_setting('request.jwt.claim.role', true),'');
  v_context_company uuid := app_private.current_user_company_id();
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.companies c
    WHERE c.id=p_company_id AND COALESCE(c.is_active,true)
  ) THEN
    RAISE EXCEPTION 'سياق الشركة غير موجود أو غير نشط';
  END IF;

  IF v_role <> 'service_role' THEN
    IF v_context_company IS NULL OR v_context_company <> p_company_id THEN
      RAISE EXCEPTION 'سياق الشركة غير صالح للجلسة الحالية';
    END IF;

    IF NOT app_private.current_user_has_permission('reports') THEN
      RAISE EXCEPTION 'REPORTS_PERMISSION_REQUIRED';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id=auth.uid()
        AND u.company_id=p_company_id
        AND COALESCE(u.status,'Active')='Active'
        AND (p_user_email IS NULL OR lower(u.email)=lower(p_user_email))
    ) THEN
      RAISE EXCEPTION 'المستخدم لا ينتمي إلى الشركة أو البريد لا يطابق الجلسة';
    END IF;
  ELSIF p_user_email IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.company_id=p_company_id
      AND lower(u.email)=lower(p_user_email)
      AND COALESCE(u.status,'Active')='Active'
  ) THEN
    RAISE EXCEPTION 'المستخدم لا ينتمي إلى الشركة';
  END IF;

  IF p_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id=p_branch_id AND b.company_id=p_company_id
  ) THEN
    RAISE EXCEPTION 'الفرع لا ينتمي إلى الشركة';
  END IF;

  IF p_item_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.items i WHERE i.id=p_item_id
  ) THEN
    RAISE EXCEPTION 'الصنف غير موجود';
  END IF;

  WITH base AS (
    SELECT il.id AS event_id,il.created_at,il.movement_date,il.company_id,
           il.voucher_id,il.reference,il.item_id,il.item_code,il.item_name,
           il.movement_type,il.qty,il.user_email,il.source_branch_id,il.target_branch_id
    FROM public.inventory_log il
    WHERE il.company_id=p_company_id
      AND (p_item_id IS NULL OR il.item_id=p_item_id)
      AND (p_movement_type IS NULL OR il.movement_type=p_movement_type)
  ),
  effects AS (
    SELECT event_id,created_at,movement_date,company_id,voucher_id,reference,
           item_id,item_code,item_name,movement_type,qty,user_email,
           source_branch_id AS branch_id,-qty AS effect_qty
    FROM base WHERE source_branch_id IS NOT NULL
    UNION ALL
    SELECT event_id,created_at,movement_date,company_id,voucher_id,reference,
           item_id,item_code,item_name,movement_type,qty,user_email,
           target_branch_id AS branch_id,qty AS effect_qty
    FROM base
    WHERE target_branch_id IS NOT NULL
      AND target_branch_id IS DISTINCT FROM source_branch_id
  ),
  states AS (
    SELECT e.*,COALESCE(sb.qty,0) AS current_qty,
      COALESCE(sb.qty,0)-COALESCE(
        SUM(e.effect_qty) OVER (
          PARTITION BY e.branch_id,e.item_id
          ORDER BY e.created_at DESC,e.event_id DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ),0
      ) AS after_qty
    FROM effects e
    JOIN public.branches b ON b.id=e.branch_id AND b.company_id=p_company_id
    LEFT JOIN public.stock_branches sb
      ON sb.branch_id=e.branch_id AND sb.item_id=e.item_id
  ),
  filtered AS (
    SELECT * FROM states
    WHERE (p_from_date IS NULL OR movement_date>=p_from_date)
      AND (p_to_date IS NULL OR movement_date<=p_to_date)
      AND (p_branch_id IS NULL OR branch_id=p_branch_id)
      AND (
        NULLIF(btrim(p_query),'') IS NULL
        OR item_code ILIKE '%'||btrim(p_query)||'%'
        OR item_name ILIKE '%'||btrim(p_query)||'%'
        OR COALESCE(reference,'') ILIKE '%'||btrim(p_query)||'%'
        OR COALESCE(voucher_id,'') ILIKE '%'||btrim(p_query)||'%'
      )
  )
  SELECT count(*) INTO v_count FROM filtered;

  WITH base AS (
    SELECT il.id AS event_id,il.created_at,il.movement_date,il.voucher_id,
           il.reference,il.item_id,il.item_code,il.item_name,il.movement_type,
           il.qty,il.user_email,il.source_branch_id,il.target_branch_id
    FROM public.inventory_log il
    WHERE il.company_id=p_company_id
      AND (p_item_id IS NULL OR il.item_id=p_item_id)
      AND (p_movement_type IS NULL OR il.movement_type=p_movement_type)
  ),
  effects AS (
    SELECT event_id,created_at,movement_date,voucher_id,reference,item_id,item_code,
           item_name,movement_type,qty,user_email,source_branch_id AS branch_id,-qty AS effect_qty
    FROM base WHERE source_branch_id IS NOT NULL
    UNION ALL
    SELECT event_id,created_at,movement_date,voucher_id,reference,item_id,item_code,
           item_name,movement_type,qty,user_email,target_branch_id AS branch_id,qty AS effect_qty
    FROM base
    WHERE target_branch_id IS NOT NULL
      AND target_branch_id IS DISTINCT FROM source_branch_id
  ),
  states AS (
    SELECT e.*,b.branch_code,b.name AS branch_name,COALESCE(i.unit,'') AS unit,
           COALESCE(sb.qty,0) AS current_qty,
           COALESCE(sb.qty,0)-COALESCE(
             SUM(e.effect_qty) OVER (
               PARTITION BY e.branch_id,e.item_id
               ORDER BY e.created_at DESC,e.event_id DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
             ),0
           ) AS after_qty
    FROM effects e
    JOIN public.branches b ON b.id=e.branch_id AND b.company_id=p_company_id
    JOIN public.items i ON i.id=e.item_id
    LEFT JOIN public.stock_branches sb ON sb.branch_id=e.branch_id AND sb.item_id=e.item_id
  ),
  filtered AS (
    SELECT * FROM states
    WHERE (p_from_date IS NULL OR movement_date>=p_from_date)
      AND (p_to_date IS NULL OR movement_date<=p_to_date)
      AND (p_branch_id IS NULL OR branch_id=p_branch_id)
      AND (
        NULLIF(btrim(p_query),'') IS NULL
        OR item_code ILIKE '%'||btrim(p_query)||'%'
        OR item_name ILIKE '%'||btrim(p_query)||'%'
        OR COALESCE(reference,'') ILIKE '%'||btrim(p_query)||'%'
        OR COALESCE(voucher_id,'') ILIKE '%'||btrim(p_query)||'%'
      )
  )
  SELECT COALESCE(
    jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC,x.event_id DESC),'[]'::jsonb
  ) INTO v_rows
  FROM (
    SELECT event_id,created_at,movement_date,voucher_id,reference,item_id,item_code,
           item_name,unit,movement_type,qty,effect_qty,branch_id,branch_code,branch_name,
           after_qty-effect_qty AS before_qty,after_qty,user_email
    FROM filtered
    LIMIT v_limit OFFSET v_offset
  ) x;

  RETURN jsonb_build_object(
    'success',true,'rows',v_rows,'count',v_count,'limit',v_limit,'offset',v_offset
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.inventory_replenishment_report(
  p_company_id uuid,
  p_user_email text DEFAULT NULL::text,
  p_branch_id uuid DEFAULT NULL::uuid,
  p_limit integer DEFAULT 200,
  p_offset integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_limit integer := LEAST(GREATEST(COALESCE(p_limit,200),1),1000);
  v_offset integer := GREATEST(COALESCE(p_offset,0),0);
  v_rows jsonb;
  v_role text := COALESCE(current_setting('request.jwt.claim.role', true),'');
  v_context_company uuid := app_private.current_user_company_id();
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.companies c
    WHERE c.id=p_company_id AND COALESCE(c.is_active,true)
  ) THEN
    RAISE EXCEPTION 'سياق الشركة غير موجود أو غير نشط';
  END IF;

  IF v_role <> 'service_role' THEN
    IF v_context_company IS NULL OR v_context_company <> p_company_id THEN
      RAISE EXCEPTION 'سياق الشركة غير صالح للجلسة الحالية';
    END IF;

    IF NOT app_private.current_user_has_permission('reports') THEN
      RAISE EXCEPTION 'REPORTS_PERMISSION_REQUIRED';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id=auth.uid()
        AND u.company_id=p_company_id
        AND COALESCE(u.status,'Active')='Active'
        AND (p_user_email IS NULL OR lower(u.email)=lower(p_user_email))
    ) THEN
      RAISE EXCEPTION 'المستخدم لا ينتمي إلى الشركة أو البريد لا يطابق الجلسة';
    END IF;
  ELSIF p_user_email IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.company_id=p_company_id
      AND lower(u.email)=lower(p_user_email)
      AND COALESCE(u.status,'Active')='Active'
  ) THEN
    RAISE EXCEPTION 'المستخدم لا ينتمي إلى الشركة';
  END IF;

  IF p_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id=p_branch_id AND b.company_id=p_company_id
  ) THEN
    RAISE EXCEPTION 'الفرع لا ينتمي إلى الشركة';
  END IF;

  SELECT COALESCE(
    jsonb_agg(to_jsonb(x) ORDER BY x.deficit_qty DESC,x.branch_name,x.item_code),
    '[]'::jsonb
  ) INTO v_rows
  FROM (
    SELECT sb.branch_id,b.branch_code,b.name AS branch_name,
           i.id AS item_id,i.item_code,i.name AS item_name,i.unit,
           GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0) AS available_qty,
           COALESCE(sb.allocated_qty,0) AS allocated_qty,
           COALESCE(i.reorder_point,0) AS reorder_point,
           COALESCE(i.max_qty,0) AS max_qty,
           GREATEST(
             COALESCE(i.reorder_point,0)-
             GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0),
             0
           ) AS deficit_qty,
           CASE
             WHEN COALESCE(i.max_qty,0)>COALESCE(i.reorder_point,0)
             THEN GREATEST(
               COALESCE(i.max_qty,0)-
               GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0),0
             )
             ELSE GREATEST(
               COALESCE(i.reorder_point,0)-
               GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0),0
             )
           END AS recommended_order_qty,
           COALESCE(i.cost_price,0) AS cost_price,
           CASE
             WHEN COALESCE(i.max_qty,0)>COALESCE(i.reorder_point,0)
             THEN GREATEST(
               COALESCE(i.max_qty,0)-
               GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0),0
             )
             ELSE GREATEST(
               COALESCE(i.reorder_point,0)-
               GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0),0
             )
           END * COALESCE(i.cost_price,0) AS recommended_order_value
    FROM public.stock_branches sb
    JOIN public.branches b ON b.id=sb.branch_id AND b.company_id=p_company_id
    JOIN public.items i ON i.id=sb.item_id
    WHERE (p_branch_id IS NULL OR sb.branch_id=p_branch_id)
      AND COALESCE(i.reorder_point,0)>0
      AND GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0)
          <=COALESCE(i.reorder_point,0)
    LIMIT v_limit OFFSET v_offset
  ) x;

  RETURN jsonb_build_object(
    'success',true,'rows',v_rows,'limit',v_limit,'offset',v_offset
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.inventory_movement_report(uuid,text,date,date,uuid,uuid,text,text,integer,integer)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.inventory_movement_report(uuid,text,date,date,uuid,uuid,text,text,integer,integer)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.inventory_replenishment_report(uuid,text,uuid,integer,integer)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.inventory_replenishment_report(uuid,text,uuid,integer,integer)
  TO authenticated, service_role;

COMMIT;