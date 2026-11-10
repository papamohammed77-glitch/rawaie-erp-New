# Report702 — استكمال عمل المساعدين، مطابقة Edge المنشورة، وفجوات المرتجعات وCI

**Recorded:** 2026-11-11 (Africa/Cairo)  
**Workstream:** Unified Warehouse / Returns / Picker authorization / legacy reopen containment / collaborative source reconciliation  
**Disposition:** `EDGE AUTH GUARDS DEPLOYED + LIVE SOURCE BYTE PARITY VERIFIED + UNSAFE REOPEN ROUTES FAIL-CLOSED + PRODUCTION BUSINESS DATA UNCHANGED / CURRENT-HEAD WAREHOUSE E2E BLOCKED BY STALE STATIC ASSERTION / PAGES HEAD PARITY OPEN.

## 1. نقطة الاستئناف ومصدر الحقيقة

استُكملت المتابعة من LVE-701 دون إعادة بناء التطبيق أو إعادة تنفيذ تغييرات المساعدين. تمت مراجعة أحدث commits على `papamohammed77-glitch/erp-frontend`، ثم إعادة قراءة النسخ الحية من Supabase بدل افتراض أن وجود الملف في Git يعني نشره.

- Operational repository: `papamohammed77-glitch/erp-frontend` / `main`
- Verified operational HEAD: `11c6a033cdb883daaf50fc9dab3458a64ffc6a5c`
- `warehouse.html` blob: `45840aef5403d86da9f2d41ce6d88a24d4b83b9f`
- `returns.html` blob: `2d725fede124a19c4cb4587eb97040ca2e2a1869`
- Warehouse E2E workflow blob: `46e7c8f8e7e7ac452323ad7ee62bbfb72d8317db`
- Governance repository HEAD at report creation: `2e16ebba7cdcc792665876a22ff91dbd7b73a54a`
- Previous checkpoint: LVE-2026-11-10-701.

Parallel contributors advanced the operational branch through the following material changes; these are recorded as collaborative work, not attributed to this continuation:

| Commit | Change | Verified effect |
|---|---|---|
| `ce3097f1f6747f22e98ba3f05d8b72acd874ac83` | Returns device-local drafts + discrepancy validation | Removes direct draft writes to `run_sheet_details`; persists drafts in Dexie; validates actual quantity and discrepancy types |
| `e9f94044aa9781a98c38db7bd6df963815474e5d` | Align Returns drafts/discrepancy workflow | Latest Returns application source synchronized with intended embedded behavior |
| `6a6a41cab684643727f6e1f4ca41fc7be145fc66` | Picker cancellation guard | Shared role and main-branch assertions; accepts `مخزن شامل` |
| `a006e02b4628245fbae4dc5d8f83738a1e75ef4e` | Picker reopen guard | Shared role and main-branch assertions; accepts `مخزن شامل` |
| `8844fabe8c56487c3e4a62f979d44985f5478993` | Returns cancellation guard | Adds shared role and main-branch assertions |
| `ad761a54dbee1859631d6ba94c07996d3bb223c4` | Legacy purchase receiving reopen containment | Replaces raw stock decrement endpoint source with HTTP 409 fail-closed response |
| `68f1e7b1ab6a805b612124d100dbc08af61f8bef` / `11c6a033cdb883daaf50fc9dab3458a64ffc6a5c` | Completed-return warning-only | Removes the residual navigation/reload action and keeps both standalone/native action warning-only |
| `d35b3b37cc1321fe8ddd44ffc5a8923ed29787d6`, `3a1df3c6b59194ef5a608d889f85192478e3a0d9`, `892f6a41d71d7e7240d040f3aaf4d37f132d2d05`, `fcf91d97a58f52a7b2f21d1acf880d86d65823e2`, `238b525348dee4dcd50a29236c7571412aacf76d` | Restore deployed Edge sources into Git | Eliminates previously identified source-control drift |

## 2. Confirmed live Supabase Edge deployment and Git parity

Project: SMART ERP `fiilmooggumokxanwiyx`, status ACTIVE_HEALTHY. Live function retrieval was repeated after the collaborators' pushes. The exact `index.ts` source content for every function below was compared with its current Git file and matched byte-for-byte. All retain `verify_jwt=true`.

| Function | Live version | Live source SHA-256 | Git blob | Byte parity |
|---|---:|---|---|---|
| `cancel-picking` | v6 ACTIVE | `16f6ff876d1088291f42ffcae556bc0188cf4147a5b2926e0be42e3d316ba73f` | `d425ce8d19babc2c96591386993bec54b499a61f` | PASS |
| `reopen-picking` | v10 ACTIVE | `e2a2dc559db3c960115ec0fc8da322aef6b8360577421cddbd519d86bd6766c2` | `a19a118095e81ea57f312717a658f31b28a15a6b` | PASS |
| `cancel-return` | v6 ACTIVE | `0be035e1c091ef44c841236c5cb8535fb689cb4de3b3804f1b126070e4ae6ff6` | `a0e6a5e48c615815c6e946e6bcd724504699e452` | PASS |
| `reopen-return` | v2 ACTIVE | `9fc2789586bd216a48bc0b333b15c9c89917fdb2a528738ed01aac395d2372a7` | `16129e14be65ce4320b380a6ec6ee7e467d94650` | PASS |
| `reopen-receiving` | v2 ACTIVE | `9792f5de99a07d0cfe1e51cfeaa9a376206a90b4782a2b39bcaedc2bf5a64620` | `45796345e1725abda8dc7eabbe998733ac6eb415` | PASS |

### 2.1 Picker cancel/reopen

Both endpoints now import `requireWarehouseRole` and `assertWarehouseMainBranch`, call them before reaching their privileged service-role RPC, and accept active roles `تحضير` or `مخزن شامل`. Existing checks for authentication, warehouse permission, active user, same company and original picker identity are retained. Existing SQL RPCs and grants were not changed:
- `cancel_runsheet_picking` remains SECURITY DEFINER and executable by service_role only; authenticated/anon EXECUTE remain false.
- `reopen_runsheet_picking` remains SECURITY DEFINER and executable by service_role only; authenticated/anon EXECUTE remain false.
- RPC transaction semantics for reservation release/reset and state transition remain unchanged.

### 2.2 Returns cancellation

`cancel-return v6` now uses the shared role/main-branch guard and accepts `مرتجعات` or `مخزن شامل`. The live source preserves:
- company-scoped runsheet lookup;
- status `Returning`;
- `return_handler_id` equals current app user;
- `return_end IS NULL`;
- conditional update rechecking the same company/state/handler and null end time.

The cancellation route does not post stock or financial transactions. Completed/reopened returns remain blocked by the existing `return_end` guard.

### 2.3 Unsafe reopen endpoints

- `reopen-return v2` returns HTTP 409 `REOPEN_RETURN_TEMPORARILY_DISABLED`, has no Supabase client, and performs no database operation. This blocks the previous unsafe raw `stock_branches.qty` decrement that did not create an `inventory_log` movement or reverse journal/customer/POS/driver-liability/credit-note effects.
- `reopen-receiving v2` returns HTTP 409 `PURCHASE_RECEIVING_REOPEN_SUSPENDED` after method/auth-header checks. It has no Supabase client or database calls. This blocks the legacy v1 raw stock decrement without purchase/AP/GL/inventory reversal. The current Receiver application continues to use `receive-purchase v18`; no caller to `reopen-receiving` was found in current operational Git search.

**Important:** suspension is containment, not feature completion. A complete atomic reversal contract is still required before either reopen capability can be re-enabled.

## 3. Returns UI and draft persistence review

### Confirmed changes

- The standalone Returns app now clearly labels the active return as a device-local draft until `تأكيد وإنهاء المرتجعات` succeeds.
- `saveReturnItem` writes only to Dexie `localChanges`; it no longer writes draft quantities into `run_sheet_details`.
- `openReturn` calls `_loadLocalChanges` after building the active in-memory session, so saved local drafts are reapplied when the same active session is reopened on that device.
- `completeReturn` constructs the final item payload from the in-memory session and sends it to the existing `complete-return v28` endpoint. On confirmed success, local draft records are deleted. No draft-only inventory/accounting posting was introduced.
- Completed-return reopen action is disabled and warning-only in standalone and embedded Returns. The embedded Returns bundle in `warehouse.html` has matching `saveReturnItem`, `completeReturn`, `cancelReturn`, and `reopenReturn` business methods. Differences found in `loadRunsheets`/completed rendering are expected host-wrapper aliases and integration adapters, not separate posting implementations.

### Remaining local-draft correctness issue

Dexie schema is `localChanges: '++id,runsheet_code,item_code'`. The current `saveReturnItem` uses `put(draft)` without a stable primary key, so repeated edits create multiple rows for the same runsheet/item. Recovery loops through them and applies values using truthy fallbacks such as:
- `ch.qty_returned || existing.qty_returned`
- `ch.notes || existing.notes`

This means an intentional zero quantity or cleared note cannot override an earlier non-zero/non-empty local value when the session is restored. It can resurrect an older draft value. The current design does not corrupt database stock by itself, but it can submit a stale quantity at final completion.

**Required exact follow-up:** preserve zero/empty values using null checks and serialize replacement of the previous local record per `(runsheet_code,item_code)` in a Dexie transaction (or perform a reviewed IndexedDB version migration to a unique compound key). Add reload/reopen tests that edit quantity to a positive value, then zero, clear notes, reload, reopen and assert the final payload matches the latest edits. Do not touch `run_sheet_details` until the final atomic `complete-return` operation.

## 4. Discrepancy reporting: confirmed RLS and new server authorization gap

The production schema for `stock_discrepancies` has RLS enabled and two policies:
- Read allows an active same-company user who is the reporter, supervisor/owner, or the assigned return handler for the associated runsheet.
- Update is limited to active same-company supervisor/owner users.

Therefore, an assigned return handler can read a pending discrepancy on their runsheet through the client-side `completeReturn` check. The RLS read policy is present; the previous concern that the check necessarily returned an empty set due to missing SELECT policy is **not confirmed**.

However, live `report-discrepancy v3` remains a security and tenant-scope gap:
1. It resolves the application user by email only; it does not bind the lookup to `auth_id`, company or Active status.
2. It loads a runsheet by `id` only and checks only `status='Returning'`; it does not require `company_id` equal to the authenticated employee's company, nor `return_handler_id` equal to the reporting employee.
3. It checks that the item exists on the runsheet, but it does not verify the caller is an authorized `مرتجعات`/`مخزن شامل` user or the assigned handler.
4. It inserts `company_id='00000000-0000-0000-0000-000000000001'` as a literal. This currently equals the **only** row in `public.companies` (company `الروائع`), so there is no current company-ID mismatch in the observed single-company production schema. It is nevertheless not a safe multi-tenant contract.
5. The updated client payload currently omits `item_name` and `expected_item_name`, so the function can store the item code as the display name rather than the actual catalog name.

**Risk:** an authenticated user mapped to an employee can attempt to create a pending discrepancy against another `Returning` runsheet if its UUID is known. The insert is service-role and bypasses the table's RLS insert policy. A fabricated pending row can block the assigned handler's completion gate. This route does not directly post stock or GL, but it can tamper with the operational exception queue.

**Proposed follow-up ChangeSet `CS-WH-702-E` (not applied):**
- Resolve the actor from the authenticated JWT using the shared warehouse-auth helper; require `مرتجعات` (which permits `مخزن شامل`) and main-branch scope.
- Require active `users.auth_id=auth.uid()` and derive `company_id` from that actor.
- Fetch the runsheet by both ID and company, requiring `Returning` and `return_handler_id=actor.appUser.id`.
- Fetch the item detail in that same runsheet; derive authoritative expected quantity from `qty_loaded-qty_delivered` rather than trusting caller-supplied expected quantity.
- Validate actual quantity as finite/nonnegative; enforce discrepancy-type semantics; validate both item codes against the current company; write the derived company ID, reporter ID and item names.
- Keep the current table and audit contract unless schema review proves otherwise; do not add stock/financial side effects.
- Add API tests for wrong role, inactive actor, wrong company, non-assigned handler, wrong item, invalid numeric values and authorized assigned-handler success.

## 5. Current Warehouse CI blocker

Latest operational Warehouse E2E:
- Run: `42914279861`
- HEAD: `11c6a033cdb883daaf50fc9dab3458a64ffc6a5c`
- Job: `130172531365` / `standalone-warehouse`
- Result: FAILED at **Static source and module contract**. Playwright and browser E2E steps were skipped.

Exact failure:
`RETURNS_WORKFLOW_MISSING:reopen-return`

The workflow's static feature list still requires the string `reopen-return` in the embedded Returns business script. The product change deliberately removes the active Edge call and makes the method warning-only, so this test expectation is obsolete. This is a test-contract defect, not evidence that Returns module initialization failed.

**Exact test-only correction (not applied):**
- Remove `reopen-return` from the list of required live workflow operations.
- Replace it with positive assertions that the embedded script contains the suspended-reopen warning and that the completed-return card renders a disabled `aria-disabled="true"` action.
- Assert the embedded script does **not** contain `RW_API.call('reopen-return'`.
- Keep the browser test that checks both standalone/native disabled button behavior.
- Rerun all four static/browser/role/branch suites on latest HEAD; do not report E2E PASS until Playwright actually completes.

Last full Warehouse Playwright pass available in the reviewed run history is `42912967193` on HEAD `765dee0a6fb109f5eb75d76547d0f0892d9d3c17`; it predates the latest draft/discrepancy and wrapper changes. The current HEAD has **no passing full Warehouse E2E**.

## 6. Cloudflare Pages production pointer

Cloudflare dashboard was read-only inspected. Automatic deployments are enabled. The latest Production deployment visible in the dashboard snapshot is commit:
- `83c0f395c34a5562752bc715a64361e675e2b20d`
- Preview/deployment URL shown: `https://e0ea2007.rawaea-erp.pages.dev/`

Subsequent commits include Returns draft/discrepancy updates and the latest embedded warning-only change through `11c6a033`. The dashboard also showed later deployment jobs queued; it did not show Production at `11c6a033`. Thus **Pages Production parity with current HEAD is NOT VERIFIED**. The production snapshot at 83c0 includes the earlier completed-return reopen disablement from commits 765dee0/7250560, so the user-facing dangerous action is already disabled in the last verified Pages artifact. The newest draft/discrepancy quality updates are not yet proven live.

## 7. SMART ERP production data safety

Read-only production baseline refreshed during this review:

| Table | Rows |
|---|---:|
| `receiving` | 1 |
| `receiving_details` | 2 |
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `stock_vouchers` | 0 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |
| `buyer_goods_custody_events` | 0 |

The only company row is `الروائع` with ID `00000000-0000-0000-0000-000000000001`. These counts match the prior baseline. This continuation performed only source reads, Edge retrieval, SELECT queries and dashboard inspection; it did not create a fixture or call any stock/finance writer. No receiving, voucher, inventory movement, reservation, supplier ledger, journal, cash/treasury, custody or return-completion business row was created by this review.

## 8. Deployment, governance and change-control status

- **CONFIRMED DEPLOYED:** Picker cancel/reopen guards (v6/v10); Returns cancel guard (v6); completed-return reopen fail-closed (v2); legacy receiving reopen fail-closed (v2).
- **CONFIRMED SOURCE PARITY:** all five live Edge `index.ts` sources match their exact tracked Git file byte-for-byte.
- **CONFIRMED APP SOURCE:** latest Git contains standalone + embedded completed-return disablement and local draft/discrepancy improvements.
- **UNVERIFIED Pages:** latest Production pointer is behind current operational HEAD.
- **FAILED CURRENT CI:** static test contract still requires the removed reopen-return call; no Playwright run at current HEAD.
- **OPEN SECURITY CHANGE:** report-discrepancy v3 authorization/company/assignment scoping.
- **OPEN DATA-QUALITY CHANGE:** local draft zero/clear semantics and duplicate-row cleanup.

Master CTO Governance §§77.2–77.3 continues to apply to production source/contract/deploy changes. This report records parallel contributors' commits and the current live state; it does not infer a separate owner approval from the fact that an action appears in Git or Supabase. No further production source or database change is made by this continuation.

## 9. Next execution sequence

1. Fix the Warehouse static test expectation so it validates a suspended completed-return action rather than requiring an active `reopen-return` call; rerun full Warehouse Playwright and capture the actual run result.
2. Reconcile local draft write/recovery semantics (zero, empty notes, duplicate local records) and add reload/reopen tests.
3. Prepare and review `CS-WH-702-E` for `report-discrepancy` authorization and tenant/assignment scoping; preserve table schema and no-posting business meaning.
4. Verify Cloudflare Pages Production advances to the intended reviewed app HEAD; distinguish Pages deployment from Supabase Edge version deployment.
5. Continue authenticated read-only employee session checks. Do not create test receipts, returns, vouchers or inventory operations against production balances.
6. Keep both reopen routes suspended until complete atomic stock + AP/GL/customer/credit-note/driver-liability reversal contracts are designed and approved.

**Current operational HEAD:** `11c6a033cdb883daaf50fc9dab3458a64ffc6a5c`  
**Latest Warehouse run:** `42914279861` (Static contract failure; Playwright skipped)  
**Latest verified Pages Production commit:** `83c0f395c34a5562752bc715a64361e675e2b20d` (dashboard snapshot)  
**Previous checkpoint:** LVE-2026-11-10-701.
