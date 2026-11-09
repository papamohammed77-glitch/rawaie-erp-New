# Report 682 — Receiver Gold UX, Receiving Contract, Security & Custody Forensic Review

**Date:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-682  
**Workstream:** RAWAEA ERP / Warehouse Receiver — PO + Quick Market receiving  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**Production database:** SMART ERP — Supabase project `fiilmooggumokxanwiyx`

## 1. Executive result

**Forensic review completed. Operational fix NOT applied. Owner ChangeSet approval is required before changing the receipt UI, Edge/RPC contract, or production function permissions.**

The present Receiver is not yet a complete receiving workstation. It has a single mixed pending list for PO and Quick Market, does not capture both the supplier/buyer-declared shipped quantity and the quantity physically accepted, does not display item photos/descriptions/barcodes, and its Completed tab is not a true receipt history. It also has a retry identity defect, a Realtime subscription mismatch, branch-scope gaps in the PO reader, unsafe HTML interpolation, and a separate legacy Quick Market SECURITY DEFINER RPC with PUBLIC/anon/authenticated EXECUTE privileges.

The two active business paths are materially different and must remain separate:

- **PO:** physical accepted quantity is posted as PurchaseIn, PO line received quantity/status is updated, and the current Production RPC posts inventory debit / supplier payable credit and a supplier-ledger liability.
- **Quick Market / Employee Custody:** accepted quantity is posted as PurchaseIn, buyer goods custody is reduced and invoice receipt progress is updated. The current RPC explicitly reports no supplier AP, supplier-ledger, journal, Treasury or cash posting.

No operational repository file, SQL object, RLS policy, Edge Function, deployment, inventory row, supplier balance, custody balance, cash/Treasury row, journal or GL record was changed by this checkpoint.

## 2. Governance and source reading

Read in full:
- `doc/Draft/Reprots/writing-block-8888-10.md` — 1,035 lines / approximately 27,617 characters, read in consecutive ranges.
- `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md` — 2,665 lines.
- `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`.
- `CURRENT_STATE.md` and the Receiver/Buyer workstream reports listed below.
- Current `receiver.html`, `picker.html`, `core.js`, current `receive-purchase` Edge source, and the current PO receive migration in the operational repository.
- All seven Edge Function entry points were scanned for receive RPC references.

The governing rules in Master §77.1 require the system to distinguish a document lifecycle from physical custody, inventory custody, supplier/customer subledger and GL effects. A PO or invoice alone is not a stock receipt. Effects must follow a real, evidenced handover/receipt and must post exactly once.

Master §77.2 and the permanent constitution require an exact Owner-reviewed ChangeSet before a change that can affect production inventory, supplier/AP, permissions or financial postings. This review therefore stops before that risky write boundary; the broad task delegation does not waive the specific approval gate in the supplied operating constitution.

## 3. Verified source state

### 3.1 Operational GitHub

- Current `main` HEAD: `11f49dc381d522549e76d47419b10a19316e3a93`.
- Receiver: `companies/company-1/warehouse/receiver.html`, blob `b0d7796ffe7f227ebd7973009d0e8190fa6d8f51`, 436 lines / 25,657 characters.
- Picker reference only: `companies/company-1/warehouse/picker.html`, blob `d483bd15b36585b975b63c2ef641481a01d5d084`.
- Shared Core: `companies/company-1/core.js`, blob `2d11b852862c523fc89e6a8b9c510462bb65cc4e`.
- Receiver Edge: `supabase/functions/receive-purchase/index.ts`, blob `a482839164f281d4a5733ad341ce7bb7668a6051`.
- PO authorization migration: `supabase/migrations/20261103155444_receive_purchase_role_and_branch_authorization.sql`, blob `47fbd47e428ef3191c3038393a81877583a8c93b`.

The Receiver itself has not been updated in the latest operational commit; the HEAD change was the Supervisor tabs restoration. The current Receiver blob was fetched again before this report.

### 3.2 Cloudflare and browser evidence

The currently open Cloudflare Pages dashboard DOM reports Production / `main` at commit `11f49dc`, with automatic deployments enabled. This confirms the displayed Production deployment pointer for the current HEAD; it does not independently verify that the published Receiver bytes match the Git blob.

