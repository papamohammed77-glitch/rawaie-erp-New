# Report 692 — Unified Warehouse Native Operational Workbench: Execution, Security Alignment & E2E

**Date:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-692  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**SMART ERP project:** `fiilmooggumokxanwiyx`  
**Scope:** Standalone `companies/company-1/warehouse/warehouse.html`, native operation bundles, shared authentication, manual vouchers and the minimum supplier-return authorization alignment.

## 0. Executive status

**Implemented in Git:** the standalone unified warehouse now hosts the six original warehouse operation experiences and the manual-voucher experience inside one page. It is not a launcher, does not navigate to the original app URLs, does not use iframes, and does not add a Parent menu entry.

**Synthetic browser E2E:** PASS.  
**Supabase authorization migration:** APPLIED.  
**Business data mutation:** NONE.  
**Cloudflare deployment parity:** UNVERIFIED.  
**Authenticated E2E using a real employee assigned `مخزن شامل`:** OPEN; no active user currently has that role.  
**Real stock/supplier/GL posting E2E:** NOT RUN by design; no production movement was created.

The owner’s latest clarification supersedes the earlier launcher and iframe interpretations in Reports 689/691:
- Four outer tabs only: Today, Operations, Vouchers, Account.
- Six operation cards open the full native operation experience inside the same standalone application.
- Five manual-voucher actions remain within the Vouchers workspace.
- The employee is one authenticated person with active warehouse role `مخزن شامل`.
- Results continue to use the original operation tables and writer contracts. There is no source-specific results tab, duplicate document, parallel stock engine, or Parent integration.

## 1. Phased execution

### Phase 1 — Standalone shell and native operation workspaces

Target: `companies/company-1/warehouse/warehouse.html` only.

Outer navigation remains:
1. `today` — Today dashboard.
2. `operations` — six native operation cards/workspaces.
3. `vouchers` — manual stock vouchers.
4. `account` — current authenticated employee/session.

Native operation bundle map:

| Outer operation key | Embedded native module | Original standalone source |
|---|---|---|
| `receiving` | `receiver` | `receiver.html` |
| `picking` | `picker` | `picker.html` |
| `loading` | `loader` | `loader.html` |
| `returns` | `returns` | `returns.html` |
| `unloading` | `unloader` | `unloader.html` |
| `counting` | `counter` | `counter.html` |
| `vouchers` | `vouchers` | `vouchers.html` |

The native HTML/JavaScript is bundled into the standalone warehouse file and mounted into persistent per-module roots. The module wrappers isolate DOM lookup through a scoped document proxy while retaining the original UI, queue/status controls, forms, and operation handlers. No `iframe`, external app navigation, or second copy of a business writer was added.

### Phase 2 — Shared identity, module mapping and lifecycle repair

Three runtime defects were found and corrected:

1. **Operation/native key mismatch.** The outer shell used semantic keys such as `receiving` and `picking`, while the embedded modules registered under `receiver` and `picker`. A fixed map now resolves the module key, root ID, ready/error events and logout cleanup. Workspace state remains keyed by the outer operation key.
2. **DOM bootstrap order.** Each native wrapper declared a local `document` proxy, which is hoisted before assignment. Its first `document.getElementById(...)` therefore dereferenced an uninitialized local variable. All seven root lookups now use `window.document.getElementById(...)` before the proxy is assigned.
3. **Logout/relogin lifecycle.** Native modules attach document/window listeners and realtime/scanner resources. Logout now performs the existing shared `RW_Auth.doLogout`, cleans module services, then reloads the standalone page so old module listeners and closures cannot survive into another employee session.

The Picker module is aligned to the shared `RW_Auth` and `RW_SHARED_SUPABASE` session/client. No second Supabase client or separate login flow is introduced.

### Phase 3 — Manual vouchers and supplier-return authorization

The existing voucher workflow is reused. Its five actions remain:
- Transfer (تحويل مخزني إلى فرع)
- TransferReceive (استلام مخزن من فرع)
- DirectSale (صرف سيارة بيع مباشر)
- DirectReturn (استلام مرتجع سيارة بيع مباشر)
- SupplierReturn (مرتجع مورد)

The original supplier-return contract is retained. The app does not replace it with a generic voucher form.

The following existing SMART ERP functions already accepted `مخزن شامل` for their established lifecycle paths; their posting logic was not changed:
- `create_manual_stock_voucher_atomic`
- `update_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`

The existing SupplierReturn send/completion rules continue to require the authenticated creator where that restriction already exists. The new access checks are consistent with that rule.

### Phase 4 — E2E and production safety

The browser suite uses synthetic auth/RPC responses and a synthetic branch UUID. It performs no business writes. It verifies:
- four outer tabs;
- no iframe or navigation to child app URLs;
- seven native bundles;
- shared core session and Picker auth alignment;
- six native operation workspaces ready and visible;
- five manual voucher actions;
- specialized SupplierReturn contract surface;
- logout cleanup and fresh-session reinitialization;
- active-role gate;
- main-branch versus scoped-branch access gate.

Real production stock, supplier, treasury or GL posting was intentionally not exercised.

