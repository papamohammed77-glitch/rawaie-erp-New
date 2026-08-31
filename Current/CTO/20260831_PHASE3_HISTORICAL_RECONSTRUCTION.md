# RAWAEA ERP — PHASE 3 HISTORICAL RECONSTRUCTION & CHANGE LEDGER

**Date:** 2026-08-31  
**Phase:** 3 — Historical Reconstruction  
**Status:** CLOSED  
**Scope:** Historical intent, architecture evolution, known repair trajectory, and current-vs-historical deltas.  
**Production data mutation:** None.

## HISTORICAL SOURCES EXAMINED

1. `rawaie-erp-review/docs/06_SYSTEM_ARCHITECTURE.md` — architecture baseline dated 2026-07-13.
2. `rawaie-erp-review/docs/11_BUSINESS_WORKFLOWS.md` — business workflow baseline dated 2026-07-13.
3. `rawaie-erp-review/docs/13_SECURITY_MODEL.md` — security baseline dated 2026-07-13.
4. `rawaie-erp-review/docs/17_ARCHITECTURAL_DECISIONS.md` — ADR baseline dated 2026-07-13.
5. Current `rawaie-erp-New/Current/Edge_Functions/*` source for critical operational paths.
6. Fresh Production definitions from Supabase `SMART ERP` captured in Phase 2.

Historical documentation is treated as design/history evidence only. Current Production and current Git remain authoritative for present behavior.

## HISTORICAL ARCHITECTURAL BASELINE

The July baseline describes a Cloud-Native + Offline-First PWA consisting of a Cloudflare-hosted PWA layer, Supabase Auth/Storage/Edge Functions, and PostgreSQL with RLS. It describes 26 PWA applications, 71 Edge Functions, and 52 database tables at that historical point. fileciteturn39file0L2-L2

The historical business workflow identifies Order-to-Cash, Procure-to-Pay, Inventory/Runsheet, Delivery/Return/Settlement, and Offline-to-Online Sync as the core flows. It also explicitly models stock progression through picking, loading, delivery, return, and unloading. fileciteturn40file0L2-L2

The historical ADR register records major architectural choices: Supabase as BaaS, PWA + Offline-First, Dexie.js/IndexedDB, `order_details` as the canonical order-detail source, `sync-run-sheet-details` as an intermediate aggregation layer, a shared `core.js`, separate PWA applications, and Edge Functions as the business service layer. fileciteturn42file0L2-L2

## HISTORICAL SECURITY POSITION

The July security model describes a defense-in-depth design using Auth/JWT, application-level permission checks, Edge Function validation, PostgreSQL RLS, and audit logging. It also records a then-known security gap: several financial tables were described as lacking RLS and were scheduled for P0 remediation. fileciteturn41file0L2-L2

This is materially different from the fresh Phase 2 Production snapshot, where all 25 inspected critical business tables have RLS enabled. Therefore the historical P0 security gap is evidence of an architectural remediation path, not current evidence that those tables remain unprotected.

## HISTORICAL BUSINESS CONTRACTS

The July workflow explicitly states:

- `complete-picking` raises `allocated_qty` / reserves stock.
- `complete-loading` reduces physical stock and allocated quantity and records inventory movement plus COGS.
- `complete-delivery` posts revenue and customer ledger effects.
- `complete-return` returns good stock and posts the reverse accounting path.
- `receive-purchase` increases stock and posts the receipt accounting entry.

The same historical document records a supplier-ledger gap in `receive-purchase`, with an explicit recommendation to add supplier-ledger posting. fileciteturn40file0L2-L2

## CURRENT IMPLEMENTATION DELTAS PROVEN FROM CODE

### 1. Stock mutation convergence

Current Production `complete_runsheet_loading` is a `SECURITY DEFINER` PL/pgSQL function. It validates company/runsheet/vehicle/loading context, updates `order_details`, then calls `public.post_stock_movement(...)` for the physical stock movement. The current Edge Function wrapper explicitly states that physical stock mutation is delegated exclusively to `post_stock_movement`. fileciteturn46file0L2-L2

Current Production `post_stock_movement` itself implements the movement-type whitelist, source/target company validation, stock-row locking, available/reserved balance checks, idempotency locking, inventory-log insertion, and the Loading/Unloading movement rules. It is therefore a genuine current stock engine, not merely a convention. The function also requires an idempotency key for Loading/Unloading. 

### 2. Sales atomicization and idempotency

Current `save-sales-invoice` authenticates the caller with Supabase Auth, derives an operation id when necessary, and delegates invoice processing to `save_sales_invoice_atomic`. fileciteturn45file0L2-L2

The current Production `save_sales_invoice_atomic` checks company context, requires `operation_id`, detects duplicate operations, creates the order/details, and for invoiced sales calls `post_stock_movement` with `POSSale` or `VanSale`. It also delegates accounting operations to atomic journal/cash/customer/driver ledger routines.

