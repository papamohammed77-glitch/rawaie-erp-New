# Report654 — Parent Finance Employee Custody Detail Modal & Actions Forensic

**Date:** 2026-11-08 (Africa/Cairo)  
**Checkpoint:** LVE-2026-11-08-654  
**Status:** CURRENT SOURCE / SMART ERP VERIFIED — MODAL CHANGESET FROM REPORT653 STILL NOT APPLIED — EDIT/CANCEL BACKEND GAP CONFIRMED — DEPLOYMENT / INTERACTIVE E2E UNVERIFIED

## 1. Executive result

The requested row-detail modal is the correct UX for the Finance custody register. The current Parent source still opens the page-level details drawer and scrolls to the matching card. Report653 already contains a complete, statically checked four-point modal ChangeSet, but that ChangeSet has not been applied.

The present request adds Edit and Delete to the detail modal. Neither operation exists in the active save-purchase-order Edge Function or the current public custody RPC set. No safe direct DML route exists: the custody tables are RLS-protected and expose scoped SELECT policies, while the ledger contains acknowledged advances, cash-box receipts and journal references. The custody record cannot safely be hard-deleted.

**Recommended treatment:**
- Open details in the wide, RTL SweetAlert2 modal already specified in Report653.
- Preserve the current SETTLE_CUSTODY action as the final settlement-and-cash-return action.
- Add Edit only for a custody that is still wholly pre-disbursement and has no dependent financial/operational documents.
- Implement “Delete” as a soft cancellation (UI label: إلغاء العهدة) with an immutable audit entry; never physically delete a cash-custody ledger row.
- Do not show Edit/Cancel as enabled actions once any advance has been acknowledged or any cash-box/journal/expense/supplier-payment/settlement/quick-market link exists.

No Parent source, Supabase schema, row, RPC, RLS/ACL, Edge Function or financial transaction was changed during this investigation.

## 2. Governing prompt and checkpoint

- Execution prompt: doc/Draft/Reprots/writing-block-8-10.md, SHA 39f18748a8a3cf633a04506216cc39fd98de523d; read completely (34,511 characters / 1,300 lines).
- Permanent constitution: SHA 3a6b1e220af8509e314e94df76563bbc6f84910d.
- Opening checkpoint: LVE-2026-11-08-653.
- Current report-repository HEAD before this report: ffb352df29f4a3eb9172a0d620df701e56c1e9c9.
- Governing restrictions retained: Parent operational source changes are owner-applied ChangeSets under constitution §7.1 / prompt §10.1; specific database/schema/RPC/RLS/ACL/Edge and financial-contract changes require a concrete approved ChangeSet under §6.2 / prompt §10.2. This report does not treat a general feature request as approval for an unreviewed schema or financial contract.

Relevant reports re-read against current evidence:
- Report648 — employee-custody issue action/auth/profile integration.
- Report650 — server-paginated register and active Edge v33.
- Report651 — duplicate bind(root) collision diagnosis.
- Report652 — one-identifier binder correction committed.
- Report653 — full detail-modal UX decision and four-point Parent ChangeSet.

## 3. Current operational source — independent Git verification

- Operational repo: papamohammed77-glitch/erp-frontend.
- Branch: main.
- Latest observed HEAD: c8d40b32150d2cb0e7e5830bac4a9e3d0a846655.
- Parent file: companies/company-1/main.html.
- Current Parent blob: 879383859d0ec20927cc718e63a7af49fa18980c.
- Fix commit retained in current ancestry: d514060d88c8156f982b6d586715c7af7d7f4c6a.
- The only descendant after that functional fix changes _forensic_current_main_extract.md, not main.html.

### Current code behavior

Within RW_Finance_Custody:
- The register button is data-custody-open-detail="<custody id>".
- Its current active handler expands #custody-full-ledger, finds [data-custody-detail] for the selected ID and calls scrollIntoView().
- It does not call Swal.fire(), change routes or navigate to another page.
- The active comprehensive bind(root) now remains callable after the earlier same-scope legacy declaration was renamed to bindLegacy(root) by commit d514060...
- The detail card currently contains the custody summary, five amount/balance cards, cash advances and acknowledgement history, expenses/supplier invoices and linked supplier payments, settlement history, plus existing advance / settle / review / document actions.
- No Edit or Delete/Cancel control is rendered.

The source fix in Report652 is present in the current blob; it is not evidence that Cloudflare serves it yet.

## 4. Modal visual and functional reference inspected

### Parent Purchase Request modal — RW_PurchaseGold.createRequest()

The in-file reference uses SweetAlert2, width 980, RTL, a gradient hero with icon and subtitle, grouped form sections, consistent spacing and rounded surfaces, didOpen for interactive controls, validation and explicit confirm/cancel labels.

