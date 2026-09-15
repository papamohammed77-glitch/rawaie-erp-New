BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_get_reports(p_company_id uuid, p_as_of_date date DEFAULT CURRENT_DATE)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
declare out jsonb;
begin
  if p_company_id is null or not exists(select 1 from public.companies where id=p_company_id) then raise exception 'COMPANY_INVALID'; end if;
  select jsonb_build_object(
    'as_of_date',p_as_of_date,
    'requests',jsonb_build_object('open',coalesce((select count(*) from purchase_requests where company_id=p_company_id and status not in('Rejected','Converted','Cancelled')),0),'pending_approval',coalesce((select count(*) from purchase_requests where company_id=p_company_id and status='PendingApproval'),0)),
    'rfqs',jsonb_build_object('open',coalesce((select count(*) from purchase_rfqs where company_id=p_company_id and status not in('Closed','Cancelled','Converted')),0),'supplier_invites',coalesce((select count(*) from purchase_rfq_suppliers r join purchase_rfqs q on q.id=r.rfq_id where q.company_id=p_company_id),0)),
    'quotations',jsonb_build_object('submitted',coalesce((select count(*) from purchase_quotations where company_id=p_company_id and status='Submitted'),0),'accepted',coalesce((select count(*) from purchase_quotations where company_id=p_company_id and status='Accepted'),0)),
    'orders',jsonb_build_object('open',coalesce((select count(*) from purchase_orders where company_id=p_company_id and status not in('Received','Cancelled')),0),'value',coalesce((select sum(total_amount) from purchase_orders where company_id=p_company_id and status not in('Cancelled')),0)),
    'invoices',jsonb_build_object('open',coalesce((select count(*) from purchase_invoices where company_id=p_company_id and status in('Draft','Posted','PartiallyPaid')),0),'outstanding',coalesce((select sum(greatest(0,total_amount-paid_amount)) from purchase_invoices where company_id=p_company_id and status in('Posted','PartiallyPaid')),0),'unbilled_receipts',coalesce((select sum(greatest(0,d.qty_received-d.qty_ordered)*d.unit_price) from purchase_order_details d join purchase_orders po on po.id=d.po_id where po.company_id=p_company_id and d.qty_received>d.qty_ordered),0)),
    'payments',jsonb_build_object('posted_amount',coalesce((select sum(amount) from purchase_payments where company_id=p_company_id and status='Posted'),0)),
    'returns',jsonb_build_object('open',coalesce((select count(*) from purchase_returns where company_id=p_company_id and status='Draft'),0),'posted_value',coalesce((select sum(total_amount) from purchase_returns where company_id=p_company_id and status='Posted'),0)),
    'supplier_aging',coalesce((select jsonb_agg(to_jsonb(x) order by net_balance desc) from public.accountant_supplier_aging(p_as_of_date) x where x.supplier_id in(select id from suppliers where company_id=p_company_id)), '[]'::jsonb),
    'quotation_comparison',coalesce((select jsonb_agg(to_jsonb(c) order by c.item_code,c.price_rank) from purchase_quotation_comparison c where c.company_id=p_company_id),'[]'::jsonb)
  ) into out;
  return out;
end;
$function$;

CREATE OR REPLACE FUNCTION public.purchase_set_settings_atomic(p_company_id uuid, p_actor text, p_settings jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
declare s public.purchase_settings%rowtype; v_default_branch uuid;
begin
  if p_company_id is null or not exists(select 1 from public.companies where id=p_company_id) then raise exception 'COMPANY_INVALID'; end if;
  if p_settings is null or jsonb_typeof(p_settings)<>'object' then raise exception 'PURCHASE_SETTINGS_INVALID'; end if;
  if p_settings ? 'default_branch_id' then
    v_default_branch := nullif(p_settings->>'default_branch_id','')::uuid;
    if v_default_branch is not null and not exists(select 1 from public.branches b where b.id=v_default_branch and b.company_id=p_company_id and coalesce(b.is_active,true)) then raise exception 'PURCHASE_DEFAULT_BRANCH_INVALID'; end if;
  end if;
  insert into public.purchase_settings(company_id) values(p_company_id) on conflict(company_id) do nothing;
  update public.purchase_settings set
    default_currency=coalesce(nullif(btrim(p_settings->>'default_currency'),''),default_currency),
    request_prefix=coalesce(nullif(btrim(p_settings->>'request_prefix'),''),request_prefix),
    rfq_prefix=coalesce(nullif(btrim(p_settings->>'rfq_prefix'),''),rfq_prefix),
    quotation_prefix=coalesce(nullif(btrim(p_settings->>'quotation_prefix'),''),quotation_prefix),
    invoice_prefix=coalesce(nullif(btrim(p_settings->>'invoice_prefix'),''),invoice_prefix),
    return_prefix=coalesce(nullif(btrim(p_settings->>'return_prefix'),''),return_prefix),
    payment_prefix=coalesce(nullif(btrim(p_settings->>'payment_prefix'),''),payment_prefix),
    require_request_approval=coalesce((p_settings->>'require_request_approval')::boolean,require_request_approval),
    require_receiving_before_invoice=coalesce((p_settings->>'require_receiving_before_invoice')::boolean,require_receiving_before_invoice),
    require_invoice_before_payment=coalesce((p_settings->>'require_invoice_before_payment')::boolean,require_invoice_before_payment),
    require_inventory_on_invoice=coalesce((p_settings->>'require_inventory_on_invoice')::boolean,require_inventory_on_invoice),
    require_inventory_voucher_on_return=coalesce((p_settings->>'require_inventory_voucher_on_return')::boolean,require_inventory_voucher_on_return),
    default_branch_id=case when p_settings ? 'default_branch_id' then v_default_branch else default_branch_id end,
    updated_at=now()
  where company_id=p_company_id
  returning * into s;
  if p_actor is not null then insert into public.audit_log(user_email,action,table_name,record_id,new_data) values(p_actor,'update','purchase_settings',p_company_id::text,to_jsonb(s)); end if;
  return jsonb_build_object('success',true,'company_id',p_company_id,'settings',to_jsonb(s));
end;
$function$;

COMMIT;
