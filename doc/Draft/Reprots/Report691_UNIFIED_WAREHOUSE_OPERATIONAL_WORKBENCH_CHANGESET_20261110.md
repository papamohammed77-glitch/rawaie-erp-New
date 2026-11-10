# Report 691 — Unified Warehouse Operational Workbench: Root Cause, Data Contracts & Surgical ChangeSet

**Date:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-691  
**Workstream:** Correct the Unified Warehouse deliverable from navigation hub to one in-app operational workbench  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**SMART ERP project:** `fiilmooggumokxanwiyx`  
**Status:** ROOT CAUSE CONFIRMED — OPERATIONAL UI CHANGESET PREPARED — OWNER CHANGE APPROVAL REQUIRED

---

## 1. Executive finding

The owner’s original requirement is a **single standalone warehouse application** in which the warehouse keeper performs all warehouse roles from their natural operational tabs:

- Receiving
- Picking
- Loading
- Returns
- Unloading
- Inventory counting
- Manual stock vouchers (not dependent on a runsheet)
- Today / operational overview
- My account

A result must appear in the tab for its business operation, regardless of whether it was initiated from the unified application or from the corresponding legacy operational application. There must be no separate “results created by the unified app” tab and no duplicate copies of business documents.

The currently deployed-source design does not meet that requirement. `warehouse.html` is a **launcher/navigation hub**, not the requested operational application.

### Direct source evidence

Current operational `main` HEAD at review:  
`fd45a7dd8a3dae92afcc66e485e74a133cb345ae`

Current `warehouse.html` blob:  
`ead58ab7c5ad354b5b93a9a20781bfe81db7a245`

The page exposes only four top-level tabs:

1. `today`
2. `operations`
3. `vouchers`
4. `account`

The `operations()` renderer creates links to `receiver.html`, `picker.html`, `loader.html`, `returns.html`, `unloader.html`, and `counter.html`. The `vouchers()` renderer links to `vouchers.html`. The `card()` helper emits ordinary `href` navigation. No operation iframe, embedded workbench, per-operation workspace, or in-tab native work queue exists in the current source.

The latest commit `fd45a7d` is not the missing implementation. Comparing `2221eea` to `fd45a7d` shows one commit with changes only to:

- `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`
- `companies/company-1/warehouse/warehouse.html`

The workflow additions harden role/scope test assertions. The warehouse application change is limited to branch-scoped access behavior in the card helper. It does not add operational tabs or embedded workflows.

**Root cause:** the previous implementation optimized the entry point and role access, then declared the result a unified warehouse hub. The functional requirement was interpreted as aggregating links rather than aggregating the operational workspaces.

---

## 2. Owner requirement — binding functional contract

### 2.1 One application, operation-native tabs

The unified app must have these top-level tabs:

| Key | Arabic label | Functional contents |
|---|---|---|
| `today` | اليوم | Read-only KPIs, alerts, branch scope, shortcuts into the operation tabs |
| `receiving` | الاستلام | Native receiving queue, pending/completed receiving, purchase invoice/PO details and receipt workflow |
| `picking` | التحضير | Runsheet work queue, assigned/available work, active picking session and completed picking |
| `loading` | التحميل | Eligible picked runsheets, assigned loading work, loading session and completed loading |
| `returns` | المرتجعات | Pending runsheet returns, return details, discrepancy reporting and completed returns |
| `unloading` | التفريغ | Loaded/delivering runsheets, unloading detail and completed unloading vouchers |
| `counting` | الجرد | New count, branch/vehicle count scope, saved counts and completed count history |
| `vouchers` | الأذونات المخزنية | Manual transfer, transfer receipt, direct-sale vehicle issue/return, supplier return and the existing manual voucher lifecycle |
| `account` | حسابي | Authenticated employee, primary job title, active warehouse role, company and allowed branch scope |

Each operation tab retains its native pending/completed filters and operation-specific actions. These are **sub-tabs inside the business tab**, not separate source-application tabs.

### 2.2 Shared visibility contract

The same underlying business record must be visible in its natural operation tab regardless of the interface from which the action was initiated.

Examples:

- A receipt initiated from the unified app appears in the Receiving tab.
- A receipt initiated from standalone `receiver.html` appears in that same Receiving tab.
- A picking task initiated or completed from the unified app appears in Picking and is visible to the original Picker application under its normal assignment/status rules.
- A manual stock voucher created from the unified app appears in the Vouchers tab and in standalone `vouchers.html`.
- Completed unloading appears in the Unloading tab as the existing `Unloading` stock voucher, not in a separate “unified app results” list.

