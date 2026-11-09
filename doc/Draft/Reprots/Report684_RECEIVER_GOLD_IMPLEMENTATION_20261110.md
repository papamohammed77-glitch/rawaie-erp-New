# Report 684 — Receiver Gold Implementation, Production Receipt Contract & Verification

**Date:** 2026-11-10 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-10-684  
**Workstream:** RAWAEA ERP / Warehouse Receiver — PO + Quick Market  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`  
**Governance repository:** `papamohammed77-glitch/rawaie-erp-New` / `main`  
**Production database:** SMART ERP — Supabase project `fiilmooggumokxanwiyx`

## 1. Executive result

The scoped Receiver implementation has been applied to the operational source, the live Production receipt RPCs and permissions, and the existing `receive-purchase` Edge Function.

**Implementation status:** `SOURCE + PRODUCTION RPC/ACL + EDGE APPLIED — SYNTHETIC LOGIC TESTS PASS — AUTHENTICATED BROWSER E2E / FINAL CLOUDFLARE UI DEPLOYMENT NOT VERIFIED`.

No real PO, Quick Market invoice, inventory movement, buyer custody event, supplier ledger row, payment, Treasury movement, journal or GL row was created or modified for testing. Production was queried after each migration; the business-row counts remained unchanged.

The two posting paths remain deliberately distinct:
- PO acceptance moves only the physically accepted quantity into inventory and posts the established inventory / supplier-liability journal and supplier-ledger credit.
- Quick Market acceptance moves only the physically accepted quantity into inventory and reduces the buyer's goods custody; it does not post supplier AP, supplier ledger, Treasury/cash or GL.
- A fully rejected shipment can now be recorded as physical receiving evidence, with sent/accepted/difference/reason, while **no stock, PO/invoice receipt state, custody, AP, cash, Treasury, journal or GL effect is created**.

## 2. Operational source state

Operational `main` HEAD after the implementation:
- `8a703e1716b4754f005a9ef9827ee8769fc74ccc`
- Current Receiver file: `companies/company-1/warehouse/receiver.html`
- Final Receiver blob: `ac8f79424d272eff5b3e4b9fcef839d1c9ee9275`
- Final Receiver source: 638 lines / 51,414 characters.
- The reference-only `warehouse/picker.html` was not modified.
- `core.js` and `main.html` were not modified.

Receiver source commits:
- `989d1ac2d4436b7805634ce44e41b20204f20858` — branch-scoped queue, source filters and item enrichment.
- `deac04847c56149c4add2b1a318c208fd936cf50` — item details and sent/accepted receiving capture.
- `c83d2546cbf70a21d2a59bcc1c371fb756d721b0` — unified PO / Quick Market receipt history.
- `7ec8204a898cdf8b2c1ddb0c205396b14635ddc4` — fully rejected shipment evidence with no stock movement.
- `a99eac8af148a6d50cb257ccd144c68a06733c04` — restored-session role gate and empty-receipt handling.

### UI implementation

1. **Source-aware receiving worklist**
   - Separate PO and Quick Market counters and filters, while retaining a unified search.
   - Search covers PO / invoice references, supplier, item code, item name, barcode and description.
   - PO rows are company-scoped and filtered using the verified profile's branch scope. Branchless PO documents use the configured main branch only where that branch is in the permitted scope. Missing/empty scope fails closed for a non-owner Receiver.
   - Quick Market rows are obtained from the authenticated `get_quick_market_receiving_queue_atomic` contract, which also enforces server-side role and branch scope.

2. **Product detail and visual inspection**
   - Product master lookup is company-scoped and uses the existing Receiver role's `warehouse` permission; no RLS widening was needed.
   - Cards show item image, item name, code, barcode, unit and description, plus the document quantity, previously received quantity and remaining eligible quantity.
   - Image preview accepts HTTPS URLs only; non-HTTPS / malformed URLs fall back to the package placeholder.

3. **Physical shipment quantities**
   - Separate fields: sent in the current delivery and physically accepted by the warehouse.
   - Accepted quantity cannot exceed sent quantity; sent quantity cannot exceed document remainder / available Buyer goods custody; four-decimal precision is enforced.
   - A reason is mandatory when sent and accepted differ.
   - A fully rejected shipment (sent quantity positive, accepted quantity zero) is recordable with a mandatory reason. The UI explicitly states no stock was added.

4. **Retry identity**
   - One cryptographically generated UUID per physical receiving event.
   - The Receiver stores the operation UUID and payload fingerprint in browser local storage before sending.
   - If the network result is uncertain, the same UUID and identical payload must be reused. A changed payload is blocked until the uncertainty is resolved.
   - On confirmed success or a definitive server rejection the pending identity is cleared; the next physical delivery gets a new UUID.
   - No deterministic operation-ID fallback remains in the Receiver Edge Function.

5. **Receipt history**
   - The Completed tab now reads actual `receiving` headers and `receiving_details`, not merely PO lifecycle status.
   - It resolves the source to its PO or Quick Market invoice and displays sent, accepted, difference, reason, supplier, source and date.
   - Fully rejected shipments are explicitly labelled as rejected, not as accepted stock receipts.

6. **Security and live updates**
   - Database-sourced values are HTML-escaped before insertion; document/item values are no longer interpolated into dynamic inline event handlers. Click/input/error actions use event delegation.
   - Realtime subscribes only to the published parent tables `purchase_orders`, `purchase_invoices`, `buyer_goods_custody_events` and `items`. It no longer subscribes to unpublished `receiving` / `receiving_details` or applies a non-existent `company_id` filter to the details child table.
   - Reconciliation remains enabled through the shared Core Realtime engine.

## 3. Production RPC changes

The exact live definitions were preserved before modification in:
`Report683_RECEIVER_LIVE_RPC_SOURCE_SNAPSHOT_20261110.md`.

Three SQL migrations were committed to operational `main` and successfully applied to Production:

| Migration file | Commit | Production migration history entry |
|---|---|---|
| `20261110143000_receiver_per_delivery_quantities_and_legacy_rpc_acl.sql` | `7435aa454771fd2de4cbad4a065ed97953957739` | `20261109223413 receiver_per_delivery_quantities_and_legacy_rpc_acl` |
| `20261110153000_receiver_record_zero_accepted_physical_delivery.sql` | `cd8a9ac6f84da453daa3b1ac377d86543b40c58d` | `20261109224240 receiver_record_zero_accepted_physical_delivery` |
| `20261110160000_qmp_receipt_retry_after_full_acceptance.sql` | `8a703e1716b4754f005a9ef9827ee8769fc74ccc` | `20261109224530 qmp_receipt_retry_after_full_acceptance` |

### Per-delivery quantity contract

Both modern writers keep their current function signatures and accept JSON line fields:
- `sent_qty` — quantity declared in the current shipment; persisted as `receiving_details.qty_expected`.
- `received_qty` — quantity actually accepted by the warehouse; persisted as `receiving_details.qty_received`.
- `difference` — `received_qty - sent_qty`.
- `reason` — mandatory whenever the quantities differ.

Rules:
- `sent_qty > 0`, accepted quantity `>= 0`, accepted quantity `<= sent_qty), at most four decimal places.
- PO sent quantity cannot exceed remaining ordered quantity.
- Quick Market sent quantity cannot exceed invoice remainder or the buyer's available goods custody after accepted warehouse quantities and supplier-return offsets.
- Duplicate item identities are rejected.
- A positive sent quantity is required for a receiving record; zero accepted quantity is permitted only with a mismatch reason.
- The per-operation fingerprint includes item, sent quantity, accepted quantity and reason. Same UUID / same payload is a duplicate; same UUID / changed payload conflicts.

