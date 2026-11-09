# Report672 — Buyer Custody Completion & SupplierReturn Partial-Acceptance Accounting Review

**Date:** 2026-11-09 (Africa/Cairo)  
**Status:** LVE670 cash/goods hardening and LVE671 SupplierReturn server authorization are confirmed in Production. The remaining SupplierReturn partial-acceptance lifecycle has been analyzed; it is not safe to close by changing only the existing completion trigger or Buyer ledger. No new operational code, SQL, Edge, deployment, or business data was changed in this review.

## 1. Verified current source and database state

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Latest observed operational commit: `c5251859bd360fbf69f9875a8bb482bbd667fe4c` — Buyer goods-custody summaries no longer add unrelated units together.
- Buyer source blob: `94e2e95d13d2d1aa8687a8c0d394a8508176137e`.
- LVE670 Production migration: `20261109154258_buyer_custody_cash_claim_and_ownership_balances_20261109`.
- LVE671 Production migration: `20261109155413_buyer_supplier_return_send_complete_role_scope_guards_20261109`.
- Both migration versions are present in `supabase_migrations.schema_migrations`.
- Latest observed GitHub combined status for `c525185`: no status checks were returned. This is not a pass.
- Cloudflare terminal Production deployment and served Buyer byte parity remain unverified; authenticated Buyer browser E2E remains unverified.

## 2. What is already implemented — do not repeat

### 2.1 Financial custody (LVE670)

- `buyer_custody_submit_quick_market_expense_atomic` counts both `Submitted` and `Approved` expense claims as committed cash.
- Invoice claim uniqueness is now scoped to active `PURCHASE_INVOICE` claims by company + invoice + receiving operation, allowing separate partial QMP receipts while preventing duplicate active claims for the same receipt.
- The PO-only submit path locks the invoice and preserves a single active claim rule.
- Buyer UI filters already-claimed receipt operations and refreshes custody when purchase orders change.
- The QMP settlement path remains distinct from supplier AP: after accepted warehouse receipt and Finance approval, it posts Inventory 124 against Employee Custody 127, not a second supplier payable/payment or Treasury movement.

### 2.2 Goods custody (LVE670)

- `buyer_goods_custody_get_balances_atomic` groups by custodian, branch, item, ownership class, supplier, and source document.
- Ownership classes remain separate: `SUPPLIER_OWNED`, `COMPANY_OWNED_SUPPLIER_RETURN`, and `UNCLASSIFIED`.
- Correction events inherit their root event's classification.
- Buyer UI has separate supplier-owned and company-owned SupplierReturn sections, source/supplier/evidence context, and a separate unclassified review section.
- The latest UI commit `c525185` removed aggregation of unlike UOM quantities; summary cards count groups and distinct suppliers instead.

### 2.3 SupplierReturn authorization (LVE671)

- `send_stock_voucher_atomic` and `complete_manual_stock_voucher_atomic` enforce SupplierReturn warehouse-management roles and branch scope server-side.
- The wrappers remain service-role-only; `anon` and `authenticated` direct EXECUTE are false.
- Existing Edge entry points remain `send-stock-voucher` v20 and `complete-stock-voucher` v4.
- Read-only role matrix: warehouse supervisor passes; Buyer and accountant do not pass the normal SupplierReturn management gate.

## 3. Confirmed remaining critical gap: partial supplier acceptance

The live SupplierReturn path is still full-quantity only:

1. `send_stock_voucher_atomic_core_20260828` posts the full SupplierReturn stock decrease from the source branch. The SupplierReturn custody trigger then records the full issued quantity as `WAREHOUSE_TO_BUYER_SUPPLIER_RETURN`.
2. `complete-stock-voucher` v4 accepts only a voucher code; it has no accepted-quantity, proof-file, acceptance-mode, or exception-note payload.
3. `complete_manual_stock_voucher_atomic_core_20260828` calculates return subtotal, discount, taxable amount, tax and net amount from the full original `stock_voucher_details` values, then posts supplier-ledger debit, journal and tax reversal for the full voucher.
4. `sync_supplier_return_buyer_custody_event` currently defaults null `received_qty` to full `qty`, and rejects any non-full acceptance.
5. Therefore changing only the custody trigger to allow partial `received_qty` would create a mismatch: custody could be reduced by a partial quantity while supplier ledger, tax and journal still reverse the full voucher amount.
6. Marking the voucher Completed after a partial acceptance would also leave the rejected remainder in Buyer custody without a distinct warehouse-return document and stock-in event.

