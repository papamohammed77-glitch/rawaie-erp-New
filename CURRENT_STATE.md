# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14 04:22:03Z (Production snapshot) + current Git reconciliation in this session

## SOURCE OF TRUTH

التقارير Historical/Reference فقط.

الحقيقة المعتمدة:
`CURRENT GIT + CURRENT SOURCE + CURRENT PRODUCTION + CURRENT DATABASE + CURRENT DEPLOYMENT EVIDENCE`

ولإغلاق Browser/System E2E يلزم أيضًا:
`CURRENT BROWSER + CURRENT CONSOLE + CURRENT NETWORK`

**Source of Truth للنظام الأم:**
`papamohammed77-glitch/erp-frontend/companies/company-1/main.html`

Historical reference only:
`Current/PWA/main2/*`, `Original/PWA/main/*`, `New-main`.

## CURRENT FRONTEND GIT

Repository: `papamohammed77-glitch/erp-frontend`
Branch: `main`
HEAD: `b6e48193f4042ed6625721aa484c53f6de8cb081`
Message: `Update manager.html`
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

The available GitHub transport does not expose the entire 1.09MB body to EOF in this runtime. Raw/clone transport was also unavailable.

`FULL MAIN.HTML LINE-BY-LINE EOF READ = NOT PROVEN`

Therefore no invented main.html line numbers were used.

Static source search did prove the current sales-navigation block and dispatcher contain no `sales-targets` Target view.

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Status:
`ACTIVE_HEALTHY`

Final Production target snapshot:
`2026-09-14 04:22:03.435613+00`

Target counts:
- sales_target_plans = 0
- sales_target_assignments = 0
- sales_target_runs = 0
- sales_target_run_lines = 0
- audit_log = 1955

No target test residue remains.

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

Secure capability gateway added in this session:
`public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)`

Gateway authorization classes:
- Read: `LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `PREVIEW`
- Management: `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CANCEL_PLAN`
- Approval: `APPROVE_PLAN`, `CLOSE_PLAN`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`

Production gateway E2E:
`SALES_TARGET_GATEWAY_ACL_E2E_PASS`

## TARGET OPERATIONS VERIFIED

`LIST_PLANS`
`LIST_ASSIGNMENTS`
`LIST_RUNS`
`SAVE_PLAN`
`SAVE_ASSIGNMENT`
`APPROVE_PLAN`
`CLOSE_PLAN`
`CANCEL_PLAN`
`PREVIEW`
`POST`
`APPROVE_RUN`
`REVERSE_RUN`

## EDGE DEPLOYMENTS

`sales-target-engine`:
- ACTIVE
- version `2`
- `verify_jwt=true`
- now routes to `sales_target_engine_gateway`

`sales-target-dashboard`:
- ACTIVE
- version `1`
- `verify_jwt=true`

Canonical source updated:
`Current/Edge_Functions/sales-target-engine/index.ts`

Canonical migration added:
`supabase/migrations/20260914071100_sales_target_secure_gateway_acl.sql`

## REALTIME

Verified directly that all four Target tables are in `supabase_realtime`:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

`REALTIME DB = VERIFIED`

Frontend subscription is still required for runtime live-update closure.

## PRODUCTION E2E

Transactional lifecycle tested in Production and rolled back:

`SAVE_PLAN → SAVE_ASSIGNMENT → APPROVE_PLAN → PREVIEW → POST → same POST → APPROVE_RUN → REVERSE_RUN → ROLLBACK`

Result:
`SALES_TARGET_FULL_LIFECYCLE_E2E_PASS`

POST retry with the same operation identity returned `duplicate=true` without creating a duplicate Run.

Cashier write denial against the new gateway was also verified.

`SALES_TARGET_BACKEND = CLOSED`

## CURRENT SALES MANAGER UI

Current file:
`erp-frontend/companies/company-1/sales/manager.html`

Current proven defects:
1. Plan selection reload can reset state.
2. `APPROVE_RUN` / `REVERSE_RUN` can send Plan ID instead of Run ID.
3. POST generates a new operation id on every click.
4. Full Plan/Assignment management UX is incomplete.
5. Realtime Target subscription is absent.

`SALES MANAGER UI = OPEN — OWNER`

## CURRENT MOTHER UI

No modification was made to `main.html`.

Static source search of the current master established:
- `RW_Navigation.menuTree` has no `sales-targets` item.
- Sales dispatcher has no `sales-targets` view route.
- No proven `sales_target` module is registered in the master.

Because full EOF read is not technically proven, no fabricated line number is recorded.

`MOTHER MAIN UI = OPEN — OWNER`

## SYSTEM CLOSURE

Closed in Production:
- Target DB schema
- Target integrity constraints/guards
- Target core RPC
- Target dashboard RPC
- Target secure gateway ACL
- Target Edge engine v2
- Target Realtime database publication
- Transactional Target lifecycle
- POST idempotency
- Test residue cleanup

Still open:
- Manager UI owner surgery
- Master main.html owner surgery
- Current main.html complete EOF read
- Browser authenticated E2E
- Browser Console/Network verification
- Frontend Realtime runtime verification
- Final System-Level Sales Targets closure

`SYSTEM-LEVEL SALES TARGETS = OPEN`

Do not convert Production PASS into Browser/System PASS.

## LATEST RAWAIE-ERP-NEW GIT

This session added two canonical production-alignment commits:

- `9139fb281dec58d1f49a87c98b2b666e3acb2315` — Harden sales target engine Edge routing through secure gateway
- `297c77f40c83ae6af891ee3846b0374aa027f26e` — Add governed Sales Target engine capability gateway

Latest report commit:
`93a11b7b927a3e458dfa69cd05f3e4c2d0019067`

## LATEST EXECUTION REPORT

`doc/Draft/Reprots/Report178_SALES_TARGETS_CURRENT_FORENSIC_AND_OWNER_SURGERY_20260914.md`

Historical reports remain untouched.

## NEXT SESSION — MANDATORY ORDER

1. Fresh Production snapshot first.
2. Re-check frontend HEAD + Direct Parent + Parent of Parent.
3. Re-check current `main.html` blob and `forensic_main_assembly.yml`.
4. Re-check Target schema/RPC/Edge/RLS/Realtime/rows.
5. Do not re-fix Target backend without new regression evidence.
6. Obtain current `main.html` body completely to EOF.
7. Extract exact Target navigation/dispatcher/module anchors and real line numbers.
8. Apply owner-side `main.html` surgery only after that proof.
9. Apply current `sales/manager.html` surgery.
10. Publish frontend.
11. Execute authenticated browser E2E as Sales Manager.
12. Verify Console + Network.
13. Verify Realtime runtime refresh.
14. Reconcile Production again in the same reporting moment.
15. Only then decide `SYSTEM-LEVEL SALES TARGETS = CLOSED`.

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