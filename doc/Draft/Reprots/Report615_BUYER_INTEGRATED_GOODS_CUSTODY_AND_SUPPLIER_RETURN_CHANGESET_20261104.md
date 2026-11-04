# Report615 — Integrated Buyer Goods Custody, Supplier Returns, Quick Market Receiving and Control Change Set

**Date:** 2026-11-04 — Africa/Cairo  
**Starting checkpoint:** LVE614 / Report614  
**Operational repository:** papamohammed77-glitch/erp-frontend / main  
**Production:** SMART ERP / fiilmooggumokxanwiyx  
**Status:** ROOT CAUSES CONFIRMED / INTEGRATED TARGET CONTRACT DESIGNED / EXACT IMPLEMENTATION SCOPE IDENTIFIED / NO OPERATIONAL OR PRODUCTION WRITE PERFORMED  
**Governance:** Master CTO §77.2–77.4; permanent charter §§6.1–6.3 and §§7–10.

---

## 1. Executive decision

The Buyer workstream must be treated as one end-to-end control system. The required outcome cannot be achieved by making the “رصيدي” screen prettier, by adding a user selector to the manual voucher, or by joining two lists in Parent. The defect is in the business-event model and its posting boundaries.

The system must distinguish three events:

1. **Physical dispatch from branch:** stock leaves the branch once.
2. **Internal custody by Purchasing Officer:** the company’s goods are held by a named employee, with no vehicle requirement.
3. **Supplier acceptance:** only the supplier-accepted quantity can reduce Supplier AP and create the related GL/tax effect.

Quick Market also has three distinct events:

1. Draft invoice creation.
2. Actual handover from supplier to Buyer.
3. Actual warehouse acceptance of the quantity offered to the warehouse.

The purchase invoice, goods custody, warehouse receipt, employee cash advance, supplier liability and supplier payment must not be treated as interchangeable facts.

**Recommended architecture:** use one financial return register in purchase_returns, linked to one physical SupplierReturn stock voucher; the stock voucher is the sole branch-stock-out writer. Append-only supplier acceptance events own the accepted quantities and the supplier AP/GL effect. Buyer Goods Custody is a separate item-level event ledger, not the existing cash-custody ledger and not vehicle stock. Parent’s existing Returns list can continue reading purchase_returns, with a recipient projection added by the owner to main.html; no runtime shadow screen or duplicate data source should be introduced.

---

## 2. Historical owner decisions — binding

The current design follows the already recorded decisions in Report606; they are not new questions for the owner:

- Supplier is the default physical recipient of a supplier return directly from the warehouse.
- The Purchasing Officer may receive goods only when the supplier expressly delegates that responsibility. Warehouse records the delegation and handover; the officer later supplies signed supplier receipt / credit-note evidence.
- Only the supplier-accepted quantity reduces the supplier balance.
- Buyer goods custody does not require a vehicle. Vehicle ID is optional logistics metadata.
- Quick Market invoice starts as Draft with no stock/AP/GL/Treasury effect. Receiver must find it by invoice number and confirm physically accepted quantities through the central receiving workflow.
- Cash purchase paid from employee custody, operating expense, supplier-credit invoice and actual supplier payment are separate financial events.
- Where supplier has already been paid from the employee’s custody cash, do not create a second Supplier AP or Supplier Payment.
- Cash advance tables and RPCs already exist and must be reused; no second cash custody system.
- Supplier Master is centrally governed by Parent. Buyer supplier directory remains read/search only.
- No changes to companies/company-1/main.html by the assistant; no new Edge Functions.

Historical sources:
- Report606: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report606_BUYER_OWNER_CLARIFICATIONS_MASTER_SUPPLIER_QUICK_RECEIPT_GOODS_CUSTODY_EXECUTION_PLAN_20261103.md
- Report614: https://github.com/papamohammed77-glitch/rawaie-erp-New/blob/main/doc/Draft/Reprots/Report614_BUYER_GOODS_CUSTODY_RETURN_RECONCILIATION_20261104.md

---

## 3. Confirmed current source and Production evidence

### 3.1 Operational source fingerprints

- Operational HEAD observed: e8ab54c75572e15e71581212479d22be139c8020.
- Buyer companies/company-1/purchasing/buyer.html blob: 311f2673a90149df6f56d59a9a187a3379e6981c.
- Parent companies/company-1/main.html blob: f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca.
- Warehouse Vouchers companies/company-1/warehouse/vouchers.html blob: 85e709d0f41c189c6624a6160965d3b1a41960ba.
- Receiver companies/company-1/warehouse/receiver.html blob: 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6.
- Core companies/company-1/core.js blob: f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1.
- Parent PO/Invoice improvement commit 3f4d48b6acfc5c5e70d2d6a09278a4bc3fd5d954 is already present; it must not be repeated.

