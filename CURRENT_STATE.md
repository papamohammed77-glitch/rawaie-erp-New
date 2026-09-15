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

Latest HEAD already contains the previously approved Sales Targets surgeries. They must not be repeated without new evidence.

## CURRENT MOTHER / CURRENT SOURCE EVIDENCE

Current `main.html` contains:

- line 1309: `var RW_SalesTargetsMain = (function(){`
- line 1423: `async function renderDashboard(planId){`
- line 1524: current end of `renderDashboard` before `subscribeRealtime()`.
- line 1900: `})();` closing `RW_SalesTargetsMain`.

Current EOF is line **40687**, ending with:

```text
</script>
</body>
</html>
```

A machine-readable GitHub blob was inspected directly. The connector cannot expose the entire 40K-line blob as one uninterrupted visual block, so no false claim of a single-shot manual line-by-line reading is made.

## FORENSIC ASSEMBLY

`forensic_main_assembly.yml` is already correct:

```text
repository: papamohammed77-glitch/erp-frontend
path: companies/company-1/main.html
ref: main
mode: published_main_is_authoritative
fragment_mode: historical_reference_only
```

No path correction is required.

## SALES TARGETS — CURRENT PRODUCTION

Supabase project:
`fiilmooggumokxanwiyx`

Production RPCs:
- `sales_target_engine_gateway`
- `sales_target_engine_atomic`
- `sales_target_dashboard_atomic`

Production Sales Targets tables:
- `sales_target_plans`
- `sales_target_assignments`
- `sales_target_runs`
- `sales_target_run_lines`

Current business counts:

```text
plans       = 0
assignments = 0
runs        = 0
run_lines   = 0
```

Existing Sales Targets integrity/audit infrastructure is present and company-scoped.

## SALES TARGETS — CURRENT SESSION ACTIONS

### Production

Added performance indexes without changing Business Logic:

```sql
CREATE INDEX idx_orders_company_date_sales_targets
  ON public.orders (company_id, order_date);

CREATE INDEX idx_order_details_order_item_sales_targets
  ON public.order_details (order_id, item_id);
```

Both indexes were verified in Production after deployment.

No Sales Targets business data was created or altered by this session.

### Frontend Source — Owner responsibility

The current source proves that `RW_SalesTargetsMain` exists, but the source does not explicitly export it to `window` after the module closes.

A fresh runtime error was supplied:

`Uncaught ReferenceError: RW_SalesTargetsMain is not defined`

The safest current surgery is therefore an explicit export at source line 1900 rather than rewriting the module or repeating previous logic changes.

Prepared Owner Surgery:

```javascript
    };
})();
window.RW_SalesTargetsMain = RW_SalesTargetsMain;
function _rwCompanyId() {
```

The current `renderDashboard` at line 1423 is also prepared for a full UX upgrade that keeps the current RPC/state-machine contract unchanged.

## CONSOLE DIAGNOSTIC

### Root runtime error

`RW_SalesTargetsMain is not defined`

Current Git contains the module declaration. Therefore the error is not proven to be a missing Sales Targets engine in Current Source.

Most likely remaining boundary:
- served asset differs from Current HEAD, or
- global exposure is not explicit in the actual execution scope.

The proposed explicit `window.RW_SalesTargetsMain` export closes the second risk without changing business logic and also provides a clean verification point for the first.

### Non-blocking warning

`cdn.tailwindcss.com should not be used in production`

This remains a warning. It is not the cause of the Sales Targets runtime error.
Removing the CDN without generating equivalent compiled CSS was intentionally rejected because the mother file uses extensive Tailwind utility classes.

### Favicon

`/favicon.ico 404` is unrelated to Sales Targets.
It remains separate from this surgery to avoid mixing unrelated UI changes.

## SALES TARGETS — UX DIRECTION

The existing source already supports:

- Plans.
- Plan approval/closure/cancellation.
- Assignment management.
- Active/inactive assignments.
- Preview.
- Posting.
- Run approval.
- Reversal with idempotency.
- Dashboard totals/ranking/trend.
- Realtime subscriptions.

The prepared UX upgrade changes presentation only to add:

- Executive KPI hierarchy.
- Primary metric progress.
- Remaining target.
- Time-pace comparison.
- Performance health indicator.
- Progress bars for assignments and ranking.
- Stronger empty states.
- Better visual separation between planning, execution, and results.

No state transition or permission contract is changed.

## CURRENT E2E STATUS

### Proven

- Current HEAD/Parent/Parent-of-parent.
- Current mother blob.
- Current Sales Targets source anchors.
- Current EOF line and closing sequence.
- Current Production Sales Targets RPC inventory.
- Current Production data counts.
- Current Production index deployment.
- Current forensic assembly path.

### Not proven

- Fresh browser-incognito run after current HEAD.
- Served-source hash comparison against blob `8bf3...`.
- Fresh Console/Network capture after the Owner surgery.

This environment cannot independently create the requested incognito browser session with DevTools capture.

## REPORTS

Current report:
`doc/Draft/Reprots/Report187_SALES_TARGETS_UX_CONSOLE_E2E_20260915.md`

Previous reports remain untouched and historical.

## NEXT EXACT CHECKPOINT

1. Owner applies the explicit global export at source line 1900.
2. Owner replaces the current `renderDashboard` function beginning at line 1423 with the prepared UX version from Report187.
3. Deploy exactly `companies/company-1/main.html`.
4. Verify served source is Current HEAD artifact or newer.
5. Open Sales Targets.
6. Press `تحديث`.
7. Verify `RW_SalesTargetsMain is not defined` is gone.
8. Capture Console + Network evidence.
9. Only after that mark Mother Sales Targets Browser E2E closed.

Do not reopen already-fixed Production or previous Sales Targets frontend surgeries without fresh evidence.
