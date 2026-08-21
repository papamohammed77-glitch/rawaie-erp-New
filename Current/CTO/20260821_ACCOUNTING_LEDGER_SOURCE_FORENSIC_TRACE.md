# RAWAEA ERP — ACCOUNTING / LEDGER SOURCE FORENSIC TRACE

**Date:** 2026-08-21  
**Authority:** Direct Production Supabase + current Git source only.  
**Reports/history:** navigation only; no report claim is treated as current truth.

## 1. Production deployment reality

Direct Production Edge Functions currently active include:

- `save-journal-entry` v6
- `save-receipt-voucher` v5
- `save-payment-voucher` v3
- `save-transfer-voucher` v3
- `save-daily-settlement` v3
- `update-driver-ledger` v1
- `save-sales-invoice` v15
- `receive-purchase` v12
- `complete-return` v24
- `complete-order-delivery` v13

The corresponding `Current/Edge_Functions` paths for `save-journal-entry`, `save-receipt-voucher`, `save-payment-voucher`, `save-transfer-voucher`, and `save-daily-settlement` are NOT present on `main` at the time of this trace.

## 2. Production Financial Writer finding

Direct `pg_proc` inspection shows no canonical public `post_journal_entry` or central ledger posting function comparable to `post_stock_movement`.

Current Production domain functions directly write financial state:

- `save_sales_invoice_atomic`
  - inserts `journal_entries`
  - inserts `journal_lines`
  - inserts `customer_ledger` for credit sales
  - inserts `driver_ledger` for VAN credit cases
- `receive_purchase_atomic`
  - inserts `journal_entries`
  - inserts `journal_lines`
  - inserts `supplier_ledger`
- `complete_return_atomic`
  - inserts `journal_entries`
  - inserts `journal_lines`
  - inserts `customer_ledger`

Therefore the financial writer model is currently distributed.

## 3. Published Edge writers

### `save-journal-entry` v6

Production source validates Authorization and resolves `company_id` from `public.users`, verifies account ownership, then directly inserts journal header and lines.

It is tenant-aware but not a single database transaction / canonical posting engine. A header can be persisted before a later line failure unless the request itself rolls back at the DB layer; the implementation does not call a central accounting RPC.

### `save-receipt-voucher` v5

Production source directly writes:

- `cash_box`
- `journal_entries`
- `journal_lines`
- `treasury`
- `driver_ledger`

The implementation hard-codes company ID `00000000-0000-0000-0000-000000000001` in `cash_box` and `journal_entries`, and performs direct treasury balance mutation by account lookup.

### `save-payment-voucher` v3

Production source directly writes:

- `cash_box`
- `journal_entries`
- `journal_lines`
- `treasury`

and hard-codes the MAIN company ID in `cash_box` and `journal_entries`.

### `save-transfer-voucher` v3

Production source directly writes:

- two `cash_box` rows
- `journal_entries`
- `journal_lines`
- source treasury balance
- target treasury balance

and hard-codes the MAIN company ID in `cash_box` and `journal_entries`.

### `save-daily-settlement` v3

Production source directly writes:

- `daily_settlements`
- `driver_liabilities`
- `journal_entries`
- `journal_lines`
- `runsheets.status`

and hard-codes the MAIN company ID in `daily_settlements` and `journal_entries`.

The implementation also allows `journal_lines` insertion failure to be logged without failing the whole settlement response, and it can continue to close the runsheet.

### `update-driver-ledger` v1

Production source directly inserts into `driver_ledger` using service-role client and accepts `driver_email`, debit, credit, reference and description from request data. The function body does not resolve company context or enforce a driver/company relationship.

## 4. Current main.html consumers

Direct Git source inspection of `Current/PWA/main.html` confirms the application calls the deployed financial functions:

- `save-journal-entry`
- `save-receipt-voucher`
- `save-payment-voucher`
- `save-transfer-voucher`
- `save-daily-settlement`

The UI therefore has real deployed consumers for these financial capabilities.

## 5. Production financial data snapshot

Direct Production query:

- `chart_of_accounts` = 87
- `journal_entries` = 2
- `journal_lines` = 0
- `customer_ledger` = 0
- `supplier_ledger` = 0
- `driver_ledger` = 0
- `treasury` = 1
- `cash_box` = 0
- `daily_settlements` = 0
- `cheques` = 0

Both current `journal_entries` are `Posted` `VoidInvoice` headers with **zero journal lines**.

This is a current persisted data-integrity finding, not a report interpretation.

## 6. Current database security finding

Direct Production inspection shows broad `public` policies / grants on financial tables.

Examples include `Allow all for all` policies on:

- `cash_box`
- `customer_ledger`
- `daily_settlements`
- `journal_entries`
- `journal_lines`
- `supplier_ledger`
- `treasury`

`driver_ledger` also has broad table grants, including INSERT for anon/authenticated, with a policy whose `with_check` is `true`.

The current database role grants additionally expose DML privileges to `anon` and `authenticated` on multiple financial tables.

## 7. Closure blockers

### ACC-001 — No canonical accounting posting engine

No `post_journal_entry` equivalent is currently present in Production public functions.

### LED-001 — No canonical ledger posting layer

Customer, Supplier and Driver ledgers are written by separate domain/Edge paths.

### FIN-001 — Tenant-unsafe published financial writers

Receipt, Payment, Transfer and Settlement production functions contain hard-coded MAIN company context.

### FIN-002 — Non-atomic financial multi-table operations

Several published writers perform multiple sequential writes across cash, journal, treasury, ledger and settlement state without a single canonical transaction boundary.

### SEC-001 — Financial tables have excessive direct DML exposure

Current Production RLS/grants are not aligned with the desired ERP financial authority boundary.

### DATA-001 — Posted journal headers without lines

Two current `journal_entries` are persisted as Posted with zero `journal_lines`.

### DEP-001 — Production financial Edge/Git divergence

Multiple active Production financial Edge functions have no corresponding `Current/Edge_Functions` artifact on `main`.

## 8. Concurrency evidence status

Current Git contains a real concurrent HTTP canary for `complete-picking` that starts two simultaneous requests and asserts exactly one success and one failure. This proves the project has an actual concurrency-test mechanism for that domain.

It does NOT prove live concurrent correctness of Accounting, Ledger, Treasury, Receipt, Payment, Transfer or Settlement operations.

## 9. Required next closure sequence

1. Freeze the current Production financial topology as evidence.
2. Build accounting event-to-journal writer matrix from deployed functions and Core RPCs.
3. Build customer/supplier/driver/treasury/settlement writer matrix.
4. Establish owner/business contracts for receipt, payment, transfer, settlement and manual journal posting.
5. Close deployment lineage for every deployed financial Edge.
6. Design/implement canonical financial posting only after contract proof.
7. Migrate ledger and treasury writers behind authoritative Core boundaries.
8. Re-test tenant isolation and concurrency at the financial boundary.
9. Repair or explicitly classify the two orphan Posted journal headers before final financial closure.

**Status:** `AUTONOMOUS CTO NOT READY — FINANCIAL CORE CLOSURE REQUIRED`
