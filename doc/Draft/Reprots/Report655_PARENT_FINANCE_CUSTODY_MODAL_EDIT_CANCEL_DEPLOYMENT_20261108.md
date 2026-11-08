# Report655 — Employee Custody Detail Modal, Guarded Edit/Cancel and Deployment

**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-655  
**Status:** PARENT CHANGE COMMITTED — SMART ERP RPC / EDGE v35 ACTIVE — CLOUDFARE APP BUILD DEPLOYED — FINANCIAL QA TRANSACTION TESTS PASSED / ROLLED BACK — AUTHENTICATED BROWSER CLICK-THROUGH UNVERIFIED

## 1. Executive outcome

The requested Employee Custody detail interaction was implemented in the Parent application and committed to the operational main branch. Clicking **فتح التفاصيل** now opens a dedicated, wide, RTL SweetAlert2 modal modeled on the Parent Purchase Request visual language and the Purchase Order detail behavior. The modal retains the register context and presents the existing custody summary, cash delivery/advance history, purchase invoices and operational expenses, supplier payments, settlement history and available actions.

The same modal now contains guarded **تعديل البيانات** and **إلغاء العهدة** actions. Edit is a synchronized pre-disbursement change to the custody header and its Initial advance. “Delete” is implemented as a soft cancellation, not a physical DELETE; it retains both the original custody and initial advance and stores the reason and actor in the audit log. The final **تسوية ورد نقد** action continues to use the existing atomic settlement and cash-receipt contract.

The live EGP 5,000 custody already acknowledged by its employee and posted to cash-box/journal was verified as ineligible for edit or cancellation. It was not modified, cancelled, settled, or otherwise touched.

## 2. Source, commits and deployment parity

Operational repository: papamohammed77-glitch/erp-frontend, branch main.

Parent file: companies/company-1/main.html.

- Main UI implementation commit: 7d04ca065a34fd295ada4f503119c5dd0b8ff5d0.
- Follow-up form correction (preselect the current employee): 084836175f322c08fe96c1fd89ed0e052fb5d3e7.
- Latest observed operational HEAD: 61b50ecfb3c104677aa97ed26e1cb5f81270495e; its only descendant change after the UI commit updates _forensic_current_main_extract.md.
- Current Parent blob: d785c25ea325dfa3df12acb5dbc4d7a848728ee6.
- Parent blob in the Cloudflare-successful commit 0848361: the same d785c25ea325dfa3df12acb5dbc4d7a848728ee6.

Cloudflare check run:
- Project: rawaea-erp.
- Check: Cloudflare Pages: rawaea-erp.
- Check run: 128831392851.
- Source commit: 084836175f322c08fe96c1fd89ed0e052fb5d3e7.
- Status: completed / success, completed at 2026-11-08T19:08:16Z.
- Deployment preview URL returned by Cloudflare: https://9be60acf.rawaea-erp.pages.dev.
- The deployed commit tree and the latest main branch resolve to the identical Parent blob above.

Other Pages projects in the same repository (warehouse-supervisor, rawaea-store, and erp-frontend) returned separate build failures for this repository push. They are not the Parent application deployment target and no source files for those apps were changed in this task.

## 3. Parent UI changes

Only companies/company-1/main.html was modified for the application behavior.

1. Added a private openDetail(id,root) renderer using SweetAlert2:
   - responsive width min(1100px, 96vw);
   - RTL layout, Finance-indigo hero and clear file identity;
   - independently scrollable detail body bounded to the viewport;
   - close button and no artificial confirm/save button for opening read-only details;
   - underlying paginated register, search filters, page and page size stay in place.
2. Replaced the detail-button expand/scroll branch with openDetail(...).
3. Preserved the already-rendered detail card as the single data/markup source and hid the old below-table accordion to remove the competing detail interface.
4. Replaced the under-table note with explicit modal and register-context behavior.
5. Added the private edit form with branch, employee, same-branch Cash treasury, issue date, purpose, amount, reference, notes and mandatory reason. The active employee is preselected when the form opens; employee and treasury choices are recalculated when branch changes.
6. Added the private cancellation confirmation with a mandatory reason. The user-facing wording is إلغاء العهدة and states that the record/history is retained.
7. Routed modal actions through one delegated modal handler. Advance, review, settle and edit/cancel open their existing/new action dialogs only after the detail modal closes; document viewing leaves the detail modal open.
8. Added the ملغاة status label, excluded cancelled records from the open-custody KPI, and suppressed advance/settlement/edit/cancel controls on a cancelled or finally closed custody.
9. Edit and cancel controls are shown only when the server-provided can_edit / can_cancel flags are true. The current posted custody therefore does not show either control.
10. The comprehensive Parent bind(root) remains the single active binder; the prior bindLegacy(root) rename and all search/pagination controls remain intact.

