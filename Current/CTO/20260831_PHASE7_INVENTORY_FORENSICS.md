# RAWAEA ERP — PHASE 7 INVENTORY FORENSICS

**Date:** 2026-08-31  
**Phase:** 7 — Inventory / Stock Forensics  
**Status:** CLOSED  
**Production mutation:** None.

## CURRENT STOCK MODEL OBSERVED

`stock_branches` currently has the following columns:

`id, branch_id, item_id, qty, allocated_qty, available_qty, updated_at`.

The schema contains no direct `company_id`; tenant ownership is relational through `branch_id → branches.company_id` and `item_id → items.company_id`.

## CURRENT INVENTORY STATE

Fresh Production snapshot at `2026-08-31T08:46:09.805507Z`:

- `stock_branches`: 20 rows
- physical `qty` total: 31
- `allocated_qty` total: 0
- `available_qty` total: 31
- negative stock rows: 0
- rows where `allocated_qty > qty`: 0
- duplicate `(branch_id,item_id)` keys: 0
- `available_qty != qty - allocated_qty`: 0
- cross-company branch/item stock mismatches: 0

Current active branches observed:

- `BR-01` / الفرع الرئيسي — stock total 26
- `BR-2` / فرع إسكندرية — stock total 5

No VAN branch is present in the current branch dataset, consistent with the current `vehicles = 0` Production count.

## INVENTORY LOG STATE

Fresh snapshot:

- `inventory_log`: 3 rows
- total logged quantity: 3
- all three recorded rows are `VoidInvoice`
- logged item codes are `1001` and `1003`
- no inventory-log item/company mismatches detected.

This is a very small movement history relative to the current stock balance. It is not sufficient by itself to reconstruct the origin of all 31 physical units; historical purchase/opening/seed operations and prior data lifecycle must therefore be traced in later forensic work.

## CANONICAL STOCK ENGINE

Current Production contains `post_stock_movement` with an explicit supported movement-type whitelist:

`PurchaseIn, TransferOut, TransferIn, POSSale, VanSale, DirectSale, SalesReturn, DirectReturn, SupplierReturn, InventoryIncrease, InventoryDecrease, Loading, Unloading`.

The current engine validates source/target branch company membership, locks relevant stock rows, enforces available/reserved constraints, supports idempotency-key conflict detection, updates stock balances, and inserts `inventory_log` records.

For `Loading`, the engine decreases both `qty` and `allocated_qty` from the source and increases target `qty`. For `Unloading`, it decreases source `qty` and increases target `qty`.

## RESERVATION VS MOVEMENT

The current architecture keeps reservation separate from physical movement:

- `reserve_stock` / `release_stock_reservation` operate on reserved quantity.
- `post_stock_movement` performs physical movement.

This separation matches the required conceptual model: reservation is not a physical stock movement.

## CURRENT LOADING CONTRACT

`complete_runsheet_loading` validates company/runsheet/vehicle/loading context and calls `post_stock_movement` for each loaded item. It also checks that loaded quantity does not exceed picked capacity and updates the order-detail fulfillment quantities.

Therefore, the current loading path has a clear physical-stock authority boundary.

## INVENTORY FORENSIC FINDINGS

### Clean invariants

The current Production balance model is internally consistent at snapshot time. No negative balances, duplicate stock keys, available/physical mismatches, or branch/item tenant mismatches were observed.

### Open forensic questions

1. The 31 current stock units cannot be fully attributed from only 3 current inventory-log rows. Historical inventory initialization/seed/opening paths must be reconstructed.
2. No allocated stock exists now, so reservation behavior cannot be validated from a live non-zero reservation case without creating test data in a safe environment.
3. No vehicle/VAN stock exists now, so current VAN transfer/sale behavior cannot be validated against live data; only source/RPC contract analysis is currently possible.
4. The full writer matrix must still verify that no non-canonical path updates `stock_branches`, `inventory_log`, or allocation fields directly.

## INVENTORY SECURITY INTERSECTION

Current `stock_branches` RLS uses the current user's company context through the parent `branches` row and requires warehouse/runsheet/reports permission. This is materially stronger than a bare authenticated policy.

However, because tenant isolation for `stock_branches` is relational, every write path and every future schema change must preserve the branch/company relationship and must not permit orphan or cross-tenant references.

## EXIT GATE

`PHASE 7 CLOSED`

Current physical stock, reservation state, inventory log, branch relationships, and canonical stock engine were directly inspected. Invariants are clean at snapshot time, while historical stock provenance and complete writer exclusivity remain later-phase obligations.
