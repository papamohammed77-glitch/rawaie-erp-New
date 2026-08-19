# CTO FORENSIC PWA + INVENTORY CLOSURE — 2026-08-19

## Governing Method
This checkpoint is based on direct GitHub source inspection and live Production PostgreSQL verification, not on historical reports or model memory.

The governing engineering sequence remains:
UNDERSTAND → RECONSTRUCT HISTORICAL CONTRACT → TRACE CURRENT BEHAVIOR → TRACE DATA/AUTH/CONTROL FLOW → COMPARE WITH TARGET → IDENTIFY GAP → SURGICAL FIX → VERIFY.

## Source Review
Reviewed directly:
- `doc/Draft/medhat/برومبت 6`
- `doc/Draft/medhat/تقرير تنفيذ برومبت 6`
- `doc/Draft/medhat/برومبت 7 ملحق بتقريره`
- `Inventory/05-GLOBAL-INVENTORY-ZERO-DEBT-RESULT-20260819.md`
- `doc/Draft/medhat/برومبت 8 وتقرير تنفيذه`
- `doc/Draft/medhat/برومبت 9 وتقرير تنفيذه`
- `doc/Draft/Hussin/تقييم برومبت 9 وتقريره` (where available)
- `doc/Draft/medhat/برومبت 10 وملحق به تقرير تنفيذه`
- Current/PWA source files

## Production Facts Verified 2026-08-19
- `post_stock_movement` remains the only PostgreSQL function that performs the actual Physical Stock movement (`stock_branches.qty` movement + `inventory_log` insertion).
- `reserve_stock` and `release_stock_reservation` are Reservation capabilities only.
- `setup_van_stock` is bootstrap/row initialization only.
- `complete_runsheet_picking` modern overload accepts `p_operation_id uuid`; the active Edge Function calls this overload with the request operation identity.
- The old 4-argument `complete_runsheet_picking` overload has no application-role EXECUTE privilege.
- Current `complete-picking` Edge version 16 accepts `operation_id` from the request body or `Idempotency-Key`, validates UUID format, and forwards it to `complete_runsheet_picking`.
- Current `picker.html` generates and persists one UUID per runsheet completion attempt in `sessionStorage`, then sends it both as `operation_id` and `Idempotency-Key`.
- Therefore request-level Picking replay safety is CLOSED in the current PWA/Edge/DB chain.

## Current Data Integrity Snapshot
Live Production query at closure:
- stock cross-company rows: 0
- inventory_log cross-company rows: 0
- order_details cross-company rows: 0

The previously reported 143 `stock_branches` and 86 `inventory_log` rows are therefore historical/stale relative to the current Production snapshot; no deletion is required for them now.

Six historical `order_details` rows were still mismatched. They were tied to old `ORD-1007` through `ORD-1009` records from July 2026, with one-unit test-like detail rows and item identities belonging to other companies. They were removed transactionally from Production and an accepted `audit_log.action='delete'` record was written before deletion. Final verification returned zero mismatches.

## PWA Forensic Finding — VAN
### `_createVanBranch()`
The alleged direct INSERT/fixed-company defect is NOT present in the current `van-sales.html` source.

Current `_createVanBranch()` correctly calls `setup-van-branch` and derives the stored company context from the authenticated user. No direct `branches` INSERT exists in this function.

Canonical `setup-van-branch` proves that vehicle identity is `VAN-{vehicle_code}` and that driver email is validation metadata.

### Actual Remaining PWA Defect
`loadVanBranch()` still constructs the branch code from the driver's email (`VAN-{email}`) before querying local/Supabase branches. This does not match the canonical identity contract `VAN-{vehicle_code}`.

This is a real Current PWA bug and should be fixed in `Current/PWA/van-sales.html` only. No new file is required.

## Required PWA Surgical Fix
Search exactly for:
`loadVanBranch: function() {`

Replace that complete function with the corrected version supplied in the CTO response/report accompanying this checkpoint.

Do NOT replace `_createVanBranch()`; it is already correct in Current.

## Picking Status
`complete-picking` is CLOSED for request-level idempotency:
PWA → operation_id + Idempotency-Key → Edge version 16 → `complete_runsheet_picking(..., p_operation_id uuid)` → `reserve_stock`.

No additional Picking patch is required at this checkpoint.

## Inventory Core Status
Global direct-function scan over live PostgreSQL confirmed:
- `post_stock_movement`: direct physical writer.
- `reserve_stock`: reservation only.
- `release_stock_reservation`: reservation release only.
- `post_manual_stock_voucher_atomic`: updates voucher detail state; delegates physical movement.
- `post_inventory_adjustment_atomic`: delegates physical movement.
- `send_stock_voucher_atomic`: delegates physical movement.
- `complete_runsheet_picking`: reservation path only.
- `complete_runsheet_reopen_loading`: no independent physical writer.
- `setup_van_stock`: bootstrap only.

`PHYSICAL WRITERS OUTSIDE post_stock_movement = 0` remains TRUE in live Production.

## Closure Percentages
- Physical Stock Core Centralization: 100% CLOSED
- Picking request-level idempotency: 100% CLOSED
- Historical cross-company stock/inventory metadata cleanup: 100% VERIFIED (current rows = 0)
- Historical order_details company/item identity cleanup: 100% VERIFIED (current rows = 0)
- Current PWA VAN branch identity alignment: NOT YET CLOSED — surgical PWA edit remains to be applied by the project owner.

## Current Overall State
Inventory Core Integrity itself remains CLOSED.
Current/PWA integration has one confirmed remaining defect in `loadVanBranch()`.

## Next Step
Apply the `loadVanBranch()` surgical replacement in the same `van-sales.html` file, then perform one real authenticated Production smoke test for VAN login/branch resolution and verify:
1. returned branch code is `VAN-{vehicle_code}`;
2. branch belongs to the authenticated company;
3. no duplicate branch is created;
4. cached branch resolution uses the canonical branch code.

## CTO Restart Checkpoint
This document is the latest factual checkpoint for the next CTO/session. Do not rely on earlier percentages without re-querying Production.
