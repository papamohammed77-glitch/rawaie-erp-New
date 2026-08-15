-- TASK: complete-picking execution boundary hardening
-- Production-applied migration: 20260815051739
-- Purpose: preserve the Edge HTTP/Auth boundary and prevent direct public
-- execution of the SECURITY DEFINER picking core by anon/authenticated roles.

REVOKE EXECUTE ON FUNCTION public.complete_runsheet_picking(uuid,text,text,jsonb)
FROM anon, authenticated;

GRANT EXECUTE ON FUNCTION public.complete_runsheet_picking(uuid,text,text,jsonb)
TO service_role;
