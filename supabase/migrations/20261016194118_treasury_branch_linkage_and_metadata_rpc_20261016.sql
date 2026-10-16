BEGIN;

ALTER TABLE public.treasury
  ADD COLUMN IF NOT EXISTS branch_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.branches'::regclass
      AND conname = 'branches_company_id_id_key'
  ) THEN
    ALTER TABLE public.branches
      ADD CONSTRAINT branches_company_id_id_key UNIQUE (company_id, id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.treasury'::regclass
      AND conname = 'treasury_company_branch_fkey'
  ) THEN
    ALTER TABLE public.treasury
      ADD CONSTRAINT treasury_company_branch_fkey
      FOREIGN KEY (company_id, branch_id)
      REFERENCES public.branches (company_id, id)
      ON DELETE RESTRICT;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_treasury_company_branch
  ON public.treasury (company_id, branch_id);

CREATE OR REPLACE FUNCTION public.finance_list_treasury_branches(p_company_id uuid)
RETURNS TABLE(id uuid, branch_code varchar, name varchar, is_active boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;
  IF app_private.current_user_company_id() IS DISTINCT FROM p_company_id THEN
    RAISE EXCEPTION 'FINANCE_COMPANY_CONTEXT_REQUIRED' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT b.id, b.branch_code, b.name, b.is_active
  FROM public.branches b
  WHERE b.company_id = p_company_id
    AND b.is_active IS TRUE
  ORDER BY b.name, b.branch_code;
END;
$function$;

CREATE OR REPLACE FUNCTION public.finance_save_treasury(
  p_company_id uuid,
  p_treasury_id uuid,
  p_account_name text,
  p_type text,
  p_opening_balance numeric,
  p_branch_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_treasury public.treasury%ROWTYPE;
  v_id uuid;
  v_code text;
  v_name text;
  v_type text;
  v_balance numeric;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;
  IF app_private.current_user_company_id() IS DISTINCT FROM p_company_id THEN
    RAISE EXCEPTION 'FINANCE_COMPANY_CONTEXT_REQUIRED' USING ERRCODE = '42501';
  END IF;

  v_name := NULLIF(BTRIM(COALESCE(p_account_name, '')), '');
  v_type := BTRIM(COALESCE(p_type, ''));
  v_balance := COALESCE(p_opening_balance, 0);

  IF v_name IS NULL THEN
    RAISE EXCEPTION 'TREASURY_ACCOUNT_NAME_REQUIRED';
  END IF;
  IF v_type NOT IN ('Cash', 'Bank') THEN
    RAISE EXCEPTION 'TREASURY_TYPE_INVALID';
  END IF;
  IF v_balance < 0 OR v_balance > 9999999999.99 THEN
    RAISE EXCEPTION 'TREASURY_OPENING_BALANCE_INVALID';
  END IF;

  IF p_branch_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.branches b
    WHERE b.id = p_branch_id
      AND b.company_id = p_company_id
      AND b.is_active IS TRUE
  ) THEN
    RAISE EXCEPTION 'TREASURY_BRANCH_INVALID';
  END IF;

  IF p_treasury_id IS NULL THEN
    v_code :=
      CASE WHEN v_type = 'Cash' THEN 'CASH-' ELSE 'BANK-' END
      || to_char(clock_timestamp(), 'YYMMDDHH24MISSMS')
      || '-'
      || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));

    INSERT INTO public.treasury (
      company_id, account_code, account_name, type,
      opening_balance, current_balance, is_active, branch_id, updated_at
    )
    VALUES (
      p_company_id, v_code, v_name, v_type,
      v_balance, v_balance, true, p_branch_id, now()
    )
    RETURNING id INTO v_id;

    RETURN jsonb_build_object(
      'success', true, 'operation', 'created',
      'id', v_id, 'account_code', v_code,
      'account_name', v_name, 'type', v_type,
      'branch_id', p_branch_id,
      'opening_balance', v_balance, 'current_balance', v_balance
    );
  END IF;

  SELECT * INTO v_treasury
  FROM public.treasury
  WHERE id = p_treasury_id
    AND company_id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TREASURY_NOT_FOUND';
  END IF;

  IF p_branch_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.pos_shifts s
    WHERE s.company_id = p_company_id
      AND s.treasury_id = p_treasury_id
      AND s.branch_id IS DISTINCT FROM p_branch_id
  ) THEN
    RAISE EXCEPTION 'TREASURY_BRANCH_CONFLICT_WITH_POS_SHIFT';
  END IF;

  UPDATE public.treasury
  SET account_name = v_name,
      type = v_type,
      branch_id = p_branch_id,
      updated_at = now()
  WHERE id = p_treasury_id
    AND company_id = p_company_id;

  RETURN jsonb_build_object(
    'success', true, 'operation', 'updated',
    'id', p_treasury_id,
    'account_code', v_treasury.account_code,
    'account_name', v_name, 'type', v_type,
    'branch_id', p_branch_id,
    'opening_balance', v_treasury.opening_balance,
    'current_balance', v_treasury.current_balance
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.finance_list_treasury_branches(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.finance_list_treasury_branches(uuid) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.finance_save_treasury(uuid, uuid, text, text, numeric, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.finance_save_treasury(uuid, uuid, text, text, numeric, uuid) TO authenticated, service_role;

COMMIT;
