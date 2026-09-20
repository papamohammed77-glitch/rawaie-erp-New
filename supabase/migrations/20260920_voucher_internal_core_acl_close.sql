BEGIN;
REVOKE EXECUTE ON FUNCTION public.send_stock_voucher_atomic_core_20260828(uuid,text,text)
FROM PUBLIC, anon, authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.post_manual_stock_voucher_atomic_core_20260828(uuid,text,text,text,jsonb,text)
FROM PUBLIC, anon, authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.complete_manual_stock_voucher_atomic_core_20260828(uuid,text,text)
FROM PUBLIC, anon, authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.cancel_manual_stock_voucher_atomic_core_20260828(uuid,text,text)
FROM PUBLIC, anon, authenticated, service_role;
COMMIT;
