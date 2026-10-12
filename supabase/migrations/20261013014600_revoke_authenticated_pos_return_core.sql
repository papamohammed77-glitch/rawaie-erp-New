-- Security hardening for the POS return core.
-- The browser must call the authenticated complete-return Edge Function.
-- That Edge Function validates the JWT and company profile, then calls this
-- SECURITY DEFINER core with service_role. Direct authenticated RPC execution
-- would let clients supply p_company_id and p_user_email outside that boundary.
REVOKE ALL ON FUNCTION public.complete_sales_return_credit_note_atomic(
  uuid, text, text, boolean, text, jsonb, text
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.complete_sales_return_credit_note_atomic(
  uuid, text, text, boolean, text, jsonb, text
) TO service_role;
