# AUTHORIZATION AND TENANT MEMORY TRACK

## LIVE IDENTITY CONTRACT
`auth.users.id → public.users.auth_id → public.users.id → company_id → role/permissions → branch scope`

Current live schema confirms `public.users.auth_id` is the relationship to `auth.users(id)` and is uniquely constrained.

## CURRENT PRODUCTION
- companies 3
- users 26
- branches 5
- RLS tables 62
- RLS policies 102

## CURRENT START-PICKING PARITY
Production `start-picking` v33 and current Git `Current/Edge_Functions/start-picking` both query `public.users` by `auth_id = auth.users.id` and then use `public.users.id` as the ERP identity.

The older handoff statement that Production v14 used `public.users.id = auth.users.id` is obsolete historical state.

## TENANT CONTRACT
A business operation must obtain company context from authenticated identity and then scope all tenant-owned reads/writes by `company_id`. `LIMIT 1` is forbidden for tenant identity when it can select another company context.

## CURRENT SECURITY POSTURE
Core reviewed domains use RLS, helper context functions, and SECURITY DEFINER RPCs. However, the ERP-wide authorization matrix remains incomplete.

## FINANCIAL SECURITY
Prompt 51 exposed broad direct DML/RLS patterns on multiple financial tables. Staging write-boundary tests passed, but Production lockdown remains gated by Consumer Matrix and runtime proof.

## OPEN
- Full current Edge/PWA auth→authorization matrix.
- Direct write surface inventory outside core domain RPCs.
- Full deployment/runtime proof.
- Final financial security rollout.
- Classification/removal of temporary registry functions.

## LESSON
An identity fix is never global by appearance. Re-check the live relation before modifying each consumer.