The existing `save-purchase-order` Edge `RECEIVE_PO` caller remains compatible: if its legacy payload omits `sent_qty`, the SQL contract defaults sent quantity to accepted quantity. No incompatible RPC signature change was made.

### Fully rejected delivery

A receiving event with positive sent quantities and zero accepted units:
- creates a receiving header/details and audit record;
- leaves PO status unchanged;
- leaves Quick Market invoice receipt state unchanged;
- does not call stock movement for those zero-accepted lines;
- does not reduce Buyer goods custody;
- does not post supplier AP / supplier ledger / Treasury / cash / journal / GL.

For mixed acceptance, only lines with positive accepted quantity trigger inventory movement and the established source-specific posting.

### QMP retry after completed receipt

The Quick Market RPC now validates the authenticated actor, effective warehouse role/permission and branch before looking up the operation ID. It checks the existing receipt and payload fingerprint **before** enforcing the invoice's final `is_received` / `received_date` state gate. Therefore, a retry after a fully accepted invoice can return the already-committed result rather than failing merely because the previous attempt completed the invoice receipt state. A different payload with the same operation ID still fails.

## 4. Legacy RPC security remediation

The old Production function remains present but is no longer executable by client roles:
`public.receive_quick_market_invoice_atomic(uuid,uuid,text,jsonb,uuid)`.

Post-migration `has_function_privilege` results:
- `anon`: false
- `authenticated`: false
- `service_role`: true

The modern PO and Quick Market receipt writers are also service-role-only; the authenticated Receiver uses the existing verified Edge boundary. The legacy function was not invoked or dropped. Catalog inspection found no other live database function referencing it, and the current Edge functions use `receive_quick_market_purchase_atomic` for QMP. The old function remains retained as a source-compatible artifact until a separate retire/drop decision is made.

The global Supabase security advisor still reports four other anonymous SECURITY DEFINER execution findings unrelated to this Receiver function. This task does not claim the entire project security advisory set is clear.

## 5. Receiver Edge Function

