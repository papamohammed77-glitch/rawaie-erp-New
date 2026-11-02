# RAWAEA ERP — تصحيح عقد المشتريات السريعة والعهدة النقدية ورصيد سيارة المشتريات
## التحقيق الحالي، تصحيح تعريفات المالك، وخطة التغيير الجراحية المتكاملة
**Checkpoint:** LVE-2026-11-02-585  
**التاريخ:** 2026-11-02  
**الحالة:** DIAGNOSIS VERIFIED / OWNER DEFINITIONS RESTORED / IMPLEMENTATION CHANGESET NOT YET APPROVED / NO PRODUCTION WRITE IN THIS CHECKPOINT

---

## 1. Current State — نقطة الانطلاق

هذه الجولة لا تبدأ من تفسير Report584، بل من إعادة قراءة المصدر التشغيلي الحالي والعقود الفعلية في Production، مع اعتماد تعريفات المالك الواردة مباشرة في التكليف الحالي باعتبارها المرجع الوظيفي الحاكم.

**Operational repository:** papamohammed77-glitch/erp-frontend  
**Branch:** main  
**Buyer source:** companies/company-1/purchasing/buyer.html  
**Buyer blob:** 73d746571a10b1720bdd31631004abce0ac9afa1  
**Buyer size:** 139,419 characters / 1,047 lines  
**Receiver source:** companies/company-1/warehouse/receiver.html  
**Receiver blob:** 3111b5e801d1bc021cf18fd66d633fbdc54ac0d6  
**Existing purchasing Edge:** supabase/functions/save-purchase-order/index.ts  
**Production Edge:** v22 / ACTIVE / verify_jwt=true (as verified in Report584); it remains the existing gateway and no new Edge Function is proposed.  
**Supabase project:** fiilmooggumokxanwiyx  
**System currency:** EGP from app_settings.

