BEGIN;

ALTER TABLE public.erp_operation_registry ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.erp_operation_registry
FROM anon, authenticated, service_role;

COMMIT;
