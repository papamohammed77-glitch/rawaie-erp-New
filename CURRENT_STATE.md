# RAWAEA ERP — CURRENT STATE PACK

## CURRENT CHECKPOINT — 2026-09-07

```text
REPOSITORY = papamohammed77-glitch/rawaie-erp-New
BRANCH = main
PRODUCTION = SMART ERP / fiilmooggumokxanwiyx
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

## LAST VERIFIED MAIN4 LINEAGE

### Report73
`4489997677ed593f1567a9fbb398ea6172c8eef5`
Main4 forensic review and exact surgical patch specification.

### Main4 user patch
`42ab7aeb113d64ea08becb134a8e114165594dc1`
`Refactor app settings retrieval and currency usage`
`2026-09-07 09:09:21 UTC`
Historical main4 blob: `7e99ce1d81e2f594f9c2ed811ce5666914b4ceef`

### Report74
`bd287ebb11760bb0a1f6aba063d6ae3be606d1f4`
Main4 post-patch forensic recheck. It identified M4-01 and M4-02 as open at that time.

### Newer Main4 user commit discovered during this recovery
`ee5638b3d71b1c94b4c611003ce8be6831ef8342`
`Update main4.md`
`2026-09-07 09:48:36 UTC`
Current main4 blob: `932c22c7e0a0285a437729a84b9a1f909bd5f573`

This is the current source truth for main4 and was fully re-read during this session.

### Report75
Current-head forensic recheck created during this session. It records the latest main4 state and the remaining source defect.

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

Current app settings:

```text
company_id     = 00000000-0000-0000-0000-000000000001
currency       = SAR
company_name   = الروائع
delivery_fee   = 0.00
min_invoice_amount = 0.00
tax_rate       = 0.00
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

`roles` still has broad policy `Allow all for all` with `qual=true / with_check=true`; this remains a separate security/governance closure.

## MAIN2

```text
PATH = Current/PWA/main2/main2.md
CURRENT BLOB = 58dd0da232ccca4c62bc17d87220bf8b705d85e8
SOURCE INTEGRATION = VERIFIED
BROWSER RUNTIME = NOT VERIFIED
FINAL 11-PART ASSEMBLY = NOT VERIFIED
```

Do not reopen main2 without new direct evidence.

## MAIN3

```text
PATH = Current/PWA/main2/main3.md
CURRENT BLOB = 479060e3d4bea5e2203c87f822b1dbc0e2f7d456
USER PATCH = APPLIED
FULL SOURCE RE-READ = VERIFIED
S1-S6 = VERIFIED
```

Do not reopen main3 without new direct evidence.

## MAIN4 — CURRENT TARGET

```text
PATH = Current/PWA/main2/main4.md
CURRENT BLOB = 932c22c7e0a0285a437729a84b9a1f909bd5f573
FULL SOURCE RE-READ TO EOF = VERIFIED
STATUS = OPEN
```

### RW_POS

```text
app_settings = company-scoped
main_branch_id = company-scoped + branch validation
main branch code = derived from configured branch
currency = app_settings
save-sales-invoice = branchCode
EGP hardcode in reviewed POS path = none
```

### RW_Roles

```text
initial roles read = company-scoped
post-delete roles read = company-scoped
post-seed roles read = company-scoped
save-role backend = company-aware
save-role success refresh = company-scoped
CURRENT DEFECT = try block after save-role token has no catch/finally before callback closes
CURRENT DEFECT = backend failure else branch was removed during patch
```

### RW_TeleSales

```text
app_settings = company-scoped
branches = company-scoped
stock_branches = restricted to current company's branch IDs
_getAvailable = requires selected branch
currency = settings currency
settings failure = blocks save
_saveOrder = exactly one async execution path
legacy duplicate _saveOrder chain = absent
```

## EXACT OPEN PATCH — M4-01

The 11-part system-parent file is edited by the user, not by the assistant.

In `Current/PWA/main2/main4.md`, inside `RW_Roles`, locate exactly:

```javascript
var token = sessionRes.data.session ? sessionRes.data.session.access_token : null;
try {
    var res = await fetch(RW_SUPABASE_URL + '/functions/v1/save-role', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: JSON.stringify(payload) });
```

