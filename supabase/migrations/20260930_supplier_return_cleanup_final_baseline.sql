-- Final baseline after controlled cleanup of experimental SupplierReturn records.
-- The destructive cleanup itself was executed on Production through a restricted
-- service-role correction path and is intentionally NOT repeated here.
-- This migration only guarantees that the temporary cleanup backdoor is absent
-- and normal voucher deletion guards are restored.

drop function if exists public.correct_delete_experimental_supplier_returns(uuid,text[],text);

create or replace function public.guard_stock_voucher_delete_integrity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_allow text;
  v_movement_count bigint;
begin
  v_allow := current_setting('app.allow_draft_voucher_delete', true);

  if coalesce(v_allow,'') <> 'true'
     or old.status <> 'Draft'
     or coalesce(old.source,'Manual') <> 'Manual' then
    raise exception 'لا يجوز حذف مستند مخزني بعد دخوله دورة التنفيذ؛ الحذف متاح للمسودة اليدوية غير المنفذة فقط';
  end if;

  select count(*)
    into v_movement_count
  from public.inventory_log il
  where il.company_id=old.company_id
    and (
      il.voucher_id=old.voucher_code
      or il.reference=old.voucher_code
      or il.idempotency_key like 'StockVoucherSend:'||old.company_id::text||':'||old.id::text||':%'
      or il.idempotency_key like 'PurchaseReceipt:%'
    )
    and (
      il.voucher_id=old.voucher_code
      or il.reference=old.voucher_code
      or il.idempotency_key like 'StockVoucherSend:'||old.company_id::text||':'||old.id::text||':%'
    );

  if v_movement_count > 0 then
    raise exception 'لا يمكن حذف إذن سبق أن أنشأ حركة مخزنية';
  end if;

  return old;
end;
$function$;

create or replace function public.guard_stock_voucher_detail_delete_integrity()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_status text;
begin
  select status into v_status
  from public.stock_vouchers
  where id=old.voucher_id;

  if v_status is null then
    raise exception 'لا يجوز حذف تفاصيل إذن مخزني غير موجود';
  end if;

  if v_status <> 'Draft' then
    raise exception 'لا يجوز حذف تفاصيل إذن مخزني بعد خروجه من حالة المسودة';
  end if;

  return old;
end;
$function$;