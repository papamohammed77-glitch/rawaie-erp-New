begin;

alter table public.companies
  add column if not exists main_branch_id uuid,
  add column if not exists main_branch_code text;

comment on column public.companies.main_branch_id is
  'COMPATIBILITY READ PROJECTION ONLY. Authoritative source is app_settings.main_branch_id. Do not write business logic against this column.';
comment on column public.companies.main_branch_code is
  'COMPATIBILITY READ PROJECTION ONLY. Authoritative source is branches.branch_code via app_settings.main_branch_id. Do not write business logic against this column.';

create or replace function public.sync_company_main_branch_projection()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_code text;
begin
  select b.branch_code
    into v_branch_code
  from public.branches b
  where b.id = new.main_branch_id
    and b.company_id = new.company_id;

  if new.main_branch_id is not null and v_branch_code is null then
    raise exception 'Invalid main branch context for company %', new.company_id;
  end if;

  update public.companies c
     set main_branch_id = new.main_branch_id,
         main_branch_code = v_branch_code,
         updated_at = now()
   where c.id = new.company_id;

  return new;
end;
$$;

comment on function public.sync_company_main_branch_projection() is
  'Compatibility projection synchronizer. app_settings.main_branch_id remains the sole authoritative source.';

drop trigger if exists trg_sync_company_main_branch_projection on public.app_settings;
create trigger trg_sync_company_main_branch_projection
after insert or update of company_id, main_branch_id
on public.app_settings
for each row
execute function public.sync_company_main_branch_projection();

update public.companies c
   set main_branch_id = a.main_branch_id,
       main_branch_code = b.branch_code,
       updated_at = now()
  from public.app_settings a
  left join public.branches b
    on b.id = a.main_branch_id
   and b.company_id = a.company_id
 where a.company_id = c.id
   and (a.main_branch_id is null or b.id is not null);

commit;