This is not a request to copy rows between applications. It is a shared-view requirement over the existing business source of truth.

### 2.3 Actor and creator identity

The signed-in employee remains the actor. For the identified warehouse account, the employee identity is **أمين مخزن عام**, with the primary role `أمين مخزن`. Its active operational warehouse role must be `مخزن شامل` after it is assigned through the existing authorized Supervisor/RPC path.

Do not substitute the application name for the human actor in `created_by`, `responsible`, `picker_id`, `loader_id`, `return_handler_id`, `completed_by`, or other actor fields.

A separate source-application attribution is not a standard field across the existing operation tables. Read-only schema inspection found no common `source_app` column in these workflows and no matching shared function contract. The application must therefore **not invent or fake** a source field. Phase 1 preserves the actual authenticated person and the existing per-workflow actor semantics. A unified `source_app=warehouse` audit marker, if required as a separate reporting attribute, needs its own reviewed contract and approval; it must not be mixed into the human actor field.

---

## 3. Forensic map of existing applications and data contracts

The following mappings were confirmed from the current operational source and Production schema. The unified app must reuse these pages and their existing services; it must not reproduce their write logic.

| Operation tab | Existing UI | Existing data read path (observed) | Existing write/action path |
|---|---|---|---|
| الاستلام | `receiver.html` | `purchase_orders`, `purchase_order_details`, `purchase_invoices`, `receiving`, `receiving_details`; `get_quick_market_receiving_queue_atomic` | `receive-purchase` Edge Function |
| التحضير | `picker.html` | `runsheets`, `run_sheet_details`, assigned picker / status filters | `start-picking`, `complete-picking`, existing cancel/reopen paths |
| التحميل | `loader.html` | `runsheets`, `run_sheet_details`, `vehicles` | `start-loading`, `cancel-loading`, `complete-loading`, `reopen-loading` |
| المرتجعات | `returns.html` | `runsheets`, `run_sheet_details`, `return_reasons`, `stock_discrepancies` | `start-return`, `cancel-return`, `report-discrepancy`, `complete-return`, `reopen-return` |
| التفريغ | `unloader.html` | `runsheets`, `run_sheet_details`; completed history from `stock_vouchers` where type = `Unloading` | `unload-runsheet` |
| الجرد | `counter.html` | `items`, `inventory_counts`, `inventory_count_details` | `save-inventory-count` |
| الأذونات المخزنية | `vouchers.html` | `stock_vouchers`, `stock_voucher_details`; `inventory_voucher_report` and existing reference RPCs | `create-stock-voucher`, `receive-stock-voucher`, existing voucher RPC/Edge lifecycle |

**Important list nuance:** these applications do not all use the same assignment rule. For example Picker and Loader intentionally distinguish work assigned to the current worker from available runsheets; completed work is also filtered by its assigned actor. Unloader’s completed history is a voucher-based view. The unified app must retain these semantics, not replace them with a broad company-wide query.

### Confirmed table identity fields

- `runsheets`: `created_by`, `picker_id`, `loader_id`, `return_handler_id`, plus lifecycle timestamps and status.
- `inventory_counts`: `created_by`, `branch_id`, `status`, `operation_id`.
- `stock_vouchers`: `created_by`, `completed_by`, `source`, `receiver_user_id`, `custodian_user_id`, branch/source/target references and lifecycle timestamps.
- `purchase_invoices`: `created_by`, `posted_by`, `purchaser_user_id`, `receipt_status`, `settlement_status`.
- `receiving`: `responsible`, `operation_id`, `purchase_invoice_id`, status and receipt timestamps.

These fields are not interchangeable. For example, the creator of a purchase invoice must not be overwritten with the receiving employee; the receipt event must preserve its own actor and document linkage.

---

## 4. Approved architectural direction for the UI ChangeSet

### 4.1 Workbench shell with native operation workspaces

The least-invasive approach is to convert `warehouse.html` into a single application shell with operation-native tabs. Each operation workspace is loaded from its existing same-origin application page inside a persistent embedded frame:

- Receiving → `receiver.html`
- Picking → `picker.html`
- Loading → `loader.html`
- Returns → `returns.html`
- Unloading → `unloader.html`
- Counting → `counter.html`
- Manual vouchers → `vouchers.html`

The embedded page remains the existing workflow implementation. The workbench provides the unified outer navigation and authenticated warehouse identity. It must not send the employee to a new browser tab or navigate away from `warehouse.html`.

