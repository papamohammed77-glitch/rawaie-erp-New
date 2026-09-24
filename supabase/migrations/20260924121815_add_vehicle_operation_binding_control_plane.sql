-- RAWAEA ERP — Vehicle Operation Binding Control Plane
-- Production migration executed 2026-09-24.
-- Scope: bind fleet vehicles to Runsheets, Branch Transfers and Direct Sales
-- without introducing a second Physical Stock engine.
-- Physical Stock remains: post_stock_movement -> stock_branches + inventory_log.

BEGIN;

ALTER TABLE public.stock_vouchers
  ADD COLUMN IF NOT EXISTS vehicle_id uuid,
  ADD COLUMN IF NOT EXISTS driver_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='stock_vouchers_vehicle_fk'
      AND conrelid='public.stock_vouchers'::regclass
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_vehicle_fk
      FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id)
      ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='stock_vouchers_driver_fk'
      AND conrelid='public.stock_vouchers'::regclass
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_driver_fk
      FOREIGN KEY (driver_id) REFERENCES public.users(id)
      ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='stock_vouchers_transfer_vehicle_driver_ck'
      AND conrelid='public.stock_vouchers'::regclass
  ) THEN
    ALTER TABLE public.stock_vouchers
      ADD CONSTRAINT stock_vouchers_transfer_vehicle_driver_ck
      CHECK (
        type <> 'Transfer'
        OR (
          (vehicle_id IS NULL AND driver_id IS NULL)
          OR
          (vehicle_id IS NOT NULL AND driver_id IS NOT NULL)
        )
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_stock_vouchers_company_vehicle
  ON public.stock_vouchers(company_id,vehicle_id,created_at DESC);

CREATE INDEX IF NOT EXISTS idx_stock_vouchers_company_transfer_driver
  ON public.stock_vouchers(company_id,driver_id,created_at DESC);

COMMENT ON COLUMN public.stock_vouchers.vehicle_id IS
  'Operational fleet vehicle assigned to a Branch Transfer. DirectSale uses to_type=Vehicle/to_id; Runsheet uses runsheets.vehicle_id.';

COMMENT ON COLUMN public.stock_vouchers.driver_id IS
  'Operational driver responsible for a Branch Transfer. DirectSale custody remains custodian_user_id.';

CREATE OR REPLACE FUNCTION public.enforce_stock_voucher_transfer_vehicle_context()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_vehicle public.vehicles%ROWTYPE;
  v_driver public.users%ROWTYPE;
BEGIN
  IF NEW.type <> 'Transfer' THEN
    IF NEW.vehicle_id IS NOT NULL OR NEW.driver_id IS NOT NULL THEN
      RAISE EXCEPTION 'vehicle_id/driver_id are supported only for Branch Transfer vouchers';
    END IF;
    RETURN NEW;
  END IF;

  IF NEW.vehicle_id IS NULL AND NEW.driver_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.vehicle_id IS NULL OR NEW.driver_id IS NULL THEN
    RAISE EXCEPTION 'Branch Transfer vehicle and driver must be provided together';
  END IF;

  IF NEW.company_id IS NULL THEN
    RAISE EXCEPTION 'Company context is required for Branch Transfer vehicle assignment';
  END IF;

  SELECT * INTO v_vehicle
  FROM public.vehicles v
  WHERE v.id=NEW.vehicle_id AND v.company_id=NEW.company_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transfer vehicle does not belong to the voucher company';
  END IF;

  SELECT * INTO v_driver
  FROM public.users u
  WHERE u.id=NEW.driver_id
    AND u.company_id=NEW.company_id
    AND COALESCE(u.status,'Active')='Active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transfer driver does not belong to the voucher company';
  END IF;

  IF TG_OP='UPDATE'
     AND OLD.status IN ('Sent','Received','Completed')
     AND OLD.vehicle_id IS NOT NULL
     AND (
       NEW.vehicle_id IS DISTINCT FROM OLD.vehicle_id
       OR NEW.driver_id IS DISTINCT FROM OLD.driver_id
     ) THEN
    RAISE EXCEPTION 'Executed Branch Transfer vehicle/driver identity is immutable';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_stock_vouchers_transfer_vehicle_context
ON public.stock_vouchers;

CREATE TRIGGER trg_stock_vouchers_transfer_vehicle_context
BEFORE INSERT OR UPDATE OF type,company_id,vehicle_id,driver_id,status
ON public.stock_vouchers
FOR EACH ROW
EXECUTE FUNCTION public.enforce_stock_voucher_transfer_vehicle_context();

-- Add VEHICLE_OPERATION_BIND to the existing fleet control plane.
DO $$
DECLARE
  v_def text;
  v_new text;
  v_marker text;
  v_code text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='fleet_command_atomic'
  LIMIT 1;

  IF v_def IS NULL THEN RAISE EXCEPTION 'fleet_command_atomic not found'; END IF;

  IF strpos(v_def,'v_command=''VEHICLE_OPERATION_BIND''')=0 THEN
    v_code := $cmd$
  ELSIF v_command='VEHICLE_OPERATION_BIND' THEN
    DECLARE
      v_operation_type text := upper(btrim(coalesce(p_payload->>'operation_type','')));
      v_vehicle_bind_id uuid := NULLIF(btrim(p_payload->>'vehicle_id'),'')::uuid;
      v_runsheet_id uuid := NULLIF(btrim(p_payload->>'runsheet_id'),'')::uuid;
      v_voucher_id uuid := NULLIF(btrim(p_payload->>'voucher_id'),'')::uuid;
      v_driver_user_id uuid := NULLIF(btrim(p_payload->>'driver_user_id'),'')::uuid;
      v_delivery_rep_user_id uuid := NULLIF(btrim(p_payload->>'delivery_rep_user_id'),'')::uuid;
      v_direct_sales_rep_id uuid := NULLIF(btrim(p_payload->>'direct_sales_rep_id'),'')::uuid;
      v_voucher public.stock_vouchers%ROWTYPE;
      v_rs public.runsheets%ROWTYPE;
      v_driver_name text;
      v_delivery_name text;
      v_rep_name text;
      v_manage jsonb;
    BEGIN
      IF v_vehicle_bind_id IS NULL THEN RAISE EXCEPTION 'المركبة مطلوبة لربط العملية'; END IF;

      SELECT * INTO v_vehicle2
      FROM public.vehicles
      WHERE id=v_vehicle_bind_id AND company_id=p_company_id
      FOR UPDATE;

      IF NOT FOUND THEN RAISE EXCEPTION 'المركبة غير موجودة ضمن الشركة'; END IF;
      IF lower(coalesce(v_vehicle2.status,'Active')) IN ('inactive','retired','maintenance','out_of_service') THEN
        RAISE EXCEPTION 'المركبة غير متاحة للتشغيل: %',coalesce(v_vehicle2.status,'NULL');
      END IF;

      IF v_operation_type='RUNSHEET' THEN
        IF v_runsheet_id IS NULL THEN RAISE EXCEPTION 'الرانشيت مطلوب'; END IF;

        SELECT * INTO v_runsheet
        FROM public.runsheets
        WHERE id=v_runsheet_id AND company_id=p_company_id
        FOR UPDATE;

        IF NOT FOUND THEN RAISE EXCEPTION 'الرانشيت غير موجود'; END IF;
        IF v_runsheet.status NOT IN ('Open','Confirmed') THEN
          RAISE EXCEPTION 'لا يمكن ربط مركبة برانشيت في الحالة: %',v_runsheet.status;
        END IF;

        IF v_driver_user_id IS NULL THEN v_driver_user_id:=v_runsheet.driver_id; END IF;

        IF v_delivery_rep_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_delivery_rep_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND (u.role IN ('مندوب توصيل','مشرف توصيل')
                 OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb)
        ) THEN
          RAISE EXCEPTION 'مندوب التوصيل غير صالح للشركة';
        END IF;

        v_manage:=public.manage_runsheet_atomic(
          p_company_id,v_runsheet.runsheet_code,'UPDATE',
          COALESCE(p_actor_email,v_actor.email),
          v_driver_user_id,v_vehicle_bind_id
        );

        IF v_delivery_rep_user_id IS NOT NULL THEN
          UPDATE public.runsheets
          SET deliverer_id=v_delivery_rep_user_id,updated_at=now()
          WHERE id=v_runsheet.id
            AND company_id=p_company_id
            AND status IN ('Open','Confirmed');

          IF NOT FOUND THEN RAISE EXCEPTION 'تعذر حفظ مندوب التوصيل للرانشيت'; END IF;
        END IF;

        SELECT coalesce(u.name,u.email) INTO v_driver_name
        FROM public.users u
        WHERE u.id=(SELECT driver_id FROM public.runsheets WHERE id=v_runsheet.id);

        SELECT coalesce(u.name,u.email) INTO v_delivery_name
        FROM public.users u
        WHERE u.id=(SELECT deliverer_id FROM public.runsheets WHERE id=v_runsheet.id);

        PERFORM set_config('request.jwt.claims',jsonb_build_object('email',v_actor.email)::text,true);

        v_response:=v_manage || jsonb_build_object(
          'command','VEHICLE_OPERATION_BIND',
          'operation_type','RUNSHEET',
          'runsheet_id',v_runsheet.id,
          'runsheet_code',v_runsheet.runsheet_code,
          'vehicle_id',v_vehicle_bind_id,
          'driver_user_id',(SELECT driver_id FROM public.runsheets WHERE id=v_runsheet.id),
          'driver_name',v_driver_name,
          'delivery_rep_user_id',(SELECT deliverer_id FROM public.runsheets WHERE id=v_runsheet.id),
          'delivery_rep_name',v_delivery_name
        );

      ELSIF v_operation_type='BRANCH_TRANSFER' THEN
        IF v_voucher_id IS NULL THEN RAISE EXCEPTION 'إذن تحويل الفرع مطلوب'; END IF;
        IF v_driver_user_id IS NULL THEN RAISE EXCEPTION 'سائق تحويل الفرع مطلوب'; END IF;

        SELECT * INTO v_voucher
        FROM public.stock_vouchers
        WHERE id=v_voucher_id AND company_id=p_company_id
        FOR UPDATE;

        IF NOT FOUND THEN RAISE EXCEPTION 'إذن التحويل غير موجود'; END IF;
        IF v_voucher.type<>'Transfer' THEN RAISE EXCEPTION 'الوثيقة المحددة ليست تحويل فرع'; END IF;

        IF NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id AND u.company_id=p_company_id
          AND COALESCE(u.status,'Active')='Active'
        ) THEN
          RAISE EXCEPTION 'سائق التحويل غير صالح للشركة';
        END IF;

        IF v_voucher.vehicle_id IS NOT NULL
           AND (
             v_voucher.vehicle_id IS DISTINCT FROM v_vehicle_bind_id
             OR v_voucher.driver_id IS DISTINCT FROM v_driver_user_id
           )
           AND v_voucher.status<>'Draft' THEN
          RAISE EXCEPTION 'تحويل الفرع المنفذ لا يمكن تغيير هوية مركبته/سائقه';
        END IF;

        PERFORM set_config('request.jwt.claims',jsonb_build_object('email',v_actor.email)::text,true);

        UPDATE public.stock_vouchers
        SET vehicle_id=v_vehicle_bind_id,driver_id=v_driver_user_id,updated_at=now()
        WHERE id=v_voucher.id AND company_id=p_company_id;

        IF NOT FOUND THEN RAISE EXCEPTION 'فشل ربط المركبة بتحويل الفرع'; END IF;

        SELECT coalesce(u.name,u.email) INTO v_driver_name
        FROM public.users u WHERE u.id=v_driver_user_id;

        v_response:=jsonb_build_object(
          'success',true,'command','VEHICLE_OPERATION_BIND',
          'operation_type','BRANCH_TRANSFER',
          'voucher_id',v_voucher.id,'voucher_code',v_voucher.voucher_code,
          'vehicle_id',v_vehicle_bind_id,'driver_user_id',v_driver_user_id,
          'driver_name',v_driver_name,
          'status',(SELECT status FROM public.stock_vouchers WHERE id=v_voucher.id)
        );

      ELSIF v_operation_type='DIRECT_SALE' THEN
        IF v_voucher_id IS NULL THEN RAISE EXCEPTION 'إذن البيع المباشر مطلوب'; END IF;

        SELECT * INTO v_voucher
        FROM public.stock_vouchers
        WHERE id=v_voucher_id AND company_id=p_company_id
        FOR UPDATE;

        IF NOT FOUND THEN RAISE EXCEPTION 'إذن البيع المباشر غير موجود'; END IF;
        IF v_voucher.type<>'DirectSale' THEN RAISE EXCEPTION 'الوثيقة المحددة ليست بيعًا مباشرًا'; END IF;

        IF v_direct_sales_rep_id IS NULL THEN
          v_direct_sales_rep_id:=v_voucher.custodian_user_id;
        END IF;

        IF v_direct_sales_rep_id IS NULL OR NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_direct_sales_rep_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND u.role='مندوب بيع مباشر'
        ) THEN
          RAISE EXCEPTION 'مندوب البيع المباشر غير صالح للشركة';
        END IF;

        PERFORM set_config('request.jwt.claims',jsonb_build_object('email',v_actor.email)::text,true);

        IF v_voucher.status='Draft' THEN
          UPDATE public.stock_vouchers
          SET to_type='Vehicle',to_id=v_vehicle_bind_id,
              custodian_user_id=v_direct_sales_rep_id,updated_at=now()
          WHERE id=v_voucher.id AND company_id=p_company_id AND status='Draft';
        ELSE
          IF v_voucher.to_type<>'Vehicle'
             OR v_voucher.to_id IS DISTINCT FROM v_vehicle_bind_id
             OR v_voucher.custodian_user_id IS DISTINCT FROM v_direct_sales_rep_id THEN
            RAISE EXCEPTION 'البيع المباشر المنفذ مرتبط بالفعل بمركبة/مندوب مختلف';
          END IF;
        END IF;

        SELECT coalesce(u.name,u.email) INTO v_rep_name
        FROM public.users u WHERE u.id=v_direct_sales_rep_id;

        v_response:=jsonb_build_object(
          'success',true,'command','VEHICLE_OPERATION_BIND',
          'operation_type','DIRECT_SALE',
          'voucher_id',v_voucher.id,'voucher_code',v_voucher.voucher_code,
          'vehicle_id',v_vehicle_bind_id,
          'direct_sales_rep_id',v_direct_sales_rep_id,
          'direct_sales_rep_name',v_rep_name,
          'status',(SELECT status FROM public.stock_vouchers WHERE id=v_voucher.id)
        );

      ELSE
        RAISE EXCEPTION 'نوع ربط العملية غير مدعوم: %',v_operation_type;
      END IF;
    END;
