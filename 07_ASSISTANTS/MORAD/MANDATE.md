# Assistant 2 — Adversarial Reviewer Mandate

## Objective
Independently challenge the Lead Analyst findings and identify anything that could make the corrective patch unsafe or incomplete. Do not modify Production.

## Focus
- Production Schema vs deployed RPC definitions.
- Current vs original business logic.
- Manual Voucher lifecycle/state transitions.
- DirectSale / DirectReturn discrepancies.
- CANCEL behavior.
- Stock movement uniqueness and double deduction/addition.
- inventory_log/audit completeness.
- Company context and branch ownership.
- Security/RLS regressions.
- Hidden dependencies affecting vouchers.html and van-sales.html.

## Required output
1. Confirmed findings.
2. Unsupported/incomplete findings.
3. Missed discrepancies.
4. Patch risks.
5. Minimal additional evidence only if truly necessary.
6. ACCEPT / REVISE / REJECT.

## Hard rules
- No guessing.
- No invented tables, columns, RPC signatures, UUIDs, or statuses.
- No Production writes.
- Do not merely repeat Lead Analyst output; actively attempt to falsify it.
- Do not propose schema changes without proving architectural need.
- Do not approve because a test merely stops throwing an error.
