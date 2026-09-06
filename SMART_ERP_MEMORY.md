# SMART ERP Cumulative Memory

## 2026-09-06 verified cross-system snapshot

### GitHub
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Default branch: `main`
- Repository is public, active, not archived; connected account has admin/maintain/push permissions.
- Latest observed commit: `315885cac52105aedfaf2046f85b8728689277e6` at `2026-09-06T03:44:47Z`.
- Latest commit message: `docs(memory): refresh 2026-09-06 verified GitHub and Supabase snapshot`.
- Since the previous snapshot, GitHub shows a new daily memory commit plus fresh forensic/main2 continuity commits. A new closure PR is visible: `#128 fix(main2): controlled residual surgical closure`; the duplicated Current/PWA/New-main closure PR family remains open, including `#127`, `#126`, `#125`, `#124`, and earlier triggers.
- The current PR descriptions still describe controlled or target-only execution, but the source snapshot does not itself prove a single authoritative merged closure for `Current/PWA/New-main`.
- The last saved snapshot referenced root `.cto-*` residue; this run did not fetch a fresh root tree listing, so cleanup status is not reclassified.
- No secret keys, passwords, or service-role credentials are stored in this file.

### Supabase
- Project: `SMART ERP` (`fiilmooggumokxanwiyx`)
- Status: `ACTIVE_HEALTHY`
- Region: `eu-west-1`
- PostgreSQL: `17.6.1.121`
- Migration state changed since the prior snapshot: latest observed migration is now `20260905080418 inventory_log_branch_attribution_contract`, newer than the prior `20260902023122 compatibility_company_main_branch_projection_20260902`.
- Edge Functions: the core business functions listed in the live project are active and JWT-protected, including inventory, sales, purchasing, logistics, accounting, reports, and audit paths. A substantial historical test/canary/E2E/recovery surface remains active with `verify_jwt=false`, including `owner-recovery-20260818`, `owner-recover-gate-20260818-7f2d9c41`, `auth-login-verification-20260818`, and multiple runtime E2E/canary functions.
- Security advisor findings remain present as of `2026-09-06T03:46:26Z`: anonymous/authenticated execution of `SECURITY DEFINER` functions `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus leaked-password protection disabled.
- Performance advisor findings remain present as of `2026-09-06T03:46:28Z`: many unindexed foreign keys, repeated auth/current_setting RLS init-plan warnings, multiple permissive policies, and unused indexes. The current output explicitly includes high-impact operational tables such as `inventory_log`, `orders`, `order_details`, `purchase_orders`, `runsheets`, `receiving`, `stock_vouchers`, `users`, `notifications`, and others.
- Edge-function log rows were not fetched in this run; therefore no new log-based conclusion is recorded.

### Delta from previous snapshot
- GitHub advanced from the prior recorded daily memory commit to `315885c...` and exposed PR `#128` as a new residual Main2 closure trigger.
- Supabase advanced from migration `20260902023122` to `20260905080418`, indicating a new production contract around inventory-log branch attribution.
- The key blockers did not clear: no single authoritative merged New-main closure is proven; security advisor warnings persist; performance debt persists; unauthenticated historical test/recovery functions remain deployed.

### Cross-system assessment
- GitHub is moving forward with documentation and controlled Main2/closure execution, but it still shows a fragmented PR topology rather than one verified final artifact.
- Supabase is healthy and has progressed with a newer inventory-log attribution migration, but runtime governance still exposes a broad historical non-JWT test/recovery surface and unchanged security/performance warnings.
- The newer migration increases the need to reconcile the app's inventory-log writes and branch-attribution assumptions against the exact `Current/PWA/New-main` code before deployment.
- Current state remains not proven Gold/Diamond and not proven Closed 100%.

### Follow-up queue
1. Fetch a fresh `main` tree/diff and establish one authoritative merged PR; verify the exact product diff is restricted to `Current/PWA/New-main` plus explicitly approved metadata.
2. Inspect the new `inventory_log_branch_attribution_contract` migration and reconcile all app writers/readers against it.
3. Retire or quarantine obsolete `verify_jwt=false` recovery/canary/E2E functions after confirming no live dependency.
4. Remediate SECURITY DEFINER grants and enable leaked-password protection.
5. Reduce RLS policy duplication and add high-value foreign-key indexes; re-check advisors after changes.
6. Fetch current runtime logs and compare any errors or 4xx/5xx patterns with GitHub workflows and deployed function versions.
7. Re-run full runtime verification on the exact artifact intended for production.
