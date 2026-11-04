-- RAWAEA ERP — Buyer Phase 1 companion contract
-- وسم فواتير أوامر الشراء الجديدة دون إعادة بناء مسار الفاتورة الحالي.
-- REVIEWED DRAFT ONLY. يُنفذ مع ملف 03 وبالتسلسل بعد مطابقتهما مع Production.

BEGIN;

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
  SELECT * INTO v_actor FROM public.users
  WHERE auth.uid()=users.auth_id AND company_id=p_company_id
    AND COALESCE(status,'Active')='Active';
  IF NOT FOUND OR NOT app_private.current_user_has_effective_permission('purchases') THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF p_purchase_order_id IS NULL OR NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'PURCHASE_ORDER_AND_OPERATION_REQUIRED';
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
  ) THEN RAISE EXCEPTION 'PURCHASE_SUPPLIER_INVALID'; END IF;

  IF p_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches WHERE id=p_branch_id AND company_id=p_company_id
  ) THEN RAISE EXCEPTION 'PURCHASE_BRANCH_INVALID'; END IF;

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' OR jsonb_array_length(p_items)<1 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_INVALID';
  END IF;

  v_fingerprint:=md5(jsonb_build_object(
    'supplier_id',p_supplier_id,'purchase_order_id',p_purchase_order_id,
    'branch_id',p_branch_id,'due_date',p_due_date,
    'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'currency',v_currency,'items',p_items
  )::text);

  SELECT * INTO v_invoice FROM public.purchase_invoices
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
      buyer_custody_id=NULL,
      receipt_status='NOT_RECEIVED',
      settlement_status='UNSETTLED',
      source_payload_fingerprint=v_fingerprint,
      updated_at=now()
  WHERE id=(v_result->>'id')::uuid
    AND company_id=p_company_id AND status='Draft';

  IF NOT FOUND THEN RAISE EXCEPTION 'PURCHASE_ORDER_INVOICE_CLASSIFICATION_FAILED'; END IF;

  RETURN v_result||jsonb_build_object(
    'purchase_source','PURCHASE_ORDER',
    'settlement_source','SUPPLIER_CREDIT',
    'purchaser_user_id',v_actor.id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_create_po_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text)
  TO authenticated, service_role;

COMMIT;