**Governance source re-read:** doc/Draft/Reprots/writing-block.md and the current Master CTO Governance document. In particular:
- `29 assigns the owner the responsibility to review and apply operational source patches.
- `48 prohibits unauthorized direct source edits, duplicate tables/functions, and unverified Production changes.
- Master `77.1 requires proof of physical cash/goods handover before balance effects.
- Master `77.2 requires the exact source/SQL changeset, impacts, dependencies, failure cases, acceptance tests and rollback to be presented and explicitly approved before production-sensitive writes.
- Master `77.4 keeps Draft documents non-posting and quick invoice posting dependent on actual approved receiving.

**Important scope distinction:** the current main.html and Driver app were inspected only where relevant; neither is a target of this change. The Parent is not to be broadly rewritten, and delivery-vans stock must remain independent from purchasing-car custody.

---

## 2. Owner Definitions — Correct Business Contract

The following definitions supersede the wrong interpretations repeated in earlier analysis.

### 2.1 رصيد سيارة مسؤول المشتريات

It is the total quantity of goods physically present in the car assigned to the purchasing officer, item by item, independent of the origin of the goods:

1. Goods physically taken from a warehouse.
2. Goods bought by the purchasing officer from the market and physically handed over to that officer.
3. Goods issued from a warehouse to the purchasing officer's car for an operational/customer need, including the customer-return/customer-service case described by the owner.

The balance is a **custodial physical stock balance**, not a delivery/sales-van balance and not a financial amount. It must show:
- current item, unit and quantity;
- source and reason for each addition;
- destination and reason for each deduction;
- invoice, warehouse receipt or voucher reference;
- date/time, issuing/receiving actors and the assigned purchasing vehicle;
- the movement history and the auditable remaining quantity.

It must never be calculated from:
- fleet_vehicle_assignments.driver_user_id;
- run_sheet_details;
- stock_branches mobile van branch;
- driver collection/balance;
- purchase invoice Draft rows alone;
- PO or quotation status.

### 2.2 العهدة النقدية لمسؤول المشتريات

It is actual money handed to the purchasing officer and held under that officer's responsibility. The Buyer app needs an **advisory, explainable cash-in-hand balance** and a record of supporting documents submitted to Accounts.

Examples supplied by the owner:
- Quick purchase from market: the supplier invoice/proof of the amount paid **and** warehouse physical receipt proving the goods reached the warehouse.
- Fuel: petrol-station receipt.
- Transportation: ticket/receipt or suitable proof.
- Other expense: supporting document appropriate to the expense.

The application must distinguish:
- cash actually handed over and acknowledged by the officer;
- expenses submitted to Accounts;
- expenses approved by Accounts;
- expenses rejected or missing proof;
- cash physically returned to Finance/Treasury;
- estimated cash remaining with the officer;
- amount still accountable/unsubstantiated.

An expense submission is evidence for review; it is not automatically a supplier payment, AP settlement or journal entry. A quick purchase paid from the buyer's cash custody must not be transformed into a supplier-credit payment merely because a supplier invoice exists.

### 2.3 تبويب «فواتيري»

This is the purchasing officer's **quick market purchase invoice register**, not a generic listing of all supplier/AP invoices.

Its purpose:
- create and record quick purchases made directly by the purchasing officer in the market;
- record invoice date, seller/supplier, invoice reference and total;
- capture the invoice image;
- record each item, quantity, price and its specification/description;
- capture one or more item/product images as needed;
- allow the officer and authorized reviewers to search, filter, open and inspect the invoice and all its evidence.

Search and list interaction should match the usability of the existing PO list and the Parent Purchase Invoices experience, including quick smart search, filters, clickable rows and a full detail view.

The current Draft edit/delete controls and downstream-reference protection must be preserved. Posted/received/paid or otherwise downstream-linked records must not be deleted or edited through the Draft path.

---

## 3. Findings — CONFIRMED

### 3.1 Buyer source

Current Buyer source already has the nine tabs, including the four requested destinations, but existence of a tab is not proof of implementation.

**فواتيري — current source**
- renderInvoices() reads all purchase_invoices plus suppliers.
- It searches invoice code, supplier invoice number, supplier name/code and status, with date/status filters.
- It opens an invoice detail modal on row click.
- Draft editing and Draft deletion are protected by status/receiving/payment checks.
- The heading describes supplier invoices generally; it is not scoped to the current buyer's quick market purchases.
- The detail modal shows commercial lines and history but no supplier invoice image, no line-level photos and no item specification field.
- createPurchaseInvoice() captures supplier, optional PO, branch, due date, supplier invoice number, notes and item lines. Item search already supports name/code/barcode. It does not capture image evidence or per-line specifications in the current UI.
- Therefore barcode lookup and Draft safety are existing strengths to preserve, not missing features to rebuild.

**رصيد السيارة — current source**
- renderVehicleBalance() requests fleet_vehicle_assignments and vehicles.
- It filters assignment by driver_user_id === currentUser.id.
- The page itself says the procurement goods custody book is not enabled.
- The current selection logic is a delivery-driver assignment lookup, not a purchasing officer vehicle assignment or custody ledger.
- This is a confirmed wrong data source for the owner's intended balance.

**العهدة — current source**
- renderCustody() shows advances, acknowledged advances, submitted/approved expenses and settlement information.
- The current message incorrectly says custody cash delivery/top-up/return are actual Treasury vouchers and that every approved purchase expense settles a supplier invoice and posts AP/GL.
- submitCustodyExpense() supports a narrow PO-linked purchase invoice + warehouse receiving-document scenario only.
- It has no supported category-specific flow for fuel, transport and other expenses.
- Its current "available for documents" calculation is not a full explanatory reconciliation of the officer's actual cash-in-hand versus approved and unsubstantiated amounts.

### 3.2 Existing purchasing gateway

Current save-purchase-order v22 is the correct existing gateway to extend if approved; no new Edge Function is needed as a default.

Verified dispatch includes:
- CREATE_INVOICE → purchase_create_invoice_atomic_v2;
- UPDATE_DRAFT_INVOICE → purchase_update_draft_invoice_atomic;
- POST_INVOICE → purchase_post_invoice_atomic;
- SUBMIT_CUSTODY_EXPENSE → buyer_custody_submit_expense_atomic;
- REVIEW_CUSTODY_EXPENSE → buyer_custody_review_expense_atomic;
- GET_CUSTODY reads company-scoped custody and expense rows, with finance seeing the company view and the purchaser seeing their own custody.

The GET_DATA allow-list includes purchase_attachments, but current metadata access is not by itself a secure private-file upload/view workflow.

### 3.3 Quick purchase invoice backend

Current purchase_invoices requires supplier_id and has a nullable purchase_order_id. Its status constraint currently allows only:
Draft, Posted, PartiallyPaid, Paid, Cancelled.

Current purchase_invoice_details already has nullable notes, which can hold an item-specific specification, but the current CREATE and UPDATE Draft RPC implementations do not persist the per-line notes value from the submitted item JSON.

Current purchase_create_invoice_atomic_v2:
- calls the canonical invoice create RPC;
- creates the invoice as Draft;
- records supplier invoice number and header notes;
- does not create stock, Treasury, supplier AP or GL effects on Draft creation.

Current purchase_update_draft_invoice_atomic:
- is restricted to an unreceived, unposted Draft;
- protects against payment, custody, return, stock-voucher and other downstream references;
- replaces invoice details and recalculates values;
- does not yet persist per-line notes.

Current purchase_post_invoice_atomic:
- preserves the PO-linked receiving/quantity/price validation route;
- returns without duplicating stock or AP already recorded by PO receiving;
- rejects a no-PO quick invoice with PURCHASE_QUICK_INVOICE_RECEIPT_REQUIRED until an approved direct warehouse-receipt contract exists.

The current receiver app is also PO-only:
- it lists Sent/Partially Received purchase orders;
- searches PO code/supplier;
- reads purchase_order_details;
- submits through the existing receive-purchase operation using the PO code.
There is no direct market-purchase invoice receiving queue and no invoice-to-receiving link in this flow.

### 3.4 Evidence and image security

Production has purchase_attachments, currently empty in the prior verified snapshot. Its columns include:
company_id, document_type, document_id, file_name, storage_path, file_url, mime_type, uploaded_by, created_at.

Current RLS is inadequate for the intended private invoice documents:
- purchase_attachments_company applies a company-only predicate;
- anon and authenticated currently have broad table DML grants;
- it does not enforce the appropriate purchaser/finance role or uploaded-by/document ownership for reads and writes.

The private employee-documents bucket has rules specialized for employee documents and buyer-custody subpaths; there is no verified buyer-purchase invoice path. The public product-images bucket is not suitable for private supplier invoices or custody receipts.

Therefore a visible "camera" button without the private storage policy, metadata authorization and secure viewing flow would be a false/insecure feature. Invoice images must not be published through the catalog's public product-image bucket.

### 3.5 Cash custody contract gap

Current buyer_custody_expenses has no expense_type column. Current submit RPC requires:
- supplier id;
- purchase invoice id;
- PO-linked invoice in Draft;
- completed PO receiving operation;
- supplier invoice document and warehouse receipt document;
- matching PO/invoice/receipt quantities and prices.

It therefore does not represent Fuel / Transport / Other.

Current review RPC has a materially different financial effect from the owner's intended quick-purchase settlement:
- it validates the PO invoice and receipt;
- posts Dr Supplier AP (211) / Cr Employee Custody (127);
- creates a buyer custody payment record;
- marks the linked purchase invoice Paid and increases its paid amount;
- debits supplier ledger to reduce the supplier payable;
- it does not require a distinct supplier cash receipt/acknowledgment.

That may be a separate PO/AP supplier-payment route, but it must not be reused for a market purchase that the buyer already paid from their cash custody. The owner-defined quick-purchase expense is a settlement of the employee's cash accountability after invoice and warehouse-receipt evidence, not an automatic supplier AP payment.

Current buyer_custody_issue_atomic and buyer_custody_add_advance_atomic invoke cash payment posting at issue/top-up creation; employee acknowledgment is a separate later action. This ordering and its handover evidence must be reconciled against Master `77.1 before any write path is changed.

