# CURRENT STATE — AUTHORITATIVE FORENSIC CHECKPOINT — 2026-09-22

## 1. Authoritative sources
Current truth for this checkpoint is:
- CURRENT GIT
- CURRENT SOURCE
- CURRENT PRODUCTION
- CURRENT DATABASE
- CURRENT DEPLOYMENT EVIDENCE

Reports are forensic clues only.

## 2. Current Git
### System repository
Repository: papamohammed77-glitch/rawaie-erp-New
HEAD observed:
5efcbae22691a7d09574412056faf5a6494765ce
Parent:
6693d1c55c6b35314f18ddde63afe3613d59833c

### Frontend repository
Repository: papamohammed77-glitch/erp-frontend
HEAD observed:
78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40
Parent:
bf88f28e33b789b4822f2dd2b7ec025827a8c54a
Current vouchers.html blob:
712f717c818819c5d5d9afba843465c7ae892672

Latest forensic report:
doc/Draft/Reprots/Report310_WAREHOUSE_VEHICLE_PICKER_CURRENT_SOURCE_REGRESSION_CLOSURE_20260922.md

## 3. Scope lock
Target:
- Warehouse → Inventory Management → Stock Vouchers.
- Vehicle smart search for DirectSale and DirectReturn.

Intentionally untouched:
- erp-frontend/companies/company-1/main.html
- erp-frontend/companies/company-1/warehouse/vouchers.html
- erp-frontend/companies/company-1/sales/van-sales.html

No new Edge Function.
No second Physical Stock Engine.

## 4. Production reality verified
Company:
00000000-0000-0000-0000-000000000001

Voucher operator:
vouchers@rawaea.com
role = مخزني
active_warehouse_role = أذونات
allowed_branch_ids = BR-01
status = Active

Direct-sales representative:
vansales@rawaea.com
role = مندوب بيع مباشر
permissions = [van-sales]
status = Active


---

## 2026-09-22 — Report311 LATEST CURRENT SOURCE CHECKPOINT

### Authoritative current heads

System repository:
224f53961c667553d5d853016d9013eb91944bab
Parent:
5efcbae22691a7d09574412056faf5a6494765ce

Frontend repository:
7a11af9ecba59da29fd6d8aad17053678d75c2e6
Parent:
ec8f2fe8ac7e8c6ac203ef2fafec520b0f05f10e

Current vouchers.html:
49a32ac408c629ac22024c8a93713ea758b73197

Current van-sales.html:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Latest forensic report:
doc/Draft/Reprots/Report311_WAREHOUSE_VOUCHERS_VEHICLE_SEARCH_LATEST_SYNTAX_REGRESSION_20260922.md

### Scope

Warehouse → Inventory Management → Stock Vouchers → DirectSale / DirectReturn vehicle picker.

### Current forensic finding

The previously reported business regression in vehicle candidate authorization has already been corrected in Current Source.

Current vehicleBranch(), pickSearch(), norm(), and pickSelect() are verified and must not be reopened.

The current blocker is a JavaScript structural regression inside App.pickArr(key):

1. The outer if(key==='wsFrom') is not explicitly closed immediately after the DirectReturn vehicle block.
2. The pickArr object member separator comma before pickShow is missing.

Current source ends with:

return allBranches;
}
pickShow:function(key)...

This produces:

vouchers:1799
Function statements require a function name

The latest frontend commit 7a11af9ecba59da29fd6d8aad17053678d75c2e6 changed:

-},
+}

and is therefore part of the current regression lineage.

### Exact owner surgical patch

File:
companies/company-1/warehouse/vouchers.html

Function:
App.pickArr(key)

Vehicle element:
replace the DirectReturn element from:

if(key==='wsFrom'){
    if(s.type==='DirectReturn'){
    ...
    }
    
to the correctly closed element in Report311.

Parser closure:
change:

return allBranches;
}

to:

return allBranches;
},

Do not modify main.html or van-sales.html.

Do not modify vehicleBranch(), pickSearch(), pickSelect(), norm(), loadRefs(), submit(), DirectSale vehicle filter, or Production RPCs.

### Production

Production vehicle contract verified.

Persistent QA retained and must not be deleted:

VCH-QA-260922
IN-24 — DirectSale — Draft — QA-SMART-VEHICLE-DS-260922
IN-25 — DirectReturn — Draft — QA-SMART-VEHICLE-DR-260922

QA audit rows:
2

QA inventory movements:
0

Current company counters:
stock_vouchers = 25
stock_voucher_details = 27
inventory_log = 26
audit_log = 2109

No Production schema/RLS/Edge Function change is required for this frontend syntax regression.

### Deterministic verification

PASS:
- DirectReturn vehicle candidates
- DirectReturn vehicle-code search
- DirectReturn Arabic license-plate search
- DirectSale vehicle candidates
- DirectSale vehicle-code search
- DirectSale Arabic license-plate search
- corrected JavaScript structure syntax

