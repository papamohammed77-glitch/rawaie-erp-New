# Report669 — Buyer Cash Custody & Goods Custody Integration Forensic Review

**Date:** 9 November 2026 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-09-669  
**Operational baseline:** `papamohammed77-glitch/erp-frontend` / `main` / `0fe255e3d9dae44332ee1863c43d9c1b0ea0ff79`  
**Production database:** SMART ERP / Supabase `fiilmooggumokxanwiyx`  
**Scope:** Buyer `عهدتي` (cash custody), Buyer `عهدة بضاعتي` (physical goods custody), linked purchase receiving and warehouse voucher contracts.  
**Execution status:** forensic inspection and read-only SQL only. No operational source file, Edge Function, schema, policy, business row, cash balance, stock balance, supplier ledger, treasury or journal was changed in this review.

---

## 1. Executive result

The two tabs represent distinct ledgers and must remain distinct:

- `عهدتي` tracks cash actually entrusted to the Buyer, cash reservations for unpaid/unsettled purchases, supported expenses, finance review and cash returns.
- `عهدة بضاعتي` tracks physical goods actually under the Buyer's responsibility. It is event-derived, not an editable balance and not a vehicle-stock alias.

Two blocking integration gaps were confirmed.

1. Quick Market invoices explicitly selected as `EMPLOYEE_CUSTODY` are correctly classified and reserved against the Buyer's cash custody, but the only expense submission/review path is PO-specific. The cash-purchase route therefore cannot complete settlement.
2. The goods ledger's aggregate is correct, but the warehouse-to-Buyer inflow has no complete execution path. The current stock-voucher trigger clears the custodian on all voucher types except `DirectSale` and `DirectReturn`; the warehouse UI has no Buyer recipient for `SupplierReturn`; and the stock send/complete writers do not append Buyer goods events.

The direct Market Supplier→Buyer physical handover path already exists and must be preserved. Saving a Quick Market invoice alone must continue to create no goods custody, no stock movement and no accounting movement.

**No production repair was applied.** These changes cross the financial posting and stock-issue boundaries. The permanent governance contract requires the exact implementation and effects to be reviewed and expressly approved before writing to Production or operational sources. This report defines the confirmed defects and proposed change boundaries for that approval.

---

## 2. Current production evidence — cash custody

### 2.1 Existing custody and Quick Market documents

Read-only production snapshot for the Buyer:

| Measure | Verified value |
|---|---:|
| Acknowledged / actually paid cash custody | EGP 5,000.00 |
| Existing purchase invoices charged to `EMPLOYEE_CUSTODY` | 2 |
| `PINV-1002` | EGP 1,000.00 — Draft / not received |
| `PINV-1003` | EGP 430.00 — Draft / not received |
| Total open Quick Market reservation | EGP 1,430.00 |
| Cash available before other expenses/returns | EGP 3,570.00 |
| Submitted/approved custody expenses | 0 |
| Returned cash | EGP 0.00 |

Both invoices have:
- `purchase_source='QUICK_MARKET'`;
- `settlement_source='EMPLOYEE_CUSTODY'`;
- `cash_custody_id` linked to the Buyer's existing custody;
- `purchase_order_id IS NULL`;
- `settlement_status='UNSETTLED'`;
- `receipt_status='NOT_RECEIVED'`;
- `status='Draft'`, `paid_amount=0`, `is_received=false`, `received_date IS NULL`.

These are existing records. They were not created or modified by this review.

### 2.2 UI cause

In `companies/company-1/purchasing/buyer.html`:

- `quickMarketCashReservation()` already reserves Quick Market amounts only when `settlement_source='EMPLOYEE_CUSTODY'`, subtracting amounts already linked to Submitted/Approved custody expenses to avoid a second deduction.
- `renderCustody()` correctly displays the open Market invoices and explains that the reservation is not yet an approved expense or journal.
- The submission button is labeled `تسوية فاتورة شراء PO`.
- `submitCustodyExpense(custodyId)` selects only invoices where `purchase_order_id` is non-null, validates a completed PO Receiving row, PO code and PO-linked receipt evidence, then calls `SUBMIT_CUSTODY_EXPENSE`.
- Consequently, a no-PO Quick Market invoice is excluded before it can be submitted.

