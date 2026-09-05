# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY CHECKPOINT — 2026-09-05

This file is the current continuity checkpoint. It is a declared state and must be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD VERIFIED = e12d6d910f298dddbd17d9af2781a78ca9560050
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

---

# 1. LAST VERIFIED EVENTS

```text
a6556235c5768d9514ee3e910ae795391e3ab868
fix(main2): surgical tenant-scoping and dashboard integrity
= ACTUAL MAIN2 SOURCE MUTATION

ac360fbe6626979e4dd43cec34b04a1c3e61b210
fix(main2): remove residual undefined orderIds and scope barcode lookup
= ACTUAL MAIN2 SOURCE MUTATION
= CLOSED M2-02 + M2-04 IN CURRENT GIT

e9d0ec685737abf9b752d40acc2d97cd2aa4907e
docs(cto): add Report60 Main2 surgical completion and self-audit
= HISTORICAL FORENSIC REPORT

dd6da64a1615ffbedd3d548c4f9668a2efa3b9f5
docs(cto): add Report61 Main2 deep forensic continuation
= HISTORICAL FORENSIC RECONCILIATION

cd1fcb9c126d43b238360cf0b795c1cf5e1c7b61
docs(cto): add Report62 Main2 surgical re-check
= CURRENT FORENSIC REPORT

STATE UPDATE AFTER THIS CHECKPOINT
= THIS COMMIT
```

Historical reports remain preserved. No report was deleted.

---

# 2. GOVERNING ENGINEERING RULES

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > DEPLOYMENTS > DATABASE CONTRACTS > HISTORY > REPORTS > MEMORY > ASSUMPTIONS

UNKNOWN != BUG
UNKNOWN != REMOVE

READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY

ONE CLOSURE UNIT AT A TIME
NO UNSAFE WHOLE-FILE REWRITE FOR A NARROW DEFECT

GIT != DEPLOYMENT PROOF
SOURCE != RUNTIME PROOF

NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

Primary governance source:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP.md
```

---

# 3. CURRENT PRODUCTION TRUTH — DIRECT SNAPSHOT

Latest direct Production verification in this continuity pass:

```text
UTC = 2026-09-05 01:21:11.637601+00
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

Additional schema facts verified directly:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

No permanent Production business data was introduced by the Main2 forensic review in this pass.

---

# 4. CURRENT GIT / MAIN2 SOURCE TRUTH

```text
CURRENT GIT HEAD = e12d6d910f298dddbd17d9af2781a78ca9560050
CURRENT MAIN2 PATH = Current/PWA/main2/main2.md
CURRENT MAIN2 BLOB = 15f101d3bea93baa5419bdca48e401ad71bbac6c
```

Current Main2 source was re-read directly during this pass and was not modified by the assistant.

Important reconciliation:

```text
Report60/Report61 are historical evidence.
Git history subsequently added ac360fbe, closing M2-02 + M2-04.
HEAD e12d6d9 is a documentation/state reconciliation commit.
```

---

# 5. MAIN1 CURRENT SOURCE STATE

```text
PATH = Current/PWA/main2/main1.md
SOURCE PATCH COMMIT = ed4e91ec595234ba7ede3f08558c660c1b100d3e
```

Verified source contract includes:

```text
RW_STATE.app.company.id
users.auth_id → users.company_id
app_settings scoped by company_id
items/customers/branches/suppliers scoped by company_id
```

Main1 Patch 1–4 remain source-closed.
Do not repeat them without new contradictory evidence.

---

# 6. MAIN2 CURRENT CLOSED / OPEN MATRIX

```text
M2-01 = CLOSED IN CURRENT SOURCE
M2-02 = CLOSED IN CURRENT SOURCE — ac360f
M2-03 = CLOSED IN CURRENT SOURCE
M2-04 = CLOSED IN CURRENT SOURCE — ac360f
M2-05 = CLOSED IN CURRENT SOURCE
M2-06 = CLOSED IN CURRENT SOURCE
M2-07R = OPEN — stale upload state after success can replay same input under a new voucher identity
M2-08 = CLOSED IN CURRENT SOURCE
M2-09 = OPEN — movement report date/branch filters are not wired into voucher query
M2-10 = OPEN — item deletion authorization is not enforced server-side
M2-11 = OPEN — HTML/DOM/inline-JS injection hardening required
M2-12 = OPEN — preventive barcode ambiguity guard required; current Production duplicates = 0
```

Current Main2:

```text
FORENSIC REVIEW = CURRENT
SOURCE CLOSURE = OPEN
RUNTIME CLOSURE = OPEN
ASSEMBLY CLOSURE = OPEN
```

---

# 7. M2-07R — OPEN ROOT CAUSE / EXACT MANUAL PATCH

Current success branch of `_executeUpload()` clears:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

while `_uploadFileData` remains populated.

Production adjustment idempotency is keyed by:

```text
InventoryAdjustment:<company_id>:<voucher_code>:<item_id>
```

