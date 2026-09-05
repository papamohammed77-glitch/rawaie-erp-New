# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD = THIS STATE COMMIT
PREVIOUS VERIFIED MAIN2 SOURCE = c503fde4d2da73d241d693e81f67405445d85747
REPORT67 COMMIT = 60c71a7d2d091bed5c7d127c90e1f221a8863063
REPORT68 COMMIT = 918809db231139e38550f23dd690c65fb4d72035
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

## GOVERNANCE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > CURRENT DEPLOYMENTS > CURRENT DATABASE CONTRACTS > HISTORICAL CONTRACTS > REPORTS > MEMORY > ASSUMPTIONS
UNKNOWN != BUG
UNKNOWN != REMOVE
READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY
ONE CLOSURE UNIT AT A TIME
GIT != DEPLOYMENT PROOF
SOURCE != RUNTIME PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

Primary governance source:
`doc/Draft/medhat/MASTER - RAWAEA ERP.md`

## LAST VERIFIED EVENTS

### Report67

```text
60c71a7d2d091bed5c7d127c90e1f221a8863063
Report67 — forensic reconciliation after Report66
```

Report67 proved the `item-unit` field-source defect and documented the earlier deferred movement-report issue.

### Report68

```text
918809db231139e38550f23dd690c65fb4d72035
Report68 — reopen M2-11 according to the central inventory movement contract
```

Report68 re-investigated the deferred movement-report issue against current Production instead of assuming the Report67 boundary was still sufficient.

## PRODUCTION TRUTH — DIRECT

Latest direct reconciliation in this session:

```text
2026-09-05 — current session
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
```

Relevant current schema facts:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

Current `post_stock_movement` contract accepts:

```text
p_source_branch_id
p_target_branch_id
```

but the current `inventory_log` schema does not store those two identities.

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
SOURCE BLOB VERIFIED = c503fde4d2da73d241d693e81f67405445d85747
MAIN2 MODIFIED IN THIS SESSION = NO
```

The four Report66 corrections remain present in current source and must not be repeated.

`_renderTable()` already contains the required closing brace before the status cell. Do not add another brace.

## CONFIRMED UNIT DEFECT

Location:

```text
Current/PWA/main2/main2.md
function openItemPage(itemCode)
id = item-unit
```

Current incorrect source:

```javascript
item.alt_unit
```

Required manual correction remains:

```javascript
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة الأساسية</label><input id="item-unit" value="' + _esc(item ? (item.unit || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

The defect is proven because `_handleSaveFromPage()` sends `item-unit` as `unit`, and Production `save-item` persists the submitted `unit`.

## M2-11 — CENTRAL MOVEMENT REPORT CONTRACT

The current main2 movement report still reads:

```text
stock_vouchers + stock_voucher_details
```

This is no longer an acceptable final architecture because the current Inventory Contract is:

```text
Physical Movement
→ post_stock_movement
→ stock_branches + inventory_log
```

Direct Production evidence proved that `post_stock_movement` already knows the source/target branches but `inventory_log` does not store them.

Therefore the permanent solution is NOT to make main2 infer branch attribution from vouchers.

### Required backend contract before the final main2 movement patch

Add nullable columns to `inventory_log`:

```text
source_branch_id uuid
 target_branch_id uuid
```

Add foreign keys to `branches(id)` while preserving NULL for historical rows that cannot be safely reconstructed.

Modify `post_stock_movement` so every newly created inventory_log row records:

```text
source_branch_id = p_source_branch_id
target_branch_id = p_target_branch_id
```

Do not delete historical inventory_log rows.
Do not invent branch attribution for rows where the source cannot be proven.

### Historical legacy evidence

The current `inventory_log` has 3 records with:

```text
movement_type = VoidInvoice
voucher_id = ORD-1015 / ORD-1016
```

No current `stock_vouchers` match these codes.
No current `orders` match these codes.

These records are therefore retained as historical/legacy records and must not be used to manufacture current Physical Stock balances.

## EXACT MAIN2 SURGICAL PATCH — AFTER THE BACKEND CONTRACT EXISTS

### PATCH A — unit field

Search for the complete line beginning with:

```javascript
html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة الأساسية</label>
```

and ending with:

