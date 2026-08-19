BEGIN;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.stock_branches
FROM anon, authenticated, service_role;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.inventory_log
FROM anon, authenticated, service_role;

GRANT SELECT
ON public.stock_branches
TO anon, authenticated, service_role;

GRANT SELECT
ON public.inventory_log
TO anon, authenticated, service_role;

COMMIT;
