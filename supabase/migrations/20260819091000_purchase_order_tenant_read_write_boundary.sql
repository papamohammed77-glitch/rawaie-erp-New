BEGIN;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.purchase_orders, public.purchase_order_details
  FROM anon, authenticated;

DROP POLICY IF EXISTS "Allow all for all" ON public.purchase_orders;
DROP POLICY IF EXISTS "Allow all for all" ON public.purchase_order_details;

CREATE POLICY purchase_orders_select_company
  ON public.purchase_orders
  FOR SELECT TO authenticated
  USING (company_id = app_private.current_user_company_id());

CREATE POLICY purchase_order_details_select_company
  ON public.purchase_order_details
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.purchase_orders po
      WHERE po.id = purchase_order_details.po_id
        AND po.company_id = app_private.current_user_company_id()
    )
  );

COMMIT;
