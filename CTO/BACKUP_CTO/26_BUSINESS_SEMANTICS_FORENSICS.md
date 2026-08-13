# 26 — BUSINESS SEMANTICS FORENSICS

## Classification rule
Historical meaning is separated from current owner decision and Production truth.

## Runsheet
Historical business model: one operational journey groups orders for field execution. `runsheets` carries driver/vehicle and stage responsibility.

## Six quantities
Historical `order_details` is the primary record for the six operational quantities. `run_sheet_details` is a projection/aggregation.

## Vehicle / Driver
Historical material associates `runsheets.vehicle_id` with the physical vehicle and `runsheets.driver_id` with the assigned driver. Current CTO memory explicitly strengthens this into `Vehicle ≠ Driver` and treats the vehicle as a mobile stock container and the representative as custodian.

Classification: `CURRENT OWNER/CTO MEMORY` for the separation rule; historical repository confirms separate fields.

## DirectSale
Current owner-confirmed contract: `MAIN → VAN` and it represents stock issue into mobile custody, not final customer sale.

Historical sources contain stock-voucher/van-sales behavior but do not alone override the current owner contract.

Classification: `CURRENT CONFIRMED`; historical evidence = supporting context only.

## VanSale
Current contract: `VAN → CUSTOMER`.
Historical `van-sales.html` clearly represents customer/order/cart operation in a mobile vehicle context, but historical UI alone is not proof of the exact current stock mutation topology.

Classification: `CURRENT BUSINESS CONTRACT` + `HISTORICAL UI SUPPORT`.

## DirectReturn
Current memory records `VAN → MAIN`, while current reconciliation records also contain unresolved custody semantics.

Classification: `CONFLICT / GAP-002` until owner/evidence reconciliation is explicit.

## SupplierReturn
Historical workflow identifies supplier return through stock-voucher behavior. Current memory distinguishes it from DirectReturn.

Classification: `BUSINESS SEMANTICS PRESERVED`, exact Production implementation requires evidence.

## Loading
Historical workflow: preparation allocates/reserves stock; loading is the first physical stock deduction in the documented model.

## Unloading
Historical workflow: unload returns stock from the run into inventory. Exact current Production topology remains a current-stage evidence question.

## Partial Receive
Historical purchasing workflow supports partial receiving. Current CTO memory separately identifies idempotency as an unresolved domain property.

Classification: `HISTORICAL BEHAVIOR CONFIRMED`; `CURRENT IDEMPOTENCY = UNKNOWN/GAP`.

## Settlement
Historical workflow closes the field journey and records driver shortage/liability. Current architecture treats accounting/ledger effects as downstream controlled domains.

## Customer Collection
Historical delivery flow records `amount_paid` and customer ledger/accounting effects. Exact current Production posting path requires current deployed evidence.

## Driver Ledger / Liability
Historical documentation distinguishes driver liability from vehicle identity. Current memory treats representative as custodian/accountability holder.

## Vehicle Account
Historical database documentation identifies vehicle tracking but does not establish Vehicle as the accounting owner of custody. Current owner memory explicitly prevents this conflation.

## Business semantic conflicts requiring owner/evidence handling
1. DirectReturn exact current custody semantics.
2. Partial Receive idempotency.
3. Historical UI order submission versus current VanSale stock contract.
4. Historical direct stock-voucher behavior versus current centralized movement architecture.

## Safe rule
When historical behavior conflicts with current owner decision, preserve the historical record and do not silently rewrite it. Current execution follows the active owner decision only after Production evidence confirms the implementation boundary.
