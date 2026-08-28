# RAWAEA ERP — 2026-08-28 Forensic Execution Log

## Governance
- Primary governance source: `doc/Draft/medhat/برومبت 72`.
- Execution directive: `doc/Draft/medhat/برومبت 73 + ملحق تقرير`, followed by the sequence recorded in Prompts 74–76 and current Production evidence.
- Rule applied: Production runtime truth > current Git > evidence/history > assistant/report conclusions.

## Production Snapshot at 2026-08-28
- Companies: 1
- Branches: 2
- Vehicles: 0
- Suppliers: 1
- Stock vouchers: 0
- Stock voucher operations: 0
- Stock rows: 20
- Inventory log rows: 3
- Negative physical qty: 0
- Negative allocated qty: 0
- allocated_qty > qty violations: 0
- duplicate non-null inventory idempotency keys: 0

## Physical Writer Discovery
A direct PostgreSQL scan of public functions referencing `stock_branches` or `inventory_log` found 3 functions that physically update/write inventory tables:
1. `post_stock_movement` (9-arg compatibility overload)
2. `post_stock_movement` (10-arg governed core)
3. reservation functions also mutate `allocated_qty`, but are not Physical Stock Movement engines.
No other independent Physical Writer was found outside the governed core after excluding reservation-only engines.

Result: Physical Writers outside `post_stock_movement` = 0.

## Verified Production Contracts
- `items.item_code` is globally UNIQUE (`items_item_code_key`).
- `stock_branches` is UNIQUE on `(branch_id,item_id)`.
- `available_qty` is generated and must not be written directly.
- `stock_voucher_operations.operation_id` is the durable operation-identity mechanism for manual voucher creation.
- `receiving.operation_id` is UNIQUE and is used by `receive_purchase_atomic`.
- `reserve_stock` and `release_stock_reservation` operate on `allocated_qty` only.
- `post_manual_stock_voucher_atomic` delegates Physical Stock Movement to `post_stock_movement`.
- `complete_return_atomic`, `post_inventory_adjustment_atomic`, `send_stock_voucher_atomic`, `save_sales_invoice_atomic`, and runsheet loading/unloading paths delegate physical movement to `post_stock_movement`.

## Executed Production Changes
1. Hardened `post_stock_movement` with transaction-scoped advisory serialization for supplied idempotency keys.
2. Added idempotency conflict detection against existing `inventory_log` records.
3. Added tenant/company validation for source and target branches.
4. Added reservation guard for `Loading` so loading cannot consume unreserved quantities.
5. Added protection against reducing physical stock below reserved quantity.
6. Preserved generated `available_qty` as database-derived.
7. Added deterministic branch-row locking to reduce source/target lock inversion risk.
8. Removed EXECUTE privilege from legacy `send_manual_stock_voucher_v2`.
9. Added governed COMMENT metadata to the inventory core and manual voucher functions.

## Production Tests
- Loading with a valid reservation succeeded.
- Retrying the same Loading operation with the same idempotency key returned `duplicate=true` and referenced the same inventory log record inside the transaction.
- The test transaction was rolled back; no test inventory rows remained.
- Loading without an adequate reservation is rejected by the core guard.
- Manual DirectSale core validation was executed with temporary Vehicle/VAN fixture data inside a transaction and rolled back; no permanent fixture rows remained.

## Important Failed/Corrected Attempts
A temporary rewrite initially attempted to write `available_qty` directly; Production rejected it because the column is generated. The implementation was corrected before final verification.
A temporary CI workflow intended to patch `vouchers.html` failed before creating a job; it was deleted and did not modify `vouchers.html`.
These events are explicitly recorded to prevent future CTOs from treating failed attempts as deployed changes.

## Vouchers / PWA Current Truth
- `Current/PWA/vouchers.html` currently remains at Git blob SHA `545c96bb8e869ab0c38fe736df01605260f3bbae` and still calls `RW_API.call('create-stock-voucher', ...)` without explicit `rep_id`/`operation_id`.
- This is not itself a correctness defect for DirectSale because the Production 10-argument `create_manual_stock_voucher_atomic` contract derives the representative from `vehicles.driver_id` and creates a deterministic operation identity.
- `Current/PWA/sw.js` was successfully updated in Git to Network-Only runtime JS/HTML/API behavior and to versioned static asset cache management.
- `Current/PWA/register-sw.js` was inspected and remains local-path registration logic.
- The Git source for `Current/Edge_Functions/create-stock-voucher` was updated to preserve compatibility with both the 10-argument legacy bridge and the 12-argument canonical contract; this source change has NOT been deployed to Production yet.
- Production `create-stock-voucher` remains version 8 at the time of this log.

## Final Status
### Inventory Core Integrity
CLOSED at the Physical Writer boundary.

### Vouchers/PWA Production Closure
INCOMPLETE. The remaining closure evidence is:
- deploy and runtime-verify the updated `create-stock-voucher` wrapper;
- complete source/runtime parity verification for `vouchers.html` against the deployed wrapper;
- perform browser-level E2E validation of DirectSale rep + vehicle selection and voucher lifecycle;
- synchronize and verify the final Git/Production versions.

This log intentionally does not claim 100% closed where Production runtime evidence is still missing.
