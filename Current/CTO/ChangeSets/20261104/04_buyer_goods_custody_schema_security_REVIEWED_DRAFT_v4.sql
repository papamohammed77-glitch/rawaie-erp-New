-- RAWAEA / SMART ERP
-- Buyer Goods Custody + Supplier Return + Quick Market Receiving
-- REVIEWED SCHEMA V4 — NON-EXECUTABLE PROPOSAL / NOT APPROVED
-- Supersedes v1, v2 and v3 as a design scaffold only.
--
-- PURPOSE
-- 1. Separate Buyer item custody from cash advances.
-- 2. Link one physical SupplierReturn stock voucher to one Parent purchase_returns row.
-- 3. Store supplier acceptance as append-only batches; do not duplicate aggregate counters
--    on purchase_return_details.
-- 4. Link Receiving lines to invoice lines and, when applicable, to one or more Buyer
--    custody events through an allocation table.
-- 5. Preserve existing purchase_returns.purchase_invoice_id NOT NULL and all existing
--    stock_voucher / purchase_return status constraints.
--
-- SAFETY
-- - DO NOT execute this file against Production or current Staging.
-- - This is additive schema/security only. It contains no complete RPC or replacement
--   Trigger definitions, no Edge source changes and no operational app changes.
-- - Fresh schema, grants, RLS, publication, function consumers, deployed source hashes,
--   storage policies and rollback must be revalidated immediately before approval.
-- - Existing Posted SAR invoices and legacy records remain untouched/unclassified.
-- - No new Edge Function is proposed.
-- - Exact owner approval under Master CTO §77.2 and the permanent charter is mandatory.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Purchase invoice source, settlement and physical/financial dimensions.
--    Existing invoices remain LEGACY_UNCLASSIFIED / UNSET / LEGACY_UNVERIFIED.
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
  ON public.purchase_invoices(company_id,purchase_source,settlement_source,status,created_at DESC);

