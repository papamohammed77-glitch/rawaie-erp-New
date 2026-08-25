BEGIN;

DO $$
DECLARE
  v_company uuid := '00000000-0000-0000-0000-000000000001'::uuid;
BEGIN
  IF (SELECT count(*) FROM public.companies WHERE id = v_company) <> 1 THEN
    RAISE EXCEPTION 'NEW_COA_COMPANY_CONTEXT_INVALID';
  END IF;
  IF (SELECT count(*) FROM public.chart_of_accounts) <> 0 THEN
    RAISE EXCEPTION 'NEW_COA_REQUIRES_EMPTY_CURRENT_COA';
  END IF;
  IF (SELECT count(*) FROM public.treasury WHERE company_id = v_company AND account_code = 'CASH-01' AND is_active = true) <> 1 THEN
    RAISE EXCEPTION 'NEW_COA_TREASURY_BASELINE_INVALID';
  END IF;
END $$;

INSERT INTO public.chart_of_accounts
  (company_id, account_code, account_name, account_type, parent_account_id, normal_balance, is_active, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001','1','الأصول','asset',NULL,'debit',true,'NEW MASTER DATA — top-level asset group; required by current ERP accounting model.'),
  ('00000000-0000-0000-0000-000000000001','2','الخصوم','liability',NULL,'credit',true,'NEW MASTER DATA — top-level liability group; required by current ERP accounting model.'),
  ('00000000-0000-0000-0000-000000000001','3','حقوق الملكية','equity',NULL,'credit',true,'NEW MASTER DATA — top-level equity group; required for coherent single-company financial master data.'),
  ('00000000-0000-0000-0000-000000000001','4','الإيرادات','revenue',NULL,'credit',true,'NEW MASTER DATA — top-level revenue group; current sales writers require revenue posting.'),
  ('00000000-0000-0000-0000-000000000001','5','المصروفات وتكلفة المبيعات','expense',NULL,'debit',true,'NEW MASTER DATA — top-level expense/cost group; current POS, return and purchase flows require COGS posting.'),
  ('00000000-0000-0000-0000-000000000001','11','الأصول الثابتة','asset',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='1'),'debit',true,'NEW MASTER DATA — fixed-asset subgroup; retained as standard ERP structure, not historical recovery.'),
  ('00000000-0000-0000-0000-000000000001','12','الأصول المتداولة','asset',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='1'),'debit',true,'NEW MASTER DATA — current-asset subgroup; required for cash, receivables and inventory.'),
  ('00000000-0000-0000-0000-000000000001','21','الخصوم المتداولة','liability',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='2'),'credit',true,'NEW MASTER DATA — current-liability subgroup; required for supplier obligations.'),
  ('00000000-0000-0000-0000-000000000001','31','رأس المال','equity',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='3'),'credit',true,'NEW MASTER DATA — opening/equity account required for coherent company financial master data.'),
  ('00000000-0000-0000-0000-000000000001','41','إيرادات المبيعات','revenue',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='4'),'credit',true,'NEW MASTER DATA — required explicitly by save_sales_invoice_atomic for POS/Van Sales revenue posting.'),
  ('00000000-0000-0000-0000-000000000001','51','تكلفة المبيعات','expense',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='5'),'debit',true,'NEW MASTER DATA — required explicitly by save_sales_invoice_atomic and complete_return_atomic for COGS/return accounting.'),
  ('00000000-0000-0000-0000-000000000001','121','النقدية (الخزينة الرئيسية)','asset',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='12'),'debit',true,'NEW MASTER DATA — explicit current POS/cash-core contract requires cash account code 121; this is not a database FK mapping to treasury CASH-01.'),
  ('00000000-0000-0000-0000-000000000001','123','العملاء (ذمم مدينة)','asset',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='12'),'debit',true,'NEW MASTER DATA — required explicitly by save_sales_invoice_atomic for credit sales and customer receivables.'),
  ('00000000-0000-0000-0000-000000000001','124','المخزون السلعي','asset',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='12'),'debit',true,'NEW MASTER DATA — required explicitly by save_sales_invoice_atomic, receive_purchase_atomic and complete_return_atomic.'),
  ('00000000-0000-0000-0000-000000000001','211','الموردون (ذمم دائنة)','liability',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='21'),'credit',true,'NEW MASTER DATA — required explicitly by receive_purchase_atomic for supplier payable posting.'),
  ('00000000-0000-0000-0000-000000000001','216','التزامات ضريبية','liability',(SELECT id FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001' AND account_code='21'),'credit',true,'NEW MASTER DATA — standard current-liability capacity retained for future tax-enabled flows; no current Production writer posts to it yet.');

DO $$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001';
  IF v_count <> 16 THEN RAISE EXCEPTION 'NEW_COA_INSERT_COUNT_MISMATCH: %',v_count; END IF;
  IF EXISTS (SELECT 1 FROM public.chart_of_accounts c WHERE c.company_id='00000000-0000-0000-0000-000000000001' AND c.parent_account_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.chart_of_accounts p WHERE p.id=c.parent_account_id AND p.company_id=c.company_id)) THEN RAISE EXCEPTION 'NEW_COA_ORPHAN_PARENT_DETECTED'; END IF;
  IF (SELECT count(DISTINCT account_code) FROM public.chart_of_accounts WHERE company_id='00000000-0000-0000-0000-000000000001') <> 16 THEN RAISE EXCEPTION 'NEW_COA_DUPLICATE_CODES_DETECTED'; END IF;
END $$;
COMMIT;
