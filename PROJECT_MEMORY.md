# SMART ERP — Daily Project Memory

This file is the verified cross-system memory snapshot for the daily review.

## Sources
- GitHub: `papamohammed77-glitch/rawaie-erp-New` (default branch `main`)
- Supabase: `SMART ERP` (`fiilmooggumokxanwiyx`)

## Protected rules
- Do not store passwords, access tokens, service-role/secret keys, session secrets, or other credentials.
- PostgreSQL/Supabase production evidence outranks reports and self-attestation.
- Git chronology/source content does not prove deployment or browser runtime.
- Preserve owner authorization semantics; do not replace owner wildcard permissions with guessed role enumerations.
- `Current/PWA/New-main` remains the canonical application target; PWA consumers remain interfaces/orchestration surfaces, not business authorities.
- `UNKNOWN != BUG`; do not claim closure without current evidence.

## Verified continuity — 2026-09-07
### GitHub
- Latest observed `main` commit before this memory write: `cf87a71d69ec8b616777ffa1e6fcc8fb0c26e38d` (`docs(memory): refresh 2026-09-07 verified GitHub and Supabase snapshot`, 2026-09-07T03:24:16Z).
- Recent history continues to show continuity/reconciliation commits around `CURRENT_STATE`, Report71/Main2, and project memory; no new product deployment is proven by commit messages alone.
- This memory update is documentation-only and does not modify application code, workflows, Supabase schema, Edge Functions, policies, secrets, or production data.
- No fresh browser/runtime or commit-specific product CI proof was obtained in this review.

### Supabase health and schema
- Project `SMART ERP` remains `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- Latest observed migration remains `20260905080418` `inventory_log_branch_attribution_contract`; no newer migration was returned.
- Current schema direction remains aligned with centralized inventory movement authority and explicit source/target branch attribution.

### Edge Functions and authorization
- Core business Edge Functions observed remain active and JWT-protected (`verify_jwt=true`), including inventory, vouchers, purchasing, sales, delivery, accounting, and reporting functions.
- Historical test/canary/fixture/gate/recovery functions remain active with `verify_jwt=false`, including picking E2E/harness functions, owner recovery functions, auth verification, receive-purchase runtime E2E, and sales canary. This remains an explicit attack-surface/lifecycle risk requiring dependency proof before retirement or hardening.
- No Edge Function was deployed, edited, or retired during this review.

### Fresh security advisories — observed 2026-09-07T03:53:37Z
- `public.create_item_with_opening_stock(...)` is callable by both `anon` and `authenticated` as `SECURITY DEFINER`.
- `public.sync_company_main_branch_projection()` is callable by both `anon` and `authenticated` as `SECURITY DEFINER`.
- Supabase Auth leaked-password protection remains disabled.
- These are current advisor findings, not historical report claims. No remediation was applied in this review.

### Fresh performance advisories — observed 2026-09-07T03:53:42Z
- Unindexed foreign keys remain across operational and financial tables, including both `inventory_log` branch foreign keys, `users`, `orders`, `purchase_orders`, `runsheets`, `stock_vouchers`, and multiple accounting/vehicle tables.
- Repeated RLS init-plan warnings remain where `auth.*()`/`current_setting()` may be re-evaluated per row; affected areas include inventory, receiving, notifications, owner profile, financial, workflow, and customer-assignment tables.
- Multiple permissive-policy warnings remain on `customer_assignments`, `fulfillment_backorders`, `receiving`, and `receiving_details`.
- Unused-index findings remain across items, vehicles, orders, finance, workflow, coupons, and related tables.
- No performance DDL changes were applied in this review.

## Cross-system reconciliation
- GitHub continuity work and Supabase production schema remain directionally aligned around a centralized core, tenant-aware operations, explicit inventory branch attribution, and JWT-protected business APIs.
- The principal unresolved risks remain: public `SECURITY DEFINER` EXECUTE exposure, broad active `verify_jwt=false` historical surface, RLS policy/performance debt, and unverified deployment/runtime parity.
- No secrets, keys, passwords, tokens, or sensitive credential material were stored or disclosed.

## Confidence boundary
```text
REPOSITORY/PROJECT IDENTITY = CONFIRMED
LATEST MAIN COMMIT = CONFIRMED
SUPABASE HEALTH = CONFIRMED
LATEST MIGRATION = CONFIRMED
CORE JWT-PROTECTED FUNCTIONS = CONFIRMED
ACTIVE verify_jwt=false TEST/RECOVERY SURFACE = CONFIRMED
SECURITY ADVISORIES = CONFIRMED (fresh 2026-09-07)
PERFORMANCE ADVISORIES = CONFIRMED (fresh 2026-09-07)
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH BROWSER E2E = UNKNOWN
GOLD/DIAMOND/100% CLOSURE = NOT PROVEN
```

## Open risks / next evidence
1. Prove deployed artifact and runtime parity with current GitHub target.
2. Reconcile all `inventory_log` writers/readers against migration `20260905080418`.
3. Retire or harden obsolete `verify_jwt=false` functions after dependency verification.
4. Revoke or narrow public EXECUTE on the two SECURITY DEFINER RPCs.
5. Enable leaked-password protection.
6. Prioritize indexes and RLS policy rewrites for inventory, tenant-scoping, receiving, and financial paths.
7. Preserve historical findings as historical unless re-confirmed from current production evidence.
