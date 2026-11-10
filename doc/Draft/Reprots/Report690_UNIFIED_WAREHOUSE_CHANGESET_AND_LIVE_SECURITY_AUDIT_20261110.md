# Report690 — Unified Warehouse: live security audit and executable ChangeSet
**Recorded:** 2026-11-10 (Africa/Cairo)  
**Workstream:** Unified Warehouse hub, role parity, operational integration  
**Status:** CHANGESET PREPARED — OPERATIONAL APPLY GATE OPEN  
**Baseline:** LVE-2026-11-10-689 / operational HEAD 9a73e585443bdad8b55b73b2676ac77385055b63

## 1. Executive decision

The current companies/company-1/warehouse/warehouse.html is not a hub. Its Git blob is exactly the Returns app blob (16d02fff2d00759451879204abf218202898f9c0) and its title/content are the Returns application. Do not modify returns.html; replace only warehouse.html with the hub after the operational changeset is approved.

The system already has a unified-role foundation. The live migration 20261109233602 unified_warehouse_role_and_scoped_inventory_counts is applied. It added مخزن شامل to the active-role assignment allowlist and the inventory-count engine/read policies. It must not be rerun. No active user currently has active_warehouse_role='مخزن شامل'.

The missing work is not another database role migration. It is:
1. a real hub UI in warehouse.html;
2. Parent navigation and Supervisor assignment UI;
3. consistent unified-role support in each operational app;
4. authorization and branch-scope enforcement at the deployed Edge Function boundary, preserving the existing atomic RPCs;
5. a secure, read-only hub dashboard data contract;
6. no-write and controlled QA/E2E verification.

No stock, accounting, supplier, treasury, voucher, employee, or other business rows were changed during this review. All Supabase checks were SELECT-only. No Edge Function was deployed and no operational source file was edited.

## 2. Evidence baseline

### 2.1 GitHub source
- Operational repository: papamohammed77-glitch/erp-frontend, branch main.
- HEAD verified by Report689 and current warehouse directory history: 9a73e585443bdad8b55b73b2676ac77385055b63.
- warehouse.html: blob 16d02fff2d00759451879204abf218202898f9c0, identical to returns.html.
- receiver.html: 47ca645aa82c14cd143f5b485afddee31f1cb87b.
- picker.html: d483bd15b36585b975b63c2ef641481a01d5d084.
- loader.html: 4375d3067f9fe5453b49f580339a1f906040967f.
- returns.html: 16d02fff2d00759451879204abf218202898f9c0.
- unloader.html: 30a41c3af75fb9455885b1b0b8427de6842924d6.
- counter.html: 32d0dc8ca0edb7cc68660f0fbd6246408117498d.
- vouchers.html: 339927c5476b74056a8ea9d9c64bd7cf9fefc088.
- supervisor.html: 792f8bbff15a0c724e47b6e6e28f2ffec903b024.
- Shared core: companies/company-1/core.js, blob 2d11b852862c523fc89e6a8b9c510462bb65cc4e.
- Shared warehouse authorization helper: supabase/functions/_shared/warehouse-auth.ts, blob cbeb79f5d5ba1bdd2f733db69c17f8e09808ed7a.
- Parent main.html blob is be58fb0e54a8e4c09ce081b15ebf5420e072bdfd; full 1,906,820-character blob was subsequently retrieved. Exact Parent menu/action insertion anchors and surgical replacements are recorded in §8.4.

### 2.2 Relevant history
- 08f7b20c13244f55589b27945f41d8c6f6f9e97c: adds the shared server-side warehouse role/branch authorization helper.
- 71e1bed55a0cfb41cc777f3dd50f96c2e7b61cb4: unified-role/database foundation (per verified history).
- 184efd1 and 050dc039: prior inventory-count contract work (do not repeat without a new mismatch).
- 0108da0: initial warehouse page creation.
- 9a73e585: renames the file to warehouse.html; the resulting blob is still the Returns app.
- Earlier loading/unloading work established the existing loading-cycle/idempotency design. Preserve loading_cycle_id, erp_operation_registry, the TASK-028 Loading/Unloading keys, and all current stock-movement sequencing.

