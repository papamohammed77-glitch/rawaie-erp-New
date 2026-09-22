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
6693d1c55c6b35314f18ddde63afe3613d59833c
Parent:
fd3db8ded40dbb680f0dc0abe036ae3804d4c962

### Frontend repository
Repository: papamohammed77-glitch/erp-frontend
HEAD observed:
56d0afea626cb83ac8445cb887e775adc266622
Current vouchers.html blob:
d69eb86aef42ab654cae4cc34479ac494e5531f2

Latest forensic report:
doc/Draft/Reprots/Report309_WAREHOUSE_VEHICLE_PICKER_FORENSIC_CLOSURE_20260922.md

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

Main operational branch:
BR-01
id = a38332b6-6cea-480a-ada1-6eb6ab0590db

Persistent QA vehicle:
vehicle_code = VCH-QA-260922
license_plate = س م ج 26922
status = Active
mobile_stock_enabled = true
mobile_branch_code = VAN-VCH-QA-260922
driver = vansales@rawaea.com

Persistent QA vouchers:
- IN-24 — DirectSale — Draft — QA-SMART-VEHICLE-DS-260922
- IN-25 — DirectReturn — Draft — QA-SMART-VEHICLE-DR-260922

Persistent QA operation identities:
- QA-OP-DS-260922
- QA-OP-DR-260922

QA audit rows = 2
QA inventory movements = 0

Do not delete these QA records.

## 5. Root cause
The vehicle regression was introduced in App.pickArr() when vehicle candidates became dependent on:
s.allowedBranch(s.user, vehicleBranch)

The vehicle mobile branch is the vehicle's stock custody location, not the operator's operational branch authorization.

Production reality:
user operational branch = BR-01
vehicle mobile branch = VAN-VCH-QA-260922

Therefore the current candidate filter returned zero vehicles before pickSearch() executed.

The defect is upstream candidate pruning, not:
- norm()
- pickSearch()
- vehicleBranch()
- loadRefs()
- pickSelect()
- Production vehicle validation
- Production custodian validation

## 6. Production backend contract
Verified:
- create_manual_stock_voucher_atomic(..., p_rep_id, p_operation_id)
- create_manual_stock_voucher_atomic_core_12_20260828
- enforce_stock_voucher_custodian
- fn_vehicle_context_guard

DirectSale:
Branch → Vehicle
Vehicle must belong to company, be Active, mobile-stock-enabled and belong to the selected direct-sales representative.
Representative must be authorized for source operational branch.

DirectReturn:
Vehicle → Branch
Vehicle must belong to company, be Active, mobile-stock-enabled and have a valid mobile branch.
Destination branch remains the operational authorization boundary.

No Production backend change is required for this regression.

## 7. Surgical owner patch
File:
erp-frontend/companies/company-1/warehouse/vouchers.html

Only the DirectReturn vehicle candidate block inside App.pickArr() is to change.

