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