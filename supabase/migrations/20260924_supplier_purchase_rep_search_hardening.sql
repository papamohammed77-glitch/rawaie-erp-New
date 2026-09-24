-- RAWAEA ERP — Supplier purchase-representative smart-search authority
-- Date: 2026-09-24
-- Scope:
--   1) Add authenticated, company-scoped lookup for active purchasing representatives.
--   2) Harden existing save_supplier_atomic to canonicalize/validate purchase_rep.
-- No new Edge Function. Existing save-supplier Edge Function remains the write gateway.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_supplier_purchase_reps(p_query text DEFAULT NULL)
RETURNS TABLE(
  id uuid,
  name text,
  email text,
  phone text,
  employee_id text,
  role_name text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_company_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'جلسة المصادقة غير صالحة';
  END IF;

  IF NOT app_private.current_user_has_permission('suppliers') THEN
    RAISE EXCEPTION 'لا تملك صلاحية الوصول إلى مندوبي المشتريات';
  END IF;

  SELECT u.company_id
    INTO v_company_id
  FROM public.users u
  WHERE u.auth_id = auth.uid()
    AND u.status IS DISTINCT FROM 'Inactive'
  LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'سياق الشركة غير متاح للمستخدم الحالي';
  END IF;

  RETURN QUERY
  WITH candidates AS (
    SELECT
      u.id,
      u.name::text AS name,
      u.email::text AS email,
      u.phone::text AS phone,
      u.employee_id::text AS employee_id,
      r.role_name::text AS role_name,
      lower(
        concat_ws(
          ' ',
          coalesce(u.name, ''),
          coalesce(u.email, ''),
          coalesce(u.phone, ''),
          coalesce(u.employee_id, '')
        )
      ) AS search_text
    FROM public.users u
    JOIN public.roles r
      ON r.id = u.role_id
     AND r.company_id = u.company_id
    WHERE u.company_id = v_company_id
      AND coalesce(u.status, 'Active') = 'Active'
      AND r.role_name = 'مسئول مشتريات'
  )
  SELECT
    c.id,
    c.name,
    c.email,
    c.phone,
    c.employee_id,
    c.role_name
  FROM candidates c
  WHERE nullif(btrim(p_query), '') IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM regexp_split_to_table(lower(btrim(p_query)), '\s+') AS token
       WHERE token <> ''
         AND position(token in c.search_text) = 0
     )
  ORDER BY
    CASE
      WHEN nullif(btrim(p_query), '') IS NOT NULL
       AND lower(c.name) LIKE lower(btrim(p_query)) || '%'
      THEN 0
      ELSE 1
    END,
    lower(c.name),
    c.id
  LIMIT 25;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_supplier_purchase_reps(text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_supplier_purchase_reps(text)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.save_supplier_atomic(
  p_auth_user_id uuid,
  p_company_id uuid,
  p_user_email text,
  p_supplier jsonb,
  p_is_edit boolean DEFAULT false,
  p_supplier_code text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
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
  v_purchase_rep_name text;
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

    if v_purchase_rep is not null then
      select u.name
        into v_purchase_rep_name
      from public.users u
      join public.roles r
        on r.id = u.role_id
       and r.company_id = u.company_id
      where u.company_id = p_company_id
        and coalesce(u.status,'Active') = 'Active'
        and r.role_name = 'مسئول مشتريات'
        and (
          lower(u.name) = lower(v_purchase_rep)
          or lower(u.email) = lower(v_purchase_rep)
        )
      order by lower(u.name), u.id
      limit 1;

      if v_purchase_rep_name is not null then
        v_purchase_rep := v_purchase_rep_name;
      elsif v_existing.purchase_rep is null
         or lower(v_existing.purchase_rep) <> lower(v_purchase_rep) then
        raise exception 'مسؤول المشتريات المحدد غير صالح أو غير نشط';
      end if;
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

  if v_purchase_rep is not null then
    select u.name
      into v_purchase_rep_name
    from public.users u
    join public.roles r
      on r.id = u.role_id
     and r.company_id = u.company_id
    where u.company_id = p_company_id
      and coalesce(u.status,'Active') = 'Active'
      and r.role_name = 'مسئول مشتريات'
      and (
        lower(u.name) = lower(v_purchase_rep)
        or lower(u.email) = lower(v_purchase_rep)
      )
    order by lower(u.name), u.id
    limit 1;

    if v_purchase_rep_name is null then
      raise exception 'مسؤول المشتريات المحدد غير صالح أو غير نشط';
    end if;

    v_purchase_rep := v_purchase_rep_name;
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

COMMIT;
