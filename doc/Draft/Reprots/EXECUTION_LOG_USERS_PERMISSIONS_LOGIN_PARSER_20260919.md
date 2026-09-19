# EXECUTION LOG — RW_Users LOGIN / PARSER FORENSIC — 2026-09-19

## 1. Governing scope
- Scope: تبويب المستخدمين والصلاحيات فقط.
- main.html: لم يتم تعديله بواسطة CTO.
- Production DB/Edge: لم تُجرَ عليها تغييرات ضمن هذه الجراحة لأنها ليست سبب العطل الحالي.
- Governing loop followed: CURRENT GIT → CURRENT SOURCE → CURRENT PRODUCTION → CURRENT DATABASE → CURRENT DEPLOYMENT → CI runtime → root cause → surgical change set → state update.

## 2. Sources reconstructed
- MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP
- CURRENT_STATE.md
- Report 244 — historical guidance only
- Mother current source: companies/company-1/main.html
- Mother workflow: .github/workflows/browser_e2e_mother_20260915.yml
- Mother forensic/assembly workflows and their runtime logs
- Production Supabase: users, roles, RLS policies, audit_log, current Edge Functions
- Latest Mother commits and direct parent chain

## 3. Current Mother Git lineage
- Mother HEAD at close of investigation: 5da2121beef82840880276d254d8665468420332
- Parent: 904705d9efcadd8e3443f167ce8fa38cb17b0525
- Parent of 904705: 58368091b6b75b861cf2d2aa994ab7c52d7eedaa
- Parent of 583680: 3bc6f6674398931f21fae26b32562587d17b7ebd
- Current main.html blob: 309bf5ea45a8f8a23b77ddf94c295c0c01dd8819

## 4. Proven root cause A — RW_Users tab parser failure

Current Mother commit:
58368091b6b75b861cf2d2aa994ab7c52d7eedaa

Commit message:
Update main.html

Exact diff:
- Previous source used:
  onclick="RW_Users._switchEmpTab(\'basic\')"
- Commit 583680 changed it to:
  onclick="RW_Users._switchEmpTab(\\'basic\\')"

The same four lines were changed:
- 5730 — basic
- 5731 — perms
- 5732 — field
- 5733 — assignments

CI reproduced the exact user-reported failure:
- Workflow: RAWAEA — Forensic Mother Assembly Guard
- Run: 35424752260
- Job: 105848653052
- Failed step: Validate Mother inline JavaScript syntax
- Error:
  /tmp/mother_scripts.js:5588
  SyntaxError: Invalid or unexpected token
  at the basic tab string containing \\'basic\\'

Published-source parser gate also reproduced:
- Workflow: RAWAEA CTO — published main.html full forensic gate
- Run: 35424752242
- Job: 105848653059
- Failed step: Exact JavaScript syntax gate — original published source
- Position:
  /tmp/main-positioned.js:5730
- Error:
  SyntaxError: Invalid or unexpected token

Conclusion:
The login failure is downstream of a JavaScript parse failure in the Mother source. The Tailwind CDN message is a separate warning and is not the parser root cause.

## 5. Proven root cause B — missing openUserPage() closing brace

Current source tail is:

  6087: }
  6089: container.scrollTop = 0;
  6091: return {

The first } closes the isEdit conditional block.
There is no second } closing function openUserPage(email) before the RW_Users return object.

Historical/current CI proof:
Before the 583680 slash regression, the existing parser gate reached the IIFE ending and failed with:
- /tmp/mother_scripts.js:6084
- SyntaxError: Unexpected token ')'

Therefore the correct surgical closure must fix both A and B together. Fixing only the four escaped strings would expose root cause B immediately.

## 6. Already-fixed items verified in CURRENT SOURCE — do not repeat
- renderTable already contains role-based search.
- RW_Users already contains function openUserPage(email).
- RW_Users return object already contains:
  _openModal: openUserPage

No owner changes are requested for these items.

## 7. Production verification
Current live Supabase:
- users = 24
- active_users = 24
- wildcard users = 1
- roles = 20
- system_roles = 3
- audit_log = 1993

OWNER:
- role = مدير النظام
- role_id valid
- permissions = ["*"]
- wildcard semantics remain intact

RLS verified for users, roles, customer_assignments.
Current deployment verified:
- save-employee v10 ACTIVE
- save-role v9 ACTIVE
- delete-employee v4 ACTIVE
- delete-role v4 ACTIVE

Production conclusion:
- No DB migration required.
- No RPC modification required.
- No Edge Function modification required.
- No data repair justified for this parser defect.

## 8. Temporary forensic trigger
A temporary comment was appended to the Mother browser E2E workflow only to force execution of the existing CI proof.
This created a short forensic commit chain.
The workflow was restored exactly afterward in:
5da2121beef82840880276d254d8665468420332

No intended Mother main.html change was made by CTO during this procedure.

## 9. Owner surgical change set

### SURGERY A — four exact string lines
File:
companies/company-1/main.html

Function:
function openUserPage(email)

Find the four current lines at 5730–5733 containing:
  _switchEmpTab(\\'basic\\')
  _switchEmpTab(\\'perms\\')
  _switchEmpTab(\\'field\\')
  _switchEmpTab(\\'assignments\\')

Delete those four lines and replace them with the same four HTML lines using one backslash before each single quote:
  _switchEmpTab(\'basic\')
  _switchEmpTab(\'perms\')
  _switchEmpTab(\'field\')
  _switchEmpTab(\'assignments\')

Change only the escaping. Do not change IDs, labels, function names, or surrounding HTML.

### SURGERY B — close openUserPage()
File:
companies/company-1/main.html

Function:
function openUserPage(email)

Find exactly:
  });
}
  
container.scrollTop = 0;

return {

Replace exactly with:
  });

  container.scrollTop = 0;
}

return {

Do not touch:
  _openModal: openUserPage

## 10. Validation order after owner applies the surgery
1. Verify current Mother HEAD/source.
2. Run RAWAEA — Forensic Mother Assembly Guard.
3. Run RAWAEA CTO — published main.html full forensic gate.
4. Run RAWAEA — Mother System Browser E2E.
5. Verify login screen loads with no page parser error.
6. Open Users & Permissions and verify:
   - user listing
   - role search
   - User 360 editor
   - permission tab switching
   - field settings
   - customer assignments
   - branch scope
   - deactivate user
   - OWNER wildcard behavior
7. Only after those pass, close this closure unit.

## 11. Closure status
RW_Users LOGIN/PARSER CLOSURE:
NOT CLOSED

Reason:
The surgical source corrections cannot be applied by CTO because the owner explicitly requested that main.html changes remain an owner-applied changeset.

Production:
VERIFIED / NO CHANGE REQUIRED

## 12. Next exact resumption
Start from Mother HEAD:
5da2121beef82840880276d254d8665468420332

Then apply only SURGERY A + SURGERY B.
Do not reapply Report 244 wholesale.
Do not modify renderTable.
Do not modify _openModal mapping.
Do not alter Production for this parser issue.

# END LOG
