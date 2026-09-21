-- RAWAEA ERP — DirectReturn SEND authorization branch correction
-- Existing function only; no new Edge Function.
-- For DirectReturn the warehouse operator is authorized against the receiving branch,
-- while the vehicle is the physical source stock container.

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

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'سياق الشركة غير متسق مع المستخدم المنفذ';
  END IF;

  SELECT * INTO v
  FROM public.stock_vouchers
  WHERE company_id=p_company_id
    AND voucher_code=p_voucher_code
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'الإذن غير موجود';
  END IF;

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
    )
    INTO v_source
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
    SELECT 1
    FROM public.branches b
    WHERE b.id=v_auth_branch
      AND b.company_id=p_company_id
      AND b.is_active=true
  ) THEN
    RAISE EXCEPTION 'سياق الفرع التشغيلي للإذن غير صالح';
  END IF;

  IF NOT (
    coalesce(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
  ) THEN
    SELECT EXISTS(
      SELECT 1 FROM public.branches b
      WHERE b.id=v_auth_branch
        AND b.company_id=p_company_id
        AND (
          (
            jsonb_typeof(v_actor.allowed_branch_ids)='array'
            AND (
              v_actor.allowed_branch_ids @> jsonb_build_array(b.branch_code)
              OR v_actor.allowed_branch_ids @> jsonb_build_array(b.id::text)
            )
          )
          OR
          (
            jsonb_typeof(v_actor.allowed_branch_ids)='string'
            AND trim(both '"' from v_actor.allowed_branch_ids::text)
                IN (b.branch_code,b.id::text,'*')
          )
        )
    ) INTO v_allowed;

    IF NOT v_allowed THEN
      RAISE EXCEPTION 'الفرع التشغيلي للإذن خارج نطاق فروع المستخدم المسموح بها';
    END IF;
  END IF;

  RETURN public.send_stock_voucher_atomic_core_20260828(
    p_company_id,p_voucher_code,p_user_email
  );
END;
$function$;