Current buyer_custody_settle_atomic requires exact cash returned and no pending expenses, but does not accept a verified cash-return receipt attachment.

Current active COA includes:
- 121 Treasury;
- 124 merchandise inventory;
- 125 driver receivables;
- 126 recoverable VAT;
- 127 employee custody;
- 211 suppliers;
- 51 cost of sales;
- 52 stock differences/adjustments.

No verified dedicated fuel/transport/other expense account mapping was found in the active accounts inspected. No such posting mapping may be invented.

### 3.6 Existing stock-voucher boundary

The current stock-voucher core accepts:
Transfer, DirectSale, DirectReturn, SupplierReturn.

The existing trigger enforce_stock_voucher_custodian():
- clears custodian_user_id for all types except DirectSale/DirectReturn;
- for those types requires an active same-company direct-sales representative with van-sales permission.

The existing trigger enforce_stock_voucher_transfer_vehicle_context():
- permits vehicle_id / driver_id only for Transfer;
- requires them together;
- requires a same-company vehicle and a same-company delivery/driver identity.

Production vehicle records currently inspected are both:
- CHV-2025-01, vehicle_type=Delivery, mobile stock enabled;
- VHL-0422, vehicle_type=Delivery, mobile stock enabled.

Thus reusing DirectSale/DirectReturn or delivery Transfer for the purchaser's car would violate role and inventory boundaries. Adding a new front-end filter or a new free-form type string is insufficient; the central voucher lifecycle, trigger guards, source/destination validation, stock posting and idempotency contract would all need an explicitly designed extension.

