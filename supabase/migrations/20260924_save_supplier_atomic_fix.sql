create or replace function public.save_supplier_atomic(
  p_auth_user_id uuid,
  p_company_id uuid,
  p_user_email text,
  p_supplier jsonb,
  p_is_edit boolean default false,
  p_supplier_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_user public.users%rowtype;
  v_auth auth.users%rowtype;
  v_owner_profile public.owner_profile%rowtype;
  v_is_owner boolean := false;
  v_existing public.suppliers%rowtype;
  v_supplier_id uuid;
  v_code text;
  v_last_num bigint;
  v_name text;
  v_phone text;
  v_area text;
  v_address text;
  v_supplier_type text;
  v_payment_type text;
  v_contact_person text;
  v_purchase_rep text;
  v_notes text;
begin
  if p_auth_user_id is null or p_company_id is null then
    raise exception 'سياق المصادقة والشركة مطلوب';
  end if;

  select *
    into v_user
  from public.users u
  where u.auth_id = p_auth_user_id
  limit 1;

  if not found or v_user.status = 'Inactive' or v_user.company_id <> p_company_id then
    raise exception 'سياق المستخدم غير صالح';
  end if;

  select *
    into v_auth
  from auth.users au
  where au.id = p_auth_user_id;

  if not found then
    raise exception 'مستخدم المصادقة غير موجود';
  end if;

  select *
    into v_owner_profile
  from public.owner_profile op
  where op.auth_user_id = p_auth_user_id
  limit 1;

  v_is_owner :=
    lower(coalesce(v_auth.raw_user_meta_data->>'isOwner','false')) = 'true'
    and jsonb_typeof(coalesce(v_user.permissions,'[]'::jsonb)) = 'array'
    and v_user.permissions ? '*'
    and v_owner_profile.id is not null;

  if not v_is_owner
     and not (
       jsonb_typeof(coalesce(v_user.permissions,'[]'::jsonb)) = 'array'
       and (
         v_user.permissions ? '*'
         or v_user.permissions ? 'suppliers'
       )
     ) then
    raise exception 'لا تملك صلاحية تنفيذ هذه العملية';
  end if;

  v_name := btrim(coalesce(p_supplier->>'name',''));
  if v_name = '' then
    raise exception 'اسم المورد مطلوب';
  end if;

  v_phone := nullif(btrim(coalesce(p_supplier->>'phone','')),'');
  v_area := nullif(btrim(coalesce(p_supplier->>'area','')),'');
  v_address := nullif(btrim(coalesce(p_supplier->>'address','')),'');
  v_supplier_type := nullif(btrim(coalesce(p_supplier->>'supplier_type','')),'');
  v_payment_type := nullif(btrim(coalesce(p_supplier->>'payment_type','')),'');
  v_contact_person := nullif(btrim(coalesce(p_supplier->>'contact_person','')),'');
  v_purchase_rep := nullif(btrim(coalesce(p_supplier->>'purchase_rep','')),'');
  v_notes := nullif(btrim(coalesce(p_supplier->>'notes','')),'');

  if p_is_edit then
    if nullif(btrim(coalesce(p_supplier_code,'')),'') is null then
      raise exception 'كود المورد مطلوب للتعديل';
    end if;

    select *
      into v_existing
    from public.suppliers s
    where s.company_id = p_company_id
      and s.supplier_code = btrim(p_supplier_code)
    for update;

    if not found then
      raise exception 'المورد غير موجود';
    end if;

    update public.suppliers
       set name = v_name,
           phone = v_phone,
           area = v_area,
           address = v_address,
           supplier_type = coalesce(v_supplier_type, 'مورد عام'),
           payment_type = coalesce(v_payment_type, 'نقدي'),
           accounts_payable = coalesce(v_existing.accounts_payable, 0),
           contact_person = v_contact_person,
           purchase_rep = v_purchase_rep,
           notes = v_notes
     where id = v_existing.id
       and company_id = p_company_id
    returning id, supplier_code into v_supplier_id, v_code;

    return jsonb_build_object(
      'success', true,
      'action', 'updated',
      'supplier_id', v_supplier_id,
      'supplier_code', v_code
    );
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'rawaea:supplier-code:' || p_company_id::text,
      0
    )
  );

  select coalesce(
           max((regexp_replace(s.supplier_code, '^SUPP-', ''))::bigint),
           1000
         )
    into v_last_num
  from public.suppliers s
  where s.company_id = p_company_id
    and s.supplier_code ~ '^SUPP-[0-9]+$';

  v_code := 'SUPP-' || (v_last_num + 1)::text;

  insert into public.suppliers(
    company_id,
    supplier_code,
    name,
    phone,
    area,
    address,
    supplier_type,
    payment_type,
    accounts_payable,
    contact_person,
    purchase_rep,
    notes,
    is_active
  )
  values(
    p_company_id,
    v_code,
    v_name,
    v_phone,
    v_area,
    v_address,
    coalesce(v_supplier_type, 'مورد عام'),
    coalesce(v_payment_type, 'نقدي'),
    0,
    v_contact_person,
    v_purchase_rep,
    v_notes,
    true
  )
  returning id into v_supplier_id;

  return jsonb_build_object(
    'success', true,
    'action', 'created',
    'supplier_id', v_supplier_id,
    'supplier_code', v_code
  );
end;
$function$;

revoke all on function public.save_supplier_atomic(uuid,uuid,text,jsonb,boolean,text)
  from public, anon, authenticated;

grant execute on function public.save_supplier_atomic(uuid,uuid,text,jsonb,boolean,text)
  to service_role;