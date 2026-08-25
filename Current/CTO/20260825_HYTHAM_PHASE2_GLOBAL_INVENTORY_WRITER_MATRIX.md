# RAWAEA ERP — PHASE 2 HYTHAM GLOBAL INVENTORY WRITER MATRIX

Date: 2026-08-25
Role: Hytham
Authority: Production PostgreSQL > Current main > Current CTO evidence > historical sources > reports
Production: SMART ERP / fiilmooggumokxanwiyx

## 1. Fresh Production Baseline

Production was re-queried before this Phase 2 sweep.

- Companies: 1
- Company: `00000000-0000-0000-0000-000000000001`
- Stock rows: 20
- Inventory log rows: 3
- Stock vouchers: 0
- Orders: 0
- Purchase Orders: 0
- Runsheets: 0
- Treasury: 1
- COA: 0

## 2. Immutable Contract

```text
Physical Movement
    -> post_stock_movement
    -> stock_branches + inventory_log

Reservation
    -> reserve_stock / release_stock_reservation
    -> allocated_qty only
```

No parallel Physical Stock engine is authorized.

## 3. Direct Writer Sweep Result

Production `pg_proc` definitions were searched for direct:

- INSERT/UPDATE/DELETE on `stock_branches`
- INSERT/UPDATE/DELETE on `inventory_log`

Result:

### Canonical Physical Writer

`post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text,text)`

This function directly mutates Physical Stock and writes `inventory_log`.

### Initialization-only writer

`setup_van_stock(uuid)` inserts zero-balance `stock_branches` initialization rows for a VAN branch and does not write `inventory_log`.

Classification: INITIALIZATION, not Physical Movement.

### Reservation writers

`reserve_stock(uuid,uuid,uuid,numeric)`

`release_stock_reservation(uuid,uuid,uuid,numeric)`

They mutate `allocated_qty` only and do not create physical movements.

### Result

No second Production Physical Stock engine was found in the public PostgreSQL function catalog.

## 4. Trigger Sweep

Non-internal triggers were inspected for references to `stock_branches` / `inventory_log`.

No trigger writer was found that creates a parallel Physical Stock mutation path.

## 5. Closure Unit Matrix

| Closure Unit | Production Core | Direct Physical Writer Outside Core | Reservation | Inventory Log | Current Result |
|---|---|---|---|---|---|
| Manual Voucher | `post_manual_stock_voucher_atomic` / `send_stock_voucher_atomic` | None found | N/A | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Purchase Receiving | `receive_purchase_atomic` | None found | N/A | through `post_stock_movement` | READY FOR UNIT REVIEW |
| POS | `save_sales_invoice_atomic` | None found | N/A | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Van Sales | Sales Core + `post_stock_movement` | None found | N/A | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Returns | `complete_return_atomic` | None found | No new physical reservation | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Loading | `complete_runsheet_loading` | None found | consumes reservation according to movement contract | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Unloading | `complete_runsheet_unloading` | None found | operational transition only | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Reopen Loading | `complete_runsheet_reopen_loading` | None found | N/A | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Inventory Adjustment | `post_inventory_adjustment_atomic` | None found | N/A | through `post_stock_movement` | READY FOR UNIT REVIEW |
| Picking | `complete_runsheet_picking` | None found | `reserve_stock` | No inventory movement | READY FOR UNIT REVIEW |

## 6. Tenant / Item Identity

Production branches validate company ownership at movement boundaries.

`item_code` is globally unique in the current Production schema and must not be reinterpreted as company-scoped.

`post_stock_movement` currently validates item identity by UUID existence; downstream consumers also validate their submitted item identity where required.

No company-scoped reinterpretation was introduced.

## 7. Idempotency / Core Canary

A controlled Production SQL transaction was executed against an existing stock row:

- `InventoryIncrease`, quantity 1
- idempotency key: `PH2-CANARY-0001`
- same call executed twice
- duplicate path observed on the second call
- temporary inventory_log count = 1 inside transaction
- transaction rolled back

No test residue was retained.

This proves the central writer's local transaction/idempotency behavior at SQL level. It does not prove authenticated HTTP E2E or two-session concurrency.

## 8. Legacy / Residual Inventory Functions

The following remain catalogued and require consumer/edge lineage review before any retirement:

- legacy `post_stock_movement` overload
- legacy `complete_runsheet_picking` overload
- legacy manual-voucher V2 surfaces where still deployed/reachable

No legacy capability is retired by this matrix alone.

## 9. Phase 2 Global Writer Discovery Status

`GLOBAL WRITER DISCOVERY = SUBSTANTIVELY VERIFIED`

`PHYSICAL WRITERS OUTSIDE post_stock_movement = 0`

subject to the remaining source/deployment/HTTP runtime evidence gates.

## 10. Not Yet Closed

- exact deployed Edge version/hash mapping for every inventory consumer;
- exhaustive Current Git ↔ Production source parity for every consumer;
- authenticated HTTP E2E;
- duplicate HTTP proof per critical writer;
- two-session concurrency proof;
- individual closure-unit runtime evidence;
- legacy retirement evidence.

## 11. Phase 2 Next Unit

`MANUAL VOUCHER`

The next step is a dedicated closure record for:

- SEND
- RECEIVE
- DirectSale
- DirectReturn
- Transfer
- partial receive
- Consumer → Edge → Core → inventory_log
- company/item identity
- operation/idempotency
- production runtime proof.

No unrelated domain is to be mixed into that closure unit.
