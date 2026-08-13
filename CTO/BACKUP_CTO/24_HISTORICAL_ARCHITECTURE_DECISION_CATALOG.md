# 24 — HISTORICAL ARCHITECTURE DECISION CATALOG

## Status
Historical decision forensics. Current Governance wins when conflict exists.

## Core historical ADRs recovered

### ADR-001 — Supabase as BaaS
**Decision:** Supabase/PostgreSQL/Auth/Edge Functions/Storage.
**Reason:** relational ERP data, RLS, integrated auth, low operational overhead.
**Rejected:** Firebase, custom Node/Express, AWS RDS+Lambda.
**Consequence:** fast delivery and relational integrity, with platform dependency.
**Status:** HISTORICAL DECISION; current stack remains aligned.

### ADR-002 — Vanilla JavaScript / ES5 foundation
**Decision:** lightweight HTML/JS PWA architecture for old field devices.
**Rejected:** React/Vue/Angular, full TypeScript, ES6-only implementation.
**Reason:** compatibility and no build-step dependency.
**Important:** later constitutional versions relaxed some syntax restrictions; historical claims must not override current Constitution.

### ADR-003 — PWA + Offline First
**Decision:** PWA instead of separate native applications.
**Reason:** field connectivity and single codebase.
**Dependency:** Service Worker + Dexie/IndexedDB.

### ADR-004 — Dexie.js
**Decision:** IndexedDB wrapper and local pending operations.
**Reason:** offline capacity and simpler local data access.

### ADR-005 — Source of Truth + Projection
**Decision:** `order_details` as the historical source for six operational quantities; `run_sheet_details` is a projection rebuilt by `sync-run-sheet-details`.
**Risk later discovered:** projection synchronization is manually invoked rather than a database trigger.

### ADR-006 — Six quantities
Historical `order_details` tracks:
- qty_ordered
- qty_picked
- qty_loaded
- qty_delivered
- qty_refused
- qty_returned

This is the core field-distribution model.

### ADR-007 — sync-run-sheet-details
**Decision:** central aggregation/projection function.
**Known consequence:** a missed call can leave `run_sheet_details` stale.

### ADR-008 — core.js
**Decision:** shared infrastructure layer for Auth, DB, API, UI, image cache and service worker.
**Historical limitation:** not all original applications adopted it.

### ADR-009 — manual fetch instead of `supabase.functions.invoke`
Historical Constitution explicitly preferred controlled manual fetch calls.
Current Production status must be verified independently.

### ADR-010 — no hard delete
Historical architectural intent: preserve financial/audit history through soft delete/reversal patterns.
Historical API catalog nevertheless contains `delete-*` functions, creating a documented tension that must not be silently resolved.

### ADR-011 — Edge Functions as business service layer
Business operations were placed in Deno/TypeScript Edge Functions rather than a conventional application server.

### ADR-012 — Cloudflare Pages
Static PWA hosting/CDN.

### ADR-013 — cache strategy
Historical design used `_headers` + Service Worker. Historical issues document earlier unsafe cache behavior and later fixes.

### ADR-014 — active_warehouse_role
Warehouse users can have an active operational role independent of their general permissions.

### ADR-015 — SweetAlert2
Human-friendly field UI and modal/notification conventions.

### ADR-016 — separate PWA applications
Role-oriented apps were intentionally separated rather than consolidating all workflows into one SPA.

## Historical rejected patterns
The records repeatedly reject:
- UI-owned core business mutations
- hard deletion of financial history
- blindly modernizing all clients without considering legacy devices
- treating projection tables as primary truth
- replacing original behavior without parity analysis

## Decision forensic rule
A historical ADR is not automatically a current requirement. It becomes current only if preserved by the active Constitution, owner decision, current implementation, or Production evidence.
