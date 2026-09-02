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
- P159 / `تقرير20.md`: fresh direct comparison of `Original/PWA/main/main2.md` vs current `New-main`; discovered that Main2 Dashboard/Items code is present in Current source but runtime dispatch and final global aliases shadow it with compact legacy renderers. No target-code modification was made by the assistant in P159.

## CURRENT SOURCE IDENTITIES
```text
Original/PWA/main/main2.md
SHA = 45d5e760a4b53e3be574346e3d9d192dbad309af

Current/PWA/New-main
Latest commit = da5af424360239c0571bf9c118871a635b96f8de
Commit message = Update New-main
Commit UTC = 2026-09-02T04:40:53Z
Current blob = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
```

The latest `da5af...` commit superseded the P158 `c3871ef...` state and added the missing password form-group `</div>` before `rw-login-options`.

## LAST VERIFIED EVENT
```text
EVENT ID        = P159-MAIN2-FORENSIC-DA5AF
EVENT TYPE      = Direct source forensic comparison
UTC             = 2026-09-02T04:40:53Z (latest target commit examined)
SOURCE          = MASTER + CURRENT_STATE + Reports16-19 + Original main2 + Current New-main + Git history + relevant Production evidence
GIT SHA         = da5af424360239c0571bf9c118871a635b96f8de
TARGET BLOB     = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
RESULT          = Main2 Dashboard/Items implementations are present in Current source; runtime route/alias shadowing is proven.
TARGET EDITED BY ASSISTANT = NO
REPORT         = doc/Draft/Reprots/تقرير20.md
REPORT COMMIT  = 8e59be597d5676c822ee9d0dd1a0e34f0a6aadd6
```

## MAIN2 FORENSIC STATUS
### Scope fact
`Original/PWA/main/main2.md` is not a full ERP snapshot. It contains the historical `RW_Dashboard` and `RW_Items` modules.

### Proven source parity
```text
RW_Dashboard full implementation = PRESENT in New-main
RW_Items full implementation     = PRESENT in New-main
Main2 source function loss       = 0 proven
```

### Proven runtime-shadow defects
1. Current contains a compact legacy `renderDashboard()` and the `actions` map points `dashboard:renderDashboard` instead of the full `RW_Dashboard.render()`.
2. Current contains a compact legacy `renderItems()` and the `actions` map points `items:renderItems` instead of the full `RW_Items.render()`.
3. Current later executes `window.RW_Dashboard={render:renderDashboard};` and `window.RW_Items={render:renderItems};`, overwriting the full module objects and their public APIs.

### Exact owner surgical patches from P159
```text
PATCH-01
Find:
 dashboard:renderDashboard,
Replace with:
 dashboard:function(){return RW_Dashboard.render();},

PATCH-02
Find:
 items:renderItems,
Replace with:
 items:function(){return RW_Items.render();},

PATCH-03
Find:
 window.RW_Dashboard={render:renderDashboard};
 window.RW_Items={render:renderItems};
Replace with:
 window.RW_Dashboard=RW_Dashboard;
 window.RW_Items=RW_Items;
```

Do not delete `renderDashboard()` or `renderItems()` yet; their removal is not proven safe until broader consumer tracing is complete.

## MAIN2 CAPABILITIES CURRENTLY SHADOWED AT RUNTIME
### Dashboard
```text
5 KPI cards
Date range filter
Previous-period comparison
Daily sales chart
Region chart + order/area drill-down
Top 10 items chart
Top 10 customers chart
Dashboard → Orders / Items navigation
```
These capabilities are present in the full Current `RW_Dashboard` implementation but are not the handlers used by the current route map.

### Items
```text
Stock-aware item list
Stock status classification
Per-branch quantities
Item editor
Image view/upload
Category CRUD + replacement flow
Movement report
Branch stock matrix
Excel export
CSV/XLSX upload preview
Bulk stock adjustment UI
Barcode search
Status filters
Branch-aware sorting
Stock-to-movement drill-down
```
These capabilities are present in the full Current `RW_Items` module but are shadowed by the compact `renderItems()` route.

## P158 HTML CORRECTION — CURRENT STATUS
```text
Password form-group closing tag = CLOSED AT SOURCE
Password CSS placement          = VERIFIED
Login footer                    = PRESENT
Raw CSS body text               = REMOVED
```
The P158 missing-div finding is superseded by the newer `da5af...` commit.

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
These anomalies are not used as a reason to alter `New-main` during P159.

Historical Inventory/Receive-Purchase lessons remain: do not reconstruct operation identity from mutable `qty_received_before` alone; use explicit operation identity when supported by the current contract.

## PRODUCTION / RUNTIME STATUS
```text
CURRENT GIT SOURCE IDENTITY       = VERIFIED
P159 SOURCE COMPARISON             = VERIFIED
TARGET CODE MODIFIED BY ASSISTANT = NO
CLOUDFLARE SERVED ARTIFACT         = NOT PROVEN IN P159
BROWSER LIVE RUNTIME               = NOT PROVEN IN P159
Main2 runtime restoration          = OWNER SURGERY REQUIRED
Inventory Core 100% closure        = NO
```

## REPORTS
```text
P155 = doc/Draft/Reprots/تقرير16.md
P156 = doc/Draft/Reprots/تقرير17.md
P157 = doc/Draft/Reprots/تقرير18.md
P158 = doc/Draft/Reprots/تقرير19.md
P159 = doc/Draft/Reprots/تقرير20.md
```

No historical report was deleted or overwritten.

## P159 SELF-AUDIT
```text
MASTER RECOVERY                     = COMPLETE
CURRENT_STATE RECONCILIATION        = COMPLETE
LATEST TARGET GIT                   = VERIFIED
ORIGINAL MAIN2                      = VERIFIED
CURRENT NEW-MAIN                    = VERIFIED
MAIN2 FULL MODULE PRESENCE          = PROVEN
DASHBOARD SHADOWING                 = PROVEN
ITEMS SHADOWING                     = PROVEN
FINAL GLOBAL ALIAS OVERWRITE        = PROVEN
SOURCE FUNCTION LOSS                = 0 PROVEN
RUNTIME CAPABILITY LOSS             = 2 MAJOR SURFACES
TARGET CODE MODIFIED BY ASSISTANT   = NO
REPORT20 CREATED                    = YES
CURRENT_STATE UPDATED               = YES
CLOUDFLARE RUNTIME VERIFIED         = NO
BROWSER RUNTIME VERIFIED            = NO
100_PERCENT_CLOSURE                 = NO
```

## NEXT AUTHORIZED STEP
Owner applies only PATCH-01, PATCH-02, PATCH-03 from `تقرير20.md`. After that, the next engineering action is live source/runtime verification of Dashboard and Items. Do not replace New-main wholesale with Original, do not rewrite `RW_Dashboard` or `RW_Items`, and do not touch Inventory Core as part of this Main2 routing correction.
