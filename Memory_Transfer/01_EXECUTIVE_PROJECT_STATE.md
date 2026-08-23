# EXECUTIVE PROJECT STATE

## Project
RAWAEA ERP — FMCG Distribution / Logistics ERP on Supabase/PostgreSQL + Edge Functions + PWA clients.

## Architectural target
ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution.
UI → Capability/Edge → Core RPC → PostgreSQL → State/History/Audit.

## Inventory state
Production evidence captured in the 2026-08-20 sweep states that `post_stock_movement` is the sole Physical Stock Movement writer; `reserve_stock` and `release_stock_reservation` are reservation-only; `setup_van_stock` is initialization. No trigger writer was found.

## Current Production re-baseline
Snapshot: 2026-08-23 03:27:59 UTC.
- Companies: 3
- Users: 26
- Branches: 5
- Items: 50
- Stock branch rows: 26
- Inventory log rows: 3
- Journal entries: 2
- Journal lines: 0
- Customer ledger rows: 0
- Supplier ledger rows: 0
- Driver ledger rows: 0
- Daily settlements: 0
- Treasury rows: 1
- Chart of accounts rows: 87
- Public PostgreSQL functions: 45

## Readiness
Inventory Core integrity is documented as closed. ERP-wide autonomous CTO readiness is NOT READY because accounting, ledgers, fulfillment-wide graph, consumers, deployment lineage, data repair, concurrency coverage, and global zero-debt outside the physical writer boundary remain open.

## Important drift
The 2026-08-21 readiness registry recorded 42 public functions and inventory_log=62; the current 2026-08-23 Production query shows 45 functions and inventory_log=3. These are different snapshots and must not be silently conflated.