### 3.2 Current deployed Edge functions

No new Edge Function is necessary or proposed.

| Function | Live version | JWT verification | Live source SHA-256 |
|---|---:|---|---|
| save-purchase-order | 22 | true | a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb |
| receive-purchase | 13 | true | 50ab45ae026a0bb4d1de7837c872c4cc42da47b6a603f340e48d023d839310cc |
| create-stock-voucher | 12 | false; source validates Bearer token using auth.getUser | c4ee58c5c94538bcb02a2a76c247996fa9368be7c5b2f7b4d44c98336d29ea4d |
| send-stock-voucher | 20 | true | 864129274b4a23d74b3378c44d8fbf8f2a269eb76d9b623350ad57c818c8805b |
| receive-stock-voucher | 22 | true | 62f6e97936997ab0ab58379bb683a08431eb2a5c96d1063943e5a3e03d24bf29 |
| complete-stock-voucher | 4 | true | 8cf684456cd82f4f331c909ad4adf5afaf1ad46ffa34d9927fded06276fed855 |

Source-parity gap: save-purchase-order exists at supabase/functions/save-purchase-order/index.ts in operational Git. The deployed live source files for receive-purchase, create-stock-voucher, send-stock-voucher, receive-stock-voucher and complete-stock-voucher are not present at matching paths in operational Git. Their live sources were recovered for this review. Before changing them, restore each live source byte-for-byte at its canonical operational path, fingerprint/version it, then apply the minimum patch. Do not deploy from an unverified historical source.

### 3.3 Current Buyer behavior

- renderVehicleBalance() is a static explanation; it reads no goods-custody data source.
- buyer_custodies and dependent tables are cash advance/expense/settlement records, not an item quantity ledger.
- Buyer Realtime subscribes to purchase and cash-custody tables but not an item-level goods-custody event source.
- quickPurchase() is an alias to createPurchaseInvoice(); it only creates a Draft invoice.
- Quick Market Draft invoice has no invoice-to-Receiving header/line relation.
- Buyer goods custody must not be derived from vehicles, Fleet assignments, purchase order state, invoice flags or the mere existence of a supplier invoice.

### 3.4 Current SupplierReturn behavior

- Warehouse Vouchers SupplierReturn UI shows Branch and Supplier; no recipient mode or Purchasing Officer picker.
- create_manual_stock_voucher_atomic accepts a generic p_rep_id argument, but the core persists custodian_user_id only for DirectSale/DirectReturn.
- Production Trigger enforce_stock_voucher_custodian() clears custodian_user_id for all types except DirectSale/DirectReturn.
- send_stock_voucher_atomic posts branch stock-out through post_stock_movement and marks the voucher Sent.
- complete_manual_stock_voucher_atomic_core_20260828 posts the full SupplierReturn value to Supplier Ledger / GL when the voucher is completed; there is no supplier accepted quantity model.
- This is not the historical owner-approved Branch → Delegated Buyer → Supplier workflow. A UI-only Buyer picker would silently lose the value in the Trigger/core.

### 3.5 Duplicate return writers

There are two independent supplier-return posting paths:

**Warehouse manual voucher**
- Physical stock-out: send_stock_voucher_atomic → post_stock_movement(..., SupplierReturn, ...).
- Financial effect: complete_manual_stock_voucher_atomic_core_20260828 posts supplier ledger and GL for the full return amount.

**Parent purchase return**
- purchase_create_return_atomic creates purchase_returns / purchase_return_details.
- purchase_post_return_atomic independently calls post_stock_movement(..., SupplierReturn, ...), posts Dr Supplier AP / Cr Inventory, inserts supplier_ledger debit and changes status to Posted.

There is no unique link between purchase_returns and stock_vouchers. If both paths describe the same physical goods and both are posted, stock and supplier AP can be reduced twice.

Additionally, purchase_create_return_atomic checks each line quantity against original invoice received_qty but does not subtract previous active returns. Multiple return documents can cumulatively exceed the received quantity. This must be locked and checked cumulatively, including Draft reservations and Posted quantities, with Cancelled excluded.

### 3.6 P0 security: direct table writes to returns

Current Production ACL inspection using pg_class.relacl and has_table_privilege confirms direct table DML privileges for PUBLIC/anon/authenticated on:
- purchase_returns
- purchase_return_details

The current RLS policies on those tables use command ALL and only constrain company_id. Therefore the permission checks in save-purchase-order are not a sufficient control: direct authenticated/anonymous table writes can bypass Edge's effective-permission check. This is a confirmed P0 ACL issue. It has not been changed.

### 3.7 Receiver / PO receiving defects

