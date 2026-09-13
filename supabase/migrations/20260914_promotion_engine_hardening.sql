BEGIN;
ALTER TABLE public.promotions ADD COLUMN IF NOT EXISTS operation_id text;
CREATE UNIQUE INDEX IF NOT EXISTS promotions_company_operation_uq ON public.promotions(company_id, operation_id) WHERE operation_id IS NOT NULL;
ALTER TABLE public.promotion_rules DROP CONSTRAINT IF EXISTS promotion_rule_percent_max_chk;
ALTER TABLE public.promotion_rules ADD CONSTRAINT promotion_rule_percent_max_chk CHECK ((reward_type NOT IN ('percent','cheapest_percent')) OR reward_value <= 100);

CREATE OR REPLACE FUNCTION public.set_promotion_active_atomic(p_company_id uuid,p_promotion_id uuid,p_is_active boolean,p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='public' AS $function$
DECLARE v_old public.promotions%ROWTYPE; v_new public.promotions%ROWTYPE;
BEGIN
 SELECT * INTO v_old FROM public.promotions WHERE id=p_promotion_id AND company_id=p_company_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'العرض غير موجود'; END IF;
 UPDATE public.promotions SET is_active=COALESCE(p_is_active,false),updated_at=now() WHERE id=p_promotion_id AND company_id=p_company_id RETURNING * INTO v_new;
 INSERT INTO public.audit_log(user_email,action,table_name,record_id,old_data,new_data) VALUES(p_user_email,'update','promotions',p_promotion_id::text,to_jsonb(v_old),to_jsonb(v_new));
 RETURN jsonb_build_object('success',true,'promotion_id',p_promotion_id,'is_active',v_new.is_active);
END;
$function$;
REVOKE ALL ON FUNCTION public.set_promotion_active_atomic(uuid,uuid,boolean,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.set_promotion_active_atomic(uuid,uuid,boolean,text) TO service_role;
COMMIT;
