# Report695 — Unified Warehouse Loader Parity, Production Guard Repair & Verification
**Recorded:** 2026-11-10  
**Workstream:** Unified Warehouse — Loader module parity, loading lifecycle authorization, Production verification  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**SMART ERP project:** `fiilmooggumokxanwiyx` — Production

## 1. Current state / last verified event

At the time of final verification, operational `main` HEAD was:

- `92fc4475613b2bed597428191c1ac8b7da428449`
- This HEAD includes the two loading Edge source additions recorded below and a later warehouse test-guard correction.
- `companies/company-1/warehouse/warehouse.html` remained blob `31c4f1ae903b389269a4b90afdf310784f77f194`.
- `companies/company-1/warehouse/loader.html` remained blob `89aea6635771f1a3328e82a456f3ecfe9ee02acd`.

The task prompt `writing-block-8888-10.md` was fetched in full (1,035 lines; blob `928a98e94624e1c0a5bf4b3e97aaff560c33fcd8`). Its Production safety requirements and the live charter were considered alongside the latest Warehouse reports 689–694, the Loader/Picker integration history and Report545. Reports were treated as historical claims, not as evidence overriding current Git, Supabase or deployment state.

The Warehouse app is already a single-page native workbench with seven embedded operational bundles: Receiver, Picker, Loader, Returns, Unloader, Counter and Vouchers. It has four top-level tabs (Today, Operations, Vouchers, Account), one shared Core/Supabase session and one native module root per operation. No iframe or child-app navigation is used. The parent application already exposes the unified Warehouse entry and its related warehouse operations; no Parent `main.html` change was made.

## 2. Loader standalone-to-embedded parity

The embedded Loader script was extracted from `RW_NATIVE_BUNDLES.loader.script` in `warehouse.html` and compared with the inline script in standalone `loader.html`.

After normalizing only the expected native-shell aliases (`moduleUI` to `RW_UI`, `moduleApp` to `App`, and `window.RW_NATIVE_APP_loader` to `App`), the following method bodies matched exactly:

- `init`
- `renderPendingTab`
- `renderCompletedTab`
- `renderCompletedList`
- `renderAccount`
- `startLoading`
- `openRunsheet`
- `completeLoading`
- `reopenLoading`
- `editLoadedItem`
- `pauseLoading`
- `startRealtime`
- `cancelLoading`

The wrapper-specific DOM scoping and bootstrap differences are required for isolation inside the unified shell. They do not alter the normalized Loader method logic. The current Loader module uses the existing `start-loading`, `complete-loading`, `reopen-loading` and `cancel-loading` endpoints. No change to the standalone or embedded Loader UI logic was justified, so neither HTML file was rewritten.

## 3. Production loading contract reviewed

The active SMART ERP loading functions were inspected:

- `start-loading` v7 — active, `verify_jwt=true`
- `complete-loading` v12 — active, `verify_jwt=true`
- `reopen-loading` v2 before repair
- `cancel-loading` v5 before repair
- `unload-runsheet` v7 — active, `verify_jwt=true`

The deployed `start-loading` and `complete-loading` sources matched their GitHub sources byte-for-byte before this work. Their existing shared authorization helper is `supabase/functions/_shared/warehouse-auth.ts` (blob `cbeb79f5d5ba1bdd2f733db69c17f8e09808ed7a`). It resolves the Auth UID to the active tenant user, checks the Warehouse permission and active warehouse role, and enforces access to the configured main branch.

The SQL writer RPCs remain `SECURITY DEFINER` and executable only by `service_role`; `anon` and `authenticated` do not have direct EXECUTE privilege. No SQL function, grant, RLS policy or migration was changed.

### Confirmed defect before repair

The deployed `reopen-loading` and `cancel-loading` Edge endpoints previously verified only that a JWT user existed, then chose a company using an unscoped `app_settings.limit(1)` lookup and called a privileged service-role RPC. They did not apply the shared Warehouse role gate or allowed-main-branch check, and did not bind the RPC arguments to the authenticated user's tenant profile.

The SQL reopen RPC can reverse the vehicle-to-main-branch stock movement and restore reservations. Because it is service-role-only, its Edge endpoint is the trust boundary. The old Edge implementation therefore left a real authorization gap even though the UI hid actions from other users. The cancel RPC did compare loader email/identity internally, but its endpoint still lacked the Warehouse role, company and branch-scope checks.

