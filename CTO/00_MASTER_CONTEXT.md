# RAWAEA ERP — CTO MASTER CONTEXT

## Status
CURATED BASELINE — v1

## Authority
This repository is the curated CTO knowledge base. It is **not** a claim that every historical document is current or that every migration is production-approved.

## Mandatory truth hierarchy
1. Latest Production SQL Evidence explicitly identified as such.
2. Actual deployed RPC definitions captured from Production.
3. Current deployed/production Edge Function behavior.
4. Current application source.
5. Approved architecture constitution and ADRs.
6. Historical documentation.
7. Unreleased migrations/designs are TARGET CANDIDATES ONLY.

When two sources conflict, the conflict is recorded; it is never silently resolved by assumption.

## Project
Rawaea ERP is an FMCG/distribution ERP built around Supabase/PostgreSQL, Supabase Edge Functions, PWA clients, Offline-first storage, warehouse operations, runsheets, sales, purchasing, delivery, returns, settlement, accounting and ledgers.

The architecture principle is ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution. The project execution order is Inventory → Accounting → Ledger → Sales → Purchasing → Delivery/Runsheet → AI.

## Current rescue scope
Inventory / Manual Stock Vouchers / Van Sales.

The immediate objective is NOT to rewrite the ERP. It is to reconcile Production reality, current code, historical code, migrations and target business rules, then produce a minimal safe patch with tests and deployment verification.

## Confirmed Production facts from rescue Evidence
- Production company_id proven: `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`.
- Active branches proven: `BR-01` (main) and `BR-2` (Alexandria), both belonging to the same company.
- app_settings main branch proven: `BR-01`, id `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`.
- Production `stock_branches`: BR-01 has 8,624 total/available quantity in the captured snapshot; BR-2 has 0.
- Production `stock_vouchers` does NOT contain `completed_by` in the captured schema evidence.
- Production `inventory_log` does NOT contain `branch_id` in the captured schema evidence.
- Production `stock_voucher_details` contains `received_qty`.
- Captured index evidence for `stock_voucher_details` proves only its primary unique index on `id`; no RECEIVE idempotency key is proven by that evidence.
- Captured RPC privilege evidence shows the manual-voucher RPCs are executable by the current execution context; the reviewed RPCs are SECURITY DEFINER.

## Confirmed Manual Voucher findings
- COMPLETE RPC writes `completed_by`, while the captured Production schema lacks that column. This is a real RPC/schema contract defect.
- SEND/RECEIVE are implemented through atomic RPC logic in the rescue workstream.
- SEND requires Draft and applies OUT movement for Transfer, DirectSale and SupplierReturn.
- RECEIVE requires Sent and applies IN movement for Transfer and DirectReturn.
- Stock rows are locked with FOR UPDATE in the reviewed atomic path.
- OUT checks `qty - allocated_qty` before deduction.
- Actual movements insert `inventory_log`.
- RECEIVE accumulates `received_qty` and may remain Sent after a partial receipt.
- Partial RECEIVE idempotency is NOT fully proven because a legitimate second partial receive is allowed and no independent request/movement identity is proven by the captured schema/index evidence.
- DirectSale and DirectReturn custody semantics have competing definitions across Production/current code and unreleased target migrations; final Target is therefore not to be invented.
- CANCEL deployed behavior was not fully proven by the persisted evidence reviewed at the rescue checkpoint.
- Manual Voucher COMPLETE/CANCEL audit effects are not fully proven.

## Critical distinction
`20260810_manual_voucher_core_v1_reconciled.sql` is an **unreleased candidate migration**, not Production truth. It must never be labeled deployed. It references `received_by` in one version, which itself requires Production schema proof before adoption. Therefore it belongs in TARGET-CANDIDATE, not CONFIRMED.

## Current source code references
- `PWA/warehouse/vouchers.html` — Manual Stock Voucher UI, source SHA `b0a6d31c787b096a8d6a25b4e9aeb1e99c9d6504`.
- `PWA/sales/van-sales.html` — Van Sales UI, source SHA `445dff4217fbf4a82f333fa716bba5d74def7680`.
- `Edge_Functions/current/inventory/send-stock-voucher.ts` — current send function, source SHA `f2f36f7c3c186eb8f9af51d8bdfd2adf2e7a7421`.
- `supabase/migrations/20260808_send_stock_voucher_atomic.sql` — atomic SEND migration, source SHA `cece154cd805a596607626df862a7d912c3ecb0c`.

## Historical knowledge
The old repository contains extensive architecture, database, API, workflow, handover, Edge Function batch reports, original Edge Functions and historical Van Sales analysis. These are valuable context, but historical claims must be reconciled against current Production Evidence before being used as implementation truth.

## CTO working rule
No assistant may convert UNKNOWN / INFERRED / HISTORICAL / TARGET-CANDIDATE into CONFIRMED merely by repetition. Every production change must follow:

Evidence → Reconciliation → Target Decision → Minimal Patch → Tests → Review → Production GO → Read-only Post-Deploy Verification.
