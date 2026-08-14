-- RAWAEA ERP — TASK-028 P0 CYCLE + BACKORDER INTEGRITY FIX
-- Forward correction for the already-applied TASK-028 baseline.
-- Fixes: persisted Loading Cycle identity, cycle-scoped Unloading idempotency,
-- Reopen -> Reload backorder consumption, and company-scoped trigger item lookup.
BEGIN;

ALTER TABLE public.runsheets
  ADD COLUMN IF NOT EXISTS loading_cycle_id uuid;

UPDATE public.runsheets
SET loading_cycle_id = gen_random_uuid()
WHERE loading_cycle_id IS NULL;

ALTER TABLE public.runsheets
  ALTER COLUMN loading_cycle_id SET DEFAULT gen_random_uuid();

CREATE UNIQUE INDEX IF NOT EXISTS ux_runsheets_loading_cycle_id
  ON public.runsheets(loading_cycle_id)
  WHERE loading_cycle_id IS NOT NULL;

ALTER TABLE public.fulfillment_backorders
  DROP CONSTRAINT IF EXISTS fulfillment_backorders_remaining_qty_check;

ALTER TABLE public.fulfillment_backorders
  ADD CONSTRAINT fulfillment_backorders_remaining_qty_status_check
  CHECK (
    (status = 'Pending' AND remaining_qty > 0)
    OR (status IN ('Cancelled','Consumed') AND remaining_qty >= 0)
  );

CREATE OR REPLACE FUNCTION public.sync_run_sheet_details()
RETURNS trigger
LANGUAGE plpgsql
SET search_path=public
AS $$
DECLARE
  r_id uuid;
  r_company_id uuid;
  i_id uuid;
  c text;
BEGIN
  IF TG_OP='DELETE' THEN
    c := OLD.item_code;
    SELECT runsheet_id, company_id INTO r_id, r_company_id
    FROM public.orders
    WHERE id=OLD.order_id;
  ELSE
    c := NEW.item_code;
    SELECT runsheet_id, company_id INTO r_id, r_company_id
    FROM public.orders
    WHERE id=NEW.order_id;
  END IF;

  IF r_id IS NULL OR r_company_id IS NULL THEN
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
  END IF;

  SELECT id INTO i_id
  FROM public.items
  WHERE company_id=r_company_id
    AND item_code=c
  ORDER BY id
  LIMIT 1;

  IF i_id IS NULL THEN
    RAISE EXCEPTION 'item_code % not found in order company %', c, r_company_id;
  END IF;

  INSERT INTO public.run_sheet_details(
    runsheet_id,item_id,item_code,item_name,unit,unit_price,
    qty_ordered,qty_picked,qty_loaded,qty_delivered,qty_refused,
    qty_returned,driver_liability
  )
  SELECT
    r_id,
    i_id,
    c,
    MAX(od.item_name),
    MAX(od.unit),
    MAX(od.unit_price),
    COALESCE(SUM(od.qty),0),
    COALESCE(SUM(od.qty_picked),0),
    COALESCE(SUM(od.qty_loaded),0),
    COALESCE(SUM(od.qty_delivered),0),
    COALESCE(SUM(od.qty_refused),0),
    COALESCE(SUM(od.qty_returned),0),
    COALESCE(SUM(od.driver_liability),0)
  FROM public.order_details od
  JOIN public.orders o ON o.id=od.order_id
  WHERE o.runsheet_id=r_id
    AND o.company_id=r_company_id
    AND od.item_code=c
  ON CONFLICT(runsheet_id,item_code) DO UPDATE SET
    item_id=EXCLUDED.item_id,
    item_name=EXCLUDED.item_name,
    unit=EXCLUDED.unit,
    unit_price=EXCLUDED.unit_price,
    qty_ordered=EXCLUDED.qty_ordered,
    qty_picked=EXCLUDED.qty_picked,
    qty_loaded=EXCLUDED.qty_loaded,
    qty_delivered=EXCLUDED.qty_delivered,
    qty_refused=EXCLUDED.qty_refused,
    qty_returned=EXCLUDED.qty_returned,
    driver_liability=EXCLUDED.driver_liability,
    updated_at=now();

  RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_run_sheet_details ON public.order_details;
CREATE TRIGGER trg_sync_run_sheet_details
AFTER INSERT OR DELETE OR UPDATE ON public.order_details
FOR EACH ROW EXECUTE FUNCTION public.sync_run_sheet_details();

