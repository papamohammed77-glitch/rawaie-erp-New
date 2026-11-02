# RAWAEA ERP — Buyer Field Purchasing App: Gold/Diamond Product Upgrade Review
**Checkpoint:** LVE-586  
**Date:** 2026-11-02  
**Status:** SOURCE REVIEW COMPLETED / PRODUCT UPGRADE DESIGN DEFINED / NO OPERATIONAL SOURCE OR PRODUCTION CHANGE IN THIS CHECKPOINT

## 1. Executive finding

This is not a request to make Buyer merely functional. Buyer is the field purchasing workstation: the user is in markets, visiting suppliers, comparing products and prices, buying urgently, carrying goods and cash, and handing goods to the warehouse. The application must therefore optimize for rapid field decisions, resilient capture, low-friction interaction, reliable evidence, and end-to-end ERP consistency.

The current app contains a substantial purchasing workflow (Today, Suppliers, PR, Quotations, Orders, Invoices, Custody, Vehicle Balance, Account), but its experience remains largely a desktop-style set of data screens rendered inside a mobile viewport. The central gap is not missing color or rounded cards; it is the absence of a unified field-work journey connecting supplier visit → product selection → market price capture → purchase evidence → physical goods custody → warehouse handover → cash reconciliation.

**No operational Buyer source was edited in this checkpoint.** The currently fetched source is 139,419 characters and corresponds to the LVE-585 verified Buyer blob `73d746571a10b1720bdd31631004abce0ac9afa1`. The latest Buyer-path commits visible in Git history include the invoice-row interaction/escaping fixes (LVE-583); they do not establish completion of the broader gold/diamond product upgrade.

## 2. Preserve completed work and binding constraints

1. Preserve the current shared `core.js` / `RW_API` gateway, authentication, company scoping, effective permissions, existing realtime lifecycle, currency-from-parent-settings behavior, and the existing purchase Edge gateway.
2. Preserve the LVE-583 invoice row click/escaping correction and the existing Draft edit/delete safeguards. Do not repeat or overwrite those fixes.
3. Preserve the current product master as the only source of item identity. Buyer must not create ad-hoc duplicate products. Invoice lines must reference the canonical item record and retain the item code/name/unit identity used by the parent ERP.
4. Preserve the LVE-585 business definitions:
   - Vehicle balance = physical goods in the purchasing officer's car, item by item, from confirmed physical movements.
   - Cash custody = actual cash in the buyer's possession and accountable responsibility, with submitted/approved/rejected/returned/unsubstantiated amounts distinct.
   - `فواتيري` = the buyer's own quick market-purchase invoices, not a generic supplier/AP invoice registry.
5. No Production DDL, RPC, trigger, RLS/grant, Edge deployment, or data write is authorized by this review. Any operational changes require the exact changeset and owner approval under the project governance documents.

## 3. Verified current-source findings

### 3.1 Data retrieval and catalog completeness

- `App.data(table)` requests `GET_DATA` with `limit:500`, caches the result for 20 seconds, and returns the returned `items` array.
- The Today screen itself warns that each entity is capped at 500 records; the Invoices screen repeats the same warning.
- This is not safe as the long-term product catalog contract. It can silently hide valid items, suppliers, invoices, orders, or history after the first 500 records unless the gateway explicitly guarantees a complete bounded set.
- The previous verified Production snapshot found 30 active items, 29 with images, 20 with barcodes, and 24 with zero `cost_price`. This is a small current catalog, not proof that the 500-row retrieval design is scalable.
- Quick item search checks only the already-loaded `items` array, matches name/code/barcode, and displays at most 20 matches. It does not show category, pack/specification, image, availability by branch, or whether a reference cost is stale/zero.
- `quickAddItem` defaults `unit_price` to `Number(it.cost_price||0)`. This is a material field risk: a zero or stale cost must never be presented as a reliable market purchase price.

### 3.2 Current tab map

