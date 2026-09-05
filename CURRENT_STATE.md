# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY CHECKPOINT — 2026-09-05

This file is the current continuity checkpoint. It is a declared state and must be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD BEFORE THIS STATE UPDATE = dd6da64a1615ffbedd3d548c4f9668a2efa3b9f5
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
= FORENSIC REPORT

dd6da64a1615ffbedd3d548c4f9668a2efa3b9f5
docs(cto): add Report61 Main2 deep forensic continuation
= CURRENT FORENSIC RECONCILIATION

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

Latest direct Production verification in the 2026-09-05 session:

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

Additional schema facts verified directly:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
```

Current duplicate-barcode check:

```text
DUPLICATE NON-EMPTY BARCODES = 0
```

No permanent Production business data was introduced by the Main2 forensic session.
Transactional adjustment testing was rolled back.

---

# 4. CURRENT GIT / MAIN2 SOURCE TRUTH

Current Git HEAD before this state update:

```text
dd6da64a1615ffbedd3d548c4f9668a2efa3b9f5
```

Current Main2 source file:

```text
PATH = Current/PWA/main2/main2.md
BLOB = 15f101d3bea93baa5419bdca48e401ad71bbac6c
```

Important reconciliation:

```text
Report60 said M2-02 + M2-04 were still open.
CURRENT GIT proves they were subsequently fixed in ac360fbe.
```

Therefore Report60 is historical evidence, not current source truth.

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
M2-07 = REOPENED AS M2-07R — replay after successful upload remains possible
M2-08 = CLOSED IN CURRENT SOURCE
M2-09 = OPEN — movement report date/branch filters are not wired into voucher query
M2-10 = OPEN — item deletion authorization is not enforced server-side
```

Current Main2 is therefore:

```text
FORENSIC REVIEW = UPDATED / CURRENT
SOURCE CLOSURE = OPEN
RUNTIME CLOSURE = OPEN
ASSEMBLY CLOSURE = OPEN
```

---

# 7. M2-07R — OPEN ROOT CAUSE

Main2 `_executeUpload()` clears:

```javascript
_uploadOperationId = null;
_uploadOperationFingerprint = null;
```

after success but leaves `_uploadFileData` populated.

Consequently another click can create a new voucherCode for the same in-memory file and submit the same adjustment again.

Production `post_inventory_adjustment_atomic` uses voucherCode inside the physical-movement idempotency key:

```text
InventoryAdjustment:<company_id>:<voucher_code>:<item_id>
```

A different voucherCode is a different idempotency identity.

The required Main2 surgical replacement is recorded verbatim in:

```text
doc/Draft/Reprots/Report61_Main2_Deep_Forensic_Continuation_20260905.md
```

Required replacement:

```javascript
_uploadFileData = [];
_uploadOperationId = null;
_uploadOperationFingerprint = null;
var uploadFileInput = byId('upload-file-input');
if (uploadFileInput) uploadFileInput.value = '';
```

Do not weaken or bypass the Production idempotency contract.

---

# 8. M2-09 — OPEN ROOT CAUSE

`_loadMovementReport()` reads `fromDate`, `toDate`, and stores `_movementBranchId`, but the `stock_vouchers` query currently applies only `company_id` and `order`.

The required surgical replacement that wires date and branch filters is recorded in Report61.

Do not broaden this into an unrelated reporting redesign.

---

# 9. M2-10 — CROSS-LAYER SECURITY OPEN

Main2 exposes item deletion from the edit page without an independent permission gate.

Current Production `delete-item` authenticates the caller but uses service-role deletion without proving the caller is authorized to delete an item.

This is:

```text
AUTHENTICATION = PRESENT
AUTHORIZATION = NOT PROVEN
```

Main2 can mitigate the visible button using the existing permission contract, but the security closure cannot be declared until the server-side `delete-item` authorization contract is fixed and verified.

Do not close this by UI hiding alone.

---

# 10. SEMANTIC REVIEW ITEMS — DO NOT PATCH BY ASSUMPTION

These findings were proven at source level but their intended business contract is not yet proven:

```text
Dashboard "صافي الربح" currently calculates:
net = totalSales - totalPurchases

Top Customers currently aggregates by customer_name rather than customer_id.
```

Classification:

```text
SEMANTIC CONTRACT UNKNOWN
NO PATCH AUTHORIZED YET
```

Resolve the historical/current accounting and customer-identity contract first.

---

# 11. ADDITIONAL SECURITY OBSERVATION

Main2 contains HTML construction paths that insert database-controlled category/item values without consistent escaping, including Category Modal paths.

Classification:

```text
POTENTIAL STORED/DOM XSS
SEPARATE SECURITY CLOSURE UNIT
NO PATCH IN THIS STATE UPDATE
```

Do not mix this with the operational Main2 closure unit until the exact DOM contract and safe event-binding strategy are mapped.

---

