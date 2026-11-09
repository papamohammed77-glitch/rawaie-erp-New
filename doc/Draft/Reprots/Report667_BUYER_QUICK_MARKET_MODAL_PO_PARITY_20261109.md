# Report667 — Buyer Quick-Market Invoice Modal Parity with PO Invoice Editor

**Date:** 2026-11-09 (Africa/Cairo)  
**Status:** SOURCE CHANGE COMMITTED · CONTRACT / LOCAL INTERACTION HARNESS PASS · PRODUCTION BUSINESS DATA UNCHANGED · DEPLOYMENT / AUTHENTICATED BROWSER E2E OPEN

## 1. Scope and authority

Owner request: in Buyer → «فواتيري», make «شراء سوق سريع» use the same professional invoice-entry interaction pattern as the PO supplier-invoice editor, while preserving the commercial distinction:

- PO invoice: invoice associated with an approved purchase order / supplier delivery.
- Quick Market invoice: a direct purchase invoice from the market, with no synthetic PO.

The current user instruction explicitly authorized a surgical change to `companies/company-1/purchasing/buyer.html`. The embedded handover prompt's general owner-only restriction is superseded for this exact Buyer source change by that explicit, narrower authorization. No additional authorization was inferred for database, Edge Function, RLS, grants, Parent, Core, stock, treasury, supplier balance, or accounting changes.

## 2. Last verified state and current source

- Resumption checkpoint before this task: `LVE-2026-11-09-666`.
- Operational repository: `papamohammed77-glitch/erp-frontend`, branch `main`.
- Pre-task HEAD observed: `8745355ae9962bb26c9ebab1a9f51febdffccc1f` (generated Buyer Tailwind build; not a Buyer business-logic change).
- Pre-task Buyer blob: `56b3ef8fed56f4ac788b4535c371aae16a8f901e`.
- Final HEAD after this task: `e4065cd8eceee4f6287251c2a09609edf7504cb7`.
- Final Buyer blob: `e8c519ac3e6e67ad82598c8d9cf2e9afbed3aa20`.
- Changed file in both commits: `companies/company-1/purchasing/buyer.html` only.

Relevant preceding fixes were re-read as source-navigation, not accepted as proof: Reports 662–666. Report666's local-catalogue/cache-invalidation race is preserved; the new item selection stores the actual modal catalogue item instead of re-reading a mutable shared cache.

## 3. Surgical change set

Two commits were created:

1. `e932e004980919b660cd44a82938e0f96e6c3c16` — `feat(buyer): align quick-market purchase invoice modal with PO invoice editor`.
2. `e4065cd8eceee4f6287251c2a09609edf7504cb7` — `fix(buyer): bind quick-market supplier selection locally`.

Only these Buyer method blocks changed:

- `quickPurchase(invoiceId)`
- Quick-market cart/search methods: `renderQuickSearch`, `quickSelectItem`, `quickAddItem`, `quickUpdate`, `quickRemove`, `renderQuickCart`.

### Resulting modal

The Quick Market modal now follows the PO invoice modal's layout and interaction pattern:

- Supplier autocomplete with supplier identity, code and phone.
- Branch and due-date fields.
- Supplier invoice number and notes.
- Item catalogue search, barcode-camera action, explicit item selection, quantity and manually entered actual unit price, then Add Line.
- Editable invoice-line quantity, actual price, discount percentage and tax rate.
- Per-line total and invoice estimated total.
- Remove-line control and duplicate-item prevention.
- Consistent responsive invoice layout and validation feedback.

Quick Market's mandatory and distinct fields remain:

- No `purchase_order_id` is sent or created.
- `settlement_source` remains either `EMPLOYEE_CUSTODY` or `SUPPLIER_CREDIT`.
- Employee-custody selection is required for custody settlement and is checked against acknowledged available funds after discount and tax.
- Supplier invoice image/PDF remains mandatory for a new Quick Market draft (JPEG/PNG/WEBP/PDF, up to 10 MB); existing attachment and registration flow is retained.
- Actual supplier price is entered manually. No `items.cost_price` default was added.
- Edit guards remain: the buyer-owned Quick Market draft is not editable after a handover event or a linked submitted/approved expense.

A post-write review caught an undeclared temporary supplier-selection variable in the first modal patch. The follow-up commit replaced it with a locally scoped `chosenSupplier`; the final source was re-fetched and recompiled after that correction.

## 4. Data and integration contract — independently checked

### Quick Market write path

The existing Buyer API wrapper sends `operation`, `payload`, and the payload's `operation_id` to the existing `save-purchase-order` Edge Function.

The current Production Edge Function is active at v37. It routes:

- `CREATE_QUICK_MARKET_INVOICE` → `purchase_create_quick_market_invoice_atomic`
- `UPDATE_QUICK_MARKET_INVOICE` → `purchase_update_quick_market_invoice_atomic`

These are separate from `CREATE_PO_INVOICE` / `UPDATE_PO_INVOICE`. The updated modal keeps those Quick Market operations unchanged and sends `discount_percent` and `tax_rate` with every item. The update RPC calls the central draft-invoice updater, which persists discount/tax fields and recalculates line and invoice totals.

Read-only inspection confirmed that the Quick Market RPC contract:

- requires a company-scoped active buyer with effective `purchases` permission;
- validates positive quantity and purchase price, and discount/tax rates from 0 through 100;
- uses idempotent operation identity / payload checks;
- checks acknowledged employee-custody cash and outstanding reservations when `EMPLOYEE_CUSTODY` is selected;
- keeps `purchase_source='QUICK_MARKET'`, `purchase_order_id IS NULL`, `receipt_status='NOT_RECEIVED'`, `settlement_status='UNSETTLED'`, `is_received=false`, and `received_date IS NULL` for the saved draft.