| Tab | Current behavior evidenced in source | Gold/diamond gap |
|---|---|---|
| Today | Aggregates summary, PRs, POs, invoices, suppliers, items, branch stock, settings and custody; shows critical shortages, overdue orders, custody estimate and quick-purchase shortcut | Needs a field action center, next-best actions, supplier/visit context, offline state, prioritized alerts, and data freshness/source labels; current metrics depend on capped client-side lists |
| Suppliers | Directory with name/code/phone/area search and supplier opening | Needs fast call/contact actions, last prices/purchases, open commitments, delivery reliability, visit notes and safe location context; avoid inventing unsupported visit data |
| PR | Existing purchase request workflow | Needs clear request urgency, branch need, stock context, approval state, and one-tap conversion paths without bypassing approval contracts |
| Quotations | Supplier quotation listing, filters, detail, accept and convert-to-PO flow | Needs side-by-side item-level supplier comparison, landed cost/availability/lead time, validity alerts and clear distinction between accepting a quote and posting stock/finance |
| Orders | PO listing/details, quantities ordered/received/remaining and status history | Needs actionable receiving progress, supplier ETA/overdue queues, item-level shortage and branch destination visibility; maintain PO status semantics |
| فواتيري | Current listing loads all `purchase_invoices`, supplier index, filters by code/supplier/date/status and opens detail; it is explicitly labeled supplier invoices | Wrong product meaning for the buyer's own market purchases; must become a scoped quick-market-purchase workbench while preserving separate supplier/AP invoice semantics elsewhere |
| عهدتي | Reads custody snapshot and shows custody, submitted/approved expenses, advances, payments and settlement; current UI text describes supplier/AP/GL effects | Needs cash-in-hand reconciliation with expense categories, evidence, approvals, physical return, and unexplained cash; avoid automatic supplier AP effects for every expense |
| رصيد السيارة | Finds active `fleet_vehicle_assignments` where `driver_user_id=currentUser.id`, then displays a read-only placeholder explaining buyer stock ledger is not enabled | Wrong identity model for a purchasing officer; no balance should be inferred from driver assignment, PO, invoice, or receiving status |
| حسابي | User profile, permissions, reports and purchase settings | Needs a compact field profile, sync/storage/device state, help and safe session controls; settings should remain role/permission gated |

### 3.3 Field experience and design-system comparison with Picker

Picker offers useful interaction patterns: large touch targets, prominent item imagery, immediate search feedback, readable item detail, visible progress, and task-focused cards. Those are patterns to adopt selectively, not a reason to copy Picker's legacy authentication or direct service wiring.

Buyer currently uses a purple theme, compact tab strip, small search results, and several table/modal-heavy flows. For a phone used in a market, the priority should be:
- a mobile-first action hierarchy rather than a compressed nine-tab desktop navigation;
- large, thumb-reachable controls and persistent primary actions;
- product cards with image, item identity, unit/pack, barcode, and contextual stock;
- explicit status and evidence states;
- fast transitions between scan/search, item details, cart, invoice capture, and handover;
- no modal stack that loses the user's current cart or captured evidence.

### 3.4 Important functional risks

1. **Cost reference:** current quick-add silently seeds a line price from `cost_price`; zero is rendered as a normal price. Replace with a labeled reference state: “لا يوجد سعر تكلفة موثوق” or “آخر تكلفة مسجلة” with its date/source when available. Never silently treat zero as a suggested purchase price.
2. **Catalog:** client-side 500 cap is not an enterprise-grade catalog contract. Introduce server-side search with cursor/page metadata, barcode exact match, and a bounded recent/popular cache; the server remains authoritative.
3. **Quick purchase identity:** current invoice creation uses the generic purchase invoice structure with mandatory supplier identity. A distinct, explicit quick-purchase source marker and seller identity strategy are required; do not classify every no-PO invoice as a market purchase.
4. **Invoice media:** current quick-purchase form does not provide a complete invoice-image and item-photo workflow. Private media storage must be company- and document-scoped; do not use the public product-images bucket for private invoices or receipts.
5. **Line specifications:** `purchase_invoice_details.notes` exists, but the previously verified create/update draft paths do not persist per-line notes. The UX must capture pack, brand/model/specification, unit, quality/expiry/batch when applicable, and notes in structured fields supported by a reviewed contract.
6. **Custody semantics:** existing expense submit/review path is PO-linked and supplier/AP oriented. Fuel, transport, market purchase and other cash expenses require separate supported categories and proof types; they must not all reduce supplier payable.
7. **Vehicle stock:** the existing delivery-vehicle and Van Sales models must not be repurposed. A canonical custodial movement model must distinguish the buyer as custodian and the buyer's purchasing vehicle from driver/van stock.
8. **Warehouse intake:** Receiver currently works from PO receiving. Quick market purchases need a distinct invoice-linked intake route with actual accepted quantities, partial/short/over receipt handling, receiver identity/time, and atomic stock posting through the canonical inventory writer.
9. **Offline resilience:** the presence of Dexie in the page does not prove an offline workflow. A proper offline queue needs explicit local draft state, retry/idempotency, conflict handling, sync indicators, and a clear prohibition on pretending an unconfirmed offline action has posted to Production.
10. **Data freshness:** cached data is held for 20 seconds without a visible last-updated/freshness label. A field user needs to know whether stock, price and supplier information is current.

