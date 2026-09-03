# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Direct Production/runtime/database evidence outranks historical reports, prompts, memory, and closure labels.
- `Current/PWA/New-main` is the only authorized application target for this product-completion track.
- `Current/PWA/main.html` and `Original/PWA/main/*` are references/contracts, not alternative publish targets.
- Fragment-only reconstruction is forbidden as persistence authority.
- Production Supabase business-data writes remain forbidden in this closure track.
- Historical reports are preserved; this file is the reconciled current-state index.

## HISTORICAL CLOSURE RECORD — PRESERVED
Earlier closure evidence proved trusted artifacts and earlier Gold/Diamond states. Those historical states are not silently promoted to current truth.

The historical regression/reconstruction incidents, verifier failures, competing-writer discovery, P163, MAIN2 governance, Diamond 122 and earlier closure evidence remain preserved in Git history and under `doc/Draft/Reprots/`.

## CURRENT AUTHORITATIVE RECONCILIATION — 2026-09-03

### Git identity
```text
REPOSITORY          = papamohammed77-glitch/rawaie-erp-New
BRANCH              = main
CURRENT HEAD        = <UPDATED BY THIS STATE COMMIT>
TARGET              = Current/PWA/New-main
CURRENT TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
```

The latest application target-affecting commit remains:

```text
282cce040c51b2f4f926a8ca9227ef89ee742713
Update New-main
```

Its direct target diff changed only the embedded timestamp from `18:00 UTC` to `22:00 UTC`.

After that target-affecting line, the repository changes were continuity/documentation work only until Report 36 was added and this file was reconciled again. No evidence currently shows a `Current/PWA/New-main` change after `282cce...`.

### Latest continuity commits
```text
ac77379f529ce4e8325af277e48dee692703ba5f
[CTO] Update CURRENT_STATE with Report 35 and offline V6 handoff

287bcc4d1b73de8843d8466267a78634c5d2995d
[CTO] Add forensic continuity Report 36 and offline successor mission packet

<state commit created immediately after the Report-36 commit>
[CTO] Reconcile CURRENT_STATE with Report 36 and offline successor mission
```

The exact final SHA of the state commit is the Git HEAD produced by this update. The target blob remains unchanged.

## CURRENT TARGET — DIRECT EVIDENCE

`Current/PWA/New-main` was fetched directly and is a complete HTML artifact beginning with:

```html
<!doctype html>
<!-- 2026-09-03 22:00 UTC -->
<html lang="ar" dir="rtl">
```

It currently references:

```html
<link rel="manifest" href="./manifest.json">
```

and contains the Login surface, application shell, sidebar/header, navigation, Dashboard/data logic, and multiple application modules.

A historical Gold/Diamond meta marker exists in the file but is not treated as fresh closure evidence.

## CURRENT PWA MANIFEST — CLOSED

```text
Current/PWA/manifest.json
start_url = ./New-main
scope     = ./
dir       = rtl
lang      = ar
icons     = 3
SHA       = f2f52998fd04094905f09afa9fbcb64b2bd38190
```

Therefore:

```text
OLD MANIFEST DISCREPANCY = CLOSED
```

Do not reopen without new direct evidence.

## OWNER / LICENSE CONTRACT — VERIFIED

Fresh direct Supabase evidence in the continuity chain establishes:

```text
public.users.permissions = ["*"]
public wildcard           = true
Auth isOwner              = true
Auth permissions         = ["*"]
owner_profile linkage    = valid
license_status           = active
```