The cash tab also renders a second copy of the physical-goods balance inside the cash custody detail. This duplicates the dedicated `عهدة بضاعتي` tab and blurs the two ledgers. The goods balance should live in the goods tab; the cash tab may show a navigation hint, not a duplicate goods ledger.

### 2.3 Server-side cause and financial risk

The current `buyer_custody_submit_expense_atomic` requires:
- a purchase invoice with `purchase_order_id IS NOT NULL`;
- a matching PO and supplier;
- a completed Receiving record keyed by the PO code;
- matching Receiving detail quantities.

It explicitly raises `CUSTODY_PURCHASE_INVOICE_NOT_LINKED_TO_PO` for a no-PO invoice.

The existing `buyer_custody_review_expense_atomic` is also PO-specific. On approval it:
- debits Supplier AP account 211 and credits Employee Custody account 127;
- creates a `buyer_custody_payments` supplier-payment record;
- debits the supplier ledger;
- marks the invoice Paid.

That path is valid for the existing PO supplier-liability workflow, but it is **not valid for a Quick Market invoice whose settlement source is Employee Custody** when the Buyer has already paid the supplier from the cash advance. Reusing it would create a false supplier AP/payment settlement and could double-settle the supplier.

The expense table currently supports `expense_type IN ('PURCHASE_INVOICE','OPERATIONAL')`. Quick Market merchandise must remain a Purchase Invoice claim; it must not be reclassified as `OPERATIONAL`, which is reserved for transport, fuel, tolls and other operating costs.

### 2.4 Required cash-purchase contract

Add a separate server-validated Quick Market cash branch while preserving the PO branch unchanged:

1. Submission is permitted only for the Buyer's own invoice, same company, same custody, `QUICK_MARKET + EMPLOYEE_CUSTODY`, matching currency/supplier/invoice number and a still-open custody.
2. It requires a Receiving document linked by **invoice ID**, with accepted quantities reconciled against every invoice line. Draft save and supplier handover alone are not warehouse receipt.
3. The existing cash reservation remains active until the purchase claim is submitted/approved; submitted/approved claim amounts replace the corresponding reservation without double counting. The current formula `ActuallyPaid - CommittedExpenses - OpenQuickMarketReservations - ReturnedCash` remains authoritative.
4. Finance/Finance Manager reviews; self-review remains forbidden.
5. On approval, the merchandise recognition/employee-custody clearing is **Dr Inventory 124 / Cr Employee Custody 127**, for the reconciled accepted purchase value, with one idempotent journal link. The invoice and claim are updated together.
6. This cash-funded Quick Market branch creates **no** Supplier AP 211, no `supplier_ledger` credit/debit, no `buyer_custody_payments` supplier-payment row, and no additional Treasury Payment: the original cash left the employee custody when the advance was physically acknowledged.
7. Existing PO supplier-credit review and generic operational-expense review remain isolated and unchanged.

The proposed approach can retain `expense_type='PURCHASE_INVOICE'`; a separate source-aware branch is needed in the submit/review writers. Do not add a new expense type unless a further complete consumer/constraint audit demonstrates that it is necessary.

### 2.5 Missing no-PO Receiving route

Production `receive-purchase` Edge Function is ACTIVE v14. Its request contract accepts `po_code` and calls `receive_purchase_atomic`, which resolves a Purchase Order, writes PO-linked Receiving details, posts inventory movements and books supplier AP/ledger credits. It has no `invoice_id` mode and must not be reused unchanged for a cash-funded Quick Market invoice.

The Receiving header currently has no dedicated `purchase_invoice_id` column. An invoice-ID Receiving mode therefore needs a first-class, company-scoped invoice link (or an equally strong already-existing immutable document relation demonstrated by a complete consumer scan); a text-only invoice-code convention is not an acceptable substitute for a foreign-key/document identity.

The Quick Market receiving writer must:
- authenticate an active warehouse receiver in the correct company/branch;
- validate QMP invoice ownership/source and per-line quantities;
- create an invoice-linked Receiving header/details with an idempotency key;
- add only accepted quantities to branch stock exactly once;
- leave rejected/unpresented quantities in Buyer goods custody;
- update receipt progress accurately, without writing Supplier AP or a supplier-ledger entry for `EMPLOYEE_CUSTODY`;
- leave financial clearing to the explicit Finance review above.

---

