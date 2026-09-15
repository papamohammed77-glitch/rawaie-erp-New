# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 current session

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
HEAD: `dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`
Direct parent: `f46dfc8183068d0dbf52c1b3b3c8cdbfc9f8f914`
Parent of parent: `8b02f2158021b6ca4ce44ced756459b037fb1ebe`
Current mother blob at HEAD commit: `8bf3ac606cdc2d51c2d705ff5f921e46dbbe6607`

Latest commit `dddf1a...` is the current mother update and already contains the previously requested Sales Targets frontend surgeries. No repeat frontend surgery is justified from the current source alone.

## CURRENT MOTHER / READ STATUS

Current source contains the `RW_SalesTargetsMain` module and the repaired anchors around:
- ~1309: `RW_SalesTargetsMain` module start.
- ~1312: `var postOperationIds = {};`.
- ~1578: Sales Targets action buttons.
- ~1670: `approvePlan()`.
- ~1682: `cancelPlan()`.
- ~1791: `openAssignmentEditor()` reset block.
- ~1857: `postRun()`.

A fresh visual line-by-line display of every current line to EOF was not reproducible because the GitHub environment truncates the very large blob. No fabricated EOF proof is claimed. Historical reconstruction placed the current EOF around 40265 lines after the latest commit, but this remains a reconstruction rather than a fresh visual dump.

## FORENSIC PATH

`forensic_main_assembly.yml` is already aligned to the published mother and remains the correct Source of Truth path. No path change was justified by current evidence.

## SALES TARGETS — CURRENT PRODUCTION

Supabase project: `fiilmooggumokxanwiyx`

Production tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Current business-data counts after transactional E2E cleanup:
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

## SALES TARGETS — PRODUCTION FIXES APPLIED IN CURRENT SESSION

1. Fixed `REVERSE_RUN` idempotency ordering so a retry checks `operation_id` before source-run state. A successful reverse is now repeatable as `duplicate=true` instead of failing because the source run is already `Reversed`.
2. Fixed `SAVE_PLAN` edit ambiguity by qualifying `sales_target_plans` columns where the PL/pgSQL variable `metric` could collide with the table column.
3. Existing Sales Targets protections remain in force: company-scoped user/plan/assignment checks, active-assignment dashboard behavior, exact-scope assignment uniqueness, and run totals snapshot trigger.

## SALES TARGETS — FINAL PRODUCTION E2E

Executed inside a single Production transaction with rollback at the end:

`SAVE_PLAN → EDIT_PLAN → SAVE_ASSIGNMENT → SET_ASSIGNMENT_ACTIVE(false) → SET_ASSIGNMENT_ACTIVE(true) → DASHBOARD → APPROVE_PLAN → CLOSE_PLAN → CLONE_PLAN → APPROVE_CLONE → POST → POST duplicate → APPROVE_RUN → REVERSE_RUN → REVERSE duplicate → CANCEL_PLAN`

Final result: PASS.

The test included real Production RPC execution and did not persist its test fixtures.

## FAILED TESTS DURING THIS SESSION

### Reverse duplicate failure
Root cause: idempotency lookup was after source status validation.
Resolution: idempotency lookup moved before source-run state validation.

### Save plan edit failure
Root cause: unqualified `metric` inside UPDATE created PL/pgSQL/table-column ambiguity.
Resolution: table columns qualified explicitly.

Neither failed transactional test left Production test data behind.

## CURRENT FRONTEND DECISION

The historical Report185 owner surgeries are already present in Current HEAD `dddf1...`:
- `postOperationIds` map.
- manager-only `خطة جديدة / تفريغ النموذج`.
- `canApprove()` guards in approval/cancel paths.
- `إعادة ضبط` in assignment editor.
- per-plan post operation identity.

Do not reapply them unless new browser/served-source evidence proves the deployed asset differs from Current Git.

The reported browser error:
`RW_SalesTargetsMain is not defined`
was not reproducible from the current Git source inspected in this session. Therefore no speculative frontend surgery was performed for it.

## BROWSER / DEPLOYMENT STATUS

Current browser/console/network proof for the exact served page after HEAD `dddf...` remains OPEN.

This environment has no browser-incognito execution capability and no independently verified Cloudflare served-asset snapshot for this session. Therefore:
```text
Production Sales Targets Engine   = VERIFIED
Production Sales Targets E2E      = VERIFIED
Current Git/source baseline       = VERIFIED
Database cleanup                  = VERIFIED
Browser/served-source E2E         = OPEN
Mother UI closure                 = OPEN
```

## REPORTS

Current session report:
`doc/Draft/Reprots/Report186_SALES_TARGETS_CURRENT_PRODUCTION_RECONCILIATION_20260915.md`

Historical reports remain untouched and are reference-only.

## NEXT EXACT CHECKPOINT

1. Start from current HEAD `dddf1aaf5a6e2fe6be7b3d89451dede9c1387258`.
2. Compare the exact served `main.html` asset to current Git before any further frontend surgery.
3. Run fresh browser E2E and capture Console + Network evidence.
4. Verify `RW_SalesTargetsMain` exists in the served page before changing any Sales Targets block.
5. Only after browser proof, continue functional/visual Sales Targets completion and then move to the next unfinished mother tab.

No earlier-fixed Sales Targets backend or frontend changes should be reopened without current evidence.
