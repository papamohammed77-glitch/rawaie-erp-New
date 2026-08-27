BEGIN;

REVOKE ALL ON FUNCTION public.get_trial_balance(date,date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_profit_loss(date,date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_balance_sheet(date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_cash_flow(date,date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_pnl_by_cost_center(date,date) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_trial_balance(date,date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_profit_loss(date,date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_balance_sheet(date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_cash_flow(date,date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_pnl_by_cost_center(date,date) TO authenticated, service_role;

COMMIT;
