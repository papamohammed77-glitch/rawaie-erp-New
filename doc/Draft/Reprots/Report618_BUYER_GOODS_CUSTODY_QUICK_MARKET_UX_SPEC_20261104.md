# Report618 — Buyer "رصيدي" and Quick Market UX/Integration Surgical Specification

**Date:** 2026-11-04 — Africa/Cairo  
**Baseline:** Buyer blob `311f2673a90149df6f56d59a9a187a3379e6981c`; Report615–617.  
**Status:** APPLICATION PATCH SPECIFICATION PREPARED / NOT APPLIED.

## 1. Current Buyer behavior verified

- `renderVehicleBalance()` is a static explanatory page. It does not read a live ledger.
- `quickPurchase()` is only `return this.createPurchaseInvoice()`.
- `createPurchaseInvoice()` creates a Draft invoice and allows optional PO; it has no physical Supplier → Buyer handover event.
- The quick-search result displays `cost_price` as "آخر تكلفة مرجعية" to the Buyer. This should be hidden by default; actual purchase price remains manually entered.
- Buyer Realtime currently subscribes to purchase docs, cash-custody tables, suppliers/items/branches/stock_branches; it does not subscribe to stock_vouchers or Receiving or a Buyer goods-custody event ledger.
- `renderCustody()` is the cash-custody screen and must remain separate and unchanged in meaning.

## 2. New functional boundary

Do not turn a Draft invoice into an inventory movement. The user-facing Quick Market flow must separate:
1. Draft supplier invoice entry.
2. Actual physical Supplier → Buyer handover.
3. Buyer → Warehouse handover.
4. Warehouse accepted/rejected quantities.
5. Accounts cash-custody settlement, only after the invoice and warehouse acceptance evidence reconcile.

A saved invoice alone creates no Buyer custody, branch stock, supplier AP, treasury or journal effect. The Buyer custody event is created only after explicit confirmation of actual physical handover.

## 3. Exact Buyer tab behavior

Keep existing tab ID `vehicle` for compatibility if necessary, but the user-facing label remains `رصيدي`. Replace only the body of `renderVehicleBalance()` after the server-side ledger APIs are ready.

### 3.1 Read contract

Call the existing `save-purchase-order` Edge through `this.api()`:
- `GET_BUYER_GOODS_CUSTODY`
- `GET_BUYER_GOODS_CUSTODY_MOVEMENTS` (cursor/page)
- `GET_BUYER_GOODS_CUSTODY_ACTIONS` or action availability fields returned by the first RPC.

Do not calculate the official balance from a client-side 500-row table read. The server returns:
- summary totals;
- item-level balance rows;
- pending warehouse acknowledgement;
- pending supplier acceptance;
- age/overdue flags;
- next valid action;
- page cursor and total count.

If the RPC fails, show an error with Retry. Never display a false zero.

### 3.2 Dashboard hierarchy

**Header:** "رصيدي — بضاعة في عهدتي" and subtitle "لا يشترط وجود سيارة".

**Summary cards:**
- عدد الأصناف.
- إجمالي الوحدات.
- بضاعة بانتظار تسليم المخزن.
- مرتجعات بانتظار قبول المورد.
- حالات متأخرة/تحتاج مراجعة.

**Primary actions:**
- `استلام مرتجع من المخزن` — shows SupplierReturn vouchers assigned to this Buyer and awaiting acknowledgement.
- `تسجيل شراء سوق` — creates a no-PO Draft invoice, then separately confirms physical receipt.
- `تسليم للمخزن` — opens a handover for items currently in the Buyer ledger.
- `تسليم مرتجع للمورد` — opens supplier acceptance for assigned return goods.

### 3.3 Item ledger

Each item row:
- item name, code, barcode, unit;
- quantity received into Buyer custody;
- accepted by Warehouse;
- accepted by Supplier;
- returned to Warehouse;
- current custody balance;
- oldest open custody age;
- source document and status.

