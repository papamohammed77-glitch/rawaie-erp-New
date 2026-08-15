# RAWAEA ERP — RESCUE RECONCILIATION / ZERO-DEBT EXECUTION

Date: 2026-08-15
Branch: `inventory-rescue-20260815`
Base: `main` @ `616067d147be29e1285760f92f56b3f0295691c3`

## PRE-CHANGE SELF-AUDIT

| Gate | Classification | Evidence |
|---|---|---|
| Business understanding | CONFIRMED | Final CTO handover + existing CTO baseline |
| Architecture understanding | CONFIRMED | Architecture Constitution + Execution Protocol |
| Database understanding | CONFIRMED | Direct Production schema/function/trigger queries |
| Historical understanding | CONFIRMED | Original `complete-picking.ts` and `send-stock-voucher.ts` |
| Production understanding | CONFIRMED | Deployed Edge definitions + Production SQL evidence + recent runtime logs |
| Current-source understanding | CONFIRMED | Current Edge source files |
| Execution confidence | HIGH | Existing Production E2E evidence and direct Production definitions |
| Unknowns affecting complete-picking closure | NONE blocking | See closure matrix |
| Unknowns affecting send-stock-voucher | NONE blocking for adapter patch | Production RPC is deployed and current runtime uses it |

## PRODUCTION TRUTH RECONCILIATION

### Project / runtime

- Production Supabase project is `SMART ERP` (`fiilmooggumokxanwiyx`).
- Production `complete-picking` is ACTIVE at version 13 with JWT verification enabled.
- Production `start-picking` is ACTIVE at version 15 with JWT verification enabled.
- Production `send-stock-voucher` is ACTIVE at version 7 with JWT verification enabled.

### Complete Picking — Current / Original / Production / Target

| Layer | Reality | Classification |
|---|---|---|
| Historical Original | Edge performed inventory logging, direct order-detail writes, reservation calls and runsheet state mutation itself | HISTORICAL |
| Current source before rescue | Thin adapter calling `complete_runsheet_picking` | CURRENT SOURCE |
| Production Edge | Same thin adapter contract as Current before rescue | PRODUCTION DEPLOYED |
| Production Core | `complete_runsheet_picking` is SECURITY DEFINER, locks the runsheet, validates company/user/picker context, aggregates item input, calls `reserve_stock`, distributes `qty_picked` across matching order details, then closes the runsheet | PRODUCTION RUNTIME CORE |
| Reservation | `reserve_stock` locks the stock row, validates company/item/branch context and increments `allocated_qty` only; physical `qty` is unchanged | PRODUCTION DEPLOYED |
| Derived aggregate | `order_details` is authoritative; AFTER INSERT/UPDATE/DELETE trigger `sync_run_sheet_details` rebuilds `run_sheet_details` | PRODUCTION DEPLOYED |
| Physical movement | None during picking | TARGET / CONFIRMED |
| Inventory log | No Picking movement is written | TARGET / CONFIRMED |

### Complete Picking — LOSS / GAIN MATRIX

| Responsibility | Result |
|---|---|
| Authentication | RETAINED / HARDENED |
| Company isolation | HARDENED: company comes from authenticated application user context in Core and is applied to runsheet/items/stock queries |
| Picker ownership | HARDENED: Core verifies `picker_id` against the authenticated application user |
| Runsheet state | HARDENED: row lock + `Picking` precondition + conditional final state transition |
| Reservation | MOVED from Edge-side orchestration to Core |
| Physical stock mutation | INTENTIONALLY REMOVED from Picking; correct because Picking is reservation, not movement |
| Picking inventory log | INTENTIONALLY REMOVED; no physical movement occurred |
| Multi-order same-item distribution | HARDENED: Core uses remaining quantity and ordered quantity per detail instead of assigning the full picked quantity to every matching order |
| `run_sheet_details` dual-write | INTENTIONALLY REMOVED; database trigger is authoritative |
| Retry behavior | HARDENED by runsheet state gate; second completion is rejected |

### Production Runtime Verification — Complete Picking

Recent Production Edge logs show successful and rejected requests against deployed version 13. The Production canary sequence performed:

1. Fixture creation.
2. Authenticated HTTP call to `/functions/v1/complete-picking` → 200.
3. Post-call verification → 200, including `Picked`, `qty_picked`, `run_sheet_details.qty_picked`, unchanged physical `qty`, increased `allocated_qty`, and zero Picking inventory-log rows.
4. Retry against the same runsheet → 400.
5. Fixture cleanup → 200.

The same sequence was observed repeatedly in the recent Production log window. A direct cleanup verification also returned zero remaining `CP-PROD-CANARY-*` runsheets, orders, or inventory-log rows.

### Complete Picking Closure

**Status: 100% CLOSED — PRODUCTION RUNTIME VERIFIED.**

No code patch is required for `complete-picking` at this checkpoint. The deployed Production contract already matches the intended rescue architecture, and the current source is aligned with it.

Concurrency note: the Core uses a row lock on the runsheet and the existing staging concurrent canary proved exactly-one-success/one-failure behavior. A separate concurrent mutation was not performed against live Production; therefore this report does not misclassify staging contention as Production runtime contention.

## SEND STOCK VOUCHER — READINESS / SURGICAL PATCH

