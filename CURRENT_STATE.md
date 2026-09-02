# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Current truth must be reconstructed from direct Git, direct Production/database evidence, active deployments/runtime evidence when available, and verified artifacts.
- Historical reports are evidence of what was done; they are not current truth by themselves.
- `Current/PWA/New-main` is the authorized target for the current PWA reconstruction track.
- `Current/PWA/main.html` is a separate artifact and must not be substituted for `New-main` by filename similarity.
- Historical reports are sacred: do not delete or overwrite them.
- `UNKNOWN ≠ BUG`, `UNKNOWN ≠ REMOVE`.
- `Git/source verified ≠ runtime verified`.
- `Runtime verified ≠ Production data repair`.
- Governing loop: CURRENT_STATE → LAST VERIFIED EVENT → CURRENT GIT → CURRENT PRODUCTION → DEPLOYMENTS/RUNTIME → CURRENT FILES → RECONCILE → SURGICAL CHANGE → VERIFY → CURRENT_STATE.

## CURRENT REPOSITORY / HEAD
```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH     = main
CURRENT HEAD = 0a76f5e76cef5b6b86f78dd7a951c5522706fd9e
HEAD MESSAGE = docs: record P162 Main2 surgical handoff
HEAD UTC    = 2026-09-02T09:59:19Z
```

`0a76f5e...` is a documentation commit. It did not modify `Current/PWA/New-main`.

## CURRENT TARGET IDENTITIES
```text
Original/PWA/main/main2.md
SHA = 45d5e760a4b53e3be574346e3d9d192dbad309af

Current/PWA/New-main
LATEST TARGET CODE COMMIT = da5af424360239c0571bf9c118871a635b96f8de
TARGET BLOB = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
TARGET CODE MODIFIED BY ASSISTANT IN P163 = NO
```

The `da5af...` target commit, created at `2026-09-02T04:40:53Z`, only added the missing login-form `</div>` before `rw-login-options`; it did not remove the Main2 duplicate/authoritative structure.

## HISTORICAL CONTINUITY
```text
P155 = doc/Draft/Reprots/تقرير16.md
P156 = doc/Draft/Reprots/تقرير17.md
P157 = doc/Draft/Reprots/تقرير18.md
P158 = doc/Draft/Reprots/تقرير19.md
P159 = doc/Draft/Reprots/تقرير20.md
P160 = doc/Draft/Reprots/تقرير21.md
P161 = doc/Draft/Reprots/تقرير22.md
P162 = doc/Draft/Reprots/تقرير23.md
P163 = doc/Draft/Reprots/تقرير24.md
```

No historical report was deleted or overwritten.

## LAST VERIFIED EVENT
```text
EVENT ID        = P163-NEWMAIN-MAIN2-SURGICAL-HANDOFF
DATE            = 2026-09-02
SOURCE          = MASTER + CURRENT_STATE + Report16 + Report22 + Report23 + direct Git + direct Production/deployment checks + direct Original/main2 + direct Current/New-main
CURRENT HEAD    = 0a76f5e76cef5b6b86f78dd7a951c5522706fd9e
TARGET          = Current/PWA/New-main
TARGET BLOB     = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
ORIGINAL SHA    = 45d5e760a4b53e3be574346e3d9d192dbad309af
RESULT          = MAIN2 FEATURE LOSS 0 PROVEN; DUPLICATE OWNERSHIP PROVEN; SURGICAL EDITS SPECIFIED
TARGET EDITED BY ASSISTANT = NO
ORIGINAL EDITED = NO
PRODUCTION DATA EDITED IN P163 = NO
REPORT = doc/Draft/Reprots/تقرير24.md
REPORT COMMIT = 61a93644b7f04f6ffa45b67ccc47114a4c6a356d
```

## MAIN2 FORENSIC STATUS
`Original/PWA/main/main2.md` is a historical source for the Main2 `RW_Dashboard` and `RW_Items` modules, not a full ERP snapshot.

### Proven capability parity
```text
RW_Dashboard full capability set = PRESENT in New-main
RW_Items full capability set     = PRESENT in New-main
MAIN2 FUNCTIONAL FEATURE LOSS    = 0 PROVEN
```