### Parent Purchase Order detail — RW_Purchases.openPO()

The detail reference uses a read-only SweetAlert2 dialog, a close affordance, no artificial confirm/save button, structured supplier/status summary and an items/total block. This is the closer behavioral reference for a custody detail view.

### Selected custody treatment

Use Report653's wide responsive min(1100px, 96vw) modal, Finance-indigo hero, RTL layout, viewport-bounded scroll body, close button, and no confirm button on the read-only detail view. Preserve the register's filters, current page and page size behind the modal. Existing financial actions must call their established functions only after closing the detail modal where a second dialog is required.

Report653's Change A–D are the exact existing Parent modal ChangeSet. They remain not applied and must be re-anchored against the current blob before owner application.

## 5. SMART ERP — live schema, API and financial contract

- Authoritative project: Supabase SMART ERP fiilmooggumokxanwiyx, ACTIVE_HEALTHY, PostgreSQL 17.6.1.121.
- Active existing Edge Function: save-purchase-order, version 33, ACTIVE, verify_jwt=true.
- Live source hash: d547f66e0455da9f9e315c95cd5e04fc9ec59cc2dafaa4aa7cc47e8c6bfe181b.

### Current custody operations actually exposed

The current Edge source and pg_proc inventory expose:
- GET_CUSTODY
- ISSUE_CUSTODY
- ACKNOWLEDGE_CUSTODY
- ADD_CUSTODY_ADVANCE
- ACKNOWLEDGE_CUSTODY_ADVANCE
- SUBMIT_CUSTODY_EXPENSE
- SUBMIT_OTHER_CUSTODY_EXPENSE
- VERIFY_CUSTODY_EXPENSE_OPERATION
- REVIEW_CUSTODY_EXPENSE
- REVIEW_OTHER_CUSTODY_EXPENSE
- GET_OTHER_CUSTODY_EXPENSE_ACCOUNTS
- SETTLE_CUSTODY

There is no UPDATE_CUSTODY, DELETE_CUSTODY, CANCEL_CUSTODY, or custody-specific edit/delete/cancel RPC in the current live function inventory. Do not add buttons that send invented operation names and then report them as functional.

### RLS and referential integrity

The five main custody tables have RLS enabled. Their current policies provide scoped authenticated SELECT; there are no general authenticated UPDATE/DELETE policies. Existing Security Definer RPCs have internal authentication, company, permission and branch validation; ACL inspection confirmed anon cannot execute them and authenticated can.

Critical relationships:
- buyer_custody_advances.custody_id references buyer_custodies.id ON DELETE RESTRICT.
- buyer_custody_settlements.custody_id references buyer_custodies.id ON DELETE RESTRICT; the settlement table also has UNIQUE(custody_id).
- buyer_custody_expenses.custody_id references the custody row with ON DELETE CASCADE; expense rows may link to purchase invoices, supplier payments and journal entries.
- Advance, expense, payment and settlement tables retain cash-box / journal / supplier / invoice relationships.
- buyer_custodies.status CHECK currently permits only Issued, UnderReview, Settled, Closed; there is no Cancelled value.

Therefore hard DELETE is not an acceptable business action. It can be blocked by RESTRICT children or cascade expense history, and must never be used to erase evidence for a posted receipt/payment or journal entry.

### Existing audit log

The existing public.audit_log table contains company_id, actor_user_id, action, table_name, record_id, old_data, new_data, source_type and operation_id. It is RLS-enabled. It has non-unique lookup indexes, including operation ID + created time; no unique operation_id index was found. There is no audit_log trigger. A future atomic Edit/Cancel RPC must write its own audit row and implement retry/idempotency safely; merely assuming a generic trigger exists would be wrong.

## 6. Live SMART ERP custody baseline — read-only

The live database currently contains one custody, one advance, no expenses, no supplier payments and no settlements.

Aggregate result for that open custody:
- Status: Issued
- Currency: EGP
- Issued amount: 5,000.00
- Acknowledged advances: 5,000.00
- Unacknowledged advances: 0
- Approved expenses: 0
- Pending expenses: 0
- Prior cash returns / settlement rows: 0

A separate relationship check confirms:
- Acknowledged advances: 1
- Advance rows with cash-box receipt: 1
- Advance rows with journal entry: 1
- Pending advances: 0
- Expenses: 0
- Supplier payments: 0
- Settlements: 0
- Quick-market purchase invoices linked to the custody: 0

**Decision for the currently existing record:** it has already crossed the cash-disbursement and journal-posting gate. Edit and cancellation must be unavailable for this record. The current final settlement / cash-return action remains eligible subject to the existing server rules. No settlement or cash-return operation was executed.

