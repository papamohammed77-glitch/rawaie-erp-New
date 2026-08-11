# CTO — CONFIRMED FACTS REGISTER

**Source:** `rawaie-erp-review` branch `rescue/manual-vouchers-inventory-core`
**Purpose:** freeze the latest confirmed facts so future work does not reopen settled questions without new evidence.

## Production identity

- Company ID: `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- Active branches: `BR-01` and `BR-2`
- Main branch: `BR-01`

## Inventory snapshot

- BR-01: 50 stock rows, qty total 8624, allocated 0, available 8624.
- BR-2: 49 stock rows, qty total 0, allocated 0, available 0.

## stock_vouchers

Captured Production schema does NOT contain `completed_by`.
Captured columns include `completed_at`, `created_by`, `sent_date`, `received_date`, status, type, from/to fields and company_id.

## inventory_log

Captured Production contract does NOT contain `branch_id`.
Captured columns include company_id, voucher_id, item_id, item_code, item_name, movement_type, qty, reference, user_email and timestamps.

## Manual Voucher RPCs

Captured RPC privilege evidence lists:

- `cancel_manual_stock_voucher_atomic(uuid,text,text)`
- `complete_manual_stock_voucher_atomic(uuid,text,text)`
- `create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)`
- `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)`

Captured COMPLETE definition attempts to write `completed_by`.
Captured CANCEL definition permits cancellation only from Draft and changes status to Cancelled without stock mutation.

## Current lifecycle rules

Current shared rules support:

- Transfer
- DirectSale
- DirectReturn
- SupplierReturn

SEND stock-out types:

- Transfer
- DirectSale
- SupplierReturn

RECEIVE stock-in types:

- Transfer
- DirectReturn

## Partial RECEIVE

Current code explicitly supports partial receipt by using `received_qty` and remaining quantity. The captured boundary does not show a request/event idempotency key. Therefore replay protection is **not proven**.

## DirectSale / DirectReturn custody

Current CREATE defaults to the authenticated user's VAN branch only when the relevant endpoint is omitted. A caller-supplied endpoint is not overwritten. Therefore strict custody ownership enforcement is **not proven**.

## Architecture/document conflicts

- Some architecture materials reference `inventory_log.branch_id`; Production evidence does not show it.
- Some architecture materials list Scrap/Adjustment as voucher types; current shared lifecycle rules do not.
- An unreleased migration proposes DirectSale OUT+IN and DirectReturn OUT+IN behavior, while current Production/current code use different semantics. The migration is NOT Production truth.

## Security classification

Broad RLS policies were observed, but RLS alone was not classified as a confirmed defect. Security must be evaluated end-to-end.

## Frozen exclusions

`SQL_Evidence/diagnostics/رد حول التعريفات.md` is not authoritative because it contains an earlier memory-based schema description followed by later verified index evidence. It is deliberately excluded.

Unreleased migrations are reference-only and are not admitted to the operational SQL set.

## Rule

These facts are frozen until new evidence changes them. Do not reopen them merely because a new assistant has not read them.
