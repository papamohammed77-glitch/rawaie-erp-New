# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE

- Direct Production/runtime/database evidence outranks reports, prompts, memory, and closure labels.
- `Current/PWA/New-main` is the sole application target for the current product-completion track.
- `Original/PWA/*` is historical reference/contract material and must not be modified or used as a competing deployment target.
- Reports are preserved as evidence/history; they are not current Truth Source.
- Function existence is not product completion.
- Static verification is not runtime verification.
- Historical Gold/Diamond markers are not fresh Gold/Diamond proof.
- No new business authority may be created in the PWA; New-main remains a client/orchestrator over authoritative backend/core contracts.

## CURRENT RECONCILIATION — 2026-09-04

### Git / Target

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH     = main

HEAD VERIFIED IMMEDIATELY BEFORE THIS CURRENT_STATE WRITE
= 3b9b752e5fe046599d132e102e00c68bddc9d813

TARGET = Current/PWA/New-main
CURRENT TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
LATEST TARGET-AFFECTING COMMIT = 282cce040c51b2f4f926a8ca9227ef89ee742713
```

### Important chronology finding

`282cce...` remains the latest direct application target change. Its direct target diff is only:

```diff
-<!-- 2026-09-03 18:00 UTC -->
+<!-- 2026-09-03 22:00 UTC -->
```

Later commits are continuity/documentation work. The latest repository commits in the current chain are:

```text
3b9b752e5fe046599d132e102e00c68bddc9d813
[CTO] Add Report 38 — forensic recovery and successor CTO directive

705f7730f11cc87319b8be7d6abefe0a5c1e6c09
[CTO] Add unified New-main successor CTO Gold/Diamond directive

8170de8b147f59035461db7f5da283992a4276e7
[CTO] Finalize CURRENT_STATE after offline CTO directive

838a5268273c74e3a955edc5a7d4cadfb42d71f3
[CTO] Add master offline CTO New-main completion directive

77e6d39067cbbc30f238190c7cb24bef7c642d3f
[CTO] Correct CURRENT_STATE to final Report 37 reconciliation HEAD

10e0395339263a09c69b9cf00c1485421144746e
[CTO] Reconcile CURRENT_STATE with Report 37 forensic handoff

cc26dd7d78862e7ae442edfca136c7dda44c7438
[CTO] Add Report 37 — forensic reconciliation and offline successor mission
```

The current-state file was previously behind its own latest documentation commit. Therefore future CTOs must always re-prove Git HEAD directly rather than trusting the HEAD value stored in this file.

## REPORTS / CONTINUITY

```text
LATEST FORENSIC REPORT
= doc/Draft/Reprots/تقرير38.md

