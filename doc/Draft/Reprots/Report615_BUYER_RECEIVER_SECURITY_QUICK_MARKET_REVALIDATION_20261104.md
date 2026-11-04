# Report615 — Buyer Custody / Receiver / Procurement Returns — Production Revalidation & Competitive Design

**Date:** 2026-11-04 — Africa/Cairo  
**Baseline:** LVE614 / Report614; operational source HEAD `e8ab54c75572e15e71581212479d22be139c8020`.  
**SMART ERP:** Supabase Production `fiilmooggumokxanwiyx`.  
**Status:** FORENSIC REVALIDATION COMPLETE / ADDITIONAL P0-P1 DEFECTS CONFIRMED / IMPLEMENTATION CONTRACT REFINED / NO PRODUCTION OR OPERATIONAL SOURCE WRITES.  
**Scope:** Buyer `رصيدي`, Warehouse manual SupplierReturn, Receiver, Quick Market invoices, cash-custody settlement, Parent purchase-return register, and procurement security.

---

## 1. Executive decision

Report614's central finding remains valid: Buyer `رصيدي` is not yet a live goods-custody ledger, and SupplierReturn has no Buyer-held stage. This revalidation adds four material findings:

1. **Receiver detail query is incompatible with Production schema.** The UI filters `purchase_order_details` by `po_code`, but the live table contains `po_id` and no `po_code`. The canonical RPC also joins by `po_id`. The Receiver UI must resolve the PO header ID first, then query detail rows by `po_id`.
2. **Direct DML is exposed on the Parent purchase-return tables.** `anon` and `authenticated` have INSERT/UPDATE/DELETE grants on `purchase_returns` and `purchase_return_details`; both tables have permissive `ALL` policies granted to `public`, scoped only by company. This creates a write path that bypasses the intended permission-gated Edge/RPC lifecycle. Restrict writes to the authorized server-side RPC/Edge path and keep client SELECT only.
3. **The current Buyer cash-custody review RPC cannot settle a Quick Market invoice.** `buyer_custody_review_expense_atomic` requires a valid PO, requires receiving by PO code, and matches supplier ledger credit by PO code. This is why a no-PO quick invoice cannot complete the approved invoice + warehouse receipt + accounts settlement path.
4. **Production has a small legacy/QA purchasing data set with inconsistent state.** Two historical no-PO invoices are Posted in SAR and have stock/AP/GL records; a separate explicitly QA-labelled Draft PO/invoice pair has `qty_received=5` / `received_qty=5` but no Receiving header/lines, no PurchaseIn movement, no supplier-ledger/journal/payment effect, and no voucher. Do not rewrite the two posted invoices. The QA-labelled Draft pair is isolated from stock/finance but is linked to four purchase-document-link rows and one status-history row; it should be cancelled/archived through an approved cleanup path, not hard-deleted blindly.

No production row was changed or deleted in this review.

---

## 2. Source and deployed Edge parity

### 2.1 Operational source

- Repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- HEAD observed: `e8ab54c75572e15e71581212479d22be139c8020`.
- Buyer: `companies/company-1/purchasing/buyer.html`, blob `311f2673a90149df6f56d59a9a187a3379e6981c`, 1181 lines.
- Warehouse vouchers: `companies/company-1/warehouse/vouchers.html`, blob `85e709d0f41c189c6624a6160965d3b1a41960ba`, 6676 lines.
- Receiver: `companies/company-1/warehouse/receiver.html`, blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`, 351 lines.
- Parent `main.html`: current blob `f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca`; still protected by the current governance lock.

### 2.2 Exact deployed Edge snapshots recovered

The following deployed functions were retrieved from Production and archived under `Current/CTO/EdgeSnapshots/20261104/`. These are byte-for-byte source snapshots, not deployments or functional changes.

| Function | Live version | Deployed source SHA-256 | JWT |
|---|---:|---|---|
| `save-purchase-order` | 22 | `a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb` | true |
| `receive-purchase` | 13 | `50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc` | true |
| `create-stock-voucher` | 12 | `c4ee58c5c94538bcb02a2a76c247996fa9368be7c5b2f7b4d44c98336d29ea4d` | false |
| `send-stock-voucher` | 20 | `864129274b4a23d74b3378c44d8fbf8f2a269eb76d9b623350ad57c818c8805b` | true |
| `receive-stock-voucher` | 22 | `62f6e97936997ab0ab58379bb683a08431eb2a5c96d1063943e5a3e03d24bf29` | true |
| `complete-stock-voucher` | 4 | `8cf684456cd82f4f331c909ad4adf5afaf1ad46ffa34d9927fded06276fed855` | true |

- The deployed `save-purchase-order` v22 `index.ts` is byte-identical to the tracked operational repository file.
- `receive-purchase` v13 and the four stock-voucher Edge sources were not present as matching tracked source paths in the operational repository; the exact deployed sources are now archived for controlled patching.
- No new Edge Function was created and no deployed Edge function was changed.

Snapshot index: `Current/CTO/EdgeSnapshots/20261104/README.md`.

---

## 3. Receiver — new confirmed UI/schema defect

### 3.1 Production schema

The live `purchase_order_details` columns include:
- `id`
- `po_id`
- `item_id`
- `item_code`
- `item_name`
- `unit`
- `qty_ordered`
- `unit_price`
- `qty_received`

There is **no `po_code` column** on this table.

### 3.2 Current Receiver code

Current `loadPODetails(i, code)` calls:

```js
supabase.from('purchase_order_details')
  .select('item_code, item_name, qty_ordered, unit')
  .eq('po_code', code)
