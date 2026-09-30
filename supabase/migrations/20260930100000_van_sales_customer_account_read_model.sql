-- Van Sales customer-account read capability
-- Production-applied migration: van_sales_customer_account_read_model_v2
-- No Edge Function added.

CREATE OR REPLACE FUNCTION public.get_van_sales_customer_account(
  p_customer_id uuid DEFAULT NULL,
  p_search text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $function$
DECLARE
  v_user public.users%ROWTYPE;
  v_company_id uuid;
  v_customer public.customers%ROWTYPE;
  v_is_allowed boolean := false;
  v_search text := lower(nullif(btrim(coalesce(p_search,'')), ''));
  v_total_debit numeric := 0;
  v_total_credit numeric := 0;
  v_balance numeric := 0;
  v_overdue numeric := 0;
  v_installment_remaining numeric := 0;
BEGIN
  SELECT * INTO v_user
  FROM public.users
  WHERE auth_id=auth.uid()
    AND coalesce(status,'Active')<>'Inactive'
  ORDER BY id
  LIMIT 1;

  IF NOT FOUND OR v_user.company_id IS NULL THEN
    RAISE EXCEPTION 'VAN_SALES_USER_COMPANY_CONTEXT_INVALID';
  END IF;

  v_company_id := v_user.company_id;

  IF NOT app_private.current_user_has_permission('van-sales') THEN
    RAISE EXCEPTION 'VAN_SALES_PERMISSION_REQUIRED';
  END IF;

  IF p_customer_id IS NULL THEN
    RETURN (
      SELECT jsonb_build_object(
        'success',true,
        'mode','list',
        'company_id',v_company_id,
        'customer_count',count(*),
        'total_debt',round(coalesce(sum(x.balance),0),2),
        'customers',coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.balance DESC,x.customer_name),'[]'::jsonb)
      )
      FROM (
        SELECT
          c.id AS customer_id,
          c.customer_code,
          c.name AS customer_name,
          c.phone,
          c.area,
          c.payment_type,
          round(coalesce((SELECT sum(coalesce(cl.debit,0)) FROM public.customer_ledger cl WHERE cl.customer_id=c.id),0),2) AS total_debit,
          round(coalesce((SELECT sum(coalesce(cl.credit,0)) FROM public.customer_ledger cl WHERE cl.customer_id=c.id),0),2) AS total_credit,
          round(coalesce((SELECT sum(coalesce(cl.debit,0)-coalesce(cl.credit,0)) FROM public.customer_ledger cl WHERE cl.customer_id=c.id),0),2) AS balance,
          round(coalesce((SELECT sum(coalesce(cl.debit,0)-coalesce(cl.credit,0)) FROM public.customer_ledger cl WHERE cl.customer_id=c.id AND cl.due_date IS NOT NULL AND cl.due_date<current_date),0),2) AS overdue_amount,
          (SELECT max(o.order_date) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=c.id AND coalesce(o.order_status,'')<>'Cancelled') AS last_invoice_date,
          (SELECT max(spr.receipt_date) FROM public.sales_payment_receipts spr WHERE spr.company_id=v_company_id AND spr.customer_id=c.id AND coalesce(spr.status,'Active')<>'Cancelled') AS last_payment_date
        FROM public.customers c
        WHERE c.company_id=v_company_id
          AND coalesce(c.is_active,true)=true
          AND (
            coalesce(v_user.allow_all_customers,false)=true
            OR EXISTS (SELECT 1 FROM public.customer_assignments ca WHERE ca.user_id=v_user.id AND ca.customer_id=c.id AND coalesce(ca.is_active,true)=true)
          )
          AND (
            v_search IS NULL
            OR lower(coalesce(c.name,'')) LIKE '%'||v_search||'%'
            OR lower(coalesce(c.customer_code,'')) LIKE '%'||v_search||'%'
            OR lower(coalesce(c.phone,'')) LIKE '%'||v_search||'%'
            OR lower(coalesce(c.area,'')) LIKE '%'||v_search||'%'
          )
          AND coalesce((SELECT sum(coalesce(cl.debit,0)-coalesce(cl.credit,0)) FROM public.customer_ledger cl WHERE cl.customer_id=c.id),0)>0
      ) x
    );
  END IF;

  SELECT * INTO v_customer
  FROM public.customers
  WHERE id=p_customer_id
    AND company_id=v_company_id
    AND coalesce(is_active,true)=true
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'VAN_SALES_CUSTOMER_NOT_FOUND_OR_WRONG_COMPANY';
  END IF;

  IF NOT coalesce(v_user.allow_all_customers,false) THEN
    SELECT EXISTS (
      SELECT 1 FROM public.customer_assignments ca
      WHERE ca.user_id=v_user.id
        AND ca.customer_id=v_customer.id
        AND coalesce(ca.is_active,true)=true
    ) INTO v_is_allowed;
    IF NOT v_is_allowed THEN
      RAISE EXCEPTION 'VAN_SALES_CUSTOMER_NOT_ASSIGNED';
    END IF;
  END IF;

  SELECT coalesce(sum(coalesce(cl.debit,0)),0), coalesce(sum(coalesce(cl.credit,0)),0)
  INTO v_total_debit,v_total_credit
  FROM public.customer_ledger cl
  WHERE cl.customer_id=v_customer.id;

  v_balance:=v_total_debit-v_total_credit;

  SELECT coalesce(sum(coalesce(cl.debit,0)-coalesce(cl.credit,0)),0)
  INTO v_overdue
  FROM public.customer_ledger cl
  WHERE cl.customer_id=v_customer.id
    AND cl.due_date IS NOT NULL
    AND cl.due_date<current_date;

  SELECT coalesce(sum(coalesce(i.remaining_amount,0)),0)
  INTO v_installment_remaining
  FROM public.installment_aging_v i
  WHERE i.company_id=v_company_id
    AND i.customer_id=v_customer.id
    AND coalesce(i.remaining_amount,0)>0;

  RETURN jsonb_build_object(
    'success',true,
    'mode','account',
    'company_id',v_company_id,
    'customer',jsonb_build_object(
      'id',v_customer.id,
      'customer_code',v_customer.customer_code,
      'name',v_customer.name,
      'phone',v_customer.phone,
      'area',v_customer.area,
      'payment_type',v_customer.payment_type
    ),
    'summary',jsonb_build_object(
      'total_debit',round(v_total_debit,2),
      'total_credit',round(v_total_credit,2),
      'balance',round(v_balance,2),
      'overdue_amount',round(v_overdue,2),
      'installment_remaining',round(v_installment_remaining,2)
    ),
    'invoices',coalesce((
      SELECT jsonb_agg(jsonb_build_object(
        'id',o.id,'order_code',o.order_code,'order_date',o.order_date,
        'order_status',o.order_status,'payment_type',o.payment_type,
        'total_amount',o.total_amount,'source',o.source
      ) ORDER BY o.order_date DESC,o.created_at DESC)
      FROM public.orders o
      WHERE o.company_id=v_company_id AND o.customer_id=v_customer.id AND coalesce(o.order_status,'')<>'Cancelled'
    ),'[]'::jsonb),
    'ledger',coalesce((
      SELECT jsonb_agg(jsonb_build_object(
        'id',cl.id,'entry_date',cl.entry_date,'reference',cl.reference,
        'description',cl.description,'debit',cl.debit,'credit',cl.credit,
        'balance',cl.balance,'due_date',cl.due_date,'user_email',cl.user_email
      ) ORDER BY cl.entry_date DESC,cl.created_at DESC)
      FROM public.customer_ledger cl
      WHERE cl.customer_id=v_customer.id
    ),'[]'::jsonb),
    'payments',coalesce((
      SELECT jsonb_agg(jsonb_build_object(
        'id',spr.id,'receipt_code',spr.receipt_code,'receipt_date',spr.receipt_date,
        'amount',spr.amount,'allocated_amount',spr.allocated_amount,
        'unallocated_amount',spr.unallocated_amount,'reference',spr.reference,
        'notes',spr.notes,'status',spr.status,'created_by',spr.created_by
      ) ORDER BY spr.receipt_date DESC,spr.created_at DESC)
      FROM public.sales_payment_receipts spr
      WHERE spr.company_id=v_company_id AND spr.customer_id=v_customer.id AND coalesce(spr.status,'Active')<>'Cancelled'
    ),'[]'::jsonb),
    'installments',coalesce((
      SELECT jsonb_agg(to_jsonb(i) ORDER BY i.next_due_date NULLS LAST)
      FROM public.installment_aging_v i
      WHERE i.company_id=v_company_id AND i.customer_id=v_customer.id AND coalesce(i.remaining_amount,0)>0
    ),'[]'::jsonb)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_van_sales_customer_account(uuid,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_van_sales_customer_account(uuid,text) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_van_sales_customer_account(uuid,text) TO authenticated;
