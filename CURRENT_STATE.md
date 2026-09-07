# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-07

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
CURRENT GIT HEAD (documentation update) = 075512d42b71edb063b83ef627c5f1d0ebdc09ad
LATEST VERIFIED MAIN4 SOURCE COMMIT = ee5638b3d71b1c94b4c611003ce8be6831ef8342
LATEST VERIFIED MAIN4 BLOB = 932c22c7e0a0285a437729a84b9a1f909bd5f573
LATEST FORENSIC REPORT = doc/Draft/Reprots/Report75_Main4_CurrentHead_Forensic_Recheck_20260907.md
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
Historical main4 Blob referenced by Report74: `7e99ce1d81e2f594f9c2ed811ce5666914b4ceef`

### Main4 newer user commit discovered during Report75 recovery
`ee5638b3d71b1c94b4c611003ce8be6831ef8342`
Message: `Update main4.md`
UTC: `2026-09-07 09:48:36`
Current main4 Blob: `932c22c7e0a0285a437729a84b9a1f909bd5f573`

This commit contains the user's application of the Report74 main4 fixes. The source was re-read again after this commit.

### Report74
`bd287ebb11760bb0a1f6aba063d6ae3be606d1f4`
Main4 post-patch forensic recheck. Historical relative to the newer `ee5638b3...` main4 commit.

### Report75
`075512d42b71edb063b83ef627c5f1d0ebdc09ad`
Current-head forensic recheck after the newer main4 user commit. Report75 identified that M4-02 is now correctly applied, while M4-01 contains a syntax-level defect because the updated `try` block has no `catch`/`finally`.

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

Current `app_settings` verified directly:

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

Relevant RLS facts previously verified:

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

### S1–S6

```text
S1 Suppliers company scope       = APPLIED / VERIFIED
S2 Settings scope + currency     = APPLIED / VERIFIED
S3 Users + Roles company scope   = APPLIED / VERIFIED
S4 assigned_by UUID              = APPLIED / VERIFIED
S5 assignment rollback handling  = APPLIED / VERIFIED
S6 removal rollback handling     = APPLIED / VERIFIED
```

Do not reopen main3 without new direct evidence.

## MAIN4 SOURCE STATE — CURRENT TARGET

```text
PATH = Current/PWA/main2/main4.md
LATEST SOURCE COMMIT = ee5638b3d71b1c94b4c611003ce8be6831ef8342
CURRENT BLOB = 932c22c7e0a0285a437729a84b9a1f909bd5f573
SOURCE PATCH M4-01 = PARTIALLY APPLIED / CURRENT SYNTAX DEFECT OPEN
SOURCE PATCH M4-02 = APPLIED / VERIFIED
FULL SOURCE RE-READ TO EOF = VERIFIED
STATUS = OPEN
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
- the refresh query in save-role success is company-scoped
- CURRENT DEFECT: the `try` immediately after save-role `var token = ...` has no catch/finally before the callback closes; the else branch for backend failure was also removed

RW_TeleSales
- app_settings reads are company-scoped
- branches read is company-scoped
- stock_branches read is limited by the current company's branch IDs
- _getAvailable requires a selected branch
- currency is read from settings
- settings failure stops save instead of silently using stale local settings
- _saveOrder is now a single async execution path
- legacy duplicate _saveOrder execution block is no longer present
```

## MAIN4 CURRENT DEFECT

```text
M4-01 = OPEN
Cause = Report74 patch was applied without preserving the surrounding try/catch structure.
Observed current structure:
  try {
      ...
      if (json.success) { ... }
  });
This is syntactically invalid because try requires catch or finally.
```

### REQUIRED USER ACTION — EXACT

In `Current/PWA/main2/main4.md`, inside `RW_Roles`, find:

```javascript
var token = sessionRes.data.session ? sessionRes.data.session.access_token : null;
try {
    var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-role', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify(payload) });
```

Starting at the `try {` shown above, delete the entire block through the `});` that appears immediately before:

```javascript
if (isEdit) {
```

Replace it with the complete corrected block from Report75:

```javascript
try {
    var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-role', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            Authorization: 'Bearer ' + token
        },
        body: JSON.stringify(payload)
    });

    var json = await res.json();
    hideLoader();

    if (json.success) {
        showToast(isEdit ? 'تم التعديل' : 'تمت الإضافة', 'success');
        Swal.close();

        var refreshedRoles = await supabase.from('roles')
            .select('*')
            .eq('company_id', _rwCompanyId())
            .order('created_at', { ascending: true });

        if (refreshedRoles.error) {
            showToast('تم الحفظ لكن تعذر تحديث قائمة الأدوار', 'warning');
            return;
        }

        rolesData = refreshedRoles.data || [];
        renderTable(rolesData);
    } else {
        showToast(json.error || 'فشل الحفظ', 'error');
    }
} catch(e) {
    hideLoader();
    showToast('فشل الاتصال بـ Edge Function', 'error');
}
```

ثم اترك السطر التالي الموجود أصلًا بدون تعديل:

