# TASK-028 — LOADING / UNLOADING CORE — CONTRACT FINDINGS

## Status
ACTIVE — EVIDENCE / CONTRACT RECONCILIATION

## Confirmed historical findings

### Original `complete-loading.ts`
Source: `rawaie-erp-review/main/Edge_Functions/original/03_loading/complete-loading.ts`

Historical behavior includes:
- requires `runsheet_code` and `items` with `loadedQty`;
- requires runsheet status `Loading`;
- deducts physical stock from `main_branch_id`;
- decreases `allocated_qty` by loaded quantity;
- writes `inventory_log` movement type `Loading`;
- updates `run_sheet_details.qty_loaded` and `remaining_qty`;
- updates `order_details.qty_loaded` and `reason_loading` on shortages;
- recalculates `orders.original_total_amount`;
- creates journal entry / journal lines for loaded stock cost;
- changes runsheet status to `Loaded`;
- changes associated orders to `Loaded`;
- contains a later Backorder mechanism.

### Historical `unload-runsheet.ts`
Source: `rawaie-erp-review/main/Edge_Functions/original/04_runsheet/unload-runsheet.ts`

Historical behavior includes:
- requires runsheet status `Loaded`;
- reads `run_sheet_details.qty_loaded`;
- adds loaded quantity back to MAIN stock;
- writes `inventory_log` movement type `Unloading`;
- zeros `run_sheet_details.qty_loaded` and `remaining_qty`;
- sets orders back to `Pending`;
- changes runsheet status back to `Picked`.

## Critical architectural finding
The historical implementation treats Loading as direct MAIN stock deduction and Unloading as direct MAIN stock return. That must NOT be promoted automatically to the new architecture because the owner-established custody model now distinguishes:

`Vehicle = mobile stock container`
`Representative = accountable custodian`

and `DirectSale = MAIN → VAN` is already the established custody issuance path.

Therefore TASK-028 must determine whether Loading is:

A. a real stock transfer MAIN → VAN, or
B. an operational runsheet state layered over stock already transferred to VAN.

A direct copy of historical `complete-loading.ts` risks a second deduction if DirectSale has already moved the same stock to the VAN branch.

## Next evidence required
Production read-only schema for:
- runsheets
- run_sheet_details
- orders
- order_details

Plus constraints and foreign keys.

If no actual runsheet exists, one controlled test runsheet created through the parent/master system is required before runtime E2E validation of TASK-028. It must be a disposable test fixture and must not be used as permanent business data.

## Current gate
NO IMPLEMENTATION until the Loading/Unloading topology is reconciled against the established DirectSale/VAN custody model.
