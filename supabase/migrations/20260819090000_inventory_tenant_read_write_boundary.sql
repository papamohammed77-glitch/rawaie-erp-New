BEGIN;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.stock_vouchers, public.stock_voucher_details
  FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.inventory_log
  FROM anon, authenticated;

DROP POLICY IF EXISTS "Allow all for all" ON public.stock_vouchers;
DROP POLICY IF EXISTS "Allow all for all" ON public.stock_voucher_details;
DROP POLICY IF EXISTS "Allow all for all" ON public.inventory_log;

CREATE POLICY stock_vouchers_select_company
  ON public.stock_vouchers
  FOR SELECT TO authenticated
  USING (company_id = app_private.current_user_company_id());

CREATE POLICY stock_voucher_details_select_company
  ON public.stock_voucher_details
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.stock_vouchers sv
      WHERE sv.id = stock_voucher_details.voucher_id
        AND sv.company_id = app_private.current_user_company_id()
    )
  );

CREATE POLICY inventory_log_select_company
  ON public.inventory_log
  FOR SELECT TO authenticated
  USING (company_id = app_private.current_user_company_id());

COMMIT;