## 3. Current production evidence — goods custody

### 3.1 Ledger and aggregate contract

Production `buyer_goods_custody_events` is the canonical append-only event ledger:
- authenticated users have no direct INSERT/UPDATE/DELETE; writes are through authorized RPCs;
- update/delete are prohibited; corrections require compensating events;
- `buyer_goods_custody_get_balances_atomic` sums all event `qty_delta` grouped by custodian, branch and item;
- the balance query has no event-type filter and no vehicle requirement;
- grouped balances use the full event history; the recent-event list is capped to 200 only;
- vehicle is optional metadata, not the balance key.

Therefore the aggregate itself is not hiding warehouse-originated or market-originated goods.

### 3.2 Current event state

Read-only production snapshot:

| Measure | Verified value |
|---|---:|
| Buyer goods custody events | 0 |
| Stock vouchers for the company | 0 |
| Stock vouchers with assigned custodian | 0 |
| SupplierReturn vouchers | 0 |
| SupplierReturn vouchers with assigned Buyer | 0 |

There is no goods balance today because neither a warehouse-to-Buyer issue nor a supplier-to-Buyer handover has been posted for these records. The two current QMP invoices remain not received and have no goods events. A saved invoice is not proof that goods physically entered the Buyer's possession.

### 3.3 Existing Supplier→Buyer market handover is valid

Buyer `recordQuickMarketHandover()` already:
- loads invoice-line handover progress;
- asks the Buyer for actual received quantity per invoice line;
- requires supplier handover evidence;
- allows vehicle metadata optionally;
- calls `REGISTER_QUICK_MARKET_HANDOVER`.

The Production RPC `buyer_goods_custody_register_handover_atomic` validates Buyer ownership, QMP Draft/not-received state, invoice lines, remaining quantities, evidence object/path and operation fingerprint, then inserts positive `SUPPLIER_TO_BUYER_QUICK_MARKET` events. It does not change branch stock, AP or supplier balance. This route is correct for the physical market handover and should remain independent of the invoice-save action.

### 3.4 Confirmed warehouse-to-Buyer integration gap

The live `enforce_stock_voucher_custodian()` trigger currently does this:

```sql
IF NEW.type NOT IN ('DirectSale','DirectReturn') THEN
  NEW.custodian_user_id := NULL;
  RETURN NEW;
END IF;
```

The two allowed mobile types are further restricted to a direct-sales representative with `van-sales` permission and a Vehicle endpoint. This is not the Buyer procurement-custody contract.

Additional confirmed gaps:
- warehouse `vouchers.html` SupplierReturn route chooses source branch and supplier only; it has no Buyer custodian/recipient selector;
- `send_stock_voucher_atomic` delegates to the central stock-send core, which supports only `Transfer`, `DirectSale`, `DirectReturn`, and `SupplierReturn`; it adds a Driver ledger only for DirectSale, not a Buyer goods event;
- `complete_manual_stock_voucher_atomic` delegates to its existing core; there is no Buyer goods acceptance writer;
- `WAREHOUSE_TO_BUYER_SUPPLIER_RETURN` exists as an allowed positive event type but no live writer currently creates it;
- the existing Buyer goods tab footer acknowledges that warehouse/supplier acceptance flows are still future work.

### 3.5 Required warehouse issue and acceptance contract

Create a distinct Buyer-custody warehouse issue/recipient workflow inside the existing central stock-document architecture. Do not overload DirectSale, DirectReturn or ordinary Branch Transfer.

The exact stock-document type and its integration points must be finalized against all current create/edit/send/complete consumers before implementation. The required invariants are:

1. A warehouse user selects the active Buyer recipient, source branch and item quantities in a dedicated stock issue purpose; the central Parent/company identity and branch permissions remain authoritative.
2. The voucher stores the Buyer `custodian_user_id` without being cleared by the current mobile-custodian trigger. Buyer recipient validation must be based on active same-company Buyer identity/effective `purchases` permission, not the Direct Sales role or `van-sales`.
3. The source stock is reduced through the canonical stock movement writer exactly once. The corresponding positive Buyer event is appended atomically for the same item/quantity/document/operation. A Draft voucher creates neither stock movement nor goods custody.
4. The Buyer event ledger remains append-only and idempotent. Retries with the same operation/payload return the original result; reuse with a different payload is rejected.
5. Vehicle stays optional and does not determine whether the balance appears.
6. A later warehouse return/acceptance creates a negative Buyer event only for the quantity actually accepted, while the canonical inventory writer restores that quantity to branch stock once.
7. A later Supplier acceptance creates a negative Buyer event only for the supplier-accepted quantity. Financial return handling (cash received versus credit note/offset) is a separate evidenced settlement; do not infer a cash refund or supplier AP from goods acceptance alone.
8. All related events must link to the original voucher/source line and acceptance document so that partial receipts and audit history remain traceable.