### Before patch
`Current/Edge_Functions/send-stock-voucher` was still the historical distributed implementation. It directly:

- read voucher state;
- resolved a source branch;
- read stock;
- updated `stock_branches.qty` directly;
- wrote `inventory_log` directly;
- then updated voucher status.

The historical repository contains the same implementation. This violated the active One-Core rule because the Edge Function was acting as a physical stock business engine.

### Production truth
Production `send-stock-voucher` version 7 is already a thin adapter:

`HTTP → auth → company context → send_stock_voucher_atomic → response`

The deployed `send_stock_voucher_atomic`:

- locks the voucher with `FOR UPDATE`;
- requires Draft state;
- validates supported movement types;
- validates source branch company context;
- groups voucher details by item;
- validates item/company context;
- calls `post_stock_movement` for each physical movement;
- uses a deterministic idempotency key per voucher/item;
- changes voucher state to Sent only after movement processing succeeds.

`post_stock_movement` is the central physical stock writer and writes `inventory_log` atomically with the stock mutation.

### Surgical patch applied
Current source was replaced with the verified Production adapter contract.

Changed file:
`Current/Edge_Functions/send-stock-voucher`

Branch commit:
`8252f2deea26fa9ce861be35c07c4192fd6c1426`

This is a source-of-truth alignment patch. It does not modify Production because Production is already on the correct adapter implementation.

### SEND LOSS / GAIN MATRIX

| Responsibility | Result |
|---|---|
| HTTP/auth contract | RETAINED |
| Company context | HARDENED |
| Voucher Draft gate | MOVED to atomic Core |
| Source-branch validation | MOVED to atomic Core |
| Stock availability validation | MOVED to `post_stock_movement` |
| Physical stock update | MOVED to central Core |
| Inventory log | MOVED to central Core |
| Idempotency | ADDED via deterministic voucher/item key |
| Voucher status transition | MOVED to atomic Core |
| Direct Edge stock writes | INTENTIONALLY REMOVED |
| Legacy parallel business engine | ELIMINATED from Current adapter |

## CURRENT REALITY MATRIX

| Closure Unit | Current source | Production | Target | Status |
|---|---|---|---|---|
| `complete-picking` | Thin Core adapter | Version 13, runtime verified | Core reservation only | **100% CLOSED** |
| `send-stock-voucher` | Patched thin adapter on rescue branch | Version 7, runtime verified | Central movement engine | **PATCHED / REVIEW GATE** |
| `receive-stock-voucher` | Existing Current source requires next reconciliation | Production version 5 | Core-only movement | QUEUED |
| `receive-purchase` | Existing Current source | Production version 9 | Central movement engine | QUEUED |
| `bulk-stock-adjustment` | Existing Current source | Production version 5 | Central movement engine | QUEUED |
| `save-sales-invoice` | Existing Current source | Production version 13 | Central movement engine | QUEUED |
| `complete-return` | Existing Current source | Production version 23 | Central movement engine | QUEUED |
| `complete-order-delivery` | Existing Current source | Production version 11 | Contract reconciliation required | QUEUED |

## ZERO-DEBT CLOSURE QUEUE

1. `complete-picking` — **CLOSED**.
2. `send-stock-voucher` — **PATCHED; review and verification gate next**.
3. `receive-stock-voucher`.
4. `receive-purchase`.
5. `bulk-stock-adjustment`.
6. `save-sales-invoice`.
7. `complete-return`.
8. `complete-order-delivery`.
9. GLOBAL PHYSICAL STOCK WRITER SWEEP.
10. Only then proceed to Accounting.

No later unit is declared closed by this document.

## PRODUCTION REALITY CLASSIFICATION

- `complete-picking`: **PRODUCTION RUNTIME VERIFIED / 100% CLOSED**.
- `send-stock-voucher` Production implementation: **PRODUCTION RUNTIME VERIFIED**.
- `send-stock-voucher` Current-source alignment: **CURRENT SOURCE PATCHED ON RESCUE BRANCH**; not yet merged to `main`.
- No Production deployment was performed by this reconciliation/patch step.

## CLEANUP VERIFICATION

Production cleanup verification after the complete-picking canary found:

- `CP-PROD-CANARY-*` runsheets remaining: 0
- `CP-PROD-CANARY-*` orders remaining: 0
- `CP-PROD-CANARY-*` inventory_log rows remaining: 0

No permanent canary business-data debris remains under that identifier.

## END-OF-REPORT SELF-AUDIT

| Gate | Final classification |
|---|---|
| Evidence hierarchy respected | YES |
| Production distinguished from Git/current source | YES |
| Original compared before declaring loss | YES |
| Complete-picking Root Cause understood | YES |
| Complete-picking Production runtime verified | YES |
| Complete-picking closed without false 100% | YES |
| Send-stock-voucher duplicate business engine removed from Current | YES |
| Production mutated by this patch | NO |
| Unverified Production concurrency claimed | NO |
| Unknowns hidden | NO |
| Later Closure Units prematurely closed | NO |

**Final execution state: COMPLETE-PICKING CLOSED → SEND-STOCK-VOUCHER PATCHED → CONTINUE TO SEND REVIEW/VERIFICATION → RECEIVE-STOCK-VOUCHER.**
