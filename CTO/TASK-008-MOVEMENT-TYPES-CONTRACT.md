# TASK-008 — Movement Types Contract

## Status
**COMPLETE / GO TO TASK-009**

## Objective
Freeze the movement-type vocabulary that is actually proven by the current Production Voucher/RPC contract, while preserving historical types without promoting them to current Production truth.

## Production Evidence
The captured Production `create_manual_stock_voucher_atomic` accepts exactly these Voucher `type` values:

- `Transfer`
- `DirectSale`
- `DirectReturn`
- `SupplierReturn`

The captured `post_manual_stock_voucher_atomic` writes `inventory_log.movement_type` from `v_voucher.type`, so for this Voucher path the movement type is the Voucher type itself.

The captured `send_stock_voucher_atomic` also writes `movement_type = v_voucher.type` for its SEND movement.

## Current Production Voucher Movement Types

| Type | Current Production support | Physical effect | Custody meaning |
|---|---|---|---|
| `Transfer` | PROVEN | SEND source qty ↓; RECEIVE target qty ↑ | Branch → Branch |
| `DirectSale` | PROVEN | SEND source qty ↓ | Current RPC represents target as Branch; Van/driver custody is separate unresolved Target semantics |
| `DirectReturn` | PROVEN | RECEIVE target qty ↑ | Current RPC represents source/target as Branch; Van/driver return semantics unresolved Target |
| `SupplierReturn` | PROVEN | SEND source qty ↓ | Branch → Supplier |

## Historical Voucher Types
The historical Manual Voucher architecture document additionally names:

- `Scrap`
- `Adjustment`

These are **HISTORICAL / NOT CURRENT PRODUCTION CREATE CONTRACT**, because the captured Production Create RPC rejects any `p_type` outside the four supported values above. fileciteturn222file0

## Critical Distinction
The contract above is the **proven Manual Voucher movement-type vocabulary**.

It does not claim that these four values exhaust every possible `inventory_log.movement_type` produced by every Inventory, Purchasing, Loading, Delivery, Return, POS, or Van Sales path. The captured Production Inventory Data Contract explicitly states that the database does not enforce an allowed-value CHECK/ENUM for `inventory_log.movement_type`. fileciteturn232file0

Therefore:

- No new movement type is invented here.
- No database ENUM/CHECK is added.
- Historical values are not promoted to current Production support.
- Other non-Voucher movement types remain outside this contract unless separately proven from current Production definitions.

## Source-of-Truth Rule
`inventory_log.movement_type` is the historical classification field for a movement record, but the current Production schema does not enforce its allowed values at database level. The application/RPC contract therefore remains the authoritative classification boundary for the captured Voucher path. fileciteturn232file0

## Gate
**TASK-008 CLOSED / GO.**

The Manual Voucher movement-type contract is frozen without inference. Any broader universal Inventory movement vocabulary is deliberately left to later Inventory Core reconciliation if and where additional current Production consumers prove additional values.

## Next Task
**TASK-009 — Partial Receive Contract**
