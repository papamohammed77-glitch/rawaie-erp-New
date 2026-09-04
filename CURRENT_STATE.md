# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY UPDATE — 2026-09-05

This file is the continuity checkpoint. It is a declared state and must always be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD BEFORE THIS STATE UPDATE = e829b747d811e40b402f0e6ba00c366818939a6f
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
```

### Reconciliation result

The previous 2026-09-04 state became stale after `ed4e91...`. Direct Git verification proves the four Main1 repair windows were actually applied in `Current/PWA/main2/main1.md`.

The latest New-main browser gate examined in this round failed for a different reason: `page.goto: Download is starting` while the workflow targeted `Current/PWA/New-main`. This does not invalidate Main1 source Patch 1–4 and does not prove Main1 browser failure.

---

# 1. LAST VERIFIED STATE

The project did NOT stop at Report51.

Continuity chain verified in this round:

```text
2bffd02...  Report52 forensic Main1 closure design
7e07088...  CURRENT_STATE sync with Report53 checkpoint
ed4e91e...  ACTUAL Main1 source repair — Patch 1–4
76a5fdd...  External Main1 analysis created
8399ff5...  External Main1 analysis updated
4baace1...  State reconciliation
 d26695c... Report54
 e829b74... Unified governance command
```

Older checkpoint claims that Main1 Patch 1–4 were pending are historical and superseded by `ed4e91...`.

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

Unified successor command now also exists at:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md
```

---

# 3. CURRENT REPAIR TARGET

```text
ACTIVE SOURCE REPAIR PACK = Current/PWA/main2/
CURRENT VERIFIED CLOSURE UNIT = Current/PWA/main2/main1.md
NEXT TARGET = cumulative Main1→Main2 source/integration verification, subject to reassessment
```

The fragments are logical parts of one parent application contract, not eleven independent products.

---

# 4. MAIN1 VERIFIED SOURCE STATE

```text
PATH = Current/PWA/main2/main1.md
SOURCE PATCH COMMIT = ed4e91ec595234ba7ede3f08558c660c1b100d3e
```

Direct current-source inspection confirms:

```text
PATCH 1 = RW_STATE.app.company.id exists
PATCH 2 = public.users lookup by auth_id supplies company_id + status
PATCH 2 = generic missing-permissions fallback is []
PATCH 3 = app_settings is company-scoped and ordered before limit(1)
PATCH 4 = items/customers/branches/suppliers bootstrap reads use company_id
```

The current file still contains:

```text
login title = 64px
login logo = 120×120
company-name = 34px
```

These visual values were intentionally preserved because no direct current evidence proves them defective.

The file remains a logical open-script fragment whose assembly continues through later Main2 fragments.

---

# 5. HISTORICAL REPORT STATUS — RECONCILED

Historical Report52/53 status:

```text
FORENSIC ANALYSIS = CLOSED
ROOT CAUSE = PROVEN
PATCH DESIGN = PROVEN
SOURCE MUTATION = NO   [historical at that time]
PRODUCTION DEPLOYMENT = NO
RUNTIME = NO
```

Current reconciled status:

```text
FORENSIC DESIGN = CLOSED
SOURCE PATCH 1–4 = APPLIED
DIRECT SOURCE VERIFICATION = CONFIRMED
PRODUCTION PRODUCT DEPLOYMENT = NOT PROVEN
MAIN1 INDEPENDENT BROWSER RUNTIME = NOT PROVEN
MAIN1→MAIN2 RUNTIME = NOT PROVEN
```

Do not reopen historical patch work without new contradictory evidence.

---

# 6. MAIN1 DEFECTS — CURRENT RESULT

```text
Unsafe wildcard default                 = FIXED IN SOURCE
Missing authoritative company bootstrap = FIXED IN SOURCE
Global app_settings lookup              = FIXED IN SOURCE
Unscoped bootstrap reads                = FIXED IN SOURCE
```

Owner wildcard semantics remain protected. `permissions=[]` is only the generic fallback; an actual Owner with `permissions=['*']` remains valid under the established Owner contract.

---

# 7. VISUAL / BRANDING FINDINGS INTENTIONALLY PRESERVED

Do not change these only because the external report mentions a different Parent/New-main recommendation:

```text
64px login title
120×120 login logo
34px company-name
historical Owner semantics
```

The external report is useful for architecture and design direction, but it is not evidence of Current Main2/Main1 defect by itself.

---

# 8. SOURCE-LINEAGE DISTINCTION

```text
Current/PWA/main/main1.md = different current lineage/reference
Current/PWA/main2/main1.md = active source-repair target
Current/PWA/New-main = integrated parent artifact
Original/PWA/main/main1.md = historical reference
```

No lineage may be overwritten by another merely because their content looks similar.

---

# 9. CORE / PARENT VISION

The desired Parent direction is:

```text
Historical UI identity
+
Current parent application shell
+
Shared Core where ownership is proven
+
Production-compatible backend contracts
+
Tenant-safe data flow
+
Preserved historical functionality
+
No duplicated business engines
+
Runtime-verifiable assembly
```

Main1 is not treated as a login-only artifact. It is the first logical segment of the current Main2 application and must be repaired/assembled by contract, not by byte-copying.

---

# 10. PRODUCTION / DATABASE CONTINUITY

Production evidence used in this stream confirms, among other relevant constraints:

