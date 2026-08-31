# RAWAEA ERP — PHASE 8 ACCOUNTING & LEDGER FORENSICS

**Date:** 2026-08-31  
**Phase:** 8 — Accounting / Ledger Forensics  
**Status:** CLOSED  
**Production mutation:** None.

## CURRENT ACCOUNTING DATA STATE

Fresh Production snapshot at `2026-08-31T08:46:42.769419Z`:

- `journal_entries`: 2
- `journal_lines`: 0
- `customer_ledger`: 0 rows
- `supplier_ledger`: 0 rows
- `driver_ledger`: 0 rows
- All ledger debit/credit totals: 0

Both current journal headers are `Cancelled` and have `entry_type = VoidInvoice` with references `VOID-ORD-1015` and `VOID-ORD-1016`.

Because there are no journal lines, there is no current posted trial-balance population to validate. The two empty cancelled headers are not treated as active unbalanced journal entries.

## JOURNAL WRITER CONTRACT

Current Production `post_journal_entry` is a `SECURITY DEFINER` PL/pgSQL writer that:

1. requires company and operation context;
2. requires an array with at least two lines;
3. validates each account belongs to the same company and is active;
4. rejects negative, zero, or both-sided lines;
5. requires both nonzero debit and credit;
6. requires total debit = total credit;
7. writes the journal header and lines in the same database transaction;
8. records operation status in `erp_operation_registry` for idempotent behavior;
9. creates an audit log entry.

This is a materially stronger control than the historical July architecture description, which largely framed financial posting as Edge Function-side workflow behavior.

## CUSTOMER LEDGER WRITER

Current `post_customer_ledger_entry`:

- requires company, operation and customer context;
- verifies the customer belongs to the company;
- prevents invalid debit/credit combinations;
- maintains a rolling balance;
- records operation status through `erp_operation_registry`;
- writes an audit log event.

## SUPPLIER LEDGER WRITER

Current `post_supplier_ledger_entry`:

- requires company, operation and supplier context;
- verifies supplier/company ownership;
- enforces debit/credit validity;
- maintains supplier balance;
- records operation status through `erp_operation_registry`;
- writes an audit log event.

This is direct evidence that the supplier-ledger gap documented in the July workflow baseline has been addressed in the current transaction engine. The historical baseline explicitly recorded `receive-purchase` as updating stock and accounting while not updating `supplier_ledger`. fileciteturn40file0L2-L2

## ACCOUNTING–INVENTORY LINKAGE

Current Production `save_sales_invoice_atomic` creates stock movement for invoiced sales through `post_stock_movement` and uses the current journal/cash/customer/driver ledger writers for the financial consequences.

Current `receive_purchase_atomic` posts `PurchaseIn` through `post_stock_movement`, creates the purchase-receipt journal, and posts the supplier ledger entry.

Current `complete_runsheet_loading` delegates the physical loading movement through `post_stock_movement`; the accounting consequence of loading must be validated separately across the full workflow because the observed function itself is focused on fulfillment/physical movement.

## CURRENT ACCOUNTING ANOMALY CLASSIFICATION

### A-001 — Empty cancelled void headers

Severity: **INFO / provenance required**, not automatically a defect.

Evidence:
- both rows are `Cancelled`;
- both references are `VOID-*`;
- zero lines exist;
- zero debit and zero credit totals result.

Required later action: trace the historical function/migration that created these headers and determine whether the intended void contract is header-only or should have a linked reversal entry.

No repair is permitted until provenance is established.

## CURRENT ACCOUNTING LIMITATIONS

The current Production dataset is too sparse to prove normal accounting workflows end-to-end:

- no current posted journal lines;
- no customer ledger rows;
- no supplier ledger rows;
- no driver ledger rows;
- no active purchase/sales/order transactions.

Therefore writer-level correctness is strongly evidenced by current function definitions, but live end-to-end accounting execution is not yet Production-verified.

## CONTROL CONCLUSION

The accounting core currently has meaningful database-side controls: balancing, company/account ownership checks, operation-level idempotency, and audit logging.

However, complete accounting correctness remains unproven because Production currently contains almost no active accounting data. Later phases must combine historical reconstruction, writer matrix analysis, and safe non-production transaction tests.

## EXIT GATE

`PHASE 8 CLOSED`

Current accounting structures, journal/ledger data state, writer contracts, and known anomalies have been directly inspected. No accounting data was changed.
