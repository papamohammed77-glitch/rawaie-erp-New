# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY UPDATE — 2026-09-05

This file is the continuity checkpoint. It is a declared state and must always be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD = 8399ff50664b76c776f01a9e941cc2bdfd247b59
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

### Latest verified Git events

```text
ed4e91ec595234ba7ede3f08558c660c1b100d3e
Update main1.md
= ACTUAL SOURCE MUTATION
= Main1 Patch 1–4 applied

8399ff50664b76c776f01a9e941cc2bdfd247b59
Update تحليل مساعد خارجي -main1
= DOCUMENTATION UPDATE ONLY
= CURRENT HEAD
```

### Reconciliation result

The previous 2026-09-04 state was stale because it pre-dated `ed4e91...`. The four Main1 patch windows formerly marked pending are now present in `Current/PWA/main2/main1.md` and were introduced by `ed4e91...`.

The latest browser gate observed after the newer HEAD was **not a Main1 source-runtime failure**. The `CTO Emergency New-main Closure` workflow failed on the `Browser smoke` step with `page.goto: Download is starting` while targeting `Current/PWA/New-main`. Its `Patch target` step passed, but the workflow was not able to establish browser runtime closure for New-main. This result must not be used to declare Main1 runtime failure.

---

# 1. LAST VERIFIED STATE

The project did NOT stop at Report51.

Direct Git investigation discovered the following continuity chain:

```text
2bffd02...  Report52 forensic Main1 closure design
7e07088...  CURRENT_STATE sync with Report53 checkpoint
ed4e91e...  ACTUAL Main1 source repair (Patch 1–4)
76a5fdd...  External Main1 analysis report created
8399ff5...  External Main1 analysis report updated — CURRENT HEAD
```

Therefore older `CURRENT_STATE` entries that named Report52/Report53 as the latest actionable state were reconciled against the actual source mutation at `ed4e91...`.

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