The referenced Report590 file could not be retrieved at the guessed path and repository search for the exact name returned no result. Report689 remains the direct current forensic source. This is a missing historical artifact, not evidence that its findings are false.

### 2.3 Supabase SMART ERP
Project: fiilmooggumokxanwiyx, ACTIVE_HEALTHY.

Applied migration:
20261109233602 unified_warehouse_role_and_scoped_inventory_counts.

Do not reapply it. It already:
- adds مخزن شامل to set_active_warehouse_role;
- introduces branch-scope helper functions;
- scopes inventory count header/detail reads;
- permits the unified role in inventory_count_engine;
- keeps count detail writes behind the existing atomic engine.

Read-only baseline captured:
- active unified-role users: 0;
- inventory_counts: 0;
- inventory_count_details: 0;
- inventory_log: 78;
- stock_branches: 58;
- journal_entries: 21;
- supplier_ledger: 3.

These are record counts, not balances or stock quantities. The previous count discrepancy is not attributed to this work.

### 2.4 Static syntax verification
Inline JavaScript was extracted and compile-checked using new Function without executing application code:
- warehouse.html: PASS (but it is still Returns code);
- receiver.html: PASS;
- picker.html: PASS;
- loader.html: PASS;
- returns.html: PASS;
- unloader.html: PASS;
- counter.html: PASS;
- vouchers.html: PASS;
- supervisor.html: PASS.

This is a syntax-only check, not authenticated E2E.

### 2.5 Cloudflare
The connected Cloudflare tab snapshot was last opened on 2026-11-09 23:33 and its newest visible deployment was 08f7b20. It predates operational HEAD 9a73e585. Therefore current Cloudflare Production parity with HEAD 9a73e585 is UNKNOWN/UNVERIFIED. The snapshot must not be described as a current deployment check.

## 3. Root causes and exact integration gaps

### 3.1 Frontend role gates
All existing apps use exact-role checks. A user assigned مخزن شامل is rejected by these gates:

| App | Current exact role | Required frontend parity |
|---|---|---|
| receiver.html | استلام | accept استلام OR مخزن شامل |
| picker.html | تحضير | accept تحضير OR مخزن شامل |
| loader.html | تحميل | accept تحميل OR مخزن شامل |
| returns.html | مرتجعات | accept مرتجعات OR مخزن شامل |
| unloader.html | تفريغ | accept تفريغ OR مخزن شامل |
| counter.html | جرد | accept جرد OR مخزن شامل |
| vouchers.html | أذونات | accept أذونات OR مخزن شامل |

Precise current gate strings observed:
- Receiver has the same role predicate in the initialization path and restored-session path; update both occurrences.
- Picker reads users.active_warehouse_role directly and compares activeRole !== 'تحضير'.
- Loader uses user.activeWarehouseRole !== 'تحميل'.
- Returns uses user.activeWarehouseRole !== 'مرتجعات'.
- Unloader uses user.activeWarehouseRole !== 'تفريغ'.
- Counter uses u.activeWarehouseRole !== 'جرد'.
- Vouchers checks s.user.activeWarehouseRole!=='أذونات' during initialization and computes warehouseVoucherRole using exact equality. Update both; do not weaken branchInScope, creator, privileged, receiver assignment, or status logic.

The role remains an operational assignment in users.active_warehouse_role. Do not change the employee's HR/job role and do not grant the base warehouse permission automatically. A user must have the existing warehouse permission (or verified owner status) and the assigned role. The shared core RW_Auth.hasWarehouseRole() currently compares exact roles; changing it globally would affect unrelated consumers. Prefer narrowly updating the seven app gates rather than broadening the shared helper.

### 3.2 Supervisor assignment UI
Current exact list:
    var roles=['استلام','تحضير','تحميل','مرتجعات','تفريغ','أذونات','جرد','احتياطي'];
    var icons={'استلام':'📦','تحضير':'📋','تحميل':'🚛','مرتجعات':'↩️','تفريغ':'🔄','أذونات':'📄','جرد':'🔍','احتياطي':'🪑'};

Required surgical replacement:
    var roles=['استلام','تحضير','تحميل','مرتجعات','تفريغ','أذونات','جرد','احتياطي','مخزن شامل'];
    var icons={'استلام':'📦','تحضير':'📋','تحميل':'🚛','مرتجعات':'↩️','تفريغ':'🔄','أذونات':'📄','جرد':'🔍','احتياطي':'🪑','مخزن شامل':'🏬'};

