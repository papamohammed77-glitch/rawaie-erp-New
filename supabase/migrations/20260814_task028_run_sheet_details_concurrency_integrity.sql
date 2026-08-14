BEGIN;
CREATE UNIQUE INDEX IF NOT EXISTS ux_run_sheet_details_runsheet_item ON public.run_sheet_details(runsheet_id,item_code);
CREATE OR REPLACE FUNCTION public.sync_run_sheet_details()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE target_runsheet_id uuid; v_item_id uuid; v_item_code text;
BEGIN
  IF TG_OP='DELETE' THEN v_item_code:=OLD.item_code; SELECT runsheet_id INTO target_runsheet_id FROM public.orders WHERE id=OLD.order_id; ELSE v_item_code:=NEW.item_code; SELECT runsheet_id INTO target_runsheet_id FROM public.orders WHERE id=NEW.order_id; END IF;
  IF target_runsheet_id IS NULL THEN IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF; END IF;
  SELECT id INTO v_item_id FROM public.items WHERE item_code=v_item_code LIMIT 1;
  INSERT INTO public.run_sheet_details(runsheet_id,item_id,item_code,item_name,unit,unit_price,qty_ordered,qty_picked,qty_loaded,qty_delivered,qty_refused,qty_returned,driver_liability)
  SELECT target_runsheet_id,v_item_id,v_item_code,MAX(od.item_name),MAX(od.unit),MAX(od.unit_price),COALESCE(SUM(od.qty),0),COALESCE(SUM(od.qty_picked),0),COALESCE(SUM(od.qty_loaded),0),COALESCE(SUM(od.qty_delivered),0),COALESCE(SUM(od.qty_refused),0),COALESCE(SUM(od.qty_returned),0),COALESCE(SUM(od.driver_liability),0)
  FROM public.order_details od JOIN public.orders o ON od.order_id=o.id
  WHERE o.runsheet_id=target_runsheet_id AND od.item_code=v_item_code
  ON CONFLICT(runsheet_id,item_code) DO UPDATE SET item_id=EXCLUDED.item_id,item_name=EXCLUDED.item_name,unit=EXCLUDED.unit,unit_price=EXCLUDED.unit_price,qty_ordered=EXCLUDED.qty_ordered,qty_picked=EXCLUDED.qty_picked,qty_loaded=EXCLUDED.qty_loaded,qty_delivered=EXCLUDED.qty_delivered,qty_refused=EXCLUDED.qty_refused,qty_returned=EXCLUDED.qty_returned,driver_liability=EXCLUDED.driver_liability,updated_at=now();
  RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END; $$;
COMMIT;