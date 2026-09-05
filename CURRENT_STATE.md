# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PREVIOUS GIT STATE HEAD = e53c0de15fd29273d1388713d940f7792577a540
REPORT69 COMMIT = ba750f3707560b7c2bf4e6ebaa8d0eeca3f2db47
REPORT70 COMMIT = 5f0a018c92a8c74415039e5016899a9af9d29c69
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

### Report69

```text
ba750f3707560b7c2bf4e6ebaa8d0eeca3f2db47
Report69 — forensic main2 review and CURRENT_STATE reconciliation
```

Report69 proved the actual `main2.md` Blob at the current HEAD and found that Patch A was already present while movement readers remained open.

### Report70

```text
5f0a018c92a8c74415039e5016899a9af9d29c69
Report70 — Production branch-attribution contract deployment and verification
```

Report70 closed the Production prerequisite for the central movement-report rewrite.

## PRODUCTION TRUTH — DIRECT

Latest direct reconciliation before/after the branch-attribution deployment:

```text
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
```

Relevant schema facts:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

### Production branch attribution status

```text
inventory_log.source_branch_id = PRESENT
inventory_log.target_branch_id = PRESENT
source FK = PRESENT
 target FK = PRESENT
post_stock_movement writes source_branch_id / target_branch_id = VERIFIED
```

A real transactional `InventoryIncrease` test was executed and rolled back. The test log contained the expected target branch and NULL source; after rollback, the test idempotency key had zero rows. No business-data mutation remains from the test.

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
CURRENT SOURCE BLOB = 089453ca6412df986fa11c2df4ce9235091a4647
```

This is the source verified at the pre-report current Git HEAD. `main2.md` was NOT modified by the assistant.

## MAIN2 VERIFIED STATE

### Report66

All four Report66 corrections remain present. Do not repeat them.

`_renderTable()` already has the required brace before the status cell. Do not add another `}`.

### PATCH A — UNIT FIELD

```text
STATUS = ALREADY APPLIED
```

The current source already uses `item.unit` in the `item-unit` field.

### PATCH B — CENTRAL MOVEMENT REPORT

```text
STATUS = READY FOR MANUAL APPLICATION
```

Production prerequisite is now CLOSED.

User must replace the complete `_loadMovementReport()` function using the exact full function recorded in Report68 section 8.

Deletion starts exactly at:

```javascript
async function _loadMovementReport() {
```

and ends at the closing brace immediately before:

```javascript
// ==================== مصفوفة الفروع – بدون تغيير ====================
```

The replacement must query `inventory_log` only and use:

```text
company_id
item_id
movement_date
source_branch_id
target_branch_id
```

No `stock_vouchers`.
No `stock_voucher_details`.

### PATCH C — DUPLICATE MOVEMENT READER

```text
STATUS = READY FOR MANUAL APPLICATION
```

User must replace the complete `_showBranchStockMovement()` function.

Delete from exactly:

```javascript
async function _showBranchStockMovement(itemCode, itemName, branchId, branchName) {
```

through the line immediately before:

```javascript
function _loadCategoriesIntoSelect() {
```

Replace with:

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

### PATCH D — FILE IMPORT IDENTITY

```text
STATUS = OPEN / DO NOT PATCH YET
```

Current code accepts `item_code` as an input header but later looks only in `items.barcode`. This inconsistency is proven, but its historical import-file contract is not yet proven. Do not change it by assumption.

## HISTORICAL LEGACY DATA

The 3 historical `VoidInvoice` records remain untouched. Do not delete them, invent branch identities, or use them to manufacture current Physical Stock balance.

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
M2-11 = OPEN / MAIN2 MOVEMENT READER PATCH + VERIFICATION
M2-12 = CLOSED IN CURRENT SOURCE
```

## VALIDATION STATUS

```text
Git HEAD before Report69 = VERIFIED e53c0de...
Current main2 Blob = VERIFIED 089453ca...
Production branch attribution = DEPLOYED
Production branch attribution runtime test = VERIFIED TRANSACTIONALLY
Patch A = ALREADY PRESENT
Patch B = NOT APPLIED
Patch C = NOT APPLIED
Patch D = OPEN / NO PATCH
Browser Runtime after B/C = NOT VERIFIED
Static/Syntax after B/C = NOT VERIFIED
11-part assembly = NOT VERIFIED
Final PWA Production Equivalence = NOT VERIFIED
Project Closure = NOT CLAIMED
```

## SELF-AUDIT

### WHAT I PROVED

- MASTER, CURRENT_STATE, Report67 and Report68 were reviewed.
- Current Git HEAD was verified from the `main` ref.
- Current `main2.md` was read directly; actual Blob is `089453ca...`.
- The stale `c503...` Blob reference in the previous CURRENT_STATE was corrected.
- Patch A is already present in current main2 and must not be repeated.
- Movement readers B/C remain voucher-based in current main2.
- Production now has source/target branch attribution fields and FKs.
- `post_stock_movement` now persists source/target branch identity.
- A transactional runtime test proved the new branch attribution behavior and was rolled back.
- The upload `item_code`/`barcode` inconsistency is proven but not safely patchable without historical contract evidence.

### WHAT I DID NOT PROVE

- Browser runtime after the user's manual B/C changes.
- Static/syntax PASS after the user's manual B/C changes.
- Final 11-part assembly.
- Final PWA Production equivalence.
- M2-10 closure.
- Patch D historical contract.

## WHAT CHANGED IN THIS SESSION

```text
main2.md = NOT MODIFIED BY ASSISTANT
Production business data = NO PERMANENT TEST DATA ADDED
Production schema/function = MODIFIED AND VERIFIED
Report69 = CREATED
Report70 = CREATED
CURRENT_STATE.md = UPDATED
```

## NEXT AUTHORIZED ACTION — USER MANUAL MAIN2 EDIT

```text
1. DO NOT touch Patch A; it is already correct.
2. In Current/PWA/main2/main2.md, replace the entire _loadMovementReport() function exactly as specified in Report68 §8.
3. Replace the entire _showBranchStockMovement() function exactly as specified in Report68 §9 / Report70.
4. Do not edit any other Main2 section during this closure.
5. Re-read main2.md completely after saving.
6. Verify there is no stock_vouchers / stock_voucher_details usage inside either movement reader.
7. Verify Report66 fixes remain intact.
8. Record the user's actual Main2 commit.
9. Then perform static/syntax and runtime verification.
10. After that, investigate Patch D from historical evidence only.
```
