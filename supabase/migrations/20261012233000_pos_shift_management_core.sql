-- RAWAEA POS Shift Management Core
-- Additive rollout: no existing orders or financial balances are rewritten.
-- Shift records are operational control records; cash_box/receipts/journals remain financial truth.

CREATE TABLE IF NOT EXISTS public.pos_terminals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  terminal_code text NOT NULL,
  terminal_label text,
  is_active boolean NOT NULL DEFAULT true,
  created_by_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pos_terminals_company_code_uk UNIQUE (company_id, terminal_code),
  CONSTRAINT pos_terminals_company_id_id_uk UNIQUE (company_id, id),
  CONSTRAINT pos_terminals_code_ck CHECK (terminal_code ~ '^[A-Za-z0-9._-]{3,80}$')
);

CREATE TABLE IF NOT EXISTS public.pos_shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id uuid NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
  cashier_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  terminal_id uuid NOT NULL,
  treasury_id uuid NOT NULL REFERENCES public.treasury(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed','frozen')),
  opening_float numeric(14,2) NOT NULL DEFAULT 0 CHECK (opening_float >= 0),
  expected_cash numeric(14,2),
  counted_cash numeric(14,2),
  cash_difference numeric(14,2),
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  open_operation_id uuid NOT NULL,
  open_fingerprint text NOT NULL,
  close_operation_id uuid,
  close_fingerprint text,
  discrepancy_reason text,
  opening_notes text,
  closing_notes text,
  close_summary jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pos_shifts_company_id_id_uk UNIQUE (company_id, id),
  CONSTRAINT pos_shifts_terminal_company_fk FOREIGN KEY (company_id, terminal_id)
    REFERENCES public.pos_terminals(company_id, id) ON DELETE RESTRICT,
  CONSTRAINT pos_shifts_open_operation_uk UNIQUE (company_id, open_operation_id),
  CONSTRAINT pos_shifts_close_operation_uk UNIQUE (company_id, close_operation_id),
  CONSTRAINT pos_shifts_close_state_ck CHECK (
    (status = 'open' AND closed_at IS NULL AND counted_cash IS NULL AND close_operation_id IS NULL)
    OR
    (status IN ('closed','frozen') AND closed_at IS NOT NULL AND counted_cash IS NOT NULL AND close_operation_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS pos_shifts_one_open_per_terminal_uidx
  ON public.pos_shifts(terminal_id) WHERE status = 'open';
CREATE UNIQUE INDEX IF NOT EXISTS pos_shifts_one_open_per_cashier_uidx
  ON public.pos_shifts(company_id, cashier_user_id) WHERE status = 'open';
CREATE INDEX IF NOT EXISTS pos_shifts_company_branch_opened_idx
  ON public.pos_shifts(company_id, branch_id, opened_at DESC);
CREATE INDEX IF NOT EXISTS pos_shifts_company_cashier_opened_idx
  ON public.pos_shifts(company_id, cashier_user_id, opened_at DESC);

CREATE TABLE IF NOT EXISTS public.pos_shift_cash_counts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  shift_id uuid NOT NULL,
  denomination numeric(12,2) NOT NULL CHECK (denomination > 0),
  quantity integer NOT NULL CHECK (quantity >= 0),
  amount numeric(14,2) GENERATED ALWAYS AS (denomination * quantity) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pos_shift_cash_counts_company_shift_denom_uk UNIQUE (company_id, shift_id, denomination),
  CONSTRAINT pos_shift_cash_counts_shift_fk FOREIGN KEY (company_id, shift_id)
    REFERENCES public.pos_shifts(company_id, id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS public.pos_shift_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  shift_id uuid NOT NULL,
  event_type text NOT NULL CHECK (event_type IN ('opened','closed','cash_counted','supervisor_reviewed')),
  operation_id uuid NOT NULL,
  actor_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pos_shift_events_company_type_operation_uk UNIQUE (company_id, event_type, operation_id),
  CONSTRAINT pos_shift_events_shift_fk FOREIGN KEY (company_id, shift_id)
    REFERENCES public.pos_shifts(company_id, id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS pos_shift_events_shift_created_idx
  ON public.pos_shift_events(company_id, shift_id, created_at);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shift_id uuid;
ALTER TABLE public.orders
  ADD CONSTRAINT orders_pos_shift_fk FOREIGN KEY (shift_id) REFERENCES public.pos_shifts(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS orders_company_shift_created_idx
  ON public.orders(company_id, shift_id, created_at) WHERE shift_id IS NOT NULL;

ALTER TABLE public.cash_box ADD COLUMN IF NOT EXISTS shift_id uuid;
ALTER TABLE public.cash_box
  ADD CONSTRAINT cash_box_pos_shift_fk FOREIGN KEY (shift_id) REFERENCES public.pos_shifts(id) ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS cash_box_company_shift_created_idx
  ON public.cash_box(company_id, shift_id, created_at) WHERE shift_id IS NOT NULL;

ALTER TABLE public.pos_terminals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_shift_cash_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_shift_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.pos_terminals, public.pos_shifts, public.pos_shift_cash_counts, public.pos_shift_events
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.pos_shift_expected_cash(p_shift_id uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT (s.opening_float + COALESCE(SUM(
    CASE
      WHEN cb.type = 'Receipt' THEN cb.amount
      WHEN cb.type = 'Payment' THEN -cb.amount
      ELSE 0
    END
  ), 0))::numeric(14,2)
  FROM public.pos_shifts s
  LEFT JOIN public.cash_box cb
    ON cb.company_id = s.company_id
   AND cb.shift_id = s.id
   AND COALESCE(cb.status, 'Active') NOT IN ('Voided','Cancelled','Inactive')
  WHERE s.id = p_shift_id
  GROUP BY s.id, s.opening_float
$function$;

CREATE OR REPLACE FUNCTION public.pos_assign_order_shift()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_cashier_user_id uuid;
  v_shift public.pos_shifts%ROWTYPE;
BEGIN
  IF lower(btrim(COALESCE(NEW.source, ''))) <> 'pos' THEN
    RETURN NEW;
  END IF;

  SELECT u.id INTO v_cashier_user_id
  FROM public.users u
  WHERE u.company_id = NEW.company_id
    AND lower(u.email) = lower(COALESCE(NEW.created_by, ''))
    AND COALESCE(u.status, 'Active') = 'Active'
  LIMIT 1;

  IF NEW.shift_id IS NOT NULL THEN
    SELECT * INTO v_shift
    FROM public.pos_shifts s
    WHERE s.id = NEW.shift_id
      AND s.company_id = NEW.company_id
      AND s.branch_id = NEW.branch_id
      AND s.status = 'open'
      AND s.cashier_user_id = v_cashier_user_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'POS_SHIFT_INVALID_OR_NOT_OWNED';
    END IF;
    RETURN NEW;
  END IF;

  IF v_cashier_user_id IS NULL OR NEW.branch_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_shift
  FROM public.pos_shifts s
  WHERE s.company_id = NEW.company_id
    AND s.branch_id = NEW.branch_id
    AND s.cashier_user_id = v_cashier_user_id
    AND s.status = 'open'
  ORDER BY s.opened_at DESC
  LIMIT 1;

  IF FOUND THEN
    NEW.shift_id := v_shift.id;
  END IF;

  -- Backward-compatible rollout: no open shift leaves legacy POS writes unchanged.
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_pos_assign_order_shift ON public.orders;
CREATE TRIGGER trg_pos_assign_order_shift
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.pos_assign_order_shift();

CREATE OR REPLACE FUNCTION public.pos_assign_cash_box_shift()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_order_shift_id uuid;
BEGIN
  IF NEW.shift_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.pos_shifts s
      WHERE s.id = NEW.shift_id AND s.company_id = NEW.company_id
    ) THEN
      RAISE EXCEPTION 'POS_SHIFT_COMPANY_MISMATCH';
    END IF;
    RETURN NEW;
  END IF;

  IF upper(COALESCE(NEW.source_type, '')) NOT IN ('POS','POS_RETURN_REFUND')
     OR NEW.source_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT o.shift_id INTO v_order_shift_id
  FROM public.orders o
  WHERE o.id = NEW.source_id
    AND o.company_id = NEW.company_id
  LIMIT 1;

  IF v_order_shift_id IS NOT NULL THEN
    NEW.shift_id := v_order_shift_id;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_pos_assign_cash_box_shift ON public.cash_box;
CREATE TRIGGER trg_pos_assign_cash_box_shift
BEFORE INSERT ON public.cash_box
FOR EACH ROW EXECUTE FUNCTION public.pos_assign_cash_box_shift();

CREATE OR REPLACE FUNCTION public.pos_open_shift(
  p_branch_id uuid,
  p_terminal_code text,
  p_opening_float numeric,
  p_operation_id uuid,
  p_treasury_id uuid DEFAULT NULL,
  p_terminal_label text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_auth_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_email text;
  v_treasury_id uuid;
  v_treasury_count integer;
  v_terminal public.pos_terminals%ROWTYPE;
  v_shift public.pos_shifts%ROWTYPE;
  v_fingerprint text;
BEGIN
  IF v_auth_id IS NULL THEN RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '42501'; END IF;
  IF NOT app_private.current_user_has_permission('pos') THEN RAISE EXCEPTION 'POS_PERMISSION_REQUIRED' USING ERRCODE = '42501'; END IF;
  v_company_id := app_private.current_user_company_id();
  IF v_company_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_COMPANY_REQUIRED' USING ERRCODE = '42501'; END IF;

  SELECT u.id, u.email INTO v_user_id, v_email
  FROM public.users u
  WHERE u.auth_id = v_auth_id AND u.company_id = v_company_id
    AND COALESCE(u.status, 'Active') = 'Active'
  LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_USER_PROFILE_REQUIRED' USING ERRCODE = '42501'; END IF;

  IF p_branch_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.get_pos_branches() b
    WHERE b.id = p_branch_id AND b.company_id = v_company_id AND COALESCE(b.is_active, true)
  ) THEN RAISE EXCEPTION 'POS_BRANCH_NOT_ALLOWED' USING ERRCODE = '42501'; END IF;

  IF p_operation_id IS NULL THEN RAISE EXCEPTION 'SHIFT_OPERATION_ID_REQUIRED'; END IF;
  IF p_opening_float IS NULL OR p_opening_float < 0 OR round(p_opening_float,2) <> p_opening_float THEN
    RAISE EXCEPTION 'SHIFT_OPENING_FLOAT_INVALID';
  END IF;
  IF NULLIF(btrim(COALESCE(p_terminal_code,'')), '') IS NULL
     OR p_terminal_code !~ '^[A-Za-z0-9._-]{3,80}$' THEN
    RAISE EXCEPTION 'SHIFT_TERMINAL_CODE_INVALID';
  END IF;

  IF p_treasury_id IS NULL THEN
    SELECT (array_agg(t.id ORDER BY t.id))[1], count(*)::integer INTO v_treasury_id, v_treasury_count
    FROM public.treasury t
    WHERE t.company_id = v_company_id AND t.is_active IS TRUE;
    IF v_treasury_count <> 1 THEN RAISE EXCEPTION 'SHIFT_TREASURY_SELECTION_REQUIRED'; END IF;
  ELSE
    v_treasury_id := p_treasury_id;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.treasury t
    WHERE t.id = v_treasury_id AND t.company_id = v_company_id AND t.is_active IS TRUE
  ) THEN RAISE EXCEPTION 'SHIFT_TREASURY_NOT_ALLOWED' USING ERRCODE = '42501'; END IF;

  v_fingerprint := md5(concat_ws('|', v_company_id, p_branch_id, p_terminal_code,
    v_treasury_id, p_opening_float::numeric(14,2), COALESCE(p_terminal_label,'')));

  SELECT * INTO v_shift
  FROM public.pos_shifts s
  WHERE s.company_id = v_company_id AND s.open_operation_id = p_operation_id
  FOR UPDATE;
  IF FOUND THEN
    IF v_shift.open_fingerprint <> v_fingerprint THEN RAISE EXCEPTION 'SHIFT_OPERATION_ID_REUSED_WITH_DIFFERENT_PAYLOAD'; END IF;
    RETURN jsonb_build_object('success', true, 'duplicate', true, 'shift_id', v_shift.id,
      'status', v_shift.status, 'opened_at', v_shift.opened_at, 'treasury_id', v_shift.treasury_id);
  END IF;

  INSERT INTO public.pos_terminals(company_id, branch_id, terminal_code, terminal_label, created_by_user_id)
  VALUES (v_company_id, p_branch_id, p_terminal_code, NULLIF(btrim(p_terminal_label),''), v_user_id)
  ON CONFLICT (company_id, terminal_code) DO NOTHING;

  SELECT * INTO v_terminal
  FROM public.pos_terminals t
  WHERE t.company_id = v_company_id AND t.terminal_code = p_terminal_code
  FOR UPDATE;
  IF NOT FOUND OR NOT v_terminal.is_active THEN RAISE EXCEPTION 'SHIFT_TERMINAL_INACTIVE_OR_MISSING'; END IF;
  IF v_terminal.branch_id <> p_branch_id THEN RAISE EXCEPTION 'SHIFT_TERMINAL_BRANCH_MISMATCH'; END IF;
  IF v_terminal.terminal_label IS NULL AND NULLIF(btrim(p_terminal_label),'') IS NOT NULL THEN
    UPDATE public.pos_terminals SET terminal_label = NULLIF(btrim(p_terminal_label),''), updated_at = now()
    WHERE id = v_terminal.id;
  END IF;

  INSERT INTO public.pos_shifts(
    company_id, branch_id, cashier_user_id, terminal_id, treasury_id, opening_float,
    open_operation_id, open_fingerprint, opening_notes
  ) VALUES (
    v_company_id, p_branch_id, v_user_id, v_terminal.id, v_treasury_id, p_opening_float,
    p_operation_id, v_fingerprint, NULLIF(btrim(p_terminal_label),'')
  ) RETURNING * INTO v_shift;

  INSERT INTO public.pos_shift_events(company_id, shift_id, event_type, operation_id, actor_user_id, payload)
  VALUES (v_company_id, v_shift.id, 'opened', p_operation_id, v_user_id,
    jsonb_build_object('branch_id',p_branch_id,'terminal_id',v_terminal.id,'treasury_id',v_treasury_id,
      'opening_float',v_shift.opening_float,'terminal_code',v_terminal.terminal_code));

  RETURN jsonb_build_object('success', true, 'duplicate', false, 'shift_id', v_shift.id,
    'status', v_shift.status, 'opened_at', v_shift.opened_at, 'branch_id', v_shift.branch_id,
    'terminal_id', v_terminal.id, 'treasury_id', v_shift.treasury_id, 'opening_float', v_shift.opening_float);
END;
$function$;

CREATE OR REPLACE FUNCTION public.pos_get_shift_summary(p_shift_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_auth_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_shift public.pos_shifts%ROWTYPE;
  v_expected numeric(14,2);
  v_cash_sales numeric(14,2);
  v_cash_refunds numeric(14,2);
  v_sale_count integer;
  v_counts jsonb;
  v_can_view_others boolean;
BEGIN
  IF v_auth_id IS NULL THEN RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '42501'; END IF;
  IF NOT app_private.current_user_has_permission('pos') THEN RAISE EXCEPTION 'POS_PERMISSION_REQUIRED' USING ERRCODE = '42501'; END IF;
  v_company_id := app_private.current_user_company_id();
  SELECT u.id INTO v_user_id FROM public.users u
  WHERE u.auth_id = v_auth_id AND u.company_id = v_company_id AND COALESCE(u.status,'Active')='Active' LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_USER_PROFILE_REQUIRED' USING ERRCODE = '42501'; END IF;

  v_can_view_others := app_private.current_user_has_permission('general_manager')
    OR app_private.current_user_has_permission('cash_manager')
    OR app_private.current_user_has_permission('accounting');

  IF p_shift_id IS NULL THEN
    SELECT * INTO v_shift FROM public.pos_shifts s
    WHERE s.company_id = v_company_id AND s.cashier_user_id = v_user_id AND s.status = 'open'
    ORDER BY s.opened_at DESC LIMIT 1;
    IF NOT FOUND THEN RETURN jsonb_build_object('success',true,'active_shift',false,'shift',NULL); END IF;
  ELSE
    SELECT * INTO v_shift FROM public.pos_shifts s
    WHERE s.id = p_shift_id AND s.company_id = v_company_id
      AND (s.cashier_user_id = v_user_id OR v_can_view_others)
    LIMIT 1;
    IF NOT FOUND THEN RAISE EXCEPTION 'SHIFT_NOT_FOUND_OR_NOT_AUTHORIZED' USING ERRCODE = '42501'; END IF;
  END IF;

  v_expected := public.pos_shift_expected_cash(v_shift.id);
  SELECT COALESCE(SUM(cb.amount) FILTER (WHERE cb.type='Receipt' AND upper(COALESCE(cb.source_type,''))='POS'),0),
         COALESCE(SUM(cb.amount) FILTER (WHERE cb.type='Payment' AND upper(COALESCE(cb.source_type,''))='POS_RETURN_REFUND'),0)
  INTO v_cash_sales, v_cash_refunds
  FROM public.cash_box cb
  WHERE cb.company_id = v_company_id AND cb.shift_id = v_shift.id
    AND COALESCE(cb.status,'Active') NOT IN ('Voided','Cancelled','Inactive');

  SELECT count(*)::integer INTO v_sale_count
  FROM public.orders o
  WHERE o.company_id = v_company_id AND o.shift_id = v_shift.id
    AND lower(COALESCE(o.source,''))='pos'
    AND o.order_status IN ('Invoiced','Partially Returned');

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'denomination', c.denomination, 'quantity', c.quantity, 'amount', c.amount
  ) ORDER BY c.denomination DESC),'[]'::jsonb)
  INTO v_counts FROM public.pos_shift_cash_counts c
  WHERE c.company_id = v_company_id AND c.shift_id = v_shift.id;

  RETURN jsonb_build_object(
    'success',true,'active_shift',(v_shift.status='open'),
    'shift',jsonb_build_object('id',v_shift.id,'company_id',v_shift.company_id,'branch_id',v_shift.branch_id,
      'cashier_user_id',v_shift.cashier_user_id,'terminal_id',v_shift.terminal_id,'treasury_id',v_shift.treasury_id,
      'status',v_shift.status,'opening_float',v_shift.opening_float,'opened_at',v_shift.opened_at,'closed_at',v_shift.closed_at,
      'expected_cash',v_expected,'counted_cash',v_shift.counted_cash,'cash_difference',v_shift.cash_difference,
      'discrepancy_reason',v_shift.discrepancy_reason,'terminal_code',(SELECT t.terminal_code FROM public.pos_terminals t WHERE t.id=v_shift.terminal_id),
      'treasury_name',(SELECT t.account_name FROM public.treasury t WHERE t.id=v_shift.treasury_id AND t.company_id=v_company_id)),
    'cash_sales',v_cash_sales,'cash_refunds',v_cash_refunds,'sale_count',v_sale_count,
    'expected_cash',v_expected,'cash_counts',v_counts,'close_summary',v_shift.close_summary
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.pos_close_shift(
  p_shift_id uuid,
  p_counted_cash numeric,
  p_counts jsonb,
  p_operation_id uuid,
  p_discrepancy_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_auth_id uuid := auth.uid();
  v_company_id uuid;
  v_user_id uuid;
  v_shift public.pos_shifts%ROWTYPE;
  v_expected numeric(14,2);
  v_count_sum numeric(14,2) := 0;
  v_denom numeric(12,2);
  v_qty_numeric numeric;
  v_qty integer;
  v_item jsonb;
  v_fingerprint text;
  v_summary jsonb;
BEGIN
  IF v_auth_id IS NULL THEN RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE = '42501'; END IF;
  IF NOT app_private.current_user_has_permission('pos') THEN RAISE EXCEPTION 'POS_PERMISSION_REQUIRED' USING ERRCODE = '42501'; END IF;
  v_company_id := app_private.current_user_company_id();
  SELECT u.id INTO v_user_id FROM public.users u
  WHERE u.auth_id=v_auth_id AND u.company_id=v_company_id AND COALESCE(u.status,'Active')='Active' LIMIT 1;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'ACTIVE_USER_PROFILE_REQUIRED' USING ERRCODE = '42501'; END IF;

  IF p_shift_id IS NULL OR p_operation_id IS NULL THEN RAISE EXCEPTION 'SHIFT_CLOSE_IDENTIFIERS_REQUIRED'; END IF;
  IF p_counted_cash IS NULL OR p_counted_cash < 0 OR round(p_counted_cash,2) <> p_counted_cash THEN
    RAISE EXCEPTION 'SHIFT_COUNTED_CASH_INVALID';
  END IF;
  IF p_counts IS NULL OR jsonb_typeof(p_counts) <> 'array' THEN RAISE EXCEPTION 'SHIFT_CASH_COUNTS_MUST_BE_ARRAY'; END IF;

  v_fingerprint := md5(concat_ws('|',p_shift_id,p_counted_cash,p_counts::text,COALESCE(p_discrepancy_reason,'')));

  SELECT * INTO v_shift FROM public.pos_shifts s
  WHERE s.id=p_shift_id AND s.company_id=v_company_id AND s.cashier_user_id=v_user_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'SHIFT_NOT_FOUND_OR_NOT_OWNED' USING ERRCODE = '42501'; END IF;

  IF v_shift.status='closed' THEN
    IF v_shift.close_operation_id=p_operation_id AND v_shift.close_fingerprint=v_fingerprint THEN
      RETURN COALESCE(v_shift.close_summary,'{}'::jsonb) || jsonb_build_object('success',true,'duplicate',true);
    END IF;
    RAISE EXCEPTION 'SHIFT_ALREADY_CLOSED';
  END IF;
  IF v_shift.status <> 'open' THEN RAISE EXCEPTION 'SHIFT_NOT_OPEN'; END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_counts) LOOP
    IF jsonb_typeof(v_item) <> 'object' OR NULLIF(v_item->>'denomination','') IS NULL
      OR NULLIF(v_item->>'quantity','') IS NULL THEN RAISE EXCEPTION 'SHIFT_CASH_COUNT_ITEM_INVALID'; END IF;
    v_denom := (v_item->>'denomination')::numeric;
    v_qty_numeric := (v_item->>'quantity')::numeric;
    IF v_denom <= 0 OR round(v_denom,2) <> v_denom OR v_qty_numeric < 0 OR v_qty_numeric <> trunc(v_qty_numeric) THEN
      RAISE EXCEPTION 'SHIFT_CASH_COUNT_VALUE_INVALID';
    END IF;
    v_qty := v_qty_numeric::integer;
    v_count_sum := v_count_sum + v_denom * v_qty;
  END LOOP;

  IF round(v_count_sum,2) <> p_counted_cash THEN
    RAISE EXCEPTION 'SHIFT_DENOMINATION_TOTAL_MISMATCH: expected %, received %', v_count_sum, p_counted_cash;
  END IF;

  v_expected := public.pos_shift_expected_cash(v_shift.id);
  IF v_expected IS NULL THEN RAISE EXCEPTION 'SHIFT_EXPECTED_CASH_UNAVAILABLE'; END IF;
  IF round(p_counted_cash-v_expected,2) <> 0 AND NULLIF(btrim(COALESCE(p_discrepancy_reason,'')),'') IS NULL THEN
    RAISE EXCEPTION 'SHIFT_DISCREPANCY_REASON_REQUIRED';
  END IF;

  INSERT INTO public.pos_shift_cash_counts(company_id,shift_id,denomination,quantity)
  SELECT v_company_id,p_shift_id,(x.value->>'denomination')::numeric,(x.value->>'quantity')::integer
  FROM jsonb_array_elements(p_counts) x;

  v_summary := jsonb_build_object(
    'shift_id',v_shift.id,'status','closed','closed_at',now(),
    'opening_float',v_shift.opening_float,'expected_cash',v_expected,
    'counted_cash',p_counted_cash,'cash_difference',round(p_counted_cash-v_expected,2),
    'discrepancy_reason',NULLIF(btrim(COALESCE(p_discrepancy_reason,'')),''),
    'denomination_total',v_count_sum
  );

  UPDATE public.pos_shifts
  SET status='closed',closed_at=now(),expected_cash=v_expected,counted_cash=p_counted_cash,
      cash_difference=round(p_counted_cash-v_expected,2),
      discrepancy_reason=NULLIF(btrim(COALESCE(p_discrepancy_reason,'')),''),
      close_operation_id=p_operation_id,close_fingerprint=v_fingerprint,
      close_summary=v_summary,updated_at=now()
  WHERE id=v_shift.id AND company_id=v_company_id;

  INSERT INTO public.pos_shift_events(company_id,shift_id,event_type,operation_id,actor_user_id,payload)
  VALUES (v_company_id,v_shift.id,'closed',p_operation_id,v_user_id,v_summary);

  RETURN v_summary || jsonb_build_object('success',true,'duplicate',false);
END;
$function$;

REVOKE ALL ON FUNCTION public.pos_shift_expected_cash(uuid) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.pos_assign_order_shift() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.pos_assign_cash_box_shift() FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.pos_open_shift(uuid,text,numeric,uuid,uuid,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.pos_get_shift_summary(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.pos_close_shift(uuid,numeric,jsonb,uuid,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.pos_open_shift(uuid,text,numeric,uuid,uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pos_get_shift_summary(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pos_close_shift(uuid,numeric,jsonb,uuid,text) TO authenticated;

COMMENT ON TABLE public.pos_shifts IS 'Operational POS shift control; not a parallel financial ledger. Financial truth remains in existing cash_box, receipt and journal contracts.';
COMMENT ON COLUMN public.orders.shift_id IS 'Nullable during staged POS rollout; populated by the database when a matching authenticated cashier has an open shift.';
COMMENT ON COLUMN public.cash_box.shift_id IS 'Operational trace link to the POS shift; does not alter treasury balances.';
