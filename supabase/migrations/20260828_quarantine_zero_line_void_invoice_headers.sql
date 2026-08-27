BEGIN;

UPDATE public.journal_entries je
SET status='Cancelled',
    updated_at=now()
WHERE je.company_id='00000000-0000-0000-0000-000000000001'::uuid
  AND je.status='Posted'
  AND je.entry_type='VoidInvoice'
  AND je.reference IN ('VOID-ORD-1015','VOID-ORD-1016')
  AND NOT EXISTS (
    SELECT 1 FROM public.journal_lines jl WHERE jl.entry_id=je.id
  );

DO $$
DECLARE v_remaining integer;
BEGIN
  SELECT count(*) INTO v_remaining
  FROM public.journal_entries je
  WHERE je.company_id='00000000-0000-0000-0000-000000000001'::uuid
    AND je.status='Posted'
    AND je.entry_type='VoidInvoice'
    AND NOT EXISTS (SELECT 1 FROM public.journal_lines jl WHERE jl.entry_id=je.id);
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION 'Zero-line Posted VoidInvoice headers remain: %',v_remaining;
  END IF;
END $$;

COMMIT;
