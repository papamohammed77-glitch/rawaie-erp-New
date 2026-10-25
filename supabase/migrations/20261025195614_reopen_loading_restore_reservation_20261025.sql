-- RAWAEA ERP: restore the consumed reservation when reopening a Loaded runsheet.
-- Root cause: the reopen Core reverses physical Loading with Unloading, but the
-- central movement engine intentionally does not recreate allocated_qty.
-- Re-reserve exactly the quantity reversed for each item so the next Loading
-- cycle can consume the reservation again. All operations remain in one DB txn.
CREATE OR REPLACE FUNCTION public.complete_runsheet_reopen_loading(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  r public.runsheets%ROWTYPE;
  v public.vehicles%ROWTYPE;
  m uuid;
  van uuid;
  d record;
  k text;
  ex integer;
  old_cycle uuid;
  new_cycle uuid;
  total numeric := 0;
BEGIN
  IF p_company_id IS NULL
     OR NULLIF(btrim(p_runsheet_code), '') IS NULL
     OR NULLIF(btrim(p_user_email), '') IS NULL
     OR NULLIF(btrim(p_operation_id), '') IS NULL THEN
    RAISE EXCEPTION 'invalid reopen-loading request';
  END IF;

  SELECT *
    INTO r
    FROM public.runsheets
   WHERE company_id = p_company_id
     AND runsheet_code = p_runsheet_code
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'runsheet not found';
  END IF;

  k := 'TASK-028|ReopenLoading|' || p_operation_id || '|' || r.id::text;

  SELECT count(*)
    INTO ex
    FROM public.inventory_log
   WHERE company_id = p_company_id
     AND idempotency_key LIKE k || '|%';

  IF ex > 0 THEN
    RETURN jsonb_build_object(
      'success', true,
      'duplicate', true,
      'operation_id', p_operation_id
    );
  END IF;

  IF r.status <> 'Loaded' OR r.loading_cycle_id IS NULL THEN
    RAISE EXCEPTION 'runsheet not Loaded';
  END IF;

  old_cycle := r.loading_cycle_id;
  new_cycle := gen_random_uuid();

  SELECT *
    INTO v
    FROM public.vehicles
   WHERE id = r.vehicle_id
     AND company_id = p_company_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'vehicle not found';
  END IF;

  SELECT main_branch_id
    INTO STRICT m
    FROM public.app_settings
   WHERE company_id = p_company_id
   ORDER BY created_at ASC, id
   LIMIT 1;

  SELECT id
    INTO van
    FROM public.branches
   WHERE company_id = p_company_id
     AND branch_code = 'VAN-' || v.vehicle_code
     AND is_active = true
   LIMIT 1;

  IF van IS NULL THEN
    RAISE EXCEPTION 'VAN branch not found';
  END IF;

  FOR d IN
    SELECT item_id, sum(qty_loaded) AS qty_loaded
      FROM public.run_sheet_details
     WHERE runsheet_id = r.id
       AND coalesce(qty_loaded, 0) > 0
     GROUP BY item_id
     ORDER BY item_id
  LOOP
    -- Reverse the physical transfer through the single central movement engine.
    PERFORM public.post_stock_movement(
      p_company_id,
      'Unloading',
      van,
      m,
      d.item_id,
      d.qty_loaded,
      r.runsheet_code,
      r.runsheet_code || '|Reopen|' || p_operation_id || '|' ||
        old_cycle::text || '|' || d.item_id::text,
      p_user_email,
      k || '|' || d.item_id::text
    );

    -- Loading consumes allocated_qty. Reopening must restore that reservation
    -- for exactly the quantity returned to MAIN, not for the full picked qty.
    PERFORM public.reserve_stock(
      p_company_id,
      m,
      d.item_id,
      d.qty_loaded
    );

    total := total + d.qty_loaded;
  END LOOP;

  UPDATE public.runsheets
     SET status = 'Loading',
         loader_end = NULL,
         loader_start = clock_timestamp(),
         loading_cycle_id = new_cycle,
         updated_at = now()
   WHERE id = r.id
     AND company_id = p_company_id
     AND status = 'Loaded';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'reopen transition failed';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'duplicate', false,
    'reopened_total', total,
    'qty_loaded_preserved', true,
    'reservations_restored', true,
    'operation_id', p_operation_id,
    'previous_loading_cycle_id', old_cycle,
    'loading_cycle_id', new_cycle
  );
END;
$function$;
