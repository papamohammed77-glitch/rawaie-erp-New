# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD BEFORE THIS STATE UPDATE = e12d6d910f298dddbd17d9af2781a78ca9560050
CURRENT GIT HEAD AFTER THIS STATE UPDATE = THIS COMMIT
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
REPORT62 = cd1fcb9c126d43b238360cf0b795c1cf5e1c7b61
```

## GOVERNANCE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > DEPLOYMENTS > DATABASE CONTRACTS > HISTORY > REPORTS > MEMORY > ASSUMPTIONS
UNKNOWN != BUG
UNKNOWN != REMOVE
READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY
ONE CLOSURE UNIT AT A TIME
GIT != DEPLOYMENT PROOF
SOURCE != RUNTIME PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

Primary governance source: `doc/Draft/medhat/MASTER - RAWAEA ERP.md`.

## LAST VERIFIED EVENTS

```text
a6556235c5768d9514ee3e910ae795391e3ab868
fix(main2): surgical tenant-scoping and dashboard integrity
= ACTUAL MAIN2 SOURCE MUTATION

ac360fbe6626979e4dd43cec34b04a1c3e61b210
fix(main2): remove residual undefined orderIds and scope barcode lookup
= ACTUAL MAIN2 SOURCE MUTATION
= CLOSED M2-02 + M2-04

e9d0ec685737abf9b752d40acc2d97cd2aa4907e
Report60 documentation

dd6da64a1615ffbedd3d548c4f9668a2efa3b9f5
Report61 documentation

cd1fcb9c126d43b238360cf0b795c1cf5e1c7b61
Report62 Main2 surgical re-check

CURRENT_STATE FINAL UPDATE = THIS COMMIT
```

Historical reports are preserved.

## PRODUCTION TRUTH — DIRECT

Verified at `2026-09-05 01:21:11.637601+00`:

```text
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
DUPLICATE NON-EMPTY BARCODES = 0
```

Schema:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
BLOB = 15f101d3bea93baa5419bdca48e401ad71bbac6c
MAIN2 SOURCE MODIFIED BY THIS SESSION = NO
```

Main2 was re-read directly from current Git. No source mutation was made because the owner explicitly required manual edits.

## MAIN2 MATRIX

```text
M2-01 = CLOSED
M2-02 = CLOSED — ac360f
M2-03 = CLOSED
M2-04 = CLOSED — ac360f
M2-05 = CLOSED
M2-06 = CLOSED
M2-07R = OPEN
M2-08 = CLOSED
M2-09 = OPEN
M2-10 = OPEN / CROSS-LAYER SECURITY
M2-11 = OPEN / HTML-DOM-INLINE-JS HARDENING
M2-12 = OPEN / PREVENTIVE BARCODE HARDENING
```

## M2-07R — EXACT MANUAL PATCH

Inside `_executeUpload()` success branch, immediately before `RW_Data.loadItems()`, find:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

Delete both and replace with:

```javascript
_uploadFileData = [];
_uploadOperationId = null;
_uploadOperationFingerprint = null;
var uploadFileInput = byId('upload-file-input');
if (uploadFileInput) uploadFileInput.value = '';
```

Do not weaken backend idempotency.

## M2-09 — EXACT MANUAL PATCH

Inside `_loadMovementReport()` replace the current one-line `vouchersRes` query with:

```javascript
var vouchersQuery = supabase.from('stock_vouchers')
    .select('id, voucher_code, voucher_date, type, reference, from_branch_id, to_branch_id')
    .eq('company_id', companyId);

if (fromDate) {
    vouchersQuery = vouchersQuery.gte('voucher_date', fromDate);
}
if (toDate) {
    vouchersQuery = vouchersQuery.lte('voucher_date', toDate);
}
if (window._movementBranchId) {
    vouchersQuery = vouchersQuery.or(
        'from_branch_id.eq.' + window._movementBranchId + ',to_branch_id.eq.' + window._movementBranchId
    );
}

var vouchersRes = await vouchersQuery.order('voucher_date', { ascending: true });
```

Inside `_renderStockMovementReport()` replace the current `if (itemCode)` state block with:

```javascript
window._movementItemCode = itemCode || null;
window._movementItemName = itemName || '';
window._movementBranchId = branchId || null;
window._movementBranchName = branchName || '';

if (itemCode) {
    setTimeout(function() { _loadMovementReport(); }, 300);
}
```

