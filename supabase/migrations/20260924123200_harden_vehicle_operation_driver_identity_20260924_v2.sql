-- RAWAEA ERP — Harden the new VEHICLE_OPERATION_BIND consumer.
-- Production migration executed 2026-09-24.
BEGIN;

DO $$
DECLARE v_def text; v_new text; v_old text; v_rep text;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='fleet_command_atomic' LIMIT 1;
  IF v_def IS NULL THEN RAISE EXCEPTION 'fleet_command_atomic not found'; END IF;

  v_old := $old$
        IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
        ) THEN
          RAISE EXCEPTION 'السائق التشغيلي غير صالح للشركة';
        END IF;
$old$;

  v_rep := $new$
        IF v_driver_user_id IS NOT NULL AND NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND (
              u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
              OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
            )
        ) THEN
          RAISE EXCEPTION 'السائق التشغيلي غير صالح أو ليس هوية سائق/توصيل';
        END IF;
$rep$;

  IF strpos(v_def,v_old)=0 THEN RAISE EXCEPTION 'VEHICLE_OPERATION_BIND driver marker not found'; END IF;
  v_new:=replace(v_def,v_old,v_rep);

  v_old := $old2$
        IF NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
        ) THEN
          RAISE EXCEPTION 'سائق التحويل غير صالح للشركة';
        END IF;
$old2$;

  v_rep := $new2$
        IF NOT EXISTS(
          SELECT 1 FROM public.users u
          WHERE u.id=v_driver_user_id
            AND u.company_id=p_company_id
            AND COALESCE(u.status,'Active')='Active'
            AND (
              u.role IN ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver')
              OR COALESCE(u.permissions,'[]'::jsonb) @> '["delivery"]'::jsonb
            )
        ) THEN
          RAISE EXCEPTION 'سائق التحويل غير صالح أو ليس هوية سائق/توصيل';
        END IF;
$new2$;

  IF strpos(v_new,v_old)=0 THEN RAISE EXCEPTION 'VEHICLE_OPERATION_BIND transfer driver marker not found'; END IF;
  v_new:=replace(v_new,v_old,v_rep);

  EXECUTE v_new;
END $$;

COMMIT;
