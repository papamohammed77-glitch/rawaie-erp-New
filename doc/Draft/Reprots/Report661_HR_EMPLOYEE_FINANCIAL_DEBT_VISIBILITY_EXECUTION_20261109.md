# Report661 — HR Employee Financial Debt Visibility: Production Execution and Verification

**Date:** 2026-11-09 (Africa/Cairo)  
**Execution status:** BACKEND APPLIED · PARENT SOURCE COMMITTED · STATIC/LOGIC TESTS PASS · CLOUDFLARE DEPLOYMENT PENDING VERIFICATION  
**Resumed from:** LVE-2026-11-09-660  
**Prior forensic design:** [Report660](Report660_HR_EMPLOYEE_FINANCIAL_DEBT_VISIBILITY_FORENSIC_CHANGESET_20261109.md)

## 1. Executive result

The HR debt-visibility defect is no longer only documented. The narrow repair has been applied to SMART ERP Production and the Parent source has been committed to operational `main`.

The HR advances response now preserves its original `rows` array and additionally returns:
- `financial_balances`: company-scoped employee balances grouped by the existing Employee Financial Subledger views.
- `financial_ledger`: an employee-specific list of at most 200 posted ledger movements when an `employee_id` is supplied; an empty array for the general HR advances list.

The Parent HR Advances view now shows a separate posted-financial position before the existing HR advance/loan documents. Employee 360 now includes per-account financial balances and the latest 30 movements. The HR Realtime channel refreshes on employee-party journal lines, employee-party cash movements, and posted journal-entry status changes.

No new table, view, GL account, cash engine, Payment/Receipt engine, Edge Function, RLS policy, grant, or permanent QA transaction was created. The existing subledger remains the only accounting source.

## 2. Source of truth and exact production baseline

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Governance repository: `papamohammed77-glitch/rawaie-erp-New`, branch `main`.
- Supabase Production project: `fiilmooggumokxanwiyx` (SMART ERP).
- Starting operational HEAD: `940ae61a00c9b6bb3d14544510328afdbadcd2bf`.
- Starting Parent blob: `c11e749c0d3620609e219ca3eea6e37bd9fff104`.
- Starting governance state: `CURRENT_STATE.md` blob `e67b770c587696a277dcce81c193a2ef4c011598`.
- Diagnosis/change-set: Report660 blob `ab076457b76530576f9dab32c6e7db43de91f4a0`.

The root cause remains the one established in LVE660: HR's `hr_query('advances')` consumed `hr_salary_advances` only, while the posted employee debt already existed in the central subledger and Finance Employee Financial 360 already consumed it.

## 3. Production database change — CS-660-A applied

### 3.1 Surgical scope

Only the `p_view='advances'` branch of `public.hr_query(text,jsonb)` was replaced. The branch boundaries were detected against the live `pg_get_functiondef` output and guarded in the deployment block; the operation aborts if either exact boundary is absent.

The original HR `rows` contract remains intact:
- reads `hr_salary_advances` within the current company;
- retains HR-wide or employee-self scope;
- retains the existing ordering and 100-row cap;
- does not transform a request/approval into a posted debt.

The response adds:
- `financial_balances`: reads `public.v_employee_financial_balances`, joins `public.users` by the internal employee Party ID and same company, includes name/email/status, and limits a non-HR caller to their own employee identity. The general HR request includes all employee balances within the current company, including an employee status field so historical balances are not silently hidden merely because the active employee picker excludes inactive people.
- `financial_ledger`: reads `public.v_employee_financial_ledger` only for the requested employee, company-scoped, permission/self-scoped, newest first and capped at 200. It returns an empty array when no employee ID is supplied.

The existing employee Party Subledger views remain the sole accounting source. `outstanding_balance = total_debit - total_credit`: a positive value is a receivable from the employee; a negative value is payable to the employee. The UI does not net these directions together.

### 3.2 Production function metadata after deployment

Live metadata query returned:

| Property | Verified value |
|---|---|
| Signature | `public.hr_query(text,jsonb)` |
| Definition length | 23,554 characters |
| Definition MD5 | `4c6b8006d35e0454e698945ae709260a` |
| Owner | `postgres` |
| SECURITY DEFINER | `true` (pre-existing property preserved) |
| search_path | `public` (pre-existing setting preserved) |
| anon EXECUTE | `false` |
| authenticated EXECUTE | `true` (pre-existing grant preserved) |
| Added response keys | `financial_balances`, `financial_ledger` |

No ACL or role grant was changed. No direct table grant or RLS policy was added.

### 3.3 RLS / identity boundary

The HR identity used in the SQL-level verification was the existing HR user/auth identity already found during LVE660. The employee-self check used the matching employee's existing auth identity and internal Party ID. Both were applied through transaction-local JWT claim settings for database verification; this is **SQL-context simulation**, not a claim that a signed-in HR browser session was available.