The ERP browser tab is at Parent sign-in, not an authenticated Receiver account. Available browser integration is read-only (tab list / tab context); it does not permit interaction with the application. Direct retrieval of the published Receiver asset was not successful. Therefore authenticated Receiver E2E and byte-for-byte published-file parity are **NOT VERIFIED**.

GitHub combined status for `11f49dc` returned no status entries. No CI pass is claimed.

## 4. Current Receiver behaviour and confirmed UI defects

1. The current three tabs are Pending, Completed and Account. Pending mixes PO and Quick Market rows into one unsegmented queue.
2. PO selection queries company-scoped purchase orders but does not select or filter `branch_id` in the Receiver reader. RLS is company-wide; the server-side PO receipt RPC applies the branch authorization. This means the UI can present a document outside the Receiver's allowed branch even though the backend later rejects it.
3. PO detail selection currently omits `item_id`, and both sources omit some of the item-master presentation data needed for the Picker-quality experience.
4. Current line display reports order/invoice quantity, previously received quantity, and remaining/available quantity. It has no distinct per-delivery `sent_qty` field and does not let the Receiver record the declared shipment quantity separately from the physically accepted quantity.
5. Item image, barcode and description detail / photo preview are absent from the Receiver. Production item master currently contains 34 HTTPS image URLs, 18 populated barcodes and 10 populated descriptions. The current Receiver role has effective `warehouse` permission, which is already included in the existing item SELECT policy; no RLS widening is needed for this currently configured role.
6. The Completed tab queries PO headers in Received / Partially Received states. It does not query the actual `receiving` / `receiving_details` operation records as a unified receipt history, so Quick Market receipts and partial delivery-level detail are not represented as an auditable receiving history.
7. Dynamic document and supplier values are inserted into HTML strings; `RW_UI.safeHTML` in Core is a direct `innerHTML` assignment, not an HTML sanitizer. Document codes are also interpolated into inline `onclick` JavaScript. A supplier/document value containing markup or quotes can break the event attribute or create a DOM-XSS surface. Picker's current image-cache concatenation must not be copied as a security pattern.
8. Current Realtime config subscribes to `purchase_orders`, `receiving` and `receiving_details`. Production publication inspection showed `purchase_orders`, `purchase_invoices`, `buyer_goods_custody_events` and `items` published, but `receiving` and `receiving_details` are not in `supabase_realtime`. Also `receiving_details` has no `company_id` column, while Core `RW_Realtime` defaults to a `company_id=eq.<company>` filter unless `companyColumn:false` is supplied. The current subscription is therefore not aligned to the live publication/schema. Core's 30-second reconciliation is the fallback, not proof of immediate live updates.
9. Current success and error rendering includes dynamic document data in HTML. It must be converted to escaped text / safe DOM binding and event delegation; adding more escaping around inline JavaScript is not an adequate fix.

## 5. Idempotency and receiving quantity contract

### 5.1 Operation identity

The current Edge v15 supports a supplied UUID from the body or `Idempotency-Key`; when absent, it creates a deterministic identity based on user/company/document/items. The current Receiver supplies neither an `operation_id` nor the header.

That fallback makes a later, physically distinct delivery with exactly the same item/quantity payload reuse the previous operation identity. A true retry should reuse the same UUID, but a new physical shipment must receive a new UUID. The front end must create a UUID per receiving event, persist the pending UUID and payload fingerprint through an uncertain response, and reuse it only for that same retry. After confirmed success, the next receiving event must get a new UUID. The same UUID with a changed payload must be rejected by the existing fingerprint guards.

### 5.2 Sent versus accepted quantity

Current PO RPC writes `receiving_details.qty_expected = purchase_order_details.qty_ordered` on every receiving event, and difference is calculated against that full order quantity. The Quick Market receipt RPC similarly stores the full invoice-line quantity / custody offer as expected on every receiving event. For split deliveries, this does not represent the quantity sent in the current delivery.

Production `receiving_details` already has:
- `qty_expected`
- `qty_received`
- `difference`
- `reason`

