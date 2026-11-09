# Report674 — Buyer Quick-Market Goods Custody & Direct Supplier Return Forensic Review

**Date:** 2026-11-09 (Africa/Cairo)  
**Status:** Forensic review completed. No operational application, Edge Function, schema, RPC, or production business-data writes were made. Exact implementation remains behind the explicit Owner ChangeSet gate in the governing operating instructions.

## 1. Scope and verified baseline

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Latest operational commit observed: `da37cbd27c0fd363bff95008919baee79622b654`.
- Buyer file: `companies/company-1/purchasing/buyer.html`.
- Buyer blob SHA: `072710c9db0184b0744eebd027fcdd3daf297269` (2,125 lines; 238,242 characters).
- Parent `main.html` was inspected through the already-open GitHub source tab because the GitHub file-fetch endpoint returned an empty payload for this 2.1 MB file.
- Production Cloudflare Pages dashboard showed project `rawaea-erp`, Production / `main`, deployment `4036153b-5400-476e-a35a-74c2a7231480`, linked to operational commit `da37cbd`. This confirms the current deployment pointer, not authenticated Buyer runtime behavior.
- Active Supabase Edge Functions: `save-purchase-order` v39 and `receive-purchase` v15.
- The connected browser was in Chat/read-only mode and exposed the Parent purchasing screen, not an authenticated Buyer PWA session. Authenticated Buyer E2E was therefore not run.

## 2. Production data snapshot — read-only

The Production SMART ERP database was queried without writes.

| Evidence | Current result |
|---|---|
| Quick-market invoice PINV-1002 | Draft, EMPLOYEE_CUSTODY, EGP 1,000, 3 lines, 20 total units, 0 received |
| Quick-market invoice PINV-1003 | Draft, EMPLOYEE_CUSTODY, EGP 430, 2 lines, 9 total units, 0 received |
| Buyer goods custody events | 0 rows |
| Purchase attachments linked to these quick-market invoices | 0 rows |
| Matching storage evidence objects | 0 rows |
| Purchase return documents | 0 rows |
| SupplierReturn stock vouchers | 0 rows |

No invoice, receipt, stock, custody, supplier, cash, treasury, or journal row was changed.

## 3. Root cause — confirmed

The Buyer UI's goods tab is the `vehicle` tab (`renderVehicleBalance`), distinct from the cash tab (`custody`). The goods balance RPC, `buyer_goods_custody_get_balances_atomic`, correctly aggregates append-only `buyer_goods_custody_events`; it does not derive physical possession from invoice headers.

A Quick Market invoice is created through `CREATE_QUICK_MARKET_INVOICE` / `purchase_create_quick_market_invoice_atomic`. Creating the invoice does not create a `SUPPLIER_TO_BUYER_QUICK_MARKET` custody event. The separate `recordQuickMarketHandover` UI action calls `REGISTER_QUICK_MARKET_HANDOVER`, requires a supplier handover evidence file and explicit quantity confirmation, and then writes the positive custody event through `buyer_goods_custody_register_handover_atomic`.

The two live invoices have no linked attachment, no storage evidence object, and no handover event. Consequently, the current confirmed goods balance is zero. This is not a rendering defect: the underlying physical custody event was never recorded. The current invoice-detail screen already contains an `إثبات استلام المورد` action when handover quantity remains, but it is presented as the modal's deny action rather than as a prominent first-class action.

**Important contract:** invoice creation alone must not assert physical custody. If the buyer actually received the goods, the system needs an explicit acknowledgement and evidence before increasing confirmed custody. The requested UX should make this step immediate and unmistakable, not silently infer possession from a draft invoice.

## 4. Supplier-return gap — confirmed

There is no supplier-return action or modal in the current Buyer `فواتيري` flow.

Two existing return flows were inspected and are not reusable for this case:

1. Parent purchasing `CREATE_RETURN` / `POST_RETURN`:
   - The modal selects invoices with status Posted / PartiallyPaid / Paid.
   - It only offers invoice lines with `received_qty > 0`.
   - The standard posting RPC performs a supplier return against branch inventory and the associated supplier/accounting path.
   - The two Buyer Quick Market invoices are Draft and have zero warehouse receipt, so this flow excludes them and its stock/accounting semantics would be wrong.

2. Warehouse `SupplierReturn` stock voucher:
   - Its source is a branch and its destination is a supplier.
   - Its custody trigger handles company-owned branch stock routed through a buyer to the supplier.
   - It is not a return of supplier-owned Quick Market goods still held by the buyer.

The Buyer needs a distinct physical return operation tied to the original Quick Market invoice and invoice line.

## 5. Cross-module dependency findings

- `buyer_goods_custody_get_balances_atomic` currently classifies `BUYER_TO_SUPPLIER_ACCEPTED` as `COMPANY_OWNED_SUPPLIER_RETURN` without distinguishing the source document. The same event type can be used for the new Buyer-held return only if classification becomes source-aware: `PurchaseInvoice` source = supplier-owned; `StockVoucher` source = company-owned supplier return.
- `get_quick_market_receiving_queue_atomic` calculates `handover_available` and `remaining_to_receive` from `SUPPLIER_TO_BUYER_QUICK_MARKET` and `BUYER_TO_WAREHOUSE_ACCEPTED` only. A direct supplier-return event must also be deducted there, or returned goods could still appear available to the warehouse. Its second balance subquery also needs the same custodian and branch scope already present in its first subquery.
- `receive_quick_market_purchase_atomic` applies the same two-event balance rule. It must include the direct supplier-accepted return event, or a returned unit could be received into branch stock later.
- `buyer_goods_custody_get_invoice_handover_progress_atomic` currently reports handover progress, not net returnable custody. The Buyer return modal can obtain the authoritative net balance from `GET_BUYER_GOODS_CUSTODY_BALANCES`; if the invoice-detail view needs a per-line summary, it should derive it from the same event ledger rather than from invoice quantity alone.
- The event ledger already contains the required audit fields: operation ID, source document and line, related document, actor, custodian, evidence path, notes, and payload fingerprint. Its existing event type `BUYER_TO_SUPPLIER_ACCEPTED` and uniqueness/idempotency constraints can represent the direct return without creating a second inventory ledger.

