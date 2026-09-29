# Report365 — Van Sales Forensic Core Authorization Closure
## 2026-09-29

## SELF-AUDIT — PRE-CHANGE
Business Understanding: 99/100
Architecture Understanding: 99/100
Database Understanding: 100/100
Historical Understanding: 98/100
Production Understanding: 100/100
Current Understanding: 100/100
Execution Confidence: 97/100

Confirmed Facts:
- Production has two active Direct Sales Representative → Vehicle primary assignments.
- Both assigned Direct Sales vehicles currently have driver_id = NULL.
- Production post_stock_movement previously authorized VanSale only through vehicles.driver_id.
- Current van-sales.html uses the canonical mobile branch returned by setup-van-branch and submits sales through save-sales-invoice.
- Current source contains an independently proven showRecentCustomers defect.
- Current Production RLS includes van-sales company/mobile-branch read scopes.
- Current save_sales_invoice_atomic posts VanSale through post_stock_movement and posts driver ledger only for credit VanSales.
- Current post_driver_ledger_entry stores a running balance snapshot, but existing Production rows for vansales show snapshot/sum inconsistency.

Unknowns:
- Browser-rendered E2E against the currently published frontend artifact.

Conflicts:
- Historical Report340 described vehicle.driver_id as the custody relation, while current Production Direct Sales assignments use fleet_vehicle_sales_rep_assignments and driver_id is NULL. Current Production data is authoritative.

Unverified Claims:
- None for the database authorization defect fixed in this closure.

## 1. CURRENT VAN SALES ARCHITECTURE

Canonical source:
papamohammed77-glitch/erp-frontend
companies/company-1/sales/van-sales.html
Current blob:
8d61382a8e0025a0d079e71dd94f33d106d9088e

Current frontend HEAD:
3c03e72f79bc337f89a1b27100795a522d249301
Parent:
609ab127410004ba9ee3161c8f0deaf630fbfd03

System checkpoint immediately before this closure:
864e22e2d86161851213c38631d24f986b384d64
Parent:
87a3daac27f3d2b1882f0c4883cab04ac4cc7fc0

## 2. PRODUCTION VEHICLE / REPRESENTATIVE FACTS

Production currently proves:

vansales@rawaea.com
→ public.users.id 111b0730-a977-4d11-bcd0-2427b178a9e5
→ primary assignment
→ CHV-2025-01
→ VAN-CHV-2025-01
→ mobile_stock_enabled = true
→ vehicles.driver_id = NULL

vansales2@rawaea.com
→ public.users.id cb086d71-ba61-4392-8d3d-c4bec02ec913
→ primary assignment
→ VHL-0422
→ VAN-VHL-0422
→ mobile_stock_enabled = true
→ vehicles.driver_id = NULL

No duplicate active vehicle per mobile branch was found.

## 3. ROOT CAUSE — CONFIRMED

Production post_stock_movement had:

VanSale
→ source mobile branch
→ vehicle
→ vehicle.driver_id
→ user.email

This was incompatible with the current Direct Sales assignment contract.

The authoritative current relationship is:

fleet_vehicle_sales_rep_assignments
→ vehicle_id
→ sales_rep_user_id
→ active primary assignment

Therefore current Van Sales could be structurally correct while the central physical movement engine rejected the authenticated representative.

## 4. SURGICAL PRODUCTION FIX

Updated the existing 10-argument function:

public.post_stock_movement(
  uuid,text,uuid,uuid,uuid,numeric,text,text,text,text
)

No Edge Function was created.
No frontend file was changed.

VanSale authorization now accepts exactly one of:

A. active driver relation:
vehicles.driver_id → users.email

OR

B. active Direct Sales relation:
fleet_vehicle_sales_rep_assignments
→ sales_rep_user_id
→ authenticated user email

Both paths remain company-scoped, active, and mobile-stock-enabled.

The item lookup was also hardened to require:
items.company_id = p_company_id

This prevents cross-company item resolution inside the central stock engine.

Canonical Git migration recorded:
supabase/migrations/20260929150000_van_sales_post_stock_movement_assignment_auth.sql

System Git commit:
9e70657af60814c71efb8b93e046e2001b733d0e

## 5. RUNTIME VERIFICATION

Production DB transaction test using real Direct Sales assignment:

Representative:
vansales2@rawaea.com

Vehicle/mobile branch:
VHL-0422 / VAN-VHL-0422

Item:
1003

Movement:
VanSale

Test quantity:
0.0001

Result:
VanSale authorization succeeded.

The transaction was rolled back.

Post-test verification:
QA idempotency log residue = 0
Production stock baseline unchanged.

Negative authorization test:
vansales@rawaea.com against VHL-0422 mobile branch

Result:
rejected with:
VanSale source branch must be the active mobile branch assigned to the authenticated driver or direct sales representative

No inventory log residue remained.