### Static validation

- Retrieved the final 1,852,376-character Parent blob from GitHub.
- Compiled the complete executable inline Parent script with new Function: passed; one executable inline block was found and parsed.
- Confirmed exactly one active function bind(root) and the retained bindLegacy(root).
- Verified the modal helper, edit/cancel functions, open-detail dispatch, hidden detail template, cancellation status label and preselected employee markers.
- No unrelated Parent tabs, Core, Buyer, Driver or purchasing/warehouse app files were edited.

## 4. SMART ERP database changes

Project: Supabase SMART ERP fiilmooggumokxanwiyx, ACTIVE_HEALTHY.

### Status and audit

- Extended buyer_custodies status constraint to include Cancelled while retaining Issued, UnderReview, Settled and Closed.
- Added partial unique index ux_audit_log_custody_operation_id on (company_id,operation_id) for custody update/cancellation audit events.
- The live audit_log_action_check allows only generic actions including update; the new procedures therefore use action='update' and a namespaced source:
  - RW_Finance_Custody:UPDATE_CUSTODY
  - RW_Finance_Custody:CANCEL_CUSTODY
- Each operation stores before/after JSON, actor, company, reason/request and operation ID. The audit event is committed atomically with the corresponding custody change.

### New atomic RPCs

public.buyer_custody_update_atomic(...)

- Requires an active authenticated actor and Finance/Finance Manager permission.
- Locks the custody and allows edits only in Issued state before custody or advance acknowledgement.
- Requires exactly one Initial advance with no acknowledgement, cash-box receipt or journal entry; rejects any additional advance, expense, supplier payment, settlement or linked quick-market invoice.
- Validates employee activity and branch eligibility, actor branch scope, active same-branch Cash treasury (non-POS), positive amount, system currency and a mandatory reason.
- Updates the custody header and Initial advance together in one transaction. It does not post cash or a journal entry.
- Enforces operation ID replay/conflict handling and writes the old/new audit record.

public.buyer_custody_cancel_atomic(...)

- Requires active authenticated Finance/Finance Manager user and authorized custody branch.
- Allows cancellation only for an unacknowledged, unposted Issued custody with only its unacknowledged Initial advance and no expense, supplier payment, settlement or linked quick-market invoice.
- Requires a non-empty reason.
- Sets status to Cancelled, preserves custody/advance rows, and writes the audit event atomically.
- Does not hard-delete any ledger row, cash box, journal or document.

Both functions are SECURITY DEFINER with search_path=''; their execution is revoked from PUBLIC and anon and granted only to authenticated. Both independently verify auth.uid(), active actor, company, permission, branch and record-state conditions. The generic Supabase Security Advisor reports authenticated execution of SECURITY DEFINER functions; this is intentional for the authenticated RPC contract and is constrained by the internal checks above. anon execution is false for both new functions.

No RLS policy was broadened and no direct table UPDATE/DELETE permission was added.

## 5. Existing Edge Function extension

The existing save-purchase-order Edge Function was extended; no new function was created.

- Current version: 35, ACTIVE, verify_jwt=true.
- Source SHA-256: 11d793f8cd8fc1d2b5d2aac9b06806df802420b7d14076d06f5b496364132bb2.
- Added Finance/Finance Manager authorization routes for UPDATE_CUSTODY and CANCEL_CUSTODY.
- Routes both operations through the caller-authenticated profileClient.rpc(...) calls.
- Extends the register's employee projection with allowed_branch_ids.
- Computes page-level can_edit / can_cancel from server-loaded custody, advance, expense, payment, settlement and linked invoice state; these flags are UI affordances only. The RPC repeats every critical condition after row lock.
- Loads cancellation metadata from audit rows using the permitted generic action and namespaced source type.
- No additional Edge Function or endpoint was introduced.

