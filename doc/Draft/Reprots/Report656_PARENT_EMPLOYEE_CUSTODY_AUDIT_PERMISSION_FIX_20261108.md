# Report656 — Parent Employee Custody Audit Permission Failure Fix

**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-656  
**Status:** ROOT CAUSE CONFIRMED — SMART ERP PRIVATE READ RPC APPLIED — EDGE v36 ACTIVE — SAME PURCHASER SESSION REQUESTS RETURN HTTP 200 — FINANCIAL DATA UNCHANGED

## 1. Incident and confirmed root cause

The Employee Custodies tab failed with:

`permission denied for table audit_log`

The browser console also showed two `POST .../functions/v1/save-purchase-order 400` responses. The Tailwind CDN production warning appeared in the same console but is unrelated to the tab failure.

The incident was correlated against live Supabase logs, not inferred from the browser message alone:

- At 2026-11-08 19:18:52 UTC, Postgres logged SQLSTATE `42501`, `permission denied for table audit_log`.
- The PostgREST error hint identified the current role as `service_role` and suggested granting it SELECT.
- The corresponding Edge request to `save-purchase-order` returned HTTP 400.
- The logged REST query was the newly added `GET_CUSTODY` cancellation-audit lookup.
- Active Edge v35 source confirmed the lookup used `sb.from("audit_log")`; `sb` is initialized with `SUPABASE_SERVICE_ROLE_KEY`.
- The actual ACL confirmed `service_role` has INSERT only on `public.audit_log`, not SELECT. The table's authenticated SELECT privilege remains subject to existing restrictive RLS policies.

**Root cause:** the new cancellation-detail lookup read the protected audit table using the service-role client, but the service role intentionally has no SELECT privilege. The resulting PostgREST error propagated through the Edge Function catch block as HTTP 400 and stopped the custody payload from loading.

The PostgREST hint was deliberately **not** followed. Granting broad SELECT on the audit table to the service role would have widened access to the full company audit log and concealed the architectural error.

## 2. Surgical database correction

Added internal function:

`app_private.buyer_custody_cancellation_audit_read_internal(uuid, uuid[])`

- `SECURITY DEFINER`, `STABLE`, and `search_path = ''`.
- Requires a live `auth.uid()`, an active user in the supplied company, and one of the existing `purchases`, `finance`, or `finance_manager` effective permissions.
- Caps each request at 200 custody IDs, matching the maximum custody-register page size.
- Verifies every requested custody belongs to the supplied company.
- A purchaser without Finance/Finance Manager permission can retrieve cancellation metadata only for custody rows where that user is the assigned employee.
- Finance/Finance Manager can retrieve metadata for the company register, consistent with the current `buyer_custodies_read_scope` policy.
- Returns only `custody_id`, `cancelled_by`, `cancelled_at`, and `cancellation_reason`; it does not return the complete audit row or `old_data` / `new_data`.

Added the public RPC entry point:

`public.buyer_custody_cancellation_audit_read(uuid, uuid[])`

This wrapper is `SECURITY INVOKER` and delegates to the internal `app_private` function. This keeps the privileged read implementation out of the exposed public API schema while allowing the authenticated Edge caller to invoke the narrow wrapper.

**Final grants verified:**
- `authenticated`: EXECUTE on the public wrapper and private internal function.
- `anon`: no EXECUTE.
- `service_role`: no EXECUTE on this read RPC and still no SELECT on `public.audit_log`.
- The public wrapper is not SECURITY DEFINER.
- The internal function uses an empty search path.
- No audit-table SELECT grant was added, and existing audit RLS policies were not broadened or replaced.

The Supabase Security Advisor was re-run after the final wrapper/private-function structure. It reported no finding for either `buyer_custody_cancellation_audit_read` function. Existing project-wide advisor findings remain outside this repair; they were not changed by this task.

## 3. Existing Edge Function correction

Updated the existing `save-purchase-order` Edge Function; no duplicate function was created.

**Deployed state:**
- Version: **36**
- Status: **ACTIVE**
- `verify_jwt`: true
- SHA-256: `40db7903fe2ce396c18dec8f13492a48b7a04b5a5ba37cc577666a7b599f4304`

