# RAWAEA ERP — GLOBAL REALTIME INTEGRATION / FIRST PRODUCTION EXECUTION

**Date:** 2026-10-31
**Execution:** direct `main` source commit + direct SMART ERP Production migration; no new branch and no PR.
**Production project:** `fiilmooggumokxanwiyx`

## Executive result
- Production Realtime publication was expanded from 72 to 81 public tables. The nine previously missing operational/master-data tables are now present.
- Canonical shared PWA core `Current/PWA/core.js` was updated directly on `main` with a shared `RW_Realtime` manager and a transactional/safe `RW_DB.syncDown`.
- The new core passed JavaScript parse validation and a mock contract test for company filtering, child-table RLS scoping, INSERT/UPDATE-only subscriptions, payload minimization, and channel cleanup.
- This is a first integration foundation, NOT global realtime closure. The operational applications and Parent have not yet all been wired to the new manager, and the canonical-to-published mirror is not currently byte-identical.

## 1. Production change — CONFIRMED
Migration name: `enable_realtime_core_master_data_tables_20261031`
Migration registry: recorded successfully.
Before: 72 tables in `supabase_realtime`.
After: 81 tables in `supabase_realtime`.
Added exactly:
- `branches`
- `customer_ledger`
- `customers`
- `daily_settlements`
- `items`
- `purchase_order_details`
- `purchase_orders`
- `supplier_ledger`
- `suppliers`
Post-migration verification at `2026-10-31T15:34:23.244838Z` returned `required_missing=[]`, all nine present, and migration record present.

### Security gate checked before adding tables
- PostgreSQL version: 17.6.
- All nine tables had RLS enabled, a primary key, and at least one SELECT policy before the publication change.
- Six tables carry `company_id`; their policies scope reads to the active company (with additional permission/role rules where applicable).
- Three child tables have no `company_id`: `customer_ledger`, `purchase_order_details`, `supplier_ledger`; their SELECT policies scope through `customers`, `purchase_orders`, and `suppliers` respectively.
- No RLS policy, GRANT, ACL, row, stock, ledger, or accounting data was changed.
- Existing publication is configured to publish INSERT/UPDATE/DELETE/TRUNCATE. The shared client manager deliberately subscribes only to INSERT and UPDATE. DELETE subscriptions are excluded because Supabase Postgres Changes does not RLS-filter DELETE events equivalently; deletions must be reconciled by authoritative re-fetch/polling or a separately secured Broadcast contract.

## 2. Canonical shared core — CONFIRMED
Repository: `papamohammed77-glitch/rawaie-erp-New`, branch `main`.
File: `Current/PWA/core.js`.
Commit: `c26a8326fee55a297331d1f636f86e160131679f`.
Blob: `685be76e4a61ef68de3182855f5e33ea04e9a435`.

### `RW_DB.syncDown` correction
- Fetches `customers`, `items`, `stock_branches`, and `branches` before mutating IndexedDB.
- Validates every Supabase result and requires array data.
- Replaces the four local tables in one Dexie read/write transaction.
- A failed query or invalid response leaves the previous local cache intact.

### New `RW_Realtime` shared API
- `RW_Realtime.start(config)` creates one managed channel per app/company.
- Each table is subscribed to INSERT and UPDATE only.
- Tables with `company_id` use a server-side `company_id=eq.<companyId>` filter.
- Child tables without `company_id` must be explicitly declared with `companyColumn:false`; authorization remains enforced by their existing RLS parent-relationship SELECT policies.
- Callbacks receive only a minimized invalidation envelope (table/event/timestamp/appId), not the raw row payload. Consumers must re-fetch authoritative data through Supabase/RLS.
- Events are debounced; hidden-tab events are reconciled on visibility return.
- Optional `onReconcile` runs after reconnection and at a configurable periodic interval.
- `stop`, `stopAll`, and `getStatus` manage lifecycle and cleanup.
- Auth token refresh is forwarded to the Realtime client; sign-out stops active channels.
- No DELETE event subscriptions are created.

### Verification
- `new Function(coreSource)` JavaScript parse: PASS.
- Mock test: PASS — expected four INSERT/UPDATE handlers for two tables; company filter applied to company-scoped table; no filter applied to parent-scoped child table; DELETE absent; event payload minimized; channel cleanup executed.
- This is static/mock verification, not authenticated browser-to-Production E2E.

