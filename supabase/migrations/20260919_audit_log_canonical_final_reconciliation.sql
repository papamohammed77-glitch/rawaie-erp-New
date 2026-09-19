-- RAWAEA ERP — Audit Log canonical final reconciliation
-- Date: 2026-09-19
-- Scope: Audit Log only.
-- This file documents the final Production state reached by:
-- 20260919114229 audit_log_forensic_read_model_20260919
-- 20260919114411 audit_log_trigger_identity_fix_20260919
-- 20260919114439 audit_log_query_runtime_fix_20260919
-- 20260919114559 audit_log_forensic_redaction_20260919

BEGIN;

ALTER TABLE public.audit_log
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS actor_user_id uuid,
  ADD COLUMN IF NOT EXISTS source_type text,
  ADD COLUMN IF NOT EXISTS operation_id text;

CREATE INDEX IF NOT EXISTS idx_audit_log_company_created
  ON public.audit_log (company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor_created
  ON public.audit_log (actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record_created
  ON public.audit_log (table_name, record_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_operation_created
  ON public.audit_log (operation_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.audit_log_redact_jsonb(p_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $function$
DECLARE
  v_out jsonb := NULL;
  v_key text;
  v_value jsonb;
BEGIN
  IF p_payload IS NULL THEN RETURN NULL; END IF;

  IF jsonb_typeof(p_payload) = 'object' THEN
    v_out := '{}'::jsonb;
    FOR v_key, v_value IN SELECT key, value FROM jsonb_each(p_payload) LOOP
      IF v_key ~* '(password|token|secret|authorization|api[_-]?key|access[_-]?key|refresh[_-]?token)' THEN
        v_out := v_out || jsonb_build_object(v_key, '[REDACTED]');
      ELSE
        v_out := v_out || jsonb_build_object(v_key, public.audit_log_redact_jsonb(v_value));
      END IF;
    END LOOP;
    RETURN v_out;
  ELSIF jsonb_typeof(p_payload) = 'array' THEN
    SELECT COALESCE(jsonb_agg(public.audit_log_redact_jsonb(value)), '[]'::jsonb)
      INTO v_out
    FROM jsonb_array_elements(p_payload);
    RETURN v_out;
  END IF;

  RETURN p_payload;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_audit_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor_user_id uuid;
  v_actor_email text;
  v_actor_company_id uuid;
  v_company_id uuid;
  v_action text;
  v_old_data jsonb;
  v_new_data jsonb;
  v_record_id text;
  v_operation_id text;
BEGIN
  v_actor_user_id := auth.uid();

  CASE TG_OP
    WHEN 'INSERT' THEN
      v_action := 'create';
      v_old_data := NULL;
      v_new_data := to_jsonb(NEW);
      v_record_id := NEW.id::text;
    WHEN 'UPDATE' THEN
      v_action := 'update';
      v_old_data := to_jsonb(OLD);
      v_new_data := to_jsonb(NEW);
      v_record_id := OLD.id::text;
    WHEN 'DELETE' THEN
      v_action := 'delete';
      v_old_data := to_jsonb(OLD);
      v_new_data := NULL;
      v_record_id := OLD.id::text;
  END CASE;

  v_operation_id := COALESCE(
    NULLIF(v_new_data->>'operation_id', ''),
    NULLIF(v_old_data->>'operation_id', '')
  );

  BEGIN
    v_company_id := COALESCE(
      CASE
        WHEN COALESCE(v_new_data->>'company_id', '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (v_new_data->>'company_id')::uuid
        ELSE NULL
      END,
      CASE
        WHEN COALESCE(v_old_data->>'company_id', '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (v_old_data->>'company_id')::uuid
        ELSE NULL
      END
    );
  EXCEPTION WHEN OTHERS THEN
    v_company_id := NULL;
  END;

  IF v_actor_user_id IS NOT NULL THEN
    SELECT u.email, u.company_id
      INTO v_actor_email, v_actor_company_id
    FROM public.users u
    WHERE u.auth_id = v_actor_user_id
      AND COALESCE(u.status, 'Active') <> 'Inactive'
    ORDER BY u.id
    LIMIT 1;

    v_company_id := COALESCE(v_company_id, v_actor_company_id);
  END IF;

  v_actor_email := COALESCE(
    NULLIF(v_actor_email, ''),
    NULLIF(current_setting('request.jwt.claim.email', true), ''),
    NULLIF((NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email'), ''),
    CASE WHEN v_actor_user_id IS NULL THEN 'system' ELSE NULL END
  );

  INSERT INTO public.audit_log (
    user_email, action, table_name, record_id, old_data, new_data,
    actor_user_id, company_id, source_type, operation_id
  ) VALUES (
    v_actor_email, v_action, TG_TABLE_NAME, v_record_id, v_old_data, v_new_data,
    v_actor_user_id, v_company_id, 'database_trigger', v_operation_id
  );

  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.audit_log_query(
  p_search text DEFAULT NULL,
  p_action text DEFAULT NULL,
  p_table_name text DEFAULT NULL,
  p_actor_email text DEFAULT NULL,
  p_record_id text DEFAULT NULL,
  p_company_id uuid DEFAULT NULL,
  p_from timestamptz DEFAULT NULL,
  p_to timestamptz DEFAULT NULL,
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public, app_private'
AS $function$
DECLARE
  v_page integer := GREATEST(COALESCE(p_page, 1), 1);
  v_page_size integer := LEAST(GREATEST(COALESCE(p_page_size, 50), 1), 5000);
  v_offset bigint;
  v_total integer;
  v_rows jsonb;
  v_summary jsonb;
  v_trust_summary jsonb;
BEGIN
  IF NOT app_private.current_user_has_permission('owner') THEN
    RAISE EXCEPTION 'OWNER_REQUIRED';
  END IF;

  v_offset := (v_page - 1)::bigint * v_page_size;

  SELECT count(*)::integer INTO v_total
  FROM public.audit_log a
  LEFT JOIN public.users u ON u.id = a.actor_user_id
  WHERE
    (NULLIF(btrim(p_search), '') IS NULL
      OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.table_name,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.record_id,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.operation_id,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.old_data::text,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.new_data::text,'') ILIKE '%'||btrim(p_search)||'%')
    AND (NULLIF(btrim(p_action),'') IS NULL OR a.action=btrim(p_action))
    AND (NULLIF(btrim(p_table_name),'') IS NULL OR a.table_name=btrim(p_table_name))
    AND (NULLIF(btrim(p_actor_email),'') IS NULL OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_actor_email)||'%')
    AND (NULLIF(btrim(p_record_id),'') IS NULL OR coalesce(a.record_id,'')=btrim(p_record_id))
    AND (p_company_id IS NULL OR a.company_id=p_company_id)
    AND (p_from IS NULL OR a.created_at>=p_from)
    AND (p_to IS NULL OR a.created_at<=p_to);

  SELECT COALESCE(jsonb_object_agg(s.action,s.n),'{}'::jsonb)
    INTO v_summary
  FROM (
    SELECT a.action,count(*)::integer n
    FROM public.audit_log a
    LEFT JOIN public.users u ON u.id=a.actor_user_id
    WHERE
      (NULLIF(btrim(p_search),'') IS NULL
        OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.table_name,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.record_id,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.operation_id,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.old_data::text,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.new_data::text,'') ILIKE '%'||btrim(p_search)||'%')
      AND (NULLIF(btrim(p_action),'') IS NULL OR a.action=btrim(p_action))
      AND (NULLIF(btrim(p_table_name),'') IS NULL OR a.table_name=btrim(p_table_name))
      AND (NULLIF(btrim(p_actor_email),'') IS NULL OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_actor_email)||'%')
      AND (NULLIF(btrim(p_record_id),'') IS NULL OR coalesce(a.record_id,'')=btrim(p_record_id))
      AND (p_company_id IS NULL OR a.company_id=p_company_id)
      AND (p_from IS NULL OR a.created_at>=p_from)
      AND (p_to IS NULL OR a.created_at<=p_to)
    GROUP BY a.action
  ) s;

  SELECT jsonb_build_object(
    'verified',count(*) FILTER (WHERE a.actor_user_id IS NOT NULL),
    'system',count(*) FILTER (WHERE a.user_email='system' AND a.actor_user_id IS NULL),
    'unverified',count(*) FILTER (WHERE a.user_email='anonymous' AND a.actor_user_id IS NULL),
    'legacy',count(*) FILTER (
      WHERE a.actor_user_id IS NULL
        AND a.user_email IS DISTINCT FROM 'system'
        AND a.user_email IS DISTINCT FROM 'anonymous')
  ) INTO v_trust_summary
  FROM public.audit_log a
  LEFT JOIN public.users u ON u.id=a.actor_user_id
  WHERE
    (NULLIF(btrim(p_search),'') IS NULL
      OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.table_name,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.record_id,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.operation_id,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.old_data::text,'') ILIKE '%'||btrim(p_search)||'%'
      OR coalesce(a.new_data::text,'') ILIKE '%'||btrim(p_search)||'%')
    AND (NULLIF(btrim(p_action),'') IS NULL OR a.action=btrim(p_action))
    AND (NULLIF(btrim(p_table_name),'') IS NULL OR a.table_name=btrim(p_table_name))
    AND (NULLIF(btrim(p_actor_email),'') IS NULL OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_actor_email)||'%')
    AND (NULLIF(btrim(p_record_id),'') IS NULL OR coalesce(a.record_id,'')=btrim(p_record_id))
    AND (p_company_id IS NULL OR a.company_id=p_company_id)
    AND (p_from IS NULL OR a.created_at>=p_from)
    AND (p_to IS NULL OR a.created_at<=p_to);

  SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.occurred_at DESC,x.id DESC),'[]'::jsonb)
    INTO v_rows
  FROM (
    SELECT
      a.id,a.created_at occurred_at,
      coalesce(NULLIF(a.user_email,'system'),u.email,a.user_email) actor_email,
      a.actor_user_id,a.action,a.table_name,a.record_id,a.company_id,
      c.name company_name,COALESCE(a.source_type,'legacy') source_type,
      a.operation_id,a.ip_address,
      CASE
        WHEN a.actor_user_id IS NOT NULL THEN 'verified'
        WHEN a.user_email='anonymous' THEN 'unverified'
        WHEN a.user_email='system' AND a.source_type='database_trigger' THEN 'system'
        ELSE 'legacy'
      END actor_trust,
      (
        SELECT COALESCE(jsonb_agg(k ORDER BY k),'[]'::jsonb)
        FROM (
          SELECT key k FROM jsonb_each(CASE WHEN jsonb_typeof(a.old_data)='object' THEN a.old_data ELSE '{}'::jsonb END)
          UNION
          SELECT key k FROM jsonb_each(CASE WHEN jsonb_typeof(a.new_data)='object' THEN a.new_data ELSE '{}'::jsonb END)
        ) keys
        WHERE (a.old_data->k) IS DISTINCT FROM (a.new_data->k)
      ) changed_fields
    FROM public.audit_log a
    LEFT JOIN public.users u ON u.id=a.actor_user_id
    LEFT JOIN public.companies c ON c.id=a.company_id
    WHERE
      (NULLIF(btrim(p_search),'') IS NULL
        OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.table_name,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.record_id,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.operation_id,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.old_data::text,'') ILIKE '%'||btrim(p_search)||'%'
        OR coalesce(a.new_data::text,'') ILIKE '%'||btrim(p_search)||'%')
      AND (NULLIF(btrim(p_action),'') IS NULL OR a.action=btrim(p_action))
      AND (NULLIF(btrim(p_table_name),'') IS NULL OR a.table_name=btrim(p_table_name))
      AND (NULLIF(btrim(p_actor_email),'') IS NULL OR coalesce(NULLIF(a.user_email,'system'),u.email,'') ILIKE '%'||btrim(p_actor_email)||'%')
      AND (NULLIF(btrim(p_record_id),'') IS NULL OR coalesce(a.record_id,'')=btrim(p_record_id))
      AND (p_company_id IS NULL OR a.company_id=p_company_id)
      AND (p_from IS NULL OR a.created_at>=p_from)
      AND (p_to IS NULL OR a.created_at<=p_to)
    ORDER BY a.created_at DESC,a.id DESC
    OFFSET v_offset LIMIT v_page_size
  ) x;

  RETURN jsonb_build_object(
    'success',true,'page',v_page,'page_size',v_page_size,
    'total',v_total,'summary',v_summary,'trust_summary',v_trust_summary,'rows',v_rows
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.audit_log_detail(p_audit_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public, app_private'
AS $function$
DECLARE v_row jsonb;
BEGIN
  IF NOT app_private.current_user_has_permission('owner') THEN
    RAISE EXCEPTION 'OWNER_REQUIRED';
  END IF;

  SELECT to_jsonb(x) INTO v_row
  FROM (
    SELECT
      a.id,a.created_at occurred_at,
      coalesce(NULLIF(a.user_email,'system'),u.email,a.user_email) actor_email,
      a.actor_user_id,a.action,a.table_name,a.record_id,a.company_id,
      c.name company_name,COALESCE(a.source_type,'legacy') source_type,
      a.operation_id,a.ip_address,a.user_agent,
      public.audit_log_redact_jsonb(a.old_data) old_data,
      public.audit_log_redact_jsonb(a.new_data) new_data,
      CASE
        WHEN a.actor_user_id IS NOT NULL THEN 'verified'
        WHEN a.user_email='anonymous' THEN 'unverified'
        WHEN a.user_email='system' AND a.source_type='database_trigger' THEN 'system'
        ELSE 'legacy'
      END actor_trust
    FROM public.audit_log a
    LEFT JOIN public.users u ON u.id=a.actor_user_id
    LEFT JOIN public.companies c ON c.id=a.company_id
    WHERE a.id=p_audit_id
  ) x;

  IF v_row IS NULL THEN RAISE EXCEPTION 'AUDIT_RECORD_NOT_FOUND'; END IF;

  RETURN jsonb_build_object('success',true,'row',v_row);
END;
$function$;

REVOKE ALL ON FUNCTION public.audit_log_query(text,text,text,text,text,uuid,timestamptz,timestamptz,integer,integer)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.audit_log_query(text,text,text,text,text,uuid,timestamptz,timestamptz,integer,integer)
  TO authenticated;

REVOKE ALL ON FUNCTION public.audit_log_detail(uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.audit_log_detail(uuid)
  TO authenticated;

REVOKE ALL ON public.audit_log FROM PUBLIC,anon,authenticated,service_role;
GRANT SELECT ON public.audit_log TO authenticated;
GRANT INSERT ON public.audit_log TO service_role;

COMMIT;
