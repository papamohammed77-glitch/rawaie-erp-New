-- RAWAEA ERP — Comprehensive Reports inventory turnover contract
-- Canonical migration for production function:
-- comprehensive_inventory_turnover_report
-- Read-only reporting capability; no business transaction writer is introduced.

BEGIN;

CREATE OR REPLACE FUNCTION public.comprehensive_inventory_turnover_report(
  p_company_id uuid,
  p_from_date date,
  p_to_date date,
  p_item_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_company uuid := app_private.current_user_company_id();
  v_from date := COALESCE(p_from_date, current_date);
  v_to date := COALESCE(p_to_date, current_date);
  v_days numeric;
  v_rows jsonb;
BEGIN
  IF v_company IS NULL THEN
    RAISE EXCEPTION 'سياق الشركة المصادق عليه مطلوب';
  END IF;

  IF p_company_id IS NULL OR p_company_id <> v_company THEN
    RAISE EXCEPTION 'سياق الشركة غير صالح للتقرير';
  END IF;

  IF v_from > v_to THEN
    RAISE EXCEPTION 'نطاق التاريخ غير صالح';
  END IF;

  IF p_item_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.items i WHERE i.id = p_item_id
  ) THEN
    RAISE EXCEPTION 'الصنف غير موجود';
  END IF;

  v_days := GREATEST((v_to - v_from) + 1, 1);

  WITH current_stock AS (
    SELECT sb.item_id,
           SUM(COALESCE(sb.qty,0)) AS current_qty,
           SUM(GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0)) AS available_qty,
           SUM(COALESCE(sb.allocated_qty,0)) AS allocated_qty
    FROM public.stock_branches sb
    JOIN public.branches b
      ON b.id=sb.branch_id
     AND b.company_id=v_company
    WHERE p_item_id IS NULL OR sb.item_id=p_item_id
    GROUP BY sb.item_id
  ),
  movement_effect AS (
    SELECT il.item_id,
           SUM(
             CASE WHEN il.target_branch_id IS NOT NULL THEN il.qty ELSE 0 END
             - CASE WHEN il.source_branch_id IS NOT NULL THEN il.qty ELSE 0 END
           ) AS period_net_movement,
           COUNT(*) AS movement_count
    FROM public.inventory_log il
    WHERE il.company_id=v_company
      AND il.movement_date BETWEEN v_from AND v_to
      AND (p_item_id IS NULL OR il.item_id=p_item_id)
    GROUP BY il.item_id
  ),
  sales_qty AS (
    SELECT od.item_id,
           SUM(
             GREATEST(
               CASE WHEN o.order_status='Delivered'
                    THEN COALESCE(od.qty_delivered,0)
                    ELSE COALESCE(od.qty,0)
               END - COALESCE(od.qty_returned,0),
               0
             )
           ) AS net_sales_qty
    FROM public.order_details od
    JOIN public.orders o ON o.id=od.order_id
    WHERE o.company_id=v_company
      AND o.order_date BETWEEN v_from AND v_to
      AND o.order_status IN ('Invoiced','Delivered')
      AND (p_item_id IS NULL OR od.item_id=p_item_id)
    GROUP BY od.item_id
  ),
  rows AS (
    SELECT i.id AS item_id,
           i.item_code,
           i.name AS item_name,
           i.unit,
           COALESCE(cs.current_qty,0) AS current_qty,
           COALESCE(cs.available_qty,0) AS available_qty,
           COALESCE(cs.allocated_qty,0) AS allocated_qty,
           COALESCE(ss.net_sales_qty,0) AS net_sales_qty,
           COALESCE(me.period_net_movement,0) AS period_net_movement,
           COALESCE(me.movement_count,0) AS movement_count,
           GREATEST(COALESCE(cs.current_qty,0)-COALESCE(me.period_net_movement,0),0) AS opening_qty,
           GREATEST(
             (GREATEST(COALESCE(cs.current_qty,0)-COALESCE(me.period_net_movement,0),0)
              + COALESCE(cs.current_qty,0)) / 2.0, 0
           ) AS average_qty,
           COALESCE(i.cost_price,0) AS cost_price,
           COALESCE(i.reorder_point,0) AS reorder_point,
           COALESCE(i.max_qty,0) AS max_qty
    FROM public.items i
    LEFT JOIN current_stock cs ON cs.item_id=i.id
    LEFT JOIN movement_effect me ON me.item_id=i.id
    LEFT JOIN sales_qty ss ON ss.item_id=i.id
    WHERE COALESCE(i.is_active,true)=true
      AND (p_item_id IS NULL OR i.id=p_item_id)
  ),
  final_rows AS (
    SELECT r.*,
           CASE WHEN r.average_qty > 0 THEN r.net_sales_qty / r.average_qty ELSE 0 END AS turnover_ratio,
           r.net_sales_qty / v_days AS avg_daily_sales,
           CASE WHEN r.net_sales_qty > 0
                THEN r.available_qty / (r.net_sales_qty / v_days)
                ELSE NULL END AS days_on_hand,
           r.current_qty * r.cost_price AS stock_value_at_cost
    FROM rows r
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'item_id',item_id,
        'item_code',item_code,
        'item_name',item_name,
        'unit',unit,
        'opening_qty',opening_qty,
        'current_qty',current_qty,
        'available_qty',available_qty,
        'allocated_qty',allocated_qty,
        'net_sales_qty',net_sales_qty,
        'period_net_movement',period_net_movement,
        'movement_count',movement_count,
        'average_qty',average_qty,
        'turnover_ratio',round(turnover_ratio::numeric,4),
        'avg_daily_sales',round(avg_daily_sales::numeric,4),
        'days_on_hand',CASE WHEN days_on_hand IS NULL THEN NULL ELSE round(days_on_hand::numeric,1) END,
        'cost_price',cost_price,
        'stock_value_at_cost',stock_value_at_cost,
        'reorder_point',reorder_point,
        'max_qty',max_qty
      )
      ORDER BY CASE WHEN turnover_ratio=0 THEN 0 ELSE 1 END,
               turnover_ratio ASC,
               item_code ASC
    ), '[]'::jsonb
  )
  INTO v_rows
  FROM final_rows;

  RETURN jsonb_build_object(
    'success',true,
    'company_id',v_company,
    'from_date',v_from,
    'to_date',v_to,
    'days',v_days,
    'rows',v_rows
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.comprehensive_inventory_turnover_report(uuid,date,date,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.comprehensive_inventory_turnover_report(uuid,date,date,uuid)
  TO authenticated, service_role;

COMMIT;
