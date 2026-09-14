# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14 07:21+03:00

## SOURCE OF TRUTH

التقارير Historical/Reference فقط.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE + CURRENT BROWSER/CONSOLE`

**Source of Truth للنظام الأم:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical reference only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `b6e48193f4042ed6625721aa484c53f6de8cb081`
Direct Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
Parent of Parent: `8392edda5c766fa69c5faea768ca35e35b498b94`

Current `companies/company-1/main.html` blob:
`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

Current `companies/company-1/sales/manager.html` blob:
`a6021c5dede730b3b2fdb590f4bfafb4467eaf8a`

## FORENSIC PATH

`erp-frontend/forensic_main_assembly.yml`

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

## MAIN.HTML READ STATUS

Blob and size are proven (`1,087,515 bytes`).

Full body to EOF could not be transported by the available GitHub endpoint in this runtime; Raw fetch and container clone were also unavailable.

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Do not invent main.html line numbers or surgical anchors.

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Status:
`ACTIVE_HEALTHY`

Final snapshot:
`2026-09-14 04:19:47.761648+00`

Counts:
- companies = 1
- branches = 2
- users = 24
- items = 17
- orders = 0
- order_details = 0
- sales_target_plans = 0
- sales_target_assignments = 0
- sales_target_runs = 0
- sales_target_run_lines = 0
- audit_log = 1955

## SALES TARGET BACKEND

Tables exist:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Central engine:
`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

Dashboard:
`public.sales_target_dashboard_atomic(uuid,uuid,text)`

Verified operations:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

Edge:
- `sales-target-engine` ACTIVE v1, `verify_jwt=true`
- `sales-target-dashboard` ACTIVE v1, `verify_jwt=true`

Realtime verified for all four target tables.

## PRODUCTION E2E RESULT

Transactional E2E succeeded and was rolled back:

`SAVE_PLAN → SAVE_ASSIGNMENT → APPROVE_PLAN → Invoiced test order → DASHBOARD → PREVIEW → POST → POST RETRY → APPROVE_RUN → REVERSE_RUN → ROLLBACK`

Measured:
- amount: 100 / 100 = 100%
- qty: 1 / 10 = 10%
- gross profit: 100 / 40 = 250%
- POST retry returned `duplicate=true` and same Run.
- rollback left all target/order test rows = 0.

`SALES TARGET PRODUCTION E2E = PASS`
`TARGET TEST RESIDUE = 0`

## CURRENT SALES MANAGER UI

Current file:
`erp-frontend/companies/company-1/sales/manager.html`

Current blob:
`a6021c5dede730b3b2fdb590f4bfafb4467eaf8a`

Current defects proven:
1. plan selection reload can reset to first plan.
2. APPROVE_RUN / REVERSE_RUN send Plan ID instead of Run ID.
3. POST generates a new operation_id on every click.
4. UI lacks complete Plan edit, Assignment edit/toggle, Preview and Run selection controls.
5. Realtime target subscription is absent.

A full owner surgical replacement for `renderTargets` is in:
`doc/Draft/Reprots/Report176_SALES_TARGETS_E2E_SYSTEM_CONTROL_20260914.md`

Local Node.js syntax check:
`PASS`

`MANAGER UI = OWNER OPEN`

## CURRENT MOTHER UI

No direct modification was made to `main.html`.

Reason: exact EOF/full body was not technically proven, so no fabricated line-level surgery was issued.

`MOTHER UI = OWNER OPEN`

## CLOSURE

`SALES TARGET DATABASE = CLOSED`
`SALES TARGET RPC = CLOSED`
`SALES TARGET EDGE = CLOSED`
`SALES TARGET REALTIME = CLOSED`
`SALES TARGET PRODUCTION E2E = CLOSED / PASS`
`SALES TARGET POST IDEMPOTENCY = CLOSED / PASS`
`SALES MANAGER UI = OPEN`
`MOTHER MAIN UI = OPEN`
`BROWSER E2E = OPEN`
`SYSTEM-LEVEL SALES TARGETS = OPEN`

Do not convert backend PASS into browser/system PASS.

## LATEST RAWAIE-ERP-NEW GIT

HEAD after final session records:
`8addc839e28c0677eb9b5449528923efb7fa52cd`

Direct Parent:
`ebf88e2f77be9f2ff1d90a162bcee87e807a9350`

The latest HEAD contains the final CURRENT_STATE reconciliation. The preceding commit contains Report177.

## LATEST EXECUTION REPORTS

`doc/Draft/Reprots/Report176_SALES_TARGETS_E2E_SYSTEM_CONTROL_20260914.md`

`doc/Draft/Reprots/Report177_SALES_TARGETS_FINAL_PRODUCTION_RECONCILIATION_20260914.md`

## NEXT SESSION — MANDATORY ORDER

1. Fresh Production snapshot first.
2. Re-check frontend HEAD + Direct Parent + Parent of Parent.
3. Re-check current main blob and `forensic_main_assembly.yml`.
4. Re-check target schema/RPC/Edge/RLS/Realtime/rows.
5. Do not re-fix Target backend without new regression evidence.
6. Obtain current `main.html` body completely to EOF.
7. Record exact Target block start/end anchors and last complete line.
8. Apply owner-side `main.html` surgery only after that proof.
9. Apply Report176 `renderTargets` surgery to `sales/manager.html`.
10. Publish the current frontend.
11. Execute authenticated browser E2E and Console/Network checks.
12. Verify live Realtime update.
13. Reconcile Production again in the same reporting moment.
14. Only after all layers pass: `SYSTEM-LEVEL SALES TARGETS = CLOSED`.

## FINAL GOVERNANCE LOOP

```text
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ CURRENT BROWSER/CONSOLE
→ HISTORICAL CONTRACT
→ ACTUAL GAP
→ SURGICAL FIX
→ TEST
→ DEPLOY
→ PRODUCTION VERIFY
→ REALTIME/AUDIT
→ FINAL RECONCILIATION
→ CLOSE
```
