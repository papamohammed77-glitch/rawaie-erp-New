-- RAWAEA ERP — surgical closure for manual voucher UPDATE duplicate-item guard
-- Date: 2026-09-24
-- Purpose: fix JSON camelCase field resolution in the canonical UPDATE RPC.
-- Business contract preserved: duplicate itemCode values remain rejected.
-- Only the duplicate-detection predicate changed; all other Production logic is reproduced exactly.

CREATE OR REPLACE FUNCTION public.update_manual_stock_voucher_atomic(p_company_id uuid, p_voucher_code text, p_operation_id text, p_reference text, p_from_type text, p_from_id uuid, p_to_type text, p_to_id uuid, p_notes text, p_items jsonb, p_rep_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_actor public.users%ROWTYPE;
  v_voucher public.stock_vouchers%ROWTYPE;
  v_vehicle public.vehicles%ROWTYPE;
  v_rep public.users%ROWTYPE;
  v_supplier public.suppliers%ROWTYPE;
  v_operation public.stock_voucher_operations%ROWTYPE;
  v_item jsonb;
  v_item_id uuid;
  v_fingerprint text;
  v_allowed boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'غير مصرح';
  END IF;

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.auth_id=auth.uid()
    AND u.company_id=p_company_id
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المستخدم الحالي غير صالح ضمن الشركة';
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR coalesce(v_actor.active_warehouse_role,'')='أذونات'
    OR v_actor.role IN ('مدير مخازن','مشرف مخازن','مدير عام')
  ) THEN
    RAISE EXCEPTION 'المستخدم غير مخول بتعديل الأذونات المخزنية';
  END IF;

  IF NULLIF(btrim(p_operation_id),'') IS NULL THEN
    RAISE EXCEPTION 'operation_id مطلوب';
  END IF;

  IF NULLIF(btrim(p_reference),'') IS NULL THEN
    RAISE EXCEPTION 'المرجع مطلوب';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items)<>'array' OR jsonb_array_length(p_items)=0 THEN
    RAISE EXCEPTION 'يجب إضافة صنف واحد على الأقل';
  END IF;

  SELECT * INTO v_voucher
  FROM public.stock_vouchers
  WHERE company_id=p_company_id
    AND voucher_code=p_voucher_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الإذن غير موجود';
  END IF;

  IF v_voucher.status<>'Draft' THEN
    RAISE EXCEPTION 'لا يمكن تعديل إذن بعد إرساله';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM jsonb_array_elements(p_items) AS z(value)
    GROUP BY btrim(z.value->>'itemCode')
    HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'لا يجوز تكرار الصنف داخل نفس الإذن';
  END IF;

  IF p_from_type='Branch' THEN
    IF p_from_id IS NULL OR NOT EXISTS(
      SELECT 1
      FROM public.branches b
      WHERE b.id=p_from_id
        AND b.company_id=p_company_id
        AND b.is_active=true
    ) THEN
      RAISE EXCEPTION 'فرع المصدر غير صالح';
    END IF;
  ELSIF p_from_type='Vehicle' THEN
    SELECT * INTO v_vehicle
    FROM public.vehicles v
    WHERE v.id=p_from_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'مركبة المصدر غير صالحة';
    END IF;
  ELSE
    RAISE EXCEPTION 'نوع المصدر غير مدعوم';
  END IF;

  IF p_to_type='Branch' THEN
    IF p_to_id IS NULL OR NOT EXISTS(
      SELECT 1
      FROM public.branches b
      WHERE b.id=p_to_id
        AND b.company_id=p_company_id
        AND b.is_active=true
    ) THEN
      RAISE EXCEPTION 'فرع الوجهة غير صالح';
    END IF;
  ELSIF p_to_type='Vehicle' THEN
    SELECT * INTO v_vehicle
    FROM public.vehicles v
    WHERE v.id=p_to_id
      AND v.company_id=p_company_id
      AND coalesce(v.status,'Active')='Active'
      AND coalesce(v.mobile_stock_enabled,true)=true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'مركبة الوجهة غير صالحة';
    END IF;
  ELSIF p_to_type='Supplier' THEN
    SELECT * INTO v_supplier
    FROM public.suppliers s
    WHERE s.id=p_to_id
      AND s.company_id=p_company_id
      AND coalesce(s.is_active,true)=true;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'المورد غير صالح';
    END IF;
  ELSE
    RAISE EXCEPTION 'نوع الوجهة غير مدعوم';
  END IF;

  IF v_voucher.type='Transfer' THEN
    IF p_from_type<>'Branch' OR p_to_type<>'Branch' THEN
      RAISE EXCEPTION 'تحويل داخلي يجب أن يكون فرعاً إلى فرع';
    END IF;

  ELSIF v_voucher.type='DirectSale' THEN
    IF p_from_type<>'Branch' OR p_to_type<>'Vehicle' THEN
      RAISE EXCEPTION 'الصرف المباشر يجب أن يكون فرعاً إلى مركبة';
    END IF;

    IF p_rep_id IS NULL THEN
      RAISE EXCEPTION 'مندوب البيع المباشر مطلوب';
    END IF;

    SELECT * INTO v_rep
    FROM public.users u
    WHERE u.id=p_rep_id
      AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
      AND u.role='مندوب بيع مباشر';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'مندوب البيع المباشر غير صالح';
    END IF;

    IF v_vehicle.driver_id<>p_rep_id THEN
      RAISE EXCEPTION 'المركبة لا تتبع مندوب البيع المباشر المحدد';
    END IF;

    IF v_rep.default_branch_id IS NOT NULL THEN
      IF v_rep.default_branch_id<>p_from_id THEN
        RAISE EXCEPTION 'الفرع المصدر غير مسموح لمندوب البيع المباشر';
      END IF;
    ELSIF NOT (
      v_rep.allowed_branch_ids IS NULL
      OR v_rep.allowed_branch_ids='[]'::jsonb
      OR coalesce(trim(both '"' from v_rep.allowed_branch_ids::text),'')='*'
    ) THEN
      SELECT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=p_from_id
          AND b.company_id=p_company_id
          AND (
            (
              jsonb_typeof(v_rep.allowed_branch_ids)='array'
              AND (
                v_rep.allowed_branch_ids @> jsonb_build_array(b.branch_code)
                OR v_rep.allowed_branch_ids @> jsonb_build_array(b.id::text)
              )
            )
            OR (
              jsonb_typeof(v_rep.allowed_branch_ids)='string'
              AND lower(trim(both '"' from v_rep.allowed_branch_ids::text))
                  = lower(b.branch_code)
            )
          )
      ) INTO v_allowed;

      IF NOT v_allowed THEN
        RAISE EXCEPTION 'الفرع المصدر غير مسموح لمندوب البيع المباشر';
      END IF;
    END IF;

  ELSIF v_voucher.type='DirectReturn' THEN
    IF p_from_type<>'Vehicle' OR p_to_type<>'Branch' THEN
      RAISE EXCEPTION 'المرتجع المباشر يجب أن يكون مركبة إلى فرع';
    END IF;

    IF p_rep_id IS NULL THEN
      RAISE EXCEPTION 'مندوب البيع المباشر مطلوب';
    END IF;

    SELECT * INTO v_rep
    FROM public.users u
    WHERE u.id=p_rep_id
      AND u.company_id=p_company_id
      AND coalesce(u.status,'Active')='Active'
      AND u.role='مندوب بيع مباشر';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'مندوب البيع المباشر غير صالح';
    END IF;

    IF v_vehicle.driver_id<>p_rep_id THEN
      RAISE EXCEPTION 'المركبة لا تتبع مندوب البيع المباشر المحدد';
    END IF;

  ELSIF v_voucher.type='SupplierReturn' THEN
    IF p_from_type<>'Branch' OR p_to_type<>'Supplier' THEN
      RAISE EXCEPTION 'مرتجع المورد يجب أن يكون فرعاً إلى مورد';
    END IF;

    IF NOT EXISTS(
      SELECT 1
      FROM public.purchase_orders po
      WHERE po.company_id=p_company_id
        AND po.supplier_id=p_to_id
        AND po.branch_id=p_from_id
    ) THEN
      RAISE EXCEPTION 'لا توجد علاقة موثقة بين المورد والفرع';
    END IF;
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
    OR (
      v_voucher.type IN ('Transfer','DirectReturn')
      AND v_actor.role='مخزني'
      AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
    )
  ) THEN

    IF p_from_type='Branch' THEN
      SELECT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=p_from_id
          AND b.company_id=p_company_id
          AND b.is_active=true
          AND (
            (
              jsonb_typeof(v_actor.allowed_branch_ids)='array'
              AND (
                v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
                OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
              )
            )
            OR (
              jsonb_typeof(v_actor.allowed_branch_ids)='string'
              AND trim(both '"' from v_actor.allowed_branch_ids::text)
                  IN (b.branch_code,b.id::text,'*')
            )
          )
      ) INTO v_allowed;

      IF NOT v_allowed THEN
        RAISE EXCEPTION 'فرع المصدر خارج نطاق المستخدم';
      END IF;
    END IF;

    IF p_to_type='Branch' THEN
      SELECT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=p_to_id
          AND b.company_id=p_company_id
          AND b.is_active=true
          AND (
            (
              jsonb_typeof(v_actor.allowed_branch_ids)='array'
              AND (
                v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
                OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
              )
            )
            OR (
              jsonb_typeof(v_actor.allowed_branch_ids)='string'
              AND trim(both '"' from v_actor.allowed_branch_ids::text)
                  IN (b.branch_code,b.id::text,'*')
            )
          )
      ) INTO v_allowed;

      IF NOT v_allowed THEN
        RAISE EXCEPTION 'فرع الوجهة خارج نطاق المستخدم';
      END IF;
    END IF;
  END IF;

  FOR v_item IN
    SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    IF nullif(btrim(v_item->>'itemCode'),'') IS NULL THEN
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
  END LOOP;

  v_fingerprint:=md5(
    jsonb_build_object(
      'voucher_id',v_voucher.id,
      'type',v_voucher.type,
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

  SELECT * INTO v_operation
  FROM public.stock_voucher_operations
  WHERE company_id=p_company_id
    AND operation_id=btrim(p_operation_id)
  FOR UPDATE;

  IF FOUND THEN
    IF v_operation.fingerprint<>v_fingerprint THEN
      RAISE EXCEPTION 'operation_id مستخدم مع بيانات مختلفة';
    END IF;

    IF v_operation.voucher_id IS NOT NULL
       AND v_operation.voucher_id<>v_voucher.id THEN
      RAISE EXCEPTION 'operation_id مرتبط بإذن آخر';
    END IF;

    RETURN jsonb_build_object(
      'success',true,
      'duplicate',true,
      'voucher_id',v_voucher.id,
      'voucher_code',p_voucher_code,
      'operation_id',btrim(p_operation_id)
    );
  END IF;

  INSERT INTO public.stock_voucher_operations(
    company_id,operation_id,fingerprint,voucher_id
  )
  VALUES(
    p_company_id,btrim(p_operation_id),v_fingerprint,v_voucher.id
  );

  UPDATE public.stock_vouchers
  SET reference=btrim(p_reference),
      from_type=p_from_type,
      from_id=p_from_id,
      to_type=p_to_type,
      to_id=p_to_id,
      notes=coalesce(p_notes,''),
      custodian_user_id=CASE
        WHEN v_voucher.type IN ('DirectSale','DirectReturn')
          THEN p_rep_id
        ELSE custodian_user_id
      END,
      updated_at=now()
  WHERE id=v_voucher.id
    AND company_id=p_company_id
    AND status='Draft';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'فشل تحديث رأس الإذن';
  END IF;

  DELETE FROM public.stock_voucher_details
  WHERE voucher_id=v_voucher.id;

  FOR v_item IN
    SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    SELECT i.id INTO v_item_id
    FROM public.items i
    WHERE i.item_code=v_item->>'itemCode';

    INSERT INTO public.stock_voucher_details(
      id,voucher_id,item_id,item_code,item_name,unit,qty,unit_price,notes,created_at
    )
    VALUES(
      gen_random_uuid(),
      v_voucher.id,
      v_item_id,
      v_item->>'itemCode',
      coalesce(nullif(v_item->>'itemName',''),v_item->>'itemCode'),
      coalesce(nullif(v_item->>'unit',''),'حبة'),
      (v_item->>'qty')::numeric,
      coalesce((v_item->>'unitPrice')::numeric,0),
      coalesce(v_item->>'notes',''),
      now()
    );
  END LOOP;

  RETURN jsonb_build_object(
    'success',true,
    'duplicate',false,
    'voucher_id',v_voucher.id,
    'voucher_code',p_voucher_code,
    'operation_id',btrim(p_operation_id),
    'status','Draft'
  );
END;
$function$