The existing inner pending/completed tabs remain visible within each business workspace. The duplicate inner “account” link is hidden because the unified shell owns the single Account tab. The duplicate internal application header is suppressed only after the embedded page has successfully authenticated and displayed its main application. The original operation content, forms, validations, confirmation steps, and lifecycle controls remain untouched.

**Why persistent frames:** picker, loader and returns have resumable or locally persisted operational sessions; counter also keeps an in-memory count cart. Recreating an iframe on every top-level tab change could discard an in-progress UI state. Workspaces should be created lazily on first use, then retained and hidden when inactive. This preserves the state of an open operation. The resulting Realtime/channel and memory footprint must be measured before release.

### 4.2 Frame/session constraints to verify

Same-origin pages and the existing shared Supabase auth storage make session reuse plausible, but it has not yet been proven in an authenticated browser session. The implementation must verify:

1. The seven operation pages can be embedded by the deployed Pages response headers; no `X-Frame-Options` or CSP `frame-ancestors` block.
2. Each frame sees the same authenticated Supabase session as the outer shell without presenting a second login.
3. Parent logout invalidates access in every embedded workspace; no stale iframe remains operational.
4. Internal account/logout controls are suppressed only after successful child authentication.
5. The embedded page's body, root application and scroll area fit the shell without nested page scrolling or cropped modals.
6. Each frame uses the existing service-worker registration and does not create competing scopes or registrations.
7. The outer shell never treats a hidden iframe as proof of authorization. The server-side guards remain authoritative.
8. No two copies of the same page are mounted for a tab, and switching tabs does not duplicate forms or actions.

If embedding is blocked or the session contract fails, stop and prepare a separate component-adaptation ChangeSet. Do not silently fall back to opening new tabs, copying full apps, or relaxing security headers.

---

## 5. Surgical operational source ChangeSet — pending owner approval

**Target file only in Phase 1:**  
`papamohammed77-glitch/erp-frontend/main/companies/company-1/warehouse/warehouse.html`

**Base commit:** `fd45a7dd8a3dae92afcc66e485e74a133cb345ae`  
**Base blob:** `ead58ab7c5ad354b5b93a9a20781bfe81db7a245`

### 5.1 Exact original navigation markup

Current source (inside `#mainApp > main.main`):

```html
<nav class="tabs"><button class="tab active" data-tab="today">اليوم</button><button class="tab" data-tab="operations">العمليات</button><button class="tab" data-tab="vouchers">الأذونات</button><button class="tab" data-tab="account">حسابي</button></nav><section id="tabContent"><div class="empty">جاري تحميل مؤشرات التشغيل...</div></section>
```

### 5.2 Required navigation replacement

Replace the four-tab navigation with the nine business tabs defined in §2.1. The `operations` and `vouchers` top-level launcher tabs are removed. Vouchers becomes a full operation workspace. The `today` and `account` views remain native shell views.

```html
<nav class="tabs" id="warehouseTabs">
  <button class="tab active" data-tab="today">اليوم</button>
  <button class="tab" data-tab="receiving">الاستلام</button>
  <button class="tab" data-tab="picking">التحضير</button>
  <button class="tab" data-tab="loading">التحميل</button>
  <button class="tab" data-tab="returns">المرتجعات</button>
  <button class="tab" data-tab="unloading">التفريغ</button>
  <button class="tab" data-tab="counting">الجرد</button>
  <button class="tab" data-tab="vouchers">الأذونات المخزنية</button>
  <button class="tab" data-tab="account">حسابي</button>
</nav>
<section id="tabContent">
  <div id="warehouseDashboard"></div>
  <div id="warehouseWorkspaceDeck" class="hidden"></div>
</section>
```

### 5.3 Exact behavior replacement inside the current `App` object

- Keep `roleName`, `allowed`, `doLogin`, `logout`, `showLogin`, `init`, `refresh`, `load`, `metric`, and the existing read-only `today()` KPI source.
- Add one immutable operation map whose entries contain the exact role, scope and native file listed in §4.1.
- Add `workspaceFrames` keyed by the seven operation keys.
- Change `tab(t)` so a business key activates its existing workspace frame, while `today` and `account` render in the shell.
- Add a lazy `activateWorkspace(key)` routine:
  - Check the existing `allowed(role, scope)` result before creating/activating a frame.
  - Create at most one iframe for each operation key.
  - Use only relative same-origin filenames from the fixed operation map; never accept a user-supplied URL.
  - Set a descriptive title and accessible loading/failure state.
  - Retain the frame after first load and toggle visibility without recreating it.
  - On frame load, verify `#mainApp` is visible in the child. Only then inject the small embedded presentation stylesheet that hides the child's duplicate top header and `#tab-account`, while retaining its native pending/completed tab controls and `#mainContent`.
  - If the child remains on its login screen, display an outer “تعذر مشاركة الجلسة” error and do not hide the child login or claim success.
  - Catch same-origin/document access errors and show a retry action; do not silently render an empty workspace.
