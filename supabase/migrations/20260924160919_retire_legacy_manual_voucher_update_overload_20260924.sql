-- RAWAEA ERP — retire unreachable legacy update overload
-- Production migration: retire_legacy_manual_voucher_update_overload_20260924
-- The 12-argument legacy overload had no authenticated/service_role Execute grant and no internal consumer.
-- Keep the current operation-identity overload only.
BEGIN;
DROP FUNCTION public.update_manual_stock_voucher_atomic(
  uuid,text,text,text,text,uuid,text,uuid,text,text,jsonb,uuid
);
COMMIT;
