# RAWAEA ERP — HYTHAM PHASE 2 GLOBAL WRITER DISCOVERY CLOSURE

Date: 2026-08-25
Authority: Production PostgreSQL > Current main > Current CTO evidence > historical sources > reports

## Scope

Phase 2 Closure Unit 1 only: Global Inventory Physical Writer Discovery.

## Production Evidence

Direct Production function-definition sweep covered public functions referencing `stock_branches` and `inventory_log` and searched specifically for direct INSERT/UPDATE/DELETE statements against both tables.

Result:

1. `post_stock_movement(...)` is the canonical Physical Stock mutation engine.
2. `setup_van_stock(...)` is initialization-only and does not write `inventory_log`.
3. `reserve_stock(...)` and `release_stock_reservation(...)` mutate reservation state (`allocated_qty`) only.
4. No other PostgreSQL function was found that acts as a parallel Physical Stock movement engine.
5. No non-internal trigger was found that creates a parallel Physical Stock mutation path.

## Consumer/Core Classification

- Manual Voucher → `post_manual_stock_voucher_atomic` / `send_stock_voucher_atomic` → `post_stock_movement`
- Purchase Receiving → `receive_purchase_atomic` → `post_stock_movement`
- POS / Van Sales → `save_sales_invoice_atomic` → `post_stock_movement`
- Returns → `complete_return_atomic` → `post_stock_movement`
- Loading / Unloading / Reopen Loading → run-sheet cores → `post_stock_movement`
- Inventory Adjustment → `post_inventory_adjustment_atomic` → `post_stock_movement`
- Picking → `reserve_stock` only; no physical movement

## Core Canary

A controlled Production transaction used an existing stock row and called `post_stock_movement` twice with the same idempotency key.

Observed inside the transaction:

- first call: movement accepted;
- second call: duplicate path returned;
- one inventory log row existed for the idempotency key;
- rollback removed all temporary state.

No residue was retained.

## Important Boundary

This closure is a SQL/Core proof only.
It does NOT certify:

- authenticated HTTP E2E;
- two-session concurrency;
- deployed Edge byte/hash parity;
- legacy retirement;
- final Phase 2 Zero-Debt.

## Decision

`GLOBAL WRITER DISCOVERY = SUBSTANTIVELY VERIFIED`

`PHYSICAL WRITERS OUTSIDE post_stock_movement = 0`

The next authorized closure unit is:

`MANUAL VOUCHER`

No Production inventory mutation was retained and no unrelated domain was modified.
