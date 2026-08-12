# RAWAEA ERP — CENTRAL CTO EXECUTION LOG

## Purpose
Mandatory chronological record of tasks, evidence, decisions, tests, gates, and unresolved conflicts.

## Control rule
No task is considered complete unless its evidence, decision, implementation status, test status, rollback status, and gate are recorded here or in a linked durable task report.

---

## CTO WORKING METHOD — CURRENT OPERATING STANDARD

### Execution rhythm
**One Stage = one coherent execution unit → one comprehensive verification → one decision → next Stage.**

Do not subdivide a Stage into artificial sub-stages merely to make an already-small task look smaller. Break a Stage only when real safety, evidence, concurrency, or dependency isolation requires it.

### Working principles
- No guessing.
- No repeating evidence already proven and still valid.
- Query the full evidence needed for the stage in one comprehensive pass whenever practical.
- Execute the stage as one coherent operation wherever safe.
- Verify the complete stage result in one comprehensive pass.
- Once proven, close the Stage and move forward immediately.
- Do not reopen closed work unless newer authoritative evidence contradicts it.
- Do not turn simple work into a documentation or analysis loop.
- Decompose only genuine complexity; never decompose for its own sake.
- Optimize for measurable progress toward implementation, validation, and release.

### Constitutional principles carried forward
1. Do not diagnose critical findings in isolation; reconcile architecture, security, authorization, source-of-truth, workflow, Production schema evidence, equivalent functions/apps, and historical warnings.
2. Broad RLS is an observed fact, not proof of a defect by itself.
3. Authentication is not authorization; business-operation authorization and database integrity are separate controls.
4. Target-required business operations must be atomic.
5. One business fact must have one authoritative source of truth and one authoritative movement history.
6. Inventory mutations converge on one central controlled business engine; adapters are not competing business engines.
7. Applications are operational event sources, not autonomous business systems or databases.
8. Preserve the current V1 one-company/multi-branch architecture unless an explicit Target decision changes it.
9. Repair the smallest coherent boundary; do not reopen unrelated domains.
10. No critical code change before Target reconciliation against Original, Current, schema evidence, equivalent functions, and Architecture.
11. Evidence classification remains explicit: PROVEN / STATIC ONLY / KNOWN-REVIEW / UNKNOWN / TARGET DECISION REQUIRED.
12. Documentation must support decisions and safe execution, never replace measurable progress.
13. Production Schema + Persisted Evidence + Actual Deployed Definitions outrank assumptions, names, migrations, and historical code.
14. Important Production read-only evidence is persisted so the same diagnostic is not repeatedly requested.
15. Lifecycle responsibility is explicit: state, physical stock, history, audit, and administrative closure must not be duplicated across stages.
16. Treat the validation database as production infrastructure; use controlled test data and avoid unnecessary contamination.
17. Protect the business first, simplify operational work second, and never achieve one by sacrificing the other.
18. A task is not considered Production-implemented merely because a report, migration, or candidate file exists in GitHub; executable changes require actual target-system execution and direct verification.
19. Contract/evidence tasks are closed from authoritative Production evidence; implementation/test tasks are closed only from actual execution evidence.
20. Every execution stage must be verified against the actual target system; repository artifacts alone never establish Production implementation.

---

## TASK-004 — Production RPC Contract / Manual Voucher Send Path
**Status: COMPLETE — GO TO TASK-005**

