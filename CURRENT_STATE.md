# RAWAEA ERP — CURRENT STATE PACK

## Checkpoint — 2026-09-08

### 1. Governance
العمل محكوم بمبادئ Engineering Governance المثبتة في ملفات MASTER وتقارير المراجعة:
- Production الحالية هي المرجع التنفيذي.
- لا تعديل قبل فهم التاريخ والعقد والسلوك الحالي.
- UNKNOWN لا يساوي BUG ولا يبرر الحذف.
- يتم العمل بوحدات Closure منفصلة، ولا ينتقل العمل إلى الوحدة التالية قبل إغلاق السابقة.
- Physical Stock Contract:
  `Physical Stock Movement -> post_stock_movement -> stock_branches + inventory_log`
- `reserve_stock` / `release_stock_reservation` مسؤولية Reservation فقط.
- ملفات `Current/PWA/main2/main1..main11` هي Source of Truth للعمل اليدوي على الأجزاء الأم.
- `Current/PWA/main/*` مرحلة مختلفة/تاريخية ولا تُستخدم كمصدر assembly canonical.
- `Current/PWA/New-main` ناتج تجميع generated target وليس مصدرًا يدويًا مستقلًا.

### 2. Current Git Reality
Repository: `papamohammed77-glitch/rawaie-erp-New`
Branch: `main`
Current relevant commits remain the previously recorded reconstruction/path closures plus the current Main7 forensic record.

### 3. Main2 fragments
المصدر الجاري العمل عليه يدويًا بواسطة المالك هو:
`Current/PWA/main2/main1.md ... main11.md`

Current fragment identities recorded before the Main7 recheck remain valid except for Main7, whose current SHA is now:
- main7: `0962e20262e77e9e6d8905c83098c2d5fac9210c`

The other fragment identities remain as previously recorded:
- main1: `4d1b42250cfe2b3a8ec7d02b7b482eca8e27bade`
- main2: `58dd0da232ccca4c62bc17d87220bf8b705d85e8`
- main3: `479060e3d4bea5e2203c87f822b1dbc0e2f7d456`
- main4: `e89d29e4164c68784c109292f27d4d77df240557`
- main5: `c4518d05ada50830e819563a55169843679d3e94`
- main6: `3b20758459c28ab0b6c055f9a0ad3992f1bd07e5`
- main8: `20f77481133d3e55ced949de16f88dadb0a69980`
- main9: `288b642d050f8b5ddeb6d43a7fd2a992fb05bb03`
- main10: `d57cef3bd7e42f7ba7ddc90bde81bdbabd5579a1`
- main11: `cad8bafa94da839ffb3a61f1a4581f52b98289f4`

### 4. Main6 Closure
Target: `Current/PWA/main2/main6.md`
Report84 surgeries M6-01..M6-09 were previously verified in the actual current source. Main6 closure remains CLOSED.

### 5. Report85 -> Report86 -> Report87 -> Report88 reconciliation
Report85 established the main2/main assembly source conflict.
Report86 continued with Production reconciliation and Main7 forensic review.
Report87 re-reviewed the evidence and corrected M7-08: lifecycle stage labels must not be changed from the established business lifecycle.
Report88 re-read the CURRENT Main7 SHA directly and reconciled Production against the current source again.

### 6. Production Reality — current checkpoint
Supabase project: `fiilmooggumokxanwiyx`

Direct Production verification during the current Main7 recheck confirmed the relevant current contracts:
- `complete_order_delivery_atomic(p_company_id, p_runsheet_code, p_order_code, p_user_email, p_items)` is the authoritative Order-level Delivery fulfillment RPC.
- `complete-order-delivery` Production v14 calls the Order-level RPC.
- `complete-delivery` Production v4 transitions a Runsheet from `Delivering` to `Delivered` and handles meter/tracking state; it is not the Order fulfillment writer.
- `save-inventory-count` Production v2 stores vehicle counts against `mobile_branch_id || vehicle.id` and writes details to `inventory_count_details`.
- `runsheets` enforces `UNIQUE(company_id, runsheet_code)`.
- `stock_voucher_details` uses `voucher_id` for parent linkage; it does not have `voucher_code` as a detail column.

No persistent Delivery/Order fixture was created merely to test Main7.

### 7. Production Inventory Core Closure
A fresh PostgreSQL writer scan remains consistent with the earlier closure:
`direct_physical_writers_outside_allowed = 0`

