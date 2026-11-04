# Report612 — RAWAEA Core Centralization Forensic Application Matrix

**LVE:** LVE-2026-11-04-612  
**Date:** 2026-11-04  
**Operational repository:** papamohammed77-glitch/erp-frontend / main  
**Operational HEAD:** 68d222b20251049daddc2f159f2b8c80cd6ffb89  
**Scope:** All 30 HTML files under companies/company-1, Core implementation, shared worker registration, direct Auth/API/DB/RPC/Realtime use, and offline storage patterns.  
**Method:** Read-only static source inventory. No code, database, deployment, or production data changes.

---

## Executive conclusion

A full inventory of all 30 HTML files under companies/company-1 confirms:

- 26 files load companies/company-1/core.js.
- Three operational entry/application surfaces do not load Core: main.html, warehouse/picker.html, and app.html.
- index.html is a static navigation/landing page and is intentionally excluded from business-app Core adoption.
- Loading Core does not establish full centralization. Many Core-loaded pages still call Supabase table queries directly, call RPCs directly, open their own Realtime channels, use direct Auth methods, or issue raw fetch requests to Edge Functions.
- No claim is made that any single application is fully centralized across every layer. Buyer is the closest current example: it uses RW_Auth, RW_API, RW_UI and RW_Realtime, and the current Buyer source contains no direct supabase.from/RPC/channel/fetch calls.

**Architecture status: PARTIALLY CENTRALIZED / MIXED IMPLEMENTATIONS / NOT YET A SINGLE CONSISTENT CORE CONTRACT.**

The intended target is not one giant application. Parent and operational PWAs should remain separate application experiences, while using one versioned shared implementation for client initialization, identity/context, data access, Edge/RPC calls, realtime, offline queues, service-worker lifecycle, observability and standard UI behavior.

## 1. Source baseline and evidence integrity

- Operational repository: papamohammed77-glitch/erp-frontend.
- Branch: main.
- HEAD: 68d222b20251049daddc2f159f2b8c80cd6ffb89.
- Core blob: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.
- Parent main.html blob: 53b5a9e9d0433a785c3d5471a9c0d68c25497882.
- Buyer blob: 311f2673a90149df6f56d59a9a187a3379e6981c.
- Picker blob: d483bd15b36585b975b63c2ef641481a01d5d084.
- app.html blob: 2e47a68fe83956e27d569e786a08dcee91af2924.
- The 30-file count and application families are consistent with the earlier Report595 architecture map, but this report re-fetched the current operational files at HEAD 68d222b rather than inheriting the older source snapshot.

A static reference/call count indicates code locations in the source; it is not a count of runtime requests or proof that every code path is exercised. Runtime/E2E behavior was not tested in this read-only inventory.

## 2. Exact application inventory

Legend:
- CORE: Core script is loaded.
- HYBRID: Core is loaded, but one or more critical integration layers bypass its shared services.
- NON-CORE: Independent client/auth/API/realtime implementation; not loading Core.
- PUBLIC: Public/customer route; it must use the shared public-data/API contract without being forced through employee authentication.
- EXEMPT: Static navigation/landing page, not a business application.

