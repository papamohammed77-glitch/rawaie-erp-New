# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report80_Main5_M5-13_Source_Reconciliation_20260908.md
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
BLOB = 9f9926511c47f0295019daaf09ff4b5a1a2efc50
FULL SOURCE READ = VERIFIED 2026-09-08
RUNTIME = OPEN
```

## MAIN5 — VERIFIED CLOSED SOURCE PATCHES

```text
M5-15 = CLOSED BY SOURCE
M5-16 = CLOSED BY SOURCE
M5-17-A = CLOSED BY SOURCE
M5-17-B = CLOSED BY SOURCE
M5-18 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
M5-19 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
M5-13-A = SOURCE VERIFIED / APPLIED
M5-13-B = SOURCE VERIFIED / APPLIED
M5-13-C = SOURCE VERIFIED / APPLIED
```

## M5-13 — BACKEND + SOURCE ROUTING

Production canonical capability:

```text
RPC = public.manage_runsheet_atomic
OPERATIONS = UPDATE / CANCEL / DELETE
SECURITY = SECURITY DEFINER
DIRECT EXECUTE = postgres + service_role
anon EXECUTE = NO
authenticated EXECUTE = NO
EDGE = manage-runsheet v1 ACTIVE
VERIFY_JWT = true
```

Source verification:

```text
main5 preConfirm -> manage-runsheet UPDATE
main5 _deleteRunsheet -> manage-runsheet DELETE
main5 _cancelRunsheet -> manage-runsheet CANCEL
Direct M5-13 runsheets/orders/run_sheet_details writers in main5 = 0
```

## M5-13 PRODUCTION CONTRACT

```text
UPDATE only Open/Confirmed; preserve current status
UPDATE validates driver and vehicle company scope
CANCEL only Open/Confirmed
DELETE only Open/Confirmed
CANCEL/DELETE reject Orders outside Pending/Confirmed
CANCEL/DELETE reject fulfillment quantities or driver liability already posted
CANCEL => Orders Confirmed + runsheet_id NULL + details deleted + Runsheet Cancelled
DELETE => Orders Confirmed + runsheet_id NULL + details deleted + Runsheet deleted
ALL MUTATIONS = ONE DATABASE TRANSACTION
```

## M5-20 — CURRENT OPEN SOURCE DEFECT

Full-file reconciliation found a real Consumer/Backend contract drift:

```text
main5 UI currently offers DELETE for Invoiced orders
Production delete-order v8 officially rejects Invoiced
Production accepts deletion only for Draft / Confirmed / Pending
```

Therefore:

```text
M5-20-A = OPEN
M5-20-B = OPEN
M5-20-C = OPEN
```

Required source corrections are documented exactly in:

```text
doc/Draft/Reprots/Report80_Main5_M5-13_Source_Reconciliation_20260908.md
```

No Production change is required for M5-20 because the backend guard is already correct.

## PRODUCTION CURRENT SNAPSHOT

```text
companies=1
users=24
branches=2
items=17
orders=0
runsheets=0
order_details=0
run_sheet_details=0
stock_branches=20
inventory_log=3
```

## PRODUCTION REALTIME / TENANT CHECK

```text
orders SELECT = company scoped
runsheets SELECT/UPDATE/DELETE policies = company scoped
order_details SELECT = tenant scoped through orders
run_sheet_details SELECT = tenant scoped through runsheets
```

The absence of a direct `company_id` filter on `order_details` / `run_sheet_details` Realtime subscriptions is not currently classified as a defect because those tables are tenant-protected through their parent relations and no evidence of cross-tenant exposure was found.

## MASTER CONTINUITY FILES VERIFIED THIS SESSION

```text
MASTER - RAWAEA ERP FORENSIC CONTINUITY GOVERNANCE v2.md = READ TO EOF
MASTER - RAWAEA ERP - UNIFIED CONTINUITY & MAIN1 EXECUTION.md = READ TO EOF
MASTER - RAWAEA ERP.md = READ TO EOF
```

## GIT LAST VERIFIED EVENT

```text
COMMIT = bf87eac7b1623058402db1495114dd4523ebe92d
DATE = 2026-09-08T02:22:34Z
MESSAGE = Refactor runsheet management with async/await
TARGET = Current/PWA/main2/main5.md
RESULT = M5-13-A/B/C source routing applied
```

## REPORTS

```text
Report79 = backend closure + exact M5-13 source instructions
Report80 = current source reconciliation + M5-20 contract drift discovery
```

No previous report was deleted.

## FINAL STATE FOR THIS SESSION

```text
M5-13 BACKEND = CLOSED
M5-13 SOURCE = VERIFIED / APPLIED
M5-20 = OPEN / EXACT SOURCE PATCH REQUIRED FROM USER
MAIN5 FINAL RELEASE GATE = OPEN
```

## NEXT AUTHORIZED ACTION

```text
Apply M5-20-A:
replace the exact one-line canDelete expression in RW_Orders._renderTable as specified in Report80.

Apply M5-20-B:
remove the exact DEBUG_DELETE console.log line specified in Report80.

Apply M5-20-C:
replace the exact three-line canDelete block in RW_Orders._showDetails as specified in Report80.

Do NOT modify main5 in any other place yet.
Then re-read main5 from line 1 -> EOF.
Then perform syntax/structure/direct-write/consumer scan again.
Then reconcile Production again.
Only after that reassess the next authorized main5 closure.
```

## FORBIDDEN ACTIONS AT THIS CHECKPOINT

```text
Do not re-apply M5-13-A/B/C; they are already present in source.
Do not enable DELETE for Invoiced in the UI.
Do not weaken the Production delete-order guard.
Do not add a second runsheet mutation path.
Do not declare MAIN5 CLOSED before M5-20 and final EOF recheck are verified.
Do not claim Browser E2E; Production currently has zero orders and zero runsheets.
```

## MASTER FILE NOTE

The exact root filename was verified and read this session:

`doc/Draft/medhat/MASTER - RAWAEA ERP.md`

No replacement content was invented.
