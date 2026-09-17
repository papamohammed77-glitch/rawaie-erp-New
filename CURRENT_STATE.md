# RAWAEA ERP — CURRENT STATE

# LATEST VERIFIED SNAPSHOT — 2026-09-18 — HR FORENSIC / SURGICAL CLOSURE

> نطاق الجلسة: HR فقط. `main.html` في Mother لم يُمس.
> التقارير مرجعية تاريخية فقط؛ Source of Truth الحالي هو CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE.

## 1. Current Git

### System repository
`papamohammed77-glitch/rawaie-erp-New`

HEAD before this state update:
```text
96cbd83bf3e69600910ae655eb832a72e3d710c1
```

Parent:
```text
2a10fd7c8ed6f756c61663ef0562c3887c40d76c
```

This session report commit:
```text
71c550da971864a494bf802699d992b9500100e8
```

Primary session report:
```text
doc/Draft/Reprots/HR_FORENSIC_SURGICAL_CLOSURE_20260918.md
```

### Mother repository
`papamohammed77-glitch/erp-frontend`

Current HEAD:
```text
9a0b72ef746f2f6f5c1b149edd2a490df39377c6
```

Parent:
```text
75af385fd4f402c107423a37d0d2b769de152105
```

Previous parent chain includes:
```text
400b16d8cfd6226b02955fe6a2fb76f386e56dde
```

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