| Domain | Application / file | Core state | Source-level integration evidence and remaining gap |
|---|---|---|---|
| Parent | main.html | NON-CORE | Own Supabase client and large independent Auth/data/RPC/Edge/Realtime implementation. Static scan: 178 supabase.from call sites, 75 supabase.auth references, 61 direct Supabase RPC references, 68 functions/v1 references, 11 channel declarations and 39 postgres_changes references. Parent contains its own RW_* namespaces, but they are not the shared core.js modules. |
| Employee entry | app.html | NON-CORE | Creates its own Supabase client and implements login, password recovery, session handling and role-based routing directly. Must share the same authenticated profile and route authorization contract as Core. |
| Warehouse | picker.html | NON-CORE | Creates its own Supabase client; has its own direct Auth flow, four raw Edge fetch call sites, Dexie storage and service-worker registration. This is an operational PWA and is the highest-priority independent warehouse application to bring onto the Core contract after the compatibility layer is ready. |
| Delivery | driver.html | HYBRID / HIGH RISK | Loads Core but still uses direct supabase.auth calls and derives authorization from user_metadata; has 27 direct table-query call sites, direct inserts/updates, four raw Edge fetches, and localStorage/Dexie offline logic. Direct DML includes a fallback users insert, credit_block_events insert, service_complaints insert/update and driver_liabilities update. |
| Delivery | supervisor.html | HYBRID | Loads Core and uses RW_Auth/RW_UI, but has nine direct Supabase RPC call sites rather than a shared Core RPC wrapper; it does not use RW_API or RW_Realtime in the scanned page. |
| Office | accountant.html | HYBRID | Loads Core, uses Auth/UI and RW_API, but has nine direct table-query call sites, 19 direct RPC call sites and a direct Auth method. Direct RPC may still be a centralized database writer; the gap is the missing common client-side invocation contract and consistent instrumentation. |
| Office | finance-manager.html | HYBRID / READ-HEAVY | Loads Core and uses Auth/UI, but reads orders, purchase_orders and treasury directly through Supabase. |
| Office | general-manager.html | HYBRID / READ-HEAVY | Loads Core and uses Auth/UI, but reads orders, purchase_orders, treasury, customers and users directly. |
| Office | hr.html | HYBRID / READ-HEAVY | Loads Core and uses Auth/UI, but reads users directly through Supabase. |
| Office | owner.html | HYBRID / READ-HEAVY | Loads Core and uses Auth/UI, but reads orders, stock_branches, users, customers, runsheets, app_settings and audit_log directly; one direct Auth method remains. |
| Purchasing | buyer.html | CORE-ALIGNED / CLOSEST CURRENT EXAMPLE | Uses RW_Auth, RW_API, RW_UI and RW_Realtime. The current file has no direct supabase.from/RPC/channel/fetch references. It still has application-specific data caching and a 500-row GET_DATA limit, and its business/runtime defects remain separately tracked in LVE611. |
| Purchasing | supervisor.html | HYBRID | Loads Core and uses Auth/UI/Realtime, but reads purchase_orders and suppliers directly through Supabase. |
| Sales | manager.html | HYBRID / REALTIME BYPASS | Loads Core and uses Auth/UI, but has seven direct table-query call sites, a separately created Supabase Realtime channel, direct Auth access and a raw fetch wrapper for sales-target-dashboard and sales-target-engine. |
| Sales | order-taker.html | HYBRID | Loads Core and uses Auth/API/DB, but has 20 direct table-query call sites and a direct Auth method; it also owns localStorage/network handling. Writes are partly routed through RW_API endpoints. |
| Sales | pos.html | HYBRID | Loads Core and uses Auth/API/DB, but still invokes six RPCs directly and has direct Auth calls. It maintains a dedicated Dexie pending_updates queue and localStorage state. Local Dexie updates must not be confused with Supabase table DML. |
| Sales | supervisor.html | HYBRID / READ-HEAVY | Loads Core and uses Auth/UI, but reads orders and users directly; no Core API or Realtime path was found in the scanned file. |
| Sales | telesales.html | HYBRID | Loads Core and uses Auth/API/DB, but has 20 direct table-query call sites and a direct Auth method; it also owns localStorage/network handling. |
| Sales | van-sales.html | HYBRID | Loads Core and uses Auth/API/DB, but has 23 direct table-query call sites, two direct RPC call sites, one direct Auth method and localStorage/offline state. |
| Store | index.html | PUBLIC / HYBRID | Loads Core but uses a direct coupons read, a direct RPC, and a raw fetch to submit-online-order. It must use a centralized public API path without requiring an employee session. |
| Store | track.html | PUBLIC / CORE NOT CONSUMED | Loads Core but does not use RW_Auth/RW_API/RW_DB/RW_UI/RW_Realtime in the scanned file; it calls a Supabase RPC directly. Preserve anonymous/token-based tracking semantics while adopting the shared public API wrapper. |
| Warehouse | counter.html | HYBRID | Loads Core and uses Auth/API/UI, but reads items and inventory_counts directly. |
| Warehouse | data.html | HYBRID | Loads Core and uses Auth, but reads items/categories/branches/stock_branches/inventory_log directly and has a raw Edge fetch rather than RW_API. |
| Warehouse | loader.html | HYBRID / STRONG CORE USE | Uses Auth/API/Realtime and several Edge operations through RW_API, but retains eight direct table-query call sites and application-specific Dexie usage. |
| Warehouse | manager.html | HYBRID | Uses Auth/UI/Realtime, but has 12 direct table-query call sites for users, stock_branches, items, runsheets, stock_vouchers and purchase_orders. |
| Warehouse | receiver.html | HYBRID / STRONG CORE USE | Uses Auth/API/Realtime and routes its receive write through RW_API, but retains direct PO/detail reads. Its PO/detail and quantity-contract defects remain separately recorded in LVE611. |
| Warehouse | returns.html | HYBRID / WRITE-BOUNDARY REVIEW REQUIRED | Uses Auth/API, but has 14 direct table-query call sites and directly updates run_sheet_details.qty_returned. The direct update must be reconciled with the existing return Edge writer to preserve one authoritative writer and avoid conflicting state transitions. |
| Warehouse | supervisor.html | HYBRID | Uses Auth/UI/Realtime, but has 13 direct reads and two direct RPC call sites. |
| Warehouse | unloader.html | HYBRID | Uses Auth/API, but has five direct table-query call sites and application-specific operational state. |
| Warehouse | vouchers.html | HYBRID / REALTIME AND AUTH BYPASS | Uses Auth/API, but retains six direct Auth references, its own Supabase channel and postgres_changes handlers, a direct users read and five direct RPC call sites. Its channel lifecycle should be managed by RW_Realtime. |
| Root | index.html | EXEMPT | Static landing/navigation page linking to app.html and main.html. It has no business data, Auth, Edge, RPC or Realtime code; no Core integration is required. |

