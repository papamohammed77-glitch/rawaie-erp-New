# RAWAEA ERP — Report59
# Main2 Surgical Forensic Continuation — 2026-09-05

## 0. Scope and governing rule

This report continues the existing Main2 work. It does not restart Main1 and does not treat prior reports as proof. The governing source is `doc/Draft/medhat/MASTER - RAWAEA ERP.md` and its required sequence is:

`READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY`

The report also preserves the rule `ONE CLOSURE UNIT AT A TIME` and the prohibition on whole-file rewrites for narrow defects.

## 1. Source and repository recovery

Direct Git evidence establishes commit `a6556235c5768d9514ee3e910ae795391e3ab868` with message:

`fix(main2): surgical tenant-scoping and dashboard integrity`

The commit directly modifies `Current/PWA/main2/main2.md` and is therefore an actual Main2 source mutation, not a historical note. The current file blob verified from that commit is:

`b1096fdadd4734881d2c16c341dea769fc306fc5`

The prior `CURRENT_STATE.md` was stale relative to this Git state: it still named `e925dc5...` as the latest HEAD and said Main2 fresh closure was on hold. This session therefore reconciled the state against direct Git before making any new closure claim.

## 2. What the existing Main2 surgery already closed

The existing `a6556235...` change correctly added/retained company-scoped behavior for:

- dashboard primary orders;
- dashboard previous-period orders;
- purchase totals;
- customer count;
- item count;
- item stock loading by current company branch IDs;
- branch stock movement voucher queries;
- category loading and category modal reads;
- company-scoped item checks during category deletion;
- category filter loading.

These are not re-patched here without contradictory evidence.

## 3. Current Production synchronization

Production was queried directly immediately before this report:

`2026-09-05 00:21:30.867647 UTC`

Observed Production facts:

- companies = 1
- app_settings = 1
- orders = 0
- purchase_orders = 0

The current `post_inventory_adjustment_atomic` definition was also read directly from Production. It is `SECURITY DEFINER` and validates the executing user's company context, then calls `post_stock_movement`. Its successful return contract is:

`success`, `duplicate`, `movement_count`, `voucher_code`, `company_id`.

This matters because the Main2 upload UI currently expects a `results[]` array that Production does not return.

## 4. Main2 defects proved by direct source inspection

### M2-01 — Dashboard net-profit order query is not company-scoped

Current source:

```js
supabase.from('orders').select('total_amount').gte('order_date', fromDate).lte('order_date', toDate)
```

The same dashboard already proves the intended tenant contract by company-scoping the primary orders query. The second query must follow the same contract.

### Ready replacement

```js
supabase.from('orders')
    .select('total_amount')
    .eq('company_id', companyId)
    .gte('order_date', fromDate)
    .lte('order_date', toDate)
```

Status: CONFIRMED DEFECT / NOT YET SOURCE-COMMITTED IN THIS SESSION.

---

### M2-02 — Dashboard "Top Items" uses undefined `orderIds`

Current source calls:

```js
supabase.from('order_details').select('item_code, item_name, qty, unit_price').in('order_id', orderIds)
```

The directly inspected `loadAll()` scope does not define `orderIds`. The primary orders query does return `id`, but the IDs are not extracted before the top-items query executes.

### Ready replacement

Move the top-items query into the already company-scoped orders callback, after `var orders = res.data || [];`:

```js
var orderIds = orders.map(function(o) { return o.id; }).filter(Boolean);

if (orderIds.length === 0) {
    renderTopItemsChart([]);
} else {
    supabase.from('order_details')
        .select('item_code, item_name, qty, unit_price')
        .in('order_id', orderIds)
        .then(function(res) {
            renderTopItemsChart(res.data || []);
        })
        .catch(function() {
            renderTopItemsChart([]);
        });
}
```

Status: CONFIRMED RUNTIME BUG / NOT YET SOURCE-COMMITTED IN THIS SESSION.