Correct owner semantics:

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
ACTIVE license
```

Do not replace this with role-permission enumeration.

An initial verification query incorrectly treated JSONB permissions as a PostgreSQL `text[]`; it failed, was corrected, and the direct verification succeeded. This is an investigator/query-type error, not a production defect.

## REPORT 33 INCIDENTS — CURRENTLY RECLASSIFIED AS LEADS

Historical runtime incidents:

```text
safeText is not defined
AUTH_ID_UNAVAILABLE
```

The Report-33 target snapshot is obsolete as current source because `New-main` changed afterward.

Current status:

```text
CARRIED-FORWARD INCIDENT LEADS
CURRENT TRACE REQUIRED
NO BLIND HISTORICAL PATCH
```

No fresh Chromium run is claimed in this continuity cycle.

## HISTORICAL UX CONTRACT

Direct inspection of `Original/PWA/main/main1.md` proved a richer historical Login contract including:

```text
Cairo
Tailwind
64px title
120x120 logo
large glass login card
gradient brand background
feature list
icon-bearing inputs
remember-me
forgot-password
password visibility
```

The `Original/PWA/main/` directory contains:

```text
main1.md ... main11.md
```

These are historical contract evidence. They are not alternative deployment targets.

## CURRENT PRODUCT COMPLETION OBJECTIVE

The next CTO must not confuse:

```text
FUNCTIONS EXIST
```

with:

```text
PRODUCT IS COMPLETE
```

Completion of the current scope requires:

```text
STRUCTURE
+ VISUAL IDENTITY
+ FUNCTIONAL CAPABILITY
+ RUNTIME INTEGRITY
+ BUSINESS SEMANTICS
+ SECURITY / TENANCY
+ PRODUCT EXPERIENCE
```

Immediate scoped product work:

```text
Company information / Logo
Login visual + functional parity
Full master sidebar
Dashboard
Sales management
```

The target must remain architecturally ready for the remaining tabs and must not become a set of islands.

## CURRENT `New-main` REALITY

Current source evidence shows real implementations, not an empty skeleton:

```text
Login surface
Owner-only audit path
Company-scoped Dashboard/data queries
Customers data/CRUD path
Items/stock data path
Suppliers data/CRUD path
Navigation/application shell
```

However, function presence is not completion proof.

A current Dashboard implementation exists, including company-scoped reads and chart/data logic, but product-level closure is still OPEN pending visual, runtime, business, navigation, security, and UX verification.

## EXACT AUTHORIZED TARGET MODIFICATION SURFACE

Do not define changes by brittle numeric line ranges. Use semantic anchors in `Current/PWA/New-main`.

### BLOCK A — LOGIN / COMPANY / LOGO
```text
<style> sections for .rw-login-* and .rw-company-*
<div id="rw-login-page"> ... </div>
```

### BLOCK B — MASTER SHELL / SIDEBAR / HEADER
```text
<div id="rw-main-shell">
<aside id="rw-sidebar">
<header id="rw-header">
#rw-page-container
```
plus directly associated CSS/navigation renderers.

### BLOCK C — AUTH / SESSION / COMPANY CONTEXT BRIDGE
Modify only existing code responsible for:

```text
session acquisition
current user
isOwner
permissions
company context
company identity
logo source resolution
```
when evidence proves a defect.

### BLOCK D — DASHBOARD
Modify only the existing Dashboard renderer and its direct presentation/data wiring for the active scope.

### BLOCK E — SALES MANAGEMENT
Modify only the existing Sales Management surface and direct client-side orchestration/navigation wiring.

Historical Sales files are references/contracts, not six new deployable applications inside the master app.

## OUT OF SCOPE UNLESS A BLOCKING DEPENDENCY IS PROVEN

```text
inventory business engines
stock posting logic
reservation engines
accounting core
ledger core
treasury
unrelated purchasing internals
delivery backend logic
Original files as application targets
Supabase production data
parallel application targets
```

## CENTRAL CORE / NO-ISLANDS CONSTITUTION

```text
RAWAEA MASTER SYSTEM
        ↓
CENTRAL BUSINESS HEART
        ↓
DOMAIN ENGINES
        ↓
