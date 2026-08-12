# STAGE-25 — vouchers.html Contract + Implementation + E2E

## Status
IN PROGRESS — SOURCE IMPLEMENTED / PRODUCTION DEPLOYMENT NOT YET VERIFIED

## Original Source Reviewed
`PWA/warehouse/vouchers.html` from rescue branch `rescue/manual-vouchers-inventory-core`.

## Production Voucher Core Used
- `create_manual_stock_voucher_atomic`
- `send_manual_stock_voucher_v2`
- `receive_manual_stock_voucher_v2`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`

## Source Implementation
Commit:
`c093e2f79c81e3a03f5dbb04ce2f22ce7226e737`

## Changes
1. Voucher lifecycle actions route directly through the verified Voucher RPC core.
2. Legacy UI calls to `send-stock-voucher`, `receive-stock-voucher`, and `complete-stock-voucher` are removed from the implemented path.
3. Create uses the verified `create_manual_stock_voucher_atomic` contract.
4. Receive UI now collects explicit `receivedQty` values per item and exposes required/received/remaining quantities.
5. Partial Receive remains `Sent`; final receipt becomes `Received` through the backend contract.
6. Draft Cancel is exposed through `cancel_manual_stock_voucher_atomic`.
7. Complete is available in the valid `Sent` / `Received` states.
8. Existing login, role gate, tabs, search, item search, cart, voucher details, and account UI are preserved.
9. UI performs no direct stock mutation and no direct inventory-log mutation.

## Production Reality Gate
The source implementation exists in GitHub, but STAGE-25 cannot be called CLOSED / GO until the updated PWA file is deployed to the actual target application and live runtime evidence proves:

`Create → Draft → Send → Partial Receive → Full Receive → Complete`

and:

`Create → Draft → Cancel`

with correct UI/API behavior and no legacy consumer path.

## Required Final Evidence
- deployed PWA version/commit
- live Create test result
- live Send test result
- live Partial Receive result
- live Full Receive result
- live Complete result
- live Draft Cancel result
- confirmation that legacy Voucher lifecycle calls are no longer the active runtime consumer path