-- ---------------------------------------------------------------------------
-- 2. SupplierReturn recipient/delegation and actual dispatched quantity.
--    NULL recipient_mode is preserved for all non-SupplierReturn voucher types.
--    Currency becomes nullable/no-default because it is meaningful only on
--    SupplierReturn; a server-side Trigger/RPC must populate company currency
--    on every new SupplierReturn before it can be sent or financially posted.
-- ---------------------------------------------------------------------------
ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS recipient_mode text,
  ADD COLUMN IF NOT EXISTS supplier_delegation_reference text,
  ADD COLUMN IF NOT EXISTS supplier_delegation_evidence_path text,
  ALTER COLUMN return_currency DROP DEFAULT,
  ALTER COLUMN return_currency DROP NOT NULL;

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
        OR
        (type = 'SupplierReturn'
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
          recipient_mode IS NOT NULL
          AND (
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
        )
      ) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.stock_vouchers'::regclass
      AND conname='stock_vouchers_supplier_currency_ck'
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_supplier_currency_ck
      CHECK (
        type <> 'SupplierReturn'
        OR (return_currency IS NOT NULL AND return_currency ~ '^[A-Z]{3}
    ALTER TABLE public.stock_voucher_details
      ADD CONSTRAINT stock_voucher_details_issued_qty_ck
      CHECK (issued_qty IS NULL OR (issued_qty >= 0 AND issued_qty <= qty)) NOT VALID;
  END IF;
END $$;

-- Do not assign issued_qty at Draft creation. The send RPC records the actual
-- dispatched quantity atomically with the branch stock-out and custody event.
-- For current full-line dispatch behavior, issued_qty may equal qty. A future
-- partial-dispatch UI must send explicit quantities and preserve the same guards.

-- ---------------------------------------------------------------------------
-- 3. Parent purchase_returns remains the sole financial return register.
--    Keep purchase_invoice_id NOT NULL and existing status CHECK unchanged.
--    Recipient is projected through the linked stock_vouchers row; do not create
--    a second mutable recipient/custodian field in purchase_returns.
-- ---------------------------------------------------------------------------
ALTER TABLE public.purchase_returns
  ADD COLUMN IF NOT EXISTS stock_voucher_id uuid,
  ADD COLUMN IF NOT EXISTS physical_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS financial_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS accepted_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS return_currency text;

ALTER TABLE public.purchase_return_details
  ADD COLUMN IF NOT EXISTS stock_voucher_detail_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_invoice_detail_id uuid,
  ADD COLUMN IF NOT EXISTS source_unit_price numeric(14,4),
  ADD COLUMN IF NOT EXISTS source_discount_percent numeric(8,4),
  ADD COLUMN IF NOT EXISTS source_tax_rate numeric(8,4),
  ADD COLUMN IF NOT EXISTS source_tax_code_id uuid;

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
      AND conname='purchase_returns_financial_status_ck'
  ) THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_financial_status_ck
      CHECK (financial_status IN ('LEGACY_UNVERIFIED','NOT_POSTED','PARTIALLY_POSTED','POSTED','AWAITING_REFUND_DISPOSITION','REVERSED'));
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
      AND conname='purchase_return_details_invoice_line_fk'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_invoice_line_fk
      FOREIGN KEY (purchase_invoice_detail_id) REFERENCES public.purchase_invoice_details(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_return_details'::regclass
      AND conname='purchase_return_details_source_discount_ck'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_source_discount_ck
      CHECK (source_discount_percent IS NULL OR source_discount_percent BETWEEN 0 AND 100) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_return_details'::regclass
      AND conname='purchase_return_details_source_tax_ck'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_source_tax_ck
      CHECK (source_tax_rate IS NULL OR source_tax_rate >= 0) NOT VALID;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_returns_stock_voucher_uidx
  ON public.purchase_returns(stock_voucher_id)
  WHERE stock_voucher_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_return_details_stock_voucher_line_uidx
  ON public.purchase_return_details(stock_voucher_detail_id)
  WHERE stock_voucher_detail_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_return_details_invoice_line_uidx
  ON public.purchase_return_details(purchase_invoice_detail_id)
  WHERE purchase_invoice_detail_id IS NOT NULL;

-- IMPORTANT SOURCE-OF-TRUTH RULE:
-- purchase_return_details.qty remains the requested/linked quantity for the
-- register. Actual dispatched quantity is stock_voucher_details.issued_qty.
-- Supplier acceptance/rejection is recorded only in acceptance detail events
-- below. No accepted/rejected/returned aggregate counters are added here.

-- ---------------------------------------------------------------------------
-- 4. Supplier acceptance batches. Each row is one evidenced physical attempt.
--    Rejections are historical observations and do not consume quantity; only
--    accepted quantities reduce Buyer custody or become eligible for AP/GL.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_return_acceptances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  return_id uuid NOT NULL REFERENCES public.purchase_returns(id) ON DELETE RESTRICT,
  acceptance_code text NOT NULL,
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
  status text NOT NULL DEFAULT 'AWAITING_FINANCE',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_return_acceptances_status_ck
    CHECK (status IN ('AWAITING_FINANCE','POSTED','REVERSED')),
  CONSTRAINT purchase_return_acceptances_code_uk
    UNIQUE (company_id,acceptance_code),
  CONSTRAINT purchase_return_acceptances_operation_uk
    UNIQUE (company_id,operation_id)
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
    UNIQUE (acceptance_id,return_detail_id)
);

CREATE INDEX IF NOT EXISTS purchase_return_acceptances_return_idx
  ON public.purchase_return_acceptances(company_id,return_id,accepted_at DESC);
CREATE INDEX IF NOT EXISTS purchase_return_acceptance_details_return_line_idx
  ON public.purchase_return_acceptance_details(return_detail_id,created_at DESC);

-- Cumulative accepted quantity is not a CHECK-only concern. RPCs must SELECT
-- purchase_returns + stock voucher source lines FOR UPDATE, then sum all
-- AWAITING_FINANCE + POSTED acceptance accepted_qty and posted return-to-
-- warehouse allocations while holding the same row locks. Rejected quantities
-- are not subtracted from the remaining source quantity so a later evidenced
-- supplier handover can retry. REVERSED is financial reversal only; it does
-- not erase the physical acceptance or custody event. Any physical return is
-- a new Receiving/event movement.

-- ---------------------------------------------------------------------------
-- 5. Append-only Buyer goods custody event ledger.
--    A positive delta enters Buyer custody; a negative delta leaves it.
--    Balance is calculated by server-side aggregate RPCs, never by editable
--    balance fields or a 500-row browser cache.
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
    UNIQUE (company_id,operation_id,source_line_id,event_type)
);

CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_balance_idx
  ON public.buyer_goods_custody_events(company_id,custodian_user_id,item_id,branch_id,created_at DESC);
CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_source_idx
  ON public.buyer_goods_custody_events(company_id,source_document_type,source_document_id);
CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_related_idx
  ON public.buyer_goods_custody_events(company_id,related_document_type,related_document_id)
  WHERE related_document_id IS NOT NULL;

-- One Receiving line can consume several source custody events (for example,
-- multiple supplier handovers on one invoice line). This allocation table is
-- the exact bridge; do not store one arbitrary custody_event_id on receiving_details.
CREATE TABLE IF NOT EXISTS public.receiving_detail_custody_allocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  receiving_detail_id uuid NOT NULL REFERENCES public.receiving_details(id) ON DELETE RESTRICT,
  custody_event_id uuid NOT NULL REFERENCES public.buyer_goods_custody_events(id) ON DELETE RESTRICT,
  allocated_qty numeric(14,4) NOT NULL CHECK (allocated_qty > 0),
  operation_id text NOT NULL,
  payload_fingerprint text NOT NULL,
  actor_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT receiving_detail_custody_allocations_operation_uk
    UNIQUE (company_id,operation_id,receiving_detail_id,custody_event_id)
);

CREATE INDEX IF NOT EXISTS receiving_detail_custody_allocations_event_idx
  ON public.receiving_detail_custody_allocations(company_id,custody_event_id);
CREATE INDEX IF NOT EXISTS receiving_detail_custody_allocations_receiving_idx
  ON public.receiving_detail_custody_allocations(company_id,receiving_detail_id);

