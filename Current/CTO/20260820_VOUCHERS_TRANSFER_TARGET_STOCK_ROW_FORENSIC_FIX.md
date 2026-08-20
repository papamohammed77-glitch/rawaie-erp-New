# RAWAEA ERP — 2026-08-20 Vouchers Transfer Target-Stock Forensic Fix

## Incident
`Current/PWA/vouchers.html` Transfer Branch→Branch SEND failed in the deployed runtime with:

`target stock row missing`

Console evidence showed the failure came from the `send-stock-voucher` Edge Function / Production RPC path, not from the Tailwind warning.

## Forensic reconstruction
The current Production contract was re-read directly from PostgreSQL.

`send_stock_voucher_atomic` correctly maps a Transfer to:

`source branch = stock_vouchers.from_id`
`target branch = stock_vouchers.to_id`
`movement type = TransferOut`

and calls the central `post_stock_movement` engine.

The central engine then validated branch/company context and Item identity, required an existing source stock row, and also required an existing target `stock_branches` row. That final requirement was the defect.

A valid destination branch is master data. A `stock_branches` row is inventory state. A missing inventory-state row for a valid destination/item pair represents a zero opening balance, not an invalid destination.

## Production evidence
At investigation time Production contained a real draft voucher:

- voucher: `IN-1`
- id: `543f1fcd-85d6-4767-94a3-39b539588296`
- type: `Transfer`
- company: `00000000-0000-0000-0000-000000000001`
- source: `BR-01` / `a38332b6-6cea-480a-ada1-6eb6ab0590db`
- target: `BR-2` / `f1bb941a-5a83-46fb-8ba3-4f0aa0c1edd2`
- details: item `1003` qty `2`, item `1005` qty `1`, item `1001` qty `1`
- creator: `vouchers@rawaea.com`
- reference: `01`
- notes: `تجربة`

Before the repair, BR-2 had `0` stock rows, including no target row for any of the three items. This reproduced the user-reported failure exactly.

## Surgical repair
The Production `post_stock_movement` function was replaced without changing the Business Movement contract.

For an inbound movement with a target branch:

1. validate target branch company context;
2. validate global Item identity;
3. atomically create `stock_branches(branch_id,item_id)` with `qty=0, allocated_qty=0` when absent;
4. use `ON CONFLICT (branch_id,item_id) DO NOTHING` for concurrency safety;
5. continue through the same central mutation and `inventory_log` path.

The source stock row remains mandatory. Source inventory is never fabricated by this repair.

No Physical Stock Writer was added. All Physical Stock Movement remains inside `post_stock_movement`.

## Runtime verification
A transactional dry-run succeeded with target rows initialized to zero and no permanent mutation from that dry-run.

The actual Production voucher `IN-1` was then sent through the real `send_stock_voucher_atomic` function.

Result:
- status: `Sent`
- movement_count: `3`
- target rows created and populated:
  - item `1001`: `1`
  - item `1003`: `2`
  - item `1005`: `1`
- allocated quantities remained `0`
- three `TransferOut` records were written to `inventory_log`
- idempotency keys were present for all three item movements
- the recorded actor was `vouchers@rawaea.com`
- source balances decreased by the exact requested quantities

This is Production Runtime Verified for the reported incident.

## Second defect found during closure: SEND retry semantics
A mandatory post-success retry test exposed a separate defect in the same writer closure: once `IN-1` was `Sent`, the next identical SEND returned `Voucher is not Draft` instead of `duplicate=true`.

This was a real idempotency contract defect because a network retry after a successful request could surface a false failure to the UI.

### Repair
A second Production migration was applied:

`20260820_send_voucher_retry_idempotency`

The function now checks the expected item movement set and matching idempotency logs before rejecting a non-Draft voucher. A complete matching prior SEND is returned as:

`success=true, duplicate=true, status=Sent`

No additional stock movement is executed.

### Runtime proof
The identical SEND retry for `IN-1` returned:

`success=true`
`duplicate=true`
`status=Sent`
`movement_count=3`

The inventory log count for that voucher remained exactly `3`; no duplicate movements were created.

Canonical Git commit for this closure:

`52ff5521ca5fbc06f0cff7d36a3feda809f34d92`

## Git canonicalization
The target-row repair is recorded in Git as:

`supabase/migrations/20260820_inventory_target_stock_row_autoinit.sql`

Commit:

`2c4c9a3eafd3d7dfd5944abdfd35a04eba7fc215`

The SEND retry repair is recorded as:

`supabase/migrations/20260820_send_voucher_retry_idempotency.sql`

Commit:

`52ff5521ca5fbc06f0cff7d36a3feda809f34d92`

## Current vouchers.html
The current Gold Master remains the single UI publication file:

`Current/PWA/vouchers.html`

Current Git blob at the time of this closure:

`812070b2e0ede5754d971fd20f4e6b5b2472f59c`

The UI contains no direct Physical Stock mutation. It calls the existing `send-stock-voucher` capability; therefore the root fixes belong in the Production core rather than in a UI-side stock workaround.

## Related current-state checks
- The deployed `receive_purchase_atomic` is already the newer `p_operation_id uuid` contract with operation reuse conflict checks; it was not incorrectly regressed to the older signature.
- `post_stock_movement` remains the sole discovered Production function that both initializes/updates `stock_branches` for Physical Movement and writes `inventory_log`; reservation functions remain reservation-only.
- The current `vouchers.html` final Gold Master IIFE overrides the older base `renderProducts` implementation and does not render sale/cost prices. The base source contains a stale price expression, but the effective runtime Gold Master path displays warehouse data only. This was verified as source/runtime behavior rather than assumed from Prompt 36 alone.

## Governing alignment
This closure follows the project's governing rule: understand historical/current/target contracts, prove the live defect in Production, apply the smallest safe change, then verify the actual Production runtime. It does not invent a new UI workaround or a second inventory engine.

## Remaining known work
This incident and its SEND retry idempotency defect are closed. This does **not** mean Global Inventory Zero-Debt is universally closed. Separate closure units and remaining historical/current Production drift must not be counted as closed without their own evidence.
