-- Buyer RPC effective-permission hardening: no raw user.permissions wildcard bypass.
BEGIN;
CREATE OR REPLACE FUNCTION public.purchase_create_quick_market_invoice_atomic(
  p_company_id uuid,
  p_supplier_id uuid,
  p_branch_id uuid,
  p_due_date date,
  p_supplier_invoice_no text,
  p_notes text,
  p_items jsonb,
  p_settlement_source text,
  p_cash_custody_id uuid,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_currency text;
  v_result jsonb;
  v_total numeric(14,2) := 0;
  v_acknowledged numeric(14,2) := 0;
  v_committed numeric(14,2) := 0;
  v_reserved numeric(14,2) := 0;
  v_fingerprint text;
  v_count integer;
  x jsonb;
  v_item public.items%ROWTYPE;
  v_custody public.buyer_custodies%ROWTYPE;
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth_id=auth.uid()
    AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';
  IF NOT FOUND THEN RAISE EXCEPTION 'BUYER_AUTH_REQUIRED'; END IF;

  IF NOT app_private.current_user_has_effective_permission('purchases') THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('RAWAEA:QUICK-MARKET:'||p_company_id::text||':'||btrim(p_operation_id),0)
  );

  IF p_settlement_source IS NULL OR p_settlement_source NOT IN ('EMPLOYEE_CUSTODY','SUPPLIER_CREDIT') THEN
    RAISE EXCEPTION 'QUICK_MARKET_SETTLEMENT_SOURCE_INVALID';
  END IF;

  SELECT upper(nullif(btrim(currency),'')) INTO v_currency
  FROM public.app_settings
  WHERE company_id=p_company_id
  ORDER BY created_at,id
  LIMIT 1;

  IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'SYSTEM_CURRENCY_NOT_CONFIGURED';
  END IF;

  IF p_branch_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.branches
    WHERE id=p_branch_id AND company_id=p_company_id AND COALESCE(is_active,true)=true
  ) THEN
    RAISE EXCEPTION 'QUICK_MARKET_BRANCH_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_supplier_invoice_no),'') IS NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_SUPPLIER_INVOICE_NUMBER_REQUIRED';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.suppliers
    WHERE id=p_supplier_id AND company_id=p_company_id AND COALESCE(is_active,false)=true
  ) THEN
    RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID';
  END IF;

  PERFORM app_private.assert_unique_purchase_supplier_invoice(
    p_company_id,p_supplier_id,p_supplier_invoice_no,NULL
  );

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_MUST_BE_ARRAY';
  END IF;

  v_count:=jsonb_array_length(p_items);
  IF v_count<1 OR v_count>500 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_COUNT_INVALID';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) x(item_code text,qty numeric,unit_price numeric)
    GROUP BY btrim(item_code)
    HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_DUPLICATE_ITEM';
  END IF;

  FOR x IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    SELECT * INTO v_item
    FROM public.items
    WHERE company_id=p_company_id
      AND item_code=btrim(x->>'item_code')
      AND COALESCE(is_active,true)=true;
    IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_INVALID_OR_INACTIVE:%',x->>'item_code'; END IF;

    IF COALESCE(NULLIF(x->>'qty','')::numeric,0)<=0
       OR COALESCE(NULLIF(x->>'unit_price','')::numeric,0)<=0
       OR COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)<0
       OR COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)>100
       OR COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)<0
       OR COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)>100 THEN
      RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_VALUE_INVALID:%',x->>'item_code';
    END IF;

    v_total:=v_total+ROUND(
      COALESCE(NULLIF(x->>'qty','')::numeric,0)
      * COALESCE(NULLIF(x->>'unit_price','')::numeric,0)
      * (1-COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)/100)
      * (1+COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)/100),
      2
    );
  END LOOP;

  IF v_total<=0 THEN RAISE EXCEPTION 'PURCHASE_INVOICE_TOTAL_INVALID'; END IF;

  v_fingerprint:=md5(jsonb_build_object(
    'supplier_id',p_supplier_id,
    'branch_id',p_branch_id,
    'due_date',p_due_date,
    'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),
    'currency',v_currency,
    'settlement_source',p_settlement_source,
    'cash_custody_id',p_cash_custody_id,
    'items',p_items
  )::text);

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE company_id=p_company_id AND operation_id=p_operation_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_invoice.purchase_source<>'QUICK_MARKET'
       OR v_invoice.source_payload_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION 'PURCHASE_OPERATION_ID_PAYLOAD_CONFLICT';
    END IF;

    RETURN jsonb_build_object(
      'success',true,'duplicate',true,'id',v_invoice.id,'code',v_invoice.invoice_code,
      'status',v_invoice.status,'currency',v_invoice.currency,
      'purchase_source',v_invoice.purchase_source
    );
  END IF;

  IF p_settlement_source='EMPLOYEE_CUSTODY' THEN
    IF p_cash_custody_id IS NULL THEN
      RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_REQUIRED';
    END IF;

    SELECT * INTO v_custody
    FROM public.buyer_custodies
    WHERE id=p_cash_custody_id
      AND company_id=p_company_id
      AND employee_id=v_actor.id
      AND status IN ('Issued','UnderReview')
      AND acknowledged_at IS NOT NULL
      AND upper(currency)=v_currency
    FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_NOT_AVAILABLE'; END IF;

    SELECT COALESCE(SUM(amount),0) INTO v_acknowledged
    FROM public.buyer_custody_advances
    WHERE company_id=p_company_id
      AND custody_id=p_cash_custody_id
      AND acknowledged_at IS NOT NULL;

    SELECT COALESCE(SUM(amount),0) INTO v_committed
    FROM public.buyer_custody_expenses
    WHERE company_id=p_company_id
      AND custody_id=p_cash_custody_id
      AND status IN ('Submitted','Approved');

    SELECT COALESCE(SUM(GREATEST(
      pi.total_amount-COALESCE(pi.paid_amount,0)-COALESCE((
        SELECT SUM(e.amount) FROM public.buyer_custody_expenses e
        WHERE e.company_id=p_company_id
          AND e.purchase_invoice_id=pi.id
          AND e.custody_id=p_cash_custody_id
          AND e.status IN ('Submitted','Approved')
      ),0),0)),0) INTO v_reserved
    FROM public.purchase_invoices pi
    WHERE pi.company_id=p_company_id
      AND pi.cash_custody_id=p_cash_custody_id
      AND pi.purchase_source='QUICK_MARKET'
      AND pi.status IN ('Draft','Posted','PartiallyPaid')
      AND pi.settlement_status IN ('UNSETTLED','PENDING_FINANCE','AP_OPEN','PARTIALLY_SETTLED');

    IF v_committed+v_reserved+v_total>v_acknowledged+0.005 THEN
      RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_LIMIT_EXCEEDED';
    END IF;
  ELSIF p_cash_custody_id IS NOT NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_NOT_ALLOWED_FOR_SUPPLIER_CREDIT';
  END IF;

  v_result:=public.purchase_create_invoice_atomic_v2(
    p_company_id,p_supplier_id,NULL,p_branch_id,p_due_date,v_currency,
    v_actor.email,p_supplier_invoice_no,p_notes,p_items,p_operation_id
  );

  IF COALESCE((v_result->>'success')::boolean,false)=false
     OR NULLIF(v_result->>'id','') IS NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_CREATE_FAILED';
  END IF;

  UPDATE public.purchase_invoices
  SET purchase_source='QUICK_MARKET',
      settlement_source=p_settlement_source,
      purchaser_user_id=v_actor.id,
      cash_custody_id=p_cash_custody_id,
      receipt_status='NOT_RECEIVED',
      settlement_status='UNSETTLED',
      source_payload_fingerprint=v_fingerprint,
      is_received=false,
      received_date=NULL,
      updated_at=now()
  WHERE id=(v_result->>'id')::uuid
    AND company_id=p_company_id
    AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'QUICK_MARKET_INVOICE_CLASSIFICATION_FAILED'; END IF;

  RETURN v_result||jsonb_build_object(
    'purchase_source','QUICK_MARKET',
    'settlement_source',p_settlement_source,
    'purchaser_user_id',v_actor.id,
    'cash_custody_reserved',p_settlement_source='EMPLOYEE_CUSTODY'
  );
