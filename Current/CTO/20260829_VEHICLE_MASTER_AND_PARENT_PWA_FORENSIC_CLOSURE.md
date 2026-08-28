# RAWAEA ERP — Vehicle Master & Parent PWA Forensic Closure

## Event
- Event ID: `VEH-MASTER-20260829-001`
- Scope: `Current/PWA/main.html`, new `Current/PWA/vehicles.html`, Production `vehicles` / `vehicle_tracking` / mobile-branch contract.
- Evidence authority: CURRENT Production Supabase → CURRENT Git → persisted evidence → historical reports.

## Historical/Architectural Contract Reconstructed
1. The governing change sequence is UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH/CONTROL FLOW → COMPARE WITH TARGET → IDENTIFY GAP → DESIGN MINIMAL SAFE CHANGE → IMPLEMENT → VERIFY.
2. `vouchers.html` is an operational warehouse UI, not a Physical Stock engine. Physical movement remains `post_stock_movement`.
3. Vehicles were already part of the operational stock model: `setup-van-branch` creates/uses `VAN-{vehicle_code}` and `complete_runsheet_loading` moves stock MAIN → vehicle branch via `post_stock_movement`.
4. Direct Sale uses vehicle + direct-sales representative semantics in the current vouchers workflow; vehicle master must therefore feed the same `vehicles` table rather than create a parallel object.

## Production Forensic Snapshot Before Vehicle Feature
- Active companies observed in current Production: 1.
- `vehicles`: 0 rows.
- `vehicle_tracking`: 0 rows.
- `VAN-*` branches without a corresponding vehicle: 0.
- `vehicle_maintenance`: 0 rows before feature foundation.
- `vehicle_documents`: 0 rows before feature foundation.
- Existing MAIN stock rows: 17.
- `users` contains active `مدير مخازن` and `مدير عام` roles; both already have broad warehouse permissions.

## Changes Implemented
### Database
- Extended `vehicles` additively with vehicle type, operating mode, ownership, model year, VIN, fuel type, refrigerated flag, mobile stock flag, and explicit `mobile_branch_id`.
- Added indexes for company/status, company/type/mode, and company/driver.
- Added `vehicle_maintenance`, `vehicle_documents`, and `vehicle_status_history` as normalized future-ready fleet foundations.
- Enabled RLS on new fleet support tables and restricted direct access to service role.
- Added context triggers preventing company/driver/mobile-branch mismatches.
- Added vehicle audit trigger writing to existing `audit_log`.
- Hardened `vehicle_tracking.company_id` by removing the legacy hardcoded default and enforcing company/vehicle context at the data layer.

### Canonical Vehicle Creation Engine
- Added `public.create_vehicle_atomic(...)` as the single authoritative vehicle creation transaction.
- Authenticated callers are validated against `users.auth_id = auth.uid()`, company scope, active status, and existing Owner/manager permission semantics.
- Service-role callers remain supported for trusted backend workflows.
- Vehicle creation optionally creates or adopts exactly one deterministic `VAN-{vehicle_code}` branch.
- Existing matching VAN branch is adopted instead of duplicated.
- The vehicle receives `mobile_branch_id` and the vehicle branch is initialized with zero physical stock rows based on the company MAIN stock rows.
- No physical movement is created during master setup; inventory movement remains exclusively under `post_stock_movement`.

### Parent PWA
- Added `Current/PWA/vehicles.html` as the only Vehicle Master UI.
- The UI is company-scoped, supports smart search over vehicle code, plate, model, type, operation mode, VIN, and driver.
- Creation supports delivery, direct-sales, transport, refrigerated, mixed operation, capacity by weight/volume, driver assignment, and mobile-stock activation.
- The page uses the exact currently published Supabase anon configuration from the existing `main.html`; no key was invented or altered.
- Added a direct return-to-parent control.
- `Current/PWA/main.html` now exposes **إدارة السيارات والأسطول** under **إدارة المخازن والمخزون** and routes to the single `vehicles.html` implementation.
- Parent integration was applied through a one-shot repository workflow, validated by commit diff, then the workflow deleted itself; no permanent CI integration artifact was left behind.

## Verification
### Database transaction test
A transaction executed `create_vehicle_atomic` using the Production `warehouse.manager` authentication identity and an active driver from the same company. The test verified that the transaction could create the vehicle/branch/stock/status-history chain and then used `ROLLBACK`. Final Production state confirmed the test vehicle did not remain.

### Current Production post-change integrity
- `vehicles = 0`.
- `vehicle_tracking = 0`.
- `VAN-* branches = 0`.
- `vehicle_without_mobile_branch = 0`.
- `orphan_vehicle_tracking = 0`.
- No operational/test data was inserted permanently.

## Competitor-derived design decisions
- SAP models vehicles as resources with explicit capacity and availability, including mass/volume and richer resource characteristics; this supports separating vehicle identity from capacity/availability planning.
- Odoo Fleet integrates vehicles with services, odometer, contracts, documents and costs; RAWAEA now has data foundations for these capabilities without making them a second source of truth.
- Almarai’s current public reporting shows the strategic importance of high-frequency distribution, large vehicle fleets, depots, and cold-chain logistics; RAWAEA’s mobile branch/container model is aligned with this operational direction while remaining appropriate to the project’s current scale.

## Important Boundaries
- This closure does not claim full fleet dispatch/route optimization or live telematics; those require additional business contracts and telemetry sources not currently present in Production.
- It does not rename or replace the existing `vehicles` table.
- It does not create a second inventory engine.
- It does not clean historical stock rows by assumption.

## Final State
The Vehicle Master foundation is production-schema ready, company-safe, audit-aware, mobile-stock aware, and integrated into the parent PWA navigation. The current Production data remains clean and empty for vehicles, so the first real vehicle can now be created through the canonical transaction without requiring a later schema redesign.
