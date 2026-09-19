# LATEST VERIFIED SESSION — 2026-09-19 — RW_Users LOGIN/PARSER FORENSIC FOLLOW-UP

> This checkpoint supersedes older summaries only for the facts explicitly listed here. Historical material below remains preserved.

## Current Reality — Verified From Current Sources

### Mother System
- Current Mother HEAD at close: `5da2121beef82840880276d254d8665468420332`
- Parent: `904705d9efcadd8e3443f167ce8fa38cb17b0525`
- Last Mother main.html change: `58368091b6b75b861cf2d2aa994ab7c52d7eedaa`
- Parent of that source change: `3bc6f6674398931f21fae26b32562587d17b7ebd`
- Current main.html blob: `309bf5ea45a8f8a23b77ddf94c295c0c01dd8819`

### Proven RW_Users Parser Defects
1. **Root cause A — double escaping**
   - `main.html` lines 5730–5733 currently contain `\\\\'`-level escaping in the generated JavaScript string.
   - Commit `58368091b6b75b861cf2d2aa994ab7c52d7eedaa` introduced this exact four-line change.
   - Current CI reproduces `SyntaxError: Invalid or unexpected token` at the basic-tab expression, positioned at source line 5730.

2. **Root cause B — missing closing brace**
   - In `function openUserPage(email)`, the `isEdit` block closes before `container.scrollTop = 0;`.
   - A second `}` is required after `container.scrollTop = 0;` to close `openUserPage()` before the returned RW_Users API object.
   - Earlier parser evidence reached the IIFE tail and failed with `SyntaxError: Unexpected token ')'`, proving this second defect independently.