OPERATING APPLICATIONS
```

`New-main` is a client/orchestrator and must not become a parallel ERP business core.

Use existing authoritative backend/core contracts; do not duplicate stock/accounting/ledger authority inside the PWA.

## OPTIMIZED FIVE-FILE OFFLINE SUCCESSOR PACKET

Because the successor CTO has no GitHub/Supabase/external file access, use these five logical attachments:

```text
1. Current/PWA/New-main — FULL CONTENT
2. Original/PWA/main.html — FULL CONTENT
3. Original/PWA/core.js — FULL CONTENT
4. One exact-content pack: Original/PWA/main/main1.md ... main11.md
5. One exact-content pack: every complete file under Original/PWA/sales/
```

Current Sales pack contains:

```text
Original/PWA/sales/order-taker.html
Original/PWA/sales/pos.html
Original/PWA/sales/sales.manager.html
Original/PWA/sales/sales.supervisor.html
Original/PWA/sales/telesales.html
Original/PWA/sales/van-sales.html
```

Preserve exact source-path headers in concatenated packs.

Important distinction:

```text
SEND FULL TARGET
BUT MODIFY ONLY THE AUTHORIZED INTERNAL BLOCKS
```

`main1` alone is insufficient for strict no-guessing completion of the master application.

## REQUIRED OFFLINE CTO SEQUENCE

```text
RECEIVE PACKET
→ COMPLETE-PACKET GATE
→ READ FULL New-main
→ READ ALL REFERENCE PACKS
→ RECONCILE CURRENT / HISTORICAL
→ TRACE safeText
→ TRACE AUTH_ID
→ LOGIN / COMPANY / LOGO
→ MASTER SIDEBAR / HEADER / NAVIGATION
→ DASHBOARD
→ SALES MANAGEMENT
→ NO-ISLANDS / INTEGRATION AUDIT
→ NAVIGATION / REFRESH / RE-ENTRY REGRESSION
→ OWNER / NON-OWNER AUTHORIZATION REVIEW
→ TENANT / SECURITY REVIEW OF TOUCHED PATHS
→ PRODUCT COMPLETENESS REVIEW
→ GOLD
→ DIAMOND
```

## GOLD / DIAMOND STATUS

Current status remains:

```text
CURRENT GOLD      = NOT CLAIMED
CURRENT DIAMOND   = NOT CLAIMED
CURRENT 100%      = NOT CLAIMED
```

Required proof includes functional behavior, runtime evidence, visual/product parity, security/tenant correctness, cross-feature integration, and no critical unresolved drift/unknowns.

## CURRENT OPEN WORK

```text
P0  Trace current safeText path; patch only if current defect is proven
P0  Trace current AUTH_ID/session lifecycle; patch only if current defect is proven
P1  Login visual + functional parity
P1  Company identity / logo source + tenant rendering
P1  Full master sidebar and navigation
P1  Dashboard product/runtime completeness
P1  Sales product/runtime completeness
P1  No-islands integration audit
P1  Navigation / refresh / re-entry regression
P1  Owner / non-owner runtime authorization proof
P1  Tenant/security proof for touched paths
P1  Fresh Gold gate
P1  Fresh Diamond gate
```

## REPORT RECORD

### Report 35
```text
doc/Draft/Reprots/تقرير35.md
commit = 7cff6ce39c5bab347fb92638ddd029adf12cad36
```

### Report 36
```text
doc/Draft/Reprots/تقرير36.md
commit = 287bcc4d1b73de8843d8466267a78634c5d2995d
```

Report 36 is the current forensic continuity record for this handoff and must not be replaced by a shorter success claim.

## HISTORICAL / PROCESS ERRORS TO REMEMBER

```text
Do not trust report labels as current truth.
Do not replay obsolete target snapshots.
Do not equate function existence with product completion.
Do not equate static pass with runtime pass.
Do not convert owner wildcard into role enumeration.
Do not reconstruct a monolithic target from fragments alone.
Do not treat trigger/marker files as success proof.
Do not fix a verifier instead of the actual target without evidence.
Do not create competing writers or parallel business cores.
```

## OFFLINE SUCCESSOR CANONICAL STARTING STATE

```text
TARGET                       = Current/PWA/New-main
TARGET BLOB                  = 22f4ee1a666141be62127159337beffb05e8b146
LATEST TARGET-AFFECTING SHA  = 282cce040c51b2f4f926a8ca9227ef89ee742713
LATEST CONTINUITY RECORD     = Report 36
LATEST APPLICATION CHANGE    = none after 282cce...
OWNER                        = isOwner=true + permissions=["*"] + active owner profile
MANIFEST                     = ./manifest.json / consistent
SAFEText                     = needs current trace
AUTH_ID                      = needs current trace
GOLD                         = not claimed
DIAMOND                      = not claimed
```

No historical closure label overrides this state.
