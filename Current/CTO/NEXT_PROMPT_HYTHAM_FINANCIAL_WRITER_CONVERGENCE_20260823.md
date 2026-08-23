# HYTHAM — NEXT EXECUTION DIRECTIVE
## FINANCIAL WRITER CONVERGENCE / ACCOUNTING CORE

### Mission

Own the **write-side financial convergence** after the master-data truth is established. Your job is to prevent parallel accounting/ledger/treasury engines and ensure every financial write is tenant-safe, atomic, idempotent, and traceable.

Current Production owner:

`00000000-0000-0000-0000-000000000001` / `MAIN` / `الروائع`

### Production facts you must start from

- `chart_of_accounts`: currently empty pending forensic recovery by Khalid.
- Treasury `CASH-01` has been restored exactly under the current company.
- `journal_entries` exists but current `journal_lines` count is 0.
- Current SQL proves the following canonical functions exist:
  - `save_sales_invoice_atomic`
  - `receive_purchase_atomic`
  - `complete_return_atomic`
  - `complete_order_delivery_atomic`
- Do not assume the existence of canonical RPCs for receipt/payment/transfer/daily-settlement/driver-ledger just because historical reports mention them.

### Required investigation

For every financial writer:

1. Find the live Edge Function deployment/version.
2. Find the live PostgreSQL function actually called.
3. Inspect all direct DML into:
   - journal_entries
   - journal_lines
   - treasury
   - cash_box
   - customer_ledger
   - supplier_ledger
   - driver_ledger
4. Trace the authenticated user -> public.users -> company_id path.
5. Reject global `LIMIT 1` company/account lookups where tenant identity is required.
6. Trace account identity by account_id/account_code and prove the relationship to the current chart.
7. Trace Treasury identity and cash_box FK identity.
8. Trace operation identity/idempotency and retry semantics.
9. Verify rollback behavior for partial failure.
10. Find duplicate/parallel financial writers and determine the canonical responsibility for each.

### Priority order

1. save-receipt-voucher
2. save-payment-voucher
3. save-transfer-voucher
4. update-driver-ledger
5. save-daily-settlement
6. save-sales-invoice
7. receive-purchase
8. complete-return
9. complete-order-delivery

### Mandatory architectural target

```text
Business operation
      ↓
Domain transaction / RPC
      ↓
Canonical financial posting core
      ↓
Journal / Treasury / Ledger state
```

No financial endpoint may independently maintain a second journal, treasury, or ledger semantics.

### Important contract rule

Do not edit the PWA merely because a financial writer is broken. First repair the authoritative backend contract. Any UI patch must be surgical and must be tied to a verified Production consumer contract.

### Execution discipline

For each writer, run a closure unit:

DISCOVER → RECONSTRUCT CONTRACT → TRACE PRODUCTION → TRACE CURRENT → IDENTIFY GAP → SURGICAL FIX → TEST/ROLLBACK → DEPLOY → PRODUCTION VERIFY → CLOSE

Do not process multiple unrelated writers as one unverified batch.

### Required output

For every writer produce:

- Historical
- Production
- Current
- Target
- Consumer
- Direct writes
- Tenant boundary
- Account identity
- Idempotency
- Atomicity
- Canonical replacement
- Loss/gain responsibility matrix
- Production runtime proof

### Zero-debt gate

The assignment is not complete while any financial writer:

- writes directly outside the canonical core;
- accepts unverified company context;
- depends on global lookups;
- has retry duplication risk;
- can leave partial accounting state;
- has Production/Current drift;
- or silently loses a historical business responsibility.
