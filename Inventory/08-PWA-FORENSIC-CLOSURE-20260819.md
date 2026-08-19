# RAWAEA ERP — PWA / Inventory Forensic Closure Checkpoint
## 2026-08-19

## Source Rule
This checkpoint was reconstructed from current GitHub sources and live Production PostgreSQL. Previous reports were treated as historical evidence only.

## Production Data State After Cleanup
- Orders remaining: 0
- Order details remaining: 0
- Inventory logs referencing deleted test orders: 0
- Journal entries referencing deleted test orders: 0
- Cross-company `stock_branches` rows: 0
- Cross-company `inventory_log` rows: 0
- Negative stock rows: 0
- Invalid `allocated_qty` rows: 0
- `erp_operation_registry` rows in `processing`/`failed`: 0
- Stock/log triggers: 0

The seven existing Orders were test data. They were deleted together with their order-cascade data and the explicitly linked test inventory/journal residues. No Owner System metadata was targeted.

## Current PWA Forensic Findings
### `Current/PWA/van-sales.html`
The historical defect described in earlier material is no longer present in `main`.
`_createVanBranch()` currently calls the canonical `setup-van-branch` capability with `driver_email` and does not perform a direct `branches` INSERT or embed a fixed Company ID.

Production `setup-van-branch` is ACTIVE and company-scoped: it authenticates the caller, resolves `users.company_id`, validates the vehicle, creates/reuses `VAN-{vehicle_code}`, then calls `setup_van_stock`.

**Status: CLOSED. No surgical PWA replacement is required.**

### `Current/PWA/picker.html`
The historical replay-safety gap is also already closed.
The current picker generates/retains a stable `complete_operation_id` in `sessionStorage` for the active company+runsheet, sends it both as `Idempotency-Key` and `operation_id`, and the current Edge Function forwards it to the 5-argument canonical `complete_runsheet_picking` overload.

Production currently contains two overloads:
- legacy 4-argument `complete_runsheet_picking` — PostgreSQL-only privilege
- canonical 5-argument `complete_runsheet_picking(..., p_operation_id uuid)` — callable by `service_role`

The application path therefore cannot select the legacy overload.

**Status: CLOSED for the application path. No picker.html patch is required.**

### `Current/PWA/main.html`
Current `main` contains `operation_id: crypto.randomUUID()` in all three Save-Sales `orderHeader` builders and sends an explicit `operation_id` for Receive-Purchase.

**Status: structurally aligned with the current Core contracts.**

### `Current/PWA/vouchers.html`
Current voucher UI uses Edge capability calls (`create-stock-voucher`, `send-stock-voucher`, `receive-stock-voucher`) rather than implementing Physical Stock mutation in the UI.

**Status: structurally aligned with the central stock architecture.**

## Inventory Core Position
Current Production confirms:
- Physical Stock mutation remains centralized in `post_stock_movement`.
- Picking uses `reserve_stock`; current `complete_runsheet_picking` reports `inventory_log_written=false`.
- No triggers exist on `stock_branches` or `inventory_log`.

## Closure Assessment
- Production data cleanup: 100% complete for the requested test Orders and linked test residues.
- Cross-company data cleanup target: 100% complete; current count is zero.
- PWA structural alignment for the four inspected applications: PASS.
- Picker request-level idempotency: PASS by current source/Edge contract.
- Van Branch tenant-safe capability path: PASS by current source/Production capability.
- Fresh end-to-end PWA runtime execution during this checkpoint: not performed; therefore runtime verification is not represented as 100%.

## Next Step
The next engineering step is a fresh Production runtime verification of the Picker capability, followed by a deliberate retirement review of the inaccessible legacy 4-argument `complete_runsheet_picking` overload only after dependency evidence proves it is unused.

## CTO Resume Point
Do not reopen `_createVanBranch()` or Picker idempotency as if they were still historical defects. The current `main` files already contain the corresponding repairs.
