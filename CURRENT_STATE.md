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
- P160 / `تقرير21.md`: revalidated the same current New-main source and corrected the P159 interpretation. Full Main2 source capability loss remains 0 proven, but Current contains duplicate `RW_Dashboard` and duplicate `RW_Items` definitions, a legacy Main1 compatibility router/alias surface, and incomplete compatibility stubs. The final live runtime winner remains unproven because later Main3 routing also exists.

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

The latest `da5af...` commit superseded the P158 `c3871ef...` state and added the missing password form-group `</div>` before `rw-login-options`.

## LAST VERIFIED EVENT
```text
EVENT ID        = P160-MAIN2-FORENSIC-FA7C
EVENT TYPE      = Direct source revalidation + ownership/duplication forensic comparison
UTC             = 2026-09-02
SOURCE          = MASTER + CURRENT_STATE + Reports16-20 + Original main2 + Current New-main + Git history + relevant Production evidence
GIT SHA         = da5af424360239c0571bf9c118871a635b96f8de
TARGET BLOB     = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
RESULT          = Main2 full modules are present; Current contains duplicate RW_Dashboard/RW_Items definitions, compatibility stubs, legacy Main1 routing residue, and a later Main3 route table. P159 routing-shadow conclusion is not sufficient to declare the final live runtime winner.
TARGET EDITED BY ASSISTANT = NO
REPORT         = doc/Draft/Reprots/تقرير21.md
REPORT COMMIT  = d2db193142834a39685f4a1913c975acf842c17e
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

### Current duplicate ownership defects
```text
RW_Dashboard definitions = 2
RW_Items definitions     = 2
```

The first pair is under `MAIN2 COMPATIBILITY`; the later pair is under `MAIN2 AUTHORITATIVE MODULE` and is the stronger current implementation.

### Legacy compatibility defects
The first `RW_Items` copy contains real stubs/delegations for category CRUD, Excel export, and upload execution, including:
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
These stubs are not evidence of missing capability in the authoritative copy; they are duplicate/false capability residue.

### Navigation ownership status
An older Main1 compatibility `actions` map still contains:
```text
dashboard:renderDashboard
items:renderItems
```
and a legacy global assignment surface:
```text
window.RW_Dashboard={render:renderDashboard}
window.RW_Items={render:renderItems}
```
A later Main3 route table is also present and uses:
```text
window.RW_Dashboard
window.RW_Items
```
Therefore final runtime ownership is unresolved from source alone.

## P160 OWNER SURGICAL INSTRUCTIONS
```text
SURGERY-01
Remove the obsolete MAIN2 COMPATIBILITY block containing the first RW_Dashboard and first RW_Items definitions, from:
/* RAWAEA MAIN2 COMPATIBILITY */
through:
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
Keep the later:
/* RAWAEA MAIN2 AUTHORITATIVE MODULE */
block intact.

SURGERY-02
Remove/neutralize the obsolete Main1 compatibility routing/alias ownership once its final consumer role is covered by the later authoritative route surface. Do not create a third router or third alias layer.

SURGERY-03
Do not rewrite or duplicate the authoritative RW_Dashboard/RW_Items implementations.
Do not repair the compatibility stubs one by one; remove the duplicate owner instead.
```

## P158 HTML CORRECTION — CURRENT STATUS
```text
Password form-group closing tag = CLOSED AT SOURCE
Password CSS placement          = VERIFIED
Login footer                    = PRESENT
Raw CSS body text               = REMOVED
```
The P158 missing-div finding remains superseded by the newer `da5af...` source state.

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
These inventory anomalies are a separate closure track and were not used to modify `New-main` in P160.

## PRODUCTION / RUNTIME STATUS
```text
CURRENT GIT SOURCE IDENTITY        = VERIFIED
P160 SOURCE COMPARISON             = VERIFIED
TARGET CODE MODIFIED BY ASSISTANT  = NO
CLOUDFLARE SERVED ARTIFACT         = NOT VERIFIED
BROWSER LIVE RUNTIME               = NOT VERIFIED
FINAL MAIN2 RUNTIME WINNER         = NOT PROVEN
MAIN2 SOURCE FEATURE LOSS          = 0 PROVEN
MAIN2 DUPLICATE OWNERSHIP          = PROVEN
LEGACY COMPATIBILITY STUBS         = PROVEN
INVENTORY CORE 100% CLOSURE        = NO
```

## REPORTS
```text
P155 = doc/Draft/Reprots/تقرير16.md
P156 = doc/Draft/Reprots/تقرير17.md
P157 = doc/Draft/Reprots/تقرير18.md
P158 = doc/Draft/Reprots/تقرير19.md
P159 = doc/Draft/Reprots/تقرير20.md
P160 = doc/Draft/Reprots/تقرير21.md
```

No historical report was deleted or overwritten.

## P160 SELF-AUDIT
```text
MASTER READ                         = DONE
CURRENT_STATE READ                  = DONE
REPORT CHAIN REVIEW                 = DONE
ORIGINAL main2 DIRECT REVIEW        = DONE
CURRENT New-main DIRECT REVIEW      = DONE
LATEST GIT IDENTITY                 = VERIFIED
MAIN2 SOURCE FEATURE PARITY         = PROVEN
RW_DASHBOARD DUPLICATE              = PROVEN
RW_ITEMS DUPLICATE                  = PROVEN
COMPATIBILITY STUBS                 = PROVEN
LEGACY MAIN1 ROUTER RESIDUE        = PROVEN
MAIN3 ROUTE TABLE                   = PROVEN
FINAL LIVE RUNTIME WINNER           = UNKNOWN
TARGET CODE MODIFIED BY ASSISTANT   = NO
HISTORICAL REPORTS DELETED          = NO
REPORT21 CREATED                    = YES
CURRENT_STATE UPDATED               = YES
CLOUDFLARE RUNTIME VERIFIED         = NO
BROWSER RUNTIME VERIFIED            = NO
100_PERCENT_CLOSURE                 = NO
```

## NEXT AUTHORIZED STATE
The owner-side surgery target is now the duplicate/legacy ownership structure, not a rewrite of Main2 functionality:
```text
REMOVE DUPLICATE COMPATIBILITY OWNER
        ↓
KEEP ONE AUTHORITATIVE RW_Dashboard
KEEP ONE AUTHORITATIVE RW_Items
        ↓
REMOVE / NEUTRALIZE OBSOLETE MAIN1 ROUTER OWNERSHIP
        ↓
KEEP ONE NAVIGATION AUTHORITY
        ↓
LIVE RUNTIME VERIFICATION
```

Do not replace `New-main` wholesale with `Original/main2`. Do not create a third Main2 module. Do not repair the duplicate stubs individually when the authoritative implementation already exists.
