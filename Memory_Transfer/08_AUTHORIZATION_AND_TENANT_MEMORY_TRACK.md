# AUTHORIZATION AND TENANT MEMORY TRACK

## Identity model
Current governing graph:
auth.users.id → public.users.auth_id → public.users.id → public.users.company_id → role/permission → application/Edge → Core RPC → company-scoped rows. fileciteturn228file0

## Critical lesson
Authentication != authorization. Tenant context must come from authenticated application-user identity where the current contract requires it; `app_settings.limit(1)` is an unsafe global context pattern and has been a proven source of defects.

## Production example
`start-picking` Production v14 uses `public.users.id = auth user id` and derives `company_id` from the user record. Current Git `start-picking` on `main` currently uses `public.users.auth_id = auth user id`, producing a real Git/Production parity conflict that must be reconciled against the deployed contract before treating Current as the canonical final source.

## Security controls
Core RPCs reviewed in the rescue stream use SECURITY DEFINER/search_path controls; RLS is not disabled as a workaround. Full ERP-wide role/permission mapping remains OPEN. 

## Required future work
- Reconcile all critical Edge Functions to the same authoritative identity contract.
- Trace role/permission checks end-to-end.
- Verify RLS policies and grants for all critical functions.
- Preserve one-company/multi-branch V1 architecture unless an explicit target decision changes it.
