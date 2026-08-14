# 31 — STAGE-28 OPERATIONAL MEMORY

## Status
Owner-confirmed business semantics for `STAGE-28 — Loading / Unloading Core`.

## 1. Full operational lifecycle

### Order branch
`Order -> Runsheet -> Picking/Preparation -> Loading -> Loaded -> Delivery -> Delivered`

### Emergency branch
`Loaded -> Emergency Unloading -> Warehouse restored -> Picked`

### Customer-return branch
`Delivery Order-by-Order -> refusal/return outcomes -> qty_refused / qty_returned`

### Separate Van-custody branch
`DirectSale (MAIN -> VAN) -> VanSale (VAN -> Customer) -> DirectReturn (VAN -> MAIN)`

## 2. System responsibilities

### Master system (`main.html`)
Owns planning/master data and administrative coordination:
- orders
- runsheets
- vehicle assignment
- driver/representative assignment
- company/system settings
- master data

### Warehouse applications
Own physical preparation workflow:
- picking
- preparation
- loading
- emergency unloading
- warehouse-side execution

### Delivery application
Operates a loaded Runsheet and executes delivery **Order-by-Order**.

### Van-sales application
Operates mobile Van custody and customer sales from that custody.

### Stock voucher application
Operates manual stock movements that are outside the automatic Runsheet/Delivery workflow.

## 3. Loading definition
Loading is the physical loading of the prepared Runsheet goods into the route vehicle after Picking/Preparation.

Loading is NOT:
- DirectSale
- a manual voucher
- a customer sale
- a customer return

The implementation must preserve `qty_picked` separately from `qty_loaded`.

## 4. Unloading definition
Unloading is an emergency/full operational reversal of a fully loaded Runsheet before delivery when the route vehicle cannot continue.

Requirements:
- input Runsheet must be `Loaded`;
- reverse the Loading effect in full;
- restore warehouse state;
- reset loaded quantities appropriately;
- return Runsheet to `Picked`;
- do not treat this as Customer Return;
- do not use DirectReturn semantics.

## 5. Delivery definition
Delivery begins only after Loading completes.

The Delivery application loads the Runsheet context and processes Orders one by one.

Per-order outcomes are tracked through:
- `qty_delivered`
- `qty_refused`
- `qty_returned`
- `driver_liability`

Completion of one Order does not mean the entire Runsheet is delivered.

## 6. Returns definition
Customer returns are order-granular.

Example:
`RS-1 -> Order A Delivered -> Order B Returned -> Order C Refused`

This is fundamentally different from:
`RS-1 Loaded -> Vehicle emergency -> Full Unloading -> Picked`

## 7. Quantity contract
Current established meanings:
- `qty` = original requested quantity.
- `qty_picked` = quantity prepared/picked.
- `qty_loaded` = quantity physically loaded.
- `qty_delivered` = quantity delivered.
- `qty_refused` = quantity refused by customer.
- `qty_returned` = quantity returned during delivery cycle.
- `driver_liability` = representative/driver accountability.

Do not introduce a second name such as `qty_ordered` into the active model unless a new authoritative owner decision explicitly requires it.

## 8. Vehicle / representative
The vehicle is the route operating unit/mobile container.
The representative/driver is the custody/accountability holder.

`runsheets.vehicle_id` and `runsheets.driver_id` are separate identities.

A representative may change vehicles. Any custody transfer must be explicit, auditable and inventory-safe.

## 9. Stock architecture boundary
`DirectSale` is a manual custody movement.
`Loading` is an automatic Runsheet/Delivery workflow.

They must not create an accidental duplicate stock deduction for the same goods.

The final Loading implementation must be reconciled with:
- `stock_branches.qty`
- `stock_branches.allocated_qty`
- `inventory_log`
- central stock movement RPC
- Runsheet quantities
- Order quantities
- audit trail

## 10. Golden fixture
`RS-1` is the designated experimental fixture for Stage-28.

Known facts:
- vehicle: `VEH-92yrzb`
- vehicle id: `70e5d809-0505-4e60-b317-feff6e799127`
- representative: `van-sales@rawaea.com`
- driver id: `a86726d9-d687-4113-a9e2-5f90f4bdb4fa`
- company: `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- MAIN branch: `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
- mobile branch: `VAN-VEH-92yrzb` / `dbdef0b7-0909-4f71-a367-30c61d021286`

No Loading or Unloading test should use real production business data when a clean fixture can be used.

## 11. Stage-28 acceptance
Stage-28 is not complete until the full path is proven:
1. clean Runsheet
2. Picking/Preparation
3. Loading
4. Loaded state
5. stock/inventory evidence
6. delivery boundary
7. emergency Unloading
8. reverse stock evidence
9. Runsheet returns to Picked
10. no duplicate inventory movement
11. no lost quantity semantics
12. no unauthorized accounting duplication
13. audit evidence preserved
