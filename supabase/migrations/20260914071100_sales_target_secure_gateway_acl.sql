BEGIN;

CREATE OR REPLACE FUNCTION public.sales_target_engine_gateway(
  p_company_id uuid,
  p_operation text,
  p_user_email text,
  p_plan_id uuid DEFAULT NULL,
  p_payload jsonb DEFAULT '{}'::jsonb,
  p_operation_id text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  actor public.users%ROWTYPE;
  op text := upper(btrim(coalesce(p_operation,'')));
  can_read boolean;
  can_manage boolean;
  can_approve boolean;
BEGIN
  SELECT * INTO actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Authenticated company context invalid';
  END IF;

  can_read := coalesce(actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
           OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_manager"]'::jsonb
           OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_supervisor"]'::jsonb
           OR coalesce(actor.permissions,'[]'::jsonb) @> '["general_manager"]'::jsonb
           OR coalesce(actor.permissions,'[]'::jsonb) @> '["reports"]'::jsonb;

  can_manage := coalesce(actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
             OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_manager"]'::jsonb
             OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_supervisor"]'::jsonb
             OR coalesce(actor.permissions,'[]'::jsonb) @> '["general_manager"]'::jsonb;

  can_approve := coalesce(actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
              OR coalesce(actor.permissions,'[]'::jsonb) @> '["sales_manager"]'::jsonb
              OR coalesce(actor.permissions,'[]'::jsonb) @> '["general_manager"]'::jsonb;

  IF op IN('LIST_PLANS','LIST_ASSIGNMENTS','LIST_RUNS','PREVIEW') AND NOT can_read THEN
    RAISE EXCEPTION 'Sales target read permission required';
  END IF;

  IF op IN('SAVE_PLAN','SAVE_ASSIGNMENT','CANCEL_PLAN') AND NOT can_manage THEN
    RAISE EXCEPTION 'Sales target management permission required';
  END IF;

  IF op IN('APPROVE_PLAN','CLOSE_PLAN','POST','APPROVE_RUN','REVERSE_RUN') AND NOT can_approve THEN
    RAISE EXCEPTION 'Sales target approval permission required';
  END IF;

  RETURN public.sales_target_engine_atomic(
    p_company_id,
    op,
    p_user_email,
    p_plan_id,
    p_payload,
    p_operation_id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)
  TO service_role;

COMMIT;
