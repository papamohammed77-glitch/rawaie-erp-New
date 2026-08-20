# RAWAEA ERP — 2026-08-19 Forensic Status

## Scope
Fresh source-first investigation of:
- `Current/PWA/main.html`
- `Current/PWA/vouchers.html`
- `rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`
- `doc/Draft/Hussin/برومبت 11 وتقريري تنفيذه`
- `doc/Draft/Hussin/برومبت 12 وتقريري تنفيذه`
- Production Supabase schema, RPCs, Edge Functions, and runtime verification.

## Proven current facts
1. Manual vouchers are a separate workflow from runsheets. Historical architecture defines: Transfer, DirectSale, DirectReturn, SupplierReturn, Scrap, Adjustment.
2. Current Production manual CREATE contract supports only: Transfer Branch→Branch; DirectSale Branch→Vehicle; DirectReturn Vehicle→Branch; SupplierReturn Branch→Supplier.
3. Vehicle stock is represented by a company branch `VAN-{vehicle_code}`; the live Production vehicle `VEH-92yrzb` has `VAN-VEH-92yrzb` initialized.
4. Physical stock mutations for the manual voucher lifecycle are routed through `post_stock_movement`; no second Physical Stock engine was introduced.
5. `items.item_code` is globally UNIQUE in the deployed schema. Item identity therefore uses global `item_code`/`item_id`; Branch/Vehicle/Supplier/header context remains company-scoped.
6. Manual voucher `reference` is enforced in Production for `source='Manual'` by a database CHECK constraint.

## Production changes actually applied
- Migration `20260819_manual_voucher_vehicle_stock_contract`
  - corrected DirectSale/DirectReturn vehicle semantics;
  - kept all stock mutation through `post_stock_movement`;
  - made direct vehicle movements complete atomically after the movement;
  - retained Transfer as Draft→Sent→Receive→Complete workflow.
- Migration `20260819_manual_voucher_lifecycle_company_scope`
  - removed `app_settings LIMIT 1` dependency from CANCEL/COMPLETE;
  - made both operations company-scoped and idempotent for already-final states.
- Migration `20260819_manual_voucher_reference_required`
  - enforced non-empty reference for manual vouchers.
- Production Edge capabilities `complete-stock-voucher` and `cancel-stock-voucher` were deployed and verified as the runtime capabilities used by the updated UI.

## vouchers.html — forensic UI closure
The file was upgraded surgically in-place. No new UI file was created.

### UI commits
- `c391695188eed6570e205752e8503ae1b60d08f1` — elevated manual voucher type selection into the gold header.
- `6c8e83697f8182790d79a019cb3483494c0b940a` — corrected the DirectReturn Vehicle→Branch selector before declaring closure.

### Current UI contract
Implemented and verified in the final Git blob:
- gold/diamond header treatment inspired by the current PWA visual language;
- manual voucher type selection is in the HEADER, not in the lower tab strip;
- the lower tabs remain only `معلقة / مكتملة / حسابي`;
- four currently Production-supported manual types are directly selectable from the header:
  - `Transfer` — Branch → Branch
  - `DirectSale` — Branch → Vehicle
  - `DirectReturn` — Vehicle → Branch
  - `SupplierReturn` — Branch → Supplier
- `Scrap` and `Adjustment` are deliberately shown as disabled/non-available because Production CREATE does not currently prove a safe backend contract for them; no fake behavior was invented;
- the create dialog opens directly for the selected header type rather than asking for the type a second time;
- DirectReturn now explicitly renders Vehicle as source and Branch as destination;
- source/destination reference data is company-scoped;
- reference is mandatory;
- item search follows the deployed global `item_code` identity model;
- Send / partial Receive / Complete / Cancel capabilities remain wired to backend/RPC capabilities;
- no client-side `stock_branches.qty` or `inventory_log` mutation was introduced;
- Physical Stock ownership remains backend-controlled through `post_stock_movement`.

### Final vouchers.html identity
- Git blob SHA: `812070b2e0ede5754d971fd20f4e6b5b2472f59c`
- Final file: `Current/PWA/vouchers.html`
- Build marker: `RAWAEA-VOUCHERS-GOLD-MASTER-2026-08-20-INV-PRIVACY`

## Production runtime verification previously completed
A Production-only forensic test was executed inside a PL/pgSQL subtransaction and intentionally rolled back after verification.