-- ---------------------------------------------------------------------------
-- 6. Receiving sources: PO, Quick Market invoice, Buyer custody, and SupplierReturn
--    return-to-warehouse. Existing columns stay nullable for legacy receipts.
-- ---------------------------------------------------------------------------
ALTER TABLE public.receiving
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'PURCHASE_ORDER',
  ADD COLUMN IF NOT EXISTS purchase_invoice_id uuid,
  ADD COLUMN IF NOT EXISTS stock_voucher_id uuid,
  ADD COLUMN IF NOT EXISTS buyer_user_id uuid,
  ADD COLUMN IF NOT EXISTS branch_id uuid,
  ADD COLUMN IF NOT EXISTS source_document_code text;

ALTER TABLE public.receiving_details
  ADD COLUMN IF NOT EXISTS receiving_id uuid,
  ADD COLUMN IF NOT EXISTS item_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_invoice_detail_id uuid,
  ADD COLUMN IF NOT EXISTS stock_voucher_detail_id uuid,
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
      CHECK (source_type IN ('PURCHASE_ORDER','QUICK_MARKET_INVOICE','BUYER_CUSTODY','SUPPLIER_RETURN_TO_WAREHOUSE'));
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
      AND conname='receiving_stock_voucher_fk'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_stock_voucher_fk
      FOREIGN KEY (stock_voucher_id) REFERENCES public.stock_vouchers(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving'::regclass
      AND conname='receiving_buyer_user_fk'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_buyer_user_fk
      FOREIGN KEY (buyer_user_id) REFERENCES public.users(id) ON DELETE RESTRICT NOT VALID;
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
      AND conname='receiving_details_header_fk'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_header_fk
      FOREIGN KEY (receiving_id) REFERENCES public.receiving(id) ON DELETE RESTRICT NOT VALID;
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
      AND conname='receiving_details_stock_voucher_line_fk'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_stock_voucher_line_fk
      FOREIGN KEY (stock_voucher_detail_id) REFERENCES public.stock_voucher_details(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving_details'::regclass
      AND conname='receiving_details_rejected_qty_ck'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_rejected_qty_ck
      CHECK (qty_rejected >= 0 AND qty_received >= 0 AND qty_received + qty_rejected <= qty_expected) NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS receiving_purchase_invoice_idx
  ON public.receiving(company_id,purchase_invoice_id)
  WHERE purchase_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_stock_voucher_idx
  ON public.receiving(company_id,stock_voucher_id)
  WHERE stock_voucher_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_details_invoice_line_idx
  ON public.receiving_details(purchase_invoice_detail_id)
  WHERE purchase_invoice_detail_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_details_header_idx
  ON public.receiving_details(receiving_id)
  WHERE receiving_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. Typed cash custody expenses. Existing legacy expenses remain unclassified.
--    No new cash custody ledger is created; buyer_custodies stays authoritative.
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

-- Do not add account codes for Fuel/Transport/Other in this migration.
-- Finance must configure valid expense accounts; finance RPC rejects missing or
-- inactive/non-expense mappings. Employee-custody Purchase uses existing 127
-- and an invoice-linked receiving proof, not Supplier AP/Payment duplication.

-- ---------------------------------------------------------------------------
-- 8. Append-only enforcement. Corrections are compensating events, never edits.
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

CREATE OR REPLACE FUNCTION app_private.reject_receiving_custody_allocation_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO pg_catalog
AS $$
BEGIN
  RAISE EXCEPTION 'RECEIVING_CUSTODY_ALLOCATIONS_ARE_APPEND_ONLY';
END;
$$;

DROP TRIGGER IF EXISTS receiving_custody_allocations_append_only
  ON public.receiving_detail_custody_allocations;
CREATE TRIGGER receiving_custody_allocations_append_only
BEFORE UPDATE OR DELETE ON public.receiving_detail_custody_allocations
FOR EACH ROW EXECUTE FUNCTION app_private.reject_receiving_custody_allocation_mutation();

-- ---------------------------------------------------------------------------
-- 9. Least-privilege return/custody read access.
--    Existing purchase-return writes remain through SECURITY DEFINER RPC/Edge only.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS purchase_returns_company ON public.purchase_returns;
DROP POLICY IF EXISTS purchase_return_details_company ON public.purchase_return_details;
DROP POLICY IF EXISTS purchase_returns_select_authorized ON public.purchase_returns;
DROP POLICY IF EXISTS purchase_return_details_select_authorized ON public.purchase_return_details;

REVOKE ALL PRIVILEGES ON TABLE public.purchase_returns,public.purchase_return_details
  FROM PUBLIC,anon,authenticated;
GRANT SELECT ON TABLE public.purchase_returns,public.purchase_return_details TO authenticated;

CREATE POLICY purchase_returns_select_authorized
ON public.purchase_returns
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
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
    SELECT 1 FROM public.purchase_returns r
    WHERE r.id=purchase_return_details.return_id
      AND r.company_id=app_private.current_user_company_id()
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
ALTER TABLE public.receiving_detail_custody_allocations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS purchase_return_acceptances_select_authorized ON public.purchase_return_acceptances;
CREATE POLICY purchase_return_acceptances_select_authorized
ON public.purchase_return_acceptances
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
  AND (
    app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
    OR EXISTS (
      SELECT 1
      FROM public.purchase_returns r
      JOIN public.stock_vouchers v ON v.id=r.stock_voucher_id
      WHERE r.id=purchase_return_acceptances.return_id
        AND v.custodian_user_id=(
          SELECT u.id FROM public.users u
          WHERE u.auth_id=auth.uid()
            AND u.company_id=purchase_return_acceptances.company_id
            AND COALESCE(u.status,'Active')='Active'
          LIMIT 1
        )
    )
  )
);

DROP POLICY IF EXISTS purchase_return_acceptance_details_select_authorized ON public.purchase_return_acceptance_details;
CREATE POLICY purchase_return_acceptance_details_select_authorized
ON public.purchase_return_acceptance_details
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_return_acceptances a
    JOIN public.purchase_returns r ON r.id=a.return_id
    JOIN public.stock_vouchers v ON v.id=r.stock_voucher_id
    WHERE a.id=purchase_return_acceptance_details.acceptance_id
      AND a.company_id=app_private.current_user_company_id()
      AND (
        app_private.current_user_has_effective_permission('finance')
        OR app_private.current_user_has_effective_permission('finance_manager')
        OR app_private.current_user_has_effective_permission('reports')
        OR v.custodian_user_id=(
          SELECT u.id FROM public.users u
          WHERE u.auth_id=auth.uid()
            AND u.company_id=a.company_id
            AND COALESCE(u.status,'Active')='Active'
          LIMIT 1
        )
      )
  )
);

