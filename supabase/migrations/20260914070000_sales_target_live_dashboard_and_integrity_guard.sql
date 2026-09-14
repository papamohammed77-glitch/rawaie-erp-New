BEGIN;

CREATE OR REPLACE FUNCTION public.sales_target_integrity_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE plan_company uuid; rep_company uuid; branch_company uuid; run_company uuid; assignment_company uuid;
BEGIN
  IF TG_TABLE_NAME='sales_target_assignments' THEN
    SELECT company_id INTO plan_company FROM public.sales_target_plans WHERE id=NEW.plan_id;
    IF plan_company IS NULL OR plan_company<>NEW.company_id THEN RAISE EXCEPTION 'Target assignment company does not match plan company'; END IF;
    IF NEW.sales_rep_id IS NOT NULL THEN
      SELECT company_id INTO rep_company FROM public.users WHERE id=NEW.sales_rep_id;
      IF rep_company IS NULL OR rep_company<>NEW.company_id THEN RAISE EXCEPTION 'Sales representative does not belong to assignment company'; END IF;
    END IF;
    IF NEW.branch_id IS NOT NULL THEN
      SELECT company_id INTO branch_company FROM public.branches WHERE id=NEW.branch_id;
      IF branch_company IS NULL OR branch_company<>NEW.company_id THEN RAISE EXCEPTION 'Branch does not belong to assignment company'; END IF;
    END IF;
    RETURN NEW;
  END IF;
  IF TG_TABLE_NAME='sales_target_run_lines' THEN
    SELECT company_id INTO run_company FROM public.sales_target_runs WHERE id=NEW.run_id;
    SELECT company_id INTO assignment_company FROM public.sales_target_assignments WHERE id=NEW.assignment_id;
    IF run_company IS NULL OR run_company<>NEW.company_id THEN RAISE EXCEPTION 'Target run company does not match run-line company'; END IF;
    IF assignment_company IS NULL OR assignment_company<>NEW.company_id THEN RAISE EXCEPTION 'Target assignment company does not match run-line company'; END IF;
    IF NEW.sales_rep_id IS NOT NULL THEN
      SELECT company_id INTO rep_company FROM public.users WHERE id=NEW.sales_rep_id;
      IF rep_company IS NULL OR rep_company<>NEW.company_id THEN RAISE EXCEPTION 'Run-line sales representative does not belong to company'; END IF;
    END IF;
    IF NEW.branch_id IS NOT NULL THEN
      SELECT company_id INTO branch_company FROM public.branches WHERE id=NEW.branch_id;
      IF branch_company IS NULL OR branch_company<>NEW.company_id THEN RAISE EXCEPTION 'Run-line branch does not belong to company'; END IF;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_sales_target_assignment_integrity ON public.sales_target_assignments;
CREATE TRIGGER trg_sales_target_assignment_integrity BEFORE INSERT OR UPDATE ON public.sales_target_assignments FOR EACH ROW EXECUTE FUNCTION public.sales_target_integrity_guard();
DROP TRIGGER IF EXISTS trg_sales_target_run_line_integrity ON public.sales_target_run_lines;
CREATE TRIGGER trg_sales_target_run_line_integrity BEFORE INSERT OR UPDATE ON public.sales_target_run_lines FOR EACH ROW EXECUTE FUNCTION public.sales_target_integrity_guard();

