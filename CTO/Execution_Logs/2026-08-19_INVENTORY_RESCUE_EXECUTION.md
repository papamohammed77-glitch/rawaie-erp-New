# RAWAEA ERP — Inventory Rescue Execution

**Execution date:** 2026-08-19
**Environment:** Production `fiilmooggumokxanwiyx`
**Authority:** FOUNDATIONAL SYSTEM CONTRACT 2026-08-19 + Governing Principles + Task Completion Directive

## Production facts verified before change

- PostgreSQL: 17.6.
- Physical stock core: `public.post_stock_movement`.
- Reservations: `reserve_stock` / `release_stock_reservation` update `allocated_qty` only.
- VAN initialization: `setup_van_stock` is initialization, not a movement engine.
- `items.item_code` is globally unique; item identity remains `item_id` / global `item_code`.
- `stock_branches` is unique by `(branch_id,item_id)`.
- Current Production direct stock writers outside the explicit exceptions above: **0**.
- No user triggers were found writing `stock_branches` or `inventory_log`.

## Drift discovered

Production Edge Functions `complete-return` v23 and `complete-order-delivery` v11 called RPCs that did not exist in Production:

- `complete_return_atomic`
- `complete_order_delivery_atomic`

Both wrappers also derived `company_id` with `app_settings.limit(1)`, which violated the tenant context contract.

## Changes applied

1. Created `erp_operation_registry` for operation-level idempotency and auditability.
2. Created `complete_return_atomic` as the transactional return owner.
3. Created `complete_order_delivery_atomic` as the transactional delivery owner.
4. `complete_return_atomic` posts good-return stock through `post_stock_movement(...,'SalesReturn',...)` only.
5. Runsheet returns update `order_details` as the authoritative fulfillment detail and refresh `run_sheet_details` as the aggregate.
6. Tenant context is derived from authenticated `users.auth_id` in the Edge Functions.
7. Deployed `complete-return` **v24**.
8. Deployed `complete-order-delivery` **v12**.
9. Synchronized the corresponding Current Edge Function source and migration into GitHub.
10. Added audit records through `audit_log` for successful operation executions.

## Current-data checks

- Negative stock / allocated anomalies: **0**.
- Orphan stock items: **0**.
- Orphan stock branches: **0**.
- `run_sheet_details` vs authoritative `order_details` quantity mismatches: **0**.
- Historical `inventory_log` entries outside the current closed movement vocabulary: **136**.
  These were preserved as historical evidence rather than rewritten. They consist of legacy `POS_Sale`, `VoidInvoice`, and `StockTake` entries. They are not current physical writers.

## Governance decision on legacy inventory logs

Legacy inventory logs are evidence of earlier system behavior. They were not silently relabeled because doing so would alter historical evidence and could fabricate a false current reconciliation. Current writers are constrained to the canonical movement vocabulary through `post_stock_movement`.

## Closure target

The architectural closure criterion for the physical stock writer was verified as:

`Physical Writers outside post_stock_movement = 0`.

The remaining legacy log vocabulary is classified as historical evidence and is not a live writer.
