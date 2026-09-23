# CURRENT STATE — UPDATED AFTER REPORT315
## Session: 2026-09-23
## Scope: Warehouse Vouchers → Transfer Scope / Smart Search
## Canonical report: doc/Draft/Reprots/Report315_WAREHOUSE_VOUCHERS_TRANSFER_SCOPE_AUTHORIZATION_CLOSURE_20260923.md
## Execution log: doc/Draft/Reprots/EXECUTION_LOG_20260923_VOUCHERS_TRANSFER_SCOPE.md

### Authoritative current heads
- System repo HEAD after session artifacts: 9248f09f8284ddde9161843ffcbf9b5f2fb8ef01
- System repo parent at last artifact commit: 83c511699d8f383830f7c171182fa47fb9240883
- Production migration artifact commit: 29e62d94fdb45de86bc61c4a2d5e7f5412e69deb
- Frontend repo HEAD: 751f6175675ffe99023337e523501bd35e9553c6
- Frontend parent: f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3
- vouchers.html current blob: 751e7b4fc814dd7011ee903e1703dc8df9896f0c
- van-sales.html reference: 8d61382a8e0025a0d079e71dd94f33d106d9088e

### Production transfer contract — CLOSED / VERIFIED
For:
role = مخزني
+
active_warehouse_role = أذونات
+
type = Transfer

the system now permits transfer between active branches belonging to the same company.

Updated Production RPCs:
- create_manual_stock_voucher_atomic (10 args)
- create_manual_stock_voucher_atomic (12 args)
- send_stock_voucher_atomic
- post_manual_stock_voucher_atomic

No new Edge Function.
No new table.
No RLS change.
No Physical Stock engine change.

### Persistent QA — DO NOT DELETE
- IN-28 Transfer Draft QA-SEARCH-BRANCH-20260923
- IN-29 DirectSale Draft QA-SEARCH-VEHICLE-DS-20260923
- IN-30 DirectReturn Draft QA-SEARCH-VEHICLE-DR-20260923
- IN-31 SupplierReturn Draft QA-SEARCH-SUPPLIER-20260923
- IN-32 Transfer Completed QA-TRANSFER-ALL-BRANCHES-20260923 BR-01 → BR-2
- IN-33 Transfer Completed QA-TRANSFER-REVERSE-20260923 BR-2 → BR-01

### Production E2E
- IN-32 Create → Send → Receive → Complete = PASS
- IN-33 Create → Send → Receive → Complete = PASS
- Same operation_id replay for IN-32 did not create a second voucher = PASS
- vansales@rawaea.com Transfer attempt BR-01 → BR-2 = REJECTED
- Item 1001 company total remained 79 after forward + reverse transfer
- IN-32 inventory_log rows = 2
- IN-33 inventory_log rows = 2
- IN-32 audit rows = 4
- IN-33 audit rows = 4

### Final Production snapshot
- companies=1
- branches=4
- vehicles=2
- suppliers=1
- direct_reps=1
- stock_vouchers=33
- stock_voucher_details=35
- inventory_log=30
- audit_log=2123

### Current vouchers.html finding
The smart search and 500-row pagination are already present in Current Source.
Transfer wsFrom/wsTo already use allBranches and MUST NOT be reverted to userBranches under the new contract.
The remaining frontend action is only:
App.allowedBranch

Exact owner replacement is in Report315.

Do not modify:
- main.html
- van-sales.html
- loadRefs()
- pickArr()
- pickSearch()
- pickSelect()
- vehicleBranch()
- norm()
- routeHtml()
- submit()
- prepare()

### Final closure state
- Production Transfer Contract = CLOSED
- Production Transfer E2E = VERIFIED
- Backend authority = VERIFIED
- Frontend source patch = OWNER ACTION REQUIRED
- Published artifact = OPEN
- Authenticated browser E2E = OPEN

### Next session exact sequence
1. Verify frontend HEAD and vouchers.html blob.
2. Apply only App.allowedBranch replacement from Report315.
3. Static parse.
4. Publish.
5. Verify served artifact identity.
6. Run authenticated browser E2E for Transfer, DirectSale, DirectReturn, SupplierReturn.
7. Verify Draft creation remains zero Physical Stock movements.
8. Capture fresh Production snapshot in the same reporting window.
9. Update closure status only after browser evidence.

---

