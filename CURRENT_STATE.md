# RAWAEA ERP — CURRENT STATE

**Last reconciled:** 2026-09-15 06:16 UTC

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
HEAD: `13425725f48c7decba3403ee631d8e0f2d757b0f`
Direct parent: `05ebb2d67b29dfe26ad77b6f314942c502e0dd8f`
Current mother blob: `5267f261f2febcbafeafdce0bb9da89a4a6bc894`

HEAD message: `Refactor KPI card layout and styles`.

## CURRENT MOTHER FILE EVIDENCE

تم فتح الـblob الحالي مباشرة من Git وتمت قراءته chunk-by-chunk حتى EOF.

- Current line count: 40,857.
- EOF verified at `</html>`.
- آخر الجزء المقروء ينتهي فعليًا بـ `</script>`, `</body>`, `</html>`.
- تم أخذ الـanchors الجراحية من نفس الـblob الحالي، وليس من تقرير قديم.

Current exact anchors used this cycle:
- navigation sales submenu: line 1144.
- `window.RW_SalesTargetsMain = RW_SalesTargetsMain;`: line 1986.
- `RW_Views.render` permission map starts line 38932 تقريبًا.
- Sales Target dispatch: line 39071 تقريبًا.

## FORENSIC ASSEMBLY

تم إنشاء:
`doc/Draft/forensic_main_assembly.yml`

ويحدد صراحة:
- repository = `papamohammed77-glitch/erp-frontend`
- path = `companies/company-1/main.html`
- ref = `main`
- mode = `published_main_is_authoritative`
- fragment_mode = `historical_reference_only`

## PRODUCTION — LOYALTY

Supabase project:
`fiilmooggumokxanwiyx`

Current tables:
- `loyalty_programs`
- `loyalty_rewards`
- `loyalty_accounts`
- `loyalty_transactions`
- `loyalty_points` (legacy compatibility cache)

Current RPC:
- `loyalty_engine_atomic(uuid,text,text,jsonb,text)`

Security:
- `SECURITY DEFINER = true`.
- EXECUTE = service_role only.
- anon/authenticated direct table grants removed.
- legacy `loyalty_points` permissive policy removed.
- audit triggers remain attached to Loyalty tables.

Current transaction permission model:
- EARN_ORDER / SYNC_ORDER: Owner, sales supervisors/managers, general manager, POS, telesales, order-taker/orders, van-sales.
- ADJUST / EXPIRE / REVERSE: Owner/general manager only.

Data identity:
- Loyalty source of truth = `loyalty_accounts + loyalty_transactions`.
- `customers.loyalty_points` = compatibility cache.

Current Production data counts:
`loyalty_programs=0`
`loyalty_rewards=0`
`loyalty_accounts=0`
`loyalty_transactions=0`

No retained E2E test records.

## SALES TARGETS

Current Production tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Current RPCs:
- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

Current model is dynamic; `sales_target_assignments` stores mutable target amount/quantity/gross-profit/weight/active values per plan.

Current Production data counts:
`sales_target_plans=0`
`sales_target_assignments=0`
`sales_target_runs=0`

No current defect was found requiring rework of the Sales Target engine or its Main UI.

## CURRENT MAIN UI GAP

Current `main.html` contains no Loyalty UI/string/functionality.

The exact proven gap is therefore:
`Mother UI Loyalty Integration = OPEN`

Sales Targets UI already exists and routes through `RW_SalesTargetsMain`; no duplicate Sales Target rewrite is authorized unless a new Production defect is proven.

## PRODUCTION CHANGES THIS CYCLE

1. Removed direct authenticated/anonymous access to Loyalty tables.
2. Removed the legacy `loyalty_points` permissive policy.
3. Broadened operational Loyalty EARN/SYNC access to actual sales channels.
4. Restored the complete `loyalty_engine_atomic` after detecting an accidental incomplete replacement during execution.
5. Created then removed an unused `loyalty_dashboard_atomic` capability to avoid leaving an unused backend surface.
6. Revalidated final Loyalty RPC shape and privileges.

## EXECUTION INCIDENT

A faulty attempt temporarily replaced `loyalty_engine_atomic` with an incomplete body. Production read-back detected the defect immediately. The complete engine was restored from the verified current definition, with all existing operations preserved and the intended channel permission change applied.

The incident is retained in Report189 for continuity; it is not hidden.

## OWNER SURGICAL CHANGESET — MAIN.HTML

The owner must change only the current published `main.html`.

### A. Navigation — current line 1144

Insert the exact new Loyalty menu item after the existing `sales-targets` item in the same Sales submenu line.

### B. Permission map — current `RW_Views.render` around 38932–38974

Add:
`'loyalty': 'customers',`

### C. Routing — current line 39071 approximately

Add immediately above the existing Sales Targets dispatch:
`if (view === 'loyalty') { RW_LoyaltyMain.render(); return; }`

### D. Module insertion — current line 1986

Insert the full `RW_LoyaltyMain` module immediately above:
`window.RW_SalesTargetsMain = RW_SalesTargetsMain;`

The complete owner block is recorded in:
`doc/Draft/Reprots/Report189_LOYALTY_TRANSACTION_ENGINE_AND_SALES_TARGETS_CURRENT_FORENSIC_CLOSURE_20260915.md`

## VERIFICATION STATE

PRODUCTION DATABASE:
- Loyalty engine shape verified.
- Loyalty privileges verified.
- Legacy direct policy verified removed.
- Current counts verified zero.
- Sales Target tables/functions verified present and dynamic.

SOURCE:
- Current mother blob verified.
- Full read to EOF verified.
- Current HEAD and parent verified.

BROWSER:
- No direct user-browser Console/Network evidence available from this environment.

Therefore:
`Browser E2E = OPEN`

and not PASS.

## OPEN WORK

1. Owner applies the four surgical Loyalty UI changes to current `main.html`.
2. Re-publish `erp-frontend/companies/company-1/main.html`.
3. Browser E2E on the published mother.
4. Verify `loyalty-engine` network calls, Console, state refresh and DB results.
5. Integrate automatic EARN_ORDER into the final invoice lifecycle using the order operation identity; do not create manual Earn without a real Order ID.
6. Define and prove a formal return-point reversal policy before automatic Return -> Loyalty SYNC; do not invent debt behavior.
7. Keep Sales Targets untouched unless a new current Production defect is proven.

## NEXT EXACT RESUMPTION POINT

Open current `erp-frontend/companies/company-1/main.html` again and verify the same four anchors against the then-current blob SHA. Then apply only the owner changeset from Report189. After republish, perform Browser Console/Network E2E before declaring Loyalty UI closed.

## REPORT

Current session report:
`doc/Draft/Reprots/Report189_LOYALTY_TRANSACTION_ENGINE_AND_SALES_TARGETS_CURRENT_FORENSIC_CLOSURE_20260915.md`

Previous reports remain untouched and are historical evidence only.