Also add the matching مخزن شامل icon branch in the existing saved-role badge expression. Keep the existing set_active_warehouse_role RPC as the only role assignment path. Do not write users.active_warehouse_role directly and do not alter the employee's main role.

### 3.3 Shared server helper exists but is not wired
supabase/functions/_shared/warehouse-auth.ts already implements:
- token/user verification;
- company/status validation;
- direct + role + role_permissions permission resolution;
- verified-owner validation;
- requireWarehouseRole, which already accepts مخزن شامل as a unified alias;
- assertWarehouseBranch;
- assertWarehouseMainBranch;
- assertWarehouseVehicleBranch.

It currently requires the warehouse permission for non-owners. This is appropriate for warehouse-only actions but must not be blindly reused for Receiver if that actor is authorized only by the existing receiving permission. Receiver's current contract accepts warehouse OR receiving; preserve that distinction. The helper is not imported by the inspected deployed loading/unloading functions.

### 3.4 Live Edge Functions are the actual security boundary
The following deployed Edge Functions were read from SMART ERP. Most do not exist as source-managed files in the operational GitHub repository; only receive-purchase/index.ts is currently source-managed among the checked paths.

| Deployed Edge Function | Live version | Current finding |
|---|---:|---|
| start-loading | 6 | Authenticates user and company, then calls RPC; no warehouse-role or branch-scope guard |
| complete-loading | 11 | Authenticates user/company and loads runsheet, then calls RPC; no active-role, branch-scope or loader-assignment guard |
| unload-runsheet | 6 | Authenticates user/company, then calls unloading RPC; no active-role or branch-scope guard |
| start-return | 5 | Has explicit Returns role and active return-handler checks; add unified role without removing assignment/status rules |
| complete-return | live deployed source inspected | Checks return workflow and handler; add unified role without removing assignment/status rules |
| receive-purchase | 17 | Uses effective profile and accepts only active role استلام |
| create-stock-voucher | 12 | Wrapper authenticates company; writer authorization is in atomic RPC |
| send-stock-voucher | 20 | Wrapper authenticates company; SupplierReturn authorization is in atomic RPC |
| receive-stock-voucher | 22 | Wrapper authenticates company; transfer receiver binding and branch checks are in atomic RPC |
| complete-stock-voucher | 4 | Wrapper authenticates company; SupplierReturn authorization is in atomic RPC |

The exact deployed function versions and code must be treated as production source. Do not deploy a new Edge Function. For the untracked functions, first establish source-managed copies in the operational repository from the exact live code, then apply the reviewed minimal edits and deploy the existing function slugs. Do not overwrite live code from an older Git snapshot.

### 3.5 RPC security and business semantics
Live ACL checks confirm the loading/unloading and voucher writer RPCs are executable by service_role, not authenticated or anon. Therefore the public Edge Function boundary must validate the authenticated actor before invoking the service-role RPC.

Key RPC facts:
- start_runsheet_loading, complete_runsheet_loading, and complete_runsheet_unloading are SECURITY DEFINER and service-role-only. Their definitions preserve run-sheet status, vehicle validity, loading cycle, idempotency registry and stock movement semantics, but do not contain an active warehouse-role predicate.
- complete_runsheet_loading and complete_runsheet_unloading must not be replaced or rewritten as part of the UI work.
- receive_purchase_atomic five-argument overload has the RECEIVE_PERMISSION_GUARD and branch checks. It currently accepts only active role استلام (plus existing warehouse/receiving permission). The four-argument overload delegates to the five-argument version.
- receive_quick_market_purchase_atomic has the same exact active role requirement استلام and permission contract.
- SupplierReturn send and completion are explicitly guarded in their atomic RPCs. send_stock_voucher_atomic calls assert_supplier_return_contract; complete_manual_stock_voucher_atomic validates SupplierReturn role and branch before delegating to the core completion function.
- Voucher creation/update paths contain role and branch predicates. The special Transfer and DirectReturn path is explicitly bound to the existing أذونات assignment for warehouse keepers.
- post_manual_stock_voucher_atomic enforces branch scope and the transfer receiver binding. Preserve its partial/full RECEIVE idempotency.