### Phase 5 — Remaining release verification

The latest Cloudflare dashboard snapshot available in the connected tab was stale: it still showed a Production pointer at commit `da5c8e1`, while current Git HEAD is `66b3d7f`. The snapshot was last opened before the final native-root correction; the public Pages asset could not be fetched through the available read-only web path. Therefore deployment and published-asset parity are **UNVERIFIED**.

A real active user with `active_warehouse_role='مخزن شامل'` is also not present in the current Production role distribution. No role was assigned or changed in this execution. The Supervisor role list already includes `مخزن شامل`, and the existing guarded `set_active_warehouse_role` RPC remains the correct assignment path.

## 2. Operational source evidence

- Current main HEAD: `66b3d7f616f1aef70fbc45bab7d20e5339e76bb8`.
- Current warehouse file blob: `1de65df6b61f96066eb9e08526d66161d0fc9d99`.
- File size: 626,747 bytes; 97 source lines.
- Seven native module root bootstraps use `window.document.getElementById`.
- Operation/native alias map is present.
- No `iframe` element and no direct links to `receiver.html`, `picker.html`, `loader.html`, `returns.html`, `unloader.html`, `counter.html` or `vouchers.html` are present in the current warehouse source.
- `companies/company-1/main.html` was not changed.
- `companies/company-1/core.js` was not changed.
- The seven original warehouse application files were not changed by this workstream.

### Key warehouse source commits

| Commit | Change |
|---|---|
| `abeda6f4fae847ccae0ef2a6c27b1031e92bbfad` | Build standalone native warehouse workspaces |
| `6f5bc3baea14e82041fa049b354b746aac52ed50` | Expose native module instances and preserve shared ERP context |
| `da5c8e1788088383730d51c11d06e5f759b792fe` | Map operation tabs to native module names |
| `6c2c08f0dd4c64a112acc571baf48d5484db2d87` | Reload after logout to clear native module listeners |
| `b5699dcb52e7cf66487a2a1fe0a3c9bebbd5a5f5` | Initialize native roots before the document proxy |

### E2E evidence

- Workflow: `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`.
- Successful run: `42863832009`.
- Run conclusion: `success`.
- Test workflow commit: `ac858f375b0b7322ba285fd54e2274e3989373f0`.
- Latest workflow file blob: `d446668c7036230a5a9dc158a919d49781d9f0a7`.

Observed PASS markers:
- `WAREHOUSE_FOUR_TAB_CONTRACT`
- `WAREHOUSE_NO_IFRAME_OR_CHILD_NAVIGATION`
- `WAREHOUSE_SEVEN_NATIVE_OPERATION_BUNDLES`
- `WAREHOUSE_SHARED_CORE_SESSION`
- `WAREHOUSE_PICKER_AUTH_ALIGNMENT`
- `WAREHOUSE_FULL_NATIVE_WORKFLOWS_PRESERVED`
- `WAREHOUSE_SUPPLIER_RETURN_CONTRACT_PRESERVED`
- `WAREHOUSE_SHARED_AUTH_AND_FOUR_TAB_SHELL`
- `WAREHOUSE_SIX_FULL_NATIVE_OPERATION_WORKSPACES`
- `WAREHOUSE_FIVE_MANUAL_VOUCHER_ACTIONS`
- `WAREHOUSE_SUPPLIER_RETURN_SPECIALIZED_CONTRACT`
- `WAREHOUSE_ACCOUNT_AND_MODULE_LOGOUT_CLEANUP`
- `WAREHOUSE_LOGOUT_RELOGIN_MODULE_REINITIALIZATION`
- `WAREHOUSE_ACTIVE_ROLE_GATE`
- `WAREHOUSE_MAIN_VS_SCOPED_BRANCH_GATING`

The current-HEAD forensic workflows also completed successfully at `66b3d7f`: Mother Assembly Guard, Mother Inventory Forensic E2E, CTO Helper Files Forensic and current Mother extract.

## 3. SMART ERP migration applied

**Migration version:** `20261110172124`  
**Migration name:** `unified_warehouse_supplier_return_scope`  
**Source file:** `supabase/migrations/20261110172124_unified_warehouse_supplier_return_scope.sql`  
**Source blob:** `098a7c121e5704388d61605713e87518942b5212`

The migration modifies only three existing function definitions, preserving their signatures, SECURITY DEFINER status, search path and grants:

1. `get_supplier_return_contract(uuid,text)`
   - Allows the unified role.
   - For a non-wildcard unified employee, requires the voucher to be a Manual SupplierReturn, created by that same authenticated employee, with `from_type='Branch'`, and the source branch accepted by `app_private.user_can_access_warehouse_branch`.
2. `save_supplier_return_contract(uuid,text,jsonb,text)`
   - Same creator and branch restriction.
   - Preserves the Manual SupplierReturn and Draft-only constraints.
   - Does not post stock, supplier balance or journal effects.
3. `delete_manual_stock_voucher_atomic(uuid,text,text)`
   - Adds a branch-scope check for the unified role through the same canonical helper, closing the NULL/empty branch-list bypass for this role.
   - Preserves the existing no-movement-before-delete guard and the existing branch/role logic for other roles.

