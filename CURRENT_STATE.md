# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD BEFORE THIS STATE UPDATE = e53c0de15fd29273d1388713d940f7792577a540
REPORT68 COMMIT = 918809db231139e38550f23dd690c65fb4d72035
REPORT69 COMMIT = ba750f3707560b7c2bf4e6ebaa8d0eeca3f2db47
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

### Report68

```text
918809db231139e38550f23dd690c65fb4d72035
Report68 — reopen M2-11 according to the central inventory movement contract
```

### Report69

```text
ba750f3707560b7c2bf4e6ebaa8d0eeca3f2db47
Report69 — forensic main2 review and CURRENT_STATE reconciliation
```

Report69 verified the actual `main2.md` blob at the current HEAD, reconciled a stale state entry, rechecked Production, and classified the remaining manual edits precisely.

## PRODUCTION TRUTH — DIRECT

Latest direct reconciliation:

```text
2026-09-05
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
```

Relevant schema facts verified directly:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

Current `inventory_log` does NOT yet contain:

```text
source_branch_id
target_branch_id
```

Current `post_stock_movement` DOES accept:

```text
p_source_branch_id
p_target_branch_id
```

and currently writes Physical Stock to `stock_branches` plus an `inventory_log` row without those branch identities.

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
CURRENT SOURCE BLOB = 089453ca6412df986fa11c2df4ce9235091a4647
```

This Blob is the source present at the current Git HEAD `e53c0de...`.

The earlier `CURRENT_STATE` reference to Blob `c503fde4...` was stale and has been corrected here.

## MAIN2 VERIFIED STATE

### Report66 fixes

The four Report66 corrections are already present and must NOT be repeated.

`_renderTable()` already has the required closing brace before the status cell. Do not add another `}`.

### PATCH A — UNIT FIELD

Already applied in current Git.

Current correct source is:

```javascript
html += '<div class="flex flex-col"><label class="text-sm font-bold">الوحدة الأساسية</label><input id="item-unit" value="' + _esc(item ? (item.unit || '') : '') + '" class="p-2.5 bg-gray-50 border rounded-lg"></div>';
```

Do NOT ask the user to change this again.

### PATCH B — CENTRAL MOVEMENT REPORT

OPEN.

Current `_loadMovementReport()` still reads:

```text
stock_vouchers + stock_voucher_details
```

The final architecture requires:

```text
inventory_log
+
company_id
+
item_id
+
source_branch_id
+
 target_branch_id
