# TASK-001 — PROJECT BASELINE

## Purpose
Establish the factual baseline for the current Inventory / Manual Stock Voucher / Van Sales rescue scope before any design or code modification.

## 1. Repository Baseline

### Primary curated repository
`papamohammed77-glitch/rawaie-erp-New`

- Default branch: `main`
- Role: CTO-curated recovery knowledge baseline.
- The repository itself explicitly states that Production Evidence is not interchangeable with historical documentation or unreleased migrations.

### Source/review repository
`papamohammed77-glitch/rawaie-erp-review`

- Default branch: `main`
- Role: original review/source repository containing the broad project documentation, current-source pointers, historical Edge Function material, rescue workstream and Evidence.

## 2. Version / State Classification

### Production
Production is represented only by explicitly captured Production Evidence under:
`SQL_Evidence/diagnostics/`

Confirmed captured facts include the Production schema, manual-voucher RPC definitions, RPC privileges, inventory-log contract, company/branch consistency, settings/main-branch consistency, stock snapshot and actual indexes.

**Important:** these files are snapshots of captured Production state; a stock snapshot is not a timeless balance.

### Current Source
The current application/service source relevant to this rescue scope is identified by immutable Git blob SHA in the curated repository:

- `PWA/warehouse/vouchers.html` — Manual Stock Voucher UI — blob SHA `b0a6d31c787b096a8d6a25b4e9aeb1e99c9d6504`.
- `PWA/sales/van-sales.html` — Van Sales UI — blob SHA `445dff4217fbf4a82f333fa716bba5d74def7680`.
- `Edge_Functions/current/inventory/send-stock-voucher.ts` — current SEND function — blob SHA `f2f36f7c3c186eb8f9af51d8bdfd2adf2e7a7421`.
- `supabase/migrations/20260808_send_stock_voucher_atomic.sql` — current SEND migration/source artifact — blob SHA `cece154cd805a596607626df862a7d912c3ecb0c`.

The curated repository deliberately keeps the large UI sources as source pointers rather than silently duplicating them without freezing the intended source ref.

### Legacy / Historical
The source repository contains historical project documentation, original Edge Functions, historical batch reports, handover material and older Van Sales analysis.

Confirmed original inventory functions requiring comparison include:
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

Historical documentation is context only and cannot override newer Production Evidence.

### Target / Unreleased
Unreleased migrations/designs are target candidates only.

The curated baseline explicitly identifies:
`20260810_manual_voucher_core_v1_reconciled.sql`

as an **unreleased candidate migration**, not Production truth. It must not be treated as deployed.

## 3. Project-Level Baseline

The historical project entry document identifies the project as RAWAEA ERP, an FMCG/distribution ERP using Supabase/PostgreSQL, Supabase Edge Functions and PWA/Offline-First clients. It documents a broad system footprint of 26 PWA applications and 71 Edge Functions. Those counts belong to the historical project baseline and are retained as context, not as current Production proof.

The current rescue scope is narrower:

`Inventory → Manual Stock Vouchers → Van Sales`

The governing execution order recorded in the curated baseline is:

`Inventory → Accounting → Ledger → Sales → Purchasing → Delivery/Runsheet → AI`

## 4. Files / Functions Directly Related to Rescue Scope

### UI
- `PWA/warehouse/vouchers.html`
- `PWA/sales/van-sales.html`

### Current inventory Edge Function
- `Edge_Functions/current/inventory/send-stock-voucher.ts`

### Original voucher/inventory functions
- create-stock-voucher
- send-stock-voucher
- receive-stock-voucher
- complete-stock-voucher
- cancel-stock-voucher
- receive-purchase
- save-inventory-count
- start-receiving
- reopen-receiving
- bulk-stock-adjustment

### Adjacent inventory-impact functions
- `complete-loading.ts`
- `unload-runsheet.ts`
- `complete-return.ts`
- `save-sales-invoice.ts`
- `update-driver-ledger.ts`

These are not declared equivalent; they are the confirmed adjacent functions requiring inventory-impact review.

## 5. Current Manual Voucher Facts

Production schema evidence proves `stock_vouchers` fields including:
`id, company_id, voucher_code, voucher_date, type, status, from_branch_id, to_branch_id, from_type, from_id, to_type, to_id, reference, notes, created_by, sent_date, received_date, completed_at, created_at, updated_at, source`.

`completed_by` is absent from the captured Production schema.

`stock_voucher_details` includes `received_qty`.

`stock_branches` includes:
`id, branch_id, item_id, qty, allocated_qty, available_qty, updated_at`.

`inventory_log` includes:
`id, company_id, log_code, movement_date, voucher_id, item_id, item_code, item_name, movement_type, qty, reference, user_email, created_at`.

The captured atomic SEND/RECEIVE path contains row locking, availability checks using `qty - allocated_qty`, inventory-log insertion and cumulative `received_qty` handling.

## 6. Current Known Transition Point

The current SEND Edge Function calls:
`send_stock_voucher_atomic(...)`

The later manual-voucher candidate path uses:
`post_manual_stock_voucher_atomic(...)`

Therefore the newer candidate path is **not proven to be the sole current consumer**. This is an implementation-transition fact, not a migration-complete claim.

## 7. Baseline Conclusion

TASK-001 establishes the following:

1. We have a reliable authority hierarchy.
2. Production Evidence is separated from current source, historical source and target candidates.
3. The current rescue scope and its directly related UI/functions are identified.
4. Immutable blob SHAs identify the two critical current UI files and the current SEND function/migration artifact.
5. The current Production contract for the core Voucher tables is partially established and contains known RPC/schema drift.
6. The baseline is sufficient to begin **TASK-002 — Inventory Data Contract**, but it is **not** permission to patch anything.

## 8. Explicit Non-Claims

This baseline does NOT claim:
- that the historical 26-PWA / 71-function counts equal the current deployed count;
- that every Edge Function has been reconciled against Production;
- that all Manual Voucher RPC dependencies have complete Production schema evidence;
- that DirectSale/DirectReturn custody has been finally decided;
- that CANCEL behavior is fully proven;
- that Partial RECEIVE idempotency is solved;
- that any unreleased migration is deployed.

## Gate

**TASK-001 STATUS: COMPLETE**

**NEXT SAFE TASK: TASK-002 — INVENTORY DATA CONTRACT**

No Production SQL or application patch is authorized by this task.
