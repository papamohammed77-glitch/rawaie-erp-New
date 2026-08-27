BEGIN;

DROP POLICY IF EXISTS "Allow all for all" ON public.cash_box;
DROP POLICY IF EXISTS "Allow all for all" ON public.treasury;
DROP POLICY IF EXISTS "Allow all for all" ON public.journal_entries;
DROP POLICY IF EXISTS "Allow all for all" ON public.journal_lines;
DROP POLICY IF EXISTS "erp_operation_registry_select_company" ON public.erp_operation_registry;

ALTER TABLE public.cash_box ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treasury ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.erp_operation_registry ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cash_box_select_company" ON public.cash_box
FOR SELECT TO authenticated
USING (company_id = app_private.current_user_company_id());

CREATE POLICY "treasury_select_company" ON public.treasury
FOR SELECT TO authenticated
USING (company_id = app_private.current_user_company_id());

CREATE POLICY "journal_entries_select_company" ON public.journal_entries
FOR SELECT TO authenticated
USING (company_id = app_private.current_user_company_id());

CREATE POLICY "journal_lines_select_company" ON public.journal_lines
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.journal_entries je
    WHERE je.id = journal_lines.entry_id
      AND je.company_id = app_private.current_user_company_id()
  )
);

CREATE POLICY "erp_operation_registry_select_company" ON public.erp_operation_registry
FOR SELECT TO authenticated
USING (company_id = app_private.current_user_company_id());

COMMIT;