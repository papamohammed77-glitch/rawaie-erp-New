# Report702 — تنفيذ حزمة الحماية الموحدة للمخزن والتحقق من الإنتاج

**Recorded:** 2026-11-11 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-11-702  
**Approved scope:** CS-WH-701-A/B/C/D approved explicitly by the owner on 2026-11-11.  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Production DB:** SMART ERP / Supabase project `fiilmooggumokxanwiyx`

## 1. Executive decision

تم تنفيذ وتطبيق الجزء الخادمي المعتمد من الحزمة، وتمت مطابقة المصادر المنشورة مع Git. أُغلقت مسارات إعادة الفتح غير الآمنة، ووُحّدت صلاحيات إلغاء/إعادة فتح التحضير وإلغاء المرتجعات مع فحص نطاق الفرع الرئيسي.

**Latest verified operational HEAD:** `98ef3dbcf493a933be752ce053f73f706e94534d`.  
**No production transaction or inventory/finance mutation was used for validation.**

The four approved work items are now in the following state:

- **A — Picker cancel/reopen:** deployed and verified as `cancel-picking v6` and `reopen-picking v10`.
- **B — Return cancellation:** deployed and verified as `cancel-return v6`.
- **C — Completed Sales Return reopen:** production Edge was already upgraded by the live system to a safe `reopen-return v2` before this task. It was preserved, not replaced. Both standalone and embedded UI now have a disabled action and warning-only method with no request to the endpoint.
- **D — Legacy purchase receiving reopen:** deployed as `reopen-receiving v2`, fail-closed, with no Supabase client/table/RPC code.

**Important remaining release gate:** Cloudflare Production asset deployment for the latest UI commits and the latest GitHub Actions Playwright run were not independently confirmed in this turn. The directly read Cloudflare dashboard snapshot showed Production at commit `83c0f395`, while the current operational HEAD is `98ef3db`. Do not claim the latest HTML is already live until the dashboard/served assets confirm the current commit. The GitHub commit combined-status queries for `475759b` and `98ef3db` returned empty status arrays, so no new post-change E2E PASS is asserted here.

## 2. Source reconciliation before edits

The main branch had advanced beyond Report701. New commits were inspected before writing; the following already-existing changes were preserved:

- `765dee0`: standalone completed-return reopen UI was disabled and its method was made warning-only.
- `7250560`: embedded Warehouse Returns reopen action was disabled.
- `83c0f39`: E2E assertion added for the completed-return disabled UI.
- `475759b`: static workflow guards were aligned to the fail-closed Returns contract.
- `98ef3db`: embedded Returns discrepancy validation source was kept byte-aligned with the standalone version.

The current deployed Edge sources were re-read from SMART ERP and synchronized into Git before editing. This exposed two version differences from Report701: `cancel-return` was already v5 (not v4), and `reopen-return` was already v2 fail-closed (not v1 unsafe). The newer/safe live sources were preserved; no old source was used to overwrite a later deployed version.

Exact synced source commits:
- `d35b3b3` — deployed `cancel-picking v5` source.
- `3a1df3c` — deployed `reopen-picking v9` source.
- `892f6a4` — deployed `cancel-return v5` source.
- `fcf91d9` — deployed `reopen-return v2` source (already fail-closed).
- `238b525` — deployed `reopen-receiving v1` source for forensic/versioned history before replacement.

## 3. CS-WH-701-A — Picker cancellation and reopen guard alignment

### Deployed state

| Function | Previous live version | Current deployed version | verify_jwt |
|---|---:|---:|---|
| `cancel-picking` | v5 | **v6** | true |
| `reopen-picking` | v9 | **v10** | true |

Both now import the existing shared helper from `../_shared/warehouse-auth.ts` and, after Authorization-header validation, execute:

```ts
const warehouseActor = await requireWarehouseRole(supabase, authHeader, "تحضير");
await assertWarehouseMainBranch(supabase, warehouseActor);
```

The prior explicit role predicate is retained and now accepts only `تحضير` or `مخزن شامل` (unless the verified owner path applies). The helper independently validates the current authenticated identity, company, active status, warehouse permission, role, and access to the configured main branch.

Unchanged:
- company/auth identity checks in the original endpoint;
- payload validation;
- `cancel_runsheet_picking` and `reopen_runsheet_picking` RPC names and argument payloads;
- all SQL RPC implementations, their status/assignment/reservation checks, and grants.

