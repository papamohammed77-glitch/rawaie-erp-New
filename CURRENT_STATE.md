# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY UPDATE — 2026-09-05

This file is the continuity checkpoint. It is a declared state and must always be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD BEFORE THIS STATE UPDATE = dde004b94b639dd715655f7be5607320a14e6f4c
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

### Latest verified events

```text
ed4e91ec595234ba7ede3f08558c660c1b100d3e
Update main1.md
= ACTUAL MAIN1 SOURCE MUTATION
= Patch 1–4 applied

8399ff50664b76c776f01a9e941cc2bdfd247b59
Update تحليل مساعد خارجي -main1
= DOCUMENTATION UPDATE ONLY

4baace12f19ab70a063d985a06488ca53cf2e799
[CTO] Reconcile CURRENT_STATE with Main1 source mutation ed4e91
= STATE RECONCILIATION

d26695ccca675fb85936bda1707398326ce882ec
[CTO] Add Report54 Main1 current-state forensic reconciliation
= FORENSIC REPORT

e829b747d811e40b402f0e6ba00c366818939a6f
[CTO] Add unified continuity and Main1 execution command
= GOVERNANCE ARTIFACT

a561147f57abe5738990e715acb525e9abc236c6
[CTO] Add MASTER FORENSIC CONTINUITY GOVERNANCE v2
= GOVERNANCE ARTIFACT

ef338627204ed6ba689887c0025b034fd361c750
[CTO] Add Report55 forensic continuity and Main1 closure assessment
= FORENSIC REPORT

d845ad63485fb9093f18bfeb86479846bd8f6eb9
[CTO] Add Report56 forensic continuity review and Main1 closure verdict
= CURRENT FORENSIC REPORT
= MAIN1 SOURCE CLOSED / FULL CLOSURE OPEN

e2dc8da6982a50328d700bc48421282ed782c7cc
[CTO] Add Report57 forensic Main1 closure continuation
= FORENSIC REPORT

e925dc516b7a67ae237d0fe77251cf5fc8d41c9e
[CTO] Add Report57 and reconcile CURRENT_STATE after Main1 forensic continuation
= STATE RECONCILIATION

c12967d903c6fccf1f437ec460c276c2967ed919
[CTO] Add Report58 — Main1 forensic closure gate after latest-state recovery
= FORENSIC REPORT

a6556235c5768d9514ee3e910ae795391e3ab868
fix(main2): surgical tenant-scoping and dashboard integrity
= ACTUAL MAIN2 SOURCE MUTATION

 dde004b94b639dd715655f7be5607320a14e6f4c
[CTO] Add Report59 Main2 surgical forensic continuation
= FORENSIC REPORT
```

---

# 1. LAST VERIFIED STATE — 2026-09-05 MAIN2 FORENSIC CONTINUATION

This round explicitly continued from existing Main2 work. It did not restart Main1 patches and did not repeat already-applied Main2 surgery.

The following distinctions were re-verified directly:

```text
ed4e91 = real Main1 source mutation

a655623 = real Main2 source mutation
message = fix(main2): surgical tenant-scoping and dashboard integrity

Current/PWA/main2/main2.md blob verified from the current commit lineage = b1096fdadd4734881d2c16c341dea769fc306fc5

Report59 = current Main2 forensic continuation report
Report59 commit = dde004b94b639dd715655f7be5607320a14e6f4c

Current Main2 source surgery in this session = NOT committed
Only Report59 documentation was added before this CURRENT_STATE reconciliation.
```

Latest direct Production query in this continuation:

```text
UTC = 2026-09-05 00:21:30.867647
companies = 1
app_settings = 1
orders = 0
purchase_orders = 0
```

The current Production `post_inventory_adjustment_atomic` was read directly and is `SECURITY DEFINER`; it validates user/company context, delegates Physical Stock movement to `post_stock_movement`, and returns:

```text
success
 duplicate
 movement_count
 voucher_code
 company_id
```

Historical multi-company snapshots must not be reused as current Production facts without re-querying Production.

---

# 2. GOVERNING ENGINEERING RULES

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > DEPLOYMENTS > DATABASE CONTRACTS > HISTORY > REPORTS > MEMORY > ASSUMPTIONS

