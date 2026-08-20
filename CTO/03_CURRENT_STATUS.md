# CURRENT CTO STATUS

## Scope
Inventory / Manual Vouchers / Purchase Receive / Van Sales / Fulfillment boundaries

## Current gate
**GO — GLOBAL INVENTORY CORE INTEGRITY CLOSED.**

Authoritative closure report:
`CTO/INVENTORY_ZERO_DEBT_SWEEP_2026-08-20.md`

## Production truth — 2026-08-20
- `post_stock_movement` is the only Production physical-stock writer.
- Physical Writers outside `post_stock_movement`: **0**.
- `reserve_stock` / `release_stock_reservation` are reservation-only engines.
- `setup_van_stock` is initialization only, not a movement engine.
- No stock_branches/inventory_log trigger writer was found.

## Closed findings
### P0
- `completed_by` / `completed_at` exist in the deployed `stock_vouchers` schema; the former NO-GO statement in this file was stale and is superseded by current Production evidence.
- Manual Voucher CREATE now uses the canonical `create_manual_stock_voucher_atomic` path.
- Manual Voucher V2 legacy execution grants are revoked for `send_manual_stock_voucher_v2` and `receive_manual_stock_voucher_v2`.
- Purchase Receive now requires a persisted UUID operation identity and rejects replay conflicts while returning duplicates safely.
- Return and Delivery production RPC paths are company-scoped and use `order_details` as fulfillment authority where applicable.

### P1
- Current Production audit path for `stock_vouchers` is active via `trg_audit_stock_vouchers` → `fn_audit_trigger()`.
- Production stock integrity snapshot is clean: no available_qty mismatch, negative qty, negative allocated_qty, or over-allocation.

## Important identity contract
`items.item_code` is globally UNIQUE in Production. `item_id` is the authoritative item reference. The `items.company_id` value is legacy/future-tenant metadata and is not, by itself, evidence that a stock row is corrupt.

Therefore the previously observed cross-company item-metadata rows were preserved rather than deleted by assumption.

## Runtime verification
- Controlled Production transaction proved central `TransferOut` + `TransferIn` movement and idempotency replay suppression; transaction rolled back with zero residual test logs.
- GitHub Production HTTP E2E run `32214977470` completed successfully, including `Verify current PWA operation identity` and `Production HTTP E2E`.

## Current source alignment
- `Current/Edge_Functions/create-stock-voucher` matches the deployed canonical capability wrapper.
- `Current/PWA/main.html` sends `operation_id` for Purchase Receive.
- Current Production Edge Functions reviewed for Manual Voucher CREATE/SEND/RECEIVE, Purchase Receive, Return, and Delivery use authenticated company context and canonical RPC boundaries.

## What is now permitted
- Continue to the next explicitly authorized phase after inventory closure.
- Picker work may resume only under the same governing principles.

## What remains outside this gate
- Accounting/ledger engine consolidation is a separate closure stream.
- Non-inventory administrative lifecycle functions are outside the Physical Writer zero-debt gate.

## Final state
**GLOBAL INVENTORY CORE INTEGRITY = 100% CLOSED.**
