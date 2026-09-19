-- RAWAEA ERP — Sales Management Center recent-orders period integrity
-- Canonical Production closure. No business-contract change; fixes period leakage only.

BEGIN;

CREATE OR REPLACE FUNCTION public.sales_management_center_read(p_company_id uuid, p_actor_email text, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  d_from date := COALESCE(p_from_date,date_trunc('month',CURRENT_DATE)::date);
  d_to date := COALESCE(p_to_date,CURRENT_DATE);
  actor public.users%ROWTYPE;
  result jsonb;
BEGIN
  IF current_user<>'postgres' AND COALESCE(auth.role(),'')<>'service_role' THEN
    IF auth.uid() IS NULL THEN
      RAISE EXCEPTION 'Authentication required';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.auth_id=auth.uid()
        AND u.company_id=p_company_id
        AND lower(u.email)=lower(COALESCE(p_actor_email,''))
        AND COALESCE(u.status,'Active')='Active'
    ) THEN
      RAISE EXCEPTION 'Authenticated company context invalid';
    END IF;
  END IF;

  SELECT *
    INTO actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(COALESCE(p_actor_email,''))
    AND COALESCE(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Authenticated sales management context invalid';
  END IF;

  IF NOT public.sales_decision_actor_ok(p_company_id,p_actor_email,false) THEN
    RAISE EXCEPTION 'Sales management read permission required';
  END IF;

  SELECT jsonb_build_object(
    'success',true,
    'period',jsonb_build_object('from',d_from,'to',d_to),

    'orders',(
      SELECT jsonb_build_object(
        'total',count(*),
        'draft',count(*) FILTER (WHERE o.order_status='Draft'),
        'confirmed',count(*) FILTER (WHERE o.order_status='Confirmed'),
        'pending',count(*) FILTER (WHERE o.order_status='Pending'),
        'invoiced',count(*) FILTER (WHERE o.order_status='Invoiced'),
        'delivered',count(*) FILTER (WHERE o.order_status='Delivered'),
        'cancelled',count(*) FILTER (WHERE o.order_status='Cancelled'),
        'sales_value',COALESCE(sum(o.total_amount) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0),
        'outstanding',COALESCE(sum(GREATEST(o.total_amount-COALESCE(o.amount_paid,0),0)) FILTER (WHERE o.order_status IN('Invoiced','Delivered','Confirmed')),0)
      )
      FROM public.orders o
      WHERE o.company_id=p_company_id AND o.order_date BETWEEN d_from AND d_to
    ),

    'quotes',(
      SELECT jsonb_build_object(
        'total',count(*),
        'draft',count(*) FILTER (WHERE q.status='Draft'),
        'sent',count(*) FILTER (WHERE q.status='Sent'),
        'accepted',count(*) FILTER (WHERE q.status='Accepted'),
        'rejected',count(*) FILTER (WHERE q.status='Rejected'),
        'expired',count(*) FILTER (WHERE q.status='Expired'),
        'converted',count(*) FILTER (WHERE q.status='Converted'),
        'won_value',COALESCE(sum(q.total_amount) FILTER (WHERE q.status IN('Accepted','Converted')),0)
      )
      FROM public.sales_quotes q
      WHERE q.company_id=p_company_id AND q.quote_date BETWEEN d_from AND d_to
    ),

    'returns',(
      SELECT jsonb_build_object(
        'total',count(*),
        'open',count(*) FILTER (WHERE COALESCE(rr.status,'open')='open'),
        'reviewing',count(*) FILTER (WHERE rr.status='reviewing'),
        'resolved',count(*) FILTER (WHERE rr.status='resolved'),
        'disputed',count(*) FILTER (WHERE rr.status='disputed'),
        'cancelled',count(*) FILTER (WHERE rr.status='cancelled'),
        'value',COALESCE(sum(cn.total_amount),0),
        'posted_value',COALESCE(sum(cn.total_amount) FILTER (WHERE cn.status='Posted'),0)
      )
      FROM public.credit_notes cn
      LEFT JOIN public.sales_return_reviews rr ON rr.credit_note_id=cn.id AND rr.company_id=cn.company_id
      WHERE cn.company_id=p_company_id AND cn.cn_date BETWEEN d_from AND d_to
    ),

    'payments',(
      SELECT jsonb_build_object(
        'receipt_count',count(*),
        'value',COALESCE(sum(r.amount),0),
        'allocated',COALESCE(sum(r.allocated_amount),0),
        'unallocated',COALESCE(sum(r.unallocated_amount),0)
      )
      FROM public.sales_payment_receipts r
      WHERE r.company_id=p_company_id AND r.receipt_date BETWEEN d_from AND d_to
    ),

    'runsheets',(
      SELECT jsonb_build_object(
        'total',count(*),
        'draft',count(*) FILTER (WHERE r.status='Draft'),
        'picking',count(*) FILTER (WHERE r.status='Picking'),
        'loading',count(*) FILTER (WHERE r.status='Loading'),
        'delivering',count(*) FILTER (WHERE r.status='Delivering'),
        'returning',count(*) FILTER (WHERE r.status='Returning'),
        'completed',count(*) FILTER (WHERE r.status IN('Completed','Closed'))
      )
      FROM public.runsheets r
      WHERE r.company_id=p_company_id AND r.run_date BETWEEN d_from AND d_to
    ),

    'decision_center',(
      SELECT jsonb_build_object(
        'evaluations',count(*),
        'blocked',count(*) FILTER (WHERE e.decision='BLOCK'),
        'approval_required',count(*) FILTER (WHERE e.decision='REQUIRE_APPROVAL'),
        'approved',count(*) FILTER (WHERE e.decision='ALLOW')
      )
      FROM public.sales_decision_evaluations e
      WHERE e.company_id=p_company_id AND e.created_at::date BETWEEN d_from AND d_to
    ),

    'commercial',(
      SELECT jsonb_build_object(
        'active_price_lists',(SELECT count(*) FROM public.commercial_catalogs c WHERE c.company_id=p_company_id AND c.is_active=true AND (c.valid_from IS NULL OR c.valid_from<=d_to) AND (c.valid_until IS NULL OR c.valid_until>=d_from)),
        'active_promotions',(SELECT count(*) FROM public.promotions p WHERE p.company_id=p_company_id AND p.is_active=true AND (p.valid_from IS NULL OR p.valid_from<=d_to) AND (p.valid_until IS NULL OR p.valid_until>=d_from)),
        'promotion_redemptions',(SELECT count(*) FROM public.promotion_redemptions pr WHERE pr.company_id=p_company_id AND pr.created_at::date BETWEEN d_from AND d_to),
        'price_list_assignments',(SELECT count(*) FROM public.commercial_customer_links l WHERE l.company_id=p_company_id)
      )
    ),

    'targets',(
      SELECT jsonb_build_object(
        'plans',count(*),
        'approved',count(*) FILTER (WHERE sp.status='Approved'),
        'closed',count(*) FILTER (WHERE sp.status='Closed')
      )
      FROM public.sales_target_plans sp
      WHERE sp.company_id=p_company_id
        AND sp.period_end>=d_from
        AND sp.period_start<=d_to
    ),

    'channels',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sales_value DESC),'[]'::jsonb)
      FROM (
        SELECT COALESCE(NULLIF(o.source,''),'unknown') channel,
               count(*) total_orders,
               COALESCE(sum(o.total_amount) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) sales_value
        FROM public.orders o
        WHERE o.company_id=p_company_id AND o.order_date BETWEEN d_from AND d_to
        GROUP BY COALESCE(NULLIF(o.source,''),'unknown')
      ) x
    ),

    'top_reps',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sales_value DESC,x.rep_name),'[]'::jsonb)
      FROM (
        SELECT COALESCE(o.sales_rep_name,o.created_by,'غير محدد') rep_name,
               COALESCE(sum(o.total_amount) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) sales_value,
               count(*) total_orders
        FROM public.orders o
        WHERE o.company_id=p_company_id AND o.order_date BETWEEN d_from AND d_to
        GROUP BY COALESCE(o.sales_rep_name,o.created_by,'غير محدد')
        ORDER BY sales_value DESC,rep_name
        LIMIT 10
      ) x
    ),

    'top_items',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sales_value DESC,x.item_code),'[]'::jsonb)
      FROM (
        SELECT od.item_id,
               od.item_code,
               COALESCE(od.item_name,i.name,od.item_code) item_name,
               COALESCE(sum(GREATEST(od.qty-COALESCE(od.qty_returned,0),0)) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) net_qty,
               COALESCE(sum(
                 GREATEST(od.qty-COALESCE(od.qty_returned,0),0) * COALESCE(od.unit_price,0)
               ) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) sales_value
        FROM public.order_details od
        JOIN public.orders o ON o.id=od.order_id AND o.company_id=p_company_id
        LEFT JOIN public.items i ON i.id=od.item_id
        WHERE o.order_date BETWEEN d_from AND d_to
          AND o.company_id=p_company_id
        GROUP BY od.item_id,od.item_code,COALESCE(od.item_name,i.name,od.item_code)
        ORDER BY sales_value DESC,od.item_code
        LIMIT 10
      ) x
    ),

    'top_customers',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sales_value DESC,x.customer_name),'[]'::jsonb)
      FROM (
        SELECT o.customer_id,
               COALESCE(o.customer_name,'غير محدد') customer_name,
               count(*) total_orders,
               COALESCE(sum(o.total_amount) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) sales_value,
               COALESCE(sum(GREATEST(o.total_amount-COALESCE(o.amount_paid,0),0)) FILTER (WHERE o.order_status IN('Invoiced','Delivered','Confirmed')),0) outstanding
        FROM public.orders o
        WHERE o.company_id=p_company_id AND o.order_date BETWEEN d_from AND d_to
        GROUP BY o.customer_id,COALESCE(o.customer_name,'غير محدد')
        ORDER BY sales_value DESC,customer_name
        LIMIT 10
      ) x
    ),

    'branch_sales',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sales_value DESC,x.branch_name),'[]'::jsonb)
      FROM (
        SELECT o.branch_id,
               COALESCE(b.name,'غير محدد') branch_name,
               count(*) total_orders,
               COALESCE(sum(o.total_amount) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) sales_value
        FROM public.orders o
        LEFT JOIN public.branches b ON b.id=o.branch_id AND b.company_id=p_company_id
        WHERE o.company_id=p_company_id AND o.order_date BETWEEN d_from AND d_to
        GROUP BY o.branch_id,COALESCE(b.name,'غير محدد')
        ORDER BY sales_value DESC,branch_name
      ) x
    ),

    'payment_mix',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sales_value DESC,x.payment_type),'[]'::jsonb)
      FROM (
        SELECT COALESCE(NULLIF(o.payment_type,''),'غير محدد') payment_type,
               count(*) total_orders,
               COALESCE(sum(o.total_amount) FILTER (WHERE o.order_status IN('Invoiced','Delivered')),0) sales_value,
               COALESCE(sum(o.amount_paid),0) paid_amount
        FROM public.orders o
        WHERE o.company_id=p_company_id AND o.order_date BETWEEN d_from AND d_to
        GROUP BY COALESCE(NULLIF(o.payment_type,''),'غير محدد')
        ORDER BY sales_value DESC,payment_type
      ) x
    ),

    'recent_orders',(
      SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.order_date DESC,x.created_at DESC),'[]'::jsonb)
      FROM (
        SELECT o.id,o.order_code,o.order_date,o.customer_name,o.total_amount,o.amount_paid,o.order_status,o.payment_type,o.source,o.sales_rep_name,o.branch_id,o.runsheet_id,o.created_at
        FROM public.orders o
        WHERE o.company_id=p_company_id
          AND o.order_date BETWEEN d_from AND d_to
        ORDER BY o.order_date DESC,o.created_at DESC,o.id DESC
        LIMIT 25
      ) x
    )
  ) INTO result;

  RETURN result;
END;
$function$


COMMIT;
