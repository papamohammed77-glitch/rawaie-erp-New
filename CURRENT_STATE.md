# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD AFTER THIS STATE UPDATE = THIS COMMIT
PREVIOUS VERIFIED HEAD = d9509d06a14ee8dde9621f79c72c212022179ef4
MAIN2 SOURCE MUTATION COMMIT = 8e5fe0d7427f8e16a8094da9e86a26e486c9cea3
REPORT62 COMMIT = cd1fcb9c126d43b238360cf0b795c1cf5e1c7b61
REPORT63 COMMIT = c8b2f094dd44bcadf2ff2571acf73ec96ca091f0
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
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
d9509d06a14ee8dde9621f79c72c212022179ef4
Latest Git history snapshot before this reconciliation

8e5fe0d7427f8e16a8094da9e86a26e486c9cea3
Refactor functions and enhance voucher query logic
= ACTUAL MAIN2 SOURCE MUTATION
= M2-07R source cleanup
= M2-09 voucher query/date/branch wiring
= M2-12 duplicate-barcode handling
= M2-11 _esc/_jsString helper addition

c8b2f094dd44bcadf2ff2571acf73ec96ca091f0
Report63 Main2 inline-JS surgical re-check
= DOCUMENTATION ONLY
= main2.md NOT modified by this report

CURRENT_STATE FINAL UPDATE = THIS COMMIT
```

Historical reports are preserved. No prior report was deleted.

## PRODUCTION TRUTH — DIRECT

Verified directly at `2026-09-05 03:34:01.191895+00`:

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

Schema facts re-confirmed from Production evidence:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
```

## MAIN2 SOURCE TRUTH

```text
PATH = Current/PWA/main2/main2.md
CURRENT SOURCE BLOB = f2ecf6f60aff0831b543a96b4b4f9c885ffb56f8
MAIN2 SOURCE MODIFIED BY THIS REPORT = NO
MAIN2 SOURCE WAS MODIFIED BY COMMIT 8e5fe0d... = YES
```

The previous `CURRENT_STATE.md` blob `15f101d3...` was stale relative to the current Main2 source. The actual current source was re-read directly from Git and reconciled against commit `8e5fe0d...`.

## MAIN2 MATRIX

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
M2-11 = OPEN / REMAINING RAW HTML + INLINE-JS HARDENING
M2-12 = CLOSED IN CURRENT SOURCE
```

## M2-11 — EXACT MANUAL PATCH NOW REQUIRED

Current source already contains:

```javascript
function _esc(s) {
    return esc(s == null ? '' : String(s));
}

function _jsString(s) {
    return JSON.stringify(s == null ? '' : String(s));
}
```

However `_jsAttr` is not defined anywhere in the repository according to direct GitHub code search.

Add immediately after `_jsString`:

```javascript
function _jsAttr(s) {
    return _esc(_jsString(s));
}
```

Then apply the exact replacements in `Report63_Main2_Surgical_InlineJS_Recheck_20260905.md`:

```text
1. _applyFilters() branch-stock clickable cell
2. _renderBranchStockMatrix() first rowHtml occurrence
3. _renderBranchStockMatrixFiltered() first rowHtml occurrence
```

For the no-branch movement call, the third argument must remain literal JavaScript `null`, not `_jsAttr(null)`.

## M2-07R / M2-09 / M2-12 CURRENT SOURCE STATUS

Commit `8e5fe0d...` already contains the previously authorized source changes:

```text
M2-07R = _uploadFileData cleared + file input reset after success
M2-09 = stock_vouchers query now uses date + branch filters
M2-12 = duplicate barcode rows are invalid instead of silently last-write-wins
```

These must still undergo post-manual-edit static/syntax verification before final Main2 closure.

## M2-10 — OPEN

Production `delete-item` authorization remains a separate server-side closure. Do not claim closure by UI hiding alone and do not invent a permission key.

## M2-11 — OPEN

The remaining scope is not the helper definition alone. Raw database/file values still enter HTML and inline-JS contexts in Main2. The exact current review in Report63 identifies the requested movement-report row builders as mandatory surgical replacements and treats `_jsAttr` as an explicit HTML-attribute-safe JavaScript literal bridge.

## M2-12 — CLOSED IN CURRENT SOURCE

The current upload-preview mapping now detects duplicate barcode keys and marks them invalid. Production currently has zero duplicate non-empty barcodes, so this is preventive hardening rather than data cleanup.

## SEMANTIC UNKNOWN — DO NOT PATCH

```text
Dashboard net profit = totalSales - totalPurchases
Top Customers = grouped by customer_name
branchIds fallback
```

Business contract is unproven; do not change these in this closure.

## INVENTORY CONTRACT

```text
PHYSICAL STOCK MOVEMENT
    ↓