The current warehouse SupplierReturn route (Branch → Supplier) must remain intact and must not be rebuilt as part of this work.

---

## 4. Why the Previous Interpretation Was Wrong — Accountability

The earlier analysis treated the presence of tabs and pre-existing Buyer custody/vehicle structures as evidence that they already matched the business process. That was incorrect.

The specific errors were:
1. Confusing the buyer's purchasing-car goods with mobile delivery/sales-van stock.
2. Treating the buyer's cash custody as a supplier-payment/AP settlement workflow instead of an employee accountability ledger.
3. Treating the generic supplier invoice list as the required quick-purchase invoice register.
4. Reading the existence of invoice and custody RPCs as proof that the workflow supported the owner's actual quick-purchase evidence and expense categories.
5. Failing to use the owner's explicit operational explanation as the primary business definition before proposing a model.

This is a functional interpretation failure, not a wording difference. The scope is corrected in this report.

### Production-change accountability

Production migration history contains earlier buyer/purchasing changes, including:
- 20261031233331 buyer employee custody ledger/manual settlement;
- 20261031233923 custody finance separation of duties;
- 20261031234921 custody storage path qualification;
- 20261031235057 custody currency and cash reconciliation;
- 20261101003952 custody advance receipt proof;
- 20261101005616 custody treasury/accounting/supplier settlement;
- 20261101005849 supplier invoice must be unposted Draft;
- 20261101010224 supplier-ledger and custody-payment adjustment;
- 20261102150516 buyer invoice Draft edit/delete;
- 20261102151137 quick invoice post requires receipt contract.

