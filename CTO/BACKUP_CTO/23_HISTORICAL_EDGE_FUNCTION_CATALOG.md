# 23 — HISTORICAL EDGE FUNCTION CATALOG

## Status
Historical responsibility reconstruction. Not a Production deployment map.

## Evidence
Historical `Edge_Functions/original/` contains domain-grouped function trees including:
- order lifecycle
- picking
- loading
- runsheet
- delivery
- returns
- settlement
- inventory
- purchasing
- master data
- accounting
- sales
- reporting
- infrastructure

The historical API catalog records 71 Edge Functions, but the catalog itself contains duplicated entries and therefore must not be interpreted as a canonical unique-function count without reconciliation.

## Responsibility map

| Domain | Representative historical functions | Main effects |
|---|---|---|
| Order lifecycle | `save-sales-invoice`, `confirm-order`, `create-runsheet`, `append-to-runsheet` | orders, order_details, runsheets |
| Picking | `start-picking`, `complete-picking`, `cancel-picking`, `reopen-picking` | reservation/allocation, runsheet detail, inventory history |
| Loading | `start-loading`, `complete-loading`, `cancel-loading`, `reopen-loading` | physical stock deduction, allocation release, inventory log, cost accounting |
| Delivery | `start-delivery`, `complete-order-delivery`, `complete-delivery`, cancel/reopen variants | delivery quantities, customer ledger, revenue accounting, vehicle tracking |
| Returns | `start-return`, `complete-return`, `cancel-return`, `reopen-return` | returned quantities, stock, liabilities, credit note/customer effects |
| Settlement | `save-daily-settlement` | daily settlement, driver liabilities, accounting |
| Inventory/vouchers | `create-stock-voucher`, `send-stock-voucher`, `receive-stock-voucher`, `complete-stock-voucher`, `cancel-stock-voucher`, `unload-runsheet`, `save-inventory-count` | stock_vouchers, stock_branches, inventory_log |
| Purchasing | `save-purchase-order`, `receive-purchase`, `start-receiving`, `cancel-receiving`, `reopen-receiving` | purchasing, receiving, stock, accounting |
| Accounting | `save-journal-entry`, receipt/payment/transfer vouchers, reports | journal, treasury/cash, financial reports |
| Master data | save/delete item/customer/supplier/branch/employee/role/settings | master data |
| Utility/audit | `sync-run-sheet-details`, `log-action`, `report-discrepancy`, `get-driver-dashboard`, `force-unassign-runsheet` | projection, audit, discrepancy, dashboard/recovery |

## Historical mutation topology

### Stock mutation candidates
Historical sources identify direct mutation capability in:
- `complete-picking` (allocation)
- `complete-loading` (physical stock)
- `complete-return` (return stock)
- `receive-purchase` (inbound stock)
- `send-stock-voucher` (source deduction)
- `receive-stock-voucher` (target addition)
- `unload-runsheet` (stock restoration)
- inventory adjustment functions

### Accounting mutation candidates
- `complete-loading`
- `complete-order-delivery`
- `complete-return`
- `receive-purchase`
- `save-daily-settlement`
- receipt/payment/transfer voucher functions
- manual journal entry

### Ledger mutation candidates
Historical documentation identifies customer ledger and driver liability/ledger effects in delivery, return and settlement paths; supplier ledger was explicitly identified as incomplete in the historical workflow review.

## Important historical architecture fact
The historical system allowed many Edge Functions to own direct side effects. This is one of the sources of the later distributed-business-logic risk.

## Current-vs-historical classification
- Historical function presence: `CONFIRMED HISTORICAL`
- Current source equivalent: must be mapped per function.
- Production deployment: `UNKNOWN` unless explicit deployment evidence exists.
- Function report statements: `HISTORICAL EVIDENCE`, not runtime proof.

## Important discrepancies
The historical API catalog includes duplicate entries such as `complete-stock-voucher` and `save-purchase-order`. Therefore the number 71 must be treated as a historical catalog count, not a guaranteed unique-function count.

## Gold rule
Do not delete or replace an original function solely because a current function exists with a similar name. Behavioral responsibility and side effects must be compared first.
