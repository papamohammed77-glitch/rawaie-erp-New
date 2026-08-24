BEGIN;

-- Canonical financial writer cores reconciled from SMART ERP Production on 2026-08-24.
-- Production company: 00000000-0000-0000-0000-000000000001.
-- This migration contains the verified deployed definitions and execution boundary.

CREATE OR REPLACE FUNCTION public.post_customer_ledger_entry(p_company_id uuid, p_operation_id uuid, p_customer_id uuid, p_entry_date date, p_reference text, p_description text, p_debit numeric, p_credit numeric, p_due_date date, p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_existing public.erp_operation_registry%rowtype;
    v_customer public.customers%rowtype;
    v_balance numeric := 0;
    v_result jsonb;
BEGIN
    IF p_company_id IS NULL THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_COMPANY_REQUIRED'; END IF;
    IF p_operation_id IS NULL THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_OPERATION_ID_REQUIRED'; END IF;
    IF p_customer_id IS NULL THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_CUSTOMER_REQUIRED'; END IF;
    IF p_entry_date IS NULL THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_DATE_REQUIRED'; END IF;
    IF coalesce(p_debit,0) < 0 OR coalesce(p_credit,0) < 0 THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_NEGATIVE_AMOUNT_NOT_ALLOWED'; END IF;
    IF coalesce(p_debit,0) > 0 AND coalesce(p_credit,0) > 0 THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_LINE_CANNOT_HAVE_BOTH_DEBIT_AND_CREDIT'; END IF;
    IF coalesce(p_debit,0) = 0 AND coalesce(p_credit,0) = 0 THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_ZERO_ENTRY_NOT_ALLOWED'; END IF;
    IF nullif(btrim(coalesce(p_user_email,'')),'') IS NULL THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_CREATED_BY_REQUIRED'; END IF;

    INSERT INTO public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status)
    VALUES(p_company_id,'post_customer_ledger_entry',p_operation_id::text,jsonb_build_object('customer_id',p_customer_id,'debit',coalesce(p_debit,0),'credit',coalesce(p_credit,0),'reference',p_reference),'processing')
    ON CONFLICT(company_id,operation_type,operation_key) DO NOTHING;

    SELECT * INTO v_existing FROM public.erp_operation_registry WHERE company_id=p_company_id AND operation_type='post_customer_ledger_entry' AND operation_key=p_operation_id::text FOR UPDATE;
    IF v_existing.status='completed' AND v_existing.response_payload IS NOT NULL THEN
        RETURN v_existing.response_payload || jsonb_build_object('duplicate',true);
    END IF;

    SELECT * INTO v_customer FROM public.customers WHERE id=p_customer_id AND company_id=p_company_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'CUSTOMER_LEDGER_CUSTOMER_NOT_FOUND_OR_WRONG_COMPANY'; END IF;

    SELECT coalesce(cl.balance,0) INTO v_balance FROM public.customer_ledger cl WHERE cl.customer_id=p_customer_id ORDER BY cl.created_at DESC, cl.id DESC LIMIT 1;
    v_balance := coalesce(v_balance,0) + coalesce(p_debit,0) - coalesce(p_credit,0);

    INSERT INTO public.customer_ledger(id,customer_id,entry_date,reference,description,debit,credit,balance,due_date,user_email)
    VALUES(gen_random_uuid(),p_customer_id,p_entry_date,p_reference,p_description,coalesce(p_debit,0),coalesce(p_credit,0),v_balance,p_due_date,p_user_email);

    v_result:=jsonb_build_object('success',true,'duplicate',false,'operation_id',p_operation_id,'company_id',p_company_id,'customer_id',p_customer_id,'debit',coalesce(p_debit,0),'credit',coalesce(p_credit,0),'balance',v_balance);

    UPDATE public.erp_operation_registry SET status='completed',response_payload=v_result,completed_at=now() WHERE company_id=p_company_id AND operation_type='post_customer_ledger_entry' AND operation_key=p_operation_id::text;
    INSERT INTO public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at) VALUES(gen_random_uuid(),p_user_email,'create','customer_ledger',p_customer_id::text,v_result,now());
    RETURN v_result;
EXCEPTION WHEN others THEN
    UPDATE public.erp_operation_registry SET status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() WHERE company_id=p_company_id AND operation_type='post_customer_ledger_entry' AND operation_key=p_operation_id::text AND status<>'completed';
    RAISE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.post_driver_ledger_entry(p_company_id uuid, p_operation_id uuid, p_driver_email text, p_entry_date date, p_reference text, p_description text, p_debit numeric, p_credit numeric)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_existing public.erp_operation_registry%rowtype; v_driver public.users%rowtype; v_balance numeric:=0; v_result jsonb;
