# Report614 — Buyer Goods Custody Ledger / Supplier Return Lifecycle / Integration Forensic Review

**Date:** 2026-11-04 — Africa/Cairo  
**Starting checkpoint:** LVE-2026-11-04-613 / Report613.  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`.  
**Production:** SMART ERP / `fiilmooggumokxanwiyx`.  
**Status:** READ-ONLY FORENSIC REVIEW COMPLETE / ROOT CAUSES CONFIRMED / TARGET CONTRACT PROPOSED / IMPLEMENTATION AND OWNER APPROVAL GATE OPEN.  
**Change status:** No operational source, database schema/data, RPC, Trigger, RLS, Edge Function, or deployment was changed in this review.

---

## 1. Executive decision

Buyer tab `رصيدي` is not an operational goods-custody ledger. It is currently a static explanatory screen. The database contains a separate cash-custody module (`buyer_custodies`) but no item-level Buyer goods-custody ledger. The Warehouse manual SupplierReturn document currently transfers stock from a branch directly toward a supplier; it cannot assign an active Purchasing Officer as the physical custodian. The live database Trigger clears `custodian_user_id` for every voucher type other than `DirectSale` and `DirectReturn`.

Two independent return posting paths are present:
1. Manual Warehouse `stock_vouchers` / `SupplierReturn`.
2. Parent purchase-cycle `purchase_returns` with `purchase_post_return_atomic`.

Both are capable of reducing branch stock and supplier payable independently. They are not linked by a unique source-document relationship. Integrating both lists without a single-writer contract risks duplicate inventory reduction and duplicate supplier-AP / journal effects.

The current quick-purchase action in Buyer is only an alias for creating a Draft purchase invoice. It does not record supplier-to-Buyer physical custody, does not create a Buyer-to-warehouse handover, and the existing Receiving Edge/RPC accepts PO code rather than a standalone invoice reference.

**Conclusion:** This is a business-contract and server-ledger change, not a presentation-only change. Do not replace the static screen with calculated numbers until a central, immutable event contract exists. Do not enable Buyer custodian selection on SupplierReturn until the Trigger and posting lifecycle are changed together. Do not merge the two return screens or invoke both posting paths for the same goods.

---

## 2. Starting state and source fingerprints

### 2.1 Current operational Git state

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Latest observed operational HEAD: `e8ab54c75572e15e71581212479d22be139c8020`.
- Latest HEAD is one commit after the Parent source patch `3f4d48b6acfc5c5e70d2d6a09278a4bc3fd5d954`; the following commit only adds `_forensic_current_main_extract.md`.
- Buyer source: `companies/company-1/purchasing/buyer.html`, blob `311f2673a90149df6f56d59a9a187a3379e6981c`.
- Parent source: `companies/company-1/main.html`, blob `f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca`.
- Warehouse vouchers source: `companies/company-1/warehouse/vouchers.html`, blob `85e709d0f41c189c6624a6160965d3b1a41960ba`.
- Receiver source: `companies/company-1/warehouse/receiver.html`, blob `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`.
- Core source remains `f4c6a0df441e0da9105d4fe7ce94ad2d7a1735e1`.

### 2.2 Current governing documents

- Latest `CURRENT_STATE.md` before this report records LVE613 and Report613.
- Permanent operating charter: `doc/Draft/Reprots/الدستور التشغيلي الدائم.md`, blob `d2afa896514b1cb6abd247d2af7a862251ce0604`.
- Master CTO Governance: `doc/Draft/Reprots/MASTER CTO GOVERNANCE & CONTINUOUS EXECUTION OS — RAWAEA ERP.md`, blob `1a0c81c2984103b5a7f3b40db41607d74051b310`.
- The applicable owner gate is Master CTO §77.2 and the permanent charter §§6.1–6.2: show the exact change set, full proposed SQL/source, business impacts, dependencies, acceptance tests and rollback; wait for explicit approval of that exact set.
- The applicable preservation rule is §77.3: do not edit `companies/company-1/main.html`; do not create new Edge Functions.

---

## 3. Buyer — actual current behavior

### CONFIRMED — `رصيدي` is a placeholder

- Buyer includes the `vehicle` tab label as `📦 رصيدي`.
- The current screen is a static explanation of the future Buyer goods-custody lifecycle. It does not query an item-level custody ledger and cannot compute a live balance.
- It explicitly avoids using fleet/vehicle stock as the Buyer balance, which is correct: Buyer physical custody must not depend on vehicle assignment.
- Buyer Realtime currently covers purchase documents and cash-custody tables, but it does not subscribe to a Buyer goods-custody movement source or to `stock_vouchers` for this purpose.

### CONFIRMED — cash custody and goods custody are separate domains

- `buyer_custodies`, `buyer_custody_advances`, `buyer_custody_expenses`, `buyer_custody_payments`, and `buyer_custody_settlements` are the cash-advance/expense/settlement workflow.
- `buyer_custodies` has employee, issued amount, currency, issue date, branch, status, operation identity and references. It has no item/quantity movement detail. It must not be repurposed as a goods ledger.
- Buyer `عهدتي` remains cash custody. Buyer `رصيدي` must be a separate item-quantity custody ledger, while financial settlement continues to use its existing cash-custody contract.

### CONFIRMED — Quick Purchase is not yet a physical purchase workflow

- `quickPurchase()` calls `createPurchaseInvoice()`.
- `createPurchaseInvoice()` calls existing `CREATE_INVOICE` through `save-purchase-order` and creates a Draft purchase invoice. The purchase order reference is optional.
- No supplier-to-Buyer event is recorded when the supplier physically hands over market goods.
- No Buyer-to-warehouse handover is created from that Draft invoice.
- Existing `submitCustodyExpense()` selects Draft invoices only when they have a PO and requires a completed Receiving document. This path cannot complete settlement of a quick invoice without a PO and does not currently link the market invoice to an independently recorded Buyer-held receipt.
- The invoice is not proof of warehouse receipt. The approved policy in Master CTO §77.4 / permanent charter §6.3 remains binding: Draft invoice alone causes no inventory, treasury, supplier-balance or journal effect.

---

## 4. Warehouse manual SupplierReturn — actual current behavior

### CONFIRMED — UI does not select the Buyer custodian

In `companies/company-1/warehouse/vouchers.html`:
- `routeHtml()` for `SupplierReturn` displays source branch and destination supplier only.
- The Buyer/employee picker is absent for this type.
- The `rep_id` is passed generically in create/update requests, but no UI value is populated for SupplierReturn.
- The form also provides the existing Supplier Return Contract and Evaluation workflow (`openSupplierReturnContract`, `saveSupplierReturnContract`).

### CONFIRMED — the existing server contract discards SupplierReturn custodian

Production Trigger `enforce_stock_voucher_custodian()` begins by clearing `NEW.custodian_user_id` and returning whenever `NEW.type` is not `DirectSale` or `DirectReturn`. Those two mobile-sales types additionally require a Vehicle endpoint and an active direct-sales representative with `van-sales`; those validation rules must remain intact.

The stock-voucher constraint `stock_vouchers_mobile_custodian_required_ck` only requires a custodian for DirectSale/DirectReturn. It does not provide a valid Buyer custody contract for SupplierReturn.

The live wrapper/core `create_manual_stock_voucher_atomic` / `create_manual_stock_voucher_atomic_core_12_20260828` accepts `p_rep_id`, but SupplierReturn validation only checks:
- source is a valid Branch;
- destination is an active Supplier;
- source/destination entity types are correct.

It does not validate a Purchasing Officer as custodian and does not preserve `p_rep_id` as custodian.

### CONFIRMED — current SupplierReturn timing

- Manual SupplierReturn is created as Draft.
- Existing send function/core (`send_stock_voucher_atomic`) posts the stock-out movement from the source branch and marks the voucher Sent.
- Existing completion function/core (`complete_manual_stock_voucher_atomic_core_20260828`) validates supplier/return-contract details and posts the supplier-ledger debit and GL journal for the return total before marking the voucher Completed.
- The existing contract validates supplier, return reason, return address, inspection/disposition and positive item/value amounts.
- It does not establish Buyer intermediate custody, per-line supplier-accepted quantity, or supplier acceptance evidence for a partial receipt.
- The current list/report logic treats SupplierReturn as a creator/admin completion task after Sent; there is no Buyer-held stage that remains open until the supplier accepts the goods.

Therefore the current route is Branch → Supplier, not Branch → Purchasing Officer → Supplier.

---

## 5. Duplicate supplier-return posting paths

### Path A — Warehouse manual voucher

- Document: `stock_vouchers` with `type='SupplierReturn'`.
- Physical writer: `send_stock_voucher_atomic` / core posts stock out of the source branch.
- Financial writer: `complete_manual_stock_voucher_atomic` / core posts a Supplier Ledger debit and GL journal for the full return total.
- Buyer custody event: absent.

### Path B — Parent purchase-cycle return

- Parent `RW_PurchaseGold.returnsView()` reads `purchase_returns`.
- Parent `createReturn()` limits the return quantity from actual invoice detail `received_qty`.
- Existing `save-purchase-order` Edge v22 maps `POST_RETURN` to `purchase_post_return_atomic(p_company_id,p_return_id,p_actor)`.
- `purchase_post_return_atomic` posts `SupplierReturn` movement to `inventory_log`, posts a journal using Supplier/AP and Inventory accounts, inserts a debit to `supplier_ledger`, and changes the return status to Posted.
- `purchase_returns` has no `stock_voucher_id` link; `stock_vouchers` has no `purchase_return_id` link.
- `purchase_returns.purchase_invoice_id` is currently NOT NULL, so it cannot represent every manual/market return that is not tied to an existing purchase invoice.

### Risk

The same physical goods can be represented once in `stock_vouchers` and again in `purchase_returns`. If both independent posting functions are completed, the same goods may be removed twice from branch inventory and the supplier balance may be reduced twice. Do not create a Parent aggregate that simply unions both datasets and still allows both posting buttons.

**A single-writer rule is mandatory:** one approved document/event must own the physical stock-out; one linked accepted-return posting may own supplier AP/GL; the second path must be a linked projection/workflow step, not another independent stock/finance writer.

---

## 6. Production database baseline — read-only

Project: `fiilmooggumokxanwiyx` (SMART ERP).

### Current row evidence at review time

The read-only counts returned zero for:
- `stock_vouchers` total and SupplierReturn subset.
- `purchase_returns`.
- `inventory_log` rows with `movement_type='SupplierReturn'`.
- `buyer_custodies`.

No test, operational, or QA rows were inserted, updated or deleted during this review.

### Relevant schema evidence

- `stock_vouchers` has `custodian_user_id`, `receiver_user_id`, `purchase_invoice_id`, `purchase_order_id`, supplier-return contract/amount fields, and company/branch/source/status references.
- `stock_voucher_details` has item and quantity/value fields, including `received_qty`; its exact meaning for supplier acceptance was not established, so do not reuse it without a contract and tests.
- `buyer_custodies` is money-only and has no item/quantity ledger.
- `purchase_returns` / `purchase_return_details` are separate financial/stock return records.
- `receiving` currently has `po_number` text, not a `purchase_invoice_id` foreign key.
- `receiving_details` currently does not have a `purchase_invoice_detail_id` foreign key.
- `purchase_invoices` allows a nullable `purchase_order_id`, but it does not have a proven direct Receiving relationship for a quick no-PO invoice.
- There is no dedicated Buyer goods custody header/detail/event table in the current schema.

### Role evidence

The active users aggregation returned one active user with role `مسئول مشتريات`. Warehouse permission roles include two active `مخزني / أذونات` users and one `مخزني / استلام` user. Role labels alone are not authorization: any future custody operation must validate the current effective user/company/permissions and branch scope server-side.

---

## 7. Edge/API parity and architectural constraints

### Current deployed Edge inventory

- `save-purchase-order` v22 ACTIVE, JWT verified, SHA `a0885a8a636b0d57ef9ab54b476001be8e3dd1f4227b921f511b002f58642ffb`.
  - Handles Draft invoices, current `CREATE_RETURN` / `POST_RETURN`, and cash custody operations.
  - `POST_RETURN` requires both purchases and finance permissions.
- `receive-purchase` v13 ACTIVE, JWT verified. Input is `po_code` plus `itemsReceived`; it calls `receive_purchase_atomic` using `p_po_code`. It has no invoice-ID based quick receipt contract.
- Existing stock voucher Edge functions are deployed and active. No new Edge Function is needed or permitted.
- The exact deployed Edge source for all stock voucher functions is not in exact parity in the operational Git source. Recover and fingerprint the deployed source before changing any Edge behavior.

### Parent preservation constraint

The current Parent `returnsView()` in `companies/company-1/main.html` reads only `purchase_returns` and displays code/value/status/action. It does not read manual `stock_vouchers`, and it does not display a recipient column.

The requested Parent recipient column therefore requires a Parent source change or an explicitly approved alternative integration path. Current governing §77.3 prohibits editing `main.html`; this report does not bypass that restriction with runtime injection or a shadow view.

### Staging / Runtime limitation

- The staging project is not schema-parity with Production (62 migrations / 70 public tables per LVE613) and cannot validate the whole Buyer/warehouse/Parent procurement cycle.
- No authenticated browser session is available in this review for Buyer/Receiver/Parent E2E.
- Cloudflare served-artifact parity is not verified in LVE613.
- No E2E claim is made.

---

## 8. Proposed target business contract — not yet implemented

### 8.1 Separate cash custody from goods custody

Keep `buyer_custodies` for cash and expense documents. Introduce a separate immutable **Buyer Goods Custody Ledger** at item/quantity granularity, company-scoped and permission-controlled.

The ledger should record source and destination events, not a manually editable balance. Each event should carry at minimum:
- company, branch, custodian user;
- item ID/code, unit and positive quantity;
- movement/event type and timestamp;
- source document type/ID/code and source line ID;
- linked target document/line where applicable;
- actor, evidence references, notes and operation/idempotency key;
- reversal/correction reference and audit metadata.

Balance must be derived from posted custody events. Corrections must be compensating events; no direct balance edits or deletion of posted events.

### 8.2 Supported goods custody movements

1. **Warehouse → Buyer (SupplierReturn handed to Buyer):** warehouse creates a SupplierReturn voucher with the Purchasing Officer selected as custodian. On actual dispatch/hand-over, branch stock decreases once and Buyer goods custody increases by the issued quantity. No supplier AP, GL, or treasury effect occurs at this stage. Vehicle is optional and does not define custody.
2. **Supplier → Buyer (Quick market invoice):** Buyer records a market invoice Draft and separately confirms actual physical handover from supplier to Buyer. Goods custody increases. Draft invoice creation alone still has no stock/AP/GL/treasury effect.
3. **Buyer → Warehouse (purchase receipt):** Buyer submits a handover; Receiver validates and records accepted/rejected quantities against invoice lines. Accepted quantity reduces Buyer custody and increases the selected branch stock once through the central stock writer. Rejected or undelivered quantity remains in Buyer custody or moves through a separately evidenced supplier return.
4. **Buyer → Supplier (SupplierReturn handover):** Buyer records supplier acceptance evidence and accepted quantity per line. Only the quantity actually accepted by the supplier reduces Buyer custody and creates the authorized supplier AP/GL return effect. Any unaccepted balance remains in Buyer custody.
5. **Direct Supplier receipt (default option):** when the supplier receives directly from the warehouse, no Buyer custody event is created. The document records Supplier as the physical recipient and requires supplier acceptance evidence before the AP/GL reduction. This direct route remains available.
6. **Corrections:** use compensating events and a reason/actor/evidence record. Do not rewrite historical movement rows.

### 8.3 Return document ownership and one-writer design

Recommended separation:
- `stock_vouchers` remains the warehouse physical issue/dispatch evidence and is the **only physical stock-out writer** for a linked manual SupplierReturn.
- A single linked purchase-return financial record (or a successor canonical SupplierReturn header) records invoice/PO context, supplier acceptance quantities/evidence, accepted value, supplier ledger and journal effect.
- A unique immutable link between the physical voucher and its financial return record is mandatory. An accepted return linked to a physical voucher must not call `post_stock_movement` a second time.
- The current `purchase_returns` requirement for non-null invoice reference must be assessed before manual/standalone returns can be represented. If an invoice is legitimately optional, the schema and all consumers must be changed in a controlled migration; otherwise a new canonical return header is required.
- Direct supplier receipt and Buyer custody are two recipient modes on the same business return, not two different financial-return mechanisms.
- A uniqueness/idempotency constraint must prevent the same voucher, line and accepted quantity being posted twice.

This is a target contract proposal. The final owner change set must settle the canonical header choice, precise accepted-quantity model, foreign keys, trigger rules and RPC signatures before implementation.

### 8.4 Quick Market invoice / receiving link

- A Draft invoice remains a document, not stock receipt or AP posting.
- The Buyer physical supplier-to-Buyer event must be explicit and auditable.
- Receiving must be able to identify the quick invoice and its invoice lines without requiring a PO.
- The current `receive-purchase` Edge/RPC is PO-code-only. Extend an existing authorized path/RPC (do not create a new Edge Function) to accept either a PO source or a quick invoice source while retaining tenant and branch permission checks.
- The accepted receiving quantities and actual handover evidence are the gate for stock/AP/GL effects under the already-approved procurement policy.
- Custody cash settlement remains separate: approved invoice + warehouse acceptance evidence can support cash-custody expense settlement, but must not be treated as proof of cash payment to supplier unless the treasury/payment evidence exists.

---

## 9. Buyer "رصيدي" UX target

Keep the tab name `رصيدي` if desired, but its subtitle should make the meaning explicit: **بضاعة في عهدتي — لا يشترط وجود سيارة**.

Recommended experience:
- Top summary: total SKU count, total units, awaiting warehouse, awaiting supplier acceptance, overdue handovers/exception count.
- Fast action tiles: `استلام مرتجع من المخزن`, `تسجيل شراء سوق واستلامه`, `تسليم للمخزن`, `تسليم مرتجع للمورد`.
- Item balance table: item/barcode, unit, opening quantity, received, delivered to warehouse, returned to supplier, current custody quantity, oldest custody age. All values derived from ledger events.
- Search by item name/code/barcode; filters by branch, supplier, event type, status and date.
- Each custody line opens the source voucher/invoice/receiving documents and evidence.
- Show the vehicle only as optional transport metadata; never group or filter the core goods balance by vehicle.
- Action buttons are status-aware and disable when the same quantity is already handed over/accepted.
- Realtime refresh includes the canonical ledger and its source documents; pagination must not silently cap the balance at 500 rows.
- Empty state explains how goods enter custody and offers the one correct next action; it must not display a fabricated zero if the ledger cannot be queried.

---

## 10. Parent Purchase Cycle — intended Returns register

Requested register should display at least:
- return code/date;
- supplier;
- physical recipient (Purchasing Officer, or Supplier for direct receipt);
- item count / requested quantity / supplier-accepted quantity;
- amount at accepted quantity;
- source voucher and linked invoice/PO;
- physical stage and financial posting stage;
- creator/actor and last update;
- evidence/exception indicator.

The `المستلم` column must be derived from a validated `custodian_user_id` when the Buyer physically received the goods; otherwise it should display the validated Supplier recipient. Do not use `created_by` as a substitute.

**Implementation remains blocked under the current no-`main.html` rule.** Prepare the exact Parent patch for owner-side application or obtain an explicit governance change before any Parent file write.

---

## 11. Required exact change set before any implementation

Per Master CTO §77.2 and permanent charter §§6.2, 8–10, the next implementation proposal must include full exact text and impact of all the following, without creating a new Edge Function:

1. **Schema/migration proposal:** canonical ledger header/detail or event table; item-level uniqueness/idempotency; company/branch/user/item foreign keys; evidence references; append-only correction references; link between SupplierReturn voucher and financial-return record; invoice-to-Receiving and invoice-line-to-Receiving-line linkage; accepted quantity and supplier acceptance evidence; indexes, RLS, policies, grants and Realtime publication.
2. **RPC proposal:** authenticated create/dispatch/receive/accept/reverse/read contracts. Validate `auth.uid()`, `get_my_effective_profile`, active user, company, permissions, branch scope, document states, quantity ceilings, accepted quantity, unique source links, operation identity. Do not trust client supplied actor or amount.
3. **Trigger/constraint proposal:** preserve all existing DirectSale/DirectReturn vehicle/driver rules; allow SupplierReturn custodian only for valid active Buyer role when recipient mode is Buyer; direct supplier receipt remains custodian-free; prevent impossible type/entity combinations; reject mutation after dispatch/acceptance except authorized compensating workflow.
4. **Existing Edge source changes:** extend existing `save-purchase-order` v22 and/or `receive-purchase` v13 plus existing stock voucher Edge paths. Recover current deployed stock Edge source and commit source parity before modification. Do not add a new Edge function.
5. **Buyer source proposal:** replace static `renderVehicleBalance` implementation; add actual event ledger read, summary, actions, Realtime subscriptions, direct invoice receipt handoff, search/filters, evidence handling and status-aware UX. Retain cash custody in `عهدتي`.
6. **Warehouse vouchers source proposal:** add explicit recipient mode (Supplier direct / Purchasing Officer), validated Buyer picker without Vehicle dependency, custodian persistence, physical handover stage, and partial supplier acceptance evidence.
7. **Receiver proposal:** support quick invoice receipt and invoice-line traceability without PO, with accepted/rejected quantity capture and central posting once.
8. **Parent view proposal:** recipient column and single canonical return register; no edit to `main.html` unless the governing lock is explicitly changed. Otherwise Parent item is an owner-side source patch.
9. **Regression contract:** preserve PO-linked receiving, existing DirectSale/DirectReturn and Transfer, existing cash custody, supplier master policy, and current purchase Draft behavior.

No production migration/RPC/Trigger/RLS/Edge/application change is authorized by this report alone.

---

## 12. Acceptance tests required before closure

### A. SupplierReturn to Buyer

- Create Draft with Branch → Supplier and recipient mode Buyer; selected user must be active, same company, effective Purchasing permission and valid branch scope.
- Draft creation and contract save must leave `stock_branches`, `inventory_log`, `supplier_ledger`, `journal_entries`, treasury and Buyer custody unchanged.
- At actual warehouse dispatch, branch quantity decreases exactly once and Buyer ledger increases exactly once by each dispatched line; supplier AP/GL remain unchanged.
- Buyer view shows only their own custody; no vehicle required and optional vehicle cannot alter balance.
- On partial supplier acceptance, accepted quantity reduces Buyer custody and supplier AP/GL effect occurs only for accepted quantity; remaining quantity remains in Buyer custody.
- Direct supplier recipient path creates no Buyer ledger event and posts AP/GL only after actual supplier acceptance.
- Retry/replay and concurrent acceptance tests prove idempotency and no negative quantity.

### B. Quick market invoice

- Create a no-PO Draft invoice: no stock/AP/GL/treasury effect.
- Record supplier-to-Buyer physical handover: Buyer goods custody increases; no branch stock/AP/GL/treasury effect.
- Transfer to warehouse and accept partial quantity: Buyer custody decreases only by accepted amount; branch stock increases once for accepted amount; AP/GL posts only according to approved receipt policy.
- Reject/short quantity: rejected amount remains in custody or follows an explicitly documented supplier return; no phantom inventory.
- Cash-custody submission must reconcile invoice + completed Receiving evidence, and cash is affected only by existing actual settlement/payment proof.

### C. Cross-application and regression

- Buyer ↔ Vouchers ↔ Receiver ↔ Parent recipient register cross references are correct.
- Realtime refresh works without duplicate rows and with pagination above 500.
- RLS denies other-company and unauthorized users; non-finance Buyer cannot see unrelated cash custody.
- Existing PO receipt, Transfer, DirectSale, DirectReturn, and manual SupplierReturn direct-to-supplier paths remain correct.
- Sum of custody events equals derived Buyer quantity by item and branch.
- Sum of supplier accepted-return events equals supplier ledger debit and balanced GL journal amounts.
- Inventory snapshot agrees with stock movement log and branch quantities.
- No duplicate event/stock/AP/GL/treasury effect after retries, refresh or network timeout.

### D. Environment / test data

Production real operating rows must not be used as test fixtures. Staging is currently not full-schema parity. Full E2E requires a separately governed schema-parity environment or an approved, transaction-rollback test path that demonstrably leaves no persistent state. No expiring persistent Production test record is permitted as a substitute.

---

## 13. Rollback and safety strategy

- Use expand/contract migrations; do not drop or repurpose existing cash custody or mobile-sales constraints.
- Preserve previous function definitions and source hashes before replacement.
- Feature-gate the new Buyer goods ledger and recipient path until all read/write contracts pass.
- New write path must be disabled until the full test matrix and permissions pass.
- For a faulty schema/API change before data use, roll back the additive migration and restore prior RPC/Trigger definitions.
- After actual stock/AP/GL events exist, do not delete rows or restore old function code blindly. Use compensating inventory movements, supplier-ledger reversal, balanced journal reversal and custody reversal events with source references and an audit record.
- Verify no cross-company access or duplicate operation after rollback.
- Keep all changes in the authorized repository/branch only; no separate branch unless the owner explicitly changes the repository workflow.

---

## 14. Evidence matrix and current status

| Area | Status | Evidence |
|---|---|---|
| CURRENT_STATE / latest LVE | CONFIRMED | LVE613 read; this review starts from its operational HEAD |
| Permanent charter | CONFIRMED | Blob `d2afa896514b1cb6abd247d2af7a862251ce0604` read in full |
| Buyer placeholder and quick-purchase alias | CONFIRMED | Current Buyer source blob `311f2673...` |
| SupplierReturn UI recipient picker absent | CONFIRMED | Current Vouchers source blob `85e709d0...` |
| SupplierReturn Trigger strips custodian | CONFIRMED | Production `enforce_stock_voucher_custodian()` |
| Current SupplierReturn stock/AP posting | CONFIRMED | Production send/complete function definitions and current code contracts |
| Separate Parent purchase_returns writer | CONFIRMED | Parent source and `purchase_post_return_atomic` |
| Buyer goods custody schema absent | CONFIRMED | Production public-table inventory |
| Quick invoice Receiving linkage absent | CONFIRMED | Production Receiving schema and Edge v13 input contract |
| Current row counts are zero for relevant test/return sets | CONFIRMED | Read-only Production count query |
| Direct user E2E / Runtime | UNVERIFIED | No authenticated browser session |
| Deployed Cloudflare artifact parity | UNVERIFIED | Not verified in this review |
| Full staging parity | CONFLICT / NOT READY | LVE613 records staging migration/table gap |
| Duplicate return integrity | ROOT CAUSE CONFIRMED / FIX OPEN | Two independent stock/AP writers with no document link |

---

## 15. Work performed and not performed

### Performed

- Read latest `CURRENT_STATE.md`, Report613, Report612 context, Master CTO Governance, latest permanent CTO protocol and the complete permanent operating charter.
- Re-fetched the current Buyer, Warehouse Vouchers, Receiver and Parent source fingerprints.
- Inspected Buyer goods balance and Quick Purchase code.
- Inspected Vouchers SupplierReturn UI, contract save workflow and payload.
- Read relevant Production table columns, constraints, triggers, RPC signatures/definitions, Edge versions and row counts.
- Inspected Parent Purchase Cycle return reader and the current `purchase_returns` posting function.
- Built the target process and acceptance/rollback design.

### Not performed

- No operational HTML/JS write.
- No `main.html` edit.
- No SQL migration or data write.
- No RPC/Trigger/RLS/GRANT/Realtime publication modification.
- No Edge Function source or deployment change.
- No new Edge Function.
- No test rows or fixture data.
- No browser E2E, signed Edge request, warehouse physical test or Cloudflare deployment verification.
- No claim that Buyer goods custody or the Parent recipient column is implemented.

---

## 16. Exact next step / approval gate

**Next stage:** prepare the complete implementation Change Set from this target contract:
- exact additive SQL/migration;
- exact replacement RPC/Trigger bodies;
- exact changes to the existing Edge sources after recovering their production parity;
- exact Buyer and Vouchers code diffs;
- exact Receiver contract change;
- exact Parent owner-side patch proposal or the explicitly permitted alternative to the locked `main.html`;
- full impact matrix and rollback.

Then present that exact set under Master CTO §77.2 for explicit owner approval before any operational write or Production action.

**Current workstream status:** NOT CLOSED / NOT IMPLEMENTED / NOT PRODUCTION READY. The root causes and the required lifecycle are now evidenced and documented; the next gate is the exact change set and owner review.
