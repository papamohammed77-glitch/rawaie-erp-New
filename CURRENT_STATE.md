# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14 07:12+03:00

## GOVERNANCE / SOURCE OF TRUTH

التقارير Historical/Reference فقط. لا تُستخدم كبديل عن Production.

الحقيقة المعتمدة دائمًا:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ويُضاف عند إغلاق E2E النظام:
`CURRENT BROWSER / CONSOLE`

**أهم نقطة تنفيذية:** الهدف الجاري هو **E2E لملف النظام الأم الحالي**:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهذا الملف وحده هو Source of Truth للنظام الأم.

Historical reference only: `Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `b6e48193f4042ed6625721aa484c53f6de8cb081`
Direct Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
Parent of Parent: `8392edda5c766fa69c5faea768ca35e35b498b94`
Current `companies/company-1/main.html` blob: `66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`
Current main.html size: `1,087,515 bytes`
Current `companies/company-1/sales/manager.html` blob: `a6021c5dede730b3b2fdb590f4bfafb4467eaf8a`

Latest frontend commit `b6e48193...` updates `sales/manager.html` and its direct parent is `3398d095...` which fixed the forensic master source-of-truth path.

## FORENSIC SOURCE-OF-TRUTH

`erp-frontend/forensic_main_assembly.yml`

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

## MASTER SOURCE READ STATUS

Current master blob/size are proven. The full body of the ~1.09MB file could not be transported by the available GitHub file endpoint to EOF in this environment; Raw fetch and container clone were also unavailable from this runtime.

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Never invent current line numbers or surgical anchors for `main.html`.

## CURRENT PRODUCTION DATABASE

Supabase project: `fiilmooggumokxanwiyx`
Status: `ACTIVE_HEALTHY`
PostgreSQL: `17.6.1.121`

Current production counts:
- companies = `1`
- branches = `2`
- users = `24`
- items = `17`
- orders = `0`
- order_details = `0`
- sales_target_plans = `0`
- sales_target_assignments = `0`
- sales_target_runs = `0`
- sales_target_run_lines = `0`

## SALES TARGETS — CURRENT PRODUCTION

Tables proven:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Current central engine:
`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

Verified operations:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

Current dashboard:
`public.sales_target_dashboard_atomic(uuid,uuid,text)`

Actuals:
`orders + order_details + items`, only `order_status='Invoiced'`, with net quantity `qty - qty_returned`.

Owner wildcard semantics remain:
`permissions=["*"]`.

## TARGET EDGE DEPLOYMENT

`sales-target-engine` — ACTIVE, Version `1`, `verify_jwt=true`.

`sales-target-dashboard` — ACTIVE, Version `1`, `verify_jwt=true`.

Runtime contract:
`JWT → users.auth_id → company_id → target RPC`

Git canonical source for engine:
`Current/Edge_Functions/sales-target-engine/index.ts`

## REALTIME

Direct Production verification through `pg_publication_tables` proves all four target tables are members of `supabase_realtime`:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

`REALTIME = VERIFIED`

## PRODUCTION E2E — SALES TARGET ENGINE

Transactional E2E was executed against current Production and rolled back completely.

Verified:
- temporary plan creation
- temporary assignment creation
- plan approval
- temporary `Invoiced` order
- live dashboard calculation
- Preview
- Post
- Post retry with same `operation_id`
- Run approval
- Run reversal
- rollback with zero test residue

Measured before rollback:
- target amount = `100`
- actual amount = `100`
- amount achievement = `100%`
- target qty = `10`
- actual qty = `1`
- qty achievement = `10%`
- target gross profit = `40`
- actual gross profit = `100`
- gross profit achievement = `250%`

Second POST returned:
`duplicate=true`
with the same Run ID.

After rollback:
- target plans = `0`
- assignments = `0`
- runs = `0`
- run lines = `0`
- orders = `0`
- order details = `0`

`PRODUCTION TARGET TRANSACTIONAL E2E = PASS`
`TARGET TEST RESIDUE = 0`

## IMPORTANT TARGET CONTRACT NOTE

The current `PREVIEW` operation creates a persisted `sales_target_runs` row with status `Preview`.

This behavior was not changed because the historical contract proving that Preview must be read-only was not established. Do not change it by assumption.

## CURRENT SALES MANAGER SOURCE

`erp-frontend/companies/company-1/sales/manager.html`

