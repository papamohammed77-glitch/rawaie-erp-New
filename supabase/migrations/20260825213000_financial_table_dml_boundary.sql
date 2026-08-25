-- Financial writer boundary: clients may read financial state but may not perform direct DML.
-- Canonical service_role RPCs remain the write path.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.journal_entries, public.journal_lines, public.customer_ledger,
   public.supplier_ledger, public.driver_ledger, public.treasury,
   public.cash_box, public.daily_settlements
FROM anon, authenticated;

GRANT SELECT
ON public.journal_entries, public.journal_lines, public.customer_ledger,
   public.supplier_ledger, public.driver_ledger, public.treasury,
   public.cash_box, public.daily_settlements
TO anon, authenticated;
