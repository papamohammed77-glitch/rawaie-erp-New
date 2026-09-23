-- RAWAEA ERP — 2026-09-23 Warehouse Vouchers Transfer authorization reconciliation
-- Final Production contract captured after forensic E2E.
-- Scope: allow warehouse-vouchers role to transfer stock between active company branches.
-- No new Edge Function. No new table. No Physical Stock engine change.
-- Physical mutation remains: post_stock_movement -> stock_branches + inventory_log.

CREATE OR REPLACE FUNCTION public.create_manual_stock_voucher_atomic(
  p_company_id uuid, p_type text, p_reference text,
  p_from_type text, p_from_id uuid, p_to_type text, p_to_id uuid,
  p_notes text, p_created_by text, p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_branch_id uuid;
  v_ok boolean;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_created_by,''),true);

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_created_by)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN RAISE EXCEPTION 'منشئ الإذن غير صالح ضمن الشركة'; END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
    OR (
      p_type='Transfer'
      AND v_actor.role='مخزني'
      AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
    )
  ) THEN
    IF p_type='Transfer' THEN
      FOR v_branch_id IN SELECT unnest(ARRAY[p_from_id,p_to_id]) LOOP
        SELECT EXISTS(
          SELECT 1 FROM public.branches b
          WHERE b.id=v_branch_id AND b.company_id=p_company_id
            AND (
              (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
                v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
                OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
              ))
              OR
              (jsonb_typeof(v_actor.allowed_branch_ids)='string'
               AND trim(both '"' from v_actor.allowed_branch_ids::text)
                   IN (b.branch_code,b.id::text,'*'))
            )
        ) INTO v_ok;
        IF NOT v_ok THEN RAISE EXCEPTION 'الفرع خارج نطاق فروع المستخدم المسموح بها'; END IF;
      END LOOP;
    ELSIF p_type IN ('DirectSale','SupplierReturn') THEN
      SELECT EXISTS(
        SELECT 1 FROM public.branches b
        WHERE b.id=p_from_id AND b.company_id=p_company_id
          AND (
            (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
              v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
            ))
            OR
            (jsonb_typeof(v_actor.allowed_branch_ids)='string'
             AND trim(both '"' from v_actor.allowed_branch_ids::text)
                 IN (b.branch_code,b.id::text,'*'))
          )
      ) INTO v_ok;
      IF NOT v_ok THEN RAISE EXCEPTION 'فرع المصدر خارج نطاق فروع المستخدم المسموح بها'; END IF;
    ELSIF p_type='DirectReturn' THEN
      SELECT EXISTS(
        SELECT 1 FROM public.branches b
        WHERE b.id=p_to_id AND b.company_id=p_company_id
          AND (
            (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
              v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
            ))
            OR
            (jsonb_typeof(v_actor.allowed_branch_ids)='string'
             AND trim(both '"' from v_actor.allowed_branch_ids::text)
                 IN (b.branch_code,b.id::text,'*'))
          )
      ) INTO v_ok;
      IF NOT v_ok THEN RAISE EXCEPTION 'فرع استلام المرتجع المباشر خارج نطاق فروع المستخدم المسموح بها'; END IF;
    END IF;
  END IF;

  RETURN public.create_manual_stock_voucher_atomic_core_20260828(
    p_company_id,p_type,p_reference,p_from_type,p_from_id,
    p_to_type,p_to_id,p_notes,p_created_by,p_items
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_manual_stock_voucher_atomic(
  p_company_id uuid, p_type text, p_reference text,
  p_from_type text, p_from_id uuid, p_to_type text, p_to_id uuid,
  p_notes text, p_created_by text, p_items jsonb,
  p_rep_id uuid, p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_rep public.users%ROWTYPE;
  v_branch_id uuid;
  v_ok boolean;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_created_by,''),true);
  PERFORM set_config('app.operation_id',coalesce(btrim(p_operation_id),''),true);

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_created_by)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN RAISE EXCEPTION 'منشئ الإذن غير صالح ضمن الشركة'; END IF;

  IF p_type IN ('DirectSale','DirectReturn') THEN
    IF p_rep_id IS NULL THEN RAISE EXCEPTION 'مندوب البيع المباشر مطلوب'; END IF;
    SELECT * INTO v_rep
    FROM public.users u
    WHERE u.company_id=p_company_id
      AND u.id=p_rep_id
      AND coalesce(u.status,'Active')='Active'
      AND u.role='مندوب بيع مباشر'
      AND coalesce(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
    LIMIT 1;
    IF NOT FOUND THEN RAISE EXCEPTION 'مندوب البيع المباشر غير صالح أو لا يملك صلاحية تطبيق البيع المباشر'; END IF;
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
    OR (
      p_type='Transfer'
      AND v_actor.role='مخزني'
      AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
    )
  ) THEN
    IF p_type='Transfer' THEN
      FOR v_branch_id IN SELECT unnest(ARRAY[p_from_id,p_to_id]) LOOP
        SELECT EXISTS(
          SELECT 1 FROM public.branches b
          WHERE b.id=v_branch_id AND b.company_id=p_company_id
            AND (
              (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
                v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
                OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
              ))
              OR
              (jsonb_typeof(v_actor.allowed_branch_ids)='string'
               AND trim(both '"' from v_actor.allowed_branch_ids::text)
                   IN (b.branch_code,b.id::text,'*'))
            )
        ) INTO v_ok;
        IF NOT v_ok THEN RAISE EXCEPTION 'الفرع خارج نطاق فروع المستخدم المسموح بها'; END IF;
      END LOOP;
    ELSIF p_type IN ('DirectSale','SupplierReturn') THEN
      SELECT EXISTS(
        SELECT 1 FROM public.branches b
        WHERE b.id=p_from_id AND b.company_id=p_company_id
          AND (
            (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
              v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
            ))
            OR
            (jsonb_typeof(v_actor.allowed_branch_ids)='string'
             AND trim(both '"' from v_actor.allowed_branch_ids::text)
                 IN (b.branch_code,b.id::text,'*'))
          )
      ) INTO v_ok;
      IF NOT v_ok THEN RAISE EXCEPTION 'فرع المصدر خارج نطاق فروع المستخدم المسموح بها'; END IF;
    ELSIF p_type='DirectReturn' THEN
      SELECT EXISTS(
        SELECT 1 FROM public.branches b
        WHERE b.id=p_to_id AND b.company_id=p_company_id
          AND (
            (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
              v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
            ))
            OR
            (jsonb_typeof(v_actor.allowed_branch_ids)='string'
             AND trim(both '"' from v_actor.allowed_branch_ids::text)
                 IN (b.branch_code,b.id::text,'*'))
          )
      ) INTO v_ok;
      IF NOT v_ok THEN RAISE EXCEPTION 'فرع استلام المرتجع المباشر خارج نطاق فروع المستخدم المسموح بها'; END IF;
    END IF;
  END IF;

  RETURN public.create_manual_stock_voucher_atomic_core_12_20260828(
    p_company_id,p_type,p_reference,p_from_type,p_from_id,
    p_to_type,p_to_id,p_notes,p_created_by,p_items,p_rep_id,p_operation_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(
  p_company_id uuid, p_voucher_code text, p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v public.stock_vouchers%ROWTYPE;
  v_source uuid;
  v_auth_branch uuid;
  v_allowed boolean;
  v_result jsonb;
  v_custodian_email text;
  v_custody_value numeric:=0;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  PERFORM set_config('app.operation_id','VoucherSend:'||p_company_id::text||':'||coalesce(btrim(p_voucher_code),''),true);

  SELECT * INTO v_actor FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;

  SELECT * INTO v FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;

  IF v.from_type='Branch' THEN
    v_source:=v.from_id;
  ELSIF v.from_type='Vehicle' THEN
    SELECT coalesce(
      (SELECT mb.id FROM public.branches mb
       WHERE mb.id=v_vehicle.mobile_branch_id AND mb.company_id=p_company_id AND mb.is_active=true),
      (SELECT lb.id FROM public.branches lb
       WHERE lb.company_id=p_company_id AND upper(lb.branch_code)=upper('VAN-'||v_vehicle.vehicle_code) AND lb.is_active=true)
    ) INTO v_source
    FROM public.vehicles v_vehicle
    WHERE v_vehicle.id=v.from_id AND v_vehicle.company_id=p_company_id
      AND coalesce(v_vehicle.status,'Active')='Active'
      AND coalesce(v_vehicle.mobile_stock_enabled,true)=true;
  END IF;

  IF v.type='DirectReturn' AND v.to_type='Branch' THEN v_auth_branch:=v.to_id;
  ELSE v_auth_branch:=v_source; END IF;

  IF v_auth_branch IS NULL OR NOT EXISTS(
    SELECT 1 FROM public.branches b
    WHERE b.id=v_auth_branch AND b.company_id=p_company_id AND b.is_active=true
  ) THEN
    RAISE EXCEPTION 'سياق الفرع التشغيلي للإذن غير صالح';
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
    OR (
      v.type='Transfer'
      AND v_actor.role='مخزني'
      AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
    )
  ) THEN
    SELECT EXISTS(
      SELECT 1 FROM public.branches b
      WHERE b.id=v_auth_branch AND b.company_id=p_company_id AND b.is_active=true
        AND (
          (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
            v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
            OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
          ))
          OR
          (jsonb_typeof(v_actor.allowed_branch_ids)='string'
           AND trim(both '"' from v_actor.allowed_branch_ids::text) IN (b.branch_code,b.id::text,'*'))
        )
    ) INTO v_allowed;
    IF NOT v_allowed THEN RAISE EXCEPTION 'الفرع التشغيلي للإذن خارج نطاق فروع المستخدم المسموح بها'; END IF;
  END IF;

  v_result:=public.send_stock_voucher_atomic_core_20260828(p_company_id,p_voucher_code,p_user_email);
  IF coalesce((v_result->>'duplicate')::boolean,false) THEN RETURN v_result; END IF;

  IF v.type='DirectSale' THEN
    IF v.custodian_user_id IS NULL THEN RAISE EXCEPTION 'DirectSale custodian context missing'; END IF;

    SELECT u.email INTO v_custodian_email
    FROM public.users u
    WHERE u.id=v.custodian_user_id AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active' AND u.role='مندوب بيع مباشر';

    IF v_custodian_email IS NULL THEN RAISE EXCEPTION 'مندوب عهدة DirectSale غير صالح'; END IF;

    SELECT coalesce(sum(
      svd.qty * coalesce(NULLIF(svd.unit_price,0),i.sales_price,i.cost_price,0)
    ),0) INTO v_custody_value
    FROM public.stock_voucher_details svd
    JOIN public.items i ON i.id=svd.item_id
    WHERE svd.voucher_id=v.id;

    IF v_custody_value>0 THEN
      PERFORM public.post_driver_ledger_entry(
        p_company_id,v.id,v_custodian_email,current_date,p_voucher_code,
        'تحميل عهدة مبيعات مباشرة – '||p_voucher_code,v_custody_value,0
      );
      v_result:=v_result||jsonb_build_object(
        'custody_ledger',true,'custodian_user_id',v.custodian_user_id,'custody_value',v_custody_value
      );
    ELSE
      v_result:=v_result||jsonb_build_object('custody_ledger',false,'custody_value',0);
    END IF;
  END IF;
  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.post_manual_stock_voucher_atomic(
  p_company_id uuid, p_voucher_code text, p_operation text,
  p_user_email text, p_effects jsonb, p_operation_id text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_allowed boolean;
  v_voucher public.stock_vouchers%ROWTYPE;
  v_is_transfer boolean:=false;
  v_result jsonb;
  v_custodian_email text;
  v_credit_value numeric:=0;
  v_driver_operation uuid;
  v_hash text;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  PERFORM set_config('app.operation_id',coalesce(btrim(p_operation_id),''),true);

  SELECT * INTO v_actor FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;

  SELECT type='Transfer' INTO v_is_transfer
  FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code
  LIMIT 1;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
    OR (
      v_is_transfer
      AND v_actor.role='مخزني'
      AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
    )
  ) THEN
    SELECT NOT EXISTS(
      SELECT 1 FROM jsonb_to_recordset(p_effects) AS x(branch_id uuid)
      WHERE NOT EXISTS(
        SELECT 1 FROM public.branches b
        WHERE b.id=x.branch_id AND b.company_id=p_company_id
          AND (
            (jsonb_typeof(v_actor.allowed_branch_ids)='array' AND (
              v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
            ))
            OR
            (jsonb_typeof(v_actor.allowed_branch_ids)='string'
             AND trim(both '"' from v_actor.allowed_branch_ids::text) IN (b.branch_code,b.id::text,'*'))
          )
      )
    ) INTO v_allowed;
    IF NOT v_allowed THEN RAISE EXCEPTION 'أحد فروع الحركة خارج نطاق فروع المستخدم المسموح بها'; END IF;
  END IF;

  SELECT * INTO v_voucher FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;

  v_result:=public.post_manual_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_operation,p_user_email,p_effects,p_operation_id
  );
  IF coalesce((v_result->>'duplicate')::boolean,false) THEN RETURN v_result; END IF;

  IF p_operation='RECEIVE' AND v_voucher.type='DirectReturn' THEN
    IF v_voucher.custodian_user_id IS NULL THEN RAISE EXCEPTION 'DirectReturn custodian context missing'; END IF;
    SELECT u.email INTO v_custodian_email
    FROM public.users u
    WHERE u.id=v_voucher.custodian_user_id AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active' AND u.role='مندوب بيع مباشر';
    IF v_custodian_email IS NULL THEN RAISE EXCEPTION 'مندوب عهدة DirectReturn غير صالح'; END IF;
    SELECT coalesce(sum(
      x.qty * coalesce(NULLIF(svd.unit_price,0),i.sales_price,i.cost_price,0)
    ),0) INTO v_credit_value
    FROM jsonb_to_recordset(p_effects) AS x(direction text,branch_id uuid,item_id uuid,item_code text,qty numeric)
    JOIN public.stock_voucher_details svd
      ON svd.voucher_id=v_voucher.id AND svd.item_id=x.item_id AND svd.item_code=x.item_code
    JOIN public.items i ON i.id=x.item_id;
    IF v_credit_value>0 THEN
      v_hash:=md5('VoucherCustodyCredit:'||p_company_id::text||':'||v_voucher.id::text||':'||coalesce(btrim(p_operation_id),''));
      v_driver_operation:=(
        substr(v_hash,1,8)||'-'||substr(v_hash,9,4)||'-'||substr(v_hash,13,4)||'-'||substr(v_hash,17,4)||'-'||substr(v_hash,21,12)
      )::uuid;
      PERFORM public.post_driver_ledger_entry(
        p_company_id,v_driver_operation,v_custodian_email,current_date,p_voucher_code,
        'تخفيض عهدة مرتجع مباشر – '||p_voucher_code,0,v_credit_value
      );
      v_result:=v_result||jsonb_build_object(
        'custody_ledger',true,'custody_credit',v_credit_value,'custodian_user_id',v_voucher.custodian_user_id
      );
    END IF;
  END IF;

  RETURN v_result;
END;
$function$;

-- Preserve existing executable grants; no function count increase.