Allowed responsibilities confirmed:
- `post_stock_movement` — Physical Stock Engine.
- `reserve_stock` / `release_stock_reservation` — Reservation only.
- `setup_van_stock` / `create_vehicle_atomic` — stock-row initialization, not operational movement.
- `complete_runsheet_picking` changes fulfillment/reservation and does not independently mutate `stock_branches.qty`.

Legacy executable inventory capabilities remain explicitly closed. The legacy definitions are retained as historical evidence and are not deleted.

### 8. Current Production return/delivery contracts
- `complete-return` authenticates the user, derives company from the authenticated user context, and calls `complete_return_atomic`.
- `complete_return_atomic` performs physical return through `post_stock_movement`.
- `complete-order-delivery` processes one Order at a time.
- `complete_order_delivery_atomic` uses `erp_operation_registry` for idempotency and does not mutate physical stock.
- `complete-delivery` finishes Runsheet state only.

### 9. Assembly Source-of-Truth correction
The reconstruction path was corrected from `Current/PWA/main/` to `Current/PWA/main2/`.
The forensic assembly configuration also uses `Current/PWA/main2/**` as the canonical editable source and `Current/PWA/New-main` as generated target.

### 10. Assembly verification status
A controlled assembly execution was previously triggered, but full Main2 assembly has not been proven Gold/Diamond.
No unsupported causal claim is recorded for the historical CI failure.

Therefore:
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`

### 11. Main7 Forensic Status — CURRENT SHA `0962e20262e77e9e6d8905c83098c2d5fac9210c`
Target:
`Current/PWA/main2/main7.md`

The current source was read directly from Git. EOF remains structurally intact:
`})();`
followed by:
`window.RW_Warehouse = RW_Warehouse;`

Already applied and therefore NOT to be re-requested:
- Receiving company scope and Receiving Details company validation.
- Driver lookup company scope for voucher form.
- Voucher list company scope.
- Voucher details resolved by company + voucher_code, then details by voucher_id.
- Receive UI remaining-quantity logic and Idempotency-Key/operation_id payload.
- `_openNewVoucherModal()` opens `loadVoucherForm()` rather than creating an empty voucher.
- Picking source list uses `Open / Confirmed`; lifecycle itself remains unchanged.

### 12. Main7 OPEN surgical items — owner applies to main7 only
The assistant must NOT edit `Current/PWA/main2/main7.md`.

#### M7-07B — missing Reference input
Current `_saveAndSendVoucher()` reads `byId('voucherReference')`, but current `loadVoucherForm(type)` does not render that element.

Exact source area: `loadVoucherForm(type)`, current lines approximately 145–154. Replace the whole grid beginning with:
`<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">`
and ending immediately before:
`<div class="mb-4">`
with a grid containing:
- `voucherEntitySelect`
- `voucherReference`
- `voucherNotesLarge`

Do not alter the item-search block after that boundary.

#### M7-09 — Delivery must execute Order-by-Order
Exact current function:
`_openDeliveryModal(rsCode)`
starts at line `1193` and ends immediately before `function _openReturnModal(rsCode)`; current closing boundary is the final `}` of `_openDeliveryModal`.

The current implementation is proven wrong because it:
- starts the Runsheet correctly;
- reads Runsheet items;
- reads all Orders;
- builds the same Runsheet item set for every Order;
- calls `complete-delivery` with `ordersData`.

This contradicts the Production contract where `complete_order_delivery_atomic` receives one `order_code` plus that Order's item quantities, while `complete-delivery` only closes the Runsheet state.

Owner replacement requirements for the full `_openDeliveryModal(rsCode)` function:
1. Resolve Runsheet with `company_id + runsheet_code`.
2. Call `start-delivery` once.
3. Read Orders using the resolved Runsheet ID, ordered by `created_at ASC`; select `id,order_code,customer_name`.
4. Open one Order at a time.
5. Read only that Order's `order_details` by `order_id`.
6. For each item calculate `remaining = qty_loaded - qty_delivered`.
7. Submit only that Order to `/functions/v1/complete-order-delivery` with:
   `runsheet_code`, `order_code`, `items`.
8. After the Order succeeds, open the next Order.
9. After all Orders succeed, call `/functions/v1/complete-delivery` with only `{ runsheet_code: rsCode }`.
10. Do not send `ordersData`.
11. Do not derive an Order's delivered quantity from `run_sheet_details`.

The current delivery lifecycle is intentionally preserved:
`Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned`.

#### M7-10 — Settlement must read the latest Vehicle Inventory Count
Exact current line containing the defect: line `962` inside `_onSettlementRsChange()`:
`itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: 0, unitPrice: Number(it.unit_price) || 0 };`

