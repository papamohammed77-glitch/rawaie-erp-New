-- Current Production reconciliation for Loyalty channel permissions and legacy cache access.
-- Mother UI remains owner-managed in erp-frontend.

BEGIN;

DROP POLICY IF EXISTS "Enable all for authenticated users" ON public.loyalty_points;
REVOKE ALL ON TABLE public.loyalty_accounts, public.loyalty_programs, public.loyalty_rewards, public.loyalty_transactions, public.loyalty_points FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.loyalty_engine_atomic(uuid,text,text,jsonb,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.loyalty_engine_atomic(uuid,text,text,jsonb,text) TO service_role;

COMMIT;
