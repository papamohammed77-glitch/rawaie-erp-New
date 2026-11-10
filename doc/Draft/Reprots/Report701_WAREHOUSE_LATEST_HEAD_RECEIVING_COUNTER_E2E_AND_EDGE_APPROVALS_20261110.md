# Report701 — آخر HEAD ونجاح E2E وتكامل صلاحيات المخزن الشامل

**التاريخ:** 2026-11-10 (Africa/Cairo)  
**النطاق:** استمرار تنفيذ Unified Warehouse بعد LVE-700؛ الأذونات اليدوية، Receiver، الجرد، مسؤول الاستلام، الصلاحيات الخلفية، وأثر Production.  
**الحالة:** `LATEST MOCKED BROWSER E2E PASS + PRODUCTION DATA UNCHANGED + TRANSFER RECEIVER FALLBACK APPLIED / EDGE ROLE ALIGNMENT AND UNSAFE REOPEN CONTAINMENT REQUIRE EXACT OWNER CHANGE APPROVAL / CURRENT CLOUDFLARE DEPLOYMENT NOT REFRESH-VERIFIED`.

## 1. نقطة المصدر الحالية

- Operational repository: `papamohammed77-glitch/erp-frontend` / `main`.
- Latest HEAD: `9a6ac1f916d88cdbb54ab154c1aa3a0761c2a89a`.
- Current blobs:
  - `companies/company-1/warehouse/warehouse.html`: `b617dc7a040df60f20f5d84321500d3dd8c11e31`.
  - `companies/company-1/warehouse/receiver.html`: `f2bd1e427b902924a50531f886ba22bb61912b91`.
  - `companies/company-1/warehouse/vouchers.html`: `bbbcd3bd577dfddf1a0ccb0f1e23b6060431b2fd`.
  - `companies/company-1/warehouse/picker.html`: `a94e18f1c7b2de5dad912011bb32999611976b8e`.
  - `companies/company-1/warehouse/returns.html`: `56868aa5c0300d22de2774e3643562cc23045d31`.
  - E2E workflow: `.github/workflows/warehouse_hub_browser_e2e_20261110.yml`, blob `901ec101e69247d6b7cff1ba15703f1decb8e00e`.
- The last commits after the prior LVE-700 source checkpoint focused on: Receiver return-to-list after successful receipt; preserving PO/QMP source filter; retaining branch and vehicle fixtures for Counter tests; isolating Counter E2E stages; fixing the test loop brace; and adding stage-aware timeout diagnostics.
- No additional operational HTML/Edge/SQL/production change was made in this continuation. No test transaction was written to SMART ERP.

## 2. What is now verified in the unified application

### 2.1 Manual voucher parity

The embedded `RW_NATIVE_BUNDLES.vouchers` was compared with standalone `vouchers.html` at the function/member level. The original functions are all present in the embedded module; no original voucher method was missing. The five existing manual actions remain:
- `Transfer`
- `TransferReceive`
- `DirectSale`
- `DirectReturn`
- `SupplierReturn`

The embedded module retains the original create/edit/delete/send/receive/complete/cancel/detail/search/print/export/report functions and the specialized SupplierReturn contract. Its differences are isolated DOM/module adaptation and the additional `BranchReceipt` request UI. It continues to share `core.js` authentication and Supabase client; it does not create a second stock engine or a separate client.

The request to receive from another branch is a Draft `Transfer` with `request_origin='WarehouseBranchReceipt'`; it is not a new stock-movement type and does not post stock at request creation.

### 2.2 Receiver and cross-module workflows

The successful receipt handler in both standalone `receiver.html` and the embedded Receiver bundle:
1. clears the active document index;
2. increments the document-open sequence;
3. explicitly renders the pending/list view;
4. refreshes the queue silently.

This fixes the case where the refreshed queue signature is unchanged but the operator must still return to the pending list. The PO/QMP source filter is retained after the operation.

The current Receiver uses `receive-purchase` v18. The dormant `reopen-receiving` endpoint is not referenced by current `receiver.html`.

### 2.3 Current browser E2E

- GitHub Actions run: `42909714464`.
- Tested HEAD: `9a6ac1f916d88cdbb54ab154c1aa3a0761c2a89a`.
- Job: `130156838407` — `standalone-warehouse`.
- Run status/conclusion: `completed / success`.

