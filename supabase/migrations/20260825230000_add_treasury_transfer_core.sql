-- 20260825230000_add_treasury_transfer_core.sql
-- Khalid / Prompt 61: canonical treasury transfer writer.
-- Production authority: SMART ERP.

create or replace function public.post_treasury_transfer_atomic(
    p_company_id uuid,
    p_operation_id uuid,
    p_source_treasury_id uuid,
    p_target_treasury_id uuid,
    p_source_account_id uuid,
    p_target_account_id uuid,
    p_amount numeric,
    p_transfer_date date,
    p_reference text,
    p_description text,
    p_created_by text,
    p_notes text default null
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_existing erp_operation_registry%rowtype;
    v_source treasury%rowtype;
    v_target treasury%rowtype;
    v_journal jsonb;
    v_ref text;
    v_out_code text;
    v_in_code text;
begin
    if p_company_id is null then raise exception 'TREASURY_TRANSFER_COMPANY_REQUIRED'; end if;
    if p_operation_id is null then raise exception 'TREASURY_TRANSFER_OPERATION_ID_REQUIRED'; end if;
    if p_source_treasury_id is null or p_target_treasury_id is null then raise exception 'TREASURY_TRANSFER_TREASURY_REQUIRED'; end if;
    if p_source_treasury_id = p_target_treasury_id then raise exception 'TREASURY_TRANSFER_SOURCE_EQUALS_TARGET'; end if;
    if p_source_account_id is null or p_target_account_id is null then raise exception 'TREASURY_TRANSFER_ACCOUNT_REQUIRED'; end if;
    if p_amount is null or p_amount <= 0 then raise exception 'TREASURY_TRANSFER_AMOUNT_INVALID'; end if;
    if p_transfer_date is null then raise exception 'TREASURY_TRANSFER_DATE_REQUIRED'; end if;
    if nullif(btrim(coalesce(p_created_by,'')),'') is null then raise exception 'TREASURY_TRANSFER_CREATED_BY_REQUIRED'; end if;
    if not exists (select 1 from companies c where c.id=p_company_id) then raise exception 'TREASURY_TRANSFER_COMPANY_NOT_FOUND'; end if;

    insert into erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
    values (p_company_id,'post_treasury_transfer',p_operation_id::text,
            jsonb_build_object('source_treasury_id',p_source_treasury_id,'target_treasury_id',p_target_treasury_id,'source_account_id',p_source_account_id,'target_account_id',p_target_account_id,'amount',p_amount,'transfer_date',p_transfer_date,'reference',p_reference,'description',p_description),
            'processing')
    on conflict(company_id,operation_type,operation_key) do nothing;

    select * into v_existing
    from erp_operation_registry
    where company_id=p_company_id and operation_type='post_treasury_transfer' and operation_key=p_operation_id::text
    for update;

    if v_existing.status='completed' and v_existing.response_payload is not null then
        return v_existing.response_payload || jsonb_build_object('duplicate',true);
    end if;

    select * into v_source from treasury where id=p_source_treasury_id and company_id=p_company_id and is_active=true for update;
    if not found then raise exception 'TREASURY_TRANSFER_SOURCE_NOT_FOUND_OR_WRONG_COMPANY'; end if;

    select * into v_target from treasury where id=p_target_treasury_id and company_id=p_company_id and is_active=true for update;
    if not found then raise exception 'TREASURY_TRANSFER_TARGET_NOT_FOUND_OR_WRONG_COMPANY'; end if;

    if coalesce(v_source.current_balance,0) < p_amount then raise exception 'TREASURY_TRANSFER_INSUFFICIENT_SOURCE_BALANCE'; end if;
    if not exists(select 1 from chart_of_accounts where id=p_source_account_id and company_id=p_company_id and coalesce(is_active,true)=true) then raise exception 'TREASURY_TRANSFER_SOURCE_ACCOUNT_INVALID'; end if;
    if not exists(select 1 from chart_of_accounts where id=p_target_account_id and company_id=p_company_id and coalesce(is_active,true)=true) then raise exception 'TREASURY_TRANSFER_TARGET_ACCOUNT_INVALID'; end if;

    v_ref := coalesce(nullif(btrim(p_reference),''),'TRF-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISSMS'));
    v_out_code := v_ref||'-OUT';
    v_in_code := v_ref||'-IN';

    insert into cash_box(voucher_code,voucher_date,treasury_id,type,amount,reference,notes,status,user_email,company_id)
    values
        (v_out_code,p_transfer_date,p_source_treasury_id,'Transfer-Out',p_amount,v_ref,p_notes,'Active',p_created_by,p_company_id),
        (v_in_code,p_transfer_date,p_target_treasury_id,'Transfer-In',p_amount,v_ref,p_notes,'Active',p_created_by,p_company_id);

    v_journal := jsonb_build_array(
        jsonb_build_object('account_id',p_target_account_id,'debit',p_amount,'credit',0,'notes',coalesce(p_notes,'Treasury transfer in')),
        jsonb_build_object('account_id',p_source_account_id,'debit',0,'credit',p_amount,'notes',coalesce(p_notes,'Treasury transfer out'))
    );

    perform public.post_journal_entry(
        p_company_id,
        p_operation_id,
        p_transfer_date,
        'TreasuryTransfer',
        v_ref,
        coalesce(p_description,'تحويل بين الخزائن'),
        p_created_by,
        v_journal,
        null,
        now(),
        null
    );

    update treasury set current_balance=current_balance-p_amount, updated_at=now() where id=p_source_treasury_id;
    update treasury set current_balance=current_balance+p_amount, updated_at=now() where id=p_target_treasury_id;

    update erp_operation_registry
    set status='completed', response_payload=jsonb_build_object('success',true,'duplicate',false,'reference',v_ref,'source_treasury_id',p_source_treasury_id,'target_treasury_id',p_target_treasury_id,'amount',p_amount), completed_at=now()
    where company_id=p_company_id and operation_type='post_treasury_transfer' and operation_key=p_operation_id::text;

    insert into audit_log(id,user_email,action,table_name,record_id,new_data,created_at)
    values(gen_random_uuid(),p_created_by,'create','treasury_transfer',v_ref,jsonb_build_object('company_id',p_company_id,'operation_id',p_operation_id,'source_treasury_id',p_source_treasury_id,'target_treasury_id',p_target_treasury_id,'amount',p_amount),now());

    return (select response_payload from erp_operation_registry where company_id=p_company_id and operation_type='post_treasury_transfer' and operation_key=p_operation_id::text);
end;
$$;

revoke all on function public.post_treasury_transfer_atomic(uuid,uuid,uuid,uuid,uuid,uuid,numeric,date,text,text,text,text) from public, anon, authenticated;
grant execute on function public.post_treasury_transfer_atomic(uuid,uuid,uuid,uuid,uuid,uuid,numeric,date,text,text,text,text) to service_role;
