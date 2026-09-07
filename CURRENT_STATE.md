# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-07

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
CURRENT GIT HEAD = c7aee872815564b910d7258d5918e550e66dc9da
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report76_Main5_Forensic_Continuation_20260907.md
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

Primary governance:
`doc/Draft/medhat/MASTER - RAWAEA ERP.md`

## LAST VERIFIED LINEAGE

### Main4 historical lineage

```text
Report73 = 4489997677ed593f1567a9fbb398ea6172c8eef5
User Main4 Patch = 42ab7aeb113d64ea08becb134a8e114165594dc1
Report74 = bd287ebb11760bb0a1f6aba063d6ae3be606d1f4
Previous Main4 Commit = ee5638b3d71b1c94b4c611003ce8be6831ef8342
Previous Main4 Blob = 932c22c7e0a0285a437729a84b9a1f909bd5f573
Current Main4 Blob = e89d29e4164c68784c109292f27d4d77df240557
```

The current main4 commit after Report75 contains the corrected M4-01 `try / if / else / catch` block. M4-02 remains intact. The main4 source was re-read during the current session.

### Current documentation events

```text
Report75 = historical forensic recheck
Report76 = c7aee872815564b910d7258d5918e550e66dc9da
CURRENT_STATE = updated after Report76
```

## PRODUCTION TRUTH — 2026-09-07 10:12:16 UTC

```text
companies      = 1
app_settings   = 1
users          = 24
roles          = 20
customers      = 3
suppliers      = 1
branches      = 2
items          = 17
orders         = 0
runsheets      = 0
stock_rows     = 20
inventory_logs = 3
```

Current company settings:

```text
company_id          = 00000000-0000-0000-0000-000000000001
currency            = SAR
company_name        = الروائع
delivery_fee        = 0.00
min_invoice_amount  = 0.00
tax_rate             = 0.00
main_branch_id      = a38332b6-6cea-480a-ada1-6eb6ab0590db
```

Branches:

```text
BR-01 = الفرع الرئيسي
BR-2  = فرع إسكندرية
```

