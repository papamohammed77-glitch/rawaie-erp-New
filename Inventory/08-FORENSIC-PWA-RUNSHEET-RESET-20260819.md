# RAWAEA ERP — Forensic PWA + Runsheet Reset Checkpoint

Date: 2026-08-19

## Source-of-truth rule
This checkpoint is based on direct GitHub source inspection and direct Production Supabase inspection. Historical Prompt 6–10 reports were treated as evidence only, not as current truth.

## Production inventory-core finding
`post_stock_movement` is the current Physical Stock engine. Current Production definitions inspected directly show:
- `post_inventory_adjustment_atomic` delegates Physical movements to `post_stock_movement`.
- `post_manual_stock_voucher_atomic` delegates Physical movements to `post_stock_movement`.
- `send_stock_voucher_atomic` delegates Physical movements to `post_stock_movement`.
- `complete_runsheet_picking` current overloads use `reserve_stock` only and do not write `inventory_log` directly.
- `reserve_stock` / `release_stock_reservation` operate on `allocated_qty` only.
- No current `stock_branches` / `inventory_log` trigger writer was found in the inspected trigger set.

The current 5-argument `complete_runsheet_picking` returns `inventory_log_written=false` and uses the reservation engine only.

## Production authorization boundary
Current RLS inspection shows only authenticated SELECT policies on `inventory_log` and `stock_branches`, company-scoped. No application INSERT/UPDATE/DELETE grants were returned for those tables in the inspected privileges query.

## PWA findings
### PASS
- `Current/PWA/main.html` currently sends `operation_id: crypto.randomUUID()` in its inspected sales order-header builders and in the purchase-receiving request.
- `Current/PWA/picker.html` persists/reuses its picking operation ID in sessionStorage and sends both the idempotency header and JSON operation_id.
- `Current/PWA/Returns.html` does not directly write Physical Stock; it calls the return capability.
- `Current/PWA/vouchers.html` uses Edge capability calls for SEND/RECEIVE instead of direct Physical Stock writes.

### DEFECT FOUND — NOT YET APPLIED
`Current/PWA/van-sales.html` function `submitQuickSale` calls `save-sales-invoice` without an `operation_id` in `orderHeader`.

Required surgical change inside the SAME function:
```javascript
var hdr = {
    operation_id: crypto.randomUUID(),
    customer_code: c.customer_code,
```

This is a real consumer/core contract gap because the current save-sales path has operation-id/idempotency semantics, while the Van Sales caller omits the identity.

A temporary GitHub Actions workflow was created to apply this exact same-file replacement, but no executable workflow result/commit was produced. The temporary workflow was removed immediately. Therefore this defect is NOT claimed closed.

### ADDITIONAL VERIFIED PWA DEFECT — NOT YET APPLIED
`Current/PWA/vouchers.html` `viewVoucherDetails` queries `stock_voucher_details` by `voucher_code`, while the inspected Production schema exposes `voucher_id` as the relation and not `voucher_code` on `stock_voucher_details`.

This should be surgically corrected to resolve the voucher ID from `stock_vouchers` by `company_id + voucher_code`, then query `stock_voucher_details` by `voucher_id`.

## Runsheet reset
Before reset Production contained exactly one runsheet: `RS-1`, status `Picked`, with 16 detail rows and 27 units of reserved stock (`allocated_qty`).

The reset was executed using `release_stock_reservation` for the 16 reservation rows, followed by deletion of the runsheet.

Final Production verification:
- runsheets = 0
- run_sheet_details = 0
- orders with runsheet_id = 0
- daily settlements with runsheet_id = 0
- driver liabilities with runsheet_id = 0
- service complaints with runsheet_id = 0
- credit block events with runsheet_id = 0
- credit notes with runsheet_id = 0
- fulfillment backorders with runsheet_id = 0
- stock rows with allocated_qty <> 0 = 0
- total allocated_qty = 0

A `delete` audit record was written for the forensic reset in `audit_log` with record_id `GLOBAL`.

## Current closure state
- Physical Stock centralization: VERIFIED from current Production function definitions.
- Picker reservation architecture: VERIFIED from current Production + current PWA.
- Runsheet test-data reset: PRODUCTION VERIFIED CLOSED.
- PWA Van Sales operation-id contract: FOUND / NOT CLOSED.
- PWA Voucher details relation: FOUND / NOT CLOSED.

## Git checkpoint
Latest Git state after cleanup of the temporary workflow: `bc9282714648d3c8a3a8f192703c580f8c162221`.

Next action must start with the two PWA consumer defects above and must not claim 100% until each is actually committed and verified against current Production behavior.
