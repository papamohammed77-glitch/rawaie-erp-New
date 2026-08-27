BEGIN;

CREATE OR REPLACE FUNCTION public.accountant_reconciliation_summary(p_as_of_date date)
RETURNS TABLE(check_code text,status text,difference numeric,detail text)
LANGUAGE plpgsql
STABLE
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  c uuid:=app_private.current_user_company_id();
  book_cash numeric:=0;
  cash_opening numeric:=0;
  gl_cash_movement numeric:=0;
  ar_sub numeric:=0;
  ar_gl numeric:=0;
  ap_sub numeric:=0;
  ap_gl numeric:=0;
  jdr numeric:=0;
  jcr numeric:=0;
  bad_posted integer:=0;
BEGIN
  IF c IS NULL THEN RAISE EXCEPTION 'ACCOUNTANT_COMPANY_CONTEXT_REQUIRED'; END IF;

  SELECT COALESCE(SUM(current_balance),0),COALESCE(SUM(opening_balance),0)
  INTO book_cash,cash_opening
  FROM public.treasury
  WHERE company_id=c AND is_active=true;

  SELECT COALESCE(SUM(jl.debit)-SUM(jl.credit),0)
  INTO gl_cash_movement
  FROM public.journal_lines jl
  JOIN public.journal_entries je ON je.id=jl.entry_id
  JOIN public.chart_of_accounts coa ON coa.id=jl.account_id
  WHERE coa.company_id=c AND coa.account_code='121' AND coa.is_active=true
    AND je.company_id=c AND je.status='Posted' AND je.entry_date<=p_as_of_date;

  SELECT COALESCE(SUM(x.balance),0) INTO ar_sub
  FROM (SELECT DISTINCT ON (cl.customer_id) cl.balance
        FROM public.customer_ledger cl
        JOIN public.customers cu ON cu.id=cl.customer_id
        WHERE cu.company_id=c
        ORDER BY cl.customer_id,cl.created_at DESC,cl.id DESC) x;

  SELECT COALESCE(SUM(jl.debit)-SUM(jl.credit),0) INTO ar_gl
  FROM public.journal_lines jl
  JOIN public.journal_entries je ON je.id=jl.entry_id
  JOIN public.chart_of_accounts coa ON coa.id=jl.account_id
  WHERE coa.company_id=c AND coa.account_code='123'
    AND je.company_id=c AND je.status='Posted' AND je.entry_date<=p_as_of_date;

  SELECT COALESCE(SUM(x.balance),0) INTO ap_sub
  FROM (SELECT DISTINCT ON (sl.supplier_id) sl.balance
        FROM public.supplier_ledger sl
        JOIN public.suppliers su ON su.id=sl.supplier_id
        WHERE su.company_id=c
        ORDER BY sl.supplier_id,sl.created_at DESC,sl.id DESC) x;

  SELECT COALESCE(SUM(jl.credit)-SUM(jl.debit),0) INTO ap_gl
  FROM public.journal_lines jl
  JOIN public.journal_entries je ON je.id=jl.entry_id
  JOIN public.chart_of_accounts coa ON coa.id=jl.account_id
  WHERE coa.company_id=c AND coa.account_code='211'
    AND je.company_id=c AND je.status='Posted' AND je.entry_date<=p_as_of_date;

  SELECT COALESCE(SUM(jl.debit),0),COALESCE(SUM(jl.credit),0)
  INTO jdr,jcr
  FROM public.journal_lines jl JOIN public.journal_entries je ON je.id=jl.entry_id
  WHERE je.company_id=c AND je.status='Posted' AND je.entry_date<=p_as_of_date;

  SELECT COUNT(*) INTO bad_posted
  FROM public.journal_entries je
  WHERE je.company_id=c AND je.status='Posted' AND je.entry_date<=p_as_of_date
    AND NOT EXISTS (SELECT 1 FROM public.journal_lines jl WHERE jl.entry_id=je.id);

  RETURN QUERY SELECT 'CASH_VS_GL',CASE WHEN abs((book_cash-cash_opening)-gl_cash_movement)<0.005 THEN 'OK' ELSE 'EXCEPTION' END,
    (book_cash-cash_opening)-gl_cash_movement,
    'Treasury movement (current minus opening) versus posted GL movement on account 121';
  RETURN QUERY SELECT 'AR_VS_GL',CASE WHEN abs(ar_sub-ar_gl)<0.005 THEN 'OK' ELSE 'EXCEPTION' END,
    ar_sub-ar_gl,'Customer subledger versus GL 123';
  RETURN QUERY SELECT 'AP_VS_GL',CASE WHEN abs(ap_sub-ap_gl)<0.005 THEN 'OK' ELSE 'EXCEPTION' END,
    ap_sub-ap_gl,'Supplier subledger versus GL 211';
  RETURN QUERY SELECT 'JOURNAL_BALANCE',CASE WHEN bad_posted=0 AND abs(jdr-jcr)<0.005 THEN 'OK' ELSE 'EXCEPTION' END,
    jdr-jcr,CASE WHEN bad_posted>0 THEN 'Posted journals without lines detected' ELSE 'Posted journal debit versus credit' END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.accountant_gl_account_activity(p_account_id uuid,p_from_date date,p_to_date date)
RETURNS TABLE(entry_id uuid,entry_code character varying,entry_date date,reference character varying,description text,entry_type character varying,account_id uuid,account_name character varying,debit numeric,credit numeric,running_balance numeric)
LANGUAGE sql STABLE SET search_path TO 'public','pg_temp'
AS $function$
WITH ctx AS (SELECT app_private.current_user_company_id() company_id),
account_guard AS (
  SELECT c.id FROM public.chart_of_accounts c CROSS JOIN ctx
  WHERE c.id=p_account_id AND c.company_id=ctx.company_id AND c.is_active=true
),
opening AS (
  SELECT COALESCE(SUM(jl.debit)-SUM(jl.credit),0) balance
  FROM public.journal_lines jl JOIN public.journal_entries je ON je.id=jl.entry_id
  JOIN account_guard ag ON ag.id=jl.account_id CROSS JOIN ctx
  WHERE je.company_id=ctx.company_id AND je.status='Posted' AND je.entry_date<p_from_date
),
rows AS (
  SELECT je.id entry_id,je.entry_code,je.entry_date,je.reference,je.description,je.entry_type,jl.account_id,jl.account_name,
         COALESCE(jl.debit,0) debit,COALESCE(jl.credit,0) credit,
         ROW_NUMBER() OVER(ORDER BY je.entry_date,je.created_at,je.id,jl.id) rn
  FROM public.journal_entries je
  JOIN public.journal_lines jl ON jl.entry_id=je.id AND jl.account_id=p_account_id
  JOIN account_guard ag ON ag.id=p_account_id CROSS JOIN ctx
  WHERE je.company_id=ctx.company_id AND je.status='Posted' AND je.entry_date BETWEEN p_from_date AND p_to_date
)
SELECT r.entry_id,r.entry_code,r.entry_date,r.reference,r.description,r.entry_type,r.account_id,r.account_name,r.debit,r.credit,
       o.balance+SUM(r.debit-r.credit) OVER(ORDER BY r.rn ROWS UNBOUNDED PRECEDING)
FROM rows r CROSS JOIN opening o ORDER BY r.rn;
$function$;

COMMIT;
