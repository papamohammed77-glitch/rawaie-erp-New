# Report541 — Delivery Assignments: Routes Tab Consumer Gap (Live Production Reconciliation)

**Observed:** 2026-10-28 21:23:00 UTC  
**Scope:** Only the reported missing delivery assignments in the Parent ERP views **الرحلات والمسارات** and **مناديب التوصيل**.  
**Classification:** `ROOT CAUSE CONFIRMED — OWNER FILE CHANGE REQUIRED`  
**Operational mutations:** None. Production SQL was read-only; no business data, schema, RPC, ACL/RLS, inventory/accounting, or deployment was changed.

## 1. PRE-CHANGE SELF-AUDIT

| Area | Result | Evidence |
|---|---|---|
| Business contract | CONFIRMED | Real supervisor assignment is persisted on `public.runsheets.deliverer_id` referencing `public.users.id`; it is not equivalent to a logistics route-plan assignment. |
| Production assignment data | CONFIRMED | Live SQL at 2026-10-28 21:21 UTC returned RS-1 and RS-2 in company `00000000-0000-0000-0000-000000000001`, both `Loaded`, with valid active deliverer users. |
| Production route plans | CONFIRMED | Live count for `delivery_route_plans` in the company is **0**. |
| Production RPC `routes` | CONFIRMED | Fresh direct call returned `success=true, rows=[]`; current routes branch selects from `delivery_route_plans`. |
| Production RPC `agents` | CONFIRMED | Fresh direct call returned `success=true`, `rows=[]`, and `runsheet_assignments=[RS-2, RS-1]`. |
| Empty `delivery_agents` registry | CONFIRMED | The count is 0; this is a separate administrative registry, not proof that runsheet assignments are missing. |
| Existing agents consumer fix | CONFIRMED | Current Parent source already reads `d.runsheet_assignments` in `agents()` and renders the separate “تعيينات الرانشيت من مشرف التوصيل” card. Do not duplicate this repair. |
| Routes consumer | CONFIRMED | Current Parent `routes()` only calls `q('routes', ...)`, renders `d.rows` as route plans, and displays “لا توجد خطط توصيل” when empty. It never reads or renders `runsheet_assignments`. |
| Published UI | PARTIALLY OBSERVED | Current connected page snapshot displayed the “الرحلات والمسارات” view and its empty route-plan state. The snapshot also contains login-form elements, so do not label it a clean authenticated E2E session. |
| Git-to-Cloudflare artifact identity | UNVERIFIED | No fresh independent served-artifact hash/commit evidence is available. |
| Authenticated browser Network/Console | UNVERIFIED | Browser context provides page text only; no fresh target-view Network body or Console evidence was captured in this run. |

## 2. Root cause

This is a **consumer/model mismatch**, not missing Production assignment data and not a proven RPC/ACL defect.

The two screens currently have different contracts:

- **مناديب التوصيل:** consumes the `agents` response and renders `runsheet_assignments` independently of the empty `delivery_agents` master registry. The existing repair is already present.
- **الرحلات والمسارات:** consumes only route-plan rows from `delivery_route_plans`. It does not render the independent supervisor assignments on `runsheets.deliverer_id`. Since Production currently has zero route plans, the page truthfully shows “لا توجد خطط توصيل” but hides the separately existing RS-1/RS-2 assignments from this screen.

The correct repair is **not** to manufacture route plans, create synthetic `delivery_agents` rows, rewrite assignments, change permissions, or change the RPC security contract. Preserve the route-plan table and add a separate runsheet-assignment card to the routes view, using the existing `agents` RPC response field.

## 3. Surgical Parent-source change — owner applies

**Repository:** `papamohammed77-glitch/erp-frontend`  
**Branch:** `main`  
**File:** `companies/company-1/main.html`  
**Current blob:** `0c1745081e8d17480433ed527d77cac9f5292021`  
**Existing related repair commit:** `cb62612a174f5b1a8d5aa5a41a4c3e5747bb73fc`

Per the project change-control contract, do not directly mutate the Parent HTML from this run. Apply the following focused edit in the existing `async function routes()` only.

### A. Add the existing assignment response

Immediately after the existing `q('routes', ...)` call, add:

```javascript
var ad = await q('agents', {search:'', status:'Active', limit:200, offset:0});
var assignments = Array.isArray(ad.runsheet_assignments) ? ad.runsheet_assignments : [];
```

Keep `S.cache.routes=d.rows||[]` and all existing route-plan rendering unchanged.

### B. Build a separate assignment card

After the existing `table` variable is constructed and before the final `set(shell(...))`, add:

```javascript
var assignmentRows = assignments.map(function(a) {
  var statusLabels = {
    Loaded: 'محملة',
    Delivering: 'جاري التوصيل',
    Delivered: 'تم التوصيل',
    Returning: 'عائدة/مرتجعة'
  };
  return '<tr style="border-top:1px solid #eef2f7">' +
    '<td class="p-3"><b>' + esc(a.runsheet_code) + '</b></td>' +
    '<td class="p-3">' + date(a.run_date) + '</td>' +
    '<td class="p-3">' + esc(a.deliverer_name || ('مستخدم ' + a.deliverer_user_id)) + '</td>' +
    '<td class="p-3">' + badge(statusLabels[a.status] || a.status, 'info') + '</td>' +
    '<td class="p-3">' + (a.delivery_agent_code ? esc(a.delivery_agent_code) : 'غير مرتبط بسجل مناديب اللوجستيات') + '</td>' +
    '</tr>';
}).join('');

var assignmentTable =
  '<div style="overflow:auto"><table class="w-full"><thead><tr>' +
  ['الرانشيت','التاريخ','مندوب التوصيل المسند فعليًا','حالة الرانشيت','ربط سجل اللوجستيات']
    .map(function(h) { return '<th class="p-3 text-right">' + h + '</th>'; }).join('') +
  '</tr></thead><tbody>' +
  (assignmentRows || '<tr><td colspan="5" class="text-center p-8 text-slate-400">لا توجد رانشيتات مسندة إلى مندوبي التوصيل في الحالات المعروضة.</td></tr>') +
  '</tbody></table></div>';
```

Replace only the final line:

```javascript
set(shell(card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table)));
```

with:

```javascript
set(shell(
  card('الرحلات والمسارات','خطة مقابل تنفيذ ومحصلة مالية',table) +
  card('تكليفات الرانشيت من مشرف التوصيل','التكليف الفعلي محفوظ في runsheets.deliverer_id؛ يُعرض مستقلًا عن خطط المسارات.',assignmentTable)
));
```

This keeps route plans and supervisor runsheet assignments as separate business concepts. It does not conflate a `runsheet.deliverer_id` assignment with a `delivery_route_plans.delivery_agent_id` relationship.

## 4. Why no Production database repair was applied

The live RPC and source contract are internally consistent with the current schema:

- `routes` correctly returns route plans, and Production currently has none.
- `agents` correctly returns the real runsheet assignments in `runsheet_assignments`.
- The existing agents consumer already renders that field.

Changing the RPC, grants, RLS, runsheet rows, or `delivery_agents` would be an unsupported workaround and could create duplicate/parallel logistics records. The defect is the missing Parent UI consumer for the already-returned field in the routes view.

## 5. Acceptance tests after owner applies the patch

1. Open **إدارة التوصيل والشحن → الرحلات والمسارات** in the published Parent after deployment.
2. Confirm the existing route-plan card still behaves unchanged.
3. Confirm the separate “تكليفات الرانشيت من مشرف التوصيل” card shows RS-1 and RS-2 with their actual assigned users and `Loaded` state.
4. Open **مناديب التوصيل** and confirm the existing assignment card still shows the same RS-1/RS-2 data.
5. Refresh both views and verify no duplicate assignments are created; this is a read-only display change.
6. Capture the authenticated RPC response, relevant DOM text, and Console result for each view.
7. Verify the deployed Cloudflare page contains the owner-applied commit. Until this is done, Production UI closure remains open.

## 6. Mutation ledger

- Production SQL/RPC checks: read-only.
- Production business data/schema/RPC/ACL/RLS: unchanged.
- Parent source and Cloudflare deployment: unchanged by this run.
- No synthetic `delivery_agents` or route-plan rows created.
- No Edge Functions created.
- Documentation artifact only.

## SELF-AUDIT FINAL

- **What I Proved:** Live RS-1/RS-2 assignments exist; the `agents` RPC returns them; the `routes` RPC returns no route plans; Production has zero route plans; the current routes consumer only renders route-plan rows; the existing agents consumer already renders runsheet assignments.
- **What I Did Not Prove:** Fresh authenticated browser Network/Console evidence; Cloudflare artifact-to-Git identity; post-patch published UI behavior.
- **What I Fixed:** Root cause identified precisely and a minimal, non-destructive Parent-source patch prepared. No production mutation was justified.
- **What I Initially Missed:** The previous repair covered only the “مناديب التوصيل” consumer, not the separate “الرحلات والمسارات” consumer.
- **What Could Still Be Wrong:** A post-deployment browser/runtime issue could remain after the source patch; verify both tabs in the published build.
- **Final Confidence:** High for the root cause and required UI change; incomplete for published E2E until the owner applies/deploys and verifies the patch.
- **Final Closure Status:** `ROOT CAUSE CONFIRMED — OWNER FILE CHANGE REQUIRED`.
- **Next exact action:** Apply the focused `routes()` patch to `companies/company-1/main.html`, publish it through the normal workflow, then capture fresh authenticated E2E evidence for both tabs.
