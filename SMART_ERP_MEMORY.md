# SMART ERP Cumulative Memory

## 2026-09-05 verified cross-system snapshot

### GitHub
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Default branch: `main`
- Repository is public, active, not archived; connected account has admin/maintain/push permissions.
- Latest observed commit: `8e5fe0d7427f8e16a8094da9e86a26e486c9cea3` at `2026-09-05T01:42:35Z`.
- Latest commit message: `Refactor functions and enhance voucher query logic`.
- Recent commits also include CTO/Main2 continuity and forensic review documentation updates.
- Open PRs remain highly duplicated around Current/PWA/New-main closure. The newest observed open PR is #127; listed closure PRs are open and not merged. Several are marked non-mergeable in the source snapshot.
- Root `main` still contains many temporary `.cto-*` trigger files, indicating unresolved execution-scaffolding residue.
- No evidence in this run proves that only `Current/PWA/New-main` is the final published product surface; that proof requires a clean merged diff on `main`.

### Supabase
- Project: `SMART ERP` (`fiilmooggumokxanwiyx`)
- Status: `ACTIVE_HEALTHY`
- Region: `eu-west-1`
- PostgreSQL: `17.6.1.121`
- Latest migration observed: `20260902023122 compatibility_company_main_branch_projection_20260902`.
- The database contains extensive central inventory, sales, purchasing, logistics, accounting, driver/supplier ledger, settlement, notification, and audit infrastructure.
- Security advisor findings still present: anonymous/authenticated execution of SECURITY DEFINER functions `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus leaked-password protection disabled.
- Performance advisor findings still present: unindexed foreign keys, auth RLS init-plan warnings, multiple permissive policies, and unused indexes.
- Edge Functions: core business functions are active and JWT-protected; many historical canary/E2E/recovery functions remain active with `verify_jwt=false`, including owner recovery and runtime test functions.
- Edge-function logs returned no rows in the latest 24-hour query.

### Cross-system assessment
- GitHub continues to show active closure/forensic work, but no single authoritative merged closure is visible.
- Supabase runtime is healthy but still carries security/performance debt and test/recovery surface residue.
- Current state is not proven Gold/Diamond or Closed 100%.

### Follow-up queue
1. Establish one authoritative merged PR and verify the exact `main` diff is restricted to `Current/PWA/New-main` plus explicitly approved non-product metadata.
2. Remove or retire temporary `.cto-*` scaffolding from the final branch where safe.
3. Reconcile GitHub application code with deployed Edge Function versions and the latest migration contract.
4. Remediate SECURITY DEFINER grants and enable leaked-password protection.
5. Quarantine or delete obsolete `verify_jwt=false` recovery/canary/E2E functions after confirming no live dependency.
6. Reduce RLS policy duplication and add high-value foreign-key indexes.
7. Re-run full runtime verification on the exact artifact intended for production.

No secret keys, passwords, or service-role credentials are stored in this file.
