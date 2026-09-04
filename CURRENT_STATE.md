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

### Git / Target — DIRECTLY RE-PROVEN

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH     = main
TARGET     = Current/PWA/New-main

LATEST VERIFIED HEAD BEFORE THIS CURRENT_STATE WRITE
= e663e2256b88805d52d1d7d212b5436b1f9e8a0b

CURRENT TARGET BLOB
= 22f4ee1a666141be62127159337beffb05e8b146

LATEST VERIFIED TARGET-AFFECTING COMMIT
= 282cce040c51b2f4f926a8ca9227ef89ee742713
```

Direct Git comparison:

```text
BASE = 282cce...
HEAD = e663e225...
AHEAD = 27
BEHIND = 0
```

The commits after `282cce...` in this reconciliation are documentation/report/continuity changes only. `Current/PWA/New-main` does not appear in the compare file set.

Therefore:

```text
TARGET CHANGED AFTER 282cce...? = NO VERIFIED EVIDENCE
TARGET CONTENT = still blob 22f4ee1a...
```

Git remains the chronology authority. The HEAD value stored here will become stale when the next documentation commit is made.

## LATEST FORENSIC REPORT

```text
= doc/Draft/Reprots/تقرير41.md
COMMIT = 4d12dcce2c4e5eaa247e57c72fb08ef7599d1b69
```

Previous preserved reports:

```text
تقرير40.md
تقرير39.md
تقرير38.md
```

## LATEST LIMITED-ASSISTANT EVIDENCE

```text
= doc/Draft/Reprots/تقرير مساعد جديد محدود
BLOB = 1da9d45a5705eb0bd334d8a943ba67aa4d91e808
```

The limited assistant did not reach New-main EOF, did not perform current Supabase investigation, and did not have Git history/runtime browser tools. Its high-value observations remain useful leads, but its conclusions about missing License UI and dead routes are not current facts.

After direct EOF inspection of New-main:

```text
license route = PRESENT
license renderer contract = PRESENT
8 alleged dead routes = CURRENT ROUTES PRESENT
```

Runtime reachability is still not automatically proven.

## SUCCESSOR DIRECTIVES

Latest limited-assistant successor directive:

```text
= doc/Draft/medhat/MASTER_CTO_NEWM_LIMITED_ASSISTANT_SUCCESSOR_V4_CONTINUATION.md
COMMIT = e663e2256b88805d52d1d7d212b5436b1f9e8a0b
```

Previous canonical directives remain preserved:

```text
MASTER_CTO_NEWM_LIMITED_ASSISTANT_SUCCESSOR_V3.md
MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR_V2.md
MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR.md
MASTER_OFFLINE_CTO_NEW_MAIN_COMPLETION.md
MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md
CTO EXECUTION COMMAND.md
```

## DIRECT CURRENT SOURCE FINDINGS — NEW-MAIN EOF

Current New-main blob `22f4ee1a...` was inspected through its ending sections. The EOF contains:

```text
RAWAEA 122 DIAMOND CONTRACT CLOSURE v1
RAWAEA MAIN1 NOTIFICATION CONTRACT CLOSURE v1
RAWAEA MAIN SIDEBAR COMPLETENESS FINAL V1
```

The current source explicitly contains:

```text
permFor(view)
allowed(view)
nav.navigate(view)
routes{}
```

Owner/license path:

```text
license:'owner'
if(view==='license'||view==='audit') return hasOwner()
license:[window.RW_OwnerLicense,'render']
{view:'license',label:'إدارة الترخيص',perm:'owner'}
```

Current route map also contains handlers for:

```text
branches
users
roles
online-store
purchase-pos
vehicle-count
branch-count
general-count
```

This disproves the limited assistant's claims that these are absent from the current source.

Important distinction:

```text
SOURCE ROUTE EXISTS != RUNTIME ROUTE PROVEN
```

## OWNER / LICENSE — DIRECT PRODUCTION VERIFICATION

Current Supabase schema was inspected before querying values.

Relevant schema facts:

```text
users.status exists
users.permissions exists (jsonb)
users.role_id exists
users.auth_id exists
roles.role_name exists
owner_profile.auth_user_id exists
owner_profile.license_status exists
```

There is no `users.is_active` field in the current schema.

Current owner state:

```text
email = owner@alrawae.com
status = Active
public.users.permissions = ["*"]
role_name = مدير النظام
auth_id = linked
owner_profile linkage = valid
license_status = active
```

Direct Auth verification:

```text
user_metadata.isOwner = true
user_metadata.permissions = ["*"]
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
ACTIVE LICENSE
```

Do not replace wildcard semantics with role-permission enumeration.

## INVESTIGATOR ERRORS RECORDED

Two query-shape mistakes occurred during this cycle/history:

```text
users.is_active  → field does not exist; actual status = users.status
roles.name       → field does not exist; actual name = roles.role_name
```

Both are classified as:

```text
INVESTIGATOR QUERY ERROR
NOT PRODUCTION DEFECT
```

Future rule:

```text
inspect information_schema.columns before querying an uncertain field
```

## SAFE-TEXT / AUTH-ID LEADS

Historical leads remain:

```text
safeText is not defined
AUTH_ID_UNAVAILABLE
```

Current source visibly contains a `window.safeText` definition and an explicit `AUTH_ID_UNAVAILABLE` defensive guard.

Status:

```text
CURRENT DEFECT = NOT PROVEN
TRACE REQUIRED BEFORE PATCH
```

## LOGIN PARITY

Current source:

```text
58px title
88x88 logo
```

Historical richer contract remains documented around:

```text
64px title
120x120 logo
Cairo
glass card
gradient background
feature list
icon-bearing inputs
remember-me
forgot-password
password visibility
```

Status:

```text
PARITY GAP LEAD
NOT YET A PATCH ORDER
```

Prove current requirement/impact before modifying.

## LIMITED-ASSISTANT FINDINGS — RECLASSIFIED

### License Management

```text
Previous claim: missing
Current source: present
Status: DISPROVEN AS CURRENT-SOURCE ABSENCE
Runtime: NOT PROVEN HERE
```

### Eight alleged dead routes

```text
Previous claim: dead
Current route map: handlers present
Status: DISPROVEN AS CURRENT-SOURCE ABSENCE
Runtime: NOT PROVEN HERE
```

### Customers / Suppliers / Branches / Settings / Users / Roles parity

These remain high-value parity leads only.

Each difference must be classified as:

```text
INTENTIONAL SIMPLIFICATION
DELEGATION
MIGRATION
MISSING FEATURE
TRUE REGRESSION
UNKNOWN
```

No blind CRUD restoration.

## MASTER - RAWAEA ERP.md

The requested file:

```text
MASTER - RAWAEA ERP.md
```

was searched in available Library/Conversation material and GitHub repository search but no verifiable copy was found/opened.

Status:

```text
NOT VERIFIED / NOT OPENED
```

Its content must not be invented. Existing validated continuity directives remain the usable substitutes until the exact file is supplied/found.

## ACTIVE PRODUCT MISSION

The product-completion mission remains:

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

New-main remains a client/orchestrator/presentation surface.

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
inventory business-engine redesign
stock posting redesign
reservation-engine redesign
accounting core redesign
ledger core redesign
treasury redesign
unrelated backend redesign
Original files as targets
parallel PWA targets
production business-data experimentation
```