CREATE OR REPLACE FUNCTION public.sales_target_dashboard_atomic(p_company_id uuid,p_plan_id uuid,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp' AS $function$
DECLARE actor public.users%ROWTYPE; plan_row public.sales_target_plans%ROWTYPE; assignments jsonb:='[]'::jsonb; ranking jsonb:='[]'::jsonb; trend jsonb:='[]'::jsonb; total_target_amount numeric:=0; total_actual_amount numeric:=0; total_target_qty numeric:=0; total_actual_qty numeric:=0; total_target_gp numeric:=0; total_actual_gp numeric:=0;
BEGIN
  SELECT * INTO actor FROM public.users WHERE company_id=p_company_id AND lower(email)=lower(p_user_email) AND coalesce(status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'Authenticated company context invalid'; END IF;
  IF NOT (coalesce(actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_manager"]'::jsonb OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_supervisor"]'::jsonb OR coalesce(actor.permissions,'[]'::jsonb) @> '["general_manager"]'::jsonb OR coalesce(actor.permissions,'[]'::jsonb) @> '["reports"]'::jsonb) THEN RAISE EXCEPTION 'Sales target read permission required'; END IF;
  SELECT * INTO plan_row FROM public.sales_target_plans WHERE id=p_plan_id AND company_id=p_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Target plan not found'; END IF;

  SELECT coalesce(jsonb_agg(to_jsonb(z) ORDER BY z.achievement_pct DESC,z.sales_rep_name), '[]'::jsonb) INTO assignments
  FROM (
    SELECT a.id,a.sales_rep_id,a.branch_id,u.name AS sales_rep_name,b.name AS branch_name,a.target_amount,a.target_qty,a.target_gross_profit,a.weight,a.active,
      coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN od.unit_price*greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0) actual_amount,
      coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0) actual_qty,
      coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN (od.unit_price-coalesce(i.cost_price,0))*greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0) actual_gp,
      CASE plan_row.metric
        WHEN 'amount' THEN CASE WHEN a.target_amount>0 THEN coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN od.unit_price*greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0)/a.target_amount*100 ELSE 0 END
        WHEN 'qty' THEN CASE WHEN a.target_qty>0 THEN coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0)/a.target_qty*100 ELSE 0 END
        WHEN 'gross_profit' THEN CASE WHEN a.target_gross_profit>0 THEN coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN (od.unit_price-coalesce(i.cost_price,0))*greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0)/a.target_gross_profit*100 ELSE 0 END
        ELSE ((CASE WHEN a.target_amount>0 THEN coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN od.unit_price*greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0)/a.target_amount*100 ELSE 0 END)+(CASE WHEN a.target_qty>0 THEN coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0)/a.target_qty*100 ELSE 0 END)+(CASE WHEN a.target_gross_profit>0 THEN coalesce(sum(CASE WHEN o.order_status='Invoiced' THEN (od.unit_price-coalesce(i.cost_price,0))*greatest(od.qty-coalesce(od.qty_returned,0),0) ELSE 0 END),0)/a.target_gross_profit*100 ELSE 0 END))/3
      END achievement_pct
    FROM public.sales_target_assignments a
    LEFT JOIN public.users u ON u.id=a.sales_rep_id
    LEFT JOIN public.branches b ON b.id=a.branch_id
    LEFT JOIN public.orders o ON o.company_id=p_company_id AND o.order_date BETWEEN plan_row.period_start AND plan_row.period_end AND (a.sales_rep_id IS NULL OR o.sales_rep_id=a.sales_rep_id) AND (a.branch_id IS NULL OR o.branch_id=a.branch_id)
    LEFT JOIN public.order_details od ON od.order_id=o.id
    LEFT JOIN public.items i ON i.id=od.item_id
    WHERE a.company_id=p_company_id AND a.plan_id=p_plan_id
    GROUP BY a.id,a.sales_rep_id,a.branch_id,u.name,b.name,a.target_amount,a.target_qty,a.target_gross_profit,a.weight,a.active,plan_row.metric
  ) z;

  SELECT coalesce(sum((v->>'target_amount')::numeric),0),coalesce(sum((v->>'actual_amount')::numeric),0),coalesce(sum((v->>'target_qty')::numeric),0),coalesce(sum((v->>'actual_qty')::numeric),0),coalesce(sum((v->>'target_gross_profit')::numeric),0),coalesce(sum((v->>'actual_gp')::numeric),0) INTO total_target_amount,total_actual_amount,total_target_qty,total_actual_qty,total_target_gp,total_actual_gp FROM jsonb_array_elements(assignments) v;

  SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.actual_amount DESC,r.rep_name), '[]'::jsonb) INTO ranking
  FROM (
    SELECT coalesce(u.name,u.email,'غير محدد') rep_name,a.sales_rep_id,sum(a.target_amount) target_amount,sum(a.actual_amount) actual_amount,sum(a.target_qty) target_qty,sum(a.actual_qty) actual_qty,sum(a.target_gross_profit) target_gp,sum(a.actual_gp) actual_gp,avg(a.achievement_pct) achievement_pct
    FROM jsonb_to_recordset(assignments) AS a(sales_rep_id uuid,target_amount numeric,actual_amount numeric,target_qty numeric,actual_qty numeric,target_gross_profit numeric,actual_gp numeric,achievement_pct numeric)
    LEFT JOIN public.users u ON u.id=a.sales_rep_id WHERE a.sales_rep_id IS NOT NULL GROUP BY a.sales_rep_id,u.name,u.email
  ) r;

  SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY t.metric_day), '[]'::jsonb) INTO trend
  FROM (
    SELECT o.order_date AS metric_day,coalesce(sum(od.unit_price*greatest(od.qty-coalesce(od.qty_returned,0),0)),0) actual_amount,coalesce(sum(greatest(od.qty-coalesce(od.qty_returned,0),0)),0) actual_qty
    FROM public.orders o JOIN public.order_details od ON od.order_id=o.id
    WHERE o.company_id=p_company_id AND o.order_status='Invoiced' AND o.order_date BETWEEN plan_row.period_start AND plan_row.period_end
    GROUP BY o.order_date
  ) t;

  RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row),'assignments',assignments,'totals',jsonb_build_object('target_amount',total_target_amount,'actual_amount',total_actual_amount,'target_qty',total_target_qty,'actual_qty',total_actual_qty,'target_gp',total_target_gp,'actual_gp',total_actual_gp,'amount_pct',CASE WHEN total_target_amount>0 THEN total_actual_amount/total_target_amount*100 ELSE 0 END,'qty_pct',CASE WHEN total_target_qty>0 THEN total_actual_qty/total_target_qty*100 ELSE 0 END,'gp_pct',CASE WHEN total_target_gp>0 THEN total_actual_gp/total_target_gp*100 ELSE 0 END),'ranking',ranking,'trend',trend);
END;
$function$;

REVOKE ALL ON FUNCTION public.sales_target_dashboard_atomic(uuid,uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_dashboard_atomic(uuid,uuid,text) TO service_role;

COMMIT;
