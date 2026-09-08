# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-08

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report79_Main5_M5-13_Backend_Closure_20260908.md
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
M5-15 = CLOSED BY SOURCE
M5-16 = CLOSED BY SOURCE
M5-17-A = CLOSED BY SOURCE
M5-17-B = CLOSED BY SOURCE
M5-18 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
M5-19 = CLOSED BY SOURCE + PRODUCTION REALTIME FOUNDATION
```

## M5-13 — BACKEND CLOSED / SOURCE HANDOFF PENDING

Report78 identified three direct frontend mutation paths: `_details` `preConfirm`, `_deleteRunsheet`, `_cancelRunsheet`.

Production now has the canonical capability:

```text
RPC = public.manage_runsheet_atomic
OPERATIONS = UPDATE / CANCEL / DELETE
SECURITY = SECURITY DEFINER
DIRECT EXECUTE = anon NO / authenticated NO / service_role YES
EDGE = manage-runsheet v1 ACTIVE
```

Contract:

```text
UPDATE only Open/Confirmed; preserve current status
UPDATE validates driver and vehicle company scope
CANCEL only Open/Confirmed
DELETE only Open/Confirmed
CANCEL/DELETE reject Orders outside Pending/Confirmed
CANCEL/DELETE reject any fulfillment quantity or driver liability already posted
CANCEL => Orders Confirmed + runsheet_id NULL + details deleted + Runsheet Cancelled
DELETE => Orders Confirmed + runsheet_id NULL + details deleted + Runsheet deleted
ALL MUTATIONS = ONE DATABASE TRANSACTION
```

## M5-13 TEST RESULT

```text
UPDATE -> CANCEL transactional test = PASS
DELETE transactional test = PASS
FULFILLMENT GUARD qty_picked=1 = PASS; mutation rejected and data preserved
TENANT GUARD = PASS
RPC privilege isolation = PASS
Production test residue = 0
```

After tests Production counts remain:

```text
companies=1
users=24
branches=2
items=17
orders=0
runsheets=0
order_details=0
run_sheet_details=0
stock_rows=20
inventory_logs=3
currency=SAR
```

## FILES ADDED THIS SESSION

```text
supabase/migrations/20260908050000_manage_runsheet_atomic_capability_m5_13.sql
Current/Edge_Functions/manage-runsheet/index.ts
doc/Draft/Reprots/Report79_Main5_M5-13_Backend_Closure_20260908.md
```

`main5.md` was NOT modified by the assistant. The user must apply the exact M5-13-A/B/C blocks in Report79.

## NEXT ACTION

```text
DO NOT move to main6 yet.
Apply M5-13-A: replace the complete preConfirm block in _details with the manage-runsheet UPDATE block from Report79.
Apply M5-13-B: replace complete _deleteRunsheet(code) with the DELETE capability block from Report79.
Apply M5-13-C: replace complete _cancelRunsheet(code) with the CANCEL capability block from Report79.
Then re-read main5 line 1 -> EOF.
Then syntax/structure/direct-write/consumer scan.
Then Production reconciliation again.
Only then authorize the next part.
```

## MASTER FILE NOTE

The exact root filename `MASTER - RAWAEA ERP.md` could not be resolved in the current accessible `main` tree. No replacement content was invented.

## PRODUCTION REALTIME

Publication includes `app_settings`, `order_details`, `orders`, `run_sheet_details`, `runsheets`; all use `REPLICA IDENTITY FULL`. Browser E2E remains unverified because Production currently has zero orders and zero runsheets.

## LAST VERIFIED EVENT

```text
EVENT TYPE = MAIN5 M5-13 BACKEND CLOSURE + SURGICAL SOURCE HANDOFF
UTC DATE = 2026-09-08
MAIN5 BLOB = fac9f9bf55e2ecdc27e5de3c7e44c5ef769d49b9
BACKEND RPC = manage_runsheet_atomic
EDGE = manage-runsheet v1 ACTIVE
RESULT = M5-13 backend contract closed; main5 source awaits exact user-applied blocks + EOF recheck
REPORT = doc/Draft/Reprots/Report79_Main5_M5-13_Backend_Closure_20260908.md
```