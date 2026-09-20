CREATE OR REPLACE FUNCTION public.inventory_voucher_report(
  p_operation text,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_op text := upper(btrim(coalesce(p_operation,'')));
  v_company_id uuid;
  v_email text;
  v_privileged boolean := false;
  v_reporting boolean := false;
  v_warehouse boolean := false;
  v_voucher_access boolean := false;
  v_type text;
  v_status text;
  v_query text;
  v_from_date date;
  v_to_date date;
  v_source text;
  v_voucher_code text;
  v_limit integer := 50;
  v_offset integer := 0;
  v_total bigint := 0;
  v_rows jsonb := '[]'::jsonb;
  v_statuses jsonb := '[]'::jsonb;
  v_types jsonb := '[]'::jsonb;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'غير مصرح'; END IF;

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.auth_id = auth.uid()
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN RAISE EXCEPTION 'المستخدم الحالي غير مسجل أو غير نشط'; END IF;

  v_company_id := v_actor.company_id;
  v_email := v_actor.email;

  v_privileged := coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
                  OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام');
  v_reporting := v_privileged
                 OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["reports"]'::jsonb;
  v_warehouse := v_privileged
                 OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["warehouse"]'::jsonb
                 OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["warehouse_manager"]'::jsonb
                 OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["warehouse_supervisor"]'::jsonb;
  v_voucher_access := v_warehouse
                      OR v_reporting
                      OR coalesce(v_actor.active_warehouse_role,'')='أذونات'
                      OR coalesce(v_actor.permissions,'[]'::jsonb) @> '["vouchers"]'::jsonb;

  IF v_op NOT IN ('LIST','SUMMARY') THEN
    RAISE EXCEPTION 'عملية تقرير الأذونات غير مدعومة';
  END IF;
  IF NOT v_voucher_access THEN
    RAISE EXCEPTION 'غير مصرح بقراءة تقارير الأذونات المخزنية';
  END IF;

  v_type := nullif(btrim(coalesce(p_payload->>'type','')),'');
  v_status := nullif(btrim(coalesce(p_payload->>'status','')),'');
  v_query := lower(nullif(btrim(coalesce(p_payload->>'search','')),''));
  v_source := coalesce(nullif(btrim(coalesce(p_payload->>'source','')),''),'Manual');
  v_voucher_code := nullif(btrim(coalesce(p_payload->>'voucher_code','')),'');
  v_from_date := nullif(btrim(coalesce(p_payload->>'from_date','')),'')::date;
  v_to_date := nullif(btrim(coalesce(p_payload->>'to_date','')),'')::date;
  v_limit := least(greatest(coalesce((p_payload->>'limit')::integer,50),1),200);
  v_offset := greatest(coalesce((p_payload->>'offset')::integer,0),0);

  IF v_type IS NOT NULL AND v_type NOT IN ('Transfer','DirectSale','DirectReturn','SupplierReturn') THEN
    RAISE EXCEPTION 'نوع الإذن غير مدعوم';
  END IF;
  IF v_status IS NOT NULL AND v_status NOT IN ('Draft','Sent','Received','Completed','Cancelled') THEN
    RAISE EXCEPTION 'حالة الإذن غير مدعومة';
  END IF;
  IF v_from_date IS NOT NULL AND v_to_date IS NOT NULL AND v_from_date > v_to_date THEN
    RAISE EXCEPTION 'نطاق التاريخ غير صالح';
  END IF;

  IF v_op='SUMMARY' THEN
    SELECT count(*) INTO v_total
    FROM public.stock_vouchers v
    WHERE v.company_id=v_company_id AND v.source=v_source
      AND (v_type IS NULL OR v.type=v_type)
      AND (v_status IS NULL OR v.status=v_status)
      AND (v_voucher_code IS NULL OR v.voucher_code=v_voucher_code)
      AND (v_from_date IS NULL OR v.voucher_date>=v_from_date)
      AND (v_to_date IS NULL OR v.voucher_date<=v_to_date)
      AND (
        v_query IS NULL
        OR lower(concat_ws(' ',v.voucher_code,v.reference,v.type,v.status,v.source,v.created_by,v.completed_by,v.notes,v.from_type,v.to_type)) LIKE '%'||v_query||'%'
        OR EXISTS (SELECT 1 FROM public.stock_voucher_details d
                   WHERE d.voucher_id=v.id
                     AND lower(concat_ws(' ',d.item_code,d.item_name,d.unit,d.notes)) LIKE '%'||v_query||'%')
        OR EXISTS (SELECT 1 FROM public.branches b
                   WHERE b.company_id=v_company_id AND b.id IN (v.from_id,v.to_id)
                     AND lower(concat_ws(' ',b.branch_code,b.name,b.location)) LIKE '%'||v_query||'%')
        OR EXISTS (SELECT 1 FROM public.vehicles vh
                   WHERE vh.company_id=v_company_id AND vh.id IN (v.from_id,v.to_id)
                     AND lower(concat_ws(' ',vh.vehicle_code,vh.license_plate,vh.model)) LIKE '%'||v_query||'%')
        OR EXISTS (SELECT 1 FROM public.suppliers sp
                   WHERE sp.company_id=v_company_id AND sp.id IN (v.from_id,v.to_id)
                     AND lower(concat_ws(' ',sp.supplier_code,sp.name,sp.search_label)) LIKE '%'||v_query||'%')
      );

    SELECT coalesce(jsonb_agg(jsonb_build_object('type',x.type,'count',x.cnt) ORDER BY x.type),'[]'::jsonb)
    INTO v_types
    FROM (
      SELECT v.type,count(*) cnt
      FROM public.stock_vouchers v
      WHERE v.company_id=v_company_id AND v.source=v_source
        AND (v_type IS NULL OR v.type=v_type)
        AND (v_status IS NULL OR v.status=v_status)
        AND (v_voucher_code IS NULL OR v.voucher_code=v_voucher_code)
        AND (v_from_date IS NULL OR v.voucher_date>=v_from_date)
        AND (v_to_date IS NULL OR v.voucher_date<=v_to_date)
      GROUP BY v.type
    ) x;

    SELECT coalesce(jsonb_agg(jsonb_build_object('status',x.status,'count',x.cnt) ORDER BY x.status),'[]'::jsonb)
    INTO v_statuses
    FROM (
      SELECT v.status,count(*) cnt
      FROM public.stock_vouchers v
      WHERE v.company_id=v_company_id AND v.source=v_source
        AND (v_type IS NULL OR v.type=v_type)
        AND (v_status IS NULL OR v.status=v_status)
        AND (v_voucher_code IS NULL OR v.voucher_code=v_voucher_code)
        AND (v_from_date IS NULL OR v.voucher_date>=v_from_date)
        AND (v_to_date IS NULL OR v.voucher_date<=v_to_date)
      GROUP BY v.status
    ) x;

    RETURN jsonb_build_object(
      'success',true,'operation','SUMMARY','type',v_type,'source',v_source,'status',v_status,
      'search',v_query,'total',v_total,
      'summary',jsonb_build_object('types',v_types,'statuses',v_statuses)
    );
  END IF;

  SELECT count(*) INTO v_total
  FROM public.stock_vouchers v
  WHERE v.company_id=v_company_id AND v.source=v_source
    AND (v_type IS NULL OR v.type=v_type)
    AND (v_status IS NULL OR v.status=v_status)
    AND (v_voucher_code IS NULL OR v.voucher_code=v_voucher_code)
    AND (v_from_date IS NULL OR v.voucher_date>=v_from_date)
    AND (v_to_date IS NULL OR v.voucher_date<=v_to_date)
    AND (
      v_query IS NULL
      OR lower(concat_ws(' ',v.voucher_code,v.reference,v.type,v.status,v.source,v.created_by,v.completed_by,v.notes,v.from_type,v.to_type)) LIKE '%'||v_query||'%'
      OR EXISTS (SELECT 1 FROM public.stock_voucher_details d
                 WHERE d.voucher_id=v.id
                   AND lower(concat_ws(' ',d.item_code,d.item_name,d.unit,d.notes)) LIKE '%'||v_query||'%')
      OR EXISTS (SELECT 1 FROM public.branches b
                 WHERE b.company_id=v_company_id AND b.id IN (v.from_id,v.to_id)
                   AND lower(concat_ws(' ',b.branch_code,b.name,b.location)) LIKE '%'||v_query||'%')
      OR EXISTS (SELECT 1 FROM public.vehicles vh
                 WHERE vh.company_id=v_company_id AND vh.id IN (v.from_id,v.to_id)
                   AND lower(concat_ws(' ',vh.vehicle_code,vh.license_plate,vh.model)) LIKE '%'||v_query||'%')
      OR EXISTS (SELECT 1 FROM public.suppliers sp
                 WHERE sp.company_id=v_company_id AND sp.id IN (v.from_id,v.to_id)
                   AND lower(concat_ws(' ',sp.supplier_code,sp.name,sp.search_label)) LIKE '%'||v_query||'%')
    );

  SELECT coalesce(jsonb_agg(to_jsonb(r) ORDER BY r.voucher_date DESC,r.created_at DESC,r.voucher_code DESC),'[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT
      v.id,v.voucher_code,v.voucher_date,v.type,v.status,v.reference,v.notes,v.source,
      v.created_by,v.completed_by,v.created_at,v.updated_at,v.sent_date,v.received_date,v.completed_at,
      v.from_type,v.from_id,v.to_type,v.to_id,
      CASE v.from_type
        WHEN 'Branch' THEN coalesce((SELECT b.name||' ['||b.branch_code||']' FROM public.branches b WHERE b.id=v.from_id AND b.company_id=v_company_id),'')
        WHEN 'Vehicle' THEN coalesce((SELECT vh.vehicle_code||' ['||vh.license_plate||']' FROM public.vehicles vh WHERE vh.id=v.from_id AND vh.company_id=v_company_id),'')
        WHEN 'Supplier' THEN coalesce((SELECT sp.name||' ['||sp.supplier_code||']' FROM public.suppliers sp WHERE sp.id=v.from_id AND sp.company_id=v_company_id),'')
        ELSE coalesce(v.from_id::text,'')
      END AS from_label,
      CASE v.to_type
        WHEN 'Branch' THEN coalesce((SELECT b.name||' ['||b.branch_code||']' FROM public.branches b WHERE b.id=v.to_id AND b.company_id=v_company_id),'')
        WHEN 'Vehicle' THEN coalesce((SELECT vh.vehicle_code||' ['||vh.license_plate||']' FROM public.vehicles vh WHERE vh.id=v.to_id AND vh.company_id=v_company_id),'')
        WHEN 'Supplier' THEN coalesce((SELECT sp.name||' ['||sp.supplier_code||']' FROM public.suppliers sp WHERE sp.id=v.to_id AND sp.company_id=v_company_id),'')
        ELSE coalesce(v.to_id::text,'')
      END AS to_label,
      (SELECT count(*) FROM public.stock_voucher_details d WHERE d.voucher_id=v.id) AS item_lines,
      (SELECT coalesce(sum(d.qty),0) FROM public.stock_voucher_details d WHERE d.voucher_id=v.id) AS total_qty,
      (SELECT count(*) FROM public.inventory_log il WHERE il.company_id=v_company_id AND il.voucher_id=v.voucher_code) AS movement_count,
      (SELECT count(*) FROM public.audit_log a
       WHERE a.table_name='stock_vouchers' AND a.record_id=v.id::text
         AND (a.company_id IS NULL OR a.company_id=v_company_id)) AS audit_count
    FROM public.stock_vouchers v
    WHERE v.company_id=v_company_id AND v.source=v_source
      AND (v_type IS NULL OR v.type=v_type)
      AND (v_status IS NULL OR v.status=v_status)
      AND (v_voucher_code IS NULL OR v.voucher_code=v_voucher_code)
      AND (v_from_date IS NULL OR v.voucher_date>=v_from_date)
      AND (v_to_date IS NULL OR v.voucher_date<=v_to_date)
      AND (
        v_query IS NULL
        OR lower(concat_ws(' ',v.voucher_code,v.reference,v.type,v.status,v.source,v.created_by,v.completed_by,v.notes,v.from_type,v.to_type)) LIKE '%'||v_query||'%'
        OR EXISTS (SELECT 1 FROM public.stock_voucher_details d
                   WHERE d.voucher_id=v.id
                     AND lower(concat_ws(' ',d.item_code,d.item_name,d.unit,d.notes)) LIKE '%'||v_query||'%')
        OR EXISTS (SELECT 1 FROM public.branches b
                   WHERE b.company_id=v_company_id AND b.id IN (v.from_id,v.to_id)
                     AND lower(concat_ws(' ',b.branch_code,b.name,b.location)) LIKE '%'||v_query||'%')
        OR EXISTS (SELECT 1 FROM public.vehicles vh
                   WHERE vh.company_id=v_company_id AND vh.id IN (v.from_id,v.to_id)
                     AND lower(concat_ws(' ',vh.vehicle_code,vh.license_plate,vh.model)) LIKE '%'||v_query||'%')
        OR EXISTS (SELECT 1 FROM public.suppliers sp
                   WHERE sp.company_id=v_company_id AND sp.id IN (v.from_id,v.to_id)
                     AND lower(concat_ws(' ',sp.supplier_code,sp.name,sp.search_label)) LIKE '%'||v_query||'%')
      )
    ORDER BY v.voucher_date DESC,v.created_at DESC,v.voucher_code DESC
    LIMIT v_limit OFFSET v_offset
  ) r;

  RETURN jsonb_build_object(
    'success',true,'operation','LIST','type',v_type,'source',v_source,'status',v_status,
    'search',v_query,'from_date',v_from_date,'to_date',v_to_date,'total',v_total,
    'offset',v_offset,'limit',v_limit,'has_more',(v_offset+v_limit)<v_total,'rows',v_rows
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.inventory_voucher_report(text,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.inventory_voucher_report(text,jsonb) TO authenticated, service_role;