Search by item name/code/barcode. Filters: date, branch, supplier, event type and status. The vehicle is optional metadata only; never a balance key or required field.

### 3.4 Movement detail

Clicking a row opens a timeline of immutable events:
- source voucher/invoice;
- physical handover timestamp and actor;
- quantities issued/acknowledged/accepted/rejected;
- receiving or supplier acceptance reference;
- evidence attachment;
- reversal/correction reference.

No edit/delete for posted events. Corrections create compensating movements.

## 4. Quick Market invoice UX

Replace the current alias:
```js
quickPurchase:function(){return this.createPurchaseInvoice();}
```

with a dedicated `createQuickMarketPurchase()` workflow that reuses the existing item/supplier search and invoice Draft builder but sets:
- `source_type='QUICK_MARKET'`;
- `purchase_order_id=null`;
- `settlement_source='BUYER_CASH_CUSTODY'` or `'SUPPLIER_CREDIT'` (explicit choice; default from supplier payment terms only as a suggestion, not as an unverified fact);
- currency from `GET_SETTINGS` only;
- manually entered actual unit price.

The invoice modal must state:
- "حفظ الفاتورة لا يعني استلام البضاعة أو ترحيل المخزون."
- "تأكيد استلام المورد → مسؤول المشتريات خطوة مستقلة."

After Draft save, show a second action:
- `تم استلام البضاعة فعليًا من المورد` — opens a confirmation with per-line actual quantities, supplier invoice reference, branch destination plan, and optional evidence.
- `لم أستلم البضاعة بعد` — leaves invoice Draft and creates no custody event.

Only the first explicit action calls `RECORD_QUICK_MARKET_HANDOVER` through the existing `save-purchase-order` Edge. The RPC validates the assigned Buyer, supplier, invoice status/source, line quantities and idempotency before appending custody events.

## 5. Buyer → Warehouse receiving

The Buyer selects custody lines and quantities to hand over. The Receiver app must see a Quick Market receipt work item by invoice ID, not by PO code.

- Receiver confirms accepted/rejected quantities per invoice line.
- Accepted quantity reduces Buyer custody and increases branch stock once.
- Rejected/unpresented quantity remains in Buyer custody.
- The invoice-to-Receiving header and line links are mandatory.
- An EMPLOYEE_CUSTODY Quick Market invoice is eligible for cash-custody expense review only after the invoice-linked Receiving evidence and accepted quantities reconcile; it must not require or create Supplier AP/Supplier Payment if the supplier was already paid from the Buyer advance. SUPPLIER_CREDIT instead requires its Supplier AP recognition. TREASURY_CASH requires a separately evidenced actual payment.
- Existing PO receiving and its validation remain unchanged.

## 6. Buyer → Supplier return

For a SupplierReturn assigned to the Buyer:
- the warehouse issue creates the Buyer custody event;
- the Buyer submits supplier acceptance quantity per line plus receipt/evidence;
- only accepted quantity reduces Buyer custody and posts supplier AP/GL return;
- rejected quantity remains in Buyer custody;
- a return-to-warehouse operation creates a separate inbound stock movement and reduces custody only when Warehouse accepts it.

The default Supplier Direct path bypasses Buyer custody and remains the normal route.

## 7. Realtime and pagination

Add the new ledger/acceptance tables to Buyer Realtime:
- `buyer_goods_custody_events`;
- `purchase_return_acceptances`;
- `purchase_return_acceptance_details`;
- `receiving`;
- `receiving_details`;
- `stock_vouchers`;
- `stock_voucher_details`.

Map events to refresh `vehicle`, `invoices`, `custody` or `today` only when relevant. Keep debounce/reconcile behavior. Do not refresh while a modal is open; set `needsLiveRefresh` as current app already does.

Balance totals must be server aggregated and paged; do not truncate at 500 rows. Event history uses cursor pagination.

## 8. Cash custody settlement remains distinct