$cmd$;

    v_marker:='  ELSIF v_command=''STATUS_CHANGE'' THEN';
    IF strpos(v_def,v_marker)=0 THEN RAISE EXCEPTION 'STATUS_CHANGE marker not found'; END IF;
    v_new:=replace(v_def,v_marker,v_code||E'\n'||v_marker);
    IF v_new=v_def THEN RAISE EXCEPTION 'fleet_command patch produced no change'; END IF;
    EXECUTE v_new;
  END IF;
END $$;

-- Add operation projections to vehicle_detail and a read model for the binding modal.
DO $$
DECLARE
  v_def text;
  v_new text;
  v_old text;
  v_view_marker text;
  v_insert text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='fleet_query'
  LIMIT 1;

  IF v_def IS NULL THEN RAISE EXCEPTION 'fleet_query not found'; END IF;

  v_old := $q$
      'runsheets',(SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY r.run_date DESC),'[]'::jsonb) FROM public.runsheets r WHERE r.vehicle_id=v_vehicle_id AND r.company_id=p_company_id LIMIT 50),
      'expenses',$q$;

  v_new := $q$
      'runsheets',(SELECT COALESCE(jsonb_agg(
        to_jsonb(r) ||
        jsonb_build_object(
          'driver_name',coalesce(du.name,du.email),
          'delivery_rep_name',coalesce(deu.name,deu.email)
        ) ORDER BY r.run_date DESC
      ),'[]'::jsonb)
      FROM public.runsheets r
      LEFT JOIN public.users du ON du.id=r.driver_id AND du.company_id=p_company_id
      LEFT JOIN public.users deu ON deu.id=r.deliverer_id AND deu.company_id=p_company_id
      WHERE r.vehicle_id=v_vehicle_id AND r.company_id=p_company_id
      LIMIT 50),
      'transfer_operations',(SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id',sv.id,'voucher_code',sv.voucher_code,'status',sv.status,
          'reference',sv.reference,'operation_date',sv.voucher_date,
          'vehicle_id',sv.vehicle_id,'driver_id',sv.driver_id,
          'driver_name',coalesce(du.name,du.email),
          'from_branch_name',fb.name,'to_branch_name',tb.name
        ) ORDER BY sv.voucher_date DESC,sv.created_at DESC
      ),'[]'::jsonb)
      FROM public.stock_vouchers sv
      LEFT JOIN public.users du ON du.id=sv.driver_id AND du.company_id=p_company_id
      LEFT JOIN public.branches fb ON fb.id=sv.from_id AND fb.company_id=p_company_id
      LEFT JOIN public.branches tb ON tb.id=sv.to_id AND tb.company_id=p_company_id
      WHERE sv.company_id=p_company_id AND sv.type='Transfer'
        AND sv.vehicle_id=v_vehicle_id
      LIMIT 50),
      'direct_sales',(SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id',sv.id,'voucher_code',sv.voucher_code,'status',sv.status,
          'reference',sv.reference,'operation_date',sv.voucher_date,
          'vehicle_id',sv.to_id,'direct_sales_rep_id',sv.custodian_user_id,
          'direct_sales_rep_name',coalesce(rep.name,rep.email)
        ) ORDER BY sv.voucher_date DESC,sv.created_at DESC
      ),'[]'::jsonb)
      FROM public.stock_vouchers sv
      LEFT JOIN public.users rep ON rep.id=sv.custodian_user_id AND rep.company_id=p_company_id
      WHERE sv.company_id=p_company_id AND sv.type='DirectSale'
        AND sv.to_type='Vehicle' AND sv.to_id=v_vehicle_id
      LIMIT 50),
      'expenses',$q$;

  IF strpos(v_def,v_old)=0 THEN
    RAISE EXCEPTION 'vehicle_detail runsheet projection marker not found';
  END IF;

  v_new:=replace(v_def,v_old,v_new);

  IF strpos(v_def,'v_view=''vehicle_operation_candidates''')=0 THEN
    v_view_marker:='  ELSIF v_view=''drivers'' THEN';

    v_insert := $view$
  ELSIF v_view='vehicle_operation_candidates' THEN
    DECLARE
      v_candidate_vehicle_id uuid := NULLIF(btrim(p_payload->>'vehicle_id'),'')::uuid;
    BEGIN
      IF v_candidate_vehicle_id IS NULL THEN
        RAISE EXCEPTION 'المركبة مطلوبة لعرض العمليات المتاحة';
      END IF;

      IF NOT EXISTS(
        SELECT 1 FROM public.vehicles v
        WHERE v.id=v_candidate_vehicle_id AND v.company_id=p_company_id
      ) THEN
        RAISE EXCEPTION 'المركبة غير موجودة ضمن الشركة';
      END IF;

      SELECT jsonb_build_object(
        'success',true,
        'vehicle_id',v_candidate_vehicle_id,
        'runsheets',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.run_date DESC,x.runsheet_code DESC),'[]'::jsonb)
          FROM (
            SELECT r.id,r.runsheet_code,r.run_date,r.status,r.vehicle_id,r.driver_id,r.deliverer_id,
              coalesce(du.name,du.email) driver_name,
              coalesce(deu.name,deu.email) delivery_rep_name
            FROM public.runsheets r
            LEFT JOIN public.users du ON du.id=r.driver_id AND du.company_id=p_company_id
            LEFT JOIN public.users deu ON deu.id=r.deliverer_id AND deu.company_id=p_company_id
            WHERE r.company_id=p_company_id AND r.status IN ('Open','Confirmed')
            ORDER BY r.run_date DESC,r.runsheet_code DESC LIMIT 50
          ) x),
        'transfers',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.voucher_date DESC,x.voucher_code DESC),'[]'::jsonb)
          FROM (
            SELECT sv.id,sv.voucher_code,sv.voucher_date,sv.status,sv.reference,
              sv.vehicle_id,sv.driver_id,coalesce(du.name,du.email) driver_name,
              coalesce(vv.vehicle_code,vv.license_plate) current_vehicle_code
            FROM public.stock_vouchers sv
            LEFT JOIN public.users du ON du.id=sv.driver_id AND du.company_id=p_company_id
            LEFT JOIN public.vehicles vv ON vv.id=sv.vehicle_id AND vv.company_id=p_company_id
            WHERE sv.company_id=p_company_id AND sv.type='Transfer' AND sv.status<>'Cancelled'
            ORDER BY sv.voucher_date DESC,sv.voucher_code DESC LIMIT 50
          ) x),
        'direct_sales',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.voucher_date DESC,x.voucher_code DESC),'[]'::jsonb)
          FROM (
            SELECT sv.id,sv.voucher_code,sv.voucher_date,sv.status,sv.reference,
              sv.to_id vehicle_id,sv.custodian_user_id direct_sales_rep_id,
              coalesce(rep.name,rep.email) direct_sales_rep_name,
              coalesce(vv.vehicle_code,vv.license_plate) current_vehicle_code
            FROM public.stock_vouchers sv
            LEFT JOIN public.users rep ON rep.id=sv.custodian_user_id AND rep.company_id=p_company_id
            LEFT JOIN public.vehicles vv ON vv.id=sv.to_id AND vv.company_id=p_company_id
            WHERE sv.company_id=p_company_id AND sv.type='DirectSale'
              AND sv.to_type='Vehicle' AND sv.status<>'Cancelled'
            ORDER BY sv.voucher_date DESC,sv.voucher_code DESC LIMIT 50
          ) x),
        'drivers',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.name),'[]'::jsonb)
          FROM (
            SELECT u.id,u.name,u.email,u.role
            FROM public.users u
            WHERE u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active'
              AND (
                u.role IN ('سائق','مندوب توصيل','مشرف توصيل')
                OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
              )
            ORDER BY u.name,u.email LIMIT 100
          ) x),
        'delivery_reps',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.name),'[]'::jsonb)
          FROM (
            SELECT u.id,u.name,u.email,u.role
            FROM public.users u
            WHERE u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active'
              AND (
                u.role IN ('مندوب توصيل','مشرف توصيل')
                OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
              )
            ORDER BY u.name,u.email LIMIT 100
          ) x),
        'direct_sales_reps',(SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.name),'[]'::jsonb)
          FROM (
            SELECT u.id,u.name,u.email,u.role
            FROM public.users u
            WHERE u.company_id=p_company_id AND COALESCE(u.status,'Active')='Active'
              AND (
                u.role='مندوب بيع مباشر'
                OR COALESCE(u.permissions,'[]'::jsonb) @> '["van-sales"]'::jsonb
              )
            ORDER BY u.name,u.email LIMIT 100
          ) x)
      ) INTO v_response;
    END;

$view$;

    IF strpos(v_def,v_view_marker)=0 THEN RAISE EXCEPTION 'fleet_query drivers marker not found'; END IF;
    v_new:=replace(v_new,v_view_marker,v_insert||E'\n'||v_view_marker);
  END IF;

  EXECUTE v_new;
END $$;

COMMIT;
