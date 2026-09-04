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

### Git / Target — RE-PROVEN

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH     = main

LATEST VERIFIED HEAD BEFORE THIS CURRENT_STATE WRITE
= a20497ccb67c37f6f60432ce0d774b2c4f181698

TARGET = Current/PWA/New-main
CURRENT TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
LATEST VERIFIED TARGET-AFFECTING COMMIT
= 282cce040c51b2f4f926a8ca9227ef89ee742713
```

### Chronology finding

Direct Git comparison between `282cce...` and `a20497...` established:

```text
AHEAD = 24 commits
BEHIND = 0
```

The complete compare file list contains documentation, reports, prompts, and continuity records only. `Current/PWA/New-main` is not among the files changed after `282cce...`.

Therefore:

```text
LATEST VERIFIED REPOSITORY HEAD = a20497...
LATEST TARGET-AFFECTING SHA     = 282cce...
TARGET CHANGED AFTER 282cce...? = NO VERIFIED EVIDENCE
```

This stored HEAD will become stale again as soon as the next documentation commit is created; Git must remain the chronology authority.

## LATEST FORENSIC REPORT

```text
= doc/Draft/Reprots/تقرير40.md
```

Previous:

```text
= doc/Draft/Reprots/تقرير39.md
= doc/Draft/Reprots/تقرير38.md
```

Report 40 records the latest Git reconciliation, the limited-assistant failure mode, direct owner/license verification, investigator errors, and the new V3 successor directive.

## SUCCESSOR CTO DIRECTIVE

Current successor directive for constrained-message environments:

```text
= doc/Draft/medhat/MASTER_CTO_NEWM_LIMITED_ASSISTANT_SUCCESSOR_V3.md
COMMIT = f11ec1fd1d84ca91220b44b3fd857a1fb7644613
```

Previous canonical successor directive remains preserved:

```text
= doc/Draft/medhat/MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR_V2.md
COMMIT = b77d9c86f3515c1054e5c404393deb4bcf943f27
```

Other preserved directives:

```text
MASTER_CTO_NEWM_PRODUCT_COMPLETION_SUCCESSOR.md
MASTER_OFFLINE_CTO_NEW_MAIN_COMPLETION.md
MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md
```

Operating model:

```text
GitHub = READ / WRITE only through owner-authorized workflow
Supabase = READ / WRITE when required and justified
```

## LIMITED-ASSISTANT RECONCILIATION

Latest limited-assistant report:

```text
= doc/Draft/Reprots/تقرير مساعد جديد محدود
```

The assistant reached only a partial state. It read V2, CURRENT_STATE, part of New-main, and main1-main4, then stopped because of message/tool limitations.

It reported these high-value leads:

```text
possible dead navigation keys
possible missing License Management UI
historical/current parity regressions in customers, suppliers, branches,
settings, users, roles
```

These remain:

```text
LEADS / NEED CURRENT FULL TRACE
```

They must not be patched blindly.

## CURRENT TARGET — DIRECT EVIDENCE

`Current/PWA/New-main` is a real implementation artifact, not an empty skeleton.

Direct source inspection confirms the current target includes:

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
Owner/license context helpers
Permission wildcard semantics
```

The source still contains historical markers:

```text
P163-GOLD-DIAMOND-CLOSED-2026-09-03
PWA-RUNTIME-GOLD-2026-09-03
```

These are not fresh closure evidence.

Current login source was observed around:

```text
58px title
88x88 logo
```

Historical richer login contract remains:

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

## OWNER / LICENSE — DIRECTLY VERIFIED IN SUPABASE

Current owner identity was rechecked directly:

