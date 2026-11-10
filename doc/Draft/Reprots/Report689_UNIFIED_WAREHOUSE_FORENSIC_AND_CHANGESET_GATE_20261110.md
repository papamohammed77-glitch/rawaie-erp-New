# Report 689 — Unified Warehouse Forensic Review & ChangeSet Gate

**Date:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-689  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Production Supabase project:** `fiilmooggumokxanwiyx` (SMART ERP)  
**Scope:** `companies/company-1/warehouse/warehouse.html` + Parent integration + all warehouse operational apps + role/branch authorization.

## 1. Executive finding — current warehouse.html is not the requested application

Current operational `main` HEAD is `9a73e585443bdad8b55b73b2676ac77385055b63`.

The latest commit added `companies/company-1/warehouse/warehouse.html`, but its Git blob is **identical** to `returns.html`:
- `warehouse.html` blob: `16d02fff2d00759451879204abf218202898f9c0`
- `returns.html` blob: `16d02fff2d00759451879204abf218202898f9c0`

The file contains the Returns application itself: its title, pending/completed/account tabs, return worklists, return editing and completion workflow, and the strict `activeWarehouseRole === 'مرتجعات'` gate. It is not a unified warehouse home, and it cannot serve a user assigned `مخزن شامل`. The copy is a potentially confusing duplicate entry point to the returns workflow. The real Returns source has not been modified by this review.

## 2. Parent and existing architecture verified

The current Parent `companies/company-1/main.html` contains:
- The existing `إدارة المخازن والمخزون` menu.
- A legacy embedded `RW_Warehouse` module (about 3,957 lines) that already contains its own views for receiving, picking, loading, delivery, returns, unloading, vouchers, vehicle/branch/general counts, settlement, and inventory control.
- Existing permission key `warehouse` (labelled `عمال المخازن`).
- Existing individual Parent views for the warehouse processes.

There is **no Parent menu action or direct link** to `warehouse/warehouse.html`. The embedded `RW_Warehouse` implementation is not the requested new standalone hub and must not be copied as a second business engine. The new app should orchestrate the existing standalone apps and their established writer paths, not reproduce their stock/accounting logic.

Shared `core.js` exposes `RW_Auth.hasWarehouseRole(roleName)`, but its current implementation compares the active role exactly. The standalone apps also contain their own direct role checks.

## 3. SMART ERP live state — verified read-only

Migration history contains:
- `20261109233602 unified_warehouse_role_and_scoped_inventory_counts`

The corresponding source file is `supabase/migrations/20261110190000_unified_warehouse_role_and_scoped_inventory_counts.sql` (blob `afe4b5275fe987b74ed334a68b3596193368f4a9`). It is already applied; **do not reapply it**.

The applied migration:
- Adds `مخزن شامل` to the existing `set_active_warehouse_role(uuid,text)` allowlist.
- Adds branch access helper functions.
- Replaces the old permissive `inventory_count_details` policy with a read-only company/branch-scoped SELECT policy.
- Scopes `inventory_counts` reads by company, role/permission and branch; general counts require access to every active company branch.
- Extends the existing `inventory_count_engine` for `مخزن شامل` and validates branch scope for create/upsert operations.
- Revokes direct INSERT/UPDATE/DELETE on `inventory_count_details` from anon/authenticated; the existing service-role engine remains the writer.

Live checks:
- `set_active_warehouse_role` and `get_warehouse_team` are executable by authenticated/service_role under their existing function bodies.
- `inventory_count_engine` remains service_role-only.
- `inventory_count_engine` contains the new role branch.
- No active user is currently assigned `مخزن شامل`.
- Current active role counts: NULL=25, أذونات=2, استلام=1, تحضير=1, تحميل=1, مرتجعات=1.
- `inventory_counts`=0, `inventory_count_details`=0, `inventory_log`=78, `stock_branches`=58, `journal_entries`=21, `supplier_ledger`=3.

The last earlier checkpoint reported inventory_log=76, journal_entries=20 and supplier_ledger=2. The live counts are now +2/+1/+1 respectively. This is a changed production baseline; its cause is **not attributed** to the role migration or this review. This review executed SELECT-only SQL and created no business records.

## 4. Role assignment gap

`supervisor.html` uses the correct guarded `set_active_warehouse_role` RPC and `get_warehouse_team`, with supervisor branch scope. However, its UI role list currently contains only:
`استلام، تحضير، تحميل، مرتجعات، تفريغ، أذونات، جرد، احتياطي`.

