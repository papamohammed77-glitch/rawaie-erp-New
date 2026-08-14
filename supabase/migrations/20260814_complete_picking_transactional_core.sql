-- TASK-028: transactional picking orchestration
-- Picking is reservation-only; physical stock movement remains owned by post_stock_movement.

CREATE OR REPLACE FUNCTION public.complete_runsheet_picking(p_company_id uuid,p_runsheet_code text,p_user_email text,p_items jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  r public.runsheets%ROWTYPE;
  v_picker_id uuid;
  v_main_branch_id uuid;
  rec record;
  od_rec record;
  remaining numeric;
  assign_qty numeric;
  total_qty numeric;
  v_note text;
  v_item_id uuid;
BEGIN
  IF p_company_id IS NULL OR NULLIF(btrim(p_runsheet_code),'') IS NULL OR NULLIF(btrim(p_user_email),'') IS NULL THEN RAISE EXCEPTION 'invalid picking request'; END IF;
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items)=0 THEN RAISE EXCEPTION 'p_items must be a non-empty array'; END IF;

  SELECT u.id INTO v_picker_id FROM public.users u WHERE u.company_id=p_company_id AND lower(u.email)=lower(p_user_email) LIMIT 1;
  IF v_picker_id IS NULL THEN RAISE EXCEPTION 'picker user not found'; END IF;

  SELECT s.main_branch_id INTO v_main_branch_id FROM public.app_settings s WHERE s.company_id=p_company_id LIMIT 1;
  IF v_main_branch_id IS NULL THEN RAISE EXCEPTION 'main branch not configured'; END IF;

  SELECT * INTO r FROM public.runsheets WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;
  IF r.status <> 'Picking' THEN RAISE EXCEPTION 'runsheet is not in Picking state'; END IF;
  IF r.picker_id IS NOT NULL AND r.picker_id <> v_picker_id THEN RAISE EXCEPTION 'runsheet is assigned to another picker'; END IF;

  CREATE TEMP TABLE IF NOT EXISTS _picking_input(item_code text PRIMARY KEY,picked_qty numeric,notes text) ON COMMIT DROP;
  TRUNCATE _picking_input;
  INSERT INTO _picking_input(item_code,picked_qty,notes)
  SELECT btrim(x.item_code),sum(greatest(coalesce(x.picked_qty,0),0)),max(x.notes)
  FROM jsonb_to_recordset(p_items) AS x(item_code text,picked_qty numeric,notes text)
  WHERE nullif(btrim(x.item_code),'') IS NOT NULL
  GROUP BY btrim(x.item_code);
  IF NOT EXISTS(SELECT 1 FROM _picking_input) THEN RAISE EXCEPTION 'no valid picking items'; END IF;

  FOR rec IN SELECT * FROM _picking_input ORDER BY item_code LOOP
    SELECT i.id INTO v_item_id FROM public.items i WHERE i.company_id=p_company_id AND i.item_code=rec.item_code LIMIT 1;
    IF v_item_id IS NULL THEN RAISE EXCEPTION 'item not found: %',rec.item_code; END IF;

    SELECT coalesce(sum(od.qty),0) INTO total_qty
    FROM public.order_details od JOIN public.orders o ON o.id=od.order_id
    WHERE o.company_id=p_company_id AND o.runsheet_id=r.id AND od.item_code=rec.item_code;
    IF rec.picked_qty > total_qty THEN RAISE EXCEPTION 'picked quantity exceeds ordered quantity for %',rec.item_code; END IF;

    IF rec.picked_qty > 0 THEN PERFORM public.reserve_stock(p_company_id,v_main_branch_id,v_item_id,rec.picked_qty); END IF;

    INSERT INTO public.inventory_log(company_id,log_code,movement_date,voucher_id,item_id,movement_type,qty,reference,user_email)
    VALUES(p_company_id,'PCK-'||replace(gen_random_uuid()::text,'-',''),current_date,p_runsheet_code,v_item_id,'Picking',rec.picked_qty,p_runsheet_code,p_user_email);

    remaining := rec.picked_qty;
    FOR od_rec IN
      SELECT od.id,od.qty
      FROM public.order_details od JOIN public.orders o ON o.id=od.order_id
      WHERE o.company_id=p_company_id AND o.runsheet_id=r.id AND od.item_code=rec.item_code
      ORDER BY od.created_at NULLS FIRST,od.id
      FOR UPDATE
    LOOP
      assign_qty := least(coalesce(od_rec.qty,0),greatest(remaining,0));
      v_note := CASE WHEN assign_qty < coalesce(od_rec.qty,0) THEN rec.notes ELSE NULL END;
      UPDATE public.order_details SET qty_picked=assign_qty,reason_picking=v_note WHERE id=od_rec.id;
      remaining := remaining-assign_qty;
    END LOOP;
    IF remaining > 0 THEN RAISE EXCEPTION 'unable to distribute picked quantity for %',rec.item_code; END IF;
  END LOOP;

  UPDATE public.runsheets SET status='Picked',picker_end=clock_timestamp(),updated_at=clock_timestamp()
  WHERE id=r.id AND status='Picking' AND (picker_id IS NULL OR picker_id=v_picker_id);
  IF NOT FOUND THEN RAISE EXCEPTION 'runsheet state changed during picking'; END IF;

  RETURN jsonb_build_object('success',true,'msg','تم إنهاء التحضير','runsheet_code',p_runsheet_code);
END;
$$;