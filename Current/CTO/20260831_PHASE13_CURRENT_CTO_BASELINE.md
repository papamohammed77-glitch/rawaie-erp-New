# RAWAEA ERP — PHASE 13 CURRENT CTO BASELINE

**Date:** 2026-08-31  
**Phase:** 13 — First Principles Rebaseline  
**Status:** CLOSED  
**Current Git HEAD:** `18468847d0247a9524e4f3ba38a07899733ec998`  
**Production:** Supabase `fiilmooggumokxanwiyx` / `SMART ERP`

## CONFIRMED FACTS

### Current Production

- Production environment is `SMART ERP` / `fiilmooggumokxanwiyx`, ACTIVE_HEALTHY, eu-west-1, PostgreSQL 17.
- Fresh Phase 2 structural snapshot: 66 public base tables, 76 public functions, 20 non-internal public triggers, 110 public policies, 173 public indexes, 488 public constraints, 198 migrations, latest migration `20260830082911`.
- Fresh business snapshot: 1 company, 24 users, 2 branches, 17 items, 3 customers, 1 supplier, 0 vehicles, 0 orders, 20 stock rows, 3 inventory-log rows, 2 cancelled void journal headers, and zero current subledger rows.

### Current inventory engine

- `post_stock_movement` exists in two overloads.
- The idempotent overload validates movement types, company/branch relationships, locks stock rows, enforces quantity/reservation constraints, updates physical stock, and inserts `inventory_log`.
- `reserve_stock` and `release_stock_reservation` are separate reservation capabilities.
- Current stock invariants tested in Production are clean: no negative stock, no allocated>qty, no available mismatch, no duplicate branch/item rows, no cross-company stock-parent mismatch.

### Current accounting engine

- `post_journal_entry` enforces balanced entries, account/company ownership, operation idempotency, and audit logging.
- `post_customer_ledger_entry`, `post_supplier_ledger_entry`, and the driver/cash writers exist as current database-side capabilities.
- `receive_purchase_atomic` posts supplier ledger, closing the historical supplier-ledger gap documented in the July baseline.

### Current security

- Critical inspected business tables have RLS enabled.
- Tenant-context functions exist in `app_private` and resolve company/permission from authenticated identity.
- Critical writer RPCs are not exposed to anon/authenticated EXECUTE in the inspected grant snapshot.

### Current deployment

- Critical Edge Functions exist in Production with separately observable versions and SHA-256 deployment artifacts.
- Current Git source for the four examined critical wrappers matches their retrieved Production source at wrapper level.
- Git→Production cryptographic lineage is not fully proven for every artifact.

### Current candidate target

- `Current/PWA/New-main` is a clean-room reconstruction candidate with explicit tenant context and delegation semantics.
- It has not been certified as a replacement for `Current/PWA/main.html`.
- Golden New-main verification PR #61 is open, unmerged and non-mergeable, and its stated purpose is verification without replacing `main.html`. fileciteturn55file0L2-L15

## UNKNOWNs

1. Exact active consumers and runtime routes for every deployed Edge Function.
2. Complete physical-stock writer matrix across every function/trigger/source artifact.
3. Complete financial/ledger writer matrix across every function/trigger/source artifact.
4. Full Git commit → Deployment artifact lineage for all critical capabilities.
5. Cloudflare Pages current production commit/artifact and deployment lineage.
6. Browser-level certification of the New-main candidate.
7. Full two-tenant authorization regression tests.
8. Provenance/business meaning of the one active `users` row without `auth_id`.
9. Provenance/business meaning of the two cancelled empty `VoidInvoice` journal headers.
10. Historical stock origin for the current 31 units beyond the three current inventory-log rows.

## CONFLICTS

### Historical RLS claim vs current Production
July documentation described several finance tables as lacking RLS. Current Production has RLS enabled on the inspected critical tables. The historical claim is retained as evidence of a previous security state, not current truth. fileciteturn41file0L2-L2

### Historical business writer model vs current database-side engines
Historical documents describe Edge Functions as the primary business execution layer. Current Production now contains substantial database-side atomic writers. The current implementation is therefore more centralized than the historical documentation baseline.

