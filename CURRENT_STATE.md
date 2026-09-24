# FINAL AUTHORITATIVE POINTER — 2026-09-24 — VOUCHERS PICKSELECT + DIRECTRETURN FORENSIC CLOSURE

## Current continuation baseline
- System repository baseline before this state update: `0d5a57d7b263cbb10e5235db56175fc4b7825ed3`
- Parent of that baseline: `1e9fdfeda9a8d143acb58d0df76d632c2362cef9`
- Latest execution report:
  `doc/Draft/Reprots/EXECUTION_LOG_20260924_VOUCHERS_PICKSELECT_AND_DIRECTRETURN_FORENSIC_CLOSURE.md`
- Durable Production migration source recorded in Git:
  `supabase/migrations/20260924205655_fix_duplicate_directreturn_branch_in_voucher_create_core.sql`

## Mother current source
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `666f15bc84348b6fb44a5c565dcf2fb4fe1d0c98`
- Parent: `1c7f2596e7543a1ea4684d84171804b3e4d5a4d8`
- `companies/company-1/warehouse/vouchers.html` blob:
  `ab5d8ddc1934e3d48e4e0c60e18a4624dd1799d2`
- `companies/company-1/main.html` blob:
  `810e4f5440f5975f55099a124deb42b086a49183`
- Assistant changed `main.html`: NO.
- Assistant changed `vouchers.html`: NO; owner-controlled surgical patch remains pending.

## Direct runtime defect
- Console error:
  `Uncaught ReferenceError: vehicleRep is not defined`
- Function: `pickSelect(key,x)`
- Faulty stale block is the `vehicleRep.id / vehicleRep.name / vehicleRep.email` block around lines 3430–3446.
- Exact surgical repair is V-07 in the latest execution report.
- After in-memory application, complete embedded JavaScript parsing: PASS.
- `vehicleRep` no longer appears in `pickSelect` after V-07; other occurrences remain only in their original valid local scopes.

## Production closures executed
- Verified QA vouchers `IN-1` and `IN-2` were test artifacts.
- Reversed their combined net physical effect exclusively through `post_stock_movement`.
- Removed voucher headers/details and original/reversal inventory-log rows.
- Retained 3 immutable operation-identity tombstones with `voucher_id IS NULL`.
- Removed temporary forensic cleanup function.
- Restored the production delete/detail guards to their normal behavior.
- Final residue:
  - QA vouchers = 0
  - QA details = 0
  - QA inventory-log rows = 0
  - forensic cleanup function = 0
  - immutable QA operation tombstones = 3

## Production DirectReturn correction
- Proved the old CREATE defect transactionally before patch.
- Patched only the existing `create_manual_stock_voucher_atomic_core_12_20260828`.
- Removed the unreachable duplicate DirectReturn branch.
- Preserved contract: Vehicle -> Branch.
- Preserved existing DirectReturn driver semantics.
- No new Edge Function.
- `post_stock_movement` unchanged.
- Full temporary E2E after the fix:
  CREATE -> SEND -> RECEIVE -> COMPLETE -> assertions -> ROLLBACK = PASS.
- No persistent QA rows after rollback.

## Production DirectSale verification
- Current active Master Assignment:
  - rep: `vansales@rawaea.com`
  - rep_id: `111b0730-a977-4d11-bcd0-2427b178a9e5`
  - vehicle: `CHV-2025-01`
  - vehicle_id: `69b08188-60ee-43af-9644-e1626a85bfa0`
  - mobile branch: `VAN-CHV-2025-01`
  - mobile_branch_id: `2fffcf58-be04-4599-a289-8791362398ff`
  - vehicle.driver_id = NULL
  - assignment is Active / Primary / end_at NULL
- DirectSale CREATE -> SEND -> Replay -> COMPLETE transaction test = PASS.
- Source stock delta = -1.
- Vehicle mobile branch stock delta = +1.
- Duplicate replay protection = PASS.
- Transaction rolled back completely.

## Current architecture rules
- Physical stock movement remains:
  `post_stock_movement -> stock_branches + inventory_log`
