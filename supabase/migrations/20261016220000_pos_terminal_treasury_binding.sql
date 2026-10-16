-- POS fixed terminal-to-treasury binding.
-- Additive, backward-compatible schema change. Existing terminal/shift identities are preserved.

ALTER TABLE public.pos_terminals
  ADD COLUMN IF NOT EXISTS treasury_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.pos_terminals'::regclass
      AND conname = 'pos_terminals_treasury_id_fkey'
  ) THEN
    ALTER TABLE public.pos_terminals
      ADD CONSTRAINT pos_terminals_treasury_id_fkey
      FOREIGN KEY (treasury_id) REFERENCES public.treasury(id) ON DELETE RESTRICT;
  END IF;
END
$$;

-- Backfill only when all historical shifts for a terminal used the same treasury.
UPDATE public.pos_terminals t
SET treasury_id = x.treasury_id
FROM (
  SELECT terminal_id, min(treasury_id::text)::uuid AS treasury_id
  FROM public.pos_shifts
  GROUP BY terminal_id
  HAVING count(DISTINCT treasury_id) = 1
) x
WHERE t.id = x.terminal_id
  AND t.treasury_id IS NULL;

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
  v_treasury_count integer;
  v_terminal public.pos_terminals%ROWTYPE;
  v_terminal_found boolean := false;
  v_shift public.pos_shifts%ROWTYPE;
  v_fingerprint text;
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

  SELECT u.id, u.email INTO v_user_id, v_email
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

  -- Resolve an already-registered physical terminal before resolving its treasury.
  SELECT * INTO v_terminal
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

  IF p_treasury_id IS NOT NULL THEN
    v_treasury_id := p_treasury_id;
  ELSIF v_terminal_found AND v_terminal.treasury_id IS NOT NULL THEN
    v_treasury_id := v_terminal.treasury_id;
  ELSE
    SELECT (array_agg(t.id ORDER BY t.id))[1], count(*)::integer
      INTO v_treasury_id, v_treasury_count
    FROM public.treasury t
    WHERE t.company_id = v_company_id
      AND t.is_active IS TRUE;

    IF v_treasury_count <> 1 THEN
      RAISE EXCEPTION 'SHIFT_TREASURY_SELECTION_REQUIRED';
    END IF;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.treasury t
    WHERE t.id = v_treasury_id
      AND t.company_id = v_company_id
      AND t.is_active IS TRUE
      AND (t.branch_id IS NULL OR t.branch_id = p_branch_id)
  ) THEN
    RAISE EXCEPTION 'SHIFT_TREASURY_NOT_ALLOWED' USING ERRCODE = '42501';
  END IF;

  IF v_terminal_found AND v_terminal.treasury_id IS NOT NULL
     AND v_terminal.treasury_id <> v_treasury_id THEN
    RAISE EXCEPTION 'SHIFT_TERMINAL_TREASURY_MISMATCH';
  END IF;

  v_fingerprint := md5(concat_ws(
    '|',
    v_company_id,
    p_branch_id,
    p_terminal_code,
    v_treasury_id,
    p_opening_float::numeric(14,2),
    COALESCE(p_terminal_label, '')
  ));

  SELECT * INTO v_shift
  FROM public.pos_shifts s
  WHERE s.company_id = v_company_id
    AND s.open_operation_id = p_operation_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_shift.open_fingerprint <> v_fingerprint THEN
      RAISE EXCEPTION 'SHIFT_OPERATION_ID_REUSED_WITH_DIFFERENT_PAYLOAD';
    END IF;
    RETURN jsonb_build_object(
      'success', true,
      'duplicate', true,
      'shift_id', v_shift.id,
      'status', v_shift.status,
      'opened_at', v_shift.opened_at,
      'treasury_id', v_shift.treasury_id,
      'terminal_id', v_shift.terminal_id
    );
  END IF;

  INSERT INTO public.pos_terminals(
    company_id, branch_id, terminal_code, terminal_label,
    created_by_user_id, treasury_id
  )
  VALUES (
    v_company_id, p_branch_id, p_terminal_code,
    NULLIF(btrim(p_terminal_label), ''), v_user_id, v_treasury_id
  )
  ON CONFLICT (company_id, terminal_code) DO NOTHING;

  SELECT * INTO v_terminal
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
  IF v_terminal.treasury_id IS NULL THEN
    UPDATE public.pos_terminals
    SET treasury_id = v_treasury_id, updated_at = now()
    WHERE id = v_terminal.id AND company_id = v_company_id;
    v_terminal.treasury_id := v_treasury_id;
  ELSIF v_terminal.treasury_id <> v_treasury_id THEN
    RAISE EXCEPTION 'SHIFT_TERMINAL_TREASURY_MISMATCH';
  END IF;

  IF v_terminal.terminal_label IS NULL
     AND NULLIF(btrim(p_terminal_label), '') IS NOT NULL THEN
    UPDATE public.pos_terminals
    SET terminal_label = NULLIF(btrim(p_terminal_label), ''), updated_at = now()
    WHERE id = v_terminal.id;
  END IF;

  INSERT INTO public.pos_shifts(
    company_id, branch_id, cashier_user_id, terminal_id, treasury_id,
    opening_float, open_operation_id, open_fingerprint, opening_notes
  )
  VALUES (
    v_company_id, p_branch_id, v_user_id, v_terminal.id, v_treasury_id,
    p_opening_float, p_operation_id, v_fingerprint,
    NULLIF(btrim(p_terminal_label), '')
  )
  RETURNING * INTO v_shift;

  INSERT INTO public.pos_shift_events(
    company_id, shift_id, event_type, operation_id, actor_user_id, payload
  )
  VALUES (
    v_company_id, v_shift.id, 'opened', p_operation_id, v_user_id,
    jsonb_build_object(
      'branch_id', p_branch_id,
      'terminal_id', v_terminal.id,
      'treasury_id', v_shift.treasury_id,
      'opening_float', v_shift.opening_float,
      'terminal_code', v_terminal.terminal_code
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'duplicate', false,
    'shift_id', v_shift.id,
    'status', v_shift.status,
    'opened_at', v_shift.opened_at,
    'branch_id', v_shift.branch_id,
    'terminal_id', v_terminal.id,
    'treasury_id', v_shift.treasury_id,
    'opening_float', v_shift.opening_float
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.pos_open_shift(uuid, text, numeric, uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pos_open_shift(uuid, text, numeric, uuid, uuid, text) TO authenticated;
