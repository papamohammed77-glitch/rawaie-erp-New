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

## 2026-09-08 verified cross-system snapshot

### GitHub
- Latest observed commit: `be610db2fdafe4f959581bc107dcff2e1f6f507a` at `2026-09-08T03:13:27Z`.
- Recent commit sequence includes `Report81` forensic reverification, `Report80` source reconciliation, `M5-13` backend closure, and a new `Report82` historical contract reconciliation for `Main5 M5-20`.
- Additional recent commits explicitly touch atomic parent POS invoiced deletion capability: restore, canonicalization, and related CURRENT_STATE updates.
- Open PR set remains fragmented. Current search still shows `#127`, `#126`, `#125`, `#123`, `#119`, `#118`, `#117`, `#115`, `#113`, `#106`, `#104`, `#103`, `#102`, `#101`, `#100`, `#99`, `#97`, `#93`, `#89`, and older review/test PRs. No single merged PR was found that proves authoritative final closure of `Current/PWA/New-main`.
- Open issues still include `#64`, `#36`, `#25`, and `#26`.
- Important evidence from issue/PR descriptions: some closure paths intentionally pause Browser E2E and authorize only static/syntax/architectural gates; therefore a full runtime proof is still not established by the current GitHub state alone.

### Supabase
- Project is directly confirmed `ACTIVE_HEALTHY` in `eu-west-1` on PostgreSQL `17.6.1.121`.
- Migration head advanced since the previous snapshot to `20260908030813 harden_delete_order_atomic_permission_core`.
- New migrations observed on 2026-09-08 include enabling realtime for orders/runsheets/fulfillment, adding app-settings realtime currency contract, deploying `manage_runsheet_atomic_capability_m5_13_v2`, closing parent POS invoiced order deletion, fixing POS invoiced delete authorization aggregation, and hardening delete-order atomic permission core.
- Edge Functions remain broadly active and JWT-protected across the business surface. A non-JWT historical surface remains active, including `start-picking-production-harness`, `cp-prod-auth-canary-20260814`, multiple runtime E2E/canary functions, `owner-recovery-20260818`, `owner-recover-gate-20260818-7f2d9c41`, and `auth-login-verification-20260818`.
- Security advisors still report the same three blocker classes: public execution of `SECURITY DEFINER` functions `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus disabled leaked-password protection. Observation timestamp: `2026-09-08T03:14:10.279Z`.
- Performance advisors still report unindexed foreign keys, RLS init-plan re-evaluation, unused indexes, and multiple permissive policies. New evidence includes findings on `inventory_log`, `orders`, `order_details`, `purchase_orders`, `runsheets`, `receiving`, `receiving_details`, `stock_vouchers`, `users`, `notifications`, `driver_ledger`, `service_complaints`, and related tables. Observation timestamp: `2026-09-08T03:14:16.472Z`.
- No runtime log rows were obtained in this pass; absence of returned rows is not evidence of absence of errors.

### Delta from 2026-09-07
- GitHub advanced materially from `ce129ad9...` to `be610db...`, with new forensic and contract-reconciliation work plus POS deletion authorization changes.
- Supabase advanced from migration `20260905080418` to `20260908030813`, a significant change that brings realtime contracts and POS/run-sheet deletion authorization into the production schema.
- The previous concern about `Current/PWA/New-main` closure remains unresolved because GitHub still exposes many overlapping open closure triggers and no authoritative merged proof.
- Security/performance advisor classes remain materially unchanged, despite the new migrations.
- The non-JWT historical function surface remains deployed.

### Cross-system assessment
- There is positive backend progress: Supabase now contains the M5-13 manage-runsheet capability and hardened parent POS invoiced order deletion, while GitHub records corresponding forensic reconciliation and CURRENT_STATE updates.
- The key drift risk is now sharper: the production schema has moved ahead with delete/realtime contracts, but direct source-to-runtime parity for the exact `Current/PWA/New-main` artifact and all consumers of the new contracts is still not proven.
- The system is not proven Gold/Diamond and not proven Closed 100%.

### Follow-up queue
1. Compare the exact `main` tree and commits since `ce129ad9...` against `Current/PWA/New-main`; verify target-only scope with an actual diff.
2. Reconcile the new migrations `20260908010304` through `20260908030813` with the app callers, especially manage-runsheet and parent POS invoiced delete flows.
3. Validate realtime subscriptions in the PWA for orders, runsheets, fulfillment, and app-settings currency contract.
4. Retire/quarantine obsolete non-JWT harness/canary/recovery functions after dependency checks.
5. Remediate the three security-advisor blocker classes and rerun advisors.
6. Add high-value foreign-key indexes and simplify duplicate RLS policies, then rerun performance advisors.
7. Obtain runtime logs and complete authenticated browser/HTTP verification against the exact artifact intended for publication.
