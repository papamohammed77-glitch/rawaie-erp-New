-- RAWAEA ERP — DirectSale representative identity/permission guard
-- Closure unit: warehouse vouchers / DirectSale
-- Purpose:
--   1) expose only active same-company Direct Sales Reps that are actually
--      allowed into the Van Sales application to warehouse voucher operators;
--   2) enforce the same contract server-side before DirectSale/DirectReturn
--      voucher creation;
--   3) preserve the existing 12-argument RPC contract and central stock engine.
-- No new Edge Function. No Physical Stock writer added.

BEGIN;

ALTER POLICY users_select_direct_reps_warehouse
ON public.users
USING (
  company_id = app_private.current_user_company_id()
  AND COALESCE(status,'Active') = 'Active'
  AND role = 'مندوب بيع مباشر'
  AND app_private.current_user_has_permission('warehouse')
  AND COALESCE(permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
);

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
  PERFORM set_config('app.user_email',COALESCE(p_created_by,''),true);

  SELECT *
    INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_created_by)
    AND COALESCE(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'منشئ الإذن غير صالح ضمن الشركة';
  END IF;

  IF p_type IN ('DirectSale','DirectReturn') THEN
    IF p_rep_id IS NULL THEN
      RAISE EXCEPTION 'مندوب البيع المباشر مطلوب';
    END IF;

    SELECT *
      INTO v_rep
    FROM public.users u
    WHERE u.company_id=p_company_id
      AND u.id=p_rep_id
      AND COALESCE(u.status,'Active')='Active'
      AND u.role='مندوب بيع مباشر'
      AND COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'مندوب البيع المباشر غير صالح أو لا يملك صلاحية تطبيق البيع المباشر';
    END IF;
  END IF;

  IF NOT (
    COALESCE(v_actor.permissions,'[]'::jsonb) @> '["*"]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR COALESCE(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
  ) THEN
    IF p_type='Transfer' THEN
      FOR v_branch_id IN SELECT unnest(ARRAY[p_from_id,p_to_id]) LOOP
        SELECT EXISTS(
          SELECT 1
          FROM public.branches b
          WHERE b.id=v_branch_id
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
        ) INTO v_ok;

        IF NOT v_ok THEN
          RAISE EXCEPTION 'الفرع خارج نطاق فروع المستخدم المسموح بها';
        END IF;
      END LOOP;

    ELSIF p_type IN ('DirectSale','SupplierReturn') THEN
      SELECT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=p_from_id
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
      ) INTO v_ok;

      IF NOT v_ok THEN
        RAISE EXCEPTION 'فرع المصدر خارج نطاق فروع المستخدم المسموح بها';
      END IF;

    ELSIF p_type='DirectReturn' THEN
      SELECT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=p_to_id
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
      ) INTO v_ok;

      IF NOT v_ok THEN
        RAISE EXCEPTION 'فرع استلام المرتجع المباشر خارج نطاق فروع المستخدم المسموح بها';
      END IF;
    END IF;
  END IF;

  RETURN public.create_manual_stock_voucher_atomic_core_12_20260828(
    p_company_id,p_type,p_reference,p_from_type,p_from_id,
    p_to_type,p_to_id,p_notes,p_created_by,p_items,p_rep_id,p_operation_id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.create_manual_stock_voucher_atomic(
  uuid,text,text,text,uuid,text,uuid,text,text,jsonb,uuid,text
) FROM public, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.create_manual_stock_voucher_atomic(
  uuid,text,text,text,uuid,text,uuid,text,text,jsonb,uuid,text
) TO service_role;

COMMIT;