This is a material evolution from the historical architecture where the business workflow was documented primarily in the Edge Function layer. The business contract now spans an Edge Function orchestration layer plus database-side atomic engines.

### 3. Purchase receiving convergence

Current `receive-purchase` authenticates the caller, resolves company context through `users.auth_id`, creates an operation id, and calls `receive_purchase_atomic`. fileciteturn47file0L2-L2

Current Production `receive_purchase_atomic` posts `PurchaseIn` through `post_stock_movement`, updates receiving/purchase quantities, posts a journal entry, and calls `post_supplier_ledger_entry`. This directly addresses the supplier-ledger gap explicitly documented in July. 

### 4. Stock-voucher convergence

Current `send-stock-voucher` authenticates the caller, resolves the authenticated user's company, and delegates to `send_stock_voucher_atomic`, rather than implementing the physical movement directly in the Edge Function wrapper. fileciteturn48file0L2-L2

### 5. RLS evolution

Historical July security documentation described multiple finance-related tables as lacking RLS. fileciteturn41file0L2-L2

Fresh Phase 2 evidence shows RLS enabled across the inspected critical business tables, including `journal_entries`, `journal_lines`, `treasury`, `daily_settlements`, `driver_ledger`, `customer_ledger`, `supplier_ledger`, `stock_branches`, and `inventory_log`.

This is confirmed as a real architectural evolution, not a documentation-only claim.

## CHANGE LEDGER

| Area | Historical state | Current observed state | Evidence class |
|---|---|---|---|
| Stock engine | Stock logic described per workflow/Edge function | `post_stock_movement` is a live DB-side atomic engine with locking/idempotency | Production + current code |
| Loading | Loading flow mutates stock and records inventory | `complete_runsheet_loading` delegates physical movement to `post_stock_movement` | Production + current code |
| Sales | Edge Functions described as primary business layer | `save-sales-invoice` orchestrates `save_sales_invoice_atomic`; stock/accounting are delegated | Production + current code |
| Purchase receiving | Historical supplier ledger gap documented | `receive_purchase_atomic` posts supplier ledger | Production + current code |
| Finance RLS | Historical documented P0 gap | Critical inspected tables currently have RLS enabled | Production + historical comparison |
| PWA architecture | 26 PWA + main/core.js baseline | Current repository contains active reconstruction branches and a moving `main`; full runtime equivalence is still not proven | Git |
| Function count | 71 historical Edge Functions | More than 71 active deployed functions currently exist, including canonical, test, canary, and retired-style endpoints | Production runtime |
| Runtime retirement | Historical/temporary utilities existed | Several historical/test endpoints still receive calls and return 410 | Production runtime |

## HISTORICAL CONTRACTS THAT REMAIN RELEVANT

The following remain identified as intended business contracts rather than obsolete ideas:

- `order_details` carries fulfillment quantities through the workflow.
- `allocated_qty` is reservation state, distinct from physical quantity.
- Loading/unloading and transfer are physical stock movements.
- Business actions should be auditable and company-scoped.
- Accounting should move with operational state transitions rather than being manually reconstructed later.
- Offline-capable field applications are an architectural requirement.

These are design intents. Their complete current implementation and consumer graph are not declared closed here.

## HISTORICAL → CURRENT RECONCILIATION OF KNOWN INCIDENT THEMES

### Previously observed architectural risk
Multiple business functions could independently modify stock, inventory logs, journals, and ledgers.

### Current observed direction
The current Production database contains explicit atomic stock and accounting primitives, including `post_stock_movement`, `post_journal_entry`, `post_cash_receipt_atomic`, `post_customer_ledger_entry`, `post_supplier_ledger_entry`, and `post_driver_ledger_entry`, with canonical Edge wrappers increasingly acting as orchestrators.

### Important limitation
The existence of canonical primitives does **not** prove every writer has been migrated to them. A complete writer matrix and consumer trace remain mandatory in later phases.

## HISTORICAL RECONSTRUCTION CONCLUSION

The system has undergone substantive architecture hardening between the July 2026 documentation baseline and the August 31, 2026 Production state. The strongest proven improvements are:

1. stock mutation centralization around `post_stock_movement`;
2. operation/idempotency protection on critical transaction flows;
3. database-side atomic financial writers;
4. broader RLS coverage across critical finance/operations tables;
5. supplier-ledger posting integrated into purchase receiving.

At the same time, the current state still shows unresolved operational-history residue (410 endpoints being called) and live evidence of data anomalies (`users.auth_id` missing for one row and two journal headers without lines). These require provenance analysis, not automatic cleanup.

## EXIT GATE

`PHASE 3 CLOSED`

Historical architecture, business workflow, security posture, ADR intent, and several major current-vs-historical changes have been reconstructed from direct repository artifacts and current Production function definitions. No historical claim has been promoted to current truth without current evidence.
