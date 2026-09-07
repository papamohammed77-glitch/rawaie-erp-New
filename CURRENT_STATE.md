# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-07

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST VERIFIED MAIN3 COMMIT = e5a340b0a2c3de8a38a2d09375753afe1538230b
LATEST VERIFIED MAIN3 BLOB = 479060e3d4bea5e2203c87f822b1dbc0e2f7d456
LATEST REPORT = doc/Draft/Reprots/Report73_Main4_Surgical_Forensic_20260907.md
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
Forensic reconciliation of main2 and stale Blob reference.

### Report70
`5f0a018c92a8c74415039e5016899a9af9d29c69`
Production branch-attribution deployment and transactional verification.

### Main2 user commit
`36482301223c07ddd256c87a2bc712198d955b7a`
Message: `Update main2.md`
Current main2 Blob: `58dd0da232ccca4c62bc17d87220bf8b705d85e8`

### Report71
`5d08da67982ba4a9e4e1524a221081b1118f731d`
Forensic main3 review and exact manual patch instructions.

### Main3 user patch commit
`e5a340b0a2c3de8a38a2d09375753afe1538230b`
Message: `Update main3.md`
UTC: `2026-09-07 04:19:49`
Current main3 Blob: `479060e3d4bea5e2203c87f822b1dbc0e2f7d456`

### Report72
`7cd86940e7ef729907872785c2f9aa5414f021d3`
Main3 post-patch forensic verification and Production contract reconciliation.

### Report73
`4489997677ed593f1567a9fbb398ea6172c8eef5`
Main4 full forensic review and exact surgical patch specification. No main4 source code was changed by the assistant.

## PRODUCTION TRUTH — 2026-09-07

```text
companies            = 1
app_settings         = 1
users                = 24
roles                = 20
customers            = 3
suppliers            = 1
branches             = 2
customer_assignments = 0
items                = 17
```

Current `app_settings`:

```text
company_id = 00000000-0000-0000-0000-000000000001
currency = SAR
company_name = الروائع
delivery_fee = 0
min_invoice_amount = 0
tax_rate = 0
main_branch_id = configured
```

Current branches:

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
app_settings.main_branch_id PRESENT
stock_branches derives company through branch_id; no company_id column
```

Relevant RLS facts:

```text
users                = ENABLED
roles                = ENABLED
customers            = ENABLED
suppliers            = ENABLED
branches             = ENABLED
app_settings         = ENABLED
customer_assignments = ENABLED
stock_branches       = company-aware through branch relationship
```

`roles` still has broad policy `Allow all for all` with `qual=true / with_check=true`; keep this as a separate security/governance closure.

## MAIN2 SOURCE STATE

```text
PATH = Current/PWA/main2/main2.md
CURRENT BLOB = 58dd0da232ccca4c62bc17d87220bf8b705d85e8
SOURCE INTEGRATION = VERIFIED
BROWSER RUNTIME = NOT VERIFIED
FINAL 11-PART ASSEMBLY = NOT VERIFIED
```

Do not reopen main2 during main4 closure without new direct evidence.

## MAIN3 SOURCE STATE

```text
PATH = Current/PWA/main2/main3.md
CURRENT BLOB = 479060e3d4bea5e2203c87f822b1dbc0e2f7d456
USER PATCH = APPLIED
FULL SOURCE RE-READ = VERIFIED
```

Logical modules:

```text
RW_Customers
RW_Suppliers
RW_Branches
RW_Settings
RW_Users
```

### S1–S6

```text
S1 Suppliers company scope       = APPLIED / VERIFIED
S2 Settings scope + currency     = APPLIED / VERIFIED
S3 Users + Roles company scope   = APPLIED / VERIFIED
S4 assigned_by UUID               = APPLIED / VERIFIED
S5 assignment rollback handling   = APPLIED / VERIFIED
S6 removal rollback handling      = APPLIED / VERIFIED
```

### MAIN3 POST-PATCH DECISION

```text
NEW MAIN3 SURGICAL PATCH = NOT JUSTIFIED BY CURRENT EVIDENCE
```

Do not reopen main3 without direct new evidence.

## MAIN4 SOURCE STATE — NEW CURRENT TARGET

```text
PATH = Current/PWA/main2/main4.md
SOURCE = CURRENT ORIGINAL PART
MODULES = RW_POS + RW_Roles + RW_TeleSales
FULL SOURCE READ TO EOF = VERIFIED
USER PATCH = NOT YET APPLIED
ASSISTANT SOURCE EDIT = NONE
STATUS = OPEN / SURGICAL PATCH SPEC READY
```

### MAIN4 PROVEN FINDINGS

```text
RW_POS
- app_settings lookup is globally unscoped via limit(1)
- POS sends branchId instead of branchCode
- POS defaults to hardcoded MAIN while Production main branch code is BR-01
- currency display is hardcoded to EGP

RW_Roles
- initial roles read is unscoped
- post-save roles read is unscoped
- post-delete roles read is unscoped
- post-seed roles read is unscoped
- save-role backend is company-aware
- delete-role backend remains a separate backend closure because its delete path is not company-scoped

