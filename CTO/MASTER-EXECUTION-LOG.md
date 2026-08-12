# RAWAEA ERP — CTO MASTER EXECUTION LOG

## Purpose
Central tracking record for the Inventory / Vouchers / Van Sales rescue plan.

## Operating Rule
Every Task records: Task ID → objective → evidence reviewed → findings → decision → implementation status → tests → Gate → next Task.

No task may silently overwrite a previous conclusion. Corrections must be appended with date/time and evidence reference.

## Approved Decomposition
- Phase A — Truth Baseline
  - TASK-001 Project Baseline — COMPLETE / GO
  - TASK-002 Inventory Data Contract — COMPLETE / GO
  - TASK-003 Voucher Data Contract
  - TASK-004 Production RPC Contract — COMPLETE / GO
- Phase B — Movement Understanding
  - TASK-005 Voucher State Machine — COMPLETE / GO
  - TASK-006 Inventory Movement Matrix
  - TASK-007 Custody Matrix
  - TASK-008 Movement Types Contract
- Phase C — Critical Risks
  - TASK-009 Partial Receive Contract
  - TASK-010 Idempotency Contract
  - TASK-011 Concurrency Contract
  - TASK-012 Atomic Transaction Contract
- Phase D — Inventory Core
  - TASK-013 Stock Engine Design
  - TASK-014 Stock Engine Implementation
  - TASK-015 Stock Engine Tests
  - TASK-016 Stock Engine Gate
- Phase E — Manual Vouchers
  - TASK-017 through TASK-024
- Phase F — vouchers.html
  - TASK-025 through TASK-027
- Phase G — Loading / Unloading
  - TASK-028 through TASK-032
- Phase H — Van Sales
  - TASK-033 through TASK-038
- Phase I — Edge Functions
  - TASK-039 through TASK-044
- Phase J — Accounting / Audit / Security
  - TASK-045 through TASK-049
- Phase K — Final Verification / Production
  - TASK-050 through TASK-055

## CTO Working Method
- One Stage = one coherent execution unit → one comprehensive verification → one decision → next Stage.
- Do not subdivide simple stages artificially; split only for real safety, evidence, concurrency, or dependency isolation.
- No guessing.
- No repeating valid evidence already proven.
- Query comprehensive evidence for the stage in one pass whenever practical.
- Verify the complete stage in one pass whenever practical.
- Once proven, close it and move forward immediately.
- Documentation supports durable evidence and decisions; it must not become a substitute for implementation or measurable progress.
- Optimize for the shortest safe route to implementation, validation, and release.

## Constitutional Principles Carried Forward
1. Diagnose critical findings in context, not isolation.
2. Broad RLS is not automatically a defect.
3. Authentication ≠ authorization.
4. Target-required business operations are atomic.
5. One business fact has one authoritative source of truth and one authoritative movement history.
6. Inventory mutations converge on one central controlled business engine.
7. Applications are event sources, not autonomous business systems or databases.
8. Preserve the current V1 one-company/multi-branch architecture unless explicitly changed by Target decision.
9. Repair the smallest coherent boundary; do not reopen unrelated domains.
10. No critical code change before Target reconciliation.
11. Preserve evidence classifications: PROVEN / STATIC ONLY / KNOWN-REVIEW / UNKNOWN / TARGET DECISION REQUIRED.
12. Production Schema + Persisted Evidence + Actual Deployed Definitions outrank assumptions, names, migrations, and historical code.
13. Important read-only Production evidence must be persisted to prevent duplicate queries.
14. Lifecycle responsibility for state, physical stock, history, audit, and closure must be explicit and non-duplicated.
15. Treat validation infrastructure as Production infrastructure; control test data deliberately.
16. Protect the business first, simplify operational work second, and never sacrifice one for the other.
17. Anti-loop: do not create documentation or analysis cycles after a decision is sufficiently proven; move to execution.

## Current State
### TASK-001
Status: COMPLETE / GO.
Baseline established with explicit separation of Production Evidence, Current Source, Legacy/Historical material and Target/Unreleased candidates.

### TASK-002
Status: COMPLETE / GO.
Production Inventory Data Contract closed from EVIDENCE-015 and its split result files.

Confirmed:
- `stock_branches.qty` is the current physical stock balance.
- `stock_branches.allocated_qty` is reserved stock and is not itself a movement.
- `stock_branches.available_qty` is a database-generated column: `qty - allocated_qty`.
- `stock_branches` is unique on `(branch_id,item_id)` and references `branches` and `items`.
- `inventory_log` is the historical movement record, not the current stock balance.
- `inventory_log.branch_id` is absent from the captured Production schema.
- Inventory/Voucher PKs, relevant FKs, unique constraints and Production indexes are now captured.
- A Production audit trigger exists on `stock_vouchers`.
- Inventory Core view/materialized-view dependency query returned no rows.

Residual items are intentionally deferred:
- movement-type enforcement → TASK-008
- Voucher lifecycle → TASK-003 / TASK-005
- RPC behavior → TASK-004
- concurrency/idempotency → TASK-010 / TASK-011
- RLS/security hardening → TASK-049

## TASK-004 — Production RPC Contract
**Status: COMPLETE / GO.**

