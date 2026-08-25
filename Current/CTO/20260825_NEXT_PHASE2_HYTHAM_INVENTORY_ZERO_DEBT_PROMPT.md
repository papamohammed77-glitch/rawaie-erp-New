# PHASE 2 — HYTHAM EXECUTION DIRECTIVE
# GLOBAL INVENTORY ZERO-DEBT — CONTROLLED PARALLEL TRACK

## Authority

Production PostgreSQL > Current main > Current CTO evidence > historical sources > reports.

## Why this track is authorized

Phase 1 COA recovery remains OPEN because the exact historical 87-row dataset is unavailable.

Inventory does not depend on recovering those historical COA rows. Therefore this is a dependency-aware parallel technical track; it does NOT declare Phase 1 closed.

## First gate — fresh baseline

Before any change:

1. Re-query Production.
2. Record timestamp.
3. Record current `main` HEAD.
4. Record Edge versions for all inventory consumers.
5. Record all public functions that mention `stock_branches` or `inventory_log`.
6. Record current open debt.

## Immutable Inventory Contract

PHYSICAL MOVEMENT
→ `post_stock_movement`
→ `stock_branches` + `inventory_log`

Reservation is separate:

`reserve_stock` / `release_stock_reservation`
→ reservation state only.

No parallel Physical Stock engine is allowed.

## Closure-unit order

1. GLOBAL WRITER DISCOVERY
2. Manual Voucher
3. Purchase Receiving
4. POS
5. Van Sales
6. Returns
7. Loading
8. Unloading
9. Inventory Adjustment
10. Picking / Reservation

Do one closure unit at a time. Do not mix unrelated repairs.

## For every closure unit

Record:

- Historical contract
- Original implementation
- Current Git implementation
- Production implementation/version
- Consumer(s)
- Physical movement responsibility
- Inventory-log responsibility
- Reservation responsibility
- Order-detail responsibility
- Runsheet responsibility
- Company/Tenant identity
- Item identity
- Idempotency
- Audit
- Direct DML
- Current runtime evidence
- Required fix
- Test evidence
- Deployment/version
- Production runtime verification
- Rollback/cleanup
- Closure status

## Mandatory discovery queries

Find every Production function/trigger that:

- modifies `stock_branches.qty`;
- modifies Physical Stock by another path;
- writes `inventory_log`;
- implements Transfer/Sale/Return/Purchase/Adjustment/Loading/Unloading.

Then cross-reference:

- Current Git
- all reachable migrations
- `Current/Edge_Functions`
- deployed Edge versions
- PWA consumers
- legacy/archive paths

## Tenant / Item Identity

Every lookup must respect the proven identity contract.
Do not introduce global lookup where company scope is required.
Do not reinterpret globally unique `item_code` as company-scoped if Production schema proves global uniqueness; use the actual schema contract.

## Source of truth

Do not dual-write `run_sheet_details` when the authoritative fulfillment contract belongs to `order_details` unless direct evidence proves otherwise.

## Legacy closure

A legacy function may be retired only after:

1. consumer discovery;
2. Production reachability/grant proof;
3. replacement path proven;
4. migration/disablement recorded;
5. post-change Production verification.

Do not delete a legacy capability merely because it looks obsolete.

## Runtime rule

SQL existence is not runtime proof.

For each critical writer, where safely possible, prove:

Authenticated HTTP
→ Edge
→ RPC/Core
→ DB
→ inventory/audit

Then:

same request twice
→ no duplicate

and, when a safe fixture exists:

two concurrent sessions
→ no double movement / lost update.

## Production mutation rule

Functional fixes are authorized only after the closure unit is understood and the exact responsibility transfer is proven.

Do not create a broad refactor that combines multiple closure units.

## Required deliverables

1. `Current/CTO/20260825_HYTHAM_PHASE2_GLOBAL_INVENTORY_WRITER_MATRIX.md`
2. one closure record per repaired writer
3. migration(s) for each production change
4. current Edge source synchronization where required
5. runtime evidence
6. updated Open Debt Register
7. final Phase 2 self-audit

## Success condition

`Physical Writers outside post_stock_movement = 0`

plus:

- Tenant integrity
- Item identity integrity
- Idempotency
- Audit coverage
- Current Git/Production alignment
- Production runtime verification

Only then may the Phase 2 global inventory closure be certified.

## Forbidden

- No COA mutation
- No Treasury mutation
- No fabricated master data
- No security weakening
- No report-only closure
- No bulk multi-writer patch without independent closure evidence
