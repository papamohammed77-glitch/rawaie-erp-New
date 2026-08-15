-- Incident repair: cancel-picking
-- 1) sync_run_sheet_details() must use order_details.item_id as authoritative identity.
-- 2) cancel_runsheet_picking() must support legacy warehouse users whose branch
--    is explicitly granted by users.allowed_branch_ids when app_settings is absent.

create or replace function public.sync_run_sheet_details()
returns trigger
language plpgsql
set search_path = public
as $function$
declare
  r_id uuid;
  r_company_id uuid;
  i_id uuid;
  c text;
  detail_item_id uuid;
begin
  if TG_OP = 'DELETE' then
    c := OLD.item_code;
    detail_item_id := OLD.item_id;
    select runsheet_id, company_id into r_id, r_company_id
    from public.orders where id = OLD.order_id;
  else
    c := NEW.item_code;
    detail_item_id := NEW.item_id;
    select runsheet_id, company_id into r_id, r_company_id
    from public.orders where id = NEW.order_id;
  end if;

  if r_id is null or r_company_id is null then
    return case when TG_OP = 'DELETE' then OLD else NEW end;
  end if;

  if detail_item_id is not null then
    select id into i_id
    from public.items
    where id = detail_item_id
    limit 1;
  else
    select id into i_id
    from public.items
    where company_id = r_company_id
      and item_code = c
    order by id
    limit 1;
  end if;

  if i_id is null then
    raise exception 'item reference % not found for order detail', coalesce(detail_item_id::text, c);
  end if;

  insert into public.run_sheet_details(
    runsheet_id,item_id,item_code,item_name,unit,unit_price,
    qty_ordered,qty_picked,qty_loaded,qty_delivered,qty_refused,
    qty_returned,driver_liability
  )
  select
    r_id,i_id,c,max(od.item_name),max(od.unit),max(od.unit_price),
    coalesce(sum(od.qty),0),coalesce(sum(od.qty_picked),0),
    coalesce(sum(od.qty_loaded),0),coalesce(sum(od.qty_delivered),0),
    coalesce(sum(od.qty_refused),0),coalesce(sum(od.qty_returned),0),
    coalesce(sum(od.driver_liability),0)
  from public.order_details od
  join public.orders o on o.id = od.order_id
  where o.runsheet_id = r_id
    and o.company_id = r_company_id
    and od.item_id = detail_item_id
  on conflict(runsheet_id,item_code) do update set
    item_id=excluded.item_id,
    item_name=excluded.item_name,
    unit=excluded.unit,
    unit_price=excluded.unit_price,
    qty_ordered=excluded.qty_ordered,
    qty_picked=excluded.qty_picked,
    qty_loaded=excluded.qty_loaded,
    qty_delivered=excluded.qty_delivered,
    qty_refused=excluded.qty_refused,
    qty_returned=excluded.qty_returned,
    driver_liability=excluded.driver_liability,
    updated_at=now();

  return case when TG_OP = 'DELETE' then OLD else NEW end;
end;
$function$;

create or replace function public.cancel_runsheet_picking(
  p_company_id uuid,
  p_runsheet_code text,
  p_auth_user_id uuid,
  p_user_email text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  r public.runsheets%rowtype;
  u public.users%rowtype;
  v_main_branch_id uuid;
  v_branch_company_id uuid;
  d record;
  picked_total numeric;
  total_picked numeric := 0;
  reset_count integer := 0;
  allowed_branch_code text;
begin
  if p_company_id is null or nullif(btrim(p_runsheet_code),'') is null or p_auth_user_id is null then
    raise exception 'invalid cancel picking request';
  end if;

  select * into u
  from public.users
  where auth_id = p_auth_user_id
    and company_id = p_company_id
  limit 1;
  if not found then raise exception 'user is not registered in company'; end if;

  select * into r
  from public.runsheets
  where company_id = p_company_id
    and runsheet_code = p_runsheet_code
  for update;
  if not found then raise exception 'runsheet not found'; end if;
  if r.status <> 'Picking' then raise exception 'runsheet is not in Picking state'; end if;
  if r.picker_id is null or r.picker_id <> u.id then raise exception 'runsheet assigned to another picker'; end if;

  select coalesce(sum(coalesce(od.qty_picked,0)),0) into total_picked
  from public.order_details od
  join public.orders o on o.id = od.order_id
  where o.company_id = p_company_id
    and o.runsheet_id = r.id
    and coalesce(od.qty_picked,0) > 0;

  if total_picked > 0 then
    select s.main_branch_id into v_main_branch_id
    from public.app_settings s
    where s.company_id = p_company_id
    limit 1;

    if v_main_branch_id is null then
      if jsonb_typeof(u.allowed_branch_ids) = 'array' then
        select b.branch_code into allowed_branch_code
        from public.branches b
        where b.is_active
          and b.branch_code in (select jsonb_array_elements_text(u.allowed_branch_ids))
        order by b.branch_code
        limit 1;
      elsif jsonb_typeof(u.allowed_branch_ids) = 'string' then
        allowed_branch_code := u.allowed_branch_ids #>> '{}';
      end if;

      if allowed_branch_code is not null then
        select b.id,b.company_id into v_main_branch_id,v_branch_company_id
        from public.branches b
        where b.is_active
          and b.branch_code = allowed_branch_code
        order by b.id
        limit 1;
      end if;
    else
      select b.company_id into v_branch_company_id
      from public.branches b
      where b.id = v_main_branch_id;
    end if;

    if v_main_branch_id is null then
      raise exception 'main warehouse branch not configured for reservation release';
    end if;
    if v_branch_company_id is null then
      select b.company_id into v_branch_company_id
      from public.branches b where b.id=v_main_branch_id;
    end if;
    if v_branch_company_id is null then
      raise exception 'reservation release branch is invalid';
    end if;
  end if;

  for d in
    select od.item_id,sum(coalesce(od.qty_picked,0)) as qty_picked
    from public.order_details od
    join public.orders o on o.id=od.order_id
    where o.company_id=p_company_id
      and o.runsheet_id=r.id
      and coalesce(od.qty_picked,0)>0
    group by od.item_id
    order by od.item_id
  loop
    picked_total := d.qty_picked;
    if d.item_id is null then raise exception 'picked detail has no item_id'; end if;
    perform public.release_stock_reservation(
      v_branch_company_id,v_main_branch_id,d.item_id,picked_total
    );
  end loop;

  update public.order_details od
  set qty_picked=0,reason_picking=null,updated_at=now()
  from public.orders o
  where od.order_id=o.id
    and o.company_id=p_company_id
    and o.runsheet_id=r.id
    and coalesce(od.qty_picked,0)>0;
  get diagnostics reset_count=row_count;

  update public.runsheets
  set status='Open',picker_id=null,picker_start=null,picker_end=null,updated_at=now()
  where id=r.id and company_id=p_company_id and status='Picking';
  if not found then raise exception 'runsheet cancellation transition failed'; end if;

  return jsonb_build_object(
    'success',true,
    'status','Open',
    'runsheet_id',r.id,
    'runsheet_code',p_runsheet_code,
    'reset_order_details',reset_count,
    'reservation_released',total_picked>0,
    'released_qty',total_picked
  );
end;
$function$;
