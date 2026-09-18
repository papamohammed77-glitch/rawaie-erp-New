-- RAWAEA ERP — CRM Customer 360 canonical closure
-- Reproducible final Production state for CRM-only closure.
BEGIN;

CREATE INDEX IF NOT EXISTS idx_orders_company_customer_date
  ON public.orders(company_id, customer_id, order_date DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_customer_followups_company_customer_date
  ON public.customer_followups(company_id, customer_id, followup_date DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_customer_ledger_customer_date
  ON public.customer_ledger(customer_id, entry_date DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_customer_assignments_customer_active
  ON public.customer_assignments(customer_id, is_active);

CREATE OR REPLACE FUNCTION public.crm_customer_directory(
  p_search text DEFAULT NULL,
  p_active_only boolean DEFAULT false,
  p_limit integer DEFAULT 100,
  p_offset integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
  v_search text := NULLIF(btrim(coalesce(p_search,'')),'');
  v_limit integer := LEAST(GREATEST(coalesce(p_limit,100),1),200);
  v_offset integer := GREATEST(coalesce(p_offset,0),0);
  v_total integer;
BEGIN
  IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('customers') THEN
    RAISE EXCEPTION 'غير مصرح للوصول إلى CRM';
  END IF;

  SELECT count(*) INTO v_total
  FROM public.customers c
  WHERE c.company_id=v_company_id
    AND (NOT p_active_only OR c.is_active IS DISTINCT FROM false)
    AND (
      v_search IS NULL
      OR c.name ILIKE '%'||v_search||'%'
      OR c.customer_code ILIKE '%'||v_search||'%'
      OR coalesce(c.phone,'') ILIKE '%'||v_search||'%'
      OR coalesce(c.area,'') ILIKE '%'||v_search||'%'
      OR coalesce(c.contact_person,'') ILIKE '%'||v_search||'%'
    );

  RETURN jsonb_build_object(
    'success',true,
    'company_id',v_company_id,
    'total',v_total,
    'kpi',jsonb_build_object(
      'total_customers',(SELECT count(*) FROM public.customers c WHERE c.company_id=v_company_id),
      'active_customers',(SELECT count(*) FROM public.customers c WHERE c.company_id=v_company_id AND c.is_active IS DISTINCT FROM false),
      'master_debt_total',coalesce((SELECT sum(coalesce(c.debt,0)) FROM public.customers c WHERE c.company_id=v_company_id),0),
      'open_followups',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.status IN ('Open','معلقة')),
      'overdue_followups',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.status IN ('Open','معلقة') AND f.followup_date < current_date),
      'due_today',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.status IN ('Open','معلقة') AND f.followup_date = current_date)
    ),
    'assignees',coalesce((
      SELECT jsonb_agg(
        jsonb_build_object('id',u.id,'email',u.email,'name',coalesce(nullif(u.name,''),u.email),'role',u.role)
        ORDER BY coalesce(u.name,u.email),u.email
      )
      FROM public.users u
      WHERE u.company_id=v_company_id
        AND u.status IS DISTINCT FROM 'Inactive'
    ),'[]'::jsonb),
    'customers',coalesce((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id',c.id,'customer_code',c.customer_code,'name',c.name,'search_label',c.search_label,
          'phone',c.phone,'area',c.area,'address',c.address,'location',c.location,
          'customer_type',c.customer_type,'payment_type',c.payment_type,'debt',coalesce(c.debt,0),
          'credit_limit',coalesce(c.credit_limit,0),'loyalty_points',coalesce(c.loyalty_points,0),
          'visit_day',c.visit_day,'contact_person',c.contact_person,'sales_rep',c.sales_rep,
          'is_active',coalesce(c.is_active,true),'location_lat',c.location_lat,'location_lng',c.location_lng,
          'order_count',(SELECT count(*) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=c.id AND o.order_status <> 'Cancelled'),
          'sales_total',coalesce((SELECT sum(coalesce(o.total_amount,0)) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=c.id AND o.order_status <> 'Cancelled'),0),
          'last_order_date',(SELECT max(o.order_date) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=c.id AND o.order_status <> 'Cancelled'),
          'open_followups',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=c.customer_code AND f.status IN ('Open','معلقة')),
          'overdue_followups',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=c.customer_code AND f.status IN ('Open','معلقة') AND f.followup_date < current_date),
          'next_followup_date',(SELECT min(f.followup_date) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=c.customer_code AND f.status IN ('Open','معلقة') AND f.followup_date >= current_date),
          'last_followup_date',(SELECT max(f.followup_date) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=c.customer_code),
          'assigned_to',coalesce((
            SELECT jsonb_agg(
              jsonb_build_object('user_id',u2.id,'email',u2.email,'name',coalesce(nullif(u2.name,''),u2.email),'active',ca.is_active)
              ORDER BY ca.is_active DESC,ca.assigned_at DESC
            )
            FROM public.customer_assignments ca
            JOIN public.users u2 ON u2.id=ca.user_id AND u2.company_id=v_company_id
            WHERE ca.customer_id=c.id
          ),'[]'::jsonb)
        )
        ORDER BY c.name ASC,c.id ASC
      )
      FROM public.customers c
      WHERE c.company_id=v_company_id
        AND (NOT p_active_only OR c.is_active IS DISTINCT FROM false)
        AND (
          v_search IS NULL
          OR c.name ILIKE '%'||v_search||'%'
          OR c.customer_code ILIKE '%'||v_search||'%'
          OR coalesce(c.phone,'') ILIKE '%'||v_search||'%'
          OR coalesce(c.area,'') ILIKE '%'||v_search||'%'
          OR coalesce(c.contact_person,'') ILIKE '%'||v_search||'%'
        )
      OFFSET v_offset LIMIT v_limit
    ),'[]'::jsonb)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.crm_customer_directory(text,boolean,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.crm_customer_directory(text,boolean,integer,integer) TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.crm_customer_360(p_customer_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
  v_customer public.customers%ROWTYPE;
BEGIN
  IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('customers') THEN
    RAISE EXCEPTION 'غير مصرح للوصول إلى CRM';
  END IF;

  SELECT * INTO v_customer
  FROM public.customers c
  WHERE c.id=p_customer_id AND c.company_id=v_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'العميل غير موجود ضمن الشركة الحالية'; END IF;

  RETURN jsonb_build_object(
    'success',true,
    'customer',jsonb_build_object(
      'id',v_customer.id,'company_id',v_customer.company_id,'customer_code',v_customer.customer_code,
      'name',v_customer.name,'search_label',v_customer.search_label,'phone',v_customer.phone,
      'location',v_customer.location,'area',v_customer.area,'address',v_customer.address,
      'customer_type',v_customer.customer_type,'payment_type',v_customer.payment_type,
      'debt',coalesce(v_customer.debt,0),'credit_limit',coalesce(v_customer.credit_limit,0),
      'loyalty_points',coalesce(v_customer.loyalty_points,0),'visit_day',v_customer.visit_day,
      'contact_person',v_customer.contact_person,'sales_rep',v_customer.sales_rep,'notes',v_customer.notes,
      'is_active',coalesce(v_customer.is_active,true),'location_lat',v_customer.location_lat,'location_lng',v_customer.location_lng
    ),
    'metrics',jsonb_build_object(
      'order_count',(SELECT count(*) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=v_customer.id AND o.order_status <> 'Cancelled'),
      'sales_total',coalesce((SELECT sum(coalesce(o.total_amount,0)) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=v_customer.id AND o.order_status <> 'Cancelled'),0),
      'last_order_date',(SELECT max(o.order_date) FROM public.orders o WHERE o.company_id=v_company_id AND o.customer_id=v_customer.id AND o.order_status <> 'Cancelled'),
      'ledger_balance',(SELECT sum(coalesce(cl.debit,0)-coalesce(cl.credit,0)) FROM public.customer_ledger cl WHERE cl.customer_id=v_customer.id),
      'open_followups',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=v_customer.customer_code AND f.status IN ('Open','معلقة')),
      'overdue_followups',(SELECT count(*) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=v_customer.customer_code AND f.status IN ('Open','معلقة') AND f.followup_date < current_date),
      'next_followup_date',(SELECT min(f.followup_date) FROM public.customer_followups f WHERE f.company_id=v_company_id AND f.customer_id=v_customer.customer_code AND f.status IN ('Open','معلقة') AND f.followup_date >= current_date)
    ),
    'assignments',coalesce((
      SELECT jsonb_agg(x.row ORDER BY x.is_active DESC,x.assigned_at DESC)
      FROM (
        SELECT jsonb_build_object('user_id',ca.user_id,'email',u.email,'name',coalesce(nullif(u.name,''),u.email),
                                  'role',u.role,'is_active',ca.is_active,'assigned_at',ca.assigned_at,'notes',ca.notes) row,
               ca.is_active,ca.assigned_at
        FROM public.customer_assignments ca
        JOIN public.users u ON u.id=ca.user_id AND u.company_id=v_company_id
        WHERE ca.customer_id=v_customer.id
      ) x
    ),'[]'::jsonb),
    'orders',coalesce((
      SELECT jsonb_agg(x.row ORDER BY x.order_date DESC,x.created_at DESC,x.id DESC)
      FROM (
        SELECT jsonb_build_object(
          'id',o.id,'order_code',o.order_code,'order_date',o.order_date,'order_status',o.order_status,
          'total_amount',coalesce(o.total_amount,0),'payment_type',o.payment_type,'branch_id',o.branch_id,
          'sales_rep_name',o.sales_rep_name,'runsheet_code',r.runsheet_code,'runsheet_status',r.status,
          'qty_ordered',coalesce(od.qty_ordered,0),'qty_picked',coalesce(od.qty_picked,0),
          'qty_loaded',coalesce(od.qty_loaded,0),'qty_delivered',coalesce(od.qty_delivered,0),
          'qty_refused',coalesce(od.qty_refused,0),'qty_returned',coalesce(od.qty_returned,0)
        ) row,o.order_date,o.created_at,o.id
        FROM public.orders o
        LEFT JOIN public.runsheets r ON r.id=o.runsheet_id AND r.company_id=v_company_id
        LEFT JOIN LATERAL (
          SELECT sum(coalesce(d.qty,0)) qty_ordered,sum(coalesce(d.qty_picked,0)) qty_picked,
                 sum(coalesce(d.qty_loaded,0)) qty_loaded,sum(coalesce(d.qty_delivered,0)) qty_delivered,
                 sum(coalesce(d.qty_refused,0)) qty_refused,sum(coalesce(d.qty_returned,0)) qty_returned
          FROM public.order_details d WHERE d.order_id=o.id
        ) od ON true
        WHERE o.company_id=v_company_id AND o.customer_id=v_customer.id
        ORDER BY o.order_date DESC,o.created_at DESC,o.id DESC
        LIMIT 20
      ) x
    ),'[]'::jsonb),
    'followups',coalesce((
      SELECT jsonb_agg(x.row ORDER BY x.followup_date DESC,x.created_at DESC,x.id DESC)
      FROM (
        SELECT jsonb_build_object(
          'id',f.id,'followup_date',f.followup_date,'followup_type',f.followup_type,
          'subject',f.subject,'notes',f.notes,'assigned_to',f.assigned_to,'status',f.status,
          'created_by',f.created_by,'created_at',f.created_at,'completed_at',f.completed_at
        ) row,f.followup_date,f.created_at,f.id
        FROM public.customer_followups f
        WHERE f.company_id=v_company_id AND f.customer_id=v_customer.customer_code
        ORDER BY f.followup_date DESC,f.created_at DESC,f.id DESC
        LIMIT 50
      ) x
    ),'[]'::jsonb),
    'ledger',coalesce((
      SELECT jsonb_agg(x.row ORDER BY x.entry_date DESC,x.created_at DESC,x.id DESC)
      FROM (
        SELECT jsonb_build_object(
          'id',cl.id,'entry_date',cl.entry_date,'reference',cl.reference,'description',cl.description,
          'debit',coalesce(cl.debit,0),'credit',coalesce(cl.credit,0),'balance',coalesce(cl.balance,0),
          'due_date',cl.due_date,'user_email',cl.user_email,'created_at',cl.created_at
        ) row,cl.entry_date,cl.created_at,cl.id
        FROM public.customer_ledger cl
        WHERE cl.customer_id=v_customer.id
        ORDER BY cl.entry_date DESC,cl.created_at DESC,cl.id DESC
        LIMIT 50
      ) x
    ),'[]'::jsonb)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.crm_customer_360(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.crm_customer_360(uuid) TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.crm_set_customer_assignment(
  p_customer_id uuid,p_user_id uuid,p_is_active boolean DEFAULT true,p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
  v_assigned_by uuid;
  v_assignment_id uuid;
BEGIN
  IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('customers') THEN
    RAISE EXCEPTION 'غير مصرح بإدارة تعيينات العملاء';
  END IF;

  SELECT id INTO v_assigned_by
  FROM public.users
  WHERE auth_id=auth.uid() AND company_id=v_company_id AND status IS DISTINCT FROM 'Inactive'
  LIMIT 1;
  IF v_assigned_by IS NULL THEN RAISE EXCEPTION 'هوية منفذ العملية غير متاحة'; END IF;

  IF NOT EXISTS(SELECT 1 FROM public.customers c WHERE c.id=p_customer_id AND c.company_id=v_company_id) THEN
    RAISE EXCEPTION 'العميل غير موجود ضمن الشركة الحالية';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=p_user_id AND u.company_id=v_company_id AND u.status IS DISTINCT FROM 'Inactive') THEN
    RAISE EXCEPTION 'المستخدم المكلف غير موجود ضمن الشركة الحالية';
  END IF;

  INSERT INTO public.customer_assignments(user_id,customer_id,assigned_by,is_active,notes)
  VALUES(p_user_id,p_customer_id,v_assigned_by,coalesce(p_is_active,true),p_notes)
  ON CONFLICT (user_id,customer_id)
  DO UPDATE SET assigned_by=EXCLUDED.assigned_by,is_active=EXCLUDED.is_active,notes=EXCLUDED.notes,assigned_at=now()
  RETURNING id INTO v_assignment_id;

  RETURN jsonb_build_object('success',true,'assignment_id',v_assignment_id,'customer_id',p_customer_id,
                            'user_id',p_user_id,'is_active',coalesce(p_is_active,true));
END;
$function$;

REVOKE ALL ON FUNCTION public.crm_set_customer_assignment(uuid,uuid,boolean,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.crm_set_customer_assignment(uuid,uuid,boolean,text) TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.crm_set_customer_followup_status(
  p_followup_id uuid,p_status text,p_notes text DEFAULT NULL,p_assigned_to text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_company_id uuid := app_private.current_user_company_id();
  v_followup public.customer_followups%ROWTYPE;
  v_status text := lower(btrim(coalesce(p_status,'')));
BEGIN
  IF v_company_id IS NULL OR NOT app_private.current_user_has_permission('customers') THEN
    RAISE EXCEPTION 'غير مصرح بإدارة متابعات العملاء';
  END IF;

  IF v_status NOT IN ('open','مفتوحة','completed','مكتملة','cancelled','ملغاة') THEN
    RAISE EXCEPTION 'حالة المتابعة غير مدعومة';
  END IF;

  SELECT * INTO v_followup
  FROM public.customer_followups f
  WHERE f.id=p_followup_id AND f.company_id=v_company_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'المتابعة غير موجودة ضمن الشركة الحالية'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.customers c
    WHERE c.company_id=v_company_id AND c.customer_code=v_followup.customer_id
  ) THEN
    RAISE EXCEPTION 'العميل المرتبط بالمتابعة غير صالح';
  END IF;

  UPDATE public.customer_followups
  SET status=CASE
       WHEN v_status IN ('open','مفتوحة') THEN 'Open'
       WHEN v_status IN ('completed','مكتملة') THEN 'completed'
       ELSE 'cancelled'
      END,
      notes=CASE WHEN p_notes IS NULL THEN notes ELSE p_notes END,
      assigned_to=CASE WHEN p_assigned_to IS NULL THEN assigned_to ELSE NULLIF(btrim(p_assigned_to),'') END,
      completed_at=CASE
        WHEN v_status IN ('completed','مكتملة') THEN coalesce(completed_at,now())
        WHEN v_status IN ('open','مفتوحة') THEN NULL
        ELSE completed_at
      END
  WHERE id=v_followup.id AND company_id=v_company_id
  RETURNING * INTO v_followup;

  RETURN jsonb_build_object('success',true,'followup_id',v_followup.id,
                            'customer_code',v_followup.customer_id,'status',v_followup.status,
                            'completed_at',v_followup.completed_at);
END;
$function$;

REVOKE ALL ON FUNCTION public.crm_set_customer_followup_status(uuid,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.crm_set_customer_followup_status(uuid,text,text,text) TO authenticated,service_role;

DROP TRIGGER IF EXISTS trg_audit_customer_followups ON public.customer_followups;
CREATE TRIGGER trg_audit_customer_followups
AFTER INSERT OR UPDATE OR DELETE ON public.customer_followups
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();

DROP TRIGGER IF EXISTS trg_audit_customer_assignments ON public.customer_assignments;
CREATE TRIGGER trg_audit_customer_assignments
AFTER INSERT OR UPDATE OR DELETE ON public.customer_assignments
FOR EACH ROW EXECUTE FUNCTION public.fn_audit_trigger();

COMMIT;