Verified in the real deployed database:
- DirectSale: MAIN physical stock decreased by exactly 1; one `DirectSale` inventory log was produced; final voucher status `Completed`.
- DirectReturn: one unit moved Vehicle→MAIN and restored the tested MAIN stock balance; one `DirectReturn` inventory log was produced; final voucher status `Completed`.
- Transfer: Branch→Branch Send produced status `Sent`; RECEIVE completed through `post_manual_stock_voucher_atomic`; status became `Received`; COMPLETE then produced `Completed`.
- All three flows passed through `post_stock_movement`.
- Final Production cleanup check returned:
  - forensic vouchers = 0
  - forensic inventory logs = 0

## Audit / governance
- `stock_vouchers` audit trigger path is `trg_audit_stock_vouchers` → `fn_audit_trigger()`.
- The audit trigger records INSERT/UPDATE/DELETE with JWT email when available and `system` fallback.
- No new parallel stock writer was introduced.
- `main.html` was not modified by this UI closure.

## Remaining known gaps / conflicts
1. Historical architecture contains Scrap and Adjustment as manual voucher types, but the current deployed CREATE contract does not support them. They remain intentionally unavailable in the UI until their backend contract is independently proven and closed.
2. Production-only Edge files `complete-stock-voucher` and `cancel-stock-voucher` are deployed; the canonical `Current/Edge_Functions` directory did not contain those files during the earlier closure. This remains documented Production/Current Git drift.
3. A legacy 9-argument `post_stock_movement` overload still exists in Production, but the application roles cannot execute it; the application path uses the canonical 10-argument idempotent overload. This is legacy residue outside the surgical voucher UI task.
4. Purchase receiving idempotency remains a separate closure unit; it is not silently counted as closed.
5. Global Inventory Core Integrity remains incomplete until the remaining writer closure units in the governing directive are independently closed.

## 2026-08-20 Transfer SEND incident closure
### Incident
Real Production `Transfer` voucher `IN-1` failed with `target stock row missing` because destination branch `BR-2` had valid company/master-data context but no `stock_branches` row for the selected items.

### Root cause
`send_stock_voucher_atomic` was already routing Transfer to `voucher.to_id` and calling the canonical `post_stock_movement`. The remaining defect was inside `post_stock_movement`: it treated an absent destination inventory-state row as an invalid movement instead of a zero opening stock state.

### Surgical Production repair
A new canonical migration was applied:

`supabase/migrations/20260820_inventory_target_stock_row_autoinit.sql`

The engine now:
- validates target branch company context;
- validates global item identity;
- atomically creates a missing target `stock_branches` row with `qty=0` and `allocated_qty=0`;
- uses `ON CONFLICT (branch_id,item_id) DO NOTHING` for concurrency safety;
- keeps source stock existence and availability checks unchanged;
- keeps all physical mutation and `inventory_log` creation inside `post_stock_movement`.

Canonical Git commit:
`2c4c9a3eafd3d7dfd5944abdfd35a04eba7fc215`

### Production runtime proof
The real Production voucher `IN-1` was then executed through `send_stock_voucher_atomic`.

Verified:
- voucher status changed to `Sent`;
- `movement_count = 3`;
- target branch `BR-2` rows were created for item codes `1001`, `1003`, `1005`;
- target quantities became `1`, `2`, `1` respectively;
- allocated quantities remained `0`;
- three `TransferOut` inventory logs were created with per-item idempotency keys;
- source balances decreased exactly by the requested quantities.

Incident status: `PRODUCTION RUNTIME VERIFIED — CLOSED`.

Forensic record:
`Current/CTO/20260820_VOUCHERS_TRANSFER_TARGET_STOCK_ROW_FORENSIC_FIX.md`

## Final status
- Manual voucher UI/UX gap for the four Production-proven types: CLOSED.
- Header-based type selection requirement: CLOSED.
- Gold/diamond visual direction: IMPLEMENTED in `vouchers.html`.
- DirectReturn Vehicle→Branch selector defect found during verification: FIXED before closure.
- Hardcoded source/target UI defect: CLOSED.
- Mandatory reference gap: CLOSED.
- Cancel / Complete / Partial Receive UI gap: CLOSED for the current Production contract.
- **Transfer Branch→Branch `target stock row missing`: CLOSED in Production and canonically recorded in Git.**
- Physical Stock ownership: remains centralized through `post_stock_movement`.
- Scrap / Adjustment creation: NOT CLOSED because Production CREATE contract is not proven; intentionally not invented.

## Memory anchor
This document is the current forensic memory anchor. The next CTO must reread it and verify Production again. Do not infer that a historical manual voucher type is implemented merely because the UI lists it. The only types considered operationally supported are those proven by the current Production CREATE contract. A missing target `stock_branches` row for a valid inbound destination is now treated as zero inventory state and initialized centrally by `post_stock_movement`; do not regress to a hard failure or introduce a client-side stock writer.
