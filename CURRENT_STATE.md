# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 03:xx UTC / current session

## SOURCE OF TRUTH

التقارير Historical/Reference فقط، ولا تُعامل كحالة حالية.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser/System E2E يلزم أيضًا:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Source of Truth للنظام الأم:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical fragments only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `f46dfc8183068d0dbf52c1b3b3c8cdbfc9f8f914`
Direct parent: `8b02f2158021b6ca4ce44ced756459b037fb1ebe`
Parent of parent: `70cc69aece9568374a8e86175e6963cae6832c02`
Current mother blob: `460e6772c365e573bfc69f6c2240ccfe65b51eb2`

Latest commit `f46dfc...` removed the illegal trailing backslashes from `openAssignmentEditor()`. The older Report184 syntax blocker is now STALE/closed at source level.

## FORENSIC PATH

`forensic_main_assembly.yml` is verified current and already points to the published mother.

## CURRENT EOF / READ NOTE

A complete historical read of the previous mother was documented with EOF at line 39847. Commit `8b02...` added 393 net lines and current `f46dfc...` kept line count in the repaired block unchanged, giving reconstructed current EOF 40240.

Because GitHub's large-blob renderer truncated the huge file in this environment, direct display of every current line to EOF was not independently reproducible in the chat tool. This is explicitly NOT claimed as a fresh line-by-line visual proof.

## SALES TARGETS — CURRENT PRODUCTION

Supabase project: `fiilmooggumokxanwiyx`

Production tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Current business-data counts after E2E cleanup:
```text
plans       = 0
assignments = 0
runs        = 0
run_lines   = 0
```

Production target engine:
- `sales-target-engine` ACTIVE, verify_jwt=true
- `sales-target-dashboard` ACTIVE, verify_jwt=true

RPCs:
- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

Supported operations:
`LIST_PLANS, LIST_ASSIGNMENTS, LIST_RUNS, SAVE_PLAN, SAVE_ASSIGNMENT, CLONE_PLAN, SET_ASSIGNMENT_ACTIVE, APPROVE_PLAN, CLOSE_PLAN, CANCEL_PLAN, PREVIEW, POST, APPROVE_RUN, REVERSE_RUN`

## SALES TARGETS — PRODUCTION FIXES APPLIED

1. Added exact-scope unique index with `NULLS NOT DISTINCT` on `(plan_id, sales_rep_id, branch_id)`.
2. Replaced `sales_target_dashboard_atomic` so only active assignments participate in assignment results, joins are company-scoped, and company-period actual totals are calculated once to avoid assignment-overlap double counting.
3. Added `sales_target_run_totals_snapshot()` and trigger `trg_sales_target_run_totals_snapshot` to keep run parent totals aligned with run-line snapshots and plan-period actuals.

## SALES TARGETS — VERIFIED PRODUCTION E2E

Verified sequence:
`SAVE_PLAN → SAVE_ASSIGNMENT → DASHBOARD → APPROVE_PLAN → POST → POST duplicate → APPROVE_RUN → REVERSE_RUN → REVERSE duplicate`

The first consolidated test had a reverse-step failure that was not reproducible after isolation. A committed Production test proved:
- POST = PASS
- APPROVE_RUN = PASS
- REVERSE_RUN = PASS
- reverse idempotency = PASS

All E2E test data was deleted afterward.

## CURRENT MOTHER — OWNER SURGERY REQUIRED

The assistant does not edit `erp-frontend/companies/company-1/main.html` by project governance. Exact owner surgery is recorded in:
`doc/Draft/Reprots/Report185_SALES_TARGETS_ENGINE_FORENSIC_E2E_20260915.md`

Required changes:
1. Replace `var postOperationId = null;` with `var postOperationIds = {};`.
2. Replace the complete `postRun()` function with the Report185 version so operation identity is scoped per plan.
3. Align `approvePlan()` and `cancelPlan()` guards with `canApprove()` because backend requires approval permission.
4. Replace the conditional `تفريغ` button with manager-only `خطة جديدة / تفريغ النموذج`.
5. Add the exact `إعادة ضبط` block to `openAssignmentEditor()` from Report185.

Already-fixed `RW_UI`, dispatcher, navigation and login syntax must not be reworked.

## BROWSER E2E STATUS

`CURRENT BROWSER / CONSOLE / NETWORK` was not independently proven in this environment.

Therefore:
```text
Backend production closure           = VERIFIED
Database integrity closure           = VERIFIED
Current Git/source baseline          = VERIFIED
Owner frontend surgery               = REQUIRED / PREPARED
Current browser E2E                  = OPEN
Full Sales Targets UI closure        = OPEN until owner surgery + browser proof
```

## HISTORICAL FILES

`Report183_SALES_TARGETS_FUNCTIONAL_DIAMOND_CLOSURE_20260914.md` and `Report184_LOGIN_SYNTAX_FORENSIC_CLOSURE_20260914.md` remain historical evidence only.

## CURRENT SESSION REPORT

`doc/Draft/Reprots/Report185_SALES_TARGETS_ENGINE_FORENSIC_E2E_20260915.md`

## NEXT EXACT CHECKPOINT

1. Owner applies the exact `main.html` surgeries from Report185.
2. Confirm current Git HEAD/SHAs again.
3. Publish the current mother.
4. Run fresh browser E2E and capture Console/Network evidence.
5. Verify Login parser PASS.
6. Verify Sales Targets create/edit/assignment/approve/post/reverse UI against the Production engine.
7. Only then mark Mother UI Sales Targets closure 100%.
