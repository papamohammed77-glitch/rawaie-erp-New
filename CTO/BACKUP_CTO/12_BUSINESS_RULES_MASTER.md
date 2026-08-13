# BACKUP CTO 12 — RAWAEA BUSINESS RULES MASTER

## Ownership and custody
1. Vehicle is a mobile inventory container/mobile branch.
2. Representative is the accountable custodian.
3. Representative responsibility covers inventory, sales value, and collection exposure for market receivables.
4. Representative is not permanently identified by vehicle.
5. Vehicle assignment may change operationally.
6. Reassignment must be controlled through inventory/custody procedures; never silently zero a vehicle's stock.
7. Accounts for vehicles, representatives, customers and related master data are created by the parent/master system.

## Vehicle lifecycle
- A vehicle record represents the physical operating unit.
- A vehicle receives a unique code such as `VEH-92yrzb`.
- The vehicle code is not generated from representative email.
- The mobile branch is derived/associated with vehicle identity under controlled rules.

## Inventory semantics
- MAIN holds warehouse stock.
- VAN/mobile branch holds vehicle custody stock.
- `qty` is physical stock.
- `allocated_qty` is reserved/allocated stock, not a movement.
- `available_qty` is derived in current Production evidence and may be generated.

## DirectSales
`DirectSale` = issue stock from warehouse MAIN to direct-sales vehicle/representative custody.

It is not a final sale from warehouse.

Topology:
`MAIN → VAN`

Expected stock effect:
`MAIN - qty`
`VAN + qty`

## VanSale
`VanSale` = final sale from vehicle custody to customer.

Topology:
`VAN → CUSTOMER`

Customer financial exposure must be handled by the appropriate sales/accounting contract. Do not collapse vehicle stock and customer receivable into one entity.

## DirectReturn
`DirectReturn` = vehicle custody returned to MAIN.

Topology:
`VAN → MAIN`

## SupplierReturn
`SupplierReturn` = warehouse/branch stock returned to supplier.

Topology:
`Branch → Supplier`

## Branch transfer
Regular Transfer semantics are branch-to-branch movement. Source and target must be distinct and explicit.

## Manual Voucher lifecycle
Draft → Sent → Received/partial Received semantics → Completed.

Cancellation is a controlled state transition and must not erase movement history.

## UI behavior
- From/To branches are selected from controlled lists.
- Vehicle selection belongs to warehouse execution but is coordinated with Fleet/Movement administration.
- Representative selection should use smart search/dropdown behavior matching Gold applications.
- No UI creates new business truth independently of Core.

## Accounting/ledger implication
The representative's custody and customer receivables are distinct concepts. A customer's debt is affected by customer transactions/collections, not by simply changing vehicle identity.

## Explicit owner decision
DirectSale means vehicle/representative stock issue, not warehouse direct sale.
