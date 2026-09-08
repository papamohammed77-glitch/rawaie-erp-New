-- RAWAEA ERP — production reconciliation migration
-- Date: 2026-09-08
-- Purpose: close tenant/company leakage in SECURITY DEFINER get_balance_sheet_data.
-- The authoritative reporting contract is company context from app_private.current_user_company_id().

create or replace function public.get_balance_sheet_data(p_as_of date)
returns json
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $function$
declare
    v_company_id uuid := app_private.current_user_company_id();
    v_result json;
begin
    if v_company_id is null then
        return json_build_object('as_of_date',p_as_of,'assets','[]'::json,'liabilities','[]'::json,'equity','[]'::json);
    end if;

    select json_build_object(
        'as_of_date', p_as_of,
        'assets', (
            select coalesce(json_agg(json_build_object(
                'account_code', ca.account_code,
                'account_name', ca.account_name,
                'balance', public.get_account_balance_as_of(ca.id, p_as_of)
            ) order by ca.account_code), '[]'::json)
            from public.chart_of_accounts ca
            where ca.company_id = v_company_id
              and ca.account_type = 'asset'
              and ca.is_active = true
        ),
        'liabilities', (
            select coalesce(json_agg(json_build_object(
                'account_code', ca.account_code,
                'account_name', ca.account_name,
                'balance', public.get_account_balance_as_of(ca.id, p_as_of)
            ) order by ca.account_code), '[]'::json)
            from public.chart_of_accounts ca
            where ca.company_id = v_company_id
              and ca.account_type = 'liability'
              and ca.is_active = true
        ),
        'equity', (
            select coalesce(json_agg(json_build_object(
                'account_code', ca.account_code,
                'account_name', ca.account_name,
                'balance', public.get_account_balance_as_of(ca.id, p_as_of)
            ) order by ca.account_code), '[]'::json)
            from public.chart_of_accounts ca
            where ca.company_id = v_company_id
              and ca.account_type = 'equity'
              and ca.is_active = true
        )
    ) into v_result;
    return v_result;
end;
$function$;

revoke all on function public.get_balance_sheet_data(date) from public, anon, authenticated;
grant execute on function public.get_balance_sheet_data(date) to authenticated, service_role;
