BEGIN;

ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER TABLE public.runsheets REPLICA IDENTITY FULL;
ALTER TABLE public.order_details REPLICA IDENTITY FULL;
ALTER TABLE public.run_sheet_details REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'runsheets'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.runsheets;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'order_details'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.order_details;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'run_sheet_details'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.run_sheet_details;
  END IF;
END $$;

COMMIT;