Exact manual change:

```text
SEARCH inside _executeUpload() success branch immediately before RW_Data.loadItems():
_uploadOperationId = null;
_uploadOperationFingerprint = null;

DELETE both lines and replace with:
```

```javascript
_uploadFileData = [];
_uploadOperationId = null;
_uploadOperationFingerprint = null;
var uploadFileInput = byId('upload-file-input');
if (uploadFileInput) uploadFileInput.value = '';
```

Do not weaken or bypass the Production idempotency contract.

---

# 8. M2-09 — OPEN ROOT CAUSE / EXACT MANUAL PATCH

Current `_loadMovementReport()` reads `fromDate`, `toDate`, and uses `window._movementBranchId`, but the voucher query applies only company scope.

Exact manual replacement:

```text
SEARCH inside _loadMovementReport() for the current one-line vouchersRes query.
DELETE that line.
REPLACE it with:
```

```javascript
var vouchersQuery = await supabase.from('stock_vouchers')
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

var vouchersRes = { data: null, error: null };
```

IMPORTANT: the exact replacement above would be wrong if written this way because `vouchersQuery` must remain a query builder and `vouchersRes` must receive its result. The correct final manual replacement is:

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

Also inside `_renderStockMovementReport()` replace the current `if (itemCode) { ... }` state-update block with:

```javascript
window._movementItemCode = itemCode || null;
window._movementItemName = itemName || '';
window._movementBranchId = branchId || null;
window._movementBranchName = branchName || '';

if (itemCode) {
    setTimeout(function() { _loadMovementReport(); }, 300);
}
```

Purpose: prevent stale branch filters from a previous report context.

---

# 9. M2-10 — CROSS-LAYER SECURITY OPEN

Production `delete-item` Version 2 proves authentication, but its deletion path does not prove role/permission authorization.

Main2 currently shows delete action on edit pages.

Do not invent a permission key.
Do not treat UI hiding as a security closure.

Authorized next step:

```text
Fix server-side Authorization in delete-item
→ prove the exact existing permission contract
→ then align Main2 button behavior with that proven contract
```

---

# 10. M2-11 — OPEN SECURITY SURGERY

`core.js` `safeHTML()` is direct `innerHTML`; it is not a sanitizer.

Main2 has raw values from DB/upload data entering HTML and inline JavaScript contexts.

Confirmed surfaces include:

```text
Category Modal names
Category option text/values
Item names/categories/descriptions/images
Current category name in edit dialog
Upload preview barcode/name values
Inline handler arguments using _esc()
```

Main2 local `_esc()` currently does not escape quotes and is used in JS-string contexts where HTML escaping is insufficient.

Manual hardening begins with replacing the local `_esc()` with:

```javascript
function _esc(s) {
    return esc(s == null ? '' : String(s));
}

function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}
```

Then:

```text
HTML text / attribute values → _esc(...)
Inline JavaScript string arguments → _jsString(...)
```

Do not replace every context mechanically; inspect each use so HTML context and JavaScript context are not mixed.

The first exact proven replacements are recorded in Report62.

---

# 11. M2-12 — PREVENTIVE BARCODE INTEGRITY HARDENING

Production currently has zero duplicate non-empty barcodes, but the schema has no UNIQUE constraint on `items.barcode`.

Main2 currently builds:

```javascript
itemMap[it.barcode] = it;
```

This is last-write-wins if duplicates appear later.

Authorized preventive patch is recorded in Report62: detect duplicate barcode keys, mark the corresponding upload rows invalid, and never silently choose one item.

This is preventive hardening, not a current data-corruption finding.

---

# 12. SEMANTIC REVIEW ITEMS — DO NOT PATCH BY ASSUMPTION

```text
Dashboard "صافي الربح" currently calculates:
net = totalSales - totalPurchases

Top Customers currently aggregates by customer_name rather than customer_id.

branchIds fallback behavior has not been proven defective.
```

Classification:

```text
SEMANTIC CONTRACT UNKNOWN
NO PATCH AUTHORIZED YET
```

---

# 13. INVENTORY CORE CONTRACT CURRENTLY RECONFIRMED

```text
PHYSICAL STOCK MOVEMENT
    ↓
post_stock_movement
    ↓
stock_branches
+
inventory_log
```

Reservation capabilities remain separate:

```text
reserve_stock
release_stock_reservation
```

Current Production `post_inventory_adjustment_atomic` is `SECURITY DEFINER` and delegates physical movement to `post_stock_movement`.

Current Production `bulk-stock-adjustment` Version 6 obtains `company_id` via `users.auth_id` and is tenant-safe at the wrapper layer.

---

# 14. KNOWN FAILURE MEMORY — MUST NOT REPEAT

