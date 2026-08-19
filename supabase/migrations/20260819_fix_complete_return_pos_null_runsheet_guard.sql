DO $$
DECLARE
  v_oid oid;
  v_ddl text;
  v_old text := 'if p_runsheet_code is not null and v_order.runsheet_id is distinct from v_runsheet.id then raise exception ''order is not assigned to the requested runsheet''; end if;';
  v_new text := 'if p_runsheet_code is not null then if v_order.runsheet_id is distinct from v_runsheet.id then raise exception ''order is not assigned to the requested runsheet''; end if; end if;';
  v_count integer;
BEGIN
  SELECT p.oid INTO v_oid
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='complete_return_atomic'
    AND pg_get_function_identity_arguments(p.oid)='p_company_id uuid, p_runsheet_code text, p_order_code text, p_is_pos_return boolean, p_user_email text, p_items jsonb';

  IF v_oid IS NULL THEN
    RAISE EXCEPTION 'complete_return_atomic target signature not found';
  END IF;

  v_ddl := pg_get_functiondef(v_oid);
  v_count := length(v_ddl)-length(replace(v_ddl,v_old,''));
  IF v_count <> length(v_old) THEN
    RAISE EXCEPTION 'target guard text not found exactly once';
  END IF;

  v_ddl := replace(v_ddl,v_old,v_new);
  EXECUTE v_ddl;
END $$;
