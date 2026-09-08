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
- Latest observed `main` commit before this memory write is `4768d861c840f5f16fcc423abff1d381be2e5788`, `Update main5.md`, created `2026-09-08T03:48:26Z`.
- The immediately preceding direct commits include `641cebcce50f2861b1167779dead4f38d4f10736` (Report83/Main6 forensic surgical reconciliation), `53456ecabea3d979942481b16fae371953b5c683` (CURRENT_STATE update for Main6), `fc96167566a1d96740663e43c11472194a7068d9` (Report83), and `dc83dfae85b94d40e47b0f94e9070e4e9006f9d9` (cross-system memory snapshot).
- Commit-scoped workflow lookup for `4768d861c840f5f16fcc423abff1d381be2e5788` returned no workflow runs. This is absence of CI evidence, not a pass or failure.
- The newest GitHub change is source-level (`main5.md`); no deployment, browser E2E, or runtime-parity proof was returned in this refresh.

### Supabase health, migrations, and Edge Functions
- `SMART ERP` remains `ACTIVE_HEALTHY` in `eu-west-1` on PostgreSQL `17.6.1.121`.
- New migrations after the prior snapshot are confirmed: `20260908010304` `enable_realtime_orders_runsheets_fulfillment`, `20260908010601` `add_app_settings_realtime_currency_contract`, `20260908020115` `manage_runsheet_atomic_capability_m5_13_v2`, `20260908030522` `close_parent_pos_invoiced_order_deletion`, `20260908030539` `fix_pos_invoiced_delete_authorization_aggregation`, and `20260908030813` `harden_delete_order_atomic_permission_core`.
- Edge Function inventory now includes `manage-runsheet` ACTIVE with `verify_jwt=true`. The core business function inventory remains overwhelmingly ACTIVE with `verify_jwt=true`.
- Historical test/canary/fixture/gate/recovery functions remain ACTIVE with `verify_jwt=false`, including picking harness/E2E, owner recovery, auth verification, receive-purchase runtime E2E, and sales canary surfaces. No retirement or hardening was performed in this refresh.

### Fresh Supabase security advisories — observed 2026-09-08T03:51:02.697Z
- Public execution warnings remain for `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()` as `SECURITY DEFINER` by both `anon` and `authenticated`.
- Supabase Auth leaked-password protection remains disabled.

### Cross-system reconciliation and open work
- GitHub and Supabase remain directionally aligned around centralized/tenant-aware operations, realtime enablement for orders/runsheets/fulfillment, and explicit hardening of parent POS invoiced-order deletion.
- The main evidence gap remains deployment/runtime parity: no fresh browser E2E result, deployed revision identity, or service-worker/cache identity was directly proven in this run.
- High-priority unresolved items remain: stale/fragmented continuity records, active `verify_jwt=false` historical surface, public EXECUTE on the two SECURITY DEFINER functions, disabled leaked-password protection, and outstanding RLS/index/policy debt.
- Production business-data writes in this refresh: `0`.
- Secrets, passwords, keys, tokens, or credential material stored/disclosed: `0`.

### 2026-09-08 confidence boundary
```text
LATEST MAIN COMMIT = CONFIRMED (4768d861c840f5f16fcc423abff1d381be2e5788 before this write)
COMMIT-SCOPED CI FOR LATEST COMMIT = NO RUNS RETURNED
SUPABASE HEALTH = CONFIRMED
NEW MIGRATIONS = CONFIRMED
MANAGE-RUNSHEET = CONFIRMED ACTIVE / JWT-PROTECTED
VERIFY_JWT_FALSE HISTORICAL SURFACE = CONFIRMED ACTIVE
SECURITY ADVISORIES = CONFIRMED (fresh)
DEPLOYED REVISION = UNKNOWN
BROWSER E2E / RUNTIME PARITY = UNKNOWN
GOLD/DIAMOND/WHOLE-SYSTEM CLOSURE = NOT PROVEN
```

### Open risks / next evidence — 2026-09-08
1. Reconcile `CURRENT_STATE.md` and Report83/Main6 continuity records against latest `main5.md` changes.
2. Obtain commit-specific CI and fresh browser/runtime proof for the current product target.
3. Verify deployment revision and service-worker/cache lineage.
4. Review the six new migrations against Git consumers and tenant/RLS contracts.
5. Retire or harden obsolete `verify_jwt=false` functions only after dependency proof.
6. Revoke or narrow public EXECUTE on the two exposed SECURITY DEFINER functions.
7. Enable leaked-password protection.
8. Prioritize FK indexes, RLS init-plan rewrites, permissive-policy consolidation, and unused-index review.
9. Keep `PROJECT_MEMORY.md` append-only and preserve all earlier evidence classifications.