## 3. What the shared Core actually provides today

Current core.js exposes these units:

1. RW_Auth — session, effective-profile hydration, permission checks and active warehouse-role checks.
2. RW_DB — primarily a local Dexie wrapper. Its exposed functions are getDB, syncDown, syncUp, getItems, getCustomers and getBranches.
3. RW_API — Edge invocation wrapper with call and callWithRetry.
4. RW_UI — common interaction, formatting, loader, error and toast helpers.
5. RW_ImageCache — shared image/cache helpers.
6. RW_SW — Service Worker update/registration helpers.
7. RW_Realtime — shared channel lifecycle, verified company-context guard, status/reconciliation and cleanup.

### 3.1 The main architectural gap: RW_DB is not a server-data repository

RW_DB currently manages local Dexie databases, a common local schema and limited sync operations. syncDown fetches customers, items, stock_branches and branches. syncUp sends pending local operations through manual fetch.

It does not currently expose a comprehensive server-side repository/query contract for all ERP domains. It does not replace direct supabase.from calls throughout the operational apps. That is why a page can load Core and still issue its own server queries.

### 3.2 RW_API is Edge-only, not a complete API/RPC gateway

RW_API currently exposes call and callWithRetry for Edge Functions. It does not provide a shared RPC method, a typed operation contract, automatic operation identity/idempotency handling, or a unified correlation/error/telemetry contract. Applications therefore call supabase.rpc directly or use raw fetch.

A direct RPC is not automatically a business-writer violation: the SQL RPC can still be the approved atomic writer. The missing part is the common, consistent invocation layer and its telemetry/retry/idempotency behavior.

### 3.3 Realtime is only partially adopted

RW_Realtime is used by Buyer, Purchasing Supervisor, Loader, Warehouse Manager, Receiver and Warehouse Supervisor. Parent main.html, Sales Manager and Warehouse Vouchers create independent channels.

The Core's default event selection is INSERT/UPDATE. DELETE-dependent screens must explicitly define and test deletion/reconciliation behavior rather than assuming the shared default covers every event.

### 3.4 Offline state remains application-specific

Current apps mix:
- RW_DB/Dexie local data,
- application-specific Dexie schemas,
- localStorage-based pending state,
- raw fetch retry behavior,
- service-worker registration/update logic.

The target is a common offline/outbox contract, not one forced Dexie schema for every app. Existing app-specific local stores may remain as adapters while identity, operation IDs, queue/retry/conflict policy, status and cleanup are unified.

## 4. Critical architecture risks

### P1 — Driver identity and write boundary

Driver loads Core but its authorization code reads Auth user_metadata and derives isOwner/role/permissions from it. The same code contains direct table inserts/updates and creates a fallback public users row from the operational client.

Supabase explicitly warns that user_metadata is user-editable and should not be used for authorization. Use the authoritative effective-profile/permission contract; do not base application authorization on user_metadata. This source finding does not, by itself, prove that a production exploit occurred; the effective RLS/GRANTS and live execution paths must be reconciled before a vulnerability conclusion.

Driver's direct DML must be mapped to existing approved RPC/Edge writers. Do not add another writer or permit an operational Driver PWA to create the Parent employee/user master.

### P1 — Returns write-boundary

