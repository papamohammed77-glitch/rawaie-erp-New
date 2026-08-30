-- RAWAEA ERP — MAIN6 dependency closure
-- Canonical replay of the two atomic capabilities used by MAIN6.
-- No physical stock mutation is performed by either capability.

create or replace function public.save_purchase_order_atomic(
  p_company_id uuid,
  p_supplier_id uuid,
  p_supplier_name text,
  p_user_email text,
  p_items jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_supplier public.suppliers%rowtype;
  v_po_id uuid;
  v_po_code text;
  v_last_num bigint;
  v_total numeric := 0;
  v_item record;
  v_master public.items%rowtype;
  v_seen text[] := '{}';
begin
  if not exists(select 1 from public.companies c where c.id=p_company_id) then raise exception 'سياق الشركة غير موجود'; end if;
  if p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'لا توجد أصناف في أمر الشراء'; end if;
  select * into v_supplier from public.suppliers where id=p_supplier_id and company_id=p_company_id and coalesce(is_active,true) limit 1;
  if not found then raise exception 'المورد غير موجود أو لا يتبع الشركة'; end if;
  perform pg_advisory_xact_lock(hashtext('rawaea:purchase-order-code:'||p_company_id::text));
  select coalesce(max(nullif(regexp_replace(po_code,'[^0-9]','','g'),'')::bigint),1000) into v_last_num from public.purchase_orders where company_id=p_company_id;
  v_po_code:='PO-'||(v_last_num+1)::text;
  for v_item in select * from jsonb_to_recordset(p_items) as x(code text,name text,unit text,price numeric,qty numeric) loop
    if nullif(btrim(v_item.code),'') is null or coalesce(v_item.qty,0)<=0 or v_item.price is null or v_item.price<0 then raise exception 'بيانات صنف غير صالحة في أمر الشراء'; end if;
    if v_item.code=any(v_seen) then raise exception 'لا يجوز تكرار الصنف داخل نفس الأمر'; end if;
    v_seen:=array_append(v_seen,v_item.code);
    select * into v_master from public.items i where i.item_code=btrim(v_item.code);
    if not found then raise exception 'الصنف غير موجود: %',v_item.code; end if;
    v_total:=v_total+(v_item.price*v_item.qty);
  end loop;
  insert into public.purchase_orders(id,company_id,po_code,po_date,supplier_id,supplier_name,total_amount,status,created_by)
  values(gen_random_uuid(),p_company_id,v_po_code,current_date,v_supplier.id,coalesce(nullif(btrim(p_supplier_name),''),v_supplier.name),v_total,'Draft',p_user_email)
  returning id into v_po_id;
  for v_item in select * from jsonb_to_recordset(p_items) as x(code text,name text,unit text,price numeric,qty numeric) loop
    select * into v_master from public.items i where i.item_code=btrim(v_item.code);
    insert into public.purchase_order_details(id,po_id,item_id,item_code,item_name,unit,qty_ordered,unit_price)
    values(gen_random_uuid(),v_po_id,v_master.id,v_master.item_code,coalesce(nullif(btrim(v_item.name),''),v_master.name),coalesce(nullif(btrim(v_item.unit),''),v_master.unit),v_item.qty,v_item.price);
  end loop;
  insert into public.audit_log(user_email,action,table_name,record_id,new_data)
  values(p_user_email,'create','purchase_orders',v_po_id::text,jsonb_build_object('company_id',p_company_id,'po_code',v_po_code,'supplier_id',v_supplier.id,'total_amount',v_total));
  return jsonb_build_object('success',true,'poID',v_po_code,'po_id',v_po_id,'total_amount',v_total);
end;
$$;
revoke all on function public.save_purchase_order_atomic(uuid,uuid,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.save_purchase_order_atomic(uuid,uuid,text,text,jsonb) to service_role;

create or replace function public.submit_online_order_atomic(
  p_company_id uuid,
  p_customer_name text,
  p_customer_phone text,
  p_customer_area text,
  p_notes text,
  p_user_email text,
  p_cart_items jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_customer_id uuid;
  v_customer_code text;
  v_order_id uuid;
  v_order_code text;
  v_last_num bigint;
  v_delivery numeric := 0;
  v_tax_rate numeric := 0;
  v_subtotal numeric := 0;
  v_total numeric := 0;
  v_item record;
  v_master public.items%rowtype;
  v_existing public.customers%rowtype;
  v_settings record;
  v_seen text[] := '{}';
begin
  if not exists(select 1 from public.companies c where c.id=p_company_id) then raise exception 'سياق الشركة غير موجود'; end if;
  if nullif(btrim(p_customer_name),'') is null or nullif(btrim(p_customer_phone),'') is null or nullif(btrim(p_customer_area),'') is null then raise exception 'بيانات العميل غير مكتملة'; end if;
  if p_cart_items is null or jsonb_typeof(p_cart_items)<>'array' or jsonb_array_length(p_cart_items)=0 then raise exception 'السلة فارغة'; end if;
  select delivery_fee,tax_rate into v_settings from public.app_settings where company_id=p_company_id order by created_at asc,id asc limit 1;
  v_delivery:=coalesce(v_settings.delivery_fee,0); v_tax_rate:=coalesce(v_settings.tax_rate,0);
  select * into v_existing from public.customers where company_id=p_company_id and phone=btrim(p_customer_phone) order by created_at asc,id asc limit 1;
  if found then
    v_customer_id:=v_existing.id;
    update public.customers set name=p_customer_name,area=p_customer_area where id=v_customer_id and company_id=p_company_id;
  else
    perform pg_advisory_xact_lock(hashtext('rawaea:customer-code:'||p_company_id::text));
    select 'CUST-'||lpad((coalesce(max(nullif(regexp_replace(customer_code,'[^0-9]','','g'),'')::bigint),0)+1)::text,6,'0') into v_customer_code from public.customers where company_id=p_company_id;
    insert into public.customers(id,company_id,customer_code,name,phone,area,customer_type,payment_type,is_active)
    values(gen_random_uuid(),p_company_id,v_customer_code,p_customer_name,btrim(p_customer_phone),p_customer_area,'اونلاين','نقدي',true) returning id into v_customer_id;
  end if;
  for v_item in select * from jsonb_to_recordset(p_cart_items) as x(code text,name text,qty numeric,price numeric,unit text) loop
    if nullif(btrim(v_item.code),'') is null or coalesce(v_item.qty,0)<=0 then raise exception 'بيانات صنف غير صالحة'; end if;
    if v_item.code=any(v_seen) then raise exception 'لا يجوز تكرار الصنف داخل السلة'; end if;
    v_seen:=array_append(v_seen,v_item.code);
    select * into v_master from public.items where item_code=btrim(v_item.code) and coalesce(is_active,true) and coalesce(show_in_store,true);
    if not found then raise exception 'الصنف غير متاح: %',v_item.code; end if;
    v_subtotal:=v_subtotal+(v_master.sales_price*v_item.qty);
  end loop;
  v_total:=v_subtotal+v_delivery+round((v_subtotal+v_delivery)*v_tax_rate/100,2);
  perform pg_advisory_xact_lock(hashtext('rawaea:online-order-code:'||p_company_id::text));
  select coalesce(max(nullif(regexp_replace(order_code,'[^0-9]','','g'),'')::bigint),1000) into v_last_num from public.orders where company_id=p_company_id;
  v_order_code:='ORD-'||(v_last_num+1)::text;
  insert into public.orders(id,company_id,order_code,order_date,customer_id,customer_name,area,total_amount,original_total_amount,delivery_fee,order_status,payment_type,created_by,source,customer_phone,notes)
  values(gen_random_uuid(),p_company_id,v_order_code,current_date,v_customer_id,p_customer_name,p_customer_area,v_total,v_total,v_delivery,'Pending','نقدي','store','online_store',btrim(p_customer_phone),coalesce(p_notes,'')) returning id into v_order_id;
  for v_item in select * from jsonb_to_recordset(p_cart_items) as x(code text,name text,qty numeric,price numeric,unit text) loop
    select * into v_master from public.items where item_code=btrim(v_item.code);
    insert into public.order_details(id,order_id,item_id,item_code,item_name,unit,unit_price,qty)
    values(gen_random_uuid(),v_order_id,v_master.id,v_master.item_code,v_master.name,v_master.unit,v_master.sales_price,v_item.qty);
  end loop;
  insert into public.audit_log(user_email,action,table_name,record_id,new_data)
  values(p_user_email,'create','orders',v_order_id::text,jsonb_build_object('company_id',p_company_id,'order_code',v_order_code,'customer_id',v_customer_id,'total_amount',v_total,'source','online_store'));
  return jsonb_build_object('success',true,'orderCode',v_order_code,'order_id',v_order_id,'total',v_total,'delivery',v_delivery,'tax_rate',v_tax_rate);
end;
$$;
revoke all on function public.submit_online_order_atomic(uuid,text,text,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.submit_online_order_atomic(uuid,text,text,text,text,text,jsonb) to service_role;