- `عهدتي` continues to show cash advances, expenses, payments and settlement.
- Quick Market invoices selected for cash custody create a `PURCHASE` expense reference only after warehouse acceptance evidence is complete.
- Finance review must match invoice ID, invoice-line accepted quantities and the existing custody ID/expense evidence. Only the SUPPLIER_CREDIT route reconciles Supplier AP; EMPLOYEE_CUSTODY must clear Employee Custody without duplicate Supplier AP/Payment.
- Review remains performed by Finance/Finance Manager, not self-approved by Buyer.
- Fuel, transport and other operating expenses use their own categories/accounts; they are not supplier purchases and do not create stock/AP.

## 9. Edge/RPC compatibility

No new Edge Function:
- `save-purchase-order` v22 adds read and action operations for the Buyer ledger and quick market handover, supplier acceptance, and cash-expense review.
- `receive-purchase` v13 adds `invoice_id` mode while preserving existing `po_code` mode.
- `create-stock-voucher` v12 / `send-stock-voucher` v20 use the existing `rep_id` → `p_rep_id` for the optional Buyer custodian, after Trigger/RPC validation.
- `complete-stock-voucher` v4 remains the warehouse completion route; linked financial posting is delegated to the single canonical acceptance/return RPC.

Every physical event receives one fresh stable operation UUID; exact retries reuse that same UUID and identical payload, while a distinct physical event (even with identical quantities) receives a new UUID. The server rejects reuse of an operation ID with a different payload. No client-side direct insert/update into event, return, receiving or supplier-ledger tables.

## 10. UX and safety improvements

- Hide `cost_price` in quick search by default; if needed, show it only as a secondary advisory detail to authorized users. The actual price remains manually entered.
- Keep supplier directory read-only from Buyer; all supplier master creation/editing stays in Parent.
- Show clear status text: مسودة، بضاعة بعهدة المشتري، بانتظار المخزن، مستلم جزئياً، بانتظار المورد، مقبول جزئياً، تمت التسوية.
- No vehicle required; vehicle can be recorded only as optional transport metadata.
- Avoid duplicate actions after success; disable/lock by document status and idempotency.
- Errors should state the blocking document/quantity, not generic "failed".

## 11. Acceptance tests

- Draft invoice save creates no stock/AP/GL/treasury/custody event.
- Confirmed supplier handover increases Buyer custody exactly once.
- No handover confirmation leaves custody unchanged.
- Warehouse partial receipt reduces custody only by accepted quantity and increases stock exactly once.
- Supplier partial acceptance reduces custody and supplier AP/GL only by accepted quantity.
- Rejected quantity remains visible in Buyer balance.
- Buyer return-to-warehouse decreases custody and increases branch stock only after Warehouse acceptance.
- Supplier Direct default creates no Buyer custody.
- Buyer Delegate recipient is visible in voucher and Parent data model.
- Cash custody review cannot occur before completed invoice receipt; no PO required for Quick Market.
- Realtime and pagination show correct balances beyond 500 events.
- Other Buyers and companies cannot read this user's custody.
- Duplicate request, timeout/retry, refresh and concurrent acceptance produce no duplicate stock/AP/GL/custody effect.


### LVE618 reconciliation note — settlement vocabulary and posting boundary
The Quick Market settlement source uses the owner-aligned values `EMPLOYEE_CUSTODY`, `SUPPLIER_CREDIT`, and `TREASURY_CASH`. The earlier phrase `BUYER_CASH_CUSTODY` is superseded. The invoice source field is `purchase_source='QUICK_MARKET'`. Employee-custody cash purchases require a complete linked Receiving proof but do not require Supplier AP credit and must not create a second Supplier Payment; the existing PO supplier-credit custody-review routine must remain isolated to its current PO branch. A new physical event receives a fresh UUID, with the same UUID reused only for retries of that event.

## 12. Status

This is the exact Buyer UX and operation specification. It is not a code change. Buyer source remains unchanged; the server-side ledger and RPC contract must be deployed and tested before replacing the static screen.
