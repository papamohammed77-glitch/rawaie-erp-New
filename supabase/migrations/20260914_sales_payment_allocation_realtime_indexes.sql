-- RAWAEA ERP — sales payment allocation realtime + lookup indexes
-- Production companion to the already-deployed sales payment allocation core.
-- No business-contract change; improves current live synchronization and FK lookup paths.

BEGIN;

CREATE INDEX IF NOT EXISTS idx_sales_payment_allocations_order_id
  ON public.sales_payment_allocations(order_id);

CREATE INDEX IF NOT EXISTS idx_sales_payment_receipts_cash_box_id
  ON public.sales_payment_receipts(cash_box_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'sales_payment_receipts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sales_payment_receipts;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'sales_payment_allocations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sales_payment_allocations;
  END IF;
END $$;

COMMIT;
