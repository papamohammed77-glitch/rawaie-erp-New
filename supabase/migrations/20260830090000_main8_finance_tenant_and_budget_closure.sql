BEGIN;

DROP POLICY IF EXISTS treasury_insert_company ON public.treasury;
DROP POLICY IF EXISTS treasury_update_company ON public.treasury;
DROP POLICY IF EXISTS treasury_delete_company ON public.treasury;

CREATE POLICY treasury_insert_company
  ON public.treasury
  FOR INSERT TO authenticated
  WITH CHECK (company_id = app_private.current_user_company_id());

CREATE POLICY treasury_update_company
  ON public.treasury
  FOR UPDATE TO authenticated
  USING (company_id = app_private.current_user_company_id())
  WITH CHECK (company_id = app_private.current_user_company_id());

CREATE POLICY treasury_delete_company
  ON public.treasury
  FOR DELETE TO authenticated
  USING (company_id = app_private.current_user_company_id());

DROP POLICY IF EXISTS budgets_access ON public.budgets;
DROP POLICY IF EXISTS budgets_company_access ON public.budgets;

CREATE POLICY budgets_company_access
  ON public.budgets
  FOR ALL TO authenticated
  USING (
    account_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.chart_of_accounts coa
      WHERE coa.id = budgets.account_id
        AND coa.company_id = app_private.current_user_company_id()
    )
  )
  WITH CHECK (
    account_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.chart_of_accounts coa
      WHERE coa.id = budgets.account_id
        AND coa.company_id = app_private.current_user_company_id()
    )
  );

CREATE OR REPLACE FUNCTION public.get_budget_vs_actual(
  p_year integer,
  p_month integer,
  p_cost_center_id uuid DEFAULT NULL::uuid
)
RETURNS TABLE(
  account_id uuid,
  account_code text,
  account_name text,
  account_type text,
  budgeted_amount numeric,
  actual_amount numeric,
  variance numeric,
  variance_percent numeric,
  status text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
BEGIN
  IF v_company_id IS NULL THEN RETURN; END IF;
  RETURN QUERY
  SELECT
    ca.id,
    ca.account_code,
    ca.account_name,
    ca.account_type,
    COALESCE(b.budgeted_amount, 0),
    public.get_account_monthly_balance(ca.id, p_year, p_month),
    COALESCE(b.budgeted_amount, 0) - public.get_account_monthly_balance(ca.id, p_year, p_month),
    CASE
      WHEN COALESCE(b.budgeted_amount, 0) = 0 THEN 0
      ELSE ROUND(((COALESCE(b.budgeted_amount, 0) - public.get_account_monthly_balance(ca.id, p_year, p_month)) / NULLIF(b.budgeted_amount, 0)) * 100, 2)
    END,
    CASE
      WHEN COALESCE(b.budgeted_amount, 0) = 0 THEN 'no_budget'
      WHEN ca.account_type = 'revenue' THEN CASE WHEN public.get_account_monthly_balance(ca.id, p_year, p_month) >= b.budgeted_amount THEN 'within' ELSE 'under' END
      ELSE CASE WHEN public.get_account_monthly_balance(ca.id, p_year, p_month) <= b.budgeted_amount THEN 'within' ELSE 'over' END
    END
  FROM public.chart_of_accounts ca
  LEFT JOIN public.budgets b
    ON b.account_id = ca.id
   AND b.budget_year = p_year
   AND b.budget_month = p_month
   AND (p_cost_center_id IS NULL OR b.cost_center_id = p_cost_center_id)
  WHERE ca.company_id = v_company_id
    AND ca.is_active = true
    AND ca.account_type IN ('revenue', 'expense')
  ORDER BY ca.account_type, ca.account_code;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_budget_vs_actual(integer,integer,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_budget_vs_actual(integer,integer,uuid) TO authenticated, service_role;

COMMIT;
