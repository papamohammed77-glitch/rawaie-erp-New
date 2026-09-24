-- RAWAEA ERP — one-time cleanup of orphaned QA operation identities/audit rows
-- Scope is strictly test artifacts: QA-* operation identities with no voucher, and QA-* stock-voucher audit rows.
-- Runtime integrity guard is disabled only for the bounded delete, then restored before commit.

BEGIN;

ALTER TABLE public.stock_voucher_operations
  DISABLE TRIGGER trg_guard_stock_voucher_operations_delete_integrity;

DELETE FROM public.stock_voucher_operations
WHERE company_id='00000000-0000-0000-0000-000000000001'::uuid
  AND voucher_id IS NULL
  AND operation_id LIKE 'QA-%'
  AND created_at < current_date;

ALTER TABLE public.stock_voucher_operations
  ENABLE TRIGGER trg_guard_stock_voucher_operations_delete_integrity;

DELETE FROM public.audit_log
WHERE table_name='stock_vouchers'
  AND new_data->>'reference' LIKE 'QA-%';

COMMIT;
