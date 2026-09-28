# FINAL AUTHORITATIVE POINTER — 2026-09-28 — REPORT348 SOURCE RESPONSIBILITY GAP CLOSED

## CURRENT REALITY — START HERE

### System Git
Current HEAD after Report348:
d813d1fd9bd8d2e478f3de6330f2abf63d9cd098

Parent:
515c508d6b6d4a15bc627d0720b92079b1153dbc

Latest change:
Report348 forensic closure + source surgical patches.

### Frontend Git
HEAD:
f07bdcc4abbbe899af569f8bfaccde04df279416

Parent:
cc35f3a9da6ababf4c8cd87b05ab93539cdae087

vouchers.html:
9e3a9cbd0124639934cdf98abc9ec579f4b19f61

main.html:
810e4f5440f5975f55099a124deb42b086a49183

picker.html:
c7ad267d852d415b680aed7716833eea9bcffdf6

van-sales.html:
8d61382a8e0025a0d079e71dd94f33d106d9088e

### Production correction
A real source-responsibility security gap was found after Report347:

- vouchers.html allowed warehouse-voucher users with activeWarehouseRole=أذونات to treat every company branch as an allowed transfer source.
- pickArr() returned allBranches for wsFrom + Transfer.
- pickSelect() incorrectly applied sender branch scope to Transfer destination.
- Production trigger did not verify sender authorization on from_id during Draft → Sent.

Production fix applied directly to the existing function:
public.enforce_transfer_responsibility_contract()

New guard:
non-admin sender must be authorized for the source branch before Draft → Sent.

No new Edge Function.
No new stock core.
No new RPC.

### Production result
Negative:
BR-2 warehouse user attempting BR-01 → BR-2 send = PASS BLOCK.
Message: مرسل التحويل غير مخول للعمل على فرع المصدر

Positive:
BR-01 → BR-2 = PASS.

Verified:
- Create PASS
- Send PASS
- receiver binding PASS
- sender Receive rejected PASS
- partial Receive PASS
- idempotent replay PASS
- remainder Receive PASS
- Complete PASS
- final Completed PASS
- stock delta 1001: 8→7 / 3→4
- stock delta 1003: 8→7 / 2→3
- transaction rolled back
- current Transfer QA residue = 0

### Existing Production ACL
public.enforce_transfer_responsibility_contract():
- postgres EXECUTE = true
- service_role EXECUTE = true
- authenticated EXECUTE = false
- anon EXECUTE = false
- PUBLIC EXECUTE = false

### Source owner patches
Do not modify from assistant side.

New owner patches:
- T-09 allowedBranch: remove Transfer all-company bypass.
- T-10 pickArr: wsFrom + Transfer must return userBranches.
- T-11 pickSelect: wsTo + Transfer must not be rejected by sender allowedBranch.

Previous Report347 patches T-06/T-07/T-08 remain owner-only and must not be repeated blindly.

### Protected files
- main.html: DO NOT TOUCH.
- vouchers.html: owner applies only documented surgical replacements.
- picker.html: no change.
- van-sales.html: no change.
- no new Edge Function.

### Browser / Deployment
- GitHub Warehouse Vouchers Browser E2E run 36407039250 is FAILED.
- Failure is in the workflow source gate (INLINE_SCRIPT_NOT_FOUND), not a Transfer business assertion.
- Current source blob contains the inline script.
- Authenticated live browser remains UNVERIFIED.
- Published artifact verification remains OPEN.

### QA cleanup
Temporary Transfer QA transactions from this session were rolled back.
No current IN-8/IN-9 Transfer vouchers remain.

Legacy SupplierReturn QA fixtures remain outside this scope because deleting completed test postings without an independent accounting/inventory reversal would be unsafe.

### Current report
doc/Draft/Reprots/Report348_WAREHOUSE_VOUCHERS_TRANSFER_SOURCE_RESPONSIBILITY_FORENSIC_CLOSURE_20260928.md

### Next exact continuation
1. Read this CURRENT_STATE first.
2. Verify current Frontend HEAD/parent and vouchers blob.
3. Check T-06..T-11 against current source before issuing any patch.
4. Apply only owner-controlled source patches in vouchers.html.
5. Parse complete vouchers.html.
6. Run authenticated browser E2E.
7. Verify served artifact.
8. Close Transfer Browser boundary only after live UI proof.
9. Then open the next real Business Contract gap.

---
# FINAL AUTHORITATIVE POINTER — 2026-09-28 — REPORT347 TRANSFER CURRENT FORENSIC CLOSURE

## CURRENT REALITY — START HERE

### Latest System Git after this session
HEAD:
f55b15ee2dffabc5d98bcde02c6245fbbb59481e

