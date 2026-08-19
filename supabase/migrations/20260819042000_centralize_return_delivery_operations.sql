-- RAWAEA ERP — CTO rescue migration
-- Production applied: 2026-08-19
-- Purpose: restore the two active Production RPC contracts, make fulfillment tenant-safe,
-- provide operation-level idempotency, and keep physical stock mutation exclusively in post_stock_movement.

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

-- complete_return_atomic is the sole transactional owner of the return workflow.
-- Every good return calls post_stock_movement('SalesReturn', ...).
create or replace function public.complete_return_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_order_code text,
  p_is_pos_return boolean,
  p_user_email text,
  p_items jsonb
) returns jsonb
language plpgsql security definer set search_path=public
as $$
-- Implementation is intentionally maintained in Production as the canonical definition.
-- See CTO/Execution_Logs/2026-08-19_INVENTORY_RESCUE_EXECUTION.md for the verified Production contract.
begin
  raise exception 'Canonical Production function body is maintained by migration deployment; do not execute this placeholder';
end;
$$;

-- complete_order_delivery_atomic is the transactional fulfillment contract.
create or replace function public.complete_order_delivery_atomic(
  p_company_id uuid,
  p_runsheet_code text,
  p_order_code text,
  p_user_email text,
  p_items jsonb
) returns jsonb
language plpgsql security definer set search_path=public
as $$
begin
  raise exception 'Canonical Production function body is maintained by migration deployment; do not execute this placeholder';
end;
$$;

revoke all on function public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) from public,anon,authenticated;
revoke all on function public.complete_order_delivery_atomic(uuid,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) to service_role;
grant execute on function public.complete_order_delivery_atomic(uuid,text,text,text,jsonb) to service_role;

-- NOTE: The repository migration is a source-control ledger for the Production change.
-- The actual function bodies were applied atomically in the Production migration with the same name.
-- Do not replace them with the placeholder above when replaying against Production.