# CURRENT STATE — AUTHORITATIVE FORENSIC CHECKPOINT — 2026-09-23
## Scope: Warehouse Vouchers → Smart Search → Branch Authorization Candidate Visibility
## Canonical report: doc/Draft/Reprots/Report314_WAREHOUSE_VOUCHERS_BRANCH_SMART_SEARCH_FORBIDDEN_SCOPE_FORENSIC_20260923.md

### Authoritative baseline before this state-file write
- System repo HEAD: b3cc3c7fe405e502c243f4d74ac5680304e5259e
- System repo parent: 23ff77cf170771221293163e938d708c51ea5032
- Frontend repo HEAD: 751f6175675ffe99023337e523501bd35e9553c6
- Frontend parent: f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3
- vouchers.html current blob: 751e7b4fc814dd7011ee903e1703dc8df9896f0c
- van-sales.html current blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

### Current verified Production snapshot
Captured: 2026-09-23 05:45:45.724837+00
- companies = 1
- branches = 4
- vehicles = 2
- suppliers = 1
- direct_reps = 1
- stock_vouchers = 31
- stock_voucher_details = 33
- inventory_log = 26
- audit_log = 2115

### Persistent QA created this session — DO NOT DELETE
- IN-28 — Transfer — Draft — QA-SEARCH-BRANCH-20260923 — BR-01 → BR-2
- IN-29 — DirectSale — Draft — QA-SEARCH-VEHICLE-DS-20260923 — BR-01 → VCH-QA-260922
- IN-30 — DirectReturn — Draft — QA-SEARCH-VEHICLE-DR-20260923 — VCH-QA-260922 → BR-01
- IN-31 — SupplierReturn — Draft — QA-SEARCH-SUPPLIER-20260923 — BR-01 → SUPP-1001
- QA inventory movements = 0
- QA audit rows = 4

### Current source finding
- Smart-search engine is present and functioning in Current Source.
- loadRefs() pagination (500-row pages) is already present and must NOT be re-applied.
- vehicleBranch(), pickSearch(), pickSelect(), norm(), routeHtml(), submit(), prepare() are preserved closed surfaces.
- The remaining proven UI defect is inside App.pickArr(key):
  1. wsFrom for non-DirectReturn returns allBranches.
  2. Transfer wsTo returns allBranches.
- This causes forbidden branches to enter the search candidate set and appear as disabled "غير مصرح" entries instead of being hidden.

### Deterministic verification
- Before surgical substitution: Transfer wsFrom and wsTo returned all 4 current branches.
- After substituting those two returns with userBranches: both returned only BR-01 for a user whose allowed_branch_ids = BR-01.
- DirectSale vehicle search by code VCH-QA-260922 = PASS.
- DirectSale vehicle search by Arabic plate س م ج 26922 = PASS.
- DirectReturn vehicle search by code VEH-TEST-260921 = PASS.
- DirectReturn vehicle search by Arabic plate س ن ر 6021 = PASS.
- Representative search by vansales@rawaea.com = PASS.
- Supplier search by SUPP-1001 and ابراهيم = PASS.
- Branch search by BR-01 = PASS.
- Production backend rejected an unauthorized BR-01 → BR-2 Transfer attempt for vouchers@rawaea.com.
- CREATE Draft QA does not create inventory movements.

### Production / infrastructure decision
- No schema change required.
- No new RPC required.
- No new Edge Function required.
- No RLS change required.
- post_stock_movement remains the canonical Physical Stock engine.
- Existing RPC authorization remains the server-side authority.

### Owner surgical action
File:
companies/company-1/warehouse/vouchers.html

Function:
App.pickArr(key)

Change ONLY:
- the wsFrom fallback return: allBranches → userBranches
- the Transfer wsTo return: allBranches → userBranches

Full replacement is in Report314.

DO NOT MODIFY:
- main.html
- van-sales.html
- loadRefs()
- vehicleBranch()
- pickSearch()
- pickSelect()
- norm()
- routeHtml()
- submit()
- prepare()
- any Edge Function
- Physical Stock Engine