In `GET_CUSTODY`:
1. The service-role client continues to load the purchase-invoice link rows it is already authorized to read.
2. The direct `sb.from("audit_log")` request was removed entirely.
3. Cancellation metadata is now obtained through `profileClient.rpc("buyer_custody_cancellation_audit_read", ...)`, carrying the caller's JWT.
4. The result mapping consumes only the four explicitly returned fields.
5. RPC errors are still surfaced; the implementation does not silently suppress authorization or data errors.

The function was re-fetched after deployment. The active remote source is version 36, contains the scoped RPC call, and contains no direct service-role read from `audit_log`.

## 4. Verification

### Authenticated RPC behavior — PASS

All QA records below were inserted inside disposable transactions and rolled back.

| Caller context | Test | Result |
|---|---|---|
| Purchaser with `purchases` permission | Read cancellation metadata for their own assigned custody | PASS; only the narrow fields were returned |
| Same purchaser | Request an unrelated/nonexistent custody ID | PASS; rejected with `CUSTODY_AUDIT_SCOPE_FORBIDDEN` |
| Finance Manager | Read cancellation metadata for the company custody register | PASS |
| Anonymous role | Execute the wrapper | DENIED by function ACL |
| Service role | Execute the wrapper or read the audit table | DENIED by function/table ACL |

Synthetic audit rows used test-only email labels and QA reasons; the surrounding transactions were rolled back. Final database check found zero matching QA audit rows.

### Actual Edge traffic after deployment — PASS

Supabase logs show requests made with the same authenticated purchaser session as the incident, after version 36 was activated:

- 2026-11-08 19:23:37 UTC — `POST save-purchase-order` — HTTP 200.
- 2026-11-08 19:23:52 UTC — `POST save-purchase-order` — HTTP 200.
- 2026-11-08 19:24:07 UTC — `POST save-purchase-order` — HTTP 200.

The corresponding requests identify Edge version 36. The post-deployment log query found no subsequent `permission denied for table audit_log` event in the checked window.

### Production data integrity — PASS

Final live row counts:

| Table / check | Rows |
|---|---:|
| buyer_custodies | 1 |
| buyer_custody_advances | 1 |
| buyer_custody_expenses | 0 |
| buyer_custody_payments | 0 |
| buyer_custody_settlements | 0 |
| QA audit rows | 0 |
| custody update/cancel audit events | 0 |

The existing custody remains EGP 5,000, status `Issued`, with its original acknowledgement, cash-box reference, and journal-entry reference. Its Initial advance remains EGP 5,000 and acknowledged. The record was not edited, cancelled, settled, or deleted. No cash, journal, supplier, or stock movement was posted.

## 5. Scope and non-regressions

- No Parent `main.html` change was needed for this backend permission fault.
- No Tailwind build change was made. The CDN message is a separate production optimization warning, not the cause of this exception.
- No new Edge Function, broad audit permission, new audit RLS policy, or browser direct-DML path was introduced.
- Existing custody edit/cancel authorization and atomic financial RPC contracts from Report655 remain unchanged.
- No QA fixture or financial movement remains.

## 6. Runtime qualification

**Confirmed:** the exact Postgres permission failure was traced to the v35 service-role audit query; the narrow private RPC and invoker wrapper were tested under purchaser and Finance Manager JWT contexts; Edge v36 is active; same-purchaser Edge calls returned HTTP 200 after deployment; production row counts and the acknowledged EGP 5,000 custody remain unchanged.

**Not claimed:** a separate visual walkthrough of the authenticated modal and all browser controls. Backend request logs establish the repaired API response path, but they are not a screenshot or full visual UI acceptance test.

## 7. Closure

**EMPLOYEE CUSTODY AUDIT PERMISSION FAILURE FIXED — PRIVATE SCOPED READ RPC ACTIVE — EDGE v36 ACTIVE — POST-DEPLOY SAME-SESSION REQUESTS HTTP 200 — AUDIT ACL UNCHANGED — NO TEST DATA OR FINANCIAL MOVEMENT LEFT.**

---
