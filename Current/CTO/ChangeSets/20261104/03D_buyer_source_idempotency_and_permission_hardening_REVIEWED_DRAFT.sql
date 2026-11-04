-- RAWAEA ERP — Buyer Phase 1
-- تحصين تكرار العمليات والصلاحيات ونسخ مسودات PO وQuick Market.
-- REVIEWED DRAFT — لا ينفذ منفردًا ولا على Production قبل اعتماد الحزمة كاملة.
-- هذه النسخة تعيد تعريف الدوال التي تتطلب حراسة إضافية؛ وهي مكملة لملف 03B.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. إنشاء فاتورة PO: تصنيف مصدر الفاتورة والتحقق من إعادة استخدام operation_id
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.purchase_create_po_invoice_atomic(
  p_company_id uuid,
  p_supplier_id uuid,
  p_purchase_order_id uuid,
  p_branch_id uuid,
  p_due_date date,
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
  v_po public.purchase_orders%ROWTYPE;
  v_invoice public.purchase_invoices%ROWTYPE;
  v_currency text;
  v_fingerprint text;
  v_result jsonb;
BEGIN
  SELECT * INTO v_actor
  FROM public.users
  WHERE auth.uid()=users.auth_id
    AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR NOT (
    app_private.current_user_has_effective_permission('purchases')
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF p_purchase_order_id IS NULL OR NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_ORDER_AND_OPERATION_REQUIRED';
  END IF;

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_MUST_BE_ARRAY';
  END IF;
  IF jsonb_array_length(p_items)<1 OR jsonb_array_length(p_items)>500 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_COUNT_INVALID';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_items) x(item_code text)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.items i
      WHERE i.company_id=p_company_id
        AND i.item_code=btrim(x.item_code)
        AND COALESCE(i.is_active,true)=true
    )
  ) THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_INVALID_OR_INACTIVE';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('RAWAEA:PO-INVOICE:'||p_company_id::text||':'||btrim(p_operation_id),0)
  );

  SELECT upper(nullif(btrim(currency),'')) INTO v_currency
  FROM public.app_settings
  WHERE company_id=p_company_id
  ORDER BY created_at,id
  LIMIT 1;

  IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'SYSTEM_CURRENCY_NOT_CONFIGURED';
  END IF;

  SELECT * INTO v_po
  FROM public.purchase_orders
  WHERE id=p_purchase_order_id
    AND company_id=p_company_id
    AND supplier_id=p_supplier_id
    AND status<>'Cancelled'
  FOR UPDATE;

  IF NOT FOUND OR upper(COALESCE(v_po.currency,''))<>v_currency THEN
    RAISE EXCEPTION 'PURCHASE_PO_SUPPLIER_OR_CURRENCY_INVALID';
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

  IF p_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches
    WHERE id=p_branch_id AND company_id=p_company_id AND COALESCE(is_active,true)=true
  ) THEN
    RAISE EXCEPTION 'PURCHASE_BRANCH_INVALID';
  END IF;

  v_fingerprint:=md5(jsonb_build_object(
    'supplier_id',p_supplier_id,'purchase_order_id',p_purchase_order_id,
    'branch_id',p_branch_id,'due_date',p_due_date,
    'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'currency',v_currency,'items',p_items
  )::text);

  SELECT * INTO v_invoice
  FROM public.purchase_invoices
  WHERE company_id=p_company_id AND operation_id=p_operation_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_invoice.purchase_source<>'PURCHASE_ORDER'
       OR v_invoice.source_payload_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION 'PURCHASE_OPERATION_ID_PAYLOAD_CONFLICT';
    END IF;

    RETURN jsonb_build_object(
      'success',true,'duplicate',true,'id',v_invoice.id,'code',v_invoice.invoice_code,
      'status',v_invoice.status,'currency',v_invoice.currency,'purchase_source','PURCHASE_ORDER'
    );
  END IF;

  v_result:=public.purchase_create_invoice_atomic_v2(
    p_company_id,p_supplier_id,p_purchase_order_id,p_branch_id,p_due_date,v_currency,
    v_actor.email,p_supplier_invoice_no,p_notes,p_items,p_operation_id
  );

  IF COALESCE((v_result->>'success')::boolean,false)=false
     OR NULLIF(v_result->>'id','') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_ORDER_INVOICE_CREATE_FAILED';
  END IF;

  UPDATE public.purchase_invoices
  SET purchase_source='PURCHASE_ORDER',
      settlement_source='SUPPLIER_CREDIT',
      purchaser_user_id=v_actor.id,
      cash_custody_id=NULL,
      receipt_status='NOT_RECEIVED',
      settlement_status='UNSETTLED',
      source_payload_fingerprint=v_fingerprint,
      updated_at=now()
  WHERE id=(v_result->>'id')::uuid
    AND company_id=p_company_id
    AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_ORDER_INVOICE_CLASSIFICATION_FAILED'; END IF;

  RETURN v_result||jsonb_build_object(
    'purchase_source','PURCHASE_ORDER',
    'settlement_source','SUPPLIER_CREDIT',
    'purchaser_user_id',v_actor.id
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. تعديل فاتورة PO: عملية موثقة، مصدر لا يتغير، ولا تعديل بعد الاستلام
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.purchase_update_po_invoice_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_supplier_id uuid,
  p_purchase_order_id uuid,
  p_branch_id uuid,
  p_due_date date,
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
  v_po public.purchase_orders%ROWTYPE;
  v_currency text;
  v_fingerprint text;
  v_request jsonb;
  v_op public.erp_operation_registry%ROWTYPE;
  v_result jsonb;
BEGIN
  SELECT * INTO v_actor FROM public.users
  WHERE auth.uid()=users.auth_id AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR NOT (
    app_private.current_user_has_effective_permission('purchases')
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL OR p_purchase_order_id IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_AND_PO_REQUIRED';
  END IF;

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_MUST_BE_ARRAY';
  END IF;
  IF jsonb_array_length(p_items)<1 OR jsonb_array_length(p_items)>500 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_COUNT_INVALID';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_items) x(item_code text)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.items i
      WHERE i.company_id=p_company_id
        AND i.item_code=btrim(x.item_code)
        AND COALESCE(i.is_active,true)=true
    )
  ) THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_INVALID_OR_INACTIVE';
  END IF;

  v_request:=jsonb_build_object(
    'invoice_id',p_invoice_id,'supplier_id',p_supplier_id,
    'purchase_order_id',p_purchase_order_id,'branch_id',p_branch_id,
    'due_date',p_due_date,'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'items',p_items
  );

  PERFORM pg_advisory_xact_lock(
    hashtextextended('RAWAEA:PO-INVOICE-UPDATE:'||p_company_id::text||':'||btrim(p_operation_id),0)
  );

  INSERT INTO public.erp_operation_registry(
    company_id,operation_type,operation_key,request_payload,status
  )
  VALUES(
    p_company_id,'purchase_update_po_invoice_atomic',btrim(p_operation_id),v_request,'processing'
  )
  ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;

  SELECT * INTO v_op
  FROM public.erp_operation_registry
  WHERE company_id=p_company_id
    AND operation_type='purchase_update_po_invoice_atomic'
    AND operation_key=btrim(p_operation_id)
  FOR UPDATE;

  IF v_op.request_payload IS DISTINCT FROM v_request THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_PAYLOAD_CONFLICT';
  END IF;

  IF v_op.status='completed' AND v_op.response_payload IS NOT NULL THEN
    RETURN v_op.response_payload||jsonb_build_object('duplicate',true);
  END IF;

  SELECT * INTO v_invoice FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'PURCHASE_ORDER'
     OR v_invoice.purchase_order_id IS DISTINCT FROM p_purchase_order_id
     OR v_invoice.purchaser_user_id IS DISTINCT FROM v_actor.id
     OR v_invoice.status<>'Draft'
     OR COALESCE(v_invoice.is_received,false)
     OR v_invoice.received_date IS NOT NULL
     OR v_invoice.posted_at IS NOT NULL
     OR COALESCE(v_invoice.paid_amount,0)<>0 THEN
    RAISE EXCEPTION 'PURCHASE_ORDER_INVOICE_NOT_EDITABLE';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.buyer_custody_expenses
    WHERE company_id=p_company_id AND purchase_invoice_id=p_invoice_id
  ) OR EXISTS (
    SELECT 1 FROM public.purchase_returns
    WHERE company_id=p_company_id AND purchase_invoice_id=p_invoice_id
  ) OR EXISTS (
    SELECT 1 FROM public.stock_vouchers
    WHERE company_id=p_company_id AND purchase_invoice_id=p_invoice_id
  ) THEN
    RAISE EXCEPTION 'PURCHASE_ORDER_INVOICE_HAS_DOWNSTREAM_DOCUMENTS';
  END IF;

  SELECT upper(nullif(btrim(currency),'')) INTO v_currency
  FROM public.app_settings WHERE company_id=p_company_id
  ORDER BY created_at,id LIMIT 1;

  IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'SYSTEM_CURRENCY_NOT_CONFIGURED';
  END IF;

  SELECT * INTO v_po FROM public.purchase_orders
  WHERE id=p_purchase_order_id AND company_id=p_company_id
    AND supplier_id=p_supplier_id AND status<>'Cancelled'
  FOR UPDATE;

  IF NOT FOUND OR upper(COALESCE(v_po.currency,''))<>v_currency THEN
    RAISE EXCEPTION 'PURCHASE_PO_SUPPLIER_OR_CURRENCY_INVALID';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.suppliers
    WHERE id=p_supplier_id AND company_id=p_company_id AND COALESCE(is_active,false)=true
  ) THEN
    RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID';
  END IF;

  PERFORM app_private.assert_unique_purchase_supplier_invoice(
    p_company_id,p_supplier_id,p_supplier_invoice_no,p_invoice_id
  );

  v_fingerprint:=md5(jsonb_build_object(
    'supplier_id',p_supplier_id,'purchase_order_id',p_purchase_order_id,
    'branch_id',p_branch_id,'due_date',p_due_date,
    'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'currency',v_currency,'items',p_items
  )::text);

  v_result:=public.purchase_update_draft_invoice_atomic(
    p_company_id,p_invoice_id,p_supplier_id,p_purchase_order_id,p_branch_id,p_due_date,
    v_currency,v_actor.email,p_supplier_invoice_no,p_notes,p_items,p_operation_id
  );

  UPDATE public.purchase_invoices
  SET purchase_source='PURCHASE_ORDER',
      settlement_source='SUPPLIER_CREDIT',
      purchaser_user_id=v_actor.id,
      cash_custody_id=NULL,
      receipt_status='NOT_RECEIVED',
      settlement_status='UNSETTLED',
      source_payload_fingerprint=v_fingerprint,
      updated_at=now()
  WHERE id=p_invoice_id AND company_id=p_company_id AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_ORDER_INVOICE_CLASSIFICATION_FAILED'; END IF;

  v_result:=v_result||jsonb_build_object(
    'purchase_source','PURCHASE_ORDER',
    'settlement_source','SUPPLIER_CREDIT',
    'purchaser_user_id',v_actor.id
  );

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_result,completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='purchase_update_po_invoice_atomic'
    AND operation_key=btrim(p_operation_id);

  RETURN v_result;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. تعديل Quick Market: تحقق صلاحية المالك، JSON، ومفتاح العملية ومحتواها
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.purchase_update_quick_market_invoice_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
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
  v_fingerprint text;
  v_request jsonb;
  v_op public.erp_operation_registry%ROWTYPE;
  v_result jsonb;
  v_total numeric(14,2):=0;
  v_acknowledged numeric(14,2):=0;
  v_committed numeric(14,2):=0;
  v_reserved numeric(14,2):=0;
  v_custody public.buyer_custodies%ROWTYPE;
  x jsonb;