The complete governance source is:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP.md
```

---

# 3. CURRENT REPAIR TARGET

For this source-repair stream:

```text
ACTIVE SOURCE REPAIR PACK = Current/PWA/main2/
CURRENT CLOSURE UNIT = Current/PWA/main2/main1.md
```

This does NOT redefine Production's deployed product target; it defines the source-repair workstream for the 11-part Main2 composite.

`Current/PWA/main2` contains:

```text
main1.md
main2.md
main3.md
main4.md
main5.md
main6.md
main7.md
main8.md
main9.md
main10.md
main11.md
```

The fragments are logical parts of one parent application contract, not eleven independent products.

---

# 4. MAIN1 VERIFIED SOURCE STATE

```text
PATH = Current/PWA/main2/main1.md
SOURCE STATUS = PATCHED BY ed4e91ec595234ba7ede3f08558c660c1b100d3e
```

Direct source inspection after the mutation confirms the following repair state:

```text
PATCH 1 = RW_STATE.app.company now includes id: null
PATCH 2 = login resolves public.users.company_id by auth_id and rejects incomplete/inactive context
PATCH 2 = permissions fallback is [] rather than implicit ['*']
PATCH 3 = app_settings lookup is explicitly scoped by RW_STATE.app.company.id
PATCH 4 = items/customers/branches/suppliers bootstrap reads explicitly carry company_id scope
```

The current Main1 also retains the previously established UI identity values:

```text
login title = 64px
login logo = 120×120
company-name = 34px
```

These were not reclassified as defects merely because the external report mentioned different parent-file values.

The fragment remains an intentional open-script logical fragment whose JavaScript assembly boundary is continued by later Main2 fragments. It must not be treated as an independently deployable HTML application solely because its filename is `.md`.

---

# 5. REPORT52 / REPORT53 STATUS — RECONCILED

The historical status was:

```text
FORENSIC ANALYSIS = CLOSED
ROOT CAUSE = PROVEN
SURGICAL PATCH WINDOWS = PROVEN
SOURCE MUTATION = NO
PRODUCTION DEPLOYMENT = NO
BROWSER RUNTIME = NO
```

That status is now **historical and superseded** for the source mutation itself by `ed4e91...`.

Current status is:

```text
FORENSIC DESIGN = CLOSED
SOURCE PATCH DESIGN = CLOSED
SOURCE MUTATION = APPLIED
SOURCE VERIFICATION = CONFIRMED BY DIRECT CONTENT INSPECTION
PRODUCTION PRODUCT DEPLOYMENT = NOT PROVEN
MAIN1 INDEPENDENT BROWSER RUNTIME = NOT PROVEN
```

Do not reopen Report52/53 patch work unless fresh contradictory evidence appears.

---

# 6. PROVEN MAIN1 DEFECTS — CURRENT RESULT

## A — Unsafe wildcard default

Historical defect:

```javascript
RW_STATE.permissions = meta.permissions || ['*'];
```

Current source result:

```javascript
RW_STATE.permissions = Array.isArray(meta.permissions) ? meta.permissions : [];
```

Owner wildcard semantics remain protected at the Owner contract level. The absence of a generic `['*']` fallback must not be converted into removal of legitimate Owner `permissions = ['*']` semantics.

## B — Missing authoritative company bootstrap

Historical defect:

Login depended on Auth metadata alone.

Current source result:

```text
Auth user
→ public.users by auth_id
→ company_id + status
→ RW_STATE.app.company.id
```

## C — Global app_settings lookup

Historical defect:

```javascript
.from('app_settings').select('*').limit(1)
```

Current source result is explicitly company-scoped and deterministically ordered before `.limit(1)`.

## D — Bootstrap reads had no explicit company scope

Current source result adds explicit company scope to:

```text
items
customers
branches
suppliers
```

This is hardening plus tenant propagation; it does not replace database-side RLS.

---

# 7. FINDINGS INTENTIONALLY PRESERVED

No current direct evidence authorizes changing these in Main1 merely because an external analysis suggested a parent-file target:

```text
login title 64px
login logo 120×120
company-name 34px
owner wildcard semantics
workflow_rules global-read contract
notification_templates global-read contract
audit_log owner contract
```

Historical/current difference alone is not a defect.

The external report's branding claims must be understood as a **cross-file Parent/New-main recommendation**, not as proof that the active Main2/Main1 source is visually defective.

---

# 8. IMPORTANT CROSS-SOURCE DISTINCTION

There are multiple Main1 lineages:

```text
Current/PWA/main/main1.md
Current/PWA/main2/main1.md
Original/PWA/main/main1.md
Current/PWA/New-main
```

They are not automatically byte-identical and must not be overwritten onto one another.

Classification:

```text
main/main1 = current different lineage/reference
main2/main1 = active source-repair target
New-main = integrated parent application artifact
Original/main1 = historical contract evidence
```

Only proven responsibilities and patch windows may cross lineage boundaries.

---

# 9. PRODUCTION / DATABASE CONTINUITY

Production evidence relevant to the broader project confirms:

```text
PostgreSQL 17.6
RLS protects company-scoped app_settings/items/customers/branches
users self-row is addressable by auth_id = auth.uid()
app_private.current_user_company_id() exists as a company-context helper
```

Owner/license contract remains protected:

```text
isOwner = true
permissions = ["*"]
owner_profile valid
license_status = active
```

No claim is made that the Main2/Main1 source fragment itself is a separately deployed Production artifact.

---

# 10. INVENTORY CONTRACT — PROTECTED

```text
PHYSICAL STOCK MOVEMENT
→ post_stock_movement
→ stock_branches + inventory_log

