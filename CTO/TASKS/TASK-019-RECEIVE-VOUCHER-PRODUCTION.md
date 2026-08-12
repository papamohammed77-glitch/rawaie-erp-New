# TASK-019 — Receive Voucher

## Status
**IN_PROGRESS — PRODUCTION EXECUTION REQUIRED**

## Objective
Implement the Receive side of Manual Stock Vouchers using the deployed central `post_stock_movement` engine while preserving the original Receive business capability and adding correct cumulative Partial Receive behavior.

## Original behavior reviewed
`Edge_Functions/original/08_inventory/receive-stock-voucher.ts` directly mutated `stock_branches`, inserted `inventory_log`, overwrote `received_qty`, and immediately set Voucher to `Received` for Transfer / DirectReturn.

## Target behavior
- Voucher must be `Sent` before Receive.
- Physical stock mutation must occur through `public.post_stock_movement(...)` only.
- Supported Receive types: `Transfer`, `DirectReturn`.
- `received_qty` is cumulative.
- Partial Receive keeps Voucher at `Sent`.
- Full Receive changes Voucher to `Received`.
- `received_date` / `received_by` are recorded at full receipt.
- Receiving beyond remaining quantity must fail atomically.
- `allocated_qty` must not change.
- Each successful Receive movement creates exactly one inventory history row.
- Existing Original capability is preserved; duplicated stock mutation is removed from the new path.

## Production status
SQL implementation artifact is prepared but **not Production-implemented until actual execution returns PASS**.

## Gate
Do not close TASK-019 until the complete transactional Production test returns:
`TASK-019 — RECEIVE VOUCHER PASS`
