-- Surgical repair: validate the submitted cart before pricing, and scope item lookup to the selected company.
-- Fail closed if the exact production function text has drifted.
begin;
do $migration$
declare
  v_def text;
  v_old text := 'for v_item in select * from jsonb_to_recordset(v_effective_items) as x(code text,name text,qty numeric,price numeric,unit text) loop';
  v_new text := 'for v_item in select * from jsonb_to_recordset(p_cart_items) as x(code text,name text,qty numeric,price numeric,unit text) loop';
  v_old_lookup text := 'select * into v_master from public.items where item_code=btrim(v_item.code) and coalesce(is_active,true) and coalesce(show_in_store,true);';
  v_new_lookup text := 'select * into v_master from public.items where company_id=p_company_id and item_code=btrim(v_item.code) and coalesce(is_active,true) and coalesce(show_in_store,true);';
  v_pos integer;
begin
  v_def := pg_get_functiondef('public.submit_online_order_atomic(uuid,text,text,text,text,text,jsonb,uuid)'::regprocedure);
  v_pos := strpos(v_def, v_old);
  if v_pos = 0 then
    raise exception 'Expected pre-pricing cart validation loop not found; refusing to mutate drifted function';
  end if;
  v_def := overlay(v_def placing v_new from v_pos for length(v_old));

  v_pos := strpos(v_def, v_old_lookup);
  if v_pos = 0 then
    raise exception 'Expected item lookup not found; refusing to mutate drifted function';
  end if;
  v_def := overlay(v_def placing v_new_lookup from v_pos for length(v_old_lookup));

  execute v_def;
end;
$migration$;
commit;