The cross-employee self-service request was rejected with `ADVANCE_SCOPE`. The views continue to be scoped by company and the current HR permission or the employee's own Party ID.

## 4. Parent HR UI — committed to operational main

Only `companies/company-1/main.html` was changed.

- Parent UI commit: `8cb7825f3dfc307db57fed239a2f36364252b71a`.
- Commit message: `fix(hr): expose employee financial subledger in HR views`.
- Parent blob after change: `be4e48f52ce7bbf12419e6a1b6560004402485ca`.
- The current operational HEAD subsequently advanced to `035217d96e0aeed37f4dd57652fd509ac86d3774` through the automated forensic extract commit. That commit is a direct child of the UI commit. Its tree still resolves `companies/company-1/main.html` to the exact UI blob `be4e48f52ce7bbf12419e6a1b6560004402485ca`.

### 4.1 HR Advances

Added a separate `المديونيات والأرصدة المالية المرحلة` card before the existing salary-advance/loan documents:
- displays total positive employee receivables separately from total employee payables;
- shows employee, status, financial nature, GL control account, debit, credit, absolute balance and its direction;
- labels the operational custody, temporary advance, salary advance, loan and employee reimbursement payable natures;
- explicitly states that only posted accounting entries are included and unissued/unposted HR requests do not become debts.

The existing HR advance/loan document table, approval action and Payments action were preserved.

### 4.2 Employee 360

Added:
- separate debit and credit totals (no netting);
- balance rows by financial nature/account;
- latest 30 posted employee ledger movements, including date, journal code/type, account, reference/description, debit and credit.

The existing HR salary advance list, payroll, documents, leave, attendance and work-entry sections remain in place.

### 4.3 Realtime

Preserved all existing HR subscriptions, including `hr_salary_advances`, and added:
- `journal_lines` filtered by `party_type=eq.Employee`;
- `cash_box` filtered by `party_type=eq.Employee`;
- `journal_entries` UPDATE filtered by `status=eq.Posted`, so a Draft-to-Posted transition refreshes the view even where the journal lines themselves did not change at posting time.

**Important RLS constraint:** no `buyer_custodies` Realtime listener was added. The currently deployed RLS read policy does not grant the HR role direct access to that table. Employee balances are read through the existing financial views, while Realtime listens only to sources HR can read under current RLS. The posted-journal status listener is company-scoped by the existing journal-entry RLS policy; it may cause a refresh after another company's-in-scope journal is posted, but it does not fetch or expose non-employee line data through this change.

## 5. Verification performed

### 5.1 Pre-deployment SQL rollback test — PASS

Before applying the permanent function replacement, the identical branch-replacement block and validation block were executed inside `BEGIN ... ROLLBACK`. It verified:
1. HR call succeeds and the original `rows` property remains an array.
2. HR receives the existing EGP 5,000 `OPERATIONAL_CUSTODY` balance on account 127.
3. HR Employee 360 receives at least one employee ledger movement.
4. The employee can read their own balances and ledger.
5. The employee cannot request another employee's financial data; the function returns `ADVANCE_SCOPE`.
6. The rollback leaves no permanent test write.

The simulated fixture refers to the existing Production QA record `BC-20261108-28F7B364`; its EGP 5,000 is an owner-confirmed test-data balance, not a claim of real employee debt.

### 5.2 Post-deployment Production verification — PASS

The same checks were executed after applying the branch change. Returned result:
- `success=true`;
- legacy HR advance rows: `0` (the existing test dataset contains no HR salary-advance rows);
- financial balance rows: `1`;
- target account 127 outstanding balance: `5000.00`;
- general list ledger rows: `0` by design, because no employee ID was supplied;
- Employee 360 ledger rows: `1`;
- employee self-scope: success with own balance and ledger;
- cross-employee scope: denied with `ADVANCE_SCOPE`.

Function metadata after the call confirmed the owner, SECURITY DEFINER flag, search_path, anon denial and authenticated grant were unchanged.

### 5.3 Frontend syntax and rendering smoke — PASS

The changed `advancesTab`, `open360` and `realtime` function bodies each passed isolated JavaScript compilation using `new Function`.

A local function-level renderer smoke test with a representative 5,000 EGP account-127 balance confirmed:
- HR Advances generated the financial position card and retained its existing HR advance card;
- Employee 360 generated the financial position card, latest-ledger card, 5,000 EGP balance and a representative journal reference;
- Realtime registered 27 channel listeners in total, including all three new constrained financial listeners, and **did not** register `buyer_custodies`.

These are source/function-level tests with mocked helper functions, not a signed-in visual browser session.

### 5.4 GitHub checks

For Parent UI commit `8cb7825f3dfc307db57fed239a2f36364252b71a`:
- `forensic-main-html`: SUCCESS;
- `verify-canonical-mother-source`: SUCCESS;
- `browser-e2e`: SUCCESS;
- `extract`, `helper-forensic`, `inventory-forensic`: SUCCESS.

