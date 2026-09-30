# تقرير 378 — التحقيق الجنائي الفعلي وتحديد الحالة الحالية لتطبيق VAN SALES
## 2026-09-30

## 1. SELF-AUDIT — PRE-CHECK

Business Understanding: 99/100
Architecture Understanding: 100/100
Database Understanding: 100/100
Historical Understanding: 99/100
Production Understanding: 100/100
Current Source Understanding: 100/100
Execution Confidence: 99/100

Confirmed Facts: 12
Unknowns: 1
Conflicts: 1
Unverified Claims: 1

Historical Opened: YES
Original Opened: YES / baseline family
Production Opened: YES
Current Opened: YES
Schema Checked: YES
Triggers Checked: YES
Dependencies Checked: YES
Consumers Checked: YES

---

# 2. CURRENT REALITY — VERIFIED FROM SOURCES

## Frontend source of truth

Repository:
papamohammed77-glitch/erp-frontend

File:
companies/company-1/sales/van-sales.html

Latest commit:
c67de5a0b601e2cc0690bf40c32d46632140f95e

Parent:
e5f3e8ed0e2a491a243bce0029aeb2e73cc824dc

Current blob SHA:
012fba212bc2ecf0d21a8990fca76190c27701f8

Current size:
3295 lines
151087 characters

Current JavaScript parse:
FAIL

Exact error:
Unexpected token ')'

The parser failure was reproduced directly with V8 against the current source.

---

# 3. ROOT CAUSE — CONFIRMED

The defect is inside:

App.loadCustomerPatterns()

Current location:
approximately line 499 through line 583.

The malformed tail is:

    .then(function(patterns) {
        if (db && db.customerPatterns) {
            return db.customerPatterns.clear().then(function() {
                return db.customerPatterns.bulkPut(patterns);
            });
        }
    });
        }).catch(function() {});

    },

The second closing sequence is unmatched.

The exact problematic sequence was introduced by commit:

e5f3e8ed0e2a491a243bce0029aeb2e73cc824dc

The next commit:

c67de5a0b601e2cc0690bf40c32d46632140f95e

changed repeatOrder and initiateEndOfDay but did not repair this syntax defect.

This explains:

van-sales:583 Uncaught SyntaxError: Unexpected token ')'

and consequently:

App is not defined

The browser cannot finish evaluating the main script, so the App object is never created.

---

# 4. PROOF BY PARENT COMPARISON

Previous parent:

74b122f9c2721178f27dd8f495cfd61134bb5399

parses successfully.

Commit:

e5f3e8ed0e2a491a243bce0029aeb2e73cc824dc

fails parsing.

Latest commit:

c67de5a0b601e2cc0690bf40c32d46632140f95e

also fails parsing.

Therefore this is a source regression, not a browser/network interpretation.

---

# 5. SURGICAL FIX — OWNER ACTION

Protected frontend rule applies.

Do not rewrite the whole file.
Do not modify picker.html.
Do not modify main.html.
Do not modify warehouse/vouchers.html.

Delete only the malformed sequence:

    });
        }).catch(function() {});

Replace it with exactly:

    })
        .catch(function() {});

This minimal replacement was independently parsed in V8 and returned:

PASS

---

# 6. IMPACT

Because of the syntax error, App is undefined at runtime.

Therefore the following cannot execute from this source:

- login/application initialization
- Van Sales navigation
- customer views
- invoice views
- vehicle custody
- balance view
- quick sale
- quick inventory
- map
- account
- repeatOrder
- initiateEndOfDay

This does not prove every deployed frontend is serving this exact Git HEAD; it proves the current Git source itself is broken.

---

# 7. CURRENT APPLICATION STRUCTURE — VERIFIED

Current contains 65 App methods plus global resolveCustomer.

Historical baseline contains 65 App methods plus _createVanBranch, making 66 named App methods.

The missing _createVanBranch responsibility is delegated to setup-van-branch.

Primary views:

- الرئيسية
- عملائي
- فواتيري
- رصيدي
- سيارتي
- الخريطة
- حسابي

Operational capabilities include:

- بيع سريع
- جرد سريع
- إقفال الوردية
- تحصيل العميل
- إعادة الطلب
- متابعة العهدة
- المؤشرات

---

# 8. CURRENT FUNCTIONS ALREADY CORRECT — DO NOT REWORK

Verified in latest Git:

- syncDown company context
- setup-van-branch integration
- loadMyCustomers customer-account RPC integration
- loadCustomerPatterns company/source/order scoping
- loadKPIs company/source scoping
- loadHomeSalesSummary company/source scoping
- loadMyInvoices company/source scoping
- collectPayment pending operation cleanup
- showCustomerDetail customer-account RPC
- submitQuickSale -> save-sales-invoice v15
- submitQuickInventory -> save-inventory-count v5
- canonical VAN stock reading

Do not rewrite these without new direct evidence.

---