## GOLD / DIAMOND

```text
CURRENT GOLD = NOT PROVEN
CURRENT DIAMOND = NOT PROVEN
CURRENT 100% = NOT PROVEN
```

Historical markers inside New-main are metadata only and do not constitute fresh acceptance evidence.

## REQUIRED NEXT EXECUTION

```text
1. Re-verify current Git HEAD and target blob.
2. Read current continuity artifacts, especially Report 41 and V4.
3. Use New-main EOF evidence to avoid replaying disproven patches.
4. Select the first currently proven blocker.
5. Patch only the smallest safe surface.
6. Verify source + relevant DB contracts.
7. If runtime is available, perform runtime regression.
8. Record exact result.
9. Update CURRENT_STATE again.
10. Continue without asking the owner to choose the next block.
```

## PERMANENT PROCESS RULES

```text
Do not trust CURRENT_STATE for chronology without Git verification.
Do not trust reports as Truth Source.
Do not replay obsolete target snapshots.
Do not equate function existence with product completion.
Do not equate static pass with runtime pass.
Do not use historical Gold/Diamond markers as proof.
Do not use partial reads to assert absence.
Do not create disconnected UI islands.
Do not create parallel business authority in New-main.
Do not replace owner wildcard with role enumeration.
Do not guess schema fields.
Do not use Production business data as a playground.
Do not classify investigator query errors as product defects.
Do not claim GitHub writes that did not occur.
Do not stop merely because the message budget is small.
Do not ask the owner to select an already-defined next block.
Do not claim complete source reading until EOF was reached.
Do not announce Gold/Diamond without fresh evidence.
```

## CHAIN OF CUSTODY

Preserved:

```text
Report 38
Report 39
Report 40
Report 41
Limited Assistant Report
V2 successor
V3 successor
V4 successor
CTO EXECUTION COMMAND
Historical prompts and reports
```

## FINAL CONTINUITY RULE

> The successor inherits evidence trails, not confidence.

> The correct next change is the first currently proven safe blocker — not the loudest historical report.

> If a claim was disproven by the current EOF/source, do not repair it again.
