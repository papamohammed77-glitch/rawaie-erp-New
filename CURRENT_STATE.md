# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth is established from direct Git, direct Production evidence, deployment/runtime evidence when available, and verified artifacts.
- Historical reports are evidence of what was done; they are not current truth by themselves.
- `Current/PWA/New-main` is the current authorized target for the ongoing PWA reconstruction track.
- `Current/PWA/main.html` is a separate protected artifact; never substitute it for `New-main` by filename similarity.
- Historical reports are sacred: do not delete or overwrite them.
- `UNKNOWN ≠ BUG`, `UNKNOWN ≠ REMOVE`.
- `Git/source verified ≠ runtime verified` and `runtime verified ≠ Production data repair`.
- Governing loop: CURRENT_STATE → LAST VERIFIED EVENT → CURRENT GIT → CURRENT PRODUCTION → DEPLOYMENTS/RUNTIME → RECONCILE → SURGICAL CHANGE → VERIFY → CURRENT_STATE.

## HISTORICAL CONTINUITY
- P133–P151: authentication, deployment, Service Worker, compatibility-route, and update-coordinator reconstruction/closures as historically recorded.
- P152–P154: auth/deployment reconciliation and separate `main.html` comparison track.
- P155 / `تقرير16.md`: first direct forensic comparison of `Original/PWA/main/main1.md` vs `Current/PWA/New-main`.
- P156 / `تقرير17.md`: corrected main1 comparison and earlier surgical findings.
- P157 / `تقرير18.md`: owner-side New-main correction verified with CSS initially misplaced in body.
- P158 / `تقرير19.md`: CSS relocation verified, but one missing HTML closing tag was then present.
- P159 / `تقرير20.md`: direct comparison of `Original/PWA/main/main2.md` vs `Current/PWA/New-main`; reported Main2 runtime shadowing.
- P160 / `تقرير21.md`: revalidated the same current New-main source and corrected the P159 interpretation. Full Main2 source capability loss remained 0 proven, but Current contained duplicate `RW_Dashboard` and duplicate `RW_Items` definitions, a legacy Main1 compatibility router/alias surface, incomplete compatibility stubs, and later Main3 routing.
- P161 / `تقرير22.md`: repeated the comparison from direct source after checking the post-P160 Git history. Confirmed that later Sep-02 `New-main` commits did not remove the Main2 capability set. Main2 functional feature loss remains 0 proven. The remaining issue is ownership/routing debt, not missing Main2 functionality.

## CURRENT SOURCE IDENTITIES
```text
Original/PWA/main/main2.md
SHA = 45d5e760a4b53e3be574346e3d9d192dbad309af

Current/PWA/New-main
Latest commit = da5af424360239c0571bf9c118871a635b96f8de
Commit message = Update New-main
Commit UTC = 2026-09-02T04:40:53Z
Current blob = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
File header timestamp = 2026-09-02 05:20 UTC
```

Latest-source note: Git history after P160 included `70aaad76c53b6d8fae045e5868938e718b30ee13`, `c3871ef49e5ed40c550f23359d75c1e380093dbd`, and the final `da5af424360239c0571bf9c118871a635b96f8de`. The latest `da5af...` commit added the missing password form-group closing `</div>` before `rw-login-options`; it did not remove the Main2 duplicate/authoritative module structure.

## LAST VERIFIED EVENT
```text
EVENT ID        = P161-MAIN2-FUNCTIONAL-GAP
EVENT TYPE      = Direct source gap analysis + continuity recovery
DATE            = 2026-09-02
SOURCE          = MASTER + CURRENT_STATE + Reports14-21 + Original main2 + Current New-main + Git history
GIT SHA         = da5af424360239c0571bf9c118871a635b96f8de
TARGET BLOB     = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
RESULT          = Main2 functional capability loss = 0 proven. RW_Dashboard/RW_Items duplicate ownership, Main1 legacy routing residue, compatibility false-capability stubs, and later Main3 routing remain present. Final live runtime winner remains unproven.
TARGET CODE EDITED BY ASSISTANT = NO
PRODUCTION DATA EDITED THIS ROUND = NO
REPORT         = doc/Draft/Reprots/تقرير22.md
REPORT COMMIT  = 32a9f9400159aea30aba13694df18cdf652ef02c
```

## MAIN2 FORENSIC STATUS
### Scope fact
`Original/PWA/main/main2.md` is not a full ERP snapshot. It contains the historical `RW_Dashboard` and `RW_Items` modules.

### Proven source parity
```text
RW_Dashboard full capability set = PRESENT in New-main
RW_Items full capability set     = PRESENT in New-main
Main2 source function loss       = 0 proven
```

