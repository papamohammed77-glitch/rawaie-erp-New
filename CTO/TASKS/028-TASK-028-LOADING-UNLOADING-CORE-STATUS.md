# TASK-028 — STAGE-28 Loading / Unloading Core

## Current gate
EVIDENCE / CONTRACT RECONCILIATION

## Current verified structure
- `public.runsheets` is the operational anchor for Loading / Unloading.
- Proven foreign keys include `vehicle_id -> vehicles.id`, `driver_id -> users.id`, `loader_id -> users.id`, `picker_id -> users.id`, `deliverer_id -> users.id`, and `return_handler_id -> users.id`.
- `runsheets` has an audit trigger on INSERT/UPDATE/DELETE.
- The experimental fixture `RS-1` was created by the master system and linked to the official test vehicle `VEH-92yrzb`.
- The driver/representative was later assigned successfully at DB level using `users.id`.

## Current UI correction
`Current/PWA/main.html` now:
- resolves `company_id` from `app_settings` for the Runsheet helper;
- loads active users including role `مندوب بيع مباشر`;
- uses `users.id` as the dropdown value for `runsheets.driver_id`;
- resolves the driver display name by `users.id`;
- filters active vehicles by the same company context.

Original UI remains untouched under `Original/PWA/main.html`.

## Current backend correction
`Current/Edge_Functions/create-runsheet.ts` was surgically corrected to resolve `company_id` from `app_settings.company_id` instead of the historical hard-coded zero UUID.

Original remains untouched under `Original/Edge Functions/create-runsheet.ts`.

## Critical historical finding
The original `complete-loading` directly decrements MAIN `stock_branches`, writes `inventory_log`, updates run-sheet/order quantities, and creates an accounting entry. This is NOT automatically the target design.

The original `unload-runsheet` directly increments MAIN stock, writes `inventory_log`, clears loaded quantities, resets orders, and returns the Runsheet to `Picked`. This is NOT automatically the target design.

## Architectural warning
The current historical Loading implementation may conflict with the already-established custody model:
- `DirectSale = MAIN -> VAN custody`
- `VanSale = VAN -> customer`
- `DirectReturn = VAN -> MAIN`

Therefore Loading must not be patched blindly into another MAIN deduction path. The target contract must explicitly answer whether Loading is:
1. a physical movement MAIN -> VAN/mobile branch, or
2. an operational step over a custody stock state already created by DirectSale.

## Mandatory next evidence
Before modifying `complete-loading` or `unload-runsheet`, collect the exact Production schema/constraints for:
- `runsheets`
- `run_sheet_details`
- `orders`
- `order_details`
- `stock_branches`
- `inventory_log`
- any loading/unloading related functions/triggers

Also capture the exact current status/rows for the experimental `RS-1` and its details.

## Current conclusion
`create-runsheet` Company Context defect: corrected in Current candidate.
`main.html` Driver/Vehicle lookup defect: corrected in Current candidate, syntax repaired and rechecked.
`complete-loading`: NOT READY FOR PATCH.
`unload-runsheet`: NOT READY FOR PATCH.

Next gate: Production schema + Runsheet detail contract + one clean fixture for the Loading boundary.