Those records prove that earlier Production changes occurred. The existence of a migration record is not evidence that the owner reviewed and approved its exact diff. I will not claim that each earlier write passed the exact-owner-approval gate without the approval record. The gate in Master `77.2 must be followed for every next production-sensitive change.

**This LVE-585 checkpoint itself performed read-only GitHub fetches and SELECT-only database queries. It did not:**
- write or alter any Production row;
- run DDL or a migration;
- alter RLS or grants;
- create/replace any RPC, trigger or Edge Function;
- deploy any Edge Function;
- modify Buyer, Receiver, Driver or Parent source;
- deploy to Cloudflare.

---

## 5. Correct Target Architecture — Proposed, Not Yet Executed

### 5.1 Quick market purchase document

Keep the existing purchase_invoices and purchase_invoice_details as the commercial document foundation, but introduce an explicit business identity for the quick market purchase so it cannot be confused with a PO/AP invoice.

Required distinction:
- existing PO-linked supplier invoice path: unchanged;
- quick market purchase paid from the buyer's cash custody: explicitly marked as that source/type.

The exact enum/column name and migration are part of the approval changeset, not a production write in this checkpoint. Do not infer "quick market" solely from purchase_order_id IS NULL, because not every historical no-PO invoice is necessarily the buyer's market purchase.

Required header data:
- authenticated purchasing officer / creator;
- invoice date and supplier invoice number;
- supplier identity or approved market-seller snapshot;
- system currency (EGP from current settings);
- invoice total and notes;
- branch/receiving destination as applicable;
- explicit payment source = buyer cash custody;
- private invoice attachment metadata and audit trail.

Required line data:
- item identity/code/name/unit;
- quantity and unit price;
- existing discount/tax fields, respecting current accounting restrictions;
- line specification/details in purchase_invoice_details.notes;
- private item photo attachments tied to the invoice line, not global public catalog photos.

Supplier master constraint: purchase_invoices.supplier_id is currently NOT NULL and references suppliers. A quick market purchase must therefore resolve to a valid supplier identity under the current schema. The final change must not fabricate supplier ids or make the FK nullable without a separately approved supplier-master decision.

### 5.2 Private invoice and item evidence

Use private storage only. A candidate is extending the existing private employee-documents bucket with a narrowly scoped purchasing path such as:
company_id / buyer_user_id / buyer-purchases / invoice_id / ...

Before enabling:
- storage INSERT/SELECT policies must require an authenticated, active same-company user with purchasing or Finance permission as appropriate;
- invoice access must be scoped to the exact company and permitted document;
- the owner/uploader and reviewer view rules must be explicit;
- use short-lived signed URLs or an equivalent authenticated viewing path;
- attachment metadata write must use a permission-checked server/RPC path, not the current broad direct table grants;
- support at least header invoice image and line-level item photos, each with declared attachment role;
- validate file MIME, size, type and path ownership;
- prevent one company/user from viewing another company's files.

Do not use public product-images for invoices, receipts or employee-custody evidence.

### 5.3 Buyer purchasing vehicle and movement ledger

The app requires a separate purchasing vehicle assignment, not fleet_vehicle_assignments.driver_user_id.

A candidate contract is a time-bound purchasing_vehicle_assignments relation:
- company;
- purchasing officer user id;
- assigned vehicle id;
- effective start/end;
- primary/active indicator;
- assigned-by and audit fields.

This may reference the existing vehicles master only after confirming whether a new purchasing vehicle should be registered there. Current Production contains only two Delivery vehicles, so neither can be silently assumed to be the buyer's car.

Prefer extending the central stock-voucher lifecycle and its idempotency/audit model rather than creating an isolated shadow inventory engine. But the new purchaser-custody endpoint must be a distinct location/role contract, not a reinterpretation of DirectSale, DirectReturn or driver Transfer.

Minimum physical movement events:
1. Supplier/market → Purchasing Vehicle: actual supplier handover to buyer; increases buyer-car custody quantity only; does not increase branch stock or create supplier AP.
2. Warehouse Branch → Purchasing Vehicle: actual issue/load; reduces source branch stock and increases buyer-car custody quantity.
3. Purchasing Vehicle → Warehouse Branch: actual warehouse acceptance; decreases buyer-car custody quantity and increases destination branch stock exactly once.
4. Warehouse Branch → Purchasing Vehicle for a customer/operational need: explicit purpose and reference; increases vehicle custody quantity and decreases branch stock.
5. If a future buyer-car → supplier return is required, supplier AP/credit effects wait for actual supplier acceptance, not merely the goods leaving the warehouse or car.

Each event must bind:
- company, assigned buyer and purchasing vehicle;
- item id/code and quantity;
- source and destination location;
- business reason and linked invoice/receipt where applicable;
- actual handover/receipt evidence;
- actor, timestamps and immutable executed identity;
- operation_id/idempotency identity;
- audit/status history.

The buyer's current vehicle balance is calculated from the completed/physically confirmed custodial movement history. A Draft invoice does not add goods to the car. A purchase invoice image without physical supplier handover does not add goods to the car. A warehouse receipt removes the accepted quantity from the buyer-car custody and adds it to the warehouse's authoritative branch stock in the same atomic operation.

### 5.4 Warehouse receiving for quick market purchases

The existing Receiver only accepts a PO code and reads purchase_order_details. It does not receive an unlinked quick invoice.

Extend the existing receiving workflow with a separately identified source document:
- PO receipt continues through the present PO path unchanged;
- quick purchase receipt references the exact quick invoice id/code and its invoice detail rows;
- receiver scans/verifies item, expected quantity and actual accepted quantity;
- partial receipt and short/over receipt are explicit;
- actual receiver identity, branch, time, notes and discrepancy reason are recorded;
- accepted quantities are linked to the buyer-car movement being unloaded;
- repeated submission is idempotent and cannot increase branch stock twice.

Do not create a fake PO, copy the invoice code into po_number as a workaround, or write directly to receiving_details without the canonical authorization and inventory posting contract.

### 5.5 Cash custody and expenses

Extend the existing custody model; do not create a second cash-custody ledger.

Required expense classifications:
- PURCHASE: quick market invoice + evidence of physical warehouse receipt. Once verified by Accounts, it reconciles the expense against the buyer's custody; it must not create a second supplier AP/payment settlement.
- FUEL: petrol-station receipt.
- TRANSPORT: transport ticket/receipt.
- OTHER: an appropriate supporting document and explanation.

For every expense:
- submitter, custody id, date, type, amount, currency and description;
- supporting document(s);
- invoice/receiving links for PURCHASE only;
- status Submitted / Approved / Rejected;
- reviewer, review time, reason and immutable audit event;
- operation_id and no duplicate deduction.

UI should show distinct figures rather than one ambiguous total:
- acknowledged cash in custody;
- approved expense total;
- pending review amount;
- rejected/unsubstantiated amount still accountable;
- cash physically returned and acknowledged;
- estimated cash remaining with the buyer;
- accounting-recognized custody liability.

A submitted document is not yet an approved deduction. A rejected or unsupported expense remains visible and accountable. The final arithmetic must reconcile acknowledged advances, all expense states and physically acknowledged cash returns without hiding pending or rejected items.

**Financial posting boundary:**
- Quick market purchase: do not debit supplier AP 211 or reduce the supplier ledger merely because the buyer gives Accounts an invoice. The intended route is purchase paid from employee custody after physical goods receipt and approved evidence.
- Inventory received into a branch must affect inventory exactly once through the canonical stock writer.
- Credit to employee custody (127) and debit to inventory (124) for received purchase goods may be the accounting treatment candidate, but it must be validated against the complete current posting chain and approved by the owner before SQL is written.
- Fuel/transport/other expense account mappings are UNKNOWN from current active COA evidence; do not post these categories automatically until Finance maps the correct accounts.
- Cash issue/top-up and cash return require actual handover/return proof and one-time effects, consistent with `77.1.