File: `supabase/functions/receive-purchase/index.ts`  
Final blob: `25b002ea4bcb76f0d7a42bf8410d275f8523b59e`  
Source commit: `30c6745ec3096a643bc92e7ab1042427f7e197ba`

Deployed Supabase Edge Function:
- Version **17**
- Status **ACTIVE**
- `verify_jwt=true`
- Re-fetched deployed `index.ts` compared byte-for-byte with the GitHub source: **MATCH**.

The Edge validates the bearer user/effective profile/company/role, requires the same valid UUID in the request body or Idempotency-Key header (and rejects disagreement if both are supplied), maps `sentQty` / `receivedQty` / `reason`, and leaves the server-side actor/branch/quantity guards authoritative. It accepts fully rejected deliveries as receiving evidence but does not itself post inventory.

## 6. Production integrity after all migrations

Read-only Production checks after the final migration confirmed:

| Table | Count after implementation |
|---|---:|
| receiving | 0 |
| receiving_details | 0 |
| inventory_log | 76 |
| supplier_ledger | 2 |
| journal_entries | 20 |
| buyer_goods_custody_events | 0 |

No production receipt, stock movement, buyer custody event, supplier balance, payment, Treasury, journal or GL row was created for testing.

Post-migration function privileges:
- `receive_purchase_atomic(uuid,text,text,jsonb,uuid)`: `service_role` only.
- `receive_quick_market_purchase_atomic(uuid,uuid,text,jsonb,uuid)`: `service_role` only.
- legacy `receive_quick_market_invoice_atomic(...)`: `service_role` only.
- authenticated Receiver read of `get_quick_market_receiving_queue_atomic(uuid)` remains available under its existing authenticated role guard.

## 7. Verification matrix

### Source / logic / contract tests

| Gate | Result |
|---|---|
| Final Receiver inline JavaScript parse | PASS |
| 23 synthetic Receiver logic assertions | **23/23 PASS** |
| HTML escaping and unsafe image URL rejection | PASS |
| HTTPS image URL acceptance | PASS |
| UUID generation and local retry identity | PASS |
| Branch code → UUID resolution | PASS |
| Missing non-owner branch scope fails closed | PASS |
| Owner all-branch scope | PASS |
| Realtime list matches published company-scoped parent tables | PASS |
| Sent/accepted quantity validation and required reason | PASS |
| Accepted > sent rejected | PASS |
| Sent > remaining document balance rejected | PASS |
| Empty receiving submission rejected | PASS |
| Network uncertainty preserves UUID and payload | PASS |
| Changed payload blocked while prior outcome uncertain | PASS |
| Same payload retry reuses the UUID | PASS |
| Confirmed success clears pending operation identity | PASS |
| Fully rejected delivery is sent with reason, accepted=0 and explicit no-stock confirmation | PASS |
| Dynamic inline handlers with database values | 0 found |
| PO / QMP production writer static effect assertions | PASS |
| Queue RPC field contract vs Receiver UI | PASS |
| QMP duplicate check precedes final invoice-state gate | PASS |
| Post-migration EXECUTE ACL checks | PASS |
| Production business-row count unchanged | PASS |

The 23 assertions used a synthetic in-memory Supabase / browser harness and did not call any production writer RPC or Edge Function.

### Release gates not completed

- **Authenticated Receiver browser E2E:** NOT RUN. The connected ERP browser tab is at the Parent application, not an authenticated Receiver session, and the available browser connector in this session is read-only. No credentials were requested or used.
- **Cloudflare Production UI asset:** NOT VERIFIED for the final Receiver commit. The open dashboard snapshot was last loaded before these Receiver commits and displayed a prior Production pointer. Direct published-file retrieval was unavailable. Automatic deployments are enabled, but that alone is not proof of the final UI artifact.
- **GitHub combined status / CI for final `main` HEAD:** no status entries were returned; no CI pass is claimed.
- **Live operational transaction E2E:** NOT RUN. No reversible, isolated test document was available/approved. Existing PO and PINV-1002/PINV-1003 were not used as fixtures. No real operation was posted just to simulate E2E.

**Do not describe the current revision as a fully released or authenticated-E2E-accepted deployment yet.** Source, Production SQL and Edge are applied and non-mutating logic tests pass; Cloudflare UI artifact and authenticated browser E2E remain the final gates.

## 8. Next handoff

Resume from LVE-2026-11-10-684. Do not reapply the three migrations or redeploy the same Edge source. First verify Cloudflare Production now points to operational `main` HEAD `8a703e1716b4754f005a9ef9827ee8769fc74ccc` and compare the published Receiver asset with blob `ac8f79424d272eff5b3e4b9fcef839d1c9ee9275`. Then use an authenticated Receiver account to verify role/branch scope, both queues, product images, partial receipt, fully rejected delivery, receipt history and live reconciliation.

Any live mutation E2E must use a deliberately approved reversible business document and a proven full reversal/cleanup path. Do not use production business invoices or open PO records as ad-hoc fixtures.
