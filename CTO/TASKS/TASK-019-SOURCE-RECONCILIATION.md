# TASK-019 — Receive Source Reconciliation

## Evidence reviewed
- Original inventory functions under `Edge_Functions/original/08_inventory`.
- Original `PWA/warehouse/vouchers.html`.
- Original `PWA/sales/van-sales.html`.
- Current Source Map under `Rescue/04-CURRENT-SOURCE-MAP.md`.
- Current/target Manual Voucher contract.

## Original Receive capability preserved
`receive-stock-voucher.ts` supports:
- authenticated Receive action;
- `Transfer` and `DirectReturn` receive types;
- destination branch resolution;
- physical stock increase;
- inventory history row;
- detail `received_qty` update;
- Voucher transition to `Received`.

## Original weaknesses intentionally not preserved
- direct `stock_branches` mutation outside the central engine;
- direct `inventory_log` writer outside the central engine;
- replacement rather than cumulative `received_qty` semantics;
- immediate `Received` transition on a partial quantity;
- non-atomic application-level sequence.

## Target Receive contract
- central physical mutation through `post_stock_movement`;
- cumulative `received_qty`;
- partial Receive keeps Voucher `Sent`;
- full Receive changes Voucher to `Received`;
- reject quantity greater than remaining;
- preserve `allocated_qty`;
- one inventory history row per successful physical Receive movement;
- atomic database transaction boundary.

## UI observations
`vouchers.html` already exposes Receive for `Transfer` / `DirectReturn`, but its current Receive action delegates to the legacy `receive-stock-voucher` contract and therefore is not yet the final consumer of the new Receive core.

`van-sales.html` was reviewed as a future consumer; it is not modified by TASK-019.

## Current non-final source status
The Source Map records the current SEND Edge Function as still using `send_stock_voucher_atomic`, while the newer candidate path is separate. This remains an integration concern for the later Edge Function phase and is not silently treated as completed.

## Gate
TASK-019 remains **IN_PROGRESS** until the Production SQL artifact returns:
`TASK-019 — RECEIVE VOUCHER PASS`.
