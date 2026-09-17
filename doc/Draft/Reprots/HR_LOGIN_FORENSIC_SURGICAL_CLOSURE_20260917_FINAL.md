# RAWAEA ERP — HR Login Forensic Surgical Closure

**Date:** 2026-09-17
**Scope:** HR tab / RW_HR only
**Main.html:** NOT MODIFIED

## 1. Evidence hierarchy used

Current truth was rebuilt from:

- current `rawaie-erp-New` Git HEAD and parent
- current `erp-frontend` Mother HEAD and parent
- current Mother `main.html` forensic extract
- current Mother runtime delivery files (`functions/_middleware.js`, `companies/company-1/sw.js`)
- current Supabase Production HR schema/RPC surface
- latest available execution/CI evidence
- current competitor documentation from official Odoo, Microsoft Dynamics 365, SAP SuccessFactors and Daftra sources

Historical reports were used only to locate evidence and prior work. They were not treated as the current state.

## 2. Current Git snapshot at investigation start

### System repository

`papamohammed77-glitch/rawaie-erp-New`

HEAD:
`3a7596e75f564ea09d4071df6cdcca58fc1e2ce9`

Parent:
`aaf06a7988c7c7ecf58b79a93691ae18cd37bc67`

The earlier `CURRENT_STATE.md` entry pointing to Mother commit `269d3fb...` was stale.

### Mother repository

`papamohammed77-glitch/erp-frontend`

HEAD before this closure:
`e1cc27b9a2f58967c6bde340ddb4fbb0d4a507a3`

Parent:
`e17f53d4e6c53389b8666b23b8d3cd4485915cee`

## 3. Production HR architecture verified

Current Supabase Production exposes these relevant HR engines:

- `hr_query(p_view text, p_payload jsonb)`
- `hr_command_atomic(p_command text, p_payload jsonb, p_operation_id text, p_actor_user_id uuid, p_actor_email text)`
- `hr_payroll_calculate_impl`
- `hr_payroll_post_impl`
- `hr_save_attendance`
- `hr_set_leave_status`
- `hr_upsert_employee_profile`
- `hr_user_has_permission`

Current HR tables verified in Production include:

`employee_profiles`, `employee_attendance`, `employee_leave_requests`, `employee_documents`, `hr_departments`, `hr_positions`, `hr_employee_assignments`, `hr_employee_schedule_assignments`, `hr_work_schedules`, `hr_attendance_events`, `hr_work_entries`, `hr_leave_types`, `hr_leave_balances`, `hr_requests`, `hr_request_approvals`, `hr_salary_advances`, `hr_salary_components`, `hr_contracts`, `hr_contract_components`, `hr_payroll_periods`, `hr_payroll_runs`, `hr_payslips`, `hr_payslip_lines`, `hr_payroll_accounting_map`, `hr_command_log`.

No HR business-data seed was created during this incident.

## 4. Forensic reconstruction of the reported browser error

Reported browser output:

```text
(index):64 cdn.tailwindcss.com should not be used in production...
main:23896 Uncaught SyntaxError: Unexpected token ')' / '}'
```

The Tailwind message is a production-hygiene warning. It is not the JavaScript parse blocker.

The current Mother forensic extract proves:

```text
23788: var RW_HR = (function() {
...
23893: }());
23894: realtime();
23895: window.RW_HR={render:render,reload:render,openEmployee360:open360};
23896: }());
23897: window.RW_HR = RW_HR;
```

Therefore the `RW_HR` IIFE is already closed at `23893` and a second unmatched `}());` appears at `23896`.

This is a source-level syntax defect inside the monolithic Mother script.

### Why it can block login

`RW_HR` is not the authentication engine. It is a routed application view.

However, the parse error is inside the Mother monolithic JavaScript block. A syntax error prevents the containing script block from parsing/executing. Any login/bootstrap code contained in that same script block cannot execute normally.

This distinguishes:

`RW_HR != authentication domain`

from:

`RW_HR syntax error -> Mother script parse failure -> bootstrap/login handlers in the same script cannot execute`