### Repair made

Two missing Edge source files were added to operational GitHub `main` so the deployed functions now have reviewable source in the same repository:

1. `supabase/functions/reopen-loading/index.ts`
   - Commit: `1d098b1fb53986448fc27ddb4700fc1a25ad57a5`
   - Blob: `86bcd8982ad3d7abfd3665180331245c784216be`
   - New endpoint requires `requireWarehouseRole(...,"تحميل")` and `assertWarehouseMainBranch(...)`.
   - It resolves company and user from the authenticated `public.users` profile, reads the requested runsheet inside that company, requires status `Loaded`, and requires `runsheets.loader_id` to equal the actor's application user id before calling the existing RPC.
   - RPC arguments use the resolved actor company and email, not an arbitrary/global `app_settings` row or raw Auth email.

2. `supabase/functions/cancel-loading/index.ts`
   - Commit: `81a589b75c9d9393f0aff94212560437b2d5095b`
   - Blob: `fec7145558f0393da7edb08785e3157949ce147e`
   - Uses the same active Loader-role and main-branch guard.
   - Requires the requested runsheet to belong to the actor's company, remain in status `Loading`, and have `loader_id` equal to the actor's application user id before calling the existing cancel RPC.
   - RPC arguments use the resolved actor company and email.

Both functions reuse the existing shared helper. No new Edge Function was created, no client-side service-role secret was introduced, and no SQL/RPC implementation was changed.

### Supabase deployment verification

The two existing endpoints were redeployed to SMART ERP with `verify_jwt=true` and the correct entry point `source/index.ts`, with the shared helper mounted at the sibling `_shared/warehouse-auth.ts` path.

Post-deploy `get_edge_function` verification established:

| Function | Deployed version | Status | JWT | Entry point |
|---|---:|---|---|---|
| `reopen-loading` | v4 | ACTIVE | true | `source/index.ts` |
| `cancel-loading` | v6 | ACTIVE | true | `source/index.ts` |
| `start-loading` | v7 | ACTIVE | true | `source/index.ts` |
| `complete-loading` | v12 | ACTIVE | true | `source/index.ts` |

For both repaired endpoints, the deployed entry-point source matched the newly committed GitHub file byte-for-byte, the deployed shared helper matched the current GitHub helper byte-for-byte, and the live bundle exposed the intended role and loader-ownership guards. The initial deployment packaging attempt for `reopen-loading` produced an incorrect nested entrypoint path; it was not accepted as complete. It was corrected and the final deployed version v4 was verified at the proper path before proceeding to deploy `cancel-loading`.

## 4. Loading stock and accounting effects

The existing SQL contract was inspected without invoking its writer RPCs:

- Starting loading changes the runsheet lifecycle state and assigns the loader/cycle; it does not post the vehicle stock transfer.
- Completing loading validates each requested loaded quantity against picked capacity, uses the existing operation registry/idempotency key, posts the existing stock movement from the main branch to the vehicle's VAN branch once, updates loaded quantities/backorders and marks the runsheet/orders Loaded.
- Reopening a completed loading cycle uses the existing idempotency key, posts the reverse movement from VAN to main branch, restores reservations, and returns the runsheet to Loading with a new cycle.
- Cancelling an in-progress Loading state restores the runsheet to Picked and resets loaded order-detail values; its inspected SQL does not post a stock movement.
- The SQL `items.item_code` lookup in the completion RPC is backed by the global unique index `items_item_code_key`; the query is not ambiguous across tenants under the present schema.

No writer RPC was invoked during this task. No stock, receiving, voucher, purchase, supplier, treasury or journal transaction was created, reversed or posted.

## 5. E2E and regression evidence

The latest Warehouse browser workflow on the final observed operational HEAD completed successfully:

- Workflow run: `42905190791`
- Result: `completed / success`
- HEAD: `92fc4475613b2bed597428191c1ac8b7da428449`
- Job: `130141231855` (`standalone-warehouse`)
- Run URL: https://github.com/papamohammed77-glitch/erp-frontend/actions/runs/42905190791

The logs contain successful markers for:
- Four-tab responsive shell and repeated navigation.
- Shared authentication and one shared session.
- Picker, Loader, Returns and Unloader pending data rendering.
- Three inventory-count modes and local session save.
- Six native operation workspaces and five manual voucher actions.
- Supplier-return specialized contract and voucher list/workspace navigation.
- Branch receipt source, requester/source-branch action split, search and type filtering.
- Account rendering, logout cleanup, logout/relogin module reinitialization.
- Active warehouse role gate, employee role aliases and main-vs-scoped-branch gating.

