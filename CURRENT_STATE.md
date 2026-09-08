# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report77_Main5_PostPatch_Forensic_Recheck_20260908.md
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
BLOB = 34182a5a2380a0b4704503a964af07b92982b86f
FULL SOURCE READ = VERIFIED 2026-09-08
RUNTIME = OPEN
```

Report76 patches present in current source:

```text
M5-01 = PRESENT
M5-02 = PRESENT
M5-03 = PARTIAL — company filter exists; full realtime coverage still required
M5-04..M5-12 = PRESENT
M5-14 = PRESENT — currency comes from app_settings
```

New open source issues found after reread:

```text
M5-15 = _printOrder order lookup not company-scoped
M5-16 = _createRS new runsheet lookup not company-scoped
M5-17-A = syntax error in ordersHtml currency concatenation
M5-17-B = syntax error in itemsHtml currency concatenation
M5-18 = orders realtime subscription incomplete
M5-19 = runsheets realtime subscription missing
```

Assistant MUST NOT edit main5. User performs the mother-file edits.

## M5-13 — OPEN CONTRACT

```text
_deleteRunsheet and _cancelRunsheet perform direct frontend DB writes
orders has no authenticated UPDATE/DELETE policy
no proven delete/cancel backend owner established
DO NOT INVENT A BACKEND CONTRACT YET
```

## PRODUCTION TRUTH — 2026-09-08 01:07 UTC

```text
companies      = 1
app_settings   = 1
users          = 24
branches       = 2
items          = 17
orders         = 0
runsheets      = 0
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

RLS facts:

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

## PRODUCTION EDGE — append-to-runsheet

```text
VERSION = 7
STATUS = ACTIVE
VERIFY_JWT = true
```

Fixed the invalid `order_details.company_id` predicate. Git source aligned with deployed v7.

## create-runsheet

```text
VERSION = 26
VERIFY_JWT = true
OWNER = create_runsheet_atomic
```

## WHAT IS PROVEN

```text
MASTER read to EOF
Report76 read
CURRENT_STATE stale state detected
main5 read to EOF
current main5 blob verified
Report76 changes rechecked
Production snapshot verified directly
Realtime publication verified directly
Replica identity verified directly
append-to-runsheet corrected and redeployed v7
create-runsheet owner verified
currency = SAR verified directly
Report77 written
```

## WHAT IS NOT PROVEN

```text
main5 source closure
main5 browser runtime
11-part final assembly
full PWA runtime equivalence
Realtime browser E2E with actual order/runsheet records
_deleteRunsheet contract
_cancelRunsheet contract
final Production equivalence of assembled PWA
```

## NEXT AUTHORIZED ACTION

```text
User applies exact M5-15..M5-19 blocks from Report77 to main5
Commit main5 and return commit/blob SHA
Then full EOF recheck + syntax + dependency + Production reconciliation
Then continue integration/runtime verification
```

## LAST VERIFIED EVENT

```text
EVENT TYPE = MAIN5 POST-PATCH FORENSIC RECHECK + PRODUCTION REALTIME INTEGRATION
UTC = 2026-09-08 01:07:16+00
MAIN5 BLOB = 34182a5a2380a0b4704503a964af07b92982b86f
PRODUCTION = companies=1, users=24, branches=2, items=17, orders=0, runsheets=0, stock_rows=20, inventory_logs=3, currency=SAR
RESULT = Production realtime foundation closed; append-to-runsheet v7 corrected; main5 remains open for exact user surgical patches M5-15..M5-19
EVIDENCE = current Git + direct Production SQL + active Edge Function deployment + Report77
```
