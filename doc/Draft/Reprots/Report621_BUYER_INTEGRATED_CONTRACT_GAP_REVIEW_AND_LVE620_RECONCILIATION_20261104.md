# Report621 — LVE620 Reconciliation / Buyer Goods Custody Integrated Change Review

**Date:** 2026-11-04 — Africa/Cairo  
**Starting evidence:** CURRENT_STATE LVE616, CTO Execution Log LVE620, Project Memory LVE620; Reports606 and 614–620; live GitHub and SMART ERP reads.  
**Operational repository:** `papamohammed77-glitch/erp-frontend` / `main`.  
**Production:** Supabase SMART ERP / `fiilmooggumokxanwiyx`.  
**Status:** LVE620 RECONCILED / V4 SCHEMA REVIEW DRAFT PREPARED / REMAINING FUNCTION + EDGE + APP CHANGE SET OPEN / NO OPERATIONAL OR PRODUCTION WRITE.

---

## 1. Executive decision

This is a continuation of the work already recorded through Report620, not a new design from zero. The durable sources were inconsistent: CURRENT_STATE still opened at LVE616, while the Execution Log and Project Memory had advanced through LVE620. This report reconciles that history and advances the implementation package without changing operational source or Production.

The target is now clear:

- **Buyer goods custody is an append-only item event ledger**, separate from cash `buyer_custodies` and independent of Vehicle/Fleet.
- **Supplier Direct is the default SupplierReturn recipient.** Buyer Delegate is an explicit exception backed by written supplier delegation reference and private evidence.
- **Warehouse dispatch owns the only branch stock-out.** A linked Parent return row owns the commercial/financial case. Supplier acceptance batches own the accepted quantities and the supplier AP/GL posting. The linked finance posting must never issue stock a second time.
- **Quick Market** is a Draft invoice, then a real Supplier→Buyer handover, then Receiver acceptance per invoice line. Invoice save alone does not receive stock or create AP/GL/Treasury/cash effects.
- **Cash purchases, Supplier Credit, Treasury Cash and operating expenses are distinct accounting sources.** A cash purchase paid by the Buyer from employee custody must not create a Supplier AP or a second Supplier Payment.
- No new Edge Function. Extend the six current deployed functions only.
- Parent `main.html` remains under the current no-edit rule; its `المستلم` column remains an owner-side patch to be applied by the owner.

No Source/Production write was performed. Report621 and schema v4 are review artifacts only.

---

## 2. Durable state reconciliation

### 2.1 Last verified project work

- `CURRENT_STATE.md` at the time of review still opened at LVE616.
- `CTO/02_EXECUTION_LOG.md` records LVE620 at the top:
  - Report620: Existing Edge Function Extension Contract.
  - Report619: Buyer custody RPC / single-writer posting contract.
  - Report618: Buyer goods custody / Quick Market UX.
  - Report617: SupplierReturn recipient and currency.
  - Report616: Receiver patch + schema scaffold.
  - Report615: security / returns / Quick Market revalidation.
- `Current/CTO/RAWAEA_PROJECT_MEMORY_117-02.md` also records LVE620 at the top.
- The last operational HEAD already recorded by those reports remains `e8ab54c75572e15e71581212479d22be139c8020`; no operational commit was added in this review.
- The current permanent operating charter is `الدستور التشغيلي الدائم.md`, blob `d2afa896514b1cb6abd247d2af7a862251ce0604`.
- Master CTO governance §77.2–77.4 remains binding.

### 2.2 Relevant reports

- Report606 — owner decisions / integrated operational direction.
- Report615 — procurement, Quick Market, SupplierReturn, security and competitive design.
- Report616 — precise Receiver source patch and initial schema scaffold.
- Report617 — SupplierReturn delegated recipient and P0 currency patch.
- Report618 — Buyer `رصيدي` and Quick Market UX.
- Report619 — RPC / single-writer posting contract.
- Report619-LVE616 — review of first SQL scaffold, v2 corrections and exact Receiver owner patch.
- Report620 — extension contract for the existing Edge Functions.
- Report614 remains the forensic starting report for the goods-custody/return issue.

