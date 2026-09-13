BEGIN;

CREATE TABLE IF NOT EXISTS public.sales_return_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  credit_note_id uuid NOT NULL REFERENCES public.credit_notes(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','reviewing','resolved','disputed','cancelled')),
  assigned_to uuid NULL REFERENCES public.users(id) ON DELETE SET NULL,
  note text NULL,
  resolution text NULL,
  created_by text NOT NULL,
  reviewed_by text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz NULL,
  CONSTRAINT sales_return_reviews_company_credit_note_uq UNIQUE (company_id, credit_note_id)
);

CREATE TABLE IF NOT EXISTS public.sales_return_review_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  review_id uuid NOT NULL REFERENCES public.sales_return_reviews(id) ON DELETE CASCADE,
  action text NOT NULL,
  from_status text NULL,
  to_status text NULL,
  assigned_to uuid NULL REFERENCES public.users(id) ON DELETE SET NULL,
  note text NULL,
  resolution text NULL,
  actor_email text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS sales_return_reviews_company_status_updated_idx
  ON public.sales_return_reviews(company_id, status, updated_at DESC);
CREATE INDEX IF NOT EXISTS sales_return_reviews_company_cn_idx
  ON public.sales_return_reviews(company_id, credit_note_id);
CREATE INDEX IF NOT EXISTS sales_return_review_events_review_created_idx
  ON public.sales_return_review_events(review_id, created_at DESC);

ALTER TABLE public.sales_return_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_return_review_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.sales_return_reviews FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.sales_return_review_events FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.sales_return_reviews TO service_role;
GRANT SELECT, INSERT ON TABLE public.sales_return_review_events TO service_role;

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

