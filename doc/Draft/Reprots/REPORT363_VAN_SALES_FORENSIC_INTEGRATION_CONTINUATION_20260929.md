# REPORT363 — VAN SALES FORENSIC INTEGRATION CONTINUATION
## 2026-09-29

## SELF-AUDIT — PRE/POST EXECUTION
- Business Understanding: 99/100
- Architecture Understanding: 99/100
- Database Understanding: 100/100
- Historical Understanding: 98/100
- Production Understanding: 100/100
- Current Understanding: 100/100
- Execution Confidence: 98/100
- Confirmed Facts: 12+
- Unknowns: 1
- Conflicts: 0 material
- Unverified Claims: 2 (browser-rendered Van Sales UI; full owner-applied frontend patch)

Historical Opened: YES
Original Opened: YES
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

## 1. SCOPE
Closed the current forensic unit around:
- Van Sales standalone application
- Production data-read integration
- Mobile branch / direct-sales-rep identity
- Sales, inventory count, customer, invoice and collection consumers
- Central Inventory boundary preservation

No new Edge Function was created.

## 2. SOURCE / CURRENT STATE
Canonical frontend:
companies/company-1/sales/van-sales.html
Current blob SHA:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Latest frontend commits inspected:
- 50d769a871dc595dfe2520186eb8a10952d56b4c — printVoucher refactor
- 1214f6bca0d5f851bec2be8bd3d466b4af758efd — vouchers refactor
- 36e521f78c8507e431bb9eb780269612c2d6cbf0 — Van Sales tenant/offline/operation-identity forensic closure

Relevant system closure history:
- 9542abdfc5cbd521e7bdd94bb1f5d4dc63ce4c16 — Report340, Direct Sales Rep ↔ Vehicle Master Assignment closure

## 3. CONTRACT CONFIRMATION
The standalone Van Sales application is a direct-sales/mobile-stock client:
- direct customer sale from vehicle/mobile stock
- customer search and customer history
- mobile stock visibility
- quick inventory count
- collection/receipt workflow
- invoice workflow
- vehicle/mobile branch discovery through setup-van-branch

It is not a Runsheet/Picking/Loading application.

## 4. PRODUCTION FORENSIC DEFECT FOUND
Before the repair, the authenticated direct-sales user could authenticate successfully but the application's direct Supabase reads returned zero rows because existing RLS policies required:
- customers permission for customers
- items/warehouse permission for items
- branches/warehouse permission for branches
- warehouse/runsheets/reports for stock_branches
- orders/runsheets/warehouse/reports for orders
- equivalent restrictions on order_details

The real direct-sales user has permission:
van-sales
and not those unrelated warehouse/order permissions.

Authenticated RLS simulation reproduced:
customers=0
items=0
branches=0
stock_branches=0
orders=0
order_details=0

This is a real Production integration defect, not a theoretical finding.

## 5. PRODUCTION REPAIR ACTUALLY APPLIED
Two Production migrations were applied.

### A. van_sales_read_scope_integration_v1
Added company-scoped SELECT access for authenticated users with van-sales on:
- customers
- items
- branches
- stock_branches
- orders (own orders)
- order_details (own-order lines)

### B. van_sales_mobile_branch_rls_helper_v2
Added:
app_private.current_user_mobile_branch_id()

This resolves the authenticated direct-sales user to the active primary vehicle assignment and its canonical mobile branch.

Branches and stock_branches are limited to that assigned mobile branch.

No Business Movement was introduced.

No stock write was introduced.

No new Edge Function was introduced.

## 6. POST-REPAIR PROOF
Authenticated RLS simulation for:
vansales@rawaea.com
with its real auth identity and company context produced:

- customers visible: 3
- items visible: 17
- branches visible: 1
- vehicle stock rows visible: 16
- own orders visible: 0
- order_details visible: 0

The zero own-orders result is consistent with there being no orders created by that user in the current Production data; it is not treated as a defect.

The assigned Production Master relationship is present:
vansales@rawaea.com
→ CHV-2025-01
→ VAN-CHV-2025-01