## 6. VAN SALES → CORE CHAIN AFTER FIX

van-sales.html
→ save-sales-invoice
→ save_sales_invoice_atomic
→ post_stock_movement
→ VAN stock

and for credit sales:

save_sales_invoice_atomic
→ post_driver_ledger_entry

The physical movement remains centralized.

## 7. CURRENT VAN SALES SOURCE — PROVEN OPEN ITEMS

The following are still genuinely open and were NOT silently closed:

### A. showRecentCustomers()
Current source:
App.showRecentCustomers() around line 1435.

It reads:
db.orders

No writer for db.orders exists in van-sales.html.

Owner-only surgical replacement remains documented in Report364.

### B. collectPayment()
Current source uses a legacy receipt payload.

Production save-receipt-voucher v7 requires:
operation_id
treasuryId
cashAccountId
offsetAccountId

The current collectPayment() payload does not supply these required fields.

Therefore collection integration remains OPEN.

### C. loadMyInvoices()/loadHomeSalesSummary()
Current source filters by created_by and date but does not explicitly constrain source='van-sales'.
Current RLS reduces exposure for the Van Sales actor, but the business query contract should still be explicit.

OPEN — separate closure unit.

### D. _loadVehicleStock()
The sold-today calculation reads the representative's orders but does not explicitly constrain source='van-sales'.

OPEN — separate closure unit.

### E. Customer patterns
loadCustomerPatterns() obtains own orders but then queries order_details without explicit order-id/company filters.
Current RLS currently scopes order_details to the representative's own orders, but the client query is broader than necessary.

OPEN — performance/clarity/security-hardening closure.

### F. End-of-day
initiateEndOfDay() is a client flow and must be reconciled with save-daily-settlement.

OPEN — separate financial/settlement closure.

### G. Driver Ledger balance integrity
Production driver_ledger has no company_id column.

For vansales:
sum(debit-credit) = 383
while the latest stored balance snapshot = 443.

For vansales2:
sum(debit-credit) = 135
while the latest stored balance snapshot = 135.

This means the Van Sales UI's current sum-based calculation is internally coherent for displayed total, but the stored running-balance field is inconsistent for vansales and can contaminate future postings because post_driver_ledger_entry starts from the latest stored balance.

This is a REAL Production data-integrity defect and requires its own controlled financial closure before modifying historical financial data.

## 8. CUSTODY / VALUE / BALANCE / VEHICLE CONTRACT

Current Production proves:

vansales:
mobile stock sales-value = 413
custody debit for IN-1 = 413

vansales2:
mobile stock sales-value = 135
custody net ledger = 135

Therefore:
- current stock value and custody debit are aligned for current direct-sale voucher loads.
- financial balance can legitimately differ from current stock value because credits/collections/returns affect the ledger.
- the REAL inconsistency is the stored driver_ledger.balance snapshot for vansales, not the separation of stock value and financial balance.

Do not change the valuation basis from sales_price to cost_price without a separate Business Contract.

## 9. PROTECTED FILES

Not modified:
- erp-frontend/companies/company-1/sales/van-sales.html
- erp-frontend/companies/company-1/warehouse/vouchers.html
- Mother main.html

No new Edge Function was created.

## 10. CURRENT STATUS

Van Sales central physical movement authorization:
CLOSED / PRODUCTION VERIFIED

Vehicle ↔ Direct Sales Representative authorization:
CLOSED / PRODUCTION VERIFIED

Company item boundary in central stock movement:
CLOSED / PRODUCTION VERIFIED

Van Sales frontend recent-customer cache:
OPEN

Van Sales collection integration:
OPEN

Van Sales source filtering:
OPEN

Customer-pattern query hardening:
OPEN

End-of-day settlement integration:
OPEN

Driver ledger balance integrity:
OPEN / REAL PRODUCTION DATA DEFECT

Browser E2E:
OPEN

## FINAL SELF-AUDIT

What I Proved
- Current production vehicle/rep assignments.
- driver_id is NULL for active Direct Sales vehicles.
- previous VanSale central authorization mismatch.
- production repair of the central authorization rule.
- positive and negative runtime behavior.
- rollback and zero QA residue.
- current van-sales source defect and additional open integrations.
- current driver_ledger arithmetic inconsistency.

What I Did Not Prove
- browser E2E against the currently deployed frontend artifact.

What I Fixed
- central VanSale authorization.
- company-scoped item resolution in post_stock_movement.

What I Initially Missed
- the central movement engine's VanSale authorization was still tied to driver_id even after Direct Sales Master Assignment became authoritative.

What Could Still Be Wrong
- frontend/browser deployment drift.
- remaining open collection/settlement/source-query contracts.
- financial impact of the historical driver_ledger snapshot inconsistency requires controlled closure.

Final Confidence:
97/100

Final Closure Status:
PARTIAL — backend authorization closure complete; Van Sales application closure remains open.