Delete starting at that `try {` and continue through the `});` immediately before:

```javascript
if (isEdit) {
```

Replace the deleted block with:

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

Leave the following line unchanged:

```javascript
if (isEdit) {
```

Do NOT reapply M4-02.

## VALIDATION STATUS

```text
MASTER = READ TO EOF
CURRENT_STATE = READ / RECONCILED / UPDATED
Report74 = READ TO EOF
Report75 = CREATED
main4 current Blob = VERIFIED
main4 full source read to EOF = VERIFIED
M4-02 = VERIFIED APPLIED
M4-01 = OPEN / SYNTAX DEFECT PROVEN
Production counts/settings/branches = VERIFIED
Production save-sales-invoice contract = VERIFIED
core.js shared primitives = VERIFIED PRESENT
Browser E2E = NOT VERIFIED
main4 browser runtime after corrected M4-01 = NOT VERIFIED
11-part assembly = NOT VERIFIED
Full PWA runtime = NOT VERIFIED
Final Production equivalence = NOT VERIFIED
```

## WHAT I PROVED

- The project was resumed from current evidence, not historical stage numbers.
- `MASTER - RAWAEA ERP.md` was read to EOF.
- `CURRENT_STATE.md` was reconciled with current Git and Production.
- A newer main4 commit existed after Report74: `ee5638b3...`.
- Current `main4.md` blob is `932c22c7...` and was read to EOF.
- The Report74 M4-02 replacement is present.
- There is exactly one `_saveOrder` definition.
- The obsolete duplicate `_saveOrder` chain is absent.
- The M4-01 company-scoped refresh query is present.
- M4-01 is not closed because its surrounding `try` statement lacks `catch`/`finally`.
- Production currently contains one company, two branches, 17 items, 20 roles, 24 users, currency SAR.
- Production `save_sales_invoice_atomic` requires `p_branch_code` and is Security Definer.
- `core.js` contains the shared `supabase`, `byId`, `safeHTML`, `safeText`, `showLoader`, and `hideLoader` primitives used by main4.

## WHAT I DID NOT PROVE

```text
Browser E2E after M4-01 correction
Production runtime of corrected main4
Final 11-part assembly
Full PWA runtime equivalence
Final production equivalence
Delete-employee closure
Roles RLS closure
Delete-role backend closure
```

## SESSION ACTIONS

```text
READ:
  MASTER
  CURRENT_STATE
  Report74
  current Git HEAD
  current main4
  current core.js
  Production PostgreSQL

VERIFY:
  current main4 commit/blob
  M4-01 current structure
  M4-02 current structure
  Production counts/settings/branches
  save-sales-invoice contract
  core.js shared primitives

DOCUMENT:
  Report75 created
  CURRENT_STATE updated

SOURCE MODIFICATION BY ASSISTANT:
  NONE for main4, by explicit user instruction

PRODUCTION MODIFICATION:
  NONE required for current main4 defect
```

## WHAT MUST NOT BE REPEATED

```text
Do not reapply M4-02.
Do not edit the removed legacy _saveOrder block; it is already absent.
Do not delete the entire RW_Roles callback.
Do not remove save-role error handling; restore it with catch + else as specified.
Do not change delete-role backend inside main4.
Do not reopen main3 without new direct evidence.
Do not declare main4 closed before a fresh full-file read after M4-01 correction.
Do not treat source verification as browser/runtime verification.
```

## CLOSURE STATUS

```text
Production branch attribution = CLOSED / VERIFIED
Main2 source = VERIFIED / RUNTIME OPEN
Main3 source = VERIFIED AFTER USER PATCH
Main3 S1-S6 = VERIFIED
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

## NEXT AUTHORIZED ACTION

```text
USER:
  Apply M4-01 corrected block exactly.
  Do not touch M4-02.

THEN:
  commit main4.md
  provide the new commit SHA + new main4 blob SHA

THEN:
  full main4 read to EOF
  verify RW_Roles try/catch/else
  verify exactly one _saveOrder
  reconcile Production again
  continue main4 integration/runtime verification

ONLY AFTER MAIN4 SOURCE + RUNTIME CLOSURE:
  open delete-employee as the next independent Closure Unit.
```
