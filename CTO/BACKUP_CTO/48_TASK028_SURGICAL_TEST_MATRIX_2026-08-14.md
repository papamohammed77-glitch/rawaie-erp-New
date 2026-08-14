# 48 — TASK-028 SURGICAL TEST MATRIX
## Date: 2026-08-14
## Branch: `task-028-loading-unloading-refactor`
## Mode: STATIC / NON-PRODUCTION QA — NO PRODUCTION EXECUTION

## REQUIRED GATE ORDER

```text
Responsibility Audit
-> P0 Idempotency
-> Lifecycle Compatibility
-> Static Validation
-> Staging Migration
-> Runtime Matrix
```

## RUNTIME TESTS

| Test | Expected |
|---|---|
| Full loading | MAIN qty decreases; MAIN allocated decreases; VAN qty increases; Runsheet `Loaded` |
| Partial loading 6/10 | MAIN -6; allocated -6; VAN +6; `qty_loaded=6`; remaining=4 |
| Second legitimate partial load 4/10 | accepted as a new event with a different payload hash/key |
| Exact retry of prior load | duplicate event, no second stock effect, no second inventory log |
| Retry with same key but different qty/type | idempotency conflict, no stock effect |
| Concurrent exact duplicate | one physical effect; duplicate winner/loser is deterministic; no second log |
| Full unloading | VAN decreases persisted `qty_loaded`; MAIN increases same amount; MAIN allocated increases same amount; Runsheet `Picked` |
| Exact retry of unloading | duplicate/no second reversal; state gate also prevents second lifecycle execution |
| Missing MAIN stock row | full rollback |
| Missing VAN stock row | full rollback |
| Insufficient picked reservation | full rollback |
| Loaded > picked | full rollback |
| Failure after stock mutation | full transaction rollback: stock/log/orders/backorder/state return to baseline |
| Backorder deduplication | unique `(order_detail_id, runsheet_id)` prevents duplicate ledger rows |
| Unloading backorder reversal | Pending rows belonging to the reversed Runsheet become `Cancelled` |
| Trigger consistency | `run_sheet_details` equals aggregation of authoritative `order_details` |
| Generated availability | no direct write to `available_qty` |
| Accounting boundary | no COGS/journal created at Loading or Unloading |
| Company isolation | every Runsheet/Vehicle/Item/Branch resolves within company context |
| Reopen-loading lifecycle | must use VAN->MAIN reversal, restore MAIN allocation, preserve loaded quantities, and return to `Loading` |

## DATABASE INVARIANTS

```text
0 <= qty_loaded <= qty_picked <= qty

LOADING:
MAIN.qty            -= loaded_qty
MAIN.allocated_qty  -= loaded_qty
VAN.qty             += loaded_qty

UNLOADING:
VAN.qty             -= persisted_qty_loaded
MAIN.qty            += persisted_qty_loaded
MAIN.allocated_qty  += persisted_qty_loaded

No COGS at Loading/Unloading/Reopen-Loading.
```

## IDEMPOTENCY REQUIREMENTS

The test must validate **event-level idempotency**, not only state gating:

- `inventory_log.idempotency_key` is persisted;
- `(company_id, idempotency_key)` is unique;
- Loading identity includes Runsheet cycle markers plus normalized operation payload hash plus item;
- Unloading identity includes Runsheet cycle markers plus persisted payload hash plus item;
- random `log_code` is never treated as the event identity.

## STATIC REVIEW CHECKS

1. `Original/` unchanged.
2. Production unchanged.
3. Thin wrappers contain no direct stock/log/accounting/backorder writes.
4. Core functions are `SECURITY DEFINER` with `SET search_path=public`.
5. `order_details` is authoritative; trigger derives `run_sheet_details`.
6. Generated `available_qty` is never written.
7. Backorder table has company/order/detail/runsheet/item FKs and uniqueness.
8. No stale `remaining_qty` field is referenced.
9. No obsolete competing TASK-028 migration remains.
10. `reopen-loading` compatibility is resolved before staging execution.

## DEPLOYMENT GATE

No Production deployment is permitted until the full matrix passes in non-production and the Implementation Reality Matrix is updated.