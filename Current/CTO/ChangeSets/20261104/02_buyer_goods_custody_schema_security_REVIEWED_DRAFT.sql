-- RAWAEA / SMART ERP
-- Buyer Goods Custody + Supplier Return + Quick Market Receiving
-- REVIEWED SCHEMA / SECURITY SCAFFOLD — NOT APPROVED FOR EXECUTION
-- Supersedes the first draft: 01_buyer_goods_custody_schema_security_DRAFT.sql
-- Production read-only basis: LVE615/LVE616, 2026-11-04.
--
-- IMPORTANT:
-- 1. This remains a schema scaffold only; it contains no replacement business RPCs,
--    Trigger bodies, Edge changes or app changes. It is NOT a deployable migration.
-- 2. Do not run on Production or Staging.
-- 3. No historic invoice/status/return values are inferred, converted or rewritten.
-- 4. purchase_returns.purchase_invoice_id remains NOT NULL in this scaffold.
--    Any relaxation requires a separate complete consumer scan and explicit migration.
-- 5. No existing stock_voucher / purchase_return status CHECK is dropped or replaced.
-- 6. Revoke direct DML from PUBLIC, anon and authenticated; retain current server writers.
-- 7. This file must be reconciled against a fresh schema + grants snapshot immediately
--    before approval and execution.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Purchase source / settlement source / responsible purchaser.
--    Preserve existing Posted SAR invoices and all legacy values as unclassified.
-- ---------------------------------------------------------------------------
ALTER TABLE public.purchase_invoices
  ADD COLUMN IF NOT EXISTS purchase_source text NOT NULL DEFAULT 'LEGACY_UNCLASSIFIED',
  ADD COLUMN IF NOT EXISTS settlement_source text NOT NULL DEFAULT 'UNSET',
  ADD COLUMN IF NOT EXISTS purchaser_user_id uuid,
  ADD COLUMN IF NOT EXISTS buyer_custody_id uuid,
  ADD COLUMN IF NOT EXISTS receipt_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS settlement_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED';

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
      AND conname='purchase_invoices_buyer_custody_fk'
  ) THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_buyer_custody_fk
      FOREIGN KEY (buyer_custody_id) REFERENCES public.buyer_custodies(id) ON DELETE RESTRICT NOT VALID;
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
      CHECK (settlement_source IN ('UNSET','SUPPLIER_CREDIT','EMPLOYEE_CUSTODY','TREASURY_CASH'));
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
      CHECK (settlement_status IN ('LEGACY_UNVERIFIED','UNSETTLED','PENDING_FINANCE','AP_OPEN','SETTLED','PAID'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS purchase_invoices_source_settlement_idx
  ON public.purchase_invoices(company_id, purchase_source, settlement_source, status, created_at DESC);

-- ---------------------------------------------------------------------------
-- 2. SupplierReturn recipient mode and actual issued quantity.
--    Recipient mode is NULL for non-SupplierReturn voucher types.
--    Never overload p_rep_id; custodian_user_id is the existing Buyer holder FK.
-- ---------------------------------------------------------------------------
ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS recipient_mode text,
  ADD COLUMN IF NOT EXISTS supplier_delegation_reference text,
  ADD COLUMN IF NOT EXISTS supplier_delegation_evidence_path text;

ALTER TABLE public.stock_voucher_details
  ADD COLUMN IF NOT EXISTS issued_qty numeric(14,4);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.stock_vouchers'::regclass
      AND conname='stock_vouchers_supplier_recipient_mode_ck'
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_supplier_recipient_mode_ck
      CHECK (
        (type <> 'SupplierReturn' AND recipient_mode IS NULL)
        OR (type = 'SupplierReturn'
            AND recipient_mode IS NOT NULL
            AND recipient_mode IN ('SUPPLIER_DIRECT','BUYER_DELEGATE'))
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.stock_vouchers'::regclass
      AND conname='stock_vouchers_supplier_delegate_ck'
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_supplier_delegate_ck
      CHECK (
        type <> 'SupplierReturn'
        OR (
          (recipient_mode='SUPPLIER_DIRECT'
            AND custodian_user_id IS NULL
            AND supplier_delegation_reference IS NULL
            AND supplier_delegation_evidence_path IS NULL)
          OR
          (recipient_mode='BUYER_DELEGATE'
            AND custodian_user_id IS NOT NULL
            AND NULLIF(btrim(COALESCE(supplier_delegation_reference,'')),'') IS NOT NULL
            AND NULLIF(btrim(COALESCE(supplier_delegation_evidence_path,'')),'') IS NOT NULL)
        )
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.stock_voucher_details'::regclass
      AND conname='stock_voucher_details_issued_qty_ck'
  ) THEN
    ALTER TABLE public.stock_voucher_details
      ADD CONSTRAINT stock_voucher_details_issued_qty_ck
      CHECK (issued_qty IS NULL OR (issued_qty >= 0 AND issued_qty <= qty)) NOT VALID;
  END IF;
END $$;

-- Acceptance quantities are intentionally NOT cached on stock_voucher_details.
-- Their source of truth is the append-only acceptance detail events below.
-- Existing return_currency DEFAULT is not changed here. Existing and future
-- SupplierReturn writers must derive currency from app_settings in their RPC.

-- ---------------------------------------------------------------------------
-- 3. Link the Parent financial return case to exactly one physical warehouse voucher.
--    Keep existing purchase_returns.purchase_invoice_id NOT NULL for now.
--    Do not replace its current status CHECK. Keep physical/financial lifecycle
--    in distinct additional columns.
-- ---------------------------------------------------------------------------
ALTER TABLE public.purchase_returns
  ADD COLUMN IF NOT EXISTS stock_voucher_id uuid,
  ADD COLUMN IF NOT EXISTS physical_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS financial_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS accepted_amount numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE public.purchase_return_details
  ADD COLUMN IF NOT EXISTS stock_voucher_detail_id uuid,
  ADD COLUMN IF NOT EXISTS issued_qty numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accepted_qty numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS rejected_qty numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS returned_to_warehouse_qty numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accepted_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accepted_tax_amount numeric(14,2) NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_returns'::regclass
      AND conname='purchase_returns_stock_voucher_fk'
  ) THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_stock_voucher_fk
      FOREIGN KEY (stock_voucher_id) REFERENCES public.stock_vouchers(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_returns'::regclass
      AND conname='purchase_returns_physical_status_ck'
  ) THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_physical_status_ck
      CHECK (physical_status IN ('LEGACY_UNVERIFIED','DRAFT','DISPATCHED','PARTIALLY_ACCEPTED','ACCEPTED','RETURNED_TO_WAREHOUSE','CANCELLED'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_returns'::regclass
      AND conname='purchase_returns_accepted_amount_ck'
  ) THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_accepted_amount_ck
      CHECK (accepted_amount >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_returns'::regclass
      AND conname='purchase_returns_financial_status_ck'
  ) THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_financial_status_ck
      CHECK (financial_status IN ('LEGACY_UNVERIFIED','NOT_POSTED','PARTIALLY_POSTED','POSTED','REVERSED'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_return_details'::regclass
      AND conname='purchase_return_details_stock_voucher_line_fk'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_stock_voucher_line_fk
      FOREIGN KEY (stock_voucher_detail_id) REFERENCES public.stock_voucher_details(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_return_details'::regclass
      AND conname='purchase_return_details_quantity_lifecycle_ck'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_quantity_lifecycle_ck
      CHECK (
        issued_qty >= 0
        AND accepted_qty >= 0
        AND rejected_qty >= 0
        AND returned_to_warehouse_qty >= 0
        AND accepted_qty + returned_to_warehouse_qty <= issued_qty
        AND rejected_qty <= issued_qty
      ) NOT VALID;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_returns_stock_voucher_uidx
  ON public.purchase_returns(stock_voucher_id)
  WHERE stock_voucher_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_return_details_stock_voucher_line_uidx
  ON public.purchase_return_details(stock_voucher_detail_id)
  WHERE stock_voucher_detail_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Supplier acceptance batches and lines.
--    One batch = one evidenced physical supplier acceptance. Partial batches
--    are permitted; RPC locks the return and checks cumulative quantities.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_return_acceptances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  return_id uuid NOT NULL REFERENCES public.purchase_returns(id) ON DELETE RESTRICT,
  acceptance_code text NOT NULL,
  acceptance_mode text NOT NULL,
  accepted_at timestamptz NOT NULL,
  supplier_representative_name text,
  supplier_receipt_ref text,
  supplier_credit_note_ref text,
  evidence_path text NOT NULL,
  recorded_by uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  operation_id text NOT NULL,
  payload_fingerprint text NOT NULL,
  journal_entry_id uuid,
  posted_at timestamptz,
  status text NOT NULL DEFAULT 'DRAFT',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_return_acceptances_mode_ck
    CHECK (acceptance_mode IN ('SUPPLIER_DIRECT','BUYER_DELEGATE')),
  CONSTRAINT purchase_return_acceptances_status_ck
    CHECK (status IN ('DRAFT','POSTED','CANCELLED')),
  CONSTRAINT purchase_return_acceptances_code_uk
    UNIQUE (company_id, acceptance_code),
  CONSTRAINT purchase_return_acceptances_operation_uk
    UNIQUE (company_id, operation_id)
);

CREATE TABLE IF NOT EXISTS public.purchase_return_acceptance_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  acceptance_id uuid NOT NULL REFERENCES public.purchase_return_acceptances(id) ON DELETE RESTRICT,
  return_detail_id uuid NOT NULL REFERENCES public.purchase_return_details(id) ON DELETE RESTRICT,
  stock_voucher_detail_id uuid NOT NULL REFERENCES public.stock_voucher_details(id) ON DELETE RESTRICT,
  accepted_qty numeric(14,4) NOT NULL DEFAULT 0,
  rejected_qty numeric(14,4) NOT NULL DEFAULT 0,
  accepted_amount numeric(14,2) NOT NULL DEFAULT 0,
  accepted_tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_return_acceptance_details_qty_ck
    CHECK (accepted_qty >= 0 AND rejected_qty >= 0 AND (accepted_qty + rejected_qty) > 0),
  CONSTRAINT purchase_return_acceptance_details_amount_ck
    CHECK (accepted_amount >= 0 AND accepted_tax_amount >= 0),
  CONSTRAINT purchase_return_acceptance_details_line_uk
    UNIQUE (acceptance_id, return_detail_id)
);

CREATE INDEX IF NOT EXISTS purchase_return_acceptances_return_idx
  ON public.purchase_return_acceptances(company_id, return_id, accepted_at DESC);
CREATE INDEX IF NOT EXISTS purchase_return_acceptance_details_return_line_idx
  ON public.purchase_return_acceptance_details(return_detail_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- 5. Append-only Buyer goods custody ledger (one row per item movement).
--    qty_delta > 0 = goods enter Buyer custody; qty_delta < 0 = goods leave it.
--    Event sums are authoritative; no cached/manual balance column.
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
      (event_type IN ('WAREHOUSE_TO_BUYER_SUPPLIER_RETURN','SUPPLIER_TO_BUYER_QUICK_MARKET')
        AND qty_delta > 0)
      OR
      (event_type IN ('BUYER_TO_WAREHOUSE_ACCEPTED','BUYER_TO_SUPPLIER_ACCEPTED','BUYER_TO_WAREHOUSE_RETURN')
        AND qty_delta < 0)
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

-- ---------------------------------------------------------------------------
-- 6. Quick Market invoice-to-Receiving linkage and rejected quantities.
--    Existing receiving.po_number is nullable, so no fabricated PO code is used.
-- ---------------------------------------------------------------------------
ALTER TABLE public.receiving
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'PURCHASE_ORDER',
  ADD COLUMN IF NOT EXISTS purchase_invoice_id uuid,
  ADD COLUMN IF NOT EXISTS branch_id uuid;

ALTER TABLE public.receiving_details
  ADD COLUMN IF NOT EXISTS item_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_invoice_detail_id uuid,
  ADD COLUMN IF NOT EXISTS qty_rejected numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS rejection_reason text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving'::regclass
      AND conname='receiving_source_type_ck'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_source_type_ck
      CHECK (source_type IN ('PURCHASE_ORDER','QUICK_MARKET_INVOICE'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving'::regclass
      AND conname='receiving_purchase_invoice_fk'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_purchase_invoice_fk
      FOREIGN KEY (purchase_invoice_id) REFERENCES public.purchase_invoices(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving'::regclass
      AND conname='receiving_branch_fk'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_branch_fk
      FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving_details'::regclass
      AND conname='receiving_details_item_fk'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_item_fk
      FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving_details'::regclass
      AND conname='receiving_details_invoice_line_fk'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_invoice_line_fk
      FOREIGN KEY (purchase_invoice_detail_id) REFERENCES public.purchase_invoice_details(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving_details'::regclass
      AND conname='receiving_details_rejected_qty_ck'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_rejected_qty_ck
      CHECK (qty_rejected >= 0) NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS receiving_purchase_invoice_idx
  ON public.receiving(company_id, purchase_invoice_id)
  WHERE purchase_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_details_invoice_line_idx
  ON public.receiving_details(purchase_invoice_detail_id)
  WHERE purchase_invoice_detail_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. Typed cash custody expense; preserve legacy classification explicitly.
--    This does not create a second cash-custody ledger.
-- ---------------------------------------------------------------------------
ALTER TABLE public.buyer_custody_expenses
  ADD COLUMN IF NOT EXISTS expense_category text NOT NULL DEFAULT 'LEGACY_UNCLASSIFIED',
  ADD COLUMN IF NOT EXISTS expense_account_id uuid,
  ADD COLUMN IF NOT EXISTS payee_kind text NOT NULL DEFAULT 'LEGACY_UNCLASSIFIED';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.buyer_custody_expenses'::regclass
      AND conname='buyer_custody_expenses_category_ck'
  ) THEN
    ALTER TABLE public.buyer_custody_expenses
      ADD CONSTRAINT buyer_custody_expenses_category_ck
      CHECK (expense_category IN ('LEGACY_UNCLASSIFIED','PURCHASE','FUEL','TRANSPORT','OTHER'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.buyer_custody_expenses'::regclass
      AND conname='buyer_custody_expenses_payee_kind_ck'
  ) THEN
    ALTER TABLE public.buyer_custody_expenses
      ADD CONSTRAINT buyer_custody_expenses_payee_kind_ck
      CHECK (payee_kind IN ('LEGACY_UNCLASSIFIED','SUPPLIER','EMPLOYEE','OTHER'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.buyer_custody_expenses'::regclass
      AND conname='buyer_custody_expenses_expense_account_fk'
  ) THEN
    ALTER TABLE public.buyer_custody_expenses
      ADD CONSTRAINT buyer_custody_expenses_expense_account_fk
      FOREIGN KEY (expense_account_id) REFERENCES public.chart_of_accounts(id) ON DELETE RESTRICT NOT VALID;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 8. Enforce append-only custody events.
--    This trigger blocks UPDATE/DELETE; controlled reversals use a new row.
-- ---------------------------------------------------------------------------
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
-- 9. Least-privilege access.
--    app_private.current_user_has_effective_permission(text) exists in Production.
--    Keep RLS as SELECT-only and let approved SECURITY DEFINER RPCs own writes.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS purchase_returns_company ON public.purchase_returns;
DROP POLICY IF EXISTS purchase_return_details_company ON public.purchase_return_details;

REVOKE ALL PRIVILEGES ON TABLE public.purchase_returns, public.purchase_return_details
  FROM PUBLIC, anon, authenticated;

GRANT SELECT ON TABLE public.purchase_returns, public.purchase_return_details TO authenticated;

CREATE POLICY purchase_returns_select_authorized
ON public.purchase_returns
FOR SELECT TO authenticated
USING (
  company_id = app_private.current_user_company_id()
  AND (
    app_private.current_user_has_effective_permission('purchases')
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
  )
);

CREATE POLICY purchase_return_details_select_authorized
ON public.purchase_return_details
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_returns r
    WHERE r.id = purchase_return_details.return_id
      AND r.company_id = app_private.current_user_company_id()
      AND (
        app_private.current_user_has_effective_permission('purchases')
        OR app_private.current_user_has_effective_permission('finance')
        OR app_private.current_user_has_effective_permission('finance_manager')
        OR app_private.current_user_has_effective_permission('reports')
      )
  )
);

ALTER TABLE public.purchase_return_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_return_acceptance_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buyer_goods_custody_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY purchase_return_acceptances_select_authorized
ON public.purchase_return_acceptances
FOR SELECT TO authenticated
USING (
  company_id = app_private.current_user_company_id()
  AND (
    app_private.current_user_has_effective_permission('purchases')
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
  )
);

CREATE POLICY purchase_return_acceptance_details_select_authorized
ON public.purchase_return_acceptance_details
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_return_acceptances a
    WHERE a.id = purchase_return_acceptance_details.acceptance_id
      AND a.company_id = app_private.current_user_company_id()
      AND (
        app_private.current_user_has_effective_permission('purchases')
        OR app_private.current_user_has_effective_permission('finance')
        OR app_private.current_user_has_effective_permission('finance_manager')
        OR app_private.current_user_has_effective_permission('reports')
      )
  )
);

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
    OR app_private.current_user_has_effective_permission('purchases')
    OR app_private.current_user_has_effective_permission('warehouse')
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
  )
);

REVOKE ALL PRIVILEGES ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details,
  public.buyer_goods_custody_events
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details,
  public.buyer_goods_custody_events
TO authenticated;

-- SECURITY DEFINER RPC ownership will provide server-side mutations. Do not
-- grant end-user INSERT/UPDATE/DELETE to any browser role.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details
TO service_role;

GRANT SELECT, INSERT ON TABLE public.buyer_goods_custody_events TO service_role;

-- ---------------------------------------------------------------------------
-- 10. Realtime publication. RLS is enabled above; event tables are append-only.
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'buyer_goods_custody_events',
    'purchase_return_acceptances',
    'purchase_return_acceptance_details',
    'receiving',
    'receiving_details'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename=t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------
-- 11. REQUIRED COMPANION CONTRACTS — NOT IMPLEMENTED IN THIS SCAFFOLD
-- ---------------------------------------------------------------------------
-- A. SECURITY DEFINER RPCs:
--    - warehouse create/update/delete draft voucher (SupplierReturn only)
--    - dispatch SupplierReturn and insert Buyer custody atomically for BUYER_DELEGATE
--    - create Supplier Direct acceptance at actual supplier pickup
--    - record supplier acceptance batches and accepted-value/tax-only posting
--    - Buyer return-to-warehouse with stock receipt and custody debit
--    - Quick Market invoice Draft + Supplier->Buyer handover
--    - Receiver PO / QUICK_MARKET_INVOICE receipt; accepted/rejected by invoice line
--    - Buyer goods-custody balance/list read with pagination and role scope
--    - typed cash expense submit/review preserving existing PO branch
--
-- B. Existing function/Edge updates; no new Edge Function:
--    - enforce_stock_voucher_custodian() for Buyer Delegate only; preserve mobile rules
--    - create_manual_stock_voucher_atomic_core / update core to persist recipient fields
--    - send_stock_voucher_atomic to set actual issued_qty + Buyer custody event atomically
--    - complete_manual_stock_voucher_atomic to refuse old full-value SupplierReturn posting;
--      linked acceptance writer posts supplier ledger, GL and tax for accepted quantity only
--    - purchase_create_return_atomic cumulative lock/quantity guard
--    - purchase_post_return_atomic for linked cases must NOT call post_stock_movement
--    - receive_purchase_atomic invoice-ID branch and all-zero quantity guard
--    - buyer_custody_review_expense_atomic separate QUICK_MARKET branch
--
-- C. Gating:
--    - do NOT drop purchase_returns.purchase_invoice_id NOT NULL until the full
--      dependent RPC/view/consumer scan is documented and historical rows reconciled.
--    - do NOT change purchase_returns.status CHECK until every consumer and
--      existing filter is updated. Use physical_status/financial_status instead.
--    - keep SupplierReturn return_currency derived from app_settings in all RPCs;
--      do not use browser SAR or a hardcoded currency default.
--    - inspect current storage bucket RLS before adding delegation/acceptance evidence upload.
--
-- D. This scaffold is not executable until exact source parity, companion RPC/Trigger,
--    security tests, schema-parity E2E, rollback and owner approval are complete.
