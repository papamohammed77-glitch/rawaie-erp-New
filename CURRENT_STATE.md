# RAWAEA ERP — CURRENT STATE PACK

## 0. AUTHORITATIVE CONTINUITY UPDATE — 2026-09-04

This file is the continuity checkpoint. It is a declared state and must always be reconciled against direct Git, Production, deployments, and runtime evidence.

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

### Latest verified Git event before this update

```text
2bffd02f09f757424e4bfa38f3411ee9cf74b2ba
[CTO] Add Report52 forensic Main1 source repair closure
```

### This continuity update

```text
Report53 = doc/Draft/Reprots/تقرير53.md
Purpose = reconcile latest Git reality and preserve Main2/Main1 repair checkpoint
```

Discover the exact current `main` HEAD directly from Git after any documentation commit; never hard-code this file's own future SHA.

---

# 1. LAST VERIFIED STATE

The project did NOT stop at Report51.

Direct Git investigation discovered:

```text
2bffd02...  Report52 forensic Main1 closure
8049d898...  Delete Current/PWA/main2/Test
c55ce8b3...  Add files via upload (Main2 source pack)
```

Therefore older `CURRENT_STATE` entries that named Report51 as latest were stale and have now been reconciled.

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

The owner explicitly changed the active repair target for this stream.

```text
ACTIVE SOURCE REPAIR PACK = Current/PWA/main2/
CURRENT CLOSURE UNIT = Current/PWA/main2/main1.md
```

This does NOT redefine Production's deployed product target; it defines the source-repair workstream requested for the 11-part Main2 composite.

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
BLOB SHA = 14b12a471c20ad23a2c18f456dbc4d59783a0d1f
SIZE = 63126 bytes
INSERTION COMMIT = c55ce8b3e0ecdfffc5739afdac53910009208f43
```

Direct source inspection confirms Main1 contains:

```text
HTML shell
CSS
Supabase client bootstrap
RW_Table
RW_Audit_log
RW_Permissions_check
RW_Permissions_applyUI
RW_Workflow
RW_Notification
RW_Audit UI
RW_STATE
RW_Auth
RW_Data
RW_Navigation
```

The fragment ends at `RW_Navigation` without closing the global script, while `main2.md` continues with the next logical application section.

---

# 5. REPORT52 STATUS — CRITICAL CONTINUITY FACT

Report52 did NOT change Main1 source bytes.

Its actual status was:

```text
FORENSIC ANALYSIS = CLOSED
ROOT CAUSE = PROVEN
SURGICAL PATCH WINDOWS = PROVEN
SOURCE MUTATION = NO
PRODUCTION DEPLOYMENT = NO
BROWSER RUNTIME = NO
```

The four proven Main1 repair windows were:

```text
PATCH 1 = add company id to RW_STATE.app.company
PATCH 2 = resolve authoritative company_id from public.users during login
PATCH 3 = company-scope app_settings lookup
PATCH 4 = explicit company scope on bootstrap reads
```

---

# 6. PROVEN MAIN1 DEFECTS

## A — Unsafe wildcard default

Current source contains:

```javascript
RW_STATE.permissions = meta.permissions || ['*'];
```

This is a confirmed frontend authorization default defect.

Owner wildcard semantics remain protected and must NOT be enumerated or replaced.

## B — Missing authoritative company bootstrap

Login uses Auth metadata without obtaining the authoritative `public.users.company_id`.

## C — Global app_settings lookup

Current source uses an unscoped:

```javascript
.from('app_settings').select('*').limit(1)
```

## D — Bootstrap reads have no explicit company scope

Current Main1 loads items/customers/branches/suppliers without explicit `company_id` filters. Current RLS protects them, so a security incident is not proven, but explicit tenant propagation is the authorized hardening.

---

# 7. FINDINGS INTENTIONALLY PRESERVED

No direct evidence authorizes changing these in Main1:

```text
login title 64px
login logo 120×120
company-name 34px
RAWAEA ERP ENTERPRISE
منصة إدارة الأعمال الذكية والمتكاملة
owner wildcard semantics
workflow_rules global-read contract
notification_templates global-read contract
audit_log owner contract
```

Historical/current difference alone is not a defect.

---

# 8. IMPORTANT CROSS-SOURCE DISTINCTION

`Current/PWA/main/main1.md` is a DIFFERENT source file and already contains a newer `RW_ShellContext` hardening pattern.

Do not copy it wholesale into Main2/Main1.

Classification:

```text
main/main1 = current different lineage/reference
main2/main1 = active source-repair target
```

Only proven patch windows may cross the boundary.

---

# 9. PRODUCTION / DATABASE CONTINUITY

Production evidence relevant to this workstream confirms:

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

No Main2/Main1 production deployment was proven or performed by Report52/Report53.

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

When a write tool only supports complete-file replacement, do not use it for a narrow repair unless the full file has first been reconstructed and re-read safely.

---

# 12. CURRENT MAIN1 PATCH INSTRUCTIONS

The exact approved surgical replacements remain in Report52 and Report53.

### PATCH 1
Search for this exact line:

```javascript
const RW_STATE = { app: { initialized: false, authenticated: false, loading: false, currentView: 'dashboard', currentUser: null, company: { name: 'الروائع ERP', logo: 'ر' } }, data: { items: [], customers: [], suppliers: [], branches: [] }, permissions: [], ui: { sidebarOpen: false, sidebarCollapsed: false } };
```

Replace only the `company` object with:

```javascript
company: { id: null, name: 'الروائع ERP', logo: 'ر' }
```

### PATCH 2
Replace the Main1 login block beginning exactly with:

```javascript
var user = authRes.data.user;
var meta = user.user_metadata || {};
```

and ending at:

```javascript
self.enterSystem();
```

with the authoritative `public.users` lookup shown in Report53 / Report52.

### PATCH 3
Replace the first unscoped `app_settings` lookup inside `enterSystem()` with:

```javascript
RW_SUPABASE_CLIENT
    .from('app_settings')
    .select('*')
    .eq('company_id', RW_STATE.app.company.id)
    .order('created_at', { ascending: true })
    .limit(1)
