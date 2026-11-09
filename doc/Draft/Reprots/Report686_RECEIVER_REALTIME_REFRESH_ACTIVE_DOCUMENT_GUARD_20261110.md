# Report 686 — Receiver Realtime Refresh Interrupting Active Order / Receipt Workspace

**Date:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-686  
**Workstream:** RAWAEA ERP / Warehouse Receiver — prevent auto-refresh from replacing active order and receipt entry  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`

## 1. Root cause confirmed from source

This was not caused by the Returns reference or by the receipt writer.

The Receiver registered these realtime sources: `purchase_orders`, `purchase_invoices`, `buyer_goods_custody_events`, and `items`. Its previous `onEvent` callback invoked `loadPurchaseOrders()` for each relevant event, and `onReconcile` invoked it again during periodic reconciliation. Core debounces events per table, not as one Receiver-wide batch; a cluster of table events could therefore launch several competing Receiver fetches.

The previous `loadPurchaseOrders()` immediately replaced the main content with a Skeleton and then called `renderList()` after every successful fetch, even when the user was inside the standalone document workspace and actively entering sent/accepted quantities. It did not compare the fetched queue with the current queue. The page was consequently replaced with the list (or restored to a previous view after overlapping requests), clearing current inputs and the user's in-progress receipt context.

The shared Core's reconciliation interval is 30 seconds, but the event path can be more frequent because each published table has an independent debounce. This explains the user's report of repeated updates much more closely than the periodic reconcile interval alone.

## 2. Surgical correction applied

Only `companies/company-1/warehouse/receiver.html` was changed.

1. **Receiver-wide refresh coalescing:** Realtime and reconciliation signals now pass through `requestQueueRefresh`, which batches the burst into one quiet refresh after 1.2 seconds.
2. **Active document protection:** If the pending tab has an open document (`activeDocumentIndex !== null`), the refresh is deferred and only `refreshPending` is marked. No fetch, Skeleton, list replacement, or input destruction occurs while the document is open.
3. **Submission protection:** The same deferral applies while `isSubmittingReceipt` is true. A single-flight guard prevents a second receipt submission from being started concurrently.
4. **Invalidate stale queue requests:** Opening a document increments `loadSequence`, causing any earlier list request to exit before it can render over the document workspace.
5. **Quiet queue refresh:** Background list refreshes do not show a Skeleton. A stable queue signature is calculated from document, item, quantity, branch, supplier and item metadata fields. If the queue is unchanged, the new fetched data is retained without rebuilding the DOM.
6. **Preserve the visible state on read failure:** A failed background refresh no longer replaces an already-loaded list/document with an error empty-state. The current view is retained and the failure is logged.
7. **Return-to-list reconciliation:** Returning from an order immediately shows the cached worklist, then requests one quiet current-data refresh. Search and source-filter state remain in memory.
8. **No Core changes:** The shared Core event engine and its 30-second reconciliation interval remain unchanged. No other application is affected.

On successful receipt, the submission lock is released, the active-document marker is cleared, and the normal queue reload is allowed to run. On a failed or uncertain request the user remains in the open document, and the existing operation UUID/fingerprint retry safety remains in force.

## 3. Changed source / scope

- Operational commit: `a0569470c2312fd633068748ca6ae6b353380d22`
- Final Receiver blob: `9b85902b2c11b21769b4b4a57927f66fbca1a082`
- Only changed path in this change: `companies/company-1/warehouse/receiver.html`.
- `returns.html` remains the read-only reference; blob unchanged at `16d02fff2d00759451879204abf218202898f9c0`.
- No changes to `core.js`, `main.html`, Picker, Edge Functions, SQL migrations, RPCs, RLS, Supabase schema, or business records.

## 4. Verification matrix

### Source / static regression checks — 13/13 PASS
- Realtime event callback uses the coalesced scheduler.
- Periodic reconciliation callback uses the same scheduler.
- Active document and in-flight receipt both defer queue refresh.
- Opening a document invalidates any prior list-fetch sequence.
- Active-document / active-submit guard executes before Skeleton or queue load.
- Background refresh does not show the initial-load Skeleton.
- Unchanged queue signature skips `renderList()`.
- Failed refresh retains the current visible view.
- Receipt submission has a single-flight guard.
- Submission lock releases on the Edge callback.
- Previous standalone workspace and navigation actions remain.
- Returns reference blob unchanged.
- GitHub compare confirms the operational change is scoped to Receiver only.

### Scheduler / data-signature behavior harness — 7/7 PASS
- Open document: refresh deferred, no timer and no queue fetch.
- Receipt submission in progress: refresh deferred, no timer and no queue fetch.
- Multiple table events: coalesced to one timer.
- One background refresh executes after coalescing and is silent.
- Completed-history mode retains its own refresh behavior.
- Identical queue data creates an identical signature.
- Changed queue data produces a different signature.

Inline JavaScript parse: **PASS**.

No production receipt RPC, Edge receipt writer, or business mutation was invoked. No stock, Buyer custody, AP, Supplier ledger, Treasury, cash, journal or GL record was created or changed.

## 5. Release / runtime limits

- Authenticated browser E2E was not run; no authenticated Receiver session with write-safe UI interaction was available.
- Cloudflare published Receiver bytes and final Production deployment pointer were not verified in this task. Do not claim the fix is live until Cloudflare is confirmed to serve blob `9b85902b2c11b21769b4b4a57927f66fbca1a082`.
- The source and scheduler behavior tests pass, but they are not a substitute for observing the actual published browser runtime.

## 6. Next handoff

1. Verify Cloudflare Pages Production points to operational commit `a0569470c2312fd633068748ca6ae6b353380d22` and compare the served Receiver asset against blob `9b85902b2c11b21769b4b4a57927f66fbca1a082`.
2. In an authenticated Receiver account, open a PO and a Quick Market invoice, enter quantities/reasons without submitting, and confirm that realtime events do not replace the workspace or clear fields.
3. Confirm navigation back refreshes the list once, and receipt submit/success/failure does not trigger a second concurrent request.
4. Do not change the Returns reference or use a live receipt as an unapproved test fixture.

**Final status:** `ROOT CAUSE IDENTIFIED — RECEIVER REFRESH COALESCED — ACTIVE DOCUMENT / SUBMISSION PROTECTED — JS + 13 STATIC + 7 SCHEDULER ASSERTIONS PASS — NO BUSINESS MUTATION — CLOUDFLARE / AUTHENTICATED BROWSER E2E NOT VERIFIED`.
