# Report619 — Buyer Custody / SupplierReturn / Quick Market RPC & Posting Contract

**Date:** 2026-11-04 — Africa/Cairo  
**Baseline:** Reports614–618; Production read-only snapshot 2026-11-04.  
**Status:** SERVER CONTRACT DESIGN / NOT IMPLEMENTED / NOT APPROVED FOR EXECUTION.

## 1. Design invariants

1. Cash custody and goods custody are separate ledgers.
2. A Draft invoice does not move stock, create AP, pay supplier or create a custody event.
3. A physical supplier-to-Buyer handover creates a Buyer goods custody event; no branch stock movement.
4. A warehouse-to-Buyer SupplierReturn dispatch decreases branch stock once and increases Buyer custody once.
5. Buyer-to-Warehouse acceptance decreases Buyer custody and increases branch stock only for accepted quantity.
6. Buyer-to-Supplier acceptance decreases Buyer custody only for supplier-accepted quantity.
7. Supplier AP/GL return posting occurs only for supplier-accepted quantity and only once.
8. A linked SupplierReturn has one physical stock writer and one financial return writer. The financial writer must not post stock.
9. Supplier Direct is the default recipient. Buyer Delegate is an explicit exception; no vehicle is required.
10. All operations are company/branch/role scoped, authenticated, server-validated and idempotent.
11. Corrections use compensating events; no posted event, stock movement, supplier ledger entry or journal row is deleted.
12. Company currency comes from `app_settings`; no SAR fallback or client-selected foreign currency.

---

## 2. Canonical document chain

| Business event | Canonical document | Physical/quantity effect | Financial effect |
|---|---|---|---|
| Create Quick Market invoice | `purchase_invoices` Draft | None | None |
| Supplier hands Quick Market goods to Buyer | `buyer_goods_custody_events` | Buyer custody + | None |
| Warehouse sends SupplierReturn to Buyer | `stock_vouchers` SupplierReturn | Branch stock − once; Buyer custody + | None |
| Supplier accepts Buyer-held return | `purchase_return_acceptances` | Buyer custody − accepted qty | Pending Finance approval |
| Finance posts accepted return | `purchase_return_acceptances` Posted | No stock movement | Supplier AP debit + balanced GL |
| Buyer hands Quick Market goods to Warehouse | `receiving` source QUICK_MARKET_INVOICE | Buyer custody − accepted qty; branch stock + once | Supplier AP credit + balanced GL |
| Buyer hands remaining custody to Warehouse | `receiving` source BUYER_CUSTODY | Buyer custody − accepted qty; branch stock + once | None |
| Supplier directly accepts Warehouse return | `stock_vouchers` + acceptance batch | Branch stock − actual supplier accepted qty | Pending Finance approval, then AP/GL debit |

Parent return case `purchase_returns` is the single register row for a SupplierReturn. It links to the physical voucher and can contain multiple supplier acceptance batches. The Parent table's recipient column still needs the owner-side patch; no `main.html` edit is included here.

---

## 3. Required RPC contracts

All new RPCs should be `SECURITY DEFINER`, use a fixed safe `search_path`, resolve the caller from `auth.uid()`, resolve company from the authenticated profile, and reject client-supplied actor/company identity. The exact full bodies must be assembled against the current live function definitions before deployment.

### 3.1 Read Buyer goods custody

`get_my_buyer_goods_custody(p_branch_id uuid DEFAULT NULL, p_cursor timestamptz DEFAULT NULL, p_limit integer DEFAULT 50) RETURNS jsonb`

Validations:
- authenticated user and active effective profile;
- user has Buyer/purchases access, or finance/authorized audit access;
- company derived from server profile;
- a Buyer sees only their own `custodian_user_id` rows; finance/audit sees authorized company scope;
- limit clamped to 1–100; cursor pagination.

Returns:
- `summary`: SKU count, units, pending warehouse, pending supplier, overdue count;
- `balances[]`: item, barcode, unit, branch, issued, accepted by supplier, accepted by warehouse, returned to warehouse, current quantity, age;
- `pending_actions[]`: source document, next valid action, quantity ceiling, status;
- `movements[]`: cursor-paged event history and evidence;
- `next_cursor`, `has_more`.

Do not derive balance in the browser from a limited 500-row query.

### 3.2 Record Quick Market physical handover

