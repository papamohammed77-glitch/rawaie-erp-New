BEGIN;

-- Security closure for the four Sales Decision persistence tables.
-- The current application contract uses sales_decision_engine_atomic()
-- as the controlled read/write gateway. Direct anon/authenticated table access
-- is intentionally not granted.

ALTER TABLE public.sales_decision_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_decision_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_decision_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_decision_policy_history ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.sales_decision_approvals FROM anon, authenticated;
REVOKE ALL ON TABLE public.sales_decision_evaluations FROM anon, authenticated;
REVOKE ALL ON TABLE public.sales_decision_policies FROM anon, authenticated;
REVOKE ALL ON TABLE public.sales_decision_policy_history FROM anon, authenticated;

COMMIT;
