# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD = THIS STATE COMMIT
PREVIOUS VERIFIED HEAD = 03eeb944481605fc1756be13ff56860fd22c56de
REPORT66 COMMIT = 03eeb944481605fc1756be13ff56860fd22c56de
REPORT67 COMMIT = 60c71a7d2d091bed5c7d127c90e1f221a8863063
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

### 1. Main2 refactor

```text
efde7f74bd47f9b8c6480878f53594025a11a00d
Refactor rowHtml construction in main2.md
```

This commit contains the four structural/inline-JS corrections requested by Report66.

### 2. Report66

```text
03eeb944481605fc1756be13ff56860fd22c56de
Create Report66
```

Report66 documented the exact four Main2 corrections and explicitly stated that `_renderTable()` no longer needed the old missing-brace fix.

### 3. Report67

```text
60c71a7d2d091bed5c7d127c90e1f221a8863063
Report67 — forensic reconciliation after Report66
```

Report67 was created after re-reading CURRENT_STATE, MASTER, Report66, current Main2, Git history, current Production, and active save-item deployment.

## PRODUCTION TRUTH — DIRECT

Verified directly at:

```text
2026-09-05 07:13:34.611727 UTC
```

```text
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
duplicate_nonempty_barcode_groups = 0
```

Production project is healthy:

```text
SMART ERP / fiilmooggumokxanwiyx
PostgreSQL 17.6.1.121
region = eu-west-1
```

Relevant schema facts re-confirmed:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

No Production business data was permanently changed by this Main2 review.

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
CURRENT SOURCE BLOB = c503fde4d2da73d241d693e81f67405445d85747
MAIN2 SOURCE MODIFIED BY THIS SESSION = NO
```

The four corrections described in Report66 are already present in the current source.

### Report66 corrections confirmed present

```text
1. _renderBranchStockMatrix() rowHtml = corrected
2. _renderBranchStockMatrix() branch cell = corrected to _jsAttr
3. _renderBranchStockMatrixFiltered() rowHtml = corrected
4. _renderBranchStockMatrixFiltered() branch cell = corrected to _jsAttr
```

`_renderTable()` already contains the closing brace required before status-cell. Do not add another brace.

## NEW CONFIRMED MAIN2 DEFECT

Location:

```text
Current/PWA/main2/main2.md
function openItemPage(itemCode)
field id = item-unit
```

Current bad expression:

```javascript
item.alt_unit
```

The current field builder uses `alt_unit` as the value of the field labeled `الوحدة الأساسية`.

`_handleSaveFromPage()` then sends that field as:

```javascript
unit: (byId('item-unit') ? byId('item-unit').value : '').trim(),
```

Production `save-item` version 12 stores the received `item.unit` value.

Therefore the currently proven risk is:

```text
Edit existing item
→ openItemPage loads alt_unit into item-unit
→ save sends alt_unit as unit
→ save-item persists it as unit
```

This is a confirmed data/function defect, not a hypothesis.

## EXACT NEXT MANUAL PATCH

The user must manually modify `main2.md` only.

Search for the complete line beginning with:

```javascript
html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة الأساسية</label>
```

and ending with:

```text
class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

Delete the complete line and replace it with:

```javascript
        html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة الأساسية</label><input id="item-unit" value="' + _esc(item ? (item.unit || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

Only intended change:

```text
item.alt_unit → item.unit
```

## DO NOT REPEAT

```text
Do NOT re-add the _renderTable() closing brace.
Do NOT repeat the four Report66 rowHtml/branch-cell fixes.
Do NOT add another _jsAttr helper.
Do NOT change category handling based on this review; save-item resolves category_id to category_name.
Do NOT modify main1.md or main3..main11.
Do NOT modify core.js, sw.js, register-sw.js, manifest.json.
Do NOT modify Production business data.
Do NOT invent a new contract for the stock-movement report.
```

## OPEN / DEFERRED INTEGRATION ISSUE

`_renderStockMovementReport()` currently derives movement history from:

```text
stock_vouchers + stock_voucher_details
```

while the current Inventory Contract defines:

```text
Physical Movement
→ post_stock_movement
→ stock_branches + inventory_log
```

`inventory_log` does not currently expose branch_id directly, so a safe full rewrite of the movement report requires a proven branch-attribution contract.

This is recorded as an open integration/design issue, not a guessed patch.

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
M2-11 = OPEN / one confirmed unit-field source defect remains
M2-12 = CLOSED IN CURRENT SOURCE
```

## CURRENT VALIDATION STATUS

```text
Report66 source corrections = VERIFIED IN CURRENT GIT
Production snapshot = VERIFIED DIRECTLY
save-item deployment = VERIFIED DIRECTLY (version 12)
Browser runtime after unit fix = NOT VERIFIED
Static/syntax after unit fix = NOT VERIFIED
11-part assembly = NOT VERIFIED
Final PWA production equivalence = NOT VERIFIED
```

## SELF-AUDIT

### What I Proved

- MASTER governance was read through its final section.
- CURRENT_STATE was reconciled against the current Git HEAD.
- Report66 was read in full.
- Main2 current blob was read directly.
- Git history proved the Report66 four corrections already exist in current Main2.
- Current Production was rechecked directly.
- `save-item` Production version 12 was inspected.
- The `item.alt_unit` → `item.unit` defect was proven from the combined source/runtime path.
- Category handling was checked and explicitly not classified as a defect.

### What I Did Not Prove

- Browser runtime after the new unit-field correction.
- Final static/syntax execution after that correction.
- Complete 11-part assembly.
- Final PWA production equivalence.
- Closure of M2-10.
- Closure of the branch-attribution contract for the item movement report.

### What Changed In This Session

```text
main2.md = NOT MODIFIED
Report67 = ADDED
CURRENT_STATE.md = UPDATED
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
1. Apply the single unit-field correction in main2.md exactly as specified above.
2. Re-read main2.md from Git after the manual save.
3. Verify item-unit now uses item.unit.
4. Verify all four Report66 corrections remain intact.
5. Run static/syntax review and unrelated-diff review.
6. Record the actual Main2 commit.
7. Update CURRENT_STATE again.
8. Only then reassess M2-10 and the deferred movement-report contract.
```