`record_quick_market_handover_atomic(p_invoice_id uuid, p_branch_id uuid, p_lines jsonb, p_operation_id text, p_evidence_path text DEFAULT NULL) RETURNS jsonb`

Validations:
- caller is the invoice's active assigned Buyer or authorized delegate;
- invoice belongs to caller's company, `source_type='QUICK_MARKET'`, `purchase_order_id IS NULL`, status Draft;
- supplier is active and invoice line IDs/items match;
- each quantity is positive and no greater than invoice line quantity not already handed over;
- branch is permitted;
- idempotency by company + operation ID + invoice line + event type.

Effects:
- append `QUICK_MARKET_SUPPLIER_TO_BUYER` positive event per line;
- no `stock_branches`, `inventory_log`, `supplier_ledger`, `journal_entries`, Treasury or cash-custody update;
- return current Buyer balance and source event IDs.

### 3.3 Create warehouse handover for Buyer-held goods

`create_buyer_custody_handover_atomic(p_branch_id uuid, p_lines jsonb, p_operation_id text) RETURNS jsonb`

Validations:
- caller is the custodian or authorized purchasing supervisor;
- requested item quantities do not exceed the current Buyer custody balance;
- source event lines are from the same company and compatible branch;
- branch is permitted.

Effects:
- create `receiving` header with `source_type='BUYER_CUSTODY'`, `buyer_user_id`, `branch_id`, operation ID and source document code;
- create `receiving_details` lines with item/event links and expected quantities;
- no stock movement or custody decrease yet; Receiving queue is pending.

### 3.4 Receive Buyer custody handover

`receive_buyer_custody_handover_atomic(p_receiving_id uuid, p_lines jsonb, p_operation_id text) RETURNS jsonb`

Validations:
- caller has Warehouse Receiving permission for the destination branch;
- receiving header is `BUYER_CUSTODY`, pending and company-scoped;
- accepted quantity per line is positive, no greater than presented quantity, and no greater than open Buyer custody;
- no line/event can be received twice.

Effects:
- post `BuyerCustodyReturnIn` inventory movement for accepted quantities only;
- append negative `BUYER_TO_WAREHOUSE` event for accepted quantities;
- update Receiving detail/header and stock exactly once;
- rejected quantity remains in Buyer custody;
- no supplier AP, supplier payment, cash or GL effect.

### 3.5 Receive Quick Market invoice by invoice ID

`receive_quick_purchase_atomic(p_invoice_id uuid, p_branch_id uuid, p_lines jsonb, p_operation_id text) RETURNS jsonb`

Validations:
- caller has Warehouse Receiving permission for branch;
- invoice is same company, `source_type='QUICK_MARKET'`, no PO, status Draft/Posted according to partial receipt state;
- every invoice line is linked to Buyer custody event(s);
- accepted quantity is positive, not above invoice outstanding quantity or Buyer custody balance;
- no duplicate line receipt; operation ID idempotent.

Effects:
- create Receiving header `source_type='QUICK_MARKET_INVOICE'`, invoice FK, branch, source document code;
- create Receiving details with invoice-line FK and item ID;
- post PurchaseIn movement for accepted quantities only;
- append negative Buyer custody event for accepted quantities;
- post Supplier AP credit and balanced Inventory/AP journal for accepted quantity only;
- insert supplier-ledger credit keyed by invoice code + receipt operation;
- set invoice status Posted after first accepted receipt; `is_received` true only when all lines are fully received; `received_date` set only when fully received;
- no Treasury cash movement. If invoice was cash-paid by Buyer, Accounts later clears the AP through the existing Buyer cash-custody payment workflow.

Preserve existing PO `receive_purchase_atomic` unchanged.

### 3.6 Create SupplierReturn case from Warehouse voucher

`create_supplier_return_case_from_voucher_atomic(p_stock_voucher_id uuid, p_recipient_mode text, p_recipient_user_id uuid, p_operation_id text) RETURNS jsonb`

Validations:
- source voucher is SupplierReturn Draft, same company and supplier/branch;
- recipient mode is Supplier Direct or Buyer Delegate;
- Buyer Delegate requires active same-company Purchasing Officer, purchases permission and branch scope;
- source detail lines/qty/items are valid;
- one unique purchase_returns row per stock voucher.

