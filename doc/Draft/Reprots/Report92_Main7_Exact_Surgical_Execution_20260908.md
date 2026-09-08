# Report92 — Main7 Exact Surgical Execution — 2026-09-08

## 1. Scope
تمت مراجعة `CURRENT_STATE.md`، ملفات MASTER الثلاثة، `تقرير مبادئ حاكمة`، `برومبت استكمال مهام`، Report87، Report89، Report90، Report91، `Current/PWA/main2/main7.md`، `Current/PWA/driver.html`، وProduction Supabase.

لم يتم تعديل `Current/PWA/main2/main7.md`.

Current Main7 SHA: `0962e20262e77e9e6d8905c83098c2d5fac9210c`.

## 2. Proven protected contracts
- Delivery lifecycle remains `Open / Confirmed → Picking → Picked → Loading → Loaded → Delivering → Delivered → Returning → Returned`.
- `driver.html` already executes Order-level Delivery through `complete-order-delivery`.
- `complete_order_delivery_atomic` is the Order fulfillment owner.
- `complete-delivery` is Runsheet finalization only.
- Physical Stock remains `post_stock_movement → stock_branches + inventory_log`.
- `reserve_stock` / `release_stock_reservation` are reservation-only.
- `items.item_code` is globally UNIQUE in Production.
- `stock_voucher_details` parent identity is `voucher_id`.
- `order_details` has no `runsheet_id`; Order-to-Runsheet traversal is through `orders`.
- `forensic_main_assembly.yml` already points to `Current/PWA/main2/**`; no correction required.

## 3. Exact owner actions on Main7

### M7-07B — `loadVoucherForm(type)`
Current lines: 145–154.

Find the exact grid whose first line is:
`<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">`
and whose last line is the `</div>` immediately before:
`<div class="mb-4">`

Delete that complete grid.

Replace with:
```html
<div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
    <div>
        <label class="block text-sm font-bold mb-1">${cfg.entityLabel}</label>
        <select id="voucherEntitySelect" class="border rounded-lg p-2 w-full"><option value="">-- اختر --</option></select>
    </div>
    <div>
        <label class="block text-sm font-bold mb-1">مرجع الإذن</label>
        <input id="voucherReference" class="border rounded-lg p-2 w-full" placeholder="مرجع الإذن...">
    </div>
    <div>
        <label class="block text-sm font-bold mb-1">ملاحظات</label>
        <textarea id="voucherNotesLarge" rows="2" class="border rounded-lg p-2 w-full" placeholder="ملاحظات..."></textarea>
    </div>
</div>
```

Do not modify the next `بحث عن صنف` block.

### M7-09 — `function _openDeliveryModal(rsCode)`
Start line: 1193.
End: the `}` immediately before `function _openReturnModal(rsCode) {`.

Delete the whole function using that exact boundary.

Use the complete Order-by-Order function recorded in Report89. The function must:
- resolve Runsheet by `company_id + runsheet_code`;
- call `start-delivery` once;
- load Orders by `company_id + runsheet_id`, ordered by `created_at ASC`, fields `id,order_code,customer_name`;
- present one Order at a time;
- read `order_details` only by `order_id`;
- calculate `remaining = qty_loaded - qty_delivered`;
- POST only the current Order to `complete-order-delivery` using `runsheet_code,order_code,items`;
- after each successful Order, move to the next Order;
- after all Orders, POST `{runsheet_code:rsCode}` to `complete-delivery`;
- never send `ordersData`;
- never derive Order quantities from `run_sheet_details`.

The full function text is preserved in Report89/Report91 and is intentionally not re-authored here to avoid introducing a third implementation.

### M7-10A — `loadSettlement()`
Current query line is inside `loadSettlement()` around line 930; exact current query text:
`var runsheetsRes = await supabase.from('runsheets').select('runsheet_code, driver_id').in('status', ['Delivered', 'Returned']);`

Replace with:
```javascript
var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
var runsheetsRes = await supabase.from('runsheets')
    .select('runsheet_code, driver_id')
    .eq('company_id', companyId)
    .in('status', ['Delivered', 'Returned']);
```