# 12. INVENTORY CORE CONTRACT CURRENTLY RECONFIRMED

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

No new Physical Stock Writer was introduced by this Main2 review.

The current Production adjustment RPC delegates Physical Movement to `post_stock_movement`.

---

# 13. KNOWN FAILURE MEMORY — MUST NOT REPEAT

```text
Do not trust Report60 over CURRENT GIT.
Do not infer current state from historical snapshots.
Do not perform unsafe full-file replacement of a large logical fragment.
Do not treat source commit as runtime proof.
Do not treat a generated/temporary executor as authoritative production source.
Do not clear a client operation identity while retaining executable stale input state.
Do not weaken backend idempotency to compensate for UI lifecycle errors.
Do not close a permission issue by hiding a button only.
```

---

# 14. DOCUMENTATION / EVIDENCE TRAIL

Current key reports:

```text
Report59_Main2_Surgical_Forensic_20260905.md
Report60_Main2_Surgical_Completion_20260905.md
Report61_Main2_Deep_Forensic_Continuation_20260905.md
```

Current governing document:

```text
MASTER - RAWAEA ERP.md
```

Current state is reconciled against the latest available Main2 commits through Report61.

---

# 15. WHAT THIS SESSION DID / DID NOT CHANGE

```text
MAIN2 SOURCE FILE = NOT MODIFIED BY THIS SESSION
MAIN1 SOURCE FILE = NOT MODIFIED
MAIN3…MAIN11 = NOT MODIFIED
New-main = NOT MODIFIED
core.js = NOT MODIFIED
sw.js = NOT MODIFIED
register-sw.js = NOT MODIFIED
manifest.json = NOT MODIFIED

Production business data = NOT permanently modified
Production schema/business functions = not modified by Main2 session

Documentation:
Report61 = ADDED
CURRENT_STATE = RECONCILED
```

This satisfies the user's explicit instruction that the Main2 file itself is to be changed manually by the owner, not by the assistant.

---

# 16. CURRENT TARGET

```text
PRIMARY TARGET = Current/PWA/main2/main2.md
CURRENT OBJECTIVE = MAIN2 SURGICAL SOURCE CLOSURE
```

Authorized next actions:

```text
1. Apply M2-07R exact surgical replacement in Main2.
2. Apply M2-09 exact voucher-query replacement in Main2.
3. Re-read changed regions from Git.
4. Perform syntax/static review and unrelated-diff review.
5. Commit Main2 source mutation.
6. Reconcile CURRENT_STATE again.
7. Then address M2-10 as a dedicated cross-layer security closure.
8. Only after Main2 source closure proceed to 11-part assembly and companion-file reconciliation.
```

Do not reopen M2-02 or M2-04 unless new direct evidence contradicts their current Git state.

---

# 17. FINAL SELF-AUDIT

```text
CURRENT GIT = DIRECTLY VERIFIED
CURRENT MAIN2 SOURCE = DIRECTLY VERIFIED
CURRENT PRODUCTION = DIRECTLY VERIFIED
CURRENT INVENTORY CONTRACT = DIRECTLY VERIFIED
CURRENT EDGE CONTRACTS RELEVANT TO MAIN2 = DIRECTLY VERIFIED
HISTORICAL REPORTS = RECONCILED

WHAT I PROVED
- Current main2 contains the post-Report60 fixes for M2-02/M2-04.
- Production adjustment idempotency is keyed by voucherCode and changing it permits a new movement identity.
- M2-07R replay risk is real at the client lifecycle level.
- M2-09 query-filter omission is real at source level.
- delete-item authorization is not proven server-side.

WHAT I DID NOT PROVE
- Main2 assembled parent artifact.
- Browser/runtime success of the 11-part application.
- Full production PWA equivalence.
- Business-contract verdict for net profit formula.
- Business-contract verdict for customer-name aggregation.
- Full server-side delete authorization closure.

WHAT I CHANGED
- Added Report61.
- Reconciled CURRENT_STATE.

WHAT I DID NOT CHANGE
- Main2 source.
- Production business state.
- Companion files.

CURRENT CLOSURE
MAIN1 SOURCE PATCHES = CLOSED
MAIN2 FORENSIC REVIEW = CURRENT
MAIN2 SOURCE = OPEN
MAIN2 RUNTIME = OPEN
ASSEMBLY = OPEN
INVENTORY CORE = NOT 100% CLOSED
```

---

# 18. CONTINUITY LOCK FOR NEXT CTO

Start from this CURRENT_STATE, then independently verify the latest Git HEAD and Production before acting.

Do not start from Report60.
Do not start from Report59.
Do not start from historical Main2 blob `b1096fd...`.
Do not restart Main1.

The immediate human-executable Main2 edits are fully specified in:

```text
doc/Draft/Reprots/Report61_Main2_Deep_Forensic_Continuation_20260905.md
```

The Main2 file remains intentionally unmodified by this session.
