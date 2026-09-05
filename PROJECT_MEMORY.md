# SMART ERP — Daily Project Memory

This file is the verified cross-system memory snapshot for the daily review.

## Sources
- GitHub: `papamohammed77-glitch/rawaie-erp-New` (default branch `main`)
- Supabase: `SMART ERP` (`fiilmooggumokxanwiyx`)

## Protected rules
- Do not store passwords, access tokens, service-role/secret keys, session secrets, or other credentials.
- PostgreSQL/Supabase production evidence outranks reports and self-attestation.
- Git chronology/source content does not prove deployment or browser runtime.
- `Current/PWA/New-main` is the canonical current application target; PWA consumers remain interface/orchestration surfaces, not business authorities.
- Preserve owner authorization semantics; do not replace owner wildcard permissions with guessed role enumerations.
- Do not reopen a closed knowledge baseline without fresh contradictory evidence.

## Historical context
### 2026-09-03 — initial and forensic continuity baseline
- Supabase connectivity verified.
- Prior reviews recorded the PWA/Core/Edge-Function/PostgreSQL separation, Supabase Auth + bearer JWT pattern, and owner/license continuity constraints.
- Production owner was verified as active with wildcard permissions `["*"]`, linked owner profile, and active license; no production write was performed in the baseline review.
- Earlier continuity notes recorded security/performance advisories, stale recovery/test function surface, and lack of fresh full-browser Gold/Diamond proof.

### 2026-09-04 — continuity and knowledge baseline
- `CURRENT_STATE.md` and project-memory continuity were refreshed around the canonical `Current/PWA/New-main` target.
- The shared runtime boundary remains `RW_Auth`, `RW_DB`, `RW_API`, and `RW_UI`; Supabase Auth metadata, owner wildcard permissions, Dexie/local sync, and bearer-token Edge Function calls are part of the verified source contract.
- Historical `Current/PWA/main/main1.md` remains useful for comparison only; visual differences from New-main are not by themselves regressions.
- Production owner continuity remains: active owner, `permissions=["*"]`, valid `owner_profile`, active license.

## Verified continuity — 2026-09-05 automation run 2
### GitHub current snapshot
- Repository identity rechecked directly: `papamohammed77-glitch/rawaie-erp-New`, public, default branch `main`, connected account has repository write/admin-level permissions.
- Latest visible `main` commit: `36482301223c07ddd256c87a2bc712198d955b7a` (`Update main2.md`, 2026-09-05T10:26:28Z).
- Immediately preceding continuity commits include Report70/Report69 reconciliation and branch-attribution closure: `c984be5...`, `5f0a018...`, `7e16c744...`, `ba750f3...`.
- Latest code-bearing change is material: `Current/PWA/main2/main2.md` rewrote `_loadMovementReport()` from `stock_vouchers` + `stock_voucher_details` reads to the central `inventory_log` contract. The new reader resolves the item by `item_code` to `item.id`, filters by company/item and optional branch, computes physical movement impact from `source_branch_id`/`target_branch_id`, calculates opening balance for `fromDate`, and excludes non-physical legacy movement types from the physical report.
- The same latest diff also replaces the branch-stock movement reader with the shared movement-report path; this is the source-level closure expected by the prior Patch C plan.
- `CURRENT_STATE.md` still records the governance rule `GIT != DEPLOYMENT PROOF`. Prior state listed Patch B/C as manual and runtime verification as unknown; the new commit is source evidence that the corresponding Main2 changes are now present on current `main`, but browser/runtime proof is still not established.
- Combined commit status for `364823...` returned no status records; the commit-specific workflow-run lookup returned no runs. This is not a CI PASS.
- Current PR search still shows many closure/execution-trigger PRs, including #128, #127, #126, #125, #124, #123, #122, #121, #120, #119, #118, #117, #116, #115, #114, #113, #112, #111, and #110. Their descriptions emphasize target-only surgery, temporary executors, or verifier triggers; no deployment proof is implied by PR presence or wording.

### Supabase current snapshot
- Project `fiilmooggumokxanwiyx` remains `ACTIVE_HEALTHY` in `eu-west-1`, PostgreSQL `17.6.1.121`, release channel `ga`.
- Public tables observed in the current schema are RLS-enabled. Current production row-count anchors remain: `companies=1`, `branches=2`, `users=24`, `app_settings=1`, `items=17`, `stock_branches=20`, `inventory_log=3`, `stock_vouchers=0`, `orders=0`, `purchase_orders=0`, `journal_entries=2`, `owner_profile=1`, `audit_log=1868`; the remaining operational tables are mostly empty or low-volume.
- Inventory invariants remain verified: `items.item_code` is globally unique; `items.barcode` is not unique; `stock_branches` has generated `available_qty = qty - allocated_qty`; `inventory_log` has `item_id`, `item_code`, `movement_type`, `qty`, `idempotency_key`, `source_branch_id`, and `target_branch_id`, with foreign keys to company/item/branches; `inventory_log.movement_type` rejects `Picking`.
- Branch attribution remains part of the production schema contract: `source_branch_id` and `target_branch_id` are present on `inventory_log`, both have branch foreign keys, and the earlier transactional `InventoryIncrease` verification was rolled back with no permanent test-data mutation.
- Owner continuity remains protected: `users.auth_id` references `auth.users`; `owner_profile` remains present; prior verified owner semantics remain active-owner + wildcard permissions + active license.