Current blob:
`a6021c5dede730b3b2fdb590f4bfafb4467eaf8a`

Current target UI source has three proven integration defects:

1. Changing the selected plan calls a full reload that can reset selection to the first plan.
2. `APPROVE_RUN` / `REVERSE_RUN` use the plan ID while the Production engine requires the run ID.
3. POST generates a new `operation_id` on every click, so a network failure after server success can create a second run.

The current UI also lacks complete controls for:
- Plan edit
- Assignment edit / activation state
- Preview
- Selecting a Run for approval/reversal
- Realtime subscription

A complete owner-side surgical replacement is recorded in:
`doc/Draft/Reprots/Report176_SALES_TARGETS_E2E_SYSTEM_CONTROL_20260914.md`

`MANAGER SURGICAL PATCH = READY FOR OWNER`

The replacement passed local Node.js JavaScript syntax validation.

## CURRENT MOTHER UI

No direct edit was made to:
`erp-frontend/companies/company-1/main.html`

Reason:
The owner requires exact surgical deletion/replacement, including exact line and complete end anchor. The full current master body could not be read to EOF in this runtime, so no fabricated line numbers or block anchors were issued.

`MOTHER MAIN UI = OWNER OPEN`

## CURRENT CLOSURE

`SALES TARGET DATABASE = CLOSED`
`SALES TARGET RPC = CLOSED`
`SALES TARGET EDGE = CLOSED`
`SALES TARGET DB INTEGRITY = CLOSED`
`SALES TARGET REALTIME = CLOSED`
`SALES TARGET PRODUCTION E2E = CLOSED / PASS`
`SALES TARGET POST IDEMPOTENCY = CLOSED / PASS`
`SALES MANAGER UI = OWNER OPEN`
`MOTHER MAIN UI = OWNER OPEN`
`BROWSER E2E = OPEN`
`SYSTEM-LEVEL SALES TARGETS = OPEN`

Do not convert backend PASS into browser/system PASS.

## CURRENT RAWAIE-ERP-NEW GIT

Latest HEAD:
`e0bd97f3fa4f975dcc2c00c227316a9ce952a86c`

Direct Parent:
`e7e0ab46c9df19672038ea88854fa8a86908d519`

Latest commits include the prior Sales Targets report/state updates.

## LATEST EXECUTION REPORT

`doc/Draft/Reprots/Report176_SALES_TARGETS_E2E_SYSTEM_CONTROL_20260914.md`

It contains:
- current-truth reconciliation
- Production E2E evidence
- manager current defects
- complete owner surgical replacement for `renderTargets`
- source-of-truth and main.html read-status constraints
- competitor benchmark notes
- final self-audit
- instructions for the next assistant/session

## NEXT SESSION START ORDER — MANDATORY

1. Capture a fresh Production snapshot first.
2. Re-check `erp-frontend` HEAD, Direct Parent, Parent of Parent, master blob and `forensic_main_assembly.yml`.
3. Re-check current Production target tables, RPC definitions, Edge versions, RLS, triggers, Realtime and row counts.
4. Do not re-fix Sales Target backend unless new Production evidence proves regression.
5. Read current `companies/company-1/main.html` completely to EOF before any exact surgery.
6. Treat `Current/PWA/main2/*` as historical reference only.
7. Locate the exact current Sales Target block in `main.html`, record the exact start/end anchors and last complete line, then issue one complete owner-side replacement.
8. Apply the complete `renderTargets` replacement from Report176 to `sales/manager.html` exactly as recorded.
9. Publish the current frontend files.
10. Execute authenticated browser E2E on the newly published version.
11. Test: create/edit plan, assignment create/edit/toggle, approval, preview, post, retry, run approval, reverse, realtime refresh, Console and Network.
12. Reconcile Production again immediately before the final report.
13. Only then set `SYSTEM-LEVEL SALES TARGETS = CLOSED`.
14. Add the next execution report; never delete historical reports.

## FINAL RULE

Never trust a report as current state.
Always reconstruct truth from:

```text
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT EVIDENCE
→ CURRENT BROWSER / CONSOLE
```

Then:

```text
HISTORICAL CONTRACT
→ CURRENT BEHAVIOR
→ ACTUAL GAP
→ SURGICAL FIX
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ OWNER UI SURGERY
→ BROWSER E2E
→ AUDIT / REALTIME
→ RECONCILIATION
→ CLOSE
```
