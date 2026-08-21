# RAWAEA ERP — DIRECT-SOURCE KNOWLEDGE CLOSURE

Date: 2026-08-21
Production: SMART ERP / fiilmooggumokxanwiyx
Rule: Production + current Git + deployed definitions + migration ledger are truth. Historical reports are navigation only.

## CURRENT PRODUCTION

Direct live query at 2026-08-21 17:57:49 UTC:

- companies = 3
- users = 26
- branches = 5
- items = 50
- stock_branches = 26
- inventory_log = 3
- stock_vouchers = 0
- stock_voucher_details = 0
- orders = 0
- runsheets = 0
- purchase_orders = 0
- journal_entries = 2
- journal_lines = 0
- audit_log = 1775
- customer_ledger = 0
- supplier_ledger = 0
- driver_ledger = 0

Current production migration head = 20260821023458.

## INVENTORY

Direct PostgreSQL inspection confirms:

- active 10-argument post_stock_movement = canonical executable physical writer.
- 9-argument legacy post_stock_movement exists but is not executable by service_role.
- reserve_stock and release_stock_reservation are reservation writers, not physical movement writers.
- sensitive inventory RPCs use SECURITY DEFINER + search_path=public.
- authenticated EXECUTE is denied for the canonical physical movement engine.

Current inventory state is therefore REGRESSION FOUNDATION / VERIFIED, not an open reconstruction task.

## CURRENT ACCOUNTING WRITERS

Direct pg_get_functiondef inspection proves live accounting/ledger side effects in at least:

- save_sales_invoice_atomic: journal_entries, journal_lines, customer_ledger for credit, driver_ledger for Van credit.
- receive_purchase_atomic: journal_entries, journal_lines, supplier_ledger.
- complete_return_atomic: journal_entries, journal_lines, customer_ledger; driver_liabilities for run-sheet shortage.

Current production does NOT expose a single canonical public post_journal_entry function in the current 42-function public inventory inspected during this closure.

Historical references to post_journal_entry/save_journal_entry_atomic must therefore remain historical until their current replacement/provenance is proven.

## DIRECT LEDGER / FINANCE RISK BOUNDARY

The remaining ERP-wide investigation must explicitly trace live Edge Functions that directly mutate:

- journal_entries
- journal_lines
- customer_ledger
- supplier_ledger
- driver_ledger
- treasury
- daily_settlements

A historical/current closure artifact already identified critical direct writers in receipt, payment, daily settlement and driver-ledger paths; those claims must be re-verified against the live Edge source before any remediation is designed.

## ACCOUNTING DATA CONDITION

Current Production has 2 journal headers and 0 journal lines.

This is a proven data condition, but its provenance and intended semantics are not yet proven. No deletion, synthetic line creation, or data rewrite is authorized on this fact alone.

## IDENTITY

Live constraints directly confirm:

- public.users.auth_id -> auth.users.id (FK + UNIQUE)
- public.users.company_id -> companies.id (FK)

Identity mapping must continue to be verified against each consumer rather than copied from historical bug reports.

## READINESS

AUTONOMOUS CTO READY = NO.

Open gates that remain materially unproven from direct sources:

1. complete live Accounting Writer inventory
2. complete live Ledger Writer inventory
3. complete PWA/Edge/RPC/DB consumer graph
4. Git SHA -> deployed artifact/runtime lineage
5. real independent-session concurrency proof
6. complete Security grant + RLS + SECURITY DEFINER matrix
7. accounting event -> journal -> ledger reconciliation
8. accounting data provenance for header-only journal entries

Next legitimate closure unit: ACCOUNTING CORE FORENSIC, followed by LEDGER CORE FORENSIC.