Do not grant direct execute to authenticated/anon, do not change service-role ACLs, and do not bypass the atomic RPCs.

## 4. Required ChangeSet

### Phase A — Hub UI (warehouse.html only)
Replace the Returns-copy content in warehouse.html with a new standalone hub. Do not alter returns.html.

Required navigation:
- Today: operational summary, assigned work, exceptions and last-refresh indicator.
- Operations: six launch tiles for Receiver, Picker, Loader, Returns, Unloader, Counter.
- Vouchers: one launch surface for the existing vouchers.html, with clear labels for Transfer, Direct Sale Issue, Direct Sale Return, Supplier Return, and branch receipt. Branch receipt is the receiving action of an existing Transfer voucher; it is not a new voucher type.
- My Account: authenticated profile, active warehouse role, company, and authorized branch scope; read-only.

Open existing app pages using same-origin relative links:
- receiver.html
- picker.html
- loader.html
- returns.html
- unloader.html
- counter.html
- vouchers.html

Do not iframe the apps, copy their business logic, invent query-string deep links, or create a second stock engine. Each existing app retains its own complete workflow and native forms/modals. Preserve session behavior and the existing PWA service-worker path.

The hub must not create stock, finance, supplier, treasury, count, or voucher records. It is an orchestrator/read-model only.

### Phase B — Dashboard read model
Current RLS is not uniformly branch-scoped:
- runsheets SELECT is company + permission scoped;
- stock_vouchers SELECT is company scoped;
- inventory_counts/detail policies are branch scoped by the applied migration.

Do not query company-wide runsheets or vouchers in the hub and merely hide unauthorized rows in JavaScript. A malicious client could bypass presentation filtering. Prepare one read-only SECURITY DEFINER RPC (suggested name: get_warehouse_hub_snapshot) that derives auth.uid(), active user, company, active role and allowed branch scope server-side and returns only authorized summary data. It must contain no INSERT/UPDATE/DELETE, no calls to stock movement, accounting, treasury, supplier ledger, or voucher posting functions. The RPC should return summary counts and exception references only, not expose unrestricted source rows.

Before writing this RPC, resolve the operational branch mapping for runsheets. runsheets has no branch_id; it references driver_id, vehicle_id, picker_id, loader_id and return_handler_id. vehicles.mobile_branch_id is the van stock branch; loading/unloading writer functions use the configured main_branch_id and van branch. Do not assume that a van branch equals the warehouse branch. Use the exact established source-branch mapping and test it with read-only queries before defining the read model.

No new table and no new Edge Function are required for the hub.

### Phase C — Unified role parity
For every app, preserve its current permission and status checks while adding the unified role as an alternative active warehouse role. The unified role must not bypass:
- verified owner checks;
- company membership and active status;
- branch scope;
- runsheet assignment (picker_id, loader_id, return_handler_id);
- workflow status and idempotency;
- vehicle active/mobile-stock checks;
- voucher creator/receiver assignment;
- SupplierReturn contract validation.

Specific server changes:
1. Wire the existing shared helper into start-picking, complete-picking, start-loading, complete-loading, unload-runsheet, start-return and complete-return after copying the exact deployed source into Git. Use requireWarehouseRole with the app's role; add the unified alias only through that helper. Use assertWarehouseMainBranch for workflows whose source branch is the configured main warehouse. For operations whose source is a vehicle branch, use assertWarehouseVehicleBranch only after confirming the existing operation contract requires that branch.
2. start-loading must verify the actor and main-warehouse branch before the RPC; the RPC self-assigns loader_id. complete-loading must verify runsheets.loader_id equals the actor's public user id and the run-sheet is still in the same active Loading cycle before the RPC. Preserve loading_cycle_id idempotency.
3. unload-runsheet must verify the active role, main-warehouse branch, same company, run-sheet status Loaded, and valid vehicle. There is no unloader_id column in runsheets; do not invent an assignment field or claim a per-unloader assignment exists. If a future requirement demands one, it is a separate schema/workflow design.
4. Picking and Returns must preserve their existing self-assignment and completion ownership checks. Add the same branch scope using the proven main-warehouse source.
5. Receiver must preserve its current distinction between warehouse and receiving permissions. Add مخزن شامل to both the Edge profile gate and the two receiving RPC role guards; do not weaken branch validation.
6. Voucher creation/update/send/complete: add مخزن شامل only to the exact active-role predicates that currently accept أذونات. Preserve all branch checks, transfer receiver binding, and SupplierReturn assertions. In particular, SupplierReturn role expansion changes who can trigger stock and supplier-account effects and must be included in the reviewed approval diff; do not silently widen it.

