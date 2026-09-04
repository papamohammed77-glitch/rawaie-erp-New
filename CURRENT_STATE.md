# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY UPDATE — 2026-09-05

This file is the continuity checkpoint. It is a declared state and must always be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CURRENT GIT HEAD BEFORE THIS STATE UPDATE = ef338627204ed6ba689887c0025b034fd361c750
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
```

---

# 1. LAST VERIFIED STATE — 2026-09-05 FORENSIC CONTINUATION

This round explicitly continued from the prior state; it did not restart Main1 patches.

The following historical/current distinctions were re-verified:

```text
ed4e91 = real Main1 source mutation
Previous session-restore concern = already repaired in current source
Previous New-main browser failure = not evidence of Main1 browser failure
External Main1 report = historical/design reference, not current truth
```

The latest direct Production query at this checkpoint shows one visible company and one corresponding `app_settings` row. Historical multi-company counts from older snapshots must not be reused as current Production facts without re-querying Production.

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

Unified governance successor:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md
```

Latest forensic governance v2:

```text
doc/Draft/medhat/MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md
```

---

# 3. CURRENT REPAIR TARGET

```text
ACTIVE SOURCE REPAIR PACK = Current/PWA/main2/
CURRENT CLOSURE UNIT = Current/PWA/main2/main1.md
NEXT AUTHORIZED TARGET = Main1 deployment/runtime proof
MAIN2 SOURCE IMPLEMENTATION = NOT STARTED
```

The fragments are logical parts of one parent application contract, not eleven independent products.

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

These source repairs are not to be repeated without new contradictory evidence.

---

# 5. SYSTEM SETTINGS / BRANDING CONTRACT

The source contract is:

```text
Authenticated User
→ users.company_id
→ app_settings(company_id)
→ company branding/configuration
```

Current Main1 uses `app_settings` as the authoritative branding/configuration source for company identity shown after entering the system.

Static strings/defaults found in HTML or state are presentation fallbacks only unless direct evidence proves otherwise.

Do NOT replace `app_settings` with static company name/logo values.

Current Production checkpoint:

```text
companies rows = 1
app_settings rows = 1
```

The current `app_settings` record includes:

```text
company_name = الروائع
company_logo = NULL
main_branch_id = a38332b6-6cea-480a-ada1-6eb6ab0590db
delivery_fee = 0.00
tax_rate = 0.00
min_invoice_amount = 0.00
```

This is a configuration readiness fact, not permission to invent missing settings.

---

# 6. MAIN1 CLOSURE STATUS — CURRENT

```text
HISTORICAL RECONCILIATION = CLOSED for addressed Patch 1–4
SOURCE PATCH 1–4 = CLOSED
SOURCE SESSION RESTORE = VERIFIED
SYSTEM SETTINGS AUTHORITY = VERIFIED AS app_settings
PRODUCTION CONFIGURATION = DIRECTLY VERIFIED, CURRENTLY 1 COMPANY / 1 SETTINGS ROW
INDEPENDENT CURRENT MAIN1 RUNTIME = NOT PROVEN
DEPLOYED ARTIFACT EQUIVALENCE = NOT PROVEN
FULL MAIN1 PRODUCT CLOSURE = OPEN
MAIN2 = NOT STARTED
```

The absence of runtime proof is not to be converted into a runtime failure.

---

# 7. HISTORICAL FAILURES / LESSONS PRESERVED

```text
stale CURRENT_STATE ≠ current truth
commit ≠ deployment proof
source ≠ runtime proof
New-main browser failure ≠ Main1 browser failure
historical Main1 analysis ≠ current Main1 source
static fallback ≠ authoritative configuration
```

Do not repeat these failure modes.

---

# 8. CURRENT REPORTS

Latest forensic report created in this continuation:

```text
doc/Draft/Reprots/تقرير55.md
```

It records:

```text
last verified state
source findings
Production findings
historical contradictions
mistakes and lessons
Main1 verdict
runtime gap
next authorized action
final self-audit
```

---

# 9. NEXT AUTHORIZED ACTION

Do not start Main2 source work merely because Main1 source is patched.

First close:

```text
Current Main1 source
+
actual deployment
+
current runtime evidence
+
Production compatibility
+
login/session/branding/navigation smoke evidence
```

Only then reassess Main1 Full Closure and authorize Main2.

---

# 10. FINAL SELF-AUDIT — 2026-09-05

```text
Business Understanding = CONFIRMED for Main1 boundary
Architecture Understanding = CONFIRMED
Database Understanding = CONFIRMED for current app_settings/company state
Historical Understanding = RECONCILED
Current Source Understanding = CONFIRMED
Production Understanding = DIRECTLY VERIFIED for current configuration snapshot
Deployment Understanding = INSUFFICIENT for Full Closure
Runtime Understanding = NOT PROVEN

Unknowns = current independent Main1 browser/runtime verification; deployed artifact equivalence
Conflicts = historical external report vs current Main1 source; old snapshot company counts vs current Production snapshot
Unverified Claims = Main1 is not yet fully runtime-closed

WHAT WAS PROVED = Main1 source Patch 1–4, session restore, app_settings authority
WHAT WAS NOT PROVED = Full runtime closure
WHAT WAS FIXED THIS ROUND = continuity/governance/report/state documentation only; no unjustified Main1 source rewrite
WHAT WAS INITIALLY MISSED = System Settings source needed direct confirmation; Production company count needed fresh query
FINAL CLOSURE STATUS = MAIN1 SOURCE-CLOSED / FULL-CLOSURE-OPEN
MAIN2 STATUS = NOT STARTED
```