This preserves the existing business intent while deriving the child rows from the already company-scoped order set.

---

### M2-03 — Category replacement selector is not company-scoped

Current source in `_deleteCategory()` checks the current company's items, but then loads replacement categories with:

```js
supabase.from('categories').select('id, category_name').neq('id', id).order('category_name')
```

That permits the UI to present another company's category as a replacement candidate.

### Ready replacement

```js
supabase.from('categories')
    .select('id, category_name')
    .eq('company_id', companyId)
    .neq('id', id)
    .order('category_name')
```

Status: CONFIRMED TENANT INTEGRITY DEFECT / NOT YET SOURCE-COMMITTED IN THIS SESSION.

---

### M2-04 — Upload preview item lookup is not company-scoped

Current source uses:

```js
supabase.from('items').select('id, item_code, barcode, name').in('barcode', barcodes)
```

Production schema proves `item_code` has a global UNIQUE constraint, but no equivalent proof was found for `barcode`. Therefore the lookup cannot safely treat barcode as a global identity key.

### Ready replacement

```js
supabase.from('items')
    .select('id, item_code, barcode, name')
    .eq('company_id', companyId)
    .in('barcode', barcodes)
```

Status: CONFIRMED TENANT/IDENTITY DEFECT / NOT YET SOURCE-COMMITTED IN THIS SESSION.

---

### M2-05 — Upload preview validates rows but execution submits all rows

Current preview correctly counts invalid rows, but `_executeUpload()` builds its `items` payload from the full `_uploadFileData` array. Therefore disabling the button only when `validCount === 0` does not prevent execution of invalid rows when some rows are valid.

### Ready replacement

The preview must mark valid entries explicitly:

```js
entry._valid = !!item && !status;
```

Then `_executeUpload()` must submit only validated entries:

```js
var items = [];
for (var u = 0; u < _uploadFileData.length; u++) {
    var row = _uploadFileData[u];
    if (!row._valid || !row.item_code) continue;
    items.push({
        item_code: row.item_code,
        qty: row.qty
    });
}

if (!items.length) {
    showToast('لا توجد صفوف صالحة للتنفيذ', 'warning');
    return;
}
```

Status: CONFIRMED VALIDATION-BYPASS DEFECT / NOT YET SOURCE-COMMITTED IN THIS SESSION.

---

### M2-06 — Adjustment success handler expects a non-existent `results[]` contract

Current source expects:

```js
(json.results || [])
```

Direct Production inspection proves `post_inventory_adjustment_atomic` returns `movement_count`, not `results[]`.

### Ready replacement

```js
var successCount = Number(json.movement_count || 0);
var failCount = 0;
showToast(
    'تم تحديث ' + successCount + ' صنف بنجاح',
    successCount > 0 ? 'success' : 'warning'
);
```

Do not fabricate per-line failure counts in the frontend when the backend contract does not provide them.

Status: CONFIRMED FRONTEND/BACKEND CONTRACT DRIFT / NOT YET SOURCE-COMMITTED IN THIS SESSION.

---

### M2-07 — Adjustment voucher code is random, weakening retry idempotency

Current source generates:

```js
var voucherCode = 'ADJ-' + new Date().toISOString().split('T')[0].replace(/-/g, '') + '-' + Math.floor(Math.random() * 1000);
```

Production's adjustment engine derives its idempotency key from `voucher_code + item_id`. Therefore a retry that regenerates the voucher code is not the same operation from the backend's point of view.

This is not safe to solve purely by guessing a frontend-only contract. The proper closure requires a stable client operation identity and an explicit backend/RPC contract for it.

Status: CONFIRMED ARCHITECTURAL GAP / OPEN DEPENDENCY. No speculative API parameter was invented.

---

### M2-08 — Item movement report has no company predicate

Current `_loadMovementReport()` queries `stock_vouchers` without `.eq('company_id', companyId)`.

### Ready replacement