DROP POLICY IF EXISTS buyer_goods_custody_events_select_authorized ON public.buyer_goods_custody_events;
CREATE POLICY buyer_goods_custody_events_select_authorized
ON public.buyer_goods_custody_events
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
  AND (
    custodian_user_id=(
      SELECT u.id FROM public.users u
      WHERE u.auth_id=auth.uid()
        AND u.company_id=buyer_goods_custody_events.company_id
        AND COALESCE(u.status,'Active')='Active'
      LIMIT 1
    )
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
  )
);

DROP POLICY IF EXISTS receiving_detail_custody_allocations_select_authorized ON public.receiving_detail_custody_allocations;
CREATE POLICY receiving_detail_custody_allocations_select_authorized
ON public.receiving_detail_custody_allocations
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
  AND EXISTS (
    SELECT 1 FROM public.buyer_goods_custody_events e
    WHERE e.id=receiving_detail_custody_allocations.custody_event_id
      AND (
        e.custodian_user_id=(
          SELECT u.id FROM public.users u
          WHERE u.auth_id=auth.uid()
            AND u.company_id=receiving_detail_custody_allocations.company_id
            AND COALESCE(u.status,'Active')='Active'
          LIMIT 1
        )
        OR app_private.current_user_has_effective_permission('finance')
        OR app_private.current_user_has_effective_permission('finance_manager')
        OR app_private.current_user_has_effective_permission('reports')
      )
  )
);

REVOKE ALL PRIVILEGES ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details,
  public.buyer_goods_custody_events,
  public.receiving_detail_custody_allocations
FROM PUBLIC,anon,authenticated,service_role;

GRANT SELECT ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details,
  public.buyer_goods_custody_events,
  public.receiving_detail_custody_allocations
TO authenticated;

-- No direct browser or service_role DML grant is added here. Companion
-- SECURITY DEFINER RPCs are the only approved business writers. Their EXECUTE grants,
-- ownership, search_path, RLS bypass expectations and JWT checks must be reviewed
-- separately before this scaffold can be promoted to an executable migration.

-- ---------------------------------------------------------------------------
-- 10. Realtime publication. Add only after the corresponding RLS is approved.
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'buyer_goods_custody_events',
    'purchase_return_acceptances',
    'purchase_return_acceptance_details',
    'receiving_detail_custody_allocations',
    'receiving',
    'receiving_details',
    'stock_vouchers'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname='supabase_realtime'
        AND schemaname='public'
        AND tablename=t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',t);
    END IF;
  END LOOP;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------
-- 11. COMPANION CONTRACTS STILL REQUIRED — THIS FILE IS NOT EXECUTABLE
-- ---------------------------------------------------------------------------
-- A. Complete SECURITY DEFINER RPC bodies with fixed search_path and auth.uid():
--    - get_my_buyer_goods_custody + cursor-paged movements;
--    - record_quick_market_handover_atomic;
--    - create_buyer_custody_handover_atomic;
--    - receive_buyer_custody_handover_atomic;
--    - receive_quick_purchase_atomic (invoice ID mode);
--    - create_supplier_return_case_from_voucher_atomic;
--    - record_supplier_return_acceptance_atomic;
--    - purchase_post_return_acceptance_atomic (financial only; NEVER posts stock);
--    - SupplierReturn return-to-warehouse receipt;
--    - Quick Market cash-custody expense submit/review branch.
--
-- B. Existing function/Trigger replacements:
--    - enforce_stock_voucher_custodian: Supplier Direct/Buyer Delegate only,
--      preserve DirectSale/DirectReturn checks byte-for-byte in behavior;
--    - create/update SupplierReturn RPC: recipient fields + delegation evidence;
--    - send_stock_voucher_atomic: actual issued_qty + one stock-out + Buyer event;
--    - complete_manual_stock_voucher_atomic: linked case status only, no duplicate AP/GL;
--    - purchase_create_return_atomic: invoice source + cumulative row-locked quantity limit;
--    - purchase_post_return_atomic: linked cases financial-only; legacy unlinked branch gated;
--    - save_supplier_return_contract: app_settings currency, reject mismatch;
--    - both SupplierReturn financial writers validate stored currency;
--    - receive_purchase_atomic new invoice_id and receiving_id modes, preserve old po_code path;
--    - post_stock_movement accepts the dedicated BuyerCustodyReturnIn movement only
--      after its source/target/idempotency contract is validated.
--
-- C. Exact non-executable until:
--    - full SQL function bodies and grants are attached;
--    - deployed Edge source snapshots and operational Git source parity are proven;
--    - storage bucket/policies for supplier delegation and acceptance evidence are reviewed;
--    - all direct writers and every purchase_returns consumer are scanned;
--    - ACL/RLS negative JWT tests and positive RPC tests are specified;
--    - schema-parity staging and rollback tests pass;
--    - authenticated Buyer/Receiver/Parent E2E and business reconciliation pass;
--    - exact owner approval is recorded under Master CTO §77.2.
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

