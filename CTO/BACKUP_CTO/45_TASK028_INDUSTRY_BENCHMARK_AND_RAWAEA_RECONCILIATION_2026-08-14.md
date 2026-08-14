# 45 — TASK-028 INDUSTRY BENCHMARK & RAWAEA RECONCILIATION
## Date: 2026-08-14
## Mode: TARGET DESIGN RESEARCH / NO PRODUCTION MUTATION

## Purpose
Transition TASK-028 from broad evidence acquisition to focused synthesis using:

```text
Production Evidence
+ Owner Contract
+ Historical Behavior
+ Mature ERP/WMS Patterns
= Target Contract Candidate
```

This report does not deploy or modify Production. It distinguishes benchmark evidence from RAWAEA decisions.

---

# 1. ESTABLISHED RAWAEA BUSINESS CONTRACT

These are already-owner-approved and are not reopened here:

- Vehicle != Representative.
- Vehicle is a mobile stock container / mobile branch.
- Representative is custodian/accountability holder.
- DirectSale = MAIN -> VAN custody.
- VanSale = VAN -> Customer.
- DirectReturn = VAN -> MAIN.
- Loading != DirectSale.
- Unloading != Customer Return.
- Runsheet workflow = Order -> Runsheet -> Picking/Preparation -> Loading -> Loaded -> Delivery Order-by-Order -> Delivered.
- Emergency Unloading = Loaded -> Full Unloading -> Picked.
- Customer returns remain order-granular during Delivery.

---

# 2. PRODUCTION FACTS RELEVANT TO TARGET DESIGN

Confirmed directly from connected Production evidence:

- `complete-picking` deployed v10 reserves stock through `reserve_stock`, records a Picking log, updates `order_details.qty_picked`, and transitions the Runsheet through a logical status lock. It does not itself transfer stock from MAIN to VAN.
- `complete-loading` deployed v9 currently decrements MAIN `stock_branches.qty`, updates `allocated_qty`, writes `inventory_log` movement type `Loading`, updates Runsheet/Order quantities, posts accounting, and creates Backorder effects.
- `unload-runsheet` deployed v4 currently restores MAIN stock, logs `Unloading`, clears loaded quantities, and returns the Runsheet to `Picked`.
- `post_stock_movement` exists in Production with row locking but currently does not accept `Loading` or `Unloading`.
- RS-1 Production snapshot has MAIN stock present and VAN stock at zero for the observed fixture items before Loading.
- `order_details` -> `sync_run_sheet_details()` is a database trigger boundary; manual dual writes require explicit justification.

These are CURRENT DEPLOYED BEHAVIORS, not automatically the target contract.

---

# 3. INDUSTRY BENCHMARKS

## 3.1 SAP EWM — Loading is not inherently identical to Goods Issue

SAP EWM documents Loading and Unloading as warehouse execution steps. Depending on configuration, Loading can be a status-triggering activity or involve warehouse-task execution; Goods Issue can be posted at different points, including after loading.

Source:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9832125c23154a179bfa1784cdc9577a/14c8cb53ad377114e10000000a174cb4.html

Implication for RAWAEA:

`Loading != automatically COGS/GI`

The event must be defined according to the stock ownership/location model.

## 3.2 SAP — Outbound process separates warehouse work from final goods issue

SAP describes outbound processing as sales document -> transportation/warehouse processing -> loading -> goods issue / truck departure. Picking, packing and loading can therefore precede the financial/physical Goods Issue boundary.

Sources:
https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/9832125c23154a179bfa1784cdc9577a/7ce32e84032340e79b8e3bb9dfbc7f7b.html
https://help.sap.com/docs/SAP_EXTENDED_WAREHOUSE_MANAGEMENT/3d97bec9bf1649099384bb8167df3cf2/c4c8cb53ad377114e10000000a174cb4.html

Implication:

Loading is a workflow step; its inventory/accounting effect depends on the modeled stock boundary.

