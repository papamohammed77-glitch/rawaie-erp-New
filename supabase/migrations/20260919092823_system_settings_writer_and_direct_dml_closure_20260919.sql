-- RAWAEA ERP — System Settings Writer / Direct-DML Closure
-- Production registry version: 20260919092823
-- Purpose:
--   1) restore the proven Store PWA free_shipping_threshold contract;
--   2) centralize Settings writes in a single audited service_role RPC;
--   3) remove direct client DML on app_settings;
--   4) preserve OWNER / settings permission semantics;
--   5) make semantic no-op saves side-effect free.

BEGIN;

ALTER TABLE public.app_settings
  ADD COLUMN IF NOT EXISTS free_shipping_threshold numeric NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.app_settings'::regclass
      AND conname='app_settings_delivery_fee_nonnegative'
  ) THEN
    ALTER TABLE public.app_settings
      ADD CONSTRAINT app_settings_delivery_fee_nonnegative
      CHECK (delivery_fee >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.app_settings'::regclass
      AND conname='app_settings_min_invoice_amount_nonnegative'
  ) THEN
    ALTER TABLE public.app_settings
      ADD CONSTRAINT app_settings_min_invoice_amount_nonnegative
      CHECK (min_invoice_amount >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.app_settings'::regclass
      AND conname='app_settings_tax_rate_range'
  ) THEN
    ALTER TABLE public.app_settings
      ADD CONSTRAINT app_settings_tax_rate_range
      CHECK (tax_rate >= 0 AND tax_rate <= 100);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid='public.app_settings'::regclass
      AND conname='app_settings_free_shipping_threshold_nonnegative'
  ) THEN
    ALTER TABLE public.app_settings
      ADD CONSTRAINT app_settings_free_shipping_threshold_nonnegative
      CHECK (free_shipping_threshold >= 0);
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.save_system_settings_atomic(
  p_company_id uuid,
  p_actor_user_id uuid,
  p_actor_email text,
  p_owner_verified boolean,
  p_settings jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_role_permissions jsonb;
  v_owner_profile_exists boolean := false;
  v_can_settings boolean := false;
  v_is_owner boolean := false;
  v_license_requested boolean := false;
  v_unknown text[];
  v_current public.app_settings%ROWTYPE;
  v_saved public.app_settings%ROWTYPE;
  v_old_data jsonb;
  v_new_data jsonb;
  v_changed boolean := false;
  v_created boolean := false;

  v_company_name text;
  v_company_phone text;
  v_company_logo text;
  v_store_name text;
  v_store_logo text;
  v_primary_color text;
  v_secondary_color text;
  v_payment_method text;
  v_currency text;
  v_delivery_fee numeric;
  v_min_invoice numeric;
  v_tax_rate numeric;
  v_free_shipping numeric;
  v_main_branch uuid;

  v_status text;
  v_trial_end date;
  v_subscription_end date;
BEGIN
  IF p_company_id IS NULL
     OR NOT EXISTS (
       SELECT 1 FROM public.companies c WHERE c.id = p_company_id
     ) THEN
    RAISE EXCEPTION 'COMPANY_INVALID';
  END IF;

  IF p_actor_user_id IS NULL
     OR p_actor_email IS NULL
     OR NULLIF(btrim(p_actor_email),'') IS NULL THEN
    RAISE EXCEPTION 'ACTOR_INVALID';
  END IF;

  IF p_settings IS NULL OR jsonb_typeof(p_settings) <> 'object' THEN
    RAISE EXCEPTION 'SETTINGS_PAYLOAD_INVALID';
  END IF;

  SELECT u.*
    INTO v_actor
  FROM public.users u
  WHERE u.id = p_actor_user_id
    AND u.company_id = p_company_id
    AND COALESCE(u.status,'Active') = 'Active'
    AND u.auth_id IS NOT NULL
    AND lower(u.email) = lower(p_actor_email)
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ACTOR_COMPANY_CONTEXT_INVALID';
  END IF;

  SELECT r.permissions
    INTO v_role_permissions
  FROM public.roles r
  WHERE r.id = v_actor.role_id
  LIMIT 1;

  SELECT EXISTS (
    SELECT 1
    FROM public.owner_profile op
    WHERE op.auth_user_id = v_actor.auth_id
  ) INTO v_owner_profile_exists;

  v_is_owner :=
    COALESCE(p_owner_verified,false)
    AND jsonb_typeof(v_actor.permissions)='array'
    AND (v_actor.permissions ? '*')
    AND v_owner_profile_exists;

  v_can_settings :=
    v_is_owner
    OR (
      jsonb_typeof(v_actor.permissions)='array'
      AND (v_actor.permissions ? 'settings' OR v_actor.permissions ? '*')
    )
    OR (
      jsonb_typeof(v_role_permissions)='array'
      AND (v_role_permissions ? 'settings' OR v_role_permissions ? '*')
    );

  IF NOT v_can_settings THEN
    RAISE EXCEPTION 'SETTINGS_PERMISSION_REQUIRED';
  END IF;

  SELECT array_agg(k ORDER BY k)
    INTO v_unknown
  FROM jsonb_object_keys(p_settings) AS k
  WHERE k NOT IN (
    'company_name',
    'company_phone',
    'company_logo',
    'store_name',
    'store_logo',
    'store_primary_color',
    'store_secondary_color',
    'payment_method',
    'currency',
    'delivery_fee',
    'min_invoice_amount',
    'tax_rate',
    'free_shipping_threshold',
    'main_branch_id',
    'status',
    'trial_end_date',
    'subscription_end_date'
  );

  IF v_unknown IS NOT NULL THEN
    RAISE EXCEPTION 'UNSUPPORTED_SETTINGS_FIELDS:%',
      array_to_string(v_unknown, ',');
  END IF;

  v_license_requested :=
    p_settings ? 'status'
    OR p_settings ? 'trial_end_date'
    OR p_settings ? 'subscription_end_date';

  IF v_license_requested AND NOT v_is_owner THEN
    RAISE EXCEPTION 'OWNER_REQUIRED_FOR_LICENSE_SETTINGS';
  END IF;

  SELECT *
    INTO v_current
  FROM public.app_settings
  WHERE company_id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.app_settings(company_id)
    VALUES (p_company_id)
    RETURNING * INTO v_current;
    v_created := true;
  END IF;

  v_old_data := CASE WHEN v_created THEN NULL ELSE to_jsonb(v_current) END;

  v_company_name := v_current.company_name;
  v_company_phone := v_current.company_phone;
  v_company_logo := v_current.company_logo;
  v_store_name := v_current.store_name;
  v_store_logo := v_current.store_logo;
  v_primary_color := v_current.store_primary_color;
  v_secondary_color := v_current.store_secondary_color;
  v_payment_method := v_current.payment_method;
  v_currency := v_current.currency;
  v_delivery_fee := v_current.delivery_fee;
  v_min_invoice := v_current.min_invoice_amount;
  v_tax_rate := v_current.tax_rate;
  v_free_shipping := v_current.free_shipping_threshold;
  v_main_branch := v_current.main_branch_id;
  v_status := v_current.status;
  v_trial_end := v_current.trial_end_date;
  v_subscription_end := v_current.subscription_end_date;

  IF p_settings ? 'company_name' THEN
    v_company_name := NULLIF(btrim(p_settings->>'company_name'),'');
    IF v_company_name IS NULL OR length(v_company_name) > 200 THEN
      RAISE EXCEPTION 'COMPANY_NAME_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'company_phone' THEN
    v_company_phone := NULLIF(btrim(p_settings->>'company_phone'),'');
    IF v_company_phone IS NOT NULL AND length(v_company_phone) > 50 THEN
      RAISE EXCEPTION 'COMPANY_PHONE_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'company_logo' THEN
    v_company_logo := NULLIF(btrim(p_settings->>'company_logo'),'');
    IF v_company_logo IS NOT NULL AND length(v_company_logo) > 2000 THEN
      RAISE EXCEPTION 'COMPANY_LOGO_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'store_name' THEN
    v_store_name := NULLIF(btrim(p_settings->>'store_name'),'');
    IF v_store_name IS NULL OR length(v_store_name) > 200 THEN
      RAISE EXCEPTION 'STORE_NAME_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'store_logo' THEN
    v_store_logo := NULLIF(btrim(p_settings->>'store_logo'),'');
    IF v_store_logo IS NOT NULL AND length(v_store_logo) > 2000 THEN
      RAISE EXCEPTION 'STORE_LOGO_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'store_primary_color' THEN
    v_primary_color := NULLIF(btrim(p_settings->>'store_primary_color'),'');
    IF v_primary_color IS NOT NULL
       AND v_primary_color !~ '^#[0-9A-Fa-f]{6}$' THEN
      RAISE EXCEPTION 'STORE_PRIMARY_COLOR_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'store_secondary_color' THEN
    v_secondary_color := NULLIF(btrim(p_settings->>'store_secondary_color'),'');
    IF v_secondary_color IS NOT NULL
       AND v_secondary_color !~ '^#[0-9A-Fa-f]{6}$' THEN
      RAISE EXCEPTION 'STORE_SECONDARY_COLOR_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'payment_method' THEN
    v_payment_method := NULLIF(btrim(p_settings->>'payment_method'),'');
    IF v_payment_method IS NOT NULL AND length(v_payment_method) > 32 THEN
      RAISE EXCEPTION 'PAYMENT_METHOD_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'currency' THEN
    v_currency := upper(NULLIF(btrim(p_settings->>'currency'),''));
    IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
      RAISE EXCEPTION 'CURRENCY_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'delivery_fee' THEN
    BEGIN
      v_delivery_fee := COALESCE(NULLIF(p_settings->>'delivery_fee','')::numeric,0);
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'DELIVERY_FEE_INVALID';
    END;
    IF v_delivery_fee < 0 THEN
      RAISE EXCEPTION 'DELIVERY_FEE_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'min_invoice_amount' THEN
    BEGIN
      v_min_invoice := COALESCE(NULLIF(p_settings->>'min_invoice_amount','')::numeric,0);
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'MIN_INVOICE_AMOUNT_INVALID';
    END;
    IF v_min_invoice < 0 THEN
      RAISE EXCEPTION 'MIN_INVOICE_AMOUNT_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'tax_rate' THEN
    BEGIN
      v_tax_rate := COALESCE(NULLIF(p_settings->>'tax_rate','')::numeric,0);
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'TAX_RATE_INVALID';
    END;
    IF v_tax_rate < 0 OR v_tax_rate > 100 THEN
      RAISE EXCEPTION 'TAX_RATE_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'free_shipping_threshold' THEN
    BEGIN
      v_free_shipping := COALESCE(NULLIF(p_settings->>'free_shipping_threshold','')::numeric,0);
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'FREE_SHIPPING_THRESHOLD_INVALID';
    END;
    IF v_free_shipping < 0 THEN
      RAISE EXCEPTION 'FREE_SHIPPING_THRESHOLD_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'main_branch_id' THEN
    IF NULLIF(btrim(p_settings->>'main_branch_id'),'') IS NULL THEN
      RAISE EXCEPTION 'MAIN_BRANCH_REQUIRED';
    END IF;

    BEGIN
      v_main_branch := (p_settings->>'main_branch_id')::uuid;
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'MAIN_BRANCH_INVALID';
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM public.branches b
      WHERE b.id = v_main_branch
        AND b.company_id = p_company_id
    ) THEN
      RAISE EXCEPTION 'MAIN_BRANCH_COMPANY_MISMATCH';
    END IF;
  END IF;

  IF p_settings ? 'status' THEN
    v_status := lower(NULLIF(btrim(p_settings->>'status'),''));
    IF v_status NOT IN ('trial','active','suspended','cancelled') THEN
      RAISE EXCEPTION 'LICENSE_STATUS_INVALID';
    END IF;
  END IF;

  IF p_settings ? 'trial_end_date'
     AND NULLIF(btrim(p_settings->>'trial_end_date'),'') IS NOT NULL THEN
    BEGIN
      v_trial_end := (p_settings->>'trial_end_date')::date;
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'TRIAL_END_DATE_INVALID';
    END;
  END IF;

  IF p_settings ? 'subscription_end_date'
     AND NULLIF(btrim(p_settings->>'subscription_end_date'),'') IS NOT NULL THEN
    BEGIN
      v_subscription_end := (p_settings->>'subscription_end_date')::date;
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'SUBSCRIPTION_END_DATE_INVALID';
    END;
  END IF;

  v_changed :=
       v_created
    OR (v_company_name IS DISTINCT FROM v_current.company_name)
    OR (v_company_phone IS DISTINCT FROM v_current.company_phone)
    OR (v_company_logo IS DISTINCT FROM v_current.company_logo)
    OR (v_store_name IS DISTINCT FROM v_current.store_name)
    OR (v_store_logo IS DISTINCT FROM v_current.store_logo)
    OR (v_primary_color IS DISTINCT FROM v_current.store_primary_color)
    OR (v_secondary_color IS DISTINCT FROM v_current.store_secondary_color)
    OR (v_payment_method IS DISTINCT FROM v_current.payment_method)
    OR (v_currency IS DISTINCT FROM v_current.currency)
    OR (v_delivery_fee IS DISTINCT FROM v_current.delivery_fee)
    OR (v_min_invoice IS DISTINCT FROM v_current.min_invoice_amount)
    OR (v_tax_rate IS DISTINCT FROM v_current.tax_rate)
    OR (v_free_shipping IS DISTINCT FROM v_current.free_shipping_threshold)
    OR (v_main_branch IS DISTINCT FROM v_current.main_branch_id)
    OR (v_status IS DISTINCT FROM v_current.status)
    OR (v_trial_end IS DISTINCT FROM v_current.trial_end_date)
    OR (v_subscription_end IS DISTINCT FROM v_current.subscription_end_date);

  IF NOT v_changed THEN
    RETURN jsonb_build_object(
      'success', true,
      'company_id', p_company_id,
      'actor_user_id', p_actor_user_id,
      'changed', false,
      'created', false,
      'owner_action', v_license_requested,
      'settings', to_jsonb(v_current)
    );
  END IF;

  UPDATE public.app_settings
  SET
    company_name = v_company_name,
    company_phone = v_company_phone,
    company_logo = v_company_logo,
    store_name = v_store_name,
    store_logo = v_store_logo,
    store_primary_color = v_primary_color,
    store_secondary_color = v_secondary_color,
    payment_method = v_payment_method,
    currency = v_currency,
    delivery_fee = v_delivery_fee,
    min_invoice_amount = v_min_invoice,
    tax_rate = v_tax_rate,
    free_shipping_threshold = v_free_shipping,
    main_branch_id = v_main_branch,
    status = v_status,
    trial_end_date = v_trial_end,
    subscription_end_date = v_subscription_end,
    updated_at = now()
  WHERE id = v_current.id
    AND company_id = p_company_id
  RETURNING * INTO v_saved;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SETTINGS_WRITE_FAILED';
  END IF;

  v_new_data := to_jsonb(v_saved);

  INSERT INTO public.audit_log(
    user_email,
    action,
    table_name,
    record_id,
    old_data,
    new_data
  ) VALUES (
    p_actor_email,
    CASE WHEN v_created THEN 'create' ELSE 'update' END,
    'app_settings',
    v_saved.id::text,
    v_old_data,
    v_new_data
  );

  RETURN jsonb_build_object(
    'success', true,
    'company_id', p_company_id,
    'actor_user_id', p_actor_user_id,
    'changed', true,
    'created', v_created,
    'owner_action', v_license_requested,
    'settings', to_jsonb(v_saved)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.save_system_settings_atomic(uuid,uuid,text,boolean,jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.save_system_settings_atomic(uuid,uuid,text,boolean,jsonb)
  TO service_role;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES
  ON public.app_settings
  FROM anon, authenticated;

COMMENT ON FUNCTION public.save_system_settings_atomic(uuid,uuid,text,boolean,jsonb)
IS 'Canonical atomic system-settings writer. General settings require settings permission; license fields require verified OWNER; direct client DML is forbidden; semantic no-op does not touch updated_at.';

COMMIT;
