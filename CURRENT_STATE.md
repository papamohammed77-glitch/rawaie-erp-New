# RAWAEA ERP — CURRENT STATE PACK

## Checkpoint — 2026-09-08 — Report93 Recheck

### Governing Rules
- Production is the execution reference; reports are investigative indexes.
- No assumption-based patches; historical contract is required before change.
- UNKNOWN != BUG and UNKNOWN != REMOVE.
- One Closure Unit at a time.
- Physical Stock: `post_stock_movement -> stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` are Reservation only.
- Parent editable Source of Truth: `Current/PWA/main2/main1.md ... main11.md`.
- `Current/PWA/main/*` is historical evidence only.
- `Current/PWA/New-main` is generated target only.

### Current Git
Repository: `papamohammed77-glitch/rawaie-erp-New`
Branch: `main`
Main7 current source SHA: `b6d19e0b9c775d02594e4cba868e63455b009824`
Latest Main7 report: `Report93_Main7_Exact_Surgical_Recheck_20260908.md`
Report93 commit: `d52032e51609429278d227880d73a2ce0e0ad16b`

### Main7 Verified Historical/Production Contract
Lifecycle is preserved exactly:
`Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned`

Delivery ownership is split correctly:
- `complete_order_delivery_atomic` = Order-level fulfillment owner.
- `complete-order-delivery` = Order-level wrapper.
- `complete-delivery` = Runsheet finalization only.
- `driver.html` already submits Order-level delivery using `runsheet_code + order_code`.

Inventory ownership remains:
`Physical Stock -> post_stock_movement -> stock_branches + inventory_log`.

### Main7 Source Status
The assistant DID NOT modify `Current/PWA/main2/main7.md`; the user owns these source surgeries.
EOF remains structurally intact: `})();` followed by `window.RW_Warehouse = RW_Warehouse;`.

### Main7 Already Applied in Current Source — DO NOT RE-REQUEST
- M7-07B `voucherReference` field is already present in `loadVoucherForm(type)`.
- M7-09 Order-by-Order `_openDeliveryModal(rsCode)` is already present.
- Receiving company scope.
- Receiving Details company validation.
- Voucher list company scope.
- Voucher detail resolution by company + voucher_code then voucher_id.
- Driver lookup company scope in voucher form.
- Receive remaining-quantity logic and Idempotency-Key/operation_id payload.
- `_openNewVoucherModal()` -> `loadVoucherForm()`.
- Picking source status list `Open / Confirmed`.

### Main7 OPEN Owner Surgeries
#### M7-10 — Settlement
- `loadSettlement()` Runsheet query must use `company_id`.
- `_onSettlementRsChange()` must be replaced as one complete function because current source has: unscoped Runsheet lookup, invalid `order_details.runsheet_id` lookup, invalid return-detail linkage through voucher code, and `countedByItem` referenced before definition.
- Latest vehicle count must resolve `vehicles.id,mobile_branch_id` and then `inventory_counts.entity_id`.

#### M7-11 — `loadBranchCount()`
Option value must be `branches.id`, not `branch_code`.

#### M7-12 — `_saveVehicleCount()`
Resolve selected driver -> `users.id` -> company-scoped `vehicles.id`; prefer `runsheets.vehicle_id` when a Runsheet is selected; pass the vehicle UUID to `save-inventory-count`.

#### M7-13 — `_saveGeneralCount()`
Resolve `app_settings.main_branch_id` by `company_id`; never send literal `MAIN` as entity ID.

#### M7-14 / M7-16 — Company Scope
Open reads requiring exact company scoping remain in:
- `loadPicking()` — current mapping around line 540.
- `_showPickingDetails(code)` Runsheet lookup.
- `loadVehicleCount()` Runsheet selector.
- `_searchDriver(query)` Users lookup.
- `loadUnloading()` Runsheet query.
- `loadLoading()` — current mapping around line 580.
- `loadDelivery()` — current mapping around line 619.
- `loadReturn()` Runsheet query.
- `_showLoadingDetails(code)`.
- `_showDeliveryDetails(code)`.
- `_showReturnDetails(code)`.
- `_openPickingModal(rsCode)`.
- `_openLoadingModal(rsCode)`.
- `_openReturnModal(rsCode)`.

#### M7-15 — Voucher Entity UUID + DirectSale representative
Production schema/Core confirms:
- `stock_vouchers.from_id` and `to_id` are UUID.
- `branches.id` and `vehicles.id` are UUID.
- `items.item_code` is globally UNIQUE.
- `create_manual_stock_voucher_atomic` has a 12-argument contract with `p_rep_id` and `p_operation_id`.
- `DirectSale` requires Vehicle UUID plus valid `p_rep_id` when executed by the warehouse voucher role.
- `DirectReturn` requires Vehicle UUID -> Branch UUID.
- `SupplierReturn` requires Branch UUID -> Supplier UUID.