### Phase D — Supervisor and Parent
- Supervisor role list and icon changes are specified in §3.2.
- Parent: exact surgical insertion is now confirmed in §8.4. Add one prominent entry under the existing warehouse operations section, gated by the existing warehouse permission, and add the corresponding action handler. Preserve all old links during rollout. Do not remove or repoint legacy app entries until hub E2E passes.

## 5. Acceptance and test matrix

### Static / no-write tests
- Compile every changed inline JavaScript block.
- Verify all seven role gates: each legacy role remains accepted; مخزن شامل accepted; unrelated role rejected; inactive user rejected; unverified owner rejected.
- Verify Supervisor displays the new role and calls the existing set_active_warehouse_role RPC only.
- Verify hub links resolve to the seven existing app paths and do not iframe them.
- Verify no dashboard query exposes cross-company or out-of-scope branch rows.
- Verify no duplicate app state engine or duplicate service-worker registration is introduced.
- Verify Parent legacy menu entries remain available.

### Authenticated no-write E2E
Use a real authenticated warehouse user with an existing allowed branch; do not change their role or create test data just to get past the gate. Confirm:
- hub login/session restore;
- Today tab load, empty state, refresh and error handling;
- all six operation links open the correct app;
- all voucher links open vouchers.html without invalid query parameters;
- My Account shows the actual role/branch;
- logout clears the session;
- a user without warehouse permission cannot enter the hub;
- a user with a different active role cannot use warehouse modules;
- a unified-role user cannot access a branch outside their allowed scope.

### Writer / business-impact QA
Only after the exact operational diff and rollback are approved, use synthetic QA fixtures on Production under the permanent constitution §6.4:
- unique QA references and operation_id;
- baseline snapshots of affected tables and balances;
- transaction rollback where possible;
- if committed E2E is unavoidable, predefine complete cleanup across all dependent rows, audit, storage, stock, supplier ledger, journal, treasury and cash records;
- remove all fixtures and compare the post-cleanup state to baseline.

Never test with real purchase orders, real supplier returns, real stock, or real financial balances. Never delete a real posted document to clean up a test.

### Explicit non-effects
For hub navigation and read-only dashboard:
- stock_branches unchanged;
- inventory_log unchanged;
- journal_entries unchanged;
- supplier_ledger unchanged;
- treasury/cash_box unchanged;
- stock_vouchers unchanged;
- purchase receipts and count sessions unchanged.

For actual operational writers, assert only the established expected stock effects and no unrelated accounting or supplier effects. SupplierReturn must be tested separately because it can post stock and supplier-account effects.

## 6. Governance and apply boundary

This ChangeSet is prepared from current live evidence. It is not applied.

The permanent constitution §6.2 and §7a require the exact operational source diff, effect, test and rollback to be presented before a production-impacting source/DB change; §7a reserves direct application of operational app files to the owner. The user's broad execution instruction does not authorize inventing unavailable source text, bypassing that explicit boundary, or making an unreviewed change to stock/supplier posting authority.

The next work is not another general analysis:
1. materialize the seven exact frontend gate replacements and the confirmed Parent menu/action patch;
2. copy the exact live Edge sources into their source-managed paths and build the narrow guard diffs;
3. produce the read-only hub RPC definition after branch mapping is proven;
4. run static and no-write tests;
5. present the exact final diff and rollback as one coherent ChangeSet for the required operational apply gate.

## 7. Final verified status

