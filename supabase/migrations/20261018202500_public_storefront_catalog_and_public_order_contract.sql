-- RAWAEA public online storefront: safe catalog RPC + explicit storefront publication identity.
-- Intended to be applied to Production only after reviewing this canonical migration.
begin;

alter table public.app_settings
  add column if not exists storefront_key text,
  add column if not exists storefront_enabled boolean not null default false;

update public.app_settings
set storefront_key = 'company-1',
    storefront_enabled = true,
    updated_at = now()
where id = '74aeade7-57f2-48ae-9265-fa8fcd1a9d66'::uuid
  and company_id = '00000000-0000-0000-0000-000000000001'::uuid;

create unique index if not exists app_settings_storefront_key_uidx
  on public.app_settings (storefront_key)
  where storefront_key is not null;

create or replace function public.get_public_store_catalog(p_storefront_key text default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  v_settings public.app_settings%rowtype;
  v_enabled_count integer;
  v_products jsonb;
begin
  if nullif(btrim(p_storefront_key), '') is not null then
    select *
      into v_settings
      from public.app_settings
     where storefront_key = btrim(p_storefront_key)
       and storefront_enabled is true
     limit 1;
  else
    select count(*) into v_enabled_count
      from public.app_settings
     where storefront_enabled is true;

    if v_enabled_count <> 1 then
      raise exception 'storefront_key is required when zero or multiple storefronts are published';
    end if;

    select *
      into v_settings
      from public.app_settings
     where storefront_enabled is true
     order by created_at asc, id asc
     limit 1;
  end if;

  if not found then
    raise exception 'المتجر غير منشور أو مفتاح المتجر غير صالح';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'item_code', i.item_code,
        'barcode', i.barcode,
        'name', i.name,
        'unit', i.unit,
        'sales_price', i.sales_price,
        'old_price', i.old_price,
        'description', i.description,
        'image_url', i.image_url,
        'category', i.category,
        'is_active', i.is_active,
        'show_in_store', i.show_in_store,
        'discount_percent', i.discount_percent,
        'discount_start', i.discount_start,
        'discount_end', i.discount_end,
        'is_daily_deal', i.is_daily_deal,
        'badge_text', i.badge_text,
        'max_qty_per_order', i.max_qty_per_order,
        'sort_order', i.sort_order,
        'qty', greatest(coalesce(sb.available_qty, sb.qty - sb.allocated_qty, 0), 0)
      )
      order by coalesce(i.sort_order, 2147483647), i.name, i.item_code
    ),
    '[]'::jsonb
  )
  into v_products
  from public.items i
  left join public.stock_branches sb
    on sb.item_id = i.id
   and sb.branch_id = v_settings.main_branch_id
  where i.company_id = v_settings.company_id
    and i.is_active is true
    and i.show_in_store is true;

  return jsonb_build_object(
    'settings', jsonb_build_object(
      'storeName', coalesce(v_settings.store_name, v_settings.company_name, 'متجر الروائع'),
      'storeLogo', coalesce(v_settings.store_logo, v_settings.company_logo, ''),
      'primaryColor', coalesce(v_settings.store_primary_color, '#2563eb'),
      'secondaryColor', coalesce(v_settings.store_secondary_color, ''),
      'deliveryFee', coalesce(v_settings.delivery_fee, 0),
      'taxRate', coalesce(v_settings.tax_rate, 0),
      'minInvoiceAmount', coalesce(v_settings.min_invoice_amount, 0),
      'freeShippingThreshold', coalesce(v_settings.free_shipping_threshold, 0),
      'paymentMethod', coalesce(v_settings.payment_method, 'both'),
      'currency', coalesce(v_settings.currency, 'SAR')
    ),
    'products', v_products
  );
end;
$function$;

revoke all on function public.get_public_store_catalog(text) from public, anon, authenticated;
grant execute on function public.get_public_store_catalog(text) to anon, authenticated;

commit;
