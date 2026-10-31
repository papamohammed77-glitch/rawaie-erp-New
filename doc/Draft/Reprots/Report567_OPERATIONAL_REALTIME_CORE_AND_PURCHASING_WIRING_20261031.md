# RAWAEA ERP — Operational Realtime Core and Purchasing Workflow Wiring

**Date:** 2026-10-31  
**Execution mode:** direct commits to `main`; no feature branch and no PR.  
**Operational repository:** `papamohammed77-glitch/erp-frontend`  
**Canonical repository:** `papamohammed77-glitch/rawaie-erp-New`  
**SMART ERP Production:** `fiilmooggumokxanwiyx`

## 1. Verified current state

- Production `supabase_realtime` publication rechecked at **2026-10-31 15:46:00 UTC**: **81 public tables**. The nine required tables are present: `branches`, `customer_ledger`, `customers`, `daily_settlements`, `items`, `purchase_order_details`, `purchase_orders`, `supplier_ledger`, `suppliers`.
- Production migration registry confirms version `20261031153418`, name `enable_realtime_core_master_data_tables_20261031`, with the exact nine-table `ALTER PUBLICATION` statement.
- Added the matching migration file to canonical source: `supabase/migrations/20261031153418_enable_realtime_core_master_data_tables.sql`. This records the already-applied Production change; it is not a second Production execution.
- Operational repository `main` reached commit `5c9da931355b51d960dd757aaa9e25f241362560` during this execution.

## 2. Shared operational core — IMPLEMENTED / STATIC+MOCK VERIFIED

File: `companies/company-1/core.js`  
Blob: `41af5dc9d8a21f2f3fe5d3e9cfc31e8f5fffa90c`  
Commit: `3d952ba1fdbfd8ed7a19792cbd9e7a654f6ed3b2`

- Ported the shared `RW_Realtime` lifecycle manager into the operational core while preserving its existing, stronger `RW_Auth` profile hydration through `get_my_effective_profile`.
- Added a mandatory tenant guard: `RW_Realtime.start` rejects a requested `companyId` unless it exactly matches `RW_Auth.getUser().company_id`. This company ID is supplied by the verified public profile, not user metadata or a page-supplied guess.
- Preserved the manager contract: INSERT/UPDATE only, company filter for company-scoped tables, explicit `companyColumn:false` only for parent-RLS-scoped child tables, debounced minimized invalidation envelopes, reconnect/visibility/periodic reconciliation, and channel cleanup.
- JavaScript parse: PASS. Mock contract: mismatched tenant rejected; matching tenant accepted; `purchase_orders` produced INSERT and UPDATE handlers with `company_id=eq.co-1`; payload was minimized; channel cleanup executed.
- The manager itself is a shared capability, not proof that every app is subscribed.

## 3. Purchasing workflow — THREE APPS WIRED

The Production schema confirms `purchase_orders.company_id` exists. Its authenticated SELECT policy is `company_id = app_private.current_user_company_id()`. Therefore these consumers subscribe only to the tenant-scoped parent table `purchase_orders`; no child-table subscription or RLS relaxation was introduced.

### Receiver
File: `companies/company-1/warehouse/receiver.html`  
Blob: `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`  
Commit: `5bad55f62da262971b0782e7b23e3ff8da5a7b0e`

- Removed a page-level `var supabase = window.supabase` overwrite that replaced the authenticated Supabase client from `core.js` with the SDK namespace.
- Starts a `purchase_orders` subscription after the verified user profile and initial view are ready.
- Re-fetches the active pending or completed purchase-order view after INSERT/UPDATE events.
- Reconciles after reconnect and every 60 seconds; stops the channel on logout.

### Purchasing Buyer
File: `companies/company-1/purchasing/buyer.html`  
Blob: `6ba510cff5250ba196528b14237ae400e544771a`  
Commit: `ec9a81dc2a1157e38823827d8604bfdf5e1ed488`

- Removed the same Supabase client overwrite.
- Subscribes to `purchase_orders` using the authenticated company ID.
- Re-fetches the order list when it is the active view; reconnect/60-second reconciliation and logout cleanup are included.

### Purchasing Supervisor
File: `companies/company-1/purchasing/supervisor.html`  
Blob: `d13e3ff72972641fa300fb956d1f5119e2019743`  
Commit: `838ce197b92f5590a833ad43194c7adbd2327050`

- Removed the same Supabase client overwrite.
- Subscribes to `purchase_orders` using the authenticated company scope.
- Refreshes the active dashboard or order list; reconnect/60-second reconciliation and logout cleanup are included.

**Resulting intended path:** Buyer or supervisor commits a purchase-order change → Production row event → receiver/buyer/supervisor receive an invalidation → each app re-reads through its own authenticated Supabase client and existing RLS. This path is implemented in source but has not yet been proven by authenticated browser E2E.