-- Do not assign issued_qty at Draft creation. The send RPC records the actual
-- dispatched quantity atomically with the branch stock-out and custody event.
-- For current full-line dispatch behavior, issued_qty may equal qty. A future
-- partial-dispatch UI must send explicit quantities and preserve the same guards.

-- ---------------------------------------------------------------------------
-- 3. Parent purchase_returns remains the sole financial return register.
--    Keep purchase_invoice_id NOT NULL and existing status CHECK unchanged.
--    Recipient is projected through the linked stock_vouchers row; do not create
--    a second mutable recipient/custodian field in purchase_returns.
-- ---------------------------------------------------------------------------
ALTER TABLE public.purchase_returns
  ADD COLUMN IF NOT EXISTS stock_voucher_id uuid,
  ADD COLUMN IF NOT EXISTS physical_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS financial_status text NOT NULL DEFAULT 'LEGACY_UNVERIFIED',
  ADD COLUMN IF NOT EXISTS accepted_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS return_currency text;

ALTER TABLE public.purchase_return_details
  ADD COLUMN IF NOT EXISTS stock_voucher_detail_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_invoice_detail_id uuid,
  ADD COLUMN IF NOT EXISTS source_unit_price numeric(14,4),
  ADD COLUMN IF NOT EXISTS source_discount_percent numeric(8,4),
  ADD COLUMN IF NOT EXISTS source_tax_rate numeric(8,4),
  ADD COLUMN IF NOT EXISTS source_tax_code_id uuid;

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
      AND conname='purchase_returns_financial_status_ck'
  ) THEN
    ALTER TABLE public.purchase_returns
      ADD CONSTRAINT purchase_returns_financial_status_ck
      CHECK (financial_status IN ('LEGACY_UNVERIFIED','NOT_POSTED','PARTIALLY_POSTED','POSTED','AWAITING_REFUND_DISPOSITION','REVERSED'));
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
      AND conname='purchase_return_details_invoice_line_fk'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_invoice_line_fk
      FOREIGN KEY (purchase_invoice_detail_id) REFERENCES public.purchase_invoice_details(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_return_details'::regclass
      AND conname='purchase_return_details_source_discount_ck'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_source_discount_ck
      CHECK (source_discount_percent IS NULL OR source_discount_percent BETWEEN 0 AND 100) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.purchase_return_details'::regclass
      AND conname='purchase_return_details_source_tax_ck'
  ) THEN
    ALTER TABLE public.purchase_return_details
      ADD CONSTRAINT purchase_return_details_source_tax_ck
      CHECK (source_tax_rate IS NULL OR source_tax_rate >= 0) NOT VALID;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_returns_stock_voucher_uidx
  ON public.purchase_returns(stock_voucher_id)
  WHERE stock_voucher_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_return_details_stock_voucher_line_uidx
  ON public.purchase_return_details(stock_voucher_detail_id)
  WHERE stock_voucher_detail_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS purchase_return_details_invoice_line_uidx
  ON public.purchase_return_details(purchase_invoice_detail_id)
  WHERE purchase_invoice_detail_id IS NOT NULL;

-- IMPORTANT SOURCE-OF-TRUTH RULE:
-- purchase_return_details.qty remains the requested/linked quantity for the
-- register. Actual dispatched quantity is stock_voucher_details.issued_qty.
-- Supplier acceptance/rejection is recorded only in acceptance detail events
-- below. No accepted/rejected/returned aggregate counters are added here.

-- ---------------------------------------------------------------------------
-- 4. Supplier acceptance batches. Each row is one evidenced physical attempt.
--    Rejections are historical observations and do not consume quantity; only
--    accepted quantities reduce Buyer custody or become eligible for AP/GL.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_return_acceptances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  return_id uuid NOT NULL REFERENCES public.purchase_returns(id) ON DELETE RESTRICT,
  acceptance_code text NOT NULL,
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
  status text NOT NULL DEFAULT 'AWAITING_FINANCE',
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_return_acceptances_status_ck
    CHECK (status IN ('AWAITING_FINANCE','POSTED','CANCELLED')),
  CONSTRAINT purchase_return_acceptances_code_uk
    UNIQUE (company_id,acceptance_code),
  CONSTRAINT purchase_return_acceptances_operation_uk
    UNIQUE (company_id,operation_id)
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
    UNIQUE (acceptance_id,return_detail_id)
);