- Receiver queries purchase_order_details using po_code, whereas actual relation is purchase_order_details.po_id → purchase_orders.id. Receiver must select PO header ID and query by po_id.
- Receiver uses parseInt() for received quantities, truncating decimal quantities.
- Receiver permits all-zero input. The live receive_purchase_atomic skips zero lines but can still insert a Receiving header and update PO state.
- The deployed receive-purchase v13 accepts PO code only; no Quick Market invoice source is supported.
- Its fallback deterministic UUID is derived from user/company/payload. A later new physical receipt with identical payload can collide with an earlier operation. Each new physical receipt needs a fresh stable operation ID; only retry of the same physical event reuses it.

### 3.8 Currency mismatch

- Warehouse SupplierReturn contract UI initializes and submits SAR.
- Production app_settings.currency is EGP.
- stock_vouchers.return_currency has DEFAULT 'SAR'.
- Posting/conversion impact is not confirmed because the review snapshot has zero return rows. Do not silently convert historical values; all new contracts must derive currency from System Settings and reject mismatch.

### 3.9 Existing Receiving and Cash Custody accounting writers

**PO Receiving writer — CONFIRMED**
- The live receive_purchase_atomic(p_company_id,p_po_code,p_user_email,p_items,p_operation_id) function posts stock movements using post_stock_movement(...,'PurchaseIn',...).
- For the accepted PO quantity it creates a journal DR Inventory account 124 / CR Supplier AP account 211, and inserts a Supplier Ledger credit for the received value.
- It updates purchase_order_details.qty_received and purchase_orders.status. It does not create a purchase_invoice_id link in receiving header/detail.
- Therefore simply extending this function for Quick Market and reusing the PO posting block for every Quick Market invoice would be wrong for an invoice paid immediately from employee cash custody: it would create Supplier AP and Supplier Ledger despite the vendor having already been paid.

**Cash Custody review writer — CONFIRMED**
- buyer_custody_review_expense_atomic is a specific supplier-invoice settlement routine, not a general expense reviewer.
- It requires a Draft invoice linked to a PO and completed PO Receiving; it checks full invoice-vs-PO quantities/prices, then posts DR Supplier AP 211 / CR Employee Custody 127, creates buyer_custody_payments, marks the invoice Paid and debits supplier_ledger.
- It does not support fuel/transport/other expenses without supplier invoice, PO, and receiving.
- Reusing it for an EMPLOYEE_CUSTODY_CASH Quick Market invoice would add a second Supplier AP/Payment route. Reusing it for operating expenses would be invalid.
- This writer must be split by explicit settlement_source and expense_category. PURCHASE_CASH must reconcile accepted inventory to Employee Custody without AP/Supplier Ledger duplication; FUEL/TRANSPORT/OTHER use Finance-approved expense accounts without stock/AP. SUPPLIER_CREDIT keeps the AP route. TREASURY_CASH remains a separate actual-payment event.

**Supplier-return acceptance financial nuance — CONFIRMED**
- Manual SupplierReturn completion reverses tax by grouping stock_voucher_details.tax_code_id and creating finance_tax_transactions for the full return, in addition to the AP/Inventory journal.
- Parent purchase_post_return_atomic does not follow the same tax-code flow; its return detail model currently only stores item/qty/unit_price/line_total.
- The unified acceptance writer must calculate accepted value, discount and tax per accepted line from the authoritative source return line, reverse only the accepted tax amount, and create one balanced journal. It must not post the full line total when the supplier has accepted only part.

### 3.9 Live Production row snapshot

At the LVE614/615 read-only review window:
- stock_vouchers total: 0.
- purchase_returns total: 0.
- inventory_log rows where movement_type='SupplierReturn': 0.
- buyer_custodies total: 0.

No test records or production rows were created, modified or deleted in this review. This snapshot is not a licence to assume the rows are still zero at migration time. The migration must recheck.

---

## 4. Competitive research translated into RAWAEA business rules

### Odoo — internal/transit ownership is different from external vendor movement

Odoo distinguishes Internal and Transit locations from Vendor/Customer external locations. Internal and transit movements can represent goods outside a particular warehouse while still owned by the company; movement to an external partner location changes valuation. Use the company-owned internal holding concept for Buyer custody rather than treating the employee as a vehicle or vendor.

Official source: https://www.odoo.com/documentation/master/applications/inventory_and_mrp/inventory/warehouses_storage/inventory_management.html

### Microsoft Dynamics 365 — return orders, partial quantities and receipt evidence

Dynamics return purchase orders support full and partial returns and mark returned lines against the original inventory transaction. The vendor shipment is recorded through a product receipt/packing-slip reference. A separate Dynamics product receipt workflow supports registration, quality inspection and per-line partial accepted quantities; receipt references support audit against the vendor's document.

