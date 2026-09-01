# RAWAEA ERP — CURRENT STATE PACK

## GOVERNANCE
- Operational truth: current Git main HEAD, Production Supabase, deployed Edge Functions, and runtime verification.
- Historical reports/prompts are evidence only.
- Authorized product target: `Current/PWA/New-main`.
- `Current/PWA/main.html` is protected.
- Prompt 124+ requires no reconstruction, no artificial workflow/executor, no speculative mutation, and no false closure.
- Documentation updates to `CURRENT_STATE.md` and the requested Hany execution report are operational records; product code changes must be confined to the final target artifact.

## P125 — NEW CTO CONTINUITY / FORENSIC REPAIR ROUND — 2026-09-01
### P125-01 — MEMORY_RECOVERY_AND_LATEST_EVENT_RECONCILIATION
- `MASTER - RAWAEA ERP.md` was read completely before execution.
- `تقرير تنفيذي 6` is the latest Hany execution report currently visible; it confirms that prior target repairs persisted and that the unresolved blocker is exact-target runtime proof.
- Current `CURRENT_STATE.md` was read before the new investigation.
- Direct Git history for `Current/PWA/New-main` was inspected. The latest product-target commit before this round is `a5b7aa69f173da5002105023676b1eada0a87c42` (`[new-main-notification-persist] MAIN1 notification contract closure`). Earlier commits explicitly persisted MAIN1 through MAIN11 contracts.
- The current target blob before this round was `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- The existing artificial `TEMP GOLD DIAMOND TARGET EXECUTOR` workflow was inspected and is not an acceptable verification path because it can mutate the target to add closure markers. It will not be used to manufacture proof.
- Supabase direct read confirms the governed production core is active and healthy; no new production mutation was required during this round.
- The direct Prompt-124 path remains unavailable as a Git blob. Its absence is retained as an evidence limitation rather than reconstructed from memory.

### P125-02 — REPAIR_STRATEGY
The large obstacle is explicitly decomposed rather than attacked as one rewrite:
1. Verify the exact target orchestration contract against MAIN10/MAIN11 source contracts.
2. Verify session/auth fail-closed behavior against Current MAIN1.
3. Verify delegated module handlers and route-to-module bindings in the target.
4. Run independent syntax/static checks against the exact target blob.
5. Establish an exact-target browser/runtime execution route without changing the verifier to force green.
6. For any proven defect, make one surgical edit directly in `Current/PWA/New-main` and immediately re-hash.
7. Recheck Supabase/RLS/Edge compatibility after any behavior-changing target edit.
8. Final self-audit, evidence reconciliation, Hany final report, then only if all gates pass declare CLOSED/GOLD/DIAMOND/COMPLETE.

### P125-03 — EFFECTIVE_ORCHESTRATION_AUDIT
- `Current/PWA/New-main` was read completely through its final MAIN11/122/notification closure blocks.
- `MAIN10` defines `RW_Views` with explicit routes including `reports-comprehensive` → `RW_Reports_Comprehensive.render`.
- The final `RAWAEA 122 DIAMOND CONTRACT CLOSURE v1` then redefines `RW_Navigation.navigate` and constructs its own route table.
- In that final route table, `reports` resolves to `window.RW_Reports.render`, while `RW_Reports_Comprehensive` is not wired into that route. This is a contract divergence: the target contains the comprehensive report module and MAIN10's router contract explicitly maps it, but the final navigation closure does not expose that route through `RW_Navigation.navigate`.
- The same 122 `clean()` function removes `online-store`, `purchase-pos`, `branches`, `vehicle-count`, `branch-count`, and `general-count` menu items from the effective tree, while the target retains handlers for those views. This is classified as a navigation-surface divergence pending proof of intended source/delegation policy.
- `MAIN11.boot()` restores session metadata and calls `RW_Auth.enterSystem()`. `enterSystem()` uses the effective `RW_Navigation.buildSidebar()` and `RW_Navigation.navigate('dashboard')`, so the final 122 override is live when DOMContentLoaded fires.
- `MAIN11.boot()` catches `enterSystem()` errors, logs them, then sets `RW_STATE.app.initialized = true` in `finally`. This is a fail-closed concern requiring runtime observation; not yet classified as a proven production defect.
- The final notification closure remains present with `_renderAndSave`, `_updateBadge`, `markRead`, and `_clickNotif`.

### P125-04 — GITHUB_ACTIONS_EXECUTION_EVIDENCE
- Multiple workflows were triggered on documentation HEAD, but representative action-run job queries returned `total_count=0` and no jobs.
- Therefore those runs are not runtime evidence.
- The artificial `TEMP GOLD DIAMOND TARGET EXECUTOR` was intentionally not invoked because it mutates the target to install closure markers.

### P125-05 — CURRENT_DECISION
- The reports-route divergence is a legitimate target contract gap, but a blind full-file replacement is not authorized by the available GitHub write primitive because `update_file` requires the complete replacement content.
- No target mutation has been made in P125 yet. The target blob remains `d657d6e4bdd90a9b60f658a8bf28560e1b10f755`.
- A historical blob containing the desired reports orchestration fix has not been found; the 31d4dc3 commit explicitly adds the 122 closure layer and its reports route remains the same.

### P125-06 — PRODUCTION_RLS_AND_CORE_COMPATIBILITY
- Direct Supabase inspection confirms RLS is enabled on `app_settings`, `budgets`, `cash_box`, `chart_of_accounts`, `customer_followups`, `inventory_log`, `journal_entries`, `journal_lines`, `notification_templates`, `notifications`, `order_details`, `orders`, `stock_branches`, `stock_voucher_details`, `stock_vouchers`, `treasury`, `users`, `workflow_log`, and `workflow_rules`.
- `customer_followups` insert/select/update/delete policies enforce `app_private.customer_belongs_to_current_company(customer_id)`.
- `orders` and `order_details` policies enforce current-company context and appropriate permissions; `stock_branches` is scoped to branches of the current company and warehouse/runsheet/report permissions.
- Notifications are restricted to the authenticated user's email, with same-company insert enforcement.
- `users` write access is restricted by current-company and users permission.
- Finance tables are current-company scoped; journal_lines are accessible only through journal_entries belonging to the current company.
- The apparent `{public}` role on workflow rules/templates is effectively gated by `auth.role()='authenticated'`; no public unauthenticated access is granted by the displayed qualifier.
- No new production data was mutated during this verification.

## CURRENT_STATUS
- Target static integration: `PASS / PRESENT`.
- Main navigation final contract: `FAIL — reports comprehensive route not exposed by MAIN122 final navigation override`.
- Navigation surface: `PARTIAL — several retained handlers are removed from the effective sidebar tree by MAIN122; source intent still requires confirmation`.
- Production RLS/core compatibility: `PASS` on direct read-only inspection.
- Exact target browser/runtime: `UNVERIFIED / BLOCKED` — existing GitHub Actions path produced 0 jobs; no independent current-target runtime proof yet.
- Final `GOLD / DIAMOND / COMPLETE`: `NOT PROVEN`.

## NEXT AUTHORIZED STAGES
7. Identify a trustworthy published/runtime endpoint for the current target SHA or an already-approved exact-target runner that actually executes.
8. Execute syntax/browser verification against that exact target. Record failures.
9. Apply one surgical target-only fix per proven runtime defect, using a safe Git write path that preserves the complete artifact.
10. Re-run every gate; then self-audit and publish Hany final report. Declare `Closed 100% / GOLD / DIAMOND / COMPLETE` only if all gates are current and green.

## HARD RULES
- Product code changes are allowed only in `Current/PWA/New-main`.
- `Current/PWA/main.html` remains protected.
- Do not create additional candidate artifacts, shadow files, reconstruction trees, or artificial workflows.
- Do not call something `Closed`, `Gold`, `Diamond`, or `Complete` without current evidence.
- Do not reopen proven-closed work without new direct evidence.
- Update this file after every logical execution operation.