## 3. Current integration reality — NOT CLOSED
### Operational Parent mirror
Operational repository `papamohammed77-glitch/erp-frontend`, `main`:
- `companies/company-1/main.html` blob `53b5a9e9d0433a785c3d5471a9c0d68c25497882`, 1,892,593 bytes in tree metadata (1,800,879 decoded characters through blob fetch).
- Static scan found 39 `postgres_changes` handlers across 11 channel constructions.
- The Parent does not load `core.js`.
- Existing subscriptions are page/module-specific; some subscribe to `event:'*'`, and some child-table subscriptions have no explicit company filter. Their callbacks and current RLS behavior need per-module review before consolidation.

### Canonical Parent source mismatch
`Current/PWA/New-main` in the canonical source repo has blob `22f4ee1a666141be62127159337beffb05e8b146` and 549,949 bytes. It contains one Realtime subscription (orders) and does not load `core.js`.
The operational `erp-frontend/companies/company-1/main.html` is materially larger and has 39 event handlers. The two files are not byte-identical (different blob SHA and size). This is a confirmed source/mirror drift that must be reconciled before copying or patching Parent code. No Parent HTML was changed.

### Standalone apps
Canonical sample inspection confirms that `picker.html` has no `core.js` reference and no Realtime subscription; `New-main` also does not load `core.js`. `loader.html`, `receiver.html`, `Returns.html`, `driver.html`, `pos.html`, and `vouchers.html` load the core, but the inspected pages have no `RW_Realtime` integration calls yet. `vouchers.html` retains its own page-specific Realtime channel.
Therefore the new manager is available in canonical core but is not yet active in all apps. Each app needs a table/consumer contract and a safe refresh callback; a blind page reload is explicitly not an acceptable substitute.

### Published operational mirror drift
At the time of inspection, `erp-frontend/companies/company-1/core.js` was blob `3cf992d8179a374b60622faba9e60dde43c9a21e` (28,837 bytes), did not contain `RW_Realtime`, and still had the old destructive `syncDown` ordering. The operational `warehouse/receiver.html` also still contained `var supabase = window.supabase;` after loading core. These are not silently overwritten: the governing source-to-publish rule requires canonical-source review and owner-controlled mirror transfer. No operational app HTML or mirror file was edited in this execution.

## 4. Critical security and performance observations
- Supabase security advisors returned 24 RLS-enabled/no-policy findings on other tables, three SECURITY DEFINER views, mutable search_path warnings, and many SECURITY DEFINER execute grants. These are pre-existing broad security findings, not caused by this Realtime migration. They must be assessed separately; no security grants or policies were changed.
- Multiple permissive SELECT policies exist on `branches`, `customers`, `items`, `orders`, `order_details`, `runsheets`, `run_sheet_details`, and other tables. This is existing policy composition. The Realtime manager relies on these current policies and does not weaken them.
- The current global publication has DELETE enabled; all new manager subscriptions intentionally omit DELETE.

## 5. Remaining closure sequence
1. Reconcile canonical `Current/PWA/New-main` against operational `erp-frontend/companies/company-1/main.html` using commit history and semantic module inventory; do not overwrite either side.
2. Build the exact table → writer → consumer → Parent-tab matrix for every operational app.
3. Prepare owner-applied surgical HTML patches for `picker`, `New-main`/Parent, and every core-enabled standalone app. Each patch must register its actual tables and refresh only the relevant visible module; no full-page reload.
4. Review and migrate existing Parent/vouchers/sales-manager Realtime handlers to the shared manager only after preserving all module callbacks, filters, modal guards, and lifecycle semantics.
5. Add authenticated browser E2E: operation in App A → Production row commit → event observed in App B and Parent tab → authoritative re-fetch shows the same state; test two companies, permission-denied users, reconnect, hidden-tab return, duplicate events, and DELETE reconciliation.
6. Confirm Cloudflare served artifact SHA/headers and verify that canonical core + owner-applied mirror patches are actually deployed.
7. Add the repository migration source file through the project's established Supabase CLI migration workflow; the Production migration registry is recorded, but a matching repository migration file was not generated in this run.

## Mutation ledger
- Production: one additive Realtime publication migration only; nine tables added; no business data or security policy changes.
- Git: one direct commit to canonical `rawaie-erp-New/main`, `Current/PWA/core.js`.
- No branch or PR created in this execution.
- No operational app HTML, Parent HTML, `erp-frontend` mirror, or Cloudflare deployment changed.

## Final status
`PRODUCTION PUBLICATION EXPANDED / CANONICAL SHARED REALTIME MANAGER COMMITTED / CACHE SYNC SAFEGUARD COMMITTED / STATIC + MOCK TESTS PASS / APP INTEGRATION OPEN / PARENT SOURCE-MIRROR DRIFT OPEN / CLOUDflare DEPLOYMENT UNVERIFIED / AUTHENTICATED E2E OPEN / GLOBAL REALTIME = NOT CLOSED`