reserve_stock / release_stock_reservation
= reservation only
```

No PWA fragment may become a competing physical stock authority.

---

# 11. FAILURE MEMORY / ANTIPATTERNS

Do not repeat:

```text
stale CURRENT_STATE treated as current Git
historical Original treated as automatic target
commit message treated as deployment proof
source treated as browser runtime proof
whole-file overwrite for surgical repair
missing Auth permissions treated as owner wildcard
reports/self-attestation treated as current production truth
```

Known recent failure:

```text
CTO Emergency New-main Closure / Browser smoke
HEAD tested = 8399ff...
Patch target = PASS
Browser smoke = FAIL
Failure = page.goto: Download is starting
Target = Current/PWA/New-main
```

This failure mode is an **integration/runtime-harness issue**, not proof that Main1's `ed4e91...` source mutation is wrong.

When a write tool only supports complete-file replacement, do not use it for a narrow repair unless the full file has first been reconstructed and re-read safely.

---

# 12. CURRENT MAIN1 PATCH STATUS

The four previously approved patch windows are now **applied** by `ed4e91...`.

```text
PATCH 1 = APPLIED
PATCH 2 = APPLIED
PATCH 3 = APPLIED
PATCH 4 = APPLIED
```

Direct current-source inspection confirms all four.

No additional Main1 source mutation is currently authorized solely from the external analysis report.

---

# 13. CURRENT CLOSURE STATUS

```text
MAIN1 TARGET IDENTIFIED = CONFIRMED
MAIN1 SOURCE INSPECTED = CONFIRMED
MAIN1 PRODUCTION CONTRACT CHECKED = CONFIRMED
MAIN1 ROOT CAUSES = PROVEN
MAIN1 PATCH DESIGN = CLOSED
MAIN1 SOURCE PATCH = APPLIED
MAIN1 DIRECT SOURCE RE-READ = CONFIRMED
MAIN1 PRODUCTION PRODUCT DEPLOYMENT = NOT PROVEN
MAIN1 INDEPENDENT BROWSER RUNTIME = NOT PROVEN
MAIN2 SOURCE = NOT MODIFIED BY THIS MAIN1 EVENT
```

Therefore:

```text
DO NOT CLAIM MAIN1 PRODUCTION DEPLOYED
DO NOT CLAIM MAIN1 BROWSER RUNTIME VERIFIED
DO NOT CLAIM PROJECT CLOSED
DO NOT CLAIM GOLD/DIAMOND
```

The source-level Main1 closure may be described as:

```text
SOURCE PATCH APPLIED + SOURCE VERIFIED
```

not as a full runtime/product closure.

---

# 14. NEXT AUTHORIZED ACTION

```text
1. Preserve ed4e91... as the authoritative Main1 source mutation.
2. Re-run a safe cumulative Main1→Main2 static/syntax verification against the actual open-script fragment contract.
3. Do not use the failed New-main Download-is-starting browser gate as a Main1 verdict.
4. If the cumulative source gate passes, reassess whether Main2 is truly the next target.
5. Any Main2 mutation must start from the newly verified state, not from Report53's stale pending-patch state.
```

Do not reopen historical login-brand visual work without fresh contradictory evidence.

---

# 15. LATEST DOCUMENTATION ARTIFACTS

```text
MASTER GOVERNANCE:
doc/Draft/medhat/MASTER - RAWAEA ERP.md

LATEST SOURCE-REPAIR REPORT:
doc/Draft/Reprots/تقرير54.md

PREVIOUS FORENSIC REPORT:
doc/Draft/Reprots/تقرير53.md

EXTERNAL MAIN1 ANALYSIS:
doc/Draft/Reprots/تحليل مساعد خارجي -main1

KNOWLEDGE PACK:
doc/Draft/Reprots/MASTER_RAWAEA_SYSTEM_PWA_KNOWLEDGE_PACK_2026-09-04.md

PROJECT MEMORY:
PROJECT_MEMORY.md

ACTIVE SOURCE PACK:
Current/PWA/main2/
```

No historical report was deleted or overwritten.

---

# 16. SUCCESSOR BOOT

Any successor CTO must first:

```text
READ CURRENT_STATE.md TO EOF
READ LATEST NUMBERED REPORT TO EOF
DISCOVER CURRENT GIT HEAD DIRECTLY
VERIFY CURRENT Main1 BLOB DIRECTLY
VERIFY RELEVANT PRODUCTION CONTRACTS
RECONCILE ANY DRIFT
DO NOT REPEAT REPORT52/53 FORENSIC WORK AS IF IT WERE UNDONE
DO NOT ASSUME REPORT52 PATCH WAS PENDING
DO NOT MOVE TO MAIN2 BEFORE THE CURRENT MAIN1 SOURCE GATE IS RE-EVALUATED
```

The successor must distinguish:

```text
PROVEN
DESIGNED
APPLIED
DEPLOYED
RUNTIME VERIFIED
CLOSED
```

---

# 17. LAST VERIFIED EVENT

```text
EVENT ID = ed4e91ec595234ba7ede3f08558c660c1b100d3e
EVENT TYPE = MAIN1 SOURCE SURGICAL REPAIR
DATE = 2026-09-04T21:45:51Z
RESULT = Main1 Patch 1–4 actually applied and confirmed in the current source.
EVIDENCE = direct current Git content + commit diff
NEXT AUTHORIZED ACTION = cumulative Main1→Main2 source verification, then reassess target.
```

### Current HEAD documentation-only event

```text
EVENT ID = 8399ff50664b76c776f01a9e941cc2bdfd247b59
EVENT TYPE = EXTERNAL MAIN1 ANALYSIS DOCUMENT UPDATE
DATE = 2026-09-04T22:20:03Z
RESULT = analysis report updated; no Main1 source mutation in this commit.
```

This file is the new continuity checkpoint. Exact current `main` HEAD must still be rediscovered directly from Git after any future state commit.