Official sources:
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order
- https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/product-receipt-against-purchase-orders

### SAP Advanced Returns Management — supplier return as a lifecycle

SAP describes supplier returns as a linked process of return purchasing document, inspection results, logistical follow-up, vendor replacement handling and financial follow-up, with authorizations by warehouse, returns, inventory and financial roles.

Official sources:
- https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/af9ef57f504840d2b81be8667206d485/666259fa030b4b959991a99b45e85e00.html
- https://help.sap.com/docs/SAP_S4HANA_CLOUD_PE/af9ef57f504840d2b81be8667206d485/cff87e426fed4ad9b3b0929aea4dedf6.html

### RAWAEA decisions adopted from this research

- Buyer custody is an internal company-controlled location/ledger, not a branch available balance, not a delivery vehicle and not an external supplier movement.
- Distinguish dispatch, custody transfer, warehouse accepted receipt and supplier accepted return.
- Support per-line partial quantities and inspection/rejection reasons.
- Keep the original source transaction line reference for every return.
- Supplier AP/GL only changes on evidenced vendor acceptance, not on warehouse dispatch.
- Use one writer for stock-out, one financial register, and an idempotent link between them.

---

## 5. Target business contract

### 5.1 SupplierReturn direct-to-supplier (default)

1. Warehouse creates the supplier return with Branch → Supplier.
2. Recipient mode defaults to SUPPLIER; no Buyer or vehicle is required.
3. Warehouse physically hands the goods to the supplier and records the receiving proof.
4. Branch stock decreases once at physical dispatch; the return remains pending acceptance.
5. Supplier accepted quantity and signed supplier receipt/credit-note proof are recorded by the authorized acceptance step.
6. Only accepted value decreases Supplier AP and creates the corresponding GL/tax reversal.
7. Rejected/unaccepted quantity remains in return-transit/hold status until physically returned to warehouse or handled by an approved disposition.

### 5.2 SupplierReturn delegated to Purchasing Officer

1. Supplier explicitly delegates receipt to the Purchasing Officer.
2. Warehouse chooses recipient mode PURCHASING_OFFICER, selects an active same-company purchasing user, records delegation reference/evidence, and hands over the goods physically.
3. The stock-out from the branch happens once; Buyer custody qty_in is created in the same transaction. No Supplier AP / GL / Treasury effect occurs.
4. Buyer sees their own goods balance, independent of vehicle.
5. Buyer records supplier handover and supplier acceptance quantities with signed receipt/credit note.
6. Buyer custody qty_out and Supplier AP/GL posting occur only for the supplier-accepted quantity.
7. Rejected/unaccepted quantity remains in Buyer custody or is physically returned to warehouse through a separate documented handover.

### 5.3 Quick Market purchase

1. Buyer creates a Draft invoice with supplier, item lines, actual unit price, system EGP, purchase_source QUICK_MARKET, settlement_source and purchaser_user_id.
2. Draft creation has no stock, supplier balance, treasury or GL effect.
3. Buyer records supplier-to-Buyer physical handover; only then are the accepted quantities entered as Buyer custody qty_in.
4. Receiver searches by invoice code or supplier invoice number and displays the actual Buyer-held lines.
5. Receiver records accepted and rejected quantities per invoice line, destination branch and proof.
6. Accepted quantity reduces Buyer custody and increases branch stock once; rejected quantity stays in Buyer custody or goes through a separately evidenced supplier return.
7. Settlement source selects the financial counter-entry:
   - EMPLOYEE_CUSTODY_CASH: inventory/expense recognition against Employee Custody; no Supplier AP or Supplier Payment duplication if vendor already received cash.
   - SUPPLIER_CREDIT: Supplier AP is recognized once for accepted goods; cash payment remains a separate event.
   - TREASURY_CASH: treasury changes only on actual documented payment, independently of physical receipt.
8. Status must distinguish invoice document state, physical receipt state and settlement state.

### 5.4.1 Refund/credit treatment for a return of cash-paid goods

A further mapping remains UNKNOWN and must not be guessed. If the original Quick Market invoice was settled using EMPLOYEE_CUSTODY_CASH and the supplier later accepts a return, there may be no Supplier AP balance to debit. The return may create a supplier refund receivable/credit balance, a supplier credit note available for offset against a later purchase, or an actual cash refund received by the employee/company. Finance must map those dispositions to the existing chart and treasury evidence before posting. The acceptance event must record which disposition occurred. Do not post a debit to Supplier AP as if it were an existing payable when the original purchase created no AP; do not increase cash or treasury merely because the supplier accepted the goods.

### 5.4 Cash custody and operating expenses

Keep buyer_custodies and its existing tables/RPCs as the cash ledger. Do not add a second cash custody system.

