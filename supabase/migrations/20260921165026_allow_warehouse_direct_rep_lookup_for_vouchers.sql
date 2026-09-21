BEGIN;

DROP POLICY IF EXISTS users_select_direct_reps_warehouse
ON public.users;

CREATE POLICY users_select_direct_reps_warehouse
ON public.users
FOR SELECT
TO authenticated
USING (
  company_id = app_private.current_user_company_id()
  AND status = 'Active'
  AND role = 'مندوب بيع مباشر'
  AND app_private.current_user_has_permission('warehouse')
);

COMMIT;
