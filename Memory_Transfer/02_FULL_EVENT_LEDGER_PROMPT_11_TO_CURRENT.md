# FULL EVENT LEDGER — PROMPT 11 TO CURRENT

## Certification status
`PARTIALLY RECONSTRUCTED`.

The Master Memory Transfer directive requires an individual event record for every Prompt/Report 11→45 plus 47/49/51/52 and all referenced anchors. Current retrieval during this handoff revalidated the governing ledgers and latest state, but the full individual prompt/report corpus has not yet been re-extracted one-by-one. Therefore this document must not claim complete prompt-level coverage.

## Durable execution milestones proven from current ledgers

### EVT-CORE-013/014 — Central Inventory Engine
- Target: centralize Physical Stock Movement in `post_stock_movement`.
- Production result: later closure sweep states sole physical writer = central engine.
- Historical rejected alternative: independent TransferOut/TransferIn draft calls.
- Current surviving contract: physical qty + inventory_log converge on central engine.

### EVT-VOUCHER-018..024 — Manual Voucher Core
- SEND, RECEIVE, Partial Receive, Complete, Cancel, Integration and Gate were recorded as Production-verified closure units in the execution ledger.
- Partial RECEIVE originally proved non-idempotent; later evidence recorded replay hardening.
- Manual Voucher V2 execution capability was later revoked for application roles.

### EVT-027 — DirectSale / VAN Custody
- DirectSale corrected from source-only deduction to two-sided MAIN→VAN custody movement.
- Vehicle and Representative are separate identities.
- Official vehicle/mobile branch baseline is preserved in the task ledger.

### EVT-STAGE28 — Loading / Unloading / Reopen
- Target: Loading MAIN→VAN; Reopen reverses Loading and starts a new `loading_cycle_id`; Reload uses new cycle; Unloading VAN→MAIN; no COGS at Loading/Reopen/Unloading.
- Production corrective migrations and deployed RPC definitions exist.
- PR #3 remains Draft/Open/Unmerged as of this handoff; its body is historical gate context and must be re-baselined against current Production.

### EVT-PICKING — Complete Picking / Start Picking
- Picking is reservation, not Physical Stock Movement.
- `complete_runsheet_picking` is a transactional Core function using `reserve_stock` and `order_details` authority.
- Production currently has `complete-picking` v13 and `start-picking` v14.
- `start-picking` v14 uses authenticated `public.users` identity/company context; current Git `start-picking` source differs and uses `auth_id`, creating a current Git/Production parity conflict that remains to be reconciled.

### EVT-2026-08-20 — Global Inventory Zero-Debt Sweep
- Production sweep states Physical Writers outside `post_stock_movement` = 0.
- Reservation and initialization were separated.
- Manual Voucher CREATE/SEND/RECEIVE, Purchase Receive idempotency, Return/Delivery company scope, and stock invariants were recorded as closed for the swept boundary.

### EVT-2026-08-21 — Autonomous CTO Readiness Rebaseline
- Inventory Core = VERIFIED.
- ERP-wide readiness = NOT READY.
- Open domains: accounting, ledgers, fulfillment graph, consumers, deployment lineage, data repair, concurrency coverage, global zero-debt outside inventory.

### EVT-2026-08-23 — Current Production Revalidation
- Production timestamp: 2026-08-23 03:27:59 UTC.
- Public PostgreSQL functions = 45, versus 42 in the 2026-08-21 snapshot.
- Inventory log rows = 3, versus 62 in the 2026-08-21 snapshot and 56 in the 2026-08-20 closure snapshot.
- These are current snapshot changes and are recorded as DRIFT; no causal explanation is assumed without provenance.

## Required future expansion
Every individual Prompt/Report from 11 through current must be indexed with the full EVENT RECORD schema from the Master Memory Transfer Directive. Any missing source stays `UNKNOWN/MISSING EVIDENCE`, never silently omitted.