The actual Playwright log confirms:
- four-tab shell, repeated responsive tab navigation, no iframe or child-app navigation;
- all seven native bundles and shared identity/client, with no duplicate Supabase client;
- Receiver PO partial-acceptance contract, return-to-pending behavior, QMP full rejection without a stock receipt, and completed audit history;
- Picker/Loader/Returns/Unloader pending-data rendering;
- Counter branch, vehicle, and general-count scope modes; create/populate/get/upsert; and save of a synthetic counted quantity within the browser mock;
- six native operation workspaces;
- five manual voucher actions and the SupplierReturn contract;
- branch receipt source selection, requester/source action separation, and `مخزن شامل` standard-transfer receive action;
- logout/re-login, active-role gate, Arabic job-title aliases, and main-vs-scoped-branch gates.

The test substitutes synthetic authentication/RPC responses and synthetic browser rows. It did **not** create a Production inventory count, receiving transaction, stock movement, voucher, supplier ledger entry, journal, treasury or cash entry. The successful count value is browser-mock state only, not a saved SMART ERP count.

## 3. SMART ERP — final read-only snapshot

Project: `fiilmooggumokxanwiyx`.

| Dataset | Read-only result |
|---|---:|
| `stock_vouchers` | 0 |
| `stock_voucher_details` | 0 |
| `stock_voucher_operations` | 32 |
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `inventory_stock_requests` | 0 |
| `inventory_counts` | 0 |
| `inventory_count_details` | 0 |
| `receiving` | 1 |
| `receiving_details` | 2 |
| `treasury` | 4 |
| `cash_box` | 9 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |
| `buyer_goods_custody_events` | 0 |

Stock totals remain `qty=142`, `allocated_qty=0`, `available_qty=142`.

The one existing `receiving` row is a real earlier business record, not a QA fixture: PO `PO-20260928`, created 2026-11-09, completed with two lines. It was not opened, altered, or used as a test fixture.

No business data changed in this continuation. No active user, role, branch, stock balance, supplier balance, GL balance, treasury or cash balance was changed.

## 4. Transfer receiver fallback remains correct

The live migration history still contains:
- `20261110212138` — designated branch receiver baseline;
- `20261110213226` — unified warehouse receiver fallback.

The enabled trigger `trg_transfer_responsibility_contract` calls `enforce_transfer_responsibility_contract`. The live function contains the fallback candidate-selection logic. Git files `20261110213226_standard_transfer_unified_warehouse_receiver_fallback.sql` and the later timestamped `20261110222000_standard_transfer_requires_designated_branch_receiver.sql` are now byte-identical (blob `1d5c878ccb6c47256b74c9b029294313c6de5ce0`); the Workflow asserts this equality so a future source push cannot silently replace the fallback with the older narrow definition.

The active Production user using `مخزن شامل` is:
- primary role `أمين مخزن`, active warehouse role `مخزن شامل`;
- direct `warehouse` permission;
- `allowed_branch_ids=["BR-01"]`, no default branch;
- company main branch is `BR-01`;
- `app_private.user_can_access_warehouse_branch(..., main_branch_id)` returns true.

The two dedicated `أذونات` receivers at BR-01 and BR-2 remain first priority. The full-role fallback only applies when no eligible dedicated receiver exists, with the unique-branch scope requirement. No receiver assignment was changed.

## 5. Backend role parity — remaining exact gaps

The live Edge Function versions were read from Supabase Production. The shared helper `supabase/functions/_shared/warehouse-auth.ts` already supports:
- authenticated user/company/status checks;
- direct, role, and detailed warehouse permissions;
- `requireWarehouseRole` accepting either the requested warehouse role or `مخزن شامل`;
- `assertWarehouseMainBranch` enforcing the employee's actual main-branch access.

The following start/complete paths already use this helper and accept the unified role:
- `start-picking` v36;
- `complete-picking` v19;
- `start-return` v6;
- `complete-return` v28;
- current `receive-purchase` v18;
- current loading cancel/reopen wrappers use the warehouse-role/main-branch guard.

Three older cancellation/reopen wrappers do not yet align:
- `cancel-picking` v5: exact `تحضير` role only; no shared main-branch guard.
- `reopen-picking` v9: exact `تحضير` role only; no shared main-branch guard.
- `cancel-return` v4: exact `مرتجعات` role only; no shared main-branch guard.