# 9. RECENT c67 CHANGES — VERIFIED

The latest commit correctly changed:

## App.repeatOrder()

It now scopes by:
- order id
- company_id
- source='van-sales'

It checks Supabase errors and uses cRes.data for the customer.

## App.initiateEndOfDay()

It now connects the UI toward:
save-daily-settlement
-> post_daily_settlement_atomic

and persists operation identity for safe retry.

These changes are not the current parse failure.

---

# 10. PRODUCTION BACKEND — VERIFIED

Production project:
fiilmooggumokxanwiyx

Verified:
setup-van-branch v5 ACTIVE
save-sales-invoice v15 ACTIVE
save-receipt-voucher v8 ACTIVE
save-inventory-count v5 ACTIVE
save-daily-settlement v4 ACTIVE

Verified Core:
post_van_sales_collection_atomic
post_daily_settlement_atomic
get_van_sales_customer_accounts
get_van_sales_customer_account

Production runsheets include:
company_id
runsheet_code
driver_id
vehicle_id
status
picking/loading/delivery/return timestamps
loading_cycle_id
picking_reservation_released

Production settlement Edge v4 derives company context from authenticated public.users.auth_id and calls post_daily_settlement_atomic.

---

# 11. INVENTORY RESCUE INTEGRATION

Van Sales remains aligned with the central Inventory Rescue contract:

Van Sale
-> save-sales-invoice
-> save_sales_invoice_atomic
-> post_stock_movement
-> canonical VAN stock branch

Reservation remains separate.

setup-van-branch remains identity/initialization.

Van Sales must not create another Physical Stock Engine.

---

# 12. COMPETITOR PRINCIPLES

- Dynamics 365 models technician trucks as inventory locations/warehouses and supports warehouse-to-truck inventory transfer with on-hand/available/allocated quantities. This supports RAWAEA's mobile VAN stock model. Sources: Microsoft Learn on inventory warehouses and inventory transfers. 
- SAP Direct Store Delivery treats van sales as a combined sales/logistics process with backend customer/material/vehicle/driver/route data. Source: SAP Help Portal Van Sales.
- Daftra centralizes sales, inventory, accounting and mobile-store workflows and supports online/offline mobile operation. Sources: Daftra ERP, Mobile Store and Mobile Apps.
- Manager supports receipts allocated against customer statements/invoices, reinforcing separation of sale from collection. Source: Manager guide.

These are benchmark principles only; RAWAEA's field workflow remains its own contract.

---

# 13. OPEN WORK — ORDERED

## Unit 0 — PARSE RESTORATION
Status: OPEN

Apply the exact two-line surgical replacement in section 5.

## Unit 1 — BROWSER E2E
After parsing is restored:
login -> syncDown -> vehicle -> customers -> invoices -> balance -> quick sale -> quick inventory -> collection -> repeatOrder -> EOD

## Unit 2 — FINANCIAL EOD CLOSURE
Prove:
Delivered/Returned runsheet
-> settlement
-> daily_settlements
-> driver liabilities
-> shortage journal when applicable
-> runsheet Closed

## Unit 3 — GLOBAL VAN SALES CONTRACT CLOSURE
Continue the existing closure order; do not reopen closed units without new evidence.

---

# 14. OWNER ACTION REQUIRED NOW

File:
companies/company-1/sales/van-sales.html

Function:
App.loadCustomerPatterns()

Exact defective element:
    });
        }).catch(function() {});

Exact replacement:
    })
        .catch(function() {});

Then reload with cache bypass.

Expected:
- SyntaxError disappears.
- App is defined.
- Van Sales can initialize.

---

# 15. FINAL JUDGMENT

Current Git source is not production-ready because it does not parse.

The backend Van Sales foundation is substantially present and Production-deployed.

The recent refactors did not justify rewriting the application.

The immediate crisis is a surgical frontend syntax regression.

No Production DB mutation is required for this syntax defect.
No new Edge Function is required.
No new RPC is required.
No main.html modification is required.

---

# 16. SELF-AUDIT — FINAL

What I Proved:
- Current frontend HEAD is c67de5a0...
- Current source fails V8 parsing.
- Parent 74b122 parses.
- Exact unmatched closure is at the end of loadCustomerPatterns.
- c67 did not repair it.
- repeatOrder and initiateEndOfDay are present in latest source.
- Required Production backend functions exist and are active.

What I Did Not Prove:
- That the live hosted frontend currently serves c67de5a...; no hosting deployment artifact was available in the inspected sources.

What I Fixed:
- No protected frontend file was modified.
- Corrected syntax block was independently validated.

What I Initially Missed:
- Previous forensic closure did not re-run a full-script parse after c67.

What Could Still Be Wrong:
- Additional browser/runtime defects may appear only after the syntax error is removed.

Final Confidence:
99/100 for the identified syntax root cause.

Final Closure Status:
INCOMPLETE — exact surgical owner patch + browser E2E remain.