No causal claim is made beyond that demonstrated parser relationship.

## 5. Important historical correction

Previous HR reports focused on this older payroll token:

```javascript
esc(x.status||'-')]))));
```

and its correction to:

```javascript
esc(x.status||'-')])));
```

That correction exists as historical work and is not the final cause of the present console location.

The remaining defect found in the current source is the **extra terminal `}());` at line 23896**.

This closure does not repeat the previous payroll repair.

## 6. Surgical strategy

`main.html` was intentionally left untouched.

The production repair was placed in the exact layers that can alter the served/cached HTML before the browser parses it:

1. `functions/_middleware.js`
   - exact route: `/companies/company-1/main.html`
   - exact content type: HTML only
   - existing payroll repair retained
   - new exact RW_HR terminal repair added
   - ambiguous matches are refused rather than guessed
   - `Cache-Control` / CDN no-store headers preserved
   - response marker added: `X-RAWAEA-HR-SHELL`

2. `companies/company-1/sw.js`
   - same exact payroll repair retained
   - same exact RW_HR terminal repair added
   - new `SW_BUILD` invalidates old static cache
   - controlled clients are reloaded after activation
   - ambiguous repair is refused

No HR database migration was required for this JavaScript syntax incident.

## 7. Exact surgical transformation

Target pattern:

```text
window.RW_HR={render:render,reload:render,openEmployee360:open360};
}());
window.RW_HR = RW_HR;
```

Served/cached canonical form:

```text
window.RW_HR={render:render,reload:render,openEmployee360:open360};
window.RW_HR = RW_HR;
```

The transformation is exact and occurrence-count guarded.

## 8. Self-test performed before finalizing

A Node syntax test was executed against a minimal source reproducer containing the exact defect:

- defective source: `node --check` => FAIL with `SyntaxError: Unexpected token '}'`
- repaired source using the same production matching logic => `node --check` PASS
- the repair matcher required the literal IIFE terminator `}());`

During implementation an initial matcher typo (`}();`) was detected by this self-test and corrected before the final Mother commit. The incorrect matcher was never accepted as the final closure.

## 9. Mother production-side commits created

Final Mother HEAD:

`eea3a62903d1533607f753d14c727145838c40e7`

Parent:

`fdf54204246c51ec79e4321e8f5605896dc7ef00`

Final closure changed only:

- `functions/_middleware.js`
- `companies/company-1/sw.js`

A direct Git comparison from the pre-closure HEAD `e1cc27b9a2f58967c6bde340ddb4fbb0d4a507a3` to final `eea3a62903d1533607f753d14c727145838c40e7` shows exactly these two files modified.

`companies/company-1/main.html` was not changed.

## 10. Production HR functional benchmark

### Odoo

Official Odoo documentation connects Employees, Attendances, Time Off, Planning and Payroll; payroll uses work entries derived from these domains.

Sources:
- https://www.odoo.com/documentation/18.0/applications/hr/employees.html
- https://www.odoo.com/documentation/18.0/applications/hr/payroll.html
- https://www.odoo.com/documentation/18.0/applications/hr/payroll/work_entries.html

### Microsoft Dynamics 365 Human Resources

Dynamics documents leave/absence plans with accrual rules, enrollments, balances, carry-over controls and related workforce management behavior.

Source:
- https://learn.microsoft.com/en-us/dynamics365/human-resources/hr-leave-and-absence-plans

### SAP SuccessFactors

SAP documents Employee Central Time Management, time sheets, clock-in/clock-out integrations, employee self-service time recording, approvals and time-off administration. Payroll is a connected Employee Central Payroll capability.

Sources:
- https://help.sap.com/docs/successfactors-employee-central/operating-time-management-in-sap-successfactors/9b874bb10627450fad5c2ceff72c107f.html
- https://help.sap.com/docs/successfactors-time-tracking/manage-time-tracking-test-script/time-statements-new
- https://www.sap.com/products/hcm/employee-central-payroll.html

### Daftra

Daftra currently documents integrated employee records, organization structure, contracts, attendance, leave, requests, payroll, salary components, employee self-service and payroll linkage to approved attendance.