## 7. EDGE FUNCTION / CORE DEPENDENCY CHECK
Production functions directly serving Van Sales were re-read:

- setup-van-branch v5 — active, JWT protected, direct-sales master-assignment aware
- save-sales-invoice v15 — active, JWT protected
- save-inventory-count v5 — active, JWT protected, direct-sales vehicle lookup supported
- save-receipt-voucher v7 — active, JWT protected

Privilege check confirmed:
- save_sales_invoice_atomic: authenticated EXECUTE = false; service_role EXECUTE = true
- setup_van_stock: authenticated EXECUTE = false; service_role EXECUTE = true
- inventory_count_engine: authenticated EXECUTE = false; service_role EXECUTE = true

This preserves the Edge → service-role Core boundary.

## 8. CENTRAL INVENTORY CONTRACT PRESERVED
Van Sales physical movement remains delegated to:
save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement

Quick inventory remains delegated to:
save-inventory-count
→ inventory_count_engine

No direct client-side mutation of stock_branches or inventory_log was introduced by this repair.

## 9. ADDITIONAL FRONTEND DEFECT FOUND
Forensic source scanning of the current Van Sales file found:

showRecentCustomers()
reads:
db.orders.orderBy('created_at')

but no:
db.orders.put / bulkPut / add / update

exists anywhere in van-sales.html.

Therefore the "recent customers" local-cache feature has a real source-level completeness defect: the store is read but not populated by this application.

This was not changed in this unit because the file is owner-controlled and the current task explicitly requires protected frontend files to remain untouched unless a surgical owner-applied patch is authorized.

Recommended surgical owner patch:
replace the data source inside showRecentCustomers() with the already-maintained db.myCustomers store, or explicitly populate db.orders after successful sale. The choice must follow the historical contract; do not invent a second cache source.

## 10. COMPETITIVE GAP STATUS
The application already contains several competitive mobile-sales capabilities:
- mobile stock view
- quick inventory
- customer search
- quick sale
- previous invoice/repeat-order
- customer purchasing patterns
- forgotten-item prompts
- map view
- collection/balance view
- offline startup fallback

Remaining competitive enhancements are separate backlog items and were not mixed into the current defect closure:
- stronger barcode-first workflow
- richer visit/route workflow
- explicit customer-visit/activity history
- stronger offline queue/sync visibility
- line-level inventory before/after audit presentation
- richer promotion/price explanation
- exception/shortage workflows
- advanced analytics and target execution

These are not required to fix the Production integration defect found here.

## 11. CURRENT CLOSURE STATUS
### Production integration foundation
CLOSED / PROVEN

### Mobile branch identity
PROVEN

### Edge/Core dependency boundary
PROVEN

### Van Sales source artifact
PRESENT / REVIEWED

### Frontend "recent customers" completeness
OPEN — source defect found

### Browser-rendered E2E
OPEN — not independently automated in this session

### Global Van Sales 100% Closure
NOT CLAIMED

## 12. SESSION DECISION
Do not reopen:
- main.html
- warehouse/vouchers.html
- previously closed DirectReturn patches

Do not create new Edge Functions.

The next Van Sales closure action is the surgical owner-applied fix for showRecentCustomers(), followed by browser E2E and regression verification.

## FINAL SELF-AUDIT
### What I Proved
Production RLS was blocking the standalone Van Sales application; the defect was reproduced with authenticated-context simulation and repaired in Production. The repair now exposes exactly the company/customer/catalog/mobile-branch data required by the existing application contract.

### What I Did Not Prove
I did not perform a browser-rendered, human click E2E session. I also did not modify the protected Van Sales frontend source in this unit.

### What I Fixed
Production read authorization for the existing Van Sales client contract, including canonical mobile-branch scoping.

### What I Initially Missed
The existing Van Sales source contains a separate local-cache defect in showRecentCustomers(): it reads db.orders without this application populating that store.

### What Could Still Be Wrong
Additional frontend UX defects may remain outside the inspected paths; those must be handled as separate surgical closure units.

### Final Confidence
96/100

### Final Closure Status
OPEN — Production integration repaired; one confirmed frontend source defect and browser E2E remain.