The table currently has zero rows. Read-only inspection found no views or materialized views consuming `receiving_details`; the other custody functions inspected require the existence of a receipt line and inspect `qty_received`, not `qty_expected` / `difference`. The current receipt writer functions are the only confirmed writers of those fields.

**Proposed contract for owner review:** record the declared quantity sent *in this delivery* in `qty_expected`; record the physically accepted quantity in `qty_received`; calculate `difference = qty_received - qty_expected`; require a reason whenever the values differ. The ordered or invoiced master quantity remains in the PO / invoice detail table and is displayed separately from the shipment quantities. This can reuse the existing columns without a new column, but a final whole-repository reader scan is still required before applying the semantic change.

Per source:
- **PO:** `0 <= accepted_qty <= sent_qty <= remaining_PO_qty`. A larger-than-order delivery remains blocked unless a separate approved over-delivery policy is introduced. The PO remains partially received until all ordered quantities are accepted.
- **Quick Market:** `0 <= accepted_qty <= sent_qty <= min(invoice_remaining_qty, buyer_goods_custody_available_qty)`. Supplier-returned quantities must already have been deducted by the live custody projection. Only accepted quantity reduces Buyer goods custody and moves to branch stock. The unaccepted remainder remains in the Buyer's goods custody.
- For both paths, require at least one positive accepted line for a stock receipt; validate all submitted lines and duplicate line identities server-side; discrepancy reason is mandatory where sent and accepted differ.

The sent quantity must be part of the server payload fingerprint so retry identity covers all material quantities and reasons.

## 6. SMART ERP Production — database, permissions and real effects

Project `fiilmooggumokxanwiyx` is `ACTIVE_HEALTHY`. All inspection in this task was read-only.

### 6.1 Current relevant counts

| Table / record family | Current count |
|---|---:|
| purchase_orders | 3 |
| purchase_order_details | 5 |
| purchase_invoices | 5 |
| purchase_invoice_details | 11 |
| receiving | 0 |
| receiving_details | 0 |
| buyer_goods_custody_events | 0 |
| inventory_log | 76 |
| supplier_ledger | 2 |
| journal_entries | 20 |

The two current open PO records are on branch BR-01. A third PO has no branch and is not open. The two Quick Market / Employee Custody invoices are on BR-01; together they contain 29 invoice units and have 0 accepted warehouse quantity. These records were not used as test fixtures and were not modified.

### 6.2 PO receiving effect

The current `receive_purchase_atomic(uuid,text,text,jsonb,uuid)` is SECURITY DEFINER and is executable only by `service_role`; the compatibility overload is also service-role-only. The Edge validates the authenticated user/profile before calling it. The function checks company, receiving role/permission, branch, PO, item identity, duplicate line items, remaining quantities and operation identity under row locks.

After a valid physical receipt it:
- posts `PurchaseIn` stock movement for the accepted quantity;
- increments PO detail `qty_received` and updates PO status;
- posts a balanced journal (inventory account 124 debit / supplier account 211 credit) for the received value;
- records supplier-ledger credit / payable for the received value;
- records the receiving header/details and audit event.

This means a PO receipt is both a stock event and a supplier/AP/GL liability event under the current contract. It must not be triggered by PO approval, PO creation or a receipt-screen preview.

### 6.3 Quick Market receipt effect

Current Receiver Edge v15 routes Quick Market invoice receipts to `receive_quick_market_purchase_atomic`, not to the legacy function described below. The live RPC is service-role-only and validates the actor, company, warehouse role/permission, branch, Quick Market source, Employee Custody settlement source, invoice state, invoice line remaining quantity and buyer goods-custody availability/returns.

After a valid physical warehouse receipt it:
- posts `PurchaseIn` only for the accepted quantity;
- increments invoice detail `received_qty` and invoice receipt status;
- records `BUYER_TO_WAREHOUSE_ACCEPTED` custody events for the accepted quantity;
- reduces Buyer goods custody only by the accepted quantity;
- explicitly does **not** post supplier AP, supplier-ledger liability, journal/GL, Treasury or cash movement.

