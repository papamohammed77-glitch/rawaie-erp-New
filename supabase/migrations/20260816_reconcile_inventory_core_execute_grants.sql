-- Inventory Core security reconciliation
-- Remove implicit PUBLIC/anon/authenticated EXECUTE from central/orchestration functions.
-- service_role remains the execution context used by Edge adapters.

REVOKE EXECUTE ON FUNCTION public.post_inventory_adjustment_atomic(
  uuid, uuid, text, text, text, text, jsonb
) FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.post_manual_stock_voucher_atomic(
  uuid, text, text, text, jsonb
) FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.setup_van_stock(
  uuid
) FROM PUBLIC, anon, authenticated;
