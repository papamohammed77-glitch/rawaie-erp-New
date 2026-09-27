-- Production hardening for standalone SupplierReturn in Warehouse Vouchers.
-- Applied in SMART ERP on 2026-09-27.
-- No new Edge Function; no inventory writer change.

ALTER POLICY suppliers_select_company
ON public.suppliers
TO authenticated
USING (
  company_id = app_private.current_user_company_id()
  AND (
    app_private.current_user_has_permission('suppliers')
    OR EXISTS (
      SELECT 1
      FROM public.users u
      WHERE u.auth_id = auth.uid()
        AND u.company_id = suppliers.company_id
        AND COALESCE(u.status,'Active') = 'Active'
        AND COALESCE(u.active_warehouse_role,'') = 'أذونات'
    )
  )
);

ALTER POLICY allow_read_return_reasons
ON public.return_reasons
TO authenticated
USING (
  auth.role() = 'authenticated'
  AND (
    company_id = app_private.current_user_company_id()
    OR company_id IS NULL
  )
);

REVOKE ALL ON FUNCTION public.assert_supplier_return_contract(uuid,uuid) FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.save_supplier_return_contract(uuid,text,jsonb,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_supplier_return_contract(uuid,text,jsonb,text) TO authenticated;

REVOKE ALL ON FUNCTION public.get_supplier_return_contract(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_supplier_return_contract(uuid,text) TO authenticated;