Post-deploy verification:
- Supabase returns `cancel-picking v6 ACTIVE verify_jwt=true` and `reopen-picking v10 ACTIVE verify_jwt=true`.
- The two function sources returned by Supabase match their Git files byte-for-byte.
- The uploaded `_shared/warehouse-auth.ts` dependency in each deployed function matches the tracked shared helper blob `cbeb79f5d5ba1bdd2f733db69c17f8e09808ed7a`.

## 4. CS-WH-701-B — Return cancellation

The currently deployed `cancel-return` had advanced to v5 and already accepted both `مرتجعات` and `مخزن شامل`. The applied patch preserved that wider, already-approved role predicate and added the shared helper plus main-branch check using required role `مرتجعات`.

**Current deployment:** `cancel-return v6 ACTIVE verify_jwt=true`.

Preserved unchanged:
- same-company runsheet lookup;
- same assigned `return_handler_id`;
- `Returning` status requirement;
- refusal where `return_end` is already set;
- conditional update with `status='Returning'`, matching handler and `return_end IS NULL`;
- cancellation remains non-posting and does not adjust stock, inventory log, supplier/customer balances, driver liability, cash, or GL.

The deployed source matches the Git source byte-for-byte, and its shared helper file matches the repository helper.

## 5. CS-WH-701-C — Completed Sales Return reopen

### Backend

The current Production endpoint had already moved to `reopen-return v2`, replacing the unsafe v1 raw-stock-decrement handler. It was verified as:
- `ACTIVE`, `verify_jwt=true`;
- returns HTTP 409 for POST;
- does not instantiate a Supabase client;
- contains no table query/update (`.from(`), no RPC call (`.rpc(`).

Its existing response code is `REOPEN_RETURN_TEMPORARILY_DISABLED`, which is semantically equivalent to the approved suspended/fail-closed contract. It was deliberately retained without unnecessary redeploy.

### UI — standalone and embedded parity

Both:
- `companies/company-1/warehouse/returns.html`
- `companies/company-1/warehouse/warehouse.html` (native embedded Returns bundle)

now preserve a disabled, non-interactive completed-return status control and a warning-only `reopenReturn` method:

```js
reopenReturn: function(){
  RW_UI.showError('إعادة فتح المرتجعات المكتملة متوقفة مؤقتًا لحماية المخزون والقيود المحاسبية. يلزم مسار عكس ذري معتمد قبل إتاحتها.');
},
```

The method no longer reads a runsheet, calls `RW_API.call('reopen-return', ...)`, or reloads the completed list. The completed-return list contains no active reopen button/onclick. Source inspection of both files confirms no active `reopen-return` API call remains.

The latest warehouse source commit also preserves the discrepancy validation contract parity with standalone Returns.

## 6. CS-WH-701-D — Legacy receiving reopen

The exact original Production v1 source was retained in Git for history, then replaced with a no-database fail-closed handler.

**Current deployment:** `reopen-receiving v2 ACTIVE verify_jwt=true`.

Behavior:
- `OPTIONS`: CORS preflight success.
- non-POST: HTTP 405.
- missing Authorization header: HTTP 401.
- POST with Authorization: HTTP 409 with code `PURCHASE_RECEIVING_REOPEN_SUSPENDED`.
- no Supabase client construction, table query/update, or RPC.
- JWT verification remains enabled at the Edge gateway.

The deployed v2 source hash is `9792f5de99a07d0cfe1e51cfeaa9a376206a90b4782a2b39bcaedc2bf5a64620`; Supabase read-back confirms the fail-closed code and zero DB/RPC call sites. Current Receiver continues to use `receive-purchase v18`; it was not modified.

## 7. Exact current source and deployment references

Operational HEAD: `98ef3dbcf493a933be752ce053f73f706e94534d`.

| Path / resource | Current Git blob SHA |
|---|---|
| `supabase/functions/cancel-picking/index.ts` | `d425ce8d19babc2c96591386993bec54b499a61f` |
| `supabase/functions/reopen-picking/index.ts` | `a19a118095e81ea57f312717a658f31b28a15a6b` |
| `supabase/functions/cancel-return/index.ts` | `a0e6a5e48c615815c6e946e6bcd724504699e452` |
| `supabase/functions/reopen-return/index.ts` | `16129e14be65ce4320b380a6ec6ee7e467d94650` |
| `supabase/functions/reopen-receiving/index.ts` | `45796345e1725abda8dc7eabbe998733ac6eb415` |
| `supabase/functions/_shared/warehouse-auth.ts` | `cbeb79f5d5ba1bdd2f733db69c17f8e09808ed7a` |
| standalone `returns.html` | `2d725fede124a19c4cb4587eb97040ca2e2a1869` |
| embedded `warehouse.html` | `987dbf4d24e2424e27a3e35e168ec4596007c1a7` |
| Warehouse E2E workflow | `136cc684c210c837fba44592d3990d08e7e26c10` |