## 6. Financial QA and safety tests

All committed QA lifecycle tests were run inside explicit PostgreSQL transactions ending in ROLLBACK. No test custody or cash/journal transaction was left behind.

### Pre-disbursement edit/cancel lifecycle — PASS

A disposable custody was issued inside a transaction, then:
1. Edited before employee acknowledgement, synchronizing header and Initial advance.
2. Replayed the exact operation ID; the retry returned a duplicate result.
3. Replayed the same operation ID with conflicting data; rejected with CUSTODY_OPERATION_ID_CONFLICT.
4. Soft-cancelled with a mandatory reason.
5. Replayed the cancellation operation ID; returned the duplicate result.
6. Attempted to add an advance after cancellation; rejected with CUSTODY_NOT_OPEN.
7. Verified two audit events, retained original custody/advance rows, and no cash-box or journal references on the QA advance.
8. Rolled the entire transaction back.

### Existing posted custody protection — PASS

Using the authorized Finance Manager identity, attempted both edit and cancellation against the actual acknowledged EGP 5,000 custody. The update RPC rejected it with CUSTODY_EDIT_AFTER_ACKNOWLEDGEMENT; the cancellation RPC rejected it with CUSTODY_CANCEL_AFTER_ACKNOWLEDGEMENT. Both attempts were enclosed in a rollback transaction. No audit or financial row was written.

### Full cash issue / acknowledgement / final return lifecycle — PASS

A second disposable transaction:
1. Issued a QA custody in pending acknowledgement state.
2. Simulated the assigned employee's authenticated acknowledgement.
3. Verified the acknowledgement posted the linked cash-box disbursement and journal entry.
4. Simulated Finance final settlement and returned the full EGP 100 balance.
5. Verified the settlement row, actual cash receipt reference, journal entry and final Settled state.
6. Rolled the entire transaction back.

This tests the existing final settlement/return contract without posting a permanent receipt against the real custody.

### Post-test Production baseline — UNCHANGED

| Table | Current rows |
|---|---:|
| buyer_custodies | 1 |
| buyer_custody_advances | 1 |
| buyer_custody_expenses | 0 |
| buyer_custody_payments | 0 |
| buyer_custody_settlements | 0 |
| new custody update/cancel audit events | 0 |

The remaining custody is the original EGP 5,000 record with employee acknowledgement, cash-box ID and journal-entry ID populated. Its status remains Issued in the current data model; the server flags both can_edit and can_cancel false for it. It was not settled or modified.

## 7. Deployment and runtime qualification

**Confirmed**
- Parent source commit and latest Parent blob.
- Complete inline JavaScript syntax compilation.
- SMART ERP status constraint, audit index, RPC signatures, function security settings and ACL.
- Active Edge v35 with JWT verification.
- Cloudflare check run for rawaea-erp completed successfully; latest Parent blob matches the blob in that successful deployment commit.

**Unverified**
- Authenticated browser click-through on the live deployed URL, including actual SweetAlert visual inspection, X/Escape dismissal, nested accordion behavior, mobile viewport and event routing in a live authenticated DOM.
- The connected Browser integration in this session was read-only, and the already-open Parent/Cloudflare tabs were stale snapshots. No live click or network-console capture was possible.

Do not confuse the successful Cloudflare build/deployment check with an authenticated UI E2E test. The source/deployment parity is confirmed; interactive runtime acceptance remains unverified.

## 8. Scope and data integrity

- No physical custody delete.
- No edit/cancel on acknowledged or posted custody.
- No permanent QA fixture or financial/inventory transaction.
- No supplier payable/payment, inventory or stock quantity mutation.
- No new Edge Function, no branch, no separate staging target.
- Existing one-time final SETTLE_CUSTODY contract remains the final settlement and return path; partial cash returns were not invented or simulated.

## 9. Closure

PARENT MODAL / GUARDED EDIT / SOFT CANCEL COMMITTED — SMART ERP RPC + EDGE v35 ACTIVE — CLOUDFLARE APP DEPLOYMENT SUCCESS — TRANSACTIONAL FINANCE TESTS PASS — PRODUCTION DATA UNCHANGED — AUTHENTICATED BROWSER E2E UNVERIFIED.

---
