BEGIN;

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
  p_items jsonb
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
  v_allowed boolean;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_user_email,''),true);
  SELECT * INTO v_actor FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;

  SELECT * INTO v FROM public.stock_vouchers
  WHERE company_id=p_company_id AND voucher_code=p_voucher_code LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'الإذن غير موجود'; END IF;

  IF v.from_type='Branch' THEN
    v_source:=v.from_id;
  ELSIF v.from_type='Vehicle' THEN
    SELECT b.id INTO v_source
    FROM public.vehicles vv
    JOIN public.branches b ON b.company_id=vv.company_id
      AND upper(b.branch_code)=upper('VAN-'||vv.vehicle_code)
    WHERE vv.id=v.from_id AND vv.company_id=p_company_id
      AND coalesce(vv.status,'Active')='Active' LIMIT 1;
  END IF;
  IF v_source IS NULL THEN RAISE EXCEPTION 'مصدر المخزون غير محدد'; END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
  ) THEN
    SELECT EXISTS(
      SELECT 1 FROM public.branches b
      WHERE b.id=v_source AND b.company_id=p_company_id
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
    IF NOT v_allowed THEN RAISE EXCEPTION 'مصدر الإذن خارج نطاق فروع المستخدم المسموح بها'; END IF;
  END IF;

  RETURN public.send_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_user_email
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.post_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_voucher_code text,
  p_operation text,
  p_user_email text,
  p_effects jsonb,
  p_operation_id text DEFAULT NULL
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
  SELECT * INTO v_actor FROM public.users u
  WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active' LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ'; END IF;
  IF p_effects IS NULL OR jsonb_typeof(p_effects)<>'array' THEN
    RAISE EXCEPTION 'بيانات الحركة غير صالحة';
  END IF;

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
        SELECT 1 FROM public.branches b
        WHERE b.id=x.branch_id AND b.company_id=p_company_id
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

REVOKE EXECUTE ON FUNCTION public.create_manual_stock_voucher_atomic_core_12_20260828(uuid,text,text,text,uuid,text,uuid,text,text,jsonb,uuid,text)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.create_manual_stock_voucher_atomic_core_20260828(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)
  FROM PUBLIC, anon, authenticated, service_role;

COMMIT;
