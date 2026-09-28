-- RAWAEA ERP — Transfer source responsibility hardening
-- Migration already applied in Supabase as version 20260928132432.
-- This file records the exact production definitions for source control.

CREATE OR REPLACE FUNCTION public.enforce_transfer_responsibility_contract()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  actor public.users%ROWTYPE;
  actor_email text;
  actor_id uuid;
  receiver_id uuid;
  receiver_count integer;
  branch_code text;
  admin_override boolean := false;
  source_scope_ok boolean := false;
BEGIN
  IF COALESCE(OLD.type, NEW.type) <> 'Transfer' THEN
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
  END IF;

  actor_email := NULLIF(BTRIM(current_setting('app.user_email', true)), '');

  IF actor_email IS NOT NULL THEN
    SELECT * INTO actor
    FROM public.users u
    WHERE u.company_id = COALESCE(OLD.company_id, NEW.company_id)
      AND lower(u.email) = lower(actor_email)
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
  ELSIF auth.uid() IS NOT NULL THEN
    SELECT * INTO actor
    FROM public.users u
    WHERE u.company_id = COALESCE(OLD.company_id, NEW.company_id)
      AND u.auth_id = auth.uid()
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
  END IF;

  IF FOUND THEN
    actor_id := actor.id;
    admin_override :=
      actor.role IN ('مدير النظام','مدير عام')
      OR COALESCE(actor.permissions,'[]'::jsonb) @> '[ "*" ]'::jsonb;
  END IF;

  IF actor_id IS NULL THEN
    IF auth.uid() IS NULL AND actor_email IS NULL THEN
      RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
    END IF;
    RAISE EXCEPTION 'هوية منفذ العملية غير صالحة';
  END IF;

  IF TG_OP='DELETE' THEN
    IF OLD.status <> 'Draft' THEN
      RAISE EXCEPTION 'لا يمكن حذف تحويل بعد إرساله';
    END IF;
    IF NOT admin_override
       AND lower(COALESCE(OLD.created_by,'')) <> lower(COALESCE(actor.email,'')) THEN
      RAISE EXCEPTION 'حذف تحويل الفرع متاح لمنشئ الإذن فقط';
    END IF;
    RETURN OLD;
  END IF;

  IF TG_OP<>'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF NEW.receiver_user_id IS DISTINCT FROM OLD.receiver_user_id
     AND NOT (OLD.status='Draft' AND NEW.status='Sent') THEN
    RAISE EXCEPTION 'مسؤول الاستلام لا يمكن تغييره بعد تثبيته';
  END IF;

  IF OLD.status='Draft' THEN
    IF NOT admin_override
       AND lower(COALESCE(OLD.created_by,'')) <> lower(COALESCE(actor.email,'')) THEN
      RAISE EXCEPTION 'تحويل الفرع في المسودة لا يعدله أو يرسله إلا منشئه';
    END IF;

    /*
     * Warehouse keeper source branch is immutable to the keeper's home branch
     * throughout the whole Draft lifecycle, not only at Send.
     */
    IF NOT admin_override
       AND actor.role='مخزني'
       AND COALESCE(actor.active_warehouse_role,'')='أذونات'
       AND (
         NEW.from_type<>'Branch'
         OR NEW.from_id IS NULL
         OR actor.default_branch_id IS NULL
         OR actor.default_branch_id IS DISTINCT FROM NEW.from_id
       ) THEN
      RAISE EXCEPTION 'فرع مصدر التحويل يجب أن يطابق الفرع الأساسي لمسؤول المخزن';
    END IF;

    IF NEW.status='Sent' THEN
      IF NEW.from_type<>'Branch' OR NEW.to_type<>'Branch' THEN
        RAISE EXCEPTION 'تحويل الفرع يجب أن يكون من فرع إلى فرع';
      END IF;

      /*
       * Source responsibility:
       * - warehouse keeper "أذونات": exact default/home branch only.
       * - other non-admin actors: preserve the existing allowed-branch contract.
       * Destination is intentionally NOT constrained to sender scope here.
       */
      IF NOT admin_override THEN
        IF actor.role='مخزني'
           AND COALESCE(actor.active_warehouse_role,'')='أذونات' THEN
          source_scope_ok :=
            NEW.from_id IS NOT NULL
            AND actor.default_branch_id IS NOT NULL
            AND actor.default_branch_id=NEW.from_id;
        ELSE
          source_scope_ok :=
            NEW.from_id IS NOT NULL
            AND (
              actor.default_branch_id = NEW.from_id
              OR actor.allowed_branch_ids IS NULL
              OR actor.allowed_branch_ids='[]'::jsonb
              OR COALESCE(TRIM(BOTH '"' FROM actor.allowed_branch_ids::text),'')='*'
              OR EXISTS (
                SELECT 1
                FROM public.branches sb
                WHERE sb.id=NEW.from_id
                  AND sb.company_id=NEW.company_id
                  AND (
                    (
                      jsonb_typeof(actor.allowed_branch_ids)='array'
                      AND (
                        actor.allowed_branch_ids @> jsonb_build_array(sb.branch_code)
                        OR actor.allowed_branch_ids @> jsonb_build_array(sb.id::text)
                      )
                    )
                    OR (
                      jsonb_typeof(actor.allowed_branch_ids)='string'
                      AND TRIM(BOTH '"' FROM actor.allowed_branch_ids::text)
                          IN (sb.branch_code,sb.id::text,'*')
                    )
                  )
              )
            );
        END IF;

        IF NOT source_scope_ok THEN
          RAISE EXCEPTION 'مرسل التحويل غير مخول للعمل على فرع المصدر';
        END IF;
      END IF;

      SELECT b.branch_code
      INTO branch_code
      FROM public.branches b
      WHERE b.id=NEW.to_id
        AND b.company_id=NEW.company_id
        AND b.is_active=true;

      IF branch_code IS NULL THEN
        RAISE EXCEPTION 'فرع الوجهة غير صالح';
      END IF;

      SELECT count(*)
      INTO receiver_count
      FROM public.users u
      WHERE u.company_id=NEW.company_id
        AND COALESCE(u.status,'Active')='Active'
        AND u.role='مخزني'
        AND COALESCE(u.active_warehouse_role,'')='أذونات'
        AND u.default_branch_id=NEW.to_id
        AND u.id<>actor.id
        AND (
          u.allowed_branch_ids IS NULL
          OR u.allowed_branch_ids='[]'::jsonb
          OR COALESCE(TRIM(BOTH '"' FROM u.allowed_branch_ids::text),'')='*'
          OR (
            jsonb_typeof(u.allowed_branch_ids)='array'
            AND (
              u.allowed_branch_ids @> jsonb_build_array(NEW.to_id::text)
              OR u.allowed_branch_ids @> jsonb_build_array(branch_code)
            )
          )
          OR (
            jsonb_typeof(u.allowed_branch_ids)='string'
            AND TRIM(BOTH '"' FROM u.allowed_branch_ids::text)
                IN (branch_code, NEW.to_id::text, '*')
          )
        );

      IF receiver_count=0 THEN
        RAISE EXCEPTION 'لا يوجد مسؤول استلام مخزني مفعّل ومحدد للفرع الوجهة';
      END IF;

      IF receiver_count>1 THEN
        RAISE EXCEPTION 'يوجد أكثر من مسؤول استلام للفرع الوجهة؛ عيّن مسؤولًا واحدًا من النظام الأم';
      END IF;

      SELECT u.id
      INTO receiver_id
      FROM public.users u
      WHERE u.company_id=NEW.company_id
        AND COALESCE(u.status,'Active')='Active'
        AND u.role='مخزني'
        AND COALESCE(u.active_warehouse_role,'')='أذونات'
        AND u.default_branch_id=NEW.to_id
        AND u.id<>actor.id
        AND (
          u.allowed_branch_ids IS NULL
          OR u.allowed_branch_ids='[]'::jsonb
          OR COALESCE(TRIM(BOTH '"' FROM u.allowed_branch_ids::text),'')='*'
          OR (
            jsonb_typeof(u.allowed_branch_ids)='array'
            AND (
              u.allowed_branch_ids @> jsonb_build_array(NEW.to_id::text)
              OR u.allowed_branch_ids @> jsonb_build_array(branch_code)
            )
          )
          OR (
            jsonb_typeof(u.allowed_branch_ids)='string'
            AND TRIM(BOTH '"' FROM u.allowed_branch_ids::text)
                IN (branch_code, NEW.to_id::text, '*')
          )
        )
      LIMIT 1;

      IF receiver_id IS NULL OR receiver_id=actor.id THEN
        RAISE EXCEPTION 'مسؤول الاستلام غير صالح أو مطابق لمرسل التحويل';
      END IF;

      NEW.receiver_user_id:=receiver_id;
      NEW.receiver_assigned_at:=COALESCE(OLD.receiver_assigned_at,now());
    END IF;

    RETURN NEW;
  END IF;

  IF OLD.status='Sent' THEN
    IF NEW.status IN ('Sent','Received') THEN
      IF OLD.receiver_user_id IS NULL THEN
        RAISE EXCEPTION 'تحويل الفرع بلا مسؤول استلام مثبت';
      END IF;
      IF actor.id<>OLD.receiver_user_id THEN
        RAISE EXCEPTION 'لا يملك هذا المستخدم مسؤولية استلام تحويل الفرع';
      END IF;
    END IF;

    IF NEW.status='Cancelled'
       AND NOT admin_override
       AND actor.id<>OLD.receiver_user_id
       AND lower(COALESCE(OLD.created_by,''))<>lower(COALESCE(actor.email,'')) THEN
      RAISE EXCEPTION 'إلغاء التحويل المرسل غير مصرح لهذا المستخدم';
    END IF;

    RETURN NEW;
  END IF;

  IF OLD.status='Received' AND NEW.status='Completed' THEN
    IF NOT admin_override
       AND actor.role NOT IN ('مدير مخازن','مشرف مخازن')
       AND lower(COALESCE(OLD.created_by,''))<>lower(COALESCE(actor.email,'')) THEN
      RAISE EXCEPTION 'إكمال تحويل الفرع متاح لمنشئ الإذن أو للإدارة المخزنية';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_manual_stock_voucher_atomic(p_company_id uuid, p_type text, p_reference text, p_from_type text, p_from_id uuid, p_to_type text, p_to_id uuid, p_notes text, p_created_by text, p_items jsonb, p_rep_id uuid, p_operation_id text)
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
  v_admin_override boolean := false;