- Change `render()` to render the shell dashboard/account or activate the chosen native workspace. It must not recreate `warehouseWorkspaceDeck` on every render.
- Remove the launcher-only `operations()` renderer and the card-list `vouchers()` renderer after the workspaces are connected.
- Change dashboard quick actions to select a tab by `data-tab`, not to navigate to an original HTML page in the same or a new browser tab.
- Add responsive workspace CSS: full-width, min-height-safe iframe area; no nested outer scroll; child `mainContent` remains internally scrollable; modals must remain within viewport on phones.
- Preserve existing service-worker registration in `warehouse.html`. Do not add a second registration call.

No business mutation, table, RPC, Edge Function, RLS policy, permission, or branch assignment is required for this UI-only Phase 1, because each child page continues to invoke its own existing contract.

### 5.4 Files expressly excluded from Phase 1

Do not modify:

- `companies/company-1/main.html`
- `companies/company-1/core.js`
- `receiver.html`
- `picker.html`
- `loader.html`
- `returns.html`
- `unloader.html`
- `counter.html`
- `vouchers.html`
- `supervisor.html`
- Any Supabase migration, RPC, Edge Function, table, trigger, grant or RLS policy

This preserves the original applications as independently accessible applications and prevents unnecessary system-parent or engine changes.

---

## 6. Role, branch and actor contract

### Current Production identity evidence

A read-only query found the active user:

- Name: `أمين مخزن عام`
- Primary `users.role`: `أمين مخزن`
- `active_warehouse_role`: currently NULL
- Branch: `BR-01` (الفرع الرئيسي), through `allowed_branch_ids`
- Status: `Active`

The existing `get_warehouse_team()` roster explicitly includes both `مخزني` and `أمين مخزن`. The existing `set_active_warehouse_role(p_user_id, p_role)` permits the role `مخزن شامل` and validates the supervisor's authority, target company, allowed warehouse job title, and branch intersection.

No role assignment was performed in this review. Use the existing Supervisor UI/RPC after an authorized supervisor session is available; never update `users.active_warehouse_role` directly to bypass the guard.

### Existing authorization state

- The hub uses the read-only `get_warehouse_hub_snapshot()` and its branch scope.
- The seven original application files already contain the unified-role frontend gate.
- Production migrations `20261110003307` and `20261110004233` are present; `20261109233602` is also present and must not be reapplied.
- Current deployed Edge versions observed: start-picking v36, complete-picking v19, start-loading v7, complete-loading v12, unload-runsheet v7, start-return v6, complete-return v28, receive-purchase v18; all ACTIVE with JWT verification enabled.

The hub may expose an operation only when its existing `allowed(role, scope)` rule permits it. A unified job title is not a branch-scope bypass, assignment bypass, receiver-binding bypass, supplier-return creator bypass or document-status bypass. Backend guards remain final.

---

## 7. Data integrity and expected business impact

### Expected impact if Phase 1 is implemented exactly

- No new business tables.
- No new RPC or Edge Function.
- No change to stock on hand, allocation/reservation, supplier balances, cash, treasury or GL.
- No duplication of operation documents.
- No bypass of pending/completed states, assigned employee checks, branch checks or receiver binding.
- The employee acting from the unified shell is still the authenticated Production user, and native workflows retain their existing actor fields.

### Critical non-regression rules

1. Creating/opening a work item does not itself post inventory or finance.
2. Receiving posts only through the existing accepted receipt workflow.
3. Picking reservations and release continue through their existing atomic paths.
4. Loading affects stock only through the current completion path and existing idempotency/assignment guards.
5. Returns and discrepancies retain their current separate lifecycle.
6. Unloading remains the existing `Unloading` voucher flow and must not create a second receipt.
7. Counting remains subject to its existing branch scope and count engine.
8. Manual vouchers remain independent of runsheet workflows and retain their two-stage/receiver/supplier contracts.
9. Duplicate click, retry, reconnect and iframe reload must not duplicate an operation.
10. Parent logout or a denied role must not leave an authorized writer surface alive in a child frame.

---

## 8. Required acceptance and E2E matrix

### Static and contract

- Exactly nine shell tabs are present, with no `operations` launcher or separate source-specific result tab.
- Each of the seven operation keys maps to exactly one original page.
- No new Edge Function, table, RPC, stock write or journal write has been added.
- Parent and original app files are unchanged.
- No external/user-supplied URL can be injected into an iframe.