Relevant schema facts:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
roles.company_id PRESENT
branches.company_id PRESENT
app_settings.company_id PRESENT
stock_branches derives company through branch_id
```

Relevant RLS facts verified directly in Production:

```text
orders = authenticated SELECT only; no authenticated UPDATE/DELETE policy
runsheets = SELECT/INSERT/UPDATE/DELETE with current-company checks
order_details = current-tenant SELECT policy
run_sheet_details = current-tenant SELECT policy
users = company-aware policies
vehicles = company-aware SELECT policy
app_settings = company-aware policies
```

`roles` broad `Allow all for all` policy remains a separate governance closure.

## MAIN2

```text
main2 source = previously verified
Browser runtime = NOT VERIFIED
11-part final assembly = NOT VERIFIED
```

Do not reopen main2 without new direct evidence.

## MAIN3

```text
main3 source = VERIFIED AFTER USER PATCH
S1-S6 = VERIFIED
```

Do not reopen main3 without new direct evidence.

## MAIN4 — SOURCE CLOSED / RUNTIME OPEN

```text
PATH = Current/PWA/main2/main4.md
BLOB = e89d29e4164c68784c109292f27d4d77df240557
FULL SOURCE RE-READ = VERIFIED
M4-01 = CORRECTED IN CURRENT GIT
M4-02 = VERIFIED
_saveOrder definitions = 1
legacy duplicate _saveOrder = absent
```

No new main4 patch is authorized from current evidence.

Remaining main4 verification:

```text
Browser runtime = OPEN
11-part integration = OPEN
Full PWA runtime = OPEN
```

## MAIN5 — CURRENT TARGET

```text
PATH = Current/PWA/main2/main5.md
BLOB = caffc0187b54444e96491dc6f00a238b2e870b32
SOURCE FULL READ = VERIFIED BY SEQUENTIAL FORENSIC REVIEW
SOURCE SYNTAX CLOSURE = NO MAIN4-LIKE DEFECT FOUND
RUNTIME = OPEN
```

### Main5 open surgical changes

```text
M5-01 = RW_Orders orders query must be company-scoped
M5-02 = order_details must be constrained by loaded order IDs
M5-03 = orders realtime subscription must be company-filtered
M5-04 = _showDetails orders lookup must be company-scoped
M5-05 = _printOrder app_settings must be company-scoped
M5-06 = remove direct orders UPDATE before create-runsheet
M5-07 = _appendRS runsheet lookups must be company-scoped
M5-08 = _loadRunsheetCodes must be company-scoped
M5-09 = _refreshData orders + order_details must be company-scoped/bounded
M5-10 = drivers and vehicles helper queries must be company-scoped
M5-11 = RW_Runsheets main list must be company-scoped
M5-12 = RW_Runsheets _details runsheet/orders lookups must be company-scoped
M5-14 = replace hardcoded EGP presentation with app_settings.currency
```

### M5-13 — OPEN CONTRACT / DO NOT PATCH YET

```text
_deleteRunsheet currently performs three direct Frontend writes
orders UPDATE is not permitted by current authenticated RLS
run_sheet_details write ownership is not proven
no Production delete-runsheet RPC/Edge capability was found
```

Do not invent a delete capability or change delete semantics until the historical/source/Business Contract is reconstructed.

## EXACT NEXT USER ACTION

Apply exactly the surgical blocks in Report76 to `Current/PWA/main2/main5.md`:

```text
M5-01
M5-02
M5-03
M5-04
M5-05
M5-06
M5-07
M5-08
M5-09
M5-10
M5-11
M5-12
M5-14
```

Do NOT change M5-13.

After the manual edits:

```text
commit main5.md
return new main5 commit SHA + blob SHA
```

Then the next authorized step is:

```text
full main5 read from first line to EOF
structural/source recheck
Production reconciliation
runtime/integration assessment
```

## WHAT IS PROVEN / NOT PROVEN

### Proven

```text
MASTER read to EOF
CURRENT_STATE reconciled against current Git and Production
Report75 treated as historical evidence
current Git HEAD identified
current main4 source re-read
M4-01 correction present
M4-02 intact
main5 source reviewed in sequential ranges
Production current counts/settings/RLS verified
main5 company-scope defects identified
main5 hardcoded EGP defects identified
```

### Not proven

```text
main4 browser runtime
main5 browser runtime
11-part final assembly
full PWA runtime equivalence
final Production equivalence
atomic delete-runsheet business contract
```

## KNOWN ANTIPATTERNS — DO NOT REPEAT

```text
Do not treat reports as current Production truth.
Do not treat source closure as runtime closure.
Do not use LIMIT 1 for company-scoped operational identity.
Do not add a new database column when an existing operation identity contract is available.
Do not invent a delete-runsheet backend without proven owner/contract.
Do not modify the 11-part system parent files directly from the assistant.
```

## CLOSURE STATUS

```text
MAIN4 SOURCE = CLOSED
MAIN4 RUNTIME = OPEN
MAIN5 SOURCE = OPEN / USER PATCH REQUIRED
MAIN5 RUNTIME = OPEN
M5-13 DELETE-RUNSHEET CONTRACT = OPEN
11-PART INTEGRATION = OPEN
PROJECT = OPEN
```

## LAST VERIFIED EVENT

```text
EVENT TYPE = FORENSIC CONTINUATION / MAIN5
UTC = 2026-09-07 10:12:16
SOURCE = Production Supabase + current Git
GIT HEAD = c7aee872815564b910d7258d5918e550e66dc9da
MAIN4 BLOB = e89d29e4164c68784c109292f27d4d77df240557
MAIN5 BLOB = caffc0187b54444e96491dc6f00a238b2e870b32
ACTION = Reconcile current state, re-read main4/main5, identify exact surgical patches
RESULT = Main4 source closed; Main5 patch specification issued; delete-runsheet contract remains open
EVIDENCE = Report76 + direct Production SQL verification
NEXT AUTHORIZED ACTION = User applies Main5 M5-01..M5-12 + M5-14, then source commit/recheck
```