Effects:
- create `purchase_returns` row with `stock_voucher_id`, nullable invoice link, recipient mode and recipient user;
- create return details linked to exact stock-voucher detail lines;
- set voucher `recipient_mode` and `custodian_user_id`;
- no stock/AP/GL/custody effect while Draft.

### 3.7 Send SupplierReturn to recipient

Use the existing `send-stock-voucher` Edge function and existing atomic path; do not create a new Edge function.

The existing stock-voucher send RPC must be extended atomically:
- validate voucher Draft, SupplierReturn, recipient mode and permissions;
- for Supplier Direct, `issued_qty` is the actual quantity accepted by supplier at handover; no Buyer custody event;
- for Buyer Delegate, `issued_qty` is actual quantity physically handed to Buyer; post branch stock-out once and append positive `WAREHOUSE_TO_BUYER` events;
- no supplier AP/GL effect at dispatch;
- retries return the existing operation result without duplicate stock/event rows.

### 3.8 Record supplier acceptance batch

`record_supplier_return_acceptance_atomic(p_return_id uuid, p_lines jsonb, p_supplier_receipt_ref text, p_evidence_path text, p_operation_id text) RETURNS jsonb`

Validations:
- Buyer Delegate: caller is assigned custodian or authorized manager.
- Supplier Direct: caller has warehouse/purchasing permission and supplier acceptance evidence.
- acceptance quantities positive and no greater than issued quantity less previous supplier acceptance and warehouse-return quantities.
- return case and supplier match; item/price/discount/tax are server sourced.
- evidence reference required for acceptance; idempotent operation.

Effects:
- create `purchase_return_acceptances` header and details;
- Buyer Delegate: append negative `BUYER_TO_SUPPLIER_ACCEPTED` custody events immediately for physically accepted quantities;
- Direct Supplier: no Buyer custody event;
- set return status `AwaitingFinance` or `PartiallyPosted` as appropriate;
- no AP/GL yet until finance approval.

### 3.9 Post accepted SupplierReturn financial batch

`purchase_post_return_acceptance_atomic(p_acceptance_id uuid, p_actor uuid) RETURNS jsonb`

Validations:
- existing `save-purchase-order` Edge v22 requires purchases + finance permissions;
- acceptance batch is AwaitingFinance and not previously posted;
- company currency equals app_settings currency;
- accepted quantities and amounts are derived from return lines, never trusted from client;
- source voucher/line link unique; no duplicate acceptance or AP/GL;
- linked physical voucher exists and already owns the stock movement.

Effects:
- supplier-ledger debit for accepted amount only;
- balanced journal entry using existing Supplier/AP and Inventory accounts;
- no `post_stock_movement` call for linked return;
- acceptance batch status Posted;
- aggregate `purchase_returns.accepted_amount` and status PartiallyPosted/Posted;
- all operation IDs and source references persisted.

Existing `purchase_post_return_atomic` must retain legacy unlinked behavior for any historical documents, but route linked cases through this accepted-batch financial-only path. Do not run both writers.

### 3.10 Currency contract

`save_supplier_return_contract`:
- resolve `app_settings.currency` by company server-side;
- reject payload currency mismatch;
- set `stock_vouchers.return_currency` from system setting;
- remove SAR fallback and SAR column default.

Both manual completion and purchase return posting must assert stored currency equals company currency before any ledger/journal write. No FX conversion is part of this task.

### 3.11 Cash custody review for Quick Market

Extend existing `buyer_custody_review_expense_atomic` with a separate no-PO branch:
- `source_type='QUICK_MARKET'`, `settlement_source='BUYER_CASH_CUSTODY'`;
- invoice ID and all invoice line Receiving evidence required;
- invoice must be fully received for full invoice settlement; partial invoices cannot settle full value;
- match supplier-ledger AP credit by invoice code, not PO code;
- preserve Finance/Finance Manager review and self-review prohibition;
- post Dr Supplier AP / Cr Employee Custody, create custody payment, supplier-ledger debit, mark invoice Paid;
- no direct Treasury cash movement; cash custody was already advanced to Buyer.
- Existing PO-linked branch and its PO/Receiving validation remain unchanged.

---

## 4. Existing Edge functions only

