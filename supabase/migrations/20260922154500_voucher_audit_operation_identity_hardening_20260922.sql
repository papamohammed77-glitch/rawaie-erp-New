-- RAWAEA ERP — Voucher authorization and audit operation identity hardening
-- Production-applied: 2026-09-22
-- No new Edge Function. Existing RPC signatures preserved.

BEGIN;

CREATE OR REPLACE FUNCTION public.complete_manual_stock_voucher_atomic_core_20260828(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v public.stock_vouchers%ROWTYPE;
  expected text;
  v_company_id uuid;
  v_supplier_id uuid;
  v_supplier_name text;
  v_return_value numeric := 0;
  v_inventory_account uuid;
  v_supplier_account uuid;
  v_financial jsonb := '{}'::jsonb;
  v_journal jsonb;
  v_supplier_ledger jsonb;
BEGIN
  SELECT u.company_id
    INTO v_company_id
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  ORDER BY u.id
  LIMIT 1;

  IF v_company_id IS NULL OR v_company_id<>p_company_id THEN
    RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ';
  END IF;

  SELECT *
    INTO v
  FROM public.stock_vouchers
  WHERE company_id=v_company_id
    AND voucher_code=p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الإذن غير موجود';
  END IF;

  IF v.status='Completed' THEN
    SELECT jsonb_build_object(
      'supplier_ledger',
      COALESCE((
        SELECT response_payload
        FROM public.erp_operation_registry
        WHERE company_id=v_company_id
          AND operation_type='post_supplier_ledger_entry'
          AND operation_key=v.id::text
          AND status='completed'
      ),'{}'::jsonb),
      'journal',
      COALESCE((
        SELECT response_payload
        FROM public.erp_operation_registry
        WHERE company_id=v_company_id
          AND operation_type='post_journal_entry'
          AND operation_key=v.id::text
          AND status='completed'
      ),'{}'::jsonb)
    )
    INTO v_financial;

    RETURN jsonb_build_object(
      'success',true,
      'duplicate',true,
      'voucher_code',p_voucher_code,
      'status',v.status,
      'financial',v_financial
    );
  END IF;

  expected := CASE
    WHEN v.type IN('Transfer','DirectReturn') THEN 'Received'
    WHEN v.type IN('DirectSale','SupplierReturn') THEN 'Sent'
    ELSE NULL
  END;

  IF expected IS NULL OR v.status<>expected THEN
    RAISE EXCEPTION 'حالة الإذن لا تسمح بالإكمال';
  END IF;

  IF v.type='SupplierReturn' THEN
    IF v.to_type<>'Supplier' OR v.to_id IS NULL THEN
      RAISE EXCEPTION 'مرتجع المورد يفتقد هوية المورد الصحيحة';
    END IF;

    SELECT s.id,s.name
      INTO v_supplier_id,v_supplier_name
    FROM public.suppliers s
    WHERE s.id=v.to_id
      AND s.company_id=v_company_id
      AND coalesce(s.is_active,true)
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'المورد غير موجود أو غير نشط ضمن الشركة';
    END IF;

    SELECT COALESCE(SUM(
      COALESCE(NULLIF(d.unit_price,0),i.cost_price,0)*COALESCE(d.qty,0)
    ),0)
      INTO v_return_value
    FROM public.stock_voucher_details d
    JOIN public.items i
      ON i.id=d.item_id
     AND i.item_code=d.item_code
    WHERE d.voucher_id=v.id;

    IF v_return_value<=0 THEN
      RAISE EXCEPTION 'لا يمكن إتمام مرتجع المورد قبل توفر قيمة تكلفة موجبة للأصناف';
    END IF;

    SELECT coa.id INTO v_inventory_account
    FROM public.chart_of_accounts coa
    WHERE coa.company_id=v_company_id
      AND coa.account_code='124'
      AND coa.is_active=true
    LIMIT 1;

    SELECT coa.id INTO v_supplier_account
    FROM public.chart_of_accounts coa
    WHERE coa.company_id=v_company_id
      AND coa.account_code='211'
      AND coa.is_active=true
    LIMIT 1;

    IF v_inventory_account IS NULL OR v_supplier_account IS NULL THEN
      RAISE EXCEPTION 'حسابات مرتجع المورد غير مكتملة للشركة';
    END IF;

    SELECT public.post_supplier_ledger_entry(
      v_company_id,v.id,v_supplier_id,v.voucher_date,p_voucher_code,
      'مرتجع مورد – '||p_voucher_code||
      CASE WHEN NULLIF(v_supplier_name,'') IS NOT NULL THEN ' – '||v_supplier_name ELSE '' END,
      v_return_value,0,v.voucher_date,p_user_email
    ) INTO v_supplier_ledger;

    SELECT public.post_journal_entry(
      v_company_id,v.id,v.voucher_date,'SupplierReturn',p_voucher_code,
      'مرتجع مورد – '||p_voucher_code||
      CASE WHEN NULLIF(v_supplier_name,'') IS NOT NULL THEN ' – '||v_supplier_name ELSE '' END,
      p_user_email,
      jsonb_build_array(
        jsonb_build_object(
          'account_id',v_supplier_account,
          'account_name','الموردون (ذمم دائنة)',
          'debit',v_return_value,'credit',0,
          'notes','خفض التزام المورد بسبب مرتجع البضاعة'
        ),
        jsonb_build_object(
          'account_id',v_inventory_account,
          'account_name','المخزون السلعي',
          'debit',0,'credit',v_return_value,
          'notes','خفض قيمة المخزون بسبب مرتجع المورد'
        )
      ),
      'JE-SVR-'||p_voucher_code,
      now(),
      NULL
    ) INTO v_journal;

    v_financial:=jsonb_build_object(
      'supplier_id',v_supplier_id,
      'supplier_name',v_supplier_name,
      'return_value',v_return_value,
      'supplier_ledger',v_supplier_ledger,
      'journal',v_journal
    );
  END IF;

  UPDATE public.stock_vouchers
  SET status='Completed',
      completed_at=now(),
      completed_by=p_user_email,
      updated_at=now()
  WHERE id=v.id
    AND company_id=v_company_id
    AND status=expected;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'فشل إكمال الإذن';
  END IF;

  RETURN jsonb_build_object(
    'success',true,
    'duplicate',false,
    'voucher_code',p_voucher_code,
    'status','Completed',
    'financial',v_financial
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_manual_stock_voucher_atomic_core_20260828(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v public.stock_vouchers%ROWTYPE;
  v_company_id uuid;
BEGIN
  SELECT u.company_id
    INTO v_company_id
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  ORDER BY u.id
  LIMIT 1;

  IF v_company_id IS NULL OR v_company_id<>p_company_id THEN
    RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ';
  END IF;

  SELECT *
    INTO v
  FROM public.stock_vouchers
  WHERE company_id=v_company_id
    AND voucher_code=p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الإذن غير موجود';
  END IF;

  IF v.status='Cancelled' THEN
    RETURN jsonb_build_object(
      'success',true,
      'duplicate',true,
      'voucher_code',p_voucher_code,
      'status',v.status
    );
  END IF;

  IF v.status<>'Draft' THEN
    RAISE EXCEPTION 'لا يمكن إلغاء إذن بعد تنفيذ حركة مخزنية؛ استخدم حركة عكسية رسمية';
  END IF;

  UPDATE public.stock_vouchers
  SET status='Cancelled',
      updated_at=now()
  WHERE id=v.id
    AND company_id=v_company_id
    AND status='Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'فشل إلغاء الإذن';
  END IF;

  RETURN jsonb_build_object(
    'success',true,
    'duplicate',false,
    'voucher_code',p_voucher_code,
    'status','Cancelled'
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_type text,
  p_reference text,
  p_from_type text,
  p_from_id uuid,
  p_to_type text,
  p_to_id uuid,
  p_notes text,
  p_created_by text,
  p_items jsonb,
  p_rep_id uuid,
  p_operation_id text
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

CREATE OR REPLACE FUNCTION public.post_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_operation text,
  p_user_email text,
  p_effects jsonb,
  p_operation_id text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_allowed boolean;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  PERFORM set_config('app.operation_id',coalesce(btrim(p_operation_id),''),true);

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;
  IF p_effects IS NULL OR jsonb_typeof(p_effects)<>'array' THEN RAISE EXCEPTION 'بيانات الحركة غير صالحة'; END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
  ) THEN
    SELECT NOT EXISTS(
      SELECT 1
      FROM jsonb_to_recordset(p_effects) AS x(branch_id uuid)
      WHERE NOT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=x.branch_id
          AND b.company_id=p_company_id
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
      )
    ) INTO v_allowed;
    IF NOT v_allowed THEN RAISE EXCEPTION 'أحد فروع الحركة خارج نطاق فروع المستخدم المسموح بها'; END IF;
  END IF;

  RETURN public.post_manual_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_operation,p_user_email,p_effects,p_operation_id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.send_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
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
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  PERFORM set_config('app.operation_id',
    'VoucherSend:'||p_company_id::text||':'||coalesce(btrim(p_voucher_code),''),
    true);

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;

  SELECT * INTO v
  FROM public.stock_vouchers
  WHERE company_id=p_company_id
    AND voucher_code=p_voucher_code
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;

  IF v.from_type='Branch' THEN
    v_source:=v.from_id;
  ELSIF v.from_type='Vehicle' THEN
    SELECT coalesce(
      (
        SELECT mb.id
        FROM public.branches mb
        WHERE mb.id=v_vehicle.mobile_branch_id
          AND mb.company_id=p_company_id
          AND mb.is_active=true
      ),
      (
        SELECT lb.id
        FROM public.branches lb
        WHERE lb.company_id=p_company_id
          AND upper(lb.branch_code)=upper('VAN-'||v_vehicle.vehicle_code)
          AND lb.is_active=true
      )
    ) INTO v_source
    FROM public.vehicles v_vehicle
    WHERE v_vehicle.id=v.from_id
      AND v_vehicle.company_id=p_company_id
      AND coalesce(v_vehicle.status,'Active')='Active'
      AND coalesce(v_vehicle.mobile_stock_enabled,true)=true;
  END IF;

  IF v.type='DirectReturn' AND v.to_type='Branch' THEN
    v_auth_branch:=v.to_id;
  ELSE
    v_auth_branch:=v_source;
  END IF;

  IF v_auth_branch IS NULL OR NOT EXISTS(
    SELECT 1 FROM public.branches b
    WHERE b.id=v_auth_branch AND b.company_id=p_company_id AND b.is_active=true
  ) THEN RAISE EXCEPTION 'سياق الفرع التشغيلي للإذن غير صالح'; END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
  ) THEN
    SELECT EXISTS(
      SELECT 1 FROM public.branches b
      WHERE b.id=v_auth_branch AND b.company_id=p_company_id
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
    ) INTO v_allowed;
    IF NOT v_allowed THEN RAISE EXCEPTION 'الفرع التشغيلي للإذن خارج نطاق فروع المستخدم المسموح بها'; END IF;
  END IF;

  RETURN public.send_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_user_email
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  PERFORM set_config('app.operation_id',
    'VoucherComplete:'||p_company_id::text||':'||coalesce(btrim(p_voucher_code),''),
    true);
  RETURN public.complete_manual_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_user_email
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  PERFORM set_config('app.operation_id',
    'VoucherCancel:'||p_company_id::text||':'||coalesce(btrim(p_voucher_code),''),
    true);
  RETURN public.cancel_manual_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_user_email
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_audit_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_actor_user_id uuid;
  v_actor_email text;
  v_actor_company_id uuid;
  v_company_id uuid;
  v_action text;
  v_old_data jsonb;
  v_new_data jsonb;
  v_record_id text;
  v_operation_id text;
BEGIN
  v_actor_user_id := auth.uid();

  CASE TG_OP
    WHEN 'INSERT' THEN
      v_action := 'create';
      v_old_data := NULL;
      v_new_data := to_jsonb(NEW);
      v_record_id := NEW.id::text;
    WHEN 'UPDATE' THEN
      v_action := 'update';
      v_old_data := to_jsonb(OLD);
      v_new_data := to_jsonb(NEW);
      v_record_id := OLD.id::text;
    WHEN 'DELETE' THEN
      v_action := 'delete';
      v_old_data := to_jsonb(OLD);
      v_new_data := NULL;
      v_record_id := OLD.id::text;
  END CASE;

  v_operation_id := COALESCE(
    NULLIF(v_new_data->>'operation_id',''),
    NULLIF(v_old_data->>'operation_id',''),
    NULLIF(current_setting('app.operation_id',true),'')
  );

  BEGIN
    v_company_id := COALESCE(
      CASE
        WHEN COALESCE(v_new_data->>'company_id','') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (v_new_data->>'company_id')::uuid
        ELSE NULL
      END,
      CASE
        WHEN COALESCE(v_old_data->>'company_id','') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (v_old_data->>'company_id')::uuid
        ELSE NULL
      END
    );
  EXCEPTION WHEN OTHERS THEN
    v_company_id := NULL;
  END;

  IF v_actor_user_id IS NOT NULL THEN
    SELECT u.email,u.company_id
      INTO v_actor_email,v_actor_company_id
    FROM public.users u
    WHERE u.auth_id=v_actor_user_id
      AND COALESCE(u.status,'Active')<>'Inactive'
    ORDER BY u.id
    LIMIT 1;
    v_company_id := COALESCE(v_company_id,v_actor_company_id);
  END IF;

  v_actor_email := COALESCE(
    NULLIF(v_actor_email,''),
    NULLIF(current_setting('app.user_email',true),''),
    NULLIF(current_setting('request.jwt.claim.email',true),''),
    NULLIF((NULLIF(current_setting('request.jwt.claims',true),'')::jsonb ->> 'email'),''),
    CASE WHEN v_actor_user_id IS NULL THEN 'system' ELSE NULL END
  );

  IF v_actor_user_id IS NULL AND NULLIF(v_actor_email,'') IS NOT NULL THEN
    SELECT u.id,u.company_id
      INTO v_actor_user_id,v_actor_company_id
    FROM public.users u
    WHERE lower(u.email)=lower(v_actor_email)
      AND COALESCE(u.status,'Active')<>'Inactive'
      AND (v_company_id IS NULL OR u.company_id=v_company_id)
    ORDER BY u.id
    LIMIT 1;
    v_company_id := COALESCE(v_company_id,v_actor_company_id);
  END IF;

  INSERT INTO public.audit_log(
    user_email,action,table_name,record_id,
    old_data,new_data,actor_user_id,company_id,
    source_type,operation_id
  ) VALUES (
    v_actor_email,v_action,TG_TABLE_NAME,v_record_id,
    v_old_data,v_new_data,v_actor_user_id,v_company_id,
    'database_trigger',v_operation_id
  );

  RETURN NULL;
END;
$function$;

COMMIT;