- Root cause of warehouse.html: CONFIRMED.
- Applied unified-role migration: CONFIRMED; do not rerun.
- Current active unified-role user count: CONFIRMED zero.
- Frontend exact-role blockers: CONFIRMED.
- Supervisor role-list omission: CONFIRMED.
- Shared warehouse auth helper exists: CONFIRMED; not wired to inspected Edge functions.
- Loading/unloading Edge role/branch/assignment gaps: CONFIRMED in live deployed versions.
- Loading/unloading RPC service-role-only ACL: CONFIRMED.
- Receiver RPC role guards still exact-role: CONFIRMED.
- Voucher SupplierReturn role guards: CONFIRMED; financial/stock effect must remain protected.
- Hub dashboard branch-safe read contract: UNKNOWN until run-sheet branch mapping is resolved.
- Parent source insertion anchor: CONFIRMED by full Git blob retrieval; exact menu/action patch recorded in §8.4.
- Cloudflare current production parity with HEAD 9a73e585: UNVERIFIED; available snapshot is stale.
- Authenticated warehouse worker E2E: NOT RUN.
- Business-data writes: NONE.
- Operational code changes: NONE.
- Final status: ROOT CAUSES CONFIRMED — OWNER CHANGESET APPLY GATE OPEN.


## 8. Industry benchmark and design implications

The benchmark supports a unified task-navigation layer, but not duplicated warehouse business logic:

- Odoo Inventory/Barcode exposes receipts, delivery orders, internal transfers and picking as operation-specific work entry points. Its barcode workflow opens outstanding receipt operations, supports scanning and quantity confirmation, and validates the transfer only at the operational completion point. This supports RAWAEA's design of one hub with clear task cards that launch the existing operation apps, while each app retains its native document and validation flow. Sources: https://www.odoo.com/documentation/master/applications/inventory_and_mrp/barcode/setup/operation_types.html and https://www.odoo.com/documentation/master/applications/inventory_and_mrp/barcode/operations/receipts_deliveries.html
- Microsoft Dynamics 365 Warehouse Management separates activity/inquiry menus, creation of work, and processing of existing work. It uses work classes to control which roles can process work, and supports user-directed or system-directed work selection. This supports keeping role/branch authorization separate from visual navigation and preserving assignment/status guards at the server boundary. Source: https://learn.microsoft.com/en-us/dynamics365/supply-chain/warehousing/configure-mobile-devices-warehouse
- SAP EWM's RF framework separates business logic from device presentation, supports personalized menus and screens, and includes picking, putaway, loading, unloading and physical inventory as standard work execution transactions. This supports using warehouse.html as a presentation/navigation shell while leaving transaction logic in the established apps and atomic services. Source: https://help.sap.com/docs/SAP_SUPPLY_CHAIN_MANAGEMENT/57574d15fa1d414792d74047b66c3e41/4d4fa477c9c20c7ae10000000a42189c.html

Design decisions derived from these references:
1. Keep one prominent operation menu with task-specific launch cards, optimized for touch.
2. Keep each operation's own workflow, confirmations, exceptions and server transaction contract.
3. Separate read-only inquiry/monitoring from work execution and from stock/finance posting.
4. Enforce work classes as role + branch + assignment + document status at the server boundary; a hub menu is never an authorization control.
5. Do not create a new generic "warehouse transaction" engine or merge all operation-specific business rules into the hub.



### 8.1 Voucher workflow nuance — preserve creator and receiver binding

A deeper read of vouchers.html actionFor() shows that the unified role must not be treated as a universal bypass:

- Transfer / status Sent: receive is permitted only when the current user's id equals stock_vouchers.receiver_user_id. Keep this exact receiver binding for all roles, including مخزن شامل. Never replace it with a generic warehouseVoucherRole check.
- DirectReturn / status Sent: the current UI allows receive for privileged users or the active أذونات role when the destination branch is in scope. The warehouseVoucherRole predicate should accept أذونات OR مخزن شامل, while preserving branchInScope(v.to_id).
- SupplierReturn / status Sent: the current UI permits completion only to the voucher creator or privileged warehouse/management users. Preserve this rule. For the new role to complete its own SupplierReturn, the RPC role predicate should allow مخزن شامل only when the acting user is the creator; it must not allow completion of another user's SupplierReturn merely because the actor has the unified role.
- SupplierReturn send: preserve the existing creator/privileged UI action and supplier-return contract. The server role extension must be conditional on creator identity for مخزن شامل, or otherwise preserve the existing أذونات/manager path.
- Draft update: preserve the existing status=Draft restriction, operation_id/idempotency, branch scope, and existing editor authorization. Do not allow edits after Sent/Received/Completed.
- DirectSale and DirectReturn remain their existing creator/privileged/receiver workflows; do not make them generic actions for every user who can open the hub.

