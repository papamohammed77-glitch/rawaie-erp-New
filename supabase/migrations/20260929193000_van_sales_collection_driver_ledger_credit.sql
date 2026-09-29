-- Van Sales customer collection: atomically reduce the sales representative custody liability.
-- Applied to Production on 2026-09-29 in migration 20260929193000.

CREATE OR REPLACE FUNCTION public.post_van_sales_collection_atomic(
  p_company_id uuid,
  p_operation_id uuid,
  p_customer_id uuid,
  p_driver_email text,
  p_amount numeric,
  p_entry_date date,
  p_treasury_id uuid DEFAULT NULL::uuid,
  p_cash_account_id uuid DEFAULT NULL::uuid,
  p_ar_account_id uuid DEFAULT NULL::uuid,
  p_reference text DEFAULT NULL::text,
  p_description text DEFAULT 'تحصيل من عميل'::text,
  p_notes text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_existing public.erp_operation_registry%rowtype;
  v_customer public.customers%rowtype;
  v_driver public.users%rowtype;
  v_treasury public.treasury%rowtype;
  v_cash_account public.chart_of_accounts%rowtype;
  v_ar_account public.chart_of_accounts%rowtype;
  v_treasury_count integer:=0;
  v_receipt jsonb;
  v_customer_ledger jsonb;
  v_driver_ledger jsonb;
  v_result jsonb;
begin
  if p_company_id is null then raise exception 'VAN_COLLECTION_COMPANY_REQUIRED'; end if;
  if p_operation_id is null then raise exception 'VAN_COLLECTION_OPERATION_ID_REQUIRED'; end if;
  if p_customer_id is null then raise exception 'VAN_COLLECTION_CUSTOMER_REQUIRED'; end if;
  if nullif(btrim(coalesce(p_driver_email,'')),'') is null then raise exception 'VAN_COLLECTION_USER_REQUIRED'; end if;
  if p_amount is null or p_amount<=0 then raise exception 'VAN_COLLECTION_AMOUNT_INVALID'; end if;
  if p_entry_date is null then raise exception 'VAN_COLLECTION_DATE_REQUIRED'; end if;

  insert into public.erp_operation_registry(
    company_id,operation_type,operation_key,request_payload,status
  )
  values(
    p_company_id,
    'post_van_sales_collection',
    p_operation_id::text,
    jsonb_build_object(
      'customer_id',p_customer_id,
      'driver_email',p_driver_email,
      'amount',p_amount,
      'reference',p_reference
    ),
    'processing'
  )
  on conflict(company_id,operation_type,operation_key) do nothing;

  select * into v_existing
  from public.erp_operation_registry
  where company_id=p_company_id
    and operation_type='post_van_sales_collection'
    and operation_key=p_operation_id::text
  for update;

  if v_existing.status='completed' and v_existing.response_payload is not null then
    return v_existing.response_payload||jsonb_build_object('duplicate',true);
  end if;

  select * into v_driver
  from public.users
  where company_id=p_company_id
    and lower(email)=lower(p_driver_email)
    and coalesce(status,'Active')='Active'
    and role='مندوب بيع مباشر'
  for update;

  if not found then raise exception 'VAN_COLLECTION_DRIVER_NOT_FOUND_OR_WRONG_COMPANY'; end if;

  select * into v_customer
  from public.customers
  where id=p_customer_id
    and company_id=p_company_id
    and coalesce(is_active,true)=true
  for update;

  if not found then raise exception 'VAN_COLLECTION_CUSTOMER_NOT_FOUND_OR_WRONG_COMPANY'; end if;

  if p_treasury_id is null then
    select count(*) into v_treasury_count
    from public.treasury
    where company_id=p_company_id
      and coalesce(is_active,true)=true;

    if v_treasury_count=1 then
      select id into p_treasury_id
      from public.treasury
      where company_id=p_company_id
        and coalesce(is_active,true)=true
      limit 1;
    end if;

    if v_treasury_count<>1 or p_treasury_id is null then
      raise exception 'VAN_COLLECTION_TREASURY_MAPPING_REQUIRED';
    end if;
  end if;

  select * into v_treasury
  from public.treasury
  where id=p_treasury_id
    and company_id=p_company_id
    and coalesce(is_active,true)=true
  for update;

  if not found then raise exception 'VAN_COLLECTION_TREASURY_NOT_FOUND_OR_WRONG_COMPANY'; end if;

  if p_cash_account_id is null then
    select id into p_cash_account_id
    from public.chart_of_accounts
    where company_id=p_company_id
      and account_code='121'
      and coalesce(is_active,true)=true
    limit 1;
  end if;

  if p_ar_account_id is null then
    select id into p_ar_account_id
    from public.chart_of_accounts
    where company_id=p_company_id
      and account_code='123'
      and coalesce(is_active,true)=true
    limit 1;
  end if;

  if p_cash_account_id is null or p_ar_account_id is null then
    raise exception 'VAN_COLLECTION_FINANCIAL_ACCOUNTS_REQUIRED';
  end if;

  select * into v_cash_account
  from public.chart_of_accounts
  where id=p_cash_account_id
    and company_id=p_company_id
    and coalesce(is_active,true)=true
  for update;

  if not found then raise exception 'VAN_COLLECTION_CASH_ACCOUNT_INVALID'; end if;

  select * into v_ar_account
  from public.chart_of_accounts
  where id=p_ar_account_id
    and company_id=p_company_id
    and coalesce(is_active,true)=true
  for update;

  if not found then raise exception 'VAN_COLLECTION_AR_ACCOUNT_INVALID'; end if;

  v_receipt:=public.post_cash_receipt_atomic(
    p_company_id,
    p_operation_id,
    p_treasury_id,
    p_cash_account_id,
    p_ar_account_id,
    p_amount,
    p_entry_date,
    p_reference,
    coalesce(p_description,'تحصيل من عميل'),
    p_driver_email,
    v_customer.name,
    'VAN_SALES_COLLECTION',
    p_customer_id,
    p_notes,
    null
  );

  v_customer_ledger:=public.post_customer_ledger_entry(
    p_company_id,
    p_operation_id,
    p_customer_id,
    p_entry_date,
    coalesce(p_reference,'COL-'||p_operation_id::text),
    coalesce(p_description,'تحصيل من عميل'),
    0,
    p_amount,
    p_entry_date,
    p_driver_email
  );

  v_driver_ledger:=public.post_driver_ledger_entry(
    p_company_id,
    p_operation_id,
    p_driver_email,
    p_entry_date,
    coalesce(p_reference,'COL-'||p_operation_id::text),
    coalesce(p_description,'تحصيل من عميل'),
    0,
    p_amount
  );

  v_result:=jsonb_build_object(
    'success',true,
    'duplicate',false,
    'operation_id',p_operation_id,
    'company_id',p_company_id,
    'customer_id',p_customer_id,
    'customer_code',v_customer.customer_code,
    'driver_email',p_driver_email,
    'amount',p_amount,
    'receipt',v_receipt,
    'customer_ledger',v_customer_ledger,
    'driver_ledger',v_driver_ledger
  );

  update public.erp_operation_registry
  set status='completed',
      response_payload=v_result,
      completed_at=now()
  where company_id=p_company_id
    and operation_type='post_van_sales_collection'
    and operation_key=p_operation_id::text;

  return v_result;

exception when others then
  update public.erp_operation_registry
  set status='failed',
      response_payload=jsonb_build_object('success',false,'error',sqlerrm),
      completed_at=now()
  where company_id=p_company_id
    and operation_type='post_van_sales_collection'
    and operation_key=p_operation_id::text
    and status<>'completed';
  raise;
end;
$function$;
