# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14 04:49:52Z (latest verified Production snapshot in this session)

## SOURCE OF TRUTH

التقارير Historical/Reference فقط.

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
HEAD: `b6e48193f4042ed6625721aa484c53f6de8cb081`
Message: `Update manager.html`
Direct Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
Parent of Parent: `8392edda5c766fa69c5faea768ca35e35b498b94`

Current mother `main.html` blob:
`66c7c9bb2c8dba4a521647c680e2cb6605b28e0d`

Current mother size:
`1,087,515 bytes`

Current manager blob:
`a6021c5dede730b3b2fdb590f4bfafb4467eaf8a`

## FORENSIC PATH

`forensic_main_assembly.yml` is already correctly aligned to:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

No change was needed.

## MAIN.HTML READ BARRIER

The current blob, size, beginning, end markers, and static searches were verified directly.

The runtime transport still does not expose the entire 1.09MB body with original line addressing to EOF.

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Therefore no fabricated main.html line numbers were produced and no main.html modification was made.

Static source evidence proves the current `RW_Navigation.menuTree` contains no independent `sales-targets` view and the current main source contains no proven `sales_target` module registration.

## CURRENT RAWAIE-ERP-NEW GIT

HEAD at start of this session:
`b71871c02f926a551894993a34205ecdd11c5286`

Direct Parent:
`93a11b7b927a3e458dfa69cd05f3e4c2d0019067`

This session added canonical migration/report commits after that HEAD.

Canonical migration:
`supabase/migrations/20260914075000_sales_targets_zero_debt_hardening.sql`

Latest report:
`doc/Draft/Reprots/Report179_SALES_TARGETS_PRODUCTION_HARDENING_AND_MOTHER_UI_FORENSIC_20260914.md`

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Latest direct snapshot:
`2026-09-14 04:49:52.424248+00`

Target counts:
- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`

`TARGET TEST RESIDUE = 0`

## SALES TARGET DATA CONTRACT

Existing tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

New production plan evolution fields:
- `version_no`
- `supersedes_plan_id`

## TENANT INTEGRITY

Production now has composite tenant-safe relationships covering:
- assignment → plan/company
- assignment → sales rep/company
- assignment → branch/company
- run → plan/company
- reversal run → same company
- run line → assignment/company
- run line → branch/company
- run line → sales rep/company
- run line → run/company

## TARGET ENGINE

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

Verified operations now include:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

Rules:
- Approved/Closed plans are historical records.
- Changing a finalized plan uses `CLONE_PLAN` to a new Draft version.
- Assignment activation changes are Draft-only.
- Rep and branch ownership is Company-checked.

## SECURE GATEWAY

`public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)`

Read:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `PREVIEW`

Management:
`SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `CANCEL_PLAN`

Approval:
`APPROVE_PLAN`, `CLOSE_PLAN`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`

Edge `sales-target-engine`: ACTIVE, version 2, `verify_jwt=true`.
Edge `sales-target-dashboard`: ACTIVE, version 1, `verify_jwt=true`.

No new Edge Function was required for this hardening.

## REALTIME

All four target tables remain in `supabase_realtime`.

`REALTIME DB = VERIFIED`

Frontend runtime subscription is still required for full system closure.

## PRODUCTION TESTS

Executed transactionally and rolled back:

- SAVE_PLAN = PASS
- SAVE_ASSIGNMENT = PASS
- CLONE_PLAN = PASS
- version_no increment = PASS
- supersedes_plan_id linkage = PASS
- copied assignment = PASS
- assignment activation on Approved plan = correctly rejected
- assignment activation on cloned Draft = PASS
- final residue = 0

A clone SQL defect was caught and fixed:
`column reference "branch_id" is ambiguous`

Root cause: PL/pgSQL variable name collided with selected column name.

## CURRENT UI

`sales/manager.html` remains OPEN — OWNER for previously proven UI surgery.

`main.html` remains OPEN — OWNER.

Current mother search proves no registered `sales-targets` view/module in the master source.

Exact mother line numbers remain intentionally unrecorded because full EOF line-addressed transport is not proven.

## SYSTEM STATUS

`SALES TARGET BACKEND = CLOSED`
`SALES TARGET TENANT INTEGRITY = CLOSED`
`SALES TARGET VERSIONED MANAGEMENT = CLOSED`
`SALES TARGET EDGE = CLOSED`
`SALES TARGET DB REALTIME = VERIFIED`
`SALES TARGET PRODUCTION TRANSACTIONAL TESTS = PASS`
`SALES MANAGER UI = OPEN`
`MOTHER MAIN UI = OPEN`
`BROWSER E2E = OPEN`
`CURRENT MAIN FULL EOF READ = OPEN`
`FRONTEND REALTIME RUNTIME = OPEN`
`SYSTEM-LEVEL SALES TARGETS = OPEN`

## NEXT SESSION — MANDATORY ORDER

1. Fresh Production snapshot first.
2. Re-check frontend HEAD + Direct Parent + Parent of Parent.
3. Re-check mother blob + size + `forensic_main_assembly.yml`.
4. Obtain complete mother body to EOF with original line addressing; do not fabricate numbers.
5. Re-check target schema, constraints, RPCs, Edge deployment versions, Realtime, and row counts.
6. Do not repeat Target backend hardening without new regression evidence.
7. Apply owner surgery in `main.html` using exact current anchors/line numbers.
8. Apply current `sales/manager.html` owner surgery.
9. Publish frontend.
10. Execute authenticated browser E2E.
11. Verify Console + Network.
12. Verify Realtime runtime refresh.
13. Reconcile Production in the same reporting moment.
14. Only then close `SYSTEM-LEVEL SALES TARGETS`.

## GOVERNANCE LOOP

```text
CURRENT GIT
→ CURRENT SOURCE
→ CURRENT PRODUCTION
→ CURRENT DATABASE
→ CURRENT DEPLOYMENT
→ CURRENT BROWSER/CONSOLE/NETWORK
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