Direct source review found two definitions of `RW_Dashboard` and two definitions of `RW_Items` in `New-main`:
```text
MAIN2 COMPATIBILITY
  ├─ RW_Dashboard #1
  └─ RW_Items #1

MAIN2 AUTHORITATIVE MODULE
  ├─ RW_Dashboard #2
  └─ RW_Items #2
```

The first pair is compatibility/legacy residue and contains false-capability stubs; the later pair contains the real authoritative implementations. The source also contains a later Main3 authoritative routing module.

## PROVEN MAIN2 OWNERSHIP DEFECTS
```text
RW_Dashboard duplicate ownership = PROVEN
RW_Items duplicate ownership     = PROVEN
Compatibility false-capability   = PROVEN
Legacy Main1 dashboard/items aliases = PROVEN
Main3 later routing               = PROVEN
```

Compatibility stubs directly identified include:
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

`_handleSaveFromPage` and `_handleDeleteFromPage` in the compatibility surface are also delegation/placeholder implementations rather than the authoritative business implementation.

## AUTHORIZED SURGICAL EDIT — OWNER MANUAL ONLY

### 1) Delete the whole duplicate Main2 Compatibility block

Search exactly:
```javascript
/* RAWAEA MAIN2 COMPATIBILITY */
```

Delete everything from that marker through this exact compatibility close:
```javascript
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
})();
```

The next retained marker must be:
```javascript
/* RAWAEA MAIN2 AUTHORITATIVE MODULE */
```

Do not delete the authoritative Main2 module or any Main3 module.

### 2) Preserve the reconstruction marker under the authoritative owner

Inside the authoritative Main2 module, locate exactly:
```javascript
window.RW_Items = RW_Items;
// MAIN2_GOVERNED_CLOSED:v1
```

Insert immediately between them:
```javascript
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
```

The resulting sequence must be:
```javascript
window.RW_Items = RW_Items;
window.RW_PWA_RECONSTRUCTION_VERSION='MAIN2-COMPLETE-SURGICAL-v1';
// MAIN2_GOVERNED_CLOSED:v1
```

### 3) Remove only the Main1 dashboard/items global aliases

Inside the long Main1 assignment, remove exactly these two fragments:
```javascript
window.RW_Dashboard={render:renderDashboard};
window.RW_Items={render:renderItems};
```

Do not remove the surrounding assignment, and do not remove:
```text
RW_POS
RW_Orders
RW_Runsheets
RW_Purchases
RW_Warehouse
RW_Finance
RW_Reports
RW_HR
RW_CRM
```

Do not remove:
```text
var actions=...
main1Delegation(...)
```

Those require a separate consumer-closure unit.

## EXPLICIT NON-ACTIONS FOR P163
```text
NO whole-file replacement
NO rewrite of RW_Dashboard
NO rewrite of RW_Items
NO new Main2 implementation
NO third RW_Dashboard
NO third RW_Items
NO one-by-one repair of compatibility stubs
NO deletion of actions
NO deletion of main1Delegation
NO modification of Original/main2.md
NO modification of Current/PWA/New-main by the assistant
```

## RUNTIME STATUS
```text
TARGET SOURCE IDENTITY           = VERIFIED
MAIN2 SOURCE PARITY              = VERIFIED
MAIN2 FUNCTIONAL FEATURE LOSS    = 0 PROVEN
DUPLICATE OWNERSHIP              = PROVEN
COMPATIBILITY FALSE-CAPABILITY   = PROVEN
MAIN1 DASHBOARD/ITEM ALIASES     = PROVEN
MAIN3 ROUTING                    = PROVEN
SERVED ARTIFACT                  = NOT VERIFIED
BROWSER LIVE RUNTIME             = NOT VERIFIED
FINAL RUNTIME WINNER             = NOT PROVEN
```

## PRODUCTION / INVENTORY CONTINUITY — SEPARATE TRACK
The current Production database has continued to receive Inventory/Finance/Voucher migrations after the earlier PWA comparison work. The latest recorded Production migration is:
```text
20260902023122 compatibility_company_main_branch_projection_20260902
```

Current Production Edge Functions are also at newer versions than those recorded in older reports. This does not alter the P163 New-main surgical finding.