Main7 required owner changes:
- Remove all `fromId:'MAIN'` / `toId:'MAIN'` values from voucher config.
- `_loadVoucherEntityOptions(type)` must use Branch UUIDs, Vehicle UUIDs, and Supplier UUIDs; DirectSale must expose vehicles attached to `مندوب بيع مباشر`.
- `_saveAndSendVoucher()` must resolve `main_branch_id` by current company, use entity UUIDs, and send `rep_id` for DirectSale.

### Protected No-Change List
- M7-08 lifecycle labels.
- `Current/PWA/driver.html` Delivery workflow/business idea.
- `_openDeliveryModal(rsCode)` current Order-by-Order design.
- `complete_order_delivery_atomic`.
- `complete_return_atomic`.
- Physical Stock Core.
- `_showUnloadingDetails()` placeholder behavior.
- `.github/workflows/forensic_main_assembly.yml` path.
- `Current/PWA/main2` as canonical editable fragment source.

### Fresh Production Snapshot
Checked directly at `2026-09-08 11:31:28.54266+00 UTC`:
- companies = 1
- branches = 2
- users = 24
- items = 17
- stock_rows = 20
- orders = 0
- order_details = 0
- runsheets = 0
- run_sheet_details = 0
- stock_vouchers = 0
- inventory_log = 3
- inventory_counts = 0
- inventory_count_details = 0

### Production Core Verification
Current relevant functions include:
- `complete_order_delivery_atomic(p_company_id, p_runsheet_code, p_order_code, p_user_email, p_items)`
- `complete_return_atomic(p_company_id, p_runsheet_code, p_order_code, p_is_pos_return, p_user_email, p_items)`
- `post_inventory_adjustment_atomic(...)`
- `post_stock_movement(...)` with idempotency-capable 10-argument overload
- `receive_purchase_atomic(..., p_operation_id uuid)`
- `complete_runsheet_picking(...)`
- `complete_runsheet_loading(...)`

Current Edge versions verified in Production:
- `start-delivery` v7
- `complete-delivery` v4
- `complete-order-delivery` v14
- `complete-return` v25
- `create-stock-voucher` v10
- `send-stock-voucher` v20
- `receive-stock-voucher` v22
- `save-inventory-count` v2
- `receive-purchase` v12

### Inventory Writer Discovery
PostgreSQL function discovery found the following routines touching `stock_branches` or `inventory_log`:
- `post_stock_movement`
- `post_inventory_adjustment_atomic` -> delegates to `post_stock_movement`
- `post_manual_stock_voucher_atomic_core_20260828` -> delegates to `post_stock_movement`
- `send_stock_voucher_atomic_core_20260828` -> delegates to `post_stock_movement`
- `complete_runsheet_picking` -> reservation/fulfillment only; no Physical Stock movement
- `reserve_stock` / `release_stock_reservation` -> reservation only
- `setup_van_stock` -> zero-row initialization only; not a movement engine

No evidence was found in this sweep of a second independent Physical Stock movement engine outside `post_stock_movement`.

### Delivery / Driver Protection
`driver.html` continues to submit Order-level delivery using `runsheet_code + order_code`; no source change was made to it.
Main7 current `_openDeliveryModal(rsCode)` follows the same Order-by-Order contract.

### Assembly
`.github/workflows/forensic_main_assembly.yml` remains correct:
`Current/PWA/main2/**` = canonical editable fragment source.
`Current/PWA/New-main` = generated target.
`Current/PWA/main/**` = historical evidence only.
No workflow path correction is required.

### Reports
Latest:
`doc/Draft/Reprots/Report93_Main7_Exact_Surgical_Recheck_20260908.md`
Previous:
`Report92_Main7_Exact_Surgical_Execution_20260908.md`
`Report91_Main7_Gold_Diamond_Surgical_Recheck_20260908.md`
`Report90_Main7_Final_Tenant_Scope_Addendum_20260908.md`
`Report89_Main7_Surgical_Review_20260908.md`
`Report88_Main7_Forensic_Recheck_20260908.md`
`Report87`

### Last Verified Event
`EVENT: MAIN7-EXACT-SURGICAL-RECHECK-20260908`
- Governing source files re-read.
- Production snapshot re-read directly.
- Main7 SHA confirmed as `b6d19e0b9c775d02594e4cba868e63455b009824`.
- M7-07B and M7-09 confirmed already present; not re-requested.
- Delivery/driver contract confirmed and protected.
- Current Main7 remaining owner surgeries enumerated exactly in Report93.
- No Main7 source modification performed by the assistant.

### Closure
`PRODUCTION INVENTORY WRITER CORE = CLOSED / VERIFIED`
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED / VERIFIED`
`MAIN7 FORENSIC REVIEW = COMPLETE`
`MAIN7 DELIVERY CONTRACT = PROVEN / PROTECTED`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`M7-10 SETTLEMENT = OPEN`
`M7-11 BRANCH COUNT IDENTITY = OPEN`
`M7-12 VEHICLE COUNT IDENTITY = OPEN`
`M7-13 GENERAL COUNT IDENTITY = OPEN`
`M7-14/16 TENANT SCOPE = OPEN`
`M7-15 VOUCHER UUID + REP CONTRACT = OPEN`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`
`PARENT GOLD/DIAMOND = NOT CLOSED`