```

### PATCH 4
Add explicit company scope to the four bootstrap reads:

```javascript
.eq('company_id', RW_STATE.app.company.id)
```

for:

```text
items
customers
branches
suppliers
```

No other Main1 change is authorized by the current evidence at this checkpoint.

---

# 13. CURRENT CLOSURE STATUS

```text
MAIN1 TARGET IDENTIFIED = CONFIRMED
MAIN1 SOURCE INSPECTED = CONFIRMED
MAIN1 PRODUCTION CONTRACT CHECKED = CONFIRMED
MAIN1 ROOT CAUSES = PROVEN
MAIN1 PATCH DESIGN = CLOSED
MAIN1 SOURCE BYTES = UNCHANGED
MAIN1 PRODUCTION DEPLOYMENT = NOT PERFORMED
MAIN1 RUNTIME = NOT VERIFIED
MAIN1 SOURCE APPLICATION = MANUAL SURGICAL PATCH PENDING
MAIN2 = NOT STARTED
```

Therefore:

```text
DO NOT CLAIM MAIN1 CLOSED
DO NOT CLAIM PRODUCTION FIXED
DO NOT CLAIM RUNTIME VERIFIED
DO NOT CLAIM GOLD/DIAMOND
```

---

# 14. NEXT AUTHORIZED ACTION

```text
1. Apply PATCH 1–4 manually to Current/PWA/main2/main1.md.
2. Re-read the complete modified Main1 from line 1 to EOF.
3. Confirm exactly one RW_STATE and one RW_Auth bootstrap remain.
4. Confirm no historical code was unintentionally reintroduced.
5. Establish the new Main1 SHA.
6. Run fragment/static syntax and Main1→Main2 integration checks.
7. Record the event in the next numbered forensic report.
8. Only after Main1 source gate closes, begin Main2.
```

Do not reopen historical login-brand visual work without fresh contradictory evidence.

---

# 15. LATEST DOCUMENTATION ARTIFACTS

```text
MASTER GOVERNANCE:
doc/Draft/medhat/MASTER - RAWAEA ERP.md

LATEST FORENSIC REPORT:
doc/Draft/Reprots/تقرير53.md

PREVIOUS FORENSIC REPORT:
doc/Draft/Reprots/تقرير52.md

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
VERIFY MAIN2/MAIN1 BLOB DIRECTLY
VERIFY RELEVANT PRODUCTION CONTRACTS
RECONCILE ANY DRIFT
DO NOT REPEAT REPORT52 FORENSIC WORK AS IF IT WERE UNDONE
DO NOT ASSUME REPORT52 PATCH WAS APPLIED
DO NOT MOVE TO MAIN2 BEFORE MAIN1 SOURCE GATE
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
EVENT ID = 2bffd02f09f757424e4bfa38f3411ee9cf74b2ba
EVENT TYPE = FORENSIC DOCUMENTATION / MAIN1 SOURCE REPAIR CLOSURE DESIGN
DATE = 2026-09-04
RESULT = Main1 root causes and exact surgical patch windows proven; source left unchanged intentionally.
NEXT AUTHORIZED ACTION = manual application of PATCH 1–4 followed by full EOF re-read and SHA verification.
```

This file is the new continuity checkpoint. Exact current `main` HEAD must still be rediscovered directly from Git after this state commit.