## 3.3 SAP / Dynamics / Odoo — Internal transfer is a distinct stock operation

SAP documents internal stock transfers as explicit product movements between internal locations/storage areas. Dynamics documents transfer journals/orders as movements between source and destination inventory dimensions. Odoo documents Internal Transfers as explicit source-location to destination-location movements that change on-hand quantity at both locations.

Sources:
https://help.sap.com/docs/PRODUCT_ID/3d97bec9bf1649099384bb8167df3cf2/51cbcb53ad377114e10000000a174cb4.html
https://learn.microsoft.com/en-us/dynamics365/supply-chain/inventory/inventory-journals
https://www.odoo.com/documentation/18.0/applications/inventory_and_mrp/barcode/operations/transfers_scratch.html

Implication for RAWAEA:

If Loading is declared a physical transfer to Vehicle custody, it should behave as a controlled source/target stock movement, not as an isolated MAIN deduction.

## 3.4 SAP — Internal stock transfer is normally not a COGS event

SAP documentation notes that storage-location-to-storage-location stock transfers within the same plant are generally posted without value because the inventory remains under the same valuation context; this is different from a final sale/Goods Issue to a customer.

Source:
https://help.sap.com/docs/SAP_ERP/96bf9ad642cf4b26a29595e3d573fb8c/a464bd534f22b44ce10000000a174cb4.html

Implication for RAWAEA:

If a Vehicle branch is an internal company custody/location, Loading should not independently invent a Cost-of-Goods-Sold journal merely because stock changes branch/location. COGS belongs to the final sale boundary unless RAWAEA has an explicit alternative accounting policy approved by the Owner.

---

# 4. MODEL COMPARISON

| Model | Description | Industry Fit | RAWAEA Contract Fit | Key Risk |
|---|---|---|---|---|
| A | MAIN -> VAN physical movement at Loading | Strong when Vehicle is the receiving internal stock location | **Strong** if Runsheet goods are not already in VAN custody | Must prevent duplication with DirectSale |
| B | Loading changes operational state only; no physical stock movement | Strong in WMS configurations where stock remains at warehouse until later GI | Weak if Vehicle is treated as a true mobile stock container and physical custody begins at Loading | MAIN can continue to show goods physically present after truck departure |
| C | MAIN -> another operational branch/location | Possible | Requires an additional stock topology not currently evidenced | More complexity / new topology |
| D | Reservation -> Loaded state without physical movement | Strong as a fulfillment-state pattern | Possible only if another event owns physical transfer | Requires explicit custody/stock boundary elsewhere |

---

# 5. TARGET CONTRACT CONVERGENCE

## 5.1 Recommended target model

The combined evidence now favors **Model A — Loading as an explicit internal stock movement from MAIN to the assigned Vehicle/mobile branch**, with the following critical qualification:

> Loading is NOT DirectSale.

They are different business events and different references, but they may both create a MAIN -> VAN physical movement for different business purposes.

The system must enforce that the same quantity is not moved twice. A Runsheet item should not also be subjected to a separate DirectSale for the same stock event.

Why this model fits the evidence:

1. Vehicle is explicitly modeled as a Mobile Stock Container / Mobile Branch.
2. Current Production `complete-loading` already decrements MAIN, showing strong legacy intent that Loading is stock-affecting.
3. Historical `complete-loading` also decremented MAIN and `unload-runsheet` restored MAIN.
4. The current VAN branch is a real stock branch with zero baseline in the clean fixture; therefore a proper Loading implementation has a natural target row.
5. Mature ERP/WMS systems support explicit internal source->destination stock transfer patterns.
6. A single MAIN-only decrement is incomplete for a mobile stock container model because it leaves no destination stock record.

Classification:

**TARGET CONTRACT CANDIDATE — HIGH CONFIDENCE, PENDING PRINCIPAL CTO / OWNER APPROVAL**

It is not yet a Production fact.

---

# 6. TARGET LOADING CONTRACT