OPEN:
- authenticated browser E2E after owner applies the surgical patch
- fresh served artifact / cache verification after deployment

### Architecture lock

Mother application:
governance/control + users + permissions + branches + vehicles + representatives + monitoring.

Standalone vouchers app:
non-order/non-runsheet stock execution:
Transfer / DirectSale / DirectReturn / SupplierReturn / Adjustment-Scrap according to existing contracts.

Van Sales:
field sales + vehicle custody + mobile inventory + offline/mobile execution.

Shared contracts, separate operational surfaces.

### Continuation instruction

Start from this checkpoint, not from Report310.

The next session must:
1. re-open CURRENT GIT and current vouchers.html;
2. verify the owner patch is present;
3. run syntax validation;
4. run authenticated browser E2E for DirectSale and DirectReturn;
5. test vehicle code + Arabic plate;
6. verify representative linkage and operational branch authorization;
7. verify CREATE Draft through existing create-stock-voucher;
8. verify no inventory movement is generated by CREATE Draft;
9. take a fresh Production snapshot;
10. only then change the closure status.

No new Edge Function.
No main.html change.
No van-sales.html change.
No parallel Physical Stock Engine.
No replay of previously closed fixes.


---
## 2026-09-22 — Report312 LATEST EXECUTION CHECKPOINT

Latest report:
doc/Draft/Reprots/Report312_WAREHOUSE_VOUCHERS_VEHICLE_PICKER_FORENSIC_EXECUTION_20260922.md

### Current authoritative Git
System HEAD:
8ddd5efed1c56f4e6dea321cc3500ae81740cbaa
Parent:
064ec25a581f4add023bdb1e1ff3fbe65a94b319

Frontend HEAD:
7a11af9ecba59da29fd6d8aad17053678d75c2e6
Parent:
ec8f2fe8ac7e8c6ac203ef2fafec520b0f05f10e

Current vouchers.html SHA:
49a32ac408c629ac22024c8a93713ea758b73197

Current van-sales.html SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

### Root cause status

PROVEN:
App.pickArr(key) structural regression + missing comma before pickShow.

The current source contains:
return allBranches;
}
pickShow:function(key)...

The required member boundary is:
return allBranches;
},
pickShow:function(key)...

The DirectReturn wsFrom element also requires the explicit closure shown in Report312.

### Vehicle search status

Vehicle search algorithm remains intact and verified:
- vehicle_code
- license_plate
- model

Do not reopen:
- vehicleBranch()
- norm()
- pickSearch()
- pickSelect()
- DirectSale vehicle filter

### Production QA retained

Persistent QA already present:
IN-24 DirectSale Draft
IN-25 DirectReturn Draft

New persistent QA created through the canonical RPC:
IN-26 DirectSale Draft
reference = QA-E2E-VEHICLE-SEARCH-DS-260922
vehicle = VCH-QA-260922
representative = vansales@rawaea.com

IN-27 DirectReturn Draft
reference = QA-E2E-VEHICLE-SEARCH-DR-260922
vehicle = VCH-QA-260922
representative = vansales@rawaea.com

Do not delete IN-24 through IN-27.

QA inventory movements = 0
QA audit rows = 4

### Fresh Production snapshot

stock_vouchers = 27
stock_voucher_details = 29
inventory_log = 26
audit_log = 2111

### Runtime deployment evidence

create-stock-voucher = v10, verify_jwt=true
send-stock-voucher = v20, verify_jwt=true
receive-stock-voucher = v22, verify_jwt=true
setup-van-branch = v4, verify_jwt=true
save-sales-invoice = v15, verify_jwt=true
save-inventory-count = v4, verify_jwt=true

No new Edge Function.
No schema change.
No RLS change.
No Physical Stock Engine change.

### Deterministic verification

PASS:
- DirectReturn candidate count = 2
- VCH-QA-260922 search
- Arabic plate س م ج 26922 search
- VEH-TEST-260921 search
- Arabic plate س ن ر 6021 search
- corrected App object syntax

OPEN:
- authenticated browser E2E after owner source patch
- fresh deployed SHA/cache verification

### Scope lock

main.html remains untouched.
vouchers.html remains untouched by automation and is awaiting owner surgical patch.
van-sales.html remains untouched.

### Next session exact sequence

1. Verify owner applied only the two Report312 surgical changes.
2. Verify fresh vouchers SHA.
3. Run syntax validation.
4. Run authenticated browser E2E for DirectReturn and DirectSale.
5. Search by vehicle_code and Arabic license plate.
6. Verify vehicle selection and representative linkage.
7. Verify branch authorization.
8. Verify CREATE Draft produces no inventory movement.
9. Take a fresh Production snapshot.
10. Only then change closure to 100% CLOSED.

Do not replay closed fixes.
Do not create a new Edge Function.
Do not touch main.html.
Do not touch van-sales.html.
Do not modify Production for this frontend parser regression unless fresh evidence proves a backend defect.