## M2-10 — OPEN

Production `delete-item` Version 2 authenticates the user but does not prove authorization before service-role deletion. No permission key is invented. UI hiding alone is not accepted as security closure.

## M2-11 — OPEN

`core.js` `safeHTML()` writes directly to `innerHTML`. Main2 has raw DB/upload values in HTML and inline JS contexts.

First helper replacement:

```javascript
function _esc(s) {
    return esc(s == null ? '' : String(s));
}

function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}
```

Rule:

```text
HTML text/attributes → _esc(...)
Inline JavaScript arguments → _jsString(...)
```

At minimum inspect/fix raw values for category names, item names/categories/descriptions/images, `currentName`, and upload barcode/name output.

## M2-12 — OPEN

Production proves `items.barcode` is not UNIQUE, while current duplicates are zero. Main2 currently uses `itemMap[it.barcode] = it`, which is last-write-wins if duplicates appear.

Preventive patch: detect duplicate barcode keys, mark those upload rows invalid, and never silently choose one item. Exact implementation is in Report62.

## SEMANTIC UNKNOWN — DO NOT PATCH

```text
Dashboard net profit = totalSales - totalPurchases
Top Customers = grouped by customer_name
branchIds fallback
```

Business contract is not proven; do not change these in this closure.

## INVENTORY CONTRACT

```text
PHYSICAL STOCK MOVEMENT
    ↓
post_stock_movement
    ↓
stock_branches + inventory_log
```

`reserve_stock` and `release_stock_reservation` remain reservation capabilities.

Production `post_inventory_adjustment_atomic` is `SECURITY DEFINER` and delegates physical movement to `post_stock_movement`.
Production `bulk-stock-adjustment` Version 6 obtains company context via `users.auth_id` and is tenant-safe at wrapper level.

## EVIDENCE / REPORTS

```text
Report59_Main2_Surgical_Forensic_20260905.md
Report60_Main2_Surgical_Completion_20260905.md
Report61_Main2_Deep_Forensic_Continuation_20260905.md
Report62_Main2_Surgical_Recheck_20260905.md
```

## WHAT THIS SESSION CHANGED

```text
Report62 = ADDED
CURRENT_STATE = UPDATED
main2.md = NOT MODIFIED
main1.md = NOT MODIFIED
main3…main11 = NOT MODIFIED
New-main = NOT MODIFIED
core.js = NOT MODIFIED
sw.js = NOT MODIFIED
register-sw.js = NOT MODIFIED
manifest.json = NOT MODIFIED
```

No permanent Production business data was introduced by this Main2 forensic pass.

## NEXT AUTHORIZED ACTION

```text
1. Owner applies M2-07R manually.
2. Owner applies M2-09 manually.
3. Owner applies M2-11 manually.
4. Owner applies M2-12 manually.
5. Re-read Main2 from Git.
6. Static/syntax review + unrelated-diff review.
7. Commit Main2 source mutation.
8. Reconcile CURRENT_STATE again.
9. Dedicated M2-10 server-side authorization closure.
10. Only then proceed to 11-part assembly and companion-file reconciliation.
```

Do not reopen M2-02 or M2-04 without new contradictory direct evidence.

## FINAL SELF-AUDIT

```text
CURRENT GIT = VERIFIED BEFORE THIS UPDATE
CURRENT PRODUCTION = DIRECTLY VERIFIED
CURRENT MAIN2 = DIRECTLY RE-READ
HISTORICAL REPORTS = RECONCILED
MAIN2 SOURCE CLOSURE = OPEN
MAIN2 RUNTIME = OPEN
ASSEMBLY = OPEN

PROVED:
- M2-02/M2-04 are closed in current Git.
- M2-07R and M2-09 are still open and have exact manual patches.
- M2-10 is a server-side authorization gap.
- M2-11 is a real unsafe HTML/inline-JS data-context issue.
- M2-12 is preventive hardening justified by the schema.

NOT PROVED:
- Browser/runtime after manual source edits.
- 11-part assembled parent artifact.
- Final PWA production equivalence.
- Net-profit business contract.
- Customer identity aggregation contract.
- Full delete authorization closure.

CLOSURE = NOT CLAIMED
```

## CONTINUITY LOCK

Start from this state. Independently verify the latest Git HEAD and Production before acting. The immediate manual Main2 edits are fully specified in `Report62_Main2_Surgical_Recheck_20260905.md`.