Do not merge these two accounting contracts. The Quick Market invoice's custody projection is a specific business rule established by the Production migration recorded in Report676; it is not permission to treat every invoice as goods received.

## 7. P1 security finding — exposed legacy Quick Market writer RPC

Production catalog contains:
`public.receive_quick_market_invoice_atomic(uuid,uuid,text,jsonb,uuid)`

Verified live definition:
- `SECURITY DEFINER`, `search_path = ''`.
- Accepts `p_user_email` as caller-supplied actor identity.
- Looks up an active user by company/email and active warehouse role `استلام`, but does not bind that email to `auth.uid()` or the caller's effective profile.
- Performs branch / invoice / quantity / buyer custody checks, then inserts receiving rows, invokes privileged `PurchaseIn` stock movement, writes buyer custody events and updates invoice receipt progress.
- Live ACL includes `PUBLIC`, `anon`, `authenticated` and `service_role`. `has_function_privilege` returned EXECUTE=true for PUBLIC, anon and authenticated.
- The current Receiver Edge and the other six current Edge entry points do not call this legacy RPC. The current Receiver Edge calls `receive_quick_market_purchase_atomic`; `save-purchase-order` invokes the guarded PO RPC for its separate `RECEIVE_PO` operation.
- The old RPC's creating migration/source is not present in the current operational migration tree. Production migration history includes the Buyer phase-1 migrations from 2026-11-04, but matching source files are absent from current `main`. The PostgREST exposed-schema setting could not be confirmed from SQL (`current_setting('pgrst.db_schemas')` returned NULL), so this report does not claim a live HTTP exploit was tested.

**Risk:** a SECURITY DEFINER stock writer whose authorization trusts a supplied email and whose ACL grants PUBLIC/anon is an unsafe privilege boundary. It was not invoked. A zero-current-event count does not make the function safe for future use once Buyer goods-custody events exist.

**Proposed immediate security change for approval:** revoke client/public execution and preserve only the service-role grant if any audited internal caller still requires the function:
```sql
REVOKE ALL ON FUNCTION public.receive_quick_market_invoice_atomic(uuid, uuid, text, jsonb, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.receive_quick_market_invoice_atomic(uuid, uuid, text, jsonb, uuid)
  TO service_role;
```
Before applying, recover/store the exact current function definition as a source-controlled snapshot and verify no legitimate internal caller uses it. If it is fully retired, consider dropping it only in a separately approved change after dependency checks; do not drop it in this first remediation.

## 8. Additional contract dependencies and source drift

- The seven current Edge functions were scanned. Only `receive-purchase` routes to PO and Quick Market receipt RPCs. `save-purchase-order` also calls `receive_purchase_atomic` in its `RECEIVE_PO` operation. It supplies `p.operation_id` or its request operation ID. Therefore the PO RPC payload change must preserve or explicitly update this second caller; do not change the shared RPC signature incompatibly.
- `main.html` is too large for the available GitHub fetch endpoint in this session, and the initiating UI of that legacy `RECEIVE_PO` operation was not fully traced. Compatibility must be proven in the change review before deployment.
- Production migration history contains `20261109190444 buyer_quick_market_invoice_derived_custody_and_supplier_return`; Report676 records that it exists in Production, but a matching migration file is not present in the current operational `main` tree. The 2026-11-04 Buyer phase-1 migrations listed in Production likewise are not all represented by same-named current-main files. This is production/source drift. Do not reapply or recreate those migrations during this Receiver task; first recover the exact live definitions and preserve them as reviewed source artifacts.
- The current `receive-purchase` Edge Function is ACTIVE v15 with `verify_jwt=true`; its deployed source was fetched and compared byte-for-byte with the current GitHub source and matched. No Edge deployment was performed.

## 9. Exact proposed Owner ChangeSet

**Scope — no unrelated application changes:**