Existing event type `WAREHOUSE_TO_BUYER_SUPPLIER_RETURN` should be used only for the exact delegated SupplierReturn meaning it encodes. If the required warehouse issue is broader than supplier-return delegation, add a separately named event type and constraint only after the stock-document design is finalized; do not mislabel generic issued goods as a supplier return.

---

## 4. Buyer UI and refresh corrections

Proposed surgical UI scope in `companies/company-1/purchasing/buyer.html`:

- `renderCustody()`: retain cash-only balances, reservations, expense claims and cash returns; remove the duplicate goods balance block and replace it with a link/hint to `عهدة بضاعتي`.
- Add an explicitly named action for a cash-funded Quick Market invoice claim, distinct from `تسوية فاتورة شراء PO`.
- Show the QMP cash claim only after invoice-linked warehouse receiving satisfies the accepted-quantity rules. Keep the existing PO button and validation isolated.
- `submitCustodyExpense()`: retain its current PO branch unchanged; route QMP invoices to the new source-aware no-PO operation and include both invoice and warehouse receipt evidence. Do not call the existing PO-only writer for QMP.
- `renderVehicleBalance()`: show warehouse and supplier inflows plus accepted warehouse/supplier outflows from the canonical event ledger; retain item/branch grouping, optional vehicle display and append-only history.
- `startRealtime()`: add invoice, invoice-detail and linked Receiving changes to the `custody` refresh target. Add stock-voucher/acceptance event subscriptions only after their actual company/branch columns and RLS scopes are verified. Keep the `vehicle` / goods tab target.
- Keep cash custody and goods custody separate; do not show vehicle stock as a substitute for Buyer's physical-custody ledger.

No Parent `main.html` or Core-wide redesign is indicated by the evidence so far.

---

## 5. Exact implementation boundary proposed for owner approval

### Existing operational files / Edge routes to extend
1. `companies/company-1/purchasing/buyer.html` — cash/goods UI separation, QMP claim UI, Realtime targets, warehouse goods balance/history labels.
2. `companies/company-1/warehouse/vouchers.html` — dedicated Buyer-custodian selection for the approved warehouse issue purpose; no change to unrelated voucher types.
3. Existing `save-purchase-order` Edge v37 — add narrowly scoped operations for QMP cash purchase submission/review and goods ledger actions as needed; no new Edge function.
4. Existing `receive-purchase` Edge v14 — add an authenticated `invoice_id` mode for Quick Market while preserving `po_code` mode.
5. Existing stock-voucher create/send/complete Edge routes — only the operations required to carry the new dedicated Buyer-custody issue and accepted return through the established central stock-document writer.

### SMART ERP schema / RPC changes to design and verify before applying
- invoice-linked Receiving header identity (current Receiving header has no `purchase_invoice_id`);
- source-aware QMP cash submission/review branches in the existing purchase-custody RPCs, without changing the PO/AP branch;
- invoice-ID Quick Market Receiving atomic writer (or a proven compatible existing central writer);
- dedicated Buyer-custody stock issue handling in the stock-voucher trigger and central send/completion wrappers;
- append-only, idempotent Buyer goods events for warehouse issue and accepted warehouse/supplier outflows, with event constraints and source-document links;
- RLS/ACL and effective permission checks for warehouse issuer, Buyer recipient and Finance reviewer;
- Realtime publication/consumer verification for any new source tables.

No schema/SQL should be drafted for application until the full current definitions, all callers, grants, triggers, event constraints, inventory movement semantics and rollback path are assembled into the final executable ChangeSet.

---

## 6. Acceptance and safety tests required before closure

All tests must run against a disposable isolated database or inside a fully rolled-back transaction with explicit before/after snapshots. No permanent QA invoice, voucher, cash, stock, supplier, payment or journal entry may remain in SMART ERP Production.

