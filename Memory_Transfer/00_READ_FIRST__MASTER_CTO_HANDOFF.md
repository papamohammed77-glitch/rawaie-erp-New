# RAWAEA ERP — MASTER CTO HANDOFF

## Handoff snapshot
- Snapshot UTC: 2026-08-23 03:27:59
- Production: `fiilmooggumokxanwiyx` / SMART ERP
- PostgreSQL: 17.6
- Current active source: `rawaie-erp-New`
- Historical/reference source: `rawaie-erp-review`

## Truth hierarchy
1. Direct Production runtime/schema/RPC/Edge/auth/data evidence
2. Current Git canonical source
3. Current architecture/evidence/CTO records
4. Historical/original contracts
5. Historical reports/prompts

Production is current truth. Git is source truth only for code lineage. A migration/report never proves deployment.

## Current verified position
- Inventory physical-writer boundary is documented as CLOSED by the 2026-08-20 sweep: `post_stock_movement` is the sole physical stock writer; `reserve_stock`/`release_stock_reservation` are reservation-only; no stock trigger writer was found.
- Production current counts at this handoff: companies 3; users 26; branches 5; items 50; stock_branches 26; inventory_log 3; journal_entries 2; journal_lines 0; customer_ledger 0; supplier_ledger 0; driver_ledger 0; daily_settlements 0; treasury 1; chart_of_accounts 87.
- Current direct Production PostgreSQL public-function count = 45. This supersedes the older 2026-08-21 snapshot of 42 and is recorded as drift.
- `start-picking` Production is v14 ACTIVE. Current Git source currently differs in identity lookup (`auth_id` vs Production v14 `id`). This is a real Git/Production parity conflict.
- `complete-picking` Production is v13 ACTIVE.
- TASK-028 PR #3 remains open/draft/unmerged; its body still lists historical remaining gates. Do not use its stale gate text as current Production truth without revalidation.
- ERP-wide readiness is NOT READY: accounting, ledgers, fulfillment graph, consumer map, deployment lineage, data repair, concurrency coverage, and global zero-debt outside the closed inventory writer boundary remain open in the 2026-08-21 readiness registry.

## Immediate execution discipline
One Closure Unit at a time. Do not treat a report as execution. For behavior changes: UNDERSTAND → RECONCILE → TARGET → PATCH → TEST → DEPLOY → PRODUCTION VERIFY → CLOSE.

## First 10 checks for a successor CTO
1. Query current Production timestamp and PostgreSQL version.
2. Count critical tables and compare with this snapshot.
3. List deployed Edge Functions and versions.
4. Re-read critical deployed RPC definitions.
5. Identify current physical stock writers.
6. Verify reservation writers separately.
7. Read Current source for the active Closure Unit.
8. Read Historical/Original for the same unit.
9. Read its current consumer(s).
10. Compare new evidence with this handoff and register drift before acting.

## Critical warning
This package is institutional memory, not a substitute for Production verification. Any contradiction with current Production must remain recorded and must not be silently normalized.
