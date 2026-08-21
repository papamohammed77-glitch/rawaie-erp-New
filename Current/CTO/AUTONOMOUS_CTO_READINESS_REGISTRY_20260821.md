# RAWAEA ERP — AUTONOMOUS CTO READINESS REGISTRY
## Snapshot: 2026-08-21

### Authority
This registry implements the `MASTER RAWAEA ERP — AUTONOMOUS CTO READINESS & CONTINUITY DIRECTIVE` and must be re-baselined from Production before each major phase.

### Current Production snapshot
- Production project: SMART ERP / `fiilmooggumokxanwiyx`
- PostgreSQL: 17.6.x
- Snapshot UTC: 2026-08-21 01:19:06
- Public functions observed: 42
- Public Edge Functions observed: current production inventory available directly from Supabase
- Companies: 3
- Users: 26
- Branches: 5
- Items: 50
- stock_branches: 26
- inventory_log: 62
- journal_entries: 2
- journal_lines: 0
- customer_ledger: 0
- supplier_ledger: 0
- driver_ledger: 0
- daily_settlements: 0
- treasury: 1
- chart_of_accounts: 87

## Readiness matrix
| Domain | Evidence Status | Current Reality | Material Unknowns | Status |
|---|---|---|---|---|
| Production Forensics | VERIFIED | Current schema/functions/Edge/data snapshot captured directly | Continuous refresh required | VERIFIED |
| PostgreSQL Core | VERIFIED for Inventory/Voucher/Fulfillment subset | Critical RPCs inspected, SECURITY DEFINER/search_path and grants checked | Full ERP-wide function semantics not yet complete | OPEN |
| Inventory Architecture | VERIFIED | `post_stock_movement(10)` is sole physical writer; reservation separated | None material for current inventory core | VERIFIED |
| Reservation | VERIFIED | `reserve_stock` / `release_stock_reservation` mutate allocated_qty only | Full reverse-lifecycle matrix still required | VERIFIED |
| Voucher Core | STRONG | create/post/send/receive/complete/cancel surfaces exist; legacy V2 execution disabled | Full UI/runtime parity and all historical contracts | OPEN |
| Fulfillment | PARTIAL | orders/order_details/runsheets/picking/loading/delivery/returns/unloading RPCs exist | Complete cross-stage state/consumer graph not yet proven | OPEN |
| Accounting | OPEN | COA 87 rows; journal_entries 2; journal_lines 0; no current public function discovered that directly writes journal tables | Posting contract, accounting event ownership, COGS/revenue/returns/purchase mapping | OPEN |
| Ledgers | OPEN | customer/supplier/driver ledgers exist but current row counts are zero | Writer ownership, event-to-ledger contract, reconciliation, balance semantics | OPEN |
| Treasury/Settlement | OPEN | treasury exists (1 row); daily_settlements exists (0 rows); save-daily-settlement Edge is deployed | End-to-end cash/settlement contract and ledger linkage | OPEN |
| Identity/Tenant | STRONG | 3 companies; company-scoped RLS patterns verified in Production | Full cross-domain auth/role/permission graph | OPEN |
| Security | STRONG for reviewed domains | RLS enabled on core tables; critical RPC grants constrained; SECURITY DEFINER/search_path verified | Full role/permission matrix for all critical functions | OPEN |
| Consumers | PARTIAL | Critical inventory/voucher/picking consumers known; many Edge versions current | Complete UI→Edge→RPC→DB consumer graph | OPEN |
| Deployment Lineage | PARTIAL | Production Edge versions and Git current state available | Full commit→artifact→deployment→runtime chain for every critical component | OPEN |
| Historical Reconstruction | STRONG | Original/Current/review history used and stale reports re-baselined | Full ERP-wide decision history | OPEN |
| Data Repair Engineering | PARTIAL | Inventory forensic checks and historical anomalies identified/classified | ERP-wide provenance/repair/reconciliation registry | OPEN |
| Concurrency Engineering | PARTIAL | Row locks/CAS/idempotency proven in critical cores | Independent-session race proof for all required paths | OPEN |
| Runtime / Browser E2E | PARTIAL | Several Production Core/runtime tests exist | Complete browser/client E2E coverage | OPEN |
| Global Zero-Debt | OPEN | Inventory physical-writer zero-debt closed | Journal writers, ledger writers, duplicate engines, consumer drift, deployment residue | OPEN |
| Autonomous CTO Readiness | NOT READY | Strong Inventory/Core forensic capability, insufficient ERP-wide closure | Material unknowns remain | NOT READY |

## Critical facts re-proven
1. `post_stock_movement(10)` is the only Production physical stock writer.
2. Legacy 9-argument `post_stock_movement` remains as a DB object but is not executable by application/service roles.
3. Reservation is isolated in `reserve_stock` / `release_stock_reservation`.
4. `items.item_code` is globally UNIQUE (`items_item_code_key`).
5. Production target stock-row initialization is now supported atomically by the central movement engine for inbound targets.
6. DirectSale target semantics now route to vehicle stock context in current Production Voucher Core.
7. Legacy Manual Voucher V2 send/receive execution is disabled for application execution roles.

## Material open work
- Accounting contract and central journal ownership.
- Ledger writer discovery and event mapping.
- Fulfillment-wide dependency/state graph.
- Full consumer map.
- Deployment lineage map.
- Data repair/reconciliation registry.
- Independent-session concurrency proof where required.
- Voucher UI full original/current/production/runtime parity.
- Global zero-debt sweep outside Inventory.

## Autonomous Gate
AUTONOMOUS CTO READY = **NO**

Reason: ERP-wide material unknowns and open domain contracts remain.
