# ARCHITECTURE AND BUSINESS CONTRACT EVOLUTION

## Governing architecture
ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution.

UI is an interface; Edge Functions are business capabilities; PostgreSQL Core owns business logic and atomic state transitions. Duplicate business logic is a defect. This is codified in the active Architecture Constitution. fileciteturn205file0

## Inventory contract
- `stock_branches.qty` = Physical Stock.
- `stock_branches.allocated_qty` = Reservation.
- `available_qty` = derived availability; if generated, never write directly.
- `inventory_log` = posted movement history.
- `post_stock_movement(10)` = central physical movement boundary.
- `reserve_stock` / `release_stock_reservation` = reservation path only.

## Fulfillment contract
orders → order_details (authoritative detail) → runsheets → Picking → Reservation → Loading MAIN→VAN → Delivery/Van Sales/Return → Unloading VAN→MAIN where applicable. fileciteturn228file0

## Custody contract
Vehicle = mobile stock container/mobile branch/physical operating unit. Representative/Driver = accountable custodian/financial responsibility holder. Vehicle identity != representative identity. DirectSale = MAIN→VAN custody loading; VanSale = VAN→Customer; DirectReturn = VAN→MAIN; SupplierReturn = Branch/Warehouse→Supplier. fileciteturn202file0

## Picking contract
Start Picking: authenticated user context → company-scoped runsheet → Open/Confirmed→Picking. No physical stock movement at start.
Complete Picking: Picking → reservation via `reserve_stock` → order_details qty_picked → derived runsheet detail sync → Picked. No physical stock decrement merely because of picking.

## Loading contract
Loading = MAIN→VAN. Loading consumes reservation and posts physical movement through central engine. Loading is not COGS by itself.
Reopen reverses the prior loading movement, preserves `qty_loaded`, and starts a new loading cycle identity. Reload uses the new cycle.
Unloading = VAN→MAIN exact inverse where applicable.

## Manual Voucher contract
Draft→Sent→Receive/Partial Receive→Completed. Cancel is controlled state transition. Physical SEND/RECEIVE converge on central stock engine.

## Accounting boundary
Accounting is a separate domain. Inventory events feed accounting; accounting must not invent inventory truth. Journal ownership/posting contract remains open in the 2026-08-21 readiness registry. fileciteturn227file0
