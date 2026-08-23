# INVENTORY MEMORY TRACK

## CURRENT SNAPSHOT
2026-08-23 03:41:38.004558 UTC

## CORE CONTRACT
`PHYSICAL MOVEMENT → post_stock_movement → stock_branches + inventory_log`

`reserve_stock / release_stock_reservation → allocated_qty only`

## CURRENT FORENSIC RESULT
Production SQL function sweep found:
- `post_stock_movement(10 args)` performs physical stock UPDATE/INSERT and inventory_log INSERT.
- `reserve_stock` / `release_stock_reservation` only change allocation state.
- `setup_van_stock` initializes stock rows.
- No trigger directly mutates physical stock or inventory_log.

Therefore:
**Physical Writers outside post_stock_movement = 0 for the current inspected Production surface.**

## CURRENT DATA
- stock_branches = 26
- inventory_log = 3
- negative physical stock: NOT OBSERVED in current sweep
- negative allocation: NOT OBSERVED in current sweep
- over-allocation: NOT OBSERVED in current sweep
- stock vouchers: 0

## HISTORICAL WRITER CLOSURE LINE
Central inventory migrations include the 14–21 August rescue lineage, later tenant/item identity corrections, legacy overload retirement, target-row auto-init, DirectSale target correction, and legacy manual V2 disablement.

## MANUAL VOUCHER
Current real lifecycle: Transfer / DirectSale / DirectReturn / SupplierReturn.
Scrap/Adjustment remain Adjustment Engine operations.

## ITEM / COMPANY IDENTITY
Live `items.item_code` is globally UNIQUE. Therefore current identity is `item_id` + unique item_code, while branch/company scope belongs to branch and operation context.
Do not retroactively classify old cross-company rows from earlier snapshots as current corruption without fresh provenance analysis.

## CURRENT LEGACY DEBT
Some legacy PostgreSQL functions still exist as objects. Several application execution grants were removed. Object existence is not equivalent to active writer capability. Retirement/deletion remains a governance-classification task.

## INVENTORY-SPECIFIC OPEN ITEMS
- Full provenance registry for historical inventory-log snapshots (56 → 62 → 3) is still required.
- Complete deployment lineage for every inventory Edge artifact remains open.
- Independent-session concurrency proof outside tested paths remains open.
- Browser/runtime E2E for critical inventory PWAs remains open.

## CLOSURE STATEMENT
Inventory physical writer centralization is **CURRENTLY VERIFIED**. This does not authorize calling the ERP globally closed.