Relevant schema facts directly verified during continuity work:
```text
items.item_code = UNIQUE globally
stock_branches = UNIQUE(branch_id,item_id)
receiving.operation_id = UNIQUE
```

Previously measured data anomalies are kept separate from this PWA track and were not deleted in P163 merely from suspicion:
```text
stock_branches branch/item-company mismatches = 143
inventory_log item/company mismatches         = 86
order_details item/company mismatches         = 6
```

These counts do not by themselves prove corruption because the current Item Master contract is globally unique by `item_code`.

## RECORDED PRIOR FAILURES / LESSONS

The following are preserved as continuity memory and must not be hidden:

1. Earlier comparisons sometimes used the wrong target file (`Current/PWA/main.html` instead of `Current/PWA/New-main`). This was corrected by direct source comparison.
2. An earlier claim that the current receive-purchase flow had no `Idempotency-Key` was later disproved by direct source evidence.
3. Earlier Inventory/Production work was sometimes performed before the current PWA scope was re-established. Those changes are historical and separate from the New-main surgical track.
4. Transactional Receive Purchase experiments exposed ordering issues between duplicate/idempotency detection and quantity/state guards.
5. Operation identity based only on mutable state such as `qty_received_before` is not a robust independent operation identity; the later direction was explicit operation identity.
6. Several early judgments about tenant/item scoping were corrected after direct schema verification showed `items.item_code` is globally unique under the current contract.
7. No such historical Inventory experiment changed `Current/PWA/New-main` in P163.
8. Git/source success must not be represented as browser/runtime success.

## P162 / P163 HANDOFF
```text
P162 = ownership surgery was specified; owner edit pending.
P163 = continuity was rebuilt from direct sources; the same surgery was revalidated; no New-main code was changed by the assistant; report24 was created.
```

### Next authorized action
```text
OWNER MANUAL SURGERY ON Current/PWA/New-main
        ↓
DIRECT RE-READ OF NEW-MAIN
        ↓
PROVE RW_Dashboard DEFINITIONS = 1
PROVE RW_Items DEFINITIONS     = 1
PROVE MARKER LOCATION
PROVE MAIN3 ROUTING INTACT
        ↓
SERVED ARTIFACT VERIFICATION
        ↓
BROWSER RUNTIME VERIFICATION
        ↓
NEXT CURRENT_STATE UPDATE
```

## REPORT INDEX
```text
P155 = doc/Draft/Reprots/تقرير16.md
P156 = doc/Draft/Reprots/تقرير17.md
P157 = doc/Draft/Reprots/تقرير18.md
P158 = doc/Draft/Reprots/تقرير19.md
P159 = doc/Draft/Reprots/تقرير20.md
P160 = doc/Draft/Reprots/تقرير21.md
P161 = doc/Draft/Reprots/تقرير22.md
P162 = doc/Draft/Reprots/تقرير23.md
P163 = doc/Draft/Reprots/تقرير24.md
```

## FINAL SELF-AUDIT
```text
MASTER READ                         = DONE
CURRENT_STATE RECONCILIATION       = DONE
P163 REPORT CREATED                 = DONE
LATEST GIT HEAD                     = VERIFIED
TARGET NEW-MAIN BLOB                = VERIFIED
ORIGINAL main2 BLOB                 = VERIFIED
CURRENT PRODUCTION MIGRATIONS       = CHECKED
CURRENT EDGE DEPLOYMENTS            = CHECKED
MAIN2 FEATURE LOSS                  = 0 PROVEN
RW_DASHBOARD DUPLICATE              = PROVEN
RW_ITEMS DUPLICATE                  = PROVEN
COMPATIBILITY STUBS                 = PROVEN
MAIN1 ALIASES                       = PROVEN
MAIN3 ROUTING                       = PROVEN
TARGET CODE MODIFIED BY ASSISTANT  = NO
ORIGINAL MODIFIED                  = NO
HISTORICAL REPORTS DELETED         = NO
OWNER SURGICAL EDIT                 = PENDING
SERVED ARTIFACT                     = NOT VERIFIED
BROWSER RUNTIME                     = NOT VERIFIED
100_PERCENT_CLOSURE                 = NO
```
