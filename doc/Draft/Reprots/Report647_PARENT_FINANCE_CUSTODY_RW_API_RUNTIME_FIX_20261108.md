# Report647 — Parent Finance Employee Custody Runtime API Dependency Fix

**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-647  
**Previous checkpoint:** LVE-2026-11-08-646  
**Scope:** Repair the live Parent Finance > Employee Custody tab failure `RW_API is not defined`; verify the true runtime root cause; preserve the existing Supabase/Edge API contract; validate source and request behavior; update project continuity state.  
**Readiness:** SOURCE FIX COMMITTED — STATIC / CONTRACT VALIDATED; CLOUDFLARE PRODUCTION DEPLOYMENT AND POST-DEPLOYMENT BROWSER E2E UNVERIFIED.

## 1. Current verified event

The connected Parent page at `https://rawaea-erp.pages.dev/companies/company-1/main` showed the Finance tabs, including **عهد الموظفين**, followed by the visible runtime error:

```
RW_API is not defined
```

The existing LVE646 Employee Custody renderer was present in the live source lineage. This new failure was not a missing tab or missing custody database operation. It was a JavaScript dependency error triggered as the custody module began loading data.

The Cloudflare dashboard snapshot read during this investigation showed automatic deployments enabled and the latest listed Production source at commit `be4647ddc1caa3393229cfd73f80a31183457d27` (a descendant of LVE646's `f6ca94a`). Therefore the previous custody-ledger UI change had progressed to a descendant deployment, while the currently observed Parent page still exposed the API-symbol failure. The dashboard snapshot has not yet confirmed deployment of the new LVE647 fix.

## 2. Root cause — confirmed

The Parent shell and standalone PWAs have different initialization contracts:

- `companies/company-1/core.js` defines the shared `RW_API` wrapper. The current core blob inspected was `2d11b852862c523fc89e6a8b9c510462bb65cc4e`.
- The Parent `companies/company-1/main.html` independently initializes its Supabase client inside its own main application closure. It does **not** load `core.js`, and it does not define `RW_API`.
- The Parent's existing variables and APIs include `RW_SUPABASE_URL`, the already initialized `supabase` client, and its own `RW_Auth` session implementation.
- The Employee Custody module contained exactly one `RW_API` reference, in local helper `A(op,p,id)`. The first `GET_CUSTODY` request calls this helper, which immediately raised the observed `ReferenceError`.

This was an invalid cross-application dependency: a Parent-local module was calling a helper supplied only by the separate shared-core application architecture. Loading the whole `core.js` into Parent would be the wrong repair because Parent already owns its Supabase client and authentication implementation; that could introduce duplicated clients, overlapping auth listeners and scope collisions.

## 3. Surgical correction applied

**Only the existing file `companies/company-1/main.html` was changed.** No other operational HTML, shared Core, database, Edge Function, RPC, RLS policy, permission, schema, or business-data path was modified.

The Employee Custody module's local request helper now:

1. Calls the Parent's already initialized `supabase.auth.getSession()`.
2. Stops with a clear expired-session error when no access token is available.
3. Sends the request through the same existing endpoint:
   `RW_SUPABASE_URL + '/functions/v1/save-purchase-order'`.
4. Keeps the same method (POST), JSON content type, Bearer JWT, and request contract:
   `{ operation, payload, operation_id? }`.
5. Preserves the server error message for non-2xx responses and rejects empty/malformed JSON, missing responses, and `success:false` results rather than silently accepting them.

The Edge Function operation names, payload shapes, idempotency field, existing writer and authorization checks remain untouched. The fix therefore removes the invalid Parent dependency without creating a new API or bypassing the current backend contract.

### Operational source history

- Previous operational base when the first correction was applied: `be4647ddc1caa3393229cfd73f80a31183457d27`.
- First surgical correction commit: `4214cda5d180a003d79233a806ce7d6a2255b66b`.
- Automated forensic-only child after that correction: `999f9ab2dcfaff86c02332bd4d4fd22280f3de93`; it did not change the Parent HTML.
- Follow-up fail-closed response parsing correction: `2a751e67405326d940af6eaf0f69ce42c7eca969`.
- Latest operational branch HEAD observed: `b48f1d660473764a8d26536632899404b2789b9d`.
- Final Parent `main.html` blob: `4d25abf0d01b65acf48d7a76634293b8ea3e06ee`.
- Compare from `be4647d` to observed HEAD reports `companies/company-1/main.html` as the operational code change (`+19/-1)); the other compared path `_forensic_current_main_extract.md` is an automated forensic extract, not a production source file in the custody fix.

The final blob was fetched and independently inspected after the later commits. It contains **zero** remaining `RW_API` references.

## 4. Verification performed

All checks below were executed against the final committed Parent source or an isolated test of the exact extracted helper. These are source/contract checks, not a claim of authenticated end-to-end operation.

| Check | Result |
|---|---|
| Final source blob fetched and inspected | PASS |
| No remaining `RW_API` references in Parent main.html | PASS (0) |
| Inline JavaScript syntax compilation | PASS (1 executable inline block; no syntax errors) |
| Existing `save-purchase-order` endpoint retained | PASS |
| POST body retains `operation`, `payload`, and optional `operation_id` | PASS |
| Parent session JWT used as Bearer token | PASS |
| Missing/expired session rejected | PASS |
| HTTP 400 backend message propagated | PASS |
| Malformed JSON rejected (fail closed) | PASS |
| Missing HTTP response rejected | PASS |
| GitHub current branch contains final file blob | PASS |
| CI status | No status entries returned; no CI pass is claimed |

No test request was sent to the real Supabase Edge Function. The API behavior checks used isolated mocked session/fetch responses so no operational business action was invoked.

## 5. Production safety / side effects

- No Supabase SQL, DDL, DML, migration, RPC, Edge Function deployment, RLS/ACL, or role/permission changes were made for LVE647.
- No test custody, advance, expense, supplier payment, settlement, cash-box, treasury, journal, stock, supplier/AP, or inventory record was created or changed.
- No file upload or storage document was created.
- Existing Parent and backend financial posting paths remain the only paths responsible for their existing approved operations.

## 6. Deployment and runtime limitations

**CONFIRMED:** the source fix is committed, the current operational branch contains the corrected blob, and static/isolated request-contract checks pass.

**UNVERIFIED:** the currently readable Cloudflare dashboard snapshot still lists `be4647d` as latest Production and does not show commit `2a751e6` or its descendant. Automatic deployments are enabled, but this is not proof that the new build has completed. The connected browser integration in this session can read tabs but cannot refresh, navigate, click or interact with the page. The open Parent tab therefore remains a pre-fix loaded page, and authenticated post-deployment Finance E2E could not be executed here.

Do not mark the tab deployed or operationally accepted until a Cloudflare Production deployment for `2a751e6` or a descendant is visible, then refresh/reopen the Parent Finance page and verify that the custody tab loads its data without the ReferenceError.

## 7. Project continuity update

The LVE646 ledger work remains intact. The immediate operational blocker is now the Parent/API boundary, not a missing database object or Edge operation.

The following project contract remains binding:
- Parent `main.html` is an independently initialized app; do not import shared `core.js` solely to provide one helper.
- Parent-local modules must use Parent-owned auth/client interfaces, unless a deliberate and separately reviewed integration contract is introduced.
- Keep employee custody requests routed through `save-purchase-order` with the existing operation/payload contract.
- No automatic financial or inventory effects arise from the UI request itself; existing backend business rules remain authoritative.
- Preserve the LVE645 custody module stop/render lifecycle protection and the LVE646 ledger completion.

## 8. Final status and next exact action

**Status:** SOURCE FIX COMMITTED — STATIC / CONTRACT VALIDATED — DEPLOYMENT / AUTHENTICATED E2E PENDING.

**Next exact action:** confirm Cloudflare Pages Production is serving `2a751e67405326d940af6eaf0f69ce42c7eca969` or a later descendant; refresh the existing Parent Finance page; open **عهد الموظفين**; verify that the ReferenceError is gone and `GET_CUSTODY` renders its response. Only then proceed to the authenticated, removable-QA acceptance cycle for issuing/acknowledging custody, expenses, review, supplier payment display and settlement reconciliation.