No owner decision already recorded in Report606 is being reopened as a question.

---

## 3. Binding owner decisions recovered from Report606

1. Supplier Direct is the normal SupplierReturn route. A Purchasing Officer receives supplier-return goods only when the supplier explicitly delegates that responsibility.
2. Warehouse records the delegation and the physical handover. The Buyer later provides signed supplier receipt / credit-note evidence.
3. Only the quantity actually accepted by the supplier reduces the supplier balance.
4. Buyer goods custody must not depend on a vehicle. Vehicle is optional logistics metadata only.
5. A Quick Market invoice starts Draft, with no stock/AP/GL/Treasury effect. Receiver must find it by RAWAEA invoice number or supplier invoice number and accept the actual delivered quantities.
6. Employee-custody cash purchase, Supplier Credit, Treasury Cash and operating expenses are different financial events.
7. When the supplier was paid from the Buyer’s cash custody, do not create a second Supplier AP or Supplier Payment.
8. The existing cash-custody tables and RPCs remain the cash ledger. Do not build a parallel cash-custody system.
9. Supplier Master remains parent-governed. Buyer supplier directory is read/search only.
10. Do not edit `companies/company-1/main.html` or create a new Edge Function.

---

## 4. Current operational source — still open

| Component | Current verified fact | Required direction |
|---|---|---|
| Buyer `رصيدي` | Static explanatory placeholder; no event-ledger read | Server aggregate + cursor-paged events + item balance |
| Buyer Quick Purchase | Alias to Draft invoice creation | Dedicated Quick Market Draft + separate physical handover |
| Buyer cash custody | Existing money/expense/settlement workflow | Preserve; extend Quick Market branch only |
| Warehouse Vouchers SupplierReturn | Branch + Supplier only; no recipient mode | Supplier Direct default / Buyer Delegate exception |
| Receiver | Queries `purchase_order_details.po_code`, which does not exist in Production; uses `parseInt` | Resolve PO ID, query by `po_id`, decimal-safe Number and all-zero guard |
| Parent Returns | Reads `purchase_returns` only; no recipient column | Owner-side projection from the linked stock voucher |
| Parent main.html | Protected by current governance §77.3 | No assistant write |

Relevant current source fingerprints:
- Buyer: `311f2673a90149df6f56d59a9a187a3379e6981c`
- Warehouse Vouchers: `85e709d0f41c189c6624a6160965d3b1a41960ba`
- Receiver: `3111b5e801d1bc021cf18fd66d633fbdc54ac0d6`
- Parent main.html: `f6ec4ab41dc517f86e17dd3d74a9d5f8add264ca` (locked)
- Operational HEAD: `e8ab54c75572e15e71581212479d22be139c8020`

---

## 5. Fresh Production evidence — read only

Project: `fiilmooggumokxanwiyx`.

### 5.1 Current schema remains unchanged

Production still does not contain:
- `purchase_invoices.purchase_source`, `settlement_source`, `purchaser_user_id`, `buyer_custody_id`, `receipt_status`, or `settlement_status`;
- `receiving.source_type`, `receiving.purchase_invoice_id`, `receiving.stock_voucher_id`, `receiving.branch_id`, or `receiving.buyer_user_id`;
- `receiving_details.receiving_id`, `item_id`, `purchase_invoice_detail_id`, `stock_voucher_detail_id`, `qty_rejected`, or custody-event allocation;
- a dedicated `buyer_goods_custody_events` table;
- SupplierReturn acceptance batch tables.

Current `purchase_returns.purchase_invoice_id` remains NOT NULL. This is deliberately preserved in schema v4; no consumer scan has authorized relaxing it.

Current `stock_vouchers.return_currency` remains TEXT NOT NULL DEFAULT 'SAR'. It is only changed by a separately approved migration/Trigger change.

### 5.2 Fresh row counts

At the fresh review snapshot:
- `purchase_invoices`: 3 total; 1 Draft; 2 Posted; 2 with no PO.
- `purchase_returns`: 0.
- `stock_vouchers`: 0.
- `receiving`: 0.
- `buyer_custodies`: 0.