All five Edge function sources read back from Supabase match their Git sources byte-for-byte. All five remain `ACTIVE` with `verify_jwt=true`. The three role-bearing endpoints also read back the deployed shared helper and pass the source guard checks. The two suspended endpoints contain no Supabase client/table/RPC access.

## 8. Post-deploy Production read-only validation

Fresh read-only counts after deployments:

| Table | Rows |
|---|---:|
| `receiving` | 1 |
| `receiving_details` | 2 |
| `inventory_log` | 78 |
| `stock_branches` | 58 |
| `stock_vouchers` | 0 |
| `stock_voucher_details` | 0 |
| `supplier_ledger` | 3 |
| `journal_entries` | 21 |
| `buyer_goods_custody_events` | 0 |

These counts exactly match Report701's pre-change baseline. Read-only ACL verification also confirms that `cancel_runsheet_picking` and `reopen_runsheet_picking` still grant EXECUTE only to `service_role`; no EXECUTE grant was added for `authenticated` or `anon`.

No migration, SQL schema change, RPC body/grant, RLS, user/role/branch, stock, reservation, receipt, return posting, voucher, supplier/customer ledger, journal, cash/Treasury, driver liability, buyer custody, or test fixture was created or changed.

## 9. Verification status and honest boundaries

**Confirmed**
- Source reconciliation against current live deployed functions.
- Successful Supabase deployment and read-back of Picker A, Returns B, and legacy receiving D.
- Already-live completed-return C backend is fail-closed and retained.
- All deployed Edge versions are ACTIVE and JWT-protected.
- Git/Production Edge source byte parity.
- UI source parity: both standalone and embedded Returns surfaces have disabled reopen action and warning-only method, with no active endpoint call.
- Production row counts and RPC ACLs unchanged.

**Not yet confirmed**
- The latest GitHub Actions Workflow/Playwright run after the final UI/workflow commits: commit status queries for `475759b` and `98ef3db` returned empty status arrays. Prior pass `42909714464` remains historical evidence on HEAD `9a6ac1f`, not a post-change pass.
- The latest Cloudflare Pages Production commit and live served asset parity: the directly read Cloudflare dashboard snapshot showed Production at `83c0f39`, older than the current UI commits and latest operational HEAD. Automatic deployment is enabled, but no fresh deployment confirmation was available from the read-only dashboard snapshot.
- Authenticated POST invocation of the 409 endpoints and authenticated role/branch runtime tests. The available Supabase integration exposes function read/deploy but no direct function-invoke action; no credentials were extracted or reused from the browser.
- No successful production transaction test was attempted by design. Supabase's deployment bundler accepted and published the Edge sources, but that is not a substitute for an authenticated role/branch integration test.

## 10. Rollback and next execution

- For A/B only, if a regression is confirmed, restore the previous exact Edge versions to revert the role/main-branch guard while leaving SQL RPC definitions and privileges unchanged.
- **Never** restore the old v1 `reopen-return` or `reopen-receiving` raw stock writers. Keep both fail-closed and repair forward.
- Do not roll back or alter stock, reservations, inventory log, supplier/customer ledgers, journals, cash or treasury to test/undo this ChangeSet.

Remaining release closure:
1. Confirm Cloudflare Production now points at the latest approved UI commit `98ef3db` and verify both served assets.
2. Confirm the GitHub Actions run generated by the final Warehouse HTML/workflow commits; require all Playwright stages to pass.
3. Run isolated mocked guard tests for role, main-branch, wrong-company, inactive-user and assignment denials; test suspended endpoint behavior with a valid JWT and zero DB/RPC operations when a supported invocation harness is available.
4. Keep authenticated Production transaction tests out of scope unless a reversible fixture and cleanup plan are separately approved.

**Closure:** `APPROVED SOURCE CHANGES COMMITTED — EDGE A/B/C/D SAFE STATE VERIFIED — PRODUCTION DATA AND RPC ACLs UNCHANGED — LATEST PAGES / CI / AUTHENTICATED GUARD E2E STILL UNVERIFIED — NOT GOLD/DIAMOND CLOSED`.

**Previous report:** `doc/Draft/Reprots/Report701_UNIFIED_WAREHOUSE_E2E_PASS_AND_PRODUCTION_GUARDED_CHANGESET_20261110.md`.
