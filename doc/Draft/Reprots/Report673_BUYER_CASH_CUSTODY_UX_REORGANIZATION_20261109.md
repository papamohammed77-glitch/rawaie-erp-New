# Report673 — Buyer Cash Custody UX Reorganization
**Date:** 2026-11-09 (Africa/Cairo)  
**Status:** Buyer cash-custody UI reorganization committed to operational `main`; financial RPCs reviewed and preserved; static JavaScript and custody-balance calculation harnesses passed. Cloudflare deployment and authenticated browser E2E remain unverified.

## 1. Scope and source baseline

- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Previous Buyer blob: `94e2e95d13d2d1aa8687a8c0d394a8508176137e`.
- UI commit: `1b761d0ee60a4f7c2ab14b14e8e0390fb0c35aac` — Improve Buyer cash custody balance clarity and expense layout.
- Follow-up refinement: `da37cbd27c0fd363bff95008919baee79622b654` — Refine Buyer custody summary and prevent overdrawn submissions.
- Final Buyer blob: `072710c9db0184b0744eebd027fcdd3daf297269`.
- Changed file: `companies/company-1/purchasing/buyer.html` only.
- No changes to Parent, warehouse, receiver, voucher, Core, Edge Function source, database schema, RLS, SQL functions, or operational rows.

## 2. Confirmed UX defects

The former `renderCustody()` page displayed a global summary that summed all open custody values and all pending/approved expenses without grouping by employee or currency. It then repeated a dense eight-column metric strip inside every employee custody card, followed by large reservation, advance, return, and expense lists. The actual `availableCash` amount existed, but was only the last small field in that strip. It was also clamped with `Math.max(0,...)`, hiding an overdrawn custody balance as zero.

This presentation blurred three distinct concepts:
- approved expenses already posted through the appropriate finance path;
- submitted expenses that reserve cash but are not yet approved;
- open Quick Market invoice reservations, which are not expenses and must not be deducted twice when a claim is approved.

## 3. Implemented Buyer UI

### 3.1 Clear personal balance first
- The default view now shows the current user's own open custodies first.
- The dominant summary displays **الرصيد المتبقي في عهدتي** per currency, without adding EGP to another currency.
- The summary fields are: original registered custody amount, cash acknowledged as actually received, approved expenses, submitted expenses pending review, Quick Market reservations, cash returned to Treasury, and current available balance.
- The calculation displayed is:
  `available = acknowledged cash − approved expenses − submitted expenses − open Quick Market reservations − cash returned`.
- Open Quick Market reservations continue to use the existing helper: invoice remaining amount after `paid_amount` and active Submitted claims. Approved QMP claims are already reflected by the invoice's increased `paid_amount`, so the reservation falls as the approved expense enters the committed total.
- The UI groups personal custody totals by currency. It never adds unlike currencies.
- A negative result is shown as an explicit **cash deficit** with a warning rather than being silently clamped to zero.
- Further expense-submission buttons are hidden when no positive available cash remains; the user receives a direct explanation.

### 3.2 Finance employee registry separated
- Finance users still retain the ability to issue custody, add advances, review expense submissions, and settle/return cash.
- The current user's personal custody remains the default view.
- Other employees' custody records are now placed in a separate collapsed **متابعة عهد الموظفين** section, not mixed into the employee's own summary.
- Closed personal and staff custody history is separated into collapsible sections.

### 3.3 Expenses organized by state
Each custody now has three distinct expense/document groups:
1. Approved and posted expenses (visible first).
2. Submitted documents awaiting finance review.
3. Rejected documents.

Expense entries consistently show amount, document type, supplier/reference/date, status, evidence links, receipt evidence, existing supplier payment reference where present, journal/account posting indication, review note, and the existing finance approve/reject actions.

Quick Market invoice review still routes to `REVIEW_QUICK_MARKET_CUSTODY_EXPENSE`; PO invoice review still routes to `REVIEW_CUSTODY_EXPENSE`; operational expenses still route to `REVIEW_OTHER_CUSTODY_EXPENSE`. The UI action wiring was re-read after the redesign.

### 3.4 Scoped visual system
- Added Buyer-only CSS classes inside the existing `buyer.html` style block: a compact dark-violet balance overview, responsive currency panels, a clear per-custody balance hero, consistent metric tiles, and collapsible detail groups.
- This uses scoped CSS in the existing Buyer document; no Parent styles, global Core styling, or compiled shared assets were changed.

