CREATE OR REPLACE FUNCTION public.finance_delete_treasury(
  p_company_id uuid,
  p_treasury_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_treasury public.treasury%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;
  IF app_private.current_user_company_id() IS DISTINCT FROM p_company_id THEN
    RAISE EXCEPTION 'FINANCE_COMPANY_CONTEXT_REQUIRED' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_treasury
  FROM public.treasury
  WHERE id = p_treasury_id
    AND company_id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TREASURY_NOT_FOUND';
  END IF;

  IF COALESCE(v_treasury.current_balance, 0) <> 0 THEN
    RAISE EXCEPTION 'TREASURY_NONZERO_BALANCE';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.cash_box
    WHERE company_id = p_company_id AND treasury_id = p_treasury_id
  ) THEN
    RAISE EXCEPTION 'TREASURY_HAS_CASH_HISTORY';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.pos_shifts
    WHERE company_id = p_company_id AND treasury_id = p_treasury_id
  ) THEN
    RAISE EXCEPTION 'TREASURY_HAS_POS_SHIFT_HISTORY';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.finance_expenses
    WHERE company_id = p_company_id AND treasury_id = p_treasury_id
  ) THEN
    RAISE EXCEPTION 'TREASURY_HAS_FINANCE_EXPENSE_HISTORY';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.finance_cheques
    WHERE company_id = p_company_id AND treasury_id = p_treasury_id
  ) THEN
    RAISE EXCEPTION 'TREASURY_HAS_CHEQUE_HISTORY';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.finance_bank_statements
    WHERE company_id = p_company_id AND treasury_id = p_treasury_id
  ) THEN
    RAISE EXCEPTION 'TREASURY_HAS_BANK_STATEMENT_HISTORY';
  END IF;

  DELETE FROM public.treasury
  WHERE id = p_treasury_id
    AND company_id = p_company_id;

  RETURN jsonb_build_object('success', true, 'deleted_id', p_treasury_id);
END;
$function$;

REVOKE ALL ON FUNCTION public.finance_delete_treasury(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.finance_delete_treasury(uuid, uuid) TO authenticated, service_role;
