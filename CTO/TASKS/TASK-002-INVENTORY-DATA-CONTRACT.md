# TASK-002 — INVENTORY DATA CONTRACT

## Objective
Freeze the factual Production contract for `stock_branches`, `inventory_log`, `allocated_qty`, and their constraints/indexes/relations before any implementation change.

## Evidence Reviewed
- `Inventory/Manual-Vouchers/01-CONTRACT.md`
- `Evidence/Production/02-inventory-log-contract.csv`
- `Evidence/Production/07-stock-voucher-indexes.csv`
- `CTO/05_TRUTH_RECONCILIATION.md`
- `Inventory/02-EVIDENCE-GAPS-AND-SQL.md`

## 1. `stock_branches`

Captured Production contract proves the following fields:

`id, branch_id, item_id, qty, allocated_qty, available_qty, updated_at`

### Confirmed meaning
- `qty` = physical stock quantity recorded for the branch/item row.
- `allocated_qty` = reserved/allocated quantity and therefore NOT itself a stock movement.
- `available_qty` = available quantity represented by the current contract; the reviewed atomic path treats availability as `qty - allocated_qty`.

### Important boundary
The exact database implementation of `available_qty` (generated column, stored value, trigger-maintained value, or other mechanism) is NOT captured sufficiently in the persisted evidence currently available.

Therefore its exact generation mechanism is **NOT ASSUMED**.

## 2. `inventory_log`

Production evidence proves:

`id, company_id, log_code, movement_date, voucher_id, item_id, item_code, item_name, movement_type, qty, reference, user_email, created_at`.

The captured contract explicitly confirms that `branch_id` is absent. fileciteturn264file0

### Source-of-truth classification
`inventory_log` is the **historical movement/audit record of stock movements**, but it is NOT the authoritative current stock balance.

Current stock balance belongs to `stock_branches`.

## 3. `allocated_qty`

`allocated_qty` belongs to `stock_branches` and represents reservation/custody allocation, not physical movement.

Therefore:

`allocated_qty` ≠ inventory movement

and must not be modified by the stock-movement engine merely because a physical movement occurred.

The reviewed Voucher contract confirms OUT availability is evaluated using `qty - allocated_qty`. fileciteturn267file0

## 4. Source of Truth Matrix

| Value / Fact | Source of Truth | Status |
|---|---|---|
| Physical current branch stock | `stock_branches.qty` | PROVEN |
| Reserved stock | `stock_branches.allocated_qty` | PROVEN |
| Available stock | Contract calculation `qty - allocated_qty` | PROVEN behavior; exact DB implementation UNKNOWN |
| Historical movement record | `inventory_log` | PROVEN |
| Item identity | `items` / `stock_branches.item_id` relationship | Relationship requires dependency-closure evidence |
| Branch identity | `branches` / `stock_branches.branch_id` relationship | Relationship requires dependency-closure evidence |
| Movement classification | `inventory_log.movement_type` | PROVEN column; allowed-value constraint NOT fully captured |

## 5. Constraints / Indexes / Relations

### What is proven
The persisted evidence proves only the captured index:

`stock_voucher_details_pkey` on `stock_voucher_details(id)`.

It does **not** prove the complete index set for `stock_branches` or `inventory_log`. fileciteturn265file0

Likewise, the persisted evidence does not yet provide the complete FK/UNIQUE/CHECK constraint closure for the Inventory tables.

### Therefore
This Task cannot truthfully declare the complete constraints/indexes/relations contract yet.

The required dependency-closure evidence is already documented as `EVIDENCE-015` in `Inventory/02-EVIDENCE-GAPS-AND-SQL.md`. fileciteturn268file0

## 6. Safety Classification

**NO PATCH AUTHORIZED.**

Reason: a Data Contract must not be completed by inference where the exact Production constraints, indexes, generated/default behavior and foreign-key relationships have not been captured.

## Gate

**TASK-002 STATUS: BLOCKED — EVIDENCE GAP ONLY**

The blocking evidence is narrowly defined:

**EVIDENCE-015 — full Production schema/dependency closure**, including the Inventory tables and their related `branches`, `items`, `app_settings`, and `audit_log` tables.

After EVIDENCE-015 is available, this Task can be closed without reopening unrelated investigation.

## Next Action
Obtain **EVIDENCE-015 only**.

Do not request already-known evidence.
Do not modify Production.
Do not design a migration.
Do not infer missing constraints/indexes/relations.
