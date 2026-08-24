BEGIN;

REVOKE ALL ON FUNCTION public.post_cash_receipt_atomic(uuid,uuid,uuid,uuid,uuid,numeric,date,text,text,text,text,text,uuid,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_cash_receipt_atomic(uuid,uuid,uuid,uuid,uuid,numeric,date,text,text,text,text,text,uuid,text,text) TO service_role;

REVOKE ALL ON FUNCTION public.post_cash_payment_atomic(uuid,uuid,uuid,uuid,uuid,numeric,date,text,text,text,text,text,uuid,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_cash_payment_atomic(uuid,uuid,uuid,uuid,uuid,numeric,date,text,text,text,text,text,uuid,text,text) TO service_role;

REVOKE ALL ON FUNCTION public.post_customer_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_customer_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) TO service_role;

REVOKE ALL ON FUNCTION public.post_supplier_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_supplier_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) TO service_role;

REVOKE ALL ON FUNCTION public.post_driver_ledger_entry(uuid,uuid,text,date,text,text,numeric,numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_driver_ledger_entry(uuid,uuid,text,date,text,text,numeric,numeric) TO service_role;

COMMIT;