CREATE INDEX IF NOT EXISTS purchase_return_acceptances_return_idx
  ON public.purchase_return_acceptances(company_id,return_id,accepted_at DESC);
CREATE INDEX IF NOT EXISTS purchase_return_acceptance_details_return_line_idx
  ON public.purchase_return_acceptance_details(return_detail_id,created_at DESC);

-- Cumulative accepted quantity is not a CHECK-only concern. RPCs must SELECT
-- purchase_returns + stock voucher source lines FOR UPDATE, then sum POSTED
-- acceptance accepted_qty and posted return-to-warehouse allocations while
-- holding the same row locks. Rejected quantities are not subtracted from the
-- remaining source quantity so a later evidenced supplier handover can retry.

-- ---------------------------------------------------------------------------
-- 5. Append-only Buyer goods custody event ledger.
--    A positive delta enters Buyer custody; a negative delta leaves it.
--    Balance is calculated by server-side aggregate RPCs, never by editable
--    balance fields or a 500-row browser cache.
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
    UNIQUE (company_id,operation_id,source_line_id,event_type)
);

CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_balance_idx
  ON public.buyer_goods_custody_events(company_id,custodian_user_id,item_id,branch_id,created_at DESC);
CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_source_idx
  ON public.buyer_goods_custody_events(company_id,source_document_type,source_document_id);
CREATE INDEX IF NOT EXISTS buyer_goods_custody_events_related_idx
  ON public.buyer_goods_custody_events(company_id,related_document_type,related_document_id)
  WHERE related_document_id IS NOT NULL;

-- One Receiving line can consume several source custody events (for example,
-- multiple supplier handovers on one invoice line). This allocation table is
-- the exact bridge; do not store one arbitrary custody_event_id on receiving_details.
CREATE TABLE IF NOT EXISTS public.receiving_detail_custody_allocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE RESTRICT,
  receiving_detail_id uuid NOT NULL REFERENCES public.receiving_details(id) ON DELETE RESTRICT,
  custody_event_id uuid NOT NULL REFERENCES public.buyer_goods_custody_events(id) ON DELETE RESTRICT,
  allocated_qty numeric(14,4) NOT NULL CHECK (allocated_qty > 0),
  operation_id text NOT NULL,
  payload_fingerprint text NOT NULL,
  actor_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT receiving_detail_custody_allocations_operation_uk
    UNIQUE (company_id,operation_id,receiving_detail_id,custody_event_id)
);

CREATE INDEX IF NOT EXISTS receiving_detail_custody_allocations_event_idx
  ON public.receiving_detail_custody_allocations(company_id,custody_event_id);
CREATE INDEX IF NOT EXISTS receiving_detail_custody_allocations_receiving_idx
  ON public.receiving_detail_custody_allocations(company_id,receiving_detail_id);

-- ---------------------------------------------------------------------------
-- 6. Receiving sources: PO, Quick Market invoice, Buyer custody, and SupplierReturn
--    return-to-warehouse. Existing columns stay nullable for legacy receipts.
-- ---------------------------------------------------------------------------
ALTER TABLE public.receiving
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'PURCHASE_ORDER',
  ADD COLUMN IF NOT EXISTS purchase_invoice_id uuid,
  ADD COLUMN IF NOT EXISTS stock_voucher_id uuid,
  ADD COLUMN IF NOT EXISTS buyer_user_id uuid,
  ADD COLUMN IF NOT EXISTS branch_id uuid,
  ADD COLUMN IF NOT EXISTS source_document_code text;

ALTER TABLE public.receiving_details
  ADD COLUMN IF NOT EXISTS receiving_id uuid,
  ADD COLUMN IF NOT EXISTS item_id uuid,
  ADD COLUMN IF NOT EXISTS purchase_invoice_detail_id uuid,
  ADD COLUMN IF NOT EXISTS stock_voucher_detail_id uuid,
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
      CHECK (source_type IN ('PURCHASE_ORDER','QUICK_MARKET_INVOICE','BUYER_CUSTODY','SUPPLIER_RETURN_TO_WAREHOUSE'));
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
      AND conname='receiving_stock_voucher_fk'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_stock_voucher_fk
      FOREIGN KEY (stock_voucher_id) REFERENCES public.stock_vouchers(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving'::regclass
      AND conname='receiving_buyer_user_fk'
  ) THEN
    ALTER TABLE public.receiving
      ADD CONSTRAINT receiving_buyer_user_fk
      FOREIGN KEY (buyer_user_id) REFERENCES public.users(id) ON DELETE RESTRICT NOT VALID;
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
      AND conname='receiving_details_header_fk'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_header_fk
      FOREIGN KEY (receiving_id) REFERENCES public.receiving(id) ON DELETE RESTRICT NOT VALID;
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
      AND conname='receiving_details_stock_voucher_line_fk'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_stock_voucher_line_fk
      FOREIGN KEY (stock_voucher_detail_id) REFERENCES public.stock_voucher_details(id) ON DELETE RESTRICT NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.receiving_details'::regclass
      AND conname='receiving_details_rejected_qty_ck'
  ) THEN
    ALTER TABLE public.receiving_details
      ADD CONSTRAINT receiving_details_rejected_qty_ck
      CHECK (qty_rejected >= 0 AND qty_received >= 0 AND qty_received + qty_rejected <= qty_expected) NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS receiving_purchase_invoice_idx
  ON public.receiving(company_id,purchase_invoice_id)
  WHERE purchase_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_stock_voucher_idx
  ON public.receiving(company_id,stock_voucher_id)
  WHERE stock_voucher_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_details_invoice_line_idx
  ON public.receiving_details(purchase_invoice_detail_id)
  WHERE purchase_invoice_detail_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS receiving_details_header_idx
  ON public.receiving_details(receiving_id)
  WHERE receiving_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 7. Typed cash custody expenses. Existing legacy expenses remain unclassified.