post_stock_movement
    ↓
stock_branches + inventory_log
```

`reserve_stock` and `release_stock_reservation` remain reservation capabilities.

## EVIDENCE / REPORTS

```text
Report59_Main2_Surgical_Forensic_20260905.md
Report60_Main2_Surgical_Completion_20260905.md
Report61_Main2_Deep_Forensic_Continuation_20260905.md
Report62_Main2_Surgical_Recheck_20260905.md
Report63_Main2_Surgical_InlineJS_Recheck_20260905.md
```

## WHAT THIS SESSION CHANGED

```text
Report63 = ADDED
CURRENT_STATE = RECONCILED
main2.md = NOT MODIFIED BY THIS REPORT
New-main = NOT MODIFIED
main1.md = NOT MODIFIED BY THIS REPORT
main3…main11 = NOT MODIFIED BY THIS REPORT
core.js = NOT MODIFIED BY THIS REPORT
sw.js = NOT MODIFIED BY THIS REPORT
register-sw.js = NOT MODIFIED BY THIS REPORT
manifest.json = NOT MODIFIED BY THIS REPORT
Production business data = NOT MODIFIED BY THIS REPORT
```

## CURRENT SOURCE EXECUTION STATUS

```text
M2-07R source fix = present
M2-09 source fix = present
M2-12 source fix = present
M2-11 helper = partially present
M2-11 _jsAttr + exact movement-row replacements = MANUAL / OPEN
M2-10 = OPEN
```

## NEXT AUTHORIZED ACTION

```text
1. Owner adds _jsAttr immediately after _jsString in Main2.
2. Owner replaces the exact _applyFilters branch-stock row line from Report63.
3. Owner replaces the exact _renderBranchStockMatrix rowHtml line from Report63.
4. Owner replaces the exact _renderBranchStockMatrixFiltered rowHtml line from Report63.
5. Re-read main2.md from current Git.
6. Run static/syntax review and unrelated-diff review.
7. Commit the manual Main2 source mutation.
8. Reconcile CURRENT_STATE again.
9. Continue dedicated M2-10 server-side authorization closure.
10. Only after Main2 closure proceed to 11-part assembly and companion-file reconciliation.
```

Do not reopen M2-02 or M2-04 without new contradictory direct evidence.

## FINAL SELF-AUDIT

```text
CURRENT GIT = DIRECTLY VERIFIED
CURRENT PRODUCTION = DIRECTLY VERIFIED AT REPORT63 SNAPSHOT TIME
CURRENT MAIN2 = DIRECTLY RE-READ
LATEST SOURCE MUTATION = DIRECTLY VERIFIED AT 8e5fe0d...
HISTORICAL REPORTS = PRESERVED AND RECONCILED

PROVED:
- Current main moved beyond the previous CURRENT_STATE checkpoint.
- Main2 has a real source mutation commit after Report62.
- M2-07R, M2-09 and M2-12 source changes are present.
- _jsAttr is absent from the repository and therefore must be defined before use.
- The requested movement-row corrections are specified exactly in Report63.
- Production snapshot remains stable and has zero duplicate non-empty barcodes.

NOT PROVED:
- Browser/runtime after the owner’s manual Main2 edits.
- Complete M2-11 closure across every raw HTML/inline-JS sink.
- M2-10 server-side authorization closure.
- Final assembled parent artifact.
- Final PWA production equivalence.

CLOSURE = NOT CLAIMED
```

## CONTINUITY LOCK

Start from this state. The immediate manual Main2 instructions are fully specified in `Report63_Main2_Surgical_InlineJS_Recheck_20260905.md`. The current source commit `8e5fe0d...` must not be confused with the pending manual `_jsAttr` movement-row corrections, which are not yet committed.