The two historical Posted SAR invoices must remain unchanged. The QA-labelled Draft PO/invoice receiving inconsistency is preserved as an audit graph; it is not a test fixture and must not be hard-deleted or treated as a real Receiving document.

### 5.3 P0 direct-write exposure remains

Fresh Production ACL inspection confirms `anon` and `authenticated` have INSERT/UPDATE/DELETE (and other grants) on:
- `purchase_returns`
- `purchase_return_details`

Both tables have RLS enabled, but the existing permissive ALL policies constrain company only. This bypasses the intended effective-permission gate in `save-purchase-order`.

Required security change: revoke direct DML from PUBLIC/anon/authenticated, retain authenticated SELECT under company + permission RLS, and keep business writes behind the existing approved SECURITY DEFINER RPC/Edge contracts. Do not apply a blanket ACL revoke to other transaction tables without mapping every current writer first.

### 5.4 Existing accounting contract that must be preserved

Existing `buyer_custody_review_expense_atomic` is a Finance/Finance Manager-only, no-self-review PO route. It requires a valid PO, a completed Receiving document by PO code, matching PO/invoice items/qty/prices and a posted Supplier AP credit. It then posts Dr Supplier AP / Cr Employee Custody, records the custody payment and supplier-ledger debit, and marks the invoice Paid.

This branch is valid for the existing PO/supplier-credit workflow and must remain behaviorally unchanged. It is not valid for a no-PO Quick Market purchase already paid by the Buyer from employee custody.

Current chart of accounts verified:
- 121 — Treasury cash.
- 124 — Inventory.
- 126 — Recoverable VAT.
- 127 — Employee Custody.
- 211 — Supplier AP.
- 51 / 52 — COGS and inventory differences/adjustments.

No dedicated Fuel/Transport expense accounts were found in the current list. Finance must configure accounts; no account codes are to be invented.

---

## 6. Root-cause and control gaps that must close together

### P0 — SupplierReturn currency

- Production company currency is EGP.
- Vouchers SupplierReturn UI initializes and submits SAR.
- `stock_vouchers.return_currency` defaults to SAR.
- `save_supplier_return_contract` accepts/falls back to SAR without validating `app_settings.currency`.
- `complete_manual_stock_voucher_atomic_core_20260828` and `purchase_post_return_atomic` do not use `return_currency`; both can post the numeric amount into Supplier Ledger/GL as though it were company currency.

Fix: resolve company currency server-side from `app_settings`; no browser currency authority, no SAR fallback/default, and both financial posting paths reject mismatch before ledger/journal writes. Do not convert historic Posted SAR invoices.

### P0 — SupplierReturn duplicate stock/AP writer

There are two independent posting paths:
1. Warehouse `stock_vouchers.SupplierReturn`: send reduces branch stock; completion posts Supplier Ledger/GL.
2. Parent `purchase_returns`: post_return calls `post_stock_movement('SupplierReturn')` and separately posts Supplier Ledger/GL.

One physical return represented in both can be posted twice. Canonical rule:
- stock voucher = sole physical stock-out writer;
- Parent `purchase_returns` = single financial return register;
- supplier acceptance batch = sole accepted-quantity AP/GL writer;
- linked `purchase_post_return_atomic` must not call `post_stock_movement`;
- linked manual voucher completion must not post Supplier AP/GL a second time;
- legacy unlinked paths remain separately gated until reconciled.

### P0 — Direct DML on purchase_returns

Revoke browser-role DML and preserve authorized SELECT. All return writes go through the server-side business RPC only.

### P1 — Cumulative return overrun

Current `purchase_create_return_atomic` checks the current return line against invoice received_qty but does not subtract prior active return documents. Concurrent or successive return documents can exceed the original accepted quantity.

The return creation/dispatch/acceptance RPCs must lock the source invoice line and return case, calculate cumulative reservations and posted accepted quantities, exclude Cancelled cases, and reject above the remaining eligible quantity.

### P1 — Receiver detail/quantity defect

