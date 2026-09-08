# RAWAEA ERP — CURRENT STATE PACK

## Checkpoint — 2026-09-08

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
Latest documentation checkpoint: `bd880910fa58857a9823eaf41f7db25d697d9c7b`
Main7 current code SHA: `0962e20262e77e9e6d8905c83098c2d5fac9210c`
Latest report commit: `bd880910fa58857a9823eaf41f7db25d697d9c7b`

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
The assistant DID NOT modify `Current/PWA/main2/main7.md`.
EOF remains structurally intact: `})();` followed by `window.RW_Warehouse = RW_Warehouse;`.

Already applied in Main7 and NOT to be re-requested:
- Receiving company scope.
- Receiving Details company validation.
- Voucher list company scope.
- Voucher detail resolution by company + voucher_code then voucher_id.
- Driver lookup company scope in voucher form.
- Receive remaining-quantity logic and Idempotency-Key/operation_id payload.
- `_openNewVoucherModal()` -> `loadVoucherForm()`.
- Picking source status list `Open / Confirmed`.

### Main7 OPEN Owner Surgeries
#### M7-07B
`loadVoucherForm(type)` lines 145–154: add the missing `voucherReference` field in the existing 3-column grid. Preserve the following `بحث عن صنف` block.

#### M7-09
`function _openDeliveryModal(rsCode)` starts at line 1193 and ends immediately before `function _openReturnModal(rsCode) {`.
Replace the whole function with the Report89 Order-by-Order version:
- Runsheet lookup = `company_id + runsheet_code`.
- `start-delivery` once.
- Orders = `company_id + runsheet_id`, ordered `created_at ASC`, fields `id,order_code,customer_name`.
- One Order per modal.
- Order items from `order_details` by `order_id`.
- `remaining = qty_loaded - qty_delivered`.
- Submit only current Order to `/functions/v1/complete-order-delivery` with `runsheet_code,order_code,items`.
- Next Order only after success.
- Final `/functions/v1/complete-delivery` with `{runsheet_code: rsCode}` only.
- No `ordersData`.
- No Order quantity derivation from `run_sheet_details`.

#### M7-10 / M7-10A / M7-10B / M7-10C / M7-10D
Settlement changes:
- line 962 hardcoded `countedQty: 0` -> latest vehicle Inventory Count.
- `loadSettlement()` Runsheet query -> company-scoped.
- Return voucher lookup -> `stock_vouchers.id` then `stock_voucher_details.voucher_id`.
- Remove `order_details.runsheet_id` lookup; traverse `orders.runsheet_id -> orders.id -> order_details.order_id`.
- Resolve `vehicles.id,mobile_branch_id`, then latest vehicle count by `inventoryEntityId`.

#### M7-11
`loadBranchCount()` option value: `(b.branch_code || b.id || '')` -> `(b.id || b.branch_code || '')`.

#### M7-12
`_saveVehicleCount()` starts at line 835. Replace the complete function before `_saveInvCount(type, entityId, reference)` with the Report89 vehicle-resolution function. Preserve the selected-driver UI; resolve driver -> user.id -> company-scoped vehicle.id; prefer Runsheet.vehicle_id.

#### M7-13
`_saveGeneralCount()` must resolve `app_settings.main_branch_id` by `company_id`; never use literal `MAIN` as `entityId`.

#### M7-14
Company-scope:
- `loadPicking()` exact current Runsheet query is line 540.
- `_showPickingDetails(code)` Runsheet lookup.
- `loadVehicleCount()` Runsheet selector.
- `_searchDriver(query)` Users lookup.
- `loadUnloading()` Runsheet query.

