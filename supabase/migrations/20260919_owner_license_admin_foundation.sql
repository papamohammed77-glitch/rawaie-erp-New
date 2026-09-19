BEGIN;

CREATE TABLE IF NOT EXISTS public.company_licenses (
  company_id uuid PRIMARY KEY REFERENCES public.companies(id) ON DELETE CASCADE,
  plan_code text,
  license_status text NOT NULL DEFAULT 'trial'
    CHECK (license_status IN ('trial','active','suspended','cancelled')),
  trial_start_date date,
  trial_end_date date,
  subscription_start_date date,
  subscription_end_date date,
  grace_end_date date,
  billing_cycle text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid
);

ALTER TABLE public.company_licenses ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.company_licenses FROM PUBLIC, anon, authenticated;

CREATE INDEX IF NOT EXISTS company_licenses_status_idx
  ON public.company_licenses (license_status);

CREATE OR REPLACE FUNCTION public.guard_app_settings_license_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
BEGIN
  IF current_user NOT IN ('postgres','service_role') THEN
    IF TG_OP = 'UPDATE'
       AND (
         NEW.status IS DISTINCT FROM OLD.status
         OR NEW.trial_end_date IS DISTINCT FROM OLD.trial_end_date
         OR NEW.subscription_end_date IS DISTINCT FROM OLD.subscription_end_date
       )
       AND NOT app_private.current_user_has_permission('owner') THEN
      RAISE EXCEPTION 'OWNER_REQUIRED_FOR_LICENSE_SETTINGS';
    END IF;

    IF TG_OP = 'INSERT'
       AND (
         lower(coalesce(NEW.status,'trial')) <> 'trial'
         OR NEW.trial_end_date IS NOT NULL
         OR NEW.subscription_end_date IS NOT NULL
       )
       AND NOT app_private.current_user_has_permission('owner') THEN
      RAISE EXCEPTION 'OWNER_REQUIRED_FOR_LICENSE_SETTINGS';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_app_settings_license_fields
  ON public.app_settings;

CREATE TRIGGER trg_guard_app_settings_license_fields
BEFORE INSERT OR UPDATE OF status, trial_end_date, subscription_end_date
ON public.app_settings
FOR EACH ROW
EXECUTE FUNCTION public.guard_app_settings_license_fields();

CREATE OR REPLACE FUNCTION public.sync_company_license_from_app_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
BEGIN
  INSERT INTO public.company_licenses (
    company_id, license_status, trial_end_date, subscription_end_date, updated_at
  )
  VALUES (
    NEW.company_id, lower(coalesce(NEW.status,'trial')),
    NEW.trial_end_date, NEW.subscription_end_date, now()
  )
  ON CONFLICT (company_id) DO UPDATE
  SET license_status = EXCLUDED.license_status,
      trial_end_date = EXCLUDED.trial_end_date,
      subscription_end_date = EXCLUDED.subscription_end_date,
      updated_at = now();

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_sync_company_license_from_app_settings
  ON public.app_settings;

CREATE TRIGGER trg_sync_company_license_from_app_settings
AFTER INSERT OR UPDATE OF status, trial_end_date, subscription_end_date
ON public.app_settings
FOR EACH ROW
EXECUTE FUNCTION public.sync_company_license_from_app_settings();

INSERT INTO public.company_licenses (
  company_id, license_status, trial_end_date, subscription_end_date
)
SELECT a.company_id,
       lower(coalesce(a.status,'trial')),
       a.trial_end_date,
       a.subscription_end_date
FROM public.app_settings a
WHERE NOT EXISTS (
  SELECT 1 FROM public.company_licenses l WHERE l.company_id = a.company_id
);