It omits `مخزن شامل`, so the production RPC supports the role but the supervisor UI cannot assign it.

`manager.html` instead writes `users.active_warehouse_role` directly. Do not use or extend that path for the new role; assignment must continue through the supervisor RPC and its branch-overlap checks.

## 5. Frontend role gates — all source files parsed

All fetched inline JavaScript in the nine existing warehouse applications parsed successfully. The current gates are:

| App | Current exact active role |
|---|---|
| `receiver.html` | `استلام` |
| `picker.html` | `تحضير` |
| `loader.html` | `تحميل` |
| `returns.html` | `مرتجعات` |
| `unloader.html` | `تفريغ` |
| `counter.html` | `جرد` |
| `vouchers.html` | `أذونات` |

Thus a worker assigned `مخزن شامل` is rejected by every one of those existing app gates, including Counter even though the DB count engine already accepts the unified role.

## 6. Backend authorization — critical integration boundary

### 6.1 Existing guards that reject the unified role

- Deployed `receive-purchase` checks the active role `استلام`; live `receive_purchase_atomic` (5-argument) and `receive_quick_market_purchase_atomic` also contain active-role and branch checks but do not contain `مخزن شامل`.
- Deployed `start-picking` and `complete-picking` check `تحضير`.
- Deployed `start-return` and `complete-return` check `مرتجعات`.
- Voucher RPCs `create_manual_stock_voucher_atomic`, `send_stock_voucher_atomic`, `complete_manual_stock_voucher_atomic`, `update_manual_stock_voucher_atomic`, and `post_manual_stock_voucher_atomic` have existing active-role/permission checks; their live definitions do not contain `مخزن شامل`. Supplier-return completion can affect stock and supplier accounting, so this must not be bypassed by a frontend-only alias.
- `inventory_count_engine` is the exception: it already supports `مخزن شامل` with branch-scoped checks.

### 6.2 Existing backend gaps that must not be widened

The deployed `start-loading v6`, `complete-loading v11`, and `unload-runsheet v6` source was fetched directly from SMART ERP. They authenticate the JWT and verify an active company user, but do not enforce the required warehouse active role, branch scope, or loader/unloader assignment before calling service-role RPCs. The corresponding live RPCs `start_runsheet_loading`, `complete_runsheet_loading`, and `complete_runsheet_unloading` contain no active-role or branch-scope guard.

This is a pre-existing critical authorization gap already identified in Report590. Adding `مخزن شامل` to the UI without closing the server-side boundary would not be a safe integration.

The live `complete_sales_return_credit_note_atomic` also has no active-role/branch check in its definition; the deployed `complete-return` Edge guard is the current role boundary. Preserve its existing stock/financial posting semantics while hardening the caller boundary.

### 6.3 Shared helper and source drift

`supabase/functions/_shared/warehouse-auth.ts` exists in Git, but it is not imported by the warehouse Edge Functions inspected. It manually reconstructs effective permissions and requires the `warehouse` permission; this contract must be reconciled with the existing receiver-specific `receiving` permission and the central effective-profile contract before use.

The Git source tree contains only a small subset of the deployed Edge Function directories. The deployed picker, loading, unloading, return and voucher functions are not all source-managed in the current repository. Their exact deployed source must be versioned before any change is deployed; do not recreate or replace a deployed function from a guessed or abbreviated body.

## 7. Required unified-hub design

The intended app should be a **workflow launcher and operational cockpit**, not a second inventory engine:

1. **Today:** read-only, company/authorized-branch scoped work summary and prioritized exceptions. No stock or finance writes.
2. **Operations:** six launch cards that open the existing full applications in the same origin/session:
   - Receiver → `receiver.html`
   - Picker → `picker.html`
   - Loader → `loader.html`
   - Returns → `returns.html`
   - Unloader → `unloader.html`
   - Counter → `counter.html`
3. **Vouchers:** operation cards for branch transfer, branch receipt, direct-sale vehicle issue, direct-sale vehicle return, and supplier return. Delegate to the existing `vouchers.html` workflow; no new voucher writer.
4. **Account:** current employee, company, assigned branches, active warehouse role and session details from the existing authenticated profile.

Navigation should use same-origin page navigation (not duplicate the business app in an iframe) so each standalone app keeps its own tested UI, state and established writer contracts. Returning to the hub should use browser history or an explicit return link.

Parent integration should add a single hub entry under warehouse operations using the existing `warehouse` permission. Role assignment should be exposed in `supervisor.html` through the existing `set_active_warehouse_role` RPC; do not change job roles or bypass branch scope.

