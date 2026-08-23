# PRODUCTION CHANGE LEDGER

## Snapshot authority
Current direct Production snapshot: 2026-08-23 03:27:59 UTC.

## Confirmed Production change families
| Area | Production fact | Classification |
|---|---|---|
| Central inventory | `post_stock_movement(10)` is the physical movement boundary; 9-arg compatibility object remains but is not executable by app/service roles | CONFIRMED |
| Reservation | `reserve_stock` / `release_stock_reservation` mutate allocation state only | CONFIRMED |
| Manual vouchers | CREATE/SEND/RECEIVE/Complete/Cancel canonical RPC surfaces exist; legacy V2 execution grants were revoked for application roles | CONFIRMED by 2026-08-20 sweep |
| Purchase receive | Persisted UUID operation identity and replay handling recorded as closed | CONFIRMED by 2026-08-20 sweep |
| Loading | MAIN→VAN via central movement Core; cycle identity persisted | CONFIRMED by deployed definitions |
| Reopen loading | Reverses prior loading, creates a new loading cycle | CONFIRMED by deployed definition |
| Unloading | VAN→MAIN via central movement Core | CONFIRMED by deployed definition |
| Picking | Reservation-only; physical qty unchanged; Core uses `reserve_stock` | CONFIRMED by current Production definition |
| Start picking | Production v14 ACTIVE; auth user → public.users → company_id → company-scoped runsheet | CONFIRMED |

## Current Edge versions revalidated from Production registry
- start-picking v14
- complete-picking v13
- start-loading v4
- complete-loading v10
- reopen-loading v2
- unload-runsheet v5
- cancel-loading v5
- send-stock-voucher v7
- receive-stock-voucher v5
- receive-purchase v9
- bulk-stock-adjustment v5
- save-sales-invoice v13
- complete-return v23
- complete-order-delivery v11
- create-runsheet v22
- setup-van-branch v1

## Governance residue
Production registry still contains several temporary/canary functions, including `cp-prod-auth-canary-20260814`, `cp-prod-fixture-canary-20260814`, `start-picking-production-harness`, and `start-picking-e2e-fixture-20260815`. They may be inert, but ACTIVE registry presence is not deletion. This remains OPEN governance evidence.

## Snapshot drift
2026-08-20 inventory_log=56; 2026-08-21 inventory_log=62; 2026-08-23 inventory_log=3. Treat these as separate snapshots; provenance/reconciliation is required before interpreting the change.