Extend buyer_custody_expenses with:
- expense_category: PURCHASE_CASH / FUEL / TRANSPORT / OTHER.
- expense_account_id.
- payee_kind: SUPPLIER / EMPLOYEE / OTHER.

Finance review:
- PURCHASE_CASH requires matching Draft invoice, actual completed Receiving, accepted line quantities and EMPLOYEE_CUSTODY_CASH source. Post Inventory DR / Employee Custody CR (or appropriate cost allocation), do not create Supplier AP, Supplier Ledger or Supplier Payment if the supplier was already paid in cash.
- FUEL / TRANSPORT / OTHER requires an active Finance-approved expense account. Post expense DR / Employee Custody CR; no stock and no Supplier Ledger by default.
- SUPPLIER_CREDIT remains in purchase AP/invoice flow with a separate actual payment.
- If the company has no configured account for an operating expense category, reject posting. Do not invent account codes.

---

## 6. Proposed database change set — not applied

This is the target schema contract for the exact migration. It is not an executed SQL migration.

### 6.1 purchase_invoices

Add:
- purchase_source: PURCHASE_ORDER / QUICK_MARKET.
- settlement_source: SUPPLIER_CREDIT / EMPLOYEE_CUSTODY_CASH / TREASURY_CASH.
- purchaser_user_id FK users.
- receipt_status: NOT_RECEIVED / PARTIALLY_RECEIVED / RECEIVED.
- settlement_status: UNSETTLED / PENDING_FINANCE / AP_OPEN / SETTLED / PAID.

New invoices must set these explicitly through the authenticated writer. Do not infer historical values or backfill based on UI labels. Preserve historic records as legacy/unreconciled until evidence is checked.

### 6.2 receiving and receiving_details

receiving add:
- purchase_invoice_id nullable FK purchase_invoices.
- branch_id nullable FK branches.
- receipt_source PO / QUICK_MARKET.

receiving_details add:
- purchase_invoice_detail_id nullable FK purchase_invoice_details.
- qty_rejected numeric(14,3) not null default 0.
- rejection_reason nullable.

Keep existing operation_id linkage and PO receipt contract. One physical event gets a fresh UUID; a retry of that exact event reuses it.

### 6.3 purchase_returns and stock_vouchers

stock_vouchers add:
- recipient_mode SUPPLIER / PURCHASING_OFFICER, default SUPPLIER.
- supplier_delegation_reference.
- supplier_delegation_attachment_id.
- purchase_return_id nullable unique FK purchase_returns.

purchase_returns add:
- stock_voucher_id nullable unique FK stock_vouchers.
- requested_amount and accepted_amount.
- status PartiallyAccepted if needed by Parent register.
- purchase_invoice_id becomes nullable ONLY after the full function/view/dependency scan and a guarded migration. If any live return rows or legacy consumers require a non-null invoice, the migration must stop; do not force-null historical records.

purchase_return_details add:
- stock_voucher_detail_id nullable unique.
- preserve requested/dispatched qty; accepted quantity is derived from acceptance events.
- Store sufficient line-level discount/tax/value basis to compute accepted value accurately. Do not prorate incorrectly from a document total or trust client-computed amount.

Chosen link direction: purchase_returns.stock_voucher_id → stock_vouchers.id. Do not create a second reciprocal FK unless both are enforced within one transaction.

### 6.4 Supplier acceptance events

Create append-only purchase_return_acceptance_events:
- id, company_id, operation_id, purchase_return_id, supplier_id, stock_voucher_id.
- accepted_by_user_id, recorded_by_user_id, accepted_at.
- supplier receipt / credit note reference and secure attachment metadata.
- status, journal_entry_id, posted_at.

Create purchase_return_acceptance_details:
- event_id, purchase_return_detail_id, stock_voucher_detail_id.
- accepted_qty > 0, rejected_qty >= 0.
- rejection disposition and evidence.
- accepted amount/tax allocation derived server-side from locked source line pricing.

The acceptance RPC locks the return header/source lines and checks cumulative accepted + rejected + returned quantities never exceed dispatched quantity. Operation ID is immutable/idempotent and replay with a different payload fails.

### 6.5 Buyer goods custody event ledger

Create append-only buyer_goods_custody_events:
- id, company_id, operation_id, event_type.
- custodian_user_id, branch_id, supplier_id.
- item_id, item_code, item_name, unit.
- qty_in and qty_out; exactly one positive.
- optional vehicle_id as logistics metadata only.
- source refs: stock_voucher_id, stock_voucher_detail_id, purchase_invoice_id, purchase_invoice_detail_id, receiving operation.
- evidence attachment ref, created_by_user_id, occurred_at.
- correction_of_event_id, correction_reason.