--    No new cash custody ledger is created; buyer_custodies stays authoritative.
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

-- Do not add account codes for Fuel/Transport/Other in this migration.
-- Finance must configure valid expense accounts; finance RPC rejects missing or
-- inactive/non-expense mappings. Employee-custody Purchase uses existing 127
-- and an invoice-linked receiving proof, not Supplier AP/Payment duplication.

-- ---------------------------------------------------------------------------
-- 8. Append-only enforcement. Corrections are compensating events, never edits.
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

CREATE OR REPLACE FUNCTION app_private.reject_receiving_custody_allocation_mutation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO pg_catalog
AS $$
BEGIN
  RAISE EXCEPTION 'RECEIVING_CUSTODY_ALLOCATIONS_ARE_APPEND_ONLY';
END;
$$;

DROP TRIGGER IF EXISTS receiving_custody_allocations_append_only
  ON public.receiving_detail_custody_allocations;
CREATE TRIGGER receiving_custody_allocations_append_only
BEFORE UPDATE OR DELETE ON public.receiving_detail_custody_allocations
FOR EACH ROW EXECUTE FUNCTION app_private.reject_receiving_custody_allocation_mutation();

-- ---------------------------------------------------------------------------
-- 9. Least-privilege return/custody read access.
--    Existing purchase-return writes remain through SECURITY DEFINER RPC/Edge only.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS purchase_returns_company ON public.purchase_returns;
DROP POLICY IF EXISTS purchase_return_details_company ON public.purchase_return_details;
DROP POLICY IF EXISTS purchase_returns_select_authorized ON public.purchase_returns;
DROP POLICY IF EXISTS purchase_return_details_select_authorized ON public.purchase_return_details;

REVOKE ALL PRIVILEGES ON TABLE public.purchase_returns,public.purchase_return_details
  FROM PUBLIC,anon,authenticated;
GRANT SELECT ON TABLE public.purchase_returns,public.purchase_return_details TO authenticated;

CREATE POLICY purchase_returns_select_authorized
ON public.purchase_returns
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
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
    SELECT 1 FROM public.purchase_returns r
    WHERE r.id=purchase_return_details.return_id
      AND r.company_id=app_private.current_user_company_id()
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
ALTER TABLE public.receiving_detail_custody_allocations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS purchase_return_acceptances_select_authorized ON public.purchase_return_acceptances;
CREATE POLICY purchase_return_acceptances_select_authorized
ON public.purchase_return_acceptances
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
  AND (
    app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
    OR EXISTS (
      SELECT 1
      FROM public.purchase_returns r
      JOIN public.stock_vouchers v ON v.id=r.stock_voucher_id
      WHERE r.id=purchase_return_acceptances.return_id
        AND v.custodian_user_id=(
          SELECT u.id FROM public.users u
          WHERE u.auth_id=auth.uid()
            AND u.company_id=purchase_return_acceptances.company_id
            AND COALESCE(u.status,'Active')='Active'
          LIMIT 1
        )
    )
  )
);

DROP POLICY IF EXISTS purchase_return_acceptance_details_select_authorized ON public.purchase_return_acceptance_details;
CREATE POLICY purchase_return_acceptance_details_select_authorized
ON public.purchase_return_acceptance_details
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.purchase_return_acceptances a
    JOIN public.purchase_returns r ON r.id=a.return_id
    JOIN public.stock_vouchers v ON v.id=r.stock_voucher_id
    WHERE a.id=purchase_return_acceptance_details.acceptance_id
      AND a.company_id=app_private.current_user_company_id()
      AND (
        app_private.current_user_has_effective_permission('finance')
        OR app_private.current_user_has_effective_permission('finance_manager')
        OR app_private.current_user_has_effective_permission('reports')
        OR v.custodian_user_id=(
          SELECT u.id FROM public.users u
          WHERE u.auth_id=auth.uid()
            AND u.company_id=a.company_id
            AND COALESCE(u.status,'Active')='Active'
          LIMIT 1
        )
      )
  )
);