```

Patch B must NOT be applied until the Production branch-attribution contract exists and is verified.

When the Production contract is closed, replace the complete `_loadMovementReport()` function using the exact full function recorded in Report68 section 8.

The deletion boundary is from:

```javascript
async function _loadMovementReport() {
```

through its closing brace immediately before:

```javascript
// ==================== مصفوفة الفروع – بدون تغيير ====================
```

### PATCH C — DUPLICATE MOVEMENT READER

OPEN.

Current `_showBranchStockMovement()` still performs its own voucher-based movement query.

After Patch B's Production prerequisite is closed, replace the complete function from:

```javascript
async function _showBranchStockMovement(itemCode, itemName, branchId, branchName) {
```

through the line immediately before:

```javascript
function _loadCategoriesIntoSelect() {
```

with the exact delegating function stored in Report68 section 9 / Report69 section 8.

### PATCH D — FILE IMPORT IDENTITY CONTRACT

OPEN — NO PATCH YET.

Current `_handleFileSelect()` accepts:

```text
barcode
item_code
باركود
الكود
```

but `_renderUploadPreview()` subsequently looks only in `items.barcode`.

This is a proven internal inconsistency, but the historical/template contract for `item_code` input is not yet proven. Do not change behavior until that contract is established.

## HISTORICAL LEGACY DATA

Current `inventory_log` contains 3 `VoidInvoice` records associated with `ORD-1015` / `ORD-1016` and no current matching `orders` or `stock_vouchers`.

Rules:

```text
DO NOT DELETE
DO NOT INVENT BRANCH ATTRIBUTION
DO NOT USE TO MANUFACTURE CURRENT PHYSICAL BALANCE
```

Any historical repair must be a separate evidence-backed data-repair unit with audit preservation.

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
M2-11 = OPEN / CENTRAL MOVEMENT CONTRACT + MOVEMENT READERS
M2-12 = CLOSED IN CURRENT SOURCE
```

## CURRENT VALIDATION STATUS

```text
Current Git HEAD = VERIFIED
Current main2 Blob = VERIFIED DIRECTLY
Production snapshot = VERIFIED DIRECTLY
post_stock_movement = VERIFIED DIRECTLY
inventory_log schema = VERIFIED DIRECTLY
Report66 fixes = VERIFIED IN CURRENT SOURCE
PATCH A unit field = ALREADY PRESENT
PATCH B movement reader = NOT APPLIED
PATCH C duplicate movement reader = NOT APPLIED
Production branch attribution = NOT PRESENT
Browser Runtime = NOT VERIFIED
Static/Syntax PASS after future manual edits = NOT VERIFIED
11-part assembly = NOT VERIFIED
Final PWA Production Equivalence = NOT VERIFIED
```

## SELF-AUDIT — REPORT69

### WHAT I PROVED

- MASTER Continuity was read completely.
- `CURRENT_STATE.md` was read and reconciled against Git and Production.
- Report67 and Report68 were read.
- `e53c0de...` is the current `main` HEAD.
- Current `main2.md` Blob is `089453ca...`.
- `item-unit` is already corrected in current Git.
- `_loadMovementReport()` is still voucher-based.
- `_showBranchStockMovement()` is still a second voucher-based reader.
- Production does not yet provide branch attribution in `inventory_log`.
- `post_stock_movement` remains the Physical Stock owner.
- Production counts were remeasured directly.
- A separate upload-import contract inconsistency was proven but deliberately left unpatched because its historical contract is not yet established.

### WHAT I DID NOT PROVE

- Browser runtime after future manual main2 changes.
- Static/syntax PASS after future manual edits.
- Production runtime for the central movement report.
- Closure of M2-10.
- Closure of M2-11.
- Final 11-part assembly.
- Final PWA Production equivalence.

### WHAT CHANGED

```text
main2.md = NOT MODIFIED BY THIS SESSION
Production business data = NOT MODIFIED BY THIS SESSION
Report69 = CREATED
CURRENT_STATE.md = RECONCILED TO ACTUAL CURRENT GIT/PRODUCTION STATE
```

## CURRENT AUTHORIZED NEXT ACTION

```text
1. Close the Production inventory_log branch-attribution contract.
2. Modify post_stock_movement so every new log stores source_branch_id / target_branch_id.
3. Verify Production schema + function definition.
4. User manually applies PATCH B in main2.md using the exact Report68 function.
5. User manually applies PATCH C in main2.md using the exact delegating function.
6. Re-read main2.md completely from Git.
7. Verify Report66 corrections remain intact.
8. Run static/syntax review.
9. Record the actual main2 commit.
10. Perform Browser/Production Runtime verification.
11. Then resolve PATCH D only after proving the historical import-file contract.
12. Reassess M2-10 and remaining closures.
```

## FORBIDDEN ACTIONS

```text
Do NOT repeat Patch A.
Do NOT repeat Report66 fixes.
Do NOT modify main1.md or main3..main11 in this closure.
Do NOT modify core.js, sw.js, register-sw.js, manifest.json in this closure.
Do NOT delete historical inventory_log rows.
Do NOT infer old branch identities.
Do NOT apply Patch B before Production branch attribution exists.
Do NOT patch PATCH D from guesswork.
Do NOT claim Runtime/Production closure without direct evidence.
```