```javascript
if (isEdit) {
```

Do not reapply M4-02.

## VALIDATION STATUS

```text
MASTER = READ TO EOF
CURRENT_STATE = READ / RECONCILED / UPDATED
Report74 = READ TO EOF
Report75 = CREATED
main3 current Blob = VERIFIED
main3 full read after user patch = VERIFIED
main3 S1-S6 = VERIFIED
main4 current Blob = VERIFIED
main4 full source read after latest user commit = VERIFIED
main4 M4-02 = VERIFIED APPLIED
main4 M4-01 = OPEN / SYNTAX DEFECT PROVEN
Production counts/settings/branches = VERIFIED
Production save-sales-invoice contract = VERIFIED
core.js shared primitives = VERIFIED PRESENT
Browser E2E = NOT VERIFIED
main4 post-corrected-patch browser runtime = NOT VERIFIED
11-part assembly = NOT VERIFIED
Full PWA runtime = NOT VERIFIED
Final Production equivalence = NOT VERIFIED
```

## WHAT I PROVED

- The project was resumed from current evidence, not historical stage numbers.
- `MASTER - RAWAEA ERP.md` was read to EOF.
- `CURRENT_STATE.md` was reconciled against current Git and current Production.
- A newer `main4.md` commit existed after Report74: `ee5638b3...`.
- The current main4 blob is `932c22c7...` and was read fully to EOF.
- The user's M4-02 replacement is present and the old duplicate `_saveOrder` block is absent.
- There is exactly one `_saveOrder` definition in current main4.
- The M4-01 refresh query is present and company-scoped.
- The surrounding `try/catch` in M4-01 is currently broken and is the only main4 source defect proven in this review.
- Production remains one company with two branches, currency SAR, and the current save-sales-invoice contract requiring `p_branch_code`.
- `core.js` currently contains the shared Supabase/UI primitives used by main4 (`supabase`, `byId`, `safeHTML`, `safeText`, `showLoader`, `hideLoader`).

## WHAT I DID NOT PROVE

```text
Browser E2E after corrected M4-01 patch
Production runtime of corrected main4
Final 11-part assembly
Full PWA runtime equivalence
Final production equivalence
Delete-employee closure
Roles RLS closure
delete-role backend closure
```

## WHAT I DID IN THIS SESSION

```text
READ / RECONCILE / VERIFY:
- MASTER full read
- CURRENT_STATE reconciliation
- Report74 full read
- current Git HEAD verification
- current main4 full read
- current main4 commit diff verification
- Production reconciliation
- core.js static dependency check

DOCUMENTATION:
- created Report75
- updated CURRENT_STATE.md

NO main4 source modification was performed by the assistant because the user explicitly owns the manual edits of the 11 system-parent fragments.
NO Production modification was required for the current main4 source defect.
```

## WHAT MUST NOT BE REPEATED

```text
Do not reapply M4-02; it is already present.
Do not edit the old duplicate _saveOrder; it is already removed.
Do not remove the entire save-role callback; only restore its try/catch and else handling as specified.
Do not modify delete-role backend inside main4.
Do not reopen main3 without new direct evidence.
Do not declare main4 closed before fresh full-file read after M4-01 correction.
Do not declare browser/runtime success from source-only verification.
```

## CLOSURE STATUS

```text
Production branch attribution = CLOSED / VERIFIED
Main2 source = VERIFIED / RUNTIME OPEN
Main3 source = VERIFIED AFTER USER PATCH
Main3 S1-S6 = VERIFIED
Main4 Report73 patch = APPLIED
Main4 M4-02 = SOURCE CLOSED / VERIFIED
Main4 M4-01 = SOURCE OPEN / SYNTAX DEFECT
Main4 runtime = OPEN
Employee delete backend = OPEN
Roles RLS governance = OPEN
Delete-role backend = OPEN
11-part integration = OPEN
Full PWA runtime = OPEN
PROJECT CLOSURE = NOT CLAIMED
```

## LAST VERIFIED STATE

```text
LAST VERIFIED MAIN4 SOURCE STATE:
  commit = ee5638b3d71b1c94b4c611003ce8be6831ef8342
  blob   = 932c22c7e0a0285a437729a84b9a1f909bd5f573
  state  = full-source-read verified; M4-02 closed; M4-01 syntax defect open

LAST DOCUMENTATION EVENT:
  Report75 = 075512d42b71edb063b83ef627c5f1d0ebdc09ad
```

## NEXT AUTHORIZED ACTION

```text
USER:
  Apply M4-01 corrected block exactly as specified above.
  Do not touch M4-02.

THEN:
  commit main4.md
  provide new commit SHA + main4 blob SHA

THEN:
  fresh full main4 read to EOF
  verify zero syntax defect in RW_Roles
  verify exactly one _saveOrder
  verify no legacy duplicate order-save chain
  reconcile Production again
  continue main4 integration/runtime verification

ONLY AFTER MAIN4 SOURCE + RUNTIME CLOSURE:
  open delete-employee as the next independent backend Closure Unit.
```