### M7-10B — `_onSettlementRsChange()` voucher linkage
Current broken block is in the 950s and starts with:
`var vouchersRes = await supabase.from('stock_vouchers').select('voucher_code').eq('reference', rsCode).eq('type', 'Return');`

Delete through the line:
`returnDetails = retRes.data || [];`

Replace with:
```javascript
var vouchersRes = await supabase.from('stock_vouchers')
    .select('id, voucher_code')
    .eq('company_id', companyId)
    .eq('reference', rsCode)
    .eq('type', 'Return');
var voucherIds = (vouchersRes.data || []).map(function(v) { return v.id; });
var returnDetails = [];
if (voucherIds.length > 0) {
    var retRes = await supabase.from('stock_voucher_details')
        .select('*')
        .in('voucher_id', voucherIds);
    returnDetails = retRes.data || [];
}
```

### M7-10C — `_onSettlementRsChange()` Order Details
Find the exact line:
`var orderDetailsRes = await supabase.from('order_details').select('*').eq('runsheet_id', rs.id);`

Delete that full line and replace with:
```javascript
var ordersForRsRes = await supabase.from('orders')
    .select('id')
    .eq('company_id', companyId)
    .eq('runsheet_id', rs.id);
if (ordersForRsRes.error) throw ordersForRsRes.error;
var orderIdsForRs = (ordersForRsRes.data || []).map(function(o) { return o.id; });
var orderDetails = [];
if (orderIdsForRs.length > 0) {
    var orderDetailsRes = await supabase.from('order_details')
        .select('*')
        .in('order_id', orderIdsForRs);
    if (orderDetailsRes.error) throw orderDetailsRes.error;
    orderDetails = orderDetailsRes.data || [];
}
```

### M7-10D — latest vehicle count
Inside `_onSettlementRsChange()`, after `loadedItems`, `orderDetails`, and `returnDetails` are built and before `itemsMap` is built, add:
```javascript
var vehicleRes = await supabase.from('vehicles')
    .select('id, mobile_branch_id')
    .eq('company_id', companyId)
    .eq('id', rs.vehicle_id)
    .maybeSingle();
if (vehicleRes.error) throw vehicleRes.error;
var vehicle = vehicleRes.data || null;
var inventoryEntityId = vehicle ? (vehicle.mobile_branch_id || vehicle.id) : null;
var countedByItem = {};
if (inventoryEntityId) {
    var countRes = await supabase.from('inventory_counts')
        .select('id')
        .eq('company_id', companyId)
        .eq('type', 'vehicle')
        .eq('entity_id', inventoryEntityId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
    if (countRes.error) throw countRes.error;
    if (countRes.data) {
        var countDetailsRes = await supabase.from('inventory_count_details')
            .select('item_code, counted_qty')
            .eq('count_id', countRes.data.id);
        if (countDetailsRes.error) throw countDetailsRes.error;
        var countDetails = countDetailsRes.data || [];
        for (var c = 0; c < countDetails.length; c++) {
            countedByItem[countDetails[c].item_code] = Number(countDetails[c].counted_qty) || 0;
        }
    }
}
```

Then at the exact current line `962`, replace:
```javascript
itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: 0, unitPrice: Number(it.unit_price) || 0 };
```
with:
```javascript
itemsMap[it.item_code] = { itemCode: it.item_code, itemName: it.item_name, unit: it.unit, loadedQty: Number(it.qty_loaded) || 0, deliveredQty: 0, returnedQty: 0, countedQty: Number(countedByItem[it.item_code]) || 0, unitPrice: Number(it.unit_price) || 0 };
```

### M7-11 — `loadBranchCount()`
Find the exact text:
`'<option value="' + (b.branch_code || b.id || '') + '"`.

Replace only with:
`'<option value="' + (b.id || b.branch_code || '') + '"`.

### M7-12 — `_saveVehicleCount()`
Start line: 835.
Delete the complete current function; its final line is the `}` immediately before:
`async function _saveInvCount(type, entityId, reference) {`

