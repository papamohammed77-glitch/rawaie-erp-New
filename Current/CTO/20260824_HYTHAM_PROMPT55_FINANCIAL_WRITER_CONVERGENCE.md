# HYTHAM — PROMPT 55 FINANCIAL WRITER CONVERGENCE

Date: 2026-08-24
Production: SMART ERP `fiilmooggumokxanwiyx`
Current operating model: one active company only.

## 1. Production Re-Baseline

Verified directly in Production PostgreSQL:

- companies = 1
- current company = `00000000-0000-0000-0000-000000000001`
- users = 24
- journal_entries = 2
- journal_lines = 0
- customer_ledger = 0
- supplier_ledger = 0
- driver_ledger = 0
- treasury = 1
- cash_box = 0
- PostgreSQL 17.6

No retired Company ID is used by the current execution path.

## 2. Global Writer Discovery

Production SQL discovery showed direct financial writes only in the canonical cores after convergence:

- `post_journal_entry`
- `post_customer_ledger_entry`
- `post_supplier_ledger_entry`
- `post_driver_ledger_entry`

Before convergence, the confirmed non-core writers were:

- `save_sales_invoice_atomic`
- `receive_purchase_atomic`
- `complete_return_atomic`

They have now been routed through the canonical cores for Journal/Ledger posting.

Physical inventory remains on `post_stock_movement` and was not changed.

## 3. Driver Ledger Contract

Current `driver_ledger` contains `driver_email` but no `company_id` and no FK.

Ownership was proven without altering the ledger schema:

- `users.email` is UNIQUE.
- `users.company_id` is mandatory and FK to `companies`.
- Current drivers are explicit users with role `مندوب توصيل`.
- Current production contains driver users but no active vehicle rows and no daily settlement rows.
- Therefore the current effective ownership contract is: Driver Ledger identity is `driver_email`, and the caller is valid only when that email resolves to an active driver user belonging to the supplied current company.

No company field was invented or added to `driver_ledger`.

## 4. Driver Ledger Core

Created Production core:

`post_driver_ledger_entry(company_id, operation_id, driver_email, entry_date, reference, description, debit, credit)`

Properties:

- SECURITY DEFINER
- restricted search_path
- current-company driver validation
- positive single-sided entry validation
- operation idempotency
- driver-row locking through `users`
- running balance
- audit
- service_role execution only

A transactional Production test succeeded and was rolled back.

Post-rollback: no test `driver_ledger` row and no test operation-registry row remained.

## 5. POS Writer Convergence

`save_sales_invoice_atomic` no longer directly inserts:

- `journal_entries`
- `journal_lines`
- `customer_ledger`
- `driver_ledger`

It now calls:

- `post_stock_movement`
- `post_cash_receipt_atomic` for cash sales
- `post_journal_entry` for sales/COGS
- `post_customer_ledger_entry` for credit customer sales
- `post_driver_ledger_entry` for Van Credit

POS PWA was not modified because its current consumer already supplies `operation_id` and the backend contract is now sufficient for the convergence.

## 6. Purchase Receiving Convergence

`receive_purchase_atomic` no longer directly inserts:

- `journal_entries`
- `journal_lines`
- `supplier_ledger`

It now routes through:

- `post_stock_movement`
- `post_journal_entry`
- `post_supplier_ledger_entry`

The supplier ownership contract is proven from `suppliers.company_id`.

## 7. Return Convergence

`complete_return_atomic` no longer directly inserts:

- `journal_entries`
- `journal_lines`
- `customer_ledger`

It now routes financial posting through:

- `post_journal_entry`
- `post_customer_ledger_entry`

Inventory movement remains `post_stock_movement`.
Driver shortage/liability records remain operational `driver_liabilities`; this is intentionally not reclassified as Driver Ledger without a proven contract.

No live Return business-flow test was fabricated because current Production has zero Orders and zero Runsheets.

## 8. Current Git / Production Lineage

`Current/Edge_Functions/save-sales-invoice` on `main` was stale relative to Production v15.

A review branch has been created:

`heytham/20260824-financial-writer-convergence`

The branch synchronizes `Current/Edge_Functions/save-sales-invoice` with verified Production v15 behavior, including operation identity/idempotency handling.

No PWA file was modified.

## 9. Tests

Completed:

- Driver Ledger transactional test + rollback
- POS cash transactional behavior + rollback
- POS credit transactional behavior + rollback
- POS duplicate/retry behavior
- Direct-writer database sweep after convergence

Not yet closed:

- authenticated HTTP end-to-end runtime proof
- two-session concurrency proof
- live Purchase Receiving business-flow proof (current Production has no purchase orders)
- live Return business-flow proof (current Production has no orders/runsheets)
- Receipt/Payment authenticated HTTP runtime proof
- Daily Settlement writer convergence

No test data was intentionally left in Production.

## 10. Final Status

`FINANCIAL WRITER CONVERGENCE = OPEN / PARTIAL`

The financial write boundary is materially centralized, but the Prompt 55 Zero-Debt gate is not declared closed until HTTP E2E, concurrency, deployment lineage for all writers, and remaining Daily Settlement/Receipt/Payment runtime paths are proven.

## Guardrails Observed

- Current company only; retired company IDs not reused.
- No COA fabrication.
- No Treasury mapping fabrication.
- No Inventory Core modification.
- No accountant.html modification.
- No finance-manager.html modification.
- No POS PWA modification.
- Current Git only for source changes.
- Production SMART ERP only for live database changes.
