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

The assigned controlled Production RPC contract test for the DirectSale `CREATE → SEND → COMPLETE` lifecycle is empirically proven with the persistent fixture. Alternate RPC consumers, Partial Receive idempotency, broader custody semantics, and other open architecture questions remain under their designated later Tasks and are not reopened here.

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

### Production lifecycle evidence reviewed
Production definitions were captured directly for:
- `create_manual_stock_voucher_atomic`
- `post_manual_stock_voucher_atomic`
- `send_stock_voucher_atomic`
- `complete_manual_stock_voucher_atomic`
- `cancel_manual_stock_voucher_atomic`

### Confirmed state machine

```text
CREATE
  ↓
Draft
  ├── CANCEL → Cancelled
  │            (only while Draft; no stock mutation)
  │
  └── SEND → Sent
             │
             ├── DirectSale / SupplierReturn
             │       └── COMPLETE → Completed
             │
             └── Transfer / DirectReturn
                     └── RECEIVE
                         ├── partial quantity → Sent + increased received_qty
                         │                      (repeat RECEIVE allowed while remainder exists)
                         └── full quantity → Received
                                             ↓
                                          COMPLETE
                                             ↓
                                          Completed
```

### Transition rules proven from Production definitions
- CREATE accepts the four voucher types: `Transfer`, `DirectSale`, `DirectReturn`, `SupplierReturn`; initial status is `Draft`.
- SEND is permitted only from `Draft` in both captured SEND implementations.
- `post_manual_stock_voucher_atomic` permits `SEND` only for `Transfer`, `DirectSale`, `SupplierReturn`; it rejects other types. Its SEND path performs an `OUT` stock effect from the voucher source branch and sets status to `Sent`.
- `post_manual_stock_voucher_atomic` permits `RECEIVE` only for `Transfer`, `DirectReturn`; it requires current status `Sent` and accepts quantities no greater than the remaining detail quantity.
- After RECEIVE, if any detail remains unreceived, status remains `Sent`; when all detail quantities are received, status becomes `Received` and `received_date` is populated.
- COMPLETE requires `Received` for `Transfer`/`DirectReturn` and `Sent` for `DirectSale`/`SupplierReturn`; it sets `Completed`, `completed_at`, and `completed_by` and does not perform stock mutation.
- CANCEL requires `Draft` only; after stock movement it raises an exception and does not reverse inventory. A formal reverse movement is required by the function message, but its implementation belongs to later movement/return tasks.

### State / mutation boundary
- Physical stock mutation occurs in SEND for the tested outbound path and in RECEIVE for the inbound path handled by `post_manual_stock_voucher_atomic`.
- `allocated_qty` is not modified by these voucher lifecycle RPCs in the captured definitions.
- COMPLETE is administrative closure only and does not mutate `stock_branches` or `inventory_log`.
- CANCEL is administrative cancellation only while Draft and does not mutate stock.

### TASK-005 closure decision
**TASK-005 CLOSED / GO.**
The voucher lifecycle state machine and its state/mutation boundaries are sufficiently proven from the captured Production RPC definitions. Partial Receive idempotency/concurrency remain explicitly assigned to TASK-009/TASK-010/TASK-011 and are not reopened here.

### Evidence source
The final lifecycle RPC definition result was supplied from the Production query `lifecycle_rpc_definitions` and is preserved in the conversation evidence.

---

## TASK-006 — Inventory Movement Matrix

**Status: COMPLETE — GO TO TASK-007**

### Objective
Freeze the currently provable movement matrix without inventing behavior for movements whose authoritative Production path is not yet closed.

### Evidence basis
- Production Inventory Data Contract / EVIDENCE-015 for `stock_branches`, `inventory_log`, and `allocated_qty`.
- Production Manual Voucher RPC definitions reviewed in TASK-004/TASK-005.
- Historical API Catalog cross-checked for the warehouse/runsheet functions that explicitly list stock, inventory-log, and accounting effects.
- Evidence classification is preserved per movement; UNKNOWN is retained where the current authoritative implementation was not proven by the available evidence.

### Matrix

