# 48 — TASK-028 SURGICAL TEST MATRIX
## Date: 2026-08-14
## Branch: `task-028-loading-unloading-refactor`
## Mode: STATIC / PRE-DEPLOYMENT QA — NO PRODUCTION EXECUTION

## FACT

The Current branch now contains:

- atomic Loading Core RPC;
- atomic Unloading inverse RPC;
- thin `complete-loading` wrapper;
- thin `unload-runsheet` wrapper;
- fulfillment Backorder ledger migration.

## STATIC ACCEPTANCE

| Test | Expected |
|---|---|
| Full loading | MAIN decreases; VAN increases by exact loaded quantity; one Loading log; Runsheet `Loaded` |
| Partial loading | Only loaded quantity transfers; each order line never exceeds picked capacity; remaining quantity recorded in Backorder ledger |
| Zero/negative load | Entire transaction rejected; no stock or log change |
| Item absent | Entire transaction rejected; no partial effects |
| Missing MAIN stock row | Entire transaction rejected |
| Missing VAN stock row | Entire transaction rejected |
| Insufficient MAIN available stock | Entire transaction rejected |
| Loaded > picked capacity | Entire transaction rejected |
| Retry after successful Loading | `Loaded` state rejects request; no second stock movement |
| Concurrent Loading for same Runsheet | Runsheet row lock allows one winner; second call rejects on state |
| Full Unloading | VAN decreases by persisted `qty_loaded`; MAIN increases same amount; Runsheet `Picked` |
| Unloading with missing VAN stock | Entire transaction rejected; no MAIN addition |
| Retry after successful Unloading | `Picked` state rejects request; no second reversal |
| Order-detail authority | `order_details.qty_loaded` is the only fulfillment quantity written by Core; trigger derives `run_sheet_details` |
| Trigger consistency | Aggregate `run_sheet_details.qty_loaded` equals sum of linked `order_details.qty_loaded` |
| Allocation release | MAIN `allocated_qty` decreases by no more than requested loaded quantity |
| Generated available quantity | No direct write to `available_qty` |
| Accounting | No journal entry created by Loading/Unloading Core |
| Backorder deduplication | Unique `(order_detail_id, runsheet_id)` prevents duplicate ledger rows |
| Unloading Backorder reversal | Pending rows for the reversed Runsheet become `Cancelled` |
| Inventory-log cardinality | One deterministic Loading/Unloading log per item per Runsheet operation |
| Company isolation | Runsheet, Vehicle, Item, Branch and settings must all belong to same company |

## DATABASE INVARIANTS

```text
0 <= qty_loaded <= qty_picked <= qty

MAIN_after = MAIN_before - loaded_qty
VAN_after  = VAN_before  + loaded_qty

UNLOAD:
VAN_after  = VAN_before  - persisted_qty_loaded
MAIN_after = MAIN_before + persisted_qty_loaded

No COGS at Loading/Unloading.
```

## REVIEW CHECKS

1. Confirm migration is not executed against Production.
2. Confirm no `Original/` file changed in branch diff.
3. Confirm no direct `stock_branches` mutation remains in the two wrapper functions.
4. Confirm wrappers do not write `inventory_log`, `journal_entries`, `journal_lines`, `run_sheet_details`, or Backorder rows directly.
5. Confirm Core RPCs are `SECURITY DEFINER` and use `SET search_path = public`.
6. Confirm Core RPCs are transaction-scoped by PostgreSQL function execution.
7. Confirm deterministic log IDs are derived from Runsheet + item, not timestamps/randomness.
8. Confirm `sync_run_sheet_details()` remains the aggregation boundary.
9. Confirm no legacy `remaining_qty` column is referenced by the new Current implementation.
10. Confirm Production deployment has not occurred.

## DEPLOYMENT GATE

This branch is **NOT** a Production deployment.

Before Production:

```text
Static review
-> Dev/Staging execution
-> Full test matrix
-> Deployment approval
-> Production verification
-> Implementation Reality Matrix update
```
