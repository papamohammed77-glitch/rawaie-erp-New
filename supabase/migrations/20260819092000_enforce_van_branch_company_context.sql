BEGIN;

CREATE OR REPLACE FUNCTION public.enforce_van_branch_company_context()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_company_id uuid;
BEGIN
  IF NEW.branch_code LIKE 'VAN-%' AND auth.uid() IS NOT NULL THEN
    v_company_id := app_private.current_user_company_id();
    IF v_company_id IS NULL THEN
      RAISE EXCEPTION 'user company context unavailable';
    END IF;
    NEW.company_id := v_company_id;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_enforce_van_branch_company_context ON public.branches;

CREATE TRIGGER trg_enforce_van_branch_company_context
BEFORE INSERT OR UPDATE OF company_id, branch_code
ON public.branches
FOR EACH ROW
EXECUTE FUNCTION public.enforce_van_branch_company_context();

REVOKE ALL ON FUNCTION public.enforce_van_branch_company_context() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.enforce_van_branch_company_context() TO authenticated, service_role;

COMMIT;
