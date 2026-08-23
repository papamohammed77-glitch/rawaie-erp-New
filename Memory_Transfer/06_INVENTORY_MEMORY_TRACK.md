# INVENTORY MEMORY TRACK

## Current Production baseline
Snapshot UTC: 2026-08-23 03:27:59.
- companies=3
- users=26
- branches=5
- items=50
- stock_branches=26
- inventory_log=3

## Core law
`post_stock_movement(10)` is the central physical stock writer. The 2026-08-20 Zero-Debt Sweep reports 0 physical writers outside it. fileciteturn212file0

## Reservation
`reserve_stock` / `release_stock_reservation` are reservation-only. Reservation changes `allocated_qty`; physical `qty` is not reduced merely by picking.

## Movement history
`inventory_log` is authoritative movement history for posted physical movements. Picking must not create a Physical Stock movement log if the current Production contract confirms reservation-only behavior.

## Identity
Production `items.item_code` is globally UNIQUE and `item_id` is authoritative. `stock_branches` is keyed by branch/item identity. Do not repair cross-company item metadata blindly; current model treats item master identity globally. fileciteturn225file0

## Proven convergence
The 2026-08-20 sweep lists these adapters converged on the central engine: send voucher, purchase receive, inventory adjustment, sales invoice, return, manual voucher, loading, reopen loading, unloading. fileciteturn222file0

## Inventory closure status
`GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED` was recorded on 2026-08-20. This closure is boundary-specific: it does not mean Accounting/Ledger/Fulfillment/Consumer/Deployment domains are closed. fileciteturn222file0

## Current risks/drift
- Current 2026-08-23 inventory_log count=3 differs from older closure snapshots (56/62). This must be treated as snapshot drift and provenance/reconciliation target.
- `Current/Edge_Functions/start-picking` differs from deployed Production v14 identity lookup and must be reconciled.
- Temporary/canary Edge Functions remain active in Production registry and require governance cleanup.
- Full fulfillment/consumer/deployment lineage remains open.
