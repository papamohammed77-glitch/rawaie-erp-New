# HYTHAM — PROMPT 56 FINANCIAL LINEAGE + SECURITY CLOSURE

Date: 2026-08-24
Environment: SMART ERP Production
Current Company: 00000000-0000-0000-0000-000000000001

## Production baseline

- Companies: 1
- Users: 24
- Treasury: 1
- Chart of Accounts: 0
- Journal Entries: 2
- Journal Lines: 0
- Customer Ledger: 0
- Supplier Ledger: 0
- Driver Ledger: 0
- Orders: 0
- Purchase Orders: 0
- Runsheets: 0
- Inventory Log: 3
- PostgreSQL: 17.6

## Security proof

The following Production financial cores currently grant EXECUTE only to service_role and deny PUBLIC, anon, and authenticated:

- post_journal_entry
- post_customer_ledger_entry
- post_supplier_ledger_entry
- post_driver_ledger_entry
- post_cash_receipt_atomic
- post_cash_payment_atomic

The canonical security migration is present in main:
`supabase/migrations/20260824_restrict_financial_core_execute_privileges.sql`
Commit: `666a71dde6f555b54377738b6524007314c176b8`

## Canonical Financial Core Migration

Production was re-applied from the canonical migration:
`supabase/migrations/20260824_canonical_financial_writer_cores.sql`

This migration records the verified Production definitions for:

- post_journal_entry
- post_customer_ledger_entry
- post_supplier_ledger_entry
- post_driver_ledger_entry

and their service_role-only EXECUTE boundary.

## Current Edge lineage

### save-sales-invoice
Production: v15, JWT required.
Current Git `Current/Edge_Functions/save-sales-invoice` was synchronized to the verified Production v15 contract.

### receive-purchase
Production: v12, JWT required.
Current Git `Current/Edge_Functions/receive-purchase` was reconciled to the verified Production v12 contract.

### complete-return
Production: v24, JWT required.
Current Git contains the same business wrapper contract and delegates to `complete_return_atomic`. Non-functional formatting/comment differences do not change the deployed contract.

### save-journal-entry
Production: v8, JWT required.
The function was absent from `Current/Edge_Functions` and has now been added from the verified Production v8 source.

## Financial writer convergence proof

The following Production RPCs currently show zero direct Journal/Ledger DML outside canonical cores:

- save_sales_invoice_atomic
- receive_purchase_atomic
- complete_return_atomic

The remaining direct Journal/Ledger DML discovered by the global sweep is inside the canonical cores only:

- post_journal_entry
- post_customer_ledger_entry
- post_supplier_ledger_entry
- post_driver_ledger_entry

Inventory remains delegated through `post_stock_movement` and was not modified.

## Driver Ledger ownership

`driver_ledger` has no company_id column.
Tenant ownership is proven through the current contract:
`driver_email -> public.users.email -> public.users.company_id`.

`post_driver_ledger_entry` verifies:
- company_id
- active driver identity
- supported driver roles
- operation identity
- duplicate protection
- running balance
- audit

No driver_ledger schema change was made.

## Closure status

Financial Core Security: CLOSED by Production evidence.
Production/Git Financial Core Lineage: CLOSED for the four canonical SQL cores and the reconciled core Edge wrappers listed above.

Still OPEN and intentionally not claimed as closed:

- Authenticated HTTP E2E for the remaining financial runtime paths.
- Two-session concurrency proof.
- Receipt writer convergence/runtime.
- Payment writer convergence/runtime.
- Daily Settlement writer convergence/runtime.
- Live Purchase business-flow proof (Production has no purchase orders).
- Live Return business-flow proof (Production has no orders/runsheets).
- Global Financial Writer Zero-Debt.

## Hard rules preserved

- No COA creation.
- No Treasury remapping.
- No Company identity changes.
- No Inventory Core changes.
- No Accountant UI changes.
- No Finance Manager UI changes.
- No PWA changes for this closure unit.
- No claim of Global Zero-Debt without HTTP and concurrency evidence.