BEGIN
  SELECT * INTO v_actor FROM public.users
  WHERE auth.uid()=users.auth_id AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR NOT (
    app_private.current_user_has_effective_permission('purchases')
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED';
  END IF;

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_MUST_BE_ARRAY';
  END IF;
  IF jsonb_array_length(p_items)<1 OR jsonb_array_length(p_items)>500 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_COUNT_INVALID';
  END IF;

  IF p_settlement_source IS NULL OR p_settlement_source NOT IN ('EMPLOYEE_CUSTODY','SUPPLIER_CREDIT') THEN
    RAISE EXCEPTION 'QUICK_MARKET_SETTLEMENT_SOURCE_INVALID';
  END IF;

  IF NULLIF(btrim(p_supplier_invoice_no),'') IS NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_SUPPLIER_INVOICE_NUMBER_REQUIRED';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_items) x(item_code text,qty numeric,unit_price numeric)
    GROUP BY btrim(item_code) HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_DUPLICATE_ITEM';
  END IF;

  FOR x IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    IF NULLIF(btrim(x->>'item_code'),'') IS NULL
       OR NOT EXISTS (
         SELECT 1 FROM public.items i
         WHERE i.company_id=p_company_id
           AND i.item_code=btrim(x->>'item_code')
           AND COALESCE(i.is_active,true)=true
       )
       OR COALESCE(NULLIF(x->>'qty','')::numeric,0)<=0
       OR COALESCE(NULLIF(x->>'unit_price','')::numeric,0)<=0
       OR COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)<0
       OR COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)>100
       OR COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)<0
       OR COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)>100 THEN
      RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_VALUE_INVALID:%',x->>'item_code';
    END IF;

    v_total:=v_total+ROUND(
      COALESCE(NULLIF(x->>'qty','')::numeric,0)
      *COALESCE(NULLIF(x->>'unit_price','')::numeric,0)
      *(1-COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)/100)
      *(1+COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)/100),2);
  END LOOP;

  IF v_total<=0 THEN RAISE EXCEPTION 'PURCHASE_INVOICE_TOTAL_INVALID'; END IF;

  v_request:=jsonb_build_object(
    'invoice_id',p_invoice_id,'supplier_id',p_supplier_id,'branch_id',p_branch_id,
    'due_date',p_due_date,'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'items',p_items,
    'settlement_source',p_settlement_source,'cash_custody_id',p_cash_custody_id
  );

  PERFORM pg_advisory_xact_lock(
    hashtextextended('RAWAEA:QUICK-MARKET-UPDATE:'||p_company_id::text||':'||btrim(p_operation_id),0)
  );

  INSERT INTO public.erp_operation_registry(
    company_id,operation_type,operation_key,request_payload,status
  )
  VALUES(
    p_company_id,'purchase_update_quick_market_invoice_atomic',btrim(p_operation_id),v_request,'processing'
  )
  ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;

  SELECT * INTO v_op
  FROM public.erp_operation_registry
  WHERE company_id=p_company_id
    AND operation_type='purchase_update_quick_market_invoice_atomic'
    AND operation_key=btrim(p_operation_id)
  FOR UPDATE;

  IF v_op.request_payload IS DISTINCT FROM v_request THEN
    RAISE EXCEPTION 'PURCHASE_OPERATION_ID_PAYLOAD_CONFLICT';
  END IF;

  IF v_op.status='completed' AND v_op.response_payload IS NOT NULL THEN
    RETURN v_op.response_payload||jsonb_build_object('duplicate',true);
  END IF;

  SELECT * INTO v_invoice FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'QUICK_MARKET'
     OR v_invoice.purchaser_user_id IS DISTINCT FROM v_actor.id
     OR v_invoice.status<>'Draft'
     OR COALESCE(v_invoice.is_received,false)
     OR v_invoice.received_date IS NOT NULL
     OR v_invoice.purchase_order_id IS NOT NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_NOT_EDITABLE';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.buyer_goods_custody_events
    WHERE company_id=p_company_id
      AND source_document_type='PurchaseInvoice'
      AND source_document_id=p_invoice_id
  ) OR EXISTS (
    SELECT 1 FROM public.buyer_custody_expenses
    WHERE company_id=p_company_id AND purchase_invoice_id=p_invoice_id
  ) THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_HAS_DOWNSTREAM_EVENTS';
  END IF;

  SELECT upper(nullif(btrim(currency),'')) INTO v_currency
  FROM public.app_settings WHERE company_id=p_company_id
  ORDER BY created_at,id LIMIT 1;

  IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION 'SYSTEM_CURRENCY_NOT_CONFIGURED';
  END IF;

  IF p_branch_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.branches
    WHERE id=p_branch_id AND company_id=p_company_id AND COALESCE(is_active,true)=true
  ) THEN
    RAISE EXCEPTION 'QUICK_MARKET_BRANCH_REQUIRED';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.suppliers
    WHERE id=p_supplier_id AND company_id=p_company_id AND COALESCE(is_active,false)=true
  ) THEN
    RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID';
  END IF;

  PERFORM app_private.assert_unique_purchase_supplier_invoice(
    p_company_id,p_supplier_id,p_supplier_invoice_no,p_invoice_id
  );

  v_fingerprint:=md5(jsonb_build_object(
    'supplier_id',p_supplier_id,'branch_id',p_branch_id,'due_date',p_due_date,
    'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'currency',v_currency,
    'settlement_source',p_settlement_source,'cash_custody_id',p_cash_custody_id,'items',p_items
  )::text);

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
      AND pi.id<>p_invoice_id
      AND pi.settlement_status IN ('UNSETTLED','PENDING_FINANCE','AP_OPEN','PARTIALLY_SETTLED');

    IF v_committed+v_reserved+v_total>v_acknowledged+0.005 THEN
      RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_LIMIT_EXCEEDED';
    END IF;
  ELSIF p_cash_custody_id IS NOT NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_NOT_ALLOWED_FOR_SUPPLIER_CREDIT';
  END IF;

  v_result:=public.purchase_update_draft_invoice_atomic(
    p_company_id,p_invoice_id,p_supplier_id,NULL,p_branch_id,p_due_date,v_currency,
    v_actor.email,p_supplier_invoice_no,p_notes,p_items,p_operation_id
  );

  UPDATE public.purchase_invoices
  SET purchase_source='QUICK_MARKET',
      settlement_source=p_settlement_source,
      purchaser_user_id=v_actor.id,
      cash_custody_id=p_cash_custody_id,
      receipt_status='NOT_RECEIVED',
      settlement_status='UNSETTLED',
      source_payload_fingerprint=v_fingerprint,
      updated_at=now()
  WHERE id=p_invoice_id AND company_id=p_company_id AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'QUICK_MARKET_INVOICE_CLASSIFICATION_FAILED'; END IF;

  v_result:=v_result||jsonb_build_object(
    'purchase_source','QUICK_MARKET',
    'settlement_source',p_settlement_source,
    'purchaser_user_id',v_actor.id
  );

  UPDATE public.erp_operation_registry
  SET status='completed',response_payload=v_result,completed_at=now()
  WHERE company_id=p_company_id
    AND operation_type='purchase_update_quick_market_invoice_atomic'
    AND operation_key=btrim(p_operation_id);

  RETURN v_result;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. قراءة دفتر الحيازة: لا يسمح للمستخدم الذي لا يحمل صلاحية المشتريات/المالية
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.buyer_goods_custody_get_balances_atomic(
  p_company_id uuid,
  p_custodian_user_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_target uuid;
  v_can_view_all boolean;
  v_balances jsonb;
  v_events jsonb;
BEGIN
  SELECT * INTO v_actor FROM public.users
  WHERE auth.uid()=users.auth_id AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND THEN RAISE EXCEPTION 'BUYER_GOODS_AUTH_REQUIRED'; END IF;

  IF NOT (
    app_private.current_user_has_effective_permission('purchases')
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
  ) THEN
    RAISE EXCEPTION 'BUYER_GOODS_PERMISSION_REQUIRED';
  END IF;

  v_can_view_all:=
    app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager');

  IF p_custodian_user_id IS NULL THEN
    v_target:=CASE WHEN v_can_view_all THEN NULL ELSE v_actor.id END;
  ELSE
    IF p_custodian_user_id<>v_actor.id AND NOT v_can_view_all THEN
      RAISE EXCEPTION 'BUYER_GOODS_SCOPE_FORBIDDEN';
    END IF;
    v_target:=p_custodian_user_id;
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'custodian_user_id',b.custodian_user_id,
    'branch_id',b.branch_id,'branch_name',br.name,
    'item_id',b.item_id,'item_code',it.item_code,'item_name',it.name,'unit',it.unit,
    'balance_qty',b.balance_qty,'vehicle_ids',b.vehicle_ids,
    'last_movement_at',b.last_movement_at
  ) ORDER BY br.name,it.name),'[]'::jsonb)
  INTO v_balances
  FROM (
    SELECT e.custodian_user_id,e.branch_id,e.item_id,
      SUM(e.qty_delta) balance_qty,
      ARRAY_REMOVE(ARRAY_AGG(DISTINCT e.vehicle_id),NULL) vehicle_ids,
      MAX(e.created_at) last_movement_at
    FROM public.buyer_goods_custody_events e
    WHERE e.company_id=p_company_id
      AND (v_target IS NULL OR e.custodian_user_id=v_target)
    GROUP BY e.custodian_user_id,e.branch_id,e.item_id
    HAVING ABS(SUM(e.qty_delta))>0.0001
  ) b
  JOIN public.branches br ON br.id=b.branch_id AND br.company_id=p_company_id
  JOIN public.items it ON it.id=b.item_id AND it.company_id=p_company_id;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id',e.id,'custodian_user_id',e.custodian_user_id,'item_id',e.item_id,
    'item_code',it.item_code,'item_name',it.name,'branch_id',e.branch_id,
    'branch_name',br.name,'vehicle_id',e.vehicle_id,'event_type',e.event_type,
    'qty_delta',e.qty_delta,'source_document_type',e.source_document_type,
    'source_document_id',e.source_document_id,'source_line_id',e.source_line_id,
    'invoice_code',pi.invoice_code,'supplier_invoice_no',pi.supplier_invoice_no,
    'operation_id',e.operation_id,'evidence_path',e.evidence_path,
    'notes',e.notes,'created_at',e.created_at
  ) ORDER BY e.created_at DESC),'[]'::jsonb)
  INTO v_events
  FROM (
    SELECT * FROM public.buyer_goods_custody_events
    WHERE company_id=p_company_id
      AND (v_target IS NULL OR custodian_user_id=v_target)
    ORDER BY created_at DESC
    LIMIT 200
  ) e
  JOIN public.items it ON it.id=e.item_id AND it.company_id=p_company_id
  JOIN public.branches br ON br.id=e.branch_id AND br.company_id=p_company_id
  LEFT JOIN public.purchase_invoices pi
    ON e.source_document_type='PurchaseInvoice'
   AND pi.id=e.source_document_id
   AND pi.company_id=p_company_id;

  RETURN jsonb_build_object(
    'success',true,'custodian_user_id',v_target,
    'can_view_all',v_can_view_all,'balances',v_balances,'events',v_events
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. حذف المسودة: نفس صلاحية المشتريات، ونفس قيد عدم وجود أي مستند تابع
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.purchase_delete_quick_market_draft_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_actor text,
  p_reason text,
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
BEGIN
  SELECT * INTO v_actor FROM public.users
  WHERE auth.uid()=users.auth_id AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';

  IF NOT FOUND OR lower(v_actor.email)<>lower(COALESCE(p_actor,'')) OR NOT (
    app_private.current_user_has_effective_permission('purchases')
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  SELECT * INTO v_invoice FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'QUICK_MARKET'
     OR v_invoice.purchaser_user_id IS DISTINCT FROM v_actor.id THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_NOT_FOUND_OR_FORBIDDEN';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.buyer_goods_custody_events
    WHERE company_id=p_company_id AND source_document_type='PurchaseInvoice'
      AND source_document_id=p_invoice_id
  ) OR EXISTS (
    SELECT 1 FROM public.buyer_custody_expenses
    WHERE company_id=p_company_id AND purchase_invoice_id=p_invoice_id
  ) THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_HAS_DOWNSTREAM_EVENTS';
  END IF;

  RETURN public.purchase_delete_draft_invoice_atomic(
    p_company_id,p_invoice_id,v_actor.email,p_reason,p_operation_id
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. الصلاحيات على الوظائف التي أعيد تعريفها
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.purchase_update_po_invoice_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,jsonb,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_update_po_invoice_atomic(uuid,uuid,uuid,uuid,uuid,date,text,text,jsonb,text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.buyer_goods_custody_get_balances_atomic(uuid,uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.buyer_goods_custody_get_balances_atomic(uuid,uuid)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.purchase_delete_quick_market_draft_atomic(uuid,uuid,text,text,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_delete_quick_market_draft_atomic(uuid,uuid,text,text,text)
  TO authenticated, service_role;

COMMIT;