```text
PostgreSQL 17.6
users self-row is addressable by auth_id = auth.uid()
app_private.current_user_company_id() exists
items.item_code is globally UNIQUE
stock_branches is UNIQUE(branch_id, item_id)
stock_vouchers is UNIQUE(company_id, voucher_code)
receiving.operation_id is UNIQUE
```

Therefore Item identity must not be incorrectly “repaired” as company-local merely from a cross-company comparison of metadata.

---

# 11. INVENTORY CONTRACT — PROTECTED

```text
PHYSICAL STOCK MOVEMENT
→ post_stock_movement
→ stock_branches + inventory_log

reserve_stock / release_stock_reservation
= reservation only
```

Inventory cleanup remains a separate workstream. Do not mix it into Main2/Main1 closure unless new evidence makes it the true current root cause.

---

# 12. FAILURE MEMORY / ANTIPATTERNS

Never repeat:

```text
stale CURRENT_STATE treated as current Git
historical report treated as live production truth
commit message treated as deployment proof
source treated as runtime proof
whole-file overwrite for a surgical repair
missing permissions treated as Owner wildcard
external report treated as definitive current scope
wrong runtime target used to judge a different source fragment
```

Latest known runtime-harness failure:

```text
Workflow = CTO Emergency New-main Closure
Run = 33925065487
Target = Current/PWA/New-main
Patch target = SUCCESS
Browser smoke = FAILURE
Failure = page.goto: Download is starting
```

This is not a Main1 source verdict.

---

# 13. REPORT54 STATUS

```text
REPORT = doc/Draft/Reprots/تقرير54.md
COMMIT = d26695ccca675fb85936bda1707398326ce882ec
STATUS = CURRENT FORENSIC RECONCILIATION
```

Report54 records:

```text
successes
failures
errors
stale-state discovery
ed4e91 source mutation
external-analysis correction
runtime gate failure classification
Production schema evidence
Main1 vision correction
next authorized action
self-audit
```

---

# 14. UNIFIED GOVERNANCE COMMAND

```text
FILE = doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md
COMMIT = e829b747d811e40b402f0e6ba00c366818939a6f
```

It consolidates:

```text
MASTER continuity governance
مبادئ حاكمة
Inventory integrity directives
Main1/Parent vision
Historical-vs-current reconciliation
Production-first verification
Failure memory
Current-state handoff
Gold/Diamond closure rules
```

It remains subordinate to direct Production evidence.

---

# 15. CURRENT CLOSURE STATUS

```text
MAIN1 FORENSIC ROOT CAUSE = CLOSED
MAIN1 PATCH DESIGN = CLOSED
MAIN1 PATCH 1–4 = APPLIED
MAIN1 DIRECT SOURCE VERIFICATION = CLOSED
CURRENT_STATE RECONCILIATION = CLOSED FOR THIS EVENT
EXTERNAL ANALYSIS CLASSIFICATION = CLOSED
MAIN1 INDEPENDENT BROWSER RUNTIME = OPEN
MAIN1→MAIN2 CUMULATIVE RUNTIME = OPEN
NEW-MAIN RUNTIME = OPEN
CORE.JS CENTRALIZATION = OPEN FOLLOW-UP
FULL GOLD/DIAMOND PARENT = OPEN
```

Therefore:

```text
DO NOT CLAIM MAIN1 PRODUCTION DEPLOYED
DO NOT CLAIM MAIN1 BROWSER RUNTIME VERIFIED
DO NOT CLAIM NEW-MAIN RUNTIME CLOSED
DO NOT CLAIM PROJECT CLOSED
DO NOT CLAIM GOLD/DIAMOND
```

---

# 16. NEXT AUTHORIZED ACTION

```text
1. Treat ed4e91... as the authoritative Main1 source mutation.
2. Run cumulative Main1→Main2 source/static verification using the actual open-script contract.
3. Verify the complete assembled JavaScript structure and dependency boundaries.
4. Reassess whether Main2 remains the correct next target.
5. Only then perform the next surgical change.
```

Do not reapply Patch 1–4 unless a new regression is proven.

---

# 17. SUCCESSOR BOOT

Any successor CTO must:

```text
READ CURRENT_STATE.md TO EOF
READ REPORT54 TO EOF
READ MASTER GOVERNANCE TO EOF
READ UNIFIED GOVERNANCE COMMAND
DISCOVER CURRENT GIT HEAD DIRECTLY
VERIFY CURRENT MAIN1 DIRECTLY
VERIFY RELEVANT PRODUCTION CONTRACTS
VERIFY ACTIVE DEPLOYMENTS
CHECK RUNTIME EVIDENCE
RECONCILE DRIFT
DO NOT REPEAT REPORT52/53 PATCH WORK
DO NOT TREAT 8399ff DOCUMENTATION AS A SOURCE PATCH
DO NOT TREAT New-main BROWSER FAILURE AS MAIN1 FAILURE
DO NOT MOVE TO MAIN2 WITHOUT CUMULATIVE MAIN1 VERIFICATION
```

---

# 18. LAST VERIFIED EVENT

```text
SOURCE EVENT = ed4e91ec595234ba7ede3f08558c660c1b100d3e
REPORT EVENT = d26695ccca675fb85936bda1707398326ce882ec
GOVERNANCE EVENT = e829b747d811e40b402f0e6ba00c366818939a6f
STATE RECONCILIATION = this update
```

Current Git HEAD must always be rediscovered directly after any future state/documentation commit.
