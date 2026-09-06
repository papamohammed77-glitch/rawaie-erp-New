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

## Historical context
### 2026-09-03 to 2026-09-05
- Established the PWA/Core/Edge-Function/PostgreSQL separation, Supabase Auth + bearer JWT boundary, owner/license continuity requirements, and the inventory authority model.
- Verified production owner continuity: active owner, wildcard permissions `["*"]`, linked owner profile, and active license.
- Verified the Main2 movement-report rewrite in Git: `Current/PWA/main2/main2.md` reads from centralized `inventory_log`, resolves `item_code` to `items.id`, uses branch attribution, computes opening balance, and excludes non-physical legacy movements from the physical report. Browser/runtime proof remained open.
- Verified production branch-attribution contract: `inventory_log.source_branch_id` and `target_branch_id` exist with branch foreign keys; `post_stock_movement` persists source/target. Transactional verification was rolled back without permanent test-data mutation.
- Verified Main3 forensic findings: supplier/user/role reads need explicit company scoping; `customer_assignments.assigned_by` is UUID-backed but the current source sends email; currency hydration is missing; `delete-employee` has a separate backend defect because deletion is email-scoped without `company_id`.
- Preserved the Patch D question as open: import input accepts `item_code` while historical downstream lookup may use `items.barcode`.

## Verified continuity — 2026-09-06 current review
### GitHub
- Latest observed `main` commit: `b233e7d6ebbd3c7370687ff0cd85d707a795641b` (`docs(memory): refresh 2026-09-06 verified GitHub and Supabase snapshot`, `2026-09-06T03:46:36Z`).
- Immediately preceding memory commit: `315885cac52105aedfaf2046f85b8728689277e6` (`2026-09-06T03:44:47Z`).
- The latest top-level change is documentation/continuity maintenance in `SMART_ERP_MEMORY.md`; no new application deployment is proven by this commit.
- `CURRENT_STATE.md` is still checkpointed `2026-09-05`; it records Main2 B/C source integration as present in current Git, Main3 manual patches pending, `delete-employee` backend defect open, and project closure not claimed.
- Commit status records for `b233e7...` are empty. A commit-filtered Actions query returned 21 historical/scheduled runs attached to the SHA; the visible run was `Operations Team Scheduler`, completed `success` on `2026-09-06T09:08:07Z`. This is not evidence of a product build/deploy or full CI gate pass.
- PR topology remains fragmented. Current continuity notes identify open closure/trigger PRs including #128 and the earlier #127/#126/#125/#124 family; no single authoritative merged `Current/PWA/New-main` closure is proven. Root `.cto-*` cleanup was not reclassified in this run because a fresh root tree listing was not fetched.

