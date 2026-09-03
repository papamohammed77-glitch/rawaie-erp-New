# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Direct runtime / production / Git evidence outranks historical reports.
- `Current/PWA/New-main` is the only authorized application target for this closure track.
- `Current/PWA/main.html` and `Original/PWA/main/*` are references, not alternative publish targets.
- Fragment-only reconstruction is forbidden as persistence authority.
- Production Supabase business-data writes remain forbidden in this closure track.
- Historical reports are preserved; this file is the reconciled current-state index.

## HISTORICAL CLOSURE RECORD — PRESERVED
Earlier closure evidence proved a trusted artifact and earlier Gold/Diamond state around blob `f26581b58f101671f96bdc23c58867b985182955` and commit `2c02361ba01f37839a6fb4ad0f44c9eac60ef44a`. That historical closure is not silently promoted to current truth.

The historical regression/reconstruction incidents, verifier failures, competing writer discovery, P163, MAIN2 governance, Diamond 122 and earlier closure evidence remain preserved in Git history and the reports under `doc/Draft/Reprots/`.

## CURRENT AUTHORITATIVE RECONCILIATION — 2026-09-03

### Current Git
```text
REPOSITORY          = papamohammed77-glitch/rawaie-erp-New
BRANCH              = main
CURRENT HEAD        = 7cff6ce39c5bab347fb92638ddd029adf12cad36
TARGET              = Current/PWA/New-main
CURRENT TARGET BLOB = 22f4ee1a666141be62127159337beffb05e8b146
```

The current HEAD is documentation/continuity work following the latest target-affecting line. The most recent target-affecting commit inspected remains:

```text
282cce040c51b2f4f926a8ca9227ef89ee742713
Update New-main
```

Its direct target diff changed only the embedded timestamp comment from `18:00 UTC` to `22:00 UTC`.

A materially earlier post-Report-33 target commit was:

```text
9f329ff876bd622df9272bb355976c835721a8c8
[CTO] Restore verified New-main blob on current main
```

That commit DID modify the application target, including Login/Logo DOM surface and print/UX code. Therefore Report 33 is historical evidence, not the current target snapshot.

## CURRENT TARGET DIRECT EVIDENCE

`Current/PWA/New-main` was fetched directly and is a complete HTML artifact beginning with:

```html
<!doctype html>
<html lang="ar" dir="rtl">
<link rel="manifest" href="./manifest.json">
```

Its current opening surface includes the Login layout and current dependencies. It is not a three-line fragment or an automatically reconstructed placeholder.

## CURRENT PWA MANIFEST RECONCILIATION

Current target:
```text
manifest href = ./manifest.json
```

Current manifest:
```text
Current/PWA/manifest.json
start_url = ./New-main
scope     = ./
dir       = rtl
lang      = ar
icons     = 3
```

Current manifest SHA:
```text
f2f52998fd04094905f09afa9fbcb64b2bd38190
```

Therefore:
```text
OLD MANIFEST DISCREPANCY = RESOLVED IN CURRENT SOURCE
```

Do not reopen this issue unless new direct evidence appears.

## OWNER / LICENSE CONTRACT — VERIFIED AGAIN 2026-09-03

Fresh direct Supabase verification was performed against project `fiilmooggumokxanwiyx` for `owner@alrawae.com`.

Verified result:

```text
public.users.permissions = ["*"]
public wildcard           = true
Auth isOwner              = true
Auth permissions         = ["*"]
owner_profile linkage    = valid
license_status           = active
```

The correct semantic contract is:

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

### Investigation note
The first verification SQL used an incompatible `text[]` operator against a `jsonb` permissions value and failed. The query was corrected and the direct verification succeeded. This is recorded as an investigator/query-type error, not a production defect.

## REPORT 33 RUNTIME INCIDENT — RECLASSIFIED

Report 33 recorded:

```text
safeText is not defined
AUTH_ID_UNAVAILABLE
```

At that historical snapshot the fresh runtime gate was:

```text
STATIC = PASS
CHROMIUM = FAIL
```

However, the target changed after Report 33. Therefore both incidents remain:

```text
CARRIED-FORWARD INCIDENT LEADS
```

They must be traced against the current `New-main` source before any patch is attempted.

## HISTORICAL UX CONTRACT

`Original/PWA/main/main1.md` was directly inspected. It proves a richer Login visual contract including:

```text
Cairo
Tailwind
64px login title
120x120 logo
large glass login card
gradient brand background
feature list
icon-bearing inputs
remember-me
forgot-password
password visibility
```

`Original/PWA/main/` contains all eleven historical contract fragments `main1.md ... main11.md`.

## CURRENT PRODUCT COMPLETION OBJECTIVE

The next CTO must not confuse:

```text
FUNCTIONS EXIST
```

with:

```text
PRODUCT IS COMPLETE
```

Completion requires, for the scoped capabilities:

```text
STRUCTURE
+ VISUAL IDENTITY
+ FUNCTIONAL CAPABILITY
+ RUNTIME INTEGRITY
+ BUSINESS SEMANTICS
+ SECURITY / TENANCY
+ PRODUCT EXPERIENCE
```

The immediate product scope is:

```text
Company information / Logo
Login screen visual + functional parity
Full master sidebar
Dashboard
Sales management
```

The architecture must remain ready for the remaining tabs without creating islands.

## OFFLINE SUCCESSOR HANDOFF — V6

The successor CTO has no external access. The canonical offline directive is now:

```text
doc/Draft/medhat/MASTER_CTO_OFFLINE_CONTINUITY_GOLD_DIAMOND_V6.md
```

Commit:
```text
1ba30f011d1d79b6430d7e190a3e8ba09cdf16f9
```

V6 strengthens V5 with:

```text
packet receipt ledger
no-analysis-before-complete-packet gate
offline evidence hierarchy
current/history/conflict/unknown classification
exact target-only application law
central-core/no-islands rules
Login/Company/Logo contract
Master Sidebar contract
Dashboard contract
Sales contract
full-file replacement / exact-patch output discipline
verification pyramid
Gold / Diamond gates
successor handoff protocol
```

V5 remains preserved unchanged.

## REPORT 35

Created and preserved:

```text
doc/Draft/Reprots/تقرير35.md
```

Commit:
```text
7cff6ce39c5bab347fb92638ddd029adf12cad36
```

Report 35 records:

```text
latest Git continuity audit
current target identity
Post-Report-33 target drift
fresh Owner/License verification
V5 review
CTO EXECUTION COMMAND review
historical UX findings
investigation query error
optimized five-file offline handoff
creation of V6
honest open-work state
```

## OPTIMIZED FIVE-FILE OFFLINE PACKET

For the successor with a 4–5 file limit, use these five logical attachments:

```text
1. Current/PWA/New-main — FULL CONTENT
2. Original/PWA/main.html — FULL CONTENT
3. Original/PWA/core.js — FULL CONTENT
4. One concatenated text pack containing Original/PWA/main/main1.md ... main11.md
5. One concatenated text pack containing every complete file under Original/PWA/sales/
```

For each concatenated pack preserve exact source path headers.

Future domain packets:

```text
Original/PWA/purchasing/
Original/PWA/delivery/
Original/PWA/office/
```

## DO-NOT-REOPEN ITEMS

Unless new direct evidence appears:

```text
Old manifest discrepancy
Historical Report-33 target hash as current
Owner role enumeration as owner proof
Historical safeText repair without current trace
Historical AUTH_ID repair without current trace
Historical Gold/Diamond labels
```

## CURRENT OPEN WORK

```text
P0  Re-audit current New-main runtime for carried-forward safeText incident
P0  Re-audit current New-main auth/identity lifecycle for carried-forward AUTH_ID incident
P1  Login visual + functional parity
P1  Company identity / logo source + tenant rendering
P1  Full master sidebar behavior and navigation
P1  Dashboard real functionality
P1  Sales functional completeness
P1  Integration / no-islands audit
P1  Full navigation / refresh / re-entry regression
P1  Owner / non-owner authorization runtime proof
P1  Tenant / security / RLS verification relevant to repaired paths
P1  Fresh Gold gate
P1  Fresh Diamond gate
```

## CURRENT STATUS — HONEST

```text
CURRENT TARGET                 = 22f4ee1a666141be62127159337beffb05e8b146
TARGET TYPE                    = COMPLETE HTML ARTIFACT
MANIFEST                      = CURRENT / CONSISTENT
OWNER WILDCARD                = PROVEN AGAIN
OWNER LICENSE                = ACTIVE / PROVEN AGAIN
REPORT 33 TARGET              = HISTORICAL, NOT CURRENT
SAFEText CURRENT STATUS       = NEEDS RE-AUDIT
AUTH_ID CURRENT STATUS        = NEEDS RE-AUDIT
LOGIN PARITY                  = OPEN
COMPANY / LOGO                = OPEN
SIDEBAR                       = OPEN
DASHBOARD                     = OPEN
SALES                         = OPEN
CURRENT FRESH CHROMIUM        = NOT RUN IN THIS CONTINUITY UPDATE
CURRENT GOLD                  = NOT CLAIMED
CURRENT DIAMOND               = NOT CLAIMED
CURRENT 100% CLOSURE          = NOT CLAIMED
```

## NEXT AUTHORIZED ACTION

The successor CTO must start from this reconciled state, receive and fully read the optimized five-file packet, then execute:

```text
AUDIT CURRENT TARGET
→ TRACE safeText
→ TRACE AUTH_ID
→ VERIFY THEY STILL EXIST AS DEFECTS
→ CLOSE OR PATCH ONLY WHEN PROVEN
→ LOGIN / COMPANY / LOGO
→ MASTER SIDEBAR
→ DASHBOARD
→ SALES
→ NO-ISLANDS
→ REGRESSION
→ GOLD
→ DIAMOND
```

No historical closure label overrides this current-state contract.
