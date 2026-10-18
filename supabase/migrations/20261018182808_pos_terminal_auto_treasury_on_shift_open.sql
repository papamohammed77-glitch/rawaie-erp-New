-- RAWAEA POS: make the authenticated POS terminal its own fixed cash container on first shift open.
-- No QR scan or arbitrary treasury selection is required. Existing terminal treasury bindings are preserved.
-- New terminal identities get one deterministic, company/branch-scoped Cash treasury atomically.
-- All created rows are in the same transaction as shift opening; failures roll them back.

CREATE OR REPLACE FUNCTION public.pos_open_shift(
  p_branch_id uuid,
  p_terminal_code text,
  p_opening_float numeric,
  p_operation_id uuid,
  p_treasury_id uuid DEFAULT NULL::uuid,
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
  v_email text;
  v_treasury_id uuid;
  v_terminal public.pos_terminals%ROWTYPE;
  v_treasury public.treasury%ROWTYPE;
  v_terminal_found boolean := false;
  v_shift public.pos_shifts%ROWTYPE;
  v_fingerprint text;
  v_branch_code text;
  v_auto_treasury_code text;
  v_auto_treasury_name text;
  v_auto_treasury_marker text;
BEGIN
  IF v_auth_id IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '42501';
  END IF;
  IF NOT app_private.current_user_has_permission('pos') THEN
    RAISE EXCEPTION 'POS_PERMISSION_REQUIRED' USING ERRCODE = '42501';
  END IF;

  v_company_id := app_private.current_user_company_id();
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'ACTIVE_COMPANY_REQUIRED' USING ERRCODE = '42501';
  END IF;

  SELECT u.id, u.email
    INTO v_user_id, v_email
  FROM public.users u
  WHERE u.auth_id = v_auth_id
    AND u.company_id = v_company_id
    AND COALESCE(u.status, 'Active') = 'Active'
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'ACTIVE_USER_PROFILE_REQUIRED' USING ERRCODE = '42501';
  END IF;

  IF p_branch_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.get_pos_branches() b
    WHERE b.id = p_branch_id
      AND b.company_id = v_company_id
      AND COALESCE(b.is_active, true)
  ) THEN
    RAISE EXCEPTION 'POS_BRANCH_NOT_ALLOWED' USING ERRCODE = '42501';
  END IF;

  IF p_operation_id IS NULL THEN
    RAISE EXCEPTION 'SHIFT_OPERATION_ID_REQUIRED';
  END IF;
  IF p_opening_float IS NULL OR p_opening_float < 0
     OR round(p_opening_float, 2) <> p_opening_float THEN
    RAISE EXCEPTION 'SHIFT_OPENING_FLOAT_INVALID';
  END IF;
  IF NULLIF(btrim(COALESCE(p_terminal_code, '')), '') IS NULL
     OR p_terminal_code !~ '^[A-Za-z0-9._-]{3,80}$' THEN
    RAISE EXCEPTION 'SHIFT_TERMINAL_CODE_INVALID';
  END IF;

  -- Serialize first-use provisioning for this company/device; retries cannot create parallel treasuries.
  PERFORM pg_advisory_xact_lock(
    hashtext('rawaea:pos-terminal:' || v_company_id::text),
    hashtext(p_terminal_code)
  );

  SELECT *
    INTO v_terminal
  FROM public.pos_terminals t
  WHERE t.company_id = v_company_id
    AND t.terminal_code = p_terminal_code
  FOR UPDATE;
  v_terminal_found := FOUND;

  IF v_terminal_found THEN
    IF NOT v_terminal.is_active THEN
      RAISE EXCEPTION 'SHIFT_TERMINAL_INACTIVE_OR_MISSING';
    END IF;
    IF v_terminal.branch_id <> p_branch_id THEN
      RAISE EXCEPTION 'SHIFT_TERMINAL_BRANCH_MISMATCH';
    END IF;
  END IF;

  -- Explicit treasury IDs are retained only for the existing privileged QR/admin binding flow.
  IF p_treasury_id IS NOT NULL THEN
    IF NOT v_terminal_found OR v_terminal.treasury_id IS NULL THEN
      RAISE EXCEPTION 'SHIFT_TERMINAL_CONFIGURATION_REQUIRED' USING ERRCODE = '42501';
    END IF;
    v_treasury_id := p_treasury_id;
  ELSIF v_terminal_found AND v_terminal.treasury_id IS NOT NULL THEN
    -- Never reassign an existing terminal's financial history.
    v_treasury_id := v_terminal.treasury_id;
  ELSE
    -- A POS terminal is the cashier's physical cash container. Create its treasury on first use.
    SELECT b.branch_code
      INTO v_branch_code
    FROM public.branches b
    WHERE b.id = p_branch_id
      AND b.company_id = v_company_id
      AND b.is_active IS TRUE;

    IF v_branch_code IS NULL THEN
      RAISE EXCEPTION 'POS_BRANCH_NOT_ALLOWED' USING ERRCODE = '42501';
    END IF;

    v_auto_treasury_code :=
      'POS-' || upper(md5(v_company_id::text || '|' || p_terminal_code));
    v_auto_treasury_marker := 'RAWAEA_AUTO_POS_TREASURY;pos-terminal-code=' || p_terminal_code;
    v_auto_treasury_name :=
      'خزينة جهاز POS - ' || v_branch_code || ' - ' || upper(right(md5(p_terminal_code), 6));

    INSERT INTO public.treasury (
      company_id, account_code, account_name, type,
      opening_balance, current_balance, is_active, notes, branch_id
    ) VALUES (
      v_company_id, v_auto_treasury_code, v_auto_treasury_name, 'Cash',
      0, 0, TRUE, v_auto_treasury_marker, p_branch_id
    )
    ON CONFLICT (company_id, account_code) DO NOTHING;

    SELECT *
      INTO v_treasury
    FROM public.treasury t
    WHERE t.company_id = v_company_id
      AND t.account_code = v_auto_treasury_code
    FOR UPDATE;

    IF NOT FOUND
       OR v_treasury.is_active IS NOT TRUE
       OR v_treasury.type <> 'Cash'
       OR v_treasury.branch_id IS DISTINCT FROM p_branch_id
       OR position(v_auto_treasury_marker IN COALESCE(v_treasury.notes, '')) = 0 THEN
      RAISE EXCEPTION 'POS_AUTO_TREASURY_IDENTITY_CONFLICT';
    END IF;

    v_treasury_id := v_treasury.id;
  END IF;

  SELECT *
    INTO v_treasury
  FROM public.treasury t
  WHERE t.id = v_treasury_id
    AND t.company_id = v_company_id
    AND t.is_active IS TRUE
    AND (t.branch_id IS NULL OR t.branch_id = p_branch_id)
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SHIFT_TREASURY_NOT_ALLOWED' USING ERRCODE = '42501';
  END IF;

  IF v_terminal_found AND v_terminal.treasury_id IS NOT NULL
     AND v_terminal.treasury_id <> v_treasury_id THEN
    RAISE EXCEPTION 'SHIFT_TERMINAL_TREASURY_MISMATCH';
  END IF;

  v_fingerprint := md5(concat_ws(
    '|', v_company_id, p_branch_id, p_terminal_code,
    v_treasury_id, p_opening_float::numeric(14,2), COALESCE(p_terminal_label, '')
  ));

  SELECT *
    INTO v_shift
  FROM public.pos_shifts s
  WHERE s.company_id = v_company_id
    AND s.open_operation_id = p_operation_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_shift.open_fingerprint <> v_fingerprint THEN
      RAISE EXCEPTION 'SHIFT_OPERATION_ID_REUSED_WITH_DIFFERENT_PAYLOAD';
    END IF;
    RETURN jsonb_build_object(
      'success', true, 'duplicate', true, 'shift_id', v_shift.id,
      'status', v_shift.status, 'opened_at', v_shift.opened_at,
      'treasury_id', v_shift.treasury_id, 'terminal_id', v_shift.terminal_id
    );
  END IF;

  IF NOT v_terminal_found THEN
    INSERT INTO public.pos_terminals (
      company_id, branch_id, terminal_code, terminal_label, created_by_user_id, treasury_id
    ) VALUES (
      v_company_id, p_branch_id, p_terminal_code,
      NULLIF(btrim(p_terminal_label), ''), v_user_id, v_treasury_id
    )
    ON CONFLICT (company_id, terminal_code) DO NOTHING;

    SELECT *
      INTO v_terminal
    FROM public.pos_terminals t
    WHERE t.company_id = v_company_id
      AND t.terminal_code = p_terminal_code
    FOR UPDATE;

    IF NOT FOUND OR NOT v_terminal.is_active THEN
      RAISE EXCEPTION 'SHIFT_TERMINAL_INACTIVE_OR_MISSING';
    END IF;
    IF v_terminal.branch_id <> p_branch_id THEN
      RAISE EXCEPTION 'SHIFT_TERMINAL_BRANCH_MISMATCH';
    END IF;
    IF v_terminal.treasury_id IS NOT NULL AND v_terminal.treasury_id <> v_treasury_id THEN
      RAISE EXCEPTION 'SHIFT_TERMINAL_TREASURY_MISMATCH';
    END IF;
    IF v_terminal.treasury_id IS NULL THEN
      UPDATE public.pos_terminals
      SET treasury_id = v_treasury_id,
          terminal_label = COALESCE(NULLIF(btrim(p_terminal_label), ''), terminal_label),
          updated_at = now()
      WHERE id = v_terminal.id AND company_id = v_company_id;
      v_terminal.treasury_id := v_treasury_id;
    END IF;
  ELSIF v_terminal.treasury_id IS NULL THEN
    UPDATE public.pos_terminals
    SET treasury_id = v_treasury_id,
        terminal_label = COALESCE(NULLIF(btrim(p_terminal_label), ''), terminal_label),
        updated_at = now()
    WHERE id = v_terminal.id AND company_id = v_company_id;
    v_terminal.treasury_id := v_treasury_id;
  END IF;

  IF v_terminal.terminal_label IS NULL AND NULLIF(btrim(p_terminal_label), '') IS NOT NULL THEN
    UPDATE public.pos_terminals
    SET terminal_label = NULLIF(btrim(p_terminal_label), ''), updated_at = now()
    WHERE id = v_terminal.id AND company_id = v_company_id;
  END IF;

  INSERT INTO public.pos_shifts (
    company_id, branch_id, cashier_user_id, terminal_id, treasury_id,
    opening_float, open_operation_id, open_fingerprint, opening_notes
  ) VALUES (
    v_company_id, p_branch_id, v_user_id, v_terminal.id, v_treasury_id,
    p_opening_float, p_operation_id, v_fingerprint, NULLIF(btrim(p_terminal_label), '')
  )
  RETURNING * INTO v_shift;

  INSERT INTO public.pos_shift_events (
    company_id, shift_id, event_type, operation_id, actor_user_id, payload
  ) VALUES (
    v_company_id, v_shift.id, 'opened', p_operation_id, v_user_id,
    jsonb_build_object(
      'branch_id', p_branch_id,
      'terminal_id', v_terminal.id,
      'treasury_id', v_shift.treasury_id,
      'opening_float', v_shift.opening_float,
      'terminal_code', v_terminal.terminal_code,
      'treasury_mode', CASE WHEN v_auto_treasury_code IS NULL THEN 'existing_binding' ELSE 'auto_device_treasury' END
    )
  );

  RETURN jsonb_build_object(
    'success', true, 'duplicate', false, 'shift_id', v_shift.id,
    'status', v_shift.status, 'opened_at', v_shift.opened_at,
    'branch_id', v_shift.branch_id, 'terminal_id', v_terminal.id,
    'terminal_code', v_terminal.terminal_code, 'treasury_id', v_shift.treasury_id,
    'opening_float', v_shift.opening_float,
    'treasury_mode', CASE WHEN v_auto_treasury_code IS NULL THEN 'existing_binding' ELSE 'auto_device_treasury' END
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.pos_open_shift(uuid, text, numeric, uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pos_open_shift(uuid, text, numeric, uuid, uuid, text) TO authenticated, service_role;