PREVIOUS FORENSIC STATION
= doc/Draft/Reprots/تقرير37.md
```

Report 38 records the latest forensic reconciliation, the CURRENT_STATE/Git chronology discrepancy, owner/license verification, current New-main evidence, and the new successor CTO directive.

## SUCCESSOR CTO DIRECTIVE

```text
TARGET DIRECTIVE
= doc/Draft/medhat/MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR.md
COMMIT
= 705f7730f11cc87319b8be7d6abefe0a5c1e6c09
```

This is the canonical directive for a successor CTO that has:

```text
GitHub = READ ONLY
Supabase = READ / WRITE
GitHub commit/write = OWNER ONLY
```

The existing offline directive remains preserved:

```text
doc/Draft/medhat/MASTER_OFFLINE_CTO_NEW_MAIN_COMPLETION.md
COMMIT = 838a5268273c74e3a955edc5a7d4cadfb42d71f3
```

The new directive supersedes the offline execution model for this successor role but does not delete or invalidate the offline directive.

## CURRENT TARGET — DIRECT EVIDENCE

`Current/PWA/New-main` is a real complete HTML artifact, not an empty skeleton. It currently includes implementation for:

```text
Login
Application shell
Sidebar / header / navigation
Dashboard/data logic
Customers paths
Items/stock paths
Suppliers paths
Owner-sensitive audit path
Company-scoped reads
```

Current file begins with:

```html
<!doctype html>
<!-- 2026-09-03 22:00 UTC -->
<html lang="ar" dir="rtl">
```

It references:

```html
<link rel="manifest" href="./manifest.json">
```

The file contains historical meta markers such as P163 Gold/Diamond markers. These are historical metadata only and are not accepted as fresh closure evidence.

## MANIFEST — PREVIOUSLY CLOSED

```text
Current/PWA/manifest.json
start_url = ./New-main
scope     = ./
dir       = rtl
lang      = ar
icons     = 3
```

Do not reopen the old manifest issue without new direct evidence.

## OWNER / LICENSE — VERIFIED

Fresh Supabase evidence confirms:

```text
public.users.permissions = ["*"]
public wildcard          = true
Auth isOwner             = true
Auth permissions         = ["*"]
owner_profile linkage    = valid
license_status           = active
```

Canonical owner contract:

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

Do not replace the wildcard owner contract with role-permission enumeration.

A prior verification query incorrectly treated JSONB permissions as PostgreSQL `text[]`; that was corrected successfully. It is an investigator/query-type error, not a production defect.

## HISTORICAL RUNTIME LEADS

```text
safeText is not defined
AUTH_ID_UNAVAILABLE
```

Current status:

```text
LEADS ONLY
CURRENT TRACE REQUIRED
NO BLIND HISTORICAL PATCH
```

No fresh Chromium runtime proof was obtained in this continuity cycle.

## HISTORICAL UX CONTRACT

`Original/PWA/main/main1.md` established a richer Login contract including:

```text
Cairo
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

Current `New-main` contains many of these concepts but visual parity is not yet proven. Current source was observed with values including approximately:

```text
58px title
88x88 logo
```

Therefore Login visual/product parity remains open.

The historical directory contains:

```text
main1.md ... main11.md
```

`main1` alone is insufficient for safe reconstruction.

## ACTIVE PRODUCT MISSION

The current target is not an Inventory rebuild.

The active product-completion scope is:

```text
A — Company information / identity / logo
B — Login visual + functional parity
C — Full master sidebar / header / navigation
D — Dashboard
E — Sales Management
F — No-islands integration
G — Navigation / refresh / re-entry regression
H — Owner / non-owner authorization proof
I — Tenant / security proof
J — Fresh Gold gate
K — Fresh Diamond gate
```

Completion means:

```text
STRUCTURE
+
VISUAL IDENTITY
+
FUNCTIONAL CAPABILITY
+
RUNTIME INTEGRITY
+
BUSINESS SEMANTICS
+
AUTHORIZATION
+
TENANCY
+
INTEGRATION
+
PRODUCT EXPERIENCE
```

## AUTHORIZED TARGET MODIFICATION SURFACE

### Block A — Login / Company / Logo

```text
<style> sections for .rw-login-* and .rw-company-*
<div id="rw-login-page"> ... </div>
```

### Block B — Master Shell / Sidebar / Header

```text
<div id="rw-main-shell">
<aside id="rw-sidebar">
<header id="rw-header">
#rw-page-container
```

### Block C — Auth / Session / Company Context

Only existing code for:

```text
session acquisition
current user
isOwner
permissions
company context
company identity
logo source
```

### Block D — Dashboard

Existing Dashboard renderer and direct data/presentation wiring only.

### Block E — Sales Management

Existing Sales surface and direct client orchestration/navigation wiring only.

## OUT OF SCOPE UNLESS A BLOCKING DEPENDENCY IS PROVEN

```text
inventory business engine redesign
stock posting redesign
reservation engine redesign
accounting core redesign
ledger core redesign
treasury redesign
unrelated purchasing internals
unrelated delivery backend redesign
Original files as targets
parallel application targets
production business-data experimentation
```

## NO-ISLANDS CONSTITUTION

```text
RAWAEA MASTER SYSTEM
        ↓
CENTRAL BUSINESS HEART
        ↓
DOMAIN ENGINES
        ↓
OPERATING APPLICATIONS
```