### Closure status
- CURRENT GIT = VERIFIED
- CURRENT SOURCE = VERIFIED
- CURRENT PRODUCTION = VERIFIED
- CURRENT DATABASE = VERIFIED
- PERSISTENT QA = VERIFIED
- ROOT CAUSE = PROVEN
- SURGICAL PATCH = READY FOR OWNER
- BROWSER AUTHENTICATED E2E = OPEN
- PUBLISHED ARTIFACT IDENTITY = OPEN
- This task must not be declared 100% CLOSED until the owner patch is applied, published, and authenticated browser E2E is run against that published artifact.

### Next-session exact sequence
1. Re-read this checkpoint and then independently verify latest System/Frontend HEADs.
2. Verify current vouchers blob before any edit.
3. Confirm whether PATCH-314-01 is already present; do not repeat it if present.
4. If not present, owner applies only the exact App.pickArr replacement in Report314.
5. Static parse.
6. Publish frontend.
7. Run authenticated browser E2E:
   - Transfer wsFrom/wsTo: forbidden branches must NOT appear.
   - DirectSale: branch → representative → vehicle; search vehicle code and Arabic plate.
   - DirectReturn: vehicle → branch; search vehicle code and Arabic plate.
   - SupplierReturn: supplier search where relationship exists.
   - Save Draft and verify no Physical Stock movement.
8. Capture served-artifact identity.
9. Capture a fresh Production snapshot at the same reporting moment.
10. Only then change Browser E2E / closure status.

### Governance
Reports are historical clues, not current truth.
Current truth is always:
CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

---

# CURRENT STATE — UPDATED AFTER REPORT313
## Session: 2026-09-22
## Current scope: Warehouse Vouchers Smart Search / Reference Directory
## Canonical report commit: a352eb94bf0a5e25be60365347876e5bd848c00f

### Authoritative current heads
- System repo HEAD at checkpoint creation: 23ff77cf170771221293163e938d708c51ea5032
- System repo parent: a352eb94bf0a5e25be60365347876e5bd848c00f
- Frontend repo HEAD: f42bc0ae0c2e88a6ebf66e54b6a9ff8e1057c5e3
- Frontend parent: 7a11af9ecba59da29fd6d8aad17053678d75c2e6
- vouchers.html current blob: 55250e74f271e18cb0dfdfb00f1c1c3ec37489c3
- van-sales.html current blob: 8d61382a8e0025a0d079e71dd94f33d106d9088e

### Session result
- Previous parser regression is CLOSED in current HEAD; do not repeat parser surgery.
- Current proven branch-search defect: App.pickArr(wsFrom) returns vehicles only for DirectReturn and lacks the normal fallback return of all company branches.
- Current proven scalability defect: loadRefs() performs unpaginated reference SELECTs. This can truncate large branch/vehicle/supplier/rep/purchase-order directories under Supabase's default 1000-row response ceiling.
- Surgical owner patch prepared in Report313; no modification was made to main.html, vouchers.html, or van-sales.html by the system.
- Production backend was intentionally not changed because the current defect is in frontend reference loading/selection, not in the central stock contract.
- Persistent QA records IN-23..IN-27 remain in Production and were not deleted.
- QA inventory movements for IN-23..IN-27 remain 0.
- Static JS parse of current vouchers.html = PASS.
- Patched-script syntax test = PASS.
- Synthetic scale test = PASS: 150 branches, 1,205 vehicles, 1,200 suppliers, 10,005 reps using 500-row pagination.
- Authenticated real-browser E2E remains OPEN and must not be labeled PASS without a real authenticated browser run.

### Production snapshot for this session
- companies = 1
- branches = 4
- active_branches = 4
- vehicles = 2
- active_vehicles = 2
- suppliers = 1
- active_suppliers = 1
- direct_reps = 1
- stock_vouchers = 27
- stock_voucher_details = 29
- inventory_log = 26
- audit_log = 695

### Owner action
Apply only PATCH-313-01, PATCH-313-02, PATCH-313-03 from:
doc/Draft/Reprots/Report313_WAREHOUSE_VOUCHERS_SMART_SEARCH_FORENSIC_SCALABILITY_CLOSURE_20260922.md
to:
companies/company-1/warehouse/vouchers.html

Do not modify main.html or van-sales.html.

### Next-session sequence
CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → DEPLOYMENT EVIDENCE → owner patch verification → authenticated browser E2E → fresh Production snapshot → final closure report.

---

# CURRENT STATE — AUTHORITATIVE FORENSIC CHECKPOINT — 2026-09-22

## 1. Authoritative sources