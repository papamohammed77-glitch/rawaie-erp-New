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

LATEST VERIFIED HEAD BEFORE THIS CURRENT_STATE WRITE
= 7ec0b26f8b99f67fef9bad48b3568a2946c7b001

TARGET = Current/PWA/New-main
CURRENT TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
LATEST VERIFIED TARGET-AFFECTING COMMIT
= 282cce040c51b2f4f926a8ca9227ef89ee742713
```

### Chronology finding

Direct Git comparison between `282cce...` and the latest observed pre-write HEAD established an 18-commit continuity/documentation tail after the target commit. No verified later modification to `Current/PWA/New-main` was found in that chain.

Therefore:

```text
LATEST OBSERVED REPOSITORY HEAD = 7ec0b26...
LATEST TARGET-AFFECTING SHA     = 282cce...
TARGET CHANGED AFTER 282cce...? = NO VERIFIED EVIDENCE
```

As always, this stored HEAD is a handoff snapshot and must be re-proven from Git by the next CTO because this CURRENT_STATE write itself creates another documentation commit.

## LATEST FORENSIC REPORT

```text
= doc/Draft/Reprots/تقرير39.md
```

Previous:

```text
= doc/Draft/Reprots/تقرير38.md
```

Report 39 corrects the stale-head situation after Report 38, records the latest Git/Supabase reconciliation, and establishes the successor V2 prompt.

## SUCCESSOR CTO DIRECTIVE

Canonical successor directive:

```text
= doc/Draft/medhat/MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR_V2.md
COMMIT = b77d9c86f3515c1054e5c404393deb4bcf943f27
```

Operating model:

```text
GitHub = READ ONLY
Supabase = READ / WRITE
GitHub commit/write = OWNER ONLY
```

The previous directives remain preserved:

```text
MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR.md
MASTER_OFFLINE_CTO_NEW_MAIN_COMPLETION.md
MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md
```

## CURRENT TARGET — DIRECT EVIDENCE

`Current/PWA/New-main` is a real implementation artifact, not an empty skeleton.

It currently contains evidence of:

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
Manifest reference
Service-worker coordinator reference
```

Historical meta markers remain inside the file, but are not fresh closure evidence:

```text
P163-GOLD-DIAMOND-CLOSED-2026-09-03
PWA-RUNTIME-GOLD-2026-09-03
```

## OWNER / LICENSE — VERIFIED

Fresh Supabase evidence confirms:

```text
public.users.permissions = ["*"]
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

The License Management visibility path is tied to `currentUser.isOwner === true` and must not be replaced by role-permission enumeration.

## MANIFEST — PREVIOUSLY CLOSED

```text
Current/PWA/manifest.json
start_url = ./New-main
scope     = ./
dir       = rtl
lang      = ar
icons     = 3
```

Do not reopen this issue without new direct evidence.

## HISTORICAL RUNTIME LEADS

```text
safeText is not defined
AUTH_ID_UNAVAILABLE
```

Current status:

```text
LEAD ONLY
CURRENT TRACE REQUIRED
NO BLIND PATCH
```

## HISTORICAL LOGIN CONTRACT

The richer historical Login contract includes:

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

Current source was observed around:

```text
58px title
88x88 logo
```

Therefore Login visual/product parity remains open until fresh evidence proves closure.

The historical directory contains `main1.md ... main11.md`; `main1` alone is insufficient for reconstruction.

## ACTIVE PRODUCT MISSION

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

New-main remains a client/orchestrator/presentation surface. It must not become a second business core.

Every restored feature must answer:

```text
Who owns it?
Who opens it?
What state feeds it?
What backend contract feeds it?
What happens after action?
What happens after refresh?
What happens on re-entry?
Who consumes the result?
How is authorization enforced?
How is tenant scope enforced?
```

## OUT OF SCOPE UNLESS BLOCKING DEPENDENCY IS PROVEN

```text
inventory business engine redesign
stock posting redesign
reservation engine redesign
accounting core redesign
ledger core redesign
treasury redesign
unrelated backend redesign
Original files as targets
parallel PWA targets
production business-data experimentation
```

## HISTORICAL BUSINESS CONTRACTS

Do not reverse these historical semantics without current evidence:

```text
Vehicle = mobile operating unit / mobile stock container
Representative/Driver = custody/accountability holder

DirectSale    = MAIN → VAN
VanSale       = VAN → Customer
DirectReturn  = VAN → MAIN

Loading       ≠ DirectSale
Unloading     ≠ Customer Return
```

## LATEST CONTINUITY RISKS

From the latest direct cross-system review:

```text
SECURITY DEFINER public execution concerns
leaked-password protection disabled
repeated 410 calls to owner-recovery-20260818
some verify_jwt=false historical/test/recovery-style functions
empty CI status result is not a passing CI result
FK / RLS / permissive-policy / unused-index findings
```

These are evidence-backed platform risks, not automatically New-main defects.

## CURRENT STATUS

```text
CURRENT GOLD    = NOT PROVEN
CURRENT DIAMOND = NOT PROVEN
CURRENT 100%    = NOT PROVEN
```

Open product items:

```text
safeText current trace
AUTH_ID current trace
Login parity
Company / logo closure
Master navigation completeness
Dashboard closure
Sales closure
No-islands proof
Owner/non-owner runtime proof
Tenant/security proof
Fresh runtime regression proof
Fresh Gold gate
Fresh Diamond gate
```

## PERMANENT PROCESS ERRORS TO AVOID

```text
Do not trust CURRENT_STATE for HEAD without Git verification.
Do not trust reports as Truth Source.
Do not replay obsolete target snapshots.
Do not equate function existence with product completion.
Do not equate static pass with runtime proof.
Do not use historical Gold/Diamond markers as proof.
Do not use main1 alone for reconstruction.
Do not create disconnected UI islands.
Do not create parallel business authority in New-main.
Do not replace owner wildcard with role enumeration.
Do not guess schema/fields/IDs/company/permissions/runtime behavior.
Do not use Production business data as a playground.
Do not classify tool/query mistakes as production defects.
Do not treat an empty CI status result as passing CI.
Do not claim GitHub commits or deployment that did not occur.
```

## NEXT EXECUTION SEQUENCE

```text
STAGE 0  Recover continuity
STAGE 1  Verify Git HEAD / target chronology
STAGE 2  Verify Supabase / Auth / License / DB contracts
STAGE 3  Read full New-main
STAGE 4  Read complete historical pack
STAGE 5  Build fact/claim/unknown/conflict map
STAGE 6  Trace safeText
STAGE 7  Trace AUTH_ID
STAGE 8  Company / Logo
STAGE 9  Login
STAGE 10 Shell / Sidebar / Header
STAGE 11 Navigation
STAGE 12 Dashboard
STAGE 13 Sales Management
STAGE 14 No-islands integration
STAGE 15 Owner/non-owner authorization
STAGE 16 Tenant/security
STAGE 17 Runtime regression
STAGE 18 Fresh Gold gate
STAGE 19 Fresh Diamond gate
STAGE 20 Final report
STAGE 21 CURRENT_STATE update
STAGE 22 Exact owner handoff
```

No material UNKNOWN or unresolved blocking CONFLICT in active scope permits closure.

## SUCCESSOR SOURCE RULE

The V2 successor prompt is the current operational constitution, but it does not replace direct evidence. Every successor must re-open the sources and re-prove the relevant facts.

## SECURITY

Never store or reproduce secrets, private keys, access tokens, service-role keys, passwords, or credentials in this file.
