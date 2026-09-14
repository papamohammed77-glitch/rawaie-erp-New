# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

## GOVERNANCE / SOURCE OF TRUTH

التقارير Historical/Reference فقط. لا تُستخدم كبديل عن Production.

الحقيقة المعتمدة دائمًا:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

**أهم نقطة تنفيذية:** الهدف الجاري هو **E2E لملف النظام الأم الحالي**:
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

وهذا الملف وحده هو Source of Truth للنظام الأم.

Historical reference only: `Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
Direct Parent: `8392edda5c766fa69c5faea768ca35e35b498b94`
Parent of Parent: `faf18cae4b629e1b1f87fca7414a147f6befb541`
Current `companies/company-1/main.html` blob: `66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`
Current main.html size: `1,087,515 bytes`

## FORENSIC SOURCE-OF-TRUTH

`erp-frontend/forensic_main_assembly.yml`

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

Proven by frontend commit `3398d0952ea723d1de42b076ad93ae19c025bfa3`.

## MASTER SOURCE READ STATUS

Current master blob/size are proven, but this environment cannot retrieve the ~1.09MB body line-by-line to EOF. Raw retrieval is also blocked.

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Never invent current line numbers or surgical anchors.

## CURRENT PRODUCTION DATABASE

Supabase project: `fiilmooggumokxanwiyx`
Status: `ACTIVE_HEALTHY`
Region: `eu-west-1`
PostgreSQL: `17.6.1.121`

### Sales Targets

Production tables proven:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Persistent rows after transactional tests:
- plans = `0`
- assignments = `0`
- runs = `0`
- run_lines = `0`

Production engine:
`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

Verified operations:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

Owner wildcard semantics remain `permissions=["*"]`.

## SALES TARGET PRODUCTION ADDITIONS — 2026-09-14

Implemented directly in Production:

1. `public.sales_target_integrity_guard()`
2. `trg_sales_target_assignment_integrity`
3. `trg_sales_target_run_line_integrity`
4. `public.sales_target_dashboard_atomic(uuid,uuid,text)`

The dashboard returns:
- plan
- assignment performance
- live totals
- ranking
- daily trend

Actuals are from `orders + order_details + items`, filtered to `order_status='Invoiced'`, using net quantity `qty - qty_returned`.

### Git canonical source

Migration:
`supabase/migrations/20260914070000_sales_target_live_dashboard_and_integrity_guard.sql`

## CURRENT EDGE DEPLOYMENT

Existing:
`sales-target-engine` — ACTIVE, Version `1`, `verify_jwt=true`.

New:
`sales-target-dashboard` — ACTIVE, Version `1`, `verify_jwt=true`.

Git source:
`Current/Edge_Functions/sales-target-dashboard/index.ts`

Runtime contract:
`JWT → users.auth_id → company_id → target RPC`

## REALTIME

Directly verified through `pg_publication_tables` that all four target tables are members of `supabase_realtime`:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

An ADD TABLE attempt correctly returned duplicate-membership and made no change.

`REALTIME = VERIFIED`

## PRODUCTION TESTS

### Live Dashboard

Transactional E2E:
- temporary plan created
- temporary assignment created
- dashboard RPC executed
- response shape verified
- transaction rolled back

`DASHBOARD_E2E = PASS`

`Target test residue = 0`

### Cross-company test

A valid second-company test is not available because current `companies` contains only the Production Company. Invalid foreign context is rejected by existing FK/company constraints before Target mutation.

## CURRENT SALES MANAGER SOURCE

`erp-frontend/companies/company-1/sales/manager.html`

Blob:
`60c6281d2a07e59d82391c225c701fc2cbb6fdff`

Current `renderTargets` is a local reporting view: direct `orders` read, `created_by` aggregation, hard-coded target `50000` ج.م, no Sales Target Engine call.

`CURRENT MANAGER TARGET UI = NOT E2E`

Complete owner-side replacement is recorded in:
`doc/Draft/Reprots/Report175_SALES_TARGET_E2E_LIVE_CONTROL_20260914.md`

## CURRENT MOTHER UI

No direct edit was made to:
`erp-frontend/companies/company-1/main.html`

Owner remains responsible for master-file surgery.

Exact current line-level surgery is not proven because the full current master body is not retrievable in this environment.

## CURRENT CLOSURE

`SALES TARGET DATABASE = CLOSED`
`SALES TARGET RPC = CLOSED`
`SALES TARGET EDGE = CLOSED`
`SALES TARGET DB INTEGRITY GUARDS = CLOSED`
`SALES TARGET REALTIME = CLOSED`
`SALES TARGET LIVE DASHBOARD = CLOSED`
`SALES TARGET BACKEND = CLOSED`
`SALES MANAGER UI = OWNER OPEN`
`MOTHER MAIN UI = OWNER OPEN`
`BROWSER E2E = OPEN`
`SYSTEM-LEVEL SALES TARGETS = OPEN`

Do not convert backend PASS into browser/system PASS.

## CURRENT RAWAIE-ERP-NEW GIT

Latest session commit:
`e7e0ab46c9df19672038ea88854fa8a86908d519`

Includes Report175, the canonical live-dashboard/integrity migration, and the canonical Edge source.

## NEXT SESSION START ORDER — MANDATORY

1. Capture a fresh Production snapshot first.
2. Re-check `erp-frontend` HEAD, Direct Parent, Parent of Parent, master blob and `forensic_main_assembly.yml`.
3. Re-check current Production tables, RPC definitions, Edge versions, RLS, triggers, Realtime and target data.
4. Read `companies/company-1/main.html` fully to EOF before any exact surgery.
5. Do not re-fix Sales Target backend unless new Production evidence proves a regression.
6. Treat `Current/PWA/main2/*` as historical reference only.
7. Locate the exact current Sales Target block in `main.html`, record exact start/end anchors and the last complete line, then issue one complete owner-side replacement.
8. Replace the proven `renderTargets` block in `sales/manager.html` from Report175.
9. Publish the current frontend files.
10. Execute real browser E2E on the newly published master; inspect Console; test Target CRUD/approval/post/reverse; verify live refresh and Audit.
11. Reconcile Production again in the same reporting moment.
12. Only then set `SYSTEM-LEVEL SALES TARGETS = CLOSED`.
13. Add a new report; never delete historical reports.

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
