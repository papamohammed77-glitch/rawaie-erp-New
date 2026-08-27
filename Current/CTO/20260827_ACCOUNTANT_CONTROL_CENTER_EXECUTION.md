# RAWAEA ERP — Accountant Control Center Execution Record

Date: 2026-08-27
Repository branch: main

## Governance
Execution followed the governing modification principle: Production and direct source evidence were treated as higher authority than historical reports. No new financial or inventory writer was introduced.

## Production changes actually applied
Two read-only Accountant Control Center layers were deployed to Production:
- `20260827_accountant_read_model_a`
- `20260827_accountant_read_model_b`

All new functions are `SECURITY INVOKER` and were revoked from PUBLIC/anon, then granted to authenticated users. They read existing Cores and tables; they do not mutate stock, journals, ledgers, treasury, orders, runsheets, or settlements.

### Read models
- `accountant_coa_tree`
- `accountant_gl_account_activity`
- `accountant_customer_aging`
- `accountant_supplier_aging`
- `accountant_runsheet_center`
- `accountant_order_center`
- `accountant_inventory_control`
- `accountant_reconciliation_summary`
- `accountant_exception_center`
- `accountant_audit_feed`
- `accountant_period_readiness`

## Production verification
A real authenticated user context was applied through a transaction for verification.

Observed Production Company context: `00000000-0000-0000-0000-000000000001`

Verified results:
- COA rows exposed through the accountant tree: 17
- Customer aging rows: 0
- Supplier aging rows: 0
- Runsheet center rows: 0
- Order center rows: 0
- Inventory control result: 1 summary row (`CURRENT_TOTAL`)
- Accountant exception center rows: 0
- Audit feed rows for the current month window: 214
- Period readiness: `UNBALANCED_JOURNALS=PASS`, `FAILED_OPERATIONS=PASS`, `PENDING_DRIVER_LIABILITIES=PASS`, `STOCK_INVARIANTS=PASS`, `PERSISTENT_PERIOD_CLOSE=REVIEW`

## Important integrity findings
The Production Item Master has a global `UNIQUE(item_code)` contract. Therefore item/company metadata mismatches in `stock_branches` were not treated as corruption merely from a cross-company comparison. No mass deletion or reassignment was performed without direct historical/relational proof.

The deployed `post_stock_movement` remains the Physical Stock movement authority. Accountant Control Center contains no physical-stock writer.

## PWA
`Current/PWA/accountant.html` was replaced with the Control Center implementation and committed to `main` after local JavaScript syntax validation.

Existing capabilities retained:
- authentication and owner/finance gating
- treasury context validation
- receipt/payment through existing Edge Functions
- journal browsing
- existing financial reporting family
- CSV export

Added read/control capabilities:
- financial dashboard health gates
- runsheet financial center
- order financial center
- customer and supplier aging
- inventory financial control
- COA tree and detailed G/L account activity
- P&L / Balance Sheet / Cash Flow access
- treasury movement view
- reconciliation center
- exception center
- audit feed and Core operation registry
- period-close readiness gates

## Explicit non-claims
- No persistent accounting-period Close mutation was invented because no verified Production contract/table for it was found.
- Static PWA source is synchronized to Git `main`. A separate static-host deployment mechanism was not present in the verified repository workflow set, so browser/runtime hosting deployment is not claimed from Git commit alone.
- No database test fixture was left behind by the verification transactions.

## Zero-debt principle
The Accountant Control Center is a read/control plane over existing financial and operational Cores. It intentionally does not create Distributed Writers.