Parent:
eba0d43b88e258f31fc99627f62ff93fdf0196dd

Latest commit:
report: close current branch transfer forensic gap and document surgical owner patches

### Current Frontend Git
HEAD:
f07bdcc4abbbe899af569f8bfaccde04df279416

Parent:
cc35f3a9da6ababf4c8cd87b05ab93539cdae087

Current vouchers.html SHA:
9e3a9cbd0124639934cdf98abc9ec579f4b19f61

Current main.html blob:
810e4f5440f5975f55099a124deb42b086a49183

Current picker.html SHA:
c7ad267d852d415b680aed7716833eea9bcffdf6

Current van-sales.html SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

### Production Transfer Security
Receiver binding and sender/receiver separation are PRODUCTION VERIFIED.

Applied production hardening:
- 20260928095000_harden_transfer_responsibility_trigger_execute_surface
- 20260928095500_close_transfer_responsibility_trigger_acl

Final ACL for public.enforce_transfer_responsibility_contract():
- anon EXECUTE = false
- authenticated EXECUTE = false
- PUBLIC EXECUTE = false
- service_role EXECUTE = true

### Production E2E
Transactional Transfer:
BR-01 → BR-2
item 1001
qty 2

Verified:
- Create = PASS
- Send = PASS
- source 8 → 6
- receiver snapshot = vouchers3 / BR-2
- receiver immutable = PASS
- sender Receive rejected = PASS
- partial Receive 1 = PASS
- destination 3 → 4
- full remaining Receive 1 = PASS
- destination 4 → 5
- final state Received = PASS
- complete path previously verified = PASS

All QA data rolled back:
- QA transfer vouchers = 0
- QA operations = 0
- QA inventory-log QA rows = 0
- source stock restored = 8
- destination stock restored = 3

### Current UI Closure
Owner-only surgical patches in Report347:
- T-06: Draft card Print button.
- T-07: receiver modal label «خروج بدون حفظ».
- T-08: detailed receipt confirm label «حفظ الكميات المستلمة».

IMPORTANT:
- Do not modify vouchers.html from assistant side.
- Do not modify main.html.
- Do not create Edge Functions.
- Do not repeat T-01..T-05.
- Do not redo Transfer backend migrations unless new Production evidence contradicts this state.
- Historical all-company Transfer scope remains unchanged.

### Browser Closure
Authenticated live Browser E2E remains OPEN because no authenticated browser session is available in the current toolset.

### Exact next action
Owner applies T-06/T-07/T-08 to:
companies/company-1/warehouse/vouchers.html

Then:
1. Re-read the entire file.
2. Verify syntax.
3. Verify no duplicate action blocks.
4. Execute authenticated E2E with Sender BR-01 and Receiver BR-2.
5. Close Browser E2E only after live UI evidence.
6. Continue to the next real Business Contract gap.

### Current report
doc/Draft/Reprots/Report347_WAREHOUSE_VOUCHERS_TRANSFER_FINAL_FORENSIC_CLOSURE_20260928.md

---

# FINAL AUTHORITATIVE POINTER — 2026-09-24 — VOUCHERS PICKSELECT + DIRECTRETURN FORENSIC CLOSURE

## Current continuation baseline
- Current System Git HEAD: `6ebea2c7aacad14a1702fe86032870fb14d87db1`
- Parent: `0d5a57d7b263cbb10e5235db56175fc4b7825ed3`
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

---

# 2026-09-27 — SupplierReturn Forensic Closure Addendum

## Verified Current Reality

### System Git
- HEAD: 27dd52a82bccfc65726ed3e46776ede28ac1281b
- Parent: 6ebea2c7aacad14a1702fe86032870fb14d87db1
- Parent of parent: 0d5a57d7b263cbb10e5235db56175fc4b7825ed3

### Mother Git
- HEAD: fce3dfaa0503957791113a5ebf57d402a4a82764
- Parent: 666f15bc84348b6fb44a5c565dcf2fb4fe1d0c98
- main.html SHA: 810e4f5440f5975f55099a124deb42b086a49183
- vouchers.html SHA: 6c3822060c0e261c73879b94a5147d807a0bc6c2
- van-sales.html SHA: 8d61382a8e0025a0d079e71dd94f33d106d9088e

## Closure Unit

SUPPLIER RETURN (SupplierReturn) in standalone warehouse vouchers.

## Root Cause — PROVED

The standalone vouchers source incorrectly restricts SupplierReturn suppliers through supplierBranchMap derived from purchase_orders.

Current Production and Mother contracts prove:
- SupplierReturn is a standalone Branch → Supplier warehouse operation.
- Active Supplier master is the authoritative destination.
- PO/Purchase Invoice linkage is optional business context, not a creation gate.

