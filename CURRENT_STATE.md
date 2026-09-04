# RAWAEA ERP — CURRENT STATE PACK

## 0. GOVERNANCE

- Direct Production/runtime/database evidence outranks reports, prompts, memory, and closure labels.
- Git proves repository chronology and source content; it does not prove deployment or browser runtime.
- Static source verification is not runtime verification.
- Historical Original is reference/contract evidence only; `Current/PWA/New-main` is the sole canonical application target for the current product-completion track.
- Reports are preserved evidence/history, not current truth by themselves.
- Never infer absence from partial reads.
- Never create a new business authority inside the PWA.
- One active Closure Unit at a time.
- The smallest proven patch outranks speculative whole-file repair.

---

# 1. CURRENT RECONCILIATION — 2026-09-04

## Repository / Git

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
CANONICAL TARGET = Current/PWA/New-main
HISTORICAL REPOSITORY = papamohammed77-glitch/rawaie-erp-review

CURRENT VERIFIED HEAD = cbdd90797629f6410290583efdbbb68011274f98
LATEST TARGET-AFFECTING COMMIT = 282cce040c51b2f4f926a8ca9227ef89ee742713
CURRENT TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
CURRENT TARGET SIZE = 575336 bytes

LATEST REPORT = doc/Draft/Reprots/تقرير49.md
LATEST SUCCESSOR = doc/Draft/medhat/MASTER_CTO_FORENSIC_BRAND_PATCH_SUCCESSOR_V12.md
```

Important: documentation/state commits occurred after the latest Product mutation. A direct compare from `282cce...` to `cbdd907...` shows 53 commits ahead with no `Current/PWA/New-main` in the changed-file set. Therefore:

```text
LATEST REPOSITORY HEAD != LATEST PRODUCT MUTATION
NO VERIFIED New-main MUTATION AFTER 282cce...
```

The current file is synchronized by this commit, but its own final SHA must be discovered from Git and must not be hard-coded here.

---

# 2. LATEST FORENSIC STATION

The previous CURRENT_STATE was stale: it stopped at a documentation checkpoint before the latest Knowledge-Gap 2 report.

Current sequence includes:

```text
Report48
V11 successor
CURRENT_STATE sync
Knowledge-Gap 2 report
Report49
V12 successor
CURRENT_STATE sync (this commit)
```

Latest Git commit before this state sync was:

```text
cbdd90797629f6410290583efdbbb68011274f98
Create comprehensive report for surgical patch decisions
```

This commit added the latest knowledge-gap request and did not mutate New-main.

---

# 3. LATEST PRODUCT TARGET REALITY

Direct source inspection confirms that `Current/PWA/New-main` is a real HTML/CSS/JS PWA artifact, not the previously alleged short descriptive file.

Known current Login source values:

```text
rw-login-title = 58px
rw-login-logo = 88 × 88
```

Current identity surface includes:

```text
RAWAEA ERP ENTERPRISE
الروائع ERP
منصة إدارة الأعمال الذكية والمتكاملة
Clean-room MAIN1 contract surface
```

The application metadata also uses `الروائع ERP`.

Historical claim that New-main was absent/only a tiny descriptive file is classified as an investigator reading error and must not be repeated.

---

# 4. HISTORICAL BRAND EVIDENCE

Direct inspection of `Original/PWA/main/main1.md` confirms:

```text
<title>الروائع ERP | نظام متكامل</title>
rw-login-title = 64px
rw-login-logo = 120 × 120
rw-company-name = 34px
```

Therefore:

```text
Current vs Original title size difference = CONFIRMED
Current vs Original logo size difference = CONFIRMED
Historical canonical product title = الروائع ERP
```

But:

```text
TRUE REGRESSION = NOT PROVEN
INTENTIONAL MODERNIZATION = PLAUSIBLE / NOT PROVEN
```

Do not change 58→64 or 88→120 solely because Original is larger.

The exact historical phrase `نظام إدارة الأعمال الذكي والمتكامل` is NOT proven by the inspected `main1.md`; only `نظام متكامل` is directly proven there.

Therefore:

```text
Current tagline = PRESERVE BY DEFAULT
Exact historical full tagline parity = NOT PROVEN
```

---

# 5. OWNER / LICENSE CONTRACT — PROTECTED

Fresh direct Supabase verification for the recovery station proves:

```text
public.users.permissions = ["*"]
status = Active
role = مدير النظام
Auth isOwner = true
Auth permissions = ["*"]
owner_profile linked
license_status = active
```

Canonical owner model:

```text
OWNER
=
AUTH IDENTITY
+
isOwner=true
+
permissions=["*"]
+
VALID owner_profile
+
ACTIVE LICENSE
```

Never:

```text
replace ["*"] with enumerated role permissions
use role_id as substitute for isOwner
modify owner authorization to make UI work
```

---

# 6. LICENSE MANAGEMENT — SOURCE CONFIRMED, RUNTIME UNKNOWN

Current source contains:

```text
view = license
label = إدارة الترخيص
perm = owner
route = RW_OwnerLicense.render
owner gate = hasOwner()
```

Therefore:

```text
LICENSE MENU/ROUTE SOURCE = CONFIRMED
OWNER GATE = CONFIRMED
LIVE BROWSER VISIBILITY = UNKNOWN
DEPLOYED REVISION = UNKNOWN
SERVICE WORKER/CACHE = UNKNOWN
```

If the user still cannot see the tab, investigate rather than duplicate the route:

```text
Auth session
→ authoritative context
→ currentUser.isOwner
→ RW_STATE.permissions
→ sidebar/menu filtering
→ buildSidebar
→ navigation
→ license route
→ renderer
→ deployed artifact
→ service worker/cache
→ browser
```

---

# 7. KNOWLEDGE-GAP 2 — CURRENT DECISION STATUS

Latest report `تقرير نقص معرفي للمساعد 2` asked for five groups: brand decision, runtime capability, dynamic identity dependencies, patch/commit scope, and rollback.

Current evidence-based decisions:

### Company name

`الروائع ERP` is the strongest canonical display identity because it is proven by the historical title and current app metadata/current company-name surface.

`RAWAEA ERP ENTERPRISE` appears as a current badge but is not proven to represent a complete intentional rebrand.

Treat the difference as an identity inconsistency requiring exact-surface classification, not a justification for global rewrite.

### Tagline

Keep:

```text
منصة إدارة الأعمال الذكية والمتكاملة
```

because the exact historical full alternative is not proven.

### Login visual sizes

```text
58px vs 64px
88×88 vs 120×120
```

Difference is proven; regression is not.

### Runtime

```text
Static source = available
Supabase direct evidence = available
Fresh browser runtime proof = unavailable in this station
```

### Dynamic branding

Current Login identity contains hard-coded literals. Full Sidebar/Header identity dataflow has not been completely proven in this station.

Do not introduce dynamic branding through `app_settings` / `company_profile` as a side-effect of a narrow parity patch.

### Patch scope

Canonical product patch target is:

```text
Current/PWA/New-main
```

Any product patch must be surgical, exact, auditable, and limited to the proven Patch Window.

### Commit / rollback

For a proven Product Patch:

```text
record starting HEAD
record starting target blob
record exact Patch Window
apply one focused change
forensic diff
source recheck
functional test
rollback if acceptance fails
record exact resulting commit SHA
```

---

# 8. CURRENT CLOSURE-UNIT RULE

Choose exactly one active unit.

```text
CU-A = License visibility / runtime-context path
CU-B = Company / Brand identity parity
CU-C = Login visual parity
```

Selection rule:

```text
Active user contradiction + fresh direct evidence
```

Do not select CU-C solely from 58/88 vs 64/120.

Do not run CU-A and CU-B in parallel.

---

# 9. ARCHITECTURAL CONTINUITY

Historical core failure:

```text
DISTRIBUTED BUSINESS LOGIC
```

Target architecture remains:

```text
PWA / Consumer
→ Application / Edge Boundary
→ Central Core / RPC
→ SSOT / DB
```

Inventory/business-engine history remains context, not automatic scope.

```text
post_stock_movement = central movement authority
reserve_stock = reservation authority
allocated_qty != physical qty
Picking != physical movement
Loading = MAIN → VAN
Van Sale = VAN → Customer
Unloading = VAN → MAIN
```

Do not reopen Inventory, Accounting, Ledger, or Treasury unless a current Closure Unit proves a blocking dependency.

---

# 10. LATEST PATCH RESULT

For the current forensic station:

```text
PRODUCT PATCH = NONE
DATABASE PATCH = NONE
DEPLOYMENT PATCH = NONE
```

This is intentional. The station's verified work was continuity reconstruction, Knowledge-Gap resolution, and successor preparation.

```text
NO-PATCH = CORRECT / INTENTIONAL
```

---

# 11. REPORT / SUCCESSOR RECORDS

Latest preserved evidence:

```text
Report49 = doc/Draft/Reprots/تقرير49.md
V12 = doc/Draft/medhat/MASTER_CTO_FORENSIC_BRAND_PATCH_SUCCESSOR_V12.md
```

Previous preserved evidence remains:

```text
Report48
V11
V10
V9
V8
V7
V6
V5
and all earlier reports/directives
```

Never delete historical reports.

---

# 12. RAW SOURCE PACK FOR NEXT ASSISTANT

Use raw URLs:

```text
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/CURRENT_STATE.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Current/PWA/New-main
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/Original/PWA/main/main1.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/%D8%AA%D9%82%D8%B1%D9%8A%D8%B148.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/%D8%AA%D9%82%D8%B1%D9%8A%D8%B949.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/Reprots/%D8%AA%D9%82%D8%B1%D9%8A%D8%B1%20%D9%86%D9%82%D8%B5%20%D9%85%D8%B9%D8%B1%D9%81%D9%8A%20%D9%84%D9%84%D9%85%D8%B3%D8%A7%D8%B9%D8%AF%202
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_CTO_FORENSIC_EXECUTION_SUCCESSOR_V11.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_CTO_FORENSIC_BRAND_PATCH_SUCCESSOR_V12.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_CTO_NEWM_LIMITED_ASSISTANT_TASK_COMPANY_IDENTITY_V6.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_CTO_NEWM_LIMITED_ASSISTANT_TASK_LOGIN_PARITY_V5.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-New/main/doc/Draft/medhat/MASTER_OFFLINE_CTO_NEW_MAIN_COMPLETION.md
https://raw.githubusercontent.com/papamohammed77-glitch/rawaie-erp-review/main/README.md
```

`MASTER - RAWAEA ERP.md` could not be independently retrieved as a standalone current-repository/current-file-surface artifact during this station. Do not invent its content; search it independently if a future source becomes available.

---

# 13. KNOWN INVESTIGATOR ERRORS — DO NOT REPEAT

```text
Do not start from zero.
Do not trust stale CURRENT_STATE for current HEAD.
Do not confuse documentation commits with product commits.
Do not declare New-main absent from partial display.
Do not treat Original differences as automatic regressions.
Do not duplicate License route because browser visibility is unknown.
Do not replace Owner ["*"] with role enumeration.
Do not treat Git as deployment proof.
Do not treat source as browser proof.
Do not treat closure metadata as fresh Gold/Diamond proof.
Do not expand Patch Window without evidence.
Do not perform speculative whole-file rewrites.
Do not introduce future architecture into a narrow fix.
```

---

# 14. RUNTIME / DEPLOYMENT STATUS

```text
RUNTIME = UNKNOWN
DEPLOYMENT = UNKNOWN
SERVICE WORKER / CACHE = UNKNOWN
FRESH GOLD = NOT PROVEN
FRESH DIAMOND = NOT PROVEN
WHOLE-PROJECT 100% = NOT PROVEN
```

---

# 15. HANDOFF

```text
STARTING HEAD FOR NEXT SUCCESSOR = cbdd90797629f6410290583efdbbb68011274f98
LATEST TARGET-AFFECTING COMMIT = 282cce040c51b2f4f926a8ca9227ef89ee742713
TARGET = Current/PWA/New-main
TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
TARGET SIZE = 575336 bytes
LATEST REPORT = doc/Draft/Reprots/تقرير49.md
LATEST SUCCESSOR = doc/Draft/medhat/MASTER_CTO_FORENSIC_BRAND_PATCH_SUCCESSOR_V12.md
PRODUCT MUTATION THIS STATION = NONE
DATABASE MUTATION THIS STATION = NONE
DEPLOYMENT MUTATION THIS STATION = NONE
OWNER WILDCARD = VERIFIED AT RECOVERY STATION
LICENSE SOURCE = VERIFIED
LICENSE RUNTIME = UNKNOWN
BRAND TRUE REGRESSION = NOT PROVEN
TAGLINE EXACT HISTORICAL PARITY = NOT PROVEN
```

## FINAL CONTINUITY RULE

> The successor inherits evidence trails, not confidence.
> Reality outranks narrative.
> EOF outranks partial visibility.
> Historical continuity is preserved, but historical assumptions do not outrank fresh evidence.
> The smallest proven patch outranks the cleanest speculative rewrite.
> Unknown runtime behavior remains UNKNOWN until observed.