#### M7-15 — NEW
Production schema proves `stock_vouchers.from_id` and `to_id` are UUIDs; `branches.id` and `vehicles.id` are UUIDs.
Current Main7 can send `MAIN`, branch_code, or driver email into these UUID fields.
Actions:
- remove `fromId:'MAIN'` / `toId:'MAIN'` literals from voucher configs.
- Transfer option value = `branches.id`.
- DirectSale/DirectReturn option value = `vehicles.id`.
- `_saveAndSendVoucher()` must pass resolved UUIDs; never `MAIN`, branch_code, or driver email for UUID columns.
- SupplierReturn keeps its existing supplier business contract.

#### M7-16 — NEW
Additional company-scope closures found in the current source:
- `loadLoading()` exact query line 580 is unscoped.
- `loadDelivery()` exact query line 619 is unscoped.
- `loadReturn()` Runsheet query is unscoped.
- `_showLoadingDetails(code)` Runsheet lookup is unscoped.
- `_showDeliveryDetails(code)` Runsheet lookup is unscoped.
- `_showReturnDetails(code)` Runsheet lookup is unscoped.
- `_openPickingModal(rsCode)` Runsheet lookup is unscoped.
- `_openLoadingModal(rsCode)` Runsheet lookup is unscoped.
- `_openReturnModal(rsCode)` Runsheet lookup is unscoped.
Patch only the tenant boundary; do not alter business flow or lifecycle.

### Protected No-Change List
- M7-08 lifecycle labels.
- `Current/PWA/driver.html` Delivery workflow/business idea.
- `complete_order_delivery_atomic`.
- `complete_return_atomic`.
- Physical Stock Core.
- `_showUnloadingDetails()` placeholder behavior.
- `.github/workflows/forensic_main_assembly.yml` path.

### Production Checkpoint
Supabase project: `fiilmooggumokxanwiyx`.
Verified relevant contracts:
- `complete_order_delivery_atomic(...)` is Order-level delivery owner.
- `complete-delivery` is Runsheet finalization.
- `save-inventory-count` uses `mobile_branch_id || vehicle.id` for vehicle counts.
- `runsheets` is unique by `(company_id, runsheet_code)`.
- `stock_voucher_details` links by `voucher_id`.
- `items.item_code` is globally UNIQUE.
- `order_details` does not contain `runsheet_id`.
- `stock_vouchers.from_id/to_id` are UUID columns.

No persistent Delivery/Order fixture was created for testing.

### Assembly
`.github/workflows/forensic_main_assembly.yml` was re-read directly and remains correct:
`Current/PWA/main2/**` = canonical editable source.
`Current/PWA/New-main` = generated target.
No path correction required.

Full Main2 assembly remains OPEN / NOT PROVEN because Main7 owner surgeries are still pending.

### Reports
Latest Main7 report:
`doc/Draft/Reprots/Report92_Main7_Exact_Surgical_Execution_20260908.md`
Previous:
`Report91_Main7_Gold_Diamond_Surgical_Recheck_20260908.md`
`Report90_Main7_Final_Tenant_Scope_Addendum_20260908.md`
`Report89_Main7_Surgical_Review_20260908.md`
`Report88_Main7_Forensic_Recheck_20260908.md`
`Report87`

### Last Verified Event
`EVENT: MAIN7-FORENSIC-RECHECK-20260908`
- Direct Git source verification.
- Direct Production Supabase verification.
- Main7 SHA: `0962e20262e77e9e6d8905c83098c2d5fac9210c`.
- Latest report: Report92.
- Production change required for Main7 in this session: none.
- Main7 source surgery remains OWNER ACTION REQUIRED.

### Closure
`PRODUCTION INVENTORY WRITER CORE = CLOSED`
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`MAIN7 FORENSIC REVIEW = COMPLETE`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`DELIVERY CONTRACT = PROVEN`
`INVENTORY COUNT CONTRACT = PROVEN`
`MAIN7 TENANT SCOPE = OPEN / OWNER ACTION REQUIRED`
`MAIN7 VOUCHER UUID INTEGRATION = OPEN / OWNER ACTION REQUIRED`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`
`PARENT GOLD/DIAMOND = NOT CLOSED`
