BEGIN;

CREATE OR REPLACE FUNCTION public.get_sales_return_management_summary(
  p_company_id uuid,
  p_from_date date DEFAULT NULL,
  p_to_date date DEFAULT NULL,
  p_actor_email text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_ok boolean; v_kpi record;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.users u WHERE lower(u.email)=lower(COALESCE(p_actor_email,'')) AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active' AND (COALESCE(u.permissions,'[]'::jsonb) @> '["*"]'::jsonb OR COALESCE(u.permissions,'[]'::jsonb) @> '["return"]'::jsonb)) INTO v_ok;
  IF NOT v_ok THEN RAISE EXCEPTION 'غير مصرح بإدارة المرتجعات'; END IF;
  SELECT COUNT(*) FILTER (WHERE COALESCE(rv.status,'open')='open') open_count,
         COUNT(*) FILTER (WHERE rv.status='reviewing') reviewing_count,
         COUNT(*) FILTER (WHERE rv.status='resolved') resolved_count,
         COUNT(*) FILTER (WHERE rv.status='disputed') disputed_count,
         COUNT(*) FILTER (WHERE rv.status='cancelled') cancelled_count,
         COUNT(*) total_count,
         COALESCE(SUM(cn.total_amount),0) total_value,
         COALESCE(SUM(CASE WHEN cn.status='Posted' THEN cn.total_amount ELSE 0 END),0) posted_value
  INTO v_kpi
  FROM public.credit_notes cn
  LEFT JOIN public.sales_return_reviews rv ON rv.credit_note_id=cn.id AND rv.company_id=cn.company_id
  WHERE cn.company_id=p_company_id AND (p_from_date IS NULL OR cn.cn_date>=p_from_date) AND (p_to_date IS NULL OR cn.cn_date<=p_to_date);
  RETURN jsonb_build_object('success',true,'kpi',jsonb_build_object('total',v_kpi.total_count,'open',v_kpi.open_count,'reviewing',v_kpi.reviewing_count,'resolved',v_kpi.resolved_count,'disputed',v_kpi.disputed_count,'cancelled',v_kpi.cancelled_count,'total_value',v_kpi.total_value,'posted_value',v_kpi.posted_value));
END;
$function$;

COMMIT;
