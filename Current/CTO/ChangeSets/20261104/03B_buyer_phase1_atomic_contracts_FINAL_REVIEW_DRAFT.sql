-- RAWAEA ERP — BUYER PHASE 1
-- عقود إنشاء Quick Market ودفتر حيازة مسؤول المشتريات
-- REVIEWED DRAFT ONLY — لا ينفذ على Production قبل اعتماد ChangeSet كامل واختبار النسخة المطابقة.
-- أساس التصميم: EGP من app_settings، المورد من الدليل المركزي، مركبة اختيارية،
-- لا حركة مخزون أو AP عند إنشاء الفاتورة أو تسليم المورد إلى المشتري.
--
-- يعتمد هذا الملف على الوظائف المركزية الحالية:
-- purchase_create_invoice_atomic_v2
-- purchase_update_draft_invoice_atomic
-- purchase_delete_draft_invoice_atomic
-- ولا ينشئ أي Edge Function جديدة.
--
-- ملاحظة: هذا الملف لا يعدل Receiver أو SupplierReturn في هذه المرحلة.
-- لا يتضمن أي UPDATE لصفوف الفواتير التاريخية أو الأرصدة أو قيود الأستاذ العام.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. تصنيف الفاتورة الجديدة مع عزل السجلات القديمة
-- ---------------------------------------------------------------------------