The exact Receiver patch remains:
- select PO header ID;
- resolve the selected PO by its code;
- query purchase_order_details using `po_id`;
- include `qty_received` and show `qty_ordered - qty_received`;
- reject errors, empty lines, negative/NaN/Infinity/above-remaining inputs and all-zero submission;
- replace `parseInt` with decimal-safe Number and correct unit precision;
- generate a new operation UUID for each physical receipt; reuse only for an exact retry of the same payload.

### P1 — Quick Market no-PO receipt and settlement

- Current `receive-purchase` v13 is PO-code-only.
- Current `receiving` / `receiving_details` lack invoice-header/line links.
- Current custody review is PO-specific.

Add mutually exclusive modes to existing `receive-purchase`: old PO `po_code`, Quick Market `invoice_id`, and Buyer custody `receiving_id`. Preserve the existing PO request + RPC unchanged.

---

## 7. Canonical lifecycle — final target

### 7.1 Supplier Direct (default)

1. Warehouse creates a SupplierReturn Draft linked to supplier and original purchase invoice/line.
2. Recipient defaults to SUPPLIER_DIRECT; no Buyer or Vehicle is required.
3. Warehouse physically dispatches the goods; the branch stock-out and physical voucher state change occur atomically once.
4. Supplier signs/records actual accepted and rejected quantities with receipt/credit-note evidence.
5. Accepted quantity moves to AWAITING_FINANCE, then only Finance approval posts Supplier AP debit and balanced GL/tax reversal.
6. Rejected/unaccepted quantity remains in return transit/hold and must be returned to warehouse or resolved through a documented logistics disposition. No silent stock restoration.

### 7.2 Supplier Delegate → Purchasing Officer

1. Supplier explicitly delegates physical receipt to a named Purchasing Officer.
2. Warehouse selects BUYER_DELEGATE, the active same-company user with purchases permission and source-branch scope, and records delegation reference + private evidence path.
3. Physical dispatch decreases branch stock once and appends a positive Buyer custody event in the same transaction. No Supplier AP/GL/Treasury change.
4. Buyer `رصيدي` shows item, quantity, source voucher, supplier and age independent of vehicle.
5. Buyer later records supplier handover; each signed supplier acceptance batch decreases custody only by accepted quantities.
6. Finance posts the accepted value/tax reversal once. Linked financial posting does not post stock again.
7. Rejected quantities remain in Buyer custody; a separate Buyer→Warehouse Receiving operation removes custody and restores branch stock only after Warehouse accepts.

### 7.3 Quick Market purchase

1. Buyer creates a Draft invoice with `purchase_source='QUICK_MARKET'`, supplier, RAWAEA + supplier invoice identifiers, items, actual manually entered price, EGP from System Settings, purchaser, branch, and explicit `settlement_source`.
2. Draft save has no stock/AP/GL/Treasury/cash-custody effect.
3. Supplier physically hands goods to Buyer. A separate handover RPC appends positive custody events per invoice line; no branch stock or supplier AP effect.
4. Receiver searches by RAWAEA invoice code or supplier invoice number, loads remaining invoice-line quantities, confirms accepted/rejected quantity per line, captures destination branch and receipt evidence.
5. Accepted quantity reduces Buyer custody and increases branch stock exactly once. Rejected/unpresented quantity remains in Buyer custody unless separately returned to supplier/warehouse.
6. Financial counter-entry depends on the actual settlement source:
   - **SUPPLIER_CREDIT:** accepted receipt recognizes Supplier AP once; actual supplier payment is a separate documented event.
   - **EMPLOYEE_CUSTODY:** at Finance review of the accepted receipt, recognize Inventory DR / Employee Custody CR using existing account 127; do not create Supplier AP, supplier ledger credit or duplicate Supplier Payment if supplier has already received the employee cash.
   - **TREASURY_CASH:** Treasury changes only when actual payment is evidenced; receipt does not infer cash paid.
7. Invoice state, physical receipt state and settlement state stay separate. Receipt flags/qty_received are projections of canonical Receiving rows; legacy flags alone are not proof.

### 7.4 Cash-paid Quick Market goods later returned to Supplier