| Edge | New branch | Compatibility |
|---|---|---|
| `save-purchase-order` v22 | read Buyer ledger; create quick handover; record acceptance; finance-post acceptance; Quick Market expense review | existing PO/PR/RFQ/invoice/return/custody operations unchanged |
| `receive-purchase` v13 | `invoice_id` for Quick Market; separate buyer-custody handover mode if appropriate | existing `po_code` unchanged |
| `create-stock-voucher` v12 | Buyer Delegate recipient via existing `rep_id` | all other voucher types unchanged |
| `send-stock-voucher` v20 | SupplierReturn Buyer custody event / actual issued qty | Transfer, DirectSale, DirectReturn unchanged |
| `complete-stock-voucher` v4 | linked return status only; finance delegated to acceptance batch | legacy unlinked behavior preserved |

No new Edge Function. Source snapshots are archived in `Current/CTO/EdgeSnapshots/20261104/`.

---

## 5. Required Trigger/stock-movement changes

### `enforce_stock_voucher_custodian()`
- DirectSale/DirectReturn existing vehicle and rep logic unchanged.
- SupplierReturn Supplier Direct: no custodian.
- SupplierReturn Buyer Delegate: active same-company Purchasing Officer, purchases permission, branch scope, no vehicle required.
- Reject all invalid mode/custodian combinations.

### `post_stock_movement`
- Add `BuyerCustodyReturnIn` as a stock-in movement type only for accepted Buyer→Warehouse Receiving.
- Keep SupplierReturn stock-out as the only physical issue writer for linked warehouse return.
- Idempotency keyed by source document/line/operation.
- Verify stock branch balance and inventory_log consistency.

### Linked return completion
- `complete_manual_stock_voucher_atomic_core_20260828` must not independently post supplier ledger/GL when a linked `purchase_returns` record exists.
- It may complete physical document status only after all issued quantity is either supplier-accepted or warehouse-returned.
- `purchase_post_return_atomic` must not post stock for linked voucher cases.

---

## 6. Status model

### Buyer goods custody
- `PendingBuyerAcknowledgement`
- `InBuyerCustody`
- `PartiallyHandedToWarehouse`
- `AwaitingSupplierAcceptance`
- `PartiallyAcceptedBySupplier`
- `AwaitingFinance`
- `PartiallyPosted`
- `Resolved`
- `CorrectionRequired`

### SupplierReturn case
- `Draft`
- `InBuyerCustody`
- `AwaitingSupplierAcceptance`
- `AwaitingFinance`
- `PartiallyPosted`
- `Posted`
- `ReturnedToWarehouse`
- `Cancelled`

These statuses must be mapped to the current UI and status constraints only after checking every consumer. Do not mass-update legacy status values.

---

## 7. Acceptance and reconciliation tests

- Buyer custody event sum equals each custodian/item/branch balance.
- Warehouse issue quantity equals branch stock-out quantity and custody increase for Buyer Delegate.
- Supplier Direct has no Buyer event; issue qty equals supplier-accepted qty.
- Supplier acceptance quantity cannot exceed issued quantity less prior acceptance/warehouse return.
- Each acceptance batch posts AP/GL exactly once and no second stock movement.
- Buyer-to-Warehouse accepted quantity reduces custody and increases stock exactly once.
- Quick Market invoice Draft and physical handover do not create stock/AP/GL/treasury.
- Quick Market warehouse acceptance creates stock/AP/GL exactly once; cash custody review clears AP after complete receipt evidence.
- Existing PO receipt and PO cash-custody review remain byte-for-byte behaviorally compatible.
- Existing DirectSale/DirectReturn/Transfer unchanged.
- Realtime shows changes; cursor pagination works beyond 500 rows.
- Cross-company, cross-branch, wrong-role and unauthorized buyer tests denied.
- Retry, timeout, duplicate payload, concurrent acceptance and partial receipt tests are idempotent.
- Currency mismatch SAR vs EGP rejected at contract save and before financial posting.
- QA-labelled Draft pair remains excluded from production E2E; historical Posted SAR invoices are preserved.
- Stock, inventory_log, supplier_ledger, journal entries and employee cash custody reconcile.

---

## 8. Status / gate

This report defines the server-side RPC and posting contracts but does not include the complete replacement SQL function bodies or deployable Edge/source diffs. It is a design specification, not an implementation.

No Production DDL/RPC/Trigger/RLS/data write; no Edge deploy; no operational app source change; no E2E. Full function bodies, exact file diffs, test scripts and rollback must be assembled and approved under Report614_NEW_P / Master CTO §77.2 before any operational write.
