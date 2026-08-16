-- Restore the canonical MAIN branch context for the legacy MAIN tenant used by Picking.
-- Idempotent: safe to re-apply after the production repair.
DO $$
declare
  v_company uuid := '00000000-0000-0000-0000-000000000001';
  v_branch uuid;
  v_settings_id uuid;
begin
  select id into v_branch
  from public.branches
  where company_id = v_company
    and branch_code = 'BR-01'
  limit 1;

  if v_branch is null then
    insert into public.branches (id, company_id, branch_code, name, is_active)
    values (gen_random_uuid(), v_company, 'BR-01', 'الفرع الرئيسي', true)
    returning id into v_branch;
  else
    update public.branches
    set name = coalesce(nullif(name, ''), 'الفرع الرئيسي'),
        is_active = true,
        updated_at = now()
    where id = v_branch;
  end if;

  select id into v_settings_id
  from public.app_settings
  where company_id = v_company
  order by created_at nulls first, id
  limit 1;

  if v_settings_id is null then
    insert into public.app_settings (
      id, company_id, main_branch_id, company_name, store_name
    )
    values (
      gen_random_uuid(), v_company, v_branch, 'الروائع', 'الروائع'
    );
  else
    update public.app_settings
    set main_branch_id = v_branch,
        updated_at = now()
    where id = v_settings_id;
  end if;

  insert into public.stock_branches (
    id, branch_id, item_id, qty, allocated_qty, updated_at
  )
  select
    gen_random_uuid(), v_branch, i.id, 0, 0, now()
  from public.items i
  where i.company_id = v_company
    and not exists (
      select 1
      from public.stock_branches sb
      where sb.branch_id = v_branch
        and sb.item_id = i.id
    );
end $$;
