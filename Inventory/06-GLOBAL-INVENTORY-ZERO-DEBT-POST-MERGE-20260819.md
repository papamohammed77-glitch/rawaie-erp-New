# GLOBAL INVENTORY ZERO-DEBT — POST-MERGE PRODUCTION CLOSURE — 2026-08-19

## Purpose
This record closes the verification limitation recorded in `Inventory/05-GLOBAL-INVENTORY-ZERO-DEBT-RESULT-20260819.md`.

The governing sources were re-read before execution:
- `doc/Draft/medhat/برومبت 6`
- `doc/Draft/medhat/تقرير تنفيذ برومبت 6`
- `doc/Draft/medhat/برومبت 7 ملحق بتقريره`
- `Inventory/05-GLOBAL-INVENTORY-ZERO-DEBT-RESULT-20260819.md`

## Production Snapshot At Closure
Production was queried directly. PostgreSQL is 17.6.

Confirmed structure:
- `post_stock_movement` is the Physical Stock engine.
- `receive_purchase_atomic`, `save_sales_invoice_atomic`, `complete_return_atomic`, `post_inventory_adjustment_atomic`, `post_manual_stock_voucher_atomic`, and `send_stock_voucher_atomic` delegate Physical Movement to the central engine where Physical Movement exists.
- `complete_order_delivery_atomic` is fulfillment-only.
- `reserve_stock` and `release_stock_reservation` are Reservation capabilities, not Physical Movement engines.
- `setup_van_stock` is bootstrap/row initialization only.
- No triggers exist on `stock_branches` or `inventory_log`.

## Legacy Physical-Movement API Closure
Production contained a 9-argument `post_stock_movement` overload without an idempotency key. It was a compatibility bridge, not an independent writer: it delegated to the canonical 10-argument function and rejected Loading/Unloading without an idempotency key.

Its `EXECUTE` privilege was revoked from `PUBLIC`, `anon`, `authenticated`, and `service_role`. The canonical 10-argument engine remains executable by `service_role`.

## PWA State
### Save-Sales
PR #14 is merged to `main` as commit `3e7ff26ecfacc153878adb9cd96f977e472206d9`.

The current PWA contains `operation_id: crypto.randomUUID()` in all three current `orderHeader` builders. The fresh Production E2E independently asserted this source condition.

### Receive-Purchase
The current PWA contains `operation_id: crypto.randomUUID()` in the receive-purchase request payload, recorded by commit `70267e11db12a3acaa02d3ee149bc66385e7492e`.

## Fresh Production HTTP E2E — SAVE SALES
A new PR-triggered Production HTTP E2E was executed after PR #14 was merged.

Run: `32214977470`
Job: `95954658863`
Conclusion: `success`

Evidence proved:
1. Current PWA operation identity assertion passed.
2. A real Production auth session was created.
3. The real `save-sales-invoice` Edge Function was called.
4. First request: `success=true, duplicate=false`.
5. Identical retry: `success=true, duplicate=true`.
6. Exactly one Order existed for the operation.
7. Exactly one `inventory_log` row existed.
8. Exactly one `journal_entries` row existed.
9. Physical stock decreased by exactly one unit.
10. `allocated_qty` was unchanged.
11. Cleanup restored the exact stock baseline.
12. Residual Orders = 0.
13. Residual Sales Inventory Logs = 0.

The Production test fixture was temporary and cleanup completed with residue-zero verification.

## Data Governance
The previously observed cross-company Item Master rows were not deleted. `items.item_code` is globally UNIQUE and the active architecture treats Item Master identity as global. Deleting or reassigning those rows without a proven ownership contract would violate the governing no-assumption rule.

## Final Self-Audit
### Proven
- Physical Stock mutation is centralized.
- The remaining callable legacy `post_stock_movement` overload is retired.
- Save-Sales PWA operation identity is on `main`.
- Receive-Purchase PWA operation identity is on `main`.
- Save-Sales post-merge Production HTTP E2E is PASS.
- Identical save retry is idempotent.
- Stock, inventory log, and accounting cardinality remain correct.
- Production test residue is zero.

### Not Claimed
- No persistent live business transaction was left in Production; the E2E restored its baseline.
- Historical evidence is not being substituted for the new runtime evidence.

## Final Status
`GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED`

`PHYSICAL WRITERS OUTSIDE post_stock_movement = 0`

`SAVE_SALES_POSTMERGE_PRODUCTION_E2E = PASS`

`PRODUCTION_TEST_RESIDUE = 0`

This document is the current memory checkpoint for a future CTO/session restart.