Acceptance tests must explicitly prove:
1. unified role cannot receive a Transfer unless receiver_user_id matches;
2. unified role can receive DirectReturn only within allowed destination branch;
3. unified role can send/complete its own SupplierReturn only, and cannot complete another employee's SupplierReturn;
4. posted SupplierReturn remains non-editable and all supplier/stock effects continue through the existing atomic contract.



### 8.2 Exact frontend gate replacements

Apply only these predicate-level edits; do not reformat or replace complete functions:

| File | Current predicate | Replacement predicate |
|---|---|---|
| receiver.html (2 occurrences) | if (!user.isOwner && user.activeWarehouseRole !== 'استلام') | if (!user.isOwner && user.activeWarehouseRole !== 'استلام' && user.activeWarehouseRole !== 'مخزن شامل') |
| picker.html | if(!isOwner && activeRole !== 'تحضير') | if(!isOwner && activeRole !== 'تحضير' && activeRole !== 'مخزن شامل') |
| loader.html | if (!isOwner && user.activeWarehouseRole !== 'تحميل') | if (!isOwner && user.activeWarehouseRole !== 'تحميل' && user.activeWarehouseRole !== 'مخزن شامل') |
| returns.html | if (!isOwner && user.activeWarehouseRole !== 'مرتجعات') | if (!isOwner && user.activeWarehouseRole !== 'مرتجعات' && user.activeWarehouseRole !== 'مخزن شامل') |
| unloader.html | if (!user.isOwner && user.activeWarehouseRole !== 'تفريغ') | if (!user.isOwner && user.activeWarehouseRole !== 'تفريغ' && user.activeWarehouseRole !== 'مخزن شامل') |
| counter.html | if(!u.isOwner&&u.activeWarehouseRole!=='جرد') | if(!u.isOwner&&u.activeWarehouseRole!=='جرد'&&u.activeWarehouseRole!=='مخزن شامل') |
| vouchers.html init | if(!s.user.isOwner&&s.user.activeWarehouseRole!=='أذونات') | if(!s.user.isOwner&&s.user.activeWarehouseRole!=='أذونات'&&s.user.activeWarehouseRole!=='مخزن شامل') |

In vouchers.html, the local role variable is currently:
    var warehouseVoucherRole =
        String(user.activeWarehouseRole || user.active_warehouse_role || '') === 'أذونات';

Replace only the final equality with:
    ['أذونات','مخزن شامل'].indexOf(
        String(user.activeWarehouseRole || user.active_warehouse_role || '')
    ) >= 0;

This local predicate is used for DirectReturn receiving and must continue to be combined with branchInScope. It must not be used to bypass the exact Transfer receiver binding or SupplierReturn creator restriction described in §8.1.

Receiver's duplicate initialization/restored-session checks must both be updated. Do not edit RW_Auth.hasWarehouseRole globally; the seven app predicates are the narrow consumers.



### 8.3 Loading / picking / return assignment details verified against live RPCs

Live deployed Edge source hashes:
- start-picking v35: fca0377fce2d02d52a17bdbbdd98cfe9cc449d052533df0a3b021be11c79914a
- complete-picking v18: 14b4d650253e73abc7c7a1b1f25a8674849c11e32d21ae9928701f19705b0537
- start-loading v6: b0e1736ac7606c1c0b81dfdccd75cc90dbad955651961a24019b6e3c4a1988e1
- complete-loading v11: c0ca692a29d14d64ec3729ae4bd12b9b84268e826ffc1c6993a48617b552b286
- unload-runsheet v6: 34323971351b98b8cd7d7bd83fa25a80f135329cd2b2e09b80c3416a0c6f10e0
- start-return v5: 47e92999e1585956bf9f25fcf6ec80921ceef71316a59a7b5a1c2b1d6290d493
- complete-return v27: 3b4d7ff8053ca35813ad24639093549e7aec622d784a3d18bbfa9ef3d54f9da1