1. `companies/company-1/warehouse/receiver.html`
   - Keep this file as the only warehouse UI target; Picker remains reference-only.
   - Separate pending PO and Quick Market source filters/cards while retaining one search across document code, supplier, item code/name and supplier invoice number.
   - Branch-scope PO list by the verified profile's allowed/default branch set; fail closed if a non-owner Receiver has no proven branch scope. Server-side authorization remains authoritative.
   - Enrich PO / QMP lines with same-company `items` metadata: item image, description, barcode, unit and stable item identity. Add safe HTTPS image rendering, fallback, photo/detail viewer, and order/invoice quantity / previously received / remaining indicators.
   - Capture declared sent quantity and physically accepted quantity separately; display discrepancy reason and do not submit invalid quantities.
   - Convert database-driven HTML to escaped text / safe DOM binding and event delegation; remove database values from inline JavaScript handlers.
   - Replace PO-only Completed with a real `receiving` operation history for both PO and Quick Market, joined to the actual source document and receipt detail lines. Retain Account/logout.
   - Change Realtime inputs to published tenant-parent tables `purchase_orders`, `purchase_invoices`, and `buyer_goods_custody_events`; retain the periodic reconcile and re-fetch authoritative rows through RLS. Do not subscribe to unpublished `receiving` / `receiving_details` or apply a company filter to a child table without that column.
   - Generate one UUID per physical receipt and persist/reuse it for the same unresolved retry/payload; use a fresh UUID for the next physical delivery.

2. `supabase/functions/receive-purchase/index.ts`
   - Require a valid supplied UUID operation ID for new Receiver submissions; stop silently deriving a deterministic identity from document/quantities for a new physical shipment.
   - Validate/map `sent_qty`, `received_qty`, reason and source-line identity into the existing PO/QMP RPC payloads.
   - Keep bearer JWT / effective-profile / role and company checks; do not weaken actor verification.

3. Existing RPC definitions in a new reviewed migration (no apply until exact definition/source recovery and Owner approval):
   - Keep existing public function signatures stable where possible; add/validate sent-quantity fields in the JSON payload for both PO and QMP writer paths.
   - For PO validate accepted <= sent <= PO remaining; insert `qty_expected=sent`, `qty_received=accepted`, `difference=accepted-sent`; discrepancy reason required.
   - For Quick Market validate accepted <= sent <= invoice remaining and buyer custody available after accepted supplier-return offsets; only accepted quantity reduces Buyer custody and posts stock.
   - Include sent quantity and reason in the payload fingerprint; keep operation IDs unique per receiving event and duplicate replay safe.
   - Preserve the exact difference in downstream effects: PO receipt maintains Inventory + Supplier/AP + GL; Quick Market receipt maintains Inventory + Buyer goods-custody only, with no AP / supplier-ledger / cash / Treasury / GL.
   - Preserve a backward-compatible default for any audited `save-purchase-order` `RECEIVE_PO` caller that still omits `sent_qty`, or update and test that caller explicitly before making it mandatory.

4. Security remediation migration:
   - Revoke PUBLIC/anon/authenticated EXECUTE on the legacy `receive_quick_market_invoice_atomic` as shown in §7; keep service_role only until dependency audit confirms whether the function can be retired.
   - Verify ACLs and test that anonymous/authenticated direct execute is denied; no stock RPC invocation in a test.

No change is proposed to `picker.html`, `core.js`, `main.html`, supplier/customer balances, stock tables, custody data, treasury, journal or GL outside the authorized receipt operation. No new Edge Function is needed.

## 10. Acceptance and E2E plan (not run)

### Static / source tests
- Parse the full inline Receiver JavaScript after patch.
- Assert all tab IDs, action handlers and event delegation targets exist.
- Verify dynamic supplier, document, barcode, item description and image values cannot create HTML or JavaScript attributes.
- Test image URLs: HTTPS accepted; javascript:, data:, HTTP and malformed URLs rejected / placeholder shown.
- Test item rendering with and without image, barcode and description.
- Verify branch filters for owner, single default branch, multiple allowed branches and missing/empty scope.
- Verify PO and Quick Market queues remain separately identifiable and searchable.