### Edge Functions and auth boundary
- The deployed function catalog remains broad and active. Representative business functions remain `verify_jwt=true`, including `save-item v12`, `save-settings v13`, `save-sales-invoice v15`, `create-runsheet v26`, `start-picking v34`, `complete-picking v17`, `start-loading v5`, `complete-loading v11`, `start-delivery v7`, `complete-delivery v4`, `complete-return v25`, `send-stock-voucher v20`, `receive-stock-voucher v22`, `receive-purchase v12`, `save-journal-entry v8`, and `bulk-stock-adjustment v6`.
- A distinct active test/canary/fixture/gate/recovery surface remains `verify_jwt=false`, including `start-picking-production-harness`, `cp-prod-auth-canary-20260814`, `cp-prod-fixture-canary-20260814`, `start-picking-e2e-fixture-20260815`, `start-picking-real-identity-e2e-20260815`, `send-stock-voucher-runtime-e2e-20260818`, `prompt2-complete-picking-http-e2e-20260818`, `complete-picking-runtime-e2e-20260818`, `owner-recovery-20260818`, `owner-recover-gate-20260818-7f2d9c41`, `auth-login-verification-20260818`, `complete-picking-picker-http-gate-20260818`, `receive-purchase-runtime-e2e-20260819`, and `save-sales-production-canary-20260819`.
- This is a confirmed attack-surface and lifecycle-management risk. It is not proof that every such function is exploitable, but each requires explicit retention/authorization justification or retirement.

### Logs, advisories, and unresolved risks
- Fresh `edge-function` logs returned an empty result and fresh `auth` logs returned an empty result at review time. No current incident is proven by those empty queries. Historical references to `owner-recovery-20260818` HTTP 410 traffic remain unresolved historical evidence only.
- Fresh security advisors at `2026-09-05T10:40:08.704Z` still report anonymous and authenticated EXECUTE exposure for SECURITY DEFINER RPCs `public.create_item_with_opening_stock(...)` and `public.sync_company_main_branch_projection()`, plus leaked-password protection disabled.
- Fresh performance advisors at `2026-09-05T10:40:11.362Z` still report many unindexed foreign keys (including both `inventory_log` branch foreign keys), RLS init-plan warnings across many policies/tables, multiple permissive policies on `customer_assignments`, `fulfillment_backorders`, `receiving`, and `receiving_details`, and multiple unused indexes. These are backlog findings, not outage proof.
- No production schema write, Edge Function deployment, credential rotation, or business-data mutation was performed in this run.

## Canonical system model
```text
RAWAEA ERP BUSINESS SYSTEM
    ↓
PWA consumers / shared runtime
    ↓
Edge Functions / RPC contracts
    ↓
PostgreSQL / Supabase SSOT
```

PWA files are consumers/interfaces. Business authority remains in backend/database contracts.

Inventory continuity remains protected:
```text
post_stock_movement = physical stock movement authority
reserve_stock = reservation authority
allocated_qty != physical qty
PWA != stock authority
```

Owner continuity remains protected:
```text
OWNER
=
AUTH OWNER IDENTITY
+
isOwner=true
+
permissions=["*"]
+
VALID owner_profile
+
ACTIVE LICENSE
```

## Runtime / deployment confidence boundary
```text
STATIC SOURCE = CONFIRMED
CURRENT MAIN2 SOURCE PATCH = CONFIRMED IN GIT (2026-09-05)
SUPABASE HEALTH/SCHEMA = CONFIRMED
FRESH AUTH/EDGE LOG RESULTS = EMPTY AT REVIEW TIME
FRESH BROWSER E2E = UNKNOWN
COMMIT-SPECIFIC CI PASS = NOT PROVEN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
FRESH GOLD = NOT PROVEN
FRESH DIAMOND = NOT PROVEN
WHOLE-PROJECT 100% = NOT PROVEN
```

## Open risks / next evidence
1. Prove current deployed runtime revision and browser behavior for Main2 after the 2026-09-05 source rewrite.
2. Close or explicitly justify all active `verify_jwt=false` test/canary/gate/recovery functions.
3. Revoke or harden public EXECUTE on the two SECURITY DEFINER RPCs and enable leaked-password protection.
4. Resolve the unindexed-FK, RLS init-plan, and multiple-permissive-policy backlog, prioritizing movement and tenant-scoping paths.
5. Preserve Patch D as open: import input accepts `item_code` while downstream lookup behavior historically used `items.barcode`; do not change by assumption without historical contract evidence.

## Confidence boundary
- Confirmed: repository/project identity, current `main` continuity docs, latest Main2 source rewrite, Supabase health, RLS-enabled public schema, inventory branch-attribution contract, broad Edge Function deployment surface, fresh empty auth/edge log queries, and fresh security/performance advisory output.
- Not confirmed: browser E2E, exact deployed revision/cache identity, commit-specific CI PASS, full PR/issue closure state, complete lifecycle classification of every `verify_jwt=false` function, Patch D historical import contract, and whole-system Gold/Diamond acceptance.