New-main is a client/orchestrator.

It must not become a second business core or duplicate authoritative stock/accounting/ledger behavior.

Every restored feature must answer:

```text
Who owns it?
Who opens it?
What state feeds it?
What backend contract feeds it?
What happens after the action?
What happens on refresh?
What happens on re-entry?
Who consumes the result?
How is authorization enforced?
How is tenant scope enforced?
```

## HISTORICAL BUSINESS TRAPS TO REMEMBER

```text
Vehicle = mobile operating unit / mobile stock container
Representative/Driver = custody/accountability holder

DirectSale = MAIN → VAN
VanSale    = VAN → Customer
DirectReturn = VAN → MAIN

Loading ≠ DirectSale
Unloading ≠ Customer Return
```

Do not reopen these historical contracts unless current evidence contradicts them.

## SUCCESSOR CTO PACKET

The successor should receive:

```text
1. Current/PWA/New-main — FULL CONTENT
2. Original/PWA/main.html — FULL CONTENT
3. Original/PWA/core.js — FULL CONTENT
4. Original/PWA/main/main1.md ... main11.md — COMPLETE PACK
5. Original/PWA/sales/order-taker.html
6. Original/PWA/sales/pos.html
7. Original/PWA/sales/sales.manager.html
8. Original/PWA/sales/sales.supervisor.html
9. Original/PWA/sales/telesales.html
10. Original/PWA/sales/van-sales.html
```

Useful optional runtime references:

```text
Original/PWA/manifest.json
Original/PWA/register-sw.js
```

Preserve exact source-path headers inside concatenated packs.

## NEXT EXECUTION SEQUENCE

```text
STAGE 0  Current-state / handoff reconciliation
STAGE 1  Git forensic verification
STAGE 2  Supabase / Auth / License forensic verification
STAGE 3  Full New-main reading
STAGE 4  Full historical reference reading
STAGE 5  Fact / Claim / Inference / Unknown / Conflict map
STAGE 6  Trace safeText and AUTH_ID
STAGE 7  Company / Logo
STAGE 8  Login
STAGE 9  Master Shell / Sidebar / Header
STAGE 10 Navigation
STAGE 11 Dashboard
STAGE 12 Sales Management
STAGE 13 No-islands integration
STAGE 14 Owner / non-owner proof
STAGE 15 Tenant / security proof
STAGE 16 Runtime regression
STAGE 17 Fresh Gold gate
STAGE 18 Fresh Diamond gate
STAGE 19 Final patch package / handoff
```

No material UNKNOWN or unresolved CONFLICT in the active scope permits a Gold/Diamond claim.

## CURRENT STATUS

```text
CURRENT GOLD    = NOT PROVEN
CURRENT DIAMOND = NOT PROVEN
CURRENT 100%    = NOT PROVEN
```

Open items:

```text
safeText current trace
AUTH_ID current trace
Login parity
Company / logo product closure
Master navigation completeness
Dashboard product closure
Sales product closure
No-islands proof
Owner/non-owner runtime proof
Tenant/security proof
Fresh runtime regression proof
Fresh Gold gate
Fresh Diamond gate
```

## PROCESS ERRORS TO PRESERVE

```text
Do not trust CURRENT_STATE for HEAD without Git verification.
Do not trust report closure labels as current truth.
Do not replay obsolete target snapshots.
Do not equate function existence with product completion.
Do not equate static pass with runtime proof.
Do not convert owner wildcard into role enumeration.
Do not use main1 alone for reconstruction.
Do not create disconnected UI islands.
Do not create parallel business authority in New-main.
Do not guess schema, field, permission, company, or runtime behavior.
Do not mutate Production business data for convenience.
Do not claim Gold/Diamond from markers.
Do not claim runtime verification without runtime evidence.
```

## CONTINUITY RULE

This file is a navigation aid and reconciled index. It must be refreshed after meaningful continuity milestones, but every future CTO must still verify current Git and Production evidence directly.

The latest application target remains unchanged after `282cce...` unless direct Git evidence proves otherwise.