## 4. Target gold/diamond product experience

### 4.1 Navigation and home

Replace the current compressed nine-tab strip with a mobile-first information architecture:
- **الرئيسية** — field action center.
- **الموردون** — directory, supplier profile, contact and history.
- **الشراء** — PRs, quotations, POs and market purchase.
- **فواتيري** — buyer-owned quick purchase invoices.
- **العهدة والسيارة** — two distinct ledgers, never conflated.
- **حسابي** — profile, sync, reports and settings.

Desktop may expose the same sections in a wider side/top navigation. The primary field action should remain visible: **شراء من السوق**.

Home should show, in order:
1. current buyer identity, branch/assignment context and sync status;
2. cash custody available / pending evidence / amount to return;
3. buyer-car physical item count/value only if a verified movement ledger exists;
4. urgent purchase requests and approved needs;
5. supplier appointments/visits only if a visit contract is actually introduced;
6. overdue PO deliveries and warehouse handover tasks;
7. high-priority stock shortage recommendations with branch and requested quantity;
8. quick actions: scan barcode, search item, create market purchase, record expense, record physical handover.

Do not display fabricated KPIs or “AI recommendations” without explainable source inputs.

### 4.2 Product discovery and selection

A premium product search should support:
- barcode scan and exact barcode match;
- instant local search over a bounded cache plus server-side search for full catalog coverage;
- name, item code, barcode, alternate code and approved specification fields;
- image-first result cards where a valid product image exists;
- unit, pack size, category and active/inactive state;
- branch-level available stock and allocated quantity, clearly time-stamped;
- last known cost with source/date and a warning when zero, missing or stale;
- supplier-specific last purchase price only when a reliable supplier-item history exists;
- favorites/recently selected items without creating duplicate item records.

The item detail sheet should show identity and buying context, then a single clear action to add to the current purchase. Quantity and market price are separate editable values. The buyer must confirm the price actually quoted by the market seller; the system must not silently use zero cost.

### 4.3 Quick market purchase journey

A guided, resumable field flow:
1. Select/confirm seller identity using an approved supplier or “unregistered market seller” workflow. Do not create fake supplier records.
2. Capture invoice photo immediately; allow retake and review.
3. Add items by scan/search; show item image and full identity.
4. Capture actual unit, pack/specification, quantity, unit price, discount/tax where contractually supported, and line notes.
5. Capture item photos only when they add evidence (substitution, damaged packaging, unfamiliar specification); link them to the invoice line, not the global catalog by default.
6. Show a continuously updated subtotal/total and currency from parent settings.
7. Show a clear validation summary: missing invoice image, missing seller identity, invalid quantity, zero price, mismatched unit, duplicate line, or unsupported tax.
8. Save as a local/offline draft if connectivity is absent; label it **محفوظ على الجهاز — لم تتم المزامنة**.
9. On sync, submit through the existing authorized gateway with idempotency key and return server-generated document identity/status.
10. The invoice remains non-posting until actual physical receipt and approval evidence satisfy the approved business contract.

The list screen should have segmented views: مسودات الجهاز، بانتظار المزامنة، بانتظار الاستلام، مكتملة/مرحّلة، مرفوضة/تحتاج تصحيحًا. Filters should include date, seller, status, item and amount. Detail should show invoice media, seller, line items, evidence timeline, receiving link and audit events.

### 4.4 Cash custody workbench

Display an actual reconciliation equation, not a generic “available” figure:
- opening/issued cash physically acknowledged by the buyer;
- additional advances physically acknowledged;
- expenses submitted (pending review);
- expenses approved;
- expenses rejected (remain cash in hand unless physically returned);
- cash physically returned and acknowledged by finance;
- unexplained/unsupported cash;
- **cash expected in hand** and **cash physically counted** as separate values.

Expense categories must include market purchase, fuel, transport, communications/other only after their evidence and accounting treatment are approved. Each category has its own proof requirements. An expense submission is not proof of payment to a supplier unless it contains the appropriate supplier payment evidence. Approval is not itself a supplier payment. Returned cash needs a receipt/acknowledgment event. Never auto-mark an invoice paid merely because a custody expense is approved.

