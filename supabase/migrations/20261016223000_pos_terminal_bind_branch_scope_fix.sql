CREATE OR REPLACE FUNCTION public.pos_bind_terminal_treasury(
  p_branch_id uuid,
  p_terminal_code text,
  p_treasury_id uuid,
  p_terminal_label text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_auth_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_default_branch_id uuid;
  v_allowed_branch_ids jsonb;
  v_is_owner boolean := false;
  v_terminal public.pos_terminals%ROWTYPE;
  v_treasury public.treasury%ROWTYPE;
  v_duplicate boolean := false;
  v_inserted_rows integer := 0;
BEGIN
  IF v_auth_id IS NULL THEN RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '42501'; END IF;
  v_company_id := app_private.current_user_company_id();
  IF v_company_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_COMPANY_REQUIRED' USING ERRCODE = '42501'; END IF;

  SELECT u.id, u.default_branch_id, u.allowed_branch_ids,
         (COALESCE(au.raw_user_meta_data->>'isOwner', 'false') = 'true'
          AND jsonb_typeof(u.permissions) = 'array'
          AND u.permissions ? '*'
          AND EXISTS (SELECT 1 FROM public.owner_profile op WHERE op.auth_user_id = auth.uid()))
    INTO v_user_id, v_default_branch_id, v_allowed_branch_ids, v_is_owner
  FROM public.users u
  LEFT JOIN auth.users au ON au.id = u.auth_id
  WHERE u.auth_id = v_auth_id AND u.company_id = v_company_id
    AND COALESCE(u.status, 'Active') = 'Active'
  LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_USER_PROFILE_REQUIRED' USING ERRCODE = '42501'; END IF;

  IF NOT (v_is_owner
      OR app_private.current_user_has_permission('general_manager')
      OR app_private.current_user_has_permission('cash_manager')) THEN
    RAISE EXCEPTION 'POS_TERMINAL_CONFIGURATION_PERMISSION_REQUIRED' USING ERRCODE = '42501';
  END IF;

  IF p_branch_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.branches b
    WHERE b.id = p_branch_id
      AND b.company_id = v_company_id
      AND b.is_active IS TRUE
      AND (
        v_is_owner
        OR b.id = v_default_branch_id
        OR (
          jsonb_typeof(v_allowed_branch_ids) = 'array'
          AND EXISTS (
            SELECT 1
            FROM jsonb_array_elements_text(v_allowed_branch_ids) allowed(value)
            WHERE allowed.value = b.id::text OR allowed.value = b.branch_code
          )
        )
        OR (
          jsonb_typeof(v_allowed_branch_ids) = 'string'
          AND (
            v_allowed_branch_ids #>> '{}' = b.id::text
            OR v_allowed_branch_ids #>> '{}' = b.branch_code
          )
        )
      )
  ) THEN RAISE EXCEPTION 'POS_BRANCH_NOT_ALLOWED' USING ERRCODE = '42501'; END IF;

  IF NULLIF(btrim(COALESCE(p_terminal_code, '')), '') IS NULL
     OR p_terminal_code !~ '^[A-Za-z0-9._-]{3,80}$' THEN
    RAISE EXCEPTION 'SHIFT_TERMINAL_CODE_INVALID';
  END IF;

  SELECT * INTO v_treasury
  FROM public.treasury t
  WHERE t.id = p_treasury_id AND t.company_id = v_company_id
    AND t.is_active IS TRUE AND (t.branch_id IS NULL OR t.branch_id = p_branch_id)
  FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'SHIFT_TREASURY_NOT_ALLOWED' USING ERRCODE = '42501'; END IF;

  INSERT INTO public.pos_terminals(
    company_id, branch_id, terminal_code, terminal_label, created_by_user_id, treasury_id
  ) VALUES (
    v_company_id, p_branch_id, p_terminal_code,
    NULLIF(btrim(p_terminal_label), ''), v_user_id, p_treasury_id
  ) ON CONFLICT (company_id, terminal_code) DO NOTHING;
  GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;

  SELECT * INTO v_terminal
  FROM public.pos_terminals t
  WHERE t.company_id = v_company_id AND t.terminal_code = p_terminal_code
  FOR UPDATE;
  IF NOT FOUND OR NOT v_terminal.is_active THEN RAISE EXCEPTION 'SHIFT_TERMINAL_INACTIVE_OR_MISSING'; END IF;
  IF v_terminal.branch_id <> p_branch_id THEN RAISE EXCEPTION 'SHIFT_TERMINAL_BRANCH_MISMATCH'; END IF;

  IF v_terminal.treasury_id IS NOT NULL AND v_terminal.treasury_id <> p_treasury_id THEN
    IF EXISTS (SELECT 1 FROM public.pos_shifts s WHERE s.company_id = v_company_id AND s.terminal_id = v_terminal.id) THEN
      RAISE EXCEPTION 'POS_TERMINAL_TREASURY_HISTORY_LOCKED';
    END IF;
    UPDATE public.pos_terminals
    SET treasury_id = p_treasury_id,
        terminal_label = COALESCE(NULLIF(btrim(p_terminal_label), ''), terminal_label),
        updated_at = now()
    WHERE id = v_terminal.id AND company_id = v_company_id;
    v_terminal.treasury_id := p_treasury_id;
    v_duplicate := false;
  ELSIF v_terminal.treasury_id = p_treasury_id THEN
    v_duplicate := (v_inserted_rows = 0);
  ELSE
    IF EXISTS (SELECT 1 FROM public.pos_shifts s WHERE s.company_id = v_company_id AND s.terminal_id = v_terminal.id) THEN
      RAISE EXCEPTION 'POS_TERMINAL_TREASURY_HISTORY_LOCKED';
    END IF;
    UPDATE public.pos_terminals
    SET treasury_id = p_treasury_id,
        terminal_label = COALESCE(NULLIF(btrim(p_terminal_label), ''), terminal_label),
        updated_at = now()
    WHERE id = v_terminal.id AND company_id = v_company_id;
    v_terminal.treasury_id := p_treasury_id;
    v_duplicate := false;
  END IF;

  IF v_terminal.terminal_label IS NULL AND NULLIF(btrim(p_terminal_label), '') IS NOT NULL THEN
    UPDATE public.pos_terminals
    SET terminal_label = NULLIF(btrim(p_terminal_label), ''), updated_at = now()
    WHERE id = v_terminal.id AND company_id = v_company_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'duplicate', v_duplicate,
    'terminal_id', v_terminal.id, 'terminal_code', v_terminal.terminal_code,
    'branch_id', v_terminal.branch_id, 'treasury_id', v_terminal.treasury_id,
    'terminal_label', v_terminal.terminal_label);
END;
$function$;

REVOKE ALL ON FUNCTION public.pos_bind_terminal_treasury(uuid, text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pos_bind_terminal_treasury(uuid, text, uuid, text) TO authenticated;