| Movement | Source | Target | Physical Stock | allocated_qty | inventory_log | Voucher/Operational Effect | Accounting | Evidence |
|---|---|---|---|---|---|---|---|---|
| Purchase Receipt | Supplier | Branch | Branch `qty +` | No proven mutation | Yes | Purchase/receiving lifecycle | Journal/Lines explicitly listed | PROVEN |
| Transfer SEND | Branch | Branch | Source `qty -` | No | Yes | Voucher `Draft → Sent` | No accounting effect proven in SEND RPC | PROVEN |
| Transfer RECEIVE | Branch | Branch | Target `qty +` | No | Yes | `received_qty +`; `Sent → Received` when fully received | No accounting effect proven in RECEIVE RPC | PROVEN |
| DirectSale SEND | Branch | Voucher target is Branch in current RPC contract; customer/custody meaning remains separate | Source `qty -` | No | Yes (`DirectSale`) | `Draft → Sent → Completed` | No accounting effect proven in voucher RPC | PROVEN for stock mutation; custody semantics deferred to TASK-007 |
| DirectReturn RECEIVE | Voucher source/target are Branch-typed in current RPC contract | Branch | Target `qty +` | No | Yes (`DirectReturn`) | `received_qty +`; full receive → `Received` | No accounting effect proven in voucher RPC | PROVEN for stock mutation; custody semantics deferred to TASK-007 |
| SupplierReturn SEND | Branch | Supplier | Source `qty -` | No | Yes (`SupplierReturn`) | `Draft → Sent → Completed` | No accounting effect proven in voucher RPC | PROVEN |
| Loading | Branch / warehouse operational flow | Loaded operational custody | `qty ↓` and `allocated_qty ↓` are explicitly listed by the historical API Catalog for `complete-loading` | `allocated_qty ↓` | Yes | Runsheet/order loading state | Journal/Lines explicitly listed | STATIC ONLY / Historical current-path evidence |
| Unloading | Loaded operational custody | Branch / stock | Stock is explicitly described as re-added by `unload-runsheet` | Not proven | Yes | Runsheet unload lifecycle | UNKNOWN | STATIC ONLY / Historical current-path evidence |
| POS / direct sales outside Manual Voucher | UNKNOWN from current authoritative Production contract | UNKNOWN | UNKNOWN | UNKNOWN | Historical/current `inventory_log` touch exists in API Catalog for delivery path, but current stock mutation authority not closed here | UNKNOWN | UNKNOWN | UNKNOWN / later sales tasks |
| VanSale | UNKNOWN from closed Production contract | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN from current authoritative definitions in this task | UNKNOWN | UNKNOWN | TARGET/CONTRACT REQUIRED later |
| Inventory Adjustment / Count | Inventory count workflow exists, but exact physical mutation engine is not closed here | UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN | `inventory_counts` / details are explicitly cataloged; mutation effect not proven here | UNKNOWN | UNKNOWN |

### Central movement boundaries proven
- `stock_branches.qty` is the physical current stock state.
- `stock_branches.allocated_qty` is reserved stock and is not itself a physical movement.
- `stock_branches.available_qty` is derived from `qty - allocated_qty`.
- `inventory_log` is movement history and is distinct from current stock.
- Manual Voucher SEND is the outbound physical movement point for the proven voucher path.
- Manual Voucher RECEIVE is the inbound physical movement point for Transfer/DirectReturn.
- COMPLETE and Draft-only CANCEL are administrative lifecycle actions, not physical stock movements.

### TASK-006 closure decision
**TASK-006 CLOSED / GO.**
The movement matrix is frozen at the highest evidence level currently available. Movements explicitly marked UNKNOWN are not guessed or silently normalized; their closure is assigned to the designated later contracts (`TASK-007` custody, `TASK-008` movement types, and later sales/loading/unloading tasks as applicable).

### Next Gate
**TASK-007 — Custody Matrix**

---

## TASK-007 — Custody Matrix
**Status: COMPLETE — GO.**

Closed by commit `65dbb10a4af9a1da357a9f7a55a24cf668f0bc35` from reconciled evidence. Custody was resolved as a distinct contract from physical stock movement; unresolved target semantics were not promoted to Production fact.

### Gate
TASK-007 CLOSED / GO TO TASK-008.

## TASK-008 — Movement Types Contract
**Status: COMPLETE — GO.**

Closed by commit `8b8c9d9d838b9eb9e50d115d3f199505c38a2108`. Production movement vocabulary was separated from historical-only/candidate types; no unproven database enum/check was invented.

### Gate
TASK-008 CLOSED / GO TO TASK-009.

## TASK-009 — Partial Receive Contract
**Status: COMPLETE — GO.**

Closed by commit `d6681a2f9aade9052548655b7b067811c9367373`. Partial Receive was frozen as cumulative `received_qty` with `Sent` retained until full receipt; idempotency was explicitly deferred to TASK-010.

### Gate
TASK-009 CLOSED / GO TO TASK-010.

## TASK-010 — Idempotency Contract
**Status: COMPLETE — FINDING / GO TO TASK-011.**

### Production test
A single transactional test executed:
`SEND 2 → RECEIVE 1 → repeat the same RECEIVE 1`
with full verification of voucher state, detail `received_qty`, `inventory_log`, source/target stock, and final classification. The transaction was rolled back.

### Result
**TASK-010 — NON-IDEMPOTENT PARTIAL RECEIVE PROVEN.**

The repeated partial RECEIVE was accepted as a second movement rather than being rejected/deduplicated by an independent operation identity. This is a Production behavior finding, not an inference from static code.

### Gate
**TASK-010 CLOSED.**
No idempotency patch was applied by TASK-010.

## NEXT TASK
**TASK-011 — Concurrency Contract**
