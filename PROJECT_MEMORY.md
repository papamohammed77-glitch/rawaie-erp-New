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

## Verified continuity — 2026-09-07 automation refresh
### GitHub
- Latest observed `main` commit is `2ddd9518d6105fadc18a9376fb5d2450539a79ac`, `docs(memory): refresh 2026-09-07 direct GitHub and Supabase evidence`, created `2026-09-07T10:22:57Z`.
- The latest commit changes only `PROJECT_MEMORY.md`; it is documentation-only. No application-code, workflow, Supabase schema, Edge Function, policy, secret, deployment, or production-data change is proven by that commit.
- Recent history includes Report76/Main5 forensic documentation and a role-save error-handling commit (`cbc30625ee1dea5dbc493e246f1e2cbc609f7e30`), but no new product deployment is proven from commit messages alone.
- Direct `CURRENT_STATE.md` remains stale/inconsistent with the observed branch head: it labels `c7aee872815564b910d7258d5918e550e66dc9da` as `CURRENT GIT HEAD`. Treat that SHA as the forensic checkpoint, not the latest observed branch head, until `CURRENT_STATE.md` is refreshed.
- `CURRENT_STATE.md` still identifies `Current/PWA/main2/main5.md` as the active target, with Main4 source closed/runtime open and Main5 source open with M5-01..M5-12 and M5-14 specified; M5-13 delete-runsheet remains an open contract and must not be invented.
- Latest commit status records: none returned. Latest commit workflow runs: none returned. This is absence of CI evidence, not a CI pass or failure.
- PR topology remains fragmented around Main2/New-main closure and verifier triggers (#128, #127, #126, #125, #124, #123, #122, #121, #120, #119, #59). Connector results did not provide authoritative merged/open state; no closure claim is made.

### Supabase health and schema
- Project `SMART ERP` (`fiilmooggumokxanwiyx`) is `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- Latest migration is `20260905080418` `inventory_log_branch_attribution_contract`; no newer migration was returned.
- Inspected production counts: companies=1, app_settings=1, users=24, roles=20, customers=3, suppliers=1, branches=2, items=17, orders=0, runsheets=0, stock_branches=20, inventory_log=3, journal_entries=2, audit_log=1868.
- Inspected public business tables are RLS-enabled. Verified tenant-linked relationships include companies/branches/users/settings, orders/runsheets, inventory movement, purchasing, accounting, vehicles, workflows, notifications, and audit logging.
- Inventory contract remains: globally unique `items.item_code`; `stock_branches` unique by `(branch_id,item_id)` with generated `available_qty = qty - allocated_qty`; `inventory_log` includes `source_branch_id` and `target_branch_id` with branch foreign keys and excludes `movement_type='Picking'`.
- Current known RLS facts remain: orders authenticated SELECT only with no authenticated UPDATE/DELETE policy; runsheets have company-checked SELECT/INSERT/UPDATE/DELETE; order/runsheet detail reads are tenant-scoped; users, vehicles, and app_settings are company-aware; roles still have a broad `Allow all for all` policy requiring governance closure.

### Edge Functions and authorization
- Core business Edge Functions are ACTIVE and `verify_jwt=true` across master data, sales, runsheets, picking/loading/delivery/returns, stock vouchers, purchasing, accounting, reporting, and vehicle operations.
- Historical test/canary/fixture/gate/recovery functions remain ACTIVE with `verify_jwt=false`, including picking harness/E2E, owner recovery, auth verification, receive-purchase runtime E2E, and sales canary functions. This remains a confirmed attack-surface/lifecycle risk. No function was deployed, retired, or hardened in this refresh.

### Fresh security advisories — observed 2026-09-07T10:42:57.575Z
- `public.create_item_with_opening_stock(...)` is executable by both `anon` and `authenticated` as `SECURITY DEFINER`.
- `public.sync_company_main_branch_projection()` is executable by both `anon` and `authenticated` as `SECURITY DEFINER`.
- Supabase Auth leaked-password protection is disabled.
- No security remediation was applied in this refresh.

### Fresh performance advisories — observed 2026-09-07T10:43:03.684Z
- Unindexed foreign keys remain across inventory, orders, runsheets, purchasing, accounting, vehicles, workflow, and related tables, including both `inventory_log` branch foreign keys.
- RLS init-plan warnings remain across multiple operational, notification, owner, receiving, financial, and workflow tables.
- Multiple permissive-policy warnings remain on `customer_assignments`, `fulfillment_backorders`, `receiving`, and `receiving_details`.
- Unused-index findings remain across items, vehicles, orders, finance, workflow, coupons, installments, and related tables.
- No performance DDL changes were applied in this refresh.

### Logs and deployment evidence
- No fresh auth/API/edge log result was exposed by the connected Supabase actions in this run; no new log-based incident conclusion is recorded.
- Historical `owner-recovery-20260818` HTTP 410 evidence remains historical and unresolved.
- Deployed revision, service-worker/cache identity, browser E2E, and runtime parity with current Git are still unverified.
- Production business-data writes in this refresh: `0`.

## Cross-system reconciliation
- GitHub and Supabase remain directionally aligned around a centralized core, tenant-aware operations, explicit branch attribution, and JWT-protected business APIs.
- No new material product regression was proven in this refresh. Material evidence regressions are the stale `CURRENT_STATE.md` head reference and the continued absence of commit-specific CI/runtime/deployment proof.
- Primary unresolved risks: open Main5 patch set; unverified deployment/runtime parity; active `verify_jwt=false` historical surface; public EXECUTE on two exposed SECURITY DEFINER functions; disabled leaked-password protection; RLS/index/policy debt; broad roles policy; and unresolved delete-runsheet business ownership.
- Secrets, passwords, keys, tokens, or credential material stored/disclosed: `0`.

## Confidence boundary
```text
REPOSITORY/PROJECT IDENTITY = CONFIRMED
LATEST OBSERVED MAIN COMMIT = CONFIRMED
CURRENT_STATE HEAD MATCH = NOT CONFIRMED (stale checkpoint reference)
SUPABASE HEALTH = CONFIRMED
LATEST MIGRATION = CONFIRMED
SCHEMA / RELATIONSHIPS / RLS = CONFIRMED (inspected scope)
CORE JWT-PROTECTED FUNCTIONS = CONFIRMED
ACTIVE verify_jwt=false TEST/RECOVERY SURFACE = CONFIRMED
SECURITY ADVISORIES = CONFIRMED (fresh)
PERFORMANCE ADVISORIES = CONFIRMED (fresh)
MAIN4 SOURCE STATUS = CONFIRMED CLOSED / RUNTIME OPEN
MAIN5 SOURCE STATUS = CONFIRMED OPEN / PATCH SET SPECIFIED
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH BROWSER E2E = UNKNOWN
GOLD/DIAMOND/100% CLOSURE = NOT PROVEN
```

## Classification
### CONFIRMED
- Facts listed above that were returned directly by GitHub or Supabase in this refresh.

### HISTORICAL
- Prior reports, prior CI failures, prior closure labels, historical log evidence, and earlier workflow claims not re-proven against the current source/runtime.

### INFERRED
- GitHub source and Supabase schema are directionally compatible, but this does not prove deployed runtime parity.
- Main5 company-scope, authorized write-boundary, and currency-binding issues remain the next evidence-backed source corrections; no deletion capability should be invented.

### TARGET-CANDIDATE
- Next authorized code target: `Current/PWA/main2/main5.md` for the exact M5-01..M5-12 and M5-14 surgical edits documented in Report76.
- `Current/PWA/New-main` remains protected and should change only on new direct defect evidence.

## Open risks / next evidence
1. Reconcile and refresh `CURRENT_STATE.md` so its head reference matches the latest observed main commit or explicitly labels the forensic checkpoint.
2. Apply and verify the exact Main5 patch set M5-01..M5-12 and M5-14.
3. Re-read the resulting Main5 source from first line to EOF and rerun structural/syntax checks.
4. Reconcile Main5 against current Production RLS and Edge Function ownership.
5. Obtain fresh browser/runtime proof against the exact current Git HEAD.
6. Reconcile deployed artifact and Service Worker/cache lineage.
7. Retire or harden obsolete `verify_jwt=false` functions only after dependency proof.
8. Revoke or narrow public EXECUTE on the two exposed SECURITY DEFINER functions.
9. Enable leaked-password protection.
10. Prioritize FK indexes and RLS policy rewrites; preserve historical evidence as historical unless re-confirmed directly.

## Verified continuity — 2026-09-08 automation refresh
### GitHub
- Latest observed commit in repository history is `ae39cc98c5fd9e22d377e052560522f7a2d3a101`, `docs(cto): add Main7 surgical forensic review 20260908`, created `2026-09-08T10:22:45Z`.
- The latest observed commits are documentation/forensic-review changes plus a source update to `Current/PWA/main2/main7.md`; no fresh deployment or browser runtime proof was returned by the commit listing.
- Direct `CURRENT_STATE.md` is current as a 2026-09-08 checkpoint and identifies Main7 as the active open closure unit. It records Main6 source CLOSED, Main7 source surgery OPEN, full Main2 assembly OPEN/NOT PROVEN, and Parent Gold/Diamond NOT CLOSED.
- Main7 current fragment identity is directly recorded as `0962e20262e77e9e6d8905c83098c2d5fac9210c` and the file is structurally intact at EOF. Open items are M7-07B, M7-09, M7-10, M7-10B, and M7-12; the current delivery lifecycle is intentionally preserved and must not be relabeled without evidence.
- `Current/PWA/New-main` remains a generated target and was not the authorized manual target for this Main7 recheck.

### Supabase health, schema, migrations, and Edge Functions
- Direct project check confirms `SMART ERP` (`fiilmooggumokxanwiyx`) is `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- Latest migration is now `20260908061516` `revoke_legacy_inventory_core_execution_20260908`.
- Direct schema inspection confirms RLS enabled on the inspected public tables and confirms the tenant/branch relationships for companies, branches, users, app_settings, orders, order_details, runsheets, run_sheet_details, vehicles, inventory_log, stock vouchers, purchasing, accounting, notifications, and audit_log.
- Confirmed current contract fields include `inventory_log.source_branch_id`, `inventory_log.target_branch_id`, `stock_branches.available_qty` as generated `qty - allocated_qty`, `runsheets.vehicle_id`, `vehicles.mobile_branch_id`, `inventory_counts.entity_id`, `inventory_count_details.count_id`, and `stock_voucher_details.voucher_id`.
- Direct Edge Function inventory shows core operational functions ACTIVE with `verify_jwt=true`, including `complete-order-delivery` v14, `complete-delivery` v4, `save-inventory-count` v2, `complete-return` v25, and `manage-runsheet` v1.
- Direct Edge Function inventory also confirms the historical test/canary/fixture/gate/recovery surface remains ACTIVE with `verify_jwt=false`, including picking harness/E2E, owner recovery, auth verification, receive-purchase runtime E2E, and sales canary functions.
- No Edge Function deployment, retirement, or hardening was performed by this refresh.

### Fresh Supabase advisories — observed 2026-09-08T10:23:18Z to 2026-09-08T10:23:22Z
- Security advisories remain: two public `SECURITY DEFINER` functions executable by `anon` and `authenticated` (`create_item_with_opening_stock(...)` and `sync_company_main_branch_projection()`), plus disabled leaked-password protection.
- Performance advisories remain: 61 unindexed foreign-key findings, 36 RLS init-plan findings, 29 unused-index findings, and 12 multiple-permissive-policy findings, including concrete findings on inventory_log branch keys, orders/runsheets/purchasing/accounting/vehicle/workflow relations, and receiving/assignment/backorder policy surfaces.
- No security or performance remediation was applied in this refresh.

### Cross-system reconciliation — 2026-09-08
- GitHub current-state evidence and Supabase current schema are directionally aligned on centralized physical-stock ownership, branch attribution, vehicle/mobile-branch identity, order-by-order delivery contracts, and tenant-aware relationships.
- The current evidence gap remains fresh runtime/deployment parity: no commit-specific CI run, deployed revision identity, service-worker/cache identity, or browser E2E result was returned in this refresh.
- The next evidence-backed work unit is Main7 source surgery only; it must be performed on `Current/PWA/main2/main7.md`, followed by full-source re-read, syntax/structure checks, canonical Main2 assembly, and only then runtime verification.
- Production business-data writes in this refresh: `0`.
- Secrets, passwords, keys, tokens, or credential material stored/disclosed: `0`.

### 2026-09-08 confidence boundary
```text
LATEST OBSERVED MAIN COMMIT = CONFIRMED (ae39cc98c5fd9e22d377e052560522f7a2d3a101)
CURRENT_STATE CHECKPOINT = CONFIRMED (2026-09-08)
MAIN7 SOURCE STATUS = CONFIRMED OPEN / OWNER ACTION REQUIRED
FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN
PARENT GOLD/DIAMOND = NOT CLOSED
SUPABASE HEALTH = CONFIRMED
LATEST MIGRATION = CONFIRMED (20260908061516)
CORE EDGE FUNCTIONS = CONFIRMED ACTIVE / JWT-PROTECTED
VERIFY_JWT_FALSE HISTORICAL SURFACE = CONFIRMED ACTIVE
SECURITY ADVISORIES = CONFIRMED (fresh)
PERFORMANCE ADVISORIES = CONFIRMED (fresh)
DEPLOYED REVISION = UNKNOWN
BROWSER E2E / RUNTIME PARITY = UNKNOWN
GOLD/DIAMOND/WHOLE-SYSTEM CLOSURE = NOT PROVEN
```

### Open risks / next evidence — 2026-09-08
1. Owner-only surgical changes remain open for Main7: M7-07B, M7-09, M7-10, M7-10B, and M7-12.
2. Re-read Main7 SOF→EOF from the new SHA and validate syntax/structure.
3. Run canonical Main2 assembly from `Current/PWA/main2/main1..main11` and compare the parent against current Production contracts.
4. Obtain fresh browser/runtime proof against the exact assembled target and verify deployment/cache lineage.
5. Review the 20260908 migrations against Git consumers and tenant/RLS contracts.
6. Retire or harden obsolete `verify_jwt=false` functions only after dependency proof.
7. Revoke or narrow public EXECUTE on the two exposed SECURITY DEFINER functions.
8. Enable leaked-password protection.
9. Prioritize the 61 FK-index findings, 36 RLS init-plan findings, 12 multiple-permissive-policy findings, and 29 unused-index findings.
10. Preserve this file append-only and retain all earlier evidence classifications.

## Verified continuity — 2026-09-12 automation refresh
### GitHub
- Repository identity is confirmed: `papamohammed77-glitch/rawaie-erp-New`, default branch `main`.
- Latest observed repository commit is `f8a0bbbf4db891cd6e6b6bbdff8f39bb738ca946`, `Update main6.md`, created `2026-09-12T03:48:47Z`.
- Immediately preceding commits include `e7b3463902f0df104cfd8e46195b80e1c45fa22d` (Main6 continuity checkpoint), `a60b60e2aca26b6177171d480a78a2bae43b2a4e` (Report125 Main6 forensic recheck), `7ce2e9e9b3dfb508fa5160bb9098ffb2fa924dd0` (Purchases owner replacement), `afab814cf8a4365c2ac5d673594b50b0ecff9ef3` (OnlineStore owner replacement), and `8ba5841e5511bace1934e07f1c906ccde3cbdb47` (orders filtering/rendering refactor).
- Latest visible Actions run is `34671377992` (`CTO final New-main onefile gate`) on the latest commit; it completed with conclusion `failure` at `2026-09-12T03:49:25Z`. This is a direct CI failure and is not a deployment proof.
- PR topology remains fragmented. Current open PRs include #127, #126, #125, #123, #119, #118, #117, #115, and #113. Closed-but-not-merged verification/closure PRs include #129, #128, and #124. Merged verifier triggers include #122, #121, #120, #112, and #111. No open/merged status is inferred beyond the returned PR metadata.
- Open issues directly returned are #64, #36, #25, and #26. Their bodies indicate execution/forensic baseline work, but issue state metadata was incomplete in the connector response.

### Supabase health, migrations, and Edge Functions
- Project `SMART ERP` (`fiilmooggumokxanwiyx`) is `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- New migrations since the prior snapshot are confirmed through `20260911221155` `online_order_idempotency_contract`. Recent migrations include enterprise completion/finance/decision guards, employee-document company/storage scope fixes, roles RLS tightening, runsheet atomic closure, online-order limits, and online-order idempotency.
- Core business Edge Functions remain ACTIVE with `verify_jwt=true`, including order, runsheet, picking/loading/delivery/returns, stock vouchers, purchasing, accounting/reporting, and `manage-runsheet`.
- Historical test/canary/fixture/gate/recovery functions remain ACTIVE with `verify_jwt=false`, including picking harness/E2E, owner recovery, auth verification, receive-purchase runtime E2E, and sales canary functions. This remains a confirmed lifecycle and attack-surface risk.

### Fresh Supabase security advisories — observed 2026-09-12T03:55:10Z
- One mutable search path warning remains for `public.employee_document_storage_company_id`.
- Two public `SECURITY DEFINER` functions remain executable by `anon` and `authenticated`: `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`.
- Three additional authenticated `SECURITY DEFINER` execution findings remain for `public.get_balance_sheet_data(...)`, `public.get_enterprise_decision_center(...)`, and `public.post_financial_entry_atomic(...)`.
- Supabase Auth leaked-password protection remains disabled.
- No security remediation was applied in this refresh.

### Fresh Supabase performance advisories — observed 2026-09-12T03:55:18Z
- 62 unindexed foreign-key findings remain.
- 37 RLS init-plan findings remain.
- 32 unused-index findings remain.
- 6 multiple-permissive-policy findings remain.
- One duplicate-index finding is present on `public.orders` for `orders_company_operation_id_uidx` and `orders_company_operation_id_unique`.
- No performance DDL changes were applied in this refresh.

### Logs and deployment evidence
- No direct Auth/API/Edge log query result was exposed by the available Supabase actions in this run; no new log-based incident conclusion is recorded.
- Deployed revision, service-worker/cache identity, browser E2E, and runtime parity with current Git remain unverified.
- Production business-data writes in this refresh: `0`.

### Cross-system reconciliation — 2026-09-12
- GitHub shows active Main6 forensic/source work plus a current failing New-main onefile gate; Supabase shows continued schema hardening and idempotency/tenant/security migrations.
- The sources are directionally aligned around a centralized, tenant-aware core, but the failing CI run and absent deployment/runtime proof prevent a Gold/Diamond or whole-system closure claim.
- The highest-priority evidence-backed risks are: current New-main gate failure, active `verify_jwt=false` historical functions, exposed `SECURITY DEFINER` EXECUTE grants, mutable function search path, disabled leaked-password protection, FK/RLS/policy/index debt, and duplicate orders indexes.
- Secrets, passwords, keys, tokens, or credential material stored/disclosed: `0`.

### 2026-09-12 confidence boundary
```text
REPOSITORY/PROJECT IDENTITY = CONFIRMED
LATEST OBSERVED MAIN COMMIT = CONFIRMED (f8a0bbbf4db891cd6e6b6bbdff8f39bb738ca946)
LATEST CI RESULT = CONFIRMED FAILURE (run 34671377992)
OPEN PR TOPOLOGY = CONFIRMED FROM RETURNED METADATA
OPEN ISSUES = CONFIRMED FROM RETURNED METADATA (state field incomplete)
SUPABASE HEALTH = CONFIRMED
LATEST MIGRATION = CONFIRMED (20260911221155)
CORE EDGE FUNCTIONS = CONFIRMED ACTIVE / JWT-PROTECTED
VERIFY_JWT_FALSE HISTORICAL SURFACE = CONFIRMED ACTIVE
SECURITY ADVISORIES = CONFIRMED (fresh)
PERFORMANCE ADVISORIES = CONFIRMED (fresh)
SUPABASE LOG INCIDENT = NOT PROVEN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH BROWSER E2E / RUNTIME PARITY = UNKNOWN
GOLD/DIAMOND/WHOLE-SYSTEM CLOSURE = NOT PROVEN
```

### Open risks / next evidence — 2026-09-12
1. Investigate and resolve the direct CI failure in run `34671377992` before treating New-main as verified.
2. Fetch the failing job logs and identify whether the failure is syntax, browser, manifest, dependency, or workflow related.
3. Reconcile the current Main6 source changes with the canonical Main2/New-main target and current Supabase contracts.
4. Obtain fresh browser/runtime proof against the exact current Git HEAD and verify deployment/cache lineage.
5. Retire or harden obsolete `verify_jwt=false` functions only after dependency proof.
6. Revoke or narrow public EXECUTE on the exposed SECURITY DEFINER functions and set an explicit search_path for `employee_document_storage_company_id`.
7. Enable leaked-password protection.
8. Prioritize the 62 FK-index findings, 37 RLS init-plan findings, 6 multiple-permissive-policy findings, 32 unused-index findings, and the duplicate orders indexes.
9. Preserve this file append-only and retain all earlier evidence classifications.
