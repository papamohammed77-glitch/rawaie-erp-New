-- RAWAEA ERP — CRM Customer 360 Production closure
BEGIN;

CREATE INDEX IF NOT EXISTS idx_orders_company_customer_date
  ON public.orders(company_id, customer_id, order_date DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_followups_company_customer_date
  ON public.customer_followups(company_id, customer_id, followup_date DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_ledger_customer_date
  ON public.customer_ledger(customer_id, entry_date DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_assignments_customer_active
  ON public.customer_assignments(customer_id, is_active);

-- The four CRM capability RPCs are the canonical read/control boundary.
-- Full definitions are preserved verbatim in the session report.
-- Production was already migrated and runtime-tested in this session.

COMMIT;