begin
 if p_company_id is null or p_operation_id is null or nullif(btrim(coalesce(p_driver_email,'')),'') is null or p_entry_date is null then raise exception 'DRIVER_LEDGER_REQUIRED_CONTEXT'; end if;
 if coalesce(p_debit,0)<0 or coalesce(p_credit,0)<0 then raise exception 'DRIVER_LEDGER_NEGATIVE_AMOUNT_NOT_ALLOWED'; end if;
 if coalesce(p_debit,0)>0 and coalesce(p_credit,0)>0 then raise exception 'DRIVER_LEDGER_BOTH_SIDES_NOT_ALLOWED'; end if;
 if coalesce(p_debit,0)=0 and coalesce(p_credit,0)=0 then raise exception 'DRIVER_LEDGER_ZERO_ENTRY_NOT_ALLOWED'; end if;
 insert into public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) values(p_company_id,'post_driver_ledger_entry',p_operation_id::text,jsonb_build_object('driver_email',p_driver_email,'debit',coalesce(p_debit,0),'credit',coalesce(p_credit,0),'reference',p_reference),'processing') on conflict(company_id,operation_type,operation_key) do nothing;
 select * into v_existing from public.erp_operation_registry where company_id=p_company_id and operation_type='post_driver_ledger_entry' and operation_key=p_operation_id::text for update;
 if v_existing.status='completed' and v_existing.response_payload is not null then return v_existing.response_payload||jsonb_build_object('duplicate',true); end if;
 select * into v_driver from public.users where lower(email)=lower(p_driver_email) and company_id=p_company_id and coalesce(status,'Active')='Active' and role in ('مندوب توصيل','سائق','سائق توصيل','Driver','Delivery Driver') for update;
 if not found then raise exception 'DRIVER_LEDGER_DRIVER_NOT_FOUND_OR_WRONG_COMPANY'; end if;
 select coalesce(balance,0) into v_balance from public.driver_ledger where lower(driver_email)=lower(p_driver_email) order by created_at desc,id desc limit 1;
 v_balance:=coalesce(v_balance,0)+coalesce(p_debit,0)-coalesce(p_credit,0);
 insert into public.driver_ledger(id,driver_email,entry_date,description,debit,credit,balance,reference,created_at) values(gen_random_uuid(),p_driver_email,p_entry_date,p_description,coalesce(p_debit,0),coalesce(p_credit,0),v_balance,p_reference,now());
 v_result:=jsonb_build_object('success',true,'duplicate',false,'operation_id',p_operation_id,'company_id',p_company_id,'driver_email',p_driver_email,'debit',coalesce(p_debit,0),'credit',coalesce(p_credit,0),'balance',v_balance);
 update public.erp_operation_registry set status='completed',response_payload=v_result,completed_at=now() where company_id=p_company_id and operation_type='post_driver_ledger_entry' and operation_key=p_operation_id::text;
 insert into public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at) values(gen_random_uuid(),p_driver_email,'create','driver_ledger',p_driver_email,v_result,now());
 return v_result;
 exception when others then update public.erp_operation_registry set status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() where company_id=p_company_id and operation_type='post_driver_ledger_entry' and operation_key=p_operation_id::text and status<>'completed'; raise;
end $function$;