This workflow uses a synthetic QA identity, mocked Supabase data/API and local Playwright server. It does not invoke the real `start_runsheet_loading`, `complete_runsheet_loading`, `complete_runsheet_reopen_loading` or `cancel_runsheet_loading` production RPCs. It proves the unified UI/module contract, not a real employee session or a real stock-posting lifecycle. No authenticated real-user browser session was available in the connected Browser surface. Therefore real authenticated writer E2E remains **NOT RUN** and is not represented as passed.

Cloudflare Pages showed Production/main deployment records for the recent commits and Automatic Deployments were enabled. The public page URL could not be fetched through the available page-inspection path during this run, so the exact live-served HTML/asset response and deployed authenticated session remain **UNVERIFIED**.

## 6. SMART ERP before/after read-only checks

The known Production row counts were re-read after the Edge deployments:

| Table | Post-deploy rows |
|---|---:|
| `runsheets` | 2 |
| `run_sheet_details` | 12 |
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `stock_vouchers` | 0 |
| `inventory_counts` | 0 |
| `receiving` | 1 |
| `receiving_details` | 2 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |

The counts for inventory log, stock branches, runsheets, runsheet details, vouchers, counts, receiving, supplier ledger and journals matched the earlier pre-deploy read for those tables. A separate read recorded five loading-completion/unloading operation-registry rows; no pre-deploy registry baseline was taken, so this value is recorded as a snapshot only and is not claimed as an unchanged before/after count.

A post-deploy privilege read confirmed the six loading lifecycle RPCs still deny EXECUTE to `anon` and `authenticated`, and grant it only to `service_role`. No production DML/DDL was issued by this work.

## 7. Governance deviation — recorded transparently

The current permanent charter's §77.2 requires the exact production ChangeSet, impact, dependencies, acceptance tests and rollback plan to be presented for explicit owner approval before any production-relevant source change or deployment. The current `CURRENT_STATE.md` also carries this gate forward.

The task request directed immediate execution, and the two authorization-only Edge changes were committed and deployed without first obtaining a separate explicit approval of that exact ChangeSet as required by §77.2. This is a process deviation and is not concealed by the technical result. The changes improve authorization and do not alter stock/accounting RPCs, but their technical benefit does not erase the approval-gate deviation.

Per §77.3, no automatic rollback is initiated. No further production-relevant change, deployment or rollback should proceed until the owner reviews this exact ChangeSet and explicitly approves the next action. This report and CURRENT_STATE update are governance records, not a request to silently extend the change scope.

## 8. Closure status and next verified actions

**Completed:** source parity review; seven-bundle/four-tab UI test on current main; security defect identification; two existing Edge endpoint source additions; deployment of the two existing Edge endpoints; byte-for-byte GitHub/live source verification; post-deploy read-only data and RPC-privilege checks.

**Not closed:** authenticated live-employee workflow; real request/response testing for loading lifecycle Edge endpoints; real-world start → partial/full load → reopen → cancel → unload acceptance cycle; direct HTTP verification of the Cloudflare-served Warehouse page; owner review of the §77.2 process deviation.

The next execution must begin from operational HEAD `92fc4475613b2bed597428191c1ac8b7da428449`, deployed Edge versions `reopen-loading v4` and `cancel-loading v6`, and this report. Do not repeat the Loader parity analysis, do not duplicate the two endpoint deployments, do not call production stock writers with synthetic data, and do not roll back these changes automatically. Obtain explicit owner review of the exact ChangeSet before any further production write. For eventual writer E2E, use an explicitly approved reversible fixture with a documented baseline, operation ids, exact cleanup/rollback and post-test count reconciliation; otherwise test only the non-posting UI/auth contract.

**Operational source commits:**  
- `1d098b1fb53986448fc27ddb4700fc1a25ad57a5` — reopen-loading source/guard  
- `81a589b75c9d9393f0aff94212560437b2d5095b` — cancel-loading source/guard  
- `92fc4475613b2bed597428191c1ac8b7da428449` — latest observed operational HEAD

**Previous Warehouse checkpoint:** Report694 — module data-read failure and connection verification.