### Cash custody
- Existing PO supplier-credit expense path still works and posts only its existing AP/employee-custody settlement.
- QMP `EMPLOYEE_CUSTODY` cannot be submitted before invoice-linked warehouse acceptance.
- No PO required for QMP cash; PO is not fabricated.
- Partial receipt cannot clear the unaccepted invoice balance.
- Finance self-review is denied; other companies/users/custodies are denied.
- QMP cash approval creates Dr124/Cr127 once, and creates no account-211 movement, Supplier AP, supplier-ledger row, supplier payment, second Treasury payment or duplicate GL.
- Submitted/approved claim replaces the QMP reservation once; available cash remains exactly `ActuallyPaid - CommittedExpenses - OpenQuickMarketReservations - ReturnedCash`.
- Duplicate, timeout/retry and payload-conflict behavior are tested.
- Rejected claims release the linked amount back into the same open reservation; they must not mark the invoice Paid.

### Goods custody
- Saving a QMP Draft alone creates no goods event, stock movement or finance posting.
- Supplier→Buyer handover adds only actual physically accepted quantities once, requires evidence and does not increase branch stock.
- Warehouse→Buyer draft voucher adds no balance; sending/issuing it decreases source stock and adds the Buyer event atomically once.
- Partial warehouse acceptance reduces Buyer custody/increases branch stock only by accepted quantity.
- Supplier acceptance reduces Buyer custody only by supplier-accepted quantity.
- Wrong Buyer, wrong company, unauthorized branch, wrong event type, over-issue, insufficient stock and mismatched item identity are denied.
- Vehicle null and non-null cases both show the same correct balance.
- Realtime updates only the currently active intended tab.
- Append-only event protections remain; corrections use compensating events.

---

## 7. Current source / deployment verification limits

- Operational GitHub main HEAD was re-read as `0fe255e3d9dae44332ee1863c43d9c1b0ea0ff79`.
- Buyer source was re-read from `companies/company-1/purchasing/buyer.html`; no changes made by this task.
- Warehouse voucher source was read-only inspected; no changes made.
- `save-purchase-order` v37, `receive-purchase` v14 and `complete-stock-voucher` v4 are the live versions observed by Supabase tools.
- Cloudflare served-asset parity and authenticated browser E2E were not verified as part of this forensic pass.
- Production SQL work in this pass consisted only of SELECTs. No test transaction or business write was executed.

---

## 8. Rollback outline for the eventual approved ChangeSet

Before any execution, retain exact pre-change definitions and SHA/hash snapshots for each altered RPC, trigger, constraint, Edge source and app file.

- Revert Buyer and warehouse UI source changes to their recorded pre-change blobs.
- Restore previous Edge source versions only for the touched existing functions.
- Restore previous SQL function/trigger definitions and event constraints in reverse dependency order.
- Remove only newly introduced columns/indexes/policies after proving no committed business document references them; never drop event rows or financial records as a rollback shortcut.
- Do not remove or rewrite existing Quick Market invoices `PINV-1002` or `PINV-1003`; the current forensic review has not changed either one.

---

## 9. Decision required

The defects and their causes are confirmed, but the repair crosses both cash-accounting and stock-movement contracts. Under the permanent operational constitution §6.2, this task request does not authorize an unreviewed new financial/stock posting contract.

**Owner approval requested for the complete scope in §5 and its invariants:**
- separate no-PO Quick Market `EMPLOYEE_CUSTODY` settlement, with full invoice-linked receiving and Finance posting Dr124/Cr127 only (no supplier AP/payment/Treasury duplicate);
- dedicated warehouse-to-Buyer stock issue and accepted outflow lifecycle through the central stock-document/event writers;
- the specified surgical Buyer UI/realtime separation and corresponding existing Edge route extensions.

After this scope is approved, the final executable SQL/source diff, posting examples, impact matrix, tests and rollback sequence must be presented before any Production write or operational source modification.

**Checkpoint:** FORENSIC REVIEW COMPLETE · ROOT CAUSES CONFIRMED · READ-ONLY PRODUCTION INSPECTION ONLY · NO CODE/SCHEMA/BUSINESS DATA CHANGED · WAITING FOR EXPLICIT CHANGESET APPROVAL.
