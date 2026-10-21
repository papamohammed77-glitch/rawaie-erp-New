-- Preserve picker-entered notes even when the picked quantity equals the ordered quantity.
-- For shortages, keep the existing behavior: attach the note to underfilled order lines.
-- For a fully picked item with a note, persist it once on the first deterministic order line.
-- No inventory, reservation, quantity distribution, status, or ACL semantics are changed.

CREATE OR REPLACE FUNCTION public.complete_runsheet_picking(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text,
  p_items jsonb,
  p_operation_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_runsheet public.runsheets%rowtype;
  v_picker_id uuid;
  v_main_branch_id uuid;
  rec record;
  od_rec record;
  remaining numeric;
  assign_qty numeric;
  total_qty numeric;
  v_note text;
  v_note_written boolean;
  v_item_id uuid;
  v_item_identity_count integer;
  v_request_payload jsonb;
  v_existing_payload jsonb;
  v_existing_request jsonb;
  v_registry_id uuid;
  v_existing_status text;
  v_response jsonb;
BEGIN
  IF p_company_id IS NULL OR NULLIF(BTRIM(p_runsheet_code),'') IS NULL OR NULLIF(BTRIM(p_user_email),'') IS NULL THEN
    RAISE EXCEPTION 'invalid picking request';
  END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items)=0 THEN
    RAISE EXCEPTION 'p_items must be a non-empty array';
  END IF;

  SELECT u.id INTO v_picker_id
  FROM public.users u
  WHERE u.company_id=p_company_id
    AND lower(u.email)=lower(p_user_email)
    AND coalesce(u.status,'Active')='Active'
  LIMIT 1;
  IF v_picker_id IS NULL THEN RAISE EXCEPTION 'picker user not found'; END IF;

  CREATE TEMP TABLE IF NOT EXISTS _picking_input(
    item_code text PRIMARY KEY,
    picked_qty numeric,
    notes text
  ) ON COMMIT DROP;
  TRUNCATE _picking_input;

  INSERT INTO _picking_input(item_code,picked_qty,notes)
  SELECT btrim(x.item_code),
         sum(greatest(coalesce(x.picked_qty,0),0)),
         max(x.notes)
  FROM jsonb_to_recordset(p_items) AS x(item_code text,picked_qty numeric,notes text)
  WHERE NULLIF(btrim(x.item_code),'') IS NOT NULL
  GROUP BY btrim(x.item_code);

  IF NOT EXISTS(SELECT 1 FROM _picking_input) THEN
    RAISE EXCEPTION 'no valid picking items';
  END IF;

  SELECT coalesce(jsonb_agg(
           jsonb_build_object('item_code',item_code,'picked_qty',picked_qty,'notes',notes)
           ORDER BY item_code
         ),'[]'::jsonb)
  INTO v_request_payload
  FROM _picking_input;

  IF p_operation_id IS NOT NULL THEN
    INSERT INTO public.erp_operation_registry(
      company_id,operation_type,operation_key,request_payload,status
    ) VALUES (
      p_company_id,
      'complete_runsheet_picking',
      p_operation_id::text,
      jsonb_build_object(
        'runsheet_code',p_runsheet_code,
        'items',v_request_payload,
        'user_email',lower(p_user_email)
      ),
      'processing'
    )
    ON CONFLICT (company_id,operation_type,operation_key) DO NOTHING
    RETURNING id INTO v_registry_id;

    IF v_registry_id IS NULL THEN
      SELECT rr.status,rr.response_payload,rr.request_payload
      INTO v_existing_status,v_existing_payload,v_existing_request
      FROM public.erp_operation_registry rr
      WHERE rr.company_id=p_company_id
        AND rr.operation_type='complete_runsheet_picking'
        AND rr.operation_key=p_operation_id::text
      FOR UPDATE;

      IF v_existing_request <> jsonb_build_object(
        'runsheet_code',p_runsheet_code,
        'items',v_request_payload,
        'user_email',lower(p_user_email)
      ) THEN
        RAISE EXCEPTION 'idempotency key conflict: operation_id was used with a different picking request';
      END IF;

      IF v_existing_status='completed' AND v_existing_payload IS NOT NULL THEN
        RETURN v_existing_payload || jsonb_build_object('duplicate',true);
      END IF;

      IF v_existing_status='processing' THEN
        RAISE EXCEPTION 'picking operation is already processing';
      END IF;

      RAISE EXCEPTION 'invalid operation registry state';
    END IF;
  END IF;

  SELECT s.main_branch_id INTO v_main_branch_id
  FROM public.app_settings s
  WHERE s.company_id=p_company_id
  ORDER BY s.created_at ASC,s.id
  LIMIT 1;
  IF v_main_branch_id IS NULL THEN RAISE EXCEPTION 'main branch not configured'; END IF;

  SELECT * INTO v_runsheet
  FROM public.runsheets
  WHERE company_id=p_company_id
    AND runsheet_code=p_runsheet_code
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
  IF v_runsheet.status <> 'Picking' THEN RAISE EXCEPTION 'runsheet is not in Picking state'; END IF;
  IF v_runsheet.picker_id IS NOT NULL AND v_runsheet.picker_id <> v_picker_id THEN RAISE EXCEPTION 'runsheet is assigned to another picker'; END IF;

  FOR rec IN SELECT * FROM _picking_input ORDER BY item_code LOOP
    SELECT (array_agg(od.item_id))[1],count(DISTINCT od.item_id),coalesce(sum(od.qty),0)
      INTO v_item_id,v_item_identity_count,total_qty
    FROM public.order_details od
    JOIN public.orders o ON o.id=od.order_id
    WHERE o.company_id=p_company_id
      AND o.runsheet_id=v_runsheet.id
      AND od.item_code=rec.item_code;

    IF v_item_id IS NULL THEN RAISE EXCEPTION 'item reference not found in runsheet orders: %',rec.item_code; END IF;
    IF v_item_identity_count <> 1 THEN RAISE EXCEPTION 'item identity is inconsistent across runsheet orders: %',rec.item_code; END IF;
    IF rec.picked_qty > total_qty THEN RAISE EXCEPTION 'picked quantity exceeds ordered quantity for %',rec.item_code; END IF;

    IF rec.picked_qty > 0 THEN
      PERFORM public.reserve_stock(p_company_id,v_main_branch_id,v_item_id,rec.picked_qty);
    END IF;

    remaining := rec.picked_qty;
    v_note_written := false;

    FOR od_rec IN
      SELECT od.id,od.qty
      FROM public.order_details od
      JOIN public.orders o ON o.id=od.order_id
      WHERE o.company_id=p_company_id
        AND o.runsheet_id=v_runsheet.id
        AND od.item_code=rec.item_code
      ORDER BY od.created_at NULLS FIRST,od.id
      FOR UPDATE
    LOOP
      assign_qty := least(coalesce(od_rec.qty,0),greatest(remaining,0));

      IF rec.picked_qty < total_qty THEN
        -- Existing shortage behavior: retain the note on each underfilled order line.
        v_note := CASE
          WHEN assign_qty < coalesce(od_rec.qty,0) THEN NULLIF(BTRIM(rec.notes),'')
          ELSE NULL
        END;
      ELSE
        -- A full quantity can still carry a damage/quality/handling note; persist it once.
        v_note := CASE
          WHEN NOT v_note_written THEN NULLIF(BTRIM(rec.notes),'')
          ELSE NULL
        END;
      END IF;

      IF v_note IS NOT NULL THEN v_note_written := true; END IF;

      UPDATE public.order_details
      SET qty_picked=assign_qty,
          reason_picking=v_note,
          updated_at=now()
      WHERE id=od_rec.id;

      remaining := remaining-assign_qty;
    END LOOP;

    IF remaining > 0 THEN RAISE EXCEPTION 'unable to distribute picked quantity for %',rec.item_code; END IF;
  END LOOP;

  UPDATE public.runsheets
  SET status='Picked',
      picker_end=clock_timestamp(),
      picking_reservation_released=false,
      updated_at=clock_timestamp()
  WHERE id=v_runsheet.id
    AND status='Picking'
    AND (picker_id IS NULL OR picker_id=v_picker_id);
  IF NOT FOUND THEN RAISE EXCEPTION 'runsheet state changed during picking'; END IF;

  v_response := jsonb_build_object(
    'success',true,'msg','تم إنهاء التحضير','runsheet_code',p_runsheet_code,
    'reservation',true,'inventory_log_written',false,'operation_id',p_operation_id,'duplicate',false
  );

  IF v_registry_id IS NOT NULL THEN
    UPDATE public.erp_operation_registry
    SET status='completed',response_payload=v_response,completed_at=now()
    WHERE id=v_registry_id;
  END IF;

  RETURN v_response;
END;
$function$;