## 4. Additional confirmed client-overwrite repairs — 13 app pages

A static audit of all 30 operational HTML entry points found 16 core-enabled pages that reassigned the shared `supabase` variable to `window.supabase` (the SDK namespace) immediately after loading `core.js`. This could break database calls that rely on the core-created client. The exact overwrite line was removed, without rewriting app logic, from:

- `companies/company-1/warehouse/manager.html`
- `companies/company-1/warehouse/supervisor.html`
- `companies/company-1/warehouse/unloader.html`
- `companies/company-1/warehouse/counter.html`
- `companies/company-1/delivery/driver.html`
- `companies/company-1/delivery/supervisor.html`
- `companies/company-1/sales/manager.html`
- `companies/company-1/sales/supervisor.html`
- `companies/company-1/office/finance-manager.html`
- `companies/company-1/office/general-manager.html`
- `companies/company-1/office/hr.html`
- `companies/company-1/office/owner.html`
- `companies/company-1/store/track.html`

The other three of the 16 are the receiver, purchasing buyer, and purchasing supervisor documented above. Inline JavaScript parse checks passed for all modified pages. No business logic, data, RLS, ACL, or accounting behavior was changed by these overwrite repairs.

## 5. Security and data boundary

- No Production business rows, stock, ledgers, accounting records, RLS policies, grants, or ACLs were modified in this execution cycle.
- `purchase_orders` has a verified `company_id` column and company-scoped authenticated SELECT policy.
- `purchase_order_details` is parent-scoped through `purchase_orders`; it was deliberately not added to these purchasing subscriptions because the current three-app refresh contract is based on the authoritative parent order list.
- Shared client subscriptions remain INSERT/UPDATE only. DELETE is intentionally excluded; secure authoritative reconciliation remains necessary for deletions.

## 6. What is still NOT CLOSED

1. **No authenticated browser-to-Production E2E yet.** No real user session was used to prove buyer → database → receiver/supervisor refresh, cross-company isolation, permission-denied behavior, reconnect, or duplicate-event handling.
2. **No Cloudflare deployment verification.** No Cloudflare deployment connector or deployment workflow/configuration was found in the operational repository tree. A Git commit is not deployment evidence.
3. **Parent remains unreconciled.** Operational `companies/company-1/main.html` and canonical `Current/PWA/New-main` remain materially different. The operational Parent previously showed 39 Postgres Changes handlers; the canonical Parent showed one. Neither was rewritten or consolidated in this cycle.
4. **Global app coverage remains incomplete.** The shared manager is present in operational `core.js`, and the three purchasing consumers are wired. The remaining operational PWAs have not yet been mapped to verified per-view refresh hooks and subscribed-table RLS contracts. The standalone picker still has its own client/auth path and no shared-core integration.
5. **Canonical/operational core drift remains.** Operational `core.js` uses the stronger effective-profile hydration and now contains the tenant-verified Realtime manager. Canonical `Current/PWA/core.js` still has a different auth implementation and has not been synchronized; do not blindly copy either file over the other.

## 7. Verification record

| Check | Result |
|---|---|
| Production publication count | PASS — 81 |
| Required nine publication tables | PASS |
| Migration registry version/name | PASS — `20261031153418` |
| Canonical migration file recorded | PASS |
| Operational core JavaScript parse | PASS |
| Realtime wrong-company rejection | PASS |
| Realtime correct-company filter | PASS |
| Minimized event envelope | PASS |
| Channel cleanup mock | PASS |
| Modified inline scripts parse | PASS |
| Purchasing three-app source wiring | PASS — static source inspection |
| Authenticated browser E2E | NOT RUN |
| Cloudflare deployment/runtime | UNVERIFIED |
| Parent reconciliation | OPEN |
| Global all-app closure | OPEN |

## 8. Exact continuation point

- Re-fetch operational Git `main` and current SHAs before any further write.
- Continue with read-only workflow mapping for each operational app; do not bulk-add table subscriptions without confirming the app's authenticated company context, SELECT RLS contract, and exact safe refresh function.
- Prioritize the runsheet chain next: picker → loader → supervisor → driver → unloader → returns, preserving each app's in-progress form state and role/branch scope.
- Reconcile Parent source/mirror before changing its existing 39 subscriptions.
- Obtain authenticated browser E2E and Cloudflare deployment evidence before claiming runtime or Production app-to-app synchronization.

**STATUS:** `OPERATIONAL REALTIME CORE IMPLEMENTED / PURCHASING THREE-APP SOURCE WIRING IMPLEMENTED / 16 SUPABASE CLIENT OVERWRITES REMOVED / STATIC+MOCK CHECKS PASS / AUTHENTICATED E2E AND DEPLOYMENT UNVERIFIED / GLOBAL ERP INTEGRATION NOT CLOSED`
