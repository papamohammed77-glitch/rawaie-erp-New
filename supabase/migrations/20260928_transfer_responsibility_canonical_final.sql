-- RAWAEA ERP
-- Canonical replay of the final Production transfer-responsibility contract.
-- Production was applied first via migrations:
-- 20260928090051_transfer_responsibility_and_receiver_binding
-- 20260928090424_fix_transfer_receiver_uuid_selection
-- This file records the final net state without the transient PostgreSQL max(uuid) defect.

ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS receiver_user_id uuid,
  ADD COLUMN IF NOT EXISTS receiver_assigned_at timestamptz;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='stock_vouchers_receiver_user_id_fkey'
      AND conrelid='public.stock_vouchers'::regclass
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_receiver_user_id_fkey
      FOREIGN KEY (receiver_user_id)
      REFERENCES public.users(id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_stock_vouchers_transfer_receiver
  ON public.stock_vouchers(company_id,receiver_user_id,status)
  WHERE type='Transfer';

CREATE OR REPLACE FUNCTION public.enforce_transfer_responsibility_contract()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $function$
DECLARE
  actor public.users%ROWTYPE;
  actor_email text;
  actor_id uuid;
  receiver_id uuid;
  receiver_count integer;
  branch_code text;
  admin_override boolean := false;
BEGIN
  IF COALESCE(OLD.type,NEW.type)<>'Transfer' THEN
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
  END IF;

  actor_email:=NULLIF(BTRIM(current_setting('app.user_email',true)),'');
  IF actor_email IS NOT NULL THEN
    SELECT * INTO actor FROM public.users u
    WHERE u.company_id=COALESCE(OLD.company_id,NEW.company_id)
      AND lower(u.email)=lower(actor_email)
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
  ELSIF auth.uid() IS NOT NULL THEN
    SELECT * INTO actor FROM public.users u
    WHERE u.company_id=COALESCE(OLD.company_id,NEW.company_id)
      AND u.auth_id=auth.uid()
      AND COALESCE(u.status,'Active')='Active'
    LIMIT 1;
  END IF;

  IF FOUND THEN
    actor_id:=actor.id;
    admin_override:=
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
    IF OLD.status<>'Draft' THEN
      RAISE EXCEPTION 'لا يمكن حذف تحويل بعد إرساله';
    END IF;
    IF NOT admin_override
       AND lower(COALESCE(OLD.created_by,''))<>lower(COALESCE(actor.email,'')) THEN
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
       AND lower(COALESCE(OLD.created_by,''))<>lower(COALESCE(actor.email,'')) THEN
      RAISE EXCEPTION 'تحويل الفرع في المسودة لا يعدله أو يرسله إلا منشئه';
    END IF;

    IF NEW.status='Sent' THEN
      IF NEW.from_type<>'Branch' OR NEW.to_type<>'Branch' THEN
        RAISE EXCEPTION 'تحويل الفرع يجب أن يكون من فرع إلى فرع';
      END IF;

      SELECT b.branch_code INTO branch_code
      FROM public.branches b
      WHERE b.id=NEW.to_id
        AND b.company_id=NEW.company_id
        AND b.is_active=true;

      IF branch_code IS NULL THEN
        RAISE EXCEPTION 'فرع الوجهة غير صالح';
      END IF;

      SELECT count(*) INTO receiver_count
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
                IN (branch_code,NEW.to_id::text,'*')
          )
        );

      IF receiver_count=0 THEN
        RAISE EXCEPTION 'لا يوجد مسؤول استلام مخزني مفعّل ومحدد للفرع الوجهة';
      END IF;

      IF receiver_count>1 THEN
        RAISE EXCEPTION 'يوجد أكثر من مسؤول استلام للفرع الوجهة؛ عيّن مسؤولًا واحدًا من النظام الأم';
      END IF;

      SELECT u.id INTO receiver_id
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
                IN (branch_code,NEW.to_id::text,'*')
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
$function$;

DROP TRIGGER IF EXISTS trg_transfer_responsibility_contract
ON public.stock_vouchers;

CREATE TRIGGER trg_transfer_responsibility_contract
BEFORE UPDATE OR DELETE
ON public.stock_vouchers
FOR EACH ROW
EXECUTE FUNCTION public.enforce_transfer_responsibility_contract();