DROP POLICY IF EXISTS buyer_goods_custody_events_select_authorized ON public.buyer_goods_custody_events;
CREATE POLICY buyer_goods_custody_events_select_authorized
ON public.buyer_goods_custody_events
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
  AND (
    custodian_user_id=(
      SELECT u.id FROM public.users u
      WHERE u.auth_id=auth.uid()
        AND u.company_id=buyer_goods_custody_events.company_id
        AND COALESCE(u.status,'Active')='Active'
      LIMIT 1
    )
    OR app_private.current_user_has_effective_permission('finance')
    OR app_private.current_user_has_effective_permission('finance_manager')
    OR app_private.current_user_has_effective_permission('reports')
  )
);

DROP POLICY IF EXISTS receiving_detail_custody_allocations_select_authorized ON public.receiving_detail_custody_allocations;
CREATE POLICY receiving_detail_custody_allocations_select_authorized
ON public.receiving_detail_custody_allocations
FOR SELECT TO authenticated
USING (
  company_id=app_private.current_user_company_id()
  AND EXISTS (
    SELECT 1 FROM public.buyer_goods_custody_events e
    WHERE e.id=receiving_detail_custody_allocations.custody_event_id
      AND (
        e.custodian_user_id=(
          SELECT u.id FROM public.users u
          WHERE u.auth_id=auth.uid()
            AND u.company_id=receiving_detail_custody_allocations.company_id
            AND COALESCE(u.status,'Active')='Active'
          LIMIT 1
        )
        OR app_private.current_user_has_effective_permission('finance')
        OR app_private.current_user_has_effective_permission('finance_manager')
        OR app_private.current_user_has_effective_permission('reports')
      )
  )
);

REVOKE ALL PRIVILEGES ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details,
  public.buyer_goods_custody_events,
  public.receiving_detail_custody_allocations
FROM PUBLIC,anon,authenticated;

GRANT SELECT ON TABLE
  public.purchase_return_acceptances,
  public.purchase_return_acceptance_details,
  public.buyer_goods_custody_events,
  public.receiving_detail_custody_allocations
TO authenticated;

-- No direct browser/service-role DML grant is added here. Companion SECURITY
-- DEFINER RPCs are the only approved business writers. Their EXECUTE grants,
-- ownership, search_path, RLS bypass expectations and JWT checks must be reviewed
-- separately before this scaffold can be promoted to an executable migration.

-- ---------------------------------------------------------------------------
-- 10. Realtime publication. Add only after the corresponding RLS is approved.
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'buyer_goods_custody_events',
    'purchase_return_acceptances',
    'purchase_return_acceptance_details',
    'receiving_detail_custody_allocations',
    'receiving',
    'receiving_details',
    'stock_vouchers'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname='supabase_realtime'
        AND schemaname='public'
        AND tablename=t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',t);
    END IF;
  END LOOP;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------
-- 11. COMPANION CONTRACTS STILL REQUIRED — THIS FILE IS NOT EXECUTABLE
-- ---------------------------------------------------------------------------
-- A. Complete SECURITY DEFINER RPC bodies with fixed search_path and auth.uid():
--    - get_my_buyer_goods_custody + cursor-paged movements;
--    - record_quick_market_handover_atomic;
--    - create_buyer_custody_handover_atomic;
--    - receive_buyer_custody_handover_atomic;
--    - receive_quick_purchase_atomic (invoice ID mode);
--    - create_supplier_return_case_from_voucher_atomic;
--    - record_supplier_return_acceptance_atomic;
--    - purchase_post_return_acceptance_atomic (financial only; NEVER posts stock);
--    - SupplierReturn return-to-warehouse receipt;
--    - Quick Market cash-custody expense submit/review branch.
--
-- B. Existing function/Trigger replacements:
--    - enforce_stock_voucher_custodian: Supplier Direct/Buyer Delegate only,
--      preserve DirectSale/DirectReturn checks byte-for-byte in behavior;
--    - create/update SupplierReturn RPC: recipient fields + delegation evidence;
--    - send_stock_voucher_atomic: actual issued_qty + one stock-out + Buyer event;
--    - complete_manual_stock_voucher_atomic: linked case status only, no duplicate AP/GL;
--    - purchase_create_return_atomic: invoice source + cumulative row-locked quantity limit;
--    - purchase_post_return_atomic: linked cases financial-only; legacy unlinked branch gated;
--    - save_supplier_return_contract: app_settings currency, reject mismatch;
--    - both SupplierReturn financial writers validate stored currency;
--    - receive_purchase_atomic new invoice_id and receiving_id modes, preserve old po_code path;
--    - post_stock_movement accepts the dedicated BuyerCustodyReturnIn movement only
--      after its source/target/idempotency contract is validated.
--
-- C. Exact non-executable until:
--    - full SQL function bodies and grants are attached;
--    - deployed Edge source snapshots and operational Git source parity are proven;
--    - storage bucket/policies for supplier delegation and acceptance evidence are reviewed;
--    - all direct writers and every purchase_returns consumer are scanned;
--    - ACL/RLS negative JWT tests and positive RPC tests are specified;
--    - schema-parity staging and rollback tests pass;
--    - authenticated Buyer/Receiver/Parent E2E and business reconciliation pass;
--    - exact owner approval is recorded under Master CTO §77.2.
