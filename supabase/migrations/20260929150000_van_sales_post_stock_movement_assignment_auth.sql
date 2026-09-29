-- RAWAEA ERP
-- 2026-09-29 — Van Sales central stock authorization hardening
-- Purpose: allow VanSale physical stock movement for an authenticated Direct Sales
-- Representative through the canonical fleet_vehicle_sales_rep_assignments relation,
-- while preserving the legacy driver_id path for delivery drivers.
--
-- This migration changes ONLY the 10-argument central stock movement function.

create or replace function public.post_stock_movement(
  p_company_id uuid,
  p_movement_type text,
  p_source_branch_id uuid,
  p_target_branch_id uuid,
  p_item_id uuid,
  p_qty numeric,
  p_voucher_id text,
  p_reference text,
  p_user_email text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_source public.stock_branches%rowtype;
  v_target public.stock_branches%rowtype;
  v_item public.items%rowtype;
  v_existing public.inventory_log%rowtype;
  v_move_qty numeric := coalesce(p_qty, 0);
begin
  if v_move_qty <= 0 then
    raise exception 'كمية الحركة يجب أن تكون أكبر من صفر';
  end if;

  if p_movement_type not in (
    'PurchaseIn','TransferOut','TransferIn','POSSale','VanSale','DirectSale',
    'SalesReturn','DirectReturn','SupplierReturn','InventoryIncrease',
    'InventoryDecrease','Loading','Unloading'
  ) then
    raise exception 'نوع حركة مخزنية غير مدعوم: %', p_movement_type;
  end if;

  if nullif(btrim(p_idempotency_key), '') is not null then
    perform pg_advisory_xact_lock(
      hashtextextended(
        'RAWAEA:STOCK-IDEM:' || p_company_id::text || ':' || btrim(p_idempotency_key),
        0
      )
    );

    select * into v_existing
    from public.inventory_log
    where company_id = p_company_id
      and idempotency_key = btrim(p_idempotency_key)
    limit 1;

    if found then
      if v_existing.movement_type <> p_movement_type
         or v_existing.qty <> v_move_qty
         or v_existing.voucher_id is distinct from p_voucher_id
         or v_existing.reference is distinct from p_reference
         or v_existing.source_branch_id is distinct from p_source_branch_id
         or v_existing.target_branch_id is distinct from p_target_branch_id then
        raise exception 'idempotency key conflict: نفس المفتاح استُخدم لحركة مختلفة';
      end if;

      return jsonb_build_object(
        'success', true,
        'duplicate', true,
        'inventory_log_id', v_existing.id,
        'movement_type', v_existing.movement_type,
        'qty', v_existing.qty
      );
    end if;
  end if;

  select * into v_item
  from public.items
  where id = p_item_id
    and company_id = p_company_id;

  if not found then
    raise exception 'الصنف غير موجود أو لا يتبع الشركة';
  end if;

  if p_source_branch_id is not null and not exists (
    select 1
    from public.branches b
    where b.id = p_source_branch_id
      and b.company_id = p_company_id
  ) then
    raise exception 'فرع المصدر لا يتبع الشركة';
  end if;

  if p_target_branch_id is not null and not exists (
    select 1
    from public.branches b
    where b.id = p_target_branch_id
      and b.company_id = p_company_id
  ) then
    raise exception 'فرع الوجهة لا يتبع الشركة';
  end if;

  if p_movement_type = 'VanSale' then
    if p_source_branch_id is null then
      raise exception 'VanSale يتطلب مخزن مركبة كمصدر';
    end if;

    if not exists (
      select 1
      from public.vehicles v
      join public.users du
        on du.id = v.driver_id
       and du.company_id = p_company_id
      where v.company_id = p_company_id
        and v.status = 'Active'
        and coalesce(v.mobile_stock_enabled, true) = true
        and v.mobile_branch_id = p_source_branch_id
        and lower(coalesce(du.email, '')) = lower(coalesce(p_user_email, ''))
        and coalesce(du.status, 'Active') = 'Active'
    )
    and not exists (
      select 1
      from public.vehicles v
      join public.fleet_vehicle_sales_rep_assignments a
        on a.vehicle_id = v.id
       and a.company_id = p_company_id
       and a.is_primary = true
       and a.end_at is null
      join public.users sr
        on sr.id = a.sales_rep_user_id
       and sr.company_id = p_company_id
      where v.company_id = p_company_id
        and v.status = 'Active'
        and coalesce(v.mobile_stock_enabled, true) = true
        and v.mobile_branch_id = p_source_branch_id
        and lower(coalesce(sr.email, '')) = lower(coalesce(p_user_email, ''))
        and coalesce(sr.status, 'Active') = 'Active'
        and sr.role = 'مندوب بيع مباشر'
    ) then
      raise exception 'VanSale source branch must be the active mobile branch assigned to the authenticated driver or direct sales representative';
    end if;
  end if;

  if p_movement_type = 'DirectSale' and p_target_branch_id is null then
    raise exception 'DirectSale يتطلب مخزن مركبة كوجهة';
  end if;

  if p_source_branch_id is null and p_target_branch_id is null then
    raise exception 'يجب تحديد مصدر أو وجهة للحركة';
  end if;

  if p_movement_type in (
    'TransferIn','PurchaseIn','SalesReturn','DirectReturn','InventoryIncrease',
    'DirectSale','Loading','Unloading'
  ) then
    if p_target_branch_id is null then
      raise exception 'وجهة الحركة مطلوبة';
    end if;

    insert into public.stock_branches(
      id, branch_id, item_id, qty, allocated_qty, updated_at
    )
    values(
      gen_random_uuid(), p_target_branch_id, p_item_id, 0, 0, now()
    )
    on conflict (branch_id, item_id) do nothing;
  end if;

  perform 1
  from public.stock_branches
  where branch_id in (p_source_branch_id, p_target_branch_id)
    and item_id = p_item_id
  order by branch_id
  for update;

  if p_movement_type in (
    'TransferOut','POSSale','VanSale','DirectSale','SupplierReturn','InventoryDecrease','Loading','Unloading'
  ) then
    select * into v_source
    from public.stock_branches
    where branch_id = p_source_branch_id
      and item_id = p_item_id;

    if not found then
      raise exception 'رصيد المصدر غير موجود';
    end if;

    if p_movement_type = 'Loading' then
      if coalesce(v_source.allocated_qty, 0) < v_move_qty then
        raise exception 'كمية التحميل تتجاوز الكمية المحجوزة';
      end if;
      if coalesce(v_source.qty, 0) < v_move_qty then
        raise exception 'الرصيد الفعلي لا يكفي للحركة';
      end if;
    else
      if coalesce(v_source.qty, 0) < v_move_qty then
        raise exception 'الرصيد الفعلي لا يكفي للحركة';
      end if;
      if coalesce(v_source.qty, 0) - v_move_qty < coalesce(v_source.allocated_qty, 0) then
        raise exception 'لا يمكن خفض الرصيد الفعلي أسفل الرصيد المحجوز';
      end if;
    end if;
  end if;

  if p_movement_type = 'Loading' then
    update public.stock_branches
    set qty = qty - v_move_qty,
        allocated_qty = allocated_qty - v_move_qty,
        updated_at = now()
    where branch_id = p_source_branch_id
      and item_id = p_item_id;

    update public.stock_branches
    set qty = qty + v_move_qty,
        updated_at = now()
    where branch_id = p_target_branch_id
      and item_id = p_item_id;

  elsif p_movement_type = 'Unloading' then
    if p_source_branch_id is null or p_target_branch_id is null then
      raise exception 'حركة التفريغ تتطلب مصدر ووجهة';
    end if;

    if coalesce(v_source.qty, 0) < v_move_qty then
      raise exception 'رصيد السيارة لا يكفي للتفريغ';
    end if;

    update public.stock_branches
    set qty = qty - v_move_qty,
        updated_at = now()
    where branch_id = p_source_branch_id
      and item_id = p_item_id;

    update public.stock_branches
    set qty = qty + v_move_qty,
        updated_at = now()
    where branch_id = p_target_branch_id
      and item_id = p_item_id;

  elsif p_movement_type = 'DirectSale' then
    update public.stock_branches
    set qty = qty - v_move_qty,
        updated_at = now()
    where branch_id = p_source_branch_id
      and item_id = p_item_id;

    update public.stock_branches
    set qty = qty + v_move_qty,
        updated_at = now()
    where branch_id = p_target_branch_id
      and item_id = p_item_id;

  elsif p_movement_type in (
    'TransferOut','POSSale','VanSale','SupplierReturn','InventoryDecrease'
  ) then
    update public.stock_branches
    set qty = qty - v_move_qty,
        updated_at = now()
    where branch_id = p_source_branch_id
      and item_id = p_item_id;

  elsif p_movement_type in (
    'TransferIn','PurchaseIn','SalesReturn','DirectReturn','InventoryIncrease'
  ) then
    update public.stock_branches
    set qty = qty + v_move_qty,
        updated_at = now()
    where branch_id = p_target_branch_id
      and item_id = p_item_id;
  end if;

  insert into public.inventory_log(
    id, company_id, log_code, movement_date, voucher_id, item_id,
    item_code, item_name, movement_type, qty, reference, user_email,
    created_at, idempotency_key, source_branch_id, target_branch_id
  )
  values(
    gen_random_uuid(), p_company_id,
    'IL-' || replace(gen_random_uuid()::text, '-', ''),
    current_date, p_voucher_id, p_item_id,
    v_item.item_code, v_item.name, p_movement_type, v_move_qty,
    p_reference, p_user_email, now(),
    nullif(btrim(p_idempotency_key), ''),
    p_source_branch_id, p_target_branch_id
  );

  return jsonb_build_object(
    'success', true,
    'duplicate', false,
    'movement_type', p_movement_type,
    'qty', v_move_qty,
    'source_branch_id', p_source_branch_id,
    'target_branch_id', p_target_branch_id
  );
end;
$function$;