RW_TeleSales
- app_settings reads are unscoped
- branches read is unscoped
- stock_branches read is not explicitly restricted through current company branches
- _getAvailable sums all branches when no branch is selected
- _saveOrder silently falls back to local values when app_settings read fails
- currency is hardcoded to EGP in several UI messages
```

### MAIN4 SURGICAL DECISION

```text
NO MAIN4 SOURCE PATCH WAS APPLIED BY THE ASSISTANT.

REQUIRED USER ACTION = APPLY THE EXACT SURGICAL PATCHES IN REPORT73.

AFTER USER PATCH:
READ MAIN4 TO EOF AGAIN
→ VERIFY EACH REPLACEMENT
→ VERIFY GIT/BLOB
→ RECONCILE PRODUCTION AGAIN
→ ONLY THEN PROCEED TO NEXT CLOSURE
```

Do not mark main4 Closed before this post-patch re-read.

## BACKEND OPEN ITEMS

### delete-employee

Production `delete-employee` remains a separate backend closure issue. It must be opened only after a fresh reconciliation following main4 closure.

```text
TARGET = delete-employee Edge Function
MAIN4 PATCH = NOT SUBSTITUTE FOR BACKEND FIX
STATUS = OPEN / NEXT BACKEND CLOSURE AFTER FRESH RECONCILIATION
```

### roles RLS / delete-role backend

```text
STATUS = OPEN / SEPARATE GOVERNANCE + BACKEND CLOSURE
```

Do not change Owner wildcard semantics while addressing this.

## VALIDATION STATUS

```text
MASTER = READ TO EOF
CURRENT_STATE = READ / RECONCILED / UPDATED
Report72 = READ TO EOF
Report73 = CREATED
main3 current Blob = VERIFIED
main3 full read after user patch = VERIFIED
main3 S1-S6 = VERIFIED
main4 full source read = VERIFIED
Production schema relevant to main4 = VERIFIED
Production RLS relevant to main4 = VERIFIED
Active Edge contracts relevant to main4 = VERIFIED
Browser E2E = NOT VERIFIED
main4 post-patch runtime = NOT VERIFIED
11-part assembly = NOT VERIFIED
Full PWA runtime = NOT VERIFIED
Final Production equivalence = NOT VERIFIED
```

## WHAT I PROVED

- Current Git HEAD after Report72 was verified before this session.
- main3 remains at the previously verified user patch and was not reopened.
- main4 was read completely from beginning to end.
- main4 contains three logical modules: POS, Roles, TeleSales.
- Production currently has one company, one settings row, 24 users, 20 roles, 3 customers, and 2 active branches.
- Production currency is SAR and the main branch code is BR-01.
- `items.item_code` is globally unique.
- main4 contains confirmed company-scope gaps.
- POS currently mismatches the deployed `save-sales-invoice` parameter contract by sending `branchId` instead of `branchCode`.
- TeleSales has a confirmed silent-settings-fallback path that can alter order total behavior when settings read fails.
- The next surgical target is main4, and delete-employee remains a separate closure after fresh reconciliation.

## WHAT I DID NOT PROVE

- Browser E2E after user-applied main4 patches.
- Main4 post-patch runtime behavior.
- Final 11-part assembly.
- Full PWA Production equivalence.
- delete-employee closure.
- roles RLS closure.
- delete-role backend closure.

## WHAT MUST NOT BE REPEATED

```text
Do not reopen main3 merely because main4 work has issues.
Do not fix backend delete-role inside main4 UI.
Do not use EGP where Production currency is SAR.
Do not send branchId to save-sales-invoice; use branchCode.
Do not allow TeleSales to continue with a silent local-settings fallback.
Do not sum stock across all branches when a single branch will own the order.
Do not declare main4 closed before full post-patch source re-read and current-state reconciliation.
```

## NEXT AUTHORIZED ACTION

```text
1. User applies the exact Report73 surgical patches to main4.md.
2. Re-read main4.md from beginning to EOF.
3. Verify no unintended deletion or truncation.
4. Verify the new Git blob/commit.
5. Reconcile Production again at the same reporting moment.
6. Perform main4 runtime/integration verification where possible.
7. Only after main4 is actually closed, perform a fresh reconciliation.
8. Open delete-employee as its own Closure Unit.
9. Continue remaining PWA parts independently.
10. Assemble the 11 parts only after their source closures are independently verified.
11. Then integrate core.js / sw.js / register-sw.js / manifest and perform final runtime verification.
```

## CLOSURE STATUS

```text
Production branch attribution = CLOSED / VERIFIED
Main2 source B/C = INTEGRATED / RUNTIME OPEN
Main3 source = VERIFIED AFTER USER PATCH
Main3 S1-S6 = VERIFIED
Main4 source forensic review = COMPLETE
Main4 user patch = PENDING
Main4 runtime = OPEN
Employee delete backend = OPEN
Roles RLS governance = OPEN
Delete-role backend = OPEN
11-part integration = OPEN
Full PWA runtime = OPEN
PROJECT CLOSURE = NOT CLAIMED
```
