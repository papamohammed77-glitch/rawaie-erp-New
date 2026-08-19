# RAWAEA ERP — 2026-08-19 Forensic Status

## Scope
Fresh source-first investigation of:
- `Current/PWA/main.html`
- `Current/PWA/vouchers.html`
- `rawaie-erp-review/Architecture/الأذونات المخزنية اليدوية.md`
- Production Supabase state and deployed RPC/Edge definitions already verified during the sweep.

## Proven current facts
1. `main.html` exposes a warehouse submenu named `الأذونات المخزنية` with: Transfer, DirectSale, DirectReturn, SupplierReturn, and Vouchers display. It also exposes filtering for automatic movements and Adjustment.
2. `main.html` currently creates manual vouchers through `create-stock-voucher`, then immediately calls `send-stock-voucher` for the operational flow.
3. `vouchers.html` is a separate manual-voucher UI. It lists only `source=Manual` or `type=Adjustment`, and its create UI currently exposes only Transfer, DirectSale, DirectReturn, SupplierReturn.
4. `vouchers.html` create UI does not expose from/to branch/vehicle/supplier selection, mandatory reference, Scrap, or Adjustment creation. It hardcodes `fromId='MAIN'` and empty `toId` in the create call.
5. `vouchers.html` supports Draft -> Send and Sent -> Receive, but no visible edit, cancel, complete, or partial-receive workflow. Details are read-only.
6. Historical/manual-voucher architecture defines six manual types: Transfer, DirectSale, DirectReturn, SupplierReturn, Scrap, Adjustment, with type-specific lifecycle rules and inventory/accounting effects.
7. Production `post_manual_stock_voucher_atomic` routes stock mutations to `post_stock_movement`; this is not a parallel Physical Stock engine.
8. The Production schema has `items.item_code` as a UNIQUE key, therefore item_code is globally unique in the deployed schema; item identity is safer through `item_id`/globally unique `item_code` than company-scoped lookup for the current contract.
9. Production `receiving.operation_id` is UNIQUE. A correct purchase-receive retry contract therefore needs stable operation identity; generating a new operation id on every retry is insufficient.
10. Several historical/legacy manual-voucher functions still contain company-context checks based on `app_settings LIMIT 1`; these are Tenant-drift risks even where they do not independently mutate stock.

## Closure status
Mandatory seven-writer inventory sweep:
- `send_stock_voucher_atomic`: Physical movement centralized through `post_stock_movement`; Production definition and deployed Edge wrapper verified. FULL CLOSURE for stock-writer responsibility.
- `receive_stock_voucher_atomic` / current manual receive path: current Edge calls `post_manual_stock_voucher_atomic`, which calls `post_stock_movement`. FULL CLOSURE for stock-writer responsibility; workflow completeness is separate.
- `receive_purchase_atomic`: partially repaired for idempotency/company scoping, but not production-runtime-closed yet because the UI does not provide a stable client operation identity and the retry contract still requires final end-to-end verification.
- `post_inventory_adjustment_atomic`: centralizes physical movement through `post_stock_movement`, but strict final tenant/consumer closure still pending.
- `save_sales_invoice_atomic`: calls `post_stock_movement`; broader tenant/item identity and accounting responsibility closure still pending.
- `complete_return_atomic`: not proven as the current valid Production runtime path; deployed `complete-return` references it, while current Production function inventory previously showed no such RPC. Legacy implementation also contained direct `stock_branches` and `inventory_log` writes. NOT CLOSED.
- `complete_order_delivery_atomic`: deployed Edge references it, but Production RPC existence/runtime contract has not been proven. NOT CLOSED.

## Important interpretation
The manual-voucher UI is not merely missing cosmetic fields. The gap is a business-workflow gap between the historical contract and the current UI/backend composition:
- destination/source selection is incomplete;
- Scrap and Adjustment creation are incomplete in the dedicated UI;
- reference and operational metadata are incomplete;
- cancellation/edit/complete workflows are incomplete or absent from the UI;
- partial receiving is not exposed in the dedicated UI;
- the UI is inconsistent with the broader six-type manual-voucher contract.

## Current percentages (strict, evidence-based)
- Mandatory seven-writer closure sweep: **2/7 fully closed = 28.6%**.
- Purchase receive: **partially remediated, not counted as closed**.
- Full manual-voucher application contract: **not closed** because the UI does not implement the complete six-type workflow proven by the historical architecture.
- ZERO-DEBT / GLOBAL INVENTORY CORE INTEGRITY: **NOT CLOSED**.

These percentages are closure-unit percentages, not a claim about the percentage of all ERP functionality.

## Next step
Do not build new voucher UI features blindly. First close the current manual-voucher contract at the backend boundary:
1. establish one authoritative CREATE/SEND/RECEIVE/CANCEL/COMPLETE contract;
2. make the UI consume it without hardcoded MAIN/empty destination values;
3. provide stable operation identity for purchase receiving;
4. then implement the missing UI capabilities against the proven contract.

## Git state marker
This file is the current memory anchor for the next CTO session. It must be reread before further inventory/voucher work.