CREATE OR REPLACE FUNCTION public.owner_license_admin_atomic(
  p_action text,
  p_company_id uuid DEFAULT NULL,
  p_actor_user_id uuid DEFAULT NULL,
  p_actor_auth_id uuid DEFAULT NULL,
  p_actor_email text DEFAULT NULL,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_owner boolean := false;
  v_company public.companies%ROWTYPE;
  v_app public.app_settings%ROWTYPE;
  v_license public.company_licenses%ROWTYPE;
  v_old jsonb;
  v_new jsonb;
  v_status text;
  v_plan text;
  v_cycle text;
  v_trial_start date;
  v_trial_end date;
  v_sub_start date;
  v_sub_end date;
  v_grace_end date;
  v_notes text;
  v_action text := lower(coalesce(p_action,''));
  v_result jsonb;
BEGIN
  IF p_actor_user_id IS NULL OR p_actor_auth_id IS NULL OR NULLIF(btrim(p_actor_email),'') IS NULL THEN
    RAISE EXCEPTION 'ACTOR_INVALID';
  END IF;

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.id = p_actor_user_id
    AND u.auth_id = p_actor_auth_id
    AND lower(u.email) = lower(p_actor_email)
    AND coalesce(u.status,'Active') = 'Active'
  LIMIT 1;

  IF NOT FOUND THEN RAISE EXCEPTION 'ACTOR_CONTEXT_INVALID'; END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.owner_profile op WHERE op.auth_user_id = p_actor_auth_id
  )
  AND jsonb_typeof(v_actor.permissions) = 'array'
  AND (v_actor.permissions ? '*')
  INTO v_owner;

  IF NOT v_owner THEN RAISE EXCEPTION 'OWNER_REQUIRED'; END IF;

  IF v_action = 'list' THEN
    SELECT jsonb_build_object(
      'success', true,
      'companies',
      coalesce((
        SELECT jsonb_agg(
          jsonb_build_object(
            'company_id', c.id,
            'company_code', c.company_code,
            'name', c.name,
            'is_active', c.is_active,
            'tax_id', c.tax_id,
            'phone', c.phone,
            'email', c.email,
            'website', c.website,
            'license_status', coalesce(l.license_status, lower(a.status)),
            'plan_code', l.plan_code,
            'billing_cycle', l.billing_cycle,
            'trial_start_date', l.trial_start_date,
            'trial_end_date', coalesce(l.trial_end_date, a.trial_end_date),
            'subscription_start_date', l.subscription_start_date,
            'subscription_end_date', coalesce(l.subscription_end_date, a.subscription_end_date),
            'grace_end_date', l.grace_end_date,
            'notes', l.notes,
            'active_users', (select count(*) from public.users u2 where u2.company_id=c.id and coalesce(u2.status,'Active')='Active'),
            'active_branches', (select count(*) from public.branches b2 where b2.company_id=c.id and coalesce(b2.is_active,true)=true),
            'main_branch_id', coalesce(c.main_branch_id,a.main_branch_id),
            'updated_at', greatest(coalesce(l.updated_at,'epoch'::timestamptz),coalesce(a.updated_at,'epoch'::timestamptz))
          )
          ORDER BY c.name, c.id
        )
        FROM public.companies c
        LEFT JOIN public.company_licenses l ON l.company_id=c.id
        LEFT JOIN LATERAL (
          SELECT a2.* FROM public.app_settings a2
          WHERE a2.company_id=c.id
          ORDER BY a2.created_at ASC, a2.id
          LIMIT 1
        ) a ON true
      ), '[]'::jsonb)
    ) INTO v_result;
    RETURN v_result;
  END IF;

  IF p_company_id IS NULL THEN RAISE EXCEPTION 'COMPANY_REQUIRED'; END IF;

  SELECT * INTO v_company FROM public.companies WHERE id=p_company_id LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'COMPANY_NOT_FOUND'; END IF;

  IF v_action = 'detail' THEN
    SELECT a.* INTO v_app
    FROM public.app_settings a
    WHERE a.company_id=p_company_id
    ORDER BY a.created_at ASC, a.id
    LIMIT 1;

    SELECT l.* INTO v_license
    FROM public.company_licenses l
    WHERE l.company_id=p_company_id;

    SELECT jsonb_build_object(
      'success', true,
      'company', jsonb_build_object(
        'id', v_company.id,
        'company_code', v_company.company_code,
        'name', v_company.name,
        'logo_url', v_company.logo_url,
        'tax_id', v_company.tax_id,
        'phone', v_company.phone,
        'email', v_company.email,
        'address', v_company.address,
        'website', v_company.website,
        'is_active', v_company.is_active,
        'main_branch_id', v_company.main_branch_id,
        'main_branch_code', v_company.main_branch_code
      ),
      'license', CASE WHEN v_license.company_id IS NULL THEN NULL ELSE to_jsonb(v_license) END,
      'runtime', CASE
        WHEN v_app.id IS NULL THEN NULL
        ELSE jsonb_build_object(
          'status', v_app.status,
          'trial_end_date', v_app.trial_end_date,
          'subscription_end_date', v_app.subscription_end_date,
          'updated_at', v_app.updated_at
        )
      END,
      'metrics', jsonb_build_object(
        'active_users', (select count(*) from public.users u where u.company_id=p_company_id and coalesce(u.status,'Active')='Active'),
        'active_branches', (select count(*) from public.branches b where b.company_id=p_company_id and coalesce(b.is_active,true)=true)
      ),
      'audit', coalesce((
        SELECT jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC)
        FROM (
          SELECT a.* FROM public.audit_log a
          WHERE a.table_name='company_licenses'
            AND a.record_id=p_company_id::text
          ORDER BY a.created_at DESC
          LIMIT 25
        ) x
      ), '[]'::jsonb)
    ) INTO v_result;

    RETURN v_result;
  END IF;

  IF v_action <> 'save' THEN RAISE EXCEPTION 'ACTION_NOT_SUPPORTED'; END IF;
  IF p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN RAISE EXCEPTION 'PAYLOAD_INVALID'; END IF;

  SELECT l.* INTO v_license
  FROM public.company_licenses l
  WHERE l.company_id=p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    SELECT a.* INTO v_app
    FROM public.app_settings a
    WHERE a.company_id=p_company_id
    ORDER BY a.created_at ASC, a.id
    LIMIT 1;

    INSERT INTO public.company_licenses(
      company_id, license_status, trial_end_date, subscription_end_date, created_by, updated_by
    )
    VALUES(
      p_company_id, lower(coalesce(v_app.status,'trial')),
      v_app.trial_end_date, v_app.subscription_end_date,
      p_actor_user_id, p_actor_user_id
    )
    RETURNING * INTO v_license;
  END IF;

  v_old := to_jsonb(v_license);

  v_status := lower(coalesce(NULLIF(btrim(p_payload->>'license_status'),''), v_license.license_status));
  IF v_status NOT IN ('trial','active','suspended','cancelled') THEN
    RAISE EXCEPTION 'LICENSE_STATUS_INVALID';
  END IF;

  v_plan := NULLIF(btrim(coalesce(p_payload->>'plan_code','')), '');
  IF v_plan IS NOT NULL AND length(v_plan)>64 THEN RAISE EXCEPTION 'PLAN_CODE_TOO_LONG'; END IF;

  v_cycle := NULLIF(btrim(coalesce(p_payload->>'billing_cycle','')), '');
  IF v_cycle IS NOT NULL AND length(v_cycle)>32 THEN RAISE EXCEPTION 'BILLING_CYCLE_TOO_LONG'; END IF;

  IF p_payload ? 'trial_start_date' THEN v_trial_start := NULLIF(btrim(p_payload->>'trial_start_date'),'')::date; ELSE v_trial_start := v_license.trial_start_date; END IF;
  IF p_payload ? 'trial_end_date' THEN v_trial_end := NULLIF(btrim(p_payload->>'trial_end_date'),'')::date; ELSE v_trial_end := v_license.trial_end_date; END IF;
  IF p_payload ? 'subscription_start_date' THEN v_sub_start := NULLIF(btrim(p_payload->>'subscription_start_date'),'')::date; ELSE v_sub_start := v_license.subscription_start_date; END IF;
  IF p_payload ? 'subscription_end_date' THEN v_sub_end := NULLIF(btrim(p_payload->>'subscription_end_date'),'')::date; ELSE v_sub_end := v_license.subscription_end_date; END IF;
  IF p_payload ? 'grace_end_date' THEN v_grace_end := NULLIF(btrim(p_payload->>'grace_end_date'),'')::date; ELSE v_grace_end := v_license.grace_end_date; END IF;

  v_notes := CASE WHEN p_payload ? 'notes' THEN NULLIF(btrim(p_payload->>'notes'),'') ELSE v_license.notes END;

  IF v_trial_start IS NOT NULL AND v_trial_end IS NOT NULL AND v_trial_end < v_trial_start THEN RAISE EXCEPTION 'TRIAL_DATE_RANGE_INVALID'; END IF;
  IF v_sub_start IS NOT NULL AND v_sub_end IS NOT NULL AND v_sub_end < v_sub_start THEN RAISE EXCEPTION 'SUBSCRIPTION_DATE_RANGE_INVALID'; END IF;
  IF v_grace_end IS NOT NULL AND v_sub_end IS NOT NULL AND v_grace_end < v_sub_end THEN RAISE EXCEPTION 'GRACE_DATE_INVALID'; END IF;

  UPDATE public.company_licenses
  SET plan_code=v_plan, license_status=v_status,
      trial_start_date=v_trial_start, trial_end_date=v_trial_end,
      subscription_start_date=v_sub_start, subscription_end_date=v_sub_end,
      grace_end_date=v_grace_end, billing_cycle=v_cycle, notes=v_notes,
      updated_at=now(), updated_by=p_actor_user_id
  WHERE company_id=p_company_id
  RETURNING * INTO v_license;

  UPDATE public.app_settings
  SET status=v_status, trial_end_date=v_trial_end, subscription_end_date=v_sub_end, updated_at=now()
  WHERE company_id=p_company_id;

  IF NOT FOUND THEN
    INSERT INTO public.app_settings(company_id,status,trial_end_date,subscription_end_date)
    VALUES(p_company_id,v_status,v_trial_end,v_sub_end);
  END IF;

  v_new := to_jsonb(v_license);

  IF v_old IS DISTINCT FROM v_new THEN
    INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data,new_data)
    VALUES(p_actor_email,'update','company_licenses',p_company_id::text,v_old,v_new);
  END IF;

  RETURN public.owner_license_admin_atomic('detail',p_company_id,p_actor_user_id,p_actor_auth_id,p_actor_email,'{}'::jsonb);
END;
$function$;

REVOKE ALL ON FUNCTION public.owner_license_admin_atomic(text,uuid,uuid,uuid,text,jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.owner_license_admin_atomic(text,uuid,uuid,uuid,text,jsonb)
  TO service_role;

COMMIT;