---

## 6. Exact Source Areas to Change — Surgical Scope

These are the only expected operational source areas for the initial change, subject to source re-fetch immediately before patching:

### Buyer
companies/company-1/purchasing/buyer.html
- applyInvoiceFilters / clearInvoiceFilters / renderInvoices: quick-purchase scoped list, expanded search and filters, without mixing normal PO/AP invoices.
- createPurchaseInvoice: explicit quick market purchase mode, invoice date, private invoice image, item specifications and item photos; keep existing barcode/name/code lookup and Draft behavior.
- openInvoice: authenticated image/detail view and per-line specifications/photos; preserve history and Draft edit/delete gate.
- renderCustody / submitCustodyExpense: categorized proof submission and clear advisory cash reconciliation; remove the incorrect blanket statement that approval always pays a supplier invoice.
- renderVehicleBalance: use purchasing-vehicle assignment and the central buyer-custody stock read model; do not query driver assignments or mobile branch stock.

### Existing purchasing Edge
supabase/functions/save-purchase-order/index.ts
- Extend the existing authenticated gateway and effective permission checks for the exact new read/write operations.
- Add the necessary quick-receipt / purchase vehicle / private attachment / expense category dispatches only if their approved RPC contracts require them.
- Keep verify_jwt=true; no new Edge Function unless a documented technical limitation proves the existing gateway cannot serve the approved contract.

