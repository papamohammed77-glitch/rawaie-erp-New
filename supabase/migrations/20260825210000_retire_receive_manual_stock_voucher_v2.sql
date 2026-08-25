-- Phase 2 / Manual Voucher Closure
-- Retirement is permitted only after consumer discovery and Production reachability proof.
-- receive_manual_stock_voucher_v2 has no EXECUTE grants in Production and no current Edge consumer.
DROP FUNCTION IF EXISTS public.receive_manual_stock_voucher_v2(uuid,text,text,jsonb);
