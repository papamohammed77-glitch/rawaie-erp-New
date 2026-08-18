# RAWAEA ERP — Prompt 3 Current Reality + SEND Stock Voucher Repair Log

Date: 2026-08-18
Execution basis: Production-first reconciliation
Canonical status: CURRENT / EVIDENCE-BACKED

## 1. Synchronization Reset

The Prompt 2 execution report was re-evaluated before any modification.
Its own review identified Production synchronization drift: it recorded an older Production state (start-picking v14, complete-picking v13, send-stock-voucher v7, receive-stock-voucher v5, complete-loading v10).

The current Production state read from Supabase in this Prompt 3 cycle is different and is therefore the only state used for decisions.

Current relevant Production Edge versions observed:
- start-picking v33
- complete-picking v15
- send-stock-voucher v19
- receive-stock-voucher v21
- complete-loading v11
- complete-return v23
- unload-runsheet v6
- save-sales-invoice v14
- bulk-stock-adjustment v5
- setup-van-branch v3

No historical percentage or old Closure result was promoted into current truth.

## 2. Source Reconciliation — SEND Stock Voucher

Current Edge adapter is company-scoped and thin:
- validates voucher_code
- authenticates the caller
- resolves public user/company context
- calls public.send_stock_voucher_atomic(...)
- does not directly mutate stock or write inventory_log

Historical Original implementation was a competing business engine: direct stock mutation, direct inventory_log behavior, hardcoded company context, weak tenant scoping, and no centralized transaction/idempotency boundary.

Current architecture is therefore materially better and follows the central inventory rescue direction.

## 3. Production Core Defect Discovered

Current public.send_stock_voucher_atomic grouped voucher detail rows by item_id/item_code when creating the actual stock movement and idempotency key.

However, the duplicate/replay detector counted raw stock_voucher_details rows.

This creates a concrete defect when the same item appears on multiple detail rows:
- first SEND groups the rows into one actual movement and one idempotency log
- expected_count counted multiple raw detail rows
- replay does not satisfy the duplicate condition
- replay then hits the Sent-state guard and returns "Voucher is not Draft"

This defect was reproduced directly against Production Core with a temporary DirectSale voucher containing two detail rows for the same item.

Observed before repair:
- first SEND: success / Sent / movement_count = 1
- replay: P0001 "Voucher is not Draft"

## 4. Permanent Repair Applied

Migration applied to Production:
20260818162929_fix_send_voucher_idempotency_duplicate_detail_groups

The repair changes expected_count to count the distinct grouped movement identity (item_id,item_code), matching the same grouping used by the actual movement loop and idempotency keys.

No temporary bypass, magic state, or adapter-side workaround was added to Production business behavior.

The exact migration was also committed to Git:
supabase/migrations/20260818163000_fix_send_voucher_idempotency_duplicate_detail_groups.sql

Production function fingerprint after repair:
546b5291430231634ca544b4cc0eaf6f

## 5. Post-Repair Production Core Verification

A second real temporary DirectSale voucher with two detail rows for the same item was executed against Production Core.

First SEND:
- success = true
- status = Sent
- movement_count = 1

Replay:
- success = true
- duplicate = true
- status = Sent
- movement_count = 1

The replay did not create a second movement.

After cleanup the baseline was restored exactly for the canary stock row:
- qty = 207.0000
- allocated_qty = 0.0000

Temporary P3 voucher rows after cleanup:
- P3 vouchers = 0

Temporary SEND inventory-log rows after cleanup:
- 0

## 6. HTTP E2E Gate Findings

The actual Production HTTP path was attempted through the existing GitHub Production canary infrastructure and the real Supabase endpoint.

The HTTP gate did reach the live runtime, but the temporary authentication bootstrap repeatedly failed before it could call send-stock-voucher.

Observed harness failures were isolated to test infrastructure:
- createUser returned no user
- generateLink for a new test user returned no generated user
- generateLink/OTP for the selected existing user returned no token
- no SEND request was made in those failed runs

The harness was never modified to bypass the actual production authentication contract.

The temporary SEND runtime harness was retired to HTTP 410 after testing.
The temporary GitHub PR was closed without merge.
The main Production canary workflow was restored to its original content.

## 7. Closure Status

SEND Stock Voucher Core Repair: PASS
Production Core duplicate-detail idempotency: PASS
Physical stock baseline restoration: PASS
Temporary fixture cleanup: PASS
Production adapter static boundary: PASS
HTTP Production E2E gate: NOT CLOSED — blocked by unavailable test Auth bootstrap, not by a failing SEND business path

Therefore:
**SEND STOCK VOUCHER = REPAIRED / CORE-GO / HTTP-CLOSURE-PENDING-AUTH**

No project-wide percentage is reported.
No full SEND Closure/GO claim is made until the Production HTTP authentication gate can execute legitimately.

## 8. Synchronization Discipline Result

This cycle demonstrates the required operating rule:
Production Current State -> Evidence -> Current Git -> Historical/Original -> Defect reproduction -> Permanent repair -> Production verification -> Current snapshot

The Prompt 2 numeric report was not treated as current truth.
The current Production deployment state was re-read in the same cycle as the repair and final verification.

## 9. Explicit Non-Goals / Not Closed Here

- receive-stock-voucher was not closed in this Prompt 3 cycle.
- full manual Voucher lifecycle/CANCEL semantics were not closed here.
- global physical stock-writer sweep was not closed here.
- HTTP E2E authentication bootstrap has not been converted into a permanent production bypass and must not be.

## 10. Final Rule

KNOW -> RECONCILE PRODUCTION -> REPRODUCE -> REPAIR PERMANENTLY -> VERIFY -> RESTORE BASELINE -> CLOSE ONLY WHEN ALL GATES PASS