### Receiver
companies/company-1/warehouse/receiver.html
- Add a separate queue/detail/action for quick market invoices awaiting warehouse acceptance.
- Keep the existing PO queue and its behavior unchanged.
- Do not write stock directly from the UI.

### Production schema and functions — proposal only
- explicit quick-purchase classification and payment source on invoice;
- safe private attachment role/document relations and policy;
- item-line notes persistence in the existing invoice CREATE/UPDATE RPCs;
- purchaser vehicle assignment and buyer-specific location/custodian contract;
- central stock voucher lifecycle/trigger/core extension for buyer custody locations;
- direct invoice-based receiving with line linkage and idempotent warehouse posting;
- expense type and evidence rules for PURCHASE/FUEL/TRANSPORT/OTHER;
- separate review path for custody reconciliation, without supplier AP side-effects for cash-paid market purchases;
- appropriate RLS/grants, company/actor checks, audit and rollback.

Do not add duplicate ledgers/RPCs where a current canonical contract can safely be extended. Do not change the Parent or delivery Driver page for this scope.

---

## 7. Acceptance Tests — Mandatory Before Closure

| Scenario | Expected result |
|---|---|
| Create quick invoice Draft | invoice and lines saved; no stock, AP, Treasury or GL change |
| Save invoice image | private company-scoped storage; only authorized buyer/Finance access |
| Save item specification/photo | attached to correct invoice line; persists after refresh |
| Search invoice by code/seller/item/barcode | only authorized quick-purchase documents returned |
| Supplier physically hands goods to buyer | buyer-car item quantity increases once; branch stock unchanged |
| Draft invoice without physical handover | vehicle balance unchanged |
| Warehouse loads stock to buyer car | source branch decreases and buyer-car balance increases atomically |
| Warehouse receives from buyer car | accepted quantity leaves buyer car and enters destination branch once |
| Partial warehouse receipt | only accepted quantity is posted; remainder remains on buyer car |
| Duplicate handover/receipt operation | replay returns duplicate/same result; no second quantity/account effect |
| Customer/operational issue from warehouse to buyer car | balance rises with purpose/reference, branch stock decreases |
| Submit PURCHASE cash expense | invoice proof + completed linked warehouse receipt required |
| Submit FUEL/TRANSPORT/OTHER | correct supporting proof required; no fake supplier/AP payment |
| Expense Submitted | visible as pending; not yet recognized as approved deduction |
| Expense Approved | correct custody reconciliation; no AP supplier debit for cash-paid quick purchase |
| Expense Rejected | remains visible/accountable; no silent deduction |
| Return unused cash to Treasury | actual return acknowledgement/document, one-time receipt and reconciled balance |
| Cross-company user attempts attachment or movement access | rejected |
| Delivery driver app / mobile van stock | unchanged |
| Existing PO receive and SupplierReturn | unchanged and regression-tested |

No Production data should be mutated to perform these tests until the complete changeset is approved. Use isolated fixtures/rollback where possible and prove no test residue.

---

## 8. Exact Risks and Decisions That Must Not Be Guessed

1. The supplier identity strategy for a quick market seller: current invoice schema requires an existing suppliers row. Do not create fake or shared "misc supplier" identities without approved policy.
2. Whether the purchaser's car is already a row in the vehicles master or requires a separate purchasing-vehicle record. Current two vehicles are both Delivery; neither is presumed to be the buyer's car.
3. The exact physical proof and actor for supplier-to-buyer handover.
4. Whether the buyer can deliver to more than one branch; default branch/target branch policy.
5. How customer-specific issues/returns should reference a customer/order, without treating them as sales.
6. The GL mapping for fuel, transportation and miscellaneous expenses.
7. The exact point where purchase invoice status transitions from Draft to Received/Posted/Approved while keeping cash-paid quick purchases distinct from AP invoices.
8. The approved cash-handover evidence and acknowledgment ordering for issue, top-up and cash return.