## 4. Correct accounting and inventory contract

A safe completion must distinguish three quantities per source line:

- **Issued to Buyer:** quantity removed from warehouse stock when the SupplierReturn is sent; this creates the positive company-owned Buyer-custody event.
- **Accepted by Supplier:** quantity supported by supplier acceptance evidence (or a controlled Buyer-representation exception); this reduces Buyer custody and creates supplier credit / inventory credit / tax reversal only for that accepted quantity.
- **Returned to Warehouse:** rejected quantity physically handed back and accepted by the warehouse through a separate document; this increases warehouse stock and reduces Buyer custody. It must not create supplier credit or tax reversal.

The invariant for every line is:

`issued_qty = supplier_accepted_qty + warehouse_returned_qty + buyer_custody_open_qty`

No quantity may be accepted twice, returned twice, or exceed the remaining custody balance. The voucher cannot be finally closed while `buyer_custody_open_qty > 0`.

### Required atomic architecture

A complete implementation needs:

1. An append-only SupplierReturn acceptance header/lines (or equivalent operation ledger) with unique operation ID, source voucher/line, accepted quantities, acceptance actor, acceptance mode, proof path, mandatory exception note where applicable, and per-operation accounting references.
2. A SupplierReturn acceptance RPC that locks the source voucher and outstanding custody lines; validates cumulative accepted + returned quantities; records evidence; appends negative `BUYER_TO_SUPPLIER_ACCEPTED` events for only the accepted quantities; and posts supplier ledger, inventory credit, tax reversal and balanced journal for only that acceptance operation. Each acceptance must have its own immutable/idempotent financial source ID; reusing the original voucher ID for multiple journal/ledger postings is unsafe.
3. A separate Buyer-to-Warehouse return document and warehouse acceptance RPC. Only actual warehouse acceptance posts an inventory increase and negative `BUYER_TO_WAREHOUSE_RETURN` event. The document must work without a vehicle and must preserve the originating SupplierReturn line.
4. A finalization guard that closes the original SupplierReturn only when all issued quantities have been accounted for as supplier-accepted or warehouse-returned. Existing full-quantity completion must not post a second full supplier credit after incremental acceptance postings.
5. A controlled Buyer-as-supplier-representative exception: only the assigned receiver with effective purchases permission, mandatory exception note, and supplier proof may record it. Normal supplier acceptance must remain restricted to authorized warehouse/supplier-return roles.
6. Existing Buyer and warehouse UIs must expose the right actions and evidence without introducing a parallel or manually editable balance. All balances remain derived from append-only events.

## 5. External ERP control comparison

The design follows the separation used by established systems:

- ERPNext Purchase Receipt records accepted and rejected quantities separately; accepted stock is posted to its warehouse and rejected stock is isolated. A Purchase Return removes only the selected physical quantity. A supplier Debit Note reverses the billed payable separately from the stock movement. References:
  - https://docs.frappe.io/erpnext/purchase-receipt
  - https://docs.frappe.io/erpnext/purchase-return
  - https://docs.frappe.io/erpnext/debit-note
- Microsoft Dynamics 365 Product receipt permits line-level quantity adjustments and creates a separate receipt journal; purchase returns use negative quantities and their own product-receipt journal:
  - https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/product-receipt-against-purchase-orders
  - https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order

These references support the rule that physical acceptance, supplier financial credit, and return-to-warehouse are separate but linked events.

## 6. Production safety and verification

- This review used read-only Production inspection.
- No Production voucher was sent/completed, no supplier balance or journal was posted, no stock movement was made, and no custody event was created.
- No synthetic business data was inserted.
- Staging remains out of schema/security parity and is not a valid substitute without a full parity and policy review.
- A production change to the partial-acceptance path is not considered verified until the full atomic flow is tested against a disposable, rollback-safe voucher fixture and reconciles all three quantities and every accounting/stock ledger.

## 7. Next execution checkpoint

**LVE672 — forensic accounting review complete; LVE670/LVE671 preserved; SupplierReturn partial acceptance remains OPEN.**

Do not patch only `sync_supplier_return_buyer_custody_event`, do not set `received_qty` to a partial value and call the existing completion RPC, and do not reuse the original voucher ID for multiple financial postings. Implement the acceptance ledger and separate warehouse-return document as one coordinated, idempotent cross-ledger change, then verify source, database, Edge, Buyer UI, warehouse UI, role denials, and accounting/stock reconciliation before declaring closure.