### Direct source evidence
- `Original/PWA/main/main2.md` opens directly with the historical `RW_Dashboard` implementation.
- `Current/PWA/New-main` contains a `MAIN2 COMPATIBILITY` surface followed by a real `RW_Dashboard` implementation, and later contains another `RW_Dashboard` / `RW_Items` implementation set.
- The later `RW_Items` implementation contains real stock loading, filtering, matrix, movement, category, export, and upload responsibilities; therefore the presence of the earlier stub copy must not be interpreted as Main2 feature loss.

### Current duplicate ownership defects
```text
RW_Dashboard definitions = 2
RW_Items definitions     = 2
```

The first pair is under `MAIN2 COMPATIBILITY`; the later pair is the stronger authoritative implementation.

### Legacy compatibility defects
The compatibility `RW_Items` copy exposes false-capability/stub surfaces for functions including:
```text
_openCategoryModal
_addCategory
_editCategory
_deleteCategory
_executeDeleteCategory
_exportMatrixToExcel
_handleFileSelect
_executeUpload
```
These are duplicate/legacy residue, not proof of missing Main2 functionality.

### Navigation ownership status
A legacy Main1 compatibility surface remains, including:
```text
window.RW_Dashboard={render:renderDashboard}
window.RW_Items={render:renderItems}
```
A later Main3 route surface also resolves through:
```text
window.RW_Dashboard
window.RW_Items
```
Therefore final runtime ownership is not proven from source order alone.

## P161 FINAL DECISION FOR MAIN2 QUESTION
```text
MAIN2 FUNCTIONAL FEATURE LOSS = 0 PROVEN
MAIN2 WHOLE-FILE REPLACEMENT  = REJECTED
MAIN2 RE-INTEGRATION           = NOT REQUIRED
MAIN2 FEATURE REWRITE          = NOT REQUIRED

OWNERSHIP / ROUTING CLEANUP    = OPEN
SERVED ARTIFACT VERIFICATION   = OPEN
BROWSER RUNTIME VERIFICATION   = OPEN
```

## AUTHORIZED NEXT STATE
The next technical work for this PWA comparison track is NOT adding Main2 features. It is surgical ownership cleanup:
```text
TRACE LEGACY MAIN1 CONSUMERS
        ↓
REMOVE DUPLICATE MAIN2 COMPATIBILITY OWNER
        ↓
KEEP ONE AUTHORITATIVE RW_Dashboard
KEEP ONE AUTHORITATIVE RW_Items
        ↓
REMOVE / NEUTRALIZE OBSOLETE ROUTER / ALIASES
        ↓
KEEP ONE NAVIGATION AUTHORITY
        ↓
VERIFY SERVED ARTIFACT
        ↓
VERIFY BROWSER RUNTIME
```

Do not replace `New-main` wholesale with `Original/main2`. Do not create a third `RW_Dashboard` or `RW_Items`. Do not repair legacy stubs one-by-one when the authoritative implementation already exists.

## INVENTORY CONTINUITY
Reference contract remains:
```text
PHYSICAL STOCK MOVEMENT
        ↓
post_stock_movement
        ↓
stock_branches + inventory_log
```
`reserve_stock` remains reservation-only.
Previously measured Production anomalies remain separately open pending evidence-driven remediation:
```text
stock_branches branch/item-company mismatches = 143
inventory_log item/company mismatches         = 86
order_details item/company mismatches         = 6
```
Inventory is a separate closure track and was not modified as part of the P161 Main2 comparison.

## PRODUCTION / RUNTIME STATUS
```text
CURRENT GIT SOURCE IDENTITY        = VERIFIED
MAIN2 SOURCE COMPARISON            = VERIFIED
MAIN2 SOURCE FEATURE LOSS          = 0 PROVEN
RW_DASHBOARD DUPLICATE             = PROVEN
RW_ITEMS DUPLICATE                 = PROVEN
COMPATIBILITY FALSE-CAPABILITY     = PROVEN
LEGACY MAIN1 ROUTER RESIDUE        = PROVEN
LATER MAIN3 ROUTING                = PROVEN
SERVED ARTIFACT                    = NOT VERIFIED
BROWSER LIVE RUNTIME               = NOT VERIFIED
FINAL MAIN2 RUNTIME WINNER         = NOT PROVEN
```

## REPORTS
```text
P155 = doc/Draft/Reprots/تقرير16.md
P156 = doc/Draft/Reprots/تقرير17.md
P157 = doc/Draft/Reprots/تقرير18.md
P158 = doc/Draft/Reprots/تقرير19.md
P159 = doc/Draft/Reprots/تقرير20.md
P160 = doc/Draft/Reprots/تقرير21.md
P161 = doc/Draft/Reprots/تقرير22.md
P162 = doc/Draft/Reprots/تقرير23.md
```

No historical report was deleted or overwritten.