- `reserve_stock` remains reservation-only.
- Do not reintroduce DirectSale dependency on `vehicles.driver_id`.
- Do not create another Edge Function for vouchers.
- Do not modify `post_stock_movement`.
- Do not reapply already-closed Report334/336/340 changes.
- Do not modify Mother `main.html` in this closure.
- Do not modify `vouchers.html` automatically; owner must apply V-07.
- Do not convert DB/RPC E2E to Browser E2E.

## Browser status
- Authenticated Browser E2E after V-07: OPEN / UNVERIFIED.
- Published artifact verification for the corrected Vouchers source: OPEN / UNVERIFIED.

## Next session
1. Fetch this CURRENT_STATE first.
2. Fetch current System HEAD and parent.
3. Fetch Mother HEAD, parent, vouchers blob, and main blob.
4. Check whether owner applied V-07 exactly before proposing it again.
5. Parse complete vouchers.html.
6. Run authenticated browser E2E against the published artifact.
7. Verify Rep -> Vehicle Master mapping in the browser network flow.
8. Verify DirectSale and DirectReturn UI end-to-end.
9. Only after browser closure open the next real closure unit.

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — REPORT340

## CURRENT SESSION TRUTH — START HERE

### System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Current HEAD before this state update: `9542abdfc5cbd521e7bdd94bb1f5d4dc63ce4c16`
- Parent: `9ce3652fb144c75b98cb77d784d1a1d276d4464c`
- Report340: `doc/Draft/Reprots/Report340_VOUCHERS_MASTER_ASSIGNMENT_AND_VAN_SALES_FORENSIC_CLOSURE_20260924.md`
- Setup Van Branch source commit: `223c53e35384efaba223999d2608d7c3f83b2eec`
- QA cleanup source commit: `9ce3652fb144c75b98cb77d784d1a1d276d4464c`

