BEGIN;

CREATE UNIQUE INDEX IF NOT EXISTS orders_company_operation_id_unique
  ON public.orders (company_id, operation_id)
  WHERE operation_id IS NOT NULL;

COMMIT;