```js
var vouchersRes = await supabase.from('stock_vouchers')
    .select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id')
    .eq('company_id', companyId)
    .order('voucher_date', { ascending: true });
```

Status: CONFIRMED TENANT REPORTING DEFECT / NOT YET SOURCE-COMMITTED IN THIS SESSION.

## 5. Production data integrity observation

A prior forensic snapshot identified historical cross-company item references in `stock_branches`. Current Production must be treated according to the latest direct snapshot, not that historical count. The current Production has one company, so the old multi-company contamination snapshot is not a current-state metric and must not be reused as a present-tense percentage or defect count without a new query.

No destructive data cleanup was executed in this Main2 source session. This was deliberate: the Main2 task does not authorize inventing data ownership mappings, and the governance rules require source/history/downstream proof before repair.

## 6. Experiments and outcomes

### Read-only source verification

PASS — current Main2 source and current commit lineage were inspected directly.

### Production synchronization

PASS — direct Production query at 2026-09-05 00:21:30.867647 UTC.

### Production adjustment RPC contract inspection

PASS — current deployed definition inspected; return shape is `movement_count`, not `results[]`.

### Destructive/fixture tests

NOT RUN against permanent Production data. The current Production has no purchase orders or orders to use as realistic positive fixtures, so creating permanent synthetic business data would violate the data-integrity rule.

## 7. What was not safely changed

`Current/PWA/main2/main2.md` was intentionally not rewritten in this session.

Reason: the available Git write primitive replaces the complete UTF-8 file. The governing continuity rule explicitly prohibits a whole-file rewrite for narrow defects. The file is large, and the connector does not provide an atomic line-range patch operation. Reconstructing the entire 1500+ line artifact manually from truncated connector responses would introduce a larger, unverifiable risk than the defects being repaired.

This is a tooling/patch-surface limitation, not a claim that the identified defects are harmless.

The defects above are therefore recorded as exact ready-to-swap surgical replacements for the next source-edit operation.

## 8. Git / CI state

Commit `a6556235c5768d9514ee3e910ae795391e3ab868` is directly confirmed as the Main2 surgical tenant-scoping commit.

No combined CI status was reported for that commit.

## 9. Final self-audit

Business Understanding = CONFIRMED for Main2 dashboard/items/upload/report surfaces.

Architecture Understanding = CONFIRMED for tenant-scoping and adjustment-engine contract boundary.

Database Understanding = DIRECTLY VERIFIED for relevant Production constraints and adjustment RPC.

Historical Understanding = RECONCILED enough to avoid repeating prior Main2 surgery.

Current Git Understanding = DIRECTLY VERIFIED.

Current Production Understanding = DIRECTLY VERIFIED at 2026-09-05 00:21:30.867647 UTC.

Source patch execution = NOT COMPLETE.

Production runtime verification of Main2 = NOT COMPLETE.

### Confirmed facts

- Main2 prior tenant-scoping surgery exists in Git.
- Main2 current blob is `b1096fdadd4734881d2c16c341dea769fc306fc5` in the directly fetched commit lineage.
- Seven remaining Main2 source defects/dependency points are confirmed above.
- Production adjustment RPC returns `movement_count` directly.
- Production currently has no purchase orders or orders for a realistic positive test fixture.

### Unknowns / open boundaries

- exact final assembled 11-part parent artifact;
- final browser/runtime deployment mapping;
- stable client operation identity for adjustment retries;
- complete Main2 runtime closure after surgical source edits.

## 10. Verdict

`MAIN2 SOURCE = HISTORICAL SURGERY PRESENT`

`MAIN2 CURRENT FORENSIC REVIEW = COMPLETED FOR THIS PASS`

`MAIN2 SURGICAL SOURCE CLOSURE = OPEN`

`MAIN2 PRODUCTION/RUNTIME CLOSURE = OPEN`

The correct next operation is not another report. It is a controlled line-level source patch using the replacements in M2-01 through M2-08, then source syntax validation, then assembly reconciliation, and only afterward runtime/Production verification.