### Behavioural fixtures (no DB writes)
- PO order 10, prior received 2, shipment sent 5, accepted 5 => PO cumulative received 7, remaining 3, difference 0, no duplicate action.
- PO order 10, prior received 2, shipment sent 5, accepted 4 with reason => PO cumulative received 6, remaining 4, receipt difference -1.
- Reject received > sent, sent > PO remaining, duplicate item identity, negative / excessive precision, empty receipt and mismatch without reason.
- Quick Market invoice line remaining / buyer custody 8, sent 5, accepted 4 => only 4 stock and custody units posted/deducted; 4 remain with Buyer; difference -1.
- Reject QMP sent > custody available, sent > invoice remaining, accepted > sent, repeated line identity, over-return offset or missing reason.
- Same operation UUID + same fingerprint => duplicate success without a second movement. Same UUID + changed fingerprint => conflict. New physical delivery with the same quantities + a new UUID => new legitimate operation.
- Ensure PO path mock writes only expected PO stock/AP/GL contract and QMP mock writes only QMP stock/custody contract; mocks invoke no real RPC.

### Authenticated read-only UI E2E
- Use a real active Receiver profile and branch scope.
- Verify PO queue, Quick Market queue, branch scope, supplier/item detail/images, sent/accepted quantity fields, receipt history for both paths, account/logout, and live refresh after an approved controlled upstream change.
- For final operational posting acceptance, use only a specifically approved reversible test document and cleanup plan with proven full reversal. Never use the current PINV-1002/PINV-1003 or live PO rows as test fixtures.
- Verify stock, buyer goods custody, supplier subledger, journal/GL and Treasury snapshots before and after the controlled test, with the separate PO/QMP expected-effect matrix.
- Verify Cloudflare Production asset content against the committed source after deployment.

**This E2E was not run in this checkpoint:** the only ERP browser tab is unauthenticated Parent sign-in, available browser integration is read-only, and no safe reversible test document was approved. No production business rows were created.

## 11. Verification matrix

| Gate | Result | Evidence |
|---|---|---|
| Operating prompt full read | PASS | 1,035 lines / ~27.6k characters, consecutive reads |
| Constitution + Master governance | PASS | Full files read; §77.1 / §77.2 applied |
| Current GitHub HEAD / Receiver / Picker / Core | PASS | Fetched current source blobs |
| Receiver Edge / deployed v15 source parity | PASS | Git source byte-equal to active deployed source |
| SMART ERP project health / schema / policies / functions | PASS — read-only | Production catalog and RLS inspected |
| PO / QMP business effect separation | PASS — source inspection | Live atomic function definitions inspected |
| Current Receiver UI gaps | PASS — source inspection | Current 436-line Receiver reviewed |
| Legacy RPC privilege finding | CONFIRMED | SECURITY DEFINER + PUBLIC/anon/authenticated EXECUTE; not invoked |
| Current Cloudflare Production pointer | PARTIAL PASS | Dashboard DOM shows main / 11f49dc; published Receiver byte parity not proven |
| GitHub CI checks for 11f49dc | NOT VERIFIED | No combined status entries |
| Authenticated Receiver E2E | NOT RUN | No authenticated session and no browser interaction capability |
| Any Production SQL / Edge / source write | NOT PERFORMED | No changes / migrations / deployments |
| Inventory / AP / custody / cash / Treasury / GL mutation | NONE | No business mutation invoked |

## 12. Owner decision required

The forensic work is complete and the ChangeSet above is prepared. It is intentionally not committed to the operational repository because its RPC changes determine inventory and supplier/AP/GL outcomes, and the legacy RPC permission change affects the Production security surface.

**Required approval:** approve LVE-2026-11-10-682 exactly as scoped in §9, including (a) per-shipment sent/accepted quantity semantics, (b) required new operation UUID per real receipt with stable retry identity, (c) legacy QMP RPC client-execute revocation, and (d) the documented PO vs Quick Market posting boundaries. Any changed scope or financial effect must be a separately reviewed ChangeSet.

**Closure state:** `FORENSIC COMPLETE — FIX NOT APPLIED — OWNER CHANGESET APPROVAL REQUIRED`.

**Next step after approval:** recover exact live RPC definitions and source drift, implement only the reviewed Receiver/Edge/RPC changes, run non-mutating syntax/fixture tests, then use an authenticated Receiver session and a separately approved reversible test document for E2E. Never claim release until the production source, Edge, deployment and post-transaction balances are verified.
