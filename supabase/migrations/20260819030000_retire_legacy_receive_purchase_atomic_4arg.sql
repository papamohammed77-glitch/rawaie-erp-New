-- RAWAEA ERP — retire legacy receive_purchase_atomic 4-argument overload.
-- Canonical Production contract is the request-idempotent 5-argument function.
-- Dependency inspection before retirement found zero dependent DB objects.
DROP FUNCTION public.receive_purchase_atomic(uuid,text,text,jsonb);