```text
class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

Delete that entire line and replace it with the exact line in the UNIT DEFECT section above.

### PATCH B — replace `_loadMovementReport()` completely

Delete the complete function beginning exactly with:

```javascript
async function _loadMovementReport() {
```

and ending with the closing brace immediately before:

```javascript
// ==================== مصفوفة الفروع – بدون تغيير ====================
```

Replace the entire function with the exact version recorded in Report68 section 8.

Required architectural properties of the replacement:

```text
SOURCE = inventory_log only
IDENTITY = item_id
TENANT = company_id
BRANCH = source_branch_id / target_branch_id
NO stock_vouchers lookup
NO stock_voucher_details lookup
OPENING BALANCE = calculated from earlier central logs
RUNNING BALANCE = movement impact by branch
TRANSFER = source negative / target positive
LOADING = source negative / target positive
UNLOADING = source negative / target positive
UNKNOWN LEGACY MOVEMENT TYPES = not used to manufacture Physical Stock balance
```

### PATCH C — remove the duplicate movement reader

Delete the complete function beginning exactly with:

```javascript
async function _showBranchStockMovement(itemCode, itemName, branchId, branchName) {
```

and ending immediately before:

```javascript
function _loadCategoriesIntoSelect() {
```

Replace it with:

```javascript
    async function _showBranchStockMovement(itemCode, itemName, branchId, branchName) {
        _switchSubTab('movement');
        window._movementItemCode = itemCode || null;
        window._movementItemName = itemName || '';
        window._movementBranchId = branchId || null;
        window._movementBranchName = branchName || '';
        setTimeout(function() {
            _renderStockMovementReport(itemCode || null, itemName || '', branchId || null, branchName || '');
        }, 0);
    }
```

This makes the movement UI use one reader path instead of two independent implementations.

## DO NOT REPEAT

```text
Do NOT re-add the _renderTable() brace.
Do NOT repeat the four Report66 fixes.
Do NOT add another _jsAttr helper.
Do NOT modify main1.md or main3..main11.
Do NOT modify core.js, sw.js, register-sw.js, manifest.json in this closure.
Do NOT delete legacy inventory_log records.
Do NOT infer historical branch_id when it cannot be proven.
Do NOT make main2 derive Physical Stock movement from stock_vouchers after the central inventory_log contract is established.
```

## CURRENT MAIN2 STATUS

```text
M2-01 = CLOSED
M2-02 = CLOSED
M2-03 = CLOSED
M2-04 = CLOSED
M2-05 = CLOSED
M2-06 = CLOSED
M2-07R = CLOSED IN CURRENT SOURCE
M2-08 = CLOSED
M2-09 = CLOSED IN CURRENT SOURCE
M2-10 = OPEN / CROSS-LAYER SERVER AUTHORIZATION
M2-11 = OPEN / unit-field defect + central movement-report contract
M2-12 = CLOSED IN CURRENT SOURCE
```

## CURRENT VALIDATION STATUS

```text
Report66 source corrections = VERIFIED IN CURRENT GIT
Current main2 source = VERIFIED DIRECTLY
Production snapshot = VERIFIED DIRECTLY
post_stock_movement current definition = VERIFIED DIRECTLY
inventory_log current rows = VERIFIED DIRECTLY
Unit-field correction = NOT APPLIED IN main2
Central branch-attribution schema = NOT YET ADDED
Central movement-report main2 patch = NOT YET APPLIED
Browser runtime after unit fix = NOT VERIFIED
Static/syntax after unit fix = NOT VERIFIED
11-part assembly = NOT VERIFIED
Final PWA production equivalence = NOT VERIFIED
```

## SELF-AUDIT

### What I Proved

- MASTER Continuity command was read completely.
- CURRENT_STATE was reconciled.
- Report66 was read completely.
- Report67 was read completely.
- Current main2 blob was read directly and in full.
- Current Production counts were rechecked directly.
- Current `post_stock_movement` was inspected directly.
- `inventory_log` current rows were inspected directly.
- The movement report's dependence on `stock_vouchers` was confirmed from current main2.
- The missing branch attribution in `inventory_log` was confirmed from Production schema.
- The existence of legacy `VoidInvoice` log records without currently matching vouchers/orders was confirmed.
- The permanent architectural boundary was therefore proven: main2 cannot safely infer a complete central movement history until branch attribution is part of the central movement record.

### What I Did Not Prove

- Browser runtime after manual main2 changes.
- Static/syntax PASS after manual changes.
- Production runtime of the rewritten movement report.
- Complete historical backfill of old inventory_log records.
- Closure of M2-10.
- Final 11-part assembly.
- Final PWA production equivalence.

### What Changed In This Session

```text
main2.md = NOT MODIFIED
Report68 = ADDED
CURRENT_STATE.md = UPDATED
Production business data = NOT MODIFIED
```

### Final Closure

```text
MAIN2 = OPEN
M2-10 = OPEN
M2-11 = OPEN
PROJECT CLOSURE = NOT CLAIMED
```

## NEXT AUTHORIZED ACTION

```text
1. Implement the inventory_log branch-attribution contract first.
2. Deploy/update post_stock_movement to populate source_branch_id and target_branch_id.
3. Verify the new Production schema and writer contract.
4. Apply PATCH A (unit field) manually in main2.md.
5. Apply PATCH B (central movement report) manually in main2.md.
6. Apply PATCH C (remove duplicate movement reader) manually in main2.md.
7. Re-read main2.md completely from Git.
8. Verify Report66 corrections remain intact.
9. Run static/syntax review.
10. Record the actual Main2 commit.
11. Then perform runtime and Production verification.
12. Reassess M2-10 and the remaining Main2 closures from the new verified state.
```