The matching Edge source files for these three functions are absent from the current Git tree, even though the deployed functions are ACTIVE. Their deployed source must first be restored verbatim to source control before a reviewed deployment. The current UI calls these routes from `picker.html` and `returns.html`, so this is a real cross-app parity gap, not a hypothetical unused route.

### Exact proposed role-alignment ChangeSet (NOT DEPLOYED)

**A. `cancel-picking` v5 and `reopen-picking` v9**

Add the existing shared helper import:

```ts
import { requireWarehouseRole, assertWarehouseMainBranch } from "../_shared/warehouse-auth.ts";
```

Immediately after confirming the Authorization header:

```ts
const whActor = await requireWarehouseRole(supabase, authHeader, "تحضير");
await assertWarehouseMainBranch(supabase, whActor);
```

Replace only the exact-role rejection:

```ts
if (!verifiedOwner && pubUser.active_warehouse_role !== "تحضير") {
```

with:

```ts
if (!verifiedOwner && !["تحضير", "مخزن شامل"].includes(String(pubUser.active_warehouse_role || ""))) {
```

The shared helper adds the missing main-branch authorization and the full-role acceptance. The existing permission, active-user, owner verification, company, assigned-picker and status checks remain. The SQL RPCs are unchanged:
- `cancel_runsheet_picking` requires the same company, authenticated user identity, `Picking` state and exact assigned `picker_id`; it resets picked quantities and releases reservations through the existing reservation function.
- `reopen_runsheet_picking` requires the same company, authenticated user identity, `Picked` state and exact assigned `picker_id`; it releases reservation through the existing helper before returning the runsheet to `Picking`.

**B. `cancel-return` v4**

Add the same helper import, and after checking the Authorization header:

```ts
const whActor = await requireWarehouseRole(supabase, authHeader, "مرتجعات");
await assertWarehouseMainBranch(supabase, whActor);
```

Replace only:

```ts
if (!verifiedOwner && appUser.active_warehouse_role !== "مرتجعات") {
```

with:

```ts
if (!verifiedOwner && !["مرتجعات", "مخزن شامل"].includes(String(appUser.active_warehouse_role || ""))) {
```

Preserve every existing guard:
- same company and active authenticated user;
- runsheet status exactly `Returning`;
- `return_handler_id` equals the authenticated application user;
- `return_end IS NULL`;
- update compare-and-set still filters by runsheet ID, company, `Returning`, assigned handler, and null `return_end`.

This cancel operation only resets the unfinished return session to `Delivered` and clears its handler/start marker. It does not alter stock, inventory log, customer credit, supplier, cash or GL.

### Required acceptance tests for this ChangeSet

Before deployment, run static tests and mocked Edge tests for:
1. eligible full-role user assigned to a runsheet at BR-01 succeeds;
2. a user outside BR-01 is rejected by `assertWarehouseMainBranch`;
3. wrong company, inactive user, no warehouse permission, and non-owner wrong role are rejected;
4. another picker/return handler cannot cancel or reopen the assigned runsheet;
5. wrong status and non-null `return_end` are rejected;
6. cancel-picking releases reservations once and resets picked details under the existing RPC;
7. reopen-picking releases reservations once and preserves the existing reopen state contract;
8. cancel-return changes only the unfinished session state and leaves all stock/financial datasets unchanged.

Rollback source must be the exact pre-change deployed Edge versions captured before deployment; do not invent a replacement or change the SQL RPC signature. A rollback must also retain the current company/assignment/status/reservation protections.

**No part of this ChangeSet was deployed.** The latest Master CTO Governance §77.2/§77.3 requires approval of this exact, shown change before production Edge deployment.

## 6. Unsafe completed-document reopen routes

Two active Edge Functions remain unsafe and are not part of the above role-alignment patch:

### `reopen-return` v1 — reachable from Returns UI

- Current `returns.html` exposes an `App.reopenReturn` action for completed (`Returned`) runsheets and calls `reopen-return`.
- The deployed Edge source checks the runsheet status and handler but queries the runsheet by code without company scope.
- It loops over returned lines and directly updates `stock_branches.qty = max(0,current_qty-qty_returned)`.
- It does not write `inventory_log`, reverse the posted customer/POS/credit-note or journal effects, or provide a complete atomic/idempotent reversal contract.
- It then changes the runsheet status to `Returning`.

