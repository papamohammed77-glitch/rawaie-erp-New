-- RAWAEA ERP
-- P0 schema repair: reconcile stock_vouchers with the deployed
-- complete_manual_stock_voucher_atomic RPC, which writes completed_by.
--
-- IMPORTANT: execute against Production only after CTO approval.
-- Idempotent. Does not alter existing data.

ALTER TABLE public.stock_vouchers
ADD COLUMN IF NOT EXISTS completed_by text;

COMMENT ON COLUMN public.stock_vouchers.completed_by IS
'User identity that completed the stock voucher; populated by the atomic voucher completion RPC.';

-- RLS NOTE:
-- Adding a column does not require a new RLS policy.
-- Existing row-level policies on public.stock_vouchers remain unchanged.
-- DO NOT add a broad policy such as USING (true) merely because this column was added.
-- The completion RPC is SECURITY DEFINER and remains governed by its existing
-- privilege model and internal validation.

-- POST-DEPLOYMENT VERIFICATION (read-only):
SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'stock_vouchers'
  AND column_name = 'completed_by';