### DirectReturn
Inside:
if(key==='wsFrom'){ ... if(s.type==='DirectReturn'){ ... }

Remove the mobile-branch user/representative authorization gate and use:

return v.status==='Active' &&
       !!vb &&
       (
           !rep ||
           (s.refs.branches||[]).some(function(branch){
               return s.allowedBranch(s.user,branch) &&
                      s.allowedBranch(rep,branch);
           })
       );

Do not change vehicleBranch(), pickSearch(), pickSelect(), loadRefs(), submit(), main.html or van-sales.html.

## 8. Verification
Deterministic JavaScript E2E using Production-like current data:
PASS
- DirectReturn vehicle candidates
- DirectReturn vehicle-code search
- DirectReturn Arabic license-plate search
- DirectReturn selection
- DirectSale vehicle candidates
- DirectSale Arabic license-plate search

Production canonical RPC creation of IN-24 and IN-25:
PASS

Production vehicle/custodian contract:
VERIFIED

Authenticated browser E2E:
OPEN
The browser harness exceeded the execution window; this must not be converted to PASS.

## 9. Architecture
Mother application:
- governance/control
- users/permissions
- branches
- vehicles
- representatives
- monitoring/reporting

Standalone vouchers application:
- non-order/non-runsheet stock operations
- Transfer
- DirectSale
- DirectReturn
- SupplierReturn
- Adjustment/Scrap by existing contract

Van Sales:
- field sales
- customer execution
- vehicle mobile stock
- offline/mobile workflow

Shared business contracts, not shared screens.

## 10. Closed work not to reopen
Do not reopen:
- Arabic norm repair
- branch directory repair
- export/select repair
- mobile_branch canonicalization
- voucher operation identity
- voucher audit hardening
- post_stock_movement centralization
- DirectReturn mobile branch convergence

## 11. Competitive gaps identified, not implemented in this closure
Potential future contract-backed work:
- stock before/after visibility
- barcode-first execution
- advanced filters by vehicle/representative/source/destination/status/date
- print/PDF
- attachments after approved storage/audit contract
- lot/batch/expiry/serial after separate business contract
- mobile custody dashboard

These are separate closure units.

## 12. Final status
PRODUCTION CONTRACT VERIFIED
SURGICAL PATCH READY
PERSISTENT QA RETAINED
DETERMINISTIC E2E PASS
AUTHENTICATED BROWSER E2E OPEN
100% CLOSED = NO

## 13. Next session start
1. Open CURRENT GIT.
2. Open current vouchers.html after owner applies the one DirectReturn vehicle-only surgical element.
3. Run authenticated browser E2E for DirectSale and DirectReturn.
4. Search by vehicle code and Arabic plate.
5. Verify vehicle selection, representative linkage, source/destination authorization.
6. Verify create Draft through existing create-stock-voucher.
7. Verify CREATE does not create inventory_log movement.
8. Only after browser E2E PASS, update this state to 100% CLOSED.

No main.html change.
No van-sales.html change.
No new Edge Function.
No parallel stock engine.

---
## 2026-09-22 — Report310 CURRENT SOURCE REGRESSION CHECKPOINT

System HEAD now:
6b6a37ab3bd6473d14d2c13e3ef89d279d1eeaa2
Parent:
79c43c6582d697c1282bf02d5e804572384f9546

Frontend HEAD now:
78ecba3fd0e1adfa3af0249dc6bf1b7d80984c40
Parent:
bf88f28e33b789b4822f2dd2b7ec025827a8c54a

Current vouchers.html SHA:
712f717c818819c5d5d9afba843465c7ae892672

Current latest forensic report:
doc/Draft/Reprots/Report310_WAREHOUSE_VEHICLE_PICKER_CURRENT_SOURCE_REGRESSION_CLOSURE_20260922.md

### New verified finding
Current vouchers.html is syntactically invalid inside App.pickArr() DirectReturn.
The exact Current Source block has:
- an unclosed vehicles filter
- an unclosed DirectReturn branch
- parser failure: missing ) after argument list

Git chain proves:
bf88f28... introduced the malformed structure.
78ecba3... removed an additional brace in the wrong location.
The current DirectSale vehicle block already contains the intended functional correction and is not reopened.

### Production snapshot
UTC:
2026-09-22 18:34:13.135197+00

Counters:
- stock_vouchers = 25
- stock_voucher_details = 27
- inventory_log = 26
- audit_log = 2109
- vehicles = 2
- active company branches = 4

Persistent QA remains:
- VCH-QA-260922
- IN-24 DirectSale Draft
- IN-25 DirectReturn Draft
- zero QA inventory movements

### Production decision
No Production schema change required.
No RLS change required.
No user permission change required.
No new Edge Function required.
Current create-stock-voucher v10 and current voucher RPC contract remain aligned with this fix.

### Exact owner action
File:
companies/company-1/warehouse/vouchers.html

Function:
App.pickArr(key)

Target:
if(key==='wsFrom'){
→ if(s.type==='DirectReturn'){

Find:
return (s.refs.vehicles||[]).filter(function(v){

Delete only that malformed DirectReturn vehicle element until before:
if(key==='wsRep'){

Replace with the complete element stored in Report310.

Do not modify:
- DirectSale vehicle block
- vehicleBranch()
- pickSearch()
- pickSelect()
- norm()
- main.html
- van-sales.html

### Verification
Current malformed source reproduced:
FAIL — SyntaxError: missing ) after argument list

Corrected DirectReturn element:
PASS — JavaScript syntax

Deterministic vehicle E2E:
PASS
- DirectReturn candidate count = 1
- DirectReturn vehicle code search = 1
- DirectReturn Arabic plate search = 1
- DirectReturn selection = PASS
- DirectSale candidate count = 1
- DirectSale vehicle code search = 1
- DirectSale Arabic plate search = 1

Authenticated Browser E2E:
OPEN

### Continuation rule
Do not declare 100% CLOSED until:
Owner patch applied
+
Current frontend SHA reverified
+
Browser E2E PASS
+
Fresh Production snapshot
+
State updated

Next exact task:
Verify the owner-applied DirectReturn block, run browser E2E for both DirectReturn and DirectSale, then close this closure unit.