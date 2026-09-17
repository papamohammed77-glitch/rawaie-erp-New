# HR / Login Forensic Closure — 2026-09-17

## Mission
Investigate the reported claim that `RW_HR` prevents the system from passing the login screen, without modifying `main.html`.

## Evidence
- Current Mother forensic extract: `FILE_LINES=25374`, `FILE_BYTES=1462518`, SHA256 `ba703e44c5f55ddd55d73df9afed72273f4e64ae6fb76a593ad43d699922b954`.
- Current Mother `RW_HR` starts at line `23788`.
- `RW_Views` references `RW_HR` as a view module before the HR declaration; the HR module is therefore routed as an application view, not as the authentication engine.
- Current HR actor resolution uses `supabase.auth.getUser()` followed by `public.users.auth_id`, matching the current Production user contract.
- Current HR reads use `hr_query`; writes use `hr_command_atomic`.
- Current HR `render()` contains its own error boundary.
- Current Production HR Core was previously verified at DB level; this session found no evidence that HR business tables being empty is an authentication blocker.

## Critical finding
**No causal evidence currently proves that `RW_HR` blocks the login transition.**

The exact current Mother source shows HR as a routed view. Therefore changing HR code merely because the browser remains on the login screen would be an assumption and violates the project evidence hierarchy.

The correct next forensic target is the authentication/bootstrap path in the current Mother `main.html`: sign-in → session/user resolution → application-user resolution → permission resolution → application-shell transition → initial view selection.

## HR-only decision
No Production HR migration was executed.
No `main.html` was modified.
No fabricated HR data was created.
No speculative HR patch was applied.

This is a deliberate forensic closure of the false lead, not a declaration that the global login issue is solved.

## Required next evidence
1. Capture the exact current login/bootstrap block from Mother.
2. Prove whether `RW_HR.render()` is awaited before the application shell is shown.
3. Capture the first browser console/network error during login.
4. Correlate that error to the exact source function.
5. Apply a surgical patch only to the proven cause.
6. Re-run authenticated browser E2E.

## Benchmark note
Odoo, Dynamics 365 Human Resources and SAP SuccessFactors all model HR as a connected domain covering employee records, contracts, attendance/time, leave, approvals and payroll/work data. Their architecture reinforces separating authentication/application bootstrap from HR domain rendering. HR should not be a hidden dependency of global login.

## Self-audit
The conclusion above is based on current Mother source evidence plus current Production HR contract evidence. Historical reports are not treated as current truth.