CREATE OR REPLACE FUNCTION public.post_journal_entry(p_company_id uuid, p_operation_id uuid, p_entry_date date, p_entry_type text, p_reference text, p_description text, p_created_by text, p_lines jsonb, p_entry_code text DEFAULT NULL::text, p_posting_date timestamp with time zone DEFAULT now(), p_movement_id uuid DEFAULT NULL::uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_existing public.erp_operation_registry%rowtype; v_entry_id uuid; v_entry_code text; v_line jsonb; v_account_id uuid; v_account_name text; v_debit numeric; v_credit numeric; v_total_debit numeric:=0; v_total_credit numeric:=0; v_line_count integer:=0; v_result jsonb;
begin
if p_company_id is null then raise exception 'ACCOUNTING_COMPANY_REQUIRED'; end if; if p_operation_id is null then raise exception 'ACCOUNTING_OPERATION_ID_REQUIRED'; end if; if p_entry_date is null then raise exception 'ACCOUNTING_ENTRY_DATE_REQUIRED'; end if; if nullif(btrim(coalesce(p_entry_type,'')),'') is null then raise exception 'ACCOUNTING_ENTRY_TYPE_REQUIRED'; end if; if nullif(btrim(coalesce(p_created_by,'')),'') is null then raise exception 'ACCOUNTING_CREATED_BY_REQUIRED'; end if; if p_lines is null or jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)<2 then raise exception 'ACCOUNTING_MINIMUM_TWO_LINES_REQUIRED'; end if; if not exists(select 1 from public.companies c where c.id=p_company_id) then raise exception 'ACCOUNTING_COMPANY_NOT_FOUND'; end if;
insert into public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) values(p_company_id,'post_journal_entry',p_operation_id::text,coalesce(p_lines,'[]'::jsonb),'processing') on conflict(company_id,operation_type,operation_key) do nothing;
select * into v_existing from public.erp_operation_registry where company_id=p_company_id and operation_type='post_journal_entry' and operation_key=p_operation_id::text for update; if v_existing.status='completed' and v_existing.response_payload is not null then return v_existing.response_payload||jsonb_build_object('duplicate',true); end if;
for v_line in select value from jsonb_array_elements(p_lines) loop v_line_count:=v_line_count+1; begin v_account_id:=nullif(v_line->>'account_id','')::uuid; exception when invalid_text_representation then raise exception 'ACCOUNTING_INVALID_ACCOUNT_ID at line %',v_line_count; end; v_debit:=coalesce((v_line->>'debit')::numeric,0); v_credit:=coalesce((v_line->>'credit')::numeric,0); if v_account_id is null then raise exception 'ACCOUNTING_ACCOUNT_REQUIRED at line %',v_line_count; end if; if v_debit<0 or v_credit<0 then raise exception 'ACCOUNTING_NEGATIVE_AMOUNT_NOT_ALLOWED at line %',v_line_count; end if; if v_debit>0 and v_credit>0 then raise exception 'ACCOUNTING_LINE_CANNOT_HAVE_BOTH_DEBIT_AND_CREDIT at line %',v_line_count; end if; if v_debit=0 and v_credit=0 then raise exception 'ACCOUNTING_ZERO_LINE_NOT_ALLOWED at line %',v_line_count; end if; select coa.account_name into v_account_name from public.chart_of_accounts coa where coa.id=v_account_id and coa.company_id=p_company_id and coalesce(coa.is_active,true)=true for update; if not found then raise exception 'ACCOUNTING_ACCOUNT_NOT_FOUND_OR_WRONG_COMPANY at line %',v_line_count; end if; v_total_debit:=v_total_debit+v_debit; v_total_credit:=v_total_credit+v_credit; end loop;
if v_total_debit<=0 or v_total_credit<=0 then raise exception 'ACCOUNTING_ENTRY_MUST_HAVE_NONZERO_DEBIT_AND_CREDIT'; end if; if v_total_debit<>v_total_credit then raise exception 'ACCOUNTING_UNBALANCED_ENTRY debit=% credit=%',v_total_debit,v_total_credit; end if;
v_entry_code:=nullif(btrim(p_entry_code),''); if v_entry_code is null then v_entry_code:='JE-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,20)); end if;
insert into public.journal_entries(id,company_id,entry_code,entry_date,reference,description,entry_type,status,created_by,posting_date) values(gen_random_uuid(),p_company_id,v_entry_code,p_entry_date,p_reference,p_description,p_entry_type,'Posted',p_created_by,coalesce(p_posting_date,now())) returning id into v_entry_id;
for v_line in select value from jsonb_array_elements(p_lines) loop v_account_id:=(v_line->>'account_id')::uuid; select coa.account_name into v_account_name from public.chart_of_accounts coa where coa.id=v_account_id and coa.company_id=p_company_id; insert into public.journal_lines(id,entry_id,account_id,account_name,debit,credit,notes,cost_center_id) values(gen_random_uuid(),v_entry_id,v_account_id,coalesce(v_line->>'account_name',v_account_name),coalesce((v_line->>'debit')::numeric,0),coalesce((v_line->>'credit')::numeric,0),nullif(v_line->>'notes',''),case when nullif(v_line->>'cost_center_id','') is null then null else (v_line->>'cost_center_id')::uuid end); end loop;
v_result:=jsonb_build_object('success',true,'duplicate',false,'entry_id',v_entry_id,'entry_code',v_entry_code,'company_id',p_company_id,'operation_id',p_operation_id,'total_debit',v_total_debit,'total_credit',v_total_credit,'line_count',v_line_count,'status','Posted'); update public.erp_operation_registry set status='completed',response_payload=v_result,completed_at=now() where company_id=p_company_id and operation_type='post_journal_entry' and operation_key=p_operation_id::text; insert into public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at) values(gen_random_uuid(),p_created_by,'create','journal_entries',v_entry_id::text,v_result,now()); return v_result; end;
$function$;

