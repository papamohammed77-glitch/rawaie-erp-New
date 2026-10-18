-- Harden the public catalog stock lookup against a cross-company main_branch_id.
begin;
do $migration$
declare
  v_def text;
  v_old text := 'from public.items i left join public.stock_branches sb on sb.item_id=i.id and sb.branch_id=v_settings.main_branch_id';
  v_new text := 'from public.items i left join public.branches b on b.id=v_settings.main_branch_id and b.company_id=v_settings.company_id left join public.stock_branches sb on sb.item_id=i.id and sb.branch_id=b.id';
  v_pos integer;
begin
  v_def:=pg_get_functiondef('public.get_public_store_catalog(text)'::regprocedure);
  if strpos(v_def,v_new)>0 then
    null;
  else
    v_pos:=strpos(v_def,v_old);
    if v_pos=0 then raise exception 'Expected public catalog stock join not found; refusing to mutate drifted function'; end if;
    v_def:=overlay(v_def placing v_new from v_pos for length(v_old));
    execute v_def;
  end if;
end;
$migration$;
commit;
