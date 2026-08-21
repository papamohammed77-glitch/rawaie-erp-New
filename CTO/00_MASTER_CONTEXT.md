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

## Governing CTO directives
- `doc/Draft/medhat/MASTER_CTO_CONTINUITY_DIRECTIVE_RAWAEA_ERP.md`
- `doc/Draft/medhat/MASTER_RAWAEA_ERP_AUTONOMOUS_CTO_READINESS_CONTINUITY_DIRECTIVE.md`
- Project-wide execution plan: `doc/Draft/Hussin/الخطة العامة الكبرى لـ RAWAEA ERP`

The Autonomous CTO Readiness directive is the mandatory readiness layer above ordinary continuity/forensics. It requires ERP-wide competency proof before any claim of autonomous CTO readiness.

## Project
Rawaea ERP is an FMCG/distribution ERP built around Supabase/PostgreSQL, Supabase Edge Functions, PWA clients, Offline-first storage, warehouse operations, runsheets, sales, purchasing, delivery, returns, settlement, accounting and ledgers.

The architecture principle is ONE CORE / ONE SOURCE OF TRUTH / controlled domain execution. The project-wide sequence remains Inventory → Accounting → Ledger → Sales/Purchasing → Fulfillment → Multi-Tenancy/Security → Consumers/Deployment → Regression/Zero-Debt, subject to current CTO stage evidence.

## Current rescue scope
Inventory / Manual Stock Vouchers / Van Sales, with Autonomous CTO Readiness expansion now requiring Accounting / Ledger / Fulfillment / Identity / Security / Consumer / Deployment / Data Repair / Concurrency evidence acquisition in parallel with authorized closure work.

The immediate objective is NOT to rewrite the ERP. It is to reconcile Production reality, current code, historical code, migrations and target business rules, then produce minimal safe changes with tests and deployment verification.

## Current Production re-baseline — 2026-08-21
- Production project ref: `fiilmooggumokxanwiyx` (`SMART ERP`).
- PostgreSQL 17.6.x.
- Snapshot UTC: `2026-08-21 01:19:06`.
- Companies: 3.
- Users: 26.
- Branches: 5.
- Items: 50.
- Stock branch rows: 26.
- Inventory log rows: 62.
- Journal entries: 2.
- Journal lines: 0.
- Customer ledger rows: 0.
- Supplier ledger rows: 0.
- Driver ledger rows: 0.
- Daily settlements: 0.
- Treasury rows: 1.
- Chart of accounts rows: 87.
- Current public PostgreSQL functions observed: 42.

## Inventory truth — current
- `post_stock_movement(10 args)` is the only Production physical stock writer.
- Legacy `post_stock_movement(9 args)` remains as a DB compatibility object but is not executable by application/service roles.
- `reserve_stock` and `release_stock_reservation` are reservation-only engines.
- `setup_van_stock` is initialization support, not a physical movement engine.
- No stock/inventory trigger writer was found.
- Target inbound stock rows can now be initialized atomically by `post_stock_movement` where the current contract requires it.
- `items.item_code` is globally UNIQUE (`items_item_code_key`); `item_id` is the authoritative item reference.

## Voucher truth — current
- Manual Voucher V2 send/receive execution is disabled for application execution roles.
- Current voucher Core includes canonical CREATE / POST / SEND / RECEIVE lifecycle paths.
- Current Production includes DirectSale target-to-vehicle-stock semantics.
- Current Production includes retry/idempotency hardening for Voucher operations.
- Full `vouchers.html` original/current/Production/runtime parity remains OPEN until independently proven.

## Historical records
Older sections/files may contain facts from 19–20 August that were correct at their snapshot but have since been superseded. They must be treated as HISTORICAL unless re-proven against the current Production snapshot.

Examples that are not automatically current anymore:
- earlier stock-voucher schema/contract statements,
- earlier DirectSale target assumptions,
- earlier Manual Voucher V2 execution availability,
- earlier Partial Receive idempotency gaps where later Production changes have superseded them.

## ERP-wide readiness status
The Inventory/Core forensic stream is strong and materially closed. Autonomous ERP-wide CTO readiness is **NOT READY** because the following remain open:
- Accounting contract and journal ownership.
- Ledger writers, event mapping and reconciliation.
- Complete Fulfillment dependency/state graph.
- Complete consumer graph and UI/runtime parity.
- Full deployment lineage.
- Data Repair/Reconciliation as a system-wide capability.
- Independent-session concurrency proof where required.
- Global zero-debt outside the closed Inventory writer boundary.

Current authoritative readiness artifacts:
- `Current/CTO/AUTONOMOUS_CTO_READINESS_REGISTRY_20260821.md`
- `Current/CTO/SYSTEM_DEPENDENCY_GRAPH_20260821.md`

## CTO working rule
No assistant may convert UNKNOWN / INFERRED / HISTORICAL / TARGET-CANDIDATE into CONFIRMED merely by repetition. Every production change must follow:

Evidence → Reconciliation → Target Decision → Minimal Patch → Tests → Review → Production GO → Read-only Post-Deploy Verification.