CREATE OR REPLACE FUNCTION public.list_sales_return_management(
  p_company_id uuid,
  p_from_date date DEFAULT NULL,
  p_to_date date DEFAULT NULL,
  p_review_status text DEFAULT NULL,
  p_source_type text DEFAULT NULL,
  p_query text DEFAULT NULL,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0,
  p_actor_email text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_ok boolean; v_limit integer := LEAST(GREATEST(COALESCE(p_limit,50),1),200); v_offset integer := GREATEST(COALESCE(p_offset,0),0); v_rows jsonb;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.users u WHERE lower(u.email)=lower(COALESCE(p_actor_email,'')) AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active' AND (COALESCE(u.permissions,'[]'::jsonb) @> '["*"]'::jsonb OR COALESCE(u.permissions,'[]'::jsonb) @> '["return"]'::jsonb)) INTO v_ok;
  IF NOT v_ok THEN RAISE EXCEPTION 'غير مصرح بإدارة المرتجعات'; END IF;
  SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.cn_date DESC,x.cn_code DESC),'[]'::jsonb) INTO v_rows
  FROM (
    SELECT cn.id credit_note_id,cn.cn_code,cn.cn_date,cn.status credit_note_status,cn.total_amount,cn.reason,cn.created_by credit_note_created_by,cn.created_at credit_note_created_at,cn.customer_id,cn.customer_name,
      CASE WHEN cn.runsheet_id IS NOT NULL THEN 'RUNSHEET' WHEN cn.order_id IS NOT NULL THEN 'ORDER' ELSE 'UNKNOWN' END source_type,
      o.order_code,rs.runsheet_code,o.branch_id,b.name branch_name,
      COALESCE(rv.status,'open') review_status,rv.id review_id,rv.assigned_to,au.name assigned_to_name,au.email assigned_to_email,rv.note review_note,rv.resolution,rv.created_by review_created_by,rv.reviewed_by,rv.created_at review_created_at,rv.updated_at review_updated_at,rv.reviewed_at,
      CASE WHEN cn.order_id IS NOT NULL THEN COALESCE(oda.returned_qty,0) ELSE COALESCE(rsa.returned_qty,0) END returned_qty,
      CASE WHEN cn.order_id IS NOT NULL THEN COALESCE(oda.returned_value,0) ELSE COALESCE(rsa.returned_value,0) END returned_value,
      COALESCE(rsa.good_qty,0) good_qty,COALESCE(rsa.damaged_qty,0) damaged_qty,COALESCE(rsa.missing_qty,0) missing_qty,COALESCE(rsa.driver_liability,0) driver_liability,
      CASE WHEN cn.runsheet_id IS NOT NULL THEN COALESCE(il.physical_return_qty,0) ELSE COALESCE(ilo.physical_return_qty,0) END physical_return_qty,
      CASE WHEN cn.runsheet_id IS NOT NULL THEN COALESCE(il.physical_return_count,0) ELSE COALESCE(ilo.physical_return_count,0) END physical_return_count
    FROM public.credit_notes cn
    LEFT JOIN public.orders o ON o.id=cn.order_id AND o.company_id=cn.company_id
    LEFT JOIN public.runsheets rs ON rs.id=cn.runsheet_id AND rs.company_id=cn.company_id
    LEFT JOIN public.branches b ON b.id=o.branch_id AND b.company_id=cn.company_id
    LEFT JOIN public.sales_return_reviews rv ON rv.credit_note_id=cn.id AND rv.company_id=cn.company_id
    LEFT JOIN public.users au ON au.id=rv.assigned_to AND au.company_id=cn.company_id
    LEFT JOIN LATERAL (SELECT COALESCE(SUM(od.qty_returned),0) returned_qty,COALESCE(SUM(od.qty_returned*od.unit_price),0) returned_value FROM public.order_details od WHERE od.order_id=cn.order_id AND COALESCE(od.qty_returned,0)>0) oda ON TRUE
    LEFT JOIN LATERAL (SELECT COALESCE(SUM(sd.qty_returned),0) returned_qty,COALESCE(SUM(sd.qty_returned*sd.unit_price),0) returned_value,COALESCE(SUM(CASE WHEN sd.return_condition='good' THEN sd.qty_returned ELSE 0 END),0) good_qty,COALESCE(SUM(CASE WHEN sd.return_condition='damaged' THEN sd.qty_returned ELSE 0 END),0) damaged_qty,COALESCE(SUM(CASE WHEN sd.return_condition='missing' THEN sd.qty_returned ELSE 0 END),0) missing_qty,COALESCE(SUM(sd.driver_liability),0) driver_liability FROM public.run_sheet_details sd WHERE sd.runsheet_id=cn.runsheet_id AND COALESCE(sd.qty_returned,0)>0) rsa ON TRUE
    LEFT JOIN LATERAL (SELECT COUNT(*) physical_return_count,COALESCE(SUM(il.qty),0) physical_return_qty FROM public.inventory_log il WHERE il.company_id=cn.company_id AND il.movement_type='Return' AND il.reference=rs.runsheet_code) il ON TRUE
    LEFT JOIN LATERAL (SELECT COUNT(*) physical_return_count,COALESCE(SUM(il.qty),0) physical_return_qty FROM public.inventory_log il WHERE il.company_id=cn.company_id AND il.movement_type='Return' AND il.reference=o.order_code) ilo ON TRUE
    WHERE cn.company_id=p_company_id
      AND (p_from_date IS NULL OR cn.cn_date>=p_from_date)
      AND (p_to_date IS NULL OR cn.cn_date<=p_to_date)
      AND (p_review_status IS NULL OR COALESCE(rv.status,'open')=p_review_status)
      AND (p_source_type IS NULL OR CASE WHEN cn.runsheet_id IS NOT NULL THEN 'RUNSHEET' WHEN cn.order_id IS NOT NULL THEN 'ORDER' ELSE 'UNKNOWN' END=p_source_type)
      AND (NULLIF(btrim(p_query),'') IS NULL OR cn.cn_code ILIKE '%'||p_query||'%' OR COALESCE(o.order_code,'') ILIKE '%'||p_query||'%' OR COALESCE(rs.runsheet_code,'') ILIKE '%'||p_query||'%' OR COALESCE(cn.customer_name,'') ILIKE '%'||p_query||'%')
    ORDER BY cn.cn_date DESC,cn.cn_code DESC LIMIT v_limit OFFSET v_offset
  ) x;
  RETURN jsonb_build_object('success',true,'rows',v_rows,'limit',v_limit,'offset',v_offset);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_sales_return_management_detail(p_company_id uuid,p_credit_note_id uuid,p_actor_email text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_ok boolean; v_header jsonb; v_lines jsonb; v_events jsonb;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.users u WHERE lower(u.email)=lower(COALESCE(p_actor_email,'')) AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active' AND (COALESCE(u.permissions,'[]'::jsonb) @> '["*"]'::jsonb OR COALESCE(u.permissions,'[]'::jsonb) @> '["return"]'::jsonb)) INTO v_ok;
  IF NOT v_ok THEN RAISE EXCEPTION 'غير مصرح بإدارة المرتجعات'; END IF;
  SELECT to_jsonb(x) INTO v_header FROM (SELECT cn.id credit_note_id,cn.cn_code,cn.cn_date,cn.status credit_note_status,cn.total_amount,cn.reason,cn.created_by,cn.created_at,cn.customer_id,cn.customer_name,CASE WHEN cn.runsheet_id IS NOT NULL THEN 'RUNSHEET' WHEN cn.order_id IS NOT NULL THEN 'ORDER' ELSE 'UNKNOWN' END source_type,o.order_code,rs.runsheet_code,o.branch_id,b.name branch_name,COALESCE(rv.status,'open') review_status,rv.id review_id,rv.assigned_to,au.name assigned_to_name,au.email assigned_to_email,rv.note review_note,rv.resolution,rv.created_by review_created_by,rv.reviewed_by,rv.created_at review_created_at,rv.updated_at review_updated_at,rv.reviewed_at FROM public.credit_notes cn LEFT JOIN public.orders o ON o.id=cn.order_id AND o.company_id=cn.company_id LEFT JOIN public.runsheets rs ON rs.id=cn.runsheet_id AND rs.company_id=cn.company_id LEFT JOIN public.branches b ON b.id=o.branch_id AND b.company_id=cn.company_id LEFT JOIN public.sales_return_reviews rv ON rv.credit_note_id=cn.id AND rv.company_id=cn.company_id LEFT JOIN public.users au ON au.id=rv.assigned_to AND au.company_id=cn.company_id WHERE cn.id=p_credit_note_id AND cn.company_id=p_company_id) x;
  IF v_header IS NULL THEN RAISE EXCEPTION 'مستند المرتجع غير موجود'; END IF;
  SELECT COALESCE(jsonb_agg(to_jsonb(l) ORDER BY l.item_code),'[]'::jsonb) INTO v_lines FROM (SELECT od.item_id,od.item_code,od.item_name,od.unit,od.unit_price,od.qty original_qty,od.qty_returned,od.qty_delivered,od.reason_return,NULL::text return_condition,od.driver_liability FROM public.order_details od JOIN public.credit_notes cn ON cn.order_id=od.order_id AND cn.company_id=p_company_id WHERE cn.id=p_credit_note_id AND COALESCE(od.qty_returned,0)>0 UNION ALL SELECT sd.item_id,sd.item_code,sd.item_name,sd.unit,sd.unit_price,sd.qty_ordered original_qty,sd.qty_returned,NULL::numeric qty_delivered,NULL::text reason_return,sd.return_condition,sd.driver_liability FROM public.run_sheet_details sd JOIN public.credit_notes cn ON cn.runsheet_id=sd.runsheet_id AND cn.company_id=p_company_id WHERE cn.id=p_credit_note_id AND COALESCE(sd.qty_returned,0)>0) l;
  SELECT COALESCE(jsonb_agg(to_jsonb(e) ORDER BY e.created_at DESC),'[]'::jsonb) INTO v_events FROM public.sales_return_review_events e JOIN public.sales_return_reviews rv ON rv.id=e.review_id AND rv.company_id=p_company_id WHERE rv.credit_note_id=p_credit_note_id;
  RETURN jsonb_build_object('success',true,'header',v_header,'lines',v_lines,'events',v_events);
END;
$function$;

CREATE OR REPLACE FUNCTION public.save_sales_return_review(p_company_id uuid,p_credit_note_id uuid,p_status text,p_assigned_to uuid DEFAULT NULL,p_note text DEFAULT NULL,p_resolution text DEFAULT NULL,p_actor_email text DEFAULT NULL) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE v_ok boolean; v_old public.sales_return_reviews%ROWTYPE; v_new public.sales_return_reviews%ROWTYPE; v_action text; v_reviewed_at timestamptz;
BEGIN
  IF p_status NOT IN ('open','reviewing','resolved','disputed','cancelled') THEN RAISE EXCEPTION 'حالة مراجعة غير مدعومة'; END IF;
  SELECT EXISTS(SELECT 1 FROM public.users u WHERE lower(u.email)=lower(COALESCE(p_actor_email,'')) AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active' AND (COALESCE(u.permissions,'[]'::jsonb) @> '["*"]'::jsonb OR COALESCE(u.permissions,'[]'::jsonb) @> '["return"]'::jsonb)) INTO v_ok;
  IF NOT v_ok THEN RAISE EXCEPTION 'غير مصرح بإدارة المرتجعات'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.credit_notes cn WHERE cn.id=p_credit_note_id AND cn.company_id=p_company_id) THEN RAISE EXCEPTION 'مستند المرتجع غير موجود'; END IF;
  IF p_assigned_to IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=p_assigned_to AND u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active') THEN RAISE EXCEPTION 'المستخدم المكلف غير صالح للشركة'; END IF;
  SELECT * INTO v_old FROM public.sales_return_reviews WHERE company_id=p_company_id AND credit_note_id=p_credit_note_id FOR UPDATE;
  v_reviewed_at:=CASE WHEN p_status IN ('resolved','disputed','cancelled') THEN now() ELSE NULL END;
  IF FOUND THEN UPDATE public.sales_return_reviews SET status=p_status,assigned_to=p_assigned_to,note=p_note,resolution=p_resolution,reviewed_by=p_actor_email,updated_at=now(),reviewed_at=v_reviewed_at WHERE id=v_old.id RETURNING * INTO v_new; v_action:='update';
  ELSE INSERT INTO public.sales_return_reviews(company_id,credit_note_id,status,assigned_to,note,resolution,created_by,reviewed_by,reviewed_at) VALUES(p_company_id,p_credit_note_id,p_status,p_assigned_to,p_note,p_resolution,p_actor_email,CASE WHEN p_status IN ('resolved','disputed','cancelled') THEN p_actor_email ELSE NULL END,v_reviewed_at) RETURNING * INTO v_new; v_action:='create'; END IF;
  INSERT INTO public.sales_return_review_events(company_id,review_id,action,from_status,to_status,assigned_to,note,resolution,actor_email) VALUES(p_company_id,v_new.id,v_action,CASE WHEN v_old.id IS NULL THEN NULL ELSE v_old.status END,v_new.status,v_new.assigned_to,p_note,p_resolution,p_actor_email);
  RETURN jsonb_build_object('success',true,'review',to_jsonb(v_new));
END;
$function$;

REVOKE ALL ON FUNCTION public.get_sales_return_management_summary(uuid,date,date,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.list_sales_return_management(uuid,date,date,text,text,text,integer,integer,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_sales_return_management_detail(uuid,uuid,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.save_sales_return_review(uuid,uuid,text,uuid,text,text,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_sales_return_management_summary(uuid,date,date,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.list_sales_return_management(uuid,date,date,text,text,text,integer,integer,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_sales_return_management_detail(uuid,uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.save_sales_return_review(uuid,uuid,text,uuid,text,text,text) TO service_role;

COMMIT;