```

This does not match the Production schema. The current canonical SQL receipt RPC correctly joins purchase-order detail rows by `pd.po_id=po.id`. The Receiver UI must resolve the selected `purchase_orders.id` using `po_code`, then query detail rows by `po_id`.

Additional precision defect:
- `submitReceiving()` currently uses `parseInt` for received quantities. This truncates fractional quantities even though SQL quantities are numeric. Change to validated `Number`, retain decimal precision, and use a suitable decimal input step.

**Impact:** This is a P0 receiving UI/data-contract defect. It must be fixed and regression-tested before using Receiver E2E as evidence of a successful PO receipt.

---

## 4. Buyer and Quick Market — current exact gaps

### 4.1 Buyer goods custody

Current Buyer source still shows:
- `renderVehicleBalance` as a static explanatory placeholder, not a database-backed ledger.
- `quickPurchase()` as an alias for `createPurchaseInvoice()`.
- `createPurchaseInvoice()` creates a Draft invoice, optionally linked to a PO; it does not create a supplier-to-Buyer physical handover.
- `startRealtime()` listens to cash-custody tables and purchase documents but has no Buyer goods-custody event source.

The cash-custody module remains a separate domain:
- `buyer_custodies` is cash issued to an employee.
- `buyer_custody_expenses` and `buyer_custody_payments` record expense review and supplier payment from custody.
- These tables must not be repurposed for item/quantity custody.

### 4.2 Quick Market invoice creation and posting

Production `purchase_create_invoice_atomic`:
- correctly reads system currency from `app_settings`;
- rejects a client-supplied currency that differs from system currency;
- permits `purchase_order_id IS NULL`;
- always creates a Draft invoice.

Production `purchase_post_invoice_atomic`:
- for PO-linked invoices, requires a completed Receiving record and matches invoice lines to received PO quantities;
- explicitly rejects a no-PO invoice with `PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED`, directing the workflow to a warehouse receipt first.

This is directionally correct, but no complete invoice-ID Receiving path currently exists:
- `receiving` has no `purchase_invoice_id` or source type;
- `receiving_details` has no `purchase_invoice_detail_id`;
- `receive-purchase` v13 accepts `po_code` only;
- Buyer cash-custody review requires a PO and validates Receiving by PO code.

### 4.3 Cash-custody settlement contract

Current `buyer_custody_review_expense_atomic`:
- requires Finance/Finance Manager and forbids self-review;
- requires invoice status Draft and exact invoice/expense total match;
- requires a valid PO;
- requires a completed Receiving header by PO code and receipt lines for every invoice line;
- validates the invoice against PO quantities, unit prices, discounts and tax;
- validates supplier AP credit by PO code;
- posts Dr Supplier AP / Cr Employee Custody, records a custody payment, marks the invoice Paid and writes the supplier-ledger debit.

This is an appropriate control for the PO path, but it cannot settle a no-PO Quick Market invoice. The new contract must preserve this exact PO validation branch and add a separate Quick Market branch keyed to invoice ID and invoice-line receiving evidence.

---

## 5. Production data reconciliation — read-only snapshot

### 5.1 Current row counts

| Dataset | Rows |
|---|---:|
| `stock_vouchers` | 0 |
| `stock_vouchers` where type = SupplierReturn | 0 |
| `purchase_returns` | 0 |
| `inventory_log` SupplierReturn movements | 0 |
| `buyer_custodies` | 0 |
| `purchase_invoices` | 3 |
| `purchase_invoice_details` | 6 |
| `purchase_orders` | 1 |
| `purchase_order_details` | 1 |
| `receiving` | 0 |
| `receiving_details` | 0 |
| `buyer_custody_expenses` | 0 |

### 5.2 Legacy posted no-PO invoices

Two historical invoices are Posted, have no PO, have `is_received=true`, currency SAR, and a combined invoice quantity of 50. Their matching `PurchaseIn` inventory log rows total 50 units, each has a supplier-ledger entry, and each has a Posted `PurchaseInvoice` journal entry.

- These are already-posted financial/inventory documents.
- They must not be deleted, rewritten to EGP, or re-posted as part of the new workflow.
- Their historical SAR currency must be preserved unless Finance approves a formal historical-currency correction. Current system currency is EGP; this does not authorize retroactive currency conversion.

### 5.3 Explicitly QA-labelled Draft pair

A separate `QA-SR`-labelled Draft PO/invoice pair exists:
- PO status Draft; invoice status Draft.
- One PO line: ordered 5, `qty_received=5`.
- One invoice line: qty 5, `received_qty=5`; invoice `is_received=true` but `received_date` is null.
- No Receiving header or details.
- No inventory movement referencing this PO/invoice.
- No supplier-ledger, journal, payment allocation, purchase return, custody expense or stock-voucher reference.
- No attachment.
- Four `purchase_document_links` and one status-history row exist.

This is an isolated QA artefact with inconsistent receiving flags, but the linked document graph and history must be preserved. Recommended cleanup is an authorized Cancel/Archive workflow that retains audit history; do not hard-delete it or change `qty_received` by direct SQL.

### 5.4 PO receipt state conflict

The only PO remains Draft even though its one line shows 5 units received. There is no Receiving document and no matching PurchaseIn movement. The related Draft invoice also has `is_received=true` without a receipt date. This is not an acceptable completed receipt state.

**Action:** quarantine this QA pair from E2E, preserve evidence, and add a reconciliation guard that prevents `qty_received` / `is_received` flags from being treated as proof of warehouse receipt without the canonical Receiving document and inventory movement.

---

## 6. Security finding — Parent return tables

Current Production grants show:
- `anon`: INSERT / UPDATE / DELETE on `purchase_returns` and `purchase_return_details`.
- `authenticated`: INSERT / UPDATE / DELETE on the same tables.
- RLS is enabled, but each table has a permissive `ALL` policy for `public`, checking only `company_id = app_private.current_user_company_id()`.

This means any authenticated user who resolves to the company context can write return headers/details directly, without the `save-purchase-order` Edge permission checks or the intended `purchase_create_return_atomic` / `purchase_post_return_atomic` business lifecycle.

Required correction:
- revoke direct INSERT/UPDATE/DELETE from `anon` and `authenticated` for both tables;
- replace broad `ALL` policies with authenticated SELECT-only policies restricted to the company and authorized procurement/finance/reporting roles;
- keep writes through the authorized existing Edge/RPC path;
- explicitly grant only the required read and server-side privileges;
- regression-test Parent reads, `save-purchase-order` create/post/cancel, and RLS.

The same review observed DML grants on several other transaction tables whose RLS policies currently provide SELECT only. Those grants should be reviewed table by table; do not apply a blanket revoke without checking all existing writers.

---

## 7. SupplierReturn — refined one-writer design

### 7.1 Current deployed mechanics

- `send_stock_voucher_atomic_core_20260828` posts a `SupplierReturn` movement for the full `stock_voucher_details.qty` and marks the voucher Sent.
- `post_stock_movement` accepts `SupplierReturn` as a source-branch stock-out type.
- `complete_manual_stock_voucher_atomic_core_20260828` currently posts supplier-ledger debit, GL journal and tax transaction for the full calculated return amount.
- `purchase_post_return_atomic` independently posts `SupplierReturn` inventory movement, supplier-ledger debit and journal entry from `purchase_returns`.
- No unique link currently ties the two documents together.

### 7.2 Canonical ownership

Use one canonical Parent return case (`purchase_returns`) linked to the Warehouse physical voucher:
- `purchase_returns` is the Parent-visible return case and the commercial/financial return header.
- `stock_vouchers` is the physical warehouse dispatch document.
- A unique `stock_voucher_id` link ties the two; a line-level FK links return lines to stock-voucher detail lines.
- Warehouse dispatch is the only branch stock-out writer.
- Buyer goods custody events are the only Buyer balance writer.
- Supplier acceptance batches are the only trigger for supplier AP/GL return posting.
- For a linked return, `purchase_post_return_atomic` must not call `post_stock_movement`; it posts only the accepted financial quantity. The manual-voucher completion path must delegate to or respect that single financial writer and must not duplicate supplier ledger/GL.
- Legacy unlinked return paths must remain separately identifiable and be preserved until reconciled; never silently reinterpret a legacy posted return.

### 7.3 Recipient model

- Default `recipient_mode='SUPPLIER_DIRECT'`; no Buyer custodian is required.
- Exception `recipient_mode='BUYER_DELEGATE'`; require a validated active same-company Purchasing Officer and preserve `custodian_user_id`.
- No Vehicle is required for either route.
- Keep DirectSale/DirectReturn vehicle and direct-sales-representative checks byte-for-byte in behavior.
- Parent `المستلم` derives from the linked recipient mode: validated Purchasing Officer for Buyer Delegate; Supplier for Direct Supplier. Never use `created_by` as recipient.

### 7.4 Partial acceptance and custody

- Record actual warehouse-issued quantity separately from requested quantity.
- For Buyer Delegate, issue to the Buyer once; Buyer custody increases by the issued quantity.
- Each supplier acceptance batch decreases Buyer custody only by the accepted quantity and posts the linked financial return only for that accepted quantity.
- Unaccepted quantity remains in Buyer custody.
- If the Buyer returns unaccepted goods to the warehouse, a separate accepted warehouse-return event decreases Buyer custody and increases branch stock once.
- For Direct Supplier, the physical issue quantity must be the quantity actually accepted by the supplier at handover; no Buyer custody event is created.
- Every batch has evidence, actor, timestamp and unique operation ID. Replays must be idempotent.

---

## 8. Competitive reference and design implications

The target contract follows the document-chain patterns used by mature ERP products rather than treating returns as a single status update:

- **Microsoft Dynamics 365 Supply Chain Management:** return purchase orders support returns from invoices, partial returns, unplanned receipts and consignment/buyback cases. The process records return shipment/product-receipt journals and vendor credit-note references. <https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order>
- **SAP S/4HANA Advanced Returns Management:** supplier return flows link a returns PO, outbound delivery, goods issue and vendor credit memo; inspection and logistical follow-up are explicit stages, with document-flow visibility. <https://help.sap.com/docs/SAP_S4HANA_CLOUD_PE/af9ef57f504840d2b81be8667206d485/cff87e426fed4ad9b3b0929aea4dedf6.html> and <https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/af9ef57f504840d2b81be8667206d485/666259fa030b4b959991a99b45e85e00.html>
- **Odoo Inventory:** two-step receiving separates supplier/input custody from final stock availability; the receipt is validated before the goods enter the stock location. This is the closest operational analogue for Buyer-held goods followed by Warehouse acceptance. <https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/inventory/shipping_receiving/daily_operations/receipts_delivery_two_steps.html> and <https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/inventory/shipping_receiving/daily_operations.html>
- **Microsoft Dynamics 365 invoice/receipt controls:** the platform prevents a posted receipt from being reduced below invoiced quantity and directs corrections through credit notes or return orders, protecting inventory valuation and accrued liability. <https://learn.microsoft.com/en-us/troubleshoot/dynamics-365/supply-chain/procurement/cant-correct-product-receipt-quantity-below-invoiced>

**RAWAEA implication:** preserve the business document chain and separate custody stages. Do not make a single Buyer balance field responsible for stock, AP and cash. The Buyer ledger is derived from posted item-level custody events; inventory and finance remain their own ledgers.

---

## 9. Target Buyer UX

The `رصيدي` tab should become **بضاعة في عهدتي — لا يشترط وجود سيارة**.

### Summary
- إجمالي الأصناف.
- إجمالي الوحدات في الحيازة.
- بضاعة بانتظار تسليم المخزن.
- مرتجعات بانتظار قبول المورد.
- حركات متأخرة / فروق تحتاج إجراء.

### Actions
- `استلام مرتجع من المخزن`.
- `تسجيل شراء سوق واستلامه`.
- `تسليم للمخزن`.
- `تسليم مرتجع للمورد`.

### Ledger
Each line shows item/barcode, unit, received, warehouse accepted, supplier accepted, returned to warehouse, current custody and age. Search by name/code/barcode. Every row opens the source document and evidence timeline. Vehicle is optional transport metadata only.

### Safety UX
- Do not display fabricated zero if the ledger read fails.
- Hide cost price by default; show purchase/return value only to finance-authorized roles.
- Disable actions when the quantity has already been posted or accepted.
- Partial acceptance leaves the remaining quantity visible in custody.
- Empty state explains the next valid action and offers the correct entry point.

---

## 10. Exact implementation package required

### Database
1. Add append-only `buyer_goods_custody_events` with company, branch, custodian, item, signed quantity, event type, source header/line, evidence, actor, operation ID and reversal reference.
2. Add `stock_vouchers.recipient_mode`, `stock_voucher_details.issued_qty`, and the accepted/returned quantity fields required for partial supplier handover.
3. Add `purchase_returns.stock_voucher_id` (unique), `recipient_mode`, `recipient_user_id`, nullable invoice reference for legitimate standalone returns, and accepted quantity/evidence fields on return details.
4. Add invoice source and settlement fields: `source_type` and `settlement_source`; legacy rows must remain `LEGACY_UNCLASSIFIED` until verified, not guessed from null PO.
5. Add `receiving.purchase_invoice_id`, `receiving.source_type`, `receiving.branch_id`, and `receiving_details.purchase_invoice_detail_id` / `item_id`.
6. Add explicit Buyer cash-expense category/payee/account mapping without repurposing `buyer_custodies`.
7. Add RLS, least-privilege grants, append-only enforcement, indexes, idempotency constraints and Realtime publication.

### RPC and existing Edge
1. Extend `enforce_stock_voucher_custodian()` for SupplierReturn Buyer Delegate only; preserve DirectSale/DirectReturn vehicle rules.
2. Extend the existing stock-voucher creation path to persist recipient mode/custodian.
3. Extend the existing send path to post actual issued quantities and create Buyer custody events atomically.
4. Extend the existing completion/return-posting paths so linked SupplierReturn has exactly one stock writer and one accepted-quantity financial writer.
5. Add invoice-ID quick receiving through the existing `receive-purchase` v13 function; retain the PO-code path unchanged.
6. Add a separate Quick Market branch to `buyer_custody_review_expense_atomic`; preserve current PO checks and add invoice/line Receiving validation for no-PO Quick Market.
7. Change `save_supplier_return_contract` to derive currency from `app_settings`; do not trust the browser's currency field.

### Application files
- Buyer: replace the static `renderVehicleBalance`; add the custody ledger, actions, evidence, quick purchase physical receipt, realtime and search.
- Vouchers: add Supplier Direct / Buyer Delegate recipient selector; the default remains Supplier; Buyer picker must be an active Purchasing Officer; no vehicle dependency.
- Receiver: fix `po_code` → PO ID / `po_id` detail query; add quick invoice receiving list and invoice-line receipt; use decimal-safe quantity parsing.
- Parent `main.html`: recipient column and unified return register are required but remain blocked by the active governance lock. No runtime injection or shadow Parent UI is allowed.

### Security
- Restrict direct DML on `purchase_returns` / `purchase_return_details`; authorized writes only through existing Edge/RPC business operations.
- Verify `auth.uid()`, effective profile, company, role, branch, quantity ceilings, source links, status transitions and idempotency in server-side functions.
- Do not expose another buyer's custody events or another company's data.

### Test and rollback
- Use schema-parity staging or an approved transaction-rollback test path that leaves no persistent Production rows.
- E2E: PO receipt, Quick Market no-PO receipt, Buyer Delegate SupplierReturn, Direct SupplierReturn, partial supplier acceptance, Buyer return-to-warehouse, custody settlement, duplicate replay, cross-company RLS, and legacy compatibility.
- Reconcile stock_branches to inventory_log; Buyer custody to event sum; supplier ledger to accepted return amount; journal debit/credit; employee custody to actual payments; and invoice received_qty to Receiving detail lines.
- Do not delete posted legacy invoices or rewrite historical SAR transactions.
- Any QA-labelled Draft pair cleanup must use an authorized cancel/archive path and preserve history.

---

## 11. Execution boundary and current result

### Completed in this continuation
- Read latest CURRENT_STATE, Report614, Report614_NEW_P and governing CTO documents.
- Revalidated live Buyer/Vouchers/Receiver source and current Production schema/RPCs/triggers/grants/policies.
- Recovered and archived exact deployed source for six existing Edge functions.
- Confirmed the Receiver `po_code` schema mismatch.
- Confirmed direct DML exposure on purchase-return tables.
- Confirmed Quick Market cash-custody review is PO-only.
- Reconciled the live purchasing rows and isolated the explicitly QA-labelled Draft pair from stock/AP/GL effects.
- Researched D365, SAP S/4HANA and Odoo official process documentation.

### Not performed
- No Production data was inserted, updated or deleted.
- No SQL migration, function, Trigger, RLS, grant or publication was changed.
- No Edge function was deployed or replaced.
- No operational Buyer/Vouchers/Receiver/Parent source was edited.
- No Cloudflare deployment or authenticated Browser E2E was performed.
- No claim of completed integration or production readiness.

### Governance gate
The permanent operating charter and Report614_NEW_P require the exact migration, complete RPC/Trigger definitions, exact source diffs, impact matrix, acceptance tests and rollback to be assembled and reviewed before operational writes. The user's direction to continue is being executed through source recovery, forensic work, design and preparation; it does not authorize guessing at irreversible stock/AP/GL behavior or bypassing the explicit change-set gate.

**Current status:** Buyer goods custody / Quick Market receipt / Parent recipient register remain OPEN / NOT IMPLEMENTED / NOT PRODUCTION READY. The additional P0/P1 defects are now evidenced and must be included in the single implementation package.
