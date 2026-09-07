# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-07

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
LATEST VERIFIED MAIN4 SOURCE COMMIT = 42ab7aeb113d64ea08becb134a8e114165594dc1
LATEST VERIFIED MAIN4 BLOB = 7e99ce1d81e2f594f9c2ed811ce5666914b4ceef
LATEST STATE REPORT = doc/Draft/Reprots/Report74_Main4_PostPatch_Forensic_Recheck_20260907.md
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
Main4 full forensic review and exact surgical patch specification.

### Main4 user patch commit
`42ab7aeb113d64ea08becb134a8e114165594dc1`
Message: `Refactor app settings retrieval and currency usage`
UTC: `2026-09-07 09:09:21`
Current main4 Blob: `7e99ce1d81e2f594f9c2ed811ce5666914b4ceef`

### Report74
`bd287ebb11760bb0a1f6aba063d6ae3be606d1f4`
Main4 post-patch forensic recheck. Report73 patch was confirmed present, then two additional source defects were found: Role save success references `dRes` outside scope; TeleSales `_saveOrder` contains a duplicate legacy execution block.

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
delivery_fee = 0.00
min_invoice_amount = 0.00
tax_rate = 0.00
main_branch_id = a38332b6-6cea-480a-ada1-6eb6ab0590db
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

## MAIN4 SOURCE STATE — CURRENT TARGET

```text
PATH = Current/PWA/main2/main4.md
CURRENT BLOB = 7e99ce1d81e2f594f9c2ed811ce5666914b4ceef
SOURCE PATCH = USER-APPLIED FROM REPORT73
FULL SOURCE RE-READ TO EOF = VERIFIED
POST-PATCH FORENSIC REVIEW = COMPLETE
STATUS = OPEN / TWO ADDITIONAL SOURCE DEFECTS FOUND
```

### MAIN4 PROVEN CURRENT STATE

```text
RW_POS
- app_settings is company-scoped
- main_branch_id is company-scoped and validated through branches.company_id
- main branch code is read from the configured branch
- currency is read from app_settings
- save-sales-invoice receives branchCode
- no EGP hardcode remains in the reviewed main4 POS path

RW_Roles
- initial roles read is company-scoped
- post-delete roles read is company-scoped
- post-seed roles read is company-scoped
- save-role backend is company-aware
- save-role success handler is currently BROKEN because it references dRes outside render() scope
- delete-role backend remains a separate backend closure

RW_TeleSales
- app_settings reads are company-scoped
- branches read is company-scoped
- stock_branches read is limited by the current company's branch IDs
- _getAvailable requires a selected branch
- currency is read from settings
- settings failure stops save instead of silently using stale local settings
- _saveOrder contains a duplicate legacy execution block after the new async/settings path and must be replaced as one complete function
```

### MAIN4 DEFECTS TO CLOSE

```text
M4-01 = Role save success refresh uses undefined/out-of-scope dRes
M4-02 = TeleSales _saveOrder contains duplicate legacy execution block
```

### REQUIRED USER ACTION

```text
1. Apply PATCH-M4-01 from Report74.
2. Replace the entire _saveOrder function with PATCH-M4-02 from Report74.
3. Do not change any other main4 source.
4. Re-read main4 from first line to EOF.
5. Verify exactly one _saveOrder definition remains.
6. Verify no stale duplicate order-save chain remains.
7. Verify the role-save success handler performs a fresh company-scoped roles query.
8. Commit the resulting main4.md.
9. Provide the new commit/blob for fresh forensic verification.
```

## BACKEND OPEN ITEMS

### delete-employee

Production `delete-employee` remains a separate backend closure issue. It must be opened only after main4 closure and a fresh reconciliation.

```text
TARGET = delete-employee Edge Function
STATUS = OPEN / NEXT BACKEND CLOSURE AFTER MAIN4
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
Report73 = READ TO EOF
Report74 = CREATED
main3 current Blob = VERIFIED
main3 full read after user patch = VERIFIED
main3 S1-S6 = VERIFIED
main4 current Blob = VERIFIED
main4 full source read after user patch = VERIFIED
Production relevant counts/settings/branches = VERIFIED
Production save-sales-invoice contract = VERIFIED
Production save-role Edge Function = VERIFIED
Production delete-role Edge Function = VERIFIED / OPEN BACKEND ISSUE
Browser E2E = NOT VERIFIED
main4 post-patch browser runtime = NOT VERIFIED
11-part assembly = NOT VERIFIED
Full PWA runtime = NOT VERIFIED
Final Production equivalence = NOT VERIFIED
```

## WHAT I PROVED

- The project was resumed from the current verified state rather than historical stage numbers.
- The latest main4 source commit after Report73 is `42ab7a...`, and it modified main4 directly.
- The main4 patch from Report73 is present in the current blob.
- The full main4 file was read again from start to EOF after the user patch.
- Production currently has one company, one app_settings row, 24 users, 20 roles, 3 customers, one supplier, two branches, and 17 items.
- Production currency is SAR.
- Production main branch code is BR-01.
- Production `save_sales_invoice_atomic` requires `p_branch_code`.
- POS is now aligned with that contract.
- The remaining main4 problems are source-level defects discovered by post-patch forensic review.

## WHAT I DID NOT PROVE

- Browser E2E after the latest two manual fixes.
- Main4 Production runtime behavior after those fixes.
- Final 11-part assembly.
- Full PWA runtime equivalence.
- delete-employee closure.
- roles RLS closure.
- delete-role backend closure.

## WHAT MUST NOT BE REPEATED

```text
Do not reopen main3 without new direct evidence.
Do not fix delete-role backend inside main4 UI.
Do not reintroduce EGP in main4.
Do not send branchId to save-sales-invoice.
Do not allow TeleSales to continue through a silent settings fallback.
Do not keep two _saveOrder execution paths.
Do not reference render-local dRes from openModal.
Do not declare main4 closed before post-patch full re-read and Production reconciliation.
```

## CLOSURE STATUS

```text
Production branch attribution = CLOSED / VERIFIED
Main2 source = VERIFIED / RUNTIME OPEN
Main3 source = VERIFIED AFTER USER PATCH
Main3 S1-S6 = VERIFIED
Main4 Report73 patch = APPLIED / VERIFIED
Main4 post-patch source = FORENSICALLY REVIEWED / TWO DEFECTS OPEN
Main4 runtime = OPEN
Employee delete backend = OPEN
Roles RLS governance = OPEN
Delete-role backend = OPEN
11-part integration = OPEN
Full PWA runtime = OPEN
PROJECT CLOSURE = NOT CLAIMED
```

## NEXT AUTHORIZED ACTION

```text
USER:
  Apply PATCH-M4-01 and PATCH-M4-02 from Report74 exactly.

THEN:
  MAIN4 FULL RE-READ TO EOF
  → VERIFY EACH REPLACEMENT
  → VERIFY SINGLE _saveOrder
  → VERIFY ROLE REFRESH QUERY
  → VERIFY CURRENT MAIN4 SOURCE BLOB
  → RECONCILE CURRENT PRODUCTION
  → PERFORM MAIN4 INTEGRATION/RUNTIME VERIFICATION
  → ONLY AFTER MAIN4 CLOSES, OPEN DELETE-EMPLOYEE AS A SEPARATE CLOSURE UNIT
```
