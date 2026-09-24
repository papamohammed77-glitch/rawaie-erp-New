-- RAWAEA ERP
-- Surgical production fix applied 2026-09-24.
-- Purpose: remove the unreachable duplicate DirectReturn branch from the existing core.
-- Contract preserved: DirectReturn = Vehicle -> Branch.
-- No new Edge Function. No change to post_stock_movement.
CREATE OR REPLACE FUNCTION public.create_manual_stock_voucher_atomic_core_12_20260828(p_company_id uuid, p_type text, p_reference text, p_from_type text, p_from_id uuid, p_to_type text, p_to_id uuid, p_notes text, p_created_by text, p_items jsonb, p_rep_id uuid, p_operation_id text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_voucher_id uuid;
  v_voucher_code text;
  v_item jsonb;
  v_item_id uuid;
  v_last_num bigint;
  v_valid boolean;
  v_actor public.users%ROWTYPE;
  v_rep public.users%ROWTYPE;
  v_vehicle public.vehicles%ROWTYPE;
  v_fingerprint text;
  v_existing public.stock_voucher_operations%ROWTYPE;
  v_allowed boolean;
BEGIN
  IF NOT EXISTS(
    SELECT 1 FROM public.companies
    WHERE id=p_company_id
  ) THEN
    RAISE EXCEPTION 'سياق الشركة غير موجود';
  END IF;

  IF NULLIF(btrim(p_reference),'') IS NULL THEN
    RAISE EXCEPTION 'المرجع مطلوب';
  END IF;

  IF p_items IS NULL
     OR jsonb_typeof(p_items)<>'array'
     OR jsonb_array_length(p_items)=0 THEN
    RAISE EXCEPTION 'يجب إضافة صنف واحد على الأقل';
  END IF;

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_created_by)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'منشئ الإذن غير صالح ضمن الشركة';
  END IF;

  IF p_type NOT IN('Transfer','DirectSale','DirectReturn','SupplierReturn') THEN
    RAISE EXCEPTION 'نوع الإذن غير مدعوم في دورة الأذونات الحالية';
  END IF;

  IF p_type='Transfer'
     AND (
       p_from_type<>'Branch'
       OR p_from_id IS NULL
       OR p_to_type<>'Branch'
       OR p_to_id IS NULL
     ) THEN
    RAISE EXCEPTION 'تحويل الفرع يتطلب فرع مصدر ووجهة';
  END IF;

  IF p_type='DirectSale' THEN
    IF p_from_type<>'Branch' OR p_from_id IS NULL OR p_to_type<>'Vehicle' THEN
      RAISE EXCEPTION 'الصرف المباشر يتطلب فرع مصدر';
    END IF;

    IF v_actor.role='مندوب بيع مباشر' THEN
      IF p_rep_id IS NULL THEN p_rep_id:=v_actor.id; END IF;
    ELSIF coalesce(v_actor.active_warehouse_role,'')='أذونات' THEN
      IF p_rep_id IS NULL THEN RAISE EXCEPTION 'مندوب البيع المباشر مطلوب للصرف المباشر'; END IF;
    ELSE
      RAISE EXCEPTION 'منشئ الصرف المباشر غير مخول بإنشاء إذن الصرف';
    END IF;

    SELECT * INTO v_rep
    FROM public.users u
    WHERE u.id=p_rep_id
      AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
      AND u.role='مندوب بيع مباشر'
      AND COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'مندوب البيع المباشر غير صالح ضمن الشركة';
    END IF;

    IF p_to_id IS NULL THEN
      SELECT a.vehicle_id INTO p_to_id
      FROM public.fleet_vehicle_sales_rep_assignments a
      JOIN public.vehicles v ON v.id=a.vehicle_id AND v.company_id=p_company_id
      WHERE a.company_id=p_company_id
        AND a.sales_rep_user_id=p_rep_id
        AND a.end_at IS NULL
        AND a.is_primary=true
        AND coalesce(v.status,'Active')='Active'
        AND coalesce(v.mobile_stock_enabled,true)=true
      ORDER BY a.start_at DESC,a.created_at DESC,a.id DESC
      LIMIT 1;
      IF p_to_id IS NULL THEN
        RAISE EXCEPTION 'لا توجد مركبة نشطة مرتبطة بمندوب البيع المباشر';
      END IF;
    END IF;

    IF v_actor.role='مندوب بيع مباشر' THEN
      p_rep_id:=v_actor.id;
    ELSIF coalesce(v_actor.active_warehouse_role,'')='أذونات' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'منشئ الصرف المباشر غير مخول بإنشاء إذن الصرف';
    END IF;

    SELECT * INTO v_vehicle
    FROM public.vehicles v
    WHERE v.id=p_to_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'المركبة الوجهة غير مهيأة كمخزن متنقل';
    END IF;

    IF v_rep.default_branch_id IS NOT NULL THEN
      v_allowed:=v_rep.default_branch_id=p_from_id;
    ELSE
      v_allowed:=NULLIF(btrim(v_rep.allowed_branch_ids::text),'') IS NULL OR v_rep.allowed_branch_ids='[]'::jsonb;
    END IF;
    IF NOT v_allowed THEN
      SELECT EXISTS(
        SELECT 1 FROM public.branches b WHERE b.id=p_from_id AND b.company_id=p_company_id AND (
          (jsonb_typeof(v_rep.allowed_branch_ids)='array' AND (v_rep.allowed_branch_ids @> jsonb_build_array(b.branch_code) OR v_rep.allowed_branch_ids @> jsonb_build_array(b.id::text)))
          OR
          (jsonb_typeof(v_rep.allowed_branch_ids)='string' AND lower(trim(both '"' from v_rep.allowed_branch_ids::text))=lower(b.branch_code))
        )
      ) INTO v_allowed;
    END IF;
    IF NOT v_allowed THEN
      RAISE EXCEPTION 'الفرع المصدر غير مسموح لمندوب البيع المباشر';
    END IF;

  ELSIF p_type='DirectReturn' THEN
    IF p_from_type<>'Vehicle'
       OR p_from_id IS NULL
       OR p_to_type<>'Branch'
       OR p_to_id IS NULL THEN
      RAISE EXCEPTION 'المرتجع المباشر يتطلب مركبة مصدر وفرع وجهة';
    END IF;

    SELECT * INTO v_vehicle
    FROM public.vehicles v
    WHERE v.id=p_from_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'المركبة المصدر غير موجودة أو غير نشطة أو ليست مهيأة كمخزن متنقل';
    END IF;

    IF NOT (
      (
        v_vehicle.mobile_branch_id IS NOT NULL
        AND EXISTS(
          SELECT 1
          FROM public.branches b
          WHERE b.id=v_vehicle.mobile_branch_id
            AND b.company_id=p_company_id
            AND b.is_active=true
        )
      )
      OR EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.company_id=p_company_id
          AND upper(b.branch_code)=upper('VAN-'||v_vehicle.vehicle_code)
          AND b.is_active=true
      )
    ) THEN
      RAISE EXCEPTION 'المركبة المصدر ليست مهيأة كمخزن متنقل صالح';
    END IF;

    IF v_actor.role='مندوب بيع مباشر'
       AND NOT EXISTS(
         SELECT 1
         FROM public.vehicles v
         WHERE v.id=p_from_id
           AND v.driver_id=v_actor.id
       ) THEN
      RAISE EXCEPTION 'المركبة المصدر لا تتبع مندوب البيع المباشر الحالي';
    END IF;

  ELSIF p_type='SupplierReturn' THEN
    IF p_from_type<>'Branch'
       OR p_from_id IS NULL
       OR p_to_type<>'Supplier'
       OR p_to_id IS NULL THEN
      RAISE EXCEPTION 'مرتجع المورد يتطلب فرع مصدر ومورد وجهة';
    END IF;

    IF NOT EXISTS(
      SELECT 1
      FROM public.suppliers s
      WHERE s.id=p_to_id
        AND s.company_id=p_company_id
        AND coalesce(s.is_active,true)
    ) THEN
      RAISE EXCEPTION 'المورد غير موجود أو غير نشط ضمن الشركة';
    END IF;

    IF NOT EXISTS(
      SELECT 1
      FROM public.purchase_orders po
      WHERE po.company_id=p_company_id
        AND po.supplier_id=p_to_id
        AND po.branch_id=p_from_id
    ) THEN
      RAISE EXCEPTION 'لا توجد علاقة موثقة بين المورد وفرع المصدر';
    END IF;
  END IF;

  IF p_from_type='Branch'
     AND NOT EXISTS(
       SELECT 1
       FROM public.branches b
       WHERE b.id=p_from_id
         AND b.company_id=p_company_id
     ) THEN
    RAISE EXCEPTION 'فرع المصدر غير موجود أو لا يتبع الشركة الحالية';
  END IF;

  IF p_from_type='Vehicle' THEN
    SELECT * INTO v_vehicle
    FROM public.vehicles v
    WHERE v.id=p_from_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'المركبة المصدر غير موجودة أو غير نشطة';
    END IF;

    IF NOT (
      (
        v_vehicle.mobile_branch_id IS NOT NULL
        AND EXISTS(
          SELECT 1
          FROM public.branches b
          WHERE b.id=v_vehicle.mobile_branch_id
            AND b.company_id=p_company_id
            AND b.is_active=true
        )
      )
      OR EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.company_id=p_company_id
          AND upper(b.branch_code)=upper('VAN-'||v_vehicle.vehicle_code)
          AND b.is_active=true
      )
    ) THEN
      RAISE EXCEPTION 'المركبة المصدر غير مهيأة كمخزن متنقل';
    END IF;
  END IF;

  IF p_to_type='Branch'
     AND NOT EXISTS(
       SELECT 1
       FROM public.branches b
       WHERE b.id=p_to_id
         AND b.company_id=p_company_id
     ) THEN
    RAISE EXCEPTION 'فرع الوجهة غير موجود أو لا يتبع الشركة الحالية';
  END IF;

  IF p_to_type='Vehicle' THEN
    SELECT * INTO v_vehicle
    FROM public.vehicles v
    WHERE v.id=p_to_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'المركبة الوجهة غير موجودة أو غير نشطة';
    END IF;

    IF NOT (
      (
        v_vehicle.mobile_branch_id IS NOT NULL
        AND EXISTS(
          SELECT 1
          FROM public.branches b
          WHERE b.id=v_vehicle.mobile_branch_id
            AND b.company_id=p_company_id
            AND b.is_active=true
        )
      )
      OR EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.company_id=p_company_id
          AND upper(b.branch_code)=upper('VAN-'||v_vehicle.vehicle_code)
          AND b.is_active=true
      )
    ) THEN
      RAISE EXCEPTION 'المركبة الوجهة غير مهيأة كمخزن متنقل';
    END IF;
  END IF;

  v_fingerprint:=md5(
    jsonb_build_object(
      'type',p_type,
      'reference',btrim(p_reference),
      'from_type',p_from_type,
      'from_id',p_from_id,
      'to_type',p_to_type,
      'to_id',p_to_id,
      'notes',coalesce(p_notes,''),
      'rep_id',p_rep_id,
      'items',p_items
    )::text
  );

  IF NULLIF(btrim(p_operation_id),'') IS NOT NULL THEN
    SELECT * INTO v_existing
    FROM public.stock_voucher_operations
    WHERE company_id=p_company_id
      AND operation_id=btrim(p_operation_id)
    FOR UPDATE;

    IF FOUND THEN
      IF v_existing.fingerprint<>v_fingerprint THEN
        RAISE EXCEPTION 'operation_id مستخدم مع بيانات مختلفة';
      END IF;

      IF v_existing.voucher_id IS NOT NULL THEN
        RETURN jsonb_build_object(
          'success',true,
          'duplicate',true,
          'voucher_id',v_existing.voucher_id,
          'voucher_code',(
            SELECT voucher_code
            FROM public.stock_vouchers
            WHERE id=v_existing.voucher_id
          ),
          'company_id',p_company_id,
          'rep_id',p_rep_id,
          'operation_id',btrim(p_operation_id)
        );
      END IF;
    ELSE
      INSERT INTO public.stock_voucher_operations(
        company_id,operation_id,fingerprint
      )
      VALUES(
        p_company_id,btrim(p_operation_id),v_fingerprint
      );
    END IF;
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtext('rawaea:stock-voucher-code')
  );

  SELECT coalesce(
    max(substring(voucher_code from '[0-9]+$')::bigint),
    0
  )
  INTO v_last_num
  FROM public.stock_vouchers
  WHERE company_id=p_company_id;

  v_voucher_code:='IN-'||(v_last_num+1)::text;

  INSERT INTO public.stock_vouchers(
    voucher_code,
    voucher_date,
    type,
    status,
    reference,
    from_type,
    from_id,
    to_type,
    to_id,
    notes,
    custodian_user_id,
    created_by,
    source,
    company_id
  )
  VALUES(
    v_voucher_code,
    current_date,
    p_type,
    'Draft',
    btrim(p_reference),
    p_from_type,
    p_from_id,
    p_to_type,
    p_to_id,
    coalesce(p_notes,''),
    CASE
      WHEN p_type IN ('DirectSale','DirectReturn') THEN p_rep_id
      ELSE NULL
    END,
    p_created_by,
    'Manual',
    p_company_id
  )
  RETURNING id INTO v_voucher_id;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(p_items)
  LOOP
    IF coalesce(nullif(v_item->>'itemCode',''),'')='' THEN
      RAISE EXCEPTION 'كود الصنف مطلوب';
    END IF;

    IF coalesce((v_item->>'qty')::numeric,0)<=0 THEN
      RAISE EXCEPTION 'كمية الصنف يجب أن تكون أكبر من صفر';
    END IF;

    SELECT i.id INTO v_item_id
    FROM public.items i
    WHERE i.item_code=v_item->>'itemCode';

    IF v_item_id IS NULL THEN
      RAISE EXCEPTION 'الصنف غير موجود: %',v_item->>'itemCode';
    END IF;

    IF EXISTS(
      SELECT 1
      FROM public.stock_voucher_details d
      WHERE d.voucher_id=v_voucher_id
        AND d.item_id=v_item_id
    ) THEN
      RAISE EXCEPTION 'لا يمكن تكرار الصنف داخل نفس الإذن: %',v_item->>'itemCode';
    END IF;

    INSERT INTO public.stock_voucher_details(
      voucher_id,
      item_id,
      item_code,
      item_name,
      unit,
      qty,
      unit_price,
      notes
    )
    VALUES(
      v_voucher_id,
      v_item_id,
      v_item->>'itemCode',
      coalesce(
        nullif(v_item->>'itemName',''),
        v_item->>'itemCode'
      ),
      coalesce(
        nullif(v_item->>'unit',''),
        'حبة'
      ),
      (v_item->>'qty')::numeric,
      coalesce(
        (v_item->>'unitPrice')::numeric,
        0
      ),
      coalesce(
        v_item->>'notes',
        ''
      )
    );
  END LOOP;

  IF NULLIF(btrim(p_operation_id),'') IS NOT NULL THEN
    UPDATE public.stock_voucher_operations
    SET voucher_id=v_voucher_id
    WHERE company_id=p_company_id
      AND operation_id=btrim(p_operation_id);
  END IF;

  RETURN jsonb_build_object(
    'success',true,
    'voucher_id',v_voucher_id,
    'voucher_code',v_voucher_code,
    'company_id',p_company_id,
    'rep_id',p_rep_id,
    'operation_id',nullif(btrim(p_operation_id),'')
  );
END;
$function$