### 4.5 Purchasing vehicle stock workbench

Show:
- selected purchasing vehicle and assigned buyer/custodian;
- item-level on-hand quantity, unit and last movement;
- received from supplier;
- loaded from warehouse;
- issued from warehouse for an operational/customer need;
- handed to warehouse (accepted quantity only);
- returned to supplier (accepted quantity only);
- discrepancy/shortage and evidence.

Only completed physical movements affect the balance. Every movement must have operation ID, actor, timestamp, source/destination, item, quantity, reason, evidence and immutable audit identity. The customer/operational-use case must reference its customer/order or business reason without accidentally creating a sales invoice. Supplier returns affect supplier/AP only after supplier acceptance and the proper financial document.

### 4.6 Supplier and quotation intelligence

Supplier profile should become a field-ready decision page:
- contact/call action and address;
- categories/items supplied;
- last purchase and last quoted price per item, with date and source;
- outstanding POs and expected deliveries;
- approved supplier performance metrics (on-time, fill rate, quality/returns) only when underlying data exists;
- quote comparison per item with unit normalization, total landed cost, lead time, payment terms, validity and availability.

Do not compare prices across incompatible units or pack sizes. Every calculated “best offer” must expose its inputs and exclusions.

## 5. Integration and accounting/stock invariants

| Business event | Inventory | Cash custody / treasury | Supplier/AP | GL |
|---|---|---|---|---|
| Market invoice saved as Draft | No effect | No effect | No effect | No effect |
| Goods physically handed from seller to buyer car | Buyer-car custodial quantity increases only | No implied effect | No implied AP effect if buyer paid cash; separate verified payment evidence required | Only through approved accounting policy |
| Cash expense submitted | No effect | Moves to pending substantiation, not approved expense | No automatic AP reduction | No automatic journal |
| Expense approved | No inventory effect by itself | Approved substantiation; cash remains accountable until properly settled | No automatic supplier payment | Account mapping and journal only under approved policy |
| Buyer car → warehouse accepted receipt | Buyer-car quantity decreases; branch stock increases by accepted quantity via canonical stock writer | No implied effect | No automatic AP effect | Inventory accounting follows canonical receipt contract |
| Warehouse → buyer car issue | Branch stock decreases; buyer-car custodial quantity increases | No cash effect | No AP effect | Inventory/custody account treatment per approved policy |
| Buyer car → supplier return | Buyer-car quantity decreases only after physical supplier handover; accepted return evidence required | No implied cash return | AP/credit note only after supplier acceptance and financial evidence | Reversal/credit treatment per approved contract |

Mandatory invariants:
- no document-status-only stock or financial effects;
- no duplicate stock posting across invoice, receiver and voucher paths;
- no direct writes to stock tables or receiving detail tables from the browser;
- use existing canonical stock writer / approved RPC path;
- all operations idempotent and company-scoped;
- every posting has a reversal/correction path, never destructive deletion of posted financial documents;
- use EGP or the parent-configured currency, never hardcoded SAR;
- maintain the existing company/role authorization and private document access boundaries.

## 6. Delivery plan — sequenced by dependency

### Phase A — Field UX foundation (no DB contract changes)
- Responsive mobile shell, navigation, design tokens and touch targets.
- Product result card and item detail sheet.
- Search state preservation and accessible empty/loading/error states.
- Visible online/offline/sync and last-refresh state.
- Remove misleading zero-cost presentation; display cost confidence/source state.
- Improve Today to action-oriented layout without inventing missing visit data.

### Phase B — Catalog and performance contract
- Confirm GET_DATA response envelope and whether server-side pagination/cursor is supported.
- Add server-side search for items and other large lists; retain only a bounded local cache.
- Barcode exact lookup; deduplicate and rank results.
- Add tests for 501+, 2,000+ and multi-page records.
- No silent partial-result behavior.

### Phase C — Quick market purchase document
- Agree seller identity strategy compatible with mandatory `purchase_invoices.supplier_id`.
- Add explicit source/type semantics and buyer ownership.
- Add private invoice/line evidence storage and authorization.
- Persist structured line specification.
- Implement local draft and reliable idempotent sync.
- Maintain Draft no-effect invariant.

### Phase D — Receiver integration
- Add separate invoice-linked receiving queue in Receiver.
- Capture actual accepted quantities and partial/short/over receipt outcomes.
- Post accepted quantities once through canonical inventory posting.
- Link buyer-car decrement and branch-stock increment atomically or through a transactionally safe operation.
- Preserve PO receiving workflow.