## 4. Financial RPC review — existing contracts preserved

Read-only review covered the Buyer custody retrieval contract in `save-purchase-order` v39 and the current Production definitions/paths for:
- `buyer_custody_review_expense_atomic` — PO-linked supplier invoice settlement, supplier payable/payment/ledger effects, and employee-custody journal.
- `buyer_custody_review_quick_market_expense_atomic` — QMP accepted-receipt value validation, Dr Inventory 124 / Cr Employee Custody 127, invoice `paid_amount` update, and no supplier AP/ledger/payment or extra Treasury movement.
- `buyer_custody_review_other_expense_atomic` — selected operating-expense account debit / employee-custody credit, without a new Treasury or stock movement.
- `buyer_custody_return_cash_atomic` — partial return through a separate cash receipt, locked custody, branch/Treasury validation, and status update.
- `buyer_custody_settle_atomic` — final close only after pending submissions, unacknowledged advances and open QMP reservations are cleared.
- The existing Buyer `quickMarketCashReservation()` and review action dispatch.

The financial contracts already distinguish PO, Quick Market and operational-expense approvals correctly. No SQL or Edge change was justified for a presentation-only task, so these functions were left unchanged.

## 5. Production snapshot and balance reconciliation

Read-only Production snapshot at verification:
- One open Buyer custody, currency EGP, status `UnderReview`.
- Original registered custody: EGP 5,000.
- Cash acknowledged with cash-box and journal references: EGP 5,000.
- Approved expenses: EGP 0.
- Submitted expense pending review: EGP 200.
- Quick Market invoices: 2 Draft / UNSETTLED, total EGP 1,430, paid EGP 0.
- Open Quick Market reservation: EGP 1,430.
- Cash returned: EGP 0.

Therefore the balance presented by the new formula is:
`5,000 − 0 − 200 − 1,430 − 0 = EGP 3,370`.

## 6. Verification evidence

**PASS**
- Full inline Buyer JavaScript parsed successfully after both source commits.
- Final Buyer file re-fetched from GitHub; final blob SHA matches the reported file.
- The test harness extracted the actual `quickMarketCashReservation()` and `getMetrics()` helpers from the committed Buyer source and passed:
  1. Live EGP balance calculation: 3,370.
  2. Moving a 200 EGP expense from Submitted to Approved leaves available cash unchanged; only its classification changes.
  3. Approving a 500 EGP partial Quick Market receipt decreases invoice reservation by 500 while adding 500 to approved expenses; total cash commitment is not deducted twice.
  4. A 300 EGP cash return decreases the available balance by 300 and appears in the returned-cash field.
- GitHub commit diff confirms only `companies/company-1/purchasing/buyer.html` changed.
- Supabase checks were read-only. No invoice, expense, advance, return, settlement, journal, stock, supplier, cash-box, Treasury, or custody business row was created or modified.

**NOT VERIFIED**
- GitHub combined status and workflow-run queries returned no status checks/workflows for `da37cbd`; do not interpret absence as a pass.
- Cloudflare terminal Production Success and served Buyer byte parity could not be confirmed from available access.
- The connected browser had no accessible authenticated Buyer runtime session through the available browser context; no authenticated UI E2E or visual review was completed.
- No synthetic business data was seeded in Production or staging.

## 7. Rollback

Revert the two Buyer-only commits in reverse order:
1. `da37cbd27c0fd363bff95008919baee79622b654`
2. `1b761d0ee60a4f7c2ab14b14e8e0390fb0c35aac`

No database rollback or business-data cleanup is required. The generated CSS build commit `2d056fd19c33cde247b36d4fe827632e04b4b898` is not required for the new scoped inline styles; retain or revert it only according to the existing automated build process.

## 8. Next acceptance step

After the new Buyer asset is served by Cloudflare, authenticate as a Buyer and verify that the personal balance overview displays EGP 3,370 for the current snapshot; approved, pending and Quick Market reservation rows remain separate; a new realtime or refresh event updates the values; and the Finance-only employee registry and review actions remain permission-scoped. Then test a finance-approved operational expense and a partial QMP receipt against a disposable, rollback-safe fixture in a schema/security-parity environment.