### Persistent fixture
- company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
- source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
- target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
- item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
- quantity `1`
- voucher `IN-1`
- voucher id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`
- reference `TEST-004-PERSISTENT`

### TEST-004
**CREATE → SEND → COMPLETE → FINAL VERIFICATION = PASS**

Confirmed:
- CREATE returned `success=true` and persisted `Draft`.
- SEND changed `Draft → Sent` and populated `sent_date`.
- BR-01/item 1004 changed `qty 206 → 205`.
- `allocated_qty` remained `0`.
- `available_qty` became `205`.
- Exactly one `inventory_log` row exists for `IN-1`: `DirectSale`, qty `1`, user `test-operator@rawaea.local`.
- COMPLETE populated `completed_at` and `completed_by` and produced no second inventory movement.
- Final verification: `IN-1 = Completed`, `completed_by = test-operator@rawaea.local`, `completed_at = 2026-08-12 16:47:45.437064+00`, BR-01/item 1004 `qty=205`, `allocated_qty=0`, `available_qty=205`, detail `qty=1`, `received_qty=0`, one inventory log, final summary `STAGE 4 PASS`.

### TASK-004 Gate
**CLOSED / GO TO TASK-005.**

The controlled lifecycle assigned to TEST-004 is empirically proven. Broader unresolved questions such as alternate SEND consumers, Partial Receive idempotency, DirectSale/DirectReturn target semantics, and broader security/audit reconciliation remain in their designated Tasks and are not reopened here.

No Production patch was approved or applied by TASK-004.

## TASK-005 — Voucher State Machine
**Status: COMPLETE / GO.**

### Production evidence
Final lifecycle RPC definitions were captured for:
- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`

### Confirmed state machine
```text
CREATE → Draft

Draft ──CANCEL──> Cancelled
  │
  └──SEND──> Sent
              ├── DirectSale / SupplierReturn ──COMPLETE──> Completed
              └── Transfer / DirectReturn ──RECEIVE──>
                    ├── partial → Sent (received_qty increases)
                    └── complete → Received ──COMPLETE──> Completed
```

### Confirmed transition rules
- CREATE accepts `Transfer`, `DirectSale`, `DirectReturn`, `SupplierReturn` and creates status `Draft`.
- SEND requires `Draft`.
- `post_manual_stock_voucher_atomic` SEND accepts `Transfer`, `DirectSale`, `SupplierReturn` and performs an outbound stock effect from the voucher source branch before setting `Sent`.
- RECEIVE accepts `Transfer`, `DirectReturn`, requires `Sent`, and rejects over-receive above the remaining detail quantity.
- Partial RECEIVE leaves status `Sent` and increments `received_qty`; full RECEIVE changes status to `Received` and populates `received_date`.
- COMPLETE requires `Sent` for `DirectSale`/`SupplierReturn` or `Received` for `Transfer`/`DirectReturn`; it sets `Completed`, `completed_at`, `completed_by` and performs no stock mutation.
- CANCEL requires `Draft`; it changes status to `Cancelled` and performs no stock mutation. It does not reverse a completed/sent movement.

### State / mutation boundary
- Outbound physical stock movement occurs during SEND.
- Inbound physical stock movement occurs during RECEIVE.
- `allocated_qty` is not modified by the captured voucher lifecycle RPCs.
- COMPLETE is administrative closure only.
- CANCEL is administrative cancellation only while Draft.
- Partial Receive idempotency and concurrency are intentionally deferred to TASK-009/010/011.

### TASK-005 Gate
**TASK-005 CLOSED / GO TO TASK-006.**

## Evidence
EVIDENCE-015 — Full Production Schema Dependency Closure.
Status: REVIEWED / ACCEPTED for TASK-002.
Result files are stored under `SQL_Evidence/diagnostics/` as split result sets 1–10 where available.

## Next Task
**TASK-006 — Inventory Movement Matrix**

## Event Log
2026-08-11 — TASK-001 completed; Project Baseline established.
2026-08-11 — TASK-002 started; Production inventory contract reviewed.
2026-08-11 — Evidence gap identified; EVIDENCE-015 required before any schema/movement decision.
2026-08-11 — EVIDENCE-015 SQL prepared for user execution.
2026-08-11 — EVIDENCE-015 result set reviewed from `SQL_Evidence/diagnostics/`.
2026-08-11 — TASK-002 closed COMPLETE / GO. Inventory Data Contract frozen from Production Evidence.
2026-08-12 — TEST-004 persistent fixture created: `IN-1` / `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`.
2026-08-12 — TEST-004 Stage 2 SEND passed: `Draft → Sent`, BR-01 qty `206 → 205`, one DirectSale inventory log.
2026-08-12 — TEST-004 Stage 3 COMPLETE passed.
2026-08-12 — TEST-004 Stage 4 final verification passed.
2026-08-12 — TASK-004 CLOSED / GO TO TASK-005.
2026-08-12 — TASK-005 Production State Machine evidence captured; CREATE/SEND/RECEIVE/COMPLETE/CANCEL transitions proven.
2026-08-12 — TASK-005 CLOSED / GO TO TASK-006.