### Existing final settlement contract

The Parent settle(id) client computes the return from issued_amount - approved expenses; the live buyer_custody_settle_atomic RPC independently recalculates the same figure after locking the custody record. It rejects:
- custody not in Issued / UnderReview
- self settlement or unauthorized company/branch/Finance actor
- submitted expenses awaiting review
- unacknowledged advances
- open quick-market purchase allocations
- approved expense total exceeding the issued amount
- a cash-return amount that does not exactly reconcile
- invalid/inactive/wrong-branch/non-Cash/POS treasury

For a positive return, the RPC creates the actual cash receipt and journal entry through post_cash_receipt_atomic, inserts the settlement row and sets custody status to Settled. This is a single final settlement, not a partial-return ledger. The settlement table's unique custody constraint confirms only one final settlement row per custody.

The existing UI label تسوية ورد نقد is therefore the real action; it should be retained inside the new modal and must not be replaced by a client-only balance calculation or direct table write.

## 7. Required Edit / Delete behavior — safe ChangeSet contract

### A. Edit

Add UPDATE_CUSTODY to the existing save-purchase-order Edge Function and a new authenticated atomic RPC (do not create another Edge Function). The RPC must lock the row and revalidate every condition server-side. A UI check is not authorization.

Enable Edit only when all of the following hold:
1. Custody status is exactly Issued; it is not UnderReview, Settled, Closed or cancelled.
2. Main custody acknowledged_at and received_at are NULL.
3. Every linked advance has acknowledged_at IS NULL, cash_box_id IS NULL and journal_entry_id IS NULL.
4. No expense, supplier payment, settlement, quick-market purchase reservation or other posted dependent document exists.
5. Actor is active, authorized for Finance and authorized for the custody branch; the employee/company ownership checks pass.
6. The edit is idempotent and records before/after values, actor, reason and operation ID in audit_log.

The RPC must update the custody header and corresponding initial-advance values together in one transaction, keep additional advances arithmetically consistent, validate positive amounts and system currency, and reject an edit that changes an already acknowledged/posting-linked record. The current UI must not decide eligibility by trusting cached values alone.

Allowed fields and arithmetic must be finalized in the RPC ChangeSet before coding. Descriptive fields may be editable in the pre-acknowledgement state; any amount/date change must synchronize the Initial advance and the master amount/date so the employee's acknowledgement confirms the exact updated document.

### B. Delete / cancellation

Do not physically DELETE a custody row. Implement CANCEL_CUSTODY as an atomic soft cancellation that retains custody, advance and audit history:
1. Finance-authorized actor and branch scope required.
2. Lock the custody row.
3. Require the same no-acknowledgement / no-cash-box / no-journal / no-expense / no-payment / no-settlement / no-quick-market-document checks as above.
4. Require a non-empty cancellation reason.
5. Set status to a new explicit Cancelled state (the existing CHECK constraint must be safely extended).
6. Write audit_log old/new values and actor/operation ID atomically.
7. Keep original custody code and source rows for forensic/history; prevent any acknowledgement, advance, expense or settlement operation on a cancelled custody.
8. Display ملغاة in the register and make the record read-only.

Do not misuse Closed to mean cancelled; that would conflate a reconciled custody with a cancelled request and corrupt reporting semantics.

### C. Settlement / cash return

Keep the current SETTLE_CUSTODY operation for a final settlement. It already produces the actual cash receipt and GL entry atomically and blocks unresolved balances/documents. It is not a separate partial cash-return API. If the owner later requires interim/partial cash returns, that is a distinct accounting design: immutable return-event ledger, each return linked to a cash-box receipt and journal, cumulative-return reconciliation, and an update to the final settlement contract. Do not emulate partial returns by inserting extra settlement rows because UNIQUE(custody_id) is present.

### D. Modal and action layout

Recommended detail-modal structure:
1. Header: custody code, employee, branch, status, close affordance.
2. Top financial summary: issued total, acknowledged cash, pending acknowledgement, approved expenses, current cash balance.
3. History sections: cash deliveries/advances, expenses and purchase invoices, supplier payments, settlement.
4. Action bar with state-aware controls:
   - تعديل البيانات only for records passing the pre-disbursement edit gate.
   - إلغاء العهدة only for records passing the pre-disbursement cancellation gate; require reason and confirmation.
   - زيادة عهدة while custody is open under existing rules.
   - تسوية ورد نقد while final settlement is eligible under existing server rules.
5. For already posted/acknowledged, settled, closed or cancelled records, show a clear read-only explanation and omit edit/cancel controls.
6. Any action that opens another dialog closes the detail modal first, then calls its existing or newly authorized operation once; on success refresh the same register page while preserving filters/page size.