## 8. Required ChangeSet before implementation

The implementation cannot be safely completed by adding a single HTML page. The complete ChangeSet must cover:

1. Replace the current Returns-copy `warehouse.html` with the new hub shell.
2. Add one Parent navigation entry using existing `warehouse` permission.
3. Add `مخزن شامل` to the supervisor roster's operational-role choices, retaining the existing RPC and branch-scope validation.
4. Update the seven frontend gates above so the unified role can enter the correct module without changing each module's business logic.
5. Update the corresponding Edge/RPC authorization predicates so `مخزن شامل` is accepted only after authenticated user, company, effective warehouse permission, authorized branch, operation state and relevant assignment checks. Do not simply append an OR condition to a SECURITY DEFINER writer.
6. Close the loading/unloading server-side authorization gaps before exposing those writers through the unified role.
7. Reconcile voucher create/send/receive/complete/update and supplier-return accounting authorization without changing posting semantics.
8. Ensure all deployed Edge source is versioned in Git before deployment. No new Edge Function or new business table is required by the hub itself.

This is a cross-cutting change affecting stock, supplier AP/journal posting and branch access. Per the owner's permanent ChangeSet rule (writing-block-8888-10 §10.1–10.3 and the operational constitution §6.2/§7a), the exact SQL/function replacements and source diffs must be shown and approved before changing operational apps, RPCs, Edge deployments or production grants. The current task establishes the business goal, but not approval of the unreviewed security/financial writer replacements.

## 9. Competitive design references

The hub's worklist/dashboard approach is consistent with public product documentation:
- Odoo 19 Warehouse Daily Operations dashboard highlights late receipts, deliveries and internal transfers and forecasts scheduled activity for the next seven days: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/reporting/dashboards.html
- Dynamics 365 warehouse mobile menus expose worker-specific menu items, work classes and existing work flows: https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse
- SAP EWM Warehouse Management Monitor centralizes operational status, pending tasks and exception monitoring: https://help.sap.com/docs/SAP_SUPPLY_CHAIN_MANAGEMENT/f41048b9ca054326bb9774db1d46e866/7c06729b-5d71-403d-ba9e-783c571fd549

These support role-based task menus and an exception-driven daily dashboard; they do not justify bypassing RAWAEA's own stock/accounting contracts.

## 10. Verification and release status

- Complete prompt, current state, permanent constitution and Reports 545/590/593/594 reviewed.
- Parent `main.html`, `core.js`, all nine existing warehouse apps, current `warehouse.html`, the migration source, and the shared warehouse-auth helper fetched and analyzed.
- All nine existing app inline JavaScript bundles: syntax **PASS**.
- Current `warehouse.html` equals Returns blob: **CONFIRMED**.
- Live migration history and key function ACLs/role markers: **READ-ONLY VERIFIED**.
- No source file, SQL migration, RPC, Edge Function, Parent UI or business row changed by this review.
- Current live counts and active-role aggregate recorded above.
- Authenticated operational browser E2E: **NOT RUN** (the available ERP tab is the Parent login, not an authenticated warehouse worker session).
- Cloudflare snapshot last showed Production/main at `8a703e1716b4754f005a9ef9827ee8769fc74ccc`, older than current HEAD `9a73e585443bdad8b55b73b2676ac77385055b63`; the dashboard was not refreshed after the new commit. Public asset fetch was inaccessible. Deployment of the current `warehouse.html` copy is **NOT VERIFIED**.

## 11. Next action

Prepare the exact owner ChangeSet for the source/Edge/RPC role and branch guards, then apply the approved implementation in phases:
- Phase A: replace the Returns-copy page with the read-only hub and Parent/Supervisor entry points.
- Phase B: role parity for existing frontends and secure Edge/RPC boundaries.
- Phase C: synthetic integration tests, then authenticated no-write E2E for navigation and role/branch visibility.
- Phase D: controlled business-operation tests only with an approved reversible QA fixture; never test by posting real stock, supplier debt, treasury or journal movements.

**Final status:** `FORENSIC REVIEW COMPLETE — CURRENT warehouse.html IS A RETURNS COPY — ROLE MIGRATION ALREADY APPLIED — UNIFIED ROLE NOT ASSIGNED OR ACCEPTED BY MODULES — CROSS-CUTTING SECURITY/FINANCIAL CHANGESET REQUIRED — NO OPERATIONAL MUTATION`.
