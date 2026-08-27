COMMENT ON FUNCTION public.accountant_reconciliation_summary(date) IS 'Forensic closure: reconcile treasury movement against opening balance plus posted GL movement; detect zero-line posted journals.';
COMMENT ON FUNCTION public.accountant_gl_account_activity(uuid,date,date) IS 'Forensic closure: account activity is company-scoped through explicit COA account ownership guard.';
