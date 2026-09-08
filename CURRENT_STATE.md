# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report78_Main5_Final_Recheck_20260908.md
```

## GOVERNANCE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > CURRENT DEPLOYMENTS > CURRENT DATABASE CONTRACTS > VERIFIED ARTIFACTS > HISTORY > REPORTS > MEMORY > ASSUMPTIONS
UNKNOWN != BUG
UNKNOWN != REMOVE
ONE CLOSURE UNIT AT A TIME
SOURCE != RUNTIME PROOF
GIT != PRODUCTION PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

## MAIN4

```text
SOURCE = CLOSED
RUNTIME = OPEN
BLOB = e89d29e4164c68784c109292f27d4d77df240557
```

## MAIN5 — CURRENT TARGET

```text
PATH = Current/PWA/main2/main5.md
BLOB = fac9f9bf55e2ecdc27e5de3c7e44c5ef769d49b9
FULL SOURCE READ = VERIFIED 2026-09-08
RUNTIME = OPEN
```

## MAIN5 — CLOSED SOURCE PATCHES

```text
M5-15 = CLOSED BY SOURCE — _printOrder order lookup company-scoped
M5-16 = CLOSED BY SOURCE — _createRS new runsheet lookup company-scoped
M5-17-A = CLOSED BY SOURCE — ordersHtml syntax corrected
M5-17-B = CLOSED BY SOURCE — itemsHtml currency syntax corrected
M5-18 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
M5-19 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
```

`main5.md` was re-read from line 1 through EOF after the user-applied patches. The above fixes are present in the current blob. The assistant did not edit `main5.md`.

## M5-13 — OPEN CONTRACT

```text
preConfirm updates runsheets directly from the frontend and does not inspect result.error
_deleteRunsheet performs multiple independent frontend DB mutations
_cancelRunsheet performs multiple independent frontend DB mutations
no proven canonical update-runsheet capability
no proven canonical delete-runsheet capability
no proven canonical cancel-runsheet capability
DO NOT INVENT A BACKEND CONTRACT
```

This remains the only blocker preventing main5 from being authorized for the next part.

## PRODUCTION TRUTH — 2026-09-08

```text
companies      = 1
app_settings   = 1
users          = 24
branches       = 2
items          = 17
orders         = 0
runsheets      = 0
order_details  = 0
run_sheet_details = 0
stock_rows     = 20
inventory_logs = 3
currency       = SAR
```

Schema facts:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
order_details has NO company_id
run_sheet_details has NO company_id
```

RLS facts relevant to main5:

```text
orders = authenticated SELECT only
runsheets = company-aware SELECT/INSERT/UPDATE/DELETE
order_details = current-tenant SELECT
run_sheet_details = current-tenant SELECT
users = company-aware
vehicles = company-aware SELECT
app_settings = company-aware
```

## PRODUCTION REALTIME — FOUNDATION CLOSED

Publication includes:

```text
app_settings
order_details
orders
run_sheet_details
runsheets
```

All five use `REPLICA IDENTITY FULL`.

Migrations:

```text
20260908010304 = enable_realtime_orders_runsheets_fulfillment
20260908010601 = add_app_settings_realtime_currency_contract
```

Browser realtime E2E remains unverified because Production has zero orders and zero runsheets.

## PRODUCTION EDGE — CURRENT RELEVANT DEPLOYMENTS

```text
create-runsheet = ACTIVE v26
complete-return = ACTIVE v25
complete-order-delivery = ACTIVE v14
create-stock-voucher = ACTIVE v10
send-stock-voucher = ACTIVE v20
receive-stock-voucher = ACTIVE v22
complete-stock-voucher = ACTIVE v4
cancel-stock-voucher = ACTIVE v4
receive-purchase = ACTIVE v12
```

## PRODUCTION INVENTORY / DATA GOVERNANCE

The current Production schema confirms `items.item_code` is globally unique. This is the current global Item Master contract; therefore a branch/company-to-item metadata mismatch must not be classified as a defect merely from company_id inequality without tracing the established global-item contract.

## WHAT IS PROVEN — 2026-09-08 RECHECK

```text
MASTER reviewed
Report77 reviewed
CURRENT_STATE reviewed
main5 read from first line to EOF
main5 current blob = fac9f9bf55e2ecdc27e5de3c7e44c5ef769d49b9
M5-15 present
M5-16 present
M5-17-A present
M5-17-B present
M5-18 present
M5-19 present
main4 boundary reviewed
main6 boundary reviewed
Production schema reviewed
Production Edge Function inventory reviewed
Production Realtime foundation reviewed
M5-13 direct frontend mutation defect re-confirmed
Report78 written
```

## WHAT IS NOT PROVEN

```text
main5 browser runtime
Realtime browser E2E with actual order/runsheet records
11-part final assembly
full PWA runtime equivalence
M5-13 canonical backend mutation owner
final Production equivalence of assembled PWA
```

## NEXT AUTHORIZED ACTION

```text
DO NOT move to main6 yet.
Close M5-13 first using a proven backend capability and the historical/current lifecycle contract.
Then re-read main5 to EOF.
Then syntax + structure + consumers + Production reconciliation again.
Only then authorize continuation to the next part.
```

## LAST VERIFIED EVENT

```text
EVENT TYPE = MAIN5 POST-PATCH FINAL FORENSIC RECHECK
UTC DATE = 2026-09-08
MAIN5 BLOB = fac9f9bf55e2ecdc27e5de3c7e44c5ef769d49b9
RESULT = M5-15..M5-19 verified in current source; M5-13 remains the sole demonstrated blocker
PRODUCTION = companies=1, users=24, branches=2, items=17, orders=0, runsheets=0, stock_rows=20, inventory_logs=3, currency=SAR
REPORT = doc/Draft/Reprots/Report78_Main5_Final_Recheck_20260908.md
```