returns.html directly updates run_sheet_details.qty_returned while also using existing return Edge operations. Verify the exact operation ordering and database policies, and retain one authoritative writer for the return event. Do not assume the direct update is harmless or delete it before mapping its business purpose.

### P1/P2 — Parent and app bootstrap split

main.html and app.html each initialize their own Supabase client/auth paths rather than using the Core bootstrap. Parent also has a large independent internal module system and many existing compatibility contracts.

Do not solve this by blindly adding a core.js script tag. The current Core creates a Supabase client under the global supabase name. Parent/app/picker already create or use a client in their own page. A direct script insertion risks duplicate client initialization/global-name collision and breaks assumptions in the existing page. First introduce an explicit bootstrap/adapter that can accept or construct exactly one page-local client and preserve legacy globals until each domain module is migrated.

### P2 — Read/data access inconsistency

Direct supabase.from references across Core-loaded apps lead to inconsistent pagination, tenant/branch scoping, error handling, field selection, caching and observability. Direct reads can remain browser-side and RLS-protected; centralization does not require a new Edge Function for every SELECT. They should use an approved shared query/repository layer with explicit domain scope and pagination.

### P2 — Realtime duplication

Parent, Sales Manager and Warehouse Vouchers bypass RW_Realtime. There is no consistent channel status, event policy, cleanup, reconnect/reconciliation behavior across these paths.

### P2 — Public Store paths

Storefront and tracking are not employee PWA modules. They must not be forced through employee Auth. They need a shared public API interface with token validation, abuse protection, narrow response contracts and no privileged service-role client exposure.

## 5. Target centralized architecture

Keep the parent ERP and each independent PWA as separate app experiences. Centralize the infrastructure and business contracts underneath them.

Recommended shared Core boundaries:

| Shared unit | Responsibility | Required final contract |
|---|---|---|
| RW_Core / bootstrap | Version and initialize one page-local Supabase client and all shared modules | Explicit init/config; reuse injected client when present; no duplicate initialization; backward-compatible global aliases during migration |
| RW_Auth | Login/session/refresh/logout and authoritative profile | get_my_effective_profile, active user, status, permissions, active warehouse role, no user_metadata-based authorization |
| RW_Context | Company, branch, warehouse, active role and app identity | Verified context only; no company/branch trust from unverified UI input |
| RW_API | Existing Edge Functions and public API operations | Central call + safe retry + operation_id/idempotency + correlation IDs + normalized errors; no raw fetch in app modules |
| RW_RPC | Existing approved PostgreSQL RPCs | Common typed call/error/telemetry wrapper; preserve database atomic writers and grants |
| RW_Data / repository | Server-side reads through the existing Supabase client | Domain query methods, explicit tenant/branch scope, pagination, selective fields, consistent errors/cache; preserve RLS |
| RW_Realtime | All shared channels | Verified company scope, app/channel identity, INSERT/UPDATE/DELETE policy, status, cleanup, reconnect and reconciliation |
| RW_Offline | Shared offline data/outbox policy | Stable operation IDs, retry state, conflict policy, actor/company/branch context, audit and cleanup; adapters for current Dexie stores |
| RW_SW | Service Worker lifecycle | One registration/update owner, stable version, explicit static cache policy, no stale business/API data caching |
| RW_UI | User feedback and loading/error behavior | Consistent accessible UI primitives without moving domain logic into Core |
| RW_Observability | Client-side operation diagnostics | appId, operation, request/operation ID, actor/context, latency, result/error, no credentials or sensitive data in logs |

Important separation:
- Core is infrastructure, not a second ERP business engine.
- Parent and operational PWAs retain domain UI and workflows.
- Edge Functions/RPCs remain the authorized business command boundary.
- Browser direct table DML for authoritative business changes is not the target architecture.
- Reads need not all become Edge Functions; use a shared query layer and preserve RLS.
- No new Edge Functions should be created merely to centralize syntax; reuse the existing API/RPC contracts whenever possible.

## 6. Execution sequence

### Stage 0 — Contract freeze and dependency map (read-only)

For each application, map:
- entry file and loaded scripts,
- Auth/session and effective-profile source,
- read tables and query scopes,
- RPC/Edge write endpoints,
- direct DML,
- Realtime tables/events,
- offline storage and retry logic,
- parent navigation/route and permissions.

Produce a consumer-to-Edge/RPC/table/permission dependency matrix before changing shared signatures.

### Stage 1 — Safe Core compatibility foundation

