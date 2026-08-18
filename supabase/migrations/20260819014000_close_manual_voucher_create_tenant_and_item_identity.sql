BEGIN;

CREATE OR REPLACE FUNCTION public.create_manual_stock_voucher_atomic(
  p_company_id uuid,
  p_type text,
  p_reference text,
  p_from_type text,
  p_from_id uuid,
  p_to_type text,
  p_to_id uuid,
  p_notes text,
  p_created_by text,
  p_items jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
declare
  v_voucher_id uuid;
  v_voucher_code text;
  v_item jsonb;
  v_item_id uuid;
  v_last_num bigint;
  v_valid boolean;
begin
  IF NOT EXISTS (SELECT 1 FROM public.companies c WHERE c.id = p_company_id) THEN
    RAISE EXCEPTION 'سياق الشركة غير موجود';
  END IF;

  if p_type not in ('Transfer','DirectSale','DirectReturn','SupplierReturn') then
    raise exception 'نوع الإذن غير مدعوم في دورة الأذونات الحالية';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'يجب إضافة صنف واحد على الأقل';
  end if;

  if p_type in ('Transfer','DirectSale','DirectReturn') then
    if p_from_type <> 'Branch' or p_from_id is null then raise exception 'مصدر الإذن يجب أن يكون فرعًا محددًا'; end if;
    if p_to_type <> 'Branch' or p_to_id is null then raise exception 'وجهة الإذن يجب أن تكون فرعًا محددًا'; end if;
  elsif p_type = 'SupplierReturn' then
    if p_from_type <> 'Branch' or p_from_id is null then raise exception 'مصدر مرتجع المورد يجب أن يكون فرعًا محددًا'; end if;
    if p_to_type <> 'Supplier' or p_to_id is null then raise exception 'وجهة مرتجع المورد يجب أن تكون موردًا محددًا'; end if;
  end if;

  if p_from_type = 'Branch' then
    select exists(select 1 from public.branches b where b.id=p_from_id and b.company_id=p_company_id) into v_valid;
    if not v_valid then raise exception 'فرع المصدر غير موجود أو لا يتبع الشركة الحالية'; end if;
  end if;
  if p_to_type = 'Branch' then
    select exists(select 1 from public.branches b where b.id=p_to_id and b.company_id=p_company_id) into v_valid;
    if not v_valid then raise exception 'فرع الوجهة غير موجود أو لا يتبع الشركة الحالية'; end if;
  end if;

  perform pg_advisory_xact_lock(hashtext('rawaea:stock-voucher-code'));
  select coalesce(max(substring(voucher_code from '[0-9]+$')::bigint),0)
    into v_last_num
  from public.stock_vouchers
  where company_id=p_company_id;

  v_voucher_code := 'IN-' || (v_last_num + 1)::text;

  insert into public.stock_vouchers(
    voucher_code,voucher_date,type,status,reference,from_type,from_id,to_type,to_id,
    notes,created_by,source,company_id
  )
  values(
    v_voucher_code,current_date,p_type,'Draft',coalesce(p_reference,''),p_from_type,p_from_id,
    p_to_type,p_to_id,coalesce(p_notes,''),p_created_by,'Manual',p_company_id
  )
  returning id into v_voucher_id;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if coalesce(nullif(v_item->>'itemCode',''),'')='' then raise exception 'كود الصنف مطلوب'; end if;
    if coalesce((v_item->>'qty')::numeric,0)<=0 then raise exception 'كمية الصنف يجب أن تكون أكبر من صفر'; end if;

    SELECT i.id INTO v_item_id
    FROM public.items i
    WHERE i.item_code = v_item->>'itemCode';

    IF v_item_id IS NULL THEN
      raise exception 'الصنف غير موجود: %',v_item->>'itemCode';
    END IF;

    if exists(select 1 from public.stock_voucher_details d where d.voucher_id=v_voucher_id and d.item_id=v_item_id) then
      raise exception 'لا يمكن تكرار الصنف داخل نفس الإذن: %',v_item->>'itemCode';
    end if;

    insert into public.stock_voucher_details(
      voucher_id,item_id,item_code,item_name,unit,qty,unit_price,notes
    )
    values(
      v_voucher_id,v_item_id,v_item->>'itemCode',
      coalesce(nullif(v_item->>'itemName',''),v_item->>'itemCode'),
      coalesce(nullif(v_item->>'unit',''),'حبة'),
      (v_item->>'qty')::numeric,
      coalesce((v_item->>'unitPrice')::numeric,0),
      coalesce(v_item->>'notes','')
    );
  end loop;

  return jsonb_build_object('success',true,'voucher_id',v_voucher_id,'voucher_code',v_voucher_code,'company_id',p_company_id);
end;
$function$;

REVOKE ALL ON FUNCTION public.create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)
  TO service_role;

COMMIT;
