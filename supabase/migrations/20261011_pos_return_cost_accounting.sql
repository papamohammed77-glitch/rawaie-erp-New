-- POS return inventory/COGS journal must use item cost, not selling price.
-- Preserve the historical non-POS runsheet return contract in this surgical patch.
DO $patch$
DECLARE
  v_def text;
  v_old_decl text := 'v_item_returned_total numeric:=0;';
  v_new_decl text := 'v_item_returned_total numeric:=0; v_item_cost numeric:=0; v_total_cost numeric:=0; v_inventory_return_value numeric:=0;';
  v_old_lookup text := 'select i.id,i.name into v_item_id,v_item_name from public.items i where i.item_code=v_item_code;';
  v_new_lookup text := 'select i.id,i.name,coalesce(i.cost_price,0) into v_item_id,v_item_name,v_item_cost from public.items i where i.company_id=p_company_id and i.item_code=v_item_code and coalesce(i.is_active,true)=true limit 1;';
  v_old_journal text := $old$
 if v_total_value>0 then
   select coa.id,coa.account_name into v_inventory_account,v_inventory_name from public.chart_of_accounts coa where coa.company_id=p_company_id and coa.account_code='124' and coa.is_active=true limit 1;
   select coa.id,coa.account_name into v_cogs_account,v_cogs_name from public.chart_of_accounts coa where coa.company_id=p_company_id and coa.account_code='51' and coa.is_active=true limit 1;
   if v_inventory_account is null or v_cogs_account is null then raise exception 'RETURN_FINANCIAL_ACCOUNTS_NOT_CONFIGURED'; end if;
   v_fin_operation_id:=gen_random_uuid();
   select (public.post_journal_entry(p_company_id,v_fin_operation_id,current_date,'SalesReturn',coalesce(p_runsheet_code,p_order_code),'مرتجعات – '||coalesce(p_runsheet_code,p_order_code),p_user_email,jsonb_build_array(jsonb_build_object('account_id',v_inventory_account,'account_name',v_inventory_name,'debit',v_total_value,'credit',0),jsonb_build_object('account_id',v_cogs_account,'account_name',v_cogs_name,'debit',0,'credit',v_total_value)),NULL,now(),NULL)->>'entry_id')::uuid into v_entry_id;
 end if;
$old$;
  v_new_journal text := $new$
 v_inventory_return_value := CASE WHEN p_is_pos_return THEN v_total_cost ELSE v_total_value END;
 if v_inventory_return_value>0 then
   select coa.id,coa.account_name into v_inventory_account,v_inventory_name from public.chart_of_accounts coa where coa.company_id=p_company_id and coa.account_code='124' and coa.is_active=true limit 1;
   select coa.id,coa.account_name into v_cogs_account,v_cogs_name from public.chart_of_accounts coa where coa.company_id=p_company_id and coa.account_code='51' and coa.is_active=true limit 1;
   if v_inventory_account is null or v_cogs_account is null then raise exception 'RETURN_FINANCIAL_ACCOUNTS_NOT_CONFIGURED'; end if;
   v_fin_operation_id:=gen_random_uuid();
   select (public.post_journal_entry(p_company_id,v_fin_operation_id,current_date,'SalesReturn',coalesce(p_runsheet_code,p_order_code),'مرتجعات – '||coalesce(p_runsheet_code,p_order_code),p_user_email,jsonb_build_array(jsonb_build_object('account_id',v_inventory_account,'account_name',v_inventory_name,'debit',v_inventory_return_value,'credit',0),jsonb_build_object('account_id',v_cogs_account,'account_name',v_cogs_name,'debit',0,'credit',v_inventory_return_value)),NULL,now(),NULL)->>'entry_id')::uuid into v_entry_id;
 end if;
$new$;
BEGIN
  SELECT pg_get_functiondef('public.complete_return_atomic(uuid,text,text,boolean,text,jsonb)'::regprocedure) INTO v_def;
  IF position(v_old_decl in v_def)=0 THEN RAISE EXCEPTION 'POS_RETURN_COST_PATCH_ABORTED: declaration anchor mismatch'; END IF;
  IF position(v_old_lookup in v_def)=0 THEN RAISE EXCEPTION 'POS_RETURN_COST_PATCH_ABORTED: item lookup anchor mismatch'; END IF;
  IF position(v_old_journal in v_def)=0 THEN RAISE EXCEPTION 'POS_RETURN_COST_PATCH_ABORTED: journal anchor mismatch'; END IF;

  v_def := replace(v_def,v_old_decl,v_new_decl);
  v_def := replace(v_def,v_old_lookup,v_new_lookup);
  v_def := replace(v_def,'v_total_value:=v_total_value+v_alloc*coalesce(v_detail.unit_price,0);','v_total_value:=v_total_value+v_alloc*coalesce(v_detail.unit_price,0); IF p_is_pos_return AND v_return_condition=''good'' THEN v_total_cost:=v_total_cost+v_alloc*v_item_cost; END IF;');
  v_def := replace(v_def,'v_total_value:=v_total_value+v_returned*coalesce(v_detail.unit_price,0);','v_total_value:=v_total_value+v_returned*coalesce(v_detail.unit_price,0); IF p_is_pos_return AND v_return_condition=''good'' THEN v_total_cost:=v_total_cost+v_returned*v_item_cost; END IF;');
  v_def := replace(v_def,v_old_journal,v_new_journal);

  IF position('v_inventory_return_value := CASE WHEN p_is_pos_return THEN v_total_cost ELSE v_total_value END;' in v_def)=0
     OR position('v_total_cost:=v_total_cost+v_returned*v_item_cost' in v_def)=0 THEN
    RAISE EXCEPTION 'POS_RETURN_COST_PATCH_ABORTED: replacement validation failed';
  END IF;
  EXECUTE v_def;
END
$patch$;

REVOKE ALL ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_return_atomic(uuid,text,text,boolean,text,jsonb) TO service_role;
