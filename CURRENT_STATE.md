# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14 15:00:40.725342+00

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
HEAD: `9e6645bf3c613f8995785d1fe70a88150ce87c16`
Message: `Update main.html`
Direct Parent: `91e50848a65cb0255e95c4e7d8f1a1523eb43e85`
Parent of Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`
Parent of Parent of Parent: `8392edda5c766fa69c5faea768ca35e35b498b94`

Current mother `main.html` blob:
`85a8a3593251a1f7c2ddbc8654cc192db8c4a0c2`

Current mother size:
`1,087,515 bytes`

## FORENSIC PATH

`forensic_main_assembly.yml` remains correctly aligned to:

```yaml
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

No reconstruction path points to the historical 11 fragments.

## MOTHER SOURCE — SALES TARGETS

Current source proves:

- `sales-targets` is registered in `RW_Navigation.menuTree`.
- `RW_SalesTargetsMain` exists in the current mother source.
- Dispatcher calls `RW_SalesTargetsMain.render()` for `sales-targets`.
- Sales Targets `render()` uses the real page container:
  `var c=byId('rw-page-container');`
- Initial plan selection uses:
  `RW_SalesTargetsMain.selectPlan(plans[0].id)`.
- Current source search finds no `rw-page-content` reference in the Sales Targets path.
- EOF markers are present as `</script>`, `</body>`, `</html>`.

The exact two fixes are already present in current HEAD `9e6645b…`; do not repeat them as a new owner surgery.

## CURRENT RAWAIE-ERP-NEW GIT

Latest relevant commits now include:

- `3b2c5d113cd07269c843a79da8c5b008679efcc7` — Create Report180
- `63c5a24c9d5ebf18f3d58f564a61ce0489682f3a` — Create Report181 / current Sales Targets closure record
- this CURRENT_STATE reconciliation commit

Latest report:
`doc/Draft/Reprots/Report181_SALES_TARGETS_CURRENT_CLOSURE_20260914.md`

Historical reports:
`Report178`, `Report179`, `Report180` remain reference-only.

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Fresh final direct snapshot:
`2026-09-14 15:00:40.725342+00`

Target counts:
- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`

`TARGET TEST RESIDUE = 0`
`TARGET E2E AUDIT RESIDUE = 0`

## SALES TARGET DATABASE CONTRACT

Tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

RLS is enabled on all four target tables.

Realtime publication includes all four target tables.

Plan versioning fields:
- `version_no`
- `supersedes_plan_id`

Tenant-safe composite relationships are present across target parent/child relationships.

## TARGET ENGINE

`public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)`

Verified operations:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

`public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)` is the current authorization boundary.

Rules:
- Approved/Closed plans are historical records.
- Finalized-plan changes use `CLONE_PLAN` to a new Draft version.
- Assignment activation changes are Draft-only.
- Sales representative and branch ownership is Company-checked.

## CURRENT EDGE DEPLOYMENT

`sales-target-engine`:
- ACTIVE
- version 2
- verify_jwt=true
- SHA `8695d5b880798ab8eb0c805b33e08fa88b601e63485ac3580f223347775bd9aa`

`sales-target-dashboard`:
- ACTIVE
- version 1
- verify_jwt=true
- SHA `c0cd73599388ba090116bc6cc4262e0e3c9ccd78a17979b2d239d124c345defe`

## PRODUCTION BACKEND E2E

Executed directly against Production with temporary E2E data, then cleaned:

- SAVE_PLAN = PASS
- SAVE_ASSIGNMENT = PASS
- APPROVE_PLAN = PASS
- PREVIEW = PASS
- POST = PASS
- POST retry with same operation_id = duplicate=true / PASS
- APPROVE_RUN = PASS
- REVERSE_RUN = PASS
- CLOSE_PLAN = PASS
- CLONE_PLAN = PASS
- cloned plan = Draft, version 2, supersedes source, assignment copied
- cleanup = PASS
- final row counts = 0/0/0/0
- final E2E audit residue = 0

Conclusion:
Production backend is not the proven cause of the Mother tab opening failure.

## SYSTEM STATUS

`SALES TARGET BACKEND = CLOSED / VERIFIED`
`SALES TARGET TENANT INTEGRITY = CLOSED / VERIFIED`
`SALES TARGET VERSIONED MANAGEMENT = CLOSED / VERIFIED`
`SALES TARGET EDGE = CLOSED / VERIFIED`
`SALES TARGET DB REALTIME = VERIFIED`
`SALES TARGET BACKEND E2E = PASS`
`MOTHER TARGET MENU = VERIFIED`
`MOTHER TARGET DISPATCHER = VERIFIED`
`MOTHER TARGET RENDER FIX = PRESENT IN CURRENT HEAD`
`SALES TARGET BROWSER E2E = OPEN`
`CURRENT CONSOLE = NOT OBSERVED`
`CURRENT NETWORK = NOT OBSERVED`
`FRONTEND REALTIME RUNTIME = NOT OBSERVED`
`SYSTEM-LEVEL SALES TARGETS = OPEN PENDING LIVE BROWSER E2E`

## NEXT SESSION — MANDATORY ORDER

1. Fresh Production snapshot first.
2. Re-check frontend HEAD + Direct Parent + Parent of Parent.
3. Re-check current mother blob + size + `forensic_main_assembly.yml`.
4. Obtain complete mother body to EOF with original line addressing when transport permits; never fabricate line numbers.
5. Re-check Sales Targets schema/RLS/functions/Realtime/Edge versions.
6. Do not repeat backend hardening without new regression evidence.
7. Publish current `main` HEAD `9e6645b…` if not already published.
8. Run authenticated browser E2E: login → إدارة المبيعات → أهداف المبيعات.
9. Verify Console and Network.
10. Verify Realtime runtime refresh.
11. Reconcile Production again immediately before the final closure report.
12. Only then change `SYSTEM-LEVEL SALES TARGETS` to CLOSED.

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