The UI total formula matches the RPC's line formula: quantity × actual price × (1 − discount%) × (1 + tax%), rounded per line to two decimals. No RPC, Edge Function, schema, RLS, grant, trigger, or migration was changed.

### Parent purchase-cycle visibility

The current Parent file was independently inspected from its Git blob (not from a historical report). `RW_PurchaseGold.invoices()` reads the shared `purchase_invoices` collection and the Parent subscribes to that table through its filtered Realtime channel. The Parent invoice query has no filter excluding `QUICK_MARKET`; therefore a Quick Market invoice is present in the same purchase-cycle → purchase-invoices subtab by virtue of its central invoice row. The Parent shows it without a PO reference rather than creating a parallel list.

No Parent change was needed for visibility, so `companies/company-1/main.html` remains untouched. Its current list visually labels the absent PO as «بدون PO»; a dedicated source badge in Parent would be a separate presentation enhancement, not a prerequisite for the shared invoice record to appear.

## 5. Verification

| Check | Result | Evidence / boundary |
|---|---|---|
| Final Buyer source re-fetch | PASS | Final blob `e8c519ac3e6e67ad82598c8d9cf2e9afbed3aa20`. |
| Full inline executable script parse | PASS | The current inline Buyer script compiled with `new Function`. |
| Change isolation | PASS | Prefix, middle and suffix outside the two targeted method blocks match the pre-task blob. |
| PO creation method preserved | PASS | Exact source comparison against pre-task Buyer blob. |
| PO invoice method preserved | PASS | Exact source comparison against pre-task Buyer blob. |
| Realtime/cache race harness | PASS | Rendered modal-local search result; cleared shared cache; selected item still added from modal catalogue. |
| Arabic/Persian letter search | PASS | Arabic partial query selected item code `1011`. |
| Cart behavior | PASS | Manual quantity/price, discount/tax edits, per-line calculation (2 × 12.50 × 0.90 × 1.05 = 23.63), duplicate prevention, line removal, invalid-quantity rejection. |
| Full modal create-flow harness | PASS | Simulated supplier autocomplete, item selection, custody source, invoice attachment upload/registration, operation ID, API payload, and refresh of `فواتيري`. |
| API payload contract | PASS | Quick Market create op used; no `purchase_order_id`; discount/tax and custody fields present. |
| RPC/Edge contract inspection | PASS (read-only) | Existing Edge v37 and current create/update RPC definitions inspected. |
| Parent invoice integration | PASS (source contract) | Parent shared invoice read and Realtime subscription include Quick Market records. |
| Supabase business writes | NONE | Harness API/storage calls were stubs only. No Production invoice, attachment, custody, stock, supplier balance, cash-box, treasury, journal or GL record was created or modified. |
| Authenticated Browser / actual camera | UNVERIFIED | No authenticated Buyer interaction was executed in the browser. |
| Cloudflare served-artifact parity | UNVERIFIED | GitHub main source commit is verified; no served-byte comparison or terminal Cloudflare deployment proof was obtained. |
| Physical warehouse receipt for Quick Market | OPEN / OUT OF SCOPE | This task did not implement or certify Buyer-to-Receiver physical receiving or stock posting. |

A read-only Production count after the source changes still showed one existing Quick Market Draft marked not received. This is an observation of existing data, not a test record created by this task.

## 6. Business-effect protection

This change improves invoice entry only. Saving this document still represents a draft, not the physical receipt or payment event.

No stock increase, supplier payable posting, supplier settlement, employee cash movement, cash-box movement, treasury movement, journal entry, or GL posting is performed by the modal patch. Those effects remain exclusively under the existing central receiving, payment and accounting workflows.

No fictitious PO is created. No direct table DML was introduced. No business-data test transaction was sent to Production.

## 7. Rollback

To reverse this task's source changes only, revert the two commits in reverse order:

1. `e4065cd8eceee4f6287251c2a09609edf7504cb7`
2. `e932e004980919b660cd44a82938e0f96e6c3c16`

No database rollback or business-data cleanup is required because no database or business-data write was made.

## 8. Remaining acceptance gate

1. Verify the terminal Cloudflare Production deployment and compare the served Buyer bytes to final blob `e8c519ac3e6e67ad82598c8d9cf2e9afbed3aa20`.
2. With an authorized Buyer account, test the real modal: new/edit draft, supplier selection, Arabic/code/barcode search, camera permission, line selection and editing, invalid inputs, attachment persistence, and custody limit handling.
3. Open Parent → دورة المشتريات → فواتير الشراء and verify the created invoice row is visible under the same company/role scope.
4. Do not create a Production test invoice to obtain this proof. Use an approved isolated test environment if one becomes available; otherwise mark live write E2E UNVERIFIED.
5. Keep separate the remaining physical handover/warehouse receiving workflow. This report does not close Buyer receiving, vehicle goods custody, supplier-return acceptance, or end-to-end Procure-to-Pay.

**Final status:** BUYER QUICK-MARKET MODAL PARITY IMPLEMENTED IN SOURCE · LOCAL INTERACTION / CONTRACT TESTS PASS · PARENT SHARED-INVOICE VISIBILITY CONFIRMED BY SOURCE · NO PRODUCTION BUSINESS DATA CHANGED · CLOUDFLARE / AUTHENTICATED BROWSER E2E OPEN.