Exact defective source blocks:
1. pickArr(key), approximately lines 2937–2964.
2. submit(), approximately lines 4085–4106.

The first makes the supplier candidate array empty when the branch has no PO history.
The second rejects the same valid transaction again.

pickSearch() is not the root cause and is not to be rewritten in this closure.

## Production Proof

Persistent QA data retained:
- Supplier: QA-SR-20260927 / QA مرتجع مورد — لا يوجد PO
- Item: QA-SR-ITEM-20260927 / QA صنف مرتجع مورد — اختبار دائم
- Voucher: IN-3 / SupplierReturn / Completed
- Reference: QA-SR-RETURN-20260927-01
- Qty: 2
- Unit value: 75
- Total: 150

Verified:
- Stock branch qty reduced by 2.
- SupplierReturn inventory_log movement exists.
- Supplier ledger debit = 150.
- Journal debit supplier payable = 150.
- Journal credit inventory = 150.
- Journal balanced.
- Complete RPC replay returned duplicate=true without creating duplicate financial posting.

## Production Changes

None required for the current defect.

Existing production architecture remains authoritative:
- create-stock-voucher v12
- send-stock-voucher v20
- receive-stock-voucher v22
- complete-stock-voucher v4
- centralized post_stock_movement
- centralized supplier ledger posting
- centralized journal posting

No new Edge Function created.
No post_stock_movement change.
No schema change.
No main.html change.
No vouchers.html change by assistant.
No van-sales change.

## Owner Surgical Changeset

File:
companies/company-1/warehouse/vouchers.html

Required owner changes are recorded in:
doc/Draft/Reprots/Report341_WAREHOUSE_VOUCHERS_SUPPLIER_RETURN_FORENSIC_CLOSURE_20260927.md

Changes:
- SR-01: Replace SupplierReturn candidate block in pickArr().
- SR-02: Replace SupplierReturn PO-map validation block in submit().
- SR-03: Rename route label only from «المورد المرتبط بالفرع» to «المورد».

No other function should be rewritten for this closure.

## Accounting Finding — OPEN SEPARATE CLOSURE

Production shows:
- suppliers.accounts_payable may differ from latest supplier_ledger.balance.
- QA supplier accounts_payable = 0 while ledger_balance = -150.
- SUPP-1001 accounts_payable = 0 while ledger_balance = 3970.

Do not patch this from SupplierReturn.
Treat as a separate authoritative-balance contract investigation.

## Competitive Gap Backlog — NOT PART OF THIS SURGICAL CLOSURE

Potential future fields/processes:
- Return Reason
- Supplier Credit Note / RMA
- Optional Purchase Invoice reference
- Optional PO reference
- Return-to Address
- Inspection / Disposition
- Tax / Discount / explicit return valuation

These require an independent business/data/accounting contract before implementation.

## Closure Status

CLOSED:
- Production SupplierReturn core
- Stock effect
- Inventory log
- Supplier ledger posting
- Journal posting
- Idempotent complete replay
- No-PO backend capability
- Persistent QA proof
- Edge-count constraint compliance

PATCH READY — OWNER APPLY:
- Vouchers SR-01
- Vouchers SR-02
- Vouchers SR-03

OPEN:
- Authenticated browser E2E after owner patch
- Published artifact verification after owner patch

## LAST VERIFIED CHECKPOINT

Production Core + DB + Accounting + Idempotency + source root cause.

## NEXT EXACT RESUMPTION POINT

Do not reopen Production SupplierReturn design.

Verify in current vouchers.html:
- SR-01 applied
- SR-02 applied
- SR-03 applied

Then:
Full parse → Published artifact check → Authenticated Browser E2E → Production post-patch verification.

---

# 2026-09-27 — Report342 SupplierReturn Business Contract Closure

## Current authoritative checkpoint