Replace that hardcoded `countedQty: 0` logic by:
- resolve `rs.vehicle_id` from the company-scoped Runsheet;
- resolve `vehicles.id,mobile_branch_id` inside the same company;
- set `inventoryEntityId = mobile_branch_id || vehicle.id`;
- read the latest `inventory_counts` row using:
  `company_id = companyId`, `type = 'vehicle'`, `entity_id = inventoryEntityId`, ordered by `created_at DESC`;
- read its `inventory_count_details` by `count_id`;
- build `countedByItem[item_code] = counted_qty`;
- use that value in `itemsMap`.

#### M7-10B — broken stock-voucher detail lookup inside settlement
Exact current area: `_onSettlementRsChange()`, current lines approximately 950–955.

Delete this complete block:
`var vouchersRes = await supabase.from('stock_vouchers').select('voucher_code').eq('reference', rsCode).eq('type', 'Return');`
through:
`returnDetails = retRes.data || [];`

Replace it with a company-scoped `stock_vouchers` lookup selecting `id,voucher_code`, build `voucherIds` from `id`, then query `stock_voucher_details` with `.in('voucher_id', voucherIds)`.

Production Schema proof: `stock_voucher_details` has `voucher_id` and no `voucher_code` detail column.

#### M7-12 — Vehicle Count entity identity
Current `_saveVehicleCount()` uses:
`var entityId = window._selectedDriver || '';`
then calls:
`await _saveInvCount('vehicle', entityId, reference || 'جرد سيارة');`

This is incompatible with Production `save-inventory-count`, which validates vehicle `entityId` against `vehicles.id` and then maps to `mobile_branch_id` when present.

Owner replacement for the complete `_saveVehicleCount()` function:
- keep the selected driver UI;
- resolve the selected driver to `users.id` inside current company;
- when a Runsheet is selected, resolve that Runsheet by `company_id + runsheet_code` and use its `vehicle_id`;
- when no Runsheet is selected, resolve the driver's active vehicle from `vehicles.driver_id` within company scope;
- reject only when no vehicle can be resolved;
- call `_saveInvCount('vehicle', vehicleId, reference || 'جرد سيارة')`.

Do not pass driver email as `entityId` to the vehicle inventory-count contract.

### 13. Main7 items intentionally NOT changed
- M7-08 lifecycle labels: NOT an error; Report87 is authoritative on this point.
- `complete_order_delivery_atomic`: NOT modified.
- `complete_return_atomic`: NOT modified.
- Physical Stock Core: NOT modified for Main7.
- `_showUnloadingDetails()`: remains placeholder; no behavior invented without a proven contract.

### 14. Tests and failures in current recheck
- Production Delivery contracts were read directly.
- Production vehicle inventory-count contract was read directly.
- Production schema for Runsheet and stock voucher detail linkage was verified.
- Main7 current SHA was re-read after discovering the previously recorded SHA was stale.
- Historical lifecycle was reconciled before prescribing any status change.
- No permanent Order/Runsheet fixture was created to manufacture a passing Delivery test.

A previous temporary Purchase Receive idempotency experiment exposed a sequencing issue and was diagnosed rather than converted into a false success; it is not being used as evidence for Main7 closure.

### 15. Reports
Latest:
`doc/Draft/Reprots/Report88_Main7_Forensic_Recheck_20260908.md`

Previous:
`doc/Draft/Reprots/Report87`

Older reports remain preserved.

### 16. Next controlled action
1. Owner applies only the exact Main7 surgical items in Section 12.
2. Re-read Main7 SOF→EOF from the new SHA.
3. Run JavaScript syntax validation on the reconstructed Main7 fragment.
4. Verify all brackets, template strings and function closures.
5. Run canonical reconstruction from `Current/PWA/main2/main1..main11`.
6. Compare reconstructed Parent against Production Delivery/Inventory contracts.
7. Only after source and assembly evidence pass, proceed to browser/runtime verification.
8. Deployment to Production is a later controlled step; no Main7 production deployment is claimed now.

### 17. Closure statement
`PRODUCTION INVENTORY WRITER CORE = CLOSED`
`LEGACY INVENTORY CORE EXECUTION = CLOSED`
`MAIN2 RECONSTRUCTION SOURCE PATH = CLOSED`
`MAIN6 SOURCE SURGERY = CLOSED`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`
`PARENT GOLD/DIAMOND = NOT CLOSED`
