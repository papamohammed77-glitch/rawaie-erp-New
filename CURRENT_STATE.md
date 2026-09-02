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
CURRENT HEAD = 239643c353cb2aeb0daa92ce4ee4c4d60b805603
HEAD MESSAGE = docs: add P164 Master CTO continuity and execution report
HEAD UTC    = 2026-09-02T22:16Z (session state update)
```

The current HEAD includes the P164 documentation and continuity artifacts; it did not modify `Current/PWA/New-main`.

## CURRENT TARGET IDENTITIES
```text
Original/PWA/main/main2.md
SHA = 45d5e760a4b53e3be574346e3d9d192dbad309af

Current/PWA/New-main
LATEST TARGET CODE COMMIT = da5af424360239c0571bf9c118871a635b96f8de
TARGET BLOB = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
TARGET CODE MODIFIED BY ASSISTANT IN P164 = NO
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
P164 = doc/Draft/Reprots/تقرير25.md
```

No historical report was deleted or overwritten.

## LAST VERIFIED EVENT
```text
EVENT ID        = P164-MASTER-CTO-CONTINUITY-PROMPT
DATE            = 2026-09-03
SOURCE          = MASTER + CURRENT_STATE + Report22 + Report23 + Report24 + direct Git history + direct Current/New-main + direct Original/main index
CURRENT HEAD    = 239643c353cb2aeb0daa92ce4ee4c4d60b805603
TARGET          = Current/PWA/New-main
TARGET BLOB     = fa7c0fcf78a3b217d781fe543b6e5a5ed7411c63
ORIGINAL SHA    = 45d5e760a4b53e3be574346e3d9d192dbad309af
RESULT          = MASTER CTO CONTINUITY PROMPT CREATED; P163 MAIN2 OWNERSHIP SURGERY REMAINS OPEN; TARGET CODE UNCHANGED
TARGET EDITED BY ASSISTANT = NO
ORIGINAL EDITED = NO
PRODUCTION DATA EDITED IN P164 = NO
MASTER PROMPT = doc/Draft/Reprots/MASTER_CTO_NEW_MAIN_CONTINUITY_EXECUTION.md
REPORT = doc/Draft/Reprots/تقرير25.md
```

## MASTER CTO PROMPT
```text
FILE = doc/Draft/Reprots/MASTER_CTO_NEW_MAIN_CONTINUITY_EXECUTION.md
PURPOSE = persistent Lead Engineer / CTO operating directive for Current/PWA/New-main
STATUS = CREATED
TARGET = Current/PWA/New-main
```

The Master Prompt explicitly reconstructs continuity from CURRENT_STATE → Git → Production → Deployments/Runtime → Current files → Historical contracts, then continues with surgical execution and verification. It is an operating directive, not proof of any current closure.

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

## AUTHORIZED SURGICAL EDIT — OWNER MANUAL / DIRECT EXECUTION

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

## EXPLICIT NON-ACTIONS FOR P164
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
NO claim that P163 surgery is closed
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
P163 SURGERY                     = OPEN
```

## PRODUCTION / INVENTORY CONTINUITY — SEPARATE TRACK
The Production database has continued to receive Inventory/Finance/Voucher migrations after earlier PWA work. Inventory must remain a separate closure track unless current New-main evidence demonstrates a direct dependency.

Relevant schema facts directly verified during continuity work:
```text
items.item_code = UNIQUE globally
stock_branches = UNIQUE(branch_id,item_id)
receiving.operation_id = UNIQUE
```

Previously measured data anomalies remain separate and were not deleted in P164 merely from suspicion:
```text
stock_branches branch/item-company mismatches = 143
inventory_log item/company mismatches         = 86
order_details item/company mismatches         = 6
```

These counts do not by themselves prove corruption because the current Item Master contract is globally unique by `item_code`.

## RECORDED PRIOR FAILURES / LESSONS

1. Wrong target-file confusion between `Current/PWA/main.html` and `Current/PWA/New-main` was corrected only after direct source comparison.
2. A prior claim that the current receive-purchase flow had no `Idempotency-Key` was later disproved by direct source evidence.
3. Inventory/Production work was historically sometimes investigated before the current PWA scope was re-established; those tracks remain historically separate unless direct dependency is proven.
4. Transactional Receive Purchase experiments exposed ordering issues between duplicate/idempotency detection and quantity/state guards.
5. Operation identity built only from mutable state such as `qty_received_before` is not a robust independent operation identity; explicit operation identity is preferred where the contract supports it.
6. Early tenant/item-scope assumptions were corrected after direct schema verification showed `items.item_code` is globally unique.
7. No such historical Inventory experiment changed `Current/PWA/New-main` in P163/P164.
8. Git/source success must not be represented as browser/runtime success.
9. `CURRENT_STATE.md` can itself be stale relative to Git; it must be reconciled every session.
10. Historical reports are sacred and are never deleted to simplify continuity.

## P164 HANDOFF
```text
P164 = build persistent Master CTO continuity prompt
      ↓
re-establish Current/PWA/New-main as the sole execution target
      ↓
retain Original/main1..main11 as historical reconstruction sources
      ↓
retain P163 Main2 ownership surgery as the next verified open target
      ↓
force direct evidence / no-guessing / current-production reconciliation
```

## NEXT AUTHORIZED ACTION
```text
RUN MASTER_CTO_NEW_MAIN_CONTINUITY_EXECUTION.md
        ↓
READ CURRENT_STATE AGAIN
        ↓
VERIFY CURRENT HEAD AND TARGET BLOB AGAIN
        ↓
VERIFY WHETHER P163 MAIN2 SURGERY WAS EXECUTED
        ↓
IF OPEN: TRACE CONSUMERS → SURGICAL OWNERSHIP EDIT → VERIFY
        ↓
VERIFY New-main SOURCE
        ↓
VERIFY SERVED ARTIFACT
        ↓
VERIFY BROWSER RUNTIME
        ↓
UPDATE CURRENT_STATE
        ↓
SELECT THE NEXT REAL OPEN TARGET
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
P164 = doc/Draft/Reprots/تقرير25.md
MASTER = doc/Draft/Reprots/MASTER_CTO_NEW_MAIN_CONTINUITY_EXECUTION.md
```

## FINAL SELF-AUDIT
```text
MASTER READ                         = DONE
CURRENT_STATE READ                  = DONE
LATEST GIT HISTORY CHECK            = DONE
LATEST TARGET IDENTITY              = VERIFIED
LATEST REPORT CHAIN                 = REVIEWED THROUGH P164
Original main1..main11 INDEX        = VERIFIED
MASTER CTO PROMPT CREATED           = DONE
P164 REPORT CREATED                 = DONE
TARGET CODE MODIFIED BY ASSISTANT  = NO
ORIGINAL MODIFIED                  = NO
HISTORICAL REPORTS DELETED          = NO
P163 MAIN2 SURGERY                  = PENDING / OPEN
SERVED ARTIFACT                     = NOT VERIFIED
BROWSER RUNTIME                     = NOT VERIFIED
PROJECT-WIDE CLOSURE                = NOT CLAIMED
```
