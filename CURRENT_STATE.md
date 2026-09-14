# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14 19:xx Africa/Cairo

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
HEAD: `70cc69aece9568374a8e86175e6963cae6832c02`
Message: `Update main.html`
Direct Parent: `9e6645bf3c613f8995785d1fe70a88150ce87c16`
Parent of Parent: `91e50848a65cb0255e95c4e7d8f1a1523eb43e85`

Current mother `main.html` blob:
`43a6061233ad9d7e84e946c9bac9e64297f643a6`

Current source timestamp embedded in file:
`2026-09-14 00:40 UTC`

Current EOF:
`39847 = </html>`

## FORENSIC PATH

`forensic_main_assembly.yml` is already correctly aligned to:

```yaml
source_of_truth:
  repository: papamohammed77-glitch/erp-frontend
  path: companies/company-1/main.html
  ref: main
assembly_status:
  mode: published_main_is_authoritative
  fragment_mode: historical_reference_only
```

No path change was required.

## MOTHER SOURCE — SALES TARGETS

Current verified anchors:

- `sales-targets` exists in `RW_Navigation.menuTree`.
- Dispatcher calls `RW_SalesTargetsMain.render()`.
- `RW_SalesTargetsMain` starts at approximately source line `1311`.
- The current module ends at approximately source line `1481` with `})();` immediately before `_rwCompanyId()`.
- Current helper includes `safeHTML`, `safeText`, and `RW_UI`.
- The old `RW_UI is not defined` root cause is CLOSED in current HEAD.
- `rw-page-container` fix is already present.
- `selectPlan()` dispatcher fix is already present.
- Current main file ends at line `39847` with `</html>`.

## CURRENT SALES TARGET FUNCTIONAL GAP

The current Mother UI exposes:

- Plan creation.
- Draft Plan editing.
- Plan selection.
- Preview.
- Approve / Cancel / Close.
- Post Run.
- Approve Run / Reverse Run.
- Dashboard KPIs.
- Read-only assignment performance.
- Ranking.
- Realtime subscriptions.

But the Mother UI still does NOT expose the backend Assignment lifecycle completely:

- Add Assignment.
- Edit Assignment.
- Activate / Deactivate Assignment.
- Clone finalized Plan / version management from the Mother UI.
- Full target dimensions: amount / quantity / gross profit / weight.
- User/representative and branch selection for assignments.

This is the current functional gap.

## CURRENT OWNER SURGERY

Do NOT repeat the historical `RW_UI` fix.

Do NOT modify the dispatcher, helper, navigation, or historical 11 fragments.

The next Mother-file surgical operation is one exact replacement only:

**Delete current `RW_SalesTargetsMain` block from line 1311 through line 1481 inclusive** and replace it with the complete block in:

`doc/Draft/Reprots/Report183_SALES_TARGETS_FUNCTIONAL_DIAMOND_CLOSURE_20260914.md`

Start anchor:
```js
var RW_SalesTargetsMain = (function(){
```

End anchor:
```js
})();
```

Do NOT delete:
```js
function _rwCompanyId() {
```

The replacement adds the missing Mother-side consumer capability for:

`SAVE_ASSIGNMENT`
`SET_ASSIGNMENT_ACTIVE`
`CLONE_PLAN`

while preserving the existing plan lifecycle and dashboard contract.

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Current verified Production Edge deployments:

```text
sales-target-engine     ACTIVE / version 2 / verify_jwt=true
sales-target-dashboard  ACTIVE / version 1 / verify_jwt=true
```

No new Sales Targets Edge Function was deployed in this session because the existing Production backend already provides the required operations.

Current directly verified Production counts include:

- `sales_target_plans = 0`
- `sales_target_runs = 0`

No permanent synthetic Sales Target data was created in this session.

## SALES TARGET DATABASE CONTRACT

Verified current routines/contract:

- `public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)` — SECURITY DEFINER.
- `public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)` — SECURITY DEFINER.
- `public.sales_target_dashboard_atomic(uuid,uuid,text)` — SECURITY DEFINER.
- `public.sales_target_integrity_guard()` — SECURITY DEFINER trigger function.

Verified engine operations:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

## PRODUCTION HARDENING COMPLETED

`sales_target_integrity_guard()` ACL was hardened previously and remains closed according to current evidence.

Canonical migration:
`supabase/migrations/20260914_sales_target_integrity_guard_acl_hardening.sql`

## CURRENT EDGE IMPLEMENTATION

`sales-target-engine` currently:

- authenticates the Bearer token;
- resolves `auth_id` to `users.company_id`;
- calls `sales_target_engine_gateway`;
- carries operation / plan / payload / operation_id.

`sales-target-dashboard` currently:

- authenticates the Bearer token;
- resolves `auth_id` to `users.company_id`;
- calls `sales_target_dashboard_atomic` for the selected plan.

No new version was deployed because no proven backend defect required it.

## CURRENT COMPETITOR GAP OBSERVATION

Official current competitor documentation confirms that mature target systems expose more than a KPI screen:

- Odoo supports target-based plans, configurable target frequency, measurable achievements, salesperson assignment, approval flow, and progressive levels. citeturn572473search1
- Dynamics 365 supports goal hierarchy, metrics, targets, time periods, rollups, and monitoring across individuals, teams, territories and parent goals. citeturn572473search0turn572473search3
- Daftra exposes sales targets by amount/quantity and performance tracking, with target/commission management around employees and teams. citeturn572473search7turn572473search9turn572473search10

RAWAEA should adopt the useful management principles without copying competitor architecture literally.

## SESSION REPORT

Current report:

`doc/Draft/Reprots/Report183_SALES_TARGETS_FUNCTIONAL_DIAMOND_CLOSURE_20260914.md`

It contains:

- current forensic state;
- latest Git and parent evidence;
- current Mother anchors and EOF;
- verified backend capability;
- precise Owner Surgery;
- the complete replacement block;
- E2E test sequence;
- PASS/FAIL matrix;
- instructions for the next CTO/momentum session.

## CLOSED

`FORENSIC SOURCE OF TRUTH = VERIFIED`
`FORENSIC PATH = VERIFIED`
`CURRENT MOTHER EOF = VERIFIED`
`OLD RW_UI ROOT CAUSE = CLOSED`
`MOTHER DISPATCHER = VERIFIED`
`MOTHER CONTAINER FIX = PRESENT`
`MOTHER selectPlan FIX = PRESENT`
`SALES TARGET BACKEND CONTRACT = VERIFIED`
`SALES TARGET TENANT/AUTHORIZATION = VERIFIED`
`SALES TARGET VERSIONED MANAGEMENT = VERIFIED`
`SALES TARGET EDGE DEPLOYMENT = VERIFIED`
`SALES TARGET DASHBOARD CONTRACT = VERIFIED`
`NO UNNECESSARY PRODUCTION INFRASTRUCTURE CHANGE = VERIFIED`

## OPEN

`MOTHER ASSIGNMENT MANAGEMENT UI = OWNER SURGERY PENDING`
`MOTHER CLONE UI = OWNER SURGERY PENDING`
`MOTHER FULL TARGET MANAGEMENT UX = OWNER SURGERY PENDING`
`LIVE BROWSER E2E = OPEN`
`CURRENT CONSOLE AFTER OWNER SURGERY = OPEN`
`CURRENT NETWORK AFTER OWNER SURGERY = OPEN`
`REALTIME BROWSER RUNTIME AFTER OWNER SURGERY = OPEN`
`SYSTEM-LEVEL SALES TARGETS = OPEN`

## MANDATORY NEXT SESSION ORDER

1. Fresh Production snapshot immediately before work.
2. Re-check frontend HEAD, Direct Parent, Mother blob SHA, and EOF.
3. Do not rebuild from the 11 historical fragments.
4. Read current `RW_SalesTargetsMain` block in Mother again before surgery.
5. Confirm whether Owner Surgery was actually applied.
6. If not, apply the exact line 1311–1481 replacement from Report183.
7. Publish the updated Mother.
8. Run authenticated browser E2E:
   `login → إدارة المبيعات → أهداف المبيعات`.
9. Verify no Console ReferenceError.
10. Verify Network calls to `sales-target-engine` and `sales-target-dashboard`.
11. Test Plan create/edit.
12. Test Assignment add/edit/disable/enable.
13. Test Approve.
14. Test Clone.
15. Test Preview.
16. Test Post and same-operation retry.
17. Test Approve Run.
18. Test Reverse Run and retry behavior.
19. Verify Realtime refresh.
20. Reconcile Production immediately before writing closure.
21. Only then move `SYSTEM-LEVEL SALES TARGETS` to CLOSED.

## GOVERNANCE LOOP

```text
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ CURRENT BROWSER/CONSOLE/NETWORK
→ HISTORICAL CONTRACT (context only)
→ ACTUAL GAP
→ SURGICAL FIX
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ REALTIME/AUDIT
→ FINAL RECONCILIATION
→ CLOSE
```