### Confirmed evidence captured
- `create_manual_stock_voucher_atomic(uuid,text,text,text,uuid,text,uuid,text,text,jsonb)` is `SECURITY DEFINER` and creates a `Draft` Manual Voucher.
- `complete_manual_stock_voucher_atomic(uuid,text,text)` is `SECURITY DEFINER` and transitions `Sent` → `Completed` for `DirectSale`/`SupplierReturn`, and `Received` → `Completed` for `Transfer`/`DirectReturn`.
- COMPLETE writes `completed_by` and `completed_at`.
- Production inventory RPC evidence includes both `send_stock_voucher_atomic(uuid,text,text)` and `post_manual_stock_voucher_atomic(uuid,text,text,text,jsonb)` with `SEND` / `RECEIVE` operations.
- The earlier transactional fixture `IN-1` (`4062e2c6-f683-4a9c-bdc9-89705dbc7a7e`) was confirmed absent after its transaction ended.
- A persistent fixture was created outside `BEGIN/ROLLBACK`:
  - company `da4ef704-88ac-4120-aa0e-65b92b2aa2bc`
  - source `BR-01` / `151e5cd7-ac4a-4fc3-b703-d73a0dbb0dc6`
  - target `BR-2` / `a08568e5-40a7-4b15-85b4-ced8ebf9971d`
  - item `1004` / `ef864b14-ec62-4b9f-9932-17da041b6e42`
  - quantity `1`
  - voucher `IN-1`
  - voucher id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`
  - reference `TEST-004-PERSISTENT`
  - notes `TEST-004 PERSISTENT FIXTURE`

### TEST-004 results

#### STAGE 1 — CREATE
**PASS**
- RPC returned `success=true`.
- Voucher `IN-1` was created and persisted in `Draft` state.

#### STAGE 2 — SEND
**PASS**
- `IN-1` transitioned `Draft → Sent`.
- `sent_date` populated.
- BR-01 / item 1004: `qty 206 → 205`.
- `allocated_qty` remained `0`.
- `available_qty` became `205`.
- Exactly one `inventory_log` row was produced: `DirectSale`, quantity `1`, user `test-operator@rawaea.local`.

#### STAGE 3 — COMPLETE
**PASS**
- COMPLETE moved the voucher to the required completed state for `DirectSale`.
- `completed_at` and `completed_by` were populated.
- COMPLETE produced no additional inventory movement; the voucher retained exactly one inventory-log row.

#### STAGE 4 — FINAL VERIFICATION
**PASS**
- Voucher `IN-1`: `Completed`.
- `completed_by = test-operator@rawaea.local`.
- `completed_at = 2026-08-12 16:47:45.437064+00`.
- BR-01 / item 1004: `qty=205`, `allocated_qty=0`, `available_qty=205`.
- Detail: item `1004`, `qty=1`, `received_qty=0`.
- Inventory history: one `DirectSale` movement, quantity `1`.
- Final summary: `STAGE 4 PASS`.

### TASK-004 closure decision
**TEST-004 PASS. TASK-004 CLOSED / GO.**

### Persistent fixture
Retained intentionally for subsequent controlled tests:
- voucher `IN-1`
- voucher_id `a0974ec8-a5d0-4339-a5fb-7d2d0cee1d64`

No automatic cleanup was performed.

### Production patch status
**None approved or applied by TASK-004.**

---

## TASK-005 — Voucher State Machine
**Status: COMPLETE — GO TO TASK-006**

Production definitions reviewed for CREATE / SEND / POST / COMPLETE / CANCEL.

Confirmed lifecycle:
```text
CREATE → Draft
Draft → Cancelled (Draft-only)
Draft → Sent (SEND)
Transfer / DirectReturn: Sent → partial Sent / full Received → Completed
DirectSale / SupplierReturn: Sent → Completed
```
COMPLETE is administrative closure and does not mutate stock. CANCEL is Draft-only and does not mutate stock.

---

## TASK-006 — Inventory Movement Matrix
**Status: COMPLETE — GO TO TASK-007**

The movement matrix was frozen from Production evidence plus explicitly classified historical evidence. `stock_branches.qty` is physical state, `allocated_qty` is reservation, `available_qty = qty - allocated_qty`, and `inventory_log` is movement history. Manual Voucher SEND/RECEIVE are the proven stock mutation points for the closed voucher paths; COMPLETE/CANCEL are administrative lifecycle actions.

---

## TASK-007 — Custody Matrix
**Status: COMPLETE — GO.**

Closed by commit `65dbb10a4af9a1da357a9f7a55a24cf668f0bc35` from reconciled evidence.

---

## TASK-008 — Movement Types Contract
**Status: COMPLETE — GO.**

Closed by commit `8b8c9d9d838b9eb9e50d115d3f199505c38a2108`.

---

## TASK-009 — Partial Receive Contract
**Status: COMPLETE — GO.**

Closed by commit `d6681a2f9aade9052548655b7b067811c9367373`.

---

## TASK-010 — Idempotency Contract
**Status: COMPLETE — FINDING / GO TO TASK-011.**

A transactional Production test executed:
`SEND 2 → RECEIVE 1 → repeat the same RECEIVE 1`.

### Result
**TASK-010 — NON-IDEMPOTENT PARTIAL RECEIVE PROVEN.**

The repeated partial RECEIVE was accepted as a second movement rather than being rejected/deduplicated by an independent operation identity. The transaction was rolled back. No idempotency patch was applied by TASK-010.

### Gate
**TASK-010 CLOSED.**

---

## TASK-011 — Concurrency Contract
**Status: COMPLETE — GO TO TASK-012.**

### Production Evidence
Production RPC definitions were captured from `pg_proc` for:
- `complete_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`

The captured evidence proves:
- `FOR UPDATE` row locking on the voucher path.
- `FOR UPDATE` row locking on stock rows in the atomic inventory path.
- Conditional/CAS-style stock updates using the previously-read `qty` and `allocated_qty` values.
- Voucher state transitions also use conditional current-state predicates.
- The production atomic path orders effects consistently before stock locking.

### Evidence classification
**PROVEN from actual deployed Production RPC definitions.**

### Gate
**TASK-011 CLOSED.**
Closed by commit `1a700dc1bfb264b282b0fee712801adf71a92a22`.

---

## TASK-012 — Atomic Transaction Contract
**Status: COMPLETE — GO TO TASK-013.**

### Production Test
A single transactional Production test was executed using only the previously-proven company/branches/item and the verified Production RPC path. The test performed:

`CREATE → SEND 2 → RECEIVE 1 → intentionally invalid RECEIVE 2 → full verification → ROLLBACK`.

The invalid RECEIVE attempted to exceed the remaining quantity. The transaction correctly rejected the invalid operation, and the comprehensive post-failure verification matched the expected pre-failure state. The complete test then rolled back.

### Result
**TASK-012 — ATOMIC TRANSACTION CONTRACT PASS.**

### Production impact
- No Schema change.
- No RPC change.
- No application change.
- No permanent test fixture created by TASK-012.
- Test data was rolled back.

### Closure classification
**Production execution VERIFIED. TASK-012 CLOSED / GO.**

### Gate
**Next: TASK-013 — Stock Engine Design.**

---

## TASK-013 — Stock Engine Design
**Status: COMPLETE — GO TO TASK-014.**

### Target Design Authority
The approved/active target design baseline is:
`TARGET — RAWAEA CENTRAL INVENTORY & STOCK MOVEMENT DESIGN`.
It explicitly establishes a single central Inventory Business Core represented by `post_stock_movement` as the authoritative physical stock posting boundary.

### Design contract confirmed
- Inventory movement is a domain operation and is not UI-owned.
- Applications express business intent; they do not implement independent stock mutation rules.
- `stock_branches.qty` is the physical stock truth.
- `stock_branches.allocated_qty` is reservation state and is separate from physical movement.
- `available_qty` is derived availability.
- `inventory_log` is the authoritative posted-movement history.
- Manual Voucher header and detail truth are `stock_vouchers` and `stock_voucher_details`.
- The central movement engine owns movement validation, availability checks, physical quantity mutations, movement logging, movement semantics, locking, and atomicity.
- Reservation is a separate operation and must not be folded into physical movement posting.
- Accounting remains a separate domain engine; this design does not invent Journal/Chart mappings.
- Runsheet remains a separate domain and does not own Manual Voucher semantics.
- `DirectSale` is custody loading to vehicle/representative, not the customer sale; `VanSale` consumes that custody; `DirectReturn` returns custody to warehouse.
- Each physical movement has one authoritative posting path and must generate exactly its corresponding inventory history record.
- `Complete` is administrative closure and must not cause a second physical stock mutation.

### Target movement boundary
The design freezes the central physical posting interface as the `post_stock_movement` boundary. It deliberately leaves `allocated_qty`, Accounting details, detailed Runsheet behavior, and unresolved Loading/Unloading semantics outside the engine contract where separate contracts are required.

### Implementation gate checked
The target design explicitly requires, before implementation: mapping all stock-writing Edge Functions, separating `qty` from `allocated_qty` writers, mapping `inventory_log` writers, mapping Voucher lifecycle functions, proving DirectSale/DirectReturn end-to-end, proving VanSale custody consumption separately, separating Runsheet ownership, mapping accounting effects, and verifying Atomicity/Concurrency. TASK-011 and TASK-012 now provide the Production evidence for the last two prerequisite contracts.

### Production / implementation status
**No production implementation was performed by TASK-013.** This Task is a design contract. No Schema, RPC, Edge Function, or PWA was modified by the task itself.

### Decision
**TASK-013 CLOSED / GO TO TASK-014.**
The Target Inventory Engine boundary is now fixed before coding. Any later implementation must conform to this design and must be separately verified in the actual target system.

---

## TASK-014 — Stock Engine Implementation
**Status: IN_PROGRESS — PRODUCTION EXECUTION REQUIRED.**

### Implementation artifact
Created:
`supabase/migrations/20260812_task014_post_stock_movement.sql`

Commit:
`170df08da029bf84c6fdf7a6743404e67bb0452c0`

### Implementation boundary
The artifact creates a new Production RPC with exact signature:
`public.post_stock_movement(uuid,text,uuid,uuid,uuid,numeric,text,text,text)`

The implementation is deliberately independent of the existing Voucher RPC consumers. It does **not** replace or modify `send_stock_voucher_atomic` or `post_manual_stock_voucher_atomic` and it does not alter schema.

### Production schema basis used
Persisted Production evidence confirms:
- `stock_branches(branch_id,item_id)` unique key.
- `stock_branches.qty` physical quantity.
- `stock_branches.allocated_qty` reservation quantity.
- generated `available_qty = qty - allocated_qty`.
- `inventory_log` fields used by the engine: `company_id`, `log_code`, `movement_date`, `voucher_id`, `item_id`, `item_code`, `item_name`, `movement_type`, `qty`, `reference`, `user_email`.

### Supported movement types in TASK-014
The implementation currently supports only movement semantics already unambiguous in the Target design:
- `PurchaseIn`
- `TransferOut`
- `TransferIn`
- `POSSale`
- `VanSale`
- `SalesReturn`
- `PurchaseReturn`
- `InventoryIncrease`
- `InventoryDecrease`

`Loading`, `Unloading`, and `Adjustment` are intentionally rejected until their separate event semantics are closed by their designated contracts. This is a safety boundary, not an inferred implementation.

### Engine invariants implemented
- Positive quantity only.
- Closed movement vocabulary.
- Company-context validation for branches and item.
- Required source/target branch validation by movement type.
- Source availability uses `qty - allocated_qty`.
- `allocated_qty` is never mutated.
- Stock row is locked with `FOR UPDATE`.
- Stock write uses conditional/CAS predicates.
- Exactly one corresponding `inventory_log` row is written per successful engine call.
- Stock mutation and inventory log are in the same database transaction boundary.
- `SECURITY DEFINER` with `search_path = public`.

### Current status
**NOT YET PRODUCTION-EXECUTED.**
Repository artifact exists; Production implementation is not considered complete until the SQL migration is actually executed against the target database and the embedded transactional verification returns successfully.

### Next required action
Execute the migration against the actual target database using the exact artifact, then return the final verification result. No Edge Function consumer is to be rewired until TASK-014 Production verification is PASS.
