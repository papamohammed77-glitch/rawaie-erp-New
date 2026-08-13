# BACKUP CTO 11 — EDGE FUNCTION MEMORY

## Rule
Original Edge Functions are immutable behavioral references. Current Edge Functions are implementation candidates/current source. Production deployed behavior outranks both.

## Original inventory functions explicitly reviewed historically
The original repository contains inventory functions including:
- create-stock-voucher.ts
- send-stock-voucher.ts
- receive-stock-voucher.ts
- complete-stock-voucher.ts
- cancel-stock-voucher.ts
- receive-purchase.ts
- save-inventory-count.ts
- start-receiving.ts
- reopen-receiving.ts
- bulk-stock-adjustment.ts

Adjacent inventory-impact functions include:
- complete-loading.ts
- unload-runsheet.ts
- complete-return.ts
- save-sales-invoice.ts
- update-driver-ledger.ts

## Current SEND implementation history
The current review work moved SEND toward DB-side atomic execution. A current Edge Function snapshot `send-stock-voucher.ts` calls `send_stock_voucher_atomic` and resolves company context from `app_settings` server-side.

Do not assume that because a current function exists in GitHub it is deployed. Confirm deployment separately.

## Business-engine lesson
A recurring defect pattern was distributed business logic: multiple Edge Functions or UIs independently changed stock/log/ledger state. This created double deductions, conflicting logs and fragile fixes.

The target architecture is:
UI → capability boundary → centralized business engine/RPC → state/logging.

## Van Sales lesson
Van Sales must never deduct MAIN when it should deduct the mobile VAN. Vehicle stock custody is a first-class business state.

Before repairing `van-sales.html`:
1. Read original `van-sales.html`.
2. Read current source.
3. Map every API/RPC call.
4. Map every stock movement.
5. Compare against central inventory contract.
6. Only then change code.
