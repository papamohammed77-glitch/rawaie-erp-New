# MASTER PROJECT AWARENESS — CORRECTION 2026-08-18

This correction supersedes one stale statement in `CTO/MASTER_PROJECT_AWARENESS_REPORT.md`.

## Corrected Production Fact

A current direct query of `public.stock_vouchers` shows that `completed_by` EXISTS in the current Production schema as a nullable `text` column.

Therefore the older rescue statement:

`stock_vouchers does not contain completed_by`

is historical evidence, not current Production truth.

## Classification

Historical rescue snapshot:
`completed_by` absent.

Current Production schema:
`completed_by` present.

CTO classification:
`RESOLVED HISTORICAL DRIFT / CURRENT FACT CONFIRMED`

No schema patch is required for this item now.

## Additional Current Fact

The current `stock_voucher` schema also includes:
- company_id
- voucher_code
- type
- status
- from_id / to_id
- sent_date
- received_date
- completed_at
- completed_by
- source

The current `send_stock_voucher_atomic` contract does not rely on `completed_by` for SEND.

## SEND Closure Status

`send-stock-voucher` has been directly verified at the Core layer:
- Draft Transfer fixture
- 5-unit `TransferOut`
- stock `200 -> 195`
- allocated_qty unchanged
- one inventory_log row
- deterministic idempotency key
- second identical SEND returns duplicate without a second movement
- all test transactions rolled back

Current and Production Edge Function definitions are both thin adapters into `send_stock_voucher_atomic`.

Fresh Production HTTP E2E was attempted but could not be executed from the available execution environment because outbound DNS/network access is unavailable and the temporary GitHub workflow commit was blocked by the execution safety gate.

Therefore:

`send-stock-voucher = PRODUCTION DEPLOYED + CORE RUNTIME VERIFIED + HTTP E2E FRESH-RUN UNVERIFIED`

It is intentionally NOT marked `100% CLOSED` until the fresh HTTP E2E gate is directly executed from a network-capable runner.