A successful Loading operation should be logically atomic and perform:

```text
Runsheet status: Loading -> Loaded

For each loaded item:
  MAIN.qty          -= loadedQty
  VAN.qty           += loadedQty
  MAIN.allocated_qty -= min(MAIN.allocated_qty, loadedQty)
  inventory_log      = one auditable Loading movement

Operational quantities:
  order_details.qty_loaded changes
  run_sheet_details.qty_loaded derives through trigger synchronization
```

Important:

- `available_qty` remains generated.
- No direct write to `available_qty`.
- No manual dual-write to `run_sheet_details` if the trigger remains authoritative.
- No independent COGS journal at Loading solely because the stock moved internally.
- Any accounting event must follow the approved accounting boundary.

---

# 7. TARGET UNLOADING CONTRACT

Unloading is the exact operational inverse of Loading for the quantities actually loaded:

```text
Runsheet status: Loaded -> Picked

For each loaded item:
  VAN.qty           -= qty_loaded
  MAIN.qty          += qty_loaded
  inventory_log      = one auditable Unloading reversal movement

Operational quantities:
  order_details.qty_loaded -> 0 for the reversed load
  run_sheet_details.qty_loaded derives through trigger synchronization
```

For partial/exception cases, the inverse must use the exact persisted loaded quantity rather than blindly using ordered quantity.

Unloading is not Customer Return.

---

# 8. QUANTITY INVARIANTS

Required baseline invariants:

```text
0 <= qty_loaded <= qty_picked <= qty

0 <= qty_delivered <= qty_loaded
0 <= qty_refused + qty_returned + qty_delivered <= qty_loaded
```

Where actual RAWAEA behavior intentionally allows a different state, the exception must be documented and approved.

---

# 9. ATOMICITY MODEL

The business transaction should be atomic across the stock-changing portion:

```text
Runsheet lock
+
Validate status / quantities
+
Validate source and target stock
+
MAIN stock mutation
+
VAN stock mutation
+
Allocation release
+
Inventory log
+
Order/run-sheet quantity updates
+
Runsheet state transition
+
Accounting / backorder effects if and only if they are part of the approved Loading boundary
```

The safest implementation shape is a database-side transaction/RPC with row locking, because the current deployed Edge Function performs many sequential calls and can leave partial state if a later call fails.

This is a TARGET architecture decision, not a claim about current Production transaction behavior.

---

# 10. IDEMPOTENCY MODEL

Do not invent a new schema until necessary.

The first target mechanism to evaluate is:

```text
lock runsheet row
require status = Loading
perform all effects in one transaction
set status = Loaded before commit
```

This yields a natural retry guard:

- first successful request commits `Loaded`;
- retry sees `Loaded` and does not repeat the stock event.

However, this alone is insufficient if any side effect can escape the transaction. Therefore the transaction boundary remains mandatory.

If business requirements later demand replayable commands while status can remain Loading, introduce a dedicated operation/event identity only after schema approval.

Classification:

**TARGET CANDIDATE — HIGH CONFIDENCE, REQUIRES IMPLEMENTATION DESIGN REVIEW**

---

# 11. ACCOUNTING BOUNDARY

Industry benchmark strongly supports separating internal stock transfer from final customer COGS recognition.

Therefore the target candidate is:

```text
Loading internal transfer:
NO new COGS by itself

VanSale / final customer sale:
COGS / revenue accounting according to the approved sales contract
```

This removes the current legacy behavior in which `complete-loading` creates a `CostOfGoodsSold` journal simply from loading.

Classification:

**TARGET CANDIDATE — REQUIRES OWNER ACCOUNTING APPROVAL BEFORE CODE CHANGE**

---

# 12. BACKORDER BOUNDARY

Backorder should represent ordered quantity that cannot be fulfilled by the current loading/fulfillment event.

Target candidate:

```text
remaining = qty - qty_loaded
```

But the exact creation event, status, duplicate prevention, and linkage must be approved against the existing sales/backorder business contract before implementation.

