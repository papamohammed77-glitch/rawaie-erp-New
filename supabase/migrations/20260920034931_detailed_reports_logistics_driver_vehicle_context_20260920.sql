-- RAWAEA ERP
-- Detailed Reports logistics driver/vehicle context
-- Canonical replay of Production migration 20260920034931
CREATE OR REPLACE FUNCTION public.detailed_reports_read(p_report_key text, p_company_id uuid DEFAULT NULL::uuid, p_user_email text DEFAULT NULL::text, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_branch_ids uuid[] DEFAULT NULL::uuid[], p_item_ids uuid[] DEFAULT NULL::uuid[], p_account_ids uuid[] DEFAULT NULL::uuid[], p_cost_center_ids uuid[] DEFAULT NULL::uuid[], p_movement_types text[] DEFAULT NULL::text[], p_trace_item_id uuid DEFAULT NULL::uuid, p_trace_direction text DEFAULT 'all'::text, p_trace_query text DEFAULT NULL::text, p_work_order_code text DEFAULT NULL::text, p_limit integer DEFAULT 200, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
  v_role text := COALESCE(current_setting('request.jwt.claim.role', true),'');
  v_key text := lower(btrim(COALESCE(p_report_key,'')));
  v_from date := COALESCE(p_from_date,current_date);
  v_to date := COALESCE(p_to_date,current_date);
  v_limit integer := LEAST(GREATEST(COALESCE(p_limit,200),1),1000);
  v_offset integer := GREATEST(COALESCE(p_offset,0),0);
  v_rows jsonb := '[]'::jsonb;
  v_summary jsonb := '{}'::jsonb;
  v_meta jsonb := '{}'::jsonb;
BEGIN
  IF v_role='service_role' THEN
    IF p_company_id IS NULL THEN RAISE EXCEPTION 'COMPANY_CONTEXT_REQUIRED'; END IF;
    v_company_id:=p_company_id;
  ELSE
    IF v_company_id IS NULL THEN RAISE EXCEPTION 'COMPANY_CONTEXT_REQUIRED'; END IF;
    IF p_company_id IS NULL OR p_company_id<>v_company_id THEN RAISE EXCEPTION 'REPORT_COMPANY_CONTEXT_MISMATCH'; END IF;
    IF NOT app_private.current_user_has_permission('reports') THEN RAISE EXCEPTION 'REPORTS_PERMISSION_REQUIRED'; END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id=auth.uid() AND u.company_id=v_company_id
        AND COALESCE(u.status,'Active')='Active'
        AND (p_user_email IS NULL OR lower(u.email)=lower(p_user_email))
    ) THEN RAISE EXCEPTION 'REPORT_ACTOR_COMPANY_MISMATCH'; END IF;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.companies c WHERE c.id=v_company_id AND COALESCE(c.is_active,true))
    THEN RAISE EXCEPTION 'REPORT_COMPANY_NOT_ACTIVE'; END IF;
  IF v_from>v_to THEN RAISE EXCEPTION 'REPORT_DATE_RANGE_INVALID'; END IF;
  IF v_key NOT IN ('inventory_gl_reconciliation','grni','material_ledger','traceability','production_variance','inventory_abc','logistics_performance')
    THEN RAISE EXCEPTION 'REPORT_KEY_NOT_SUPPORTED:%',v_key; END IF;

  IF p_branch_ids IS NOT NULL AND cardinality(p_branch_ids)>0 AND EXISTS(
    SELECT 1 FROM unnest(p_branch_ids) x(branch_id)
    WHERE NOT EXISTS(SELECT 1 FROM public.branches b WHERE b.id=x.branch_id AND b.company_id=v_company_id)
  ) THEN RAISE EXCEPTION 'REPORT_BRANCH_SCOPE_INVALID'; END IF;

  IF p_item_ids IS NOT NULL AND cardinality(p_item_ids)>0 AND EXISTS(
    SELECT 1 FROM unnest(p_item_ids) x(item_id)
    WHERE NOT EXISTS(SELECT 1 FROM public.items i WHERE i.id=x.item_id)
  ) THEN RAISE EXCEPTION 'REPORT_ITEM_SCOPE_INVALID'; END IF;

  IF p_account_ids IS NOT NULL AND cardinality(p_account_ids)>0 AND EXISTS(
    SELECT 1 FROM unnest(p_account_ids) x(account_id)
    WHERE NOT EXISTS(
      SELECT 1 FROM public.chart_of_accounts c
      WHERE c.id=x.account_id AND c.company_id=v_company_id
    )
  ) THEN RAISE EXCEPTION 'REPORT_ACCOUNT_SCOPE_INVALID'; END IF;

  IF p_cost_center_ids IS NOT NULL AND cardinality(p_cost_center_ids)>0
    THEN RAISE EXCEPTION 'REPORT_COST_CENTER_SCOPE_UNPROVEN'; END IF;

  IF v_key='inventory_abc' THEN
    WITH base AS (
      SELECT od.item_id,od.item_code,
             COALESCE(MAX(od.item_name),MAX(i.name),od.item_code) item_name,
             SUM(GREATEST(COALESCE(od.qty,0)-COALESCE(od.qty_returned,0),0)) net_qty,
             SUM(GREATEST(COALESCE(od.qty,0)-COALESCE(od.qty_returned,0),0)*COALESCE(od.unit_price,0)) sales_value
      FROM public.order_details od
      JOIN public.orders o ON o.id=od.order_id AND o.company_id=v_company_id
      LEFT JOIN public.items i ON i.id=od.item_id
      WHERE o.order_date BETWEEN v_from AND v_to
        AND o.order_status IN ('Invoiced','Delivered')
        AND (p_branch_ids IS NULL OR cardinality(p_branch_ids)=0 OR o.branch_id=ANY(p_branch_ids))
        AND (p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR od.item_id=ANY(p_item_ids))
      GROUP BY od.item_id,od.item_code
    ),
    ranked AS (
      SELECT b.*,
             COALESCE(SUM(b.sales_value) OVER (),0) total_sales,
             COALESCE(SUM(b.sales_value) OVER (
               ORDER BY b.sales_value DESC,b.item_code
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
             ),0) cumulative_sales
      FROM base b
    )
    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'item_id',r.item_id,
        'item_code',r.item_code,
        'item_name',r.item_name,
        'net_qty',r.net_qty,
        'sales_value',r.sales_value,
        'sales_share_pct',CASE WHEN r.total_sales=0 THEN 0 ELSE ROUND((r.sales_value/r.total_sales)*100,2) END,
        'cumulative_share_pct',CASE WHEN r.total_sales=0 THEN 0 ELSE ROUND((r.cumulative_sales/r.total_sales)*100,2) END,
        'abc_class',CASE
          WHEN r.total_sales=0 THEN 'C'
          WHEN r.total_sales=r.sales_value THEN 'A'
          WHEN r.cumulative_sales/r.total_sales <= 0.80 THEN 'A'
          WHEN r.cumulative_sales/r.total_sales <= 0.95 THEN 'B'
          ELSE 'C'
        END
      ) ORDER BY r.sales_value DESC,r.item_code
    ),'[]'::jsonb) INTO v_rows
    FROM ranked r;

    v_summary:=jsonb_build_object(
      'row_count',jsonb_array_length(v_rows),
      'total_sales_value',COALESCE((SELECT SUM((x->>'sales_value')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'class_a_count',COALESCE((SELECT COUNT(*) FROM jsonb_array_elements(v_rows) x WHERE x->>'abc_class'='A'),0),
      'class_b_count',COALESCE((SELECT COUNT(*) FROM jsonb_array_elements(v_rows) x WHERE x->>'abc_class'='B'),0),
      'class_c_count',COALESCE((SELECT COUNT(*) FROM jsonb_array_elements(v_rows) x WHERE x->>'abc_class'='C'),0)
    );
    v_meta:=jsonb_build_object(
      'report_key',v_key,
      'source_truth','CURRENT_PRODUCTION',
      'sales_source','orders + order_details',
      'eligible_statuses',jsonb_build_array('Invoiced','Delivered'),
      'classification','Analytical 80/15/5 cumulative sales convention',
      'policy_status','ANALYTICAL_ONLY',
      'note','Classification is a report analysis aid, not a purchasing policy; thresholds are not configurable in current Production.'
    );
    RETURN jsonb_build_object(
      'success',true,'report_key',v_key,'company_id',v_company_id,
      'from_date',v_from,'to_date',v_to,'limit',v_limit,'offset',v_offset,
      'summary',v_summary,'meta',v_meta,
      'rows',(SELECT COALESCE(jsonb_agg(value),'[]'::jsonb)
              FROM (SELECT value FROM jsonb_array_elements(v_rows) WITH ORDINALITY q(value,ord)
                    ORDER BY ord LIMIT v_limit OFFSET v_offset) paged)
    );
  END IF;

  IF v_key='logistics_performance' THEN
    WITH rs AS (
      SELECT r.id,r.runsheet_code,r.run_date,r.status,r.driver_id,r.vehicle_id,
             r.picker_start,r.picker_end,r.loader_start,r.loader_end,r.delivery_start,r.delivery_end
      FROM public.runsheets r
      WHERE r.company_id=v_company_id
        AND r.run_date BETWEEN v_from AND v_to
        AND (
          p_branch_ids IS NULL OR cardinality(p_branch_ids)=0 OR EXISTS (
            SELECT 1 FROM public.orders bo
            WHERE bo.runsheet_id=r.id AND bo.company_id=v_company_id AND bo.branch_id=ANY(p_branch_ids)
          )
        )
    ),
    ord AS (
      SELECT o.runsheet_id,
             COUNT(*) order_count,
             COUNT(*) FILTER (WHERE o.order_status='Delivered') delivered_order_count,
             COALESCE(SUM(o.total_amount) FILTER (WHERE o.order_status IN ('Invoiced','Delivered')),0) sales_value,
             COALESCE(SUM(o.amount_paid) FILTER (WHERE o.order_status IN ('Invoiced','Delivered')),0) amount_paid
      FROM public.orders o JOIN rs ON rs.id=o.runsheet_id
      WHERE o.company_id=v_company_id
      GROUP BY o.runsheet_id
    ),
    det AS (
      SELECT d.runsheet_id,
             COALESCE(SUM(CASE WHEN p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR d.item_id=ANY(p_item_ids) THEN COALESCE(d.qty_ordered,0) ELSE 0 END),0) ordered_qty,
             COALESCE(SUM(CASE WHEN p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR d.item_id=ANY(p_item_ids) THEN COALESCE(d.qty_picked,0) ELSE 0 END),0) picked_qty,
             COALESCE(SUM(CASE WHEN p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR d.item_id=ANY(p_item_ids) THEN COALESCE(d.qty_loaded,0) ELSE 0 END),0) loaded_qty,
             COALESCE(SUM(CASE WHEN p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR d.item_id=ANY(p_item_ids) THEN COALESCE(d.qty_delivered,0) ELSE 0 END),0) delivered_qty,
             COALESCE(SUM(CASE WHEN p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR d.item_id=ANY(p_item_ids) THEN COALESCE(d.qty_refused,0) ELSE 0 END),0) refused_qty,
             COALESCE(SUM(CASE WHEN p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR d.item_id=ANY(p_item_ids) THEN COALESCE(d.qty_returned,0) ELSE 0 END),0) returned_qty
      FROM public.run_sheet_details d JOIN rs ON rs.id=d.runsheet_id
      GROUP BY d.runsheet_id
    )
    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'runsheet_id',r.id,'runsheet_code',r.runsheet_code,'run_date',r.run_date,'status',r.status,
        'driver_id',r.driver_id,'driver_name',dr.name,'driver_email',dr.email,
        'vehicle_id',r.vehicle_id,'vehicle_code',vh.vehicle_code,'vehicle_plate',vh.license_plate,
        'vehicle_model',vh.model,'vehicle_status',vh.status,
        'order_count',COALESCE(o.order_count,0),'delivered_order_count',COALESCE(o.delivered_order_count,0),
        'sales_value',COALESCE(o.sales_value,0),'amount_paid',COALESCE(o.amount_paid,0),
        'outstanding',COALESCE(o.sales_value,0)-COALESCE(o.amount_paid,0),
        'ordered_qty',COALESCE(d.ordered_qty,0),'picked_qty',COALESCE(d.picked_qty,0),
        'loaded_qty',COALESCE(d.loaded_qty,0),'delivered_qty',COALESCE(d.delivered_qty,0),
        'refused_qty',COALESCE(d.refused_qty,0),'returned_qty',COALESCE(d.returned_qty,0),
        'pick_completion_pct',CASE WHEN COALESCE(d.ordered_qty,0)=0 THEN NULL ELSE ROUND(d.picked_qty/d.ordered_qty*100,2) END,
        'load_completion_pct',CASE WHEN COALESCE(d.ordered_qty,0)=0 THEN NULL ELSE ROUND(d.loaded_qty/d.ordered_qty*100,2) END,
        'delivery_fill_pct',CASE WHEN COALESCE(d.ordered_qty,0)=0 THEN NULL ELSE ROUND(d.delivered_qty/d.ordered_qty*100,2) END,
        'refusal_pct',CASE WHEN COALESCE(d.loaded_qty,0)=0 THEN NULL ELSE ROUND(d.refused_qty/d.loaded_qty*100,2) END,
        'return_pct',CASE WHEN COALESCE(d.delivered_qty,0)=0 THEN NULL ELSE ROUND(d.returned_qty/d.delivered_qty*100,2) END,
        'pick_minutes',CASE WHEN r.picker_start IS NULL OR r.picker_end IS NULL THEN NULL ELSE ROUND(EXTRACT(EPOCH FROM (r.picker_end-r.picker_start))/60.0,2) END,
        'load_minutes',CASE WHEN r.loader_start IS NULL OR r.loader_end IS NULL THEN NULL ELSE ROUND(EXTRACT(EPOCH FROM (r.loader_end-r.loader_start))/60.0,2) END,
        'delivery_minutes',CASE WHEN r.delivery_start IS NULL OR r.delivery_end IS NULL THEN NULL ELSE ROUND(EXTRACT(EPOCH FROM (r.delivery_end-r.delivery_start))/60.0,2) END,
        'full_cycle_minutes',CASE WHEN r.picker_start IS NULL OR r.delivery_end IS NULL THEN NULL ELSE ROUND(EXTRACT(EPOCH FROM (r.delivery_end-r.picker_start))/60.0,2) END,
        'on_time_supported',false,'settlement_status',ds.status,'settlement_code',ds.settlement_code
      ) ORDER BY r.run_date DESC,r.runsheet_code DESC
    ),'[]'::jsonb) INTO v_rows
    FROM rs r
    LEFT JOIN ord o ON o.runsheet_id=r.id
    LEFT JOIN det d ON d.runsheet_id=r.id
    LEFT JOIN public.daily_settlements ds ON ds.runsheet_id=r.id AND ds.company_id=v_company_id
    LEFT JOIN public.users dr ON dr.id=r.driver_id AND dr.company_id=v_company_id
    LEFT JOIN public.vehicles vh ON vh.id=r.vehicle_id AND vh.company_id=v_company_id;

    v_summary:=jsonb_build_object(
      'row_count',jsonb_array_length(v_rows),
      'runsheet_count',jsonb_array_length(v_rows),
      'completed_delivery_runsheets',COALESCE((SELECT COUNT(*) FROM jsonb_array_elements(v_rows) x WHERE x->>'full_cycle_minutes' IS NOT NULL),0),
      'ordered_qty',COALESCE((SELECT SUM((x->>'ordered_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'picked_qty',COALESCE((SELECT SUM((x->>'picked_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'loaded_qty',COALESCE((SELECT SUM((x->>'loaded_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'delivered_qty',COALESCE((SELECT SUM((x->>'delivered_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'refused_qty',COALESCE((SELECT SUM((x->>'refused_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'returned_qty',COALESCE((SELECT SUM((x->>'returned_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0),
      'delivery_fill_pct',CASE
        WHEN COALESCE((SELECT SUM((x->>'ordered_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0)=0 THEN NULL
        ELSE ROUND(
          COALESCE((SELECT SUM((x->>'delivered_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0) /
          NULLIF((SELECT SUM((x->>'ordered_qty')::numeric) FROM jsonb_array_elements(v_rows) x),0) * 100,2)
      END,
      'average_full_cycle_minutes',(
        SELECT ROUND(AVG((x->>'full_cycle_minutes')::numeric),2) FROM jsonb_array_elements(v_rows) x
        WHERE x->>'full_cycle_minutes' IS NOT NULL
      ),
      'on_time_supported',false,
      'on_time_reason','لا يوجد موعد تسليم مخطط في Production الحالية يسمح بقياس الالتزام بالموعد دون اختلاق بيانات.'
    );
    v_meta:=jsonb_build_object(
      'report_key',v_key,'source_truth','CURRENT_PRODUCTION',
      'sources','runsheets + orders + run_sheet_details + daily_settlements',
      'field_roles','ordered/picked/loaded/delivered/refused/returned are authoritative operational quantities already used by field workflow',
      'on_time_supported',false,
      'note','Report is read-only; it observes the existing field workflow and does not replace runsheet/picking/loading/delivery engines.'
    );
    RETURN jsonb_build_object(
      'success',true,'report_key',v_key,'company_id',v_company_id,
      'from_date',v_from,'to_date',v_to,'limit',v_limit,'offset',v_offset,
      'summary',v_summary,'meta',v_meta,
      'rows',(SELECT COALESCE(jsonb_agg(value),'[]'::jsonb)
              FROM (SELECT value FROM jsonb_array_elements(v_rows) WITH ORDINALITY q(value,ord)
                    ORDER BY ord LIMIT v_limit OFFSET v_offset) paged)
    );
  END IF;

  IF v_key IN ('inventory_gl_reconciliation','grni','material_ledger','traceability','production_variance') THEN
    RETURN public.detailed_reports_read_paged_internal(
      p_report_key,p_company_id,p_user_email,p_from_date,p_to_date,p_branch_ids,p_item_ids,p_account_ids,
      p_cost_center_ids,p_movement_types,p_trace_item_id,p_trace_direction,p_trace_query,p_work_order_code,
      p_limit,p_offset
    );
  END IF;

  IF v_key='inventory_gl_reconciliation' THEN
    SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.branch_name,x.item_code),'[]'::jsonb)
    INTO v_rows
    FROM (
      SELECT sb.branch_id,b.branch_code,b.name branch_name,sb.item_id,i.item_code,i.name item_name,i.unit,
             COALESCE(sb.qty,0) qty_on_hand,COALESCE(sb.allocated_qty,0) allocated_qty,
             GREATEST(COALESCE(sb.qty,0)-COALESCE(sb.allocated_qty,0),0) available_qty,
             COALESCE(i.cost_price,0) current_cost_price,
             COALESCE(sb.qty,0)*COALESCE(i.cost_price,0) physical_value_current_cost
      FROM public.stock_branches sb
      JOIN public.branches b ON b.id=sb.branch_id AND b.company_id=v_company_id
      JOIN public.items i ON i.id=sb.item_id
      WHERE (p_branch_ids IS NULL OR cardinality(p_branch_ids)=0 OR sb.branch_id=ANY(p_branch_ids))
        AND (p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR sb.item_id=ANY(p_item_ids))
    ) x;

    WITH physical AS (
      SELECT SUM(COALESCE(sb.qty,0)) qty_on_hand,
             SUM(COALESCE(sb.qty,0)*COALESCE(i.cost_price,0)) physical_value,
             SUM(CASE WHEN COALESCE(sb.qty,0)>0 AND COALESCE(i.cost_price,0)=0 THEN sb.qty ELSE 0 END) uncosted_qty
      FROM public.stock_branches sb
      JOIN public.branches b ON b.id=sb.branch_id AND b.company_id=v_company_id
      JOIN public.items i ON i.id=sb.item_id
      WHERE (p_branch_ids IS NULL OR cardinality(p_branch_ids)=0 OR sb.branch_id=ANY(p_branch_ids))
        AND (p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR sb.item_id=ANY(p_item_ids))
    ), gl AS (
      SELECT COALESCE(SUM(jl.debit),0) debit,COALESCE(SUM(jl.credit),0) credit
      FROM public.journal_lines jl
      JOIN public.journal_entries je ON je.id=jl.entry_id
      JOIN public.chart_of_accounts coa ON coa.id=jl.account_id
      WHERE je.company_id=v_company_id AND je.status='Posted' AND je.entry_date<=v_to
        AND coa.company_id=v_company_id
        AND (
          ((p_account_ids IS NULL OR cardinality(p_account_ids)=0) AND coa.account_code='124')
          OR (p_account_ids IS NOT NULL AND cardinality(p_account_ids)>0 AND coa.id=ANY(p_account_ids))
        )
    )
    SELECT jsonb_build_object(
      'qty_on_hand',COALESCE(p.qty_on_hand,0),
      'uncosted_qty',COALESCE(p.uncosted_qty,0),
      'physical_value_current_cost',COALESCE(p.physical_value,0),
      'gl_debit_to_date',COALESCE(g.debit,0),
      'gl_credit_to_date',COALESCE(g.credit,0),
      'gl_balance_to_date',COALESCE(g.debit-g.credit,0),
      'difference',COALESCE(p.physical_value,0)-COALESCE(g.debit-g.credit,0),
      'valuation_basis','stock_branches.qty × items.cost_price (current Production cost basis)',
      'inventory_gl_account','124',
      'historical_as_of_supported',(v_to=current_date),
      'status',CASE
        WHEN v_to<>current_date THEN 'CURRENT_SNAPSHOT_ONLY'
        WHEN COALESCE(p.qty_on_hand,0)>0 AND COALESCE(p.uncosted_qty,0)>0 THEN 'VALUATION_BASIS_MISSING'
        WHEN abs(COALESCE(p.physical_value,0)-COALESCE(g.debit-g.credit,0))<0.005 THEN 'ALIGNED'
        ELSE 'VALUE_DIFFERENCE' END
    ) INTO v_summary
    FROM physical p CROSS JOIN gl g;

    v_meta:=jsonb_build_object(
      'report_key',v_key,'source_truth','CURRENT_PRODUCTION','physical_source','stock_branches',
      'cost_source','items.cost_price','gl_source','journal_entries + journal_lines + chart_of_accounts',
      'historical_cost_source_available',false,
      'note','Past-date monetary valuation is not claimed because Production has no historical cost-layer/valuation table.'
    );

  ELSIF v_key='grni' THEN
    WITH invoiced AS (
      SELECT pi.purchase_order_id po_id,piid.item_id,
             SUM(COALESCE(piid.qty,0)) invoiced_qty,
             SUM(COALESCE(piid.line_total,0)) invoiced_value
      FROM public.purchase_invoices pi
      JOIN public.purchase_invoice_details piid ON piid.invoice_id=pi.id
      WHERE pi.company_id=v_company_id AND pi.purchase_order_id IS NOT NULL
        AND pi.status<>'Draft' AND pi.invoice_date<=v_to
      GROUP BY pi.purchase_order_id,piid.item_id
    ), recv_dates AS (
      SELECT po_number,MAX(date) last_receiving_date
      FROM public.receiving
      WHERE company_id=v_company_id AND date<=v_to
      GROUP BY po_number
    )
    SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.grni_value DESC,x.po_code,x.item_code),'[]'::jsonb)
    INTO v_rows
    FROM (
      SELECT po.id po_id,po.po_code,po.po_date,po.supplier_id,po.supplier_name,po.branch_id,
             pod.item_id,pod.item_code,pod.item_name,pod.unit,
             COALESCE(pod.qty_ordered,0) ordered_qty,COALESCE(pod.qty_received,0) received_qty,
             COALESCE(inv.invoiced_qty,0) invoiced_qty,
             GREATEST(COALESCE(pod.qty_received,0)-COALESCE(inv.invoiced_qty,0),0) uninvoiced_qty,
             COALESCE(pod.qty_received,0)*COALESCE(pod.unit_price,0) received_value_at_po_price,
             COALESCE(inv.invoiced_value,0) invoiced_value,
             GREATEST(COALESCE(pod.qty_received,0)*COALESCE(pod.unit_price,0)-COALESCE(inv.invoiced_value,0),0) grni_value,
             rd.last_receiving_date,
             GREATEST(v_to-COALESCE(rd.last_receiving_date,po.po_date),0) days_outstanding,
             CASE WHEN COALESCE(pod.qty_received,0)<=0 THEN 'NOT_RECEIVED'
                  WHEN COALESCE(inv.invoiced_qty,0)<=0 THEN 'RECEIVED_NOT_INVOICED'
                  WHEN COALESCE(inv.invoiced_qty,0)<COALESCE(pod.qty_received,0) THEN 'PARTIALLY_INVOICED'
                  ELSE 'FULLY_INVOICED' END status
      FROM public.purchase_orders po
      JOIN public.purchase_order_details pod ON pod.po_id=po.id
      LEFT JOIN invoiced inv ON inv.po_id=po.id AND inv.item_id=pod.item_id
      LEFT JOIN recv_dates rd ON rd.po_number=po.po_code
      WHERE po.company_id=v_company_id AND po.po_date<=v_to
        AND (p_branch_ids IS NULL OR cardinality(p_branch_ids)=0 OR po.branch_id=ANY(p_branch_ids))
        AND (p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR pod.item_id=ANY(p_item_ids))
    ) x;

    SELECT jsonb_build_object(
      'row_count',jsonb_array_length(v_rows),
      'total_received_value',COALESCE(SUM((r->>'received_value_at_po_price')::numeric),0),
      'total_invoiced_value',COALESCE(SUM((r->>'invoiced_value')::numeric),0),
      'total_grni_value',COALESCE(SUM((r->>'grni_value')::numeric),0),
      'control_account_configured',EXISTS(
        SELECT 1 FROM public.chart_of_accounts coa
        WHERE coa.company_id=v_company_id
          AND (upper(coa.account_name) LIKE '%GRNI%' OR upper(coa.account_code) LIKE '%GRNI%')
      )
    ) INTO v_summary
    FROM jsonb_array_elements(v_rows) r;

    v_meta:=jsonb_build_object(
      'report_key',v_key,'source_truth','CURRENT_PRODUCTION',
      'receipt_source','purchase_order_details.qty_received + receiving',
      'invoice_source','purchase_invoices + purchase_invoice_details',
      'grni_control_account','not invented; explicit Production account only',
      'valuation_basis','PO unit price for received exposure; invoice line_total for invoiced exposure'
    );

  ELSIF v_key='material_ledger' THEN
    WITH base AS (
      SELECT il.id event_id,il.created_at,il.movement_date,il.company_id,il.voucher_id,il.reference,
             il.item_id,il.item_code,il.item_name,il.movement_type,il.qty,il.user_email,
             il.source_branch_id,il.target_branch_id
      FROM public.inventory_log il
      WHERE il.company_id=v_company_id
        AND (p_item_ids IS NULL OR cardinality(p_item_ids)=0 OR il.item_id=ANY(p_item_ids))
        AND (p_movement_types IS NULL OR cardinality(p_movement_types)=0 OR il.movement_type=ANY(p_movement_types))
    ), effects AS (
      SELECT event_id,created_at,movement_date,company_id,voucher_id,reference,item_id,item_code,item_name,
             movement_type,qty,user_email,source_branch_id branch_id,-qty effect_qty,'OUT' direction
      FROM base WHERE source_branch_id IS NOT NULL
      UNION ALL
      SELECT event_id,created_at,movement_date,company_id,voucher_id,reference,item_id,item_code,item_name,
             movement_type,qty,user_email,target_branch_id branch_id,qty effect_qty,'IN' direction
      FROM base WHERE target_branch_id IS NOT NULL AND target_branch_id IS DISTINCT FROM source_branch_id
    ), states AS (
      SELECT e.*,b.branch_code,b.name branch_name,i.unit,COALESCE(i.cost_price,0) current_cost_price,
             COALESCE(sb.qty,0) current_qty,
             COALESCE(sb.qty,0)-COALESCE(
               SUM(e.effect_qty) OVER(
                 PARTITION BY e.branch_id,e.item_id
                 ORDER BY e.created_at DESC,e.event_id DESC
                 ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
               ),0) after_qty
      FROM effects e
      JOIN public.branches b ON b.id=e.branch_id AND b.company_id=v_company_id
      JOIN public.items i ON i.id=e.item_id
      LEFT JOIN public.stock_branches sb ON sb.branch_id=e.branch_id AND sb.item_id=e.item_id
      WHERE p_branch_ids IS NULL OR cardinality(p_branch_ids)=0 OR e.branch_id=ANY(p_branch_ids)
    )
    SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC,x.event_id DESC),'[]'::jsonb)
    INTO v_rows
    FROM (
      SELECT s.event_id,s.created_at,s.movement_date,s.branch_id,s.branch_code,s.branch_name,
             s.item_id,s.item_code,s.item_name,s.unit,s.movement_type,s.qty,s.effect_qty,
             s.after_qty-s.effect_qty before_qty,s.after_qty,s.current_cost_price,
             abs(s.effect_qty)*s.current_cost_price movement_value_current_cost,
             s.voucher_id,s.reference,s.user_email,s.direction,
             CASE WHEN j.id IS NULL THEN 'UNLINKED' ELSE 'POSTED' END financial_status,
             j.id journal_entry_id,j.entry_code journal_entry_code,COALESCE(j.amount,0) journal_net_amount,
             CASE WHEN j.id IS NULL THEN NULL ELSE 'REFERENCE' END financial_link_method,
             'RECORDED' physical_status
      FROM states s
      LEFT JOIN LATERAL (
        SELECT je.id,je.entry_code,COALESCE(SUM(COALESCE(jl.debit,0)-COALESCE(jl.credit,0)),0) amount
        FROM public.journal_entries je
        LEFT JOIN public.journal_lines jl ON jl.entry_id=je.id
        WHERE je.company_id=v_company_id AND je.status='Posted'
          AND (
            (NULLIF(btrim(s.reference),'') IS NOT NULL AND je.reference=s.reference)
            OR (NULLIF(btrim(s.voucher_id),'') IS NOT NULL AND je.reference=s.voucher_id)
          )
        GROUP BY je.id,je.entry_code
        ORDER BY je.entry_date DESC,je.created_at DESC,je.id DESC LIMIT 1
      ) j ON true
      WHERE s.movement_date BETWEEN v_from AND v_to
        AND (
          NULLIF(btrim(p_trace_query),'') IS NULL
          OR s.item_code ILIKE '%'||btrim(p_trace_query)||'%'
          OR s.item_name ILIKE '%'||btrim(p_trace_query)||'%'
          OR COALESCE(s.reference,'') ILIKE '%'||btrim(p_trace_query)||'%'
          OR COALESCE(s.voucher_id,'') ILIKE '%'||btrim(p_trace_query)||'%'
        )
    ) x;

    SELECT jsonb_build_object(
      'row_count',jsonb_array_length(v_rows),
      'physical_recorded_rows',(SELECT count(*) FROM jsonb_array_elements(v_rows) r WHERE r->>'physical_status'='RECORDED'),
      'financial_linked_rows',(SELECT count(*) FROM jsonb_array_elements(v_rows) r WHERE r->>'financial_status'='POSTED'),
      'financial_unlinked_rows',(SELECT count(*) FROM jsonb_array_elements(v_rows) r WHERE r->>'financial_status'='UNLINKED')
    ) INTO v_summary;

    v_meta:=jsonb_build_object(
      'report_key',v_key,'source_truth','CURRENT_PRODUCTION','physical_source','inventory_log',
      'financial_source','journal_entries + journal_lines',
      'financial_link_method','REFERENCE match only; no direct inventory_log → journal_entries FK',
      'value_basis','current items.cost_price × absolute movement quantity',
      'excluded_non_stock_logs','inventory_log events without source_branch_id/target_branch_id are not treated as physical stock effects'
    );

  ELSIF v_key='traceability' THEN
    IF p_trace_item_id IS NULL THEN RAISE EXCEPTION 'TRACE_ITEM_REQUIRED'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.items i WHERE i.id=p_trace_item_id) THEN RAISE EXCEPTION 'TRACE_ITEM_NOT_FOUND'; END IF;

    WITH inv AS (
      SELECT il.id event_id,il.created_at,il.movement_date,il.voucher_id,il.reference,il.item_id,il.item_code,
             il.item_name,il.movement_type,il.qty,il.source_branch_id,il.target_branch_id,il.user_email
      FROM public.inventory_log il
      WHERE il.company_id=v_company_id AND il.item_id=p_trace_item_id
        AND il.movement_date BETWEEN v_from AND v_to
        AND (
          lower(COALESCE(p_trace_direction,'all'))='all'
          OR (lower(p_trace_direction)='forward' AND il.target_branch_id IS NOT NULL)
          OR (lower(p_trace_direction)='backward' AND il.source_branch_id IS NOT NULL)
        )
    )
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'event_id',inv.event_id,'created_at',inv.created_at,'movement_date',inv.movement_date,
      'movement_type',inv.movement_type,'qty',inv.qty,'item_id',inv.item_id,'item_code',inv.item_code,
      'item_name',inv.item_name,'source_branch_id',inv.source_branch_id,'target_branch_id',inv.target_branch_id,
      'reference',inv.reference,'voucher_id',inv.voucher_id,'user_email',inv.user_email,
      'chain_direction',CASE WHEN lower(COALESCE(p_trace_direction,'all'))='forward' THEN 'FORWARD'
                             WHEN lower(COALESCE(p_trace_direction,'all'))='backward' THEN 'BACKWARD'
                             ELSE 'EVENT' END,
      'order_link',(
        SELECT jsonb_build_object('order_id',o.id,'order_code',o.order_code,'customer_id',o.customer_id,
          'customer_name',o.customer_name,'order_status',o.order_status,'runsheet_id',o.runsheet_id)
        FROM public.orders o
        WHERE o.company_id=v_company_id AND (o.order_code=inv.reference OR o.order_code=inv.voucher_id)
        ORDER BY o.created_at DESC,o.id DESC LIMIT 1
      ),
      'purchase_order_link',(
        SELECT jsonb_build_object('purchase_order_id',po.id,'po_code',po.po_code,'supplier_id',po.supplier_id,
          'supplier_name',po.supplier_name,'status',po.status)
        FROM public.purchase_orders po
        WHERE po.company_id=v_company_id AND (po.po_code=inv.reference OR po.po_code=inv.voucher_id)
        ORDER BY po.created_at DESC,po.id DESC LIMIT 1
      )
    ) ORDER BY
      CASE WHEN lower(COALESCE(p_trace_direction,'all'))='backward' THEN inv.created_at ELSE NULL END ASC,
      CASE WHEN lower(COALESCE(p_trace_direction,'all'))<>'backward' THEN inv.created_at ELSE NULL END DESC,
      inv.event_id DESC),'[]'::jsonb)
    INTO v_rows
    FROM inv
    WHERE NULLIF(btrim(p_trace_query),'') IS NULL
       OR inv.item_code ILIKE '%'||btrim(p_trace_query)||'%'
       OR inv.item_name ILIKE '%'||btrim(p_trace_query)||'%'
       OR COALESCE(inv.reference,'') ILIKE '%'||btrim(p_trace_query)||'%'
       OR COALESCE(inv.voucher_id,'') ILIKE '%'||btrim(p_trace_query)||'%';

    v_summary:=jsonb_build_object(
      'row_count',jsonb_array_length(v_rows),'traceability_level','ITEM_DOCUMENT',
      'batch_tracking_supported',false,'batch_source_status','NOT_AVAILABLE_IN_CURRENT_PRODUCTION_SCHEMA',
      'serial_tracking_supported',false,'lot_tracking_supported',false
    );
    v_meta:=jsonb_build_object(
      'report_key',v_key,'source_truth','CURRENT_PRODUCTION','source','inventory_log + orders + purchase_orders',
      'document_chain','REFERENCE / voucher_id based',
      'critical_gap','No batch/lot/serial identity columns or tables were discovered in current Production.',
      'safe_behavior','The report refuses to fabricate batch/lot identity and remains item/document trace only.'
    );

  ELSIF v_key='production_variance' THEN
    v_rows:='[]'::jsonb;
    v_summary:=jsonb_build_object(
      'status','CONTRACT_GAP','supported',false,
      'planned_actual_quantity_supported',false,'monetary_variance_supported',false,
      'work_order_source_safe',false,'work_order_company_scope','UNPROVEN',
      'reason','Production contains legacy work_orders/work_order_details without company_id/FK to companies and no proven Production writer/consumer linking tenant ownership, actual output, BOM, routing, material consumption, or production cost.',
      'rows',0
    );
    v_meta:=jsonb_build_object(
      'report_key',v_key,'source_truth','CURRENT_PRODUCTION','status','READINESS_ONLY',
      'do_not_invent','No planned/actual cost or quantity variance is fabricated.',
      'next_contract_closure','Production Order + BOM + output/consumption + cost identity with explicit company scope'
    );
  END IF;

  RETURN jsonb_build_object(
    'success',true,'report_key',v_key,'company_id',v_company_id,
    'from_date',v_from,'to_date',v_to,'limit',v_limit,'offset',v_offset,
    'summary',v_summary,'meta',v_meta,
    'rows',CASE WHEN v_key='production_variance' THEN '[]'::jsonb ELSE COALESCE(
      (SELECT COALESCE(jsonb_agg(value),'[]'::jsonb)
       FROM (
         SELECT value FROM jsonb_array_elements(v_rows) WITH ORDINALITY q(value,ord)
         ORDER BY ord LIMIT v_limit OFFSET v_offset
       ) paged),'[]'::jsonb) END
  );
END;
$function$


REVOKE ALL ON FUNCTION public.detailed_reports_read(text,uuid,text,date,date,uuid[],uuid[],uuid[],uuid[],text[],uuid,text,text,text,integer,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.detailed_reports_read(text,uuid,text,date,date,uuid[],uuid[],uuid[],uuid[],text[],uuid,text,text,text,integer,integer) TO authenticated, service_role;
