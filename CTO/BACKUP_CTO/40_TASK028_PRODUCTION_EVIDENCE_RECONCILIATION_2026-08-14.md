# TASK-028 — Production Evidence Reconciliation
## Date: 2026-08-14
## Status: EVIDENCE ACQUISITION COMPLETE / IMPLEMENTATION NO-GO

### 1. Authority
Production evidence was obtained directly from the connected Supabase project `SMART ERP` (`fiilmooggumokxanwiyx`) in `mhassan Org`.
No DDL, DML, migration, Edge Function deployment, or data mutation was executed during this reconnaissance.

### 2. Production identity
- Organization: mhassan Org
- Project: SMART ERP
- Project status: ACTIVE_HEALTHY
- PostgreSQL: 17.6.1.121 / engine 17
- `app_settings.company_id`: `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- Company code: `ALRAWAE`
- Company name: الروائع للتوزيع
- Main branch: `BR-01` / الفرع الرئيسي
- Main branch id: `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`

This establishes that SMART ERP is a live RAWAEA company context, but the Production-vs-staging identity remains an architectural governance fact to preserve explicitly.

### 3. Golden fixture confirmation
Production contains:
- Vehicle: `VEH-92yrzb`
- Vehicle id: `70e5d809-0505-4e60-b317-feff6e799127`
- Driver user id: `a86726d9-d687-4113-a9e2-5f90f4bdb4fa`
- Driver email: `van-sales@rawaea.com`
- Mobile branch: `VAN-VEH-92yrzb`
- Mobile branch id: `dbdef0b7-0909-4f71-a367-30c61d021286`

This directly confirms the Vehicle / Driver / Mobile Branch fixture used by the continuity memory.

### 4. Current Production schema evidence
`stock_branches` contains:
- `qty` numeric
- `allocated_qty` numeric
- `available_qty` generated as `(qty - allocated_qty)`

`run_sheet_details` contains:
- `qty_ordered`
- `qty_picked`
- `qty_loaded`
- `qty_delivered`
- `qty_refused`
- `qty_returned`
- `driver_liability`

`order_details` contains:
- `qty`
- `qty_picked`
- `qty_loaded`
- `qty_delivered`
- `qty_refused`
- `qty_returned`
- `driver_liability`

`runsheets` contains:
- `status`
- `driver_id`
- `vehicle_id`
- picker/loader/deliverer/return-handler identities and timestamps.

### 5. Deployed Edge Function evidence
Production currently has ACTIVE functions:
- `start-loading` version 3
- `complete-loading` version 9
- `cancel-loading` version 4
- `reopen-loading` version 1
- `unload-runsheet` version 4
- `cancel-unload` version 1
- `start-picking` version 11
- `complete-picking` version 10
- `start-delivery` version 6
- `complete-delivery` version 3
- `complete-order-delivery` version 10
- `start-order-delivery` version 1
- `complete-return` version 22

This is direct deployment evidence, not GitHub inference.

### 6. Critical Production finding: complete-loading bypasses the central stock engine
The deployed `complete-loading` function directly:
1. Reads `stock_branches.qty` and `allocated_qty`.
2. Updates `stock_branches.qty` directly.
3. Writes `inventory_log` directly.
4. Updates `run_sheet_details` directly.
5. Updates `order_details` directly.
6. Updates `orders` directly.
7. Creates `journal_entries` / `journal_lines` directly.
8. Updates the runsheet to `Loaded`.
9. Creates Backorders.
10. Calls `sync-run-sheet-details`.

Therefore the production implementation is not currently routed through `post_stock_movement` for Loading.

### 7. Critical Production finding: central engine does NOT currently define Loading/Unloading movement types
The deployed `post_stock_movement` is SECURITY DEFINER and locks source/target stock rows with `FOR UPDATE`, but its allowed movement types are:
`PurchaseIn, TransferOut, TransferIn, DirectSale, DirectReturn, SupplierReturn, POSSale, VanSale, SalesReturn, PurchaseReturn, InventoryIncrease, InventoryDecrease`.

`Loading` and `Unloading` are absent.

This is a decisive TASK-028 contract gap: the existing central engine cannot presently represent Loading/Unloading as movement types without a deliberate contract change.

### 8. Critical semantic conflict in current Production implementation
The deployed `complete-loading` performs:
`MAIN qty -= loadedQty`
while the documented business topology distinguishes Loading from DirectSale and defines the mobile branch / custody topology separately.

The deployed `unload-runsheet` performs:
`MAIN qty += qty_loaded`

Neither function moves stock through the VAN/mobile branch. This must NOT be interpreted as proof that the intended Loading stock topology is MAIN→VAN; it is proof of the current deployed behavior only.

### 9. Critical company-isolation discrepancy
`app_settings.company_id` for the active RAWAEA context is:
`da4ef704-88ac-4120-aa0e-65b92b2aa2bc`.

The deployed `complete-loading` and `unload-runsheet` contain hard-coded:
`00000000-0000-0000-0000-000000000001`
when writing `inventory_log`.

The same hard-coded company id is used by `complete-loading` for journal entries and Backorder order creation.

This is a CONFIRMED deployed-source risk and requires reconciliation before any Stage-28 promotion.

### 10. Production stock state at evidence time
For `BR-01`, stock rows exist with positive quantities for many items.
For `VAN-VEH-92yrzb`, the observed stock rows are zero at evidence time.

This is a snapshot, not a historical proof of prior Loading behavior.

### 11. DirectReturn / Unloading distinction
The deployed `unload-runsheet` is a runsheet-level operation that:
- requires status `Loaded`
- restores `qty_loaded` to the main branch
- writes `Unloading` to inventory_log
- clears loaded quantities
- sets orders to `Pending`
- sets runsheet to `Picked`

This is current Production behavior. It does not by itself establish the business equivalence of Unloading and DirectReturn; those remain separate contracts.

### 12. Current decision
`TASK-028 = EVIDENCE / CONTRACT RECONCILIATION`

The evidence gate is now materially advanced, but implementation remains NO-GO because the following contract decisions must be reconciled before a permanent change:

1. Exact stock topology for Loading.
2. Whether Loading is a stock movement, operational state transition, or both.
3. Whether VAN/mobile branch receives stock during Loading or remains only custody metadata until a later movement.
4. Exact relationship between `qty`, `qty_picked`, `qty_loaded`, and `allocated_qty`.
5. Idempotency key / duplicate-post prevention for Loading and Unloading.
6. Atomic boundary across stock + run-sheet detail + order detail + runsheet state + accounting/backorder side effects.
7. Company-context source for every mutation; no hard-coded company id.
8. Whether accounting belongs to Loading or a later financial event.
9. Backorder creation boundary and idempotency.
10. Unloading reversal semantics and partial/unloaded quantities.

### 13. Safety conclusion
No Production mutation was performed.
No Edge Function was deployed.
No migration was applied.
No data was changed.

The correct next gate is a surgical contract decision based on this Production evidence, followed by a non-production validation path. The current `complete-loading` and `unload-runsheet` implementations must not be copied or patched opportunistically.

## Classification summary
- CONFIRMED: SMART ERP is active and contains RAWAEA production-shaped data.
- CONFIRMED: deployed Loading/Unloading functions exist and are active.
- CONFIRMED: deployed Loading/Unloading directly mutate stock and logs.
- CONFIRMED: deployed functions bypass `post_stock_movement`.
- CONFIRMED: `post_stock_movement` currently lacks Loading/Unloading types.
- CONFIRMED: deployed Loading/Unloading contain hard-coded legacy company id.
- CONFIRMED: VAN branch exists and is tied to the golden vehicle/driver fixture.
- UNKNOWN: whether the intended Production business contract is MAIN→VAN at Loading.
- UNKNOWN: final accounting boundary for Loading.
- UNKNOWN: final idempotency contract.
- CONFLICT: historical/current design intent versus deployed Loading stock topology.
- TARGET: future unified Stage-28 implementation.
- HISTORICAL: any original behavior not directly observed in current Production.