Balance = SUM(qty_in) − SUM(qty_out), grouped by Buyer/user and item (branch dimension when needed). Prevent outbound quantity exceeding locked balance. No update/delete of posted events; use compensating event only.

### 6.6 Cash-custody expense table

buyer_custody_expenses add expense_category, expense_account_id, payee_kind. Reuse existing document paths only where secure policy covers them; add procurement-evidence private storage prefix and company/employee/role-based policies for supplier delegation, receipt and acceptance proofs.

### 6.7 RLS, ACL, publication and grants

- Revoke direct DML from PUBLIC, anon and authenticated on purchase_returns and purchase_return_details.
- Grant SELECT only to authenticated; preserve company SELECT RLS policy.
- Keep service_role access for existing authenticated server Edge writer.
- Apply server-writer-only policy to new custody/acceptance tables; authenticated gets only SELECT allowed by scope. All mutations via validated atomic RPC.
- Add new custody/acceptance event tables to supabase_realtime only after RLS policies exist and DELETE behavior is defined.
- Do not use public product-images for signed procurement evidence.

Proposed P0-D ACL fragment (NOT EXECUTED; must be revalidated against live grants immediately before migration):

~~~sql
BEGIN;

LOCK TABLE public.purchase_returns, public.purchase_return_details
  IN ACCESS EXCLUSIVE MODE;

REVOKE ALL PRIVILEGES ON TABLE
  public.purchase_returns,
  public.purchase_return_details
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON TABLE
  public.purchase_returns,
  public.purchase_return_details
TO authenticated;

DROP POLICY IF EXISTS purchase_returns_company
  ON public.purchase_returns;
CREATE POLICY purchase_returns_company_select
  ON public.purchase_returns
  FOR SELECT TO authenticated
  USING (company_id = app_private.current_user_company_id());

DROP POLICY IF EXISTS purchase_return_details_company
  ON public.purchase_return_details;
CREATE POLICY purchase_return_details_company_select
  ON public.purchase_return_details
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.purchase_returns r
      WHERE r.id = purchase_return_details.return_id
        AND r.company_id = app_private.current_user_company_id()
    )
  );

COMMIT;
~~~

---

## 7. Required RPC and Edge behavior

### 7.1 Existing save-purchase-order v22

Extend the current function only:
- GET_GOODS_CUSTODY, role-scoped and paginated.
- CREATE_INVOICE or a narrowly scoped Quick Market create action with purchase_source/settlement_source/purchaser_user_id.
- RECORD_SUPPLIER_TO_BUYER_HANDOVER.
- RECORD_BUYER_TO_WAREHOUSE_HANDOVER.
- RECORD_SUPPLIER_RETURN_ACCEPTANCE.
- Category-aware SUBMIT/REVIEW_CUSTODY_EXPENSE.

Every action validates get_my_effective_profile, auth user/company, active account, permission, branch scope, source references, status and idempotency server-side. Do not trust client actor, company, amount, accepted qty or expense account.

Convert CREATE_RETURN / POST_RETURN to the linked single-writer model. No independent posting of a second SupplierReturn movement for a return linked to stock voucher.

### 7.2 Existing stock voucher functions

Restore live deployed sources into operational Git before editing:
- create-stock-voucher v12.
- send-stock-voucher v20.
- receive-stock-voucher v22.
- complete-stock-voucher v4.

Extend SupplierReturn contract with recipient_mode and explicit supplier delegation proof. Do not overload rep_id or the DirectSale/DirectReturn contract.

On dispatch:
- Existing send_stock_voucher_atomic remains the only branch stock-out writer.
- If recipient_mode=PURCHASING_OFFICER, create Buyer qty_in in the same transaction.
- If recipient_mode=SUPPLIER, no Buyer custody entry is created.
- Do not create supplier AP/GL at dispatch.

On supplier acceptance:
- common acceptance RPC records accepted qty, proof, event and financial posting.
- Buyer mode creates Buyer qty_out for accepted qty; direct supplier mode has no Buyer event.
- post supplier AP/GL only for accepted value; do not call branch stock writer again.
- rejected quantity remains in Buyer custody/return hold or is physically returned to warehouse with a separate documented event.

### 7.3 Existing receive-purchase v13

Restore exact live source to supabase/functions/receive-purchase/index.ts before changes.
- Accept existing PO source OR Quick Market purchase_invoice_id / invoice reference.
- Keep authentication and receiving-role/branch scope.
- Reject all-zero accepted quantity before creating receiving header.
- Per-line accepted + rejected <= remaining source quantity.
- New physical receiving gets a fresh operation UUID; retry same event reuses.
- Quick Market line identity links to invoice_detail; stock increases only by accepted qty once.
- Preserve existing PO path and its status transitions. Do not deploy new Edge Function.