### Already Correct — Do Not Reapply
- `renderTable` already searches by name/email/phone/**role**.
- `function openUserPage(email)` already exists in current source.
- RW_Users already maps:
  `_openModal: openUserPage`.

## Production Snapshot — Verified
- users = 24
- active_users = 24
- wildcard_users = 1
- roles = 20
- system_roles = 3
- audit_log = 1993
- OWNER role = `مدير النظام`
- OWNER `role_id` valid
- OWNER permissions = [`*`]
- RLS policies verified on users, roles, customer_assignments.
- Current user/role Edge deployments verified:
  - save-employee v10 ACTIVE
  - save-role v9 ACTIVE
  - delete-employee v4 ACTIVE
  - delete-role v4 ACTIVE
- Production DB/Edge changes required for this parser issue: **NONE**.

## CI Runtime Evidence
- Forensic Mother Assembly Guard run `35424752260`, job `105848653052`:
  - failed inline JavaScript syntax validation at the escaped basic-tab string.
- Published main.html forensic gate run `35424752242`, job `105848653059`:
  - failed at `/tmp/main-positioned.js:5730` with `Invalid or unexpected token`.
- Mother System Browser E2E run `35424752288`, job `105848653233`:
  - blocked before Playwright by an earlier source gate; therefore browser E2E is **not yet PASS**.
- Current CI does not establish Production browser runtime pass until the two owner surgeries are applied and rerun.

## Owner Surgical Changes — Exact
### SURGERY A
File: `companies/company-1/main.html`
Function: `function openUserPage(email)`
Lines: `5730–5733`

Replace the four current lines whose onclick expressions contain:
- `_switchEmpTab(\\'basic\\')`
- `_switchEmpTab(\\'perms\\')`
- `_switchEmpTab(\\'field\\')`
- `_switchEmpTab(\\'assignments\\')`

with the exact same four lines using the single-backslash JavaScript escaping:
- `_switchEmpTab(\'basic\')`
- `_switchEmpTab(\'perms\')`
- `_switchEmpTab(\'field\')`
- `_switchEmpTab(\'assignments\')`

Change escaping only. Do not alter IDs, labels, function names, or surrounding HTML.

### SURGERY B
File: `companies/company-1/main.html`
Function: `function openUserPage(email)`

Find exactly:
```
    });
}

container.scrollTop = 0;

return {
```

Replace exactly with:
```
    });

container.scrollTop = 0;
}

return {
```

The operative change is the added function-closing `}` after `container.scrollTop = 0;`.
Do not modify `_openModal: openUserPage`.

## Documentation
- Corrective report: `doc/Draft/Reprots/Report245_USERS_PERMISSIONS_LOGIN_PARSER_FORENSIC_SURGICAL_CLOSURE_20260919.md`
- Execution log: `doc/Draft/Reprots/EXECUTION_LOG_USERS_PERMISSIONS_LOGIN_PARSER_20260919.md`
- Report 244 remains historical guidance; do not reapply it wholesale.

## Closure Status
- RW_Users LOGIN/PARSER CLOSURE = **NOT CLOSED**
- Root cause = proven.
- Exact owner surgery = prepared.
- Production backend = verified, no change required.
- main.html = intentionally not modified by CTO per owner instruction.
- No 100% closure claim until fresh source syntax gate + browser E2E + functional Users/Permissions verification pass.

## Next Exact Resumption Point
1. Start from Mother HEAD `5da2121beef82840880276d254d8665468420332`.
2. Verify current main.html blob remains `309bf5ea45a8f8a23b77ddf94c295c0c01dd8819`.
3. Apply SURGERY A only.
4. Apply SURGERY B only.
5. Do not touch `renderTable`.
6. Do not touch `_openModal: openUserPage`.
7. Run the existing source syntax gates.
8. Run Mother Browser E2E.
9. Open Users & Permissions and verify the complete current User 360 surface.
10. Only after closure is proven, continue to the next independent business-contract gap.

# LATEST VERIFIED SESSION — 2026-09-19 — RW_Users PAGE SURGERY

> Session continuation checkpoint. This header supersedes older summaries only for the facts explicitly listed here. Historical material below remains preserved.

## Current Reality
- Scope closed in this session: RW_Users / المستخدمون والصلاحيات فقط.
- Current Mother HEAD: 189a2e082569144842bf793e9b3a439363078fdc
- Mother parent: 991b0290ce88c271540cc822d9849128fb1e2dd9
- Mother current main.html blob: 60d61ad247b4172b79ded234b806d6b77c153e1b
- System HEAD after this session documentation: 18c59da8600612f6a53b2d8160fed37b611fc668
- System parent at session start: bb0369f00e11f2b099762d9947e6b3e993fed095

## Production Snapshot Verified
- companies: 1
- users: 24
- active_users: 24
- roles: 20
- active_branches: 2
- audit_log: 1993
- users_without_role_id: 23
- dangling_role_id: 0
- cross_company_role_id: 0
- role_text_mismatch: 0

OWNER:
- role = مدير النظام
- role_id = valid
- permissions = ["*"]
- OWNER wildcard semantics remain unchanged.

## Current Deployment Verified
- save-employee v10 ACTIVE — f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75
- save-role v9 ACTIVE — cd4eb540120d165da4f32465ac9825152d7360a703f0e9d2e2cec497b6ee67be
- delete-employee v4 ACTIVE — 7a2657afff27449026f8bef474e5c9c5f0f001345a1e205efda871f2db6206ae
- delete-role v4 ACTIVE — e9a3837b1df7d93f4447a88bf4f14846f7e6fdf04714699b89fa21adc8d8bd3

## RW_Users Current Source Finding
Current main.html still contains:
- renderTable(data) with a duplicated secondary search condition that must include role.
- function openModal(email) as the current user editor.
- _openModal: openModal in RW_Users return object.
- Current field panel duplicate heading defect.
- Permission list includes items and stock_adjustment and all current application/system permission keys.

## Owner Surgical Change Set
Report:
doc/Draft/Reprots/Report244_USERS_PERMISSIONS_PAGE_FORENSIC_SURGICAL_CLOSURE_20260919.md

Execution log:
doc/Draft/Reprots/EXECUTION_LOG_USERS_PERMISSIONS_PAGE_20260919.md

Owner must apply only:
1. renderTable search-condition replacement.
2. full replacement of function openModal(email) with function openUserPage(email), exactly as Report 244.
3. replace _openModal: openModal with _openModal: openUserPage.

No main.html changes were made by CTO in this session.

## Production Change Status
- No Production migration required.
- No new Edge deployment required.
- Existing backend contract verified sufficient for this UI surgery.
- RLS verified on users / roles / customer_assignments.

## Validation
- Current Git source verified.
- Current Production database verified.
- Current RLS verified.
- Current Edge deployments verified.
- Replacement JavaScript syntax: PASS.
- Browser E2E: NOT RUN.
Therefore:
OWNER SURGICAL CHANGE SET READY
NOT 100% RUNTIME CLOSED.

## Non-Regression Contract
Do not modify:
- post_stock_movement
- reserve_stock
- runsheet lifecycle
- picking
- loading
- delivery
- return
- unloading
- stock vouchers engine
- accounting
- settlement
- OWNER isOwner + permissions:["*"] semantics

## Next Session — Start Here
1. Read this checkpoint.
2. Verify current Mother HEAD and main.html blob again.
3. Confirm Report 244 owner surgery has been applied.
4. Verify renderTable role search.
5. Verify _openModal -> openUserPage.
6. Run Browser E2E on Production.
7. Re-query users/roles/RLS.
8. Close RW_Users only after runtime proof.
9. Do not repeat already closed backend work.

---

# LATEST VERIFIED SESSION — 2026-09-18 — RW_Users FOLLOW-UP FORENSIC SURGICAL CLOSURE

> نطاق هذه الحالة: **RW_Users / المستخدمون والصلاحيات فقط**.  
> مصدر الحقيقة: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.  
> `main.html` لم يُعدَّل بواسطة CTO.

## Current Git — System

- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Current HEAD immediately before this final CURRENT_STATE checkpoint: `da03ad5e204bebe0cb584c2949a7b290d0c96deb`
- Parent: `5757955832baec8c84b1be360df1a10a0a8ce7`
- Source-change HEAD before documentation commits: `08628e01d75fe50ddbde0617c669132322e1b290`
- This checkpoint commit is the final session reference.
- Previous parent chain:
  - `f660a937d16be05e470ec2e94cb3dba8584ffc8e`
  - parent `ecd9afcf462991cdfe107264df90bc51f96e096a`
  - parent `f3c15bac375dfca129e6814603867eed5b53117b`

## Current Git — Mother

- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD: `6f37b88b19e11d2885cfd9b51cc3992d81b5ac47`
- Parent: `55271f8b65c6121085d209b090d2d67117ef9c3e`
- Last main.html-changing commit: `55271f8b65c6121085d209b090d2d67117ef9c3e`
- Parent of main.html-changing commit: `033a5386930cee0d306a3a398a402066e596dfe`
- Current `companies/company-1/main.html` blob: `68ee9c23c876209364f405eed3d23a0c33f9d0ce`
- CTO direct main.html modifications: **0**

## Production Snapshot — post deployment

- companies = 1
- active_branches = 2
- users = 24
- active_users = 24
- roles = 20
- stock_branches = 20
- inventory_log = 3
- audit_log = 1993
- users_without_role_id = 23
- unused_roles = 4

## Production Edge Changes — this closure

- `save-role` v9, `verify_jwt=true`
  - SHA256: `cd4eb540120d165da4f32465ac9825152d7360a703f0e9d2e2cec497b6ee67be`
  - source sync commit: `ecd9afcf462991cdfe107264df90bc51f96e096a`
- `save-employee` v10, `verify_jwt=true`
  - SHA256: `f1ff0999d1e5bef8423ebeaff580e35d16da505134a09087054725bb89480e75`
  - source sync commit: `f660a937d16be05e470ec2e94cb3dba8584ffc8e`
- `bulk-stock-adjustment` v7, `verify_jwt=true`
  - SHA256: `18439000f1e138b56af0b33013729a9ccc469f9b4cf49e9c9bf1bb0c8d3e9a76`
  - canonical source commit: `08628e01d75fe50ddbde0617c669132322e1b290`

## What was closed in Production

- Dynamic role propagation:
  - updated role permissions propagate to active users.
  - direct user permissions are preserved.
  - users receive canonical `role_id`.
  - Auth metadata permissions are synchronized.
  - compensating rollback path exists.
- User save:
  - explicit password required on CREATE.
  - no default `123456` fallback.
  - role must exist within current company.
  - `role_id` is stored canonically.
  - audit failure rolls back DB/Auth.
- Stock adjustment:
  - backend requires `stock_adjustment` for non-owner.
  - owner wildcard semantics preserved.
  - branch and item context are company-scoped.

## Current Mother source findings

The current Mother `main.html` already contains the prior 8 RW_Users surgical changes from `55271f8...`.

Two **new** source defects were proven in the current blob and were NOT fixed by CTO:

1. `RW_Users.openModal` parser defect around global line ~5694:
   missing `+` after the literal `'</div>'`.
2. `RW_Users.openModal` permission-list regression around global line ~5530:
   `items` permission was replaced by `stock_adjustment` instead of both being present.

### Owner surgical patch gate

Exact replacements are in:
`doc/Draft/Reprots/Report243_USERS_PERMISSIONS_FOLLOWUP_FORENSIC_SURGICAL_CLOSURE_20260918.md`

Required owner actions:
- fix DEFECT-01 exact block;
- restore `items` beside `stock_adjustment` in DEFECT-02.

No wholesale main.html replacement.

## User/Role data integrity exception intentionally left open

`mostafa@rawaea.com`:
- role = `موظف`
- role_id = NULL
- no matching role exists
- permissions = []

No speculative role assignment was executed.

No bulk `role_id` backfill was executed.

No unused role was deleted.

## Competitive capability gaps left as future closure units

Not production bugs; do not reopen without fresh evidence:

- generic CRUD/action matrix;
- generic record rules;
- generic field-level permissions;
- permission simulator / Login-as;
- device/session management;
- audit/history UI;
- broader reusable policy inheritance.

## Verification boundary

**VERIFIED**
- current System/Mother git refreshed.
- current main.html blob inspected.
- Production snapshot refreshed after deployment.
- three required Edge deployments are active.
- source/deployment parity for changed Edge functions recorded.
- no Production business counts changed.

**OPEN**
- owner source cutover in main.html.
- Browser E2E for RW_Users.
- full live runtime closure of the tab.

## Authoritative artifacts

- Report: `doc/Draft/Reprots/Report243_USERS_PERMISSIONS_FOLLOWUP_FORENSIC_SURGICAL_CLOSURE_20260918.md`
- Execution log: `doc/Draft/Reprots/EXECUTION_LOG_USERS_PERMISSIONS_FOLLOWUP_20260918.md`

## Next-session entry

Start from:
CURRENT_STATE → System HEAD/parent → Mother HEAD/parent/blob → Production users/roles snapshot → deployed Edge metadata → owner surgical gate → browser E2E.

Do not reopen any prior closed change without new Current Evidence.

---

# LATEST VERIFIED SESSION — 2026-09-18 — RW_Users USERS & PERMISSIONS FORENSIC SURGICAL CLOSURE

> هذه هي أحدث حالة تنفيذية. Current Truth = CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> نطاق هذه الوحدة: RW_Users / المستخدمين والصلاحيات فقط. main.html لم يُعدّل بواسطة CTO.

## Current System Git

- Repository: papamohammed77-glitch/rawaie-erp-New
- Report commit: d2617bbcb940df1dc01cdf74438c8bd59fc0929b
- Execution log commit: 4cabe17b46491c25c957a2662e65e9c05fe3248a
- Current HEAD immediately before this CURRENT_STATE update: 4cabe17b46491c25c957a2662e65e9c05fe3248a
- Direct parent: d2617bbcb940df1dc01cdf74438c8bd59fc0929b
- User/Role source closure commits:
  - 893a5df53a3d35f3bf74741e6f1811b7a1cee756
  - 76e5f1c4e5738385e22c60ff072575e32a258893
  - d02b384f10b46d8b3fa6f0d34a662fa1d4b790f5
  - dfd7072fad75bc39a5415c1354009427bcfc013b

## Mother Current Git

- Repository: papamohammed77-glitch/erp-frontend
- HEAD: 033a5386930cee0d306a3a398a402066e596dfe
- Direct parent: aa6e8177ab32f45fed08a07113b83eb9c6aa7fd1
- Current main.html blob: 506bc3fc22036bb9ef2d23d93e753060ccced563
- main.html lines: 26,221
- main.html size: 1,425,430 bytes
- CTO main.html modifications in this closure: 0

## Production Snapshot

- companies=1
- active_branches=2
- active_items=16
- users=24
- active_users=24
- roles=20
- orders=0
- purchase_orders=0
- receiving=0
- runsheets=0
- stock_branches=20
- inventory_log=3
- audit_log=1993

## Production User/Role Integrity

- users.is_owner: DOES NOT EXIST
- Owner contract users: 1
- users without role_id: 23
- dangling role_id: 0
- cross-company role_id: 0
- text role / role_id mismatch: 0
- active users with users permission but without roles permission: 0
- active users with roles permission but without users permission: 0

Unused Roles found but not deleted:
- أمين مخزن (system)
- امين مخزن (custom)
- مسئول مشتريات
- مشرف مشتريات

No role_id bulk backfill was executed.

## Production Edge Closure

- save-employee v9, verify_jwt=true
- delete-employee v4, verify_jwt=true
- save-role v8, verify_jwt=true
- delete-role v4, verify_jwt=true

Deployment boundary:
Deployment/source/database evidence verified.
Live Browser E2E after Mother cutover remains open.

## Current Source Surgical Targets — Owner Only

Apply only the exact blocks recorded in:
doc/Draft/Reprots/Report242_USERS_PERMISSIONS_FORENSIC_SURGICAL_CLOSURE_20260918.md

Targets:
1. Owner filter in renderTable
2. fail-closed users/roles loading in render
3. remove fake role fallback
4. phone/role filtering in filterTable
5. add stock_adjustment to direct user permission list
6. preserve existing custom permissions against role permissions
7. preserve custom-permission toggle state
8. change user action wording from Delete to Deactivate

Do not replace main.html wholesale.

## Closure Boundaries

Closed:
- Production user-management actor authorization
- Owner protection
- Auth/user synchronization
- wildcard protection
- role deletion protection
- role rename protection
- explicit users/roles audit on managed mutations
- System Source alignment with deployed User/Role Edge functions

Open:
- Owner application of main.html surgical patches
- Browser E2E verification
- Dynamic role propagation / role_id reconciliation
- generic CRUD permission model
- generic record rules / field-level permission model
- user permission simulation UI

## Next Session Entry Rule

Start from:
CURRENT_STATE.md
+
current System HEAD/parent
+
current Mother HEAD/parent
+
current main.html blob
+
current Production
+
current deployed Edge metadata

Do not reopen any closed User/Role Edge fix without new Current Evidence.
Do not touch Inventory, Runsheet, Reports, HR, CRM, or separate operational apps unless a separate Current-Evidence closure is opened.

## Authoritative Session Artifacts

- Report: doc/Draft/Reprots/Report242_USERS_PERMISSIONS_FORENSIC_SURGICAL_CLOSURE_20260918.md
- Execution log: doc/Draft/Reprots/EXECUTION_LOG_USERS_PERMISSIONS_20260918.md

---

# RAWAEA ERP — CURRENT STATE

## LATEST VERIFIED SESSION — 2026-09-18 — COMPREHENSIVE REPORTS CURRENT RUNTIME FORENSIC / SURGICAL CLOSURE

> هذه هي أحدث حالة مثبتة لهذه الجلسة. المصدر الحاكم: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> نطاق الجلسة: RW_Reports_Comprehensive فقط. main.html لم يُعدّل بواسطة CTO.

### Current Git — System Repository
- Repository: papamohammed77-glitch/rawaie-erp-New
- Session report commit: d69201bbbf9492b2d073207fdc2d8762e71dd12d
- Current branch HEAD: أحدث commit على main يحتوي هذا الـCURRENT_STATE checkpoint.
- Previous state checkpoint commit: 2861919a190c3c8004bcfa06241300d6eb85ecf5
- Previous report-state commit: eaf272ac291681212e228463e5bfd8c0e107b123
- Inventory turnover production migration: f8117693e8b7c6f1d6a4aaffbb0f17765f4aa064
- Current report: doc/Draft/Reprots/Report239_COMPREHENSIVE_REPORTS_CURRENT_RUNTIME_FORENSIC_SURGICAL_CLOSURE_20260918.md

### Current Git — Mother Repository
- Repository: papamohammed77-glitch/erp-frontend
- Current HEAD: 7a1edbc31861fb87720b0f0455bd1e3a15cb0b0b
- Direct parent: d662cfb14c7c5b4889d0fdbc4d7c6898330d82e9
- Current companies/company-1/main.html blob: 618a3dc0a74d20b0c533c9393a663a1849d0f926
- Current main.html size: 25,905 lines
- Mother HEAD commit did not modify main.html; it modified forensic extract only.
- main.html CTO modifications in this session: 0.

### Current Comprehensive Reports Source
- Module: RW_Reports_Comprehensive
- Current source boundary: approximately lines 19,844–23,381.
- Report definitions: 38.
- Sections: Sales, Inventory/Purchases, Finance, CRM, Logistics, HR.
- Current source parser before surgical repair: FAIL — Invalid or unexpected token.
- Confirmed defects:
  1. malformed _generateReport() button-string construction around line 20,144;
  2. malformed newline literals in _exportReportCsv();
  3. literal </script> embedded in _printReport() around line 23,359;
  4. stale finance-tax description contradicting currently available Production tax reporting contracts.
- In-memory surgical reconstruction against the exact current blob:
  - RW_Reports_Comprehensive parse = PASS.
  - Full inline script V8 parse = PASS.
  - malformed _generateReport('' occurrences = 0.
  - literal </script> count = 6.
- The embedded </script> is the causal explanation to test first for later console warnings in lines 23,496–25,702; do not create separate patches for those warnings before browser retest.

### Current Production Database
- Project: fiilmooggumokxanwiyx
- Companies: 1
- Company: 00000000-0000-0000-0000-000000000001 / الروائع
- Active branches: 2
- Active items: 16
- Orders: 0
- Purchase Orders: 0
- Receiving: 0
- Runsheets: 0
- Journal Entries: 2
- Daily Settlements: 0
- Stock rows: 20
- Inventory log rows: 3
- Cross-company stock/item mismatch: 0
- Cross-company inventory_log/item mismatch: 0

### Current Production Reporting Contracts
Verified directly under authenticated company context:
- inventory_movement_report
- inventory_replenishment_report
- comprehensive_inventory_turnover_report
- finance_tax_report
- finance_tax_settlements_report
- accountant_gl_account_activity
- accountant_period_readiness
- accountant_reconciliation_summary
- accountant_exception_center
- get_trial_balance
- get_profit_loss
- get_balance_sheet_data
- get_cash_flow

Read-only/transactional probes:
- inventory_movement_report = success
- inventory_replenishment_report = success
- comprehensive_inventory_turnover_report = success
- finance_tax_report = empty current result
- finance_tax_settlements_report = empty current result
- get_trial_balance = 17 rows
- get_profit_loss = 0 rows
- get_balance_sheet_data = valid JSON
- get_cash_flow = 0 rows
- accountant_period_readiness = 5 rows
- accountant_reconciliation_summary = 4 rows
- accountant_exception_center = 0 rows

No synthetic business data was retained.

### Production Change Required for This Closure
- Reporting database migration required: NO.
- Reporting schema change required: NO.
- Reason: the current defect is Source JavaScript / HTML parsing integrity. The required Production reporting contracts already exist and were verified.

### Owner Surgical Source Gate
The exact four source-only changes are documented in:
doc/Draft/Reprots/Report239_COMPREHENSIVE_REPORTS_CURRENT_RUNTIME_FORENSIC_SURGICAL_CLOSURE_20260918.md

They target only RW_Reports_Comprehensive:
1. Replace the malformed report-action button block.
2. Replace function _exportReportCsv() completely.
3. Escape the embedded script closing tag in _printReport() from </script> to <\/script> in the JavaScript source string.
4. Update the stale finance-tax description only.

Do NOT replace all main.html.
Do NOT modify neighboring modules before browser retest.

### Closure Status
- Current Git = VERIFIED
- Current Mother source = VERIFIED
- Current Production reporting contracts = VERIFIED
- Source root cause = PROVEN
- Exact surgical patch = READY
- In-memory repaired source parse = PASS
- main.html CTO modification = 0
- Production DB change for this closure = 0
- Owner source cutover = PENDING
- Browser E2E = OPEN
- 38-report live smoke = OPEN
- Comprehensive Reports full closure = OPEN until owner cutover + browser verification

### Next Session Starting Point
1. Re-read Report239.
2. Verify System HEAD/parent again.
3. Verify Mother HEAD/parent and main.html blob again.
4. Confirm whether owner applied exactly the four surgical changes.
5. Verify malformed _generateReport('' count = 0.
6. Verify no literal </script> remains inside RW_Reports_Comprehensive.
7. Run V8 parser on the full inline script.
8. Open Comprehensive Reports.
9. Smoke-test all 38 report IDs.
10. Test عرض التقرير / تحديث / CSV / طباعة / رجوع.
11. Re-check Console after parser and HTML termination are clean.
12. Re-read Production counts after browser.
13. Only then close Comprehensive Reports.
14. Do not reopen inventory/picking/loading/delivery/CRM/HR/accounting engines without fresh evidence.

---

## LATEST VERIFIED SESSION — 2026-09-18 — COMPREHENSIVE REPORTS FORENSIC/SURGICAL CLOSURE

> هذا القطاع هو أحدث حالة مثبتة ويعلو على أي snapshot أقدم أدناه.  
> مصدر الحقيقة: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

### Current Git — System Repository
- Repository: `papamohammed77-glitch/rawaie-erp-New`
- Latest session commit: `46eecdbd61d188a664a5650852b6bb6c5904c9e0`
- Direct parent: `c7b6f37a40d1ef66e68569806552b60ad5dd8653`. The production migration commit immediately before the report is `f8117693e8b7c6f1d6a4aaffbb0f17765f4aa064`.
- Production migration commit for inventory turnover: `f8117693e8b7c6f1d6a4aaffbb0f17765f4aa064`.
- Comprehensive reports forensic report:
  `doc/Draft/Reprots/Report238_COMPREHENSIVE_REPORTS_FORENSIC_SURGICAL_CLOSURE_20260918.md`

### Current Git — Mother Repository
- Repository: `papamohammed77-glitch/erp-frontend`
- Current HEAD verified: `fdfdb2bf03271e8eedad81ad8400c243b89c33a5`
- Direct parent verified: `d265bb72a64f4bbabf9c125a1b5bba5d17ffd799`
- Current Mother `main.html` blob: `468da111b9da992331dba9162c6c6e6509b76004`
- Current Mother main.html: 25,837 lines / 1,413,915 characters.
- main.html was NOT modified by this session.

### Comprehensive Reports Module
- Module: `RW_Reports_Comprehensive`
- Source boundary: approximately lines 19,844–23,313 of current Mother main.html.
- Verified report definitions: 38.
- Sections: Sales, Inventory/Purchases, Finance, CRM, Logistics, HR.
- No report outside this module was intentionally modified.

### Production Database
- Project: `fiilmooggumokxanwiyx`
- Current company count: 1.
- Current company: `00000000-0000-0000-0000-000000000001`.
- Active branches: 2.
- Active items: 16.
- Orders: 0.
- Purchase Orders: 0.
- Receiving: 0.
- Runsheets: 0.
- Journal Entries: 2.
- Daily Settlements: 0.
- Stock rows: 20.
- Cross-company stock item rows: 0.
- Cross-company inventory_log item rows: 0.
- Cross-company order_detail item rows: 0.

### Production Reporting Contracts Verified
- `inventory_movement_report`
- `inventory_replenishment_report`
- `finance_tax_report`
- `finance_tax_settlements_report`
- `accountant_gl_account_activity`
- `accountant_period_readiness`
- `accountant_reconciliation_summary`
- `accountant_exception_center`
- `get_trial_balance`
- `get_profit_loss`
- `get_balance_sheet_data`
- `get_cash_flow`

### Production Change Executed In This Session
New reporting-only contract:
`public.comprehensive_inventory_turnover_report(uuid,date,date,uuid)`

Canonical migration:
`supabase/migrations/20260918_comprehensive_inventory_turnover_report.sql`

Status:
- Production deployed.
- Auth guard verified.
- Unauthenticated/no-company-context execution rejected.
- Authenticated context returned the correct current company.
- No operational stock/order data was modified.

### Source Surgical Work Prepared — Owner Managed
Exact source replacements are documented in Report238 for:
- report UX/open-report controls
- CSV export
- report freshness metadata
- realized sales filtering
- item-sales quantity handling
- cost-based inventory valuation
- inventory movement report wiring
- low-stock report wiring
- inventory turnover/dormant report wiring
- Finance GL wiring
- Treasury company scope
- Finance Tax wiring

Owner must apply these to the current Mother source. Do NOT replace the whole main.html.

### Deliberately Untouched
- Sales transaction engines.
- Inventory physical stock writers.
- Picking / Loading / Delivery / Return workflows.
- Runsheet lifecycle.
- CRM transaction engines.
- HR transaction engines.
- Existing reports without a proven contract gap.

### Verification Status
- Current Git: VERIFIED.
- Current Mother Source: VERIFIED.
- Current Production Database: VERIFIED.
- Current Production reporting RPCs: VERIFIED.
- New Inventory Turnover Production contract: DEPLOYED + AUTH VERIFIED.
- Mother source cutover: PENDING OWNER.
- Browser E2E after source cutover: OPEN / NOT VERIFIED.
- Overall Comprehensive Reports closure: OPEN UNTIL OWNER CUTOVER + BROWSER E2E.

### Next Session Start Point
1. Re-read Report238 in full.
2. Verify current System HEAD again.
3. Verify current Mother HEAD and main.html blob again.
4. Re-open only `RW_Reports_Comprehensive`.
5. Confirm the owner-applied surgical replacements against the exact current blob.
6. Run syntax verification.
7. Run authenticated browser smoke tests for the 38 report IDs.
8. Re-read Production after browser actions.
9. Close only the remaining browser/runtime gate.
10. Do not reopen any operational engine already closed.

---

# LATEST VERIFIED SNAPSHOT — 2026-09-18 — CRM FORENSIC / SURGICAL CLOSURE

> نطاق هذه الجلسة: **CRM فقط**. لا إعادة فتح لأي مسار سابق، ولا تعديل لـ `main.html` بواسطة CTO.
> Source of Truth: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> التقرير التنفيذي: `doc/Draft/Reprots/CRM_FORENSIC_SURGICAL_CLOSURE_20260918.md`

## 1. Current Git at CRM checkpoint

### System repository
`papamohammed77-glitch/rawaie-erp-New`

CRM session HEAD:
`5e103748d65fb4c9c0988a6c89dbffb58708642d`

Previous parent:
`d224caf54aeab08abd75b4347848918a52e80da4`

CRM report commit:
`1597df279466b2b55e16fad7ead0aa1c2fe455eb`

CRM migration finalization commit:
`d224caf54aeab08abd75b4347848918a52e80da4`

### Mother repository
`papamohammed77-glitch/erp-frontend`

Current Mother HEAD recorded in latest state:
`9a0b72ef746f2f6f5c1b149edd2a490df39377c6`

Current `companies/company-1/main.html` blob:
`8ba8ef60c2875ea68ed85283ce772e023c0ef771`

CRM source block:
- line 23899 → 24017
- exact marker: `// RW_CRM – إدارة علاقات العملاء (CRM)`
- CTO source modification count in Mother: **0**

## 2. CRM Production closure

Applied Production migrations:
`20260918053518 crm_customer_360_closure_20260918`
`20260918053550 crm_customer_360_ordered_arrays_fix_20260918`

Canonical CRM Production functions:
`crm_customer_directory`
`crm_customer_360`
`crm_set_customer_assignment`
`crm_set_customer_followup_status`
`crm_save_customer_followup`

Final Production definition fingerprints:
- `crm_customer_360` = `6ca15b1a6d3a1001b77dba89b5cb3030`
- `crm_customer_directory` = `75f297aaa97d315dbfed6bb461e17f6c`
- `crm_save_customer_followup` = `b8bbd0d0ca83da7dea49aba460289c09`
- `crm_set_customer_assignment` = `6672a76b20077ebc63b3a06a6d576651`
- `crm_set_customer_followup_status` = `1a5dd26c1087c6e48841fc8df55d03e8`

## 3. Production CRM data state

Current Production:
`customers = 3`
`customer_followups = 0`
`customer_assignments = 0`
`customer_ledger = 0`
`orders = 0`

No synthetic CRM business data remains.

## 4. What was proven

- Current CRM was reconstructed from the actual Mother blob.
- CRM was confirmed to be a lightweight follow-up list, not a Customer 360.
- Existing `RW_Customers` remains the customer master CRUD surface.
- No current CRM inventory/order/runsheet/finance writer exists.
- Production RLS/company boundary was verified.
- Customer 360 read contract passed under an authenticated CRM user context.
- Follow-up create/status/assignment commands passed inside a rollback transaction.
- Existing audit mechanism `fn_audit_trigger()` now covers `customer_followups` and `customer_assignments`.
- Production returned to its original business-data counts after rollback.
- Current Mother `main.html` was not modified.
- Competitor benchmark was checked against official Odoo, Dynamics 365, SAP Sales Cloud, Daftra and Manager.io documentation.

## 5. Target CRM behavior now defined

`Customer Directory`
→ `CRM KPI`
→ `Customer 360`
→ profile/contact
→ assignments
→ follow-up lifecycle
→ sales/order history
→ runsheet/delivery context
→ customer ledger

CRM remains a **read/control cockpit** and does not replace ERP engines.

## 6. Owner surgical integration gate

The exact source replacement is in:
`doc/Draft/Reprots/CRM_FORENSIC_SURGICAL_CLOSURE_20260918.md`

Target:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Exact source block:
line **23899–24017** in blob:
`8ba8ef60c2875ea68ed85283ce772e023c0ef771`

Do not edit any other main.html module.

After owner integration:
1. verify old CRM block occurs 0 times;
2. verify replacement occurs 1 time;
3. run JS syntax check;
4. open CRM;
5. open Customer 360;
6. create one follow-up;
7. complete/reopen/cancel it;
8. assign a company user;
9. verify customer/order/runsheet/ledger sections;
10. verify no neighboring module regression;
11. re-check Production counts and audit log.

## 7. Explicit non-actions

Do not:
- modify `main.html` outside the exact CRM block;
- alter `RW_Customers`;
- alter order/runsheet/delivery/inventory writers;
- replace `customer_followups.customer_id TEXT` without a new proven contract;
- create a parallel CRM engine;
- declare browser Production PASS from SQL PASS.

## 8. Next-session starting sequence

Start by refreshing:
`CURRENT_STATE`
→ System HEAD/parent
→ Mother HEAD/parent
→ current main.html blob
→ Production CRM function definitions
→ CRM counts

Then verify the owner source integration gate above.

Only after authenticated browser CRM is green should the next CRM Closure Unit open.

## 9. CRM closure status

`PRODUCTION CRM CORE = CLOSED`
`PRODUCTION DATA INTEGRITY = CLOSED`
`PRODUCTION AUDIT BOUNDARY = CLOSED`
`SOURCE SURGICAL PATCH = READY`
`MOTHER main.html CTO edits = 0`
`LIVE BROWSER CRM = OPEN UNTIL OWNER PATCH + RUNTIME EVIDENCE`

---

# RAWAEA ERP — CURRENT STATE

# LATEST VERIFIED SNAPSHOT — 2026-09-18 — HR TAB RUNTIME EXPORT ROOT CAUSE

> نطاق هذه الحالة: HR tab runtime only. main.html لم يُعدل من هذه الجلسة.
> التقرير التنفيذي: doc/Draft/Reprots/HR_TAB_RUNTIME_FORENSIC_CLOSURE_20260918.md

## Current Truth

### System repository
HEAD:
cd8a2ef714be4ba069f1e1606359bb348dd560a0

Parent:
2a6965377e8872b642bc14e659e18507992965d7

Baseline before this session's documentation commits:
fee9cf2a1cfcd020d67093d4c0633edfa574ed70

### Mother repository
HEAD:
b0d4475576f712057340821653d4a3a9d08e14e6

Parent:
29631c0e910b25b77fc5d4e2dda8efca8adfdb20

Current main.html blob:
6dbca77b5e0fe569f3435fd39f965002dc7c0d2b

Current main.html forensic SHA256:
b6f079ce423d1869c672ba265d2c473a5fc3853f8f2ea0cf1949e02c83e5d218

## HR runtime root cause — PROVEN

RW_HR opens at line 23788 as:
var RW_HR = (function() {

RW_Views.render calls at line 23741:
if (view === 'hr') { RW_HR.render(); return; }

RW_HR.render exists at line 23902.

Current terminal:
23932: realtime();
23933: window.RW_HR={render:render,reload:render,openEmployee360:open360};
23934: }());
23935: window.RW_HR = RW_HR;

There is no module-level return inside RW_HR IIFE.

Therefore:
RW_HR = undefined
and then:
window.RW_HR = undefined

This exactly explains:
Cannot read properties of undefined (reading 'render')

The defect is Module Export Contract Failure, not a current Parser Failure.

## Historical proof

Commit 15325117153959536d8035b603ef9cfd64fc736d removed the RW_HR IIFE close while retaining:
window.RW_HR = RW_HR;

Commit 48139d0b711496712d3c43572eef0e0e4ee5934c restored only the outer script-final closure.

Commit 1f3e89e8761e34e3982746ae93ab0260e4d4b1a4 restored RW_HR IIFE closure but still did not add the required return.

Do not rewrite HR and do not patch RW_Views for this incident.

## Owner Surgical Changeset — READY

File:
companies/company-1/main.html

Exact current block at lines 23932–23935:

  realtime();
  window.RW_HR={render:render,reload:render,openEmployee360:open360};
}());
window.RW_HR = RW_HR;

Delete that block and replace it with:

  realtime();
  return {
    render: render,
    reload: render,
    openEmployee360: open360
  };
}());
window.RW_HR = RW_HR;

No other main.html element is authorized by this incident.

## Production

Supabase HR core verified:
hr_query
hr_command_atomic
hr_user_has_permission
hr_payroll_calculate_impl
hr_payroll_post_impl
hr_list_employees
hr_save_attendance
hr_set_leave_status
hr_upsert_employee_profile

Current Production HR operational domain tables are empty; no fabricated HR business data exists.

No Production DB migration is required for this root cause.
No Production data repair is required for this root cause.
No new middleware/SW workaround is required.

## Closure status

CURRENT SOURCE ROOT CAUSE = PROVEN
PRODUCTION HR CORE = VERIFIED
OWNER SURGICAL PATCH = READY
MAIN.HTML MODIFIED BY CTO = 0
PRODUCTION DB CHANGE = 0
LIVE BROWSER AFTER OWNER PATCH = OPEN
FULL HR E2E = OPEN

## Next exact session

1. Verify Owner applied only the exact surgical block above.
2. Verify the defective block occurs 0 times.
3. Verify the replacement return block occurs 1 time.
4. Run JS syntax validation.
5. Verify typeof RW_HR === 'object'.
6. Verify typeof RW_HR.render === 'function'.
7. Open HR from Mother navigation.
8. Smoke-test all ten HR tabs read-only.
9. Only after live browser closure open the next HR Closure Unit.
10. Do not reopen inventory/runsheet/delivery/picking/accounting without direct new evidence.


# LATEST VERIFIED SNAPSHOT — 2026-09-18 — HR LOGIN PARSER ROOT-CAUSE / SURGICAL PATCH READY

> نطاق الجلسة: HR / Mother login parser فقط. `companies/company-1/main.html` لم يُعدل في هذه الجلسة.
> مصدر الحقيقة: CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.
> التقرير التنفيذي: `doc/Draft/Reprots/HR_LOGIN_FORENSIC_SURGICAL_ROOT_CAUSE_20260918.md`

## 1. Current Git

### System repository
`papamohammed77-glitch/rawaie-erp-New`

Latest system commit:
```
78da908d23be6ae64f544bf46abf9a5d0d6be3ea
```

Parent:
```
79b16b22c5fe5b22fa0e9aa37d7026269394dbe0
```

Previous implementation/evidence commit:
```
a58c53e4ef8e90b719ab6bc22679446455a9297a
```

### Mother repository
`papamohammed77-glitch/erp-frontend`

Current HEAD:
```
6a9cfb3b28b27023320f4a0cd8c049e76d0fc6db
```

Parent:
```
1a8d0144446fe42b706eadd5683f6789dbbfac2f
```

Current `companies/company-1/main.html` blob:
```
a2551e35b50c3fa8de03114ea54094e0eaca14dd
```

## 2. Forensic root cause

Current source inspection proved two independent syntax defects inside `RW_HR`:

### Defect A — modal()

Location:
```
RW_HR / global line 23818
function modal(title,body,onSubmit,key)
```

The function is missing one final `}`.

Individual V8 parser result:
```
Unexpected token ')'
```

### Defect B — RW_HR IIFE closure

RW_HR opens at global line 23788:
```
var RW_HR = (function() {
```

Current source has:
```
window.RW_HR={render:render,reload:render,openEmployee360:open360};
window.RW_HR = RW_HR;
```

The required RW_HR closure is missing between those two lines:
```
}());
```

Historical Git proof:
- commit `15325117153959536d8035b603ef9cfd64fc736d` removed that exact `}();` from the RW_HR boundary.
- commit `48139d0b711496712d3c43572eef0e0e4ee5934c` restored only the file-final `})();`.
- current final `})();` therefore closes the wrong remaining scope and is where the browser reports `Unexpected token ')'`.

The inner:
```
(function installModalResilience(){ ... }());
```
at the end of RW_HR is not the RW_HR module closure.

## 3. Parser proof

Current full inline JavaScript:
```
FAIL — Unexpected token ')'
```

Current `modal()` alone:
```
FAIL — Unexpected token ')'
```

After exactly these two source changes:
1. replace `modal()` with the complete corrected function in the session report;
2. insert the exact `}());` at the RW_HR boundary before `window.RW_HR = RW_HR;`;

the same current inline JavaScript was re-parsed with V8 `new Function()`:
```
PASS
```

No other HR source element was required for the parser closure.

## 4. Tailwind warning

`cdn.tailwindcss.com should not be used in production` is a production-use warning only.
It is not the causal JavaScript parser error for this incident and was not modified.

## 5. Mother protection

``

## 2. main.html protection

`companies/company-1/main.html` was NOT modified in this session.

Current Mother main blob checked:
```text
8ba8ef60c2875ea68ed85283ce772e023c0ef771
```

No direct edit to main.html was performed.

## 3. Parser incident — current truth

The historical incident was:
```text
main:25370 Uncaught SyntaxError: Unexpected token ')'
```

Current Mother source was re-inspected before changing it. The currently stored main artifact has the canonical RW_HR terminal and no newly proven parser defect.

The old reports that described an unmatched second `}());` were not accepted as current truth without source verification.

The Tailwind CDN message is a production warning, not the JavaScript parser cause.

The remaining practical risk was a stale/deployed artifact or old runtime route rather than a justified new edit to `main.html`.

## 4. HR runtime routing — CLOSED

Current `companies/company-1/app.html` previously sent:
```text
permission=hr
    ↓
/companies/company-1/office/hr.html
```

That file is a Legacy HR application with its own direct user queries/cache and incomplete Attendance/Salary surfaces.

It is no longer the runtime target.

Current route:
```text
permission=hr
    ↓
/companies/company-1/main.html
    ↓
Mother HR / RW_HR
```

Git commit:
```text
400b16d8cfd6226b02955fe6a2fb76f386e56dde
```

## 5. Direct `/hr` route — CLOSED

Current `_redirects` previously had:
```text
/hr /companies/company-1/office/hr.html 200
```

It now has:
```text
/hr /companies/company-1/main.html 200
```

Git commit:
```text
75af385fd4f402c107423a37d0d2b769de152105
```

This removes the legacy HR application from the normal runtime entry path without deleting historical code.

## 6. Service Worker republish boundary — CLOSED

Current SW build:
```text
RAWAEA_SW_P156_HR_REPUBLISH_20260918
```

Git commit:
```text
9a0b72ef746f2f6f5c1b149edd2a490df39377c6
```

The existing SW contract remains:
- HTML/navigation/API/runtime are network-backed.
- Static assets use versioned cache.
- Old static caches are removed on activation.
- Controlled windows are navigated after activation.
- Known RW_HR response repairs remain in place.

## 7. Production HR database

Supabase project:
```text
fiilmooggumokxanwiyx
```

Core HR engines verified:
```text
hr_query
hr_command_atomic
hr_payroll_calculate_impl
hr_payroll_post_impl
hr_save_attendance
hr_set_leave_status
hr_upsert_employee_profile
hr_user_has_permission
```

The core HR domain tables exist. No fabricated HR business data was added.

## 8. Production security closure — actor identity

Finding:
`hr_command_atomic` allowed caller-supplied `p_actor_email` to differ from the actor user identity.

Fix:
```text
hr_command_log_enforce_actor_identity()
```

Trigger:
```text
trg_hr_command_log_actor_identity
```

Behavior:
- actor_user_id must exist in the same company.
- actor_email is derived from `public.users`.
- invalid actor/company context is rejected.

Migration:
```text
hr_command_log_actor_identity_guard_20260918
```

Production transactional test with spoofed email proved the stored actor became:
```text
actor_user_id = 67552c18-144e-453f-b0e8-5b7730b929d6
actor_email   = hr@rawaea.com
```

## 9. Production security closure — employee documents DML

Migration:
```text
hr_employee_documents_table_dml_boundary_20260918
```

Applied:
```sql
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
ON TABLE public.employee_documents
FROM anon, authenticated;
```

The current design continues to use the HR command capability for metadata, while direct public table mutation is removed.

## 10. HR authorization context

Real Production HR user verified:
```text
email      = hr@rawaea.com
auth_id    = 99eea49f-c27d-43e1-85b9-c97d4d85c55b
company_id = 00000000-0000-0000-0000-000000000001
permission = hr
```

JWT-context test verified:
```text
auth.uid()
auth.role()
app_private.current_user_company_id()
hr_user_has_permission(...,'hr')
hr_query('self',...)
hr_query('dashboard',...)
hr_query('employees',...)
```

OWNER wildcard semantics were not changed.

## 11. Current HR functional scope

Mother HR source has the integrated HR tab family:
```text
dashboard
employees
organization
contracts
attendance
leaves
requests
advances
payroll
documents
```

Current Production has no HR business fixtures, therefore full transactional E2E is not declared closed.

## 12. Competitive benchmark snapshot

Verified against current official documentation:

- Odoo: employee master, contracts, attendance/time off, payroll and work entries.
- Microsoft Dynamics 365 Human Resources: time & attendance, calculation/approval groups, absence setup and time updates.
- SAP SuccessFactors: Time Management, time sheets, clock-in/out, approvals, alerts and payroll integration.
- Daftra: employee records, organization, contracts, attendance, leave, requests/loans, dynamic salary components, payroll and ESS-oriented capabilities.
- Manager.io: employee and payroll capabilities tied to accounting, used as a narrower benchmark.

These benchmarks are used to identify future capabilities, not to justify copying external product behavior.

## 13. Closure status

```text
HR source reconstruction                 = VERIFIED
HR legacy runtime route                  = CLOSED
Direct /hr legacy route                  = CLOSED
Mother SW republish boundary             = CLOSED
main.html modifications                  = 0
Production actor identity                = CLOSED
Production employee_documents DML        = CLOSED
Production HR auth context               = VERIFIED
Current Mother Git                      = VERIFIED
Current System Git                      = VERIFIED
Live deployed artifact                   = NOT INDEPENDENTLY VERIFIED
Authenticated live browser E2E            = OPEN
Full HR transactional E2E                = OPEN
```

Do not convert the first six states into `PRODUCTION BROWSER PASS` without live browser evidence.

## 14. Next session protocol

1. Start from this exact CURRENT_STATE and verify the System and Mother HEAD/parent chain.
2. Verify `main.html` blob remains unchanged.
3. Obtain/fetch the actual deployed Mother URL.
4. Confirm the served `app.html`, `_redirects`, and `sw.js` correspond to the current Mother HEAD.
5. Confirm the live `/hr` route no longer serves `office/hr.html`.
6. Confirm the live browser reaches Mother login without `Unexpected token ')'`.
7. Run authenticated HR login → session → company → Mother HR.
8. Run one read-only smoke for each HR tab.
9. Create test data only through an isolated test/transaction harness; never seed fake Production business data just to obtain PASS.
10. Only after runtime evidence is green, open the next HR Closure Unit.

## 15. Governance rules carried forward

- Reports are historical evidence, not the current state.
- Never repeat a closed fix without new evidence.
- Never edit `main.html` for this incident unless fresh current-source evidence proves a defect there.
- Never create a second HR runtime engine.
- Never claim browser Production PASS from Git/SQL PASS.
- Keep HR operations behind the Mother `hr_query` / `hr_command_atomic` contract.
- Preserve OWNER `isOwner + permissions:["*"]` semantics.
- Any new HR feature must be a closure unit: contract → source → DB → permissions → runtime → verification.
