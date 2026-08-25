BEGIN;

DO $$
DECLARE v_company uuid := '00000000-0000-0000-0000-000000000001'::uuid;
BEGIN
  IF (SELECT count(*) FROM public.chart_of_accounts WHERE company_id=v_company) <> 16 THEN
    RAISE EXCEPTION 'NEW_COA_PARENT_FIX_EXPECTED_16_ROWS';
  END IF;

  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='11' AND p.account_code='1';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='12' AND p.account_code='1';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='21' AND p.account_code='2';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='31' AND p.account_code='3';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='41' AND p.account_code='4';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='51' AND p.account_code='5';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code IN ('121','123','124') AND p.account_code='12';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='211' AND p.account_code='21';
  UPDATE public.chart_of_accounts c SET parent_account_id=p.id, updated_at=now()
  FROM public.chart_of_accounts p
  WHERE c.company_id=v_company AND p.company_id=v_company AND c.account_code='216' AND p.account_code='21';

  IF EXISTS (
    SELECT 1 FROM public.chart_of_accounts c
    WHERE c.company_id=v_company AND c.account_code IN ('11','12','21','31','41','51','121','123','124','211','216') AND c.parent_account_id IS NULL
  ) THEN
    RAISE EXCEPTION 'NEW_COA_PARENT_FIX_FAILED';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.chart_of_accounts c
    WHERE c.company_id=v_company AND c.parent_account_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.chart_of_accounts p WHERE p.id=c.parent_account_id AND p.company_id=v_company)
  ) THEN
    RAISE EXCEPTION 'NEW_COA_ORPHAN_PARENT_DETECTED_AFTER_FIX';
  END IF;
END $$;

COMMIT;