**Disposition:** do not invoke. The endpoint and its UI action require a separate fail-closed containment ChangeSet or, later, a fully atomic reversal contract. No direct stock update or endpoint call was made.

### `reopen-receiving` v1 — dormant in current Receiver source

- The current `receiver.html` uses `receive-purchase` v18 and has no reference to `reopen-receiving`.
- The old ACTIVE endpoint directly decrements `stock_branches.qty` for previously received quantities and changes the PO back to `Receiving`, without a matching inventory-log or purchase/AP/GL reversal.
- Its PO lookup is not company-scoped.

**Disposition:** keep dormant and do not invoke. Containment is required before any future UI/client reconnects it.

These are production safety blockers. Disabling the endpoints or hiding their UI entry points changes operational behavior and therefore must be presented as an exact ChangeSet with rollback and receive owner approval under §77.2; no such deployment was performed.

## 7. Parent and Cloudflare release state

- The connected browser snapshot of the Parent application visibly shows `المخزن الشامل` in the shortcut area and in the warehouse navigation, along with manual voucher and count entries. The Parent integration is therefore present in the inspected UI snapshot.
- The Cloudflare dashboard tab last opened around 21:44 showed a Production deployment at commit `0bb9e3e287bd8cb67df2df911f5e588ee40fecfb`. This snapshot predates the Receiver/Warehouse UI commit `a68a206184b2d588e10793a8146229eb35baddc9`.
- At that older snapshot, `vouchers.html` matched current main, while `warehouse.html` and `receiver.html` did not. Their current main blobs include the Receiver success-return-to-list fix.
- The Cloudflare tab was not refreshed in Chat mode; therefore this is only the **last observed** deployment, not a claim about the current latest Production deployment. Current Cloudflare SHA and served-byte parity remain UNVERIFIED.

## 8. Execution and mutation ledger

- Warehouse E2E run `42909714464` on HEAD `9a6ac1f` succeeded.
- SMART ERP was read-only in this continuation. The last migration already applied is `20261110213226`; no new migration or DDL was executed.
- No Edge Function was deployed or modified.
- No app HTML, Parent, Core, user, role, branch or operational DB row was modified in this continuation.
- The one completed `receiving` business row and its two details were left unchanged.
- No stock, reservations, receiving, voucher, supplier, treasury, cash, GL, inventory count or buyer custody record was created as a test.

## 9. Release decision

**CONFIRMED**
- Main voucher feature parity between standalone and embedded sources.
- Latest Warehouse browser E2E and static checks pass on HEAD 9a6.
- Receiver return-to-pending fix, PO partial receipt and QMP full-rejection mocked tests pass.
- All seven native modules mount under shared auth/client; no iframe or duplicate stock engine.
- Unified-role transfer receiver fallback is applied and source-consistent.
- Full-role employee has active main-branch scope BR-01.
- Production business data and stock totals remain unchanged.

**OPEN / NOT CLOSED**
1. Restore the three deployed cancellation Edge sources to Git and apply the exact role + main-branch guard ChangeSet after owner approval.
2. Contain the reachable unsafe `reopen-return` route and dormant unsafe `reopen-receiving` route; design full reversals separately.
3. Refresh Cloudflare dashboard and verify deployment SHA/served asset parity with current main.
4. Run authenticated employee read-only E2E in the deployed browser session.
5. Do not run real stock/financial posting E2E until an isolated reversible fixture and cleanup proof exist.

**Final status:** `UNIFIED WAREHOUSE SOURCE PARITY + LATEST MOCKED E2E PASS + SMART ERP BUSINESS DATA UNCHANGED / EDGE ROLE ALIGNMENT AWAITING EXACT CHANGE APPROVAL / UNSAFE REOPEN CONTAINMENT OPEN / CLOUDFLARE CURRENT DEPLOYMENT UNVERIFIED / NOT GOLD-DIAMOND CLOSED`.

## 10. Exact next action

The only production code changes ready for review are the three Edge guards in §5, plus the separate fail-closed containment decisions in §6. They must not be conflated:
- first preserve the deployed source versions;
- apply only the reviewed role/main-branch guard patch to the three cancel/reopen wrappers;
- do not modify the SQL posting/reservation/financial RPCs;
- keep completed-document reopen blocked until a complete atomic reversal contract exists;
- refresh Cloudflare and run the authenticated read-only check;
- only then assess the separate reversible-writer test.

**Previous checkpoint:** LVE-2026-11-10-700.
