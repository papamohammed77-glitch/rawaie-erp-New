BEGIN;

REVOKE ALL ON FUNCTION public.post_daily_settlement_atomic(uuid,uuid,text,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_daily_settlement_atomic(uuid,uuid,text,text,text) TO service_role;

REVOKE ALL ON FUNCTION public.post_driver_liability_entry(uuid,text,uuid,uuid,text,text,numeric,numeric,numeric,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_driver_liability_entry(uuid,text,uuid,uuid,text,text,numeric,numeric,numeric,text,text) TO service_role;

REVOKE ALL ON FUNCTION public.enforce_van_branch_company_context() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enforce_van_branch_company_context() TO service_role;

REVOKE ALL ON FUNCTION public.get_warehouse_team() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_warehouse_team() TO service_role;

REVOKE ALL ON FUNCTION public.set_active_warehouse_role(uuid,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_active_warehouse_role(uuid,text) TO service_role;

COMMIT;