- Define the Core bootstrap/factory and client injection behavior.
- Preserve ES5-compatible global contracts required by existing apps.
- Add missing shared RPC invocation and server-read repository interfaces.
- Add shared operation/correlation identity and safe retry semantics.
- Formalize branch/company context.
- Expand Realtime event policy and tests.
- Do not migrate the Parent or all apps in one operation.

### Stage 2 — Consolidate independent entry points

1. app.html: shared Auth/profile/route authorization.
2. warehouse/picker.html: shared Auth/API/Realtime/Offline/SW adapters, preserving the current picking workflow and Dexie data shape.
3. main.html: compatibility bridge first, then domain-by-domain migration. Do not rewrite the 1.8-million-character Parent source or its 46 internal namespaces broadly.

### Stage 3 — Close highest-risk hybrid apps

1. Driver: authoritative effective profile, no user-master creation from Driver, route direct writes through existing approved commands, and remove raw Edge fetches.
2. Returns: resolve direct run_sheet_details update against the return single-writer contract.
3. Vouchers: move its independent channel and Auth invocations into Core.
4. Sales Manager: use RW_Realtime and RW_API rather than its private channel/fetch wrapper.
5. POS / Van Sales / Order Taker / Telesales: migrate reads and RPC invocation to common wrappers incrementally; preserve offline operation semantics.

### Stage 4 — Standardize read-only and oversight applications

Move Accountant, Finance Manager, General Manager, HR, Owner, Sales Supervisor, Purchasing Supervisor, Warehouse Manager/Supervisor, Counter, Data Entry, Unloader and other dashboard reads to RW_Data, without changing their domain-specific permission scopes.

### Stage 5 — Public Store adapters

Use shared public API and tracking-token modules while preserving public access semantics. Do not require employee Auth on customer storefront/tracking.

### Stage 6 — Offline, Service Worker and end-to-end closure

Unify outbox/retry/update contracts, while preserving app-specific local storage adapters. Run per-app and cross-app tests for Auth, tenant/branch, permissions, RLS, direct DML denial, API/RPC idempotency, Realtime reconnect/delete/reconcile, offline replay, SW upgrade and complete business workflows.

## 7. Acceptance criteria for declaring centralization complete

Centralization is not complete merely because every HTML file contains a core.js script tag.

Each business PWA must demonstrate:

1. Exactly one Core-managed page-local Supabase client and one authoritative Auth/session/profile path.
2. Company/branch/active-role context derived from a verified profile.
3. No app-local authorization based on user_metadata.
4. All authoritative writes routed through an existing approved Edge/RPC single-writer contract.
5. All RPC/Edge invocations use shared wrappers and explicit idempotency identity where the operation is retryable.
6. All server reads use an approved shared data/query layer, with tenant/branch scope, RLS, pagination and consistent error handling.
7. All Realtime subscriptions are Core-managed and pass event, filter, reconnect, cleanup and reconciliation tests.
8. Offline queues preserve the same actor/company/branch and operation identity after restart/retry.
9. One service-worker update/cache contract; no stale business API responses.
10. Parent/PWA navigation, permissions, stock, treasury, supplier/customer balances and journal effects pass regression tests.
11. Authenticated browser E2E and canonical deployed artifact parity are proven for each application.

## 8. What was and was not done

**Completed:**
- Enumerated all 30 current HTML files at operational HEAD 68d222b.
- Read Core implementation and the relevant application entry files.
- Classified Core loading, Auth/API/DB/Realtime usage and direct bypass patterns.
- Identified direct write-boundary review points in Driver and Returns.
- Defined a phased centralization architecture and acceptance gate.

**Not done:**
- No operational app/Core source changes.
- No Supabase schema/RPC/RLS/GRANT/Edge changes.
- No production data writes.
- No Cloudflare deployment.
- No creation of an Edge Function or migration.
- No authenticated Browser E2E or runtime performance test.

## 9. Final CTO determination

**Current status:** PARTIALLY CENTRALIZED / MIGRATION PLAN DEFINED / EXECUTION NOT STARTED.

**First priority:** Design and present the exact Core bootstrap/API/RPC/data contract and compatibility bridge before migrating Parent, Picker or app.html. Then close Driver/Returns write-boundary risks and migrate the remaining hybrid apps by domain.

Do not perform a mass find-and-replace, do not convert all applications into one HTML application, do not duplicate business writers, and do not add new Edge Functions as a substitute for a shared client-side contract.

Any source, RPC, permission, production or deployment change remains subject to Master CTO Governance §77.2 and requires explicit owner approval of the exact proposed change.