### Mother Git
- Repository: `papamohammed77-glitch/erp-frontend`
- Latest HEAD verified: `1c7f2596e7543a1ea4684d84171804b3e4d5a4d8`
- Parent: `cd67be47d1a36e42b3c5b8738d8ba1475f95ef86`
- Current `main.html` blob: `810e4f5440f5975f55099a124deb42b086a49183`
- Current standalone `companies/company-1/warehouse/vouchers.html` blob: `287f9900efdf1ee595f6537e9d230ef06e347c06`
- Current standalone `companies/company-1/sales/van-sales.html` blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`
- Neither `main.html` nor `warehouse/vouchers.html` was modified by the assistant.

### Production
- Supabase project: `fiilmooggumokxanwiyx`
- Existing `create-stock-voucher`: version 12, unchanged.
- Existing `fleet_query`: active control-plane read API.
- Existing `fleet_command_atomic`: active control-plane write API.
- Existing `setup-van-branch`: upgraded to version 5; no new Edge Function created.
- `setup-van-branch` deployed SHA256: `71986370ae16e744332bc93f2b533dddf89433ef2cf1d34445da9c474e2c3f25`
- Active Master assignment:
  - vehicle `CHV-2025-01`
  - vehicle_id `69b08188-60ee-43af-9644-e1626a85bfa0`
  - Direct Sales Rep `vansales@rawaea.com`
  - rep_id `111b0730-a977-4d11-bcd0-2427b178a9e5`
  - assignment_id `861ecd15-5ab6-4e53-8995-5d2d97570c3e`
  - start_at `2026-09-24 18:57:12.987021+00`
  - is_primary = true
  - end_at = null.
- The real vehicle `CHV-2025-01` has `driver_id = NULL`; therefore Direct Sales Rep must not be resolved through `vehicles.driver_id`.

### Production changes executed in this session
1. Updated existing `setup-van-branch` to resolve Direct Sales Rep → Vehicle through `fleet_vehicle_sales_rep_assignments`, while preserving driver-based fallback for non-Direct-Sales users.
2. Cleaned the proven QA fixture `FRD-2025-02 TEST` and its mobile branch, stock fixture rows, vehicle status history and QA audit rows.
3. No change to `fleet_query`, `fleet_command_atomic`, `post_stock_movement`, `create-stock-voucher`, DirectReturn semantics, or the Mother.
4. Created Report340.

### Production verification
- `fleet_query('direct_sales_rep_assignments')` with the Vouchers user actor returned the active Rep→Vehicle assignment.
- The same Fleet query with the Van Sales user actor returned the same active assignment.
- Production transactional E2E:
  - DirectSale CREATE with `to_id = NULL` + `rep_id = vansales` = success.
  - Server resolved `to_id` to `CHV-2025-01`.
  - Draft status persisted.
  - SEND = movement_count 1.
  - Source stock delta = -1.
  - REPLAY = `duplicate=true`.
  - Entire test ROLLBACK = no residue.
- Before/after test stock snapshot: 11 → 10 during SEND and then rolled back.
- Current QA fixture after cleanup:
  - test vehicle = 0
  - test mobile branch = 0
  - test stock rows = 0
  - matching QA audit rows = 0.
- Current Production vehicles = 1.
- Current Production branches = 3.
- No current DirectSale drafts exist.

### Current defect and owner-only source patch
The standalone Vouchers source still contains the old DirectSale assumption:
`vehicle.driver_id === selectedRep.id`

The necessary owner-applied surgical repair is documented in Report340 as PATCH V-01 through V-09:
- add Master assignment maps;
- read `fleet_query('direct_sales_rep_assignments')`;
- filter DirectSale reps to those with active Master vehicle;
- resolve Rep→Vehicle from Master assignment, never from `driver_id`;
- auto-fill and lock the vehicle after Rep selection;
- reconcile stale vehicle values to the authoritative assignment;
- allow DirectSale submit to rely on Master resolution;
- keep DirectReturn driver semantics unchanged.

### Browser state
- Authenticated Browser E2E against the published Vouchers/Mother artifact: OPEN / UNVERIFIED.
- DB/RPC/Deployment evidence must not be converted to Browser PASS.

### Next session
1. Fetch CURRENT_STATE.
2. Fetch System HEAD + parent + Report340.
3. Fetch Mother HEAD + parent + current blobs.
4. Read `companies/company-1/warehouse/vouchers.html` completely.
5. Apply only PATCH V-01..V-09 to that owner-controlled file.
6. Re-read the whole file and verify no DirectSale branch still resolves vehicle through `driver_id`.
7. Run authenticated Browser E2E.
8. Verify:
   - Fleet query call;
   - Rep→Vehicle autofill;
   - DirectSale CREATE;
   - Draft no stock mutation;
   - SEND one physical movement;
   - REPLAY duplicate;
   - Van Sales startup resolves the same vehicle through `setup-van-branch`.
9. Do not touch Mother `main.html` unless new current-source evidence contradicts the current verified state.
10. Do not create another Edge Function.

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — REPORT339

## Current truth after Report339
### System Git
- HEAD after report creation: `62422bfbbcd4c8a7d31cca2cde9fc4fcf2fba7df`
- Parent: `dfeb5ad0fe17202df38f3cb3ac3e82a655afed67`
- Previous source commit containing the vouchers change: `eb22f825a145c88b27a3dd791ad189d767b2c8ff`
- `Current/PWA/vouchers.html` blob: `d32d57eada0d3fdac4ce45dc469c6eeab19828a3`
- Report: `doc/Draft/Reprots/Report339_MOTHER_FLEET_DIRECTSALE_OPTIONAL_DOCUMENT_VOUCHERS_AUTOBIND_FORENSIC_CLOSURE_20260924.md`

### Mother Git
- Current HEAD verified: `f26e7e995706ea45ad586a31238178d9c7891e71`
- Parent: `d13537d0f4d8d7f0e2c0ac6d25d779bc4062760e`
- Current `companies/company-1/main.html` blob: `6885ccdbb44344ae6aa839fbc7a4ccb93494bb24`
- Mother `main.html` was NOT modified by assistant.

### Production
- Supabase project: `fiilmooggumokxanwiyx`
- No new Edge Function.
- `create-stock-voucher` deployed version: 12.
- Fleet control plane: `fleet_query` + `fleet_command_atomic`.
- Physical stock authority: `post_stock_movement`.

## Production changes completed in Report339
1. Created `public.fleet_vehicle_sales_rep_assignments`.
2. Extended existing `VEHICLE_OPERATION_BIND` with `DIRECT_SALE_MASTER`.
3. Extended `fleet_query` with direct-sales-rep assignment read model and vehicle/detail projections.
4. Extended `create_manual_stock_voucher_atomic_core_12_20260828` so DirectSale can omit `to_id` and resolve the active mobile vehicle from the Master assignment.
5. Reordered DirectSale actor/rep validation in the create core.
6. Existing `create-stock-voucher` version 12 was verified as already passing `rep_id` and `operation_id`; no Edge Function creation was needed.
7. `Current/PWA/vouchers.html` was updated to auto-map Rep -> Vehicle and stop requiring a vehicle for DirectSale at UI submit.

## Verified
- Master binding: PASS.
- Master binding replay with same operation_id/payload: `duplicate=true`.
- Fleet assignment query: PASS.
- Vehicle detail projection: PASS.
- DirectSale CREATE with omitted vehicle: PASS; server resolved vehicle from Rep->Vehicle mapping.
- Draft CREATE produced no inventory movement and no journal entry.
- QA data from this session cleaned: vouchers 0, QA operation identities 0, QA fleet registry 0, QA inventory_log 0, QA audit rows 0, QA assignment rows 0.
- Protected delete trigger re-enabled.

## Still OPEN
- Owner-only Mother `main.html` PATCHes in Report339:
  PATCH 1 around line 29233: make DirectSale document option optional.
  PATCH 2 around line 29290: make DirectSale reference editable/optional.
  PATCH 3 around line 29313 inside `openVehicleOperationLinkForm()`: choose `DIRECT_SALE_MASTER` when no voucher is selected and pass optional reference.
- Published Mother artifact verification.
- Authenticated Browser E2E.

## Do not redo
- DirectSale driver decoupling.
- DirectSale custodian identity persistence.
- Physical stock centralization.
- Legacy manual-voucher update retirement.
- DirectReturn driver semantics.
- Do not create another Edge Function for this capability.
- Do not modify `post_stock_movement`.

## Next session execution
1. Fetch this file first.
2. Fetch current System HEAD/parent and Mother HEAD/parent/blob.
3. Verify Report339 PATCH 1/2/3 status in Mother before issuing them again.
4. Verify the published Mother artifact.
5. Apply/verify the exact owner-only main.html surgical replacements.
6. Run authenticated Browser E2E.
7. Only after Browser verification, open the next closure unit.

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — POST-REPORT338

## Session authoritative truth
### System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Current HEAD: `1ca51a461608f25a730a237f28e891a784d6ca84`
- Parent: `b5772877db399028be13be1750178847cb18605e`
- Report: `doc/Draft/Reprots/Report338_MOTHER_FLEET_PERMISSION_BOUNDARY_AND_VOUCHERS_DIRECTSALE_FORENSIC_CLOSURE_20260924.md`

### Mother Git
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `9257912dddb3b432a7d6979f41c68e25570ce3f5`
- Parent: `f32f970ad395ad163f770d3cdf56f9015198e3a6`
- Current `companies/company-1/main.html` blob: `617e6d9ac123e1112dc37bea0097b59b0d0509cb`
- `main.html` was NOT modified by assistant.
- PATCH-337 was already applied in Mother commit `f32f970ad395ad163f770d3cdf56f9015198e3a6`.

### Current separate-app source
- `Current/PWA/vouchers.html`
- Current blob: `3e93448feac5c74f4f09bca605bb722db755ada0`
- Source fix commit: `cb6f0b500ea4dbae43e87214ac59da2c278b0597`
- DirectSale no longer enforces `vehicle.driver_id = sales_rep`.
- DirectSale now sends `rep_id`.
- Create retry now carries `operation_id`.

### Current Production
- Supabase project: `fiilmooggumokxanwiyx`
- Fleet control plane: `fleet_query` + `fleet_command_atomic`
- Binding command: `VEHICLE_OPERATION_BIND`
- No new Edge Function created.
- Current deployed `create-stock-voucher` version: 12.

### Production E2E verified in this session
- Mother Fleet BIND by `finance-manager@rawaea.com`: PASS.
- Replay: `duplicate=true`.
- BIND stock delta: 0.
- BIND journal entries/lines delta: 0.
- Vouchers DirectSale CREATE → SEND → REPLAY: PASS.
- CREATE persisted `rep_id` as custodian identity.
- SEND source branch item 1001: -1.
- SEND vehicle mobile branch item 1001: +1.
- inventory_log: +1.
- journal_entries: 0.
- journal_lines: 0.
- Replay: `duplicate=true`.
- All QA transactional test data rolled back.
- Current QA voucher / operation / inventory residues from this session: 0.

### Mother access contract — current session
- Operational employees execute through separate apps.
- Operational employees must not use Mother `main.html` for field execution.
- Production capability `VEHICLE_OPERATION_BIND` remains available to the operational consumer layer where required.
- Mother Fleet navigation/read must remain limited to its historical management audience.

### Owner-only Mother patch remaining
PATCH-338:
1. Restore the historical Fleet navigation permission line.
2. Replace `canBindVehicleOperation()` with the management-only capability gate.
3. Remove operational permissions from the `canRead()` return block.

Do NOT change:
- `command()`
- `VEHICLE_OPERATION_BIND` special case
- Vehicle Detail master-data separation
- `openVehicleOperationLinkForm()`
- Fleet query/reporting contracts
- DirectReturn driver semantics
- `post_stock_movement`
- create/send/receive inventory writers

### Browser state
- Authenticated Browser E2E for the published Mother artifact: OPEN / UNVERIFIED.
- Do not convert source/DB/RPC PASS into Browser PASS.

### Immediate next session
1. Fetch this CURRENT_STATE first.
2. Fetch Mother HEAD + parent + main blob.
3. Verify whether PATCH-338 was applied before issuing it again.
4. Verify published artifact.
5. Run authenticated Browser E2E.
6. Only after that, open the next closure unit.

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — POST-REPORT337 FINAL STATE

## Final System Git
- HEAD: `44c377a89eb0e66e6007debfba61cfd098618a1c`
- Parent: `016e62148fa82c6edb1d0ebd82efa170dc9924d4`
- This state file is the latest authoritative continuation pointer after Report337.

## Final Mother Git
- HEAD: `7ca0aa1324fe1d925a752f559e990e92e29a384b`
- Parent: `854bc0d05389131782529e1b68801e4d651286c8`
- `companies/company-1/main.html` blob: `95cf0d8dfcb87f78962ae89038f141bcdb2c29a6`
- `main.html` remains untouched by the assistant.
- Owner-only PATCH-337 is documented in Report337.

## Final Production
- `VEHICLE_OPERATION_BIND` operational authorization = deployed.
- Warehouse Supervisor E2E = PASS.
- Vouchers operator E2E = PASS.
- DirectSale CREATE → BIND → REPLAY → SEND = PASS.
- QA residue = 0.
- Browser authenticated E2E = OPEN / UNVERIFIED.

## Immediate next action
Owner applies PATCH-337 to Mother `main.html`, then the next session verifies the new Mother HEAD/source/published artifact before any further change.

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — REPORT337 FLEET OPERATION BINDING AUTHORIZATION CLOSURE

## Current primary-source identities
### System Git
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Current HEAD: `016e62148fa82c6edb1d0ebd82efa170dc9924d4`
- Parent: `7030f026feeb5b89e097be28ef43f917e5f36eae`
- Report337 added: `doc/Draft/Reprots/Report337_MOTHER_FLEET_OPERATION_BINDING_AUTHZ_FORENSIC_CLOSURE_20260924.md`
- Production authorization source migration:
  `supabase/migrations/20260924164239_open_vehicle_operation_bind_for_operational_roles_20260924.sql`
- Production-applied cleanup source reconciled:
  `supabase/migrations/20260924164848_cleanup_qa_orphan_operation_identities_and_audit_20260924.sql`
- An unapplied temporary cleanup filename was removed from Git to prevent source/Production drift.

### Mother Git
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `7ca0aa1324fe1d925a752f559e990e92e29a384b`
- Parent: `854bc0d05389131782529e1b68801e4d651286c8`
- Current `companies/company-1/main.html` blob:
  `95cf0d8dfcb87f78962ae89038f141bcdb2c29a6`
- Mother `main.html`: NOT modified by assistant.

## Production truth
- Supabase project: `fiilmooggumokxanwiyx`
- Fleet Control Plane: `fleet_query` + `fleet_command_atomic`
- Binding command: `VEHICLE_OPERATION_BIND`
- No new Edge Function created.

### Production changes completed
1. `20260924164239_open_vehicle_operation_bind_for_operational_roles_20260924`
   - Fleet read access extended to operational warehouse/voucher/transfer/direct-sale/van-sales/delivery/vehicle-count contexts.
   - Only `VEHICLE_OPERATION_BIND` receives the expanded command authorization.
   - Existing Fleet master-data command authorization remains unchanged.
2. `20260924164831_cleanup_orphaned_qa_stock_voucher_operation_artifacts_20260924`
   - Exists in Production migration history.
   - Exact source content was not recoverable from current Git; it was not reconstructed by assumption.
3. `20260924164848_cleanup_qa_orphan_operation_identities_and_audit_20260924`
   - Applied to remove only orphaned QA operation identities and QA stock-voucher audit records.
   - Current QA residue verified at zero.

## Production verification
### Warehouse Supervisor
- `warehouse.supervisor@rawaea.com`
- `fleet_query(vehicle_operation_candidates)` = PASS
- `VEHICLE_OPERATION_BIND` = PASS
- replay = `duplicate=true`
- vehicle detail projection = PASS
- bind caused no stock movement and no GL movement.

### Vouchers operator
- `vouchers@rawaea.com`
- Fleet candidate query = PASS
- `VEHICLE_OPERATION_BIND` = PASS
- persistence = PASS
- rollback = PASS.

### DirectSale full E2E
`CREATE → BIND → REPLAY → SEND` = PASS
- source branch stock delta = -1
- vehicle mobile branch stock delta = +1
- inventory_log delta = +1
- custody/driver ledger delta = +1
- journal_entries delta = 0
- journal_lines delta = 0
- rollback = PASS.

## Data hygiene
- QA vouchers = 0
- QA stock_voucher_operations = 0
- QA inventory_log = 0
- QA fleet registry = 0
- QA stock-voucher audit residue = 0.

## Main.html current defect and owner-only surgical repair
The current Mother source still contains a permission-model mismatch:
- Fleet navigation excludes operational permissions.
- `canRead()` excludes operational permissions.
- Vehicle Detail link button is gated by `canManage()`.
- `openVehicleOperationLinkForm()` uses `canManage()`.
- `command()` uses `canManage()` for every Fleet command.

This causes an operational warehouse/voucher user to lose the Vehicle Operation Binding capability even though Production Control Plane can now authorize the specific binding command.

### PATCH-337 required in Mother
Owner must make exactly these six surgical changes documented in Report337:
1. Fleet navigation permission line.
2. Add `canBindVehicleOperation()` helper before `canRead()`.
3. Expand only the return block inside `canRead()`.
4. Special-case only `VEHICLE_OPERATION_BIND` in `command()`.
5. Move only the Vehicle Operation Binding button out of the `canManage()` bundle while keeping Fleet master-data buttons unchanged.
6. Change only the guard line inside `openVehicleOperationLinkForm()` to `canBindVehicleOperation()`.

No other Mother business logic is approved for modification in this closure.

## Browser status
- Authenticated Browser E2E against the published Mother artifact remains OPEN / UNVERIFIED.
- DB/RPC E2E must not be converted to Browser PASS.

## Competitive context
The current architecture remains consistent with documented patterns in:
- Odoo Fleet/Services/Odometer
- Dynamics Transportation Management
- SAP Transportation Management Resources
- Daftra Transportation
- Manager.io References / Inventory Locations / Custom Fields.

Future competitive backlog, separate from this closure:
- trip cost
- cost/km
- fuel economics
- maintenance allocation
- capacity utilization
- route plan vs actual
- vehicle availability
- asset lifecycle/depreciation
- route profitability
- vehicle/operation/document 360 reporting.

## Continuity rules
Start every next session from:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

Do not:
- reapply Report334.
- reapply Report336 DirectSale driver/custodian fixes.
- create another Edge Function for this capability.
- modify `post_stock_movement`.
- change DirectReturn driver semantics.
- treat Browser as verified before authenticated browser evidence exists.

After Owner applies PATCH-337:
- fetch the new Mother HEAD/blob;
- parse the complete `main.html`;
- verify the exact six substitutions;
- verify the published artifact;
- run authenticated Browser E2E;
- verify Fleet query and command network calls;
- verify BIND has no stock/GL side effects;
- then execute the next open closure only.

---
# FINAL AUTHORITATIVE POINTER — 2026-09-24 — REPORT336 FINAL GIT POINTER
## Last verified System repository state
- Git HEAD immediately before this state update: a806fa54090336324018cf7cb691788cab81d01b
- Parent: d71727f3a2edf03b586aae9fb6cd74ec94ccfea7
- This pointer follows the production-backed migrations, Report336 finalization, and migration filename reconciliation.
- Mother HEAD: 111a6876ddf38394989896f64767170b77c3231e
- Mother parent: 26d4d4d347be477b69482e75627154aa6565d5ac
- Mother main.html blob: 3d1ac970c0e81d0a581045ce79b140708ccfa3af
- Mother main.html remains unmodified.

## Production final truth
- 20260924155735 decouple DirectSale operation rep from vehicle.driver_id.
- 20260924155822 persist DirectSale/DirectReturn custodian_user_id on create.
- 20260924160919 retire legacy manual voucher update overload.
- DirectSale E2E CREATE -> BIND -> REPLAY -> SEND: PASS.
- Stock: source -1 / vehicle mobile branch +1.
- inventory_log +1 / driver_ledger +1 / G/L entries 0 / G/L lines 0.
- QA residual counts: vouchers 0, operations 0, inventory 0, ledger 0, fleet registry 0.
- Production stock writer remains centralized through post_stock_movement.
- No direct inventory_log writer outside the central movement path was found.
- reserve_stock and release_stock_reservation affect allocated_qty only.
- create_vehicle_atomic and setup_van_stock only initialize stock rows with qty=0.
- Legacy update overload has been removed.
- The 10-argument create compatibility overload remains because inventory_stock_request_engine uses it for Transfer conversion.

## Main.html decision
- No new surgical patch.
- Report334 Owner changes remain the current Mother implementation.
- Do not reapply Report334.
- Browser authenticated E2E remains OPEN / UNVERIFIED.

## Primary continuity
- Report336: doc/Draft/Reprots/Report336_MOTHER_FLEET_DIRECTSALE_OPERATION_REP_VEHICLE_FORENSIC_CLOSURE_20260924.md
- Production migration files:
  - supabase/migrations/20260924155735_decouple_directsale_operation_rep_from_vehicle_driver_20260924.sql
  - supabase/migrations/20260924155822_persist_directsale_operation_custodian_on_create_20260924.sql
  - supabase/migrations/20260924160919_retire_legacy_manual_voucher_update_overload_20260924.sql

---
# FINAL AUTHORITATIVE POINTER — 2026-09-24 — REPORT336 GLOBAL WRITER CLOSURE
## Additional closure after Global Writer Discovery
- Production migration: retire_legacy_manual_voucher_update_overload_20260924
- Legacy update_manual_stock_voucher_atomic 12-arg overload: RETIRED; no authenticated/service_role Execute and no internal Consumer found.
- Global physical writer scan: no direct inventory_log writer outside post_stock_movement; reserve/release only change allocated_qty; vehicle/van setup only initialize stock rows at qty=0.
- Compatibility create_manual_stock_voucher_atomic 10-arg overload remains because inventory_stock_request_engine uses it for Transfer conversion; it is not a parallel physical writer.
- Final Production stock movement architecture remains post_stock_movement -> stock_branches + inventory_log.
- DirectSale CREATE/UPDATE driver coupling remains removed; DirectSale custodian_user_id remains persisted from p_rep_id.
- main.html remains unmodified; no new surgical patch is justified.
- Browser authenticated E2E remains OPEN/UNVERIFIED.

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — REPORT336
## Current Production Closure — Mother Fleet / DirectSale Operation Identity

### Current Git at end of execution chain
- System documentation chain: 3ede2d67cb1fa097483c9a76f7052ae903706584 -> 0cdac99939b12ce86d35207a2c76ee0be7595552 -> e97437e4e1c5abb3eedf41c080f0ef17e6f4c549
- Last Mother HEAD verified: 111a6876ddf38394989896f64767170b77c3231e
- Mother parent: 26d4d4d347be477b69482e75627154aa6565d5ac
- main.html blob: 3d1ac970c0e81d0a581045ce79b140708ccfa3af
- main.html was NOT modified.

### Production changes executed directly
1. 20260924155735_decouple_directsale_operation_rep_from_vehicle_driver_20260924
   - DirectSale CREATE no longer requires vehicles.driver_id = Direct Sales Rep.
   - DirectSale UPDATE no longer requires vehicle driver equality.
   - DirectReturn driver coupling remains intact.
2. 20260924155822_persist_directsale_operation_custodian_on_create_20260924
   - DirectSale/DirectReturn CREATE persists p_rep_id into stock_vouchers.custodian_user_id.

### Current verified contract
DirectSale operation identity:
- Vehicle = stock_vouchers.to_id
- Direct Sales Rep / custody actor = stock_vouchers.custodian_user_id
- Physical movement = post_stock_movement -> stock_branches + inventory_log
- Fleet binding = fleet_command_atomic / VEHICLE_OPERATION_BIND

### Production E2E
CREATE -> BIND -> REPLAY -> SEND = PASS
- BIND = success=true
- REPLAY = duplicate=true
- SEND = success=true, status=Sent, movement_count=1
- Stock delta: BR-01 -1; vehicle mobile branch +1
- inventory_log delta: +1
- driver_ledger delta: +1
- journal_entries delta: 0
- journal_lines delta: 0
- QA rollback residue: 0
- BR-01 item 1001 after rollback: 11
- mobile vehicle branch item 1001 after rollback: 0

### Mother main.html decision
No new surgical patch is justified.
The existing owner-applied Report334 implementation already contains:
- openVehicleOperationLinkForm()
- voucher_id binding
- direct_sales_rep_id binding
- operation_id
- VEHICLE_OPERATION_BIND
- vehicle detail direct_sales reporting
Do not reapply Report334.

### Browser status
Published artifact identity and authenticated Browser E2E remain OPEN/UNVERIFIED.
Never convert DB/RPC/source E2E to Browser PASS.

### Primary reports
- Report335: doc/Draft/Reprots/Report335_MOTHER_FLEET_VEHICLE_OPERATION_LINK_CURRENT_RECONCILIATION_E2E_20260924.md
- Report336: doc/Draft/Reprots/Report336_MOTHER_FLEET_DIRECTSALE_OPERATION_REP_VEHICLE_FORENSIC_CLOSURE_20260924.md

### Next CTO resumption
Verify CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT first.
Do not reintroduce vehicle.driver_id coupling for DirectSale.
Do not change main.html unless contradictory current-source evidence appears.
Do not create a new Edge Function for this capability.

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — POST-REPORT335
## Current System HEAD
- HEAD: `e6e96b34289dcb14186453ddd6ee323164b2fdc2`
- Parent: `71c698206026a38b29ffd215b6babaee7d77cbe9`
- Latest commit: `state: finalize Report335 current Mother fleet E2E checkpoint`

## Current Closure Pointer
- Report335: `doc/Draft/Reprots/Report335_MOTHER_FLEET_VEHICLE_OPERATION_LINK_CURRENT_RECONCILIATION_E2E_20260924.md`
- Mother current HEAD: `111a6876ddf38394989896f64767170b77c3231e`
- Mother main.html blob: `3d1ac970c0e81d0a581045ce79b140708ccfa3af`
- Report334 Mother patches are already Owner-applied; do not reapply.