Important distinctions:
- start-picking directly transitions an Open/Confirmed runsheet to Picking and self-assigns picker_id. It must receive role + main-branch authorization before that update. Its existing concurrent-start/retry behavior must remain unchanged.
- complete_runsheet_picking checks the authenticated business user's picker_id against the runsheet before reserving stock and completing the pick. Preserve this existing assignment check and its reservation semantics; the function explicitly returns inventory_log_written=false.
- start_runsheet_loading assigns loader_id and starts the loading cycle. Preserve its existing RPC.
- complete_runsheet_loading checks status=Loading, vehicle, loader_start and loading_cycle_id, but the live function does NOT verify runsheets.loader_id against the actor. The complete-loading Edge Function must add this check before invoking the service-role RPC. It must also verify the actor's main-warehouse branch. Do not modify the RPC's TASK-028 idempotency or stock posting logic.
- complete_runsheet_unloading checks Loaded state and loading_cycle_id, then posts Unloading stock movements from the VAN branch back to app_settings.main_branch_id and clears the loading cycle. There is no unloader_id field or per-unloader assignment contract. Add role and main-warehouse branch checks at the Edge boundary; do not invent an assignment column.
- start-return self-assigns return_handler_id after validating Delivered state and pending return quantities. Preserve that self-assignment and pending-quantity logic.
- complete-return verifies Returning state and return_handler_id equals the current user before calling complete_sales_return_credit_note_atomic. Keep this gate limited to runsheet returns; do not broaden the separate POS/order return contract.
- runsheets has only the trg_audit_runsheets audit trigger among non-internal triggers. The start-picking direct status/assignment update therefore creates an audit event, but it is not itself a stock movement. The actual pick reservation occurs in complete_runsheet_picking.

These details correct any interpretation that every app needs a newly invented assignment model: use the existing picker_id, loader_id and return_handler_id contracts where they exist; unloading has no per-worker assignment field.



### 8.4 Exact Parent main.html integration patch — source retrieval now resolved

The complete Parent blob was retrieved through GitHub fetch_blob (1,906,820 characters), blob SHA be58fb0e54a8e4c09ce081b15ebf5420e072bdfd. Its single inline JavaScript block compile-checks PASS. The source insertion points are confirmed:

**A. Warehouse operations menu — source line 1530**

Current block:
    { label: 'العمليات المخزنية', icon: 'fa-timeline', submenu: [
        { view: 'receiving', label: 'الاستلام' },
        { view: 'picking', label: 'التحضير' },
        { view: 'loading', label: 'التحميل' },
        { view: 'delivery', label: 'التوصيل' },
        { view: 'return', label: 'المرتجعات' },
        { view: 'unloading', label: 'التفريغ' }
    ] },

Surgical replacement:
    { label: 'العمليات المخزنية', icon: 'fa-timeline', submenu: [
        { action: 'openWarehouseHub', label: 'المخزن الشامل', icon: 'fa-warehouse', perm: 'warehouse' },
        { view: 'receiving', label: 'الاستلام' },
        { view: 'picking', label: 'التحضير' },
        { view: 'loading', label: 'التحميل' },
        { view: 'delivery', label: 'التوصيل' },
        { view: 'return', label: 'المرتجعات' },
        { view: 'unloading', label: 'التفريغ' }
    ] },

**B. Navigation action handler — source line 2367**

Current block:
    _handleAction(action, arg) {
        if (action === 'openDataEntry') {
            window.open('warehouse/data.html', '_blank', 'noopener,noreferrer');
            return;
        }

Insert immediately after the openDataEntry block:
    if (action === 'openWarehouseHub') {
        window.open('warehouse/warehouse.html', '_blank', 'noopener,noreferrer');
        return;
    }

Permission is already implemented by RW_Navigation._hasPermission(item): it calls RW_Permissions_check(item.perm). The existing permission key warehouse is already declared in Parent app permissions. Do not add a new permission, do not modify _hasPermission, and do not remove the legacy operation entries.

Relative URL is correct from companies/company-1/main.html: warehouse/warehouse.html resolves to companies/company-1/warehouse/warehouse.html.