UNKNOWN != BUG
UNKNOWN != REMOVE

READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY

ONE CLOSURE UNIT AT A TIME

NO WHOLE-FILE REWRITE FOR A NARROW DEFECT

GIT != DEPLOYMENT PROOF
SOURCE != RUNTIME PROOF

NO CLOSURE CLAIM WITHOUT EVIDENCE
```

Primary governance source:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP.md
```

---

# 3. CURRENT REPAIR TARGET

```text
ACTIVE SOURCE REPAIR PACK = Current/PWA/main2/
CURRENT FORENSIC CLOSURE UNIT = Main2 surgical source closure
CURRENT SUBTASK = forensic review of main2.md
NEXT SAFE ACTION = apply line-level replacements recorded in Report59
MAIN2 SOURCE FILES = PRESENT
MAIN2 HISTORICAL SURGERY = PRESENT
MAIN2 FRESH SURGICAL CLOSURE = OPEN
MAIN2 PRODUCTION/RUNTIME CLOSURE = OPEN
```

The fragments are logical parts of one parent application contract, not eleven independent products.

Current strategy is to preserve the 11 logical parts, perform surgical corrections part-by-part, then assemble the parent artifact before final publish/runtime testing.

---

# 4. MAIN1 VERIFIED SOURCE STATE

```text
PATH = Current/PWA/main2/main1.md
SOURCE PATCH COMMIT = ed4e91ec595234ba7ede3f08558c660c1b100d3e
```

Direct source verification confirms:

```text
PATCH 1 = RW_STATE.app.company.id exists
PATCH 2 = public.users lookup by auth_id supplies company_id + status
PATCH 2 = generic missing-permissions fallback is []
PATCH 3 = app_settings is company-scoped and ordered before limit(1)
PATCH 4 = items/customers/branches/suppliers bootstrap reads use company_id
SESSION RESTORE = present in current source
```

These source repairs are closed and must not be repeated without new contradictory direct evidence.

---

# 5. SYSTEM SETTINGS / BRANDING CONTRACT

The source contract is:

```text
Authenticated User
→ users.company_id
→ app_settings(company_id)
→ company branding/configuration
```

Static strings/defaults in HTML/state are presentation fallbacks unless direct evidence proves otherwise.

Latest Production verification:

```text
companies = 1
app_settings = 1
```

---

# 6. MAIN1 CLOSURE STATUS — CURRENT

```text
HISTORICAL RECONCILIATION = CLOSED for addressed Patch 1–4
SOURCE PATCH 1–4 = CLOSED
SOURCE SESSION RESTORE = VERIFIED
SYSTEM SETTINGS AUTHORITY = VERIFIED AS app_settings
PRODUCTION CONFIGURATION = DIRECTLY VERIFIED
EXACT ASSEMBLY LINEAGE = NOT PROVEN
DEPLOYED ARTIFACT EQUIVALENCE = NOT PROVEN
INDEPENDENT CURRENT MAIN1 RUNTIME = NOT PROVEN
FULL MAIN1 PRODUCT CLOSURE = OPEN
```

Therefore:

```text
MAIN1.md = SOURCE-CLOSED, but NOT Closed 100% as an integrated production/runtime product
```

The source itself does not require new patching.

---

# 7. NEW-MAIN / RUNTIME EVIDENCE

Current direct investigation established:

```text
Current/PWA/New-main = separate current artifact
New-main architecture = not proven to be the current assembly output of main2/main1.md
```

Known CI evidence remains scoped to New-main:

```text
RUN = 33927339279
JOB = 101198600466
RESULT = FAILURE
FAILED STEP = Immutable audited target
CHROMIUM = SKIPPED
```

The failure is not valid proof of Main1 browser failure.

---

# 8. HISTORICAL FAILURES / LESSONS PRESERVED

```text
stale CURRENT_STATE ≠ current truth
commit ≠ deployment proof
source ≠ runtime proof
New-main browser failure ≠ Main1 browser failure
historical Main1 analysis ≠ current Main1 source
static fallback ≠ authoritative configuration
```

---

# 9. MAIN2 CURRENT FACTS