ALTER TABLE public.purchase_invoices
  ADD COLUMN IF NOT EXISTS purchase_source text NOT NULL DEFAULT 'LEGACY_UNCLASSIFIED',
  ADD COLUMN IF NOT EXISTS settlement_source text NOT NULL DEFAULT 'UNSET',
  ADD COLUMN IF NOT EXISTS purchaser_user_id uuid,
  ADD COLUMN IF NOT EXISTS cash_custody_id uuid,
  ADD COLUMN IF NOT EXISTS receipt_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS settlement_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS source_payload_fingerprint text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_purchaser_user_fk'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_purchaser_user_fk
      FOREIGN KEY (purchaser_user_id) REFERENCES public.users(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_cash_custody_fk'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_cash_custody_fk
      FOREIGN KEY (cash_custody_id) REFERENCES public.buyer_custodies(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_purchase_source_ck'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_purchase_source_ck
      CHECK (purchase_source IN ('LEGACY_UNCLASSIFIED','PURCHASE_ORDER','QUICK_MARKET'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_settlement_source_ck'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_settlement_source_ck
      CHECK (settlement_source IN ('UNSET','SUPPLIER_CREDIT','EMPLOYEE_CUSTODY'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_receipt_status_ck'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_receipt_status_ck
      CHECK (receipt_status IN ('LEGACY_UNVERIFIED','NOT_RECEIVED','PARTIALLY_RECEIVED','RECEIVED'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_settlement_status_ck'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_settlement_status_ck
      CHECK (settlement_status IN ('LEGACY_UNVERIFIED','UNSETTLED','PENDING_FINANCE','AP_OPEN','PARTIALLY_SETTLED','SETTLED','PAID'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_source_relation_ck'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_source_relation_ck
      CHECK (
        (purchase_source='LEGACY_UNCLASSIFIED')
        OR
        (purchase_source='PURCHASE_ORDER'
          AND purchase_order_id IS NOT NULL
          AND purchaser_user_id IS NOT NULL
          AND settlement_source='SUPPLIER_CREDIT'
          AND cash_custody_id IS NULL
          AND source_payload_fingerprint IS NOT NULL)
        OR
        (purchase_source='QUICK_MARKET'
          AND purchase_order_id IS NULL
          AND branch_id IS NOT NULL
          AND purchaser_user_id IS NOT NULL
          AND NULLIF(btrim(supplier_invoice_no),'') IS NOT NULL
          AND settlement_source IN ('EMPLOYEE_CUSTODY','SUPPLIER_CREDIT')
          AND source_payload_fingerprint IS NOT NULL)
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_invoices'::regclass
      AND conname='purchase_invoices_cash_custody_source_ck'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_cash_custody_source_ck
      CHECK (
        (settlement_source='EMPLOYEE_CUSTODY' AND cash_custody_id IS NOT NULL)
        OR
        (settlement_source IN ('UNSET','SUPPLIER_CREDIT') AND cash_custody_id IS NULL)
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS purchase_invoices_buyer_source_idx
  ON public.purchase_invoices(company_id, purchaser_user_id, purchase_source, status, created_at DESC);

CREATE INDEX IF NOT EXISTS purchase_invoices_cash_custody_reservation_idx
  ON public.purchase_invoices(company_id, cash_custody_id, status)
  WHERE cash_custody_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. دفتر أحداث حيازة البضاعة — ليس رصيد مخزن ولا رصيد سيارة
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.buyer_goods_custody_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  custodian_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  item_id uuid NOT NULL REFERENCES public.items(id) ON DELETE RESTRICT,
  vehicle_id uuid REFERENCES public.vehicles(id) ON DELETE RESTRICT,
  event_type text NOT NULL,
  qty_delta numeric(14,4) NOT NULL,
  source_document_type text NOT NULL,
  source_document_id uuid NOT NULL,
  source_line_id uuid NOT NULL,
  related_document_type text,
  related_document_id uuid,
  operation_id text NOT NULL,
  payload_fingerprint text NOT NULL,
  evidence_path text,
  actor_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  reverses_event_id uuid REFERENCES public.buyer_goods_custody_events(id) ON DELETE RESTRICT,
  correction_reason text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT buyer_goods_custody_events_type_ck
    CHECK (event_type IN (
      'WAREHOUSE_TO_BUYER_SUPPLIER_RETURN',
      'SUPPLIER_TO_BUYER_QUICK_MARKET',
      'BUYER_TO_WAREHOUSE_ACCEPTED',
      'BUYER_TO_SUPPLIER_ACCEPTED',
      'BUYER_TO_WAREHOUSE_RETURN',
      'BUYER_CUSTODY_CORRECTION'
    )),
  CONSTRAINT buyer_goods_custody_events_sign_ck
    CHECK (
      (event_type IN ('WAREHOUSE_TO_BUYER_SUPPLIER_RETURN','SUPPLIER_TO_BUYER_QUICK_MARKET') AND qty_delta > 0)
      OR
      (event_type IN ('BUYER_TO_WAREHOUSE_ACCEPTED','BUYER_TO_SUPPLIER_ACCEPTED','BUYER_TO_WAREHOUSE_RETURN') AND qty_delta < 0)
      OR
      (event_type='BUYER_CUSTODY_CORRECTION' AND qty_delta <> 0)
    ),
  CONSTRAINT buyer_goods_custody_events_operation_uk
    UNIQUE (company_id, operation_id, source_line_id, event_type)
);

CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_balance_idx
  ON public.buyer_goods_custody_events(company_id, custodian_user_id, item_id, branch_id, created_at DESC);

CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_source_idx
  ON public.buyer_goods_custody_events(company_id, source_document_type, source_document_id);

CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_related_idx
  ON public.buyer_goods_custody_events(company_id, related_document_type, related_document_id)
  WHERE related_document_id IS NOT NULL;

ALTER TABLE public.buyer_goods_custody_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS buyer_goods_custody_events_select_authorized
  ON public.buyer_goods_custody_events;

CREATE POLICY buyer_goods_custody_events_select_authorized
ON public.buyer_goods_custody_events
FOR SELECT TO authenticated
USING (
  company_id = app_private.current_user_company_id()
  AND (
    custodian_user_id = (
      SELECT u.id FROM public.users u
      WHERE u.auth_id = auth.uid()
        AND u.company_id = buyer_goods_custody_events.company_id
        AND COALESCE(u.status,'Active')='Active'
      LIMIT 1
    )
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR COALESCE((SELECT (public.get_my_effective_profile()->>'isOwner')::boolean),false)
  )
);

REVOKE ALL PRIVILEGES ON TABLE public.buyer_goods_custody_events
  FROM PUBLIC, anon, authenticated;

GRANT SELECT ON TABLE public.buyer_goods_custody_events TO authenticated;
GRANT SELECT, INSERT ON TABLE public.buyer_goods_custody_events TO service_role;

-- منع التعديل والحذف المباشر حتى من مسارات التطبيق؛ التصحيح بحدث عكسي فقط.
CREATE OR REPLACE FUNCTION app_private.reject_buyer_goods_custody_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO pg_catalog
AS $$
BEGIN
  RAISE EXCEPTION 'BUYER_GOODS_CUSTODY_EVENTS_ARE_APPEND_ONLY';
END;
$$;

DROP TRIGGER IF EXISTS buyer_goods_custody_events_append_only
  ON public.buyer_goods_custody_events;

CREATE TRIGGER buyer_goods_custody_events_append_only
BEFORE UPDATE OR DELETE ON public.buyer_goods_custody_events
FOR EACH ROW EXECUTE FUNCTION app_private.reject_buyer_goods_custody_event_mutation();

-- ---------------------------------------------------------------------------
-- 3. إنشاء فاتورة سوق سريع Draft بعملية واحدة وتصنيف ومصدر وسقف عهدة
-- ---------------------------------------------------------------------------

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

  IF NOT app_private.current_user_has_effective_permission('purchases')
     AND NOT (COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb) THEN
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

-- ---------------------------------------------------------------------------
-- 4. تعديل مسودة Quick Market قبل ثبوت استلام البضاعة من المورد
--    يمنع التعديل فور وجود أي حدث حيازة أو مستند استلام أو مصروف تابع.
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
  v_result jsonb;
  v_total numeric(14,2):=0;
  v_acknowledged numeric(14,2):=0;
  v_committed numeric(14,2):=0;
  v_reserved numeric(14,2):=0;
  v_custody public.buyer_custodies%ROWTYPE;
  x jsonb;
BEGIN
  SELECT * INTO v_actor FROM public.users
  WHERE auth_id=auth.uid() AND company_id=p_company_id AND COALESCE(status,'Active')='Active';
  IF NOT FOUND OR NOT (
    app_private.current_user_has_effective_permission('purchases')
  ) THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'PURCHASE_OPERATION_ID_REQUIRED'; END IF;

  SELECT * INTO v_invoice FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'QUICK_MARKET'
     OR v_invoice.purchaser_user_id<>v_actor.id
     OR v_invoice.status<>'Draft'
     OR COALESCE(v_invoice.is_received,false)
     OR v_invoice.received_date IS NOT NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_NOT_EDITABLE';
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

  SELECT upper(nullif(btrim(currency),'')) INTO v_currency
  FROM public.app_settings
  WHERE company_id=p_company_id ORDER BY created_at,id LIMIT 1;

  IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN RAISE EXCEPTION 'SYSTEM_CURRENCY_NOT_CONFIGURED'; END IF;
  IF p_settlement_source IS NULL OR p_settlement_source NOT IN ('EMPLOYEE_CUSTODY','SUPPLIER_CREDIT') THEN
    RAISE EXCEPTION 'QUICK_MARKET_SETTLEMENT_SOURCE_INVALID';
  END IF;

  IF p_branch_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.branches WHERE id=p_branch_id AND company_id=p_company_id
  ) THEN RAISE EXCEPTION 'QUICK_MARKET_BRANCH_REQUIRED'; END IF;

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_MUST_BE_ARRAY';
  END IF;
  IF jsonb_array_length(p_items)<1 OR jsonb_array_length(p_items)>500 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEM_COUNT_INVALID';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_items) x(item_code text,qty numeric,unit_price numeric)
    GROUP BY btrim(item_code) HAVING count(*)>1
  ) THEN RAISE EXCEPTION 'PURCHASE_INVOICE_DUPLICATE_ITEM'; END IF;

  FOR x IN SELECT value FROM jsonb_array_elements(COALESCE(p_items,'[]'::jsonb)) LOOP
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
      *COALESCE(NULLIF(x->>'unit_price','')::numeric,0)
      *(1-COALESCE(NULLIF(x->>'discount_percent','')::numeric,0)/100)
      *(1+COALESCE(NULLIF(x->>'tax_rate','')::numeric,0)/100),2);
  END LOOP;

  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_MUST_BE_ARRAY';
  END IF;
  IF jsonb_array_length(p_items)<1 OR v_total<=0 THEN
    RAISE EXCEPTION 'PURCHASE_INVOICE_ITEMS_INVALID';
  END IF;

  v_fingerprint:=md5(jsonb_build_object(
    'supplier_id',p_supplier_id,'branch_id',p_branch_id,'due_date',p_due_date,
    'supplier_invoice_no',NULLIF(btrim(p_supplier_invoice_no),''),
    'notes',NULLIF(btrim(p_notes),''),'currency',v_currency,
    'settlement_source',p_settlement_source,'cash_custody_id',p_cash_custody_id,'items',p_items
  )::text);

  IF p_settlement_source='EMPLOYEE_CUSTODY' THEN
    IF p_cash_custody_id IS NULL THEN RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_REQUIRED'; END IF;
    SELECT * INTO v_custody FROM public.buyer_custodies
    WHERE id=p_cash_custody_id AND company_id=p_company_id AND employee_id=v_actor.id
      AND status IN ('Issued','UnderReview') AND acknowledged_at IS NOT NULL AND upper(currency)=v_currency
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_NOT_AVAILABLE'; END IF;

    SELECT COALESCE(SUM(amount),0) INTO v_acknowledged FROM public.buyer_custody_advances
    WHERE company_id=p_company_id AND custody_id=p_cash_custody_id AND acknowledged_at IS NOT NULL;

    SELECT COALESCE(SUM(amount),0) INTO v_committed FROM public.buyer_custody_expenses
    WHERE company_id=p_company_id AND custody_id=p_cash_custody_id AND status IN ('Submitted','Approved');

    SELECT COALESCE(SUM(total_amount),0) INTO v_reserved FROM public.purchase_invoices
    WHERE company_id=p_company_id AND cash_custody_id=p_cash_custody_id
      AND purchase_source='QUICK_MARKET' AND status='Draft' AND id<>p_invoice_id
      AND settlement_status='UNSETTLED';

    IF v_committed+v_reserved+v_total>v_acknowledged+0.005 THEN
      RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_LIMIT_EXCEEDED';
    END IF;
  ELSIF p_cash_custody_id IS NOT NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_CASH_CUSTODY_NOT_ALLOWED_FOR_SUPPLIER_CREDIT';
  END IF;

  v_result:=public.purchase_update_draft_invoice_atomic(
    p_company_id,p_invoice_id,p_supplier_id,NULL,p_branch_id,p_due_date,v_currency,v_actor.email,
    p_supplier_invoice_no,p_notes,p_items,p_operation_id
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

  RETURN v_result||jsonb_build_object('purchase_source','QUICK_MARKET','settlement_source',p_settlement_source);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. إثبات انتقال بضاعة السوق من المورد إلى عهدة المشتري
--    لا يغير stock_branches أو inventory_log أو supplier_ledger أو journal_entries.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.buyer_goods_custody_register_handover_atomic(
  p_company_id uuid,
  p_invoice_id uuid,
  p_vehicle_id uuid,
  p_items jsonb,
  p_evidence_path text,
  p_notes text,
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
  v_detail public.purchase_invoice_details%ROWTYPE;
  v_item jsonb;
  v_qty numeric(14,4);
  v_already numeric(14,4);
  v_fingerprint text;
  v_existing_count integer;
  v_inserted integer:=0;
  v_event_id uuid;
  v_events jsonb:='[]'::jsonb;
BEGIN
  SELECT * INTO v_actor FROM public.users
  WHERE auth_id=auth.uid() AND company_id=p_company_id AND COALESCE(status,'Active')='Active';
  IF NOT FOUND OR NOT app_private.current_user_has_effective_permission('purchases') THEN
    RAISE EXCEPTION 'BUYER_PURCHASE_PERMISSION_REQUIRED';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN RAISE EXCEPTION 'BUYER_GOODS_OPERATION_ID_REQUIRED'; END IF;
  IF COALESCE(jsonb_typeof(p_items),'')<>'array' THEN
    RAISE EXCEPTION 'BUYER_GOODS_ITEMS_MUST_BE_ARRAY';
  END IF;
  IF jsonb_array_length(p_items)<1 THEN
    RAISE EXCEPTION 'BUYER_GOODS_ITEMS_REQUIRED';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended('RAWAEA:BUYER-GOODS:'||p_company_id::text||':'||btrim(p_operation_id),0)
  );

  SELECT * INTO v_invoice FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'QUICK_MARKET'
     OR v_invoice.purchaser_user_id<>v_actor.id
     OR v_invoice.status<>'Draft'
     OR COALESCE(v_invoice.is_received,false)
     OR v_invoice.received_date IS NOT NULL
     OR v_invoice.branch_id IS NULL
     OR NULLIF(btrim(v_invoice.supplier_invoice_no),'') IS NULL THEN
    RAISE EXCEPTION 'QUICK_MARKET_INVOICE_NOT_ELIGIBLE_FOR_HANDOVER';
  END IF;

  IF p_vehicle_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.vehicles
    WHERE id=p_vehicle_id AND company_id=p_company_id AND COALESCE(status,'Active')='Active'
  ) THEN
    RAISE EXCEPTION 'BUYER_GOODS_VEHICLE_INVALID';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_items) x(item_code text,qty numeric)
    GROUP BY btrim(item_code) HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'BUYER_GOODS_DUPLICATE_ITEM';
  END IF;

  v_fingerprint:=md5(jsonb_build_object(
    'invoice_id',p_invoice_id,'vehicle_id',p_vehicle_id,
    'items',p_items,'evidence_path',p_evidence_path,'notes',p_notes
  )::text);

  SELECT count(*) INTO v_existing_count
  FROM public.buyer_goods_custody_events
  WHERE company_id=p_company_id AND operation_id=p_operation_id;

  IF v_existing_count>0 THEN
    IF EXISTS (
      SELECT 1 FROM public.buyer_goods_custody_events
      WHERE company_id=p_company_id AND operation_id=p_operation_id
        AND payload_fingerprint IS DISTINCT FROM v_fingerprint
    ) THEN
      RAISE EXCEPTION 'BUYER_GOODS_OPERATION_ID_PAYLOAD_CONFLICT';
    END IF;

    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'id',id,'item_id',item_id,'qty_delta',qty_delta,'event_type',event_type
    ) ORDER BY created_at),'[]'::jsonb)
    INTO v_events
    FROM public.buyer_goods_custody_events
    WHERE company_id=p_company_id AND operation_id=p_operation_id;

    RETURN jsonb_build_object('success',true,'duplicate',true,'invoice_id',p_invoice_id,'events',v_events);
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
    v_qty:=NULLIF(btrim(v_item->>'qty'),'')::numeric;
    IF v_qty IS NULL OR v_qty<=0 THEN
      RAISE EXCEPTION 'BUYER_GOODS_QTY_INVALID:%',v_item->>'item_code';
    END IF;

    SELECT * INTO v_detail
    FROM public.purchase_invoice_details
    WHERE invoice_id=p_invoice_id AND item_code=btrim(v_item->>'item_code')
    FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'BUYER_GOODS_ITEM_NOT_IN_INVOICE:%',v_item->>'item_code'; END IF;

    SELECT COALESCE(SUM(qty_delta),0) INTO v_already
    FROM public.buyer_goods_custody_events
    WHERE company_id=p_company_id
      AND source_document_type='PurchaseInvoice'
      AND source_document_id=p_invoice_id
      AND source_line_id=v_detail.id
      AND event_type='SUPPLIER_TO_BUYER_QUICK_MARKET';

    IF v_already+v_qty>v_detail.qty+0.0001 THEN
      RAISE EXCEPTION 'BUYER_GOODS_HANDOVER_EXCEEDS_INVOICE_QTY:%',v_detail.item_code;
    END IF;

    INSERT INTO public.buyer_goods_custody_events(
      company_id,branch_id,custodian_user_id,item_id,vehicle_id,event_type,qty_delta,
      source_document_type,source_document_id,source_line_id,operation_id,payload_fingerprint,
      evidence_path,actor_user_id,notes
    )
    VALUES(
      p_company_id,v_invoice.branch_id,v_actor.id,v_detail.item_id,p_vehicle_id,'SUPPLIER_TO_BUYER_QUICK_MARKET',v_qty,
      'PurchaseInvoice',p_invoice_id,v_detail.id,p_operation_id,v_fingerprint,
      NULLIF(btrim(p_evidence_path),''),v_actor.id,NULLIF(btrim(p_notes),'')
    )
    RETURNING id INTO v_event_id;

    v_inserted:=v_inserted+1;
  END LOOP;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id',id,'item_id',item_id,'qty_delta',qty_delta,'event_type',event_type
  ) ORDER BY created_at),'[]'::jsonb)
  INTO v_events
  FROM public.buyer_goods_custody_events
  WHERE company_id=p_company_id AND operation_id=p_operation_id;

  RETURN jsonb_build_object(
    'success',true,'duplicate',false,'invoice_id',p_invoice_id,
    'event_count',v_inserted,'events',v_events,
    'warehouse_stock_changed',false,'supplier_balance_changed',false
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- 6. قراءة رصيد الحيازة المشتق؛ المستخدم يرى نفسه، والمالية ترى الجميع
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
  WHERE auth_id=auth.uid() AND company_id=p_company_id AND COALESCE(status,'Active')='Active';
  IF NOT FOUND THEN RAISE EXCEPTION 'BUYER_GOODS_AUTH_REQUIRED'; END IF;

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
-- 7. حذف مسودة Quick Market فقط قبل أي حركة حيازة أو استلام أو مصروف
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
  WHERE auth.uid()=users.auth_id AND company_id=p_company_id AND COALESCE(status,'Active')='Active';
  IF NOT FOUND OR lower(v_actor.email)<>lower(COALESCE(p_actor,'')) THEN
    RAISE EXCEPTION 'BUYER_AUTH_REQUIRED';
  END IF;

  SELECT * INTO v_invoice FROM public.purchase_invoices
  WHERE id=p_invoice_id AND company_id=p_company_id FOR UPDATE;

  IF NOT FOUND OR v_invoice.purchase_source<>'QUICK_MARKET'
     OR v_invoice.purchaser_user_id<>v_actor.id THEN
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
-- 8. صلاحيات تنفيذ الوظائف الجديدة
-- ---------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_create_quick_market_invoice_atomic(uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.purchase_update_quick_market_invoice_atomic(uuid,uuid,uuid,uuid,date,text,text,jsonb,text,uuid,text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.buyer_goods_custody_register_handover_atomic(uuid,uuid,uuid,jsonb,text,text,text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.buyer_goods_custody_register_handover_atomic(uuid,uuid,uuid,jsonb,text,text,text)
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

-- ---------------------------------------------------------------------------
-- 9. عناصر مطلوبة قبل النشر — لا تُنفذ من هذا الملف وحده
-- ---------------------------------------------------------------------------
-- أ. تحديث مدخل save-purchase-order الحالي لإضافة العمليات:
--    CREATE_QUICK_MARKET_INVOICE
--    UPDATE_QUICK_MARKET_INVOICE
--    REGISTER_GOODS_HANDOVER
--    GET_GOODS_CUSTODY
--    DELETE_QUICK_MARKET_DRAFT
--    وكلها عبر profileClient.rpc مع JWT المستخدم، دون Edge Function جديدة.
--
-- ب. تحديث Buyer:
--    فصل Quick Market عن فاتورة PO؛ إخفاء cost_price؛ جعل vehicle_id اختياريًا؛
--    إضافة إثبات المورد→المشتري؛ عرض رصيد مشتق من buyer_goods_custody_events؛
--    عرض فواتير المستخدم الحالي فقط افتراضيًا.
--
-- ج. لا يضاف استلام Quick Market إلى Receiver هنا. يبقى زر ترحيل الفاتورة بلا PO
--    مرفوضًا في purchase_post_invoice_atomic حتى يكتمل عقد المرحلة الثانية.
--
-- د. لا يضاف مسار SupplierReturn أو قبول المورد هنا. يظل تنفيذ ذلك في مرحلة مستقلة
--    تتضمن ربط القسيمة المرتجعة والقبول الجزئي ومصدر حركة مخزون واحد.
--
-- هـ. لا تُجرى أي عملية UPDATE أو DELETE على الفواتير التاريخية SAR.
-- ---------------------------------------------------------------------------