### 7.4 Parent Returns register

Parent main.html is locked to owner-side source edits. The current parent returnsView reads purchase_returns only. The linked purchase_returns header becomes the single register projection, so one list can show:
- return code/date/supplier.
- recipient: Buyer user if delegated, supplier if direct.
- source voucher and invoice/PO.
- requested qty, accepted qty, accepted amount.
- physical stage and financial stage.
- creator, handover/acceptance evidence and exception status.

No runtime injection or shadow view. Owner-side patch is prepared for main.html but not applied by this work.

---

## 8. Buyer UI target — Gold/diamond workbench

Keep existing Buyer tabs and all functioning logic. Replace only the static renderVehicleBalance section plus focused helpers.

### Summary cards
- Current item count and total units in Buyer custody.
- Delegated supplier returns in custody.
- Quick Market purchases awaiting warehouse handover/acceptance.
- Warehouse handovers awaiting acceptance.
- Supplier acceptance outstanding.
- Overdue custody/exception count.

### Primary actions
1. تسجيل شراء سوق واستلام فعلي.
2. استلام مرتجع مفوض من المخزن.
3. تسليم للمخزن.
4. تسليم مرتجع للمورد.

### Item list
- item name/code/barcode/unit.
- current custody qty.
- source document, supplier, originating branch.
- received date and custody age.
- warehouse handover/accepted qty.
- supplier accepted qty.
- rejected/pending qty.
- optional vehicle metadata only.
- next allowed action based on document stage.

Search by item name/code/barcode, supplier, invoice and voucher. Filters by date, branch, source, status and overdue. Each row opens source/target evidence. Mobile line-cards; desktop table; progressive action dialogs. No giant single form.

Realtime subscribes to custody events, stock vouchers, purchase returns/acceptance events, invoices/details and receiving headers/details. Balance reads through a single company/permission-filtered, paginated RPC; never use generic GET_DATA 500-row cap as a balance source.

### Empty state
If no events exist, show a genuine empty state with the available next action. If ledger query fails or incomplete, show data unavailable—not zero balance.

---

## 9. Surgical Receiver source corrections

Current file: companies/company-1/warehouse/receiver.html, blob 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6.

Required surgical corrections:
1. loadPurchaseOrders must select PO id and branch, then load detail by po_id.
2. Add Quick Market invoices awaiting receipt, searchable by invoice code and supplier invoice number.
3. Load invoice detail by invoice_id; show supplier, Buyer purchaser, invoice number, branch and lines.
4. Replace parseInt with Number and proper unit precision.
5. Capture accepted and rejected quantity separately with reason.
6. Disable all-zero submission; enforce the same atomically in RPC.
7. New physical receipt receives fresh operation UUID; retry reuses the exact same key.
8. Show real receipt ID/status after server success. Do not display “stock updated” unless canonical stock writer actually succeeded.

---

## 10. Cumulative return and posting invariants

Final RPC implementation must enforce:
1. Lock source invoice and all relevant source lines during return creation.
2. Available-to-return = actual received quantity minus active Draft/reserved and Posted/accepted returns; Cancelled excluded.
3. Concurrent return create attempts serialize; cumulative qty cannot exceed received qty.
4. A supplier return physical voucher can link to at most one Parent financial return header; one return header cannot link to two live vouchers.
5. Each acceptance event locks header/source lines and checks accepted + rejected/returned quantities never exceed dispatched.
6. Same operation ID + same payload returns original response; changed payload with same operation ID fails.
7. Branch stock-out posts once at dispatch. Supplier acceptance never creates another stock-out.
8. Buyer custody qty_in occurs once at delegated handover; qty_out only on accepted supplier return or warehouse handover.
9. Supplier Ledger and GL post only accepted amount; balanced journal/tax allocation.
10. Direct supplier recipient path creates no Buyer custody event.
11. DirectSale/DirectReturn trigger rules remain unchanged.

---

## 11. Test and release acceptance matrix

### Supplier return default direct supplier
- Recipient defaults Supplier.
- Draft/contract save has no stock/AP/GL/Treasury effect.
- Dispatch decreases branch qty once; no Buyer event.
- Supplier accepted qty with signed proof posts AP/GL once.
- Partial accept: accepted qty posted; rejected remainder remains open and needs separate disposition.
- No repeat under retry/concurrent acceptance.

### Supplier-delegated Buyer custody
- Only active same-company user with effective purchases permission can be selected; explicit delegation reference/evidence is mandatory.
- Before warehouse handover, Buyer balance unchanged.
- Dispatch decreases branch qty once and increases Buyer qty once; no AP/GL.
- No vehicle required.
- Supplier partial acceptance decreases Buyer custody and AP/GL only by accepted quantity.
- Remaining/rejected balance stays in custody until a separate physical return/acceptance event.