```text
Do not trust historical Report60/Report61 over current Git.
Do not infer current state from historical snapshots.
Do not perform unsafe whole-file replacement of a large logical fragment.
Do not treat source commit as runtime proof.
Do not clear operation identity while retaining executable stale input state.
Do not weaken backend idempotency to compensate for UI lifecycle defects.
Do not close authorization issues by hiding UI controls only.
Do not invent permission keys.
Do not treat current zero barcode duplicates as proof that barcode is globally unique.
```

---

# 15. DOCUMENTATION / EVIDENCE TRAIL

```text
Report59_Main2_Surgical_Forensic_20260905.md
Report60_Main2_Surgical_Completion_20260905.md
Report61_Main2_Deep_Forensic_Continuation_20260905.md
Report62_Main2_Surgical_Recheck_20260905.md
```

Primary governing document:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP.md
```

---

# 16. WHAT THIS SESSION DID / DID NOT CHANGE

```text
MAIN2 SOURCE FILE = NOT MODIFIED BY THIS SESSION
MAIN1 SOURCE FILE = NOT MODIFIED
MAIN3…MAIN11 = NOT MODIFIED
New-main = NOT MODIFIED
core.js = NOT MODIFIED
sw.js = NOT MODIFIED
register-sw.js = NOT MODIFIED
manifest.json = NOT MODIFIED

Production business data = NO PERMANENT CHANGE BY THIS MAIN2 FORENSIC PASS

Report62 = ADDED
CURRENT_STATE = RECONCILED
```

This satisfies the explicit instruction that `main2.md` is to be changed manually by the project owner, not by the assistant.

---

# 17. CURRENT TARGET

```text
PRIMARY TARGET = Current/PWA/main2/main2.md
CURRENT OBJECTIVE = MAIN2 SURGICAL SOURCE CLOSURE
```

Authorized next actions:

```text
1. Owner manually applies M2-07R.
2. Owner manually applies M2-09.
3. Owner manually applies M2-11 security hardening.
4. Owner manually applies M2-12 preventive barcode hardening.
5. Re-read changed regions from Git.
6. Static/syntax verification.
7. Unrelated-diff review.
8. Commit Main2 source mutation.
9. Reconcile CURRENT_STATE again.
10. Then dedicated M2-10 server-side delete authorization closure.
11. Only after Main2 source closure proceed to 11-part assembly and companion-file reconciliation.
```

Do not reopen M2-02 or M2-04 without new contradictory direct evidence.

---

# 18. FINAL SELF-AUDIT

```text
CURRENT GIT = DIRECTLY VERIFIED
CURRENT MAIN2 SOURCE = DIRECTLY VERIFIED
CURRENT PRODUCTION = DIRECTLY VERIFIED
CURRENT INVENTORY CONTRACT = DIRECTLY VERIFIED
CURRENT BULK-STOCK-ADJUSTMENT EDGE = DIRECTLY VERIFIED
CURRENT DELETE-ITEM EDGE = DIRECTLY VERIFIED
CURRENT CORE ESC/SafeHTML CONTRACT = DIRECTLY VERIFIED
HISTORICAL REPORTS = RECONCILED

WHAT I PROVED
- HEAD is e12d6d9, newer than the CURRENT_STATE checkpoint that preceded this report.
- Main2 current blob remains 15f101d3bea93baa5419bdca48e401ad71bbac6c.
- M2-02 and M2-04 are closed in current Git.
- M2-07R remains open and its root cause is proven.
- M2-09 remains open and its root cause is proven.
- M2-10 is a real cross-layer authorization gap.
- M2-11 is a real source-level HTML/inline-JS injection hardening gap.
- M2-12 is a valid preventive guard because barcode is not UNIQUE in schema.
- Current Production barcode duplicate groups = 0.

WHAT I DID NOT PROVE
- Browser/runtime Main2 after manual edits.
- 11-part assembled parent artifact.
- Final PWA production equivalence.
- Business contract for net-profit formula.
- Business contract for customer-name aggregation.
- Full server-side delete authorization closure.

WHAT I CHANGED
- Added Report62.
- Reconciled CURRENT_STATE to current Git and current Production evidence.

WHAT I DID NOT CHANGE
- Main2 source.
- Main1 source.
- Companion PWA files.
- Production business data in this Main2 forensic pass.

CURRENT CLOSURE
MAIN1 SOURCE PATCHES = CLOSED
MAIN2 FORENSIC REVIEW = CURRENT
MAIN2 SOURCE = OPEN
MAIN2 RUNTIME = OPEN
ASSEMBLY = OPEN
INVENTORY CORE = NOT YET 100% CLOSED
```

---

# 19. CONTINUITY LOCK FOR NEXT CTO

Start from this CURRENT_STATE, then independently verify the latest Git HEAD and Production before acting.

Do not start from Report60.
Do not start from Report61.
Do not start from historical Main2 blobs.
Do not restart Main1.
Do not assume that a manual patch was applied until Git re-read proves it.

Immediate human-executable Main2 edits are fully specified in:

```text
doc/Draft/Reprots/Report62_Main2_Surgical_Recheck_20260905.md
```

The Main2 file remains intentionally unmodified by this session.