## 8. Exact Parent ChangeSet scope and anchors

**Target:** papamohammed77-glitch/erp-frontend / main / companies/company-1/main.html  
**Current anchor blob:** 879383859d0ec20927cc718e63a7af49fa18980c.

### Modal core — inherit Report653 Change A–D

Use the exact four changes in Report653:
- A. Add openDetail(id,root) immediately before the current active function bind(root).
- B. Replace the detail click expand/scroll branch with openDetail(id,h).
- C. Keep current detail-card template as the single source but hide the below-table accordion.
- D. Replace the below-table helper note with the modal/filter-retention note.

Report653 contains the complete proposed helper and verbatim original/replacement anchors. Reconfirm all anchors against the current Parent blob before application.

### Added action wiring — requires the backend contract in §7 first

- Add data-custody-edit and data-custody-cancel action markers only after the new Edge operations/RPCs exist and are deployed.
- Extend the modal's own delegated handler to route Edit and Cancel; do not add a second conflicting root onclick or duplicate the comprehensive bind(root).
- Add small private edit(id) and cancel(id) functions within RW_Finance_Custody; re-fetch/refresh through the existing render() path after success.
- Update status rendering to label Cancelled as ملغاة; disable issue/advance/review/settlement actions on a cancelled custody.
- Do not alter unrelated Finance tabs, Parent router, Core, Buyer, Driver or existing accounting code.

This action extension is not yet an executable production patch because its Edge/RPC/DB contract does not exist. The exact RPC argument/SQL definition, audit shape, DDL rollback and test plan must be reviewed together before any schema or Edge deployment.

## 9. Deployment and browser evidence

The connected browser could only read open tabs; it could not reload, click or inspect interactive behavior in this session.

- Parent application tab displayed the Employee Custody register and the existing inline detail section, including one open custody row.
- Cloudflare dashboard's last available snapshot (tab last opened 2026-11-08 18:12:13Z) displayed Production deployment b68c77a4 sourced from commit 855810884e9184122c5f149b6d052479a840cc6f.
- That displayed source predates the binder fix commit d514060... The dashboard snapshot is not a refreshed current deployment poll; treat deployment parity as UNVERIFIED, not as proof that the present latest build is still that one.
- No authenticated modal click, close/Escape, nested accordion interaction, action routing, keyboard, mobile viewport, Console or Network E2E was performed.

## 10. Acceptance tests required after the approved implementation

### Static / source
- One active comprehensive bind(root); no later duplicate declaration that shadows it.
- Each new modal/action marker and handler exists exactly once.
- Complete Parent inline executable script parses.
- Modal is RTL and viewport-bounded; no route change or page refresh on open/close.
- All action IDs and operation payloads are passed unchanged to the correct service operation.

### State and permissions
- A posted/acknowledged custody cannot be edited/cancelled.
- An unacknowledged, unposted custody can be edited subject to server revalidation.
- Cancellation requires a reason and is soft-only.
- Cross-company, cross-branch and non-Finance users are rejected by RPC even if they forge UI calls.
- Idempotent retry cannot produce a second update/cancellation/audit event.

### Financial invariants
- Opening/closing details has zero write calls and no cash/stock/journal effect.
- Edit before acknowledgement creates no cash movement.
- Cancel before acknowledgement creates no cash movement and preserves audit/advance history.
- Final settle posts one cash receipt and its journal entry for exactly the server-computed outstanding return; custody transitions to Settled exactly once.
- No approved supplier invoice/payment or stock receipt is changed by custody UI operations.

### UX / deployment
- Details opens once; X and Escape close; inner body scrolls; underlying register filter/page/page-size remain unchanged.
- Advance/review/settle/document route once; no event handler collision.
- Test narrow/mobile and desktop widths.
- Confirm Cloudflare serves the new Parent blob before declaring implementation deployed.
- No production QA transaction is left behind; use reversible, explicitly tagged test data and full cleanup only if a test transaction is truly required.

## 11. Rollback and closure state

- Modal-only Parent rollback: revert only the modal helper, detail click branch, hidden-template attribute and note line to the exact previous blob; preserve all earlier finance binder fixes.
- Edit/cancel backend rollback: only with an approved staged rollback plan that restores the prior status constraint and service contract without deleting audit/cash/journal evidence. Do not drop posted ledger records.
- No operational rollback was needed because no operational source or database writes were made.

**Closure:** CURRENT SOURCE / LIVE CUSTODY / EDGE CONTRACT VERIFIED — REPORT653 MODAL CHANGESET NOT APPLIED — EDIT/CANCEL REQUIRE NEW AUTHORIZED BACKEND CONTRACT — CLOUDFLARE / AUTHENTICATED UI E2E UNVERIFIED.

---