This is not an ordinary Supplier AP debit if the original purchase created no Supplier AP. The reports correctly leave refund/credit disposition as UNKNOWN until Finance maps it to an existing account and approved workflow.

Until that mapping is approved:
- record the physical acceptance and custody exit;
- mark financial status AWAITING_REFUND_DISPOSITION;
- do not debit a nonexistent AP balance;
- do not increase Treasury or book cash received without actual refund evidence;
- do not fabricate a receivable or credit-note asset account.

### 7.5 Cash expenses

Keep existing `buyer_custodies` as the only cash advance ledger. Extend expense records with category, payee kind and approved expense account. Fuel/Transport/Other posting must fail closed until Finance configures a real active expense account; no guessed account mapping and no Supplier Ledger movement for operating expenses.

---

## 8. Competitive design translated into RAWAEA

Official vendor documentation supports the same key control boundaries:

- **Microsoft Dynamics 365** supports partial return purchase orders copied/marked against source invoice inventory transactions, then records the return shipment/product receipt with a packing-slip reference. This supports an immutable link to the original purchase and a separate physical shipment event. [D365 return purchase order](https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/tasks/create-purchase-return-order). citeturn651801search0
- **Dynamics 365 product receipt** separates preregistration/quality processing from final Received state and records per-line discrepancies with a supplier product receipt reference. [D365 product receipt](https://learn.microsoft.com/en-us/dynamics365/supply-chain/procurement/product-receipt-against-purchase-orders). citeturn651801search3
- **Odoo two-step receipts** keep goods in an Input location until the internal transfer to Stock is validated; the goods are not available for further processing before that transfer. This is the closest pattern for Buyer-held/input goods not yet accepted into branch stock. [Odoo two-step receipt](https://www.odoo.com/documentation/17.0/applications/inventory_and_mrp/inventory/management/incoming/two_steps.html). citeturn651801search1
- **Odoo three-step receipts** adds a Quality location before stock, supporting an optional quality hold when rejection/inspection is required. [Odoo three-step receipt](https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/inventory/shipping_receiving/daily_operations/receipts_three_steps.html). citeturn651801search7
- **SAP Advanced Returns Management** links a return PO, outbound delivery/goods issue and supplier credit memo; goods issue quantity informs the credit-memo quantity. [SAP supplier return document flow](https://help.sap.com/docs/SAP_S4HANA_CLOUD_PE/af9ef57f504840d2b81be8667206d485/cff87e426fed4ad9b3b0929aea4dedf6.html). citeturn651801search5

RAWAEA adopts the process separation, not a copy of the vendor products: custody, warehouse availability, supplier acceptance, financial posting and cash payment remain distinct ledgers/documents.

---

## 9. Schema draft review — v1/v2/v3/v4

### Rejected

- v1: unsafe/incomplete.
- v3: rejected despite higher filename number. It drops `purchase_returns.purchase_invoice_id NOT NULL`, replaces an existing status check, gives all stock voucher types a default SupplierReturn recipient_mode, drops delegation evidence and duplicates quantity counters. Do not execute.

### v2 — reviewed but still a scaffold

v2 corrected several key risks: preserves the invoice NOT NULL and existing status checks, keeps recipient_mode nullable for non-SupplierReturn, adds delegation evidence, append-only custody event, and DML revocation. However it still:
- stores accepted/rejected/returned aggregate counters on `purchase_return_details` as well as acceptance detail batches (two sources of truth);
- gives acceptance batches no AWAITING_FINANCE state;
- does not provide an allocation table when a Receiving line consumes multiple Buyer custody events;
- permits only PO and Quick Market source types on Receiving, not Buyer custody/return-to-warehouse;
- does not link Receiving details to their header or return source voucher line;
- leaves return_currency SAR default/removal outside this scaffold;
- leaves full RPC/Trigger/Edge/app bodies and storage policies unimplemented.

### v4 — review draft created in this review

File: `Current/CTO/ChangeSets/20261104/04_buyer_goods_custody_schema_security_REVIEWED_DRAFT_v4.sql`.

v4:
- preserves `purchase_returns.purchase_invoice_id NOT NULL` and current status checks;
- adds the invoice source/settlement/purchaser/receipt/settlement dimensions;
- keeps SupplierReturn recipient mode NULL for all other voucher types and requires supplier delegation reference/evidence for Buyer Delegate;
- removes the SAR default and NOT NULL requirement from return_currency so server Trigger/RPC can populate it only for SupplierReturn while non-return vouchers remain null;
- links Parent return header/details to one stock voucher and its exact source lines;
- removes accepted/rejected aggregate counters from return details; acceptance detail batches become the only acceptance history;
- adds `AWAITING_FINANCE` acceptance status;
- creates append-only Buyer custody events separate from cash custody;
- adds Receiving source types for PO, Quick Market, Buyer custody and SupplierReturn-to-warehouse;
- adds header/line source references and a many-to-many custody event allocation bridge;
- hardens purchase-return direct DML to authenticated SELECT only;
- limits direct read policies for the goods ledger to its custodian and finance/audit roles; privileged receiving remains through authenticated RPCs;
- adds event/receiving Realtime publication only after RLS.

**v4 remains NOT EXECUTABLE.** It still requires all companion function bodies, function privileges, storage policy, all-consumer scans, constraint validations against current rows and a schema-parity test/rollback.

---

## 10. Exact next implementation components

1. **Production SQL/RPC/Trigger bodies:** append-only ledger reads/writes, row-locked cumulative return guards, create/update/dispatch/acceptance/finance post/return-to-warehouse, invoice-ID Quick Market receiving, all-zero guard, currency enforcement, and existing PO/mobile-sales/Transfer compatibility.
2. **Existing Edge sources only:** save-purchase-order v22, receive-purchase v13, create-stock-voucher v12, send-stock-voucher v20, receive-stock-voucher v22, complete-stock-voucher v4. All six live source snapshots are archived; five are absent from matching operational Git paths and must be restored byte-for-byte before editing. Use `profileClient` for new auth.uid()-based RPCs. No new Edge.
3. **Buyer source:** `رصيدي` live ledger, cursor pagination, timeline/evidence, item search, handover actions, Quick Market modal, no vehicle dependency, no default cost-price exposure, precise statuses.
4. **Warehouse Vouchers source:** Supplier Direct default / Buyer Delegate exception; isolated Purchasing Officer picker; delegation evidence; preserve DirectSale/DirectReturn rep/vehicle rules; show recipient in detail/list.
5. **Receiver source:** exact Report619 patch for PO id/po_id, decimals and all-zero; add invoice-ID and receiving-ID modes; per-line accepted/rejected with evidence; no success toast until stock RPC confirms.
6. **Parent owner-side patch:** add `المستلم` column by joining `purchase_returns.stock_voucher_id` to `stock_vouchers`; Buyer Delegate shows validated Purchasing Officer, Supplier Direct shows Supplier. The assistant must not edit `main.html` under §77.3.
7. **Cash custody review:** preserve PO branch verbatim; add Quick Market EMPLOYEE_CUSTODY branch that uses invoice-ID Receiving evidence and account 127, without Supplier AP/ledger/payment duplication. Supplier Credit uses AP once; Treasury Cash requires a separate actual payment proof.
8. **Security and storage:** verify storage bucket policies for delegation and signed supplier receipt evidence. Keep evidence private and scoped to company + supplier return + authorized actor; no public product-image storage.
9. **Tests:** real JWT negative and positive RLS tests, retry/changed-payload idempotency, concurrent returns/acceptances, partial and rejected quantities, branch scope, decimal quantities, all-zero receive, PO/mobile-sales/Transfer regression, Buyer/Receiver/Parent Realtime and financial reconciliation.
10. **Environment:** current Staging is not schema parity (62 migrations/70 tables per LVE613); no full E2E can be claimed there until schema parity is achieved. Do not use Production real transactions as test fixtures.

---

## 11. Exact acceptance and reconciliation criteria

### Inventory and Buyer custody
- Draft invoice / Draft SupplierReturn / delegation registration: zero stock/treasury/AP/GL effect.
- Supplier→Buyer handover: Buyer custody increases exactly once; stock/AP/GL/treasury unchanged.
- Warehouse→Buyer SupplierReturn dispatch: branch decreases once; Buyer event increases once; AP/GL unchanged.
- Buyer→Warehouse acceptance: Buyer custody decreases only accepted quantity; branch increases once; rejected quantity remains in custody.
- Buyer→Supplier acceptance: Buyer custody decreases only supplier-accepted quantity; financial posting pending Finance.
- Supplier Direct: no Buyer custody event.
- No balance can become negative; sum of immutable event deltas equals item/branch/custodian balance.

### Supplier AP / GL / currency
- Linked return acceptance: accepted value/tax only; one Supplier Ledger debit; balanced GL; no second stock movement.
- Linked manual voucher completion cannot duplicate AP/GL.
- Cumulative returns cannot exceed the original accepted/invoiced eligible quantity after previous active returns, including concurrent attempts.
- Return currency is set from app_settings and equals EGP; SAR client payload/fallback rejected.
- Cash-paid purchase return does not debit nonexistent AP; wait for explicit refund/credit disposition evidence and configured finance mapping.

### Quick Market / Cash custody
- Draft invoice creates no financial or stock effects.
- Receiver accepted quantities match invoice lines and Buyer custody allocations.
- SUPPLIER_CREDIT recognizes AP once; actual payment separately.
- EMPLOYEE_CUSTODY uses Inventory DR / Employee Custody CR (127) only through Finance review with accepted Receiving; no Supplier AP/Supplier Payment duplication.
- TREASURY_CASH changes only after actual evidenced payment.
- Fuel/Transport/Other cannot post without a configured active expense account.

### Security / regression
- anon/authenticated direct INSERT/UPDATE/DELETE to purchase_returns/details denied.
- Buyer reads own goods custody only; Finance/Audit sees permitted scope; other company denied.
- Unauthorized user/cross-company/cross-branch/inactive/non-purchasing delegate rejected server-side.
- Existing PO receiving, PO cash custody, DirectSale, DirectReturn and Transfer remain behaviorally unchanged.
- Retries/refresh/timeouts do not duplicate stock, custody, AP, GL or Treasury.
- Browser E2E and deployed artifact parity are independently proven; static SQL/source inspection is not E2E.

---

## 12. Deployment, rollback and governance boundary

No Source, Production schema, DML, RPC, Trigger, RLS, GRANT, Edge deployment, Cloudflare deployment, or test fixture was changed in this review.

Before any operational write:
1. Assemble exact full SQL/RPC/Trigger definitions and exact Edge/source diffs from the archived production snapshots.
2. Re-fetch current source/schema/grants/consumers immediately before approval.
3. Run the migration and full tests in a schema-parity isolated environment.
4. Provide the exact impact matrix for inventory, Supplier Ledger/AP, GL/VAT, Employee Custody, Treasury, all consuming apps, security and deployment.
5. Provide rollback for the pre-event stage and compensating-event reversal plan after business events exist.
6. Submit that exact complete package for explicit owner approval under Master CTO §77.2.

Keep `main.html` untouched and create no new Edge Function. No user question is needed for business rules already recorded in Report606.

---

## 13. Final status

- **CONFIRMED:** LVE620 is the latest prior checkpoint in Execution Log/Project Memory; CURRENT_STATE lagged at LVE616.
- **CONFIRMED:** core business gaps, P0 ACL, P0 currency, duplicate supplier return posting, Receiver defect and Quick Market no-PO receipt gap remain open in Production.
- **PREPARED:** reviewed schema proposal v4; not applied.
- **NOT IMPLEMENTED:** full RPC/Trigger definitions, Edge diffs/deploy, Buyer/Vouchers/Receiver operational source, Parent owner patch.
- **UNVERIFIED:** authenticated Browser E2E, schema-parity E2E, deployed Cloudflare artifact parity.
- **Overall:** CHANGE SET PREPARATION IN PROGRESS / APPROVAL GATE OPEN / BUYER PROCUREMENT NOT PRODUCTION READY.
