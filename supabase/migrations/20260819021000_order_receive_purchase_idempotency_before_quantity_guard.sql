-- Production-applied migration record.
-- Canonical runtime definition is the verified Production function
-- public.receive_purchase_atomic(uuid,text,text,jsonb,uuid).
-- This migration records the closure contract for reproducibility:
--   1. p_operation_id is required.
--   2. operation identity is checked before quantity-state rejection on retry.
--   3. a completed operation returns duplicate=true after payload validation.
--   4. all PO / branch lookups are company-scoped.
--   5. physical stock movement is delegated to public.post_stock_movement.
--
-- The full Production function definition is intentionally preserved by the
-- prior Production migration and is the authoritative runtime source for this
-- closure. This file exists as the durable migration ledger entry in Git.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.proname='receive_purchase_atomic'
      AND pg_get_function_identity_arguments(p.oid)='p_company_id uuid, p_po_code text, p_user_email text, p_items jsonb, p_operation_id uuid'
  ) THEN
    RAISE EXCEPTION 'Required Production function public.receive_purchase_atomic(uuid,text,text,jsonb,uuid) is missing';
  END IF;
END $$;

COMMIT;
