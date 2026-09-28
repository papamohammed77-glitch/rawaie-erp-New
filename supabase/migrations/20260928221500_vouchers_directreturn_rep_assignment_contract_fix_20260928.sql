-- RAWAEA ERP — DirectReturn representative assignment contract alignment
-- 2026-09-28
-- Surgical Production repair only.
-- No new table, no new RPC, no new Edge Function.
-- Canonical representative/vehicle relation is the active primary
-- row in fleet_vehicle_sales_rep_assignments.
-- Legacy vehicles.driver_id remains a backward-compatible fallback.

DO $outer$
DECLARE
  v_def text;
BEGIN
  SELECT pg_get_functiondef(
    'public.create_manual_stock_voucher_atomic_core_12_20260828(uuid,text,text,text,uuid,text,uuid,text,text,jsonb,uuid,text)'::regprocedure
  )
  INTO v_def;

  IF position('fleet_vehicle_sales_rep_assignments' in v_def) > 0
     AND position('v_vehicle.driver_id=v_rep_id' in v_def) = 0
  THEN
    RETURN;
  END IF;

  IF position($old$    IF v_actor.role='مندوب بيع مباشر'
       AND NOT EXISTS(
         SELECT 1
         FROM public.vehicles v
         WHERE v.id=p_from_id
           AND v.driver_id=v_actor.id
       ) THEN
      RAISE EXCEPTION 'المركبة المصدر لا تتبع مندوب البيع المباشر الحالي';
    END IF;$old$ in v_def) = 0
  THEN
    RAISE EXCEPTION 'CREATE CORE DirectReturn legacy guard not found';
  END IF;

  v_def := replace(
    v_def,
    $old$    IF v_actor.role='مندوب بيع مباشر'
       AND NOT EXISTS(
         SELECT 1
         FROM public.vehicles v
         WHERE v.id=p_from_id
           AND v.driver_id=v_actor.id
       ) THEN
      RAISE EXCEPTION 'المركبة المصدر لا تتبع مندوب البيع المباشر الحالي';
    END IF;$old$,
    $new$    IF p_rep_id IS NULL THEN
      RAISE EXCEPTION 'مندوب البيع المباشر مطلوب';
    END IF;

    IF NOT (
      EXISTS(
        SELECT 1
        FROM public.fleet_vehicle_sales_rep_assignments a
        WHERE a.company_id=p_company_id
          AND a.vehicle_id=p_from_id
          AND a.sales_rep_user_id=p_rep_id
          AND a.end_at IS NULL
          AND a.is_primary=true
      )
      OR EXISTS(
        SELECT 1
        FROM public.vehicles v
        WHERE v.id=p_from_id
          AND v.company_id=p_company_id
          AND v.driver_id=p_rep_id
      )
    ) THEN
      RAISE EXCEPTION 'المركبة المصدر لا تتبع مندوب البيع المباشر المحدد';
    END IF;$new$
  );

  EXECUTE v_def;
END
$outer$;

DO $outer$
DECLARE
  v_def text;
BEGIN
  SELECT pg_get_functiondef(
    'public.update_manual_stock_voucher_atomic(uuid,text,text,text,text,uuid,text,uuid,text,jsonb,uuid)'::regprocedure
  )
  INTO v_def;

  IF position('fleet_vehicle_sales_rep_assignments' in v_def) > 0
     AND position('v_vehicle.driver_id<>p_rep_id' in v_def) = 0
  THEN
    RETURN;
  END IF;

  IF position($old$    IF v_vehicle.driver_id<>p_rep_id THEN
      RAISE EXCEPTION 'المركبة لا تتبع مندوب البيع المباشر المحدد';
    END IF;$old$ in v_def) = 0
  THEN
    RAISE EXCEPTION 'UPDATE DirectReturn legacy guard not found';
  END IF;

  v_def := replace(
    v_def,
    $old$    IF v_vehicle.driver_id<>p_rep_id THEN
      RAISE EXCEPTION 'المركبة لا تتبع مندوب البيع المباشر المحدد';
    END IF;$old$,
    $new$    IF NOT (
      EXISTS(
        SELECT 1
        FROM public.fleet_vehicle_sales_rep_assignments a
        WHERE a.company_id=p_company_id
          AND a.vehicle_id=v_vehicle.id
          AND a.sales_rep_user_id=p_rep_id
          AND a.end_at IS NULL
          AND a.is_primary=true
      )
      OR v_vehicle.driver_id=p_rep_id
    ) THEN
      RAISE EXCEPTION 'المركبة لا تتبع مندوب البيع المباشر المحدد';
    END IF;$new$
  );

  EXECUTE v_def;
END
$outer$;