### Quick Market cash purchase
- Draft invoice no stock/AP/GL/Treasury.
- Supplier-to-Buyer handover records custody only.
- Receiver searches invoice number and accepts per line.
- On Finance approval of cash custody purchase, accepted stock is capitalized once and Employee Custody cleared once; no Supplier AP/payment duplication.
- Invoice/accepted value differences remain unresolved pending supplier credit/refund or documented variance.

### Quick Market Supplier Credit
- Draft has no effect.
- Buyer physical handover adds custody.
- Receiver acceptance increases branch stock once and recognizes Supplier AP once.
- Actual supplier payment remains independent and requires treasury cash/instrument evidence.

### Operating expenses
- Fuel/Transport/Other require configured active expense account.
- Expense review posts Expense DR / Employee Custody CR once; no stock/AP/Supplier Ledger unless explicit separate event.
- No direct Treasury double subtraction.

### Regression
- PO full and partial receipts.
- Decimal quantities.
- Quick Market without PO.
- All-zero rejected before header.
- Transfer, DirectSale and DirectReturn unchanged.
- Buyer cash advance issue/acknowledge/settlement unchanged except typed expense routing.
- Realtime, pagination >500, retries, network timeout, cross-company RLS, unauthorized user and no negative custody.
- Branch stock / inventory_log / custody ledger / supplier_ledger / journal totals reconcile.

### Security
- anon cannot read/write returns.
- authenticated can read company-scoped return records but cannot directly insert/update/delete return or event rows.
- Buyer cannot read other custodians absent authorized Finance/Warehouse control.
- Evidence is private and access-scoped.
- Only validated RPC writers can change posted balances.

---

## 12. Test environment and rollback

- SMART ERP Production is real operating data; no persistent QA fixtures or test records are allowed.
- Staging remains non-parity at 62 migrations / 70 public tables and lacks current Buyer invoice/custody schema; full-cycle E2E there is not valid.
- Require a schema-parity isolated test project/branch with masked data or an approved transaction-rollback test path proven to leave no state.
- No testing through permanent expiring Production fixtures.
- Use additive migration and server-side feature gate. Read path can remain hidden until all write contracts and RLS pass.
- Before physical events exist, restore prior RPC/Trigger/schema from recorded source/migration.
- After real events exist, never delete posted events or blindly restore old writers; use compensating stock, supplier ledger, journal and custody events with source linkage.
- Verify current data snapshot again immediately before migration; abort if active/unlinked return rows appeared.

---

## 13. Scope that remains explicitly blocked or unverified

- Signed-in Buyer/Receiver/Parent browser E2E and actual Realtime event-to-DOM.
- Cloudflare canonical artifact parity with operational Git HEAD.
- Storage upload/download for supplier delegation and acceptance evidence; current private storage policies only cover Buyer cash-custody path.
- Full dependency scan before making purchase_returns.purchase_invoice_id nullable.
- Complete final executable replacement bodies for all RPC/Trigger/function changes are not yet authored in this report. This is the integrated behavior/schema change contract, not a deployable migration bundle.
- Parent main.html recipient column requires owner-side application; no main.html write performed.
- Expense account mapping remains unknown for Fuel/Transport/Other until configured by Finance.

---

## 14. Execution record

**Completed**
- Re-read CURRENT_STATE, permanent charter, Master CTO governance and relevant historical reports/owner decisions.
- Re-fetched current Buyer, Vouchers, Receiver and Parent source.
- Inspected live Production schemas, constraints, Trigger/function definitions, Edge versions/source, table ACL/RLS, Storage policies and Realtime publication.
- Reconfirmed current return data counts.
- Researched official Odoo, Microsoft Dynamics 365 and SAP return/inventory workflows and mapped useful principles to RAWAEA.
- Prepared the integrated target contract and acceptance/rollback scope.

**Not performed**
- No operational HTML/JS source write.
- No main.html edit.
- No Production DDL/DML, RPC, Trigger, RLS, ACL, grant, publication or storage policy change.
- No Edge source update or deployment.
- No new Edge Function.
- No test data or QA fixtures.
- No browser E2E or Cloudflare deployment verification.

**Current status:** ROOT CAUSES CONFIRMED / TARGET DESIGN COMPLETE / IMPLEMENTATION NOT APPLIED / NOT PRODUCTION READY.

**Next execution unit:** author the exact full SQL migration and replacement bodies from this contract; restore all live Edge sources into operational Git and verify parity; create exact Buyer/Vouchers/Receiver diffs and owner-side Parent patch; attach impact matrix, tests and rollback; present the exact change set under §77.2. No user clarification is needed for decisions already documented in Report606.