These are explicit design gates; no silent assumptions.

---

## 9. Official ERP Pattern Check

The target design follows common enterprise controls rather than merely copying screens:
- Microsoft Dynamics 365 documents vendor invoice handling with invoice header/lines, invoice attachments and an integrated image/file viewer; this supports the need for the supplier invoice image to be attached to the invoice record and inspectable by authorized reviewers.
- Dynamics 365 invoice matching supports matching invoice lines against product receipts and allows received-quantity matching; this supports the separation between invoice evidence and actual goods-receipt evidence.

Official references:
- https://learn.microsoft.com/en-us/dynamics365/finance/accounts-payable/vendor-invoice-automation
- https://learn.microsoft.com/en-us/dynamics365/finance/accounts-payable/vendor-invoices-overview

This competitor material informs design controls; it does not override RAWAEA business policy or justify a Production change by itself.

---

## 10. Work Actually Completed in LVE-585

1. Re-read current Buyer source and current Receiver source.
2. Re-read the project governance source and current-state history.
3. Re-read existing Buyer API dispatch and current v22 purchasing gateway source.
4. Queried Production schema, constraints, table privileges, stock-voucher trigger definitions and relevant migration history using SELECT only.
5. Confirmed the two registered Production vehicles are Delivery vehicles.
6. Confirmed the no-PO invoice posting guard, the current expense review AP side-effect, and the mismatch between the existing expense contract and the owner's four expense categories.
7. Authored this corrected implementation contract and next-step scope.
8. No source code or Production business logic was changed in this checkpoint.

---

## 11. Owner Approval Gate and Next Execution

The business definitions are now clear. The technical implementation is not yet complete because Buyer vehicle custody, direct quick-invoice receiving, private invoice evidence and custody expense categories do not exist as an integrated contract in the current Production model.

The next executable package must contain, before any production write:
1. exact migration SQL with dependency order;
2. exact surgical Buyer / Receiver / existing Edge diffs;
3. exact function signatures and role/RLS/storage policies;
4. expected stock, custody, inventory, supplier-ledger and GL deltas for each scenario;
5. failure cases and replay/idempotency outcomes;
6. regression tests for PO receipt, SupplierReturn, Delivery Van stock and all current Buyer tabs;
7. rollback and restoration plan;
8. explicit owner approval on that exact package.

Per the current project governance, operational HTML changes remain owner-applied after review. No migration, trigger, RPC, RLS/grant or Edge deployment is authorized by the broad task request alone.

**Current status:**
OWNER DEFINITIONS CORRECTED / CURRENT SOURCE AND PRODUCTION CONTRACTS RE-VERIFIED / BUYER INVOICE REGISTER NOT YET QUICK-PURCHASE-SCOPED / CASH CUSTODY CATEGORIES NOT IMPLEMENTED / PURCHASING VEHICLE STOCK LEDGER NOT IMPLEMENTED / RECEIVER QUICK-INVOICE INTAKE MISSING / PRIVATE INVOICE ATTACHMENT SECURITY GAP / EXACT CHANGESET TO BE PREPARED FOR OWNER APPROVAL / NO PRODUCTION WRITE IN LVE-585 / NOT CLOSED

---

## 12. Instructions to the Next CTO

1. Start by reading this Report585, then re-fetch the current operational Buyer, Receiver, Edge and the exact Production definitions; do not rely on hashes if current main has moved.
2. Do not re-open Report584's wrong assumption that "vehicle balance" means supplier-to-warehouse return or driver van stock. Use the corrected owner definitions in Section 2.
3. Do not rebuild existing tabs or remove Draft edit/delete safety. Preserve barcode lookup and PO workflow.
4. Do not turn a cash-paid market purchase into AP payment.
5. Do not reuse Driver/mobile stock or supplier-return flow for buyer custody.
6. Prepare the exact full changeset first; stop before applying Production writes until the owner explicitly approves the precise diff.
7. After approval, deploy through the existing authenticated gateway, test each acceptance case, verify balances and accounting effects, inspect Cloudflare served artifact, and update CURRENT_STATE with proof, not claims.