### System Git
- Current System HEAD: \`fcae1c79016aae1fc0c8e3f977c7cdbc88be7238\`
- Production migration commit: \`d5a124803a9cc17560b4022844cb04eb3e3d1312\`
- Report: \`doc/Draft/Reprots/Report342_SUPPLIER_RETURN_BUSINESS_CONTRACT_UI_PRODUCTION_CLOSURE_20260927.md\`

### Mother Git
- HEAD: \`4a322fa793027f8584d9f0d55638ef5a14aebc03\`
- Parent: \`fce3dfaa0503957791113a5ebf57d402a4a82764\`
- vouchers.html SHA: \`6aca57d8baa8c78b616a281411f15438f34676bf\`
- main.html SHA: \`810e4f5440f5975f55099a124deb42b086a49183\`
- van-sales.html SHA: \`8d61382a8e0025a0d079e71dd94f33d106d9088e\`

## Source conclusion
- Commit 4a322... already contains SR-01/SR-02/SR-03.
- Do not reapply those fixes.
- pickSearch is not the root cause.
- SupplierReturn remains Branch → Supplier and independent of PO/Order/Runsheet.

## Production closure executed
Migration:
\`close_supplier_return_contract_accounting_20260927\`

Durable migration:
\`supabase/migrations/20260927152000_close_supplier_return_contract_accounting.sql\`

Closed:
- Return Reason
- Supplier Credit Note reference
- Supplier RMA reference
- Optional PO reference
- Optional Purchase Invoice reference
- Return-to Address
- Inspection status
- Disposition
- line unit price
- line discount
- line tax
- explicit return totals
- typed purchase document links
- Supplier Ledger posting
- GL posting
- tax transaction
- supplier accounts_payable synchronization
- authenticated RPC path
- negative guard before stock movement
- Contract Save idempotency

No new Edge Function was created.

## Production RPCs
- save_supplier_return_contract
- get_supplier_return_contract
- assert_supplier_return_contract

Existing core updated:
- complete_manual_stock_voucher_atomic_core_20260828
- send_stock_voucher_atomic

## Persistent QA

### Supplier
- QA-SR-CLOSURE-20260927
- id: \`8a4ec462-d9ef-43e3-943d-9c1369b2561e\`

### Item
- QA-SR-ITEM-20260927
- cost: 75

### PO
- QA-SR-PO-20260927
- id: \`967e9cfa-01c7-42ac-90c7-dad16b3b4de3\`

### Purchase Invoice
- QA-SR-INV-20260927
- id: \`2f6208c9-32e9-41a2-9014-56826f8b5e84\`

### IN-4
- id: \`9a849d3a-399c-447a-8696-597438050d70\`
- qty: 2
- gross: 150
- discount: 15
- taxable: 135
- VAT: 20.25
- total: 155.25
- status: Completed
- optional PO + Invoice references present
- Credit Note / RMA references present
- journal balanced
- stock reduced from 8 to 6
- inventory_log verified
- supplier ledger verified
- suppliers.accounts_payable synchronized
- tax transaction verified
- purchase_document_links verified

### IN-5
- id: \`6a1c9195-48b4-4700-8e62-da304bd0205e\`
- direct-purchase path
- PO = NULL
- Purchase Invoice = NULL
- total = 75
- status: Completed
- supplier ledger and journal verified

### IN-6
- negative guard fixture
- status remains Draft
- missing Return Reason rejected before Send
- no stock movement created

## Accounting master reconciliation
- payable_balance_mismatches = 0
- suppliers_checked = 4

## Owner surgical patch
File:
\`companies/company-1/warehouse/vouchers.html\`

Owner-only additions are documented in Report342:
- SR-04 refs for returnReasons/taxCodes
- SR-05 loadRefs master data
- SR-06 SupplierReturn Contract UI entry
- SR-07 authenticated Contract modal + line valuation + optional PO/Invoice
- SR-08 submit preflight
- SR-09 create callback Contract save
- SR-10 edit callback Contract save

The assistant did not modify vouchers.html.

## Protected files
- main.html: untouched
- vouchers.html: untouched by assistant
- van-sales.html: untouched

## Browser / Deployment status
OPEN:
- authenticated browser E2E after Owner Patch
- published artifact verification after Owner Patch

Do not convert DB/RPC evidence into Browser PASS.

## Exact next resumption
1. Verify Owner SR-04 through SR-10 in current vouchers.html.
2. Parse embedded JavaScript fully.
3. Publish/deploy the owner-controlled source.
4. Run authenticated browser E2E.
5. Re-read IN-4, IN-5, IN-6 from Production.
6. Verify stock, inventory_log, supplier ledger, payable master, journal, tax transaction, document links.
7. Close SupplierReturn UI only after browser proof.

Do not reopen:
- SR-01/SR-02/SR-03
- DirectSale fixes
- DirectReturn fixes
- Fleet fixes

Do not touch main.html unless new contradictory evidence appears.
Do not create a new Edge Function.

## Final root cause
SupplierReturn had previously been incorrectly coupled to supplierBranchMap generated from PO history.

That source coupling was already removed by Mother commit 4a322....

The remaining gap was the absence of the full SupplierReturn Business Contract in the Production data/accounting layer.

That Production contract is now closed.


---

# CURRENT SESSION CHECKPOINT — 2026-09-27 — Report343 SupplierReturn UI / RLS Forensic Closure

## Authoritative Git after this session

### System
- Current HEAD: `db654788af5f4e7639d816ebda97182356b47a72`
- Parent: `010fdcbc61bf5bbabd2a27a79636927d14f7db3b`
- Previous parent chain includes Production hardening migration commit:
  `fc93c4c3f1b057734d89f289fd9743c394797a7a`

### Mother
- Repository: `papamohammed77-glitch/erp-frontend`
- HEAD: `4a322fa793027f8584d9f0d55638ef5a14aebc03`
- Parent: `fce3dfaa0503957791113a5ebf57d402a4a82764`
- `companies/company-1/main.html`: `810e4f5440f5975f55099a124deb42b086a49183`
- `companies/company-1/warehouse/vouchers.html`: `6aca57d8baa8c78b616a281411f15438f34676bf`
- `companies/company-1/sales/van-sales.html`: `8d61382a8e0025a0d079e71dd94f33d106d9088e`

## Production actions executed

### Migration
`supabase/migrations/20260927165000_harden_supplier_return_voucher_directory_and_rpc_acl_20260927.sql`

Applied successfully.

Changes:
- Supplier SELECT now supports active warehouse role `أذونات` inside current company without granting `suppliers` management permission.
- Return Reasons SELECT is company-scoped (or global NULL company).
- `assert_supplier_return_contract(uuid,uuid)`: PUBLIC/anon/authenticated EXECUTE revoked.
- `save_supplier_return_contract(uuid,text,jsonb,text)`: authenticated-only EXECUTE.
- `get_supplier_return_contract(uuid,text)`: authenticated-only EXECUTE.

No Edge Function created.

## Forensic root causes closed

1. SupplierReturn Contract UI remained absent from current `vouchers.html` while Production Contract was already closed.
2. Supplier Smart Search itself was not defective. Supplier rows were hidden by `suppliers_select_company` because `vouchers@rawaea.com` has `permissions=["warehouse"]` and role `مخزني / أذونات`.
3. The prior Report342 SR-10 snippet had an ordering bug: it could clear `editVoucherCode` before testing/saving it.
4. `supplierReturnDraft` was not reset when entering a new workspace/edit/back flow, creating stale-contract risk.

## Proven Production Search result

Authenticated simulation for `vouchers@rawaea.com` after RLS fix:
- current company = company-1
- supplier permission = false
- visible supplier rows = 4

This proves the Supplier dropdown data layer is now available without broadening Supplier management permission.

## Permanent QA — DO NOT DELETE

Voucher:
`QA-SR-UI-CONTRACT-20260927-01`

ID:
`6c2cea2c-548b-48b3-aeb9-def4a80776e1`

Status:
`Completed`

Supplier:
`QA-SR-CLOSURE-20260927`

Item:
`QA-SR-ITEM-20260927`

QA contract:
- Return Reason = SR001
- Credit Note = QA-UI-CN-20260927-01
- RMA = QA-UI-RMA-20260927-01
- PO = NULL
- Purchase Invoice = NULL
- Inspection = passed
- Disposition = credit_requested
- Unit Price = 75
- Discount = 10%
- Tax = VAT15-PURCHASE
- Total = 77.63

E2E DB/RPC:
Draft → Contract Save → Send → Complete = PASS

Effects:
- stock BR-01 QA item: 5 → 4
- inventory_log: SupplierReturn qty 1
- supplier ledger debit: 77.63
- supplier accounts_payable: -307.88
- tax transaction taxable: 67.50; tax: 10.13
- journal: Posted and balanced at 77.63
- operation registry key: `QA-SR-UI-CONTRACT-OP-20260927-01`, completed

QA remains permanently retained.

## Owner Surgical Patch — current vouchers.html only

Owner must apply Report343 SR-04 → SR-10.

Exact current source locations:
- App.refs: ~line 27
- App state: ~line 34
- loadRefs purchase_orders block: ~line 132
- newWorkspace: line 2384
- editVoucher state: ~line 2075
- SupplierReturn routeHtml: line 3492
- SupplierReturn submit validation: line 4070
- edit success callback: line 4232
- create success callback: line 4365
- back: line 4396

Do not repeat SR-01/SR-02/SR-03.

Do not touch:
- main.html
- van-sales.html
- existing stock core
- existing Edge Functions

## Owner patch includes

- returnReasons/taxCodes refs
- loadRefs for Return Reasons / Tax Codes
- SupplierReturn Contract entry button
- full Contract modal
- line price / discount / tax fields
- optional PO / Invoice
- Credit Note / RMA
- Return-to Address
- Inspection / Disposition
- contract fingerprint
- authenticated Contract RPC call
- submit preflight
- create callback save
- edit callback save with corrected ordering
- stale draft reset

## Browser / deployment

Still OPEN:
- authenticated browser E2E
- published artifact verification

DB/RPC evidence must not be relabeled Browser PASS.

## Report

Current closure report:
`doc/Draft/Reprots/Report343_WAREHOUSE_VOUCHERS_SUPPLIER_RETURN_UI_RLS_FORENSIC_CLOSURE_20260927.md`

The report contains the complete surgical replacement elements and competitor traceability.

## Next exact continuation

1. Re-fetch current Mother vouchers.html.
2. Verify SR-04..SR-10 are applied exactly.
3. Full JavaScript parse.
4. Commit/publish owner-controlled artifact.
5. Verify served artifact identity.
6. Authenticated browser E2E.
7. Re-read permanent QA voucher and all downstream evidence.
8. Close Browser/Deployment boundary only after proof.

## Do not reopen

- SupplierReturn Production schema
- SR-01/SR-02/SR-03
- DirectSale closure
- DirectReturn closure
- Fleet closure
- Supplier search engine without new evidence
- new Edge Function creation


## Final checkpoint correction — Report343 latest commit
- Report343 latest commit: `db654788af5f4e7639d816ebda97182356b47a72`
- Report343 duplicate documentation block removed; surgical patch unchanged.
- Production migration commit: `fc93c4c3f1b057734d89f289fd9743c394797a7a`
- Latest System HEAD therefore points to the corrected Report343 documentation.

## END OF CURRENT STATE — 2026-09-27


---

# CURRENT STATE — 2026-09-27 — Report 344 Closure Checkpoint

## Authoritative checkpoint

- System documentation HEAD before this state update: `23c3bef8cd181f113312d81ffa545bfbf3fab7bb` (Report 344).
- Parent: `d89cbfaa475adaf9a05c3f3c9a5bec7e4f163d16`.
- Mother frontend HEAD: `2203768d8fd3f58a2fa0b378c45494b0741be9cd`.
- Mother parent: `4a322fa793027f8584d9f0d55638ef5a14aebc03`.
- Current vouchers.html blob: `306cb0ddf6e922951a8a164d9a7818728c6cb0da`.
- Current van-sales.html blob: `8d61382a8e0025a0d079e71dd94f33d106d9088e`.
- Current main.html blob: `810e4f5440f5975f55099a124deb42b086a49183`.
- Current app.html blob: `ec75f89c11620f6e8b8ef5996cf1a3289dcf20b4`.

## Report 344 result

- Root cause of `vouchers:2986 Uncaught SyntaxError: Function statements require a function name` is confirmed: the `pickArr:function(key)` closing segment `return []; },` was deleted before `pickShow:function(key)` in commit `4a322fa793027f8584d9f0d55638ef5a14aebc03`.
- Surgical Patch 1 is READY; no source file was modified by the assistant.
- Surgical Patch 2 (SR-08 SupplierReturn submit preflight) is READY; no source file was modified by the assistant.
- In-memory parse after both patches: embedded scripts 1/6 through 6/6 PASS.
- Production SupplierReturn Contract/DB/RLS/ACL remains CLOSED; no new table and no new Edge Function were created.
- Existing permanent completed QA `QA-SR-UI-CONTRACT-20260927-01` remains retained.
- New permanent browser fixture created and retained: reference `QA-SR-BROWSER-E2E-20260927-01`, voucher id `e029730a-2925-4c42-8472-57c6b0264c27`, voucher code `IN-7`, status Draft, type SupplierReturn, contract total 77.63, PO + Purchase Invoice references populated.
- The new Draft fixture has no inventory movement, supplier-ledger entry, journal entry, or tax transaction yet; it is reserved for Browser E2E after Owner source patch.
- Transactional RPC E2E PASS for PO + Invoice and for Invoice-only (direct purchase path); temporary test vouchers were rolled back, permanent QA data was not deleted.
- Authenticated Contract RPC grants verified: save/get executable by authenticated, not anon; internal assert capability restricted.

## Exact Owner Source Action

File: `companies/company-1/warehouse/vouchers.html`

1. Inside `pickArr:function(key)`, replace the exact defective SupplierReturn-to-`pickShow` segment with the Section 5 replacement in Report 344.
2. Inside `submit()`, insert SR-08 immediately before the existing `if(this.mode==='edit'){` after SupplierReturn validation, exactly as Section 7 in Report 344.

Do not rewrite the file. Do not touch main.html or van-sales.html. Do not create Edge Functions.

## Closure status

- Production / DB / RPC / RLS / Contract / QA: CLOSED.
- Source UI: OWNER PATCH REQUIRED.
- Browser E2E: OPEN.
- Published artifact verification: OPEN.

Report:
`doc/Draft/Reprots/Report344_WAREHOUSE_VOUCHERS_SYNTAX_SR_PREFLIGHT_FORENSIC_CLOSURE_20260927.md`

Next session must begin from CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT and must not re-open already closed Production Contract work.



---

# CURRENT STATE — 2026-09-28 — Report 345 Transfer Responsibility Closure

## Authoritative current reality

- System HEAD at session start: `2870ca03ee884c0eac4e19184b105d6c5927479c`
- System parent: `23c3bef8cd181f113312d81ffa545bfbf3fab7bb`
- Frontend current HEAD at session start: `4e67a7dde2b01d6810a247f62f193c8d2dc4202a`
- Frontend parent: `2203768d8fd3f58a2fa0b378c45494b0741be9cd`
- Current vouchers.html SHA at session start: `8910c9d6f032a8ddde907e5a4c7ae824a5a4267d`
- Current vouchers.html lines: 5599
- main.html unchanged in this session.
- van-sales.html unchanged in this session.

## Production changes executed

### 1. Transfer receiver binding
Production migration:
`20260928_transfer_responsibility_and_receiver_binding`
Version:
`20260928090051`

Added:
- `stock_vouchers.receiver_user_id`
- `stock_vouchers.receiver_assigned_at`
- FK to `public.users(id)`
- transfer receiver index
- transfer responsibility trigger

### 2. Production bug fix
Production migration:
`20260928_fix_transfer_receiver_uuid_selection`
Version:
`20260928090424`

Corrected UUID selection after the initial test exposed unsupported `max(uuid)`.

## Current business contract

### Transfer Draft
Only creator may edit / delete / send.

### Transfer Sent
Server has one immutable receiver snapshot.

Only `receiver_user_id` may perform Receive / Receive state transitions.

Sender cannot receive.

### Transfer Received
Creator or warehouse management may complete according to the centralized contract.

## Test users

Sender:
- `vouchers@rawaea.com`
- active_warehouse_role = `أذونات`
- default branch = BR-01
- allowed branch = BR-01

Receiver:
- `vouchers3@rawaea.com`
- active_warehouse_role = `أذونات`
- default branch = BR-2
- allowed branch = BR-2

## E2E result

Fixture IN-8:
- Create = PASS
- Send = PASS
- Receiver binding = PASS
- Sender Receive rejection = PASS
- Partial Receive = PASS
- Replay duplicate protection = PASS
- Full remaining Receive = PASS
- Complete = PASS
- QA cleanup = PASS

Fixture IN-9:
- Non-creator draft update rejection = PASS
- Non-creator deletion blocked = PASS
- QA cleanup = PASS

All Transfer QA fixtures from this session removed.

## Historical contradiction resolved

IN-2 was reported previously as rolled back, but CURRENT PRODUCTION showed it Completed with 10 movement rows.

IN-2 was reversed and purged after direct current-production verification.

Verification:
- no IN-2 Transfer voucher remains
- no IN-2 inventory_log remains
- stock balances restored for the tested item rows

## Source UI state

Current source has NOT been modified by this session.

Owner Change Set prepared:
- T-01 actionFor responsibility filtering
- T-02 cards sender/receiver actions
- T-03 exit confirmation
- T-04 receive full/detailed UX
- T-05 Transfer receiver detail toolbar

## Closure

- Transfer Production Security Contract: PRODUCTION VERIFIED
- Receiver Binding: PRODUCTION VERIFIED
- Partial / Full Receive backend: PRODUCTION VERIFIED
- Source UI responsibility: OWNER PATCH REQUIRED
- Browser E2E: OPEN
- Published artifact verification: OPEN

## Do not reopen

- SupplierReturn Production Contract
- SupplierReturn schema / RLS / RPC
- DirectSale closure
- DirectReturn closure
- Fleet closure
- Physical Stock Core
- new Edge Function creation

## Exact next session

If Owner has merged T-01..T-05:
→ verify current frontend SHA
→ parse all embedded scripts
→ authenticated Browser E2E with sender + receiver
→ verify UI visibility and click paths
→ verify served artifact
→ close Browser/Deployment boundary.

If Owner has NOT merged them:
→ do not re-run Production Security work
→ only verify source patch status.

## Report

`doc/Draft/Reprots/Report345_WAREHOUSE_VOUCHERS_TRANSFER_RESPONSIBILITY_FORENSIC_CLOSURE_20260928.md`



## Report345 Amendment — 2026-09-28
- Report345 was amended after self-audit to include the **complete T-04 `receive:function(code,full)` surgical replacement**, not a cross-reference only.
- T-02/T-05 JavaScript quote escaping was normalized in the report so the code blocks are directly copyable from Markdown.
- Latest Report345 commit: `f5e47a191603403363bfe0b0dbdf490da0eff955`.
- This amendment does not change Production state; it only completes the Owner Change Set documentation.


---

# CURRENT STATE — 2026-09-28 — Report346 Transfer Receiver UI Final Checkpoint

## Authoritative current reality

### GIT
- System HEAD: `66151de0f0a594c5842afa1f9fef6fb521cfd316`; parent: `f5e47a191603403363bfe0b0dbdf490da0eff955`.
- Frontend HEAD: `cc35f3a9da6ababf4c8cd87b05ab93539cdae087`; parent: `4e67a7dde2b01d6810a247f62f193c8d2dc4202a`.
- Latest frontend commit changes only `companies/company-1/warehouse/vouchers.html`.
- Current vouchers blob: `b9b34b91a3c33f0689a20a493432e69c8e1c5f0c`.
- main.html unchanged: `810e4f5440f5975f55099a124deb42b086a49183`.
- van-sales.html unchanged: `8d61382a8e0025a0d079e71dd94f33d106d9088e`.
- picker.html unchanged: `c7ad267d852d415b680aed7716833eea9bcffdf6`.

### PRODUCTION / DATABASE
- Transfer responsibility migrations remain active:
  - `20260928090051_transfer_responsibility_and_receiver_binding`.
  - `20260928090424_fix_transfer_receiver_uuid_selection`.
- `stock_vouchers.receiver_user_id` and `receiver_assigned_at` are present.
- `trg_transfer_responsibility_contract` is active.
- DB trigger enforces a single receiver snapshot, excludes sender from receiver selection, prevents receiver reassignment after Send, and blocks unauthorized Receive/Complete transitions.
- `stock_vouchers` authenticated policy is SELECT-only; operational writes are via existing server-side RPC path.
- Existing `receive-stock-voucher` Edge Function remains version 22; no new Edge Function was created.
- No Production schema/function change was needed in Report346.

### TEST EVIDENCE
Transactional QA fixtures were created and rolled back. No Transfer QA fixtures remain.

Verified in Production transaction:
- sender receive attempt rejected by responsibility contract.
- assigned receiver partial receive PASS.
- same-operation replay returns duplicate PASS.
- receiver remaining quantity receive PASS.
- creator completion PASS.
- receiver identity is immutable after Send by trigger contract.

The only failed assertion in the first harness was a test-order error: receiver_user_id was read before Send. It did not represent a product failure and must not be repeated.

### SOURCE UI STATE
Current `vouchers.html` already contains and must retain:
- T-01 actor-aware `actionFor(v)`.
- T-02 responsibility-aware pending buttons.
- T-03 `exitVoucherDetails()`.
- T-04 `receive(code, full)` with full/partial receiving and idempotency.

Current source defect:
- `var topActions=` exists inside `details:function(code)` and correctly builds receiver actions.
- It is currently unused: `topActions+` occurrences = 0.
- The old print/export toolbar remains directly after `var h=` around line 1935.

### OWNER SURGICAL PATCH — T-05
File: `companies/company-1/warehouse/vouchers.html`
Function: `details:function(code)`

Find the exact toolbar directly after `var h=`:

```javascript
'<div class="flex flex-wrap justify-end gap-2 mb-3 no-print">'+
'<button type="button" onclick="App.printVoucher()" class="px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-black">🖨 طباعة</button>'+
'<button type="button" onclick="App.exportVoucher()" class="px-3 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black">⇩ تصدير CSV</button>'+
'</div>'+
```

Delete that complete element and replace it with exactly:

```javascript
topActions+
```

Do not modify any other function or block in vouchers.html.

### CLOSURE STATUS
- Production transfer responsibility: CLOSED.
- DB authorization and rollback behavior: CLOSED.
- T-01/T-02/T-03/T-04: PRESENT and must not be reimplemented.
- T-05 receiver modal toolbar wiring: OPEN — one surgical source replacement only.
- main.html: DO NOT TOUCH.
- van-sales.html: NO CHANGE REQUIRED.
- picker.html: NO CHANGE REQUIRED.
- No new Edge Function.
- No new migration unless new Production evidence proves this contract broken.

### NEXT SESSION ENTRY SEQUENCE
1. Verify current GIT HEADs and vouchers blob SHA.
2. Verify T-01..T-04 remain unchanged.
3. Apply T-05 exact toolbar replacement only.
4. Verify `topActions+` occurs once and the obsolete toolbar is gone.
5. Run authenticated browser E2E for sender/receiver/partial/full/complete.
6. Do not repeat Production repair or recreate old QA fixtures.

Report: `doc/Draft/Reprots/Report346_WAREHOUSE_VOUCHERS_TRANSFER_RESPONSIBILITY_FORENSIC_CURRENT_CLOSURE_20260928.md`