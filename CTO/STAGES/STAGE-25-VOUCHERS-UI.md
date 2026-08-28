# STAGE-25 — vouchers.html Contract + Implementation + E2E

## Status
FORENSIC CURRENT STATUS — DATABASE/CAPABILITY CLOSURE VERIFIED; LIVE BROWSER RUNTIME NOT CLAIMED

## Current Source
`Current/PWA/vouchers.html`

## Current Production Contract
- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`
- `post_inventory_adjustment_atomic`
- `post_stock_movement`

## Current Production Truth
Verified 2026-08-28:
- companies: 1
- branches: 2
- vehicles: 0
- suppliers: 1
- stock_vouchers: 0
- stock_voucher_operations: 0
- stock_branches: 20
- inventory_log: 3
- negative stock: 0
- over-allocated stock: 0
- duplicate stock keys: 0
- branch/item company mismatch: 0
- inventory_log/item mismatch: 0
- order_detail/item mismatch: 0
- runsheet/item mismatch: 0

## Closure Changes Applied
1. CREATE is now server-authorized for warehouse operator `active_warehouse_role='أذونات'` while allowing explicit direct-sales representative selection.
2. DirectSale validates representative/company/active-state and vehicle/company/active-state/driver relation.
3. A permanent `stock_voucher_operations` registry provides operation identity + fingerprint + voucher link for CREATE idempotency.
4. Existing ten-argument CREATE signature remains as compatibility wrapper.
5. Adjustment idempotency bug was found by testing and fixed: duplicate Physical Stock results are now surfaced and not counted as a second mutation.
6. Adjustment, Complete, and Cancel now bind company context to the active executing user.
7. `stock_vouchers`, `stock_voucher_details`, and `stock_branches` remain in Realtime with FULL replica identity.
8. `Current/core.js` provides a non-duplicating compatibility path to canonical `Current/PWA/core.js` because `vouchers.html` resolves `../core.js`.

## Physical Writer Rule
Production function discovery finds only:
- `post_stock_movement` as Physical Stock Writer.
- `reserve_stock` and `release_stock_reservation` as Reservation Engines.

No parallel Physical Stock Writer was found.

## Transactional Production Proof
Temporary fixtures were created and rolled back.

### DirectSale
- warehouse operator successfully created DirectSale with explicit representative
- repeated same operation_id returned duplicate + same voucher
- send moved exactly one unit Branch → Vehicle VAN branch
- source stock 2 → 1
- vehicle stock 0 → 1
- repeated SEND did not duplicate movement

### Transfer
- CREATE succeeded
- SEND moved exactly one unit Branch → Branch
- target stock row auto-initialization worked

### Adjustment
- first adjustment changed stock once
- repeated same request returned duplicate=true and movement_count=0
- no second stock mutation occurred after the fix

### Branch Authorization
- DirectSale from a representative's disallowed branch was rejected by the database contract

All tests were transactionally rolled back; Production final counts remain clean.

## Browser Runtime Boundary
A live authenticated browser session was not available in this execution context. Production currently contains zero vehicles, so a persistent live DirectSale workflow cannot be executed against real vehicle master data without inventing operational data.

Therefore the following are intentionally **not** claimed:
- live authenticated browser E2E proof of `Create → Send → Receive → Complete`
- live authenticated browser proof of Draft Cancel
- persistent live DirectSale against a real Production vehicle

## Final Position
The voucher Database/Capability layer is verified against current Production and transactional runtime evidence. The remaining Stage-25 gate is external browser-session evidence plus real vehicle master data. No false CLOSED label is applied to those unproven conditions.
