# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-05

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
LAST VERIFIED WORK COMMIT = 5d08da67982ba4a9e4e1524a221081b1118f731d
LAST VERIFIED WORK = Report71 — forensic main3 review and surgical patch instructions
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
```

## GOVERNANCE

```text
CURRENT REALITY > CURRENT GIT > CURRENT PRODUCTION > CURRENT DEPLOYMENTS > CURRENT DATABASE CONTRACTS > HISTORICAL CONTRACTS > REPORTS > MEMORY > ASSUMPTIONS
UNKNOWN != BUG
UNKNOWN != REMOVE
READ → VERIFY → RECONCILE → UNDERSTAND → PATCH → VERIFY
ONE CLOSURE UNIT AT A TIME
GIT != DEPLOYMENT PROOF
SOURCE != RUNTIME PROOF
NO CLOSURE CLAIM WITHOUT CURRENT EVIDENCE
```

Primary governance:
`doc/Draft/medhat/MASTER - RAWAEA ERP.md`

## LAST VERIFIED EVENTS

### Report69

`ba750f3707560b7c2bf4e6ebaa8d0eeca3f2db47`

Forensic reconciliation of main2 and its stale Blob reference.

### Report70

`5f0a018c92a8c74415039e5016899a9af9d29c69`

Production branch-attribution deployment and transactional verification.

### Main2 user commit

`36482301223c07ddd256c87a2bc712198d955b7a`

Message: `Update main2.md`

Current main2 source Blob after that commit:
`58dd0da232ccca4c62bc17d87220bf8b705d85e8`

### Report71

`5d08da67982ba4a9e4e1524a221081b1118f731d`

Forensic main3 review, Production scope verification, exact surgical patch instructions, and backend defect classification.

## PRODUCTION TRUTH — DIRECT RECONCILIATION

```text
companies       = 1
app_settings    = 1
orders          = 0
purchase_orders = 0
branches        = 2
items           = 17
stock_branches  = 20
inventory_log   = 3
```

Relevant schema facts:

```text
items.item_code UNIQUE globally
stock_branches UNIQUE(branch_id,item_id)
receiving.operation_id UNIQUE
items.barcode NOT UNIQUE
roles.company_id PRESENT
customer_assignments.assigned_by = uuid
```

Relevant RLS facts:

```text
users                = RLS ENABLED
roles                = RLS ENABLED
customers            = RLS ENABLED
suppliers            = RLS ENABLED
branches             = RLS ENABLED
app_settings         = RLS ENABLED
customer_assignments = RLS ENABLED
```

Important residue:

```text
roles policy `Allow all for all` = qual=true / with_check=true
```

This is a backend governance/security closure item; the main3 UI is still required to query roles by company and must not depend on the broad policy.

Production branch attribution remains verified:

```text
inventory_log.source_branch_id = PRESENT
inventory_log.target_branch_id = PRESENT
source FK = PRESENT
target FK = PRESENT
post_stock_movement persists source/target = VERIFIED
```

## MAIN2 SOURCE STATE

```text
PATH = Current/PWA/main2/main2.md
CURRENT BLOB = 58dd0da232ccca4c62bc17d87220bf8b705d85e8
```

The current source was rechecked after the user commit. The movement reader now references `inventory_log` and branch attribution, and the current search found no `stock_vouchers` / `stock_voucher_details` references inside that movement reader.

Therefore:

```text
MAIN2 B/C SOURCE INTEGRATION = VERIFIED IN CURRENT GIT
MAIN2 BROWSER RUNTIME = NOT VERIFIED
MAIN2 FINAL 11-PART ASSEMBLY = NOT VERIFIED
PROJECT CLOSURE = NOT CLAIMED
```

Do not reopen main2 during the main3 surgical pass unless new direct evidence appears.

## MAIN3 SOURCE STATE

```text
PATH = Current/PWA/main2/main3.md
CURRENT BLOB = 1bfedd3b16abb804d83e2b7d5671f1b31f320a14
STATUS = NOT MODIFIED BY ASSISTANT
STATUS = FORENSICALLY REVIEWED
```

The file was read completely from start to final closing brace and compared to `Original/PWA/main/main3.md`.

Current logical modules:

```text
RW_Customers
RW_Suppliers
RW_Branches
RW_Settings
RW_Users
```

### Proven safe / no patch

```text
RW_Customers = NO PATCH
RW_Branches  = NO PATCH
save-customer Edge = COMPANY SCOPED
save-supplier Edge = COMPANY SCOPED
save-branch Edge = COMPANY SCOPED
save-settings Edge = COMPANY SCOPED + OWNER/LICENSE checks
save-employee Edge = COMPANY SCOPED
```

### Main3 manual patches prepared

```text
S1 = suppliers company-scoped reads
S2 = app_settings company-scoped read + currency hydration
S3 = users/roles company-scoped reads and refreshes
S4 = customer_assignments.assigned_by UUID correction
S5 = assignment write error/rollback handling
S6 = assignment removal error/rollback handling
```

Exact instructions are recorded in `doc/Draft/Reprots/Report71`.

### Why S4 is mandatory

Production schema:

```text
customer_assignments.assigned_by = uuid
```

Current main3 sends:

```javascript
assigned_by: (RW_STATE.app.currentUser && RW_STATE.app.currentUser.email) || null,
```

This is a direct type-contract mismatch.

### Why S2 is mandatory

Production `app_settings` contains:

```text
currency
```

Current main3 renders a currency selector from `currentSettings.currency` but does not hydrate that property from `appSets.currency`.

### Why S1/S3 are mandatory

`suppliers`, `users`, `roles` are company-scoped entities in the current schema. Current main3 uses global reads for them. `roles` is especially sensitive because its current RLS policy is broad.

## BACKEND OPEN ITEM

Production `delete-employee` currently authenticates the caller but performs the database delete using email only, without a `company_id` predicate.

Classification:

```text
BACKEND DEFECT = PROVEN
TARGET = delete-employee Edge Function
MAIN3 PATCH = NOT SUBSTITUTE FOR BACKEND FIX
STATUS = OPEN / SEPARATE CLOSURE UNIT
```

Do not declare the Employee lifecycle fully closed until this closure is addressed and verified.

## PATCHES NOT TO DO

```text
Do not modify main2 during main3 closure.
Do not modify core.js / sw.js / register-sw.js / manifest during main3 closure.
Do not patch RW_Customers or RW_Branches without new evidence.
Do not change Owner ["*"] semantics.
Do not replace roles policy blindly inside this main3 task.
Do not invent an Edge Function for assignments unless a later closure proves the existing direct-write contract must be replaced.
Do not claim browser/runtime closure from source inspection.
```

## VALIDATION STATUS

```text
MASTER continuity = READ TO EOF
Knowledge Pack 2026-09-04 = READ TO EOF
Report69 = READ TO EOF
Report70 = READ TO EOF
Report71 = CREATED
Current Git main ref = VERIFIED
Main2 current Blob = VERIFIED
Main3 current Blob = VERIFIED
Main3 full read = VERIFIED
Production relevant schema = VERIFIED
Production relevant RLS = VERIFIED
Production relevant Edge Functions = VERIFIED
Main3 manual patches = PREPARED, NOT APPLIED BY ASSISTANT
Main3 runtime = NOT VERIFIED
Main3 static/syntax after user edit = NOT VERIFIED
11-part assembly = NOT VERIFIED
Full PWA runtime = NOT VERIFIED
Project Closure = NOT CLAIMED
```

## WHAT I PROVED

- The repository moved after Report70; the current main ref is now on the user's main2 update followed by Report71.
- The stale main2 Blob recorded by the old state is no longer current.
- Main2 B/C source integration is present in current Git.
- Main3 Blob is still `1bfedd3...` and was read to EOF.
- Main3 is not a Physical Stock writer.
- Main3 contains direct company-scoped reads for suppliers/users/roles that should be explicitly scoped.
- Main3 contains a concrete `assigned_by` UUID vs email mismatch.
- Main3 contains a concrete missing `currency` hydration.
- Production current RLS and schema were directly checked.
- Production `delete-employee` has a separate unscoped email-delete defect.

## WHAT I DID NOT PROVE

- Browser E2E after the manual main3 edits.
- Static/syntax after the manual main3 edits.
- Runtime success of customer assignment after S4-S6.
- Final 11-part assembly.
- Final PWA Production equivalence.
- Closure of backend `delete-employee`.
- Closure of the broad `roles` RLS policy.

## CURRENT TARGET

```text
PRIMARY TARGET = Current/PWA/main2/main3.md
MODE = USER MANUAL SURGICAL EDIT
```

## NEXT AUTHORIZED ACTION

```text
1. Apply S1-S6 in main3 exactly as written in Report71.
2. Do not change any other main3 code in the same edit.
3. Re-read main3.md completely after saving.
4. Verify the exact replacement text is intact and no surrounding code was lost.
5. Commit the user's main3 change.
6. Re-fetch the new main3 Blob from Git.
7. Perform static/syntax review.
8. Verify the affected Production contracts again.
9. Then address the separate delete-employee backend closure.
10. After main3 closure, reassess the next target from fresh evidence rather than historical stage numbering.
```

## CLOSURE STATUS

```text
Production branch attribution = CLOSED / DEPLOYED / TRANSACTIONALLY VERIFIED
Main2 source B/C = INTEGRATED IN CURRENT GIT / RUNTIME OPEN
Main3 = FORENSIC REVIEW COMPLETE / MANUAL PATCH PENDING
Main3 source closure = OPEN
Main3 runtime closure = OPEN
Employee delete backend = OPEN
11-part integration = OPEN
Project Closure = NOT CLAIMED
```
