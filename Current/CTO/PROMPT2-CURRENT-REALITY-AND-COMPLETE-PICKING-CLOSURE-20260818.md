# RAWAEA ERP — PROMPT 2 CURRENT REALITY + COMPLETE PICKING CLOSURE

Date: 2026-08-18
Execution: Prompt 2
Canonical location: `Current/`

## 1. CURRENT REALITY RESET

The previous Prompt-1 execution report is not treated as current truth. Direct Production evidence was re-read first, then current Git, historical/original sources, and deployment/runtime logs were reconciled.

### Current Production snapshot used for this stage
- `start-picking`: ACTIVE v33
- `complete-picking`: ACTIVE v15
- `start-loading`: ACTIVE v5
- `complete-loading`: ACTIVE v11
- `complete-return`: ACTIVE v23
- `unload-runsheet`: ACTIVE v6
- `send-stock-voucher`: ACTIVE v19
- `receive-stock-voucher`: ACTIVE v21
- `receive-purchase`: ACTIVE v9
- `bulk-stock-adjustment`: ACTIVE v5
- `save-sales-invoice`: ACTIVE v14
- `setup-van-branch`: ACTIVE v3

Version existence is not closure by itself; runtime evidence was required for the active Closure Unit.

## 2. PROMPT-1 RESPONSE EVALUATION

The earlier response had a valid evidence hierarchy and correctly separated Production, Current, Original, and Target. Its principal defect was synchronization: its numeric plan and status snapshot had become stale relative to later Production deployments and migrations.

The corrected operating sequence for this Prompt-2 cycle is:

`Production Current State → Reality Matrix → Git/Current → Historical/Original → Target → Closure Unit`

No previous PASS/100% result was promoted without current proof.

## 3. CURRENT COMPLETE-PICKING CONTRACT

### Current Edge adapter
`Current/Edge_Functions/complete-picking`

Responsibilities retained:
- request parsing
- authentication
- mapping authenticated user to public user/company context
- input normalization
- call to `complete_runsheet_picking`
- response formatting

Responsibilities intentionally absent:
- direct `stock_branches` mutation
- direct `inventory_log` write
- autonomous reservation orchestration
- direct `run_sheet_details` dual-write

### Production Core
`public.complete_runsheet_picking(...)`

Verified current behavior:
- SECURITY DEFINER
- company/user validation
- runsheet `FOR UPDATE`
- `Picking` state gate
- picker ownership validation
- duplicate item aggregation
- authoritative item identity from order details
- quantity bounds validation
- reservation through `reserve_stock`
- deterministic distribution of `qty_picked`
- final transition to `Picked`
- physical stock `qty` unchanged by Picking
- no Picking inventory movement is written

`reserve_stock` owns reservation state (`allocated_qty`).
`release_stock_reservation` owns reservation release.
`sync_run_sheet_details` remains derived from authoritative order details.

## 4. HISTORICAL / ORIGINAL DELTA

Historical Original `complete-picking` contained distributed business behavior, including direct state changes, direct inventory-log behavior and reservation orchestration.

Current architecture moved those responsibilities into the controlled Core boundary.

The current adapter therefore preserves the operational HTTP contract while removing the historical competing business engine.

## 5. PRODUCTION HTTP E2E — COMPLETE PICKING

The existing Production canary workflow was reconstructed only where its retired test harness had drifted from the current database contract. No application business code was changed.

Production log sequence on 2026-08-18:

1. Canary authentication helper → HTTP 200.
2. Canary fixture creation → HTTP 200.
3. Actual Production `/functions/v1/complete-picking` v15 → HTTP 200.
4. Verification helper → HTTP 200.
5. Verification proved the runsheet/detail/derived detail state and reservation boundary.
6. Retry of the same completion → HTTP 400.
7. Fixture cleanup → HTTP 200.

The runtime log records the successful Production request as:

`POST /functions/v1/complete-picking | 200 | version 15`

and the retry as:

`POST /functions/v1/complete-picking | 400 | version 15`

The first verification confirmed the intended boundary:
- physical stock `qty` stayed at baseline (`200` in the canary fixture)
- `allocated_qty` increased by `1`
- runsheet became `Picked`
- `qty_picked = 1`
- no `Picking` inventory-log rows were generated

After cleanup, direct Production verification returned:
- stock `qty = 200`
- `allocated_qty = 0`
- canary runsheets = 0
- canary public users = 0
- canary inventory-log rows = 0
- canary run-sheet-detail rows = 0
- canary auth user = 0 after manual final cleanup

## 6. CORRECTIONS MADE DURING THIS STAGE

Only test infrastructure and durable documentation were corrected.

Correct fixes:
- refreshed retired canary identity helper to match the current `public.users` Warehouse Picker contract
- refreshed retired fixture helper to support the workflow's current `mode=verify` contract
- corrected fixture cleanup to release reservations before deleting fixture records
- restored the canary baseline after the first verification run
- removed the canary auth user left after automatic cleanup

No production business function was patched during this stage because the Production `complete-picking` implementation already matched the required rescue architecture and passed runtime proof.

## 7. COMPLETE-PICKING GATE

| Gate | Result |
|---|---|
| Historical reviewed | PASS |
| Original reviewed | PASS |
| Current source reviewed | PASS |
| Production Edge reviewed | PASS |
| Production Core reviewed | PASS |
| Dependencies reviewed | PASS |
| Consumer/HTTP contract reviewed | PASS |
| Static adapter boundary | PASS |
| Production HTTP E2E first execution | PASS |
| Production state verification | PASS |
| Retry/repeat rejection | PASS |
| Reservation boundary | PASS |
| No physical Picking movement | PASS |
| Baseline restoration | PASS |
| Fixture cleanup | PASS |
| Production application code changed | NO |

### Closure decision
**COMPLETE-PICKING = CLOSED / GO**

This closure applies only to `complete-picking`.

No later Closure Unit is implicitly closed by this document.

## 8. REMAINING CURRENT PRIORITY

The next safe unit is selected from current Production truth, not the stale numerical plan:

1. `send-stock-voucher` — reconcile current source/Production gate if still required.
2. `receive-stock-voucher` — full Closure Unit.
3. `receive-purchase`.
4. `bulk-stock-adjustment`.
5. `save-sales-invoice`.
6. `complete-return`.
7. `complete-order-delivery`.
8. global physical stock-writer sweep.

## 9. SELF-AUDIT

Business Understanding: CONFIRMED for Inventory/Warehouse/Picking scope.
Architecture Understanding: CONFIRMED for inspected domain.
Database Understanding: CONFIRMED for inspected objects.
Historical Understanding: CONFIRMED for reviewed Original sources.
Production Understanding: CONFIRMED for inspected Production/core/runtime.
Current Understanding: CONFIRMED for inspected Current artifacts.
Execution Confidence: HIGH for `complete-picking`; not a project-wide closure claim.

### Explicit unknowns still carried
- Manual Voucher full audit/CANCEL semantics outside this unit are not closed here.
- Partial RECEIVE final request-level idempotency semantics outside this unit are not closed here.
- DirectSale/DirectReturn target custody semantics outside this unit are not closed here.
- Full project-wide physical stock-writer sweep is not closed here.

### Final rule
`KNOW → DECIDE → REPAIR → TEST → DEPLOY/VERIFY → CLOSE → CONTINUE`