### Git current vs Production deployment time
Git `main` continues to change on 2026-08-31 while critical Edge deployments were last updated on 2026-08-17 through 2026-08-20. This is deployment drift evidence, not proof of functional divergence.

## STALE CLAIMS

The following must not be treated as current without revalidation:

- historical table/function counts such as 52 tables / 71 Edge Functions;
- historical security status before the RLS remediation path;
- historical supplier-ledger gap;
- any older `CURRENT_STATE` numeric snapshot;
- any historical claim that a specific Edge Function is still the active consumer of a business capability.

## HISTORICAL CLAIMS

The following are retained as historical contract evidence:

- Cloud-Native + Offline-First PWA architecture.
- Multi-PWA model with shared core behavior.
- `order_details` as the historical fulfillment source of truth.
- `allocated_qty` as reservation state distinct from physical stock.
- historical Order-to-Cash and Procure-to-Pay state transitions. fileciteturn40file0L2-L2
- ADR-driven architectural decisions around Supabase, PWA, Dexie.js, shared core, and separate applications. fileciteturn42file0L2-L2

## CURRENT PRODUCTION TRUTH

### Business lifecycle

The current intended flow remains a channel-to-order → fulfillment/runsheet → loading/delivery/return → settlement/accounting process, with operational and financial consequences delegated to canonical database/Edge engines.

### Inventory authority

`post_stock_movement` is the proven current physical-stock authority for the inspected movement families.

### Accounting authority

`post_journal_entry` is the proven current journal writer for new balanced journal entries, with specialized ledger/cash writers for subledgers/cash.

### Tenant authority

`auth.users` identity → `public.users.auth_id` → `public.users.company_id` is the current tenant-context chain used by critical code.

### Security verdict

Current security is materially hardened but **not uniformly safe** because of broad RLS/grant exposure on core order/fulfillment tables.

## TARGET ARCHITECTURE

The directly evidenced target direction is:

- tenant-aware shell and specialized PWAs;
- canonical Edge/RPC transaction writers;
- centralized physical stock movement;
- database-side atomic accounting/ledger posting;
- auditability and idempotency;
- no duplicate physical stock writers;
- no business-flow dependence on stale retired endpoints.

The target is not a license to redesign business contracts without evidence.

## OPEN CLOSURE UNITS

`P0-S001` — orders tenant-isolation policy/grant hardening  
`P0-S002` — order_details tenant-isolation policy/grant hardening  
`P0-S003` — run_sheet_details tenant-isolation policy/grant hardening  
`P0-S004` — daily_settlements least-privilege tenant-scoped read policy  
`C-001` — complete active consumer → capability → function matrix  
`C-002` — complete writer exclusivity matrix  
`C-003` — Git → Production deployment lineage certification  
`C-004` — two-tenant authorization regression test fixture/harness  
`C-005` — provenance of active user without auth_id  
`C-006` — provenance of cancelled empty void journal headers  
`C-007` — New-main browser/runtime certification before replacement

## CLOSED CLOSURE UNITS

- Phase 0 command ingestion.
- Source authority mapping.
- Fresh Production snapshot.
- Historical reconstruction baseline.
- Target system reconstruction.
- Core dependency graph.
- Inventory forensic snapshot/invariants.
- Accounting writer reconstruction.
- Cross-system relational integrity checks.
- Runtime drift classification.
- Assistant behavioral calibration.

## PRODUCTION-ONLY DRIFT

- Deployed Edge Function versions/SHA artifacts not represented by exact deployment mapping in Git metadata.
- Historical/test endpoints receiving 410 traffic.
- Current Production data conditions with limited historical movement records.

## GIT-ONLY DRIFT

- New-main candidate and active verification artifacts/branches not yet proven to be the Production UI artifact.
- Current Git changes newer than the latest critical Edge deployment timestamps.

## READINESS CONCLUSION

The project is sufficiently reconstructed for **forensic engineering**, but not cleared for uncontrolled Production engineering. The security P0 findings and incomplete consumer/deployment proof are the gating constraints.

## EXIT GATE

`PHASE 13 CLOSED`