```text
public.users.permissions = ["*"]
users.status            = Active
Auth user_metadata.isOwner = true
Auth permissions        = ["*"]
owner_profile linkage   = valid
license_status          = active
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

Do not replace `[*]` semantics with role-permission enumeration.

## CURRENT OWNER/LICENSE SOURCE CONTRACT

New-main contains runtime context support for:

```text
RW_ShellContext.isOwner()
RW_ShellContext.getLicenseState()
RW_OwnerLicense.isOwner()
RW_OwnerLicense.permissions()
RW_OwnerLicense.profile()
RW_OwnerLicense.licenseState()
RW_OwnerLicense.isActive()
```

The authoritative login context also reads:

```text
users.auth_id
users.company_id
users.status
users.permissions
owner_profile
app_settings
Auth metadata
```

The source derives owner state from the combined identity/wildcard/owner-profile contract.

This proves the owner/license data contract is active. It does NOT by itself prove that the License Management UI is complete or reachable.

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

A current source read shows `window.safeText` and an explicit `AUTH_ID_UNAVAILABLE` defensive guard. These findings must be traced, not assumed to be current defects.

## QUERY / INVESTIGATOR ERROR LOG

A recent production verification query initially referenced:

```text
users.is_active
```

which does not exist in the current schema. Schema inspection showed:

```text
users.status
```

was the correct status field.

Classification:

```text
INVESTIGATOR QUERY ERROR
NOT PRODUCTION DEFECT
```

## AUTH LOGS — CURRENT EVIDENCE

Recent Auth logs show successful owner password/token authentication events through the deployed frontend origin, alongside expected session refresh/revocation events and some historical invalid/session-not-found requests.

Auth service activity does not alone prove full browser UX or product completeness.

## CURRENT PLATFORM / EDGE CONTEXT

The current Supabase project remains active with a broad Edge Function surface across:

```text
Master data
Sales / Orders
Runsheets
Picking / Loading / Delivery / Return
Inventory vouchers
Purchasing
Accounting / Reporting
Audit
```

The project also contains historical/test/canary/recovery-style functions, including some `verify_jwt=false` functions. Their existence is not automatically a product defect.

## HISTORICAL BUSINESS CONTRACTS

Preserve these until direct current evidence proves a deliberate change:

```text
Vehicle = mobile operating unit / mobile stock container
Representative/Driver = custody/accountability holder

DirectSale    = MAIN → VAN
VanSale       = VAN → Customer
DirectReturn  = VAN → MAIN

Loading       ≠ DirectSale
Unloading     ≠ Customer Return
```

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

New-main must remain a client/orchestrator/presentation surface and must not become a second business core.

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

## GOLD / DIAMOND STATUS

```text
CURRENT GOLD    = NOT PROVEN
CURRENT DIAMOND = NOT PROVEN
CURRENT 100%    = NOT PROVEN
```

Do not use historical markers as proof.

## REQUIRED NEXT EXECUTION SEQUENCE

```text
STAGE 0  Recover continuity
STAGE 1  Re-verify Git HEAD / target chronology
STAGE 2  Verify Supabase / Auth / License / DB contracts
STAGE 3  Read COMPLETE New-main to EOF in chunks
STAGE 4  Re-test limited-assistant findings against full current source
STAGE 5  Read complete historical pack needed by conflict map
STAGE 6  Build Fact / Claim / Unknown / Conflict matrix
STAGE 7  Trace safeText
STAGE 8  Trace AUTH_ID
STAGE 9  Company / Logo
STAGE 10 Login
STAGE 11 Shell / Navigation
STAGE 12 License Management UI/backend reachability
STAGE 13 Dashboard
STAGE 14 Sales Management
STAGE 15 No-islands integration
STAGE 16 Owner/non-owner authorization
STAGE 17 Tenant/security
STAGE 18 Runtime regression
STAGE 19 Fresh Gold
STAGE 20 Fresh Diamond
STAGE 21 Final report
STAGE 22 CURRENT_STATE update
```

### Critical sequencing rule

The next assistant must not begin by repairing the License tab merely because the limited report mentioned it.

The first repair must be selected from the first **currently proven** blocking defect after the complete New-main trace.

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
Do not treat an empty CI status response as passing CI.
Do not claim GitHub commits or deployment that did not occur.
Do not stop simply because message budget is small.
Do not ask the owner to choose the next block when the execution sequence is already defined.
Do not claim a source was read completely until EOF was reached.
```

## CHAIN OF CUSTODY

The following artifacts were preserved and not deleted:

```text
Report 38
Report 39
Report 40
Limited assistant report
V2 successor prompt
V3 limited-assistant successor prompt
Historical prompts
```

## FINAL CONTINUITY RULE

> The project is not complete when the functions exist. It is complete when the living product is proven as an integrated system.

> The successor inherits evidence trails, not confidence. Every important claim must be reproduced from the highest available source before it becomes a fact.