The workflow steps show a generic Mother-shell/browser run and a canonical payroll syntax assertion. It is **not** accepted as HR-specific authenticated browser E2E.

## 6. Cloudflare deployment state — NOT YET VERIFIED

At the last inspected GitHub check-run snapshot:
- Cloudflare Pages project `rawaea-erp` was still `in_progress` for commit `8cb7825`; no Success result or deployed preview URL for this commit had yet been confirmed.
- sibling projects `warehouse-supervisor`, `rawaea-store` and `erp-frontend` returned Build Failed for the same commit. Their cause was not diagnosed in this focused HR change and must not be attributed to the Parent HR patch without the individual deployment logs.
- the Cloudflare dashboard browser tab still displayed the previous deployment at `940ae61` when last read; that is a stale dashboard snapshot, not proof of the new deployment.

Accordingly, source commit is **CONFIRMED**, but Pages publication is **PENDING**. Do not claim the updated HR interface is live until the `rawaea-erp` deployment reports Success and serves the new Main blob.

## 7. Supabase advisor observations — baseline warnings, no unrelated repair

Post-change advisors:
- Health: no lints.
- Security: 24 INFO RLS-enabled/no-policy findings; one SECURITY DEFINER view finding for `v_finance_employee_directory`; two anon-callable SECURITY DEFINER function warnings for public storefront RPCs; 131 authenticated-callable SECURITY DEFINER function warnings, including the existing `hr_query`; and one leaked-password-protection warning.
- Performance: 251 unindexed-FK INFO findings, 67 auth RLS init-plan warnings, 124 unused-index INFO findings, 18 multiple-permissive-policy warnings and 8 duplicate-index warnings. The advisor lists an existing duplicate index pair on `journal_lines` (`journal_lines_employee_subledger_idx` / `journal_lines_party_idx`) and an unindexed account FK. No index, policy, other function, or security setting was changed as part of this task.

The existing `hr_query` SECURITY DEFINER warning is visible because authenticated users execute this established RPC. In this change, anon remains denied and the existing company/HR/employee scope checks remain in the function and financial views. Do not switch its execution mode or alter its broader search-path/ACL contract in this narrow repair without a separate full-function security assessment.

## 8. Scope and data integrity

- No new SQL table, view, column, GL account or Edge Function.
- No change to cash_box, treasury balances, journal entries, journal lines, custody rows, inventory or salary-advance documents.
- No new QA fixture and no persistent test data.
- No new grant, RLS policy or direct end-user table access.
- Existing EGP 5,000 QA custody balance remains unchanged.
- HR requested/approved advances remain separate from posted accounting liabilities/receivables.
- Positive and negative employee balances are never netted into a misleading single number.

## 9. Outstanding acceptance gates

1. Confirm Cloudflare Pages `rawaea-erp` deployment for commit `8cb7825` is SUCCESS and deployed Main blob matches `be4e48f52ce7bbf12419e6a1b6560004402485ca`.
2. Sign in with an authorized HR account and visually test the HR Advances summary, employee row details, Employee 360 movements and live refresh after a test-only posted employee journal/cash event.
3. Validate a self-service employee sees only their own financial details through the real authenticated API/browser session, not only through transaction-local SQL claim simulation.
4. Inspect any sibling Pages failures separately before treating them as regressions.

## 10. Rollback and recovery

- Database rollback: restore only the previous `advances` branch body from the pre-change `hr_query(text,jsonb)` definition captured immediately before deployment. Do not drop or recreate the function, because that could alter owner, ACLs or configuration. No data rollback is required.
- Parent source rollback: revert commit `8cb7825f3dfc307db57fed239a2f36364252b71a` through a normal revert commit, preserving the later forensic-extract commit and all unrelated history.
- No Edge Function rollback or data cleanup is required.

## 11. Final classification

| Component | Status |
|---|---|
| Root cause | CONFIRMED |
| SMART ERP RPC change | APPLIED |
| HR balance payload | VERIFIED |
| HR Employee 360 ledger payload | VERIFIED |
| HR self-scope / cross-employee denial | VERIFIED by simulated JWT SQL context |
| Parent Main source | COMMITTED |
| Changed function syntax | PASS |
| Function-level HR/360/realtime smoke | PASS |
| GitHub forensic/canonical/browser workflow checks | PASS, but not HR-specific authenticated E2E |
| Cloudflare `rawaea-erp` deploy | PENDING |
| Authenticated HR visual browser E2E | UNVERIFIED |

**LAST VERIFIED EVENT — LVE-2026-11-09-661:** the HR employee financial subledger has been connected to the existing HR RPC and Parent HR views. Production returns the existing test EGP 5,000 account-127 employee custody balance to the HR response; the UI source is committed and function-level checks pass. Deployment/runtime acceptance remains open pending the target Cloudflare Pages result and a real authenticated HR session.