Replace with the exact Report89 version:
```javascript
async function _saveVehicleCount() {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    var selectedDriver = window._selectedDriver || '';
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }
    if (!selectedDriver) { showToast('يجب اختيار مندوب', 'warning'); return; }

    var reference = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';
    var notes = (byId('vc-notes') ? byId('vc-notes').value : '') || '';
    if (notes) reference = reference ? reference + ' | ' + notes : notes;

    var vehicleId = null;
    var selectedRunsheet = (byId('vc-runsheet-select') ? byId('vc-runsheet-select').value : '') || '';

    if (selectedRunsheet) {
        var rsRes = await supabase.from('runsheets')
            .select('vehicle_id')
            .eq('company_id', companyId)
            .eq('runsheet_code', selectedRunsheet)
            .maybeSingle();
        if (rsRes.error) { showToast(rsRes.error.message, 'error'); return; }
        vehicleId = rsRes.data ? rsRes.data.vehicle_id : null;
    }

    if (!vehicleId) {
        var userRes = await supabase.from('users')
            .select('id')
            .eq('company_id', companyId)
            .eq('email', selectedDriver)
            .maybeSingle();
        if (userRes.error) { showToast(userRes.error.message, 'error'); return; }
        var driverId = userRes.data ? userRes.data.id : null;
        if (driverId) {
            var vehicleRes = await supabase.from('vehicles')
                .select('id')
                .eq('company_id', companyId)
                .eq('driver_id', driverId)
                .limit(1)
                .maybeSingle();
            if (vehicleRes.error) { showToast(vehicleRes.error.message, 'error'); return; }
            vehicleId = vehicleRes.data ? vehicleRes.data.id : null;
        }
    }

    if (!vehicleId) { showToast('لا توجد مركبة مرتبطة بهذا المندوب', 'warning'); return; }
    await _saveInvCount('vehicle', vehicleId, reference || 'جرد سيارة');
}
```

### M7-13 — `_saveGeneralCount()`
Delete the current full function:
`async function _saveGeneralCount() {`
through the `}` immediately before the Settlement section comment.

Replace with the exact Report89 version:
```javascript
async function _saveGeneralCount() {
    var companyId = (RW_STATE && RW_STATE.app && RW_STATE.app.companyId) || null;
    var notes = (byId('gc-notes') ? byId('gc-notes').value : '') || '';
    if (!companyId) { showToast('سياق الشركة غير محدد', 'error'); return; }

    var settingsRes = await supabase.from('app_settings')
        .select('main_branch_id')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();
    if (settingsRes.error) { showToast(settingsRes.error.message, 'error'); return; }
    var mainBranchId = settingsRes.data ? settingsRes.data.main_branch_id : null;
    if (!mainBranchId) { showToast('الفرع الرئيسي غير محدد', 'error'); return; }

    await _saveInvCount('general', mainBranchId, 'جرد عام' + (notes ? ' | ' + notes : ''));
}
```

### M7-14 — additional tenant scope
Apply exactly these replacements:

1. `loadPicking()` — current line 540:
`var res = await supabase.from('runsheets').select('*').in('status', ['Open', 'Confirmed']);`
Replace with a `companyId` guard and `.eq('company_id', companyId)`.

2. `_showPickingDetails(code)` — the Runsheet lookup by `runsheet_code` only. Add `.eq('company_id', companyId)` and a company guard before the lookup.

3. `loadVehicleCount()` — add `companyId` guard and `.eq('company_id', companyId)` to its Runsheet selector.

4. `_searchDriver(query)` — add `companyId` guard and `.eq('company_id', companyId)` to the Users query.

5. `loadUnloading()` — add `companyId` guard and `.eq('company_id', companyId)` to `runsheets` query.

### M7-15 — Voucher Entity UUID contract
Production Schema proves:
- `stock_vouchers.from_id` UUID.
- `stock_vouchers.to_id` UUID.
- `branches.id` UUID.
- `vehicles.id` UUID.

Current Main7 sends `MAIN`, branch codes, or driver emails into those identity fields. This is an integration defect.