Sources:
- https://www.daftra.com/en/hrm/
- https://www.daftra.com/en/payroll/
- https://docs.daftra.com/en/user_manual/employee-attendance-logs/

### Manager.io

Manager.io is materially narrower than the HR suites above; it should not be used as evidence that a complete HRIS needs only employee records and payroll primitives. RAWAEA's existing HR schema already contains a broader domain surface than a minimal accounting add-on.

## 11. HR contract comparison

| Capability | RAWAEA Production evidence | Benchmark pattern | Gap status |
|---|---|---|---|
| Employee master | `employee_profiles`, `users`, `hr_list_employees` | Odoo / SAP / Daftra central employee records | Present |
| Organization | departments, positions, assignments | Odoo / Dynamics / Daftra organizational hierarchy | Present |
| Contracts | `hr_contracts`, `hr_contract_components` | Odoo / Daftra / SAP | Present |
| Attendance | `employee_attendance`, `hr_attendance_events`, `hr_work_entries` | Odoo / SAP / Daftra | Present |
| Leave | `hr_leave_types`, `hr_leave_balances`, requests | Odoo / Dynamics / SAP / Daftra | Present |
| Requests/approvals | `hr_requests`, `hr_request_approvals` | SAP / Daftra approval workflows | Present |
| Salary advances | `hr_salary_advances` | Daftra-style requests/advances | Present |
| Payroll periods/runs | `hr_payroll_periods`, `hr_payroll_runs` | Odoo / SAP / Daftra payroll cycle | Present |
| Payslips | `hr_payslips`, `hr_payslip_lines` | Odoo / SAP / Daftra | Present |
| Payroll accounting map | `hr_payroll_accounting_map` | ERP/HCM accounting integration pattern | Present |
| ESS / approvals / audit | Production command engine + request tables + `hr_command_log` | SAP/Daftra workflow pattern | Present at backend contract level; browser proof still required |
| Full browser/E2E | Not independently verified in this closure | Mature suites require end-to-end runtime verification | OPEN |

The comparison does not declare a winner. It identifies architecture and capability patterns that are objectively documented by the cited vendors.

## 12. Current closure state

### Proven

- `RW_HR` is a routed view, not the authentication engine.
- Current Mother source contains an extra terminal `}());` after the RW_HR IIFE has already closed.
- This is a real JavaScript parser defect.
- Exact surgical response-layer and service-worker repairs are committed.
- `main.html` was not modified.
- Local syntax self-test passes after the exact transformation.
- Production HR backend contains a centralized `hr_query` / `hr_command_atomic` contract and the expected HR domain tables.

### Not yet proven

- The live deployed URL has not been independently fetched in this session because the production URL is not exposed by the connected GitHub source metadata and no Cloudflare deployment connector is available in this session.
- Therefore served-artifact hash and live browser Login → Shell E2E remain runtime gates.

This is an explicit evidence boundary, not a guessed closure.

## 13. Next-session execution sequence

1. Read this report first.
2. Verify Mother HEAD and parent against live Git.
3. Verify the two repaired delivery files.
4. Verify that `main.html` remains byte-identical to the pre-closure source.
5. Obtain the live production URL from the deployment system.
6. Fetch `/companies/company-1/main.html` and inspect `X-RAWAEA-HR-SHELL`.
7. Verify the served HTML no longer contains the exact extra terminal sequence.
8. Run authenticated browser E2E: Login → session → company context → application shell.
9. Open HR and verify dashboard, employees, organization, contracts, attendance, leaves, requests, advances, payroll, documents and Employee 360.
10. Verify HR realtime behavior and no tenant bleed.
11. Re-read Production after E2E.
12. Only then mark RW_HR Login Runtime Closure = 100%.

## 14. Final governance note

The report intentionally records the live evidence boundary instead of turning a Git commit into a false Production Runtime PASS.

The system is now protected against the exact known RW_HR terminal syntax defect at both server-response and service-worker layers, while the original `main.html` remains unchanged as requested.