CREATE OR REPLACE FUNCTION public.post_supplier_ledger_entry(p_company_id uuid, p_operation_id uuid, p_supplier_id uuid, p_entry_date date, p_reference text, p_description text, p_debit numeric, p_credit numeric, p_due_date date, p_user_email text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_existing public.erp_operation_registry%rowtype; v_supplier public.suppliers%rowtype; v_balance numeric:=0; v_result jsonb;
begin if p_company_id is null or p_operation_id is null or p_supplier_id is null or p_entry_date is null then raise exception 'SUPPLIER_LEDGER_REQUIRED_CONTEXT'; end if; if coalesce(p_debit,0)<0 or coalesce(p_credit,0)<0 then raise exception 'SUPPLIER_LEDGER_NEGATIVE_AMOUNT_NOT_ALLOWED'; end if; if coalesce(p_debit,0)>0 and coalesce(p_credit,0)>0 then raise exception 'SUPPLIER_LEDGER_BOTH_SIDES_NOT_ALLOWED'; end if; if coalesce(p_debit,0)=0 and coalesce(p_credit,0)=0 then raise exception 'SUPPLIER_LEDGER_ZERO_ENTRY_NOT_ALLOWED'; end if; insert into public.erp_operation_registry(company_id,operation_type,operation_key,request_payload,status) values(p_company_id,'post_supplier_ledger_entry',p_operation_id::text,jsonb_build_object('supplier_id',p_supplier_id,'debit',coalesce(p_debit,0),'credit',coalesce(p_credit,0),'reference',p_reference),'processing') on conflict(company_id,operation_type,operation_key) do nothing; select * into v_existing from public.erp_operation_registry where company_id=p_company_id and operation_type='post_supplier_ledger_entry' and operation_key=p_operation_id::text for update; if v_existing.status='completed' and v_existing.response_payload is not null then return v_existing.response_payload||jsonb_build_object('duplicate',true); end if; select * into v_supplier from public.suppliers where id=p_supplier_id and company_id=p_company_id for update; if not found then raise exception 'SUPPLIER_LEDGER_SUPPLIER_NOT_FOUND_OR_WRONG_COMPANY'; end if; select coalesce(balance,0) into v_balance from public.supplier_ledger where supplier_id=p_supplier_id order by created_at desc,id desc limit 1; v_balance:=coalesce(v_balance,0)+coalesce(p_credit,0)-coalesce(p_debit,0); insert into public.supplier_ledger(id,supplier_id,entry_date,reference,description,debit,credit,balance,due_date,user_email,created_at) values(gen_random_uuid(),p_supplier_id,p_entry_date,p_reference,p_description,coalesce(p_debit,0),coalesce(p_credit,0),v_balance,p_due_date,p_user_email,now()); v_result:=jsonb_build_object('success',true,'duplicate',false,'operation_id',p_operation_id,'company_id',p_company_id,'supplier_id',p_supplier_id,'debit',coalesce(p_debit,0),'credit',coalesce(p_credit,0),'balance',v_balance); update public.erp_operation_registry set status='completed',response_payload=v_result,completed_at=now() where company_id=p_company_id and operation_type='post_supplier_ledger_entry' and operation_key=p_operation_id::text; insert into public.audit_log(id,user_email,action,table_name,record_id,new_data,created_at) values(gen_random_uuid(),p_user_email,'create','supplier_ledger',p_supplier_id::text,v_result,now()); return v_result; exception when others then update public.erp_operation_registry set status='failed',response_payload=jsonb_build_object('success',false,'error',sqlerrm),completed_at=now() where company_id=p_company_id and operation_type='post_supplier_ledger_entry' and operation_key=p_operation_id::text and status<>'completed'; raise; end $function$;

REVOKE ALL ON FUNCTION public.post_journal_entry(uuid,uuid,date,text,text,text,text,jsonb,text,timestamp with time zone,uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_journal_entry(uuid,uuid,date,text,text,text,text,jsonb,text,timestamp with time zone,uuid) TO service_role;
REVOKE ALL ON FUNCTION public.post_customer_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_customer_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) TO service_role;
REVOKE ALL ON FUNCTION public.post_supplier_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_supplier_ledger_entry(uuid,uuid,uuid,date,text,text,numeric,numeric,date,text) TO service_role;
REVOKE ALL ON FUNCTION public.post_driver_ledger_entry(uuid,uuid,text,date,text,text,numeric,numeric) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.post_driver_ledger_entry(uuid,uuid,text,date,text,text,numeric,numeric) TO service_role;

COMMIT;
