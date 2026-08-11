-- RAWAEA ERP — Reconciliation migration
-- Purpose: reconcile Production stock_vouchers with the deployed
-- complete_manual_stock_voucher_atomic RPC, which writes completed_by.
--
-- IMPORTANT: review and execute against Production only after CTO approval.
-- This file is intentionally idempotent and does not alter existing data.

ALTER TABLE public.stock_vouchers
ADD COLUMN IF NOT EXISTS completed_by text;

COMMENT ON COLUMN public.stock_vouchers.completed_by IS
'User identity that completed the stock voucher. Added to reconcile the Production stock_vouchers contract with complete_manual_stock_voucher_atomic.';

-- Verification after execution:
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'stock_vouchers'
--   AND column_name = 'completed_by';