## P161 SELF-AUDIT
```text
MASTER READ                         = DONE
CURRENT_STATE READ                  = DONE
REPORT CHAIN REVIEW                 = DONE
RECENT GIT HISTORY                  = DONE
ORIGINAL main2 DIRECT REVIEW        = DONE
CURRENT New-main DIRECT REVIEW      = DONE
LATEST GIT IDENTITY                 = VERIFIED
MAIN2 SOURCE FEATURE PARITY         = PROVEN
MAIN2 FEATURE LOSS                  = 0 PROVEN
RW_DASHBOARD DUPLICATE              = PROVEN
RW_ITEMS DUPLICATE                  = PROVEN
COMPATIBILITY STUBS                 = PROVEN
LEGACY MAIN1 ROUTER RESIDUE         = PROVEN
MAIN3 ROUTE TABLE                   = PROVEN
FINAL LIVE RUNTIME WINNER           = UNKNOWN
TARGET CODE MODIFIED BY ASSISTANT   = NO
PRODUCTION DATA MODIFIED THIS ROUND = NO
HISTORICAL REPORTS DELETED          = NO
REPORT22 CREATED                    = YES
CURRENT_STATE UPDATED               = YES (P161)
SERVED ARTIFACT VERIFIED            = NO
BROWSER RUNTIME VERIFIED             = NO
100_PERCENT_CLOSURE                 = NO
```

## P162 SURGICAL HANDOFF
```text
EVENT ID        = P162-MAIN2-OWNERSHIP-SURGERY-SPEC
DATE            = 2026-09-02
REPORT          = doc/Draft/Reprots/تقرير23.md
REPORT COMMIT   = 3a5865aa15ecf9c8bea74d6e94322337ec8c4fba
TARGET          = Current/PWA/New-main
TARGET MODIFIED BY ASSISTANT = NO
ORIGINAL MODIFIED = NO
PRODUCTION DATA MODIFIED = NO
HISTORICAL REPORTS DELETED = NO
```

### P162 finding
```text
MAIN2 FUNCTIONAL FEATURE LOSS = 0 PROVEN
RW_Dashboard duplicate ownership = PROVEN
RW_Items duplicate ownership = PROVEN
Compatibility false-capability = PROVEN
Main1 Dashboard/Items global aliases = PROVEN
Main3 route table = PROVEN
```

### P162 owner-side surgical edit
1. Delete the complete duplicate block beginning at:
```javascript
/* RAWAEA MAIN2 COMPATIBILITY */
```
and ending at the compatibility close:
```javascript
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
})();
```
The next marker must be:
```javascript
/* RAWAEA MAIN2 AUTHORITATIVE MODULE */
```

2. Preserve the reconstruction version marker by adding, inside the authoritative module, immediately after:
```javascript
window.RW_Items = RW_Items;
```
this line:
```javascript
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
```
so the authoritative end contains:
```javascript
window.RW_Items = RW_Items;
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
// MAIN2_GOVERNED_CLOSED:v1
```

3. Inside the long Main1 assignment, remove only these two assignments:
```javascript
window.RW_Dashboard={render:renderDashboard};
window.RW_Items={render:renderItems};
```
Do not remove the surrounding Main1 `actions` closure or `main1Delegation` in P162; their final external-consumer closure is a separate unit.

### P162 explicit non-actions
```text
NO whole-file replacement
NO Main2 feature rewrite
NO third RW_Dashboard
NO third RW_Items
NO one-by-one repair of compatibility stubs
NO deletion of actions in this unit
NO deletion of main1Delegation in this unit
```

### P162 closure state
```text
MAIN2 SOURCE PARITY              = CLOSED
MAIN2 FUNCTIONAL FEATURE LOSS    = 0 PROVEN
OWNERSHIP SURGERY SPECIFIED      = YES
OWNER MANUAL EDIT                = PENDING
SERVED ARTIFACT                  = OPEN
BROWSER RUNTIME                  = OPEN
100_PERCENT_CLOSURE              = NO
```

### P162 self-audit
```text
MASTER RE-READ                   = DONE
CURRENT_STATE RE-READ            = DONE
REPORT22 RE-READ                 = DONE
REPORT21 RE-READ                 = DONE
RECENT GIT DIRECT CHECK          = DONE
Original main2 DIRECT CHECK      = DONE
Current New-main DIRECT CHECK    = DONE
LATEST TARGET COMMIT             = VERIFIED
LATEST TARGET BLOB               = VERIFIED
FEATURE LOSS CLAIM               = 0 PROVEN
DUPLICATE OWNERSHIP              = PROVEN
COMPATIBILITY STUBS              = PROVEN
MAIN1 ALIASES                    = PROVEN
MAIN3 ROUTING                    = PROVEN
TARGET EDITED BY ASSISTANT       = NO
PRODUCTION DATA EDITED           = NO
REPORT23 CREATED                 = YES
HISTORICAL REPORTS PRESERVED     = YES
```
