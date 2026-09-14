# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-14

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
Direct Parent: `91e50848a65cb0255e95c4e7d8f1a1523eb43e85`
Parent of Parent: `3398d0952ea723d1de42b076ad93ae19c025bfa3`

Current mother `main.html` blob:
`85a8a3593251a1f7c2ddbc8654cc192db8c4a0c2`

## FORENSIC PATH

`forensic_main_assembly.yml` is already correctly aligned to `erp-frontend/companies/company-1/main.html` as the published main source of truth. Historical fragments are reference-only.

## MOTHER SOURCE — SALES TARGETS

Verified from the current mother blob:

- `sales-targets` exists in `RW_Navigation.menuTree`.
- Dispatcher calls `RW_SalesTargetsMain.render()`.
- `RW_SalesTargetsMain` exists.
- `render()` uses `rw-page-container`.
- The current HEAD already contains the previous `selectPlan()` fix.
- `safeHTML` is already defined.
- `RW_UI` is not defined while Sales Targets calls `RW_UI.safeHTML(...)`.
- Current source ends with the expected `</script>`, `</body>`, `</html>` markers.

### CURRENT OWNER SURGERY

Do not modify the Sales Targets dispatcher, `render()`, `renderDashboard()`, or `selectPlan()`.

In the current mother file find this exact line:

```js
const safeText = (el, text) => { if (!el) return; try { el.innerText = text; } catch(e) { console.error(e); } };
```

Add immediately after it:

```js
const RW_UI = { safeHTML: safeHTML };
```

This is the currently proven root-cause fix for the reported `RW_UI is not defined` failure.

## CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Current target counts:
- `sales_target_plans = 0`
- `sales_target_assignments = 0`
- `sales_target_runs = 0`
- `sales_target_run_lines = 0`

No synthetic target data remains.

## SALES TARGET DATABASE CONTRACT

Verified current Production routines:

- `public.sales_target_engine_atomic(uuid,text,text,uuid,jsonb,text)` — SECURITY DEFINER
- `public.sales_target_engine_gateway(uuid,text,text,uuid,jsonb,text)` — SECURITY DEFINER
- `public.sales_target_dashboard_atomic(uuid,uuid,text)` — SECURITY DEFINER
- `public.sales_target_integrity_guard()` — SECURITY DEFINER trigger function

Verified engine operations:
`LIST_PLANS`, `LIST_ASSIGNMENTS`, `LIST_RUNS`, `SAVE_PLAN`, `SAVE_ASSIGNMENT`, `CLONE_PLAN`, `SET_ASSIGNMENT_ACTIVE`, `APPROVE_PLAN`, `CLOSE_PLAN`, `CANCEL_PLAN`, `PREVIEW`, `POST`, `APPROVE_RUN`, `REVERSE_RUN`.

## PRODUCTION HARDENING COMPLETED

`sales_target_integrity_guard()` had direct EXECUTE grants to `PUBLIC`, `anon`, and `authenticated`.

It was corrected directly in Production:

```sql
REVOKE ALL ON FUNCTION public.sales_target_integrity_guard()
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.sales_target_integrity_guard()
  TO postgres, service_role;
```

Fresh verification now shows only:
- postgres = EXECUTE
- service_role = EXECUTE

Canonical migration:
`supabase/migrations/20260914_sales_target_integrity_guard_acl_hardening.sql`

## CURRENT EDGE DEPLOYMENT

`sales-target-engine` = ACTIVE, version 2, verify_jwt=true.

`sales-target-dashboard` = ACTIVE, version 1, verify_jwt=true.

The current Edge engine wrapper resolves authenticated `auth_id` to `users.company_id` and calls the authorization gateway. No unnecessary new version was deployed.

## DIRECT PRODUCTION TESTS

- `LIST_PLANS` with `sales.manager@rawaea.com` → PASS; current result is `plans=[]`.
- `SAVE_PLAN` with `accountant@rawaea.com` → correctly rejected with `Sales target management permission required`.
- Final target row counts remain `0/0/0/0`.

A complete successful business-cycle E2E was not fabricated because Production contains no target business records and synthetic create/delete tests would pollute audit history.

Therefore the sequence below is NOT currently claimed as live Production-pass:
`SAVE → ASSIGN → APPROVE → PREVIEW → POST → APPROVE_RUN → REVERSE_RUN`.

## CLOSED

`SALES TARGET BACKEND CONTRACT = VERIFIED`
`SALES TARGET TENANT/AUTHORIZATION = VERIFIED`
`SALES TARGET INTEGRITY GUARD ACL = CLOSED`
`SALES TARGET EDGE = VERIFIED`
`SALES TARGET DB REALTIME CONFIG = VERIFIED`
`MOTHER TARGET MENU = VERIFIED`
`MOTHER TARGET DISPATCHER = VERIFIED`
`MOTHER TARGET CONTAINER FIX = PRESENT`
`MOTHER TARGET selectPlan FIX = PRESENT`
`SALES TARGET ROOT CAUSE = PROVEN`

## OPEN

`MOTHER TARGET OWNER SURGERY = PENDING`
`LIVE BROWSER E2E = OPEN`
`CURRENT CONSOLE/NETWORK AFTER OWNER SURGERY = PENDING`
`SALES TARGET REALTIME RUNTIME AFTER OWNER SURGERY = PENDING`
`SYSTEM-LEVEL SALES TARGETS = OPEN`

## NEXT SESSION — MANDATORY ORDER

1. Fresh Production snapshot first.
2. Re-check frontend HEAD + Direct Parent + Parent of Parent.
3. Re-check current mother blob SHA and EOF.
4. Do not rebuild from historical 11 fragments.
5. Do not repeat the already-present `rw-page-container` or `selectPlan` fixes.
6. Apply only the exact `RW_UI` owner surgery above if not already merged.
7. Run authenticated browser E2E: login → إدارة المبيعات → أهداف المبيعات.
8. Verify Console has no `RW_UI` ReferenceError.
9. Verify Network reaches `sales-target-engine` and `sales-target-dashboard`.
10. Verify Realtime refresh after a target-table change.
11. Reconcile Production immediately before the final closure report.
12. Close system-level task only after browser + console + network + runtime evidence are current.

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