Classification:

**TARGET CANDIDATE — NOT YET OWNER-APPROVED**

---

# 13. TRIGGER BOUNDARY

Current Production has:

```text
order_details
    -> trg_sync_run_sheet_details
    -> sync_run_sheet_details()
    -> run_sheet_details
```

Therefore target implementation should update the authoritative `order_details` quantities only once and allow the database trigger to synchronize `run_sheet_details` unless a future owner-approved architecture intentionally changes this boundary.

Manual dual writes are prohibited without explicit justification.

---

# 14. SURGICAL IMPLEMENTATION PLAN — PRE-APPROVAL ONLY

No code is changed by this report.

### Step 1 — Current-only design
Create a database-side atomic Loading operation that:
- locks Runsheet and relevant stock rows;
- validates `Loading` state;
- validates quantity invariants;
- moves stock MAIN -> VAN;
- releases allocation;
- writes one Loading inventory event;
- updates `order_details.qty_loaded`;
- relies on trigger for `run_sheet_details` synchronization;
- handles approved accounting/backorder boundaries;
- commits state `Loaded` atomically.

### Step 2 — Unloading inverse
Create the exact inverse transaction:
- locks Runsheet and VAN/MAIN rows;
- validates `Loaded` state;
- moves VAN -> MAIN using persisted `qty_loaded`;
- writes one Unloading event;
- reverses operational loaded quantities;
- returns Runsheet to Picked.

### Step 3 — Rewire deployed consumers
Only after the new Core contract is approved:
- `complete-loading` becomes a thin capability wrapper around the Core transaction.
- `unload-runsheet` becomes a thin capability wrapper around the inverse Core transaction.
- Legacy direct stock/accounting writes are removed from the capability layer.

### Step 4 — Tests
Required:
- full load
- partial load
- zero load rejection
- insufficient stock
- retry after success
- concurrent double submission
- failure at each intermediate stage
- unload full
- unload after partial load
- repeated unload rejection
- inventory log cardinality
- MAIN/VAN balance conservation
- accounting consistency
- backorder deduplication

### Step 5 — Production Gate
Only after all tests pass and Owner/Principal CTO approves the target contract:
- deploy Current only
- run controlled Production verification
- capture before/after stock and log evidence
- update Implementation Reality Matrix

---

# 15. REMAINING APPROVAL ITEMS

These are now narrow and explicit:

1. Approve Model A as the Loading stock boundary.
2. Approve that Loading internal transfer is not itself COGS.
3. Approve exact Backorder event/linkage semantics.
4. Confirm whether the current Driver/Vehicle custody model requires every Runsheet vehicle to have an active mobile branch before Loading.
5. Confirm whether any operational requirement permits DirectSale and Loading to act on the same physical quantities in one Runsheet.

These are not broad reconnaissance questions; they are implementation authorization decisions.

---

# 16. FINAL STATUS

```text
TASK-027 IMPLEMENTATION REALITY AUDIT = COMPLETE / PARTIAL GOLD
TASK-028 INDUSTRY BENCHMARK           = COMPLETE
TASK-028 TARGET CONTRACT CANDIDATE     = MODEL A — INTERNAL MAIN -> VAN TRANSFER
TASK-028 IMPLEMENTATION                = NO-GO UNTIL APPROVAL
PRODUCTION MUTATION                    = NONE
PRODUCTION DEPLOYMENT                  = NONE
```

## Primary conclusion

The evidence no longer justifies an indefinite discovery loop.

The strongest target candidate is:

```text
Picking = reservation / allocation
Loading = physical internal MAIN -> VAN transfer
VanSale = VAN -> Customer sale
Unloading = exact inverse VAN -> MAIN
```

This preserves the RAWAEA custody model while aligning the stock boundary with mature ERP/WMS transfer patterns.

The target remains a **candidate** until Principal CTO / Owner approval, especially for accounting and backorder boundaries.
