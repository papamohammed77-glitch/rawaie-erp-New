-- RAWAEA / SMART ERP
-- Buyer Goods Custody + Supplier Return + Quick Market Receiving
-- SCHEMA / SECURITY DRAFT ONLY — NOT APPROVED FOR EXECUTION
-- Supersedes DRAFT v1: removes duplicate returned_to_warehouse_qty from stock_voucher_details; aggregate return-to-warehouse quantity is tracked on purchase_return_details.
-- Snapshot basis: Production read-only review 2026-11-04 / LVE615.
-- This file intentionally contains additive schema and grants only.
-- It is NOT a complete deployable migration until the companion RPC/Trigger
-- definitions, existing Edge diffs, application diffs, acceptance tests,
-- rollback, and explicit owner approval are attached.
-- Do not run this file against Production or Staging as-is.

BEGIN;

-- 1) Explicit source and settlement classification.
-- Existing records remain LEGACY_UNCLASSIFIED / UNSET; do not infer old intent.
ALTER TABLE public.purchase_invoices
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'LEGACY_UNCLASSIFIED',
  ADD COLUMN IF NOT EXISTS settlement_source text NOT NULL DEFAULT 'UNSET';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_invoices'::regclass AND conname='purchase_invoices_source_type_ck') THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_source_type_ck
      CHECK (source_type IN ('LEGACY_UNCLASSIFIED','PURCHASE_ORDER','QUICK_MARKET'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_invoices'::regclass AND conname='purchase_invoices_settlement_source_ck') THEN
    ALTER TABLE public.purchase_invoices
      ADD CONSTRAINT purchase_invoices_settlement_source_ck
      CHECK (settlement_source IN ('UNSET','SUPPLIER_CREDIT','BUYER_CASH_CUSTODY'));
  END IF;
END $$;

-- 2) Physical SupplierReturn recipient / issued quantities.
ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS recipient_mode text NOT NULL DEFAULT 'SUPPLIER_DIRECT';

ALTER TABLE public.stock_voucher_details
  ADD COLUMN IF NOT EXISTS issued_qty numeric(14,4);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.stock_vouchers'::regclass AND conname='stock_vouchers_recipient_mode_ck') THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_recipient_mode_ck
      CHECK (recipient_mode IN ('SUPPLIER_DIRECT','BUYER_DELEGATE'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.stock_voucher_details'::regclass AND conname='stock_voucher_details_issued_qty_ck') THEN
    ALTER TABLE public.stock_voucher_details
      ADD CONSTRAINT stock_voucher_details_issued_qty_ck
      CHECK (issued_qty IS NULL OR (issued_qty >= 0 AND issued_qty <= qty));
  END IF;
END $$;

-- 3) One Parent-visible return case linked uniquely to its physical voucher.
ALTER TABLE public.purchase_returns
  ALTER COLUMN purchase_invoice_id DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS stock_voucher_id uuid,
  ADD COLUMN IF NOT EXISTS recipient_mode text NOT NULL DEFAULT 'SUPPLIER_DIRECT',
  ADD COLUMN IF NOT EXISTS recipient_user_id uuid,
  ADD COLUMN IF NOT EXISTS accepted_amount numeric(14,2) NOT NULL DEFAULT 0;

ALTER TABLE public.purchase_return_details
  ADD COLUMN IF NOT EXISTS stock_voucher_detail_id uuid,
  ADD COLUMN IF NOT EXISTS accepted_qty numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS returned_to_warehouse_qty numeric(14,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS accepted_amount numeric(14,2) NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_returns'::regclass AND conname='purchase_returns_stock_voucher_fk') THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_stock_voucher_fk
      FOREIGN KEY (stock_voucher_id) REFERENCES public.stock_vouchers(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_returns'::regclass AND conname='purchase_returns_recipient_user_fk') THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_recipient_user_fk
      FOREIGN KEY (recipient_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_returns'::regclass AND conname='purchase_returns_recipient_mode_ck') THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_recipient_mode_ck
      CHECK (
        (recipient_mode='SUPPLIER_DIRECT' AND recipient_user_id IS NULL)
        OR (recipient_mode='BUYER_DELEGATE' AND recipient_user_id IS NOT NULL)
      );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_returns'::regclass AND conname='purchase_returns_status_check') THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_status_check
      CHECK (status IN ('Draft','InBuyerCustody','AwaitingSupplierAcceptance','AwaitingFinance','PartiallyPosted','Posted','ReturnedToWarehouse','Cancelled'));
  ELSE
    ALTER TABLE public.purchase_returns DROP CONSTRAINT purchase_returns_status_check;
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_status_check
      CHECK (status IN ('Draft','PartiallyPosted','Posted','Cancelled'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_return_details'::regclass AND conname='purchase_return_details_voucher_line_fk') THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_voucher_line_fk
      FOREIGN KEY (stock_voucher_detail_id) REFERENCES public.stock_voucher_details(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.purchase_return_details'::regclass AND conname='purchase_return_details_accepted_qty_ck') THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_accepted_qty_ck
      CHECK (accepted_qty >= 0 AND returned_to_warehouse_qty >= 0 AND accepted_qty + returned_to_warehouse_qty <= qty);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_returns_stock_voucher_uidx
  ON public.purchase_returns(stock_voucher_id)
  WHERE stock_voucher_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_return_details_voucher_line_uidx
  ON public.purchase_return_details(stock_voucher_detail_id)
  WHERE stock_voucher_detail_id IS NOT NULL;

-- 4) Multiple supplier acceptance batches; each batch is independently idempotent.
CREATE TABLE IF NOT EXISTS public.purchase_return_acceptances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  return_id uuid NOT NULL REFERENCES public.purchase_returns(id) ON DELETE RESTRICT,
  acceptance_code text NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  supplier_receipt_ref text,
  evidence_path text,
  accepted_by uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  operation_id text NOT NULL,
  status text NOT NULL DEFAULT 'Draft',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_return_acceptances_status_ck
    CHECK (status IN ('Draft','AwaitingFinance','Posted','Cancelled')),
  CONSTRAINT purchase_return_acceptances_company_code_uk
    UNIQUE (company_id, acceptance_code),
  CONSTRAINT purchase_return_acceptances_operation_uk
    UNIQUE (company_id, operation_id)
);

CREATE TABLE IF NOT EXISTS public.purchase_return_acceptance_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  acceptance_id uuid NOT NULL REFERENCES public.purchase_return_acceptances(id) ON DELETE RESTRICT,
  return_detail_id uuid NOT NULL REFERENCES public.purchase_return_details(id) ON DELETE RESTRICT,
  item_id uuid NOT NULL REFERENCES public.items(id) ON DELETE RESTRICT,
  item_code text NOT NULL,
  accepted_qty numeric(14,4) NOT NULL CHECK (accepted_qty > 0),
  unit_price numeric(14,4) NOT NULL CHECK (unit_price >= 0),
  accepted_amount numeric(14,2) NOT NULL CHECK (accepted_amount >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_return_acceptance_details_line_uk
    UNIQUE (acceptance_id, return_detail_id)
);

-- 5) Immutable item-level Buyer goods custody event ledger.
CREATE TABLE IF NOT EXISTS public.buyer_goods_custody_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  custodian_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  item_id uuid NOT NULL REFERENCES public.items(id) ON DELETE RESTRICT,
  event_type text NOT NULL,
  qty_delta numeric(14,4) NOT NULL CHECK (qty_delta <> 0),
  source_document_type text NOT NULL,
  source_document_id uuid NOT NULL,
  source_line_id uuid NOT NULL,
  related_document_type text,
  related_document_id uuid,
  operation_id text NOT NULL,
  evidence_path text,
  actor_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  reverses_event_id uuid REFERENCES public.buyer_goods_custody_events(id) ON DELETE RESTRICT,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT buyer_goods_custody_events_type_ck
    CHECK (event_type IN (
      'WAREHOUSE_TO_BUYER',
      'QUICK_MARKET_SUPPLIER_TO_BUYER',
      'BUYER_TO_WAREHOUSE',
      'BUYER_TO_SUPPLIER_ACCEPTED',
      'BUYER_CUSTODY_CORRECTION'
    )),
  CONSTRAINT buyer_goods_custody_events_operation_uk
    UNIQUE (company_id, operation_id, source_line_id, event_type)
);

CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_balance_idx
  ON public.buyer_goods_custody_events(company_id, custodian_user_id, item_id, created_at DESC);
CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_source_idx
  ON public.buyer_goods_custody_events(company_id, source_document_type, source_document_id);
CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_branch_idx
  ON public.buyer_goods_custody_events(company_id, branch_id, created_at DESC);

-- 6) Quick Market invoice-to-Receiving header/line links.
ALTER TABLE public.receiving
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'PURCHASE_ORDER',
  ADD COLUMN IF NOT EXISTS purchase_invoice_id uuid,
  ADD COLUMN IF NOT EXISTS buyer_user_id uuid,
  ADD COLUMN IF NOT EXISTS source_document_code text,
  ADD COLUMN IF NOT EXISTS branch_id uuid;

ALTER TABLE public.receiving_details
  ADD COLUMN IF NOT EXISTS item_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_invoice_detail_id uuid,
  ADD COLUMN IF NOT EXISTS buyer_custody_event_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving'::regclass AND conname='receiving_source_type_ck') THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_source_type_ck
      CHECK (source_type IN ('PURCHASE_ORDER','QUICK_MARKET_INVOICE','BUYER_CUSTODY'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving'::regclass AND conname='receiving_purchase_invoice_fk') THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_purchase_invoice_fk
      FOREIGN KEY (purchase_invoice_id) REFERENCES public.purchase_invoices(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving'::regclass AND conname='receiving_branch_fk') THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_branch_fk
      FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving_details'::regclass AND conname='receiving_details_item_fk') THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_item_fk
      FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving'::regclass AND conname='receiving_buyer_user_fk') THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_buyer_user_fk
      FOREIGN KEY (buyer_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving_details'::regclass AND conname='receiving_details_buyer_event_fk') THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_buyer_event_fk
      FOREIGN KEY (buyer_custody_event_id) REFERENCES public.buyer_goods_custody_events(id) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.receiving_details'::regclass AND conname='receiving_details_invoice_line_fk') THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_invoice_line_fk
      FOREIGN KEY (purchase_invoice_detail_id) REFERENCES public.purchase_invoice_details(id) ON DELETE RESTRICT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS receiving_purchase_invoice_idx
  ON public.receiving(company_id, purchase_invoice_id)
  WHERE purchase_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_details_invoice_line_idx
  ON public.receiving_details(purchase_invoice_detail_id)
  WHERE purchase_invoice_detail_id IS NOT NULL;

-- 7) Explicit expense classification; legacy rows remain OTHER.
ALTER TABLE public.buyer_custody_expenses
  ADD COLUMN IF NOT EXISTS expense_category text NOT NULL DEFAULT 'OTHER',
  ADD COLUMN IF NOT EXISTS expense_account_id uuid,
  ADD COLUMN IF NOT EXISTS payee_kind text NOT NULL DEFAULT 'SUPPLIER';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.buyer_custody_expenses'::regclass AND conname='buyer_custody_expenses_category_ck') THEN
    ALTER TABLE public.buyer_custody_expenses
      ADD CONSTRAINT buyer_custody_expenses_category_ck
      CHECK (expense_category IN ('PURCHASE','FUEL','TRANSPORT','OTHER'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.buyer_custody_expenses'::regclass AND conname='buyer_custody_expenses_payee_kind_ck') THEN
    ALTER TABLE public.buyer_custody_expenses
      ADD CONSTRAINT buyer_custody_expenses_payee_kind_ck
      CHECK (payee_kind IN ('SUPPLIER','EMPLOYEE','OTHER'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.buyer_custody_expenses'::regclass AND conname='buyer_custody_expenses_expense_account_fk') THEN
    ALTER TABLE public.buyer_custody_expenses
      ADD CONSTRAINT buyer_custody_expenses_expense_account_fk
      FOREIGN KEY (expense_account_id) REFERENCES public.chart_of_accounts(id) ON DELETE RESTRICT;
  END IF;
END $$;

-- 8) Append-only enforcement for the custody event ledger.
CREATE OR REPLACE FUNCTION app_private.reject_buyer_goods_custody_event_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
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

-- 9) Least-privilege return access. Existing Parent reads remain available
-- to authenticated procurement/finance/report users; direct client writes stop.
DROP POLICY IF EXISTS purchase_returns_company ON public.purchase_returns;
DROP POLICY IF EXISTS purchase_return_details_company ON public.purchase_return_details;

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

REVOKE ALL ON TABLE public.purchase_returns FROM anon, authenticated;
REVOKE ALL ON TABLE public.purchase_return_details FROM anon, authenticated;
GRANT SELECT ON TABLE public.purchase_returns TO authenticated;
GRANT SELECT ON TABLE public.purchase_return_details TO authenticated;

-- New tables are read-only to clients; writes are only through SECURITY DEFINER RPCs.
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

REVOKE ALL ON TABLE public.purchase_return_acceptances FROM anon, authenticated;
REVOKE ALL ON TABLE public.purchase_return_acceptance_details FROM anon, authenticated;
REVOKE ALL ON TABLE public.buyer_goods_custody_events FROM anon, authenticated;
GRANT SELECT ON TABLE public.purchase_return_acceptances TO authenticated;
GRANT SELECT ON TABLE public.purchase_return_acceptance_details TO authenticated;
GRANT SELECT ON TABLE public.buyer_goods_custody_events TO authenticated;

-- Service role is the only direct API writer; SECURITY DEFINER RPCs execute as owner.
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.purchase_return_acceptances TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.purchase_return_acceptance_details TO service_role;
GRANT SELECT, INSERT ON TABLE public.buyer_goods_custody_events TO service_role;

-- 10) Realtime publication for Buyer/Receiver cross-application refresh.
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

-- Mandatory before execution:
-- 1. Add complete RPCs for create/send/accept/return-to-warehouse/read and Quick Market receipt.
-- 2. Replace existing Trigger/RPC bodies with single-writer and quantity/idempotency guards.
-- 3. Confirm all existing direct writers and Parent read roles against current source.
-- 4. Add RLS negative tests using real JWTs; do not rely on postgres/service-role SQL context.
-- 5. Add migration rollback and test it on a schema-parity environment.
-- 6. Obtain exact changeset approval under Report614_NEW_P / Master CTO §77.2.