END;
$function$;
REVOKE ALL ON FUNCTION public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.purchase_update_buyer_legacy_draft_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_supplier_id uuid,
  p_purchase_order_id uuid,
  p_branch_id uuid,
  p_due_date date,
  p_currency text,
  p_actor text,
  p_supplier_invoice_no text,
  p_notes text,
  p_items jsonb,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_is_owner boolean:=COALESCE((public.get_my_effective_profile()->>'isOwner')::boolean,false);
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth.uid()=users.auth_id
    AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR lower(v_actor.email)<>lower(COALESCE(p_actor,'')) THEN
    RAISE EXCEPTION 'BUYER_ACTOR_AUTH_MISMATCH';
  END IF;

  IF NOT (
    app_private.current_user_has_effective_permission('purchases')
    OR v_is_owner
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED';
  END IF;

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id
  FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'LEGACY_UNCLASSIFIED' THEN
    RAISE EXCEPTION 'BUYER_LEGACY_INVOICE_NOT_FOUND_OR_WRONG_SOURCE';
  END IF;

  IF lower(COALESCE(v_invoice.created_by,''))<>lower(v_actor.email)
     AND NOT v_is_owner THEN
    RAISE EXCEPTION 'BUYER_INVOICE_NOT_OWNED_BY_CURRENT_USER';
  END IF;

  IF p_purchase_order_id IS DISTINCT FROM v_invoice.purchase_order_id THEN
    RAISE EXCEPTION 'BUYER_LEGACY_INVOICE_SOURCE_CONVERSION_FORBIDDEN';
  END IF;

  PERFORM app_private.assert_unique_purchase_supplier_invoice(
    p_company_id,p_supplier_id,p_supplier_invoice_no,p_invoice_id
  );

  RETURN public.purchase_update_draft_invoice_atomic(
    p_company_id,p_invoice_id,p_supplier_id,p_purchase_order_id,p_branch_id,
    p_due_date,p_currency,v_actor.email,p_supplier_invoice_no,p_notes,p_items,p_operation_id
  );
END;
$function$;
REVOKE ALL ON FUNCTION public.purchase_update_buyer_legacy_draft_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_update_buyer_legacy_draft_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,text,text,jsonb,text) TO authenticated, service_role;
COMMIT;