### Browser, authenticated read-only

Using a real user assigned `مخزن شامل` through Supervisor:

1. Login once to warehouse.html.
2. Open Receiving. Confirm the native pending/completed queue appears without a second login.
3. Open Picker, Loader, Returns, Unloader, Counter and Vouchers the same way.
4. Switch between tabs after opening an active workspace. Verify it is preserved rather than re-created.
5. Verify each tab's native operation queues show the records available to that employee under existing company/branch/assignment filters.
6. Open each corresponding original HTML directly in a second same-origin tab and compare document IDs/statuses for the same records.
7. Verify no duplicate list entries, duplicate realtime handlers, duplicate service-worker registrations, clipped modals or browser errors.
8. Log out from the shell. Verify all child writer surfaces are inaccessible.
9. Test an employee without warehouse authorization and a warehouse user without main-branch scope. Confirm the correct tabs remain inaccessible; do not hide server-side denial.
10. Verify the account shows human actor `أمين مخزن عام`, job `أمين مخزن`, active role `مخزن شامل`, and branch `BR-01`.

### Business record coherence — no artificial production writes

For each operation, use an existing real document only for read-only comparison. A future controlled write test must use the approved reversible QA protocol; do not create a real production receipt, picking completion, loading, return, count adjustment, voucher posting, supplier adjustment or journal entry just to test the shell.

The cross-application acceptance rule is:

`same company + same document id + same operation state + same actor + one business record`

The source-origin attribution must not overwrite the human actor or source document creator.

---

## 9. Rollback plan

Phase 1 rollback is limited to the single target file:

- Restore `warehouse.html` from base blob `ead58ab7c5ad354b5b93a9a20781bfe81db7a245` if the approved patch fails.
- Do not revert the existing unified-role gates, already-applied migrations or deployed Edge versions.
- No business data cleanup should be necessary because this phase adds no writer path and no records.
- Preserve all original operational app files and the previous launcher entry point in Git history.

---

## 10. Deployment and verification status before approval

| Check | Current evidence |
|---|---|
| Source HEAD | CONFIRMED: `fd45a7dd8a3dae92afcc66e485e74a133cb345ae` |
| Unified app currently meets requested UX | **CONFLICT — does not meet requirement** |
| Original seven operational pages exist | CONFIRMED |
| Existing workflows use shared Production contracts | CONFIRMED from source/schema mapping |
| Unified role backend/Edge support | CONFIRMED in Report690 and current Edge version inventory |
| Employee role assignment | UNKNOWN / not assigned; active role is NULL |
| Same-origin iframe headers/session in real browser | UNVERIFIED |
| Latest commit CI status | UNVERIFIED: connector returned no status entries and no workflow runs |
| Cloudflare Production asset parity after `fd45a7d` | UNVERIFIED; Report690 only verified deployment through `2221eea` |
| Production stock/finance side effects in this review | NONE — read-only |
| Operational source/DB changes in this review | NONE |

---

## 11. Governance gate and exact approval required

This ChangeSet is intentionally restricted to `warehouse.html`. It does not authorize changes to Parent, Core, original apps, database schema, RPCs, Edge Functions, permissions, or business data.

The standing constitution and Master CTO Governance require the complete proposed change to be reviewed and explicitly approved before operational source changes. In particular:

- Constitution §6.2: review and owner approval before changes affecting workflow/integration/permissions/data.
- Constitution §7.a: owner applies changes to operational app files; assistant prepares exact source-based ChangeSet.
- Master CTO Governance §77.2–77.3: a general task request is not an open authorization to make unreviewed operational changes.

**Exact approval requested:** approve the Phase 1 `warehouse.html` ChangeSet in §5, using base HEAD `fd45a7dd8a3dae92afcc66e485e74a133cb345ae`, with the exclusions in §5.4 and acceptance/rollback requirements in §§8–9.

No operational source, database, deployment, role assignment or business data was modified while preparing this ChangeSet.

---

## 12. Last verified event

The current workstream has moved from “hub navigation” to a confirmed functional requirement mismatch. The source, app workflows, relevant Production table columns, role assignment contract and deployed Edge inventory have been inspected. The exact workbench direction and Phase 1 target are now defined.

**Next event:** after the owner approves the specific Phase 1 source ChangeSet, apply only the approved `warehouse.html` patch, run static + authenticated no-write E2E, and verify deployment. Do not mark the unified warehouse application complete until all nine tabs and cross-application document coherence pass.
