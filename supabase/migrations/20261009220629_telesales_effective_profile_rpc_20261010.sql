CREATE OR REPLACE FUNCTION public.get_my_effective_profile()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT jsonb_build_object(
    'id', u.id,
    'auth_id', u.auth_id,
    'company_id', u.company_id,
    'email', COALESCE(u.email, au.email),
    'name', COALESCE(NULLIF(u.name, ''), NULLIF(au.raw_user_meta_data->>'name', ''), au.email),
    'role', COALESCE(NULLIF(u.role, ''), 'موظف'),
    'status', COALESCE(u.status, 'Active'),
    'active_warehouse_role', u.active_warehouse_role,
    'default_branch_id', u.default_branch_id,
    'allowed_branch_ids', u.allowed_branch_ids,
    'permissions',
      COALESCE((
        SELECT jsonb_agg(to_jsonb(effective.permission) ORDER BY effective.permission)
        FROM (
          SELECT DISTINCT btrim(source.permission) AS permission
          FROM (
            SELECT jsonb_array_elements_text(
              CASE WHEN jsonb_typeof(u.permissions) = 'array'
                   THEN u.permissions ELSE '[]'::jsonb END
            ) AS permission
            UNION ALL
            SELECT jsonb_array_elements_text(
              CASE WHEN jsonb_typeof(r.permissions) = 'array'
                   THEN r.permissions ELSE '[]'::jsonb END
            ) AS permission
            UNION ALL
            SELECT rp.permission_key AS permission
            FROM public.role_permissions rp
            WHERE rp.role_id = u.role_id
          ) source
          WHERE NULLIF(btrim(source.permission), '') IS NOT NULL
        ) effective
      ), '[]'::jsonb),
    'isOwner',
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
  )
  FROM public.users u
  LEFT JOIN public.roles r
    ON r.id = u.role_id
   AND r.company_id = u.company_id
  LEFT JOIN auth.users au
    ON au.id = u.auth_id
  WHERE auth.uid() IS NOT NULL
    AND u.auth_id = auth.uid()
    AND u.status IS DISTINCT FROM 'Inactive'
  LIMIT 1;
$function$;

REVOKE ALL ON FUNCTION public.get_my_effective_profile() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_effective_profile() FROM anon;
REVOKE ALL ON FUNCTION public.get_my_effective_profile() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_effective_profile() TO authenticated;

COMMENT ON FUNCTION public.get_my_effective_profile() IS
'Returns only the authenticated caller profile with merged direct and role permissions; never accepts a caller-supplied user id.';