CREATE OR REPLACE FUNCTION public.start_runsheet_loading(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
  r public.runsheets%ROWTYPE;
  u public.users%ROWTYPE;
  a text;
BEGIN
  SELECT * INTO u
  FROM public.users
  WHERE email=p_user_email AND company_id=p_company_id
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'user is not registered in company'; END IF;

  SELECT runsheet_code INTO a
  FROM public.runsheets
  WHERE company_id=p_company_id AND status='Loading' AND loader_id=u.id
  LIMIT 1;
  IF a IS NOT NULL THEN RAISE EXCEPTION 'user already has Loading runsheet: %',a; END IF;

  SELECT * INTO r
  FROM public.runsheets
  WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code
  FOR UPDATE;
  IF NOT FOUND OR r.status<>'Picked' THEN RAISE EXCEPTION 'runsheet is not Picked'; END IF;

  UPDATE public.runsheets
  SET status='Loading',
      loader_id=u.id,
      loader_start=clock_timestamp(),
      loader_end=NULL,
      loading_cycle_id=gen_random_uuid(),
      updated_at=now()
  WHERE id=r.id AND status='Picked';
  IF NOT FOUND THEN RAISE EXCEPTION 'start transition failed'; END IF;

  RETURN jsonb_build_object(
    'success',true,
    'runsheet_id',r.id,
    'status','Loading',
    'loading_cycle_id',(SELECT loading_cycle_id FROM public.runsheets WHERE id=r.id)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_runsheet_loading(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
  r public.runsheets%ROWTYPE;
  u public.users%ROWTYPE;
BEGIN
  SELECT * INTO u
  FROM public.users
  WHERE email=p_user_email AND company_id=p_company_id
  LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'user is not registered in company'; END IF;

  SELECT * INTO r
  FROM public.runsheets
  WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code
  FOR UPDATE;
  IF NOT FOUND OR r.status<>'Loading' OR r.loader_id<>u.id THEN
    RAISE EXCEPTION 'invalid Loading cancellation context';
  END IF;

  UPDATE public.order_details od
  SET qty_loaded=0, updated_at=now()
  FROM public.orders o
  WHERE od.order_id=o.id
    AND o.company_id=p_company_id
    AND o.runsheet_id=r.id
    AND COALESCE(od.qty_loaded,0)>0;

  UPDATE public.runsheets
  SET status='Picked',
      loader_id=NULL,
      loader_start=NULL,
      loader_end=NULL,
      loading_cycle_id=NULL,
      updated_at=now()
  WHERE id=r.id AND status='Loading';

  RETURN jsonb_build_object('success',true,'runsheet_id',r.id,'status','Picked');
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_loading(
  p_company_id uuid,
  p_runsheet_id uuid,
  p_items jsonb,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
  r public.runsheets%ROWTYPE;
  v public.vehicles%ROWTYPE;
  m uuid;
  van uuid;
  code text;
  req numeric;
  cap numeric;
  rem numeric;
  iid uuid;
  d record;
  keybase text;
  total numeric:=0;
BEGIN
  SELECT * INTO r
  FROM public.runsheets
  WHERE id=p_runsheet_id
  FOR UPDATE;
  IF NOT FOUND OR r.company_id<>p_company_id OR r.status<>'Loading'
     OR r.vehicle_id IS NULL OR r.loader_start IS NULL
     OR r.loading_cycle_id IS NULL THEN
    RAISE EXCEPTION 'invalid Loading context';
  END IF;

  SELECT * INTO v FROM public.vehicles
  WHERE id=r.vehicle_id AND company_id=p_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'vehicle not found'; END IF;

  SELECT main_branch_id INTO STRICT m
  FROM public.app_settings
  WHERE company_id=p_company_id;

  SELECT id INTO van
  FROM public.branches
  WHERE company_id=p_company_id
    AND branch_code='VAN-'||v.vehicle_code
    AND is_active=true
  LIMIT 1;
  IF van IS NULL THEN RAISE EXCEPTION 'VAN branch not found'; END IF;

  keybase:='TASK-028|Loading|'||r.loading_cycle_id::text;

  FOR code,req IN
    SELECT x.item_code,SUM(x.loaded_qty)
    FROM jsonb_to_recordset(p_items) x(item_code text,loaded_qty numeric)
    GROUP BY x.item_code
    ORDER BY x.item_code
  LOOP
    SELECT id INTO iid
    FROM public.items
    WHERE company_id=p_company_id AND item_code=code
    ORDER BY id
    LIMIT 1;
    IF iid IS NULL OR req<=0 THEN RAISE EXCEPTION 'invalid item request'; END IF;

    SELECT COALESCE(SUM(GREATEST(COALESCE(od.qty_picked,0),0)),0) INTO cap
    FROM public.order_details od
    JOIN public.orders o ON o.id=od.order_id
    WHERE o.company_id=p_company_id
      AND o.runsheet_id=r.id
      AND od.item_code=code;
    IF req>cap THEN RAISE EXCEPTION 'loaded quantity exceeds picked capacity'; END IF;

    UPDATE public.order_details od
    SET qty_loaded=0,updated_at=now()
    FROM public.orders o
    WHERE od.order_id=o.id
      AND o.company_id=p_company_id
      AND o.runsheet_id=r.id
      AND od.item_code=code;

    rem:=req;
    FOR d IN
      SELECT od.id,COALESCE(od.qty_picked,0) picked
      FROM public.order_details od
      JOIN public.orders o ON o.id=od.order_id
      WHERE o.company_id=p_company_id
        AND o.runsheet_id=r.id
        AND od.item_code=code
        AND COALESCE(od.qty_picked,0)>0
      ORDER BY od.id
      FOR UPDATE OF od
    LOOP
      EXIT WHEN rem<=0;
      UPDATE public.order_details
      SET qty_loaded=LEAST(rem,d.picked),updated_at=now()
      WHERE id=d.id;
      rem:=rem-LEAST(rem,d.picked);
    END LOOP;
    IF rem<>0 THEN RAISE EXCEPTION 'failed to allocate loaded quantity'; END IF;

    PERFORM public.post_stock_movement(
      p_company_id,'Loading',m,van,iid,req,r.runsheet_code,
      keybase||'|'||iid::text,p_user_email,
      keybase||'|'||iid::text
    );

    INSERT INTO public.fulfillment_backorders(
      company_id,order_id,order_detail_id,runsheet_id,item_id,item_code,remaining_qty,status
    )
    SELECT
      p_company_id,od.order_id,od.id,r.id,od.item_id,od.item_code,
      (od.qty-COALESCE(od.qty_loaded,0)),'Pending'
    FROM public.order_details od
    JOIN public.orders o ON o.id=od.order_id
    WHERE o.company_id=p_company_id
      AND o.runsheet_id=r.id
      AND od.item_code=code
      AND od.qty>COALESCE(od.qty_loaded,0)
    ON CONFLICT(order_detail_id,runsheet_id)
    DO UPDATE SET
      remaining_qty=EXCLUDED.remaining_qty,
      status='Pending',
      updated_at=now();

    total:=total+req;
  END LOOP;

  UPDATE public.fulfillment_backorders fb
  SET remaining_qty=GREATEST(od.qty-COALESCE(od.qty_loaded,0),0),
      status=CASE
        WHEN od.qty<=COALESCE(od.qty_loaded,0) THEN 'Consumed'
        ELSE 'Pending'
      END,
      updated_at=now()
  FROM public.order_details od
  JOIN public.orders o ON o.id=od.order_id
  WHERE fb.order_detail_id=od.id
    AND fb.runsheet_id=r.id
    AND o.company_id=p_company_id;

  UPDATE public.runsheets
  SET status='Loaded',loader_end=clock_timestamp(),updated_at=now()
  WHERE id=r.id AND status='Loading';
  IF NOT FOUND THEN RAISE EXCEPTION 'Load transition failed'; END IF;

  UPDATE public.orders
  SET order_status='Loaded',updated_at=now()
  WHERE company_id=p_company_id AND runsheet_id=r.id;

  RETURN jsonb_build_object('success',true,'runsheet_id',r.id,'loaded_total',total,'loading_cycle_id',r.loading_cycle_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_unloading(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
DECLARE
  r public.runsheets%ROWTYPE;
  v public.vehicles%ROWTYPE;
  m uuid;
  van uuid;
  d record;
  total numeric:=0;
  unload_key text;
BEGIN
  SELECT * INTO r
  FROM public.runsheets
  WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code
  FOR UPDATE;
  IF NOT FOUND OR r.status<>'Loaded' OR r.loading_cycle_id IS NULL THEN
    RAISE EXCEPTION 'runsheet not Loaded';
  END IF;

  SELECT * INTO v FROM public.vehicles
  WHERE id=r.vehicle_id AND company_id=p_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'vehicle not found'; END IF;

  SELECT main_branch_id INTO STRICT m
  FROM public.app_settings
  WHERE company_id=p_company_id;

  SELECT id INTO van
  FROM public.branches
  WHERE company_id=p_company_id
    AND branch_code='VAN-'||v.vehicle_code
    AND is_active=true
  LIMIT 1;
  IF van IS NULL THEN RAISE EXCEPTION 'VAN branch not found'; END IF;

  FOR d IN
    SELECT item_id,qty_loaded
    FROM public.run_sheet_details
    WHERE runsheet_id=r.id AND COALESCE(qty_loaded,0)>0
    ORDER BY item_id
  LOOP
    unload_key:='TASK-028|Unloading|'||r.loading_cycle_id::text||'|'||d.item_id::text;
    PERFORM public.post_stock_movement(
      p_company_id,'Unloading',van,m,d.item_id,d.qty_loaded,r.runsheet_code,
      r.runsheet_code||'|Unloading|'||r.loading_cycle_id::text||'|'||d.item_id::text,
      p_user_email,unload_key
    );
    total:=total+d.qty_loaded;
  END LOOP;

  UPDATE public.order_details od
  SET qty_loaded=0,updated_at=now()
  FROM public.orders o
  WHERE od.order_id=o.id
    AND o.company_id=p_company_id
    AND o.runsheet_id=r.id;

  UPDATE public.fulfillment_backorders
  SET status='Cancelled',updated_at=now()
  WHERE runsheet_id=r.id AND status='Pending';

  UPDATE public.runsheets
  SET status='Picked',loader_end=NULL,loader_start=NULL,loading_cycle_id=NULL,updated_at=now()
  WHERE id=r.id AND status='Loaded';

  UPDATE public.orders
  SET order_status='Pending',updated_at=now()
  WHERE company_id=p_company_id AND runsheet_id=r.id;

  RETURN jsonb_build_object('success',true,'status','Picked','unloaded_total',total,'unloading_cycle',r.loading_cycle_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_runsheet_reopen_loading(
  p_company_id uuid,
  p_runsheet_code text,
  p_user_email text,
  p_operation_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=public
AS $$
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
  total numeric:=0;
BEGIN
  SELECT * INTO r
  FROM public.runsheets
  WHERE company_id=p_company_id AND runsheet_code=p_runsheet_code
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'runsheet not found'; END IF;

  k:='TASK-028|ReopenLoading|'||p_operation_id||'|'||r.id::text;
  SELECT count(*) INTO ex
  FROM public.inventory_log
  WHERE company_id=p_company_id AND idempotency_key LIKE k||'|%';
  IF ex>0 THEN
    RETURN jsonb_build_object('success',true,'duplicate',true,'operation_id',p_operation_id);
  END IF;

  IF r.status<>'Loaded' OR r.loading_cycle_id IS NULL THEN
    RAISE EXCEPTION 'runsheet not Loaded';
  END IF;
  old_cycle:=r.loading_cycle_id;
  new_cycle:=gen_random_uuid();

  SELECT * INTO v FROM public.vehicles
  WHERE id=r.vehicle_id AND company_id=p_company_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'vehicle not found'; END IF;

  SELECT main_branch_id INTO STRICT m
  FROM public.app_settings
  WHERE company_id=p_company_id;

  SELECT id INTO van
  FROM public.branches
  WHERE company_id=p_company_id
    AND branch_code='VAN-'||v.vehicle_code
    AND is_active=true
  LIMIT 1;
  IF van IS NULL THEN RAISE EXCEPTION 'VAN branch not found'; END IF;

  FOR d IN
    SELECT item_id,qty_loaded
    FROM public.run_sheet_details
    WHERE runsheet_id=r.id AND COALESCE(qty_loaded,0)>0
    ORDER BY item_id
  LOOP
    PERFORM public.post_stock_movement(
      p_company_id,'Unloading',van,m,d.item_id,d.qty_loaded,r.runsheet_code,
      r.runsheet_code||'|Reopen|'||p_operation_id||'|'||old_cycle::text||'|'||d.item_id::text,
      p_user_email,k||'|'||d.item_id::text
    );
    total:=total+d.qty_loaded;
  END LOOP;

  UPDATE public.runsheets
  SET status='Loading',
      loader_end=NULL,
      loader_start=clock_timestamp(),
      loading_cycle_id=new_cycle,
      updated_at=now()
  WHERE id=r.id AND status='Loaded';
  IF NOT FOUND THEN RAISE EXCEPTION 'reopen transition failed'; END IF;

  RETURN jsonb_build_object(
    'success',true,
    'duplicate',false,
    'reopened_total',total,
    'qty_loaded_preserved',true,
    'operation_id',p_operation_id,
    'previous_loading_cycle_id',old_cycle,
    'loading_cycle_id',new_cycle
  );
END;
$$;

COMMIT;
