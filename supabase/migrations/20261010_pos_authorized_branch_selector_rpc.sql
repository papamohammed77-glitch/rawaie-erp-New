-- POS branch selector: authenticated, company-scoped, user-allowed branches only.
-- Does not change branches RLS and does not create an Edge Function.
CREATE OR REPLACE FUNCTION public.get_pos_branches()
RETURNS TABLE (
  id uuid,
  company_id uuid,
  branch_code character varying,
  name character varying,
  location text,
  manager character varying,
  phone character varying,
  is_active boolean,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_company_id uuid;
  v_default_branch_id uuid;
  v_allowed_branch_ids jsonb;
  v_is_owner boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT
    u.company_id,
    u.default_branch_id,
    u.allowed_branch_ids,
    (
      COALESCE(au.raw_user_meta_data->>'isOwner', 'false') = 'true'
      AND jsonb_typeof(u.permissions) = 'array'
      AND u.permissions ? '*'
      AND EXISTS (
        SELECT 1
        FROM public.owner_profile op
        WHERE op.auth_user_id = auth.uid()
      )
    )
  INTO v_company_id, v_default_branch_id, v_allowed_branch_ids, v_is_owner
  FROM public.users u
  LEFT JOIN auth.users au ON au.id = u.auth_id
  WHERE u.auth_id = auth.uid()
    AND u.status IS DISTINCT FROM 'Inactive'
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'active company profile not found' USING ERRCODE = '42501';
  END IF;

  IF NOT app_private.current_user_has_permission('pos') THEN
    RAISE EXCEPTION 'POS permission required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    b.id, b.company_id, b.branch_code, b.name, b.location, b.manager,
    b.phone, b.is_active, b.created_at, b.updated_at
  FROM public.branches b
  WHERE b.company_id = v_company_id
    AND b.is_active IS TRUE
    AND (
      v_is_owner
      OR b.id = v_default_branch_id
      OR (
        jsonb_typeof(v_allowed_branch_ids) = 'array'
        AND EXISTS (
          SELECT 1
          FROM jsonb_array_elements_text(v_allowed_branch_ids) allowed(value)
          WHERE allowed.value = b.id::text
             OR allowed.value = b.branch_code
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
  ORDER BY
    CASE WHEN b.id = v_default_branch_id THEN 0 ELSE 1 END,
    b.name,
    b.branch_code;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_pos_branches() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_pos_branches() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_pos_branches() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pos_branches() TO service_role;