```text
Current/PWA/main2/main1.md = present
Current/PWA/main2/main2.md = present
Current/PWA/main2/main3.md = present
Current/PWA/main2/main4.md = present
Current/PWA/main2/main5.md = present
Current/PWA/main2/main6.md = present
Current/PWA/main2/main7.md = present
Current/PWA/main2/main8.md = present
Current/PWA/main2/main9.md = present
Current/PWA/main2/main10.md = present
Current/PWA/main2/main11.md = present
```

Historical Main2 surgery commits include:

```text
cc949417c635295f71218df036aeca2fd5846cda
fix(cto): start cumulative syntax gate at closed Main1+Main2 boundary

26ad9bc1880749dd0d3f6d43a99c0221630b5a68
fix(cto): preserve main2 compatibility IIFE boundary during P163 surgery

a6556235c5768d9514ee3e910ae795391e3ab868
fix(main2): surgical tenant-scoping and dashboard integrity
```

Current interpretation:

```text
MAIN2 SOURCE FILES = PRESENT
MAIN2 HISTORICAL SURGERY = EXISTS
MAIN2 FORENSIC REVIEW = COMPLETED IN REPORT59
MAIN2 SURGICAL SOURCE CLOSURE = OPEN
MAIN2 PRODUCTION/RUNTIME CLOSURE = OPEN
```

Do not restart Main2 from zero.

---

# 10. MAIN2 FORENSIC FINDINGS — REPORT59

The following are confirmed by direct source inspection and/or Production contract inspection.

```text
M2-01 = Dashboard net-profit order query missing company_id predicate
M2-02 = Dashboard Top Items query references undefined orderIds
M2-03 = Category replacement selector missing company_id predicate
M2-04 = Upload preview item lookup uses barcode without company scope
M2-05 = Upload preview validates rows but execution payload includes unvalidated rows
M2-06 = Upload success handler expects json.results[] while Production returns movement_count
M2-07 = Adjustment voucherCode is random, weakening retry idempotency against the current backend key contract
M2-08 = Stock movement report voucher query missing company_id predicate
```

Ready-to-swap replacements are preserved verbatim in:

```text
doc/Draft/Reprots/Report59_Main2_Surgical_Forensic_20260905.md
```

No replacement has been silently generalized or invented.

---

# 11. WHY MAIN2 SOURCE WAS NOT REWRITTEN IN THIS PASS

The governing rule forbids a whole-file rewrite for a narrow defect.

The available Git connector write operation replaces a file as a complete payload; it does not expose an atomic line-range patch primitive. The directly fetched Main2 source exceeds the safe manual reconstruction surface of the connector responses, which are truncated for large files.

Therefore:

```text
Reconstructing main2.md from truncated tool output = UNSAFE
Whole-file replacement for 8 narrow defects = GOVERNANCE VIOLATION

Chosen action = preserve source unchanged + record exact surgical replacements
```

This is a tooling/patch-surface constraint, not a declaration that the defects are harmless or acceptable.

---

# 12. PRODUCTION DATA INTEGRITY

Current Production at the final verification point of this session:

```text
companies = 1
app_settings = 1
orders = 0
purchase_orders = 0
```

No destructive data repair was executed from Main2 in this session.

Historical contamination observations from earlier multi-company snapshots must not be promoted into current-state metrics without a fresh Production query.

---

# 13. CURRENT REPORTS

```text
Report56 = d845ad63485fb9093f18bfeb86479846bd8f6eb9
Report57 = e2dc8da6982a50328d700bc48421282ed782c7cc
Report58 = c12967d903c6fccf1f437ec460c276c2967ed919
Report59 = dde004b94b639dd715655f7be5607320a14e6f4c
```

All previous reports remain preserved. No report was deleted.

---

# 14. NEXT AUTHORIZED ACTION

Do NOT re-patch Main1 Patch 1–4.

Do NOT repeat Main2 fixes already contained in `a6556235...`.

Do NOT declare Main2 source closed yet.

The next authorized source action is:

```text
apply M2-01 … M2-08 as controlled line-level edits to Current/PWA/main2/main2.md
→ syntax/static analysis
→ compare resulting diff against Report59 exactly
→ commit Main2 source patch
→ re-query Production contract if backend contract changes are introduced
→ assemble 11 parts
→ reconcile core.js / sw.js / register-sw.js / manifest.json
→ deployment
→ runtime/browser verification
→ Production verification
→ update CURRENT_STATE
```

M2-07 must be solved with an explicit stable operation identity contract; do not manufacture an idempotency token in the UI without backend support.

---

# 15. FINAL SELF-AUDIT — 2026-09-05 MAIN2 PASS

```text
Business Understanding = CONFIRMED for Main2 dashboard/items/upload/report surfaces
Architecture Understanding = CONFIRMED for tenant-scoping and inventory-adjustment contract boundary
Database / Production = DIRECTLY VERIFIED at 2026-09-05 00:21:30.867647 UTC
Historical Understanding = RECONCILED sufficiently to avoid repeating prior Main2 surgery
Current Git Understanding = DIRECTLY VERIFIED
Current Main2 Source = DIRECTLY VERIFIED
Deployment Understanding = OPEN
Runtime Understanding = OPEN
Source Patch Execution = OPEN

CONFIRMED FACTS
- a655623 is an actual Main2 source mutation
- current Main2 blob = b1096fdadd4734881d2c16c341dea769fc306fc5
- Report59 contains the confirmed remaining source defects and exact ready-to-swap replacements
- Production adjustment RPC returns movement_count and not results[]
- Production currently has no orders or purchase orders for a realistic positive fixture
- no Main2 source write was executed in this pass

UNKNOWNS
- final line-level application of M2-01…M2-08
- final assembled 11-part parent artifact
- final browser/runtime deployment mapping
- stable adjustment operation-identity contract after source patch

CONFLICTS RESOLVED
- stale CURRENT_STATE head vs actual Main2 commit a655623
- historical Main2 hold vs current explicit owner authorization
- current Production single-company reality vs historical multi-company contamination snapshots

WHAT I PROVED
- Main2 previous surgical commit exists
- Main2 current source contains 8 remaining confirmed findings listed above
- current Production adjustment engine contract differs from the frontend expectation
- a safe full-file rewrite is not justified for narrow defects under the governing rules

WHAT I DID NOT PROVE
- Main2 runtime/browser success
- final assembly equivalence
- production deployment of a newly patched Main2
- 100% inventory/source closure

WHAT I CHANGED
- Report59 forensic report
- CURRENT_STATE reconciliation

WHAT I DID NOT CHANGE
- Current/PWA/main2/main2.md
- Current/PWA/main2/main1.md
- main3.md through main11.md
- New-main
- core.js
- sw.js
- register-sw.js
- manifest.json

FINAL CLOSURE STATUS
MAIN1 = SOURCE-CLOSED / FULL-PRODUCT-CLOSURE-OPEN
MAIN2 = FORENSIC-REVIEW-COMPLETE / SURGICAL-SOURCE-CLOSURE-OPEN
INVENTORY CORE = NOT 100% CLOSED
```

---

# 16. CONTINUITY LOCK

The next CTO or assistant must begin from `dde004b94b639dd715655f7be5607320a14e6f4c` and preserve the following facts:

```text
MAIN1 SOURCE = CLOSED FOR PATCHES 1–4
MAIN1 FULL PRODUCT = OPEN
MAIN2 PRIOR SURGERY COMMIT = a6556235c5768d9514ee3e910ae795391e3ab868
MAIN2 CURRENT BLOB = b1096fdadd4734881d2c16c341dea769fc306fc5
MAIN2 REPORT59 = dde004b94b639dd715655f7be5607320a14e6f4c
LATEST PRODUCTION VERIFICATION = 2026-09-05 00:21:30.867647 UTC
PRODUCTION COMPANIES = 1
PRODUCTION APP_SETTINGS = 1
PRODUCTION ORDERS = 0
PRODUCTION PURCHASE_ORDERS = 0
MAIN2 SOURCE PATCH = OPEN
MAIN2 RUNTIME = NOT VERIFIED
```

The next source operation must apply only the explicit Report59 replacements and must not recreate Main1 or reopen already-closed Main2 surgery without contradictory direct evidence.
