BEGIN;

CREATE OR REPLACE FUNCTION public.sales_target_audit_trigger() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  actor text;
  row_new jsonb;
  row_old jsonb;
BEGIN
  row_new:=CASE WHEN TG_OP<>'DELETE' THEN to_jsonb(NEW) ELSE NULL END;
  row_old:=CASE WHEN TG_OP<>'INSERT' THEN to_jsonb(OLD) ELSE NULL END;
  actor:=NULLIF(current_setting('request.jwt.claims',true)::jsonb->>'email','');
  actor:=coalesce(actor,row_new->>'created_by',row_new->>'approved_by',row_new->>'closed_by',row_old->>'created_by',row_old->>'approved_by',row_old->>'closed_by','system');
  IF TG_OP='INSERT' THEN
    INSERT INTO public.audit_log(user_email,action,table_name,record_id,new_data)
    VALUES(actor,'create',TG_TABLE_NAME,NEW.id::text,row_new);
  ELSIF TG_OP='UPDATE' THEN
    INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data,new_data)
    VALUES(actor,'update',TG_TABLE_NAME,OLD.id::text,row_old,row_new);
  ELSE
    INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data)
    VALUES(actor,'delete',TG_TABLE_NAME,OLD.id::text,row_old);
  END IF;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION public.sales_target_audit_trigger() FROM PUBLIC,anon,authenticated;

COMMIT;
