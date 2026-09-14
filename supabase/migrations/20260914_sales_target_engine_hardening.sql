BEGIN;

CREATE OR REPLACE FUNCTION public.sales_target_engine_atomic(
  p_company_id uuid,
  p_operation text,
  p_user_email text,
  p_plan_id uuid DEFAULT NULL,
  p_payload jsonb DEFAULT '{}'::jsonb,
  p_operation_id text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  actor public.users%ROWTYPE;
  plan_row public.sales_target_plans%ROWTYPE;
  ass public.sales_target_assignments%ROWTYPE;
  run_row public.sales_target_runs%ROWTYPE;
  r numeric; q numeric; gp numeric; target numeric; ach numeric; metric text;
  can_manage boolean;
  can_approve boolean;
  op text:=upper(btrim(coalesce(p_operation,'')));
  assignment_id uuid;
BEGIN
  SELECT * INTO actor FROM public.users
  WHERE company_id=p_company_id AND lower(email)=lower(p_user_email) AND coalesce(status,'Active')='Active'
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'Authenticated company context invalid'; END IF;

  can_manage := coalesce(actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
             OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_manager"]'::jsonb
             OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_supervisor"]'::jsonb
             OR coalesce(actor.permissions,'[]'::jsonb) @> '["general_manager"]'::jsonb;
  can_approve := coalesce(actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
              OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_manager"]'::jsonb
              OR coalesce(actor.permissions,'[]'::jsonb) @> '["general_manager"]'::jsonb;
  IF op IN('SAVE_PLAN','SAVE_ASSIGNMENT') AND NOT can_manage THEN RAISE EXCEPTION 'Sales target management permission required'; END IF;
  IF op IN('APPROVE_PLAN','CLOSE_PLAN','CANCEL_PLAN','APPROVE_RUN','REVERSE_RUN') AND NOT can_approve THEN RAISE EXCEPTION 'Sales target approval permission required'; END IF;

  IF op='LIST_PLANS' THEN
    RETURN jsonb_build_object('success',true,'plans',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.period_start DESC,x.created_at DESC) FROM (SELECT * FROM public.sales_target_plans WHERE company_id=p_company_id) x),'[]'::jsonb));
  END IF;
  IF op='LIST_ASSIGNMENTS' THEN
    IF p_plan_id IS NULL THEN RAISE EXCEPTION 'plan_id required'; END IF;
    RETURN jsonb_build_object('success',true,'assignments',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.id) FROM (SELECT * FROM public.sales_target_assignments WHERE company_id=p_company_id AND plan_id=p_plan_id) x),'[]'::jsonb));
  END IF;
  IF op='LIST_RUNS' THEN
    RETURN jsonb_build_object('success',true,'runs',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.evaluated_at DESC) FROM (SELECT * FROM public.sales_target_runs WHERE company_id=p_company_id ORDER BY evaluated_at DESC) x),'[]'::jsonb));
  END IF;

  IF op='SAVE_PLAN' THEN
    IF p_plan_id IS NULL THEN
      IF NULLIF(btrim(p_payload->>'plan_code'),'') IS NULL THEN RAISE EXCEPTION 'plan_code required'; END IF;
      IF NULLIF(btrim(p_payload->>'period_start'),'') IS NULL OR NULLIF(btrim(p_payload->>'period_end'),'') IS NULL THEN RAISE EXCEPTION 'Target period required'; END IF;
      IF (p_payload->>'period_end')::date < (p_payload->>'period_start')::date THEN RAISE EXCEPTION 'Target period is invalid'; END IF;
      IF coalesce(p_payload->>'metric','amount') NOT IN('amount','qty','gross_profit','mixed') THEN RAISE EXCEPTION 'Unsupported target metric'; END IF;
      INSERT INTO public.sales_target_plans(company_id,plan_code,name,period_start,period_end,metric,status,notes,created_by)
      VALUES(p_company_id,btrim(p_payload->>'plan_code'),coalesce(nullif(btrim(p_payload->>'name'),''),btrim(p_payload->>'plan_code')),(p_payload->>'period_start')::date,(p_payload->>'period_end')::date,coalesce(p_payload->>'metric','amount'),'Draft',p_payload->>'notes',p_user_email)
      RETURNING * INTO plan_row;
    ELSE
      UPDATE public.sales_target_plans
      SET name=coalesce(nullif(btrim(p_payload->>'name'),''),name),
          period_start=coalesce(nullif(p_payload->>'period_start','')::date,period_start),
          period_end=coalesce(nullif(p_payload->>'period_end','')::date,period_end),
          metric=coalesce(nullif(p_payload->>'metric',''),metric),
          notes=coalesce(p_payload->>'notes',notes),updated_at=now()
      WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft'
      RETURNING * INTO plan_row;
      IF NOT FOUND THEN RAISE EXCEPTION 'Draft target plan not found'; END IF;
      IF plan_row.period_end<plan_row.period_start THEN RAISE EXCEPTION 'Target period is invalid'; END IF;
    END IF;
    RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row));
  END IF;

  IF op='SAVE_ASSIGNMENT' THEN
    IF NOT EXISTS(SELECT 1 FROM public.sales_target_plans WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft') THEN RAISE EXCEPTION 'Draft target plan required'; END IF;
    assignment_id:=NULLIF(p_payload->>'id','')::uuid;
    IF assignment_id IS NULL THEN
      INSERT INTO public.sales_target_assignments(company_id,plan_id,sales_rep_id,branch_id,target_amount,target_qty,target_gross_profit,weight,active,notes,created_by)
      VALUES(p_company_id,p_plan_id,NULLIF(p_payload->>'sales_rep_id','')::uuid,NULLIF(p_payload->>'branch_id','')::uuid,coalesce((p_payload->>'target_amount')::numeric,0),coalesce((p_payload->>'target_qty')::numeric,0),coalesce((p_payload->>'target_gross_profit')::numeric,0),coalesce((p_payload->>'weight')::numeric,100),coalesce((p_payload->>'active')::boolean,true),p_payload->>'notes',p_user_email)
      RETURNING * INTO ass;
    ELSE
      UPDATE public.sales_target_assignments
      SET sales_rep_id=NULLIF(p_payload->>'sales_rep_id','')::uuid,
          branch_id=NULLIF(p_payload->>'branch_id','')::uuid,
          target_amount=coalesce((p_payload->>'target_amount')::numeric,target_amount),
          target_qty=coalesce((p_payload->>'target_qty')::numeric,target_qty),
          target_gross_profit=coalesce((p_payload->>'target_gross_profit')::numeric,target_gross_profit),
          weight=coalesce((p_payload->>'weight')::numeric,weight),
          active=coalesce((p_payload->>'active')::boolean,active),
          notes=coalesce(p_payload->>'notes',notes),updated_at=now()
      WHERE id=assignment_id AND company_id=p_company_id AND plan_id=p_plan_id
      RETURNING * INTO ass;
      IF NOT FOUND THEN RAISE EXCEPTION 'Target assignment not found'; END IF;
    END IF;
    RETURN jsonb_build_object('success',true,'assignment',to_jsonb(ass));
  END IF;

  IF op='APPROVE_PLAN' THEN
    IF NOT EXISTS(SELECT 1 FROM public.sales_target_assignments WHERE plan_id=p_plan_id AND company_id=p_company_id AND active=true) THEN RAISE EXCEPTION 'At least one active target assignment is required'; END IF;
    UPDATE public.sales_target_plans SET status='Approved',approved_by=p_user_email,approved_at=now(),updated_at=now()
    WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft' RETURNING * INTO plan_row;
    IF NOT FOUND THEN RAISE EXCEPTION 'Draft target plan not found'; END IF;
    RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row));
  END IF;

  IF op='CLOSE_PLAN' THEN
    UPDATE public.sales_target_plans SET status='Closed',closed_by=p_user_email,closed_at=now(),updated_at=now()
    WHERE id=p_plan_id AND company_id=p_company_id AND status='Approved' RETURNING * INTO plan_row;
    IF NOT FOUND THEN RAISE EXCEPTION 'Approved target plan not found'; END IF;
    RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row));
  END IF;

  IF op='CANCEL_PLAN' THEN
    UPDATE public.sales_target_plans SET status='Cancelled',updated_at=now()
    WHERE id=p_plan_id AND company_id=p_company_id AND status='Draft' RETURNING * INTO plan_row;
    IF NOT FOUND THEN RAISE EXCEPTION 'Only Draft target plans can be cancelled'; END IF;
    RETURN jsonb_build_object('success',true,'plan',to_jsonb(plan_row));
  END IF;

  IF op IN('PREVIEW','POST') THEN
    SELECT * INTO plan_row FROM public.sales_target_plans WHERE id=p_plan_id AND company_id=p_company_id;
    IF NOT FOUND OR plan_row.status NOT IN('Approved','Closed') THEN RAISE EXCEPTION 'Approved or Closed target plan required'; END IF;
    IF op='POST' THEN
      IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'operation_id required'; END IF;
      SELECT * INTO run_row FROM public.sales_target_runs WHERE company_id=p_company_id AND operation_id=p_operation_id FOR UPDATE;
      IF FOUND THEN RETURN jsonb_build_object('success',true,'duplicate',true,'run',to_jsonb(run_row)); END IF;
    END IF;
    INSERT INTO public.sales_target_runs(company_id,plan_id,operation_id,status,created_by)
    VALUES(p_company_id,p_plan_id,coalesce(nullif(p_operation_id,''),'PREVIEW-'||gen_random_uuid()::text),CASE WHEN op='POST' THEN 'Posted' ELSE 'Preview' END,p_user_email)
    RETURNING * INTO run_row;

    FOR ass IN SELECT * FROM public.sales_target_assignments WHERE company_id=p_company_id AND plan_id=p_plan_id AND active=true ORDER BY id LOOP
      SELECT coalesce(sum(od.unit_price*greatest(od.qty-coalesce(od.qty_returned,0),0)),0),
             coalesce(sum(greatest(od.qty-coalesce(od.qty_returned,0),0)),0),
             coalesce(sum((od.unit_price-coalesce(i.cost_price,0))*greatest(od.qty-coalesce(od.qty_returned,0),0)),0)
      INTO r,q,gp
      FROM public.orders o
      JOIN public.order_details od ON od.order_id=o.id
      JOIN public.items i ON i.id=od.item_id
      WHERE o.company_id=p_company_id
        AND o.order_status='Invoiced'
        AND o.order_date BETWEEN plan_row.period_start AND plan_row.period_end
        AND (ass.sales_rep_id IS NULL OR o.sales_rep_id=ass.sales_rep_id)
        AND (ass.branch_id IS NULL OR o.branch_id=ass.branch_id);
      metric:=plan_row.metric;
      ach:=CASE metric
        WHEN 'amount' THEN CASE WHEN ass.target_amount>0 THEN r/ass.target_amount*100 ELSE 0 END
        WHEN 'qty' THEN CASE WHEN ass.target_qty>0 THEN q/ass.target_qty*100 ELSE 0 END
        WHEN 'gross_profit' THEN CASE WHEN ass.target_gross_profit>0 THEN gp/ass.target_gross_profit*100 ELSE 0 END
        ELSE (CASE WHEN ass.target_amount>0 THEN r/ass.target_amount*100 ELSE 0 END
             +CASE WHEN ass.target_qty>0 THEN q/ass.target_qty*100 ELSE 0 END
             +CASE WHEN ass.target_gross_profit>0 THEN gp/ass.target_gross_profit*100 ELSE 0 END)/3
      END;
      INSERT INTO public.sales_target_run_lines(company_id,run_id,assignment_id,sales_rep_id,branch_id,target_amount,actual_amount,target_qty,actual_qty,target_gross_profit,actual_gross_profit,achievement_amount_pct,achievement_qty_pct,achievement_gp_pct,primary_achievement_pct)
      VALUES(p_company_id,run_row.id,ass.id,ass.sales_rep_id,ass.branch_id,ass.target_amount,r,ass.target_qty,q,ass.target_gross_profit,gp,
             CASE WHEN ass.target_amount>0 THEN r/ass.target_amount*100 ELSE 0 END,
             CASE WHEN ass.target_qty>0 THEN q/ass.target_qty*100 ELSE 0 END,
             CASE WHEN ass.target_gross_profit>0 THEN gp/ass.target_gross_profit*100 ELSE 0 END,
             ach);
    END LOOP;
    UPDATE public.sales_target_runs z
    SET total_target_amount=(SELECT coalesce(sum(target_amount),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),
        total_actual_amount=(SELECT coalesce(sum(actual_amount),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),
        total_target_qty=(SELECT coalesce(sum(target_qty),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),
        total_actual_qty=(SELECT coalesce(sum(actual_qty),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),
        total_target_gp=(SELECT coalesce(sum(target_gross_profit),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id),
        total_actual_gp=(SELECT coalesce(sum(actual_gross_profit),0) FROM public.sales_target_run_lines WHERE run_id=run_row.id)
    WHERE z.id=run_row.id;
    RETURN jsonb_build_object('success',true,'run_id',run_row.id,'status',(SELECT status FROM public.sales_target_runs WHERE id=run_row.id));
  END IF;

  IF op='APPROVE_RUN' THEN
    UPDATE public.sales_target_runs SET status='Approved',approved_by=p_user_email,approved_at=now()
    WHERE id=p_plan_id AND company_id=p_company_id AND status='Posted' RETURNING * INTO run_row;
    IF NOT FOUND THEN RAISE EXCEPTION 'Posted target run not found'; END IF;
    RETURN jsonb_build_object('success',true,'run',to_jsonb(run_row));
  END IF;

  IF op='REVERSE_RUN' THEN
    SELECT * INTO run_row FROM public.sales_target_runs WHERE id=p_plan_id AND company_id=p_company_id AND status IN('Posted','Approved') FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Posted or Approved target run not found'; END IF;
    IF p_operation_id IS NULL OR btrim(p_operation_id)='' THEN RAISE EXCEPTION 'operation_id required'; END IF;
    UPDATE public.sales_target_runs SET status='Reversed' WHERE id=run_row.id AND company_id=p_company_id AND status IN('Posted','Approved');
    INSERT INTO public.sales_target_runs(company_id,plan_id,operation_id,status,created_by,reversal_of_run_id)
    VALUES(p_company_id,run_row.plan_id,p_operation_id,'Reversed',p_user_email,run_row.id)
    RETURNING * INTO run_row;
    RETURN jsonb_build_object('success',true,'run',to_jsonb(run_row));
  END IF;

  RAISE EXCEPTION 'Unsupported operation: %',op;
END;
$function$;

REVOKE ALL ON FUNCTION public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text) TO service_role;
REVOKE ALL ON FUNCTION public.sales_target_assignment_guard() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.sales_target_audit_trigger() FROM PUBLIC,anon,authenticated;

CREATE INDEX IF NOT EXISTS sales_target_assignments_plan_fk_idx ON public.sales_target_assignments(plan_id);
CREATE INDEX IF NOT EXISTS sales_target_assignments_rep_fk_idx ON public.sales_target_assignments(sales_rep_id);
CREATE INDEX IF NOT EXISTS sales_target_assignments_branch_fk_idx ON public.sales_target_assignments(branch_id);
CREATE INDEX IF NOT EXISTS sales_target_runs_plan_fk_idx ON public.sales_target_runs(plan_id);
CREATE INDEX IF NOT EXISTS sales_target_runs_reversal_fk_idx ON public.sales_target_runs(reversal_of_run_id);
CREATE INDEX IF NOT EXISTS sales_target_run_lines_assignment_fk_idx ON public.sales_target_run_lines(assignment_id);
CREATE INDEX IF NOT EXISTS sales_target_run_lines_rep_fk_idx ON public.sales_target_run_lines(sales_rep_id);
CREATE INDEX IF NOT EXISTS sales_target_run_lines_branch_fk_idx ON public.sales_target_run_lines(branch_id);

DROP POLICY IF EXISTS sales_target_plans_read ON public.sales_target_plans;
CREATE POLICY sales_target_plans_read ON public.sales_target_plans FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=(select auth.uid()) AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_plans.company_id));
DROP POLICY IF EXISTS sales_target_assignments_read ON public.sales_target_assignments;
CREATE POLICY sales_target_assignments_read ON public.sales_target_assignments FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=(select auth.uid()) AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_assignments.company_id));
DROP POLICY IF EXISTS sales_target_runs_read ON public.sales_target_runs;
CREATE POLICY sales_target_runs_read ON public.sales_target_runs FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=(select auth.uid()) AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_runs.company_id));
DROP POLICY IF EXISTS sales_target_run_lines_read ON public.sales_target_run_lines;
CREATE POLICY sales_target_run_lines_read ON public.sales_target_run_lines FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.users u WHERE u.auth_id=(select auth.uid()) AND coalesce(u.status,'Active')='Active' AND u.company_id=public.sales_target_run_lines.company_id));

COMMIT;