### Phase E — Buyer cash custody
- Add supported expense types and evidence rules.
- Reconcile physical acknowledgment, pending, approved, rejected and returned cash.
- Define GL accounts for fuel/transport/other with finance owner; do not invent mappings.
- Remove supplier/AP auto-payment coupling for non-supplier expenses.
- Add settlement proof and independent cash count.

### Phase F — Buyer vehicle custody ledger
- Confirm vehicle master strategy and buyer-to-vehicle assignment contract.
- Extend canonical movement architecture rather than adding an isolated shadow ledger.
- Add physical movement types and evidence.
- Connect Receiver and customer/operational issue flows.
- Add discrepancy and audit reports.

### Phase G — Intelligence and optimization
- Supplier/item price history and normalized quote comparison.
- Purchase recommendation by branch demand, available stock, allocated stock, sales velocity, lead time and minimum order constraints.
- Explain every recommendation with source data, freshness and confidence.
- No autonomous PO creation or posting without approval policy.

## 7. Acceptance and non-regression test matrix

1. Search finds a valid item beyond the first 500 records.
2. Exact barcode scan returns the canonical item and never creates a duplicate.
3. Zero/missing/stale cost is visibly marked and is never silently treated as a recommended price.
4. Adding/removing/updating invoice lines preserves item identity and recalculates totals correctly.
5. Offline draft survives app close/reopen and is visibly not posted.
6. Retrying a sync request does not create duplicate invoices, movements, expenses or attachments.
7. Private invoice and receipt images are accessible only to authorized company/role/document participants.
8. Draft invoice has zero stock, treasury, supplier-ledger and GL effect.
9. Partial receiving increases branch stock only by accepted quantity and reduces buyer-car balance by the same accepted quantity.
10. Rejected/short quantities remain traceable and do not silently post.
11. Buyer-car stock never derives from driver assignment, PO status or invoice status.
12. Custody expense submission/approval does not mark a supplier invoice Paid unless a distinct valid supplier payment event exists.
13. Fuel/transport/other expenses do not reduce supplier AP.
14. Cash returned is distinguished from cash merely claimed or approved.
15. Customer/operational issue from buyer car does not create a sale unless an explicit sales transaction is created.
16. Parent currency, company isolation, role permissions and shared gateway behavior remain intact.
17. Existing Picker, Receiver, PO, invoice Draft edit/delete and realtime non-regression tests pass.
18. Mobile field usability: one-hand navigation, readable sunlight contrast, no horizontal overflow, camera permission denial recovery, slow network and reconnect behavior.

## 8. Decisions requiring owner/finance/operations evidence before implementation

These are genuine contract decisions, not blockers to the UX design:
1. How to represent an unregistered market seller while `purchase_invoices.supplier_id` is currently mandatory.
2. Whether purchasing vehicles are registered in the existing vehicle master with a distinct vehicle purpose, or in a dedicated purchasing-vehicle assignment model. Existing delivery vehicles must not be assumed.
3. Who confirms supplier-to-buyer physical handover and what evidence is mandatory.
4. Whether one buyer may carry goods for multiple destination branches in one trip.
5. How customer-specific goods issued from buyer car are documented without automatically becoming a sale.
6. Finance-approved GL mappings for fuel, transport and other expenses.
7. Whether the quick invoice lifecycle uses a dedicated source/type plus receiving status, while remaining separate from generic supplier AP invoices.
8. What evidence and acknowledgment are required for cash issue, top-up and physical cash return.

Recommended default: design around explicit source/type and immutable physical events, keep Drafts non-posting, separate substantiation from payment, and never overload delivery-driver or Van Sales contracts.

## 9. Current completion statement

**Completed in LVE-586:** current Buyer source re-read; Picker comparison; tab-by-tab gap review; 500-record retrieval limitation confirmed; zero-cost default risk confirmed; field-first target experience defined; cross-system stock/cash/AP/GL invariants and phased acceptance plan documented.

**Not completed:** no Buyer code implementation, no Receiver change, no schema/RPC/Edge change, no production upload or posting, no browser E2E, and no deployment verification in this checkpoint. These must not be represented as done.

**Next executable engineering slice:** Phase A + the catalog server-search contract investigation. These can be developed as isolated, reviewable source patches without altering Production business contracts. The market invoice, custody and vehicle ledger phases must follow their explicit data-contract and accounting decisions.
