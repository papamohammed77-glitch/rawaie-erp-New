# CURRENT SOURCE MAP

## UI
- `PWA/warehouse/vouchers.html` — Manual Stock Vouchers UI — SHA `b0a6d31c787b096a8d6a25b4e9aeb1e99c9d6504`.
- `PWA/sales/van-sales.html` — Van Sales UI — SHA `445dff4217fbf4a82f333fa716bba5d74def7680`.

## Current Inventory Edge
- `Edge_Functions/current/inventory/send-stock-voucher.ts` — SHA `f2f36f7c3c186eb8f9af51d8bdfd2adf2e7a7421`.

## Original inventory functions to preserve for comparison
- `Edge_Functions/original/08_inventory/create-stock-voucher.ts`
- `send-stock-voucher.ts`
- `receive-stock-voucher.ts`
- `complete-stock-voucher.ts`
- `cancel-stock-voucher.ts`
- `receive-purchase.ts`
- `save-inventory-count.ts`
- `start-receiving.ts`
- `reopen-receiving.ts`
- `bulk-stock-adjustment.ts`

## Adjacent functions requiring inventory-impact review
- `complete-loading.ts`
- `unload-runsheet.ts`
- `complete-return.ts`
- `save-sales-invoice.ts`
- `update-driver-ledger.ts`

## Current SEND migration
- `supabase/migrations/20260808_send_stock_voucher_atomic.sql` — SHA `cece154cd805a596607626df862a7d912c3ecb0c`.
- It defines `send_stock_voucher_atomic(...)`, used by the current `send-stock-voucher.ts`.

## Important reconciliation point
The later manual-voucher candidate path uses `post_manual_stock_voucher_atomic(...)`. The current `send-stock-voucher.ts` captured above still calls `send_stock_voucher_atomic(...)`. This is a real implementation-transition fact and must not be silently treated as completed migration.

## Historical project context
The source repository also contains 71-function API documentation, 26-PWA project maps, original Edge Functions, historical batch reports, a master handover and Van Sales analysis. These are referenced by source path and must be classified historical unless independently reconciled.