### Supabase health and schema
- Project remains `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- Latest observed migration: `20260905080418` `inventory_log_branch_attribution_contract`, newer than `20260902023122` `compatibility_company_main_branch_projection_20260902`.
- Key production row-count anchors remain: `companies=1`, `branches=2`, `users=24`, `app_settings=1`, `items=17`, `stock_branches=20`, `inventory_log=3`, `stock_vouchers=0`, `orders=0`, `purchase_orders=0`, `journal_entries=2`, `owner_profile=1`, `audit_log=1868`.
- Public business tables observed in the current schema are RLS-enabled.
- `items.item_code` is globally unique; `items.barcode` is not unique.
- `stock_branches.available_qty` is generated as `qty - allocated_qty`.
- `inventory_log` has `item_id`, `item_code`, `movement_type`, `qty`, `idempotency_key`, `source_branch_id`, and `target_branch_id`; the branch columns have foreign keys to `branches`; `movement_type` rejects `Picking`.
- `customer_assignments.assigned_by` is UUID-backed with an FK to `users.id`; `users.auth_id` is unique and references `auth.users`.
- `app_settings` contains `currency` and `main_branch_id`; `companies.main_branch_id/main_branch_code` are compatibility read projections only.
- Historical continuity remains: owner profile and active-owner wildcard authorization semantics are preserved; no production business-data write was made during this review.

### Edge Functions and authorization
- Representative business functions remain active and JWT-protected (`verify_jwt=true`), including `save-item v12`, `save-settings v13`, `save-sales-invoice v15`, `create-runsheet v26`, `start-picking v34`, `complete-picking v17`, `start-loading v5`, `complete-loading v11`, `start-delivery v7`, `complete-delivery v4`, `complete-return v25`, `send-stock-voucher v20`, `receive-stock-voucher v22`, `receive-purchase v12`, `save-journal-entry v8`, and `bulk-stock-adjustment v6`.
- Historical test/canary/fixture/gate/recovery functions remain active with `verify_jwt=false`, including `start-picking-production-harness`, `cp-prod-auth-canary-20260814`, `cp-prod-fixture-canary-20260814`, `start-picking-e2e-fixture-20260815`, `start-picking-real-identity-e2e-20260815`, `send-stock-voucher-runtime-e2e-20260818`, `prompt2-complete-picking-http-e2e-20260818`, `complete-picking-runtime-e2e-20260818`, `owner-recovery-20260818`, `owner-recover-gate-20260818-7f2d9c41`, `auth-login-verification-20260818`, `complete-picking-picker-http-gate-20260818`, `receive-purchase-runtime-e2e-20260819`, and `save-sales-production-canary-20260819`.
- This remains a material attack-surface and lifecycle risk. It is not proof that each function is exploitable, but each requires explicit retention/authorization justification or retirement.

### Logs and advisories
- The Supabase connector did not expose a fresh auth/edge log query result in this run, so no new log-based incident conclusion is recorded. Historical `owner-recovery-20260818` HTTP 410 evidence remains unresolved historical evidence only.
- Fresh security advisors observed at `2026-09-06T10:23:40.210Z` still report anonymous and authenticated EXECUTE exposure for SECURITY DEFINER RPCs `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`. Leaked-password protection remains disabled.
- Fresh performance advisors observed at `2026-09-06T10:23:45.385Z` still report many unindexed foreign keys, including both `inventory_log` branch foreign keys; repeated RLS init-plan warnings across operational tables; multiple permissive policies on `customer_assignments`, `fulfillment_backorders`, `receiving`, and `receiving_details`; and multiple unused indexes.

## Cross-system reconciliation
- GitHub Main2 source direction and Supabase migration `20260905080418` are aligned around centralized `inventory_log` movement reporting plus source/target branch attribution.
- This is source/schema evidence only. The deployed browser revision, service-worker/cache identity, exact deployed Edge Function revision, and full runtime behavior remain unverified.
- No material regression was proven in this run. The material unresolved authorization risks are the public SECURITY DEFINER EXECUTE grants, broad historical `verify_jwt=false` function surface, the broad `roles` RLS residue recorded in `CURRENT_STATE.md`, and the open `delete-employee` tenant-scoping defect.
- No production schema write, Edge Function deployment, credential rotation, or permanent business-data mutation was performed.

## Confidence boundary
```text
REPOSITORY/PROJECT IDENTITY = CONFIRMED
LATEST MAIN COMMIT = CONFIRMED
CURRENT_STATE/CURRENT GIT = CONFIRMED
SUPABASE HEALTH = CONFIRMED
LATEST MIGRATION = CONFIRMED
RLS-ENABLED PUBLIC SCHEMA = CONFIRMED
CORE JWT-PROTECTED FUNCTIONS = CONFIRMED
ACTIVE verify_jwt=false TEST/RECOVERY SURFACE = CONFIRMED
SECURITY/PERFORMANCE ADVISORIES = CONFIRMED
COMMIT-SPECIFIC PRODUCT CI PASS = NOT PROVEN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH BROWSER E2E = UNKNOWN
GOLD/DIAMOND/100% CLOSURE = NOT PROVEN
```

## Open risks / next evidence
1. Fetch a fresh `main` tree/diff and prove one authoritative merged product closure restricted to `Current/PWA/New-main` plus approved metadata.
2. Reconcile all inventory-log writers/readers against migration `20260905080418` and verify the deployed revision/cache uses the current movement reader.
3. Retire or quarantine obsolete `verify_jwt=false` functions after confirming no live dependency.
4. Revoke or harden public EXECUTE on the two SECURITY DEFINER RPCs and enable leaked-password protection.
5. Resolve unindexed foreign keys, RLS init-plan warnings, multiple permissive policies, and unused-index debt, prioritizing inventory and tenant-scoping paths.
6. Apply and verify Main3 patches S1-S6 exactly as documented; then close the separate `delete-employee` backend defect with a company-scoped delete predicate.
7. Preserve Patch D as open until historical import-contract evidence resolves `item_code` versus `barcode` behavior.
8. Run fresh browser/runtime verification on the exact artifact intended for production.
