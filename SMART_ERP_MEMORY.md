# SMART ERP Cumulative Memory

## 2026-09-07 verified cross-system snapshot

### GitHub
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Default branch: `main`
- Repository is public, active, not archived; connected account has admin/maintain/push permissions.
- Latest observed commit: `ce129ad9c5f6e4660139328c2fecfa863d9be0d1` at `2026-09-06T10:24:29Z`.
- Latest commit message: `docs(memory): refresh 2026-09-06 current GitHub and Supabase snapshot`.
- Compared with the previous saved snapshot, the repository advanced beyond `315885cac...`; the newest visible commits are additional memory refreshes and forensic/main2 reconciliation records.
- PR `#128` is now closed without merge. PR `#127` remains open and mergeable; the broader duplicated closure family remains open, including `#126`, `#125`, `#123`, `#119`, `#118`, `#117`, `#115`, `#113`, and older closure/verification triggers.
- Issue search still exposes open execution/governance records including `#64`, `#36`, `#25`, and `#26`; these remain evidence of unfinished or historical work queues rather than proof of final closure.
- The source data still does not prove one authoritative merged closure for `Current/PWA/New-main`; descriptions claim target-only execution, but the final merged diff and full runtime proof are not established by this snapshot.
- No fresh root-tree listing was available in this run, so prior `.cto-*` residue status is carried forward as unknown rather than cleared.
- No secret keys, passwords, or service-role credentials are stored in this file.

### Supabase
- Project: `SMART ERP` (`fiilmooggumokxanwiyx`)
- Project state was not re-enumerated by a dedicated project-health endpoint in this run; prior recorded state remains `ACTIVE_HEALTHY` in the cumulative memory.
- Latest observed migration remains `20260905080418 inventory_log_branch_attribution_contract`, newer than `20260902023122 compatibility_company_main_branch_projection_20260902`.
- Live Edge Functions are broadly active and JWT-protected for core business paths, including master data, sales, inventory, logistics, purchasing, accounting, reports, notifications, and audit operations.
- A substantial historical non-JWT surface remains deployed (`verify_jwt=false`), including production harness, canary, runtime E2E, recovery, and login-verification functions such as `start-picking-production-harness`, `cp-prod-auth-canary-20260814`, `owner-recovery-20260818`, `owner-recover-gate-20260818-7f2d9c41`, `auth-login-verification-20260818`, and multiple runtime E2E/canary endpoints.
- Security advisors observed at `2026-09-07T03:23:31.864Z` still report anonymous and authenticated execution of `SECURITY DEFINER` functions `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus leaked-password protection disabled.
- Performance advisors observed at `2026-09-07T03:23:36.792Z` still report numerous unindexed foreign keys, RLS init-plan re-evaluation warnings, multiple permissive policies, and unused indexes. The findings include operational surfaces such as `inventory_log`, `orders`, `order_details`, `purchase_orders`, `runsheets`, `receiving`, `stock_vouchers`, `users`, `notifications`, `driver_ledger`, and related tables.
- Edge-function log rows were not fetched in this run; no new log-based conclusion is recorded.

### Delta from previous snapshot
- GitHub advanced from the prior recorded head `315885cac...` to `ce129ad9...` with an additional memory-refresh commit.
- PR `#128` moved from the prior visible state to closed/unmerged; PR `#127` and many other closure PRs remain open.
- Supabase migration state did not advance beyond `20260905080418` in the evidence collected this run.
- Security and performance advisor findings remain open and materially unchanged.
- The non-JWT historical test/recovery surface remains deployed; this blocker did not clear.

### Cross-system assessment
- GitHub continues to show documentation and controlled execution activity, but the PR topology remains fragmented and does not establish one final production artifact.
- Supabase remains governed by a newer inventory-log branch-attribution contract than the previous snapshot, while runtime security/performance findings and historical non-JWT functions remain unresolved.
- The principal cross-system drift risk is still the absence of direct proof that the exact `Current/PWA/New-main` artifact on `main` is fully reconciled with the current production migration/function contracts.
- Current state remains not proven Gold/Diamond and not proven Closed 100%.

### Follow-up queue
1. Fetch a fresh `main` tree and exact commit diff; prove the final product change is limited to `Current/PWA/New-main` plus explicitly approved metadata.
2. Read and reconcile `inventory_log_branch_attribution_contract` against every app writer/reader in `Current/PWA/New-main`.
3. Retire or quarantine obsolete `verify_jwt=false` recovery/canary/E2E functions after dependency checks.
4. Remediate SECURITY DEFINER grants and enable leaked-password protection.
5. Reduce RLS policy duplication and add high-value foreign-key indexes; then re-run advisors.
6. Fetch current runtime logs and compare 4xx/5xx or error patterns with GitHub workflow activity and deployed function versions.
7. Re-run full runtime verification on the exact artifact intended for production.
