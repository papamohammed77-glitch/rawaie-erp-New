-- RAWAEA ERP — CTO rescue migration
-- Production applied: 2026-08-19
-- Restores the active return/delivery contracts, adds operation idempotency,
-- and preserves the rule that physical stock mutation belongs only to post_stock_movement.

create table if not exists public.erp_operation_registry (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null,
  operation_type text not null,
  operation_key text not null,
  request_payload jsonb not null default '{}'::jsonb,
  status text not null default 'processing' check (status in ('processing','completed','failed')),
  response_payload jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (company_id, operation_type, operation_key)
);
create index if not exists erp_operation_registry_company_type_idx
  on public.erp_operation_registry(company_id, operation_type, created_at desc);

create or replace function public.complete_return_atomic(
  p_company_id uuid,p_runsheet_code text,p_order_code text,p_is_pos_return boolean,p_user_email text,p_items jsonb
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_op_key text; v_existing jsonb; v_main_branch uuid; v_runsheet record; v_order record;
  v_item jsonb; v_item_id uuid; v_item_code text; v_returned numeric; v_remaining numeric; v_alloc numeric;
  v_total_value numeric:=0; v_updated integer:=0; v_skipped integer:=0; v_adjusted integer:=0;
  v_detail record; v_expected_return numeric; v_new_returned numeric; v_line_liability numeric;
  v_return_condition text; v_reason text; v_customer_balance numeric:=0; v_entry_id uuid;
  v_inventory_account uuid; v_cogs_account uuid; v_inventory_name text; v_cogs_name text;
  v_order_total_original numeric:=0; v_order_total_returned numeric:=0; v_order_new_total numeric:=0;
  v_order_new_status text; v_stock_move jsonb; v_fingerprint text; v_existing_status text; v_result jsonb;
begin
  if p_company_id is null or nullif(btrim(p_user_email),'') is null then raise exception 'invalid company/user context'; end if;
  if coalesce(p_runsheet_code,'')='' and coalesce(p_order_code,'')='' then raise exception 'runsheet_code or order_code is required'; end if;
  if p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'items are required'; end if;
  if p_runsheet_code is not null and p_order_code is null and p_is_pos_return then raise exception 'POS return requires order_code'; end if;
  if p_runsheet_code is not null and p_is_pos_return then raise exception 'runsheet return and POS return cannot be combined'; end if;

  v_fingerprint:=md5(coalesce(p_company_id::text,'')||'|'||coalesce(p_runsheet_code,'')||'|'||coalesce(p_order_code,'')||'|'||coalesce(p_is_pos_return,false)::text||'|'||p_items::text);
  v_op_key:=coalesce(p_runsheet_code,p_order_code)||':'||v_fingerprint;
  select response_payload,status into v_existing,v_existing_status from public.erp_operation_registry
  where company_id=p_company_id and operation_type='complete_return' and operation_key=v_op_key for update;
  if found then
    if v_existing_status='completed' and v_existing is not null then return(v_existing||jsonb_build_object('duplicate',true)); end if;
    raise exception 'return operation is already in progress';
  end if;
  insert into public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
  values(p_company_id,'complete_return',v_op_key,p_items,'processing');

  select a.main_branch_id into v_main_branch from public.app_settings a
  where a.company_id=p_company_id and a.main_branch_id is not null order by a.created_at asc,a.id limit 1;
  if v_main_branch is null then raise exception 'MAIN branch context unavailable for company'; end if;

  if p_runsheet_code is not null then
    select r.* into v_runsheet from public.runsheets r
    where r.company_id=p_company_id and r.runsheet_code=p_runsheet_code for update;
    if not found then raise exception 'runsheet not found: %',p_runsheet_code; end if;
    if v_runsheet.status<>'Returning' then raise exception 'runsheet is not in Returning state: %',v_runsheet.status; end if;
  end if;

  if p_order_code is not null then
    select o.* into v_order from public.orders o
    where o.company_id=p_company_id and o.order_code=p_order_code for update;
    if not found then raise exception 'order not found: %',p_order_code; end if;
    if v_order.order_status='Cancelled' then raise exception 'cannot return a cancelled order'; end if;
    if p_runsheet_code is not null and v_order.runsheet_id is distinct from v_runsheet.id then raise exception 'order is not assigned to the requested runsheet'; end if;
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_item_code:=nullif(btrim(coalesce(v_item->>'item_code',v_item->>'itemCode','')),'');
    v_returned:=greatest(coalesce((v_item->>'returnedQty')::numeric,(v_item->>'returned_qty')::numeric,0),0);
    v_return_condition:=lower(coalesce(v_item->>'return_condition',v_item->>'returnCondition','good'));
    v_reason:=nullif(coalesce(v_item->>'reason',''),'');
    if v_returned<=0 then v_skipped:=v_skipped+1; continue; end if;
    if v_item_code is null then raise exception 'return item_code is required'; end if;
    if v_return_condition not in ('good','damaged','missing') then raise exception 'unsupported return condition: %',v_return_condition; end if;
    select i.id into v_item_id from public.items i where i.item_code=v_item_code;
    if v_item_id is null then raise exception 'item not found: %',v_item_code; end if;

    if p_runsheet_code is not null then
      v_remaining:=v_returned;
      for v_detail in
        select od.id,od.qty_loaded,od.qty_delivered,od.qty_returned,od.unit_price
        from public.order_details od join public.orders o on o.id=od.order_id
        where o.company_id=p_company_id and o.runsheet_id=v_runsheet.id and od.item_code=v_item_code
        order by od.created_at asc,od.id asc for update of od
      loop
        exit when v_remaining<=0;
        v_expected_return:=greatest(0,coalesce(v_detail.qty_loaded,0)-coalesce(v_detail.qty_delivered,0)-coalesce(v_detail.qty_returned,0));
        v_alloc:=least(v_remaining,v_expected_return);
        if v_alloc<=0 then continue; end if;
        v_new_returned:=coalesce(v_detail.qty_returned,0)+v_alloc;
        v_line_liability:=case when v_return_condition in('damaged','missing') then greatest(0,coalesce(v_detail.qty_loaded,0)-coalesce(v_detail.qty_delivered,0)-v_new_returned)*coalesce(v_detail.unit_price,0) else 0 end;
        update public.order_details set qty_returned=v_new_returned,reason_return=coalesce(v_reason,reason_return),driver_liability=v_line_liability,updated_at=now() where id=v_detail.id;
        v_total_value:=v_total_value+v_alloc*coalesce(v_detail.unit_price,0);
        v_remaining:=v_remaining-v_alloc; v_updated:=v_updated+1;
      end loop;
      if v_remaining>0 then raise exception 'return quantity exceeds outstanding run-sheet quantity for item % by %',v_item_code,v_remaining; end if;
      if v_return_condition='good' then
        v_stock_move:=public.post_stock_movement(p_company_id,'SalesReturn',null,v_main_branch,v_item_id,v_returned,p_runsheet_code,p_runsheet_code,p_user_email,'Return:'||v_op_key||':'||v_item_id::text);
      end if;
    else
      select od.id,od.qty,od.qty_returned,od.unit_price into v_detail from public.order_details od
      where od.order_id=v_order.id and od.item_code=v_item_code for update;
      if not found then raise exception 'order detail not found for item %',v_item_code; end if;
      v_expected_return:=greatest(0,coalesce(v_detail.qty,0)-coalesce(v_detail.qty_returned,0));
      if v_returned>v_expected_return then v_adjusted:=v_adjusted+1; v_returned:=v_expected_return; end if;
      if v_returned<=0 then continue; end if;
      update public.order_details set qty_returned=coalesce(qty_returned,0)+v_returned,reason_return=coalesce(v_reason,reason_return,'مرتجع من نقطة البيع'),driver_liability=0,updated_at=now() where id=v_detail.id;
      v_total_value:=v_total_value+v_returned*coalesce(v_detail.unit_price,0); v_updated:=v_updated+1;
      if v_return_condition='good' then
        v_stock_move:=public.post_stock_movement(p_company_id,'SalesReturn',null,v_main_branch,v_item_id,v_returned,p_order_code,p_order_code,p_user_email,'Return:'||v_op_key||':'||v_item_id::text);
      end if;
    end if;
  end loop;

  if v_total_value>0 then
    select coa.id,coa.account_name into v_inventory_account,v_inventory_name from public.chart_of_accounts coa where coa.company_id=p_company_id and coa.account_code='124' and coa.is_active=true limit 1;
    select coa.id,coa.account_name into v_cogs_account,v_cogs_name from public.chart_of_accounts coa where coa.company_id=p_company_id and coa.account_code='51' and coa.is_active=true limit 1;
    if v_inventory_account is not null and v_cogs_account is not null then
      select id into v_entry_id from public.journal_entries where company_id=p_company_id and reference=coalesce(p_runsheet_code,p_order_code) and entry_type='SalesReturn' and description like 'مرتجعات – %' order by created_at desc limit 1;
      if v_entry_id is null then
        insert into public.journal_entries(id,company_id,entry_code,entry_date,reference,description,entry_type,status,created_by,posting_date)
        values(gen_random_uuid(),p_company_id,'JE-RTN-'||left(v_fingerprint,16),current_date,coalesce(p_runsheet_code,p_order_code),'مرتجعات – '||coalesce(p_runsheet_code,p_order_code),'SalesReturn','Posted',p_user_email,now()) returning id into v_entry_id;
        insert into public.journal_lines(entry_id,account_id,account_name,debit,credit)
        values(v_entry_id,v_inventory_account,v_inventory_name,v_total_value,0),(v_entry_id,v_cogs_account,v_cogs_name,0,v_total_value);
      end if;
    end if;
  end if;

  if v_order.id is not null and v_total_value>0 then
    select coalesce(cl.balance,0) into v_customer_balance from public.customer_ledger cl where cl.customer_id=v_order.customer_id order by cl.created_at desc limit 1;
    insert into public.customer_ledger(customer_id,entry_date,reference,description,debit,credit,balance,due_date,user_email)
    values(v_order.customer_id,current_date,p_order_code,'مرتجع – '||p_order_code,0,v_total_value,v_customer_balance-v_total_value,current_date,p_user_email);
  end if;

  if v_order.id is not null then
    select coalesce(sum(od.qty),0),coalesce(sum(od.qty_returned),0),coalesce(sum(greatest(0,od.qty-od.qty_returned)*od.unit_price),0)
    into v_order_total_original,v_order_total_returned,v_order_new_total from public.order_details od where od.order_id=v_order.id;
    v_order_new_status:=case when v_order_total_original>0 and v_order_total_returned>=v_order_total_original then 'Returned' else 'Partially Returned' end;
    update public.orders set order_status=v_order_new_status,total_amount=v_order_new_total,updated_at=now() where id=v_order.id;
  end if;

  if p_runsheet_code is not null then
    update public.run_sheet_details rsd set qty_ordered=a.qty_ordered,qty_picked=a.qty_picked,qty_loaded=a.qty_loaded,qty_delivered=a.qty_delivered,qty_refused=a.qty_refused,qty_returned=a.qty_returned,driver_liability=a.driver_liability,updated_at=now()
    from (
      select od.item_code,coalesce(sum(od.qty),0) qty_ordered,coalesce(sum(od.qty_picked),0) qty_picked,coalesce(sum(od.qty_loaded),0) qty_loaded,coalesce(sum(od.qty_delivered),0) qty_delivered,coalesce(sum(od.qty_refused),0) qty_refused,coalesce(sum(od.qty_returned),0) qty_returned,coalesce(sum(od.driver_liability),0) driver_liability
      from public.order_details od join public.orders o on o.id=od.order_id where o.company_id=p_company_id and o.runsheet_id=v_runsheet.id group by od.item_code
    ) a where rsd.runsheet_id=v_runsheet.id and rsd.item_code=a.item_code;
    update public.runsheets set status='Returned',return_end=now(),updated_at=now() where id=v_runsheet.id and status='Returning';
  end if;

  v_result:=jsonb_build_object('success',true,'duplicate',false,'msg','تم إنهاء المرتجعات بنجاح','updated_count',v_updated,'skipped_count',v_skipped,'adjusted_count',v_adjusted,'total_returned_value',v_total_value,'new_order_status',v_order_new_status);
  update public.erp_operation_registry set status='completed',response_payload=v_result,completed_at=now() where company_id=p_company_id and operation_type='complete_return' and operation_key=v_op_key;
  insert into public.audit_log(user_email,action,table_name,record_id,new_data) values(p_user_email,'CTO_RESCUE_COMPLETE_RETURN','erp_operation_registry',v_op_key,v_result);
  return v_result;
exception when others then
  update public.erp_operation_registry set status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() where company_id=p_company_id and operation_type='complete_return' and operation_key=v_op_key;
  raise;
end; $$;

create or replace function public.complete_order_delivery_atomic(
  p_company_id uuid,p_runsheet_code text,p_order_code text,p_user_email text,p_items jsonb
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  v_op_key text; v_existing jsonb; v_runsheet record; v_order record; v_item jsonb; v_item_code text; v_requested numeric; v_remaining numeric; v_updated integer:=0; v_result jsonb; v_fingerprint text; v_detail record; v_alloc numeric; v_order_loaded numeric; v_order_delivered numeric;
begin
  if p_company_id is null or nullif(btrim(p_user_email),'') is null or nullif(btrim(p_runsheet_code),'') is null or nullif(btrim(p_order_code),'') is null then raise exception 'invalid delivery request'; end if;
  if p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'items are required'; end if;
  v_fingerprint:=md5(p_company_id::text||'|'||p_runsheet_code||'|'||p_order_code||'|'||p_items::text); v_op_key:=p_runsheet_code||':'||p_order_code||':'||v_fingerprint;
  select response_payload into v_existing from public.erp_operation_registry where company_id=p_company_id and operation_type='complete_order_delivery' and operation_key=v_op_key for update;
  if found then return(v_existing||jsonb_build_object('duplicate',true)); end if;
  insert into public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) values(p_company_id,'complete_order_delivery',v_op_key,p_items,'processing');
  select r.* into v_runsheet from public.runsheets r where r.company_id=p_company_id and r.runsheet_code=p_runsheet_code for update; if not found then raise exception 'runsheet not found: %',p_runsheet_code; end if;
  select o.* into v_order from public.orders o where o.company_id=p_company_id and o.order_code=p_order_code and o.runsheet_id=v_runsheet.id for update; if not found then raise exception 'order is not assigned to runsheet: %',p_order_code; end if;
  if v_order.order_status='Cancelled' then raise exception 'cannot deliver a cancelled order'; end if;
  for v_item in select value from jsonb_array_elements(p_items) loop
    v_item_code:=nullif(btrim(coalesce(v_item->>'itemCode',v_item->>'item_code','')),''); v_requested:=greatest(coalesce((v_item->>'deliveredQty')::numeric,(v_item->>'delivered_qty')::numeric,0),0);
    if v_item_code is null then raise exception 'delivery itemCode is required'; end if; if v_requested<=0 then continue; end if; v_remaining:=v_requested;
    for v_detail in select od.id,od.qty_loaded,od.qty_delivered from public.order_details od where od.order_id=v_order.id and od.item_code=v_item_code order by od.created_at,od.id for update loop
      exit when v_remaining<=0; v_alloc:=least(v_remaining,greatest(0,coalesce(v_detail.qty_loaded,0)-coalesce(v_detail.qty_delivered,0))); if v_alloc<=0 then continue; end if;
      update public.order_details set qty_delivered=coalesce(qty_delivered,0)+v_alloc,reason_delivery=coalesce(nullif(v_item->>'reason',''),reason_delivery),updated_at=now() where id=v_detail.id; v_remaining:=v_remaining-v_alloc; v_updated:=v_updated+1;
    end loop;
    if v_remaining>0 then raise exception 'delivered quantity exceeds loaded quantity for item % by %',v_item_code,v_remaining; end if;
  end loop;
  select coalesce(sum(od.qty_loaded),0),coalesce(sum(od.qty_delivered),0) into v_order_loaded,v_order_delivered from public.order_details od where od.order_id=v_order.id;
  update public.orders set order_status=case when v_order_loaded>0 and v_order_delivered>=v_order_loaded then 'Delivered' else 'Partially Delivered' end,updated_at=now() where id=v_order.id;
  update public.run_sheet_details rsd set qty_ordered=a.qty_ordered,qty_picked=a.qty_picked,qty_loaded=a.qty_loaded,qty_delivered=a.qty_delivered,qty_refused=a.qty_refused,qty_returned=a.qty_returned,driver_liability=a.driver_liability,updated_at=now()
  from (
    select od.item_code,coalesce(sum(od.qty),0) qty_ordered,coalesce(sum(od.qty_picked),0) qty_picked,coalesce(sum(od.qty_loaded),0) qty_loaded,coalesce(sum(od.qty_delivered),0) qty_delivered,coalesce(sum(od.qty_refused),0) qty_refused,coalesce(sum(od.qty_returned),0) qty_returned,coalesce(sum(od.driver_liability),0) driver_liability
    from public.order_details od join public.orders o on o.id=od.order_id where o.company_id=p_company_id and o.runsheet_id=v_runsheet.id group by od.item_code
  ) a where rsd.runsheet_id=v_runsheet.id and rsd.item_code=a.item_code;
  v_result:=jsonb_build_object('success',true,'duplicate',false,'msg','تم إنهاء التسليم بنجاح','updated_count',v_updated,'order_status',(select order_status from public.orders where id=v_order.id));
  update public.erp_operation_registry set status='completed',response_payload=v_result,completed_at=now() where company_id=p_company_id and operation_type='complete_order_delivery' and operation_key=v_op_key;
  insert into public.audit_log(user_email,action,table_name,record_id,new_data) values(p_user_email,'CTO_RESCUE_COMPLETE_ORDER_DELIVERY','erp_operation_registry',v_op_key,v_result);
  return v_result;
exception when others then
  update public.erp_operation_registry set status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() where company_id=p_company_id and operation_type='complete_order_delivery' and operation_key=v_op_key;
  raise;
end; $$;

revoke all on function public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) from public,anon,authenticated;
revoke all on function public.complete_order_delivery_atomic(uuid,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) to service_role;
grant execute on function public.complete_order_delivery_atomic(uuid,text,text,text,jsonb) to service_role;
