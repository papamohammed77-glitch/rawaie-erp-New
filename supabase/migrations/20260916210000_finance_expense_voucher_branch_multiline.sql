BEGIN;

ALTER TABLE public.finance_expenses ADD COLUMN IF NOT EXISTS branch_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='finance_expenses_branch_id_fkey'
  ) THEN
    ALTER TABLE public.finance_expenses
      ADD CONSTRAINT finance_expenses_branch_id_fkey
      FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.finance_save_expense(
  p_company_id uuid,
  p_expense_id uuid,
  p_expense_code text,
  p_expense_date date,
  p_beneficiary_name text,
  p_category_id uuid,
  p_treasury_id uuid,
  p_description text,
  p_attachment_url text,
  p_reference text,
  p_created_by text,
  p_operation_id uuid,
  p_branch_id uuid,
  p_lines jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_existing public.finance_expenses%ROWTYPE;
  v_id uuid;
  v_result jsonb;
BEGIN
  IF app_private.current_user_company_id() IS DISTINCT FROM p_company_id THEN
    RAISE EXCEPTION 'FINANCE_COMPANY_CONTEXT_REQUIRED';
  END IF;
  IF p_branch_id IS NULL THEN RAISE EXCEPTION 'EXPENSE_BRANCH_REQUIRED'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id=p_branch_id AND b.company_id=p_company_id AND COALESCE(b.is_active,true)
  ) THEN RAISE EXCEPTION 'EXPENSE_BRANCH_INVALID'; END IF;
  IF p_treasury_id IS NULL THEN RAISE EXCEPTION 'EXPENSE_TREASURY_REQUIRED'; END IF;

  SELECT * INTO v_existing
  FROM public.finance_expenses
  WHERE company_id=p_company_id AND operation_id=p_operation_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing.branch_id IS DISTINCT FROM p_branch_id
       OR v_existing.treasury_id IS DISTINCT FROM p_treasury_id THEN
      RAISE EXCEPTION 'EXPENSE_OPERATION_CONTEXT_CONFLICT';
    END IF;
    RETURN jsonb_build_object(
      'success',true,'duplicate',true,'id',v_existing.id,
      'expense_code',v_existing.expense_code,
      'journal_entry_id',v_existing.journal_entry_id,
      'branch_id',v_existing.branch_id,
      'treasury_id',v_existing.treasury_id,
      'total',v_existing.total_amount+v_existing.tax_amount
    );
  END IF;

  v_result:=public.finance_save_expense(
    p_company_id,p_expense_id,p_expense_code,p_expense_date,
    p_beneficiary_name,p_category_id,p_treasury_id,p_description,
    p_attachment_url,p_reference,p_created_by,p_operation_id,p_lines
  );
  v_id:=NULLIF(v_result->>'id','')::uuid;
  IF v_id IS NULL THEN RAISE EXCEPTION 'EXPENSE_SAVE_RESULT_INVALID'; END IF;

  UPDATE public.finance_expenses
  SET branch_id=p_branch_id, updated_at=now()
  WHERE id=v_id AND company_id=p_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'EXPENSE_BRANCH_UPDATE_FAILED'; END IF;

  RETURN v_result || jsonb_build_object('branch_id',p_branch_id,'treasury_id',p_treasury_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.finance_list_expenses_v2(
  p_company_id uuid,
  p_from date,
  p_to date
)
RETURNS TABLE(
  id uuid, expense_code text, expense_date date, beneficiary_name text,
  category_name text, branch_id uuid, branch_name text, treasury_id uuid,
  treasury_name text, total_amount numeric, tax_amount numeric, status text,
  description text, reference text, journal_entry_id uuid, line_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
SELECT e.id,e.expense_code,e.expense_date,e.beneficiary_name,c.name,
       e.branch_id,b.name,e.treasury_id,t.account_name,e.total_amount,e.tax_amount,
       e.status,e.description,e.reference,e.journal_entry_id,
       (SELECT count(*) FROM public.finance_expense_lines l WHERE l.expense_id=e.id)
FROM public.finance_expenses e
LEFT JOIN public.finance_expense_categories c ON c.id=e.category_id
LEFT JOIN public.branches b ON b.id=e.branch_id
LEFT JOIN public.treasury t ON t.id=e.treasury_id
WHERE e.company_id=p_company_id
  AND e.expense_date BETWEEN p_from AND p_to
  AND p_company_id=app_private.current_user_company_id()
ORDER BY e.expense_date DESC,e.created_at DESC
$function$;

REVOKE ALL ON FUNCTION public.finance_save_expense(uuid,uuid,text,date,text,uuid,uuid,text,text,text,text,uuid,uuid,jsonb)
  FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.finance_save_expense(uuid,uuid,text,date,text,uuid,uuid,text,text,text,text,uuid,uuid,jsonb)
  TO authenticated,service_role;

REVOKE ALL ON FUNCTION public.finance_list_expenses_v2(uuid,date,date)
  FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.finance_list_expenses_v2(uuid,date,date)
  TO authenticated,service_role;

COMMIT;
