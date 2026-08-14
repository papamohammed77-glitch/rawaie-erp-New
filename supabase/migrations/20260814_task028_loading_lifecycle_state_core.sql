BEGIN;

CREATE OR REPLACE FUNCTION public.start_runsheet_loading(
    p_company_id uuid,
    p_runsheet_code text,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_user public.users%ROWTYPE;
    v_active text;
BEGIN
    IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code),'') IS NULL THEN
        RAISE EXCEPTION 'company_id and runsheet_code are required';
    END IF;

    SELECT * INTO v_user
    FROM public.users
    WHERE email=p_user_email AND company_id=p_company_id
    LIMIT 1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'user is not registered in the company context';
    END IF;

    SELECT runsheet_code INTO v_active
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND status='Loading'
      AND loader_id=v_user.id
    LIMIT 1;
    IF v_active IS NOT NULL THEN
        RAISE EXCEPTION 'user already has a Loading runsheet: %',v_active;
    END IF;

    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE company_id=p_company_id
      AND runsheet_code=p_runsheet_code
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.status <> 'Picked' THEN RAISE EXCEPTION 'runsheet is not Picked: %',v_rs.status; END IF;

    UPDATE public.runsheets
    SET status='Loading',loader_id=v_user.id,loader_start=now(),updated_at=now()
    WHERE id=v_rs.id AND status='Picked';
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet transition Picked -> Loading failed'; END IF;

    RETURN jsonb_build_object('success',true,'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,'status','Loading','loader_id',v_user.id);
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_runsheet_loading(
    p_company_id uuid,
    p_runsheet_code text,
    p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
    v_rs public.runsheets%ROWTYPE;
    v_user public.users%ROWTYPE;
BEGIN
    IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code),'') IS NULL THEN
        RAISE EXCEPTION 'company_id and runsheet_code are required';
    END IF;

    SELECT * INTO v_user
    FROM public.users
    WHERE email=p_user_email AND company_id=p_company_id
    LIMIT 1;
    IF NOT FOUND THEN RAISE EXCEPTION 'user is not registered in the company context'; END IF;

    SELECT * INTO v_rs
    FROM public.runsheets
    WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code
    FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
    IF v_rs.status <> 'Loading' THEN RAISE EXCEPTION 'runsheet is not Loading: %',v_rs.status; END IF;
    IF v_rs.loader_id <> v_user.id THEN RAISE EXCEPTION 'runsheet is assigned to another loader'; END IF;

    -- Loading state owns no physical stock yet. Physical reversal belongs to Reopen/Unloading after Loaded.
    UPDATE public.order_details od
    SET qty_loaded=0,updated_at=now()
    FROM public.orders o
    WHERE od.order_id=o.id
      AND o.company_id=p_company_id
      AND o.runsheet_id=v_rs.id
      AND COALESCE(od.qty_loaded,0)>0;

    UPDATE public.runsheets
    SET status='Picked',loader_id=NULL,loader_start=NULL,updated_at=now()
    WHERE id=v_rs.id AND status='Loading';
    IF NOT FOUND THEN RAISE EXCEPTION 'runsheet transition Loading -> Picked failed'; END IF;

    RETURN jsonb_build_object('success',true,'runsheet_id',v_rs.id,'runsheet_code',v_rs.runsheet_code,'status','Picked');
END;
$$;

REVOKE ALL ON FUNCTION public.start_runsheet_loading(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_runsheet_loading(uuid,text,text) TO service_role;
REVOKE ALL ON FUNCTION public.cancel_runsheet_loading(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_runsheet_loading(uuid,text,text) TO service_role;

COMMIT;
