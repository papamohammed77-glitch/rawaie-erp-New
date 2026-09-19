DO $$
DECLARE
  src text;
BEGIN
  SELECT pg_get_functiondef(p.oid)
  INTO src
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='owner_license_admin_atomic'
    AND pg_get_function_identity_arguments(p.oid)='p_action text, p_company_id uuid, p_actor_user_id uuid, p_actor_auth_id uuid, p_actor_email text, p_payload jsonb';

  IF src IS NULL THEN
    RAISE EXCEPTION 'owner_license_admin_atomic definition not found';
  END IF;

  src := replace(
    src,
    $old$
  INSERT INTO public.audit_log(
    user_email,action,table_name,record_id,old_data,new_data
  )
  VALUES(
    p_actor_email,
    CASE WHEN v_old = v_new THEN 'license.noop' ELSE 'license.update' END,
    'company_licenses',
    p_company_id::text,
    v_old,
    v_new
  );

  RETURN public.owner_license_admin_atomic('detail',p_company_id,p_actor_user_id,p_actor_auth_id,p_actor_email,'{}'::jsonb);
$old$,
    $new$
  IF v_old IS DISTINCT FROM v_new THEN
    INSERT INTO public.audit_log(
      user_email,action,table_name,record_id,old_data,new_data
    )
    VALUES(
      p_actor_email,
      'update',
      'company_licenses',
      p_company_id::text,
      v_old,
      v_new
    );
  END IF;

  RETURN public.owner_license_admin_atomic('detail',p_company_id,p_actor_user_id,p_actor_auth_id,p_actor_email,'{}'::jsonb);
$new$
  );

  IF src NOT LIKE '%IF v_old IS DISTINCT FROM v_new THEN%' THEN
    RAISE EXCEPTION 'AUDIT_REWRITE_FAILED';
  END IF;

  EXECUTE src;
END $$;