BEGIN
  PERFORM set_config('app.user_email',coalesce(p_created_by,''),true);
  PERFORM set_config('app.operation_id',coalesce(btrim(p_operation_id),''),true);

  SELECT * INTO v_actor
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_created_by)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'منشئ الإذن غير صالح ضمن الشركة';
  END IF;

  v_admin_override :=
    v_actor.role IN ('مدير النظام','مدير عام')
    OR COALESCE(v_actor.permissions,'[]'::jsonb) @> '[ "*" ]'::jsonb;

  /*
   * Transfer source is the exact home/default branch of a warehouse keeper.
   * Destination remains freely selectable and is resolved to a receiver on Send.
   */
  IF p_type='Transfer'
     AND p_from_type='Branch'
     AND NOT v_admin_override
     AND v_actor.role='مخزني'
     AND COALESCE(v_actor.active_warehouse_role,'')='أذونات'
  THEN
    IF p_from_id IS NULL
       OR v_actor.default_branch_id IS NULL
       OR p_from_id IS DISTINCT FROM v_actor.default_branch_id
    THEN
      RAISE EXCEPTION 'فرع مصدر التحويل يجب أن يطابق الفرع الأساسي لمسؤول المخزن';
    END IF;
  END IF;

  IF p_type IN('DirectSale','DirectReturn') THEN
    IF p_rep_id IS NULL THEN
      RAISE EXCEPTION 'مندوب البيع المباشر مطلوب';
    END IF;

    SELECT * INTO v_rep
    FROM public.users u
    WHERE u.company_id=p_company_id
      AND u.id=p_rep_id
      AND coalesce(u.status,'Active')='Active'
      AND u.role='مندوب بيع مباشر'
      AND coalesce(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'مندوب البيع المباشر غير صالح أو لا يملك صلاحية تطبيق البيع المباشر';
    END IF;
  END IF;

  IF NOT(
    coalesce(v_actor.permissions,'[]'::jsonb) @> '[ "*" ]'::jsonb
    OR v_actor.allowed_branch_ids IS NULL
    OR v_actor.allowed_branch_ids='[]'::jsonb
    OR coalesce(trim(both '"' from v_actor.allowed_branch_ids::text),'')='*'
    OR (
      p_type IN('Transfer','DirectReturn')
      AND v_actor.role='مخزني'
      AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
      AND p_to_type='Branch'
    )
  ) THEN
    IF p_type='Transfer' THEN
      /*
       * Legacy/general scoped users keep their existing branch-scope contract.
       * The dedicated warehouse keeper exact-source rule was already enforced above.
       */
      IF NOT (
        v_actor.role='مخزني'
        AND coalesce(v_actor.active_warehouse_role,'')='أذونات'
      ) THEN
        FOR v_branch_id IN SELECT unnest(array[p_from_id,p_to_id]) LOOP
          SELECT EXISTS(
            SELECT 1
            FROM public.branches b
            WHERE b.id=v_branch_id
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
                    IN(b.branch_code,b.id::text,'*')
                )
              )
          ) INTO v_ok;

          IF NOT v_ok THEN
            RAISE EXCEPTION 'الفرع خارج نطاق فروع المستخدم المسموح بها';
          END IF;
        END LOOP;
      END IF;

    ELSIF p_type IN('DirectSale','SupplierReturn') THEN
      SELECT EXISTS(
        SELECT 1
        FROM public.branches b
        WHERE b.id=p_from_id
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
                IN(b.branch_code,b.id::text,'*')
            )
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
                IN(b.branch_code,b.id::text,'*')
            )
          )
      ) INTO v_ok;

      IF NOT v_ok THEN
        RAISE EXCEPTION 'فرع استلام المرتجع المباشر خارج نطاق فروع المستخدم المسموح بها';
      END IF;
    END IF;
  END IF;

  RETURN public.create_manual_stock_voucher_atomic_core_12_20260828(
    p_company_id,p_type,p_reference,p_from_type,p_from_id,p_to_type,p_to_id,
    p_notes,p_created_by,p_items,p_rep_id,p_operation_id
  );
END;
$function$
;