BEGIN;

-- Defense-in-depth: even if direct SELECT/INSERT/UPDATE/DELETE grants are
-- added later by mistake, anon/authenticated remain denied by RLS.
-- The controlled Sales Decision Engine (SECURITY DEFINER) is intentionally
-- outside these role-targeted restrictive policies.

CREATE POLICY sales_decision_approvals_no_direct_user_access
  ON public.sales_decision_approvals
  AS RESTRICTIVE
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY sales_decision_evaluations_no_direct_user_access
  ON public.sales_decision_evaluations
  AS RESTRICTIVE
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY sales_decision_policies_no_direct_user_access
  ON public.sales_decision_policies
  AS RESTRICTIVE
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

CREATE POLICY sales_decision_policy_history_no_direct_user_access
  ON public.sales_decision_policy_history
  AS RESTRICTIVE
  FOR ALL
  TO anon, authenticated
  USING (false)
  WITH CHECK (false);

COMMIT;