#### M7-15A — `loadVoucherForm(type)` config
Remove `fromId:'MAIN'` and `toId:'MAIN'` literals from the four voucher configs. Do not replace them with another hardcoded identity.

#### M7-15B — `_loadVoucherEntityOptions(type)`
- Transfer option value = `branches.id`.
- DirectSale option value = `vehicles.id`.
- DirectReturn option value = `vehicles.id`.
- All Branch/Vehicle queries must use current company context.
- Display names/codes/driver information remain presentation only.
- SupplierReturn identity must remain compatible with the existing supplier contract; do not invent a supplier UUID contract without source evidence.

#### M7-15C — `_saveAndSendVoucher()`
Delete these two current lines:
`var toId = cfg.toId || entity;`
`var fromId = cfg.fromId || entity;`

Replace with resolved UUIDs from the selector and current voucher type. Never send:
- `MAIN`.
- branch_code where UUID is expected.
- driver email where vehicle UUID is expected.

## 4. Additional source integrity finding
The current Main7 also contains unscoped operational reads in:
- `loadLoading()` — exact query line 580:
  `var res = await supabase.from('runsheets').select('*').in('status', ['Loaded']);`
- `loadDelivery()` — exact query line 619:
  `var res = await supabase.from('runsheets').select('*').in('status', ['Delivered']);`
- `loadReturn()` — query in the Return section:
  `var res = await supabase.from('runsheets').select('*').in('status', ['Returned']);`

It also contains unscoped Runsheet lookups inside `_showLoadingDetails(code)`, `_showDeliveryDetails(code)`, `_showReturnDetails(code)`, `_openPickingModal(rsCode)`, `_openLoadingModal(rsCode)`, and `_openReturnModal(rsCode)`.

These are the same tenant-boundary root cause. They should be patched in the same surgical tenant-scope pass: resolve `companyId` once inside each function where required, add company guards, and add `.eq('company_id', companyId)` to each Runsheet lookup. No business behavior or lifecycle state changes.

The exact current source anchors above are used to avoid changing any Delivery/Loading/Return business logic.

## 5. Explicit no-change list
- `M7-08` lifecycle labels.
- `Current/PWA/driver.html` Delivery business workflow.
- `complete_order_delivery_atomic`.
- `complete_return_atomic`.
- Physical Stock Core.
- `_showUnloadingDetails()` behavior.
- `.github/workflows/forensic_main_assembly.yml` path.

## 6. Production actions
No Production change was required by the Main7 source defects above. Production contracts were rechecked directly. The current Production inventory architecture remains the protected central engine.

## 7. Verification gate after owner surgery
Owner must, after applying the exact surgeries:
1. Read Main7 SOF→EOF.
2. Run JS syntax validation on the reconstructed fragment.
3. Check braces/template strings/function boundaries.
4. Confirm Delivery contains no `ordersData`.
5. Confirm Order lookup fields `id,order_code,customer_name`.
6. Confirm Order detail lookup uses `order_id`.
7. Confirm Settlement uses latest vehicle count by `mobile_branch_id || vehicle.id`.
8. Confirm Branch/General/Vehicle counts pass UUID entity IDs.
9. Confirm Voucher `from_id/to_id` are UUIDs.
10. Confirm all operational Runsheet/Users reads are company-scoped.
11. Assemble from `Current/PWA/main2/main1..main11`.
12. Run canonical workflow checks.
13. Only after source and assembly pass, proceed to browser/runtime Production gate.

## 8. Closure
`MAIN7 FORENSIC REVIEW = COMPLETE`
`MAIN7 SOURCE SURGERY = OPEN / OWNER ACTION REQUIRED`
`DELIVERY CONTRACT = PROVEN`
`INVENTORY COUNT CONTRACT = PROVEN`
`TENANT SCOPE = OPEN`
`VOUCHER UUID INTEGRATION = OPEN`
`FULL MAIN2 ASSEMBLY = OPEN / NOT PROVEN`
`PARENT GOLD/DIAMOND = NOT CLOSED`
