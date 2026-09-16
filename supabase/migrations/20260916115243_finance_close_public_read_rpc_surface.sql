BEGIN;
REVOKE ALL ON FUNCTION public.finance_list_cheques(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.finance_list_cheques(uuid,text) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.finance_list_expenses(uuid,date,date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.finance_list_expenses(uuid,date,date) TO authenticated, service_role;
COMMIT;