## 6. Required design for the Owner ChangeSet

### 6.1 Handover visibility

- Keep confirmed goods balance event-based.
- In the Buyer goods tab, add a separate, clearly labelled list of Quick Market invoice quantities **awaiting physical handover confirmation**. These are not included in confirmed custody.
- Promote `إثبات استلام المورد` to a clear primary action in invoice details.
- If the owner wants the quick-purchase workflow to complete handover immediately, add an explicit physical-receipt acknowledgement plus handover evidence to the save flow; do not infer possession from invoice creation alone.
- For PINV-1002 and PINV-1003, do not backfill custody automatically. Their evidence and handover events are absent. Use the existing handover flow after the buyer supplies valid evidence.

### 6.2 Direct supplier return

Add a Buyer-only modal in `فواتيري`, available only for positive net custody on a Quick Market invoice line. It must:
- show invoice, supplier, item, unit, original quantity, warehouse-accepted quantity, supplier-returned quantity, and current returnable custody;
- allow partial return by line, never above current net custody;
- require a return reason and supplier acceptance evidence;
- use an idempotent operation ID and verify ambiguous outcomes before retrying;
- record a negative `BUYER_TO_SUPPLIER_ACCEPTED` event whose source is the original `PurchaseInvoice` and source line, and whose related destination is the supplier;
- show the accepted return in the invoice's movement history and immediately refresh the goods balance;
- never call the Parent `POST_RETURN` path or the warehouse `SupplierReturn` stock-voucher path for these buyer-held goods.

### 6.3 Financial and stock boundaries

The direct Buyer-held return is a physical custody event only:
- no branch stock movement, because the goods never entered branch stock;
- no supplier payable or supplier-ledger adjustment from this custody event alone;
- no journal, Treasury, or cash-custody mutation;
- if the supplier actually refunds cash, record it through the separate cash-return workflow;
- if a credit note is issued, post it through a separate authorized financial document when the source invoice has the corresponding financial liability.

This prevents a Draft EMPLOYEE_CUSTODY invoice from generating an unsupported supplier credit or inventory issue.

### 6.4 Minimal technical scope

- One new RPC in the existing SMART ERP database for registering the direct Quick Market supplier return.
- Surgical source-aware classification update to `buyer_goods_custody_get_balances_atomic`.
- Surgical available-quantity update to `get_quick_market_receiving_queue_atomic` and `receive_quick_market_purchase_atomic`.
- One new operation branch in existing `save-purchase-order` (no new Edge Function).
- Buyer-only invoice-detail action/modal and the pending-handover panel.
- No new table is required if the existing append-only event ledger is used as the return-operation record.
- Do not alter the existing warehouse SupplierReturn trigger or Parent purchase-return posting path.

## 7. Competitive process check

- Microsoft Dynamics 365 documents return purchase orders for goods sent back to a vendor, including partial returns and cases where an invoice exists before receipt; it separates creating the return order from confirming and recording shipment. See [Create a purchase return order](https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order).
- Odoo documents vendor returns as stock movements from stock to the vendor location, with inventory value removed; vendor credit notes are a separate financial document. See [Inventory valuation — Vendor returns](https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/inventory_valuation/operations_valuation.html) and [Manage vendor bills](https://www.odoo.com/documentation/saas-16.3/applications/inventory_and_mrp/purchase/manage_deals/manage.html).

Applied principle: record the physical return against the original invoice and current custody; do not create a branch stock issue or financial credit when the goods never entered branch stock and the source invoice is still Draft.

## 8. Verification status

**PASS — read-only/source checks**
- Buyer source and relevant UI methods inspected.
- Current deployed Cloudflare Production pointer matches commit `da37cbd`.
- Active Edge Function versions checked.
- Relevant Production tables, functions, triggers, event constraints, and receiving queue logic inspected.
- Current invoice/custody/evidence counts independently queried.

**NOT RUN / NOT CLAIMED**
- No source patch was applied.
- No SQL function was changed.
- No production data was written.
- No authenticated Buyer browser E2E was run.
- No post-change test or deployment verification can be claimed.

## 9. Approval gate and next action

The governing operating instructions require a specific Owner ChangeSet review before modifying the operational Buyer app or Production SQL. The user's broad task authorization does not replace review of the exact patch. Therefore this report records the verified defect and implementation boundary; it does not claim the application is fixed.

Next step: prepare the complete Owner ChangeSet with full replacement SQL definitions, the exact Edge branch, the exact Buyer UI insertion/replacement, static checks, an isolated rollback-safe test fixture, and rollback instructions. Only after that exact ChangeSet is approved may the operational file and Production RPCs be changed.

## 10. Rollback and data safety

No rollback is needed because this review made no operational or database changes. For the future approved implementation, test only with isolated fixture data; never create test handovers, returns, stock receipts, supplier credits, cash receipts, or journals against live business invoices. Any correction to a committed custody event must use an explicit reversal event, not deletion or silent mutation.