The first migration attempt failed on an incomplete replacement anchor in the delete-function body. The migration transaction rolled back. Read-only verification confirmed that none of the function markers were applied and no migration version was recorded. The source patch was corrected to insert the unified-role branch guard before the intact existing branch block, then the migration succeeded as version `20261110172124`.

No new table, RPC, Edge Function, trigger, RLS policy or grant was added. Existing stock/supplier/GL posting functions were not rewritten.

### Post-migration verification

- All three target functions remain SECURITY DEFINER.
- `get_supplier_return_contract`: anon EXECUTE=false; authenticated=true; service_role=true.
- `save_supplier_return_contract`: anon EXECUTE=false; authenticated=true; service_role=true.
- `delete_manual_stock_voucher_atomic`: anon EXECUTE=false; authenticated=false; service_role=true.
- Both SupplierReturn contract functions contain the unified-role creator/branch guard.
- Draft delete contains `app_private.user_can_access_warehouse_branch`.
- Applied migration history contains `20261110172124 unified_warehouse_supplier_return_scope`.

## 4. Production data baseline — unchanged

Read-only counts after the migration:

| Table | Rows |
|---|---:|
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `stock_vouchers` | 0 |
| `stock_voucher_details` | 0 |
| `purchase_invoices` | 5 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |
| `inventory_counts` | 0 |
| `inventory_count_details` | 0 |

The same counts were recorded immediately before the migration. No test voucher, receipt, inventory count, supplier return, stock movement, payment, journal entry or supplier-ledger row was created. No role assignment was made.

Active user warehouse-role distribution:
- `<NULL>`: 26
- `أذونات`: 2
- `استلام`: 1
- `تحضير`: 1
- `تحميل`: 1
- `مرتجعات`: 1
- `مخزن شامل`: 0

The existing Supervisor role assignment path must be used when an authorized employee is assigned the new role. Direct SQL update of `users.active_warehouse_role` was not performed.

## 5. Business/data contract preserved

- The same human employee remains the actor; no app name is substituted into `created_by`, `completed_by`, `picker_id`, `loader_id`, `return_handler_id` or `responsible`.
- Each native module uses its original tables, RPCs, Edge Functions, lifecycle states, idempotency and assignment filters.
- No parallel operation document or source-specific result list is introduced.
- Receiving, picking, loading, returns, unloading and counting continue to use their existing operation contracts.
- Manual vouchers remain independent of runsheets.
- SupplierReturn contract metadata is still saved as a Draft-only contract; the posting/stock/AP/GL writer path remains unchanged and retains its creator/branch/status restrictions.
- Opening a tab, mounting a native module, or saving a draft contract is not treated as physical stock/cash handover or accounting posting.

## 6. Open blockers and exact next actions

1. **Cloudflare deployment parity — UNVERIFIED.** Refresh/inspect the current `rawaea-erp` Pages deployment and confirm that the served `warehouse.html` contains blob `1de65df6...` or the exact current commit artifact. The last visible dashboard snapshot is stale and not evidence of the latest deployment.
2. **Real unified-role user — NOT PRESENT.** Use the existing Supervisor UI and `set_active_warehouse_role` RPC to assign an authorized warehouse employee with correct branch scope. Do not write the role column directly.
3. **Authenticated no-write browser E2E — OPEN.** Once the latest deployment and real role session exist, verify all seven workspaces in the actual session, branch scope, logout propagation and cross-app read visibility.
4. **Business writer E2E — NOT RUN.** Only run reversible QA fixtures after explicit safe fixture design, before/after baseline, exact cleanup and proof that no inventory/supplier/treasury/GL residual remains. Do not use real production transactions as test data.
5. **Visual QA — OPEN.** Verify mobile/desktop sizing, modal boundaries, child form usability, global CSS interactions and scrolling on the deployed artifact. The synthetic browser test proves function readiness, not visual design quality.

## 7. Mutation ledger

| Layer | Change |
|---|---|
| `warehouse.html` | Native workspace mapping/bootstrap/logout fixes; no business engine change |
| Original warehouse apps | No changes |
| Parent `main.html` | No changes |
| Shared `core.js` | No changes |
| Supabase | One migration changing three existing function bodies only |
| Edge Functions | No deploy or new function |
| Tables/data | No business row changes |
| Roles/users | No role assignment or user update |
| Cloudflare | No deployment action verified |

**Last verified event:** native workspace E2E passed; Supabase SupplierReturn/branch authorization migration `20261110172124` applied and verified; production row counts unchanged.  
**Status:** `SOURCE IMPLEMENTED + SYNTHETIC E2E PASS + RPC AUTH ALIGNMENT APPLIED / DEPLOYMENT AND REAL-USER E2E OPEN`.

**Next exact action:** verify the current Cloudflare Pages deployment for the latest main artifact, then run authenticated read-only E2E using an employee assigned `مخزن شامل`. Do not run a stock or financial posting test until a reversible QA fixture and cleanup proof exist.
