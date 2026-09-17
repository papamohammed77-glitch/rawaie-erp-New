# RAWAEA ERP — RW_HR Login Blocker — Surgical Closure Report
## 2026-09-17

## 1. Scope

Critical incident only: the Mother ERP remains on the login screen and Console reports:

```text
(index):64 cdn.tailwindcss.com should not be used in production.
main:23896:3 Uncaught SyntaxError: Unexpected token ')'
```

Constraint: `erp-frontend/companies/company-1/main.html` is **NOT modified by this task**. The required change is prepared as an isolated RW_HR replacement artifact.

---

## 2. Current Git baseline

Latest System commits verified in the current sequence:

```text
8c4b55a8cf3e13cfcafc44ddd86e0a0916222b17
 docs(hr): update current state after login blocker forensic closure

3d368c830d3986e289d6c97b114967ea83cf6463
 docs(hr): record login blocker forensic non-causality

265e0b36e6196e4dee812a52a39a720c34d7efa2
 Update print statement from 'Hello' to 'Goodbye'

ec6ac7c5889d0e4ff4fef849ca1cfda0a85a61ab
 docs(hr): record production login syntax forensic closure

9b97ef495986e1d92a0448985fbb376f1b936a6f
 ci(hr): enforce syntax-safe Mother HR surgical artifact
```

The current-state file was stale relative to the latest Git HEAD and is updated in this closure cycle.

Mother current baseline remains:

```text
repo: papamohammed77-glitch/erp-frontend
file: companies/company-1/main.html
HEAD: 269d3fb7776005ae6c2d9431cf784bde4b434e92
Parent: 2b8ef7a26716470020bb786566210c0c41a434dd
```

Persisted Mother forensic extract:

```text
FILE_LINES=25374
FILE_BYTES=1462518
SHA256=ba703e44c5f55ddd55d73df9afed72273f4e64ae6fb76a593ad43d699922b954
RW_HR start=23788
```

---

## 3. Root-cause determination

The `cdn.tailwindcss.com` message is a production-hygiene warning. It is **not** the parser blocker.

The blocker is a JavaScript syntax error inside the large Mother script, within the RW_HR payroll rendering function `payrollTab`.

The defective expression ends with an extra closing parenthesis:

```javascript
esc(x.status||'-')]))));
```

The syntactically correct expression is:

```javascript
esc(x.status||'-')])));
```

Therefore the direct causal chain is:

```text
extra ')'
→ JavaScript SyntaxError
→ script block cannot be parsed
→ bootstrap/event registration contained in the script cannot execute normally
→ application can remain on the login screen
```

Important distinction:

```text
RW_HR is not the authentication engine.
```

However, because RW_HR is embedded inside the Mother monolithic JavaScript runtime, a syntax error inside the RW_HR block can prevent the enclosing script from parsing/executing and therefore affect the global login/runtime path.

This reconciles the earlier finding that RW_HR is not itself responsible for authentication with the later proven parser failure inside the RW_HR block.

---

## 4. Production comparison

The Production HR Core is not the source of this syntax failure.

Confirmed Production contract remains:

```text
hr_query              = canonical read engine
hr_command_atomic     = canonical write engine
```

Production HR Core was previously verified/hardened, with direct client DML removed and legacy writers retained only for the compatibility window. No Production HR structural change is required to fix this JavaScript parser error.

Therefore:

```text
Production migration required for this incident = NO
Supabase schema change required                 = NO
RLS change required                              = NO
New Edge Function required                      = NO
```

---

## 5. Surgical artifact already prepared

Canonical complete replacement:

```text
doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js
```

Blob SHA:

```text
d02050f9f8131156b5dc283d5229cb1ffff5e5fd
```

The artifact is a complete replacement for **RW_HR only**, not for `main.html`.

Its design is already aligned with the current Production HR Core:

```text
Reads      → hr_query
Mutations  → hr_command_atomic
Identity   → Supabase Auth → public.users.auth_id
```

It exposes the complete HR surface prepared for cutover:

```text
dashboard
employees
Employee 360
organization
contracts
attendance
leaves
requests
advances
payroll
documents
realtime
```

---

## 6. Syntax safety guard

A repository CI guard already exists:

```text
.github/workflows/hr_surgical_artifact_normalizer.yml
```

It is intentionally narrow. It detects the exact known legacy payroll token and normalizes it only when exactly one occurrence exists, then runs:

```text
node --check doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js
```

This guard protects the **surgical artifact**. It does not claim that Mother `main.html` has been cut over.

---

## 7. Exact surgical modification

No broad rewrite is authorized.

The required source operation is exactly:

```text
Mother main.html
→ locate current RW_HR block
→ replace only RW_HR block
→ leave every byte outside that block unchanged
```

Boundary established by current forensic evidence:

```text
START
var RW_HR = (function() {

END
window.RW_HR = RW_HR;
```

Approximate current range:

```text
23788 .. 24064
```

Replacement source:

```text
doc/Draft/Reprots/HR_MOTHER_SURGICAL_REPLACEMENT_20260917_FINAL.js
```

No change to `main.html` has been performed in this task.

---

## 8. Closure status

```text
Root cause identified                         = PASS
Root cause correlated to current source      = PASS
Production HR Core implicated                 = NO
Surgical replacement prepared                = PASS
Artifact syntax guard                         = PASS / PRESENT
Mother main.html cutover                      = OPEN
Served artifact verification                  = OPEN
Authenticated browser login after cutover    = OPEN
Full HR browser E2E                           = OPEN
```

Therefore this incident is **ROOT-CAUSE-CLOSED / IMPLEMENTATION-OPEN**.

It must not be marked fully closed until the replacement is actually assembled into Mother and the authenticated browser gates pass.

---

## 9. Next exact closure sequence

```text
1. Use the canonical surgical artifact.
2. Replace only RW_HR inside Mother main.html.
3. Run full assembled-main syntax validation.
4. Verify no collateral diff outside RW_HR.
5. Deploy the resulting Mother artifact through the approved deployment path.
6. Verify served artifact identity/hash.
7. Run authenticated Login → Company Context → Application Shell.
8. Confirm the Unexpected token ')' error is absent.
9. Open HR.
10. Exercise Payroll tab specifically.
11. Exercise remaining HR tabs.
12. Re-read Production and verify no unintended DB changes.
13. Record runtime evidence.
14. Update CURRENT_STATE.md.
15. Only then mark RW_HR closed.

Do not modify Supabase for this JavaScript syntax incident.
Do not touch main.html outside the RW_HR boundary.
Do not recreate HR Core.
Do not seed HR business data.
```

---

## 10. Session continuation instruction

The next CTO must begin from:

```text
CURRENT GIT
+
CURRENT MOTHER SOURCE
+
CURRENT PRODUCTION
+
CURRENT DATABASE
+
CURRENT DEPLOYMENT EVIDENCE
```

Known fact to preserve:

```text
The login-blocking parser defect is the extra closing parenthesis in RW_HR/payrollTab's final payslip table expression.
```

Known non-causal distinction to preserve:

```text
RW_HR is not the authentication engine; the parser failure inside the monolithic Mother script is what can block global script execution.
```

No historical report may override this without newer primary evidence.
