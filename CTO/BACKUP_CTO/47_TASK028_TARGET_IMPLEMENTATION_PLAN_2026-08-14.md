# 47 — TASK-028 TARGET IMPLEMENTATION PLAN
## Date: 2026-08-14
## Branch: `task-028-loading-unloading-refactor`
## Mode: CURRENT-ONLY CONTROLLED REFACTOR / NO PRODUCTION MUTATION

## FACT

Production evidence confirms:

- `post_stock_movement(...)` exists as a `SECURITY DEFINER` PostgreSQL function and currently excludes `Loading` / `Unloading` from its deployed movement contract.
- `complete-loading` currently performs direct stock, inventory-log, order/run-sheet quantity, accounting, state, and Backorder side effects sequentially.
- `unload-runsheet` currently restores MAIN directly and does not decrement the Vehicle/VAN stock branch.
- `sync_run_sheet_details()` is the authoritative aggregation trigger from `order_details` into `run_sheet_details`.
- The live `run_sheet_details` schema does not expose the legacy `remaining_qty` field referenced by the deployed legacy `complete-loading` implementation.
- Vehicle `VEH-92yrzb` has a production branch `VAN-VEH-92yrzb`.

## DECISION

Principal CTO authorization is accepted:

```text
Loading   = internal MAIN -> VAN stock transfer
Unloading = exact inverse VAN -> MAIN
Loading   != DirectSale
Loading   != Customer Return
No COGS at Loading/Unloading
```

## TARGET

### Loading

One PostgreSQL transaction will:

1. lock the Runsheet;
2. require `status = Loading` and a valid Loading cycle identity;
3. resolve the assigned Vehicle and canonical `VAN-<vehicle_code>` branch;
4. validate requested quantities against picked capacity in `order_details`;
5. lock MAIN and VAN stock rows in deterministic order;
6. move MAIN -> VAN through `post_stock_movement`;
7. consume the corresponding MAIN `allocated_qty` reservation;
8. distribute `loaded_qty` across matching order lines without exceeding picked capacity;
9. let `sync_run_sheet_details()` derive the Runsheet aggregates;
10. write one inventory movement per item with a deterministic event-level idempotency key;
11. create one Backorder ledger row per still-unfulfilled order detail where required;
12. transition Runsheet `Loading -> Loaded`;
13. transition linked Orders to `Loaded`;
14. commit atomically.

### Unloading

One PostgreSQL transaction will:

1. lock the Runsheet;
2. require `status = Loaded` and a valid completed Loading cycle;
3. resolve the Vehicle/VAN branch;
4. read persisted `qty_loaded` from `run_sheet_details`;
5. lock VAN and MAIN stock rows in deterministic order;
6. move VAN -> MAIN through `post_stock_movement`;
7. restore MAIN `allocated_qty` by the reversed loaded quantity;
8. write one deterministic Unloading event per item;
9. reset `order_details.qty_loaded` so the existing trigger derives `run_sheet_details`;
10. cancel Backorder ledger rows belonging to the reversed Runsheet load;
11. transition Runsheet `Loaded -> Picked`;
12. transition linked Orders to `Pending`;
13. commit atomically.

## IDEMPOTENCY

State gating remains a lifecycle guard, but it is NOT the idempotency contract.

The event-level contract is:

```text
inventory_log.idempotency_key
        ↓
UNIQUE(company_id, idempotency_key)
```

Loading and Unloading use deterministic keys derived from:

- Runsheet id;
- Loading cycle markers (`loader_start` and, for Loading, the previous `loader_end` when present);
- normalized operation payload hash;
- item UUID.

Therefore:

- retrying the exact same operation returns `duplicate=true` and performs no second stock effect;
- a legitimate subsequent Partial Loading with a different operation payload gets a different key;
- a key reused with a different movement type or quantity raises an idempotency conflict;
- concurrent duplicate calls are protected by deterministic row locks plus the unique key.

Random UUIDs remain acceptable only as non-semantic `inventory_log.log_code`; they are NOT used for idempotency.

## ATOMICITY

`complete_runsheet_loading` and `complete_runsheet_unloading` are PostgreSQL transaction boundaries. Physical stock, inventory log, fulfillment quantities, Backorder state, and Runsheet/Order transitions succeed or roll back together.

## TRIGGER BOUNDARY

`order_details` remains authoritative for fulfillment quantities. `sync_run_sheet_details()` remains the derived aggregation mechanism. The Core does not manually dual-write `run_sheet_details`.

## CONTROLLED REFACTOR CLASSIFICATION

The Edge Functions are intentionally reduced to capability wrappers. This is a **CONTROLLED REFACTOR**, not a one-line surgical patch, because responsibility is moved from distributed Edge logic into transactional Core RPCs.

## SURGICAL FILES

### Current only

- `Current/Edge_Functions/complete-loading`
- `Current/Edge_Functions/unload-runsheet`
- `Current/Edge_Functions/reopen-loading` only when the lifecycle blocker is corrected under the same responsibility matrix.

### Database

- `supabase/migrations/20260814_task028_loading_unloading_atomic_core_final.sql`

### Original

Untouched and immutable.

### Production

No DDL, data mutation, or Edge deployment is permitted from this branch.

## BACKORDER LEDGER

`public.fulfillment_backorders` is a durable fulfillment ledger, not an automatic child customer Order. It preserves original order, original order detail, originating Runsheet, remaining quantity, and lifecycle status.

## ACCOUNTING

No `journal_entries` or `journal_lines` are created by Loading, Unloading, or the new inventory transfer boundary. COGS remains a separate final-sale/delivery concern.

## ACCEPTANCE GATE

The branch is not Runtime-accepted until:

- responsibility mapping is complete;
- event-level idempotency is statically verified;
- lifecycle compatibility is resolved;
- staging migration executes successfully;
- the full test matrix passes;
- no Production or Original mutation has occurred.
