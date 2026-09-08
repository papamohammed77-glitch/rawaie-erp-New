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
- Primary unresolved risks: open Main5 patch set; unverified deployment/runtime parity; active `verify_jwt=false` historical surface; public EXECUTE on two `SECURITY DEFINER` functions; disabled leaked-password protection; RLS/index/policy debt; broad roles policy; and unresolved delete-runsheet business ownership.
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
- Latest observed `main` commit before this memory write is `d9b30602549190ca15fbdaa45d4263e88eb7a510`, `docs(memory): append 2026-09-08 verified cross-system snapshot`, created `2026-09-08T03:14:35Z`.
- Recent direct commit history also includes `4540d048496a282ddae84ca1c7b3bd18b0b954b5` (continuity state after Main5 M5-20 reconciliation), `be610db2fdafe4f959581bc107dcff2e1f6f507a` (Report82 historical contract reconciliation for Main5 M5-20), `9c2dab4cb7a5f04a36472ae92324f90f1c2380fe` (canonicalize atomic parent POS Invoiced deletion capability), `a4c26d7c5e1a0ebfb0d394b04810126c497b18a4` (restore parent POS Invoiced deletion through atomic core capability), and `c1cade237d0929b8f1a18de7e3c9b2d38fdb8101` (Report81 Main5 M5-20 forensic reverification).
- The latest commit-specific workflow lookup returned no workflow runs. This is absence of commit-scoped CI evidence, not a pass or failure.
- A direct job inspection for run `34071150899` showed the `control-plane` job completed successfully, with completed steps for checkout, operations-queue build/dispatch, and control-plane summary publication. This proves the control-plane job only; it does not prove application build, deployment, browser E2E, or production parity.
- Open PR topology remains fragmented: #127, #126, #125, #123, #119, #118, #117, #115 are open in the retrieved set; #128 is closed without merge; #122, #121, #120, #112, #111, and #109 are merged. Open PR descriptions continue to identify temporary trigger/verifier/executor paths rather than a single authoritative product release.
- Open issues retrieved remain #64, #36, #25, and #26. Their bodies identify execution/reconciliation and Phase-0 technical-baseline work; issue presence is not proof of completion.

### Supabase health, migrations, and Edge Functions
- The current Supabase migration list contains new entries after the prior snapshot: `20260908010304` `enable_realtime_orders_runsheets_fulfillment`, `20260908010601` `add_app_settings_realtime_currency_contract`, `20260908020115` `manage_runsheet_atomic_capability_m5_13_v2`, `20260908030522` `close_parent_pos_invoiced_order_deletion`, `20260908030539` `fix_pos_invoiced_delete_authorization_aggregation`, and `20260908030813` `harden_delete_order_atomic_permission_core`.
- Edge Function inventory now includes `manage-runsheet` as ACTIVE `verify_jwt=true`; the core business function set remains predominantly ACTIVE with `verify_jwt=true`.
- Historical test/canary/fixture/gate/recovery functions remain ACTIVE with `verify_jwt=false`, including picking harness/E2E, owner recovery, auth verification, receive-purchase runtime E2E, and sales canary functions. No retirement or hardening was performed in this refresh.

### Fresh Supabase advisories — observed 2026-09-08
- Security warnings remain for public execution of `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()` as `SECURITY DEFINER` by both `anon` and `authenticated`.
- Supabase Auth leaked-password protection remains disabled.
- Performance findings remain for unindexed foreign keys across operational tables, including `inventory_log.source_branch_id` and `inventory_log.target_branch_id`; RLS init-plan warnings across operational, notification, owner, receiving, financial, and workflow tables; multiple permissive policies on `customer_assignments`, `fulfillment_backorders`, `receiving`, and `receiving_details`; and unused indexes across items, vehicles, orders, finance, workflow, coupons, installments, and related tables.
- No DDL, DML, Edge Function deployment, security remediation, performance remediation, or production-data write was performed by this refresh.

### Logs and cross-system reconciliation
- The connected Supabase actions did not expose a fresh auth/API/Edge log result in this run; no new log-based incident conclusion is recorded.
- GitHub and Supabase are directionally aligned around continued Main5 reconciliation and a centralized/tenant-aware backend, including new realtime contracts and hardening of parent POS invoiced-order deletion.
- The main evidence gap remains deployment/runtime parity: no fresh browser E2E result, deployed revision identity, or service-worker/cache identity was directly proven in this run.
- Secrets, passwords, keys, tokens, or credential material stored/disclosed: `0`.

### 2026-09-08 confidence boundary
```text
LATEST MAIN COMMIT = CONFIRMED (d9b30602549190ca15fbdaa45d4263e88eb7a510 before this write)
COMMIT-SCOPED CI FOR LATEST COMMITS = NO RUNS RETURNED
CONTROL-PLANE RUN 34071150899 = JOB SUCCESS CONFIRMED
OPEN PR/ISSUE SURFACE = CONFIRMED FROM DIRECT GITHUB RESULTS
NEW SUPABASE MIGRATIONS = CONFIRMED
MANAGE-RUNSHEET FUNCTION = CONFIRMED ACTIVE / JWT-PROTECTED
SECURITY ADVISORIES = CONFIRMED (fresh)
PERFORMANCE ADVISORIES = CONFIRMED (fresh)
FRESH SUPABASE LOGS = NOT EXPOSED
DEPLOYED REVISION = UNKNOWN
BROWSER E2E / RUNTIME PARITY = UNKNOWN
GOLD/DIAMOND/WHOLE-SYSTEM CLOSURE = NOT PROVEN
```

### Open risks / next evidence — 2026-09-08
1. Reconcile `CURRENT_STATE.md` against the observed `main` head and recent Main5 M5-20 commits.
2. Obtain commit-specific CI and fresh browser/runtime proof for the current product target.
3. Verify deployment revision and service-worker/cache lineage.
4. Review the new realtime and M5-13/M5-20 database changes against Git consumers and tenant/RLS contracts.
5. Retire or harden obsolete `verify_jwt=false` functions only after dependency proof.
6. Revoke or narrow public EXECUTE on the two exposed `SECURITY DEFINER` functions.
7. Enable leaked-password protection.
8. Prioritize FK indexes, RLS init-plan rewrites, permissive-policy consolidation, and unused-index review.
9. Keep `PROJECT_MEMORY.md` append-only and preserve all earlier evidence classifications.
